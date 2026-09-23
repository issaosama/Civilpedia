import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/home/presentation/widgets/categories_section.dart';
import 'package:civilpedia/features/home/presentation/widgets/engineering_directory_section.dart';
import 'package:civilpedia/features/home/presentation/widgets/quick_access_section.dart';
import 'package:civilpedia/features/home/presentation/widgets/quick_tools_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  @override
  Future<List<EngineeringTopic>> getAllTopics() async => [];

  @override
  Future<EngineeringTopic?> getTopicById(String id) async => null;

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async =>
      [];

  @override
  Future<Map<String, CategoryInfo>> getCategories() async => {
    'concrete': const CategoryInfo(
      id: 'concrete',
      titleAr: 'الخرسانة',
      titleEn: 'Concrete',
    ),
    'steel': const CategoryInfo(
      id: 'steel',
      titleAr: 'الحديد',
      titleEn: 'Steel',
    ),
    'soil': const CategoryInfo(id: 'soil', titleAr: 'التربة', titleEn: 'Soil'),
    'roads': const CategoryInfo(
      id: 'roads',
      titleAr: 'الطرق',
      titleEn: 'Roads',
    ),
    'finishing': const CategoryInfo(
      id: 'finishing',
      titleAr: 'التشطيبات',
      titleEn: 'Finishing',
    ),
  };

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async =>
      const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async => const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => [];
}

Widget _surface({
  required Widget child,
  double width = 320,
  Locale locale = const Locale('ar'),
  ThemeData? theme,
  double textScale = 1.3,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: theme ?? ThemeData.dark(),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          height: 600,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 600),
              textScaler: TextScaler.linear(textScale),
            ),
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('normal phone shows four preview cards per row', (tester) async {
    for (final section in <Widget>[
      const QuickAccessSection(),
      const QuickToolsSection(),
      const EngineeringDirectorySection(),
    ]) {
      await tester.pumpWidget(
        _surface(width: 390, textScale: 1, child: section),
      );
      await tester.pumpAndSettle();
      final wrap = tester.widget<Wrap>(find.byType(Wrap).first);
      expect(wrap.children.length, 4);
      final first = tester.getTopLeft(find.byWidget(wrap.children.first));
      final last = tester.getTopLeft(find.byWidget(wrap.children.last));
      expect(last.dy, first.dy);
      expect(tester.takeException(), isNull);
    }
  });

  group('Home layout resilience on narrow screens', () {
    testWidgets('QuickAccessSection does not overflow at 320 logical px', (
      tester,
    ) async {
      await tester.pumpWidget(_surface(child: const QuickAccessSection()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('QuickToolsSection does not overflow at 320 logical px', (
      tester,
    ) async {
      await tester.pumpWidget(_surface(child: const QuickToolsSection()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('CategoriesSection does not overflow at 320 logical px', (
      tester,
    ) async {
      final provider = EncyclopediaProvider(
        repository: _FakeEncyclopediaRepository(),
      );
      await provider.loadAllTopics();
      await tester.pumpWidget(
        _surface(
          child: ChangeNotifierProvider<EncyclopediaProvider>.value(
            value: provider,
            child: const CategoriesSection(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'EngineeringDirectorySection does not overflow at 320 logical px',
      (tester) async {
        await tester.pumpWidget(
          _surface(child: const EngineeringDirectorySection()),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('English LTR flexible cards render at 1.3x text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _surface(
          locale: const Locale('en'),
          theme: ThemeData.light(),
          child: const Column(
            children: [QuickAccessSection(), QuickToolsSection()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Engineering Knowledge'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('Engineering Knowledge'))),
        TextDirection.ltr,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('wider layout remains bounded without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _surface(
          width: 1000,
          child: const Column(
            children: [QuickAccessSection(), QuickToolsSection()],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
