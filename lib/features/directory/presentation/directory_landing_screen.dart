import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/shell_content_insets.dart';
import '../../../core/services/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/civil_app_bar.dart';
import '../../../core/widgets/civil_surface_card.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import 'canonical_entity_type_presentation.dart';

/// Directory Landing — heading + canonical entity type browse grid.
///
/// V1-R05 — adapted to canonical cloud `directory_entities.entity_type`
/// taxonomy (9 values) from the canonical [CanonicalEntityTypePresentation].
/// The legacy local fixed [BusinessType] taxonomy is no longer authoritative
/// on the production Directory path.
///
/// The Landing represents the taxonomy, not current data volume: it performs
/// ZERO entity reads, shows no counts, and renders identically whether or not
/// the cloud Directory has any data.
///
/// A category tap invokes [onCategorySelected] with the tapped canonical
/// entity type string. When [onCategorySelected] is null the cards are inert.
class DirectoryLandingScreen extends StatelessWidget {
  /// Reusable presentation seam for listing phase. When provided,
  /// tapping a category invokes it with the canonical entity type string.
  /// When null, no navigation and no action.
  final ValueChanged<String>? onCategorySelected;

  /// Bottom scroll padding for the category grid.
  ///
  /// Shell-independent: this screen detects the AppShell ancestor and
  /// applies the closed UI-SAFE-1 contract when hosted inside the shell.
  final double bottomContentPadding;

  const DirectoryLandingScreen({
    super.key,
    this.onCategorySelected,
    this.bottomContentPadding = AppSpacing.huge,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final types = CanonicalEntityTypePresentation.orderedTypes;

    final isShellHosted = ShellContentInsets.maybeOf(context) != null;
    final effectiveBottomPadding = isShellHosted
        ? shellSafeBottomPadding(context)
        : bottomContentPadding + MediaQuery.paddingOf(context).bottom;

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
              bottom: effectiveBottomPadding,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 140,
                crossAxisSpacing: AppSpacing.lg,
                mainAxisSpacing: AppSpacing.lg,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final entityType = types[index];
                return _CategoryCard(
                  entityType: entityType,
                  onTap: onCategorySelected == null
                      ? null
                      : () => onCategorySelected!(entityType),
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
  final String entityType;
  final VoidCallback? onTap;

  const _CategoryCard({required this.entityType, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final theme = Theme.of(context);
    final label = CanonicalEntityTypePresentation.labelFor(
      entityType,
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
              CanonicalEntityTypePresentation.iconFor(entityType),
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
