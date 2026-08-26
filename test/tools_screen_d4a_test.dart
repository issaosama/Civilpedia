import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_colors.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/core/widgets/civil_app_bar.dart';
import 'package:civilpedia/core/widgets/civil_surface_card.dart';
import 'package:civilpedia/features/tools/presentation/screens/tools_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

GoRouter _toolsRouter() {
  return GoRouter(
    initialLocation: '/tools',
    routes: [
      GoRoute(
        path: '/tools',
        builder: (_, __) => ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: const ToolsScreen(),
        ),
      ),
      GoRoute(
        path: '/calculator/concrete',
        builder: (_, __) => const Scaffold(body: Text('Concrete Calculator')),
      ),
      GoRoute(
        path: '/calculator/steel',
        builder: (_, __) => const Scaffold(body: Text('Steel Weight Calculator')),
      ),
      GoRoute(
        path: '/calculator/brick',
        builder: (_, __) => const Scaffold(body: Text('Brick Calculator')),
      ),
      GoRoute(
        path: '/calculator/tile',
        builder: (_, __) => const Scaffold(body: Text('Tile Calculator')),
      ),
      GoRoute(
        path: '/calculator/checklist',
        builder: (_, __) => const Scaffold(body: Text('Inspection Checklist')),
      ),
    ],
  );
}

Widget _toolsApp({double width = 412, ThemeData? theme}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: MaterialApp.router(
      theme: theme ?? AppTheme.lightTheme,
      routerConfig: _toolsRouter(),
    ),
  );
}

void main() {
  group('ToolsScreen D4A visual migration', () {
    testWidgets('Tools root renders', (tester) async {
      await tester.pumpWidget(_toolsApp());
      await tester.pumpAndSettle();

      expect(find.text(Ar.tools), findsOneWidget);
      expect(find.text(Ar.engineeringTools), findsOneWidget);
      expect(find.text(Ar.toolsDescription), findsOneWidget);
    });

    testWidgets('uses theme-aware page background and header', (tester) async {
      await tester.pumpWidget(_toolsApp());
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, AppTheme.lightTheme.scaffoldBackgroundColor);
      expect(appBar.foregroundColor, AppTheme.lightTheme.colorScheme.onSurface);
      expect(appBar.elevation, 0);
    });

    testWidgets('adapts header to dark theme', (tester) async {
      await tester.pumpWidget(_toolsApp(theme: AppTheme.darkTheme));
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, AppTheme.darkTheme.scaffoldBackgroundColor);
      expect(appBar.foregroundColor, AppTheme.darkTheme.colorScheme.onSurface);
    });

    testWidgets('legacy large solid-orange AppBar is gone', (tester) async {
      await tester.pumpWidget(_toolsApp());
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, isNot(AppColors.primaryDark));
      expect(appBar.backgroundColor, isNot(AppColors.primary));

      expect(find.byType(CivilAppBar), findsOneWidget);
    });

    testWidgets('Concrete Calculator remains available and navigates', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(412, 800)),
          child: MaterialApp.router(routerConfig: _toolsRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(CivilSurfaceCard);
      expect(cardFinder, findsAtLeastNWidgets(2));

      await tester.tap(cardFinder.at(1));
      await tester.pumpAndSettle();

      expect(find.text('Concrete Calculator'), findsOneWidget);
    });

    testWidgets('Steel Weight Calculator remains available and navigates', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(412, 800)),
          child: MaterialApp.router(routerConfig: _toolsRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(CivilSurfaceCard);
      expect(cardFinder, findsAtLeastNWidgets(2));

      await tester.tap(cardFinder.at(2));
      await tester.pumpAndSettle();

      expect(find.text('Steel Weight Calculator'), findsOneWidget);
    });

    testWidgets('Masonry/Brick Calculator remains available and navigates', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(412, 800)),
          child: MaterialApp.router(routerConfig: _toolsRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final brickCard = find.widgetWithText(CivilSurfaceCard, 'حاسبة الطابوق');
      await tester.scrollUntilVisible(brickCard, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(brickCard, findsOneWidget);

      await tester.tap(brickCard);
      await tester.pumpAndSettle();

      expect(find.text('Brick Calculator'), findsOneWidget);
    });

    testWidgets('Tile Calculator remains available and navigates', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(412, 800)),
          child: MaterialApp.router(routerConfig: _toolsRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final tileCard = find.widgetWithText(CivilSurfaceCard, 'حاسبة الكاشي');
      await tester.scrollUntilVisible(tileCard, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(tileCard, findsOneWidget);

      await tester.tap(tileCard);
      await tester.pumpAndSettle();

      expect(find.text('Tile Calculator'), findsOneWidget);
    });

    testWidgets('Inspection Checklist remains available and navigates', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(412, 800)),
          child: MaterialApp.router(routerConfig: _toolsRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final checklistCard = find.widgetWithText(CivilSurfaceCard, 'قائمة التفتيش');
      await tester.scrollUntilVisible(checklistCard, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(checklistCard, findsOneWidget);

      await tester.tap(checklistCard);
      await tester.pumpAndSettle();

      expect(find.text('Inspection Checklist'), findsOneWidget);
    });

    testWidgets('tool cards use CivilSurfaceCard and semantic icon color', (tester) async {
      await tester.pumpWidget(_toolsApp());
      await tester.pumpAndSettle();

      expect(find.byType(CivilSurfaceCard), findsAtLeastNWidgets(3));

      final icons = tester.widgetList<Icon>(find.byType(Icon));
      final orangeIcons = icons.where((i) => i.color == AppColors.primary).length;
      expect(orangeIcons, greaterThanOrEqualTo(3));
    });

    testWidgets('RTL layout uses TextAlign.start for tool labels', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(412, 800)),
            child: MaterialApp(
              home: Scaffold(
                body: ChangeNotifierProvider(
                  create: (_) => LanguageProvider(),
                  child: const ToolsScreen(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleFinder = find.text('حاسبة الخرسانة');
      expect(titleFinder, findsOneWidget);

      final text = tester.widget<Text>(titleFinder);
      expect(text.textAlign, TextAlign.start);
    });

    testWidgets('no overflow at 412 logical px', (tester) async {
      await tester.pumpWidget(_toolsApp(width: 412));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 390 logical px', (tester) async {
      await tester.pumpWidget(_toolsApp(width: 390));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 360 logical px', (tester) async {
      await tester.pumpWidget(_toolsApp(width: 360));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 320 logical px', (tester) async {
      await tester.pumpWidget(_toolsApp(width: 320));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('final content is scrollable and reachable', (tester) async {
      await tester.pumpWidget(_toolsApp());
      await tester.pumpAndSettle();

      final lastTool = find.widgetWithText(CivilSurfaceCard, 'حاسبة الكاشي');
      await tester.scrollUntilVisible(lastTool, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(lastTool, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
