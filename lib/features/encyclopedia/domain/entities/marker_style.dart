import 'package:flutter/material.dart';
import 'content_block.dart';

class MarkerStyle {
  final String name;
  final Color _semanticFgLight;
  final Color _semanticFgDark;
  final Color _semanticBgLight;
  final Color _semanticBgDark;
  final String _symbol;
  final Color _symbolFgLight;
  final Color _symbolFgDark;

  const MarkerStyle._({
    required this.name,
    required Color semanticFgLight,
    required Color semanticFgDark,
    required Color semanticBgLight,
    required Color semanticBgDark,
    required String symbol,
    required Color symbolFgLight,
    required Color symbolFgDark,
  })  : _semanticFgLight = semanticFgLight,
        _semanticFgDark = semanticFgDark,
        _semanticBgLight = semanticBgLight,
        _semanticBgDark = semanticBgDark,
        _symbol = symbol,
        _symbolFgLight = symbolFgLight,
        _symbolFgDark = symbolFgDark;

  Color semanticFgColor(bool isDark) => isDark ? _semanticFgDark : _semanticFgLight;
  Color semanticBgColor(bool isDark) => isDark ? _semanticBgDark : _semanticBgLight;
  Color symbolColor(bool isDark) => isDark ? _symbolFgDark : _symbolFgLight;
  String get symbol => _symbol;

  bool get useTheme => false;

  static const _styles = <String, MarkerStyle>{
    'neutral': MarkerStyle._(
      name: 'neutral',
      semanticFgLight: Color(0xFF616161),
      semanticFgDark: Color(0xFFBDBDBD),
      semanticBgLight: Color(0xFFF5F5F5),
      semanticBgDark: Color(0xFF1E1E1E),
      symbol: '•',
      symbolFgLight: Color(0xFFFFFFFF),
      symbolFgDark: Color(0xFFE0E0E0),
    ),
    'inspection': MarkerStyle._(
      name: 'inspection',
      semanticFgLight: Color(0xFFEF6C00),
      semanticFgDark: Color(0xFFFF9800),
      semanticBgLight: Color(0xFFFFF3E0),
      semanticBgDark: Color(0xFF1A0F00),
      symbol: '!',
      symbolFgLight: Color(0xFFFFFFFF),
      symbolFgDark: Color(0xFFFFFFFF),
    ),
    'info': MarkerStyle._(
      name: 'info',
      semanticFgLight: Color(0xFF1976D2),
      semanticFgDark: Color(0xFF64B5F6),
      semanticBgLight: Color(0xFFE3F2FD),
      semanticBgDark: Color(0xFF001529),
      symbol: 'i',
      symbolFgLight: Color(0xFFFFFFFF),
      symbolFgDark: Color(0xFFFFFFFF),
    ),
    'warning': MarkerStyle._(
      name: 'warning',
      semanticFgLight: Color(0xFFF9A825),
      semanticFgDark: Color(0xFFFFCA28),
      semanticBgLight: Color(0xFFFFF8E1),
      semanticBgDark: Color(0xFF1A1600),
      symbol: '!',
      symbolFgLight: Color(0xFF1A1A1A),
      symbolFgDark: Color(0xFF1A1A1A),
    ),
    'critical': MarkerStyle._(
      name: 'critical',
      semanticFgLight: Color(0xFFD32F2F),
      semanticFgDark: Color(0xFFEF5350),
      semanticBgLight: Color(0xFFFFEBEE),
      semanticBgDark: Color(0xFF2A0000),
      symbol: '!',
      symbolFgLight: Color(0xFFFFFFFF),
      symbolFgDark: Color(0xFFFFFFFF),
    ),
    'success': MarkerStyle._(
      name: 'success',
      semanticFgLight: Color(0xFF388E3C),
      semanticFgDark: Color(0xFF66BB6A),
      semanticBgLight: Color(0xFFE8F5E9),
      semanticBgDark: Color(0xFF001A00),
      symbol: '✓',
      symbolFgLight: Color(0xFFFFFFFF),
      symbolFgDark: Color(0xFFFFFFFF),
    ),
    'diamond': MarkerStyle._(
      name: 'diamond',
      semanticFgLight: Color(0xFF2E7D32),
      semanticFgDark: Color(0xFF66BB6A),
      semanticBgLight: Color(0xFFE8F5E9),
      semanticBgDark: Color(0xFF001A00),
      symbol: '◆',
      symbolFgLight: Color(0xFFFFFFFF),
      symbolFgDark: Color(0xFFFFFFFF),
    ),
    'triangle': MarkerStyle._(
      name: 'triangle',
      semanticFgLight: Color(0xFF1565C0),
      semanticFgDark: Color(0xFF64B5F6),
      semanticBgLight: Color(0xFFE3F2FD),
      semanticBgDark: Color(0xFF001529),
      symbol: '▲',
      symbolFgLight: Color(0xFFFFFFFF),
      symbolFgDark: Color(0xFFFFFFFF),
    ),
    'square': MarkerStyle._(
      name: 'square',
      semanticFgLight: Color(0xFF6A1B9A),
      semanticFgDark: Color(0xFFCE93D8),
      semanticBgLight: Color(0xFFF3E5F5),
      semanticBgDark: Color(0xFF1A0029),
      symbol: '■',
      symbolFgLight: Color(0xFFFFFFFF),
      symbolFgDark: Color(0xFFFFFFFF),
    ),
    'target': MarkerStyle._(
      name: 'target',
      semanticFgLight: Color(0xFFC62828),
      semanticFgDark: Color(0xFFEF5350),
      semanticBgLight: Color(0xFFFFEBEE),
      semanticBgDark: Color(0xFF2A0000),
      symbol: '◎',
      symbolFgLight: Color(0xFFFFFFFF),
      symbolFgDark: Color(0xFFFFFFFF),
    ),
  };

  static MarkerStyle fromInspectionPoint(InspectionPoint point) {
    final key = point.effectiveMarkerStyle;
    return _styles[key]!;
  }
}
