import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../localization/ar.dart';

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
    final textColor = lightSurface ? AppColors.mainText : const Color(0xFFF0ECE2);
    final hintColor = lightSurface
        ? AppColors.textSecondary.withValues(alpha: 0.8)
        : const Color(0xFFF0ECE2).withValues(alpha: 0.6);
    final iconColor = lightSurface
        ? AppColors.textSecondary
        : const Color(0xFFF0ECE2).withValues(alpha: 0.7);
    final fillColor = lightSurface
        ? AppColors.surface.withValues(alpha: 0.8)
        : const Color(0xFFF0ECE2).withValues(alpha: 0.12);
    final borderColor = lightSurface ? AppColors.border : Colors.transparent;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(Icons.search, color: iconColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: borderColor.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: borderColor.withValues(alpha: 0.8), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      style: TextStyle(color: textColor),
    );
  }
}
