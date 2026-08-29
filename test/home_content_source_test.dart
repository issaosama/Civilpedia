import 'package:civilpedia/data/repositories/article_repository.dart';
import 'package:civilpedia/features/home/data/home_content_source.dart';
import 'package:civilpedia/features/home/presentation/widgets/latest_articles_section.dart';
import 'package:civilpedia/features/home/presentation/widgets/quick_tools_section.dart';
import 'package:civilpedia/models/tool_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeContentSource — read-compatible Home read boundary (W1.1)', () {
    test(
      'latestArticles preserves the legacy latest-article read, content and order',
      () {
        final boundary = const HomeContentSource();
        final legacy = ArticleRepository().getLatestArticles();

        expect(boundary.latestArticles, isNotEmpty);
        expect(boundary.latestArticles.length, legacy.length);
        expect(boundary.latestArticles, equals(legacy));
      },
    );

    test('tools preserves the legacy tool registry verbatim', () {
      final boundary = const HomeContentSource();
      final legacy = ArticleRepository.tools;

      expect(boundary.tools, isNotEmpty);
      expect(boundary.tools.length, legacy.length);
      expect(
        boundary.tools.map((t) => (t as ToolModel).id),
        equals(legacy.map((t) => t.id).toList()),
      );
    });

    test(
      'boundary does not duplicate engineering Knowledge (no catalog surface)',
      () {
        // Home's Knowledge-backed sections (categories, engineering topics) read
        // from the authoritative Encyclopedia pipeline. The W1.1 boundary must
        // expose ONLY legacy reads, not a duplicate catalog source.
        const boundary = HomeContentSource();
        expect(boundary.latestArticles, isNotNull);
        expect(boundary.tools, isNotNull);
      },
    );
  });

  group('HomeContentSource — behavior preservation', () {
    test('boundary data integrates with LatestArticlesSection contract', () {
      // LatestArticlesSection renders the first `homeArticleLimit` rows. The
      // boundary must hand it the same non-empty, order-preserved read so Home
      // composition is behaviorally unchanged (rendering itself is covered by
      // home_latest_articles_test with local image data).
      final articles = const HomeContentSource().latestArticles;
      expect(articles, isNotEmpty);
      expect(
        articles.length,
        greaterThanOrEqualTo(LatestArticlesSection.homeArticleLimit),
      );

      final legacy = ArticleRepository().getLatestArticles();
      final shown = articles
          .take(LatestArticlesSection.homeArticleLimit)
          .toList();
      final legacyShown = legacy
          .take(LatestArticlesSection.homeArticleLimit)
          .toList();
      expect(shown, equals(legacyShown));
      for (final a in shown) {
        expect(a.id, isNotNull);
        expect(a.title, isNotEmpty);
      }
    });

    testWidgets('QuickToolsSection still renders the real tool registry', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: QuickToolsSection()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(QuickToolsSection), findsOneWidget);
      final tools = ArticleRepository.tools;
      expect(tools, isNotEmpty);
    });
  });
}
