# Civilpedia — M1a Private Commercial Catalog / Version Foundation Implementation Contract V1

CONTRACT_ID: M1a
CONTRACT_VERSION: V1
DOCUMENT_STATUS: ACCEPTED — CANONICAL M1a PRIVATE COMMERCIAL CATALOG FOUNDATION IMPLEMENTATION CONTRACT
FREEZE_STATE: ACCEPTED — IMPLEMENTATION CONTRACT ONLY
ARCHITECT_ACCEPTANCE: APPROVED
SLICE: M1a — PRIVATE COMMERCIAL CATALOG / VERSION FOUNDATION
MODE: IMPLEMENTATION-CONTRACT DRAFTING ONLY — NO PRODUCTION IMPLEMENTATION YET
IMPLEMENTATION_AUTHORIZED: NO
PREPARED_DATE: 2026-10-02
REPOSITORY_BASELINE: main @ 0a31fce46b3235b698009773240788e3cd5b5533
LOCAL_ORIGIN_MAIN_BASELINE: 0a31fce46b3235b698009773240788e3cd5b5533
TECHNICAL_ARCHITECTURE_AUTHORITY: ACCEPTED C3, including §§46–47
ACCEPTANCE_AUTHORITY: ChatGPT Architect
GIT_OWNER: User

## 1. Authority, purpose and present authorization

Authority chain: [Frozen Commercial Model V1](../CIVILPEDIA_COMMERCIAL_MODEL_V1.md), including its §33 freeze; [accepted C1](CIVILPEDIA_COMMERCIAL_CORE_AUTHORITY_RECONCILIATION_CONTRACT_V1.md), current acceptance §25; [accepted C2](CIVILPEDIA_COMMERCIAL_PUBLICATION_ENTITLEMENT_CONTRACT_V1.md), current acceptance §31; [accepted C3](CIVILPEDIA_COMMERCIAL_SUBSCRIPTION_ENTITLEMENT_ENFORCEMENT_CONTRACT_V1.md), current acceptance §§46–47. C3 is the canonical technical architecture authority. Its earlier draft labels are historical under §46; this document does not rewrite them.

This draft specifies the smallest additive private catalog/version foundation derived from C3 §§2–5, 9, 29, 32, 36, 41, 44 and 47, and C3-AD-01, C3-AD-02 and C3-AD-20. The structure can represent future approved offers without creating a commercial entitlement, publishing a Business, changing current Directory behavior or granting new application runtime authority. Externally observable application behavior after a future accepted M1a implementation must be **ZERO CHANGE**.

Only this new Markdown file is authorized in the present pass. The migration, SQL tests and Dart test described below are future artifacts and must not be created now. Drafting is not freeze, Architect acceptance or implementation authorization. Independent review, Architect acceptance and separate explicit M1a implementation authorization must all precede implementation.

The [Master Roadmap](../CIVILPEDIA_V1_MASTER_ROADMAP.md) remains the phase/status SSOT: R10.5-D is CURRENT for its pre-implementation audit only, with implementation authorization NO. This expressly requested commercial contract-drafting task does not advance that phase or unlock any implementation. The [Agent Operating Model](../CIVILPEDIA_AGENT_OPERATING_MODEL.md) and repository Git ownership remain unchanged.

## 2. Independently re-inspected repository baseline

Inspection was read-only at `0a31fce46b3235b698009773240788e3cd5b5533`. HEAD and local `origin/main` match. There are exactly 21 migration files, uniquely numbered 00001–00021 without gaps; 00022 is unused. The highest migration is `00021_staff_application_operations_foundation.sql`. This is repository evidence, not a deployed-schema or production-data audit; `origin/main` was not refreshed through a remote fetch.

| Re-inspected source | M1a-relevant finding |
| --- | --- |
| [00001](../../../supabase/migrations/00001_extensions_and_updated_at_function.sql) | Existing pgcrypto/UUID convention and reusable `public.set_updated_at()`; no new extension or copied timestamp function is needed. |
| [00002](../../../supabase/migrations/00002_regions.sql), [00003](../../../supabase/migrations/00003_profiles_and_staff_roles.sql), [00004](../../../supabase/migrations/00004_roles_permissions_and_staff.sql) | UUID/reference conventions, profiles and separate staff capability chain; no catalog owner/business/staff provisioning belongs in M1a. |
| [00005](../../../supabase/migrations/00005_directory_entities_and_categories.sql), [00006](../../../supabase/migrations/00006_entity_relationships.sql), [00007](../../../supabase/migrations/00007_business_applications.sql) | Entity, membership, category, location and application foundations; none is a commercial version or entitlement. Preserve all structures and data. |
| [00008](../../../supabase/migrations/00008_plans_and_subscriptions.sql) | `public.plans` supplies stable UUID/code identity; subscriptions remain legacy entity-linked records with `numeric(12,2)` amounts. |
| [00009](../../../supabase/migrations/00009_audit_logs.sql), [00010](../../../supabase/migrations/00010_rls_authorization_baseline.sql), [00011](../../../supabase/migrations/00011_business_application_write_hardening.sql) | Audit foundation, explicit client grants/RLS and later application-write revoke. Public plans SELECT is unfiltered; subscriptions have no ordinary client grants. New private catalog data must not inherit this public read surface. |
| [00012](../../../supabase/migrations/00012_region_reference_data_foundation.sql), [00013](../../../supabase/migrations/00013_region_preference_reference_data_correction.sql) | Geographic/reference-data migrations and additive preference separation; their seeds and profile FK remain untouched. |
| [00014](../../../supabase/migrations/00014_business_application_claim_hardening.sql), [00015](../../../supabase/migrations/00015_business_application_claim_concurrency_hardening.sql) | Claim uniqueness and entity locking; definer guard uses the existing `public, pg_temp` path, which must not be copied into new commercial authority. |
| [00016](../../../supabase/migrations/00016_business_application_server_mutations.sql), [00017](../../../supabase/migrations/00017_business_application_creation_authorization_hardening.sql) | Actor-bound definer RPCs, per-function EXECUTE revokes and explicit grants. 00017 documents default PUBLIC execute on a trigger function created after an earlier blanket revoke. There is no migration-owner default-privilege hardening in 00001–00021. |
| [00018](../../../supabase/migrations/00018_business_application_activation_ownership_provisioning.sql), [00019](../../../supabase/migrations/00019_business_ownership_management_foundation.sql) | Activation/OWNER provisioning and actor-bound management reads; no new commercial consumer or modification belongs in this slice. |
| [00020](../../../supabase/migrations/00020_business_profile_management.sql), [00021](../../../supabase/migrations/00021_staff_application_operations_foundation.sql) | Profile update locks the entity after non-null actor validation but before business authorization; staff operations remain application-specific. Both are protected future integration dependencies. |
| [config.toml](../../../supabase/config.toml), [seed.sql](../../../supabase/seed.sql) | Local PostgreSQL major 17; API schemas are `public` and `graphql_public`; extra search path is `public` and `extensions`. The configured seed exists and is intentionally empty. No private-schema API exposure or commercial seed is present. |
| [migration lint](../../../test/v1_r09q_migration_lint_test.dart), [security matrix](../../../test/v1_r09q_security_matrix_test.dart), [runtime security smoke](../../../supabase/tests/v1_r09q_security_smoke.sql) | Five-digit filenames, preserved accepted history through 00021, source-level security assertions, and transactional pgTAP fixtures with role/JWT switching and final ROLLBACK. Static tests do not prove runtime ACLs. |
| [quality gate](../../../tool/quality_gate.ps1), [CI workflow](../../../.github/workflows/flutter_quality.yml) | Selected Flutter suites run sequentially; the gate explicitly runs no Supabase tests. Existing automation does not supply fresh runtime M1a evidence and must not be edited by this slice. |

The latest relevant persisted commercial review/acceptance evidence is C3 §46: initial backend/security result B; three LOW documentary corrections applied and revalidated PASS; Architect acceptance APPROVED; implementation authorization NO. C3 §47 supplies the carry-forward requirements. [R07 correction evidence](../reports/V1-R07_STAFF_ADMIN_OPERATIONS_CORRECTION_REPORT.md) and the [R09Q contract](V1-R09Q_CROSS_CUTTING_QUALITY_GATE_CONTRACT.md) are historical infrastructure context, not an M1a PASS.

Installed Supabase CLI `2.116.0` supports explicit local reset, lint and selected pgTAP paths, verified through read-only help. Docker's local engine is unavailable at inspection. No stack was started, reset, queried or altered; no SQL/Flutter tests were run. Consequently actual database ownership, role memberships, default ACLs and live Data API configuration are **not runtime-verified in this draft**. §6 makes their verification a mandatory implementation preflight and gate; absence of that evidence cannot be called a security PASS.

## 3. Exact future migration boundary and order

Proposed future migration, verified unused at this baseline:

`supabase/migrations/00022_commercial_private_catalog_foundation.sql`

The present request selects this final filename; C3 §44's earlier proposed `00022_commercial_catalog_private_foundation.sql` was a recommendation only. There must be one 00022 migration, never both spellings. Recheck the inventory before implementation. If another change consumes 00022, stop the filename choice, report the actual next free number and obtain Architect reauthorization; do not renumber or overwrite accepted history silently.

The migration may create only `commercial_private` and the four tables in §4, their PK/FK/UNIQUE/CHECK constraints and indexes, defensive RLS with no policies, ownership assertions, object/default ACL hardening and explanatory comments. It must create no persistent function, trigger, view, sequence, enum, extension or new role. A migration-local `DO` assertion/dynamic role-quoting block is permitted and creates no persistent routine or runtime API.

Required order within the migration transaction:

1. Verify the creator/owner context and baseline; reject conflicting pre-existing schema/objects rather than silently adopting them through `IF NOT EXISTS`.
2. Establish the verified creator's safe global defaults and create/restrict the private schema; clear private-schema-specific default additions before creating tables.
3. Create `entitlement_bundles`, `bundle_items`, `plan_versions`, then `term_prices`, with qualified dependencies and constraints.
4. Enable RLS on all four new tables, leave policies absent, and explicitly revoke any unintended ACLs on new objects as defense in depth.
5. Assert final ownership, ACL/default state, empty tables and absence of new routines/consumers; allow the runner to complete the file only if all assertions hold.

Migration 00022 **MUST rely exclusively on the Supabase migration runner's verified per-file wrapping transaction** for ALL-OR-NOTHING atomicity. Before authoring, the implementation must verify the installed CLI/runner behavior. The migration file must contain no authored transaction-control `BEGIN`, `COMMIT` or `ROLLBACK`, no `-- pg-delta: transaction=false` directive, and no partial-success mode. Authored transaction control can interact unsafely with Supabase CLI migration execution and may permit warning-only, partial or skipped execution. If the runner's atomic wrapping cannot be verified, **STOP and report; do not implement**.

No concurrent index build, runtime deployment, seed, DML against existing records, destructive ALTER/DROP/TRUNCATE, or permissive partial success. ALTER operations on the newly created tables/default ACLs to establish this boundary are allowed; altering existing public tables/policies/functions is excluded.

## 4. Exact private schema and object inventory

The accepted name is **`commercial_private`** (C3 §§2, 44, 47). It remains absent from `api.schemas`, `api.extra_search_path`, active PostgREST exposed schemas and Realtime publication membership. Config files remain unchanged. Physical FK visibility/introspection is not permission to return private rows in a public projection.

| New table | Meaning and stable reference |
| --- | --- |
| `commercial_private.entitlement_bundles` | One version of a named typed benefit bundle; stable UUID plus bundle code/version and capability-registry version. |
| `commercial_private.bundle_items` | Explicit typed scalar values belonging to exactly one bundle version; no JSON rule language. |
| `commercial_private.plan_versions` | Immutable material commercial metadata/bundle reference for an existing `public.plans.id`, separated from mutable public identity labels. |
| `commercial_private.term_prices` | Versioned standard retail month-duration/IQD price offers tied to one retail plan version. |

No Business/entity/user FK, purchased term, agreement, eligibility, payment, entitlement interval or publication record is introduced. Table emptiness after migration is mandatory. All data in the test gate is isolated and rolled back.

## 5. `public.plans` and legacy subscriptions — precise preservation

Existing `public.plans`: `id uuid` PK with UUID default; unique non-null `code`; non-null `name`; nullable `description`; `is_active boolean NOT NULL DEFAULT true`; creation/update timestamps and shared update trigger. 00010 grants anon/authenticated SELECT and its `plans_select_all` policy is unfiltered. Preserve these columns, constraints, grants, policies, trigger and data exactly.

Each private plan version has a non-null FK to `public.plans(id)`, `ON UPDATE RESTRICT ON DELETE RESTRICT`. No new uniqueness constraint or composite key is added to the public table. No rename, replacement, new plan row, activation/deactivation, public view or nested public payload is added. `public.plans.is_active` remains its existing flag and is not reinterpreted as approved offer, entitlement or publication authority. The new FK preserves future referenced identities; with no private rows, current behavior is unchanged.

C3 reserves `business`, `business_pro`, `business_plus`, `corporate` for later collision-reviewed mapping. M1a must not assume those rows already exist in a deployed database. Four synthetic identities with those shapes may exist only in transactional tests. Later M2 publication must verify stable ID/code/family and pricing-mode mapping against approved identities; a bare FK does not establish that commercial mapping.

Existing `public.subscriptions` remains unchanged: UUID/entity/plan references; `trialing/active/past_due/canceled/paused`; mandatory `started_at`, nullable `ends_at`, `price_paid numeric(12,2)` and currency; existing date check, timestamps, indexes and grants/RLS. M1a neither reads these labels as commercial entitlement nor writes/migrates their rows. Any future public commercial catalog requires a separately authorized safe projection/RPC.

## 6. Creator and ownership preflight — no assumed execution role

Current migrations do not declare `SET ROLE`, an explicit schema owner or owner-specific default ACLs. CLI configuration identifies PostgreSQL 17, not the effective migration creator. Do not hardcode `postgres` as a verified fact from those files, or use the test runner's login as proof of migration ownership.

Define **R** as the trusted `current_user` that will actually execute object creation. Before the authorized migration, capture non-secret evidence through the same local migration execution path: server version, `session_user`, `current_user`, effective role, role attributes/membership, schema-create/FK-reference authority, relevant global and schema default ACLs and existing object ownership. Verify R can set its own defaults and create the private schema, and that anon/authenticated/service_role do not inherit R or another role granting private access. R must not be a client application role. No client token, password or key may enter the report.

The migration must assert that its actual creator matches this verified context. Its schema, tables, indexes and implicitly generated table row types are owned by R; ownership transfer after creation is not a substitute for setting the creator's defaults. Quote any dynamically used role identifier safely; never treat a client value as an identifier. Ordinary client roles receive no membership, CREATE or runtime privileges. Later slices using another creator must establish and test that creator's defaults before creating commercial objects.

If runtime evidence reveals unexpected ownership, inherited grants, unsupported privileges or a schema collision, fail the gate before deployment. Do not improvise a role, expand the allowlist, use blanket CASCADE or silently retry mutation. The exact implementation is conditional on this verified role context; the contract defines the required end state without pretending that offline inspection verified it.

## 7. Required owner/default-privilege hardening — MED-1

The relevant PostgreSQL 17 rules are checked against primary [ALTER DEFAULT PRIVILEGES documentation](https://www.postgresql.org/docs/17/sql-alterdefaultprivileges.html): defaults apply to future objects of their actual creator, not inherited membership roles; schema-specific defaults add to global defaults. A schema-only revoke cannot remove built-in PUBLIC function EXECUTE. Changing defaults does not revoke existing objects.

`FUNCTIONS` and `ROUTINES` are equivalent terminology for this ALTER DEFAULT PRIVILEGES purpose. Include TYPES default protection as defense in depth without creating custom types/domains or expanding the four-table boundary.

The selected design is persistent default hardening for verified creator R, plus private-schema ACL checks. It adds no role and does not rely on remembering each future function's revoke. This is the explicitly required security configuration exception to a structures-only migration:

| Boundary | Required implementation equivalent / verified outcome |
| --- | --- |
| Schema itself | Revoke ALL (USAGE and CREATE) on `commercial_private` from PUBLIC, anon, authenticated and service_role; no other non-owner grant or inherited client access. |
| R's global TABLES defaults | `ALTER DEFAULT PRIVILEGES FOR ROLE R` with REVOKE ALL ON TABLES from PUBLIC, anon, authenticated and service_role; neutralize global additions that could otherwise flow into private tables. |
| R's global SEQUENCES defaults | Same creator-level REVOKE ALL ON SEQUENCES from those grantees, although no production sequence is created by M1a. |
| R's global FUNCTIONS defaults | Same creator-level REVOKE EXECUTE ON FUNCTIONS from those grantees, **without `IN SCHEMA`**, removing built-in PUBLIC EXECUTE and any explicit client defaults. |
| R's global TYPES defaults | Same creator-level REVOKE USAGE ON TYPES from PUBLIC and unintended client grantees, including anon, authenticated and service_role, **without `IN SCHEMA`**, removing built-in PUBLIC USAGE and any explicit client defaults. |
| R's private-schema additions | Revoke matching TABLES/SEQUENCES/FUNCTIONS/TYPES default grants `IN SCHEMA commercial_private`; a remaining schema-specific grant must not restore access removed globally. |
| New current objects | Revoke ALL on new private tables and any unexpectedly granted private objects from the same grantees; this complements secure defaults and cannot replace them. |

`R` above is a verified, safely quoted role identifier, not literal SQL to paste without preflight. Preserve R's necessary owner privileges. Inspect all other default grantees and role inheritance, not just these four names; an unexpected accessible role requires a fail-closed report, not an unreviewed cascade.

**Global scope is intentional and must be disclosed in implementation review:** R's reduced defaults affect its future objects across this database. They do not alter existing public-schema object ACLs, existing RPC EXECUTE grants or current public reads. Existing `IN SCHEMA public` default additions are not rewritten in M1a and may still explicitly grant access to future public objects; no such new public object is in this slice. Later slices must use explicit reviewed grants for any intended future exposure. Do not revoke ALL ON ALL TABLES/FUNCTIONS IN SCHEMA public or restore unsafe PUBLIC function defaults as a rollback shortcut.

Acceptance requires both catalog/default-ACL inspection and fresh-object probes under R (§17). Schema exclusion or current named-table revokes alone are insufficient.

## 8. Search-path invariant — MED-2

M1a creates **zero persistent functions and zero triggers**, so no SECURITY DEFINER function is necessary. Confirm that through source inspection and before/after `pg_proc` inventory, not just a search for one expected name. Test-only probe functions in §17 are SECURITY INVOKER and disappear with ROLLBACK.

Future private commercial definers must use a fixed trusted path such as `commercial_private, pg_temp`, with `pg_temp` last, and qualify cross-schema relations/functions. Prefer fully-qualified references throughout; an empty path with all references qualified is also suitable when reviewed. Keep untrusted `public`, caller-selected schemas and early `pg_temp` out of commercial authority lookup. Fully qualifying one table is not sufficient if types, functions, operators or dynamic SQL still resolve through an unsafe path. The primary [PostgreSQL definer security guidance](https://www.postgresql.org/docs/17/sql-createfunction.html#SQL-CREATEFUNCTION-SECURITY) informs this invariant.

No new `SET search_path = public, pg_temp` commercial function is permitted. Existing functions retain their accepted definitions. A future function contract must verify controlled namespace CREATE privileges (including no PUBLIC CREATE on `public`), trusted owner, explicit EXECUTE grants, actor authorization, fixed resolution and adversarial schema/temp-object injection tests. M1a does not alter the existing public schema. Needing a persistent function in M1a requires Architect reauthorization rather than treating this future invariant as permission to create one.

## 9. Common DDL conventions and lifecycle checks

These are exact intended schema requirements for review, not executed DDL. All columns below are NOT NULL unless explicitly marked nullable. Each table uses a UUID `id` PK with the existing UUID-generation convention. Existing migrations commonly use bare `gen_random_uuid()`; the deliberately qualified PostgreSQL 17 built-in `pg_catalog.gen_random_uuid()` is the safer intended form for new M1a DDL. `created_at timestamptz DEFAULT pg_catalog.now()` is documentary creation time, never a payment/publication/entitlement anchor. No new extension is needed.

No `updated_at` column/trigger is introduced: these are versioned records, with specific publication/retirement markers rather than a generic overwritable historical timestamp. PK/FK key values are stable; FKs are immediate and retention-preserving (`ON UPDATE RESTRICT ON DELETE RESTRICT`), never cascading version/history deletion. PK and UNIQUE indexes supply the indexes specified below; no speculative general indexing layer is added.

Bundles, plan versions and term prices share `status text DEFAULT 'draft'` checked to `draft`, `published`, `retired`; nullable `published_at` and `retired_at` timestamptz markers. Enforce this exact shape: draft has neither marker; published has `published_at` and no retirement marker; retired has both and `retired_at >= published_at`. Non-null lifecycle times must be finite. Status is catalog availability, not subscription, entitlement, Business lifecycle or publication. A valid row shape does not authorize a publication transition (§14).

Plan/price effective windows use nullable `effective_from` and `effective_until` timestamptz with half-open semantics `[from, until)`. Finite endpoints; an end requires a start and must be greater than it. Published/retired rows require a start. Drafts may carry planned windows; a NULL end means no catalog end scheduled, never an unlimited commercial entitlement.

## 10. Exact minimum plan-version model

`commercial_private.plan_versions`:

| Column | Type/default or reference | Intended constraint / meaning |
| --- | --- | --- |
| `id` | uuid PK, UUID default | Stable plan-version reference. |
| `plan_id` | uuid FK `public.plans(id)` | Existing canonical stable identity; RESTRICT. |
| `version` | integer | Greater than zero; UNIQUE `(plan_id, version)`. |
| `bundle_version_id` | uuid FK `commercial_private.entitlement_bundles(id)` | Explicit benefit-version pin; RESTRICT. |
| `pricing_mode` | text | Checked to `retail` or `custom_quote`; no default that assumes a family. |
| `name_ar` | text | Trimmed non-empty display metadata for the version, not a rewrite of `public.plans.name`. |
| `description_ar` | text, nullable | NULL or trimmed non-empty metadata. |
| `sort_order` | integer DEFAULT 0 | Non-negative commercial display order, not entitlement precedence. |
| `status`, `published_at`, `retired_at` | Common lifecycle fields | §9 lifecycle check. |
| `effective_from`, `effective_until` | timestamptz, nullable | §9 window checks. |
| `created_at` | timestamptz, creation default | Documentary creation time. |

Add UNIQUE `(id, pricing_mode)` as the target of the restrictive term-price composite FK. No duplicate plan family/code column is added: the canonical plan UUID remains the identity. Future publisher validation binds Business/Pro/Plus to `retail`, Corporate to `custom_quote`, rejects unmapped/colliding identities and requires a compatible published bundle. No cross-table business rule is disguised as an unsafe CHECK querying mutable public rows.

Multiple numbered draft versions are permitted; retirement prevents new offers but leaves old version/bundle references usable for future historical fulfillment. M1a supplies no publisher or active offer selector. Overlap and transition checks belong to the later authorized catalog writer (§14), before any published offer can be consumed.

## 11. Exact minimum bundle and typed-item model

`commercial_private.entitlement_bundles`:

| Column | Type/default or reference | Intended constraint / meaning |
| --- | --- | --- |
| `id` | uuid PK, UUID default | One immutable bundle-version identity. |
| `code` | text | Stable lowercase machine code; full-string pattern `^[a-z][a-z0-9_]*$`, length 1–64. |
| `version` | integer | Greater than zero; UNIQUE `(code, version)`. |
| `registry_version` | integer | Greater than zero; identifies the compatible future server capability registry. |
| `status`, `published_at`, `retired_at` | Common lifecycle fields | §9 lifecycle check. |
| `created_at` | timestamptz, creation default | Documentary creation time. |

`commercial_private.bundle_items`:

| Column | Type/default or reference | Intended constraint / meaning |
| --- | --- | --- |
| `id` | uuid PK, UUID default | Item identity with the existing UUID convention. |
| `bundle_version_id` | uuid FK `commercial_private.entitlement_bundles(id)` | RESTRICT; UNIQUE `(bundle_version_id, capability_key)`. |
| `capability_key` | text | Length 1–128; lowercase dot-separated identifiers, each segment matching `[a-z][a-z0-9_]*`; no whitespace or executable expression. |
| `value_kind` | text | Checked to `boolean`, `integer` or `text`. |
| `value_boolean` | boolean, nullable | Value only for boolean kind. |
| `value_integer` | bigint, nullable | Value only for integer kind; non-negative whole-unit count/limit. |
| `value_text` | text, nullable | Value only for text kind; trimmed non-empty scalar, maximum 256 characters. |
| `is_required` | boolean DEFAULT true | Compatibility flag for future fail-closed evaluation; it grants no right. |
| `created_at` | timestamptz, creation default | Documentary creation time. |

Use an explicit CHECK of three alternatives: for each `value_kind`, its matching value is non-null and both other values are null. Do not rely on a nullable comparison that can pass SQL CHECK as UNKNOWN. Negative integer values, unknown kinds, no value, multiple values and empty text must fail. There is no JSON/JSONB, SQL expression, nullable unlimited quota sentinel or client-provided arbitrary grant language.

M1a stores typed scalar structure, not the full feature registry or a tier matrix. No media quota, extra-Branch price/cap, Grace access or analytics policy is invented. Future approved publishers/evaluators must match key/type/registry versions, validate allowed scalar values and deny the dependent capability for unknown required keys, unknown registry versions or incompatible types. Optional unknown data may never create rights. Stored rows alone create no effective commercial entitlement; the fixed server evaluator remains a later slice under C3 §9.

## 12. Exact minimum term-price model

`commercial_private.term_prices` contains standard retail offers only:

| Column | Type/default or reference | Intended constraint / meaning |
| --- | --- | --- |
| `id` | uuid PK, UUID default | Stable immutable price-version identity. |
| `plan_version_id` | uuid | Composite FK `(plan_version_id, pricing_mode)` to `plan_versions(id, pricing_mode)`, RESTRICT. |
| `pricing_mode` | text DEFAULT 'retail' | CHECK `pricing_mode = 'retail'`; composite FK prevents a row for a custom-quote version. |
| `version` | integer | Greater than zero; UNIQUE `(plan_version_id, duration_months, version)`. |
| `duration_months` | integer | CHECK IN `(1, 3, 12)`; no six-month standard retail offer. |
| `amount_iqd` | bigint | CHECK `amount_iqd >= 0`; whole IQD units, not minor units or floating point. |
| `currency` | text DEFAULT 'IQD' | CHECK `currency = 'IQD'`; non-null, no silent currency conversion. |
| `status`, `published_at`, `retired_at` | Common lifecycle fields | §9 lifecycle check. |
| `effective_from`, `effective_until` | timestamptz, nullable | §9 window checks. |
| `created_at` | timestamptz, creation default | Documentary creation time. |

Required representability from frozen policy §3.2 / C3 §4, reproduced as test-shape evidence, **not production seed instructions**:

| Plan family | 1 month IQD | 3 months IQD | 12 months IQD |
| --- | --- | --- | --- |
| Business | 20,000 | 55,000 | 200,000 |
| Business Pro | 40,000 | 110,000 | 400,000 |
| Business Plus | 70,000 | 190,000 | 700,000 |

Corporate has `custom_quote`, no required retail price row and no fixed price in M1a. Its approved Plus floor, 12-month minimum and quotation workflow remain future quote/term authority; a standard-retail duration check must not be misapplied to Corporate quotes. Founding adjustments, A8 promotional grants, Sponsored, add-ons and payment allocations are not encoded as term-price rows by M1a.

Non-negative storage does not approve a zero-price permanent tier. Only a separately authorized publisher may validate policy-approved retail prices. PostgreSQL integer storage guarantees integer representation, not rejection of every fractional expression before a cast; later input validation must reject unsupported monetary values before coercion. No rounding or legacy conversion is performed here.

## 13. Constraint and index acceptance summary

Immediate M1a database enforcement consists of UUID PKs; non-null required values; positive numbered versions/registry versions; exact uniqueness keys; typed item exclusivity/scalar checks; lifecycle-marker coherence; finite, ordered effective windows; `duration_months IN (1,3,12)`; non-negative integer IQD amount; exact IQD currency; restrictive FKs, including retail-mode consistency. Explicit NOT NULL and null-aware alternatives must make invalid values fail rather than disappear into three-valued CHECK logic.

No check binds any row to a current Business, user, subscription, category, launch count, payment evidence or open commercial policy answer. No value resolves OQ-01–03, OQ-12, OQ-16–17, OQ-23, OQ-72, OQ-80–84 or any other OPEN item. OQ-84 remains unresolved. All policy OQ statuses, severity, owner and classification remain unchanged; C1 AR and C2/C3 registers are untouched.

Only the listed PK/UNIQUE indexes are required. The bundle-item UNIQUE index covers its parent/key lookup; plan-version UNIQUE covers plan/version; term-price UNIQUE covers plan-version/duration/version. No performance-driven indexes, partial live-offer uniqueness rule or new extension is justified before the consumer contract. This foundation does not claim to enforce cross-row published-window overlap or historical mutation prevention yet (§14).

### Agreed constraint and index names — F3

Future 00022 DDL must use deterministic descriptive `chk_*` names for CHECKs, `fk_*` for FOREIGN KEYs, `uq_*` for UNIQUE constraints and `idx_*` for any separately authorized non-constraint index. A UNIQUE constraint's backing index retains its `uq_*` name; a PK uses the conventional `<table>_pkey`. No non-constraint index is currently required or authorized by M1a. Existing repository names are not renamed.

The following names are the contract's agreed inventory for the already specified checks/keys; grouping checks under these names does not change their semantics or add columns/rules:

| Table | Exact name | Existing requirement enforced |
| --- | --- | --- |
| `entitlement_bundles` | `entitlement_bundles_pkey` | PK `(id)`. |
| `entitlement_bundles` | `uq_entitlement_bundles_code_version` | UNIQUE `(code, version)`. |
| `entitlement_bundles` | `chk_entitlement_bundles_code` | Full code pattern and length (§11). |
| `entitlement_bundles` | `chk_entitlement_bundles_version` | Positive version. |
| `entitlement_bundles` | `chk_entitlement_bundles_registry_version` | Positive registry version. |
| `entitlement_bundles` | `chk_entitlement_bundles_lifecycle` | Allowed status, marker coherence and finite lifecycle times (§9). |
| `bundle_items` | `bundle_items_pkey` | PK `(id)`. |
| `bundle_items` | `fk_bundle_items_bundle_version_id` | Restrictive bundle-version FK. |
| `bundle_items` | `uq_bundle_items_bundle_key` | UNIQUE `(bundle_version_id, capability_key)`. |
| `bundle_items` | `chk_bundle_items_capability_key` | Full segmented key pattern and length (§11). |
| `bundle_items` | `chk_bundle_items_typed_value` | Allowed kind and exactly its matching non-null value; other values null (§11). |
| `bundle_items` | `chk_bundle_items_integer_value` | Non-null integer values are non-negative. |
| `bundle_items` | `chk_bundle_items_text_value` | Non-null text values are trimmed non-empty scalars within the length limit. |
| `plan_versions` | `plan_versions_pkey` | PK `(id)`. |
| `plan_versions` | `fk_plan_versions_plan_id` | Restrictive FK to `public.plans(id)`. |
| `plan_versions` | `fk_plan_versions_bundle_version_id` | Restrictive bundle-version FK. |
| `plan_versions` | `uq_plan_versions_plan_version` | UNIQUE `(plan_id, version)`. |
| `plan_versions` | `uq_plan_versions_id_pricing_mode` | UNIQUE `(id, pricing_mode)`. |
| `plan_versions` | `chk_plan_versions_version` | Positive version. |
| `plan_versions` | `chk_plan_versions_pricing_mode` | `retail` or `custom_quote`. |
| `plan_versions` | `chk_plan_versions_metadata` | Non-empty `name_ar`; NULL or non-empty `description_ar` (§10). |
| `plan_versions` | `chk_plan_versions_sort_order` | Non-negative order. |
| `plan_versions` | `chk_plan_versions_lifecycle` | Allowed status, marker coherence and finite lifecycle times (§9). |
| `plan_versions` | `chk_plan_versions_effective_window` | Finite, ordered window; an end requires a start; published/retired require a start (§9). |
| `term_prices` | `term_prices_pkey` | PK `(id)`. |
| `term_prices` | `fk_term_prices_plan_version_pricing_mode` | Restrictive composite FK to `plan_versions(id, pricing_mode)`. |
| `term_prices` | `uq_term_prices_plan_duration_version` | UNIQUE `(plan_version_id, duration_months, version)`. |
| `term_prices` | `chk_term_prices_version` | Positive version. |
| `term_prices` | `chk_term_prices_pricing_mode` | `retail` only. |
| `term_prices` | `chk_term_prices_duration_months` | 1, 3 or 12 months. |
| `term_prices` | `chk_term_prices_amount_iqd` | Non-negative amount. |
| `term_prices` | `chk_term_prices_currency` | IQD only. |
| `term_prices` | `chk_term_prices_lifecycle` | Allowed status, marker coherence and finite lifecycle times (§9). |
| `term_prices` | `chk_term_prices_effective_window` | Finite, ordered window; an end requires a start; published/retired require a start (§9). |

Migration/static/runtime tests must use this agreed inventory as their independent expected names, not infer expected names from the implementation and test those same invented names. Assert name, table, constraint kind, columns/reference/check meaning and corresponding backing index where applicable through source and database catalogs; for named-constraint violations, failure tests must identify the expected constraint as well as SQLSTATE. Any future non-constraint index needs an agreed exact `idx_*` name before authoring, through Architect reauthorization; this convention does not authorize extra indexes.

## 14. Historical immutability and future publication prerequisite

Before publication/reference, a trusted future catalog authoring workflow may revise a draft's material metadata, bundle link, typed values and planned prices/windows. Published or commercially referenced material facts must thereafter be immutable: plan identity/version; bundle identity/registry/items; approved metadata/benefits; currency, amount, duration and version identity. Changes require a new version. Retirement/approved availability changes stop new offers, never rewrite purchased price or benefit history. Future orders/terms must pin immutable version IDs and material snapshots per C3 §§5, 36.

M1a creates no authoring API, publication transition, consumer or production row. FKs enforce references and block destructive parent deletion; CHECKs only enforce each row's shape. They **do not prove immutability under owner UPDATE, child-item UPDATE/DELETE or lifecycle reversal**. No owner/superuser bypass is described as secure runtime authorization.

Before any later production catalog publication/reference, its accepted writer slice must implement and test a transactional guard/trigger/RPC boundary that locks the plan version, bundle and prices consistently, seals bundle items, rejects mutation/deletion/reversion after publication or commercial reference, verifies compatible published bundles and identity/pricing mapping, and prevents overlapping published standard offers for the same plan/duration/time across versions. It must preserve purchased snapshots and audited retirement semantics. This is a prerequisite carried from C3, not permission to implement such functions/triggers now. M1a may pass as an empty, inaccessible pre-consumer foundation; it may not be presented as a fully enforced live catalog.

## 15. Deny-by-default runtime access and migration safety

All four tables have RLS ENABLED, zero policies, no grants to PUBLIC/anon/authenticated/service_role and no client-accessible schema USAGE/CREATE. Owner administration is a trusted DDL/test context; owners or privileged roles can bypass ordinary RLS. Trusted SQL-editor/admin roles may access private structures by design within their existing authority; that is not Data API exposure or a new client grant. ACLs, role membership and schema/API exclusion therefore remain independent controls. Do not create a business/staff capability, membership, service credential or grant.

No public CRUD, Business Center read, Admin Console read, Flutter consumer, new RPC, view, public nested join, Realtime feed, worker or scheduler is introduced. No change to routes, AuthProvider, production Supabase authority or existing Directory policies. Private schema absence from API config alone does not prove ACL safety; ACL denial alone does not prove actual API schema exclusion. Verify both.

The future review must compare pre/post public object definitions, constraints, grants/policies/functions, existing plan/subscription data and current Directory read outputs. Preserve the existing schema's behavior, even where its later commercial replacement is planned. Catalog creation time/status and public plan active status must never be interpreted as paid rights or publication.

## 16. Exact file allowlists

**Present drafting allowlist — one new file only:**

`docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_M1A_PRIVATE_CATALOG_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md`

**Maximum proposed future M1a implementation allowlist — three new files only, requiring later explicit authorization:**

| Exact future path | Purpose |
| --- | --- |
| `supabase/migrations/00022_commercial_private_catalog_foundation.sql` | Single additive private foundation/default-security migration. |
| `supabase/tests/commercial_m1a_private_catalog_foundation_test.sql` | Focused transactional pgTAP structure, data constraints, owner/default ACL probes and regression evidence. |
| `test/commercial_m1a_private_catalog_migration_test.dart` | Focused source/inventory/config/absence-of-consumer assertions, following existing Dart migration-test conventions. |

No wildcard permission or edits to existing migration/test/gate/config files are included. Existing test files below are read/run-only. Any additional role/function/trigger, API test harness file, CI change, production file, migration ID/name change or surface beyond these paths requires Architect reauthorization. Disposable test fixtures and evidence outputs do not become production source; keep temporary evidence outside protected paths, sanitize it and do not stage it.

## 17. Focused runtime structure, constraints and default-privilege tests

Use PostgreSQL 17 in an explicitly verified disposable **local** Supabase database. Capture a pre-00022 baseline after 00021; apply the future migration through the real runner and compare the same database before/after. A clean full chain through 00022 must also succeed. Tests use BEGIN, pgTAP assertions, `SET LOCAL ROLE`, controlled synthetic JWT identities as needed, `RESET ROLE`, `finish()` and final ROLLBACK, matching the existing smoke convention. Those transaction-control statements belong only in test files, never migration 00022. Test failures must return a non-zero gate result. Verify the installed runner's per-file atomic wrapping before migration authoring; source checks must reject authored migration transaction control and the transaction=false directive (§3). Failure-path evidence must prove runner-owned atomic rollback without warning-only, partial or skipped execution.

| Required evidence class | Exact assertions / cases |
| --- | --- |
| Migration structure | Exactly the new schema/four tables; exact columns/types/defaults and agreed constraint/backing-index names from §13, verified independently by source/static/runtime tests; restrictive public plan FK and retail-mode composite FK; correct owner R; RLS enabled/no policies; no new routine/trigger/view/sequence/extension/role or public structure change; 00022 follows unchanged 00001–00021. |
| Constraint failures | Duplicate plan/version, bundle code/version, bundle item/key or price plan/duration/version; zero/negative/null required versions; orphan plan/bundle/price FK; quote-mode price; durations 0/2/6/negative; negative amount, non-IQD/null currency; invalid status/marker/window/null-endpoint shapes; unsupported kind, negative integer, missing/multiple typed values, malformed key/code and empty/oversize text. Assert actual SQLSTATE/check failures. |
| Valid representability | Synthetic Business/Pro/Plus plan identities, pinned bundle versions and all nine frozen retail amount/duration shapes; integer storage verified; custom-quote Corporate version with zero retail price rows; two historical version IDs coexist. No production fixture is retained. |
| Direct runtime denial | As anon and authenticated (including valid ordinary/business/staff JWT shapes), attempt private SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES/TRIGGER authority and schema CREATE; deny with 42501 as applicable. Verify effective service_role ACL denial separately; RLS bypass is not a schema/table grant. No caller can acquire owner privilege through role membership. |
| PUBLIC/default ACL | Inspect schema/object ACLs including implicit ACL defaults; expand ACLs and test grantee OID 0 for PUBLIC, not a fictional login named PUBLIC. Inspect `pg_default_acl` for R at global/private scope across TABLES, SEQUENCES, FUNCTIONS/ROUTINES and TYPES, and all effective client/inherited privileges; use the fresh-object probes below. Absence of an ACL row is not automatically absence of built-in PUBLIC EXECUTE or type USAGE. Verify TYPES defaults directly without creating custom types/domains. |
| No seed / no entitlement | All four production tables empty immediately after migration and again after fixture rollback; public plan/subscription/entity/membership rows unchanged; no agreement, purchased term, payment, grant or evaluator created. |
| Existing regression | Public plan schema/policy/ACL and permitted client result sets unchanged; existing Directory active-parent reads and denied mutations unchanged; subscriptions definitions/ACL/data unchanged; existing RPC definitions/ACL unchanged. Compare deterministic before/after fixtures plus retained source/data fingerprints. |

### Fresh-object defaults probe — mandatory MED-1 proof

Within the rolled-back test transaction, create ordinary test objects **in `commercial_private` as the same verified creator R**: a small table, a sequence and an ordinary SECURITY INVOKER SQL function returning a harmless constant. They are not persistent migration objects. Do not use `CREATE TEMP TABLE` as the main schema-default probe, because a pg_temp object would test a different namespace; do not manually REVOKE on any probe object before asserting defaults.

Inspect each new object's effective ACL, resolving NULL ACLs through PostgreSQL defaults; PUBLIC and ordinary client roles must have no table/sequence/function authority. Anon/authenticated must fail qualified operations and execution; independently inspect function EXECUTE so schema denial cannot mask a leaked function ACL. Owner R can perform the harmless baseline operation. Roll back all probes and any test-only fixture changes. This proves defaults for future objects; named-table revokes alone cannot satisfy the gate.

The test must also prove that the migration's global-default change left **existing** public table/function ACLs unchanged. Later creation under a different owner is not covered by R's successful probe and must establish its own verified defaults. No unverified default-permission claim or skipped runtime test may support acceptance.

## 18. Focused API, search-path and app regression gate

The future authorized gate must inspect configured `api.schemas` and the running local PostgREST schema configuration; `commercial_private` must be excluded from both, with no private Realtime publication. With local anon and ordinary authenticated sessions, probe the private schema through actual Data API schema/profile selection and confirm it cannot return or mutate catalog rows. Compare an allowed `public.plans` read and current Directory list/detail reads before/after. Keep these bounded operational HTTP probes in the evidence record; no new production API/harness file or remote connection is authorized.

For search-path evidence, demonstrate zero new persistent definer or invoker functions/triggers after excluding rolled-back probes. If a function becomes necessary, the three-file scope/design must be reauthorized and its fixed-path injection/adversarial tests supplied; a source-text pattern or definer label alone cannot prove safe resolution.

Run the following **future** focused commands sequentially; these were not run during drafting. CLI syntax was checked against installed help, and [Supabase database testing guidance](https://supabase.com/docs/guides/database/testing) supports the pgTAP mechanism:

```text
supabase db reset --local --version 00021
```

That command is allowed only in the future disposable local gate. Capture baseline evidence and the migration execution role; forward-apply the sole pending 00022 migration with:

```text
supabase migration up --local
```

Capture the before/after comparisons on that same database before resetting it. Then prove clean full-chain application with:

```text
supabase db reset --local
supabase db lint --local --schema commercial_private --level warning --fail-on warning
supabase test db --local supabase/tests/commercial_m1a_private_catalog_foundation_test.sql supabase/tests/v1_r09q_security_smoke.sql
flutter test --no-pub test/commercial_m1a_private_catalog_migration_test.dart
flutter test --no-pub test/v1_r09q_migration_lint_test.dart
flutter test --no-pub test/v1_r09q_security_matrix_test.dart
flutter test --no-pub test/v1_r05_directory_cloud_integration_test.dart
```

The new test must verify migration scope, no seed/consumer/config exposure and default-hardening intent; existing lint/security suites preserve accepted history and the Directory suite provides a focused read/parser regression. None replaces runtime ACL, fresh-object or actual API probes. Use the focused paths, not `tool/quality_gate.ps1`, the entire SQL test directory or a repository-wide suite. No SDK/cache/global package patches, automatic tool installation, linked/remote reset/push, production connection or protected-test edits. If local runtime infrastructure is unavailable, report the gate incomplete and obtain the necessary environment decision; do not downgrade it to static-only PASS.

## 19. Carry-forward requirements and ownership

Review labels below are trace labels from the request; they do not imply unresolved semantic acceptance blockers in accepted C3. C3 §47 remains the accepted requirement authority.

| Carry-forward | Required handling / boundary |
| --- | --- |
| MED-1 — M1a default privileges | Required now in the future M1a migration design: verified creator defaults, schema/object ACLs and unrevoked fresh-object probes (§§6–7, 17). No reliance on manual per-function revokes. |
| MED-2 — definer search_path | No M1a persistent function; future fixed trusted path/qualified resolution invariant and adversarial gate (§§8, 18). |
| MED-3 — legacy amount | M4 owns evidence-backed `public.subscriptions.price_paid numeric(12,2)` → integer-IQD conversion, explicit rounding, exceptions and reconciliation. M1a creates empty bigint price structure and performs **NO conversion**. |
| MED-4 — profile lock order/security | Future profile/commercial integration must reconcile 00020 entity-lock-before-business-authorization behavior, unauthorized locking/error implications and interaction with C3's global lock order/other paths. M1a does not modify 00020 or decide its replacement. |
| Projection consistency before M5 | Explicit publication-projection vs authoritative-generation reconciliation testing is mandatory before cutover, including disagreement/staleness and fail-closed guards. M1a creates no projection or test for that later behavior. |
| Catalog publication/immutability | Before M2/later production publication or any reference/consumer: compatible bundle validation, material immutability, item sealing, identity mapping and overlap tests (§14). No catalog runtime acceptance is inferred from M1a DDL. |

No OQ is answered, closed, narrowed or reclassified. No unrelated contract family is self-authorized, and C1/C2/C3 registers retain their accepted meanings.

## 20. Explicit exclusions / no seed or activation

No production plan/bundle/price reference-data seeding; no Business/Pro/Plus activation; no Launch Partner/Founding eligibility or grants; no payment, commercial agreement, purchased term, entitlement evaluation/grant, publication/hiding, Directory RLS/read cutover, existing-state reconciliation/backfill, ownership invitation, branch/media/analytics rule, Corporate quote flow, Sponsored product, worker/scheduler, app UI/routes/auth/cache consumer, Supabase config/API exposure change or production deployment.

Commercial Model, C1, C2, C3, roadmap, 00001–00021, seed, existing SQL tests, all Flutter production files, CI/quality scripts and protected dirty files remain outside the edit allowlist. M1a creates no new runtime application authority. A test fixture is not permission to create production reference data or invent an OPEN OQ answer.

## 21. Rollback and failure boundary

M1a is additive and pre-consumer. On a migration failure, the verified runner-owned wrapping transaction must atomically roll back schema/tables/default-ACL changes; never leave a partially exposed foundation. Migration 00022 must not author its own ROLLBACK or other transaction control (§3). A successful but not-yet-used foundation's primary operational rollback is to keep structures private/unreachable and activate no consumers. Existing public behavior continues.

Do not use destructive DROP, public ACL relaxation or restoration of unsafe PUBLIC function defaults as normal production rollback. Removing proven unused additions is possible only through an explicitly reviewed migration policy; once later slices reference them, retain historical records and restrictive FKs. Capture pre-change defaults for evidence, not as an automatic insecure rollback script. Later restore/deprecation/cleanup requires its own accepted scope and authorization.

## 22. Future implementation acceptance gate

Future M1a implementation is acceptable only when independent focused review confirms the three-file allowlist, additive transactional migration, exact structures/constraints, zero production rows/consumers/functions, verified owner/defaults, inaccessible/non-exposed private schema, no client privilege/EXECUTE leak, rolled-back fresh-object probes, successful runtime database/data/API regression tests and focused static/Directory gates. Existing plans, subscriptions, Directory and RPC behavior must be unchanged; global default-hardening scope must be explicitly recorded. No protected dirty file or unrelated formatting/refactor may change.

Report actual commands, assertion counts, role/default evidence, exit statuses and any environmental limitation. Historical PASS, Docker absence, future test descriptions or a successful Flutter/static test cannot substitute for runtime security evidence. Broad integrated suites/deployment are outside this gate.

## 23. Drafting validation, Git safety and review recommendation

Expected drafting delta: this one new untracked Markdown file. Protected baseline:

```text
 M test/a5_6_profile_bootstrap_test.dart
 M test/v1_r08_cloud_profile_foundation_test.dart
 M test/v1_r08_profile_edit_screen_widget_test.dart
?? OpenCode_Usage_Report.txt
?? artifacts/
```

Draft validation must verify existing-file fingerprints including protected artifacts; authorities/roadmap/SQL/Flutter/tests unchanged; local links resolve; Markdown table columns/fences valid; whitespace checks pass for both tracked baseline and the new untracked Markdown; staged list empty; HEAD and local origin/main still `0a31fce46b3235b698009773240788e3cd5b5533`; inventory still 00001–00021 with no 00022 SQL/test file created. Actual results are reported with delivery. No stage, commit, push, reset, revert, clean or stash is authorized.

Commercial policy decisions changed: 0. Accepted C3 technical architecture decisions changed: 0. OQs closed/reclassified: 0. Production implementation/migrations/tests created: 0. This draft specifies proposed DDL details and required future evidence without recording implementation, independent M1a review or Architect acceptance.

Recommendation: **READY FOR INDEPENDENT BACKEND/DATABASE/SECURITY CONTRACT REVIEW**. The review must assess the minimum DDL, owner-level default-hardening scope, deferred immutable-publication boundary and focused runtime gate. Acceptance of the contract must remain distinct from separate explicit authorization to implement M1a. No future implementation or contract family is authorized by this recommendation.

IMPLEMENTATION_AUTHORIZED = NO

## 24. Final Architect contract acceptance record — 2026-10-02

- Initial independent review: C
- Initial blocking technical findings: F1 transaction-wrapper ambiguity; F2 default-privilege completeness; F3 naming determinism
- Correction pass completed
- Focused independent re-review: A — READY FOR ARCHITECT ACCEPTANCE AND EXPLICIT IMPLEMENTATION AUTHORIZATION
- F1: RESOLVED
- F2: RESOLVED
- F3: RESOLVED
- F1 / F2 / F3: resolved and independently revalidated
- Remaining CRITICAL/HIGH/MEDIUM/LOW findings: 0
- Informational findings: 2, no action required
- Architect Acceptance: APPROVED
- Commercial policy changes: 0
- C1/C2/C3 architecture changes: 0
- M1a slice scope changes: 0
- OQs closed/reclassified: 0
- Implementation authorization: NO
- Authority: ChatGPT Architect

This record persists the supplied final Architect decision and focused independent re-review result. The two informational items were reviewed and explicitly considered non-blocking / no-action; neither polish item is applied, and §3 is unchanged by acceptance. Earlier draft/review statements remain preserved as historical context; the current metadata and this record establish contract acceptance without rewriting that history.

Acceptance is of the implementation contract only. The re-review's readiness for explicit implementation authorization is not authorization itself. The exact schema, four-table design, future migration and three-file implementation allowlist, F1/F2/F3 wording, security/test obligations, carry-forwards, exclusions and all OQs remain unchanged. M1a must not be implemented, and migration 00022 and its tests must not be created, until separate explicit Architect implementation authorization is issued. No future contract family is self-authorized.

IMPLEMENTATION_AUTHORIZED = NO
