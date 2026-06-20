import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/encyclopedia_provider.dart';
import '../widgets/section_header_widget.dart';
import '../widgets/content_block_widget.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';

class TopicDetailScreen extends StatefulWidget {
  final String topicId;

  const TopicDetailScreen({super.key, required this.topicId});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<EncyclopediaProvider>()
          .loadTopicDetail(widget.topicId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    final provider = context.watch<EncyclopediaProvider>();
    final topic = provider.currentTopic;

    return Scaffold(
      appBar: AppBar(
        title: Text(topic != null ? (isArabic ? topic.titleAr : (topic.titleEn ?? topic.titleAr)) : ''),
      ),
      body: AsyncValueWidget(
        isLoading: provider.isLoading,
        error: provider.error,
        isEmpty: topic == null && provider.error == null,
        onRetry: () => provider.loadTopicDetail(widget.topicId),
        onEmpty: () => Center(
          child: Text(tr(Ar.topicNotFound, En.topicNotFound),
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        onData: () => _content(context, provider, topic!, tr),
      ),
    );
  }

  Widget _content(BuildContext context, EncyclopediaProvider provider, EngineeringTopic topic, String Function(String ar, String en) tr) {
    final sections = provider.currentSections;
    return ListView(
      padding: AppSpacing.padLg,
      children: [
        _summaryCard(context, topic),
        AppSpacing.gapLg,
        if (sections.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(tr(Ar.noSectionsYet, En.noSectionsYet),
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...sections.map((section) {
            final blocks = provider.blocksForSection(section.id);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeaderWidget(section: section),
                AppSpacing.gapSm,
                if (blocks.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Text(tr(Ar.noContentYet, En.noContentYet),
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  ...blocks.map(
                    (block) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ContentBlockWidget(block: block),
                    ),
                  ),
              ],
            );
          }),
        AppSpacing.gapXl,
      ],
    );
  }

  Widget _summaryCard(BuildContext context, EngineeringTopic topic) {
    final isArabicSummary = context.watch<LanguageProvider>().isArabic;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        boxShadow: DesignTokens.softShadow(AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabicSummary ? topic.titleAr : (topic.titleEn ?? topic.titleAr),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (topic.titleEn != null && isArabicSummary) ...[
            const SizedBox(height: 4),
            Text(
              topic.titleEn!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            topic.summary,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          if (topic.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: topic.tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
