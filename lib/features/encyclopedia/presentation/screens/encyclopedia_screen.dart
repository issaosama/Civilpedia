import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/encyclopedia_provider.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../theme/encyclopedia_card_colors.dart';

const _categoryOrder = [
  'concrete',
  'steel',
  'soil',
  'roads',
  'finishing',
];

// Muted fallback colors for topic cards without a cover image.
// These are intentionally subdued earth tones that don't compete
// with actual cover photos, while still providing visual variety.
const _mutedCategoryColors = {
  'concrete': Color(0xFFD4A373),
  'steel': Color(0xFFBA8A8A),
  'soil': Color(0xFF9B8B7A),
  'roads': Color(0xFF7D9B7D),
  'finishing': Color(0xFFB8A88A),
};

String _categoryLabel(String id) {
  switch (id) {
    case 'concrete':
      return Ar.concreteCategory;
    case 'steel':
      return Ar.steelCategory;
    case 'soil':
      return Ar.soilCategory;
    case 'roads':
      return Ar.roadsCategory;
    case 'finishing':
      return Ar.finishingCategory;
    default:
      return id;
  }
}

class EncyclopediaScreen extends StatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EncyclopediaProvider>().loadAllTopics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchField({required bool isDark}) {
    final bgColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.mainText;
    final hintColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    return TextField(
      controller: _searchController,
      onChanged: (query) {
        context.read<EncyclopediaProvider>().searchTopics(query);
      },
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: Ar.search,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(Icons.search, color: iconColor),
        filled: true,
        fillColor: bgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: borderColor.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      style: TextStyle(color: textColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EncyclopediaProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String ar, String en) => isArabic ? ar : en;

    return Scaffold(
      appBar: AppBar(title: Text(tr(Ar.engineeringEncyclopedia, En.engineeringEncyclopedia))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _buildSearchField(isDark: isDark),
          ),
          Expanded(
            child: AsyncValueWidget(
              isLoading: provider.isLoading,
              error: provider.error,
              isEmpty: provider.topics.isEmpty && provider.error == null,
              onRetry: () => provider.loadAllTopics(),
              onEmpty: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    provider.isSearchActive
                        ? 'لا توجد نتائج للبحث عن "${_searchController.text}"'
                        : tr(Ar.noTopicsInCategory, En.noTopicsInCategory),
                    style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              onData: () => provider.isSearchActive
                  ? _buildSearchResults(provider, isDark: isDark)
                  : _buildCategorySections(provider, isDark: isDark, tr: tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(EncyclopediaProvider provider, {required bool isDark}) {
    return ListView.separated(
      padding: AppSpacing.padLg,
      itemCount: provider.topics.length,
      separatorBuilder: (_, __) => AppSpacing.gapMd,
      itemBuilder: (context, index) => _topicCard(context, provider.topics[index], isDark: isDark),
    );
  }

  Widget _buildCategorySections(EncyclopediaProvider provider, {required bool isDark, required String Function(String, String) tr}) {
    final grouped = <String, List<EngineeringTopic>>{};
    for (final topic in provider.topics) {
      grouped.putIfAbsent(topic.categoryId, () => []).add(topic);
    }

    final unknownKeys = grouped.keys.where((k) => !_categoryOrder.contains(k)).toList()..sort();
    final orderedKeys = _categoryOrder.where((k) => grouped.containsKey(k)).followedBy(unknownKeys).toList();

    if (orderedKeys.isEmpty) {
      return Center(
        child: Text(
          tr(Ar.noTopicsInCategory, En.noTopicsInCategory),
          style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: orderedKeys.length,
      itemBuilder: (context, index) {
        final categoryId = orderedKeys[index];
        final topics = grouped[categoryId]!;
        return _categorySection(context, categoryId, topics, isDark: isDark, tr: tr);
      },
    );
  }

  Widget _categorySection(BuildContext context, String categoryId, List<EngineeringTopic> topics, {required bool isDark, required String Function(String, String) tr}) {
    const previewCount = 4;
    final showAll = topics.length > previewCount;
    final displayTopics = showAll ? topics.take(previewCount).toList() : topics;
    final countColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 8, 0),
          child: Row(
            children: [
              Text(
                _categoryLabel(categoryId),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${topics.length})',
                style: TextStyle(
                  fontSize: 12,
                  color: countColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/encyclopedia/topics/$categoryId'),
                child: Text(tr(Ar.viewAll, En.viewAll), style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayTopics.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _compactTopicCard(context, displayTopics[index], isDark: isDark),
          ),
        ),
      ],
    );
  }

  Widget _compactTopicCard(BuildContext context, EngineeringTopic topic, {required bool isDark}) {
    final hasCover = topic.coverImageUrl != null && topic.coverImageUrl!.trim().isNotEmpty;
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return GestureDetector(
      onTap: () => context.push('/encyclopedia/topic/${topic.id}'),
      child: Container(
        width: 160,
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
                        errorBuilder: (_, __, ___) => _categoryHeader(topic.categoryId, isDark: isDark),
                      ),
                    ),
                  )
                : _categoryHeader(topic.categoryId, isDark: isDark),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.titleAr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        topic.summary,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: mutedText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ..._compactCardChipsList(topic, isDark: isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryHeader(String categoryId, {required bool isDark}) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _categoryColor(categoryId),
            _categoryColor(categoryId).withValues(alpha: 0.6),
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
        child: Icon(_categoryIcon(categoryId), color: Colors.white, size: 32),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (topic.titleEn != null)
                          Text(
                            topic.titleEn!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: mutedText),
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
              ..._cardChips(topic, isDark: isDark),
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

  List<Widget> _cardChips(EngineeringTopic topic, {required bool isDark}) {
    final chips = _cardChipLabels(topic);
    if (chips.isEmpty) return const [];
    return [
      const SizedBox(height: 10),
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: chips.map((chip) => _buildChip(chip, isDark: isDark)).toList(),
      ),
    ];
  }

  List<Widget> _compactCardChipsList(EngineeringTopic topic, {required bool isDark}) {
    final chips = _cardChipLabels(topic, maxChips: 1);
    if (chips.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: SizedBox(
          height: 18,
          child: Wrap(
            spacing: 4,
            runSpacing: 0,
            children: chips.map((chip) => _buildChip(chip, isDark: isDark, compact: true)).toList(),
          ),
        ),
      ),
    ];
  }

  List<String> _cardChipLabels(EngineeringTopic topic, {int maxChips = 2}) {
    final source = topic.keyTopics.isNotEmpty ? topic.keyTopics : topic.tags;
    return source
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .take(maxChips)
        .toList();
  }

  Widget _buildChip(String label, {required bool isDark, bool compact = false}) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          fontSize: compact ? 9 : null,
          color: isDark ? EncyclopediaCardColors.chipDarkText : EncyclopediaCardColors.chipText,
        ),
      ),
    );
  }
}
