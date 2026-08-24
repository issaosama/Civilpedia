import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Shared header primitive for the Civilpedia light design system.
///
/// Provides the approved header hierarchy (dark title on page-background or
/// light surface) without forcing every feature screen to look identical.
/// Feature AppBars are *not* migrated to this primitive in D2B; the widget is
/// built and tested here so later phases can adopt it screen-by-screen.
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

  /// AppBar background color. Defaults to the canonical page background.
  final Color? backgroundColor;

  /// Foreground color for icons and the automatic back button. Defaults to
  /// the canonical primary text color.
  final Color? foregroundColor;

  /// Title text color when [title] is a string-less widget. Defaults to the
  /// canonical primary text color.
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
    final effectiveBackground = backgroundColor ?? AppColors.pageBackground;
    final effectiveForeground = foregroundColor ?? AppColors.textPrimary;
    final effectiveTitleColor = titleColor ?? AppColors.textPrimary;
    final effectiveElevation = elevation ?? 0;

    final titleWidget = title is Text
        ? DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: effectiveTitleColor,
                  fontWeight: FontWeight.bold,
                ),
            child: title!,
          )
        : title;

    PreferredSizeWidget? bottomWidget = bottom;
    if (showDivider && bottom == null) {
      bottomWidget = const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.border),
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
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    final dividerHeight = showDivider && bottom == null ? 1.0 : 0.0;
    return Size.fromHeight(kToolbarHeight + bottomHeight + dividerHeight);
  }
}
