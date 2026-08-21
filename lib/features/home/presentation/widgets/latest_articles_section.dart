import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/custom_card.dart';
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      child: Column(
        children: articles
            .take(homeArticleLimit)
            .map((article) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CustomCard(
                    onTap: () => context.push('/article/${article.id}'),
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      height: 80,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                            child: ArticleImage(
                              imageUrl: article.image,
                              width: 80,
                              height: 80,
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
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
