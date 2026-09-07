import '../entities/auth_error.dart';
import '../entities/auth_session.dart';

/// A5.4 — Auth boundary between the presentation layer and Supabase Auth.
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
  Future<void> signOut();
}

/// Failure carrying a UI-facing [AuthError].
class AuthGatewayException implements Exception {
  const AuthGatewayException(this.error);

  final AuthError error;

  @override
  String toString() => 'AuthGatewayException(${error.name})';
}