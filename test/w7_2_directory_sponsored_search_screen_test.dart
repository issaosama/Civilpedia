import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/features/directory/domain/canonical_directory_entity.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_detail_screen.dart';
import 'package:civilpedia/features/directory/presentation/directory_search_screen.dart';
import 'package:civilpedia/features/directory/presentation/widgets/directory_sponsored_provider_card.dart';
import 'package:civilpedia/features/monetization/domain/entities/sponsored_placement.dart';
import 'package:civilpedia/features/monetization/domain/monetization_reference.dart';
import 'package:civilpedia/features/monetization/domain/value_objects/campaign_destination.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/features/saved/domain/saved_item_reference.dart';
import 'package:civilpedia/features/saved/domain/saved_reference_store.dart';
import 'package:civilpedia/routes/app_routes.dart';

import 'helpers/canonical_directory_test_helpers.dart';

const _directorySponsored = 'directory_sponsored';
final _at = DateTime(2026, 3, 15, 12, 0, 0);

MonetizationReference _ref(String id) => MonetizationReference(
      ownerDomain: MonetizationOwners.directory,
      entityType: 'provider',
      entityId: id,
    );

SponsoredPlacement _placement({
  String disclosureLabel = 'Sponsored',
  MonetizationReference? subject,
}) {
  final s = subject ?? _ref('p-1');
  return SponsoredPlacement(
    placementKey: _directorySponsored,
    campaignId: 'c1',
    subject: s,
    destination: CampaignDestination.internal(s),
    sponsorshipType: 'sponsorship',
    disclosureLabel: disclosureLabel,
    servedAt: _at,
  );
}

/// In-memory fake [SavedReferenceStore] so detail navigation in widget tests
/// never touches real persistence.
class _FakeSavedStore implements SavedReferenceStore {
  final List<SavedItemReference> _refs = [];

  @override
  Future<List<SavedItemReference>> loadAll() async => List.of(_refs);

  @override
  Future<bool> contains(String referenceId) async =>
      _refs.any((r) => r.id == referenceId);

  @override
  Future<void> save(SavedItemReference reference) async {
    if (!_refs.any((r) => r.id == reference.id)) _refs.add(reference);
  }

  @override
  Future<void> remove(String referenceId) async {
    _refs.removeWhere((r) => r.id == referenceId);
  }
}

/// V1-R05 sponsored surface harness: [DirectorySponsoredProviderCard] directly,
/// with the tap wired to the real canonical `/directory/entity/:id` route push
/// that the production owning surface performs (canonical-ID resolution).
Widget _sponsoredCardApp(CanonicalDirectoryEntity entity, {VoidCallback? onTap}) {
  final fakeRepo = FakeCloudDirectoryRepository([entity]);
  final savedStore = _FakeSavedStore();
  final card = Builder(
    builder: (context) => DirectorySponsoredProviderCard(
      placement: _placement(),
      entity: entity,
      onTap: onTap ??
          () {
            context.push(
              AppRoutes.directoryEntityDetailFor(entity.id),
              extra: entity,
            );
          },
    ),
  );
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: canonicalDirectoryDetailRouter(
        home: Scaffold(body: card),
        repository: fakeRepo,
        savedReferenceStore: savedStore,
      ),
    ),
  );
}

Widget _searchApp(
  FakeCloudDirectoryRepository repo, {
  String? initialEntityType,
}) {
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: DirectorySearchScreen(
        repository: repo,
        initialEntityType: initialEntityType,
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeCloudDirectoryRepository repo,
  String? initialEntityType,
}) async {
  await tester.pumpWidget(
    _searchApp(repo, initialEntityType: initialEntityType),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('W7.2 SPONSORED CARD — disclosure & entity', () {
    testWidgets('D+E: one renderable placement → disclosure + real entity',
        (tester) async {
      final entity = fakeEntity(id: 'p-1', name: 'Sponsored Co');
      await tester.pumpWidget(_sponsoredCardApp(entity));
      expect(find.byType(DirectorySponsoredProviderCard), findsOneWidget);
      // Disclosure label visibly rendered.
      expect(find.text('Sponsored'), findsOneWidget);
      // The sponsored card presents the real entity.
      expect(find.text('Sponsored Co'), findsOneWidget);
    });

    testWidgets('F: sponsored card resolves real entity', (tester) async {
      final entity = fakeEntity(id: 'p-1', name: 'Real Sponsored Co');
      await tester.pumpWidget(_sponsoredCardApp(entity));
      expect(find.byType(DirectorySponsoredProviderCard), findsOneWidget);
      expect(find.text('Real Sponsored Co'), findsOneWidget);
    });

    testWidgets('G: sponsored tap → real DirectoryProviderDetailScreen',
        (tester) async {
      final entity = fakeEntity(id: 'p-1', name: 'Sponsored Co');
      await tester.pumpWidget(_sponsoredCardApp(entity));
      await tester.tap(find.text('Sponsored Co'));
      await tester.pumpAndSettle();
      expect(find.byType(DirectoryProviderDetailScreen), findsOneWidget);
    });

    testWidgets('H: sponsored + unverified → disclosure AND real unverified badge',
        (tester) async {
      final entity = fakeEntity(
        id: 'p-1',
        name: 'Sponsored Co',
        verificationStatus: VerificationStatus.unverified,
      );
      await tester.pumpWidget(_sponsoredCardApp(entity));
      // Disclosure label clearly rendered (sponsorship must not imply
      // verification and must not be hidden).
      expect(find.text('Sponsored'), findsOneWidget);
      // The REAL unverified badge is rendered inside the sponsored card (Arabic
      // default label 'غير موثّق'). Sponsorship does NOT grant verification, so
      // the badge remains unverified.
      expect(find.text('غير موثّق'), findsOneWidget);
    });
  });

  group('W7.2 SCREEN — organic rendering', () {
    testWidgets('A: organic only → no sponsored slot, organic renders',
        (tester) async {
      final repo = FakeCloudDirectoryRepository([
        fakeEntity(id: 'org-1', name: 'Organic Co'),
      ]);
      await _pump(tester, repo: repo);
      expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
      expect(find.text('Organic Co'), findsOneWidget);
    });

    testWidgets('Q: nothing sponsored renders without a campaign',
        (tester) async {
      final repo = FakeCloudDirectoryRepository([
        fakeEntity(id: 'org-1', name: 'Organic Co'),
      ]);
      await _pump(tester, repo: repo);
      expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
      expect(find.text('Sponsored'), findsNothing);
      expect(find.textContaining('Sponsor'), findsNothing);
    });

    testWidgets('I: verified organic provider → verified badge, no sponsorship',
        (tester) async {
      final repo = FakeCloudDirectoryRepository([
        fakeEntity(
          id: 'org-1',
          name: 'Verified Organic',
          verificationStatus: VerificationStatus.verified,
        ),
      ]);
      await _pump(tester, repo: repo);
      expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
      expect(find.text('موثّق'), findsOneWidget);
      expect(find.text('Sponsored'), findsNothing);
    });

    testWidgets('O: organic providers render in order, unchanged',
        (tester) async {
      final repo = FakeCloudDirectoryRepository([
        fakeEntity(id: 'a', name: 'Alpha Organic'),
        fakeEntity(id: 'b', name: 'Beta Organic'),
      ]);
      await _pump(tester, repo: repo);
      expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
      expect(find.text('Alpha Organic'), findsOneWidget);
      // Scroll the (lazy) list to reveal the bottom organic card before
      // asserting it exists.
      await tester.scrollUntilVisible(
        find.text('Beta Organic'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Beta Organic'), findsOneWidget);
    });

    testWidgets('P: search filters organic results', (tester) async {
      final repo = FakeCloudDirectoryRepository([
        fakeEntity(id: 'p-1', name: 'Sponsored Co'),
        fakeEntity(id: 'org-1', name: 'Organic Co'),
      ]);
      await _pump(tester, repo: repo);
      // Type a query that matches ONLY the organic provider.
      await tester.enterText(find.byType(TextField), 'Organic');
      await tester.pump(const Duration(milliseconds: 300));
      // Organic result filtered to the matching provider.
      expect(find.text('Organic Co'), findsOneWidget);
      expect(find.text('Sponsored Co'), findsNothing);
    });

    testWidgets('Q-ZERO: entity-type filter works over canonical data',
        (tester) async {
      final repo = FakeCloudDirectoryRepository([
        fakeEntity(id: 'p-1', name: 'Supplier Co', entityType: 'supplier'),
        fakeEntity(id: 'org-1', name: 'Store Co', entityType: 'store'),
      ]);
      await _pump(
        tester,
        repo: repo,
        initialEntityType: 'supplier',
      );
      expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
      expect(find.text('Supplier Co'), findsOneWidget);
      expect(find.text('Store Co'), findsNothing);
    });
  });
}