import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../encyclopedia/domain/entities/engineering_topic.dart';
import '../../../encyclopedia/presentation/widgets/topic_card_chip.dart';

/// A HOME-ONLY wide topic discovery card.
///
/// This is intentionally separate from [TopicCompactCard] so the reference
/// Home layout can be matched without affecting Encyclopedia/Preview variants.
/// It reuses [TopicCardChip] for tag rendering and keeps typography consistent.
class HomeTopicCard extends StatelessWidget {
  final EngineeringTopic topic;
  final bool isDark;
  final VoidCallback onTap;

  const HomeTopicCard({
    super.key,
    required this.topic,
    required this.isDark,
    required this.onTap,
  });

  static const double _imageHeight = 70;

  @override
  Widget build(BuildContext context) {
    final hasCover = topic.coverImageUrl != null && topic.coverImageUrl!.trim().isNotEmpty;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final labels = topicCardLabels(topic, maxChips: 2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
          boxShadow: isDark ? null : DesignTokens.softShadow(AppColors.cardShadow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            hasCover
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(DesignTokens.radiusMd),
                      topRight: Radius.circular(DesignTokens.radiusMd),
                    ),
                    child: SizedBox(
                      height: _imageHeight,
                      width: double.infinity,
                      child: Image.asset(
                        topic.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _categoryHeader(topic.categoryId),
                      ),
                    ),
                  )
                : _categoryHeader(topic.categoryId),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    topic.titleAr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topic.summary,
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (labels.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 0,
                      children: labels
                          .map((label) => TopicCardChip(label: label, isDark: isDark))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryHeader(String id) {
    return Container(
      height: _imageHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _categoryColor(id),
            _categoryColor(id).withValues(alpha: 0.6),
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
        child: Icon(_categoryIcon(id), color: Colors.white, size: 28),
      ),
    );
  }

  static const _mutedCategoryColors = {
    'concrete': Color(0xFFD4A373),
    'steel': Color(0xFFBA8A8A),
    'soil': Color(0xFF9B8B7A),
    'roads': Color(0xFF7D9B7D),
    'finishing': Color(0xFFB8A88A),
  };

  Color _categoryColor(String id) {
    return _mutedCategoryColors[id] ?? const Color(0xFFB0A090);
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
