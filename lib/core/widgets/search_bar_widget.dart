import 'package:flutter/material.dart';

import '../../localization/ar.dart';
import '../../localization/en.dart';
import '../theme/design_tokens.dart';

/// Canonical Civilpedia search field.
///
/// The active theme owns palette and contrast. [lightSurface] remains as a
/// compatibility selector between the standard and grouped light surfaces;
/// dark mode always uses its frozen grouped surface.
class SearchBarWidget extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Invoked when the user taps the field. Used by read-only launchers.
  final VoidCallback? onTap;

  /// An explicit localized hint. When omitted, the widget derives its default
  /// Arabic or English hint from the active locale.
  final String? hintText;

  final bool lightSurface;
  final bool readOnly;
  final bool autofocus;

  /// Uses the same search contract in a denser 48px presentation.
  final bool compact;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.hintText,
    this.lightSurface = false,
    this.readOnly = false,
    this.autofocus = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final effectiveHint = hintText ?? (isArabic ? Ar.search : En.search);
    final fillColor = isDark
        ? colorScheme.surfaceContainer
        : lightSurface
        ? colorScheme.surface
        : colorScheme.surfaceContainer;

    OutlineInputBorder outline(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSearch),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      readOnly: readOnly,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      textAlign: TextAlign.start,
      style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: effectiveHint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        prefixIcon: Icon(Icons.search_rounded, size: compact ? 22 : 24),
        prefixIconConstraints: compact
            ? const BoxConstraints(minWidth: 48, minHeight: 48)
            : null,
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? colorScheme.secondary
              : colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: fillColor,
        border: outline(colorScheme.outlineVariant),
        enabledBorder: outline(colorScheme.outlineVariant),
        focusedBorder: outline(colorScheme.secondary, width: 2),
        isDense: compact,
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: compact ? 16 : 20,
          vertical: compact ? 10 : 14,
        ),
        constraints: BoxConstraints(minHeight: compact ? 48 : 56),
      ),
    );
  }
}
