import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/features/directory/data/sb_profiles_directory_repository.dart';
import 'package:civilpedia/features/directory/domain/directory_data_version.dart';
import 'package:civilpedia/features/directory/domain/directory_repository.dart';
import 'package:civilpedia/features/profile/data/local_service_business_repository.dart';
import 'package:civilpedia/features/profile/data/service_business_data_source.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/features/profile/domain/service_business_repository.dart';
import 'package:civilpedia/routes/app_routes.dart';

const _kKey = 'sb_profiles';

/// Raw legacy (V0) JSON serialization of a ServiceBusinessProfile, matching
/// the pre-W5.1 persisted shape byte-for-byte.
Map<String, dynamic> _legacyJson({
  String id = 'sb-1',
  String verification = 'unverified',
  String type = 'contractor',
  String baghdadArea = 'karrada',
  String? planType,
  bool featured = false,
  bool foundingPartner = false,
}) {
  return {
    'id': id,
    'name': 'Contractor $id',
    'type': type,
    'categories': <String>['general'],
    'subCategories': <String>['residential'],
    'baghdadArea': baghdadArea,
    'address': 'Address $id',
    'phones': ['0770$id'],
    'whatsapp': '0780$id',
    'description': 'Desc $id',
    'verificationStatus': verification,
    'featured': featured,
    'foundingPartner': foundingPartner,
    'createdAt': '2020-01-01T00:00:00.000',
    'updatedAt': '2021-01-01T00:00:00.000',
    'futureOwnerUserId': null,
    'planType': planType,
    'schemaVersion': 1,
  };
}

String _encodeLegacy(List<Map<String, dynamic>> rows) => jsonEncode(rows);

ServiceBusinessRepository _legacyRepo() =>
    LocalServiceBusinessRepository(ServiceBusinessDataSource());

DirectoryRepository _directoryRepo() => SbProfilesDirectoryRepository(
      businessRepo: _legacyRepo(),
    );

ServiceBusinessProfile _richProfile() {
  return ServiceBusinessProfile(
    id: 'sb-r1',
    name: 'Rich',
    type: BusinessType.supplier,
    categories: const ['steel'],
    subCategories: const ['rebar'],
    baghdadArea: BaghdadArea.karrada,
    address: 'R1 street',
    phones: const ['077000'],
    whatsapp: '078000',
    description: 'Rich desc',
    verificationStatus: VerificationStatus.verified,
    featured: true,
    foundingPartner: true,
    createdAt: DateTime.parse('2020-02-02T00:00:00.000'),
    updatedAt: DateTime.parse('2021-02-02T00:00:00.000'),
    futureOwnerUserId: 'u1',
    planType: 'pro',
    schemaVersion: 1,
  );
}

/// Proves the Directory layer never reaches SharedPreferences directly
/// (only the legacy data source may): no shared_preferences import and no
/// low-level getInstance/jsonEncode/jsonDecode call sites.
bool _directorySourceHasNoDirectPrefsAccess() {
  final source = File(
    'lib/features/directory/data/sb_profiles_directory_repository.dart',
  ).readAsStringSync();
  return !source.contains(
          "import 'package:shared_preferences/shared_preferences.dart'")
      && !source.contains('getInstance(')
      && !source.contains('jsonDecode(')
      && !source.contains('jsonEncode(');
}

/// Proves no new physical Directory persistence key is introduced.
bool _noNewDirectoryKey() {
  final keysSource = File(
    'lib/core/storage/app_storage_keys.dart',
  ).readAsStringSync();
  return !keysSource.contains('directory_entities')
      && !keysSource.contains('directory_profiles')
      && !keysSource.contains('sb_profiles_v1')
      && !keysSource.contains('directory_');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('W5.1 STORAGE COMPATIBILITY', () {
    test('1. AppStorageKeys.sbProfiles remains exactly sb_profiles', () {
      expect(AppStorageKeys.sbProfiles, _kKey);
    });

    test('2. add no new Directory persistence key', () {
      expect(_noNewDirectoryKey(), isTrue);
    });

    test('3. legacy raw V0 array is readable through DirectoryRepository',
        () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([
          _legacyJson(id: 'sb-1', verification: 'verified'),
          _legacyJson(id: 'sb-2', verification: 'pending'),
        ]),
      });
      final repo = _directoryRepo();
      final all = await repo.loadAll();
      expect(all, hasLength(2));
      expect(all[0].id, 'sb-1');
      expect(all[0].verificationStatus, VerificationStatus.verified);
      expect(all[1].id, 'sb-2');
      expect(all[1].verificationStatus, VerificationStatus.pending);
    });

    test('4. reading legacy V0 causes no storage rewrite', () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([_legacyJson(id: 'sb-1')]),
      });
      final repo = _directoryRepo();
      await repo.loadAll();
      await repo.loadById('sb-1');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_kKey),
          _encodeLegacy([_legacyJson(id: 'sb-1')]));
    });
  });

  group('W5.1 WRAPPER', () {
    test('5. loadAll mirrors businessRepo loadAll', () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([_legacyJson(id: 'a'), _legacyJson(id: 'b')]),
      });
      final legacy = _legacyRepo();
      final directory = _directoryRepo();
      expect((await directory.loadAll()).length,
          (await legacy.loadAll()).length);
    });

    test('6. loadById mirrors legacy behavior', () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([_legacyJson(id: 'a')]),
      });
      final directory = _directoryRepo();
      expect((await directory.loadById('a'))?.id, 'a');
      expect(await directory.loadById('missing'), isNull);
    });

    test('7. save delegates correctly', () async {
      final directory = _directoryRepo();
      await directory.save(_richProfile());
      final all = await directory.loadAll();
      expect(all, hasLength(1));
      expect(all.single.id, 'sb-r1');
    });

    test('8. delete delegates correctly', () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([_legacyJson(id: 'a'), _legacyJson(id: 'b')]),
      });
      final directory = _directoryRepo();
      await directory.delete('a');
      expect((await directory.loadAll()).map((p) => p.id), ['b']);
    });

    test('9. clearAll delegates correctly', () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([_legacyJson(id: 'a')]),
      });
      final directory = _directoryRepo();
      await directory.clearAll();
      expect(await directory.loadAll(), isEmpty);
    });

    test('10. Directory layer does not access SharedPreferences directly',
        () {
      expect(_directorySourceHasNoDirectPrefsAccess(), isTrue);
    });

    test('11. Directory layer does not duplicate sb_profiles serialization',
        () {
      expect(_directorySourceHasNoDirectPrefsAccess(), isTrue);
    });
  });

  group('W5.1 CROSS-COMPAT', () {
    test('12. save via Directory readable via legacy businessRepo', () async {
      final directory = _directoryRepo();
      final legacy = _legacyRepo();
      await directory.save(_richProfile());
      final viaLegacy = await legacy.loadAll();
      expect(viaLegacy, hasLength(1));
      expect(viaLegacy.single.id, 'sb-r1');
    });

    test('13. save via legacy businessRepo readable via Directory', () async {
      final directory = _directoryRepo();
      final legacy = _legacyRepo();
      await legacy.save(_richProfile());
      final viaDirectory = await directory.loadById('sb-r1');
      expect(viaDirectory, isNotNull);
    });

    test('14. delete via Directory reflected through legacy repository',
        () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([_legacyJson(id: 'a'), _legacyJson(id: 'b')]),
      });
      final directory = _directoryRepo();
      final legacy = _legacyRepo();
      await directory.delete('a');
      expect((await legacy.loadAll()).map((p) => p.id), ['b']);
    });

    test('15. clear via Directory reflected through legacy repository',
        () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([_legacyJson(id: 'a')]),
      });
      final directory = _directoryRepo();
      final legacy = _legacyRepo();
      await directory.clearAll();
      expect(await legacy.loadAll(), isEmpty);
    });
  });

  group('W5.1 VERIFICATION', () {
    test('16. all five states round-trip through Directory', () async {
      final directory = _directoryRepo();
      for (final v in VerificationStatus.values) {
        final p = ServiceBusinessProfile(
          id: 'v-${v.name}',
          name: 'n',
          type: BusinessType.other,
          verificationStatus: v,
        );
        await directory.save(p);
      }
      final all = await directory.loadAll();
      final statuses = all.map((p) => p.verificationStatus).toSet();
      expect(statuses, VerificationStatus.values.toSet());
    });

    test('17. rejected never becomes suspended', () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([_legacyJson(id: 'r', verification: 'rejected')]),
      });
      final loaded = await _directoryRepo().loadById('r');
      expect(loaded?.verificationStatus.name, 'rejected');
      expect(loaded?.verificationStatus, isNot(VerificationStatus.suspended));
    });

    test('18. suspended never becomes rejected', () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([_legacyJson(id: 's', verification: 'suspended')]),
      });
      final loaded = await _directoryRepo().loadById('s');
      expect(loaded?.verificationStatus.name, 'suspended');
      expect(loaded?.verificationStatus, isNot(VerificationStatus.rejected));
    });
  });

  group('W5.1 ENTITY COMPAT', () {
    test('19. BusinessType values preserved', () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([_legacyJson(id: 't', type: 'equipment_owner')]),
      });
      final loaded = await _directoryRepo().loadById('t');
      expect(loaded?.type, BusinessType.equipmentOwner);
    });

    test('20. BaghdadArea values preserved', () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([_legacyJson(id: 'b', baghdadArea: 'karrada')]),
      });
      final loaded = await _directoryRepo().loadById('b');
      expect(loaded?.baghdadArea, BaghdadArea.karrada);
    });

    test('21. legacy fields preserved through a save+reload', () async {
      final directory = _directoryRepo();
      await directory.save(_richProfile());
      final loaded = await directory.loadById('sb-r1');
      expect(loaded?.planType, 'pro');
      expect(loaded?.featured, isTrue);
      expect(loaded?.foundingPartner, isTrue);
      expect(loaded?.schemaVersion, 1);
      expect(loaded?.futureOwnerUserId, 'u1');
    });

    test('22. no organic filtering/gating introduced on read', () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([_legacyJson(id: 'x', planType: 'pro')]),
      });
      // Non-core fields must not cause the record to be dropped or hidden.
      final all = await _directoryRepo().loadAll();
      expect(all, hasLength(1));
    });
  });

  group('W5.1 VERSION AWARENESS', () {
    test('23. legacy source recognized internally as v0', () {
      final repo = SbProfilesDirectoryRepository(businessRepo: _legacyRepo());
      expect(repo.sourceVersion, DirectoryDataVersion.v0);
    });

    test('24. no persisted envelope conversion on read', () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([_legacyJson(id: 'a')]),
      });
      await _directoryRepo().loadAll();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_kKey),
          _encodeLegacy([_legacyJson(id: 'a')]));
    });

    test('25. no new schema-version sidecar key written', () async {
      final directory = _directoryRepo();
      await directory.save(_richProfile());
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys()) {
        expect(k, _kKey);
      }
    });
  });

  group('W5.1 DI', () {
    test('26. canonical directoryRepo resolves and wraps businessRepo truth',
        () async {
      SharedPreferences.setMockInitialValues({
        _kKey: _encodeLegacy([_legacyJson(id: 'di')]),
      });
      final directory = SbProfilesDirectoryRepository(
        businessRepo: _legacyRepo(),
      );
      final all = await directory.loadAll();
      expect(all, hasLength(1));
      expect(all.single.id, 'di');
    });

    test('27. businessRepo remains a distinct compatible type', () {
      final legacy = _legacyRepo();
      expect(legacy, isA<ServiceBusinessRepository>());
      expect(legacy, isA<LocalServiceBusinessRepository>());
    });
  });

  group('W5.1 ARCHITECTURE', () {
    test('28. no Directory UI introduced', () {
      expect(File('lib/features/directory/presentation').existsSync(), isFalse);
      expect(File('lib/features/directory/ui').existsSync(), isFalse);
    });

    test('29. shell destinations = W6.3 target shell (5 routes, /directory)', () {
      final routes = kShellDestinations.map((d) => d.route).toList();
      expect(routes, [
        AppRoutes.home,
        AppRoutes.encyclopedia,
        AppRoutes.tools,
        AppRoutes.projects,
        AppRoutes.directory,
      ]);
      expect(routes.any((r) => r.endsWith('directory')), isTrue);
      expect(kShellDestinations.length, 5);
    });

    test('30. no global-search / search edits (search constant unchanged)',
        () {
      expect(AppRoutes.search, '/search');
    });

    test('31. no Saved/User storage key or reference additions', () {
      final keys = File(
        'lib/core/storage/app_storage_keys.dart',
      ).readAsStringSync();
      expect(keys.contains('directoryEntities'), isFalse);
      expect(keys.contains('savedProvider'), isFalse);
    });

    test('32. no monetization behavior introduced in Directory data layer', () {
      final repo = File(
        'lib/features/directory/data/sb_profiles_directory_repository.dart',
      ).readAsStringSync();
      expect(repo.contains('featured'), isFalse);
      expect(repo.contains('planType'), isFalse);
      expect(repo.contains('foundingPartner'), isFalse);
    });
  });
}
