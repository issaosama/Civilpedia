import 'package:flutter/material.dart';
import 'content_block.dart';

class MarkerStyle {
  final String name;
  final Color _fgLight;
  final Color _fgDark;
  final Color _bgLight;
  final Color _bgDark;
  final String _symbol;
  final Color _symbolFgLight;
  final Color _symbolFgDark;

  const MarkerStyle._({
    required this.name,
    required Color fgLight,
    required Color fgDark,
    required Color bgLight,
    required Color bgDark,
    required String symbol,
    required Color symbolFgLight,
    required Color symbolFgDark,
  })  : _fgLight = fgLight,
        _fgDark = fgDark,
        _bgLight = bgLight,
        _bgDark = bgDark,
        _symbol = symbol,
        _symbolFgLight = symbolFgLight,
        _symbolFgDark = symbolFgDark;

  Color fgColor(bool isDark) => isDark ? _fgDark : _fgLight;
  Color bgColor(bool isDark) => isDark ? _bgDark : _bgLight;
  Color symbolColor(bool isDark) => isDark ? _symbolFgDark : _symbolFgLight;
  String get symbol => _symbol;

  static const _styles = <String, MarkerStyle>{
    'neutral': MarkerStyle._(
      name: 'neutral',
      fgLight: Color(0xFF616161),
      fgDark: Color(0xFFBDBDBD),
      bgLight: Color(0xFFF5F5F5),
      bgDark: Color(0xFF1E1E1E),
      symbol: '•',
      symbolFgLight: Color(0xFFFFFFFF),
      symbolFgDark: Color(0xFFE0E0E0),
    ),
    'inspection': MarkerStyle._(
      name: 'inspection',
      fgLight: Color(0xFFEF6C00),
      fgDark: Color(0xFFFF9800),
      bgLight: Color(0xFFFFF3E0),
      bgDark: Color(0xFF1A0F00),
      symbol: '!',
      symbolFgLight: Color(0xFFFFFFFF),
      symbolFgDark: Color(0xFFFFFFFF),
    ),
    'info': MarkerStyle._(
      name: 'info',
      fgLight: Color(0xFF1976D2),
      fgDark: Color(0xFF64B5F6),
      bgLight: Color(0xFFE3F2FD),
      bgDark: Color(0xFF001529),
      symbol: 'i',
      symbolFgLight: Color(0xFFFFFFFF),
      symbolFgDark: Color(0xFFFFFFFF),
    ),
    'warning': MarkerStyle._(
      name: 'warning',
      fgLight: Color(0xFFF9A825),
      fgDark: Color(0xFFFFCA28),
      bgLight: Color(0xFFFFF8E1),
      bgDark: Color(0xFF1A1600),
      symbol: '!',
      symbolFgLight: Color(0xFF1A1A1A),
      symbolFgDark: Color(0xFF1A1A1A),
    ),
    'critical': MarkerStyle._(
      name: 'critical',
      fgLight: Color(0xFFD32F2F),
      fgDark: Color(0xFFEF5350),
      bgLight: Color(0xFFFFEBEE),
      bgDark: Color(0xFF2A0000),
      symbol: '!',
      symbolFgLight: Color(0xFFFFFFFF),
      symbolFgDark: Color(0xFFFFFFFF),
    ),
    'success': MarkerStyle._(
      name: 'success',
      fgLight: Color(0xFF388E3C),
      fgDark: Color(0xFF66BB6A),
      bgLight: Color(0xFFE8F5E9),
      bgDark: Color(0xFF001A00),
      symbol: '✓',
      symbolFgLight: Color(0xFFFFFFFF),
      symbolFgDark: Color(0xFFFFFFFF),
    ),
  };

  static MarkerStyle fromInspectionPoint(InspectionPoint point) {
    final key = point.markerStyle;
    if (key != null && _styles.containsKey(key)) {
      return _styles[key]!;
    }
    return point.isCritical ? _styles['critical']! : _styles['inspection']!;
  }
}
