import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Canonical reusable surface primitive for the Civilpedia design system.
///
/// Owns surface color, border, radius, shadow, clip and generic tap behavior.
/// Feature widgets compose this primitive and remain responsible for their own
/// content, icons, business meaning and navigation.
///
/// Defaults are theme-aware: the primary surface uses [ColorScheme.surface] and
/// the warm variant uses [ColorScheme.surfaceContainer]. Explicit [color]
/// overrides are still respected.
class CivilSurfaceCard extends StatelessWidget {
  /// Child widget rendered inside the card surface.
  final Widget child;

  /// Optional tap callback. When provided, the card wraps the child in an
  /// [InkWell] with matching border radius and ripple.
  final VoidCallback? onTap;

  /// Explicit surface color. When null, [warm] selects between the canonical
  /// primary and warm surfaces derived from the active theme.
  final Color? color;

  /// Use the warm secondary surface ([ColorScheme.surfaceContainer]) instead of
  /// the default primary elevated surface.
  final bool warm;

  /// Whether to draw the canonical subtle border using the theme divider color.
  final bool hasBorder;

  /// Internal padding. Defaults to a direction-aware 16 logical pixels.
  final EdgeInsetsGeometry? padding;

  /// Border radius. Defaults to [DesignTokens.radiusMd].
  final double? radius;

  /// Elevation / shadow level. Defaults to [DesignTokens.elevation2].
  final double? elevation;

  /// Clip behavior. Defaults to [Clip.antiAlias] so children respect the radius.
  final Clip clipBehavior;

  const CivilSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.warm = false,
    this.hasBorder = false,
    this.padding,
    this.radius,
    this.elevation,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = color ?? (warm ? colorScheme.surfaceContainer : colorScheme.surface);
    final effectiveRadius = radius ?? DesignTokens.radiusMd;
    final effectiveElevation = elevation ?? DesignTokens.elevation2;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(effectiveRadius),
      side: hasBorder ? BorderSide(color: theme.dividerTheme.color ?? colorScheme.outline) : BorderSide.none,
    );

    final borderRadius = BorderRadius.circular(effectiveRadius);
    final content = Padding(
      padding: padding ?? const EdgeInsetsDirectional.all(16),
      child: child,
    );

    final cardContent = onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: content,
          )
        : content;

    return Material(
      color: effectiveColor,
      elevation: effectiveElevation,
      shadowColor: theme.shadowColor,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      clipBehavior: clipBehavior,
      child: cardContent,
    );
  }
}
