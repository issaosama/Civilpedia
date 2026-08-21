import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/home/presentation/widgets/categories_section.dart';
import 'package:civilpedia/features/home/presentation/widgets/engineering_topics_section.dart';
import 'package:civilpedia/features/home/presentation/widgets/quick_access_section.dart';
import 'package:civilpedia/features/home/presentation/widgets/quick_tools_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  @override
  Future<List<EngineeringTopic>> getAllTopics() async => [
        EngineeringTopic(
          id: 't1',
          titleAr: 'فحص الخرسانة',
          categoryId: 'concrete',
          summary: 'ملخص',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
          tags: const [],
          keyTopics: const [],
        ),
        EngineeringTopic(
          id: 't2',
          titleAr: 'حديد التسليح',
          categoryId: 'steel',
          summary: 'ملخص',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
          tags: const [],
          keyTopics: const [],
        ),
      ];

  @override
  Future<EngineeringTopic?> getTopicById(String id) async => null;

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async => [];

  @override
  Future<Map<String, CategoryInfo>> getCategories() async => {
        'concrete': const CategoryInfo(id: 'concrete', titleAr: 'الخرسانة', titleEn: 'Concrete'),
        'steel': const CategoryInfo(id: 'steel', titleAr: 'الحديد', titleEn: 'Steel'),
        'soil': const CategoryInfo(id: 'soil', titleAr: 'التربة', titleEn: 'Soil'),
        'roads': const CategoryInfo(id: 'roads', titleAr: 'الطرق', titleEn: 'Roads'),
        'finishing': const CategoryInfo(id: 'finishing', titleAr: 'التشطيبات', titleEn: 'Finishing'),
      };

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async => const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async => const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => [];
}

void main() {
  group('Home scroll stress test', () {
    testWidgets('scrolls a Home-like feed without layout exceptions', (tester) async {
      final provider = EncyclopediaProvider(repository: _FakeEncyclopediaRepository());
      await provider.loadAllTopics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<EncyclopediaProvider>.value(
              value: provider,
              child: const SizedBox(
                height: 300,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      QuickAccessSection(),
                      QuickToolsSection(),
                      CategoriesSection(),
                      EngineeringTopicsSection(),
                      SizedBox(height: 400), // force scrollability
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, -300), 1000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
