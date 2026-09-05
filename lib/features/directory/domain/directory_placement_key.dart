/// W7.2 — Stable placement identity owned by the Directory/Monetization
/// integration boundary.
///
/// Sponsorship is a Monetization concern; the *placement* (where a sponsored
/// projection may appear) is declared here so no raw string literal is scattered
/// across Directory or Monetization consumers. See W7.2 §2.
///
/// Eligibility is resolved by [CampaignPlacementResolver] matching an
/// [AdPlacementRequest]'s key, never by widget/screen names.
abstract final class DirectoryPlacementKeys {
  /// The one canonical Directory search sponsored placement.
  static const String directorySponsored = 'directory_sponsored';

  /// The Directory provider entity type used in sponsored subject references
  /// (e.g. `directory:provider:<id>`), mirroring the Saved cross-domain shape.
  static const String providerEntityType = 'provider';
}
