# CIVILPEDIA V1-R10.5-D — PROFILE + USER AREA PRESENTATION IMPLEMENTATION CONTRACT

PHASE: V1-R10
SLICE: R10.5-D — Profile + User Area Presentation Pass
CONTRACT: V1-R10.5-D-PRESENTATION-CONTRACT-v1
STATUS: ACCEPTED / FROZEN
ARCHITECT_ACCEPTANCE: ACCEPTED — INDEPENDENT A ACCEPTANCE
IMPLEMENTATION_AUTHORIZED: NO
IMPLEMENTATION_STATE: NOT STARTED
ROADMAP_CHANGE_AUTHORIZED_IN_THIS_PASS: YES — APPEND-ONLY ACCEPTANCE/FREEZE RECORD
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
CUI2A1_IMPLEMENTATION_AUTHORIZED: NO
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
IOS_COMPATIBILITY_QA: REQUIRED BEFORE IOS LAUNCH / PLANNED / UNVERIFIED
COMMIT_PUSH_AUTHORIZED: NO
DRAFT_DATE: 2026-10-12

## Authority, provenance and current write boundary

The Owner explicitly authorizes creation of this draft contract only. No production/test/guard/roadmap edit, freeze, execution, acceptance, staging, commit or push is granted by this document. Normative implementation requirements below are proposed requirements for a later separately frozen and authorized task.

The [Master Roadmap](../CIVILPEDIA_V1_MASTER_ROADMAP.md) remains phase/status SSOT: R10.5-D is CURRENT for focused pre-implementation audit only, implementation NO / NOT STARTED. Its parent [R10 contract](V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md), Appendices G/H, [visual/token freeze](V1-R10_1_VISUAL_DIRECTION_TOKEN_FREEZE.md), [R08 Auth/Profile contract](V1-R08_AUTH_PROFILE_PRODUCTION_COMPLETION_CONTRACT.md), [P2-C profile read contract](V1-R09_P2-C_AUTHENTICATED_PROFILE_READ_UX_CONTRACT.md) and [Operating Model](../CIVILPEDIA_AGENT_OPERATING_MODEL.md) remain unchanged.

This draft carries forward the completed audit and prior contract proposal in the existing Codex chat “Integrate owner decisions” (thread `01a12c2f-a5ec-7713-b6b4-1810d3b83ef8`): audit turn `01a12c94-c89b-7870-9222-ade6bf7f610e`; contract proposal/Architect scope-decision turn `01a12ccb-a793-7ea3-b5a1-029fa24d3088`; commercial compatibility source audit turn `01a12cd7-b368-76b0-baff-c6e59517a05a`. These were read as existing evidence; the audits were not rerun. They are chat evidence, not newly persisted acceptance reports. The Owner's current instruction confirms the five-screen/one-new-test proposal, Projects responsive convention and exact 17-file manifest; it does not freeze them.

Verified drafting entry: branch `main`; HEAD and local `origin/main` = `0ceb646621027e2ab902b13302c452038154ab11`; index empty; three protected modified tests and three protected untracked files as §O. No R10.5-D contract at this path exists to overwrite; the proposed new visual test remains absent. Parent R10 Appendices A–H are read-only; this standalone slice draft replaces none of their authority.

The only current write path is:
`docs/architecture/contracts/V1-R10_5D_PROFILE_USER_AREA_PRESENTATION_IMPLEMENTATION_CONTRACT.md`.

The six paths in §A are a future implementation proposal, not today's write permission. All guard-maintenance stages in §L require their own separate authority.

## Completed evidence and carried-forward findings

The completed audit established existing cloud/local separation, whole-body Profile conflict versus header-only User Area conflict, two-step setup, cloud role/region editing, manual recovery/save retry, and the five ordinary User Area entries with a capability-gated staff entry. Presentation debt includes noncanonical app bars/custom surfaces, fixed action sizes, directional icons and raw backup-error interpolation.

Architect decisions retained: no recovery-state parity redesign; no Google Play destination change; Arabic-only active V1 with dormant English compatibility; no new data, routes, providers, fields or backup operation. §N records broader improvements as separate proposals.

The independently accepted four-guard correction is now committed at `0ceb646621027e2ab902b13302c452038154ab11`, parent `2cbed9f81d9346ac4b16c00e9c20282aaddc97eb`. It recognized the exact Owner planning/gov composition only. Historical focused evidence: CUI-2A0 56, HARDEN1 25, M1B 28, M3 35, M1a 24, R09q 10 = 178 PASS / zero failures; independent review PASS supplied for that exact diff. Those results do not establish GREEN after this additional draft.

Drafting input production blobs at entry HEAD (future execution must reverify actual approved ancestry/content, never invent hashes):

| Proposed existing production path | Entry committed blob |
| --- | --- |
| lib/features/profile/presentation/profile_screen.dart | 1e1906c414da6f2c817caaefa478147af3a2bf9d |
| lib/features/profile/presentation/screens/profile_setup_screen.dart | d5d7e1474729b368358361aa47c4b5cf195745d4 |
| lib/features/profile/presentation/screens/profile_edit_screen.dart | 33622c0d6ad95be1d017060ab917643589a9d81e |
| lib/features/profile/presentation/screens/authenticated_profile_edit_screen.dart | a13e970046a4d9db3885107ab00b9f60daa09307 |
| lib/features/user_area/presentation/user_area_screen.dart | 274b4588c9c4ea7a1125d14fad63db1d4527c337 |

## A. Proposed future implementation scope and exclusions

**Purpose:** align existing Profile and User Area presentation with the accepted R10 visual system while preserving existing behavior.

**Proposed modification boundary: exactly five existing production files and one new test file.**

| Type | Exact path |
|---|---|
| Existing production | [profile_screen.dart](../../../lib/features/profile/presentation/profile_screen.dart) |
| Existing production | [profile_setup_screen.dart](../../../lib/features/profile/presentation/screens/profile_setup_screen.dart) |
| Existing production | [profile_edit_screen.dart](../../../lib/features/profile/presentation/screens/profile_edit_screen.dart) |
| Existing production | [authenticated_profile_edit_screen.dart](../../../lib/features/profile/presentation/screens/authenticated_profile_edit_screen.dart) |
| Existing production | [user_area_screen.dart](../../../lib/features/user_area/presentation/user_area_screen.dart) |
| New test | `test/v1_r10_5d_profile_user_area_visual_test.dart` |

The proposed test path does not currently exist.

**Excluded:** all other files, including existing tests; authentication/providers; profile data/domain/persistence; routes and shell; dependency composition; shared theme/widget implementations; localization resources; backup services; Business/Staff screens; Saved/Downloads; Android/iOS configuration; dependencies; Supabase/migrations; commercial guards; documentation.

No new feature, editable field, navigation destination, recovery workflow, account-deletion interface, backup operation or commercial capability may be introduced.

R10.5-E/F, R10.6/R10.7 and commercial CUI-2A1/M4/M5 remain outside authorization. Current controls are verified in [Roadmap:128](../CIVILPEDIA_V1_MASTER_ROADMAP.md), [R10 contract:2492](V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md), and [Roadmap:4285](../CIVILPEDIA_V1_MASTER_ROADMAP.md).

## B. Per-file modification manifest

| File | Permitted presentation changes | Explicit preservation requirements |
|---|---|---|
| **ProfileScreen** | Replace raw app bar and repeated card decoration with existing canonical components. Use theme foreground/surface roles, token spacing, direction-aware padding/icons, flexible actions and established responsive sizing. Replace raw backup exception interpolation with the existing localized failure text. | Preserve constructor and `profileEditRoute`; cloud/local branches; whole-body conflict replacement; read-only cloud rows; separate edit action; refresh/retry callbacks; theme switch; sign-out; every utility destination; export confirmation, operation, filename, success handling and timing. |
| **ProfileSetupScreen** | Canonical app bar with the existing explicit step-back callback; themed selectable surfaces/actions; scroll/flex adjustments for short screens and scaled text. | Preserve role → region → Home, selectable values and ordering, selection requirements, persistence payload, anonymous identity creation and unknown Baghdad-area compatibility value. |
| **ProfileEditScreen** | Canonical app bar/cards; theme-aware action styling; readable selector values, directional layout, adaptive gutters and content width. | Preserve the guest/local editor, existing pickers, `_hasChanges`, save payload, timestamps, persistence call, snackbar and navigation result. Do not add new pending/dirty-back semantics. |
| **AuthenticatedProfileEditScreen** | Canonical app bars/cards; theme-aware save spinner; directional icons; resilient selector/action layout; scrollable static loading/error/session states. | Preserve cloud-only authority, role/region choices, initialization/resynchronization, pending locking, save pipeline, typed failures, manual retry, successful rebaselining, remaining on-screen after save and existing `PopScope`/discard behavior. |
| **UserAreaScreen** | Canonical app bar/header/list surfaces; flexible loading text and actions; safe-area/shared-bottom-inset handling; directional icons; remove the redundant separator when staff entry is absent. | Preserve five ordinary entries, order and destinations; capability-gated staff entry; existing capability loading lifecycle; ListTile-free header; header-only conflict behavior; cleanup/observation branches and their existing callbacks. |
| **New visual test** | Add deterministic presentation and integration assertions described below, using existing public seams and test-local fixtures. | No production test hooks, real credentials, real Supabase calls, persistent user data or modifications to existing suites. |

Source anchors include [Profile:233](../../../lib/features/profile/presentation/profile_screen.dart), [setup:138](../../../lib/features/profile/presentation/screens/profile_setup_screen.dart), [local editor:294](../../../lib/features/profile/presentation/screens/profile_edit_screen.dart), [authenticated editor:459](../../../lib/features/profile/presentation/screens/authenticated_profile_edit_screen.dart), and [User Area:54](../../../lib/features/user_area/presentation/user_area_screen.dart).

The backup change is narrowly defined: replace the user-facing expression at [Profile:831](../../../lib/features/profile/presentation/profile_screen.dart) with the existing localized `backupExportFailed` text. Existing translations are available at [Ar:625](../../../lib/localization/ar.dart) and [En:644](../../../lib/localization/en.dart). Do not change backup operations or other exception handling.

## C. Security and behavioral invariants

The implementation must preserve:

1. One production Supabase authority and one `AuthProvider`.
2. Authenticated cloud profile SSOT; no authenticated local-profile fallback or fabricated profile.
3. Current-user/session-generation checks, stale-read suppression and account-bound clearance.
4. Existing bootstrap, ownership binding and conflict neutralization.
5. Cloud editing limited to canonical role and region preference. Role remains descriptive and grants no privilege.
6. Existing save validation, single-flight behavior, authoritative reread, uncertainty reconciliation and manual retry.
7. Existing authenticated-editor dirty/pending navigation semantics.
8. Existing route dispatch, protected-route redirects, return allowlist, route extras and navigation outcomes.
9. Profile whole-body conflict and User Area header-only conflict behavior.
10. Existing recovery predicates, callbacks and action availability. **No recovery-state parity redesign.**
11. User Area’s five ordinary entries and independently authorized staff entry.
12. Existing backup operations and Google Play share/rating destinations.

These are supported by [R08 contract:134](V1-R08_AUTH_PROFILE_PRODUCTION_COMPLETION_CONTRACT.md), [contract:167](V1-R08_AUTH_PROFILE_PRODUCTION_COMPLETION_CONTRACT.md), [contract:206](V1-R08_AUTH_PROFILE_PRODUCTION_COMPLETION_CONTRACT.md), [contract:231](V1-R08_AUTH_PROFILE_PRODUCTION_COMPLETION_CONTRACT.md), and [route dispatch:138](../../../lib/routes/app_router.dart).

Visual restructuring must not introduce new reads, writes or retries during rebuilds.

## D. Visual acceptance criteria

- Use existing `CivilAppBar` and `CivilSurfaceCard`; shared implementations remain unchanged.
- Preserve the setup screen’s explicit step-back behavior when adopting `CivilAppBar`.
- Use active `ColorScheme`, `TextTheme`, `AppSpacing` and `DesignTokens`. No new color literals or opacity-based white/black decoration.
- Preserve approved true-black canvas and layered dark surfaces.
- Primary actions and pending indicators use the corresponding theme foreground roles.
- Owned interactive hit areas meet the existing **48×48 logical-pixel** requirement. Measure hit areas; visual button height alone is insufficient evidence.
- Labels and status text remain readable without suppressing text scaling.
- Selection remains recognizable through existing non-color cues.
- Loading, not-found, typed failure and retained known-good data remain distinguishable.
- No redundant staff separator when the staff entry is hidden.
- Backup failure presentation contains localized text without raw exception details.
- Existing labels, tile inventory and callbacks remain unchanged.

See [R10 token rules:149](V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md), [shared components:198](V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md), [touch targets:334](V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md), and [dark amendment:858](V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md).

## E. Responsive and RTL test cases

**Proposed layout rule:** reuse the accepted Projects convention, rather than introduce a new width limit.

After safe-area adjustment, derive horizontal gutters from available width:

- Below 600: `AppSpacing.lg` — 16.
- From 600 through 839: `AppSpacing.xxl` — 24.
- From 840: `AppSpacing.lg * 2` — 32.
- Center the scrollable body with content width capped at **760**, matching existing Projects presentation.
- Keep the app bar full-width.
- Apply `shellSafeBottomPadding` once, without summing duplicate device/shell clearance.

The existing convention is verified at [ProjectListScreen:242](../../../lib/features/projects/presentation/project_list_screen.dart); the inset utility is at [shell_content_insets.dart:67](../../../lib/core/navigation/shell_content_insets.dart). The Owner's current drafting instruction includes this established 760 logical-pixel cap. It remains a draft R10.5-D requirement until Architect acceptance/freeze.

The new test file must cover these cases:

| Case | Required assertion |
|---|---|
| All five screens, Arabic, light/dark, 390×844, scale 1.0 | Canonical chrome, expected content and no layout exceptions. |
| Compact stress, 320×568, scale 2.0 | Critical identity, loading/error and action text remain readable and reachable by scrolling. |
| Short landscape, 844×390 | Setup steps and editor static states remain usable; no trapped footer or inaccessible action. |
| Widths 599/600 and 839/840 | Correct gutter transitions, without discontinuous overflow. |
| Expanded width 1024 | Established content cap and centered body; unchanged single-column semantics. |
| Nonzero horizontal/bottom safe areas | Content and final actions remain clear of injected insets. |
| Root versus injected shell obstruction | Shared bottom clearance applied exactly once. |
| Long Arabic identity/selector values | Wrapping/flex behavior without hiding actionable labels. |
| Guest/cloud/loading/not-found/read failure | Existing state content and callbacks preserved. |
| Known-good cloud data plus refresh failure | Data remains visible with existing typed notice/retry. |
| Conflict states | Profile body blocked; User Area header blocked with five ordinary tiles retained. |
| Staff hidden/authorized | Five ordinary entries remain; staff condition and separators are correct. |
| Clean/dirty/pending authenticated editor | Existing enabling and back behavior retained while layouts remain readable. |
| Backup failure | Exact localized failure presentation; no exception text or real export side effects. |

Use focused representative combinations, rather than a full Cartesian product.

Arabic RTL is the active runtime acceptance path. Retain existing English tests and add representative LTR directional/layout checks in the new suite. Do not enable the language switch or require Owner English runtime QA. See [R10 contract:2499](V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md).

## F. Focused regression test manifest

The following **17 existing files** are required future regression inputs and remain read-only:

1. [a5_6_profile_bootstrap_test.dart](../../../test/a5_6_profile_bootstrap_test.dart)
2. [a5_8_setup_flow_test.dart](../../../test/a5_8_setup_flow_test.dart)
3. [v1_r08_cloud_profile_foundation_test.dart](../../../test/v1_r08_cloud_profile_foundation_test.dart)
4. [v1_r08_profile_edit_screen_widget_test.dart](../../../test/v1_r08_profile_edit_screen_widget_test.dart)
5. [v1_r08_profile_screen_widget_test.dart](../../../test/v1_r08_profile_screen_widget_test.dart)
6. [v1_r08_user_area_widget_test.dart](../../../test/v1_r08_user_area_widget_test.dart)
7. [v1_r08_auth_screen_widget_test.dart](../../../test/v1_r08_auth_screen_widget_test.dart)
8. [user_area_route_test.dart](../../../test/user_area_route_test.dart)
9. [profile_edit_route_test.dart](../../../test/profile_edit_route_test.dart)
10. [v1_r08_router_auth_test.dart](../../../test/v1_r08_router_auth_test.dart)
11. [v1_r08_auth_session_foundation_test.dart](../../../test/v1_r08_auth_session_foundation_test.dart)
12. [v1_r09_p2_c_authenticated_profile_read_foundation_test.dart](../../../test/v1_r09_p2_c_authenticated_profile_read_foundation_test.dart)
13. [v1_r09_p2_c_authenticated_profile_read_ux_test.dart](../../../test/v1_r09_p2_c_authenticated_profile_read_ux_test.dart)
14. [v1_r07_staff_operations_flutter_test.dart](../../../test/v1_r07_staff_operations_flutter_test.dart)
15. [v1_r10_2_theme_foundation_test.dart](../../../test/v1_r10_2_theme_foundation_test.dart)
16. [shell_content_insets_test.dart](../../../test/shell_content_insets_test.dart)
17. [app_shell_test.dart](../../../test/app_shell_test.dart)

The final presentation gate additionally includes the one new test file.

Existing tests already protect whole-body versus header-only conflict behavior, setup flow and staff authorization. See [Profile test:374](../../../test/v1_r08_profile_screen_widget_test.dart), [User Area test:464](../../../test/v1_r08_user_area_widget_test.dart), [setup test:148](../../../test/a5_8_setup_flow_test.dart), and [staff test:568](../../../test/v1_r07_staff_operations_flutter_test.dart).

No full repository suite is authorized by this proposed gate.

## G. Baseline test execution requirements

**No tests are executed or claimed GREEN in this documentation-only drafting pass.** The prior 178/178 commercial result applies to the exact committed guard composition, not to this new draft or future R10.5-D source.

Before future production edits:

1. Verify the actual committed freeze, authorization and compatibility records.
2. Record branch, HEAD, index, complete dirty/untracked inventory and protected SHA-256 hashes.
3. Confirm the five production files match the approved execution baseline and the proposed new test path remains absent.
4. Execute the 17 existing regression files against the **actual working-tree contents**, including the three protected modified tests.
5. Record exact command, revision, toolchain, pass/fail/skip counts and failures. Historical results cannot substitute.
6. Require all selected baseline tests to pass before production changes.
7. Run the separately approved commercial compatibility gate described in section L.
8. Record targeted analyzer baseline for the five production files; final analysis must introduce no new diagnostics. The previously observed internal Dart analyzer Enum crash is a separate tooling issue, not a source diagnostic or successful analysis. Preserve its evidence; do not repair SDKs, dependencies or global caches. If analysis cannot complete, report the limitation for an explicit Architect disposition before execution/acceptance; do not manufacture an analyzer PASS.

Future Flutter tests should use `--no-pub` and run without concurrent Flutter processes. Normal generated test/build caches must be covered by the later execution authorization; tracked files and protected artifacts must remain unchanged.

A missing dependency, toolchain failure or baseline test failure is a STOP. Do not run dependency upgrades, repair global SDK/cache sources, or edit protected tests to obtain GREEN.

## H. Manual Android visual QA

After automated gates pass, Owner visual acceptance should cover:

- Arabic light/dark on a compact Android phone.
- Portrait, landscape and increased system text size.
- Profile guest/local and authenticated/cloud views.
- Loading, not-found, typed failure and retained-data refresh failure.
- Existing ownership-conflict and recovery presentations.
- User Area with staff hidden and authorized.
- Setup role → region flow and within-step back.
- Guest/local editor selection, save and return.
- Authenticated editor clean, dirty, pending, successful save and manual retry.
- Toolbar/system back and discard confirmation.
- Final-content clearance with gesture and button navigation.
- Existing share/rating/support/privacy actions and backup feedback.

Agent verification covers programmatic behavior and measured geometry; Owner QA covers subjective appearance. Evidence must identify the tested revision and device/settings. Existing protected screenshots must not be overwritten.

## I. Deferred iOS native QA requirements

Register this dependency for the later approved launch-readiness process:

**`R10.5-D-IOS-01 — Native Profile/User Area compatibility: REQUIRED BEFORE iOS launch; UNVERIFIED.`**

Separate approved handling must address:

- Platform-appropriate rating/share destination using verified product/store metadata.
- Native sharing and external URL launching.
- iPhone safe areas, home indicator, landscape and larger text.
- Picker focus, dismissal and native back gestures, including dirty/pending editing.
- Sign-in return flow under the existing authority model.
- Backup-export location, feedback and user retrieval.
- Actual plugin/build/configuration compatibility.

Current Google Play destinations are verified at [Profile:43](../../../lib/features/profile/presentation/profile_screen.dart) and [Profile:49](../../../lib/features/profile/presentation/profile_screen.dart). They must remain unchanged within R10.5-D.

R10.5-D presentation acceptance must not be described as iOS-native readiness, store compliance or simultaneous-launch assurance. This dependency does not require new form inputs, billing work or native configuration changes in this slice.

## J. Failure and rollback boundaries

- A failure permits correction only within the five production files and new test, after authorization.
- A failure requiring changes to an excluded file stops implementation and returns to the Architect.
- Preserve the original baseline evidence and identify whether a failure preceded the change.
- Do not alter tests or weaken assertions to accommodate a regression.
- Revert only the implementer’s identifiable slice edits when explicitly authorized; never restore an entire file over concurrent or pre-existing work.
- No automatic reset, clean, stash, checkout, revert, commit amendment or force-push.
- No database rollback exists within this slice because no database operation is permitted.
- Recheck protected hashes and changed paths after test execution and before review.

The implementation task must finish with a reviewable diff and evidence; Git publication requires separate Owner authorization.

## K. Independent review requirements

A reviewer independent of the implementer must verify:

1. Exact six-file implementation footprint.
2. Full diff and every invariant in section C.
3. Component/token use and responsive convention.
4. New tests exercise rendered UI and meaningful interactions.
5. Preserved routes, conflict boundaries, staff authorization and save/retry semantics.
6. Localized backup failure without backup-operation changes.
7. Protected hashes and unrelated entries unchanged.
8. Current focused test/analyzer evidence.
9. Separate commercial compatibility evidence.
10. Android visual acceptance and explicit iOS dependency status.

HIGH or MEDIUM findings block acceptance; LOW observations require explicit disposition. The reviewer must not silently fix code. This follows [Agent Operating Model:5](../CIVILPEDIA_AGENT_OPERATING_MODEL.md) and its review policy.

Final acceptance, closure and next-slice advancement remain Architect decisions.

## L. Proposed staged authorization and commercial compatibility strategy

### L.1 Actual current recognition boundary

The latest CUI-2A0 live recognizer `hasOwnerPlanningDocumentaryBoundary` validates exact pinned documents, branch/ancestry, independent committed/index/unstaged/untracked inventories and protected raw bytes before invoking the unchanged historical predicate. HARDEN1/M1B/M3 consume it and also reconstruct exact documentary/source expectations. M1B preserves a full historical HARDEN1 oracle.

Current observed authorities:

| Object | Exact committed identity |
| --- | --- |
| Owner planning commit | ac64cd6275888fd2768db2a890e98fbfc9819ab1 |
| Planning parent | ed9840084eb67b1bb295459b420093a37d8bccbb |
| Compatibility authorization commit | 2cbed9f81d9346ac4b16c00e9c20282aaddc97eb |
| Planning roadmap blob | e2e239e08f14350b910ab22185c095387e5a2301 |
| Current authorized roadmap blob | dba35363152429ca78933e1669e80758cfaba48c |
| Readiness-document blob | ee696d6a4054fd5476f81f3d7c2c9b6e6e8cd7ab |
| CUI-2A1 frozen contract blob | 8071f951ff336714c420a5216504d0d49183e055 |
| Current CUI-2A0 guard blob | fef6a5cc7fb3866a8ac99fcaf3a11943da443a1b |
| Current HARDEN1 guard blob | 9c2687969ec27f96362264c470db3080281b377b |
| Current M1B guard blob | c28a02599e431b0e7331cb2713ef74e634787027 |
| Current M3 guard blob | 06452fdbeda3d043a3f386d969b91e9e6aa5d7de |

Source-based assessment: this new contract path is outside the current exact repository inventories. Its untracked/staged/committed addition, a later freeze/roadmap record, and the six R10.5-D implementation paths are not recognized by the existing Owner-planning branch. No suites were rerun to manufacture a fresh failure or GREEN. Owner-authorized draft preparation may proceed, but existing GREEN must not be claimed for this new composition and the mismatch must not be bypassed.

The prior roadmap compatibility record explicitly excludes R10.5-D freeze/implementation states and arbitrary future records. Frozen CUI-2A1 §16/§22 gates remain intact. Any new recognition needs a separate bounded Architect/Owner decision and, where it would change a frozen contract/gate, a formal accepted addendum. This draft is not that amendment or authorization.

### L.2 Maintainable finite-stage design — proposal only

Retain historical exact predicates and fixtures as immutable commercial/security oracles. Layer a named R10.5-D state recognizer in the existing CUI-2A0 guard, with one authoritative description per separately approved state. Have the three consumers use the same decision; keep their exact reconstruction requirements consistent. No new helper file or consumer refactor is authorized here.

Define explicit stages rather than repeatedly replacing the historical baseline:

| Candidate stage | Required separate authority/evidence | Permitted recognition |
| --- | --- | --- |
| Documentary DRAFT | Owner-approved exact draft and documentary compatibility authority; observed committed contract blob/ancestry | Only the exact contract addition; implementation remains NO; roadmap otherwise exact |
| ACCEPTED/FROZEN, execution NO | Architect acceptance, exact frozen contract and separately authorized append-only roadmap synchronization | Exact observed document blobs/records; zero R10.5-D source/test implementation |
| Execution authorized, prerequisites pending | Separate Owner instruction and committed exact execution record, pinned frozen contract and six-path boundary | Recognition of documentary authority only; no source edits until committed compatibility GREEN and §G baseline pass |
| Execution active | All prerequisites evidenced; explicit ordinary UI execution authority | Only M changes to the five named existing presentation files and A/change to the one named new test; all other sources/protected bytes invariant |
| Accepted implementation / closure | Independent review, Android acceptance, Architect acceptance, Owner Git closure and exact final source/test blobs | Exact approved implementation identities plus one separately approved closure append; no arbitrary successor state |

Observe real commit/parent/blob identities after the Owner-approved commits exist; never invent future SHAs. Bind branch/ancestry, exact contract/version, literal roadmap authority, prerequisite evidence and state-specific paths/statuses. A pending candidate can be reviewed under separately authorized exact review allowances; it cannot enable live implementation authority. Do not derive expected source from the live file being checked.

Validate committed delta, staged delta, unstaged delta and untracked inventory independently, including deletions/renames/type changes and restoration hiding committed drift. Compare exact identities in both committed objects and live composition. Preserve only explicitly enumerated pre-existing dirt with its raw hashes. Reject documentation prefixes, filename lookalikes, future suffixes, arbitrary HEAD as an expected authority, environment bypasses and missing/mismatched records.

For active UI work, the six-path permission is a bounded presentation delta under a separately approved execution contract, not a new commercial authority. Preserve every unrelated baseline source and the historical SQL/security oracles. Independent full-diff review verifies semantics; after acceptance, pin the actual final UI/test blobs. Subsequent new edits need new authority.

Additions are data describing exact approved transitions and focused tests of the common recognizer; historical predicates/pins remain unchanged. M1B's expected HARDEN1 source must retain a hand-authored exact transformation with unique anchors and adversarial rejection. A generic manifest loader trusting editable live documentation would create circular trust and is not the proposed solution.

### L.3 Security/recognition acceptance gate

A separately authorized compatibility pass must preserve every historical pin and predicate, exact migrations 00001–00026 and runtime-test bytes, frozen commercial policy/prices/entitlements, CUI-1/CUI-2A0 CLOSED, M3 CLOSED shadow isolation, four A0 permissions/six RPCs, CLAIM/receipt/audit ACL and privacy predicates, and all eight §O protected identities. Commercial CURRENT remains NONE; CUI-2A1/M4/M5 implementation remains NO. Ordinary UI authority must never authorize commercial source/SQL/publication/payment/entitlement work.

Positive tests: historical fixtures still pass; each exact approved stage passes its own real recognizer; draft/freeze without execution permission permits zero UI changes; committed execution with prerequisites met permits only the six named paths; the final accepted exact implementation and closure are distinct. All consumers agree.

Adversarial tests must use the same live recognizer and reject wrong commit/parent/ancestry/blob, missing/altered/uncommitted authority, truncated/arbitrary future documents, premature production changes, pending prerequisites, wrong source status/path, added helpers/docs/tests, concealed staged/committed drift, protected-byte mutation, SQL/migration/configuration changes, commercial activation and historical fallback accepting invalid live states. Each source mutation must actually change its historical fixture and exercise the real matcher.

Required six-suite compatibility gate, sequentially:

```text
flutter test --no-pub test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
flutter test --no-pub test/commercial_harden1_public_plans_exposure_migration_test.dart
flutter test --no-pub test/commercial_m1b_catalog_reference_data_migration_test.dart
flutter test --no-pub test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart
flutter test --no-pub test/commercial_m1a_private_catalog_migration_test.dart
flutter test --no-pub test/v1_r09q_security_matrix_test.dart
```

All executed, zero failures, no weakened/skipped assertions; unchanged M1a/R09q. Independent Big Pickle review remains mandatory for guard compatibility, with exact diff/source oracle/inventories and six-suite execution. If unavailable, explicit Owner decision naming a replacement is required; no silent substitution under ordinary UI review defaults. CRITICAL/HIGH/MEDIUM findings block acceptance. This is a future gate, not today's test authorization.

### L.4 Sequence of separate approvals

1. Architect reviews this DRAFT and resolves §N; Owner separately authorizes any documentary corrections. No roadmap change in the current task.
2. Owner approves the exact documentary persistence/compatibility sequence; separately authorize the bounded guard work and commit of reviewed documentation. Preserve an implementation-NO stage while actual document identities are observed. Any intermediate unrecognized composition must be reported, not labeled GREEN.
3. Architect separately accepts/freezes the contract; Owner separately authorizes exact roadmap synchronization and documentary Git closure. A frozen contract alone grants no implementation permission.
4. Owner separately approves the exact ordinary UI execution record and later execution instruction, conditioned on committed compatibility GREEN and §G baseline. Define the finite stage transitions and any formal guard-contract addenda before guard edits.
5. Separately execute/review/Owner-commit the exact four-guard transition work against actual committed documentary identities, preserving historical security and Big Pickle review. Do not use this draft or the old planning authorization as permission.
6. Verify live committed preimplementation compatibility GREEN with zero R10.5-D production changes, the 17-file baseline and analysis disposition. Then and only then execute the five-screen/one-test UI slice.
7. Run the new visual suite plus all 17 unchanged regression files and the separately approved six-suite commercial preservation gate; record exact revision/commands/counts/exits. Complete Android QA and independent ordinary UI review.
8. Architect accepts; Owner separately authorizes exact implementation Git closure and any closure-document recognition. Keep mandatory future iPhone compatibility QA open until actual evidence exists.

The design reduces duplicated decision logic and avoids rediscovering the same mismatch at every stage. It still requires exact new documentary identities and separate Owner decisions; no safe design can treat all future roadmap text as automatically trusted.

## M. Exact STOP conditions

For the later implementation task, stop before editing or stop further work immediately if:

- Actual governing records identify another current slice.
- A committed freeze or explicit execution authorization is absent.
- Compatibility prerequisites are absent or failing.
- Branch, HEAD or index differs from the approved execution baseline without an approved explanation.
- Any protected hash changes or an unrelated entry disappears/changes.
- An unexpected modified, staged or untracked file appears outside the agreed execution allowance.
- A baseline regression fails or required tests cannot execute.
- A solution requires changing excluded files, dependencies or shared components.
- Auth/session, ownership, persistence, route, recovery or save/retry behavior changes.
- Cloud fields, region choices, tile inventory or staff authority change.
- Google Play destinations or native configuration change.
- Raw backup errors cannot be removed within the specified presentation boundary.
- New tests require production injection hooks or real service/user-data side effects.
- Responsive/accessibility compliance requires expansion into R10.6.
- Review identifies an unresolved HIGH/MEDIUM finding.
- Git staging/publication, deployment or database work is requested without separate authorization.

Report the precise evidence and required decision. Do not attempt an automatic mutation retry or unrelated repair.

## N. Architect decisions still required and better-solution proposals

Before freeze: accept the exact per-file requirements, responsive/text-scale matrix and 17-file manifest; assign the ordinary UI implementer and independent reviewer under the Operating Model (Big Pickle routine UI implementer; Copilot/Architect ordinary review by default). The Owner's explicit assignment to Codex covers this drafting task only. Guard compatibility retains its distinct Big Pickle independent-review requirement.

Approve/amend the finite-stage compatibility design in §L, its exact future write boundary, documentary commit sequence and any formally required frozen-gate addendum. Decide the targeted analyzer tooling disposition if the internal Enum crash persists. Assign ownership and later separately approved execution for `R10.5-D-IOS-01`; do not invent an App Store identity.

The Owner's quality/maintainability/UX/performance/security principle permits evidence-based proposals and formal amendment/replacement of a frozen decision. It grants no implicit boundary expansion.

| Separate improvement | Existing evidence / benefit | Tradeoffs, migration risk and required approval |
| --- | --- | --- |
| Common exact commercial transition description (§L) | Current matcher is centralized, but HARDEN1/M1B/M3 repeat composition/reconstruction logic and exact global inventories reject routine authorized UI/document additions. One bounded state description reduces drift and repeated repair. | Must retain independent security checks and M1B source oracle; circular live-manifest trust or broad exceptions would weaken governance. Separate source audit/Architect acceptance/Owner guard authority and any frozen addendum before implementation. |
| Recovery-presentation parity | Completed audit found Profile whole-body conflict and fewer explicit cleanup/observation branches than User Area. Consistent recovery presentation may improve comprehension. | Existing tests deliberately preserve the difference; changing callbacks/action availability could expose private data or alter auth recovery. Separate Auth-aware scope/contract amendment, C2/C3 and screen-level evidence, independent security review. Preserve current behavior in R10.5-D. |
| Platform-appropriate native action feedback/destinations | Share/rating currently use Google Play; URL-launch feedback and backup retrieval are native-device dependencies. Platform-specific validated destinations can improve iPhone UX. | Requires actual product/store metadata, plugin/device proof and potentially native/data-boundary files outside this slice. Separate Owner product decision and authorized task; keep existing destinations/backup operations now. |

No broader redesign, global responsive framework, speculative performance refactor or new screen is justified in this draft. Component reuse and local layout provide the scoped improvement without migration of authority/data. If implementation identifies a superior alternative, report measured evidence, UX/security/performance impact, tradeoffs, migration risks and the exact required amendment before adopting it.

## O. Protected entry bytes and documentary validation

Preserve these exact raw `git hash-object --no-filters` identities. The first three tests are pre-existing modified files; the following three files are pre-existing untracked; M1a/R09q are read/run-only preservation suites.

| Protected path | Entry raw-byte identity |
| --- | --- |
| test/a5_6_profile_bootstrap_test.dart | 3bf84c06d8de648c793b93168832dd3f4557f6c4 |
| test/v1_r08_cloud_profile_foundation_test.dart | ed2fdfeace5d815d6c6a36df01bcf828c69e2e20 |
| test/v1_r08_profile_edit_screen_widget_test.dart | 8044513a653f601c37c6c91d55638254b82554cc |
| OpenCode_Usage_Report.txt | e0c432a4b8bd72e94d3db203b59ba260597dd601 |
| artifacts/r10_4a/home_dark.png | 45e4ba795bbcffbf283b282e48ff0d436ecb6e20 |
| artifacts/r10_4a/home_light.png | c35bb2314dd916f64cba5794d729aa12bd7a8247 |
| test/commercial_m1a_private_catalog_migration_test.dart | 2f73cf52711fb78969741470724f2aa2567995a5 |
| test/v1_r09q_security_matrix_test.dart | 8dcd0a3089833354fa49174b5db2a3d8c26318b9 |

The previously asserted repository-wide aggregate hash is withdrawn: it was not independently reproduced and must not be used as preservation evidence. No replacement aggregate hash is asserted or required. Normalized document comparison is not raw-byte preservation.

Reproducible baseline for this targeted correction: branch `main`, HEAD `0ceb646621027e2ab902b13302c452038154ab11`, empty index, and 1,207 tracked paths whose exact inventory matches that commit. Excluding this untracked draft, the nonignored entry inventory consists of those tracked paths plus exactly `OpenCode_Usage_Report.txt`, `artifacts/r10_4a/home_dark.png` and `artifacts/r10_4a/home_light.png`. The only pre-existing tracked changes are the three modified tests identified in the table above. All eight individual raw-byte hashes above were verified at correction entry.

Run the following read-only PowerShell commands from `D:\Civilpedia`. Capture their complete output at entry and after the authorized edit; compare branch, HEAD, exact tracked/untracked inventories, changed-path/status lists and each protected-file hash. Counts alone are insufficient. For this §O correction, all these outputs must remain identical; only the already-untracked draft's content may change.

```powershell
git branch --show-current
git rev-parse HEAD

$tracked = @(git -c core.quotePath=false ls-files --cached)
$committed = @(git -c core.quotePath=false ls-tree -r --name-only 0ceb646621027e2ab902b13302c452038154ab11)
$tracked.Count
Compare-Object $committed $tracked

git -c core.quotePath=false ls-files --others --exclude-standard
git --no-optional-locks status --short --untracked-files=all
git diff --name-status HEAD
git diff --name-status
git diff --cached --name-status

$protected = @(
  'test/a5_6_profile_bootstrap_test.dart'
  'test/v1_r08_cloud_profile_foundation_test.dart'
  'test/v1_r08_profile_edit_screen_widget_test.dart'
  'OpenCode_Usage_Report.txt'
  'artifacts/r10_4a/home_dark.png'
  'artifacts/r10_4a/home_light.png'
  'test/commercial_m1a_private_catalog_migration_test.dart'
  'test/v1_r09q_security_matrix_test.dart'
)
foreach ($path in $protected) {
  $hash = git hash-object --no-filters -- $path
  if ($LASTEXITCODE -ne 0) { throw "Protected hash failed: $path" }
  "$path`t$hash"
}
git diff --check
```

Required results: `main`; the exact baseline HEAD; tracked count 1,207 and no `Compare-Object` differences; exactly the three protected untracked paths plus this draft; exactly the three protected modified tests in both HEAD and unstaged changed-path outputs; no staged changes; eight hashes matching the table individually; and `git diff --check` exit 0. Preserve the entry Git status shown below exactly:

```text
 M test/a5_6_profile_bootstrap_test.dart
 M test/v1_r08_cloud_profile_foundation_test.dart
 M test/v1_r08_profile_edit_screen_widget_test.dart
?? OpenCode_Usage_Report.txt
?? artifacts/r10_4a/home_dark.png
?? artifacts/r10_4a/home_light.png
?? docs/architecture/contracts/V1-R10_5D_PROFILE_USER_AREA_PRESENTATION_IMPLEMENTATION_CONTRACT.md
```

Git path/status comparisons establish repository composition; the eight raw hashes establish byte preservation for the explicitly protected files. They do not constitute an independently reproduced raw-byte proof for every repository file. Verify the draft's bytes before §O and from §P onward remain identical to correction entry. Because this draft is untracked, `git diff --check` alone does not inspect its content; check it separately for trailing whitespace and document consistency.

Document validation must verify DRAFT / NOT FROZEN, implementation NO, exact five existing presentation paths and absent new test, the exact 17 distinct existing regression files, resolvable local references, unchanged protected content and empty index, plus `git diff --check` and whitespace checks on this untracked document. Report its untracked status. Do not run Flutter/analyzer/device/build/SQL gates during this documentation-only pass.

Future regression commands are `flutter test --no-pub <exact manifest path>`, one process at a time. Before UI edits run all 17; after UI edits run the new visual suite and all 17, plus §L's separately authorized six-suite preservation gate. Require zero failures and no skipped required cases; record per-file results against actual source/working-tree identity. No full repository suite is authorized.

QA screenshots/evidence must use a separately approved output location or an external review location. Existing protected screenshots cannot be overwritten, and the six-file future implementation boundary does not silently permit extra repository artifact paths.

## P. Closure evidence required for the later slice

Before Architect acceptance, provide the exact frozen contract/execution/compatibility identities and ancestry, reviewed six-file diff, preserved sources/raw hashes/inventories, new visual and 17-file regression results, six-suite commercial evidence, analyzer diagnostics or explicit tooling disposition, independent review/finding dispositions and Android Owner visual acceptance. Record actual device/settings/revision and explicit status of mandatory future iPhone dependency. Historical totals and platform declarations cannot substitute.

No acceptance, Git closure, next-slice advancement, deployment or iOS readiness is asserted by this draft. The Master Roadmap remains unchanged. Production implementation, commercial implementation and commit/push remain unauthorized.

**R10.5-D CONTRACT DRAFT READY FOR ARCHITECT ACCEPTANCE. IMPLEMENTATION NOT AUTHORIZED.**

## Q. Architect acceptance / contract freeze — 2026-10-12

CONTRACT_STATUS: ACCEPTED / FROZEN
ARCHITECT_ACCEPTANCE: ACCEPTED — FOLLOWING INDEPENDENT A ACCEPTANCE
IMPLEMENTATION_AUTHORIZED: NO
IMPLEMENTATION_STATE: NOT STARTED
R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO
OWNER_GIT_REVIEW: PENDING
COMMIT_PUSH_AUTHORIZED: NO

Authority: the Owner-provided **CIVILPEDIA — R10.5-D CONTRACT FREEZE** instruction conveys the Architect's acceptance following independent A acceptance, explicitly accepts the §O correction, and authorizes only this contract freeze and one append-only Master Roadmap acceptance record. The acceptance outcome is supplied by that instruction; no reviewer identity, review artifact, new audit or fresh test result is invented.

Accepted input: the corrected contract at entry branch `main`, HEAD `0ceb646621027e2ab902b13302c452038154ab11`; individual contract raw SHA-256 `DEB8340F1650B8AC54C6733D08EA0D242E253D2E789290D6B4690FDC1B5C389C`. That identity refers to the reviewed corrected draft before this metadata/acceptance append. The contract is still untracked pending Owner Git review; no committed freeze identity is claimed.

The exact five-screen/one-new-test boundary in §§A/B, all existing security/behavioral invariants in §C, responsive/theme/RTL requirements and visual matrix in §§D/E, exact 17-file manifest in §F, validation/QA/review/STOP requirements in §§G–M, the §N improvement boundaries, accepted §O correction and §P implementation closure requirements are preserved. No accepted requirement, implementation path, test, security invariant or §O byte is rewritten by this freeze.

This latest acceptance record supersedes earlier DRAFT / NOT FROZEN, acceptance-pending and proposed-scope wording only as to contract acceptance/freeze. The drafting-only write boundary and no-roadmap-change descriptions record the prior drafting task; the live freeze task permits exactly this existing contract and an append-only acceptance record in the Master Roadmap. §O's DRAFT-status validation describes its preserved drafting/correction stage; live freeze validation requires ACCEPTED / FROZEN and implementation NO. §P's evidence requirements govern later implementation acceptance, not this documentary contract acceptance.

The scope/test-matrix freeze decisions formerly listed in §N are satisfied by the supplied Architect acceptance. Future execution-agent assignment, analysis-tooling disposition if needed, exact guard-stage authorization/identities and mandatory iPhone dependency handling remain separate prerequisites. §L's maintainable compatibility strategy is retained as design/planning; acceptance of this contract grants no guard write permission or recognition of pending/uncommitted states.

The Master Roadmap's appended **V1-R10.5-D CONTRACT ACCEPTANCE / FREEZE — 2026-10-12** record supplies the current freeze fact while preserving all preceding roadmap bytes. Earlier NOT FROZEN descriptions remain historical; R10.5-D remains CURRENT for audit only, implementation NO / NOT STARTED. R10.5-E/F, R10.6 and R10.7 remain LOCKED. Commercial CURRENT remains NONE, commercial implementation NO; CUI-2A1/M4/M5 implementation remains unauthorized and commercial closures/security authorities unchanged.

Before any production execution, separately authorize and complete exact documentary guard compatibility against actual Owner-committed contract/roadmap identities, required six-suite GREEN and independent Big Pickle review, then meet the separately committed execution instruction and §G baseline gate. The historical Owner-planning correction at `0ceb646621027e2ab902b13302c452038154ab11` does not recognize this freeze or authorize subsequent implementation.

No Flutter/test/guard/SQL/Supabase/dependency change, roadmap execution grant, deployment, staging, commit or push is authorized by this acceptance. Frozen requirements may change only through a separate approved amendment.

**R10.5-D CONTRACT FROZEN — IMPLEMENTATION NOT AUTHORIZED — OWNER GIT REVIEW PENDING**
