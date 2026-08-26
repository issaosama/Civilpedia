import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/home/presentation/home_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeConnectivityProvider extends ConnectivityProvider {
  _FakeConnectivityProvider() : super();

  @override
  void dispose() {
    // The parent's async _init() has enough time to complete during pump(),
    // so super.dispose() can safely cancel the initialized subscription.
    super.dispose();
  }
}

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  @override
  Future<List<EngineeringTopic>> getAllTopics() async => const [];

  @override
  Future<EngineeringTopic?> getTopicById(String id) async => null;

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async => const [];

  @override
  Future<Map<String, CategoryInfo>> getCategories() async => const {};

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async => const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(String topicId, String sectionId) async => const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => const [];
}

Widget _pumpHome({required ThemeData theme}) {
  final provider = EncyclopediaProvider(repository: _FakeEncyclopediaRepository());
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: provider),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider<ConnectivityProvider>(create: (_) => _FakeConnectivityProvider()),
    ],
    child: MaterialApp(
      theme: theme,
      home: const HomeMainScreen(),
    ),
  );
}

void main() {
  group('HomeMainScreen theme-aware background', () {
    testWidgets('uses light theme scaffold background', (tester) async {
      await tester.pumpWidget(_pumpHome(theme: AppTheme.lightTheme));
      await tester.pump(const Duration(milliseconds: 200));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.scaffoldBackgroundColor, AppTheme.lightTheme.scaffoldBackgroundColor);
    });

    testWidgets('uses dark theme scaffold background', (tester) async {
      await tester.pumpWidget(_pumpHome(theme: AppTheme.darkTheme));
      await tester.pump(const Duration(milliseconds: 200));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.scaffoldBackgroundColor, AppTheme.darkTheme.scaffoldBackgroundColor);
    });
  });
}
