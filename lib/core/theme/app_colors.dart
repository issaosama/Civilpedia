import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Light Theme ──
  static const Color background = Color(0xFFDBD6CB);      // cement/warm concrete (legacy; preserved for compat)
  static const Color surface = Color(0xFFF6F1E8);          // warm off-white card / panel
  static const Color surfaceWhite = Color(0xFFFFFFFF);     // pure white where needed
  static const Color surfacePrimary = surfaceWhite;        // canonical primary elevated surface
  static const Color surfaceWarm = surface;                // canonical warm secondary surface
  static const Color mainText = Color(0xFF221F18);          // dark warm text
  static const Color textPrimary = Color(0xFF221F18);       // alias for mainText (backward compat)
  static const Color textSecondary = Color(0xFF6D6258);    // medium warm grey, readable on light surfaces
  static const Color border = Color(0xFFE6DDCD);           // soft warm border
  static const Color cardShadow = Color(0x1A000000);       // shadow tint

  static const Color textMuted = Color(0xFF5C5545);       // readable muted text for card summaries (~2.6:1 on surface)
  static const Color darkTextMuted = Color(0xFFC0BAA8);    // readable muted text in dark mode (~4.75:1 on darkSurface)

  // ── Amber / Yellow Accent System ──
  static const Color primary = Color(0xFFE98A1E);          // primary amber
  static const Color primaryDark = Color(0xFFC26A0C);      // darker amber for readable elements
  static const Color primaryLight = Color(0xFFF19A38);     // lighter amber
  static const Color primarySoft = Color(0xFFFBEAD3);     // soft amber background

  // ── Brand Secondary Accents ──
  static const Color brandBlue = Color(0xFF2E6BC6);        // Civilpedia logo blue, used sparingly
  static const Color brandNeutral = Color(0xFF8B7D6B);     // calm warm neutral support tone

  // ── Page / Home surfaces ──
  static const Color pageBackground = Color(0xFFFAF7F2);   // canonical warm off-white page background
  static const Color homeBackground = pageBackground;      // backward-compatible alias

  // ── Dark Surface / Text ──
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Semantic ──
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);

  // ── Legacy aliases (backward compat for untouched screens) ──
  static const Color surfaceTint = Color(0xFFF0F0FF);
  static const Color surfaceContainer = Color(0xFFF8F8FF);

  // ── Dark Theme ──
  static const Color darkBackground = Color(0xFF15140F);   // deep warm dark
  static const Color darkSurface = Color(0xFF1F1D16);      // dark card
  static const Color darkSurfaceElevated = Color(0xFF24221A); // elevated surface
  static const Color darkBottomNav = Color(0xFF1A1813);    // bottom nav surface
  static const Color darkTextPrimary = Color(0xFFF0ECE2);  // warm off-white
  static const Color darkTextSecondary = Color(0xFFA8A294); // muted warm
  static const Color darkBorder = Color(0xFF322F25);       // dark border
  static const Color darkBorderLight = Color(0xFF2C2920);

  // ── Legacy dark aliases (backward compat) ──
  static const Color darkCard = Color(0xFF1F1D16);         // same as darkSurface
}
