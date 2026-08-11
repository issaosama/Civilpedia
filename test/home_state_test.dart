import 'dart:async';

import 'package:civilpedia/core/widgets/shimmer_loading.dart';
import 'package:civilpedia/core/widgets/state_widgets.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/topic_compact_card.dart';
import 'package:civilpedia/features/home/presentation/home_main_screen.dart';
import 'package:civilpedia/features/home/presentation/widgets/home_data_section.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

EngineeringTopic _topic(String id, String title) => EngineeringTopic(
  id: id,
  titleAr: title,
  categoryId: 'cat1',
  summary: 'ملخص $title',
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
  tags: const [],
  keyTopics: const [],
);

List<EngineeringTopic> _catalog() => [
  _topic('t1', 'فحص الخرسانة'),
  _topic('t2', 'خلط الخرسانة'),
  _topic('t3', 'حديد التسليح'),
];

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  List<EngineeringTopic> topics;
  Duration delay;
  Object? error;
  int getAllTopicsCalls = 0;

  _FakeEncyclopediaRepository({
    required this.topics,
    this.delay = Duration.zero,
    this.error,
  });

  @override
  Future<List<EngineeringTopic>> getAllTopics() async {
    getAllTopicsCalls++;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (error != null) throw error!;
    return topics;
  }

  @override
  Future<EngineeringTopic?> getTopicById(String id) async {
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async =>
      topics.where((t) => t.categoryId == categoryId).toList();

  @override
  Future<Map<String, CategoryInfo>> getCategories() async => const {};

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async => const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(String topicId, String sectionId) async =>
      const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => topics;
}

Widget _wrap(EncyclopediaProvider provider) {
  return ChangeNotifierProvider<EncyclopediaProvider>.value(
    value: provider,
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: HomeDataSection()),
      ),
    ),
  );
}

/// Ends the test by advancing past any entrance-animation timers
/// (AnimatedListItem) and unmounting the tree so pending timers are disposed
/// before the fake-async teardown check.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  group('Home initial load states', () {
    testWidgets('shows a real loading shimmer, then content once loaded', (tester) async {
      final repo = _FakeEncyclopediaRepository(
        topics: _catalog(),
        delay: const Duration(milliseconds: 200),
      );
      final provider = EncyclopediaProvider(repository: repo);

      await tester.pumpWidget(_wrap(provider));
      // First frame: no data and no completed load yet → loading treatment,
      // never the empty state.
      expect(find.byType(ShimmerSection), findsOneWidget);
      expect(find.byType(EmptyStateWidget), findsNothing);

      await tester.pump();

      expect(repo.getAllTopicsCalls, 1);
      expect(find.byType(ShimmerSection), findsOneWidget);
      expect(find.byType(TopicCompactCard), findsNothing);
      expect(find.byType(ErrorStateWidget), findsNothing);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.byType(ShimmerSection), findsNothing);
      expect(find.byType(TopicCompactCard), findsWidgets);
      await _unmount(tester);
    });

    testWidgets('never shows the empty state before the initial load completes', (tester) async {
      final repo = _FakeEncyclopediaRepository(
        topics: const [],
        delay: const Duration(milliseconds: 200),
      );
      final provider = EncyclopediaProvider(repository: repo);

      await tester.pumpWidget(_wrap(provider));
      expect(find.byType(ShimmerSection), findsOneWidget);
      expect(find.byType(EmptyStateWidget), findsNothing);

      await tester.pump();
      expect(repo.getAllTopicsCalls, 1);
      expect(find.byType(ShimmerSection), findsOneWidget);
      expect(find.byType(EmptyStateWidget), findsNothing);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      // Only a completed real load may reveal the empty catalog.
      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.byType(ShimmerSection), findsNothing);
      await _unmount(tester);
    });

    testWidgets('does not re-trigger a load when topics are already loaded', (tester) async {
      final repo = _FakeEncyclopediaRepository(topics: _catalog());
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadAllTopics();
      expect(repo.getAllTopicsCalls, 1);

      await tester.pumpWidget(_wrap(provider));
      await tester.pump();
      await tester.pump();

      expect(repo.getAllTopicsCalls, 1);
      expect(find.byType(TopicCompactCard), findsWidgets);
      expect(find.byType(ShimmerSection), findsNothing);
      await _unmount(tester);
    });

    testWidgets('shows a retryable error state when the initial load fails', (tester) async {
      final repo = _FakeEncyclopediaRepository(
        topics: _catalog(),
        error: StateError('catalog unavailable'),
      );
      final provider = EncyclopediaProvider(repository: repo);

      await tester.pumpWidget(_wrap(provider));
      await tester.pump();
      await tester.pump();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text(Ar.errorOccurred), findsOneWidget);
      expect(find.text(Ar.retry), findsOneWidget);
      expect(find.byType(ShimmerSection), findsNothing);
      await _unmount(tester);
    });

    testWidgets('retry after failure triggers a real reload and recovers', (tester) async {
      final repo = _FakeEncyclopediaRepository(
        topics: _catalog(),
        delay: const Duration(milliseconds: 100),
        error: StateError('catalog unavailable'),
      );
      final provider = EncyclopediaProvider(repository: repo);

      await tester.pumpWidget(_wrap(provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.byType(ErrorStateWidget), findsOneWidget);

      repo.error = null;
      await tester.tap(find.text(Ar.retry));
      await tester.pump();

      expect(repo.getAllTopicsCalls, 2);
      expect(find.byType(ShimmerSection), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.byType(TopicCompactCard), findsWidgets);
      await _unmount(tester);
    });

    testWidgets('shows an empty state when the catalog loads with no topics', (tester) async {
      final provider = EncyclopediaProvider(
        repository: _FakeEncyclopediaRepository(topics: const []),
      );

      await tester.pumpWidget(_wrap(provider));
      await tester.pump();
      await tester.pump();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.byType(TopicCompactCard), findsNothing);
      expect(find.byType(ErrorStateWidget), findsNothing);
      await _unmount(tester);
    });
  });

  group('Refresh behavior', () {
    testWidgets('refreshHomeData triggers a real reload and waits for completion', (tester) async {
      final repo = _FakeEncyclopediaRepository(topics: _catalog());
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadAllTopics();
      expect(repo.getAllTopicsCalls, 1);

      repo.delay = const Duration(milliseconds: 200);

      BuildContext? ctx;
      await tester.pumpWidget(
        ChangeNotifierProvider<EncyclopediaProvider>.value(
          value: provider,
          child: Builder(builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          }),
        ),
      );

      final refresh = refreshHomeData(ctx!);
      expect(repo.getAllTopicsCalls, 2);
      expect(provider.isLoading, isTrue);

      var completed = false;
      refresh.whenComplete(() => completed = true);

      await tester.pump(const Duration(milliseconds: 100));
      expect(completed, isFalse);

      await tester.pump(const Duration(milliseconds: 100));
      await refresh;

      expect(completed, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.allTopics.length, _catalog().length);
      await _unmount(tester);
    });

    testWidgets('keeps showing content while a background refresh is running', (tester) async {
      final repo = _FakeEncyclopediaRepository(topics: _catalog());
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadAllTopics();

      await tester.pumpWidget(_wrap(provider));
      await tester.pump();
      expect(find.byType(TopicCompactCard), findsWidgets);

      repo.delay = const Duration(milliseconds: 300);
      unawaited(provider.loadAllTopics());
      await tester.pump();

      expect(provider.isLoading, isTrue);
      expect(provider.allTopics, isNotEmpty);
      expect(find.byType(ShimmerSection), findsNothing);
      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.byType(TopicCompactCard), findsWidgets);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(provider.isLoading, isFalse);
      expect(find.byType(TopicCompactCard), findsWidgets);
      await _unmount(tester);
    });

    testWidgets('a failed refresh keeps the existing content (no error takeover)', (tester) async {
      final repo = _FakeEncyclopediaRepository(topics: _catalog());
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadAllTopics();

      await tester.pumpWidget(_wrap(provider));
      await tester.pump();
      expect(find.byType(TopicCompactCard), findsWidgets);

      repo.error = StateError('reload failed');
      await provider.loadAllTopics();
      await tester.pump();

      expect(provider.error, isNotNull);
      expect(provider.allTopics, isNotEmpty);
      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.byType(TopicCompactCard), findsWidgets);
      await _unmount(tester);
    });
  });

  group('Duplicate-load protection', () {
    test('concurrent loadAllTopics calls share a single real load', () async {
      final repo = _FakeEncyclopediaRepository(
        topics: _catalog(),
        delay: const Duration(milliseconds: 50),
      );
      final provider = EncyclopediaProvider(repository: repo);

      final f1 = provider.loadAllTopics();
      final f2 = provider.loadAllTopics();
      final f3 = provider.loadAllTopics();

      expect(repo.getAllTopicsCalls, 1);
      await Future.wait([f1, f2, f3]);
      expect(repo.getAllTopicsCalls, 1);
      expect(provider.allTopics.length, _catalog().length);
    });

    test('a later call after completion starts a fresh reload (real refresh)', () async {
      final repo = _FakeEncyclopediaRepository(topics: _catalog());
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadAllTopics();
      expect(repo.getAllTopicsCalls, 1);

      await provider.loadAllTopics();
      expect(repo.getAllTopicsCalls, 2);
    });
  });

  group('Initial-load lifecycle flag', () {
    test('starts uncompleted, then becomes true after a successful empty load', () async {
      final repo = _FakeEncyclopediaRepository(topics: const []);
      final provider = EncyclopediaProvider(repository: repo);

      expect(provider.hasCompletedInitialLoad, isFalse);
      expect(provider.isLoading, isFalse);

      await provider.loadAllTopics();

      expect(provider.hasCompletedInitialLoad, isTrue);
      expect(provider.allTopics, isEmpty);
    });

    test('becomes true even when the initial load fails (never empty before attempt)', () async {
      final repo = _FakeEncyclopediaRepository(
        topics: _catalog(),
        error: StateError('catalog unavailable'),
      );
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadAllTopics();

      expect(provider.hasCompletedInitialLoad, isTrue);
      expect(provider.error, isNotNull);
      expect(provider.allTopics, isEmpty);
    });

    test('stays true across a successful retry after an initial failure', () async {
      final repo = _FakeEncyclopediaRepository(
        topics: _catalog(),
        error: StateError('catalog unavailable'),
      );
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadAllTopics();
      expect(provider.hasCompletedInitialLoad, isTrue);
      expect(provider.error, isNotNull);

      repo.error = null;
      await provider.loadAllTopics();

      expect(provider.hasCompletedInitialLoad, isTrue);
      expect(provider.error, isNull);
      expect(provider.allTopics.length, _catalog().length);
    });
  });
}
