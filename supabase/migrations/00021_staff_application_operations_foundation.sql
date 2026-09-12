-- V1-R07 — Staff / Admin Operations Foundation (server/security Part 1).
--
-- Adds the smallest staff read surface required by the frozen V1-R07 contract:
-- one granular read permission, current-session capability discovery, a bounded
-- keyset-paginated queue, and one bounded detail projection. Existing A6 staff
-- mutation, locking, activation, and audit functions remain unchanged.
--
-- Human identity is always auth.uid(). Staff authority remains exclusively:
-- staff_memberships -> roles -> role_permissions -> permissions.code.
-- Initial staff membership provisioning remains a trusted Supabase/database
-- administrative operation outside the client; there is no self-enrollment.

-- ============================================================
-- 1. Read permission and existing reviewer-role assignment
-- ============================================================

INSERT INTO public.permissions (code, description)
VALUES (
  'business_applications.read',
  'Read bounded staff business-application queue and detail projections'
)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
CROSS JOIN public.permissions p
WHERE r.code = 'application_reviewer'
  AND p.code = 'business_applications.read'
ON CONFLICT DO NOTHING;

-- The pre-existing status-only index cannot support the frozen ordering and
-- keyset cursor. This index supports status filtering followed by
-- created_at ASC, id ASC without introducing a redundant general index.
CREATE INDEX idx_business_applications_staff_queue
  ON public.business_applications (status, created_at, id);

-- ============================================================
-- 2. Current-session granular capabilities
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_staff_application_capabilities()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_actor uuid := auth.uid();
  v_permissions jsonb;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;

  SELECT COALESCE(jsonb_agg(granted.code ORDER BY granted.code), '[]'::jsonb)
    INTO v_permissions
    FROM (
      SELECT DISTINCT perm.code
      FROM public.staff_memberships sm
      JOIN public.role_permissions rp ON rp.role_id = sm.role_id
      JOIN public.permissions perm ON perm.id = rp.permission_id
      WHERE sm.user_id = v_actor
        AND sm.is_active
        AND sm.effective_at <= now()
        AND (sm.expires_at IS NULL OR sm.expires_at > now())
        AND perm.code IN (
          'business_applications.read',
          'business_applications.review',
          'business_applications.return_for_correction',
          'business_applications.mark_contacted',
          'business_applications.schedule_visit',
          'business_applications.approve',
          'business_applications.reject',
          'business_applications.activate'
        )
    ) AS granted;

  RETURN jsonb_build_object('permissions', v_permissions);
END;
$fn$;

COMMENT ON FUNCTION public.get_staff_application_capabilities() IS
  'V1-R07 — Returns the current authenticated session''s deterministic, '
  'duplicate-free granular business-application permissions. Identity comes '
  'only from auth.uid() and active/effective/unexpired staff memberships. '
  'Capability discovery is UX-only; every staff RPC authorizes independently.';

-- ============================================================
-- 3. Bounded staff application queue
-- ============================================================

CREATE OR REPLACE FUNCTION public.list_staff_business_applications(
  p_status text DEFAULT NULL,
  p_application_type text DEFAULT NULL,
  p_limit integer DEFAULT 25,
  p_cursor_created_at timestamptz DEFAULT NULL,
  p_cursor_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_actor uuid := auth.uid();
  v_result jsonb;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;

  IF NOT public.has_staff_application_permission(
       'business_applications.read') THEN
    RAISE EXCEPTION 'staff_permission_denied' USING ERRCODE = 'P0PER';
  END IF;

  IF p_status IS NOT NULL AND p_status NOT IN (
    'SUBMITTED',
    'UNDER_REVIEW',
    'CONTACTED',
    'VISIT_SCHEDULED',
    'NEEDS_CORRECTION',
    'APPROVED',
    'REJECTED',
    'ACTIVATED'
  ) THEN
    RAISE EXCEPTION 'invalid_application_status_filter'
      USING ERRCODE = 'P0DAT';
  END IF;

  IF p_application_type IS NOT NULL
     AND p_application_type NOT IN ('NEW', 'CLAIM') THEN
    RAISE EXCEPTION 'invalid_application_type_filter'
      USING ERRCODE = 'P0DAT';
  END IF;

  IF p_limit IS NULL OR p_limit < 1 OR p_limit > 50 THEN
    RAISE EXCEPTION 'invalid_page_size' USING ERRCODE = 'P0DAT';
  END IF;

  IF (p_cursor_created_at IS NULL) <> (p_cursor_id IS NULL) THEN
    RAISE EXCEPTION 'invalid_queue_cursor' USING ERRCODE = 'P0DAT';
  END IF;

  WITH fetched AS (
    SELECT
      ba.created_at AS cursor_created_at,
      ba.id AS cursor_id,
      jsonb_build_object(
        'id', ba.id,
        'application_type', ba.application_type,
        'status', ba.status,
        'created_at', ba.created_at,
        'updated_at', ba.updated_at,
        'reviewed_by_user_id', ba.reviewed_by_user_id,
        'new_business', CASE
          WHEN ba.application_type = 'NEW' THEN jsonb_build_object(
            'name', ba.metadata ->> 'name',
            'entity_type', ba.metadata ->> 'entity_type'
          )
          ELSE NULL
        END,
        'claim_target', CASE
          WHEN ba.application_type = 'CLAIM' THEN jsonb_build_object(
            'id', de.id,
            'name', de.name,
            'entity_type', de.entity_type
          )
          ELSE NULL
        END
      ) AS item
    FROM public.business_applications ba
    LEFT JOIN public.directory_entities de ON de.id = ba.target_entity_id
    WHERE (
      (p_status IS NULL AND ba.status IN (
        'SUBMITTED', 'UNDER_REVIEW', 'CONTACTED', 'VISIT_SCHEDULED'
      ))
      OR ba.status = p_status
    )
      AND (p_application_type IS NULL
           OR ba.application_type = p_application_type)
      AND (p_cursor_created_at IS NULL
           OR (ba.created_at, ba.id) > (p_cursor_created_at, p_cursor_id))
    ORDER BY ba.created_at ASC, ba.id ASC
    LIMIT p_limit + 1
  ), page AS (
    SELECT *
    FROM fetched
    ORDER BY cursor_created_at ASC, cursor_id ASC
    LIMIT p_limit
  )
  SELECT jsonb_build_object(
    'items', COALESCE(
      (
        SELECT jsonb_agg(page.item ORDER BY page.cursor_created_at, page.cursor_id)
        FROM page
      ),
      '[]'::jsonb
    ),
    'next_cursor', CASE
      WHEN (SELECT count(*) FROM fetched) > p_limit THEN (
        SELECT jsonb_build_object(
          'created_at', page.cursor_created_at,
          'id', page.cursor_id
        )
        FROM page
        ORDER BY page.cursor_created_at DESC, page.cursor_id DESC
        LIMIT 1
      )
      ELSE NULL
    END
  )
  INTO v_result;

  RETURN v_result;
END;
$fn$;

COMMENT ON FUNCTION public.list_staff_business_applications(
  text, text, integer, timestamptz, uuid
) IS
  'V1-R07 — Permission-checked bounded staff queue. Default statuses are '
  'SUBMITTED/UNDER_REVIEW/CONTACTED/VISIT_SCHEDULED. Orders by created_at/id '
  'ascending and uses a paired keyset cursor. Returns no applicant PII.';

-- ============================================================
-- 4. Bounded staff application detail
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_staff_business_application_detail(
  p_application_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_actor uuid := auth.uid();
  v_row public.business_applications;
  v_applicant_display_name text;
  v_applicant_phone text;
  v_target public.directory_entities;
  v_contacts jsonb;
  v_visits jsonb;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;

  IF NOT public.has_staff_application_permission(
       'business_applications.read') THEN
    RAISE EXCEPTION 'staff_permission_denied' USING ERRCODE = 'P0PER';
  END IF;

  SELECT ba.*
    INTO v_row
    FROM public.business_applications ba
    WHERE ba.id = p_application_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'application_not_found' USING ERRCODE = 'P0NOT';
  END IF;

  SELECT p.display_name, p.phone
    INTO v_applicant_display_name, v_applicant_phone
    FROM public.profiles p
    WHERE p.user_id = v_row.applicant_user_id;

  IF v_row.target_entity_id IS NOT NULL THEN
    SELECT de.*
      INTO v_target
      FROM public.directory_entities de
      WHERE de.id = v_row.target_entity_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'entity_not_found' USING ERRCODE = 'P0NOT';
    END IF;
  END IF;

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', ac.id,
        'contacted_by_user_id', ac.contacted_by_user_id,
        'contacted_at', ac.contacted_at,
        'contact_type', ac.contact_type,
        'result', ac.result,
        'notes', ac.notes
      ) ORDER BY ac.contacted_at ASC, ac.id ASC
    ),
    '[]'::jsonb
  )
  INTO v_contacts
  FROM (
    SELECT history.*
    FROM public.application_contacts history
    WHERE history.application_id = v_row.id
    ORDER BY history.contacted_at DESC, history.id DESC
    LIMIT 50
  ) AS ac;

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', av.id,
        'scheduled_at', av.scheduled_at,
        'completed_at', av.completed_at,
        'status', av.status,
        'location', av.location,
        'notes', av.notes,
        'visited_by_user_id', av.visited_by_user_id,
        'created_at', av.created_at,
        'updated_at', av.updated_at
      ) ORDER BY av.scheduled_at ASC, av.id ASC
    ),
    '[]'::jsonb
  )
  INTO v_visits
  FROM (
    SELECT history.*
    FROM public.application_visits history
    WHERE history.application_id = v_row.id
    ORDER BY history.scheduled_at DESC, history.id DESC
    LIMIT 50
  ) AS av;

  RETURN jsonb_build_object(
    'application', jsonb_build_object(
      'id', v_row.id,
      'application_type', v_row.application_type,
      'status', v_row.status,
      'target_entity_id', v_row.target_entity_id,
      'reviewed_by_user_id', v_row.reviewed_by_user_id,
      'reviewed_at', v_row.reviewed_at,
      'return_reason', v_row.return_reason,
      'rejection_reason', v_row.rejection_reason,
      'approved_at', v_row.approved_at,
      'activated_at', v_row.activated_at,
      'created_at', v_row.created_at,
      'updated_at', v_row.updated_at
    ),
    'applicant', jsonb_build_object(
      'display_name', v_applicant_display_name,
      'phone', v_applicant_phone
    ),
    'new_business', CASE
      WHEN v_row.application_type = 'NEW' THEN jsonb_build_object(
        'name', v_row.metadata ->> 'name',
        'entity_type', v_row.metadata ->> 'entity_type'
      )
      ELSE NULL
    END,
    'claim_target', CASE
      WHEN v_row.application_type = 'CLAIM' THEN jsonb_build_object(
        'id', v_target.id,
        'name', v_target.name,
        'entity_type', v_target.entity_type,
        'lifecycle_status', v_target.lifecycle_status,
        'verification_status', v_target.verification_status,
        'claim_status', v_target.claim_status
      )
      ELSE NULL
    END,
    'contacts', v_contacts,
    'visits', v_visits
  );
END;
$fn$;

COMMENT ON FUNCTION public.get_staff_business_application_detail(uuid) IS
  'V1-R07 — Permission-checked bounded staff review detail. Applicant PII is '
  'limited to display_name and phone; NEW metadata and CLAIM target data are '
  'projected explicitly; contact/visit histories are each capped at 50 rows. '
  'No raw profile, audit log, or generic staff notes are returned.';

-- ============================================================
-- 5. Client execute lockdown
-- ============================================================

REVOKE EXECUTE ON FUNCTION public.get_staff_application_capabilities()
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_staff_application_capabilities()
  TO authenticated;

REVOKE EXECUTE ON FUNCTION public.list_staff_business_applications(
  text, text, integer, timestamptz, uuid
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_staff_business_applications(
  text, text, integer, timestamptz, uuid
) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.get_staff_business_application_detail(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_staff_business_application_detail(uuid)
  TO authenticated;
