import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/data/local/hive_helper.dart';
import 'package:civilpedia/features/articles/presentation/screens/article_details_screen.dart';
import 'package:civilpedia/features/articles/presentation/widgets/article_image.dart';
import 'package:civilpedia/models/article_model.dart';

Widget _articleImage(String url, {double? width, double? height}) {
  return MaterialApp(
    home: Scaffold(
      body: ArticleImage(
        imageUrl: url,
        width: width,
        height: height,
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(widget);
}

void main() {
  group('ArticleImage', () {
    testWidgets('renders CachedNetworkImage for non-empty URL',
        (tester) async {
      await _pump(
        tester,
        _articleImage('https://example.com/img.jpg', width: 100, height: 100),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, 'https://example.com/img.jpg');
      expect(image.width, 100);
      expect(image.height, 100);
      expect(image.fit, BoxFit.cover);
    });

    testWidgets('empty URL shows local fallback immediately', (tester) async {
      await _pump(
        tester,
        _articleImage('', width: 100, height: 100),
      );

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('whitespace-only URL shows local fallback immediately',
        (tester) async {
      await _pump(
        tester,
        _articleImage('   ', width: 100, height: 100),
      );

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });

    testWidgets('image load failure uses local fallback', (tester) async {
      await _pump(
        tester,
        _articleImage('https://example.com/img.jpg', width: 100, height: 100),
      );

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final errorWidget = image.errorWidget!(
        tester.element(find.byType(CachedNetworkImage)),
        '',
        Exception('load failed'),
      );

      expect(errorWidget, isA<Container>());
      final container = errorWidget as Container;
      final center = container.child as Center;
      final icon = center.child as Icon;
      expect(icon.icon, Icons.article_outlined);
    });

    testWidgets('loading state renders safely', (tester) async {
      await _pump(
        tester,
        _articleImage('https://example.com/img.jpg', width: 100, height: 100),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fallback preserves requested dimensions', (tester) async {
      await _pump(
        tester,
        _articleImage('', width: 100, height: 80),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byIcon(Icons.article_outlined),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.constraints?.minWidth, 100);
      expect(container.constraints?.maxWidth, 100);
      expect(container.constraints?.minHeight, 80);
      expect(container.constraints?.maxHeight, 80);
    });

    testWidgets('narrow phone renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _articleImage('https://example.com/img.jpg', width: 60, height: 60),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('dark mode renders without exception', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ArticleImage(
              imageUrl: '',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ArticleDetailsScreen offline image', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('article_image_test');
      await HiveHelper.init(path: tempDir.path);
      await HiveHelper.toggleDownload(
        'offline-img-article',
        const ArticleModel(
          id: 'offline-img-article',
          title: 'Article Without Image',
          image: '   ',
          category: 'اختبار',
          content:
              'محتوى مقال تجريبي يجب أن يظهر حتى عندما لا تكون الصورة متوفرة.',
        ),
      );
    });

    tearDownAll(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    testWidgets('remains renderable when image cannot load', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: const MaterialApp(
            home: ArticleDetailsScreen(articleId: 'offline-img-article'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Article Without Image'), findsOneWidget);
      expect(
        find.text(
          'محتوى مقال تجريبي يجب أن يظهر حتى عندما لا تكون الصورة متوفرة.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
