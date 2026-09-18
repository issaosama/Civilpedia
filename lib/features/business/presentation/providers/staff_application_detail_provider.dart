import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/business_application_staff_gateway.dart';
import '../../domain/business_application_status.dart';
import '../../domain/staff_application_capabilities.dart';
import '../../domain/staff_application_detail.dart';
import '../../domain/staff_read_result.dart';
import '../../domain/staff_remote_read.dart';

typedef _StaffDetailReadKey = ({
  String userId,
  int authGeneration,
  String applicationId,
});

class _ActiveStaffDetailRead {
  _ActiveStaffDetailRead({required this.requestEpoch});

  final int requestEpoch;
  late final Future<void> future;
}

enum StaffDetailState {
  initial,
  loading,
  data,
  notFound,
  accessDenied,
  signInRequired,
  error,
  mutating,
  mutationError,
  refreshAfterMutationError,
}

enum _DetailReadMode { normal, postMutation }

/// Staff detail and mutation provider with an independent exact-key read lane.
class StaffApplicationDetailProvider extends ChangeNotifier {
  StaffApplicationDetailProvider({
    required BusinessApplicationStaffGateway gateway,
    required AuthProvider auth,
    ValueChanged<BusinessApplicationStaffCause>? onPermissionLost,
    Future<void> Function()? onMutationCommitted,
  }) : _gateway = gateway,
       _auth = auth,
       _onPermissionLost = onPermissionLost,
       _onMutationCommitted = onMutationCommitted;

  final BusinessApplicationStaffGateway _gateway;
  final AuthProvider _auth;
  final ValueChanged<BusinessApplicationStaffCause>? _onPermissionLost;
  final Future<void> Function()? _onMutationCommitted;

  String? _applicationId;
  StaffDetailState _state = StaffDetailState.initial;
  StaffApplicationDetail? _detail;
  BusinessApplicationStaffCause? _lastErrorCause;
  StaffRemoteReadFailureKind? _lastRemoteFailure;
  bool _readUnavailable = false;
  StaffRemoteReadPhase _readPhase = StaffRemoteReadPhase.idle;
  _StaffDetailReadKey? _dataKey;
  bool _hasAuthoritativeResult = false;
  bool _mutationSucceeded = false;

  int _requestEpoch = 0;
  int _mutationEpoch = 0;
  int _reviewRevision = 0;
  final Map<_StaffDetailReadKey, _ActiveStaffDetailRead> _activeReads = {};
  bool _disposed = false;

  StaffDetailState get state => _state;
  StaffApplicationDetail? get detail => _detail;
  BusinessApplicationStaffCause? get lastErrorCause => _lastErrorCause;
  StaffRemoteReadFailureKind? get lastRemoteFailure => _lastRemoteFailure;
  bool get readUnavailable => _readUnavailable;
  StaffRemoteReadPhase get readPhase => _readPhase;
  bool get isRefreshing => _readPhase == StaffRemoteReadPhase.refreshing;
  bool get mutationSucceeded => _mutationSucceeded;
  String? get applicationId => _applicationId;
  int get activeReadCount => _activeReads.length;
  int get reviewRevision => _reviewRevision;

  String? get _currentUserId => _auth.session?.userId;

  Future<void> load(String applicationId) {
    return _startRead(applicationId, mode: _DetailReadMode.normal);
  }

  Future<void> refresh() {
    final id = _applicationId;
    if (id == null) return Future.value();
    return _startRead(id, mode: _DetailReadMode.normal);
  }

  /// Manual reread after a committed mutation whose authoritative reread
  /// failed. This never resends the mutation.
  Future<void> refreshDetail() {
    final id = _applicationId;
    if (id == null) return Future.value();
    return _startRead(id, mode: _DetailReadMode.postMutation);
  }

  Future<void> _startRead(
    String applicationId, {
    required _DetailReadMode mode,
    bool forceNew = false,
  }) {
    if (_disposed) return Future.value();
    final userId = _currentUserId;
    if (!_auth.isLoggedIn || userId == null || userId.isEmpty) {
      _invalidateReadLane(clearApplicationId: false);
      _applicationId = applicationId;
      _state = StaffDetailState.signInRequired;
      _notifyIfAlive();
      return Future.value();
    }

    final key = (
      userId: userId,
      authGeneration: _auth.generation,
      applicationId: applicationId,
    );
    if (!forceNew) {
      final active = _activeReads[key];
      if (active != null &&
          active.requestEpoch == _requestEpoch &&
          _applicationId == applicationId) {
        return active.future;
      }
    }

    _applicationId = applicationId;
    final hasMatchingKnownGood =
        _hasAuthoritativeResult && _dataKey == key && _detail != null;
    if (!hasMatchingKnownGood) {
      _clearKnownGood();
    }
    _lastErrorCause = null;
    _lastRemoteFailure = null;
    _readUnavailable = false;
    if (mode == _DetailReadMode.normal) {
      _mutationSucceeded = false;
      _readPhase = hasMatchingKnownGood
          ? StaffRemoteReadPhase.refreshing
          : StaffRemoteReadPhase.loading;
      _state = hasMatchingKnownGood
          ? StaffDetailState.data
          : StaffDetailState.loading;
      _notifyIfAlive();
    }

    final requestEpoch = ++_requestEpoch;
    final capturedRevision = _reviewRevision;
    final active = _ActiveStaffDetailRead(requestEpoch: requestEpoch);
    active.future =
        _performRead(
          key: key,
          requestEpoch: requestEpoch,
          capturedRevision: capturedRevision,
          mode: mode,
        ).whenComplete(() {
          if (identical(_activeReads[key], active)) {
            _activeReads.remove(key);
          }
        });
    _activeReads[key] = active;
    return active.future;
  }

  Future<void> _performRead({
    required _StaffDetailReadKey key,
    required int requestEpoch,
    required int capturedRevision,
    required _DetailReadMode mode,
  }) async {
    StaffReadResult<StaffApplicationDetail> result;
    try {
      result = _gateway.isAvailable
          ? await _gateway.getApplicationDetail(key.applicationId)
          : const StaffReadUnavailable<StaffApplicationDetail>();
    } catch (_) {
      result = const StaffRemoteReadFailure<StaffApplicationDetail>(
        StaffRemoteReadFailureKind.unexpected,
      );
    }
    if (!_canPublishRead(
      key,
      requestEpoch: requestEpoch,
      capturedRevision: capturedRevision,
    )) {
      return;
    }
    if (result case StaffReadSuccess(
      :final data,
    ) when data.id != key.applicationId) {
      result = const StaffRemoteReadFailure<StaffApplicationDetail>(
        StaffRemoteReadFailureKind.malformedResponse,
      );
    }
    _applyReadResult(key, result, mode: mode);
    _notifyIfAlive();
  }

  void _applyReadResult(
    _StaffDetailReadKey key,
    StaffReadResult<StaffApplicationDetail> result, {
    required _DetailReadMode mode,
  }) {
    switch (result) {
      case StaffReadSuccess(:final data):
        _detail = data;
        _dataKey = key;
        _hasAuthoritativeResult = true;
        _lastErrorCause = null;
        _lastRemoteFailure = null;
        _readUnavailable = false;
        _readPhase = StaffRemoteReadPhase.loaded;
        _state = StaffDetailState.data;
        _mutationSucceeded = false;
      case StaffReadDenied(:final cause):
        _lastErrorCause = cause;
        _lastRemoteFailure = null;
        _readUnavailable = false;
        if (_isAuthorityDenial(cause)) {
          _clearKnownGood();
          _readPhase = StaffRemoteReadPhase.failed;
          _state = cause == BusinessApplicationStaffCause.unauthenticated
              ? StaffDetailState.signInRequired
              : StaffDetailState.accessDenied;
          if (mode == _DetailReadMode.normal) {
            _mutationSucceeded = false;
          }
          _signalPermissionLost(cause);
        } else if (cause == BusinessApplicationStaffCause.applicationNotFound) {
          _clearKnownGood();
          _readPhase = StaffRemoteReadPhase.authoritativeNotFound;
          _state = StaffDetailState.notFound;
          if (mode == _DetailReadMode.normal) {
            _mutationSucceeded = false;
          }
        } else {
          _publishReadFailure(key, mode: mode);
        }
      case StaffRemoteReadFailure(:final kind):
        _lastErrorCause = null;
        _lastRemoteFailure = kind;
        _readUnavailable = false;
        _publishReadFailure(key, mode: mode);
      case StaffReadUnavailable():
        _lastErrorCause = BusinessApplicationStaffCause.unexpected;
        _lastRemoteFailure = null;
        _readUnavailable = true;
        _publishReadFailure(key, mode: mode);
    }
  }

  void _publishReadFailure(
    _StaffDetailReadKey key, {
    required _DetailReadMode mode,
  }) {
    _readPhase = StaffRemoteReadPhase.failed;
    final hasMatchingKnownGood =
        _hasAuthoritativeResult && _dataKey == key && _detail != null;
    if (mode == _DetailReadMode.postMutation) {
      _state = StaffDetailState.refreshAfterMutationError;
    } else if (hasMatchingKnownGood) {
      _state = StaffDetailState.data;
    } else {
      _clearKnownGood();
      _state = StaffDetailState.error;
    }
  }

  bool _canPublishRead(
    _StaffDetailReadKey key, {
    required int requestEpoch,
    required int capturedRevision,
  }) {
    return !_disposed &&
        requestEpoch == _requestEpoch &&
        capturedRevision == _reviewRevision &&
        key.applicationId == _applicationId &&
        _auth.isCurrentSession(
          userId: key.userId,
          generation: key.authGeneration,
        );
  }

  bool isActionAvailable(
    StaffAction action,
    StaffApplicationCapabilities capabilities,
  ) {
    final status = _detail?.status;
    if (status == null) return false;
    return _actionPermitted(action, capabilities) &&
        _actionValidForStatus(action, status);
  }

  static bool _actionPermitted(
    StaffAction action,
    StaffApplicationCapabilities capabilities,
  ) {
    return switch (action) {
      StaffAction.beginReview => capabilities.canBeginReview,
      StaffAction.returnForCorrection => capabilities.canReturnForCorrection,
      StaffAction.markContacted => capabilities.canMarkContacted,
      StaffAction.scheduleVisit => capabilities.canScheduleVisit,
      StaffAction.approve => capabilities.canApprove,
      StaffAction.reject => capabilities.canReject,
      StaffAction.activate => capabilities.canActivate,
    };
  }

  static bool _actionValidForStatus(
    StaffAction action,
    BusinessApplicationStatus status,
  ) {
    return switch (action) {
      StaffAction.beginReview => status == BusinessApplicationStatus.submitted,
      StaffAction.returnForCorrection ||
      StaffAction.markContacted ||
      StaffAction.scheduleVisit =>
        status == BusinessApplicationStatus.underReview,
      StaffAction.approve || StaffAction.reject =>
        status == BusinessApplicationStatus.underReview ||
            status == BusinessApplicationStatus.contacted ||
            status == BusinessApplicationStatus.visitScheduled,
      StaffAction.activate => status == BusinessApplicationStatus.approved,
    };
  }

  Future<bool> _runMutation(
    Future<BusinessApplicationStaffResult> Function() call,
  ) async {
    final id = _applicationId;
    final userId = _currentUserId;
    if (_disposed ||
        id == null ||
        userId == null ||
        !_auth.isLoggedIn ||
        _state == StaffDetailState.mutating) {
      return false;
    }
    final authGeneration = _auth.generation;
    final mutationEpoch = _mutationEpoch;

    // Mutation entry supersedes every pre-mutation detail read before the RPC
    // can commit, preventing an old completion from publishing while mutating.
    _reviewRevision++;
    _requestEpoch++;
    _activeReads.clear();
    _mutationSucceeded = false;
    _state = StaffDetailState.mutating;
    _lastErrorCause = null;
    _lastRemoteFailure = null;
    _readUnavailable = false;
    _notifyIfAlive();

    final result = await call();
    if (!_canPublishMutation(
      applicationId: id,
      userId: userId,
      authGeneration: authGeneration,
      mutationEpoch: mutationEpoch,
    )) {
      return false;
    }

    switch (result) {
      case BusinessApplicationStaffSucceeded():
        _mutationSucceeded = true;
        _notifyMutationCommitted();
        await _startRead(
          id,
          mode: _DetailReadMode.postMutation,
          forceNew: true,
        );
        return _state == StaffDetailState.data;
      case BusinessApplicationStaffDenied(:final cause):
        _lastErrorCause = cause;
        _lastRemoteFailure = null;
        _readUnavailable = false;
        if (_isAuthorityDenial(cause)) {
          _clearKnownGood();
          _state = cause == BusinessApplicationStaffCause.unauthenticated
              ? StaffDetailState.signInRequired
              : StaffDetailState.accessDenied;
          _mutationSucceeded = false;
          _signalPermissionLost(cause);
        } else {
          _state = cause == BusinessApplicationStaffCause.applicationNotFound
              ? StaffDetailState.notFound
              : StaffDetailState.mutationError;
        }
        _notifyIfAlive();
        return false;
    }
  }

  bool _canPublishMutation({
    required String applicationId,
    required String userId,
    required int authGeneration,
    required int mutationEpoch,
  }) {
    return !_disposed &&
        mutationEpoch == _mutationEpoch &&
        applicationId == _applicationId &&
        _auth.isCurrentSession(userId: userId, generation: authGeneration);
  }

  void _notifyMutationCommitted() {
    final callback = _onMutationCommitted;
    if (callback != null) unawaited(callback());
  }

  Future<bool> beginReview() =>
      _runMutation(() => _gateway.beginReview(_applicationId!));

  Future<bool> returnForCorrection(String reason) => _runMutation(
    () => _gateway.returnForCorrection(_applicationId!, reason: reason),
  );

  Future<bool> markContacted({
    required String contactType,
    String? result,
    String? notes,
  }) => _runMutation(
    () => _gateway.markContacted(
      _applicationId!,
      contactType: contactType,
      result: result,
      notes: notes,
    ),
  );

  Future<bool> scheduleVisit({
    required DateTime scheduledAt,
    String? location,
    String? notes,
  }) => _runMutation(
    () => _gateway.scheduleVisit(
      _applicationId!,
      scheduledAt: scheduledAt,
      location: location,
      notes: notes,
    ),
  );

  Future<bool> approve() =>
      _runMutation(() => _gateway.approve(_applicationId!));

  Future<bool> reject(String reason) =>
      _runMutation(() => _gateway.reject(_applicationId!, reason: reason));

  Future<bool> activate() =>
      _runMutation(() => _gateway.activate(_applicationId!));

  void clear() {
    if (_disposed) return;
    _mutationEpoch++;
    _invalidateReadLane(clearApplicationId: false);
    _state = StaffDetailState.initial;
    notifyListeners();
  }

  void _invalidateReadLane({required bool clearApplicationId}) {
    _requestEpoch++;
    _activeReads.clear();
    if (clearApplicationId) _applicationId = null;
    _clearKnownGood();
    _mutationSucceeded = false;
    _lastErrorCause = null;
    _lastRemoteFailure = null;
    _readUnavailable = false;
    _readPhase = StaffRemoteReadPhase.idle;
  }

  void _clearKnownGood() {
    _detail = null;
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
    _mutationEpoch++;
    _requestEpoch++;
    _activeReads.clear();
    super.dispose();
  }
}

enum StaffAction {
  beginReview,
  returnForCorrection,
  markContacted,
  scheduleVisit,
  approve,
  reject,
  activate,
}
