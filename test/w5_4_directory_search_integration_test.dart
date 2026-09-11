import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/features/directory/domain/canonical_directory_entity.dart';
import 'package:civilpedia/features/directory/domain/cloud_directory_repository.dart';
import 'package:civilpedia/features/directory/presentation/canonical_entity_type_presentation.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_card.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_detail_screen.dart';
import 'package:civilpedia/features/directory/presentation/directory_search_screen.dart';
import 'package:civilpedia/routes/app_routes.dart';

import 'helpers/canonical_directory_test_helpers.dart';

class _FakeCloudDirectoryRepository implements CloudDirectoryRepository {
  int loadCalls = 0;
  final List<CanonicalDirectoryEntity> entities;

  _FakeCloudDirectoryRepository(this.entities);

  @override
  bool get isAvailable => true;

  @override
  Future<DirectoryCachedData?> readCache() async => null;

  @override
  Future<DirectoryRefreshResult> refresh() async =>
      const DirectoryRefreshResult(status: DirectoryRefreshStatus.failure);

  @override
  Future<CanonicalDirectoryEntity?> loadByCanonicalId(String id) async {
    for (final e in entities) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<DirectoryLoadResult> load() async {
    loadCalls++;
    if (entities.isEmpty) {
      return DirectoryLoadResult(
        state: DirectoryLoadState.empty,
        entities: const [],
        refreshedAt: DateTime.now().toUtc(),
      );
    }
    return DirectoryLoadResult(
      state: DirectoryLoadState.fresh,
      entities: List<CanonicalDirectoryEntity>.from(entities),
      refreshedAt: DateTime.now().toUtc(),
    );
  }
}

CanonicalDirectoryEntity _p({
  required String id,
  String name = '',
  String entityType = 'other',
  List<CanonicalDirectoryCategory> categories = const [],
  List<CanonicalDirectoryLocation> locations = const [],
  List<String> phones = const [],
}) {
  return fakeEntity(
    id: id,
    name: name,
    entityType: entityType,
    categories: categories,
    locations: locations,
    contacts: [for (final phone in phones) fakePhone(phone)],
  );
}

Widget _app(_FakeCloudDirectoryRepository repo) {
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: canonicalDirectoryDetailRouter(
        home: DirectorySearchScreen(repository: repo),
        repository: repo,
      ),
    ),
  );
}

void main() {
  group('W5.4 — W5.3 INTEGRATION', () {
    testWidgets('44. search results render DirectoryProviderCard', (tester) async {
      final entities = [_p(id: 'a', name: 'Alpha Co', entityType: 'supplier')];
      await tester.pumpWidget(_app(_FakeCloudDirectoryRepository(entities)));
      await tester.pumpAndSettle();
      expect(find.byType(DirectoryProviderCard), findsOneWidget);
    });

    testWidgets('45. tapping result opens DirectoryProviderDetailScreen', (tester) async {
      final entities = [
        _p(id: 'a', name: 'Alpha', phones: _defaultPhones(), entityType: 'supplier'),
      ];
      await tester.pumpWidget(_app(_FakeCloudDirectoryRepository(entities)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DirectoryProviderCard));
      await tester.pumpAndSettle();
      expect(find.byType(DirectoryProviderDetailScreen), findsOneWidget);
    });

    testWidgets('46. query engine unchanged (filtering still applies)', (tester) async {
      final entities = [
        _p(id: 'a', name: 'Alpha Steel', entityType: 'supplier'),
        _p(id: 'b', name: 'Beta Co', entityType: 'contractor'),
      ];
      await tester.pumpWidget(_app(_FakeCloudDirectoryRepository(entities)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'steel');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DirectoryProviderCard), findsOneWidget);
      expect(find.text('Alpha Steel'), findsOneWidget);
      expect(find.text('Beta Co'), findsNothing);
    });

    testWidgets('47. text search works through card', (tester) async {
      final entities = [
        _p(id: 'a', name: 'Omega', categories: [fakeCategory('Reinforcement')]),
        _p(id: 'b', name: 'Gamma', categories: [fakeCategory('Formwork')]),
      ];
      await tester.pumpWidget(_app(_FakeCloudDirectoryRepository(entities)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'formwork');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DirectoryProviderCard), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
      expect(find.text('Omega'), findsNothing);
    });

    testWidgets('48. category filter unchanged', (tester) async {
      final entities = [
        _p(id: 'a', name: 'Supplier Co', entityType: 'supplier'),
        _p(id: 'b', name: 'Contractor Co', entityType: 'contractor'),
      ];
      await tester.pumpWidget(_app(_FakeCloudDirectoryRepository(entities)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String?>).first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(CanonicalEntityTypePresentation.arLabel('supplier')).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Supplier Co'), findsOneWidget);
      expect(find.text('Contractor Co'), findsNothing);
    });

    testWidgets('49. location filter unchanged', (tester) async {
      final entities = [
        _p(
          id: 'a',
          name: 'Co A',
          locations: [fakeLocation('adhamiya', regionName: 'الأعظمية')],
        ),
        _p(
          id: 'b',
          name: 'Co B',
          locations: [fakeLocation('mansour', regionName: 'المنصور')],
        ),
      ];
      await tester.pumpWidget(_app(_FakeCloudDirectoryRepository(entities)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String?>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('adhamiya').last);
      await tester.pumpAndSettle();
      expect(find.text('Co A'), findsOneWidget);
      expect(find.text('Co B'), findsNothing);
    });

    testWidgets('50. debounce remains 280ms', (tester) async {
      final entities = [_p(id: 'a', name: 'Alpha Steel')];
      await tester.pumpWidget(_app(_FakeCloudDirectoryRepository(entities)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Alpha Steel'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(DirectoryProviderCard), findsNothing);
    });

    testWidgets('51. source ordering unchanged (stable)', (tester) async {
      final entities = [
        _p(id: 'a', name: 'First', entityType: 'supplier'),
        _p(id: 'b', name: 'Second', entityType: 'contractor'),
      ];
      await tester.pumpWidget(_app(_FakeCloudDirectoryRepository(entities)));
      await tester.pumpAndSettle();
      final cards = tester.widgetList<DirectoryProviderCard>(
        find.byType(DirectoryProviderCard),
      );
      final names = cards.map((c) => c.entity.name).toList();
      expect(names, ['First', 'Second']);
    });

    testWidgets('52. loadAll still called once', (tester) async {
      final repo = _FakeCloudDirectoryRepository([_p(id: 'a', name: 'Alpha')]);
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.loadCalls, 1);
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