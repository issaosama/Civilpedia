import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    final base = GoogleFonts.cairoTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      displayMedium: base.displayMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineLarge: base.headlineLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleLarge: base.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium: base.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleSmall: base.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      labelLarge: base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      labelMedium: base.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
      labelSmall: base.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
    );
  }

  static TextTheme get darkTextTheme {
    final base = GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme);
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
      displayMedium: base.displayMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
      headlineLarge: base.headlineLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      titleLarge: base.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      titleMedium: base.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      titleSmall: base.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.darkTextPrimary),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.darkTextPrimary),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.darkTextSecondary),
      labelLarge: base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkTextPrimary),
      labelMedium: base.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.darkTextSecondary),
      labelSmall: base.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.darkTextSecondary),
    );
  }
}
