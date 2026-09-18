import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/business_application_staff_gateway.dart';
import '../../domain/staff_application_capabilities.dart';
import '../../domain/staff_read_result.dart';
import '../../domain/staff_remote_read.dart';

typedef _StaffCapabilitiesReadKey = ({String userId, int authGeneration});

enum StaffAccessState {
  initial,
  resolving,
  authorized,
  noReadPermission,
  signInRequired,
  error,
}

/// Current-session Staff capability resolution with exact-key coalescing and
/// canonical AuthProvider generation guards.
class StaffAccessProvider extends ChangeNotifier {
  StaffAccessProvider({
    required BusinessApplicationStaffGateway gateway,
    required AuthProvider auth,
    VoidCallback? onPermissionLost,
  }) : _gateway = gateway,
       _auth = auth,
       _onPermissionLost = onPermissionLost {
    _auth.addListener(_handleAuthChanged);
  }

  final BusinessApplicationStaffGateway _gateway;
  final AuthProvider _auth;
  final VoidCallback? _onPermissionLost;

  StaffAccessState _state = StaffAccessState.initial;
  StaffApplicationCapabilities? _capabilities;
  BusinessApplicationStaffCause? _lastErrorCause;
  StaffRemoteReadFailureKind? _lastRemoteFailure;
  bool _readUnavailable = false;
  StaffRemoteReadPhase _readPhase = StaffRemoteReadPhase.idle;
  _StaffCapabilitiesReadKey? _currentKey;

  int _requestEpoch = 0;
  final Map<_StaffCapabilitiesReadKey, Future<void>> _activeReads = {};
  bool _disposed = false;

  StaffAccessState get state => _state;
  StaffApplicationCapabilities? get capabilities => _capabilities;
  BusinessApplicationStaffCause? get lastErrorCause => _lastErrorCause;
  StaffRemoteReadFailureKind? get lastRemoteFailure => _lastRemoteFailure;
  bool get readUnavailable => _readUnavailable;
  StaffRemoteReadPhase get readPhase => _readPhase;
  int get activeReadCount => _activeReads.length;

  bool get isAuthorized => _state == StaffAccessState.authorized;
  bool get isResolving => _state == StaffAccessState.resolving;
  bool get hasReadPermission => _capabilities?.canRead ?? false;

  String? get _currentUserId => _auth.session?.userId;

  /// Resolves capabilities for the current `(userId, authGeneration)` key.
  /// Repeated calls for that exact active key join one underlying RPC.
  Future<void> load() {
    if (_disposed) return Future.value();
    final userId = _currentUserId;
    if (!_auth.isLoggedIn || userId == null || userId.isEmpty) {
      _invalidateReads();
      _state = StaffAccessState.signInRequired;
      _readPhase = StaffRemoteReadPhase.idle;
      _notifyIfAlive();
      return Future.value();
    }

    final key = (userId: userId, authGeneration: _auth.generation);
    final active = _activeReads[key];
    if (active != null) return active;

    _currentKey = key;
    _state = StaffAccessState.resolving;
    _capabilities = null;
    _lastErrorCause = null;
    _lastRemoteFailure = null;
    _readUnavailable = false;
    _readPhase = StaffRemoteReadPhase.loading;
    _notifyIfAlive();

    final requestEpoch = ++_requestEpoch;
    late final Future<void> operation;
    operation = _performLoad(key, requestEpoch).whenComplete(() {
      if (identical(_activeReads[key], operation)) {
        _activeReads.remove(key);
      }
    });
    _activeReads[key] = operation;
    return operation;
  }

  Future<void> _performLoad(
    _StaffCapabilitiesReadKey key,
    int requestEpoch,
  ) async {
    StaffReadResult<StaffApplicationCapabilities> result;
    try {
      result = _gateway.isAvailable
          ? await _gateway.getCapabilities()
          : const StaffReadUnavailable<StaffApplicationCapabilities>();
    } catch (_) {
      result = const StaffRemoteReadFailure<StaffApplicationCapabilities>(
        StaffRemoteReadFailureKind.unexpected,
      );
    }
    if (!_canPublish(key, requestEpoch)) return;

    switch (result) {
      case StaffReadSuccess(:final data):
        _capabilities = data;
        _lastErrorCause = null;
        _lastRemoteFailure = null;
        _readUnavailable = false;
        _state = data.canRead
            ? StaffAccessState.authorized
            : StaffAccessState.noReadPermission;
        _readPhase = data.canRead
            ? StaffRemoteReadPhase.loaded
            : StaffRemoteReadPhase.authoritativeEmpty;
        if (!data.canRead) _signalPermissionLost();
      case StaffReadDenied(:final cause):
        _capabilities = null;
        _lastErrorCause = cause;
        _lastRemoteFailure = null;
        _readUnavailable = false;
        _readPhase = StaffRemoteReadPhase.failed;
        _state = switch (cause) {
          BusinessApplicationStaffCause.unauthenticated =>
            StaffAccessState.signInRequired,
          BusinessApplicationStaffCause.staffPermissionDenied =>
            StaffAccessState.noReadPermission,
          _ => StaffAccessState.error,
        };
        if (_isAuthorityDenial(cause)) _signalPermissionLost();
      case StaffRemoteReadFailure(:final kind):
        _capabilities = null;
        _lastErrorCause = null;
        _lastRemoteFailure = kind;
        _readUnavailable = false;
        _readPhase = StaffRemoteReadPhase.failed;
        _state = StaffAccessState.error;
      case StaffReadUnavailable():
        _capabilities = null;
        _lastErrorCause = BusinessApplicationStaffCause.unexpected;
        _lastRemoteFailure = null;
        _readUnavailable = true;
        _readPhase = StaffRemoteReadPhase.failed;
        _state = StaffAccessState.error;
    }
    _notifyIfAlive();
  }

  bool _canPublish(_StaffCapabilitiesReadKey key, int requestEpoch) {
    return !_disposed &&
        requestEpoch == _requestEpoch &&
        _currentKey == key &&
        _auth.isCurrentSession(
          userId: key.userId,
          generation: key.authGeneration,
        );
  }

  void reset() {
    if (_disposed) return;
    _invalidateReads();
    _state = StaffAccessState.initial;
    _readPhase = StaffRemoteReadPhase.idle;
    notifyListeners();
  }

  void applyPrivilegedDenial(BusinessApplicationStaffCause cause) {
    if (_disposed) return;
    _invalidateReads();
    final userId = _currentUserId;
    if (userId != null && userId.isNotEmpty) {
      _currentKey = (userId: userId, authGeneration: _auth.generation);
    }
    _lastErrorCause = cause;
    _lastRemoteFailure = null;
    _readUnavailable = false;
    _readPhase = StaffRemoteReadPhase.failed;
    _state = cause == BusinessApplicationStaffCause.unauthenticated
        ? StaffAccessState.signInRequired
        : StaffAccessState.noReadPermission;
    notifyListeners();
  }

  void _handleAuthChanged() {
    if (_disposed) return;
    final priorKey = _currentKey;
    final userId = _currentUserId;
    if (_auth.isLoggedIn && userId != null && userId.isNotEmpty) {
      final nextKey = (userId: userId, authGeneration: _auth.generation);
      if (priorKey == nextKey) return;
      _invalidateReads();
      if (priorKey != null) _signalPermissionLost();
      unawaited(load());
      return;
    }

    if (priorKey != null || _state != StaffAccessState.signInRequired) {
      _invalidateReads();
      _state = StaffAccessState.signInRequired;
      _readPhase = StaffRemoteReadPhase.idle;
      _notifyIfAlive();
      if (priorKey != null) _signalPermissionLost();
    }
  }

  void _invalidateReads() {
    _requestEpoch++;
    _activeReads.clear();
    _currentKey = null;
    _capabilities = null;
    _lastErrorCause = null;
    _lastRemoteFailure = null;
    _readUnavailable = false;
  }

  static bool _isAuthorityDenial(BusinessApplicationStaffCause cause) {
    return cause == BusinessApplicationStaffCause.staffPermissionDenied ||
        cause == BusinessApplicationStaffCause.unauthenticated;
  }

  void _signalPermissionLost() => _onPermissionLost?.call();

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _auth.removeListener(_handleAuthChanged);
    _requestEpoch++;
    _activeReads.clear();
    super.dispose();
  }
}
