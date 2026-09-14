import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/logger_service.dart';
import '../../domain/entities/auth_error.dart';
import '../../domain/entities/auth_event.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_gateway.dart';

enum AuthStatus {
  guest,
  resolving,
  authenticating,
  authenticated,
  signOutPending,
  error,
  ownershipConflict,

  /// Sign-out recovery is unresolved. [AuthProvider.recoveryStatus] separates
  /// unknown remote outcome, local cleanup, and required normal restart.
  cleanupRecovery,

  /// V1-R09 H2 — the canonical auth-state observation stream terminated
  /// unexpectedly. Fresh authority is latched off; a restart is required.
  observationUnavailable,
}

enum PostAuthLifecycleState {
  idle,
  running,
  success,
  retryableFailure,
  provisioningFailure,
  permissionDenied,
  invalidData,
  malformedResponse,
  authFailure,
  unexpected,
  ownershipConflict,
  corruptOwnershipRegistry,
}

enum SignOutReason { explicit, external }

/// Result of the observable post-auth pipeline invoked for a genuinely
/// authenticated session (Google sign-in or restored session).
enum PostAuthOutcome {
  /// Claim + bootstrap completed (or no work was registered).
  success,

  /// Claim/bootstrap failed transiently (network, backend). Authentication
  /// itself stays successful; the UI may offer a safe retry.
  retryableFailure,

  /// F7 — the canonical `public.profiles` row could not be provisioned for a
  /// provisioning-specific reason. Authentication itself stays successful; the
  /// distinct typed lifecycle state lets the UI present a provisioning-specific
  /// recovery path.
  provisioningFailure,
  permissionDenied,
  invalidData,
  malformedResponse,
  authFailure,
  unexpected,

  /// The device's local ownership registry is bound to a DIFFERENT
  /// authenticated user. Fail-closed: auth is neutralized, no bootstrap runs.
  ownershipConflict,

  /// The persisted ownership registry is corrupt. Auth is neutralized and no
  /// account-bound work runs until the authoritative session is resolved.
  corruptOwnershipRegistry,
}

typedef PostAuthWork = Future<PostAuthOutcome> Function(AuthSession session);

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthGateway? gateway,
    PostAuthWork? onPostAuth,
    VoidCallback? onAccountBoundReset,
    VoidCallback? onSessionRefresh,
  }) : _gateway = gateway,
       _onPostAuth = onPostAuth,
       _onAccountBoundReset = onAccountBoundReset,
       _onSessionRefresh = onSessionRefresh {
    _authSubscription = _gateway?.authEvents.listen(
      _handleAuthEvent,
      onError: (_) {},
    );
    // V1-R09 C3 — the gateway may have already resumed a persisted
    // credential-exchange journal before this provider subscribed.
    // Synchronize state immediately for the C3 exchange quarantine states.
    final c3Recovery = recoveryStatus;
    if ((c3Recovery == AuthRecoveryStatus.exchangeTimedOutPending ||
            c3Recovery == AuthRecoveryStatus.exchangeNeutralizing ||
            c3Recovery == AuthRecoveryStatus.exchangeBlockedCleanupFailure ||
            c3Recovery == AuthRecoveryStatus.exchangeBlockedUnattributed ||
            c3Recovery == AuthRecoveryStatus.localResetRestartRequired) &&
        _session == null &&
        _status != AuthStatus.observationUnavailable) {
      _enterLogoutCleanupRecovery();
    }
  }

  final AuthGateway? _gateway;
  final PostAuthWork? _onPostAuth;
  final VoidCallback? _onAccountBoundReset;
  final VoidCallback? _onSessionRefresh;

  StreamSubscription<AuthEvent>? _authSubscription;

  AuthSession? _session;
  AuthStatus _status = AuthStatus.guest;
  AuthError? _error;
  int _generation = 0;
  String? _pipelineUserId;
  int _pipelineGeneration = -1;
  _PipelineRun? _pipelineRecord;

  Future<void>? _signInFuture;
  Future<void>? _signOutFuture;
  bool _recoveryRetryBusy = false;
  bool _disposed = false;
  String? _recoveryOperationId;

  PostAuthLifecycleState _postAuthState = PostAuthLifecycleState.idle;

  bool get isAvailable => _gateway?.isAvailable ?? false;

  /// Machine-readable life-cycle state.
  AuthStatus get status => _status;

  /// The canonical application-wide session generation / auth epoch.
  ///
  /// Advances on EVERY identity transition — including guest → authenticated
  /// and authenticated → guest (V1-R08 finding 6/19). Same-identity refreshes
  /// and token renewals never advance it. Account-bound async work captures
  /// the active user and [generation] and may publish a result only while both
  /// still match.
  int get generation => _generation;

  /// Observable state of the post-auth claim/bootstrap pipeline.
  PostAuthLifecycleState get postAuthState => _postAuthState;

  /// The last sign-in failure, or the retained blocking session message
  /// (session loss / ownership conflict) in guest state, else null.
  AuthError? get error => _error;

  /// The active authenticated session, or null while signed out.
  AuthSession? get session => _session;

  bool get isLoggedIn => _status == AuthStatus.authenticated;

  /// Exposes the existing gateway authority gate to account-bound consumers.
  bool get canAccountAuthorityBeGranted =>
      !isAuthorityBlocked && (_gateway?.canAccountAuthorityBeGranted ?? false);

  /// A session restore or sign-in is in flight (used to disable actions).
  bool get isRestoring =>
      _status == AuthStatus.resolving || _status == AuthStatus.authenticating;

  bool get isSigningIn => _status == AuthStatus.authenticating;
  bool get isSigningOut => _status == AuthStatus.signOutPending;

  /// True while the device blockingly rejects a second account (local
  /// ownership conflict) or after it has been neutralized until cleared.
  bool get isOwnershipBlocked =>
      _status == AuthStatus.ownershipConflict ||
      (_status == AuthStatus.guest && _error == AuthError.ownershipConflict);

  /// V1-R09 H1 — true while a sign-out recovery requires bounded cleanup
  /// before fresh authority may resume.
  bool get isCleanupBlocked => _status == AuthStatus.cleanupRecovery;

  AuthRecoveryStatus get recoveryStatus =>
      _gateway?.recoveryStatus ?? AuthRecoveryStatus.none;
  bool get isRecoveryRetryBusy => _recoveryRetryBusy;

  /// V1-R09 H2 — true once the auth observation stream terminated and a
  /// restart is required before fresh authority may resume.
  bool get isAuthObservationUnavailable =>
      _status == AuthStatus.observationUnavailable;

  /// V1-R09 H1/H2/C3 — authority-restricted states (cleanup required,
  /// credential-exchange quarantine, or lost observation) must not present
  /// normal sign-in/restore surfaces.
  bool get isAuthorityBlocked =>
      _status == AuthStatus.cleanupRecovery ||
      _status == AuthStatus.observationUnavailable ||
      recoveryStatus == AuthRecoveryStatus.restartRequired ||
      recoveryStatus == AuthRecoveryStatus.storageFailure ||
      recoveryStatus == AuthRecoveryStatus.exchangeTimedOutPending ||
      recoveryStatus == AuthRecoveryStatus.exchangeNeutralizing ||
      recoveryStatus == AuthRecoveryStatus.exchangeBlockedCleanupFailure ||
      recoveryStatus == AuthRecoveryStatus.exchangeBlockedUnattributed ||
      recoveryStatus == AuthRecoveryStatus.localResetRestartRequired;

  String? get currentName => _session?.displayName;
  String? get currentEmail => _session?.email;
  String? get currentUserId => _session?.userId;

  String get userName => currentName ?? 'Civil Engineer';
  String get userEmail => currentEmail ?? 'guest@civilpedia.com';

  /// Whether an account-bound result captured for [userId] at [generation]
  /// may still be published. Old-session and old-user completions must be
  /// dropped by the caller when this returns false.
  bool isCurrentSession({required String userId, required int generation}) {
    return isLoggedIn &&
        userId == _session?.userId &&
        generation == _generation;
  }

  Future<void> restoreSession() async {
    if (!isAvailable) return;
    if (isAuthorityBlocked) return;

    _setStatus(AuthStatus.resolving);

    AuthSession? restored;
    try {
      restored = await _gateway?.restoreSession();
    } catch (error) {
      LoggerService.warning('Session restore failed; continuing as guest.');
      LoggerService.error('Session restore failure', error);
    }

    if (restored != null) {
      await _reconcileAuthenticatedSession(restored);
    } else if (recoveryStatus != AuthRecoveryStatus.none) {
      // V1-R09 H1 — a pending/blocked sign-out cleanup gate is observable: the
      // provider must not claim plain guest while cleanup is still required.
      _enterLogoutCleanupRecovery();
    } else {
      _enterGuest();
    }
  }

  Future<void> signInWithGoogle() async {
    if (!isAvailable) {
      _fail(AuthError.unavailable);
      return;
    }
    final pending = _signInFuture;
    if (pending != null) return pending;
    final future = _performSignIn();
    _signInFuture = future;
    try {
      await future;
    } finally {
      _signInFuture = null;
    }
  }

  Future<void> _performSignIn() async {
    if (isAuthorityBlocked) return;

    _error = null;
    _setStatus(AuthStatus.authenticating);

    final attemptGeneration = _generation;
    AuthSession? session;
    try {
      session = await _gateway?.signInWithGoogle();
    } on AuthGatewayException catch (e) {
      if (_disposed) return;
      if (recoveryStatus != AuthRecoveryStatus.none) {
        _enterLogoutCleanupRecovery();
        return;
      }
      if (attemptGeneration != _generation) return;
      _fail(e.error);
      return;
    } catch (error) {
      LoggerService.error('Google sign-in failed', error);
      _fail(AuthError.signInFailed);
      return;
    }

    if (_disposed || attemptGeneration != _generation || isAuthorityBlocked) {
      if (session != null) _gateway?.rejectCredentialAdmission(session);
      return;
    }
    if (session == null) {
      _setStatus(AuthStatus.guest);
      return;
    }

    if (!(_gateway?.consumeCredentialAdmission(session) ?? false)) {
      _enterLogoutCleanupRecovery();
      return;
    }
    // No await between the final gateway receipt check and provisional
    // installation: reconciliation installs synchronously before its first await.
    await _reconcileAuthenticatedSession(session);
  }

  Future<void> resetQuarantinedDeviceSignIn() async {
    if (_disposed ||
        _recoveryRetryBusy ||
        recoveryStatus != AuthRecoveryStatus.exchangeBlockedUnattributed)
      return;
    _recoveryRetryBusy = true;
    notifyListeners();
    try {
      await _gateway?.resetQuarantinedDeviceSignIn();
      if (!_disposed) _enterLogoutCleanupRecovery();
    } catch (_) {
      // The local reset never restores authority or exposes raw storage errors.
    } finally {
      _recoveryRetryBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> signOut() async {
    final pending = _signOutFuture;
    if (pending != null) return pending;
    final future = _performSignOut();
    _signOutFuture = future;
    try {
      await future;
    } finally {
      _signOutFuture = null;
    }
  }

  Future<void> _performSignOut() async {
    if (_status == AuthStatus.guest) return;
    if (_status == AuthStatus.ownershipConflict) return;
    if (isAuthorityBlocked) return;
    if (_status == AuthStatus.resolving ||
        _status == AuthStatus.authenticating) {
      return;
    }

    _error = null;
    _setStatus(AuthStatus.signOutPending);

    try {
      await _gateway!.signOut();
      if (_disposed) return;
    } on AuthGatewayException catch (e) {
      _signOutFailed(e.error);
      return;
    } catch (_) {
      _signOutFailed(AuthError.signOutFailed);
      return;
    }

    if (_status == AuthStatus.signOutPending) {
      _enterGuest();
    }
  }

  /// V1-R09 H1 — retries the owned local cleanup of the pending sign-out
  /// recovery operation.
  ///
  /// Only acts while the provider is in [AuthStatus.cleanupRecovery]. On
  /// success the recovery gate is cleared and normal guest authority resumes;
  /// on any failure the provider stays blocked and the retry stays available.
  Future<void> retryAuthCleanup() async {
    if (_recoveryRetryBusy) return;
    // V1-R09 C3 — credential-exchange quarantine is surfaced by the gateway
    // even without a prior restoreSession. Enter cleanup recovery when a
    // recovery gate is observable so the retry dispatcher can run.
    if (_status != AuthStatus.cleanupRecovery) {
      if (recoveryStatus == AuthRecoveryStatus.none) return;
      _enterLogoutCleanupRecovery();
    }
    _recoveryRetryBusy = true;
    notifyListeners();
    try {
      final result =
          await _gateway?.retryAuthRecovery() ?? AuthRecoveryResult.blocked;
      if (_disposed) return;
      if (result == AuthRecoveryResult.cleanGuest &&
          _status == AuthStatus.cleanupRecovery &&
          recoveryStatus == AuthRecoveryStatus.none) {
        _clearCleanupRecovery();
      } else if (_status == AuthStatus.cleanupRecovery) {
        _error = recoveryStatus == AuthRecoveryStatus.storageFailure
            ? AuthError.unexpected
            : AuthError.recoveryBlocked;
      }
    } catch (_) {
      LoggerService.warning('Logout cleanup retry failed; stays blocked.');
    } finally {
      _recoveryRetryBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    if (_status == AuthStatus.ownershipConflict) return;
    if (isAuthorityBlocked) return;
    _error = null;
    _setStatus(AuthStatus.guest);
    notifyListeners(); // rebuild even when the status was already guest (neutralized)
    _notifySessionRefresh();
  }

  Future<void> _reconcileAuthenticatedSession(AuthSession session) async {
    if (isAuthorityBlocked ||
        !(_gateway?.canAccountAuthorityBeGranted ?? true)) {
      return;
    }
    // Reconciliations of the SAME identity while already authenticated (or
    // mid-claim) update the session in place and NEVER advance the generation —
    // a token refresh or repeated restore must not invalidate account-bound
    // work that is still current.
    if (_session?.userId == session.userId &&
        (_status == AuthStatus.authenticated ||
            _status == AuthStatus.authenticating)) {
      _session = session;
      notifyListeners();
      return;
    }

    // V1-R08 (finding 6/19) — EVERY transition into a genuinely new identity
    // advances the canonical generation, INCLUDING guest → authenticated. A
    // capture taken while signed out must never land in the new session.
    _advanceGeneration();
    final wasAuthenticated = _status == AuthStatus.authenticated;
    if (wasAuthenticated) {
      // Replacing one authenticated identity with another: clear old account
      // state before the new session becomes visible. No cross-account flash.
      _notifyAccountBoundReset();
    }

    _session = session;
    _error = null;
    _setStatus(AuthStatus.authenticating);
    _notifySessionRefresh();
    await _runPostAuthPipeline(session);
  }

  Future<void> _runPostAuthPipeline(AuthSession session) {
    final userId = session.userId;
    final generation = _generation;
    final alreadySettled =
        _pipelineUserId == userId &&
        _pipelineGeneration == generation &&
        _postAuthState == PostAuthLifecycleState.success;
    if (alreadySettled) return Future.value();

    // V1-R08 (finding 7) — the pending run is keyed by (user, generation) so
    // a divergent account never reuses another identity's in-flight pipeline.
    final pending = _pipelineRecord;
    if (pending != null &&
        pending.userId == userId &&
        pending.generation == generation) {
      return pending.future;
    }

    final run = _doPipeline(session, generation);
    _pipelineRecord = _PipelineRun(
      userId: userId,
      generation: generation,
      future: run,
    );
    return run.whenComplete(() {
      if (identical(_pipelineRecord?.future, run)) {
        _pipelineRecord = null;
      }
    });
  }

  /// V1-R08 (finding 9) — Retries the post-auth claim/bootstrap pipeline for
  /// the CURRENT authenticated session after a retryable failure. Strictly a
  /// no-op outside a current authenticated session, when no retry is due, or
  /// while another pipeline run is already in flight.
  Future<void> retryPostAuth() async {
    if (isAuthorityBlocked || !(_gateway?.canAccountAuthorityBeGranted ?? true))
      return;
    final session = _session;
    if (_status != AuthStatus.authenticated || session == null) return;
    if (_postAuthState != PostAuthLifecycleState.retryableFailure) return;
    if (_pipelineRecord != null) return;
    await _runPostAuthPipeline(session);
  }

  Future<void> _doPipeline(AuthSession session, int generation) async {
    _postAuthState = PostAuthLifecycleState.running;
    notifyListeners();

    final callback = _onPostAuth;
    PostAuthOutcome outcome;
    if (callback == null) {
      outcome = PostAuthOutcome.success;
    } else {
      try {
        outcome = await callback(session);
      } catch (error) {
        LoggerService.error('Post-auth pipeline failed', error);
        outcome = PostAuthOutcome.retryableFailure;
      }
    }

    if (generation != _generation) return;

    _pipelineUserId = session.userId;
    _pipelineGeneration = generation;
    _postAuthState = _mapOutcome(outcome);
    notifyListeners();

    switch (outcome) {
      case PostAuthOutcome.success:
        _setStatus(AuthStatus.authenticated);
        // F5 — final authenticated transition: refresh the router so the
        // protected `?return=` destination is re-evaluated (not only re-read
        // by AuthScreen) once the pipeline has fully settled.
        _notifySessionRefresh();
      case PostAuthOutcome.retryableFailure:
        _setStatus(AuthStatus.authenticated);
        // F5 — same transition reachable after a retryable claim failure: the
        // session IS authoritative, so the router must re-evaluate protected
        // destinations (the profile seam offers the retry).
        _notifySessionRefresh();
      case PostAuthOutcome.provisioningFailure:
      case PostAuthOutcome.permissionDenied:
      case PostAuthOutcome.invalidData:
      case PostAuthOutcome.malformedResponse:
      case PostAuthOutcome.authFailure:
      case PostAuthOutcome.unexpected:
        // F7 — provisioning genuinely failed for a provisioning-specific
        // reason: the session is authoritative and stays authenticated; the
        // distinct lifecycle state is observable for a typed recovery path.
        _setStatus(AuthStatus.authenticated);
        _notifySessionRefresh();
      case PostAuthOutcome.ownershipConflict:
        _setStatus(AuthStatus.ownershipConflict);
        _notifyAccountBoundReset();
        unawaited(_neutralizeTemporarySession());
      case PostAuthOutcome.corruptOwnershipRegistry:
        _setStatus(AuthStatus.ownershipConflict);
        _notifyAccountBoundReset();
        unawaited(_neutralizeTemporarySession());
    }
    notifyListeners();
  }

  PostAuthLifecycleState _mapOutcome(PostAuthOutcome o) => switch (o) {
    PostAuthOutcome.success => PostAuthLifecycleState.success,
    PostAuthOutcome.retryableFailure => PostAuthLifecycleState.retryableFailure,
    PostAuthOutcome.provisioningFailure =>
      PostAuthLifecycleState.provisioningFailure,
    PostAuthOutcome.permissionDenied => PostAuthLifecycleState.permissionDenied,
    PostAuthOutcome.invalidData => PostAuthLifecycleState.invalidData,
    PostAuthOutcome.malformedResponse =>
      PostAuthLifecycleState.malformedResponse,
    PostAuthOutcome.authFailure => PostAuthLifecycleState.authFailure,
    PostAuthOutcome.unexpected => PostAuthLifecycleState.unexpected,
    PostAuthOutcome.ownershipConflict =>
      PostAuthLifecycleState.ownershipConflict,
    PostAuthOutcome.corruptOwnershipRegistry =>
      PostAuthLifecycleState.corruptOwnershipRegistry,
  };

  /// Neutralizes the temporary second-account session. On failure the
  /// provider remains blocked in [AuthStatus.ownershipConflict] until the
  /// authoritative session resolves (signed-out/expired event).
  Future<void> _neutralizeTemporarySession() async {
    _error = AuthError.ownershipConflict;
    try {
      await _gateway?.signOut();
    } catch (_) {}
  }

  void _handleAuthEvent(AuthEvent event) {
    final session = event.session;
    switch (event.type) {
      case AuthEventType.sessionRestored:
        if (session == null) {
          if (_status == AuthStatus.resolving) _enterGuest();
          return;
        }
        // Startup restoration: reconcile with the canonical stream instead of
        // depending only on a one-time currentSession read.
        unawaited(_reconcileAuthenticatedSession(session));

      case AuthEventType.signedIn:
        if (session == null) return;
        if (_status == AuthStatus.authenticating && _signInFuture != null) {
          // The in-flight explicit sign-in already reconciles this session;
          // the stream signal would only duplicate the pipeline.
          return;
        }
        unawaited(_reconcileAuthenticatedSession(session));

      case AuthEventType.signedOut:
        // Every definitive SDK event is forwarded. Already-neutralized
        // recovery stays blocked; the event is not proof persistence is clean.
        if (_status == AuthStatus.cleanupRecovery) return;
        if (_status == AuthStatus.observationUnavailable) return;
        final wasExplicit = _status == AuthStatus.signOutPending;
        _enterGuest(
          reason: wasExplicit ? SignOutReason.explicit : SignOutReason.external,
        );

      case AuthEventType.sessionLost:
        if (_status == AuthStatus.cleanupRecovery) return;
        if (_status == AuthStatus.observationUnavailable) return;
        _enterGuest(reason: SignOutReason.external);

      case AuthEventType.logoutCleanupRequired:
        // V1-R09 H1 — remote revocation succeeded but owned local cleanup is
        // pending/blocked/stalled. Neutralize authority and expose the retry
        // seam; the user is signed out but the gate is not clean yet.
        _recoveryOperationId = event.operationId;
        _enterLogoutCleanupRecovery();

      case AuthEventType.logoutCleanupCleared:
        if (event.operationId != null &&
            _recoveryOperationId != null &&
            event.operationId != _recoveryOperationId)
          return;
        if (recoveryStatus != AuthRecoveryStatus.none) return;
        // V1-R09 H1 — the pending cleanup settled. Only relevant while the
        // recovery gate is actually held; otherwise the signedOut event above
        // already produced the canonical guest state.
        if (_status == AuthStatus.cleanupRecovery) {
          _clearCleanupRecovery();
        } else if (_status == AuthStatus.authenticated &&
            _error == AuthError.retryableNetwork) {
          // V1-R09 C2 — the delayed remote revocation eventually succeeded and
          // the owned cleanup finished. The attempted sign-out actually
          // completed, so end as a clean guest instead of leaving a stale
          // retryable failure behind.
          _enterGuest();
        }

      case AuthEventType.authRecoveryChanged:
        if (recoveryStatus == AuthRecoveryStatus.none) return;
        if (_session == null && _status != AuthStatus.observationUnavailable) {
          _enterLogoutCleanupRecovery();
        }
        _error = recoveryStatus == AuthRecoveryStatus.storageFailure
            ? AuthError.unexpected
            : AuthError.recoveryBlocked;
        notifyListeners();

      case AuthEventType.authObservationUnavailable:
        // V1-R09 H2 — canonical observation is gone. Fresh authority stays
        // latched off until the app is restarted.
        _enterObservationUnavailable();

      case AuthEventType.tokenRefreshed:
        if (isAuthorityBlocked) return;
        if (session != null) {
          _session = session;
          notifyListeners();
        }

      case AuthEventType.sessionReplaced:
        if (session != null) {
          // userUpdated/session replacement: reconcile with the canonical
          // stream. Generation/reset semantics live ONLY in
          // [_reconcileAuthenticatedSession] (a genuinely new identity
          // advances + resets there; a same-user update does not).
          unawaited(_reconcileAuthenticatedSession(session));
        }
    }
  }

  void _enterGuest({SignOutReason reason = SignOutReason.explicit}) {
    // V1-R08 (finding 6) — a transition AWAY from a session/identity advances
    // the generation. A fresh app start that was already guest does not
    // fabricate an epoch bump.
    final hadSession = _session != null || _status != AuthStatus.guest;
    final wasConflict = _status == AuthStatus.ownershipConflict;
    _session = null;
    if (hadSession) {
      _advanceGeneration();
    }
    _pipelineUserId = null;
    _pipelineGeneration = -1;
    _pipelineRecord = null;
    _postAuthState = PostAuthLifecycleState.idle;

    if (wasConflict) {
      _error = AuthError.ownershipConflict;
    } else if (reason == SignOutReason.external) {
      _error = AuthError.sessionLost;
    } else {
      _error = null;
    }

    _setStatus(AuthStatus.guest);
    if (hadSession) {
      _notifyAccountBoundReset();
    }
    _notifySessionRefresh();
  }

  // V1-R09 H1 — the remote half of the authoritative sign-out succeeded but
  // owned local cleanup is pending/blocked/stalled. The provider neutralizes
  // authority and exposes the bounded [retryAuthCleanup] seam instead of
  // claiming a clean guest state.
  void _enterLogoutCleanupRecovery() {
    if (_status == AuthStatus.cleanupRecovery) {
      notifyListeners();
      return;
    }
    if (_status == AuthStatus.observationUnavailable) return;
    final hadSession = _session != null;
    _session = null;
    if (hadSession) {
      _advanceGeneration();
    }
    _pipelineUserId = null;
    _pipelineGeneration = -1;
    _pipelineRecord = null;
    _postAuthState = PostAuthLifecycleState.idle;
    _error = AuthError.recoveryBlocked;
    _setStatus(AuthStatus.cleanupRecovery);
    if (hadSession) {
      _notifyAccountBoundReset();
    }
    _notifySessionRefresh();
  }

  void _clearCleanupRecovery() {
    if (_status != AuthStatus.cleanupRecovery) return;
    _recoveryOperationId = null;
    _error = null;
    _setStatus(AuthStatus.guest);
    notifyListeners();
    _notifySessionRefresh();
  }

  // V1-R09 H2 — the canonical auth-state observation stream terminated
  // unexpectedly. Fresh authority stays latched off this process; the app must
  // restart before account authority may resume.
  void _enterObservationUnavailable() {
    final hadSession = _session != null || _status != AuthStatus.guest;
    _session = null;
    if (hadSession) {
      _advanceGeneration();
    }
    _pipelineUserId = null;
    _pipelineGeneration = -1;
    _pipelineRecord = null;
    _postAuthState = PostAuthLifecycleState.idle;
    _error = AuthError.recoveryBlocked;
    _setStatus(AuthStatus.observationUnavailable);
    if (hadSession) {
      _notifyAccountBoundReset();
    }
    _notifySessionRefresh();
  }

  void _signOutFailed(AuthError error) {
    if (_disposed) return;
    if (isAuthorityBlocked && _session == null) return;
    if (_session != null) {
      // Remote sign-out failed: never claim guest. Preserve/re-resolve the
      // authoritative session and expose a recoverable failure.
      _setStatus(AuthStatus.authenticated);
      _error = error;
      notifyListeners();
    } else {
      _enterGuest();
    }
  }

  void _fail(AuthError error) {
    _session = null;
    _error = error;
    _setStatus(AuthStatus.error);
  }

  void _advanceGeneration() {
    _generation++;
  }

  void _notifyAccountBoundReset() {
    _onAccountBoundReset?.call();
  }

  void _notifySessionRefresh() {
    _onSessionRefresh?.call();
  }

  void _setStatus(AuthStatus status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// A single-flight post-auth pipeline run, keyed by the canonical identity and
/// the generation under which it started (V1-R08 finding 7). A divergent
/// account or a later generation must NOT reuse this future.
class _PipelineRun {
  const _PipelineRun({
    required this.userId,
    required this.generation,
    required this.future,
  });

  final String userId;
  final int generation;
  final Future<void> future;
}
