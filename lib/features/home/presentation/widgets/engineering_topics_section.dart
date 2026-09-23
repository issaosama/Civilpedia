import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'home_topic_card.dart';

/// Home's Engineering Topic Discovery section.
///
/// Surfaces exactly two authoritative encyclopedia topics directly on the
/// dashboard. Uses [EncyclopediaProvider.allTopics], never
/// [EncyclopediaProvider.topics], so the section remains independent of the
/// active Encyclopedia search/filter state.
class EngineeringTopicsSection extends StatefulWidget {
  const EngineeringTopicsSection({super.key});

  /// Number of topic cards shown on Home.
  static const int homeTopicLimit = 2;

  @override
  State<EngineeringTopicsSection> createState() =>
      _EngineeringTopicsSectionState();
}

class _EngineeringTopicsSectionState extends State<EngineeringTopicsSection> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<EncyclopediaProvider>();
    final allTopics = provider.allTopics;
    final isInitiallyLoading =
        allTopics.isEmpty &&
        (provider.isLoading || !provider.hasCompletedInitialLoad);

    if (isInitiallyLoading) {
      return const ShimmerSection(itemHeight: 200);
    }

    if (provider.error != null && allTopics.isEmpty) {
      return ErrorStateWidget(
        onRetry: () => context.read<EncyclopediaProvider>().loadAllTopics(),
      );
    }

    if (allTopics.isEmpty) {
      return const EmptyStateWidget(icon: Icons.menu_book_outlined);
    }

    final displayTopics = allTopics
        .take(EngineeringTopicsSection.homeTopicLimit)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = constraints.maxWidth < 600
            ? 16.0
            : constraints.maxWidth < 840
            ? 24.0
            : 32.0;
        final cards = [
          for (final topic in displayTopics)
            HomeTopicCard(
              topic: topic,
              isDark: isDark,
              onTap: () => context.push('/encyclopedia/topic/${topic.id}'),
            ),
        ];

        return Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
          child: constraints.maxWidth < 600
              ? Column(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      cards[i],
                      if (i < cards.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                )
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        Expanded(child: cards[i]),
                        if (i < cards.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}
