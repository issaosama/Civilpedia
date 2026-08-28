import 'dart:io';

import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/data/local/hive_helper.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_favorites_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/topic_list_card.dart';
import 'package:civilpedia/features/saved/presentation/saved_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

const _boxName = 'favorites_test_box';

EngineeringTopic _topic(String id, String title) => EngineeringTopic(
  id: id,
  titleAr: title,
  categoryId: 'cat1',
  summary: 'ملخص $title',
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
  tags: const ['concrete'],
  keyTopics: const ['خرسانة'],
);

class _InMemoryEncyclopediaFavoritesStore
    implements EncyclopediaFavoritesStore {
  final List<String> _ids = [];

  @override
  Future<List<String>> read() async => List.of(_ids);

  @override
  Future<void> add(String topicId) async {
    if (!_ids.contains(topicId)) _ids.insert(0, topicId);
  }

  @override
  Future<void> remove(String topicId) async {
    _ids.remove(topicId);
  }
}

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  final List<EngineeringTopic> topics;
  _FakeEncyclopediaRepository(this.topics);

  @override
  Future<EngineeringTopic?> getTopicById(String id) async {
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  @override
  Future<List<EngineeringTopic>> getAllTopics() async => topics;

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async =>
      topics.where((t) => t.categoryId == categoryId).toList();

  @override
  Future<Map<String, CategoryInfo>> getCategories() async =>
      const <String, CategoryInfo>{};

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async =>
      const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async => const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => topics;
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('civilpedia_fav_test');
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

  group('EncyclopediaFavoritesProvider persistence', () {
    test('save adds id and isFavorite reflects it', () async {
      final provider = EncyclopediaFavoritesProvider();
      await provider.load();
      await provider.save('topic-1');

      expect(provider.isFavorite('topic-1'), isTrue);
      expect(provider.savedIds, ['topic-1']);
    });

    test('save is idempotent', () async {
      final provider = EncyclopediaFavoritesProvider();
      await provider.load();
      await provider.save('topic-1');
      await provider.save('topic-1');
      await provider.save('topic-1');

      expect(provider.savedIds, ['topic-1']);
    });

    test('remove is idempotent and clears the entry', () async {
      final provider = EncyclopediaFavoritesProvider();
      await provider.load();
      await provider.save('topic-1');
      await provider.remove('topic-1');
      await provider.remove('topic-1');

      expect(provider.isFavorite('topic-1'), isFalse);
      expect(provider.savedIds, isEmpty);
    });

    test('most recently saved comes first', () async {
      final provider = EncyclopediaFavoritesProvider();
      await provider.load();
      await provider.save('topic-a');
      await provider.save('topic-b');
      await provider.save('topic-c');

      expect(provider.savedIds, ['topic-c', 'topic-b', 'topic-a']);
    });

    test('persistence survives provider recreation', () async {
      final first = EncyclopediaFavoritesProvider();
      await first.load();
      await first.save('topic-1');
      await first.save('topic-2');

      final second = EncyclopediaFavoritesProvider();
      await second.load();

      expect(second.isFavorite('topic-1'), isTrue);
      expect(second.isFavorite('topic-2'), isTrue);
      expect(second.savedIds, ['topic-2', 'topic-1']);
    });

    test('load reads values persisted directly in Hive', () async {
      await HiveHelper.addEncyclopediaFavorite('topic-9');

      final provider = EncyclopediaFavoritesProvider();
      await provider.load();

      expect(provider.isFavorite('topic-9'), isTrue);
    });

    test('corrupted persisted data does not crash load', () async {
      await Hive.box(_boxName).put(
        AppStorageKeys.encyclopediaFavorites,
        <dynamic>['topic-1', 42, 'topic-2', null],
      );

      final provider = EncyclopediaFavoritesProvider();
      await provider.load();

      expect(provider.savedIds, ['topic-1', 'topic-2']);
    });

    test('savedIds cannot be mutated by callers', () {
      final provider = EncyclopediaFavoritesProvider();
      expect(() => provider.savedIds.add('x'), throwsUnsupportedError);
    });

    test(
      'provider works with an injected in-memory store (no Hive needed)',
      () async {
        final provider = EncyclopediaFavoritesProvider(
          store: _InMemoryEncyclopediaFavoritesStore(),
        );
        await provider.load();
        await provider.save('a');
        await provider.save('b');
        await provider.save('a');

        expect(provider.savedIds, ['b', 'a']);

        await provider.remove('a');
        expect(provider.savedIds, ['b']);
        expect(provider.isFavorite('b'), isTrue);
      },
    );
  });

  group('domain separation from legacy article favorites', () {
    test(
      'same raw id keeps legacy and encyclopedia favorites independent',
      () async {
        final provider = EncyclopediaFavoritesProvider();
        await provider.load();

        await HiveHelper.toggleFavorite('shared-id');
        await provider.save('shared-id');

        expect(HiveHelper.isFavorite('shared-id'), isTrue);
        expect(HiveHelper.isEncyclopediaFavorite('shared-id'), isTrue);

        await provider.remove('shared-id');

        expect(provider.isFavorite('shared-id'), isFalse);
        expect(HiveHelper.isEncyclopediaFavorite('shared-id'), isFalse);
        expect(
          HiveHelper.isFavorite('shared-id'),
          isTrue,
          reason: 'legacy article favorite must remain untouched',
        );

        await HiveHelper.toggleFavorite('shared-id');

        expect(HiveHelper.isFavorite('shared-id'), isFalse);
        expect(
          HiveHelper.isEncyclopediaFavorite('shared-id'),
          isFalse,
          reason: 'encyclopedia favorite was already removed',
        );
      },
    );

    test('encyclopedia favorites use a separate Hive key', () async {
      final provider = EncyclopediaFavoritesProvider();
      await provider.load();
      await provider.save('topic-1');

      final favoritesBox = Hive.box(_boxName);
      final legacy = favoritesBox.get(
        AppStorageKeys.favorites,
        defaultValue: <String>[],
      );
      final encyclopedia = favoritesBox.get(
        AppStorageKeys.encyclopediaFavorites,
        defaultValue: <String>[],
      );

      expect(legacy, isEmpty);
      expect(encyclopedia, ['topic-1']);
    });
  });

  group('saved topic resolution', () {
    test('resolveTopics preserves order and skips missing ids', () async {
      final repository = _FakeEncyclopediaRepository([
        _topic('t1', 'الموضوع الأول'),
        _topic('t2', 'الموضوع الثاني'),
      ]);
      final provider = EncyclopediaProvider(repository: repository);
      await provider.loadAllTopics();

      final resolved = provider.resolveTopics(['t1', 'missing', 't2']);

      expect(resolved.map((t) => t.id).toList(), ['t1', 't2']);
    });

    test('resolveTopics returns empty for no ids', () async {
      final repository = _FakeEncyclopediaRepository([
        _topic('t1', 'الموضوع الأول'),
      ]);
      final provider = EncyclopediaProvider(repository: repository);
      await provider.loadAllTopics();

      expect(provider.resolveTopics(const []), isEmpty);
    });
  });

  group('widgets', () {
    testWidgets('TopicListCard remove trailing fires onRemove', (tester) async {
      var removed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TopicListCard(
              topic: _topic('t1', 'الموضوع الأول'),
              isDark: false,
              onTap: () {},
              onRemove: () => removed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip(Ar.removeFromFavorites));
      expect(removed, isTrue);
    });

    testWidgets('SavedScreen shows encyclopedia topics and unsave updates UI', (
      tester,
    ) async {
      final repository = _FakeEncyclopediaRepository([
        _topic('t1', 'الموضوع الأول'),
        _topic('t2', 'الموضوع الثاني'),
      ]);
      final favoritesProvider = EncyclopediaFavoritesProvider(
        store: _InMemoryEncyclopediaFavoritesStore(),
      );
      await favoritesProvider.load();
      await favoritesProvider.save('t1');
      await favoritesProvider.save('t2');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
              value: EncyclopediaProvider(repository: repository),
            ),
            ChangeNotifierProvider.value(value: favoritesProvider),
          ],
          child: const MaterialApp(home: SavedScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الموضوع الأول'), findsOneWidget);
      expect(find.text('الموضوع الثاني'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite).first);
      await tester.pumpAndSettle();

      expect(find.text('الموضوع الثاني'), findsNothing);
      expect(find.text('الموضوع الأول'), findsOneWidget);
      expect(favoritesProvider.isFavorite('t2'), isFalse);
      expect(favoritesProvider.isFavorite('t1'), isTrue);
    });

    testWidgets('SavedScreen shows empty state when nothing is saved', (
      tester,
    ) async {
      final repository = _FakeEncyclopediaRepository([
        _topic('t1', 'الموضوع الأول'),
      ]);
      final favoritesProvider = EncyclopediaFavoritesProvider(
        store: _InMemoryEncyclopediaFavoritesStore(),
      );
      await favoritesProvider.load();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
              value: EncyclopediaProvider(repository: repository),
            ),
            ChangeNotifierProvider.value(value: favoritesProvider),
          ],
          child: const MaterialApp(home: SavedScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Ar.noFavorites), findsOneWidget);
    });
  });
}
