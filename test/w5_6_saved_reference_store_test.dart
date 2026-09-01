import 'dart:io';

import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/data/local/hive_helper.dart';
import 'package:civilpedia/features/saved/data/hive_saved_reference_store.dart';
import 'package:civilpedia/features/saved/domain/saved_item_reference.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'w5_6_saved_reference_store_box';

SavedItemReference _providerRef(String id, {DateTime? savedAt}) {
  return SavedItemReference(
    ownerDomain: SavedReferenceOwners.directory,
    entityType: SavedReferenceEntityTypes.provider,
    entityId: id,
    savedAt: savedAt ?? DateTime.utc(2026, 9, 1, 12, 0, 0),
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('civilpedia_w5_6_store');
    await HiveHelper.init(path: tempDir.path, boxName: _boxName);
  });

  setUp(() async {
    await Hive.box(_boxName).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('W5.6 structured SavedReferenceStore', () {
    test('1. empty structured store loads empty', () async {
      final store = const HiveSavedReferenceStore();
      expect(await store.loadAll(), isEmpty);
    });

    test('2. provider reference saves', () async {
      final store = const HiveSavedReferenceStore();
      await store.save(_providerRef('p-1'));
      final refs = await store.loadAll();
      expect(refs, hasLength(1));
      expect(refs.single.entityId, 'p-1');
    });

    test('3. persisted ownerDomain = directory', () async {
      final store = const HiveSavedReferenceStore();
      await store.save(_providerRef('p-1'));
      final refs = HiveHelper.getSavedReferences();
      expect((refs.single as Map)['ownerDomain'], SavedReferenceOwners.directory);
      expect((await store.loadAll()).single.ownerDomain, 'directory');
    });

    test('4. persisted entityType = provider', () async {
      final store = const HiveSavedReferenceStore();
      await store.save(_providerRef('p-1'));
      final refs = HiveHelper.getSavedReferences();
      expect((refs.single as Map)['entityType'], SavedReferenceEntityTypes.provider);
      expect((await store.loadAll()).single.entityType, 'provider');
    });

    test('5. persisted entityId = profile.id', () async {
      final store = const HiveSavedReferenceStore();
      await store.save(_providerRef('profile-42'));
      final refs = HiveHelper.getSavedReferences();
      expect((refs.single as Map)['entityId'], 'profile-42');
      expect((await store.loadAll()).single.entityId, 'profile-42');
    });

    test('6. savedAt persists as UTC', () async {
      final store = const HiveSavedReferenceStore();
      final when = DateTime.utc(2026, 9, 1, 13, 45, 30);
      await store.save(_providerRef('p-1', savedAt: when));
      final persisted = (HiveHelper.getSavedReferences()).single as Map;
      expect(persisted['savedAt'], when.toIso8601String());
      final loaded = (await store.loadAll()).single;
      expect(loaded.savedAt, when.toUtc());
    });

    test('7. deterministic id remains directory:provider:<id>', () async {
      final store = const HiveSavedReferenceStore();
      await store.save(_providerRef('p-123'));
      final loaded = (await store.loadAll()).single;
      expect(loaded.id, 'directory:provider:p-123');
      expect(await store.contains('directory:provider:p-123'), isTrue);
    });

    test('8. repeated save creates no duplicate', () async {
      final store = const HiveSavedReferenceStore();
      await store.save(_providerRef('p-1'));
      await store.save(_providerRef('p-1'));
      final refs = await store.loadAll();
      expect(refs, hasLength(1));
      expect((HiveHelper.getSavedReferences()), hasLength(1));
    });

    test('9. repeated save preserves original savedAt', () async {
      final store = const HiveSavedReferenceStore();
      final original = DateTime.utc(2026, 1, 1);
      await store.save(_providerRef('p-1', savedAt: original));
      await store.save(_providerRef('p-1', savedAt: DateTime.utc(2026, 9, 1)));
      final loaded = (await store.loadAll()).single;
      expect(loaded.savedAt, original.toUtc());
    });

    test('10. remove deletes the exact reference', () async {
      final store = const HiveSavedReferenceStore();
      await store.save(_providerRef('p-1'));
      await store.save(_providerRef('p-2'));
      await store.remove('directory:provider:p-1');
      final refs = await store.loadAll();
      expect(refs.map((r) => r.entityId), ['p-2']);
      expect(await store.contains('directory:provider:p-1'), isFalse);
    });

    test('11. repeated remove is a safe no-op', () async {
      final store = const HiveSavedReferenceStore();
      await store.save(_providerRef('p-1'));
      await store.remove('directory:provider:p-1');
      await store.remove('directory:provider:p-1');
      expect(await store.loadAll(), isEmpty);
      expect(await store.contains('directory:provider:p-1'), isFalse);
    });

    test('12. multiple refs preserve insertion order', () async {
      final store = const HiveSavedReferenceStore();
      await store.save(_providerRef('p-1'));
      await store.save(_providerRef('p-2'));
      await store.save(_providerRef('p-3'));
      final refs = await store.loadAll();
      expect(refs.map((r) => r.entityId).toList(), ['p-1', 'p-2', 'p-3']);
    });

    test('13. malformed persisted record does not crash and is skipped', () async {
      await Hive.box(_boxName).put(
        AppStorageKeys.savedReferences,
        <dynamic>[
          _providerRef('p-ok', savedAt: DateTime.utc(2026)).toJson(),
          <String, dynamic>{'ownerDomain': 'directory'}, // missing fields
          42,
          null,
          <String, dynamic>{
            'ownerDomain': SavedReferenceOwners.directory,
            'entityType': SavedReferenceEntityTypes.provider,
            'entityId': '',
          }, // empty entityId -> invalid
        ],
      );
      final store = const HiveSavedReferenceStore();
      final refs = await store.loadAll();
      expect(refs.map((r) => r.entityId), ['p-ok']);
    });

    test('14. legacy Saved keys are untouched by structured writes', () async {
      final box = Hive.box(_boxName);
      await box.put(AppStorageKeys.favorites, <String>['a-1']);
      await box.put(AppStorageKeys.encyclopediaFavorites, <String>['t-1']);
      const store = HiveSavedReferenceStore();
      await store.save(_providerRef('p-1'));
      expect(HiveHelper.getFavorites(), ['a-1']);
      expect(HiveHelper.getEncyclopediaFavorites(), ['t-1']);
      expect(await store.contains('directory:provider:p-1'), isTrue);
    });

    test('15. save works locally without any network', () async {
      const store = HiveSavedReferenceStore();
      await store.save(_providerRef('offline-p'));
      final refs = await store.loadAll();
      expect(refs.single.entityId, 'offline-p');
      expect(refs.single.id, 'directory:provider:offline-p');
    });
  });
}
