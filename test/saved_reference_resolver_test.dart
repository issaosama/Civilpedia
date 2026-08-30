import 'dart:io';

import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/data/local/hive_helper.dart';
import 'package:civilpedia/features/saved/data/hive_saved_reference_resolver.dart';
import 'package:civilpedia/features/saved/domain/saved_item_reference.dart';
import 'package:civilpedia/features/saved/domain/saved_reference_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'w3_1_saved_reference_test_box';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('civilpedia_w3_1_test');
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

  group('SavedItemReference', () {
    test('id is a deterministic composite of ownerDomain/entityType/entityId',
        () {
      const ref = SavedItemReference(
        ownerDomain: SavedReferenceOwners.knowledge,
        entityType: SavedReferenceEntityTypes.article,
        entityId: 'a-1',
      );
      expect(ref.id, 'knowledge:article:a-1');
    });

    test('same entityId in different namespaces produces different ids', () {
      const topic = SavedItemReference(
        ownerDomain: SavedReferenceOwners.knowledge,
        entityType: SavedReferenceEntityTypes.topic,
        entityId: 'shared',
      );
      const article = SavedItemReference(
        ownerDomain: SavedReferenceOwners.knowledge,
        entityType: SavedReferenceEntityTypes.article,
        entityId: 'shared',
      );
      expect(topic.id, isNot(article.id));
    });

    test('legacy-derived references carry a null savedAt (no fabrication)',
        () {
      const ref = SavedItemReference(
        ownerDomain: SavedReferenceOwners.knowledge,
        entityType: SavedReferenceEntityTypes.topic,
        entityId: 't-1',
      );
      expect(ref.savedAt, isNull);
    });
  });

  group('SavedReferenceResolver.merge (pure)', () {
    test('every legacy favorites id is readable as an article reference', () {
      final refs = SavedReferenceResolver.merge(
        encyclopediaTopicIds: const [],
        legacyArticleIds: const ['a-1', 'a-2', 'a-3'],
      );

      expect(refs, hasLength(3));
      for (var i = 0; i < refs.length; i++) {
        expect(refs[i].ownerDomain, SavedReferenceOwners.knowledge);
        expect(refs[i].entityType, SavedReferenceEntityTypes.article);
        expect(refs[i].entityId, 'a-${i + 1}');
        expect(refs[i].savedAt, isNull);
        expect(refs[i].id, 'knowledge:article:a-${i + 1}');
      }
    });

    test('every encyclopedia favorites id is readable as a topic reference',
        () {
      final refs = SavedReferenceResolver.merge(
        encyclopediaTopicIds: const ['t-1', 't-2'],
        legacyArticleIds: const [],
      );

      expect(refs, hasLength(2));
      for (var i = 0; i < refs.length; i++) {
        expect(refs[i].ownerDomain, SavedReferenceOwners.knowledge);
        expect(refs[i].entityType, SavedReferenceEntityTypes.topic);
        expect(refs[i].entityId, 't-${i + 1}');
        expect(refs[i].savedAt, isNull);
        expect(refs[i].id, 'knowledge:topic:t-${i + 1}');
      }
    });

    test('combined read merges both stores into a single canonical list', () {
      final refs = SavedReferenceResolver.merge(
        encyclopediaTopicIds: const ['t-2', 't-1'],
        legacyArticleIds: const ['a-1', 'a-0'],
      );

      expect(
        refs.map((r) => '<${r.entityType}:${r.entityId}>').toList(),
        ['<topic:t-2>', '<topic:t-1>', '<article:a-1>', '<article:a-0>'],
      );
    });

    test('same raw id in both stores stays distinct in the merge', () {
      final refs = SavedReferenceResolver.merge(
        encyclopediaTopicIds: const ['shared', 't-1'],
        legacyArticleIds: const ['a-1', 'shared'],
      );

      final topics = refs
          .where((r) => r.entityType == SavedReferenceEntityTypes.topic)
          .toList();
      final articles = refs
          .where((r) => r.entityType == SavedReferenceEntityTypes.article)
          .toList();

      expect(topics.where((r) => r.entityId == 'shared'), hasLength(1));
      expect(articles.where((r) => r.entityId == 'shared'), hasLength(1));
      expect(
        topics.firstWhere((r) => r.entityId == 'shared').id,
        isNot(articles.firstWhere((r) => r.entityId == 'shared').id),
      );
    });

    test('merge is deterministic and never mutates its inputs', () {
      const topicIds = ['t-3', 't-2', 't-1'];
      const articleIds = ['a-1', 'a-2'];

      final first = SavedReferenceResolver.merge(
        encyclopediaTopicIds: topicIds,
        legacyArticleIds: articleIds,
      );
      final second = SavedReferenceResolver.merge(
        encyclopediaTopicIds: topicIds,
        legacyArticleIds: articleIds,
      );

      expect(first, second);
      expect(topicIds, ['t-3', 't-2', 't-1']);
      expect(articleIds, ['a-1', 'a-2']);
    });

    test('unusual but valid string ids are preserved exactly', () {
      final refs = SavedReferenceResolver.merge(
        encyclopediaTopicIds: const ['a:b', ' 001 ', ''],
        legacyArticleIds: const [],
      );

      expect(refs.map((r) => r.entityId), ['a:b', ' 001 ', '']);
      expect(refs[0].id, 'knowledge:topic:a:b');
    });
  });

  group('SavedReferenceResolver read-through', () {
    test('resolve reads both injected sources and returns the canonical merge',
        () async {
      final resolver = SavedReferenceResolver(
        encyclopediaTopicIds: () async => const ['t-9'],
        legacyArticleIds: () async => const ['a-9'],
      );

      final refs = await resolver.resolve();

      expect(refs, hasLength(2));
      expect(refs[0].entityType, SavedReferenceEntityTypes.topic);
      expect(refs[0].entityId, 't-9');
      expect(refs[1].entityType, SavedReferenceEntityTypes.article);
      expect(refs[1].entityId, 'a-9');
    });

    test('result order is deterministic regardless of async completion timing',
        () async {
      final resolver = SavedReferenceResolver(
        encyclopediaTopicIds: () async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return const ['t-2', 't-1'];
        },
        legacyArticleIds: () async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return const ['a-1'];
        },
      );

      final first = await resolver.resolve();
      final second = await resolver.resolve();

      expect(
        first.map((r) => r.entityId).toList(),
        ['t-2', 't-1', 'a-1'],
      );
      expect(first, second);
    });

    test('resolve never writes storage', () async {
      var writes = 0;
      final resolver = SavedReferenceResolver(
        encyclopediaTopicIds: () async {
          writes++;
          return const ['t-1'];
        },
        legacyArticleIds: () async {
          writes++;
          return const ['a-1'];
        },
      );

      await resolver.resolve();

      expect(writes, 2);
    });
  });

  group('Hive-backed integration (hiveSavedReferenceResolver)', () {
    test(
      'resolve leaves persisted values and keys untouched and creates no new '
      'key',
      () async {
        final box = Hive.box(_boxName);
        await box.put(AppStorageKeys.favorites, <String>['a-1', 'a-2']);
        await box.put(
          AppStorageKeys.encyclopediaFavorites,
          <String>['t-2', 't-1'],
        );
        await box.put(AppStorageKeys.downloads, <String>['dl-1']);
        await box.put(
          AppStorageKeys.offlineArticle('dl-1'),
          <String, dynamic>{'id': 'dl-1'},
        );

        final before = Map<dynamic, dynamic>.of(box.toMap());
        final refs = await hiveSavedReferenceResolver().resolve();
        final after = Map<dynamic, dynamic>.of(box.toMap());

        expect(
          refs.map((r) => r.id).toList(),
          [
            'knowledge:topic:t-2',
            'knowledge:topic:t-1',
            'knowledge:article:a-1',
            'knowledge:article:a-2',
          ],
        );
        expect(after.keys.toSet(), before.keys.toSet());
        expect(
          after.keys.toSet(),
          <dynamic>{
            AppStorageKeys.favorites,
            AppStorageKeys.encyclopediaFavorites,
            AppStorageKeys.downloads,
            AppStorageKeys.offlineArticle('dl-1'),
          },
        );
        expect(after, equals(before));
      },
    );

    test('legacy favorites ids are readable through the Hive-backed resolver',
        () async {
      final box = Hive.box(_boxName);
      await box.put(AppStorageKeys.favorites, <String>['a-1', 'a-3']);

      final refs = await hiveSavedReferenceResolver().resolve();

      expect(
        refs.map((r) => r.id).toList(),
        ['knowledge:article:a-1', 'knowledge:article:a-3'],
      );
    });

    test(
      'malformed persisted entries are filtered safely and resolve never '
      'crashes',
      () async {
        final box = Hive.box(_boxName);
        await box.put(
          AppStorageKeys.encyclopediaFavorites,
          <dynamic>['t-1', 42, 't-2', null],
        );
        await box.put(
          AppStorageKeys.favorites,
          <dynamic>['a-1', 7, 'a-2', false],
        );

        final refs = await hiveSavedReferenceResolver().resolve();

        expect(
          refs.map((r) => r.id).toList(),
          [
            'knowledge:topic:t-1',
            'knowledge:topic:t-2',
            'knowledge:article:a-1',
            'knowledge:article:a-2',
          ],
        );
      },
    );

    test('downloads and offline payloads remain readable and untouched',
        () async {
      final box = Hive.box(_boxName);
      await box.put(AppStorageKeys.favorites, <String>['a-1']);
      await box.put(AppStorageKeys.encyclopediaFavorites, <String>['t-1']);
      await box.put(AppStorageKeys.downloads, <String>['dl-1', 'dl-2']);
      const offlinePayload = <String, dynamic>{'id': 'dl-1'};
      await box.put(AppStorageKeys.offlineArticle('dl-1'), offlinePayload);
      final offlineBefore = box.get(AppStorageKeys.offlineArticle('dl-1'));

      final refs = await hiveSavedReferenceResolver().resolve();

      expect(refs.map((r) => r.entityId).toList(), ['t-1', 'a-1']);
      expect(HiveHelper.getDownloads(), ['dl-1', 'dl-2']);
      expect(HiveHelper.isDownloaded('dl-1'), isTrue);
      expect(HiveHelper.isDownloaded('dl-2'), isTrue);
      expect(box.get(AppStorageKeys.offlineArticle('dl-1')), offlineBefore);
      expect(offlineBefore, equals(offlinePayload));
    });
  });
}