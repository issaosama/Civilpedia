import 'package:civilpedia/features/home/presentation/widgets/quick_access_section.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _quickAccessRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: QuickAccessSection()),
      ),
      GoRoute(
        path: '/encyclopedia',
        builder: (_, __) => const Scaffold(body: Text('Encyclopedia screen')),
      ),
      GoRoute(
        path: '/tools',
        builder: (_, __) => const Scaffold(body: Text('Tools screen')),
      ),
      GoRoute(
        path: '/articles',
        builder: (_, __) => const Scaffold(body: Text('Articles screen')),
      ),
      GoRoute(
        path: '/saved',
        builder: (_, __) => const Scaffold(body: Text('Saved screen')),
      ),
    ],
  );
}

void main() {
  group('QuickAccessSection', () {
    testWidgets('renders four real destination cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: _quickAccessRouter()),
      );
      await tester.pumpAndSettle();

      expect(find.text(Ar.encyclopedia), findsOneWidget);
      expect(find.text(Ar.tools), findsOneWidget);
      expect(find.text(Ar.articles), findsOneWidget);
      expect(find.text(Ar.saved), findsOneWidget);

      expect(find.text(Ar.engineeringKnowledge), findsOneWidget);
      expect(find.text(Ar.calculatorsAndTools), findsOneWidget);
      expect(find.text(Ar.latestArticles), findsOneWidget);
      expect(find.text(Ar.savedItems), findsOneWidget);
    });

    testWidgets('tapping Encyclopedia switches to the encyclopedia branch', (tester) async {
      final router = _quickAccessRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text(Ar.encyclopedia));
      await tester.pumpAndSettle();

      expect(find.text('Encyclopedia screen'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/encyclopedia');
    });

    testWidgets('tapping Tools switches to the tools branch', (tester) async {
      final router = _quickAccessRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text(Ar.tools));
      await tester.pumpAndSettle();

      expect(find.text('Tools screen'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/tools');
    });

    testWidgets('tapping Saved switches to the saved branch', (tester) async {
      final router = _quickAccessRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text(Ar.saved));
      await tester.pumpAndSettle();

      expect(find.text('Saved screen'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/saved');
    });

    testWidgets('tapping Articles pushes the articles list screen', (tester) async {
      final router = _quickAccessRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text(Ar.articles));
      await tester.pumpAndSettle();

      expect(find.text('Articles screen'), findsOneWidget);
    });
  });
}
