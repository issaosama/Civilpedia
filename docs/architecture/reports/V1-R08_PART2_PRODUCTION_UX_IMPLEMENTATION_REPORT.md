# V1-R08 Part 2 — Production UX Implementation Report

**Phase:** V1-R08 Part 2 (Big Pickle / Kimi) — contract §25 "Part 2 — Big Pickle / Kimi".

**Status:** IMPLEMENTATION REPORT — NOT A CLOSURE RECORD. V1-R08 remains OPEN
pending the independent UX/router review called for by the Part-2 final
decision. Roadmap phase status is NOT modified by this report.

**Status update (V1-R08 closure pass, historical findings unchanged):**
independent UX/router review ultimately ACCEPTED Part 2 —
`PASS — V1-R08 PART 2 ACCEPTED` (final correction evidence 111/111 PASS;
final integrated repository suite 2223/2223 PASS). See the V1-R08 Phase Gate
and Closure reports.

**Scope (as contracted, §25 Part 2):** complete production UX on the accepted
Part 1 foundation — Auth screen states and retry, profile display/edit, User
Area, dirty and unsaved guards, localized errors, return-navigation UX, loading
and retry states, and focused widget/routing tests.

---

## 1. Objective

Deliver the V1-R08 Part 2 production UX layer on the already-accepted,
uncommitted Part 1 architecture, prove it with focused widget/routing suites
(no full-suite run per environment rule), and move the phase gate to
independent UX/router review.

## 2. Part 1 Foundation Reused (not re-architected)

- `AuthProvider` lifecycle (session epoch, restore, sign-in pipeline,
  `postAuthState`, ownership blocking, `isSigningOut`) — untouched.
- `UserProfileProvider` cloud SSOT (strict parse, settled-load semantics,
  `ensureCloudProfileLoaded`, typed save results) — untouched; only the
  `isCloudProfileLoading` + `_cloudLoadSettled` seam was already present from
  Part 1 and is consumed read-only by Part 2 surfaces.
- Router gate (`appRouter` redirect, `AuthRefreshListenable`,
  `AuthReturnDestination.resolve`) — untouched; Part 2 adds the authenticated
  editor dispatch inside the existing `_buildProfileEdit` split.
- Migration 00022 and the database contract — untouched.
- `fake_auth_gateway.dart` events/emit surface — reused as-is by the new
  widget suites.

## 3. Auth Screen Production UX (`auth_screen.dart`)

- Restored-session re-entry stays on the signed-in card (no guest flash).
- Sign-in runs with a disabled/spinner primary affordance (never a second
  submit while authenticating).
- Post-auth pipeline surfaced as one of: running seam
  (`authPostSetupRunning`), retryable seam (`authPostSetupRetryable` +
  Retry), provisioning seam (`authPostSetupProvisioning` + go-to-profile),
  or the signed-in card (`signedInAs`).
- Navigation to the allowlisted return/profile destination happens ONLY after
  the post-auth pipeline settles; a direct parked `retryPostAuth()` never
  auto-navigates (screen-level Retry is the only navigation path).
- Ownership-conflict blocks sign-in entirely (fail closed); an unavailable
  gateway renders the notice and no button.
- Typed error mapping (`AuthError`) → localized rows.

## 4. Profile Screen Production UX (`profile_screen.dart`)

- Ownership-blocked sessions get a fail-closed body (no profile affordances).
- Identity header: guest identity + Login, or authenticated name/email with a
  confirm-gated sign-out (Cancel keeps the session; pending spinner; typed
  `signOutFailed` snackbar with Retry).
- Cloud card (read-only role + region, `not set` for an unresolved region)
  with an explicit Edit button that pushes `/user/profile/edit` WITHOUT a
  local extra (SSOT).
- State ladder: cloud bound → cloud load failed (`profileCloudLoadFailed` +
  Retry, local is NEVER a fallback) → in-flight loading row (never "not set")
  → settled-empty (`profileNotSet`, fail closed) → W3.4 auth-agnostic local
  card (last-resort compatibility branch).

## 5. Authenticated Cloud Profile Editor (`authenticated_profile_edit_screen.dart`)

New production editor behind `/user/profile/edit` (and auto-selected for
signed-in hits on `/profile/edit`):

- Session gate: lost session renders `authSessionLost`; in-flight load renders
  `profileCloudLoading`; failed load renders `profileCloudLoadFailed` + Retry;
  settled-empty renders `profileNotAvailable` fail-closed (no form).
- Form preselects canonical defaults (empty role → `general_user`; region
  "Not set" only as initial value), role/region pickers offer ONLY the
  canonical codes (11 roles, 6 zones).
- Save disabled until dirty; save writes via
  `saveRoleAndRegionPreference`, re-baselines, stays on-screen, shows
  `profileUpdated`.
- Retryable save failure preserves the draft + typed cause snackbar with Retry;
  other typed causes fail closed.
- `PopScope` unsaved guard: Back → Stay/Discard dialog; Discard pops directly.
- `didChangeDependencies` re-syncs the form when a NEW authoritative cloud row
  appears (identity switch), guarded by `identical(_lastSyncedCloud, …)`.
- Two compile defects surfaced during suite bring-up were corrected:
  non-promotable public `String? roleCode` guarded with `!`, and the two
  `_buildSection` call sites switched to the required named `context:`.

## 6. User Area Identity/Cloud Header (`user_area_screen.dart`)

`_UserAreaHeader` (private, deliberately LIST TILE-FREE) between the AppBar
and the navigation card:

- Ownership conflict → blocking card.
- Guest → `userAreaSignInPrompt` + full-width Login (`context.go` → `/auth`).
- Authenticated → initial/name/email, cloud line (role · region), in-flight
  loading line, typed load-failure line + Retry, or `profileNotAvailable`;
  Edit-profile push to `/user/profile/edit`; confirm-gated Sign out with
  pending spinner and recoverable failure snackbar.
- The hub navigation-card ListTile inventory remains EXACTLY five (asserted).

## 7. Routing: Authenticated Editor Dispatch + Legacy Guest Carrier

- `_buildProfileEdit` (shared by `/profile/edit` and `/user/profile/edit`):
  signed-in always renders the cloud editor regardless of extra; guests keep
  the W3.4 legacy local-edit contract (wrong-type → NotFound, missing-extra →
  provider fallback, valid local extra → ProfileEditScreen).
- Direct-dispatch and Back flows verified; `/user` remains a public hub while
  the `/user/profile` family stays protected.

## 8. Localization

Part 2 key blocks appended to `ar.dart` and `en.dart` (33 keys): auth
post-auth seams, signed-in card, cloud editor state keys, form/role/region
labels, save results, unsaved-discard dialog, sign-out confirm/pending/
failed, user-area sign-in prompt. All keys referenced by the reworked screens
were cross-checked against both files before the suites were run.

## 9. Verification — Focused Suites (evidence)

Focused run (no full `flutter test`, per environment rule) — ALL PASSED:

```
flutter test test/user_area_route_test.dart \
  test/v1_r08_auth_screen_widget_test.dart \
  test/v1_r08_profile_screen_widget_test.dart \
  test/v1_r08_profile_edit_screen_widget_test.dart \
  test/v1_r08_user_area_widget_test.dart \
  test/v1_r08_router_auth_test.dart \
  test/v1_r08_cloud_profile_foundation_test.dart \
  test/auth_provider_test.dart
```

Result: **124/124 tests green** across the 8 suites.

New Part-2 widget files added in this pass:

- `test/v1_r08_auth_screen_widget_test.dart` — 9 tests: quiet guest; success
  navigates only after the pipeline settles; cancelled; failed (typed);
  retryable seam + Retry resume; running seam (parked gateway, explicit pumps);
  provisioning; ownership-conflict fail-closed; unavailable gateway.
- `test/v1_r08_profile_screen_widget_test.dart` — 9 tests: guest local card +
  login; authenticated cloud card + Edit; load-failure Retry (no local fallback);
  gated loading (never "not set"); settled-empty fail-closed; sign-out
  confirm/cancel/confirm-success; sign-out failure + Retry; conflict-blocked
  body; W3.4 auth-agnostic local-card compatibility regression.
- `test/v1_r08_profile_edit_screen_widget_test.dart` — 11 tests (E1–E11):
  session-lost; gated loading → form; load-failure Retry; settled-empty
  fail-closed; canonical defaults + Save-disabled; role dialog (canonical-only)
  → Save enabled; region dialog (exactly six zones, "Not set" non-selectable);
  save writes + re-baselines + stays + `profileUpdated`; retryable failure
  preserves draft + Retry; PopScope Stay/Discard via real Navigator push;
  cloud re-read re-sync clears dirty. Holds only through a Navigator-push
  harness so Back/PopScope behave like production.
- `test/v1_r08_user_area_widget_test.dart` — 8 tests: guest header +
  Login + exact 5-tile inventory; cloud-bound role · region line; no-cloud
  not-available; in-flight loading; load-failure Retry recovers; sign-out
  confirm flows; sign-out failure + Retry; ownership-conflict block with intact
  nav inventory.

Route-level rework verified in `test/user_area_route_test.dart`: hub identity
header Edit push to `/user/profile/edit`; authenticated `/user/profile/edit`
dispatch contract (4 cases); W3.4 guest legacy `/profile/edit` contract
(4 cases); authenticated direct dispatch never reaches the local
`ProfileEditScreen`; the legacy edit test now rides `_guestAuth()`.

Test hygiene honored throughout: no `pumpAndSettle` while an indeterminate
spinner is mounted (Completer-gated gateways + explicit pumps), `FilledButton`
and `OutlinedButton` use type-predicate finders (the `.icon` factories build
private subclasses invisible to `find.byType`), and the `Ar.signOutConfirmTitle
== Ar.logout` string collision is avoided by asserting on the confirm message.

## 10. Constraints Honored During This Pass

- Contract `V1-R08_AUTH_PROFILE_PRODUCTION_COMPLETION_CONTRACT.md`: NOT
  modified (frozen).
- Migration 00022 / database contract: untouched.
- No `git add` / `git commit` / `git push`; Part 1 + Part 2 changes stay
  uncommitted as required.
- No full `flutter test`; no `flutter analyze` (pre-existing SDK analyzer
  crash on Flutter 3.32.8 / Dart 3.8.1 — see V1-R05 correction report §"Not
  run"); compilation correctness is carried by passing test compilation.
- `pubspec.lock` and `OpenCode_Usage_Report.txt`: untouched.
- `git diff --check`: clean (only pre-existing CRLF warnings).
- Headers render zero ListTiles → the hub inventory stayed exactly five.
- No email/password auth, no avatar upload, no account deletion, no
  multi-account workspaces introduced.

## 11. Not Done in This Pass

- Live DEV Supabase smoke (server/dev-availability deferred — unchanged
  environment constraint).
- Full-suite regression (deferred to the integration phase gate per §24).
- Roadmap phase-status edits (V1-R08 stays CURRENT until the independent
  UX/router review).
- Any Part 1 architecture rework (preserved stability per scope authority).

## 12. Final Decision

Part 2 production UX is implemented on the accepted Part 1 foundation, the
focused widget/routing suites (124 tests across the 8 suites) are green, the
documented Part-2 boundary items are delivered, and all standing constraints
(migration, contract, git state, analyzer/suite rules, report hygiene) were
honored. V1-R08 is NOT closed. The phase gate moves to independent UX/router
review with this report as the implementation evidence.

PART 2 COMPLETE — READY FOR INDEPENDENT UX/ROUTING REVIEW

---

## 13. Correction Addendum — Part 2 Independent Review (findings 1/2/3/5/9)

The independent UX/routing review of Part 2 returned findings F1/F2/F3/F5/F9
(no findings on the remaining items). Correction status for each:

- **F1 — `/user/profile/edit` guard.** `_buildProfileEdit` now dispatches on the
  canonical `AuthStatus` (not `isLoggedIn`): authenticated → cloud editor;
  conflict-bound → `_ProfileEditRouteBlockedScreen`; other non-guest
  unsettled states → `_ProfileEditRouteResolvingScreen` (never the legacy
  guest editor). Both seam screens **watch** `AuthProvider` and swap in the
  authenticated editor in place once the status settles — a GoRouter refresh
  alone does not re-invoke the dispatcher for an unchanged match.
- **F2 — conflicting local profile.** Verified the authenticated cloud card
  never reads a conflicting local profile (cloud is SSOT; local fallback is
  ignored).
- **F3 — unified conflict guard / recovery.** One shared `OwnershipConflictView`
  (stuck → Retry; restore-in-flight → disabled spinner; neutralized
  guest+conflict → Return-to-sign-in → `clearError` + optional `onCleared`),
  embedded in the auth screen, profile screen, user-area header (compact), and
  the router blocked screen. Guard everywhere: `error == ownershipConflict &&
  !isLoggedIn`. Raw Google sign-in is unavailable while conflict-bound.
  `clearError()` now also calls `notifyListeners()` explicitly — previously the
  neutralized state (status already `guest`) would never rebuild the UI after
  clearing (a real defect the new test caught).
- **F5 — sign-out pending UX.** Identity/sign-out branches keyed on
  `session != null` (not `isLoggedIn`), so the disabled + spinner pending sign-out
  action renders genuinely during `signOutPending`.
- **F9 — router recovery-navigation.** Protected `?return=` allowlist flows
  preserved; blocked route recovers via `context.go(AppRoutes.auth)`;
  resolving seam observed at `/profile/edit` while a restore is parked.
- **F2 forced-Arabic audit.** The auth, profile, user-area, editor and router
  surfaces are fully `tr()`-localized (profile `/auth` login button included);
  a `LanguageProvider` stub that always returned Arabic was made functional
  (English reachable) as the enabler for locale tests. Forced-Arabic
  `const Text(Ar.*)` found in articles/business/search/saved screens are
  outside R08 Part 2 scope.

### Correction verification (focused suites, no full suite — environment rule)

```
flutter test test/v1_r08_auth_screen_widget_test.dart \
  test/v1_r08_router_auth_test.dart \
  test/v1_r08_profile_edit_screen_widget_test.dart \
  test/v1_r08_user_area_widget_test.dart \
  test/v1_r08_profile_screen_widget_test.dart \
  test/user_area_route_test.dart
```

Result: **108/108 tests green** (66 correction-pass tests across the five
reviewed suites + 42-regression `user_area_route_test.dart`). New correction
coverage: F1 resolving seam at `/profile/edit` (never the guest editor) and
authenticated settle; stale-seam self-heal; F1/F3 blocked route Retry →
clean guest; neutralized route recovery navigates `/auth`; auth-screen
neutralized unlock (via the fixed `clearError`); F4 gated sign-in single-flight
+ spinner; F5 gated sign-out pending in profile + user area; F6 live
`sessionLost`/`signedOut` events revert profile/user-area/editor surfaces; F7
editor unchanged-Back passthrough and save single-flight lock; F8 conflicting
local profile never overrides cloud role/region; F10 English-locale suites
across all surfaces.

`git diff --check` clean (pre-existing CRLF warnings only). Object
`OpenCode_Usage_Report.txt`, the frozen contract, migration 00022, and the
roadmap are untouched; no `git add/commit/push`.

### Correction decision

The five review findings are corrected with proofs, no contract change is
required, and the surviving focused suites are green. Part 2 remains open to
the focused UX/routing recheck called for by the review.

---

## 14. Final Route/Conflict Correction — focused recheck pass

The final focused recheck returned four tightly related findings (all route-
seam / ownership-conflict recovery). All corrected, no architecture redesign:

- **1. Resolving seam → ALL terminal states.** `_buildProfileEdit` now returns
  one self-healing `_ProfileEditDispatch` widget that **watches** the canonical
  `AuthStatus` and re-renders the correct target on every settle (a GoRouter
  refresh alone does not re-invoke the route builder for an unchanged match):
  - resolving → authenticated → `AuthenticatedProfileEditScreen`;
  - resolving → guest → the legacy W3.4 local-edit contract (extra →
    provider fallback → NotFoundScreen);
  - resolving → ownership-conflict → fail-closed
    `_ProfileEditRouteBlockedScreen` / `OwnershipConflictView`.
  The two seam screens are now presentational only — the dispatcher is
  authoritative, so no stale seam can remain mounted.
- **2. Active-conflict Retry → guest blank dead-end.** Previously the blocked
  screen shell could stay mounted as `OwnershipConflictView` shrank to
  `SizedBox.shrink()` (blank). The dispatcher now replaces the blocked screen
  entirely once any settlement occurs — Retry → clean guest lands on the
  deterministic guest surface (legacy editor / NotFoundScreen), never blank,
  never stale A/B data, never a silently continuing authenticated flow.
- **3. Local single-flight recovery guard.** `OwnershipConflictView._handle()`
  now sets `_isHandling = true` BEFORE awaiting provider work and swallows a
  duplicate callback that lands before a rebuild disables the affordance;
  canonical provider state remains authoritative. A same-frame double-tap test
  proves exactly ONE provider operation for one recovery.
- **4. Tests for the missing transitions** (in `v1_r08_router_auth_test.dart`):
  resolving → clean guest; resolving → ownership conflict; conflict Retry →
  guest (no blank; NotFoundScreen seam asserted); double-recovery tap
  (gated `_GatedRetryGateway`, restore call count == 2 = one setup + ONE
  retry). The existing Retry test gained an explicit no-blank assertion.

### Final focused verification (no full suite — environment rule)

```
flutter test --no-pub test/v1_r08_router_auth_test.dart
flutter test --no-pub test/v1_r08_auth_screen_widget_test.dart \
  test/v1_r08_profile_screen_widget_test.dart \
  test/v1_r08_user_area_widget_test.dart \
  test/v1_r08_profile_edit_screen_widget_test.dart \
  test/user_area_route_test.dart
```

Result: **111/111 tests green** across the six suites (17 router incl. the new
transition/single-flight tests; 94 affected + regression). Preserved: resolving
→ authenticated, authenticated cloud-editor dispatch, settled-guest legacy
dispatch, conflict fail-closed, F2 cloud SSOT, F5 sign-out UX, secure
`?return=` allowlist, English/Arabic localization, Part 1 lifecycle, second-
account security, no migration 00022. `git diff --check` clean (pre-existing
CRLF warnings only); nothing staged/committed/pushed;
`OpenCode_Usage_Report.txt` untouched.

### Final correction decision

The four findings are corrected with proofs on the smallest reactive
implementation consistent with the router/provider architecture. No contract
change required; V1-R08 remains open to the last UX/routing confirmation.