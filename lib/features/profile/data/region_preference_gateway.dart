/// A5.7 — Narrow boundary for the canonical Region Preference reference set
/// (`public.region_preferences`). Resolves a STABLE preference CODE to its
/// database `region_preferences.id` (uuid). Callers never know UUID literals —
/// only codes.
///
/// Conceptually SEPARATE from the physical `public.regions` taxonomy:
///   * preference zones (Baghdad-Karkh / Baghdad-Rusafa / North / Central /
///     South / All Iraq) are NOT stored in `public.regions`;
///   * `entity_locations.region_id` (physical business/entity location) NEVER
///     references a preference zone.
///
/// Reads rely on the public RLS for `region_preferences` (SELECT for anon +
/// authenticated, migration 00013). Implementations must be fake-safe in tests
/// and MUST NOT use service_role.
abstract class RegionPreferenceGateway {
  /// Returns the `region_preferences.id` for a stable [code], or null when the
  /// code resolves to no active row.
  ///
  /// A lookup/network failure MUST throw so the caller can fail-safe and never
  /// invent or guess a preference id.
  Future<String?> resolvePreferenceIdByCode(String code);
}