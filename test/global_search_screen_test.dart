import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/widgets/civil_surface_card.dart';
import 'package:civilpedia/features/search/domain/search_aggregator.dart';
import 'package:civilpedia/features/search/domain/search_result.dart';
import 'package:civilpedia/features/search/presentation/screens/global_search_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/routes/app_routes.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

/// Probe shell branch so the routing contract can be asserted without pulling
/// heavyweight feature providers.
class _BranchProbe extends StatelessWidget {
  final String label;
  const _BranchProbe({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Text('probe:$label', key: ValueKey('probe-$label')),
    );
  }
}

/// Mirrors production routing: shell branches from kShellDestinations plus the
/// root-level `/search` route with a fake aggregator injected.
GoRouter _buildTestRouter({required SearchAggregator aggregator}) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          for (final destination in kShellDestinations)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: destination.route,
                  builder: (_, __) => _BranchProbe(label: destination.route),
                ),
              ],
            ),
        ],
      ),
      GoRoute(
        path: AppRoutes.search,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => GlobalSearchScreen(aggregator: aggregator),
      ),
      GoRoute(
        path: '/encyclopedia/topic/:topicId',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => Scaffold(
          appBar: AppBar(),
          body: Text('topic-detail:${state.pathParameters['topicId']}'),
        ),
      ),
      for (final tool in const [
        AppRoutes.calculatorConcrete,
        AppRoutes.calculatorSteel,
        AppRoutes.calculatorBrick,
        AppRoutes.calculatorChecklist,
        AppRoutes.calculatorTile,
      ])
        GoRoute(
          path: tool,
          parentNavigatorKey: _rootKey,
          builder: (context, state) => Scaffold(body: Text('tool:$tool')),
        ),
    ],
  );
}

SearchAggregator _fakeAggregator(
  List<SearchResult> results, {
  List<String>? queries,
}) {
  return SearchAggregator(
    knowledgeSource: (q) async {
      queries?.add(q);
      return results
          .where((r) => r.type == SearchResultType.knowledge)
          .toList();
    },
    toolsSource: (q) async {
      queries?.add(q);
      return results.where((r) => r.type == SearchResultType.tool).toList();
    },
  );
}

Future<void> _pumpRouter(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    MaterialApp.router(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _searchFor(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

/// Navigate to `/search` via push (mirrors Home/Header → /search) so the
/// root-pushed back stack is exercised, matching production.
Future<void> _openSearch(WidgetTester tester, GoRouter router) async {
  router.push(AppRoutes.search);
  await tester.pumpAndSettle();
}

/// Taps a result tile by its title (scoped to the tile to disambiguate from the
/// search field text when they collide).
Future<void> _tapResult(WidgetTester tester, String title) async {
  await tester.tap(find.widgetWithText(CivilSurfaceCard, title));
  await tester.pumpAndSettle();
}

void main() {
  test('AppRoutes.search is the canonical root path /search', () {
    expect(AppRoutes.search, '/search');
  });

  test('/search is NOT a bottom-navigation shell destination', () {
    final routes = kShellDestinations.map((d) => d.route).toList();
    expect(routes, isNot(contains(AppRoutes.search)));
  });

  testWidgets('renders the shared SearchBarWidget with the global hint', (
    tester,
  ) async {
    final router = _buildTestRouter(aggregator: _fakeAggregator(const []));
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    expect(find.byType(GlobalSearchScreen), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == Ar.globalSearchHint,
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    '/search renders above the shell (no bottom nav) and Back restores',
    (tester) async {
      final router = _buildTestRouter(aggregator: _fakeAggregator(const []));
      await _pumpRouter(tester, router);

      expect(find.byKey(const ValueKey('probe-/home')), findsOneWidget);
      expect(find.byType(AppShell), findsOneWidget);

      await _openSearch(tester, router);

      expect(find.byType(GlobalSearchScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byKey(const ValueKey('probe-/home')), findsOneWidget);
    },
  );

  testWidgets('empty query shows the initial search prompt', (tester) async {
    final router = _buildTestRouter(aggregator: _fakeAggregator(const []));
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    expect(find.text(Ar.initialSearchPrompt), findsOneWidget);
    expect(find.text(Ar.noSearchResults), findsNothing);
  });

  testWidgets('non-empty query with no results shows the no-results message', (
    tester,
  ) async {
    final router = _buildTestRouter(aggregator: _fakeAggregator(const []));
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    await _searchFor(tester, 'لا شيء');
    expect(find.text(Ar.noSearchResults), findsOneWidget);
  });

  testWidgets('submitting a query invokes the aggregator and shows results', (
    tester,
  ) async {
    final queries = <String>[];
    final router = _buildTestRouter(
      aggregator: _fakeAggregator(const [
        SearchResult(
          id: 't1',
          type: SearchResultType.knowledge,
          title: 'الخرسانة',
          subtitle: 'نظرة عامة',
        ),
      ], queries: queries),
    );
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    await _searchFor(tester, '  خرسانة  ');
    expect(queries, contains('خرسانة'));
    expect(find.text('الخرسانة'), findsOneWidget);
  });

  testWidgets('unified Knowledge then Tools list in aggregator order', (
    tester,
  ) async {
    final router = _buildTestRouter(
      aggregator: _fakeAggregator(const [
        SearchResult(
          id: 'k1',
          type: SearchResultType.knowledge,
          title: 'موضوع أول',
        ),
        SearchResult(
          id: 'k2',
          type: SearchResultType.knowledge,
          title: 'موضوع ثان',
        ),
        SearchResult(
          id: 'concrete',
          type: SearchResultType.tool,
          title: 'حاسبة الخرسانة',
        ),
      ]),
    );
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    await _searchFor(tester, 'بحث');

    expect(find.text('موضوع أول'), findsOneWidget);
    expect(find.text('موضوع ثان'), findsOneWidget);
    expect(find.text('حاسبة الخرسانة'), findsOneWidget);

    final first = tester.getTopLeft(find.text('موضوع أول'));
    final second = tester.getTopLeft(find.text('موضوع ثان'));
    final third = tester.getTopLeft(find.text('حاسبة الخرسانة'));
    expect(first.dy, lessThan(second.dy));
    expect(second.dy, lessThan(third.dy));
  });

  testWidgets('Knowledge result tap navigates to canonical topic detail', (
    tester,
  ) async {
    final router = _buildTestRouter(
      aggregator: _fakeAggregator(const [
        SearchResult(
          id: 'k9',
          type: SearchResultType.knowledge,
          title: 'موضوع',
        ),
      ]),
    );
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    await _searchFor(tester, 'موضوع');
    await _tapResult(tester, 'موضوع');

    expect(find.text('topic-detail:k9'), findsOneWidget);
  });

  testWidgets('Tool result tap navigates to canonical calculator route', (
    tester,
  ) async {
    final router = _buildTestRouter(
      aggregator: _fakeAggregator(const [
        SearchResult(
          id: 'concrete',
          type: SearchResultType.tool,
          title: 'خرسانة',
        ),
      ]),
    );
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    await _searchFor(tester, 'خرسانة');
    await _tapResult(tester, 'خرسانة');

    expect(find.text('tool:${AppRoutes.calculatorConcrete}'), findsOneWidget);
  });

  testWidgets('unresolved tool id renders but does not navigate or crash', (
    tester,
  ) async {
    final router = _buildTestRouter(
      aggregator: _fakeAggregator(const [
        SearchResult(
          id: 'unknown-tool',
          type: SearchResultType.tool,
          title: 'أداة غامضة',
        ),
        SearchResult(
          id: 'k1',
          type: SearchResultType.knowledge,
          title: 'موضوع',
        ),
      ]),
    );
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    await _searchFor(tester, 'بحث');
    expect(find.text('أداة غامضة'), findsOneWidget);

    await _tapResult(tester, 'أداة غامضة');

    expect(find.byType(GlobalSearchScreen), findsOneWidget);
    expect(find.text('موضوع'), findsOneWidget);
  });

  testWidgets('Back from a resolved result returns to /search', (tester) async {
    final router = _buildTestRouter(
      aggregator: _fakeAggregator(const [
        SearchResult(
          id: 'k1',
          type: SearchResultType.knowledge,
          title: 'موضوع',
        ),
      ]),
    );
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    await _searchFor(tester, 'موضوع');
    await _tapResult(tester, 'موضوع');
    expect(find.text('topic-detail:k1'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(GlobalSearchScreen), findsOneWidget);
    expect(find.text('topic-detail:k1'), findsNothing);
  });

  testWidgets('search bar is direction-aware (RTL) on the result screen', (
    tester,
  ) async {
    final router = _buildTestRouter(aggregator: _fakeAggregator(const []));
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    expect(
      Directionality.of(tester.element(find.byType(TextField))),
      TextDirection.rtl,
    );
  });
}
