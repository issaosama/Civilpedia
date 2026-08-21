import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/encyclopedia_provider.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../widgets/topic_compact_card.dart';
import '../widgets/topic_list_card.dart';

const _categoryOrder = [
  'concrete',
  'steel',
  'soil',
  'roads',
  'finishing',
];

class EncyclopediaScreen extends StatefulWidget {
  final String? initialQuery;

  const EncyclopediaScreen({super.key, this.initialQuery});

  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EncyclopediaProvider>();
      final query = widget.initialQuery?.trim() ?? '';
      if (query.isNotEmpty) {
        _searchController.text = query;
        provider.searchTopics(query);
      }
      if (provider.allTopics.isEmpty && !provider.isLoading) {
        provider.loadAllTopics();
      }
    });
  }

  @override
  void didUpdateWidget(EncyclopediaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newQuery = widget.initialQuery?.trim() ?? '';
    final oldQuery = oldWidget.initialQuery?.trim() ?? '';
    if (newQuery == oldQuery) return;

    _searchController.text = newQuery;
    if (newQuery.isNotEmpty) {
      context.read<EncyclopediaProvider>().searchTopics(newQuery);
    } else {
      context.read<EncyclopediaProvider>().clearSearch();
    }
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
    final catLabel = context.read<EncyclopediaProvider>().categoryLabel(categoryId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 8, 0),
          child: Row(
            children: [
              Text(
                catLabel,
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
            itemBuilder: (context, index) => TopicCompactCard(
              topic: displayTopics[index],
              isDark: isDark,
              variant: TopicCompactCardVariant.preview,
              onTap: () => context.push('/encyclopedia/topic/${displayTopics[index].id}'),
            ),
          ),
        ),
      ],
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
