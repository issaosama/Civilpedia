import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';

/// A neutral, scalable category card used by both the Home category strip and
/// the full categories grid.
///
/// Phase C intentionally does NOT use category-name hardcoding for icons,
/// colors, or images because the authoritative [CategoryInfo] exposes only
/// identity and titles. Visual variation is limited to a consistent
/// engineering design-system treatment; any future rich metadata must come
/// from the catalog, not from presentation code.
class EncyclopediaCategoryCard extends StatelessWidget {
  final String title;
  final int? topicCount;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  /// When true, the card renders a denser treatment suitable for the Home
  /// category rail. The full categories grid continues to use the default
  /// roomier layout.
  final bool compact;

  const EncyclopediaCategoryCard({
    super.key,
    required this.title,
    this.topicCount,
    this.onTap,
    this.width,
    this.height,
    this.compact = false,
  });

  String _countLabel(BuildContext context) {
    final count = topicCount;
    if (count == null) return '';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (count == 1) return '1 ${isArabic ? Ar.topic : En.topic}';
    return '$count ${isArabic ? Ar.topics : En.topics}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    final cardPadding = compact
        ? const EdgeInsets.all(6)
        : const EdgeInsets.all(12);
    final iconContainerSize = compact ? 32.0 : 40.0;
    final iconPadding = compact ? 6.0 : 8.0;
    final iconSize = compact ? 18.0 : 22.0;
    final titleFontSize = compact ? 12.0 : 13.0;
    final countFontSize = compact ? 10.0 : 11.0;
    final contentSpacing = compact ? 6.0 : 12.0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Container(
          width: width,
          height: height,
          padding: cardPadding,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder.withValues(alpha: 0.6)
                  : AppColors.border.withValues(alpha: 0.6),
            ),
            boxShadow: isDark
                ? null
                : DesignTokens.cardShadow(AppColors.cardShadow),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Icon(
                  Icons.category_outlined,
                  color: AppColors.primary,
                  size: iconSize,
                ),
              ),
              SizedBox(height: contentSpacing),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.mainText,
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize,
                    ),
                    maxLines: compact ? null : 2,
                    overflow: compact ? null : TextOverflow.ellipsis,
                  ),
                  if (topicCount != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _countLabel(context),
                      style: TextStyle(color: muted, fontSize: countFontSize),
                      maxLines: compact ? null : 1,
                      overflow: compact ? null : TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
