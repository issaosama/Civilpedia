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

  static const steelBlue = EncyclopediaTopicTheme._(
    accent: Color(0xFF4A6B8A),
    accentSoft: Color(0xFFE8EDF2),
    accentChip: Color(0xFFD8E0E8),
    accentDark: Color(0xFF2E4A66),
  );

  static const graphite = EncyclopediaTopicTheme._(
    accent: Color(0xFF5A5E66),
    accentSoft: Color(0xFFEDEEF0),
    accentChip: Color(0xFFDFE0E4),
    accentDark: Color(0xFF3A3D44),
  );

  static const sand = EncyclopediaTopicTheme._(
    accent: Color(0xFFB8A88A),
    accentSoft: Color(0xFFF5F0E8),
    accentChip: Color(0xFFEDE6D8),
    accentDark: Color(0xFF8C7E66),
  );

  static const brick = EncyclopediaTopicTheme._(
    accent: Color(0xFF8B5E4A),
    accentSoft: Color(0xFFF0E8E4),
    accentChip: Color(0xFFE6DAD4),
    accentDark: Color(0xFF6B4230),
  );

  static const emerald = EncyclopediaTopicTheme._(
    accent: Color(0xFF2D7A5A),
    accentSoft: Color(0xFFE6F0EC),
    accentChip: Color(0xFFD4E4DC),
    accentDark: Color(0xFF1E5C42),
  );

  static const indigo = EncyclopediaTopicTheme._(
    accent: Color(0xFF4A5080),
    accentSoft: Color(0xFFEAEAF2),
    accentChip: Color(0xFFDCDCE8),
    accentDark: Color(0xFF323866),
  );

  static const copper = EncyclopediaTopicTheme._(
    accent: Color(0xFFA0734A),
    accentSoft: Color(0xFFF0E8E0),
    accentChip: Color(0xFFE6DCD0),
    accentDark: Color(0xFF7A5832),
  );

  static const asphalt = EncyclopediaTopicTheme._(
    accent: Color(0xFF6A6E78),
    accentSoft: Color(0xFFECEDF0),
    accentChip: Color(0xFFDEE0E4),
    accentDark: Color(0xFF4E525C),
  );

  static const List<EncyclopediaTopicTheme> all = [
    cementGray,
    navy,
    teal,
    olive,
    amber,
    maroon,
    steelBlue,
    graphite,
    sand,
    brick,
    emerald,
    indigo,
    copper,
    asphalt,
  ];

  static const EncyclopediaTopicTheme defaultTheme = cementGray;

  static EncyclopediaTopicTheme fromKey(String? key) {
    return switch (key) {
      'navy' => navy,
      'teal' => teal,
      'olive' => olive,
      'amber' => amber,
      'maroon' => maroon,
      'steel_blue' => steelBlue,
      'graphite' => graphite,
      'sand' => sand,
      'brick' => brick,
      'emerald' => emerald,
      'indigo' => indigo,
      'copper' => copper,
      'asphalt' => asphalt,
      _ => cementGray,
    };
  }
}
