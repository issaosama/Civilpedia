import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/data/local/hive_helper.dart';
import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/features/directory/domain/directory_repository.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_detail_screen.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_favorites_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/features/saved/domain/saved_item_reference.dart';
import 'package:civilpedia/features/saved/domain/saved_reference_resolver.dart';
import 'package:civilpedia/features/saved/domain/saved_reference_store.dart';
import 'package:civilpedia/features/saved/presentation/saved_screen.dart';
import 'package:civilpedia/localization/ar.dart';

class _FakeDirectoryRepository implements DirectoryRepository {
  final List<ServiceBusinessProfile> providers;
  _FakeDirectoryRepository(this.providers);

  @override
  Future<List<ServiceBusinessProfile>> loadAll() async => List.of(providers);

  @override
  Future<ServiceBusinessProfile?> loadById(String id) async {
    for (final p in providers) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<void> save(ServiceBusinessProfile profile) async {}
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> clearAll() async {}
}

class _FakeSavedStore implements SavedReferenceStore {
  final List<SavedItemReference> refs;
  _FakeSavedStore([List<SavedItemReference> seed = const []]) : refs = List.of(seed);

  @override
  Future<List<SavedItemReference>> loadAll() async => List.of(refs);
  @override
  Future<bool> contains(String referenceId) async =>
      refs.any((r) => r.id == referenceId);
  @override
  Future<void> save(SavedItemReference reference) async {
    if (!refs.any((r) => r.id == reference.id)) refs.add(reference);
  }

  @override
  Future<void> remove(String referenceId) async {
    refs.removeWhere((r) => r.id == referenceId);
  }
}

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  final List<EngineeringTopic> topics;
  _FakeEncyclopediaRepository([this.topics = const []]);

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async =>
      topics;
  @override
  Future<EngineeringTopic?> getTopicById(String id) async {
    for (final t in topics) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => topics;
  @override
  Future<List<EngineeringTopic>> getAllTopics() async => topics;
  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async =>
      const [];
  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async => const [];
  @override
  Future<Map<String, CategoryInfo>> getCategories() async =>
      const <String, CategoryInfo>{};
}

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

ServiceBusinessProfile _provider(String id, {String name = '', BusinessType type = BusinessType.supplier, BaghdadArea area = BaghdadArea.karrada}) {
  return ServiceBusinessProfile(id: id, name: name, type: type, baghdadArea: area);
}

SavedItemReference _dirRef(String id) => SavedItemReference(
  ownerDomain: SavedReferenceOwners.directory,
  entityType: SavedReferenceEntityTypes.provider,
  entityId: id,
  savedAt: DateTime.utc(2026, 8, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  required DirectoryRepository directoryRepo,
  required SavedReferenceStore store,
  List<String> topicIds = const [],
  List<String> articleIds = const [],
  List<EngineeringTopic> topics = const [],
}) async {
  final favorites = EncyclopediaFavoritesProvider();
  await favorites.load();
  final resolver = SavedReferenceResolver(
    encyclopediaTopicIds: () async => List.of(topicIds),
    legacyArticleIds: () async => List.of(articleIds),
    structuredReferences: () async => store.loadAll(),
  );
  await tester.runAsync(() async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(
            create: (_) => EncyclopediaProvider(
              repository: _FakeEncyclopediaRepository(topics),
            ),
          ),
          ChangeNotifierProvider.value(value: favorites),
        ],
        child: MaterialApp(
          home: SavedScreen(
            favoritesResolver: resolver,
            directoryRepository: directoryRepo,
            savedReferenceStore: store,
          ),
        ),
      ),
    );
    // Let the async resolve + loadById chain fully complete on the real event
    // loop before the widget settles.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
}

void main() {
  late Directory tempDir;
  const boxName = 'w5_6_saved_screen_directory_box';

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('civilpedia_w5_6_saved_dir');
    await HiveHelper.init(path: tempDir.path, boxName: boxName);
  });

  setUp(() async {
    await Hive.box(boxName).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('W5.6 SavedScreen Directory section', () {
    testWidgets('38. no Directory section when no Directory refs', (tester) async {
      await _pump(
        tester,
        directoryRepo: _FakeDirectoryRepository([_provider('p1', name: 'Alpha')]),
        store: _FakeSavedStore(const []),
      );
      expect(find.text(Ar.savedEngineeringDirectory), findsNothing);
      expect(find.text('Alpha'), findsNothing);
    });

    testWidgets('39. Directory section appears with provider refs', (tester) async {
      await _pump(
        tester,
        directoryRepo: _FakeDirectoryRepository([_provider('p1', name: 'Alpha')]),
        store: _FakeSavedStore([_dirRef('p1')]),
      );
      expect(find.text(Ar.savedEngineeringDirectory), findsOneWidget);
    });

    testWidgets('40. resolved provider row shows name', (tester) async {
      await _pump(
        tester,
        directoryRepo: _FakeDirectoryRepository([_provider('p1', name: 'Alpha Steel')]),
        store: _FakeSavedStore([_dirRef('p1')]),
      );
      expect(find.text('Alpha Steel'), findsOneWidget);
    });

    testWidgets('41. row shows localized BusinessType', (tester) async {
      await _pump(
        tester,
        directoryRepo: _FakeDirectoryRepository([
          _provider('p1', name: 'Alpha', type: BusinessType.supplier),
        ]),
        store: _FakeSavedStore([_dirRef('p1')]),
      );
      expect(find.textContaining('مورّد'), findsOneWidget);
    });

    testWidgets('42. row shows location when meaningful', (tester) async {
      await _pump(
        tester,
        directoryRepo: _FakeDirectoryRepository([
          _provider('p1', name: 'Alpha', area: BaghdadArea.karrada),
        ]),
        store: _FakeSavedStore([_dirRef('p1')]),
      );
      expect(find.textContaining('كرادة'), findsOneWidget);
    });

    testWidgets('43. source/ref order preserved', (tester) async {
      await _pump(
        tester,
        directoryRepo: _FakeDirectoryRepository([
          _provider('p1', name: 'Provider One'),
          _provider('p2', name: 'Provider Two'),
          _provider('p3', name: 'Provider Three'),
        ]),
        store: _FakeSavedStore([_dirRef('p1'), _dirRef('p2'), _dirRef('p3')]),
      );
      expect(tester.getTopLeft(find.text('Provider One')).dy <
          tester.getTopLeft(find.text('Provider Two')).dy, isTrue);
      expect(tester.getTopLeft(find.text('Provider Two')).dy <
          tester.getTopLeft(find.text('Provider Three')).dy, isTrue);
    });

    testWidgets('44. row tap opens DirectoryProviderDetailScreen', (tester) async {
      await _pump(
        tester,
        directoryRepo: _FakeDirectoryRepository([_provider('p1', name: 'Alpha')]),
        store: _FakeSavedStore([_dirRef('p1')]),
      );
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      expect(find.byType(DirectoryProviderDetailScreen), findsOneWidget);
    });

    testWidgets('45. back returns to SavedScreen', (tester) async {
      await _pump(
        tester,
        directoryRepo: _FakeDirectoryRepository([_provider('p1', name: 'Alpha')]),
        store: _FakeSavedStore([_dirRef('p1')]),
      );
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      expect(find.byType(DirectoryProviderDetailScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SavedScreen), findsOneWidget);
    });

    testWidgets('46. missing provider renders Provider unavailable', (tester) async {
      await _pump(
        tester,
        directoryRepo: _FakeDirectoryRepository(const []),
        store: _FakeSavedStore([_dirRef('missing')]),
      );
      expect(find.text(Ar.savedProviderUnavailable), findsOneWidget);
    });

    testWidgets('47. missing provider row is non-navigating', (tester) async {
      await _pump(
        tester,
        directoryRepo: _FakeDirectoryRepository(const []),
        store: _FakeSavedStore([_dirRef('missing')]),
      );
      await tester.tap(find.text(Ar.savedProviderUnavailable));
      await tester.pumpAndSettle();
      expect(find.byType(DirectoryProviderDetailScreen), findsNothing);
    });

    testWidgets('48. missing provider ref is not silently deleted', (tester) async {
      final store = _FakeSavedStore([_dirRef('missing')]);
      await _pump(
        tester,
        directoryRepo: _FakeDirectoryRepository(const []),
        store: store,
      );
      expect(find.text(Ar.savedProviderUnavailable), findsOneWidget);
      await tester.pumpAndSettle();
      expect(store.refs, hasLength(1));
      expect(store.refs.single.entityId, 'missing');
    });

    testWidgets('49. Knowledge Saved rendering remains unchanged', (tester) async {
      // A Knowledge topic still renders alongside a Directory section.
      await _pump(
        tester,
        directoryRepo: _FakeDirectoryRepository([_provider('p1', name: 'Alpha')]),
        store: _FakeSavedStore([_dirRef('p1')]),
        topicIds: const ['t1'],
        topics: [_topic('t1', 'الموضوع الأول')],
      );
      expect(find.text('الموضوع الأول'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text(Ar.engineeringEncyclopedia), findsOneWidget);
      expect(find.text(Ar.savedEngineeringDirectory), findsOneWidget);
    });
  });
}
