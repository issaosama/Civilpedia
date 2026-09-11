-- V1-R03 — Business ownership and management read foundation.
--
-- Canonical authority remains auth.uid() + business_memberships. This migration
-- adds narrow server-authorized reads for an actor's associated businesses and
-- for OWNER/ADMIN membership rosters. It adds no membership mutation path.

-- ============================================================
-- Part 1 — Internal management authorization helper
-- ============================================================

CREATE OR REPLACE FUNCTION public.has_business_management_access(
  p_entity_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
  SELECT EXISTS (
    SELECT 1
      FROM public.business_memberships bm
     WHERE bm.user_id = auth.uid()
       AND bm.entity_id = p_entity_id
       AND bm.role IN ('OWNER', 'ADMIN')
  );
$fn$;

COMMENT ON FUNCTION public.has_business_management_access(uuid) IS
  'V1-R03 internal authorization seam. Returns true only when auth.uid() has '
  'an OWNER or ADMIN business_membership for the entity. Not client-executable.';

-- ============================================================
-- Part 2 — Authenticated actor business projection
-- ============================================================

CREATE OR REPLACE FUNCTION public.list_my_businesses()
RETURNS TABLE (
  entity_id uuid,
  name text,
  entity_type text,
  membership_role text,
  claim_status text,
  verification_status text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_actor uuid := auth.uid();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;

  RETURN QUERY
  SELECT de.id,
         de.name,
         de.entity_type,
         bm.role,
         de.claim_status,
         de.verification_status
    FROM public.business_memberships bm
    JOIN public.directory_entities de ON de.id = bm.entity_id
   WHERE bm.user_id = v_actor
     AND bm.role IN ('OWNER', 'ADMIN', 'MEMBER');
END;
$fn$;

COMMENT ON FUNCTION public.list_my_businesses() IS
  'V1-R03 authenticated read of the minimum management projection for entities '
  'linked to auth.uid() through OWNER, ADMIN, or MEMBER business memberships.';

-- ============================================================
-- Part 3 — OWNER/ADMIN membership roster
-- ============================================================

CREATE OR REPLACE FUNCTION public.list_business_members(
  p_entity_id uuid
)
RETURNS TABLE (
  user_id uuid,
  entity_id uuid,
  role text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_actor uuid := auth.uid();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;

  IF NOT public.has_business_management_access(p_entity_id) THEN
    RAISE EXCEPTION 'business_management_permission_denied'
      USING ERRCODE = 'P0PER';
  END IF;

  RETURN QUERY
  SELECT bm.user_id,
         bm.entity_id,
         bm.role
    FROM public.business_memberships bm
   WHERE bm.entity_id = p_entity_id
     AND bm.role IN ('OWNER', 'ADMIN', 'MEMBER');
END;
$fn$;

COMMENT ON FUNCTION public.list_business_members(uuid) IS
  'V1-R03 OWNER/ADMIN-only membership roster. Returns canonical membership '
  'identity, entity, and role only; unauthorized access fails with P0PER.';

-- ============================================================
-- Part 4 — Execute lockdown
-- ============================================================

REVOKE EXECUTE ON FUNCTION public.has_business_management_access(uuid)
  FROM PUBLIC, anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.list_my_businesses()
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_my_businesses()
  TO authenticated;

REVOKE EXECUTE ON FUNCTION public.list_business_members(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_business_members(uuid)
  TO authenticated;
