import 'package:civilpedia/core/theme/app_colors.dart';
import 'package:civilpedia/core/theme/design_tokens.dart';
import 'package:civilpedia/core/widgets/civil_app_bar.dart';
import 'package:civilpedia/core/widgets/civil_surface_card.dart';
import 'package:civilpedia/core/widgets/search_bar_widget.dart';
import 'package:civilpedia/core/widgets/section_header.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CivilSurfaceCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CivilSurfaceCard(child: Text('card content')),
          ),
        ),
      );

      expect(find.text('card content'), findsOneWidget);
    });

    Finder cardMaterial() => find.descendant(
          of: find.byType(CivilSurfaceCard),
          matching: find.byType(Material),
        );

    testWidgets('defaults to primary surface color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CivilSurfaceCard(child: SizedBox()),
          ),
        ),
      );

      final material = tester.widget<Material>(cardMaterial());
      expect(material.color, AppColors.surfacePrimary);
    });

    testWidgets('warm variant uses warm surface', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CivilSurfaceCard(warm: true, child: SizedBox()),
          ),
        ),
      );

      final material = tester.widget<Material>(cardMaterial());
      expect(material.color, AppColors.surfaceWarm);
    });

    testWidgets('tap callback is invoked', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivilSurfaceCard(
              onTap: () => tapped = true,
              child: const Text('tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap me'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('uses canonical card radius and elevation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CivilSurfaceCard(child: SizedBox()),
          ),
        ),
      );

      final material = tester.widget<Material>(cardMaterial());
      final shape = material.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(DesignTokens.radiusMd));
      expect(material.elevation, DesignTokens.elevation2);
    });

    testWidgets('clips child to the card radius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CivilSurfaceCard(child: SizedBox()),
          ),
        ),
      );

      final material = tester.widget<Material>(cardMaterial());
      expect(material.clipBehavior, Clip.antiAlias);
    });
  });

  group('CivilAppBar', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: CivilAppBar(title: Text('Page Title')),
          ),
        ),
      );

      expect(find.text('Page Title'), findsOneWidget);
    });

    testWidgets('renders actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            appBar: CivilAppBar(
              title: Text('Page Title'),
              actions: [Icon(Icons.search)],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('uses page background and dark foreground by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: CivilAppBar(title: Text('Page Title')),
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, AppColors.pageBackground);
      expect(appBar.foregroundColor, AppColors.textPrimary);
      expect(appBar.elevation, 0);
    });

    testWidgets('shows back button when there is a route to pop', (
      tester,
    ) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            key: navigatorKey,
            onGenerateRoute: (settings) {
              if (settings.name == '/second') {
                return MaterialPageRoute(
                  builder: (_) => const Scaffold(
                    appBar: CivilAppBar(title: Text('Second')),
                  ),
                  settings: settings,
                );
              }
              return MaterialPageRoute(
                builder: (_) => const SizedBox.expand(),
                settings: settings,
              );
            },
          ),
        ),
      );

      navigatorKey.currentState!.pushNamed('/second');
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
    });

    testWidgets('does not imply back button when showBackButton is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: CivilAppBar(
              title: Text('No Back'),
              showBackButton: false,
            ),
          ),
        ),
      );

      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('leading widget overrides back behavior', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: CivilAppBar(
              title: Text('Custom Leading'),
              leading: Icon(Icons.menu),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('divider is rendered by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: CivilAppBar(title: Text('Divided')),
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('RTL layout places leading at the visual start', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              appBar: CivilAppBar(
                title: Text('RTL'),
                leading: Icon(Icons.menu),
                showBackButton: false,
              ),
            ),
          ),
        ),
      );

      final leadingFinder = find.byIcon(Icons.menu);
      expect(leadingFinder, findsOneWidget);

      final leadingBox = tester.renderObject<RenderBox>(leadingFinder);
      final appBarBox = tester.renderObject<RenderBox>(find.byType(AppBar));
      final leadingCenter = leadingBox.localToGlobal(leadingBox.size.center(Offset.zero));
      final appBarCenter = appBarBox.localToGlobal(appBarBox.size.center(Offset.zero));
      // In RTL the leading widget should be on the right half of the AppBar.
      expect(leadingCenter.dx, greaterThan(appBarCenter.dx));
    });
  });

  group('SearchBarWidget', () {
    testWidgets('preserves onSubmitted callback', (tester) async {
      String? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(onSubmitted: (q) => submitted = q),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test query');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submitted, 'test query');
    });

    testWidgets('uses TextAlign.start instead of hardcoded right', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SearchBarWidget()),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textAlign, TextAlign.start);
    });

    testWidgets('RTL layout uses start alignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: SearchBarWidget()),
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textAlign, TextAlign.start);
    });

    testWidgets('uses radiusSearch token for border radius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SearchBarWidget()),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      final border = field.decoration!.border! as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(DesignTokens.radiusSearch));
    });

    testWidgets('preserves default Ar.search hint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SearchBarWidget()),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.hintText, Ar.search);
    });
  });

  group('SectionHeader', () {
    testWidgets('renders title and action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'الأقسام',
              actionLabel: 'عرض الكل',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('الأقسام'), findsOneWidget);
      expect(find.text('عرض الكل'), findsOneWidget);
    });

    testWidgets('uses semantic text color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'Title'),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Title'));
      final style = text.style ?? DefaultTextStyle.of(tester.element(find.text('Title'))).style;
      expect(style.color, AppColors.textPrimary);
    });

    testWidgets('RTL layout places title at the visual start', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SectionHeader(
                title: 'عنوان',
                actionLabel: 'الكل',
              ),
            ),
          ),
        ),
      );

      final titleBox = tester.renderObject<RenderBox>(find.text('عنوان'));
      final actionBox = tester.renderObject<RenderBox>(find.text('الكل'));
      final titleCenter = titleBox.localToGlobal(titleBox.size.center(Offset.zero));
      final actionCenter = actionBox.localToGlobal(actionBox.size.center(Offset.zero));

      // In RTL, the title (start) should be to the right of the action (end).
      expect(titleCenter.dx, greaterThan(actionCenter.dx));
    });
  });
}
