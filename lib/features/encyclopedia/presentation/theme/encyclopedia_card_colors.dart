import 'package:flutter/material.dart';
import 'encyclopedia_topic_theme.dart';

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
  // These delegate to the active theme preset. Call [apply] to switch at
  // runtime, e.g. when a topic's visual_theme key is read from JSON.
  static Color get accent => _current.accent;
  static Color get accentSoft => _current.accentSoft;
  static Color get accentChip => _current.accentChip;
  static Color get accentDark => _current.accentDark;

  static EncyclopediaTopicTheme _current = EncyclopediaTopicTheme.defaultTheme;
  static EncyclopediaTopicTheme get current => _current;

  static void apply(EncyclopediaTopicTheme theme) {
    _current = theme;
  }

  // ── Semantic: Safety Notes (fixed amber) ──
  static const Color safetyBorder = Color(0xFFD4A017);
  static const Color safetyIcon = Color(0xFFB8860B);

  // ── Semantic: Common Mistakes (fixed red) ──
  static const Color mistakeBg = Color(0xFFFDECEA);
  static const Color mistakeBorder = Color(0xFFA23A36);
}
