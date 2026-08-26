import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared header primitive for the Civilpedia design system.
///
/// Provides the approved header hierarchy without forcing every feature screen
/// to look identical. Defaults are theme-aware; explicit color overrides remain
/// supported for feature-specific needs.
class CivilAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Primary title widget, typically a [Text].
  final Widget? title;

  /// Whether to show the automatic back/close button when appropriate.
  /// Defaults to true. Ignored when [leading] is provided.
  final bool showBackButton;

  /// Optional leading widget. When provided, [showBackButton] is ignored.
  final Widget? leading;

  /// Optional trailing actions.
  final List<Widget>? actions;

  /// Optional bottom widget (e.g. a TabBar).
  final PreferredSizeWidget? bottom;

  /// Whether to show a subtle 1-px bottom divider.
  final bool showDivider;

  /// Elevation. Defaults to 0 because the preferred look is flat with an
  /// optional divider.
  final double? elevation;

  /// AppBar background color. Defaults to the theme scaffold/page background.
  final Color? backgroundColor;

  /// Foreground color for icons and the automatic back button. Defaults to the
  /// theme onSurface color.
  final Color? foregroundColor;

  /// Title text color when [title] is a string-less widget. Defaults to the
  /// theme onSurface color.
  final Color? titleColor;

  const CivilAppBar({
    super.key,
    this.title,
    this.showBackButton = true,
    this.leading,
    this.actions,
    this.bottom,
    this.showDivider = true,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveBackground = backgroundColor ?? theme.scaffoldBackgroundColor;
    final effectiveForeground = foregroundColor ?? colorScheme.onSurface;
    final effectiveTitleColor = titleColor ?? colorScheme.onSurface;
    final effectiveElevation = elevation ?? 0;
    final isDark = theme.brightness == Brightness.dark;

    final titleWidget = title is Text
        ? DefaultTextStyle.merge(
            style: theme.textTheme.titleLarge?.copyWith(
                  color: effectiveTitleColor,
                  fontWeight: FontWeight.bold,
                ),
            child: title!,
          )
        : title;

    PreferredSizeWidget? bottomWidget = bottom;
    if (showDivider && bottom == null) {
      bottomWidget = PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: theme.dividerTheme.color ?? colorScheme.outline),
      );
    }

    return AppBar(
      automaticallyImplyLeading: showBackButton && leading == null,
      leading: leading,
      title: titleWidget,
      actions: actions,
      bottom: bottomWidget,
      backgroundColor: effectiveBackground,
      foregroundColor: effectiveForeground,
      elevation: effectiveElevation,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    final dividerHeight = showDivider && bottom == null ? 1.0 : 0.0;
    return Size.fromHeight(kToolbarHeight + bottomHeight + dividerHeight);
  }
}
