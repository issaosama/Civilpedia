import 'package:civilpedia/core/theme/app_colors.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/core/widgets/civil_app_bar.dart';
import 'package:civilpedia/core/widgets/search_bar_widget.dart';
import 'package:civilpedia/core/widgets/section_header.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/screens/categories_screen.dart';
import 'package:civilpedia/features/encyclopedia/presentation/screens/encyclopedia_screen.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/screens/topic_list_screen.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/encyclopedia_category_card.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/topic_list_card.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

EngineeringTopic _topic(
  String id,
  String title, {
  String categoryId = 'concrete',
  List<String> tags = const [],
  List<String> keyTopics = const [],
}) =>
    EngineeringTopic(
      id: id,
      titleAr: title,
      categoryId: categoryId,
      summary: 'ملخص $title',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      tags: tags,
      keyTopics: keyTopics,
    );

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  final List<EngineeringTopic> topics;
  final Map<String, CategoryInfo> categories;

  _FakeEncyclopediaRepository({
    required this.topics,
    this.categories = const {},
  });

  @override
  Future<EngineeringTopic?> getTopicById(String id) async =>
      topics.where((t) => t.id == id).firstOrNull;

  @override
  Future<List<EngineeringTopic>> getAllTopics() async => topics;

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async =>
      topics.where((t) => t.categoryId == categoryId).toList();

  @override
  Future<Map<String, CategoryInfo>> getCategories() async => categories;

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async => const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async =>
      const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => topics;
}

EncyclopediaProvider _providerWithTopics() {
  return EncyclopediaProvider(
    repository: _FakeEncyclopediaRepository(
      topics: [
        _topic('t1', 'فحص الخرسانة', categoryId: 'concrete'),
        _topic('t2', 'خلط الخرسانة', categoryId: 'concrete'),
        _topic('t3', 'حديد التسليح', categoryId: 'steel'),
      ],
      categories: {
        'concrete': const CategoryInfo(id: 'concrete', titleAr: 'الخرسانة', titleEn: 'Concrete'),
        'steel': const CategoryInfo(id: 'steel', titleAr: 'الحديد', titleEn: 'Steel'),
      },
    ),
  );
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  EncyclopediaProvider? provider,
}) async {
  final effectiveProvider = provider ?? _providerWithTopics();
  await effectiveProvider.loadAllTopics();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: effectiveProvider),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EncyclopediaScreen D3A', () {
    testWidgets('uses CivilAppBar with light page-background treatment', (
      tester,
    ) async {
      await _pumpScreen(tester, const EncyclopediaScreen());

      expect(find.byType(CivilAppBar), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, AppTheme.lightTheme.scaffoldBackgroundColor);
      expect(appBar.elevation, 0);
    });

    testWidgets('does not use the legacy amber AppBar', (tester) async {
      await _pumpScreen(tester, const EncyclopediaScreen());

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, isNot(AppColors.primaryDark));
      expect(appBar.backgroundColor, isNot(AppColors.primary));
    });

    testWidgets('uses the shared SearchBarWidget', (tester) async {
      await _pumpScreen(tester, const EncyclopediaScreen());

      expect(find.byType(SearchBarWidget), findsOneWidget);
    });

    testWidgets('uses SectionHeader for category sections', (tester) async {
      await _pumpScreen(tester, const EncyclopediaScreen());

      expect(find.byType(SectionHeader), findsWidgets);
      expect(find.text(Ar.viewAll), findsWidgets);
    });

    testWidgets('initial route query still drives provider search', (
      tester,
    ) async {
      final provider = _providerWithTopics();
      await _pumpScreen(
        tester,
        const EncyclopediaScreen(initialQuery: 'خرسانة'),
        provider: provider,
      );

      expect(provider.isSearchActive, isTrue);
      expect(provider.currentSearchQuery, 'خرسانة');
      expect(find.byType(TopicListCard), findsWidgets);
      expect(find.byType(SectionHeader), findsNothing);
    });

    testWidgets('typing in SearchBarWidget updates search results', (
      tester,
    ) async {
      final provider = _providerWithTopics();
      await _pumpScreen(tester, const EncyclopediaScreen(), provider: provider);

      await tester.enterText(find.byType(SearchBarWidget), 'حديد');
      await tester.pumpAndSettle();

      expect(provider.currentSearchQuery, 'حديد');
      expect(find.byType(TopicListCard), findsOneWidget);
      expect(find.text('حديد التسليح'), findsOneWidget);
    });

    testWidgets('clearing search returns to category sections', (
      tester,
    ) async {
      final provider = _providerWithTopics();
      await _pumpScreen(
        tester,
        const EncyclopediaScreen(initialQuery: 'حديد'),
        provider: provider,
      );

      expect(provider.isSearchActive, isTrue);

      await tester.enterText(find.byType(SearchBarWidget), '');
      await tester.pumpAndSettle();

      expect(provider.isSearchActive, isFalse);
      expect(find.byType(SectionHeader), findsWidgets);
    });

    testWidgets('category tap routes to topic list', (tester) async {
      final provider = _providerWithTopics();
      await provider.loadAllTopics();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
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
            routerConfig: GoRouter(
              initialLocation: '/encyclopedia',
              routes: [
                GoRoute(
                  path: '/encyclopedia',
                  builder: (_, __) => const EncyclopediaScreen(),
                ),
                GoRoute(
                  path: '/encyclopedia/topics/:id',
                  builder: (_, state) =>
                      TopicListScreen(categoryId: state.pathParameters['id']!),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(Ar.viewAll).first);
      await tester.pumpAndSettle();

      expect(find.byType(TopicListScreen), findsOneWidget);
    });
  });

  group('CategoriesScreen D3A', () {
    testWidgets('uses CivilAppBar with light treatment', (tester) async {
      await _pumpScreen(tester, const CategoriesScreen());

      expect(find.byType(CivilAppBar), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, AppTheme.lightTheme.scaffoldBackgroundColor);
    });

    testWidgets('renders real categories with EncyclopediaCategoryCard', (
      tester,
    ) async {
      await _pumpScreen(tester, const CategoriesScreen());

      expect(find.byType(EncyclopediaCategoryCard), findsWidgets);
      expect(find.text('الخرسانة'), findsOneWidget);
      expect(find.text('الحديد'), findsOneWidget);
    });

    testWidgets('tapping a category navigates to topic list', (tester) async {
      final provider = _providerWithTopics();
      await provider.loadAllTopics();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
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
            routerConfig: GoRouter(
              initialLocation: '/categories',
              routes: [
                GoRoute(
                  path: '/categories',
                  builder: (_, __) => const CategoriesScreen(),
                ),
                GoRoute(
                  path: '/encyclopedia/topics/:id',
                  builder: (_, state) =>
                      TopicListScreen(categoryId: state.pathParameters['id']!),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('الخرسانة'));
      await tester.pumpAndSettle();

      expect(find.byType(TopicListScreen), findsOneWidget);
    });
  });

  group('TopicListScreen D3A', () {
    testWidgets('uses CivilAppBar with category title', (tester) async {
      final provider = _providerWithTopics();
      await _pumpScreen(
        tester,
        const TopicListScreen(categoryId: 'concrete'),
        provider: provider,
      );

      expect(find.byType(CivilAppBar), findsOneWidget);
      expect(find.text('الخرسانة'), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, AppTheme.lightTheme.scaffoldBackgroundColor);
    });

    testWidgets('renders TopicListCards and tap navigates to topic detail', (
      tester,
    ) async {
      final provider = _providerWithTopics();
      await provider.loadAllTopics();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
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
            routerConfig: GoRouter(
              initialLocation: '/encyclopedia/topics/concrete',
              routes: [
                GoRoute(
                  path: '/encyclopedia/topics/:id',
                  builder: (_, state) =>
                      TopicListScreen(categoryId: state.pathParameters['id']!),
                ),
                GoRoute(
                  path: '/encyclopedia/topic/:id',
                  builder: (_, state) => Scaffold(
                    body: Text('detail ${state.pathParameters['id']}'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TopicListCard), findsWidgets);

      await tester.tap(find.text('فحص الخرسانة'));
      await tester.pumpAndSettle();

      expect(find.text('detail t1'), findsOneWidget);
    });

    testWidgets('back button leads at the visual start in RTL', (tester) async {
      final provider = _providerWithTopics();
      final navigatorKey = GlobalKey<NavigatorState>();
      await provider.loadAllTopics();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
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
                if (settings.name == '/list') {
                  return MaterialPageRoute(
                    builder: (_) => const TopicListScreen(categoryId: 'concrete'),
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

      navigatorKey.currentState!.pushNamed('/list');
      await tester.pumpAndSettle();

      final backFinder = find.byType(BackButton);
      expect(backFinder, findsOneWidget);

      final backBox = tester.renderObject<RenderBox>(backFinder);
      final appBarBox = tester.renderObject<RenderBox>(find.byType(AppBar));
      final backCenter = backBox.localToGlobal(backBox.size.center(Offset.zero));
      final appBarCenter = appBarBox.localToGlobal(appBarBox.size.center(Offset.zero));
      expect(backCenter.dx, greaterThan(appBarCenter.dx));
    });
  });

  group('Responsive D3A', () {
    const widths = [412.0, 390.0, 360.0, 320.0];

    for (final width in widths) {
      testWidgets('EncyclopediaScreen renders without overflow at ${width.toInt()}px', (
        tester,
      ) async {
        tester.binding.setSurfaceSize(Size(width, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await _pumpScreen(tester, const EncyclopediaScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('CategoriesScreen renders without overflow at ${width.toInt()}px', (
        tester,
      ) async {
        tester.binding.setSurfaceSize(Size(width, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await _pumpScreen(tester, const CategoriesScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('TopicListScreen renders without overflow at ${width.toInt()}px', (
        tester,
      ) async {
        final provider = _providerWithTopics();
        tester.binding.setSurfaceSize(Size(width, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await _pumpScreen(
          tester,
          const TopicListScreen(categoryId: 'concrete'),
          provider: provider,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
