import 'package:flutter/material.dart';

class DesignTokens {
  DesignTokens._();

  // Radii: small 12, icon 14, card 18, large 26, xl 30
  static const double radiusXs = 8;
  static const double radiusSm = 12;    // small components
  static const double radiusIcon = 14;  // icon containers
  static const double radiusMd = 18;    // cards / tiles
  static const double radiusLg = 26;    // large containers
  static const double radiusXl = 30;    // bottom nav / extra large
  static const double radiusFull = 999;

  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 600);

  static const Curve curveFast = Curves.easeOut;
  static const Curve curveNormal = Curves.easeInOut;
  static const Curve curveSpring = Curves.elasticOut;

  static const double elevation1 = 1;
  static const double elevation2 = 3;
  static const double elevation3 = 6;
  static const double elevation4 = 12;

  static List<BoxShadow> softShadow(Color shadowColor) => [
        BoxShadow(color: shadowColor.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
        BoxShadow(color: shadowColor.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
      ];

  // Slightly stronger shadow for cards on cement background
  static List<BoxShadow> cardShadow(Color shadowColor) => [
        BoxShadow(color: shadowColor.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 2)),
        BoxShadow(color: shadowColor.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 6)),
      ];
}
