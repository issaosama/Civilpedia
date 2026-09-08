import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/features/profile/data/cloud_profile.dart';
import 'package:civilpedia/features/profile/data/personal_profile_bootstrap_coordinator.dart';
import 'package:civilpedia/features/profile/data/personal_profile_remote_gateway.dart';
import 'package:civilpedia/features/profile/data/profile_bootstrap_outcome.dart';
import 'package:civilpedia/features/profile/data/region_preference.dart';
import 'package:civilpedia/features/profile/data/region_preference_gateway.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';

const _userA = 'auth-users-uuid-A';
const _userB = 'auth-users-uuid-B';

String get _root => Directory.current.path;

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

/// Programmable [PersonalProfileRemoteGateway] fake: fetch + create, plus the
/// A5.8 single-column preference update (legacy `preferred_region_id` is never
/// written by this seam).
class _FakeRemoteGateway implements PersonalProfileRemoteGateway {
  CloudProfile? cloudProfile;
  Object? fetchError;
  Object? createError;

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

  @override
  Future<String?> resolvePreferenceIdByCode(String code) async {
    if (resolveError != null) throw resolveError!;
    return codes[code];
  }
}

LocalUserProfile _localProfile({
  CivilUserType userType = CivilUserType.siteEngineer,
  BaghdadArea area = BaghdadArea.unknown,
  String? futureCloudUserId,
}) {
  return LocalUserProfile(
    anonymousInstallId: 'user_1234_42',
    userType: userType,
    baghdadArea: area,
    futureCloudUserId: futureCloudUserId,
  );
}

PersonalProfileBootstrapCoordinator _coordinator(
  _MemoryProfileRepository repo,
  _FakeRemoteGateway gateway,
) {
  return PersonalProfileBootstrapCoordinator(
    localRepository: repo,
    remoteGateway: gateway,
    regionPreferenceGateway: _FakePreferenceGateway(),
  );
}

String _read(String relative) => File('$_root/$relative').readAsStringSync();

void main() {
  group('1. frozen six Region Preference codes are unique and deterministic',
      () {
    test('exactly the six frozen zones exist', () {
      expect(RegionPreferenceCode.all.length, 6);
      expect(RegionPreferenceCode.all.toSet().length, 6,
          reason: 'no duplicate code');
    });

    test('every code is non-empty, canonical, and known', () {
      for (final code in RegionPreferenceCode.all) {
        expect(code, isNotEmpty);
        expect(code.startsWith('IQ_PREF_'), isTrue);
        expect(RegionPreferenceCode.isKnown(code), isTrue);
      }
    });

    test('unknown/foreign codes are rejected deterministically', () {
      expect(RegionPreferenceCode.isKnown('IQ_PREF_NORTHWEST'), isFalse);
      expect(RegionPreferenceCode.isKnown('IQ_BAGHDAD_KARRADA'), isFalse);
      expect(RegionPreferenceCode.isKnown('IQ'), isFalse);
    });
  });

  group('2. Region Preference and physical public.regions are separate '
      'concepts', () {
    test('preference codes live in their own IQ_PREF_ namespace', () {
      for (final code in RegionPreferenceCode.all) {
        expect(code, startsWith('IQ_PREF_'));
      }
    });

    test('00013 creates a dedicated region_preferences table', () {
      final migration = _read('supabase/migrations/00013_region_preference_reference_data_correction.sql');
      expect(migration, contains('CREATE TABLE public.region_preferences'));
      expect(migration, contains('CREATE POLICY "region_preferences_select_all"'));
    });

    test('00013 never inserts preference zones into public.regions', () {
      final migration = _read('supabase/migrations/00013_region_preference_reference_data_correction.sql');
      expect(migration.contains('INSERT INTO public.regions'), isFalse,
          reason: 'preference zones must not be encoded as fake geoprows');
      expect(migration.contains('region_type'), isFalse);
    });

    test('preference code namespace is disjoint from geographic seed codes',
        () {
      final geographic = _read('supabase/migrations/00012_region_reference_data_foundation.sql');
      for (final code in RegionPreferenceCode.all) {
        expect(geographic.contains(code), isFalse,
            reason: '00012 (physical regions) must not contain $code');
      }
    });
  });

  group('3. entity_locations cannot use preference-zone identifiers', () {
    test('entity_locations.region_id FK references physical regions only', () {
      final migration = _read('supabase/migrations/00006_entity_relationships.sql');
      expect(migration, contains('REFERENCES public.regions(id)'));
    });

    test('00013 does not re-point entity_locations and profiles keeps two '
        'distinct region FKs', () {
      final migration = _read('supabase/migrations/00013_region_preference_reference_data_correction.sql');
      expect(migration.contains('ALTER TABLE public.entity_locations'), isFalse);
      expect(migration, contains('ADD COLUMN region_preference_id'));
      expect(migration, contains('REFERENCES public.region_preferences(id)'));
    });
  });

  group('4. BaghdadArea locality is NOT silently treated as a Region '
      'Preference', () {
    test('create with any local BaghdadArea persists NO region column',
        () async {
      for (final area in BaghdadArea.values) {
        final repo = _MemoryProfileRepository(profile: _localProfile(area: area));
        final gateway = _FakeRemoteGateway();
        final coordinator = _coordinator(repo, gateway);

        final outcome = await coordinator.bootstrap(userId: _userA);

        expect(outcome, ProfileBootstrapOutcome.associated,
            reason: '$area must never block association');
        expect(gateway.createCalls, 1);
        expect(gateway.cloudProfile!.preferredRegionId, isNull,
            reason: '$area must not be written as a physical region');
        expect(gateway.cloudProfile!.regionPreferenceId, isNull,
            reason: '$area must not be invented as a preference zone');
        expect(repo.profile!.baghdadArea, area,
            reason: 'local locality always preserved');
      }
    });

    test('no production code maps BaghdadArea to a preference code', () {
      final dataDir = '$_root/lib/features/profile/data';
      final preferenceSource =
          File('$dataDir/region_preference.dart').readAsStringSync();
      expect(preferenceSource.contains('baghdad_area.dart'), isFalse,
          reason: 'RegionPreferenceCode must be independent of BaghdadArea '
              '(no import of the Directory locality enum)');
      final mapperGone = File('$dataDir/region_preference_mapper.dart').existsSync();
      expect(mapperGone, isFalse,
          reason: 'the conflation mapper must not exist');
    });
  });

  group('5. All Iraq exists as an explicit canonical preference', () {
    test('IQ_PREF_ALL is present, unique, canonical', () {
      expect(RegionPreferenceCode.allIraq, 'IQ_PREF_ALL');
      expect(RegionPreferenceCode.isKnown(RegionPreferenceCode.allIraq), isTrue);
      expect(
        RegionPreferenceCode.all.where((c) => c == RegionPreferenceCode.allIraq).length,
        1,
      );
    });
  });

  group('6. North/Central/South exist independently of BaghdadArea', () {
    test('all three zone codes are present and distinct', () {
      expect(RegionPreferenceCode.north, 'IQ_PREF_NORTH');
      expect(RegionPreferenceCode.central, 'IQ_PREF_CENTRAL');
      expect(RegionPreferenceCode.south, 'IQ_PREF_SOUTH');
      expect({...RegionPreferenceCode.all}, containsAll([
        RegionPreferenceCode.north,
        RegionPreferenceCode.central,
        RegionPreferenceCode.south,
      ]));
      final zoneCodes = {
        RegionPreferenceCode.north,
        RegionPreferenceCode.central,
        RegionPreferenceCode.south,
      };
      expect(zoneCodes.length, 3, reason: 'no two zones share a code');
    });
  });

  group('7. legacy local value with no safe preference mapping', () {
    test('cloud preference remains unset and local value preserved', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(area: BaghdadArea.karrada),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = const CloudProfile(
          userId: _userA,
          roleCode: 'site_engineer',
        );
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.associated,
          reason: 'unmappable legacy data must never block authentication');
      expect(gateway.cloudProfile!.regionPreferenceId, isNull,
          reason: 'no mapping exists → cloud preference stays unset');
      expect(gateway.cloudProfile!.preferredRegionId, isNull);
      expect(repo.profile!.baghdadArea, BaghdadArea.karrada,
          reason: 'legacy local locality preserved locally');
      expect(gateway.createCalls, 0, reason: 'no remote mutation');
    });
  });

  group('8. known safe preference resolves through stable code', () {
    test('only known zone codes resolve to a seeded id', () async {
      final gateway = _FakePreferenceGateway();
      for (final code in RegionPreferenceCode.all) {
        final id = await gateway.resolvePreferenceIdByCode(code);
        expect(id, isNotNull, reason: '$code must resolve to a seeded id');
        expect(id!.trim(), isNotEmpty);
      }
      expect(await gateway.resolvePreferenceIdByCode('IQ_PREF_FAKE'), isNull);
      expect(await gateway.resolvePreferenceIdByCode('IQ_BAGHDAD_KARRADA'),
          isNull,
          reason: 'a physical locality is not a preference');
    });

    test('lookup failure throws so callers fail-safe (no invented id)', () async {
      final gateway = _FakePreferenceGateway()
        ..resolveError = Exception('db down');
      expect(
        () => gateway.resolvePreferenceIdByCode(RegionPreferenceCode.allIraq),
        throwsException,
      );
    });
  });

  group('9. no production Flutter code hardcodes preference UUIDs', () {
    test('no UUID literal exists in production region/preference code', () {
      final uuid = RegExp(
        r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
        caseSensitive: false,
      );
      final dataDir = '$_root/lib/features/profile/data';
      final sources = <String>[
        for (final entry in Directory(dataDir).listSync())
          if (entry is File && entry.path.endsWith('.dart')) entry.path,
        '$_root/lib/core/di/app_dependencies.dart',
        '$_root/lib/main.dart',
      ];
      expect(sources.length, greaterThanOrEqualTo(8));
      for (final path in sources) {
        final content = File(path).readAsStringSync();
        expect(uuid.hasMatch(content), isFalse,
            reason: 'preference UUIDs are database implementation details and '
                'must never appear in Flutter production code ($path)');
      }
    });
  });

  group('10. A5.5/A5.6 ownership protections remain green', () {
    test('different bound user → FAIL CLOSED, no remote traffic', () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(futureCloudUserId: _userA),
      );
      final gateway = _FakeRemoteGateway();
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userB);

      expect(outcome, ProfileBootstrapOutcome.differentUserBlocked);
      expect(gateway.fetchCalls, 0);
      expect(gateway.createCalls, 0);
      expect(repo.profile!.futureCloudUserId, _userA);
    });

    test('role/name conflicts still produce profileConflict (both preserved)',
        () async {
      final repo = _MemoryProfileRepository(
        profile: _localProfile(userType: CivilUserType.consultantEngineer),
      );
      final gateway = _FakeRemoteGateway()
        ..cloudProfile = const CloudProfile(
          userId: _userA,
          roleCode: 'site_engineer',
        );
      final coordinator = _coordinator(repo, gateway);

      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.profileConflict);
      expect(repo.profile!.futureCloudUserId, isNull);
      expect(gateway.cloudProfile!.roleCode, 'site_engineer',
          reason: 'cloud untouched');
    });
  });

  group('11. existing 00012 geographic seed remains valid and additive', () {
    test('00013 is additive: no DROP/DELETE/TRUNCATE against regions/profiles',
        () {
      final migration = _read('supabase/migrations/00013_region_preference_reference_data_correction.sql');
      final destructive =
          RegExp(r'\bDROP\s+(TABLE|COLUMN|VIEW|FUNCTION|POLICY|TRIGGER|INDEX|SCHEMA|DATABASE|TYPE)\b|\bTRUNCATE\b|\bDELETE\s+FROM\b');
      expect(destructive.hasMatch(migration), isFalse,
          reason: '00013 must stay non-destructive whitelist-additive only');
    });

    test('00012 keeps the geographic code namespace untouched', () {
      final migration = _read('supabase/migrations/00012_region_reference_data_foundation.sql');
      expect(migration, contains('IQ_BAGHDAD_KARRADA'));
      expect(migration, contains('region_type'));
      expect(migration.contains('IQ_PREF_'), isFalse,
          reason: 'geographic migration must not contain preference codes');
    });
  });
}