import 'package:civilpedia/core/theme/app_colors.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/core/theme/design_tokens.dart';
import 'package:civilpedia/core/widgets/civil_surface_card.dart';
import 'package:civilpedia/core/widgets/search_bar_widget.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R10.2 frozen color roles', () {
    test('light palette matches the accepted R10.1 tokens', () {
      expect(AppColors.brandAmber, const Color(0xFFFE9E03));
      expect(AppColors.brandBlue, const Color(0xFF0155DA));
      expect(AppColors.brandBlueDark, const Color(0xFF063284));
      expect(AppColors.background, const Color(0xFFFAF7F2));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.surfaceSecondary, const Color(0xFFF6F1E8));
      expect(AppColors.textPrimary, const Color(0xFF221F18));
      expect(AppColors.textOnAmber, const Color(0xFF221F18));
    });

    test('dark palette matches the approved true-black amendment', () {
      expect(AppColors.darkBackground, const Color(0xFF000000));
      expect(AppColors.darkSurface, const Color(0xFF121212));
      expect(AppColors.darkSurfaceSecondary, const Color(0xFF1A1A1A));
      expect(AppColors.darkSurfaceElevated, const Color(0xFF262626));
      expect(AppColors.darkBorder, const Color(0xFF2B2B2B));
      expect(AppColors.darkBorderStrong, const Color(0xFF666666));
      expect(AppColors.darkBrandAmber, const Color(0xFFFFB02E));
      expect(AppColors.darkBrandBlue, const Color(0xFF63A4FF));
    });

    test('dark strong control boundary meets 3:1 contrast', () {
      expect(
        _contrastRatio(
          AppColors.darkBorderStrong,
          AppColors.darkSurfaceSecondary,
        ),
        greaterThanOrEqualTo(3),
      );
    });
  });

  group('R10.2 Material theme', () {
    testWidgets(
      'light theme maps brand, surfaces, and accessible Amber foreground',
      (tester) async {
        final theme = AppTheme.lightTheme;
        final scheme = theme.colorScheme;
        await tester.pumpWidget(
          MaterialApp(theme: theme, home: const SizedBox()),
        );

        expect(theme.scaffoldBackgroundColor, AppColors.background);
        expect(scheme.primary, AppColors.brandAmber);
        expect(scheme.onPrimary, AppColors.textOnAmber);
        expect(scheme.secondary, AppColors.brandBlue);
        expect(scheme.surface, AppColors.surface);
        expect(scheme.surfaceContainer, AppColors.surfaceSecondary);
        expect(theme.appBarTheme.backgroundColor, AppColors.background);
        expect(theme.cardTheme.elevation, DesignTokens.elevation2);

        final elevatedStyle = theme.elevatedButtonTheme.style!;
        expect(
          elevatedStyle.backgroundColor!.resolve(<WidgetState>{}),
          AppColors.brandAmber,
        );
        expect(
          elevatedStyle.foregroundColor!.resolve(<WidgetState>{}),
          AppColors.textOnAmber,
        );
        expect(theme.chipTheme.selectedColor, AppColors.brandAmberSoft);
        expect(theme.dialogTheme.backgroundColor, AppColors.surfaceElevated);
        expect(
          theme.bottomSheetTheme.backgroundColor,
          AppColors.surfaceElevated,
        );
        expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
      },
    );

    testWidgets(
      'dark theme uses true-black surfaces, bright accents, and border depth',
      (tester) async {
        final theme = AppTheme.darkTheme;
        final scheme = theme.colorScheme;
        await tester.pumpWidget(
          MaterialApp(theme: theme, home: const SizedBox()),
        );

        expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
        expect(scheme.primary, AppColors.darkBrandAmber);
        expect(scheme.onPrimary, AppColors.darkTextOnAmber);
        expect(scheme.secondary, AppColors.darkBrandBlue);
        expect(scheme.surface, AppColors.darkSurface);
        expect(scheme.surfaceContainer, AppColors.darkSurfaceSecondary);
        expect(theme.cardTheme.elevation, DesignTokens.elevation0);
        expect(
          theme.dialogTheme.backgroundColor,
          AppColors.darkSurfaceElevated,
        );
        expect(
          theme.bottomSheetTheme.backgroundColor,
          AppColors.darkSurfaceElevated,
        );
      },
    );

    testWidgets(
      'Cairo hierarchy preserves frozen sizes, weights, and line heights',
      (tester) async {
        final textTheme = AppTheme.lightTheme.textTheme;
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const SizedBox()),
        );

        expect(textTheme.displayLarge!.fontSize, 32);
        expect(textTheme.displayLarge!.fontWeight, FontWeight.w700);
        expect(textTheme.displayLarge!.height, 1.20);
        expect(textTheme.headlineMedium!.fontSize, 20);
        expect(textTheme.headlineMedium!.fontWeight, FontWeight.w700);
        expect(textTheme.bodyMedium!.fontSize, 14);
        expect(textTheme.bodyMedium!.height, 1.65);
        expect(textTheme.labelLarge!.fontWeight, FontWeight.w600);
      },
    );
  });

  group('R10.2 shared primitives', () {
    testWidgets('dark CivilSurfaceCard is flat and separated by a border', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: CivilSurfaceCard(child: Text('Dark card')),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(CivilSurfaceCard),
          matching: find.byType(Material),
        ),
      );
      final shape = material.shape! as RoundedRectangleBorder;

      expect(material.color, AppColors.darkSurface);
      expect(material.elevation, DesignTokens.elevation0);
      expect(shape.side.color, AppColors.darkBorder);
    });

    testWidgets('default search hint follows English locale', (tester) async {
      await _pumpSearch(tester, const Locale('en'));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.hintText, En.search);
      expect(
        (field.decoration!.focusedBorder! as OutlineInputBorder)
            .borderSide
            .width,
        2,
      );
      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(56),
      );
    });

    testWidgets('default search hint follows Arabic locale', (tester) async {
      await _pumpSearch(tester, const Locale('ar'));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.hintText, Ar.search);
      expect(field.textAlign, TextAlign.start);
    });
  });
}

Future<void> _pumpSearch(WidgetTester tester, Locale locale) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(child: SearchBarWidget(lightSurface: true)),
      ),
    ),
  );
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
