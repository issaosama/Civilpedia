import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/content_block_widget.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/image_unavailable_fallback.dart';
import 'package:civilpedia/features/encyclopedia/presentation/theme/encyclopedia_card_colors.dart';
import 'package:civilpedia/features/encyclopedia/presentation/theme/encyclopedia_topic_theme.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';

void main() {
  setUpAll(() {
    EncyclopediaCardColors.apply(EncyclopediaTopicTheme.defaultTheme);
  });

  Widget wrapContent(Widget child, {Locale? locale}) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('RR.1 Missing topic image fallback', () {
    testWidgets('valid image renders normally and shows no fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapContent(
          ContentBlockWidget(
            block: ImageBlock(imageUrl: 'assets/images/rebar_cover.png', caption: 'Fig valid'),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();

      expect(find.text('Fig valid'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text(Ar.imageUnavailable), findsNothing);
      expect(find.byType(ImageUnavailableFallback), findsNothing);
    });

    testWidgets('missing image does not throw and topic content still renders', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapContent(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ContentBlockWidget(
                block: ImageBlock(imageUrl: 'missing/path.png', caption: 'Fig 1'),
              ),
              ContentBlockWidget(
                block: TextBlock(content: 'بعد الصورة التنفيذ يستمر', variant: TextVariant.paragraph),
              ),
            ],
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Fig 1'), findsOneWidget);
      expect(find.text('بعد الصورة التنفيذ يستمر'), findsOneWidget);
    });

    testWidgets('missing image shows localized fallback message', (tester) async {
      await tester.pumpWidget(
        wrapContent(
          ContentBlockWidget(
            block: ImageBlock(imageUrl: 'missing/path.png', caption: null),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();

      expect(find.byType(ImageUnavailableFallback), findsOneWidget);
      expect(find.text(Ar.imageUnavailable), findsOneWidget);
      expect(find.text(En.imageUnavailable), findsNothing);
    });

    testWidgets('missing image shows English fallback in en locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapContent(
          ContentBlockWidget(
            block: ImageBlock(imageUrl: 'missing/path.png', caption: null),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pump();

      expect(find.byType(ImageUnavailableFallback), findsOneWidget);
      expect(find.text(En.imageUnavailable), findsOneWidget);
      expect(find.text(Ar.imageUnavailable), findsNothing);
    });

    testWidgets('one missing image does not break other image blocks', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapContent(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ContentBlockWidget(
                block: ImageBlock(imageUrl: 'missing/a.png', caption: 'Fig A'),
              ),
              ContentBlockWidget(
                block: ImageBlock(imageUrl: 'assets/images/rebar_cover.png', caption: 'Fig B'),
              ),
              ContentBlockWidget(
                block: ImageBlock(imageUrl: 'missing/c.png', caption: 'Fig C'),
              ),
            ],
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Fig A'), findsOneWidget);
      expect(find.text('Fig B'), findsOneWidget);
      expect(find.text('Fig C'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == 'assets/images/rebar_cover.png',
        ),
        findsOneWidget,
      );
      expect(find.byType(ImageUnavailableFallback), findsNWidgets(2));
      expect(find.text(Ar.imageUnavailable), findsNWidgets(2));
    });
  });
}