/// Canonical, typed identity of a Civilpedia tool.
///
/// F0.5 scope: this contract answers **"which tool?"** — it is an *identity*
/// contract, **not** a navigation/resolver contract.
///
/// It intentionally models identity as independent from route path:
/// - [ToolKey] / [ToolKey.stableId] == "which tool this is".
/// - `AppRoutes` (F0.1) == "what the current route path is".
/// - A later resolver (out of scope for F0.5) will answer "where this
///   ToolKey navigates".
///
/// No route is declared here, no resolver is defined, no consumer is migrated,
/// and no persistence is introduced. See M8 §20 (F0.5) and the Tools domain
/// contract in M4.
///
/// The values mirror the current production tool inventory (the `id` of each
/// entry in `ArticleRepository.tools` / `ToolModel`). Identities are stable
/// semantic machine identifiers and must never be tied to UI labels or
/// display text.
library;

/// Canonical tools identity.
enum ToolKey {
  /// Concrete volume / quantity calculator.
  concrete('concrete'),

  /// Steel weight calculator.
  steel('steel'),

  /// Brick / masonry quantity calculator.
  brick('brick'),

  /// On-site checklist/inspection tool.
  checklist('checklist'),

  /// Tile quantity estimator.
  tile('tile');

  /// Stable semantic machine identity, independent of any route path and of
  /// any localized display label.
  ///
  /// This is the value a future resolver / projection can key on. It is NOT a
  /// route and must NOT be used as a navigation path.
  final String stableId;

  const ToolKey(this.stableId);
}
