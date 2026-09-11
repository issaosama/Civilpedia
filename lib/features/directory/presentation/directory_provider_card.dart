import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/language_provider.dart';
import '../../../core/theme/app_colors.dart';
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
/// Excludes contact, address, description, saved/bookmark, and monetization
/// signals — the detail surface owns full provider information.
class DirectoryProviderCard extends StatelessWidget {
  final CanonicalDirectoryEntity entity;
  final VoidCallback? onTap;

  const DirectoryProviderCard({
    super.key,
    required this.entity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final typeLabel = CanonicalEntityTypePresentation.labelFor(
      entity.entityType,
      isArabic: isArabic,
    );
    final locationLabel = _locationLabel(entity, isArabic);
    final categories = _displayCategories(entity);

    return CivilSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusIcon),
            ),
            child: Icon(
              CanonicalEntityTypePresentation.iconFor(entity.entityType),
              color: AppColors.primaryDark,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (locationLabel != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    categories.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: DirectoryVerificationBadge(
                    status: entity.verificationStatus,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _displayCategories(CanonicalDirectoryEntity entity) {
    final result = <String>[];
    for (final cat in entity.categories) {
      final name = cat.name.trim();
      if (name.isNotEmpty) result.add(name);
    }
    return result;
  }

  static String? _locationLabel(CanonicalDirectoryEntity entity, bool isArabic) {
    if (entity.locations.isEmpty) return null;
    final first = entity.locations.first;
    final regionName = first.regionName;
    if (regionName != null && regionName.isNotEmpty) return regionName;
    // Fallback to region code when name is not available.
    return first.regionCode.isNotEmpty ? first.regionCode : null;
  }
}
