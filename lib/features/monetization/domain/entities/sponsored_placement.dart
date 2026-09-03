import '../monetization_reference.dart';
import '../value_objects/campaign_destination.dart';

/// W7.1 — A `SponsoredPlacement`: the cross-domain projection of one resolution.
///
/// Monetization exposes placements; Home renders `SponsoredPlacement` only when
/// a campaign is active (M4 §16). Per M4 §19 this is a deliberately bounded,
/// read-only cross-domain projection with stable identity — it references the
/// sponsored subject ([subject]) and never contains a Directory entity copy.
///
/// [servedAt] records the evaluation time at which the placement was resolved,
/// making a resolved projection deterministic and auditable without calling
/// `DateTime.now()` inside business logic.
class SponsoredPlacement {
  const SponsoredPlacement({
    required this.placementKey,
    required this.campaignId,
    required this.subject,
    required this.destination,
    required this.sponsorshipType,
    required this.disclosureLabel,
    required this.servedAt,
  });

  /// The placement this projection satisfies (matches the AdPlacementRequest).
  final String placementKey;

  /// Stable identity of the campaign that supplied this placement.
  final String campaignId;

  /// Reference to the sponsored subject entity (never a clone).
  final MonetizationReference subject;

  /// Constrained, campaign-authored destination.
  final CampaignDestination destination;

  /// Sponsorship type (disclosure taxonomy).
  final String sponsorshipType;

  /// Clear user-facing disclosure label (e.g. "Sponsored" / "مُموّل").
  final String disclosureLabel;

  /// Evaluation time at which this placement was resolved (deterministic).
  final DateTime servedAt;

  @override
  bool operator ==(Object other) =>
      other is SponsoredPlacement &&
      other.placementKey == placementKey &&
      other.campaignId == campaignId &&
      other.subject == subject &&
      other.destination == destination &&
      other.sponsorshipType == sponsorshipType &&
      other.disclosureLabel == disclosureLabel &&
      other.servedAt == servedAt;

  @override
  int get hashCode => Object.hash(placementKey, campaignId, subject,
      destination, sponsorshipType, disclosureLabel, servedAt);

  @override
  String toString() => 'SponsoredPlacement(campaign: $campaignId, '
      'placement: $placementKey, subject: $subject)';
}
