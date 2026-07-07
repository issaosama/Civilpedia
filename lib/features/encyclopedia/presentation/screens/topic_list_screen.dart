import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/encyclopedia_provider.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.watch<LanguageProvider>().isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    final provider = context.watch<EncyclopediaProvider>();
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Scaffold(
      appBar: AppBar(title: Text(_categoryLabel(widget.categoryId, tr))),
      body: AsyncValueWidget(
        isLoading: provider.isLoading,
        error: provider.error,
        isEmpty: provider.topics.isEmpty && provider.error == null,
        onRetry: () => provider.loadTopicsByCategory(widget.categoryId),
        onEmpty: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book, size: 48, color: mutedText),
              const SizedBox(height: 12),
              Text(tr(Ar.noTopicsInCategory, En.noTopicsInCategory),
                  style: TextStyle(color: mutedText)),
            ],
          ),
        ),
        onData: () => ListView.separated(
          padding: AppSpacing.padLg,
          itemCount: provider.topics.length,
          separatorBuilder: (_, __) => AppSpacing.gapMd,
          itemBuilder: (context, index) =>
              _topicCard(context, provider.topics[index], isDark: isDark),
        ),
      ),
    );
  }

  Widget _topicCard(BuildContext context, EngineeringTopic topic, {required bool isDark}) {
    final hasCover = topic.coverImageUrl != null && topic.coverImageUrl!.trim().isNotEmpty;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
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
                  hasCover
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Image.asset(
                              topic.coverImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultTopicIcon(isDark: isDark),
                            ),
                          ),
                        )
                      : _defaultTopicIcon(isDark: isDark),
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
                                ?.copyWith(color: mutedText),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left, color: mutedText),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                topic.summary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: mutedText,
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
                        color: mutedText.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusFull),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: mutedText,
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

  Widget _defaultTopicIcon({required bool isDark}) {
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final bgColor = mutedText.withValues(alpha: 0.10);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Icon(Icons.menu_book, color: mutedText, size: 22),
    );
  }

  String _categoryLabel(String id, String Function(String ar, String en) tr) {
    const labels = {
      'concrete': Ar.concreteCategory,
      'steel': Ar.steelCategory,
      'soil': Ar.soilCategory,
      'roads': Ar.roadsCategory,
      'finishing': Ar.finishingCategory,
    };
    final arLabel = labels[id] ?? id;
    if (arLabel == id) return id;
    final enLabels = {
      'concrete': En.concreteCategory,
      'steel': En.steelCategory,
      'soil': En.soilCategory,
      'roads': En.roadsCategory,
      'finishing': En.finishingCategory,
    };
    return tr(arLabel, enLabels[id] ?? id);
  }
}
