import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../localization/ar.dart';

/// The reference-style "الوصول السريع" row exposing the four current real
/// platform destinations: Encyclopedia, Tools, Articles, Saved.
///
/// No fake Directory destinations are added. Each card uses a deterministic
/// accent tint from the existing Civilpedia palette.
class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        const horizontalPadding = 16.0;
        const count = 4;
        const cardHeight = 84.0;
        final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
        final cardWidth = (availableWidth - (gap * (count - 1))) / count;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              _QuickAccessCard(
                width: cardWidth,
                height: cardHeight,
                title: Ar.encyclopedia,
                subtitle: Ar.engineeringKnowledge,
                icon: Icons.menu_book_outlined,
                route: '/encyclopedia',
                accent: AppColors.primary,
              ),
              const SizedBox(width: gap),
              _QuickAccessCard(
                width: cardWidth,
                height: cardHeight,
                title: Ar.tools,
                subtitle: Ar.calculatorsAndTools,
                icon: Icons.build_outlined,
                route: '/tools',
                accent: AppColors.success,
              ),
              const SizedBox(width: gap),
              _QuickAccessCard(
                width: cardWidth,
                height: cardHeight,
                title: Ar.articles,
                subtitle: Ar.latestArticles,
                icon: Icons.article_outlined,
                route: '/articles',
                accent: AppColors.info,
              ),
              const SizedBox(width: gap),
              _QuickAccessCard(
                width: cardWidth,
                height: cardHeight,
                title: Ar.saved,
                subtitle: Ar.savedItems,
                icon: Icons.bookmark_outline,
                route: '/saved',
                accent: AppColors.warning,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final double width;
  final double height;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color accent;

  const _QuickAccessCard({
    required this.width,
    required this.height,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: InkWell(
          onTap: () {
            // Shell branches switch tabs with go(); detail screens above the
            // shell should push so the user can return to Home.
            const shellBranches = {
              '/home',
              '/encyclopedia',
              '/tools',
              '/saved',
              '/profile',
            };
            if (shellBranches.contains(route)) {
              context.go(route);
            } else {
              context.push(route);
            }
          },
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.6)
                    : AppColors.border.withValues(alpha: 0.6),
              ),
              boxShadow: isDark ? null : DesignTokens.softShadow(AppColors.cardShadow),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusIcon),
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.mainText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
