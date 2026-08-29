import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/search/data/search_aggregator_production.dart';
import 'package:civilpedia/features/search/domain/search_aggregator.dart';
import 'package:civilpedia/features/search/domain/search_result.dart';
import 'package:civilpedia/features/tools/domain/tool_key.dart';

EngineeringTopic _topic(
  String id,
  String title, {
  List<String> tags = const [],
}) => EngineeringTopic(
  id: id,
  titleAr: title,
  categoryId: 'cat1',
  summary: 'ملخص $title',
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
  tags: tags,
);

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  final List<EngineeringTopic> topics;
  int searchCalls = 0;
  final List<String> receivedQueries = [];

  _FakeEncyclopediaRepository({this.topics = const []});

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async {
    searchCalls++;
    receivedQueries.add(query);
    final q = query.toLowerCase();
    return topics
        .where(
          (t) =>
              q.isEmpty ||
              t.titleAr.toLowerCase().contains(q) ||
              t.summary.toLowerCase().contains(q) ||
              t.tags.any((tag) => tag.toLowerCase().contains(q)),
        )
        .toList();
  }

  @override
  Future<List<EngineeringTopic>> getAllTopics() async => topics;

  @override
  Future<EngineeringTopic?> getTopicById(String id) async {
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async =>
      topics.where((t) => t.categoryId == categoryId).toList();

  @override
  Future<Map<String, CategoryInfo>> getCategories() async => const {};

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async =>
      const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async => const [];
}

/// A controllable source stub ("scriptable") used to prove isolation directly.
class _ScriptableSource {
  int calls = 0;
  final List<String> receivedQueries = [];
  List<SearchResult> Function(String query)? handler;
  Object? throwError;

  SearchSource get source => (String query) async {
    calls++;
    receivedQueries.add(query);
    if (throwError != null) throw throwError!;
    return handler?.call(query) ?? const [];
  };
}

void main() {
  group('W2.2 production sources — projection', () {
    test(
      'knowledge adapter projects matching topics via the repository',
      () async {
        final repo = _FakeEncyclopediaRepository(
          topics: [
            _topic('t1', 'فحص الخرسانة', tags: const ['خرسانة']),
            _topic('t2', 'خلط الخرسانة', tags: const ['خرسانة']),
            _topic('t3', 'حديد التسليح', tags: const ['حديد']),
          ],
        );
        final results = await knowledgeSearchSource(repo)('خرسانة');

        expect(results, hasLength(2));
        for (final r in results) {
          expect(r.type, SearchResultType.knowledge);
          expect(r.id, anyOf('t1', 't2'));
          expect(r.subtitle, isNotNull);
        }
        // Reuses the repository — the authoritative search boundary was called.
        expect(repo.searchCalls, 1);
      },
    );

    test(
      'tools adapter surfaces the authoritative registry as ToolKey ids',
      () async {
        final results = await toolsSearchSource()('');

        // Exactly the 5 supported production tools, projected with ToolKey ids.
        expect(results.map((r) => r.id).toSet(), {
          for (final key in ToolKey.values) key.stableId,
        });
        for (final r in results) {
          expect(r.type, SearchResultType.tool);
          expect(r.id.startsWith('/'), isFalse, reason: r.id);
          expect(r.id.startsWith('calculator/'), isFalse, reason: r.id);
          expect(r.subtitle, isNotNull);
        }
      },
    );

    test('tools adapter filters by name/description', () async {
      final results = await toolsSearchSource()('الحديد');
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r.type, SearchResultType.tool);
        expect(
          '${r.id} ${r.title} ${r.subtitle}'.contains('الحديد') ||
              '${r.title} ${r.subtitle}'.toLowerCase().contains(
                'الحديد'.toLowerCase(),
              ),
          isTrue,
        );
      }
    });

    test('tools adapter returns empty for a non-matching query', () async {
      final results = await toolsSearchSource()('x-not-found');
      expect(results, isEmpty);
    });
  });

  group('W2.2 aggregator — successful aggregation', () {
    SearchResult know(String id, String title) =>
        SearchResult(id: id, type: SearchResultType.knowledge, title: title);
    SearchResult tool(ToolKey key) => SearchResult(
      id: key.stableId,
      type: SearchResultType.tool,
      title: key.stableId,
    );

    test('both domains succeed → combined results with both types', () async {
      final knowledge = _ScriptableSource()
        ..handler = (_) => [know('k1', 'أ'), know('k2', 'ب')];
      final tools = _ScriptableSource()
        ..handler = (_) => [tool(ToolKey.concrete), tool(ToolKey.steel)];

      final aggregator = SearchAggregator(
        knowledgeSource: knowledge.source,
        toolsSource: tools.source,
      );
      final results = await aggregator.search('خرسانة');

      expect(results, hasLength(4));
      expect(
        results.where((r) => r.type == SearchResultType.knowledge),
        hasLength(2),
      );
      expect(
        results.where((r) => r.type == SearchResultType.tool),
        hasLength(2),
      );
      // Deterministic order: Knowledge first, then Tools.
      expect(results[0].type, SearchResultType.knowledge);
      expect(results[3].type, SearchResultType.tool);
    });

    test('per-domain ordering is preserved within each domain', () async {
      final knowledge = _ScriptableSource()
        ..handler = (_) => [know('a', 'x'), know('b', 'y')];
      final tools = _ScriptableSource()
        ..handler = (_) => [tool(ToolKey.tile), tool(ToolKey.brick)];

      final aggregator = SearchAggregator(
        knowledgeSource: knowledge.source,
        toolsSource: tools.source,
      );
      final results = await aggregator.search('q');

      expect(results.sublist(0, 2).map((r) => r.id).toList(), ['a', 'b']);
      expect(results.sublist(2, 4).map((r) => r.id).toList(), [
        ToolKey.tile.stableId,
        ToolKey.brick.stableId,
      ]);
    });

    test('results carry no domain entity ownership and no raw route', () async {
      final knowledge = _ScriptableSource()..handler = (_) => [know('k1', 'أ')];
      final tools = _ScriptableSource()
        ..handler = (_) => [tool(ToolKey.concrete)];

      final aggregator = SearchAggregator(
        knowledgeSource: knowledge.source,
        toolsSource: tools.source,
      );
      final results = await aggregator.search('q');

      for (final r in results) {
        expect(r.type, isA<SearchResultType>());
        expect(r.title, isA<String>());
        if (r.type == SearchResultType.tool) {
          expect(r.id.startsWith('/'), isFalse);
          expect(r.id.startsWith('calculator/'), isFalse);
        }
      }
    });
  });

  group('W2.2 aggregator — per-domain failure isolation', () {
    SearchResult know(String id) =>
        SearchResult(id: id, type: SearchResultType.knowledge, title: id);
    SearchResult tool(ToolKey k) => SearchResult(
      id: k.stableId,
      type: SearchResultType.tool,
      title: k.stableId,
    );

    test(
      'Knowledge throws + Tools succeeds → Tools results returned',
      () async {
        final knowledge = _ScriptableSource()
          ..throwError = StateError('k fail');
        final tools = _ScriptableSource()
          ..handler = (_) => [tool(ToolKey.tile)];

        final aggregator = SearchAggregator(
          knowledgeSource: knowledge.source,
          toolsSource: tools.source,
        );
        final results = await aggregator.search('q');

        expect(results, hasLength(1));
        expect(results.single.type, SearchResultType.tool);
        expect(results.single.id, ToolKey.tile.stableId);
      },
    );

    test(
      'Tools throws + Knowledge succeeds → Knowledge results returned',
      () async {
        final knowledge = _ScriptableSource()..handler = (_) => [know('k1')];
        final tools = _ScriptableSource()..throwError = Exception('t fail');

        final aggregator = SearchAggregator(
          knowledgeSource: knowledge.source,
          toolsSource: tools.source,
        );
        final results = await aggregator.search('q');

        expect(results, hasLength(1));
        expect(results.single.type, SearchResultType.knowledge);
        expect(results.single.id, 'k1');
      },
    );

    test(
      'a failing domain does not prevent the healthy source being queried',
      () async {
        final knowledge = _ScriptableSource()
          ..throwError = StateError('k fail');
        final tools = _ScriptableSource()
          ..handler = (_) => [tool(ToolKey.brick)];

        final aggregator = SearchAggregator(
          knowledgeSource: knowledge.source,
          toolsSource: tools.source,
        );
        await aggregator.search('q');

        expect(
          tools.calls,
          1,
          reason: 'healthy Tools source must still be called',
        );
        expect(knowledge.calls, 1);
      },
    );

    test('both domains fail → controlled empty result, no crash', () async {
      final knowledge = _ScriptableSource()..throwError = StateError('k');
      final tools = _ScriptableSource()..throwError = Exception('t');

      final aggregator = SearchAggregator(
        knowledgeSource: knowledge.source,
        toolsSource: tools.source,
      );
      final results = await aggregator.search('q');

      expect(results, isEmpty);
      // Both were still individually attempted.
      expect(knowledge.calls, 1);
      expect(tools.calls, 1);
    });
  });

  group('W2.2 aggregator — query behavior', () {
    test('query reaches both sources unchanged (same trimmed value)', () async {
      final knowledge = _ScriptableSource();
      final tools = _ScriptableSource();

      final aggregator = SearchAggregator(
        knowledgeSource: knowledge.source,
        toolsSource: tools.source,
      );
      await aggregator.search('  فحص الخرسانة  ');

      expect(knowledge.receivedQueries, ['فحص الخرسانة']);
      expect(tools.receivedQueries, ['فحص الخرسانة']);
    });

    test(
      'empty and whitespace-only query → both sources still queried',
      () async {
        for (final raw in ['', '   ']) {
          final knowledge = _ScriptableSource();
          final tools = _ScriptableSource();
          final aggregator = SearchAggregator(
            knowledgeSource: knowledge.source,
            toolsSource: tools.source,
          );
          final results = await aggregator.search(raw);
          expect(results, isEmpty);
          expect(knowledge.calls, 1, reason: 'raw="$raw"');
          expect(tools.calls, 1, reason: 'raw="$raw"');
        }
      },
    );

    test('empty query surfaces all supported tools from the registry', () async {
      // Aligns with established "empty search shows everything" semantics.
      final knowledge = _ScriptableSource()
        ..handler = (_) => const <SearchResult>[];

      final aggregator = SearchAggregator(
        knowledgeSource: knowledge.source,
        // use the real tools adapter so "empty → all" is proven against registry
        toolsSource: toolsSearchSource(),
      );
      final results = await aggregator.search('');

      expect(
        results.where((r) => r.type == SearchResultType.tool),
        hasLength(ToolKey.values.length),
      );
    });
  });

  group('W2.2 scope protection', () {
    test('only knowledge and tool result types exist', () {
      expect(SearchResultType.values.toSet(), {
        SearchResultType.knowledge,
        SearchResultType.tool,
      });
    });

    test('no raw tool route is stored in any SearchResult', () async {
      final results = await toolsSearchSource()('');
      for (final r in results) {
        expect(r.id.startsWith('/'), isFalse);
        expect(r.id.startsWith('calculator/'), isFalse);
        expect(
          ToolKey.values.map((k) => k.stableId).contains(r.id),
          isTrue,
          reason: 'tool id must be a ToolKey.stableId',
        );
      }
    });
  });
}
