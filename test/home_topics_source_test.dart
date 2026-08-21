import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/home/presentation/widgets/engineering_topics_section.dart';
import 'package:civilpedia/features/home/presentation/widgets/home_topic_card.dart';
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

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  final List<EngineeringTopic> topics;
  _FakeEncyclopediaRepository({required this.topics});

  @override
  Future<List<EngineeringTopic>> getAllTopics() async => topics;

  @override
  Future<EngineeringTopic?> getTopicById(String id) async => null;

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async =>
      topics.where((t) => t.categoryId == categoryId).toList();

  @override
  Future<Map<String, CategoryInfo>> getCategories() async => const {};

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

void main() {
  group('EngineeringTopicsSection topic source', () {
    testWidgets('uses allTopics, not the active search-filtered topics',
        (tester) async {
      final repo = _FakeEncyclopediaRepository(
        topics: [
          _topic('t1', 'فحص الخرسانة'),
          _topic('t2', 'حديد التسليح'),
          _topic('t3', 'خلط الخرسانة'),
        ],
      );
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadAllTopics();

      // Activate a search that would shrink provider.topics to a subset.
      provider.searchTopics('فحص');
      expect(provider.topics.length, 1);
      expect(provider.allTopics.length, 3);

      await tester.pumpWidget(
        ChangeNotifierProvider<EncyclopediaProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EngineeringTopicsSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Home discovery reflects the unfiltered authoritative collection, capped
      // at [EngineeringTopicsSection.homeTopicLimit].
      expect(find.byType(HomeTopicCard), findsNWidgets(2));
    });
  });
}
