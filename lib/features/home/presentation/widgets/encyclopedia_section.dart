import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';

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
      context.read<EncyclopediaProvider>().loadAllTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final topics = context.watch<EncyclopediaProvider>().topics;
    if (topics.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final topic = topics[index];
          return _topicCard(context, topic);
        },
      ),
    );
  }

  Widget _topicCard(BuildContext context, dynamic topic) {
    return GestureDetector(
      onTap: () => context.push('/encyclopedia/topic/${topic.id}'),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
          boxShadow: DesignTokens.softShadow(AppColors.cardShadow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _categoryColor(topic.categoryId),
                    _categoryColor(topic.categoryId).withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(DesignTokens.radiusMd),
                  topRight: Radius.circular(DesignTokens.radiusMd),
                ),
              ),
              child: Center(
                child: Icon(
                  _categoryIcon(topic.categoryId),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.titleAr,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.summary,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (topic.tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: topic.tags.take(2).map<Widget>((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusFull),
                            ),
                            child: Text(
                              tag,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 9,
                                  ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String id) {
    return switch (id) {
      'concrete' => const Color(0xFF1565C0),
      'steel' => const Color(0xFFC62828),
      'soil' => const Color(0xFF795548),
      'roads' => const Color(0xFF2E7D32),
      _ => AppColors.primary,
    };
  }

  IconData _categoryIcon(String id) {
    return switch (id) {
      'concrete' => Icons.view_agenda,
      'steel' => Icons.build,
      'soil' => Icons.terrain,
      'roads' => Icons.signpost,
      _ => Icons.menu_book,
    };
  }
}
