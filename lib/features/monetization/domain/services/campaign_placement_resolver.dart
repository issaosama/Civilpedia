import '../entities/advertisement_campaign.dart';
import '../entities/sponsored_placement.dart';
import '../value_objects/ad_placement_request.dart';

/// W7.1 — Pure domain resolver/evaluator for sponsored placement eligibility.
///
/// Implements the M6 §27 contract:
///
///   AdPlacementRequest → Monetization → active eligible campaign(s)
///                      → SponsoredPlacement projection
///
/// with the hard invariant (M1 §11 / M3 §16 / M4 §10 / M8 §13):
///
///   **no active eligible campaign → NO SponsoredPlacement**
///
/// Eligibility is resolved as pure domain logic with an INJECTED evaluation
/// time `at` — the resolver never calls `DateTime.now()` internally, so it is
/// deterministic and fully testable (M8 §21 / W7.1 §5).
///
/// Failure isolation (M8 §14 / W7.1 §14): a campaign whose eligibility cannot be
/// established yields NO placement. This never throws into an organic caller —
/// a caller resolving an unsupported/malformed candidate simply gets a safe
/// empty result.
///
/// SELECTION POLICY (M8 §6): the authoritative docs do NOT define what happens
/// when MORE THAN ONE campaign is eligible for the same request — no priority,
/// ordering, rotation, first-match, or bidding rule is assigned. This resolver
/// therefore does NOT pick a winner. [evaluate] resolves a single given
/// campaign; [evaluateAll] reports the deterministic set of eligible placements
/// in input order WITHOUT choosing among them. Choosing among multiple eligible
/// campaigns is an ARCHITECT DECISION REQUIRED and is intentionally deferred.
class CampaignPlacementResolver {
  const CampaignPlacementResolver();

  /// Resolves the sponsored placement for ONE candidate campaign at time [at],
  /// or `null` when that campaign is not eligible for [request].
  ///
  /// A campaign is eligible when ALL hold:
  /// - [AdvertisementCampaign.isEnabled] is true;
  /// - the campaign is within its active period at [at] (open-ended if the
  ///   corresponding bound is null, so unbounded ⇒ always within);
  /// - the campaign's [AdvertisementCampaign.placementKey] matches the request;
  /// - the campaign's subject reference is valid (never empty identity).
  SponsoredPlacement? evaluate(
    AdPlacementRequest request,
    AdvertisementCampaign campaign, {
    required DateTime at,
  }) {
    if (!_isEligible(request, campaign, at)) return null;
    return SponsoredPlacement(
      placementKey: campaign.placementKey,
      campaignId: campaign.id,
      subject: campaign.subject,
      destination: campaign.destination,
      sponsorshipType: campaign.sponsorshipType,
      disclosureLabel: campaign.disclosureLabel,
      servedAt: at,
    );
  }

  /// Reports the set of eligible placements among [campaigns] at [at], in input
  /// order. If none is eligible the result is empty.
  ///
  /// Deterministic and order-preserving. Does NOT select among multiple
  /// eligible campaigns (selection policy is unresolved — see class docs).
  List<SponsoredPlacement> evaluateAll(
    AdPlacementRequest request,
    List<AdvertisementCampaign> campaigns, {
    required DateTime at,
  }) {
    final result = <SponsoredPlacement>[];
    for (final campaign in campaigns) {
      final placement = evaluate(request, campaign, at: at);
      if (placement != null) result.add(placement);
    }
    return result;
  }

  bool _isEligible(
    AdPlacementRequest request,
    AdvertisementCampaign campaign,
    DateTime at,
  ) {
    if (!campaign.isEnabled) return false;
    if (campaign.placementKey != request.placementKey) return false;
    if (!campaign.subject.isValid) return false;
    final startsAt = campaign.startsAt;
    if (startsAt != null && at.isBefore(startsAt)) return false;
    final endsAt = campaign.endsAt;
    if (endsAt != null && at.isAfter(endsAt)) return false;
    return true;
  }
}
