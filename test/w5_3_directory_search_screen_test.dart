import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/features/directory/domain/directory_repository.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_detail_screen.dart';
import 'package:civilpedia/features/directory/presentation/directory_search_screen.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:civilpedia/routes/app_routes.dart';

/// Counts calls to [loadAll] so tests can assert single-load-once behavior.
class _FakeDirectoryRepository implements DirectoryRepository {
  int loadAllCalls = 0;
  final List<ServiceBusinessProfile> profiles;
  final Object? throwOnLoad;
  final Future<void>? pendingFirstLoad;

  _FakeDirectoryRepository(
    this.profiles, {
    this.throwOnLoad,
  }) : pendingFirstLoad = null;

  _FakeDirectoryRepository.delayed(
    this.profiles,
    this.pendingFirstLoad,
  ) : throwOnLoad = null;

  @override
  Future<List<ServiceBusinessProfile>> loadAll() async {
    loadAllCalls++;
    if (pendingFirstLoad != null && loadAllCalls == 1) {
      await pendingFirstLoad!;
    }
    if (throwOnLoad != null) throw throwOnLoad!;
    return List<ServiceBusinessProfile>.from(profiles);
  }

  @override
  Future<ServiceBusinessProfile?> loadById(String id) async => null;

  @override
  Future<void> save(ServiceBusinessProfile profile) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> clearAll() async {}
}

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
  );
}

Widget _app(_FakeDirectoryRepository repo, {BusinessType? initialCategory}) {
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: DirectorySearchScreen(
        repository: repo,
        initialCategory: initialCategory,
      ),
    ),
  );
}

Future<_FakeDirectoryRepository> _pump(
  WidgetTester tester, {
  List<ServiceBusinessProfile> profiles = const [],
  BusinessType? initialCategory,
  Object? throwOnLoad,
}) async {
  final repo = _FakeDirectoryRepository(profiles, throwOnLoad: throwOnLoad);
  await tester.pumpWidget(_app(repo, initialCategory: initialCategory));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('W5.3 SCREEN — load & states', () {
    testWidgets('28. screen loads through DirectoryRepository', (tester) async {
      final repo = await _pump(tester);
      expect(repo.loadAllCalls, 1);
      expect(find.byType(DirectorySearchScreen), findsOneWidget);
    });

    testWidgets('29. repository loadAll called once', (tester) async {
      final repo = await _pump(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.loadAllCalls, 1);
    });

    testWidgets('30. initial loading state works', (tester) async {
      final completer = Completer<void>();
      final repo = _FakeDirectoryRepository.delayed(const [], completer.future);
      await tester.pumpWidget(_app(repo));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Complete the load; loading state resolves.
      completer.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('31. browse mode renders loaded profiles', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Company A', type: BusinessType.supplier),
        _p(id: 'b', name: 'Company B', type: BusinessType.contractor),
      ];
      await _pump(tester, profiles: profiles);
      expect(find.text('Company A'), findsOneWidget);
      expect(find.text('Company B'), findsOneWidget);
    });

    testWidgets('32. initialCategory preselects correct BusinessType', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Supplier Co', type: BusinessType.supplier, baghdadArea: BaghdadArea.karrada),
        _p(id: 'b', name: 'Contractor Co', type: BusinessType.contractor, baghdadArea: BaghdadArea.karrada),
      ];
      await _pump(tester, profiles: profiles, initialCategory: BusinessType.supplier);
      // Only the supplier profile is shown; contractor filtered out.
      expect(find.text('Supplier Co'), findsOneWidget);
      expect(find.text('Contractor Co'), findsNothing);
    });

    testWidgets('39. empty repository shows empty-directory state', (tester) async {
      await _pump(tester, profiles: const []);
      expect(find.text(Ar.directoryEmptyDirectory), findsOneWidget);
    });

    testWidgets('40. non-empty repo + zero matches shows no-results state', (tester) async {
      final profiles = [_p(id: 'a', name: 'Alpha Co')];
      await _pump(tester, profiles: profiles);
      await tester.enterText(find.byType(TextField), 'zzz-none');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(Ar.directoryNoResults), findsOneWidget);
    });

    testWidgets('50. error state on repository load failure', (tester) async {
      await _pump(tester, throwOnLoad: Exception('boom'));
      expect(find.text(Ar.errorOccurred), findsOneWidget);
    });
  });

  group('W5.3 SCREEN — search field & debounce', () {
    testWidgets('33. search field filters results', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Alpha Steel', type: BusinessType.supplier),
        _p(id: 'b', name: 'Beta Materials', type: BusinessType.contractor),
      ];
      await _pump(tester, profiles: profiles);
      await tester.enterText(find.byType(TextField), 'steel');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Alpha Steel'), findsOneWidget);
      expect(find.text('Beta Materials'), findsNothing);
    });

    testWidgets('34. debounce behavior works (single re-filter after pause)', (tester) async {
      final profiles = [_p(id: 'a', name: 'Alpha Steel')];
      await _pump(tester, profiles: profiles);
      // Type, then advance less than debounce: no filter yet.
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 100));
      // Still showing profile before debounce elapses.
      expect(find.text('Alpha Steel'), findsOneWidget);
      // Advance past debounce: filter applies.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(Ar.directoryNoResults), findsOneWidget);
    });
  });

  group('W5.3 SCREEN — filters', () {
    testWidgets('35. category selection filters immediately', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Supplier Co', type: BusinessType.supplier),
        _p(id: 'b', name: 'Contractor Co', type: BusinessType.contractor),
      ];
      await _pump(tester, profiles: profiles);
      // Open the category dropdown and select Supplier.
      await tester.tap(
        find.byType(DropdownButtonFormField<BusinessType?>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.directoryTypeSupplier).last);
      await tester.pumpAndSettle();
      expect(find.text('Supplier Co'), findsOneWidget);
      expect(find.text('Contractor Co'), findsNothing);
    });

    testWidgets('36. location selection filters immediately', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Co A', baghdadArea: BaghdadArea.adhamiya),
        _p(id: 'b', name: 'Co B', baghdadArea: BaghdadArea.mansour),
      ];
      await _pump(tester, profiles: profiles);
      await tester.tap(find.byType(DropdownButtonFormField<BaghdadArea?>));
      await tester.pumpAndSettle();
      // "الأعظمية" is near the top of the location option list.
      await tester.tap(find.text(BaghdadArea.adhamiya.arName).last);
      await tester.pumpAndSettle();
      expect(find.text('Co A'), findsOneWidget);
      expect(find.text('Co B'), findsNothing);
    });

    testWidgets('37. clearing category returns all', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Supplier Co', type: BusinessType.supplier),
        _p(id: 'b', name: 'Contractor Co', type: BusinessType.contractor),
      ];
      await _pump(tester, profiles: profiles, initialCategory: BusinessType.supplier);
      // Only supplier shown initially.
      expect(find.text('Contractor Co'), findsNothing);
      // Open category dropdown and select All.
      await tester.tap(find.byType(DropdownButtonFormField<BusinessType?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.directoryFilterAll).last);
      await tester.pumpAndSettle();
      expect(find.text('Contractor Co'), findsOneWidget);
      expect(find.text('Supplier Co'), findsOneWidget);
    });

    testWidgets('38. clearing location returns all', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Co A', baghdadArea: BaghdadArea.adhamiya),
        _p(id: 'b', name: 'Co B', baghdadArea: BaghdadArea.mansour),
      ];
      await _pump(tester, profiles: profiles);
      // Select a location first.
      await tester.tap(find.byType(DropdownButtonFormField<BaghdadArea?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(BaghdadArea.adhamiya.arName).last);
      await tester.pumpAndSettle();
      expect(find.text('Co A'), findsOneWidget);
      expect(find.text('Co B'), findsNothing);
      // Clear location back to All ("الكل" is the first menu item).
      await tester.tap(find.byType(DropdownButtonFormField<BaghdadArea?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.directoryFilterAll).last);
      await tester.pumpAndSettle();
      expect(find.text('Co A'), findsOneWidget);
      expect(find.text('Co B'), findsOneWidget);
    });
  });

  group('W5.3 SCREEN — result presentation', () {
    testWidgets('41. no result count displayed', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Alpha Co', type: BusinessType.supplier),
        _p(id: 'b', name: 'Beta Co', type: BusinessType.contractor),
      ];
      await _pump(tester, profiles: profiles);
      expect(find.textContaining('results'), findsNothing);
      expect(find.textContaining('نتائج'), findsNothing);
    });

    testWidgets('42. result row shows name', (tester) async {
      final profiles = [_p(id: 'a', name: 'Alpha Steel')];
      await _pump(tester, profiles: profiles);
      expect(find.text('Alpha Steel'), findsOneWidget);
    });

    testWidgets('43. result row shows localized BusinessType', (tester) async {
      final profiles = [_p(id: 'a', name: 'Alpha', type: BusinessType.supplier)];
      await _pump(tester, profiles: profiles);
      expect(find.text(Ar.directoryTypeSupplier), findsOneWidget);
    });

    testWidgets('44. result row does not show contact', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Alpha', phones: ['07701234567'], whatsapp: '07801234567'),
      ];
      await _pump(tester, profiles: profiles);
      expect(find.text('07701234567'), findsNothing);
      expect(find.text('07801234567'), findsNothing);
      expect(find.byIcon(Icons.phone), findsNothing);
    });

    testWidgets('45. result row shows verification badge but filter is absent (W5.5)', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.verified),
      ];
      await _pump(tester, profiles: profiles);
      // Verification is displayed on the listing card (W5.5). LanguageProvider
      // defaults to Arabic → verified label is موثّق; the icon confirms the badge.
      expect(find.text('موثّق'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
      // Display only: no verification filter UI is introduced.
      expect(find.text('Verified only'), findsNothing);
      expect(find.text('مراجعة'), findsNothing);
    });

    testWidgets('46. result row does not show Saved', (tester) async {
      final profiles = [_p(id: 'a', name: 'Alpha')];
      await _pump(tester, profiles: profiles);
      expect(find.byIcon(Icons.bookmark), findsNothing);
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
    });

    testWidgets('47. result navigates to provider detail (W5.4)', (tester) async {
      final profiles = [_p(id: 'a', name: 'Alpha Co')];
      await _pump(tester, profiles: profiles);
      await tester.tap(find.text('Alpha Co'));
      await tester.pumpAndSettle();
      // Internal (production-unexposed) Navigator push opens the detail.
      expect(find.byType(DirectoryProviderDetailScreen), findsOneWidget);
    });
  });

  group('W5.3 SCREEN — boundaries', () {
    test('48. no Global Search integration', () {
      // W5.3 is Directory-local; the search screen does not expose projections.
      expect(Ar.directorySearchTitle, isNotEmpty);
      expect(En.directorySearchTitle, 'Search Directory');
    });

    test('49. no permanent Directory route declared', () {
      // Directory routes are NOT added to AppRoutes in W5.3.
      expect(AppRoutes.search, isNot(contains('/directory')));
      // Screen type exists (imported above) but production-unexposed.
      expect(DirectorySearchScreen, isNotNull);
    });

    testWidgets('51. shell destinations unchanged', (tester) async {
      // Five tabs preserved; no Directory destination.
      final routes = kShellDestinations.map((d) => d.route).toList();
      expect(routes, [
        AppRoutes.home,
        AppRoutes.encyclopedia,
        AppRoutes.tools,
        AppRoutes.saved,
        AppRoutes.profile,
      ]);
      expect(find.byType(DirectorySearchScreen), findsNothing);
    });
  });
}
