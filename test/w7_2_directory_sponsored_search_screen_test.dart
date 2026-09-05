import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/features/directory/domain/directory_repository.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_detail_screen.dart';
import 'package:civilpedia/features/directory/presentation/directory_search_screen.dart';
import 'package:civilpedia/features/directory/presentation/widgets/directory_sponsored_provider_card.dart';
import 'package:civilpedia/features/monetization/domain/entities/advertisement_campaign.dart';
import 'package:civilpedia/features/monetization/domain/monetization_reference.dart';
import 'package:civilpedia/features/monetization/domain/services/campaign_source.dart';
import 'package:civilpedia/features/monetization/domain/value_objects/campaign_destination.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';

const _directorySponsored = 'directory_sponsored';
final _at = DateTime(2026, 3, 15, 12, 0, 0);

MonetizationReference _ref(String id) => MonetizationReference(
      ownerDomain: MonetizationOwners.directory,
      entityType: 'provider',
      entityId: id,
    );

AdvertisementCampaign _campaign({
  required String id,
  bool isEnabled = true,
  String placementKey = _directorySponsored,
  MonetizationReference? subject,
  CampaignDestination? destination,
  String disclosureLabel = 'Sponsored',
}) {
  final s = subject ?? _ref('p-1');
  return AdvertisementCampaign(
    id: id,
    isEnabled: isEnabled,
    placementKey: placementKey,
    subject: s,
    destination: destination ?? CampaignDestination.internal(s),
    disclosureLabel: disclosureLabel,
  );
}

class _FakeCampaignSource implements CampaignSource {
  _FakeCampaignSource(this.result);
  final Future<List<AdvertisementCampaign>> Function() result;

  @override
  Future<List<AdvertisementCampaign>> campaignsFor(String placementKey) {
    return result();
  }
}

class _FakeDirectoryRepository implements DirectoryRepository {
  _FakeDirectoryRepository(this.profiles);
  final List<ServiceBusinessProfile> profiles;

  @override
  Future<List<ServiceBusinessProfile>> loadAll() async {
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
  BaghdadArea baghdadArea = BaghdadArea.unknown,
  VerificationStatus verificationStatus = VerificationStatus.unverified,
}) {
  return ServiceBusinessProfile(
    id: id,
    name: name.isEmpty ? 'Provider $id' : name,
    type: type,
    baghdadArea: baghdadArea,
    verificationStatus: verificationStatus,
  );
}

Widget _app(
  _FakeDirectoryRepository repo, {
  CampaignSource? campaignSource,
}) {
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: DirectorySearchScreen(
        repository: repo,
        campaignSource: campaignSource,
        now: () => _at,
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeDirectoryRepository repo,
  CampaignSource? campaignSource,
}) async {
  await tester.pumpWidget(
    _app(repo, campaignSource: campaignSource ?? _FakeCampaignSource(() async => const [])),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('W7.2 SCREEN — no campaign → no sponsored slot', () {
    testWidgets('A: zero campaigns → no sponsored slot, organic only', (tester) async {
      final repo = _FakeDirectoryRepository([_p(id: 'org-1', name: 'Organic Co')]);
      await _pump(tester, repo: repo);
      expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
      expect(find.text('Organic Co'), findsOneWidget);
    });

    testWidgets('Q: no campaign → no blank sponsored spacing/header', (tester) async {
      final repo = _FakeDirectoryRepository([_p(id: 'org-1', name: 'Organic Co')]);
      await _pump(tester, repo: repo);
      expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
      expect(find.text('Sponsored'), findsNothing);
      expect(find.textContaining('Sponsor'), findsNothing);
    });

    testWidgets('B: source throws → no sponsored slot, organic still renders',
        (tester) async {
      final repo = _FakeDirectoryRepository([_p(id: 'org-1', name: 'Organic Co')]);
      await _pump(
        tester,
        repo: repo,
        campaignSource: _FakeCampaignSource(() async => throw Exception('down')),
      );
      expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
      expect(find.text('Organic Co'), findsOneWidget);
    });

    testWidgets('C: inactive campaign → no sponsored slot', (tester) async {
      final repo = _FakeDirectoryRepository([_p(id: 'p-1'), _p(id: 'org-1', name: 'Organic Co')]);
      await _pump(
        tester,
        repo: repo,
        campaignSource: _FakeCampaignSource(
          () async => [_campaign(id: 'c1', isEnabled: false)],
        ),
      );
      expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
      expect(find.text('Organic Co'), findsOneWidget);
    });
  });

  group('W7.2 SCREEN — one renderable campaign → sponsored slot', () {
    testWidgets('D+E: one eligible renderable → one sponsored slot + disclosed',
        (tester) async {
      final repo = _FakeDirectoryRepository([
        _p(id: 'p-1', name: 'Sponsored Co'),
        _p(id: 'org-1', name: 'Organic Co'),
      ]);
      await _pump(
        tester,
        repo: repo,
        campaignSource: _FakeCampaignSource(() async => [_campaign(id: 'c1')]),
      );
      expect(find.byType(DirectorySponsoredProviderCard), findsOneWidget);
      // Disclosure label visibly rendered.
      expect(find.text('Sponsored'), findsOneWidget);
      // The sponsored card presents the real provider.
      expect(
        find.descendant(
          of: find.byType(DirectorySponsoredProviderCard),
          matching: find.text('Sponsored Co'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('F: sponsored card resolves real profile via loadById', (tester) async {
      final repo = _FakeDirectoryRepository([_p(id: 'p-1', name: 'Real Sponsored Co')]);
      await _pump(
        tester,
        repo: repo,
        campaignSource: _FakeCampaignSource(() async => [_campaign(id: 'c1')]),
      );
      expect(find.byType(DirectorySponsoredProviderCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DirectorySponsoredProviderCard),
          matching: find.text('Real Sponsored Co'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('G: sponsored tap → real DirectoryProviderDetailScreen', (tester) async {
      final repo = _FakeDirectoryRepository([
        _p(id: 'p-1', name: 'Sponsored Co'),
        _p(id: 'org-1', name: 'Organic Co'),
      ]);
      await _pump(
        tester,
        repo: repo,
        campaignSource: _FakeCampaignSource(() async => [_campaign(id: 'c1')]),
      );
      await tester.tap(find.byType(DirectorySponsoredProviderCard));
      await tester.pumpAndSettle();
      expect(find.byType(DirectoryProviderDetailScreen), findsOneWidget);
    });

    testWidgets('J: missing sponsored provider → slot omitted', (tester) async {
      // Campaign references p-1 but repository has no p-1.
      final repo = _FakeDirectoryRepository([_p(id: 'org-1', name: 'Organic Co')]);
      await _pump(
        tester,
        repo: repo,
        campaignSource: _FakeCampaignSource(() async => [_campaign(id: 'c1')]),
      );
      expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
      expect(find.text('Organic Co'), findsOneWidget);
    });

    testWidgets('K: empty disclosure → slot omitted', (tester) async {
      final repo = _FakeDirectoryRepository([_p(id: 'p-1'), _p(id: 'org-1', name: 'Organic Co')]);
      await _pump(
        tester,
        repo: repo,
        campaignSource: _FakeCampaignSource(
          () async => [_campaign(id: 'c1', disclosureLabel: '  ')],
        ),
      );
      expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
      expect(find.text('Organic Co'), findsOneWidget);
    });

    testWidgets('L: external destination → slot omitted', (tester) async {
      final repo = _FakeDirectoryRepository([_p(id: 'org-1', name: 'Organic Co')]);
      await _pump(
        tester,
        repo: repo,
        campaignSource: _FakeCampaignSource(
          () async => [
            _campaign(
              id: 'c1',
              destination: CampaignDestination.external('https://example.com'),
            ),
          ],
        ),
      );
      expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
      expect(find.text('Organic Co'), findsOneWidget);
    });
  });

  group('W7.2 SCREEN — multiple eligible campaigns', () {
    testWidgets('N: two renderable → exactly ONE slot, source-order first wins',
        (tester) async {
      final repo = _FakeDirectoryRepository([
        _p(id: 'p-1', name: 'First Sponsored'),
        _p(id: 'p-2', name: 'Second Sponsored'),
      ]);
      await _pump(
        tester,
        repo: repo,
        campaignSource: _FakeCampaignSource(
          () async => [
            _campaign(id: 'c-a', subject: _ref('p-1')),
            _campaign(id: 'c-b', subject: _ref('p-2')),
          ],
        ),
      );
      expect(find.byType(DirectorySponsoredProviderCard), findsOneWidget);
      // First source-order wins at the W7.2 surface: the sponsored card shows
      // ONLY 'First Sponsored', never 'Second Sponsored'.
      expect(
        find.descendant(
          of: find.byType(DirectorySponsoredProviderCard),
          matching: find.text('First Sponsored'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(DirectorySponsoredProviderCard),
          matching: find.text('Second Sponsored'),
        ),
        findsNothing,
      );
    });

    testWidgets('M: first unrenderable, second renderable → second renders',
        (tester) async {
      final repo = _FakeDirectoryRepository([
        _p(id: 'p-1', name: 'Good Sponsored'),
      ]);
      await _pump(
        tester,
        repo: repo,
        campaignSource: _FakeCampaignSource(
          () async => [
            _campaign(id: 'c-empty', disclosureLabel: ' '),
            _campaign(id: 'c-missing', subject: _ref('p-nope')),
            _campaign(id: 'c-good', subject: _ref('p-1')),
          ],
        ),
      );
      expect(find.byType(DirectorySponsoredProviderCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DirectorySponsoredProviderCard),
          matching: find.text('Good Sponsored'),
        ),
        findsOneWidget,
      );
    });
  });

  group('W7.2 SCREEN — verification independence', () {
    testWidgets('H: sponsored + unverified → disclosure AND real unverified badge',
        (tester) async {
      final repo = _FakeDirectoryRepository([
        _p(id: 'p-1', name: 'Sponsored Co', verificationStatus: VerificationStatus.unverified),
      ]);
      await _pump(
        tester,
        repo: repo,
        campaignSource: _FakeCampaignSource(() async => [_campaign(id: 'c1')]),
      );
      // Disclosure label clearly rendered (sponsorship must not imply
      // verification and must not be hidden).
      expect(find.text('Sponsored'), findsOneWidget);
      // The REAL unverified badge is rendered inside the sponsored card (Arabic
      // default label 'غير موثّق'). Sponsorship does NOT grant verification, so
      // the badge remains unverified.
      expect(
        find.descendant(
          of: find.byType(DirectorySponsoredProviderCard),
          matching: find.text('غير موثّق'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('I: verified organic provider → no sponsorship without campaign',
        (tester) async {
      final repo = _FakeDirectoryRepository([
        _p(id: 'org-1', name: 'Verified Organic', verificationStatus: VerificationStatus.verified),
      ]);
      await _pump(tester, repo: repo);
      expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
      expect(find.text('موثّق'), findsOneWidget);
      expect(find.text('Sponsored'), findsNothing);
    });
  });

  group('W7.2 SCREEN — organic/sponsored separation', () {
    testWidgets('O: sponsored provider also organic → appears in BOTH, order unchanged',
        (tester) async {
      final repo = _FakeDirectoryRepository([
        _p(id: 'a', name: 'Alpha Organic'),
        _p(id: 'p-1', name: 'Dual Co'),
        _p(id: 'b', name: 'Beta Organic'),
      ]);
      await _pump(
        tester,
        repo: repo,
        campaignSource: _FakeCampaignSource(
          () async => [_campaign(id: 'c1', subject: _ref('p-1'))],
        ),
      );
      // Sponsored slot + organic result.
      expect(find.byType(DirectorySponsoredProviderCard), findsOneWidget);
      expect(find.text('Dual Co'), findsNWidgets(2));
      // Organic peers still present and ordered.
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

    testWidgets('P: sponsored not matching organic query is still shown in slot',
        (tester) async {
      final repo = _FakeDirectoryRepository([
        _p(id: 'p-1', name: 'Sponsored Co'),
        _p(id: 'org-1', name: 'Organic Co'),
      ]);
      await _pump(
        tester,
        repo: repo,
        campaignSource: _FakeCampaignSource(() async => [_campaign(id: 'c1')]),
      );
      // Type a query that matches ONLY the organic provider.
      await tester.enterText(find.byType(TextField), 'Organic');
      await tester.pump(const Duration(milliseconds: 300));
      // Sponsored slot still present (not gated by organic query).
      expect(find.byType(DirectorySponsoredProviderCard), findsOneWidget);
      expect(find.text('Sponsored Co'), findsOneWidget);
      // Organic result filtered to the matching provider.
      expect(find.text('Organic Co'), findsOneWidget);
    });

    testWidgets(
        'Q-ZERO: zero organic results (category filter) + sponsored → sponsored renders',
        (tester) async {
      final repo = _FakeDirectoryRepository([
        _p(id: 'p-1', name: 'Sponsored Co'),
        _p(id: 'org-1', name: 'Other Co', type: BusinessType.engineeringOffice),
      ]);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: DirectorySearchScreen(
              repository: repo,
              campaignSource:
                  _FakeCampaignSource(() async => [_campaign(id: 'c1')]),
              now: () => _at,
              initialCategory: BusinessType.materialShop,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Organic filter (materialShop) returns zero matches but directory has
      // providers for other categories — sponsored slot MUST still render.
      expect(find.byType(DirectorySponsoredProviderCard), findsOneWidget);
      expect(find.text('Sponsored'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DirectorySponsoredProviderCard),
          matching: find.text('Sponsored Co'),
        ),
        findsOneWidget,
      );
    });
  });
}
