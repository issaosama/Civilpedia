# Civilpedia — Commercial M3 Entitlement Evaluator / Shadow Implementation Contract V1

DOCUMENT_STATUS: ACCEPTED — CANONICAL M3 IMPLEMENTATION CONTRACT

FREEZE_STATE: FROZEN — ACCEPTED M3 SLICE DEFINITION ONLY

ARCHITECT_ACCEPTANCE: ACCEPTED — 2026-10-04

IMPLEMENTATION_AUTHORIZED: NO

DOCUMENT_VERSION: 1

DRAFT_DATE: 2026-10-04

TRACK: Separately authorized commercial backend architecture drafting

PUBLIC_BEHAVIOR_DELTA_PROPOSED: ZERO

This document proposes the smallest additive M3 evaluator and private shadow-evidence slice. It records no acceptance, implementation authorization, catalog approval, commercial grant, M4 reconciliation, or M5 cutover. Approval of architecture and authorization to execute it are separate decisions. All objects and tests described as future work below remain proposals.

## 1. Verified repository baseline and evidence limits

Repository: `D:\Civilpedia`.

HEAD and the local `origin/main` reference both equal `dcc736ba7a8dc0b068f6c8bfc11b74566ab756dc` (`feat(commercial): add M1b canonical catalog reference data`). The Owner's current instruction records M1b as CLOSED, IMPLEMENTED, INDEPENDENTLY ACCEPTED, COMMITTED and PUSHED. The migration chain currently contains 00001–00024; the latest file is [00024](../../../supabase/migrations/00024_commercial_catalog_reference_data.sql). No M3 migration exists at this drafting baseline. Local remote-reference equality is a repository observation, not a new remote/network verification.

The staged list is empty. The protected incoming working-tree state is:

```text
 M test/a5_6_profile_bootstrap_test.dart
 M test/v1_r08_cloud_profile_foundation_test.dart
 M test/v1_r08_profile_edit_screen_widget_test.dart
?? OpenCode_Usage_Report.txt
?? artifacts/r10_4a/home_dark.png
?? artifacts/r10_4a/home_light.png
```

Current source, rather than old runtime reports, supplies the physical audit below. This drafting pass runs no database, HTTP, migration, or Flutter gate. Historical accepted reports provide context only; their PASS counts are not M3 evidence. A new implementation must establish its own live baseline and execution context.

## 2. Authority hierarchy and trace

| Authority | Controlling content for this proposal | Boundary preserved |
| --- | --- | --- |
| [Frozen Commercial Model](../CIVILPEDIA_COMMERCIAL_MODEL_V1.md) | §§2/2.1/2.5 paid-only foundations; §6 Sponsored separation; §8.2 composition; §§26.1–26.7 time/Grace/enforcement/ownership; §§27–28 payment, Founding, quality and privacy; §31 Corporate/ownership/Baghdad launch; §32 A8; §33 freeze/governance | Commercial policy SSOT; no price, policy, OQ or freeze amendment |
| [C1](CIVILPEDIA_COMMERCIAL_CORE_AUTHORITY_RECONCILIATION_CONTRACT_V1.md) | Commercial authority reconciliation and legacy separation | AR-01–AR-14 remain OPEN/deferred; this proposal resolves none |
| [C2](CIVILPEDIA_COMMERCIAL_PUBLICATION_ENTITLEMENT_CONTRACT_V1.md) | Entitlement/publication composition and Grace continuation clarification | C2-AR-01–C2-AR-12 remain as defined; conceptual acceptance is not implementation permission |
| [C3](CIVILPEDIA_COMMERCIAL_SUBSCRIPTION_ENTITLEMENT_ENFORCEMENT_CONTRACT_V1.md) | §§7–10 versioned agreements/terms/evaluation; §§12–18 time/publication/projection; §§19–26 safety/launch/cutover; §§29–36 security/concurrency/shadow/cache; §§37–43 Corporate/tests/dependencies; §§46–47 acceptance/carry-forward | C3-AD-01–C3-AD-20 and M0–M7 meaning preserved; M3 does not finish later contract families |
| [M1a](CIVILPEDIA_COMMERCIAL_M1A_PRIVATE_CATALOG_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md) and [00022](../../../supabase/migrations/00022_commercial_private_catalog_foundation.sql) | Four private catalog tables, creator context, default privileges, RLS/ACL hardening | Existing schema, 34 constraints and migration history unchanged |
| [HARDEN-1](CIVILPEDIA_COMMERCIAL_HARDEN1_PUBLIC_PLANS_EXPOSURE_IMPLEMENTATION_CONTRACT_V1.md) and [00023](../../../supabase/migrations/00023_commercial_public_plans_exposure_hardening.sql) | Raw public.plans denial and no replacement public catalog API | No public GRANT, plans policy restoration, public proxy or financial leak |
| [M1b](CIVILPEDIA_COMMERCIAL_M1B_CATALOG_REFERENCE_DATA_IMPLEMENTATION_CONTRACT_V1.md) and [00024](../../../supabase/migrations/00024_commercial_catalog_reference_data.sql) | Exactly 17 + 23 = 40 canonical reference rows; D3-A; final original-code C′ rule; predecessor compatibility addendum | No reseeding, normalization, catalog activation or runtime entitlement by M3 |
| [Operating Model](../CIVILPEDIA_AGENT_OPERATING_MODEL.md) and [V1 Master Roadmap](../CIVILPEDIA_V1_MASTER_ROADMAP.md) | Agent routing, execution SSOT and separate authorization | UI CURRENT remains R10.5-D audit only; required commercial roadmap record is §31 below |

Later accepted records within each authority control its current state; earlier draft/acceptance-time authorization wording remains historical. In particular, M1b's current landed state comes from the current Owner instruction and baseline, not an inference that every earlier pause statement still governs execution. This draft does not edit those records or inherit M1b's seed authorization for M3.

## 3. Slice decision and sequence

Choose **internal evaluator infrastructure plus private shadow observations; defer physical publication snapshots and all commercial authority writers**. The evaluator can compute complete synthetic canonical cases in isolated tests and compare actual current Directory observations against explicitly incomplete commercial authority in runtime shadow work. It cannot truthfully report an actual production Business as canonically entitled today: purchased terms, grants and publication approvals are absent, and M1b references remain draft.

This limitation is intentional and reviewable. A comparison reporting INCOMPLETE_AUTHORITY is useful missing-authority evidence, not a completed M4 disposition or a disguised grant. If the Architect requires live purchased terms, catalog publication, authoritative grants or publishable production snapshots in the first M3 implementation, that requires a separately accepted expanded contract and authorization; it cannot be added while implementing this one.

Preserve C3's sequence: M1 private foundation; M2 approved catalog versions/bundles/prices; M3 internal evaluation/projection/shadow; M4 reviewed legacy classification/linking; M5 controlled public cutover. Landed M1b reference data is reusable catalog infrastructure, but its draft rows do **not** satisfy M2's approved-offer authority. Positive production evaluation awaits an approved catalog and canonical fact-provider contract. Neither dependency is silently implemented here.

Dual-read means internal comparison of two separately labelled outcomes. It never means legacy visibility OR canonical entitlement grants publication. The existing public Directory path continues to decide existing public reads until separately authorized M5.

## 4. Current physical audit

The classification labels in this table are scope decisions against current source, not declarations that legacy data meets frozen commercial requirements.

| Concept | Current physical finding / source | Classification | M3 use or deferral |
| --- | --- | --- | --- |
| Canonical entity identity | public.directory_entities UUID and accepted child relationships, [00005](../../../supabase/migrations/00005_directory_entities_and_categories.sql) | EXISTS AND REUSABLE | Read identity and current public observation; do not infer commercial eligibility from a legacy entity_type |
| Versioned catalog infrastructure | commercial_private.plan_versions, entitlement_bundles, bundle_items, term_prices, 00022/00024 | EXISTS AND REUSABLE | Preserve private structure and 40 canonical references; use explicit version compatibility, never implicit activation |
| Approved commercial offer | M1b versions/bundles/prices are draft with localization sentinel; the four canonical M1b public.plans identities are inactive; unrelated preserved legacy plans are not implied inactive | MISSING — DEFER TO LATER PHASE | Approved catalog/version sealing and new-offer authority require their own authorization; no draft-based purchase |
| Commercial agreement / purchase basis | [00008](../../../supabase/migrations/00008_plans_and_subscriptions.sql) subscriptions link entity/plan but lack canonical agreement and purchase evidence | EXISTS BUT LEGACY / NON-AUTHORITATIVE | Canonical agreement store/writers deferred; legacy comparison only |
| Purchased terms | Legacy started_at, nullable ends_at and numeric price_paid are not immutable purchased-term snapshots | MISSING — DEFER TO LATER PHASE | Pure evaluator input contract now; physical terms and creation authority later |
| Renewals / scheduled successors | No canonical predecessor chain, scheduled purchased successor or immutable extension history | MISSING — DEFER TO LATER PHASE | Validate synthetic chains; no new term or anchor writes |
| Entitlement grants | No canonical entitlement-grant authority | MISSING — DEFER TO LATER PHASE | Term/grant-aware kernel does not create a generic production grant engine |
| Launch Partner | No dedicated A8 program_versions/promotional_grants authority | MISSING — DEFER TO LATER PHASE | Dedicated A8 input semantics, zero production grants; no trialing import |
| Founding evidence | No canonical allocator, paid pricing-treatment evidence or badge/history authority | MISSING — DEFER TO LATER PHASE | Do not substitute Flutter flags; pricing facts remain future paid-term snapshots |
| Payment verification | Legacy price_paid/currency/status do not prove independently verified funds; no commercial order/allocation/verification store | MISSING — DEFER TO LATER PHASE | Require trusted evidence in synthetic input; no payment workflow |
| Current Directory publication | [00010](../../../supabase/migrations/00010_rls_authorization_baseline.sql) active-lifecycle RLS and current gateway SELECT | EXISTS BUT LEGACY / NON-AUTHORITATIVE | Authoritative for existing accepted public reads; non-authoritative for canonical commercial publication |
| Canonical publication authority | No selected approved-content pointer, readiness versions, commercial basis and launch/enforcement revision aggregate | MISSING — DEFER TO LATER PHASE | Composite kernel only; no pointer, publish/hide write or public read guard |
| Immutable public-safe snapshot | [00020](../../../supabase/migrations/00020_business_profile_management.sql) managed profile projection is mutable/current and includes claim/management fields | EXISTS BUT LEGACY / NON-AUTHORITATIVE | No reuse as a canonical immutable public snapshot; physical safe snapshots deferred |
| Canonical authority revision / generation | updated_at is optimistic profile concurrency, not commercial publication authority | MISSING — DEFER TO LATER PHASE | Missing production revisions remain NULL; separate shadow sequencing below |
| Enforcement / suspension | Legacy lifecycle has suspended; no canonical attributable enforcement/termination/closure authority with revisions | EXISTS BUT LEGACY / NON-AUTHORITATIVE | Observe legacy suppression; it cannot prove absence of canonical enforcement |
| Moderation approval | Application review/activation and verification statuses exist, but not the version-bound commercial content/readiness approval interface | MISSING — DEFER TO LATER PHASE | Explicit incomplete dependency, never ACTIVATED equals commercial approval |
| Launch-scope authorization | Categories/regions exist; no auditable commercial category-opening/Baghdad launch scope authority | MISSING — DEFER TO LATER PHASE | No is_active/category-count inference or launch event fabrication |
| Ownership / onboarding | [00018](../../../supabase/migrations/00018_business_application_activation_ownership_provisioning.sql) provisioning; [00019](../../../supabase/migrations/00019_business_ownership_management_foundation.sql) actor-bound management | EXISTS BUT LEGACY / NON-AUTHORITATIVE | Preserve accepted membership functions; they do not establish complete Primary Owner/recovery/commercial readiness |
| Business audit | [00009](../../../supabase/migrations/00009_audit_logs.sql) and accepted RPC audit calls exist | EXISTS BUT LEGACY / NON-AUTHORITATIVE | Preserve generic audit; no canonical commercial events/outbox or monetary provenance inferred |
| Commercial events / outbox | No canonical commercial domain-event/outbox authority | MISSING — DEFER TO LATER PHASE | Shadow evidence is not a purchase/payment/publication event ledger |
| Shadow comparison history | No current dedicated private comparison store | MISSING — M3 NEEDS IT | Add m3_shadow_runs, observational and append-only through supported path |
| Shadow ordering / replay control | No current observation-generation / request replay store | MISSING — M3 NEEDS IT | Add m3_shadow_heads; generation orders observations only, never grants authority |

## 5. Current gateways, tests and operational compatibility

[Directory gateway](../../../lib/features/directory/data/supabase_directory_read_gateway.dart) selects public.directory_entities and explicit category/location/contact/media relationships; 00010 filters entity and children through active parent lifecycle. It does not join commercial terms or invoke an entitlement evaluator. It has strict parsing, canonical UUID detail lookup and typed read failures. M3 leaves this query, DTO, RLS, paging behavior and cache contract unchanged.

[Auth gateway](../../../lib/features/auth/data/supabase_auth_gateway.dart) and [AuthProvider](../../../lib/features/auth/presentation/providers/auth_provider.dart) remain the accepted shared session/credential/recovery authority. [Membership gateway](../../../lib/features/business/data/supabase_business_membership_gateway.dart) uses own-membership reads and list_my_businesses/list_business_members; [profile gateway](../../../lib/features/business/data/supabase_business_profile_management_gateway.dart) uses the two existing managed-profile RPCs. None becomes a commercial or finance authorization interface.

The [Directory closure](../reports/V1-R05_DIRECTORY_CLOUD_INTEGRATION_CLOSURE.md) and [profile-management closure](../reports/V1-R06_BUSINESS_PROVIDER_PROFILE_MANAGEMENT_CLOSURE.md) are historical accepted reports. The observed lock ordering is taken from current SQL, including 00020's lock-before-membership check, rather than assuming that a summary saying authorization is enforced implies authorization precedes every lock.

The current predecessor SQL tests assert exactly four private foundation tables and no persistent private functions. The actual 00024 replay preflight has the same restriction. Therefore they are **checkpoint gates**, not valid unchanged whole-schema inventory gates after M3 adds objects. §27 defines mandatory tests both before and after M3; no migration history rewrite, skipped security assertion, or deletion of M3 objects to manufacture a post-M3 PASS is permitted.

## 6. Exact inclusions

1. Two private observation/control tables, four owner-only internal functions and the explicitly listed indexes/constraints in §§8–10.
2. A deterministic version-1 entitlement kernel and a separate publication-composite kernel consuming closed, validated canonical-input envelopes.
3. An owner-only synchronous runtime shadow capture that reads existing identity/current visibility, records absent canonical providers, and cannot receive fabricated entitlement inputs from its caller.
4. Isolated synthetic canonical truth tables for supported term, scheduled successor, A8, Corporate, time, publication and generation cases; fixture results are never production authority.
5. Private redacted result/version/mismatch evidence and replay/order controls.
6. Future migration, SQL/static/security/HTTP/atomicity and focused regression gates, including the two named predecessor static-test compatibility files and any subsequently proved/explicitly authorized exact snapshot path in §29.

## 7. Exact exclusions

No change to public visibility, lifecycle_status, Directory query/child RLS, cache authority, Auth, ownership or profile RPCs, Flutter, config.toml, API schemas, Realtime publication, existing catalog/security migrations, reference rows or commercial contracts. No public view/RPC or replacement raw-plans API. No catalog publishing, price/plan change, real customer order, payment verification/allocation, purchased-term write, refund/credit, renewal/reactivation workflow, A8 grant, Founding award, Corporate quote approval, production seed, legacy import/backfill/classification, numeric conversion, automatic repair or M5 cutover.

No persistent public-content snapshot, live publication pointer, authoritative generation writer, notification scheduler, background worker, generic promotion/rules engine or new database role. M3 does not install triggers in accepted tables. A public behavior change or any need to alter an excluded writer is a STOP / Architect scope decision.

## 8. Minimum data model and authority classes

| Layer | M3 physical treatment | Authority boundary |
| --- | --- | --- |
| A — Entitlement facts | Existing private reference catalog; transient typed/validated paid-term/A8 fixture envelope | No new agreement, payment, term, program or grant records; runtime missing provider stays missing |
| B — Publication facts | Transient version-bound readiness, ownership, moderation, enforcement, launch and continuity envelope | No stored approval flags or legacy status upgrades |
| C — Safe projection | Transient descriptor for fixture validation: format/content/selected revision and public-safe allowlist conformance | No content table, public snapshot, public RPC or future M5 pointer |
| D — Internal control | m3_shadow_heads | Observation ordering only; not canonical authority_revision or publication generation |
| E — Reconciliation evidence | m3_shadow_runs | Restricted evidence; not a commercial event/outbox, entitlement or publication decision |

All proposed physical objects live in existing commercial_private, owned by postgres, with its existing deny-by-default schema boundary. No separate commercial authority schema is introduced.

### 8.1 commercial_private.m3_shadow_heads

| Requirement | Proposed contract |
| --- | --- |
| Purpose / authority class | Serialize latest observation generation and request replay for one observed entity; observational control only |
| PK / uniqueness | entity_id UUID primary key; one head per observed UUID |
| Fields | entity_id; shadow_generation bigint initially 0 and nonnegative; created_at and updated_at timestamptz captured by server |
| FKs | No FK into public.directory_entities, Auth or catalog. Existing deletion/ownership behavior must gain no restriction or cascade from shadow evidence. Entity existence is checked at capture; an observational UUID may outlive its source |
| State / lifecycle | Generation increments exactly once per new committed run; no entitlement/publication state; 0 means no run, never canonical authority revision 0 |
| Mutation authority | Only m3_capture_shadow_v1 under direct postgres session; no client INSERT/UPDATE/DELETE or arbitrary head setter |
| Visibility / RLS | No client schema/table/column grants; RLS enabled, not forced, zero policies, same reviewed owner model as M1a |
| History / retention | Head is mutable control; historical observations are in runs. No automatic purge or legal-retention period invented; maintenance requires a separate bounded operational authorization |
| Production versus fixtures | Migration creates empty infrastructure. Authorized local validation uses rollback fixtures. A later explicitly authorized direct-server shadow exercise may write observations about existing entities, never commercial facts |

### 8.2 commercial_private.m3_shadow_runs

| Requirement | Proposed contract |
| --- | --- |
| Purpose / authority class | Append-only restricted observation, evaluator and mismatch history |
| PK / uniqueness | request_id UUID primary key; unique (entity_id, shadow_generation); replay for a different entity or expected input generation conflicts |
| FK | entity_id references m3_shadow_heads(entity_id), RESTRICT, no cascade. No FK into accepted public/catalog/Auth relations; referenced canonical input IDs are observational evidence, not relational purchase authority |
| Core fields | request_id and entity_id UUID; expected_shadow_generation and committed shadow_generation bigint; evaluator_version, input_version, calendar_rule_version, source_origin and input_fingerprint text; observed_at and recorded_at timestamptz; legacy_visible boolean; authority/entitlement/publication outcome and mismatch_category text constrained to the finite §33 vocabulary; reason_codes bounded text array; redacted result_summary JSONB with both observation-input revision fingerprints (§33.10); no additional revision table/column |
| Revision fields | authority_revision, projection_revision, authoritative_generation and candidate_generation nullable bigint. Missing actual canonical providers are NULL, never invented from updated_at or shadow_generation |
| Constraints / state | Generation greater than 0 and equal to expected + 1; bounded nonempty versions; allowed origin runtime_shadow or test_fixture; closed outcome/reason vocabulary; size limits; absent revisions cannot accompany an affirmative publication result. runtime_shadow rows require incomplete authority, UNKNOWN_FAIL_CLOSED entitlement/publication and NULL canonical revisions under this adapter; fixture rows cannot be promoted |
| Mutation authority | Supported runtime capture inserts only; no update/delete function. Database owner remains privileged, so append-only is a supported-writer invariant, not a claim that postgres cannot alter its own table |
| Visibility / RLS | Same owner-only, defensive unforced RLS and zero-policy posture as heads; no client raw JSON/result access |
| History / retention | Preserve committed observations and their original versions/time. Replay returns the historical record labelled as such, not current permission. No global cleanup job; fixtures roll back to exact entry baseline |
| Production versus fixtures | Empty after migration. Runtime capture hardcodes runtime_shadow and cannot accept a fixture envelope. Synthetic stored runs, if needed by SQL tests, use isolated rollback rows marked test_fixture; no fixture becomes runtime evidence |

Each captured run and head update commits together or neither. An existing request identity is checked for exact replay before rejection against the now-advanced head; replay rechecks origin, entity and the original expected-generation identity. A different identity conflicts. A stale expected shadow generation cannot advance the head for a new request. §33.10 freezes fresh/replay results and §33.11 error classes. Database errors produce no success record.

## 9. Exact proposed function inventory

These are private SQL-callable helpers, not exposed RPCs. Signatures and the complete named arguments/return columns in the normative §33 correction appendix are proposed implementation boundaries; changing them requires contract review before authorization. This appendix makes the v1 proposal precise; it does not freeze or accept the draft or authorize implementation.

| Function / signature | Behavior and output | Security / execution |
| --- | --- | --- |
| m3_evaluate_entitlement_v1(jsonb, timestamptz) | Pure validated canonical-input kernel; typed scalar result columns and a closed capability object (§12). Same envelope/version/as_of gives the same result | SECURITY INVOKER; IMMUTABLE only if all calendar operations use explicit timezone/input and no database lookup/time read; postgres only |
| m3_evaluate_publication_v1(jsonb, jsonb, timestamptz) | Validates a bound entitlement result plus independent publication facts; returns typed readiness/continuity/denial outcomes (§16) | SECURITY INVOKER; same purity condition; postgres only |
| m3_generation_matches_v1(bigint, bigint, bigint, bigint) | Strict comparison of authority/projection revision and authoritative/candidate generation; missing, negative or unequal value returns false | SECURITY INVOKER; IMMUTABLE; postgres only; no writer |
| m3_capture_shadow_v1(uuid, uuid, bigint) | Entity, request, expected shadow generation; captures server time and actual current-source observation, constructs incomplete canonical runtime envelope, calls kernels, atomically records redacted evidence | SECURITY INVOKER; VOLATILE; direct postgres session only; no caller clock, actor UUID, fact JSON, success flag or provider override |

All four functions set a fixed commercial_private, pg_temp search_path and fully qualify catalog/private/public references and required built-ins/operators where resolution could be injected. An invoker function cannot supply privileges missing from the caller. There is no SECURITY DEFINER in this proposed inventory. Introducing a definer, new helper, RPC, view, type, trigger, sequence or exposed wrapper is a scope change, not an implementation convenience.

Pure kernels' explicit time argument exists to test fixed boundary instants. It is not an operational clock interface: runtime capture supplies one database wall-time observation after its shadow lock; ordinary clients cannot execute any kernel. If implementation cannot satisfy IMMUTABLE semantics, STOP and correct the contract/signature classification before claiming determinism; do not mark a time-reading/database-reading function immutable.

## 10. Constraints, indexes and object bounds

Use UUID inputs and bigint generation, built-in scalar types, bounded JSONB envelopes/results and explicit CHECK/unique/FK constraints; no custom policy enum, serial/identity sequence or downloaded rule language. Name all new constraints/indexes deterministically with m3_shadow_heads or m3_shadow_runs prefixes. Preserve the four existing tables' 34 constraint names byte-for-byte.

The physical index inventory is deliberately small: heads PK for entity capture; runs PK for exact replay; unique runs (entity_id, shadow_generation) for latest history/ordered comparison; one runs (recorded_at, request_id) index for bounded operational time-window inspection. The unique entity/generation index also supports per-entity history; do not duplicate it. No guessed term/grant/projection index is installed on absent authority tables.

Proposed technical envelope limits: at most 64 KiB serialized input per kernel, 32 relevant term records, 8 grant records, 64 bundle items, and a bounded redacted run summary at most 16 KiB. These are evaluation-resource limits, not commercial term/grant quotas: overflow returns INCOMPLETE_AUTHORITY/INPUT_BOUND_EXCEEDED, never silently drops a conflicting record or selects the highest tier. A future fact provider must prove completeness of the bounded relevant window; exceeding it needs a separately reviewed query/interface adjustment.

## 11. Closed canonical input and provenance contract

Use the normalized, internally constructed version-1 JSONB envelopes defined exhaustively in §33, with fixed unique field names, scalar types, UUID/version links, cardinality and explicit presence markers; return the defined typed scalar columns. JSONB is transport for the small fixed kernel, not a dynamic rules engine. Reject malformed/unknown fields and duplicate semantic record identities under §33.2; do not claim to detect duplicate raw object keys after conversion to jsonb. No client-controlled SQL, identifier, function name, predicate or expression is executable.

Required entitlement input groups are entity identity/model eligibility; provider completeness/provenance; agreement ID/revision; immutable purchased term chain and approved extensions; pinned plan_version, registry version, bundle version/material-benefit snapshot; paid authorization or approved Corporate agreement reference; dedicated A8 program/grant facts; independent enforcement; and calendar-rule version. Distinguish an absent provider from a complete provider reporting zero applicable terms/grants. Legacy status cannot turn one into the other.

Required publication input groups are exact entity/requested scope; previously selected approved content and prior-publication event; fields-gate result bound to content and requirements versions; canonical onboarding/Primary Owner or authorized recovery continuity evidence; moderation/verification applicability and evidence; enforcement/closure; launch authorization; commercial basis/continuity; safe projection descriptor; authority revision and authoritative/candidate generation. The kernel requires explicit trusted evidence for each affirmative dependency; null or a raw legacy boolean cannot stand in for a pass.

Bind both kernels to the same entity, evaluator/input/calendar versions, provenance, synthetic-provider revision and as_of instant; publication names the exact entitlement input revision and its own composite input revision (§33.3). Publication rejects a result from a different binding. Fixture inputs require source_origin = test_fixture and may simulate complete accepted authority; actual runtime capture never loads a positive fixture or trusts a caller-supplied approval. Synthetic term/grant/provider facts and their positive results have zero production effect: privileges, observation-only table semantics and absence of a promotion/public mutation path establish safety independently of environment names. No M3 column represents current entitlement; no FK/function may promote a shadow row into canonical authority.

Current runtime adapter: read existing entity identity and the active-lifecycle public observation, with explicit named columns; do not read financial amounts or full raw subscriptions. Record canonical providers as unavailable, the M1b catalog as draft references, and revisions as NULL. This adapter yields INCOMPLETE_AUTHORITY for canonical entitlement and publication, even when legacy_visible is true. Adding a live provider or enabling a positive production result is outside this contract.

## 12. Typed entitlement outcomes

Outcome labels below are internal evaluator results, not new stored commercial lifecycle states. Keep basis status, time context, enforcement and usable capabilities separate, as C3 §10 requires.

| Output | Fixed semantics |
| --- | --- |
| authority_outcome | COMPLETE, INCOMPLETE_AUTHORITY, CONFLICTING_AUTHORITY or UNSUPPORTED_VERSION; required unknowns never produce a grant |
| basis_context | NONE, PENDING_ANCHOR, FUTURE, IN_EFFECT, GRACE or AFTER_GRACE when established; NULL when required facts are unknown. NONE means proven absence, not absent provider; selected source PAID_TERM or A8_PROMOTIONAL_GRANT only when established |
| entitlement_outcome | ENTITLED only for a complete, compatible in-effect paid/A8 basis; NOT_ENTITLED for complete known absence, pending/future/expired basis; otherwise UNKNOWN_FAIL_CLOSED |
| enforcement_context | Clear, warning, suspension, termination or confirmed permanent closure only when proven by canonical facts; otherwise unknown. Suspension may leave an in-effect purchased basis while denying its public use |
| continuity_eligible | Separate boolean for prior-publication Grace continuation; never the same as active paid/promo entitlement |
| source/version references | Agreement/term/grant, pinned plan/bundle/registry/evaluator/calendar identifiers and original/effective end; private only |
| capabilities | Known fixed supported keys with typed value and dependent-operation permission; no unknown/unlimited fallback; availability alone does not supply actor RBAC |
| next_boundary / reasons | Earliest relevant future time boundary and bounded internal reason codes; absent safe boundary cannot issue a publication lease |

Required grants/permissions in the result fail closed when authority is unknown. An enforcement denial does not rewrite purchased history or pretend payment never occurred. Grace has entitlement_outcome NOT_ENTITLED with continuity considered separately. No negative outcome changes current Directory visibility in M3.

## 13. Term/grant selection and version compatibility

Evaluate at one server-provided instant. Require a unique canonical entity/agreement, immutable approved purchase basis, compatible pinned registry/bundle and valid relevant intervals. Preserve retired purchased versions only with evidence they were approved when purchased and remain supported; draft versions cannot be treated as accepted offers. Missing bundle, version conflict, malformed required capability or unsupported rules denies the dependent operation; no default Business/Plus/free/unlimited plan.

Validate the complete relevant predecessor/successor chain before choosing a source. Half-open adjacent intervals do not overlap. At a successor start, an already purchased valid successor is recognized directly without a worker updating a current-term pointer; prior-term Grace cannot compete with the successor. Conflicting paid chains, duplicate bases, invalid predecessor links or overlapping paid/A8 benefits produce CONFLICTING_AUTHORITY, not stacking or highest-tier selection. Paid/A8 conversion remains excluded until its separate anchor-preserving source-switch contract is accepted.

An unanchored approved initial reservation can be PENDING_ANCHOR and may describe candidate first-publication readiness, but it is not in-effect entitlement or launch-density supply. M3 never creates its anchor. A due day-15 exception lacking reconciled trusted evidence/materialized authority remains incomplete; a read kernel does not invent a historical anchor or consume an order.

## 14. Supported catalog capability interpretation

| Existing M1b key | Supported type / frozen meaning | Limits on inference |
| --- | --- | --- |
| branches.included | Integer Business 1 / Pro 2 / Plus 3; Corporate Plus floor represented by 3 | Not an extra-Branch price/cap or Corporate ceiling |
| team.active_member_max | Integer 5 for ordinary plans; Corporate floor reference | Not an assignment of OWNER/ADMIN/financial authority or invented Corporate cap |
| media.upload_enabled | Boolean feature availability | No storage quota, count/size allowance or upload/security workflow inferred |
| analytics.available | Boolean feature availability | No metric definition, sale/lead assertion, visibility or retention right inferred |
| sponsored.purchase_eligible | Boolean prerequisite: false Business, true Pro/Plus; absent in current Corporate bundle | No campaign/payment/inventory grant; absence denies this prerequisite until approved compatible terms establish it |

These catalog values are reference semantics, not currently active production benefits. Unknown required keys deny their dependent capability; unknown optional keys confer no benefit. If a required dependency cannot be identified safely, the affected evaluation remains UNKNOWN_FAIL_CLOSED rather than assuming irrelevance. Public publication never follows merely from a true Sponsored/media/analytics flag.

## 15. Time, Grace, renewal and reactivation

Preserve C3 §§12–16 and AD-07/AD-08: UTC timestamptz instants, explicit Asia/Baghdad calendar-rule version, half-open intervals and server wall time. Add calendar days/months in Baghdad retaining local time-of-day, clamp absent target month days as accepted, then compare UTC endpoints. No device timezone, transaction-start time after a long lock wait, 30/90/365-day substitution or invented anniversary rule.

Payment Verification Time is not Subscription Term Start. Normal paid first-term start is successful public availability under the frozen publication rules. The sole-customer-delay exception needs documented requests and trusted historical cause at the end of the 14-calendar-day window; mixed/unknown/Civilpedia delay cannot activate it. Reactivation remains verified payment plus successful republication, non-retroactive. The evaluator consumes proven anchors/extensions; it writes none.

Paid/A8 in-effect intervals are [start, effective_end). Grace is exactly [effective_end, effective_end + 5 Baghdad calendar days); the exact Grace end is AFTER_GRACE. Grace is the frozen explicit continuation/exception after paid/promo expiry, not normal active entitlement and not first publication of a never-published Draft. Prior publication and no stronger denial are mandatory for continuity. No mutable permanent grace_active entitlement, management-access rule, analytics rule or Sponsored grant is created.

Early renewal starts at the previous effective paid end. Renewal during Grace starts at the original previous expiry, including accepted extensions, not the verification time. A valid scheduled successor can cover elapsed Grace under the frozen renewal rules. After Grace, a new pending reactivation cannot be backdated to old expiry. Time denial is computed even if every worker stops; M3 itself has no due-work/reminder writer.

## 16. Publication-composite kernel

Compute distinct outputs: intrinsic_readiness, candidate_first_publication_ready, continuity_eligible, and discoverability_outcome (ALLOW, DENY or UNKNOWN_FAIL_CLOSED) **for the internal evaluated case only**. They are not public mutations or discoverability permission for a real runtime entity. A candidate first-publication result cannot claim successful availability or start a clock. Runtime missing providers always keep discoverability UNKNOWN_FAIL_CLOSED.

| Required input | Affirmative proof required | Fail-closed / separation rule |
| --- | --- | --- |
| Entity/model identity | Genuine eligible commercial Business Entity in the requested canonical scope | No entitlement from a UUID, old type, lifecycle, branch duplicate or seed alone |
| Commercial basis | In-effect compatible approved paid/A8 basis; or proven prior-publication Grace continuation | Approved pending-anchor basis supports candidate readiness only, never current discovery |
| Required fields / quality | Accepted requirements version and result for the exact selected approved content | No arbitrary score; unresolved exact matrix OQ-76 and post-publication consequences OQ-48 stay blocked |
| Onboarding / ownership | Canonical readiness and accepted owner process; or explicit prior-publication recovery continuity without disqualifying risk | Legacy claim/OWNER rows do not prove it; recovery alone need not hide a previously approved entity |
| Moderation / verification | Version-bound approval and any circumstance-specific independent verification requirement | Full Verified is not universal; payment/entitlement neither grants Verified nor proves content approval |
| Enforcement / closure | Current attributable no-denial result | Suspension, termination and confirmed closure override use; warning or closure request alone is not automatically confirmed closure |
| Launch scope | Accepted market/category authorization and applicable scope revision | No raw category is_active or count-based auto-open; OQ-84 branches cannot choose continuation by default |
| Safe projection | Selected approved content descriptor, supported format and public-safe allowlist | Missing/unsafe/superseded content cannot rescue readiness |
| Generation consistency | Current authoritative facts revision equals the selected projection revision, and candidate generation equals current generation | NULL/mismatch/stale result denies; no updated_at or shadow-generation substitution |

PAID != VERIFIED; ENTITLED != PUBLISHED; PUBLISHED != VERIFIED; VERIFIED != SPONSORED. A paid term can exist while profile/moderation/launch readiness is absent. A previously selected approved snapshot is distinct from an unapproved proposed profile edit. M3 records unresolved affected branches without choosing new quality/takedown or ownership policy.

## 17. Projection decision and public-safe descriptor

M3 implements **no physical publication snapshot infrastructure**. This is evaluator/shadow infrastructure only; safe snapshot construction, immutable storage, publication pointer, guarded public DTO/RPC, paging, cache leases and actual writer integration remain separately contracted before M5. The existing managed-profile JSON projection is not promoted into that role.

Synthetic tests supply a transient approved descriptor and public-safe content fixture to validate the composite contract. Future content allowlist is canonical identity/type, approved name/description, authorized category/location or service area, intended public contacts/media, supported content-format revision and independently approved public trust labels. Reject payment evidence/amounts, payer/verifier/owner/staff identifiers, private invitation/raw claim metadata, fraud/risk notes, private audit IDs and internal reasons. No SELECT *, raw-row serialization or arbitrary nested client selection.

Only descriptor identifiers/revisions and a conformance result may enter restricted shadow evidence; do not persist public content or private input blobs in runs. A descriptor is derived evidence, not policy authority. Tests showing a valid descriptor do not constitute snapshot creation or M5 public publication.

## 18. Authority revision, generation and revocation

Canonical authority_revision identifies the committed selected commercial/publication facts; projection_revision binds derived content to that revision; authoritative_generation changes on every relevant invalidation; candidate_generation is what a computation observed. All four are distinct from observation-only shadow_generation. Actual missing canonical revisions remain NULL. Current updated_at and request IDs are not substitutes.

The generation helper requires complete matching pairs. A newer denial has a newer authoritative generation; an older computed projection cannot satisfy that current generation. Future integrated writers must synchronously invalidate/update canonical authority in the same transaction as content, enforcement, ownership, commercial or launch changes. Expiry/Grace-end is also checked by live server-time guards even without a generation write or worker. A late worker must compare expected revision/generation under the canonical lock and discard stale work; it must never clear a newer denial or select an old snapshot.

M3 tests prototype this invariant with synthetic revisions and shadow compare-and-set races. No actual public worker or revocation integration is installed. Passing the prototype is **not** proof that current 00020/profile/payment/enforcement writers maintain canonical generations.

Named mandatory carry-forward gate: **PRE-M5-PROJECTION-AUTHORITY-GENERATION-RECONCILIATION**. Before M5, independently test real authoritative writers, selected snapshot, live guard, expiry/Grace, current denials, request races, delayed computation, retry and every reachable old/public read path. Inject projection/facts revision and generation drift, including G0 finishing after G1 denial: the gate MUST FAIL, guarded read/publication decisions MUST DENY, and redacted operational alert/evidence MUST be produced. Reconciliation MUST NOT invent entitlement, manufacture missing authority, publish as repair, or let stale/delayed output overwrite newer denial. Assert those effects independently and re-run against the actual integrated schema/writers; a M3 fixture/prototype PASS cannot waive this C3 §47 obligation. This adds no M3 alert worker, snapshot or public endpoint.

## 19. Strict shadow execution and mismatch model

Capture computes, compares and records only. It never changes lifecycle, public visibility, legacy subscription, catalog state, ownership, content, entitlement or publication authority. No mismatch remediation, trigger, cron, event consumer, enabled periodic job or client entry point is included.

The synchronous direct-server capture observes one existing entity per bounded transaction. Runtime public observation is labelled legacy_active_rls, reflecting the current active-parent entity visibility predicate, not complete HTTP DTO/child validity or commercial publication approval. Tests separately verify actual HTTP Directory/child reads. No subscription value is required to calculate this current Directory predicate. Optional later legacy observation must remain redacted and separately authorized, with no price conversion.

| Mismatch category | Meaning / action |
| --- | --- |
| AUTHORITY_GAP_VISIBLE | Legacy observation visible; canonical providers incomplete. Record missing authority; do not hide or grandfather |
| AUTHORITY_GAP_NOT_VISIBLE | Legacy observation not visible; canonical providers incomplete. Record gap; no publish |
| LEGACY_VISIBLE_CANONICAL_DENY | Complete synthetic comparison denies a visible fixture; no Directory mutation |
| LEGACY_HIDDEN_CANONICAL_ALLOW | Complete synthetic comparison would allow a hidden fixture; no Directory mutation |
| MATCH_VISIBLE / MATCH_NOT_VISIBLE | Comparable complete fixture observations agree; agreement still grants no authority |
| INPUT_OR_VERSION_CONFLICT | Invalid/malformed/unsupported/completeness conflict; no affirmative result |
| STALE_GENERATION | Candidate revision/generation stale or expected shadow generation lost; no head advancement from stale request |
| EVALUATION_ERROR | Bounded failure/database error; report operational failure, no fabricated successful run |

Actual runtime adapter supports only missing-authority categories while authoritative providers are absent. Synthetic comparison categories are test_fixture evidence, never promoted to runtime truth. Request replay reports historical observed_at/origin separately; it cannot be interpreted as a new current evaluation.

## 20. Security contract for every object

| Object class | Owner / ACL / RLS | Actor and capability boundary |
| --- | --- | --- |
| Existing commercial_private schema | Preserve postgres ownership, existing owner-only USAGE/CREATE, no PUBLIC/anon/authenticated/service_role access | No new role, login or API exposure |
| Two new tables and their indexes/constraints | postgres; no nonowner table/column privileges; enabled unforced RLS, zero policies; internal FK only | Direct trusted DB owner writes via reviewed capture or isolated fixtures; no Business/staff/client grant |
| Four functions | postgres; SECURITY INVOKER, fixed safe path/qualified references; revoke PUBLIC EXECUTE and any client grants in same atomic migration | Only direct current_user = session_user = postgres with role setting none for runtime capture; log system origin, not spoofed auth.uid/user parameter |
| New views/RPCs/types/sequences/triggers | None proposed | Any addition requires scope review |
| Existing public/ownership/Auth objects | Existing owners, ACLs, RLS, signatures and source preserved | Membership/staff/application-review role does not inherit commercial finance/evaluation permission |

Carry M1a default privilege hardening forward for the verified creator: TABLES, SEQUENCES, FUNCTIONS/ROUTINES and TYPES deny nonowner PUBLIC/anon/authenticated/service_role privileges, including effective global defaults. Verify actual creator/default ACL before object creation and fresh-object probes afterward. Explicit per-function revokes are defense in depth, not a substitute for secure creator defaults. A mismatch stops implementation; do not weaken ownership/grants or use a broader server credential to bypass a failed gate.

Runtime capture's session context is its narrowly allowed system capability. No deployed operator login/role provisioning is authorized here; a production invocation needs a separately authorized operational mechanism. postgres is privileged and bypasses unforced owner RLS as in M1a, so RLS is defensive isolation, not a claim that owner access itself proves commercial approval. SECURITY INVOKER and no client execution avoid adding a definer escalation path. Any later definer needs a constrained reviewed owner, fixed commercial_private, pg_temp path/qualified references and independently derived actor/target capabilities.

API schemas/config.toml, PUBLIC grants, raw public.plans denial and Realtime inventories remain unchanged. No secrets, auth JWTs, financial data, receipt URLs, staff notes or service_role credentials enter shadow JSON or Flutter. Test schema USAGE/CREATE and SELECT/INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER, column privileges, function EXECUTE and forged-role/session paths. Use genuine authenticated HTTP probes; a fabricated JWT or SET ROLE alone does not replace the API gate.

## 21. Concurrency and current writer audit

| Existing path | Actual ordering / observation | Required M3 boundary |
| --- | --- | --- |
| 00018 activation | auth.uid and staff activation permission checked, then application row lock, then entity lock/provisioning; audit in accepted transaction | Do not call it while holding entity-first commercial locks; no activation integration |
| 00019 ownership reads | Actor-bound membership read and OWNER/ADMIN management helper | No commercial lock/writer; membership is not term/finance authority |
| 00020 profile update | Requires actor, locks entity FOR UPDATE, then checks management membership and expected_updated_at; accepted profile/child writes and audit | Lock-before-authorization security/lock-order concern remains explicit future integration obligation; do not silently patch it |
| New capture | Only its private shadow head is write-locked; no public entity/application/catalog/payment row lock or writer invocation | Cannot join/invert existing application/entity hierarchy or block accepted deletion through a new FK |

For capture, use a bounded consistent repeatable-read transaction established by the direct runner. Require it explicitly; an incompatible context fails before writing. Validate the direct session and arguments, inspect request identity, and return a matching historical replay before any stale-head rejection, time recapture, source reread or head mutation. For a new request, lock/create the single shadow head, recheck request identity after serialization, then validate expected generation; only afterward capture fresh database wall time and read the consistent source snapshot (§33.10). Record snapshot provenance and time. Snapshot consistency is not proof of live canonical writer integration or instantaneous revocation; M3 output is observational only. A later source edit does not turn an old record into a current grant. Serialization/database failures roll back; an explicitly directed retry uses the same request identity and original arguments, never blind mutating retry.

The supported implementation is synchronous, with no external two-stage worker. Concurrent new requests with the same expected generation yield one committed advance and a stale/conflict outcome for the other; exact replay yields one original run. Fixture delay tests must prove old expected generations cannot overwrite a newer record. Batch operational work, if separately authorized, calls one entity at a time with explicit bounded selection; no Directory N+1 invocation or new batch scheduler.

Retain C3's future authority hierarchy: catalog/program reservations, transfer reservations, launch scopes, sorted entity rows, then declared private aggregates/order/payment/term rows. M3's isolated shadow locks do not instantiate that end-state. Before integrating 00020 or 00018, freeze the exact shared lock order and authorization-before-lock implications and test all writers. Serialization/lock/database failures roll back; no blind mutation retry.

## 22. Legacy boundary, A8, Founding and Corporate

public.subscriptions statuses trialing, active, past_due, canceled and paused remain legacy evidence. None maps automatically to a purchased term, paid verification, Grace, A8 grant or canonical denial-clear state. lifecycle_status, claim, OWNER membership, Flutter PlanType, featured and foundingPartner likewise grant nothing. M4 owns reviewed classification/linking and the evidence-backed numeric(12,2) price_paid to integer-IQD conversion, including rounding; M3 reads no amount, converts nothing and decides no mapping.

A8 Launch Partner is a **dedicated promotional source**, not a paid term or generic grant-engine fallback: approved program/grant identity/version, normally-once genuine-entity evidence, Business Pro at 0 IQD, 60 Baghdad calendar days, start at the later governing anchor of formal commercial launch or the Business's **first successful public publication AFTER that launch**, as defined by the Frozen Model. Pre-launch publication alone cannot satisfy the publication-side anchor. Require independent fixtures for pre-launch publication only, launch without qualifying publication, first qualifying post-launch publication, and coordinated launch/publication under accepted C3; do not invent a different strict-inequality policy. Reserved/unanchored promo is not active supply. No card, auto-charge or auto-renewal; promotional Grace does not count as active launch density. M3 needs the typed A8 input interface and synthetic cases, **not physical program/grant infrastructure or production grants**. OQ-72 and OQ-80/OQ-81-dependent duplicate/revocation/continuity branches remain unresolved.

Founding Partner remains paid-term pricing treatment plus badge/history, not free entitlement or an A8 alias. Preserve frozen ordinary/Founding annual prices and reference rows without deriving eligibility from labels or percentage math. Counter/evidence, short first-term pricing and badge/copy branches remain with OQ-01/OQ-02/OQ-14; M3 implements no allocator, award or public badge.

Corporate remains custom quote with all Business Plus entitlements as its floor, written duration/terms and at least 12-month commitment; no retail term_price is required. A complete synthetic approved Corporate basis may be evaluated without a retail price row, but needs accepted quote/material-benefit evidence and compatible floor. Current reference 3 branches / 5 team is a floor, not a negotiated ceiling or unlimited plan. No custom scale, payment schedule, quote approval or missing Sponsored prerequisite is invented. Corporate written payment authority is explicit, not universal retail-prepaid enforcement or a name-based bypass.

## 23. Launch and open-policy behavior

Intrinsic per-entity readiness is separate from category-opening authority, avoiding recursive counting. Future density counts distinct genuine entities with in-effect qualifying paid basis or authorized active A8 plus intrinsic publishability; it excludes duplicate branches, incomplete/suspended/terminated/closed and Grace-only bases. Preserve BAGHDAD FIRST, initial five-Business gate, 8–10 and approximately 30 targets, no automatic 5-to-4 shutdown and honest zero-supply state. No fake/free padding or automatic non-Baghdad expansion.

M3 neither opens a category nor persists a flag answering post-promotion policy. OQ-84 remains unresolved; any case requiring its continuation/re-gating/Coming Soon answer yields an explicit blocked dependency. A test may exercise known frozen rules with supplied already-authorized scope evidence; it cannot label one unresolved OQ-84 outcome approved.

## 24. Performance and observability

Actual runtime query shape is a primary-key entity observation plus one private head/replay and bounded run insert. Explicit columns only, no aggregate full-table financial scan, arbitrary nested private joins, Directory per-row evaluator or public counts based on shadow results. Use the indexes in §10 and test execution plans at justified fixture sizes. Stop on oversized input; do not implement cache/worker optimization without a reviewed query shape.

Future term/grant providers must use entity/agreement plus current/relevant scheduled-window indexes, program/entity identity, canonical revision/selected projection lookup and next validity-boundary queries. Those indexes belong to their future physical writers, not this migration. Avoid requiring a worker-maintained current-term pointer for a scheduled successor.

Restricted run evidence must include evaluator/input/calendar versions, observed server instant, request/system origin, entity UUID, input fingerprint and completeness, typed basis/use/publication result, missing/conflict reason categories, actual-or-NULL revisions, observation generation and mismatch category. Recorded time is distinct from observed/effective time. Do not store complete input envelopes, personal actor data, payment identifiers/amounts, financial evidence or raw profile content. Hashes are operational equality checks, not anonymization or independent proof of authority.

Monitor aggregate gaps, unsupported-version counts, conflicts, stale requests, evaluation errors and capture latency without exposing reasons publicly. Failed transactions leave no success run; report redacted SQLSTATE/operation correlation outside the failed transaction through the authorized local evidence report, not a fabricated committed audit event. No monitoring vendor, exported dashboard, outbox or automatic repair is authorized.

## 25. Failure-mode contract

| Case | Internal evaluator/control result | Effect on existing public authority |
| --- | --- | --- |
| Canonical provider absent | INCOMPLETE_AUTHORITY / UNKNOWN_FAIL_CLOSED, revisions NULL | None |
| Complete provider has no term/grant | NOT_ENTITLED; no continuity without proven expired prior publication | None |
| Pending or future basis | No current entitlement; pending first-publication readiness separate | None |
| Overlap, duplicate source or bad chain | CONFLICTING_AUTHORITY; no tier selection/stacking | None |
| Unsupported non-overlapping paid/A8 conversion | INCOMPLETE_AUTHORITY / POLICY_DEPENDENCY_BLOCKED; no implicit source-switch policy | None |
| Draft/unapproved/unsupported catalog or missing bundle | UNKNOWN_FAIL_CLOSED or dependent capability denied | None |
| Malformed value/unknown required key/oversized input | Dependent use denied; incomplete/invalid result, no truncation | None |
| Paid/A8 expires | Active entitlement ends exactly at endpoint; evaluate separate Grace continuity | None |
| Grace ends / never-published Draft in Grace | Deny continuation/new discovery; worker lag cannot extend interval | None |
| Suspended/terminated/confirmed closed | Public-use override denies even if historical basis in effect | None |
| Missing moderation/quality/ownership/launch requirement | UNKNOWN_FAIL_CLOSED; unresolved policy branch marked blocked | None |
| Missing/unsafe/stale selected projection | Deny internal discoverability; no old-content fallback | None |
| Revision/generation missing or mismatch | Deny; candidate cannot replace newer denial | None |
| Delayed request / worker prototype | Stale expected shadow generation cannot advance head; future candidate denied | None |
| Duplicate request | Same entity/expected generation returns labelled original history; changed identity conflicts | None |
| Retry after unknown result | Explicit status inspection by request ID before separately directed retry; no blind replay | None |
| SQL/serialization/lock/context error | Entire capture rolls back; no success row, no fabricated COMPLETE result | None |

## 26. Migration sequencing and atomicity proposal

Propose one future migration, next free prefix **00025**, exact proposed filename `supabase/migrations/00025_commercial_entitlement_evaluator_shadow.sql`. Recheck next-free prefix against HEAD/origin and migration inventory immediately before any future authorization. A different occupied prefix requires an Architect-recorded naming adjustment, never renumbering/replacing 00024. This drafting pass creates no SQL.

Future migration must verify the actual trusted creator/session and supported execution context (the predecessor source requires direct postgres and PostgreSQL 17), 00022 default ACLs, HARDEN-1 denial, accepted catalog/security fingerprints, absent target objects and zero scope drift before additive DDL. Re-establish the runner-owned transaction evidence in that live context. Create only the objects listed here; preserve existing function/policy/trigger/role/default/security definitions and all 40 rows. Include postconditions for exact new inventory, zero nonowner grants, zero public mutation and empty shadow tables. No production capture/fixture insert or catalog update in migration.

Runner owns atomicity. Preserve no authored BEGIN/COMMIT/ROLLBACK and no transaction=false directive in migration source. Test a controlled **same-file late-failure** after actual object creation/postconditions in a disposable context using the supported runner; prove all new objects/receipts disappear, migration history does not record success and the entire prior data/security baseline remains unchanged. A separate unrelated failing transaction is not migration atomicity evidence. Test replay/conflicting pre-existing objects fail without partial effects; no blind mutation retry.

## 27. Mandatory future test contract

No gate below is claimed run or passed by this draft. Future evidence reports include exact commands, live context, test counts, boundary instants, fingerprints, role/HTTP provenance and cleanup verification; static PASS cannot substitute for PostgreSQL/API evidence.

Normative independent-oracle rule: expected schemas, field names, values, outcomes, time boundaries, reason codes, generation results and fixture relationships MUST be hand-authored from frozen authorities and accepted contracts, including the subsequently accepted §33 interface. Tests MUST NOT derive expectations from the migration/function bodies under test or rows just produced by the implementation. Implementation output is the ACTUAL side, never the oracle. Pin accepted historical checkpoints independently; do not regenerate snapshots from changed actual output to obtain PASS.

| Gate | Required evidence |
| --- | --- |
| A — Static migration contract | Unique 00025 name/ordering; immutable 00001–00024 and contracts/config/Flutter; exact two tables/four invoker functions; deterministic names/constraints; explicit column reads; no grants/proxy/old-writer change; runner-owned atomicity; empty infrastructure/no seed |
| B — SQL object/evaluator matrix | Exact inventory, validated envelopes/typed outputs, completeness versus known absence, supported retail/A8/Corporate and negative cases; valid scheduled successors without pointer worker; no overlapping/highest-tier fallback |
| C — Privileges/RLS/defaults | postgres creator, secure global/schema defaults, fresh table/sequence/function/type privilege probes with rollback, owner-only effective ACLs, RLS enabled/zero policies, no schema exposure/Realtime, all client EXECUTE/table/column denials |
| D — Time boundaries | Exact start/end/Grace end, Baghdad five/14/60-day instants, month-end/leap-year purchased months, renewal before expiry/during Grace, non-retroactive reactivation, verified versus publish anchor, unsupported/missing causal day-15 proof |
| E — Publication truth table | Entitlement alone insufficient; quality/ownership/recovery/moderation/verification applicability/enforcement/launch/projection composition; no universal Verified; paid and A8 Grace prior-publication cases; unresolved policy branches blocked |
| F — No automatic authority | Lifecycle active, claim, OWNER/ADMIN/MEMBER, PlanType, featured, foundingPartner and each legacy status individually and combined never confer a basis, actor capability or canonical readiness |
| G — Shadow isolation | Visible/hidden Directory fixtures, mismatches and failed capture leave entity/children/lifecycle/legacy/catalog/Auth/security fingerprints unchanged; only new shadow records may differ; fixture evidence cannot become runtime origin |
| H — Generation prototype | Missing/different revisions/generations deny; newer denial beats delayed candidate; same expected shadow generation race permits one advance; original run immutable through supported path; replay payload conflict rolls back |
| I — Fault/rollback | Database/serialization/error paths, invalid context, lost race, duplicate request, explicit reread semantics, capture atomicity and actual same-file migration late-failure rehearsal |
| J — HTTP security | Fresh PostgREST schema-cache handling and documented readiness; anon and genuine authenticated public.plans denial; nested relationship leakage denial; no commercial_private/functions exposure or replacement API |
| K — Positive regressions | Directory entity/child reads and detail canonical IDs, Auth/profile-own access, existing ownership/managed-profile RPC and permission denials; shared Supabase/AuthProvider/cache source unchanged |
| L — Final fingerprints / cleanup | Exact 40 canonical rows and all unrelated data/security unchanged; no production term/grant/payment/approval facts; shadow fixture/head/run/probe/temp role/object cleanup returns to entry baseline; staged list empty and diff check clean |

### 27.1 Predecessor checkpoint and post-M3 composition

On a disposable local validation database, first apply the immutable chain through 00024 and run the **unchanged** [M1a SQL](../../../supabase/tests/commercial_m1a_private_catalog_foundation_test.sql), [HARDEN-1 SQL](../../../supabase/tests/commercial_harden1_public_plans_exposure_test.sql) and [M1b SQL](../../../supabase/tests/commercial_m1b_catalog_reference_data_test.sql) gates, including M1b's actual-file replay/conflict/security fixtures. Record their exact counts and phase baseline. Do not replay 00024 against an expanded private schema or call a failure caused by its accepted four-table precondition an M3 implementation defect.

Then apply 00025, including a separate full clean-chain reset through the new migration. The new M3 SQL gate must explicitly reassert **every retained foundation/security/catalog obligation** in the composed state: four original tables and definitions/34 constraints/accepted indexes intact; exact 40 canonical rows/tuples and no extras; raw plans/policy/ACL denial; all six private tables with correct owner/RLS/no policies/nonowner table/column ACLs; exactly four new private functions with invoker/path/no client execute; no extra private/public proxy, view, trigger, type, role, API schema or Realtime exposure; unchanged defaults and fresh-object probes; unrelated table/routine/security fingerprints and Directory/Auth/ownership positive/negative controls. It cannot check only total row counts or declare checkpoint PASS sufficient for post-M3 security.

This split preserves predecessor gates and their historical inventory semantics while testing the entire expanded production security boundary. Existing predecessor SQL files and migration preflights remain unchanged. If a required retained assertion cannot be reproduced at the post-M3 boundary, STOP for an explicit compatibility decision; do not skip/weaken it.

### 27.2 Focused static / Flutter regressions

Run the new proposed M3 Dart static test and the [M1a static](../../../test/commercial_m1a_private_catalog_migration_test.dart), [HARDEN-1 static](../../../test/commercial_harden1_public_plans_exposure_migration_test.dart) and [M1b static](../../../test/commercial_m1b_catalog_reference_data_migration_test.dart) gates with explicitly pinned historical and composed-phase expectations. Inventory-only compatibility is insufficient: M1b fixes 24 files/00024 last, freezes predecessor tests and its contract against ebaf5f7b4402366285e214eec99735a931b69d8d, and rejects all tracked/untracked lib/docs changes. The accepted predecessor compatibility addendum/test changes already differ from that old checkpoint. The M3 contract and future accepted commercial roadmap record add intentional documentary differences. HARDEN-1 also freezes the roadmap against its historical baseline. These are scope/snapshot compatibility obligations, not permission to weaken security or catalog assertions.

Before execution authorization, record exact conflicting assertions and approved expected deltas for both named static files (§29). Preserve immutable migration history and historical checkpoint validity; explicitly recognize the already accepted M1b compatibility changes and the accepted M3 contract/governance record in composed-phase expectations. Keep lib/**, unrelated documents, config, seed, exact catalog tuples, grants/RLS/defaults, C′ and every semantic/security assertion protected. Use a deterministic declared phase/checkpoint, never nonempty rows, filename presence or a wholesale new-baseline snapshot to waive checks. No test is edited in this correction pass. M1a currently needs no additional static edit; any further proven conflict requires an enumerated path/assertion-level Architect amendment before editing. Post-M3 security/catalog obligations remain fully reasserted under §27.1.

Focused production-source regressions include [Directory integration](../../../test/v1_r05_directory_cloud_integration_test.dart), [Auth gateway](../../../test/supabase_auth_gateway_test.dart), [AuthProvider](../../../test/auth_provider_test.dart), [ownership management](../../../test/v1_r03_business_ownership_management_test.dart), [profile management](../../../test/v1_r06_business_profile_management_test.dart) and [profile server](../../../test/v1_r06_profile_management_server_test.dart). No repository-wide suite is authorized by this draft; live SQL lint and targeted security/HTTP gates are mandatory during a separately authorized implementation.

## 28. Rollback, acceptance and independent review

M3 rollback disables the private shadow invocation. Public Directory authority was never switched; no entitlement is invented/deleted. Preserve valid evidence/history and existing tables/data. Removing new objects, if desired, needs a separately authorized additive rollback migration and bounded evidence-retention decision; do not edit committed migrations, drop accepted objects, grant raw plans, reset production data or restore a weaker public policy.

Future implementation acceptance requires all §27 gates, zero public/Flutter/cache behavior delta, exact authorized file/object scope, no canonical grants/purchases/approvals seeded, complete redacted report and zero residual fixtures. No final security acceptance can be self-issued by the implementer.

Independent review must confirm: current-source physical audit; evaluator-only decision and absent-provider honesty; no draft catalog approval; closed typed/provenance boundary; frozen term/Grace/A8/Corporate interpretation; separate publication gates; NULL canonical revisions versus shadow sequence; no hidden public/authority writer; effective ACL/default/path/role security; existing lock-order preservation; checkpoint plus complete composed regression plan; real API and atomicity evidence; all dependencies/OQs and roadmap authorization prerequisites; rollback with no new grant. Review must decide whether this restricted infrastructure slice is useful/acceptable before any implementation authorization.

## 29. Proposed future implementation allowlist

This is a proposal for a later explicit authorization, **not permission to edit these paths now**.

| Proposed path | Exact future permitted change |
| --- | --- |
| supabase/migrations/00025_commercial_entitlement_evaluator_shadow.sql | New additive empty infrastructure and exact four functions/two tables; no accepted authority/data mutation |
| supabase/tests/commercial_m3_entitlement_evaluator_shadow_test.sql | New SQL/pgTAP truth tables, composed security/catalog regressions and fully rolled-back fixtures |
| test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart | New static migration/scope/semantic contract tests; no production Flutter |
| test/commercial_m1b_catalog_reference_data_migration_test.dart | Future explicitly authorized compatibility only: exact 00001–00024 historical prefix plus 00025; phase-aware documentary/source-scope expectations for already accepted predecessor compatibility changes, accepted M3 contract and committed commercial governance record; narrowly corresponding HARDEN-1 expected-test reconciliation. Preserve all semantic/security/catalog assertions and unrelated-file protection |
| test/commercial_harden1_public_plans_exposure_migration_test.dart | Future explicitly authorized compatibility only: exact historical roadmap prefix plus the reviewed committed commercial control record in composed-phase expectations; any mechanically corresponding approved snapshot literals. No grants/RLS/raw-plans/default/catalog/security assertion change |

The five-path proposal names the three new implementation artifacts and the two static compatibility files proved necessary by independent source review. This is a conditional future compatibility reconciliation, not authority to edit tests now. At execution preflight enumerate exact affected assertions, accepted historical checkpoints, expected documentary suffixes and the approved composed-phase phase detector. Preserve all original migration, seed, C′, security and catalog meaning; do not broadly allow arbitrary migrations, documents or test rewrites. A further necessary inventory/document-snapshot file must be proved from implementation evidence and added by exact path and assertion boundary through Architect authorization before editing; this is not an open wildcard allowlist.

No predecessor SQL edit, contract/roadmap/config edit, production lib/** edit or additional report/script file belongs to this implementation allowlist. Required governance changes are a separate documentary pass before implementation, not an implementation-time exception. If an authorized executor needs more files or schema objects, STOP and obtain a concrete Architect boundary amendment.

## 30. Carry-forward dependencies and unchanged OQs

| Dependency / frozen register trace | Handling in M3 / owner of later completion |
| --- | --- |
| Approved versioned catalog (C3 M2/AD-01/AD-18) | Draft M1b references stay draft. Catalog publishing/localization/sealing and positive production consumption need their own accepted authority |
| Agreement/terms/payment writers and immutable benefits | Kernel input only; canonical fact provider and authorization later; no screenshot/price/status shortcut |
| A8 dedicated grant/launch event and conversion | Synthetic accepted ordinary rules only; production grants and paid/promo source switch separately contracted |
| Required fields/content/moderation — OQ-48/OQ-49/OQ-76 | No new matrix/approver/takedown policy; affected actual readiness incomplete |
| Ownership/RBAC/invitation — OQ-77/OQ-78/OQ-79/OQ-82/OQ-83 | No OWNER mapping to Primary Owner/finance authority; no recovery/invitation implementation |
| Launch/duplicate policy — OQ-72/OQ-80/OQ-81/OQ-84 | Preserve genuine-entity requirement and explicit missing approval; no duplicate merge or post-promotion default |
| Founding — OQ-01/OQ-02/OQ-14 | No pricing eligibility/counter/badge inference |
| Limits/access/analytics — OQ-03/OQ-12/OQ-16/OQ-17 | No provisional quota, Grace management or analytics-retention grant |
| Verification/content/Branch/closure — OQ-13/OQ-19/OQ-52/OQ-54/OQ-56/OQ-57/OQ-68/OQ-71 | Scope-specific independent interfaces; no generic Verified/closed-link/re-entry default |
| Payment/representation/legacy/legal — OQ-09/OQ-10/OQ-15/OQ-22/OQ-23/OQ-40; P-34 and D-19 | No rail/fraud/reference/catalog-policy answer, seed disposition, proration formula or legal retention invented |
| C3 §47 M4 numeric conversion | Evidence-backed integer-IQD conversion and rounding remain M4; no numeric casting in evaluator/runtime evidence |
| C3 §47 00020 integration | Authorization/lock-order and synchronous canonical invalidation explicitly deferred; separately accepted integration required |
| C3 §47 pre-M5 projection/facts gate | Named §18 gate must run against actual snapshot and writers before public cutover; M3 prototype does not discharge it |
| Directory/cache/old-client compatibility and safe public DTO | No new lease/TTL/offline rule or route; mandatory accepted M5 dependencies |
| Predecessor gate compatibility | Phase-pinned SQL/historical static checkpoints plus complete composed regression (§27); exact future M1b and HARDEN-1 static compatibility boundaries (§29), with no security/catalog weakening |

Every other OPEN OQ also remains unchanged. The Frozen Model's register remains 84 registered / 48 OPEN / 36 CLOSED; zero closed, narrowed, reclassified or reopened by this draft. C1 ARs, C2 ARs and C3 ADs keep their substantive meaning. Missing technical providers are documented dependencies, not new commercial policy answers or invented OQ resolutions.

## 31. Roadmap / governance prerequisite

The separately authorized commercial backend drafting track does not unlock R10.5-D implementation or R10.5-E and later UI work. The current roadmap states R10.5-D CURRENT / AUTHORIZED for focused pre-implementation audit only, implementation NO; its production boundary remains unfrozen. The roadmap is untouched in this pass.

Frozen Model §33.2 requires a separately authorized slice with a frozen contract, file boundary/test gate and its own IMPLEMENTATION_AUTHORIZED: YES in the roadmap. **Before M3 implementation**, identify, separately authorize, persist and Owner-commit a bounded commercial-track control record in docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md: M1b closure at the verified committed baseline; separately controlled commercial M3; exact accepted contract/version; the five enumerated paths and any subsequently proved/authorized exact compatibility path; migration name and required gates; explicit M3 YES only when actually granted; no public cutover/seed/paid-term authority; unchanged R10.5-D audit-only control and later UI locks. Persist acceptance and explicit authorization in this contract without rewriting drafting history. No roadmap file or UI phase control is edited by this correction pass, and no broad governance rewrite is proposed.

The accepted committed governance record is an explicit expected documentary delta, not a security/catalog change. Mechanically affected static snapshots may be reconciled only through the precise future §27.2/§29 authorization, preserving the historical roadmap prefix and accepted UI locks. Identify that reconciliation before implementation; do not execute with known-red snapshot assumptions or silently rebaseline the suites. Documentary acceptance/commit remains Owner/Architect work; this correction grants no staging/commit authority.

Neither current user authorization to **draft** nor approval of this proposal supplies that roadmap YES. Do not edit roadmap or promote an implementation phase during drafting. If governance remains absent at execution preflight, STOP for the exact documentary action above rather than infer authorization from landed M1b or filenames.

## 32. Drafting scope, Git safety and review handoff

Current authorized write scope is exactly this new Markdown file. No migration, SQL test, Dart test, Flutter, contract authority, roadmap, config or accepted baseline file is edited. Existing dirty files and untracked artifacts remain protected. No runtime operation, production/cloud change, staging, commit, push, reset, revert, stash or clean is authorized/performed in this drafting pass.

Draft validation must establish: HEAD/local origin/main unchanged; staged list empty; this file the only new task delta; all pre-existing tracked/nonignored untracked bytes unchanged against the entry manifest; local links resolve; Markdown tables and fences structurally valid; no migration/test created; git diff --check clean. Untracked document formatting must also be checked directly, since ordinary git diff does not include an untracked file. These documentary checks do not constitute implementation acceptance.

Status at handoff remains **DOCUMENT_STATUS: DRAFT — READY FOR ARCHITECT REVIEW**, **ARCHITECT_ACCEPTANCE: PENDING** and **IMPLEMENTATION_AUTHORIZED: NO**. Request focused independent re-review of the bounded correction appendix, absent production authorities, generation prototype limits, checkpoint/composed gates, two named static compatibility paths and governance prerequisite. No future contract family is self-authorized.

## 33. Normative v1 interface correction appendix — acceptance pending

CORRECTION_DATE: 2026-10-04. Authority: Owner-requested bounded correction of independent review C, three MEDIUM/four LOW. This appendix supersedes only the affected conceptual interface/compatibility descriptions, preserving the original evaluator/shadow design. It is a precise proposal for independent review, not Architect acceptance or implementation permission. DOCUMENT_STATUS remains DRAFT — READY FOR ARCHITECT REVIEW; ARCHITECT_ACCEPTANCE remains PENDING; IMPLEMENTATION_AUTHORIZED remains NO.

### 33.1 Shared representation and finite vocabularies

All JSON object field sets below are closed and exhaustive. **Every listed field is required**, including fields whose value may be JSON null; no optional/omittable fields or aliases exist. Every returned SQL column exists in exactly the listed order. Tables' `Null` column specifies JSON null/SQL NULL permission; a conditional null rule further restricts it. A forbidden null/wrong scalar shape uses INVALID_FIELD_TYPE unless §33.11 names a more specific failure; a well-typed cross-entity/reference/revision link violation uses BINDING_MISMATCH unless a specific chain/anchor/duplicate rule applies. Structural failure is a typed fail-closed return for kernels, an exact exception for capture, or false for the generation helper (§33.11). No coercion of strings to numbers/booleans, fallback enum, extra object key or executable expression is allowed. Shared shape names are documentation definitions, not additional SQL types/functions. PostgreSQL argument-conversion errors occur before entry and retain their native SQLSTATE for every function; the typed kernel guarantee covers representable SQL arguments, including SQL NULL and non-finite timestamptz values.

| Type notation | PostgreSQL / JSON representation and validation |
| --- | --- |
| UUID | uuid / lowercase canonical 36-character UUID string; nil UUID forbidden; entity links must equal root entity_id; fixture UUIDs are non-production identities, not a new Business identity authority |
| I | bigint / integral JSON number within 0..9223372036854775807; field-specific minimum applies; no numeric strings/fractions |
| TS | timestamptz / UTC string YYYY-MM-DDTHH:MM:SS.ffffffZ with exactly six fractional digits; finite valid Gregorian year 0001..9999; no infinity/-infinity, leap-second spelling, invalid date, implicit timezone or client-clock authority |
| H | text / exactly 64 lowercase hexadecimal characters, SHA-256 observation fingerprint under §33.3; not an approval signature |
| B | boolean / true or false only |
| E(name) | text / exact case-sensitive token from the named vocabulary below; no whitespace/case normalization |
| J(shape) | jsonb / exactly the named object/array shape; nested unknown fields forbidden |
| Reasons | text[] / JSON array of distinct reason tokens in ascending bytewise ASCII order; 0..64 entries; no null element; empty only when no reason applies; no truncation |

For valid bindings all as_of values equal the function's p_as_of instant. Required evidence decision/recorded/purchase times cannot be after that instant. Future scheduled starts/ends are permitted only as validated committed interval boundaries. Timestamp arithmetic is exclusively accepted C3 §13 / §15 of this draft: Asia/Baghdad calendar days/months, retained local time, month-day clamping, half-open intervals. TS bounds are technical evaluator support, not a new commercial term limit; out-of-range authority fails closed.

| Vocabulary | Exact tokens |
| --- | --- |
| input_version | m3.input.v1 |
| evaluator_version | m3.evaluator.v1 |
| calendar_rule_version | m3.baghdad_calendar.v1 |
| envelope_kind | ENTITLEMENT_INPUT, PUBLICATION_INPUT, ENTITLEMENT_RESULT |
| source_origin | runtime_shadow, test_fixture |
| provider_status | COMPLETE, UNAVAILABLE |
| approval_state | APPROVED, PENDING, REJECTED, UNKNOWN |
| gate_status | PASS, FAIL, UNKNOWN, BLOCKED_POLICY |
| policy_dependency | OQ-48, OQ-49, OQ-72, OQ-76, OQ-77, OQ-79, OQ-80, OQ-81, OQ-82, OQ-83, OQ-84 |
| family | business, business_pro, business_plus, corporate |
| pricing_mode | retail, custom_quote |
| catalog_status | DRAFT, PUBLISHED, RETIRED |
| authority_outcome | COMPLETE, INCOMPLETE_AUTHORITY, CONFLICTING_AUTHORITY, UNSUPPORTED_VERSION |
| basis_context | NONE, PENDING_ANCHOR, FUTURE, IN_EFFECT, GRACE, AFTER_GRACE |
| source_kind | PAID_TERM, A8_PROMOTIONAL_GRANT |
| entitlement_outcome | ENTITLED, NOT_ENTITLED, UNKNOWN_FAIL_CLOSED |
| enforcement_context | CLEAR, WARNING, SUSPENDED, TERMINATED, CLOSED, UNKNOWN |
| term_purpose | INITIAL, RENEWAL, REACTIVATION |
| anchor_rule | PUBLICATION, CUSTOMER_DELAY_DAY15, RENEWAL_BOUNDARY, REPUBLICATION |
| delay_cause | CUSTOMER_ONLY, CIVILPEDIA, MIXED, UNKNOWN |
| authorization_kind | VERIFIED_FUNDS, CORPORATE_WRITTEN |
| value_kind | boolean, integer, text; registry v1 recognizes only the five key/type pairs in §33.4 |
| commercial_permission | ALLOW, DENY |
| intrinsic_readiness | READY, NOT_READY, UNKNOWN_FAIL_CLOSED |
| discoverability_outcome | ALLOW, DENY, UNKNOWN_FAIL_CLOSED |
| verification_requirement | REQUIRED, NOT_REQUIRED, UNKNOWN |
| verification_state | VERIFIED, UNVERIFIED, UNKNOWN |
| projection_kind | CANDIDATE, SELECTED |
| projection_format_version | m3.public_descriptor.v1 |
| market_context | BAGHDAD; other scopes are unsupported/deferred, never silently opened |
| comparison_target | legacy_active_rls, fixture_visibility |
| comparison_result | MATCH, DIFFERENT, INCOMPARABLE |
| capture_status | FRESH, REPLAY |
| mismatch_category | AUTHORITY_GAP_VISIBLE, AUTHORITY_GAP_NOT_VISIBLE, LEGACY_VISIBLE_CANONICAL_DENY, LEGACY_HIDDEN_CANONICAL_ALLOW, MATCH_VISIBLE, MATCH_NOT_VISIBLE, INPUT_OR_VERSION_CONFLICT, STALE_GENERATION, EVALUATION_ERROR |

Unknown input/evaluator/calendar/registry/catalog/bundle/A8-program/projection-format versions return UNSUPPORTED_VERSION and UNKNOWN_FAIL_CLOSED, never select a substitute. Numeric plan_version, bundle_version, registry_version and A8 program_version are exactly 1 in this v1 supported fixture interface. Support for any later numeric version needs an accepted compatibility amendment; this is not a permission to approve live v1 rows. Unknown enum/type/shape values follow §33.11. All other OPEN policy dependencies remain unresolved under §30; the finite dependency field supplies no affirmative answer.

The **complete v1 reason vocabulary** is: INVALID_ENVELOPE, MISSING_REQUIRED_FIELD, UNKNOWN_FIELD, INVALID_FIELD_TYPE, INVALID_ENUM, INVALID_UUID, INVALID_TIMESTAMP, NONFINITE_TIMESTAMP, INVALID_GENERATION, INPUT_BOUND_EXCEEDED, UNSUPPORTED_INPUT_VERSION, UNSUPPORTED_EVALUATOR_VERSION, UNSUPPORTED_CALENDAR_VERSION, UNSUPPORTED_CATALOG_VERSION, UNSUPPORTED_BUNDLE_VERSION, UNSUPPORTED_REGISTRY_VERSION, UNSUPPORTED_PROGRAM_VERSION, UNSUPPORTED_PROJECTION_FORMAT, BINDING_MISMATCH, INPUT_REVISION_MISMATCH, DUPLICATE_TERM_ID, DUPLICATE_GRANT_ID, DUPLICATE_SOURCE_ID, DUPLICATE_CAPABILITY_KEY, DUPLICATE_REVISION_IDENTITY, CANONICAL_PROVIDER_UNAVAILABLE, RUNTIME_AUTHORITY_UNAVAILABLE, ELIGIBILITY_NOT_PROVEN, APPROVAL_NOT_PROVEN, CATALOG_NOT_APPROVED, BUNDLE_MISSING, CAPABILITY_MISSING, CAPABILITY_DISABLED, UNKNOWN_REQUIRED_CAPABILITY, MALFORMED_CAPABILITY, NO_APPLICABLE_BASIS, AUTHORIZATION_NOT_PROVEN, CORPORATE_TERMS_INVALID, INVALID_TERM_CHAIN, OVERLAPPING_BASIS, ANCHOR_PENDING, ANCHOR_EVIDENCE_MISSING, ANCHOR_CONFLICT, A8_PUBLICATION_ANCHOR_MISSING, POLICY_DEPENDENCY_BLOCKED, FUTURE_BASIS, TERM_EXPIRED, GRACE_CONTINUITY, GRACE_ENDED, PRIOR_PUBLICATION_NOT_PROVEN, ENFORCEMENT_UNKNOWN, ENFORCEMENT_DENIED, REQUIRED_FIELDS_NOT_PROVEN, ONBOARDING_NOT_PROVEN, MODERATION_NOT_PROVEN, VERIFICATION_NOT_PROVEN, LAUNCH_NOT_PROVEN, PROJECTION_NOT_PROVEN, GENERATION_MISSING, GENERATION_MISMATCH, ENTITLEMENT_NOT_IN_EFFECT, STALE_SHADOW_GENERATION, REQUEST_ID_CONFLICT, INTERNAL_EVALUATION_ERROR. These 64 internal evidence codes are never a public error/UX API. Kernels deduplicate/sort the applicable set; they must not invent more codes or truncate a set to hide a denial. Reason codes do not themselves create authority.

### 33.2 Normalized JSONB and semantic uniqueness

[PostgreSQL 17 JSON documentation](https://www.postgresql.org/docs/17/datatype-json.html) establishes that conversion to jsonb normalizes duplicate object keys and retains only the last value; earlier duplicate names/values cannot be recovered by a receiving function. **No M3 function promises raw textual duplicate-key detection.** Only reviewed internal constructors with fixed unique field names create the normalized input/result objects. Future external/raw ingestion needing textual-key rejection must validate before conversion through a separately reviewed boundary; no M3 ingestion API is introduced.

Within the normalized envelope, reject duplicate term_id, grant_id, consumed source_id across terms/grants, capability_key within one bundle, catalog (plan_version_id, plan_version) and (bundle_version_id, bundle_version) identities, extension_id, extension (term_id, revision) and repeated predecessor successors where a single chain is required. Reuse of the same approved catalog by distinct adjacent terms is valid through one catalog entry and is not a duplicate entitlement. Reuse of a proof reference alone is not source consumption. Objects cannot carry two semantic records by aliases. Array multiplicity is checked explicitly before hashing/selection; JSONB containment/set-like comparison is not a duplicate detector.

Cardinality is exact: root providers has six named members; terms 0..32; grants 0..8; catalog 0..40; each catalog items 0..64; extensions 0..32 in total across terms; result capabilities exactly five named keys; reason arrays 0..64. Publication gate_results has exactly eight named members. Kernels accept at most 64 KiB UTF-8 of normalized JSONB text each; the publication bound-result plus publication-envelope combined must meet that limit. Persisted redacted result_summary is at most 16 KiB. Overflow fails closed without dropping records; no quota/business-policy meaning is attached to these technical bounds.

### 33.3 Observation-input revision and exact binding

The entitlement envelope's input_revision and publication envelope's publication_input_revision are content fingerprints, **not monotonically increasing authority generations**. Calculate H as SHA-256 over UTF-8 PostgreSQL-17 JSONB text of the normalized closed object with only its own fingerprint member removed. Validate duplicates first. Sort terms by term_id, grants by grant_id, catalog by plan_version_id, items by capability_key and extensions by revision then extension_id using bytewise ASCII order; sorted order is required at the input boundary. Scalar formatting follows §33.1. The engine-major/string-format rule is part of m3.input.v1; do not use a client serializer or session timezone. As_of and all provider/catalog/benefit/publication facts remain inside the fingerprint. The entitlement-result result_fingerprint follows the same rule after removal of that one member. No new hash helper object/extension is authorized.

synthetic_provider_revision is an explicit positive fixture snapshot number when source_origin = test_fixture, and NULL for runtime_shadow. Individual provider/catalog/agreement/evidence revisions describe the supplied test facts and are included in the fingerprint; none is inferred from a plan label or legacy updated_at. Publication's entitlement_input_revision and entitlement_result_fingerprint must equal the bound kernel result; entity_id, as_of, input/evaluator/calendar versions, source_origin and synthetic_provider_revision must also match. The publication fingerprint includes those bindings and its entire independent composite envelope. Passing a hash proves observation equality, not commercial approval, provider truth or the existence of production records.

Persist both input fingerprints in the closed run summary; input_fingerprint is H of the closed two-member object {entitlement_input_revision, publication_input_revision}. Preserve originals on replay. Invariant: **M3 shadow_generation != future canonical authority_generation != future projection_generation in meaning; no equality or mapping is implied by matching numbers.** authority_revision/projection_revision and authoritative_generation/candidate_generation are the four separately supplied synthetic comparison values of §18; actual runtime values remain NULL. No observation fingerprint, fixture revision, request UUID or shadow head substitutes for them.

### 33.4 Entitlement input: exact root and shared fact shapes

Signature: m3_evaluate_entitlement_v1(p_input jsonb, p_as_of timestamptz). SQL NULL/invalid p_input or SQL NULL/non-finite/unsupported p_as_of returns the single fail-closed row under §33.11 (NULL p_as_of uses INVALID_TIMESTAMP). No database lookup, time read or mutation occurs.

| Root field | Type | Null | Exact meaning |
| --- | --- | --- | --- |
| envelope_kind | E(envelope_kind) | No | ENTITLEMENT_INPUT only |
| input_version | E(input_version) | No | m3.input.v1 |
| evaluator_version | E(evaluator_version) | No | m3.evaluator.v1 |
| calendar_rule_version | E(calendar_rule_version) | No | m3.baghdad_calendar.v1 |
| source_origin | E(source_origin) | No | Mandatory non-production test_fixture or restricted runtime_shadow |
| entity_id | UUID | No | Exact evaluated entity identity |
| as_of | TS | No | Equal to p_as_of |
| input_revision | H | No | Recomputed entitlement observation fingerprint |
| synthetic_provider_revision | I | Yes | >=1 for test_fixture; NULL for runtime_shadow |
| providers | J(Providers) | No | Exactly six completeness declarations |
| model_eligibility | J(Gate) | No | Genuine commercial eligibility proof; no legacy-type inference |
| agreement | J(Agreement) | Yes | NULL only for proven absence or unavailable provider |
| catalog | Array of Catalog | No | 0..40 pinned reference/material-benefit snapshots |
| terms | Array of Term | No | 0..32 complete relevant chain records |
| grants | Array of A8Grant | No | 0..8 relevant dedicated promo records |
| enforcement | J(Enforcement) | No | Independent current enforcement evidence |
| prior_publication | J(PublicationHistory) | Yes | Prior publication evidence for this source/entity; never a legacy active flag |

Providers is exactly {eligibility, agreement_terms, grants, catalog, enforcement, publication_history}, each a Provider with the three fields below. COMPLETE with an empty applicable array is proven absence; UNAVAILABLE is missing authority, never proven absence. V1 requires all six providers COMPLETE for a complete synthetic evaluation. A future narrower completeness/window interface requires review, not silent omission of conflict-bearing records.

| Provider field | Type | Null | Rule |
| --- | --- | --- | --- |
| status | E(provider_status) | No | COMPLETE or UNAVAILABLE |
| revision | I | Yes | >=1 for COMPLETE; NULL for UNAVAILABLE |
| source_origin | E(source_origin) | No | Equal to root origin |

| Gate field | Type | Null | Rule |
| --- | --- | --- | --- |
| status | E(gate_status) | No | PASS/FAIL require attributable evidence; UNKNOWN is missing proof; BLOCKED_POLICY is unresolved policy |
| entity_id | UUID | No | Equal to root entity_id |
| evidence_id | UUID | Yes | Non-null for PASS/FAIL; NULL for UNKNOWN/BLOCKED_POLICY |
| revision | I | Yes | >=1 for PASS/FAIL; NULL for UNKNOWN/BLOCKED_POLICY |
| decided_at | TS | Yes | Non-null and <=as_of for PASS/FAIL; NULL otherwise |
| content_revision | I | Yes | >=1 and equal to publication content_revision for fields/moderation/required verification; NULL for non-content gates or unavailable content |
| requirements_revision | I | Yes | >=1 for required-fields PASS/FAIL; NULL when not applicable/unknown |
| scope_id | UUID | Yes | Equal to requested scope_id for launch PASS/FAIL; NULL for non-scope gates |
| policy_dependency | E(policy_dependency) | Yes | Non-null only for BLOCKED_POLICY; NULL otherwise |

| Agreement field | Type | Null | Rule |
| --- | --- | --- | --- |
| agreement_id | UUID | No | Unique ordinary agreement for supplied entity |
| entity_id | UUID | No | Root identity |
| revision | I | No | >=1; every term links this exact revision |
| approval_state | E(approval_state) | No | Only APPROVED can support a paid basis |
| approval_evidence_id | UUID | Yes | Required for APPROVED; null does not mean approval |
| approved_at | TS | Yes | Required for APPROVED and <=as_of; NULL unless APPROVED |

| Enforcement field | Type | Null | Rule |
| --- | --- | --- | --- |
| context | E(enforcement_context) | No | CLEAR/WARNING are not denial; SUSPENDED/TERMINATED/CLOSED deny use; UNKNOWN never clears denial |
| entity_id | UUID | No | Root identity |
| evidence_id | UUID | Yes | Non-null for every known context; NULL for UNKNOWN |
| revision | I | Yes | >=1 for known context; NULL for UNKNOWN |
| effective_at | TS | Yes | <=as_of for known current context; NULL for UNKNOWN |

| PublicationHistory field | Type | Null | Rule |
| --- | --- | --- | --- |
| publication_event_id | UUID | No | Attributable successful public-availability event |
| entity_id | UUID | No | Root identity |
| source_kind | E(source_kind) | No | Exact prior paid/promo source |
| source_id | UUID | No | Selected term_id or grant_id, not consumed-order source_id |
| content_revision | I | No | >=1; historical approved content identity |
| available_at | TS | No | <=as_of and inside the source's proven publication history |

| Catalog field | Type | Null | Rule |
| --- | --- | --- | --- |
| plan_id | UUID | No | Exact family identity frozen in M1b §7.1 |
| family | E(family) | No | Match that identity; A8 uses business_pro |
| plan_version_id | UUID | No | Exact corresponding v1 identity in M1b §7.1 |
| plan_version | I | No | Exactly 1 supported |
| pricing_mode | E(pricing_mode) | No | retail for business/pro/plus; custom_quote for corporate |
| plan_status | E(catalog_status) | No | DRAFT cannot support purchase; RETIRED requires historical purchase approval/support |
| plan_published_at | TS | Yes | NULL for DRAFT; non-null for PUBLISHED/RETIRED |
| plan_retired_at | TS | Yes | Non-null only for RETIRED; >=plan_published_at |
| bundle_version_id | UUID | No | Exact family bundle identity in M1b §7.2 |
| bundle_version | I | No | Exactly 1 supported |
| registry_version | I | No | Exactly 1 supported |
| bundle_status | E(catalog_status) | No | Same lifecycle requirements as plan_status |
| bundle_published_at | TS | Yes | NULL for DRAFT; non-null for PUBLISHED/RETIRED |
| bundle_retired_at | TS | Yes | Non-null only for RETIRED; >=bundle_published_at |
| approval_evidence_id | UUID | Yes | Required to prove approved plan/bundle/material benefits; DRAFT uses NULL |
| approved_at | TS | Yes | Non-null with approved evidence; <=purchase/grant selection and <=as_of |
| snapshot_revision | H | No | Hash of this closed Catalog object with only snapshot_revision removed; item order normalized |
| items | Array of Item | No | 0..64; approved supported values must conform to frozen M1b §10; no invented quota/custom scale |

| Item field | Type | Null | Rule |
| --- | --- | --- | --- |
| capability_key | text/string | No | 1..128 ASCII characters; unique per bundle; registered key/type pairs below |
| value_kind | E(value_kind) | No | Exact scalar kind; no coercion |
| value_boolean | B | Yes | Sole non-null value for boolean |
| value_integer | I | Yes | Sole non-null value for integer |
| value_text | text/string | Yes | Sole non-null value for text; 1..256 nonblank characters; no executable meaning |
| is_required | B | No | Unknown required key denies; unknown optional key grants nothing |

The five registry-v1 pairs are branches.included/integer, team.active_member_max/integer, media.upload_enabled/boolean, analytics.available/boolean and sponsored.purchase_eligible/boolean. Known-key wrong-kind/multiple-value/null-value input is MALFORMED_CAPABILITY. Missing known keys deny their dependent prerequisite; missing ordinary required floor items make the basis incomplete. The Corporate v1 floor retains the four approved reference items; Sponsored may remain absent (dependent prerequisite denied) or be explicitly established by separately supplied approved written terms consistent with C3 §38. No negotiated custom scale/unknown key is implemented by v1. Plan/bundle approval and publication must precede or equal the relevant purchased_at/selected_at; a RETIRED version remains valid only for a basis acquired before its retired_at. Retirement cannot invalidate that approved historical snapshot. No kernel reads live draft rows as approved merely because these IDs are recognized.

### 33.5 Paid-term, anchor, extension and A8 fixture shapes

| Term field | Type | Null | Rule |
| --- | --- | --- | --- |
| term_id | UUID | No | Unique relevant term identity |
| source_id | UUID | No | Unique consumed paid-order/authorization identity; observational only |
| agreement_id | UUID | No | Match supplied Agreement |
| agreement_revision | I | No | Match Agreement.revision |
| plan_version_id | UUID | No | Resolve exactly one Catalog entry |
| bundle_version_id | UUID | No | Match that Catalog entry |
| purpose | E(term_purpose) | No | INITIAL/RENEWAL/REACTIVATION; conversion excluded |
| predecessor_term_id | UUID | Yes | NULL for INITIAL; required for RENEWAL/REACTIVATION and resolve supplied chain |
| duration_months | I | No | retail 1/3/12; Corporate >=12, approved written commitment |
| purchased_at | TS | No | <=as_of; approval/catalog support proven at this purchase instant |
| authorization | J(Authorization) | No | Independently approved funds or written Corporate condition |
| anchor_rule | E(anchor_rule) | No | INITIAL: PUBLICATION or proved CUSTOMER_DELAY_DAY15; RENEWAL: RENEWAL_BOUNDARY; REACTIVATION: REPUBLICATION |
| anchor | J(Anchor) | Yes | NULL is pending/unproven, never automatic historical start |
| original_end | TS | Yes | NULL with null anchor; otherwise accepted calendar-month endpoint from anchor.effective_at |
| effective_end | TS | Yes | NULL with null anchor; otherwise final approved extension endpoint or original_end |
| extensions | Array of Extension | No | Empty with null anchor; 0..32 total across terms; complete approved sequence |

| Authorization field | Type | Null | Rule |
| --- | --- | --- | --- |
| kind | E(authorization_kind) | No | VERIFIED_FUNDS for retail; Corporate requires CORPORATE_WRITTEN |
| state | E(approval_state) | No | APPROVED only permits approved purchase basis |
| evidence_id | UUID | Yes | Required for APPROVED; no screenshot/status substitution |
| decided_at | TS | Yes | Required for APPROVED; <=purchased_at and <=as_of; NULL unless APPROVED |
| quote_id | UUID | Yes | Required for approved CORPORATE_WRITTEN; NULL for VERIFIED_FUNDS |
| quote_valid_from | TS | Yes | Required for approved Corporate quote; NULL for retail |
| quote_valid_until | TS | Yes | Required for approved Corporate quote; >quote_valid_from; accepted within half-open interval; NULL for retail |
| quote_accepted_at | TS | Yes | Required for approved Corporate quote; <=purchased_at/as_of and inside validity; NULL for retail |
| commitment_months | I | Yes | Corporate >=12 and equals approved duration_months; NULL for retail |
| payment_condition | J(Gate) | No | PASS evidence for explicit agreed activation obligation; not universal Corporate retail-prepaid enforcement |

Corporate shape records the accepted quotation's actual validity; the accepted C3 default is 30 Baghdad calendar days unless explicitly specified. The kernel does not create a quote, invent a validity date or require a retail term_price. No money/receipt/payer data is needed in these transient fixtures.

| Anchor field | Type | Null | Rule |
| --- | --- | --- | --- |
| anchor_event_id | UUID | No | Proven materialized anchor decision, never a computed shadow success |
| entity_id | UUID | No | Root identity |
| effective_at | TS | No | Actual publication/republication instant, predecessor effective end, or approved day-15 rule deadline |
| recorded_at | TS | No | >=effective_at for initial/reactivation/day-15; renewal may be recorded before its scheduled effective_at; <=as_of |
| publication_event_id | UUID | Yes | Required for PUBLICATION/REPUBLICATION; NULL for other rules |
| requests_evidence_id | UUID | Yes | Required for CUSTOMER_DELAY_DAY15; NULL for other rules |
| delay_evidence_id | UUID | Yes | Required for CUSTOMER_DELAY_DAY15; historical causal proof at deadline; NULL otherwise |
| cause_at_deadline | E(delay_cause) | Yes | CUSTOMER_ONLY for valid day-15; NULL for other rules; mixed/unknown/Civilpedia cannot start |

Anchor validation never creates anchors: PUBLICATION/REPUBLICATION requires trusted successful availability proof at or after purchased_at and the independently approved activation obligation; day-15 effective_at equals verified-funds decided_at plus 14 Baghdad calendar days with documented requests/sole customer cause; renewal equals predecessor effective_end. RENEWAL requires the approved purchase/verification before predecessor Grace-end; exactly Grace-end is after Grace and requires REACTIVATION with new authorization and a new successful republication anchor. An unproven payment-operation case spanning that boundary remains POLICY_DEPENDENCY_BLOCKED, not a receipt-submission cutoff exception. A declared due day-15 basis without materialized proof is incomplete. An approved unanchored ordinary initial/reactivation basis is PENDING_ANCHOR, not ENTITLED. Extensions cannot create an initial anchor. First-term normal publication and paid renewal/reactivation remain accepted C3 semantics, not fixture-clock authority.

| Extension field | Type | Null | Rule |
| --- | --- | --- | --- |
| extension_id | UUID | No | Unique append-only approved adjustment identity |
| term_id | UUID | No | Match parent Term.term_id |
| revision | I | No | Contiguous 1..N, unique per term |
| evidence_id | UUID | No | Attributable approved extension proof; no quantum invented |
| recorded_at | TS | No | <=as_of |
| effective_end | TS | No | >previous approved endpoint; final entry equals Term.effective_end |

| A8Grant field | Type | Null | Rule |
| --- | --- | --- | --- |
| grant_id | UUID | No | Dedicated unique promotional identity |
| source_id | UUID | No | Unique approved reservation source, never legacy subscription ID conversion |
| entity_id | UUID | No | Root identity |
| program_id | UUID | No | Dedicated synthetic A8 program identity, not a fifth base plan |
| program_version | I | No | Exactly 1 supported |
| program_approval_evidence_id | UUID | No | Approved ordinary A8 program proof |
| grant_approval_evidence_id | UUID | No | Approved selection/grant proof |
| once_per_entity_evidence_id | UUID | No | Approved normal genuine-entity/once evidence; no new dedup algorithm |
| plan_version_id | UUID | No | Supported business_pro Catalog entry |
| bundle_version_id | UUID | No | Matching Pro bundle |
| selected_at | TS | No | <=as_of; catalog approval/support at selection |
| formal_launch_event_id | UUID | Yes | Non-null with formal_launch_at; absent is missing anchor dependency |
| formal_launch_at | TS | Yes | Formal event instant <=as_of; no guessed launch date |
| first_post_launch_publication_event_id | UUID | Yes | Non-null with qualifying first_post_launch_publication_at |
| first_post_launch_publication_at | TS | Yes | Qualifying first successful publication after launch, including accepted coordinated make-available boundary; pre-launch event invalid |
| start_at | TS | Yes | Proven materialized start = governing later anchor; never inferred/written by kernel |
| end_at | TS | Yes | Non-null with start_at; exactly start_at +60 Baghdad calendar days |
| exception_dependency | E(policy_dependency) | Yes | NULL for ordinary accepted rule; OQ-72/OQ-80/OQ-81-dependent exceptional case stays BLOCKED_POLICY |

Both A8 start/end are NULL while reserved/unanchored. Missing qualifying post-launch publication returns PENDING_ANCHOR plus A8_PUBLICATION_ANCHOR_MISSING, never max(launch, an older publication). Evidence pairs must be consistent; no start with absent launch/qualifying publication, overlapping paid/promo source or repeated ordinary genuine-entity grant is allowed. Renaming a program cannot authorize another ordinary grant. The eight-record input bound admits adversarial fixtures, not eight grants per entity. A paid/promo conversion relationship, even without overlapping intervals, remains a separately controlled transition dependency and yields INCOMPLETE_AUTHORITY/POLICY_DEPENDENCY_BLOCKED in this v1; overlapping bases remain CONFLICTING_AUTHORITY/OVERLAPPING_BASIS. Exceptions are not authorized by filling a UUID. No production program/grant/term record is created or linked by these shapes.

### 33.6 Entitlement return: exactly one typed row

Columns below are also the exhaustive ENTITLEMENT_RESULT JSON object supplied as publication's p_entitlement_result. JSON types follow §33.1; SQL timestamps serialize to TS, SQL NULL to JSON null, Reasons to an array. Construction is internal from the actual kernel row; arbitrary caller-created positive results are not an authorized call path. Validation/hashing/binding is required again at publication entry; a hash is not a privilege or signature.

| Return column (ordered) | PostgreSQL type / JSON shape | Null | Meaning |
| --- | --- | --- | --- |
| envelope_kind | text / E(envelope_kind) | No | ENTITLEMENT_RESULT |
| input_version | text / E(input_version) | No | Executed m3.input.v1 result format |
| evaluator_version | text / E(evaluator_version) | No | Executed m3.evaluator.v1 |
| calendar_rule_version | text / E(calendar_rule_version) | No | Executed m3.baghdad_calendar.v1 |
| entity_id | uuid / UUID | Yes | Validated root identity; NULL if binding header malformed |
| source_origin | text / E(source_origin) | Yes | Validated origin; NULL if binding header malformed |
| as_of | timestamptz / TS | Yes | Validated p_as_of; NULL if invalid/header mismatch |
| input_revision | text / H | Yes | Validated/recomputed observation revision; NULL on structural/fingerprint failure |
| synthetic_provider_revision | bigint / I | Yes | Validated fixture revision; runtime NULL |
| authority_outcome | text / E(authority_outcome) | No | Completeness/conflict/version dimension |
| basis_context | text / E(basis_context) | Yes | Proven time context; NULL for uncertain/conflicting basis |
| source_kind | text / E(source_kind) | Yes | Unique selected paid/A8 source only |
| entitlement_outcome | text / E(entitlement_outcome) | No | Active commercial basis only; Grace is NOT_ENTITLED |
| enforcement_context | text / E(enforcement_context) | No | Independent denial context; UNKNOWN if unproven |
| enforcement_revision | bigint / I | Yes | Validated Enforcement.revision; runtime NULL |
| continuity_eligible | boolean / B | No | Prior-publication Grace eligibility with no stronger denial; false if unproven |
| agreement_id | uuid / UUID | Yes | Paid source only; NULL for A8/unknown/none |
| term_id | uuid / UUID | Yes | Selected paid term only |
| grant_id | uuid / UUID | Yes | Selected A8 grant only; term_id and grant_id mutually exclusive |
| plan_id | uuid / UUID | Yes | Selected supported Catalog reference |
| plan_version_id | uuid / UUID | Yes | Pinned reference, never implicit current plan |
| plan_version | bigint / I | Yes | Selected supported version 1 |
| bundle_version_id | uuid / UUID | Yes | Pinned bundle |
| bundle_version | bigint / I | Yes | Selected supported version 1 |
| registry_version | bigint / I | Yes | Selected supported version 1 |
| snapshot_revision | text / H | Yes | Selected immutable Catalog material-benefit fingerprint |
| original_start | timestamptz / TS | Yes | Materialized source start; NULL for pending/unknown/none |
| original_end | timestamptz / TS | Yes | Original paid endpoint or fixed A8 endpoint |
| effective_end | timestamptz / TS | Yes | Final approved endpoint |
| grace_end | timestamptz / TS | Yes | effective_end +5 Baghdad calendar days |
| prior_publication_event_id | uuid / UUID | Yes | Proven history for selected source/entity |
| capabilities | jsonb / CapabilityMap | No | Exactly five fixed keys, even on denial |
| next_boundary | timestamptz / TS | Yes | Earliest relevant validated boundary strictly >as_of; NULL if none safely known |
| reason_codes | text[] / Reasons | No | Closed sorted internal reason set |
| result_fingerprint | text / H | No | Hash of serialized closed result excluding this column |

CapabilityMap has exactly the five keys in §33.4. Each value is exactly {value_kind, value, commercial_permission, reason_codes}: value_kind is integer for branches/team and boolean for the other three; value is the matching JSON scalar or null if absent/uncertain; commercial_permission is ALLOW/DENY; reason_codes is Reasons. ALLOW requires COMPLETE, ENTITLED, known compatible affirmative value (true for Boolean prerequisites; valid approved positive count for integer items) and CLEAR/WARNING, and means commercial prerequisite only, never actor RBAC, upload permission, Sponsored campaign or public publication. A valid false Boolean is retained as false with DENY/CAPABILITY_DISABLED. Missing/unsupported/expired/enforced inputs always DENY. Grace grants no undefined management/analytics/media/Sponsored access. Even all-true capabilities cannot publish. Valid purchased history may remain ENTITLED under SUSPENDED/TERMINATED/CLOSED while all public-use commercial permissions and continuity are denied.

Validate the complete chain before source selection. Adjacent valid successors take effect at their anchored starts without pointer updates; Grace cannot compete with a successor. At most one applicable base source; overlap/duplicate consumption/invalid chain is CONFLICTING_AUTHORITY. With complete known absence return COMPLETE/NONE/NOT_ENTITLED; with unavailable provider return INCOMPLETE_AUTHORITY/NULL/UNKNOWN_FAIL_CLOSED. Pending/future/expired/Grace cases are complete NOT_ENTITLED where facts are proven. For past disjoint intervals use the most recent proven effective end for time context; competing pending initial/reactivation reservations or divergent successor chains are conflicts, not highest-tier choice.

### 33.7 Publication input: exact independent composite envelope

Signature: m3_evaluate_publication_v1(p_entitlement_result jsonb, p_publication_input jsonb, p_as_of timestamptz). p_entitlement_result is exactly §33.6's internally serialized actual result. Both arguments are revalidated, including their fingerprints, finite types and binding. Malformed/unsupported/binding failures return the single §33.8 fail-closed row, not an exception; SQL NULL p_as_of uses INVALID_TIMESTAMP. No database read/write or clock read occurs.

| Publication root field | Type | Null | Exact meaning |
| --- | --- | --- | --- |
| envelope_kind | E(envelope_kind) | No | PUBLICATION_INPUT only |
| input_version | E(input_version) | No | m3.input.v1 |
| evaluator_version | E(evaluator_version) | No | m3.evaluator.v1 |
| calendar_rule_version | E(calendar_rule_version) | No | m3.baghdad_calendar.v1 |
| entity_id | UUID | No | Match entitlement result |
| source_origin | E(source_origin) | No | Match entitlement result |
| as_of | TS | No | Match result and p_as_of |
| synthetic_provider_revision | I | Yes | Same fixture revision as entitlement result; runtime NULL |
| entitlement_input_revision | H | Yes | Exact match to result.input_revision; NULL only when that validated fail-closed result has NULL input_revision; never permits affirmative publication |
| entitlement_result_fingerprint | H | No | Match recomputed result.result_fingerprint |
| publication_input_revision | H | No | Recompute composite fingerprint under §33.3 |
| legacy_visible | B | No | Actual legacy active-parent observation or separately labelled fixture observation; no commercial inference |
| scope | J(Scope) | Yes | NULL is unavailable requested canonical scope; not a default launch authorization |
| content_revision | I | Yes | >=1, exact proposed/selected approved content; NULL if unavailable |
| required_fields | J(Gate) | No | PASS bound to content and requirements versions |
| onboarding | J(Gate) | No | Accepted normal onboarding or attributable accepted prior-publication recovery continuity; never legacy OWNER count |
| moderation | J(Gate) | No | Bound independent approved-content decision |
| verification_requirement | E(verification_requirement) | No | Independent circumstance-specific applicability |
| verification_state | E(verification_state) | No | Independent evidence state; never derived from payment/publication |
| verification | J(Gate) | No | Evidence of applicable verification decision; NOT_REQUIRED needs applicability proof, not a fabricated Verified label |
| enforcement | J(Enforcement) | No | Match entitlement context/revision and root entity; no stale denial-clear override |
| launch | J(Gate) | No | PASS bound to Scope.scope_id and revision |
| projection | J(ProjectionDescriptor) | Yes | NULL means unavailable, never old-content fallback |
| prior_publication | J(PublicationHistory) | Yes | Match result.prior_publication_event_id/source/entity for continuation |
| authority_revision | I | Yes | Synthetic authoritative facts revision; >=0 if provided; runtime NULL |
| projection_revision | I | Yes | Synthetic selected projection binding revision; >=0 if provided; runtime NULL |
| authoritative_generation | I | Yes | Synthetic current authority generation; >=0 if provided; runtime NULL |
| candidate_generation | I | Yes | Synthetic computation-observed generation; >=0 if provided; runtime NULL |

| Scope field | Type | Null | Rule |
| --- | --- | --- | --- |
| scope_id | UUID | No | Canonical requested commercial scope in fixture, not a new stored authority |
| category_id | UUID | No | Explicit eligible category identity; no count/is_active inference |
| market_id | UUID | No | Explicit authorized geographic identity |
| market_context | E(market_context) | No | BAGHDAD only in supported v1 cases |
| revision | I | No | >=1; equals launch.revision when launch PASS/FAIL |

| ProjectionDescriptor field | Type | Null | Rule |
| --- | --- | --- | --- |
| descriptor_id | UUID | No | Transient approved descriptor identity, not a production snapshot row |
| entity_id | UUID | No | Root identity |
| content_revision | I | No | >=1; equal to root content_revision and content-bound gates |
| kind | E(projection_kind) | No | CANDIDATE for first-publication readiness; SELECTED for current discovery/continuity |
| format_version | E(projection_format_version) | No | m3.public_descriptor.v1 |
| approval | J(Gate) | No | PASS bound to entity/content; independent approval proof |
| public_field_paths | Array of text/string | No | 1..32 unique ASCII paths, sorted; only canonical_identity, entity_type, approved_name, approved_description, authorized_categories, authorized_geography, public_contacts, public_media, approved_trust_labels; no private nested path or wildcard |
| conformance | J(Gate) | No | PASS evidence bound to same content; public-safe allowlist validation, not mere absence of money from a sample |
| projection_revision | I | Yes | Equal to root projection_revision; NULL cannot allow discovery |
| candidate_generation | I | Yes | Equal to root candidate_generation; NULL cannot allow discovery |

The descriptor names/proofs are the closed M3 fixture interface, not a public DTO/schema or permission to store content. Hand-authored safe/unsafe content fixtures must separately test §17's recursive allowlist/privacy obligation and the conformance proof they supply; a field manifest alone does not certify a future snapshot builder or actual row values. Missing/unsafe/stale descriptors deny. Only allowed descriptor IDs/revisions/conformance summaries may be persisted; content/input blobs are excluded. Known private-field or wildcard manifests return PROJECTION_NOT_PROVEN, never ignore the offending path.

All Gate null/binding rules from §33.4 apply. Launch PASS/FAIL requires matching scope; verification REQUIRED requires VERIFIED plus bound PASS proof. NOT_REQUIRED may retain UNVERIFIED and still pass through proven applicability; UNKNOWN or missing applicability fails closed. BLOCKED_POLICY reports the exact validated dependency, including OQ-84, through the affected existing Gate's policy_dependency in the bound publication input together with the typed output; no separate OQ output column is required or authorized (§35). This reports dependency evidence without choosing continuation/re-gating or other policy. Known ownership recovery continuity requires prior publication and attributable accepted Gate evidence, not a new universal recovery exception.

### 33.8 Publication return: exactly one typed row

| Return column (ordered) | PostgreSQL type / JSON shape | Null | Meaning |
| --- | --- | --- | --- |
| input_version | text / E(input_version) | No | Executed v1 result format |
| evaluator_version | text / E(evaluator_version) | No | Executed evaluator version |
| calendar_rule_version | text / E(calendar_rule_version) | No | Executed calendar rule |
| entity_id | uuid / UUID | Yes | Validated bound identity; NULL on malformed binding header |
| source_origin | text / E(source_origin) | Yes | Validated origin; NULL on malformed binding header |
| as_of | timestamptz / TS | Yes | Bound instant; NULL on invalid/mismatched instant |
| synthetic_provider_revision | bigint / I | Yes | Bound fixture revision or runtime NULL |
| entitlement_input_revision | text / H | Yes | Validated/recomputed entitlement input revision; NULL on structural/binding failure |
| publication_input_revision | text / H | Yes | Validated/recomputed composite revision; NULL on structural/binding failure |
| authority_outcome | text / E(authority_outcome) | No | Entitlement plus composite completeness/conflict/version dimension |
| entitlement_outcome | text / E(entitlement_outcome) | No | Validated entitlement result; UNKNOWN_FAIL_CLOSED on invalid binding |
| enforcement_context | text / E(enforcement_context) | No | Independent current context, UNKNOWN if invalid/missing |
| verification_requirement | text / E(verification_requirement) | No | Proven applicability or UNKNOWN |
| verification_state | text / E(verification_state) | No | Independent trust state or UNKNOWN |
| intrinsic_readiness | text / E(intrinsic_readiness) | No | Per-entity readiness, separate from category/projection/generation authorization |
| candidate_first_publication_ready | boolean / B | No | Candidate-only readiness; never successful publication/anchor |
| continuity_eligible | boolean / B | No | Proven existing-publication Grace continuity after all current independent use gates |
| discoverability_outcome | text / E(discoverability_outcome) | No | Internal ALLOW/DENY/UNKNOWN only; no actual public effect |
| gate_results | jsonb / GateResults | No | Eight separate evidence dimensions below |
| authority_revision | bigint / I | Yes | Validated synthetic facts revision; NULL runtime/invalid |
| projection_revision | bigint / I | Yes | Validated synthetic projection binding revision; NULL runtime/invalid |
| authoritative_generation | bigint / I | Yes | Validated synthetic current generation; NULL runtime/invalid |
| candidate_generation | bigint / I | Yes | Validated synthetic observed generation; NULL runtime/invalid |
| generation_matches | boolean / B | No | Exact helper result; false on any missing/invalid comparison |
| legacy_visible | boolean / B | Yes | Validated observation; NULL on malformed input |
| comparison_target | text / E(comparison_target) | Yes | legacy_active_rls for runtime_shadow; fixture_visibility for test_fixture; NULL on malformed origin |
| comparison_result | text / E(comparison_result) | No | MATCH/DIFFERENT only for complete determinate comparison; otherwise INCOMPARABLE |
| mismatch_category | text / E(mismatch_category) | No | Deterministic mapping below, not remediation instruction |
| reason_codes | text[] / Reasons | No | Closed sorted union of applicable entitlement/composite reasons |

GateResults is exactly {required_fields, onboarding, moderation, verification, enforcement, launch, projection, generation}; each value is E(gate_status), non-null. It reports each dimension independently even where another dimension denies. Enforcement maps CLEAR/WARNING to PASS, SUSPENDED/TERMINATED/CLOSED to FAIL, UNKNOWN to UNKNOWN. Projection approval/conformance and revision binding must pass separately; generation is PASS only for exact complete comparison, FAIL for mismatched known pairs, UNKNOWN for missing values. No single Boolean absorbs verification, entitlement, enforcement or errors.

Intrinsic READY requires proven eligibility and approved commercial basis (including approved PENDING_ANCHOR candidate basis or proven Grace continuation), required-fields/onboarding/moderation/applicable verification and no enforcement denial; it excludes launch/projection/generation to avoid recursive density. Known failed intrinsic gates give NOT_READY; required unknown/blocked facts give UNKNOWN_FAIL_CLOSED. candidate_first_publication_ready requires a proven PENDING_ANCHOR basis, intrinsic READY, launch PASS, approved/conforming CANDIDATE descriptor and complete matching revision/generation inputs. It remains NOT_ENTITLED and cannot claim availability. Current ALLOW requires intrinsic READY, authorized launch, approved/conforming SELECTED descriptor, generation_matches, and either ENTITLED in-effect basis or proven prior-publication Grace continuity. No pending/future basis allows current discovery.

Structural/binding/version failure yields UNKNOWN_FAIL_CLOSED and false readiness/continuity flags. A validated actual entitlement result with a null input_revision is consumed only as its fail-closed state; publication does not invent a replacement fingerprint to make it affirmative. Its UNSUPPORTED_VERSION or CONFLICTING_AUTHORITY outcome propagates when the remaining validated bindings match; mismatched bindings follow §33.11. For valid semantic inputs, any proven stronger enforcement/projection/generation or required-gate denial yields DENY even if other facts are unknown; unknown/blocked requirements without proven denial yield UNKNOWN_FAIL_CLOSED. Unsupported versions remain UNSUPPORTED_VERSION. authority_outcome remains INCOMPLETE_AUTHORITY when required unknowns exist, independently of a known denial. A complete negative case is COMPLETE plus DENY. Runtime adapter always yields INCOMPLETE_AUTHORITY/UNKNOWN_FAIL_CLOSED, never a positive result.

Comparison mapping uses this exact precedence: invalid schema/version/binding/conflicting input -> INCOMPARABLE plus INPUT_OR_VERSION_CONFLICT; otherwise valid runtime_shadow -> INCOMPARABLE plus AUTHORITY_GAP_VISIBLE/NOT_VISIBLE according to the actual Boolean; otherwise fixture with stale known revision/generation -> INCOMPARABLE plus STALE_GENERATION; otherwise incomplete fixture comparison authority -> INCOMPARABLE plus INPUT_OR_VERSION_CONFLICT; otherwise complete fixture ALLOW with visible -> MATCH/MATCH_VISIBLE, ALLOW with hidden -> DIFFERENT/LEGACY_HIDDEN_CANONICAL_ALLOW, DENY with visible -> DIFFERENT/LEGACY_VISIBLE_CANONICAL_DENY, DENY with hidden -> MATCH/MATCH_NOT_VISIBLE. A well-formed bound entitlement result with UNSUPPORTED_VERSION propagates that authority outcome and never a positive publication result. Database errors are external EVALUATION_ERROR evidence, not a successful kernel/capture row.

### 33.9 Generation helper: exact arguments and Boolean contract

The ordered arguments are p_authority_revision bigint, p_projection_revision bigint, p_authoritative_generation bigint, p_candidate_generation bigint. They permit SQL NULL solely to represent missing evidence. Return type is boolean, exactly one non-null scalar. Return true iff all four are non-null, nonnegative, p_authority_revision = p_projection_revision and p_authoritative_generation = p_candidate_generation. Any NULL, negative or unequal pair returns false; zero is permitted synthetic comparison data, never invented production generation. No exception is raised for a representable bigint comparison. A caller value outside bigint or wrong SQL argument type fails PostgreSQL argument conversion before function entry; it is never coerced into a valid generation.

This tests a predicate, not a canonical lock/writer. A fixture that supplies two stale equal values does not prove freshness; the future PRE-M5 gate must obtain current authority under its real canonical lock and reject G0 against the committed G1 denial. The helper supplies neither revision nor permission.

### 33.10 Capture arguments, persistence, fresh/replay results and ordering

Signature: m3_capture_shadow_v1(p_entity_id uuid, p_request_id uuid, p_expected_shadow_generation bigint). Entity/request are mandatory non-null non-nil UUIDs; expected generation is mandatory, 0..9223372036854775806 (reserve headroom for exactly one increment). No other input, clock, fact JSON, positive flag, actor or environment token is accepted. Direct postgres session/context and repeatable-read transaction checks precede request/source inspection or mutation. Invalid arguments/context follow §33.11, never insert a run.

Ordered execution is normative:

1. Validate session and arguments. Look up request_id before comparing against current head or checking current entity existence.
2. If it exists, validate original origin runtime_shadow, entity_id, expected generation, committed generation = expected+1 and closed stored summary/fingerprints/versions. Exact match returns REPLAY; any identity conflict/corrupt original raises its declared error. Do not recapture time, reevaluate facts, check current head equality, advance head or insert a run. Replay survives source changes/deletion because it is explicitly historical evidence.
3. For a new identity, lock/create only its private entity head; recheck request identity before stale-head rejection. Then compare current shadow_generation to expected. Any lost race rolls back, including a newly created head; no conflicting current/latest record is fabricated.
4. Capture one finite database wall-time instant after the head lock; verify source entity exists and observe only explicit identity/lifecycle columns. legacy_visible is exactly the accepted active-parent predicate. Construct the exact runtime envelope below, hash, evaluate, and atomically insert one run/update the head to expected+1. observed_at is this captured instant; recorded_at is a finite database wall time >=observed_at captured for the insert, with no new evaluator as_of.
5. Same-request/new-request races under repeatable-read may produce native serialization/unique/lock failures because a snapshot cannot see a concurrent commit. Preserve those errors/rollback; do not silently start another transaction or manufacture replay. Only an explicitly directed status reread/retry in a new transaction with the same request identity and original arguments may return the now-committed historical result.

Runtime construction is structural: source_origin runtime_shadow; synthetic_provider_revision NULL; all six Provider statuses UNAVAILABLE/revisions NULL; model_eligibility UNKNOWN; agreement/prior_publication NULL; catalog/terms/grants empty; enforcement UNKNOWN. Publication scope/content/projection/prior_publication and all four canonical comparison numbers are NULL; all Gate statuses UNKNOWN with null evidence, verification requirement/state UNKNOWN. Identity, server as_of, versions and recomputed observation fingerprints are valid; legacy_visible is the actual observation. Kernels reject attempts to use a different affirmative runtime shape as INCOMPLETE_AUTHORITY/UNKNOWN_FAIL_CLOSED with RUNTIME_AUTHORITY_UNAVAILABLE. Runtime capture has no override input. Existing draft catalog remains infrastructure, not inferred entity-plan entitlement.

Fresh and replay return **the same complete ordered TABLE shape below**. Only capture_status/is_historical differ: FRESH/false versus REPLAY/true. All other values in replay are the validated originally committed record, never current-state permission. is_historical denotes replay provenance; even FRESH remains an observation rather than production authority.

| Capture return column (ordered) | PostgreSQL type / JSON meaning | Null | Fresh/replay rule |
| --- | --- | --- | --- |
| capture_status | text / E(capture_status) | No | FRESH or REPLAY only |
| is_historical | boolean / B | No | false for new row, true for original replay |
| request_id | uuid / UUID | No | Original command identity |
| entity_id | uuid / UUID | No | Original observed identity |
| expected_shadow_generation | bigint / I | No | Original expected head |
| shadow_generation | bigint / I | No | Original committed expected+1; >0 |
| source_origin | text / E(source_origin) | No | runtime_shadow only on this function's return |
| input_version | text / E(input_version) | No | Original m3.input.v1 |
| evaluator_version | text / E(evaluator_version) | No | Original m3.evaluator.v1 |
| calendar_rule_version | text / E(calendar_rule_version) | No | Original m3.baghdad_calendar.v1 |
| observed_at | timestamptz / TS | No | Original evaluated server instant |
| recorded_at | timestamptz / TS | No | Original committed evidence recording instant |
| input_fingerprint | text / H | No | Original paired-input fingerprint |
| entitlement_input_revision | text / H | No | Original summary member, no new column required |
| publication_input_revision | text / H | No | Original summary member |
| legacy_visible | boolean / B | No | Original actual observation |
| authority_outcome | text / E(authority_outcome) | No | INCOMPLETE_AUTHORITY only |
| entitlement_outcome | text / E(entitlement_outcome) | No | UNKNOWN_FAIL_CLOSED only |
| publication_outcome | text / E(discoverability_outcome) | No | UNKNOWN_FAIL_CLOSED only |
| comparison_target | text / E(comparison_target) | No | legacy_active_rls only; stored in summary |
| comparison_result | text / E(comparison_result) | No | INCOMPARABLE only; stored in summary |
| mismatch_category | text / E(mismatch_category) | No | AUTHORITY_GAP_VISIBLE or AUTHORITY_GAP_NOT_VISIBLE |
| authority_revision | bigint / I | Yes | NULL always under current runtime adapter |
| projection_revision | bigint / I | Yes | NULL always |
| authoritative_generation | bigint / I | Yes | NULL always |
| candidate_generation | bigint / I | Yes | NULL always |
| reason_codes | text[] / Reasons | No | Original closed reason set; includes CANONICAL_PROVIDER_UNAVAILABLE and RUNTIME_AUTHORITY_UNAVAILABLE |
| result_summary | jsonb / RunSummary | No | Original redacted closed object below; <=16 KiB |

RunSummary is exactly the required members in the following table. It is the same shape for runtime observations and separately labelled rollback test_fixture inserts; supported capture writes runtime only. Runtime constraints require the values above plus null catalog_binding, UNKNOWN enforcement/readiness, false candidate/continuity and eight UNKNOWN gates. Fixture inserts remain evidence, with no function promoting them. No full envelope, public content, order/term/grant/payment/evidence/payer identifiers or monetary data may be serialized here.

| RunSummary field | JSON type | Null | Rule |
| --- | --- | --- | --- |
| entitlement_input_revision | H | No | Original entitlement observation identity |
| publication_input_revision | H | No | Original composite observation identity |
| comparison_target | E(comparison_target) | No | Match provenance |
| comparison_result | E(comparison_result) | No | Match typed comparison |
| basis_context | E(basis_context) | Yes | Proven fixture context or runtime NULL |
| enforcement_context | E(enforcement_context) | No | Independent context; runtime UNKNOWN |
| intrinsic_readiness | E(intrinsic_readiness) | No | Runtime UNKNOWN_FAIL_CLOSED |
| candidate_first_publication_ready | B | No | Runtime false |
| continuity_eligible | B | No | Runtime false |
| gate_results | J(GateResults) | No | Eight explicit dimensions; runtime UNKNOWN |
| catalog_binding | J(CatalogBinding) | Yes | NULL for runtime/unknown; only nonfinancial selected references |
| snapshot_provenance | J(SnapshotProvenance) | No | Original observation execution context |

CatalogBinding is exactly {plan_id UUID, plan_version_id UUID, plan_version I, bundle_version_id UUID, bundle_version I, registry_version I, snapshot_revision H}, all required/non-null when the object exists, with the supported v1/catalog linkage rules. SnapshotProvenance is exactly {transaction_isolation, observation_time_basis}, both required non-null strings: repeatable_read and server_wall_after_shadow_lock for runtime; fixture_snapshot and fixed_fixture_instant for test_fixture. These finite context tokens are not environment-name security assumptions. Run table columns retain the typed authority/entitlement/publication outcomes, origin/versions/time/reasons/mismatch separately, as §8 requires; summary does not duplicate raw private facts.

Two tables/four functions remain the exact inventory. No table column means current entitlement; heads order observations only; runs store history/evidence only. No FK/function/public consumer can promote a row into production entitlement, selected publication or lifecycle state. Positivity in a synthetic result or fixture row has zero production effect by access restrictions, origin constraints, no supported promotion path and no authority/public mutation consumer. Rollback fixtures are cleanup discipline, not the underlying security assumption; postgres privilege is explicitly not claimed restricted by its own RLS.

### 33.11 Exact failure/error behavior and precedence

Both kernels return exactly one typed fail-closed row for every validation/version/semantic uncertainty listed here; they do not raise application exceptions for these cases. For structural/binding failure clear all source/catalog/time-context/reference/canonical-generation fields, preserve only completely validated binding header values, return INCOMPLETE_AUTHORITY (UNSUPPORTED_VERSION for a version failure; CONFLICTING_AUTHORITY for a duplicate semantic identity), UNKNOWN_FAIL_CLOSED, UNKNOWN enforcement/verification, all permissions DENY, false readiness/continuity/generation flags and INCOMPARABLE/INPUT_OR_VERSION_CONFLICT. Entitlement capabilities retain the exact five-key shape with null values/DENY. Publication gate_results is eight UNKNOWN members on structural failure. A fingerprint error clears binding fingerprints rather than echoing unvalidated assertions; result_fingerprint can still identify the well-formed fail-closed result row.

Choose the first structural failure in this fixed order, returning its single primary reason: serialized-size/array-cardinality bound; SQL-null/non-object root; missing field; unknown field; wrong scalar/nested type or required array order; invalid UUID; invalid/non-finite timestamp; unsupported version; invalid enum; semantic duplicate identity; wrong canonical fingerprint/binding. Within a stage traverse root/object paths in ascending bytewise ASCII order and arrays in their prescribed order. Invalid numeric revision/generation fields in the publication comparison use INVALID_GENERATION, rather than generic INVALID_FIELD_TYPE; valid present NULL values use GENERATION_MISSING. Never echo raw malformed data. Once structurally valid, accumulate all applicable semantic reasons deterministically under the finite vocabulary; unsupported required registry key remains a version/configuration denial, not a free feature. DB/resource/internal execution errors are not caught into a success row.

| Failure/input condition | Entitlement kernel | Publication kernel / helper or capture where applicable |
| --- | --- | --- |
| Malformed/non-object/SQL NULL envelope | Typed unknown, INVALID_ENVELOPE | Typed unknown, INVALID_ENVELOPE |
| Missing listed field | Typed unknown, MISSING_REQUIRED_FIELD | Same; nullable field must still be present |
| Unknown field/alias | Typed unknown, UNKNOWN_FIELD | Same; no ignored authority-bearing extension |
| Array outside its cardinality / wrong canonical order | Typed unknown, INPUT_BOUND_EXCEEDED / INVALID_ENVELOPE respectively | Same; no silent sort/drop to repair authority |
| Wrong type/invalid enum/UUID | Typed unknown, INVALID_FIELD_TYPE/INVALID_ENUM/INVALID_UUID by precedence | Same |
| Invalid timestamp | Typed unknown, INVALID_TIMESTAMP | Same; capture bad server/context timestamp aborts P3COR |
| Infinity/-infinity spelling/non-finite argument | Typed unknown, NONFINITE_TIMESTAMP | Same; helper has no timestamp input |
| Unsupported schema/evaluator/calendar/catalog/bundle/registry/A8-program/format version | UNSUPPORTED_VERSION + corresponding finite reason, unknown entitlement | UNSUPPORTED_VERSION/unknown discovery; helper no version input |
| Duplicate term/grant/source/capability/revision identity | CONFLICTING_AUTHORITY + corresponding DUPLICATE reason, unknown entitlement | Conflicting/unknown result or binding failure; never select a duplicate source |
| Catalog draft/unapproved, missing required bundle/capability | INCOMPLETE_AUTHORITY, CATALOG_NOT_APPROVED/BUNDLE_MISSING/CAPABILITY_MISSING; dependent permission DENY | No affirmative publication rescue |
| Unknown required capability key / wrong registered type | UNSUPPORTED_VERSION + UNKNOWN_REQUIRED_CAPABILITY / INCOMPLETE_AUTHORITY + MALFORMED_CAPABILITY | Unknown discovery; unknown optional key grants no benefit |
| Missing/unavailable provider | INCOMPLETE_AUTHORITY, CANONICAL_PROVIDER_UNAVAILABLE; never NONE | UNKNOWN_FAIL_CLOSED for required unavailable composite authority |
| Conflicting/overlapping term/grant/chain or anchor | CONFLICTING_AUTHORITY + INVALID_TERM_CHAIN/OVERLAPPING_BASIS/ANCHOR_CONFLICT | No current allowance; INCOMPARABLE conflict |
| Approved ordinary unanchored initial/reactivation | COMPLETE/PENDING_ANCHOR/NOT_ENTITLED + ANCHOR_PENDING | Candidate readiness possible only under §33.8; current discovery DENY |
| Due day-15 missing materialized proof; declared start missing anchor evidence | INCOMPLETE_AUTHORITY + ANCHOR_EVIDENCE_MISSING | No invented start or positive publication |
| A8 launch/qualifying publication absent | COMPLETE/PENDING_ANCHOR/NOT_ENTITLED + A8_PUBLICATION_ANCHOR_MISSING for an otherwise approved reservation | Current discovery DENY; no pre-launch/publication clock |
| Wrong/negative generation number | Not an entitlement field; unknown field rejected | Typed unknown + INVALID_GENERATION; helper false; capture P3ARG |
| Missing comparison field / present null generation | Not an entitlement field | Missing field: MISSING_REQUIRED_FIELD; present NULL: unknown + GENERATION_MISSING; helper false; capture NULL expected generation P3ARG |
| Known mismatched generation/revision pairs | No effect on purchased history | DENY + GENERATION_MISMATCH; helper false; stale new capture P3STA |
| Unresolved required OQ branch | INCOMPLETE_AUTHORITY + POLICY_DEPENDENCY_BLOCKED | UNKNOWN_FAIL_CLOSED/BLOCKED_POLICY; no default answer |
| Bound result/entity/version/as_of/revision mismatch | Typed input revision denial where applicable | Typed unknown + BINDING_MISMATCH/INPUT_REVISION_MISMATCH; no caller assertion accepted |
| Suspended/terminated/closed with valid purchased basis | History can remain ENTITLED; public-use permissions DENY + ENFORCEMENT_DENIED | DENY regardless of payment or other positive gates |
| Expired/Grace/after-Grace/future known basis | COMPLETE/NOT_ENTITLED with TERM_EXPIRED/GRACE_CONTINUITY/GRACE_ENDED/FUTURE_BASIS as applicable | Grace only preserves proven prior-publication continuation without stronger denial; future/after-Grace deny |
| Database/serialization/lock/resource/unexpected internal failure | Propagate original PostgreSQL error; no fabricated typed success | Same; capture atomically rolls back all head/run writes |

Capture application exception classes are exactly: P3ARG (NULL/nil/out-of-range argument), P3CTX (wrong direct role/session/transaction context), P3REF (fresh target entity absent), P3MIS (existing request reused for a different origin/entity/original expected generation), P3STA (new request's expected head stale), P3COR (corrupt original run/summary, unsafe server timestamp, nonconforming internal runtime output). Messages are those fixed class descriptions, without raw JSON/private data. Native PostgreSQL argument-conversion, SQL, lock, uniqueness and serialization errors retain their original SQLSTATE. Failed capture returns no success row/receipt; EVALUATION_ERROR is only redacted external diagnostic classification. Kernel validation paths have no P3 exception class. Any unclassified branch must STOP contract implementation rather than invent a token, catch-all grant or alternate representation.

### 33.12 Correction trace, acceptance boundaries and future independent vectors

M1 is addressed by §§33.1–33.11's exhaustive normalized input/nested shapes, typed results, finite vocabulary, fingerprints and function-specific errors. M2 is addressed by §11/§33.2's explicit post-jsonb boundary and semantic-identity checks. M3 is addressed by §§27.2/29/31's two exact future compatibility files, historical/composed checkpoints, accepted-record snapshot consequences and bounded conditional authorization. L1/L2/L3/L4 are addressed in §§22/18/27/4 respectively. No finding is self-revalidated or Architect-accepted by this correction record.

Future hand-authored vectors must enumerate each required field missing/null/wrong-type/unknown-key case; every supported and unsupported version; duplicate semantic identities; finite/non-finite timestamps; both input/result fingerprint mismatches; same/different entity/as_of/provider revision; complete empty versus unavailable providers; every paid/A8/Corporate interval/anchor branch; exact Grace endpoints; selected/candidate descriptor and eight gate dimensions; all generation null/negative/equal/mismatched cases; fresh capture, replay before stale-head rejection, identity conflict, concurrent same/different request IDs, delayed completion and native rollback failures. Include exact A8 pre-launch/no-post-launch/post-launch/coordinated boundary fixtures and independent pre-M5 drift-denial/alert/no-repair evidence requirements. Expectations come from accepted authorities, never actual migration output.

The proposed physical inventory remains **two shadow tables and four internal invoker functions**, **one proposed 00025 migration**, no production entitlement/publication authority and **ZERO user-visible delta**. Only this contract was authorized for correction; no SQL/migration/test/Flutter/roadmap artifact is created or edited by this pass. M4 classification/conversion and M5 public cutover remain separately gated; OQ-84 and every other OPEN OQ remain unchanged. The next step is focused independent contract re-review, not implementation.

## 34. Architect Acceptance Record — 2026-10-04

Architect decision: **M3 CONTRACT IS ACCEPTED**. The Owner-provided focused independent re-review verdict is **A — M3 CONTRACT READY FOR ARCHITECT ACCEPTANCE**, with CRITICAL 0, HIGH 0, MEDIUM 0 and LOW 3. This record persists that decision; it does not issue a new independent review.

Current documentary status is **DOCUMENT_STATUS: ACCEPTED — CANONICAL M3 IMPLEMENTATION CONTRACT**, **ARCHITECT_ACCEPTANCE: ACCEPTED — 2026-10-04**, and **IMPLEMENTATION_AUTHORIZED: NO**. Acceptance freezes the existing M3 slice definition as architecture/implementation-contract authority for future separately authorized execution. This record supersedes documentary draft/pending/not-frozen status and re-review-next-step statements retained in the introduction and §§1–33 as drafting history; their technical semantics are unchanged.

### 34.1 Non-blocking LOW carry-forward observations

| Finding | Implementation-hygiene observation only |
| --- | --- |
| LOW-1 | Some duplicate semantic classes resolve deterministically through existing closed reason tokens but could use explicit mapping. |
| LOW-2 | Six per-gate *_NOT_PROVEN reason tokens are currently redundant with explicit gate-status dimensions unless future implementation maps them explicitly. |
| LOW-3 | STALE_SHADOW_GENERATION, REQUEST_ID_CONFLICT and INTERNAL_EVALUATION_ERROR are surplus as kernel reason tokens because the corresponding conditions are handled through capture errors / mismatch classification. |

All three are **NON-BLOCKING** carry-forward implementation-hygiene observations. They do not alter accepted behavior, reopen architecture or authorize vocabulary redesign. If needed, they may be resolved mechanically during separately authorized contract execution within the accepted semantics and closed vocabulary; no new policy is permitted. No normative vocabulary or reason semantics is changed by this acceptance record.

### 34.2 Pre-implementation STOP and preserved boundaries

**M3 implementation remains BLOCKED until a separately authorized and Owner-committed commercial-track roadmap/control authorization record exists under §31. IMPLEMENTATION_AUTHORIZED remains NO.** The current formal UI roadmap state is unchanged; no roadmap/control record is created by this pass.

Acceptance authorizes none of: 00025 execution, SQL/migration, pgTAP/test changes, Flutter/Directory changes, entitlement activation, grants, payment, M4, M5, roadmap implementation, staging, commit or push. The two-table/four-function design, 00025 proposal, evaluator/result schemas, reason semantics, JSONB boundary, A8, Grace/time, synthetic safety, predecessor compatibility, M4/M5 boundary, OQ-84 and ZERO public behavior delta remain unchanged. Only documentary status/acceptance metadata and this record are finalized.

## 35. Architect Clarification / Binding Interpretation — Policy Dependency Reporting — 2026-10-04

Authority: Owner-provided Architect decision. This is a narrow clarification of §33.7 / §33.8, with no reopening of the accepted architecture.

SEMANTIC_SCOPE: clarifies dependency-reporting carrier only; no output/schema/authority change.

### 35.1 Existing input carrier and typed output

The complete dependency-reporting context is **validated publication input + typed publication output**. The exact policy/OQ identifier remains in the supplied, validated input; it is not duplicated into an output column, encoded into POLICY_DEPENDENCY_BLOCKED, or replaced by a dynamic reason string.

The Architect instruction's notation **p_publication_input.policy_dependency** refers to the policy_dependency member of the affected **existing Gate** within the publication input, under §33.4 / §33.7. It does not add a root field or JSON alias to the closed 28-field publication envelope. The existing Gate paths are required_fields, onboarding, moderation, verification, launch, projection.approval and projection.conformance; each carries its own policy_dependency. An identifier from another gate cannot substitute for the dependency of the evaluated blocked path.

**BLOCKED_POLICY** remains the existing Gate.status / affected gate_results dimension's gate-status token. A policy-blocked publication result reports that status with **POLICY_DEPENDENCY_BLOCKED** in reason_codes. It does not add BLOCKED_POLICY to authority_outcome or discoverability_outcome. The authority, readiness, discoverability, stronger-denial precedence and flags continue to follow §33.8; the publication return remains exactly 29 columns.

“Report the exact OQ identifier” means that the evaluated/reportable result context retains the exact validated policy_dependency supplied for that blocked path, while the typed output carries the existing status and generic reason. The identifier remains included in the normalized publication input and its publication_input_revision binding under §33.3. It is never inferred, synthesized or defaulted by the evaluator.

### 35.2 Cross-field invariant, converse and validation

For every existing publication-input Gate, **status = BLOCKED_POLICY requires a present, non-null policy_dependency from the existing finite vocabulary**: OQ-48, OQ-49, OQ-72, OQ-76, OQ-77, OQ-79, OQ-80, OQ-81, OQ-82, OQ-83 or OQ-84. Conversely, policy_dependency is NULL for a non-blocked Gate, as §33.4 already requires. All other Gate null/evidence/binding rules remain unchanged.

If the publication evaluator reports BLOCKED_POLICY plus POLICY_DEPENDENCY_BLOCKED, the exact accepted dependency for the affected path MUST be supplied in that validated input. It cannot emit POLICY_DEPENDENCY_BLOCKED without a valid exact input-carried policy_dependency consistent with the requested blocked path, including when a blocked reason is composed with the bound entitlement result. Multiple blocked paths retain their own identifiers in the input; the existing reason set remains deduplicated and sorted.

Missing, null, malformed, unsupported or inconsistent dependency input **fails closed under the existing §33.1 / §33.11 validation semantics and precedence**: an omitted required Gate member uses MISSING_REQUIRED_FIELD; a wrong scalar or forbidden null uses INVALID_FIELD_TYPE; an identifier outside the finite vocabulary uses INVALID_ENUM; a well-typed binding inconsistency uses BINDING_MISMATCH. No fallback OQ, new reason token, new SQLSTATE or affirmative result is created.

policy_dependency grants **NO authority** and answers **NO OQ**. OQ-84 remains unresolved: M3 must never choose among its continuation, re-gating, Coming Soon or other policy alternatives.

### 35.3 Preserved interfaces, status and execution boundary

Publication input remains **28 fields** and publication output **29 columns**. The entitlement and capture interfaces, RunSummary, two-table design, four-function design, 00025 proposal, reason vocabulary and SQLSTATE model remain unchanged. There is no new schema/object, public behavior or canonical policy authority.

M3 remains shadow-only. This clarification adds no policy authority table, shadow/output/publication column, OQ resolution record or persistence solely to echo policy_dependency. The input and its existing revision binding retain the evaluated dependency context; any future long-term dependency persistence beyond the accepted M3 evidence model requires separate authorization.

DOCUMENT_STATUS remains **ACCEPTED — CANONICAL M3 IMPLEMENTATION CONTRACT**; ARCHITECT_ACCEPTANCE remains **ACCEPTED — 2026-10-04**; FREEZE_STATE remains **FROZEN — ACCEPTED M3 SLICE DEFINITION ONLY**. The acceptance-time IMPLEMENTATION_AUTHORIZED metadata, separately committed commercial control, §29 implementation scope and UI roadmap locks are unchanged.

This pass is **NARROW CONTRACT CLARIFICATION ONLY**: no implementation, SQL, migration, test edit, roadmap edit, staging, commit or push. It executes none of the separately controlled M3 implementation authority.
