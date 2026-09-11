import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/features/directory/domain/canonical_directory_entity.dart';
import 'package:civilpedia/features/directory/domain/cloud_directory_repository.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_detail_screen.dart';
import 'package:civilpedia/features/directory/presentation/directory_search_screen.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart' show VerificationStatus;
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:civilpedia/routes/app_routes.dart';

import 'helpers/canonical_directory_test_helpers.dart';

class _FakeCloudDirectoryRepository implements CloudDirectoryRepository {
  int loadCalls = 0;
  final List<CanonicalDirectoryEntity> entities;
  final Object? throwOnLoad;
  final Future<void>? pendingFirstLoad;

  _FakeCloudDirectoryRepository(
    this.entities, {
    this.throwOnLoad,
  }) : pendingFirstLoad = null;

  _FakeCloudDirectoryRepository.delayed(
    this.entities,
    this.pendingFirstLoad,
  ) : throwOnLoad = null;

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
    if (pendingFirstLoad != null && loadCalls == 1) {
      await pendingFirstLoad!;
    }
    if (throwOnLoad != null) {
      return const DirectoryLoadResult(state: DirectoryLoadState.error);
    }
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

Widget _app(_FakeCloudDirectoryRepository repo, {String? initialEntityType}) {
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: canonicalDirectoryDetailRouter(
        home: DirectorySearchScreen(
          repository: repo,
          initialEntityType: initialEntityType,
        ),
        repository: repo,
      ),
    ),
  );
}

Future<_FakeCloudDirectoryRepository> _pump(
  WidgetTester tester, {
  List<CanonicalDirectoryEntity> entities = const [],
  String? initialEntityType,
  Object? throwOnLoad,
}) async {
  final repo = _FakeCloudDirectoryRepository(entities, throwOnLoad: throwOnLoad);
  await tester.pumpWidget(_app(repo, initialEntityType: initialEntityType));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('W5.3 SCREEN — load & states', () {
    testWidgets('28. screen loads through CloudDirectoryRepository', (tester) async {
      final repo = await _pump(tester);
      expect(repo.loadCalls, 1);
      expect(find.byType(DirectorySearchScreen), findsOneWidget);
    });

    testWidgets('29. repository load called once', (tester) async {
      final repo = await _pump(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.loadCalls, 1);
    });

    testWidgets('30. initial loading state works', (tester) async {
      final completer = Completer<void>();
      final repo = _FakeCloudDirectoryRepository.delayed(const [], completer.future);
      await tester.pumpWidget(_app(repo));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('31. browse mode renders loaded entities', (tester) async {
      final entities = [
        _p(id: 'a', name: 'Company A', entityType: 'supplier'),
        _p(id: 'b', name: 'Company B', entityType: 'contractor'),
      ];
      await _pump(tester, entities: entities);
      expect(find.text('Company A'), findsOneWidget);
      expect(find.text('Company B'), findsOneWidget);
    });

    testWidgets('32. initialEntityType preselects correct entity type', (tester) async {
      final entities = [
        _p(id: 'a', name: 'Supplier Co', entityType: 'supplier', locations: [fakeLocation('karrada', regionName: 'كرادة')]),
        _p(id: 'b', name: 'Contractor Co', entityType: 'contractor', locations: [fakeLocation('karrada', regionName: 'كرادة')]),
      ];
      await _pump(tester, entities: entities, initialEntityType: 'supplier');
      expect(find.text('Supplier Co'), findsOneWidget);
      expect(find.text('Contractor Co'), findsNothing);
    });

    testWidgets('39. empty repository shows empty-directory state', (tester) async {
      await _pump(tester, entities: const []);
      expect(find.text(Ar.directoryEmptyDirectory), findsOneWidget);
    });

    testWidgets('40. non-empty repo + zero matches shows no-results state', (tester) async {
      final entities = [_p(id: 'a', name: 'Alpha Co')];
      await _pump(tester, entities: entities);
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
      final entities = [
        _p(id: 'a', name: 'Alpha Steel', entityType: 'supplier'),
        _p(id: 'b', name: 'Beta Materials', entityType: 'contractor'),
      ];
      await _pump(tester, entities: entities);
      await tester.enterText(find.byType(TextField), 'steel');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Alpha Steel'), findsOneWidget);
      expect(find.text('Beta Materials'), findsNothing);
    });

    testWidgets('34. debounce behavior works (single re-filter after pause)', (tester) async {
      final entities = [_p(id: 'a', name: 'Alpha Steel')];
      await _pump(tester, entities: entities);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Alpha Steel'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(Ar.directoryNoResults), findsOneWidget);
    });
  });

  group('W5.3 SCREEN — filters', () {
    testWidgets('35. category selection filters immediately', (tester) async {
      final entities = [
        _p(id: 'a', name: 'Supplier Co', entityType: 'supplier'),
        _p(id: 'b', name: 'Contractor Co', entityType: 'contractor'),
      ];
      await _pump(tester, entities: entities);
      await tester.tap(
        find.byType(DropdownButtonFormField<String?>).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.directoryTypeSupplier).last);
      await tester.pumpAndSettle();
      expect(find.text('Supplier Co'), findsOneWidget);
      expect(find.text('Contractor Co'), findsNothing);
    });

    testWidgets('36. location selection filters immediately', (tester) async {
      final entities = [
        _p(id: 'a', name: 'Co A', locations: [fakeLocation('adhamiya', regionName: 'الأعظمية')]),
        _p(id: 'b', name: 'Co B', locations: [fakeLocation('mansour', regionName: 'المنصور')]),
      ];
      await _pump(tester, entities: entities);
      await tester.tap(find.byType(DropdownButtonFormField<String?>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('adhamiya').last);
      await tester.pumpAndSettle();
      expect(find.text('Co A'), findsOneWidget);
      expect(find.text('Co B'), findsNothing);
    });

    testWidgets('37. clearing category returns all', (tester) async {
      final entities = [
        _p(id: 'a', name: 'Supplier Co', entityType: 'supplier'),
        _p(id: 'b', name: 'Contractor Co', entityType: 'contractor'),
      ];
      await _pump(tester, entities: entities, initialEntityType: 'supplier');
      expect(find.text('Contractor Co'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<String?>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.directoryFilterAll).last);
      await tester.pumpAndSettle();
      expect(find.text('Contractor Co'), findsOneWidget);
      expect(find.text('Supplier Co'), findsOneWidget);
    });

    testWidgets('38. clearing location returns all', (tester) async {
      final entities = [
        _p(id: 'a', name: 'Co A', locations: [fakeLocation('adhamiya', regionName: 'الأعظمية')]),
        _p(id: 'b', name: 'Co B', locations: [fakeLocation('mansour', regionName: 'المنصور')]),
      ];
      await _pump(tester, entities: entities);
      await tester.tap(find.byType(DropdownButtonFormField<String?>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('adhamiya').last);
      await tester.pumpAndSettle();
      expect(find.text('Co A'), findsOneWidget);
      expect(find.text('Co B'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<String?>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.directoryFilterAll).last);
      await tester.pumpAndSettle();
      expect(find.text('Co A'), findsOneWidget);
      expect(find.text('Co B'), findsOneWidget);
    });
  });

  group('W5.3 SCREEN — result presentation', () {
    testWidgets('41. no result count displayed', (tester) async {
      final entities = [
        _p(id: 'a', name: 'Alpha Co', entityType: 'supplier'),
        _p(id: 'b', name: 'Beta Co', entityType: 'contractor'),
      ];
      await _pump(tester, entities: entities);
      expect(find.textContaining('results'), findsNothing);
      expect(find.textContaining('نتائج'), findsNothing);
    });

    testWidgets('42. result row shows name', (tester) async {
      final entities = [_p(id: 'a', name: 'Alpha Steel')];
      await _pump(tester, entities: entities);
      expect(find.text('Alpha Steel'), findsOneWidget);
    });

    testWidgets('43. result row shows localized entity type', (tester) async {
      final entities = [_p(id: 'a', name: 'Alpha', entityType: 'supplier')];
      await _pump(tester, entities: entities);
      expect(find.text(Ar.directoryTypeSupplier), findsOneWidget);
    });

    testWidgets('44. result row does not show contact', (tester) async {
      final entities = [
        _p(id: 'a', name: 'Alpha', contacts: [fakePhone('07701234567'), fakeWhatsApp('07801234567')]),
      ];
      await _pump(tester, entities: entities);
      expect(find.text('07701234567'), findsNothing);
      expect(find.text('07801234567'), findsNothing);
      expect(find.byIcon(Icons.phone), findsNothing);
    });

    testWidgets('45. result row shows verification badge but filter is absent (W5.5)', (tester) async {
      final entities = [
        _p(id: 'a', name: 'Alpha', verificationStatus: VerificationStatus.verified),
      ];
      await _pump(tester, entities: entities);
      expect(find.text('موثّق'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.text('Verified only'), findsNothing);
      expect(find.text('مراجعة'), findsNothing);
    });

    testWidgets('46. result row does not show Saved', (tester) async {
      final entities = [_p(id: 'a', name: 'Alpha')];
      await _pump(tester, entities: entities);
      expect(find.byIcon(Icons.bookmark), findsNothing);
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
    });

    testWidgets('47. result navigates to provider detail (W5.4)', (tester) async {
      final entities = [_p(id: 'a', name: 'Alpha Co')];
      await _pump(tester, entities: entities);
      await tester.tap(find.text('Alpha Co'));
      await tester.pumpAndSettle();
      expect(find.byType(DirectoryProviderDetailScreen), findsOneWidget);
    });
  });

  group('W5.3 SCREEN — boundaries', () {
    test('48. no Global Search integration', () {
      expect(Ar.directorySearchTitle, isNotEmpty);
      expect(En.directorySearchTitle, 'Search Directory');
    });

    test('49. no permanent Directory route declared', () {
      expect(AppRoutes.search, isNot(contains('/directory')));
      expect(DirectorySearchScreen, isNotNull);
    });

    testWidgets('51. shell destinations = W6.3 target shell', (tester) async {
      final routes = kShellDestinations.map((d) => d.route).toList();
      expect(routes, [
        AppRoutes.home,
        AppRoutes.encyclopedia,
        AppRoutes.tools,
        AppRoutes.projects,
        AppRoutes.directory,
      ]);
      expect(find.byType(DirectorySearchScreen), findsNothing);
    });
  });
}
