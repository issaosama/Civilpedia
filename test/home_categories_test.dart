import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/screens/categories_screen.dart';
import 'package:civilpedia/features/home/presentation/widgets/categories_section.dart';

/// Authoritative categories that intentionally do NOT match the legacy
/// ArticleRepository category names, proving Home reads from the provider.
final Map<String, CategoryInfo> _realCategories = {
  'concrete': const CategoryInfo(
    id: 'concrete',
    titleAr: 'الخرسانة الحقيقية',
    titleEn: 'Concrete',
  ),
  'finishing': const CategoryInfo(
    id: 'finishing',
    titleAr: 'أعمال الإنهاءات الحقيقية',
    titleEn: 'Finishing',
  ),
  'fundamentals': const CategoryInfo(
    id: 'fundamentals',
    titleAr: 'أساسيات الهندسة الحقيقية',
    titleEn: 'Engineering Fundamentals',
  ),
};

final List<EngineeringTopic> _realTopics = [
  EngineeringTopic(
    id: 't-concrete-1',
    titleAr: 'موضوع خرسانة',
    categoryId: 'concrete',
    summary: 'ملخص',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  ),
];

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  @override
  Future<Map<String, CategoryInfo>> getCategories() async => _realCategories;

  @override
  Future<List<EngineeringTopic>> getAllTopics() async => _realTopics;

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async =>
      _realTopics.where((t) => t.categoryId == categoryId).toList();

  @override
  Future<EngineeringTopic?> getTopicById(String id) async {
    try {
      return _realTopics.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async => const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async =>
      const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => [];
}

Future<EncyclopediaProvider> _createLoadedProvider() async {
  final provider = EncyclopediaProvider(
    repository: _FakeEncyclopediaRepository(),
  );
  await provider.loadAllTopics();
  return provider;
}

void main() {
  group('Home CategoriesSection authoritative source', () {
    testWidgets('renders real encyclopedia categories, not legacy names',
        (tester) async {
      final provider = await _createLoadedProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(body: CategoriesSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الخرسانة الحقيقية'), findsOneWidget);
      expect(find.text('أعمال الإنهاءات الحقيقية'), findsOneWidget);
      expect(find.text('أساسيات الهندسة الحقيقية'), findsOneWidget);

      // Legacy names must NOT appear.
      expect(find.text('خرسانة'), findsNothing);
      expect(find.text('حديد'), findsNothing);
      expect(find.text('تربة'), findsNothing);
    });

    testWidgets('tapping a category routes to /encyclopedia/topics/:id',
        (tester) async {
      final provider = await _createLoadedProvider();

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: CategoriesSection()),
          ),
          GoRoute(
            path: '/encyclopedia/topics/:categoryId',
            builder: (_, state) => Text(
              'topic-list-${state.pathParameters['categoryId']}',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('الخرسانة الحقيقية'));
      await tester.pumpAndSettle();

      expect(find.text('topic-list-concrete'), findsOneWidget);
    });

    testWidgets('category journey reaches topic detail via shared routes',
        (tester) async {
      final provider = await _createLoadedProvider();

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: CategoriesSection()),
          ),
          GoRoute(
            path: '/encyclopedia/topics/:categoryId',
            builder: (context, state) => ElevatedButton(
              onPressed: () => context.push('/encyclopedia/topic/t-concrete-1'),
              child: const Text('open topic'),
            ),
          ),
          GoRoute(
            path: '/encyclopedia/topic/:topicId',
            builder: (_, state) => Text(
              'topic-detail-${state.pathParameters['topicId']}',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('الخرسانة الحقيقية'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open topic'));
      await tester.pumpAndSettle();

      expect(find.text('topic-detail-t-concrete-1'), findsOneWidget);
    });
  });

  group('View All categories screen', () {
    testWidgets('CategoriesScreen renders authoritative encyclopedia categories',
        (tester) async {
      final provider = await _createLoadedProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: CategoriesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الخرسانة الحقيقية'), findsOneWidget);
      expect(find.text('أعمال الإنهاءات الحقيقية'), findsOneWidget);
      expect(find.text('أساسيات الهندسة الحقيقية'), findsOneWidget);

      expect(find.text('خرسانة'), findsNothing);
      expect(find.text('حديد'), findsNothing);
    });

    testWidgets('CategoriesScreen tap routes to /encyclopedia/topics/:id',
        (tester) async {
      final provider = await _createLoadedProvider();

      final router = GoRouter(
        initialLocation: '/categories',
        routes: [
          GoRoute(
            path: '/categories',
            builder: (_, __) => const CategoriesScreen(),
          ),
          GoRoute(
            path: '/encyclopedia/topics/:categoryId',
            builder: (_, state) => Text(
              'topic-list-${state.pathParameters['categoryId']}',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('الخرسانة الحقيقية'));
      await tester.pumpAndSettle();

      expect(find.text('topic-list-concrete'), findsOneWidget);
    });
  });
}
