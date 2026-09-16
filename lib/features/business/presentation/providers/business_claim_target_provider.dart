import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/business_claim_target.dart';
import '../../domain/business_claim_target_gateway.dart';
import '../../domain/business_remote_read.dart';

typedef _ClaimTargetReadKey = ({String userId, int authGeneration});

enum BusinessClaimTargetState { loading, data, error, empty }

/// Authenticated CLAIM-candidate presentation data. Server-side mutation
/// guards remain the final claimability authority.
class BusinessClaimTargetProvider extends ChangeNotifier {
  BusinessClaimTargetProvider({
    required BusinessClaimTargetGateway gateway,
    required AuthProvider auth,
  }) : _gateway = gateway,
       _auth = auth;

  final BusinessClaimTargetGateway _gateway;
  final AuthProvider _auth;

  BusinessClaimTargetState _state = BusinessClaimTargetState.loading;
  List<BusinessClaimTarget> _targets = const [];
  String? _error;
  BusinessRemoteReadPhase _readPhase = BusinessRemoteReadPhase.idle;
  BusinessRemoteReadFailureKind? _readFailure;
  _ClaimTargetReadKey? _dataKey;
  bool _hasAuthoritativeResult = false;

  int _readEpoch = 0;
  final Map<_ClaimTargetReadKey, Future<void>> _activeReads = {};
  bool _disposed = false;

  BusinessClaimTargetState get state => _state;
  List<BusinessClaimTarget> get targets => _targets;
  String? get error => _error;
  BusinessRemoteReadPhase get readPhase => _readPhase;
  BusinessRemoteReadFailureKind? get readFailure => _readFailure;
  bool get isRefreshing => _readPhase == BusinessRemoteReadPhase.refreshing;
  int get activeReadCount => _activeReads.length;

  String? get _currentUserId => _auth.session?.userId;
  bool get _isAuthenticated =>
      _auth.isLoggedIn && (_currentUserId?.isNotEmpty ?? false);

  Future<void> reload() {
    final userId = _currentUserId;
    if (!_isAuthenticated || userId == null || userId.isEmpty) {
      _invalidateAndClear();
      _state = BusinessClaimTargetState.error;
      _readFailure = BusinessRemoteReadFailureKind.authRestricted;
      _readPhase = BusinessRemoteReadPhase.failed;
      _notifyIfAlive();
      return Future.value();
    }

    final key = (userId: userId, authGeneration: _auth.generation);
    final active = _activeReads[key];
    if (active != null) return active;

    final hasMatchingKnownGood = _hasAuthoritativeResult && _dataKey == key;
    if (!hasMatchingKnownGood) {
      _targets = const [];
      _dataKey = null;
      _hasAuthoritativeResult = false;
    }
    _error = null;
    _readFailure = null;
    _readPhase = hasMatchingKnownGood
        ? BusinessRemoteReadPhase.refreshing
        : BusinessRemoteReadPhase.loading;
    _state = hasMatchingKnownGood
        ? (_targets.isEmpty
              ? BusinessClaimTargetState.empty
              : BusinessClaimTargetState.data)
        : BusinessClaimTargetState.loading;
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

  Future<void> _performRead(_ClaimTargetReadKey key, int requestEpoch) async {
    try {
      final loaded = await _gateway.listUnclaimedTargets();
      if (!_canPublish(key, requestEpoch)) return;
      if (loaded.any((target) => !target.isUnclaimed)) {
        _publishFailure(key, BusinessRemoteReadFailureKind.malformedResponse);
      } else {
        _targets = List.unmodifiable(loaded);
        _dataKey = key;
        _hasAuthoritativeResult = true;
        _readFailure = null;
        _readPhase = _targets.isEmpty
            ? BusinessRemoteReadPhase.authoritativeEmpty
            : BusinessRemoteReadPhase.loaded;
        _state = _targets.isEmpty
            ? BusinessClaimTargetState.empty
            : BusinessClaimTargetState.data;
      }
    } catch (error) {
      if (!_canPublish(key, requestEpoch)) return;
      _publishFailure(
        key,
        error is BusinessRemoteReadException
            ? error.kind
            : BusinessRemoteReadFailureKind.unexpected,
      );
    }
    _notifyIfAlive();
  }

  void _publishFailure(
    _ClaimTargetReadKey key,
    BusinessRemoteReadFailureKind cause,
  ) {
    _readFailure = cause;
    _readPhase = BusinessRemoteReadPhase.failed;
    final hasMatchingKnownGood = _hasAuthoritativeResult && _dataKey == key;
    if (hasMatchingKnownGood) {
      _state = _targets.isEmpty
          ? BusinessClaimTargetState.empty
          : BusinessClaimTargetState.data;
    } else {
      _targets = const [];
      _state = BusinessClaimTargetState.error;
    }
  }

  bool _canPublish(_ClaimTargetReadKey key, int requestEpoch) {
    return !_disposed &&
        requestEpoch == _readEpoch &&
        _currentUserId == key.userId &&
        _auth.generation == key.authGeneration &&
        _auth.isCurrentSession(
          userId: key.userId,
          generation: key.authGeneration,
        );
  }

  Future<void> load() async {
    final userId = _currentUserId;
    final key = userId == null
        ? null
        : (userId: userId, authGeneration: _auth.generation);
    if (key != null && _hasAuthoritativeResult && _dataKey == key) return;
    await reload();
  }

  void _invalidateAndClear() {
    _readEpoch++;
    _activeReads.clear();
    _targets = const [];
    _error = null;
    _readFailure = null;
    _dataKey = null;
    _hasAuthoritativeResult = false;
  }

  void resetForIdentityChange() {
    if (_disposed) return;
    _invalidateAndClear();
    _state = BusinessClaimTargetState.loading;
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
