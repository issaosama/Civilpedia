/// A5.7 — Canonical REGION PREFERENCE zones (frozen first-launch contract).
///
/// Conceptually SEPARATE from BOTH:
///   * `public.regions` — physical Iraq geography
///     (Iraq → Governorate → City → District → Neighborhood), and
///   * `BaghdadArea` — the legacy/local Directory filtering enumeration of
///     detailed Baghdad areas (physical, Directory-only).
///
/// The frozen contract is EXACTLY six user/market preference zones. These are
/// the only values the Region Preference concept may take; the DB mirror is
/// `region_preferences` (migration 00013), keyed by the same stable codes.
///
/// Contract rules enforced here and by callers:
///   * Flutter resolves preference zones by STABLE CODE — never by UUID literal
///     or localized label (labels are presentation-only).
///   * Preference zones are NEVER stored as fake districts/cities in
///     `public.regions`, and `entity_locations.region_id` NEVER references a
///     preference zone.
///   * A [BaghdadArea] locality is NEVER silently treated as a broad Region
///     Preference — no guessing, no invented mapping.
abstract final class RegionPreferenceCode {
  const RegionPreferenceCode._();

  static const String baghdadKarkh = 'IQ_PREF_BAGHDAD_KARKH';
  static const String baghdadRusafa = 'IQ_PREF_BAGHDAD_RUSAFA';
  static const String north = 'IQ_PREF_NORTH';
  static const String central = 'IQ_PREF_CENTRAL';
  static const String south = 'IQ_PREF_SOUTH';
  static const String allIraq = 'IQ_PREF_ALL';

  /// The frozen six-zone contract, in frozen display order (sort_order 1..6 in
  /// `region_preferences`).
  static const List<String> all = [
    baghdadKarkh,
    baghdadRusafa,
    north,
    central,
    south,
    allIraq,
  ];

  static const Set<String> _known = {...all};

  /// True when [code] is one of the frozen canonical preference codes.
  static bool isKnown(String code) => _known.contains(code);
}