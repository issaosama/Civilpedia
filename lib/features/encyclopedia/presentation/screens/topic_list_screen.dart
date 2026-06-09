import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/encyclopedia_provider.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';

class TopicListScreen extends StatefulWidget {
  final String categoryId;

  const TopicListScreen({super.key, required this.categoryId});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<EncyclopediaProvider>()
          .loadTopicsByCategory(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EncyclopediaProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(_categoryLabel(widget.categoryId))),
      body: AsyncValueWidget(
        isLoading: provider.isLoading,
        error: provider.error,
        isEmpty: provider.topics.isEmpty && provider.error == null,
        onRetry: () => provider.loadTopicsByCategory(widget.categoryId),
        onEmpty: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book, size: 48, color: AppColors.textSecondary),
              SizedBox(height: 12),
              Text('لا توجد مواضيع في هذا التصنيف بعد',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        onData: () => ListView.separated(
          padding: AppSpacing.padLg,
          itemCount: provider.topics.length,
          separatorBuilder: (_, __) => AppSpacing.gapMd,
          itemBuilder: (context, index) =>
              _topicCard(context, provider.topics[index]),
        ),
      ),
    );
  }

  Widget _topicCard(BuildContext context, EngineeringTopic topic) {
    return Card(
      elevation: DesignTokens.elevation1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        onTap: () => context.push('/encyclopedia/topic/${topic.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                    child: Icon(Icons.menu_book,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.titleAr,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (topic.titleEn != null)
                          Text(
                            topic.titleEn!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                topic.summary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (topic.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: topic.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusFull),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String id) {
    const labels = {
      'concrete': 'الخرسانة',
      'steel': 'الحديد',
      'soil': 'التربة',
      'roads': 'الطرق',
    };
    return labels[id] ?? id;
  }
}
