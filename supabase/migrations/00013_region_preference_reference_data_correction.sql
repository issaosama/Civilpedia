-- A5.7 — Migration 00013: REGION PREFERENCE reference data correction
--
-- ARCHITECTURE CORRECTION (architect blocker):
--   "REGION PREFERENCE ≠ BAGHDAD DIRECTORY AREA"
--
-- The frozen first-launch Region Preference contract is SIX USER/MARKET
-- PREFERENCE ZONES (potentially non-geographic in the strictest sense):
--   1. Baghdad - Karkh           (بغداد - الكرخ)
--   2. Baghdad - Rusafa          (بغداد - الرصافة)
--   3. Northern governorates     (المحافظات الشمالية)
--   4. Central governorates      (المحافظات الوسطى)
--   5. Southern governorates     (المحافظات الجنوبية)
--   6. All Iraq                  (كل العراق)
--
-- These are NOT the same concept as `public.regions` (physical Iraq →
-- Governorate → City → District → Neighborhood) or `BaghdadArea` (the
-- legacy/local Directory filtering enumeration of detailed Baghdad areas).
--
-- Correction invariants (all ADDITIVE and NON-DESTRUCTIVE):
--   * A dedicated, separate `region_preferences` reference table holds the
--     frozen six zones. Preference zones are NEVER encoded as fake districts
--     or cities inside `public.regions`.
--   * `entity_locations.region_id` keeps pointing at `public.regions` ONLY —
--     preference-zone identifiers can never be referenced by a physical
--     business/entity location.
--   * `profiles.preferred_region_id` (legacy FK → public.regions) is PRESERVED
--     for compatibility and NOT dropped/renamed. A NEW preference-specific FK
--     column (`region_preference_id` → region_preferences) is added instead.
--   * Migration 00012's 27 geographic rows remain valid geographic reference
--     data (Iraq / Baghdad / Baghdad districts) with a DISJOINT code namespace
--     (`IQ_`, `IQ_BAGHDAD_*` vs `IQ_PREF_*`) — nothing is deleted or rewritten.
--   * No silent data rewrite: profiles rows are untouched by this migration
--     (the new column is NULL by default; no UPDATE is issued).
--
-- Stable machine codes are the application identity contract; localized names
-- are presentation only. UUIDs below are deterministic DATABASE
-- IMPLEMENTATION DETAILS and are never compiled into Flutter — Flutter
-- resolves by code through RegionPreferenceGateway.

-- ============================================================
-- 1. Dedicated Region Preference reference table.
-- ============================================================
CREATE TABLE public.region_preferences (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  code       text        NOT NULL UNIQUE,
  name_ar    text        NOT NULL,
  name_en    text        NOT NULL,
  is_active  boolean     NOT NULL DEFAULT true,
  sort_order integer     NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Deny-by-default posture (mirrors migration 00010): enable RLS, grant only
-- the public SELECT needed to resolve preference codes, and open a permissive
-- SELECT policy (reference data only — no write/delete grants).
ALTER TABLE public.region_preferences ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.region_preferences TO anon, authenticated;

CREATE POLICY "region_preferences_select_all" ON public.region_preferences
  FOR SELECT TO anon, authenticated
  USING (true);

-- ============================================================
-- 2. Seed the frozen 6 zones (repeat-safe deterministic upsert).
--    ON CONFLICT (code) re-syncs the row to this canonical definition and
--    keeps the same deterministic id; no rows are ever deleted.
-- ============================================================
INSERT INTO public.region_preferences
  (id, code, name_ar, name_en, is_active, sort_order)
VALUES
  ('10000000-0000-4000-8000-000000000101', 'IQ_PREF_BAGHDAD_KARKH',
   'بغداد - الكرخ',   'Baghdad - Karkh',   true, 1),
  ('10000000-0000-4000-8000-000000000102', 'IQ_PREF_BAGHDAD_RUSAFA',
   'بغداد - الرصافة', 'Baghdad - Rusafa',  true, 2),
  ('10000000-0000-4000-8000-000000000103', 'IQ_PREF_NORTH',
   'المحافظات الشمالية', 'Northern governorates', true, 3),
  ('10000000-0000-4000-8000-000000000104', 'IQ_PREF_CENTRAL',
   'المحافظات الوسطى', 'Central governorates', true, 4),
  ('10000000-0000-4000-8000-000000000105', 'IQ_PREF_SOUTH',
   'المحافظات الجنوبية', 'Southern governorates', true, 5),
  ('10000000-0000-4000-8000-000000000106', 'IQ_PREF_ALL',
   'كل العراق',        'All Iraq',          true, 6)
ON CONFLICT (code) DO UPDATE
  SET name_ar    = EXCLUDED.name_ar,
      name_en    = EXCLUDED.name_en,
      is_active  = true,
      sort_order = EXCLUDED.sort_order;

-- ============================================================
-- 3. Profile preference ownership: preference-specific FK (additive).
--    `preferred_region_id` (legacy geographic FK → regions) is PRESERVED.
-- ============================================================
ALTER TABLE public.profiles
  ADD COLUMN region_preference_id uuid
    REFERENCES public.region_preferences(id) ON DELETE SET NULL;

-- ============================================================
-- 4. Documentation (metadata only; non-functional).
-- ============================================================
COMMENT ON TABLE public.region_preferences IS
  'Frozen user/market Region Preference zones (Baghdad-Karkh, Baghdad-Rusafa, '
  'North, Central, South, All Iraq). Conceptually SEPARATE from public.regions '
  '(physical geography) and from the BaghdadArea locality enumeration used by '
  'Directory filtering. Preference zones are never stored as public.regions '
  'rows and entity_locations.region_id never references this table.';

COMMENT ON COLUMN public.region_preferences.code IS
  'Stable immutable application contract for a Region Preference zone. '
  'Flutter resolves preference zones by code, never by UUID or display label.';

COMMENT ON COLUMN public.profiles.region_preference_id IS
  'Canonical Region Preference (market/coverage zone) reference (FK to '
  'region_preferences). Distinct from preferred_region_id (legacy FK to '
  'regions, physical geography) — the two concepts are never conflated. '
  'Not written by A5.7 bootstrap until a local preference model exists.';

COMMENT ON COLUMN public.profiles.preferred_region_id IS
  'LEGACY geographic/onboarding reference (FK to regions). Preserved for '
  'compatibility; region preference is tracked separately in '
  'region_preference_id.';

-- Partition sanity guard for reviewers (additive; cannot fail on the expected
-- shape, so it is a no-op assertion helper comment only — the real invariants
-- are verified against DEV in the A5.7 validation step).