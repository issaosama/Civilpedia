import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/features/directory/domain/directory_query.dart';
import 'package:civilpedia/features/directory/domain/directory_query_engine.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_card.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_detail_screen.dart';
import 'package:civilpedia/features/directory/presentation/directory_verification_badge.dart';
import 'package:civilpedia/features/directory/presentation/services/directory_contact_launcher.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/routes/app_routes.dart';

ServiceBusinessProfile _p({
  required String id,
  String name = '',
  BusinessType type = BusinessType.other,
  List<String> categories = const [],
  List<String> subCategories = const [],
  BaghdadArea baghdadArea = BaghdadArea.unknown,
  String? address,
  String? description,
  List<String> phones = const [],
  String? whatsapp,
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
    address: address,
    description: description,
    phones: phones,
    whatsapp: whatsapp,
    verificationStatus: verificationStatus,
    featured: featured,
    foundingPartner: foundingPartner,
    planType: planType,
  );
}

class _FakeLauncher implements DirectoryContactLauncher {
  final List<String> launchedPhones = [];
  final List<String> launchedWhatsApps = [];

  @override
  Future<bool> launchPhone(String trimmedPhone) async {
    launchedPhones.add(trimmedPhone);
    return true;
  }

  @override
  Future<bool> launchWhatsApp(String digits) async {
    launchedWhatsApps.add(digits);
    return true;
  }
}

Widget _badgeApp(VerificationStatus status) {
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(child: DirectoryVerificationBadge(status: status)),
      ),
    ),
  );
}

Future<_FakeLauncher> _pumpDetail(
  WidgetTester tester,
  ServiceBusinessProfile profile,
) async {
  final launcher = _FakeLauncher();
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: DirectoryProviderDetailScreen(
          profile: profile,
          contactLauncher: launcher,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return launcher;
}

void main() {
  group('W5.5 BADGE — five states render', () {
    testWidgets('1. unverified renders', (tester) async {
      await tester.pumpWidget(_badgeApp(VerificationStatus.unverified));
      expect(find.text('غير موثّق'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('2. pending renders', (tester) async {
      await tester.pumpWidget(_badgeApp(VerificationStatus.pending));
      expect(find.text('قيد المراجعة'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('3. verified renders', (tester) async {
      await tester.pumpWidget(_badgeApp(VerificationStatus.verified));
      expect(find.text('موثّق'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('4. rejected renders', (tester) async {
      await tester.pumpWidget(_badgeApp(VerificationStatus.rejected));
      expect(find.text('مرفوض'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });

    testWidgets('5. suspended renders', (tester) async {
      await tester.pumpWidget(_badgeApp(VerificationStatus.suspended));
      expect(find.text('موقوف'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });
  });

  group('W5.5 BADGE — Arabic labels', () {
    testWidgets('6. Arabic unverified label correct', (tester) async {
      expect(
        DirectoryVerificationPresentation.labelFor(
          VerificationStatus.unverified,
          isArabic: true,
        ),
        'غير موثّق',
      );
    });

    testWidgets('7. Arabic pending label correct', (tester) async {
      expect(
        DirectoryVerificationPresentation.labelFor(
          VerificationStatus.pending,
          isArabic: true,
        ),
        'قيد المراجعة',
      );
    });

    testWidgets('8. Arabic verified label correct', (tester) async {
      expect(
        DirectoryVerificationPresentation.labelFor(
          VerificationStatus.verified,
          isArabic: true,
        ),
        'موثّق',
      );
    });

    testWidgets('9. Arabic rejected label correct', (tester) async {
      expect(
        DirectoryVerificationPresentation.labelFor(
          VerificationStatus.rejected,
          isArabic: true,
        ),
        'مرفوض',
      );
    });

    testWidgets('10. Arabic suspended label correct', (tester) async {
      expect(
        DirectoryVerificationPresentation.labelFor(
          VerificationStatus.suspended,
          isArabic: true,
        ),
        'موقوف',
      );
    });
  });

  group('W5.5 BADGE — English labels', () {
    testWidgets('11. English unverified label correct', (tester) async {
      expect(
        DirectoryVerificationPresentation.labelFor(
          VerificationStatus.unverified,
          isArabic: false,
        ),
        'Unverified',
      );
    });

    testWidgets('12. English pending label correct', (tester) async {
      expect(
        DirectoryVerificationPresentation.labelFor(
          VerificationStatus.pending,
          isArabic: false,
        ),
        'Pending review',
      );
    });

    testWidgets('13. English verified label correct', (tester) async {
      expect(
        DirectoryVerificationPresentation.labelFor(
          VerificationStatus.verified,
          isArabic: false,
        ),
        'Verified',
      );
    });

    testWidgets('14. English rejected label correct', (tester) async {
      expect(
        DirectoryVerificationPresentation.labelFor(
          VerificationStatus.rejected,
          isArabic: false,
        ),
        'Rejected',
      );
    });

    testWidgets('15. English suspended label correct', (tester) async {
      expect(
        DirectoryVerificationPresentation.labelFor(
          VerificationStatus.suspended,
          isArabic: false,
        ),
        'Suspended',
      );
    });
  });

  group('W5.5 BADGE — accessibility & distinction', () {
    testWidgets('16. badge includes text', (tester) async {
      await tester.pumpWidget(_badgeApp(VerificationStatus.verified));
      expect(find.text('موثّق'), findsOneWidget);
    });

    testWidgets('17. badge includes icon', (tester) async {
      await tester.pumpWidget(_badgeApp(VerificationStatus.verified));
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('18. status not conveyed by color alone (icon + text present)', (tester) async {
      await tester.pumpWidget(_badgeApp(VerificationStatus.pending));
      expect(find.text('قيد المراجعة'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('19. rejected and suspended labels differ', (tester) async {
      expect(
        DirectoryVerificationPresentation.labelFor(
          VerificationStatus.rejected,
          isArabic: true,
        ),
        isNot(
          DirectoryVerificationPresentation.labelFor(
            VerificationStatus.suspended,
            isArabic: true,
          ),
        ),
      );
    });

    testWidgets('20. rejected and suspended icons differ', (tester) async {
      expect(
        DirectoryVerificationPresentation.iconFor(VerificationStatus.rejected),
        isNot(
          DirectoryVerificationPresentation.iconFor(VerificationStatus.suspended),
        ),
      );
    });
  });

  group('W5.5 CARD — five states on listing', () {
    Widget cardApp(ServiceBusinessProfile p) {
      return ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: DirectoryProviderCard(profile: p)),
        ),
      );
    }

    testWidgets('21. card displays unverified', (tester) async {
      await tester.pumpWidget(
        cardApp(_p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.unverified)),
      );
      expect(find.text('غير موثّق'), findsOneWidget);
    });

    testWidgets('22. card displays pending', (tester) async {
      await tester.pumpWidget(
        cardApp(_p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.pending)),
      );
      expect(find.text('قيد المراجعة'), findsOneWidget);
    });

    testWidgets('23. card displays verified', (tester) async {
      await tester.pumpWidget(
        cardApp(_p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.verified)),
      );
      expect(find.text('موثّق'), findsOneWidget);
    });

    testWidgets('24. card displays rejected', (tester) async {
      await tester.pumpWidget(
        cardApp(_p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.rejected)),
      );
      expect(find.text('مرفوض'), findsOneWidget);
    });

    testWidgets('25. card displays suspended', (tester) async {
      await tester.pumpWidget(
        cardApp(_p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.suspended)),
      );
      expect(find.text('موقوف'), findsOneWidget);
    });

    testWidgets('26. long provider name still constrained safely', (tester) async {
      final longName = 'A' * 200;
      await tester.pumpWidget(
        cardApp(
          _p(
            id: 'a',
            name: longName,
            verificationStatus: VerificationStatus.verified,
            categories: ['Steel'],
          ),
        ),
      );
      expect(find.text(longName), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('27. badge does not remove category summary', (tester) async {
      await tester.pumpWidget(
        cardApp(_p(id: 'a', name: 'Alpha', categories: ['Steel'], verificationStatus: VerificationStatus.verified)),
      );
      expect(find.text('Steel'), findsOneWidget);
      expect(find.text('موثّق'), findsOneWidget);
    });

    testWidgets('28. card tap behavior unchanged', (tester) async {
      var tapped = 0;
      Widget app(ServiceBusinessProfile p) {
        return ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: DirectoryProviderCard(
                profile: p,
                onTap: () => tapped++,
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(app(_p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.verified)));
      await tester.tap(find.text('Alpha'));
      expect(tapped, 1);
    });

    testWidgets('29. verification does not display planType', (tester) async {
      await tester.pumpWidget(
        cardApp(_p(id: 'a', name: 'Alpha', planType: 'premium', verificationStatus: VerificationStatus.verified)),
      );
      expect(find.text('premium'), findsNothing);
    });

    testWidgets('30. verification does not display featured', (tester) async {
      await tester.pumpWidget(
        cardApp(_p(id: 'a', name: 'Alpha', featured: true, verificationStatus: VerificationStatus.verified)),
      );
      expect(find.textContaining('featured'), findsNothing);
    });

    testWidgets('31. verification does not display foundingPartner', (tester) async {
      await tester.pumpWidget(
        cardApp(_p(id: 'a', name: 'Alpha', foundingPartner: true, verificationStatus: VerificationStatus.verified)),
      );
      expect(find.textContaining('founding'), findsNothing);
    });
  });

  group('W5.5 DETAIL — five states + frozen W5.4 fields', () {
    testWidgets('32. detail displays verification badge in identity', (tester) async {
      await _pumpDetail(tester, _p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.verified));
      expect(find.text('موثّق'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('33. detail renders unverified', (tester) async {
      await _pumpDetail(tester, _p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.unverified));
      expect(find.text('غير موثّق'), findsOneWidget);
    });

    testWidgets('34. detail renders pending', (tester) async {
      await _pumpDetail(tester, _p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.pending));
      expect(find.text('قيد المراجعة'), findsOneWidget);
    });

    testWidgets('35. detail renders verified', (tester) async {
      await _pumpDetail(tester, _p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.verified));
      expect(find.text('موثّق'), findsOneWidget);
    });

    testWidgets('36. detail renders rejected', (tester) async {
      await _pumpDetail(tester, _p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.rejected));
      expect(find.text('مرفوض'), findsOneWidget);
    });

    testWidgets('37. detail renders suspended', (tester) async {
      await _pumpDetail(tester, _p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.suspended));
      expect(find.text('موقوف'), findsOneWidget);
    });

    testWidgets('38. phones unchanged', (tester) async {
      final launcher = await _pumpDetail(
        tester,
        _p(id: 'a', name: 'Alpha', phones: ['0770000000', '0780000000'], verificationStatus: VerificationStatus.verified),
      );
      expect(find.text('اتصال — 0770000000'), findsOneWidget);
      expect(find.text('اتصال — 0780000000'), findsOneWidget);
      await tester.tap(find.text('اتصال — 0770000000'));
      expect(launcher.launchedPhones, ['0770000000']);
    });

    testWidgets('39. WhatsApp unchanged', (tester) async {
      final launcher = await _pumpDetail(
        tester,
        _p(id: 'a', name: 'Alpha', whatsapp: '0770 000 0000', verificationStatus: VerificationStatus.verified),
      );
      // All digits are extracted (including any leading 0); display only.
      await tester.tap(find.text('واتساب — 07700000000'));
      expect(launcher.launchedWhatsApps, ['07700000000']);
    });

    testWidgets('40. no-contact state unchanged', (tester) async {
      await _pumpDetail(tester, _p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.verified));
      expect(find.text('لا توجد معلومات اتصال'), findsOneWidget);
    });

    testWidgets('41. address unchanged', (tester) async {
      await _pumpDetail(
        tester,
        _p(id: 'a', name: 'Alpha', address: 'Karrada St', verificationStatus: VerificationStatus.verified),
      );
      expect(find.text('Karrada St'), findsOneWidget);
    });

    testWidgets('42. services unchanged', (tester) async {
      await _pumpDetail(
        tester,
        _p(id: 'a', name: 'Alpha', categories: ['Steel'], subCategories: ['Reinforcement'], verificationStatus: VerificationStatus.verified),
      );
      expect(find.text('Steel'), findsOneWidget);
      expect(find.text('Reinforcement'), findsOneWidget);
    });
  });

  group('W5.5 SERIALIZATION / COMPATIBILITY — no changes', () {
    test('43. unverified round-trips as unverified', () {
      final p = _p(id: 'a', verificationStatus: VerificationStatus.unverified);
      expect(ServiceBusinessProfile.fromJson(p.toJson()).verificationStatus, VerificationStatus.unverified);
    });

    test('44. pending round-trips as pending', () {
      final p = _p(id: 'a', verificationStatus: VerificationStatus.pending);
      expect(ServiceBusinessProfile.fromJson(p.toJson()).verificationStatus, VerificationStatus.pending);
    });

    test('45. verified round-trips as verified', () {
      final p = _p(id: 'a', verificationStatus: VerificationStatus.verified);
      expect(ServiceBusinessProfile.fromJson(p.toJson()).verificationStatus, VerificationStatus.verified);
    });

    test('46. rejected round-trips as rejected', () {
      final p = _p(id: 'a', verificationStatus: VerificationStatus.rejected);
      expect(ServiceBusinessProfile.fromJson(p.toJson()).verificationStatus, VerificationStatus.rejected);
    });

    test('47. suspended round-trips as suspended', () {
      final p = _p(id: 'a', verificationStatus: VerificationStatus.suspended);
      expect(ServiceBusinessProfile.fromJson(p.toJson()).verificationStatus, VerificationStatus.suspended);
    });

    test('48. unknown persisted value falls back to unverified', () {
      final json = _p(id: 'a', verificationStatus: VerificationStatus.verified).toJson();
      json['verificationStatus'] = 'bogus-token';
      expect(
        ServiceBusinessProfile.fromJson(json).verificationStatus,
        VerificationStatus.unverified,
      );
    });

    test('49. rejected never maps to suspended', () {
      final p = ServiceBusinessProfile.fromJson(
        _p(id: 'a', verificationStatus: VerificationStatus.rejected).toJson(),
      );
      expect(p.verificationStatus, VerificationStatus.rejected);
      expect(p.verificationStatus, isNot(VerificationStatus.suspended));
    });

    test('50. suspended never maps to rejected', () {
      final p = ServiceBusinessProfile.fromJson(
        _p(id: 'a', verificationStatus: VerificationStatus.suspended).toJson(),
      );
      expect(p.verificationStatus, VerificationStatus.suspended);
      expect(p.verificationStatus, isNot(VerificationStatus.rejected));
    });
  });

  group('W5.5 FILTER / ORDER FREEZE', () {
    test('51. DirectoryQuery has no verification field', () {
      // DirectoryQuery exposes ONLY text/category/location — no verification.
      const q = DirectoryQuery();
      expect(q.text, '');
      expect(q.category, isNull);
      expect(q.location, isNull);
      expect(q.hasText, isFalse);
    });

    test('52. verification does not change DirectoryQueryEngine filtering', () {
      final profiles = [
        _p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.verified),
        _p(id: 'b', name: 'Alpha', verificationStatus: VerificationStatus.unverified),
      ];
      final result = DirectoryQueryEngine.apply(profiles, const DirectoryQuery(text: 'alpha'));
      expect(result.map((p) => p.id), ['a', 'b']);
    });

    test('53. verified profile does not reorder above unverified', () {
      final profiles = [
        _p(id: 'a', name: 'One', verificationStatus: VerificationStatus.unverified),
        _p(id: 'b', name: 'Two', verificationStatus: VerificationStatus.verified),
      ];
      final result = DirectoryQueryEngine.apply(profiles, const DirectoryQuery());
      expect(result.map((p) => p.id), ['a', 'b']);
    });

    test('54. suspended profile remains in results if it otherwise matches', () {
      final profiles = [
        _p(id: 'a', name: 'Match', verificationStatus: VerificationStatus.suspended),
      ];
      final result = DirectoryQueryEngine.apply(profiles, const DirectoryQuery(text: 'match'));
      expect(result.map((p) => p.id), ['a']);
    });

    test('55. rejected profile remains in results if it otherwise matches', () {
      final profiles = [
        _p(id: 'a', name: 'Match', verificationStatus: VerificationStatus.rejected),
      ];
      final result = DirectoryQueryEngine.apply(profiles, const DirectoryQuery(text: 'match'));
      expect(result.map((p) => p.id), ['a']);
    });
  });

  group('W5.5 NAV / SAVED / MONETIZATION', () {
    testWidgets('56. no verification filter UI', (tester) async {
      await tester.pumpWidget(_badgeApp(VerificationStatus.verified));
      expect(find.text('Verified only'), findsNothing);
      expect(find.text('Pending'), findsNothing);
      expect(find.text('Rejected'), findsNothing);
      expect(find.text('Suspended'), findsNothing);
    });

    testWidgets('57. no Saved button introduced', (tester) async {
      await _pumpDetail(tester, _p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.verified));
      expect(find.byIcon(Icons.bookmark), findsNothing);
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
    });

    testWidgets('58. no sponsored badge introduced', (tester) async {
      await _pumpDetail(tester, _p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.verified));
      expect(find.text('Sponsored'), findsNothing);
      expect(find.text('مموّل'), findsNothing);
    });

    test('59. no permanent Directory route added', () {
      expect(AppRoutes.search, isNot(contains('/directory')));
    });

    test('60. shell destinations unchanged', () {
      final routes = kShellDestinations.map((d) => d.route).toList();
      expect(routes, [
        AppRoutes.home,
        AppRoutes.encyclopedia,
        AppRoutes.tools,
        AppRoutes.saved,
        AppRoutes.profile,
      ]);
    });
  });
}
