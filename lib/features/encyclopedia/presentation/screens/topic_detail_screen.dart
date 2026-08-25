import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/encyclopedia_favorites_provider.dart';
import '../providers/encyclopedia_provider.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/topic_section.dart';
import '../../domain/entities/localized_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/civil_app_bar.dart';
import '../../../../localization/ar.dart';
import '../theme/encyclopedia_card_colors.dart';
import '../theme/encyclopedia_topic_theme.dart';
import '../widgets/content_block_widget.dart';

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
      context.read<EncyclopediaProvider>().loadTopicDetail(widget.topicId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EncyclopediaProvider>();
    final topic = provider.currentTopic;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.pageBackground,
      appBar: CivilAppBar(
        showBackButton: true,
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.pageBackground,
        foregroundColor:
            isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        actions: [_FavoriteButton(topicId: widget.topicId)],
      ),
      body: SafeArea(
        top: false,
        child: AsyncValueWidget(
          isLoading: provider.isLoading,
          error: provider.error,
          isEmpty: topic == null && provider.error == null,
          onRetry: () => provider.loadTopicDetail(widget.topicId),
          onEmpty: () => Center(
            child: Text(
              Ar.topicNotFound,
              style: TextStyle(
                color:
                    isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          onData: () => _buildArticle(context, provider, topic!),
        ),
      ),
    );
  }

  // ───────────── Main article column ─────────────

  Widget _buildArticle(
    BuildContext context,
    EncyclopediaProvider provider,
    EngineeringTopic topic,
  ) {
    EncyclopediaCardColors.apply(
      EncyclopediaTopicTheme.fromKey(topic.visualTheme),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sortedSections = List<TopicSection>.from(provider.currentSections)
      ..sort((a, b) => a.order.compareTo(b.order));

    int seq = 0;

    Widget numbered(Widget Function(int n) builder) {
      seq++;
      return builder(seq);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasText(topic.coverImageUrl)) _buildCoverImage(context, topic),
          _buildHeroSection(context, topic),
          const SizedBox(height: AppSpacing.md),
          for (final section in sortedSections)
            numbered(
              (n) => _buildSectionByOrder(
                context,
                section,
                provider,
                isDark: isDark,
                number: n,
              ),
            ),
          if (_hasLegacyMetadata(topic))
            ..._buildLegacySections(context, topic, isDark: isDark, startNumber: seq + 1),
          if (topic.relatedToolRoutes.isNotEmpty)
            _buildRelatedToolsSection(context, topic, isDark: isDark),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  // ───────────── Data helpers ─────────────

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  bool _localizedHasText(LocalizedText? value) =>
      _hasText(value?.ar) || _hasText(value?.en);

  String _cleanDisplayText(String text) {
    return text.replaceAll('[DRAFT - REVIEW REQUIRED]', '').trim();
  }

  bool _hasLegacyMetadata(EngineeringTopic topic) {
    return _localizedHasText(topic.beforeWork) ||
        _localizedHasText(topic.duringWork) ||
        _localizedHasText(topic.afterWork) ||
        _localizedHasText(topic.siteNotes) ||
        _localizedHasText(topic.codeNotes) ||
        _localizedHasText(topic.reportWording) ||
        topic.commonMistakes.any((m) => _hasText(m.ar) || _hasText(m.en)) ||
        topic.acceptRejectItems.any((item) => _hasText(item.criteriaAr));
  }

  // ───────────── Section header ─────────────

  Widget _buildSectionHeader(
    BuildContext context,
    String kicker,
    String title, {
    int? number,
    required bool isDark,
  }) {
    final displayKicker = number != null
        ? '$kicker · ${number.toString().padLeft(2, '0')}'
        : kicker;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xl,
        end: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 2,
                color: EncyclopediaCardColors.accent,
              ),
              const SizedBox(width: 10),
              Text(
                displayKicker,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: EncyclopediaCardColors.accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── Section-driven block rendering ─────────────

  Widget _buildSectionByOrder(
    BuildContext context,
    TopicSection section,
    EncyclopediaProvider provider, {
    required bool isDark,
    required int number,
  }) {
    final blocks = provider.blocksForSection(section.id);
    if (blocks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          section.type.labelAr.toUpperCase(),
          section.title,
          number: number,
          isDark: isDark,
        ),
        ...blocks.map((block) => _renderSingleBlock(block)),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _renderSingleBlock(ContentBlock block) {
    return ContentBlockWidget(block: block);
  }

  // ───────────── Legacy metadata sections ─────────────

  List<Widget> _buildLegacySections(
    BuildContext context,
    EngineeringTopic topic, {
    required bool isDark,
    required int startNumber,
  }) {
    final widgets = <Widget>[];
    int n = startNumber;

    if (_hasText(topic.siteNotes?.ar) || _hasText(topic.codeNotes?.ar)) {
      widgets.add(_buildImportanceSection(context, topic, isDark: isDark, number: n++));
    }

    if (_localizedHasText(topic.beforeWork) ||
        _localizedHasText(topic.duringWork) ||
        _localizedHasText(topic.afterWork)) {
      widgets.add(_buildLegacyAppSection(context, topic, isDark: isDark, number: n++));
    }

    if (topic.acceptRejectItems.any((item) => _hasText(item.criteriaAr))) {
      widgets.add(_buildLegacyInspSection(context, topic, isDark: isDark, number: n++));
    }

    if (topic.commonMistakes.any((m) => _hasText(m.ar) || _hasText(m.en))) {
      widgets.add(_buildCommonMistakesSection(context, topic, isDark: isDark, number: n++));
    }

    if (_hasText(topic.reportWording?.ar)) {
      widgets.add(_buildReportWordingSection(context, topic, isDark: isDark));
    }

    return widgets;
  }

  Widget _buildLegacyAppSection(
    BuildContext context,
    EngineeringTopic topic, {
    required bool isDark,
    required int number,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'APPLICATION',
          'طريقة التنفيذ',
          number: number,
          isDark: isDark,
        ),
        if (_hasText(topic.beforeWork?.ar))
          _buildSubSection(context, 'قبل العمل', topic.beforeWork!.ar, isDark: isDark),
        if (_hasText(topic.duringWork?.ar))
          _buildSubSection(context, 'أثناء العمل', topic.duringWork!.ar, isDark: isDark),
        if (_hasText(topic.afterWork?.ar))
          _buildSubSection(context, 'بعد العمل', topic.afterWork!.ar, isDark: isDark),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildLegacyInspSection(
    BuildContext context,
    EngineeringTopic topic, {
    required bool isDark,
    required int number,
  }) {
    final validItems = topic.acceptRejectItems
        .where((item) => _hasText(item.criteriaAr))
        .toList();
    if (validItems.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'INSPECTION',
          'فحص الأعمال بعد الإنجاز',
          number: number,
          isDark: isDark,
        ),
        ...validItems.map(
          (item) => _buildInspectionRow(
            context,
            item.criteriaAr,
            item.acceptanceLimitAr,
            item.methodAr,
            item.isCritical,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  // ───────────── Hero Section ─────────────

  Widget _buildHeroSection(BuildContext context, EngineeringTopic topic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final category =
        context.read<EncyclopediaProvider>().categoryLabel(topic.categoryId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xl,
          ),
          child: Text(
            category,
            style: theme.textTheme.labelMedium?.copyWith(
              color: EncyclopediaCardColors.accent,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xl,
          ),
          child: Text(
            topic.titleAr,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (topic.simpleExplanation != null)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.xl,
            ),
            child: Text(
              topic.simpleExplanation!.ar,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                height: 1.7,
              ),
            ),
          )
        else if (topic.summary.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.xl,
            ),
            child: Text(
              topic.summary,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (topic.keyTopics.isNotEmpty)
          _buildKeyTopics(context, topic, isDark: isDark)
        else if (topic.tags.isNotEmpty)
          _buildTags(context, topic, isDark: isDark),
      ],
    );
  }

  Widget _buildKeyTopics(
    BuildContext context,
    EngineeringTopic topic, {
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'كلمات مفتاحية',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: topic.keyTopics
                .map((kt) => kt.trim())
                .where((kt) => kt.isNotEmpty)
                .toSet()
                .map((kt) => _detailChip(context, kt, isDark: isDark))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(
    BuildContext context,
    EngineeringTopic topic, {
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xl,
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: topic.tags
            .map((tag) => _detailChip(context, tag, isDark: isDark))
            .toList(),
      ),
    );
  }

  Widget _detailChip(
    BuildContext context,
    String label, {
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? EncyclopediaCardColors.chipDarkBg
            : EncyclopediaCardColors.chipBg,
        border: Border.all(
          color: isDark
              ? EncyclopediaCardColors.chipDarkBorder
              : EncyclopediaCardColors.chipBorder,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isDark
              ? EncyclopediaCardColors.chipDarkText
              : EncyclopediaCardColors.chipText,
        ),
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context, EngineeringTopic topic) {
    final url = topic.coverImageUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xs,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: (isDark ? AppColors.darkBorder : AppColors.border)
                  .withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            boxShadow: DesignTokens.softShadow(Colors.black),
          ),
          child: Image.asset(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  // ───────────── IMPORTANCE · 02 ─────────────

  Widget _buildImportanceSection(
    BuildContext context,
    EngineeringTopic topic, {
    required bool isDark,
    required int number,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'IMPORTANCE',
          'الأهمية الهندسية',
          number: number,
          isDark: isDark,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xl,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              border: BorderDirectional(
                start: BorderSide(
                  color: EncyclopediaCardColors.accent,
                  width: 3,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasText(topic.siteNotes?.ar))
                  _buildImportanceItem(context, topic.siteNotes!.ar, isDark: isDark),
                if (_hasText(topic.codeNotes?.ar))
                  _buildImportanceItem(context, topic.codeNotes!.ar, isDark: isDark),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildImportanceItem(
    BuildContext context,
    String text, {
    required bool isDark,
  }) {
    final display = _cleanDisplayText(text);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 5),
            child: Icon(
              Icons.diamond,
              size: 8,
              color: EncyclopediaCardColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              display,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    height: 1.7,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSection(
    BuildContext context,
    String title,
    String content, {
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xl,
        end: AppSpacing.xl,
        bottom: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  height: 1.7,
                ),
          ),
        ],
      ),
    );
  }

  // ───────────── INSPECTION · 07 ─────────────

  Widget _buildInspectionRow(
    BuildContext context,
    String criteria,
    String? limit,
    String? method,
    bool isCritical, {
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xl,
        end: AppSpacing.xl,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 2),
            child: Icon(
              isCritical ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              size: 18,
              color: isCritical
                  ? AppColors.error
                  : (isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  height: 1.6,
                ),
                children: [
                  TextSpan(
                    text: criteria,
                    style: TextStyle(
                      fontWeight:
                          isCritical ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (limit != null && limit.isNotEmpty)
                    TextSpan(
                      text: ' — $limit',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  if (method != null && method.isNotEmpty)
                    TextSpan(
                      text: ' | $method',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── COMMON MISTAKES · 08 ─────────────

  Widget _buildCommonMistakesSection(
    BuildContext context,
    EngineeringTopic topic, {
    required bool isDark,
    required int number,
  }) {
    final validMistakes = topic.commonMistakes
        .where((m) => _hasText(m.ar) || _hasText(m.en))
        .toList();

    if (validMistakes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'COMMON MISTAKES',
          'أخطاء شائعة يجب تجنبها',
          number: number,
          isDark: isDark,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xl,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: EncyclopediaCardColors.mistakeBg,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              border: Border.all(
                color: EncyclopediaCardColors.mistakeBorder.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...validMistakes.map(
                  (m) => _buildMistakeItem(context, m.ar, isDark: isDark),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildMistakeItem(
    BuildContext context,
    String text, {
    required bool isDark,
  }) {
    if (!_hasText(text)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '×',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── Report Wording ─────────────

  Widget _buildReportWordingSection(
    BuildContext context,
    EngineeringTopic topic, {
    required bool isDark,
  }) {
    final wording = _cleanDisplayText(topic.reportWording!.ar);
    if (wording.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '', 'صياغة تقرير', isDark: isDark),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xl,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              color:
                  isDark ? AppColors.darkSurfaceElevated : AppColors.surfacePrimary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wording,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        height: 1.7,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: wording));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ الصياغة'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: EncyclopediaCardColors.accentSoft,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusXs),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy,
                              size: 14,
                              color: EncyclopediaCardColors.accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'نسخ',
                              style: TextStyle(
                                fontSize: 12,
                                color: EncyclopediaCardColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  // ───────────── Related Tools ─────────────

  Widget _buildRelatedToolsSection(
    BuildContext context,
    EngineeringTopic topic, {
    bool isDark = false,
  }) {
    const toolNames = <String, String>{
      '/calculator/concrete': 'حاسبة الخرسانة',
      '/calculator/steel': 'حاسبة الحديد',
      '/calculator/tile': 'حاسبة البلاط',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '', 'أدوات ذات صلة', isDark: isDark),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xl,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: topic.relatedToolRoutes.map((route) {
              final name = toolNames[route] ?? route;
              return GestureDetector(
                onTap: () {
                  try {
                    context.go(route);
                  } catch (_) {}
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: EncyclopediaCardColors.accentSoft,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusXs),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      color: EncyclopediaCardColors.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

// ───────────── Favorite action ─────────────

class _FavoriteButton extends StatelessWidget {
  final String topicId;

  const _FavoriteButton({required this.topicId});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<EncyclopediaFavoritesProvider>();
    final isFavorite = favoritesProvider.isFavorite(topicId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        favoritesProvider.toggle(topicId);
      },
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
      color: isFavorite
          ? AppColors.error
          : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
      tooltip: isFavorite ? Ar.removeFromFavorites : Ar.addToFavorites,
    );
  }
}
