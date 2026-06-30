import 'package:flutter/material.dart';

class EncyclopediaTopicTheme {
  const EncyclopediaTopicTheme._({
    required this.accent,
    required this.accentSoft,
    required this.accentChip,
    required this.accentDark,
  });

  final Color accent;
  final Color accentSoft;
  final Color accentChip;
  final Color accentDark;

  static const cementGray = EncyclopediaTopicTheme._(
    accent: Color(0xFF8A8F9A),
    accentSoft: Color(0xFFF0F1F3),
    accentChip: Color(0xFFE2E4E8),
    accentDark: Color(0xFF5C6068),
  );

  static const navy = EncyclopediaTopicTheme._(
    accent: Color(0xFF1B2A4A),
    accentSoft: Color(0xFFEBEDF2),
    accentChip: Color(0xFFDDE0EA),
    accentDark: Color(0xFF0E1A33),
  );

  static const teal = EncyclopediaTopicTheme._(
    accent: Color(0xFF1A7A6E),
    accentSoft: Color(0xFFE6F2F0),
    accentChip: Color(0xFFD4E8E4),
    accentDark: Color(0xFF0F5C52),
  );

  static const olive = EncyclopediaTopicTheme._(
    accent: Color(0xFF6B8E23),
    accentSoft: Color(0xFFF5F7EE),
    accentChip: Color(0xFFEFF3E0),
    accentDark: Color(0xFF4A6625),
  );

  static const amber = EncyclopediaTopicTheme._(
    accent: Color(0xFFC8913A),
    accentSoft: Color(0xFFF8F0E0),
    accentChip: Color(0xFFF2E8D0),
    accentDark: Color(0xFFA07128),
  );

  static const maroon = EncyclopediaTopicTheme._(
    accent: Color(0xFF7A2834),
    accentSoft: Color(0xFFF2E8EA),
    accentChip: Color(0xFFE8D8DC),
    accentDark: Color(0xFF5A1E26),
  );

  static const List<EncyclopediaTopicTheme> all = [
    cementGray,
    navy,
    teal,
    olive,
    amber,
    maroon,
  ];

  static const EncyclopediaTopicTheme defaultTheme = cementGray;
}
