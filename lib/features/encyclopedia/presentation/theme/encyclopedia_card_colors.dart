import 'package:flutter/material.dart';

class EncyclopediaCardColors {
  EncyclopediaCardColors._();

  // ── Page constants ──
  static const Color pageBg = Color(0xFFFAF7F2);
  static const Color paperBg = Color(0xFFFFFEFB);
  static const Color textPrimary = Color(0xFF171411);
  static const Color textSecondary = Color(0xFF6D6258);
  static const Color textMuted = Color(0xFF9A8E84);
  static const Color border = Color(0xFFE8DCD3);
  static const Color softPanel = Color(0xFFF7EFEA);
  static const Color tableHeaderBg = Color(0xFFF3E8E3);
  static const Color dangerText = Color(0xFFA23A36);

  // ── Topic accent (default: Cement Gray) ──
  // TODO: Make configurable via a topic theme key in a future phase.
  // Future theme options: navy, teal, olive, amber, maroon, cement_gray.
  static const Color accent = Color(0xFF8A8F9A);
  static const Color accentSoft = Color(0xFFF0F1F3);
  static const Color accentChip = Color(0xFFE2E4E8);
  static const Color accentDark = Color(0xFF5C6068);

  // ── Semantic: Safety Notes (fixed amber) ──
  static const Color safetyBorder = Color(0xFFD4A017);
  static const Color safetyIcon = Color(0xFFB8860B);

  // ── Semantic: Common Mistakes (fixed red) ──
  static const Color mistakeBg = Color(0xFFFDECEA);
  static const Color mistakeBorder = Color(0xFFA23A36);
}
