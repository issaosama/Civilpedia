# V1-R07 — Independent Focused Review — Correction Report (Part 2: Flutter App)

CURRENT_PHASE_ID: V1-R07
CURRENT_PHASE_TITLE: Staff Admin Operations Foundation
CURRENT_PHASE_CONTRACT: V1-R07_STAFF_ADMIN_OPERATIONS_FOUNDATION_CONTRACT
CORRECTION PASS: TARGETED — no redesign, no scope expansion, no migration changes
CORRECTION SOURCE: V1-R07 Independent Focused Review Part 2 (23 Flutter correction findings)

## Context

- Part 1 (Server / Security) was **ACCEPTED** (28/28 focused server tests; A6 server regression 37/37). No server, migration, contract, or roadmap text was modified during this pass.
- This pass corrected the Flutter-layer findings only. All corrections are implemented locally in the app layer and verified with the three prescribed `--no-pub` focused suites, plus the new production-gateway behavioral suite.
- The V1-R07 staff files are all new (untracked) in Git; the modified files listed under `git status` are limited to the intended V1-R07 Flutter surface, the two focused A6.3/user-area test harnesses, and the roadmap. `OpenCode_Usage_Report.txt` remains untracked and untouched.

## Final decision

**CORRECTIONS COMPLETE — READY FOR FOCUSED CODEX RECHECK**

Every finding in the 23-finding correction set was addressed in the Flutter layer, all four focused suites pass, `git diff --check` is clean, and no server/migration/contract file was touched. No server change and no Architect product decision is required to proceed to the focused Codex recheck.

## Review findings addressed

| # | Finding | Correction |
|---|---------|-----------|
| 1 | Privileged data was not cleared on permission loss (P0PER/P0AUT) across all staff surfaces | Queue append (`loadMore`) and detail `load` now route P0PER/P0AUT through the shared permission-loss path: state → `accessDenied`/`signInRequired`, privileged data cleared, `onPermissionLost` fired. `StaffOperationsScope` cascades clearance to every sibling provider. |
| 2 | More than one mutation RPC could be issued for a single user action | `StaffApplicationDetailProvider._runMutation` guards **before** invoking the gateway call: any mutation while `mutating` returns `false` with zero RPCs. Test: pending `beginReview` then `approve()` → only `['beginReview']` reaches the fake. |
| 3 | Capabilities parsing accepted malformed permission entries | `StaffApplicationCapabilities.tryFromJson` fails closed: non-string permission entries, missing/non-list `permissions` → `null` (no invented defaults). Unknown well-formed codes are ignored for capability computation. |
| 4 | Summary/pagination parsing accepted malformed `next_cursor` | `StaffApplicationSummary`/page parsing now distinguishes **explicit `null`** (valid final page, `hasMore == false`) from **malformed cursor maps** (whole page fails). Missing half of a cursor key fails the page. |
| 5 | Detail parsing accepted malformed contacts/visits | `StaffApplicationContact`/`StaffApplicationVisit` failure fails the **whole** detail (no partial snapshot). Contacts/visits absent are relaxed defaults (empty list). |
| 6 | Load-more failure could corrupt or lose the loaded page | `loadMore` failure keeps all loaded items and enters `StaffQueueState.loadMoreError`; `retryLoadMore` re-requests the **same** `next_cursor` (never a different page). Verified via cursor recording `[null, cursor, cursor]`. |
| 7 | Post-mutation refresh failure was not recoverable; no real refresh action | Failed post-mutation reread enters recoverable `refreshAfterMutationError`; `_WarningBanner` refresh action performs a **real** `refreshDetail()` reread (one-shot post-mutation result consumed). Test replaced the former `acknowledgeRefreshWarning` with a real-reread test. |
| 8 | Stale async read results could overwrite newer state | Request-sequence guard on detail reads: results from a superseded request are ignored. Test uses two gated `Completer`s — the stale (first) completion never overwrites the fresh one. |
| 9 | Queue did not refresh after a committed mutation | Post-mutation committed callback (`onMutationCommitted`) triggers `queue.refresh()` through `StaffOperationsScope`; test verifies the queue reloads after `approve()`. |
| 10 | Auth lifecycle changes did not clear privilege state | `StaffAccessProvider` listens to auth changes: sign-out resets + fires `onPermissionLost`; session replacement clears old runtime state and re-resolves capabilities. |
| 11 | User Area staff tile swallowed provider absence silently | `_StaffEntryTile` silent `ProviderNotFoundException` fallback removed; the tile requires the provider and renders staff operations only when authorized/hidden otherwise (dead-end state impossible). |
| 12 | No composition root wiring staff providers safely | `StaffOperationsScope` (`lib/core/di/staff_operations_scope.dart`) wires `access.onPermissionLost → queue.clear()+detail.clear()`, `queue.onPermissionLost → detail.clear()`, `detail.onPermissionLost → queue.clear()`, `detail.onMutationCommitted → queue.refresh()`, and disposes all providers. `main.dart` uses it. |
| 13 | Confirm dialogs used generic labels | Every mutation shows an action-specific confirm message and confirm-label via `_confirm`/`_promptReason` (beginReview, approve, activate, returnForCorrection, reject). Verified in widget test (approve dialog shows `Ar.staffConfirmApprove` + approve confirm label; cancel closes it). |
| 14 | Malformed route ids could reach the gateway | `StaffApplicationId.isValidUuid` guards the review screen: a non-UUID `:applicationId` shows the not-found state **before** any RPC (`detailCalls == 0` verified). |
| 15 | Accumulated localization gaps in staff screens | All review/queue screen strings resolved through `StaffApplicationMessages.localized` (status labels, action labels, contact types, visit statuses, load-more-error banner); keys verified present in both `ar.dart` and `en.dart`. |
| 16 | Server/migration was out of correction scope | Migration `00021`, `v1_r07_staff_operations_server_test.dart` (28/28), and the contract remain **frozen and untouched** — the server contract is the authoritative source for the queue `next_cursor` shape and contact/visit codes used by parsing. |
| 17 | Queue screen offered no recovery from append failure | Queue screen shows a rete-load error banner on `loadMoreError` wired to `retryLoadMore()`; permission loss shows the denied state and clears the view. |
| 18 | A6.3 staff-contract mock drifted from the current gateway interface | `_ScriptedStaffGateway` read stubs updated to `getCapabilities()`, `listApplications({statusFilter, typeFilter, limit, cursor})`, `getApplicationDetail(...)` returning `StaffReadUnavailable` (server tests assert only the write surface). 37/37 still green. |
| 19 | Staff entry required provider access semantics uncertain | Tile rendering now gated strictly on `StaffAccessProvider` authorization (read-capability), matching the access-provider state machine. |
| 20 | Production gateway behavior was untested | New `test/v1_r07_staff_gateway_production_test.dart` (17/17): real `SupabaseClient` + recording HTTP client verifies RPC names/params (`get_staff_application_capabilities`, `list_staff_business_applications` filters/cursor, `get_staff_business_application_detail`, `staff_begin_application_review`, `staff_reject_business_application`), projection parsing, P0AUT/P0PER/P0NOT/P0TRA/P0COR/P0REJ/P0DAT/P0CLM/P0OWN → typed causes, malformed projection → unexpected denial, uninitialized service → `StaffReadUnavailable`. |
| 21 | Schema/projection strict-parsing lacked regression tests | 12 strict-parsing tests added (capabilities, page/cursor, contact/visit detail) — all fail closed on malformed server projections. |
| 22 | Provider state-machine corrections lacked direct tests | Added tests: queue load-more preserve + same-cursor retry + P0PER clearance; detail P0PER clearance, one-mutation-RPC guard, stale-read discard, post-mutation queue refresh; access sign-out/session-replacement lifecycle. |
| 23 | Cross-provider clearance and widget behavior lacked tests | Added `StaffOperationsScope` wiring tests (detail permission loss clears queue; access sign-out clears queue+detail) and review-screen widget tests (invalid-id fail-safe, action-specific confirm dialog, activate-only-for-approved gating). |

## Verification (this pass)

- `flutter test --no-pub test/v1_r07_staff_operations_flutter_test.dart` → **+50: All tests passed** (26 pre-existing plus 24 new correction tests).
- `flutter test --no-pub test/user_area_route_test.dart` → **+29: All tests passed**.
- `flutter test --no-pub test/a6_3_business_application_mutation_test.dart` → **+37: All tests passed**.
- `flutter test --no-pub test/v1_r07_staff_gateway_production_test.dart` → **+17: All tests passed** (new).
- `git diff --check` → clean (no whitespace errors; only LF→CRLF notices).
- `git status --short` → only intended V1-R07 files (see below); `OpenCode_Usage_Report.txt` untracked and untouched; nothing staged or committed.
- One production bug surfaced and fixed by the new scope test: `StaffOperationsScope` wired `detail.clear` (a tear-off on a not-yet-initialized `late final`) — replaced with a lazy closure. Fields are initialized in constructor order and cross-references resolve on invocation.

## Fixed deliverables (this pass)

- `lib/core/di/staff_operations_scope.dart` — cross-provider permission-loss/mutation composition root (`main.dart` uses it).
- `lib/features/business/domain/staff_application_id.dart` — UUID route guard.
- `lib/features/business/presentation/screens/staff_application_review_screen.dart` — full rewrite: fail-safe route guard, localized header/history/actions, action-specific confirm dialogs, real refresh-after-mutation-error.
- `lib/features/business/presentation/providers/*` — access (auth lifecycle), queue (load-more recovery), detail (mutation guard, stale-read guard, post-mutation refresh).
- `lib/features/business/domain/staff_application_capabilities.dart`, `staff_application_summary.dart`, `staff_application_detail.dart` — fail-closed parsing.
- `lib/features/business/presentation/staff_application_messages.dart` + `lib/localization/{ar,en}.dart` — staff message wiring.
- `lib/features/user_area/presentation/user_area_screen.dart` — staff tile requires the provider.
- `test/v1_r07_staff_operations_flutter_test.dart` (50), `test/v1_r07_staff_gateway_production_test.dart` (17) — correction + real-gateway coverage.
- `test/a6_3_business_application_mutation_test.dart`, `test/user_area_route_test.dart` — harness updates only (read-stub interface + tile rendering), still green.

## Not run (pre-existing environment/constraint, unchanged)

- `flutter pub get`, `flutter analyze`, and the full Flutter suite are **not** run per the correction-pass constraints.
- The pre-existing `sky_engine` pub-resolution error print under `dart pub deps` does not affect `--no-pub` test execution and was not repaired.
- No server/migration/contract/roadmap changes were made — server evidence is reused from the accepted Part 1.
- Nothing was committed or pushed; Git state is left as-is for the reviewer/Codex recheck.

CORRECTIONS COMPLETE — READY FOR FOCUSED CODEX RECHECK