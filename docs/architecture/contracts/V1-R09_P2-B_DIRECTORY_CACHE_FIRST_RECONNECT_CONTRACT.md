# CIVILPEDIA V1-R09 PART 2 — P2-B DIRECTORY CACHE-FIRST + RECONNECT CONTRACT

PHASE: V1-R09 Part 2
SLICE: P2-B — Directory Cache-First + Reconnect
CONTRACT: V1-R09-P2-B-CONTRACT-v1
STATUS: FROZEN
ARCHITECT DECISION: FROZEN
IMPLEMENTATION_AUTHORIZED: YES after this contract is persisted

## 1. Authority and Purpose

This contract persists the accepted P2-B architecture inspection proposal for
directory cache-first behavior and reconnect integration. It is the
authoritative implementation boundary for V1-R09 Part 2 slice P2-B.

It layers on V1-R09-CONTRACT-v1 (and C3-ADDENDUM-A, which applies to Part 1
C3 only). Everything in the parent contract that is not changed here remains
in force. V1-R08 authentication, identity, ownership, and account-bound
guarantees are preserved unchanged.

Supabase public Directory remains the canonical data authority. The local
Directory cache is a stale read-only presentation surface only.

## 2. Internal Partition

P2-B is split into two internal implementation windows. No new roadmap phase
IDs are created; both windows live inside the existing V1-R09 Part 2 roadmap
entry.

### P2-B1 — Data/cache/outcome foundation
STATUS: AUTHORIZED
IMPLEMENTATION_AUTHORIZED: YES (after this contract is persisted)

P2-B1 owns the data-layer outcome taxonomy, cache-first repository
capabilities (readCache + refresh), the canonical single-flight complete
refresh Future, whole-snapshot validation, and the internal-outcome contract.
No production presentation may be migrated to the new seam until P2-B2.

### P2-B2 — Search/detail/Saved/reconnect UX
STATUS: LOCKED until P2-B1 independent acceptance.

P2-B2 owns migration of production presentation from the compatibility
`load()` seam to `readCache()` + `refresh()`, reconnect-triggered eligible
refresh wiring, and the search/detail/Saved UX. P2-B2 must not begin until
P2-B1 passes independent focused review.

## 3. Mandatory Architect Amendments

The following amendments are architect-frozen and must be present in every
P2-B design and implementation. They may not be relaxed or refactored away.

### AMENDMENT 1 — NETWORK != OFFLINE

Internal read outcomes must be kept distinct:

- `offline`
- `network`
- `timeout`
- `serviceUnavailable`
- `malformedResponse`
- `unexpected`
- `authoritativeNotFound`
- `invalidCanonicalId`
- `success`
- `authoritativeEmpty`

`offline` is allowed only when canonical transport state confirms
`unavailable`. A request-level `network` failure must NOT claim that device
transport is confirmed offline.

The presentation may reuse neutral "connection unavailable / could not
connect" copy where appropriate, but must not falsely assert transport state.
Transport state and request outcome remain two independent facts.

### AMENDMENT 2 — AUTO RECONNECT CAUSES

Automatic reconnect refresh is eligible only for the transport-like causes:

- `offline`
- `network`
- `timeout`
- `serviceUnavailable`

The following causes are NOT eligible for automatic reconnect refresh:

- `malformedResponse`
- `unexpected`
- `authoritativeNotFound`
- `invalidCanonicalId`

Malformed/unexpected may offer an explicit manual idempotent reload, but the
reconnect path must not treat them as transport recovery failures. Reconnect
is a transport-recovery mechanism, not a general error-retry mechanism.

### AMENDMENT 3 — NO DATA-LAYER CONNECTIVITYPROVIDER DEPENDENCY

Data/gateway/repository layers must NOT import or depend on
ConnectivityProvider. Presentation/controller owns transport observation.

The feature/controller may short-circuit a remote attempt as typed `offline`
only when canonical transport state confirms unavailable. The
gateway/repository classifies actual request failures independently of
transport state.

### AMENDMENT 4 — LOAD() COMPATIBILITY

During P2-B1, the existing `load()` remains a compatibility seam for current
production callers. P2-B1 must not break existing UI behavior before P2-B2
integration. No new production caller may adopt `load()`.

P2-B2 will migrate production presentation to:

- `readCache()`
- `refresh()`

Do not remove `load()` during P2-B1.

## 4. Accepted Invariants (Frozen)

The following invariants are accepted and frozen for P2-B:

- Supabase public Directory is authoritative.
- The cache is a stale read-only presentation surface only.
- The canonical ID is `directory_entities.id` UUID.
- `ServiceBusinessProfile` / `sb_profiles` remain isolated legacy data.
- No heuristic identity mapping.
- Exactly one Directory repository.
- Exactly one Directory cache.
- Whole-snapshot validation.
- Valid cached-empty is distinct from no cache.
- A malformed required entity/relationship row fails the complete snapshot.
- A partial malformed response never replaces a valid cache.
- Authoritative empty may replace an old cache.
- Remote authoritative success remains usable in memory even if the cache
  write fails.
- `SharedPreferences.setString` returning false is a persistence failure.
- One repository-owned complete-refresh Future for single-flight.
- Equivalent complete refreshes coalesce.
- ReconnectGenerationGate owns no Future/network operation.
- 15-second canonical read deadline.
- No raw backend errors in the UI.
- Saved local references publish before Directory remote resolution.
- Saved references are never removed merely because Directory is unavailable.
- No mutation replay.
- No background sync.
- No offline mutation queue.
- No database migration / RLS / schema / Edge Function / Realtime /
  service_role changes.

## 5. Backend Decision

P2-B makes no backend change. No migration, RLS change, schema change, Edge
Function, Realtime rule, or `service_role` usage is authorized. If a genuine
backend dependency is discovered during P2-B, implementation must stop with:

`DATABASE CONTRACT CONTRADICTION — ARCHITECT DECISION REQUIRED`

## 6. Test and Gate Policy

Implementation and correction passes use focused tests only. Do not run the
full repository suite during P2-B1 or P2-B2 implementation/correction. Run
Flutter test processes sequentially; parallel `flutter test` is forbidden in
this repository (known NativeAssets/build-artifact collision).

P2-B1 must prove at minimum:

- cache-first: immediate cache publication before refresh completion;
- fresh / fresh-empty / stale / stale-empty / no-cache outcome behavior;
- failed refresh retains a valid cache;
- partial malformed response never replaces a valid cache;
- authoritative empty replaces an old cache;
- cache write failure does not discard an authoritative in-memory result;
- one single-flight complete-refresh Future;
- equivalent complete refreshes coalesce;
- one bounded eligible refresh per reconnect transition;
- reconnect never replays a mutation;
- network != offline claims (request outcome does not assert transport state);
- reconnect eligibility limited to offline/network/timeout/serviceUnavailable;
- data layer has no ConnectivityProvider dependency;
- `load()` compatibility seam preserved with no new production adopters;
- 15-second canonical read deadline;
- no raw backend errors in UI.

## 7. Stop Conditions

Implementation must stop with the exact applicable contradiction when:

- the accepted authority model, the cache model, or the four amendments must
  change:
  `P2-B CONTRACT CONTRADICTION — ARCHITECT DECISION REQUIRED`;
- a database, schema, RLS, migration, Storage, Function, or Realtime change is
  genuinely required:
  `DATABASE CONTRACT CONTRADICTION — ARCHITECT DECISION REQUIRED`;
- an accepted V1-R08 security guarantee must change:
  `R08 CONTRACT CHANGE REQUIRED — ARCHITECT DECISION REQUIRED`.

## 8. Completion Conditions

P2-B1 is not complete merely because code exists. Closure requires P2-B1 to
pass independent focused review, P2-B2 to remain locked until then, and no
unresolved contract contradiction to remain.

This freeze authorizes P2-B1 implementation only after this contract is
persisted. It does not mark V1-R09 closed.