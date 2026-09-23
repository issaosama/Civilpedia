import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/civil_app_bar.dart';
import '../../../../core/widgets/civil_surface_card.dart';
import '../../../../data/repositories/article_repository.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../widgets/article_image.dart';

/// Full list of all legacy articles.
///
/// This screen preserves the existing repository order and canonical detail
/// navigation while presenting the list through the R10 surface language.
class AllArticlesScreen extends StatelessWidget {
  const AllArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final articles = ArticleRepository.articles;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: CivilAppBar(
        title: Text(isArabic ? Ar.allArticles : En.allArticles),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = _contentWidth(constraints.maxWidth);
          return Align(
            alignment: AlignmentDirectional.topCenter,
            child: SizedBox(
              width: contentWidth,
              height: constraints.maxHeight,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                itemCount: articles.length,
                separatorBuilder: (_, __) => AppSpacing.gapMd,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return _AllArticleCard(
                    title: article.title,
                    category: article.category,
                    imageUrl: article.image,
                    onTap: () => context.push('/article/${article.id}'),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  double _contentWidth(double width) {
    final gutter = width < 600
        ? AppSpacing.lg
        : width < 840
        ? AppSpacing.xxl
        : AppSpacing.xxl + AppSpacing.sm;
    return (width - gutter * 2).clamp(0, 760).toDouble();
  }
}

class _AllArticleCard extends StatelessWidget {
  const _AllArticleCard({
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.onTap,
  });

  final String title;
  final String category;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final forwardIcon = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left
        : Icons.chevron_right;

    return Semantics(
      button: true,
      label: title,
      child: CivilSurfaceCard(
        onTap: onTap,
        hasBorder: true,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            ArticleImage(
              imageUrl: imageUrl,
              width: 96,
              height: 104,
              fit: BoxFit.cover,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.gapSm,
                    _CategoryChip(label: category, isDark: isDark),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
              child: Icon(
                forwardIcon,
                size: 22,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarningSoft : AppColors.brandAmberSoft,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: isDark
              ? AppColors.darkBrandAmber
              : AppColors.brandAmberPressed,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
