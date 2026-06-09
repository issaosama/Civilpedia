import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/theme/design_tokens.dart';

class ArticlesSection extends StatelessWidget {
  final String title;
  final List<dynamic> articles;

  const ArticlesSection({
    super.key,
    required this.title,
    required this.articles,
  });

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            itemCount: articles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final article = articles[index];
              return AnimatedListItem(
                index: index,
                child: SizedBox(
                  width: 170,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surface : Colors.white,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        width: 1,
                      ),
                      boxShadow: DesignTokens.softShadow(theme.shadowColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          onTap: () => context.push('/article/${article.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Hero(
                                tag: 'article_img_${article.id}',
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(DesignTokens.radiusMd),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: article.image,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article.title,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      article.category ?? '',
                                      style: TextStyle(fontSize: 11, color: theme.primaryColor, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
