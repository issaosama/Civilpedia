import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../monetization/domain/entities/sponsored_placement.dart';
import '../../../profile/domain/service_business_profile.dart';
import '../directory_provider_card.dart';

/// W7.2 — Sponsorship disclosure wrapper for the Directory search result list.
///
/// This component owns the SPONSORED presentation only. It renders the campaign
/// disclosure clearly and adjacently, then reuses the REAL [DirectoryProviderCard]
/// for the resolved REAL [ServiceBusinessProfile] (sponsored ≠ second entity).
///
/// [DirectoryProviderCard] itself stays organic and sponsorship-neutral — it is
/// NOT given a monetization authority here, and its provider UI is NOT
/// duplicated.
///
/// Disclosure rules (W7.2 §8):
/// - shows [SponsoredPlacement.disclosureLabel] visibly, NOT hidden behind
///   interaction;
/// - never derived from verificationStatus / featured / foundingPartner /
///   planType;
/// - never blended into ordinary provider metadata so it cannot be mistaken for
///   a verification badge.
class DirectorySponsoredProviderCard extends StatelessWidget {
  const DirectorySponsoredProviderCard({
    super.key,
    required this.placement,
    required this.profile,
    this.onTap,
  });

  /// The Monetization-owned resolution that disclosed and authorized this
  /// sponsored presentation.
  final SponsoredPlacement placement;

  /// The real Directory provider being presented.
  final ServiceBusinessProfile profile;

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
        DirectoryProviderCard(profile: profile, onTap: onTap),
      ],
    );
  }
}

/// Compact, clearly-disclosed sponsorship marker shown above the sponsored
/// provider card. Deliberately distinct from the verification badge (no icon
/// reuse, warning-tinted surface) so it cannot be mistaken for verification.
class _DisclosureChip extends StatelessWidget {
  const _DisclosureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.primaryDark;

    return Semantics(
      label: label,
      container: true,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ads_click_outlined, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
