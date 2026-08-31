import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_detail_screen.dart';
import 'package:civilpedia/features/directory/presentation/services/directory_contact_launcher.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/localization/ar.dart';

class _FakeLauncher implements DirectoryContactLauncher {
  final List<String> launchedPhones = [];
  final List<String> launchedWhatsApps = [];
  bool succeed = true;

  @override
  Future<bool> launchPhone(String trimmedPhone) async {
    if (!succeed) return false;
    launchedPhones.add(trimmedPhone);
    return true;
  }

  @override
  Future<bool> launchWhatsApp(String digits) async {
    if (!succeed) return false;
    launchedWhatsApps.add(digits);
    return true;
  }
}

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

Widget _app(ServiceBusinessProfile profile, _FakeLauncher launcher) {
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: DirectoryProviderDetailScreen(
        profile: profile,
        contactLauncher: launcher,
      ),
    ),
  );
}

Future<_FakeLauncher> _pump(
  WidgetTester tester,
  ServiceBusinessProfile profile, {
  _FakeLauncher? launcher,
}) async {
  final l = launcher ?? _FakeLauncher();
  await tester.pumpWidget(_app(profile, l));
  await tester.pumpAndSettle();
  return l;
}

void main() {
  group('W5.4 DETAIL — identity', () {
    testWidgets('14. detail renders provider name', (tester) async {
      await _pump(tester, _p(id: 'a', name: 'Alpha Steel'));
      // Name appears in the AppBar title and the identity header.
      expect(find.text('Alpha Steel'), findsAtLeastNWidgets(1));
    });

    testWidgets('15. detail renders BusinessType', (tester) async {
      await _pump(tester, _p(id: 'a', name: 'Alpha', type: BusinessType.supplier));
      expect(find.text('مورّد'), findsOneWidget);
    });

    testWidgets('16. detail renders BaghdadArea', (tester) async {
      await _pump(
        tester,
        _p(id: 'a', name: 'Alpha', baghdadArea: BaghdadArea.karrada),
      );
      expect(find.text('كرادة'), findsOneWidget);
    });
  });

  group('W5.4 DETAIL — description & address', () {
    testWidgets('17. description shown when present', (tester) async {
      await _pump(tester, _p(id: 'a', name: 'Alpha', description: '  A real description  '));
      expect(find.textContaining('A real description'), findsOneWidget);
    });

    testWidgets('18. description hidden when absent', (tester) async {
      await _pump(tester, _p(id: 'a', name: 'Alpha'));
      expect(find.text(Ar.directoryDescription), findsNothing);
    });

    testWidgets('19. address shown when present', (tester) async {
      await _pump(tester, _p(id: 'a', name: 'Alpha', address: 'Baghdad St'));
      expect(find.text('Baghdad St'), findsOneWidget);
    });

    testWidgets('20. address hidden when absent', (tester) async {
      await _pump(tester, _p(id: 'a', name: 'Alpha'));
      expect(find.text(Ar.directoryAddress), findsNothing);
    });
  });

  group('W5.4 DETAIL — services', () {
    testWidgets('21. categories shown', (tester) async {
      await _pump(tester, _p(id: 'a', name: 'Alpha', categories: ['Steel', 'Concrete']));
      expect(find.text('Steel'), findsOneWidget);
      expect(find.text('Concrete'), findsOneWidget);
    });

    testWidgets('22. subCategories shown', (tester) async {
      await _pump(
        tester,
        _p(id: 'a', name: 'Alpha', subCategories: ['Reinforcement', 'Formwork']),
      );
      expect(find.text('Reinforcement'), findsOneWidget);
      expect(find.text('Formwork'), findsOneWidget);
    });

    testWidgets('services section hidden when no categories/subCategories', (tester) async {
      await _pump(tester, _p(id: 'a', name: 'Alpha'));
      expect(find.text(Ar.directoryServices), findsNothing);
    });
  });

  group('W5.4 DETAIL — contact', () {
    testWidgets('23. multiple phones all rendered', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', phones: ['0771111111', '0772222222']);
      await _pump(tester, p);
      expect(find.textContaining('0771111111'), findsOneWidget);
      expect(find.textContaining('0772222222'), findsOneWidget);
    });

    testWidgets('24. empty phone strings ignored', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', phones: ['   ', '0771111111', '']);
      await _pump(tester, p);
      expect(find.textContaining('0771111111'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
    });

    testWidgets('25. WhatsApp shown when launchable', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', whatsapp: '+964 780 123 4567');
      await _pump(tester, p);
      expect(find.textContaining('9647801234567'), findsOneWidget);
    });

    testWidgets('26. WhatsApp hidden when no digits', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', whatsapp: 'whatsapp only');
      await _pump(tester, p);
      expect(find.byIcon(Icons.chat), findsNothing);
    });

    testWidgets('27. no-contact state when no phone/WhatsApp', (tester) async {
      await _pump(tester, _p(id: 'a', name: 'Alpha'));
      expect(find.text(Ar.directoryNoContactInformation), findsOneWidget);
    });

    testWidgets('28. no-contact state absent when actionable contact exists', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', phones: ['0771111111']);
      await _pump(tester, p);
      expect(find.text(Ar.directoryNoContactInformation), findsNothing);
    });
  });

  group('W5.4 DETAIL — exclusions', () {
    testWidgets('29. no email action', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', phones: ['0771111111']);
      await _pump(tester, p);
      expect(find.byIcon(Icons.mail_outline), findsNothing);
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('30. no website action', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', phones: ['0771111111']);
      await _pump(tester, p);
      expect(find.byIcon(Icons.link), findsNothing);
      expect(find.textContaining('http'), findsNothing);
    });

    testWidgets('31. no maps action', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', address: 'Baghdad', phones: ['0771111111']);
      await _pump(tester, p);
      expect(find.text('Baghdad'), findsOneWidget);
      expect(find.byIcon(Icons.map), findsNothing);
      expect(find.byIcon(Icons.directions), findsNothing);
    });

    testWidgets('32. no verification display', (tester) async {
      final p = _p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.verified);
      await _pump(tester, p);
      expect(find.text('verified'), findsNothing);
      expect(find.byIcon(Icons.verified), findsNothing);
    });

    testWidgets('33. no Saved UI', (tester) async {
      await _pump(tester, _p(id: 'a', name: 'Alpha'));
      expect(find.byIcon(Icons.bookmark), findsNothing);
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
    });

    testWidgets('34. no sponsored/featured/plan display', (tester) async {
      final p = _p(
        id: 'a',
        name: 'Alpha',
        featured: true,
        foundingPartner: true,
        planType: 'premium',
        phones: ['0771111111'],
      );
      await _pump(tester, p);
      expect(find.textContaining('featured'), findsNothing);
      expect(find.textContaining('founding'), findsNothing);
      expect(find.text('premium'), findsNothing);
      expect(find.textContaining('sponsored'), findsNothing);
      expect(find.textContaining('مموّل'), findsNothing);
    });
  });

  group('W5.4 CONTACT LAUNCH', () {
    testWidgets('35. phone URI uses tel scheme via launcher', (tester) async {
      final l = await _pump(tester, _p(id: 'a', name: 'Alpha', phones: ['0771111111']));
      await tester.tap(find.byIcon(Icons.phone));
      expect(l.launchedPhones, ['0771111111']);
    });

    testWidgets('36. phone uses trimmed stored value', (tester) async {
      final l = await _pump(tester, _p(id: 'a', name: 'Alpha', phones: ['  0771111111  ']));
      await tester.tap(find.byIcon(Icons.phone));
      expect(l.launchedPhones, ['0771111111']);
    });

    testWidgets('37. multiple phone buttons launch their own numbers', (tester) async {
      final l = await _pump(
        tester,
        _p(id: 'a', name: 'Alpha', phones: ['0771111111', '0772222222']),
      );
      expect(find.byIcon(Icons.phone), findsNWidgets(2));
      await tester.tap(find.byIcon(Icons.phone).first);
      expect(l.launchedPhones, ['0771111111']);
      await tester.tap(find.byIcon(Icons.phone).last);
      expect(l.launchedPhones, ['0771111111', '0772222222']);
    });

    testWidgets('40. empty-digit WhatsApp is unavailable', (tester) async {
      final l = await _pump(tester, _p(id: 'a', name: 'Alpha', whatsapp: 'no digits'));
      expect(find.byIcon(Icons.chat), findsNothing);
      expect(l.launchedWhatsApps, isEmpty);
    });

    testWidgets('38. WhatsApp strips non-digits', (tester) async {
      expect(extractWhatsAppDigits('+964 (780) 123-4567'), '9647801234567');
      expect(extractWhatsAppDigits('wa.me/07801234567'), '07801234567');
    });

    testWidgets('39. WhatsApp does not infer country code', (tester) async {
      // A stored leading +964 is preserved as meaningful digits, never dropped.
      expect(extractWhatsAppDigits('+9647801234567'), '9647801234567');
      // A stored 07-prefixed number stays 07-prefixed; no leading country added.
      expect(extractWhatsAppDigits('07801234567'), '07801234567');
    });

    testWidgets('41. WhatsApp launch uses wa.me and success shows no error', (tester) async {
      final l = await _pump(
        tester,
        _p(id: 'a', name: 'Alpha', phones: ['0771111111'], whatsapp: '07801234567'),
      );
      // WhatsApp is its own button (chat icon), distinct from call (phone).
      await tester.tap(find.byIcon(Icons.chat));
      expect(l.launchedWhatsApps, ['07801234567']);
      expect(find.text(Ar.directoryUnableToOpenApp), findsNothing);
    });

    testWidgets('42. launcher failure produces benign error feedback', (tester) async {
      final l = _FakeLauncher()..succeed = false;
      await _pump(tester, _p(id: 'a', name: 'Alpha', phones: ['0771111111']), launcher: l);
      await tester.tap(find.byIcon(Icons.phone));
      await tester.pump();
      expect(find.text(Ar.directoryUnableToOpenApp), findsOneWidget);
    });

    testWidgets('43. launch failure does not crash', (tester) async {
      final l = _FakeLauncher()..succeed = false;
      await _pump(tester, _p(id: 'a', name: 'Alpha', phones: ['0771111111']), launcher: l);
      await tester.tap(find.byIcon(Icons.phone));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
