import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../encyclopedia/presentation/providers/encyclopedia_provider.dart';
import '../../../encyclopedia/presentation/widgets/encyclopedia_category_card.dart';

/// Home's horizontal category strip.
///
/// Phase B corrected the data ownership: categories come from the shared
/// [EncyclopediaProvider] (authoritative catalog), NOT from the legacy
/// [ArticleRepository]. Phase C polishes presentation and limits Home to a
/// compact, useful subset while keeping the full catalog reachable via View All.
class CategoriesSection extends StatefulWidget {
  const CategoriesSection({super.key});

  /// Maximum number of category cards shown on Home. The full catalog remains
  /// available through the dedicated categories screen.
  static const int homeCategoryLimit = 6;

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
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

  int _topicCountFor(
    EncyclopediaProvider provider,
    String categoryId,
  ) {
    return provider.allTopics.where((t) => t.categoryId == categoryId).length;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EncyclopediaProvider>();
    final categories = provider.categories.values.toList();

    if (provider.isLoading && categories.isEmpty) {
      return SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
          ),
          itemCount: CategoriesSection.homeCategoryLimit,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => const ShimmerCategoryCard(),
        ),
      );
    }

    if (provider.error != null && categories.isEmpty) {
      return SizedBox(
        height: 150,
        child: ErrorStateWidget(
          onRetry: () => context.read<EncyclopediaProvider>().loadAllTopics(),
        ),
      );
    }

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayCategories = categories.take(CategoriesSection.homeCategoryLimit).toList();

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
        ),
        itemCount: displayCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = displayCategories[index];
          return EncyclopediaCategoryCard(
            compact: true,
            width: 100,
            height: 112,
            title: category.titleAr,
            topicCount: _topicCountFor(provider, category.id),
            onTap: () => context.push('/encyclopedia/topics/${category.id}'),
          );
        },
      ),
    );
  }
}
