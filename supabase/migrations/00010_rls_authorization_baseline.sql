-- A5.3 — Migration 00010: RLS & server authorization baseline
--
-- Enforces deny-by-default Row Level Security + a narrow database
-- privilege baseline for the Data API roles (anon / authenticated).
--
-- Access model:
--   Public reference data   regions, directory_categories, plans
--                           → anon + authenticated: SELECT only
--   Public directory        directory_entities, directory_entity_categories,
--                           entity_locations, entity_contacts, entity_media
--                           → anon + authenticated: SELECT only,
--                             directory_entities filtered to lifecycle_status
--                             = 'active'; child tables visible only when the
--                             parent entity is active
--   Profiles                → authenticated: SELECT/INSERT/UPDATE own row
--                             (user_id = auth.uid()); no DELETE
--   Business memberships    → authenticated: SELECT own rows; no mutations
--   Business applications   → authenticated: INSERT own, SELECT own, UPDATE
--                             from DRAFT/NEEDS_CORRECTION → DRAFT/SUBMITTED/
--                             NEEDS_CORRECTION; no DELETE
--   Staff / billing / audit roles, permissions, role_permissions,
--                             staff_memberships, subscriptions, audit_logs,
--                             application_contacts, application_visits,
--                             application_notes
--                             → NO anon/authenticated grants at all
--
-- Layering notes:
--   * Privilege grants gate *table access*; RLS policies gate *rows*.
--     A table with zero grants to a role is unreachable via PostgREST
--     regardless of policies.
--   * RLS is not FORCED: postgres/service_role (server-side / staff flows)
--     intentionally bypass RLS. That is the design — staff authorization is
--     a separate later phase (A5.4+).
--   * Future migrations must keep this deny-by-default posture and issue
--     explicit GRANTs for any table anon/authenticated may read.

-- ============================================================
-- 1. Explicitly enable RLS on every table (idempotent; the
--    platform auto-enables RLS, this documents the guarantee).
-- ============================================================
ALTER TABLE public.regions                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles                       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles                          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_memberships              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.directory_entities             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.directory_categories           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.directory_entity_categories    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_memberships           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.entity_locations               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.entity_contacts                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.entity_media                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_applications          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.application_contacts           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.application_visits             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.application_notes              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plans                          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs                     ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 2. Revoke every privilege previously granted to the Data API
--    roles (deny-by-default baseline). The tables currently carry
--    only REFERENCES/TRIGGER/TRUNCATE grants from creation; this
--    removes those and any future drift.
-- ============================================================
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM authenticated;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM authenticated;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM anon;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM authenticated;

-- ============================================================
-- 3. Grant the narrow baseline (table-level access).
-- ============================================================

-- Public reference data: SELECT for everyone.
GRANT SELECT ON public.regions              TO anon, authenticated;
GRANT SELECT ON public.directory_categories TO anon, authenticated;
GRANT SELECT ON public.plans                TO anon, authenticated;

-- Public directory: SELECT for everyone (RLS filters active entities).
GRANT SELECT ON public.directory_entities          TO anon, authenticated;
GRANT SELECT ON public.directory_entity_categories TO anon, authenticated;
GRANT SELECT ON public.entity_locations            TO anon, authenticated;
GRANT SELECT ON public.entity_contacts             TO anon, authenticated;
GRANT SELECT ON public.entity_media                TO anon, authenticated;

-- Profiles: authenticated only, own-row (RLS).
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;

-- Business memberships: authenticated only, own-row (RLS), read-only.
GRANT SELECT ON public.business_memberships TO authenticated;

-- Business applications: authenticated only, own-row (RLS), lifecycle-aware.
GRANT SELECT, INSERT, UPDATE ON public.business_applications TO authenticated;

-- ============================================================
-- 4. Row Level Security policies.
-- ============================================================

-- ---------- profiles: users manage their own row only ----------
CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ---------- regions: fully public reference taxonomy ----------
CREATE POLICY "regions_select_all" ON public.regions
  FOR SELECT TO anon, authenticated
  USING (true);

-- ---------- directory_categories: fully public managed taxonomy ----------
CREATE POLICY "directory_categories_select_all" ON public.directory_categories
  FOR SELECT TO anon, authenticated
  USING (true);

-- ---------- plans: fully public plan catalog (no payments data) ----------
CREATE POLICY "plans_select_all" ON public.plans
  FOR SELECT TO anon, authenticated
  USING (true);

-- ---------- directory_entities: only active entities are public ----------
CREATE POLICY "directory_entities_select_active" ON public.directory_entities
  FOR SELECT TO anon, authenticated
  USING (lifecycle_status = 'active');

-- ---------- directory entity children: visible only when the parent
--             entity is active (defense-in-depth vs parent filter) ----------
CREATE POLICY "directory_entity_categories_select_active_parent"
  ON public.directory_entity_categories
  FOR SELECT TO anon, authenticated
  USING (EXISTS (
    SELECT 1 FROM public.directory_entities parent
    WHERE parent.id = entity_id
      AND parent.lifecycle_status = 'active'
  ));

CREATE POLICY "entity_locations_select_active_parent" ON public.entity_locations
  FOR SELECT TO anon, authenticated
  USING (EXISTS (
    SELECT 1 FROM public.directory_entities parent
    WHERE parent.id = entity_id
      AND parent.lifecycle_status = 'active'
  ));

CREATE POLICY "entity_contacts_select_active_parent" ON public.entity_contacts
  FOR SELECT TO anon, authenticated
  USING (EXISTS (
    SELECT 1 FROM public.directory_entities parent
    WHERE parent.id = entity_id
      AND parent.lifecycle_status = 'active'
  ));

CREATE POLICY "entity_media_select_active_parent" ON public.entity_media
  FOR SELECT TO anon, authenticated
  USING (EXISTS (
    SELECT 1 FROM public.directory_entities parent
    WHERE parent.id = entity_id
      AND parent.lifecycle_status = 'active'
  ));

-- ---------- business_memberships: read your own memberships ----------
CREATE POLICY "business_memberships_select_own" ON public.business_memberships
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- ---------- business_applications: own-row, lifecycle-aware ----------
CREATE POLICY "business_applications_insert_own" ON public.business_applications
  FOR INSERT TO authenticated
  WITH CHECK (applicant_user_id = auth.uid());

CREATE POLICY "business_applications_select_own" ON public.business_applications
  FOR SELECT TO authenticated
  USING (applicant_user_id = auth.uid());

CREATE POLICY "business_applications_update_own" ON public.business_applications
  FOR UPDATE TO authenticated
  USING (applicant_user_id = auth.uid()
         AND status IN ('DRAFT', 'NEEDS_CORRECTION'))
  WITH CHECK (applicant_user_id = auth.uid()
              AND status IN ('DRAFT', 'SUBMITTED', 'NEEDS_CORRECTION'));

-- ============================================================
-- Known limitation (documented, not silently fixed):
--   With UPDATE on their own application, an applicant can set the
--   non-ownership operational fields (reviewed_by_user_id,
--   reviewed_at, approved_at, rejection_reason, ...) that staff are
--   expected to control. This is a data-integrity concern, not a
--   privilege-escalation path (none of those fields grant access).
--   Closing it requires a BEFORE UPDATE trigger or column-level
--   grants; it is deliberately deferred to the staff-authorization
--   phase (A5.4+) so it does not block legitimate server-side
--   staff transitions with an under-specified mechanism.
-- ============================================================