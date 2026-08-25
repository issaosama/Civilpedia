import 'package:civilpedia/core/theme/app_colors.dart';
import 'package:civilpedia/core/widgets/civil_app_bar.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/localized_text.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_favorites_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/screens/topic_detail_screen.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/inspection_point_widget.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/encyclopedia/topics/concrete',
  routes: [
    GoRoute(
      path: '/encyclopedia/topics/:id',
      builder: (_, __) => const Scaffold(
        body: Center(child: Text('topic list')),
      ),
    ),
    GoRoute(
      path: '/encyclopedia/topic/:id',
      builder: (_, state) => TopicDetailScreen(
        topicId: state.pathParameters['id']!,
      ),
    ),
  ],
);

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

EngineeringTopic _richTopic({
  String title = 'فحص الخرسانة',
  String summary = 'ملخص مختصر لفحص الخرسانة',
  List<String> keyTopics = const ['فحص', 'خرسانة', 'جودة'],
  String? visualTheme,
}) {
  return EngineeringTopic(
    id: 'td1',
    titleAr: title,
    categoryId: 'concrete',
    summary: summary,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    keyTopics: keyTopics,
    simpleExplanation: const LocalizedText(
      ar: 'شرح مبسط لأهمية فحص الخرسانة بعد الصب.',
      en: 'Simple explanation',
    ),
    visualTheme: visualTheme,
    relatedToolRoutes: const ['/calculator/concrete'],
  );
}

final List<TopicSection> _defaultSections = [
  const TopicSection(
    id: 's_exec',
    title: 'خطوات التنفيذ',
    type: SectionType.execution,
    order: 1,
  ),
  const TopicSection(
    id: 's_safety',
    title: 'إجراءات السلامة',
    type: SectionType.safety,
    order: 2,
  ),
  const TopicSection(
    id: 's_insp',
    title: 'الفحص',
    type: SectionType.inspection,
    order: 3,
  ),
  const TopicSection(
    id: 's_table',
    title: 'جدول البيانات',
    type: SectionType.general,
    order: 4,
  ),
];

final Map<String, List<ContentBlock>> _defaultBlocks = {
  's_exec': [
    const TextBlock(content: 'نص توضيحي عام عن خطوات التنفيذ.'),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 1,
        description: 'جهز المعدات والأدوات المطلوبة.',
      ),
    ),
  ],
  's_safety': [
    SafetyNoteBlock(
      note: const SafetyNote(
        message: 'ارتدِ معدات الوقاية الشخصية.',
        severity: SafetySeverity.high,
      ),
    ),
  ],
  's_insp': [
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'معيار الفحص الأساسي',
        acceptableTolerance: '±5 ملم',
        method: 'القياس بالشريط',
        isCritical: true,
      ),
    ),
  ],
  's_table': [
    TableBlock(
      data: const TableData(
        headers: ['عنصر', 'القيمة'],
        rows: [TableRowData(cells: ['قوة الضغط', '25 ميجا'])],
      ),
    ),
  ],
};

Future<void> _pumpScreen(
  WidgetTester tester, {
  String topicId = 'td1',
  EngineeringTopic? topic,
  List<TopicSection>? sections,
  Map<String, List<ContentBlock>>? blocks,
}) async {
  final effectiveTopic = topic ?? _richTopic();
  final repo = _FakeRepo(
    topic: effectiveTopic,
    sections: sections ?? _defaultSections,
    blocksBySection: blocks ?? _defaultBlocks,
  );
  final provider = EncyclopediaProvider(repository: repo);
  final favoritesStore = _FakeFavoritesStore();
  final favoritesProvider = EncyclopediaFavoritesProvider(store: favoritesStore);
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
        home: TopicDetailScreen(topicId: topicId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TopicDetailScreen D3B', () {
    testWidgets('renders successfully with light page background', (
      tester,
    ) async {
      await _pumpScreen(tester);

      expect(find.byType(CivilAppBar), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, AppColors.pageBackground);
      expect(appBar.elevation, 0);
    });

    testWidgets('renders topic title and summary', (tester) async {
      await _pumpScreen(tester);

      expect(find.text('فحص الخرسانة'), findsOneWidget);
      expect(find.text('شرح مبسط لأهمية فحص الخرسانة بعد الصب.'), findsOneWidget);
    });

    testWidgets('renders representative engineering blocks', (tester) async {
      await _pumpScreen(tester);

      expect(find.text('نص توضيحي عام عن خطوات التنفيذ.'), findsOneWidget);
      expect(find.text('جهز المعدات والأدوات المطلوبة.'), findsOneWidget);
      expect(find.text('ارتدِ معدات الوقاية الشخصية.'), findsOneWidget);
      expect(find.byType(InspectionPointWidget), findsOneWidget);
      expect(find.textContaining('معيار الفحص'), findsOneWidget);
      expect(find.text('عنصر'), findsOneWidget);
      expect(find.text('القيمة'), findsOneWidget);
    });

    testWidgets('favorite action toggles and persists in provider', (
      tester,
    ) async {
      await _pumpScreen(tester);

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);

      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('back button is at the visual start in RTL', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => EncyclopediaProvider(
                repository: _FakeRepo(
                  topic: _richTopic(),
                  sections: _defaultSections,
                  blocksBySection: _defaultBlocks,
                ),
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => EncyclopediaFavoritesProvider(
                store: _FakeFavoritesStore(),
              ),
            ),
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
            home: Navigator(
              key: navigatorKey,
              onGenerateRoute: (settings) {
                if (settings.name == '/detail') {
                  return MaterialPageRoute(
                    builder: (_) => const TopicDetailScreen(topicId: 'td1'),
                    settings: settings,
                  );
                }
                return MaterialPageRoute(
                  builder: (_) => const SizedBox.expand(),
                  settings: settings,
                );
              },
            ),
          ),
        ),
      );

      navigatorKey.currentState!.pushNamed('/detail');
      await tester.pumpAndSettle();

      final backFinder = find.byType(BackButton);
      expect(backFinder, findsOneWidget);

      final backBox = tester.renderObject<RenderBox>(backFinder);
      final appBarBox = tester.renderObject<RenderBox>(find.byType(AppBar));
      final backCenter = backBox.localToGlobal(backBox.size.center(Offset.zero));
      final appBarCenter =
          appBarBox.localToGlobal(appBarBox.size.center(Offset.zero));
      expect(backCenter.dx, greaterThan(appBarCenter.dx));
    });

    testWidgets('long Arabic title does not overflow', (tester) async {
      final longTitle = 'عنوان طويل جداً يتضمن مصطلحات هندسية مثل الخرسانة المسلحة والهبوط والانضغاط';
      await _pumpScreen(
        tester,
        topic: _richTopic(title: longTitle),
      );

      expect(find.text(longTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('long content scrolls vertically', (tester) async {
      final manyBlocks = <ContentBlock>[
        for (var i = 0; i < 30; i++)
          TextBlock(content: 'فقرة توضيحية رقم $i تحتوي على نص طويل للتأكد من التمرير.'),
      ];
      await _pumpScreen(
        tester,
        sections: [
          const TopicSection(
            id: 's_long',
            title: 'محتوى طويل',
            type: SectionType.general,
            order: 1,
          ),
        ],
        blocks: {'s_long': manyBlocks},
      );

      expect(find.text('محتوى طويل'), findsOneWidget);
      const firstBlock = 'فقرة توضيحية رقم 0 تحتوي على نص طويل للتأكد من التمرير.';
      const lastBlock = 'فقرة توضيحية رقم 29 تحتوي على نص طويل للتأكد من التمرير.';
      expect(find.text(firstBlock), findsOneWidget);

      final scrollable = find.byType(SingleChildScrollView);
      expect(scrollable, findsOneWidget);

      await tester.drag(scrollable, const Offset(0, -1500));
      await tester.pumpAndSettle();
      await tester.drag(scrollable, const Offset(0, -1500));
      await tester.pumpAndSettle();

      expect(find.text(lastBlock), findsOneWidget);
    });

    testWidgets('preserves section order from provider', (tester) async {
      await _pumpScreen(tester);

      final first = find.text('خطوات التنفيذ');
      final second = find.text('إجراءات السلامة');
      expect(first, findsOneWidget);
      expect(second, findsOneWidget);

      final firstOffset = tester.getTopLeft(first);
      final secondOffset = tester.getTopLeft(second);
      expect(firstOffset.dy, lessThan(secondOffset.dy));
    });

    testWidgets('loads the requested topic identity', (tester) async {
      final provider = EncyclopediaProvider(
        repository: _FakeRepo(
          topic: _richTopic(),
          sections: _defaultSections,
          blocksBySection: _defaultBlocks,
        ),
      );
      final favoritesProvider = EncyclopediaFavoritesProvider(
        store: _FakeFavoritesStore(),
      );
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
            home: const TopicDetailScreen(topicId: 'td1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.currentTopic?.id, 'td1');
    });

    testWidgets('navigates from topic list to detail via /encyclopedia/topic/:id', (
      tester,
    ) async {
      final provider = EncyclopediaProvider(
        repository: _FakeRepo(
          topic: _richTopic(),
          sections: _defaultSections,
          blocksBySection: _defaultBlocks,
        ),
      );
      await provider.loadAllTopics();
      final favoritesProvider = EncyclopediaFavoritesProvider(
        store: _FakeFavoritesStore(),
      );
      await favoritesProvider.load();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: favoritesProvider),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: MaterialApp.router(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            routerConfig: _router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      _router.go('/encyclopedia/topic/td1');
      await tester.pumpAndSettle();

      expect(find.text('فحص الخرسانة'), findsOneWidget);
    });
  });

  group('TopicDetailScreen D3B responsive', () {
    const widths = [412.0, 390.0, 360.0, 320.0];

    for (final width in widths) {
      testWidgets('renders without overflow at ${width.toInt()}px', (
        tester,
      ) async {
        tester.binding.setSurfaceSize(Size(width, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await _pumpScreen(
          tester,
          topic: _richTopic(
            title: 'عنوان طويل جداً يتضمن مصطلحات هندسية متعددة',
            keyTopics: const ['فحص', 'خرسانة', 'جودة', 'اختبار', 'هبوط'],
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
