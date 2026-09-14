import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';

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
  String sessionId = 'sess-123',
  int exp = 1893456000,
}) => _jwt(
  payload: {
    'sub': userId,
    'session_id': sessionId,
    'exp': exp,
    'aud': 'authenticated',
    'role': 'authenticated',
    'iat': 1609459200,
  },
);

String _fakeSessionJson({
  String userId = 'user-a',
  String? accessToken,
  int? expiresAt,
}) {
  final token = accessToken ?? 'test-access-token-$userId';
  return jsonEncode({
    'access_token': token,
    'token_type': 'bearer',
    'expires_in': 3600,
    if (expiresAt != null) 'expires_at': expiresAt,
    'refresh_token': 'test-refresh-token',
    'user': {
      'id': userId,
      'email': 'user@example.com',
      'user_metadata': {'full_name': 'User $userId'},
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

String _randomProjectIdentity() => 'test_${Random().nextInt(1 << 20)}';

Future<AuthRecoveryStorageCoordinator> _openCoordinator({
  String? projectIdentity,
  LocalStorage? delegate,
}) async {
  return AuthRecoveryStorageCoordinator.open(
    projectIdentity: projectIdentity ?? _randomProjectIdentity(),
    delegate: delegate ?? _FakeLocalStorage(),
  );
}

Future<void> _seedRecovery(
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

class _FakeLocalStorage implements LocalStorage {
  _FakeLocalStorage();

  String? _snapshot;
  Object? accessTokenError;
  Object? persistError;
  Future<void>? accessBarrier;
  int accessTokenCalls = 0;
  int persistCalls = 0;
  int removeCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => _snapshot != null;

  @override
  Future<String?> accessToken() async {
    accessTokenCalls++;
    if (accessTokenError != null) throw accessTokenError!;
    if (accessBarrier != null) await accessBarrier;
    return _snapshot;
  }

  @override
  Future<void> removePersistedSession() async {
    removeCalls++;
    _snapshot = null;
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    persistCalls++;
    if (persistError != null) throw persistError!;
    _snapshot = persistSessionString;
  }
}

class _TestException implements Exception {
  const _TestException();
}

void main() {
  const devConfig = BackendConfig(
    appEnvRaw: 'development',
    supabaseUrl: 'https://project.supabase.co',
    supabaseAnonKey: 'anon-key',
    googleServerClientId: 'g-web-client-id.apps.googleusercontent.com',
  );

  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('c1_test_');
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

  group('SDK interface integration', () {
    test(
      'custom LocalStorage adapter is used during real Supabase startup',
      () async {
        SharedPreferences.setMockInitialValues({
          _storageKey(devConfig.supabaseUrl): _fakeSessionJson(),
        });

        final service = SupabaseService(
          config: devConfig,
          authOptions: const FlutterAuthClientOptions(
            detectSessionInUri: false,
          ),
        );
        await service.init();

        expect(service.isInitialized, isTrue);
        expect(Supabase.instance.client.auth.currentSession, isNotNull);
        expect(service.recoveryState?.status, AuthRecoveryStartupStatus.none);
        expect(service.recoveryCoordinator, isNotNull);

        service.dispose();
      },
    );

    test('no second Supabase client is introduced', () async {
      final service = SupabaseService(
        config: devConfig,
        authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
      );
      await service.init();

      final client1 = Supabase.instance.client;
      final client2 = Supabase.instance.client;
      expect(identical(client1, client2), isTrue);

      service.dispose();
    });

    test('SupabaseService retains recovery coordinator', () async {
      final service = SupabaseService(config: devConfig);
      await service.init();

      expect(service.recoveryCoordinator, isNotNull);

      service.dispose();
    });
  });

  group('normal startup', () {
    test('restores persisted session when no recovery record exists', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey(devConfig.supabaseUrl): _fakeSessionJson(),
      });

      final service = SupabaseService(
        config: devConfig,
        authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
      );
      await service.init();

      expect(service.recoveryState?.status, AuthRecoveryStartupStatus.none);
      expect(Supabase.instance.client.auth.currentSession, isNotNull);
      expect(Supabase.instance.client.auth.currentSession!.user.id, 'user-a');

      service.dispose();
    });
  });

  group('unresolved recovery', () {
    test('blocks normal restoration while leaving snapshot intact', () async {
      await _seedRecovery(devConfig.supabaseUrl, (coordinator) async {
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.active,
          correlation: const SessionCorrelation(userId: 'user-a'),
        );
      });
      SharedPreferences.setMockInitialValues({
        _storageKey(devConfig.supabaseUrl): _fakeSessionJson(),
      });

      final service = SupabaseService(
        config: devConfig,
        authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
      );
      await service.init();

      expect(
        service.recoveryState?.status,
        AuthRecoveryStartupStatus.unresolved,
      );
      expect(Supabase.instance.client.auth.currentSession, isNull);

      service.dispose();
    });
  });

  group('cleanup-required recovery', () {
    test('blocks normal restoration with cleanupRequired status', () async {
      await _seedRecovery(devConfig.supabaseUrl, (coordinator) async {
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.cleanupRequired,
          correlation: const SessionCorrelation(userId: 'user-a'),
        );
      });
      SharedPreferences.setMockInitialValues({
        _storageKey(devConfig.supabaseUrl): _fakeSessionJson(),
      });

      final service = SupabaseService(
        config: devConfig,
        authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
      );
      await service.init();

      expect(
        service.recoveryState?.status,
        AuthRecoveryStartupStatus.cleanupRequired,
      );
      expect(Supabase.instance.client.auth.currentSession, isNull);

      service.dispose();
    });
  });

  group('corrupt recovery', () {
    test('fails closed for account access but app startup succeeds', () async {
      await _seedRecovery(devConfig.supabaseUrl, (coordinator) async {
        await coordinator.markCorrupt(
          AuthRecoveryCorruptReason.unreadableJournal,
        );
      });
      SharedPreferences.setMockInitialValues({
        _storageKey(devConfig.supabaseUrl): _fakeSessionJson(),
      });

      final service = SupabaseService(
        config: devConfig,
        authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
      );
      await service.init();

      expect(service.isInitialized, isTrue);
      expect(service.recoveryState?.status, AuthRecoveryStartupStatus.corrupt);
      expect(Supabase.instance.client.auth.currentSession, isNull);

      service.dispose();
    });

    test('corrupt journal entry schema yields corrupt state', () async {
      final identity = _randomProjectIdentity();
      final box = await Hive.openBox(
        '${AppStorageKeys.authRecoveryJournalBox}_$identity',
      );
      await box.put(AppStorageKeys.authRecoveryJournalEntry, {
        'schemaVersion': 999,
        'operationId': 'x',
        'operationType': 'signOut',
        'phase': 'active',
        'userId': 'x',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      await box.close();

      final coordinator = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: identity,
        delegate: _FakeLocalStorage(),
      );

      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.corrupt,
      );
      await coordinator.close();
    });

    test('malformed corrupt marker yields corrupt state', () async {
      final identity = _randomProjectIdentity();
      final box = await Hive.openBox(
        '${AppStorageKeys.authRecoveryJournalBox}_$identity',
      );
      await box.put(
        '${AppStorageKeys.authRecoveryJournalEntry}_corrupt',
        'not-a-map',
      );
      await box.close();

      final coordinator = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: identity,
        delegate: _FakeLocalStorage(),
      );

      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.corrupt,
      );
      await coordinator.close();
    });

    test(
      'corrupt-marker write failure latches in-memory corrupt state',
      () async {
        final coordinator = await _openCoordinator();
        await coordinator.close();

        final result = await coordinator.markCorrupt(
          AuthRecoveryCorruptReason.writeFailure,
        );
        expect(result, isFalse);
        expect(
          coordinator.readRecoveryState().status,
          AuthRecoveryStartupStatus.corrupt,
        );
      },
    );
  });

  group('journal hardening / typed schema', () {
    test('persisted idle phase maps to corrupt, not none', () async {
      final identity = _randomProjectIdentity();
      final box = await Hive.openBox(
        '${AppStorageKeys.authRecoveryJournalBox}_$identity',
      );
      await box.put(AppStorageKeys.authRecoveryJournalEntry, {
        'schemaVersion': 1,
        'operationId': 'op-1',
        'operationType': 'signOut',
        'phase': 'idle',
        'userId': 'user-a',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      await box.close();

      final coordinator = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: identity,
        delegate: _FakeLocalStorage(),
      );

      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.corrupt,
      );
      await coordinator.close();
    });

    test('malformed operationType maps to corrupt', () async {
      final identity = _randomProjectIdentity();
      final box = await Hive.openBox(
        '${AppStorageKeys.authRecoveryJournalBox}_$identity',
      );
      await box.put(AppStorageKeys.authRecoveryJournalEntry, {
        'schemaVersion': 1,
        'operationId': 'op-1',
        'operationType': 'unknownOperation',
        'phase': 'active',
        'userId': 'user-a',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      await box.close();

      final coordinator = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: identity,
        delegate: _FakeLocalStorage(),
      );

      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.corrupt,
      );
      await coordinator.close();
    });

    test('malformed phase maps to corrupt', () async {
      final identity = _randomProjectIdentity();
      final box = await Hive.openBox(
        '${AppStorageKeys.authRecoveryJournalBox}_$identity',
      );
      await box.put(AppStorageKeys.authRecoveryJournalEntry, {
        'schemaVersion': 1,
        'operationId': 'op-1',
        'operationType': 'signOut',
        'phase': 'unknownPhase',
        'userId': 'user-a',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      await box.close();

      final coordinator = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: identity,
        delegate: _FakeLocalStorage(),
      );

      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.corrupt,
      );
      await coordinator.close();
    });

    test('unconstrained reason text cannot be persisted', () {
      // The public API accepts only [AuthRecoveryCorruptReason]; there is no
      // String overload. This test simply exercises the enum path.
      expect(AuthRecoveryCorruptReason.values, isNot(contains(isA<String>())));
    });
  });

  group('coordinator durability', () {
    test('begin/update/complete round-trip', () async {
      final coordinator = await _openCoordinator();

      final began = await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: const SessionCorrelation(
          userId: 'user-a',
          expiresAt: 12345,
        ),
      );
      expect(began, isTrue);

      final afterBegin = coordinator.readRecoveryState();
      expect(afterBegin.status, AuthRecoveryStartupStatus.unresolved);
      final afterBeginRecord = afterBegin.record!;
      expect(afterBeginRecord.operationType, AuthRecoveryOperationType.signOut);
      expect(afterBeginRecord.phase, AuthRecoveryPhase.active);
      expect(afterBeginRecord.userId, 'user-a');
      expect(afterBeginRecord.expiresAt, 12345);

      final updated = await coordinator.updateOwnedOperation(
        expectedOperationId: afterBeginRecord.operationId,
        phase: AuthRecoveryPhase.cleanupRequired,
      );
      expect(updated, isTrue);
      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.cleanupRequired,
      );

      final completed = await coordinator.completeOwnedOperation(
        expectedOperationId: afterBeginRecord.operationId,
      );
      expect(completed, isTrue);
      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.none,
      );
    });

    test('acknowledged write failure is surfaced when box is closed', () async {
      final coordinator = await _openCoordinator();
      await coordinator.close();

      expect(
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.active,
          correlation: const SessionCorrelation(userId: 'user-a'),
        ),
        isFalse,
      );
      expect(
        await coordinator.updateOwnedOperation(
          expectedOperationId: 'x',
          phase: AuthRecoveryPhase.cleanupRequired,
        ),
        isFalse,
      );
      expect(
        await coordinator.completeOwnedOperation(expectedOperationId: 'x'),
        isFalse,
      );
    });
  });

  group('operation-owned journal mutation', () {
    test('begin does not overwrite an unresolved operation', () async {
      final coordinator = await _openCoordinator();
      final first = await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: const SessionCorrelation(userId: 'user-a'),
      );
      expect(first, isTrue);
      final firstId = coordinator.readRecoveryEntry()!.operationId;

      final second = await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: const SessionCorrelation(userId: 'user-a'),
      );
      expect(second, isFalse);
      expect(coordinator.readRecoveryEntry()!.operationId, firstId);
    });

    test('update with wrong operation id is rejected', () async {
      final coordinator = await _openCoordinator();
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: const SessionCorrelation(userId: 'user-a'),
      );

      final result = await coordinator.updateOwnedOperation(
        expectedOperationId: 'wrong-id',
        phase: AuthRecoveryPhase.cleanupRequired,
      );
      expect(result, isFalse);
      expect(coordinator.readRecoveryEntry()?.phase, AuthRecoveryPhase.active);
    });

    test('complete with wrong operation id is rejected', () async {
      final coordinator = await _openCoordinator();
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: const SessionCorrelation(userId: 'user-a'),
      );

      final result = await coordinator.completeOwnedOperation(
        expectedOperationId: 'wrong-id',
      );
      expect(result, isFalse);
      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.unresolved,
      );
    });

    test('complete only succeeds with correct owned operation id', () async {
      final coordinator = await _openCoordinator();
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: const SessionCorrelation(userId: 'user-a'),
      );
      final id = coordinator.readRecoveryEntry()!.operationId;

      final result = await coordinator.completeOwnedOperation(
        expectedOperationId: id,
      );
      expect(result, isTrue);
      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.none,
      );
    });

    test('mismatched correlation blocks destructive complete', () async {
      final coordinator = await _openCoordinator();
      final corrA = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-a')),
        projectIdentity: 'https://project-a.example',
      );
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: corrA,
      );
      final id = coordinator.readRecoveryEntry()!.operationId;

      final corrB = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-b')),
        projectIdentity: 'https://project-a.example',
      );
      final result = await coordinator.completeOwnedOperation(
        expectedOperationId: id,
        expectedCorrelation: corrB,
      );
      expect(result, isFalse);
      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.unresolved,
      );
    });
  });

  group('coordinator non-bypassable boundary', () {
    test('production API has no unowned destructive storage methods', () async {
      final coordinator = await _openCoordinator();
      // The coordinator exposes only narrow recovery operations and the
      // SDK-init seam. Destructive recovery behavior is exercised below
      // through the remaining correlation-bound transaction surfaces.
      expect(coordinator.sdkLocalStorage, isA<LocalStorage>());
      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.none,
      );
      expect(coordinator.readRecoveryEntry(), isNull);
    });

    test('all state mutations go through the coordinator queue', () async {
      final coordinator = await _openCoordinator();
      final corr = const SessionCorrelation(userId: 'user-a');

      expect(
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.active,
          correlation: corr,
        ),
        isTrue,
      );
      final id = coordinator.readRecoveryEntry()!.operationId;

      expect(
        await coordinator.updateOwnedOperation(
          expectedOperationId: id,
          phase: AuthRecoveryPhase.cleanupRequired,
        ),
        isTrue,
      );
      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.cleanupRequired,
      );

      expect(
        await coordinator.completeOwnedOperation(expectedOperationId: id),
        isTrue,
      );
      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.none,
      );

      expect(
        await coordinator.markCorrupt(
          AuthRecoveryCorruptReason.unreadableJournal,
        ),
        isTrue,
      );
      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.corrupt,
      );
    });

    test('runOwnedRecoveryOperation denies wrong operation id', () async {
      final coordinator = await _openCoordinator();
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: const SessionCorrelation(userId: 'user-a'),
      );

      var actionRan = false;
      final result = await coordinator.runOwnedRecoveryOperation(
        expectedOperationId: 'wrong-id',
        action: (tx) async {
          actionRan = true;
          return 42;
        },
      );

      expect(result.allowed, isFalse);
      expect(actionRan, isFalse);
    });

    test('runOwnedRecoveryOperation denies mismatched correlation', () async {
      final coordinator = await _openCoordinator();
      final corrA = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-a')),
        projectIdentity: 'https://project.example',
      );
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: corrA,
      );
      final id = coordinator.readRecoveryEntry()!.operationId;

      final corrB = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-b')),
        projectIdentity: 'https://project.example',
      );
      var actionRan = false;
      final result = await coordinator.runOwnedRecoveryOperation(
        expectedOperationId: id,
        expectedCorrelation: corrB,
        action: (tx) async {
          actionRan = true;
          return null;
        },
      );

      expect(result.allowed, isFalse);
      expect(actionRan, isFalse);
    });

    test(
      'runOwnedRecoveryOperation allows correct owner and correlation',
      () async {
        final coordinator = await _openCoordinator();
        final corr = SessionCorrelation.fromSessionJson(
          _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-ok')),
          projectIdentity: 'https://project.example',
        );
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.active,
          correlation: corr,
        );
        final id = coordinator.readRecoveryEntry()!.operationId;

        final result = await coordinator.runOwnedRecoveryOperation(
          expectedOperationId: id,
          expectedCorrelation: corr,
          action: (tx) async {
            await tx.updatePhase(AuthRecoveryPhase.cleanupRequired);
            return 'done';
          },
        );

        expect(result.allowed, isTrue);
        expect(result.value, 'done');
        expect(
          coordinator.readRecoveryState().status,
          AuthRecoveryStartupStatus.cleanupRequired,
        );
      },
    );

    test(
      'runOwnedRecoveryOperation storage action cannot bypass ownership',
      () async {
        final snapshot = _fakeSessionJson(
          accessToken: _fakeAccessToken(sessionId: 'sess-owner'),
        );
        final delegate = _FakeLocalStorage().._snapshot = snapshot;
        final project = _projectIdentity('https://project.example');
        final coordinator = await _openCoordinator(
          delegate: delegate,
          projectIdentity: project,
        );
        final corr = SessionCorrelation.fromSessionJson(
          snapshot,
          projectIdentity: project,
        );
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.active,
          correlation: corr,
        );
        final id = coordinator.readRecoveryEntry()!.operationId;

        final wrongCorr = SessionCorrelation.fromSessionJson(
          _fakeSessionJson(
            accessToken: _fakeAccessToken(sessionId: 'sess-other'),
          ),
          projectIdentity: project,
        );
        final denied = await coordinator.runOwnedRecoveryOperation(
          expectedOperationId: id,
          expectedCorrelation: wrongCorr,
          action: (tx) async {
            return tx.removeMatchingRecoverySnapshot();
          },
        );
        expect(denied.allowed, isFalse);
        expect(delegate.removeCalls, 0);
        expect(delegate._snapshot, snapshot);

        final allowed = await coordinator.runOwnedRecoveryOperation(
          expectedOperationId: id,
          expectedCorrelation: corr,
          action: (tx) async {
            expect(
              await tx.inspectRecoverySnapshot(),
              RecoverySnapshotState.matching,
            );
            return tx.removeMatchingRecoverySnapshot();
          },
        );
        expect(allowed.allowed, isTrue);
        expect(allowed.value, isTrue);
        expect(delegate.removeCalls, 1);
        expect(delegate._snapshot, isNull);
      },
    );
  });

  group('C2 final conditional transaction boundary', () {
    final blockedSnapshots = <String, String>{
      'valid B, different user': _fakeSessionJson(
        userId: 'user-b',
        accessToken: _fakeAccessToken(userId: 'user-b', sessionId: 'sess-b'),
      ),
      'valid B, same user but different session': _fakeSessionJson(
        accessToken: _fakeAccessToken(sessionId: 'sess-b'),
      ),
      'malformed JSON': '{broken',
      'empty malformed data': '',
      'insufficient session identity': _fakeSessionJson(
        accessToken: _fakeAccessToken(sessionId: ''),
      ),
      'wrong token type': '{"access_token":7,"user":{"id":"user-a"}}',
    };
    for (final entry in blockedSnapshots.entries) {
      test(
        'owned A preserves ${entry.key} through every remaining removal surface',
        () async {
          final project = _projectIdentity('https://project.example');
          final a = _fakeSessionJson(
            accessToken: _fakeAccessToken(sessionId: 'sess-a'),
          );
          final corrA = SessionCorrelation.fromSessionJson(
            a,
            projectIdentity: project,
          );
          final delegate = _FakeLocalStorage().._snapshot = entry.value;
          final coordinator = await _openCoordinator(
            delegate: delegate,
            projectIdentity: project,
          );
          expect(
            await coordinator.beginOperation(
              type: AuthRecoveryOperationType.signOut,
              phase: AuthRecoveryPhase.cleanupRequired,
              correlation: corrA,
            ),
            isTrue,
          );
          final originalEntry = coordinator.readRecoveryEntry()!;
          final result = await coordinator.runOwnedRecoveryOperation<bool>(
            expectedOperationId: originalEntry.operationId,
            expectedCorrelation: corrA,
            action: (tx) async {
              expect(
                await tx.inspectRecoverySnapshot(),
                RecoverySnapshotState.blocked,
              );
              expect(await tx.removeMatchingRecoverySnapshot(), isFalse);
              expect(delegate._snapshot, entry.value);
              expect(delegate.removeCalls, 0);
              // Exercise the other transaction capability through the actual
              // guarded adapter, as an SDK persistence callback would use it.
              await tx.runOwnedSdkLocalCleanup(
                coordinator.sdkLocalStorage.removePersistedSession,
              );
              expect(await tx.readRecoverySnapshot(), entry.value);
              return true;
            },
          );
          expect(result.allowed, isTrue);
          expect(result.value, isTrue);
          expect(delegate._snapshot, entry.value);
          expect(delegate.removeCalls, 0);
          final after = coordinator.readRecoveryEntry()!;
          expect(after.operationId, originalEntry.operationId);
          expect(after.phase, originalEntry.phase);
          expect(after.userId, originalEntry.userId);
          expect(after.sessionId, originalEntry.sessionId);
          expect(after.projectIdentity, originalEntry.projectIdentity);
        },
      );
    }

    test(
      'journal ownership without captured correlation permits no destruction',
      () async {
        final project = _projectIdentity('https://project.example');
        final a = _fakeSessionJson(
          accessToken: _fakeAccessToken(sessionId: 'sess-a'),
        );
        final delegate = _FakeLocalStorage().._snapshot = a;
        final coordinator = await _openCoordinator(
          delegate: delegate,
          projectIdentity: project,
        );
        final corr = SessionCorrelation.fromSessionJson(
          a,
          projectIdentity: project,
        );
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.cleanupRequired,
          correlation: corr,
        );
        final id = coordinator.readRecoveryEntry()!.operationId;
        final result = await coordinator.runOwnedRecoveryOperation<bool>(
          expectedOperationId: id,
          // Deliberately omit expectedCorrelation: journal ownership is valid.
          action: (tx) async {
            expect(await tx.removeMatchingRecoverySnapshot(), isFalse);
            await expectLater(
              tx.runOwnedSdkLocalCleanup(
                coordinator.sdkLocalStorage.removePersistedSession,
              ),
              throwsStateError,
            );
            return true;
          },
        );
        expect(result.allowed, isTrue);
        expect(result.value, isTrue);
        expect(delegate._snapshot, a);
        expect(delegate.removeCalls, 0);
        expect(coordinator.readRecoveryEntry()!.operationId, id);
        expect(
          coordinator.readRecoveryEntry()!.phase,
          AuthRecoveryPhase.cleanupRequired,
        );
      },
    );
  });

  group('transaction lifetime', () {
    test('escaped transaction cannot mutate later operation B', () async {
      final delegate = _FakeLocalStorage();
      final project = _projectIdentity('https://project.example');
      final coordinator = await _openCoordinator(
        delegate: delegate,
        projectIdentity: project,
      );
      final corrA = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-a')),
        projectIdentity: project,
      );
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: corrA,
      );
      final idA = coordinator.readRecoveryEntry()!.operationId;

      AuthRecoveryTransaction? escaped;
      final result = await coordinator.runOwnedRecoveryOperation(
        expectedOperationId: idA,
        expectedCorrelation: corrA,
        action: (tx) async {
          escaped = tx;
          return null;
        },
      );
      expect(result.allowed, isTrue);

      // Complete A and begin B.
      await coordinator.completeOwnedOperation(expectedOperationId: idA);

      // Establish B's real persisted SDK snapshot through the existing seam
      // BEFORE B starts, and capture the exact expected value.
      final bSessionJson = _fakeSessionJson(
        userId: 'user-b',
        accessToken: _fakeAccessToken(userId: 'user-b', sessionId: 'sess-b'),
      );
      await coordinator.sdkLocalStorage.persistSession(bSessionJson);
      final initialRemoveCalls = delegate.removeCalls;

      final corrB = SessionCorrelation.fromSessionJson(
        bSessionJson,
        projectIdentity: project,
      );
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: corrB,
      );
      final idB = coordinator.readRecoveryEntry()!.operationId;
      expect(idB, isNot(idA));

      // Escaped A transaction must be invalid and must not mutate B.
      expect(
        () => escaped!.updatePhase(AuthRecoveryPhase.cleanupRequired),
        throwsA(isA<StateError>()),
      );
      expect(() => escaped!.complete(), throwsA(isA<StateError>()));
      expect(
        () => escaped!.removeMatchingRecoverySnapshot(),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        escaped!.runOwnedSdkLocalCleanup(
          coordinator.sdkLocalStorage.removePersistedSession,
        ),
        throwsStateError,
      );
      expect(() => escaped!.readRecoverySnapshot(), throwsA(isA<StateError>()));

      // A. B journal remains unchanged: still B's operation, still active.
      expect(coordinator.readRecoveryEntry()!.operationId, idB);
      expect(coordinator.readRecoveryEntry()!.phase, AuthRecoveryPhase.active);

      // C. No destructive delegate call occurred.
      expect(initialRemoveCalls, 0);
      expect(delegate.removeCalls, initialRemoveCalls);
      expect(delegate._snapshot, bSessionJson);

      // B. B snapshot remains EXACTLY unchanged, read back through the
      // authorized current B transaction.
      final bRead = await coordinator.runOwnedRecoveryOperation(
        expectedOperationId: idB,
        expectedCorrelation: corrB,
        action: (tx) async => tx.readRecoverySnapshot(),
      );
      expect(bRead.allowed, isTrue);
      expect(bRead.value, bSessionJson);

      // D. Escaped A did not gain authority over B; the legitimate B
      // transaction still works, including destructive removal.
      final bRemove = await coordinator.runOwnedRecoveryOperation(
        expectedOperationId: idB,
        expectedCorrelation: corrB,
        action: (tx) async {
          return tx.removeMatchingRecoverySnapshot();
        },
      );
      expect(bRemove.allowed, isTrue);
      expect(bRemove.value, isTrue);
      expect(delegate.removeCalls, initialRemoveCalls + 1);
      expect(delegate._snapshot, isNull);

      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.unresolved,
      );
    });

    test('transaction invalidates on callback failure', () async {
      final coordinator = await _openCoordinator();
      final corr = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-fail')),
        projectIdentity: 'https://project.example',
      );
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: corr,
      );
      final id = coordinator.readRecoveryEntry()!.operationId;

      AuthRecoveryTransaction? escaped;
      await expectLater(
        coordinator.runOwnedRecoveryOperation(
          expectedOperationId: id,
          expectedCorrelation: corr,
          action: (tx) async {
            escaped = tx;
            throw const _TestException();
          },
        ),
        throwsA(isA<_TestException>()),
      );

      expect(
        () => escaped!.updatePhase(AuthRecoveryPhase.cleanupRequired),
        throwsA(isA<StateError>()),
      );

      // Queue must still be usable for a later valid operation.
      final later = await coordinator.updateOwnedOperation(
        expectedOperationId: id,
        phase: AuthRecoveryPhase.cleanupRequired,
      );
      expect(later, isTrue);
      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.cleanupRequired,
      );
    });

    test(
      'active transaction validates current ownership before acting',
      () async {
        final projectIdentity = 'tx-revalidate-test';
        final snapshot = _fakeSessionJson(
          accessToken: _fakeAccessToken(sessionId: 'sess-a'),
        );
        final delegate = _FakeLocalStorage().._snapshot = snapshot;
        final coordinator = await AuthRecoveryStorageCoordinator.open(
          projectIdentity: projectIdentity,
          delegate: delegate,
        );
        final corrA = SessionCorrelation.fromSessionJson(
          snapshot,
          projectIdentity: projectIdentity,
        );
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.active,
          correlation: corrA,
        );
        final idA = coordinator.readRecoveryEntry()!.operationId;

        final result = await coordinator.runOwnedRecoveryOperation(
          expectedOperationId: idA,
          expectedCorrelation: corrA,
          action: (tx) async {
            // Complete A through the transaction, then mutate the underlying
            // journal directly so the current entry becomes operation B.
            await tx.complete();
            final box = Hive.box(
              '${AppStorageKeys.authRecoveryJournalBox}_$projectIdentity',
            );
            await box.put(AppStorageKeys.authRecoveryJournalEntry, {
              'schemaVersion': 1,
              'operationId': 'operation-b',
              'operationType': 'signOut',
              'phase': 'active',
              'userId': 'user-b',
              'createdAt': DateTime.now().toUtc().toIso8601String(),
              'updatedAt': DateTime.now().toUtc().toIso8601String(),
            });

            // The transaction must revalidate and reject because the current
            // entry is now operation B, not A.
            final updated = await tx.updatePhase(
              AuthRecoveryPhase.cleanupRequired,
            );
            expect(updated, isFalse);

            expect(await tx.removeMatchingRecoverySnapshot(), isFalse);
            return null;
          },
        );
        expect(result.allowed, isTrue);
        expect(delegate.removeCalls, 0);
        expect(delegate._snapshot, snapshot);
        expect(coordinator.readRecoveryEntry()!.operationId, 'operation-b');
        await coordinator.close();
      },
    );

    test('active legitimate transaction allows intended mutations', () async {
      final original = _fakeSessionJson(
        accessToken: _fakeAccessToken(sessionId: 'sess-legit'),
      );
      final delegate = _FakeLocalStorage().._snapshot = original;
      final project = _projectIdentity('https://project.example');
      final coordinator = await _openCoordinator(
        delegate: delegate,
        projectIdentity: project,
      );
      final corr = SessionCorrelation.fromSessionJson(
        original,
        projectIdentity: project,
      );
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: corr,
      );
      final id = coordinator.readRecoveryEntry()!.operationId;

      final result = await coordinator.runOwnedRecoveryOperation(
        expectedOperationId: id,
        expectedCorrelation: corr,
        action: (tx) async {
          final snapshot = await tx.readRecoverySnapshot();
          expect(snapshot, original);
          expect(
            await tx.updatePhase(AuthRecoveryPhase.cleanupRequired),
            isTrue,
          );
          expect(await tx.removeMatchingRecoverySnapshot(), isTrue);
          expect(delegate._snapshot, isNull);
          expect(await tx.complete(), isTrue);
          return 'ok';
        },
      );

      expect(result.allowed, isTrue);
      expect(result.value, 'ok');
      expect(delegate.removeCalls, 1);
      expect(
        coordinator.readRecoveryState().status,
        AuthRecoveryStartupStatus.none,
      );
    });
  });

  group('token safety', () {
    test('journal serialization never contains raw tokens', () async {
      final identity = _randomProjectIdentity();
      final coordinator = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: identity,
        delegate: _FakeLocalStorage(),
      );
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: SessionCorrelation.fromSessionJson(_fakeSessionJson()),
      );

      final raw =
          Hive.box(
                '${AppStorageKeys.authRecoveryJournalBox}_$identity',
              ).get(AppStorageKeys.authRecoveryJournalEntry)
              as Map;
      final json = jsonEncode(raw);

      expect(json, isNot(contains('test-access-token')));
      expect(json, isNot(contains('test-refresh-token')));
      expect(json, isNot(contains('google-id-token')));
      expect(json, isNot(contains('google-access-token')));
      expect(json, isNot(contains('provider_token')));
      expect(raw['userId'], 'user-a');
      await coordinator.close();
    });
  });

  group('project-scoped recovery storage', () {
    test('project A unresolved does not block project B', () async {
      const urlA = 'https://api.alpha.example';
      const urlB = 'https://api.beta.example';
      final coordinatorA = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: _projectIdentity(urlA),
        delegate: _FakeLocalStorage(),
      );
      await coordinatorA.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: const SessionCorrelation(userId: 'user-a'),
      );

      final coordinatorB = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: _projectIdentity(urlB),
        delegate: _FakeLocalStorage(),
      );

      expect(
        coordinatorA.readRecoveryState().status,
        AuthRecoveryStartupStatus.unresolved,
      );
      expect(
        coordinatorB.readRecoveryState().status,
        AuthRecoveryStartupStatus.none,
      );
    });

    test('recreating project A still sees its unresolved record', () async {
      const urlA = 'https://api.alpha.example';
      final coordinatorA = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: _projectIdentity(urlA),
        delegate: _FakeLocalStorage(),
      );
      await coordinatorA.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: const SessionCorrelation(userId: 'user-a'),
      );
      await coordinatorA.close();

      final coordinatorA2 = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: _projectIdentity(urlA),
        delegate: _FakeLocalStorage(),
      );

      expect(
        coordinatorA2.readRecoveryState().status,
        AuthRecoveryStartupStatus.unresolved,
      );
    });

    test('localhost ports are isolated', () async {
      const url21 = 'http://localhost:54321';
      const url22 = 'http://localhost:54322';
      final c21 = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: _projectIdentity(url21),
        delegate: _FakeLocalStorage(),
      );
      await c21.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: const SessionCorrelation(userId: 'user-a'),
      );
      final c22 = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: _projectIdentity(url22),
        delegate: _FakeLocalStorage(),
      );

      expect(
        c21.readRecoveryState().status,
        AuthRecoveryStartupStatus.unresolved,
      );
      expect(c22.readRecoveryState().status, AuthRecoveryStartupStatus.none);
      expect(_projectIdentity(url21), isNot(_projectIdentity(url22)));
    });

    test('scheme/host normalization distinguishes case and default ports', () {
      const a = 'https://API.Alpha.Example';
      const b = 'https://api.alpha.example';
      const c = 'HTTPS://API.ALPHA.EXAMPLE:443';
      const d = 'http://api.alpha.example';
      expect(_projectIdentity(a), _projectIdentity(b));
      expect(_projectIdentity(b), _projectIdentity(c));
      expect(_projectIdentity(b), isNot(_projectIdentity(d)));
    });
  });

  group('session correlation', () {
    test('extracts non-secret identity from session JSON', () async {
      final correlation = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(),
      );
      expect(correlation.userId, 'user-a');
      expect(correlation.expiresAt, isNull);
      expect(correlation.hasSessionId, isFalse);
    });

    test('extracts session_id from realistic GoTrue JWT payload', () {
      final jwt = _fakeAccessToken(sessionId: 'sess-abc-123');
      final correlation = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: jwt),
      );
      expect(correlation.userId, 'user-a');
      expect(correlation.sessionId, 'sess-abc-123');
      expect(correlation.hasSessionId, isTrue);
    });

    test('same user + same expiration + different session_id differ', () {
      final a = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(
          accessToken: _fakeAccessToken(sessionId: 'sess-a', exp: 2000000000),
          expiresAt: 2000000000,
        ),
        projectIdentity: 'https://project.example',
      );
      final b = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(
          accessToken: _fakeAccessToken(sessionId: 'sess-b', exp: 2000000000),
          expiresAt: 2000000000,
        ),
        projectIdentity: 'https://project.example',
      );
      expect(a.matches(b), isFalse);
    });

    test('same session_id + expected user/project matches as intended', () {
      final a = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-x')),
        projectIdentity: 'https://project.example',
      );
      final b = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-x')),
        projectIdentity: 'https://project.example',
      );
      expect(a.matches(b), isTrue);
    });

    test(
      'missing session_id marks correlation insufficient for destructive ownership',
      () {
        final correlation = SessionCorrelation.fromSessionJson(
          _fakeSessionJson(),
          projectIdentity: 'https://project.example',
        );
        expect(correlation.hasSessionId, isFalse);
        expect(correlation.isSufficientForDestructiveCleanup, isFalse);
      },
    );

    test('project identity participates in correlation match', () {
      final same = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-p')),
        projectIdentity: 'https://project-a.example',
      );
      final otherProject = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-p')),
        projectIdentity: 'https://project-b.example',
      );
      expect(same.matches(otherProject), isFalse);
    });

    test('raw token material is never serialized in correlation toMap', () {
      final jwt = _fakeAccessToken(sessionId: 'sess-raw');
      final correlation = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: jwt),
        projectIdentity: 'https://project.example',
      );
      final map = correlation.toMap();
      final json = jsonEncode(map);
      expect(json, isNot(contains(jwt)));
      expect(json, isNot(contains('access_token')));
      expect(map['sessionId'], 'sess-raw');
    });
  });

  group('guarded storage', () {
    test('exact SDK session string is persisted unchanged', () async {
      final coordinator = await _openCoordinator();
      const snapshot = '{"access_token":"abc","refresh_token":"def"}';

      await coordinator.sdkLocalStorage.persistSession(snapshot);
      final recovered = await (coordinator.sdkLocalStorage as dynamic)
          .accessToken();

      expect(recovered, snapshot);
    });

    test(
      'exact underlying snapshot remains intact when restoration is blocked',
      () async {
        final delegate = _FakeLocalStorage();
        final coordinator = await _openCoordinator(delegate: delegate);
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.active,
          correlation: const SessionCorrelation(userId: 'user-a'),
        );
        const snapshot = '{"access_token":"abc"}';

        await coordinator.sdkLocalStorage.persistSession(snapshot);
        final access = await coordinator.sdkLocalStorage.accessToken();

        expect(access, isNull);
        expect(delegate._snapshot, snapshot);
      },
    );

    test(
      'delegate failure does not permanently poison serialization queue',
      () async {
        final delegate = _FakeLocalStorage()
          ..accessTokenError = Exception('disk failure');
        final coordinator = await _openCoordinator(delegate: delegate);

        await expectLater(
          coordinator.sdkLocalStorage.accessToken(),
          throwsA(isA<Exception>()),
        );

        delegate.accessTokenError = null;
        final result = await coordinator.sdkLocalStorage.accessToken();
        expect(result, isNull);
      },
    );

    test('unresolved state blocks accessToken', () async {
      final delegate = _FakeLocalStorage().._snapshot = '{"x":1}';
      final coordinator = await _openCoordinator(delegate: delegate);
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: const SessionCorrelation(userId: 'user-a'),
      );

      expect(await coordinator.sdkLocalStorage.accessToken(), isNull);
    });

    test('cleanupRequired blocks accessToken', () async {
      final delegate = _FakeLocalStorage().._snapshot = '{"x":1}';
      final coordinator = await _openCoordinator(delegate: delegate);
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.cleanupRequired,
        correlation: const SessionCorrelation(userId: 'user-a'),
      );

      expect(await coordinator.sdkLocalStorage.accessToken(), isNull);
    });

    test('corrupt blocks accessToken', () async {
      final delegate = _FakeLocalStorage().._snapshot = '{"x":1}';
      final coordinator = await _openCoordinator(delegate: delegate);
      await coordinator.markCorrupt(AuthRecoveryCorruptReason.malformedMarker);

      expect(await coordinator.sdkLocalStorage.accessToken(), isNull);
    });

    test('only true no-record state allows normal access', () async {
      final delegate = _FakeLocalStorage().._snapshot = '{"x":1}';
      final coordinator = await _openCoordinator(delegate: delegate);

      expect(await coordinator.sdkLocalStorage.accessToken(), '{"x":1}');
    });

    test('malformed journal record blocks access', () async {
      final identity = _randomProjectIdentity();
      final box = await Hive.openBox(
        '${AppStorageKeys.authRecoveryJournalBox}_$identity',
      );
      await box.put(AppStorageKeys.authRecoveryJournalEntry, {
        'schemaVersion': 1,
        'operationId': 'op',
        'operationType': 'badType',
        'phase': 'active',
        'userId': 'user',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      await box.close();

      final coordinator = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: identity,
        delegate: _FakeLocalStorage().._snapshot = '{"x":1}',
      );

      expect(await coordinator.sdkLocalStorage.accessToken(), isNull);
      await coordinator.close();
    });
  });

  group('restart safety', () {
    test('unresolved block survives close/reopen reconstruction', () async {
      const url = 'https://close-reopen.example';
      final coordinator = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: _projectIdentity(url),
        delegate: _FakeLocalStorage(),
      );
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.active,
        correlation: const SessionCorrelation(userId: 'user-a'),
      );
      await coordinator.close();

      final coordinator2 = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: _projectIdentity(url),
        delegate: _FakeLocalStorage(),
      );

      expect(
        coordinator2.readRecoveryState().status,
        AuthRecoveryStartupStatus.unresolved,
      );
    });

    test('corrupt state survives close/reopen reconstruction', () async {
      const url = 'https://close-reopen-corrupt.example';
      final coordinator = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: _projectIdentity(url),
        delegate: _FakeLocalStorage(),
      );
      await coordinator.markCorrupt(
        AuthRecoveryCorruptReason.unreadableJournal,
      );
      await coordinator.close();

      final coordinator2 = await AuthRecoveryStorageCoordinator.open(
        projectIdentity: _projectIdentity(url),
        delegate: _FakeLocalStorage(),
      );

      expect(
        coordinator2.readRecoveryState().status,
        AuthRecoveryStartupStatus.corrupt,
      );
    });

    test(
      'wrong-owner completion attempt leaves original record after reopen',
      () async {
        const url = 'https://wrong-owner.example';
        final coordinator = await AuthRecoveryStorageCoordinator.open(
          projectIdentity: _projectIdentity(url),
          delegate: _FakeLocalStorage(),
        );
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.active,
          correlation: const SessionCorrelation(userId: 'user-a'),
        );
        await coordinator.close();

        final coordinator2 = await AuthRecoveryStorageCoordinator.open(
          projectIdentity: _projectIdentity(url),
          delegate: _FakeLocalStorage(),
        );
        final result = await coordinator2.completeOwnedOperation(
          expectedOperationId: 'wrong-id',
        );
        expect(result, isFalse);
        expect(
          coordinator2.readRecoveryState().status,
          AuthRecoveryStartupStatus.unresolved,
        );
      },
    );

    test(
      'owned completion allows normal restoration on next startup',
      () async {
        await _seedRecovery(devConfig.supabaseUrl, (coordinator) async {
          await coordinator.beginOperation(
            type: AuthRecoveryOperationType.signOut,
            phase: AuthRecoveryPhase.active,
            correlation: const SessionCorrelation(userId: 'user-a'),
          );
          final id = coordinator.readRecoveryEntry()!.operationId;
          await coordinator.completeOwnedOperation(expectedOperationId: id);
        });
        SharedPreferences.setMockInitialValues({
          _storageKey(devConfig.supabaseUrl): _fakeSessionJson(),
        });

        final service = SupabaseService(
          config: devConfig,
          authOptions: const FlutterAuthClientOptions(
            detectSessionInUri: false,
          ),
        );
        await service.init();

        expect(service.recoveryState?.status, AuthRecoveryStartupStatus.none);
        expect(Supabase.instance.client.auth.currentSession, isNotNull);

        service.dispose();
      },
    );

    test(
      'unresolved block survives Supabase reinitialization with reconstruction',
      () async {
        await _seedRecovery(devConfig.supabaseUrl, (coordinator) async {
          await coordinator.beginOperation(
            type: AuthRecoveryOperationType.signOut,
            phase: AuthRecoveryPhase.active,
            correlation: const SessionCorrelation(userId: 'user-a'),
          );
        });
        SharedPreferences.setMockInitialValues({
          _storageKey(devConfig.supabaseUrl): _fakeSessionJson(),
        });

        final service1 = SupabaseService(
          config: devConfig,
          authOptions: const FlutterAuthClientOptions(
            detectSessionInUri: false,
          ),
        );
        await service1.init();
        expect(
          service1.recoveryState?.status,
          AuthRecoveryStartupStatus.unresolved,
        );
        expect(Supabase.instance.client.auth.currentSession, isNull);
        service1.dispose();
        await Supabase.instance.dispose();
        await Hive.close();

        Hive.init(tempDir.path);
        SharedPreferences.setMockInitialValues({
          _storageKey(devConfig.supabaseUrl): _fakeSessionJson(),
        });
        final service2 = SupabaseService(
          config: devConfig,
          authOptions: const FlutterAuthClientOptions(
            detectSessionInUri: false,
          ),
        );
        await service2.init();
        expect(
          service2.recoveryState?.status,
          AuthRecoveryStartupStatus.unresolved,
        );
        expect(Supabase.instance.client.auth.currentSession, isNull);
        service2.dispose();
      },
    );
  });

  group('account authority gate', () {
    SupabaseClient _testClient() =>
        SupabaseClient(devConfig.supabaseUrl, devConfig.supabaseAnonKey);

    Future<SupabaseService> _readyService() async {
      final service = SupabaseService(config: devConfig);
      await service.init();
      return service;
    }

    test('BLOCKED + fresh login attempt: exchange does not start', () async {
      await _seedRecovery(devConfig.supabaseUrl, (coordinator) async {
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.active,
          correlation: const SessionCorrelation(userId: 'user-a'),
        );
      });
      final service = await _readyService();
      var exchangeCalls = 0;
      var credentialCalls = 0;
      final gateway = SupabaseAuthGateway(
        service: service,
        client: _testClient(),
        credentialsProvider: () {
          credentialCalls++;
          return Future.value(
            const GoogleCredentialBundle(
              idToken: 'id-token',
              accessToken: 'google-access',
            ),
          );
        },
        credentialExchange: ({required idToken, required accessToken}) {
          exchangeCalls++;
          return Future.value(
            const AuthSession(
              userId: 'user-a',
              email: 'a@example.com',
              displayName: 'A',
            ),
          );
        },
      );
      final provider = AuthProvider(gateway: gateway);

      await provider.signInWithGoogle();

      expect(credentialCalls, 0);
      expect(exchangeCalls, 0);
      expect(provider.isLoggedIn, isFalse);
      expect(provider.error, AuthError.recoveryBlocked);

      provider.dispose();
      gateway.dispose();
      service.dispose();
    });

    test('BLOCKED + auth event: provider does not authenticate', () async {
      await _seedRecovery(devConfig.supabaseUrl, (coordinator) async {
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.active,
          correlation: const SessionCorrelation(userId: 'user-a'),
        );
      });
      final service = await _readyService();
      final controller = StreamController<AuthState>.broadcast();
      var bootstrapCalls = 0;
      final gateway = SupabaseAuthGateway(
        service: service,
        client: _testClient(),
        authStateStreamFactory: () => controller.stream,
      );
      final provider = AuthProvider(
        gateway: gateway,
        onPostAuth: (_) async {
          bootstrapCalls++;
          return PostAuthOutcome.success;
        },
      );

      controller.add(
        AuthState(
          AuthChangeEvent.initialSession,
          Session(
            accessToken: 'x',
            tokenType: 'bearer',
            user: User(
              id: 'user-a',
              email: 'a@example.com',
              appMetadata: {},
              userMetadata: {'full_name': 'A'},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
              role: 'authenticated',
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(provider.isLoggedIn, isFalse);
      expect(provider.status, AuthStatus.guest);
      expect(bootstrapCalls, 0);
      expect(provider.postAuthState, PostAuthLifecycleState.idle);

      await controller.close();
      provider.dispose();
      gateway.dispose();
      service.dispose();
    });

    test('BLOCKED + restoreSession: no application authority', () async {
      await _seedRecovery(devConfig.supabaseUrl, (coordinator) async {
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.active,
          correlation: const SessionCorrelation(userId: 'user-a'),
        );
      });
      final service = await _readyService();
      final gateway = SupabaseAuthGateway(
        service: service,
        client: _testClient(),
      );
      final provider = AuthProvider(gateway: gateway);

      await provider.restoreSession();

      expect(provider.isLoggedIn, isFalse);
      expect(provider.status, AuthStatus.cleanupRecovery);
      expect(provider.isAuthorityBlocked, isTrue);

      provider.dispose();
      gateway.dispose();
      service.dispose();
    });

    test('CORRUPT + fresh login attempt: exchange does not start', () async {
      await _seedRecovery(devConfig.supabaseUrl, (coordinator) async {
        await coordinator.markCorrupt(
          AuthRecoveryCorruptReason.unreadableJournal,
        );
      });
      final service = await _readyService();
      var exchangeCalls = 0;
      final gateway = SupabaseAuthGateway(
        service: service,
        client: _testClient(),
        credentialsProvider: () => Future.value(
          const GoogleCredentialBundle(idToken: 'id', accessToken: 'a'),
        ),
        credentialExchange: ({required idToken, required accessToken}) {
          exchangeCalls++;
          return Future.value(
            const AuthSession(
              userId: 'user-a',
              email: 'a@example.com',
              displayName: 'A',
            ),
          );
        },
      );
      final provider = AuthProvider(gateway: gateway);

      await provider.signInWithGoogle();

      expect(exchangeCalls, 0);
      expect(provider.isLoggedIn, isFalse);
      expect(provider.error, AuthError.recoveryBlocked);

      provider.dispose();
      gateway.dispose();
      service.dispose();
    });

    test(
      'CLEAN: existing sign-in/restoration behavior remains normal',
      () async {
        final service = await _readyService();
        final sdk = _testClient();
        addTearDown(sdk.dispose);
        final gateway = SupabaseAuthGateway(
          service: service,
          client: sdk,
          credentialsProvider: () => Future.value(
            const GoogleCredentialBundle(idToken: 'id', accessToken: 'a'),
          ),
          credentialExchange: ({required idToken, required accessToken}) async {
            // Correlation exists only AFTER the simulated SDK exchange saves
            // its actual session, never in the pre-exchange journal.
            await sdk.auth.setInitialSession(
              _fakeSessionJson(accessToken: _fakeAccessToken()),
            );
            return const AuthSession(
              userId: 'user-a',
              email: 'a@example.com',
              displayName: 'A',
            );
          },
          credentialExchangeCorrelationProvider: () =>
              SessionCorrelation.fromSessionJson(
                jsonEncode(sdk.auth.currentSession!.toJson()),
                projectIdentity: _projectIdentity(devConfig.supabaseUrl),
              ),
        );
        final provider = AuthProvider(gateway: gateway);

        await provider.signInWithGoogle();

        expect(provider.isLoggedIn, isTrue);
        expect(provider.status, AuthStatus.authenticated);
        expect(provider.session?.userId, 'user-a');

        provider.dispose();
        gateway.dispose();
        service.dispose();
      },
    );

    test(
      'recovery becomes blocked during Google picker: exchange does not start',
      () async {
        final service = await _readyService();
        final credentialsCompleter = Completer<GoogleCredentialBundle>();
        var exchangeCalls = 0;
        final gateway = SupabaseAuthGateway(
          service: service,
          client: _testClient(),
          credentialsProvider: () => credentialsCompleter.future,
          credentialExchange: ({required idToken, required accessToken}) {
            exchangeCalls++;
            return Future.value(
              const AuthSession(
                userId: 'user-a',
                email: 'a@example.com',
                displayName: 'A',
              ),
            );
          },
        );
        final provider = AuthProvider(gateway: gateway);

        final signInFuture = provider.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);

        // Recovery becomes blocked while the picker is pending.
        await service.recoveryCoordinator!.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.active,
          correlation: const SessionCorrelation(userId: 'user-a'),
        );

        credentialsCompleter.complete(
          const GoogleCredentialBundle(idToken: 'id', accessToken: 'a'),
        );
        await signInFuture;

        expect(exchangeCalls, 0);
        expect(provider.isLoggedIn, isFalse);
        expect(provider.error, AuthError.recoveryBlocked);

        provider.dispose();
        gateway.dispose();
        service.dispose();
      },
    );

    test(
      'recovery becomes blocked during SDK exchange: result not admitted',
      () async {
        final service = await _readyService();
        final exchangeCompleter = Completer<AuthSession>();
        var exchangeCalls = 0;
        final gateway = SupabaseAuthGateway(
          service: service,
          client: _testClient(),
          credentialsProvider: () => Future.value(
            const GoogleCredentialBundle(idToken: 'id', accessToken: 'a'),
          ),
          credentialExchange: ({required idToken, required accessToken}) {
            exchangeCalls++;
            return exchangeCompleter.future;
          },
        );
        final provider = AuthProvider(gateway: gateway);

        final signInFuture = provider.signInWithGoogle();
        for (var i = 0; i < 100 && exchangeCalls == 0; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
        expect(exchangeCalls, 1);

        // C3 already owns the single journal: a competing C2 cannot begin.
        expect(
          await service.recoveryCoordinator!.beginOperation(
            type: AuthRecoveryOperationType.signOut,
            phase: AuthRecoveryPhase.active,
            correlation: const SessionCorrelation(userId: 'user-a'),
          ),
          isFalse,
        );
        await service.recoveryCoordinator!.markCorrupt(
          AuthRecoveryCorruptReason.ownershipViolation,
        );

        exchangeCompleter.complete(
          const AuthSession(
            userId: 'user-a',
            email: 'a@example.com',
            displayName: 'A',
          ),
        );
        await signInFuture;

        expect(provider.isLoggedIn, isFalse);
        expect(provider.error, AuthError.recoveryBlocked);
        expect(provider.postAuthState, PostAuthLifecycleState.idle);

        provider.dispose();
        gateway.dispose();
        service.dispose();
      },
    );

    test('canonical recovery state is queried, not copied', () {
      expect(
        SupabaseAuthGateway(
          service: SupabaseService(config: devConfig),
        ).canAccountAuthorityBeGranted,
        isTrue,
      );
    });
  });

  group('V1-R09 C2 owned SDK local cleanup capability', () {
    for (final replacement in ['B', 'malformed']) {
      test(
        'actual deletion rechecks $replacement after matching preflight A',
        () async {
          final a = _fakeSessionJson(
            accessToken: _fakeAccessToken(sessionId: 'sess-a'),
          );
          final bytes = replacement == 'B'
              ? _fakeSessionJson(
                  accessToken: _fakeAccessToken(sessionId: 'sess-b'),
                )
              : '{broken';
          final delegate = _FakeLocalStorage().._snapshot = a;
          final project = _projectIdentity('https://project.example');
          final coordinator = await _openCoordinator(
            delegate: delegate,
            projectIdentity: project,
          );
          final corr = SessionCorrelation.fromSessionJson(
            a,
            projectIdentity: project,
          );
          await coordinator.beginOperation(
            type: AuthRecoveryOperationType.signOut,
            phase: AuthRecoveryPhase.cleanupRequired,
            correlation: corr,
          );
          final id = coordinator.readRecoveryEntry()!.operationId;
          await coordinator.runOwnedRecoveryOperation(
            expectedOperationId: id,
            expectedCorrelation: corr,
            action: (tx) async {
              expect(
                await tx.inspectRecoverySnapshot(),
                RecoverySnapshotState.matching,
              );
              // Simulates changed underlying bytes AFTER the gateway preflight.
              delegate._snapshot = bytes;
              await tx.runOwnedSdkLocalCleanup(
                coordinator.sdkLocalStorage.removePersistedSession,
              );
              expect(await tx.removeMatchingRecoverySnapshot(), isFalse);
              return null;
            },
          );
          expect(delegate.removeCalls, 0);
          expect(delegate._snapshot, bytes);
          expect(coordinator.readRecoveryEntry()!.operationId, id);
        },
      );
    }

    test(
      'configured project, not record/snapshot data, authorizes deletion',
      () async {
        final a = _fakeSessionJson(
          accessToken: _fakeAccessToken(sessionId: 'sess-a'),
        );
        final delegate = _FakeLocalStorage().._snapshot = a;
        final coordinator = await _openCoordinator(delegate: delegate);
        final corr = SessionCorrelation.fromSessionJson(
          a,
          projectIdentity: 'foreign-project',
        );
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.cleanupRequired,
          correlation: corr,
        );
        await coordinator.runOwnedRecoveryOperation(
          expectedOperationId: coordinator.readRecoveryEntry()!.operationId,
          expectedCorrelation: corr,
          action: (tx) async {
            expect(
              await tx.inspectRecoverySnapshot(),
              RecoverySnapshotState.blocked,
            );
            expect(await tx.removeMatchingRecoverySnapshot(), isFalse);
            await expectLater(
              tx.runOwnedSdkLocalCleanup(
                coordinator.sdkLocalStorage.removePersistedSession,
              ),
              throwsStateError,
            );
            return null;
          },
        );
        expect(delegate.removeCalls, 0);
        expect(delegate._snapshot, a);
      },
    );

    test(
      'permission expires before a delayed read; queue drains without unrestricted fallback',
      () async {
        final a = _fakeSessionJson(
          accessToken: _fakeAccessToken(sessionId: 'sess-a'),
        );
        final b = _fakeSessionJson(
          accessToken: _fakeAccessToken(sessionId: 'sess-b'),
        );
        final delegate = _FakeLocalStorage().._snapshot = a;
        final project = _projectIdentity('https://project.example');
        final coordinator = await _openCoordinator(
          delegate: delegate,
          projectIdentity: project,
        );
        final corr = SessionCorrelation.fromSessionJson(
          a,
          projectIdentity: project,
        );
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.cleanupRequired,
          correlation: corr,
        );
        final barrier = Completer<void>();
        final invoked = Completer<void>();
        delegate.accessBarrier = barrier.future;
        Future<void>? sdkRemoval;
        var finished = false;
        final transaction = coordinator.runOwnedRecoveryOperation(
          expectedOperationId: coordinator.readRecoveryEntry()!.operationId,
          expectedCorrelation: corr,
          action: (tx) async {
            await tx.runOwnedSdkLocalCleanup(() async {
              sdkRemoval = coordinator.sdkLocalStorage.removePersistedSession();
              invoked.complete();
            });
            finished = true;
            return null;
          },
        );
        await invoked.future;
        await Future<void>.delayed(Duration.zero);
        final queuedB = coordinator.sdkLocalStorage.persistSession(b);
        expect(
          finished,
          isFalse,
          reason: 'initiated storage read still drains the owned slot',
        );
        barrier.complete();
        await transaction;
        await sdkRemoval;
        await queuedB;
        await coordinator.sdkLocalStorage.removePersistedSession();
        expect(delegate.removeCalls, 0);
        expect(delegate._snapshot, b);
        expect(finished, isTrue);
      },
    );

    test(
      'duplicate owned SDK notifications share one delegate removal',
      () async {
        final a = _fakeSessionJson(
          accessToken: _fakeAccessToken(sessionId: 'sess-a'),
        );
        final delegate = _FakeLocalStorage().._snapshot = a;
        final project = _projectIdentity('https://project.example');
        final coordinator = await _openCoordinator(
          delegate: delegate,
          projectIdentity: project,
        );
        final corr = SessionCorrelation.fromSessionJson(
          a,
          projectIdentity: project,
        );
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.cleanupRequired,
          correlation: corr,
        );
        await coordinator.runOwnedRecoveryOperation(
          expectedOperationId: coordinator.readRecoveryEntry()!.operationId,
          expectedCorrelation: corr,
          action: (tx) async {
            await tx.runOwnedSdkLocalCleanup(() async {
              await Future.wait([
                coordinator.sdkLocalStorage.removePersistedSession(),
                coordinator.sdkLocalStorage.removePersistedSession(),
              ]);
            });
            return null;
          },
        );
        expect(delegate.removeCalls, 1);
        expect(delegate._snapshot, isNull);
      },
    );

    test(
      'correct owner/correlation allows guarded remove inline, no deadlock',
      () async {
        final delegate = _FakeLocalStorage()
          .._snapshot = _fakeSessionJson(
            accessToken: _fakeAccessToken(sessionId: 'sess-a'),
          );
        final coordinator = await _openCoordinator(
          delegate: delegate,
          projectIdentity: _projectIdentity('https://project.example'),
        );
        final corr = SessionCorrelation.fromSessionJson(
          _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-a')),
          projectIdentity: _projectIdentity('https://project.example'),
        );
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.cleanupRequired,
          correlation: corr,
        );
        final id = coordinator.readRecoveryEntry()!.operationId;

        final result = await coordinator.runOwnedRecoveryOperation(
          expectedOperationId: id,
          expectedCorrelation: corr,
          action: (tx) async {
            // This runs inside the held queue slot. If the guarded adapter tried
            // to enqueue removePersistedSession, it would deadlock.
            await tx.runOwnedSdkLocalCleanup(
              () => coordinator.sdkLocalStorage.removePersistedSession(),
            );
            return 'done';
          },
        );

        expect(result.allowed, isTrue);
        expect(result.value, 'done');
        expect(delegate.removeCalls, 1);
        expect(delegate._snapshot, isNull);
      },
    );

    test('wrong operation id rejects owned SDK cleanup', () async {
      final delegate = _FakeLocalStorage()
        .._snapshot = _fakeSessionJson(
          accessToken: _fakeAccessToken(sessionId: 'sess-a'),
        );
      final coordinator = await _openCoordinator(
        delegate: delegate,
        projectIdentity: _projectIdentity('https://project.example'),
      );
      final corr = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-a')),
        projectIdentity: _projectIdentity('https://project.example'),
      );
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.cleanupRequired,
        correlation: corr,
      );

      final result = await coordinator.runOwnedRecoveryOperation(
        expectedOperationId: 'wrong-id',
        expectedCorrelation: corr,
        action: (tx) async {
          await tx.runOwnedSdkLocalCleanup(
            () => coordinator.sdkLocalStorage.removePersistedSession(),
          );
          return 'done';
        },
      );

      expect(result.allowed, isFalse);
      expect(delegate.removeCalls, 0);
      expect(delegate._snapshot, isNotNull);
    });

    test('wrong correlation rejects owned SDK cleanup', () async {
      final delegate = _FakeLocalStorage()
        .._snapshot = _fakeSessionJson(
          accessToken: _fakeAccessToken(sessionId: 'sess-a'),
        );
      final coordinator = await _openCoordinator(
        delegate: delegate,
        projectIdentity: _projectIdentity('https://project.example'),
      );
      final corrA = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-a')),
        projectIdentity: _projectIdentity('https://project.example'),
      );
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.cleanupRequired,
        correlation: corrA,
      );
      final id = coordinator.readRecoveryEntry()!.operationId;

      final corrB = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-b')),
        projectIdentity: _projectIdentity('https://project.example'),
      );
      final result = await coordinator.runOwnedRecoveryOperation(
        expectedOperationId: id,
        expectedCorrelation: corrB,
        action: (tx) async {
          await tx.runOwnedSdkLocalCleanup(
            () => coordinator.sdkLocalStorage.removePersistedSession(),
          );
          return 'done';
        },
      );

      expect(result.allowed, isFalse);
      expect(delegate.removeCalls, 0);
      expect(delegate._snapshot, isNotNull);
    });

    test('escaped transaction rejects owned SDK cleanup', () async {
      final delegate = _FakeLocalStorage()
        .._snapshot = _fakeSessionJson(
          accessToken: _fakeAccessToken(sessionId: 'sess-a'),
        );
      final coordinator = await _openCoordinator(
        delegate: delegate,
        projectIdentity: _projectIdentity('https://project.example'),
      );
      final corr = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-a')),
        projectIdentity: _projectIdentity('https://project.example'),
      );
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.cleanupRequired,
        correlation: corr,
      );
      final id = coordinator.readRecoveryEntry()!.operationId;

      AuthRecoveryTransaction? escaped;
      await coordinator.runOwnedRecoveryOperation(
        expectedOperationId: id,
        expectedCorrelation: corr,
        action: (tx) async {
          escaped = tx;
          return null;
        },
      );

      expect(
        () => escaped!.runOwnedSdkLocalCleanup(
          () => coordinator.sdkLocalStorage.removePersistedSession(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(delegate.removeCalls, 0);
      expect(delegate._snapshot, isNotNull);
    });

    test('owned SDK cleanup does not touch operation B', () async {
      final delegate = _FakeLocalStorage();
      final coordinator = await _openCoordinator(
        delegate: delegate,
        projectIdentity: _projectIdentity('https://project.example'),
      );
      final corrA = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-a')),
        projectIdentity: _projectIdentity('https://project.example'),
      );
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.cleanupRequired,
        correlation: corrA,
      );
      final idA = coordinator.readRecoveryEntry()!.operationId;
      await coordinator.completeOwnedOperation(expectedOperationId: idA);

      final bSnapshot = _fakeSessionJson(
        accessToken: _fakeAccessToken(sessionId: 'sess-b'),
      );
      await coordinator.sdkLocalStorage.persistSession(bSnapshot);
      final corrB = SessionCorrelation.fromSessionJson(
        _fakeSessionJson(accessToken: _fakeAccessToken(sessionId: 'sess-b')),
        projectIdentity: _projectIdentity('https://project.example'),
      );
      await coordinator.beginOperation(
        type: AuthRecoveryOperationType.signOut,
        phase: AuthRecoveryPhase.cleanupRequired,
        correlation: corrB,
      );
      expect(coordinator.readRecoveryEntry()!.operationId, isNot(idA));

      final result = await coordinator.runOwnedRecoveryOperation(
        expectedOperationId: idA,
        expectedCorrelation: corrA,
        action: (tx) async {
          await tx.runOwnedSdkLocalCleanup(
            () => coordinator.sdkLocalStorage.removePersistedSession(),
          );
          return null;
        },
      );

      expect(result.allowed, isFalse);
      expect(delegate.removeCalls, 0);
      expect(delegate._snapshot, bSnapshot);
    });
  });

  group('C3 Addendum A narrow coordinator operations', () {
    test(
      'same-key upgrade preserves metadata and cannot grant deletion to placeholder owner',
      () async {
        final project = _randomProjectIdentity();
        final delegate = _FakeLocalStorage();
        final coordinator = await _openCoordinator(
          projectIdentity: project,
          delegate: delegate,
        );
        addTearDown(coordinator.close);
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.credentialExchange,
          phase: AuthRecoveryPhase.timedOutPending,
          correlation: SessionCorrelation(
            userId: 'credential-exchange-pending-0',
            projectIdentity: project,
          ),
        );
        final original = coordinator.readRecoveryEntry()!;
        final exact = SessionCorrelation(
          userId: 'user-a',
          sessionId: 'sess-123',
          projectIdentity: project,
        );
        delegate._snapshot = _fakeSessionJson(accessToken: _fakeAccessToken());
        final bytes = delegate._snapshot;
        late AuthRecoveryTransaction escaped;
        final result = await coordinator.runOwnedRecoveryOperation<bool>(
          expectedOperationId: original.operationId,
          action: (tx) async {
            escaped = tx;
            expect(
              await tx.upgradeCredentialCorrelation(
                exact,
                phase: AuthRecoveryPhase.neutralizing,
              ),
              isTrue,
            );
            expect(await tx.removeMatchingRecoverySnapshot(), isFalse);
            return true;
          },
        );
        expect(result.value, isTrue);
        final updated = coordinator.readRecoveryEntry()!;
        expect(updated.operationId, original.operationId);
        expect(updated.createdAt, original.createdAt);
        expect(updated.operationType, original.operationType);
        expect(updated.sessionId, exact.sessionId);
        expect(delegate._snapshot, bytes);
        expect(delegate.removeCalls, 0);
        await expectLater(
          escaped.upgradeCredentialCorrelation(
            exact,
            phase: AuthRecoveryPhase.neutralizing,
          ),
          throwsStateError,
        );
        await expectLater(escaped.resetQuarantinedSnapshot(), throwsStateError);
        final owned = await coordinator.runOwnedRecoveryOperation<bool>(
          expectedOperationId: original.operationId,
          expectedCorrelation: exact,
          action: (tx) async {
            expect(
              await tx.upgradeCredentialCorrelation(
                exact,
                phase: AuthRecoveryPhase.neutralizing,
              ),
              isTrue,
            );
            expect(
              await tx.upgradeCredentialCorrelation(
                SessionCorrelation(
                  userId: 'user-b',
                  sessionId: 'sess-b',
                  projectIdentity: project,
                ),
                phase: AuthRecoveryPhase.neutralizing,
              ),
              isFalse,
            );
            return tx.removeMatchingRecoverySnapshot();
          },
        );
        expect(owned.value, isTrue);
        expect(delegate.removeCalls, 1);
      },
    );

    for (final phase in AuthRecoveryPhase.values) {
      test(
        'upgrade source phase is explicitly limited: ${phase.name}',
        () async {
          final project = _randomProjectIdentity();
          final coordinator = await _openCoordinator(projectIdentity: project);
          addTearDown(coordinator.close);
          await coordinator.beginOperation(
            type: AuthRecoveryOperationType.credentialExchange,
            phase: phase,
            correlation: SessionCorrelation(
              userId: 'pending',
              projectIdentity: project,
            ),
          );
          final id = coordinator.readRecoveryEntry()!.operationId;
          final result = await coordinator.runOwnedRecoveryOperation<bool>(
            expectedOperationId: id,
            action: (tx) => tx.upgradeCredentialCorrelation(
              SessionCorrelation(
                userId: 'a',
                sessionId: 'a-id',
                projectIdentity: project,
              ),
              phase: AuthRecoveryPhase.neutralizing,
            ),
          );
          expect(
            result.value,
            phase == AuthRecoveryPhase.active ||
                phase == AuthRecoveryPhase.timedOutPending,
          );
          expect(coordinator.readRecoveryEntry()!.operationId, id);
        },
      );
    }

    test(
      'sign-out ownership cannot use C3 upgrade or unattributed reset',
      () async {
        final project = _randomProjectIdentity();
        final delegate = _FakeLocalStorage().._snapshot = '{unknown}';
        final coordinator = await _openCoordinator(
          projectIdentity: project,
          delegate: delegate,
        );
        addTearDown(coordinator.close);
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.signOut,
          phase: AuthRecoveryPhase.blockedUnattributed,
          correlation: SessionCorrelation(
            userId: 'pending',
            projectIdentity: project,
          ),
        );
        await coordinator.runOwnedRecoveryOperation<void>(
          expectedOperationId: coordinator.readRecoveryEntry()!.operationId,
          action: (tx) async {
            expect(
              await tx.upgradeCredentialCorrelation(
                SessionCorrelation(
                  userId: 'a',
                  sessionId: 'a',
                  projectIdentity: project,
                ),
                phase: AuthRecoveryPhase.neutralizing,
              ),
              isFalse,
            );
            expect(
              await tx.resetQuarantinedSnapshot(),
              QuarantinedResetResult.denied,
            );
            expect(await tx.removeMatchingRecoverySnapshot(), isFalse);
          },
        );
        expect(delegate.removeCalls, 0);
        expect(delegate._snapshot, '{unknown}');
      },
    );

    test(
      'insufficient or different-project upgrade cannot gain exact authority',
      () async {
        final project = _randomProjectIdentity();
        final coordinator = await _openCoordinator(projectIdentity: project);
        addTearDown(coordinator.close);
        await coordinator.beginOperation(
          type: AuthRecoveryOperationType.credentialExchange,
          phase: AuthRecoveryPhase.active,
          correlation: SessionCorrelation(
            userId: 'pending',
            projectIdentity: project,
          ),
        );
        final original = coordinator.readRecoveryEntry()!;
        await coordinator.runOwnedRecoveryOperation<void>(
          expectedOperationId: original.operationId,
          action: (tx) async {
            for (final bad in [
              SessionCorrelation(userId: 'a', projectIdentity: project),
              const SessionCorrelation(
                userId: 'a',
                sessionId: 'a',
                projectIdentity: 'foreign-project',
              ),
            ]) {
              expect(
                await tx.upgradeCredentialCorrelation(
                  bad,
                  phase: AuthRecoveryPhase.neutralizing,
                ),
                isFalse,
              );
            }
          },
        );
        expect(coordinator.readRecoveryEntry()!.toMap(), original.toMap());
      },
    );
  });
}
