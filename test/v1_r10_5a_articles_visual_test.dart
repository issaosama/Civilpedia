import 'dart:io';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/core/theme/app_colors.dart';
import 'package:civilpedia/core/widgets/civil_app_bar.dart';
import 'package:civilpedia/core/widgets/civil_surface_card.dart';
import 'package:civilpedia/data/local/hive_helper.dart';
import 'package:civilpedia/data/repositories/article_repository.dart';
import 'package:civilpedia/features/articles/presentation/screens/all_articles_screen.dart';
import 'package:civilpedia/features/articles/presentation/screens/article_details_screen.dart';
import 'package:civilpedia/features/articles/presentation/screens/articles_screen.dart';
import 'package:civilpedia/features/articles/presentation/widgets/article_image.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

const _boxName = 'v1_r10_5a_articles_visual_box';

GoRouter _listRouter(Widget home) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => home),
      GoRoute(
        path: '/article/:id',
        builder: (_, state) =>
            Scaffold(body: Text('detail:${state.pathParameters['id']}')),
      ),
    ],
  );
}

Widget _localizedApp({
  required Widget home,
  Locale locale = const Locale('ar'),
  ThemeData? theme,
  bool isArabic = true,
}) {
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(isArabic: isArabic),
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: theme,
      home: home,
    ),
  );
}

Widget _localizedRouter({
  required GoRouter router,
  Locale locale = const Locale('ar'),
  ThemeData? theme,
}) {
  return MaterialApp.router(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: theme,
    routerConfig: router,
  );
}

Future<void> _seedImageFreeOfflineArticle() async {
  final article = ArticleRepository.articles.first;
  final json = article.toJson()..['image'] = '';
  final box = Hive.box(_boxName);
  await box.put(AppStorageKeys.offlineArticle(article.id), json);
  await box.put(AppStorageKeys.downloads, const <String>[]);
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('civilpedia_r10_5a');
    await HiveHelper.init(path: tempDir.path, boxName: _boxName);
  });

  setUp(() async {
    await Hive.box(_boxName).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('category Article list preserves rows and canonical navigation', (
    tester,
  ) async {
    final router = _listRouter(const ArticlesScreen(category: 'خرسانة'));
    await tester.pumpWidget(_localizedRouter(router: router));
    await tester.pump();

    expect(find.byType(CivilAppBar), findsOneWidget);
    expect(find.byType(CivilSurfaceCard), findsNWidgets(3));
    expect(find.text('أنواع الخرسانة المسلحة'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsNWidgets(3));
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    await tester.tap(find.text('أنواع الخرسانة المسلحة'));
    await tester.pumpAndSettle();
    expect(find.text('detail:1'), findsOneWidget);
  });

  testWidgets('All Articles keeps order, English LTR, dark tokens and width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = _listRouter(const AllArticlesScreen());
    await tester.pumpWidget(
      _localizedRouter(
        router: router,
        locale: const Locale('en'),
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.darkBackground,
        ),
      ),
    );
    await tester.pump();

    expect(find.text(En.allArticles), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsWidgets);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(
      tester.getTopLeft(find.text(ArticleRepository.articles[0].title)).dy,
      lessThan(
        tester.getTopLeft(find.text(ArticleRepository.articles[1].title)).dy,
      ),
    );
    expect(
      tester.getSize(find.byType(CivilSurfaceCard).first).width,
      lessThanOrEqualTo(760),
    );
    final categoryText = tester.widget<Text>(find.text('خرسانة').first);
    expect(categoryText.style?.color, AppColors.darkBrandAmber);

    await tester.tap(find.text(ArticleRepository.articles[0].title));
    await tester.pumpAndSettle();
    expect(find.text('detail:1'), findsOneWidget);
  });

  testWidgets('Article detail keeps exact content and existing actions', (
    tester,
  ) async {
    final article = ArticleRepository.articles.first;
    await tester.runAsync(_seedImageFreeOfflineArticle);
    await tester.pumpWidget(
      _localizedApp(
        home: const ArticleDetailsScreen(articleId: '1'),
        locale: const Locale('en'),
        isArabic: false,
      ),
    );
    await tester.pump();

    expect(find.byType(CivilAppBar), findsOneWidget);
    expect(find.text(En.articleDetails), findsNothing);
    expect(find.text(Ar.articleDetails), findsNothing);
    expect(find.byType(ArticleImage), findsOneWidget);
    expect(find.byType(Hero), findsOneWidget);
    expect(find.text(article.category), findsOneWidget);
    expect(find.text(article.title), findsOneWidget);
    expect(find.text(article.content), findsOneWidget);
    expect(find.byTooltip(En.addToFavorites), findsOneWidget);
    expect(find.byTooltip(En.download), findsOneWidget);
    expect(find.textContaining('reading'), findsNothing);
    expect(find.textContaining('author'), findsNothing);
    expect(find.textContaining('updated'), findsNothing);

    for (final button in tester.widgetList<IconButton>(
      find.byType(IconButton),
    )) {
      final size = tester.getSize(find.byWidget(button));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }

    final title = tester.widget<Text>(find.text(article.title));
    final body = tester.widget<Text>(find.text(article.content));
    expect(title.style!.fontSize, greaterThan(body.style!.fontSize!));

    final favoriteAction = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(En.addToFavorites),
        matching: find.byType(IconButton),
      ),
    );
    final downloadAction = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(En.download),
        matching: find.byType(IconButton),
      ),
    );
    expect(favoriteAction.onPressed, isNotNull);
    expect(downloadAction.onPressed, isNotNull);
  });

  testWidgets('Article detail is RTL-safe and uses dark category treatment', (
    tester,
  ) async {
    await tester.runAsync(_seedImageFreeOfflineArticle);
    await tester.pumpWidget(
      _localizedApp(
        home: const ArticleDetailsScreen(articleId: '1'),
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.darkBackground,
        ),
      ),
    );
    await tester.pump();

    expect(
      Directionality.of(tester.element(find.byType(ArticleDetailsScreen))),
      TextDirection.rtl,
    );
    final categoryText = tester.widget<Text>(find.text('خرسانة'));
    expect(categoryText.style?.color, AppColors.darkBrandAmber);
    expect(tester.takeException(), isNull);
  });
}
