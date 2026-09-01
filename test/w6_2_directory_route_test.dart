import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/di/app_dependencies.dart';
import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/core/widgets/civil_surface_card.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/directory/presentation/directory_landing_screen.dart';
import 'package:civilpedia/features/directory/presentation/directory_search_screen.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/routes/app_router.dart';
import 'package:civilpedia/routes/app_routes.dart';
import 'package:civilpedia/routes/not_found_screen.dart';

/// Test path-provider stub so [AppDependencies.init] resolves a real documents
/// dir without touching platform channels.
class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    final dir = Directory.systemTemp.createTempSync('civilpedia_w6_2');
    return dir.path;
  }
}

Widget _app() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ],
    child: MaterialApp.router(routerConfig: appRouter),
  );
}

Future<void> _open(WidgetTester tester, String path) async {
  appRouter.go(path);
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
}

String _currentPath() => appRouter.routerDelegate.currentConfiguration.uri.path;

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PathProviderPlatform.instance = _FakePathProvider();
    await AppDependencies.init();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('W6.2 AppRoutes.directory is the canonical /directory path', () {
    expect(AppRoutes.directory, '/directory');
  });

  test('W6.2 AppRoutes.directorySearch is /directory/search', () {
    expect(AppRoutes.directorySearch, '/directory/search');
  });

  test('W6.3 Directory IS a Bottom Navigation destination at index 4', () {
    final routes = kShellDestinations.map((d) => d.route).toList();
    expect(routes, ['/home', '/encyclopedia', '/tools', '/projects', '/directory']);
    expect(routes.indexOf('/directory'), 4);
    expect(routes.length, 5);
    expect(routes.contains('/directory/search'), isFalse);
  });

  testWidgets('W6.2 /directory renders the real DirectoryLandingScreen',
      (tester) async {
    _useTallViewport(tester);
    await _open(tester, AppRoutes.directory);

    expect(find.byType(DirectoryLandingScreen), findsOneWidget);
    expect(find.text(Ar.directoryLandingTitle), findsWidgets);
    expect(_currentPath(), AppRoutes.directory);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'W6.2 selecting a category from /directory navigates to /directory/search '
    'with the selected BusinessType as initialCategory',
    (tester) async {
      _useTallViewport(tester);
      await _open(tester, AppRoutes.directory);

      final type = BusinessType.supplier;
      final cards = find.byType(DirectoryLandingScreen);
      expect(cards, findsOneWidget);

      // Tap the first category card (supplier) on the Landing grid.
      final supplierCard = find.descendant(
        of: cards,
        matching: find.byType(CivilSurfaceCard),
      ).first;
      expect(supplierCard, findsOneWidget);
      await tester.tap(supplierCard, warnIfMissed: false);
      await tester.pumpAndSettle();

      // W6.3: a GoRouter context.push onto the /directory branch navigator
      // renders the pushed DirectorySearchScreen with the shell chrome visible;
      // the widget's presence + initialCategory prove the landing -> search
      // navigation carried the selected BusinessType.
      expect(find.byType(DirectorySearchScreen), findsOneWidget);
      final search = tester.widget<DirectorySearchScreen>(
        find.byType(DirectorySearchScreen),
      );
      expect(search.initialCategory, type);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'W6.2 direct /directory/search with no category opens unfiltered browse '
    'mode (initialCategory null) and renders the real DirectorySearchScreen',
    (tester) async {
      _useTallViewport(tester);
      await _open(tester, AppRoutes.directorySearch);

      final search = tester.widget<DirectorySearchScreen>(
        find.byType(DirectorySearchScreen),
      );
      expect(search.initialCategory, isNull);
      expect(_currentPath(), AppRoutes.directorySearch);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'W6.2 /directory/search renders the real DirectorySearchScreen',
    (tester) async {
      _useTallViewport(tester);
      await _open(tester, AppRoutes.directorySearch);

      expect(find.byType(DirectorySearchScreen), findsOneWidget);
      expect(find.text(Ar.directorySearchTitle), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'W6.2 provider detail is NOT a permanent route (/directory/provider/:id '
    'is NotFound and no nested /directory child routes exist)',
    (tester) async {
      _useTallViewport(tester);
      for (final path in [
        '/directory/provider/some-id',
        '/directory/provider',
        '/directory/some-id',
        '/directory/map',
        '/directory/reviews',
        '/directory/rfq',
      ]) {
        await _open(tester, path);
        expect(
          find.byType(NotFoundScreen),
          findsOneWidget,
          reason: '$path must not be a registered route in W6.2',
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'W6.2 /directory Landing -> Search -> Back journey returns to Landing',
    (tester) async {
      _useTallViewport(tester);
      await _open(tester, AppRoutes.directory);

      final cards = find.byType(DirectoryLandingScreen);
      final categoryCard = find
          .descendant(of: cards, matching: find.byType(CivilSurfaceCard))
          .first;
      await tester.tap(categoryCard, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(DirectorySearchScreen), findsOneWidget);

      // Landing -> (push Search) -> Back -> Landing. The pushed page pops back
      // to the Landing screen.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DirectoryLandingScreen), findsOneWidget);
      expect(find.byType(DirectorySearchScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('W6.2 /projects remains unchanged and valid', (tester) async {
    _useTallViewport(tester);
    await _open(tester, AppRoutes.projects);
    expect(_currentPath(), AppRoutes.projects);
    expect(tester.takeException(), isNull);
  });
}
