import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/civil_surface_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../../../../routes/app_routes.dart';
import '../../../business/domain/directory_entity_types.dart';
import 'home_preview_layout.dart';

/// Home discovery preview for the existing Engineering Directory branch.
///
/// Each card enters the established Directory search route with one canonical
/// entity type. View All continues to enter the canonical Directory root.
class EngineeringDirectorySection extends StatelessWidget {
  const EngineeringDirectorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final items = [
      _DirectoryPreviewItem(
        title: isArabic
            ? Ar.homeDirectorySuppliersTitle
            : En.homeDirectorySuppliersTitle,
        subtitle: isArabic
            ? Ar.homeDirectorySuppliersSubtitle
            : En.homeDirectorySuppliersSubtitle,
        icon: Icons.inventory_2_outlined,
        entityType: DirectoryEntityType.supplier,
        useAmber: false,
      ),
      _DirectoryPreviewItem(
        title: isArabic
            ? Ar.homeDirectoryCompaniesTitle
            : En.homeDirectoryCompaniesTitle,
        subtitle: isArabic
            ? Ar.homeDirectoryCompaniesSubtitle
            : En.homeDirectoryCompaniesSubtitle,
        icon: Icons.business_outlined,
        entityType: DirectoryEntityType.company,
        useAmber: true,
      ),
      _DirectoryPreviewItem(
        title: isArabic
            ? Ar.homeDirectoryEngineeringOfficesTitle
            : En.homeDirectoryEngineeringOfficesTitle,
        subtitle: isArabic
            ? Ar.homeDirectoryEngineeringOfficesSubtitle
            : En.homeDirectoryEngineeringOfficesSubtitle,
        icon: Icons.engineering_outlined,
        entityType: DirectoryEntityType.engineeringOffice,
        useAmber: false,
      ),
      _DirectoryPreviewItem(
        title: isArabic ? Ar.directoryServices : En.directoryServices,
        subtitle: isArabic
            ? Ar.homeDirectoryServicesSubtitle
            : En.homeDirectoryServicesSubtitle,
        icon: Icons.home_repair_service_outlined,
        entityType: DirectoryEntityType.serviceProvider,
        useAmber: true,
      ),
    ];

    void openDirectory() => context.go(AppRoutes.directory);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          homeAccent: true,
          title: isArabic ? Ar.directoryLandingTitle : En.directoryLandingTitle,
          actionLabel: isArabic ? Ar.viewAll : En.viewAll,
          actionColor: Theme.of(context).colorScheme.primary,
          onAction: openDirectory,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 6),
          child: Text(
            isArabic
                ? Ar.homeDirectoryDescription
                : En.homeDirectoryDescription,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final gutter = width < 600
                ? 16.0
                : width < 840
                ? 24.0
                : 32.0;
            final columns = homePreviewColumns(context, width);
            const gap = 8.0;
            final cardWidth =
                (width - (gutter * 2) - (gap * (columns - 1))) / columns;

            return Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
              child: Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: cardWidth,
                      child: _DirectoryPreviewCard(
                        item: item,
                        onTap: () => context.push(
                          AppRoutes.directorySearch,
                          extra: item.entityType,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DirectoryPreviewItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String entityType;
  final bool useAmber;

  const _DirectoryPreviewItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.entityType,
    required this.useAmber,
  });
}

class _DirectoryPreviewCard extends StatelessWidget {
  final _DirectoryPreviewItem item;
  final VoidCallback onTap;

  const _DirectoryPreviewCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = item.useAmber
        ? (isDark ? AppColors.darkBrandAmber : AppColors.brandAmberPressed)
        : (isDark ? AppColors.darkBrandBlue : AppColors.brandBlue);
    final iconSurface = item.useAmber
        ? (isDark ? AppColors.darkWarningSoft : AppColors.brandAmberSoft)
        : (isDark ? AppColors.darkInfoSoft : AppColors.brandBlueSoft);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 104),
      child: CivilSurfaceCard(
        key: ValueKey('home-directory-${item.entityType}'),
        hasBorder: true,
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconSurface,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusIcon),
                ),
                child: Icon(item.icon, size: 18, color: accent),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
