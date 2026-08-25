import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/entities/engineering_topic.dart';
import 'topic_card_chip.dart';

enum TopicCompactCardVariant { home, preview }

class _TopicCompactCardConfig {
  final double width;
  final EdgeInsets internalPadding;
  final TextStyle? Function(TextTheme) titleTextStyleFromTheme;
  final int titleMaxLines;
  final double titleDescSpacing;
  final int chipMaxChips;
  final double chipWrapRunSpacing;
  final double? chipHeight;
  final double? chipPaddingTop;

  _TopicCompactCardConfig({
    required this.width,
    required this.internalPadding,
    required this.titleTextStyleFromTheme,
    required this.titleMaxLines,
    required this.titleDescSpacing,
    required this.chipMaxChips,
    required this.chipWrapRunSpacing,
    this.chipHeight,
    this.chipPaddingTop,
  });

  static _TopicCompactCardConfig fromVariant(TopicCompactCardVariant variant) {
    return switch (variant) {
      TopicCompactCardVariant.home => _TopicCompactCardConfig(
        width: 200,
        internalPadding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
        titleTextStyleFromTheme: (tt) => tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        titleMaxLines: 2,
        titleDescSpacing: 8,
        chipMaxChips: 2,
        chipWrapRunSpacing: 2,
      ),
      TopicCompactCardVariant.preview => _TopicCompactCardConfig(
        width: 160,
        internalPadding: const EdgeInsets.all(12),
        titleTextStyleFromTheme: (tt) => tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        titleMaxLines: 1,
        titleDescSpacing: 4,
        chipMaxChips: 1,
        chipWrapRunSpacing: 0,
        chipHeight: 18,
        chipPaddingTop: 6,
      ),
    };
  }
}

class TopicCompactCard extends StatelessWidget {
  final EngineeringTopic topic;
  final bool isDark;
  final TopicCompactCardVariant variant;
  final VoidCallback onTap;

  const TopicCompactCard({
    super.key,
    required this.topic,
    required this.isDark,
    required this.variant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = _TopicCompactCardConfig.fromVariant(variant);
    final hasCover = topic.coverImageUrl != null && topic.coverImageUrl!.trim().isNotEmpty;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: config.width,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
          boxShadow: isDark ? null : DesignTokens.softShadow(AppColors.cardShadow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            hasCover
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(DesignTokens.radiusMd),
                      topRight: Radius.circular(DesignTokens.radiusMd),
                    ),
                    child: SizedBox(
                      height: 80,
                      width: double.infinity,
                      child: Image.asset(
                        topic.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _categoryHeader(topic.categoryId),
                      ),
                    ),
                  )
                : _categoryHeader(topic.categoryId),
            Expanded(
              child: Padding(
                padding: config.internalPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.titleAr,
                      style: config.titleTextStyleFromTheme(tt),
                      maxLines: config.titleMaxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: config.titleDescSpacing),
                    Text(
                      topic.summary,
                      style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w400, color: secondaryText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    ..._buildChips(topic, isDark: isDark, config: config),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChips(EngineeringTopic topic, {required bool isDark, required _TopicCompactCardConfig config}) {
    final chips = topicCardLabels(topic, maxChips: config.chipMaxChips);
    if (chips.isEmpty) return const [];
    final wrap = Wrap(
      spacing: 4,
      runSpacing: config.chipWrapRunSpacing,
      children: chips.map((chip) => TopicCardChip(label: chip, isDark: isDark)).toList(),
    );
    if (config.chipPaddingTop != null || config.chipHeight != null) {
      return [
        Padding(
          padding: EdgeInsets.only(top: config.chipPaddingTop ?? 0),
          child: config.chipHeight != null ? SizedBox(height: config.chipHeight, child: wrap) : wrap,
        ),
      ];
    }
    return [wrap];
  }

  Widget _categoryHeader(String id) {
    return Container(
      height: 80,
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
        child: Icon(_categoryIcon(id), color: Colors.white, size: 32),
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
