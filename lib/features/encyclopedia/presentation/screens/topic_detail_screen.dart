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
import '../../../../core/widgets/async_value_widget.dart';
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
    EncyclopediaCardColors.apply(EncyclopediaTopicTheme.fromKey(topic.visualTheme));
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
          _buildTopBar(context, isDark: isDark),
          _buildDivider(isDark: isDark),
          _buildBrandPill(isDark: isDark),
          if (_hasText(topic.coverImageUrl)) _buildCoverImage(topic, isDark: isDark),
          _buildHeroSection(topic, isDark: isDark),
          const SizedBox(height: 8),
          for (final section in sortedSections)
            numbered((n) => _buildSectionByOrder(section, provider, isDark: isDark, number: n)),
          if (_hasLegacyMetadata(topic))
            ..._buildLegacySections(topic, isDark: isDark, startNumber: seq + 1),
          if (topic.relatedToolRoutes.isNotEmpty)
            _buildRelatedToolsSection(context, topic, isDark: isDark),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ───────────── Data helpers ─────────────

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  bool _localizedHasText(LocalizedText? value) => _hasText(value?.ar) || _hasText(value?.en);

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

  // ───────────── Section-driven block rendering ─────────────

  Widget _buildSectionByOrder(TopicSection section, EncyclopediaProvider provider, {required bool isDark, required int number}) {
    final blocks = provider.blocksForSection(section.id);
    if (blocks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(section.type.labelAr.toUpperCase(), section.title, number: number, isDark: isDark),
        ...blocks.map((block) => _renderSingleBlock(block, isDark: isDark)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _renderSingleBlock(ContentBlock block, {required bool isDark}) {
    return ContentBlockWidget(block: block);
  }

  // ───────────── Legacy metadata sections ─────────────

  List<Widget> _buildLegacySections(EngineeringTopic topic, {required bool isDark, required int startNumber}) {
    final widgets = <Widget>[];
    int n = startNumber;

    if (_hasText(topic.siteNotes?.ar) || _hasText(topic.codeNotes?.ar)) {
      widgets.add(_buildImportanceSection(topic, isDark: isDark, number: n++));
    }

    if (_localizedHasText(topic.beforeWork) || _localizedHasText(topic.duringWork) || _localizedHasText(topic.afterWork)) {
      widgets.add(_buildLegacyAppSection(topic, isDark: isDark, number: n++));
    }

    if (topic.acceptRejectItems.any((item) => _hasText(item.criteriaAr))) {
      widgets.add(_buildLegacyInspSection(topic, isDark: isDark, number: n++));
    }

    if (topic.commonMistakes.any((m) => _hasText(m.ar) || _hasText(m.en))) {
      widgets.add(_buildCommonMistakesSection(topic, isDark: isDark, number: n++));
    }

    if (_hasText(topic.reportWording?.ar)) {
      widgets.add(_buildReportWordingSection(topic, isDark: isDark));
    }

    return widgets;
  }

  Widget _buildLegacyAppSection(EngineeringTopic topic, {required bool isDark, required int number}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('APPLICATION', 'طريقة التنفيذ', number: number, isDark: isDark),
        if (_hasText(topic.beforeWork?.ar))
          _buildSubSection('قبل العمل', topic.beforeWork!.ar, isDark: isDark),
        if (_hasText(topic.duringWork?.ar))
          _buildSubSection('أثناء العمل', topic.duringWork!.ar, isDark: isDark),
        if (_hasText(topic.afterWork?.ar))
          _buildSubSection('بعد العمل', topic.afterWork!.ar, isDark: isDark),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLegacyInspSection(EngineeringTopic topic, {required bool isDark, required int number}) {
    final validItems = topic.acceptRejectItems.where((item) => _hasText(item.criteriaAr)).toList();
    if (validItems.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('INSPECTION', 'فحص الأعمال بعد الإنجاز', number: number, isDark: isDark),
        ...validItems.map((item) => _buildInspectionRow(
              item.criteriaAr,
              item.acceptanceLimitAr,
              item.methodAr,
              item.isCritical,
              isDark: isDark,
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  // ───────────── Top Bar ─────────────

  Widget _buildTopBar(BuildContext context, {required bool isDark}) {
    final favoritesProvider = context.watch<EncyclopediaFavoritesProvider>();
    final isFavorite = favoritesProvider.isFavorite(widget.topicId);

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
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              favoritesProvider.toggle(widget.topicId);
            },
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: isFavorite
                  ? EncyclopediaCardColors.dangerText
                  : (isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary),
            ),
            tooltip: isFavorite ? Ar.removeFromFavorites : Ar.addToFavorites,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
            context.read<EncyclopediaProvider>().categoryLabel(topic.categoryId),
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
        if (topic.keyTopics.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كلمات مفتاحية',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? EncyclopediaCardColors.darkTextMuted : EncyclopediaCardColors.textMuted,
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
                    .map((kt) => _detailChip(kt, isDark: isDark))
                    .toList(),
                ),
              ],
            ),
          )
        else if (topic.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: topic.tags.map((tag) => _detailChip(tag, isDark: isDark)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _detailChip(String label, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? EncyclopediaCardColors.chipDarkBg : EncyclopediaCardColors.chipBg,
        border: Border.all(
          color: isDark ? EncyclopediaCardColors.chipDarkBorder : EncyclopediaCardColors.chipBorder,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? EncyclopediaCardColors.chipDarkText : EncyclopediaCardColors.chipText,
        ),
      ),
    );
  }

  Widget _buildCoverImage(EngineeringTopic topic, {required bool isDark}) {
    final url = topic.coverImageUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: (isDark ? EncyclopediaCardColors.darkBorder : EncyclopediaCardColors.border).withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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

  Widget _buildImportanceSection(EngineeringTopic topic, {required bool isDark, required int number}) {
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

  // ───────────── INSPECTION · 07 ─────────────

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

  // ───────────── COMMON MISTAKES · 08 ─────────────

  Widget _buildCommonMistakesSection(EngineeringTopic topic, {required bool isDark, required int number}) {
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
