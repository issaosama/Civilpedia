import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/features/directory/domain/directory_repository.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_card.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_detail_screen.dart';
import 'package:civilpedia/features/directory/presentation/directory_search_screen.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/routes/app_routes.dart';

class _FakeDirectoryRepository implements DirectoryRepository {
  int loadAllCalls = 0;
  final List<ServiceBusinessProfile> profiles;

  _FakeDirectoryRepository(this.profiles);

  @override
  Future<List<ServiceBusinessProfile>> loadAll() async {
    loadAllCalls++;
    return List<ServiceBusinessProfile>.from(profiles);
  }

  @override
  Future<ServiceBusinessProfile?> loadById(String id) async {
    for (final p in profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

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
}) {
  return ServiceBusinessProfile(
    id: id,
    name: name,
    type: type,
    categories: categories,
    subCategories: subCategories,
    baghdadArea: baghdadArea,
    phones: phones,
  );
}

Widget _app(_FakeDirectoryRepository repo) {
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: DirectorySearchScreen(repository: repo),
    ),
  );
}

void main() {
  group('W5.4 — W5.3 INTEGRATION', () {
    testWidgets('44. search results render DirectoryProviderCard', (tester) async {
      final profiles = [_p(id: 'a', name: 'Alpha Co', type: BusinessType.supplier)];
      await tester.pumpWidget(_app(_FakeDirectoryRepository(profiles)));
      await tester.pumpAndSettle();
      expect(find.byType(DirectoryProviderCard), findsOneWidget);
    });

    testWidgets('45. tapping result opens DirectoryProviderDetailScreen', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Alpha', phones: _defaultPhones(), type: BusinessType.supplier),
      ];
      await tester.pumpWidget(_app(_FakeDirectoryRepository(profiles)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DirectoryProviderCard));
      await tester.pumpAndSettle();
      expect(find.byType(DirectoryProviderDetailScreen), findsOneWidget);
    });

    testWidgets('46. query engine unchanged (filtering still applies)', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Alpha Steel', type: BusinessType.supplier),
        _p(id: 'b', name: 'Beta Co', type: BusinessType.contractor),
      ];
      await tester.pumpWidget(_app(_FakeDirectoryRepository(profiles)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'steel');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DirectoryProviderCard), findsOneWidget);
      expect(find.text('Alpha Steel'), findsOneWidget);
      expect(find.text('Beta Co'), findsNothing);
    });

    testWidgets('47. text search works through card', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Omega', categories: ['Reinforcement']),
        _p(id: 'b', name: 'Gamma', categories: ['Formwork']),
      ];
      await tester.pumpWidget(_app(_FakeDirectoryRepository(profiles)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'formwork');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DirectoryProviderCard), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
      expect(find.text('Omega'), findsNothing);
    });

    testWidgets('48. category filter unchanged', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Supplier Co', type: BusinessType.supplier),
        _p(id: 'b', name: 'Contractor Co', type: BusinessType.contractor),
      ];
      await tester.pumpWidget(_app(_FakeDirectoryRepository(profiles)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<BusinessType?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('مورّد').last);
      await tester.pumpAndSettle();
      expect(find.text('Supplier Co'), findsOneWidget);
      expect(find.text('Contractor Co'), findsNothing);
    });

    testWidgets('49. location filter unchanged', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'Co A', baghdadArea: BaghdadArea.adhamiya),
        _p(id: 'b', name: 'Co B', baghdadArea: BaghdadArea.mansour),
      ];
      await tester.pumpWidget(_app(_FakeDirectoryRepository(profiles)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<BaghdadArea?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الأعظمية').last);
      await tester.pumpAndSettle();
      expect(find.text('Co A'), findsOneWidget);
      expect(find.text('Co B'), findsNothing);
    });

    testWidgets('50. debounce remains 280ms', (tester) async {
      final profiles = [_p(id: 'a', name: 'Alpha Steel')];
      await tester.pumpWidget(_app(_FakeDirectoryRepository(profiles)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Alpha Steel'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(DirectoryProviderCard), findsNothing);
    });

    testWidgets('51. source ordering unchanged (stable)', (tester) async {
      final profiles = [
        _p(id: 'a', name: 'First', type: BusinessType.supplier),
        _p(id: 'b', name: 'Second', type: BusinessType.contractor),
      ];
      await tester.pumpWidget(_app(_FakeDirectoryRepository(profiles)));
      await tester.pumpAndSettle();
      final cards = tester.widgetList<DirectoryProviderCard>(
        find.byType(DirectoryProviderCard),
      );
      final names = cards.map((c) => c.profile.name).toList();
      expect(names, ['First', 'Second']);
    });

    testWidgets('52. loadAll still called once', (tester) async {
      final repo = _FakeDirectoryRepository([_p(id: 'a', name: 'Alpha')]);
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.loadAllCalls, 1);
    });

    test('53. no permanent Directory route added', () {
      expect(AppRoutes.search, isNot(contains('/directory')));
    });

    test('54. shell destinations = W6.3 target shell', () {
      final routes = kShellDestinations.map((d) => d.route).toList();
      expect(routes, [
        AppRoutes.home,
        AppRoutes.encyclopedia,
        AppRoutes.tools,
        AppRoutes.projects,
        AppRoutes.directory,
      ]);
    });
  });
}

List<String> _defaultPhones() => ['07701234567'];
