# CIVILPEDIA V1-R09 PART 2 — P2-D BUSINESS REMOTE READ UX CONTRACT

PHASE: V1-R09 Part 2
SLICE: P2-D — Business Remote Read UX
CONTRACT: V1-R09-P2-D-CONTRACT-v1
STATUS: FROZEN
ARCHITECT DECISION: FROZEN
IMPLEMENTATION_AUTHORIZED: YES after this contract is persisted (P2-D1 only)

## 1. Authority and Purpose

This contract persists the accepted P2-D architecture inspection proposal for
the authenticated Business remote-read surface and its lifecycle safety. It is
the authoritative implementation boundary for V1-R09 Part 2 slice P2-D.

It layers on V1-R09-CONTRACT-v1, on the closed P2-B slice, and on the closed
P2-C slice. Everything in the parent and prior slice contracts that is not
changed here remains in force. V1-R08 authentication, identity, ownership, and
account-bound guarantees are preserved unchanged.

Supabase remains the server authority for all authenticated Business reads.
AuthProvider remains the only session authority. `business_memberships` remains
the Business ownership/access authority, `directory_entities.id` remains the
canonical Business identity, and the frozen server RPCs remain the
authoritative read projections.

## 2. Business Domain / Authority

P2-D covers authenticated Business remote reads for:

- managed-business list;
- OWNER/ADMIN managed public-business profile;
- applicant-owned business application list/detail/status;
- CLAIM target selection.

It excludes:

- public Directory browsing;
- Staff review;
- legacy `sb_profiles` / service-business local models.

Authority:

- AuthProvider = session authority;
- `business_memberships` = Business ownership/access authority;
- `directory_entities.id` = canonical Business identity;
- `list_my_businesses()` = managed-business authoritative read projection;
- `get_managed_business_profile(entityId)` = managed-profile authoritative
  read;
- `business_applications` own rows = application authority for current actor;
- active/unclaimed `directory_entities` projection = CLAIM candidate
  presentation only;
- database mutation guards = final claimability authority;
- CloudDirectoryRepository = separate public Directory authority; NEVER a
  Business-read fallback;
- `sb_profiles` / LocalServiceBusinessRepository = legacy/compatibility only;
  NEVER Business authority/fallback.

## 3. Read Taxonomy

Freeze the shared Business read failure taxonomy:

- `network`
- `timeout`
- `serviceUnavailable`
- `malformedResponse`
- `permissionDenied`
- `authRestricted`
- `unexpected`

`authoritativeNotFound` is a successful authoritative absence result, not a
failure.

The data layer NEVER emits `offline`.

Canonical deadline:

- `RemoteOperationPolicy.read` = 15 seconds.

Mapping must be narrow and source-aware:

- connection/transport client failures → `network`;
- read deadline / `TimeoutException` → `timeout`;
- `08xxx`, `53xxx`, `PGRST000..PGRST003` → `serviceUnavailable`;
- `42501` → `permissionDenied`;
- `P0PER` → `permissionDenied` ONLY where the specific RPC contract proves that
  meaning;
- `P0AUT` → `authRestricted` ONLY where the specific RPC contract proves that
  meaning;
- `PGRST301..PGRST303` → `authRestricted` only when the encountered source
  semantics are verified as JWT/session restriction;
- `AuthException` / auth-specific status 401 → `authRestricted` where narrowly
  proven.

Do NOT blanket-map a generic PostgREST code `"401"`.

Literal PostgREST code `"503"` → `unexpected`.

Strict required-row parsing / invalid response shape → `malformedResponse`.

Unknown or unproven exception/code → `unexpected`.

No raw exception/backend details may reach widgets.

## 4. Authoritative Absence

Managed-business list:

- successful empty → authoritative empty list;
- NOT `authoritativeNotFound`.

Managed profile:

- contract-proven `P0NOT` from `get_managed_business_profile` →
  `authoritativeNotFound` / controlled unavailable profile.

Application list:

- successful empty → authoritative empty list.

Application detail:

- successful null → authoritative absence within CURRENT ACTOR'S AUTHORIZED
  READ SCOPE.

This must NOT be described as proof that the application does not exist
globally. It may mean:

- absent;
- unavailable to current actor;
- not owned / not visible under current RLS.

UI: controlled unavailable state only.

Claim target list:

- successful empty → no currently visible claim candidates.

No absence state may:

- create Business data;
- submit an application;
- trigger bootstrap/provisioning;
- mutate ownership;
- redirect into a new workflow implicitly.

## 5. Strict Complete Response

Any malformed required row causes the complete corresponding read to fail as
`malformedResponse`.

Do NOT silently skip malformed required rows.

Do NOT fabricate an empty result from malformed data.

Known-good same-key data may remain visible during the malformed failure.

## 6. Coalescing Keys — Separate from Request Epoch

Exact active read/coalescing keys:

- Managed list: `(userId, authGeneration)`;
- Managed profile: `(userId, authGeneration, entityId, profileRevision)`;
- Application list: `(userId, authGeneration, applicationRevision)`;
- Application detail: `(userId, authGeneration, applicationId,
  applicationRevision)`;
- Claim targets: `(userId, authGeneration)`.

`requestEpoch` is NOT part of these keys.

`requestEpoch` is a separate publication token.

Rules:

- same exact key already active → MAY join/coalesce;
- different key → MUST start independently;
- new underlying logical read → receives newer `requestEpoch` for that read
  lane;
- repeated manual retry while the exact same key is already active → does not
  launch an unsafe duplicate request;
- User A active read → User B may start independently;
- entity/application key change → starts independently;
- accepted mutation changes revision → post-mutation authoritative read starts
  under a different key;
- old completion may remove only its OWN matching active handle;
- old completion must never clear an active handle belonging to a newer or
  different key.

Do NOT implement one global Future gate.

## 7. Read Lanes / Epochs

Freeze independent publication lanes where required. At minimum:

- managed-business list lane;
- managed-profile lane;
- application-list lane;
- application-detail lane;
- claim-target lane;
- editor auxiliary reference-data lane.

A newer underlying request within a lane supersedes older publication.

A late stale result performs ZERO publication, including:

- data;
- empty/notFound;
- failure;
- loading/finalizer state;
- active-handle cleanup belonging to another request.

Application list and detail MUST NOT overwrite each other's phase/state.

## 8. Session / Identity Safety

Every authenticated Business publication validates:

- provider still alive;
- captured `userId` still current;
- captured `authGeneration` still current;
- AuthProvider current-session guard where applicable;
- matching resource identity;
- matching mutation revision where applicable;
- current `requestEpoch`.

Sign-out:

- invalidates Business read publication;
- late results publish nothing.

User A → User B:

- B starts independently;
- A does not block B;
- late A cannot publish/clear B state.

Entity switch:

- old entity profile must never appear under new entity identity.

Application switch:

- old application detail must never appear under new application identity.

Dispose:

- invalidates epochs/active ownership;
- no late notify/publication.

## 9. Mutation Revision

Managed profile:

- accepted managed-profile mutation that publishes canonical projection →
  increments `profileRevision` BEFORE older reads may publish.

Application mutations:

- accepted create / submit / resubmit publication → increments
  `applicationRevision` BEFORE older reads may publish.

Every relevant read captures its start revision.

Mismatch at completion → ZERO stale publication.

This applies to:

- success;
- failure metadata;
- authoritative empty/notFound;
- finalizer state.

Do NOT redesign mutation APIs, retry semantics, call counts, or server
authority.

## 10. Editor Auxiliary Reference Data

`directory_categories` and regions are authoritative REFERENCE DATA. They are
not the managed-profile authority.

Freeze a separate auxiliary read lane/state.

Required:

- managed profile succeeds + categories/regions read fails → KEEP managed
  profile; KEEP existing editor draft where valid; expose one auxiliary typed
  read failure notice; manual retry.

Reference-data failure MUST NOT:

- clear managed profile;
- become managed-profile `authoritativeNotFound`;
- clear the draft;
- establish Business absence.

If both reference reads are grouped by the current implementation, one
coalesced auxiliary notice is sufficient.

## 11. Presentation

- No data + initial read → bounded loading;
- No data + remote failure → `RemoteDataNotice` `noData`; manual retry;
- Matching known-good data + refresh → preserve data; lightweight refreshing
  state;
- Matching known-good data + failure → preserve data; one compact typed notice;
  manual retry;
- Success → replace matching data; clear matching failure;
- Malformed → never publish malformed data; preserve matching known-good if
  available.

No duplicate feature notice.

TransportStatusBanner remains AppShell-owned.

## 12. Connectivity

Manual retry only.

NO:

- automatic reconnect refresh;
- ReconnectGenerationGate;
- polling;
- background Business reads;
- connectivity-triggered read.

Business gateway emits `network`.

Presentation maps:

- `network` + ConnectivityProvider confirmed unavailable → `offline`;
- `network` + available/unknown → `network`.

Reconnect alone → zero Business read calls.

## 13. Localization

AR and EN must use the ACTIVE APP LOCALE.

Current screens that hard-code Arabic / `isArabic = true` must be corrected in
P2-D2.

No forced direction. RTL/LTR follows Flutter/app locale.

Prefer existing localization strings.

Do not duplicate shared network/offline wording.

## 14. main.dart Boundary

`lib/main.dart` may be modified in P2-D1 ONLY if required for wiring.

Allowed:

- inject existing AuthProvider/session context into existing Business
  providers;
- required provider dependency wiring.

NOT allowed:

- Business read logic;
- classification logic;
- repository authority;
- new SupabaseClient;
- duplicate provider authority;
- timers/background sync.

If wiring is unnecessary, leave `main.dart` unchanged.

## 15. Cache / Local State

No new durable Business cache.

Preserve:

- transient provider memory;
- editor mutation draft;
- public Directory durable cache as separate authority;
- legacy `sb_profiles` as legacy only.

Never use Directory cache or `sb_profiles` as a Business fallback.

## 16. Backend

NO backend change.

No:

- migration;
- schema;
- RLS;
- grant;
- RPC change;
- Edge Function;
- Realtime;
- `service_role`.

Migration 00022 remains absent.

## 17. Internal Partition

### P2-D1 — Typed Business Read / State / Lifecycle Foundation
STATUS: IMPLEMENTATION_AUTHORIZED: YES after this contract is persisted.

Expected scope:

- shared Business read domain/data helpers;
- four Business gateways;
- four Business providers;
- minimal `main.dart` wiring only if required;
- affected fakes;
- foundation/regression tests.

Preferred implementer:

- Codex / GPT-5.6 Sol High

Independent reviewer:

- GPT-5.6 Sol High, separate read-only session

### P2-D2 — Business Remote-Read Presentation UX
STATUS: LOCKED pending independent P2-D1 acceptance.

P2-D2 owns the read-facing presentation work and must not begin until P2-D1
passes independent focused review.

Preferred implementer:

- Big Pickle

Reviewer:

- GitHub Copilot Civilpedia Reviewer

## 18. Test and Gate Policy

Implementation and correction passes use focused tests only. Do not run the
full repository suite during P2-D1 or P2-D2 implementation/correction. Run
Flutter test processes sequentially; parallel `flutter test` is forbidden in
this repository (known NativeAssets/build-artifact collision).

P2-D1 must prove at minimum:

- taxonomy mapped narrowly and source-aware (no blanket generic-code mapping;
  literal `"503"` → `unexpected`; organization/TypeError shape → malformed);
- coalescing keys do NOT include `requestEpoch`; same-key joins; different-key
  starts independently; repeated manual retry on the same key never duplicates;
- read lanes/epochs: late stale result performs zero publication (data / empty
  / notFound / failure / finalizer / foreign active-handle cleanup);
- application list and detail lanes never overwrite each other's phase/state;
- sign-out / user switch / entity switch / application switch / dispose all
  block late publication;
- mutation revision guards: mismatch completes as zero stale publication
  (success, failure metadata, authoritative empty/notFound, finalizer);
- auxiliary reference-data failure preserves managed profile + draft and
  exposes exactly one auxiliary notice;
- managed-profile `authoritativeNotFound` only on contract-proven `P0NOT`;
- application-detail authoritative null stays within the current actor's
  authorized read scope;
- no durable Business cache; no Directory/`sb_profiles` fallback;
- no raw exception/backend details reach widgets;
- `RemoteOperationPolicy.read` = 15 seconds maintained.

## 19. Stop Conditions

Implementation must stop with the exact applicable contradiction when:

- the accepted authority model, read lifecycle model, or a frozen amendment
  must change:
  `P2-D CONTRACT CONTRADICTION — ARCHITECT DECISION REQUIRED`;
- a database, schema, RLS, migration, Storage, Function, or Realtime change is
  genuinely required:
  `DATABASE CONTRACT CONTRADICTION — ARCHITECT DECISION REQUIRED`;
- an accepted V1-R08 security guarantee must change:
  `R08 CONTRACT CHANGE REQUIRED — ARCHITECT DECISION REQUIRED`.

## 20. Completion Conditions

P2-D1 is not complete merely because code exists. Closure requires P2-D1 to
pass independent focused review, P2-D2 to remain locked until then, and no
unresolved contract contradiction to remain.

This freeze authorizes P2-D1 implementation only (after contract persistence).
It does not mark V1-R09 closed.