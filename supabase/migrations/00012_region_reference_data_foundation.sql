-- A5.7 — Migration 00012: region reference data foundation
--
-- Establishes the canonical region reference data contract required by
-- personal-profile region persistence (A5.6 integration), future Directory
-- filtering, business/entity locations, and nearby/map experiences.
--
-- Contract:
--   * The STABLE REGION CODE is the application identity contract. Flutter
--     resolves by code only — NEVER by UUID literal or localized labels.
--   * UUIDs seeded below are DATABASE IMPLEMENTATION DETAILS (deterministic
--     literals, repeat-safe). They are documented here and never compiled into
--     Flutter.
--   * The existing regions hierarchy (country → governorate → district) is
--     reused unchanged; it already distinguishes levels safely. The user
--     "region preference / market coverage area" semantic is expressed as a
--     leaf locality in the same taxonomy; future exact physical business
--     locations reuse the same hierarchy through entity_locations.region_id.
--
-- Note on the modeling rule:
--   * A. user REGION PREFERENCE  → leaf district rows under IQ_BAGHDAD.
--   * B. exact physical location (Governorate → City → District → Neighborhood)
--         → the SAME hierarchy; additive child rows can be added later without
--         schema change. No complex GIS system is built here.
--
-- What is NOT seeded:
--   * BaghdadArea.unknown  → no region (user chose none).
--   * BaghdadArea.other    → a locality outside the fixed list was chosen; it
--     has NO canonical locality and is NEVER fabricated into a fake region row.
--   * "All Iraq" is NOT a current freeze choice (onboarding offers only the
--     BaghdadArea list); when the product adds it, IQ itself represents it.

-- ============================================================
-- 1. Strengthen the stable-code uniqueness contract (additive).
--    Codes are documents-for-the-application; make them globally unique with a
--    single-column unique index (existing per-parent constraint is retained).
-- ============================================================
CREATE UNIQUE INDEX uq_regions_code
  ON public.regions (code);

-- ============================================================
-- 2. Canonical seed data (repeat-safe deterministic UPsert).
--    ON CONFLICT (code) re-syncs the row to this canonical definition,
--    keeping the same deterministic id — no rows are ever deleted.
--    is_active is re-asserted so a previously-archived row cannot silently
--    disable a live preference region.
-- ============================================================
INSERT INTO public.regions (id, parent_id, code, region_type, name_ar, name_en)
VALUES
  ('10000000-0000-4000-8000-000000000001', NULL, 'IQ',                    'country',     'العراق',     'Iraq'),
  ('10000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001',
   'IQ_BAGHDAD', 'governorate', 'بغداد', 'Baghdad'),
  -- Baghdad localities (mirror of the frozen first-launch BaghdadArea list,
  -- in enum declaration order; codes are the Flutter contract).
  ('10000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_ADHAMIYA',
   'district', 'الأعظمية',  'Adhamiya'),
  ('10000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_AMIRIYA',
   'district', 'عامرية',    'Amiriya'),
  ('10000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_BAYA',
   'district', 'بياع',      'Baya'''),
  ('10000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_DEWANIJA',
   'district', 'دوانيج',    'Dewanija'),
  ('10000000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_DORA',
   'district', 'دورة',      'Dora'),
  ('10000000-0000-4000-8000-000000000008', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_GHAZALIYA',
   'district', 'غزالية',    'Ghazaliya'),
  ('10000000-0000-4000-8000-000000000009', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_HURRIYA',
   'district', 'حرة',       'Hurriya'),
  ('10000000-0000-4000-8000-00000000000A', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_JADRIYA',
   'district', 'جادرية',    'Jadriya'),
  ('10000000-0000-4000-8000-00000000000B', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_JAMIYA',
   'district', 'جامعة',     'Jami''a'),
  ('10000000-0000-4000-8000-00000000000C', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_KADHIMIYA',
   'district', 'كاظمية',    'Kadhimiya'),
  ('10000000-0000-4000-8000-00000000000D', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_KARRADA',
   'district', 'كرادة',     'Karrada'),
  ('10000000-0000-4000-8000-00000000000E', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_KARKH',
   'district', 'كرخ',       'Karkh'),
  ('10000000-0000-4000-8000-00000000000F', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_MAHMUDIYA',
   'district', 'محمودية',   'Mahmudiya'),
  ('10000000-0000-4000-8000-000000000010', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_MANSOUR',
   'district', 'منصور',     'Mansour'),
  ('10000000-0000-4000-8000-000000000011', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_QANAT',
   'district', 'قناة',      'Qanat'),
  ('10000000-0000-4000-8000-000000000012', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_RASHID',
   'district', 'رشيد',      'Rashid'),
  ('10000000-0000-4000-8000-000000000013', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_RUSAFA',
   'district', 'رصافة',     'Rusafa'),
  ('10000000-0000-4000-8000-000000000014', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_SADR_CITY',
   'district', 'مدينة الصدر', 'Sadr City'),
  ('10000000-0000-4000-8000-000000000015', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_SAYDIYA',
   'district', 'سيدية',     'Saydiya'),
  ('10000000-0000-4000-8000-000000000016', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_SHAAB',
   'district', 'شعب',       'Sha''ab'),
  ('10000000-0000-4000-8000-000000000017', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_SHUALA',
   'district', 'شعلة',      'Shu''ala'),
  ('10000000-0000-4000-8000-000000000018', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_YARMOUK',
   'district', 'يرموك',     'Yarmouk'),
  ('10000000-0000-4000-8000-000000000019', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_ZAFRANIYA',
   'district', 'زعفرانية',  'Za''franiya'),
  ('10000000-0000-4000-8000-00000000001A', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_ABU_GHRAIB',
   'district', 'أبو غريب',  'Abu Ghraib'),
  ('10000000-0000-4000-8000-00000000001B', '10000000-0000-4000-8000-000000000002', 'IQ_BAGHDAD_TAJI',
   'district', 'تاجي',      'Taji')
ON CONFLICT (code) DO UPDATE
  SET parent_id   = EXCLUDED.parent_id,
      region_type = EXCLUDED.region_type,
      name_ar     = EXCLUDED.name_ar,
      name_en     = EXCLUDED.name_en,
      is_active   = true;

-- ============================================================
-- 3. Document the contract on the table (non-functional).
-- ============================================================
COMMENT ON COLUMN public.regions.code IS
  'Stable immutable application contract for a region. Never renamed after '
  'release; Flutter resolves regions by code, never by UUID or display label.';