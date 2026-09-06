-- A5.2 — Migration 00005: directory_entities + directory_categories
--
-- directory_entities: the core Directory identity record.
-- directory_categories: managed category taxonomy (stable IDs/codes).
-- (directory_entity_categories and the other 1:N relationship tables are in
-- migration 00006.)

-- ============================================================
-- directory_entities
-- ============================================================
CREATE TABLE public.directory_entities (
  id                 uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type        text    NOT NULL
                         CHECK (entity_type IN (
                           'company',
                           'engineering_office',
                           'contractor',
                           'supplier',
                           'store',
                           'technician',
                           'laboratory',
                           'equipment_provider',
                           'service_provider'
                         )),
  name               text    NOT NULL,
  description        text,
  lifecycle_status   text    NOT NULL DEFAULT 'draft'
                         CHECK (lifecycle_status IN (
                           'draft', 'active', 'inactive', 'suspended'
                         )),
  verification_status text   NOT NULL DEFAULT 'unverified'
                         CHECK (verification_status IN (
                           'unverified', 'pending', 'verified',
                           'rejected', 'suspended'
                         )),
  -- Ownership / claim flow state: orthogonal to verification_status.
  -- none   = entity is not yet claimed by any user (or claim not started).
  -- pending = a claim or ownership transfer is being reviewed.
  -- claimed = ownership has been approved and linked via business_memberships.
  claim_status       text    NOT NULL DEFAULT 'unclaimed'
                         CHECK (claim_status IN (
                           'unclaimed', 'pending', 'claimed'
                         )),
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.directory_entities IS
  'Core Directory identity record. Each row is one company/office/contractor/'
  'supplier/store/technician/laboratory/equipment-provider/service-provider. '
  'verification_status (quality signal) is orthogonal to lifecycle_status '
  '(business state) and claim_status (ownership flow). '
  'Paid-plan / sponsored logic lives elsewhere — not in this table.';

CREATE TRIGGER trigger_set_updated_at
  BEFORE UPDATE ON public.directory_entities
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- Structural indexes for common Directory queries.
CREATE INDEX idx_directory_entities_entity_type
  ON public.directory_entities (entity_type);
CREATE INDEX idx_directory_entities_verification_status
  ON public.directory_entities (verification_status);
CREATE INDEX idx_directory_entities_lifecycle_status
  ON public.directory_entities (lifecycle_status);
CREATE INDEX idx_directory_entities_created_at
  ON public.directory_entities (created_at);

-- ============================================================
-- directory_categories (managed taxonomy)
-- ============================================================
CREATE TABLE public.directory_categories (
  id                 uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_category_id uuid    REFERENCES public.directory_categories(id) ON DELETE RESTRICT,
  code               text    NOT NULL,
  name_ar            text    NOT NULL,
  name_en            text,
  is_active          boolean NOT NULL DEFAULT true,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),

  -- Unique code within each parent level; root categories must also be unique.
  CONSTRAINT uq_directory_categories_parent_code
    UNIQUE (parent_category_id, code)
);

-- Enforces unique codes among root-level categories (NULL parent), which a
-- plain unique index would otherwise allow due to PostgreSQL NULL semantics.
CREATE UNIQUE INDEX uq_directory_categories_root_code
  ON public.directory_categories (code)
  WHERE (parent_category_id IS NULL);

CREATE TRIGGER trigger_set_updated_at
  BEFORE UPDATE ON public.directory_categories
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

COMMENT ON TABLE public.directory_categories IS
  'Managed category taxonomy for Directory entities. Hierarchical (self-referential parent). '
  'Stable machine-readable code is the identity; Arabic/English labels are display-only.';
