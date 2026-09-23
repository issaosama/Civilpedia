import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/civil_surface_card.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import 'home_preview_layout.dart';

/// Home's compact entry points to four existing product destinations.
///
/// Cards use flexible minimum sizing so Cairo line height and supported text
/// scaling can grow without clipping. Routing behavior remains unchanged.
class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String ar, String en) => isArabic ? ar : en;
    final items = [
      _QuickAccessItem(
        title: tr(Ar.encyclopedia, En.encyclopedia),
        subtitle: tr(Ar.engineeringKnowledge, En.engineeringKnowledge),
        icon: Icons.menu_book_outlined,
        route: '/encyclopedia',
        useAmber: false,
      ),
      _QuickAccessItem(
        title: tr(Ar.tools, En.tools),
        subtitle: tr(Ar.calculatorsAndTools, En.calculatorsAndTools),
        icon: Icons.build_outlined,
        route: '/tools',
        useAmber: true,
      ),
      _QuickAccessItem(
        title: tr(Ar.articles, En.articles),
        subtitle: tr(Ar.latestArticles, En.latestArticles),
        icon: Icons.article_outlined,
        route: '/articles',
        useAmber: false,
      ),
      _QuickAccessItem(
        title: tr(Ar.saved, En.saved),
        subtitle: tr(Ar.savedItems, En.savedItems),
        icon: Icons.bookmark_outline,
        route: '/saved',
        useAmber: true,
      ),
    ];

    return LayoutBuilder(
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
                  child: _QuickAccessCard(item: item),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAccessItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool useAmber;

  const _QuickAccessItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.useAmber,
  });
}

class _QuickAccessCard extends StatelessWidget {
  final _QuickAccessItem item;

  const _QuickAccessCard({required this.item});

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
        hasBorder: true,
        padding: EdgeInsets.zero,
        onTap: () {
          const shellBranches = {
            '/home',
            '/encyclopedia',
            '/tools',
            '/saved',
            '/profile',
          };
          if (shellBranches.contains(item.route)) {
            context.go(item.route);
          } else {
            context.push(item.route);
          }
        },
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
                  borderRadius: BorderRadius.circular(14),
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
