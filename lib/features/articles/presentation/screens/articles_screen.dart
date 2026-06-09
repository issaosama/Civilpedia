import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../data/repositories/article_repository.dart';

class ArticlesScreen extends StatelessWidget {
  final String category;

  const ArticlesScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final repo = ArticleRepository();
    final articles = repo.getArticlesByCategory(category);
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: articles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final article = articles[index];
          return CustomCard(
            onTap: () => context.push('/article/${article.id}'),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  child: CachedNetworkImage(
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
                    children: [
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.category,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left),
              ],
            ),
          );
        },
      ),
    );
  }
}
