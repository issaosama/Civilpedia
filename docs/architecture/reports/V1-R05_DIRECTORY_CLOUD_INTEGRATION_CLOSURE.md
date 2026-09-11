# V1-R05 Closure Record

PHASE: V1-R05
TITLE: Directory Cloud Integration
CONTRACT: V1-R05-CONTRACT-v1
STATUS: CLOSED
ARCHITECT_FINAL_REVIEW: PASS
INDEPENDENT_REVIEW: PASS

This closure record summarizes accepted scope and evidence. It does not duplicate the frozen contract, which remains authoritative and unchanged at `docs/architecture/contracts/V1-R05_DIRECTORY_CLOUD_INTEGRATION_CONTRACT.md`.

---

## Delivered Scope

- Canonical Directory entity model (canonical Directory identity, entity type, category, region, lifecycle, claim, verification) with fail-closed parsing.
- Production cloud-backed Directory read flow with dedicated offline snapshot cache.
- Schema-correct Supabase projections (bilingual categories/regions; media fields only `id`, `url`, `media_type`).
- Canonical Directory detail routing and Saved references by canonical entity ID.
- Explicit storage-key guard for the dedicated Directory cache key.
- Read-only cloud surface; no V1-R04 claim-gateway changes.

## Authority Model

- `public.directory_entities.id` is the canonical Directory identity.
- Production Directory authority is cloud-backed (Supabase, via `SupabaseCloudDirectoryRepository` / `SupabaseDirectoryReadGateway`).
- Legacy `sb_profiles` is isolated from production authority; no heuristic local/cloud identity mapping.
- V1-R04 claim gateway remains separate and authenticated/claim-specific.
- No profile mutations introduced by V1-R05.

## Cache/Offline Model

- `directory_cloud_cache` is an offline snapshot only — never an authority of record.
- Whole-snapshot validation; any malformed snapshot is rejected completely (fail-closed).
- Successful authoritative refresh replaces the snapshot; failed refresh preserves the last valid snapshot.
- Authoritative empty refresh replaces a stale snapshot.

## Legacy Isolation

- Legacy `sb_profiles` wrapper repository is untouched by the Directory cloud cache key.
- Behavioral test proves the surface never writes or overwrites `sb_profiles`.
- No DB migration, RLS/grant changes, or destructive data changes.

## Routing / Saved Compatibility

- Directory detail routing uses the canonical entity ID (`/directory/entity/:id`).
- Saved Directory references use the canonical entity ID.
- Existing Directory detail/card/save/search flows remain route-compatible.

## Tests / Evidence

- V1-R05 focused suite: 83/83 PASS.
- Previous full Flutter suite: 1800+ PASS.
- Relevant regression evidence: 266 PASS.
- Production `SupabaseCloudDirectoryRepository` behavioral tests: PASS.
- Production `SupabaseDirectoryReadGateway` behavioral tests: PASS (query shape intercepted; schema-accurate PostgREST responses parsed through the real gateway).
- `sb_profiles` behavioral isolation test: PASS.
- git diff --check: PASS.

## Analyzer Limitation

- `flutter analyze` crashes for environment/SDK reasons; confirmed NOT causal to V1-R05 changes.

## Deferred Live DEV Smoke

- Live DEV Supabase smoke not executed during V1-R05.
- Status: DEFERRED — ENVIRONMENT CREDENTIALS UNAVAILABLE.
- Non-blocking for V1-R05 closure; mandatory carry-forward work in V1-R14 — Supabase Production Readiness, must be completed before production launch.

## Scope Exclusions

- No V1-R06 profile management implementation.
- No V1-R14 production-readiness items beyond the deferred smoke note.
- No DB migration, RLS, or grant changes.
- No changes to the V1-R04 claim gateway.

## Git State at Closure

- Roadmap updated: V1-R05 CLOSED; V1-R06 promoted to CURRENT; V1-R06 contract NOT_FROZEN; V1-R06 implementation NOT authorized.
- Nothing staged, committed, or pushed by this closure pass.
- Closure commit: PENDING OWNER COMMIT (owner stages explicit files after review).
- `OpenCode_Usage_Report.txt` untouched (remains untracked).