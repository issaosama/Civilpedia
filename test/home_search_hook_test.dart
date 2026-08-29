import 'package:civilpedia/core/widgets/search_bar_widget.dart';
import 'package:civilpedia/features/search/domain/search_aggregator.dart';
import 'package:civilpedia/features/search/domain/search_result.dart';
import 'package:civilpedia/features/search/presentation/screens/global_search_screen.dart';
import 'package:civilpedia/features/home/presentation/home_main_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

/// Mirrors how HomeMainScreen wires its search launcher: the shared
/// [SearchBarWidget] is read-only on Home and its tap opens [openHomeSearch].
class _SearchHarness extends StatelessWidget {
  const _SearchHarness();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SearchBarWidget(
            hintText: Ar.homeEngineeringSearchHint,
            readOnly: true,
            onTap: () => openHomeSearch(context),
          ),
        ),
      ),
    );
  }
}

/// Records every trimmed query each domain source receives.
SearchAggregator _recordingAggregator(List<String> log) => SearchAggregator(
  knowledgeSource: (q) async {
    log.add(q);
    return const <SearchResult>[];
  },
  toolsSource: (q) async {
    log.add(q);
    return const <SearchResult>[];
  },
);

/// Production-shaped routing: the harness lives at `/` (Home stand-in) and the
/// plain root-level `/search` route builds Global Search in its empty state.
GoRouter _router({required SearchAggregator aggregator}) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _SearchHarness()),
      GoRoute(
        path: AppRoutes.search,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => GlobalSearchScreen(aggregator: aggregator),
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, GoRouter router) async {
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

Uri _currentUri(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(GlobalSearchScreen))).state.uri;

void main() {
  group('W2.4 openHomeSearch — Home launcher → root Global Search', () {
    testWidgets('Home search surface is read-only and needs no text entry', (
      tester,
    ) async {
      final router = _router(aggregator: _recordingAggregator([]));
      await _pump(tester, router);

      final homeField = tester.widget<TextField>(find.byType(TextField));
      expect(homeField.readOnly, isTrue);
      expect(homeField.decoration?.hintText, Ar.homeEngineeringSearchHint);
      expect(homeField.controller, isNull);
    });

    testWidgets(
      'tapping the Home search surface opens root /search immediately',
      (tester) async {
        final log = <String>[];
        final router = _router(aggregator: _recordingAggregator(log));
        await _pump(tester, router);

        expect(find.byType(GlobalSearchScreen), findsNothing);

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        // Opened the plain canonical route with NO query forwarded.
        expect(find.byType(GlobalSearchScreen), findsOneWidget);
        expect(_currentUri(tester).path, AppRoutes.search);
        expect(_currentUri(tester).queryParameters, isEmpty);
        expect(log, isEmpty);
      },
    );

    testWidgets('nothing is typed or entered on Home (launcher only)', (
      tester,
    ) async {
      final router = _router(aggregator: _recordingAggregator([]));
      await _pump(tester, router);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // The /search field starts empty: the user types only inside Global
      // Search, so nothing was forwarded or auto-searched.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
      expect(find.text(Ar.initialSearchPrompt), findsOneWidget);
    });

    testWidgets('Back from Global Search returns Home', (tester) async {
      final router = _router(aggregator: _recordingAggregator([]));
      await _pump(tester, router);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.byType(GlobalSearchScreen), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(GlobalSearchScreen), findsNothing);
      expect(find.byType(_SearchHarness), findsOneWidget);
    });
  });
}
