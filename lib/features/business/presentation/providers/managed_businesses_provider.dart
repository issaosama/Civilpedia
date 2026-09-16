import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/business_membership_capabilities.dart';
import '../../domain/business_membership_gateway.dart';
import '../../domain/business_remote_read.dart';
import '../../domain/managed_business_summary.dart';

typedef _ManagedBusinessesReadKey = ({String userId, int authGeneration});

enum ManagedBusinessesState {
  signInRequired,
  loading,
  data,
  empty,
  error,
  unavailable,
}

class ManagedBusinessListItem {
  const ManagedBusinessListItem({
    required this.summary,
    required this.capabilities,
  });

  final ManagedBusinessSummary summary;
  final BusinessMembershipCapabilities capabilities;

  bool get canManagePublicProfile => capabilities.canManageEntity;
}

/// Account-bound managed-business list with exact-key coalescing and stale
/// publication protection.
class ManagedBusinessesProvider extends ChangeNotifier {
  ManagedBusinessesProvider({
    required BusinessMembershipGateway membershipGateway,
    required AuthProvider auth,
  }) : _membershipGateway = membershipGateway,
       _auth = auth;

  final BusinessMembershipGateway _membershipGateway;
  final AuthProvider _auth;

  ManagedBusinessesState _state = ManagedBusinessesState.loading;
  List<ManagedBusinessListItem> _items = const [];
  BusinessManagementReadCause? _errorCause;
  BusinessRemoteReadPhase _readPhase = BusinessRemoteReadPhase.idle;
  BusinessRemoteReadFailureKind? _readFailure;
  _ManagedBusinessesReadKey? _dataKey;
  bool _hasAuthoritativeResult = false;

  int _readEpoch = 0;
  final Map<_ManagedBusinessesReadKey, Future<void>> _activeReads = {};
  bool _disposed = false;

  ManagedBusinessesState get state => _state;
  List<ManagedBusinessListItem> get items => _items;

  /// Compatibility lens for the existing P2-D2-locked screen.
  BusinessManagementReadCause? get errorCause => _errorCause;

  BusinessRemoteReadPhase get readPhase => _readPhase;
  BusinessRemoteReadFailureKind? get readFailure => _readFailure;
  bool get isRefreshing => _readPhase == BusinessRemoteReadPhase.refreshing;
  bool get isBusy =>
      _readPhase == BusinessRemoteReadPhase.loading || isRefreshing;
  int get activeReadCount => _activeReads.length;

  String? get _currentUserId => _auth.session?.userId;

  bool get _isAuthenticated =>
      _auth.isLoggedIn && (_currentUserId?.isNotEmpty ?? false);

  Future<void> load() {
    final userId = _currentUserId;
    if (!_isAuthenticated || userId == null || userId.isEmpty) {
      _invalidateAndClear();
      _state = ManagedBusinessesState.signInRequired;
      _readPhase = BusinessRemoteReadPhase.idle;
      _notifyIfAlive();
      return Future.value();
    }

    final key = (userId: userId, authGeneration: _auth.generation);
    final active = _activeReads[key];
    if (active != null) return active;

    if (!_membershipGateway.isAvailable) {
      _publishFailure(key, BusinessRemoteReadFailureKind.serviceUnavailable);
      _notifyIfAlive();
      return Future.value();
    }

    final hasMatchingKnownGood = _hasAuthoritativeResult && _dataKey == key;
    if (!hasMatchingKnownGood) {
      _items = const [];
      _hasAuthoritativeResult = false;
      _dataKey = null;
    }
    _readFailure = null;
    _errorCause = null;
    _readPhase = hasMatchingKnownGood
        ? BusinessRemoteReadPhase.refreshing
        : BusinessRemoteReadPhase.loading;
    _state = hasMatchingKnownGood
        ? (_items.isEmpty
              ? ManagedBusinessesState.empty
              : ManagedBusinessesState.data)
        : ManagedBusinessesState.loading;
    _notifyIfAlive();

    final requestEpoch = ++_readEpoch;
    late final Future<void> operation;
    operation = _performRead(key, requestEpoch).whenComplete(() {
      if (identical(_activeReads[key], operation)) {
        _activeReads.remove(key);
      }
    });
    _activeReads[key] = operation;
    return operation;
  }

  Future<void> _performRead(
    _ManagedBusinessesReadKey key,
    int requestEpoch,
  ) async {
    ManagedBusinessListResult result;
    try {
      result = await _membershipGateway.listMyBusinesses();
    } catch (error) {
      result = ManagedBusinessListDenied(
        error is BusinessRemoteReadException
            ? error.kind
            : BusinessRemoteReadFailureKind.unexpected,
      );
    }
    if (!_canPublish(key, requestEpoch)) return;

    switch (result) {
      case ManagedBusinessListAvailable(:final businesses):
        _items = List.unmodifiable([
          for (final summary in businesses)
            ManagedBusinessListItem(
              summary: summary,
              capabilities: summary.capabilities,
            ),
        ]);
        _dataKey = key;
        _hasAuthoritativeResult = true;
        _readFailure = null;
        _errorCause = null;
        _readPhase = _items.isEmpty
            ? BusinessRemoteReadPhase.authoritativeEmpty
            : BusinessRemoteReadPhase.loaded;
        _state = _items.isEmpty
            ? ManagedBusinessesState.empty
            : ManagedBusinessesState.data;
      case ManagedBusinessListDenied(:final cause):
        _publishFailure(key, cause);
      case ManagedBusinessListUnavailable():
        _publishFailure(key, BusinessRemoteReadFailureKind.serviceUnavailable);
    }
    _notifyIfAlive();
  }

  void _publishFailure(
    _ManagedBusinessesReadKey key,
    BusinessRemoteReadFailureKind cause,
  ) {
    _readFailure = cause;
    _errorCause = _legacyCause(cause);
    _readPhase = BusinessRemoteReadPhase.failed;
    final hasMatchingKnownGood = _hasAuthoritativeResult && _dataKey == key;
    if (hasMatchingKnownGood) {
      _state = _items.isEmpty
          ? ManagedBusinessesState.empty
          : ManagedBusinessesState.data;
    } else {
      _items = const [];
      _state = cause == BusinessRemoteReadFailureKind.serviceUnavailable
          ? ManagedBusinessesState.unavailable
          : ManagedBusinessesState.error;
    }
  }

  bool _canPublish(_ManagedBusinessesReadKey key, int requestEpoch) {
    return !_disposed &&
        requestEpoch == _readEpoch &&
        _currentUserId == key.userId &&
        _auth.generation == key.authGeneration &&
        _auth.isCurrentSession(
          userId: key.userId,
          generation: key.authGeneration,
        );
  }

  static BusinessManagementReadCause _legacyCause(
    BusinessRemoteReadFailureKind cause,
  ) {
    return switch (cause) {
      BusinessRemoteReadFailureKind.authRestricted =>
        BusinessManagementReadCause.unauthenticated,
      BusinessRemoteReadFailureKind.permissionDenied =>
        BusinessManagementReadCause.permissionDenied,
      _ => BusinessManagementReadCause.unexpected,
    };
  }

  void _invalidateAndClear() {
    _readEpoch++;
    _activeReads.clear();
    _items = const [];
    _errorCause = null;
    _readFailure = null;
    _dataKey = null;
    _hasAuthoritativeResult = false;
  }

  void reset() {
    if (_disposed) return;
    _invalidateAndClear();
    _state = ManagedBusinessesState.loading;
    _readPhase = BusinessRemoteReadPhase.idle;
    notifyListeners();
  }

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _readEpoch++;
    _activeReads.clear();
    super.dispose();
  }
}
