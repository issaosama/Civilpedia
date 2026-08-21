import 'package:civilpedia/core/widgets/custom_card.dart';
import 'package:civilpedia/features/home/presentation/widgets/latest_articles_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeArticle {
  final String id;
  final String title;
  final String category;
  final String image;

  const _FakeArticle({
    required this.id,
    required this.title,
    required this.category,
    this.image = '',
  });
}

GoRouter _articlesRouter(List<_FakeArticle> articles) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: LatestArticlesSection(articles: articles),
        ),
      ),
      GoRoute(
        path: '/article/:id',
        builder: (_, state) => Text('Article ${state.pathParameters['id']}'),
      ),
    ],
  );
}

void main() {
  group('LatestArticlesSection', () {
    const articles = [
      _FakeArticle(id: 'a1', title: 'أول مقال', category: 'خرسانة', image: ''),
      _FakeArticle(id: 'a2', title: 'ثاني مقال', category: 'حديد', image: ''),
      _FakeArticle(id: 'a3', title: 'ثالث مقال', category: 'تشطيبات', image: ''),
      _FakeArticle(id: 'a4', title: 'رابع مقال', category: 'طرق', image: ''),
    ];

    testWidgets('renders up to homeArticleLimit rows', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: _articlesRouter(articles)),
      );
      await tester.pumpAndSettle();

      expect(find.text('أول مقال'), findsOneWidget);
      expect(find.text('ثاني مقال'), findsOneWidget);
      expect(find.text('ثالث مقال'), findsOneWidget);
      expect(find.text('رابع مقال'), findsNothing);

      expect(find.text('خرسانة'), findsOneWidget);
      expect(find.text('حديد'), findsOneWidget);
      expect(find.text('تشطيبات'), findsOneWidget);
    });

    testWidgets('tapping a row navigates to /article/:id', (tester) async {
      final router = _articlesRouter(articles);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('أول مقال'));
      await tester.pumpAndSettle();

      expect(find.text('Article a1'), findsOneWidget);
    });

    testWidgets('renders nothing when the article list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: _articlesRouter(const [])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LatestArticlesSection), findsOneWidget);
      expect(find.byType(CustomCard), findsNothing);
    });
  });
}
