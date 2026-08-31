import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/civil_app_bar.dart';
import '../../../core/widgets/civil_surface_card.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../profile/domain/service_business_profile.dart';
import 'directory_category_presentation.dart';

/// Directory Landing — heading + BusinessType category browse grid.
///
/// W5.2 — first Directory presentation surface. PRODUCTION-UNEXPOSED: nothing
/// routes or navigates to this screen until the W6 readiness gate wires it.
///
/// The Landing represents the taxonomy (all 12 [BusinessType] categories), not
/// current data volume: it performs ZERO profile reads, shows no counts, and
/// renders identically whether or not `sb_profiles` has any data.
///
/// A category tap invokes [onCategorySelected] with the tapped [BusinessType].
/// When [onCategorySelected] is null the cards are inert (no navigation).
class DirectoryLandingScreen extends StatelessWidget {
  /// Reusable presentation seam for a future listing phase. When provided,
  /// tapping a category invokes it with the [BusinessType]. When null, no
  /// navigation and no action (W5.2 never pushes a route).
  final ValueChanged<BusinessType>? onCategorySelected;

  /// Bottom scroll padding for the category grid.
  ///
  /// W5.2 stays shell-independent: this screen must NOT know the AppShell
  /// floating-nav geometry (bar height, margin, safe offsets). Callers that
  /// host the Landing below chrome (e.g. a future shell branch) supply the
  /// required content clearance here; the default is normal Directory/design
  /// bottom spacing. The device bottom SafeArea inset is added at build time.
  final double bottomContentPadding;

  const DirectoryLandingScreen({
    super.key,
    this.onCategorySelected,
    this.bottomContentPadding = AppSpacing.huge,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final types = DirectoryCategoryPresentation.orderedTypes;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: CivilAppBar(
        showBackButton: false,
        title: Text(isArabic ? Ar.directoryLandingTitle : En.directoryLandingTitle),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsetsDirectional.only(
              start: AppSpacing.lg,
              end: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom: bottomContentPadding + bottomInset,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                // Fixed compact row height (~140px) so card density is stable
                // across widths and long labels never overflow.
                mainAxisExtent: 140,
                crossAxisSpacing: AppSpacing.lg,
                mainAxisSpacing: AppSpacing.lg,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final type = types[index];
                return _CategoryCard(
                  businessType: type,
                  onTap: onCategorySelected == null
                      ? null
                      : () => onCategorySelected!(type),
                );
              }, childCount: types.length),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final BusinessType businessType;
  final VoidCallback? onTap;

  const _CategoryCard({required this.businessType, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final theme = Theme.of(context);
    final label = DirectoryCategoryPresentation.labelFor(
      businessType,
      isArabic: isArabic,
    );

    return CivilSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(DesignTokens.radiusIcon),
            ),
            child: Icon(
              DirectoryCategoryPresentation.iconFor(businessType),
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.start,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
