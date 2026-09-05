import '../entities/advertisement_campaign.dart';

/// W7.2 — Monetization-owned source of candidate [AdvertisementCampaign]s.
///
/// This is the SMALLEST campaign-source abstraction W7.2 Directory consumes to
/// obtain the candidate campaigns for a given placement. It is a read boundary
/// only — it supplies campaigns, it does not author, store, or persist them.
///
/// Ownership (M4 §10): Monetization owns the campaign and this source. Directory
/// never builds or persists campaigns; it only requests the candidates for a
/// placement it renders.
///
/// Deliberate boundaries:
/// - NO persistence (no Hive / SharedPreferences / SQLite / Firestore / JSON /
///   backend / Remote Config). A durable campaign authority is a future
///   Monetization responsibility, not a W7.2 one.
/// - The default production implementation is HONEST-EMPTY: with no configured
///   campaign authority it returns an empty list, so an unconfigured build shows
///   no sponsored content.
///
/// A source reports the candidate campaigns for [placementKey]. Campaign
/// *eligibility* is decoupled: the caller filters via
/// [CampaignPlacementResolver.evaluateAll], never here.
abstract interface class CampaignSource {
  /// Returns the candidate campaigns targeting [placementKey], in source order.
  ///
  /// A source must never throw for an empty/unconfigured state; it returns an
  /// empty list. On an unexpected implementation error it may throw — W7.2
  /// callers fail closed (no placement) and organic behavior is unaffected.
  Future<List<AdvertisementCampaign>> campaignsFor(String placementKey);
}
