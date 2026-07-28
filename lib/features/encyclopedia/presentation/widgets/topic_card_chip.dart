import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../theme/encyclopedia_card_colors.dart';
import '../../domain/entities/engineering_topic.dart';

List<String> topicCardLabels(EngineeringTopic topic, {int maxChips = 2}) {
  final source = topic.keyTopics.isNotEmpty ? topic.keyTopics : topic.tags;
  return source
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .take(maxChips)
      .toList();
}

class TopicCardChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const TopicCardChip({super.key, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? EncyclopediaCardColors.chipDarkBg : EncyclopediaCardColors.chipBg,
        border: Border.all(
          color: isDark ? EncyclopediaCardColors.chipDarkBorder : EncyclopediaCardColors.chipBorder,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: isDark ? EncyclopediaCardColors.chipDarkText : EncyclopediaCardColors.chipText,
            ),
      ),
    );
  }
}
