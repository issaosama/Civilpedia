import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/entities/engineering_topic.dart';
import 'topic_card_chip.dart';

class TopicListCard extends StatelessWidget {
  final EngineeringTopic topic;
  final bool isDark;
  final VoidCallback onTap;

  const TopicListCard({
    super.key,
    required this.topic,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCover =
        topic.coverImageUrl != null && topic.coverImageUrl!.trim().isNotEmpty;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final mutedText =
        isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  hasCover
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.radiusSm),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Image.asset(
                              topic.coverImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _defaultTopicIcon(
                                isDark: isDark,
                                mutedText: mutedText,
                              ),
                            ),
                          ),
                        )
                      : _defaultTopicIcon(
                          isDark: isDark,
                          mutedText: mutedText,
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
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (topic.titleEn != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              topic.titleEn!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: secondaryText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                      fontWeight: FontWeight.w400,
                      color: secondaryText,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _TopicCardChipsList(topic: topic, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultTopicIcon({
    required bool isDark,
    required Color mutedText,
  }) {
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
}

class _TopicCardChipsList extends StatelessWidget {
  final EngineeringTopic topic;
  final bool isDark;

  const _TopicCardChipsList({required this.topic, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final chips = topicCardLabels(topic, maxChips: 2);
    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: chips.map((chip) => TopicCardChip(label: chip, isDark: isDark)).toList(),
    );
  }
}
