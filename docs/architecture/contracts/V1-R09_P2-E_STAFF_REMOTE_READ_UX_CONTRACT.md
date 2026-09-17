# CIVILPEDIA V1-R09 PART 2 — P2-E STAFF REMOTE READ UX CONTRACT

PHASE: V1-R09 Part 2
SLICE: P2-E — Staff Remote Read UX
CONTRACT: V1-R09-P2-E-CONTRACT-v1
STATUS: FROZEN
ARCHITECT DECISION: FROZEN (RATIFIED WITH AMENDMENTS)
IMPLEMENTATION_AUTHORIZED: YES after this contract is persisted (P2-E1 only)

## 1. Authority and Purpose

This contract persists the accepted, Architect-ratified P2-E architecture
inspection proposal for the Staff remote-read surface and its lifecycle
safety. It is the authoritative implementation boundary for V1-R09 Part 2
slice P2-E.

It layers on V1-R09-CONTRACT-v1, on the closed P2-B slice, on the closed P2-C
slice, on the closed P2-D slice, and on the closed V1-R07 Staff foundation.
Everything in the parent and prior slice contracts that is not changed here
remains in force. V1-R08 authentication, identity, ownership, and
account-bound guarantees are preserved unchanged.

Supabase remains the server authority for all Staff reads. AuthProvider
remains the only session authority. `staff_memberships`,
`role_permissions`, and `permissions` remain the Staff access authority, and
the frozen migration-00021 Server RPCs remain the authoritative read
projections.

The Architect Amendments ratified with this freeze are applied verbatim and
are recorded as an Appendix to this contract. They take precedence over any
conflicting language inherited from the proposal.

## 2. Staff Domain / Authority

P2-E covers the Staff remote-read surfaces for business-application
administration:

- capability resolution (`get_staff_application_capabilities()`);
- application queue (`list_staff_business_applications(...)`);
- application detail (`get_staff_business_application_detail(uuid)`);
- the READ facets of the Staff detail/queue providers: the post-mutation
  authoritative detail reread and the post-mutation queue refresh.

It excludes:

- all Staff mutation RPCs (`staff_begin_application_review`,
  `staff_return_application_for_correction`,
  `staff_mark_application_contacted`,
  `staff_schedule_application_visit`,
  `staff_approve_business_application`,
  `staff_reject_business_application`,
  `staff_activate_business_application`), their transition matrix, deposits,
  permission codes, and audit behavior;
- A6.3 / A6.4 activation and provisioning;
- `staff_memberships` administration and any RLS/grant/DML;
- public Directory browsing / directory cache;
- legacy `sb_profiles` / local service-business models.

Authority:

- AuthProvider = session authority; all Staff RPCs derive the actor
  server-side from `auth.uid()` (SECURITY DEFINER performs the resolution;
  there is no caller-supplied actor argument);
- `staff_memberships` (active, effective, unexpired) → `role_permissions` →
  `permissions.code` = Staff permission authority (`has_staff_application_permission`);
- `get_staff_application_capabilities()` = capability proclamation
  (an empty `permissions` array is the authoritative no-read-permission
  proclamation);
- `list_staff_business_applications(...)` = authoritative queue projection
  (empty JSON items = authoritative empty queue; keyset `(created_at, id)`
  cursor pagination; bounded page size 1..50; frozen status/type filters);
- `get_staff_business_application_detail(uuid)` = authoritative detail
  projection (`P0NOT` = global absence of the application or of its canonical
  CLAIM target entity — SECURITY DEFINER means there is no hidden-row category
  and no RLS-shading; `P0PER` = authorized-actor-scope denial);
- `directory_entities.id` = canonical Business identity for CLAIM targets
  (the working directory `directory_entities` public authority never doubles
  as a Staff read fallback);
- `business_applications.id` = canonical application identity.

## 3. Staff READ Channels and the Renamed Failure Variant

Staff READ outcomes resolve into TWO distinct channels:

1. DOMAIN channel (preserved): `StaffReadDenied(cause)` using the existing
   `BusinessApplicationStaffCause`. The following domain causes stay in this
   channel exactly as today:
   - `P0AUT` → `unauthenticated`;
   - `P0PER` → `staffPermissionDenied`;
   - `P0NOT` → `applicationNotFound`;
   - `P0DAT` → `requiredDataMissing` — AMENDMENT 2: P0DAT remains the existing
     Staff domain cause and is NEVER mapped to `malformedResponse`.
   - the mutation-only causes (`invalidTransition`,
     `correctionReasonRequired`, `rejectionReasonRequired`) remain
     domain-only and are not used by read classification.

2. REMOTE FAILURE channel (renamed per AMENDMENT 1): the new remote failure
   variant is `StaffRemoteReadFailure(kind)` carrying
   `StaffRemoteReadFailureKind`:

   ```
   enum StaffRemoteReadFailureKind {
     network,
     timeout,
     serviceUnavailable,
     malformedResponse,
     permissionDenied,
     authRestricted,
     unexpected,
   }
   ```

   The variant is deliberately named away from any "InfrastructureFailure"
   form. It carries remote, auth-policy, and read-boundary failures.

   The Staff RPC/domain denials remain DOMAIN outcomes and are NOT globally
   mapped into this enum: `P0AUT` remains the existing Staff domain auth
   denial where the specific RPC proves that meaning; `P0PER` remains the
   existing Staff domain permission denial where the specific RPC proves that
   meaning; `P0NOT` remains the existing Staff domain absence outcome where
   applicable; `P0DAT` remains `requiredDataMissing` in `StaffReadDenied`.
   The exact source/RPC semantics decide whether a signal stays a Staff domain
   outcome; there is no global P0AUT/P0PER → remote-enum mapping.

`StaffReadUnavailable` (feature backend not initialized) is preserved as a
distinct outcome and is not a failure kind.

`authoritativeEmpty` (queue) and `authoritativeNotFound` (detail `P0NOT`) are
successful authoritative absence outcomes, not failures.

The data layer NEVER emits `offline`.

Canonical deadline: `RemoteOperationPolicy.read` = 15 seconds at the Staff
data boundary.

## 4. Source-Aware Classification

Mapping is narrow and source-aware — each signal is mapped from the encounter
semantics of the specific frozen Staff RPC, never from blanket rules:

- connection/transport client failures (`SocketException`,
  `HandshakeException`, `HttpException`, `ClientException`, recognized
  transport error shapes) → `StaffRemoteReadFailureKind.network`;
- read deadline / `TimeoutException` under `RemoteOperationPolicy.read`
  (15 s) → `StaffRemoteReadFailureKind.timeout`;
- `08xxx`, `53xxx`, verified `PGRST000..PGRST003` → `StaffRemoteReadFailureKind
  .serviceUnavailable`;
- `42501` → `StaffRemoteReadFailureKind.permissionDenied`;
- `PGRST301..PGRST303` → `StaffRemoteReadFailureKind.authRestricted` ONLY where
  JWT/session semantics are verified;
- auth-specific HTTP / status `401` → `StaffRemoteReadFailureKind.authRestricted`
  where proven;
- generic PostgREST code `"401"` → NOT blanket-mapped to `authRestricted`;
- literal PostgREST code `"503"` → `StaffRemoteReadFailureKind.unexpected`
  unless it is proven to be a real HTTP transport status rather than a
  PostgREST code string;
- strict required-row parsing failure, invalid / non-map response shape,
  or `FormatException` / `TypeError` response shape → `StaffRemoteReadFailureKind
  .malformedResponse`;
- requested canonical application id mismatch on detail → `StaffRemoteReadFailureKind
  .malformedResponse` (see Section 6);
- `PGRST116` / `406` / `"200"`-shape → `StaffRemoteReadFailureKind
  .malformedResponse` only when the encountered source semantics are verified;
- `P0AUT` / `P0PER` / `P0NOT` / `P0DAT` → DOMAIN causes (Section 3), never
  remote kinds; there is no global P0AUT/P0PER → remote-enum mapping;
- unknown or unproven exception/code → `StaffRemoteReadFailureKind.unexpected`.

`StaffRemoteReadFailureKind.malformedResponse` remains reserved exclusively
for:

- malformed required response shape;
- malformed required row/field;
- parser / schema-contract violation;
- canonical requested-ID mismatch.

No raw exception / SQLSTATE / PostgREST code / stack-trace text may reach
widgets. Remote widgets receive only the mapped cause. Domain denial-caused
widget state is unchanged.

## 5. Authoritative Absence

- Queue: successful empty (`items: []`) → `authoritativeEmpty`; neutral empty
  state, not a failure, never a mutation trigger.
- Detail: contract-proven `P0NOT` → `authoritativeNotFound` (application or
  its canonical CLAIM target business entity is globally absent; SECURITY
  DEFINER means no hidden-row category, so this is not scoped by RLS).
- Capabilities: empty `permissions` -> authoritative `noReadPermission`
  presentation outcome; distinct from `P0AUT` (no session) and `P0PER`
  (session + permission denied on a specific RPC).

No absence state may:

- create application data;
- submit a mutation;
- trigger provisioning/bootstrap;
- redirect into a workflow implicitly.

## 6. Strict Complete Response + Canonical-ID Validation

- Any malformed REQUIRED row causes the COMPLETE corresponding Staff read to
  fail as `StaffRemoteReadFailureKind.malformedResponse`.
- Do NOT silently skip malformed required rows.
- Do NOT fabricate an empty result from malformed data.
- Known-good same-key data may remain visible during the malformed failure
  (Section 12).

Canonical-ID validation (AMENDMENT 4):

- the detail read MUST verify that the parsed canonical application id equals
  the requested `applicationId`;
- a mismatch → `StaffRemoteReadFailureKind.malformedResponse`; the detail is
  never published under a mismatched identity.

## 7. Coalescing Keys — Separate from Request Epoch

Exact active read/coalescing keys:

- Capabilities: `(userId, authGeneration)`;
- Queue first page: `(userId, authGeneration, status, type)`;
- Queue pagination: `(userId, authGeneration, status, type, cursor)`;
- Detail: `(userId, authGeneration, applicationId)`.

`requestEpoch` is NOT part of these keys.

`requestEpoch` is a separate publication token.

Rules:

- same exact key already active → MAY join/coalesce (no duplicate behind-RPC);
- different key → MUST start independently;
- new underlying logical read → receives a newer `requestEpoch` for that read
  lane;
- repeated manual retry while the exact same key is already active → does not
  launch an unsafe duplicate request;
- User A active read → User B may start independently;
- application/filter key change → starts independently;
- accepted Staff mutation changes the revision → the post-mutation
  authoritative read starts under a new publication token;
- old completion may remove only its OWN matching active handle;
- old completion must never clear an active handle belonging to a newer or
  different key.

Do NOT implement one global Future gate.

## 8. Read Lanes / Epochs

Freeze independent publication lanes:

- capabilities lane;
- queue lane (first page + pagination, one lane);
- detail lane.

A newer underlying request within a lane supersedes older publication.

A late stale result performs ZERO publication, including:

- data;
- empty / notFound / noReadPermission;
- failure;
- loading / finalizer state;
- active-handle cleanup belonging to another request.

Lanes never overwrite each other's phase/state.

## 9. Session / Identity Safety

Every Staff read publication validates:

- provider still alive;
- captured `userId` still current;
- captured `authGeneration` still current;
- AuthProvider current-session guard where applicable;
- matching resource identity (canonical-ID validation, Section 6);
- matching mutation revision where applicable (Section 10);
- current `requestEpoch`.

Sign-out: invalidates Staff read publication; late results publish nothing.

User A → User B: B starts independently; A does not block B; late A cannot
publish/clear B state.

Application switch: old application detail must never appear under the new
application identity.

Dispose: invalidates epochs/active ownership; no late notify/publication.

## 10. Staff Mutation Revision Protection for Queue and Detail

AMENDMENT 4 — Staff mutation revision protection applies to BOTH the detail
and the queue lane providers.

Detail lane:

- an accepted Staff mutation entry supersedes in-flight READ publication: the
  detail provider bumps its read `requestEpoch` at mutation entry, so a stale
  pre-mutation read may NOT publish during `mutating` or after the mutation
  has been accepted;
- the post-mutation authoritative detail reread then owns state;
- the reread publishes under the new token.

Queue lane:

- an accepted mutation commit (via `onMutationCommitted`) performs an
  authoritative queue refresh under a NEW `requestEpoch`;
- a stale queue read may not publish over the refreshed page;
- mutation outcome is never cleared on read failure.

Failure semantics:

- post-mutation reread / refresh failure → recoverable
  `refreshAfterMutationError` presentation; manual retry only; no auto-resend.

Do NOT redesign mutation APIs, retry semantics, call counts, or server
authority.

## 11. Auxiliary-Lane Isolation

AMENDMENT 4 — Staff has NO auxiliary server read lanes:

- the queue filter bar is local widget state; there are NO server
  reference-data reads for Staff;
- P2-E introduces NO auxiliary read lanes and NO background read of any kind.

Auxiliary-lane isolation rules:

- Staff reads never fall back to Directory / cloud-profile /
  Business-owner-provider data;
- no durable Staff cache (Section 17).

If a future Staff auxiliary read becomes genuinely required, it is a new
contract change, not an implementation decision inside P2-E.

## 12. Exact-Key Known-Good Preservation

AMENDMENT 4 — failure must never destroy known-good data for the exact same
read key.

Queue:

- refresh with matching known-good items → lightweight `refreshing` state
  that PRESERVES the items;
- refresh failure → preserve the known-good items + exactly ONE compact typed
  notice + manual retry;
- a full `loading` state clears only on first load, permission-loss,
  sign-in-required, or explicit scope/epoch invalidation;
- `loadMoreError` continues to preserve already-loaded pages.

Detail:

- refresh failure → preserve the known-good detail + exactly ONE compact
  typed notice + manual retry;
- `noData` notices only when NO known-good data exists;
- success replaces ONLY matching-key data and clears the matching failure;
- permission-loss, sign-in-required, and authoritative `notFound` clear the
  lane state (authoritative outcomes, not failures).

Success-replacement rule: success replaces matching known-good data, clears
the matching failure; never crosses into another key.

## 13. Connectivity

Manual retry only. NO:

- automatic reconnect refresh;
- `ReconnectGenerationGate`;
- polling;
- background Staff reads;
- connectivity-triggered read;
- timers.

Staff data layer emits `network`.

Presentation maps:

- `network` + ConnectivityProvider confirmed unavailable (TransportState
  unavailable) → `offline`;
- `network` + available/unknown → `network`.

`offline` is presentation-only; reconnect alone triggers ZERO Staff reads.

## 14. Transport-Banner Non-Expansion

AMENDMENT 4 — `TransportStatusBanner` remains AppShell-owned and is NOT
duplicated.

Staff routes are root routes ABOVE the AppShell (`parentNavigatorKey:
_rootNavigator`), so the banner is not an ancestor of Staff screens. P2-E2
introduces a screen-scoped `StaffRemoteReadNotice` adapter over the shared
`RemoteDataNotice` instead of expanding banner ownership. No shell change is
authorized.

## 15. Localization

AMENDMENT 3 — reuse the shared `RemoteDataNotice` localization:

- all remote-data wording (offline, network, timeout, serviceUnavailable,
  malformed, permissionDenied, authRestricted, unexpected) and the retry
  labels come from the shared widget's `RemoteDataCause` →
  `Ar.notice*` / `En.notice*` and `Ar.retry` / `En.retry` mapping;
- Staff must NOT create a parallel remote-data wording set;
- add ONLY genuinely missing Staff-specific AR/EN keys (for example a Staff
  review-state or Staff action string the shared notice does not provide) —
  no blanket additions;
- new keys, when genuinely required, are added to both `ar.dart` and `en.dart`
  with parity.

AR and EN use the ACTIVE APP LOCALE. No hard-coded Arabic, no `isArabic`
literals, no forced direction. RTL/LTR follows Flutter/app locale.

## 16. main.dart / Scope Boundary

`lib/main.dart` may be modified in P2-E1 ONLY if required for wiring.

Allowed:

- inject existing AuthProvider/session context into existing Staff providers;
- required provider dependency wiring.

NOT allowed:

- Staff read logic;
- classification logic;
- repository authority;
- new SupabaseClient;
- duplicate provider authority;
- timers/background sync.

If wiring is unnecessary, leave `main.dart` unchanged.

`StaffOperationsScope` wiring and cross-provider `onPermissionLost` /
`onMutationCommitted` behavior are preserved.

## 17. Cache / Local State

No new durable Staff cache.

Preserve:

- transient provider memory;
- queue filter-bar local state.

Staff never uses Directory cache, cloud profiles, or Business-owner providers
as a fallback.

## 18. Backend Freeze

AMENDMENT 4 — NO backend change.

No:

- migration;
- schema;
- RLS;
- grant;
- RPC change;
- Edge Function;
- Realtime;
- `service_role`.

Migration 00022 remains absent. No new server API is introduced.

## 19. Internal Partition

### P2-E1 — Typed Staff Read / State / Lifecycle Foundation
STATUS: IMPLEMENTATION_AUTHORIZED: YES after this contract is persisted.

Expected scope:

- the renamed remote failure variant `StaffRemoteReadFailure` +
  `StaffRemoteReadFailureKind` (Section 3);
- Staff source-aware read classification (Section 4);
- `RemoteOperationPolicy.read` (15 s) deadline at the Staff data boundary;
- coalescing keys + request-epoch separation (Sections 7–8);
- canonical-ID validation (Section 6);
- strict complete-response parsing (Section 6);
- Staff mutation revision protection for the queue and detail lanes
  (Section 10);
- exact-key known-good preservation state model (Section 12);
- the affected Staff gateway/providers/domain helpers and dependent fakes;
- foundation/regression tests for the above.

Expected files (foundation):

- `lib/features/business/domain/business_application_staff_gateway.dart`
  (read outcome taxonomy + deadline ownership contract);
- `lib/features/business/domain/staff_read_result.dart` (renamed remote
  failure variant);
- `lib/features/business/domain/staff_application_detail.dart`
  (canonical-ID validation support);
- `lib/features/business/data/supabase_business_application_staff_gateway.dart`
  (deadline + classifier + strict mapping);
- `lib/features/business/domain/staff_remote_read.dart` (StaffRemoteReadFailure
  + StaffRemoteReadFailureKind);
- `lib/features/business/data/staff_remote_read_classifier.dart`;
- `lib/features/business/presentation/providers/staff_access_provider.dart`,
  `staff_application_queue_provider.dart`,
  `staff_application_detail_provider.dart`,
  `staff_operations_scope.dart` (lifecycle/guard wiring only);
- `main.dart` only if required for wiring (Section 16);
- affected fakes and affected existing Staff tests.

Preferred implementer: Codex / GPT-5.6 Sol High
Independent reviewer: GPT-5.6 Sol High, separate read-only session

### P2-E2 — Staff Remote-Read Presentation UX
STATUS: LOCKED pending independent P2-E1 acceptance.

P2-E2 owns the read-facing presentation work and must not begin until P2-E1
passes independent focused review.

Expected scope:

- known-good refresh/refresh-failed presentation for queue and detail
  (Section 12);
- screen-scoped `StaffRemoteReadNotice` adapter over the shared
  `RemoteDataNotice` (Section 14);
- offline promotion via the canonical ConnectivityProvider (Section 13);
- manual-retry wiring (Section 13);
- ONLY genuinely missing Staff-specific AR/EN keys (Section 15).

Expected files (presentation):

- `lib/features/business/presentation/widgets/staff_remote_read_notice.dart`;
- `lib/features/business/presentation/screens/staff_application_queue_screen.dart`;
- `lib/features/business/presentation/screens/staff_application_review_screen.dart`;
- `lib/features/business/presentation/staff_application_messages.dart`
  (only genuinely missing Staff keys);
- `lib/localization/ar.dart` / `en.dart` (only genuinely missing keys);
- affected Staff UX tests.

Preferred implementer: Big Pickle
Reviewer: GitHub Copilot Civilpedia Reviewer

## 20. Test and Gate Policy

Implementation and correction passes use focused tests only. Do not run the
full repository suite during P2-E1 or P2-E2 implementation/correction. Run
Flutter test processes sequentially; parallel `flutter test` is forbidden in
this repository (known NativeAssets/build-artifact collision).

P2-E1 must prove at minimum:

- the renamed remote failure variant + `StaffRemoteReadFailureKind` taxonomy;
- source-aware classification is narrow and proven — INCLUDING: `P0DAT`
  remains the existing Staff domain cause and is never `malformedResponse`;
  literal `"401"`/`"503"` → `unexpected`; response-shape/TypeError →
  `malformedResponse`;
- coalescing keys do NOT include `requestEpoch`; same-key joins; different-key
  starts independently; repeated manual retry on the same key never
  duplicates;
- read lanes/epochs: late stale result performs zero publication (data / empty
  / notFound / failure / finalizer / foreign active-handle cleanup);
- capabilities, queue, and detail lanes never overwrite each other's
  phase/state;
- canonical-ID mismatch on detail completes as zero publication /
  `malformedResponse`;
- Staff mutation revision guards for BOTH queue and detail (stale read cannot
  publish during/after an accepted mutation);
- strict complete-response parsing (one malformed required row fails the whole
  read);
- exact-key known-good preservation (refresh/refresh-failure preserve
  known-good data);
- sign-out / user switch / application switch / dispose all block late
  publication;
- no durable Staff cache; no Directory/profile/Business-owner fallback; no new
  auxiliary read lane;
- no raw exception/backend details reach widgets;
- `RemoteOperationPolicy.read` = 15 seconds maintained at the Staff data
  boundary.

## 21. Stop Conditions

Implementation must stop with the exact applicable contradiction when:

- the accepted authority model, read lifecycle model, or a frozen amendment
  must change:
  `P2-E CONTRACT CONTRADICTION — ARCHITECT DECISION REQUIRED`;
- a database, schema, RLS, migration, Storage, Function, or Realtime change is
  genuinely required:
  `DATABASE CONTRACT CONTRADICTION — ARCHITECT DECISION REQUIRED`;
- an accepted V1-R08 security guarantee must change:
  `R08 CONTRACT CHANGE REQUIRED — ARCHITECT DECISION REQUIRED`.

## 22. Completion Conditions

P2-E1 is not complete merely because code exists. Closure requires P2-E1 to
pass independent focused review, P2-E2 to remain locked until then, and no
unresolved contract contradiction to remain.

This freeze authorizes P2-E1 implementation only (after contract persistence).
It does not mark V1-R09 closed.

## Appendix — Architect Amendments (applied verbatim)

1) rename the new remote failure variant away from "InfrastructureFailure";

2) keep P0DAT as the existing Staff domain cause — do NOT map it to
   malformedResponse;

3) reuse shared RemoteDataNotice localization; add only genuinely missing
   Staff-specific AR/EN keys;

4) freeze the additional clauses for source-aware classification, key-vs-epoch
   separation, Staff mutation revision protection for queue/detail,
   canonical-ID validation, strict complete-response parsing, exact-key
   known-good preservation, auxiliary-lane isolation, manual-retry-only
   connectivity, transport-banner non-expansion, and backend freeze.

All frozen semantics in Sections 1–22 above remain in force for the lifetime
of V1-R09-P2-E-CONTRACT-v1 and may only change through an authorized
contract addendum.