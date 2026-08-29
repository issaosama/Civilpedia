import 'dart:async';

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
/// plain root-level `/search` route with a fake aggregator injected.
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

/// Records every trimmed query each domain source receives (one entry per
/// source per aggregator run, so a single search records two entries).
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

/// Gated aggregator: each query's search only completes when its gate is
/// completed manually, so tests can exercise stale-result ordering exactly.
SearchAggregator _gatedAggregator(
  Map<String, Completer<List<SearchResult>>> gates,
  List<String> log,
) {
  return SearchAggregator(
    knowledgeSource: (q) async {
      log.add('k:$q');
      final results = await gates[q]!.future;
      return results
          .where((r) => r.type == SearchResultType.knowledge)
          .toList();
    },
    toolsSource: (q) async {
      log.add('t:$q');
      final results = await gates[q]!.future;
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

/// Types a live query and lets the debounce elapse deterministically.
Future<void> _type(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

/// Simulates the (optional) keyboard search action on the current text.
Future<void> _submitCurrent(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pump(const Duration(milliseconds: 300));
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

  testWidgets('/search SearchBar receives focus and is ready for typing', (
    tester,
  ) async {
    final router = _buildTestRouter(
      aggregator: _fakeAggregator(const [
        SearchResult(
          id: 't1',
          type: SearchResultType.knowledge,
          title: 'الخرسانة',
        ),
      ]),
    );
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    final editable = tester.state<EditableTextState>(find.byType(EditableText));
    expect(editable.widget.focusNode.hasFocus, isTrue);

    await _type(tester, 'خرسانة');
    expect(find.widgetWithText(CivilSurfaceCard, 'الخرسانة'), findsOneWidget);
  });

  testWidgets('typing triggers search automatically without a submit press', (
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

    // No keyboard search action is dispatched — purely typing.
    await _type(tester, 'خرسانة');
    expect(queries, isNotEmpty);
    expect(queries.where((q) => q == 'خرسانة').length, 2);
    expect(find.widgetWithText(CivilSurfaceCard, 'الخرسانة'), findsOneWidget);
  });

  testWidgets('debounce coalesces quick keystrokes into one search', (
    tester,
  ) async {
    final queries = <String>[];
    final router = _buildTestRouter(
      aggregator: _fakeAggregator(const [], queries: queries),
    );
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    await tester.enterText(find.byType(TextField), 'خ');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'خر');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'خرس');
    await tester.pump(const Duration(milliseconds: 100));

    // No keystroke was separated long enough on its own; nothing ran yet.
    expect(queries, isEmpty);

    // After the typing pause, exactly one aggregator run happens.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(queries, ['خرس', 'خرس']);
  });

  testWidgets('latest query wins over stale async results', (tester) async {
    final log = <String>[];
    final gates = <String, Completer<List<SearchResult>>>{
      'خر': Completer<List<SearchResult>>(),
      'خرسانة': Completer<List<SearchResult>>(),
    };
    final router = _buildTestRouter(aggregator: _gatedAggregator(gates, log));
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    // First query's search hangs on its gate.
    await tester.enterText(find.byType(TextField), 'خر');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(log, contains('k:خر'));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // User quickly types the fuller query; its search is also gated.
    await tester.enterText(find.byType(TextField), 'خرسانة');
    await tester.pump(const Duration(milliseconds: 300));
    expect(log, contains('k:خرسانة'));

    // The NEWER query completes and renders.
    gates['خرسانة']!.complete(const [
      SearchResult(
        id: 't1',
        type: SearchResultType.knowledge,
        title: 'الخرسانة',
        subtitle: 'الحديثة',
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('الخرسانة'), findsOneWidget);

    // The OLDER 'خر' search now finishes LATE; it must not overwrite results.
    gates['خر']!.complete(const [
      SearchResult(
        id: 't2',
        type: SearchResultType.knowledge,
        title: 'نتيجة قديمة',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('نتيجة قديمة'), findsNothing);
    expect(find.text('الخرسانة'), findsOneWidget);
  });

  testWidgets('empty/whitespace query performs no search and restores prompt', (
    tester,
  ) async {
    final queries = <String>[];
    final router = _buildTestRouter(
      aggregator: _fakeAggregator(const [
        SearchResult(
          id: 't1',
          type: SearchResultType.knowledge,
          title: 'الخرسانة',
        ),
      ], queries: queries),
    );
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    await _type(tester, 'خرسانة');
    expect(find.widgetWithText(CivilSurfaceCard, 'الخرسانة'), findsOneWidget);
    expect(queries.length, 2);

    // Clearing to empty cancels the debounce, skips the aggregator, clears
    // results and restores the initial prompt.
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(queries.length, 2);
    expect(find.text(Ar.initialSearchPrompt), findsOneWidget);
    expect(find.widgetWithText(CivilSurfaceCard, 'الخرسانة'), findsNothing);

    // Whitespace-only behaves identically.
    await _type(tester, 'خرسانة');
    expect(find.widgetWithText(CivilSurfaceCard, 'الخرسانة'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(queries.length, 4);
    expect(find.text(Ar.initialSearchPrompt), findsOneWidget);
    expect(find.widgetWithText(CivilSurfaceCard, 'الخرسانة'), findsNothing);
  });

  testWidgets('keyboard search action remains a harmless submit fallback', (
    tester,
  ) async {
    final queries = <String>[];
    final router = _buildTestRouter(
      aggregator: _fakeAggregator(const [
        SearchResult(
          id: 't1',
          type: SearchResultType.knowledge,
          title: 'الخرسانة',
        ),
      ], queries: queries),
    );
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    await tester.enterText(find.byType(TextField), 'خرسانة');
    await _submitCurrent(tester);

    expect(queries.where((q) => q == 'خرسانة').length, 2);
    expect(find.text('الخرسانة'), findsOneWidget);
  });

  testWidgets('non-empty query with no results shows the no-results message', (
    tester,
  ) async {
    final router = _buildTestRouter(aggregator: _fakeAggregator(const []));
    await _pumpRouter(tester, router);

    await _openSearch(tester, router);

    await _type(tester, 'لا شيء');
    expect(find.text(Ar.noSearchResults), findsOneWidget);
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

    await _type(tester, 'بحث');

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

    await _type(tester, 'موضوع');
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

    await _type(tester, 'خرسانة');
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

    await _type(tester, 'بحث');
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

    await _type(tester, 'موضوع');
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

  group('W2.4 refinement — launcher + live search contract', () {
    testWidgets('no /search?q= dependency remains (q is ignored)', (
      tester,
    ) async {
      final queries = <String>[];
      final router = _buildTestRouter(
        aggregator: _fakeAggregator(const [], queries: queries),
      );
      await _pumpRouter(tester, router);

      // A leftover q parameter has no effect: Home no longer forwards queries.
      router.push('${AppRoutes.search}?q=${Uri.encodeComponent('خرسانة')}');
      await tester.pumpAndSettle();

      expect(find.byType(GlobalSearchScreen), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
      expect(find.text(Ar.initialSearchPrompt), findsOneWidget);
      expect(queries, isEmpty);
    });

    testWidgets('Home → /search → result → Back → /search → Back → Home', (
      tester,
    ) async {
      final router = _buildTestRouter(
        aggregator: _fakeAggregator(const [
          SearchResult(
            id: 'k1',
            type: SearchResultType.knowledge,
            title: 'الخرسانة',
          ),
        ]),
      );
      await _pumpRouter(tester, router);

      expect(find.byKey(const ValueKey('probe-/home')), findsOneWidget);

      // Home launcher push → root /search (single level, no q forwarding).
      await _openSearch(tester, router);
      expect(find.byType(AppShell), findsNothing);
      expect(find.byType(GlobalSearchScreen), findsOneWidget);

      await _type(tester, 'خرسانة');
      await _tapResult(tester, 'الخرسانة');
      expect(find.text('topic-detail:k1'), findsOneWidget);

      // Result → Back → Global Search.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(GlobalSearchScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);

      // /search → Back → Home above the shell.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byKey(const ValueKey('probe-/home')), findsOneWidget);
    });
  });
}
