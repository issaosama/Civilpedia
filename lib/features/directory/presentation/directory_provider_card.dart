import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/language_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/civil_surface_card.dart';
import '../domain/canonical_directory_entity.dart';
import 'canonical_entity_type_presentation.dart';
import 'directory_verification_badge.dart';

/// V1-R05 — Canonical reusable Directory provider/listing card.
///
/// Scannable listing identity: canonical entity-type icon, name, localized
/// canonical entity type, canonical region summary, coarse category summary,
/// and a compact verification badge.
/// Excludes contact actions, saved/bookmark, and monetization
/// signals — the detail surface owns full provider information.
class DirectoryProviderCard extends StatelessWidget {
  final CanonicalDirectoryEntity entity;
  final VoidCallback? onTap;

  const DirectoryProviderCard({super.key, required this.entity, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final typeLabel = CanonicalEntityTypePresentation.labelFor(
      entity.entityType,
      isArabic: isArabic,
    );
    final locationLabel = _locationLabel(entity, isArabic);
    final categories = _displayCategories(entity, isArabic);
    final description = entity.description?.trim();

    return CivilSurfaceCard(
      onTap: onTap,
      radius: 18,
      elevation: 0,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      hasBorder: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(DesignTokens.radiusIcon),
            ),
            child: Icon(
              CanonicalEntityTypePresentation.iconFor(entity.entityType),
              color: colors.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entity.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      typeLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (locationLabel != null) ...[
                      Text(
                        '·',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        locationLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    DirectoryVerificationBadge(
                      status: entity.verificationStatus,
                    ),
                  ],
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      categories.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              color: colors.secondary,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  static List<String> _displayCategories(
    CanonicalDirectoryEntity entity,
    bool isArabic,
  ) {
    final result = <String>[];
    for (final cat in entity.categories) {
      final name = _firstNonEmpty([
        if (isArabic) cat.nameAr else cat.nameEn,
        if (isArabic) cat.nameEn else cat.nameAr,
        cat.name,
        cat.code,
      ]);
      if (name != null) result.add(name);
    }
    return result;
  }

  static String? _locationLabel(
    CanonicalDirectoryEntity entity,
    bool isArabic,
  ) {
    if (entity.locations.isEmpty) return null;
    final first = entity.locations.first;
    return _firstNonEmpty([
      if (isArabic) first.regionNameAr else first.regionNameEn,
      if (isArabic) first.regionNameEn else first.regionNameAr,
      first.regionName,
      first.regionCode,
    ]);
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
