import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/ownership/data_owner.dart';
import 'package:civilpedia/core/ownership/guest_install_identity.dart';
import 'package:civilpedia/core/ownership/local_data_claim_coordinator.dart';
import 'package:civilpedia/core/ownership/local_favorites_gateway.dart';
import 'package:civilpedia/core/ownership/ownership_registry.dart';
import 'package:civilpedia/core/ownership/ownership_registry_store.dart';
import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/data/local/hive_helper.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/profile/data/local_user_profile_data_source.dart';
import 'package:civilpedia/features/profile/data/local_user_profile_repository.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/projects/data/local_project_note_repository.dart';
import 'package:civilpedia/features/projects/data/local_project_repository.dart';
import 'package:civilpedia/features/projects/data/project_local_data_source.dart';
import 'package:civilpedia/features/projects/data/project_persistence_gateway.dart';
import 'package:civilpedia/features/projects/domain/entities/project.dart';
import 'package:civilpedia/features/saved/data/hive_saved_reference_store.dart';
import 'package:civilpedia/features/saved/domain/saved_item_reference.dart';

import 'fakes/fake_auth_gateway.dart';

const _boxName = 'a5_5_claim_box';
const _userA = 'auth-users-uuid-A';
const _userB = 'auth-users-uuid-B';

/// Registry store that always throws on save, simulating an interrupted /
/// failed claim write.
class _ThrowingRegistryStore implements OwnershipRegistryStore {
  int saveAttempts = 0;

  @override
  Future<RegistryState> load() async => const RegistryMissing();

  @override
  Future<void> save(OwnershipRegistry registry) async {
    saveAttempts++;
    throw Exception('simulated disk write failure');
  }
}

LocalDataClaimCoordinator _buildCoordinator() {
  return LocalDataClaimCoordinator(
    registryStore: const SharedPreferencesOwnershipRegistryStore(),
    guestIdentity: GuestInstallIdentity(
      userProfileRepository: LocalUserProfileRepository(
        LocalUserProfileDataSource(),
      ),
    ),
    projectGateway: ProjectPersistenceGateway(),
    savedReferenceStore: const HiveSavedReferenceStore(),
    favoritesGateway: const HiveLocalFavoritesGateway(),
  );
}

Future<RegistryState> _loadRegistryState() async {
  return const SharedPreferencesOwnershipRegistryStore().load();
}

Future<OwnershipRegistry> _loadRegistry() async {
  final state = await _loadRegistryState();
  if (state is RegistryValid) return state.registry;
  throw StateError('expected a valid registry, got $state');
}

Future<Project> _seedProject() async {
  return LocalProjectRepository(ProjectLocalDataSource()).createProject(
    'مشروع الجسر',
  );
}

Future<String> _seedNote(String projectId) async {
  final gateway = ProjectPersistenceGateway();
  final noteRepo = LocalProjectNoteRepository(gateway);
  final note = await noteRepo.createNote(projectId: projectId, text: 'ملاحظة');
  return note!.noteId;
}

Future<void> _seedSavedReference([String? entityId]) async {
  await const HiveSavedReferenceStore().save(
    SavedItemReference(
      ownerDomain: SavedReferenceOwners.knowledge,
      entityType: SavedReferenceEntityTypes.topic,
      entityId: entityId ?? 'topic-9',
    ),
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('civilpedia_a5_5_claim');
    await HiveHelper.init(path: tempDir.path, boxName: _boxName);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Hive.box(_boxName).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('A5.5 ownership primitives', () {
    test('DataOwner guest requires a non-empty guestId', () {
      expect(
        () => DataOwner.guest(guestId: ''),
        throwsAssertionError,
      );
      expect(DataOwner.guest(guestId: 'g-1').isGuest, isTrue);
      expect(DataOwner.guest(guestId: 'g-1').userId, isNull);
    });

    test('DataOwner user requires a non-empty userId', () {
      expect(() => DataOwner.user(userId: ''), throwsAssertionError);
      final owner = DataOwner.user(userId: _userA);
      expect(owner.isUser, isTrue);
      expect(owner.ownedBy(_userA), isTrue);
      expect(owner.ownedBy(_userB), isFalse);
    });

    test('DataOwner serialization round-trip', () {
      final roundTrip = DataOwner.tryFromMap(
        DataOwner.user(userId: _userA).toMap(),
      )!;
      expect(roundTrip, DataOwner.user(userId: _userA));
      expect(
        DataOwner.tryFromMap(DataOwner.guest(guestId: 'g').toMap()),
        DataOwner.guest(guestId: 'g'),
      );
      expect(DataOwner.tryFromMap(const {}), isNull);
      expect(DataOwner.tryFromMap({'type': 'user'}), isNull);
    });

    test('OwnershipRegistry tryDecode fails closed on malformed ownership',
        () {
      final base = <String, dynamic>{
        'schemaVersion': 1,
        'owners': {
          'project:a': {'type': 'user', 'userId': _userA},
        },
        'claims': [],
      };
      expect(
        OwnershipRegistry.tryDecode(base).isOwnedByUser('project:a', _userA),
        isTrue,
      );

      // Any malformed ownership entry → ownership becomes ambiguous → corrupt.
      expect(
        () => OwnershipRegistry.tryDecode({
          ...base,
          'owners': {
            'project:a': {'type': 'bogus'},
          },
        }),
        throwsA(
          isA<OwnershipRegistryCorruptException>(),
        ),
      );
      expect(
        () => OwnershipRegistry.tryDecode({
          ...base,
          'owners': {'project:a': 'not-a-map'},
        }),
        throwsA(isA<OwnershipRegistryCorruptException>()),
      );
      expect(
        () => OwnershipRegistry.tryDecode({
          ...base,
          'owners': {'': {'type': 'user', 'userId': _userA}},
        }),
        throwsA(isA<OwnershipRegistryCorruptException>()),
      );
      expect(
        () => OwnershipRegistry.tryDecode({...base, 'owners': [1, 2]}),
        throwsA(isA<OwnershipRegistryCorruptException>()),
      );
      expect(
        () => OwnershipRegistry.tryDecode({'boundUserId': 42, ...base}),
        throwsA(isA<OwnershipRegistryCorruptException>()),
      );
      expect(
        () => OwnershipRegistry.tryDecode({'boundUserId': '', ...base}),
        throwsA(isA<OwnershipRegistryCorruptException>()),
      );
      expect(
        () => OwnershipRegistry.tryDecode([1, 2, 3]),
        throwsA(isA<OwnershipRegistryCorruptException>()),
      );
      expect(
        () => OwnershipRegistry.tryDecode(null),
        throwsA(isA<OwnershipRegistryCorruptException>()),
      );

      // Non-ownership-critical additive fields are tolerated: malformed claim
      // journal entries and unknown top-level fields never change ownership.
      final tolerant = OwnershipRegistry.tryDecode({
        ...base,
        'unknownAdditiveField': 123,
        'claims': [
          {
            'guestId': 'g',
            'userId': _userA,
            'claimedAt': '2026-09-01T00:00:00.000Z',
          },
          {'guestId': 'broken'},
          42,
        ],
      });
      expect(tolerant.isOwnedByUser('project:a', _userA), isTrue);
      expect(tolerant.claims, hasLength(1));
    });

    test('OwnershipRegistry claim operations are idempotent', () {
      var registry = OwnershipRegistry();
      registry = registry.claimKey('project:p1', _userA);
      final once = registry.claimKey('project:p1', _userA);
      expect(once.ownerOf('project:p1')!.ownedBy(_userA), isTrue);
      expect(once, registry, reason: 're-claim must not change the registry');

      final journaled = registry.withClaimRecord('g-1', _userA);
      final journaledTwice = journaled.withClaimRecord('g-1', _userA);
      expect(journaled.claims, hasLength(1));
      expect(journaledTwice.claims, hasLength(1));

      final bound = registry.copyWithBoundAccount(
        userId: _userA,
        guestId: 'g-1',
      );
      expect(
        bound.copyWithBoundAccount(userId: _userA, guestId: 'g-1').boundUserId,
        _userA,
      );
    });

    test('registry JSON round-trip preserves everything', () async {
      final store = const SharedPreferencesOwnershipRegistryStore();
      var registry = OwnershipRegistry()
          .claimKey('project:p1', _userA)
          .withClaimRecord('g-1', _userA)
          .copyWithBoundAccount(userId: _userA, guestId: 'g-1');
      await store.save(registry);
      final state = await store.load();
      expect(state, isA<RegistryValid>());
      final loaded = (state as RegistryValid).registry;
      expect(loaded.boundUserId, _userA);
      expect(loaded.boundGuestId, 'g-1');
      expect(loaded.isOwnedByUser('project:p1', _userA), isTrue);
      expect(loaded.claims.single.guestId, 'g-1');
      expect(loaded.claims.single.userId, _userA);
    });

    test('registry store fail-closed: corrupt json is DISTINCT from missing',
        () async {
      // Absent key → legitimate missing state.
      final missing = await const SharedPreferencesOwnershipRegistryStore()
          .load();
      expect(missing, isA<RegistryMissing>());

      // Present-but-corrupt payload → fail-closed corrupt state, payload kept.
      const corruptPayload = '{not valid json';
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.ownershipRegistry: corruptPayload,
      });
      final corrupt = await const SharedPreferencesOwnershipRegistryStore()
          .load();
      expect(corrupt, isA<RegistryCorrupt>());
      expect(
        (await SharedPreferences.getInstance())
            .getString(AppStorageKeys.ownershipRegistry),
        corruptPayload,
        reason: 'the corrupt payload must never be silently replaced',
      );
    });
  });

  group('A5.5 guest identity', () {
    test('profile anonymousInstallId wins when present', () async {
      final repo = LocalUserProfileRepository(LocalUserProfileDataSource());
      await repo.saveProfile(
        LocalUserProfile(anonymousInstallId: 'user_profile_123'),
      );
      final identity = GuestInstallIdentity(userProfileRepository: repo);
      expect(await identity.resolveGuestId(), 'user_profile_123');
    });

    test('falls back to a persisted install id and stays stable', () async {
      final repo = LocalUserProfileRepository(LocalUserProfileDataSource());
      final identity = GuestInstallIdentity(userProfileRepository: repo);
      final first = await identity.resolveGuestId();
      expect(first, startsWith('guest_'));

      final second = await identity.resolveGuestId();
      expect(second, first, reason: 'install id must be stable across calls');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppStorageKeys.anonymousInstallId), first);
    });

    test('empty profile anonymousInstallId falls back to install id', () async {
      final repo = LocalUserProfileRepository(LocalUserProfileDataSource());
      await repo.saveProfile(LocalUserProfile(anonymousInstallId: ''));
      final identity = GuestInstallIdentity(userProfileRepository: repo);
      final id = await identity.resolveGuestId();
      expect(id, startsWith('guest_'));
    });
  });

  group('A5.5 claim lifecycle (test matrix)', () {
    test('1. fresh guest with no data signs in → no failure, no fake records',
        () async {
      final outcome = await _buildCoordinator().claimFor(_userA);

      expect(outcome.executed, isTrue);
      expect(outcome.claimedRecordCount, 0);
      expect(outcome.claimedKeys, isEmpty);

      final registry = await _loadRegistry();
      expect(registry.boundUserId, _userA);
      expect(registry.owners, isEmpty);

      expect(await ProjectPersistenceGateway().readProjects(), isEmpty);
      expect(await const HiveSavedReferenceStore().loadAll(), isEmpty);
    });

    test('2. guest with a Project signs in → survives and becomes owned',
        () async {
      await _seedProject();
      final before = await ProjectPersistenceGateway().readProjects();
      final projectId = before.single.id;

      final outcome = await _buildCoordinator().claimFor(_userA);

      expect(outcome.claimedRecordCount, 1);
      expect(outcome.claimedKeys, contains('project:$projectId'));

      final projects = await ProjectPersistenceGateway().readProjects();
      expect(projects, hasLength(1));
      expect(projects.single.id, projectId);
      expect(projects.single.name, 'مشروع الجسر');

      final registry = await _loadRegistry();
      expect(registry.isOwnedByUser('project:$projectId', _userA), isTrue);
    });

    test('3. guest with a Saved item signs in → item survives', () async {
      await _seedSavedReference('topic-9');

      final outcome = await _buildCoordinator().claimFor(_userA);

      expect(
        outcome.claimedKeys,
        contains('saved:${SavedReferenceOwners.knowledge}:'
            '${SavedReferenceEntityTypes.topic}:topic-9'),
      );

      final refs = await const HiveSavedReferenceStore().loadAll();
      expect(refs, hasLength(1));
      expect(refs.single.entityId, 'topic-9');

      final registry = await _loadRegistry();
      expect(
        registry.isOwnedByUser(
          'saved:${SavedReferenceOwners.knowledge}:'
          '${SavedReferenceEntityTypes.topic}:topic-9',
          _userA,
        ),
        isTrue,
      );
    });

    test('4. guest with a Note signs in → note survives', () async {
      final seeded = await _seedProject();
      final noteId = await _seedNote(seeded.id);

      final outcome = await _buildCoordinator().claimFor(_userA);

      expect(outcome.claimedKeys, contains('note:$noteId'));

      final notes = await ProjectPersistenceGateway()
          .readProjectNotes(seeded.id);
      expect(notes, hasLength(1));
      expect(notes.single.text, 'ملاحظة');

      final registry = await _loadRegistry();
      expect(registry.isOwnedByUser('note:$noteId', _userA), isTrue);
    });

    test('5. multiple guest records → all preserved and claimed', () async {
      final gateway = ProjectPersistenceGateway();
      final projectRepo = LocalProjectRepository(
        ProjectLocalDataSource(gateway),
      );
      final p1 = await projectRepo.createProject('P1');
      final p2 = await projectRepo.createProject('P2');
      final p3 = await projectRepo.createProject('P3');
      await LocalProjectNoteRepository(gateway)
          .createNote(projectId: p1.id, text: 'n1');
      await LocalProjectNoteRepository(gateway)
          .createNote(projectId: p2.id, text: 'n2');
      await _seedSavedReference('t-1');
      await _seedSavedReference('t-2');

      final outcome = await _buildCoordinator().claimFor(_userA);

      expect(outcome.claimedRecordCount, greaterThanOrEqualTo(5));
      for (final projectId in [p1.id, p2.id, p3.id]) {
        expect(outcome.claimedKeys, contains('project:$projectId'));
      }

      final registry = await _loadRegistry();
      for (final projectId in [p1.id, p2.id, p3.id]) {
        expect(registry.isOwnedByUser('project:$projectId', _userA), isTrue);
      }

      expect(await gateway.readProjects(), hasLength(3));
      expect(await const HiveSavedReferenceStore().loadAll(), hasLength(2));
    });

    test('6. claim run twice → no duplication, no corruption', () async {
      await _seedProject();
      await _seedSavedReference('topic-9');

      final coordinator = _buildCoordinator();
      final first = await coordinator.claimFor(_userA);
      final second = await coordinator.claimFor(_userA);

      expect(first.claimedRecordCount, greaterThan(0));
      expect(second.claimedRecordCount, 0, reason: 'no new claims on re-run');
      expect(second.alreadyOwnedCount, greaterThan(0));

      final registry = await _loadRegistry();
      expect(registry.claims, hasLength(1), reason: 'journal stays singular');
      expect(
        registry.owners.keys.where((k) => k.startsWith('project:')).length,
        1,
      );

      expect(await ProjectPersistenceGateway().readProjects(), hasLength(1));
      expect(await const HiveSavedReferenceStore().loadAll(), hasLength(1));
    });

    test('7. failed/interrupted claim leaves original data recoverable',
        () async {
      await _seedProject();
      final beforeJson = (await SharedPreferences.getInstance())
          .getString(AppStorageKeys.projectsList);

      final failing = _ThrowingRegistryStore();
      final coordinator = LocalDataClaimCoordinator(
        registryStore: failing,
        guestIdentity: GuestInstallIdentity(
          userProfileRepository: LocalUserProfileRepository(
            LocalUserProfileDataSource(),
          ),
        ),
        projectGateway: ProjectPersistenceGateway(),
        savedReferenceStore: const HiveSavedReferenceStore(),
        favoritesGateway: const HiveLocalFavoritesGateway(),
      );

      await expectLater(coordinator.claimFor(_userA), throwsException);
      expect(failing.saveAttempts, 1);

      // Source data unchanged on failed claim.
      final afterJson = (await SharedPreferences.getInstance())
          .getString(AppStorageKeys.projectsList);
      expect(afterJson, beforeJson);
      expect(await ProjectPersistenceGateway().readProjects(), hasLength(1));

      // Recovery: a later run on the real store claims cleanly.
      final recovered = await _buildCoordinator().claimFor(_userA);
      expect(recovered.executed, isTrue);
      expect(recovered.claimedRecordCount, 1);
      expect((await _loadRegistry()).boundUserId, _userA);
    });

    test('8. logout leaves local owned data in place', () async {
      final seeded = await _seedProject();

      final coordinator = _buildCoordinator();
      final provider = AuthProvider(
        gateway: FakeAuthGateway(signInResult: fakeSession),
        onAuthenticated: (s) async => coordinator.claimFor(s.userId),
      );

      await provider.signInWithGoogle();
      await _settleClaimFuture();
      expect(provider.isLoggedIn, isTrue);

      var registry = await _loadRegistry();
      expect(registry.boundUserId, fakeSession.userId);
      expect(
        registry.isOwnedByUser('project:${seeded.id}', fakeSession.userId),
        isTrue,
      );

      await provider.signOut();
      expect(provider.isLoggedIn, isFalse);

      // Logout must neither delete the content nor revert the ownership.
      registry = await _loadRegistry();
      expect(registry.boundUserId, fakeSession.userId);
      expect(
        registry.isOwnedByUser('project:${seeded.id}', fakeSession.userId),
        isTrue,
      );
      final projects = await ProjectPersistenceGateway().readProjects();
      expect(projects, hasLength(1));
      expect(projects.single.id, seeded.id);
    });

    test('9. re-login to the same account preserves ownership', () async {
      final seeded = await _seedProject();

      final coordinator = _buildCoordinator();
      await coordinator.claimFor(_userA);

      // Simulate logout then re-login of the SAME account.
      final reLogin = await coordinator.claimFor(_userA);
      expect(reLogin.executed, isTrue);
      expect(reLogin.claimedRecordCount, 0);

      final registry = await _loadRegistry();
      expect(registry.boundUserId, _userA);
      expect(registry.isOwnedByUser('project:${seeded.id}', _userA), isTrue);
      expect(registry.claims, hasLength(1));
    });

    test('10. legacy pre-A5.5 local records migrate without key deletion',
        () async {
      final legacyProjectJson = jsonEncode([
        {
          'id': 'project_legacy_1',
          'name': 'Legacy bridge',
          'createdAt': '2024-01-02T03:04:05.000',
          'updatedAt': '2024-01-03T03:04:05.000',
          'isArchived': false,
        },
      ]);
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.projectsList: legacyProjectJson,
      });
      final gateway = ProjectPersistenceGateway();
      await gateway.writeProjectNotes('project_legacy_1', []);
      await HiveHelper.toggleFavorite('art-legacy');
      await HiveHelper.addEncyclopediaFavorite('topic-legacy');
      await HiveHelper.toggleDownload('art-legacy');
      await _seedSavedReference('provider-legacy');

      final outcome = await _buildCoordinator().claimFor(_userA);

      expect(outcome.executed, isTrue);
      expect(outcome.claimedRecordCount, greaterThanOrEqualTo(5));

      // Legacy keys still present, byte-identical (no re-write, no deletion).
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppStorageKeys.projectsList), legacyProjectJson);
      expect(
        prefs.getString(AppStorageKeys.projectNotes('project_legacy_1')),
        '[]',
      );

      final projects = await gateway.readProjects();
      expect(projects.single.id, 'project_legacy_1');
      expect(HiveHelper.getFavorites(), contains('art-legacy'));
      expect(HiveHelper.getEncyclopediaFavorites(), contains('topic-legacy'));
      expect(HiveHelper.getDownloads(), contains('art-legacy'));

      final registry = await _loadRegistry();
      expect(
        registry.isOwnedByUser('project:project_legacy_1', _userA),
        isTrue,
      );
      expect(
        registry.isOwnedByUser(
          'saved:${SavedReferenceOwners.knowledge}:'
          '${SavedReferenceEntityTypes.topic}:provider-legacy',
          _userA,
        ),
        isTrue,
      );
    });

    test('11. a different authenticated user never reassigns claimed data',
        () async {
      final seeded = await _seedProject();

      final coordinator = _buildCoordinator();
      final first = await coordinator.claimFor(_userA);
      expect(first.executed, isTrue);

      final second = await coordinator.claimFor(_userB);
      expect(second.executed, isFalse);
      expect(second.boundUserId, _userA);

      final registry = await _loadRegistry();
      expect(registry.boundUserId, _userA);
      expect(registry.isOwnedByUser('project:${seeded.id}', _userA), isTrue);
      expect(registry.isOwnedByUser('project:${seeded.id}', _userB), isFalse);

      // Data itself untouched.
      final projects = await ProjectPersistenceGateway().readProjects();
      expect(projects, hasLength(1));
      expect(projects.single.id, seeded.id);
    });
  });

  group('A5.5 fail-closed corruption regression', () {
    test('1. missing registry is legitimate: first claim succeeds', () async {
      expect(await _loadRegistryState(), isA<RegistryMissing>());

      await _seedProject();
      final outcome = await _buildCoordinator().claimFor(_userA);

      expect(outcome.executed, isTrue);
      expect(outcome.blockedCorruptRegistry, isFalse);

      final state = await _loadRegistryState();
      expect(state, isA<RegistryValid>());
      expect((state as RegistryValid).registry.boundUserId, _userA);
    });

    test('2. invalid JSON payload → claim blocked, payload preserved',
        () async {
      const corruptPayload = '{not valid json';
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.ownershipRegistry: corruptPayload,
      });
      await _seedProject();

      final outcome = await _buildCoordinator().claimFor(_userA);

      expect(outcome.executed, isFalse);
      expect(outcome.blockedCorruptRegistry, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppStorageKeys.ownershipRegistry), corruptPayload);
      expect(
        prefs.getString(AppStorageKeys.projectsList),
        isNotNull,
        reason: 'user data must remain exactly as it was',
      );
      expect(await ProjectPersistenceGateway().readProjects(), hasLength(1));
    });

    test('3. wrong root structure/type → claim blocked', () async {
      const payload = '[1, 2, 3]';
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.ownershipRegistry: payload,
      });

      final outcome = await _buildCoordinator().claimFor(_userA);

      expect(outcome.blockedCorruptRegistry, isTrue);
      expect(
        (await SharedPreferences.getInstance())
            .getString(AppStorageKeys.ownershipRegistry),
        payload,
      );
    });

    test('4. corrupt bound-user ownership metadata → claim blocked', () async {
      final corrupt = {
        'schemaVersion': 1,
        'boundUserId': 12345,
        'owners': <String, dynamic>{},
        'claims': <dynamic>[],
      };
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.ownershipRegistry: jsonEncode(corrupt),
      });

      final outcome = await _buildCoordinator().claimFor(_userA);

      expect(outcome.blockedCorruptRegistry, isTrue);
      expect(outcome.executed, isFalse);
    });

    test('5. corrupt registry + different user → NEVER reassigns anything',
        () async {
      const corruptPayload = '{corrupt-but-unreadable';
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.ownershipRegistry: corruptPayload,
      });
      await _seedProject();
      await _seedSavedReference('topic-9');

      final first = await _buildCoordinator().claimFor(_userA);
      expect(first.blockedCorruptRegistry, isTrue);

      final second = await _buildCoordinator().claimFor(_userB);
      expect(second.blockedCorruptRegistry, isTrue);

      expect(await _loadRegistryState(), isA<RegistryCorrupt>());
      expect(
        (await SharedPreferences.getInstance())
            .getString(AppStorageKeys.ownershipRegistry),
        corruptPayload,
      );

      expect(await ProjectPersistenceGateway().readProjects(), hasLength(1));
      expect(await const HiveSavedReferenceStore().loadAll(), hasLength(1));
    });

    test('6. intended user cannot be proven from a corrupt registry → no guess',
        () async {
      // Shaped like a real registry that owned data for _userA, but one
      // ownership entry is malformed — the full ownership picture can no
      // longer be proven to be correct.
      final halfCorrupt = {
        'schemaVersion': 1,
        'boundUserId': _userA,
        'boundGuestId': 'guest_1',
        'owners': {
          'project:p1': {'type': 'user', 'userId': _userA},
          'project:p2': 'boom',
        },
        'claims': <dynamic>[],
      };
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.ownershipRegistry: jsonEncode(halfCorrupt),
      });
      await _seedProject();

      final outcome = await _buildCoordinator().claimFor(_userA);

      expect(
        outcome.blockedCorruptRegistry,
        isTrue,
        reason: 'ownership cannot be proven → fail closed, never guess',
      );
      expect(outcome.executed, isFalse);
      expect(await _loadRegistryState(), isA<RegistryCorrupt>());
    });

    test('7. blocked claim leaves ALL user data byte/logically unchanged',
        () async {
      const corruptPayload = '{not valid json';
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.ownershipRegistry: corruptPayload,
      });
      final seeded = await _seedProject();
      await _seedNote(seeded.id);
      await _seedSavedReference('topic-9');
      await HiveHelper.toggleFavorite('art-1');
      await HiveHelper.addEncyclopediaFavorite('topic-2');
      await HiveHelper.toggleDownload('art-1');

      final prefs = await SharedPreferences.getInstance();
      final projectsJson = prefs.getString(AppStorageKeys.projectsList);
      final notesJson = prefs.getString(
        AppStorageKeys.projectNotes(seeded.id),
      );
      final favoritesBefore = HiveHelper.getFavorites().toList();
      final encyclopediaBefore = HiveHelper.getEncyclopediaFavorites().toList();
      final downloadsBefore = HiveHelper.getDownloads().toList();

      final outcome = await _buildCoordinator().claimFor(_userA);
      expect(outcome.blockedCorruptRegistry, isTrue);
      expect(outcome.executed, isFalse);

      final prefsAfter = await SharedPreferences.getInstance();
      expect(
        prefsAfter.getString(AppStorageKeys.ownershipRegistry),
        corruptPayload,
      );
      expect(prefsAfter.getString(AppStorageKeys.projectsList), projectsJson);
      expect(
        prefsAfter.getString(AppStorageKeys.projectNotes(seeded.id)),
        notesJson,
      );

      expect(await ProjectPersistenceGateway().readProjects(), hasLength(1));
      expect(
        await ProjectPersistenceGateway().readProjectNotes(seeded.id),
        hasLength(1),
      );
      expect(await const HiveSavedReferenceStore().loadAll(), hasLength(1));
      expect(HiveHelper.getFavorites(), favoritesBefore);
      expect(HiveHelper.getEncyclopediaFavorites(), encyclopediaBefore);
      expect(HiveHelper.getDownloads(), downloadsBefore);
    });

    test('8. valid registries still claim idempotently after the hardening',
        () async {
      SharedPreferences.setMockInitialValues({});
      await _seedProject();
      await _seedSavedReference('topic-9');

      final coordinator = _buildCoordinator();
      final first = await coordinator.claimFor(_userA);
      expect(first.executed, isTrue);
      expect(first.blockedCorruptRegistry, isFalse);

      final second = await coordinator.claimFor(_userA);
      expect(second.executed, isTrue);
      expect(second.claimedRecordCount, 0, reason: 'idempotent re-claim');
      expect((await _loadRegistry()).claims, hasLength(1));

      final other = await coordinator.claimFor(_userB);
      expect(other.executed, isFalse);
      expect(other.blockedCorruptRegistry, isFalse);
      expect(other.boundUserId, _userA);
    });
  });

  group('A5.5 claim trigger seam (only REAL sessions)', () {
    test('successful sign-in triggers the callback with the session', () async {
      final triggered = <AuthSession>[];
      final provider = AuthProvider(
        gateway: FakeAuthGateway(signInResult: fakeSession),
        onAuthenticated: (s) async => triggered.add(s),
      );

      await provider.signInWithGoogle();
      await _settleClaimFuture();

      expect(triggered, hasLength(1));
      expect(triggered.single.userId, fakeSession.userId);
    });

    test('cancelled sign-in does NOT trigger the callback', () async {
      var triggered = false;
      final provider = AuthProvider(
        gateway: FakeAuthGateway(signInResult: null),
        onAuthenticated: (s) async => triggered = true,
      );

      await provider.signInWithGoogle();
      expect(provider.isLoggedIn, isFalse);
      expect(triggered, isFalse);
    });

    test('failed sign-in does NOT trigger the callback', () async {
      var triggered = false;
      final provider = AuthProvider(
        gateway: FakeAuthGateway(signInError: Exception('boom')),
        onAuthenticated: (s) async => triggered = true,
      );

      await provider.signInWithGoogle();
      expect(provider.status, AuthStatus.error);
      expect(triggered, isFalse);
    });

    test('restore with a persisted session triggers the callback', () async {
      final triggered = <AuthSession>[];
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
        onAuthenticated: (s) async => triggered.add(s),
      );

      await provider.restoreSession();
      expect(provider.isLoggedIn, isTrue);
      await _settleClaimFuture();
      expect(triggered, hasLength(1));
    });

    test('restore without a session does NOT trigger the callback', () async {
      var triggered = false;
      final provider = AuthProvider(
        gateway: FakeAuthGateway(),
        onAuthenticated: (s) async => triggered = true,
      );

      await provider.restoreSession();
      expect(triggered, isFalse);
    });

    test('signOut does NOT trigger the callback and keeps data', () async {
      await _seedProject();
      var triggered = 0;
      final coordinator = _buildCoordinator();
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
        onAuthenticated: (s) async {
          triggered++;
          await coordinator.claimFor(s.userId);
        },
      );
      await provider.restoreSession();
      await _settleClaimFuture();
      expect(triggered, 1);

      await provider.signOut();
      expect(triggered, 1, reason: 'logout never re-fires the claim');
      expect(await ProjectPersistenceGateway().readProjects(), hasLength(1));
    });

    test('a throwing callback is swallowed and keeps the user authenticated',
        () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(signInResult: fakeSession),
        onAuthenticated: (s) async => throw Exception('claim boom'),
      );

      await provider.signInWithGoogle();
      await _settleClaimFuture();

      expect(provider.isLoggedIn, isTrue);
      expect(provider.error, isNull);
    });

    test('picker-open/attempt-start never claims (no session yet)', () async {
      final state = await _loadRegistryState();
      expect(state, isA<RegistryMissing>());
    });
  });
}

/// Awaits the fire-and-forget post-auth claim to finish.
Future<void> _settleClaimFuture() async {
  for (var i = 0; i < 50; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}