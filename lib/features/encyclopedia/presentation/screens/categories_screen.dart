import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../localization/ar.dart';
import '../../presentation/providers/encyclopedia_provider.dart';
import '../widgets/encyclopedia_category_card.dart';

/// Full-screen view of all engineering encyclopedia categories.
///
/// Phase B realigned this route with the authoritative catalog. It no longer
/// consumes the legacy [ArticleRepository]; the source of truth is now the
/// shared [EncyclopediaProvider]. Tapping a category enters the same
/// `/encyclopedia/topics/:categoryId` flow used everywhere else.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EncyclopediaProvider>();
      if (provider.allTopics.isEmpty && !provider.isLoading) {
        provider.loadAllTopics();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EncyclopediaProvider>();
    final categories = provider.categories.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text(Ar.categories)),
      body: _buildBody(context, provider, categories),
    );
  }

  Widget _buildBody(
    BuildContext context,
    EncyclopediaProvider provider,
    List<dynamic> categories,
  ) {
    if (provider.isLoading && categories.isEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const ShimmerCategoryCard(),
      );
    }

    if (provider.error != null && categories.isEmpty) {
      return ErrorStateWidget(
        onRetry: () => context.read<EncyclopediaProvider>().loadAllTopics(),
      );
    }

    if (categories.isEmpty) {
      return const EmptyStateWidget(icon: Icons.menu_book_outlined);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return EncyclopediaCategoryCard(
          width: double.infinity,
          height: double.infinity,
          title: category.titleAr,
          onTap: () => context.push('/encyclopedia/topics/${category.id}'),
        );
      },
    );
  }
}
