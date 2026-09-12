# V1-R06 Closure Record

PHASE: V1-R06
TITLE: Business / Provider Profile Management
CONTRACT: V1-R06-CONTRACT-v1
STATUS: CLOSED
ARCHITECT_FINAL_REVIEW: PASS
INDEPENDENT_REVIEW: PASS

This closure record summarizes accepted scope and evidence. It does not duplicate the frozen contract, which remains authoritative and unchanged at `docs/architecture/contracts/V1-R06_BUSINESS_PROVIDER_PROFILE_MANAGEMENT_CONTRACT.md`.

---

## Delivered Server Scope

- Migration `supabase/migrations/00020_business_profile_management.sql`.
- No new tables; no direct Directory table write grants; no `service_role` usage.
- `auth.uid()` is the actor identity; `business_memberships` remains canonical business authority via `has_business_management_access()`.
- OWNER and ADMIN allowed; MEMBER denied; unrelated authenticated users denied; guests denied.
- `public.get_managed_business_profile(p_entity_id uuid)` — read-only management projection.
- `public.update_managed_business_profile(...)` — atomic mutation with optimistic concurrency.

## Authorization Model

- Server enforces membership role checks before any read or write.
- Client capability model (`BusinessMembershipCapabilities`) mirrors server authority for UX gating.
- MEMBER sees no management entry points; OWNER/ADMIN see **My Managed Businesses** and **Manage/Edit Public Profile**.

## RPC Guarantees

- Atomic profile update; no partial writes.
- Optimistic concurrency via `p_expected_updated_at`; stale versions raise `P0CON`.
- Protected status fields (`entity_type`, `lifecycle_status`, `claim_status`, `verification_status`, timestamps) are not client-writable.
- Primary location only; bounded contacts and categories.
- `audit_logs` event written on successful mutation.
- Verification flips `verified → pending` only for frozen material changes (name, primary region, address, coordinates).

## Flutter Management UX

- User Area → My Managed Businesses → Manage/Edit Public Profile.
- Canonical entity-ID routing.
- Fail-closed management projection parsing.
- Typed `P0*` error mapping with Arabic messages.
- Dirty-state handling, client validation, and unsaved-changes guard.
- Conflict detection with reload action.
- Online-only save; save confirmation dialog; no duplicate mutation on retry.
- Primary contact management UI.
- Canonical categories/regions selectors.
- Non-public profiles do not expose the public Preview action.

## Cache / Public Directory Integration

- Save success triggers `CloudDirectoryRepository.refresh()` to update public Directory cache.
- Refresh failure is surfaced as a non-blocking warning with **Retry public refresh**.
- No direct `directory_cloud_cache` mutation from Flutter.

## Tests / Evidence

- Part 1 server/security: 15/15 PASS.
- V1-R05 primary-location regression: 1/1 PASS.
- V1-R06 focused suite: 81/81 PASS.
- User Area routing: 29/29 PASS.
- Previous full Flutter suite: 1909/1909 PASS.
- Production `SupabaseBusinessProfileManagementGateway` behavioral tests: PASS (real gateway seam with mocked HTTP; RPC shape and error-code mapping verified).
- `git diff --check`: PASS.

## Analyzer Limitation

- `flutter analyze` remains unavailable for environment/SDK reasons; confirmed NOT causal to V1-R06 changes.

## Deferred DEV Server QA

- Live DEV Supabase smoke not executed during V1-R06.
- Status: DEFERRED — CREDENTIALS UNAVAILABLE.
- Non-blocking for V1-R06 closure; mandatory carry-forward work in V1-R14 — Supabase Production Readiness, must be completed before production launch.

## Deferred Scope

- Media upload / Supabase Storage bucket / media mutation: intentionally NOT implemented.
- Multi-location management: NOT implemented.
- Existing media remains read-only.
- These remain deferred until the Architect places them in the appropriate later V1 work.

## Scope Exclusions

- No V1-R07 implementation.
- No V1-R14 production-readiness items beyond the deferred smoke note.
- No further DB migration, RLS, or grant changes beyond migration 00020.
- No changes to V1-R05 Directory authority or cache semantics.

## Git State at Closure

- Roadmap updated: V1-R06 CLOSED; V1-R07 promoted to CURRENT; V1-R07 contract NOT_FROZEN; V1-R07 implementation NOT authorized.
- Nothing staged, committed, or pushed by this closure pass.
- Closure commit: PENDING OWNER COMMIT (owner stages explicit files after review).
- `OpenCode_Usage_Report.txt` untouched (remains untracked).
