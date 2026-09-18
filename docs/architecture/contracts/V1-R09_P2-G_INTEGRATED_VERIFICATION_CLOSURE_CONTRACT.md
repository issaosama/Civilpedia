# CIVILPEDIA V1-R09 PART 2 — P2-G INTEGRATED UX VERIFICATION AND CLOSURE CONTRACT

PHASE: V1-R09 Part 2
SLICE: P2-G — Integrated UX Verification and Closure
CONTRACT: V1-R09-P2-G-CONTRACT-v1
STATUS: FROZEN
ARCHITECT DECISION: FROZEN (per completed P2-G integrated verification inspection)
IMPLEMENTATION_AUTHORIZED: NO — verification execution authorized only after Architect checkpoint

## 1. Authority and Purpose

This contract persists P2-G as a VERIFICATION-FIRST INTEGRATED CLOSURE GATE for
V1-R09 Part 2. It is the authoritative boundary for the final slice of V1-R09.

It layers on V1-R09-CONTRACT-v1 and on the CLOSED P2-A / P2-B / P2-C / P2-D /
P2-E / P2-F slices. Everything in the parent and prior-slice contracts that is
not changed here remains in force. P2-G does NOT alter remote-data,
connectivity, authentication, identity, ownership, or account-bound guarantees.

P2-G requires:

- ONE mandatory surgical production correction already proven by inspection;
- focused integrated deterministic evidence (one new suite);
- selected accepted R09 regression suites;
- closure-evidence consistency recording (NOT fabrication).

This freeze persists semantics ONLY. No production code, test, or historical
report artifact is modified by this freeze.

## 2. Non-Goals

P2-G is NOT:

- a feature phase;
- a refactor phase;
- V1-R09Q — Post-R09 Cross-Cutting Quality Gate;
- V1-R17 final End-to-End QA;
- V1-R10 UI redesign;
- backend production readiness;
- performance/load testing;
- release packaging;
- full repository test execution.

SCOPE MAY BE LIMITED. QUALITY MAY NOT BE LIMITED.

## 3. Mandatory Surgical Correction (founded by inspection)

Freeze the inspection finding as a REQUIRED P2-G production correction:

FILE:
- `lib/features/encyclopedia/presentation/widgets/encyclopedia_content_notice.dart`

CURRENT DEFECT:
- the retry action renders `Ar.retry` regardless of the active locale
  (`child: const Text(Ar.retry)` inside the notice's TextButton).

VIOLATION:
- this contradicts the already accepted P2-F §16 symmetric AR/EN localization
  invariant ("no hard-coded Arabic-only P2-F error copy").

REQUIRED:
- Arabic locale -> Arabic retry copy (`Ar.retry`);
- English locale -> English retry copy (`En.retry`);
- preserve the existing widget architecture and the notice's
  "owns NO localization resolution" contract (the message stays
  caller-localized);

- no new localization keys unless genuinely necessary — reuse existing
  `Ar.retry` / `En.retry`;
- no broader Encyclopedia localization cleanup;
- no P2-F architecture redesign.

The correction MUST be completed and verified before P2-G / V1-R09 closure.
This known R09 defect MUST NOT be deferred to V1-R09Q.

## 4. P2-G Integrated Test

Authorize exactly ONE new focused integrated suite:

- `test/v1_r09_p2_g_integrated_gate_test.dart`

Its purpose is to prove TRUE cross-feature R09 behavior not already
sufficiently proven by accepted focused suites. It MUST NOT duplicate every
P2-B..P2-F test.

Frozen integrated scenario areas are defined in sections 5-12 below.

## 5. Transport Policy Integration

Integrated evidence MUST prove the frozen policy split:

DIRECTORY:
- canonical `reconnectGeneration` MAY trigger an eligible refresh exactly once;
- Directory owns `ReconnectGenerationGate`;
- no duplicate generation-triggered refresh.

PROFILE:
- connectivity recovery MUST NOT auto-refresh;
- manual retry only.

BUSINESS:
- connectivity recovery MUST NOT auto-refresh;
- manual retry only.

STAFF:
- connectivity recovery MUST NOT auto-refresh;
- manual retry only.

ENCYCLOPEDIA:
- no connectivity-driven read behavior at all.

Where practical, exercise these policies under the SAME canonical connectivity
authority instance. Do NOT infer policy merely from type names.

## 6. Offline / Network Presentation Integration

For remote feature failures (where the accepted feature contract supports
remote failure presentation):

- `network` + canonical `unavailable` -> offline presentation;
- `network` + canonical `available` -> network presentation;
- `network` + canonical `unknown` -> network presentation.

Encyclopedia local-content failure:

- MUST remain a local-content failure regardless of connectivity state;
- MUST NOT become `offline`, `network`, `timeout`, or
  `serviceUnavailable`.

## 7. App Shell + Encyclopedia Local Failure Coexistence

Add deterministic integrated evidence that when:

- AppShell transport state is `unavailable`

AND

- Encyclopedia has a local-content failure,

then:

- `TransportStatusBanner` MAY render as the global transport status;
- the Encyclopedia local-content notice remains independently local;
- the local-content failure is NOT relabeled offline;
- no duplicate transport authority is created;
- the shell remains usable.

This proves coexistence, NOT semantic merging.

## 8. Session / Identity Integration

Add the SMALLEST deterministic cross-provider evidence needed to prove
authenticated R09 state does not cross account boundaries.

At minimum cover an actual integrated reset path around:

- User A: authenticated; account-bound providers contain or are loading data;
- sign-out OR User B becomes current;

and verify account-bound R09 state is invalidated/reset safely across the
actual coordinated reset seam (`resetAccountBoundState` + the staff scope
reset path wired in the real composition root).

Relevant providers: only those wired into the real reset path:

- `UserProfileProvider`;
- Business application / claim / managed-businesses/profile state where
  applicable;
- `StaffOperationsScope`.

Do NOT force Directory into account-bound clearing — Directory is public.
Do NOT clear device-local Encyclopedia favorites merely because auth changes.
Avoid reproducing every provider's already-proven lifecycle test — the purpose
is to prove the COORDINATED reset wiring.

## 9. Retry / Mutation Safety

Integrated evidence MUST preserve:

- Directory: read refresh / reconnect only;
- Profile: manual READ retry;
- Business: manual READ retry;
- Staff: manual READ retry;
- Encyclopedia: manual same-authority local read retry.

No P2-G retry/reconnect path may invoke a mutation. Do NOT retest every
mutation RPC individually if existing accepted suites already prove it.

## 10. Known-Good Priority

P2-G MUST verify no integrated presentation regression changed accepted
known-good semantics. At minimum assert cross-feature policy consistency:

- Directory cache survives refresh failure;
- remote feature known-good data remains primary where its frozen contract
  says so;
- Encyclopedia known-good local content remains primary on same-identity
  reload failure;
- authoritative permission loss MAY intentionally clear privileged Staff
  state.

Do NOT demand identical UX where domain semantics differ.

## 11. English Encyclopedia Notice Regression

Add deterministic evidence — inside the P2-G integrated suite OR by extending
`test/v1_r09_p2_f_encyclopedia_local_content_hardening_test.dart` (whichever is
the best existing seam) — that:

- `Locale('en')` + `EncyclopediaContentNotice` with retry renders `En.retry`;
- and MUST NOT render `Ar.retry`;
- Arabic behavior is preserved.

This test is mandatory because it directly guards the surgical correction in
section 3.

## 12. Selected P2-G Regression Suites (exact existing paths)

Verified to exist in the CURRENT repository at freeze time. Run SEQUENTIALLY.

P2-A..P2-F accepted suites:
- `test/v1_r09_p2_shared_ux_test.dart`
- `test/v1_r09_p2_b_directory_data_test.dart`
- `test/v1_r09_p2_b_directory_ux_test.dart`
- `test/v1_r09_p2_c_authenticated_profile_read_foundation_test.dart`
- `test/v1_r09_p2_c_authenticated_profile_read_ux_test.dart`
- `test/v1_r09_p2_d_business_remote_read_foundation_test.dart`
- `test/v1_r09_p2_d_business_remote_read_ux_test.dart`
- `test/v1_r09_p2_e_staff_remote_read_foundation_test.dart`
- `test/v1_r09_p2_e_staff_remote_read_ux_test.dart`
- `test/v1_r09_p2_f_encyclopedia_local_content_hardening_test.dart`

Shared primitives / shell:
- `test/app_shell_test.dart`
- `test/remote_operation_policy_test.dart`

Directly relevant historical Directory (R05) suites required by the current
Directory cache-first/reconnect providers:
- `test/v1_r05_directory_cloud_integration_test.dart`
- `test/w5_3_directory_search_screen_test.dart`
- `test/w5_4_directory_search_integration_test.dart`
- `test/w5_4_directory_provider_detail_screen_test.dart`
- `test/w5_6_directory_provider_detail_save_test.dart`
- `test/w5_6_saved_screen_directory_test.dart`
- `test/saved_reference_resolver_test.dart`
- `test/w6_2_directory_route_test.dart`

Directly relevant historical R08 / auth / Profile / user-area suites required
by the current profile and user-area providers:
- `test/v1_r08_cloud_profile_foundation_test.dart`
- `test/v1_r08_profile_screen_widget_test.dart`
- `test/v1_r08_profile_edit_screen_widget_test.dart`
- `test/v1_r08_user_area_widget_test.dart`
- `test/user_area_route_test.dart`

Directly relevant historical Business (R04/R06) suites required by the current
Business read providers:
- `test/v1_r04_business_application_ux_test.dart`
- `test/v1_r06_business_profile_management_test.dart`

NOTE on baseline-dirty paths:
- `test/v1_r08_cloud_profile_foundation_test.dart` and
  `test/v1_r08_profile_edit_screen_widget_test.dart` are part of the
  pre-existing dirty baseline. They are listed because their on-disk content is
  the accepted current evidence. P2-G MUST NOT modify them.
- `test/a5_6_profile_bootstrap_test.dart` (also baseline-dirty) is NOT selected;
  it is a legacy bootstrap suite not required by the current R09 providers.

## 13. Execution Policy — IMPORTANT

All selected P2-G regression suites MUST run:

- SEQUENTIALLY;
- ONE SUITE AT A TIME;

Do NOT use one Flutter invocation containing many test paths if it can execute
tests concurrently. Do NOT run tests in parallel. Reason: the Civilpedia
environment has had NativeAssets PathExistsException under parallel test
execution.

Do NOT run (unless separately authorized):

- `flutter pub get`;
- `flutter precache`;
- `pub cache repair`;
- analyzer.

## 14. No Full Repository Suite

P2-G does NOT require the full Civilpedia test suite. Do NOT run every
repository test. The Post-R09 Quality Gate (V1-R09Q) exists for the next
cross-cutting quality checkpoint.

P2-G MUST remain:

- smaller than V1-R09Q;
- far smaller than V1-R17 final E2E.

Freeze selected R09 regression execution only.

## 15. Production File Boundary

Default production modifications — ONLY:

- `lib/features/encyclopedia/presentation/widgets/encyclopedia_content_notice.dart`
  for the mandatory AR/EN retry correction.

NO other production change is authorized by default.

If integrated verification exposes another genuine defect:

STOP and classify it BEFORE editing:

- A. TEST/EVIDENCE GAP -> tests only;
- B. SMALL INTEGRATION DEFECT within frozen architecture -> ARCHITECT
  authorization required before any production edit outside the one
  Encyclopedia widget;
- C. FROZEN CONTRACT CONTRADICTION -> P2-G CONTRACT CONFLICT — ARCHITECT
  DECISION REQUIRED;
- D. LATER-PHASE ISSUE -> record/defer; do NOT opportunistically fix.

## 16. Test File Boundary

Authorize ADD:

- `test/v1_r09_p2_g_integrated_gate_test.dart`

Authorize MODIFY only where necessary for the mandatory localization
regression:

- `test/v1_r09_p2_f_encyclopedia_local_content_hardening_test.dart`

if this is the best existing seam; otherwise keep the EN retry assertion inside
the P2-G integrated gate. Do NOT rewrite accepted P2-A..P2-F suites merely to
consolidate tests.

## 17. Doc / Closure Evidence

Do NOT edit historical implementation/review report artifacts during
verification.

Inspection found:

- an on-disk P2-D2 report (`Civilpedia_V1-R09_P2-D2_Report.txt`) whose tail
  predates the later formal closure;
- some accepted slices do not have standalone report artifacts currently
  present on disk.

Freeze the authority rule:

Formal roadmap closure records
+ frozen contracts
+ accepted git commits
+ available acceptance evidence

are the authoritative closure trail.

- Do NOT fabricate missing report files;
- Do NOT rewrite the historical P2-D2 report to make its old tail look current;
- At P2-G / V1-R09 closure, append a concise reconciliation note stating:
  - historical report artifacts may predate formal closure;
  - later roadmap closure records supersede their transitional status wording;
  - absence of a separate report artifact does not negate an accepted closure
    recorded by contract/roadmap/git evidence.

## 18. Localization / RTL / Theme

P2-G only needs targeted R09 state verification.

Verify the new/accepted R09 notices in:

- Arabic RTL;
- English LTR; including the corrected Encyclopedia retry label.

Keep dark/narrow verification limited to shared R09 components already covered,
plus any directly changed Encyclopedia notice if needed. Do NOT begin V1-R10
visual QA.

## 19. Closure Blockers

Freeze P2-G / V1-R09 blockers.

HIGH BLOCKERS:
- stale authenticated state crosses user/session boundary;
- production authority fallback regression;
- unauthorized reconnect policy;
- retry triggers mutation;
- privileged Staff data survives authoritative permission loss;
- cross-resource identity leak;
- duplicate transport authority causing incorrect behavior.

MEDIUM BLOCKERS:
- wrong offline/network mapping;
- destructive known-good regression;
- local Encyclopedia failure mislabeled as remote/offline;
- raw technical error leakage;
- manual-only feature auto-refreshes on reconnect;
- required integrated deterministic evidence missing;
- localization defect in a newly introduced R09 state;
- selected regression suite failure.

LOW:
- historical report wording mismatch superseded by formal closure;
- missing standalone report artifact where authoritative closure trail exists;
- non-functional naming/readability issue.

HIGH or MEDIUM: P2-G cannot close.
LOW: may be recorded and deferred if no trust/behavior impact remains.

## 20. P2-G Acceptance Execution

Expected execution sequence:

1. implement ONLY the frozen Encyclopedia EN retry-label correction;
2. add the focused P2-G integrated gate test;
3. run P2-G integrated gate;
4. run exact selected R09 regression suites sequentially (section 12);
5. correct only test/evidence issues inside authorized boundary;
6. if another production defect is found outside the single authorized widget:
   STOP for Architect decision;
7. independent review;
8. P2-G formal closure;
9. V1-R09 formal closure checkpoint;
10. V1-R09Q becomes NEXT.

## 21. V1-R09 Closure Path

Freeze:

P2-G acceptance
-> P2-G formal closure
-> V1-R09 formal closure record/checkpoint
-> V1-R09 CLOSED
-> V1-R09Q NEXT / AUTHORIZABLE
-> V1-R10 remains QUEUED after R09Q

No additional R09 technical phase may be invented.

## 22. Backend Protection

No backend change.

Do NOT modify: Supabase; migrations; RLS; grants; RPC; Edge; Realtime;
`service_role`. Migration 00022 remains absent.

## 23. Git Safety

After this docs-only contract persistence run:

    git diff --check
    git status --short
    git diff --name-only
    git diff --cached --name-only
    git rev-parse HEAD
    git rev-parse origin/main

Expected invariants:

- HEAD == origin/main ==
  44bb04a1de00e38efa8cf6f8084b7e7375426b45
- only the intended docs paths changed (this contract + the roadmap live-state
  update);
- nothing staged, committed, or pushed;
- baseline dirty paths untouched:
  `test/a5_6_profile_bootstrap_test.dart`,
  `test/v1_r08_cloud_profile_foundation_test.dart`,
  `test/v1_r08_profile_edit_screen_widget_test.dart`,
  `OpenCode_Usage_Report.txt`.

## 24. Closure Criteria

P2-G may not be marked completed or closed by this freeze. P2-G can only be
reported ready after: the mandatory AR/EN retry correction implemented and green;
the P2-G integrated gate green; the selected R09 regression suites green
(sequential); closure-evidence reconciliation appended; independent review
accepted; Architect checkpoint.

## Appendix A — Inspection Evidence (accepted at P2-G inspection)

- `EncyclopediaContentNotice` defect confirmed in repository truth:
  `lib/features/encyclopedia/presentation/widgets/encyclopedia_content_notice.dart`
  line 67 hard-codes `const Text(Ar.retry)`; all four Encyclopedia screens pass
  locale-aware error/known-good messages, so only the retry label leaks to AR
  under the EN locale.
- All four P2-F widget tests pump `Locale('ar')`; no EN-locale notice render
  exists today — the reason the defect escaped P2-F acceptance.
- `En.retry` exists in `lib/localization/en.dart` ('Retry'); `Ar.retry` exists
  in `lib/localization/ar.dart`. No new localization key is needed.
- Transport policy split verified: `ReconnectGenerationGate` consumers are ONLY
  the two Directory controllers; no Profile/Business/Staff/Encyclopedia
  provider subscribes to connectivity or auto-reconnects.
- Encyclopedia provider has no ConnectivityProvider dependency; typed local
  taxonomy is `assetUnavailable / malformedContent / unexpected`; no
  offline/network/timeout/serviceUnavailable.
- Coordinated reset seam verified in the composition root (`resetAccountBoundState`
  + `StaffOperationsScope.resetForAuthChange`).
- On-disk P2-D2 report tail predates the formal P2-D closure record; roadmap
  closure records remain the authoritative closure trail (see section 17).

## Appendix B — Roadmap Live State (as updated by this freeze)

    V1-R09:    CURRENT
    P2-A:      CLOSED
    P2-B:      CLOSED
    P2-C:      CLOSED
    P2-D:      CLOSED
    P2-E:      CLOSED
    P2-F:      CLOSED
    P2-G:      CURRENT — VERIFICATION CONTRACT FROZEN
    V1-R09Q:   QUEUED
    V1-R10:    QUEUED

P2-G is NOT marked completed by this freeze.
V1-R09 is NOT marked closed by this freeze.