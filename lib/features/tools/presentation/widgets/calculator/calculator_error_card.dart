import 'package:flutter/material.dart';
import '../../../../../core/theme/design_tokens.dart';

/// A reusable error card used by calculator screens.
class CalculatorErrorCard extends StatelessWidget {
  final String message;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const CalculatorErrorCard({
    super.key,
    required this.message,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(top: 12),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(
          color: errorColor.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: errorColor,
        ),
        textAlign: TextAlign.center,
        softWrap: true,
      ),
    );
  }
}
