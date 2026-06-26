import 'package:flutter/material.dart';
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

const Color _pageBg = Color(0xFFFAF7F2);
const Color _paperBg = Color(0xFFFFFEFB);
const Color _textPrimary = Color(0xFF171411);
const Color _textSecondary = Color(0xFF6D6258);
const Color _textMuted = Color(0xFF9A8E84);
const Color _border = Color(0xFFE8DCD3);
const Color _softPanel = Color(0xFFF7EFEA);
const Color _accent = Color(0xFF8A3030);
const Color _accentSoft = Color(0xFFF5E9E5);
const Color _dangerText = Color(0xFFA23A36);
const Color _tableHeaderBg = Color(0xFFF3E8E3);

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

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: AsyncValueWidget(
          isLoading: provider.isLoading,
          error: provider.error,
          isEmpty: topic == null && provider.error == null,
          onRetry: () => provider.loadTopicDetail(widget.topicId),
          onEmpty: () => const Center(
            child: Text(Ar.topicNotFound, style: TextStyle(color: _textSecondary)),
          ),
          onData: () => _buildArticle(context, provider, topic!),
        ),
      ),
    );
  }

  // ───────────── Main article column ─────────────

  Widget _buildArticle(BuildContext context, EncyclopediaProvider provider, EngineeringTopic topic) {
    final blocksByType = _collectBlocksByType(provider);

    int seq = 0;

    Widget numbered(Widget Function(int n) builder) {
      seq++;
      return builder(seq);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(context),
          _buildDivider(),
          _buildBrandPill(),
          _buildHeroSection(topic),
          const SizedBox(height: 8),
          numbered((n) => _buildOverviewSection(topic, blocksByType, number: n)),
          if (_hasImportanceData(topic, blocksByType))
            numbered((n) => _buildImportanceSection(topic, blocksByType, number: n)),
          if (_hasTableData(blocksByType))
            numbered((n) => _buildDimensionsSection(blocksByType, number: n)),
          if (_hasApplicationData(topic, blocksByType))
            numbered((n) => _buildApplicationSection(topic, blocksByType, number: n)),
          if (_hasSafetyData(blocksByType))
            numbered((n) => _buildSafetySection(blocksByType, number: n)),
          if (_hasInspectionData(topic, blocksByType))
            numbered((n) => _buildInspectionSection(topic, blocksByType, number: n)),
          if (_hasCommonMistakes(topic, blocksByType))
            numbered((n) => _buildCommonMistakesSection(topic, blocksByType, number: n)),
          if (topic.reportWording != null)
            _buildReportWordingSection(topic),
          if (topic.relatedToolRoutes.isNotEmpty)
            _buildRelatedToolsSection(context, topic),
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

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  bool _localizedHasText(LocalizedText? value) => _hasText(value?.ar) || _hasText(value?.en);

  String _cleanDisplayText(String text) {
    return text.replaceAll('[DRAFT - REVIEW REQUIRED]', '').trim();
  }

  // ───────────── Section header ─────────────

  Widget _buildSectionHeader(String kicker, String title, {int? number}) {
    final displayKicker = number != null ? '$kicker · ${number.toString().padLeft(2, '0')}' : kicker;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 36, height: 2, color: _accent),
              const SizedBox(width: 12),
              Text(
                displayKicker,
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: _accent,
                  fontWeight: FontWeight.w600,
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ───────────── Top Bar ─────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _textPrimary),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const Spacer(),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'CIVIL PEDIA',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2.5,
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'سيڤل بيديا',
                style: TextStyle(fontSize: 8, color: _textSecondary, height: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(horizontal: 16));
  }

  Widget _buildBrandPill() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _accentSoft,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'الموسوعة الهندسية',
          style: TextStyle(fontSize: 10, color: _accent, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ───────────── Hero Section ─────────────

  Widget _buildHeroSection(EngineeringTopic topic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _categoryName(topic.categoryId),
            style: const TextStyle(
              fontSize: 12,
              color: _accent,
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
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
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
              style: const TextStyle(
                fontSize: 15,
                color: _textSecondary,
                height: 1.7,
              ),
            ),
          )
        else if (topic.summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              topic.summary,
              style: const TextStyle(
                fontSize: 15,
                color: _textSecondary,
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
                  color: _border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(tag, style: const TextStyle(fontSize: 11, color: _textSecondary)),
              )).toList(),
            ),
          ),
        const SizedBox(height: 16),
        if (_hasText(topic.featuredImageUrl)) _buildHeroImage(topic),
      ],
    );
  }

  Widget _buildHeroImage(EngineeringTopic topic) {
    final url = topic.featuredImageUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border.withValues(alpha: 0.5)),
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

  Widget _buildOverviewSection(EngineeringTopic topic, Map<SectionType, List<ContentBlock>> blocksByType, {required int number}) {
    final overviewText = topic.simpleExplanation?.ar ?? topic.summary;
    if (!_hasText(overviewText)) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('OVERVIEW', 'نظرة عامة', number: number),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            overviewText,
            style: const TextStyle(fontSize: 15, color: _textPrimary, height: 1.8),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ───────────── IMPORTANCE · 02 ─────────────

  Widget _buildImportanceSection(EngineeringTopic topic, Map<SectionType, List<ContentBlock>> blocksByType, {required int number}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('IMPORTANCE', 'الأهمية الهندسية', number: number),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _softPanel,
              borderRadius: BorderRadius.circular(10),
              border: const Border(
                right: BorderSide(color: _accent, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasText(topic.siteNotes?.ar))
                  _buildImportanceItem(topic.siteNotes!.ar),
                if (_hasText(topic.codeNotes?.ar))
                  _buildImportanceItem(topic.codeNotes!.ar),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildImportanceItem(String text) {
    final display = _cleanDisplayText(text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Icon(Icons.diamond, size: 8, color: _accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── DIMENSIONS · 05 ─────────────

  Widget _buildDimensionsSection(Map<SectionType, List<ContentBlock>> blocksByType, {required int number}) {
    final tables = <TableBlock>[];
    final images = <Widget>[];
    for (final blocks in blocksByType.values) {
      for (final block in blocks) {
        if (block is TableBlock && block.data.rows.isNotEmpty) tables.add(block);
      }
      images.addAll(_imageBlocksFrom(blocks));
    }
    if (tables.isEmpty && images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('DIMENSIONS', 'القياسات والسماكات المتداولة', number: number),
        ...tables.map((t) => _buildEditorialTable(t)),
        ...images,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEditorialTable(TableBlock tableBlock) {
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
                style: const TextStyle(
                  fontSize: 13,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(_tableHeaderBg),
                headingTextStyle: const TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                dataTextStyle: const TextStyle(
                  color: _textPrimary,
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
        ],
      ),
    );
  }

  // ───────────── APPLICATION · 06 ─────────────

  Widget _buildApplicationSection(EngineeringTopic topic, Map<SectionType, List<ContentBlock>> blocksByType, {required int number}) {
    final executionBlocks = blocksByType[SectionType.execution] ?? <ContentBlock>[];
    final steps = executionBlocks.whereType<ExecutionStepBlock>().toList()
      ..sort((a, b) => a.step.stepNumber.compareTo(b.step.stepNumber));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('APPLICATION', 'طرق التنفيذ', number: number),
        if (_hasText(topic.beforeWork?.ar))
          _buildSubSection('قبل العمل', topic.beforeWork!.ar),
        if (_hasText(topic.duringWork?.ar))
          _buildSubSection('أثناء العمل', topic.duringWork!.ar),
        if (_hasText(topic.afterWork?.ar))
          _buildSubSection('بعد العمل', topic.afterWork!.ar),
        if (steps.isNotEmpty) ...[
          if (!_localizedHasText(topic.beforeWork) && !_localizedHasText(topic.duringWork) && !_localizedHasText(topic.afterWork))
            const SizedBox(height: 4)
          else
            const SizedBox(height: 8),
          ...steps.map((s) => _buildStepCard(s)),
        ],
        ..._imageBlocksFrom(executionBlocks),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSubSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(ExecutionStepBlock stepBlock) {
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
              color: _accent,
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
                  style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.6),
                ),
                if (step.notes != null && step.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.notes!,
                    style: const TextStyle(fontSize: 12, color: _textSecondary, height: 1.5),
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

  Widget _buildInspectionSection(EngineeringTopic topic, Map<SectionType, List<ContentBlock>> blocksByType, {required int number}) {
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
        _buildSectionHeader('INSPECTION', 'فحص الأعمال بعد الإنجاز', number: number),
        ...validAcceptReject.map((item) => _buildInspectionRow(
              item.criteriaAr,
              item.acceptanceLimitAr,
              item.methodAr,
              item.isCritical,
            )),
        ...validInspPoints.map((b) => _buildInspectionRow(
              b.point.criteria,
              b.point.acceptableTolerance,
              b.point.method,
              b.point.isCritical,
            )),
        ...validChecklists.map(_buildChecklistBlock),
        ..._imageBlocksFrom(inspBlocks),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInspectionRow(String criteria, String? limit, String? method, bool isCritical) {
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
              color: isCritical ? _dangerText : _textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.6),
                children: [
                  TextSpan(
                    text: criteria,
                    style: TextStyle(fontWeight: isCritical ? FontWeight.w600 : FontWeight.normal),
                  ),
                  if (limit != null && limit.isNotEmpty)
                    TextSpan(
                      text: ' — $limit',
                      style: const TextStyle(color: _textSecondary),
                    ),
                  if (method != null && method.isNotEmpty)
                    TextSpan(
                      text: ' | $method',
                      style: const TextStyle(color: _textMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistBlock(ChecklistBlock block) {
    final validItems = block.items.where((i) => _hasText(i.text)).toList();
    if (validItems.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasText(block.title)) ...[
              Text(
                block.title!,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary),
              ),
              const SizedBox(height: 10),
            ],
            ...validItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_box_outline_blank, size: 18, color: _textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.text,
                          style: const TextStyle(fontSize: 13, color: _textPrimary, height: 1.5),
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

  Widget _buildImageBlock(ImageBlock block) {
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
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          if (_hasText(block.caption))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  block.caption!,
                  style: const TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _imageBlocksFrom(List<ContentBlock> blocks) {
    return blocks
        .whereType<ImageBlock>()
        .where((b) => b.imageUrl.isNotEmpty)
        .map(_buildImageBlock)
        .toList();
  }

  // ───────────── COMMON MISTAKES · 08 ─────────────

  Widget _buildSafetySection(Map<SectionType, List<ContentBlock>> blocksByType, {required int number}) {
    final safetyBlocks = blocksByType[SectionType.safety] ?? <ContentBlock>[];
    final validNotes = safetyBlocks.whereType<SafetyNoteBlock>().where((s) => _hasText(s.note.message)).toList();
    if (validNotes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('SAFETY', 'تنبيهات السلامة', number: number),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _softPanel,
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
                        style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.6),
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

  Widget _buildCommonMistakesSection(EngineeringTopic topic, Map<SectionType, List<ContentBlock>> blocksByType, {required int number}) {
    final validMistakes = topic.commonMistakes.where((m) => _hasText(m.ar) || _hasText(m.en)).toList();

    if (validMistakes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('COMMON MISTAKES', 'أخطاء شائعة يجب تجنبها', number: number),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _accentSoft.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _dangerText.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...validMistakes.map((m) => _buildMistakeItem(m.ar)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMistakeItem(String text) {
    if (!_hasText(text)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('×', style: TextStyle(fontSize: 16, color: _dangerText, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── Report Wording ─────────────

  Widget _buildReportWordingSection(EngineeringTopic topic) {
    final wording = _cleanDisplayText(topic.reportWording!.ar);
    if (wording.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('', 'صياغة تقرير'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
              color: _paperBg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wording,
                  style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.7),
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
                          color: _accentSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy, size: 14, color: _accent),
                            SizedBox(width: 6),
                            Text(
                              'نسخ',
                              style: TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w600),
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

  Widget _buildRelatedToolsSection(BuildContext context, EngineeringTopic topic) {
    const toolNames = <String, String>{
      '/calculator/concrete': 'حاسبة الخرسانة',
      '/calculator/steel': 'حاسبة الحديد',
      '/calculator/tile': 'حاسبة البلاط',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('', 'أدوات ذات صلة'),
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
                    color: _accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 13, color: _accent, fontWeight: FontWeight.w500),
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
