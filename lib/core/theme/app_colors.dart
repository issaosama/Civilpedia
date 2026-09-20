import 'package:flutter/material.dart';

/// Canonical Civilpedia color roles frozen in V1-R10.1.
class AppColors {
  AppColors._();

  // Brand.
  static const Color brandAmber = Color(0xFFFE9E03);
  static const Color brandAmberPressed = Color(0xFFA95400);
  static const Color brandAmberSoft = Color(0xFFFFF1DB);
  static const Color brandBlue = Color(0xFF0155DA);
  static const Color brandBlueDark = Color(0xFF063284);
  static const Color brandBlueSoft = Color(0xFFE8F1FF);

  // Light surfaces and content.
  static const Color background = Color(0xFFFAF7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF6F1E8);
  static const Color surfaceElevated = Color(0xFFFFFDFC);
  static const Color textPrimary = Color(0xFF221F18);
  static const Color textSecondary = Color(0xFF665E55);
  static const Color textMuted = Color(0xFF70685F);
  static const Color textOnAmber = Color(0xFF221F18);
  static const Color textOnBlue = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDED5C7);
  static const Color borderStrong = Color(0xFF8C8174);
  static const Color divider = Color(0xFFEAE2D7);

  // Light semantic roles.
  static const Color success = Color(0xFF267A4B);
  static const Color successSoft = Color(0xFFE8F4EC);
  static const Color warning = Color(0xFF9A5B00);
  static const Color warningSoft = Color(0xFFFFF2D8);
  static const Color error = Color(0xFFB3261E);
  static const Color errorSoft = Color(0xFFFDECEA);
  static const Color info = Color(0xFF245FAE);
  static const Color infoSoft = brandBlueSoft;
  static const Color disabled = Color(0xFF9D958A);
  static const Color disabledSurface = Color(0xFFEEE8DE);
  static const Color scrim = Color(0x7A221F18);

  // Dark surfaces and content.
  static const Color darkBackground = Color(0xFF121820);
  static const Color darkSurface = Color(0xFF19212B);
  static const Color darkSurfaceSecondary = Color(0xFF202A35);
  static const Color darkSurfaceElevated = Color(0xFF273340);
  static const Color darkTextPrimary = Color(0xFFF5F1E8);
  static const Color darkTextSecondary = Color(0xFFC9C2B7);
  static const Color darkTextMuted = Color(0xFF9D968C);
  static const Color darkBorder = Color(0xFF3A4653);
  static const Color darkBorderStrong = Color(0xFF687482);
  static const Color darkBrandAmber = Color(0xFFFFB02E);
  static const Color darkTextOnAmber = Color(0xFF241A0E);
  static const Color darkBrandBlue = Color(0xFF63A4FF);
  static const Color darkTextOnBlue = Color(0xFF0B1625);

  // Dark semantic roles.
  static const Color darkSuccess = Color(0xFF6FCF97);
  static const Color darkSuccessSoft = Color(0xFF173626);
  static const Color darkWarning = Color(0xFFFFC45C);
  static const Color darkWarningSoft = Color(0xFF3B2A10);
  static const Color darkError = Color(0xFFFF8A80);
  static const Color darkErrorSoft = Color(0xFF421E1D);
  static const Color darkInfo = Color(0xFF78B2FF);
  static const Color darkInfoSoft = Color(0xFF152F50);
  static const Color darkDisabled = Color(0xFF717983);
  static const Color darkDisabledSurface = Color(0xFF252E38);
  static const Color darkScrim = Color(0xB80B1016);

  // Third-party brand color.
  static const Color googleBlue = Color(0xFF4285F4);

  // Compatibility aliases for existing callers. New code should use the
  // semantic roles above and migrate old names only when touched.
  static const Color primary = brandAmber;
  static const Color primaryDark = brandAmberPressed;
  static const Color primaryLight = darkBrandAmber;
  static const Color primarySoft = brandAmberSoft;
  static const Color onPrimary = textOnAmber;
  static const Color mainText = textPrimary;
  static const Color pageBackground = background;
  static const Color homeBackground = background;
  static const Color surfaceWhite = surface;
  static const Color surfacePrimary = surface;
  static const Color surfaceWarm = surfaceSecondary;
  static const Color surfaceTint = brandBlueSoft;
  static const Color surfaceContainer = surfaceSecondary;
  static const Color cardShadow = Color(0x1F221F18);
  static const Color brandNeutral = Color(0xFF8B7D6B);
  static const Color darkBottomNav = darkSurfaceElevated;
  static const Color darkBorderLight = darkBorder;
  static const Color darkCard = darkSurface;
}
