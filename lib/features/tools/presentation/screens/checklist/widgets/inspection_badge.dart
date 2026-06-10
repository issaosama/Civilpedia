import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/design_tokens.dart';

class InspectionBadge extends StatelessWidget {
  final String label;
  final Color color;

  const InspectionBadge({
    super.key,
    required this.label,
    required this.color,
  });

  factory InspectionBadge.critical(String label) {
    return InspectionBadge(label: label, color: AppColors.error);
  }

  factory InspectionBadge.required(String label) {
    return InspectionBadge(label: label, color: AppColors.warning);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
