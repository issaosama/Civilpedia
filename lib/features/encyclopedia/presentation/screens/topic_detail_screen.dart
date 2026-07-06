import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/encyclopedia_provider.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/topic_section.dart';
import '../../domain/entities/localized_text.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../localization/ar.dart';
import '../theme/encyclopedia_card_colors.dart';
import '../theme/encyclopedia_topic_theme.dart';

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
      backgroundColor: isDark ? EncyclopediaCardColors.darkPageBg : EncyclopediaCardColors.pageBg,
      body: SafeArea(
        child: AsyncValueWidget(
          isLoading: provider.isLoading,
          error: provider.error,
          isEmpty: topic == null && provider.error == null,
          onRetry: () => provider.loadTopicDetail(widget.topicId),
          onEmpty: () => Center(
            child: Text(Ar.topicNotFound, style: TextStyle(color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary)),
          ),
          onData: () => _buildArticle(context, provider, topic!),
        ),
      ),
    );
  }

  // ───────────── Main article column ─────────────

  Widget _buildArticle(BuildContext context, EncyclopediaProvider provider, EngineeringTopic topic) {
    final blocksByType = _collectBlocksByType(provider);
    EncyclopediaCardColors.apply(EncyclopediaTopicTheme.fromKey(topic.visualTheme));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int seq = 0;

    Widget numbered(Widget Function(int n) builder) {
      seq++;
      return builder(seq);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(context, isDark: isDark),
          _buildDivider(isDark: isDark),
          _buildBrandPill(isDark: isDark),
          _buildHeroSection(topic, isDark: isDark),
          const SizedBox(height: 8),
          numbered((n) => _buildOverviewSection(topic, blocksByType, isDark: isDark, number: n)),
          if (_hasGeneralData(blocksByType))
            numbered((n) => _buildGeneralSection(blocksByType, isDark: isDark, number: n)),
          if (_hasImportanceData(topic, blocksByType))
            numbered((n) => _buildImportanceSection(topic, blocksByType, isDark: isDark, number: n)),
          if (_hasTableData(blocksByType))
            numbered((n) => _buildDimensionsSection(blocksByType, isDark: isDark, number: n)),
          if (_hasApplicationData(topic, blocksByType))
            numbered((n) => _buildApplicationSection(topic, blocksByType, isDark: isDark, number: n)),
          if (_hasSafetyData(blocksByType))
            numbered((n) => _buildSafetySection(blocksByType, isDark: isDark, number: n)),
          if (_hasInspectionData(topic, blocksByType))
            numbered((n) => _buildInspectionSection(topic, blocksByType, isDark: isDark, number: n)),
          if (_hasCommonMistakes(topic, blocksByType))
            numbered((n) => _buildCommonMistakesSection(topic, blocksByType, isDark: isDark, number: n)),
          if (topic.reportWording != null)
            _buildReportWordingSection(topic, isDark: isDark),
          if (topic.relatedToolRoutes.isNotEmpty)
            _buildRelatedToolsSection(context, topic, isDark: isDark),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ───────────── Data helpers ─────────────

  Map<SectionType, List<ContentBlock>> _collectBlocksByType(EncyclopediaProvider provider) {
    final map = <SectionType, List<ContentBlock>>{};
    for (final section in provider.currentSections) {
      final blocks = provider.blocksForSection(section.id);
      if (blocks.isNotEmpty) {
        map.putIfAbsent(section.type, () => []);
        map[section.type]!.addAll(blocks);
      }
    }
    return map;
  }

  bool _hasImportanceData(EngineeringTopic topic, Map<SectionType, List<ContentBlock>> blocksByType) {
    if (_hasText(topic.siteNotes?.ar) || _hasText(topic.codeNotes?.ar)) return true;
    return false;
  }

  bool _hasTableData(Map<SectionType, List<ContentBlock>> blocksByType) {
    for (final blocks in blocksByType.values) {
      if (blocks.any((b) => b is TableBlock && b.data.rows.isNotEmpty)) return true;
    }
    return false;
  }

  bool _hasApplicationData(EngineeringTopic topic, Map<SectionType, List<ContentBlock>> blocksByType) {
    if (_localizedHasText(topic.beforeWork) || _localizedHasText(topic.duringWork) || _localizedHasText(topic.afterWork)) return true;
    if (blocksByType.containsKey(SectionType.execution)) return true;
    return false;
  }

  bool _hasInspectionData(EngineeringTopic topic, Map<SectionType, List<ContentBlock>> blocksByType) {
    if (topic.acceptRejectItems.any((item) => _hasText(item.criteriaAr))) { return true; }
    if (blocksByType.containsKey(SectionType.inspection) &&
        blocksByType[SectionType.inspection]!.any((b) =>
            (b is InspectionPointBlock && _hasText(b.point.criteria)) ||
            (b is ChecklistBlock && b.items.any((i) => _hasText(i.text))))) { return true; }
    return false;
  }

  bool _hasCommonMistakes(EngineeringTopic topic, Map<SectionType, List<ContentBlock>> blocksByType) {
    if (topic.commonMistakes.any((m) => _hasText(m.ar) || _hasText(m.en))) { return true; }
    return false;
  }

  bool _hasSafetyData(Map<SectionType, List<ContentBlock>> blocksByType) {
    final safetyBlocks = blocksByType[SectionType.safety] ?? <ContentBlock>[];
    return safetyBlocks.any((b) => b is SafetyNoteBlock && _hasText(b.note.message));
  }

  bool _hasGeneralData(Map<SectionType, List<ContentBlock>> blocksByType) {
    final generalBlocks = blocksByType[SectionType.general] ?? <ContentBlock>[];
    return generalBlocks.isNotEmpty;
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  bool _localizedHasText(LocalizedText? value) => _hasText(value?.ar) || _hasText(value?.en);

  String _cleanDisplayText(String text) {
    return text.replaceAll('[DRAFT - REVIEW REQUIRED]', '').trim();
  }

  // ───────────── Section header ─────────────

  Widget _buildSectionHeader(String kicker, String title, {int? number, bool isDark = false}) {
    final displayKicker = number != null ? '$kicker · ${number.toString().padLeft(2, '0')}' : kicker;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 36, height: 2, color: EncyclopediaCardColors.accent),
              const SizedBox(width: 12),
              Text(
                displayKicker,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: EncyclopediaCardColors.accent,
                  fontWeight: FontWeight.w600,
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ───────────── Top Bar ─────────────

  Widget _buildTopBar(BuildContext context, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'CIVIL PEDIA',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2.5,
                  color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'سيڤل بيديا',
                style: TextStyle(fontSize: 8, color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary, height: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider({required bool isDark}) {
    return Container(height: 1, color: isDark ? EncyclopediaCardColors.darkBorder : EncyclopediaCardColors.border, margin: const EdgeInsets.symmetric(horizontal: 16));
  }

  Widget _buildBrandPill({bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? EncyclopediaCardColors.darkSoftPanel : EncyclopediaCardColors.accentSoft,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'الموسوعة الهندسية',
          style: TextStyle(fontSize: 10, color: EncyclopediaCardColors.accent, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ───────────── Hero Section ─────────────

  Widget _buildHeroSection(EngineeringTopic topic, {required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _categoryName(topic.categoryId),
            style: TextStyle(
              fontSize: 12,
              color: EncyclopediaCardColors.accent,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            topic.titleAr,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (topic.simpleExplanation != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              topic.simpleExplanation!.ar,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary,
                height: 1.7,
              ),
            ),
          )
        else if (topic.summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              topic.summary,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),
        const SizedBox(height: 14),
        if (topic.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: topic.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: (isDark ? EncyclopediaCardColors.darkBorder : EncyclopediaCardColors.border).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(tag, style: TextStyle(fontSize: 11, color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary)),
              )).toList(),
            ),
          ),
        const SizedBox(height: 16),
        if (_hasText(topic.featuredImageUrl)) _buildHeroImage(topic, isDark: isDark),
      ],
    );
  }

  Widget _buildHeroImage(EngineeringTopic topic, {required bool isDark}) {
    final url = topic.featuredImageUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (isDark ? EncyclopediaCardColors.darkBorder : EncyclopediaCardColors.border).withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  String _categoryName(String id) {
    switch (id) {
      case 'concrete':
        return 'الخرسانة';
      case 'steel':
        return 'الحديد';
      case 'soil':
        return 'التربة';
      case 'finishing':
        return 'أعمال الإنهاءات';
      default:
        return id;
    }
  }

  // ───────────── OVERVIEW · 01 ─────────────

  Widget _buildOverviewSection(EngineeringTopic topic, Map<SectionType, List<ContentBlock>> blocksByType, {required bool isDark, required int number}) {
    final overviewText = topic.simpleExplanation?.ar ?? topic.summary;
    if (!_hasText(overviewText)) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('OVERVIEW', 'نظرة عامة', number: number, isDark: isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            overviewText,
            style: TextStyle(fontSize: 15, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.8),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ───────────── IMPORTANCE · 02 ─────────────

  Widget _buildImportanceSection(EngineeringTopic topic, Map<SectionType, List<ContentBlock>> blocksByType, {required bool isDark, required int number}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('IMPORTANCE', 'الأهمية الهندسية', number: number, isDark: isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? EncyclopediaCardColors.darkSoftPanel : EncyclopediaCardColors.softPanel,
              borderRadius: BorderRadius.circular(10),
              border: Border(
                right: BorderSide(color: EncyclopediaCardColors.accent, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasText(topic.siteNotes?.ar))
                  _buildImportanceItem(topic.siteNotes!.ar, isDark: isDark),
                if (_hasText(topic.codeNotes?.ar))
                  _buildImportanceItem(topic.codeNotes!.ar, isDark: isDark),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildImportanceItem(String text, {required bool isDark}) {
    final display = _cleanDisplayText(text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Icon(Icons.diamond, size: 8, color: EncyclopediaCardColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              display,
              style: TextStyle(fontSize: 14, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── DIMENSIONS · 05 ─────────────

  Widget _buildDimensionsSection(Map<SectionType, List<ContentBlock>> blocksByType, {required bool isDark, required int number}) {
    final tables = <TableBlock>[];
    final images = <Widget>[];
    for (final blocks in blocksByType.values) {
      for (final block in blocks) {
        if (block is TableBlock && block.data.rows.isNotEmpty) tables.add(block);
      }
      images.addAll(_imageBlocksFrom(blocks, isDark: isDark));
    }
    if (tables.isEmpty && images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('TABLES', 'القياسات والسماكات المتداولة', number: number, isDark: isDark),
        ...tables.map((t) => _buildEditorialTable(t, isDark: isDark)),
        ...images,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEditorialTable(TableBlock tableBlock, {required bool isDark}) {
    final data = tableBlock.data;
    if (data.rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.caption != null && data.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                data.caption!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? EncyclopediaCardColors.darkBorder : EncyclopediaCardColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(isDark ? EncyclopediaCardColors.darkTableHeaderBg : EncyclopediaCardColors.tableHeaderBg),
                        headingTextStyle: TextStyle(
                          color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        dataTextStyle: TextStyle(
                          color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        columnSpacing: 24,
                        horizontalMargin: 14,
                        columns: data.headers.map((h) => DataColumn(label: Text(h))).toList(),
                        rows: data.rows
                            .map((row) => DataRow(
                                  cells: row.cells.map((c) => DataCell(Text(c))).toList(),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  if (constraints.maxWidth < _tableTotalWidth(data))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(Icons.swipe, size: 12, color: isDark ? EncyclopediaCardColors.darkTextMuted : EncyclopediaCardColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'اسحب الجدول أفقياً لعرض جميع الأعمدة',
                            style: TextStyle(fontSize: 11, color: isDark ? EncyclopediaCardColors.darkTextMuted : EncyclopediaCardColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  double _tableTotalWidth(TableData data) {
    const colSpacing = 24.0;
    const horizMargin = 14.0;
    final colCount = data.headers.length;
    final totalWidth = colCount * 120.0 + (colCount - 1) * colSpacing + 2 * horizMargin;
    return totalWidth;
  }

  // ───────────── APPLICATION · 06 ─────────────

  Widget _buildApplicationSection(EngineeringTopic topic, Map<SectionType, List<ContentBlock>> blocksByType, {required bool isDark, required int number}) {
    final executionBlocks = blocksByType[SectionType.execution] ?? <ContentBlock>[];
    final steps = executionBlocks.whereType<ExecutionStepBlock>().toList()
      ..sort((a, b) => a.step.stepNumber.compareTo(b.step.stepNumber));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('APPLICATION', 'طرق التنفيذ', number: number, isDark: isDark),
        if (_hasText(topic.beforeWork?.ar))
          _buildSubSection('قبل العمل', topic.beforeWork!.ar, isDark: isDark),
        if (_hasText(topic.duringWork?.ar))
          _buildSubSection('أثناء العمل', topic.duringWork!.ar, isDark: isDark),
        if (_hasText(topic.afterWork?.ar))
          _buildSubSection('بعد العمل', topic.afterWork!.ar, isDark: isDark),
        if (steps.isNotEmpty) ...[
          if (!_localizedHasText(topic.beforeWork) && !_localizedHasText(topic.duringWork) && !_localizedHasText(topic.afterWork))
            const SizedBox(height: 4)
          else
            const SizedBox(height: 8),
          ...steps.map((s) => _buildStepCard(s, isDark: isDark)),
        ],
        ..._imageBlocksFrom(executionBlocks, isDark: isDark),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSubSection(String title, String content, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(fontSize: 14, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(ExecutionStepBlock stepBlock, {required bool isDark}) {
    final step = stepBlock.step;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: EncyclopediaCardColors.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '${step.stepNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.description,
                  style: TextStyle(fontSize: 14, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.6),
                ),
                if (step.notes != null && step.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.notes!,
                    style: TextStyle(fontSize: 12, color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── INSPECTION · 07 ─────────────

  Widget _buildInspectionSection(EngineeringTopic topic, Map<SectionType, List<ContentBlock>> blocksByType, {required bool isDark, required int number}) {
    final inspBlocks = blocksByType[SectionType.inspection] ?? <ContentBlock>[];

    final validAcceptReject = topic.acceptRejectItems.where((item) => _hasText(item.criteriaAr)).toList();
    final validInspPoints = inspBlocks.whereType<InspectionPointBlock>().where((b) => _hasText(b.point.criteria)).toList();
    final validChecklists = inspBlocks.whereType<ChecklistBlock>().where((b) => b.items.any((i) => _hasText(i.text))).toList();

    if (validAcceptReject.isEmpty && validInspPoints.isEmpty && validChecklists.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('INSPECTION', 'فحص الأعمال بعد الإنجاز', number: number, isDark: isDark),
        ...validAcceptReject.map((item) => _buildInspectionRow(
              item.criteriaAr,
              item.acceptanceLimitAr,
              item.methodAr,
              item.isCritical,
              isDark: isDark,
            )),
        ...validInspPoints.map((b) => _buildInspectionRow(
              b.point.criteria,
              b.point.acceptableTolerance,
              b.point.method,
              b.point.isCritical,
              isDark: isDark,
            )),
        ...validChecklists.map((b) => _buildChecklistBlock(b, isDark: isDark)),
        ..._imageBlocksFrom(inspBlocks, isDark: isDark),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInspectionRow(String criteria, String? limit, String? method, bool isCritical, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              isCritical ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              size: 18,
              color: isCritical ? EncyclopediaCardColors.dangerText : (isDark ? EncyclopediaCardColors.darkTextMuted : EncyclopediaCardColors.textMuted),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.6),
                children: [
                  TextSpan(
                    text: criteria,
                    style: TextStyle(fontWeight: isCritical ? FontWeight.w600 : FontWeight.normal),
                  ),
                  if (limit != null && limit.isNotEmpty)
                    TextSpan(
                      text: ' — $limit',
                      style: TextStyle(color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary),
                    ),
                  if (method != null && method.isNotEmpty)
                    TextSpan(
                      text: ' | $method',
                      style: TextStyle(color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistBlock(ChecklistBlock block, {required bool isDark}) {
    final validItems = block.items.where((i) => _hasText(i.text)).toList();
    if (validItems.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? EncyclopediaCardColors.darkBorder : EncyclopediaCardColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasText(block.title)) ...[
              Text(
                block.title!,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary),
              ),
              const SizedBox(height: 10),
            ],
            ...validItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_box_outline_blank, size: 18, color: isDark ? EncyclopediaCardColors.darkTextMuted : EncyclopediaCardColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.text,
                          style: TextStyle(fontSize: 13, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ───────────── Image Block ─────────────

  Widget _buildImageBlock(ImageBlock block, {required bool isDark}) {
    if (block.imageUrl.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              block.imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (_, __, ___) {
                if (kReleaseMode) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'تعذر تحميل الصورة\n${block.imageUrl}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade300 : Colors.grey),
                  ),
                );
              },
            ),
          ),
          if (_hasText(block.caption))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  block.caption!,
                  style: TextStyle(fontSize: 12, color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _imageBlocksFrom(List<ContentBlock> blocks, {required bool isDark}) {
    return blocks
        .whereType<ImageBlock>()
        .where((b) => b.imageUrl.isNotEmpty)
        .map((b) => _buildImageBlock(b, isDark: isDark))
        .toList();
  }

  // ───────────── GENERAL CONTENT · 03 ─────────────

  Widget _buildGeneralSection(Map<SectionType, List<ContentBlock>> blocksByType, {required bool isDark, required int number}) {
    final generalBlocks = blocksByType[SectionType.general] ?? <ContentBlock>[];
    if (generalBlocks.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (final block in generalBlocks) {
      if (block is TextBlock && _hasText(block.content)) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Text(
            block.content,
            style: TextStyle(fontSize: 14, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.7),
          ),
        ));
      } else if (block is ImageBlock && block.imageUrl.isNotEmpty) {
        children.add(_buildImageBlock(block, isDark: isDark));
      } else if (block is SafetyNoteBlock && _hasText(block.note.message)) {
        children.add(_buildGeneralSafetyNote(block, isDark: isDark));
      }
    }
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('GENERAL', 'المحتوى العام', number: number, isDark: isDark),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildGeneralSafetyNote(SafetyNoteBlock block, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? EncyclopediaCardColors.darkSoftPanel : EncyclopediaCardColors.softPanel,
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            right: BorderSide(color: Color(0xFFD4A017), width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB8860B)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                block.note.message,
                style: TextStyle(fontSize: 13, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────── COMMON MISTAKES · 08 ─────────────

  Widget _buildSafetySection(Map<SectionType, List<ContentBlock>> blocksByType, {required bool isDark, required int number}) {
    final safetyBlocks = blocksByType[SectionType.safety] ?? <ContentBlock>[];
    final validNotes = safetyBlocks.whereType<SafetyNoteBlock>().where((s) => _hasText(s.note.message)).toList();
    if (validNotes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('SAFETY', 'تنبيهات السلامة', number: number, isDark: isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? EncyclopediaCardColors.darkSoftPanel : EncyclopediaCardColors.softPanel,
              borderRadius: BorderRadius.circular(10),
              border: const Border(
                right: BorderSide(color: Color(0xFFD4A017), width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: validNotes.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFB8860B)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.note.message,
                        style: TextStyle(fontSize: 14, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.6),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCommonMistakesSection(EngineeringTopic topic, Map<SectionType, List<ContentBlock>> blocksByType, {required bool isDark, required int number}) {
    final validMistakes = topic.commonMistakes.where((m) => _hasText(m.ar) || _hasText(m.en)).toList();

    if (validMistakes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('COMMON MISTAKES', 'أخطاء شائعة يجب تجنبها', number: number, isDark: isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? EncyclopediaCardColors.darkMistakeBg : EncyclopediaCardColors.mistakeBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: EncyclopediaCardColors.mistakeBorder.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...validMistakes.map((m) => _buildMistakeItem(m.ar, isDark: isDark)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMistakeItem(String text, {required bool isDark}) {
    if (!_hasText(text)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('×', style: TextStyle(fontSize: 16, color: EncyclopediaCardColors.dangerText, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── Report Wording ─────────────

  Widget _buildReportWordingSection(EngineeringTopic topic, {required bool isDark}) {
    final wording = _cleanDisplayText(topic.reportWording!.ar);
    if (wording.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('', 'صياغة تقرير', isDark: isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? EncyclopediaCardColors.darkBorder : EncyclopediaCardColors.border),
              color: isDark ? EncyclopediaCardColors.darkPaperBg : EncyclopediaCardColors.paperBg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wording,
                  style: TextStyle(fontSize: 14, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.7),
                ),
                const SizedBox(height: 12),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                    color: isDark ? EncyclopediaCardColors.darkSoftPanel : EncyclopediaCardColors.accentSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy, size: 14, color: EncyclopediaCardColors.accent),
                            const SizedBox(width: 6),
                            Text(
                              'نسخ',
                              style: TextStyle(fontSize: 12, color: EncyclopediaCardColors.accent, fontWeight: FontWeight.w600),
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
        const SizedBox(height: 8),
      ],
    );
  }

  // ───────────── Related Tools ─────────────

  Widget _buildRelatedToolsSection(BuildContext context, EngineeringTopic topic, {bool isDark = false}) {
    const toolNames = <String, String>{
      '/calculator/concrete': 'حاسبة الخرسانة',
      '/calculator/steel': 'حاسبة الحديد',
      '/calculator/tile': 'حاسبة البلاط',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('', 'أدوات ذات صلة', isDark: isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: EncyclopediaCardColors.accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 13, color: EncyclopediaCardColors.accent, fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
