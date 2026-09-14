import 'auth_session.dart';

enum AuthEventType {
  sessionRestored,
  signedIn,
  signedOut,
  tokenRefreshed,
  sessionReplaced,
  sessionLost,

  /// V1-R09 H1 — a sign-out reached remote success but owned local cleanup is
  /// pending/blocked/stalled. Fresh account authority must stay neutralized
  /// until the cleanup retry succeeds.
  logoutCleanupRequired,

  /// V1-R09 H1 — an authoritative sign-out fully settled (cleanup completed).
  logoutCleanupCleared,

  /// Non-authoritative recovery progress/error; query the gateway's typed state.
  authRecoveryChanged,

  /// V1-R09 H2 — the canonical auth-state observation stream terminated
  /// unexpectedly. The app should not re-arm authority; a restart is required.
  authObservationUnavailable,
}

class AuthEvent {
  const AuthEvent({required this.type, this.session, this.operationId});

  final AuthEventType type;
  final AuthSession? session;

  /// Only application-generated recovery events carry this ownership marker.
  /// SDK signedOut events deliberately never acquire guessed operation IDs.
  final String? operationId;
}
