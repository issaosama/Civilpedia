import '../monetization_reference.dart';
import '../value_objects/ad_placement_request.dart';
import '../value_objects/campaign_destination.dart';

/// W7.1 — An advertisement campaign: the Monetization-owned sponsorship record.
///
/// Authoritative ownership (M4 §10): Monetization owns the Campaign, its
/// placement, sponsorship period/state, and sponsorship type. The sponsored
/// **subject** is referenced, never duplicated — [subject] is a
/// [MonetizationReference] to the real Directory entity (sponsored ≠ second
/// entity, M6 §13; M4 §10 `Directory Supplier + Monetization Sponsorship`).
///
/// Campaign identity is [id], which is distinct from and never reuses the
/// subject's identity. A single [subject] may carry only one sponsorship
/// *relationship* here — this entity models one campaign, not a Directory copy.
///
/// Eligibility-relevant state (query-able purely): [isEnabled], the
/// [startsAt]/[endsAt] active period, [placementKey] the request must match, and
/// a valid [subject]. A campaign with no valid subject must never produce a
/// placement.
class AdvertisementCampaign {
  const AdvertisementCampaign({
    required this.id,
    this.isEnabled = false,
    this.startsAt,
    this.endsAt,
    required this.placementKey,
    required this.subject,
    required this.destination,
    this.sponsorshipType = '',
    this.disclosureLabel = '',
  });

  /// Stable campaign identity. Distinct from the subject's identity.
  final String id;

  /// Whether this campaign is enabled/active (false by default so an unset
  /// campaign is never eligible).
  final bool isEnabled;

  /// Start of the sponsorship active period, if the period is bounded.
  final DateTime? startsAt;

  /// End of the sponsorship active period, if the period is bounded.
  final DateTime? endsAt;

  /// The placement this campaign targets; must equal an [AdPlacementRequest]'s
  /// placementKey to be eligible for that request.
  final String placementKey;

  /// Reference to the sponsored subject entity (never a clone).
  final MonetizationReference subject;

  /// Constrained, campaign-authored destination (M3 §16 allowlist).
  final CampaignDestination destination;

  /// Sponsorship type (disclosure taxonomy, M6 §13).
  final String sponsorshipType;

  /// Clear user-facing disclosure label (e.g. "Sponsored" / "مُموّل").
  final String disclosureLabel;

  @override
  bool operator ==(Object other) =>
      other is AdvertisementCampaign &&
      other.id == id &&
      other.isEnabled == isEnabled &&
      other.startsAt == startsAt &&
      other.endsAt == endsAt &&
      other.placementKey == placementKey &&
      other.subject == subject &&
      other.destination == destination &&
      other.sponsorshipType == sponsorshipType &&
      other.disclosureLabel == disclosureLabel;

  @override
  int get hashCode => Object.hash(id, isEnabled, startsAt, endsAt,
      placementKey, subject, destination, sponsorshipType, disclosureLabel);

  @override
  String toString() => 'AdvertisementCampaign($id, placement: $placementKey)';
}
