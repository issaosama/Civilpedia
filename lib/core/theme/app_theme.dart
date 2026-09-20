import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'design_tokens.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.brandAmber,
      onPrimary: AppColors.textOnAmber,
      primaryContainer: AppColors.brandAmberSoft,
      onPrimaryContainer: AppColors.brandAmberPressed,
      secondary: AppColors.brandBlue,
      onSecondary: AppColors.textOnBlue,
      secondaryContainer: AppColors.brandBlueSoft,
      onSecondaryContainer: AppColors.brandBlueDark,
      tertiary: AppColors.info,
      onTertiary: AppColors.textOnBlue,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainer: AppColors.surfaceSecondary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.border,
      error: AppColors.error,
      onError: AppColors.textOnBlue,
      errorContainer: AppColors.errorSoft,
      onErrorContainer: AppColors.error,
      scrim: AppColors.scrim,
      surfaceTint: AppColors.brandAmber,
    );
    final textTheme = AppTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.brandAmber,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      shadowColor: AppColors.cardShadow,
      disabledColor: AppColors.disabled,
      focusColor: AppColors.brandBlue.withValues(alpha: 0.12),
      hintColor: AppColors.textMuted,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: DesignTokens.elevation0,
        scrolledUnderElevation: DesignTokens.elevation0,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.cardShadow,
        elevation: DesignTokens.elevation2,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.surfaceSecondary,
        text: AppColors.textPrimary,
        hint: AppColors.textMuted,
        border: AppColors.borderStrong,
        focus: AppColors.brandBlue,
        error: AppColors.error,
        disabledFill: AppColors.disabledSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(
          background: AppColors.brandAmber,
          foreground: AppColors.textOnAmber,
          disabledBackground: AppColors.disabledSurface,
          disabledForeground: AppColors.disabled,
          elevation: DesignTokens.elevation0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledButtonStyle(
          background: AppColors.brandAmber,
          foreground: AppColors.textOnAmber,
          disabledBackground: AppColors.disabledSurface,
          disabledForeground: AppColors.disabled,
          elevation: DesignTokens.elevation1,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandBlue,
          disabledForegroundColor: AppColors.disabled,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: textTheme.labelLarge,
          side: const BorderSide(color: AppColors.brandBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandBlue,
          disabledForegroundColor: AppColors.disabled,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
        ),
      ),
      chipTheme: _chipTheme(
        background: AppColors.surface,
        selectedBackground: AppColors.brandAmberSoft,
        foreground: AppColors.textSecondary,
        selectedForeground: AppColors.brandAmberPressed,
        disabled: AppColors.disabledSurface,
        border: AppColors.border,
        textTheme: textTheme,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: DesignTokens.elevation3,
        titleTextStyle: textTheme.headlineMedium,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        modalBackgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: DesignTokens.elevation3,
        modalElevation: DesignTokens.elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusLg),
          ),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.brandBlueDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textOnBlue,
        ),
        actionTextColor: AppColors.darkBrandAmber,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.brandBlue,
        selectionColor: AppColors.brandBlueSoft,
        selectionHandleColor: AppColors.brandBlue,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandBlue,
        linearTrackColor: AppColors.brandBlueSoft,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.brandAmberPressed,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: DesignTokens.elevationNavigation,
      ),
      pageTransitionsTheme: _pageTransitions,
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.darkBrandAmber,
      onPrimary: AppColors.darkTextOnAmber,
      primaryContainer: AppColors.darkWarningSoft,
      onPrimaryContainer: AppColors.darkBrandAmber,
      secondary: AppColors.darkBrandBlue,
      onSecondary: AppColors.darkTextOnBlue,
      secondaryContainer: AppColors.darkInfoSoft,
      onSecondaryContainer: AppColors.darkInfo,
      tertiary: AppColors.darkInfo,
      onTertiary: AppColors.darkTextOnBlue,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainer: AppColors.darkSurfaceSecondary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorderStrong,
      outlineVariant: AppColors.darkBorder,
      error: AppColors.darkError,
      onError: AppColors.darkTextOnBlue,
      errorContainer: AppColors.darkErrorSoft,
      onErrorContainer: AppColors.darkError,
      scrim: AppColors.darkScrim,
      surfaceTint: AppColors.darkBrandBlue,
    );
    final textTheme = AppTypography.darkTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.darkBrandAmber,
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkBackground,
      shadowColor: Colors.transparent,
      disabledColor: AppColors.darkDisabled,
      focusColor: AppColors.darkBrandBlue.withValues(alpha: 0.16),
      hintColor: AppColors.darkTextMuted,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: DesignTokens.elevation0,
        scrolledUnderElevation: DesignTokens.elevation0,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: const IconThemeData(
          color: AppColors.darkTextPrimary,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.darkTextPrimary,
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: DesignTokens.elevation0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.darkSurfaceSecondary,
        text: AppColors.darkTextPrimary,
        hint: AppColors.darkTextMuted,
        border: AppColors.darkBorderStrong,
        focus: AppColors.darkBrandBlue,
        error: AppColors.darkError,
        disabledFill: AppColors.darkDisabledSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(
          background: AppColors.darkBrandAmber,
          foreground: AppColors.darkTextOnAmber,
          disabledBackground: AppColors.darkDisabledSurface,
          disabledForeground: AppColors.darkDisabled,
          elevation: DesignTokens.elevation0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledButtonStyle(
          background: AppColors.darkBrandAmber,
          foreground: AppColors.darkTextOnAmber,
          disabledBackground: AppColors.darkDisabledSurface,
          disabledForeground: AppColors.darkDisabled,
          elevation: DesignTokens.elevation0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkBrandBlue,
          disabledForegroundColor: AppColors.darkDisabled,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: textTheme.labelLarge,
          side: const BorderSide(color: AppColors.darkBrandBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkBrandBlue,
          disabledForegroundColor: AppColors.darkDisabled,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
        ),
      ),
      chipTheme: _chipTheme(
        background: AppColors.darkSurface,
        selectedBackground: AppColors.darkWarningSoft,
        foreground: AppColors.darkTextSecondary,
        selectedForeground: AppColors.darkBrandAmber,
        disabled: AppColors.darkDisabledSurface,
        border: AppColors.darkBorder,
        textTheme: textTheme,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: DesignTokens.elevation0,
        titleTextStyle: textTheme.headlineMedium,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        modalBackgroundColor: AppColors.darkSurfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: DesignTokens.elevation0,
        modalElevation: DesignTokens.elevation0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusLg),
          ),
          side: BorderSide(color: AppColors.darkBorder),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.darkBorderStrong,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        contentTextStyle: textTheme.bodyMedium,
        actionTextColor: AppColors.darkBrandBlue,
        behavior: SnackBarBehavior.floating,
        elevation: DesignTokens.elevation0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.darkBrandBlue,
        selectionColor: AppColors.darkInfoSoft,
        selectionHandleColor: AppColors.darkBrandBlue,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.darkBrandBlue,
        linearTrackColor: AppColors.darkInfoSoft,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        selectedItemColor: AppColors.darkBrandAmber,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: DesignTokens.elevation0,
      ),
      pageTransitionsTheme: _pageTransitions,
    );
  }

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color text,
    required Color hint,
    required Color border,
    required Color focus,
    required Color error,
    required Color disabledFill,
  }) {
    OutlineInputBorder outline(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: TextStyle(color: hint),
      labelStyle: TextStyle(color: text),
      floatingLabelStyle: TextStyle(color: focus),
      iconColor: hint,
      prefixIconColor: hint,
      suffixIconColor: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: outline(border),
      enabledBorder: outline(border),
      focusedBorder: outline(focus, width: 2),
      errorBorder: outline(error),
      focusedErrorBorder: outline(error, width: 2),
      disabledBorder: outline(disabledFill),
    );
  }

  static ButtonStyle _filledButtonStyle({
    required Color background,
    required Color foreground,
    required Color disabledBackground,
    required Color disabledForeground,
    required double elevation,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: disabledBackground,
      disabledForegroundColor: disabledForeground,
      minimumSize: const Size(64, 48),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      elevation: elevation,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
    );
  }

  static ChipThemeData _chipTheme({
    required Color background,
    required Color selectedBackground,
    required Color foreground,
    required Color selectedForeground,
    required Color disabled,
    required Color border,
    required TextTheme textTheme,
  }) {
    return ChipThemeData(
      backgroundColor: background,
      selectedColor: selectedBackground,
      disabledColor: disabled,
      labelStyle: textTheme.labelMedium?.copyWith(color: foreground),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: selectedForeground,
      ),
      checkmarkColor: selectedForeground,
      side: BorderSide(color: border),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );
}
