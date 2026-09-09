-- A6.3.1 — Server-authorized business-application creation.
--
-- Removes generic authenticated INSERT access and replaces it with two narrow
-- SECURITY DEFINER RPCs. Applicant identity always comes from auth.uid(); both
-- RPCs create canonical DRAFT rows and expose no staff/lifecycle-owned fields.
-- CLAIM insertion continues through trigger_guard_claim_insert (00014/00015),
-- preserving its directory-entity row lock, claimability check, FK, and the
-- uq_business_applications_live_claim concurrency backstop.

REVOKE INSERT ON public.business_applications FROM authenticated;

DROP POLICY "business_applications_insert_own"
  ON public.business_applications;

-- This trigger function was created after migration 00010's blanket function
-- revoke. Triggers do not require caller EXECUTE, so remove its default PUBLIC
-- grant while retaining it as the single CLAIM lock/validation implementation.
REVOKE EXECUTE ON FUNCTION public.guard_claim_application_insert()
  FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.create_new_business_application(
  p_metadata jsonb DEFAULT NULL
)
RETURNS public.business_applications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_actor uuid := auth.uid();
  v_row public.business_applications;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;

  INSERT INTO public.business_applications (
    applicant_user_id,
    application_type,
    target_entity_id,
    status,
    metadata
  ) VALUES (
    v_actor,
    'NEW',
    NULL,
    'DRAFT',
    p_metadata
  )
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$fn$;

COMMENT ON FUNCTION public.create_new_business_application(jsonb) IS
  'A6.3.1 — Creates a NEW application as DRAFT for auth.uid(). The caller may '
  'supply candidate metadata only; identity and all lifecycle/staff fields are '
  'server-owned. Creates no entity, membership, subscription, or activation.';

CREATE OR REPLACE FUNCTION public.create_claim_business_application(
  p_target_entity_id uuid
)
RETURNS public.business_applications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_actor uuid := auth.uid();
  v_row public.business_applications;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;

  IF p_target_entity_id IS NULL THEN
    RAISE EXCEPTION 'target_required' USING ERRCODE = 'P0DAT';
  END IF;

  INSERT INTO public.business_applications (
    applicant_user_id,
    application_type,
    target_entity_id,
    status,
    metadata
  ) VALUES (
    v_actor,
    'CLAIM',
    p_target_entity_id,
    'DRAFT',
    NULL
  )
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$fn$;

COMMENT ON FUNCTION public.create_claim_business_application(uuid) IS
  'A6.3.1 — Creates a CLAIM application as DRAFT for auth.uid(). The caller '
  'supplies only the target entity. The existing 00014/00015 INSERT trigger '
  'authoritatively locks and validates claimability; the existing FK and live-'
  'claim unique index remain authoritative. Creates no ownership side effects.';

-- PostgreSQL grants new-function EXECUTE to PUBLIC by default. Remove every
-- implicit client path, then grant only the two intended authenticated RPCs.
REVOKE EXECUTE ON FUNCTION public.create_new_business_application(jsonb)
  FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.create_claim_business_application(uuid)
  FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.create_new_business_application(jsonb)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_claim_business_application(uuid)
  TO authenticated;
