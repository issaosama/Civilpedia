-- A5.2 — Migration 00002: regions
-- Hierarchical Iraq geography. Supports:
--   Iraq → Governorate → City → District → Neighborhood
-- and the current broad onboarding preference model.
--
-- Uses stable machine-readable codes, not Arabic names as identity.
-- Structurally future-ready for all Iraq governorates.
-- Taxonomy data (actual rows) is NOT seeded here; structure only.

CREATE TABLE public.regions (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id  uuid        REFERENCES public.regions(id) ON DELETE RESTRICT,
  code       text        NOT NULL,
  region_type text       NOT NULL
               CHECK (region_type IN (
                 'country', 'governorate', 'city', 'district', 'neighborhood'
               )),
  name_ar    text        NOT NULL,
  name_en    text,
  is_active  boolean     NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  -- Prevent duplicate code under the same parent (unique at each level).
  -- (NULL parent rows are excluded: for the root 'country' level, see
  -- uq_regions_root_code below — PostgreSQL treats NULLs as distinct in a
  -- plain unique index.)
  CONSTRAINT uq_regions_parent_code
    UNIQUE (parent_id, code),

  -- Only country-level regions have no parent.
  CONSTRAINT chk_regions_root_has_parent_type
    CHECK (
      (parent_id IS NULL AND region_type = 'country')
      OR
      (parent_id IS NOT NULL AND region_type IN (
        'governorate', 'city', 'district', 'neighborhood'
      ))
    )
);

-- Enforces globally unique codes among root-level (country) regions.
CREATE UNIQUE INDEX uq_regions_root_code
  ON public.regions (code)
  WHERE (parent_id IS NULL);

CREATE TRIGGER trigger_set_updated_at
  BEFORE UPDATE ON public.regions
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

COMMENT ON TABLE public.regions IS
  'Managed geographic taxonomy. Each region has a stable machine-readable code '
  'and a type (country/governorate/city/district/neighborhood). Parent–child '
  'hierarchy enforced via parent_id self-reference. No display-name uniqueness '
  'constraint — translation is display-only.';
