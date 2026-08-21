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
/// Phase B corrected the data ownership: categories now come from the shared
/// [EncyclopediaProvider] (authoritative catalog), NOT from the legacy
/// [ArticleRepository]. Tapping a category routes into the same
/// category→topics→detail flow used by the Encyclopedia tab.
class CategoriesSection extends StatefulWidget {
  const CategoriesSection({super.key});

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EncyclopediaProvider>();
    final categories = provider.categories.values.toList();

    if (provider.isLoading && categories.isEmpty) {
      return SizedBox(
        height: 130,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
          ),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => const ShimmerCategoryCard(),
        ),
      );
    }

    if (provider.error != null && categories.isEmpty) {
      return SizedBox(
        height: 130,
        child: ErrorStateWidget(
          onRetry: () => context.read<EncyclopediaProvider>().loadAllTopics(),
        ),
      );
    }

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
        ),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          return EncyclopediaCategoryCard(
            width: 110,
            height: 130,
            title: category.titleAr,
            onTap: () => context.push('/encyclopedia/topics/${category.id}'),
          );
        },
      ),
    );
  }
}
