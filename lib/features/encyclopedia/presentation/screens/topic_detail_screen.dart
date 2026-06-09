import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/encyclopedia_provider.dart';
import '../widgets/section_header_widget.dart';
import '../widgets/content_block_widget.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';

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
    final provider = context.watch<EncyclopediaProvider>();
    final topic = provider.currentTopic;

    return Scaffold(
      appBar: AppBar(
        title: Text(topic?.titleAr ?? ''),
      ),
      body: AsyncValueWidget(
        isLoading: provider.isLoading,
        error: provider.error,
        isEmpty: topic == null && provider.error == null,
        onRetry: () => provider.loadTopicDetail(widget.topicId),
        onEmpty: () => const Center(
          child: Text('الموضوع غير موجود',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        onData: () => _content(context, provider, topic!),
      ),
    );
  }

  Widget _content(BuildContext context, EncyclopediaProvider provider, dynamic topic) {
    final sections = provider.currentSections;
    return ListView(
      padding: AppSpacing.padLg,
      children: [
        _summaryCard(context, topic),
        AppSpacing.gapLg,
        if (sections.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('لا توجد أقسام بعد',
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
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Text('لا توجد محتويات بعد',
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

  Widget _summaryCard(BuildContext context, dynamic topic) {
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
            topic.titleAr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (topic.titleEn != null) ...[
            const SizedBox(height: 4),
            Text(
              topic.titleEn,
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
