# CIVILPEDIA V1-R08 — AUTH + PROFILE PRODUCTION COMPLETION CONTRACT

PHASE: V1-R08
TITLE: Auth + Profile Production Completion
CONTRACT: V1-R08-CONTRACT-v1
STATUS: FROZEN
IMPLEMENTATION_AUTHORIZED: YES

## 1. Authority and Scope

This contract is the authoritative implementation boundary for V1-R08. The
phase completes the existing Google/Supabase authentication and personal
profile foundations for production use. It does not introduce a second
identity system, a second auth state manager, or a second authenticated profile
source of truth.

The frozen authentication flow is:

Google Sign-In → Google ID token → Supabase `signInWithIdToken` → canonical
`auth.users.id` identity.

Canonical human identity and personal-profile ownership come exclusively from
`auth.uid()` / `auth.users.id`. Google email, auth metadata, profile
`role_code`, business memberships, staff memberships, and local device profile
data never grant account authority. Flutter must never use `service_role`.

## 2. Existing Components to Extend

Reuse and extend the existing `AuthGateway`, `SupabaseAuthGateway`, and
`AuthProvider`. `AuthProvider` remains the single canonical Flutter session
authority. Reuse the existing guest ownership registry and claim algorithm,
personal-profile bootstrap, region-preference foundation, profile provider,
routes, User Area, `ProfileEditScreen`, and `AppDependencies` wiring where
their current responsibilities remain valid.

Do not create parallel auth, profile, session-listener, identity, ownership, or
region systems.

## 3. Auth Lifecycle State

The canonical auth state must distinguish enough behavior for:

- initial/session restoration;
- guest;
- sign-in pending;
- authenticated;
- sign-out pending;
- recoverable authentication failure; and
- local ownership/account conflict.

Exact internal types may follow established project conventions. Provider
operations must have domain-level concurrency guards; disabling a UI button is
not sufficient.

## 4. Supabase Auth Event Stream

Extend the existing auth gateway with one bounded stream of canonical Supabase
auth/session events. The existing Supabase client is the event authority. The
integration must handle the events relevant to the current Google-only model:

- restored or initial session;
- signed in;
- signed out;
- token/session refresh;
- session removal, expiration, or revocation; and
- authenticated user/session replacement.

`AuthProvider` must reconcile startup restoration with this stream and must no
longer depend only on a one-time `currentSession` read. Native Google ID-token
authentication does not require callback/deep-link auth architecture, so none
is added in V1-R08.

## 5. Canonical Session Generation

V1-R08 introduces one application-wide session generation/auth epoch. It
changes whenever the canonical authenticated identity changes or the session
becomes signed out. Account-bound asynchronous operations capture the active
user and generation and may publish a result only while both still match.

Work started for user A must never restore data after user A signs out, the
session expires or is revoked, user B replaces user A, or a second-account
ownership conflict blocks user B. Feature-specific providers may use request
sequencing internally, but those sequences must bind to the one canonical auth
generation rather than becoming competing session authorities.

## 6. Sign-In Contract

Only one Google/Supabase sign-in may run at a time. Repeated provider calls
while sign-in is pending must reuse or reject the pending operation and must
not start another provider flow, guest claim, or profile bootstrap.

Cancellation returns safely without a user-facing failure. Configuration,
retryable provider/network failure, sign-in failure, ownership conflict, and
unexpected failure use typed causes and localized presentation. Raw
Google/Supabase/backend error text must not be shown.

## 7. Sign-Out and External Session Loss

Explicit sign-out follows this order:

1. enter sign-out pending state;
2. call the canonical remote sign-out path;
3. wait for authoritative confirmation or the reconciled signed-out auth
   event; and
4. transition to guest, advance the session generation, and complete
   account-state reset.

The app must not claim guest state before remote sign-out succeeds. On failure,
it retains or re-resolves the authoritative Supabase session, exposes a
localized recoverable failure, and permits retry. The failure is not swallowed.

Session loss outside explicit sign-out follows the same privacy boundary.
Expiration, revocation, external sign-out, or session removal transitions away
from authenticated state, advances the generation, clears account-bound
state, and causes protected routes to fail closed.

## 8. Account-Bound State Reset

Confirmed identity or session changes must clear or invalidate every provider
that holds authenticated-user data, including at minimum:

- `UserProfileProvider` authenticated state;
- business applications;
- claim targets;
- managed businesses;
- business-profile editor state;
- staff access, queue, and detail state;
- post-auth claim/bootstrap state; and
- User Area account-specific state.

Providers must prevent old futures from repopulating state after reset. This is
session/privacy hardening only; it does not redesign general offline caches.

## 9. Second Account on One Device

V1-R08 does not implement multiple local ownership workspaces. If the local
ownership registry is bound to user A and user B authenticates on the device:

- do not rebind, merge, transfer, or claim user A's local data;
- do not display user A's local profile to user B;
- do not bootstrap user B from user A's local profile;
- do not enter normal authenticated account UI for user B;
- expose an explicit blocking local-ownership/account conflict; and
- sign out or otherwise neutralize user B's temporary Supabase session.

If temporary-session cleanup fails, remain in a blocking conflict/recovery
state with no account-private data rendered until the authoritative session is
resolved. Ownership reset or transfer UI is outside this phase.

## 10. Guest Ownership Claim Lifecycle

Keep the existing stable keys, atomic sidecar registry, idempotent claim,
same-owner behavior, different-owner refusal, and corrupt-registry fail-closed
behavior unchanged.

The post-auth sequence is:

1. authentication succeeds;
2. the canonical session generation is established;
3. guest/local ownership claim runs; and
4. canonical personal-profile bootstrap runs.

This sequence is observable and is no longer fire-and-forget. It represents
running, success, retryable failure, ownership conflict, and corrupt/fail-closed
local ownership where applicable. An old-generation result is ignored.

## 11. Canonical Personal Profile

For an authenticated user, `public.profiles` is the sole operational personal
profile source of truth, keyed by `profiles.user_id = auth.uid()`. Cloud profile
data drives authenticated profile display and editing. A successful mutation
is followed by an authoritative cloud reread before canonical state is
replaced or success is reported.

`LocalUserProfile` may remain the guest/local preference model. It must not act
as authenticated profile authority and must not cross account boundaries.

Legacy `BaghdadArea` remains guest/local compatibility data only. It cannot
override or substitute for an authenticated canonical region preference and
must not leak between accounts.

## 12. Profile Provisioning

Retain one race-safe lazy provisioning/bootstrap strategy; do not add a
database trigger in parallel. Provisioning derives the owner from the active
authenticated session and ensures that a user can obtain one canonical own
profile row even when no local profile exists. It uses existing database
defaults/nullability and only existing approved Google metadata mappings.

Provisioning remains idempotent and duplicate-safe. If the existing schema
requires a value with no safe established default, implementation stops with:

`PROFILE PROVISIONING CONTRACT CONTRADICTION — ARCHITECT DECISION REQUIRED`

## 13. Cloud Profile Read Contract

Authenticated profile reads target the current session's own row; UI callers
cannot provide an arbitrary owner ID. Parsing is strict. Malformed authority or
projection fields fail closed and must not produce a fabricated usable profile
or fall back to a different user's local profile.

The profile state supports resolving/loading, loaded, provisioning/empty where
applicable, retryable error, malformed response, permission/session loss, and
ownership conflict.

## 14. Frozen Editable Fields

Authenticated V1-R08 profile editing is limited to:

1. professional role through the existing canonical `role_code`; and
2. canonical region preference through the existing
   `region_preferences` code/ID relationship.

`role_code` is descriptive only and never grants staff, admin, business
ownership, business-management, or route authority. Unknown role values fail
safely to non-privileged presentation behavior.

The following are not promoted to editable cloud fields in V1-R08:

- display name;
- phone;
- company;
- title;
- `logoPath`;
- arbitrary email; and
- avatar/photo.

Google/Supabase display name, email, and existing photo metadata may be shown
read-only where already supported.

## 15. Cloud Profile Save Contract

Profile save uses the existing RLS-backed own-row boundary and accepts no
arbitrary owner identity from UI code. It validates canonical role and region
values before mutation and provides:

- save-in-flight and duplicate-save guards;
- typed and localized failure state;
- stale-session result suppression;
- authoritative reread after server success;
- dirty reset only after authoritative reread succeeds; and
- an unsaved-change navigation guard.

Do not manually patch local state as final authenticated authority. Do not add
an optimistic-concurrency version column; server write followed by
authoritative reread is the frozen V1 behavior.

## 16. Region Authority

Reuse the existing canonical `region_preferences` reference set and stable
code-to-ID resolution. Keep it separate from physical `regions` and legacy
`BaghdadArea`. No new region source of truth or R08 region schema is permitted.

## 17. Protected Route Policy

One central auth-resolution policy applies to current routes that genuinely
require authentication. Public app, Encyclopedia, Directory browsing, and
Tools routes remain public.

- While auth is resolving, protected account content is not rendered and no
  private-data flash is permitted.
- A guest opening a protected route is sent to the auth-required flow.
- An authenticated user may continue; server RLS/RPC authorization remains the
  final authority.
- Session loss while a protected screen is open fails closed and removes
  private content.

Staff capability checks and business authorization continue independently
after authentication.

## 18. Return Destination Security

When authentication begins from a protected route, successful authentication
returns to the intended route only when it is an internal, recognized,
allowlisted, syntactically valid authenticated navigation target. Reject
absolute external URLs, arbitrary schemes, malformed paths, and unrecognized
redirect strings. If no valid return destination exists, use `/user/profile`.

Returning to `/staff/applications` does not grant staff authority; the existing
staff capability boundary still applies.

## 19. Auth and Profile Error Contracts

The minimal typed auth error model distinguishes cancellation,
configuration/unavailable, retryable network/provider failure, sign-in
failure, sign-out failure, session expired/lost, local ownership/account
conflict, and unexpected failure.

The typed profile operation model distinguishes unauthenticated/session lost,
permission denied, invalid canonical data, malformed response, retryable
network/backend failure, provisioning failure, local ownership/account
conflict where applicable, and unexpected failure.

Neither model exposes raw provider, token, PostgREST, or backend messages.

## 20. User Area and Profile UX

Authenticated User Area identity comes from the active auth session; personal
profile state comes from the canonical cloud profile. It supports resolving,
profile loading, profile available, retry/error, sign-out pending/error, and
guest states without displaying prior-account local fields.

The current non-persisting name edit must be removed, disabled, or presented as
read-only. Name editing is not added to canonical profile scope.

Profile UI receives production loading, retry, validation, save-pending,
failure, malformed-profile, permission/session-loss, success-after-reread, and
unsaved-navigation states. V1-R08 does not redesign the visual system.

## 21. Database Contract

Database assessment: `OPTION A — NO MIGRATION REQUIRED`.

Existing `public.profiles` supplies one row per `auth.users` identity,
primary-key ownership, own-row SELECT/INSERT/UPDATE RLS, canonical professional
role constraints, canonical region-preference FK, duplicate prevention, and no
profile DELETE grant. V1-R08 stays inside those constrained columns and
preserves `auth.uid()` ownership.

If implementation proves a schema or migration change unavoidable, stop with:

`DATABASE CONTRACT CONTRADICTION — ARCHITECT DECISION REQUIRED`

Do not create migration `00022` silently and do not modify earlier migrations.

## 22. Security Invariants

V1-R08 must preserve and test:

- own-row profile SELECT, INSERT, and UPDATE;
- cross-user profile access denial;
- invalid role and region rejection;
- no profile delete grant;
- no Flutter `service_role` path;
- no caller-controlled owner authority;
- no authorization derived from profile role;
- no stale-session or old-generation result publication;
- no user A data visible or actionable for user B;
- no false guest state after failed remote sign-out;
- no protected-route private-data flash;
- no old-session bootstrap result; and
- no account-conflict bypass.

## 23. Explicit Exclusions

V1-R08 excludes email/password registration or authentication, forgot
password, password recovery/reset, email verification/resend, additional
social providers, phone auth, MFA, SSO, avatar upload or Storage work, account
deletion, multi-account local workspaces, ownership reset/transfer UI,
generalized identity or admin-user management, impersonation, staff-role
management, business membership/profile management, generalized offline sync,
broad connectivity or global-cache redesign, analytics, notifications, and
subscriptions/payments.

Password recovery is deferred and not required for V1-R08. Email verification
is not required by the current Google-only product auth model. Personal avatar
upload and account deletion are deferred. V1-R09 owns general offline,
connectivity, and error-state hardening.

## 24. Verification Contract

### Server and Security

Verify own-profile SELECT/INSERT/UPDATE, cross-user denial, invalid role and
region rejection, no profile delete grant, no client service-role path, and no
migration drift.

### Auth and Session

Cover startup restoration, guest and authenticated restoration, signed-in and
signed-out events, token refresh, expired/revoked sessions, duplicate sign-in
guard, successful and failed sign-out, user A sign-out, user A to user B
protection, stale future suppression, second-account conflict and temporary
session neutralization, plus guest-claim idempotency, retry, and stale-result
suppression.

### Profile

Cover provisioning with no local profile, duplicate-create races,
cloud-authoritative read, strict malformed projection rejection, role and
region validation, save and duplicate-save guards, save then authoritative
reread, failed-save state preservation, session replacement during read/save,
and exclusion of guest local state from authenticated authority.

### Routing and Widgets

Cover protected deep links while resolving and guest, absence of private-data
flash, allowlisted return navigation, rejection of invalid/external returns,
`/user/profile` fallback, session loss on protected screens, profile
loading/error/retry, unsaved edit guard, sign-out pending/error, and prior-user
profile exclusion.

Use focused tests during implementation. Run the complete repository suite
once at the integrated V1-R08 phase gate because shared auth/provider/router
architecture changes.

## 25. Sequential Implementation Split

### Part 1 — Codex

Implement and verify the security/session architecture: Supabase auth events,
`AuthProvider` lifecycle, sign-in/sign-out concurrency, canonical session
generation, account-bound reset and invalidation, observable claim lifecycle,
second-account conflict handling, canonical cloud profile gateway/provider
authority, provisioning/read/save foundations, protected-route and return-route
security foundations, and focused security/session/domain tests.

### Part 2 — Big Pickle / Kimi

After independent acceptance of Part 1, complete production UX on that
foundation: Auth screen states and retry, profile display/edit, User Area,
dirty and unsaved guards, localized errors, return-navigation UX, loading and
retry states, and focused widget/routing tests.

Part 2 must not begin until Part 1 is independently reviewed and accepted.
