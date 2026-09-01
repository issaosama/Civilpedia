import 'dart:io';

import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/data/local/hive_helper.dart';
import 'package:civilpedia/features/saved/data/hive_saved_reference_resolver.dart';
import 'package:civilpedia/features/saved/data/hive_saved_reference_store.dart';
import 'package:civilpedia/features/saved/domain/saved_item_reference.dart';
import 'package:civilpedia/features/saved/domain/saved_reference_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'w5_6_resolver_structured_box';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('civilpedia_w5_6_resolver');
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

  final providerRef = SavedItemReference(
    ownerDomain: SavedReferenceOwners.directory,
    entityType: SavedReferenceEntityTypes.provider,
    entityId: 'p-1',
    savedAt: DateTime.utc(2026, 8, 1),
  );

  group('W5.6 resolver — legacy unchanged', () {
    test('16. existing article legacy refs still resolve unchanged', () async {
      final resolver = SavedReferenceResolver(
        encyclopediaTopicIds: () async => const [],
        legacyArticleIds: () async => const ['a-1', 'a-2'],
      );
      final refs = await resolver.resolve();
      expect(
        refs.map((r) => r.id).toList(),
        ['knowledge:article:a-1', 'knowledge:article:a-2'],
      );
    });

    test('17. existing topic legacy refs still resolve unchanged', () async {
      final resolver = SavedReferenceResolver(
        encyclopediaTopicIds: () async => const ['t-2', 't-1'],
        legacyArticleIds: () async => const [],
      );
      final refs = await resolver.resolve();
      expect(
        refs.map((r) => r.id).toList(),
        ['knowledge:topic:t-2', 'knowledge:topic:t-1'],
      );
    });

    test('18. structured directory/provider ref is included', () async {
      final resolver = SavedReferenceResolver(
        encyclopediaTopicIds: () async => const [],
        legacyArticleIds: () async => const [],
        structuredReferences: () async => [providerRef],
      );
      final refs = await resolver.resolve();
      expect(refs, contains(providerRef));
      expect(refs.single.ownerDomain, SavedReferenceOwners.directory);
      expect(refs.single.entityType, SavedReferenceEntityTypes.provider);
      expect(refs.single.entityId, 'p-1');
    });

    test('19. legacy + structured merge correctly in fixed order', () async {
      final resolver = SavedReferenceResolver(
        encyclopediaTopicIds: () async => const ['t-1'],
        legacyArticleIds: () async => const ['a-1'],
        structuredReferences: () async => [providerRef],
      );
      final refs = await resolver.resolve();
      expect(
        refs.map((r) => r.id).toList(),
        ['knowledge:topic:t-1', 'knowledge:article:a-1', providerRef.id],
      );
    });

    test('20. deterministic id prevents structured duplicates', () {
      final merged = SavedReferenceResolver.merge(
        encyclopediaTopicIds: const [],
        legacyArticleIds: const [],
        structuredReferences: [providerRef, providerRef],
      );
      expect(merged, hasLength(1));
    });

    test('21. legacy savedAt remains null', () async {
      final refs = await SavedReferenceResolver(
        encyclopediaTopicIds: () async => const ['t-1'],
        legacyArticleIds: () async => const ['a-1'],
      ).resolve();
      expect(refs.every((r) => r.savedAt == null), isTrue);
    });

    test('22. structured savedAt remains its actual value', () async {
      final refs = await SavedReferenceResolver(
        encyclopediaTopicIds: () async => const [],
        legacyArticleIds: () async => const [],
        structuredReferences: () async => [providerRef],
      ).resolve();
      expect(refs.single.savedAt, DateTime.utc(2026, 8, 1));
    });

    test('23. resolver does not write or migrate legacy values', () async {
      final box = Hive.box(_boxName);
      await box.put(AppStorageKeys.favorites, <String>['a-1']);
      await box.put(AppStorageKeys.encyclopediaFavorites, <String>['t-1']);
      await const HiveSavedReferenceStore().save(providerRef);

      final before = Map<dynamic, dynamic>.of(box.toMap());
      final refs = await hiveSavedReferenceResolver().resolve();
      final after = Map<dynamic, dynamic>.of(box.toMap());

      expect(
        refs.map((r) => r.id).toList(),
        ['knowledge:topic:t-1', 'knowledge:article:a-1', providerRef.id],
      );
      expect(after, equals(before));
      expect(HiveHelper.getFavorites(), ['a-1']);
      expect(HiveHelper.getEncyclopediaFavorites(), ['t-1']);
      expect(
        after.keys.toSet(),
        <dynamic>{AppStorageKeys.favorites, AppStorageKeys.encyclopediaFavorites, AppStorageKeys.savedReferences},
      );
    });
  });
}
