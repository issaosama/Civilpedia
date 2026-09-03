import '../monetization_reference.dart';

/// W7.1 — Constrained destination for a sponsored campaign.
///
/// Navigation rules (M3 §16) require ad destinations be authored as
/// **constrained campaign entities** (an allowed-destination allowlist), NOT
/// free-form URL strings. A campaign points its [SponsoredPlacement] at either:
///
/// - an INTERNAL domain entity (via a stable [MonetizationReference] to the real
///   sponsored subject or an approved internal promo), or
/// - an EXTERNAL verified URI, which is explicitly gated by product policy.
///
/// This is the domain-authored destination declaration; it does not itself
/// navigate and carries no Flutter/route objects. The allowlist/safety decision
/// (where an internal destination may resolve) belongs to the owning surface.
class CampaignDestination {
  const CampaignDestination._({
    required this.kind,
    this.reference,
    this.uri,
  }) : assert(
          (kind == CampaignDestinationKind.internal && reference != null) ||
              (kind == CampaignDestinationKind.external && uri != null),
          'Internal destinations need a reference; external need a gated uri.',
        );

  /// An internal destination: a stable reference to a real domain entity or
  /// approved internal promo surface. Never a free-form route string.
  factory CampaignDestination.internal(MonetizationReference reference) =>
      CampaignDestination._(kind: CampaignDestinationKind.internal,
          reference: reference);

  /// An external destination behind a verified, product-gated URI.
  factory CampaignDestination.external(String uri) =>
      CampaignDestination._(kind: CampaignDestinationKind.external, uri: uri);

  final CampaignDestinationKind kind;

  /// Present for [CampaignDestinationKind.internal]; references the real
  /// subject (sponsored ≠ second entity).
  final MonetizationReference? reference;

  /// Present for [CampaignDestinationKind.external]; the gated verified URI.
  final String? uri;

  @override
  bool operator ==(Object other) =>
      other is CampaignDestination &&
      other.kind == kind &&
      other.reference == reference &&
      other.uri == uri;

  @override
  int get hashCode => Object.hash(kind, reference, uri);

  @override
  String toString() =>
      kind == CampaignDestinationKind.internal
          ? 'CampaignDestination.internal($reference)'
          : 'CampaignDestination.external($uri)';
}

/// Constrained destination kind (M3 §16).
enum CampaignDestinationKind {
  /// Internal domain entity / approved internal promo.
  internal,

  /// External verified URI, gated by product policy.
  external,
}
