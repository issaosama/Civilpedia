-- A5.2 — Migration 00003: profiles + staff roles/permissions/memberships
--
-- profiles:          1:1 personal profile linked to auth.users.
-- roles:             Staff/Civilpedia-employee roles (separate from business membership roles).
-- permissions:       Granular permission definitions (schema only; no speculative seed).
-- role_permissions:  Many-to-many role ↔ permission.
-- staff_memberships: User ↔ staff role (Civilpedia employees).
--
-- Business membership roles (OWNER/ADMIN/MEMBER) are modeled inline on
-- business_memberships (migration 00005) as CHECK-constrained text codes,
-- NOT as FK references to this staff roles table. This keeps staff
-- authorization cleanly separated from Directory business access roles.

-- ============================================================
-- profiles (1:1 with auth.users)
-- ============================================================
CREATE TABLE public.profiles (
  user_id              uuid PRIMARY KEY
    REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name         text,
  photo_url            text,
  role_code            text NOT NULL DEFAULT 'general_user'
                         CHECK (role_code IN (
                           'general_user',
                           'site_engineer',
                           'consultant_engineer',
                           'structural_engineer',
                           'contractor',
                           'engineering_student',
                           'technician_supervisor',
                           'supplier_shop_owner',
                           'engineering_office',
                           'construction_company',
                           'building_office'
                         )),
  preferred_region_id  uuid
    REFERENCES public.regions(id) ON DELETE SET NULL,
  phone                text,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.profiles IS
  '1:1 personal profile for each Supabase authenticated user. '
  'Does NOT store business permissions, staff permissions, or subscription state.';
COMMENT ON COLUMN public.profiles.role_code IS
  'Stable role code for user type / professional role (display label is separate).';
COMMENT ON COLUMN public.profiles.preferred_region_id IS
  'Broad geographic/onboarding preference reference (FK to regions).';

CREATE TRIGGER trigger_set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- ============================================================
-- roles (staff / Civilpedia employee roles)
-- ============================================================
-- OWNER is representable as a protected staff role, but protection logic
-- belongs to later server authorization (A5.3+). is_protected flag
-- marks roles that must not be deleted or reassigned casually.
CREATE TABLE public.roles (
  id           uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  code         text    NOT NULL UNIQUE,
  name         text    NOT NULL,
  is_protected boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.roles IS
  'Staff / Civilpedia employee roles (admin, moderator, owner, support, etc.). '
  'NOT the same as Directory business membership roles (OWNER/ADMIN/MEMBER).';

-- ============================================================
-- permissions
-- ============================================================
-- Schema only. No speculative dozens of permissions seeded here.
CREATE TABLE public.permissions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code        text NOT NULL UNIQUE,
  description text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.permissions IS
  'Granular permission definitions for staff authorization. Schema foundation only; '
  'no speculative seed data. Actual permission codes are added during A5.3+ '
  'when RLS and authorization are implemented.';
