import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final card = Container(
      height: height,
      width: width,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? surface.withValues(alpha: 0.6) : surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.5)),
        boxShadow: DesignTokens.softShadow(Theme.of(context).shadowColor),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          onTap: onTap,
          child: card,
        ),
      );
    }
    return card;
  }
}
