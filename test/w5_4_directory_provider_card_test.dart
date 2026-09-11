import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/features/directory/domain/canonical_directory_entity.dart';
import 'package:civilpedia/features/directory/presentation/canonical_entity_type_presentation.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_card.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';

import 'helpers/canonical_directory_test_helpers.dart';

CanonicalDirectoryEntity _p({
  required String id,
  String name = '',
  String entityType = 'other',
  List<CanonicalDirectoryCategory> categories = const [],
  List<CanonicalDirectoryLocation> locations = const [],
  List<CanonicalDirectoryContact> contacts = const [],
  VerificationStatus verificationStatus = VerificationStatus.unverified,
}) {
  return fakeEntity(
    id: id,
    name: name,
    entityType: entityType,
    categories: categories,
    locations: locations,
    contacts: contacts,
    verificationStatus: verificationStatus,
  );
}

Widget _app(CanonicalDirectoryEntity entity, {VoidCallback? onTap}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: Scaffold(
        body: DirectoryProviderCard(entity: entity, onTap: onTap),
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

    testWidgets('2. card renders localized entity type', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', entityType: 'supplier');
      await tester.pumpWidget(_app(p));
      // LanguageProvider defaults to Arabic.
      final expected = CanonicalEntityTypePresentation.labelFor(
        'supplier',
        isArabic: true,
      );
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('3. card renders location region name', (tester) async {
      final p = _p(
        id: 'a',
        name: 'Alpha',
        locations: [fakeLocation('karrada', regionName: 'كرادة')],
      );
      await tester.pumpWidget(_app(p));
      expect(find.text('كرادة'), findsOneWidget);
    });

    testWidgets('4. card renders categories when present', (tester) async {
      final p = _p(
        id: 'a',
        name: 'Alpha',
        categories: [fakeCategory('Steel'), fakeCategory('Concrete')],
      );
      await tester.pumpWidget(_app(p));
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
      final p = _p(
        id: 'a',
        name: 'Alpha',
        contacts: [fakePhone('07701234567'), fakeWhatsApp('07801234567')],
      );
      await tester.pumpWidget(_app(p));
      expect(find.text('07701234567'), findsNothing);
      expect(find.text('07801234567'), findsNothing);
      expect(find.byIcon(Icons.phone), findsNothing);
    });

    testWidgets('9. card displays verification badge (W5.5)', (tester) async {
      final p = _p(
        id: 'a',
        name: 'Alpha',
        verificationStatus: VerificationStatus.verified,
      );
      await tester.pumpWidget(_app(p));
      // LanguageProvider defaults to Arabic → label is موثّق; the icon confirms the badge.
      expect(find.text('موثّق'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('10. card has no saved/bookmark', (tester) async {
      final p = _p(id: 'a', name: 'Alpha');
      await tester.pumpWidget(_app(p));
      expect(find.byIcon(Icons.bookmark), findsNothing);
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
    });

    testWidgets('11. card only shows expected fields — no extra keyword signals', (tester) async {
      final p = _p(id: 'a', name: 'Alpha');
      await tester.pumpWidget(_app(p));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.textContaining('featured'), findsNothing);
      expect(find.textContaining('founding'), findsNothing);
      expect(find.textContaining('premium'), findsNothing);
    });

    testWidgets('12. extra entity metadata does not leak into card', (tester) async {
      final p = _p(id: 'a', name: 'Alpha');
      await tester.pumpWidget(_app(p));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.textContaining('claim'), findsNothing);
      expect(find.textContaining('lifecycle'), findsNothing);
    });

    testWidgets('13. description does not appear on card', (tester) async {
      final p = _p(id: 'a', name: 'Alpha');
      await tester.pumpWidget(_app(p));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.textContaining('description'), findsNothing);
    });
  });
}
