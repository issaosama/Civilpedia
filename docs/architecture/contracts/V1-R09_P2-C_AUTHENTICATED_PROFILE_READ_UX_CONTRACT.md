# CIVILPEDIA V1-R09 PART 2 — P2-C AUTHENTICATED PROFILE READ UX CONTRACT

PHASE: V1-R09 Part 2
SLICE: P2-C — Authenticated Profile Read UX
CONTRACT: V1-R09-P2-C-CONTRACT-v1
STATUS: FROZEN
ARCHITECT DECISION: FROZEN
IMPLEMENTATION_AUTHORIZED: YES after this contract is persisted (P2-C1 only)

## 1. Authority and Purpose

This contract persists the accepted P2-C architecture inspection proposal for
the authenticated profile read surface and its lifecycle safety. It is the
authoritative implementation boundary for V1-R09 Part 2 slice P2-C.

It layers on V1-R09-CONTRACT-v1 (including C3-ADDENDUM-A) and on the closed
P2-B slice. Everything in the parent contract that is not changed here remains
in force. V1-R08 authentication, identity, ownership, and account-bound
guarantees are preserved unchanged.

Supabase `public.profiles` remains the authenticated-profile single source of
truth. AuthProvider remains the only auth/session authority.

## 2. Mandatory Architect Amendments

The following architect amendments are frozen and must be present in every
P2-C design and implementation. They may not be relaxed or refactored away.

### AMENDMENT 1 — KEYED READ SINGLE-FLIGHT

Profile read coalescing is scoped by an exact logical read key:

- `(userId, authGeneration, profileRevision)`

Rules:

- Equivalent active read with the same key: MAY coalesce/join.
- Different `userId`: MUST start independently.
- Different `authGeneration`: MUST start independently.
- Different `profileRevision`: MUST start independently.
- User A in-flight read MUST NOT block User B.
- A pre-edit read MUST NOT absorb or block a post-edit authoritative reread.
- An old completion must not clear or replace an active read owned by a newer
  key.

`UserProfileProvider` owns this transient read orchestration.

Do NOT move network authority into AuthProvider. AuthProvider remains
consume-only auth/session authority.

### AMENDMENT 2 — PROFILE REVISION

Every logical profile read captures:

- `startProfileRevision`

Publication requires:

- `startProfileRevision == currentProfileRevision`

Any accepted profile mutation that changes the canonical in-memory profile
state advances `profileRevision` BEFORE an older read may publish.

Therefore an older read cannot overwrite a newer accepted edit.

This applies to all read outcomes, including `authoritativeNotFound`.

A stale `notFound` may NEVER clear a newer edited/loaded profile.

### AMENDMENT 3 — NARROW FAILURE CLASSIFICATION

Read-specific taxonomy remains:

- `network`
- `timeout`
- `serviceUnavailable`
- `malformedResponse`
- `permissionDenied`
- `authRestricted`
- `unexpected`

No data-layer `offline`. ConnectivityProvider remains presentation-owned;
the gateway/repository never claims confirmed transport state.

Recognized temporary availability examples:

- `08xxx`
- `53xxx`
- `PGRST000`
- `PGRST001`
- `PGRST002`
- `PGRST003`

   → `serviceUnavailable`

Recognized RLS/permission rejection:

- `42501` and only other explicitly proven permission equivalents

   → `permissionDenied`

Recognized JWT/session restrictions only:

   → `authRestricted`

Do NOT blanket-map all PostgrestException values.

Unknown/unproven PostgREST codes:

   → `unexpected`

Literal PostgREST code `"503"`:

   → NOT interpreted as HTTP 503.

No raw code/message/details reach widgets.

P2-C `permissionDenied` / `authRestricted` read failures do NOT sign the user
out. AuthProvider remains the only auth/session authority.

### AMENDMENT 4 — AUTHORITATIVE NOT FOUND

Successful authoritative absence is distinct from infrastructure failure.

`authoritativeNotFound` may clear an obsolete profile ONLY after all
publication guards pass:

- provider still alive;
- request epoch current;
- captured `userId` current;
- captured `authGeneration` current;
- captured `profileRevision` current.

Then:

- controlled authenticated-profile-unavailable state;
- manual read retry permitted.

It MUST NOT:

- expose guest profile;
- create a profile;
- invoke bootstrap;
- change auth authority;
- sign out;
- replay mutation.

`PersonalProfileBootstrapCoordinator` remains the sole provisioning path.

## 3. Preserved Accepted Contract

The following accepted behavior is preserved and remains in force:

- AuthProvider is consume-only auth authority.
- `public.profiles` is authenticated-profile SSOT.
- No durable authenticated profile cache.
- No authenticated guest fallback.
- Same-user in-memory known-good profile may remain visible during read
  failure.
- Canonical 15-second `RemoteOperationPolicy.read`.
- Manual retry only.
- No automatic reconnect refresh.
- No ReconnectGenerationGate for Profile.
- TransportStatusBanner remains AppShell-owned.
- RemoteDataNotice reused.
- network != confirmed offline.
- Profile read failure must not clear auth authority.
- Malformed data never publishes.
- No mutation redesign.
- No mutation replay / offline queue.
- No database / backend changes.

## 4. Internal Partition

P2-C is split into two internal implementation windows. No new roadmap phase
IDs are created; both windows live inside the existing V1-R09 Part 2 roadmap
entry.

### P2-C1 — Typed Read & Lifecycle Foundation
STATUS: IMPLEMENTATION_AUTHORIZED: YES after this contract is persisted.

Boundary:

- `lib/features/profile/data/personal_profile_remote_gateway.dart`
- `lib/features/profile/data/supabase_personal_profile_remote_gateway.dart`
- `lib/features/profile/presentation/providers/user_profile_provider.dart`
- new focused foundation test

Preferred implementer:

- Codex

Independent reviewer:

- GPT-5.6 Sol High

### P2-C2 — Profile Read Presentation
STATUS: LOCKED pending independent P2-C1 acceptance.

P2-C2 owns the read-facing presentation work. It must not begin until P2-C1
passes independent focused review.

Preferred implementer:

- Big Pickle

Reviewer:

- GitHub Copilot Civilpedia Reviewer

## 5. Test and Gate Policy

Implementation and correction passes use focused tests only. Do not run the
full repository suite during P2-C1 or P2-C2 implementation/correction. Run
Flutter test processes sequentially; parallel `flutter test` is forbidden in
this repository (known NativeAssets/build-artifact collision).

P2-C1 must prove at minimum:

- keyed single-flight: same key coalesces; different userId / authGeneration /
  profileRevision start independently;
- User A in-flight read never blocks User B;
- pre-edit read never absorbs or blocks post-edit authoritative reread;
- old completion never clears an active read owned by a newer key;
- publication requires `startProfileRevision == currentProfileRevision`;
- any accepted in-memory profile mutation advances revision before an older
  read may publish;
- stale `authoritativeNotFound` never clears a newer edited/loaded profile;
- temporary availability codes map to `serviceUnavailable`;
- `42501` maps to `permissionDenied`;
- JWT/session restrictions map to `authRestricted`;
- unproven/unknown PostgREST codes map to `unexpected`;
- literal `"503"` is NOT treated as HTTP 503;
- no data-layer `offline`;
- no raw code/message/details reach widgets;
- permissionDenied/authRestricted read failures do not sign the user out;
- `authoritativeNotFound` publication requires all five guards and reaches a
  controlled authenticated-profile-unavailable state with manual retry;
- `authoritativeNotFound` never exposes guest, creates, bootstraps, changes
  auth authority, signs out, or replays a mutation;
- `PersonalProfileBootstrapCoordinator` remains the sole provisioning path;
- AuthProvider remains consume-only;
- 15-second `RemoteOperationPolicy.read` maintained.

## 6. Stop Conditions

Implementation must stop with the exact applicable contradiction when:

- the accepted authority model, read lifecycle model, or the four amendments
  must change:
  `P2-C CONTRACT CONTRADICTION — ARCHITECT DECISION REQUIRED`;
- a database, schema, RLS, migration, Storage, Function, or Realtime change is
  genuinely required:
  `DATABASE CONTRACT CONTRADICTION — ARCHITECT DECISION REQUIRED`;
- an accepted V1-R08 security guarantee must change:
  `R08 CONTRACT CHANGE REQUIRED — ARCHITECT DECISION REQUIRED`.

## 7. Completion Conditions

P2-C1 is not complete merely because code exists. Closure requires P2-C1 to
pass independent focused review, P2-C2 to remain locked until then, and no
unresolved contract contradiction to remain.

This freeze authorizes P2-C1 implementation only (after contract persistence).
It does not mark V1-R09 closed.

## Appendix — P2-C1 Closure

P2-C1: ACCEPTED / CLOSED
Independent review: PASS
Test evidence: 205 PASS / 0 FAIL / 0 SKIPPED
Findings: HIGH NONE / MEDIUM NONE / LOW NONE
P2-C2: may now be unlocked
P2-C overall: remains CURRENT