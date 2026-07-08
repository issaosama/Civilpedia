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
    accent: Color(0xFF787D88),
    accentSoft: Color(0xFFDEE0E6),
    accentChip: Color(0xFFC4C8D0),
    accentDark: Color(0xFF484C54),
  );

  static const navy = EncyclopediaTopicTheme._(
    accent: Color(0xFF1B2A4A),
    accentSoft: Color(0xFFCCD2E2),
    accentChip: Color(0xFFB0BACE),
    accentDark: Color(0xFF1E3254),
  );

  static const teal = EncyclopediaTopicTheme._(
    accent: Color(0xFF1A7A6E),
    accentSoft: Color(0xFFC8E0DC),
    accentChip: Color(0xFFAACAC4),
    accentDark: Color(0xFF0F5C52),
  );

  static const olive = EncyclopediaTopicTheme._(
    accent: Color(0xFF6B8E23),
    accentSoft: Color(0xFFD4DCBC),
    accentChip: Color(0xFFB6C69C),
    accentDark: Color(0xFF3A521A),
  );

  static const amber = EncyclopediaTopicTheme._(
    accent: Color(0xFFB47C28),
    accentSoft: Color(0xFFE6D8B4),
    accentChip: Color(0xFFCCBE96),
    accentDark: Color(0xFF8A5C1E),
  );

  static const maroon = EncyclopediaTopicTheme._(
    accent: Color(0xFF7A2834),
    accentSoft: Color(0xFFDCC8CC),
    accentChip: Color(0xFFC2B0B6),
    accentDark: Color(0xFF5A1E26),
  );

  static const steelBlue = EncyclopediaTopicTheme._(
    accent: Color(0xFF3C5C78),
    accentSoft: Color(0xFFCAD4E2),
    accentChip: Color(0xFFACBACC),
    accentDark: Color(0xFF2E4A66),
  );

  static const graphite = EncyclopediaTopicTheme._(
    accent: Color(0xFF464A52),
    accentSoft: Color(0xFFD0D2D8),
    accentChip: Color(0xFFB0B3BA),
    accentDark: Color(0xFF2C2F36),
  );

  static const sand = EncyclopediaTopicTheme._(
    accent: Color(0xFF9C8A6A),
    accentSoft: Color(0xFFDCD2BE),
    accentChip: Color(0xFFBEB49C),
    accentDark: Color(0xFF6E624E),
  );

  static const brick = EncyclopediaTopicTheme._(
    accent: Color(0xFF8B5E4A),
    accentSoft: Color(0xFFDACCC2),
    accentChip: Color(0xFFBEB0A6),
    accentDark: Color(0xFF6B4230),
  );

  static const emerald = EncyclopediaTopicTheme._(
    accent: Color(0xFF2D7A5A),
    accentSoft: Color(0xFFC4DAD0),
    accentChip: Color(0xFFA6C4B8),
    accentDark: Color(0xFF1E5C42),
  );

  static const indigo = EncyclopediaTopicTheme._(
    accent: Color(0xFF3E4470),
    accentSoft: Color(0xFFC8C8DC),
    accentChip: Color(0xFFAAAAC0),
    accentDark: Color(0xFF323866),
  );

  static const copper = EncyclopediaTopicTheme._(
    accent: Color(0xFF94663E),
    accentSoft: Color(0xFFDACABA),
    accentChip: Color(0xFFBEAE9A),
    accentDark: Color(0xFF7A5832),
  );

  static const asphalt = EncyclopediaTopicTheme._(
    accent: Color(0xFF545862),
    accentSoft: Color(0xFFCCD0D6),
    accentChip: Color(0xFFACB0B8),
    accentDark: Color(0xFF383C46),
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
