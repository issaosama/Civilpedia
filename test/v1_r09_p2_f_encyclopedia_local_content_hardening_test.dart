import 'dart:convert';
import 'dart:io';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/core/widgets/state_widgets.dart';
import 'package:civilpedia/features/encyclopedia/data/datasources/encyclopedia_json_datasource.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_favorites_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/screens/categories_screen.dart';
import 'package:civilpedia/features/encyclopedia/presentation/screens/encyclopedia_screen.dart';
import 'package:civilpedia/features/encyclopedia/presentation/screens/topic_detail_screen.dart';
import 'package:civilpedia/features/encyclopedia/presentation/screens/topic_list_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _TestAssetBundle extends CachingAssetBundle {
  _TestAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final data = assets[key];
    if (data == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    return ByteData.sublistView(utf8.encode(data));
  }
}

Map<String, dynamic> _topicJson(String id) => {
      'id': id,
      'titleAr': 'العنوان $id',
      'categoryId': 'concrete',
      'summary': 'ملخص $id',
      'tags': <String>[],
      'relatedTopicIds': <String>[],
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-01T00:00:00.000Z',
    };

Map<String, dynamic> _sectionJson(String id, [String type = 'execution']) => {
      'id': id,
      'title': 'قسم $id',
      'type': type,
      'order': 1,
    };

Map<String, dynamic> _baseCatalog() => {
      'topics': [_topicJson('t1'), _topicJson('t2')],
      'sections': {
        't1': [_sectionJson('s1')],
      },
      'blocks': {
        't1__s1': [
          {'type': 'text', 'content': 'hello'},
        ],
      },
      'categories': [
        {'id': 'c1', 'title': {'ar': 'خرسانة', 'en': 'Concrete'}},
      ],
    };

/// Wraps a catalog with the authoritative `_meta` whose declared counts are
/// computed from the actual parsed collections.
Map<String, dynamic> _generatedCatalog(Map<String, dynamic> catalog) {
  final topics = catalog['topics'] as List;
  final sections = catalog['sections'] as Map<String, dynamic>;
  final blocks = catalog['blocks'] as Map<String, dynamic>;
  final sectionCount = sections.values.fold<int>(
    0,
    (sum, value) => sum + (value as List).length,
  );
  final blockCount = blocks.values.fold<int>(
    0,
    (sum, value) => sum + (value as List).length,
  );
  return {
    ...catalog,
    '_meta': {
      'format': 'civilpedia-catalog-generated',
      'schemaVersion': 1,
      'topicCount': topics.length,
      'sectionCount': sectionCount,
      'blockCount': blockCount,
    },
  };
}

Future<EncyclopediaContentException> _failingLoad(
  EncyclopediaJsonDataSource source,
) async {
  try {
    await source.fetchAllTopics();
  } catch (e) {
    return e as EncyclopediaContentException;
  }
  throw StateError('expected an EncyclopediaContentException');
}

EngineeringTopic _topicFixture(
  String id,
  String title, {
  String categoryId = 'concrete',
}) =>
    EngineeringTopic(
      id: id,
      titleAr: title,
      categoryId: categoryId,
      summary: 'ملخص $id',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      tags: const [],
    );

class _FakeFavoritesStore implements EncyclopediaFavoritesStore {
  final List<String> _ids = [];

  @override
  Future<List<String>> read() async => List.unmodifiable(_ids);

  @override
  Future<void> add(String topicId) async => _ids.add(topicId);

  @override
  Future<void> remove(String topicId) async => _ids.remove(topicId);
}

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  _FakeEncyclopediaRepository({
    this.topics = const [],
    this.categories = const {},
  });

  final List<EngineeringTopic> topics;
  final Map<String, CategoryInfo> categories;

  Object? allTopicsError;
  Object? detailError;
  Object? categoryError;

  int allTopicsCalls = 0;
  int categoryCalls = 0;
  String? lastCategoryRequested;

  @override
  Future<List<EngineeringTopic>> getAllTopics() async {
    allTopicsCalls++;
    final e = allTopicsError;
    if (e != null) throw e;
    return topics;
  }

  @override
  Future<EngineeringTopic?> getTopicById(String id) async {
    final e = detailError;
    if (e != null) throw e;
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async {
    categoryCalls++;
    lastCategoryRequested = categoryId;
    final e = categoryError;
    if (e != null) throw e;
    return topics.where((t) => t.categoryId == categoryId).toList();
  }

  @override
  Future<Map<String, CategoryInfo>> getCategories() async => categories;

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async =>
      const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async =>
      const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => topics;
}

Future<void> _pumpHost(
  WidgetTester tester,
  EncyclopediaProvider provider,
  Widget home,
) async {
  final favoritesProvider =
      EncyclopediaFavoritesProvider(store: _FakeFavoritesStore());
  await favoritesProvider.load();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        ChangeNotifierProvider.value(value: favoritesProvider),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EncyclopediaJsonDataSource - authoritative lane classification', () {
    test('assetUnavailable when the generated asset is missing', () async {
      final source = EncyclopediaJsonDataSource(
        bundle: _TestAssetBundle({'assets/unrelated/file.json': '{}'}),
      );

      final failure = await _failingLoad(source);
      expect(failure.kind, EncyclopediaContentFailureKind.assetUnavailable);
      expect(source.usingGeneratedCatalog, isFalse);
    });

    test('malformedContent when the generated asset is not valid JSON',
        () async {
      final source = EncyclopediaJsonDataSource(
        bundle: _TestAssetBundle({
          EncyclopediaJsonDataSource.authoritativeAssetPath: 'not json',
        }),
      );

      final failure = await _failingLoad(source);
      expect(failure.kind, EncyclopediaContentFailureKind.malformedContent);
    });

    test('malformedContent when the root is not an object', () async {
      final source = EncyclopediaJsonDataSource(
        bundle: _TestAssetBundle({
          EncyclopediaJsonDataSource.authoritativeAssetPath: '[1, 2, 3]',
        }),
      );

      final failure = await _failingLoad(source);
      expect(failure.kind, EncyclopediaContentFailureKind.malformedContent);
    });

    test('malformedContent when _meta is missing', () async {
      final source = EncyclopediaJsonDataSource(
        bundle: _TestAssetBundle({
          EncyclopediaJsonDataSource.authoritativeAssetPath:
              jsonEncode(_baseCatalog()),
        }),
      );

      final failure = await _failingLoad(source);
      expect(failure.kind, EncyclopediaContentFailureKind.malformedContent);
    });

    test('malformedContent when _meta format is not the generated format',
        () async {
      final source = EncyclopediaJsonDataSource(
        bundle: _TestAssetBundle({
          EncyclopediaJsonDataSource.authoritativeAssetPath: jsonEncode({
            ..._generatedCatalog(_baseCatalog()),
            '_meta': {
              'format': 'legacy-format',
              'schemaVersion': 1,
              'topicCount': 2,
              'sectionCount': 1,
              'blockCount': 1,
            },
          }),
        }),
      );

      final failure = await _failingLoad(source);
      expect(failure.kind, EncyclopediaContentFailureKind.malformedContent);
    });

    test('malformedContent when _meta schemaVersion is unsupported', () async {
      final source = EncyclopediaJsonDataSource(
        bundle: _TestAssetBundle({
          EncyclopediaJsonDataSource.authoritativeAssetPath: jsonEncode({
            ..._generatedCatalog(_baseCatalog()),
            '_meta': {
              'format': 'civilpedia-catalog-generated',
              'schemaVersion': 99,
              'topicCount': 2,
              'sectionCount': 1,
              'blockCount': 1,
            },
          }),
        }),
      );

      final failure = await _failingLoad(source);
      expect(failure.kind, EncyclopediaContentFailureKind.malformedContent);
    });

    test('malformedContent when a topic is malformed (skip gate)', () async {
      final source = EncyclopediaJsonDataSource(
        bundle: _TestAssetBundle({
          EncyclopediaJsonDataSource.authoritativeAssetPath:
              jsonEncode(_generatedCatalog({
            ..._baseCatalog(),
            'topics': [
              _topicJson('t1'),
              {'id': null, 'titleAr': 'broken'},
            ],
          })),
        }),
      );

      final failure = await _failingLoad(source);
      expect(failure.kind, EncyclopediaContentFailureKind.malformedContent);
      expect(failure.skips, isNotEmpty);
      expect(failure.skips.first.kind, 'topic');
      expect(source.usingGeneratedCatalog, isFalse);
    });

    test('malformedContent when a section is malformed (skip gate)', () async {
      final source = EncyclopediaJsonDataSource(
        bundle: _TestAssetBundle({
          EncyclopediaJsonDataSource.authoritativeAssetPath:
              jsonEncode(_generatedCatalog({
            ..._baseCatalog(),
            'sections': {
              't1': [
                _sectionJson('s1', 'bogus_type'),
              ],
            },
          })),
        }),
      );

      final failure = await _failingLoad(source);
      expect(failure.kind, EncyclopediaContentFailureKind.malformedContent);
      expect(failure.skips, isNotEmpty);
      expect(failure.skips.first.kind, 'section');
    });

    test('malformedContent when a block type is unknown (skip gate)',
        () async {
      final source = EncyclopediaJsonDataSource(
        bundle: _TestAssetBundle({
          EncyclopediaJsonDataSource.authoritativeAssetPath:
              jsonEncode(_generatedCatalog({
            ..._baseCatalog(),
            'blocks': {
              't1__s1': [
                {'type': 'text', 'content': 'ok'},
                {'type': 'unknown_type', 'content': 'bad'},
              ],
            },
          })),
        }),
      );

      final failure = await _failingLoad(source);
      expect(failure.kind, EncyclopediaContentFailureKind.malformedContent);
      expect(failure.skips, isNotEmpty);
      expect(failure.skips.first.kind, 'block');
      expect(failure.skips.first.blockType, 'unknown_type');
    });

    test('malformedContent when a category entry is malformed (skip gate)',
        () async {
      final source = EncyclopediaJsonDataSource(
        bundle: _TestAssetBundle({
          EncyclopediaJsonDataSource.authoritativeAssetPath:
              jsonEncode(_generatedCatalog({
            ..._baseCatalog(),
            'categories': [
              {'id': 'c1', 'title': {'ar': 'خرسانة', 'en': 'Concrete'}},
              {'nope': true},
            ],
          })),
        }),
      );

      final failure = await _failingLoad(source);
      expect(failure.kind, EncyclopediaContentFailureKind.malformedContent);
      expect(failure.skips, isNotEmpty);
      expect(failure.skips.first.kind, 'category');
    });

    test('malformedContent when declared counts disagree with parsed content',
        () async {
      final source = EncyclopediaJsonDataSource(
        bundle: _TestAssetBundle({
          EncyclopediaJsonDataSource.authoritativeAssetPath: jsonEncode({
            ..._generatedCatalog(_baseCatalog()),
            '_meta': {
              'format': 'civilpedia-catalog-generated',
              'schemaVersion': 1,
              'topicCount': 999,
              'sectionCount': 1,
              'blockCount': 1,
            },
          }),
        }),
      );

      final failure = await _failingLoad(source);
      expect(failure.kind, EncyclopediaContentFailureKind.malformedContent);
    });

    test('manual retry re-attempts the same authoritative lane', () async {
      final assets = <String, String>{};
      final source =
          EncyclopediaJsonDataSource(bundle: _TestAssetBundle(assets));

      final first = await _failingLoad(source);
      expect(first.kind, EncyclopediaContentFailureKind.assetUnavailable);
      expect(source.usingGeneratedCatalog, isFalse);

      assets[EncyclopediaJsonDataSource.authoritativeAssetPath] =
          jsonEncode(_generatedCatalog(_baseCatalog()));
      final topics = await source.fetchAllTopics();

      expect(topics.length, 2);
      expect(source.usingGeneratedCatalog, isTrue);
      expect(source.lastSkips, isEmpty);
    });
  });

  group('EncyclopediaProvider - P2-F state machine', () {
    test('initial catalog failure surfaces a typed contentFailure', () async {
      final repo = _FakeEncyclopediaRepository()
        ..allTopicsError = const EncyclopediaContentException(
          EncyclopediaContentFailureKind.assetUnavailable,
        );
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadAllTopics();

      expect(provider.hasContentFailure, isTrue);
      expect(
        provider.contentFailure!.kind,
        EncyclopediaContentFailureKind.assetUnavailable,
      );
      expect(provider.error, isNotNull);
      expect(provider.allTopics, isEmpty);
      expect(provider.hasCompletedInitialLoad, isTrue);
    });

    test('unexpected errors are classified without leaking raw text into UI',
        () async {
      final repo = _FakeEncyclopediaRepository()
        ..allTopicsError = StateError('secret-raw-probe');
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadAllTopics();

      expect(provider.hasContentFailure, isTrue);
      expect(
        provider.contentFailure!.kind,
        EncyclopediaContentFailureKind.unexpected,
      );
    });

    test('a successful retry clears the failure and loads content', () async {
      final repo = _FakeEncyclopediaRepository(topics: [_topicFixture('t1', 'أ')])
        ..allTopicsError = const EncyclopediaContentException(
          EncyclopediaContentFailureKind.assetUnavailable,
        );
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadAllTopics();
      expect(provider.hasContentFailure, isTrue);

      repo.allTopicsError = null;
      await provider.loadAllTopics();

      expect(provider.hasContentFailure, isFalse);
      expect(provider.allTopics, hasLength(1));
    });

    test('reload failure preserves known-good topics', () async {
      final repo = _FakeEncyclopediaRepository(topics: [_topicFixture('t1', 'أ')]);
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadAllTopics();
      expect(provider.allTopics, hasLength(1));

      repo.allTopicsError = const EncyclopediaContentException(
        EncyclopediaContentFailureKind.malformedContent,
      );
      await provider.loadAllTopics();

      expect(provider.hasContentFailure, isTrue);
      expect(provider.allTopics, hasLength(1));
      expect(provider.allTopics.single.id, 't1');
    });

    test('same-category reload failure preserves known-good category topics',
        () async {
      final repo =
          _FakeEncyclopediaRepository(topics: [_topicFixture('t1', 'أ')]);
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadTopicsByCategory('concrete');
      expect(provider.categoryTopics, hasLength(1));

      repo.categoryError = const EncyclopediaContentException(
        EncyclopediaContentFailureKind.malformedContent,
      );
      await provider.loadTopicsByCategory('concrete');

      expect(provider.hasContentFailure, isTrue);
      expect(provider.categoryTopics, hasLength(1));
    });

    test('cross-category failure clears stale category topics', () async {
      final repo = _FakeEncyclopediaRepository(
        topics: [
          _topicFixture('t1', 'أ'),
          _topicFixture('t2', 'ب', ),
        ],
      );
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadTopicsByCategory('concrete');
      expect(provider.categoryTopics, hasLength(2));

      repo.categoryError = const EncyclopediaContentException(
        EncyclopediaContentFailureKind.malformedContent,
      );
      await provider.loadTopicsByCategory('steel');

      expect(provider.hasContentFailure, isTrue);
      expect(provider.categoryTopics, isEmpty);
    });

    test('same-topic reload failure preserves known-good detail', () async {
      final repo =
          _FakeEncyclopediaRepository(topics: [_topicFixture('A', 'موضوع أ')]);
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadTopicDetail('A');
      expect(provider.currentTopic?.id, 'A');

      repo.detailError = const EncyclopediaContentException(
        EncyclopediaContentFailureKind.assetUnavailable,
      );
      await provider.loadTopicDetail('A');

      expect(provider.hasContentFailure, isTrue);
      expect(provider.currentTopic?.id, 'A');
      expect(provider.showingSameTopicKnownGood, isTrue);
    });

    test('cross-topic A to B failure never presents A as B', () async {
      final repo = _FakeEncyclopediaRepository(
        topics: [_topicFixture('A', 'موضوع أ')],
      );
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadTopicDetail('A');
      expect(provider.currentTopic?.id, 'A');

      repo.detailError = const EncyclopediaContentException(
        EncyclopediaContentFailureKind.assetUnavailable,
      );
      await provider.loadTopicDetail('B');

      expect(provider.hasContentFailure, isTrue);
      expect(provider.currentTopic, isNull);
      expect(provider.showingSameTopicKnownGood, isFalse);
    });

    test('same-category reload failure preserves known-good topic list', () async {
      final repo = _FakeEncyclopediaRepository(
        topics: [_topicFixture('ca', 'خرسانة أ')],
      );
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadTopicsByCategory('concrete');
      expect(provider.categoryTopics.single.id, 'ca');

      repo.categoryError = const EncyclopediaContentException(
        EncyclopediaContentFailureKind.assetUnavailable,
      );
      await provider.loadTopicsByCategory('concrete');

      expect(provider.hasContentFailure, isTrue);
      expect(provider.categoryTopics.single.id, 'ca');
      expect(provider.showingSameCategoryKnownGood, isTrue);
    });

    test('cross-category failure never presents category A as category B',
        () async {
      final repo = _FakeEncyclopediaRepository(
        topics: [_topicFixture('ca', 'خرسانة أ')],
      );
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadTopicsByCategory('concrete');
      expect(provider.categoryTopics.single.id, 'ca');

      repo.categoryError = const EncyclopediaContentException(
        EncyclopediaContentFailureKind.assetUnavailable,
      );
      await provider.loadTopicsByCategory('steel');

      expect(provider.hasContentFailure, isTrue);
      expect(provider.categoryTopics, isEmpty);
      expect(provider.showingSameCategoryKnownGood, isFalse);
    });

    test('catalog reload failure preserves known-good topics and categories',
        () async {
      final repo = _FakeEncyclopediaRepository(
        topics: [_topicFixture('ct', 'موضوع كامل')],
        categories: const {
          'concrete': CategoryInfo(
            id: 'concrete',
            titleAr: 'خرسانة',
            titleEn: 'Concrete',
          ),
        },
      );
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadAllTopics();
      expect(provider.allTopics.single.id, 'ct');
      expect(provider.categories.keys, contains('concrete'));

      repo.allTopicsError = const EncyclopediaContentException(
        EncyclopediaContentFailureKind.malformedContent,
      );
      await provider.loadAllTopics();

      expect(provider.hasContentFailure, isTrue);
      expect(provider.allTopics.single.id, 'ct');
      expect(provider.categories.keys, contains('concrete'));
      expect(provider.showingKnownGoodCatalog, isTrue);
    });

    test('missing topic id is a topic-not-found outcome, not a content failure',
        () async {
      final repo =
          _FakeEncyclopediaRepository(topics: [_topicFixture('exists', 'موجود')]);
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadTopicDetail('missing-topic');

      expect(provider.hasContentFailure, isFalse);
      expect(provider.contentFailure, isNull);
      expect(provider.currentTopic, isNull);
    });
  });

  group('P2-F screen surfaces - controlled localized copy only', () {
    testWidgets('EncyclopediaScreen failure shows localized error, no raw text',
        (tester) async {
      final provider = EncyclopediaProvider(
        repository: _FakeEncyclopediaRepository()
          ..allTopicsError = const EncyclopediaContentException(
            EncyclopediaContentFailureKind.malformedContent,
            message: 'internal-diagnostic-probe',
          ),
      );

      await _pumpHost(tester, provider, const EncyclopediaScreen());

      expect(find.text(Ar.encyclopediaContentError), findsOneWidget);
      expect(find.textContaining('internal-diagnostic-probe'), findsNothing);
      expect(find.textContaining('EncyclopediaContentException'), findsNothing);
    });

    testWidgets('CategoriesScreen failure shows localized error, no raw text',
        (tester) async {
      final provider = EncyclopediaProvider(
        repository: _FakeEncyclopediaRepository()
          ..allTopicsError = StateError('secret-raw-probe'),
      );

      await _pumpHost(tester, provider, const CategoriesScreen());

      expect(find.text(Ar.encyclopediaContentError), findsOneWidget);
      expect(find.text(Ar.retry), findsOneWidget);
      expect(find.textContaining('secret-raw-probe'), findsNothing);
    });

    testWidgets('TopicDetailScreen known-good reload failure shows notice + '
        'article, never the generic error', (tester) async {
      final repo = _FakeEncyclopediaRepository(
        topics: [_topicFixture('tdA', 'فحص الخرسانة')],
      );
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadTopicDetail('tdA');

      repo.detailError = const EncyclopediaContentException(
        EncyclopediaContentFailureKind.assetUnavailable,
      );

      await _pumpHost(
        tester,
        provider,
        const TopicDetailScreen(topicId: 'tdA'),
      );

      expect(find.text(Ar.encyclopediaContentKnownGoodNotice), findsOneWidget);
      expect(find.text('فحص الخرسانة'), findsWidgets);
      expect(find.text(Ar.encyclopediaContentError), findsNothing);
      expect(find.textContaining('EncyclopediaContentException'), findsNothing);
    });

    testWidgets('TopicDetailScreen cross-topic failure shows controlled error, '
        'no stale content', (tester) async {
      final provider = EncyclopediaProvider(
        repository: _FakeEncyclopediaRepository()..detailError =
            const EncyclopediaContentException(
              EncyclopediaContentFailureKind.assetUnavailable,
            ),
      );

      await _pumpHost(
        tester,
        provider,
        const TopicDetailScreen(topicId: 'td-new'),
      );

      expect(find.text(Ar.encyclopediaContentError), findsOneWidget);
      expect(find.text(Ar.encyclopediaContentKnownGoodNotice), findsNothing);
      expect(find.textContaining('assetUnavailable'), findsNothing);
    });
  });

  group('P2-F known-good catalog/category UX (surgical correction)', () {
    testWidgets('EncyclopediaScreen known-good catalog reload failure keeps '
        'content + one notice + manual retry', (tester) async {
      final repo = _FakeEncyclopediaRepository(
        topics: [
          _topicFixture('k1', 'موضوع كامل أ'),
          _topicFixture('k2', 'موضوع كامل ب'),
        ],
        categories: const {
          'concrete': CategoryInfo(
            id: 'concrete',
            titleAr: 'خرسانة',
            titleEn: 'Concrete',
          ),
        },
      );
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadAllTopics();
      expect(provider.allTopics.length, 2);

      repo.allTopicsError = const EncyclopediaContentException(
        EncyclopediaContentFailureKind.assetUnavailable,
      );
      await provider.loadAllTopics();
      expect(provider.hasContentFailure, isTrue);
      expect(provider.showingKnownGoodCatalog, isTrue);

      await _pumpHost(tester, provider, const EncyclopediaScreen());

      expect(find.text(Ar.encyclopediaContentKnownGoodNotice), findsOneWidget);
      expect(find.text('موضوع كامل أ'), findsWidgets);
      expect(find.text('موضوع كامل ب'), findsWidgets);
      expect(find.text(Ar.retry), findsOneWidget);
      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text(Ar.encyclopediaContentError), findsNothing);

      repo.allTopicsError = null;
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(repo.allTopicsCalls, 3);
      expect(find.text(Ar.encyclopediaContentKnownGoodNotice), findsNothing);
      expect(find.text('موضوع كامل أ'), findsWidgets);
    });

    testWidgets('CategoriesScreen known-good reload failure keeps categories + '
        'one notice + retry, never silent', (tester) async {
      final repo = _FakeEncyclopediaRepository(
        topics: [_topicFixture('k1', 'موضوع كامل أ')],
        categories: const {
          'concrete': CategoryInfo(
            id: 'concrete',
            titleAr: 'خرسانة',
            titleEn: 'Concrete',
          ),
        },
      );
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadAllTopics();
      expect(provider.categories.length, 1);

      repo.allTopicsError = const EncyclopediaContentException(
        EncyclopediaContentFailureKind.malformedContent,
      );
      await provider.loadAllTopics();
      expect(provider.hasContentFailure, isTrue);

      await _pumpHost(tester, provider, const CategoriesScreen());

      expect(find.text(Ar.encyclopediaContentKnownGoodNotice), findsOneWidget);
      expect(find.text('خرسانة'), findsOneWidget);
      expect(find.text(Ar.retry), findsOneWidget);
      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text(Ar.encyclopediaContentError), findsNothing);

      repo.allTopicsError = null;
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(repo.allTopicsCalls, 3);
      expect(find.text(Ar.encyclopediaContentKnownGoodNotice), findsNothing);
      expect(find.text('خرسانة'), findsOneWidget);
    });

    testWidgets('TopicListScreen same-category reload failure keeps topics + '
        'one notice + retry', (tester) async {
      final repo = _FakeEncyclopediaRepository(
        topics: [_topicFixture('t1', 'موضوع الخرسانة')],
      );
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadTopicsByCategory('concrete');
      expect(provider.categoryTopics.single.id, 't1');

      repo.categoryError = const EncyclopediaContentException(
        EncyclopediaContentFailureKind.assetUnavailable,
      );
      await provider.loadTopicsByCategory('concrete');
      expect(provider.showingSameCategoryKnownGood, isTrue);

      await _pumpHost(
        tester,
        provider,
        const TopicListScreen(categoryId: 'concrete'),
      );

      expect(find.text(Ar.encyclopediaContentKnownGoodNotice), findsOneWidget);
      expect(find.text('موضوع الخرسانة'), findsWidgets);
      expect(find.text(Ar.retry), findsOneWidget);
      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text(Ar.encyclopediaContentError), findsNothing);
    });

    testWidgets('TopicListScreen cross-category failure never presents A as B, '
        'retry is for the B lane', (tester) async {
      final repo = _FakeEncyclopediaRepository(
        topics: [
          _topicFixture('a1', 'موضوع الحديد أ'),
          _topicFixture('b1', 'موضوع الفولاذ ب', categoryId: 'steel'),
        ],
      );
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadTopicsByCategory('concrete');
      expect(provider.categoryTopics.single.id, 'a1');

      repo.categoryError = StateError('steel-lane-probe');
      await provider.loadTopicsByCategory('steel');
      expect(provider.hasContentFailure, isTrue);
      expect(provider.categoryTopics, isEmpty);
      expect(provider.showingSameCategoryKnownGood, isFalse);

      await _pumpHost(
        tester,
        provider,
        const TopicListScreen(categoryId: 'steel'),
      );

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text(Ar.encyclopediaContentError), findsOneWidget);
      expect(find.text(Ar.retry), findsOneWidget);
      expect(find.text('موضوع الحديد أ'), findsNothing);
      expect(find.text('موضوع الفولاذ ب'), findsNothing);
      expect(find.text(Ar.encyclopediaContentKnownGoodNotice), findsNothing);
      expect(find.textContaining('steel-lane-probe'), findsNothing);

      repo.categoryError = null;
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(repo.lastCategoryRequested, 'steel');
      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text('موضوع الفولاذ ب'), findsWidgets);
      expect(find.text('موضوع الحديد أ'), findsNothing);
    });

    testWidgets('missing topic id renders topic-not-found, not a content '
        'failure, and never a stale previous topic', (tester) async {
      final repo = _FakeEncyclopediaRepository(
        topics: [_topicFixture('shown', 'موضوع سابق معروض')],
      );
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadTopicDetail('shown');
      expect(provider.currentTopic?.id, 'shown');

      await _pumpHost(
        tester,
        provider,
        const TopicDetailScreen(topicId: 'missing-topic'),
      );

      expect(provider.hasContentFailure, isFalse);
      expect(provider.contentFailure, isNull);
      expect(provider.currentTopic, isNull);
      expect(find.text(Ar.topicNotFound), findsOneWidget);
      expect(find.text('موضوع سابق معروض'), findsNothing);
      expect(find.text(Ar.encyclopediaContentError), findsNothing);
    });
  });

  group('P2-F sync gate - packaged catalog authority', () {
    test('generated catalog is byte-identical to the app_ready artifact',
        () {
      final packaged =
          File('assets/encyclopedia/catalog.generated.json').readAsBytesSync();
      final ready =
          File('app_ready_jsons/catalog.generated.json').readAsBytesSync();

      expect(packaged, ready);
    });

    test('packaged catalog passes the full authoritative lane', () async {
      final content =
          File('assets/encyclopedia/catalog.generated.json').readAsStringSync();
      final source = EncyclopediaJsonDataSource(
        bundle: _TestAssetBundle({
          EncyclopediaJsonDataSource.authoritativeAssetPath: content,
        }),
      );

      final topics = await source.fetchAllTopics();
      final categories = await source.fetchCategories();

      expect(topics.length, 13);
      expect(categories.length, 6);
      expect(source.usingGeneratedCatalog, isTrue);
      expect(source.lastSkips, isEmpty);
    });

    test('declared _meta counts and zero skips hold for the packaged catalog',
        () {
      final decoded = jsonDecode(
            File('assets/encyclopedia/catalog.generated.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
      final meta = decoded['_meta'] as Map<String, dynamic>;

      expect(meta['format'], 'civilpedia-catalog-generated');
      expect(meta['schemaVersion'], 1);
      expect(meta['topicCount'], 13);

      final result = parseCatalogJson(decoded);
      final sectionCount = result.sections.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      );
      final blockCount = result.blocks.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      );

      expect(sectionCount, 117);
      expect(blockCount, 539);
      expect(result.categories.length, 6);
      expect(result.skips, isEmpty);
      expect(meta['topicCount'], result.topics.length);
      expect(meta['sectionCount'], sectionCount);
      expect(meta['blockCount'], blockCount);
    });
  });

  group('P2-F localized copy - symmetric AR/EN', () {
    test('content error keys are present and language specific', () {
      expect(Ar.encyclopediaContentError, 'تعذر تحميل محتوى الموسوعة');
      expect(
        En.encyclopediaContentError,
        'Encyclopedia content could not be loaded',
      );
      expect(Ar.encyclopediaContentError, isNot(En.encyclopediaContentError));
    });

    test('known-good notice keys are present and language specific', () {
      expect(
        Ar.encyclopediaContentKnownGoodNotice,
        'يتم عرض آخر محتوى تم تحميله بنجاح',
      );
      expect(
        En.encyclopediaContentKnownGoodNotice,
        'Showing the last successfully loaded content',
      );
    });
  });
}