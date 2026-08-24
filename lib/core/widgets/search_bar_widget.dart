import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/design_tokens.dart';
import '../../localization/ar.dart';

/// Search field used by Home and Encyclopedia.
///
/// Supports a light-surface variant (Home) and the existing dark-surface
/// variant (Encyclopedia). The D2B cleanup keeps the same public API while
/// replacing raw hardcoded colors with semantic tokens and making the layout
/// direction-aware.
class SearchBarWidget extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;

  /// When true, the search field renders with dark text/icons on a light
  /// surface, suitable for the Home header. Defaults to the existing dark
  /// surface styling used by EncyclopediaScreen.
  final bool lightSurface;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintText = Ar.search,
    this.lightSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    final darkSurfaceColor = AppColors.darkTextPrimary;

    final textColor = lightSurface ? AppColors.mainText : darkSurfaceColor;
    final hintColor = lightSurface
        ? AppColors.textSecondary.withValues(alpha: 0.75)
        : darkSurfaceColor.withValues(alpha: 0.6);
    final iconColor = lightSurface
        ? AppColors.textSecondary
        : darkSurfaceColor.withValues(alpha: 0.7);
    final fillColor = lightSurface
        ? AppColors.surfacePrimary.withValues(alpha: 0.95)
        : darkSurfaceColor.withValues(alpha: 0.12);
    final borderColor = lightSurface
        ? AppColors.border.withValues(alpha: 0.8)
        : Colors.transparent;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusSearch),
      borderSide: BorderSide(color: borderColor),
    );
    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusSearch),
      borderSide: BorderSide(color: borderColor.withValues(alpha: 0.5)),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusSearch),
      borderSide: BorderSide(color: borderColor.withValues(alpha: 0.8), width: 1.5),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      textAlign: TextAlign.start,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(Icons.search, color: iconColor),
        filled: true,
        fillColor: fillColor,
        border: border,
        enabledBorder: enabledBorder,
        focusedBorder: focusedBorder,
        contentPadding: const EdgeInsetsDirectional.only(
          start: 20,
          end: 20,
          top: 14,
          bottom: 14,
        ),
      ),
      style: TextStyle(color: textColor),
    );
  }
}
