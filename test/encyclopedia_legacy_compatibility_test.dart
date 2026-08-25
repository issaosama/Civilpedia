import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/accept_reject_item.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/localized_text.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_favorites_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/screens/topic_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// D3C1 — Legacy content compatibility guardrails.
///
/// These tests protect CURRENT backward-compatible behavior. They do NOT
/// assert the desired future normalized behavior. If a legacy field is
/// removed from the entity or presentation layer, the corresponding test
/// must fail, forcing an explicit compatibility decision.

class _FakeFavoritesStore implements EncyclopediaFavoritesStore {
  final List<String> _ids = [];

  @override
  Future<List<String>> read() async => List.unmodifiable(_ids);

  @override
  Future<void> add(String topicId) async => _ids.add(topicId);

  @override
  Future<void> remove(String topicId) async => _ids.remove(topicId);
}

class _FakeRepo implements EncyclopediaRepository {
  final EngineeringTopic topic;
  final List<TopicSection> sections;
  final Map<String, List<ContentBlock>> blocksBySection;

  _FakeRepo({
    required this.topic,
    required this.sections,
    required this.blocksBySection,
  });

  @override
  Future<EngineeringTopic?> getTopicById(String id) async =>
      topic.id == id ? topic : null;

  @override
  Future<List<EngineeringTopic>> getAllTopics() async => [topic];

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async =>
      [];

  @override
  Future<Map<String, CategoryInfo>> getCategories() async => {
        topic.categoryId: CategoryInfo(
          id: topic.categoryId,
          titleAr: 'الخرسانة',
          titleEn: 'Concrete',
        ),
      };

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async =>
      sections;

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async =>
      blocksBySection[sectionId] ?? const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => [];
}

Future<void> _pumpTopicDetail(
  WidgetTester tester, {
  required EngineeringTopic topic,
  List<TopicSection>? sections,
  Map<String, List<ContentBlock>>? blocks,
}) async {
  final repo = _FakeRepo(
    topic: topic,
    sections: sections ?? const [],
    blocksBySection: blocks ?? const {},
  );
  final provider = EncyclopediaProvider(repository: repo);
  final favoritesProvider =
      EncyclopediaFavoritesProvider(store: _FakeFavoritesStore());
  await favoritesProvider.load();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        ChangeNotifierProvider.value(value: favoritesProvider),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: TopicDetailScreen(topicId: topic.id),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

EngineeringTopic _baseTopic({
  String id = 'legacy-t1',
  String titleAr = 'موضوع توافقي',
  String summary = 'ملخص احتياطي',
  LocalizedText? simpleExplanation,
  LocalizedText? beforeWork,
  LocalizedText? duringWork,
  LocalizedText? afterWork,
  LocalizedText? siteNotes,
  LocalizedText? codeNotes,
  LocalizedText? reportWording,
  List<LocalizedText> commonMistakes = const [],
  List<AcceptRejectItem> acceptRejectItems = const [],
  String? featuredImageUrl,
}) {
  return EngineeringTopic(
    id: id,
    titleAr: titleAr,
    categoryId: 'concrete',
    summary: summary,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    simpleExplanation: simpleExplanation,
    beforeWork: beforeWork,
    duringWork: duringWork,
    afterWork: afterWork,
    siteNotes: siteNotes,
    codeNotes: codeNotes,
    reportWording: reportWording,
    commonMistakes: commonMistakes,
    acceptRejectItems: acceptRejectItems,
    featuredImageUrl: featuredImageUrl,
  );
}

void _assertVerticalOrder(WidgetTester tester, List<String> labels) {
  double? lastY;
  for (final label in labels) {
    final finder = find.text(label);
    expect(finder, findsOneWidget, reason: 'Expected "$label" on screen');
    final y = tester.getTopLeft(finder).dy;
    if (lastY != null) {
      expect(y, greaterThan(lastY), reason: '"$label" should appear below previous label');
    }
    lastY = y;
  }
}

void main() {
  group('Legacy compatibility guardrails (D3C1)', () {
    // ─────────────────────────────────────────────────────────────
    // A. simpleExplanation precedence contract
    // ─────────────────────────────────────────────────────────────
    testWidgets(
      'simpleExplanation takes precedence over summary when populated',
      (tester) async {
        final topic = _baseTopic(
          simpleExplanation: const LocalizedText(ar: 'شرح مبسط قديم', en: ''),
          summary: 'ملخص حديث',
        );
        await _pumpTopicDetail(tester, topic: topic);

        expect(find.text('شرح مبسط قديم'), findsOneWidget);
        expect(find.text('ملخص حديث'), findsNothing);
      },
    );

    testWidgets(
      'summary is used as fallback when simpleExplanation is null',
      (tester) async {
        final topic = _baseTopic(
          simpleExplanation: null,
          summary: 'ملخص احتياطي',
        );
        await _pumpTopicDetail(tester, topic: topic);

        expect(find.text('ملخص احتياطي'), findsOneWidget);
        expect(find.text('شرح مبسط قديم'), findsNothing);
      },
    );

    // ─────────────────────────────────────────────────────────────
    // B. beforeWork / duringWork / afterWork contract
    // ─────────────────────────────────────────────────────────────
    testWidgets(
      'legacy before/during/after work renders in the existing order',
      (tester) async {
        final topic = _baseTopic(
          beforeWork: const LocalizedText(ar: 'تحضير الموقع قبل العمل.', en: ''),
          duringWork: const LocalizedText(ar: 'مراقبة الجودة أثناء العمل.', en: ''),
          afterWork: const LocalizedText(ar: 'المعالجة والصيانة بعد العمل.', en: ''),
        );
        await _pumpTopicDetail(tester, topic: topic);

        expect(find.text('طريقة التنفيذ'), findsOneWidget);
        _assertVerticalOrder(tester, [
          'قبل العمل',
          'أثناء العمل',
          'بعد العمل',
        ]);
        expect(find.text('تحضير الموقع قبل العمل.'), findsOneWidget);
        expect(find.text('مراقبة الجودة أثناء العمل.'), findsOneWidget);
        expect(find.text('المعالجة والصيانة بعد العمل.'), findsOneWidget);
      },
    );

    // ─────────────────────────────────────────────────────────────
    // C. siteNotes / codeNotes contract
    // ─────────────────────────────────────────────────────────────
    testWidgets(
      'legacy siteNotes and codeNotes render the importance section',
      (tester) async {
        final topic = _baseTopic(
          siteNotes: const LocalizedText(ar: 'ملاحظة موقع مهمة.', en: ''),
          codeNotes: const LocalizedText(ar: 'ملاحظة كودية مهمة.', en: ''),
        );
        await _pumpTopicDetail(tester, topic: topic);

        expect(find.text('الأهمية الهندسية'), findsOneWidget);
        expect(find.text('ملاحظة موقع مهمة.'), findsOneWidget);
        expect(find.text('ملاحظة كودية مهمة.'), findsOneWidget);
      },
    );

    // ─────────────────────────────────────────────────────────────
    // D. reportWording contract
    // ─────────────────────────────────────────────────────────────
    testWidgets(
      'legacy report wording remains renderable',
      (tester) async {
        final topic = _baseTopic(
          reportWording: const LocalizedText(
            ar: 'تم الفحص وفقاً للمواصفات ولم تسجل ملاحظات.',
            en: '',
          ),
        );
        await _pumpTopicDetail(tester, topic: topic);

        expect(find.text('صياغة تقرير'), findsOneWidget);
        expect(
          find.text('تم الفحص وفقاً للمواصفات ولم تسجل ملاحظات.'),
          findsOneWidget,
        );
      },
    );

    // ─────────────────────────────────────────────────────────────
    // E. commonMistakes contract
    // ─────────────────────────────────────────────────────────────
    testWidgets(
      'legacy common mistakes remain renderable',
      (tester) async {
        final topic = _baseTopic(
          commonMistakes: const [
            LocalizedText(ar: 'صب الخرسانة في حرارة مرتفعة.', en: ''),
            LocalizedText(ar: 'إهمال معالجة الخرسانة.', en: ''),
          ],
        );
        await _pumpTopicDetail(tester, topic: topic);

        expect(find.text('أخطاء شائعة يجب تجنبها'), findsOneWidget);
        expect(find.text('صب الخرسانة في حرارة مرتفعة.'), findsOneWidget);
        expect(find.text('إهمال معالجة الخرسانة.'), findsOneWidget);
      },
    );

    // ─────────────────────────────────────────────────────────────
    // F. acceptRejectItems contract
    // ─────────────────────────────────────────────────────────────
    testWidgets(
      'legacy accept/reject items remain renderable',
      (tester) async {
        final topic = _baseTopic(
          acceptRejectItems: const [
            AcceptRejectItem(
              criteriaAr: 'معيار القبول الأساسي',
              acceptanceLimitAr: '±2 ملم',
              methodAr: 'القياس بالشريط',
              isCritical: true,
            ),
          ],
        );
        await _pumpTopicDetail(tester, topic: topic);

        expect(find.text('فحص الأعمال بعد الإنجاز'), findsOneWidget);
        // Legacy inspection criteria are rendered inside a RichText span, so we
        // verify the plain text directly rather than relying on find.textContaining.
        final hasCriteria = tester
            .widgetList(find.byType(RichText))
            .whereType<RichText>()
            .any(
              (rt) => rt.text.toPlainText().contains('معيار القبول الأساسي'),
            );
        expect(hasCriteria, isTrue);
      },
    );

    // ─────────────────────────────────────────────────────────────
    // G. Modern-only topic
    // ─────────────────────────────────────────────────────────────
    testWidgets(
      'modern sections and blocks render without legacy fallback sections',
      (tester) async {
        final topic = _baseTopic(
          simpleExplanation: null,
          summary: 'ملخص حديث',
        );
        const sections = [
          TopicSection(
            id: 's_modern',
            title: 'قسم حديث',
            type: SectionType.general,
            order: 1,
          ),
        ];
        const blocks = {
          's_modern': [TextBlock(content: 'نص حديث داخل قسم حديث.')],
        };
        await _pumpTopicDetail(
          tester,
          topic: topic,
          sections: sections,
          blocks: blocks,
        );

        expect(find.text('نص حديث داخل قسم حديث.'), findsOneWidget);
        expect(find.text('طريقة التنفيذ'), findsNothing);
        expect(find.text('الأهمية الهندسية'), findsNothing);
        expect(find.text('أخطاء شائعة يجب تجنبها'), findsNothing);
        expect(find.text('فحص الأعمال بعد الإنجاز'), findsNothing);
        expect(find.text('صياغة تقرير'), findsNothing);
      },
    );

    // ─────────────────────────────────────────────────────────────
    // H. Mixed legacy + modern topic
    // ─────────────────────────────────────────────────────────────
    testWidgets(
      'mixed legacy and modern content renders both without deduplication',
      (tester) async {
        final topic = _baseTopic(
          simpleExplanation: const LocalizedText(ar: 'شرح بسيط قديم', en: ''),
          commonMistakes: const [
            LocalizedText(ar: 'خطأ قديم في قائمة الموضوع.', en: ''),
          ],
        );
        const sections = [
          TopicSection(
            id: 's_mixed',
            title: 'قسم مختلط',
            type: SectionType.general,
            order: 1,
          ),
        ];
        const blocks = {
          's_mixed': [
            TextBlock(content: 'نص حديث داخل القسم المختلط.'),
            CommonMistakesBlock(
              title: 'أخطاء حديثة',
              items: [CalloutItem(text: 'خطأ حديث داخل كتلة.')],
            ),
          ],
        };
        await _pumpTopicDetail(
          tester,
          topic: topic,
          sections: sections,
          blocks: blocks,
        );

        // Modern content is present.
        expect(find.text('نص حديث داخل القسم المختلط.'), findsOneWidget);
        expect(find.text('خطأ حديث داخل كتلة.'), findsOneWidget);

        // Legacy content is ALSO present — current behavior does not deduplicate.
        expect(find.text('شرح بسيط قديم'), findsOneWidget);
        expect(find.text('أخطاء شائعة يجب تجنبها'), findsOneWidget);
        expect(find.text('خطأ قديم في قائمة الموضوع.'), findsOneWidget);
      },
    );

    // ─────────────────────────────────────────────────────────────
    // Featured image legacy field status
    // ─────────────────────────────────────────────────────────────
    testWidgets(
      'featuredImageUrl is preserved by entity serialization (unused by UI)',
      (tester) async {
        const url = 'assets/images/legacy_featured.png';
        final topic = _baseTopic(featuredImageUrl: url);
        final roundTripped = EngineeringTopic.fromJson(topic.toJson());

        expect(roundTripped.featuredImageUrl, url);
      },
    );
  });
}
