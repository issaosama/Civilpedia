import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/encyclopedia_provider.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../../../core/navigation/shell_content_insets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/civil_app_bar.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/section_header.dart';
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EncyclopediaProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String ar, String en) => isArabic ? ar : en;

    return Scaffold(
      appBar: CivilAppBar(
        showBackButton: false,
        showDivider: true,
        title: Text(tr(Ar.engineeringEncyclopedia, En.engineeringEncyclopedia)),
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.hPadLgVSm,
            child: SearchBarWidget(
              controller: _searchController,
              hintText: Ar.search,
              lightSurface: true,
              onChanged: (query) {
                context.read<EncyclopediaProvider>().searchTopics(query);
              },
            ),
          ),
          Expanded(
            child: AsyncValueWidget(
              isLoading: provider.isLoading,
              error: provider.error,
              isEmpty: provider.topics.isEmpty && provider.error == null,
              onRetry: () => provider.loadAllTopics(),
              onEmpty: () => Center(
                child: Padding(
                  padding: AppSpacing.padXl,
                  child: Text(
                    provider.isSearchActive
                        ? 'لا توجد نتائج للبحث عن "${_searchController.text}"'
                        : tr(Ar.noTopicsInCategory, En.noTopicsInCategory),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
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
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: shellSafeBottomPadding(context),
      ),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: shellSafeBottomPadding(context)),
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
    final catLabel = context.read<EncyclopediaProvider>().categoryLabel(categoryId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '$catLabel (${topics.length})',
          actionLabel: tr(Ar.viewAll, En.viewAll),
          onAction: () => context.push('/encyclopedia/topics/$categoryId'),
        ),
        AppSpacing.gapSm,
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.hPadLg,
            itemCount: displayTopics.length,
            separatorBuilder: (_, __) => AppSpacing.gapMd,
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
