import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/features/search/domain/search_result.dart';
import 'package:civilpedia/features/search/navigation/search_route_resolver.dart';
import 'package:civilpedia/features/tools/domain/tool_key.dart';
import 'package:civilpedia/routes/app_routes.dart';

void main() {
  const resolver = SearchRouteResolver();

  group('SearchResultType — typed V1 domains', () {
    test('distinguishes the supported V1 source domains', () {
      expect(SearchResultType.values, [
        SearchResultType.knowledge,
        SearchResultType.tool,
      ]);
      expect(SearchResultType.knowledge, isNot(SearchResultType.tool));
    });

    test('has no Projects/Directory/Future types in V1 shape', () {
      // W2 Global Search V1 searches Knowledge + Tools only.
      final names = SearchResultType.values.map((t) => t.name).toSet();
      expect(names, {'knowledge', 'tool'});
    });
  });

  group('SearchResult — lightweight projection', () {
    test('represents a Knowledge result without owning an EngineeringTopic', () {
      const topicId = 'concrete-inspection';
      const result = SearchResult(
        id: topicId,
        type: SearchResultType.knowledge,
        title: 'فحص الخرسانة',
        subtitle: 'إجراءات الفحص الموقعية',
      );

      expect(result.id, topicId);
      expect(result.type, SearchResultType.knowledge);
      expect(result.title, 'فحص الخرسانة');
      expect(result.subtitle, 'إجراءات الفحص الموقعية');
      // No EngineeringTopic instance is required; the projection stands alone.
    });

    test(
      'represents a Tool result using ToolKey identity, not a raw route',
      () {
        final key = ToolKey.concrete;
        final result = SearchResult(
          id: key.stableId,
          type: SearchResultType.tool,
          title: 'حاسبة الخرسانة',
        );

        expect(result.type, SearchResultType.tool);
        expect(result.id, key.stableId);
        // The projection's identity is the ToolKey stable id, never a route.
        expect(result.id.startsWith('calculator/'), isFalse);
        expect(result.id.startsWith('/'), isFalse);
      },
    );

    test('value equality and hashCode', () {
      const a = SearchResult(
        id: 'x',
        type: SearchResultType.tool,
        title: 'T',
        subtitle: 'S',
      );
      const b = SearchResult(
        id: 'x',
        type: SearchResultType.tool,
        title: 'T',
        subtitle: 'S',
      );
      const c = SearchResult(
        id: 'x',
        type: SearchResultType.tool,
        title: 'Other',
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
      expect(a.hashCode, isNot(c.hashCode));
    });

    test('optional subtitle defaults to null', () {
      const r = SearchResult(
        id: 'y',
        type: SearchResultType.knowledge,
        title: 'Y',
      );
      expect(r.subtitle, isNull);
    });
  });

  group('SearchRouteResolver — typed resolution', () {
    test('every supported ToolKey resolves to the correct canonical route', () {
      const cases = <ToolKey, String>{
        ToolKey.concrete: AppRoutes.calculatorConcrete,
        ToolKey.steel: AppRoutes.calculatorSteel,
        ToolKey.brick: AppRoutes.calculatorBrick,
        ToolKey.checklist: AppRoutes.calculatorChecklist,
        ToolKey.tile: AppRoutes.calculatorTile,
      };

      for (final entry in cases.entries) {
        expect(
          resolver.toolRoute(entry.key),
          entry.value,
          reason: '${entry.key.stableId} should map to ${entry.value}',
        );
      }
    });

    test('typed tool result resolves via ToolKey stable id', () {
      for (final key in ToolKey.values) {
        final route = resolver.routeFor(
          type: SearchResultType.tool,
          id: key.stableId,
        );
        expect(route, resolver.toolRoute(key));
        expect(route, isNotNull);
      }
    });

    test('unknown tool id resolves safely to null', () {
      expect(
        resolver.routeFor(type: SearchResultType.tool, id: 'not-a-tool'),
        isNull,
      );
    });

    test(
      'knowledge result resolves via the canonical Knowledge route contract',
      () {
        const topicId = 'concrete-inspection';
        final route = resolver.routeFor(
          type: SearchResultType.knowledge,
          id: topicId,
        );
        // Reuses AppRoutes.topicDetailFor — the existing canonical helper.
        expect(route, AppRoutes.topicDetailFor(topicId));
        expect(route, '/encyclopedia/topic/$topicId');
      },
    );
  });

  group('SearchRouteResolver — compatibility edge (legacy raw routes)', () {
    test(
      'maps every registry-form raw route (no leading slash) to ToolKey',
      () {
        // exact spellings used by ArticleRepository.tools -> ToolModel.route
        const cases = <String, ToolKey>{
          'calculator/concrete': ToolKey.concrete,
          'calculator/steel': ToolKey.steel,
          'calculator/brick': ToolKey.brick,
          'calculator/checklist': ToolKey.checklist,
          'calculator/tile': ToolKey.tile,
        };

        for (final entry in cases.entries) {
          expect(
            resolver.toolKeyFromLegacyRoute(entry.key),
            entry.value,
            reason: '${entry.key} should map to ${entry.value.stableId}',
          );
        }
      },
    );

    test('maps content-form raw routes (leading slash) to ToolKey', () {
      // exact spelling used by relatedToolRoutes in content (e.g. '/calculator/concrete')
      for (final key in ToolKey.values) {
        final route = '/calculator/${key.stableId}';
        expect(resolver.toolKeyFromLegacyRoute(route), key);
      }
    });

    test(
      'compat boundary resolves legacy routes to canonical destinations',
      () {
        for (final key in ToolKey.values) {
          for (final raw in [
            'calculator/${key.stableId}',
            '/calculator/${key.stableId}',
          ]) {
            expect(
              resolver.routeFromLegacyToolRoute(raw),
              resolver.toolRoute(key),
              reason: '$raw should resolve for ${key.stableId}',
            );
          }
        }
      },
    );

    test('unknown legacy route resolves safely and explicitly to null', () {
      for (final raw in [
        'calculator/excavator',
        '/calculator/nonexistent',
        'calculator/',
        'tools',
        '/tools',
        'somewhere/else',
        '/search',
      ]) {
        expect(resolver.toolKeyFromLegacyRoute(raw), isNull, reason: raw);
        expect(resolver.routeFromLegacyToolRoute(raw), isNull, reason: raw);
      }
    });

    test('does not require generated encyclopedia content', () {
      // Pure typed resolution and legacy mapping; no data source is touched.
      expect(
        resolver.routeFor(type: SearchResultType.knowledge, id: 'any-topic'),
        AppRoutes.topicDetailFor('any-topic'),
      );
      expect(
        resolver.routeFromLegacyToolRoute('/calculator/tile'),
        AppRoutes.calculatorTile,
      );
    });

    test('never produces a /search route', () {
      final allRoutes = <String?>[
        for (final key in ToolKey.values) resolver.toolRoute(key),
        resolver.routeFor(type: SearchResultType.knowledge, id: 't'),
        resolver.routeFromLegacyToolRoute('/calculator/concrete'),
      ];
      for (final route in allRoutes) {
        expect(route, isNot('/search'));
        expect(route, isNotNull);
      }
    });
  });
}
