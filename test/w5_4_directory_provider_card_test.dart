import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_card.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';

ServiceBusinessProfile _p({
  required String id,
  String name = '',
  BusinessType type = BusinessType.other,
  List<String> categories = const [],
  List<String> subCategories = const [],
  BaghdadArea baghdadArea = BaghdadArea.unknown,
  List<String> phones = const [],
  String whatsapp = '',
  VerificationStatus verificationStatus = VerificationStatus.unverified,
  bool featured = false,
  bool foundingPartner = false,
  String? planType,
}) {
  return ServiceBusinessProfile(
    id: id,
    name: name,
    type: type,
    categories: categories,
    subCategories: subCategories,
    baghdadArea: baghdadArea,
    phones: phones,
    whatsapp: whatsapp,
    verificationStatus: verificationStatus,
    featured: featured,
    foundingPartner: foundingPartner,
    planType: planType,
  );
}

Widget _app(ServiceBusinessProfile profile, {VoidCallback? onTap}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: Scaffold(
        body: DirectoryProviderCard(profile: profile, onTap: onTap),
      ),
    ),
  );
}

void main() {
  group('W5.4 CARD', () {
    testWidgets('1. card renders provider name', (tester) async {
      final p = _p(id: 'a', name: 'Alpha Steel Co');
      await tester.pumpWidget(_app(p));
      expect(find.text('Alpha Steel Co'), findsOneWidget);
    });

    testWidgets('2. card renders localized BusinessType', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', type: BusinessType.supplier);
      await tester.pumpWidget(_app(p));
      // LanguageProvider defaults to Arabic.
      expect(find.text('مورّد'), findsOneWidget);
    });

    testWidgets('3. card renders localized BaghdadArea', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', baghdadArea: BaghdadArea.karrada);
      await tester.pumpWidget(_app(p));
      expect(find.text('كرادة'), findsOneWidget);
    });

    testWidgets('4. card renders categories when present', (tester) async {
      final p = _p(
        id: 'a',
        name: 'Alpha',
        categories: ['Steel', '  ', 'Concrete'],
      );
      await tester.pumpWidget(_app(p));
      // Trims + drops empties, preserves order.
      expect(find.text('Steel · Concrete'), findsOneWidget);
    });

    testWidgets('5. empty categories produce no placeholder spam', (tester) async {
      final p = _p(id: 'a', name: 'Alpha');
      await tester.pumpWidget(_app(p));
      expect(find.text('Steel · Concrete'), findsNothing);
      expect(find.textContaining('No'), findsNothing);
    });

    testWidgets('6. long name constrained safely', (tester) async {
      final longName = 'A' * 200;
      final p = _p(id: 'a', name: longName);
      await tester.pumpWidget(_app(p));
      expect(find.text(longName), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. card invokes onTap', (tester) async {
      var tapped = 0;
      final p = _p(id: 'a', name: 'Alpha');
      await tester.pumpWidget(_app(p, onTap: () => tapped++));
      await tester.tap(find.text('Alpha'));
      expect(tapped, 1);
    });

    testWidgets('8. card has no contact button', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', phones: ['07701234567'], whatsapp: '07801234567');
      await tester.pumpWidget(_app(p));
      expect(find.text('07701234567'), findsNothing);
      expect(find.text('07801234567'), findsNothing);
      expect(find.byIcon(Icons.phone), findsNothing);
    });

    testWidgets('9. card has no verification', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.verified);
      await tester.pumpWidget(_app(p));
      expect(find.text('verified'), findsNothing);
      expect(find.byIcon(Icons.verified), findsNothing);
    });

    testWidgets('10. card has no saved/bookmark', (tester) async {
      final p = _p(id: 'a', name: 'Alpha');
      await tester.pumpWidget(_app(p));
      expect(find.byIcon(Icons.bookmark), findsNothing);
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
    });

    testWidgets('11. featured does not change card', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', featured: true);
      await tester.pumpWidget(_app(p));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.textContaining('featured'), findsNothing);
    });

    testWidgets('12. foundingPartner does not change card', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', foundingPartner: true);
      await tester.pumpWidget(_app(p));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.textContaining('founding'), findsNothing);
    });

    testWidgets('13. planType does not change card', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', planType: 'premium');
      await tester.pumpWidget(_app(p));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('premium'), findsNothing);
    });
  });
}
