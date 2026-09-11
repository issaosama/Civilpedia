# V1-R05 — Independent Focused Review — Correction Report

CURRENT_PHASE_ID: V1-R05
CURRENT_PHASE_TITLE: Directory Cloud Integration
CURRENT_PHASE_CONTRACT: V1-R05-CONTRACT-v1
CORRECTION PASS: TARGETED — no redesign, no scope expansion
CORRECTION SOURCE: V1-R05 Independent Focused Review (decision: FAIL — correction required)

## Final decision

**CONTRACT RESTORE BLOCKED — EXACT ARCHITECT CONTRACT SOURCE REQUIRED**

The exact, frozen Architect-authored text for `V1-R05-CONTRACT-v1` is not
stored in this repository (the contracts path held an Implementation Report;
roadmap `CIVILPEDIA_V1_MASTER_ROADMAP.md` at section 7.1 line 122 references
only the version id). Per the correction-pass instruction set, the contract is
never recreated from memory. All functional corrections that could be verified
against migration-truth, roadmap reference, and existing tests were applied and
verified as described below; final phase closure and V1-R06 promotion remain
Architect decisions gated on contract restoration.

## Review findings addressed

| # | Finding | Correction |
|---|---------|-----------|
| 1 | Gateway SELECT projections used a single `name` column for `directory_categories` and `regions` (both are bilingual: `name_ar`, `name_en`) and a non-existent `caption` on `entity_media` | `supabase_directory_read_gateway.dart` now projects `directory_categories(id, code, name_ar, name_en)`, `regions(id, code, name_ar, name_en)`, and `entity_media(id, url, media_type)`; `caption` was dropped from parsing entirely; added a `_displayName` (English-first, Arabic fallback) helper and UUID guard on `loadById`. Verified against `supabase/migrations/00005`, `00006`, `00002/00012/00013`. |
| 2 | Parsing fell back to invented default states (e.g. bogus `verification_status` → `unverified`) instead of failing closed | `canonical_directory_entity.dart` `tryFromRow`/`tryFromJson` now fail closed: valid canonical UUID `id`, known `entity_type` (9 codes), known `lifecycle_status`, known `claim_status`, and known `verification_status` are ALL required; any missing/unknown value returns null. `isValidUuid` uses format-only validation (accepts the zero test ids). |
| 3 | Cache silently dropped malformed entity rows, letting a partial snapshot stand | `directory_cloud_cache.dart` `tryDecode` now rejects the WHOLE snapshot when any entity row fails closed parsing (no authoritative row is silently dropped; repository attempts cloud refresh instead). |
| 4 | Detail navigation could treat a whole-entity `extra` as authoritative detail state | Routing now always resolves through the canonical ID route: new `DirectoryProviderDetailResolver` (repository/cache-authoritative, seed entity only a non-authoritative first-frame hint, mismatched/unknown ids rejected). Search, Saved, and sponsored surfaces push `/directory/entity/:id` with the resolved repository destination. |
| 5 | W5.1 guard used a naming-pattern regex (`directory_*`) | `test/w5_1_directory_repository_test.dart` now enforces an explicit approved static-key baseline (all pre-existing keys + exactly `directory_cloud_cache`); any new/renamed literal fails regardless of prefix/name. |

## Verification (this pass)

- `flutter test test/v1_r05_directory_cloud_integration_test.dart` → **+72: All tests passed** (original 42 plus strengthened A–N coverage: projection contract, bilingual mapping, whole-snapshot cache rejection, canonical routing resolution).
- Affected routing/Saved/W5.x suites: `w5_1`, `w5_3`, `w5_4` (screen), `w5_5` clearance, `w5_6` saved screen, `w6_2`, `w7_2` (screen + coordinator), plus detail/card/verification/save screens → **+110 +26 +130: all passed**.
- `git diff --check` → clean (no whitespace errors; only LF→CRLF notices).
- `git status --short` → only intended V1-R05 files modified/added; `OpenCode_Usage_Report.txt` untracked and untouched; nothing staged or committed.
- No V1-R04 claim tests import the corrected files — no claim-gateway regression path.

## Not run (pre-existing environment/constraint, unchanged)

- `flutter analyze` crashes on a pre-existing SDK analyzer bug (`Bad state: No definition of type Enum`, Flutter 3.32.8 / Dart 3.8.1); compilation correctness is carried by the passing test compilation. Not re-run per scope rules.
- DEV Supabase read smoke: no DEV credentials exist in the workspace (only placeholder `https://project.supabase.co` test config); cannot be performed.
- Full suite: not re-run (existing +1800 PASS evidence reused per re-verification rules).

## Deliverables (this pass)

- `docs/architecture/reports/V1-R05_DIRECTORY_CLOUD_INTEGRATION_IMPLEMENTATION_REPORT.md` — implementation report relocated from the contract path.
- `docs/architecture/contracts/V1-R05_DIRECTORY_CLOUD_INTEGRATION_CONTRACT.md` — **BLOCKED** placeholder requiring the exact Architect contract source.
- This correction report for the Independent Focused Review.

IMPLEMENTATION CORRECTED — CLOSURE BLOCKED ON CONTRACT RESTORATION (Architect decision)

---

## STATUS UPDATE — SUPERSEDED

The contract restoration blocker recorded above was subsequently resolved after the Architect supplied the exact frozen V1-R05-CONTRACT-v1 source. The frozen contract was restored verbatim. The historical blocked decision above is retained as evidence but no longer represents the current phase state.

The frozen contract now lives at `docs/architecture/contracts/V1-R05_DIRECTORY_CLOUD_INTEGRATION_CONTRACT.md` (restored, immutable). This report remains implementation/review evidence only.