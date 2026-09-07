import 'package:flutter/foundation.dart';

import '../../../../core/services/logger_service.dart';
import '../../domain/entities/auth_error.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_gateway.dart';

/// App-level authentication life-cycle of the A5.4 state machine.
enum AuthStatus {
  /// Signed out; the app runs in guest mode with full local functionality.
  guest,

  /// A session restore (startup) or a Google sign-in is in flight.
  restoring,

  /// A valid Supabase session is active ([AuthSession] present).
  authenticated,

  /// The last sign-in attempt failed; the app stays usable in guest mode.
  error,
}

/// A5.4 — App-level authentication state (replaces the legacy in-memory/plain
/// text provider).
///
/// The provider never talks to Supabase directly: all session work delegates
/// to an injected [AuthGateway] (production: [SupabaseAuthGateway]; tests:
/// fakes). Session persistence is owned by Supabase, so nothing here stores
/// tokens or credentials manually.
///
/// Guarantees:
/// * Startup is never blocked ([restoreSession] is fire-and-forget and a
///   restore failure degrades silently to GUEST).
/// * [signOut] never deletes user-local application data.
/// * The canonical identity is the Supabase `auth.users.id`.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthGateway? gateway}) : _gateway = gateway;

  final AuthGateway? _gateway;

  AuthSession? _session;
  AuthStatus _status = AuthStatus.guest;
  AuthError? _error;

  /// The gateway is available when the backend is initialized AND a Google
  /// client id is present in the build.
  bool get isAvailable => _gateway?.isAvailable ?? false;

  /// Machine-readable life-cycle state.
  AuthStatus get status => _status;

  /// Backward-compatible accessors used by the profile and home UI.
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  /// A restore/sign-in is currently in flight (used to disable actions).
  bool get isRestoring => _status == AuthStatus.restoring;

  /// The last [AuthError], or null when the last sign-in did not fail.
  AuthError? get error => _error;

  /// The active authenticated session, or null while signed out.
  AuthSession? get session => _session;

  /// The authenticated display name, or null while signed out.
  String? get currentName => _session?.displayName;

  /// The authenticated email, or null while signed out.
  String? get currentEmail => _session?.email;

  /// Legacy alias: name (falls back to the historical guest default).
  String get userName => currentName ?? 'Civil Engineer';

  /// Legacy alias: email (falls back to the historical guest default).
  String get userEmail => currentEmail ?? 'guest@civilpedia.com';

  /// Restores a persisted Supabase session without blocking startup.
  ///
  /// No-op unless currently GUEST. Failures keep the app in guest mode and
  /// never surface an error banner (offline-first behavior).
  Future<void> restoreSession() async {
    if (!isAvailable || _status != AuthStatus.guest) return;
    _setStatus(AuthStatus.restoring);

    AuthSession? restored;
    try {
      restored = await _gateway?.restoreSession();
    } catch (error) {
      LoggerService.warning('Session restore failed; continuing as guest.');
      LoggerService.error('Session restore failure', error);
    }

    if (restored != null) {
      _session = restored;
      _setStatus(AuthStatus.authenticated);
    } else {
      _setStatus(AuthStatus.guest);
    }
  }

  /// Starts native Google sign-in. On failure the provider moves to
  /// [AuthStatus.error] while remaining usable in guest mode; on cancellation
  /// it returns silently to GUEST.
  Future<void> signInWithGoogle() async {
    if (!isAvailable) {
      _fail(AuthError.unavailable);
      return;
    }

    _error = null;
    _setStatus(AuthStatus.restoring);

    AuthSession? session;
    try {
      session = await _gateway?.signInWithGoogle();
    } on AuthGatewayException catch (e) {
      _fail(e.error);
      return;
    } catch (error) {
      LoggerService.error('Google sign-in failed', error);
      _fail(AuthError.signInFailed);
      return;
    }

    if (session == null) {
      // User cancelled the Google sheet — stay guest without an error.
      _setStatus(AuthStatus.guest);
      return;
    }
    _session = session;
    _setStatus(AuthStatus.authenticated);
  }

  /// Ends the session. The UI flips to GUEST immediately (offline-first) and
  /// the backend sign-out runs unawaited semantics — it is awaited here, but
  /// failure never bubbles to the caller.
  ///
  /// Local user data (Projects, Saved, Notes, preferences, downloads) is
  /// NEVER deleted.
  Future<void> signOut() async {
    final wasAuthenticated = isLoggedIn;
    _session = null;
    _error = null;
    _setStatus(AuthStatus.guest);
    if (wasAuthenticated) {
      try {
        await _gateway?.signOut();
      } catch (error) {
        LoggerService.error('Backend sign-out failed', error);
      }
    }
  }

  /// Clears a surfaced sign-in error and returns to plain GUEST state.
  void clearError() {
    if (_error == null) return;
    _error = null;
    _setStatus(AuthStatus.guest);
  }

  void _fail(AuthError error) {
    _session = null;
    _error = error;
    _setStatus(AuthStatus.error);
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}