import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/projects/presentation/project_list_screen.dart'
    as canonical;
import 'package:civilpedia/features/tools/presentation/screens/checklist/project_list_screen.dart'
    as legacy_tools_shim;
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/routes/app_router.dart';
import 'package:civilpedia/routes/app_routes.dart';
import 'package:civilpedia/routes/not_found_screen.dart';

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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('W6.1 AppRoutes.projects is the canonical /projects path', () {
    expect(AppRoutes.projects, '/projects');
  });

  test(
    'W6.1 legacy Tools path is a compatibility shim resolving to the same '
    'canonical ProjectListScreen',
    () {
      expect(
        legacy_tools_shim.ProjectListScreen,
        same(canonical.ProjectListScreen),
      );
    },
  );

  test('W6.3 Projects IS a Bottom Navigation destination at index 3', () {
    final routes = kShellDestinations.map((d) => d.route).toList();
    expect(routes, ['/home', '/encyclopedia', '/tools', '/projects', '/directory']);
    expect(routes.indexOf('/projects'), 3);
    expect(routes.length, 5);
  });

  testWidgets('W6.1 /projects renders the real Production ProjectListScreen',
      (tester) async {
    _useTallViewport(tester);
    await _open(tester, AppRoutes.projects);

    expect(find.byType(canonical.ProjectListScreen), findsOneWidget);
    // W6.3: the same label appears once in the AppBar title and once as the
    // Bottom Navigation tab label; assert the AppBar title specifically.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(Ar.checklistMyProjects),
      ),
      findsOneWidget,
    );
    expect(_currentPath(), AppRoutes.projects);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'W6.1 /projects opens the same canonical screen as the legacy Tools '
    'import path',
    (tester) async {
      _useTallViewport(tester);
      await _open(tester, AppRoutes.projects);

      final legacyWidget = find.byType(legacy_tools_shim.ProjectListScreen);
      expect(legacyWidget, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'W6.1 no nested project route is registered (/projects/:projectId is '
    'NotFound)',
    (tester) async {
      _useTallViewport(tester);
      await _open(tester, '/projects/some-id');

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.byType(canonical.ProjectListScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'W6.1 no inspections/reports/placeholder project routes exist',
    (tester) async {
      _useTallViewport(tester);
      for (final path in [
        '/projects/some-id/inspections',
        '/projects/some-id/reports',
        '/projects/some-id/calculations',
        '/projects/some-id/checklists',
        '/projects/some-id/notes',
      ]) {
        await _open(tester, path);
        expect(
          find.byType(NotFoundScreen),
          findsOneWidget,
          reason: '$path must not be a registered route in W6.1',
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
