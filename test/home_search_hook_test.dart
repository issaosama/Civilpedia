import 'package:civilpedia/core/widgets/search_bar_widget.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/screens/encyclopedia_screen.dart';
import 'package:civilpedia/features/home/presentation/home_main_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

EngineeringTopic _topic(
  String id,
  String title, {
  List<String> tags = const [],
  List<String> keyTopics = const [],
}) => EngineeringTopic(
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
/// [SearchBarWidget] and the W1.2 semantic entry [openHomeSearch]. This asserts
/// Home uses the semantic hook, not an Encyclopedia-specific helper.
class _SearchHarness extends StatelessWidget {
  const _SearchHarness();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SearchBarWidget(
            hintText: Ar.homeEngineeringSearchHint,
            onSubmitted: (query) => openHomeSearch(context, query),
          ),
        ),
      ),
    );
  }
}

/// Mirrors the production `/encyclopedia` route mapping. There is deliberately
/// NO `/search` route in W1.2, so after submission the resolved location must be
/// `/encyclopedia` (never `/search`).
GoRouter _searchRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _SearchHarness()),
      GoRoute(
        path: '/encyclopedia',
        builder: (_, state) =>
            EncyclopediaScreen(initialQuery: state.uri.queryParameters['q']),
      ),
    ],
  );
}

/// Resolves the current location of the router in [tester].
String _currentPath(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(EncyclopediaScreen))).state.uri.path;

void main() {
  group('W1.2 openHomeSearch — semantic Home search entry', () {
    testWidgets(
      'valid query reaches /encyclopedia?q= and Encyclopedia applies it',
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

        // Landed on Encyclopedia (the current active search authority), not /search.
        expect(find.byType(EncyclopediaScreen), findsOneWidget);
        // Trimmed query applied via ?q=.
        expect(provider.currentSearchQuery, 'فحص الخرسانة');
        // Resolved to /encyclopedia — the (non-existent) /search route was NOT used.
        expect(_currentPath(tester), '/encyclopedia');
      },
    );

    testWidgets('query encoding is preserved through the hook', (tester) async {
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

      // A query containing a space must be URL-encoded into /encyclopedia?q=.
      await tester.enterText(find.byType(TextField), 'فحص الخرسانة');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.byType(EncyclopediaScreen), findsOneWidget);
      expect(provider.currentSearchQuery, 'فحص الخرسانة');
      // The underlying URI carried the encoded query on /encyclopedia.
      expect(_currentPath(tester), '/encyclopedia');
      expect(
        GoRouter.of(
          tester.element(find.byType(EncyclopediaScreen)),
        ).state.uri.queryParameters['q'],
        'فحص الخرسانة',
      );
    });

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

    testWidgets('Encyclopedia remains the active search authority', (
      tester,
    ) async {
      final provider = _CountingProvider(
        repository: _FakeEncyclopediaRepository(_catalog()),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<EncyclopediaProvider>.value(
          value: provider,
          child: MaterialApp.router(routerConfig: _searchRouter()),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'خرسانة');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Encyclopedia screen performed the lookup once.
      expect(provider.searchCalls, 1);
      expect(provider.currentSearchQuery, 'خرسانة');
      expect(_currentPath(tester), '/encyclopedia');
    });
  });
}
