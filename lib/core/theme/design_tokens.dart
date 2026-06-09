import 'package:flutter/material.dart';

class DesignTokens {
  DesignTokens._();

  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
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
}
