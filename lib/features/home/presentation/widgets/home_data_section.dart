import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../data/repositories/article_repository.dart';
import '../../../../localization/ar.dart';
import '../../../encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'articles_section.dart';
import 'encyclopedia_section.dart';

/// Renders Home's data-driven region from the single EncyclopediaProvider
/// authority. Reflects the real load state: initial loading (shimmer),
/// retryable error, empty catalog, or the bundled articles content.
/// Before the first load attempt completes, an empty provider is treated as
/// loading (never as an empty catalog); content stays visible during a
/// background refresh.
class HomeDataSection extends StatelessWidget {
  const HomeDataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EncyclopediaProvider>();
    final hasData = provider.allTopics.isNotEmpty;
    final showLoading =
        !hasData && (provider.isLoading || !provider.hasCompletedInitialLoad);
    final hasError = provider.error != null && !hasData;
    final isEmpty = !showLoading && !hasError && !hasData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EncyclopediaSection(),
        AppSpacing.gapSm,
        if (showLoading)
          const ShimmerSection()
        else if (hasError)
          ErrorStateWidget(
            onRetry: () => context.read<EncyclopediaProvider>().loadAllTopics(),
          )
        else if (isEmpty)
          const EmptyStateWidget(icon: Icons.menu_book_outlined)
        else ...[
          ArticlesSection(
            title: Ar.featuredArticles,
            articles: ArticleRepository().getFeaturedArticles(),
          ),
          const SizedBox(height: 8),
          ArticlesSection(
            title: Ar.latestArticles,
            articles: ArticleRepository().getLatestArticles(),
          ),
        ],
      ],
    );
  }
}
