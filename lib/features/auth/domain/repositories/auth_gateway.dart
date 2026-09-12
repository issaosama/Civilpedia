import 'dart:async';

import '../entities/auth_error.dart';
import '../entities/auth_event.dart';
import '../entities/auth_session.dart';

/// A5.4/V1-R08 — Auth boundary between the presentation layer and Supabase
/// Auth.
///
/// The provider layer depends on this interface; production wires
/// [SupabaseAuthGateway]. Implementations must never store the session
/// manually — Supabase itself persists and restores the session on device.
///
/// Identity contract: the returned [AuthSession.userId] is always the
/// canonical `auth.users.id`, never a Google provider id.
abstract interface class AuthGateway {
  /// Whether a sign-in can work in this build (backend initialized AND a
  /// Google client id configured). False keeps the UI in guest mode.
  bool get isAvailable;

  /// Bounded stream of canonical Supabase auth/session lifecycle events.
  ///
  /// This is the single authoritative event source for the current Google-only
  /// auth model: restored/initial session, signed in, signed out, token/session
  /// refresh, session replacement, and external session loss/removal.
  Stream<AuthEvent> get authEvents;

  /// Restores a previously persisted session, or null when signed out.
  ///
  /// Implementations MUST NOT throw on transient restore problems; caller
  /// degrades to guest when anything unexpected happens.
  Future<AuthSession?> restoreSession();

  /// Starts native Google sign-in. Returns null when the user cancels or a
  /// session cannot be completed; otherwise returns the authenticated session.
  ///
  /// Throws [AuthGatewayException] for failures that deserve a visible error.
  Future<AuthSession?> signInWithGoogle();

  /// Ends the current session. MUST never delete user-local application data
  /// (Projects, Saved, Notes, preferences, downloads).
  ///
  /// Throws [AuthGatewayException] with a typed cause on failure so the caller
  /// never fakes guest state before the remote sign-out succeeds.
  Future<void> signOut();

  /// V1-R08 (finding 16) — Releases the gateway's auth-state subscription and
  /// resources. The app-lifetime singleton owns a SINGLE subscription; this
  /// explicit disposal path is wired through [AppDependencies.dispose]. The
  /// default is a safe no-op for fakes.
  void dispose() {}
}

/// Failure carrying a UI-facing [AuthError].
class AuthGatewayException implements Exception {
  const AuthGatewayException(this.error);

  final AuthError error;

  @override
  String toString() => 'AuthGatewayException(${error.name})';
}