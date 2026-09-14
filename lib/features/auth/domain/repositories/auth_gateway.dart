import 'dart:async';

import '../entities/auth_error.dart';
import '../entities/auth_event.dart';
import '../entities/auth_session.dart';

enum AuthRecoveryStatus {
  none,
  remotePending,
  cleanupRequired,
  blockedCleanupFailure,
  storageFailure,
  restartRequired,

  /// V1-R09 C3 — a credential-exchange attempt timed out while the raw
  /// Supabase exchange was still unresolved. Fresh sign-in is blocked until
  /// the late result is safely settled.
  exchangeTimedOutPending,

  /// V1-R09 C3 — a timed-out exchange succeeded late and installed a stale
  /// session; stale-session neutralization is in progress.
  exchangeNeutralizing,

  /// V1-R09 C3 — stale-session neutralization failed. Recovery is blocked
  /// until an explicit retry or restart resolves it.
  exchangeBlockedCleanupFailure,
  exchangeBlockedUnattributed,
  localResetRestartRequired,
}

enum AuthRecoveryResult {
  cleanGuest,
  blocked,
  restartRequired,
  retainedSession,
  busy,
}

/// Typed C2 capability on the existing auth gateway, not another authority.
abstract interface class AuthRecoveryGateway {
  AuthRecoveryStatus get recoveryStatus;
  Future<AuthRecoveryResult> retryAuthRecovery();
}

/// C3 process-local admission on the existing authority, not another provider.
abstract interface class AuthCredentialAdmissionGateway {
  bool consumeCredentialAdmission(AuthSession candidate);
  void rejectCredentialAdmission(AuthSession candidate);
}

abstract interface class QuarantinedDeviceSignInGateway {
  Future<AuthRecoveryResult> resetQuarantinedDeviceSignIn();
}

extension AuthCredentialAdmission on AuthGateway {
  bool consumeCredentialAdmission(AuthSession candidate) {
    final gateway = this;
    return gateway is AuthCredentialAdmissionGateway
        ? (gateway as AuthCredentialAdmissionGateway)
              .consumeCredentialAdmission(candidate)
        : canAccountAuthorityBeGranted;
  }

  void rejectCredentialAdmission(AuthSession candidate) {
    final gateway = this;
    if (gateway is AuthCredentialAdmissionGateway) {
      (gateway as AuthCredentialAdmissionGateway).rejectCredentialAdmission(
        candidate,
      );
    }
  }

  Future<AuthRecoveryResult> resetQuarantinedDeviceSignIn() async {
    final gateway = this;
    return gateway is QuarantinedDeviceSignInGateway
        ? (gateway as QuarantinedDeviceSignInGateway)
              .resetQuarantinedDeviceSignIn()
        : AuthRecoveryResult.blocked;
  }
}

/// Keeps older, non-recovery gateway implementations source-compatible.
extension AuthGatewayRecovery on AuthGateway {
  AuthRecoveryStatus get recoveryStatus {
    final gateway = this;
    if (gateway is AuthRecoveryGateway) {
      return (gateway as AuthRecoveryGateway).recoveryStatus;
    }
    return isLogoutCleanupBlocked
        ? AuthRecoveryStatus.cleanupRequired
        : AuthRecoveryStatus.none;
  }

  Future<AuthRecoveryResult> retryAuthRecovery() async {
    final gateway = this;
    if (gateway is AuthRecoveryGateway) {
      return (gateway as AuthRecoveryGateway).retryAuthRecovery();
    }
    return await retryAuthCleanup()
        ? AuthRecoveryResult.cleanGuest
        : AuthRecoveryResult.blocked;
  }
}

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
  ///
  /// This reflects backend/service availability, NOT whether account authority
  /// is currently admissible; see [canAccountAuthorityBeGranted].
  bool get isAvailable;

  /// Whether application account authority may currently be granted.
  ///
  /// When a recovery journal blocks authority (unresolved, cleanup-required,
  /// or corrupt), identity-bearing paths must not promote a session to
  /// authenticated application state.
  bool get canAccountAuthorityBeGranted => true;

  /// V1-R09 H2 — whether the canonical auth-state observation stream is
  /// healthy. Once the stream terminates unexpectedly it stays unhealthy for
  /// this process; fresh authority must not be granted and a restart is
  /// required. The default is the healthy state for fakes.
  bool get isAuthObservationAvailable => true;

  /// Compatibility view of a blocked sign-out recovery, including remotePending.
  /// Production presentation uses the typed [AuthGatewayRecovery] capability.
  bool get isLogoutCleanupBlocked => false;

  /// Legacy compatibility seam. True means verified clean guest ONLY.
  /// Production callers use [AuthGatewayRecovery.retryAuthRecovery].
  ///
  /// Returns `true` when the recovery gate is now clean and normal guest
  /// authority may resume. Returns `false` while the operation is still
  /// blocked or unresolved. Never throws.
  Future<bool> retryAuthCleanup() async => false;

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
  /// explicit disposal seam is wired through [AppDependencies.dispose]. The
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
