import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/spacing.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: padding ?? AppSpacing.padLg,
          child: child,
        ),
      ),
    );
  }
}
