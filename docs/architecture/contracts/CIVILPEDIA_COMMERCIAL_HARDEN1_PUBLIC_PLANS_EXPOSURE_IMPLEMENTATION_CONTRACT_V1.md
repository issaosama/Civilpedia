# Civilpedia — HARDEN-1 Public Plans Raw Exposure Hardening Implementation Contract V1

CONTRACT_ID: HARDEN-1
CONTRACT_VERSION: V1
DOCUMENT_STATUS: ACCEPTED — CANONICAL PUBLIC.PLANS EXPOSURE HARDENING IMPLEMENTATION CONTRACT
SLICE: HARDEN-1 — PUBLIC.PLANS RAW EXPOSURE HARDENING
MODE: IMPLEMENTATION-CONTRACT DESIGN ONLY
ARCHITECT_ACCEPTANCE: APPROVED
IMPLEMENTATION_AUTHORIZED: NO
PREPARED_DATE: 2026-10-03
REPOSITORY_BASELINE: main @ 58595971e28ef247579c6b87e4ac22444ace2812
LOCAL_ORIGIN_MAIN_BASELINE: 58595971e28ef247579c6b87e4ac22444ace2812
POLICY_AUTHORITY: FROZEN Commercial Model V1, §33
TECHNICAL_ARCHITECTURE_AUTHORITY: ACCEPTED C3, §§46–47
SEQUENCING_AUTHORITY: ACCEPTED M1b, §§2–4, 27, 30
ACCEPTANCE_AUTHORITY: ChatGPT Architect
GIT_OWNER: User
ROWS_AUTHORIZED: 0

## 1. Authority, purpose and authorization boundary

Authority chain: [Frozen Commercial Model](../CIVILPEDIA_COMMERCIAL_MODEL_V1.md), particularly §§14.3–14.4, L-37, §25.4 item 5 and the §33 freeze; [accepted C1](CIVILPEDIA_COMMERCIAL_CORE_AUTHORITY_RECONCILIATION_CONTRACT_V1.md), §§11, 20–21 and acceptance §25; [accepted C2](CIVILPEDIA_COMMERCIAL_PUBLICATION_ENTITLEMENT_CONTRACT_V1.md), §§25, 28 and acceptance §31; [accepted C3](CIVILPEDIA_COMMERCIAL_SUBSCRIPTION_ENTITLEMENT_ENFORCEMENT_CONTRACT_V1.md), §§3–4, 19, 27–29, 41 and acceptance §§46–47; [accepted M1a contract](CIVILPEDIA_COMMERCIAL_M1A_PRIVATE_CATALOG_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md), §§5, 7–8, 14–19, 24 and implemented [migration 00022](../../../supabase/migrations/00022_commercial_private_catalog_foundation.sql); [accepted M1b](CIVILPEDIA_COMMERCIAL_M1B_CATALOG_REFERENCE_DATA_IMPLEMENTATION_CONTRACT_V1.md), DR-2, D3-A, HARDEN-1 dependency and current acceptance §30.

This contract proposes the smallest security change needed before any separately authorized canonical `public.plans` identity seed: remove ordinary-client raw access, retain the same identity table and server-side references, and create no replacement endpoint. It does not implement commercial entitlement or publication enforcement. M1b remains accepted as **design and sequencing authority only**: SCOPE-A 17 rows deferred; SCOPE-B 23 rows deferred; 40 rows designed; **0 rows authorized**. D3-B remains rejected.

The latest relevant persisted commercial decision/review record is M1b §30: initial independent result B, documentary corrections NC-1…NC-7 applied, optional NC-8/NC-9 applied, Architect acceptance APPROVED, HARDEN-1 implementation and M1b seed unauthorized. The supplied current request states that M1a implementation is accepted; 00022 and its two tests are present in the verified committed baseline. Historical M1a draft/acceptance wording is preserved in its own contract. This draft neither rewrites history nor declares a new independent review PASS.

The [Master Roadmap](../CIVILPEDIA_V1_MASTER_ROADMAP.md) remains the phase/status SSOT; R10.5-D is CURRENT for its pre-implementation audit only. The explicitly requested HARDEN-1 contract design does not advance the roadmap or authorize implementation. The [Agent Operating Model](../CIVILPEDIA_AGENT_OPERATING_MODEL.md) retains routing and Git authority.

**Present scope: create this Markdown file only.** No migration, SQL test, Dart test, database grant/policy/data change, production/cloud action, configuration change or Git mutation is authorized. Contract acceptance, implementation authorization and future seed authorization are separate decisions.

## 2. Verified repository and local evidence baseline

Fresh read-only inspection was performed at **HEAD == local origin/main == `58595971e28ef247579c6b87e4ac22444ace2812`** on `main`. Local origin/main is a remote-tracking reference; no fetch or production/deployed-state audit was performed. Migration inventory contains exactly 22 uniquely numbered files, 00001–00022 without gaps. **00023 is the actual next free prefix at this baseline.**

All six commercial authorities in §1, [00010](../../../supabase/migrations/00010_rls_authorization_baseline.sql) and 00022 were read in full; 00008, production call sites, relevant tests and configuration were re-inspected. Source findings were checked against the already-running disposable local database through read-only catalog/data queries and local HTTP requests. No stack restart/reset, fixture insertion, Auth user creation, migration application or test execution occurred in this drafting pass.

| Evidence boundary | Observed state; limit |
| --- | --- |
| Local execution context | PostgreSQL 17.6, database postgres, session_user/current_user postgres, role setting none, migration history latest 00022. The query login is evidence of this inspection context, not independent proof of a future migration runner's effective role. |
| Installed tool | Supabase CLI 2.116.0, rechecked read-only. No tool update or installation. |
| Local API configuration | [config.toml](../../../supabase/config.toml): exposed schemas public and graphql_public; extra search path public and extensions; API port 54321; database port 54322; PostgreSQL major 17. commercial_private remains excluded. |
| Current anon Data API | Local public.plans direct read returned HTTP 200 and an empty array. This proves current endpoint accessibility, not future denial or production emptiness. |
| Current Auth health | Local Auth health returned HTTP 200. No genuine authenticated plans request was made in this pass. |
| Current GraphQL | Local endpoint returned HTTP 200 with “pg_graphql extension is not enabled.” pg_graphql is absent from the extension inventory; GraphQL row-access evidence is unavailable in this environment. |
| Existing local stack | Inspected as running; Vector is absent under the prior local operational exception. No Docker security, database extension or repository configuration change was made. Required runtime services must be reverified at a future gate. |

| Current local relation | Row count |
| --- | --- |
| public.plans | 0 |
| public.subscriptions | 0 |
| commercial_private.plan_versions | 0 |
| commercial_private.entitlement_bundles | 0 |
| commercial_private.bundle_items | 0 |
| commercial_private.term_prices | 0 |

These are drafting-time local counts only. A future authorized gate must re-inventory data and preserve any legitimate legacy rows exactly; it must not assume every deployment is empty.

## 3. Exact existing public.plans structure

[00008_plans_and_subscriptions.sql](../../../supabase/migrations/00008_plans_and_subscriptions.sql) and the live catalog agree:

| Column | Type | Nullable | Default |
| --- | --- | --- | --- |
| id | uuid | NO | gen_random_uuid() |
| code | text | NO | none |
| name | text | NO | none |
| description | text | YES | none |
| is_active | boolean | NO | true |
| created_at | timestamp with time zone | NO | now() |
| updated_at | timestamp with time zone | NO | now() |

Relation kind: ordinary table. Owner: postgres. Constraints: `plans_pkey` PRIMARY KEY (id), `plans_code_key` UNIQUE (code), with their existing backing indexes. Trigger: `trigger_set_updated_at`, BEFORE UPDATE for each row, invoking the existing `public.set_updated_at()`. No INSERT trigger or plan seed is defined by 00008.

HARDEN-1 preserves every column/default, ID, code, label, active flag, constraint, index, comment and trigger. It does not reinterpret is_active as entitlement/publication authority or replace public plan identity with private duplicates.

## 4. Exact existing grants, RLS and privilege paths

00010 enables RLS and explicitly grants SELECT to anon and authenticated. The live table ACL is:

| Grantee | Current table privileges | Grantor / grant option |
| --- | --- | --- |
| postgres | SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN | postgres; no grant options |
| service_role | SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN | postgres; no grant options |
| anon | SELECT only | postgres; no grant option |
| authenticated | SELECT only | postgres; no grant option |
| PUBLIC (grantee OID 0) | none | no ACL entry |

Exact observed ACL entries: `postgres=arwdDxtm/postgres`, `service_role=arwdDxtm/postgres`, `anon=r/postgres`, `authenticated=r/postgres`. PostgreSQL 17's MAINTAIN privilege is included in the owner/server preservation boundary. All seven column ACLs are NULL; no separate column grant exists. Effective ordinary-client column SELECT is currently true because of table SELECT.

| RLS property | Current exact state |
| --- | --- |
| RLS enabled / forced | true / false |
| Policy count | 1 |
| Name | plans_select_all |
| Command / permissiveness | SELECT / PERMISSIVE |
| Roles | anon, authenticated |
| USING / WITH CHECK | true / absent |

**Trace precision:** 00010 and the live catalog identify policy roles **anon, authenticated**, not PUBLIC. M1b §§4.2 H-2 and 5.3 describe this as TO PUBLIC; that historical wording is not the literal source/catalog role list. This draft uses the reverified exact list without editing M1b. Its conclusion remains unchanged: all rows, including inactive plans, are visible to both ordinary API roles.

Fresh role inspection found no MEMBER/SET path from anon/authenticated to postgres, service_role or supabase_admin; both ordinary roles lack superuser/BYPASSRLS. The authenticator role can SET the normal JWT roles, including service_role, with INHERIT false; preserve that established API routing configuration. Trusted service credentials and owner access are separate from an ordinary authenticated user's app/business/staff labels. Neither a Business OWNER nor a general staff label justifies raw plan access.

PostgreSQL privileges accumulate through direct grants, PUBLIC and role membership; therefore effective table/column and role-path checks are mandatory, beyond matching an ACL string. See primary [PostgreSQL 17 REVOKE guidance](https://www.postgresql.org/docs/17/sql-revoke.html).

## 5. Fresh consumer and dependency inventory

Source search covered migrations, SQL routines/views, lib, tests and other production repository paths, with generated dependency prose excluded from runtime-consumer classification. Live dependency catalogs and non-system routine bodies were also inspected. No current production consumer of raw plans was found; a repository scan cannot assert absence of unknown external clients, so future deployment inventory remains a precondition.

| Consumer / dependency | Reconfirmed finding; handling |
| --- | --- |
| Production Dart/Flutter | ZERO public.plans table consumers; no production subscription consumer requiring its raw rows. Existing PlanType/PlanTier and local profile scaffolding are unrelated legacy access concepts under C3 §28 and remain untouched. |
| Production RPC/function/view | No source consumer reading/joining plans; live routine-body search found none and no dependent view/materialized view was found. The shared update trigger is not a read API. No replacement consumer is required. |
| Public subscriptions | Existing plan_id FK; preserve in §9. |
| Private plan_versions | M1a plan_id FK; preserve in §9. |
| Other inbound FKs | None beyond the two inventoried constraints. No plans Realtime publication membership was found. |
| Existing M1a SQL test | [commercial_m1a_private_catalog_foundation_test.sql](../../../supabase/tests/commercial_m1a_private_catalog_foundation_test.sql), baseline lines 703–709, asserts an unfiltered count of four rolled-back plan fixtures for each of anon/authenticated. This is a test dependency on the old exposure and needs the precise future adjustment in §16. |
| Existing M1a Dart test | [commercial_m1a_private_catalog_migration_test.dart](../../../test/commercial_m1a_private_catalog_migration_test.dart), line 95, checks the original public plan FK source anchor; it does not require client plans visibility. Keep unchanged and run as a regression. |
| R09Q / Directory tests | [SQL security smoke](../../../supabase/tests/v1_r09q_security_smoke.sql), [migration lint](../../../test/v1_r09q_migration_lint_test.dart), [security matrix](../../../test/v1_r09q_security_matrix_test.dart) and [Directory integration](../../../test/v1_r05_directory_cloud_integration_test.dart) require no source edit. Historical 00010 source assertions remain historical baseline checks. |
| PostgREST / GraphQL | Current raw Data API accessibility is observed in §2. GraphQL is disabled locally; exposure must still be tested if available at the future target gate (§13). |

**Production-consumer stop rule:** if pre-implementation re-inspection discovers a Flutter/runtime consumer or external integration requiring raw plans, STOP and report the dependency. Do not silently break it, add a speculative adapter or broaden this contract. The existing test dependency is explicitly addressed by the fourth future allowlist file, without a production Flutter change.

## 6. Frozen privacy invariant

The following Frozen §14.3 / L-37 requirements remain exact and binding:

| Commercial data | Public exposure |
| --- | --- |
| Subscription plan name | NEVER PUBLIC |
| Subscription price | NEVER PUBLIC |
| Subscription expiry | NEVER PUBLIC |
| Commercial entitlement metadata | NEVER PUBLIC |
| Payment details | NEVER PUBLIC |

Internal owner/admin data, receipts/payment identifiers, internal verification/fraud notes, analytics and sensitive identity evidence remain protected by their existing frozen rules as well. No policy amendment, code-only plan-name surrogate, duplicate private identity or equivalent raw endpoint may work around DR-2. HARDEN-1 creates no new publication or catalog DTO interpretation and closes/reclassifies no OQ, C1 AR, C2-AR or C3-AD entry. OQ-84 and every other OPEN OQ remain unresolved as currently defined.

## 7. Architecture evaluation and one recommendation

| Option | Assessment | Disposition in this draft |
| --- | --- | --- |
| A — revoke ordinary raw SELECT and remove plans_select_all, no replacement | Removes the demonstrated unused raw surface while preserving identity, FK, server and Flutter boundaries. A gate verifies every effective access path. | **RECOMMENDED** |
| B — revoke raw access and add a bounded projection/RPC | Could serve a separately justified, privacy-safe future interface; no legitimate present runtime consumer was found. Adds API/output/authorization work without a present requirement. | Deferred to a separate later contract and authorization. |
| C — move/duplicate plans, redact labels, or rely only on a policy/active filter | Identity replacement risks existing FKs; label/code substitution does not satisfy DR-2; row filtering alone retains a raw capability and risks later policy reopening. No objectively safer smaller design was demonstrated. | Rejected for this slice. |

**Choose A: revoke-only, with zero production Flutter changes.** Revocation plus removal of the permissive policy is sufficient for the current inspected consumer graph when combined with fail-closed preconditions and SQL/API evidence. Keeping RLS enabled with no replacement policy adds default-deny defense for ordinary roles. It does not grant or remove trusted database-owner/server capability. This is the same retained-identity architecture as C3; it is not C3's unrelated “option B” catalog-family selection.

No view, RPC, persistent function, catalog endpoint, Flutter DTO, Remote Config, new client or runtime catalog consumer is part of HARDEN-1. No alternate endpoint may expose equivalent plan-name, price, entitlement, expiry or payment data.

## 8. Exact intended future privilege/policy delta

Only the following security changes are proposed; **no executable migration SQL is written in this draft**:

1. Revoke table SELECT on public.plans from anon and authenticated; explicitly target PUBLIC SELECT as defense in depth while requiring its baseline ACL to be empty.
2. Remove the single exact plans_select_all policy. Create no replacement policy.
3. Retain RLS enabled, forced-RLS false, owner/server ACLs, all columns and every other object's accepted security posture.

| Principal / property | Before | Required after |
| --- | --- | --- |
| anon | SELECT table access; effective SELECT on all columns | No table privilege and no effective column SELECT; direct raw SELECT denied. |
| authenticated | SELECT table access; effective SELECT on all columns | No table privilege and no effective column SELECT; direct raw SELECT denied for ordinary/business/general-staff sessions. |
| PUBLIC OID 0 | No table or column ACL entry | No table or column privilege; no indirect ordinary access. |
| postgres | All eight table privileges in §4; owner | Identical ACL and ownership, including REFERENCES and MAINTAIN. |
| service_role | All eight table privileges in §4; BYPASSRLS | Identical trusted server ACL; no new client service credential or private-schema grant. |
| Seven column ACLs | NULL | NULL; no residual or newly introduced column grants. |
| RLS enabled / forced | true / false | true / false. |
| Policies | Exact sole policy in §4 | Zero policies; plans_select_all absent. |
| Roles, memberships, defaults | Existing verified state | Identical; no role, membership or default-ACL modification. |

Use restrictive, precisely targeted revocation/removal; no blanket public-schema revoke, CASCADE, silent IF EXISTS adoption or unrelated security alteration. Any unexpected inherited privilege, column grant, grant option, extra policy or new consumer fails preflight. PostgreSQL's corresponding column-revocation behavior does not replace independent before/after effective-column checks.

Existing table/schema/RPC ACLs outside the declared plans SELECT delta, private-schema/default hardening, triggers/functions, exposed schemas, API configuration, publication membership and Auth routing remain identical.

## 9. Legacy and private FK safety

| Exact inbound constraint | Existing definition | Required preservation / evidence |
| --- | --- | --- |
| public.subscriptions.subscriptions_plan_id_fkey | plan_id → public.plans(id), ON UPDATE NO ACTION (default), ON DELETE RESTRICT; validated | Same constraint/target/actions/validation. Existing rows, plan IDs, references and all subscription semantics remain identical. |
| commercial_private.plan_versions.fk_plan_versions_plan_id | plan_id → public.plans(id), ON UPDATE RESTRICT, ON DELETE RESTRICT; validated | Same restrictive constraint. Owner-side reference creation/checking remains usable; private ordinary-client and service_role denial remains intact. |

Preserve the plan PK/unique key, subscription entity FK, legacy status vocabulary, date checks and numeric(12,2) price_paid. No ID change, row deletion/rename, reference rewrite, active-state update, conversion, grandfathering or subscription entitlement mapping. MED-3 remains M4; MED-4 remains future profile/commercial integration; publication-generation reconciliation remains before M5.

Owner/server table REFERENCES capability is retained. Foreign-key integrity is enforced by database checks rather than ordinary-client SELECT policy; PostgreSQL documents that referential-integrity checks bypass row security. This does not authorize returning referenced data through an API. See primary [PostgreSQL 17 row-security guidance](https://www.postgresql.org/docs/17/ddl-rowsecurity.html).

Future rolled-back fixtures must prove valid owner-side public subscription and private plan-version references, orphan rejection and restrictive parent deletion behavior. Private insert/reference probes execute as the verified owner, not by granting service_role access to commercial_private.

## 10. Zero seed and future private-management interfaces

HARDEN-1 authorizes **ZERO production/catalog rows**. It creates no business, business_pro, business_plus or corporate canonical identity, no M1b row and no plan, bundle, item, version or price seed. It activates no offer, entitlement, agreement, payment, promotion, publication or Business.

Future Business Center subscription information must use a separately contracted **bounded authenticated DTO/RPC**, derived from server-verified Business and finance capability. Generic authenticated public.plans SELECT is not that interface. Business ownership alone does not create a raw-table exception here.

Trusted database/service/admin capability remains separate from public API exposure. General staff receive no automatic commercial read grant. The exact commercial admin API, staff capability mapping, catalog presentation and any future safe public projection are outside this contract and require separate accepted scope and explicit implementation authorization.

## 11. Future migration identity, structure and atomicity

Proposed name at the verified unused prefix:

`supabase/migrations/00023_commercial_public_plans_exposure_hardening.sql`

This name is **proposed, unreserved and unauthorized**. Reverify inventory before future authoring; if 00023 is consumed, STOP, report the actual next free prefix and obtain Architect reauthorization. Never overwrite or silently renumber a frozen path.

The migration is security hardening of the existing relation only: precondition/postcondition assertions, the exact SELECT revocations and named policy removal in §8, plus explanatory comments. A migration-local assertion block is permitted; it creates no persistent function or API. No other table/column/constraint/index/schema/trigger/view/routine/extension/role/default-ACL change, data DML, seed, public configuration change or FORCE RLS operation.

Required order: verify execution context and every §12 database precondition before the first mutation; obtain appropriate relation locking so the checked plans state cannot be concurrently changed during the hardening transaction; apply only §8; assert exact denial, retained owner/server/reference capability and unchanged structures/data/security elsewhere before runner commit. Operations must be qualified to the exact public.plans relation. A postcondition failure is an error, never a warning or partial-success acceptance.

Use the real Supabase migration runner's verified **per-file wrapping transaction**. No authored BEGIN, COMMIT, ROLLBACK, START TRANSACTION, SAVEPOINT or transaction=false directive in the migration; block-language BEGIN/END is not authored transaction control. No alternate partial-success execution mode. Assertion/lock/revocation/policy-removal/postcondition failure must roll back the complete file and leave its migration history unapplied.

Accepted prior runner-atomicity evidence may be reused only after verifying the same CLI/execution path, effective creator, server and runner context. Otherwise require a controlled disposable-local late-failure rehearsal: use the exact migration statements with a forced failure appended **inside the same migration file**, in an isolated temporary verification project outside repository source. Snapshot grants/policy/history before and after and prove all changes roll back. A failure in a later separate migration does not prove this file's atomicity. Such temporary inputs are future verification fixtures, not a fourth migration or extra repository artifact. No rehearsal is performed or file created now.

## 12. Fail-closed implementation and deployment preconditions

Implementation remains blocked pending independent contract review, Architect acceptance and **separate explicit implementation authorization**. After authorization, source/deployment inventory and migration assertions form complementary gates: a database catalog cannot discover every Dart or external consumer.

| Precondition | Required evidence / STOP trigger |
| --- | --- |
| Baseline and migration inventory | Actual execution baseline recorded; unchanged accepted history through 00022; sole intended pending HARDEN-1 migration; proposed prefix unused. Unknown source drift or collision requires review/reauthorization. |
| Production consumers | Repeat §5 source/call-site and relevant deployment/external-consumer inventory. Any new legitimate raw plans runtime consumer requires STOP and an explicit compatibility decision before migration. |
| Relation shape | Exact §3 seven columns/types/defaults/nullability, owner, relation kind, constraints, indexes and trigger; no unexpected schema/object dependency. Material drift fails before revocation. |
| Policy baseline | Exactly §4's one SELECT/PERMISSIVE/anon+authenticated/true policy, with no WITH CHECK, RLS enabled and not forced. Missing/mismatched policy or extra policy fails; do not silently adopt an already-hardened or divergent database. |
| Grants and authority paths | Exact §4 owner/server/anon/authenticated ACLs and grantors; PUBLIC empty; column ACLs NULL; no grant options, unknown accessible grantees, client owner/server membership or effective inherited bypass. Material drift fails before revocation. |
| FK inventory | Both §9 FKs validated with unchanged target/actions; no unreviewed extra inbound constraint or consumer. Retain required owner-side capability. |
| Private security and defaults | M1a schema/table/default ACLs, owner and no-policy/non-exposed state captured and unchanged; no private client/service grant or PUBLIC default leak. |
| Data and seed boundary | Before/after fingerprints/counts for plans, subscriptions, Directory and private catalog; no unauthorized canonical M1b seed. Nonempty legitimate legacy data requires inventory/preservation, not deletion or forced emptiness. |
| Execution / environment | Verified same real runner and trusted creator context, PostgreSQL 17, healthy required local PostgreSQL/PostgREST/Auth/Kong services, reachable database/API and runtime gate available. Owner/service privilege variation requires explicit review rather than assumption. |
| Atomicity and rollout | Verified wrapping transaction, bounded lock behavior and all-or-nothing assertions; dependent rollout halted on any failure. No automatic mutation retry or unreviewed privilege restoration. |

Authorization does not waive these gates. Unsupported/missing runtime infrastructure means **incomplete gate / STOP**, never static-only PASS. This contract authorizes no production/cloud deployment; any such later action requires its own approved execution boundary and fresh deployed-state inventory.

## 13. Data API and GraphQL evidence boundary

Future ordinary clients must not retrieve any raw plans row/field/count through direct or nested PostgREST requests, regardless of is_active or Business/staff labels. Test both anon and a **genuine ordinary authenticated session**; a service credential, owner login or synthetic SQL role switch is not the HTTP authenticated gate. Tokens/keys remain out of repository files and reports.

Before interpreting relationship-level HTTP results, the future authorized implementation verification must explicitly refresh/reload the **local PostgREST schema cache** using a supported mechanism verified for the installed environment, or restart the relevant local PostgREST/API service if that is the verified supported mechanism. Verify Data API health after the reload/restart, then run the direct and nested plans-denial probes with positive unrelated API controls. No unverified production operation is prescribed or authorized. A stale-cache 4xx/5xx result must not be treated as proof of secure access denial or data exposure; security proof requires fresh-cache behavior together with PostgreSQL ACL/RLS evidence and positive unrelated API controls. This is operational test hygiene only and changes no hardening architecture.

Probe direct all-column and bounded id/code/name selects, count/HEAD access, plans-root relationship reads, subscription-to-plans embedding and applicable Directory-to-subscription-to-plans paths. Verify no restricted raw payload or surrogate appears. A request rejected only because its parent subscription table is inaccessible is insufficient proof of plans denial; combine it with direct SQL/ACL and direct API probes. Preserve legitimate unrelated Directory responses and accepted child filtering.

Direct denial requires a real permission/unavailable-resource result consistent with the installed API version, ordinarily 401/403 with permission error or a verified schema-cache omission/404. **HTTP 200 with an empty array, NULL embedded rows, disabled introspection or zero rows is not sufficient direct-denial evidence.** Relationship omission/error must be traced to the denied relation, with positive Directory controls.

If pg_graphql is available, test known plans fields/collection and applicable relationship queries with both roles, plus introspection only where already enabled. No raw plan fields/data may be accessible. Disabled introspection alone does not prove query denial. Supabase documents GraphQL's PostgreSQL privilege/RLS controls and permission-based schema visibility in its primary [GraphQL security guidance](https://supabase.com/docs/guides/graphql/security).

If pg_graphql remains disabled as observed in §2, record **environmental limitation / GraphQL runtime probe unavailable**; do not claim a GraphQL PASS or fail solely for that disabled optional surface. Still inspect extension/API exposure and prove PostgreSQL/Data API denial. Before any target with GraphQL enabled is accepted, run its actual GraphQL gate. Do not enable an extension, introspection, exposed schema or alter config.toml to make this slice's tests run.

## 14. Expected public delta and rollback boundary

**Expected intentional security delta:** before HARDEN-1, ordinary anon/authenticated clients can read raw public.plans; after a successful separately authorized implementation, they cannot. This is not M1a's zero-delta claim and not M1b seed authorization. An inaccessible raw catalog is the deliberate result.

All other accepted behavior must remain unchanged: Auth, Directory list/detail/children, entity publication/lifecycle, subscriptions, Business/profile/application RPCs, Saved/routes/cache and Flutter production source. No equivalent plan-name endpoint, price/expiry/payment/entitlement leakage, weaker private security or implicit paid-publication cutover is allowed.

On migration failure, runner atomicity preserves the complete pre-file state and leaves HARDEN-1 unlanded; halt dependent rollout. After successful hardening, operational rollback prefers halting M1b/consumer rollout and investigating compatibility while retaining raw-access denial. It must **not** automatically restore unsafe SELECT or plans_select_all, delete data or undo private security. Any proposal to reopen raw access requires explicit security review and an Architect decision; no rollback script or feature flag grants that approval.

## 15. Future focused runtime and regression gate

All actions in this section are **future requirements**, not commands run or tests created in this drafting pass. Use an explicitly verified disposable local Supabase environment only after implementation authorization. No remote reset/push, no --ignore-health-check, no unauthenticated Docker TCP endpoint, no Docker/configuration/extension weakening. The earlier Vector exception is a local operational exception only; reuse it only within an applicable authorized local gate and record it.

| Gate | Required nontrivial evidence |
| --- | --- |
| Pre-00023 baseline | Reset the disposable local chain through 00022 using the installed CLI; capture creator/runner context, §12 catalogs/data/source hashes, successful current anon raw read, required service health and positive Directory/Auth controls. |
| Forward and clean chain | Forward-apply the sole pending HARDEN-1 migration through the real runner; verify its history and exact delta before reset. Then clean full-chain reset through the same hardening file must succeed with no canonical seed and the same security state. |
| Runtime ACL/RLS | pgTAP effective table/column privilege denial for anon/authenticated; PUBLIC OID 0 inspection; no inherited owner/server path; direct SELECT attempts raise SQLSTATE 42501; plans_select_all absent and RLS true/forced false; owner/service_role public-plans ACLs identical including MAINTAIN. |
| Business/staff distinction | Ordinary authenticated SQL/JWT cases for Business and general staff labels still deny raw plans. Do not create a new role/membership/finance capability. Real Auth HTTP evidence remains independently required. |
| FK / data integrity | Rolled-back synthetic, noncanonical fixtures demonstrate valid owner subscription and private-version references, invalid reference rejection and both restrictive FK behaviors. Original constraints/IDs/data fingerprints match; private access/default-security probes and the existing M1a gate remain green. |
| HTTP / relationships | Actual anon and ordinary Auth session probes in §13 deny direct/raw embedded access; unrelated public Directory list/detail/contact/category controls and Auth health match the baseline. No new interface returns private fields. |
| GraphQL | Conditional actual role/query gate in §13 when enabled; explicitly record the disabled local limitation otherwise. Never represent introspection absence as access proof. |
| Catalog / RPC regression | Before/after plans/subscriptions/Directory/private data match after fixture rollback; schemas, default ACLs, other table ACLs/policies, RPC definitions/EXECUTE grants, triggers/extensions/publications and roles unchanged outside §8. Only intended plans ACL/policy fingerprints differ. |
| Drift failures | On disposable pre-00023 fixtures, test missing/mismatched policy, missing expected grant, unexpected PUBLIC/column/inherited access and structural drift. The actual migration must raise before changing the baseline; history and security snapshots remain unchanged. No permissive skip or migration-local repair. |
| Transaction failure | Verify or revalidate the real runner context and same-file late-failure atomicity under §11. Expected failure must leave grants/policy and migration history unchanged; report it separately from positive migration success. |

Test data, assertion helpers and privilege-drift fixtures must be bounded to disposable tests and fully rolled back/reset. The new SQL test uses the established transactional pgTAP convention and SECURITY INVOKER temporary helpers; no persistent function or client EXECUTE grant is needed. Preserve existing M1a fixtures; add no production seed or M1b 40-row feasibility probe. Commercial production rows authorized remain zero.

The future focused sequence, using CLI 2.116.0 syntax and after the §12 safety preflight, is:

```text
supabase db reset --local --version 00022
supabase migration up --local
supabase db reset --local
supabase test db --local supabase/tests/commercial_harden1_public_plans_exposure_test.sql supabase/tests/commercial_m1a_private_catalog_foundation_test.sql supabase/tests/v1_r09q_security_smoke.sql
flutter test --no-pub test/commercial_harden1_public_plans_exposure_migration_test.dart
flutter test --no-pub test/commercial_m1a_private_catalog_migration_test.dart
flutter test --no-pub test/v1_r09q_migration_lint_test.dart
flutter test --no-pub test/v1_r09q_security_matrix_test.dart
flutter test --no-pub test/v1_r05_directory_cloud_integration_test.dart
```

Capture before/after evidence and perform operational HTTP/GraphQL and failure-path probes at the corresponding stages; the command list alone is not the gate. Recheck installed help/execution context before use if the CLI changes. Run focused Flutter tests sequentially. No broad repository suite, CI/gate modification, SDK/cache/global-source patch or protected-test edit. Report commands, exits, assertion counts, sanitized evidence and limitations accurately.

## 16. Existing M1a test correction — required fourth future file

HARDEN-1 deliberately supersedes the **current raw-plans visibility expectation** in the existing M1a SQL regression when running the complete chain after HARDEN-1. It does not retrospectively change M1a's accepted behavior at 00022.

Baseline lines 703–709 in the existing SQL test comprise the adjacent comment at 703–704 and the raw public.plans assertion at 705–709, which uses `pg_temp.m1a_read` to require four fixture plans for anon and authenticated. The different Directory assertion beginning at **line 710 is preserved and must not be modified**. That helper rethrows permission errors, so leaving it or merely changing its expected return would abort the suite after hardening. The minimal future correction is:

- Replace just that two-role positive-read assertion with the same plans query passed to the already-existing `pg_temp.m1a_result` denial helper, expecting **`42501|`** for each role.
- Retain both role cases and the assertion count. Update only the immediately adjacent comment/assertion label to explain the post-HARDEN-1 expectation.
- Preserve fixture IDs/data, all helpers, Directory/child filtering, subscriptions denial, constraints/FK, private/default ACL probes and every other assertion.

Do not delete, skip or weaken those tests. No existing SQL migration, M1a contract, Dart test, protected test, global test helper or CI file needs editing. This source-proven test dependency is the sole justified expansion beyond the expected three new implementation files. It is **not applied in this drafting pass** and requires inclusion in later explicit authorization. The unchanged historical M1a source/contract remains available to assess 00022 behavior independently.

## 17. Future focused Dart/static gate

The new focused Dart test must use independent expectations from this contract, rather than derive expected behavior from the migration it is testing:

1. Exact proposed migration path/prefix, unique increasing five-digit inventory, unchanged 00001–00022 history and only §18's allowed implementation files.
2. Exact SELECT revocation targets PUBLIC/anon/authenticated and exact plans_select_all removal intent; RLS preservation and before/after assertions; no GRANT back, replacement policy or generalized public-schema revoke.
3. No plans/subscription/catalog INSERT/UPDATE/DELETE/TRUNCATE, plan seed, canonical M1b UUID/data payload, table/column/FK rewrite or other data mutation.
4. No new persistent view/RPC/function/trigger, replacement public endpoint, DTO, production Flutter consumer, Remote Config, role/membership/default-ACL alteration, extension/configuration requirement or private-security relaxation.
5. No authored transaction-control statement or transaction=false directive. Distinguish quoted/block/comment text from top-level transaction statements, so an allowed assertion block is not falsely rejected.
6. Exact unchanged reference/structure preservation requirements and narrow M1a two-role test correction in §16; no assertion deletion, skip or relaxation of unrelated security tests.
7. Actual config.toml, seed, Flutter production and protected-file hashes unchanged under the execution baseline comparison.

This gate checks source/inventory intent only. It cannot prove live ACLs, owner/server FK capability, runner rollback, ordinary Auth identity or Data API/GraphQL denial; §15 remains mandatory.

## 18. Exact file boundaries

**Present drafting allowlist: one new Markdown contract only.**

`docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_HARDEN1_PUBLIC_PLANS_EXPOSURE_IMPLEMENTATION_CONTRACT_V1.md`

**Proposed future implementation allowlist: three new files and one narrowly edited existing SQL test. All require later explicit authorization.**

| Exact future path | Action / bounded purpose |
| --- | --- |
| supabase/migrations/00023_commercial_public_plans_exposure_hardening.sql | NEW: sole security-only migration in §§8, 11–12. |
| supabase/tests/commercial_harden1_public_plans_exposure_test.sql | NEW: focused transactional runtime/security, FK/data and denial assertions. |
| test/commercial_harden1_public_plans_exposure_migration_test.dart | NEW: independent focused source/inventory gate in §17. |
| supabase/tests/commercial_m1a_private_catalog_foundation_test.sql | EDIT: only the two raw-plans role assertions and their adjacent documentary label/comment in §16. |

No wildcard allowance or other repository artifact. Existing read/run-only regressions in §§5, 15 remain untouched. No production Flutter file. Additional file, API harness, role, function, seed, migration number/name, configuration or test-boundary change requires Architect reauthorization.

## 19. M1b interlock and migration-number consequence

HARDEN-1 must be separately **contracted → accepted → explicitly implementation-authorized → implemented → landed → independently verified** before canonical public.plans identity seed. Completion does **not** reopen SCOPE-A, SCOPE-B or D3-B. The Architect must still issue a **separate explicit authorization naming the M1b seed tier**, with its accepted cutover/fixture/test/data boundary and unresolved-policy prerequisites.

M1b §21's future 00023_commercial_catalog_reference_data.sql is explicitly **unreserved and unclaimed**. If HARDEN-1 uses and lands 00023, future M1b authoring must stop that old filename choice, inspect the then-next unused prefix and obtain Architect reauthorization. This draft does not edit/renumber M1b, reserve 00024, or authorize an automatic second migration.

Rows authorized by HARDEN-1: **0**. M1b remains **40 designed / 0 authorized** before and after successful HARDEN-1. No bundle-only workaround, duplicate private anchor, code-only public label, localization-sentinel publication or future contract family is self-authorized.

## 20. Review and future acceptance gate

This draft is recommended **READY FOR INDEPENDENT POSTGRESQL / SUPABASE SECURITY CONTRACT REVIEW**, subject to Architect acceptance. No independent HARDEN-1 review has yet been performed or accepted by the drafting agent.

Future implementation requires independent security-sensitive implementation review **before commit**, assessing exact four-file scope, fail-closed assertions, effective table/column/inherited denial, real anon/Auth/API evidence, conditional GraphQL result, retained owner/server/FKs/private defaults, complete atomicity/regression gate, explicit public-access delta and the closed seed interlock. HIGH/MEDIUM findings block acceptance under the Operating Model; no missing runtime evidence may be waived through a static PASS.

Architect acceptance of this contract alone is not permission to implement. No stage/commit/push becomes authorized by a review recommendation, runtime PASS or implementation acceptance; the user remains Git owner.

## 21. Drafting safety and evidence record

Protected pre-existing dirty baseline:

```text
 M test/a5_6_profile_bootstrap_test.dart
 M test/v1_r08_cloud_profile_foundation_test.dart
 M test/v1_r08_profile_edit_screen_widget_test.dart
?? OpenCode_Usage_Report.txt
?? artifacts/
```

Before drafting, SHA-256 fingerprints were captured for all 1,188 existing tracked/nonignored untracked files, including protected artifacts. Final delivery must compare those exact paths/hashes, confirm that only this contract is new, validate local links/table widths/fences/whitespace, and verify the index remains empty and HEAD/local origin/main remain the full §2 SHA. Migration inventory must still end at 00022; all three proposed new implementation artifacts must remain absent.

Current pass: commercial policy changes 0; C1/C2/C3/M1a/M1b/roadmap changes 0; OQs closed/reclassified 0; production rows authorized 0; implementation artifacts created 0. The only runtime inspection was read-only local catalog/data/API evidence; no DB mutation, test execution, implementation, stage, commit, push, reset/revert/stash/clean or production/cloud modification.

DOCUMENT_STATUS: ACCEPTED — CANONICAL PUBLIC.PLANS EXPOSURE HARDENING IMPLEMENTATION CONTRACT
ARCHITECT_ACCEPTANCE: APPROVED
IMPLEMENTATION_AUTHORIZED: NO

## 22. Final Architect acceptance record — 2026-10-03

- Independent review verdict: B
- Security defects: 0
- Technical architecture defects: 0
- Policy/sequencing defects: 0
- Required correction F-1: applied
- Required correction F-2: applied
- Independent provenance note F-3: informational only
- Selected architecture: REVOKE-ONLY
- Replacement public API authorized: NO
- Production Flutter changes authorized: NO
- Rows authorized: 0
- HARDEN-1 Architect Acceptance: APPROVED
- HARDEN-1 Implementation Authorized: NO
- Migration 00023 implementation authorized: NO
- M1b seed authorized: NO
- Commercial policy changes: 0
- OQs closed/reclassified: 0
- Authority: ChatGPT Architect

This record persists the supplied Architect decision after applying only the two required non-semantic documentary corrections. The independent verdict was **B — technically sound and secure; approve subject to two non-semantic corrections**. No security, architecture, policy, migration-design, scope, authority or sequencing correction was required. Current acceptance metadata and this record supersede earlier draft/review-pending statements, which remain preserved as historical context. F-3 is informational only and creates no additional action or review claim.

Acceptance is of the implementation contract only. **IMPLEMENTATION_AUTHORIZED remains NO; ROWS_AUTHORIZED remains 0.** The revoke-only design, exact four-file future allowlist and narrow M1a raw-plans assertion edit remain unchanged. Migration 00023 remains **PROPOSED / UNRESERVED**; no migration or test is created or modified by acceptance. No grants, RLS, plan data, Flutter, config.toml, M1b, 00022 or roadmap is changed. All OQs retain their existing meaning and status.

Successful HARDEN-1 contract acceptance does **not** authorize M1b seed. The required sequence remains: **HARDEN-1 contract accepted → explicit HARDEN-1 implementation authorization → HARDEN-1 implementation → independent implementation review → land/commit/push → verification → separate explicit Architect authorization reopening M1b seed**. The user remains Git owner; this sequence grants no staging, commit or push authorization now. Rows authorized now: **0**.
