import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_service.dart';
import '../../../core/network/remote_operation_policy.dart';
import '../../../core/services/logger_service.dart';
import 'auth_recovery_library.dart';
import 'session_correlation.dart';
import '../domain/entities/auth_error.dart';
import '../domain/entities/auth_event.dart';
import '../domain/entities/auth_session.dart';
import '../domain/repositories/auth_gateway.dart';

/// Handles the platform-dependent `GoogleSignIn` lifecycle (singleton
/// initialization + authentication) while keeping the applied behaviour
/// unit-testable without touching the real plugin.
///
/// The real singleton is comprised of:
/// * `initialize(clientId:, serverClientId:)` â€” must be awaited exactly once
///   before any other call (google_sign_in 7.x singleton contract).
/// * `authenticate()` â€” completes with the signed-in [GoogleSignInAccount],
///   throwing a `GoogleSignInException` when the user cancels.
/// * `authorization(account, scopes)` â€” best-effort silent
///   `authorizationForScopes` first, falling back to `authorizeScopes` (the
///   pattern from the official Supabase Flutter guide) to also return a
///   [GoogleSignInClientAuthorization] whose `accessToken` is forwarded to
///   Supabase together with the idToken.
@protected
@visibleForTesting
typedef GoogleSignInApi = ({
  Future<void> Function({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  })
  initialize,
  Future<GoogleSignInAccount> Function(List<String> scopeHint) authenticate,
  Future<GoogleSignInClientAuthorization> Function(
    GoogleSignInAccount account,
    List<String> scopes,
  )
  authorization,
  Future<void> Function() signOut,
});

@immutable
class GoogleCredentialBundle {
  const GoogleCredentialBundle({
    required this.idToken,
    required this.accessToken,
  });

  final String idToken;
  final String accessToken;
}

// Raw SDK mutation results are normalized BEFORE any settlement is attempted.
// Processing exceptions cannot be mistaken for raw exchange failures.
sealed class _RawCredentialExchangeOutcome {}

final class _RawSuccess extends _RawCredentialExchangeOutcome {
  _RawSuccess({this.response, this.injectedCandidate});
  final AuthResponse? response;
  final AuthSession? injectedCandidate;
}

final class _RawFailure extends _RawCredentialExchangeOutcome {
  _RawFailure(this.error);
  final AuthError error;
}

enum _ExchangePhase {
  idle,
  active,
  committing,
  timedOutPending,
  neutralizing,
  blockedCleanupFailure,
  blockedUnattributed,
  localResetRestartRequired,
}

enum _SettlementFailure {
  validation,
  journal,
  processing,
  remoteRevoke,
  localCleanup,
  unattributed,
  localReset,
  restartRequired,
}

/// Non-secret ownership. Raw mutation and settlement never release g early.
class _CredentialExchangeOperation {
  _CredentialExchangeOperation({
    required this.generation,
    required this.operationId,
    required this.placeholderCorrelation,
    this.reconstructed = false,
  });
  final int generation;
  final String operationId;
  final SessionCorrelation placeholderCorrelation;
  final bool reconstructed;
  bool rawPending = false;
  bool settlementPending = false;
  bool resetAppliedHere = false;
}

class _CredentialExchangeState {
  const _CredentialExchangeState(
    this.phase, [
    this.operation,
    this.exact,
    this.failure,
  ]);
  const _CredentialExchangeState.idle()
    : phase = _ExchangePhase.idle,
      operation = null,
      exact = null,
      failure = null;
  final _ExchangePhase phase;
  final _CredentialExchangeOperation? operation;
  final SessionCorrelation? exact;
  final _SettlementFailure? failure;
  bool get isIdle => phase == _ExchangePhase.idle;
  bool get blocksNewExchange => !isIdle;
  bool get blocksAccountAuthority => !isIdle;
  int? get generation => operation?.generation;
}

/// No credentials: candidate identity + operation/generation + gateway binding.
class _CredentialCommitReceipt {
  _CredentialCommitReceipt(
    this.owner,
    this.operation,
    this.correlation,
    this.candidate,
  );
  final SupabaseAuthGateway owner;
  final _CredentialExchangeOperation operation;
  final SessionCorrelation? correlation;
  final AuthSession candidate;
}

@protected
@visibleForTesting
typedef GoogleCredentialsProvider = Future<GoogleCredentialBundle?> Function();

@protected
@visibleForTesting
typedef SupabaseCredentialExchange =
    Future<AuthSession> Function({
      required String idToken,
      required String accessToken,
    });

@protected
@visibleForTesting
typedef SupabaseRemoteSignOut = Future<void> Function();

@protected
@visibleForTesting
typedef SupabaseLocalSignOut = Future<void> Function();

/// V1-R09 C3 â€” optional test seam that supplies the non-secret session
/// correlation captured at the moment an injected credential exchange returns.
/// Production uses the actual SDK session; this is only for deterministic
/// injected-init tests.
@protected
@visibleForTesting
typedef CredentialExchangeCorrelationProvider = SessionCorrelation? Function();

@protected
@visibleForTesting
typedef AuthStateStreamFactory = Stream<AuthState> Function();

@protected
@visibleForTesting
GoogleSignInApi wireGoogleSignIn() {
  final google = GoogleSignIn.instance;
  return (
    initialize: ({clientId, serverClientId, nonce, hostedDomain}) =>
        google.initialize(
          clientId: clientId,
          serverClientId: serverClientId,
          nonce: nonce,
          hostedDomain: hostedDomain,
        ),
    authenticate: (scopeHint) => google.authenticate(scopeHint: scopeHint),
    authorization: (account, scopes) async {
      final silent = await account.authorizationClient.authorizationForScopes(
        scopes,
      );
      if (silent != null) return silent;
      return account.authorizationClient.authorizeScopes(scopes);
    },
    signOut: () => google.signOut(),
  );
}

/// A5.4/V1-R08 â€” Production Supabase-backed [AuthGateway].
///
/// Flow: native [GoogleSignIn] â†’ idToken + Google authorization access token
/// â†’ `signInWithIdToken(OAuthProvider.google)` â†’ Supabase Auth session.
/// Session persistence is owned by Supabase itself (its local storage); this
/// gateway never writes the session to SharedPreferences or other stores.
///
/// The canonical identity exposed to the app is `auth.users.id`
/// ([AuthSession.userId]), taken from the Supabase session â€” never from the
/// Google account id.
///
/// V1-R08 â€” [authEvents] is the bounded authoritative Supabase auth-state
/// lifecycle stream (restored/signed-in/signed-out/refreshed/removed). It
/// wraps the existing Supabase client's own auth-state event source; the
/// provider reconciles startup restoration with it rather than relying only on
/// a one-time `currentSession` read.
///
/// Safety guarantees:
/// * Restore is a no-op and sign-in/sign-out fail through typed outcomes when
///   [isAvailable] is false, so unavailable authority never fabricates state.
/// * The Google `serverClientId` is a PUBLIC identifier supplied by
///   dart-define â€” never a client secret.
/// * [signOut] never touches user-local application data.
@visibleForTesting
enum CredentialExchangeCheckpoint {
  beforeCommitCompletion,
  afterCommitCompletion,
  beforeLateUpgrade,
  afterLateUpgrade,
  remoteSuccessBeforeCleanup,
}

/// Production leaves this observer absent. Tests pause real SDK/journal paths,
/// never substitute an exchange, storage coordinator or commit receipt.
class SupabaseAuthGateway
    implements
        AuthGateway,
        AuthRecoveryGateway,
        AuthCredentialAdmissionGateway,
        QuarantinedDeviceSignInGateway {
  SupabaseAuthGateway({
    required this.service,
    GoogleSignInApi Function()? googleSignInFactory,
    GoogleCredentialsProvider? credentialsProvider,
    SupabaseCredentialExchange? credentialExchange,
    CredentialExchangeCorrelationProvider?
    credentialExchangeCorrelationProvider,
    SupabaseRemoteSignOut? remoteSignOut,
    SupabaseLocalSignOut? localSignOut,
    Future<void> Function(CredentialExchangeCheckpoint)? exchangeCheckpoint,
    SupabaseClient? client,
    AuthStateStreamFactory? authStateStreamFactory,
    Duration credentialExchangeTimeout =
        RemoteOperationPolicy.authCredentialExchange,
    Duration signOutTimeout = RemoteOperationPolicy.mutation,
    Duration googleSignOutTimeout = RemoteOperationPolicy.mutation,
  }) : _googleSignInFactory = googleSignInFactory ?? wireGoogleSignIn,
       _credentialsProvider = credentialsProvider,
       _credentialExchange = credentialExchange,
       _credentialExchangeCorrelationProvider =
           credentialExchangeCorrelationProvider,
       _remoteSignOut = remoteSignOut,
       _localSignOut = localSignOut,
       _exchangeCheckpoint = exchangeCheckpoint,
       _injectedClient = client,
       _authStateStreamFactory = authStateStreamFactory,
       _credentialExchangeTimeout = credentialExchangeTimeout,
       _signOutTimeout = signOutTimeout,
       _googleSignOutTimeout = googleSignOutTimeout {
    service.addListener(_handleServiceState);
    if (service.isInitialized) {
      _ensureAuthStateSubscription();
      _resumeCredentialExchangeStateIfNeeded();
    }
  }

  final SupabaseService service;
  final GoogleSignInApi Function() _googleSignInFactory;
  final GoogleCredentialsProvider? _credentialsProvider;
  final SupabaseCredentialExchange? _credentialExchange;
  final CredentialExchangeCorrelationProvider?
  _credentialExchangeCorrelationProvider;
  final SupabaseRemoteSignOut? _remoteSignOut;
  final SupabaseLocalSignOut? _localSignOut;
  final Future<void> Function(CredentialExchangeCheckpoint)?
  _exchangeCheckpoint;
  final SupabaseClient? _injectedClient;
  final AuthStateStreamFactory? _authStateStreamFactory;
  final Duration _credentialExchangeTimeout;
  final Duration _signOutTimeout;
  final Duration _googleSignOutTimeout;

  GoogleSignInApi? _googleSignIn;
  bool _initialized = false;
  bool _disposed = false;
  StreamSubscription<AuthState>? _authStateSubscription;
  late final StreamController<AuthEvent> _authEvents =
      StreamController<AuthEvent>.broadcast();

  // V1-R09 C3 â€” explicit credential-exchange state machine.
  _CredentialExchangeState _credentialExchangeState =
      const _CredentialExchangeState.idle();
  int _nextCredentialExchangeGeneration = 0;
  _CredentialCommitReceipt? _commitReceipt;
  Future<AuthRecoveryResult>? _deviceResetFuture;
  bool _startingExchange = false;

  // V1-R09 H1 â€” authoritative sign-out operation holder and epoch.
  int _outboundEpoch = 0;
  _OutboundSignOut? _outboundSignOut;

  // V1-R09 H1 -- single-flight retry of the owned local cleanup.
  Future<AuthRecoveryResult>? _cleanupRetryFuture;
  AuthRecoveryStatus _recoveryRestriction = AuthRecoveryStatus.none;

  // V1-R09 H2 -- the canonical auth-state observation stream healthy latch.
  bool _authObservationAvailable = true;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  String get _projectIdentity =>
      AuthRecoveryStorageCoordinator.projectIdentityFromUrl(
        service.config.supabaseUrl,
      );

  @override
  bool get isAvailable =>
      service.isInitialized && service.config.googleServerClientId.isNotEmpty;

  @override
  bool get canAccountAuthorityBeGranted {
    if (_disposed ||
        _startingExchange ||
        _recoveryRestriction != AuthRecoveryStatus.none)
      return false;
    // V1-R09 C3 â€” unresolved credential-exchange quarantine blocks account
    // authority for the timed-out generation and any later generation.
    if (_credentialExchangeState.blocksAccountAuthority) return false;
    // V1-R09 H2 â€” once the canonical auth-state observation stream terminates
    // unexpectedly, fresh account authority must not be granted this process.
    if (!_authObservationAvailable) return false;
    final recovery = service.recoveryState;
    if (recovery == null) return true;
    return !recovery.blocksAccountAuthority;
  }

  @override
  bool get isAuthObservationAvailable => _authObservationAvailable;

  @override
  Stream<AuthEvent> get authEvents {
    _ensureAuthStateSubscription();
    return _authEvents.stream;
  }

  void _ensureAuthStateSubscription() {
    if (_disposed || _authStateSubscription != null || !isAvailable) return;
    final stream =
        _authStateStreamFactory?.call() ?? _client.auth.onAuthStateChange;
    _authStateSubscription = stream.listen(
      (state) {
        final event = _mapAuthState(state);
        if (event != null && !_authEvents.isClosed) {
          _authEvents.add(event);
        }
      },
      onError: (Object error) {
        // V1-R09 H2 â€” recoverable stream errors must NOT stop future auth
        // observation. The underlying broadcast stream stays alive and this
        // single subscription is retained until onDone.
        LoggerService.warning(
          'Supabase auth-state stream error (non-fatal): $error',
        );
      },
      onDone: () {
        // V1-R09 H2 â€” an unexpected termination of the canonical observation
        // stream is a hard stop for this process. Authority is latched off and
        // the stream must NOT be re-armed (a re-subscribe could miss the
        // session-loss window and fabricate stale identity).
        if (_disposed) return;
        _handleAuthObservationLost();
      },
    );
  }

  void _handleAuthObservationLost() {
    _authObservationAvailable = false;
    if (!_authEvents.isClosed) {
      _authEvents.add(
        const AuthEvent(type: AuthEventType.authObservationUnavailable),
      );
    }
  }

  void _handleServiceState() {
    if (service.isInitialized) {
      _ensureAuthStateSubscription();
      _resumeCredentialExchangeStateIfNeeded();
    }
  }

  /// V1-R09 C3 — on process restart, surface a persisted credential-exchange
  /// journal as the explicit in-memory quarantine state so the provider can
  /// enter cleanup recovery and the user can retry neutralization.
  void _resumeCredentialExchangeStateIfNeeded() {
    if (_disposed || !isAvailable || !_credentialExchangeState.isIdle) return;
    final entry = service.recoveryCoordinator?.readRecoveryEntry();
    if (entry == null ||
        entry.operationType != AuthRecoveryOperationType.credentialExchange) {
      return;
    }
    final identity = _entryCorrelation(entry);
    final operation = _CredentialExchangeOperation(
      generation: _nextCredentialExchangeGeneration++,
      operationId: entry.operationId,
      placeholderCorrelation: identity,
      reconstructed: true,
    );
    final phase = switch (entry.phase) {
      AuthRecoveryPhase.neutralizing => _ExchangePhase.neutralizing,
      AuthRecoveryPhase.cleanupRequired ||
      AuthRecoveryPhase.blockedCleanupFailure =>
        _ExchangePhase.blockedCleanupFailure,
      AuthRecoveryPhase.blockedUnattributed =>
        _ExchangePhase.blockedUnattributed,
      AuthRecoveryPhase.localResetAppliedRestartRequired =>
        _ExchangePhase.localResetRestartRequired,
      _ => _ExchangePhase.timedOutPending,
    };
    _credentialExchangeState = _CredentialExchangeState(
      phase,
      operation,
      identity.isSufficientForDestructiveCleanup ? identity : null,
    );
    _emitExchangeRecoveryChanged();
    // Normal SDK initialization has already completed. Verification, never
    // destruction, is automatic only for the durable reset-applied marker.
    if (entry.phase == AuthRecoveryPhase.localResetAppliedRestartRequired ||
        (phase == _ExchangePhase.timedOutPending &&
            !identity.isSufficientForDestructiveCleanup)) {
      unawaited(retryAuthRecovery());
    }
  }

  AuthEvent? _mapAuthState(AuthState state) {
    final session = state.session;
    final event = state.event;
    switch (event) {
      case AuthChangeEvent.initialSession:
        // Startup restoration signal. A non-null session is the restored
        // authenticated state; null simply confirms the guest state we already
        // start in. Also surfaced so the provider can reconcile startup with
        // the canonical stream instead of a one-time currentSession read.
        if (session == null) return null;
        if (!canAccountAuthorityBeGranted) return null;
        return AuthEvent(
          type: AuthEventType.sessionRestored,
          session: _toSession(session.user),
        );
      case AuthChangeEvent.signedIn:
        if (session == null) return null;
        // V1-R09 C1/C3 â€” recovery or quarantine must block identity-bearing
        // authority. The explicit state machine gate below covers the C3
        // timed-out-pending / neutralizing / blocked-cleanup-failure cases
        // without relying on bool combinations.
        if (!canAccountAuthorityBeGranted) return null;
        if (_credentialExchangeState.blocksAccountAuthority) return null;
        return AuthEvent(
          type: AuthEventType.signedIn,
          session: _toSession(session.user),
        );
      case AuthChangeEvent.signedOut:
        // Definitive events are never attributed to a pending cleanup.
        return const AuthEvent(type: AuthEventType.signedOut);
      case AuthChangeEvent.tokenRefreshed:
        if (session == null) {
          // A refresh that left no session is treated as an external loss.
          return const AuthEvent(type: AuthEventType.sessionLost);
        }
        // V1-R09 C1 â€” recovery must block identity-bearing authority.
        if (!canAccountAuthorityBeGranted) return null;
        return AuthEvent(
          type: AuthEventType.tokenRefreshed,
          session: _toSession(session.user),
        );
      case AuthChangeEvent.userDeleted:
        return const AuthEvent(type: AuthEventType.sessionLost);
      case AuthChangeEvent.passwordRecovery:
        return null;
      case AuthChangeEvent.userUpdated:
        if (session == null) return null;
        // V1-R09 C1 â€” recovery must block identity-bearing authority.
        if (!canAccountAuthorityBeGranted) return null;
        return AuthEvent(
          type: AuthEventType.sessionReplaced,
          session: _toSession(session.user),
        );
      case AuthChangeEvent.mfaChallengeVerified:
        if (session == null) return null;
        // V1-R09 C1 â€” recovery must block identity-bearing authority.
        if (!canAccountAuthorityBeGranted) return null;
        return AuthEvent(
          type: AuthEventType.tokenRefreshed,
          session: _toSession(session.user),
        );
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    if (!isAvailable) return null;
    if (!canAccountAuthorityBeGranted) return null;
    _ensureAuthStateSubscription();
    final session = _client.auth.currentSession;
    final user = session?.user;
    if (user == null) return null;
    return _toSession(user);
  }

  @override
  Future<AuthSession?> signInWithGoogle() async {
    if (!isAvailable) {
      throw const AuthGatewayException(AuthError.unavailable);
    }
    _ensureAuthStateSubscription();
    if (!canAccountAuthorityBeGranted) {
      throw const AuthGatewayException(AuthError.recoveryBlocked);
    }

    try {
      final credentials = await _obtainGoogleCredentials();
      if (credentials == null) return null;
      if (credentials.idToken.isEmpty || credentials.accessToken.isEmpty) {
        throw const AuthGatewayException(AuthError.signInFailed);
      }

      // V1-R09 C1 â€” recovery may have become blocked during the Google picker.
      // Re-check before any SDK credential exchange starts.
      if (!canAccountAuthorityBeGranted) {
        throw const AuthGatewayException(AuthError.recoveryBlocked);
      }

      // V1-R09 C3 â€” credential-exchange quarantine. A still-unresolved
      // exchange (most commonly a timed-out one) must block a competing
      // second exchange.
      if (_credentialExchangeState.blocksNewExchange) {
        throw const AuthGatewayException(AuthError.retryableNetwork);
      }

      final coordinator = service.recoveryCoordinator;
      final isProductionExchange = _credentialExchange == null;

      // V1-R09 C3 — production credential exchange requires the accepted C1
      // recovery journal to be present. The injected-init test seam may bypass
      // recovery foundation; in that case the exchange runs without durable
      // recovery ownership (no journal, no restart survival).
      if (isProductionExchange && coordinator == null) {
        throw const AuthGatewayException(AuthError.recoveryBlocked);
      }

      // The human account-picker/consent interaction above is deliberately
      // unbounded. Only the Supabase network credential exchange is timed.
      final generation = _nextCredentialExchangeGeneration++;
      final projectIdentity =
          AuthRecoveryStorageCoordinator.projectIdentityFromUrl(
            service.config.supabaseUrl,
          );
      final placeholderCorrelation = SessionCorrelation(
        userId: 'credential-exchange-pending-$generation',
        projectIdentity: projectIdentity,
      );

      _startingExchange = true;
      AuthRecoveryJournalEntry? entry;
      try {
        if (coordinator != null) {
          final begun = await coordinator.beginOperation(
            type: AuthRecoveryOperationType.credentialExchange,
            phase: AuthRecoveryPhase.active,
            correlation: placeholderCorrelation,
          );
          if (!begun || _disposed) {
            throw const AuthGatewayException(AuthError.recoveryBlocked);
          }
          entry = coordinator.readRecoveryEntry();
          if (entry == null) {
            throw const AuthGatewayException(AuthError.recoveryBlocked);
          }
        }
      } finally {
        _startingExchange = false;
      }
      final operation = _CredentialExchangeOperation(
        generation: generation,
        operationId: entry?.operationId ?? _generateOperationId(),
        placeholderCorrelation: placeholderCorrelation,
      );

      return await _runCredentialExchange(operation, credentials);
    } on AuthGatewayException {
      rethrow;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw const AuthGatewayException(AuthError.signInFailed);
    } on AuthRetryableFetchException {
      throw const AuthGatewayException(AuthError.retryableNetwork);
    } on AuthException {
      // Provider/configuration/auth rejection is distinct from transport.
      throw const AuthGatewayException(AuthError.signInFailed);
    } catch (error) {
      final failure = classifyInfrastructureFailure(error);
      switch (failure.kind) {
        case InfrastructureFailureKind.offline:
        case InfrastructureFailureKind.timeout:
        case InfrastructureFailureKind.network:
        case InfrastructureFailureKind.serviceUnavailable:
          throw const AuthGatewayException(AuthError.retryableNetwork);
        case InfrastructureFailureKind.malformedResponse:
        case InfrastructureFailureKind.unknown:
          throw const AuthGatewayException(AuthError.unexpected);
      }
    }
  }

  Future<AuthSession?> _runCredentialExchange(
    _CredentialExchangeOperation operation,
    GoogleCredentialBundle credentials,
  ) async {
    _credentialExchangeState = _CredentialExchangeState(
      _ExchangePhase.active,
      operation,
    );
    operation.rawPending = true;
    final raw = _observeRawExchange(operation, credentials);
    _RawCredentialExchangeOutcome outcome;
    try {
      outcome = await raw.timeout(_credentialExchangeTimeout);
    } on TimeoutException {
      // CAS: the deadline can change ONLY this ACTIVE operation.
      if (_ownsExchange(operation, _ExchangePhase.active)) {
        _credentialExchangeState = _CredentialExchangeState(
          _ExchangePhase.timedOutPending,
          operation,
        );
        _emitExchangeRecoveryChanged();
        // Observe immediately, before the first journal await. The observer
        // owns persistence of the timeout phase and subsequent settlement.
        unawaited(_settleTimedOutExchange(operation, raw));
      }
      throw const AuthGatewayException(AuthError.retryableNetwork);
    }
    if (!_ownsExchange(operation, _ExchangePhase.active)) {
      throw const AuthGatewayException(AuthError.recoveryBlocked);
    }
    if (outcome is _RawFailure) {
      await _settleRawFailure(operation);
      throw AuthGatewayException(outcome.error);
    }
    // Raw success is terminal. Nothing in this separate processing scope can
    // be reclassified as raw failure or erase a potentially installed session.
    _credentialExchangeState = _CredentialExchangeState(
      _ExchangePhase.committing,
      operation,
    );
    try {
      return await _commitExchange(operation, outcome as _RawSuccess);
    } on AuthGatewayException {
      if (_ownsExchange(operation, _ExchangePhase.committing)) {
        await _blockExchange(operation, _SettlementFailure.validation);
      }
      rethrow;
    } catch (_) {
      await _blockExchange(operation, _SettlementFailure.processing);
      throw const AuthGatewayException(AuthError.recoveryBlocked);
    }
  }

  Future<_RawCredentialExchangeOutcome> _observeRawExchange(
    _CredentialExchangeOperation operation,
    GoogleCredentialBundle credentials,
  ) async {
    try {
      final injected = _credentialExchange;
      if (injected != null) {
        return _RawSuccess(
          injectedCandidate: await injected(
            idToken: credentials.idToken,
            accessToken: credentials.accessToken,
          ),
        );
      }
      // This try covers the raw SDK call ONLY, not response validation,
      // correlation upgrade, journal completion or neutralization.
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: credentials.idToken,
        accessToken: credentials.accessToken,
      );
      return _RawSuccess(response: response);
    } catch (error) {
      final network = classifyInfrastructureFailure(error);
      return _RawFailure(
        error is AuthRetryableFetchException ||
                network.kind == InfrastructureFailureKind.network ||
                network.kind == InfrastructureFailureKind.timeout ||
                network.kind == InfrastructureFailureKind.offline ||
                network.kind == InfrastructureFailureKind.serviceUnavailable
            ? AuthError.retryableNetwork
            : error is AuthGatewayException
            ? error.error
            : error is AuthException
            ? AuthError.signInFailed
            : AuthError.unexpected,
      );
    } finally {
      operation.rawPending = false;
    }
  }

  Future<GoogleCredentialBundle?> _obtainGoogleCredentials() async {
    final injected = _credentialsProvider;
    if (injected != null) return injected();

    final google = _googleSignIn ??= _googleSignInFactory();
    if (!_initialized) {
      await google.initialize(
        serverClientId: service.config.googleServerClientId,
      );
      _initialized = true;
    }

    final account = await google.authenticate(const []);
    // Scopes used by the official Supabase Flutter Google Sign-In guide.
    final authorization = await google.authorization(account, const [
      'email',
      'profile',
    ]);
    final idToken = account.authentication.idToken;
    if (idToken == null) return null;
    return GoogleCredentialBundle(
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
  }

  SessionCorrelation _entryCorrelation(AuthRecoveryJournalEntry entry) =>
      SessionCorrelation(
        userId: entry.userId,
        expiresAt: entry.expiresAt,
        sessionId: entry.sessionId,
        projectIdentity: entry.projectIdentity,
      );

  SessionCorrelation? _tryCaptureCurrentSessionCorrelation() {
    final current = _client.auth.currentSession;
    if (current == null) return null;
    try {
      return _captureCorrelation(current);
    } catch (_) {
      return null;
    }
  }

  bool _ownsExchange(
    _CredentialExchangeOperation operation, [
    _ExchangePhase? phase,
  ]) =>
      !_disposed &&
      identical(_credentialExchangeState.operation, operation) &&
      _credentialExchangeState.generation == operation.generation &&
      _credentialExchangeState.operation?.operationId ==
          operation.operationId &&
      (phase == null || _credentialExchangeState.phase == phase);

  bool _installedSessionMatches(SessionCorrelation exact) =>
      _tryCaptureCurrentSessionCorrelation()?.matches(exact) == true;

  bool _memoryAbsent() {
    // Only the legacy injected no-client test seam lacks an SDK singleton.
    if (_credentialExchange != null &&
        service.recoveryCoordinator == null &&
        _injectedClient == null)
      return true;
    return _client.auth.currentSession == null;
  }

  void _emitExchangeRecoveryChanged() {
    if (!_disposed && !_authEvents.isClosed) {
      _authEvents.add(const AuthEvent(type: AuthEventType.authRecoveryChanged));
    }
  }

  void _emitExchangeRecoveryCleared() {
    if (!_disposed && !_authEvents.isClosed) {
      _authEvents.add(
        const AuthEvent(type: AuthEventType.logoutCleanupCleared),
      );
    }
  }

  Future<void> _blockExchange(
    _CredentialExchangeOperation operation,
    _SettlementFailure reason, {
    bool unattributed = false,
  }) async {
    if (!_ownsExchange(operation)) return;
    _commitReceipt = null;
    final exact = _credentialExchangeState.exact;
    _credentialExchangeState = _CredentialExchangeState(
      unattributed
          ? _ExchangePhase.blockedUnattributed
          : _ExchangePhase.blockedCleanupFailure,
      operation,
      exact,
      reason,
    );
    _emitExchangeRecoveryChanged();
    final coordinator = service.recoveryCoordinator;
    if (coordinator == null) return;
    final result = await coordinator.runOwnedRecoveryOperation<bool>(
      expectedOperationId: operation.operationId,
      action: (tx) async {
        if (!_ownsExchange(operation)) return false;
        // Never lose durable remote-success evidence by replacing cleanupRequired.
        if (!unattributed) return true;
        return tx.updatePhase(AuthRecoveryPhase.blockedUnattributed);
      },
    );
    if (!_ownsExchange(operation)) return;
    if (result.value != true) {
      _recoveryRestriction = AuthRecoveryStatus.storageFailure;
      // Includes admission lost after an acknowledged completion. A durable
      // corrupt marker fails closed even when the completed entry is absent.
      await coordinator.markCorrupt(AuthRecoveryCorruptReason.writeFailure);
      if (_ownsExchange(operation)) _emitExchangeRecoveryChanged();
    }
  }

  Future<bool> _upgradeExchange(
    _CredentialExchangeOperation operation,
    SessionCorrelation exact,
    AuthRecoveryPhase phase,
  ) async {
    final coordinator = service.recoveryCoordinator;
    if (coordinator == null) return _credentialExchange != null;
    final upgraded = await coordinator.runOwnedRecoveryOperation<bool>(
      expectedOperationId: operation.operationId,
      action: (tx) async {
        if (!_ownsExchange(operation)) return false;
        return tx.upgradeCredentialCorrelation(exact, phase: phase);
      },
    );
    return _ownsExchange(operation) && upgraded.value == true;
  }

  (AuthSession, SessionCorrelation?) _validateRawSuccess(_RawSuccess raw) {
    if (raw.injectedCandidate != null) {
      final exact = service.recoveryCoordinator == null
          ? null
          : _credentialExchangeCorrelationProvider?.call();
      if (service.recoveryCoordinator != null &&
          (exact == null ||
              !exact.isSufficientForDestructiveCleanup ||
              exact.projectIdentity != _projectIdentity)) {
        throw const AuthGatewayException(AuthError.recoveryBlocked);
      }
      return (raw.injectedCandidate!, exact);
    }
    final response = raw.response!;
    final sdk = response.session;
    if (sdk == null ||
        response.user == null ||
        sdk.user.id != response.user!.id) {
      throw const AuthGatewayException(AuthError.recoveryBlocked);
    }
    final exact = _captureCorrelation(sdk);
    if (!exact.isSufficientForDestructiveCleanup ||
        exact.projectIdentity != _projectIdentity) {
      throw const AuthGatewayException(AuthError.recoveryBlocked);
    }
    return (_toSession(response.user!), exact);
  }

  bool _validCommit(
    _CredentialExchangeOperation operation,
    SessionCorrelation? exact, {
    required bool completed,
  }) {
    if (!_ownsExchange(operation, _ExchangePhase.committing) ||
        operation.rawPending ||
        !_authObservationAvailable ||
        _recoveryRestriction != AuthRecoveryStatus.none)
      return false;
    if (exact != null && !_installedSessionMatches(exact)) return false;
    final recovery = service.recoveryState;
    if (service.recoveryCoordinator == null) return _credentialExchange != null;
    if (completed) return recovery != null && !recovery.blocksAccountAuthority;
    final entry = recovery?.record;
    return entry?.operationId == operation.operationId &&
        entry?.operationType == AuthRecoveryOperationType.credentialExchange;
  }

  Future<AuthSession> _commitExchange(
    _CredentialExchangeOperation operation,
    _RawSuccess raw,
  ) async {
    final (candidate, exact) = _validateRawSuccess(raw);
    if (!_validCommit(operation, exact, completed: false)) {
      await _blockExchange(operation, _SettlementFailure.validation);
      throw const AuthGatewayException(AuthError.recoveryBlocked);
    }
    if (exact != null &&
        !await _upgradeExchange(
          operation,
          exact,
          AuthRecoveryPhase.committing,
        )) {
      await _blockExchange(operation, _SettlementFailure.journal);
      throw const AuthGatewayException(AuthError.recoveryBlocked);
    }
    if (!_validCommit(operation, exact, completed: false)) {
      await _blockExchange(operation, _SettlementFailure.validation);
      throw const AuthGatewayException(AuthError.recoveryBlocked);
    }
    _credentialExchangeState = _CredentialExchangeState(
      _ExchangePhase.committing,
      operation,
      exact,
    );
    if (_exchangeCheckpoint != null) {
      await _exchangeCheckpoint(
        CredentialExchangeCheckpoint.beforeCommitCompletion,
      );
    }
    if (!_validCommit(operation, exact, completed: false)) {
      await _blockExchange(operation, _SettlementFailure.validation);
      throw const AuthGatewayException(AuthError.recoveryBlocked);
    }
    final coordinator = service.recoveryCoordinator;
    final completed = coordinator == null
        ? true
        : (await coordinator.runOwnedRecoveryOperation<bool>(
                expectedOperationId: operation.operationId,
                expectedCorrelation: exact,
                action: (tx) async {
                  if (!_validCommit(operation, exact, completed: false))
                    return false;
                  return tx.complete();
                },
              )).value ==
              true;
    if (_exchangeCheckpoint != null) {
      await _exchangeCheckpoint(
        CredentialExchangeCheckpoint.afterCommitCompletion,
      );
    }
    if (!completed || !_validCommit(operation, exact, completed: true)) {
      await _blockExchange(
        operation,
        completed ? _SettlementFailure.validation : _SettlementFailure.journal,
      );
      throw const AuthGatewayException(AuthError.recoveryBlocked);
    }
    _commitReceipt = _CredentialCommitReceipt(
      this,
      operation,
      exact,
      candidate,
    );
    // Remain COMMITTING: ordinary SDK events cannot admit this candidate.
    return candidate;
  }

  @override
  bool consumeCredentialAdmission(AuthSession candidate) {
    final receipt = _commitReceipt;
    _commitReceipt = null; // single-use, including rejected consumption
    if (receipt == null ||
        !identical(receipt.owner, this) ||
        !identical(receipt.candidate, candidate) ||
        !_validCommit(
          receipt.operation,
          receipt.correlation,
          completed: true,
        )) {
      if (receipt != null && _ownsExchange(receipt.operation)) {
        // Block synchronously; persistence work is separately observed.
        unawaited(_observeCommitRejection(receipt.operation));
      }
      return false;
    }
    _credentialExchangeState = const _CredentialExchangeState.idle();
    return true; // Provider installs provisionally in this synchronous stack.
  }

  @override
  void rejectCredentialAdmission(AuthSession candidate) {
    final receipt = _commitReceipt;
    if (receipt == null || !identical(receipt.candidate, candidate)) return;
    _commitReceipt = null;
    unawaited(_observeCommitRejection(receipt.operation));
  }

  Future<void> _observeCommitRejection(
    _CredentialExchangeOperation operation,
  ) async {
    try {
      await _blockExchange(operation, _SettlementFailure.validation);
    } catch (_) {
      if (_ownsExchange(operation)) {
        _recoveryRestriction = AuthRecoveryStatus.storageFailure;
        _emitExchangeRecoveryChanged();
      }
    }
  }

  Future<void> _settleTimedOutExchange(
    _CredentialExchangeOperation operation,
    Future<_RawCredentialExchangeOutcome> raw,
  ) async {
    operation.settlementPending = true;
    try {
      final coordinator = service.recoveryCoordinator;
      if (coordinator != null) {
        final saved = await coordinator.runOwnedRecoveryOperation<bool>(
          expectedOperationId: operation.operationId,
          action: (tx) async {
            if (!_ownsExchange(operation, _ExchangePhase.timedOutPending)) {
              return false;
            }
            return tx.updatePhase(AuthRecoveryPhase.timedOutPending);
          },
        );
        if (!_ownsExchange(operation)) return;
        if (saved.value != true) {
          // Still observe raw; journal failure is not raw failure.
          await raw;
          await _blockExchange(operation, _SettlementFailure.journal);
          return;
        }
      }
      final outcome = await raw;
      if (!_ownsExchange(operation, _ExchangePhase.timedOutPending)) return;
      if (outcome is _RawFailure) {
        await _settleRawFailure(operation);
      } else {
        final (_, exact) = _validateRawSuccess(outcome as _RawSuccess);
        if (exact == null) {
          // Legacy no-SDK seam can prove empty memory, never infer an identity.
          await _settleRawFailure(operation);
          return;
        }
        if (_exchangeCheckpoint != null) {
          await _exchangeCheckpoint(
            CredentialExchangeCheckpoint.beforeLateUpgrade,
          );
        }
        if (!_ownsExchange(operation, _ExchangePhase.timedOutPending)) return;
        if (!await _upgradeExchange(
          operation,
          exact,
          AuthRecoveryPhase.neutralizing,
        )) {
          await _blockExchange(operation, _SettlementFailure.journal);
          return;
        }
        if (!_ownsExchange(operation)) return;
        _credentialExchangeState = _CredentialExchangeState(
          _ExchangePhase.neutralizing,
          operation,
          exact,
        );
        _emitExchangeRecoveryChanged();
        if (_exchangeCheckpoint != null) {
          await _exchangeCheckpoint(
            CredentialExchangeCheckpoint.afterLateUpgrade,
          );
        }
        if (!_ownsExchange(operation)) return;
        await _neutralizeExchange(operation, exact);
      }
    } catch (_) {
      await _observeProcessingFailure(operation);
    } finally {
      operation.settlementPending = false;
    }
  }

  Future<void> _observeProcessingFailure(
    _CredentialExchangeOperation operation,
  ) async {
    try {
      await _blockExchange(operation, _SettlementFailure.processing);
    } catch (_) {
      if (_ownsExchange(operation)) {
        _recoveryRestriction = AuthRecoveryStatus.storageFailure;
        _emitExchangeRecoveryChanged();
      }
    }
  }

  Future<AuthRecoveryResult> _settleRawFailure(
    _CredentialExchangeOperation operation,
  ) async {
    if (!_ownsExchange(operation) || operation.rawPending) {
      return AuthRecoveryResult.busy;
    }
    final coordinator = service.recoveryCoordinator;
    if (coordinator == null) {
      if (_memoryAbsent()) return _exchangeCleanGuest(operation);
      await _blockExchange(
        operation,
        _SettlementFailure.unattributed,
        unattributed: true,
      );
      return AuthRecoveryResult.blocked;
    }
    final verified = await coordinator.runOwnedRecoveryOperation<bool>(
      expectedOperationId: operation.operationId,
      action: (tx) async {
        if (!_ownsExchange(operation) ||
            operation.rawPending ||
            !_memoryAbsent())
          return false;
        final snapshot = await tx.readRecoverySnapshot();
        // An awaited read may race a new SDK memory installation.
        if (!_ownsExchange(operation) ||
            operation.rawPending ||
            !_memoryAbsent() ||
            snapshot != null)
          return false;
        return tx.complete();
      },
    );
    if (!_ownsExchange(operation)) return AuthRecoveryResult.blocked;
    if (verified.value == true &&
        _memoryAbsent() &&
        !coordinator.readRecoveryState().blocksAccountAuthority) {
      return _exchangeCleanGuest(operation);
    }
    await _blockExchange(
      operation,
      _SettlementFailure.unattributed,
      unattributed: true,
    );
    return AuthRecoveryResult.blocked;
  }

  AuthRecoveryResult _exchangeCleanGuest(
    _CredentialExchangeOperation operation,
  ) {
    if (!_ownsExchange(operation) || operation.rawPending) {
      return AuthRecoveryResult.blocked;
    }
    _commitReceipt = null;
    _credentialExchangeState = const _CredentialExchangeState.idle();
    _recoveryRestriction = AuthRecoveryStatus.none;
    _emitExchangeRecoveryCleared();
    return AuthRecoveryResult.cleanGuest;
  }

  _OutboundSignOut _exchangeCleanupOperation(
    _CredentialExchangeOperation operation,
    SessionCorrelation exact,
  ) {
    final existing = _outboundSignOut;
    if (existing != null &&
        existing.operationId == operation.operationId &&
        identical(existing.exchangeOwner, operation))
      return existing;
    return _outboundSignOut = _OutboundSignOut(
      epoch: ++_outboundEpoch,
      operationId: operation.operationId,
      correlation: exact,
      exchangeOwner: operation,
    );
  }

  Future<AuthRecoveryResult> _neutralizeExchange(
    _CredentialExchangeOperation operation,
    SessionCorrelation exact,
  ) async {
    if (!_ownsExchange(operation) || operation.rawPending) {
      return AuthRecoveryResult.busy;
    }
    final work = _exchangeCleanupOperation(operation, exact);
    if (work.remotePending || work.rawCleanupPending || work.localWorkPending) {
      return AuthRecoveryResult.busy;
    }
    final coordinator = service.recoveryCoordinator!;
    final entry = coordinator.readRecoveryEntry();
    if (entry?.operationId != operation.operationId) {
      return AuthRecoveryResult.blocked;
    }
    // cleanupRequired is durable proof of remote success: never revoke twice.
    if (entry?.phase == AuthRecoveryPhase.cleanupRequired ||
        entry?.phase == AuthRecoveryPhase.blockedCleanupFailure) {
      return _attemptLocalCleanup(work);
    }
    // Reserve before any await. Token is ephemeral to this stack/HTTP call.
    work.remotePending = true;
    String? token;
    try {
      final inspected = await coordinator.runOwnedRecoveryOperation<bool>(
        expectedOperationId: operation.operationId,
        expectedCorrelation: exact,
        action: (tx) async {
          if (!_ownsExchange(operation) || !_currentSessionMatches(work)) {
            return false;
          }
          final snapshotState = await tx.inspectRecoverySnapshot();
          if (!_ownsExchange(operation) ||
              !_currentSessionMatches(work) ||
              snapshotState == RecoverySnapshotState.blocked)
            return false;
          final current = _client.auth.currentSession;
          if (current != null) {
            token = current.accessToken;
            return true;
          }
          if (snapshotState == RecoverySnapshotState.absent) return true;
          final snapshot = await tx.readRecoverySnapshot();
          if (!_ownsExchange(operation) ||
              !_currentSessionMatches(work) ||
              snapshot == null)
            return false;
          final session = Session.fromJson(jsonDecode(snapshot));
          if (session == null || !_captureCorrelation(session).matches(exact)) {
            return false;
          }
          token = session.accessToken;
          return true;
        },
      );
      if (!_ownsExchange(operation)) return AuthRecoveryResult.blocked;
      if (inspected.value != true || !_currentSessionMatches(work)) {
        work.remotePending = false;
        // Exact A does not license signOut(current B) or deleting B.
        await _blockExchange(
          operation,
          _SettlementFailure.validation,
          unattributed: true,
        );
        return AuthRecoveryResult.blocked;
      }
      if (token == null) {
        work.remotePending = false;
        // Both absent: no SDK signOut, remote revoke or persistence deletion.
        return _settleRawFailure(operation);
      }
      final raw = _performAdminSignOut(token!);
      token = null;
      // The normalizing remote helper and this observer are attached before
      // any deadline wait. No recovery queue is held during HTTP.
      final settlement = _observeExchangeRemote(operation, work, raw);
      return await settlement.timeout(
        _signOutTimeout,
        onTimeout: () {
          if (_ownsExchange(operation)) {
            _credentialExchangeState = _CredentialExchangeState(
              _ExchangePhase.blockedCleanupFailure,
              operation,
              exact,
              _SettlementFailure.remoteRevoke,
            );
            _emitExchangeRecoveryChanged();
          }
          return AuthRecoveryResult.blocked;
        },
      );
    } catch (_) {
      work.remotePending = false;
      await _observeProcessingFailure(operation);
      return AuthRecoveryResult.blocked;
    }
  }

  Future<AuthRecoveryResult> _observeExchangeRemote(
    _CredentialExchangeOperation operation,
    _OutboundSignOut work,
    Future<bool> raw,
  ) async {
    try {
      final succeeded = await raw;
      if (!_ownsExchange(operation) || !_isCurrentOperation(work)) {
        return AuthRecoveryResult.blocked;
      }
      if (!succeeded) {
        work.remotePending = false;
        // Keep NEUTRALIZING durable (remote not proven). Explicit retry only.
        _credentialExchangeState = _CredentialExchangeState(
          _ExchangePhase.blockedCleanupFailure,
          operation,
          work.correlation,
          _SettlementFailure.remoteRevoke,
        );
        _emitExchangeRecoveryChanged();
        return AuthRecoveryResult.blocked;
      }
      final saved = await service.recoveryCoordinator!
          .runOwnedRecoveryOperation<bool>(
            expectedOperationId: operation.operationId,
            expectedCorrelation: work.correlation,
            action: (tx) async {
              if (!_ownsExchange(operation)) return false;
              return tx.updatePhase(AuthRecoveryPhase.cleanupRequired);
            },
          );
      if (!_ownsExchange(operation)) return AuthRecoveryResult.blocked;
      if (saved.value != true) {
        work.remotePending = false;
        await _blockExchange(operation, _SettlementFailure.journal);
        return AuthRecoveryResult.blocked;
      }
      if (_exchangeCheckpoint != null) {
        await _exchangeCheckpoint(
          CredentialExchangeCheckpoint.remoteSuccessBeforeCleanup,
        );
      }
      if (!_ownsExchange(operation)) return AuthRecoveryResult.blocked;
      work.remotePending = false;
      return _attemptLocalCleanup(work); // accepted C2 implementation
    } catch (_) {
      work.remotePending = false;
      await _observeProcessingFailure(operation);
      return AuthRecoveryResult.blocked;
    }
  }

  // --------------------------------------------------------------------------
  // V1-R09 H1 / M1 â€” remote-first authoritative sign-out helpers
  // --------------------------------------------------------------------------

  Future<void> _remoteRevoke() async {
    final revoke = _remoteSignOut ?? _defaultRemoteSignOut;
    await revoke();
  }

  /// Public GoTrue "/auth/v1/logout?scope=local" remote revocation using the
  /// captured access token through the OFFICIAL admin API on the SAME client.
  ///
  /// This is the remote half of authoritative sign-out. A 2xx (or an already
  /// invalid/expired token: 401/403/404) means the remote token is no longer an
  /// authoritative issue for this session; any other terminal/transport failure
  /// surfaces as a typed non-success.
  @visibleForTesting
  Future<bool> _performAdminSignOut(String accessToken) async {
    try {
      await _client.auth.admin.signOut(accessToken, scope: SignOutScope.local);
      return true;
    } on AuthException catch (error) {
      // 401/403/404 mean the token is already invalid or the session is gone â€”
      // an authoritative remote state for this session.
      final status = error.statusCode;
      if (status == '401' || status == '403' || status == '404') {
        return true;
      }
      return false;
    } on AuthUnknownException {
      return false;
    } on AuthRetryableFetchException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Default remote revocation used by H3 neutralization of stale sessions,
  /// routed through the same official admin API and the current token.
  Future<void> _defaultRemoteSignOut() async {
    final accessToken = _client.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      // Nothing authoritative to revoke remotely; local-only clear is enough.
      return;
    }
    if (!await _performAdminSignOut(accessToken)) {
      throw const AuthGatewayException(AuthError.signOutFailed);
    }
  }

  Future<void> _clearLocalSession() async {
    // The installed public SDK clears memory/emits before a redundant remote
    // call. Flutter persistence is separately observed by the guarded adapter.
    final clear = _localSignOut;
    if (clear != null) {
      await clear();
    } else {
      await _client.auth.signOut(scope: SignOutScope.local);
    }
  }

  Future<void> _boundedGoogleSignOut() async {
    try {
      final google = _googleSignIn ??= _googleSignInFactory();
      if (!_initialized) {
        await google
            .initialize(serverClientId: service.config.googleServerClientId)
            .timeout(_googleSignOutTimeout);
        _initialized = true;
      }
      await google.signOut().timeout(_googleSignOutTimeout);
    } on TimeoutException {
      // Best-effort cleanup stalled; the canonical session is already gone.
    } catch (_) {
      // Non-fatal: Supabase is the session authority.
    }
  }

  @override
  Future<void> signOut() async {
    if (!isAvailable) {
      throw const AuthGatewayException(AuthError.signOutFailed);
    }
    if (!canAccountAuthorityBeGranted) {
      throw const AuthGatewayException(AuthError.recoveryBlocked);
    }
    _ensureAuthStateSubscription();
    final coordinator = service.recoveryCoordinator;
    if (coordinator == null) {
      throw const AuthGatewayException(AuthError.recoveryBlocked);
    }
    final session = _client.auth.currentSession;
    if (session == null) {
      await _boundedGoogleSignOut();
      return;
    }
    final correlation = _captureCorrelation(session);
    if (!correlation.isSufficientForDestructiveCleanup ||
        session.accessToken.isEmpty) {
      throw const AuthGatewayException(AuthError.recoveryBlocked);
    }
    final begun = await coordinator.beginOperation(
      type: AuthRecoveryOperationType.signOut,
      phase: AuthRecoveryPhase.remotePending,
      correlation: correlation,
    );
    final entry = coordinator.readRecoveryEntry();
    if (!begun || entry == null) {
      throw const AuthGatewayException(AuthError.recoveryBlocked);
    }
    final operation = _OutboundSignOut(
      epoch: ++_outboundEpoch,
      operationId: entry.operationId,
      correlation: correlation,
    );
    _outboundSignOut = operation;
    final remote = _performAdminSignOut(session.accessToken);
    operation.remotePending = true;
    try {
      final succeeded = await remote.timeout(_signOutTimeout);
      operation.remotePending = false;
      final result = await _settleRemote(operation, succeeded);
      if (!succeeded) {
        throw AuthGatewayException(
          result == AuthRecoveryResult.blocked
              ? AuthError.unexpected
              : AuthError.signOutFailed,
        );
      }
    } on TimeoutException {
      _watchRemote(operation, remote);
      throw const AuthGatewayException(AuthError.retryableNetwork);
    }
  }

  SessionCorrelation _captureCorrelation(Session session) =>
      SessionCorrelation.fromSessionJson(
        jsonEncode(session.toJson()),
        projectIdentity: _projectIdentity,
      );

  String _generateOperationId() {
    final now = DateTime.now().toUtc();
    final rand = Random().nextInt(0x7fffffff);
    return '${now.millisecondsSinceEpoch}_$rand';
  }

  bool _isCurrentOperation(_OutboundSignOut operation) =>
      !_disposed &&
      identical(_outboundSignOut, operation) &&
      operation.epoch == _outboundEpoch &&
      (operation.exchangeOwner == null ||
          _ownsExchange(operation.exchangeOwner!));

  bool _currentSessionMatches(_OutboundSignOut operation) {
    final current = _client.auth.currentSession;
    if (current == null) return true;
    try {
      return _captureCorrelation(current).matches(operation.correlation);
    } catch (_) {
      return false;
    }
  }

  void _emitRecovery(_OutboundSignOut operation, AuthEventType type) {
    if (!_isCurrentOperation(operation) || _authEvents.isClosed) return;
    _authEvents.add(AuthEvent(type: type, operationId: operation.operationId));
  }

  void _storageFailure(_OutboundSignOut operation) {
    if (!_isCurrentOperation(operation)) return;
    _recoveryRestriction = AuthRecoveryStatus.storageFailure;
    _emitRecovery(operation, AuthEventType.authRecoveryChanged);
  }

  void _watchRemote(_OutboundSignOut operation, Future<bool> remote) {
    // This observer owns the late result, never an escaped transaction/token.
    unawaited(() async {
      try {
        final succeeded = await remote;
        operation.remotePending = false;
        if (_isCurrentOperation(operation)) {
          await _settleRemote(operation, succeeded);
        }
      } catch (_) {
        _storageFailure(operation);
      }
    }());
  }

  Future<AuthRecoveryResult> _settleRemote(
    _OutboundSignOut operation,
    bool succeeded,
  ) async {
    if (!_isCurrentOperation(operation) || operation.remoteHandled) {
      return AuthRecoveryResult.blocked;
    }
    operation.remoteHandled = true;
    final coordinator = service.recoveryCoordinator!;
    if (succeeded) {
      final updated = await coordinator.updateOwnedOperation(
        expectedOperationId: operation.operationId,
        expectedCorrelation: operation.correlation,
        phase: AuthRecoveryPhase.cleanupRequired,
      );
      // Even a failed journal write cannot resurrect remotely revoked authority.
      if (!updated) _storageFailure(operation);
      _emitRecovery(operation, AuthEventType.logoutCleanupRequired);
      if (!updated) return AuthRecoveryResult.blocked;
      return _attemptLocalCleanup(operation);
    }

    // Live failure retains previously admitted authority. Restart recovery has
    // no admitted account, and must use normal restoration on a later startup.
    final finalized = await coordinator.runOwnedRecoveryOperation<bool>(
      expectedOperationId: operation.operationId,
      expectedCorrelation: operation.correlation,
      action: (tx) async {
        if (operation.restartRecovery &&
            (!_currentSessionMatches(operation) ||
                await tx.inspectRecoverySnapshot() !=
                    RecoverySnapshotState.matching)) {
          return false;
        }
        return tx.complete();
      },
    );
    if (!finalized.allowed || finalized.value != true) {
      _storageFailure(operation);
      return AuthRecoveryResult.blocked;
    }
    if (operation.restartRecovery) {
      _recoveryRestriction = AuthRecoveryStatus.restartRequired;
      _emitRecovery(operation, AuthEventType.authRecoveryChanged);
      return AuthRecoveryResult.restartRequired;
    }
    return AuthRecoveryResult.retainedSession; // Failure, NOT a clean logout.
  }

  Future<AuthRecoveryResult> _blockCleanup(
    _OutboundSignOut operation,
    AuthRecoveryTransaction tx,
  ) async {
    if (!await tx.updatePhase(AuthRecoveryPhase.blockedCleanupFailure)) {
      _storageFailure(operation);
    }
    return AuthRecoveryResult.blocked;
  }

  Future<bool> _observeRawCleanup(_OutboundSignOut operation) async {
    try {
      await _clearLocalSession();
      return true;
    } catch (_) {
      // Normalize synchronous invocation errors and late asynchronous failures.
      return false;
    } finally {
      operation.rawCleanupPending = false;
    }
  }

  Future<AuthRecoveryResult> _runLocalCleanup(
    _OutboundSignOut operation,
  ) async {
    final coordinator = service.recoveryCoordinator!;
    final ready = await coordinator.runOwnedRecoveryOperation<bool>(
      expectedOperationId: operation.operationId,
      expectedCorrelation: operation.correlation,
      action: (tx) async {
        if (await tx.inspectRecoverySnapshot() ==
                RecoverySnapshotState.blocked ||
            !_isCurrentOperation(operation) ||
            !_currentSessionMatches(operation)) {
          await _blockCleanup(operation, tx);
          return false;
        }
        // No installed session: never ask the SDK to emit a destructive logout.
        if (_client.auth.currentSession == null) return true;
        var completed = false;
        await tx.runOwnedSdkLocalCleanup(
          () async {
            // All preflight awaits are over. Revalidate immediately before the
            // SDK synchronously clears its currentSession.
            if (!_isCurrentOperation(operation) ||
                !_currentSessionMatches(operation))
              return;
            if (_client.auth.currentSession == null) {
              completed = true;
              return;
            }
            operation.rawCleanupPending = true;
            final raw = _observeRawCleanup(operation);
            operation.rawCleanup = raw;
            try {
              await raw.timeout(_signOutTimeout);
              completed = true;
              // Installed SDK emits before the raw future settles. Yield one
              // event-loop turn so its unpaused asynchronous persistence listener
              // registers all preceding SDK events under the guarded boundary.
              await Future<void>.delayed(Duration.zero);
            } on TimeoutException {
              _watchLocalRaw(operation, raw);
            }
          },
          canRemove: () =>
              _isCurrentOperation(operation) &&
              _client.auth.currentSession == null,
        );
        return completed;
      },
    );
    if (!ready.allowed || ready.value != true) {
      if (coordinator.readRecoveryState().status ==
          AuthRecoveryStartupStatus.corrupt)
        _storageFailure(operation);
      return AuthRecoveryResult.blocked;
    }
    // Fresh slot: SDK persistence writes queued during the first slot run
    // BEFORE verification. Never close the journal ahead of them.
    return _verifyLocalCleanup(operation);
  }

  Future<AuthRecoveryResult> _verifyLocalCleanup(
    _OutboundSignOut operation,
  ) async {
    if (!_isCurrentOperation(operation) || operation.rawCleanupPending) {
      return AuthRecoveryResult.blocked;
    }
    final result = await service.recoveryCoordinator!
        .runOwnedRecoveryOperation<AuthRecoveryResult>(
          expectedOperationId: operation.operationId,
          expectedCorrelation: operation.correlation,
          action: (tx) async {
            if (await tx.inspectRecoverySnapshot() ==
                    RecoverySnapshotState.blocked ||
                !_isCurrentOperation(operation) ||
                _client.auth.currentSession != null) {
              return _blockCleanup(operation, tx);
            }
            if (!await tx.removeMatchingRecoverySnapshot(
              canRemove: () =>
                  _isCurrentOperation(operation) &&
                  _client.auth.currentSession == null,
            )) {
              return _blockCleanup(operation, tx);
            }
            if (await tx.inspectRecoverySnapshot() !=
                    RecoverySnapshotState.absent ||
                !_isCurrentOperation(operation) ||
                _client.auth.currentSession != null) {
              return _blockCleanup(operation, tx);
            }
            if (!await tx.complete()) {
              _storageFailure(operation);
              return AuthRecoveryResult.blocked;
            }
            return AuthRecoveryResult.cleanGuest;
          },
        );
    if (operation.exchangeOwner != null &&
        result.value == AuthRecoveryResult.cleanGuest &&
        (!_isCurrentOperation(operation) ||
            !_memoryAbsent() ||
            service.recoveryState?.blocksAccountAuthority != false)) {
      if (_isCurrentOperation(operation)) {
        await _blockExchange(
          operation.exchangeOwner!,
          _SettlementFailure.validation,
          unattributed: true,
        );
      }
      return AuthRecoveryResult.blocked;
    }
    return result.value ?? AuthRecoveryResult.blocked;
  }

  void _publishLocalOutcome(
    _OutboundSignOut operation,
    AuthRecoveryResult result,
  ) {
    if (!_isCurrentOperation(operation) || operation.cleanupFinalized) return;
    final exchange = operation.exchangeOwner;
    if (exchange != null) {
      if (result == AuthRecoveryResult.cleanGuest) {
        operation.cleanupFinalized = true;
        _exchangeCleanGuest(exchange);
      } else if (_ownsExchange(exchange)) {
        _credentialExchangeState = _CredentialExchangeState(
          _ExchangePhase.blockedCleanupFailure,
          exchange,
          operation.correlation,
          _SettlementFailure.localCleanup,
        );
        _emitExchangeRecoveryChanged();
      }
      return;
    }
    if (result == AuthRecoveryResult.cleanGuest) {
      operation.cleanupFinalized = true;
      _recoveryRestriction = AuthRecoveryStatus.none;
    }
    _emitRecovery(
      operation,
      result == AuthRecoveryResult.cleanGuest
          ? AuthEventType.logoutCleanupCleared
          : AuthEventType.logoutCleanupRequired,
    );
    if (!operation.googleCleanupStarted) {
      operation.googleCleanupStarted = true;
      unawaited(_boundedGoogleSignOut());
    }
  }

  Future<AuthRecoveryResult> _observeLocalWork(
    _OutboundSignOut operation,
  ) async {
    try {
      final result = await _runLocalCleanup(operation);
      _publishLocalOutcome(operation, result);
      return result;
    } catch (_) {
      _storageFailure(operation);
      _publishLocalOutcome(operation, AuthRecoveryResult.blocked);
      return AuthRecoveryResult.blocked;
    } finally {
      operation.localWorkPending = false;
    }
  }

  Future<AuthRecoveryResult> _attemptLocalCleanup(
    _OutboundSignOut operation,
  ) async {
    if (operation.rawCleanupPending || operation.localWorkPending) {
      return AuthRecoveryResult.blocked;
    }
    operation.localWorkPending = true;
    final work = _observeLocalWork(operation);
    operation.localWork = work;
    try {
      return await work.timeout(_signOutTimeout);
    } on TimeoutException {
      // UI deadline is separate from serialization: an already-started storage
      // mutation retains its queue slot until settled. The observer owns it.
      _publishLocalOutcome(operation, AuthRecoveryResult.blocked);
      return AuthRecoveryResult.blocked;
    }
  }

  void _watchLocalRaw(_OutboundSignOut operation, Future<bool> raw) {
    unawaited(() async {
      try {
        await raw;
        await Future<void>.delayed(Duration.zero);
        // The original transaction must drain delegate work and exit first.
        final work = operation.localWork;
        if (work != null) await work;
        if (!_isCurrentOperation(operation) || operation.cleanupFinalized)
          return;
        final result = await _verifyLocalCleanup(operation);
        _publishLocalOutcome(operation, result);
      } catch (_) {
        _storageFailure(operation);
      }
    }());
  }

  @override
  AuthRecoveryStatus get recoveryStatus {
    if (_recoveryRestriction != AuthRecoveryStatus.none) {
      return _recoveryRestriction;
    }

    final live = switch (_credentialExchangeState.phase) {
      _ExchangePhase.idle ||
      _ExchangePhase.active ||
      _ExchangePhase.committing => null,
      _ExchangePhase.timedOutPending =>
        AuthRecoveryStatus.exchangeTimedOutPending,
      _ExchangePhase.neutralizing => AuthRecoveryStatus.exchangeNeutralizing,
      _ExchangePhase.blockedCleanupFailure =>
        AuthRecoveryStatus.exchangeBlockedCleanupFailure,
      _ExchangePhase.blockedUnattributed =>
        AuthRecoveryStatus.exchangeBlockedUnattributed,
      _ExchangePhase.localResetRestartRequired =>
        AuthRecoveryStatus.localResetRestartRequired,
    };
    if (live != null) return live;
    if (_startingExchange || !_credentialExchangeState.isIdle) {
      return AuthRecoveryStatus
          .none; // active/committing is busy, not retryable
    }

    final entry = service.recoveryState?.record;
    if (entry == null) return AuthRecoveryStatus.none;

    return switch (entry.operationType) {
      AuthRecoveryOperationType.signOut => switch (entry.phase) {
        AuthRecoveryPhase.remotePending => AuthRecoveryStatus.remotePending,
        AuthRecoveryPhase.cleanupRequired => AuthRecoveryStatus.cleanupRequired,
        _ => AuthRecoveryStatus.blockedCleanupFailure,
      },
      AuthRecoveryOperationType.credentialExchange => switch (entry.phase) {
        AuthRecoveryPhase.active || AuthRecoveryPhase.timedOutPending =>
          AuthRecoveryStatus.exchangeTimedOutPending,
        AuthRecoveryPhase.blockedUnattributed =>
          AuthRecoveryStatus.exchangeBlockedUnattributed,
        AuthRecoveryPhase.localResetAppliedRestartRequired =>
          AuthRecoveryStatus.localResetRestartRequired,
        AuthRecoveryPhase.neutralizing =>
          AuthRecoveryStatus.exchangeNeutralizing,
        AuthRecoveryPhase.blockedCleanupFailure =>
          AuthRecoveryStatus.exchangeBlockedCleanupFailure,
        _ => AuthRecoveryStatus.exchangeBlockedCleanupFailure,
      },
    };
  }

  @override
  bool get isLogoutCleanupBlocked => recoveryStatus != AuthRecoveryStatus.none;

  @override
  Future<bool> retryAuthCleanup() async =>
      await retryAuthRecovery() == AuthRecoveryResult.cleanGuest;

  @override
  Future<AuthRecoveryResult> retryAuthRecovery() async {
    if (_startingExchange ||
        _credentialExchangeState.phase == _ExchangePhase.active ||
        _credentialExchangeState.phase == _ExchangePhase.committing ||
        (_credentialExchangeState.operation?.rawPending ?? false) ||
        (_credentialExchangeState.operation?.settlementPending ?? false) ||
        _deviceResetFuture != null)
      return AuthRecoveryResult.busy;
    if (_disposed || !isAvailable || !_authObservationAvailable) {
      return AuthRecoveryResult.blocked;
    }
    if (_recoveryRestriction == AuthRecoveryStatus.restartRequired) {
      return AuthRecoveryResult.restartRequired;
    }
    final pending = _cleanupRetryFuture;
    if (pending != null) return pending;
    final future = _performPhaseAwareRetry();
    _cleanupRetryFuture = future;
    try {
      return await future;
    } catch (_) {
      final operation = _outboundSignOut;
      if (operation != null) _storageFailure(operation);
      return AuthRecoveryResult.blocked;
    } finally {
      _cleanupRetryFuture = null;
    }
  }

  Future<AuthRecoveryResult> _performPhaseAwareRetry() async {
    final coordinator = service.recoveryCoordinator;
    final entry = coordinator?.readRecoveryEntry();
    if (coordinator == null || entry == null) {
      return AuthRecoveryResult.blocked;
    }

    return switch (entry.operationType) {
      AuthRecoveryOperationType.signOut => _performSignOutPhaseAwareRetry(
        coordinator,
        entry,
      ),
      AuthRecoveryOperationType.credentialExchange =>
        _performCredentialExchangePhaseAwareRetry(coordinator, entry),
    };
  }

  Future<AuthRecoveryResult> _performSignOutPhaseAwareRetry(
    AuthRecoveryStorageCoordinator coordinator,
    AuthRecoveryJournalEntry entry,
  ) async {
    final correlation = SessionCorrelation(
      userId: entry.userId,
      expiresAt: entry.expiresAt,
      sessionId: entry.sessionId,
      projectIdentity: entry.projectIdentity,
    );
    if (!correlation.isSufficientForDestructiveCleanup) {
      return AuthRecoveryResult.blocked;
    }
    var operation = _outboundSignOut;
    if (operation == null || operation.operationId != entry.operationId) {
      operation = _OutboundSignOut(
        epoch: ++_outboundEpoch,
        operationId: entry.operationId,
        correlation: correlation,
        restartRecovery: true,
      );
      _outboundSignOut = operation;
    }
    if (operation.remotePending ||
        operation.rawCleanupPending ||
        operation.localWorkPending)
      return AuthRecoveryResult.blocked;

    switch (entry.phase) {
      case AuthRecoveryPhase.remotePending:
        return _retryRemotePendingSignOut(operation);
      case AuthRecoveryPhase.cleanupRequired:
      case AuthRecoveryPhase.blockedCleanupFailure:
        return _attemptLocalCleanup(operation);
      default:
        return AuthRecoveryResult.blocked;
    }
  }

  Future<AuthRecoveryResult> _performCredentialExchangePhaseAwareRetry(
    AuthRecoveryStorageCoordinator coordinator,
    AuthRecoveryJournalEntry entry,
  ) async {
    final operation = _credentialExchangeState.operation;
    if (operation == null ||
        !_ownsExchange(operation) ||
        entry.operationId != operation.operationId) {
      return AuthRecoveryResult.blocked; // IDLE never starts a C3 operation
    }
    if (operation.rawPending ||
        operation.settlementPending ||
        _credentialExchangeState.phase == _ExchangePhase.active ||
        _credentialExchangeState.phase == _ExchangePhase.committing) {
      return AuthRecoveryResult.busy;
    }
    if (entry.phase == AuthRecoveryPhase.localResetAppliedRestartRequired) {
      if (!operation.reconstructed || operation.resetAppliedHere) {
        return AuthRecoveryResult.restartRequired;
      }
      // Fresh normal SDK startup, no raw mutation exists in this process.
      return _settleRawFailure(operation);
    }
    if (entry.phase == AuthRecoveryPhase.blockedUnattributed) {
      if (operation.resetAppliedHere) return AuthRecoveryResult.blocked;
      // Inspection may establish absence, NEVER infer ownership from account
      // hints or sign out unknown memory. Explicit reset is the sole exception.
      return _settleRawFailure(operation);
    }
    final exact = _entryCorrelation(entry);
    if (!exact.isSufficientForDestructiveCleanup ||
        exact.projectIdentity != _projectIdentity) {
      return _settleRawFailure(operation);
    }
    if (entry.phase == AuthRecoveryPhase.committing) {
      final saved = await coordinator.updateOwnedOperation(
        expectedOperationId: operation.operationId,
        expectedCorrelation: exact,
        phase: AuthRecoveryPhase.neutralizing,
      );
      if (!_ownsExchange(operation) || !saved) {
        await _blockExchange(operation, _SettlementFailure.journal);
        return AuthRecoveryResult.blocked;
      }
    }
    _credentialExchangeState = _CredentialExchangeState(
      _ExchangePhase.neutralizing,
      operation,
      exact,
    );
    _emitExchangeRecoveryChanged();
    return _neutralizeExchange(operation, exact);
  }

  @override
  Future<AuthRecoveryResult> resetQuarantinedDeviceSignIn() async {
    final operation = _credentialExchangeState.operation;
    final coordinator = service.recoveryCoordinator;
    if (_disposed ||
        operation == null ||
        coordinator == null ||
        !_ownsExchange(operation, _ExchangePhase.blockedUnattributed) ||
        operation.rawPending ||
        operation.settlementPending ||
        _cleanupRetryFuture != null)
      return AuthRecoveryResult.blocked;
    final existing = _deviceResetFuture;
    if (existing != null) return AuthRecoveryResult.busy;
    operation.resetAppliedHere = true;
    final raw = _observeDeviceReset(operation, coordinator);
    _deviceResetFuture = raw;
    // A stalled delegate retains serialization and ownership, but not the UI.
    return raw.timeout(
      _signOutTimeout,
      onTimeout: () => AuthRecoveryResult.blocked,
    );
  }

  Future<AuthRecoveryResult> _observeDeviceReset(
    _CredentialExchangeOperation operation,
    AuthRecoveryStorageCoordinator coordinator,
  ) async {
    try {
      final reset = await coordinator
          .runOwnedRecoveryOperation<QuarantinedResetResult>(
            expectedOperationId: operation.operationId,
            action: (tx) async {
              if (!_ownsExchange(
                operation,
                _ExchangePhase.blockedUnattributed,
              )) {
                return QuarantinedResetResult.denied;
              }
              return tx.resetQuarantinedSnapshot();
            },
          );
      if (!_ownsExchange(operation)) return AuthRecoveryResult.blocked;
      if (reset.value != QuarantinedResetResult.applied) {
        _credentialExchangeState = _CredentialExchangeState(
          _ExchangePhase.blockedUnattributed,
          operation,
          null,
          _SettlementFailure.localReset,
        );
        _emitExchangeRecoveryChanged();
        return AuthRecoveryResult.blocked;
      }
      operation.resetAppliedHere = true;
      _credentialExchangeState = _CredentialExchangeState(
        _ExchangePhase.localResetRestartRequired,
        operation,
        null,
        _SettlementFailure.restartRequired,
      );
      _emitExchangeRecoveryChanged();
      return AuthRecoveryResult.restartRequired;
    } catch (_) {
      if (_ownsExchange(operation)) _emitExchangeRecoveryChanged();
      return AuthRecoveryResult.blocked;
    } finally {
      _deviceResetFuture = null;
    }
  }

  Future<AuthRecoveryResult> _retryRemotePendingSignOut(
    _OutboundSignOut operation,
  ) async {
    Future<bool>? remote;
    final launched = await service.recoveryCoordinator!
        .runOwnedRecoveryOperation<bool>(
          expectedOperationId: operation.operationId,
          expectedCorrelation: operation.correlation,
          action: (tx) async {
            if (await tx.inspectRecoverySnapshot() !=
                    RecoverySnapshotState.matching ||
                !_currentSessionMatches(operation))
              return false;
            // Raw JSON and Session remain local to this owned callback. Public
            // parsing has no SDK/session/provider mutation side effect.
            final snapshot = await tx.readRecoverySnapshot();
            try {
              if (snapshot == null) return false;
              final json = jsonDecode(snapshot);
              if (json is! Map<String, dynamic>) return false;
              final session = Session.fromJson(json);
              if (session == null ||
                  session.accessToken.isEmpty ||
                  !_captureCorrelation(
                    session,
                  ).matches(operation.correlation) ||
                  !_currentSessionMatches(operation))
                return false;
              operation.remoteHandled = false;
              operation.remotePending = true;
              remote = _performAdminSignOut(session.accessToken);
              return true;
            } catch (_) {
              return false;
            }
          },
        );
    if (!launched.allowed || launched.value != true || remote == null) {
      return AuthRecoveryResult.blocked;
    }
    try {
      final succeeded = await remote!.timeout(_signOutTimeout);
      operation.remotePending = false;
      return await _settleRemote(operation, succeeded);
    } on TimeoutException {
      _watchRemote(operation, remote!);
      return AuthRecoveryResult.blocked;
    }
  }

  AuthSession _toSession(User user) {
    final metadata = user.userMetadata;
    final googleName = (metadata?['full_name'] ?? metadata?['name']) as String?;
    final googlePhoto =
        (metadata?['avatar_url'] ?? metadata?['picture']) as String?;
    return AuthSession(
      userId: user.id,
      email: user.email ?? '',
      displayName: googleName ?? user.email ?? '',
      photoUrl: googlePhoto,
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    service.removeListener(_handleServiceState);
    _authStateSubscription?.cancel();
    _authEvents.close();
  }
}

/// Non-secret operation ownership and observed completion handles only.
class _OutboundSignOut {
  _OutboundSignOut({
    required this.epoch,
    required this.operationId,
    required this.correlation,
    this.restartRecovery = false,
    this.exchangeOwner,
  });

  final int epoch;
  final String operationId;
  final SessionCorrelation correlation;
  final bool restartRecovery;
  final _CredentialExchangeOperation? exchangeOwner;
  bool remotePending = false;
  bool remoteHandled = false;
  bool rawCleanupPending = false;
  bool localWorkPending = false;
  bool cleanupFinalized = false;
  bool googleCleanupStarted = false;
  Future<bool>? rawCleanup;
  Future<AuthRecoveryResult>? localWork;
}
