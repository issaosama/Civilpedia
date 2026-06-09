import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/repositories/article_repository.dart';
import '../../../../localization/ar.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(title: const Text(Ar.categories)),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final imageUrl = _categoryImages[cat.name] ?? '';
          return GestureDetector(
            onTap: () => context.push('/articles/${cat.name}'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cat.color.withValues(alpha: 0.85), cat.color.withValues(alpha: 0.3)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        Icon(cat.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(cat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
