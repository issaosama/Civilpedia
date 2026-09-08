-- A6.2 — Migration 00015: business application CLAIM concurrency hardening
--
-- Architect concurrency audit follow-up to 00014.
--
-- Problem:
--   00014's trigger guard validated claimability with a plain SELECT:
--     SELECT 1 FROM directory_entities
--     WHERE id = NEW.target_entity_id AND claim_status <> 'unclaimed'
--   A plain SELECT takes no row lock. A concurrent server/staff transition
--   that changes directory_entities.claim_status (future A6.3 review/
--   activation flow) could interleave between this validation and the
--   application INSERT, so CLAIM creation could be validated against stale
--   claimability state.
--
-- Hardening:
--   The trigger now takes an explicit row lock on the target entity BEFORE
--   validating claim_status:
--     PERFORM 1 FROM public.directory_entities
--       WHERE id = NEW.target_entity_id FOR UPDATE;
--   The lock is acquired by id regardless of claim_status (so an 'unclaimed'
--   row is locked too), then claim_status is re-checked under the lock. Under
--   READ COMMITTED the re-check sees the committed state consistent with the
--   locked row version, serializing safely against any concurrent
--   claim_status transition on the same entity. The lock is held by the
--   INSERT's transaction and therefore covers the whole check-then-insert
--   window.
--
-- Scope safety (unchanged from 00014):
--   * Same trigger name: trigger_guard_claim_insert (unchanged).
--   * Same custom SQLSTATE P0CLM ('target not claimable') for claimed/pending
--     (or unreadable) targets.
--   * Missing target: FOR UPDATE matches no row, claimability check passes,
--     the application's INSERT then fails on the existing FK → 23503
--     (targetNotFound). Behavior preserved.
--   * RLS/grants untouched (INSERT own + SELECT own only; UPDATE/DELETE not
--     granted for clients).
--   * No data rewrite, no DELETE/TRUNCATE, no membership/ownership/entity
--     side effects, claim_status is never mutated by this function.
--   * No change to uq_business_applications_live_claim (00014 duplicate-live
--     protection unchanged).
--
-- A6.3+ contract note:
--   Any future server-authorized claim_status transition must respect the same
--   directory-entity/application concurrency boundary: transitions that flip
--   claimability must write directory_entities.claim_status under a row lock
--   so they serialize with CLAIM inserts as this trigger does.

CREATE OR REPLACE FUNCTION public.guard_claim_application_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.application_type = 'CLAIM' THEN
    -- Lock the target row BEFORE validating claim_status. The lock covers the
    -- whole check-then-insert window (the trigger runs inside the INSERT
    -- transaction). A missing target locks nothing; the FK (23503) still fires
    -- on the final INSERT, preserving the distinct targetNotFound outcome.
    PERFORM 1
      FROM public.directory_entities
     WHERE id = NEW.target_entity_id
       FOR UPDATE;

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
  'A6.2 (00014 + 00015) — BEFORE INSERT guard on public.business_applications: '
  'a new CLAIM application is accepted only when the target '
  'directory_entities row exists and is authoritatively claimable '
  '(claim_status = ''unclaimed''). 00015 hardens 00014 with an explicit '
  'SELECT ... FOR UPDATE row lock on the target entity, acquired before '
  'claim_status validation, serializing concurrent staff/server claim_status '
  'transitions (A6.3 concurrency boundary) so the check-then-insert window '
  'cannot validate against stale claimability. Claimed/pending (or unreadable) '
  'targets fail closed via custom SQLSTATE P0CLM → typed targetNotClaimable '
  'denial. Missing targets flow through untouched; the FK emits 23503 → '
  'targetNotFound. Performs no writes; RLS and grants are unchanged.';