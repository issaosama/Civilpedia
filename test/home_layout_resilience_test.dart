import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/home/presentation/widgets/categories_section.dart';
import 'package:civilpedia/features/home/presentation/widgets/quick_access_section.dart';
import 'package:civilpedia/features/home/presentation/widgets/quick_tools_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  @override
  Future<List<EngineeringTopic>> getAllTopics() async => [];

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

Widget _narrowSurface({required Widget child}) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: MediaQuery(
      data: const MediaQueryData(size: Size(320, 600)),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Home layout resilience on narrow screens', () {
    testWidgets('QuickAccessSection does not overflow at 320 logical px', (tester) async {
      await tester.pumpWidget(_narrowSurface(child: const QuickAccessSection()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('QuickToolsSection does not overflow at 320 logical px', (tester) async {
      await tester.pumpWidget(_narrowSurface(child: const QuickToolsSection()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('CategoriesSection does not overflow at 320 logical px', (tester) async {
      final provider = EncyclopediaProvider(repository: _FakeEncyclopediaRepository());
      await provider.loadAllTopics();
      await tester.pumpWidget(
        _narrowSurface(
          child: ChangeNotifierProvider<EncyclopediaProvider>.value(
            value: provider,
            child: const CategoriesSection(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
