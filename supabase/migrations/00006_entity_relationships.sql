-- A5.2 — Migration 00006: directory_entity_categories + business_memberships
-- + entity_locations + entity_contacts + entity_media
--
-- These are the many-to-many / 1:N relationship tables that attach
-- metadata and access control to a directory_entities row.

-- ============================================================
-- directory_entity_categories (many-to-many: entity ↔ category)
-- ============================================================
-- Supports: one primary category + multiple additional categories.
CREATE TABLE public.directory_entity_categories (
  entity_id   uuid NOT NULL REFERENCES public.directory_entities(id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES public.directory_categories(id) ON DELETE RESTRICT,
  is_primary  boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (entity_id, category_id)
);

-- Enforce at most one primary category per entity.
CREATE UNIQUE INDEX uq_entity_categories_one_primary
  ON public.directory_entity_categories (entity_id)
  WHERE (is_primary = true);

COMMENT ON TABLE public.directory_entity_categories IS
  'Many-to-many: Directory entity ↔ category. is_primary enforced at most '
  'one primary per entity via a partial unique index. '
  'ON DELETE CASCADE: removing an entity removes its category assignments. '
  'ON DELETE RESTRICT: prevent deleting a category still assigned to an entity.';

-- ============================================================
-- business_memberships (User ↔ Directory Entity, many-to-many)
-- ============================================================
-- Business membership roles are NOT FK-referenced to the staff roles table.
-- They use inline CHECK-constrained text codes (OWNER/ADMIN/MEMBER) to keep
-- staff authorization cleanly separate from Directory business access roles.
CREATE TABLE public.business_memberships (
  user_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  entity_id  uuid        NOT NULL REFERENCES public.directory_entities(id) ON DELETE CASCADE,
  role       text        NOT NULL DEFAULT 'MEMBER'
               CHECK (role IN ('OWNER', 'ADMIN', 'MEMBER')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (user_id, entity_id)
);

CREATE TRIGGER trigger_set_updated_at
  BEFORE UPDATE ON public.business_memberships
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- Index for "which entities does this user manage / have access to?" lookups.
CREATE INDEX idx_business_memberships_entity_id
  ON public.business_memberships (entity_id);

COMMENT ON TABLE public.business_memberships IS
  'Many-to-many: User ↔ Directory Entity. Business membership roles are '
  'OWNER/ADMIN/MEMBER (CHECK-constrained text codes), NOT FK references '
  'to the staff roles table. One user may manage multiple entities; '
  'one entity may have multiple users. UNIQUE (user_id, entity_id) enforced.';

-- ============================================================
-- entity_locations (1:N: multiple branches per entity)
-- ============================================================
-- Coordinates are nullable by design: technicians/service providers may use
-- service-area-only profiles without any private location or exact map pin.
CREATE TABLE public.entity_locations (
  id         uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id  uuid    NOT NULL
               REFERENCES public.directory_entities(id) ON DELETE CASCADE,
  region_id  uuid
               REFERENCES public.regions(id) ON DELETE SET NULL,
  address    text,
  latitude   numeric(9, 6),
  longitude  numeric(9, 6),
  is_primary boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_locations_coordinates_together
    CHECK ((latitude IS NULL) = (longitude IS NULL)),

  CONSTRAINT chk_locations_latitude_range
    CHECK (latitude IS NULL OR (latitude >= -90 AND latitude <= 90)),

  CONSTRAINT chk_locations_longitude_range
    CHECK (longitude IS NULL OR (longitude >= -180 AND longitude <= 180))
);

CREATE TRIGGER trigger_set_updated_at
  BEFORE UPDATE ON public.entity_locations
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- At most one primary branch per entity.
CREATE UNIQUE INDEX uq_entity_locations_one_primary
  ON public.entity_locations (entity_id)
  WHERE (is_primary = true);

-- Query-critical structural indexes.
CREATE INDEX idx_entity_locations_region_id
  ON public.entity_locations (region_id);

COMMENT ON TABLE public.entity_locations IS
  'Physical/service locations per Directory entity. Multiple rows per entity '
  'support multi-branch businesses. city/address via FK to regions hierarchy. '
  'latitude/longitude nullable so exact map pins are optional (service-area-profiles).';

-- ============================================================
-- entity_contacts (1:N independent contact entries)
-- ============================================================
CREATE TABLE public.entity_contacts (
  id           uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id    uuid    NOT NULL
                REFERENCES public.directory_entities(id) ON DELETE CASCADE,
  contact_type text    NOT NULL
                CHECK (contact_type IN (
                  'phone', 'whatsapp', 'email', 'website', 'other'
                )),
  value        text    NOT NULL,
  is_primary   boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_contacts_non_empty_value
    CHECK (length(trim(value)) > 0)
);

CREATE TRIGGER trigger_set_updated_at
  BEFORE UPDATE ON public.entity_contacts
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- One primary contact per (entity, contact_type).
CREATE UNIQUE INDEX uq_entity_contacts_one_primary_per_type
  ON public.entity_contacts (entity_id, contact_type)
  WHERE (is_primary = true);

COMMENT ON TABLE public.entity_contacts IS
  'Independent contact entries (phone/whatsapp/email/website/other) per '
  'entity. Phone is not enforced globally for every entity — a required '
  'phone will be a business-application workflow rule later, not a DB-level '
  'constraint on directory_entities.';

-- ============================================================
-- entity_media (logo/cover/gallery metadata)
-- ============================================================
CREATE TABLE public.entity_media (
  id         uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id  uuid    NOT NULL
              REFERENCES public.directory_entities(id) ON DELETE CASCADE,
  media_type text    NOT NULL
              CHECK (media_type IN ('logo', 'cover', 'gallery')),
  url        text    NOT NULL,
  position   integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_entity_media_entity_id
  ON public.entity_media (entity_id);

COMMENT ON TABLE public.entity_media IS
  'Media metadata (logo/cover/gallery) for Directory entities. Stores the '
  'storage reference only — Supabase Storage wiring is a later phase.';

