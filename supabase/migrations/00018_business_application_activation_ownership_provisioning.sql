-- A6.4 — Business application activation and ownership provisioning.
--
-- APPROVED → ACTIVATED is an authoritative, atomic server transition. NEW
-- applications create the minimum canonical directory entity from the approved
-- metadata snapshot. CLAIM applications use only their stored target_entity_id.
-- Both paths create exactly one OWNER business_membership, mark the entity
-- claimed, persist application/entity traceability, and append one sanitized
-- audit record in the same transaction. ACTIVATED calls are idempotent replays
-- only when every ownership invariant remains intact.

-- ============================================================
-- Part 1 — Activation permission
-- ============================================================

INSERT INTO public.permissions (code, description)
VALUES (
  'business_applications.activate',
  'Activate an approved application and provision canonical ownership'
)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
CROSS JOIN public.permissions p
WHERE r.code = 'application_reviewer'
  AND p.code = 'business_applications.activate'
ON CONFLICT DO NOTHING;

-- ============================================================
-- Part 2 — Internal canonical entity-type validation
-- ============================================================
-- directory_entities.entity_type is CHECK-constrained text in migration 00005.
-- PostgreSQL cannot apply that row constraint to an application JSON value
-- without inserting an entity, so this private helper mirrors those exact nine
-- storage values. Contract tests keep it synchronized with the table CHECK.

CREATE OR REPLACE FUNCTION public.is_valid_directory_entity_type(
  p_entity_type text
)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path = public, pg_temp
AS $fn$
  SELECT p_entity_type IN (
    'company',
    'engineering_office',
    'contractor',
    'supplier',
    'store',
    'technician',
    'laboratory',
    'equipment_provider',
    'service_provider'
  );
$fn$;

COMMENT ON FUNCTION public.is_valid_directory_entity_type(text) IS
  'A6.4 — Internal validator mirroring the exact directory_entities.entity_type '
  'CHECK values from migration 00005. Not executable by client roles.';

-- ============================================================
-- Part 3 — Harden NEW creation metadata at the server boundary
-- ============================================================

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

  IF jsonb_typeof(p_metadata) IS DISTINCT FROM 'object'
     OR jsonb_typeof(p_metadata -> 'name') IS DISTINCT FROM 'string'
     OR length(trim(p_metadata ->> 'name')) = 0
     OR jsonb_typeof(p_metadata -> 'entity_type') IS DISTINCT FROM 'string'
     OR NOT public.is_valid_directory_entity_type(
       p_metadata ->> 'entity_type'
     ) THEN
    RAISE EXCEPTION 'invalid_new_application_metadata'
      USING ERRCODE = 'P0DAT';
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
  'A6.4 — Creates a NEW DRAFT for auth.uid() only when metadata contains a '
  'nonblank string name and an exact canonical directory entity_type. The '
  'caller cannot supply identity, lifecycle state, or staff-owned fields.';

-- ============================================================
-- Part 4 — Atomic activation RPC
-- ============================================================

CREATE OR REPLACE FUNCTION public.staff_activate_business_application(
  p_application_id uuid
)
RETURNS public.business_applications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_actor uuid := auth.uid();
  v_row public.business_applications;
  v_entity_id uuid;
  v_before_target_id uuid;
  v_entity_type text;
  v_entity_name text;
  v_claim_status text;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;

  IF NOT public.has_staff_application_permission(
       'business_applications.activate') THEN
    RAISE EXCEPTION 'staff_permission_denied' USING ERRCODE = 'P0PER';
  END IF;

  -- Canonical first lock for every activation path and replay.
  SELECT ba.* INTO v_row
    FROM public.business_applications ba
   WHERE ba.id = p_application_id
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'application_not_found' USING ERRCODE = 'P0NOT';
  END IF;

  -- Network-safe replay: return success only when the original provisioning
  -- remains complete and internally consistent. Never self-heal corruption.
  IF v_row.status = 'ACTIVATED' THEN
    IF v_row.target_entity_id IS NULL
       OR v_row.activated_at IS NULL
       OR v_row.applicant_user_id IS NULL THEN
      RAISE EXCEPTION 'activation_ownership_invariant_conflict'
        USING ERRCODE = 'P0OWN';
    END IF;

    SELECT de.claim_status INTO v_claim_status
      FROM public.directory_entities de
     WHERE de.id = v_row.target_entity_id
     FOR UPDATE;
    IF NOT FOUND OR v_claim_status <> 'claimed' THEN
      RAISE EXCEPTION 'activation_ownership_invariant_conflict'
        USING ERRCODE = 'P0OWN';
    END IF;

    IF NOT EXISTS (
      SELECT 1
        FROM public.business_memberships bm
       WHERE bm.user_id = v_row.applicant_user_id
         AND bm.entity_id = v_row.target_entity_id
         AND bm.role = 'OWNER'
    ) THEN
      RAISE EXCEPTION 'activation_ownership_invariant_conflict'
        USING ERRCODE = 'P0OWN';
    END IF;

    RETURN v_row;
  END IF;

  IF v_row.status <> 'APPROVED' THEN
    RAISE EXCEPTION 'invalid_transition'
      USING ERRCODE = 'P0TRA',
            DETAIL = 'activation requires APPROVED or a valid ACTIVATED replay';
  END IF;

  IF v_row.applicant_user_id IS NULL THEN
    RAISE EXCEPTION 'activation_ownership_invariant_conflict'
      USING ERRCODE = 'P0OWN';
  END IF;

  v_before_target_id := v_row.target_entity_id;

  IF v_row.application_type = 'NEW' THEN
    IF v_row.target_entity_id IS NOT NULL THEN
      RAISE EXCEPTION 'activation_ownership_invariant_conflict'
        USING ERRCODE = 'P0OWN';
    END IF;

    IF jsonb_typeof(v_row.metadata) IS DISTINCT FROM 'object'
       OR jsonb_typeof(v_row.metadata -> 'name') IS DISTINCT FROM 'string'
       OR length(trim(v_row.metadata ->> 'name')) = 0
       OR jsonb_typeof(v_row.metadata -> 'entity_type') IS DISTINCT FROM 'string'
       OR NOT public.is_valid_directory_entity_type(
         v_row.metadata ->> 'entity_type'
       ) THEN
      RAISE EXCEPTION 'invalid_new_application_metadata'
        USING ERRCODE = 'P0DAT';
    END IF;

    v_entity_name := trim(v_row.metadata ->> 'name');
    v_entity_type := v_row.metadata ->> 'entity_type';

    INSERT INTO public.directory_entities (entity_type, name)
    VALUES (v_entity_type, v_entity_name)
    RETURNING id INTO v_entity_id;

    INSERT INTO public.business_memberships (user_id, entity_id, role)
    VALUES (v_row.applicant_user_id, v_entity_id, 'OWNER');

    UPDATE public.directory_entities de
       SET claim_status = 'claimed'
     WHERE de.id = v_entity_id;

  ELSIF v_row.application_type = 'CLAIM' THEN
    v_entity_id := v_row.target_entity_id;
    IF v_entity_id IS NULL THEN
      RAISE EXCEPTION 'claim_target_required' USING ERRCODE = 'P0DAT';
    END IF;

    -- Canonical CLAIM lock order: application first, directory entity second.
    SELECT de.claim_status INTO v_claim_status
      FROM public.directory_entities de
     WHERE de.id = v_entity_id
     FOR UPDATE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'entity_not_found' USING ERRCODE = 'P0NOT';
    END IF;
    IF v_claim_status <> 'unclaimed' THEN
      RAISE EXCEPTION 'target_not_claimable' USING ERRCODE = 'P0CLM';
    END IF;

    IF EXISTS (
      SELECT 1
        FROM public.business_memberships bm
       WHERE bm.user_id = v_row.applicant_user_id
         AND bm.entity_id = v_entity_id
    ) OR EXISTS (
      SELECT 1
        FROM public.business_memberships bm
       WHERE bm.entity_id = v_entity_id
         AND bm.role = 'OWNER'
    ) THEN
      RAISE EXCEPTION 'activation_ownership_invariant_conflict'
        USING ERRCODE = 'P0OWN';
    END IF;

    INSERT INTO public.business_memberships (user_id, entity_id, role)
    VALUES (v_row.applicant_user_id, v_entity_id, 'OWNER');

    UPDATE public.directory_entities de
       SET claim_status = 'claimed'
     WHERE de.id = v_entity_id;
  ELSE
    RAISE EXCEPTION 'invalid_application_type' USING ERRCODE = 'P0DAT';
  END IF;

  UPDATE public.business_applications ba
     SET target_entity_id = v_entity_id,
         status = 'ACTIVATED',
         activated_at = now()
   WHERE ba.id = v_row.id
   RETURNING * INTO v_row;

  PERFORM public.append_audit_log(
    v_actor,
    'BUSINESS_APPLICATION_ACTIVATED',
    'business_application',
    v_row.id,
    jsonb_build_object(
      'status', 'APPROVED',
      'application_type', v_row.application_type,
      'target_entity_id', v_before_target_id
    ),
    jsonb_build_object(
      'status', 'ACTIVATED',
      'application_type', v_row.application_type,
      'target_entity_id', v_entity_id
    ),
    NULL
  );

  RETURN v_row;
END;
$fn$;

COMMENT ON FUNCTION public.staff_activate_business_application(uuid) IS
  'A6.4 — Atomically activates an APPROVED NEW/CLAIM application, provisions '
  'its applicant as canonical OWNER, marks the resulting entity claimed, '
  'persists target_entity_id and activated_at, and writes one sanitized audit '
  'record. Valid ACTIVATED replays return without side effects.';

-- ============================================================
-- Part 5 — EXECUTE lockdown
-- ============================================================

REVOKE EXECUTE ON FUNCTION public.is_valid_directory_entity_type(text)
  FROM PUBLIC, anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.create_new_business_application(jsonb)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_new_business_application(jsonb)
  TO authenticated;

REVOKE EXECUTE ON FUNCTION public.staff_activate_business_application(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.staff_activate_business_application(uuid)
  TO authenticated;
