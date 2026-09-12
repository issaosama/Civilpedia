# V1-R08 Part 1 — Review Findings Correction Report

**Phase:** V1-R08 Part 1 independent-review correction pass
**Scope:** the 26 concrete review findings against the V1-R08 auth/profile
production-completion surface. No Part 2 UX, no redesign, no destructive
migration, no change to the frozen contract document.

---

## 1. What was corrected

### Auth provider / session epoch (findings on auth lifecycle)
- `lib/features/auth/presentation/providers/auth_provider.dart`
  - `_reconcileAuthenticatedSession` now advances `generation` on EVERY genuine
    identity transition, INCLUDING `guest → authenticated` and `authenticated →
    guest`; same-identity refreshes / token renewals / same-user re-auth while
    already authenticated NEVER advance.
  - The pending post-auth run is keyed by `(userId, generation)` via the new
    `_PipelineRun` single-flight record: a divergent account (or later
    generation) never reuses another identity's in-flight pipeline future, and a
    stale completion is dropped by the final generation check.
  - `retryPostAuth()` is strictly gated: only a current authenticated session
    with `postAuthState == retryableFailure` and no in-flight run triggers a
    re-run.
  - `_enterGuest` advances the epoch (only when a session/state actually
    existed), clears the pipeline record, and notifies the account-bound reset.
  - `clearError` also notifies the router refresh listenable.
  - `sessionReplaced` handler simplified — generation/reset semantics live only
    in `_reconcileAuthenticatedSession`.

### Account-bound state reset seam (findings on cross-account leakage)
- `lib/main.dart` — account-bound providers are built once, and a single
  `resetAccountBoundState` closure resets them together on every canonical
  identity change (transition into a different user OR sign-out/session loss):
  - `UserProfileProvider.resetForIdentityChange()`
  - `BusinessApplicationProvider.resetForIdentityChange()`
  - `BusinessClaimTargetProvider.resetForIdentityChange()`
  - `ManagedBusinessesProvider.reset()`
  - `BusinessProfileEditorProvider.reset()`
  - `StaffOperationsScope.resetForAuthChange()` (access + queue + detail)
- Providers converted to `ChangeNotifierProvider.value` so the same instances
  reset in place.

### Cloud profile SSOT + strict parsing (findings 1/4/17)
- `lib/features/profile/presentation/providers/user_profile_provider.dart`
  rewritten:
  - `profile` (local) is exposed ONLY while signed out.
  - `authenticatedProfile` (strictly parsed `CloudProfile`) is the sole
    authoritative profile while signed in; `saveProfile` is a no-op while
    authenticated (no local surrogate can shadow cloud state).
  - `ensureCloudProfileLoaded()` coalesces reads and publishes results only
    under the captured `(userId, generation)` — stale/guest results are dropped.
- `lib/features/profile/data/cloud_profile.dart` — `parseCloudProfileRow`
  enforces: `user_id` present + matches the authenticated user + valid UUID;
  `role_code` canonical when present; UUID-typed columns valid; throws typed
  `CloudProfileParseException`. `isCanonicalRoleCode` / `canonicalRoleCodes`
  are the single source for allowed role values. (Also fixed the
  `supplier_shopOwner` → `supplierShopOwner` typo.)

### Frozen mutation surface (findings 2/18)
- `displayName` is no longer a cloud-written field:
  - `updateDisplayName` removed from `PersonalProfileRemoteGateway`,
    `SupabasePersonalProfileRemoteGateway`, the provider, and every test fake.
  - The only authenticated mutation is `saveRoleAndRegionPreference` → single
    `saveEditableFields(userId, roleCode, regionPreferenceId)` call backed by a
    strict validation chain.

### Save foundation (findings 3/13/14/17)
- `lib/features/profile/presentation/providers/profile_operation_result.dart`
  (new) — typed `ProfileOperationCause` + `ProfileOperationResult`.
- `saveRoleAndRegionPreference` guarantees:
  1. unauthenticated → `unauthenticated`, no-op;
  2. non-canonical role / unknown region code → `invalidData`, no remote call;
  3. known code resolved through `RegionPreferenceGateway` (never a hardcoded
     UUID); resolution failure → `retryableFailure`;
  4. duplicate of current authoritative values → `ok(wasNoOp: true)` with NO
     backend mutation;
  5. write failure / RLS denial → typed `retryableFailure` / `permissionDenied`,
     prior cloud state preserved;
  6. success triggers an authoritative strict re-read; only a parse under the
     SAME `(userId, generation)` installs state; later results → `sessionLost`.
- RLS denial mapping (`SQLSTATE 42501`/“permission denied”) and insert-race
  (`23505`) mapping live in `SupabasePersonalProfileRemoteGateway`.

### Provisioning without a local profile (finding 5)
- `PersonalProfileBootstrapCoordinator._provisionWithoutLocalProfile` creates a
  minimal canonical row from authenticated metadata ONLY (userId +
  displayName/photoUrl) when no local profile exists; an existing row is simply
  accepted (`associated`); the insert race is re-read deterministically.
  `ProfileBootstrapOutcome.noLocalProfile` removed.

### Routing / return destination (findings 11/12/21)
- `lib/features/auth/presentation/auth_refresh_listenable.dart` (new) — router
  `refreshListenable` reacts to live identity transitions.
- `lib/features/auth/domain/auth_return_destination.dart` (new) — allowlist
  resolver shared by `app_router` redirect and `auth_screen`: starting `/`,
  no scheme/authority, no `//`, no `..`, inside the protected families only.

### Gateway lifecycle (finding 16)
- `AuthGateway` gains a default `dispose()`; `AppDependencies.dispose()` invokes
  `_authGateway.dispose()` (Supabase gateway cancels its auth stream).

## 2. Verification

Focused `flutter test --no-pub` (no analyser, no full suite, pubspec.lock
untouched) — all green:

- `test/v1_r08_cloud_profile_foundation_test.dart` (rewritten: SSOT, strict
  parser, save foundation, typed causes, duplicate guard, stale suppression)
- `test/v1_r08_auth_session_foundation_test.dart` (epoch semantics, keyed
  pipeline, divergent-account isolation, retry gating, account-bound reset)
- `test/v1_r08_router_auth_test.dart` (new: return allowlist + live redirect)
- `test/a5_6_profile_bootstrap_test.dart`, `test/a5_7_region_reference_test.dart`
- `test/profile_edit_route_test.dart`, `test/user_area_route_test.dart`,
  `test/a5_8_setup_flow_test.dart`, `test/a5_8_splash_restart_route_test.dart`,
  `test/auth_screen_test.dart`, `test/w6_3_nav_transition_test.dart`,
  `test/ui_safe_1_screen_regression_test.dart`, `test/a5_5_ownership_claim_test.dart`,
  `test/widget_test.dart`

`git diff --check` clean; `pubspec.lock` at committed baseline; frozen contract
document and `OpenCode_Usage_Report.txt` untouched.

---

**Final decision line:**

CORRECTIONS COMPLETE — READY FOR FOCUSED AUTH/SESSION RECHECK