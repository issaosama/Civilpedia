import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/business_application_staff_gateway.dart';
import '../../domain/staff_application_capabilities.dart';
import '../../domain/staff_read_result.dart';

/// V1-R07 — Lifecycle states for current-session staff capability resolution.
enum StaffAccessState {
  /// Not yet asked to resolve.
  initial,

  /// Capability RPC in flight.
  resolving,

  /// Session has `business_applications.read`.
  authorized,

  /// Authenticated but no staff read permission.
  noReadPermission,

  /// No authenticated session.
  signInRequired,

  /// Backend unavailable or unclassified error.
  error,
}

/// V1-R07 — Resolves the current session's granular staff application
/// permissions. This is UX-only; every staff RPC revalidates authority.
///
/// Privileged queue/detail providers must not render data while this provider
/// is in [StaffAccessState.resolving] or [StaffAccessState.noReadPermission].
///
/// Fail-closed guarantees (findings 1, 10):
/// - session changes (sign-out, session replacement) reset capability state and
///   restart resolution for the new session;
/// - a server `P0PER`/`P0AUT` denial never leaves stale authorized capability
///   data behind — it clears and signals [onPermissionLost] so privileged
///   queue/detail data owned elsewhere is cleared too.
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

  /// The auth user id for which the current capability state was resolved, or
  /// null while signed out / unresolved. Used to detect session replacement.
  String? _resolvedUser;

  int _requestSeq = 0;

  StaffAccessState get state => _state;
  StaffApplicationCapabilities? get capabilities => _capabilities;
  BusinessApplicationStaffCause? get lastErrorCause => _lastErrorCause;

  bool get isAuthorized => _state == StaffAccessState.authorized;
  bool get isResolving => _state == StaffAccessState.resolving;
  bool get hasReadPermission => _capabilities?.canRead ?? false;

  @override
  void dispose() {
    _auth.removeListener(_handleAuthChanged);
    super.dispose();
  }

  /// Resolves capabilities for the current session. Safe to call repeatedly.
  Future<void> load() async {
    if (!_auth.isLoggedIn) {
      _resolvedUser = null;
      _state = StaffAccessState.signInRequired;
      _capabilities = null;
      _lastErrorCause = null;
      notifyListeners();
      return;
    }

    if (!_gateway.isAvailable) {
      _state = StaffAccessState.error;
      _capabilities = null;
      _lastErrorCause = BusinessApplicationStaffCause.unexpected;
      notifyListeners();
      return;
    }

    final request = ++_requestSeq;
    _resolvedUser = _auth.session?.userId;
    _state = StaffAccessState.resolving;
    _capabilities = null;
    _lastErrorCause = null;
    notifyListeners();

    final result = await _gateway.getCapabilities();
    if (request != _requestSeq) return;
    switch (result) {
      case StaffReadSuccess(:final data):
        _capabilities = data;
        _state = data.canRead
            ? StaffAccessState.authorized
            : StaffAccessState.noReadPermission;
        _lastErrorCause = null;
      case StaffReadDenied(:final cause):
        _capabilities = null;
        _lastErrorCause = cause;
        _state = switch (cause) {
          BusinessApplicationStaffCause.unauthenticated =>
            StaffAccessState.signInRequired,
          BusinessApplicationStaffCause.staffPermissionDenied =>
            StaffAccessState.noReadPermission,
          _ => StaffAccessState.error,
        };
        if (cause == BusinessApplicationStaffCause.staffPermissionDenied ||
            cause == BusinessApplicationStaffCause.unauthenticated) {
          _signalPermissionLost();
        }
      case StaffReadUnavailable():
        _capabilities = null;
        _state = StaffAccessState.error;
        _lastErrorCause = BusinessApplicationStaffCause.unexpected;
    }
    notifyListeners();
  }

  /// Clears capability state, e.g. on sign-out.
  void reset() {
    _requestSeq++;
    _resolvedUser = null;
    _state = StaffAccessState.initial;
    _capabilities = null;
    _lastErrorCause = null;
    notifyListeners();
  }

  /// Applies an authoritative denial reported by another privileged staff RPC.
  /// This invalidates any capability read in flight without recursively
  /// re-emitting the scope callback that delivered the denial.
  void applyPrivilegedDenial(BusinessApplicationStaffCause cause) {
    _requestSeq++;
    _resolvedUser = cause == BusinessApplicationStaffCause.unauthenticated
        ? null
        : _auth.session?.userId;
    _capabilities = null;
    _lastErrorCause = cause;
    _state = cause == BusinessApplicationStaffCause.unauthenticated
        ? StaffAccessState.signInRequired
        : StaffAccessState.noReadPermission;
    notifyListeners();
  }

  /// Auth session transition handling (finding 10).
  ///
  /// Binds capability resolution to the auth provider: any change in the
  /// authenticated user (sign-out or replacement) resets staff state and clears
  /// privileged queue/detail data for the previous session, and restarts
  /// capability resolution for a newly authenticated session.
  void _handleAuthChanged() {
    final signedIn = _auth.isLoggedIn;
    if (signedIn) {
      final user = _auth.session?.userId;
      if (_resolvedUser != null && _resolvedUser != user) {
        _signalPermissionLost();
      }
      if (_resolvedUser != user) {
        _resolvedUser = user;
        unawaited(load());
      }
      return;
    }

    if (_resolvedUser != null) {
      _resolvedUser = null;
      reset();
      _signalPermissionLost();
    }
  }

  void _signalPermissionLost() {
    _onPermissionLost?.call();
  }
}
