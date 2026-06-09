import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/repositories/article_repository.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  static const _categoryImages = {
    'خرسانة': 'https://images.unsplash.com/photo-1581578731546-c64695cc6942?w=400',
    'حديد': 'https://images.unsplash.com/photo-1614444442667-9e9d9c7a7a9a?w=400',
    'تربة': 'https://images.unsplash.com/photo-1531834685032-c34bf0d84c77?w=400',
    'طرق': 'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?w=400',
    'إدارة مشاريع': 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=400',
    'مساحة': 'https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=400',
  };

  @override
  Widget build(BuildContext context) {
    final categories = ArticleRepository.categories;
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final imageUrl = _categoryImages[cat.name] ?? '';
          return GestureDetector(
            onTap: () => context.push('/articles/${cat.name}'),
            child: Container(
              width: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  gradient: LinearGradient(
                    colors: [cat.color.withValues(alpha: 0.85), cat.color.withValues(alpha: 0.4)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.all(8),
                child: Text(
                  cat.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
