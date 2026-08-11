import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import '../../../../features/encyclopedia/presentation/widgets/topic_compact_card.dart';

class EncyclopediaSection extends StatefulWidget {
  const EncyclopediaSection({super.key});

  @override
  State<EncyclopediaSection> createState() => _EncyclopediaSectionState();
}

class _EncyclopediaSectionState extends State<EncyclopediaSection> {
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
    final topics = context.watch<EncyclopediaProvider>().topics;

    if (topics.isEmpty) return const SizedBox(height: 200);

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final topic = topics[index];
          return TopicCompactCard(
            topic: topic,
            isDark: isDark,
            variant: TopicCompactCardVariant.home,
            onTap: () => context.push('/encyclopedia/topic/${topic.id}'),
          );
        },
      ),
    );
  }
}
