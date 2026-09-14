import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:civilpedia/core/backend/backend_config.dart';
import 'package:civilpedia/core/backend/supabase_service.dart';
import 'package:civilpedia/features/auth/data/auth_recovery_library.dart';
import 'package:civilpedia/features/auth/data/session_correlation.dart';
import 'package:civilpedia/features/auth/data/supabase_auth_gateway.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_error.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/features/auth/domain/repositories/auth_gateway.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// V1-R09 PART 1 SLICE C2 — H1 authoritative remote-first sign-out,
// H2 observation-loss, and M1 bounded Google cleanup.
//
// These tests run the FULL production path: a real Supabase initialization
// against a controlled GoTrue HTTP server, real SDK session installation, the
// recovery coordinator journal, and the guarded local-storage adapter. This is
// deliberately NOT the injected-init seam used elsewhere: H1 sign-out requires
// the coordinator boundary and fail-closes otherwise.
// ---------------------------------------------------------------------------

/// Per-call plan for one `/auth/v1/logout` request.
class _LogoutPlan {
  const _LogoutPlan({this.status = 200, this.hang = false});

  final int status;
  final bool hang;
}

String _base64UrlNoPadding(String input) {
  var result = input;
  while (result.endsWith('=')) {
    result = result.substring(0, result.length - 1);
  }
  return result;
}

String _jwt({
  required Map<String, dynamic> payload,
  Map<String, dynamic>? header,
}) {
  final h = _base64UrlNoPadding(
    base64Url.encode(
      utf8.encode(jsonEncode(header ?? {'alg': 'HS256', 'typ': 'JWT'})),
    ),
  );
  final p = _base64UrlNoPadding(
    base64Url.encode(utf8.encode(jsonEncode(payload))),
  );
  return '$h.$p.dummy-signature';
}

String _fakeAccessToken({
  String userId = 'user-a',
  String sessionId = 'sess-a',
}) => _jwt(
  payload: {
    'sub': userId,
    'session_id': sessionId,
    'exp': 1893456000,
    'aud': 'authenticated',
    'role': 'authenticated',
    'iat': 1609459200,
  },
);

String _sessionJson({required String sessionId, String userId = 'user-a'}) {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  return jsonEncode({
    'access_token': _fakeAccessToken(sessionId: sessionId, userId: userId),
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': now + 3600,
    'refresh_token': 'test-refresh-token',
    'user': {
      'id': userId,
      'email': 'user@example.com',
      'user_metadata': {'full_name': 'User A'},
      'app_metadata': {},
      'aud': 'authenticated',
      'created_at': '2024-01-01T00:00:00Z',
      'role': 'authenticated',
    },
  });
}

String _storageKey(String url) =>
    'sb-${Uri.parse(url).host.split(".").first}-auth-token';

String _projectIdentity(String url) =>
    AuthRecoveryStorageCoordinator.projectIdentityFromUrl(url);

class _GoTrueTestServer {
  _GoTrueTestServer._(this.server, this.config);

  final HttpServer server;
  final BackendConfig config;

  int logoutCalls = 0;
  int tokenCalls = 0;
  final List<String?> logoutScopes = [];
  final List<String?> logoutAuthorization = [];
  final List<_LogoutPlan> logoutPlan = [];
  final List<String> tokenSessionIds = [];
  final List<HttpResponse> _heldLogouts = [];

  static Future<_GoTrueTestServer> start({
    List<String>? tokenSessionIds,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final instance = _GoTrueTestServer._(
      server,
      BackendConfig(
        appEnvRaw: 'development',
        supabaseUrl: 'http://${server.address.host}:${server.port}',
        supabaseAnonKey: 'test-anon-key',
        googleServerClientId: 'g-web-client-id.apps.googleusercontent.com',
      ),
    )..tokenSessionIds.addAll(tokenSessionIds ?? ['sess-a']);
    server.listen(instance._handle);
    return instance;
  }

  /// Completes a held (hanging) logout request with [status], simulating the
  /// remote call finally answering after its application deadline.
  void resolveHeldLogout({int status = 200}) {
    for (final response in _heldLogouts) {
      response.statusCode = status;
      response.close();
    }
    _heldLogouts.clear();
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    final path = request.uri.path;
    if (path == '/auth/v1/token') {
      final idx = tokenCalls++;
      final sessionId =
          tokenSessionIds[idx.clamp(0, tokenSessionIds.length - 1)];
      response.statusCode = 200;
      response.headers.contentType = ContentType.json;
      response.write(_sessionJson(sessionId: sessionId));
      await response.close();
      return;
    }
    if (path == '/auth/v1/logout') {
      final idx = logoutCalls++;
      logoutScopes.add(request.uri.queryParameters['scope']);
      logoutAuthorization.add(
        request.headers.value(HttpHeaders.authorizationHeader),
      );
      final plan = idx < logoutPlan.length
          ? logoutPlan[idx]
          : const _LogoutPlan();
      if (plan.hang) {
        _heldLogouts.add(response);
        return;
      }
      response.statusCode = plan.status;
      await response.close();
      return;
    }
    response.statusCode = 404;
    await response.close();
  }

  Future<void> dispose() async {
    for (final response in _heldLogouts) {
      await response.close();
    }
    _heldLogouts.clear();
    await server.close(force: true);
  }
}

GoogleSignInApi _stubGoogleSignIn({void Function()? onSignOut}) {
  return (
    initialize: ({clientId, serverClientId, nonce, hostedDomain}) async {},
    authenticate: (_) async => throw UnimplementedError(),
    authorization: (_, __) async => throw UnimplementedError(),
    signOut: () async => onSignOut?.call(),
  );
}

void main() {
  const credentials = GoogleCredentialBundle(
    idToken: 'google-id-token',
    accessToken: 'google-access-token',
  );
  late Directory tempDir;

  setUp(() async {
    // NOTE: deliberately NO TestWidgetsFlutterBinding.ensureInitialized().
    // flutter_test's binding replaces HttpOverrides with a mock client that
    // returns 400 for EVERY request, which would break the REAL HTTP calls
    // this file makes against the controlled GoTrue server.
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('c2_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    try {
      await Supabase.instance.dispose();
    } catch (_) {
      // Not initialized or already disposed.
    }
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  Future<void> seedRecovery(
    String url,
    Future<void> Function(AuthRecoveryStorageCoordinator coordinator) seed,
  ) async {
    final coordinator = await AuthRecoveryStorageCoordinator.open(
      projectIdentity: _projectIdentity(url),
      delegate: _FakeLocalStorage(),
    );
    await seed(coordinator);
    await coordinator.close();
  }

  group('V1-R09 C2 H1 — remote-first authoritative sign-out', () {
    test('remote success + owned cleanup ends as clean guest', () async {
      final server = await _GoTrueTestServer.start();
      addTearDown(server.dispose);
      var googleSignOutCalls = 0;

      final service = SupabaseService(
        config: server.config,
        authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
      );
      await service.init();
      addTearDown(service.dispose);

      final gateway = SupabaseAuthGateway(
        service: service,
        credentialsProvider: () async => credentials,
        googleSignInFactory: () =>
            _stubGoogleSignIn(onSignOut: () => googleSignOutCalls++),
      );
      addTearDown(gateway.dispose);
      final provider = AuthProvider(
        gateway: gateway,
        onAccountBoundReset: () {},
        onSessionRefresh: () {},
      );
      addTearDown(provider.dispose);

      await provider.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);

      expect(provider.isLoggedIn, isTrue);
      expect(
        Supabase.instance.client.auth.currentSession,
        isNotNull,
        reason: 'real SDK session must be installed',
      );

      await provider.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        server.logoutCalls,
        2,
        reason:
            'explicit admin revocation + the SDK local signOut both '
            'reach /auth/v1/logout?scope=local',
      );
      expect(server.logoutScopes.whereType<String>().toSet(), {'local'});
      expect(
        Supabase.instance.client.auth.currentSession,
        isNull,
        reason: 'local SDK session must be cleared after remote success',
      );
      expect(provider.isLoggedIn, isFalse);
      expect(provider.status, AuthStatus.guest);
      expect(provider.error, isNull);
      expect(provider.isCleanupBlocked, isFalse);
      expect(
        gateway.isLogoutCleanupBlocked,
        isFalse,
        reason: 'journal must have closed after owned cleanup',
      );
      expect(
        googleSignOutCalls,
        1,
        reason: 'M1 — bounded Google cleanup must run last, best-effort',
      );
      expect(
        service.recoveryCoordinator!.readRecoveryState().status,
        AuthRecoveryStartupStatus.none,
      );
    });

    test(
      'known remote failure closes the journal and keeps identity',
      () async {
        final server = await _GoTrueTestServer.start()
          ..logoutPlan.add(const _LogoutPlan(status: 500));
        addTearDown(server.dispose);

        final service = SupabaseService(
          config: server.config,
          authOptions: const FlutterAuthClientOptions(
            detectSessionInUri: false,
          ),
        );
        await service.init();
        addTearDown(service.dispose);

        final gateway = SupabaseAuthGateway(
          service: service,
          credentialsProvider: () async => credentials,
          googleSignInFactory: () => _stubGoogleSignIn(),
        );
        addTearDown(gateway.dispose);
        final provider = AuthProvider(gateway: gateway);
        addTearDown(provider.dispose);

        await provider.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);
        expect(provider.isLoggedIn, isTrue);

        await provider.signOut();
        await Future<void>.delayed(Duration.zero);

        expect(
          server.logoutCalls,
          1,
          reason: 'no local cleanup/second call happens after a remote failure',
        );
        expect(
          Supabase.instance.client.auth.currentSession,
          isNotNull,
          reason: 'remote failure must not clear the local SDK session',
        );
        expect(provider.isLoggedIn, isTrue);
        expect(provider.status, AuthStatus.authenticated);
        expect(provider.error, AuthError.signOutFailed);
        expect(
          gateway.isLogoutCleanupBlocked,
          isFalse,
          reason: 'the failed operation closed its journal',
        );
      },
    );

    test(
      'remote timeout keeps identity and leaves a recoverable journal',
      () async {
        final server = await _GoTrueTestServer.start()
          ..logoutPlan.add(const _LogoutPlan(hang: true));
        addTearDown(server.dispose);

        final service = SupabaseService(
          config: server.config,
          authOptions: const FlutterAuthClientOptions(
            detectSessionInUri: false,
          ),
        );
        await service.init();
        addTearDown(service.dispose);

        final gateway = SupabaseAuthGateway(
          service: service,
          credentialsProvider: () async => credentials,
          googleSignInFactory: () => _stubGoogleSignIn(),
          signOutTimeout: const Duration(milliseconds: 60),
        );
        addTearDown(gateway.dispose);
        final provider = AuthProvider(
          gateway: gateway,
          onAccountBoundReset: () {},
          onSessionRefresh: () {},
        );
        addTearDown(provider.dispose);

        await provider.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);
        expect(provider.isLoggedIn, isTrue);

        await provider.signOut();

        expect(
          provider.isLoggedIn,
          isTrue,
          reason: 'a timed-out remote revocation must not drop identity',
        );
        expect(provider.status, AuthStatus.authenticated);
        expect(provider.error, AuthError.retryableNetwork);
        expect(server.logoutCalls, 1);
        expect(Supabase.instance.client.auth.currentSession, isNotNull);
        expect(
          !gateway.canAccountAuthorityBeGranted,
          isTrue,
          reason: 'remotePending journal keeps fresh authority closed',
        );
        final record = service.recoveryCoordinator!.readRecoveryEntry();
        expect(record, isNotNull);
        expect(record!.phase, AuthRecoveryPhase.remotePending);
        expect(record.operationType, AuthRecoveryOperationType.signOut);
        expect(record.sessionId, 'sess-a');
      },
    );

    test(
      'late success after timeout completes the cleanup and ends guest',
      () async {
        final server = await _GoTrueTestServer.start()
          ..logoutPlan.add(const _LogoutPlan(hang: true));
        addTearDown(server.dispose);

        final service = SupabaseService(
          config: server.config,
          authOptions: const FlutterAuthClientOptions(
            detectSessionInUri: false,
          ),
        );
        await service.init();
        addTearDown(service.dispose);

        final gateway = SupabaseAuthGateway(
          service: service,
          credentialsProvider: () async => credentials,
          googleSignInFactory: () => _stubGoogleSignIn(),
          signOutTimeout: const Duration(milliseconds: 60),
        );
        addTearDown(gateway.dispose);
        final provider = AuthProvider(
          gateway: gateway,
          onAccountBoundReset: () {},
          onSessionRefresh: () {},
        );
        addTearDown(provider.dispose);

        await provider.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);

        await provider.signOut();
        expect(provider.error, AuthError.retryableNetwork);

        // The hung remote call finally returns 200.
        server.resolveHeldLogout(status: 200);
        // Allow the late watcher + owned cleanup + bounded Google cleanup.
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(Supabase.instance.client.auth.currentSession, isNull);
        expect(provider.isLoggedIn, isFalse);
        expect(provider.status, AuthStatus.guest);
        expect(provider.error, isNull);
        expect(
          gateway.isLogoutCleanupBlocked,
          isFalse,
          reason: 'late success must settle the journal and close the gate',
        );
        expect(
          service.recoveryCoordinator!.readRecoveryState().status,
          AuthRecoveryStartupStatus.none,
        );
        expect(
          server.logoutCalls,
          2,
          reason: 'explicit revoke (held) + the local-cleanup SDK signOut',
        );
      },
    );

    test(
      'late failure after timeout closes the journal, keeps identity',
      () async {
        final server = await _GoTrueTestServer.start()
          ..logoutPlan.add(const _LogoutPlan(hang: true));
        addTearDown(server.dispose);

        final service = SupabaseService(
          config: server.config,
          authOptions: const FlutterAuthClientOptions(
            detectSessionInUri: false,
          ),
        );
        await service.init();
        addTearDown(service.dispose);

        final gateway = SupabaseAuthGateway(
          service: service,
          credentialsProvider: () async => credentials,
          googleSignInFactory: () => _stubGoogleSignIn(),
          signOutTimeout: const Duration(milliseconds: 60),
        );
        addTearDown(gateway.dispose);
        final provider = AuthProvider(gateway: gateway);
        addTearDown(provider.dispose);

        await provider.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);

        await provider.signOut();
        expect(provider.error, AuthError.retryableNetwork);

        server.resolveHeldLogout(status: 500);
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Late remote failure: no cleanup, no guest. Journal closed.
        expect(Supabase.instance.client.auth.currentSession, isNotNull);
        expect(provider.isLoggedIn, isTrue);
        expect(provider.status, AuthStatus.authenticated);
        expect(gateway.isLogoutCleanupBlocked, isFalse);
        expect(
          service.recoveryCoordinator!.readRecoveryState().status,
          AuthRecoveryStartupStatus.none,
        );
      },
    );
  });

  group('V1-R09 C2 M1/H1 — stalling owned local cleanup', () {
    test(
      'stalled cleanup neutralizes identity and retry clears the gate',
      () async {
        final server = await _GoTrueTestServer.start()
          ..logoutPlan.add(const _LogoutPlan(status: 200))
          ..logoutPlan.add(const _LogoutPlan(hang: true));
        addTearDown(server.dispose);

        final service = SupabaseService(
          config: server.config,
          authOptions: const FlutterAuthClientOptions(
            detectSessionInUri: false,
          ),
        );
        await service.init();
        addTearDown(service.dispose);

        final gateway = SupabaseAuthGateway(
          service: service,
          credentialsProvider: () async => credentials,
          googleSignInFactory: () => _stubGoogleSignIn(),
          signOutTimeout: const Duration(milliseconds: 60),
        );
        addTearDown(gateway.dispose);
        final provider = AuthProvider(
          gateway: gateway,
          onAccountBoundReset: () {},
          onSessionRefresh: () {},
        );
        addTearDown(provider.dispose);

        await provider.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);
        expect(provider.isLoggedIn, isTrue);

        // Remote revoke succeeds; the local-cleanup SDK signOut stalls on its
        // incidental remote call.
        await provider.signOut();
        await Future<void>.delayed(Duration.zero);

        expect(
          Supabase.instance.client.auth.currentSession,
          isNull,
          reason: 'the SDK clears local state before waiting on the revoke',
        );
        expect(provider.isLoggedIn, isFalse);
        expect(provider.status, AuthStatus.cleanupRecovery);
        expect(provider.isCleanupBlocked, isTrue);
        expect(provider.isAuthorityBlocked, isTrue);
        expect(provider.error, AuthError.recoveryBlocked);
        expect(gateway.isLogoutCleanupBlocked, isTrue);
        final postSignOut = service.recoveryCoordinator!.readRecoveryEntry();
        expect(postSignOut, isNotNull);
        expect(postSignOut!.phase, AuthRecoveryPhase.cleanupRequired);

        // While blocked, fresh authority must be neutralized: sign-in, restore
        // and clearError are inert.
        final tokenCallsBefore = server.tokenCalls;
        await provider.signInWithGoogle();
        await provider.restoreSession();
        provider.clearError();
        expect(server.tokenCalls, tokenCallsBefore);
        expect(provider.status, AuthStatus.cleanupRecovery);
        expect(provider.error, AuthError.recoveryBlocked);

        // A retry cannot race an unresolved SDK call. Its result must settle
        // before the gate opens to another account.
        await provider.retryAuthCleanup();
        await Future<void>.delayed(Duration.zero);

        expect(
          server.logoutCalls,
          2,
          reason: 'only the explicit revoke + the stalled cleanup call exist',
        );
        expect(provider.status, AuthStatus.cleanupRecovery);
        server.resolveHeldLogout();
        await _waitFor(() => provider.status == AuthStatus.guest);
        expect(provider.status, AuthStatus.guest);
        expect(provider.error, isNull);
        expect(provider.isCleanupBlocked, isFalse);
        expect(
          gateway.isLogoutCleanupBlocked,
          isFalse,
          reason: 'retry settled the owned cleanup and closed the journal',
        );
        expect(
          service.recoveryCoordinator!.readRecoveryState().status,
          AuthRecoveryStartupStatus.none,
        );
      },
    );

    test('A-vs-B — foreign current session blocks destructive cleanup', () async {
      final server = await _GoTrueTestServer.start(tokenSessionIds: ['sess-b']);
      addTearDown(server.dispose);
      final url = server.config.supabaseUrl;
      final identity = _projectIdentity(url);

      // A stale sign-out recovery owned by session A (cleanupRequired) with a
      // persisted foreign remnant.
      final corrA = SessionCorrelation.fromSessionJson(
        _sessionJson(sessionId: 'sess-a'),
        projectIdentity: identity,
      );
      await seedRecovery(url, (coordinator) async {
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.cleanupRequired,
          correlation: corrA,
        );
      });
      SharedPreferences.setMockInitialValues({
        _storageKey(url): _sessionJson(sessionId: 'sess-a'),
      });

      final service = SupabaseService(
        config: server.config,
        authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
      );
      await service.init();
      addTearDown(service.dispose);
      expect(
        service.recoveryState?.status,
        AuthRecoveryStartupStatus.cleanupRequired,
      );

      final gateway = SupabaseAuthGateway(
        service: service,
        credentialsProvider: () async => credentials,
        googleSignInFactory: () => _stubGoogleSignIn(),
      );
      addTearDown(gateway.dispose);
      final provider = AuthProvider(
        gateway: gateway,
        onAccountBoundReset: () {},
        onSessionRefresh: () {},
      );
      addTearDown(provider.dispose);

      // Session B is installed directly on the SDK while the recovery gate is
      // held: C1 blocks its admission into the provider, but the SDK session is
      // present and persisted.
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: 'id-token-b',
        accessToken: 'access-token-b',
      );
      await Future<void>.delayed(Duration.zero);

      expect(Supabase.instance.client.auth.currentSession, isNotNull);
      expect(
        provider.isLoggedIn,
        isFalse,
        reason: 'C1 admission gate suppresses the foreign signedIn event',
      );

      // The retry observes current session B and must fail closed.
      final cleared = await gateway.retryAuthCleanup();
      await Future<void>.delayed(Duration.zero);

      expect(cleared, isFalse);
      expect(
        Supabase.instance.client.auth.currentSession,
        isNotNull,
        reason: 'session B must never be destroyed by stale cleanup',
      );
      final record = service.recoveryCoordinator!.readRecoveryEntry();
      expect(record, isNotNull);
      expect(record!.phase, AuthRecoveryPhase.blockedCleanupFailure);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(_storageKey(url)),
        isNotNull,
        reason: 'the persisted remnant must be retained for audit',
      );
      expect(provider.status, AuthStatus.cleanupRecovery);
      expect(provider.isAuthorityBlocked, isTrue);
    });
  });

  group('C2 exact snapshot matrix', () {
    test('A: installed A and persisted A use owned SDK clear', () async {
      final h = await _RecoveryHarness.open(installed: true);
      await h.provider.retryAuthCleanup();
      await _waitFor(() => h.provider.status == AuthStatus.guest);
      expect(h.sdkCalls, 1);
      expect(h.sdkCompletions, 1);
      expect(h.storage.removeCalls, 1);
      expect(h.storage.snapshot, isNull);
      expect(h.coordinator.readRecoveryEntry(), isNull);
    });
    test(
      'B: null current and persisted A delete only through owned storage',
      () async {
        final h = await _RecoveryHarness.open();
        expect(h.client.auth.currentSession, isNull);
        await h.provider.retryAuthCleanup();
        expect(h.sdkCalls, 0);
        expect(h.server.logoutCalls, 0);
        expect(h.storage.removeCalls, 1);
        expect(h.storage.snapshot, isNull);
        expect(h.coordinator.readRecoveryEntry(), isNull);
        expect(h.provider.status, AuthStatus.guest);
        expect(h.resets, 0, reason: 'startup never admitted an account');
      },
    );
    test(
      'C: null current and persisted B preserve exact bytes and owner A',
      () async {
        final b = _sessionJson(sessionId: 'sess-b', userId: 'user-b');
        final h = await _RecoveryHarness.open(snapshot: b);
        final originalEntry = h.coordinator.readRecoveryEntry()!;
        final id = originalEntry.operationId;
        final initialRemoveCalls = h.storage.removeCalls;
        final activeA = await h.coordinator.runOwnedRecoveryOperation<bool>(
          expectedOperationId: id,
          expectedCorrelation: SessionCorrelation(
            userId: originalEntry.userId,
            sessionId: originalEntry.sessionId,
            projectIdentity: originalEntry.projectIdentity,
          ),
          action: (tx) async {
            expect(await tx.removeMatchingRecoverySnapshot(), isFalse);
            expect(h.storage.snapshot, b);
            expect(h.storage.removeCalls, 0);
            await tx.runOwnedSdkLocalCleanup(
              h.coordinator.sdkLocalStorage.removePersistedSession,
            );
            expect(await tx.readRecoverySnapshot(), b);
            return true;
          },
        );
        expect(activeA.allowed, isTrue);
        expect(activeA.value, isTrue);
        expect(h.client.auth.currentSession, isNull);
        expect(h.sdkCalls, 0);
        expect(h.server.logoutCalls, 0);
        expect(h.storage.removeCalls, 0);
        expect(h.storage.snapshot, b);
        expect(h.coordinator.readRecoveryEntry()!.operationId, id);
        expect(h.coordinator.readRecoveryEntry()!.phase, originalEntry.phase);
        await h.provider.retryAuthCleanup();
        expect(h.sdkCalls, 0);
        expect(initialRemoveCalls, 0);
        expect(h.storage.removeCalls, initialRemoveCalls);
        expect(h.storage.snapshot, b);
        expect(h.coordinator.readRecoveryEntry()!.operationId, id);
        expect(
          h.coordinator.readRecoveryEntry()!.phase,
          AuthRecoveryPhase.blockedCleanupFailure,
        );
        expect(h.provider.isAuthorityBlocked, isTrue);
      },
    );
    test('D: current B and persisted B remain exactly unchanged', () async {
      final h = await _RecoveryHarness.open(
        installed: true,
        snapshot: _sessionJson(sessionId: 'sess-b', userId: 'user-b'),
      );
      final b = h.client.auth.currentSession;
      final snapshot = h.storage.snapshot;
      await h.provider.retryAuthCleanup();
      expect(identical(h.client.auth.currentSession, b), isTrue);
      expect(h.storage.snapshot, snapshot);
      expect(h.sdkCalls, 0);
      expect(h.storage.removeCalls, 0);
      expect(
        h.provider.recoveryStatus,
        AuthRecoveryStatus.blockedCleanupFailure,
      );
    });
    test(
      'E: installed A with absent persistence clears memory without deletion',
      () async {
        final h = await _RecoveryHarness.open(
          installed: true,
          missingAfterInit: true,
        );
        await h.provider.retryAuthCleanup();
        expect(h.sdkCalls, 1);
        expect(h.storage.removeCalls, 0);
        expect(h.client.auth.currentSession, isNull);
        expect(h.provider.status, AuthStatus.guest);
      },
    );
    test('E: B appearing before settlement survives A cleanup', () async {
      final h = await _RecoveryHarness.open(
        installed: true,
        missingAfterInit: true,
      );
      h.server.logoutPlan.add(const _LogoutPlan(hang: true));
      final retry = h.provider.retryAuthCleanup();
      await _waitFor(() => h.server.logoutCalls == 1);
      final b = _sessionJson(sessionId: 'sess-b', userId: 'user-b');
      h.storage.snapshot = b;
      h.server.resolveHeldLogout();
      await retry;
      await _waitFor(
        () =>
            h.provider.recoveryStatus ==
            AuthRecoveryStatus.blockedCleanupFailure,
      );
      expect(h.sdkCalls, 1);
      expect(h.storage.removeCalls, 0);
      expect(h.storage.snapshot, b);
      expect(h.provider.isLoggedIn, isFalse);
    });
    final malformedCases = <String, String>{
      'empty': '',
      'invalid JSON': '{broken',
      'wrong root': '[]',
      'wrong token type': '{"access_token":7,"user":{"id":"user-a"}}',
      'missing user': jsonEncode({
        'access_token': _fakeAccessToken(),
        'token_type': 'bearer',
      }),
      'missing session_id': _sessionJson(sessionId: ''),
    };
    for (final entry in malformedCases.entries) {
      test(
        'F: malformed/insufficient snapshot preserved: ' + entry.key,
        () async {
          final h = await _RecoveryHarness.open(snapshot: entry.value);
          await h.provider.retryAuthCleanup();
          expect(h.sdkCalls, 0);
          expect(h.storage.removeCalls, 0);
          expect(h.storage.snapshot, entry.value);
          expect(
            h.provider.recoveryStatus,
            AuthRecoveryStatus.blockedCleanupFailure,
          );
        },
      );
    }
    test(
      'both absent completes the journal without any SDK/delete call',
      () async {
        final h = await _RecoveryHarness.open(absent: true);
        await h.provider.retryAuthCleanup();
        expect(h.sdkCalls, 0);
        expect(h.storage.removeCalls, 0);
        expect(h.provider.status, AuthStatus.guest);
        expect(h.coordinator.readRecoveryEntry(), isNull);
      },
    );
  });

  group('C2 definitive event delivery and authority timing', () {
    test(
      'exact independent and SDK event order: before, during and after cleanup',
      () async {
        final h = await _RecoveryHarness.open(
          installed: true,
          relayEvents: true,
        );
        h.emit(const AuthState(AuthChangeEvent.signedOut, null));
        await _waitFor(() => h.definitiveEvents.length == 1);
        expect(h.provider.status, AuthStatus.cleanupRecovery);
        h.server.logoutPlan.add(const _LogoutPlan(hang: true));
        final retry = h.provider.retryAuthCleanup();
        await _waitFor(
          () => h.server.logoutCalls == 1 && h.definitiveEvents.length == 2,
        );
        expect(
          h.sdkCalls,
          1,
          reason: 'second signedOut is emitted by the real SDK',
        );
        expect(h.sdkCompletions, 0);
        h.emit(const AuthState(AuthChangeEvent.signedOut, null));
        h.emit(const AuthState(AuthChangeEvent.userDeleted, null));
        await _waitFor(() => h.definitiveEvents.length == 4);
        expect(h.provider.status, AuthStatus.cleanupRecovery);
        expect(
          h.resets,
          0,
          reason: 'reconstructed recovery admitted no account',
        );
        expect(h.coordinator.readRecoveryEntry(), isNotNull);
        h.server.resolveHeldLogout();
        await retry;
        await _waitFor(() => h.provider.status == AuthStatus.guest);
        h.emit(const AuthState(AuthChangeEvent.signedOut, null));
        await _waitFor(() => h.definitiveEvents.length == 5);
        expect(h.definitiveEvents, [
          AuthEventType.signedOut,
          AuthEventType.signedOut,
          AuthEventType.signedOut,
          AuthEventType.sessionLost,
          AuthEventType.signedOut,
        ]);
        expect(h.resets, 0);
      },
    );

    for (final late in [false, true]) {
      test(
        '${late ? "late" : "in-time"} remote success removes authority before local settlement',
        () async {
          final h = await _RecoveryHarness.open(live: true, relayEvents: true);
          final generation = h.provider.generation;
          expect(h.provider.isLoggedIn, isTrue);
          h.server.logoutPlan.addAll([
            _LogoutPlan(hang: late),
            const _LogoutPlan(hang: true),
          ]);
          final signingOut = h.provider.signOut();
          if (late) {
            await signingOut;
            expect(h.provider.isLoggedIn, isTrue);
            expect(h.resets, 0);
            h.server.resolveHeldLogout();
          }
          await _waitFor(() => h.server.logoutCalls == 2);
          await _waitFor(() => h.definitiveEvents.length == 1);
          expect(h.provider.status, AuthStatus.cleanupRecovery);
          expect(h.provider.session, isNull);
          expect(h.provider.isAuthorityBlocked, isTrue);
          expect(
            h.provider.isCurrentSession(
              userId: 'user-a',
              generation: generation,
            ),
            isFalse,
          );
          expect(
            h.coordinator.readRecoveryEntry()!.phase,
            AuthRecoveryPhase.cleanupRequired,
          );
          expect(h.resets, 1);
          h.emit(const AuthState(AuthChangeEvent.userDeleted, null));
          h.emit(const AuthState(AuthChangeEvent.signedOut, null));
          await _waitFor(() => h.definitiveEvents.length == 3);
          await h.provider.signInWithGoogle();
          await h.provider.restoreSession();
          expect(h.server.tokenCalls, 0);
          expect(h.provider.status, AuthStatus.cleanupRecovery);
          expect(h.resets, 1);
          h.server.resolveHeldLogout();
          await signingOut;
          await _waitFor(() => h.provider.status == AuthStatus.guest);
          expect(h.resets, 1);
          expect(h.definitiveEvents, [
            AuthEventType.signedOut,
            AuthEventType.sessionLost,
            AuthEventType.signedOut,
          ]);
          expect(
            h.events
                .where((e) => e.type == AuthEventType.logoutCleanupCleared)
                .length,
            1,
          );
        },
      );
    }

    test(
      'B collision rejects admission without hiding definitive events',
      () async {
        final h = await _RecoveryHarness.open(
          installed: true,
          relayEvents: true,
          snapshot: _sessionJson(sessionId: 'sess-b', userId: 'user-b'),
        );
        final snapshot = h.storage.snapshot;
        h.emit(
          AuthState(AuthChangeEvent.signedIn, h.client.auth.currentSession),
        );
        await h.provider.retryAuthCleanup();
        h.emit(const AuthState(AuthChangeEvent.signedOut, null));
        h.emit(const AuthState(AuthChangeEvent.userDeleted, null));
        await _waitFor(() => h.definitiveEvents.length == 2);
        expect(h.definitiveEvents, [
          AuthEventType.signedOut,
          AuthEventType.sessionLost,
        ]);
        expect(h.provider.status, AuthStatus.cleanupRecovery);
        expect(h.provider.session, isNull);
        expect(h.storage.snapshot, snapshot);
        expect(h.storage.removeCalls, 0);
        expect(h.sdkCalls, 0);
        expect(h.resets, 0);
      },
    );
  });

  group('C2 real reconstructed remotePending', () {
    test(
      'explicit retry privately revokes persisted A before owned removal',
      () async {
        final h = await _RecoveryHarness.open(
          phase: AuthRecoveryPhase.remotePending,
        );
        final snapshot = h.storage.snapshot;
        expect(h.provider.status, AuthStatus.cleanupRecovery);
        expect(h.provider.recoveryStatus, AuthRecoveryStatus.remotePending);
        expect(h.client.auth.currentSession, isNull);
        expect(h.server.logoutCalls, 0);
        expect(h.server.tokenCalls, 0);
        await h.provider.signInWithGoogle();
        expect(h.server.tokenCalls, 0);
        h.server.logoutPlan.add(const _LogoutPlan(hang: true));
        final retry = h.provider.retryAuthCleanup();
        await _waitFor(() => h.server.logoutCalls == 1);
        expect(h.provider.isRecoveryRetryBusy, isTrue);
        expect(h.storage.snapshot, snapshot);
        expect(h.storage.removeCalls, 0);
        expect(h.sdkCalls, 0);
        expect(h.server.logoutAuthorization, ['Bearer ${_fakeAccessToken()}']);
        expect(h.server.logoutScopes, ['local']);
        h.server.resolveHeldLogout();
        await retry;
        expect(h.provider.isRecoveryRetryBusy, isFalse);
        expect(h.provider.status, AuthStatus.guest);
        expect(h.storage.snapshot, isNull);
        expect(h.storage.removeCalls, 1);
        expect(h.sdkCalls, 0);
        expect(
          h.server.tokenCalls,
          0,
          reason: 'recovery never installs parsed A',
        );
        expect(h.resets, 0);
      },
    );

    test(
      'ordinary failure requires restart; only normal next startup restores A',
      () async {
        final h = await _RecoveryHarness.open(
          phase: AuthRecoveryPhase.remotePending,
        );
        final snapshot = h.storage.snapshot;
        h.server.logoutPlan.add(const _LogoutPlan(status: 500));
        await h.provider.retryAuthCleanup();
        expect(h.provider.recoveryStatus, AuthRecoveryStatus.restartRequired);
        expect(
          await h.gateway.retryAuthRecovery(),
          AuthRecoveryResult.restartRequired,
        );
        expect(h.provider.isAuthObservationUnavailable, isFalse);
        expect(h.coordinator.readRecoveryEntry(), isNull);
        h.provider.clearError();
        await h.provider.restoreSession();
        await h.provider.signInWithGoogle();
        expect(h.provider.status, AuthStatus.cleanupRecovery);
        expect(h.provider.session, isNull);
        expect(h.client.auth.currentSession, isNull);
        expect(h.storage.snapshot, snapshot);
        expect(h.storage.removeCalls, 0);
        expect(h.sdkCalls, 0);
        expect(h.googleCalls, 0);
        expect(h.server.logoutCalls, 1);
        expect(h.server.tokenCalls, 0);

        // A new process lifetime, using the SAME persisted delegate and the
        // normal SDK restoration entry point, never recovery's parsed Session.
        await h.stopClient();
        final coordinator = await AuthRecoveryStorageCoordinator.open(
          projectIdentity: _projectIdentity(h.server.config.supabaseUrl),
          delegate: h.storage,
        );
        addTearDown(coordinator.close);
        await Supabase.initialize(
          url: h.server.config.supabaseUrl,
          anonKey: h.server.config.supabaseAnonKey,
          authOptions: FlutterAuthClientOptions(
            localStorage: coordinator.sdkLocalStorage,
            detectSessionInUri: false,
            autoRefreshToken: false,
          ),
        );
        final service = _HarnessService(h.server.config, coordinator);
        addTearDown(service.dispose);
        final gateway = SupabaseAuthGateway(service: service);
        addTearDown(gateway.dispose);
        final provider = AuthProvider(gateway: gateway);
        addTearDown(provider.dispose);
        await provider.restoreSession();
        expect(provider.isLoggedIn, isTrue);
        expect(provider.currentUserId, 'user-a');
        expect(h.server.tokenCalls, 0);
      },
    );

    for (final success in [true, false]) {
      test(
        'timeout stays single-flight; late ${success ? "success" : "failure"} takes fresh ownership',
        () async {
          final h = await _RecoveryHarness.open(
            phase: AuthRecoveryPhase.remotePending,
          );
          final snapshot = h.storage.snapshot;
          final id = h.coordinator.readRecoveryEntry()!.operationId;
          h.server.logoutPlan.add(const _LogoutPlan(hang: true));
          await h.provider.retryAuthCleanup();
          expect(h.provider.isRecoveryRetryBusy, isFalse);
          expect(
            h.coordinator.readRecoveryEntry()!.phase,
            AuthRecoveryPhase.remotePending,
          );
          expect(h.coordinator.readRecoveryEntry()!.operationId, id);
          expect(h.storage.removeCalls, 0);
          expect(h.storage.snapshot, snapshot);
          await h.provider.retryAuthCleanup();
          await h.provider.signInWithGoogle();
          expect(h.server.logoutCalls, 1);
          expect(h.server.tokenCalls, 0);
          h.server.resolveHeldLogout(status: success ? 200 : 500);
          await _waitFor(() => h.coordinator.readRecoveryEntry() == null);
          await _waitFor(
            () => success
                ? h.provider.status == AuthStatus.guest
                : h.provider.recoveryStatus ==
                      AuthRecoveryStatus.restartRequired,
          );
          expect(h.sdkCalls, 0);
          expect(h.storage.removeCalls, success ? 1 : 0);
          expect(h.storage.snapshot, success ? isNull : snapshot);
          expect(h.server.logoutCalls, 1);
        },
      );
    }

    final invalid = <String, String?>{
      'missing': null,
      'foreign B': _sessionJson(sessionId: 'sess-b', userId: 'user-b'),
      'malformed': '{broken',
      'insufficient': _sessionJson(sessionId: ''),
    };
    for (final entry in invalid.entries) {
      test('${entry.key} snapshot cannot authorize remote retry', () async {
        final h = await _RecoveryHarness.open(
          phase: AuthRecoveryPhase.remotePending,
          absent: entry.value == null,
          snapshot: entry.value,
        );
        await h.provider.retryAuthCleanup();
        expect(h.provider.isRecoveryRetryBusy, isFalse);
        expect(h.provider.isAuthorityBlocked, isTrue);
        expect(await h.gateway.retryAuthRecovery(), AuthRecoveryResult.blocked);
        expect(h.server.logoutCalls, 0);
        expect(h.sdkCalls, 0);
        expect(h.storage.removeCalls, 0);
        expect(h.storage.snapshot, entry.value);
      });
    }

    for (final success in [false, true]) {
      test(
        'late remote ${success ? "success" : "failure"} checks journal write outcome',
        () async {
          final h = await _RecoveryHarness.open(
            phase: AuthRecoveryPhase.remotePending,
          );
          final snapshot = h.storage.snapshot;
          h.server.logoutPlan.add(const _LogoutPlan(hang: true));
          await h.provider.retryAuthCleanup();
          await h.coordinator.close();
          h.server.resolveHeldLogout(status: success ? 200 : 500);
          await _waitFor(
            () =>
                h.provider.recoveryStatus == AuthRecoveryStatus.storageFailure,
          );
          h.provider.clearError();
          await h.provider.restoreSession();
          await h.provider.signInWithGoogle();
          expect(h.provider.isAuthorityBlocked, isTrue);
          expect(h.provider.session, isNull);
          expect(h.storage.snapshot, snapshot);
          expect(h.storage.removeCalls, 0);
          expect(h.sdkCalls, 0);
          expect(h.googleCalls, 0);
          expect(h.server.logoutCalls, 1);
          expect(h.server.tokenCalls, 0);
        },
      );
    }

    for (final live in [false, true]) {
      test(
        '${live ? "live" : "restart"} failure cannot ignore failed journal finalization',
        () async {
          final h = await _RecoveryHarness.open(
            live: live,
            phase: AuthRecoveryPhase.remotePending,
          );
          final snapshot = h.storage.snapshot;
          final session = h.provider.session;
          h.server.logoutPlan.add(const _LogoutPlan(hang: true));
          final action = live
              ? h.provider.signOut()
              : h.provider.retryAuthCleanup();
          await _waitFor(() => h.server.logoutCalls == 1);
          // Closing the actual persisted journal after the request starts forces
          // deterministic completion failure; no private journal bypass/seam.
          await h.coordinator.close();
          h.server.resolveHeldLogout(status: 500);
          await action;
          await _waitFor(
            () =>
                h.provider.recoveryStatus == AuthRecoveryStatus.storageFailure,
          );
          expect(h.provider.isAuthorityBlocked, isTrue);
          expect(h.provider.error, AuthError.unexpected);
          expect(h.provider.session, same(session));
          h.provider.clearError();
          await h.provider.restoreSession();
          await h.provider.signInWithGoogle();
          expect(h.provider.session, same(session));
          expect(h.provider.isAuthorityBlocked, isTrue);
          expect(h.storage.snapshot, snapshot);
          expect(h.storage.removeCalls, 0);
          expect(h.sdkCalls, 0);
          expect(h.googleCalls, 0);
          expect(h.resets, 0);
          expect(h.server.tokenCalls, 0);
        },
      );
    }
  });

  group('C2 observed raw cleanup and delegate settlement', () {
    test(
      'synchronous local invocation failure retains recovery; explicit retry resets only once',
      () async {
        final h = await _RecoveryHarness.open(live: true);
        h.localInvocationError = StateError(
          'controlled local invocation failure',
        );
        await h.provider.signOut();
        await _waitFor(
          () =>
              h.provider.recoveryStatus ==
              AuthRecoveryStatus.blockedCleanupFailure,
        );
        expect(h.sdkFailures, 1);
        expect(h.client.auth.currentSession, isNotNull);
        expect(h.provider.session, isNull);
        expect(h.provider.isAuthorityBlocked, isTrue);
        expect(h.storage.removeCalls, 0);
        expect(h.resets, 1);
        h.localInvocationError = null;
        await h.provider.retryAuthCleanup();
        await _waitFor(() => h.provider.status == AuthStatus.guest);
        expect(h.sdkCalls, 2);
        expect(
          h.server.logoutCalls,
          2,
          reason: 'one authoritative revoke, one SDK local-scope revoke',
        );
        expect(h.storage.snapshot, isNull);
        expect(h.resets, 1);
      },
    );

    test(
      'Google initialization is bounded and its late error is consumed',
      () async {
        final h = await _RecoveryHarness.open(live: true);
        final barrier = Completer<void>();
        h.googleInitializeBarrier = barrier.future;
        h.googleInitializeError = StateError(
          'controlled Google initialization failure',
        );
        final errors = <Object>[];
        await _captureAsyncErrors(errors, () async {
          await h.provider.signOut();
          await _waitFor(() => h.provider.status == AuthStatus.guest);
          await _waitFor(() => h.googleInitializeCalls == 1);
          await Future<void>.delayed(const Duration(milliseconds: 90));
          barrier.complete();
          await Future<void>.delayed(const Duration(milliseconds: 20));
          expect(h.googleCalls, 0);
          expect(h.provider.status, AuthStatus.guest);
          expect(h.resets, 1);
        });
        expect(errors, isEmpty);
      },
    );

    test(
      'late raw SDK error is observed once; expired permission cannot delete B',
      () async {
        final h = await _RecoveryHarness.open(live: true);
        final errors = <Object>[];
        await _captureAsyncErrors(errors, () async {
          h.server.logoutPlan.addAll([
            const _LogoutPlan(),
            const _LogoutPlan(hang: true),
          ]);
          await h.provider.signOut();
          expect(h.provider.status, AuthStatus.cleanupRecovery);
          expect(h.sdkCompletions, 0);
          expect(h.resets, 1);
          final b = _sessionJson(sessionId: 'sess-b', userId: 'user-b');
          await h.coordinator.sdkLocalStorage.persistSession(b);
          final removes = h.storage.removeCalls;
          await h.coordinator.sdkLocalStorage.removePersistedSession();
          expect(
            h.storage.snapshot,
            b,
            reason: 'late SDK request has no active capability',
          );
          await h.provider.retryAuthCleanup();
          expect(h.sdkCalls, 1);
          h.server.resolveHeldLogout(status: 500);
          await _waitFor(() => h.sdkFailures == 1);
          await _waitFor(
            () =>
                h.provider.recoveryStatus ==
                AuthRecoveryStatus.blockedCleanupFailure,
          );
          await Future<void>.delayed(const Duration(milliseconds: 20));
          expect(h.sdkCompletions, 1);
          expect(h.sdkCalls, 1);
          expect(h.server.logoutCalls, 2);
          expect(h.storage.snapshot, b);
          expect(h.storage.removeCalls, removes);
          expect(h.provider.isAuthorityBlocked, isTrue);
          expect(h.resets, 1);
          expect(
            h.events.where((e) => e.type == AuthEventType.logoutCleanupCleared),
            isEmpty,
          );
        });
        expect(errors, isEmpty);
      },
    );

    test('journal cannot outrun delayed SDK persistence delegate', () async {
      final h = await _RecoveryHarness.open(live: true);
      final barrier = Completer<void>();
      h.storage.removeBarrier = barrier.future;
      final action = h.provider.signOut();
      await _waitFor(() => h.sdkCompletions == 1 && h.storage.removeCalls == 1);
      expect(h.client.auth.currentSession, isNull);
      expect(h.storage.snapshot, isNotNull);
      expect(
        h.coordinator.readRecoveryEntry()!.phase,
        AuthRecoveryPhase.cleanupRequired,
      );
      expect(h.provider.status, AuthStatus.cleanupRecovery);
      expect(h.resets, 1);
      await action;
      await h.provider.retryAuthCleanup();
      expect(h.provider.isRecoveryRetryBusy, isFalse);
      expect(h.sdkCalls, 1);
      expect(h.storage.removeCalls, 1);
      expect(h.coordinator.readRecoveryEntry(), isNotNull);
      barrier.complete();
      await _waitFor(() => h.provider.status == AuthStatus.guest);
      expect(h.storage.snapshot, isNull);
      expect(h.coordinator.readRecoveryEntry(), isNull);
      expect(h.resets, 1);
      expect(
        h.events
            .where((e) => e.type == AuthEventType.logoutCleanupCleared)
            .length,
        1,
      );
    });

    test(
      'stalled Google cleanup and its late failure cannot delay or restore logout',
      () async {
        final h = await _RecoveryHarness.open(live: true);
        final barrier = Completer<void>();
        h.googleBarrier = barrier.future;
        h.googleError = StateError('controlled Google cleanup failure');
        final errors = <Object>[];
        await _captureAsyncErrors(errors, () async {
          await h.provider.signOut();
          await _waitFor(() => h.provider.status == AuthStatus.guest);
          expect(h.provider.status, AuthStatus.guest);
          await _waitFor(() => h.googleCalls == 1);
          expect(h.provider.isSigningOut, isFalse);
          await Future<void>.delayed(const Duration(milliseconds: 90));
          barrier.complete();
          await Future<void>.delayed(const Duration(milliseconds: 20));
          expect(h.provider.status, AuthStatus.guest);
          expect(h.client.auth.currentSession, isNull);
          expect(h.resets, 1);
        });
        expect(errors, isEmpty);
      },
    );
  });

  group('V1-R09 C2 remote response semantics', () {
    Future<_TestSignOutResult> _signOutWithStatus(int status) async {
      final server = await _GoTrueTestServer.start()
        ..logoutPlan.add(_LogoutPlan(status: status));
      addTearDown(server.dispose);

      final service = SupabaseService(
        config: server.config,
        authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
      );
      await service.init();
      addTearDown(service.dispose);

      final gateway = SupabaseAuthGateway(
        service: service,
        credentialsProvider: () async => credentials,
        googleSignInFactory: () => _stubGoogleSignIn(),
      );
      addTearDown(gateway.dispose);
      final provider = AuthProvider(gateway: gateway);
      addTearDown(provider.dispose);

      await provider.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);
      expect(provider.isLoggedIn, isTrue);

      await provider.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      return _TestSignOutResult(
        provider: provider,
        logoutCalls: server.logoutCalls,
      );
    }

    test('2xx success logs out', () async {
      final r = await _signOutWithStatus(200);
      expect(r.provider.isLoggedIn, isFalse);
      expect(r.provider.status, AuthStatus.guest);
      expect(r.provider.error, isNull);
    });

    test('401 terminal cleanup logs out', () async {
      final r = await _signOutWithStatus(401);
      expect(r.provider.isLoggedIn, isFalse);
      expect(r.provider.status, AuthStatus.guest);
      expect(r.provider.error, isNull);
    });

    test('403 terminal cleanup logs out', () async {
      final r = await _signOutWithStatus(403);
      expect(r.provider.isLoggedIn, isFalse);
      expect(r.provider.status, AuthStatus.guest);
      expect(r.provider.error, isNull);
    });

    test('404 terminal cleanup logs out', () async {
      final r = await _signOutWithStatus(404);
      expect(r.provider.isLoggedIn, isFalse);
      expect(r.provider.status, AuthStatus.guest);
      expect(r.provider.error, isNull);
    });

    test('400 failure keeps identity', () async {
      final r = await _signOutWithStatus(400);
      expect(r.provider.isLoggedIn, isTrue);
      expect(r.provider.status, AuthStatus.authenticated);
      expect(r.provider.error, AuthError.signOutFailed);
    });

    test('422 failure keeps identity', () async {
      final r = await _signOutWithStatus(422);
      expect(r.provider.isLoggedIn, isTrue);
      expect(r.provider.status, AuthStatus.authenticated);
      expect(r.provider.error, AuthError.signOutFailed);
    });

    test('429 failure keeps identity', () async {
      final r = await _signOutWithStatus(429);
      expect(r.provider.isLoggedIn, isTrue);
      expect(r.provider.status, AuthStatus.authenticated);
      expect(r.provider.error, AuthError.signOutFailed);
    });

    test('500 failure keeps identity', () async {
      final r = await _signOutWithStatus(500);
      expect(r.provider.isLoggedIn, isTrue);
      expect(r.provider.status, AuthStatus.authenticated);
      expect(r.provider.error, AuthError.signOutFailed);
    });
  });
}

class _TestSignOutResult {
  _TestSignOutResult({required this.provider, required this.logoutCalls});

  final AuthProvider provider;
  final int logoutCalls;
}

class _FakeLocalStorage implements LocalStorage {
  _FakeLocalStorage();

  String? _snapshot;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => _snapshot != null;

  @override
  Future<String?> accessToken() async => _snapshot;

  @override
  Future<void> removePersistedSession() async => _snapshot = null;

  @override
  Future<void> persistSession(String persistSessionString) async =>
      _snapshot = persistSessionString;
}

Future<void> _captureAsyncErrors(
  List<Object> errors,
  Future<void> Function() action,
) {
  // Keep assertion failures on the test's Future, separate from detached
  // asynchronous errors in the zone under observation.
  final done = Completer<void>();
  runZonedGuarded(() async {
    try {
      await action();
      done.complete();
    } catch (error, stack) {
      done.completeError(error, stack);
    }
  }, (error, _) => errors.add(error));
  return done.future;
}

Future<void> _waitFor(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 4));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline))
      fail('Controlled condition did not settle');
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

class _TrackingStorage implements LocalStorage {
  _TrackingStorage(this.snapshot);
  String? snapshot;
  int removeCalls = 0;
  Future<void>? removeBarrier;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async => snapshot != null;
  @override
  Future<String?> accessToken() async => snapshot;
  @override
  Future<void> persistSession(String value) async {
    snapshot = value;
  }

  @override
  Future<void> removePersistedSession() async {
    removeCalls++;
    final barrier = removeBarrier;
    if (barrier != null) await barrier;
    snapshot = null;
  }
}

/// Only exposes the real coordinator/client with a controllable storage delegate.
/// No auth gateway or auth event behavior is faked.
class _HarnessService extends SupabaseService {
  _HarnessService(BackendConfig config, this.coordinator)
    : super(config: config);
  final AuthRecoveryStorageCoordinator coordinator;
  @override
  bool get isInitialized => true;
  @override
  AuthRecoveryStorageCoordinator get recoveryCoordinator => coordinator;
  @override
  AuthRecoveryState get recoveryState => coordinator.readRecoveryState();
}

class _RecoveryHarness {
  _RecoveryHarness(this.server, this.storage, this.coordinator, this.service);
  final _GoTrueTestServer server;
  final _TrackingStorage storage;
  final AuthRecoveryStorageCoordinator coordinator;
  final _HarnessService service;
  late final SupabaseAuthGateway gateway;
  late final AuthProvider provider;
  final events = <AuthEvent>[];
  StreamSubscription<AuthEvent>? _events;
  StreamSubscription<AuthState>? _relay;
  StreamController<AuthState>? _input;
  int sdkCalls = 0;
  int sdkCompletions = 0;
  int sdkFailures = 0;
  int googleCalls = 0;
  int resets = 0;
  Object? localInvocationError;
  Future<void>? googleInitializeBarrier;
  Object? googleInitializeError;
  int googleInitializeCalls = 0;
  Future<void>? googleBarrier;
  Object? googleError;
  bool _stopped = false;
  SupabaseClient get client => Supabase.instance.client;

  List<AuthEventType> get definitiveEvents => events
      .map((e) => e.type)
      .where(
        (e) => e == AuthEventType.signedOut || e == AuthEventType.sessionLost,
      )
      .toList();

  void emit(AuthState event) => _input!.add(event);

  static Future<_RecoveryHarness> open({
    String? snapshot,
    bool absent = false,
    bool installed = false,
    bool missingAfterInit = false,
    bool live = false,
    bool relayEvents = false,
    AuthRecoveryPhase phase = AuthRecoveryPhase.cleanupRequired,
  }) async {
    final server = await _GoTrueTestServer.start();
    final storage = _TrackingStorage(
      absent ? null : snapshot ?? _sessionJson(sessionId: 'sess-a'),
    );
    final project = _projectIdentity(server.config.supabaseUrl);
    final correlation = SessionCorrelation.fromSessionJson(
      _sessionJson(sessionId: 'sess-a'),
      projectIdentity: project,
    );
    var coordinator = await AuthRecoveryStorageCoordinator.open(
      projectIdentity: project,
      delegate: storage,
    );
    if (!installed && !live) {
      expect(
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: phase,
          correlation: correlation,
        ),
        isTrue,
      );
      await coordinator.close();
      coordinator = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: project,
        delegate: storage,
      );
    }
    await Supabase.initialize(
      url: server.config.supabaseUrl,
      anonKey: server.config.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: coordinator.sdkLocalStorage,
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    if (installed && !live) {
      expect(
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: phase,
          correlation: correlation,
        ),
        isTrue,
      );
    }
    if (missingAfterInit) storage.snapshot = null;
    final service = _HarnessService(server.config, coordinator);
    final h = _RecoveryHarness(server, storage, coordinator, service);
    if (relayEvents) {
      h._input = StreamController<AuthState>.broadcast();
      h._relay = Supabase.instance.client.auth.onAuthStateChange.listen(
        h._input!.add,
        onError: h._input!.addError,
      );
    }
    h.gateway = SupabaseAuthGateway(
      service: service,
      signOutTimeout: const Duration(milliseconds: 150),
      googleSignOutTimeout: const Duration(milliseconds: 60),
      googleSignInFactory: () => (
        initialize: ({clientId, serverClientId, nonce, hostedDomain}) async {
          h.googleInitializeCalls++;
          if (h.googleInitializeBarrier != null)
            await h.googleInitializeBarrier;
          if (h.googleInitializeError != null) throw h.googleInitializeError!;
        },
        authenticate: (_) async => throw UnimplementedError(),
        authorization: (_, __) async => throw UnimplementedError(),
        signOut: () async {
          h.googleCalls++;
          if (h.googleBarrier != null) await h.googleBarrier;
          if (h.googleError != null) throw h.googleError!;
        },
      ),
      credentialsProvider: () async => const GoogleCredentialBundle(
        idToken: 'google-id-token',
        accessToken: 'google-access-token',
      ),
      authStateStreamFactory: relayEvents ? () => h._input!.stream : null,
      localSignOut: () {
        h.sdkCalls++;
        if (h.localInvocationError != null) {
          h.sdkFailures++;
          h.sdkCompletions++;
          throw h.localInvocationError!; // Throws before returning a Future.
        }
        return () async {
          try {
            await Supabase.instance.client.auth.signOut(
              scope: SignOutScope.local,
            );
          } catch (_) {
            h.sdkFailures++;
            rethrow;
          } finally {
            h.sdkCompletions++;
          }
        }();
      },
    );
    h.provider = AuthProvider(
      gateway: h.gateway,
      onAccountBoundReset: () => h.resets++,
    );
    h._events = h.gateway.authEvents.listen(h.events.add);
    addTearDown(h.dispose);
    await h.provider.restoreSession();
    await Future<void>.delayed(Duration.zero);
    return h;
  }

  Future<void> stopClient() async {
    if (_stopped) return;
    _stopped = true;
    provider.dispose();
    gateway.dispose();
    await _events?.cancel();
    await _relay?.cancel();
    await _input?.close();
    await Supabase.instance.dispose();
    await coordinator.close();
    service.dispose();
  }

  Future<void> dispose() async {
    await stopClient();
    await server.dispose();
  }
}
