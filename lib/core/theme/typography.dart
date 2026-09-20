import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => _buildTextTheme(
    base: GoogleFonts.cairoTextTheme(),
    primary: AppColors.textPrimary,
    secondary: AppColors.textSecondary,
  );

  static TextTheme get darkTextTheme => _buildTextTheme(
    base: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
    primary: AppColors.darkTextPrimary,
    secondary: AppColors.darkTextSecondary,
  );

  static TextTheme _buildTextTheme({
    required TextTheme base,
    required Color primary,
    required Color secondary,
  }) {
    TextStyle? style(
      TextStyle? source,
      double size,
      FontWeight weight,
      double height, {
      bool muted = false,
    }) {
      return source?.copyWith(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: muted ? secondary : primary,
      );
    }

    return base.copyWith(
      displayLarge: style(base.displayLarge, 32, FontWeight.w700, 1.20),
      displayMedium: style(base.displayMedium, 28, FontWeight.w700, 1.25),
      displaySmall: style(base.displaySmall, 24, FontWeight.w700, 1.35),
      headlineLarge: style(base.headlineLarge, 24, FontWeight.w700, 1.35),
      headlineMedium: style(base.headlineMedium, 20, FontWeight.w700, 1.40),
      headlineSmall: style(base.headlineSmall, 18, FontWeight.w600, 1.45),
      titleLarge: style(base.titleLarge, 18, FontWeight.w600, 1.45),
      titleMedium: style(base.titleMedium, 16, FontWeight.w600, 1.50),
      titleSmall: style(base.titleSmall, 14, FontWeight.w600, 1.50),
      bodyLarge: style(base.bodyLarge, 16, FontWeight.w400, 1.65),
      bodyMedium: style(base.bodyMedium, 14, FontWeight.w400, 1.65),
      bodySmall: style(base.bodySmall, 12, FontWeight.w400, 1.60, muted: true),
      labelLarge: style(base.labelLarge, 14, FontWeight.w600, 1.40),
      labelMedium: style(
        base.labelMedium,
        12,
        FontWeight.w600,
        1.40,
        muted: true,
      ),
      labelSmall: style(
        base.labelSmall,
        11,
        FontWeight.w500,
        1.30,
        muted: true,
      ),
    );
  }
}
