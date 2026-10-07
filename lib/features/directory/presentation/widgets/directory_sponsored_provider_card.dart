import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/language_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../../../monetization/domain/entities/sponsored_placement.dart';
import '../../domain/canonical_directory_entity.dart';
import '../directory_provider_card.dart';

/// W7.2 — Sponsorship disclosure wrapper for the Directory search result list.
///
/// This component owns the SPONSORED presentation only. It renders the campaign
/// disclosure clearly and adjacently, then reuses the REAL [DirectoryProviderCard]
/// for the resolved REAL V1-R05 [CanonicalDirectoryEntity] (sponsored ≠ second
/// entity).
///
/// [DirectoryProviderCard] itself stays organic and sponsorship-neutral — it is
/// NOT given a monetization authority here, and its provider UI is NOT
/// duplicated.
class DirectorySponsoredProviderCard extends StatelessWidget {
  const DirectorySponsoredProviderCard({
    super.key,
    required this.placement,
    required this.entity,
    this.onTap,
  });

  /// The Monetization-owned resolution that disclosed and authorized this
  /// sponsored presentation.
  final SponsoredPlacement placement;

  /// The real canonical Directory entity being presented.
  final CanonicalDirectoryEntity entity;

  /// Optional tap callback; when provided the underlying real provider card is
  /// interactive (opens the existing provider detail surface).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DisclosureChip(label: placement.disclosureLabel),
        const SizedBox(height: AppSpacing.sm),
        DirectoryProviderCard(entity: entity, onTap: onTap),
      ],
    );
  }
}

/// Compact, clearly-disclosed sponsorship marker shown above the sponsored
/// provider card. Deliberately distinct from the verification badge (no icon
/// reuse, separate advertising boundary) so it cannot be mistaken for verification.
class _DisclosureChip extends StatelessWidget {
  const _DisclosureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final paidLabel = isArabic
        ? Ar.cui1PaidAdvertisement
        : En.cui1PaidAdvertisement;

    return Semantics(
      label: '$label, $paidLabel',
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.ads_click_outlined,
              size: 18,
              color: colors.onSecondaryContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    paidLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
