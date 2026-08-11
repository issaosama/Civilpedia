import 'package:civilpedia/core/widgets/search_bar_widget.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/screens/encyclopedia_screen.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/topic_compact_card.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/topic_list_card.dart';
import 'package:civilpedia/features/home/presentation/home_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

EngineeringTopic _topic(
  String id,
  String title, {
  List<String> tags = const [],
  List<String> keyTopics = const [],
}) =>
    EngineeringTopic(
      id: id,
      titleAr: title,
      categoryId: 'cat1',
      summary: 'ملخص $title',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      tags: tags,
      keyTopics: keyTopics,
    );

List<EngineeringTopic> _catalog() => [
      _topic(
        't1',
        'فحص الخرسانة',
        tags: const ['خرسانة'],
        keyTopics: const ['اختبار الضغط'],
      ),
      _topic(
        't2',
        'خلط الخرسانة',
        tags: const ['خرسانة'],
        keyTopics: const ['نسبة الخلط'],
      ),
      _topic(
        't3',
        'حديد التسليح',
        tags: const ['حديد'],
        keyTopics: const ['شد الحديد'],
      ),
    ];

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  final List<EngineeringTopic> topics;
  _FakeEncyclopediaRepository(this.topics);

  @override
  Future<EngineeringTopic?> getTopicById(String id) async {
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  @override
  Future<List<EngineeringTopic>> getAllTopics() async => topics;

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async =>
      topics.where((t) => t.categoryId == categoryId).toList();

  @override
  Future<Map<String, CategoryInfo>> getCategories() async =>
      const <String, CategoryInfo>{};

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async =>
      const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async => const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => topics;
}

class _CountingProvider extends EncyclopediaProvider {
  _CountingProvider({required super.repository});
  int searchCalls = 0;

  @override
  void searchTopics(String query) {
    searchCalls++;
    super.searchTopics(query);
  }
}

/// Mirrors how HomeMainScreen wires its search bar, driven by the real
/// [SearchBarWidget] and the real [openEncyclopediaSearch] navigation helper.
class _SearchHarness extends StatelessWidget {
  const _SearchHarness();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SearchBarWidget(
            onSubmitted: (query) => openEncyclopediaSearch(context, query),
          ),
        ),
      ),
    );
  }
}

/// Mirrors the production `/encyclopedia` route mapping so the test exercises
/// the real query-parameter contract (initialQuery from `?q=`).
GoRouter _searchRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _SearchHarness()),
      GoRoute(
        path: '/encyclopedia',
        builder: (_, state) => EncyclopediaScreen(
          initialQuery: state.uri.queryParameters['q'],
        ),
      ),
    ],
  );
}

Future<EncyclopediaProvider> _pumpEncyclopediaScreen(
  WidgetTester tester, {
  required EncyclopediaProvider provider,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: EncyclopediaScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return provider;
}

void main() {
  group('SearchBarWidget', () {
    testWidgets('delivers submitted text via onSubmitted', (tester) async {
      String? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(onSubmitted: (query) => submitted = query),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'فحص الخرسانة');
      await tester.testTextInput.receiveAction(TextInputAction.search);

      expect(submitted, 'فحص الخرسانة');
    });
  });

  group('Home search navigation contract', () {
    testWidgets(
      'submitting a real query navigates to Encyclopedia with the query applied',
      (tester) async {
        final provider = EncyclopediaProvider(
          repository: _FakeEncyclopediaRepository(_catalog()),
        );

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: provider,
            child: MaterialApp.router(routerConfig: _searchRouter()),
          ),
        );
        await tester.pump();

        await tester.enterText(find.byType(TextField), '  فحص الخرسانة  ');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        expect(find.byType(EncyclopediaScreen), findsOneWidget);
        expect(provider.currentSearchQuery, 'فحص الخرسانة');

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.controller!.text, 'فحص الخرسانة');

        expect(find.byType(TopicListCard), findsOneWidget);
        expect(find.text('خلط الخرسانة'), findsNothing);
        expect(find.text('حديد التسليح'), findsNothing);
      },
    );

    testWidgets('whitespace-only submit does not navigate', (tester) async {
      final provider = EncyclopediaProvider(
        repository: _FakeEncyclopediaRepository(_catalog()),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp.router(routerConfig: _searchRouter()),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.byType(EncyclopediaScreen), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      expect(provider.currentSearchQuery, isNull);
    });
  });

  group('EncyclopediaScreen initial query', () {
    testWidgets('applies the initial query on entry', (tester) async {
      final provider = EncyclopediaProvider(
        repository: _FakeEncyclopediaRepository(_catalog()),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: EncyclopediaScreen(initialQuery: 'خرسانة'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.currentSearchQuery, 'خرسانة');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'خرسانة');

      expect(find.text('فحص الخرسانة'), findsOneWidget);
      expect(find.text('خلط الخرسانة'), findsOneWidget);
      expect(find.text('حديد التسليح'), findsNothing);
    });

    testWidgets('initial query is applied exactly once, not on rebuild', (
      tester,
    ) async {
      final provider = _CountingProvider(
        repository: _FakeEncyclopediaRepository(_catalog()),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<EncyclopediaProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: EncyclopediaScreen(initialQuery: 'خرسانة'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.searchCalls, 1);
      expect(provider.currentSearchQuery, 'خرسانة');

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      provider.notifyListeners();
      await tester.pump();

      expect(provider.searchCalls, 1);
      expect(provider.currentSearchQuery, 'خرسانة');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'خرسانة');
    });

    testWidgets('clearing the field restores normal category content', (
      tester,
    ) async {
      final provider = EncyclopediaProvider(
        repository: _FakeEncyclopediaRepository(_catalog()),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: EncyclopediaScreen(initialQuery: 'خرسانة'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TopicListCard), findsWidgets);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(provider.isSearchActive, isFalse);
      expect(find.byType(TopicListCard), findsNothing);
      expect(find.byType(TopicCompactCard), findsWidgets);
    });

    testWidgets('opens normally without an initial query', (tester) async {
      final provider = EncyclopediaProvider(
        repository: _FakeEncyclopediaRepository(_catalog()),
      );
      await _pumpEncyclopediaScreen(tester, provider: provider);

      expect(provider.currentSearchQuery, isNull);
      expect(find.byType(TopicCompactCard), findsWidgets);
      expect(find.byType(TopicListCard), findsNothing);
    });

    testWidgets('typing in the field still performs the existing search', (
      tester,
    ) async {
      final provider = EncyclopediaProvider(
        repository: _FakeEncyclopediaRepository(_catalog()),
      );
      await _pumpEncyclopediaScreen(tester, provider: provider);

      await tester.enterText(find.byType(TextField), 'حديد');
      await tester.pumpAndSettle();

      expect(provider.currentSearchQuery, 'حديد');
      expect(find.byType(TopicListCard), findsOneWidget);
      expect(find.text('حديد التسليح'), findsOneWidget);
      expect(find.text('خلط الخرسانة'), findsNothing);
    });

    testWidgets('whitespace-only initial query is ignored', (tester) async {
      final provider = EncyclopediaProvider(
        repository: _FakeEncyclopediaRepository(_catalog()),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<EncyclopediaProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: EncyclopediaScreen(initialQuery: '   '),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.currentSearchQuery, isNull);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
      expect(find.byType(TopicCompactCard), findsWidgets);
    });
  });
}
