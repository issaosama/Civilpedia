import 'package:flutter/material.dart';

class InspectionCategory {
  final String id;
  final String titleKey;
  final IconData icon;
  final Color accentColor;
  final int order;

  const InspectionCategory({
    required this.id,
    required this.titleKey,
    required this.icon,
    required this.accentColor,
    required this.order,
  });
}
