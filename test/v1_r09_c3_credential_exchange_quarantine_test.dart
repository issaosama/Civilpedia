import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:civilpedia/core/backend/backend_config.dart';
import 'package:civilpedia/core/backend/supabase_service.dart';
import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/features/auth/data/auth_recovery_library.dart';
import 'package:civilpedia/features/auth/data/session_correlation.dart';
import 'package:civilpedia/features/auth/data/supabase_auth_gateway.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_error.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/features/auth/domain/repositories/auth_gateway.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// V1-R09 PART 1 SLICE C3 — H3 credential-exchange timeout / late completion /
// stale-session quarantine.
//
// These tests run the FULL production path: real Supabase initialization
// against a controlled GoTrue HTTP server, real SDK session installation, the
// recovery coordinator journal, and the guarded local-storage adapter.
// ---------------------------------------------------------------------------

/// Per-call plan for one `/auth/v1/token` or `/auth/v1/logout` request.
class _CallPlan {
  const _CallPlan({this.status = 200, this.hang = false, this.snapshot});
  final String? snapshot;

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

String _jwt({required Map<String, dynamic> payload}) {
  final h = _base64UrlNoPadding(
    base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'}))),
  );
  final p = _base64UrlNoPadding(
    base64Url.encode(utf8.encode(jsonEncode(payload))),
  );
  return '$h.$p.dummy-signature';
}

String _fakeAccessToken({required String userId, required String sessionId}) =>
    _jwt(
      payload: {
        'sub': userId,
        'session_id': sessionId,
        'exp': 1893456000,
        'aud': 'authenticated',
        'role': 'authenticated',
        'iat': 1609459200,
      },
    );

String _sessionJson({
  required String sessionId,
  required String userId,
  String? refreshToken,
}) {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  return jsonEncode({
    'access_token': _fakeAccessToken(sessionId: sessionId, userId: userId),
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': now + 3600,
    'refresh_token': refreshToken ?? 'test-refresh-token',
    'user': {
      'id': userId,
      'email': 'user@example.com',
      'user_metadata': {'full_name': 'User'},
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

  int tokenCalls = 0;
  int logoutCalls = 0;
  final List<_CallPlan> tokenPlan = [];
  final List<_CallPlan> logoutPlan = [];
  final List<HttpResponse> _heldTokens = [];
  final List<HttpResponse> _heldLogouts = [];

  static Future<_GoTrueTestServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final instance = _GoTrueTestServer._(
      server,
      BackendConfig(
        appEnvRaw: 'development',
        supabaseUrl: 'http://${server.address.host}:${server.port}',
        supabaseAnonKey: 'test-anon-key',
        googleServerClientId: 'g-web-client-id.apps.googleusercontent.com',
      ),
    );
    server.listen(instance._handle);
    return instance;
  }

  void resolveHeldToken({int status = 200}) {
    for (final response in _heldTokens) {
      response.statusCode = status;
      response.write(_sessionJson(sessionId: 'sess-a', userId: 'user-a'));
      response.close();
    }
    _heldTokens.clear();
  }

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
      final plan = idx < tokenPlan.length ? tokenPlan[idx] : const _CallPlan();
      if (plan.hang) {
        _heldTokens.add(response);
        return;
      }
      response.statusCode = plan.status;
      response.headers.contentType = ContentType.json;
      response.write(
        plan.snapshot ?? _sessionJson(sessionId: 'sess-a', userId: 'user-a'),
      );
      await response.close();
      return;
    }
    if (path == '/auth/v1/logout') {
      final idx = logoutCalls++;
      final plan = idx < logoutPlan.length
          ? logoutPlan[idx]
          : const _CallPlan();
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
    for (final response in _heldTokens) {
      await response.close();
    }
    for (final response in _heldLogouts) {
      await response.close();
    }
    _heldTokens.clear();
    _heldLogouts.clear();
    await server.close(force: true);
  }
}

GoogleSignInApi _stubGoogleSignIn() {
  return (
    initialize: ({clientId, serverClientId, nonce, hostedDomain}) async {},
    authenticate: (_) async => throw UnimplementedError(),
    authorization: (_, __) async => throw UnimplementedError(),
    signOut: () async {},
  );
}

const credentials = GoogleCredentialBundle(
  idToken: 'google-id-token',
  accessToken: 'google-access-token',
);

/// The real SDK, Hive journal/coordinator and guarded delegate are used in every
/// test below. Hooks pause processing only; no fake AuthGateway authority.
class _Harness {
  _Harness(this.server, this.storage);
  final _GoTrueTestServer server;
  final _FakeLocalStorage storage;
  late SupabaseService service;
  late SupabaseAuthGateway gateway;
  late AuthProvider provider;
  int localCalls = 0;
  int bootstrapCalls = 0;
  int resets = 0;
  Duration exchangeTimeout = const Duration(milliseconds: 80);
  Duration mutationTimeout = const Duration(milliseconds: 100);
  Future<void> Function(CredentialExchangeCheckpoint)? checkpoint;

  AuthRecoveryStorageCoordinator get coordinator =>
      service.recoveryCoordinator!;
  SupabaseClient get client => Supabase.instance.client;
  AuthRecoveryJournalEntry? get entry => coordinator.readRecoveryEntry();
  SessionCorrelation get exactA => SessionCorrelation(
    userId: 'user-a',
    sessionId: 'sess-a',
    projectIdentity: _projectIdentity(server.config.supabaseUrl),
  );

  Future<void> initialize() async {
    service = SupabaseService(
      config: server.config,
      recoveryDelegate: storage,
      authOptions: const FlutterAuthClientOptions(
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
    await service.init();
    expect(service.isInitialized, isTrue);
    gateway = SupabaseAuthGateway(
      service: service,
      credentialsProvider: () async => credentials,
      googleSignInFactory: _stubGoogleSignIn,
      credentialExchangeTimeout: exchangeTimeout,
      signOutTimeout: mutationTimeout,
      exchangeCheckpoint: (point) async {
        await checkpoint?.call(point);
      },
      localSignOut: () async {
        localCalls++;
        await client.auth.signOut(scope: SignOutScope.local);
      },
    );
    provider = AuthProvider(
      gateway: gateway,
      onPostAuth: (_) async {
        bootstrapCalls++;
        return PostAuthOutcome.success;
      },
      onAccountBoundReset: () {
        resets++;
      },
    );
  }

  Future<void> restart() async {
    provider.dispose();
    gateway.dispose();
    await Supabase.instance.dispose();
    await coordinator.close();
    service.dispose();
    checkpoint = null;
    await initialize();
    await _until(
      () =>
          gateway.recoveryStatus !=
          AuthRecoveryStatus.localResetRestartRequired,
    );
  }

  Future<void> installB() async {
    final snapshot = _sessionJson(sessionId: 'sess-b', userId: 'user-b');
    await client.auth.setInitialSession(snapshot);
    // Drain the installed SDK's asynchronous persistence listener.
    await Future<void>.delayed(Duration.zero);
    await coordinator.sdkLocalStorage.persistSession(
      jsonEncode(client.auth.currentSession!.toJson()),
    );
    expect(client.auth.currentUser?.id, 'user-b');
    expect(
      SessionCorrelation.fromSessionJson(
        storage.snapshot!,
        projectIdentity: _projectIdentity(server.config.supabaseUrl),
      ).userId,
      'user-b',
    );
  }

  Future<void> dispose() async {
    provider.dispose();
    gateway.dispose();
    await server.dispose();
    try {
      await Supabase.instance.dispose();
    } catch (_) {}
    await coordinator.close();
    service.dispose();
  }
}

Future<void> _until(bool Function() condition) async {
  final end = DateTime.now().add(const Duration(seconds: 4));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Expected transition did not settle');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

class _FakeLocalStorage implements LocalStorage {
  String? snapshot;
  int reads = 0;
  int removeCalls = 0;
  int writes = 0;
  void Function(int)? onRead;
  Future<void> Function(int)? onReadAsync;
  Future<void>? removeBarrier;
  bool failRead = false;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async => snapshot != null;
  @override
  Future<String?> accessToken() async {
    reads++;
    onRead?.call(reads);
    await onReadAsync?.call(reads);
    if (failRead) throw StateError('controlled storage failure');
    return snapshot;
  }

  @override
  Future<void> removePersistedSession() async {
    removeCalls++;
    if (removeBarrier != null) await removeBarrier;
    snapshot = null;
  }

  @override
  Future<void> persistSession(String value) async {
    writes++;
    snapshot = value;
  }
}

void main() {
  late Directory directory;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = Directory.systemTemp.createTempSync('c3_addendum_');
    Hive.init(directory.path);
  });
  tearDown(() async {
    try {
      await Supabase.instance.dispose();
    } catch (_) {}
    await Hive.close();
    directory.deleteSync(recursive: true);
  });

  Future<_Harness> create({
    bool hangingToken = false,
    AuthRecoveryPhase? phase,
    String? snapshot,
    bool exact = false,
    List<_CallPlan> logoutPlans = const [],
  }) async {
    final server = await _GoTrueTestServer.start();
    if (hangingToken) server.tokenPlan.add(const _CallPlan(hang: true));
    server.logoutPlan.addAll(logoutPlans);
    final storage = _FakeLocalStorage()..snapshot = snapshot;
    if (phase != null) {
      final coordinator = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: _projectIdentity(server.config.supabaseUrl),
        delegate: storage,
      );
      expect(
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.credentialExchange,
          phase: phase,
          correlation: SessionCorrelation(
            userId: exact ? 'user-a' : 'credential-exchange-pending-0',
            sessionId: exact ? 'sess-a' : null,
            projectIdentity: _projectIdentity(server.config.supabaseUrl),
          ),
        ),
        isTrue,
      );
      await coordinator.close();
    }
    final h = _Harness(server, storage);
    await h.initialize();
    addTearDown(h.dispose);
    return h;
  }

  test(
    'journaled healthy in-time commit admits once through receipt',
    () async {
      final h = await create();
      h.checkpoint = (point) async {
        if (point == CredentialExchangeCheckpoint.beforeCommitCompletion) {
          expect(h.entry!.phase, AuthRecoveryPhase.committing);
          expect(h.entry!.sessionId, 'sess-a');
          expect(h.gateway.canAccountAuthorityBeGranted, isFalse);
          expect(h.bootstrapCalls, 0);
        }
      };
      await h.provider.signInWithGoogle();
      expect(h.provider.isLoggedIn, isTrue);
      expect(h.bootstrapCalls, 1);
      expect(h.entry, isNull);
      expect(h.server.tokenCalls, 1);
      expect(h.server.logoutCalls, 0);
      expect(h.localCalls, 0);
      expect(
        h.gateway.consumeCredentialAdmission(h.provider.session!),
        isFalse,
      );
    },
  );

  test('journaled in-time raw failure verifies absence and closes', () async {
    final h = await create();
    h.server.tokenPlan.add(const _CallPlan(status: 400));
    await h.provider.signInWithGoogle();
    expect(h.provider.isLoggedIn, isFalse);
    expect(h.provider.status, AuthStatus.error);
    expect(h.entry, isNull);
    expect(h.storage.snapshot, isNull);
    expect(h.server.logoutCalls, 0);
    expect(h.storage.removeCalls, 0);
  });

  test(
    'timeout immediately exposes recovery and prevents overlapping exchange',
    () async {
      final h = await create(hangingToken: true);
      await h.provider.signInWithGoogle();
      expect(h.provider.status, AuthStatus.cleanupRecovery);
      expect(h.provider.isSigningIn, isFalse);
      expect(h.provider.isAuthorityBlocked, isTrue);
      await _until(() => h.entry?.phase == AuthRecoveryPhase.timedOutPending);
      final id = h.entry!.operationId;
      final reads = h.storage.reads;
      expect(await h.gateway.retryAuthRecovery(), AuthRecoveryResult.busy);
      expect(h.storage.reads, reads);
      await h.provider.signInWithGoogle();
      expect(h.server.tokenCalls, 1);
      expect(h.entry!.operationId, id);
      expect(h.entry!.sessionId, isNull);
      expect(h.bootstrapCalls, 0);
    },
  );

  test(
    'ACTIVE recovery is busy with zero storage inspection or mutation',
    () async {
      final h = await create(hangingToken: true);
      final pending = h.provider.signInWithGoogle();
      await _until(() => h.server.tokenCalls == 1);
      final entry = h.entry!;
      final reads = h.storage.reads;
      expect(await h.gateway.retryAuthRecovery(), AuthRecoveryResult.busy);
      expect(h.storage.reads, reads);
      expect(h.entry!.toMap(), entry.toMap());
      h.server.resolveHeldToken(status: 400);
      await pending;
    },
  );

  test(
    'COMMITTING blocks retry/events and cannot be overwritten by timeout',
    () async {
      final h = await create();
      final entered = Completer<void>();
      final release = Completer<void>();
      h.checkpoint = (point) async {
        if (point == CredentialExchangeCheckpoint.beforeCommitCompletion) {
          entered.complete();
          await release.future;
        }
      };
      final pending = h.provider.signInWithGoogle();
      await entered.future;
      final id = h.entry!.operationId;
      final reads = h.storage.reads;
      await Future<void>.delayed(const Duration(milliseconds: 130));
      expect(await h.gateway.retryAuthRecovery(), AuthRecoveryResult.busy);
      expect(h.storage.reads, reads);
      expect(h.entry!.phase, AuthRecoveryPhase.committing);
      expect(h.entry!.operationId, id);
      expect(h.provider.isLoggedIn, isFalse);
      expect(h.bootstrapCalls, 0);
      release.complete();
      await pending;
      expect(h.provider.isLoggedIn, isTrue);
      expect(h.server.tokenCalls, 1);
    },
  );

  test(
    'late raw failure with both absent releases g, fresh g+1 succeeds',
    () async {
      final h = await create(hangingToken: true);
      await h.provider.signInWithGoogle();
      final id = h.entry!.operationId;
      h.server.resolveHeldToken(status: 400);
      await _until(() => h.gateway.recoveryStatus == AuthRecoveryStatus.none);
      await h.provider.signInWithGoogle();
      expect(h.server.tokenCalls, 2);
      expect(h.provider.isLoggedIn, isTrue);
      expect(h.bootstrapCalls, 1);
      expect(h.entry, isNull);
      expect(id, isNotEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 130));
      expect(h.provider.isLoggedIn, isTrue);
      expect(h.server.logoutCalls, 0);
      expect(h.storage.removeCalls, 0);
    },
  );

  for (final withMemory in [false, true]) {
    test(
      'late raw failure does not attribute unexpected B (memory=$withMemory)',
      () async {
        final h = await create(hangingToken: true);
        await h.provider.signInWithGoogle();
        if (withMemory) {
          await h.installB();
        } else {
          h.storage.snapshot = _sessionJson(
            sessionId: 'sess-b',
            userId: 'user-b',
          );
        }
        final bytes = h.storage.snapshot;
        h.server.resolveHeldToken(status: 400);
        await _until(
          () =>
              h.gateway.recoveryStatus ==
              AuthRecoveryStatus.exchangeBlockedUnattributed,
        );
        expect(h.storage.snapshot, bytes);
        expect(h.storage.removeCalls, 0);
        expect(h.localCalls, 0);
        expect(h.server.logoutCalls, 0);
        expect(h.provider.isLoggedIn, isFalse);
        expect(h.bootstrapCalls, 0);
      },
    );
  }

  test(
    'late A uses same record with no gap, neutralizes, then fresh g+1 admits',
    () async {
      final h = await create(hangingToken: true);
      await h.provider.signInWithGoogle();
      await _until(() => h.entry?.phase == AuthRecoveryPhase.timedOutPending);
      final original = h.entry!;
      final phases = <AuthRecoveryPhase>[];
      final box = Hive.box<dynamic>(
        '${AppStorageKeys.authRecoveryJournalBox}_${_projectIdentity(h.server.config.supabaseUrl)}',
      );
      final subscription = box
          .watch(key: AppStorageKeys.authRecoveryJournalEntry)
          .listen((event) {
            if (!event.deleted) {
              final entry = AuthRecoveryJournalEntry.fromMap(
                Map<String, dynamic>.from(event.value as Map),
              );
              expect(entry.operationId, original.operationId);
              expect(entry.operationType, original.operationType);
              expect(entry.createdAt, original.createdAt);
              phases.add(entry.phase);
            } else {
              expect(h.client.auth.currentSession, isNull);
              expect(h.storage.snapshot, isNull);
            }
          });
      addTearDown(subscription.cancel);
      h.server.resolveHeldToken();
      await _until(() => h.gateway.recoveryStatus == AuthRecoveryStatus.none);
      expect(
        phases,
        containsAllInOrder([
          AuthRecoveryPhase.neutralizing,
          AuthRecoveryPhase.cleanupRequired,
        ]),
      );
      expect(h.provider.isLoggedIn, isFalse);
      expect(h.bootstrapCalls, 0);
      expect(h.localCalls, 1);
      expect(h.storage.removeCalls, 1);
      expect(h.client.auth.currentSession, isNull);
      await subscription.cancel();
      await h.provider.signInWithGoogle();
      expect(h.provider.isLoggedIn, isTrue);
      expect(h.bootstrapCalls, 1);
      expect(h.server.tokenCalls, 2);
    },
  );

  for (final withMemory in [true]) {
    test(
      'exact A cleanup preflight preserves B bytes and memory=$withMemory',
      () async {
        final h = await create(hangingToken: true);
        h.checkpoint = (point) async {
          if (point == CredentialExchangeCheckpoint.afterLateUpgrade) {
            await h.installB();
          }
        };
        await h.provider.signInWithGoogle();
        h.server.resolveHeldToken();
        await _until(
          () =>
              h.gateway.recoveryStatus ==
              AuthRecoveryStatus.exchangeBlockedUnattributed,
        );
        final bytes = h.storage.snapshot;
        expect(h.client.auth.currentUser?.id, 'user-b');
        expect(h.localCalls, 0);
        expect(h.storage.removeCalls, 0);
        expect(h.server.logoutCalls, withMemory ? 0 : 1);
        expect(h.provider.isLoggedIn, isFalse);
        expect(h.bootstrapCalls, 0);
        await h.provider.signInWithGoogle();
        expect(h.server.tokenCalls, 1);
        expect(h.storage.snapshot, bytes);
      },
    );
  }

  for (final point in [
    CredentialExchangeCheckpoint.beforeCommitCompletion,
    CredentialExchangeCheckpoint.afterCommitCompletion,
  ]) {
    for (final replacement in ['B', 'loss']) {
      test(
        'commit $point revalidates SDK after awaited $replacement',
        () async {
          final h = await create();
          h.checkpoint = (where) async {
            if (where != point) return;
            if (replacement == 'B') {
              await h.installB();
            } else {
              await h.client.auth.signOut(scope: SignOutScope.local);
              await Future<void>.delayed(Duration.zero);
            }
          };
          await h.provider.signInWithGoogle();
          expect(h.provider.isLoggedIn, isFalse);
          expect(h.provider.session, isNull);
          expect(h.bootstrapCalls, 0);
          expect(h.gateway.canAccountAuthorityBeGranted, isFalse);
          expect(h.localCalls, 0);
          if (replacement == 'B') {
            expect(h.client.auth.currentUser?.id, 'user-b');
            expect(h.server.logoutCalls, 0);
            expect(h.storage.removeCalls, 0);
          }
        },
      );
    }
  }

  test(
    'single-use receipt rejects SDK replacement after gateway returns',
    () async {
      final h = await create();
      final candidate = await h.gateway.signInWithGoogle();
      expect(candidate, isNotNull);
      expect(h.gateway.canAccountAuthorityBeGranted, isFalse);
      await h.installB();
      final bytes = h.storage.snapshot;
      expect(h.gateway.consumeCredentialAdmission(candidate!), isFalse);
      expect(h.gateway.consumeCredentialAdmission(candidate), isFalse);
      await _until(() => h.gateway.recoveryStatus != AuthRecoveryStatus.none);
      expect(h.storage.snapshot, bytes);
      expect(h.localCalls, 0);
      expect(h.server.logoutCalls, 0);
      expect(h.bootstrapCalls, 0);
    },
  );

  for (final point in [
    CredentialExchangeCheckpoint.beforeLateUpgrade,
    CredentialExchangeCheckpoint.afterLateUpgrade,
    CredentialExchangeCheckpoint.remoteSuccessBeforeCleanup,
  ]) {
    test(
      'crash/reconstruction preserves blocking same journal at $point',
      () async {
        final h = await create(hangingToken: true);
        final reached = Completer<void>();
        final release = Completer<void>();
        h.checkpoint = (where) async {
          if (where == point) {
            reached.complete();
            await release.future;
          }
        };
        await h.provider.signInWithGoogle();
        final original = h.entry!;
        h.server.resolveHeldToken();
        await reached.future;
        await Future<void>.delayed(Duration.zero);
        expect(h.storage.snapshot, isNotNull);
        expect(h.entry!.operationId, original.operationId);
        expect(h.entry!.createdAt, original.createdAt);
        h.gateway.dispose(); // old callbacks lose their process ownership
        release.complete();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await h.restart();
        expect(h.entry!.operationId, original.operationId);
        expect(h.gateway.canAccountAuthorityBeGranted, isFalse);
        if (point == CredentialExchangeCheckpoint.beforeLateUpgrade) {
          expect(h.entry!.sessionId, isNull); // production-real placeholder
          await h.provider.retryAuthCleanup();
          expect(
            h.gateway.recoveryStatus,
            AuthRecoveryStatus.exchangeBlockedUnattributed,
          );
          expect(h.server.logoutCalls, 0);
          expect(h.storage.removeCalls, 0);
        } else {
          final before = h.server.logoutCalls;
          await h.provider.retryAuthCleanup();
          expect(h.gateway.recoveryStatus, AuthRecoveryStatus.none);
          expect(h.storage.snapshot, isNull);
          expect(h.client.auth.currentSession, isNull);
          expect(h.localCalls, 0, reason: 'restart memory is absent');
          expect(
            h.server.logoutCalls,
            point == CredentialExchangeCheckpoint.remoteSuccessBeforeCleanup
                ? before
                : before + 1,
          );
        }
      },
    );
  }

  test(
    'upgrade write failure reconstructs old blocking placeholder, never clean',
    () async {
      final h = await create(hangingToken: true);
      h.checkpoint = (where) async {
        if (where == CredentialExchangeCheckpoint.beforeLateUpgrade) {
          await h.coordinator.close();
        }
      };
      await h.provider.signInWithGoogle();
      final original = h.entry!;
      h.server.resolveHeldToken();
      await _until(
        () => h.gateway.recoveryStatus == AuthRecoveryStatus.storageFailure,
      );
      expect(h.provider.isLoggedIn, isFalse);
      expect(h.server.logoutCalls, 0);
      await h.restart();
      expect(h.entry!.operationId, original.operationId);
      expect(h.entry!.sessionId, isNull);
      expect(h.entry!.phase, AuthRecoveryPhase.timedOutPending);
      expect(h.gateway.canAccountAuthorityBeGranted, isFalse);
    },
  );

  test(
    'raw-success processing exception remains durable blocked, never raw failure',
    () async {
      final h = await create(hangingToken: true);
      h.checkpoint = (where) async {
        if (where == CredentialExchangeCheckpoint.afterLateUpgrade) {
          throw StateError('controlled processing failure');
        }
      };
      await h.provider.signInWithGoogle();
      final id = h.entry!.operationId;
      h.server.resolveHeldToken();
      await _until(
        () =>
            h.gateway.recoveryStatus ==
            AuthRecoveryStatus.exchangeBlockedCleanupFailure,
      );
      expect(h.entry!.operationId, id);
      expect(h.entry!.sessionId, 'sess-a');
      expect(h.storage.snapshot, isNotNull);
      expect(h.bootstrapCalls, 0);
      expect(h.server.logoutCalls, 0);
      expect(h.provider.isLoggedIn, isFalse);
    },
  );

  test('remote deadline releases queue/UI but not revoke ownership', () async {
    final h = await create(
      hangingToken: true,
      logoutPlans: [const _CallPlan(hang: true)],
    );
    await h.provider.signInWithGoogle();
    h.server.resolveHeldToken();
    await _until(() => h.server.logoutCalls == 1);
    await _until(
      () =>
          h.gateway.recoveryStatus ==
          AuthRecoveryStatus.exchangeBlockedCleanupFailure,
    );
    final record = h.entry!;
    final inspect = await h.coordinator.runOwnedRecoveryOperation<bool>(
      expectedOperationId: record.operationId,
      action: (tx) async => await tx.readRecoverySnapshot() != null,
    );
    expect(inspect.value, isTrue, reason: 'network never holds the queue');
    await h.provider.retryAuthCleanup();
    expect(h.provider.isRecoveryRetryBusy, isFalse);
    expect(h.server.logoutCalls, 1);
    expect(h.server.tokenCalls, 1);
    h.server.resolveHeldLogout();
    await _until(() => h.gateway.recoveryStatus == AuthRecoveryStatus.none);
    expect(h.localCalls, 1);
    expect(h.storage.snapshot, isNull);
  });

  test(
    'remote failure retains quarantine and explicit retry does not skip revoke',
    () async {
      final h = await create(
        hangingToken: true,
        logoutPlans: [const _CallPlan(status: 500)],
      );
      await h.provider.signInWithGoogle();
      h.server.resolveHeldToken();
      await _until(
        () =>
            h.gateway.recoveryStatus ==
            AuthRecoveryStatus.exchangeBlockedCleanupFailure,
      );
      expect(h.entry!.phase, AuthRecoveryPhase.neutralizing);
      expect(h.storage.snapshot, isNotNull);
      expect(h.storage.removeCalls, 0);
      expect(h.localCalls, 0);
      await h.provider.retryAuthCleanup();
      expect(h.gateway.recoveryStatus, AuthRecoveryStatus.none);
      expect(
        h.server.logoutCalls,
        3,
        reason: 'retry revoke + real SDK local logout',
      );
    },
  );

  test(
    'local SDK deadline is finite, observed, and cannot relaunch raw cleanup',
    () async {
      final h = await create(
        hangingToken: true,
        logoutPlans: [const _CallPlan(), const _CallPlan(hang: true)],
      );
      await h.provider.signInWithGoogle();
      h.server.resolveHeldToken();
      await _until(() => h.server.logoutCalls == 2);
      await _until(
        () =>
            h.gateway.recoveryStatus ==
            AuthRecoveryStatus.exchangeBlockedCleanupFailure,
      );
      await h.provider.retryAuthCleanup();
      expect(h.provider.isRecoveryRetryBusy, isFalse);
      expect(h.localCalls, 1);
      expect(h.server.logoutCalls, 2);
      expect(h.entry, isNotNull);
      h.server.resolveHeldLogout();
      await _until(() => h.gateway.recoveryStatus == AuthRecoveryStatus.none);
      expect(h.storage.snapshot, isNull);
      expect(h.client.auth.currentSession, isNull);
    },
  );

  test(
    'delegate cleanup drains behind finite UI deadline and survives crash',
    () async {
      final h = await create(hangingToken: true);
      final release = Completer<void>();
      h.storage.removeBarrier = release.future;
      await h.provider.signInWithGoogle();
      final id = h.entry!.operationId;
      h.server.resolveHeldToken();
      await _until(() => h.storage.removeCalls == 1);
      await _until(
        () =>
            h.gateway.recoveryStatus ==
            AuthRecoveryStatus.exchangeBlockedCleanupFailure,
      );
      expect(h.entry!.operationId, id);
      expect(h.entry!.phase, AuthRecoveryPhase.cleanupRequired);
      var nextSlotRan = false;
      final queued = h.coordinator.runOwnedRecoveryOperation<bool>(
        expectedOperationId: id,
        action: (_) async {
          nextSlotRan = true;
          return true;
        },
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(nextSlotRan, isFalse);
      h.gateway.dispose();
      release.complete();
      await queued;
      expect(h.entry!.operationId, id);
      await h.restart();
      expect(h.entry!.operationId, id);
      await h.provider.retryAuthCleanup();
      expect(h.gateway.recoveryStatus, AuthRecoveryStatus.none);
      expect(h.storage.removeCalls, 1);
    },
  );

  for (final (index, snapshot) in [
    _sessionJson(sessionId: 'sess-a', userId: 'user-a'),
    _sessionJson(sessionId: 'sess-b', userId: 'user-b'),
    '{malformed',
    '{"user":{"id":"user-a"}}',
  ].indexed) {
    test(
      'insufficient production placeholder never attributes snapshot $index',
      () async {
        final h = await create(
          phase: AuthRecoveryPhase.timedOutPending,
          snapshot: snapshot,
        );
        final original = h.entry!;
        expect(original.sessionId, isNull);
        await h.provider.retryAuthCleanup();
        expect(h.entry!.operationId, original.operationId);
        expect(h.entry!.phase, AuthRecoveryPhase.blockedUnattributed);
        expect(h.storage.snapshot, snapshot);
        expect(h.localCalls, 0);
        expect(h.server.logoutCalls, 0);
        expect(h.storage.removeCalls, 0);
        expect(h.provider.isLoggedIn, isFalse);
      },
    );
  }

  for (final phase in [
    AuthRecoveryPhase.neutralizing,
    AuthRecoveryPhase.cleanupRequired,
  ]) {
    test('restart exact A / persisted B preserved in $phase', () async {
      final bytes = _sessionJson(sessionId: 'sess-b', userId: 'user-b');
      final h = await create(phase: phase, exact: true, snapshot: bytes);
      expect(h.client.auth.currentSession, isNull);
      await h.provider.retryAuthCleanup();
      expect(h.storage.snapshot, bytes);
      expect(h.storage.removeCalls, 0);
      expect(h.server.logoutCalls, 0);
      expect(h.localCalls, 0);
      expect(h.gateway.canAccountAuthorityBeGranted, isFalse);
    });
  }

  for (final malformed in [false, true]) {
    test(
      'explicit exact-byte reset malformed=$malformed stays blocked until restart',
      () async {
        final bytes = malformed
            ? '{invalid raw bytes'
            : _sessionJson(sessionId: 'unknown', userId: 'unknown-user');
        final h = await create(
          phase: AuthRecoveryPhase.timedOutPending,
          snapshot: bytes,
        );
        await h.provider.retryAuthCleanup();
        final original = h.entry!;
        expect(
          h.gateway.recoveryStatus,
          AuthRecoveryStatus.exchangeBlockedUnattributed,
        );
        expect(h.storage.removeCalls, 0, reason: 'no automatic reset');
        await h.provider.resetQuarantinedDeviceSignIn();
        expect(h.storage.snapshot, isNull);
        expect(h.storage.removeCalls, 1);
        expect(h.localCalls, 0);
        expect(h.server.logoutCalls, 0);
        expect(
          h.gateway.recoveryStatus,
          AuthRecoveryStatus.localResetRestartRequired,
        );
        expect(h.entry!.operationId, original.operationId);
        expect(h.entry!.createdAt, original.createdAt);
        expect(
          h.entry!.phase,
          AuthRecoveryPhase.localResetAppliedRestartRequired,
        );
        await h.provider.signInWithGoogle();
        await h.provider.retryAuthCleanup();
        expect(h.server.tokenCalls, 0);
        expect(h.provider.isLoggedIn, isFalse);
        expect(h.entry, isNotNull);
        await h.restart();
        expect(h.entry, isNull);
        expect(h.provider.status, AuthStatus.guest);
        expect(h.gateway.recoveryStatus, AuthRecoveryStatus.none);
        await h.provider.signInWithGoogle();
        expect(h.provider.isLoggedIn, isTrue);
      },
    );
  }

  test('exact-byte reset rejects X to B race without any removal', () async {
    final h = await create(
      phase: AuthRecoveryPhase.blockedUnattributed,
      snapshot: '{unknown X',
    );
    final original = h.entry!;
    final b = _sessionJson(sessionId: 'sess-b', userId: 'user-b');
    final secondRead = h.storage.reads + 2;
    h.storage.onRead = (read) {
      if (read == secondRead) h.storage.snapshot = b;
    };
    await h.provider.resetQuarantinedDeviceSignIn();
    expect(h.storage.snapshot, b);
    expect(h.storage.removeCalls, 0);
    expect(h.entry!.operationId, original.operationId);
    expect(h.entry!.phase, AuthRecoveryPhase.blockedUnattributed);
    expect(h.localCalls, 0);
    expect(h.server.logoutCalls, 0);
    expect(h.provider.isLoggedIn, isFalse);
  });

  test('explicit local reset never signs out unknown SDK memory B', () async {
    final h = await create(
      phase: AuthRecoveryPhase.blockedUnattributed,
      snapshot: '{unknown X',
    );
    await h.installB();
    await h.provider.resetQuarantinedDeviceSignIn();
    expect(h.client.auth.currentUser?.id, 'user-b');
    expect(h.storage.snapshot, isNull);
    expect(h.localCalls, 0);
    expect(h.server.logoutCalls, 0);
    expect(h.provider.isLoggedIn, isFalse);
    expect(
      h.gateway.recoveryStatus,
      AuthRecoveryStatus.localResetRestartRequired,
    );
    await h.provider.signInWithGoogle();
    expect(h.server.tokenCalls, 0);
  });

  test(
    'next startup reset marker + unexpected B never completes or deletes',
    () async {
      final b = _sessionJson(sessionId: 'sess-b', userId: 'user-b');
      final h = await create(
        phase: AuthRecoveryPhase.localResetAppliedRestartRequired,
        snapshot: b,
      );
      await _until(
        () =>
            h.gateway.recoveryStatus ==
            AuthRecoveryStatus.exchangeBlockedUnattributed,
      );
      expect(h.entry!.phase, AuthRecoveryPhase.blockedUnattributed);
      expect(h.storage.snapshot, b);
      expect(h.storage.removeCalls, 0);
      expect(h.server.logoutCalls, 0);
      expect(h.provider.isLoggedIn, isFalse);
    },
  );

  for (final phase in [
    null,
    AuthRecoveryPhase.active,
    AuthRecoveryPhase.neutralizing,
    AuthRecoveryPhase.cleanupRequired,
    AuthRecoveryPhase.localResetAppliedRestartRequired,
  ]) {
    test('reset outside BLOCKED_UNATTRIBUTED rejected ($phase)', () async {
      final h = await create(phase: phase);
      expect(
        await h.gateway.resetQuarantinedDeviceSignIn(),
        isNot(AuthRecoveryResult.cleanGuest),
      );
      expect(h.storage.removeCalls, 0);
      expect(h.server.logoutCalls, 0);
      expect(h.localCalls, 0);
    });
  }

  for (final point in [
    CredentialExchangeCheckpoint.beforeCommitCompletion,
    CredentialExchangeCheckpoint.remoteSuccessBeforeCleanup,
  ]) {
    test('journal completion failure stays blocked at $point', () async {
      final late =
          point == CredentialExchangeCheckpoint.remoteSuccessBeforeCleanup;
      final h = await create(hangingToken: late);
      h.checkpoint = (where) async {
        if (where == point) await h.coordinator.close();
      };
      await h.provider.signInWithGoogle();
      if (late) h.server.resolveHeldToken();
      await _until(
        () => h.gateway.recoveryStatus == AuthRecoveryStatus.storageFailure,
      );
      expect(h.provider.isLoggedIn, isFalse);
      expect(h.bootstrapCalls, 0);
      expect(h.gateway.canAccountAuthorityBeGranted, isFalse);
      await h.provider.signInWithGoogle();
      expect(h.server.tokenCalls, 1);
    });
  }

  test(
    'disposed generation late raw success makes zero recovery mutations',
    () async {
      final h = await create(hangingToken: true);
      await h.provider.signInWithGoogle();
      await _until(() => h.entry!.phase == AuthRecoveryPhase.timedOutPending);
      final before = h.entry!.toMap();
      h.gateway.dispose();
      h.server.resolveHeldToken();
      await _until(() => h.client.auth.currentSession != null);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(h.entry!.toMap(), before);
      expect(h.localCalls, 0);
      expect(h.server.logoutCalls, 0);
      expect(h.storage.removeCalls, 0);
      expect(h.bootstrapCalls, 0);
    },
  );

  for (final state in [
    'ACTIVE',
    'COMMITTING',
    'TIMED_OUT_PENDING',
    'NEUTRALIZING',
    'BLOCKED_CLEANUP_FAILURE',
    'BLOCKED_UNATTRIBUTED',
    'LOCAL_RESET_RESTART_REQUIRED',
  ]) {
    test(
      'account-bearing real SDK events denied, definitive events forwarded: $state',
      () async {
        final h = await create(
          hangingToken: state != 'COMMITTING',
          phase:
              [
                'BLOCKED_UNATTRIBUTED',
                'LOCAL_RESET_RESTART_REQUIRED',
              ].contains(state)
              ? AuthRecoveryPhase.blockedUnattributed
              : null,
          snapshot:
              [
                'BLOCKED_UNATTRIBUTED',
                'LOCAL_RESET_RESTART_REQUIRED',
              ].contains(state)
              ? '{unknown}'
              : null,
          logoutPlans: state == 'NEUTRALIZING'
              ? [const _CallPlan(hang: true)]
              : state == 'BLOCKED_CLEANUP_FAILURE'
              ? [const _CallPlan(status: 500)]
              : [],
        );
        Future<void>? signIn;
        Completer<void>? commitRelease;
        if (state == 'COMMITTING') {
          final entered = Completer<void>();
          commitRelease = Completer<void>();
          h.checkpoint = (point) async {
            if (point == CredentialExchangeCheckpoint.beforeCommitCompletion) {
              entered.complete();
              await commitRelease!.future;
            }
          };
          signIn = h.provider.signInWithGoogle();
          await entered.future;
        } else if (state == 'LOCAL_RESET_RESTART_REQUIRED') {
          await h.provider.resetQuarantinedDeviceSignIn();
        } else if (state != 'BLOCKED_UNATTRIBUTED') {
          signIn = h.provider.signInWithGoogle();
          if (state == 'ACTIVE') {
            await _until(() => h.server.tokenCalls == 1);
          } else {
            await signIn;
            if (['NEUTRALIZING', 'BLOCKED_CLEANUP_FAILURE'].contains(state)) {
              h.server.resolveHeldToken();
              await _until(() => h.server.logoutCalls == 1);
              if (state == 'BLOCKED_CLEANUP_FAILURE') {
                await _until(
                  () =>
                      h.gateway.recoveryStatus ==
                      AuthRecoveryStatus.exchangeBlockedCleanupFailure,
                );
              }
            }
          }
        }
        final events = <AuthEvent>[];
        final subscription = h.gateway.authEvents.listen(events.add);
        final b = Session.fromJson(
          jsonDecode(_sessionJson(sessionId: 'sess-b', userId: 'user-b')),
        )!;
        for (final event in [
          AuthChangeEvent.initialSession,
          AuthChangeEvent.signedIn,
          AuthChangeEvent.tokenRefreshed,
          AuthChangeEvent.userUpdated,
          AuthChangeEvent.mfaChallengeVerified,
        ]) {
          h.client.auth.notifyAllSubscribers(event, session: b);
        }
        h.client.auth.notifyAllSubscribers(AuthChangeEvent.signedOut);
        h.client.auth.notifyAllSubscribers(AuthChangeEvent.userDeleted);
        await Future<void>.delayed(Duration.zero);
        expect(events.where((event) => event.session != null), isEmpty);
        expect(
          events.map((event) => event.type),
          contains(AuthEventType.signedOut),
        );
        expect(
          events.map((event) => event.type),
          contains(AuthEventType.sessionLost),
        );
        expect(h.provider.isLoggedIn, isFalse);
        expect(h.bootstrapCalls, 0);
        await subscription.cancel();
        h.gateway.dispose();
        commitRelease?.complete();
        if (signIn != null) await signIn;
      },
    );
  }

  test(
    'late failure read rechecks SDK memory after awaited persistence read',
    () async {
      final h = await create(hangingToken: true);
      await h.provider.signInWithGoogle();
      var installed = false;
      h.storage.onReadAsync = (_) async {
        if (installed) return;
        installed = true;
        await h.client.auth.setInitialSession(
          _sessionJson(sessionId: 'sess-b', userId: 'user-b'),
        );
        // Even returning absence cannot authorize completion after memory changed.
        h.storage.snapshot = null;
      };
      h.server.resolveHeldToken(status: 400);
      await _until(
        () =>
            h.gateway.recoveryStatus ==
            AuthRecoveryStatus.exchangeBlockedUnattributed,
      );
      expect(h.client.auth.currentUser?.id, 'user-b');
      expect(h.entry, isNotNull);
      expect(h.localCalls, 0);
      expect(h.server.logoutCalls, 0);
      expect(h.storage.removeCalls, 0);
    },
  );

  test(
    'raw late network failure and settlement exceptions have no unhandled zone error',
    () async {
      final h = await create(hangingToken: true);
      final errors = <Object>[];
      final done = Completer<void>();
      runZonedGuarded(
        () async {
          await h.provider.signInWithGoogle();
          h.server.resolveHeldToken(status: 400);
          await _until(
            () => h.gateway.recoveryStatus == AuthRecoveryStatus.none,
          );
          done.complete();
        },
        (error, _) {
          errors.add(error);
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(const Duration(seconds: 5));
      expect(errors, isEmpty);
      expect(h.bootstrapCalls, 0);
    },
  );

  for (final late in [false, true]) {
    test(
      'raw failure journal finalization failure cannot publish clean guest (late=$late)',
      () async {
        final h = await create(hangingToken: true);
        final pending = h.provider.signInWithGoogle();
        await _until(() => h.server.tokenCalls == 1);
        if (late) await pending;
        h.storage.onReadAsync = (_) async {
          h.storage.onReadAsync = null;
          await h.coordinator.close();
        };
        h.server.resolveHeldToken(status: 400);
        await pending;
        await _until(
          () => h.gateway.recoveryStatus == AuthRecoveryStatus.storageFailure,
        );
        expect(h.provider.isLoggedIn, isFalse);
        expect(h.gateway.canAccountAuthorityBeGranted, isFalse);
        expect(h.localCalls, 0);
        expect(h.server.logoutCalls, 0);
      },
    );
  }

  test('begin journal failure prevents raw exchange', () async {
    final h = await create();
    await h.coordinator.close();
    await h.provider.signInWithGoogle();
    expect(h.server.tokenCalls, 0);
    expect(h.provider.isLoggedIn, isFalse);
    expect(h.gateway.canAccountAuthorityBeGranted, isFalse);
  });

  test(
    'timeout phase write failure retains blocking journal and observes raw',
    () async {
      final h = await create(hangingToken: true);
      final signIn = h.provider.signInWithGoogle();
      await _until(() => h.server.tokenCalls == 1);
      await h.coordinator.close();
      await signIn;
      expect(h.provider.isLoggedIn, isFalse);
      h.server.resolveHeldToken(status: 400);
      await _until(
        () => h.gateway.recoveryStatus == AuthRecoveryStatus.storageFailure,
      );
      expect(h.server.tokenCalls, 1);
      expect(h.bootstrapCalls, 0);
      await h.restart();
      expect(h.gateway.canAccountAuthorityBeGranted, isFalse);
    },
  );

  test(
    'reset storage failure preserves bytes and explicit retry remains available',
    () async {
      final h = await create(
        phase: AuthRecoveryPhase.blockedUnattributed,
        snapshot: '{unknown}',
      );
      h.storage.failRead = true;
      await h.provider.resetQuarantinedDeviceSignIn();
      expect(h.provider.isRecoveryRetryBusy, isFalse);
      expect(
        h.gateway.recoveryStatus,
        AuthRecoveryStatus.exchangeBlockedUnattributed,
      );
      expect(h.storage.snapshot, '{unknown}');
      expect(h.storage.removeCalls, 0);
      h.storage.failRead = false;
      await h.provider.resetQuarantinedDeviceSignIn();
      expect(
        h.gateway.recoveryStatus,
        AuthRecoveryStatus.localResetRestartRequired,
      );
      expect(h.localCalls, 0);
      expect(h.server.logoutCalls, 0);
    },
  );

  test(
    'reset marker write failure keeps same durable operation blocked',
    () async {
      final h = await create(
        phase: AuthRecoveryPhase.blockedUnattributed,
        snapshot: '{unknown}',
      );
      final original = h.entry!;
      final finalRead = h.storage.reads + 3;
      h.storage.onReadAsync = (read) async {
        if (read == finalRead) await h.coordinator.close();
      };
      await h.provider.resetQuarantinedDeviceSignIn();
      expect(h.storage.snapshot, isNull);
      expect(h.gateway.canAccountAuthorityBeGranted, isFalse);
      expect(h.provider.isLoggedIn, isFalse);
      expect(h.localCalls, 0);
      expect(h.server.logoutCalls, 0);
      await h.restart();
      expect(h.entry!.operationId, original.operationId);
      expect(h.entry!.phase, AuthRecoveryPhase.blockedUnattributed);
    },
  );

  test(
    'reset completion failure on fresh startup cannot enable sign-in',
    () async {
      final h = await create(
        phase: AuthRecoveryPhase.blockedUnattributed,
        snapshot: '{unknown}',
      );
      await h.provider.resetQuarantinedDeviceSignIn();
      h.storage.onReadAsync = (_) async {
        h.storage.onReadAsync = null;
        final name =
            '${AppStorageKeys.authRecoveryJournalBox}_${_projectIdentity(h.server.config.supabaseUrl)}';
        await Hive.box<dynamic>(name).close();
      };
      await h.restart();
      expect(h.provider.isLoggedIn, isFalse);
      expect(h.gateway.canAccountAuthorityBeGranted, isFalse);
      expect(h.gateway.recoveryStatus, AuthRecoveryStatus.storageFailure);
      await h.provider.signInWithGoogle();
      expect(h.server.tokenCalls, 0);
    },
  );

  test(
    'explicit reset delegate stall is bounded and retains serialization',
    () async {
      final h = await create(
        phase: AuthRecoveryPhase.blockedUnattributed,
        snapshot: '{unknown}',
      );
      final release = Completer<void>();
      h.storage.removeBarrier = release.future;
      await h.provider.resetQuarantinedDeviceSignIn();
      expect(h.provider.isRecoveryRetryBusy, isFalse);
      expect(h.storage.removeCalls, 1);
      await h.provider.resetQuarantinedDeviceSignIn();
      expect(h.storage.removeCalls, 1);
      expect(h.provider.isLoggedIn, isFalse);
      release.complete();
      await _until(
        () =>
            h.gateway.recoveryStatus ==
            AuthRecoveryStatus.localResetRestartRequired,
      );
      expect(h.entry, isNotNull);
      expect(h.storage.snapshot, isNull);
    },
  );

  for (final matrix in ['A/absent', 'A/B', 'B/A']) {
    test('shared C2 cleanup exact-A preflight matrix $matrix', () async {
      final h = await create(hangingToken: true);
      String? protectedBytes;
      h.checkpoint = (point) async {
        if (point != CredentialExchangeCheckpoint.remoteSuccessBeforeCleanup)
          return;
        await Future<void>.delayed(Duration.zero);
        if (matrix == 'A/absent') {
          h.storage.snapshot = null;
        } else if (matrix == 'A/B') {
          h.storage.snapshot = _sessionJson(
            sessionId: 'sess-b',
            userId: 'user-b',
          );
          protectedBytes = h.storage.snapshot;
        } else {
          await h.installB();
          h.storage.snapshot = _sessionJson(
            sessionId: 'sess-a',
            userId: 'user-a',
          );
          protectedBytes = h.storage.snapshot;
        }
      };
      await h.provider.signInWithGoogle();
      h.server.resolveHeldToken();
      if (matrix == 'A/absent') {
        await _until(() => h.gateway.recoveryStatus == AuthRecoveryStatus.none);
        expect(h.localCalls, 1);
        expect(h.storage.removeCalls, 0);
        expect(h.client.auth.currentSession, isNull);
      } else {
        await _until(
          () =>
              h.gateway.recoveryStatus ==
              AuthRecoveryStatus.exchangeBlockedCleanupFailure,
        );
        expect(h.localCalls, 0);
        expect(h.storage.removeCalls, 0);
        expect(h.storage.snapshot, protectedBytes);
        expect(
          h.server.logoutCalls,
          1,
          reason: 'only pre-collision A remote revoke',
        );
      }
      expect(h.provider.isLoggedIn, isFalse);
      expect(h.bootstrapCalls, 0);
    });
  }

  test(
    'exact A with malformed persisted bytes blocks without deletion or revoke',
    () async {
      final h = await create(
        phase: AuthRecoveryPhase.neutralizing,
        exact: true,
        snapshot: '{malformed}',
      );
      await h.provider.retryAuthCleanup();
      expect(h.storage.snapshot, '{malformed}');
      expect(h.localCalls, 0);
      expect(h.server.logoutCalls, 0);
      expect(h.storage.removeCalls, 0);
      expect(h.provider.isLoggedIn, isFalse);
    },
  );
}
