-- A5.3.1 — Migration 00011: business_application write hardening
--
-- Direct applicant UPDATE on public.business_applications is
-- intentionally denied.
--
-- Migration 00010 (already applied remotely) granted authenticated
-- UPDATE plus a status-aware UPDATE policy. Although RLS enforced
-- row ownership and status transitions, PostgreSQL UPDATE still let
-- the applicant write server/staff-owned operational columns:
--   reviewed_by_user_id, reviewed_at, approved_at, rejection_reason,
--   return_reason, and other operational/review metadata.
--
-- Remedy (small atomic change):
--   1. REVOKE UPDATE on public.business_applications from authenticated.
--   2. DROP the applicant UPDATE policy created by migration 00010.
--
-- Preserved unchanged:
--   - INSERT own (authenticated)
--   - SELECT own (authenticated)
--   - no DELETE
--   - all staff/server tables remain grant-protected
--   - every other A5.3 policy and grant untouched.
--
-- Future draft editing / submission must use an explicit,
-- server-authorized mutation contract (RPC / service layer) designed
-- when the Business Application feature is implemented. A weak ad-hoc
-- RPC or a privileged helper function is intentionally NOT introduced now.
--
-- Security > premature functionality.

REVOKE UPDATE ON public.business_applications FROM authenticated;

DROP POLICY "business_applications_update_own" ON public.business_applications;