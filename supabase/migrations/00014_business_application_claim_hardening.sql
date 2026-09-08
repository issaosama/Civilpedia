-- A6.2 — Migration 00014: business application CLAIM authoritative hardening
--
-- Architect blocker resolution: client/domain prechecks alone are racy.
-- Two invariants are made authoritative at the database:
--
--   INVARIANT 1 — a CLAIM target already claimed is not claimable:
--     `directory_entities.claim_status` is the canonical claimability signal.
--     * 'unclaimed' → a new CLAIM application may be created.
--     * 'pending'   → a claim/ownership transfer is being reviewed → NOT
--                     claimable (fail closed).
--     * 'claimed'   → ownership approved and linked via business_memberships
--                     → NOT claimable (fail closed).
--     Values/casing audited from migration 00005 (CHECK constraint, all
--     lowercase). Enforced by a BEFORE INSERT trigger that reads the target
--     row with the owner's privileges (SECURITY DEFINER) and raises a
--     deterministic custom SQLSTATE ('P0CLM') mapped to a typed denial in
--     Flutter. A missing target is intentionally left to the existing FK
--     (SQLSTATE 23503 → targetNotFound) so the two outcomes stay distinct.
--
--   INVARIANT 2 — no concurrent duplicate live CLAIM per (applicant, target):
--     partial UNIQUE INDEX on (applicant_user_id, target_entity_id) for
--     CLAIM rows whose status is still LIVE. Concurrent identical inserts
--     conflict at the index (SQLSTATE 23505) → a typed duplicateClaim denial.
--
-- LIVE vs FINAL statuses (product semantics of migration 00007 as encoded in
-- the A6.2 domain `BusinessApplicationStatus.isFinal`:
--   isFinal = REJECTED or ACTIVATED only).
--   * LIVE   = DRAFT, SUBMITTED, UNDER_REVIEW, NEEDS_CORRECTION,
--              CONTACTED, VISIT_SCHEDULED, APPROVED.  (APPROVED is live: it
--              still awaits activation.)
--   * FINAL  = REJECTED, ACTIVATED. A truly final application releases the
--              (applicant, target) slot, permitting a later new claim where
--              the product allows retry.
--
-- Scope safety:
--   * The index is partial to application_type = 'CLAIM'. NEW applications
--     (NULL target) are never indexed. CLAIM rows always satisfy
--     target_entity_id IS NOT NULL via chk_app_requires_target_for_claim.
--   * NULL applicant_user_id rows (auth user deleted, ON DELETE SET NULL) are
--     distinct under PostgreSQL NULL semantics — harmless, and such a user
--     cannot act.
--   * Additive only: no DROP/DELETE/TRUNCATE/ALTER of existing objects.
--   * RLS (00010/00011) untouched: INSERT own + SELECT own, UPDATE revoked.
--   * Creating a CLAIM application still creates NO business_memberships,
--     never mutates directory_entities.claim_status, never verifies/activates,
--     never grants ownership. This migration only validates whether the
--     application row itself may be inserted.
--   * A later activation/staff flow that sets claim_status = 'claimed'
--     delivers the INVARIANT-1 'already claimed' refusal for subsequent
--     claims; it does not retroactively rewrite history.

-- ============================================================
-- INVARIANT 2: authoritative duplicate live CLAIM protection
-- ============================================================
CREATE UNIQUE INDEX uq_business_applications_live_claim
  ON public.business_applications (applicant_user_id, target_entity_id)
  WHERE application_type = 'CLAIM'
    AND status IN (
      'DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'NEEDS_CORRECTION',
      'CONTACTED', 'VISIT_SCHEDULED', 'APPROVED'
    );

COMMENT ON INDEX public.uq_business_applications_live_claim IS
  'A6.2 — At most one LIVE CLAIM application per (applicant_user_id, '
  'target_entity_id). LIVE = all nine statuses except REJECTED/ACTIVATED '
  '(both final). Concurrent identical CLAIM inserts conflict here (23505) and '
  'are mapped to a typed duplicateClaim denial in Flutter. FINAL applications '
  'release the slot, so a later new claim after a rejected/activated '
  'application is permitted.';

-- ============================================================
-- INVARIANT 1: claimability of the CLAIM target at insert time
-- ============================================================
CREATE OR REPLACE FUNCTION public.guard_claim_application_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.application_type = 'CLAIM' THEN
    IF EXISTS (
      SELECT 1 FROM public.directory_entities
      WHERE id = NEW.target_entity_id
        AND claim_status <> 'unclaimed'
    ) THEN
      RAISE EXCEPTION 'target entity is not claimable (claim_status is not unclaimed)'
        USING ERRCODE = 'P0CLM';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.guard_claim_application_insert() IS
  'A6.2 — BEFORE INSERT guard on public.business_applications: a new CLAIM '
  'application is only accepted when the target directory_entities row exists '
  'with claim_status = ''unclaimed'' (authoritative INVARIANT 1). A target with '
  'claim_status pending/claimed (or unreadable) fails closed via custom '
  'SQLSTATE P0CLM, mapped to a typed targetNotClaimable denial in Flutter. '
  'Reads with SECURITY DEFINER so RLS (active-only entity visibility) never '
  'weakens authority; performs no writes, so no privilege surface is added. '
  'NEW applications and missing targets flow through untouched (the FK emits '
  '23503 → targetNotFound).';

CREATE TRIGGER trigger_guard_claim_insert
  BEFORE INSERT ON public.business_applications
  FOR EACH ROW EXECUTE PROCEDURE public.guard_claim_application_insert();

COMMENT ON TRIGGER trigger_guard_claim_insert ON public.business_applications IS
  'A6.2 — Enforces CLAIM-target claimability (claim_status) before any row is '
  'inserted. Invariant 1 backstop for the CREATE CLAIM flow.';