import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/shell_content_insets.dart';
import '../../../core/services/language_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/civil_app_bar.dart';
import '../../../core/widgets/civil_surface_card.dart';
import '../../../core/widgets/search_bar_widget.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../../routes/app_routes.dart';
import 'canonical_entity_type_presentation.dart';

/// Canonical nine-type Directory browse surface. It performs no entity reads,
/// shows no counts, and retains the supplied category navigation callback.
class DirectoryLandingScreen extends StatelessWidget {
  final ValueChanged<String>? onCategorySelected;
  final double bottomContentPadding;

  const DirectoryLandingScreen({
    super.key,
    this.onCategorySelected,
    this.bottomContentPadding = AppSpacing.huge,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final theme = Theme.of(context);
    final types = CanonicalEntityTypePresentation.orderedTypes;
    final isShellHosted = ShellContentInsets.maybeOf(context) != null;
    final effectiveBottomPadding = isShellHosted
        ? shellSafeBottomPadding(context)
        : bottomContentPadding + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: CivilAppBar(
        showBackButton: false,
        title: Text(
          isArabic ? Ar.directoryLandingTitle : En.directoryLandingTitle,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final gutter = width < 600
              ? AppSpacing.lg
              : width < 840
              ? AppSpacing.xxl
              : 2 * AppSpacing.lg;
          final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final columns = width < 600
              ? (width < 360 || textScale > 1.4 ? 1 : 2)
              : width < 840
              ? 3
              : 4;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  AppSpacing.xxl,
                  gutter,
                  AppSpacing.xxl,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            isArabic
                                ? Ar.cui1Introduction
                                : En.cui1Introduction,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          SearchBarWidget(
                            readOnly: true,
                            lightSurface: true,
                            hintText: isArabic
                                ? Ar.directorySearchHint
                                : En.directorySearchHint,
                            onTap: () => GoRouter.maybeOf(
                              context,
                            )?.push(AppRoutes.directorySearch),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          Text(
                            isArabic ? Ar.cui1BrowseTypes : En.cui1BrowseTypes,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsetsDirectional.only(
                  start: gutter,
                  end: gutter,
                  bottom: effectiveBottomPadding,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: LayoutBuilder(
                        builder: (context, gridConstraints) {
                          final tileWidth =
                              (gridConstraints.maxWidth -
                                  AppSpacing.lg * (columns - 1)) /
                              columns;
                          return Wrap(
                            key: const ValueKey('cui1-landing-grid'),
                            spacing: AppSpacing.lg,
                            runSpacing: AppSpacing.lg,
                            children: [
                              for (final entityType in types)
                                SizedBox(
                                  width: tileWidth,
                                  child: _CategoryCard(
                                    entityType: entityType,
                                    onTap: onCategorySelected == null
                                        ? null
                                        : () => onCategorySelected!(entityType),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
    final colors = theme.colorScheme;
    final label = CanonicalEntityTypePresentation.labelFor(
      entityType,
      isArabic: isArabic,
    );

    return CivilSurfaceCard(
      onTap: onTap,
      hasBorder: true,
      elevation: DesignTokens.elevation0,
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 108),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusIcon),
              ),
              child: Icon(
                CanonicalEntityTypePresentation.iconFor(entityType),
                size: 24,
                color: colors.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              label,
              textAlign: TextAlign.start,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
