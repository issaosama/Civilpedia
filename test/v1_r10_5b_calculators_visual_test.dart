import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_colors.dart';
import 'package:civilpedia/core/widgets/civil_app_bar.dart';
import 'package:civilpedia/features/tools/presentation/screens/calculators/calculator_screen.dart';
import 'package:civilpedia/features/tools/presentation/screens/calculators/tile_calculator_screen.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/checklist_screen.dart';
import 'package:civilpedia/features/tools/presentation/widgets/calculator/calculator_primary_button.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _calculatorApp(Widget home, {ThemeData? theme}) {
  return MaterialApp(theme: theme, home: home);
}

Widget _checklistApp({ThemeData? theme}) {
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: theme,
      home: const ChecklistScreen(),
    ),
  );
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final entry in const <(String, Widget)>[
    ('Concrete', CalculatorScreen(type: 'concrete')),
    ('Steel', CalculatorScreen(type: 'steel')),
    ('Brick', CalculatorScreen(type: 'brick')),
    ('Tile', TileCalculatorScreen()),
  ]) {
    testWidgets('${entry.$1} uses CivilAppBar and preserves refresh', (
      tester,
    ) async {
      _useTallViewport(tester);
      await tester.pumpWidget(_calculatorApp(entry.$2));
      await tester.pump();

      expect(find.byType(CivilAppBar), findsOneWidget);
      expect(find.byTooltip(Ar.reset), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, isNot(AppColors.primary));
    });
  }

  testWidgets('CalculatorPrimaryButton uses accessible Amber foreground', (
    tester,
  ) async {
    await tester.pumpWidget(
      _calculatorApp(
        CalculatorPrimaryButton(onPressed: () {}, label: Ar.calculate),
      ),
    );

    final elevatedButton = find.byWidgetPredicate(
      (widget) => widget is ElevatedButton,
    );
    final button = tester.widget<ElevatedButton>(elevatedButton);
    expect(button.style?.backgroundColor?.resolve({}), AppColors.primary);
    expect(button.style?.foregroundColor?.resolve({}), AppColors.textOnAmber);
    expect(
      tester
          .widget<SizedBox>(
            find.ancestor(of: elevatedButton, matching: find.byType(SizedBox)),
          )
          .width,
      double.infinity,
    );
  });

  testWidgets('Checklist uses CivilAppBar and RTL-aware chevrons', (
    tester,
  ) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_checklistApp());
    await tester.pump();

    expect(find.byType(CivilAppBar), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsWidgets);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('Checklist reset control owns at least a 48x48 target', (
    tester,
  ) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_checklistApp());
    await tester.pump();

    final resetButton = find.ancestor(
      of: find.text(Ar.inspectionResetAll),
      matching: find.byWidgetPredicate((widget) => widget is TextButton),
    );
    final size = tester.getSize(resetButton);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('dark calculator uses approved canvas and surface tokens', (
    tester,
  ) async {
    _useTallViewport(tester);
    final darkTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.darkSurface,
        outlineVariant: AppColors.darkBorder,
      ),
    );
    await tester.pumpWidget(
      _calculatorApp(const CalculatorScreen(type: 'steel'), theme: darkTheme),
    );
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.darkBackground);
    final darkSurface = find.byWidgetPredicate((widget) {
      if (widget is! Container || widget.decoration is! BoxDecoration) {
        return false;
      }
      return (widget.decoration! as BoxDecoration).color ==
          AppColors.darkSurface;
    });
    expect(darkSurface, findsWidgets);
  });
}
