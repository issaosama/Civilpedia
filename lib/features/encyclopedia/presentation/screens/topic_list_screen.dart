import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/encyclopedia_provider.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/civil_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../widgets/topic_list_card.dart';

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
      appBar: CivilAppBar(
        title: Text(provider.categoryLabel(widget.categoryId, isArabic: isArabic)),
      ),
      body: AsyncValueWidget(
        isLoading: provider.isLoading,
        error: provider.error,
        isEmpty: provider.categoryTopics.isEmpty && provider.error == null,
        onRetry: () => provider.loadTopicsByCategory(widget.categoryId),
        onEmpty: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book, size: 48, color: mutedText),
              AppSpacing.gapMd,
              Text(
                tr(Ar.noTopicsInCategory, En.noTopicsInCategory),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        onData: () => ListView.separated(
          padding: AppSpacing.padLg,
          itemCount: provider.categoryTopics.length,
          separatorBuilder: (_, __) => AppSpacing.gapMd,
          itemBuilder: (context, index) =>
              _topicCard(context, provider.categoryTopics[index], isDark: isDark),
        ),
      ),
    );
  }

  Widget _topicCard(BuildContext context, EngineeringTopic topic, {required bool isDark}) {
    return TopicListCard(
      topic: topic,
      isDark: isDark,
      onTap: () => context.push('/encyclopedia/topic/${topic.id}'),
    );
  }
}
