import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/location/baghdad_area.dart';
import '../../../core/services/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/civil_surface_card.dart';
import '../../profile/domain/service_business_profile.dart';
import 'directory_category_presentation.dart';
import 'directory_verification_badge.dart';

/// W5.4 — canonical reusable Directory provider/listing card.
///
/// Scannable listing identity only: BusinessType icon, provider name, localized
/// BusinessType, localized BaghdadArea, a coarse single-line category summary
/// and a compact verification badge (W5.5). Deliberately excludes contact,
/// address, description, saved/bookmark and any Monetization signals
/// (`featured`/`foundingPartner`/`planType`) — the detail surface owns full
/// provider information (W5.4). Verification is display metadata only: it never
/// filters, reorders or hides the card.
class DirectoryProviderCard extends StatelessWidget {
  /// The provider to present.
  final ServiceBusinessProfile profile;

  /// Optional tap callback (e.g. opening the provider detail surface). When
  /// null, the card is not interactive.
  final VoidCallback? onTap;

  const DirectoryProviderCard({
    super.key,
    required this.profile,
    this.onTap,
  });

  /// Coarse category summary for the listing.
  ///
  /// Trims values, drops empties, preserves source order, joined into a single
  /// line. No sorting, no counts, no "+N", no persistence.
  static List<String> _displayCategories(ServiceBusinessProfile profile) {
    final result = <String>[];
    for (final raw in profile.categories) {
      final trimmed = raw.trim();
      if (trimmed.isNotEmpty) result.add(trimmed);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final typeLabel = DirectoryCategoryPresentation.labelFor(
      profile.type,
      isArabic: isArabic,
    );
    final locationLabel = _locationLabel(profile.baghdadArea, isArabic);
    final categories = _displayCategories(profile);

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
              DirectoryCategoryPresentation.iconFor(profile.type),
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
                  profile.name,
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
                    status: profile.verificationStatus,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _locationLabel(BaghdadArea area, bool isArabic) {
  if (area == BaghdadArea.unknown) return null;
  return isArabic ? area.arName : area.enName;
}
