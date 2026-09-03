/// W7.1 — Code-level placement identity for an advertisement placement.
///
/// Represents a request for an approved monetization placement. It carries only
/// the context needed to resolve campaign eligibility — the stable placement
/// the caller is requesting — and nothing else.
///
/// Deliberate boundaries (M8 §21, M4 §16):
/// - NO Flutter concerns: no BuildContext, Widget, or route object.
/// - NO UI coordinates / widget/screen names.
/// - NO free-form destination; the constrained destination is authored on the
///   campaign itself ([CampaignDestination]), never passed in a request.
///
/// Placement identity is a stable key (e.g. `home_banner`,
/// `directory_sponsored`) established by the owning surface, not a display
/// label. Value-equal; purely descriptive placeholder constants are provided
/// for consistency only and are not an exhaustive registry.
class AdPlacementRequest {
  const AdPlacementRequest({required this.placementKey});

  /// Stable identity of the requested placement.
  final String placementKey;

  @override
  bool operator ==(Object other) =>
      other is AdPlacementRequest && other.placementKey == placementKey;

  @override
  int get hashCode => placementKey.hashCode;

  @override
  String toString() => 'AdPlacementRequest($placementKey)';
}
