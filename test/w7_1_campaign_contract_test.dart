import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/features/monetization/domain/entities/advertisement_campaign.dart';
import 'package:civilpedia/features/monetization/domain/monetization_reference.dart';
import 'package:civilpedia/features/monetization/domain/services/campaign_placement_resolver.dart';
import 'package:civilpedia/features/monetization/domain/value_objects/ad_placement_request.dart';
import 'package:civilpedia/features/monetization/domain/value_objects/campaign_destination.dart';

const _homeBanner = 'home_banner';
const _directorySponsored = 'directory_sponsored';

final _subject = MonetizationReference(
  ownerDomain: MonetizationOwners.directory,
  entityType: 'provider',
  entityId: 'provider-42',
);

AdvertisementCampaign _campaign({
  String id = 'campaign-1',
  bool isEnabled = false,
  DateTime? startsAt,
  DateTime? endsAt,
  String placementKey = _homeBanner,
  MonetizationReference? subject,
  String sponsorshipType = 'sponsored_banner',
  String disclosureLabel = 'Sponsored',
}) {
  return AdvertisementCampaign(
    id: id,
    isEnabled: isEnabled,
    startsAt: startsAt,
    endsAt: endsAt,
    placementKey: placementKey,
    subject: subject ?? _subject,
    destination: CampaignDestination.internal(_subject),
    sponsorshipType: sponsorshipType,
    disclosureLabel: disclosureLabel,
  );
}

void main() {
  final resolver = CampaignPlacementResolver();
  final request = AdPlacementRequest(placementKey: _homeBanner);
  final at = DateTime(2026, 3, 15, 12, 0, 0);

  group('W7.1 — no campaign ⇒ no sponsored placement', () {
    test('A: no campaigns → no SponsoredPlacement', () {
      expect(
        resolver.evaluateAll(request, const [], at: at),
        isEmpty,
      );
    });

    test('B: inactive (disabled) campaign → no SponsoredPlacement', () {
      final campaign = _campaign(isEnabled: false);
      expect(resolver.evaluate(request, campaign, at: at), isNull);
    });

    test(
      'C: campaign outside its valid active period → no SponsoredPlacement',
      () {
        final notStarted = _campaign(
          isEnabled: true,
          startsAt: DateTime(2026, 4, 1),
          endsAt: DateTime(2026, 5, 1),
        );
        expect(resolver.evaluate(request, notStarted, at: at), isNull);

        final expired = _campaign(
          isEnabled: true,
          startsAt: DateTime(2026, 1, 1),
          endsAt: DateTime(2026, 2, 1),
        );
        expect(resolver.evaluate(request, expired, at: at), isNull);
      },
    );

    test('D: campaign for a different placement → no SponsoredPlacement', () {
      final otherPlacement = _campaign(
        isEnabled: true,
        placementKey: _directorySponsored,
      );
      expect(
        resolver.evaluate(request, otherPlacement, at: at),
        isNull,
      );
    });

    test('I: malformed/ineligible candidate cannot fabricate a placement', () {
      // Empty subject identity → subject invalid → no placement.
      final emptySubject = _campaign(
        isEnabled: true,
        subject: const MonetizationReference(
          ownerDomain: '',
          entityType: 'provider',
          entityId: 'provider-42',
        ),
      );
      expect(resolver.evaluate(request, emptySubject, at: at), isNull);

      // Placement mismatch + disabled: still no placement.
      final disabledOther = _campaign(
        isEnabled: false,
        placementKey: _directorySponsored,
      );
      expect(resolver.evaluate(request, disabledOther, at: at), isNull);
    });
  });

  group('W7.1 — active eligible campaign ⇒ placement', () {
    test('E: active eligible campaign → SponsoredPlacement', () {
      final campaign = _campaign(isEnabled: true);
      final placement = resolver.evaluate(request, campaign, at: at);

      expect(placement, isNotNull);
      expect(placement!.placementKey, _homeBanner);
    });

    test('F: SponsoredPlacement preserves campaign identity', () {
      final campaign = _campaign(id: 'campaign-77', isEnabled: true);
      final placement = resolver.evaluate(request, campaign, at: at);

      expect(placement, isNotNull);
      expect(placement!.campaignId, 'campaign-77');
    });

    test(
      'G: SponsoredPlacement references the subject identity, never clones it',
      () {
        final campaign = _campaign(isEnabled: true);
        final placement = resolver.evaluate(request, campaign, at: at);

        expect(placement, isNotNull);
        // It carries the stable reference, not a Directory entity copy.
        expect(placement!.subject, equals(_subject));
        expect(placement.subject.id, 'directory:provider:provider-42');
      },
    );

    test('placement preserves disclosure metadata and constrained destination',
        () {
      final campaign = _campaign(
        isEnabled: true,
        sponsorshipType: 'sponsored_offer',
        disclosureLabel: 'مُموّل',
      );
      final placement = resolver.evaluate(request, campaign, at: at);

      expect(placement, isNotNull);
      expect(placement!.sponsorshipType, 'sponsored_offer');
      expect(placement.disclosureLabel, 'مُموّل');
      expect(placement.destination.kind, CampaignDestinationKind.internal);
      expect(placement.destination.reference, _subject);
    });
  });

  group('W7.1 — deterministic evaluation time', () {
    test('H: injected time drives eligibility, with no DateTime.now() inside',
        () {
      // Campaign active over [t0, t2]; a time inside (t1) resolves, outside (t3)
      // does not — same resolver, only the injected `at` changes.
      final campaign = _campaign(
        isEnabled: true,
        startsAt: DateTime(2026, 3, 1),
        endsAt: DateTime(2026, 3, 31),
      );

      final inside = DateTime(2026, 3, 15);
      final outside = DateTime(2026, 4, 15);

      expect(resolver.evaluate(request, campaign, at: inside), isNotNull);
      expect(resolver.evaluate(request, campaign, at: outside), isNull);

      // The served projection records the exact injected time.
      final resolved = resolver.evaluate(request, campaign, at: inside);
      expect(resolved!.servedAt, inside);
    });

    test('unbounded period is eligible whenever enabled and placement matches',
        () {
      final openEnded = _campaign(
        isEnabled: true,
        startsAt: null,
        endsAt: null,
      );
      expect(
        resolver.evaluate(request, openEnded, at: DateTime(2020, 1, 1)),
        isNotNull,
      );
      expect(
        resolver.evaluate(request, openEnded, at: DateTime(2999, 1, 1)),
        isNotNull,
      );
    });
  });

  group('W7.1 — failure isolation', () {
    test('J: no monetization result never throws into the caller', () {
      // No campaigns, a disabled campaign, an out-of-period campaign, and a
      // malformed subject all resolve to a safe empty result — no exception.
      final campaigns = [
        AdvertisementCampaign(
          id: 'disabled',
          placementKey: _homeBanner,
          subject: _subject,
          destination: CampaignDestination.internal(_subject),
        ),
        _campaign(
          isEnabled: true,
          startsAt: DateTime(2030, 1, 1),
          subject: const MonetizationReference(
            ownerDomain: 'directory',
            entityType: 'provider',
            entityId: '',
          ),
        ),
      ];

      expect(resolver.evaluateAll(request, campaigns, at: at), isEmpty);
      // Individual resolution also returns null rather than throwing.
      for (final c in campaigns) {
        expect(
          () => resolver.evaluate(request, c, at: at),
          returnsNormally,
        );
      }
    });
  });

  group('W7.1 — multiple eligible campaigns (selection policy unresolved)', () {
    test(
      'evaluateAll reports the deterministic eligible set in input order, '
      'without picking a winner or fabricating a placement',
      () {
        final eligibleA = _campaign(id: 'a', isEnabled: true);
        final ineligible = _campaign(id: 'disabled');
        final eligibleB = _campaign(id: 'b', isEnabled: true);

        final placements = resolver.evaluateAll(
          request,
          [eligibleA, ineligible, eligibleB],
          at: at,
        );

        // Reports only the eligible ones, preserving input order.
        expect(placements.map((p) => p.campaignId).toList(), ['a', 'b']);
      },
    );
  });
}
