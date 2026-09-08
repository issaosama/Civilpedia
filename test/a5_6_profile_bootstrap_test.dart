import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/profile/data/cloud_profile.dart';
import 'package:civilpedia/features/profile/data/personal_profile_bootstrap_coordinator.dart';
import 'package:civilpedia/features/profile/data/personal_profile_remote_gateway.dart';
import 'package:civilpedia/features/profile/data/profile_bootstrap_outcome.dart';
import 'package:civilpedia/features/profile/data/region_preference.dart';
import 'package:civilpedia/features/profile/data/region_preference_gateway.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';

import 'fakes/fake_auth_gateway.dart';

const _userA = 'auth-users-uuid-A';
const _userB = 'auth-users-uuid-B';

const _sessionA = AuthSession(
  userId: _userA,
  email: 'a@cipilpedia.test',
  displayName: 'مدير أ',
);

/// In-memory local profile repository (no SharedPreferences in unit tests).
class _MemoryProfileRepository implements UserProfileRepository {
  _MemoryProfileRepository({this.profile});

  LocalUserProfile? profile;
  Object? loadError;
  Object? saveError;
  int saveCalls = 0;

  @override
  Future<LocalUserProfile?> loadProfile() async {
    if (loadError != null) throw loadError!;
    return profile;
  }

  @override
  Future<void> saveProfile(LocalUserProfile value) async {
    if (saveError != null) throw saveError!;
    saveCalls++;
    profile = value;
  }

  @override
  Future<void> clearProfile() async {
    profile = null;
  }
}

/// Programmable [PersonalProfileRemoteGateway] fake. Simulates the Supabase
/// row for a user as mutable state so create/fetch behave like PostgREST.
class _FakeRemoteGateway implements PersonalProfileRemoteGateway {
  CloudProfile? cloudProfile;
  Object? fetchError;
  Object? createError;

  /// When true, [createProfile] behaves like a unique-violation insert-race:
  /// another client wins and this gateway then serves the row it created.
  bool createAlreadyExists = false;
  CloudProfile? raceRow;

  int fetchCalls = 0;
  int createCalls = 0;
  int updatePreferenceCalls = 0;
  final List<CloudProfile> created = [];

  @override
  Future<CloudProfile?> fetchByUserId(String userId) async {
    fetchCalls++;
    if (fetchError != null) throw fetchError!;
    return cloudProfile;
  }

  @override
  Future<void> createProfile(CloudProfile profile) async {
    createCalls++;
    if (createAlreadyExists) {
      cloudProfile = raceRow;
      throw const CloudProfileAlreadyExistsException();
    }
    if (createError != null) throw createError!;
    created.add(profile);
    cloudProfile = profile;
  }

  @override
  Future<void> updateRegionPreferenceId({
    required String userId,
    required String regionPreferenceId,
  }) async {
    updatePreferenceCalls++;
    cloudProfile = CloudProfile(
      userId: userId,
      displayName: cloudProfile?.displayName,
      photoUrl: cloudProfile?.photoUrl,
      roleCode: cloudProfile?.roleCode,
      preferredRegionId: cloudProfile?.preferredRegionId,
      regionPreferenceId: regionPreferenceId,
      phone: cloudProfile?.phone,
    );
  }
}

/// Programmable [RegionPreferenceGateway] fake mirroring migration 00013.
class _FakePreferenceGateway implements RegionPreferenceGateway {
  static const Map<String, String> seededCodes = {
    'IQ_PREF_BAGHDAD_KARKH': '10000000-0000-4000-8000-000000000101',
    'IQ_PREF_BAGHDAD_RUSAFA': '10000000-0000-4000-8000-000000000102',
    'IQ_PREF_NORTH': '10000000-0000-4000-8000-000000000103',
    'IQ_PREF_CENTRAL': '10000000-0000-4000-8000-000000000104',
    'IQ_PREF_SOUTH': '10000000-0000-4000-8000-000000000105',
    'IQ_PREF_ALL': '10000000-0000-4000-8000-000000000106',
  };

  final Map<String, String> codes = seededCodes;
  Object? resolveError;
  int resolveCalls = 0;

  @override
  Future<String?> resolvePreferenceIdByCode(String code) async {
    resolveCalls++;
    if (resolveError != null) throw resolveError!;
    return codes[code];
  }
}

LocalUserProfile _localProfile({
  String installId = 'user_1234_42',
  CivilUserType userType = CivilUserType.siteEngineer,
  BaghdadArea area = BaghdadArea.karrada,
  String? name,
  String? futureCloudUserId,
  String? regionPreferenceCode,
}) {
  return LocalUserProfile(
    anonymousInstallId: installId,
    userType: userType,
    baghdadArea: area,
    name: name,
    futureCloudUserId: futureCloudUserId,
    regionPreferenceCode: regionPreferenceCode,
  );
}

PersonalProfileBootstrapCoordinator _coordinator(
  _MemoryProfileRepository repo,
  _FakeRemoteGateway gateway, {
  _FakePreferenceGateway? preferenceGateway,
}) {
  return PersonalProfileBootstrapCoordinator(
    localRepository: repo,
    remoteGateway: gateway,
    regionPreferenceGateway: preferenceGateway ?? _FakePreferenceGateway(),
  );
}

Future<void> _flushAsync() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

const _engineerCloud = CloudProfile(
  userId: _userA,
  roleCode: 'site_engineer',
);

/// Cloud row that carries a region FK without any trustworthy local mapping.
const _engineerCloudWithRegion = CloudProfile(
  userId: _userA,
  roleCode: 'site_engineer',
  preferredRegionId: '11111111-2222-3333-4444-555555555555',
);

void main() {
  group('A5.6 scenario 1 — no cloud profile → created once + bound', () {
    test('fetches null, creates exactly one row, binds local to auth users id',
        () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.siteEngineer),
      );
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      expect(gateway.fetchCalls, 1);
      expect(gateway.createCalls, 1);
      final created = gateway.created.single;
      expect(created.userId, _userA);
      expect(created.roleCode, 'site_engineer');
      expect(created.preferredRegionId, isNull);
      expect(created.phone, isNull);
      expect(repo.profile!.futureCloudUserId, _userA);
    });
  });

  group('A5.6 scenario 2 — re-run is idempotent, no duplicate row', () {
    test('second run re-reads the existing row and creates nothing', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.structuralEngineer),
      );
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway);

      final first = await coordinator.bootstrap(userId: _userA);
      final second = await coordinator.bootstrap(userId: _userA);

      expect(first, ProfileBootstrapOutcome.associated);
      expect(second, ProfileBootstrapOutcome.associated);
      expect(gateway.createCalls, 1, reason: 'only one row ever created');
      expect(gateway.created.length, 1);
    });
  });

  group('A5.6 scenario 3 — existing cloud profile identical → association',
      () {
    test('equal role and no conflicting personal fields binds locally',
        () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.siteEngineer),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = _engineerCloud;
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      expect(gateway.createCalls, 0);
      expect(repo.profile!.futureCloudUserId, _userA);
      expect(repo.profile!.userType, CivilUserType.siteEngineer);
    });

    test('cloud missing display_name while local has none → compatible',
        () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.siteEngineer),
      );
      final gateway = _FakeRemoteGateway()..cloudProfile = _engineerCloud;
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      expect(repo.profile!.futureCloudUserId, _userA);
    });
  });

  group('A5.6 scenario 4 — local already bound to same user → idempotent', () {
    test('no local write needed, succeeds and keeps binding', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.contractor,
          futureCloudUserId: _userA,
        ),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = const CloudProfile(
          userId: _userA,
          roleCode: 'contractor',
        );
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      expect(repo.saveCalls, 0, reason: 'idempotent — no redundant write');
      expect(repo.profile!.futureCloudUserId, _userA);
    });
  });

  group('A5.6 scenario 5 — different bound user → FAIL CLOSED', () {
    test('no rebind, no remote mutation, explicit outcome', () async {
      final local = _localProfile(
        userType: CivilUserType.siteEngineer,
        futureCloudUserId: _userA,
      );
      final repo = _MemoryProfileRepository(profile: local);
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userB);

      expect(outcome, ProfileBootstrapOutcome.differentUserBlocked);
      expect(repo.profile!.futureCloudUserId, _userA,
          reason: 'binding must never change from A to B');
      expect(gateway.fetchCalls, 0, reason: 'no remote read for other user');
      expect(gateway.createCalls, 0, reason: 'no remote mutation');
      expect(repo.saveCalls, 0);
    });
  });

  group('A5.6 scenario 6 — existing cloud differs → conflict, both preserved',
      () {
    test('same account, different role/region on device B → preserved both',
        () async {
      // Device A cloud: site_engineer role.
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.consultantEngineer,
          area: BaghdadArea.baya,
        ),
      );
      final gateway = _FakeRemoteGateway()..cloudProfile = _engineerCloud;
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.profileConflict);
      expect(repo.profile!.futureCloudUserId, isNull,
          reason: 'no silent association');
      expect(repo.profile!.userType, CivilUserType.consultantEngineer,
          reason: 'device B local role unchanged');
      expect(repo.profile!.baghdadArea, BaghdadArea.baya,
          reason: 'device B region stays local-only');
      expect(gateway.cloudProfile!.roleCode, 'site_engineer',
          reason: 'cloud untouched');
      expect(gateway.cloudProfile!.preferredRegionId, isNull);
      expect(gateway.createCalls, 0);
      expect(gateway.fetchCalls, 1);
    });

    test('cloud display_name differs from local name → conflict', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(name: 'Ahmad'),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = const CloudProfile(
          userId: _userA,
          roleCode: 'site_engineer',
          displayName: 'Zainab',
        );
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.profileConflict);
      expect(repo.profile!.name, 'Ahmad');
      expect(gateway.cloudProfile!.displayName, 'Zainab');
    });

    test('cloud role equal but empty vs non-empty name is NOT a conflict',
        () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(name: 'Ahmad'),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = const CloudProfile(
          userId: _userA,
          roleCode: 'site_engineer',
          displayName: '',
        );
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      expect(repo.profile!.futureCloudUserId, _userA);
    });
  });

  group('A5.6 scenario 7 — network/read failure → local untouched + retry', () {
    test('read throws: failure, binding not persisted', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.siteEngineer),
      );
      final gateway = _FakeRemoteGateway()
        ..fetchError = Exception('offline');
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.failure);
      expect(repo.profile!.futureCloudUserId, isNull,
          reason: 'binding must not be falsely marked complete');
      expect(repo.saveCalls, 0);
      expect(gateway.createCalls, 0);
    });

    test('retry succeeds after connectivity returns', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.siteEngineer),
      );
      final gateway = _FakeRemoteGateway()
        ..fetchError = Exception('offline');
      final coordinator = _coordinator(repo, gateway);

      await coordinator.bootstrap(userId: _userA);

      gateway.fetchError = null;
      final retry = await coordinator.bootstrap(userId: _userA);

      expect(retry, ProfileBootstrapOutcome.associated);
      expect(gateway.created.length, 1, reason: 'no duplicate after retry');
      expect(repo.profile!.futureCloudUserId, _userA);
    });
  });

  group('A5.6 scenario 8 — remote insert failure → local untouched', () {
    test('create throws: failure and no local write', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.siteEngineer),
      );
      final gateway = _FakeRemoteGateway()
        ..createError = Exception('db down');
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.failure);
      expect(repo.profile!.futureCloudUserId, isNull);
      expect(repo.saveCalls, 0);
      expect(gateway.created, isEmpty);
    });
  });

  group('A5.6 scenario 9 — insert race → re-read, deterministic outcome', () {
    test('race winner compatible → associated from CASE B path', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.siteEngineer),
      );
      final gateway = _FakeRemoteGateway()
        ..createAlreadyExists = true
        ..raceRow = _engineerCloud;
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      expect(gateway.createCalls, 1);
      expect(gateway.fetchCalls, 2, reason: 're-read the raced row');
      expect(repo.profile!.futureCloudUserId, _userA);
      expect(gateway.cloudProfile!.roleCode, 'site_engineer',
          reason: 'raced row preserved');
    });

    test('race winner conflicts → profileConflict, both preserved', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.consultantEngineer),
      );
      final gateway = _FakeRemoteGateway()
        ..createAlreadyExists = true
        ..raceRow = _engineerCloud;
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.profileConflict);
      expect(repo.profile!.futureCloudUserId, isNull);
      expect(gateway.cloudProfile!.roleCode, 'site_engineer');
      expect(repo.profile!.userType, CivilUserType.consultantEngineer);
    });
  });

  group('A5.6 scenario 10 — display name/photo metadata → safe create mapping',
      () {
    test('maps auth display name and photo url when available', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.structuralEngineer),
      );
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(
        userId: _userA,
        authDisplayName: 'م. أحمد',
        authPhotoUrl: 'https://example.com/avatar.jpg',
      );

      expect(outcome, ProfileBootstrapOutcome.associated);
      final created = gateway.created.single;
      expect(created.displayName, 'م. أحمد');
      expect(created.photoUrl, 'https://example.com/avatar.jpg');
      expect(created.roleCode, 'structural_engineer');
      expect(created.preferredRegionId, isNull);
      expect(created.phone, isNull);
    });

    test('local name wins over auth display name (no invention both ways)',
        () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          name: 'Local Name',
        ),
      );
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway);

      await coordinator.bootstrap(
        userId: _userA,
        authDisplayName: 'Google Name',
      );

      expect(gateway.created.single.displayName, 'Local Name');
    });
  });

  group('A5.6 scenario 11 — auth metadata missing → no invented values', () {
    test('create succeeds with role only, no empty strings', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.generalUser),
      );
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      final created = gateway.created.single;
      expect(created.displayName, isNull);
      expect(created.photoUrl, isNull);
      expect(created.roleCode, 'general_user');
    });
  });

  group('A5.6 scenario 12 — logout keeps local profile + binding', () {
    test('signOut never deletes the local binding', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          futureCloudUserId: _userA,
        ),
      );
      final gateway = _FakeRemoteGateway()..cloudProfile = _engineerCloud;
      final coordinator = _coordinator(repo, gateway);

      final auth = AuthProvider(
        gateway: FakeAuthGateway(signInResult: _sessionA),
        onAuthenticated: (session) async {
          await coordinator.bootstrap(userId: session.userId);
        },
      );
      await auth.signInWithGoogle();
      await _flushAsync();

      expect(auth.isLoggedIn, isTrue);
      expect(repo.profile!.futureCloudUserId, _userA);

      await auth.signOut();

      expect(auth.isLoggedIn, isFalse);
      expect(repo.profile, isNotNull, reason: 'local profile never deleted');
      expect(repo.profile!.futureCloudUserId, _userA,
          reason: 'cloud ownership binding survives logout');
    });
  });

  group('A5.6 scenario 13 — bootstrap failure keeps auth authenticated', () {
    test('sign-in remains authenticated even when the seam work fails',
        () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.siteEngineer),
      );
      final gateway = _FakeRemoteGateway()
        ..fetchError = Exception('offline');
      final coordinator = _coordinator(repo, gateway);

      final auth = AuthProvider(
        gateway: FakeAuthGateway(signInResult: _sessionA),
        onAuthenticated: (session) async {
          await coordinator.bootstrap(userId: session.userId);
        },
      );

      await auth.signInWithGoogle();
      await _flushAsync();

      expect(auth.isLoggedIn, isTrue,
          reason: 'profile bootstrap failure must not unauthenticate');
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.error, isNull);
    });
  });

  group('A5.6 scenario 14 — legacy local profile (null binding) → no data loss',
      () {
    test('bootstraps and preserves every local field', () async {
      final created = DateTime(2024, 1, 1);
      final repo = _MemoryProfileRepository(
        profile: LocalUserProfile(
          anonymousInstallId: 'user_legacy_111',
          userType: CivilUserType.technicianSupervisor,
          baghdadArea: BaghdadArea.kadhimiya,
          name: 'باقي',
          createdAt: created,
        ),
      );
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      final saved = repo.profile!;
      expect(saved.anonymousInstallId, 'user_legacy_111');
      expect(saved.userType, CivilUserType.technicianSupervisor);
      expect(saved.baghdadArea, BaghdadArea.kadhimiya);
      expect(saved.name, 'باقي');
      expect(saved.futureCloudUserId, _userA);
      // Newer schema data is never lost by a legacy-field copy.
      expect(saved.schemaVersion, repo.profile!.schemaVersion);
    });
  });

  group('A5.6 scenario 15 — guest / no authenticated session → no cloud op', () {
    test('empty user id is skipped with no remote traffic', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.siteEngineer),
      );
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: '');

      expect(outcome, ProfileBootstrapOutcome.skippedGuest);
      expect(gateway.fetchCalls, 0);
      expect(gateway.createCalls, 0);
      expect(repo.profile!.futureCloudUserId, isNull);
      expect(repo.saveCalls, 0);
    });

    test('no local profile → no cloud profile is fabricated', () async {
      final repo = _MemoryProfileRepository();
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.noLocalProfile);
      expect(gateway.fetchCalls, 0);
      expect(gateway.createCalls, 0);
    });
  });

  group('A5.6 guard rails', () {
    test('local read failure → failure with no remote traffic', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.siteEngineer),
      )..loadError = Exception('storage broken');
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.failure);
      expect(gateway.fetchCalls, 0);
      expect(gateway.createCalls, 0);
    });

    test('local binding write failure → failure, cloud already created but '
        'local unmarked (retry-safe)', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.siteEngineer),
      )..saveError = Exception('disk full');
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.failure);
      expect(gateway.created.length, 1,
          reason: 'cloud row was created (cannot be rolled back deterministically)');
      expect(repo.profile!.futureCloudUserId, isNull);

      // Fix storage: retry now evaluates CASE B against the existing row and
      // completes the association without a duplicate.
      repo.saveError = null;
      final retry = await coordinator.bootstrap(userId: _userA);
      expect(retry, ProfileBootstrapOutcome.associated);
      expect(repo.profile!.futureCloudUserId, _userA);
      expect(gateway.createCalls, 1, reason: 'no duplicate insert on retry');
    });

    test('role-code mapping is complete and invertible for all user types',
        () {
      for (final type in CivilUserType.values) {
        final code = civilUserTypeToRoleCode(type);
        expect(roleCodeToCivilUserType(code), type,
            reason: 'round-trip failed for $type');
      }
      expect(roleCodeToCivilUserType('unknown_code'),
          CivilUserType.generalUser);
    });
  });

  group('A5.7 region compatibility — preference ≠ Directory area', () {
    test('1. local region present + cloud region NULL → compatible + local '
        'region preserved + cloud untouched', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          area: BaghdadArea.karrada,
        ),
      );
      final gateway = _FakeRemoteGateway()..cloudProfile = _engineerCloud;
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      expect(repo.profile!.futureCloudUserId, _userA);
      expect(repo.profile!.baghdadArea, BaghdadArea.karrada,
          reason: 'local area must be preserved, never written up');
      expect(gateway.cloudProfile!.preferredRegionId, isNull,
          reason: 'cloud region remains NULL (no invented preference write)');
      expect(gateway.createCalls, 0, reason: 'no remote mutation');
    });

    test('2. local region NULL + cloud region present → compatible + cloud '
        'untouched', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          area: BaghdadArea.unknown,
        ),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = _engineerCloudWithRegion;
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      expect(repo.profile!.futureCloudUserId, _userA);
      expect(gateway.cloudProfile!.preferredRegionId,
          '11111111-2222-3333-4444-555555555555',
          reason: 'cloud region preserved, never overwritten/cleared');
      expect(gateway.createCalls, 0, reason: 'no remote mutation');
    });

    test('3. local area + cloud region present → compatible, BOTH preserved '
        '(region never blocks association in A5.7)', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          area: BaghdadArea.karrada,
        ),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = _engineerCloudWithRegion;
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated,
          reason: 'physical local area ≠ cloud preference → never a conflict');
      expect(repo.profile!.futureCloudUserId, _userA);
      expect(repo.profile!.baghdadArea, BaghdadArea.karrada,
          reason: 'local profile unmutated');
      expect(gateway.cloudProfile!.preferredRegionId,
          '11111111-2222-3333-4444-555555555555',
          reason: 'cloud unmutated');
      expect(gateway.createCalls, 0, reason: 'no remote mutation');
    });

    test('4. same role/name, both regions meaningful → compatible, both '
        'preserved (regions are conceptually separate)', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          area: BaghdadArea.karrada,
          name: 'Ahmad',
        ),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = const CloudProfile(
          userId: _userA,
          roleCode: 'site_engineer',
          displayName: 'Ahmad',
          preferredRegionId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        );
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated,
          reason: 'role and name match; region fields never produce a '
              'conflict because local area is Directory geography, not a '
              'Region Preference');
      expect(repo.profile!.futureCloudUserId, _userA);
      expect(repo.profile!.baghdadArea, BaghdadArea.karrada,
          reason: 'local preserved');
      expect(gateway.cloudProfile!.preferredRegionId,
          'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          reason: 'cloud preserved (no write, no clear)');
    });

    test('5. NO cloud profile + local region exists → create with region NULL, '
        'local region preserved, binding only after confirmed create',
        () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.structuralEngineer,
          area: BaghdadArea.baya,
        ),
      );
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      final created = gateway.created.single;
      expect(created.preferredRegionId, isNull,
          reason: 'create never invents a region UUID');
      expect(created.regionPreferenceId, isNull,
          reason: 'create never invents a preference zone code');
      expect(repo.profile!.baghdadArea, BaghdadArea.baya,
          reason: 'local region stays safe locally');
      expect(repo.profile!.futureCloudUserId, _userA,
          reason: 'binding persisted after a confirmed create');
      expect(gateway.createCalls, 1);
    });

    test('6. retry with existing cloud region → deterministic association, '
        'no mutation on either side', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          area: BaghdadArea.karrada,
        ),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = _engineerCloudWithRegion;
      final coordinator = _coordinator(repo, gateway);

      final first = await coordinator.bootstrap(userId: _userA);
      final second = await coordinator.bootstrap(userId: _userA);

      expect(first, ProfileBootstrapOutcome.associated);
      expect(second, ProfileBootstrapOutcome.associated,
          reason: 'deterministic — region never blocks, both sides preserved');
      expect(repo.profile!.futureCloudUserId, _userA);
      expect(gateway.cloudProfile!.preferredRegionId,
          '11111111-2222-3333-4444-555555555555',
          reason: 'cloud untouched');
      expect(repo.profile!.baghdadArea, BaghdadArea.karrada,
          reason: 'local untouched');
      expect(gateway.createCalls, 0);
    });
  });

  group('A5.8 region preference bootstrap — safe cloud integration', () {
    const pref = RegionPreferenceCode.allIraq;
    const prefId = '10000000-0000-4000-8000-000000000106';

    test('1. create with resolved preference writes region_preference_id and '
        'binds only after a confirmed create', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          regionPreferenceCode: pref,
        ),
      );
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      final created = gateway.created.single;
      expect(created.regionPreferenceId, prefId,
          reason: 'canonical resolved id must reach the new cloud row');
      expect(created.preferredRegionId, isNull,
          reason: 'legacy preferred_region_id is never written');
      expect(repo.profile!.futureCloudUserId, _userA,
          reason: 'binding persisted only after confirmed create');
      expect(repo.profile!.regionPreferenceCode, pref,
          reason: 'local preference preserved');
    });

    test('2. existing cloud, same preference → associate safely, no mutation',
        () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          regionPreferenceCode: pref,
        ),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = const CloudProfile(
          userId: _userA,
          roleCode: 'site_engineer',
          regionPreferenceId: prefId,
        );
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      expect(repo.profile!.futureCloudUserId, _userA);
      expect(gateway.createCalls, 0, reason: 'no create');
      expect(gateway.updatePreferenceCalls, 0, reason: 'no fill needed');
      expect(gateway.cloudProfile!.regionPreferenceId, prefId);
    });

    test('3. cloud preference NULL + local preference → conditional '
        'single-column fill, then bind', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          regionPreferenceCode: pref,
        ),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = const CloudProfile(
          userId: _userA,
          roleCode: 'site_engineer',
        );
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      expect(gateway.updatePreferenceCalls, 1,
          reason: 'single-column safe fill attempted');
      expect(gateway.cloudProfile!.regionPreferenceId, prefId,
          reason: 'fill wrote the resolved id only');
      expect(gateway.cloudProfile!.roleCode, 'site_engineer',
          reason: 'other cloud columns untouched');
      expect(repo.profile!.futureCloudUserId, _userA,
          reason: 'bind after safe result');
      expect(gateway.createCalls, 0);
    });

    test('4. cloud preference DIFFERENT from local → profileConflict, no '
        'overwrite, no rebind', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          regionPreferenceCode: pref,
        ),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = const CloudProfile(
          userId: _userA,
          roleCode: 'site_engineer',
          regionPreferenceId: '10000000-0000-4000-8000-000000000104',
        );
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.profileConflict);
      expect(repo.profile!.futureCloudUserId, isNull,
          reason: 'no rebind on conflict');
      expect(gateway.updatePreferenceCalls, 0, reason: 'no overwrite');
      expect(gateway.cloudProfile!.regionPreferenceId,
          '10000000-0000-4000-8000-000000000104',
          reason: 'cloud preserved');
      expect(repo.profile!.regionPreferenceCode, pref,
          reason: 'local preserved');
    });

    test('5. FAIL-CLOSED: lookup failure + NO cloud profile → no create, no '
        'binding, retryable failure', () async {
      final preferenceGateway = _FakePreferenceGateway()
        ..resolveError = Exception('db down');
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          regionPreferenceCode: pref,
        ),
      );
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway,
          preferenceGateway: preferenceGateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.failure,
          reason: 'meaningful preference + unresolved canonical id → retryable '
              'failure');
      expect(gateway.createCalls, 0,
          reason: 'must NOT create a cloud row when the id cannot be proven');
      expect(repo.profile!.futureCloudUserId, isNull,
          reason: 'must NOT bind the local profile');
      expect(repo.profile!.regionPreferenceCode, pref,
          reason: 'local untouched');
    });

    test('6. FAIL-CLOSED: lookup failure + existing cloud profile → no '
        'association, no mutation, retryable failure', () async {
      final preferenceGateway = _FakePreferenceGateway()
        ..resolveError = Exception('offline');
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          regionPreferenceCode: pref,
        ),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = const CloudProfile(
          userId: _userA,
          roleCode: 'site_engineer',
        );
      final coordinator = _coordinator(repo, gateway,
          preferenceGateway: preferenceGateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.failure,
          reason: 'cannot prove the existing cloud preference is compatible; '
              'never bypass conflict detection');
      expect(repo.profile!.futureCloudUserId, isNull,
          reason: 'no binding without a proven-safe association');
      expect(gateway.createCalls, 0, reason: 'no remote create');
      expect(gateway.updatePreferenceCalls, 0, reason: 'no remote update');
      expect(gateway.cloudProfile!.regionPreferenceId, isNull,
          reason: 'cloud untouched');
      expect(repo.profile!.regionPreferenceCode, pref,
          reason: 'local untouched');
    });

    test('7. retry after a lookup failure succeeds → normal safe create '
        'semantics resume', () async {
      final preferenceGateway = _FakePreferenceGateway()
        ..resolveError = Exception('flaky');
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          regionPreferenceCode: pref,
        ),
      );
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway,
          preferenceGateway: preferenceGateway);

      final first = await coordinator.bootstrap(userId: _userA);
      expect(first, ProfileBootstrapOutcome.failure);
      expect(gateway.createCalls, 0);
      expect(repo.profile!.futureCloudUserId, isNull);

      preferenceGateway.resolveError = null;
      final second = await coordinator.bootstrap(userId: _userA);

      expect(second, ProfileBootstrapOutcome.associated);
      expect(gateway.createCalls, 1, reason: 'create after proven-safe id');
      final created = gateway.created.single;
      expect(created.regionPreferenceId, prefId);
      expect(repo.profile!.futureCloudUserId, _userA);
    });

    test('8. local preference NULL + existing cloud preference → associate '
        'and preserve cloud, no lookup required', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(
          userType: CivilUserType.siteEngineer,
          regionPreferenceCode: null,
        ),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = const CloudProfile(
          userId: _userA,
          roleCode: 'site_engineer',
          regionPreferenceId: prefId,
        );
      final preferenceGateway = _FakePreferenceGateway();
      final coordinator = _coordinator(repo, gateway,
          preferenceGateway: preferenceGateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated);
      expect(repo.profile!.futureCloudUserId, _userA);
      expect(gateway.cloudProfile!.regionPreferenceId, prefId,
          reason: 'cloud preference preserved, never unset');
      expect(preferenceGateway.resolveCalls, 0,
          reason: 'no lookup needed when local is NULL');
      expect(gateway.createCalls, 0);
      expect(gateway.updatePreferenceCalls, 0);
    });
  });
}