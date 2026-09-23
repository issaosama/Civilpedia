import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/civil_surface_card.dart';
import '../../../articles/presentation/widgets/article_image.dart';

/// Reference-style compact vertical list of the latest real articles.
///
/// Shows up to [homeArticleLimit] rows with thumbnail, title, and category.
/// No fake metadata (date/read-time/popularity) is invented.
class LatestArticlesSection extends StatelessWidget {
  final List<dynamic> articles;

  const LatestArticlesSection({super.key, required this.articles});

  static const int homeArticleLimit = 3;

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = constraints.maxWidth < 600
            ? 16.0
            : constraints.maxWidth < 840
            ? 24.0
            : 32.0;
        return Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
          child: Column(
            children: articles
                .take(homeArticleLimit)
                .map(
                  (article) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CivilSurfaceCard(
                      onTap: () => context.push('/article/${article.id}'),
                      padding: EdgeInsets.zero,
                      hasBorder: true,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 88),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusMd,
                              ),
                              child: ArticleImage(
                                imageUrl: article.image,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    article.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    article.category ?? '',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
