import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/business_application_staff_gateway.dart';
import '../../domain/business_application_status.dart';
import '../../domain/business_application_type.dart';
import '../../domain/staff_application_capabilities.dart';
import '../../domain/staff_application_summary.dart';
import '../../domain/staff_read_result.dart';
import '../../domain/staff_remote_read.dart';

typedef _StaffQueueScopeKey = ({
  String userId,
  int authGeneration,
  BusinessApplicationStatus? status,
  BusinessApplicationType? type,
});
typedef _StaffQueueReadKey = ({
  String userId,
  int authGeneration,
  BusinessApplicationStatus? status,
  BusinessApplicationType? type,
  DateTime? cursorCreatedAt,
  String? cursorId,
});

class _ActiveStaffQueueRead {
  _ActiveStaffQueueRead({required this.requestEpoch});

  final int requestEpoch;
  late final Future<void> future;
}

enum StaffQueueState {
  initial,
  loading,
  loadingMore,
  loadMoreError,
  data,
  empty,
  error,
  accessDenied,
  signInRequired,
}

/// Bounded Staff queue with exact-key coalescing, one queue publication lane,
/// canonical auth guards, and mutation-revision protection.
class StaffApplicationQueueProvider extends ChangeNotifier {
  StaffApplicationQueueProvider({
    required BusinessApplicationStaffGateway gateway,
    required AuthProvider auth,
    ValueChanged<BusinessApplicationStaffCause>? onPermissionLost,
  }) : _gateway = gateway,
       _auth = auth,
       _onPermissionLost = onPermissionLost;

  final BusinessApplicationStaffGateway _gateway;
  final AuthProvider _auth;
  final ValueChanged<BusinessApplicationStaffCause>? _onPermissionLost;

  StaffQueueState _state = StaffQueueState.initial;
  StaffApplicationQueueFilter _filter = const StaffApplicationQueueFilter();
  StaffApplicationPage? _page;
  BusinessApplicationStaffCause? _lastErrorCause;
  StaffRemoteReadFailureKind? _lastRemoteFailure;
  bool _readUnavailable = false;
  StaffRemoteReadPhase _readPhase = StaffRemoteReadPhase.idle;
  _StaffQueueScopeKey? _dataKey;
  bool _hasAuthoritativeResult = false;

  int _requestEpoch = 0;
  int _reviewRevision = 0;
  final Map<_StaffQueueReadKey, _ActiveStaffQueueRead> _activeReads = {};
  bool _disposed = false;

  StaffQueueState get state => _state;
  StaffApplicationQueueFilter get filter => _filter;
  List<StaffApplicationSummary> get items => _page?.items ?? const [];
  bool get hasMore => _page?.hasMore ?? false;
  BusinessApplicationStaffCause? get lastErrorCause => _lastErrorCause;
  StaffRemoteReadFailureKind? get lastRemoteFailure => _lastRemoteFailure;
  bool get readUnavailable => _readUnavailable;
  StaffRemoteReadPhase get readPhase => _readPhase;
  bool get isRefreshing => _readPhase == StaffRemoteReadPhase.refreshing;
  int get activeReadCount => _activeReads.length;
  int get reviewRevision => _reviewRevision;

  String? get _currentUserId => _auth.session?.userId;

  Future<void> loadInitial({StaffApplicationQueueFilter? filter}) {
    if (_disposed) return Future.value();
    final nextFilter = filter ?? _filter;
    final userId = _currentUserId;
    if (!_auth.isLoggedIn || userId == null || userId.isEmpty) {
      _filter = nextFilter;
      _invalidateAndClear();
      _state = StaffQueueState.signInRequired;
      _notifyIfAlive();
      return Future.value();
    }

    final scopeKey = (
      userId: userId,
      authGeneration: _auth.generation,
      status: nextFilter.status,
      type: nextFilter.type,
    );
    final readKey = _firstPageKey(scopeKey);
    final active = _activeReads[readKey];
    if (active != null &&
        active.requestEpoch == _requestEpoch &&
        _filter == nextFilter) {
      return active.future;
    }

    _filter = nextFilter;
    final hasMatchingKnownGood =
        _hasAuthoritativeResult && _dataKey == scopeKey;
    if (!hasMatchingKnownGood) {
      _page = null;
      _dataKey = null;
      _hasAuthoritativeResult = false;
    }
    _lastErrorCause = null;
    _lastRemoteFailure = null;
    _readUnavailable = false;
    _readPhase = hasMatchingKnownGood
        ? StaffRemoteReadPhase.refreshing
        : StaffRemoteReadPhase.loading;
    _state = hasMatchingKnownGood
        ? (items.isEmpty ? StaffQueueState.empty : StaffQueueState.data)
        : StaffQueueState.loading;
    _notifyIfAlive();

    return _startRead(
      readKey: readKey,
      scopeKey: scopeKey,
      cursor: null,
      append: false,
    );
  }

  Future<void> loadMore() {
    if (_disposed || !hasMore) {
      return Future.value();
    }
    final userId = _currentUserId;
    final cursor = _page?.nextCursor;
    if (!_auth.isLoggedIn ||
        userId == null ||
        userId.isEmpty ||
        cursor == null) {
      return Future.value();
    }
    final scopeKey = (
      userId: userId,
      authGeneration: _auth.generation,
      status: _filter.status,
      type: _filter.type,
    );
    final readKey = _paginationKey(scopeKey, cursor);
    final active = _activeReads[readKey];
    if (active != null && active.requestEpoch == _requestEpoch) {
      return active.future;
    }
    if (_state != StaffQueueState.data &&
        _state != StaffQueueState.empty &&
        _state != StaffQueueState.loadMoreError) {
      return Future.value();
    }

    _state = StaffQueueState.loadingMore;
    _lastErrorCause = null;
    _lastRemoteFailure = null;
    _readUnavailable = false;
    _notifyIfAlive();
    return _startRead(
      readKey: readKey,
      scopeKey: scopeKey,
      cursor: cursor,
      append: true,
    );
  }

  Future<void> _startRead({
    required _StaffQueueReadKey readKey,
    required _StaffQueueScopeKey scopeKey,
    required StaffApplicationCursor? cursor,
    required bool append,
  }) {
    final requestEpoch = ++_requestEpoch;
    final capturedRevision = _reviewRevision;
    final active = _ActiveStaffQueueRead(requestEpoch: requestEpoch);
    active.future =
        _performRead(
          readKey: readKey,
          scopeKey: scopeKey,
          cursor: cursor,
          append: append,
          requestEpoch: requestEpoch,
          capturedRevision: capturedRevision,
        ).whenComplete(() {
          if (identical(_activeReads[readKey], active)) {
            _activeReads.remove(readKey);
          }
        });
    _activeReads[readKey] = active;
    return active.future;
  }

  Future<void> _performRead({
    required _StaffQueueReadKey readKey,
    required _StaffQueueScopeKey scopeKey,
    required StaffApplicationCursor? cursor,
    required bool append,
    required int requestEpoch,
    required int capturedRevision,
  }) async {
    StaffReadResult<StaffApplicationPage> result;
    try {
      result = _gateway.isAvailable
          ? await _gateway.listApplications(
              statusFilter: scopeKey.status,
              typeFilter: scopeKey.type,
              cursor: cursor,
            )
          : const StaffReadUnavailable<StaffApplicationPage>();
    } catch (_) {
      result = const StaffRemoteReadFailure<StaffApplicationPage>(
        StaffRemoteReadFailureKind.unexpected,
      );
    }
    if (!_canPublish(
      readKey,
      requestEpoch: requestEpoch,
      capturedRevision: capturedRevision,
    )) {
      return;
    }

    if (append) {
      _applyAppendResult(scopeKey, result);
    } else {
      _applyFirstPageResult(scopeKey, result);
    }
    _notifyIfAlive();
  }

  Future<void> retryLoadMore() => loadMore();

  Future<void> refresh() => loadInitial(filter: _filter);

  Future<void> setFilter(StaffApplicationQueueFilter filter) {
    if (filter == _filter) return Future.value();
    return loadInitial(filter: filter);
  }

  Future<void> retry() => loadInitial(filter: _filter);

  /// Called exactly after an accepted Staff mutation commit. The revision is
  /// advanced before a new authoritative queue refresh can begin, so every
  /// older queue completion becomes non-publishable.
  Future<void> onMutationCommitted() {
    if (_disposed) return Future.value();
    _reviewRevision++;
    _requestEpoch++;
    _activeReads.clear();
    return loadInitial(filter: _filter);
  }

  void _applyFirstPageResult(
    _StaffQueueScopeKey key,
    StaffReadResult<StaffApplicationPage> result,
  ) {
    switch (result) {
      case StaffReadSuccess(:final data):
        _page = data;
        _dataKey = key;
        _hasAuthoritativeResult = true;
        _lastErrorCause = null;
        _lastRemoteFailure = null;
        _readUnavailable = false;
        _readPhase = data.items.isEmpty
            ? StaffRemoteReadPhase.authoritativeEmpty
            : StaffRemoteReadPhase.loaded;
        _state = data.items.isEmpty
            ? StaffQueueState.empty
            : StaffQueueState.data;
      case StaffReadDenied(:final cause):
        _lastErrorCause = cause;
        _lastRemoteFailure = null;
        _readUnavailable = false;
        if (_isAuthorityDenial(cause)) {
          _clearKnownGood();
          _readPhase = StaffRemoteReadPhase.failed;
          _state = cause == BusinessApplicationStaffCause.unauthenticated
              ? StaffQueueState.signInRequired
              : StaffQueueState.accessDenied;
          _signalPermissionLost(cause);
        } else {
          _publishFirstPageFailure(key);
        }
      case StaffRemoteReadFailure(:final kind):
        _lastErrorCause = null;
        _lastRemoteFailure = kind;
        _readUnavailable = false;
        _publishFirstPageFailure(key);
      case StaffReadUnavailable():
        _lastErrorCause = BusinessApplicationStaffCause.unexpected;
        _lastRemoteFailure = null;
        _readUnavailable = true;
        _publishFirstPageFailure(key);
    }
  }

  void _publishFirstPageFailure(_StaffQueueScopeKey key) {
    _readPhase = StaffRemoteReadPhase.failed;
    if (_hasAuthoritativeResult && _dataKey == key) {
      _state = items.isEmpty ? StaffQueueState.empty : StaffQueueState.data;
    } else {
      _clearKnownGood();
      _state = StaffQueueState.error;
    }
  }

  void _applyAppendResult(
    _StaffQueueScopeKey key,
    StaffReadResult<StaffApplicationPage> result,
  ) {
    switch (result) {
      case StaffReadSuccess(:final data):
        final existing = _page?.items ?? const <StaffApplicationSummary>[];
        final existingIds = existing.map((item) => item.id).toSet();
        final newItems = data.items
            .where((item) => !existingIds.contains(item.id))
            .toList();
        _page = StaffApplicationPage(
          items: [...existing, ...newItems],
          nextCursor: data.nextCursor,
        );
        _dataKey = key;
        _hasAuthoritativeResult = true;
        _lastErrorCause = null;
        _lastRemoteFailure = null;
        _readUnavailable = false;
        _readPhase = items.isEmpty
            ? StaffRemoteReadPhase.authoritativeEmpty
            : StaffRemoteReadPhase.loaded;
        _state = items.isEmpty ? StaffQueueState.empty : StaffQueueState.data;
      case StaffReadDenied(:final cause):
        _lastErrorCause = cause;
        _lastRemoteFailure = null;
        _readUnavailable = false;
        _publishAppendFailure(cause: cause);
      case StaffRemoteReadFailure(:final kind):
        _lastErrorCause = null;
        _lastRemoteFailure = kind;
        _readUnavailable = false;
        _publishAppendFailure();
      case StaffReadUnavailable():
        _lastErrorCause = BusinessApplicationStaffCause.unexpected;
        _lastRemoteFailure = null;
        _readUnavailable = true;
        _publishAppendFailure();
    }
  }

  void _publishAppendFailure({BusinessApplicationStaffCause? cause}) {
    _readPhase = StaffRemoteReadPhase.failed;
    if (cause != null && _isAuthorityDenial(cause)) {
      _clearKnownGood();
      _state = cause == BusinessApplicationStaffCause.unauthenticated
          ? StaffQueueState.signInRequired
          : StaffQueueState.accessDenied;
      _signalPermissionLost(cause);
      return;
    }
    _state = StaffQueueState.loadMoreError;
  }

  bool _canPublish(
    _StaffQueueReadKey key, {
    required int requestEpoch,
    required int capturedRevision,
  }) {
    return !_disposed &&
        requestEpoch == _requestEpoch &&
        capturedRevision == _reviewRevision &&
        _auth.isCurrentSession(
          userId: key.userId,
          generation: key.authGeneration,
        ) &&
        key.status == _filter.status &&
        key.type == _filter.type;
  }

  static _StaffQueueReadKey _firstPageKey(_StaffQueueScopeKey key) => (
    userId: key.userId,
    authGeneration: key.authGeneration,
    status: key.status,
    type: key.type,
    cursorCreatedAt: null,
    cursorId: null,
  );

  static _StaffQueueReadKey _paginationKey(
    _StaffQueueScopeKey key,
    StaffApplicationCursor cursor,
  ) => (
    userId: key.userId,
    authGeneration: key.authGeneration,
    status: key.status,
    type: key.type,
    cursorCreatedAt: cursor.createdAt,
    cursorId: cursor.id,
  );

  void clear() {
    if (_disposed) return;
    _invalidateAndClear();
    _state = StaffQueueState.initial;
    notifyListeners();
  }

  void _invalidateAndClear() {
    _requestEpoch++;
    _activeReads.clear();
    _clearKnownGood();
    _lastErrorCause = null;
    _lastRemoteFailure = null;
    _readUnavailable = false;
    _readPhase = StaffRemoteReadPhase.idle;
  }

  void _clearKnownGood() {
    _page = null;
    _dataKey = null;
    _hasAuthoritativeResult = false;
  }

  static bool _isAuthorityDenial(BusinessApplicationStaffCause cause) {
    return cause == BusinessApplicationStaffCause.staffPermissionDenied ||
        cause == BusinessApplicationStaffCause.unauthenticated;
  }

  void _signalPermissionLost(BusinessApplicationStaffCause cause) {
    _onPermissionLost?.call(cause);
  }

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _requestEpoch++;
    _activeReads.clear();
    super.dispose();
  }
}
