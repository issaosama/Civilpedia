import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/features/home/data/datasources/ad_data_source.dart';
import 'package:civilpedia/features/home/data/models/ad_banner.dart';
import 'package:civilpedia/features/home/presentation/widgets/ad_carousel_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Explicit single-ad preview fixture with a local-safe image URL (avoids
/// depending on a live network in widget tests).
class _PreviewAdSource implements AdDataSource {
  @override
  Future<List<AdBanner>> fetchActiveAds() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [
      AdBanner(
        id: 'preview-ad',
        imageUrl: 'data:image/png;base64,iVBORw0KGgo=',
        actionUrl: 'https://example.com/preview',
        title: 'Preview',
      ),
    ];
  }
}

Widget _host({AdDataSource? dataSource}) {
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            AdCarouselWidget(dataSource: dataSource),
            const SizedBox(height: 24, child: Text('below')),
          ],
        ),
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
}

void main() {
  group('AdDataSource production versus preview contract', () {
    test('LocalAdDataSource returns a genuinely empty result (no campaign)', () async {
      final ads = await LocalAdDataSource().fetchActiveAds();
      expect(ads, isEmpty);
    });

    test('MockAdDataSource explicitly provides preview ads', () async {
      final ads = await MockAdDataSource().fetchActiveAds();
      expect(ads, isNotEmpty);
      expect(ads, isA<List<AdBanner>>());
    });
  });

  group('AdCarouselWidget', () {
    testWidgets('default behavior uses honest production source: no ad slot and no blank gap',
        (tester) async {
      await tester.pumpWidget(_host());
      await _settle(tester);

      expect(find.byType(AdCarouselWidget), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final renderBox =
          tester.renderObject<RenderBox>(find.byType(AdCarouselWidget));
      expect(renderBox.size.height, 0);
    });

    testWidgets('empty ads do not throw and content flows up into the vacated space',
        (tester) async {
      await tester.pumpWidget(_host());
      await _settle(tester);

      final belowOffset = tester.getTopLeft(find.text('below')).dy;
      expect(belowOffset, lessThan(10));
    });

    testWidgets('an explicitly injected preview source renders the existing carousel',
        (tester) async {
      await tester.pumpWidget(_host(dataSource: _PreviewAdSource()));
      await _settle(tester);

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);

      final renderBox =
          tester.renderObject<RenderBox>(find.byType(AdCarouselWidget));
      expect(renderBox.size.height, greaterThan(0));
    });

    testWidgets('injected MockAdDataSource renders the existing carousel', (tester) async {
      await tester.pumpWidget(_host(dataSource: MockAdDataSource()));
      await _settle(tester);

      expect(find.byType(PageView), findsOneWidget);
    });
  });
}
