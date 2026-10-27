# CIVILPEDIA R10-SHELL-A11Y-01 — BOUNDED REMEDIATION CONTRACT

CONTRACT_ID: R10-SHELL-A11Y-01-v1
STATUS: REVIEW CANDIDATE — NOT FROZEN / NOT INDEPENDENTLY ACCEPTED
GOVERNANCE_CANDIDATE_AUTHORIZED: YES — EXACT SIX-PATH FOUNDATION ONLY
IMPLEMENTATION_AUTHORIZED: NO
SHELL_EXECUTION_RELEASED: NO
STAGE_COMMIT_PUSH_AUTHORIZED: NO
R10.5-D: NOT CLOSED
R10.5-E: LOCKED
R10.6: LOCKED
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
ANALYZER_STATUS: NOT PASS
DATE: 2026-10-25

## A. Authority and finding

The Owner-forwarded “R10-SHELL-A11Y-01 GOVERNANCE FOUNDATION” instruction
authorizes one governance/compatibility candidate and its focused validation.
The Architect accepts the prior proposal as the preferred direction, not an
already frozen contract. This document grants no production execution, Git
publication, final acceptance, new phase activation or backend authority.

The Architect confirmed a MEDIUM shared bottom-navigation visual/accessibility
defect in the accepted bounded Android QA evidence, 04-settings-settled.png:
actual system font scale 2.0 with three-button navigation crowds the labels.
The custom shell fixes bar height at 70 logical pixels, divides its width among
five destinations, and renders scaled labels with one-line/no-wrap/fade limits.
The existing single SafeArea and max-based clearance are not the diagnosed cause.

A separate code finding is that the replacement Semantics node excludes its
child semantics but supplies no semantic tap action. Reliable accessible
activation needs correction and coverage in the later implementation.

Guest/local Profile, User Area and local Profile Editor remain accepted for the
supplied screenshots only. This shared-shell remediation does not redesign them,
expand frozen R10.5-D, reopen R10.3 or activate R10.5-E/R10.6. No conclusion about
untested runtime states follows from screenshot acceptance.

## B. Verified entry and immutable inputs

Branch main; HEAD and local origin/main:
213073496d0f7b2e3d9caf8046d3684944db5fec
Parent: 6c7ddb307f6729181ed86ae9fe6cc4b1561bc167
Index empty. Original inventory: five modified R10.5-D production screens,
three modified protected regression tests and four original untracked files.

Committed roadmap raw blob: 85f200c2190034e571d8712a4dbe027a397be286.
Frozen R10.5-D contract raw blob: 0c8f38c87248d31a5aef23a4cfe9f20a546b1329.
Preserve its eight literal section O raw identities and the six UI checkpoint
raw identities in the roadmap's October 18 record. Preserve the existing
R10.5-D visual test as untracked, with its exact checkpoint bytes.

Production shell entry blob: 18b5e55678060e24105844b6128e321d028a8561.
Clearance helper entry blob: fb5177ff1bcd93a2a720f33958d5e47df2e1afa8.
Existing app_shell_test.dart entry blob: ee94ce7506d139c84a1540ef1ebada1213bc5c10.
All remain read-only during this foundation. The dedicated implementation test
must remain absent.

## C. Disjoint exact manifests

Current governance candidate only:

```text
A docs/architecture/contracts/V1-R10_SHELL_A11Y_01_BOUNDED_REMEDIATION_CONTRACT.md
M docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md
M test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
M test/commercial_harden1_public_plans_exposure_migration_test.dart
M test/commercial_m1b_catalog_reference_data_migration_test.dart
M test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart
```

Future implementation proposal, not current permission:

```text
M lib/core/navigation/app_shell.dart
A test/shared_bottom_navigation_accessibility_test.dart
```

lib/core/navigation/shell_content_insets.dart is inspection-only. Existing
shell/navigation tests, five R10.5-D screens, its visual test, all protected
files, routes, theme/localization, dependencies, native configuration, Auth,
Supabase, SQL and business sources cannot change. Any unavoidable additional
path requires an explicit accepted scope amendment before editing.

## D. Proposed bounded geometry — measurable review criteria

All dimensions below are logical pixels. Use actual local constraints after
horizontal safe areas, the existing 16/24/32 gutters and 760 maximum width.
Let W be the resulting bar viewport width. Let V be the shell viewport height
after the top system safe area. Let B = max(device bottom inset, 16).
Let R = max(96, 0.40 * V) reserve vertical space above navigation for the
existing banner and branch viewport. Let Hmax = min(128, V - B - R).
These proposed budgets require independent review and actual short-landscape
validation before freeze; they are not a claim of universal geometry support.

Measure with the actual inherited TextScaler, locale, direction, font metrics,
11-pixel base label, line height 1.3 and both weights 500/600. Rendering and
measurement must use identical inputs; selection must not unexpectedly resize
the bar. Do not substitute a nominal Android scale for its effective scaler.

Ordinary layout is permitted exactly when W / 5 >= 48, every measured label
fits its cell horizontally with 4 pixels padding on each side, and the wrapped
height Hrow = max(70, 32 + 3 + tallest label height + 20) is <= Hmax.
Allow centered natural wrapping with no arbitrary line count, fade, ellipsis,
shortened canonical label or scaled-down text. Detect horizontal glyph overflow;
width-constrained paragraph size alone is insufficient proof of full visibility.

Otherwise use horizontal-scroll fallback in the same floating surface. Use
uniform cell width max(48, 40, widest full unwrapped scaled label + 8).
Its height Hscroll = max(70, 32 + 3 + tallest unwrapped label height + 20)
must be <= Hmax and W must be >= 48. All five destinations remain present;
retain RTL ordering/initial alignment, expose scrolling to accessibility, and
bring selected or accessibility-focused items fully into view. Fallback must
activate only for the failed measurable ordinary-layout conditions above.

If neither mode fits, STOP/report W, V, B, R, Hmax, both measured heights,
effective scaling and font inputs. Do not shrink targets/text, hide destinations,
cap global scaling, clip content or claim support. No rail/drawer/grid redesign.
The viewport budgets and fallback's usability are unresolved acceptance risks
until the specified review and device evidence exist.

Retain the normal-scale 70-pixel appearance wherever its full labels fit; retain
surface colors, radii, border/shadow, 24-pixel icons, 40x32 icon treatment,
3-pixel icon-label gap and selected non-color cues. Enlarged layout must not
consume the reserved branch viewport. Final branch content remains reachable
by scrolling; never force an inaccessible fixed footer.

## E. Insets, activation and behavior

Compute one geometry result, consumed by both bar rendering and ShellContentInsets:
published obstruction = resolved H + max(device bottom inset, 16).
Retain exactly one existing SafeArea and unchanged max-based
shellSafeBottomPadding. Do not sum a second system inset or publish stale 70-pixel
obstruction after growth. Width/height/orientation/scaler changes must update
both uses without a post-frame resize loop or stale-clearance frame.

All five actual hit regions must measure at least 48x48. Provide one semantic
node per destination with the complete canonical label, button role, selected
state and tap action. Use one shared activation function for pointer/semantic
entry points; one activation causes at most one navigation callback/haptic.
Preserve current selected-tab inertness, goBranch mapping, IndexedStack branch
state, root-route behavior and double-back handling. Introduce no new routes,
restoration feature, data access, mutation retry or global font-scale cap.

## F. Validation and evidence

Foundation: first run targeted shell-governance recognition cases, then CUI-2A0,
HARDEN1, M1B, M3, unchanged M1a and unchanged R09q sequentially with
flutter test --no-pub. Record actual commands, exits and pass/fail/skip counts;
require zero failures/skipped mandatory tests. Stop on a new native Flutter/Dart
crash. No SDK/cache/registry/toolchain repair or repository-wide suite.

Later implementation: before edits run unchanged app_shell_test.dart,
shell_content_insets_test.dart, w6_3_nav_transition_test.dart and
w5_5_search_bottom_clearance_test.dart. Afterwards run those four plus the new
dedicated suite sequentially, and the separately authorized six-suite security
preservation gate. No existing suite may be edited to accommodate the change.

New suite must mount the real AppShell and cover Arabic RTL light/dark,
effective scales 1.0/2.0, 320/390 portrait, 844x390 short landscape,
599/600 and 839/840 transitions, expanded width, horizontal/bottom insets and
both sides of each geometry/fallback threshold. Assert complete glyph visibility,
nonoverlap, both hit-target dimensions, exact obstruction, final production Home
content clearance using fixtures, selected/focused fallback visibility, semantic
actions, one callback, branch state, selected-tab inertness and existing back.
Test deterministic unsupported-viewport reporting. Retain representative dormant
English LTR compatibility; active V1 remains Arabic-only.

After separately authorized build/device execution, require actual Android
system font scale 2.0 plus three-button navigation, portrait/landscape,
light/dark, all five destinations, final Home content and TalkBack activation.
Compare normal scale and gesture navigation. Record actual revision, device/API,
system settings, effective TextScaler/insets and screenshots externally at an
approved location. Widget scalers are not actual Android evidence.

Analyzer remains NOT PASS. Historical alternative evidence is candidate-specific
to R10.5-D and does not cover new shell source. Before release obtain successful
targeted analysis or a new explicit Architect tooling disposition with evidence
and residual limits. Android/widget evidence does not certify native iOS.

## G. Finite foundation recognition and later releases

Keep original R10.5-D allowed paths, historical classifiers/fixtures, security
negatives and SQL/source oracles unchanged. Add a distinct shell-governance
layer. Validate actual complete inventories before any explicit predecessor
projection; never discard unexplained changes or untracked paths.

This foundation recognizes only (1) the exact pending six-path governance
candidate at entry HEAD, empty index, exact original checkpoint dirt; and
(2) its exact single-parent direct-child governance commit, empty index and
unchanged original checkpoint dirt. Both retain REVIEW CANDIDATE status and
productionExecutionAuthorized false. Recognition proves composition only.

Bind exact contract and roadmap raw identities/preserved prefix; exact normalized
complete guard sources; all eight protected and six UI raw identities; original
untracked inventory; branch/ancestry; modes and statuses in every Git layer.
Reject any seventh path, unexpected staging, merge, altered authority, concealed
change/restore history or unrelated descendant. Preserve M1B's independently
authored unique-anchor HARDEN1 oracle. No live-derived expected source, broad
path/ancestry exceptions, environment switches or historical fallback.

The new CUI source fingerprint covers its whole LF-normalized UTF-8 source with
one uniquely anchored fingerprint declaration replaced by forty zeroes. The
declaration must equal the compiled fixed fingerprint. Other guards use complete
fixed normalized blob identities. Preserve every older fingerprint/oracle on its
fixed historical inputs. Observe actual complete committed blobs after Owner Git
closure; never invent future hashes or confuse normalized with protected raw pins.

Future freeze/release, shell/test candidate, publication staging, exact shell
commit and closure are LOCKED / NOT RECOGNIZED by this foundation. After the
governance commit exists, separately authorize their finite compatibility design
against observed identities and any genuine frozen-gate amendment. No shell work
before accepted contract freeze, committed compatibility GREEN, baseline/tooling
disposition and separate Owner release naming those inputs. No current declaration
claims a human release instruction can be proved by Git.

Independent Big Pickle High review is required for governance and later shell
work; reviewer substitution requires explicit Owner naming/scoping. Owner Android
visual/TalkBack acceptance and final Architect acceptance remain separate. Local
commit and push each require separate Owner authority and exact staged review.
Keep original dirt unstaged. Do not automatically close R10.5-D or unlock successors.

Preserve raw roadmap bytes through any later Owner staging as well as on disk.
Current automatic line-ending filtering produces a different blob. During an
expressly authorized publication only, use per-command core.autocrlf=false for
the exact staging paths and verify each indexed blob equals its accepted raw
identity. Do not change global/repository configuration or stage anything now.

## H. Carried-forward Owner decisions and residual limits

The current Owner-forwarded foundation instruction explicitly directs persistence
of approved F1/F2 LOW protected-test-hygiene deferral and limited Android fixture
adjudication. This is the provenance for the new record, not an invented earlier
approval date or fresh QA result. No protected test bytes change.

The fixture adjudication accepts supplied presentation/behavior evidence only.
Actual Google Sign-In, authenticated runtime/backend integration, native utilities
and successful export remain UNVERIFIED. It is no authentication/backend/native
readiness approval, no automatic acceptance of untested states and no waiver of
the MEDIUM shell finding. Final Owner acceptance, R10.5-D closure, production
readiness and R10.5-D-IOS-01 remain unestablished/open as previously governed.

STOP for drift, missing authority, failed mandatory gate, native crash, required
out-of-manifest change, weakened oracle, unsupported geometry or unresolved
MEDIUM/HIGH finding. Preserve evidence and report the precise required decision.
