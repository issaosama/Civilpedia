import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import '../../../../features/encyclopedia/domain/entities/engineering_topic.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../features/encyclopedia/presentation/theme/encyclopedia_card_colors.dart';

class EncyclopediaSection extends StatefulWidget {
  const EncyclopediaSection({super.key});

  @override
  State<EncyclopediaSection> createState() => _EncyclopediaSectionState();
}

const _mutedCategoryColors = {
  'concrete': Color(0xFFD4A373),
  'steel': Color(0xFFBA8A8A),
  'soil': Color(0xFF9B8B7A),
  'roads': Color(0xFF7D9B7D),
  'finishing': Color(0xFFB8A88A),
  'general': Color(0xFFB0A090),
};

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
    // Force Theme dependency so this widget always rebuilds on theme switch,
    // even when topics is empty (avoiding stale colors from early-return).
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topics = context.watch<EncyclopediaProvider>().topics;
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    if (topics.isEmpty) return const SizedBox(height: 200);

    final isDarkCard = isDark;
    final cardMuted = mutedText;

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final topic = topics[index];
          return _topicCard(context, topic, isDark: isDarkCard, mutedText: cardMuted);
        },
      ),
    );
  }

  Widget _topicCard(BuildContext context, dynamic topic, {required bool isDark, required Color mutedText}) {
    final hasCover = topic.coverImageUrl != null && topic.coverImageUrl!.trim().isNotEmpty;
    return GestureDetector(
      onTap: () => context.push('/encyclopedia/topic/${topic.id}'),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
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
                          ?.copyWith(color: mutedText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    ..._cardChips(topic, isDark: isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryHeader(String id) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _categoryColor(id),
            _categoryColor(id).withValues(alpha: 0.5),
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
          _categoryIcon(id),
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

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

  List<Widget> _cardChips(EngineeringTopic topic, {required bool isDark}) {
    final chips = _cardChipLabels(topic);
    if (chips.isEmpty) return const [];
    return [
      Wrap(
        spacing: 4,
        runSpacing: 2,
        children: chips.map((chip) => _buildChip(chip, isDark: isDark)).toList(),
      ),
    ];
  }

  List<String> _cardChipLabels(EngineeringTopic topic) {
    final source = topic.keyTopics.isNotEmpty ? topic.keyTopics : topic.tags;
    return source
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .take(2)
        .toList();
  }

  Widget _buildChip(String label, {required bool isDark}) {
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
