# V1-R09 Part 1 — Infrastructure Implementation Report

This is an implementation report, not a closure or acceptance report.

## Connectivity Foundation

- source abstraction: `TransportSource` owns the injectable initial check and change stream; `ConnectivityPlusTransportSource` is the sole production adapter that constructs `connectivity_plus`.
- canonical states: `TransportState.unknown`, `available`, and `unavailable` are the canonical app-wide transport meanings. `available` means transport only, not internet or Supabase health.
- initialization: `ConnectivityProvider` starts `unknown`, subscribes before checking, applies the centralized three-second deadline, and publishes a successful check only if a newer stream event has not already won the race.
- stream handling: change events are deduplicated at provider state level; stream errors safely return the authority to `unknown` without escaping.
- disposal: disposal is idempotent, clears the retained subscription, cancels it exactly once, absorbs an asynchronous cancellation error, and ignores all later callbacks.
- transition semantics: `reconnectGeneration` advances exactly once for each real `unavailable` → `available` edge. Repeated `available` signals do not create a second reconnect identity. The compatibility `isOnline` getter is true only for confirmed `available`; `unknown` is false.

## Timeout Infrastructure

- policy: `RemoteOperationPolicy` centralizes all V1-R09 defaults, and `runWithRemoteDeadline` converts application deadline expiry to a typed infrastructure timeout without pretending to cancel an uncancellable SDK Future.
- startup: six seconds for Supabase service initialization.
- reads: fifteen seconds for ordinary authenticated-profile and region-preference reads used by the post-auth profile foundation.
- mutations: twenty seconds for personal-profile writes and authoritative sign-out.
- auth exchange: twenty seconds around only the Supabase credential exchange after Google credentials are obtained; the human account picker and consent interaction remain unbounded.
- connectivity: three seconds for the initial platform transport check.

## Failure Classification

- common type: `InfrastructureFailureKind`, `InfrastructureFailure`, and the small `InfrastructureFailureException` boundary.
- offline: produced only when a caller explicitly supplies confirmed unavailable transport context.
- timeout: produced by the application-owned deadline helper and recognized when classifying an existing `TimeoutException`.
- network: socket, TLS handshake, and HTTP transport exceptions map to network.
- unavailable: missing backend configuration and explicitly typed service-unavailable failures remain distinct.
- malformed: `FormatException` maps to malformed response.
- unknown: all unclassified failures remain unknown; they are not mislabeled as network.
- domain preservation: typed feature/domain exceptions pass through deadline wrappers unchanged. Auth rejection and profile permission/provisioning outcomes are mapped before the common infrastructure layer.

## Startup Resilience

- previous blocking path: `main()` awaited `AppDependencies.init()`, which in turn awaited an unbounded `Supabase.initialize(...)` call before `runApp`.
- new behavior: the existing dependency container still owns one service and one initialization operation, but waits at most the frozen six-second application deadline.
- Supabase timeout: timeout records a typed timeout failure, returns from initialization safely, and leaves backend-dependent capabilities unavailable.
- failure: missing configuration and thrown initialization failures do not escape into app startup; the service exposes unavailable state plus a typed reason.
- local shell: local initialization remains in the existing container, and the app reaches `runApp` after missing configuration, immediate initialization failure, or the bounded timeout.
- late initialization: the original in-flight operation may complete later on the same `SupabaseService`. Late success transitions that instance to ready and notifies listeners; the existing auth gateway then attaches to the authoritative Supabase auth stream. No second container or client was introduced.

## Auth / Network Safety

- sign-in: production Supabase auth separates retryable transport failures, auth/config rejection, cancellation, and unexpected faults without surfacing raw SDK errors.
- exchange timeout: only the post-Google Supabase exchange is bounded. Timeout maps to `AuthError.retryableNetwork` and cannot fabricate an authenticated session.
- sign-out: canonical Supabase sign-out is bounded by the mutation deadline. Timeout, network failure, or unavailable authority produces `AuthError.signOutFailed`; no automatic retry or mutation replay was added.
- cached session: failed authoritative sign-out leaves the current authenticated session and account-bound state intact, and clears the provider busy state.
- post-auth bootstrap: production personal-profile reads/writes and region-preference reads use timed decorators. Deadline expiry is caught by the existing coordinator/provider boundaries as retryable post-auth failure while authentication remains valid; an intentional session-bound retry can later succeed.
- definitive session loss: the existing accepted Supabase `signedOut`, user removal, and equivalent authoritative lifecycle events continue to own transition to guest.
- temporary connectivity loss: `ConnectivityProvider` has no auth dependency and cannot sign in, sign out, replace a session, clear account data, or advance auth generation.
- stale-result protection: existing auth epoch, session generation, single-flight, second-account fail-closed, and stale-completion checks were not bypassed or replaced.

## Reconnect Foundation

- transition: consumers can observe explicit transport state and a monotonic identity for each real `unavailable` → `available` transition.
- duplicate prevention: provider state deduplication plus `reconnectGeneration` lets a future eligible read remember the last handled transition and avoid retry storms.
- mutation replay: none. No reconnect callback submits, signs out, saves a profile, or performs any other mutation.
- Part 2 integration: no Directory, encyclopedia, business/staff, profile, banner, or other feature auto-refresh was wired in Part 1.

## Tests

- connectivity: 11 focused cases cover initial `unknown`, `unknown` not online, available/unavailable initial results, timeout, exception, both transition directions, duplicate reconnect suppression, stream error, exact-once disposal, post-dispose suppression, and initial-check/stream race ordering.
- timeout/classification: 9 focused cases exercise actual deadline/helper and timed-gateway boundaries, all common classifications, and preservation of a profile permission denial.
- startup: 9 service cases cover missing/invalid configuration, successful initialization, thrown failure, short injected stall deadline, late readiness on the same service, and the exact frozen production deadline.
- auth: 27 cases selected across `supabase_auth_gateway_test.dart` (11) and `auth_provider_test.dart` (16), including exchange timeout, retryable transport mapping, auth rejection, unexpected failure, sign-out timeout, sign-out network failure, late service readiness, timed post-auth profile read/retry, and connectivity/auth separation.
- R08 regressions: 109 directly affected cases selected across `v1_r08_auth_session_foundation_test.dart` (45), `a5_6_profile_bootstrap_test.dart` (39), and `v1_r08_cloud_profile_foundation_test.dart` (25), including definitive signed-out handling and stale old-session completion suppression.
- exact counts: 165 test cases selected/discovered statically; 0 test cases executed, 0 assertion failures observed, and 1 Flutter runner preflight failure. Both the smallest connectivity command and the final eight-file focused command exited before test discovery because Flutter attempted to write `C:\src\flutter\bin\cache\libimobiledevice.stamp`, which is outside the permitted workspace. Modifying or repairing the Flutter SDK/cache was explicitly out of scope.
- full suite: NO.
- analyzer: NO.

## Part 2 Boundary

- Directory integration: not implemented; no immediate-cache publication or Directory reconnect refresh.
- stale-empty: not changed.
- encyclopedia errors: raw-error presentation not changed.
- offline banner: not added.
- feature UX: no broad localized failure/empty-state normalization.
- reconnect reads: foundation only; no feature read is automatically refreshed yet.

## Protection

- R08 changed: implementation seams were hardened, but no accepted R08 auth/session/ownership semantics were changed.
- migration 00022: absent.
- old migrations: untouched.
- contract: the pre-existing untracked frozen V1-R09 contract was read as authority and not edited.
- roadmap: the pre-existing modified roadmap was not edited by Part 1 implementation.
- pubspec: unchanged.
- new dependencies: none.

## Git

- diff check: PASS; `git diff --check` reported no whitespace errors (only Git's existing LF-to-CRLF working-copy warnings).
- staged: NO.
- committed: NO; `HEAD` remains `e80fab8883a3631e58d1cc9bb83846c7f981d0fa`.
- pushed: NO; local `HEAD` and `origin/main` remain the same recorded commit.
- OpenCode_Usage_Report.txt: pre-existing untracked file, untouched by this implementation.

## Files Changed

Part 1 implementation/report files:

- `lib/core/network/remote_operation_policy.dart`
- `lib/core/services/transport_source.dart`
- `lib/core/services/connectivity_provider.dart`
- `lib/core/backend/supabase_service.dart`
- `lib/core/di/app_dependencies.dart`
- `lib/features/auth/data/supabase_auth_gateway.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart` (format-only; provider behavior remains unchanged)
- `lib/features/profile/data/timed_profile_gateways.dart`
- `test/connectivity_provider_test.dart`
- `test/remote_operation_policy_test.dart`
- `test/supabase_service_test.dart`
- `test/supabase_auth_gateway_test.dart`
- `test/auth_provider_test.dart`
- `docs/architecture/reports/V1-R09_PART1_INFRASTRUCTURE_IMPLEMENTATION_REPORT.md`

Pre-existing protected worktree entries, not changed by this implementation:

- `docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md`
- `docs/architecture/contracts/V1-R09_OFFLINE_CONNECTIVITY_ERROR_HARDENING_CONTRACT.md`
- `OpenCode_Usage_Report.txt`

## V1-R09 Part 1 — Critical Auth/Network Correction Cycle

Independent review identified 3 HIGH + 2 MEDIUM defects. Part 1 was NOT restarted; only the five reported defects were fixed.

### H1 — Server-first authoritative sign-out

- `SupabaseAuthGateway.signOut()` now performs remote revocation BEFORE clearing the local SDK session.
- Production remote revocation uses the public GoTrue `/auth/v1/logout` HTTP endpoint with the current access token.
- A 20-second application deadline (`RemoteOperationPolicy.mutation`) bounds the remote call.
- On remote timeout/network/service failure the local SDK session is preserved and `AuthGatewayException(AuthError.signOutFailed)` is returned; the provider stays authenticated.
- On remote success the local SDK session is cleared with `SupabaseClient.auth.signOut(scope: SignOutScope.local)` and the provider transitions to guest.
- Added real SDK / controlled-HTTP tests using a local `HttpServer` impersonating GoTrue: remote success clears local session and provider becomes guest; remote failure/timeout keep both SDK and provider sessions.

### H2 — Auth stream error continuity

- `_ensureAuthStateSubscription()` no longer cancels the upstream subscription on recoverable stream errors.
- Errors are logged and the broadcast stream stays alive so later `signedOut`/`userRemoved`/refresh events are still forwarded.
- `onDone` only marks the subscription null so a later access re-subscribes without duplicates.
- Added tests proving a stream error is followed by a forwarded `signedOut` event and that multiple listeners do not create duplicate SDK subscriptions.

### H3 — Timed-out credential exchange quarantine

- Each `signInWithGoogle()` attempt receives a monotonic credential-exchange generation token.
- A pending exchange blocks competing sign-in attempts (`AuthError.retryableNetwork`).
- `Future.timeout()` is still used for the application deadline, but a late-completion watcher is attached to the raw SDK exchange Future.
- On timeout the operation is marked timed-out; any `signedIn` event it later publishes is suppressed in `_mapAuthState`.
- Late failure clears the quarantine and allows retry.
- Late success triggers stale-session neutralization (remote-first sign-out + local clear) before the quarantine is released; the provider never installs the stale session.
- Added tests for timeout, second-attempt blocking, late failure, late-success neutralization, and fresh retry after quarantine release.

### M1 — Google cleanup cannot block sign-out

- `_boundedGoogleSignOut()` now runs AFTER remote revocation and local SDK clear.
- It is best-effort, bounded by `RemoteOperationPolicy.mutation`, and non-blocking (`unawaited`).
- If `_googleSignIn` was never initialized (e.g., tests using injected credential exchange), it is lazily created from the factory so cleanup is still attempted.
- Added test proving a never-completing Google `signOut()` does not prevent the provider from becoming guest.

### M2 — Region-fill timeout is retryable, not success

- `PersonalProfileBootstrapCoordinator._associateOrConflict()` now classifies infrastructure failures from `updateRegionPreferenceId`.
- Timeout / network / offline / service-unavailable failures return `ProfileBootstrapOutcome.failure` (retryable) instead of falsely associating.
- Permission, provisioning, malformed, and unknown domain errors remain non-fatal and preserve the completed association.
- Added test through the real chain `TimedRegionPreferenceGateway` → `TimedPersonalProfileRemoteGateway` → `PersonalProfileBootstrapCoordinator` → `AuthProvider`/`retryPostAuth()`: timeout is retryable, auth stays valid, retry succeeds, no corrupt binding.

### Correction test results

- `test/supabase_auth_gateway_test.dart`: 21/21 PASS (was 11/11; added H1/H2/H3/M1 coverage).
- `test/auth_provider_test.dart`: 16/16 PASS.
- `test/a5_6_profile_bootstrap_test.dart`: 40/40 PASS (was 39/39; added M2 coverage).
- `test/v1_r08_auth_session_foundation_test.dart`: 45/45 PASS.
- `test/v1_r08_cloud_profile_foundation_test.dart`: 25/25 PASS.
- Total directly affected focused tests executed: 147 PASS / 0 FAIL / 0 skipped.
- No analyzer run; no pub get; no migration; no contract/roadmap/pubspec change.

## Remaining Concerns

None.

## Architecture-Approved Final Correction Cycle — Blocked

An authoritative architecture adjudication approved a final surgical correction design with the following mandatory elements:

- H1: remote-first sign-out using the public `client.auth.admin.signOut(accessToken, scope: SignOutScope.local)` API.
- H1: persistent Hive-based auth recovery journal written before any risky auth mutation.
- H1/H3: guarded `FlutterAuthClientOptions.localStorage` adapter that consults the recovery journal before allowing persisted SDK sessions to become restorable application authority.
- H1: explicit sign-out state machine (`AUTHENTICATED → REMOTE_PENDING → LOGGED_OUT_CLEANUP_REQUIRED`) with cleanup-failure and cleanup-stall recovery states.
- H2: auth-stream continuity with unexpected `onDone` leading to a restart-required blocked state.
- H3: explicit credential-exchange state machine (`IDLE / ACTIVE(g) / COMMITTING(g) / TIMED_OUT_PENDING(g) / NEUTRALIZING(g) / BLOCKED_CLEANUP_FAILURE(g)`) with deadline arbitration and event buffering/admission.
- H3: journal-gated `restoreSession()` and `retryAuthCleanup()` recovery operation.
- M2: specific PostgreSQL error-code mapping in `SupabasePersonalProfileRemoteGateway.updateRegionPreferenceId` and null-only conditional fill with authoritative reread.
- Minimal UI/router/localization updates for `LOGGED_OUT_CLEANUP_REQUIRED`, `BLOCKED_CLEANUP_FAILURE`, and restart-required states.

### Why this pass is blocked

The approved architecture is a substantial redesign of the auth recovery surface. Safe implementation requires:

1. Verifying the exact public `LocalStorage` / `FlutterAuthClientOptions` interface against the installed SDK versions (`supabase_flutter 2.15.4`, `supabase 2.13.4`, `gotrue 2.25.0`). The workspace does not expose the SDK source, and guessing the interface would risk silent runtime breakage or compile failures.
2. Introducing a persistent recovery journal and a guarded local-storage adapter that intercepts every Supabase auth persistence read/write. This is a cross-cutting change that affects startup ordering, crash recovery, and all auth state transitions.
3. Rewiring `AuthProvider`, `SupabaseAuthGateway`, `AuthScreen`, `UserAreaScreen`, and the router around a multi-phase state machine. The scope is larger than a single surgical correction pass and needs dedicated incremental review/tests.
4. The previous focused correction (H1/H2/H3/M1/M2) already passed 147 directly affected tests and delivered the requested security semantics (remote-first sign-out, stream continuity, credential-exchange quarantine, region-fill timeout handling). Re-architecting it now without the ability to verify the new SDK hooks endangers those passes.

### Recommended path forward

- Either break the approved architecture into smaller, independently verifiable increments (journal + adapter first, then state machine, then UI), or
- Accept the previous focused correction as the V1-R09 Part 1 security fix and schedule the full recovery-state architecture for V1-R09 Part 2 or a dedicated auth-hardening sub-phase.

## Final Decision

IMPLEMENTATION BLOCKED — ARCHITECT DECISION REQUIRED

---

# V1-R09 Part 1 — C1 Recovery Foundation Evidence

SDK source inspection was performed READ-ONLY on the installed Pub cache:

- `supabase_flutter 2.15.4` (`C:\Users\acer\AppData\Local\Pub\Cache\hosted\pub.dev\supabase_flutter-2.15.4`)
- `supabase 2.13.4`
- `gotrue 2.25.0`

Verified public contracts:

- `FlutterAuthClientOptions.localStorage` is typed as `LocalStorage?` and passed through `Supabase.initialize(authOptions: ...)` to `SupabaseClient` auth options.
- `LocalStorage` (defined in `supabase_flutter/src/local_storage.dart`) has five public methods:
  - `Future<void> initialize()`
  - `Future<bool> hasAccessToken()`
  - `Future<String?> accessToken()`
  - `Future<void> removePersistedSession()`
  - `Future<void> persistSession(String persistSessionString)`
- Storage serialization ownership: `SupabaseAuth._onAuthStateChange` encodes `session.toJson()` and passes the JSON string to `persistSession(...)`; restoration calls `accessToken()` and feeds the same string to `setInitialSession(...)` / `recoverSession(...)`.
- Default storage key is computed by `Supabase.initialize` as `"sb-${host first segment}-auth-token"` when no custom `localStorage` is supplied.
- Restoration sequence: `SupabaseAuth.initialize()` calls `_localStorage.initialize()`, `hasAccessToken()`, `accessToken()`, then `setInitialSession(...)`; later `SupabaseAuth.recoverSession()` calls `accessToken()` again and `recoverSession(...)`.

## New source files

- `lib/features/auth/data/session_correlation.dart` — non-secret session correlation handle (`userId` + `expiresAt`), factory from GoTrue session JSON.
- `lib/features/auth/data/auth_recovery_journal.dart` — versioned Hive journal; typed recovery state (`none`, `unresolved`, `cleanupRequired`, `corrupt`); operations `beginOperation`, `updatePhase`, `complete`, `markCorrupt`; acknowledged-write results surfaced as `Future<bool>`.
- `lib/features/auth/data/guarded_supabase_local_storage.dart` — `LocalStorage` adapter wrapping a delegate (default `SharedPreferencesLocalStorage`) and consulting the recovery journal before returning a persisted session during normal restoration; serializes storage operations through an internal queue.

## Modified source files

- `lib/core/storage/app_storage_keys.dart` — additive `authRecoveryJournalBox` and `authRecoveryJournalEntry` keys.
- `lib/core/backend/supabase_service.dart` — when no custom `initialize` is injected, builds the recovery journal and guarded `LocalStorage` adapter, passes it through `FlutterAuthClientOptions.localStorage`, and exposes the post-init `AuthRecoveryState` via `recoveryState`.

## Design decisions

- Journal stores only metadata (`schemaVersion`, `operationId`, `operationType`, `phase`, `userId`, `expiresAt`, timestamps). No access token, refresh token, ID token, Google token, or OAuth credential is persisted or derivable.
- Session correlation is `userId` + `expiresAt` from session metadata; stronger than user id alone, non-secret, no token hashing.
- Fail-closed startup: unresolved/cleanup-required/corrupt recovery records cause the guarded adapter to return `null` to the SDK restoration path, so the persisted snapshot cannot become normal application auth authority. The underlying snapshot remains in the delegate storage for later recovery operations.
- Local Civilpedia functionality remains available because Supabase initialization still completes; only authenticated state is suppressed.
- No migrations, no second SupabaseClient, no custom token store, no service_role, no pubspec/dependency changes.

## Tests

New focused test file: `test/auth_recovery_foundation_test.dart`.

Coverage:

- SDK integration: custom adapter used during real `Supabase.initialize`; no second Supabase client.
- Normal startup: persisted session restored when journal absent.
- Unresolved recovery: persisted session blocked, `currentSession` null, status `unresolved`.
- Cleanup-required recovery: persisted session blocked, status `cleanupRequired`.
- Corrupt recovery: startup succeeds, account access blocked, status `corrupt`; invalid schema also yields corrupt.
- Journal durability: begin/update/complete round-trip; write failure surfaced when box closed.
- Token safety: raw serialized journal entry verified not to contain access/refresh/Google/provider tokens.
- Restart persistence: unresolved block survives Supabase disposal + reinitialization; completing recovery allows normal restoration.
- Session correlation: extraction from session JSON; stronger-than-user-id via expiration.

Results:

- `test/auth_recovery_foundation_test.dart`: 14/14 PASS.
- `test/supabase_auth_gateway_test.dart`: 21/21 PASS (regression).
- `test/auth_provider_test.dart`: 16/16 PASS (regression).
- `test/supabase_service_test.dart`: 9/9 PASS (regression).
- C1 + directly affected foundation regressions: 60/60 PASS.
- No analyzer run; no pub get; no full suite.

## C1 Scope Protection

- H1 logout behavior: NOT modified beyond the recovery foundation.
- H2 stream recovery: NOT modified.
- H3 exchange quarantine: NOT modified.
- M2 profile mapping: NOT modified.
- Broad recovery UX: NOT added.
- Part 2: NOT started.
- Migration 00022: absent.
- Frozen contract: untouched.
- Roadmap phase controls: untouched.
- pubspec: unchanged.
- Dependencies: none added.
- SDK/package source: read-only; no modifications.
- SupabaseClient count: one per `Supabase.initialize` call, as before.

## Remaining Concerns

None for C1.

## Final Decision

C1 COMPLETE — READY FOR INDEPENDENT REVIEW

---

# V1-R09 Part 1 — C1 Recovery Foundation Correction Cycle

Independent review found 4 HIGH + 5 MEDIUM defects in the C1 recovery foundation. This pass did NOT restart C1, C2/C3/C4, or Part 2; only the reported findings were corrected.

## Journal Hardening

- **typed schema:** Added closed `AuthRecoveryOperationType` and `AuthRecoveryPhase` enums. `AuthRecoveryJournalEntry` now stores and validates typed values; unknown `operationType`/`phase` values fail parsing and map to `corrupt`.
- **idle/unknown behavior:** Removed the previous `case 'idle': return none` mapping. Any persisted journal record now maps to a blocking state (`unresolved`/`cleanupRequired`) or `corrupt`; no existing record maps to `none`.
- **corrupt handling:** `read()` treats any non-null value at the corrupt flag key as corrupt. Malformed corrupt markers, schema mismatches, and unknown enum strings all fail closed to `AuthRecoveryStartupStatus.corrupt`.
- **corrupt write failure:** `markCorrupt(AuthRecoveryCorruptReason)` returns `Future<bool>`. If persistence fails, an in-memory corrupt latch is set for the current process and `false` is returned; account authority remains blocked and the failure is observable.
- **operation ownership:** `beginOperation` refuses to overwrite an existing unresolved/cleanup/corrupt record. `updatePhase` and `complete` require `expectedOperationId` and optional `expectedCorrelation`; stale operations cannot mutate or clear a newer record.
- **overwrite protection:** Tests prove `begin A → begin B` leaves A intact, `complete A with wrong id` leaves A intact, and `complete A with correct id` allows later B.
- **project scoping:** `AuthRecoveryJournal.open` accepts a stable non-secret `projectIdentity` derived from the Supabase URL host and scopes the Hive box name. Project A's unresolved record does not block project B; recreating project A still sees A's record.
- **result:** Journal state is closed/typed and fail-closed.

## Session Correlation

- **project identity:** Added `projectIdentity` to `SessionCorrelation`; it participates in correlation matching.
- **user identity:** `userId` retained as required field.
- **session_id:** Added safe local Base64URL JSON-payload decoding of the GoTrue access-token JWT to extract the non-secret `session_id` claim; no JWT dependency added, no signature verification performed.
- **expiresAt:** Retained as auxiliary metadata.
- **missing session_id:** Correlation explicitly marks `hasSessionId == false` and `isSufficientForDestructiveCleanup == false`; C2/C3 must remain blocked from destructive cleanup using only `userId + expiresAt`.
- **secret safety:** `SessionCorrelation.toMap()` stores only `sessionId`, never the raw bearer token, refresh token, or full JWT. `toString()` redacts the session id.
- **destructive ownership readiness:** `matches()` requires project + user + session_id equality and sufficient correlation on both sides.
- **result:** Correlation model is safe and stronger than `userId + expiresAt`.

## Guarded Storage

- **retained instance:** `SupabaseService` now creates and retains an `AuthRecoveryStorageCoordinator` and exposes `recoveryCoordinator` and `guardedLocalStorage`; later C2/C3 recovery uses the exact same adapter/serialization boundary.
- **SDK format:** The adapter delegates to the SDK's normal `SharedPreferencesLocalStorage` using the same storage key; exact session string is persisted unchanged.
- **restoration blocking:** `accessToken()` consults the journal and returns `null` for `unresolved`/`cleanupRequired`/`corrupt`; underlying snapshot remains intact and recoverable via `readPersistedSnapshotForRecovery()`.
- **common ordering boundary:** `AuthRecoveryStorageCoordinator` owns one `RecoveryAsyncQueue`; journal transitions and SDK persisted-session access/removal are serialized through the same queue.
- **queue failure recovery:** A delegate failure does not permanently poison the queue; later operations still execute.
- **snapshot retention:** Tests verify the exact underlying snapshot remains intact while restoration is blocked.
- **result:** One retained guarded adapter + one shared recovery queue.

## Account Authority Gate

- **canonical recovery state:** `SupabaseService.recoveryState` re-reads from the journal on every access; `SupabaseAuthGateway.canAccountAuthorityBeGranted` queries the current state, so there is no one-time copied boolean.
- **fresh sign-in blocked:** `signInWithGoogle()` checks `canAccountAuthorityBeGranted` before obtaining credentials or starting SDK exchange and throws `AuthGatewayException(AuthError.recoveryBlocked)`.
- **auth event blocked:** `_mapAuthState` suppresses identity-bearing events (`initialSession`, `signedIn`, `tokenRefreshed`, `userUpdated`, `mfaChallengeVerified`, `sessionReplaced`) while recovery blocks authority; loss events still forward safely.
- **restore blocked:** `restoreSession()` returns `null` while recovery blocks authority.
- **clean state:** When no recovery record exists, existing R08 sign-in/restoration behavior remains unchanged.
- **profile/bootstrap:** Because identity-bearing paths are suppressed, the post-auth claim/bootstrap pipeline cannot start while recovery is blocked.
- **result:** Minimal C1 admission gate; no H2/H3 redesign.

## Restart Safety

- **close/reopen:** Tests close the Hive box (or all boxes) and recreate the journal/coordinator/service backed by the same persistence.
- **unresolved:** Unresolved recovery survives close/reopen and Supabase reinitialization.
- **corrupt:** Corrupt state survives close/reopen.
- **owned completion:** Completing the owned operation allows normal restoration on the next startup.
- **project isolation:** Project A's unresolved record does not block project B; recreating project A retains A's record.
- **result:** Recovery state is durable across reconstruction.

## Tests

- **exact files:**
  - `test/auth_recovery_foundation_test.dart`
  - `test/supabase_service_test.dart`
  - `test/supabase_auth_gateway_test.dart`
  - `test/auth_provider_test.dart`
  - `test/v1_r08_auth_session_foundation_test.dart`
  - `test/v1_r08_auth_screen_widget_test.dart`
  - `test/v1_r07_staff_operations_flutter_test.dart`
- **exact counts:** 49 + 9 + 21 + 16 + 45 + 14 + 75 = 229 PASS / 0 FAIL / 0 skipped.
- **executable:** YES; Flutter runner executed successfully.
- **journal ownership:** Tests for overwrite rejection, wrong-id update/complete rejection, correct complete, correlation mismatch.
- **project isolation:** Tests for cross-project non-blocking and project-recreation durability.
- **correlation:** Tests for `session_id` extraction, raw-token absence, same-user/different-session mismatch, same-session match, missing `session_id`, project participation.
- **auth authority:** Tests for blocked fresh sign-in, blocked auth event, blocked restore, corrupt protection, clean-state normality.
- **restart:** Tests for close/reopen unresolved/corrupt, owned completion, Supabase reinitialization reconstruction.
- **full suite:** NO.
- **analyzer:** NO.

## C1 Boundary

- **H1:** Only the minimal recovery authority gate added; server-first logout behavior NOT redesigned.
- **H2:** Stream lifecycle NOT redesigned; only event admission gate added.
- **H3:** Credential exchange state machine NOT redesigned; only admission gate and ownership foundation added.
- **M2:** Profile/region error mapping NOT modified.
- **Part 2:** NOT started.

## Protection

- **migration 00022:** absent.
- **migrations:** unchanged.
- **contract:** `docs/architecture/contracts/V1-R09_OFFLINE_CONNECTIVITY_ERROR_HARDENING_CONTRACT.md` untouched.
- **roadmap:** `docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md` not edited by this correction.
- **pubspec:** unchanged.
- **dependencies:** none added; no `pub get` run.
- **SDK/package source:** read-only; no modifications.
- **SupabaseClient count:** one per `Supabase.initialize` call, as before.

## Git

- **diff check:** PASS; only Git LF-to-CRLF working-copy warnings.
- **staged:** NO.
- **committed:** NO.
- **pushed:** NO.
- **OpenCode_Usage_Report.txt:** untouched (remains untracked).

## Remaining Concerns

None for C1.

## Final Decision

C1 CORRECTIONS COMPLETE — READY FOR INDEPENDENT RECHECK

---

# V1-R09 Part 1 — C1 Final Foundation Correction Cycle

Independent review found 2 HIGH + 2 MEDIUM defects in the previously corrected C1 recovery foundation. This pass did NOT restart C1, C2/C3/C4, or Part 2; only the reported findings were fixed.

## Recovery Mutation Boundary

- **mutable journal exposure:** Removed `coordinator.journal` and the `AuthRecoveryJournal` constructor parameter from `SupabaseService`. The journal implementation is now owned privately by `AuthRecoveryStorageCoordinator`; production code cannot obtain a mutable handle.
- **coordinator authority:** All production recovery operations (`beginOperation`, `updateOwnedOperation`, `completeOwnedOperation`, `markCorrupt`, `readRecoverySnapshot`, `removeRecoverySnapshot`) go through the coordinator's narrow public API.
- **queue:** One `RecoveryAsyncQueue` serializes every state-mutating operation. The guarded SDK adapter uses the same queue instance.
- **owned transaction:** Added `runOwnedRecoveryOperation(expectedOperationId, expectedCorrelation, action)`. Inside a single queued slot it verifies operation ownership and optional correlation, then exposes a constrained `AuthRecoveryTransaction` to the action. Mismatches return `OwnedRecoveryResult.denied` and the storage action never runs.
- **TOCTOU protection:** The action executes while queue ownership is held; it cannot leave the queue and re-enter. The transaction surface only permits `updatePhase`, `complete`, `readRecoverySnapshot`, and `removeRecoverySnapshot`.
- **result:** No bypass path; one serialized ownership boundary.

## Project Identity

- **normalized authority:** `AuthRecoveryStorageCoordinator.projectIdentityFromUrl` uses `Uri.origin` (lowercase scheme + host + effective port) and Base64URL-encodes it for safe Hive box naming.
- **custom domains:** `https://api.alpha.example` and `https://api.beta.example` produce different identities.
- **localhost ports:** `http://localhost:54321` and `http://localhost:54322` produce different identities.
- **malformed URL:** `projectIdentityFromUrl` throws on missing host; `SupabaseService` catches this and fails initialization safely rather than collapsing to a shared namespace.
- **persisted namespace:** Box name is `${AppStorageKeys.authRecoveryJournalBox}_<base64url-origin>`.
- **result:** No collisions; fail-closed on bad URLs.

## Async Account Authority Gate

- **pre-picker check:** `signInWithGoogle()` checks `canAccountAuthorityBeGranted` before awaiting Google credentials.
- **post-picker check:** Re-checks immediately after credentials return and before starting `signInWithIdToken`.
- **pre-exchange:** The existing H3 quarantine check remains; recovery gate now precedes it.
- **post-exchange:** Re-checks after the SDK exchange completes and before returning the session. If recovery became blocked during the exchange, the session is not admitted as application authority.
- **direct result admission:** The direct return path and the auth-event path both consult `SupabaseAuthGateway.canAccountAuthorityBeGranted`, which reads the live `SupabaseService.recoveryState`.
- **auth events:** `initialSession`, `signedIn`, `tokenRefreshed`, `userUpdated`, `mfaChallengeVerified`, and `sessionReplaced` are suppressed while recovery blocks authority; loss events still forward.
- **restore:** `restoreSession()` returns `null` while blocked.
- **bootstrap:** Because identity-bearing admission is blocked, `AuthProvider` cannot start the post-auth claim/bootstrap pipeline.
- **result:** Async race between picker/exchange and recovery blocking is closed.

## Restart / Isolation

- **unresolved reopen:** Write unresolved → close box → recreate coordinator/service → still blocked.
- **corrupt reopen:** Write corrupt → close box → recreate → still blocked.
- **correct completion:** Owned complete → close/reopen → clean startup allowed.
- **wrong-owner completion:** Write entry → close/reopen → attempt complete with wrong id → rejected; original unresolved record remains.
- **project A/B:** `https://api.alpha.example` unresolved does not block `https://api.beta.example`; recreating A still blocks A.
- **localhost isolation:** `:54321` unresolved does not block `:54322`.
- **result:** Recovery state durable across reconstruction; project/port isolation proven.

## Tests

- **exact files:**
  - `test/auth_recovery_foundation_test.dart`
  - `test/supabase_service_test.dart`
  - `test/supabase_auth_gateway_test.dart`
  - `test/auth_provider_test.dart`
  - `test/v1_r08_auth_session_foundation_test.dart`
  - `test/v1_r08_auth_screen_widget_test.dart`
  - `test/v1_r07_staff_operations_flutter_test.dart`
- **exact counts:** 60 + 9 + 21 + 16 + 45 + 14 + 75 = 240 PASS / 0 FAIL / 0 skipped.
- **picker transition:** Test verifies recovery becomes blocked while picker is pending → `signInWithIdToken` count = 0, result = `recoveryBlocked`, provider not authenticated, no bootstrap.
- **exchange transition:** Test verifies recovery becomes blocked while SDK exchange is pending → returned session not admitted, provider not authenticated, no bootstrap, recovery remains blocked, no destructive cleanup in C1.
- **ownership/storage atomicity:** Tests prove `runOwnedRecoveryOperation` denies wrong id, denies mismatched correlation, allows correct owner, and prevents destructive snapshot removal on mismatch.
- **project collision:** Tests for `alpha`/`beta` domains, `localhost:54321`/`54322`, case/default-port normalization, and recreation.
- **restart matrix:** Tests for unresolved/corrupt/wrong-owner/correct-completion across close/reopen and Supabase reinitialization.
- **executable:** YES (`flutter test --no-pub`).
- **full suite:** NO.
- **analyzer:** NO.

## C1 Boundary

- **H1:** Server-first logout workflow NOT implemented; only admission gate.
- **H2:** Stream onDone lifecycle NOT redesigned; only event admission gate.
- **H3:** Timed credential-exchange state machine / stale-session neutralization NOT redesigned; only admission gate and ownership foundation.
- **M2:** Profile region mapping NOT modified.
- **Part 2:** NOT started.

## Protection

- **migration 00022:** absent.
- **migrations:** unchanged.
- **contract:** untouched.
- **roadmap:** untouched by this correction.
- **pubspec:** unchanged.
- **dependencies:** none added; no `pub get`.
- **SDK/package source:** read-only; no modifications.
- **SupabaseClient count:** one per `Supabase.initialize` call.

## Git

- **diff check:** PASS; only LF-to-CRLF working-copy warnings.
- **staged:** NO.
- **committed:** NO.
- **pushed:** NO.
- **OpenCode_Usage_Report.txt:** untouched.

## Remaining Concerns

None for C1.

## Final Decision

C1 FINAL CORRECTIONS COMPLETE — READY FOR ACCEPTANCE RECHECK

---

# V1-R09 Part 1 — C1 Closure Correction Cycle

Independent review found 2 HIGH + 1 MEDIUM defect in the previously corrected C1 recovery foundation. This pass did NOT restart C1, C2/C3/C4, or Part 2; only the reported transaction-lifetime and API-closure findings were fixed.

## Transaction Ownership

- **captured operation:** `_AuthRecoveryTransactionImpl` now captures the validated `operationId` and optional `SessionCorrelation` at creation.
- **captured correlation:** Same immutable capture.
- **current-entry revalidation:** Every transaction method revalidates that the currently persisted record still matches the captured ownership before acting; if not, it rejects without mutation.
- **stale A vs B:** A transaction created for A cannot gain authority over B, even if the current entry changes to B during the callback.
- **result:** Ownership is verified at entry and re-verified at every action.

## Transaction Lifetime

- **active capability:** Each transaction holds an `_active` flag set to true at creation.
- **finally invalidation:** `runOwnedRecoveryOperation` invalidates the transaction in a `finally` block, covering normal return, thrown exceptions, and failed awaited futures.
- **escaped transaction:** After the callback ends, any retained transaction object throws `StateError` on every method and performs no mutation.
- **exception path:** A callback that throws still invalidates the transaction; the shared queue remains usable for later valid operations.
- **nested queue behavior:** The transaction operates inside the already-held queue slot and never re-enters `RecoveryAsyncQueue`, preventing self-deadlock.
- **result:** Transaction capability expires with the queue ownership interval.

## Recovery API Closure

- **mutable journal exposure:** `AuthRecoveryJournal` is now a library-private `_AuthRecoveryJournal` inside the `auth_recovery` library. It is not importable or constructible from outside the recovery coordinator implementation.
- **public snapshot removal:** Removed `coordinator.removeRecoverySnapshot()` and `coordinator.readRecoverySnapshot()` from the public API; snapshot access/removal is now only available through an active owned `AuthRecoveryTransaction`.
- **guarded storage exposure:** Removed `SupabaseService.guardedLocalStorage` public getter. The guarded adapter is retained privately by `AuthRecoveryStorageCoordinator` and exposed only as `sdkLocalStorage` (a `LocalStorage`-typed seam) for the one-time SDK initialization wiring.
- **SDK-facing storage:** The SDK still receives a `LocalStorage` adapter that implements `persistSession`/`removePersistedSession`; this is required by Supabase and is not a second client or second store.
- **application recovery path:** Recovery code must use `runOwnedRecoveryOperation` → active `AuthRecoveryTransaction`. There is no public direct route to unowned destructive storage mutation.
- **result:** No production bypass for unowned destructive recovery access.

## Tests

- **exact files:**
  - `test/auth_recovery_foundation_test.dart`
  - `test/supabase_service_test.dart`
  - `test/supabase_auth_gateway_test.dart`
  - `test/auth_provider_test.dart`
- **exact counts:** 64 + 9 + 21 + 16 = 110 PASS / 0 FAIL / 0 skipped.
- **escaped A → B:** Test begins A, captures transaction in callback, completes A, begins B, then proves the escaped A transaction throws on `updatePhase`, `complete`, `readRecoverySnapshot`, and `removeRecoverySnapshot` without changing B or its snapshot.
- **callback failure:** Test throws inside the callback and proves the escaped transaction is invalid afterwards, while the queue remains usable.
- **wrong operation:** Test proves `runOwnedRecoveryOperation` with a wrong `expectedOperationId` returns `denied` and never executes the action.
- **wrong correlation:** Test proves mismatched `expectedCorrelation` returns `denied` and prevents destructive snapshot removal.
- **active legitimate transaction:** Test proves a valid in-callback transaction can read snapshot, update phase, remove snapshot, and complete the operation.
- **unowned destructive access:** Source/diff verification confirms no public mutable journal constructor, no public coordinator snapshot removal, and no public `SupabaseService.guardedLocalStorage` getter remain in production code.
- **executable:** YES (`flutter test --no-pub`).
- **full suite:** NO.
- **analyzer:** NO.

## Preserved C1 Guarantees

- **async authority gate:** Pre-picker, post-picker, and post-exchange checks remain unchanged.
- **project isolation:** Full normalized-origin project identity remains unchanged.
- **session correlation:** `project + user + session_id` model, with `expiresAt` auxiliary and missing `session_id` fail-closed, remains unchanged.
- **restart:** Close/reopen reconstruction tests remain unchanged.
- **corruption:** Corrupt recovery handling remains unchanged.
- **SDK storage compatibility:** Exact SDK session string delegation through the guarded adapter remains unchanged.
- **result:** All previously accepted C1 behavior preserved.

## C1 Boundary

- **H1:** Server-first logout workflow NOT implemented.
- **H2:** Stream onDone lifecycle NOT redesigned.
- **H3:** Timed credential-exchange state machine / stale-session neutralization NOT redesigned.
- **M2:** Profile region mapping NOT modified.
- **Part 2:** NOT started.

## Protection

- **migration 00022:** absent.
- **migrations:** unchanged.
- **contract:** untouched.
- **roadmap:** untouched.
- **pubspec:** unchanged.
- **dependencies:** none added; no `pub get`.
- **SDK/package source:** read-only; no modifications.
- **SupabaseClient count:** one per `Supabase.initialize` call.

## Git

- **diff check:** PASS; only LF-to-CRLF working-copy warnings.
- **staged:** NO.
- **committed:** NO.
- **pushed:** NO.
- **OpenCode_Usage_Report.txt:** untouched.

## Remaining Concerns

None for C1.

## Final Decision

C1 CLOSURE CORRECTIONS COMPLETE — READY FOR FINAL ACCEPTANCE

---

# C1 Final Test Evidence Closure

Independent review found the escaped-A→B regression test lacked explicit proof
of unchanged B persisted snapshot and zero destructive delegate calls. Test-only
strengthening appended; no production source change.

## Changed Files

- production:
- tests:
  - `test/auth_recovery_foundation_test.dart` (strengthened `escaped transaction cannot mutate later operation B` only)
- docs:
  - `docs/architecture/reports/V1-R09_PART1_INFRASTRUCTURE_IMPLEMENTATION_REPORT.md` (this closure appended)

## Escaped A → B

- B journal initialized: YES — B began before escaped A attempts.
- B snapshot initialized: YES — `{"access_token":"b-abc","refresh_token":"b-ref"}` persisted through `coordinator.sdkLocalStorage.persistSession(...)` seam; exact string captured.
- escaped update: rejected — `StateError`.
- escaped complete: rejected — `StateError`.
- escaped remove: rejected — `StateError`.
- B journal unchanged: YES — `operationId` still B and `phase` still `active` after all escaped attempts.
- B snapshot unchanged: YES — read back through the authorized current B transaction, exact string equality with original B snapshot.
- initial removeCalls: 0.
- final removeCalls: 0 (after all escaped attempts; before the legitimate-B demonstration).
- result: escaped A gained no authority over B; no unowned destructive call reached the delegate.
- legitimate B works: YES — a valid B transaction then removed B's snapshot (`removeCalls` 0 → 1, snapshot `null`).

## Focused Test

- command: `flutter test --no-pub test/auth_recovery_foundation_test.dart`
- passed: 64
- failed: 0
- skipped: 0

## Protection

- production source modified: NO
- diff check: PASS (only LF-to-CRLF working-copy warnings)
- staged: NO
- committed: NO
- pushed: NO
- OpenCode_Usage_Report.txt: untouched

## Final Decision

C1 TEST EVIDENCE COMPLETE — READY FOR FINAL MICRO-ACCEPTANCE

---

# V1-R09 Part 1 — C2 Remote-First Authoritative Sign-Out

Slice C2 implements the H1 authoritative remote-first sign-out (journal-before-remote),
H2 observation-loss UX, and M1 bounded Google cleanup on top of the accepted C1 recovery
boundary. The UI surfaces typed/blocked states; focused production-path tests cover the
full flow against a controlled GoTrue HTTP server.

## Production Changes

- `lib/features/auth/data/supabase_auth_gateway.dart`:
  - `signOut()`: journal-before-remote — `beginOperation(remotePending)` is durably
    persisted BEFORE the remote revocation starts; on success the journal moves to
    `cleanupRequired` and owned local cleanup settles the recovery snapshot inside an
    owned transaction; on known remote failure the journal closes and `signOutFailed`
    is surfaced while identity is retained (fail-closed).
  - Late-completion watchers are armed ONLY after the application deadline elapses
    (post-timeout/infra branches), so in-time resolutions are settled by the awaited
    continuation and can never be pre-empted by the watcher's first-microtask claim.
  - `_performOwnedLocalCleanup()`: bounded local cleanup OUTSIDE the recovery queue;
    A-vs-B correlation re-check antes every destructive removal; a stalled cleanup
    returns `stalled`, arms its late watcher, and surfaces `logoutCleanupRequired`.
  - `_isOwnedCleanupActive` suppresses the SDK `signedOut` BYPRODUCT of the owned
    cleanup, so the provider never misreads a successful neutralization as an external
    session loss.
  - `_handleCredentialExchangeCompletion` gates stale-session neutralization on
    `_credentialExchangeTimedOut` only — an in-time exchange whose `.then` watcher
    races the awaited continuation must NOT neutralize a healthy sign-in (H3 fix).
  - New interface members `isAuthObservationAvailable`, `isLogoutCleanupBlocked`,
    `retryAuthCleanup()`; gateway `isLogoutCleanupBlocked` reflects
    `remotePending`/`cleanupRequired`/`blockedCleanupFailure` journal states.
- `lib/features/auth/presentation/providers/auth_provider.dart`:
  - New `AuthStatus.cleanupRecovery` with `retryAuthCleanup` seam; signed-in/restore/
    clearError are inert while authority is blocked; `logoutCleanupCleared` also ends
    an authenticated+`retryableNetwork` state (delayed revoke eventually succeeded) as
    a clean guest.
- `lib/features/auth/presentation/auth_screen.dart`, `lib/features/user_area/presentation/user_area_screen.dart`,
  `lib/localization/en.dart`, `lib/localization/ar.dart`:
  - Branch order: ownership conflict → post-auth → `isCleanupBlocked`
    (`_CleanupRequiredNotice` + retry) → `isAuthObservationUnavailable`
    (`_RestartRequiredNotice`) → available → sign-in; user-area header shows the
    cleanup retry / restart notices; sign-out snackbar also covers `retryableNetwork`.
  - Localization keys added: `authLogoutCleanupTitle`, `authLogoutCleanupMessage`,
    `retryCleanup`, `authRestartRequired` (en + ar).
- Router: NO branch needed — protected-route redirects funnel to `/auth`, whose
  AuthScreen already displays the cleanup/restart notices; `_ProfileEditDispatch`
  fails closed to a safe surface. Decision recorded.

## Test Changes

- `test/supabase_auth_gateway_test.dart`: surgery — removed the now-inapplicable
  injected-init sign-out tests/helpers; added H2 `unexpected onDone latches
  observation off and never re-arms`.
- `test/v1_r09_c2_sign_out_recovery_test.dart` (NEW): production path only — real
  `Supabase.initialize` vs a controlled GoTrue HTTP server, Hive temp dir +
  SharedPreferences mock, JWT `session_id` tokens, guarded local storage. 7 tests:
  happy path (`logoutCalls==2`, scope local, guest, `googleSignOutCalls==1`), known
  remote failure (journal closed, identity kept), timeout (`remotePending`,
  authenticated, `retryableNetwork`), late success (clean guest), late failure
  (journal closed, identity kept), stalled cleanup (`cleanupRecovery`, blocked
  sanitization, retry clears gate with no extra remote call), A-vs-B (foreign session
  B → `blockedCleanupFailure`, B + remnant retained).
- `test/fakes/fake_auth_gateway.dart`, `test/v1_r08_auth_session_foundation_test.dart`,
  `test/v1_r07_staff_operations_flutter_test.dart`: fakes now declare the three new
  interface members explicitly (`implements` does not inherit interface default bodies).

## Defects Found and Fixed During Bring-Up

1. H3 quarantine raced healthy sign-ins: the late-completion watcher (registered
   before the await) ran `_neutralizeStaleSession` on an in-time exchange, revoking a
   just-created session. Fixed by gating neutralization on `_credentialExchangeTimedOut`.
2. Sign-out settler race: pre-await watcher claimed the handled latch, so the on-time
   path returned early — a known remote failure (500) surfaced as NO error (silent
   success) and clean sign-outs could end `sessionLost`. Fixed by arming late watchers
   post-deadline only and suppressing the cleanup's byproduct `signedOut`.

## Focused Test

- command: `flutter test --no-pub test/supabase_auth_gateway_test.dart
  test/auth_provider_test.dart test/auth_recovery_foundation_test.dart
  test/v1_r08_auth_session_foundation_test.dart test/v1_r09_c2_sign_out_recovery_test.dart`
- result: 148 PASS / 0 FAIL / 0 skipped across the five focused files.
- C2 slice alone: `flutter test --no-pub test/v1_r09_c2_sign_out_recovery_test.dart`
  → 7 PASS / 0 FAIL / 0 skipped.
- executable: YES.
- full suite: NO.
- analyzer: NO.

## C2 Boundary

- **C3/H3/C4/M2:** NOT started.
- **Part 2:** NOT started.

## Protection

- **migration 00022:** absent.
- **migrations:** unchanged.
- **contract:** untouched.
- **roadmap:** untouched by this correction.
- **pubspec:** unchanged.
- **dependencies:** none added; no `pub get`.
- **SDK/package source:** read-only; no modifications.
- **SupabaseClient count:** one per `Supabase.initialize` call.

## Git

- **diff check:** run after this append.
- **staged:** NO.
- **committed:** NO.
- **pushed:** NO.
- **OpenCode_Usage_Report.txt:** untouched.

## Remaining Concerns

None for C2.

## Final Decision

C2 IMPLEMENTATION COMPLETE — READY FOR ACCEPTANCE REVIEW

---

# V1-R09 Part 1 — C2 Critical Correction Cycle

Independent review found 4 HIGH + 2 MEDIUM defects in the previously accepted C2
remote-first authoritative sign-out implementation. This pass did NOT restart
C1, C2, C3/C4, or Part 2; only the reported findings were fixed.

## Immediate Authority Loss (HIGH-1)

- `_completeAuthoritativeSignOut()` now persists `cleanupRequired`, then
  publishes `logoutCleanupRequired` IMMEDIATELY, before any local SDK cleanup
  or Google cleanup.
- The provider removes application authority and resets account-bound state
  exactly once at this boundary.
- Local SDK cleanup and Google cleanup run only after the authority-loss event.
- Result: no authenticated window remains after remote server success is known,
  including in-time success, late success, and retry success.

## remotePending Recovery (HIGH-2 / HIGH-5 / HIGH-6 / HIGH-7)

- `isLogoutCleanupBlocked` no longer treats `remotePending` as cleanup-ready.
- `retryAuthCleanup()` is now phase-aware:
  - `remotePending` + exact current-session match → retries remote revocation
    only, then applies normal C2 success/failure semantics.
  - `remotePending` + missing/mismatched session → remains blocked, no local
    cleanup, no destructive guess.
  - `cleanupRequired` / `blockedCleanupFailure` → owned local cleanup only.
- No phase silently jumps to another phase.
- Access tokens are captured ephemerally and never persisted.

## Owned SDK Cleanup (HIGH-3)

- Added `AuthRecoveryTransaction.runOwnedSdkLocalCleanup()` — a narrow owned
  capability used only inside `runOwnedRecoveryOperation(...)`.
- `_GuardedSupabaseLocalStorage.removePersistedSession()` recognizes the active
  owned-transaction capability and performs the delegate removal inline,
  preventing recovery-queue self-deadlock.
- The capability is cleared in a finally block; an escaped or stale transaction
  cannot invoke it.
- `_performOwnedLocalCleanup()` now runs entirely inside the owned recovery
  transaction with correlation revalidation before destructive work.

## signedOut Suppression (HIGH-4)

- Replaced phase-wide `_isOwnedCleanupActive` with a transient one-shot
  `_cleanupEventSuppression` capability.
- Active only immediately around the specific owned
  `client.auth.signOut(scope: local)` call; consumed once; cleared in finally.
- Independent `signedOut`, `userRemoved`, and later stream events are NOT
  suppressed merely because the journal phase is cleanup-related.
- The provider ignores `signedOut`/`sessionLost` only when already in
  `cleanupRecovery` to avoid a duplicate reset, while genuine events remain
  observable through the gateway stream.

## Remote Failure Finalization (MEDIUM-1)

- `_settleRemoteOnTime()` now checks the result of
  `completeOwnedOperation()`.
- If journal finalization fails after a known remote failure, it surfaces
  `AuthGatewayException(AuthError.unexpected)`, preserves valid authenticated
  authority, and leaves recovery fail-closed.
- Raw error text is never surfaced.

## Remote Response Semantics (MEDIUM-2)

- `_performAdminSignOut()` treats 2xx and terminal `401`/`403`/`404` as remote
  success.
- `400`/`422`/`429`/`5xx`/unknown/malformed failures are treated as ordinary
  non-success; no cleanup runs.
- No status codes are inferred from message strings.
- Added focused tests for every listed status.

## M1 Google Cleanup Ordering

- Google cleanup remains the very last best-effort, bounded, non-authoritative
  surface and runs only after remote success, authority removal, and local SDK
  cleanup.

## H2 Preservation

- Recoverable stream errors keep the subscription alive; later events remain
  observable.
- Added the missing `tokenRefreshed` after stream-error test.
- No H2 redesign.

## H3 Carry-Forward

- The existing credential-exchange timeout guard is preserved unchanged and
  marked `UNACCEPTED C3 CARRY-FORWARD`.
- No H3 acceptance or expansion.

## Tests

- `test/v1_r09_c2_sign_out_recovery_test.dart`: 23 tests (was 7).
- `test/supabase_auth_gateway_test.dart`: 17 tests (was 16; +1 H2 refresh).
- `test/auth_recovery_foundation_test.dart`: 69 tests (was 64; +5 owned SDK
  cleanup tests).
- `test/auth_provider_test.dart`: 16 tests (regression).
- `test/v1_r08_auth_session_foundation_test.dart`: 45 tests (regression).
- Command:
  `flutter test --no-pub test/supabase_auth_gateway_test.dart test/auth_provider_test.dart test/auth_recovery_foundation_test.dart test/v1_r08_auth_session_foundation_test.dart test/v1_r09_c2_sign_out_recovery_test.dart`
- Result: 170 PASS / 0 FAIL / 0 skipped.
- Full suite: NO.
- Analyzer: NO.

## C1 Preservation

- Project-scoped recovery journal, normalized authority identity,
  project+user+session_id correlation, missing session_id fail-closed,
  one `AuthRecoveryStorageCoordinator`, one `RecoveryAsyncQueue`, owned
  transaction lifetime, guarded SDK `LocalStorage`, startup/pre-picker/
  post-picker/post-exchange/authority/restore gates, and corrupt/unresolved
  fail-closed behavior are all preserved.
- The owned SDK cleanup capability is a narrow C1 extension that keeps the
  ownership invariant intact.

## Boundary

- C3/H3: not accepted or expanded.
- C4/M2: not started.
- Part 2: not started.
- Migration 00022: absent.
- Migrations: unchanged.
- Frozen contract: untouched.
- Roadmap controls: untouched.
- pubspec: unchanged.
- Dependencies: unchanged.
- SDK/package source: untouched.
- One `SupabaseClient`, one `AuthProvider`.
- `OpenCode_Usage_Report.txt`: untouched.

## Git

- diff check: run after this append.
- staged: NO.
- committed: NO.
- pushed: NO.

## Remaining Concerns

None for C2.

## Final Decision

C2 CORRECTIONS COMPLETE — READY FOR INDEPENDENT RECHECK

---

# V1-R09 Part 1 — C2 Astra-Approved Surgical Correction Evidence

Date: 2026-09-14. Scope: the final C2 correction authorized by the architect.
This append supersedes the preceding C2 suppression/restart/cleanup claims;
earlier review and implementation history is intentionally retained.

## Snapshot ownership and conditional deletion

- Recovery privately decodes the SDK snapshot and validates the public installed
  `Session.fromJson` representation. Empty strings, invalid JSON, wrong types,
  missing identity, missing `session_id`, and insufficient correlation block
  cleanup without modifying the stored bytes.
- The coordinator's configured project identity is authoritative. The recorded
  project must match it, and project + user + `session_id` identify the target.
  `expiresAt` is not destructive identity; snapshot fields cannot select a
  different project or remote authority.
- Matrix A (current A / persisted A): invoke the actual public SDK local clear
  under ownership; track its persistence callback and verify settled absence.
- Matrix B (null / persisted A): zero SDK sign-out calls; conditional owned
  deletion only, followed by absence verification and checked journal closure.
- Matrix C (null / persisted B): zero SDK clear and zero delegate removal;
  preserve the exact B bytes and protected A operation; blocked cleanup.
- Matrix D (current B / persisted B): preserve the identical installed session
  and stored snapshot; no SDK clear or delegate deletion for A.
- Matrix E (current A / absent): clear matching installed A, without deleting
  absent storage. Revalidate later persistence; a B snapshot appearing before
  settlement is preserved and keeps cleanup blocked.
- Matrix F (null / malformed): preserve exact bytes; no SDK clear or removal.
- Both absent: verify both, close the owned journal, then permit clean guest;
  zero SDK clear and zero delegate removal.
- The capability contains only operation ID, correlation, and lifetime validity.
  The guarded adapter re-reads the actual snapshot at the deletion boundary.
  An earlier matching preflight never permits a later B/malformed deletion.
- There is still one coordinator, guarded SDK adapter, and recovery queue.
  Owned deletion runs inline; outside-capability SDK calls use the shared queue.
  Calls requested while recovery is blocked cannot become unrestricted later.
- SDK removal work initiated under ownership is observed and drained before the
  original queue slot exits. Permission is invalidated before draining; an
  outstanding read cannot retain deletion permission after its lifetime ends.
  Already-started delegate writes must settle before later queued persistence.
- Verification obtains a fresh queue slot, after queued SDK persistence writes,
  and checks absence, current-session state, ownership, and journal completion.
  A completed SDK sign-out Future alone is never evidence of clean persistence.

## Definitive events and provider idempotence

- Removed all C2 cleanup-event suppression fields/helpers/filtering. No one-shot,
  pending-Future, sessionless, or first-event replacement suppressor was added.
- SDK `signedOut`, `userDeleted` (mapped to session loss), and definitive loss
  events remain observable through the gateway even while cleanup is stalled.
- Remote authoritative success publishes authority loss before local settlement.
  `cleanupRecovery` handles repeated definitive events idempotently: no new
  account reset, no journal completion, and no assumption of clean persistence.
- Only verified owned cleanup transitions recovery to clean guest. Non-secret
  operation IDs on custom recovery notifications reject stale completion.
  No operation ownership is guessed for sessionless SDK events.
- Tests assert exact ordered event lists before/during/after real SDK cleanup,
  independent signed-out events, user removal during recovery, and B collision.
- Both in-time and late remote-success tests hold local cleanup independently.
  Before local completion: provider recovery, application session null, private
  authority and sign-in blocked, journal cleanup-required, old generation no
  longer current, and reset count exactly 1. After completion it remains 1.
  Reconstructed recovery never admitted an account, so its reset count is 0.

## Real remotePending restart and recovery UI

- Tests close/reopen the actual coordinator from the persisted journal and
  initialize real Supabase with the same guarded storage boundary. No credential
  exchange installs A in reconstructed recovery; SDK currentSession stays null.
- Startup enters explicit recovery, not ordinary unrestricted guest. Arabic and
  English auth UI expose the phase-aware retry, disable concurrent taps, and
  replace retry with restart instructions when a restart is required. The actual
  profile-edit route reaches this recovery surface; protected-route return
  validation remains intact. The User-area recovery action uses the same provider.
- Typed status/results distinguish remote-pending, local-cleanup, blocked storage,
  clean guest, and restart required. A separate retained-session result describes
  an ordinary failed live logout. The legacy boolean seam remains compatibility
  only; true means verified clean guest, never mere journal closure.
- Inside an active owned callback only, persisted A is privately parsed,
  validated, and used ephemerally with the SAME client's public
  `auth.admin.signOut(accessToken, scope: SignOutScope.local)`.
  No parsed Session is installed, admitted, or published; no token enters the
  journal, provider, logs, or any additional storage.
- Retry remote success persists cleanup-required, removes application authority,
  performs the matrix, verifies storage, checks finalization, then permits guest.
- Ordinary failed retry after restart preserves A exactly and checks journal
  closure. Success of that closure yields a process-local restart-required latch,
  not immediate authority and not H2 observation loss. A new startup restores A
  only through the normal SDK + C1/R08 admission path; this is executable-tested.
- Retry timeout releases visible busy while retaining one observed raw remote
  operation. No overlapping revoke, local clear, or fresh auth occurs. Late
  success/failure obtains fresh ownership; no escaped transaction is reused.
- Missing, B, malformed, and insufficient snapshots cannot authorize a remote
  token use or deletion. They return finite blocked results.
- Deterministically closing the actual journal after a held remote request tests
  ordinary and late finalization/write failure. The result is typed storage
  failure; snapshot preserved, no SDK/Google cleanup, and no clear-error, restore,
  or sign-in bypass. Live ordinary failure retains its already-admitted identity.

## Observed asynchronous cleanup and M1

- One owner wraps raw SDK local cleanup immediately and normalizes synchronous
  invocation exceptions and asynchronous failures into a non-throwing result.
  Application deadline does not mean cancellation or success. Late observers
  retain operation/result handles, not an escaped destructive transaction.
- A retry cannot launch competing SDK cleanup while the raw call or owned storage
  work remains unresolved. Later verification waits for the original transaction
  to exit before acquiring a fresh slot: no same-queue self-deadlock.
- Tests hold the real SDK local-scope HTTP request past its deadline, then fail
  it. The failure is observed once; captured unhandled zone errors are zero;
  duplicate SDK call/remote settlement is absent; late deletion permission cannot
  remove B; provider remains safely blocked.
- A real SDK persistence delegate is independently delayed. SDK completion does
  not close the journal or release account authority before that delegate settles.
  Releasing it produces verified guest once, with reset count still 1.
- A synchronous local invocation failure leaves recovery and a retry available;
  a later successful local attempt does not repeat the account reset.
- M1 remains last, best-effort and non-authoritative after remote success and a
  local cleanup attempt. Google initialization and sign-out are bounded, and
  timeout/late errors are consumed. Tests hold/fail each independently without
  delaying canonical logout, restoring authority, or leaking zone errors.

## Focused executable verification

Command executed (no full suite, analyzer, or pub get):

```powershell
flutter test --no-pub test/supabase_auth_gateway_test.dart test/auth_provider_test.dart test/auth_recovery_foundation_test.dart test/v1_r08_auth_session_foundation_test.dart test/v1_r09_c2_sign_out_recovery_test.dart
```

The final run used the JSON reporter to count non-hidden test completions.

| Exact focused file | PASS | FAIL | SKIPPED |
| --- | ---: | ---: | ---: |
| test/supabase_auth_gateway_test.dart | 17 | 0 | 0 |
| test/auth_provider_test.dart | 27 | 0 | 0 |
| test/auth_recovery_foundation_test.dart | 74 | 0 | 0 |
| test/v1_r08_auth_session_foundation_test.dart | 45 | 0 | 0 |
| test/v1_r09_c2_sign_out_recovery_test.dart | 49 | 0 | 0 |
| Total | 212 | 0 | 0 |

- Real installed Supabase/GoTrue, controlled loopback HTTP, actual event emission,
  actual coordinator/journal reconstruction, and guarded storage are exercised.
  The local-call counting seam delegates to real SDK sign-out except for the
  explicit synchronous-invocation-failure test.
- Retained C1 ownership, escaped A-to-B exact-snapshot/remove-count proof, wrong
  owner/correlation, project isolation, queue, and authority-gate regressions.
  Successful C2 capability fixtures now use valid correlated SDK snapshots.
  The old restore assertion expecting guest under sign-out recovery now expects
  explicit blocked recovery; its no-authority invariant is unchanged.
- Added precise deletion-boundary, expired-capability, duplicate-notification,
  localized retry/busy/restart, real route reachability, and stale completion proof.
- Existing H2 tests cover error continuity, later refresh/definitive events,
  unexpected onDone fail-closed/no re-arm, and one subscription. H2 subscription
  and observation-loss methods are unchanged; suppression removal strengthens
  delivery. The R08 auth-session regression file remains unchanged and passes.
- Intermediate focused runs exposed the new adapter's recursive extension
  dispatch and test-fixture/setup/timing errors. Those were corrected; the counts
  above are the completed final run, not a sum of earlier attempts.

## Change boundary and preservation

Compared SHA-256 hashes of all 1,112 tracked/untracked non-ignored files with the
snapshot captured at the start of this correction. Before this report append,
only the following 14 allowed files differed; no baseline file was removed:

- lib/features/auth/data/supabase_auth_gateway.dart
- lib/features/auth/data/auth_recovery_storage_coordinator.dart
- lib/features/auth/data/guarded_supabase_local_storage.dart
- lib/features/auth/domain/repositories/auth_gateway.dart
- lib/features/auth/domain/entities/auth_event.dart
- lib/features/auth/presentation/providers/auth_provider.dart
- lib/features/auth/presentation/auth_screen.dart
- lib/features/user_area/presentation/user_area_screen.dart
- lib/localization/ar.dart
- lib/localization/en.dart
- lib/routes/app_router.dart
- test/auth_provider_test.dart
- test/auth_recovery_foundation_test.dart
- test/v1_r09_c2_sign_out_recovery_test.dart

This append is the sole additional changed file. The worktree already contained
earlier R09 implementation changes, including a modified roadmap and an untracked
contract/report/usage file; those pre-existing statuses are not new C2 edits.

- C1 remains accepted: one project-scoped journal/coordinator/queue/adapter, exact
  transaction lifetime, sufficient correlation, and fail-closed admission remain.
- C3/H3: NOT expanded or accepted. The credential-exchange and quarantine method
  block is textually unchanged from the pre-correction source. Its status remains
  UNACCEPTED C3 CARRY-FORWARD.
- C4/M2 and Part 2: not started or modified by this correction.
- Migration 00022: absent; migrations 00001–00021 unchanged from task baseline.
- Frozen contract, roadmap controls, pubspec and dependency files: unchanged
  from task baseline. No package upgrade, private SDK API, SDK/package source
  patch, SDK/cache repair, extra production SupabaseClient/AuthProvider, privileged
  credential, or token/session store was introduced.
- OpenCode_Usage_Report.txt: exact baseline hash retained; not edited.
- Git: diff check passed before this append; final diff/status are checked again
  after it. Index empty; HEAD remains e80fab8883a3631e58d1cc9bb83846c7f981d0fa.
  No staging, commit, or push was performed.

## Remaining concerns

None identified for the authorized C2 correction. Independent acceptance is still
required; this evidence does not accept C3/H3 or authorize another slice.

## Final decision

C2 SURGICAL CORRECTION COMPLETE — READY FOR FINAL INDEPENDENT ACCEPTANCE

---

# V1-R09 Part 1 — C2 Final Destructive-Boundary Closure

Date: 2026-09-14. Final closure of the remaining independent-review HIGH finding.
This append supersedes the prior claim that every recovery removal surface was
conditional. Prior implementation and review history is preserved.

## Unsafe API and caller audit

- Removed `AuthRecoveryTransaction.removeRecoverySnapshot()` from both the
  public transaction contract and its implementation. No alias, compatibility
  wrapper, or replacement generic removal method remains.
- Production had zero callers of the removed method. Its six test call sites
  covered wrong-owner/positive-owner behavior, escaped A and authorized B,
  ownership lost within a transaction, and successful transaction mutations.
  Those assertions now use the existing conditional method and check its result.
- Positive deletion fixtures now contain valid serialized SDK sessions and use
  the coordinator's actual configured project identity. Malformed placeholder
  data is no longer expected to be destructively removable by an owned operation.
- A final search across production and tests finds no occurrence of the removed
  method. The historical reports retain its name as evidence of the correction.

## Final destructive boundary

- `removeMatchingRecoverySnapshot()` is the remaining transaction-level snapshot
  deletion method. Its expected correlation and operation ID come from the
  captured active transaction; callers cannot replace them at deletion time.
- Missing captured correlation returns false. Active journal ownership by itself
  cannot authorize deletion. The owned SDK callback capability also requires
  sufficient captured correlation and the configured project identity.
- Both recovery deletion paths converge on `_removeMatchingSnapshot`: verify
  current ownership, read the CURRENT stored bytes, recheck ownership after the
  read, parse/validate, compare configured project + user + `session_id`, and only
  then invoke the delegate. Expiry remains excluded from destructive identity.
- B, malformed JSON, empty malformed data, wrong types, or insufficient session
  identity do not cause removal. Verified absence retains the existing behavior.
- Audited transaction/coordinator APIs, guarded LocalStorage, SupabaseService,
  and gateway recovery helpers. The gateway already uses the conditional path;
  no production caller migration was necessary. SupabaseService exposes no raw
  delegate or separate destructive method.
- The unchanged normal SDK LocalStorage removal path is queued and refuses
  removal if recovery was blocked when requested or is blocked when executed.
  During owned SDK cleanup it instead uses the private conditional capability.
  Normal SDK behavior outside recovery was not redesigned.

## Runtime regression evidence

- Record A / active A / valid B is exercised through both remaining transaction
  surfaces: direct conditional removal and owned SDK-callback removal through the
  actual guarded adapter. B's exact serialized bytes remain unchanged; delegate
  removeCalls remains 0; A's journal operation, phase, and correlation remain.
- Both different-user B and same-user/different-session B are covered. Negative
  cases also include malformed JSON, empty bytes, missing session identity, and
  wrong token types. A seventh new test proves that an owned transaction without
  captured correlation cannot delete even a valid A snapshot.
- The existing real-SDK matrix C test now explicitly attempts both transaction
  removal surfaces before invoking gateway retry. It asserts currentSession null,
  SDK sign-out calls 0, remote logout calls 0, delegate removals 0, exact B bytes,
  and unchanged A journal ownership/phase before the normal blocked retry result.
- The A-to-A positive path inspects a matching real session, invokes only the
  conditional removal method, checks true, and asserts exactly one delegate
  removal and absent snapshot.
- The escaped-A-to-B regression still proves exact B snapshot preservation,
  initial/final removeCalls 0, unchanged B journal, and authorized B readback.
  Expired A is rejected through both remaining destructive transaction surfaces;
  subsequent authorized B conditional cleanup succeeds exactly once.
- Ownership-loss tests now use valid correlated snapshots so their rejection is
  attributable to lost ownership rather than incidental malformed fixtures.

## Executable verification

Executed only the two directly affected files (JSON reporter used for counts):

```powershell
flutter test --no-pub test/auth_recovery_foundation_test.dart test/v1_r09_c2_sign_out_recovery_test.dart
```

| Exact focused file | PASS | FAIL | SKIPPED |
| --- | ---: | ---: | ---: |
| test/auth_recovery_foundation_test.dart | 81 | 0 | 0 |
| test/v1_r09_c2_sign_out_recovery_test.dart | 49 | 0 | 0 |
| Total | 130 | 0 | 0 |

Full suite: NO. Analyzer: NO. Pub get: NO. No additional test file was needed.

## Preservation and protection

Only these files changed relative to the 1,112-file starting hash inventory:

- lib/features/auth/data/auth_recovery_storage_coordinator.dart
- test/auth_recovery_foundation_test.dart
- test/v1_r09_c2_sign_out_recovery_test.dart
- docs/architecture/reports/V1-R09_PART1_INFRASTRUCTURE_IMPLEMENTATION_REPORT.md
  (this append only)

The sole production change is removal of the unsafe declaration/implementation
and clarification of the existing conditional method's documentation. The
validator, adapter, journal, queue, gateway, provider, UI, and their prior C2
behavior remain unchanged. Focused C2 tests retain matrix A–F/both-absent,
delegate/journal ordering, event delivery, reset timing, restart recovery,
single-flight timeout, raw Future ownership, and bounded Google cleanup coverage.

- C1: transaction lifetime, one coordinator/queue, project isolation, correlation,
  and authority gates preserved; destructive ownership invariant strengthened.
- C3/H3: source unchanged; UNACCEPTED C3 CARRY-FORWARD.
- C4/M2 and Part 2: not started or modified by this closure.
- Migration 00022 absent; migrations, contract, roadmap controls, pubspec and
  dependency files unchanged from the starting worktree.
- No SDK/package edits, privileged credential, extra production SupabaseClient,
  AuthProvider, token store, or recovery queue introduced.
- OpenCode_Usage_Report.txt retains its starting hash and was not edited.
- Pre-existing dirty worktree changes are preserved. No staging, commit or push.
  HEAD remains e80fab8883a3631e58d1cc9bb83846c7f981d0fa. Diff check passed before
  this append; final diff/status and append integrity are verified afterward.

## Remaining concerns

None within the authorized destructive-boundary closure.

## Final decision

C2 DESTRUCTIVE BOUNDARY CLOSED — READY FOR FINAL MICRO-ACCEPTANCE

---

# V1-R09 Part 1 — C3 Contract-Addendum Correction Report

Date: 2026-09-14. Scope: C3/H3 correction plus architect-authorized C3 Addendum A.
This is implementation evidence, not independent acceptance or authorization to
begin C4 or Part 2. Previous report history is preserved.

## Contract Addendum

- recorded: C3 CONTRACT ADDENDUM A appended before implementation; effective
  identifier V1-R09-CONTRACT-v1 + C3-ADDENDUM-A.
- exact scope: explicit quarantined device sign-in reset on the existing
  credentialExchange / blockedUnattributed recovery operation only.
- remote effects: NONE from reset; no signOut/admin.signOut, global logout,
  account deletion, or other-device revocation.
- local effects: exact unchanged SDK auth-persistence bytes only; no profile,
  project, business, or other Civilpedia local/cloud data removal.
- result: implemented. The original 19,582-byte contract prefix has SHA-256
  67376239DB347DA49386AD10DCD00B43E1886C3B901BF644029D6FDEC12AF9FA,
  identical to the starting worktree.

## Durable Handoff

- same operation: operationId, operationType, and createdAt retained through
  active -> timedOutPending -> neutralizing -> cleanupRequired -> completion.
- correlation upgrade: owned placeholder-to-exact SDK correlation and phase
  replace the same journal key in one acknowledged write. No complete/begin
  handoff. Exact A cannot be reassigned to B. Identical repeat is idempotent.
- crash safety: real journal reconstruction covers SDK-persisted A before
  handling, failed upgrade, exact A before revoke, durable remote success before
  local cleanup, and an in-progress persistence delegate.
- result: PASS in focused implementation tests.

## Raw / Settlement Separation

- raw success: actual SDK response is normalized separately from settlement.
- raw failure: fresh ownership verifies null SDK memory and absent persistence,
  rechecking memory after awaited reads and requiring successful completion.
- processing failure: never reclassified as raw failure; recovery stays blocked.
  Validation, journal, processing, remote, local, unattributed, reset failure,
  and restart-required reasons are distinct typed settlement values.
- result: PASS.

## In-Time Commit

- pre-validation: COMMITTING ownership, generation, exact SDK correlation,
  observation health, and owned journal are checked before completion.
- post-validation: lifetime, ownership, current SDK identity and clean recovery
  are checked again after completion. Lost admission remains blocked; a missing
  completed record is durably marked corrupt rather than granting authority.
- commit receipt: single-use process-local non-secret receipt binds gateway,
  operation, generation, exact correlation and the returned candidate. Provider
  checks its epoch and consumes synchronously immediately before installation.
- SDK correlation: derived from actual SDK result; a pre-exchange placeholder
  never fabricates session_id. SDK loss/replacement at commit checkpoints and
  replacement after gateway return reject admission.
- result: PASS.

## Recovery / Generation

- ACTIVE: busy, without recovery storage inspection/completion/cleanup.
- COMMITTING: busy; normal account-bearing event admission remains gated.
- timeout CAS: only the current ACTIVE operation can become timedOutPending.
- g vs g+1: all non-idle states block a new exchange; terminal raw mutation,
  successful durable settlement and clean recovery precede a fresh attempt.
  Disposed/obsolete callbacks perform no recovery mutation.
- result: PASS.

## A-vs-B

- installed B: real SDK-installed B is preserved at A cleanup/commit boundaries.
- persisted B: exact bytes preserved, including null-memory restart and mixed
  A/B preflight cases.
- remote effects: no B revoke; collision preflight does not launch logout.
- local effects: zero SDK signOut/delegate removal at a B collision boundary.
- result: PASS.

## Bounded Neutralization

- remote: same client's public auth.admin.signOut(token, scope: local), observed
  immediately, with the existing 20-second mutation deadline.
- local: shared accepted C2 bounded/observed cleanup, not a parallel C3 variant.
- queue: token capture is owned; remote HTTP wait is outside the recovery queue.
  Already-started delegate writes retain serialization until they drain.
- late settlement: fresh ownership; no second raw revoke/local cleanup while
  pending; durable remote-success evidence is retained before local cleanup.
  Timeout bounds visible waiting and does not claim cancellation.
- result: PASS.

## Unattributed Restart

- production placeholder: project/non-secret pending metadata only, no invented
  Supabase session_id.
- blocked state: insufficient/unknown/malformed restored data becomes durable
  blockedUnattributed without guessing identity or destructive recovery.
- admission: private authority and fresh sign-in blocked; public/local features
  remain available.
- result: PASS.

## Explicit Device Sign-In Reset

- availability: typed gateway/provider action only for the owned durable C3
  blockedUnattributed operation; other operation types/phases reject it.
- exact-byte deletion: initial read plus immediate pre-removal read in the one
  recovery queue; only unchanged bytes are removed.
- SDK signOut calls: ZERO for reset.
- remote revoke calls: ZERO for reset.
- changed-snapshot race: X -> B rejects deletion and preserves exact B bytes.
- restart-required: same operation becomes localResetAppliedRestartRequired;
  unknown SDK memory remains untouched and current-process authority blocked.
- next-start verification: normal initialization plus null SDK memory and
  absent persistence, with acknowledged journal completion, permits guest.
  Unexpected data or completion failure stays blocked.
- result: PASS.

## Provider / UX

- timeout: immediate cleanupRecovery, finite sign-in busy state; no Google
  action while the raw exchange remains unresolved.
- blocked unattributed: localized explanation and explicit device-reset action.
- local reset: finite retry busy state; restart message replaces reset/sign-in.
- localization: Arabic and English explain local-only removal, restart and
  signing in again, without claiming cloud/account/other-device revocation.
- result: PASS.

## Tests

- exact files and exact final counts (JSON reporter):

| Focused file | PASS | FAIL | SKIPPED |
| --- | ---: | ---: | ---: |
| test/auth_recovery_foundation_test.dart | 93 | 0 | 0 |
| test/v1_r09_c2_sign_out_recovery_test.dart | 49 | 0 | 0 |
| test/v1_r09_c3_credential_exchange_quarantine_test.dart | 64 | 0 | 0 |
| test/supabase_auth_gateway_test.dart | 22 | 0 | 0 |
| test/auth_provider_test.dart | 27 | 0 | 0 |
| test/auth_screen_test.dart | 8 | 0 | 0 |
| TOTAL | 263 | 0 | 0 |

- production-path: C3 uses real Supabase/GoTrue HTTP responses, session memory,
  event delivery, Hive journal/coordinator and guarded storage; not primarily
  the legacy injected no-journal seam.
- crash matrix: all five specified durable handoff points covered.
- B protection: installed B, persisted B, mixed states, malformed persistence,
  exact bytes and destructive call counts asserted.
- commit race: pre/post-completion SDK loss/replacement, single-use receipt,
  delayed COMMITTING timeout and no stale bootstrap admission.
- generation: no overlapping exchange; late failure/success settlement permits
  a fresh intentional attempt only after safe completion.
- deadlines: remote, SDK local cleanup and delegate stalls; finite UI waits,
  observed late results and no duplicate raw mutations.
- journal failures: begin, timeout phase, upgrade, in-time/late failure
  finalization, commit/local completion, reset marker and next-start completion.
- local reset: unchanged/changed/malformed bytes, unknown memory, restart,
  unexpected next-start data, out-of-state rejection and retry failures.
- async errors: explicit guarded-zone assertion plus real late-error and
  processing-failure tests; zero unhandled errors in final run.
- executable: 263 PASS / 0 FAIL / 0 SKIPPED, final process exit 0.
- full suite: NO.
- analyzer: NO.
- pub get: NO.

Exact focused invocation (the final run added --reporter json for counting):

```powershell
flutter test --no-pub test/auth_recovery_foundation_test.dart test/v1_r09_c2_sign_out_recovery_test.dart test/v1_r09_c3_credential_exchange_quarantine_test.dart test/supabase_auth_gateway_test.dart test/auth_provider_test.dart test/auth_screen_test.dart
```

Intermediate runs exposed obsolete pre-addendum expectations and missing
storage-failure classification; these were corrected before the final passing
run. Final counts above are executable results, not test-definition estimates.
After the continuation request, current source/test hashes were compared with
the passing-run snapshot: no changes; passed tests were not repeated.

## C1 Preservation

- coordinator: one existing coordinator, with narrowly scoped owned upgrade
  and explicit reset methods; no raw storage bypass introduced.
- queue: one queue; delegate draining preserved.
- transaction: captured ownership and callback lifetime enforced; escaped
  upgrade/reset calls reject; exact-A upgrade does not grant destructive rights
  to an uncorrelated placeholder transaction.
- normal deletion: existing identity/project matching retained; optional
  last-moment memory veto only narrows removal permission. No unconditional
  normal recovery deletion surface.
- result: C1 accepted semantics preserved; 93/93 foundation tests pass
  (the existing 81 plus 12 new boundary tests).

## C2 Preservation

- sign-out: accepted remote-first behavior retained.
- conditional removal: same matcher and guarded adapter, with shared caller
  memory revalidation immediately before destructive delegate work.
- events: definitive SDK loss forwarded; account-bearing events gated in every
  restrictive C3 state.
- bounded cleanup: accepted raw observation, finite UI deadline, delegate
  draining and fresh late settlement reused by C3.
- result: all 49 accepted C2 regression tests pass; C2 test file unchanged.

## Boundary

- C4: NOT STARTED.
- Part 2: NOT STARTED.

## Protection

Compared SHA-256 hashes for the 509-file starting inventory (lib, test, docs,
supabase, pubspec files and OpenCode_Usage_Report.txt). This correction changes:

Production:
- lib/features/auth/data/auth_recovery_journal.dart
- lib/features/auth/data/auth_recovery_storage_coordinator.dart
- lib/features/auth/data/supabase_auth_gateway.dart
- lib/features/auth/domain/repositories/auth_gateway.dart
- lib/features/auth/presentation/providers/auth_provider.dart
- lib/features/auth/presentation/auth_screen.dart
- lib/features/user_area/presentation/user_area_screen.dart
- lib/localization/ar.dart
- lib/localization/en.dart

Tests:
- test/auth_recovery_foundation_test.dart
- test/v1_r09_c3_credential_exchange_quarantine_test.dart
- test/supabase_auth_gateway_test.dart
- test/auth_screen_test.dart

Docs:
- docs/architecture/contracts/V1-R09_OFFLINE_CONNECTIVITY_ERROR_HARDENING_CONTRACT.md
  (authorized append only)
- docs/architecture/reports/V1-R09_PART1_INFRASTRUCTURE_IMPLEMENTATION_REPORT.md
  (this append only)

All other inventoried files retain their starting hashes.

- migration 00022: ABSENT.
- migrations: unchanged.
- contract: only authorized C3 Addendum A; original bytes preserved.
- roadmap: unchanged from this correction's starting worktree, including controls.
- pubspec: unchanged.
- dependencies: unchanged; no pub get.
- SDK/package: no manual modification or patch.
- SupabaseClient: one production Supabase initialization/authority; no second client.
- AuthProvider: one production instance, existing construction in lib/main.dart.
- service_role: no privileged credential introduced.

## Git

- diff check: passed before this append; final diff check and append-prefix
  integrity checked afterward.
- staged: NO.
- committed: NO; HEAD remains e80fab8883a3631e58d1cc9bb83846c7f981d0fa.
- pushed: NO.
- OpenCode_Usage_Report.txt: untouched; starting SHA-256
  E263153E220BFC6E6ADF8D4CC313E4799D978F544432407086D1306CADCB7715 retained.
  Pre-existing dirty/untracked work was preserved, not reverted or staged.

## Remaining Concerns

None within the authorized correction scope. Independent acceptance is still
required. C4 and Part 2 remain locked.

## Final Decision

C3 CORRECTIONS COMPLETE — READY FOR INDEPENDENT RECHECK

---

# V1-R09 Part 1 — C4 M2 Profile-Region Error Mapping + Integration

Date: 2026-09-14. Scope: C4 M2 only — typed profile-region backend error mapping,
null-only UPDATE predicate, and authoritative reread integration with the existing
profile update flow. Previous C1/C2/C3 history is preserved.

## Error Mapping

- `42501` → `CloudProfilePermissionDeniedException` (RLS / insufficient privilege).
- `23502` → `CloudProfileInvalidDataException` (NOT NULL violation).
- `23503` → `CloudProfileInvalidDataException` (FK violation).
- `23514` → `CloudProfileInvalidDataException` (CHECK violation).
- `23P01` → `CloudProfileInvalidDataException` (exclusion violation).
- SQLSTATE class `22xxx` → `CloudProfileInvalidDataException` (data / text representation errors).
- UPDATE-time `23505` → `CloudProfileInvalidDataException`; explicitly NOT interpreted as
  successful create-profile provisioning or already-exists success.
- Malformed backend response → strict `parseCloudProfileRow` throws
  `CloudProfileParseException`, surfaced as `malformedResponse`.
- Infrastructure (timeout, network, offline, service unavailable) →
  `InfrastructureFailureException` with the existing `InfrastructureFailureKind` taxonomy.
- Auth/session failures → remain upstream under `AuthProvider` generation/session checks;
  never collapsed into permission/domain/infrastructure causes.
- Unexpected SQLSTATE / unclassifiable backend failure → `CloudProfileUnexpectedException`,
  surfaced as `unexpected` (not retryable infrastructure).

Implementation locations:
- `lib/features/profile/data/supabase_personal_profile_remote_gateway.dart`
  - `isPermissionDenied`, `isUpdateInvalidDataRejection`, `isUnexpectedBackendFailure`
    classification helpers.
  - `updateRegionPreferenceId` and `saveEditableFields` apply the mapping and leave
    infrastructure exceptions for the caller's classifier.
- `lib/features/profile/data/personal_profile_remote_gateway.dart`
  - Added `CloudProfileInvalidDataException` and `CloudProfileUnexpectedException`.

## Region Update

- Ownership: RLS (`user_id = auth.uid()`) plus the caller-supplied `userId` remains the
  authority; no second auth check was added.
- Null-only predicate: `updateRegionPreferenceId` adds `.isFilter('region_preference_id', null)`
  to the UPDATE query so the backend rejects any attempt to overwrite an already-populated
  cloud region.
- Already populated: bootstrap path treats a cloud preference difference as `profileConflict`;
  the gateway's null-only predicate prevents silent replacement.
- Timeout: `TimedPersonalProfileRemoteGateway` applies the existing 20-second mutation deadline;
  expiry is `InfrastructureFailureKind.timeout`.
- Retry: only infrastructure failures are retryable; domain/permission/auth/malformed/unknown
  errors are not converted into automatic retry behavior. A manual retry revalidates auth
  identity, session generation, and authoritative profile state through the existing gates.

## Authoritative Reread

- Performed: `PersonalProfileBootstrapCoordinator._associateOrConflict` now calls
  `_remoteGateway.fetchByUserId(userId)` after a successful `updateRegionPreferenceId`.
- Strict parsing: the reread uses the existing `parseCloudProfileRow` strict parser
  (SSOT flow); malformed rows throw `CloudProfileParseException`.
- Identity/generation: the reread result is validated against the captured `userId`;
  mismatches return `failure` / `ownershipConflict` and never bind.
- False-success prevention: the coordinator only binds when the reread confirms the
  expected `regionPreferenceId`. A reread that returns null, a different region, or fails
  returns `ProfileBootstrapOutcome.failure` (retryable, no binding, no false success).
- Provider path: `UserProfileProvider.saveRoleAndRegionPreference` already performed an
  authoritative reread; it was extended to map the new typed exceptions and infrastructure
  kinds to precise `ProfileOperationCause` values without publishing the local submitted
  value before the reread.

## C3 / Auth Preservation

- Recovery gate: `AuthProvider.isAuthorityBlocked` / `canAccountAuthorityBeGranted` still
  blocks the post-auth pipeline and direct `saveRoleAndRegionPreference` before any backend
  mutation.
- A-vs-B: generation/session checks in `UserProfileProvider` reject stale results after a
  session change; account B cannot adopt account A's in-flight region mutation.
- Session loss: only authoritative auth lifecycle events control session loss; temporary
  backend/network failure during profile mutation does not sign out the user or clear the
  restored session.
- Provider: one `AuthProvider`, one production `SupabaseClient`; no second authority added.

## Tests

- exact files:
  - `test/v1_r09_c4_profile_region_mapping_test.dart` (new)
  - `test/a5_6_profile_bootstrap_test.dart` (regression)
  - `test/a5_7_region_reference_test.dart` (regression)
  - `test/v1_r08_cloud_profile_foundation_test.dart` (regression)
  - `test/v1_r08_profile_edit_screen_widget_test.dart` (regression)
  - `test/v1_r08_profile_screen_widget_test.dart` (regression)
  - `test/auth_provider_test.dart` (regression)
  - `test/auth_recovery_foundation_test.dart` (C3 regression)
  - `test/v1_r09_c3_credential_exchange_quarantine_test.dart` (C3 regression)
  - `test/v1_r09_c2_sign_out_recovery_test.dart` (C2 regression)
  - `test/supabase_auth_gateway_test.dart` (C2/C3 regression)
  - `test/remote_operation_policy_test.dart` (regression)
- exact counts:
  - C4 focused: 29 PASS / 0 FAIL / 0 skipped
  - Profile regressions: 151 PASS / 0 FAIL / 0 skipped
    (`a5_6_profile_bootstrap_test.dart` 40,
    `a5_7_region_reference_test.dart` 20,
    `v1_r08_cloud_profile_foundation_test.dart` 25,
    `v1_r08_profile_edit_screen_widget_test.dart` 16,
    `v1_r08_profile_screen_widget_test.dart` 14,
    `auth_provider_test.dart` 16,
    `remote_operation_policy_test.dart` 20)
  - C1/C2/C3 regressions: 228 PASS / 0 FAIL / 0 skipped
    (`auth_recovery_foundation_test.dart` 81,
    `v1_r09_c3_credential_exchange_quarantine_test.dart` 64,
    `v1_r09_c2_sign_out_recovery_test.dart` 49,
    `supabase_auth_gateway_test.dart` 22,
    `auth_provider_test.dart` 12 already counted in profile regressions)
- mapping: covered by SQLSTATE classification helpers and production gateway HTTP tests.
- update predicate: covered by bootstrap and production gateway query-string assertions.
- reread: covered by bootstrap coordinator tests.
- generation: covered by provider A→B session-change test.
- recovery gate: covered by provider blocked-authority test.
- network/session preservation: covered by provider network-failure test.
- regressions: all directly affected focused suites pass.
- full suite: NO.
- analyzer: NO.

## Boundary

- C1: remains CLOSED/accepted.
- C2: remains CLOSED/accepted.
- C3: remains CLOSED/accepted; no C3 invariants were changed.
- Part 2: NOT started.

## Protection

- migration 00022: absent.
- migrations: unchanged.
- contract: `docs/architecture/contracts/V1-R09_OFFLINE_CONNECTIVITY_ERROR_HARDENING_CONTRACT.md`
  unchanged except for any pre-existing dirty state.
- Addendum A: unchanged.
- roadmap: unchanged by this slice.
- pubspec: unchanged.
- dependencies: unchanged; no `pub get`.
- SDK/package: no manual modification or patch.
- SupabaseClient: one production initialization/authority.
- AuthProvider: one production instance.
- service_role: no privileged credential introduced.
- OpenCode_Usage_Report.txt: untouched.

## Git

- diff check: PASS; only Git LF-to-CRLF working-copy warnings.
- staged: NO.
- committed: NO; HEAD remains `e80fab8883a3631e58d1cc9bb83846c7f981d0fa`.
- pushed: NO.

## Remaining Concerns

None within the authorized C4 M2 scope. Independent acceptance is still required.
Part 2 remains locked.

## Final Decision

C4 IMPLEMENTATION COMPLETE — READY FOR INDEPENDENT REVIEW

---

# V1-R09 Part 1 — C4 Surgical Correction Report

Date: 2026-09-15. Scope: correction of the two HIGH and four MEDIUM C4
findings in the independent review. C1/C2/C3 remain accepted/closed. This
appendix does not supersede or rewrite any previous implementation evidence.

## C3 Authority Gate

- mutation entry: consumes the existing gateway authority through
  AuthProvider.canAccountAuthorityBeGranted; no C3 state machine is duplicated.
- authenticated→blocked: all five named C3 restrictive states are tested after
  successful authentication, with the same session object and generation retained.
- retryPostAuth: returns before invoking the pipeline when the accepted
  authority gate is blocked. Production bootstrap receives a captured
  session/generation guard through the existing AppDependencies pipeline.
- backend calls: zero writes and zero region lookups at a blocked entry; a
  restriction introduced during lookup also prevents the write.
- result: PASS.

## Error Taxonomy

- infrastructure: genuine transport, timeout, typed service-unavailable, SDK
  retryable fetch, and the SDK HTTP 503 fallback are retryable.
- auth/session: CloudProfileAuthException is distinct and never clears the SDK
  or provider session. Exact PostgREST PGRST301/PGRST302/PGRST303 and HTTP 401
  fallback codes are supported by public backend/installed SDK evidence.
  Canonical AuthSessionMissingException, AuthInvalidJwtException, and auth
  exceptions carrying status 401 are also distinct.
- permission: 42501 remains permissionDenied.
- invalid: 23502/23503/23514/23P01, valid five-character class-22 SQLSTATEs,
  and UPDATE-time 23505 remain invalidData.
- malformed: strict parser failure and malformed response shape remain
  malformedResponse; no partial profile or authenticated local fallback.
- unknown: missing/unrecognized codes and untyped exceptions stay unexpected,
  with no raw details in presentation state and no automatic network retry.
  PGRST300 is not mislabelled as a user-session rejection.
- retryability: permission/invalid/malformed/auth/unexpected bootstrap outcomes
  do not enter the retryable post-auth lifecycle.
- result: PASS.

Evidence: installed postgrest 2.8.0 types.dart/fromJson and
postgrest_builder.dart/_parseResponse preserve backend code and use HTTP
status as fallback; the shared supabase 2.13.4 AuthHttpClient obtains the
access token without separately classifying PostgREST responses. Installed
gotrue 2.25.0 exposes canonical auth exception types.
Public JWT-code definitions:
https://docs.postgrest.org/en/v14/references/errors.html#group-3-jwt
and https://docs.postgrest.org/en/v12/references/errors.html#group-3-jwt.
Classification uses no guessed error-message matching for auth.

## Bootstrap Propagation

- typed outcomes: permissionDenied, invalidData, malformedResponse, authFailure,
  and unexpected are carried through ProfileBootstrapOutcome → PostAuthOutcome
  → PostAuthLifecycleState.
- infrastructure: existing failure/retryableFailure represents transport failure
  or a still-unresolved timed-out mutation.
- non-infrastructure: remote failure and reread paths retain their typed cause.
  Local storage failure is unexpected; missing canonical rows remain
  provisioning failure, and null/mismatching post-fill regions are conflict.
- UI/provider: localized AR/EN messages expose typed failures without offering
  the network-retry action for non-infrastructure outcomes. Session-loss
  ownership remains exclusively with the accepted auth lifecycle.
- result: PASS.

## Region Conflict

- direct save mismatch: returns ProfileOperationCause.profileConflict.
- authoritative cloud value: only the strict reread profile is published.
- submitted value: never installed speculatively.
- retry: no automatic overwrite/retry; a retry after an uncertain write rereads
  current cloud state. A differing existing region causes conflict.
- result: PASS.

## Generation / A→B

- capture point: user identity and auth generation are captured before lookup.
- post-lookup validation: both ownership and the accepted authority gate are
  checked after the awaited lookup and immediately before mutation.
- mutation boundary: deterministic A→B and authority-block barriers prove zero
  backend writes after invalidation.
- post-mutation: identity/generation/authority checks remain after write,
  authoritative reread, and region-code resolution.
- result: PASS.

## Manual Retry

- authoritative reread: a failed/uncertain mutation sets process-local request
  metadata only. The next explicit attempt reads current cloud state first.
- identity: request metadata is bound to user and generation; an old operation
  cannot authorize a write for a replacement account.
- generation: retry validates before and after its awaits.
- recovery gate: consumes the existing C3 gate; blocked retry never mutates.
- raw settlement: TimedPersonalProfileRemoteGateway observes completion of
  the original raw Future separately from its unchanged 20-second deadline.
  Retry cannot start another write while the old raw request is unresolved.
  Late success and late failure are consumed and tested.
- mutation race: a region retry uses the same client with own-user AND
  region_preference_id IS NULL predicates, protecting a concurrently populated
  region after the preflight read. Role-only retry does not rewrite the region.
  No queue, background retry, extra client, or SDK patch was introduced.
- definite rejection: invalid/permission/auth rejection does not leave corrected
  input trapped behind an uncertainty marker.
- result: PASS.

## Tests

Final command (repository-relative paths):

```powershell
flutter test --no-pub test/v1_r09_c4_profile_region_mapping_test.dart test/a5_6_profile_bootstrap_test.dart test/v1_r08_cloud_profile_foundation_test.dart test/auth_provider_test.dart test/v1_r08_auth_screen_widget_test.dart test/v1_r08_profile_edit_screen_widget_test.dart test/v1_r08_auth_session_foundation_test.dart test/v1_r09_c2_sign_out_recovery_test.dart test/v1_r09_c3_credential_exchange_quarantine_test.dart --reporter json
```

- test/v1_r09_c4_profile_region_mapping_test.dart: 73 PASS / 0 FAIL / 0 SKIPPED.
- test/a5_6_profile_bootstrap_test.dart: 40 PASS / 0 FAIL / 0 SKIPPED.
- test/v1_r08_cloud_profile_foundation_test.dart: 25 PASS / 0 FAIL / 0 SKIPPED.
- test/auth_provider_test.dart: 27 PASS / 0 FAIL / 0 SKIPPED.
- test/v1_r08_auth_screen_widget_test.dart: 24 PASS / 0 FAIL / 0 SKIPPED.
- test/v1_r08_profile_edit_screen_widget_test.dart: 16 PASS / 0 FAIL / 0 SKIPPED.
- test/v1_r08_auth_session_foundation_test.dart: 45 PASS / 0 FAIL / 0 SKIPPED.
- test/v1_r09_c2_sign_out_recovery_test.dart: 49 PASS / 0 FAIL / 0 SKIPPED.
- test/v1_r09_c3_credential_exchange_quarantine_test.dart: 64 PASS / 0 FAIL / 0 SKIPPED.
- exact total: 363 PASS / 0 FAIL / 0 SKIPPED; executable exit 0.
- authenticated→blocked: all five specified states; zero lookup/write and no
  post-auth retry while retaining the authenticated session.
- auth classification: real installed Supabase/PostgREST client with controlled
  HTTP responses, plus canonical installed auth exception types.
- non-infrastructure propagation: mutation and reread matrix through actual
  coordinator, AppDependencies mapping, and AuthProvider.
- real malformed parser: malformed HTTP row passes through production strict
  parsing; no new profile publication, no retryable classification, no logout.
- A→B lookup race: deterministic barrier before backend mutation; zero writes.
- region mismatch: conflict, authoritative value retained, one write only.
- provisioning 23505: existing create-race scenarios preserved; update 23505
  remains a domain failure.
- session preservation: no sign-out calls for profile failure; AR/EN widgets
  retain authenticated state and omit network retry for non-infrastructure.
- retry/deadline: late success/failure raw settlement and conditional retry
  predicates are explicitly exercised.
- fixture corrections: old generic Exception('network/offline') fixtures now
  use actual SocketException for infrastructure assertions. Local storage
  failure expectations are non-infrastructure unexpected. A previous hanging
  mutation fixture now explicitly settles its raw request before retry.
- full repository suite: NOT RUN. Analyzer: NOT RUN. Pub get: NOT RUN.
- result: PASS; independent acceptance remains required.

## C1/C2/C3 Preservation

- C1: coordinator, queue, transaction lifetime, guarded storage, and journal
  production files have identical starting-worktree hashes.
- C2: sign-out/recovery implementation unchanged; all 49 focused tests pass.
- C3: gateway/journal/cleanup/Addendum A unchanged. AuthProvider changes are
  limited to exposing the existing authority gate, consuming it at retry,
  carrying C4 post-auth outcomes, and formatting; recovery-event behavior and
  the C3 state machine are unchanged. All 64 focused C3 tests pass.
- result: PASS.

## Protection

- Part 2: not started.
- migration 00022: absent; migrations unchanged.
- contract and C3 Addendum A: identical starting-worktree hashes.
- roadmap, pubspec, lockfile/dependencies: identical starting-worktree hashes.
- SDK/package: no edits or patches.
- SupabaseClient: one production Supabase initialization/client authority.
- AuthProvider: one production instance.
- service_role: no credential or client usage introduced.
- OpenCode_Usage_Report.txt: identical starting-worktree hash; untouched.
- change boundary: 14 related production Dart files and 5 related test files,
  plus this append-only report. Main/AppDependencies changes wire the captured
  ownership callback; auth/editor/localization changes carry C4 outcomes.
  No files removed. Other pre-existing worktree changes are preserved.
- baseline audit: 1,114 tracked/untracked non-ignored files hashed before the
  correction; 1,095 unchanged before this report append.

## Git

- diff check: PASS (existing line-ending warnings only).
- staged: NO.
- committed: NO.
- pushed: NO.

## Remaining Concerns

None within the authorized correction scope. Independent review is pending.

## Final Decision

C4 CORRECTIONS COMPLETE — READY FOR INDEPENDENT RECHECK

---

# V1-R09 Part 1 — C4 Final Surgical Correction Report

Date: 2026-09-15. Scope: final correction of the remaining MEDIUM C4 finding
(same-user generation rollover with an unresolved raw profile-region mutation).
C1/C2/C3 remain accepted/closed. Part 2 remains locked. Previous C4 history is
preserved.

## Pending Mutation Guard

- previous defect: When `_uncertainSave.generation` differed from the current
  auth generation, the provider discarded local uncertainty and proceeded to
  issue a new write without consulting the gateway's actual pending-mutation
  state. This allowed a second mutation to start while the old generation's raw
  write was still unresolved, violating the C4 no-competing-write requirement.
- generation rollover: Auth generation mismatch (same user, g1 → g2) is now
  treated as "old result may not be adopted", NOT as "old raw mutation has
  settled". These are separate facts.
- gateway pending check: Added `_isProfileMutationPending(userId)`, which asks
  the production gateway (via `ProfileMutationSettlement`) whether a raw
  mutation for the current `userId` is still in flight. This check runs before
  any new profile-region mutation, regardless of whether `_uncertainSave` is
  null, matches the current generation, or differs from it.
- duplicate-write prevention: If the gateway reports pending, the provider
  returns `ProfileOperationCause.retryableFailure`, does NOT clear
  `_uncertainSave`, and does NOT call `saveEditableFields` or
  `saveEditableFieldsIfRegionAbsent`.
- result: PASS.

## Same-User g1 → g2

- g1 unresolved: User A at generation g1 starts `saveRoleAndRegionPreference`;
  the application deadline expires while the raw gateway mutation is still
  unresolved; `_uncertainSave` records `(userId: A, generation: g1, ...)`, and
  the provider surfaces `retryableFailure`.
- g2 retry: A signs out and signs back in as the same user, advancing the auth
  generation to g2. A(g2) requests the same region save while the g1 raw
  mutation is still pending.
- backend writes: Second backend write count == 0; the pending guard blocks the
  retry before any new raw mutation starts.
- authoritative reread: After the original raw mutation settles, the provider
  performs an authoritative `fetchByUserId` reread before deciding whether to
  no-op, conflict, or allow a fresh mutation.
- result: PASS. The g1 operation result is not adopted into the g2 session; g2
  remains safely blocked from a competing write until settlement and reread.

## A → B Preservation

- stale A: A(g1) unresolved uncertainty remains in `_uncertainSave`.
- B: Account B becomes current at g2. The provider treats A's uncertainty as
  stale (different user), checks the gateway pending state for B, and rereads
  B's authoritative cloud profile before any B mutation.
- result: PASS. Existing A→B protections remain unchanged; B does not adopt A's
  result. The prior A→B session-generation-change regression test continues to
  pass.

## Tests

- exact files:
  - `test/v1_r09_c4_profile_region_mapping_test.dart` (C4 focused)
  - `test/v1_r08_cloud_profile_foundation_test.dart` (profile/provider regression)
  - `test/auth_provider_test.dart` (smallest auth-provider regression)
- exact counts: 74 + 25 + 27 = 126 PASS / 0 FAIL / 0 SKIPPED.
- same-user rollover: new deterministic regression test
  `same-user generation rollover blocks retry while raw mutation pending, then
  rereads after settlement` PASS.
- duplicate write: asserted `raw.saveCalls` remains 1 during the g2 blocked
  retry and after settlement.
- settlement: asserted `timed.isProfileMutationPending(_userA)` transitions
  from true to false after `raw.release()`; post-settlement save no-ops via
  authoritative reread.
- A→B regression: existing test
  `A→B session-generation change during save rejects result` PASS.
- result: PASS.

## Boundary

- C1: unchanged / accepted / closed.
- C2: unchanged / accepted / closed.
- C3: unchanged / accepted / closed.
- Part 2: NOT started; remains locked.

## Protection

- source files changed:
  - `lib/features/profile/presentation/providers/user_profile_provider.dart`
  - `test/v1_r09_c4_profile_region_mapping_test.dart`
  - `docs/architecture/reports/V1-R09_PART1_INFRASTRUCTURE_IMPLEMENTATION_REPORT.md`
    (this append only)
- migration 00022: absent.
- migrations: unchanged.
- contract: `docs/architecture/contracts/V1-R09_OFFLINE_CONNECTIVITY_ERROR_HARDENING_CONTRACT.md`
  unchanged.
- C3 Addendum A: unchanged.
- roadmap: unchanged.
- pubspec: unchanged.
- dependencies: unchanged; no `pub get`.
- SDK/package source: no manual modification or patch.
- SupabaseClient: one production initialization/authority.
- AuthProvider: one production instance.
- OpenCode_Usage_Report.txt: untouched.

## Git

- diff check: PASS; only Git LF-to-CRLF working-copy warnings.
- staged: NO.
- committed: NO.
- pushed: NO.

## Remaining Concerns

None.

## Final Decision

C4 FINAL CORRECTION COMPLETE — READY FOR MICRO-RECHECK

---

# V1-R09 Part 1 — Connectivity Lifecycle Correction Report

## Origin

This correction originates from the Part 1 Integrated Gate failure:
`flutter test --no-pub` produced PASS 2558 / FAIL 11 / SKIPPED 0 / EXIT CODE 1.
All 11 failures shared one root cause — not repeated defects.

## Root Cause

`ConnectivityProvider._initialize()` waited on the initial availability probe
through `runWithRemoteDeadline()` → `Future.timeout(timeout)`. `Future.timeout`
allocates an internal one-shot Timer that cannot be cancelled from outside.
The provider's default initial-check deadline is 3s
(`RemoteOperationPolicy.connectivityCheck`), so any short-lived provider
(widget-test fixtures that construct `ConnectivityProvider()`/super() directly,
and the real provider in Home) is disposed long before the probe settles or the
3s Timer fires. flutter_test's automated teardown then reports a pending
Timer — 11 failures across the Integrated Gate, all the same mechanism.

## Deadline Ownership

- `ConnectivityProvider` now owns the deadline explicitly:
  - `Timer? _initialCheckTimer` created in `_initialize()` with
    `_initialCheckTimeout` (centralized policy default 3s unchanged).
  - `Completer<void>? _initializationCompleter` captures the same completer the
    `initialization` Future resolves through, so `dispose()` can settle a probe
    that will never be resolved.
- The internal `settled` arbiter enforces single settlement: exactly one winner
  out of (raw probe success / raw probe error / deadline). The first winner
  cancels the deadline Timer, records settlement, and completes `initialization`.
- Late winners after settlement are ignored: no state mutation, no
  `notifyListeners`, no second `initialization` completion.
- Error ownership preserved: the probe Future always has an attached `onError`
  (plus a trailing `catchError` guard), so a probe that fails after a settle or
  after dispose can never surface as an unhandled async error.

## Disposal

`dispose()` now:
- cancels the owned `_initialCheckTimer` (zero provider-owned pending deadline
  Timers survive disposal),
- completes `_initializationCompleter` if still open (an `await
  provider.initialization` after dispose resolves instead of hanging),
- cancels the availability stream subscription exactly once,
- keeps the pre-existing guard that no stream event/error or late probe result
  published after `_disposed`.

## Transport Semantics

Unchanged canonical behavior:
- starts `TransportState.unknown`; `isOnline` (Home backward-compatible view) is
  false unless confirmed `available`.
- probe `true` → `available`, probe `false` → `unavailable`, probe error →
  `unknown`.
- deadline win stays `unknown`; the deadline is a completeness bound, not a claim
  of backend health — `available` is never invented on timeout.
- `_sourceEventSequence` staleness rule preserved: a newer stream event still
  wins over a stale initial probe.
- `reconnectGeneration` increments only on real UNAVAILABLE → AVAILABLE.

## Tests

- exact file: `test/connectivity_provider_test.dart` — existing canonical
  transport lifecycle group (10 tests) PLUS new "deadline lifecycle ownership"
  group, scenarios A–H:
  - A. initial success settles exactly once and cancels the deadline
  - B. initial failure is consumed and settles safely UNKNOWN
  - C. deadline win stays UNKNOWN and late completion is ignored
  - D. dispose before source completion ignores the late result
  - E. dispose before the deadline leaves no provider-owned timer
  - F. a late source error after dispose stays consumed
  - G. stream events and errors never publish after disposal
  - H. repeated dispose and late completion are lifecycle-safe
- result: 19 PASS / 0 FAIL / 0 SKIPPED (10 existing + 9 new).
- widget regression proof (short-lived provider fixtures that carried the
  Integrated Gate failures):
  - `test/home_main_screen_theme_test.dart` (Home fixture): 2 PASS.
  - `test/a5_8_splash_restart_route_test.dart` (A5.8 fixture): 9 PASS.
- steady-state Integrated Gate count was not rerun in this pass (focused
  evidence only, per workflow).

## Boundary

- C1, C2, C3: unchanged / accepted / closed.
- C4 (same-user generation rollover): unchanged; its final-correction evidence
  is preserved above.
- Part 2: NOT started; remains locked.
- Scope of this pass: `connectivity_provider.dart` deadline lifecycle plus its
  test file and this report append only.

## Protection

- source files changed:
  - `lib/core/services/connectivity_provider.dart`
  - `test/connectivity_provider_test.dart`
  - `docs/architecture/reports/V1-R09_PART1_INFRASTRUCTURE_IMPLEMENTATION_REPORT.md`
    (this append only)
- migration 00022: absent.
- migrations: unchanged.
- contract: `docs/architecture/contracts/V1-R09_OFFLINE_CONNECTIVITY_ERROR_HARDENING_CONTRACT.md`
  unchanged.
- C3 Addendum A: unchanged.
- roadmap: unchanged.
- pubspec / dependencies: unchanged; no new dependencies; no `pub get`.
- SDK/package source: no manual modification or patch.
- SupabaseClient: one production initialization/authority (unchanged).
- AuthProvider: one production instance (unchanged).
- OpenCode_Usage_Report.txt: untouched.

## Git

- diff check: PASS; only Git LF-to-CRLF working-copy warnings.
- staged: NO.
- committed: NO.
- pushed: NO.

## Remaining Concerns

None.

## Final Decision

PART 1 CONNECTIVITY LIFECYCLE CORRECTION COMPLETE — READY FOR REGATE

---

## Correction Note (Re-Gate preparation)

Correction: `test/connectivity_provider_test.dart` contains 11 pre-existing
tests and 8 lifecycle/deadline tests, total 19. The prior "10 existing + 9 new"
wording in the Connectivity Lifecycle Correction section was a counting error
only; no technical evidence above is altered.

Follow-up (Re-Gate correction pass): the lifecycle group gained 2 deterministic
ordering-regression tests — "stream AVAILABLE before deadline is never
overwritten by the deadline" and "stream UNAVAILABLE before deadline is never
overwritten by the deadline" — so the file now totals 21 tests (11 pre-existing
canonical + 10 lifecycle/deadline-ordering).

---

# V1-R09 Part 1 — Formal Closure Record

## Acceptance

- C1 ACCEPTED / CLOSED.
- C2 ACCEPTED / CLOSED.
- C3 ACCEPTED / CLOSED.
- C4 ACCEPTED / CLOSED.
- connectivity lifecycle correction: ACCEPTED (provider-owned timer, single
  settlement, dispose-safe cancellation, zero pending provider-owned timers).
- connectivity deadline-ordering correction: ACCEPTED (deadline cannot
  overwrite newer authoritative stream evidence; 2 deterministic ordering
  regression tests).
- obsolete test baselines: CORRECTED (V1-R06 roadmap current-phase baseline
  advanced to V1-R09; W5.1 Directory key baseline now includes the authorized
  C1 `auth_recovery_journal` / `auth_recovery_journal_entry` keys while
  retaining an explicit allow-list).
- final full-suite: `flutter test --no-pub` → 2579 PASS / 0 FAIL / 0 SKIPPED /
  exit code 0.
- blocking findings: NONE.

## Decision

- Part 1 formally CLOSED.
- Part 2 AUTHORIZED to begin.

No further Part 1 full-suite rerun is required unless future Part 2 work
invalidates relevant Part 1 evidence.

## Roadmap / Contract

- roadmap: V1-R09 Part 1 recorded CLOSED / ACCEPTED; V1-R09 Part 2 AUTHORIZED /
  current within V1-R09; V1-R09 overall remains CURRENT; V1-R10 remains QUEUED.
- contract `V1-R09_OFFLINE_CONNECTIVITY_ERROR_HARDENING_CONTRACT.md` and C3
  Addendum A: unchanged and authoritative (frozen).
- migrations: unchanged (00001–00021 present; 00022 absent).
- pubspec / pubspec.lock / dependencies: unchanged.
- SDK/package: untouched.
