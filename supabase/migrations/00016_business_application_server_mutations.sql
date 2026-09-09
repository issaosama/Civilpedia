-- A6.3 — Migration 00016: business application server-authorized mutations
--
-- Architecture:
--   Direct applicant/staff mutation of public.business_applications is denied
--   for `authenticated` (00010 baseline + 00011 write hardening: UPDATE revoked,
--   no UPDATE policy, no DELETE). A6.3 replaces the "unavailable" placeholder
--   with an explicit, narrow, server-authorized mutation contract implemented
--   as SECURITY DEFINER RPC functions. All authorization and state transitions
--   are authoritative at the database; the Flutter client calls RPCs only and
--   never issues a PostgREST UPDATE/DELETE on business_applications.
--
-- Authoritative transition matrix (server-enforced, acyclic, fail closed):
--   * Applicant  submit    DRAFT            → SUBMITTED
--   * Applicant  resubmit  NEEDS_CORRECTION → SUBMITTED
--   * Staff      review    SUBMITTED        → UNDER_REVIEW
--   * Staff      correct   UNDER_REVIEW     → NEEDS_CORRECTION   (reason required)
--   * Staff      contact   UNDER_REVIEW     → CONTACTED          (contact record)
--   * Staff      visit     UNDER_REVIEW     → VISIT_SCHEDULED    (visit record)
--   * Staff      approve   UNDER_REVIEW / CONTACTED / VISIT_SCHEDULED → APPROVED
--   * Staff      reject    UNDER_REVIEW / CONTACTED / VISIT_SCHEDULED → REJECTED (reason required)
--   * APPROVED / REJECTED are terminal in A6.3.
--
-- ACTIVATION IS DELIBERATELY NOT IMPLEMENTED (deferred to A6.4):
--   ACTIVATED requires atomic directory_entities row creation + business
--   membership OWNER provisioning + claim_status transition which cannot be
--   safely determined yet. Activating an APPROVED application as a status-only
--   change would be a fake activation and is NOT introduced. No A6.3 mutation
--   ever creates a membership, never writes directory_entities.claim_status /
--   verification_status, and never performs ownership side effects.
--
-- Concurrency contract:
--   * Every mutation SELECTs the application row FOR UPDATE before validating
--     status, so concurrent transitions serialize on the application row.
--   * Applicant submit/resubmit for CLAIM additionally re-validate the target
--     under the directory_entities row lock (boundary from 00015): lock the
--     entity FOR UPDATE, then require claim_status = 'unclaimed'.
--   * A6.3 never writes claim_status, so there is no competing entity write;
--     the documented lock order for A6.3 is: application row → (submit/resubmit
--     only) target entity row. A6.4 activation (disallowed today) must keep
--     this order and re-check claimability under the same lock.
--
-- Staff authorization contract:
--   staff_memberships (is_active + effective/expiry window) → role_permissions
--   → permissions.code. Identity is ALWAYS derived from auth.uid() server-side;
--   no caller-supplied user id/role/email is ever trusted. Access tables carry
--   zero anon/authenticated grants (00010) and stay that way — the SECURITY
--   DEFINER helpers read them with owner privileges only.
--
-- Typed error contract (custom SQLSTATE, no raw SQL surfaced to Flutter):
--   P0AUT  unauthenticated (no auth session)
--   P0NAC  not the applicant (applicant RPCs only)
--   P0NOT   application not found
--   P0TRA  invalid transition for the current status
--   P0PHR  authoritative phone (profiles.phone) missing on the applicant
--   P0DAT  required application data missing (NEW without candidate metadata,
--           staff record data invalid/missing)
--   P0CLM   CLAIM target is not claimable (claim_status <> 'unclaimed')
--   P0COR  correction reason required and empty
--   P0REJ  rejection reason required and empty
--   P0PER  staff permission denied
--
-- Security-sensitive transitions write public.audit_logs IN THE SAME
-- TRANSACTION as the state change, so an audit write failure rolls back the
-- transition (an unlogged sensitive change is impossible). Audit payloads
-- contain status snapshots only — no metadata, no phone, no tokens.

-- ============================================================
-- Part 1 — Minimal staff permission reference data (A5.3 gap)
-- ============================================================
-- permissions was schema-only; these are the minimal codes the A6.3 staff
-- surface requires. No broader role hierarchy is invented here.
INSERT INTO public.permissions (code, description)
VALUES
  ('business_applications.review',
   'Begin review of a SUBMITTED business application'),
  ('business_applications.return_for_correction',
   'Return an UNDER_REVIEW application for applicant correction'),
  ('business_applications.mark_contacted',
   'Record an applicant contact attempt on an UNDER_REVIEW application'),
  ('business_applications.schedule_visit',
   'Schedule a site visit for an UNDER_REVIEW application'),
  ('business_applications.approve',
   'Approve an application (pre-activation; grants no ownership)'),
  ('business_applications.reject',
   'Reject an application')
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.roles (code, name, is_protected)
VALUES ('application_reviewer', 'Application Reviewer', true)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
CROSS JOIN public.permissions p
WHERE r.code = 'application_reviewer'
  AND p.code IN (
    'business_applications.review',
    'business_applications.return_for_correction',
    'business_applications.mark_contacted',
    'business_applications.schedule_visit',
    'business_applications.approve',
    'business_applications.reject'
  )
ON CONFLICT DO NOTHING;

-- ============================================================
-- Part 2 — Internal helpers (NOT exposed to clients)
-- ============================================================
-- Both helpers are SECURITY DEFINER so they read grant-protected staff/audit
-- tables as the function owner (RLS bypassed like the rest of the 00010
-- server-side design). They receive NO EXECUTE grants below, so only
-- definer-context RPC functions can call them.

CREATE OR REPLACE FUNCTION public.has_staff_application_permission(
  p_permission text
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
  SELECT EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    JOIN public.role_permissions rp ON rp.role_id = sm.role_id
    JOIN public.permissions perm ON perm.id = rp.permission_id
    WHERE sm.user_id = auth.uid()
      AND sm.is_active
      AND (sm.expires_at IS NULL OR sm.expires_at > now())
      AND sm.effective_at <= now()
      AND perm.code = p_permission
  );
$fn$;

COMMENT ON FUNCTION public.has_staff_application_permission(p_permission text) IS
  'A6.3 — Single authorization gate for business-application staff actions. '
  'Derives the actor purely from auth.uid(), walks staff_memberships '
  '(active + effective/expiry window) → role_permissions → permissions.code. '
  'No caller-supplied identity is ever trusted. Not granted to any client role.';

CREATE OR REPLACE FUNCTION public.append_audit_log(
  p_actor_user_id uuid,
  p_action text,
  p_target_type text,
  p_target_id uuid,
  p_before_data jsonb,
  p_after_data jsonb,
  p_reason text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
BEGIN
  INSERT INTO public.audit_logs (
    actor_user_id, action, target_type, target_id,
    before_data, after_data, reason
  ) VALUES (
    p_actor_user_id, p_action, p_target_type, p_target_id,
    p_before_data, p_after_data, p_reason
  );
END;
$fn$;

COMMENT ON FUNCTION public.append_audit_log(
  p_actor_user_id uuid, p_action text, p_target_type text, p_target_id uuid,
  p_before_data jsonb, p_after_data jsonb, p_reason text
) IS
  'A6.3 — Append-only audit insert used inside the same transaction as a '
  'security-sensitive business-application mutation. If the audit write fails '
  'the surrounding transition rolls back. Sanitized: caller passes status '
  'snapshots/reason only. Not granted to any client role.';

-- ============================================================
-- Part 3 — Applicant RPCs (granted to authenticated)
-- ============================================================

CREATE OR REPLACE FUNCTION public.submit_business_application(
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
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;

  SELECT ba.* INTO v_row
    FROM public.business_applications ba
   WHERE ba.id = p_application_id
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'application_not_found' USING ERRCODE = 'P0NOT';
  END IF;

  IF v_row.applicant_user_id IS DISTINCT FROM v_actor THEN
    RAISE EXCEPTION 'not_applicant' USING ERRCODE = 'P0NAC';
  END IF;

  IF v_row.status <> 'DRAFT' THEN
    RAISE EXCEPTION 'invalid_transition'
      USING ERRCODE = 'P0TRA',
            DETAIL = 'only a DRAFT application may be submitted';
  END IF;

  -- Frozen product contract: authoritative phone must be present before an
  -- application may progress. Presence only — phone present is NOT phone
  -- confirmed/verified (verification is out of contract and not invented).
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
     WHERE p.user_id = v_actor
       AND p.phone IS NOT NULL
       AND length(trim(p.phone)) > 0
  ) THEN
    RAISE EXCEPTION 'phone_required' USING ERRCODE = 'P0PHR';
  END IF;

  IF v_row.application_type = 'NEW' AND v_row.metadata IS NULL THEN
    RAISE EXCEPTION 'required_application_data_missing' USING ERRCODE = 'P0DAT';
  END IF;

  -- CLAIM: re-validate the target under the 00015 entity-lock boundary.
  IF v_row.application_type = 'CLAIM' THEN
    PERFORM 1
      FROM public.directory_entities de
     WHERE de.id = v_row.target_entity_id
       FOR UPDATE;
    IF EXISTS (
      SELECT 1 FROM public.directory_entities de
       WHERE de.id = v_row.target_entity_id
         AND de.claim_status <> 'unclaimed'
    ) THEN
      RAISE EXCEPTION 'target_not_claimable' USING ERRCODE = 'P0CLM';
    END IF;
  END IF;

  -- Fresh submission clears stale review/anchor state. return_reason and
  -- rejection_reason are deliberately preserved for traceability.
  UPDATE public.business_applications ba
     SET status = 'SUBMITTED',
         reviewed_by_user_id = NULL,
         reviewed_at = NULL,
         approved_at = NULL
   WHERE ba.id = v_row.id
   RETURNING * INTO v_row;

  PERFORM public.append_audit_log(
    v_actor,
    'BUSINESS_APPLICATION_SUBMIT',
    'business_application',
    v_row.id,
    jsonb_build_object('status', 'DRAFT'),
    jsonb_build_object('status', 'SUBMITTED'),
    NULL
  );

  RETURN v_row;
END;
$fn$;

COMMENT ON FUNCTION public.submit_business_application(p_application_id uuid) IS
  'A6.3 — Applicant submits a DRAFT application → SUBMITTED. Requires an '
  'authenticated session (P0AUT), own application (P0NAC, P0NOT), status '
  'DRAFT (P0TRA), an authoritative profiles.phone on the applicant (P0PHR), '
  'candidate data for NEW (P0DAT), and a still-claimable target for CLAIM '
  '(P0CLM, verified under the entity row lock). No ownership/membership/'
  'claim_status side effects. Writes an audit record in the same transaction.';

CREATE OR REPLACE FUNCTION public.resubmit_business_application(
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
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;

  SELECT ba.* INTO v_row
    FROM public.business_applications ba
   WHERE ba.id = p_application_id
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'application_not_found' USING ERRCODE = 'P0NOT';
  END IF;

  IF v_row.applicant_user_id IS DISTINCT FROM v_actor THEN
    RAISE EXCEPTION 'not_applicant' USING ERRCODE = 'P0NAC';
  END IF;

  IF v_row.status <> 'NEEDS_CORRECTION' THEN
    RAISE EXCEPTION 'invalid_transition'
      USING ERRCODE = 'P0TRA',
            DETAIL = 'only a NEEDS_CORRECTION application may be resubmitted';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
     WHERE p.user_id = v_actor
       AND p.phone IS NOT NULL
       AND length(trim(p.phone)) > 0
  ) THEN
    RAISE EXCEPTION 'phone_required' USING ERRCODE = 'P0PHR';
  END IF;

  IF v_row.application_type = 'NEW' AND v_row.metadata IS NULL THEN
    RAISE EXCEPTION 'required_application_data_missing' USING ERRCODE = 'P0DAT';
  END IF;

  IF v_row.application_type = 'CLAIM' THEN
    PERFORM 1
      FROM public.directory_entities de
     WHERE de.id = v_row.target_entity_id
       FOR UPDATE;
    IF EXISTS (
      SELECT 1 FROM public.directory_entities de
       WHERE de.id = v_row.target_entity_id
         AND de.claim_status <> 'unclaimed'
    ) THEN
      RAISE EXCEPTION 'target_not_claimable' USING ERRCODE = 'P0CLM';
    END IF;
  END IF;

  -- Keep return_reason intact (correction history must stay traceable).
  UPDATE public.business_applications ba
     SET status = 'SUBMITTED',
         reviewed_by_user_id = NULL,
         reviewed_at = NULL,
         approved_at = NULL
   WHERE ba.id = v_row.id
   RETURNING * INTO v_row;

  PERFORM public.append_audit_log(
    v_actor,
    'BUSINESS_APPLICATION_RESUBMIT',
    'business_application',
    v_row.id,
    jsonb_build_object('status', 'NEEDS_CORRECTION'),
    jsonb_build_object('status', 'SUBMITTED'),
    NULL
  );

  RETURN v_row;
END;
$fn$;

COMMENT ON FUNCTION public.resubmit_business_application(p_application_id uuid) IS
  'A6.3 — Applicant resubmits a NEEDS_CORRECTION application → SUBMITTED. '
  'Same identity/data/phone/claimability gates as submit; history is preserved '
  '(return_reason never erased). No ownership side effects. Audit in same tx.';

-- ============================================================
-- Part 4 — Staff RPCs (granted to authenticated; internally require
-- a staff_memberships membership holding the matching permission)
-- ============================================================

CREATE OR REPLACE FUNCTION public.staff_begin_application_review(
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
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;
  IF NOT public.has_staff_application_permission(
       'business_applications.review') THEN
    RAISE EXCEPTION 'staff_permission_denied' USING ERRCODE = 'P0PER';
  END IF;

  SELECT ba.* INTO v_row
    FROM public.business_applications ba
   WHERE ba.id = p_application_id
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'application_not_found' USING ERRCODE = 'P0NOT';
  END IF;

  IF v_row.status <> 'SUBMITTED' THEN
    RAISE EXCEPTION 'invalid_transition'
      USING ERRCODE = 'P0TRA',
            DETAIL = 'only a SUBMITTED application may be reviewed';
  END IF;

  UPDATE public.business_applications ba
     SET status = 'UNDER_REVIEW',
         reviewed_by_user_id = v_actor,
         reviewed_at = now()
   WHERE ba.id = v_row.id
   RETURNING * INTO v_row;

  PERFORM public.append_audit_log(
    v_actor,
    'BUSINESS_APPLICATION_REVIEW_BEGIN',
    'business_application',
    v_row.id,
    jsonb_build_object('status', 'SUBMITTED'),
    jsonb_build_object('status', 'UNDER_REVIEW'),
    NULL
  );

  RETURN v_row;
END;
$fn$;

COMMENT ON FUNCTION public.staff_begin_application_review(p_application_id uuid) IS
  'A6.3 — Staff: SUBMITTED → UNDER_REVIEW. Requires business_applications.'
  '.review permission. No ownership side effects. Audit in same tx.';

CREATE OR REPLACE FUNCTION public.staff_return_application_for_correction(
  p_application_id uuid,
  p_reason text
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
  IF NOT public.has_staff_application_permission(
       'business_applications.return_for_correction') THEN
    RAISE EXCEPTION 'staff_permission_denied' USING ERRCODE = 'P0PER';
  END IF;
  IF p_reason IS NULL OR length(trim(p_reason)) = 0 THEN
    RAISE EXCEPTION 'correction_reason_required' USING ERRCODE = 'P0COR';
  END IF;

  SELECT ba.* INTO v_row
    FROM public.business_applications ba
   WHERE ba.id = p_application_id
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'application_not_found' USING ERRCODE = 'P0NOT';
  END IF;

  IF v_row.status <> 'UNDER_REVIEW' THEN
    RAISE EXCEPTION 'invalid_transition'
      USING ERRCODE = 'P0TRA',
            DETAIL = 'only an UNDER_REVIEW application may be returned for correction';
  END IF;

  UPDATE public.business_applications ba
     SET status = 'NEEDS_CORRECTION',
         return_reason = trim(p_reason),
         reviewed_by_user_id = v_actor,
         reviewed_at = now()
   WHERE ba.id = v_row.id
   RETURNING * INTO v_row;

  PERFORM public.append_audit_log(
    v_actor,
    'BUSINESS_APPLICATION_RETURN_FOR_CORRECTION',
    'business_application',
    v_row.id,
    jsonb_build_object('status', 'UNDER_REVIEW'),
    jsonb_build_object('status', 'NEEDS_CORRECTION'),
    trim(p_reason)
  );

  RETURN v_row;
END;
$fn$;

COMMENT ON FUNCTION public.staff_return_application_for_correction(
  p_application_id uuid, p_reason text
) IS
  'A6.3 — Staff: UNDER_REVIEW → NEEDS_CORRECTION with a required reason. '
  'History preserved for the applicant. No ownership side effects. Audit in same tx.';

CREATE OR REPLACE FUNCTION public.staff_mark_application_contacted(
  p_application_id uuid,
  p_contact_type text,
  p_result text DEFAULT NULL,
  p_notes text DEFAULT NULL
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
  IF NOT public.has_staff_application_permission(
       'business_applications.mark_contacted') THEN
    RAISE EXCEPTION 'staff_permission_denied' USING ERRCODE = 'P0PER';
  END IF;
  IF p_contact_type IS NULL
     OR p_contact_type NOT IN ('phone', 'whatsapp', 'email', 'visit', 'other')
  THEN
    RAISE EXCEPTION 'invalid_contact_type' USING ERRCODE = 'P0DAT';
  END IF;

  SELECT ba.* INTO v_row
    FROM public.business_applications ba
   WHERE ba.id = p_application_id
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'application_not_found' USING ERRCODE = 'P0NOT';
  END IF;

  IF v_row.status <> 'UNDER_REVIEW' THEN
    RAISE EXCEPTION 'invalid_transition'
      USING ERRCODE = 'P0TRA',
            DETAIL = 'only an UNDER_REVIEW application may be recorded as contacted';
  END IF;

  -- Operational contact history (grant-protected table, reached only through
  -- this definer context).
  INSERT INTO public.application_contacts (
    application_id, contacted_by_user_id, contact_type, result, notes
  ) VALUES (
    v_row.id, v_actor, p_contact_type,
    NULLIF(trim(p_result), ''), NULLIF(trim(p_notes), '')
  );

  UPDATE public.business_applications ba
     SET status = 'CONTACTED',
         reviewed_by_user_id = v_actor,
         reviewed_at = now()
   WHERE ba.id = v_row.id
   RETURNING * INTO v_row;

  PERFORM public.append_audit_log(
    v_actor,
    'BUSINESS_APPLICATION_CONTACTED',
    'business_application',
    v_row.id,
    jsonb_build_object('status', 'UNDER_REVIEW'),
    jsonb_build_object('status', 'CONTACTED'),
    NULLIF(trim(p_notes), '')
  );

  RETURN v_row;
END;
$fn$;

COMMENT ON FUNCTION public.staff_mark_application_contacted(
  p_application_id uuid, p_contact_type text, p_result text, p_notes text
) IS
  'A6.3 — Staff: UNDER_REVIEW → CONTACTED and inserts an application_contacts '
  'record with the actor from auth.uid(). Contact submitted via this RPC never '
  'creates ownership/membership. Audit in same tx.';

CREATE OR REPLACE FUNCTION public.staff_schedule_application_visit(
  p_application_id uuid,
  p_scheduled_at timestamptz,
  p_location text DEFAULT NULL,
  p_notes text DEFAULT NULL
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
  IF NOT public.has_staff_application_permission(
       'business_applications.schedule_visit') THEN
    RAISE EXCEPTION 'staff_permission_denied' USING ERRCODE = 'P0PER';
  END IF;
  IF p_scheduled_at IS NULL THEN
    RAISE EXCEPTION 'scheduled_at_required' USING ERRCODE = 'P0DAT';
  END IF;

  SELECT ba.* INTO v_row
    FROM public.business_applications ba
   WHERE ba.id = p_application_id
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'application_not_found' USING ERRCODE = 'P0NOT';
  END IF;

  IF v_row.status <> 'UNDER_REVIEW' THEN
    RAISE EXCEPTION 'invalid_transition'
      USING ERRCODE = 'P0TRA',
            DETAIL = 'only an UNDER_REVIEW application may schedule a visit';
  END IF;

  INSERT INTO public.application_visits (
    application_id, scheduled_at, location, notes, visited_by_user_id
  ) VALUES (
    v_row.id, p_scheduled_at,
    NULLIF(trim(p_location), ''), NULLIF(trim(p_notes), ''), v_actor
  );

  UPDATE public.business_applications ba
     SET status = 'VISIT_SCHEDULED',
         reviewed_by_user_id = v_actor,
         reviewed_at = now()
   WHERE ba.id = v_row.id
   RETURNING * INTO v_row;

  PERFORM public.append_audit_log(
    v_actor,
    'BUSINESS_APPLICATION_VISIT_SCHEDULED',
    'business_application',
    v_row.id,
    jsonb_build_object('status', 'UNDER_REVIEW'),
    jsonb_build_object(
      'status', 'VISIT_SCHEDULED',
      'scheduled_at', p_scheduled_at
    ),
    NULLIF(trim(p_notes), '')
  );

  RETURN v_row;
END;
$fn$;

COMMENT ON FUNCTION public.staff_schedule_application_visit(
  p_application_id uuid, p_scheduled_at timestamptz, p_location text, p_notes text
) IS
  'A6.3 — Staff: UNDER_REVIEW → VISIT_SCHEDULED and inserts an '
  'application_visits record (actor = auth.uid()). No ownership side effects. '
  'Audit in same tx.';

CREATE OR REPLACE FUNCTION public.staff_approve_business_application(
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
  v_before_status text;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;
  IF NOT public.has_staff_application_permission(
       'business_applications.approve') THEN
    RAISE EXCEPTION 'staff_permission_denied' USING ERRCODE = 'P0PER';
  END IF;

  SELECT ba.* INTO v_row
    FROM public.business_applications ba
   WHERE ba.id = p_application_id
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'application_not_found' USING ERRCODE = 'P0NOT';
  END IF;

  IF v_row.status NOT IN ('UNDER_REVIEW', 'CONTACTED', 'VISIT_SCHEDULED') THEN
    RAISE EXCEPTION 'invalid_transition'
      USING ERRCODE = 'P0TRA',
            DETAIL = 'approval requires UNDER_REVIEW, CONTACTED or VISIT_SCHEDULED';
  END IF;

  v_before_status := v_row.status;

  -- APPROVED is distinct from ACTIVATED. Approval is a decision, NOT an
  -- ownership grant: no business_memberships row, no claim_status change, no
  -- verification_status change, no activation. Those are A6.4 provisioning.
  UPDATE public.business_applications ba
     SET status = 'APPROVED',
         approved_at = now(),
         reviewed_by_user_id = v_actor,
         reviewed_at = now()
   WHERE ba.id = v_row.id
   RETURNING * INTO v_row;

  PERFORM public.append_audit_log(
    v_actor,
    'BUSINESS_APPLICATION_APPROVED',
    'business_application',
    v_row.id,
    jsonb_build_object('status', v_before_status),
    jsonb_build_object('status', 'APPROVED'),
    NULL
  );

  RETURN v_row;
END;
$fn$;

COMMENT ON FUNCTION public.staff_approve_business_application(p_application_id uuid) IS
  'A6.3 — Staff: UNDER_REVIEW/CONTACTED/VISIT_SCHEDULED → APPROVED. Approval '
  'is NOT activation and creates NO ownership/membership/claim_status effect '
  '(deferred to A6.4 atomically). Audit in same tx.';

CREATE OR REPLACE FUNCTION public.staff_reject_business_application(
  p_application_id uuid,
  p_reason text
)
RETURNS public.business_applications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_actor uuid := auth.uid();
  v_row public.business_applications;
  v_before_status text;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;
  IF NOT public.has_staff_application_permission(
       'business_applications.reject') THEN
    RAISE EXCEPTION 'staff_permission_denied' USING ERRCODE = 'P0PER';
  END IF;
  IF p_reason IS NULL OR length(trim(p_reason)) = 0 THEN
    RAISE EXCEPTION 'rejection_reason_required' USING ERRCODE = 'P0REJ';
  END IF;

  SELECT ba.* INTO v_row
    FROM public.business_applications ba
   WHERE ba.id = p_application_id
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'application_not_found' USING ERRCODE = 'P0NOT';
  END IF;

  IF v_row.status NOT IN ('UNDER_REVIEW', 'CONTACTED', 'VISIT_SCHEDULED') THEN
    RAISE EXCEPTION 'invalid_transition'
      USING ERRCODE = 'P0TRA',
            DETAIL = 'rejection requires UNDER_REVIEW, CONTACTED or VISIT_SCHEDULED';
  END IF;

  v_before_status := v_row.status;

  UPDATE public.business_applications ba
     SET status = 'REJECTED',
         rejection_reason = trim(p_reason),
         reviewed_by_user_id = v_actor,
         reviewed_at = now()
   WHERE ba.id = v_row.id
   RETURNING * INTO v_row;

  PERFORM public.append_audit_log(
    v_actor,
    'BUSINESS_APPLICATION_REJECTED',
    'business_application',
    v_row.id,
    jsonb_build_object('status', v_before_status),
    jsonb_build_object('status', 'REJECTED'),
    trim(p_reason)
  );

  RETURN v_row;
END;
$fn$;

COMMENT ON FUNCTION public.staff_reject_business_application(
  p_application_id uuid, p_reason text
) IS
  'A6.3 — Staff: UNDER_REVIEW/CONTACTED/VISIT_SCHEDULED → REJECTED with a '
  'required reason. Terminal; no ownership side effects. Audit in same tx.';

-- ============================================================
-- Part 5 — EXECUTE lockdown
-- ============================================================
-- PostgreSQL grants EXECUTE to PUBLIC by default for new functions. We revoke
-- that everywhere and grant EXECUTE on the eight client-facing mutation RPCs
-- to `authenticated` ONLY (authorization happens inside each function; helpers
-- get no grants at all so they are unreachable except from definer context).
-- `anon` keeps zero EXECUTE. business_applications itself keeps the exact
-- 00010/00011 grant posture — no new table grants are issued.

REVOKE EXECUTE ON FUNCTION public.has_staff_application_permission(text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.append_audit_log(
  uuid, text, text, uuid, jsonb, jsonb, text
) FROM PUBLIC;

REVOKE EXECUTE ON FUNCTION public.submit_business_application(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.resubmit_business_application(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.staff_begin_application_review(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.staff_return_application_for_correction(
  uuid, text
) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.staff_mark_application_contacted(
  uuid, text, text, text
) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.staff_schedule_application_visit(
  uuid, timestamptz, text, text
) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.staff_approve_business_application(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.staff_reject_business_application(
  uuid, text
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.submit_business_application(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resubmit_business_application(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.staff_begin_application_review(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.staff_return_application_for_correction(
  uuid, text
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.staff_mark_application_contacted(
  uuid, text, text, text
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.staff_schedule_application_visit(
  uuid, timestamptz, text, text
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.staff_approve_business_application(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.staff_reject_business_application(
  uuid, text
) TO authenticated;