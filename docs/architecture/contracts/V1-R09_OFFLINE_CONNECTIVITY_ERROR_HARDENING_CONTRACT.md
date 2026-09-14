# CIVILPEDIA V1-R09 — OFFLINE / CONNECTIVITY / ERROR HARDENING CONTRACT

PHASE: V1-R09
TITLE: Offline / Connectivity / Error Hardening
CONTRACT: V1-R09-CONTRACT-v1
STATUS: FROZEN
IMPLEMENTATION_AUTHORIZED: YES

## 1. Authority and Purpose

This contract is the authoritative implementation boundary for V1-R09. The
phase hardens Civilpedia so that existing local features remain usable when
network or backend services are unavailable, material remote operations end in
finite safe states, connectivity is represented truthfully, retries are
bounded and safe, and cached data has predictable authority and presentation.

V1-R09 preserves all accepted V1-R08 authentication, identity, ownership, and
account-bound stale-result guarantees. It is not a general offline
synchronization engine and creates no new server authority.

## 2. Existing Components to Extend

Reuse and extend the existing `connectivity_plus ^6.1.0` dependency,
`ConnectivityProvider`, `SupabaseService`, `AppDependencies`, existing
gateways/providers, Directory cloud cache, and existing state widgets and
notice patterns.

Do not create a second connectivity provider, parallel dependency container,
internet-reachability service, offline database, background synchronization
framework, or competing session authority.

## 3. Canonical Transport State

`ConnectivityProvider` becomes the one canonical app-wide transport authority.
Its canonical state has exactly these meanings:

- `unknown`: the initial platform check has not completed, or the platform
  cannot currently provide a trustworthy result;
- `available`: one or more network transports are present; and
- `unavailable`: no usable network transport is present.

Transport `available` never proves that the internet, Supabase, authentication
backend, or a particular request is reachable or healthy. Actual request
outcomes remain authoritative for service and network failures. Connectivity
state must never be used as authentication authority.

The provider must:

- accept an injectable/testable connectivity source;
- begin in `unknown`, never optimistic online;
- bound the initial platform check to three seconds;
- handle initialization and stream failures without crashing;
- dispose subscriptions correctly; and
- be the only production consumer that instantiates the connectivity plugin.

Feature code may observe the canonical provider. It must not construct its own
`connectivity_plus` object or infer backend health from transport state.

## 4. Application-Level Offline Presentation

Civilpedia must provide one reusable, localized, non-blocking application-level
transport indication.

When transport is `unavailable`, the user receives a clear offline indication
while navigation and local features remain available. The application shell is
not replaced by a blocking offline page. When transport is `available`, the UI
must not claim backend or service health. `unknown` must not be presented as
confirmed online.

Feature-level request failures remain independently represented. Existing
Civilpedia visual primitives and layout conventions must be preserved; this
phase does not authorize a broad visual redesign.

## 5. Local-First Startup

The local application shell and existing local capabilities must not be
blocked indefinitely by remote initialization. The guaranteed local set
includes at minimum:

- packaged encyclopedia catalog and text content;
- calculators and tools;
- local projects and associated notes, calculations, checklists, and records;
- saved items, favorites, download references, and downloaded article data;
- preferences, onboarding, language, and theme; and
- guest/local profile data.

Remote SDK/service initialization must either execute outside the blocking
local-shell critical path or have an application-owned bounded failure path.
Supabase startup/service initialization has a six-second target deadline.
Missing configuration and returned initialization failure continue to leave
backend-dependent features safely unavailable while local features remain
usable.

Remote initialization that completes after the shell starts must update the
existing dependent services safely without requiring an application restart
where practical. This work must use the existing dependency container. If
safe late initialization proves impossible without a parallel container or a
major uncontracted architecture redesign, implementation must stop with:

`ARCHITECTURE CONTRADICTION — ARCHITECT DECISION REQUIRED`

Production credential, environment, deployment, and health validation remain
V1-R14 responsibilities.

## 6. Application-Owned Timeout Policy

Every material V1 remote operation must terminate through an application-owned
time bound. The frozen V1 target deadlines are:

| Operation class | Target deadline |
| --- | ---: |
| Remote startup/service initialization | 6 seconds |
| Ordinary network and RPC reads | 15 seconds |
| Remote mutations, sign-out, profile writes, and business/staff mutations | 20 seconds |
| Supabase credential exchange after Google credentials are obtained | 20 seconds |
| Initial connectivity platform check | 3 seconds |

The human Google account-picker or consent interaction must not time out merely
because the user takes time to respond. The 20-second authentication deadline
begins around the network/service credential exchange after Google credentials
have been obtained.

A timeout must:

- map to a typed safe state;
- release loading and busy state;
- preserve any valid state whose retention is already safe;
- permit an intentional manual retry when appropriate; and
- never be presented as success, empty authority, permission denial, or
  definitive authentication loss.

No material V1 network operation may leave a screen or mutation indefinitely
loading or busy.

## 7. Common Infrastructure Failure Classification

Introduce one small common request/infrastructure failure classification that
distinguishes at least:

- offline or transport unavailable;
- timeout;
- network or transport request failure;
- service unavailable;
- malformed response; and
- unknown.

Feature-specific error models may wrap or map this classification. It must not
replace domain-specific causes such as unauthenticated, permission denied,
ownership conflict, invalid transition, optimistic-concurrency conflict, or a
known SQLSTATE/domain denial.

Malformed server data must not be classified as a network failure. Unknown
exceptions must not all be classified as network failures. Raw exception
details remain internal diagnostics only.

## 8. Raw Error Policy

No raw exception text may reach production user UI. Forbidden user-facing
output includes:

- `exception.toString()` or `error.toString()`;
- `PostgrestException.message` or `AuthException.message`;
- raw SQLSTATE values; and
- backend, transport, or parser implementation messages.

Production UI must use safe localized presentation. Existing appropriate
logging may retain diagnostic detail. The current encyclopedia provider/widget
path that renders `e.toString()` must be corrected in V1-R09.

## 9. Read Retry Policy

Manual retry remains available for retryable network and read failures.
Automatic retry is not globally enabled.

An `unavailable` to `available` transport transition may trigger one bounded
automatic refresh only when all of these conditions hold:

- the operation is idempotent and read-only;
- its provider or screen is active, or it holds a retryable stale/error state;
- at most one refresh is launched for the relevant reconnect transition;
- no retry storm can occur;
- account-bound work validates the current identity and auth/session
  generation; and
- request-generation and stale-completion protections remain effective.

Initial reconnect automation must be conservative. It should prioritize the
public Directory and only clearly safe, currently visible idempotent reads
whose integration is straightforward. It must not be forced across every
feature.

## 10. Mutation Retry Policy

Blind automatic mutation retry is forbidden. Writes remain explicit user
actions unless an existing operation has a concretely proven idempotent
contract.

This prohibition includes profile save, application submit/resubmit, business
management mutation, staff actions, and authentication/sign-out side effects.
Existing single-flight, concurrency, optimistic-concurrency, and
server-transition guards remain mandatory. A timeout or failure must release
the busy state and allow a deliberate manual retry where safe; it must never
produce fake success.

Reconnect must never replay, submit, or mutate user data automatically.

## 11. Public Directory Cache-First Contract

The public Directory must become truly cache-first. Its required load sequence
is:

1. read and validate the persistent cached snapshot;
2. publish a valid snapshot immediately;
3. start a bounded cloud refresh;
4. after successful authoritative refresh, replace both cache and
   presentation; and
5. after refresh failure, retain the valid snapshot and present it as stale.

A valid cache must not remain hidden behind an awaited remote refresh. A
successful authoritative empty refresh replaces the old snapshot. Failed or
partial refresh must not destroy the last valid snapshot. Malformed cache
remains fail-closed.

Presentation must distinguish:

- loading with no cache;
- fresh data;
- fresh empty;
- stale data;
- stale empty; and
- unrecoverable error with no usable cache.

A valid stale empty snapshot must never render an indefinite spinner.

## 12. Stale Data Presentation

Cached/stale Directory content must be explicitly distinguishable from fresh
authoritative data with a localized stale/offline notice. Exact cache age or a
user-facing timestamp is not required for V1. Existing `refreshedAt` metadata
may remain internal. Stale data must never be portrayed as freshly confirmed.

## 13. Authentication During Network Loss

All V1-R08 security semantics remain authoritative. Temporary transport,
timeout, or backend failure must not by itself:

- clear a locally restored authenticated session;
- advance identity to guest;
- expose guest-local data as authenticated-profile fallback;
- reset account ownership; or
- bypass second-account conflict protection.

A cached/current Supabase session may remain the canonical local session while
backend validity is temporarily unverifiable. Definitive accepted auth
lifecycle events—including signed out, user removed, or equivalent
authoritative loss—continue to control session loss.

Failed authoritative sign-out leaves the user authenticated. Connectivity
state must never cause sign-in, sign-out, session replacement, or account reset.

## 14. Account-Bound Retry and Result Safety

Every account-bound delayed retry or result introduced by V1-R09 must validate:

- current authenticated identity;
- current auth/session generation; and
- provider/request generation where applicable.

An old-session retry or completion must never publish into a new account.
Reconnect behavior must preserve all accepted V1-R08 account-bound reset,
ownership-conflict, and stale-result guarantees.

## 15. Backend-Authoritative Feature Behavior

V1-R09 does not create durable offline authority for:

- authenticated cloud profile;
- applications and claim targets;
- managed businesses or business profile management; or
- staff queue, detail, capabilities, or actions.

When backend or network access is unavailable, these features must terminate
loading, show a safe localized offline/network/timeout/unavailable state,
preserve valid existing in-memory state where that is already safe, and offer
manual retry when appropriate.

Authenticated profile must never fall back to `LocalUserProfile`. Backend data
or permissions must not be fabricated from stale or missing responses.

## 16. Encyclopedia and Network Images

Packaged encyclopedia catalog and text remain fully local. V1-R09 must remove
raw exception presentation, use a safe localized error state, and ensure that
network-image failure does not block locally available text or content.

The phase must not add a backend dependency to packaged encyclopedia content.
Guaranteed offline retention of arbitrary remote images is out of scope.

## 17. Loading, Error, Empty, and Unavailable States

Material V1 screens must not remain indefinitely loading or busy because of a
network request. Network-backed features distinguish, where relevant:

- loading;
- empty;
- offline/network failure;
- timeout;
- service unavailable;
- permission or authentication failure;
- malformed or unexpected failure; and
- stale/cached state.

Not every state requires a unique design. Reuse `ErrorStateWidget`,
`EmptyStateWidget`, `AsyncValueWidget`, and existing warning/notice patterns.
The application must not be replaced by a global backend-unavailable page.

## 18. Reconnect Rules

An `unavailable` to `available` transition is a transport signal only. It may
launch the bounded eligible read refresh described in Section 9. It must not:

- replay mutations or submit forms;
- perform staff or business actions;
- clear authentication errors as if backend success were proven; or
- claim Supabase reachability.

If the refresh fails, the feature remains in its correct stale or error state.

## 19. Dependency and Server Boundary

No new dependency is authorized. Reuse `connectivity_plus ^6.1.0`.
Specifically, do not add an internet checker, second connectivity plugin,
background-sync framework, or offline database framework unless the Architect
reopens this contract.

Database decision: `OPTION A — NO DATABASE MIGRATION REQUIRED`.

V1-R09 adds no migration `00022`, schema change, RLS change, Edge Function,
Storage integration, or Realtime adoption. If implementation finds a genuine
database requirement, it must stop with:

`DATABASE CONTRACT CONTRADICTION — ARCHITECT DECISION REQUIRED`

## 20. Mandatory Scope

V1-R09 MUST deliver:

1. canonical injectable transport authority;
2. explicit unknown/available/unavailable state;
3. safe connectivity initialization and stream lifecycle;
4. non-blocking local-first startup;
5. application-owned network timeouts;
6. common infrastructure failure classification;
7. no raw exception UI;
8. finite loading and busy states;
9. Directory immediate-cache and bounded-refresh flow;
10. stale-empty Directory correction;
11. safe manual retry behavior;
12. conservative reconnect refresh for eligible reads;
13. localized offline, timeout, and unavailable UX;
14. preservation of R08 session and ownership guarantees; and
15. focused offline, startup, timeout, reconnect, cache, and session tests.

## 21. Recommended Scope

Where low-risk and directly useful, V1-R09 SHOULD:

- reuse one consistent global offline transport indicator;
- normalize retry and error copy;
- make the existing connectivity provider fully testable;
- handle network-image failure gracefully; and
- use common mapping helpers to reduce duplicated transport classification.

These items must not expand the phase into a rewrite.

## 22. Deferred to V1-R14

The following remain V1-R14 responsibilities:

- production Supabase credential validation;
- production deployment health checks;
- monitoring and observability rollout;
- production environment verification;
- server performance and load tuning;
- broad RLS/schema readiness work; and
- existing deferred DEV server QA.

## 23. Explicitly Out of Scope

V1-R09 excludes:

- offline mutation queues;
- background synchronization engines;
- conflict-resolution engines;
- multi-account local workspaces;
- ownership reset or transfer;
- replacement or weakening of R08 identity semantics;
- Supabase Storage, Edge Functions, or Realtime adoption;
- broad visual redesign; and
- guaranteed caching of arbitrary remote images.

## 24. Implementation Partition

### Part 1 — Infrastructure / Foundation

Preferred implementer: Codex.

Part 1 owns connectivity abstraction/provider, startup resilience, timeout
infrastructure, common failure classification, auth/network-loss protection,
base reconnect semantics, and focused infrastructure tests.

### Part 2 — Feature Integration / UX

Preferred implementer: Codex.

Part 2 owns Directory cache-first behavior, stale-empty handling, encyclopedia
safe errors, feature-level offline/timeout UX, selected reconnect integration,
localization, and focused widget/integration tests.

Part 2 must not begin until Part 1 passes independent focused review.

## 25. Test and Gate Policy

Implementation and correction passes use focused tests only. Do not run the
full repository suite during Part 1 or Part 2 implementation/correction.

Part 1 must prove at minimum:

- unknown/available/unavailable transport transitions;
- safe initial-check timeout and stream error behavior;
- disposal and absence of competing connectivity sources;
- local shell availability under missing, failed, and slow remote startup;
- timeout classification and release of loading/busy state;
- temporary network failure does not clear a restored session; and
- account/session generation rejects stale retry results.

Part 2 must prove at minimum:

- immediate Directory cache publication before refresh completion;
- fresh, fresh-empty, stale, stale-empty, and no-cache error behavior;
- failed refresh retains a valid cache;
- one bounded eligible refresh per reconnect transition;
- reconnect never replays a mutation;
- encyclopedia UI never renders raw exception text;
- localized offline/timeout/unavailable presentation; and
- local text/content remains usable when remote images fail.

After Part 1 independent acceptance, Part 2 may begin. After Part 2 independent
acceptance, run one integrated V1-R09 full Flutter suite. The known analyzer
environment issue remains non-gating unless the environment changes. Do not
patch or repair the Flutter SDK/cache.

## 26. V1-R08 Protection

V1-R09 explicitly preserves:

- the canonical `AuthProvider` architecture;
- auth epoch/session generation;
- the Supabase auth event subscription;
- authoritative sign-out semantics;
- second-account fail-closed behavior;
- coordinated account-bound provider resets;
- cloud profile as authenticated-profile single source of truth;
- strict cloud profile parsing;
- profile-save single-flight behavior;
- authoritative post-write reread;
- secure return-destination handling; and
- reactive definitive session loss.

Any implementation that requires weakening or changing one of these guarantees
must stop with:

`R08 CONTRACT CHANGE REQUIRED — ARCHITECT DECISION REQUIRED`

## 27. Stop Conditions

Implementation must stop and return the exact applicable contradiction when:

- safe late initialization requires a parallel dependency container or major
  uncontracted architecture redesign:
  `ARCHITECTURE CONTRADICTION — ARCHITECT DECISION REQUIRED`;
- a database, schema, RLS, migration, Storage, Function, or Realtime change is
  genuinely required:
  `DATABASE CONTRACT CONTRADICTION — ARCHITECT DECISION REQUIRED`; or
- an accepted V1-R08 security guarantee must change:
  `R08 CONTRACT CHANGE REQUIRED — ARCHITECT DECISION REQUIRED`.

## 28. Completion Conditions

V1-R09 is not complete merely because code exists. Closure requires both
implementation parts to pass their independent reviews, the final integrated
V1-R09 Flutter suite to pass, documentation and roadmap evidence to be updated
under a later authorized gate, and no unresolved contract contradiction to
remain.

This freeze authorizes implementation only. It does not mark V1-R09 closed.

---

## C3 CONTRACT ADDENDUM A — Architect Authorized

Effective contract: **V1-R09-CONTRACT-v1 + C3-ADDENDUM-A**.

The original frozen contract above is preserved. This architect-authorized
addendum applies only to V1-R09 Part 1 C3 credential-exchange recovery. C1 and C2
remain accepted; C4 and Part 2 remain locked. Roadmap phase controls are unchanged.

### C3-A — Explicit Quarantined Device Sign-In Reset

An interrupted credential exchange can leave SDK persistence whose ownership
cannot be attributed to that exchange using public SDK evidence. Such evidence
must not be admitted, guessed, automatically deleted, or remotely revoked.
Recovery enters the durable `credentialExchange / blockedUnattributed` state.

Only an explicit user action, **Reset sign-in on this device**, authorizes local
removal of that quarantined SDK auth persistence. This is the sole exception to
identity-correlated recovery deletion. It is scoped to the existing SDK auth
storage delegate, never another token store or application-data storage.

Inside the single recovery queue, an active owned transaction must validate the
operation type and blocked-unattributed phase, read the exact quarantined bytes,
and re-read them immediately before deletion. A changed snapshot is preserved;
the action fails blocked and requires reinspection. Captured bytes remain in
memory only. No token or snapshot is written to the recovery journal or logs.

The reset must never call SDK `auth.signOut`, `admin.signOut`, or any remote
revocation. It does not delete an account, cloud/profile/business data, projects,
other local Civilpedia data, or another device's session. Unknown SDK memory is
not cleared by a destructive SDK call.

After local removal and verified persistence absence, the SAME operation is
durably updated to `localResetAppliedRestartRequired`. Account authority and
fresh sign-in stay blocked in the current process. Localized AR/EN copy must
explain that local sign-in is removed, the user must restart and sign in again,
and cloud accounts/data and other-device sessions are not deleted or revoked.

Only a fresh normal startup may finalize this record, after confirming both
persisted auth absence and null current SDK session. Any unexpected session or
snapshot returns to blocked-unattributed recovery without automatic deletion.
Failed deletion, phase persistence, or finalization always remains blocked.

### C3 correction invariants

One exchange retains its operation ID, type, and creation time through active,
timed-out-pending, exact-identity neutralization, cleanup-required, and verified
completion. Phase/correlation upgrades replace the same journal record in one
acknowledged owned write; there is no delete-and-recreate handoff. Raw exchange
outcomes and settlement failures remain distinct. In-time admission requires
pre/post completion validation and a single-use non-secret commit receipt.
All live raw mutations remain observed and single-flight after application
timeouts. Ordinary C1/C2 conditional deletion and bounded observed cleanup are
unchanged; this explicit local reset does not grant a generic removal capability.
