import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// A reusable label/value row for calculator result cards.
///
/// Responsive: long labels wrap safely, value never overflows, and the layout
/// works in both LTR and RTL.
class CalculatorResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final EdgeInsetsGeometry padding;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const CalculatorResultRow({
    super.key,
    required this.label,
    required this.value,
    this.isBold = false,
    this.padding = const EdgeInsets.symmetric(vertical: 3),
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultLabelColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final defaultValueColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: labelStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    color: defaultLabelColor,
                    fontSize: 14,
                  ),
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: valueStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    color: defaultValueColor,
                    fontSize: 14,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  ),
              textAlign: TextAlign.end,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
