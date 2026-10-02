# Civilpedia — M1b Canonical Commercial Catalog Reference Data Implementation Contract V1

CONTRACT_ID: M1b
CONTRACT_VERSION: V1
DOCUMENT_STATUS: **ACCEPTED — CANONICAL COMMERCIAL CATALOG DESIGN & SEQUENCING AUTHORITY**
FREEZE_STATE: ACCEPTED — DESIGN / SEQUENCING ONLY
ARCHITECT_ACCEPTANCE: **APPROVED**
SLICE: M1b — CANONICAL COMMERCIAL CATALOG REFERENCE DATA
SCOPE_STATE: **ZERO ROWS AUTHORIZED — SCOPE-A AND SCOPE-B BOTH DEFERRED** (§3)
MODE: **DOCUMENTATION ONLY — ACCEPTED DESIGN / SEQUENCING, NO IMPLEMENTATION**
IMPLEMENTATION_AUTHORIZED: **NO**
PREPARED_DATE: 2026-10-02
REVISED_DATE: 2026-10-02 (`DR-1` and `DR-2` folded in; scope re-derived. Second revision: `M1b-DEC-3` decided as **D3-A**; all 40 rows deferred); final documentary correction / Architect acceptance: 2026-10-03
REPOSITORY_BASELINE: main @ `4977a35d4f982fa75ec8c04eee606358dc9126ab`
LOCAL_ORIGIN_MAIN_BASELINE: `4977a35d4f982fa75ec8c04eee606358dc9126ab`
TECHNICAL_ARCHITECTURE_AUTHORITY: ACCEPTED C3, including §§2–5, 9, 32, 36, 37, 44, 46–47
POLICY_AUTHORITY: FROZEN Commercial Model V1 (§33 freeze)
PHYSICAL_FOUNDATION_AUTHORITY: `00022_commercial_private_catalog_foundation.sql` (M1a, accepted)
ACCEPTANCE_AUTHORITY: ChatGPT Architect
GIT_OWNER: User

---

## 1. Authority, purpose and present authorization

Authority chain: [Frozen Commercial Model V1](../CIVILPEDIA_COMMERCIAL_MODEL_V1.md) and its §33 freeze; [accepted C1](CIVILPEDIA_COMMERCIAL_CORE_AUTHORITY_RECONCILIATION_CONTRACT_V1.md); [accepted C2](CIVILPEDIA_COMMERCIAL_PUBLICATION_ENTITLEMENT_CONTRACT_V1.md); [accepted C3](CIVILPEDIA_COMMERCIAL_SUBSCRIPTION_ENTITLEMENT_ENFORCEMENT_CONTRACT_V1.md) §§46–47; and the accepted [M1a implementation contract](CIVILPEDIA_COMMERCIAL_M1A_PRIVATE_CATALOG_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md), whose physical result is [00022](../../../supabase/migrations/00022_commercial_private_catalog_foundation.sql).

This document specifies the smallest additive slice that would **populate canonical commercial catalog reference data** on top of accepted M1a: four canonical plan identities, four versioned entitlement bundles, one initial plan version per identity, and the exact nine standard retail term-price rows.

**As of this revision, that slice is not authorizable.** The Architect has decided `DR-1` and `DR-2` (§2). `DR-2` requires canonical plan identities to be withheld until a separately authorized `public.plans` hardening step exists, and that dependency cascades through the M1a foreign-key graph to withhold `plan_versions` and `term_prices` as well. The **frozen design of all 40 canonical rows is preserved in full** so that no decision, evidence, matrix or UUID is lost and the later authorized cutover has an unambiguous input.

Only this Markdown file is authorized in the present pass. Migration `00023`, the pgTAP test and the Dart test are **future artifacts of a not-yet-authorized cutover and must not be created now** (§21). **No test gate is defined for this pass**, because no artifact is authorized; §22 records only the requirements a future contract must re-state.

**Zero database rows, zero public deltas and zero private deltas are authorized by this document** (§19).

The Master Roadmap remains phase/status SSOT and is not advanced by this document. This pass does not unlock any implementation.

---

## 2. Architect decision register

Two decisions were escalated by the first draft. Both are now decided. They are recorded verbatim in intent; the Architect remains the acceptance authority for this re-scoped document.

### 2.1 `DR-1` — Arabic plan copy sentinel — **DECIDED**

`commercial_private.plan_versions.name_ar` is `NOT NULL` with `btrim(name_ar) <> ''`, but Arabic plan display copy is **OPEN** (`D-27`, `OQ-14`, `OQ-69`, §28.14) and **no authorized Arabic commercial-copy localization SSOT exists in this repository**. The Architect has decided:

1. A **private, draft-only localization sentinel/token** may be used for `name_ar`. It is **not** user-facing Arabic copy.
2. `plan_versions` remain **`draft`** only.
3. The placeholder is **private commercial metadata only**.
4. It must **never** be exposed through public catalog, API or UI.
5. **Publication/activation of a plan version must fail closed** while `name_ar` is still a placeholder.
6. Later replacement must come from the **authorized Arabic localization/copy SSOT**.
7. **M1b must not invent final Arabic marketing copy.**
8. `plan_versions` and `term_prices` **remain in M1b scope** — they are withheld solely by `DR-2` (§2.2), **not** by this localization decision.
9. This decision **does not close** the Arabic-copy OPEN question.

The concrete sentinel, enforcement invariants and required test gates are specified in §9.

### 2.2 `DR-2` — `public.plans` seeding — **DECIDED: DO NOT SEED**

Seeding the four canonical `public.plans` identities creates a real, observable public Data API delta. Frozen §14.3 row 1 records **"Subscription plan name — Never public — `LOCKED`"**; `L-37` records "Never public: plan name, price, payment details, expiry, … entitlement metadata"; §25.4 item 5 forbids exposing commercial metadata publicly. The Architect has decided:

1. **Do not amend or weaken Frozen §14.3 / `L-37`.**
2. **Do not seed** the four canonical `public.plans` identities in M1b under the current public-read policy.
3. **Do not use code-only or machine-token values in `public.plans.name` as a workaround** — that would still create a publicly readable plan-name surrogate. The first draft's "Option A restricted" is therefore **REJECTED, not merely deferred**.
4. **Do not create duplicate/private replacement plan identities** to bypass the existing FK architecture.
5. M1b must **explicitly recognize a sequencing dependency**: before canonical plan identities are seeded, Civilpedia needs a **separately authorized hardening/cutover step** that removes raw `public.plans` exposure and replaces it with an explicitly safe public catalog projection/DTO — if and when such public catalog presentation is authorized (§4).
6. Until that authority exists:
   - canonical `public.plans` seed = **DEFERRED**
   - `plan_versions` referencing those new canonical identities = **DEFERRED**
   - entitlement bundles **may be designed** but **must not be activated as commercial authority**
   - `term_prices` tied to deferred `plan_versions` = **DEFERRED**
   - **no Frozen policy addendum is created by M1b**
   - **no observable public plan-name exposure is accepted**
7. M1b **must not pretend the conflict is solved** and **must not silently become implementation-authorized**.
8. Architect priority: **preserve Frozen policy and accepted security boundaries over forcing M1b to seed data now.**

The derivation of these consequences from the M1a FK graph is in §5.6.

---

## 3. Sequenced re-scope of M1b

### 3.1 Scope partition

| Tier | Rows | Records | M1b status | Reason |
|---|---|---|---|---|
| **SCOPE-A** | **17** | 4 `public.plans` + 4 `plan_versions` + 9 `term_prices` | **DEFERRED** | Blocked by `DR-2` (§2.2). `plan_versions.plan_id` FKs `public.plans(id)`; `term_prices` FKs `plan_versions`. No anchor ⇒ no anchor-bound data. |
| **SCOPE-B** | **23** | 4 `entitlement_bundles` + 19 `bundle_items` | **DEFERRED** (`M1b-DEC-3` = **D3-A**) | `entitlement_bundles` has **no** FK to `public.plans` (§5.6), so these rows are *structurally* independent and remain fully specified. They are withheld by `DR-2.6` and, decisively, by the **D3-A** decision: no standalone draft-only bundle seeding (§3.2). |
| **Total designed** | **40** | — | **none authorized to be written** | — |

### 3.2 `M1b-DEC-3` — SCOPE-B seeding disposition — **DECIDED: D3-A (DEFER)**

`DR-2` states bundles "may be designed but must not be activated as commercial authority". Whether that permits writing **draft** bundle rows in M1b was not settled by the decision text. The Architect has decided:

> **Choose D3-A. Do NOT seed `entitlement_bundles` or `bundle_items` as a standalone slice.**

**Architect rationale (recorded):**

1. Standalone draft-only bundles provide **no runtime value** before canonical plan identities / `plan_versions` can be safely established.
2. Seeding only SCOPE-B would create a **partially materialized canonical catalog** whose remaining reference graph is intentionally blocked by `DR-2`.
3. Civilpedia should prefer **one deterministic, auditable reference-data cutover** after `HARDEN-1` rather than split canonical catalog creation across two disconnected seed events.
4. This avoids unnecessary **version/reconciliation complexity** before any runtime catalog consumer exists.
5. **No policy requires early bundle materialization.**

**Therefore:**

| Item | Status |
|---|---|
| SCOPE-A | **DEFERRED** |
| SCOPE-B | **DEFERRED** |
| **M1b rows authorized now** | **0** |
| All 40 canonical row definitions, UUIDs, price matrix, capability matrix, `DR-1` sentinel rules and conflict rules | **remain frozen as design** |
| Data seeding | **None** until `HARDEN-1` is accepted and implemented **and** a later explicit Architect authorization reopens the M1b seed |
| OQ closure/reclassification | **None.** No OQ is closed or reclassified by this decision |
| `IMPLEMENTATION_AUTHORIZED` | Remains **NO** |

**Rejected alternative — `D3-B` (standalone draft-only SCOPE-B seeding):** considered and **REJECTED**. It carries **no** authority, is **not** authorized, and must not be reintroduced by inference. Reopening it would require an explicit new Architect decision superseding this one; it is not available as an implementation shortcut.

### 3.2.1 Consequence of D3-A

D3-A removes the last remaining candidate for an authorizable M1b seed. Combined with `DR-2`:

```text
SCOPE-A  17 rows  DEFERRED  (structurally blocked by DR-2)
SCOPE-B  23 rows  DEFERRED  (decided by M1b-DEC-3 = D3-A)
           ────────────────────────────
TOTAL     40 rows  DESIGNED, FROZEN, 0 AUTHORIZED
```

**M1b is a complete, frozen design with no authorizable deliverable.** Its only remaining outputs are this document and the `HARDEN-1` prerequisite it identifies.

### 3.3 What this document now delivers

- The **complete frozen design** of all 40 canonical rows: identities, codes, UUIDs, matrices, evidence citations and exclusions — unchanged by the re-scope.
- **Three** **decided** Architect decisions (`DR-1`, `DR-2`, `M1b-DEC-3` = **D3-A**) with concrete, testable consequences.
- A **specified but unauthorized** sequencing dependency (`HARDEN-1`, §4).
- A **corrected** security posture: M1b's public behavior delta is now **exactly zero** (§19), which is stronger than the first draft's declared non-zero delta.
- **Zero** authorized rows, stated as a decided outcome rather than an open question.

### 3.4 What this document does **not** deliver

- No migration, SQL test or Dart test.
- No seed of any tier.
- No Frozen policy addendum.
- No amendment, relaxation or reinterpretation of §14.3, §14.4, `L-37` or §25.4.
- No authorization. `IMPLEMENTATION_AUTHORIZED = NO` (§27).

---

## 4. Sequencing dependency `HARDEN-1` — public catalog hardening / safe projection

`DR-2` requires a **separately authorized** step to exist before canonical plan identities may be seeded. This section specifies the dependency. It is **not** a proposal to implement it now, and it is **not** part of M1b.

### 4.1 Ordering invariant

```text
HARDEN-1 (separately authorized, landed and verified)
    MUST PRECEDE
canonical public.plans identity seed
    WHICH REQUIRES
commercial_private.plan_versions seed
    WHICH REQUIRES
commercial_private.term_prices seed
```

Before canonical `public.plans` identities may be seeded, `HARDEN-1` must be separately **contracted → accepted → implementation-authorized → implemented → landed → verified**. Completing that sequence does **not** automatically reopen M1b: a separate explicit Architect authorization naming the seed tier remains required (§27).

No canonical `public.plans` row may be created while raw public exposure exists. `M1a` cannot be re-run, re-scoped or reused to satisfy this: `fk_plan_versions_plan_id` is an accepted, correct M1a design property and `DR-2` explicitly forbids replacing the public anchor with a duplicate or private identity.

### 4.2 Required properties of `HARDEN-1`

| # | Requirement |
|---|---|
| H-1 | A **separate contract**, a **separate migration number** and a **separate explicit authorization**. It is not a prerequisite that M1b may satisfy itself. |
| H-2 | Removes or replaces the **raw, unfiltered `public.plans` exposure**: policy `plans_select_all` (`FOR SELECT TO PUBLIC USING (true)`) together with the `anon` / `authenticated` `SELECT` grants. |
| H-3 | Preserves Frozen §14.3 / §14.4 / `L-37` and §25.4 item 5 **verbatim**. `HARDEN-1` **hardens**; it never reinterprets or weakens them. |
| H-4 | If and when public catalog presentation is separately authorized, replaces raw table access with an **explicitly safe projection** — a bounded view or bounded RPC returning only currently published, marketable metadata (C3 §4; C3 §18 supports the bounded public-read/projection principle). Not a raw row proxy, not a full-row view. |
| H-5 | Creates **no** duplicate or private replacement plan identity; does not alter `fk_plan_versions_plan_id`. |
| H-6 | Independent security review of the resulting ACL/policy posture, plus explicit proof that no price, entitlement, window, publisher or plan-name field becomes readable. |
| H-7 | Leaves `commercial_private` posture untouched: still `RLS ENABLED`, zero policies, no client grants, no publication membership. |
| H-8 | Records its own rollback boundary. Revoking public `SELECT` from `public.plans` is **not** a destructive operation, but the decision must be recorded as an operator-visible change. |

### 4.3 Observed feasibility note (non-authorizing)

§5.4 establishes that **`public.plans` has zero Dart consumers**. Therefore `HARDEN-1` **option (a) — revoke-only** (drop `plans_select_all`, revoke `anon`/`authenticated` `SELECT`, and ship **no** projection yet) is a **pure hardening with no product or Flutter impact**, because nothing in the repository reads the table. This makes the sequencing dependency materially cheaper than a coupled UI change would be. It is an observation for planning only: `HARDEN-1` remains unauthorized, and the choice between option (a) and the projected option (b) of H-4 is the Architect's.

---

## 5. Independently re-inspected repository baseline (read-only)

Inspection was read-only at `4977a35d4f982fa75ec8c04eee606358dc9126ab`. `HEAD` and local `origin/main` match exactly. `origin/main` was **not** refreshed through a remote fetch and is a remote-tracking reference, not a deployed-state audit.

Protected pre-existing dirty baseline, unchanged by this pass:

```text
 M test/a5_6_profile_bootstrap_test.dart
 M test/v1_r08_cloud_profile_foundation_test.dart
 M test/v1_r08_profile_edit_screen_widget_test.dart
?? OpenCode_Usage_Report.txt
?? artifacts/
```

### 5.1 Migration inventory

Exactly **22** migration files, uniquely numbered `00001`–`00022`, no gaps and no duplicates. Highest is `00022_commercial_private_catalog_foundation.sql`. `00023` remains the actual next free number, but **it is not authorized** (§21).

`test/v1_r09q_migration_lint_test.dart` freezes `00001`–`00021` as an exact accepted baseline and asserts only that later prefixes are unique, strictly increasing and canonically named (`^\d{5}_[a-z0-9]+(?:_[a-z0-9]+)*\.sql$`). A future `00023_commercial_catalog_reference_data.sql` therefore requires **no edit** to that accepted test.

### 5.2 Actual M1a physical model — extracted from `00022`, not from summaries

`commercial_private.entitlement_bundles`

| Column | Type | Null | Default | Constraint |
|---|---|---|---|---|
| `id` | `uuid` | NOT NULL | `pg_catalog.gen_random_uuid()` | PK `entitlement_bundles_pkey` |
| `code` | `text` | NOT NULL | — | `chk_entitlement_bundles_code`: `char_length 1..64` AND `code ~ '^[a-z][a-z0-9_]*$'` (**dots are NOT permitted in a bundle code**) |
| `version` | `integer` | NOT NULL | — | `chk_entitlement_bundles_version`: `> 0`; `uq_entitlement_bundles_code_version` UNIQUE `(code, version)` |
| `registry_version` | `integer` | NOT NULL | — | `chk_entitlement_bundles_registry_version`: `> 0` |
| `status` | `text` | NOT NULL | `'draft'` | lifecycle CHECK (below) |
| `published_at` | `timestamptz` | NULL | — | lifecycle CHECK |
| `retired_at` | `timestamptz` | NULL | — | lifecycle CHECK |
| `created_at` | `timestamptz` | NOT NULL | `pg_catalog.now()` | — |

**No `plan_id` column and no foreign key of any kind.** This is the structural fact that separates SCOPE-B from SCOPE-A.

`commercial_private.bundle_items`

| Column | Type | Null | Default | Constraint |
|---|---|---|---|---|
| `id` | `uuid` | NOT NULL | `pg_catalog.gen_random_uuid()` | PK `bundle_items_pkey` |
| `bundle_version_id` | `uuid` | NOT NULL | — | FK `fk_bundle_items_bundle_version_id` → `entitlement_bundles(id)` `ON UPDATE RESTRICT ON DELETE RESTRICT`; `uq_bundle_items_bundle_key` UNIQUE `(bundle_version_id, capability_key)` |
| `capability_key` | `text` | NOT NULL | — | `chk_bundle_items_capability_key`: `char_length 1..128` AND `capability_key ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$'` (dot-separated lowercase segments) |
| `value_kind` | `text` | NOT NULL | — | `chk_bundle_items_typed_value` |
| `value_boolean` | `boolean` | NULL | — | exclusivity per `value_kind` |
| `value_integer` | `bigint` | NULL | — | `chk_bundle_items_integer_value`: `>= 0` when non-null |
| `value_text` | `text` | NULL | — | `chk_bundle_items_text_value`: trimmed non-empty, `<= 256` |
| `is_required` | `boolean` | NOT NULL | `true` | compatibility flag only; grants no right |
| `created_at` | `timestamptz` | NOT NULL | `pg_catalog.now()` | — |

`chk_bundle_items_typed_value` is an explicit three-alternative non-null-aware CHECK: `boolean` requires `value_boolean` non-null and both others null; `integer` requires `value_integer` non-null and both others null; `text` requires `value_text` non-null and both others null. Verified live as `(((value_kind = 'boolean') AND (value_boolean IS NOT NULL) AND (value_integer IS NULL) AND (value_text IS NULL)) OR ...)`.

`commercial_private.plan_versions`

| Column | Type | Null | Default | Constraint |
|---|---|---|---|---|
| `id` | `uuid` | NOT NULL | `pg_catalog.gen_random_uuid()` | PK `plan_versions_pkey` |
| `plan_id` | `uuid` | NOT NULL | — | FK `fk_plan_versions_plan_id` → `public.plans(id)` `ON UPDATE RESTRICT ON DELETE RESTRICT`; `uq_plan_versions_plan_version` UNIQUE `(plan_id, version)` |
| `version` | `integer` | NOT NULL | — | `chk_plan_versions_version`: `> 0` |
| `bundle_version_id` | `uuid` | NOT NULL | — | FK `fk_plan_versions_bundle_version_id` → `entitlement_bundles(id)` RESTRICT |
| `pricing_mode` | `text` | NOT NULL | — | `chk_plan_versions_pricing_mode`: IN `('retail','custom_quote')`; **no default** |
| `name_ar` | `text` | **NOT NULL** | — | `chk_plan_versions_metadata`: `btrim(name_ar) <> ''` |
| `description_ar` | `text` | NULL | — | same CHECK: NULL or trimmed non-empty |
| `sort_order` | `integer` | NOT NULL | `0` | `chk_plan_versions_sort_order`: `>= 0` |
| `status` / `published_at` / `retired_at` | `text` / `timestamptz` ×2 | see lifecycle | `'draft'` / NULL / NULL | `chk_plan_versions_lifecycle` |
| `effective_from` / `effective_until` | `timestamptz` | NULL ×2 | — | `chk_plan_versions_effective_window`: finite endpoints; an end requires a start and `> start`; `status <> 'draft'` requires a non-null start |
| `created_at` | `timestamptz` | NOT NULL | `pg_catalog.now()` | — |

`uq_plan_versions_id_pricing_mode` UNIQUE `(id, pricing_mode)` exists solely as the FK target for retail-mode term prices.

`commercial_private.term_prices`

| Column | Type | Null | Default | Constraint |
|---|---|---|---|---|
| `id` | `uuid` | NOT NULL | `pg_catalog.gen_random_uuid()` | PK `term_prices_pkey` |
| `plan_version_id` | `uuid` | NOT NULL | — | composite FK `(plan_version_id, pricing_mode)` → `plan_versions(id, pricing_mode)` RESTRICT |
| `pricing_mode` | `text` | NOT NULL | `'retail'` | `chk_term_prices_pricing_mode`: `= 'retail'` (composite FK additionally forbids a quote-mode price row) |
| `version` | `integer` | NOT NULL | — | `chk_term_prices_version`: `> 0`; `uq_term_prices_plan_duration_version` UNIQUE `(plan_version_id, duration_months, version)` |
| `duration_months` | `integer` | NOT NULL | — | `chk_term_prices_duration_months`: IN `(1, 3, 12)` — **no six-month offer is representable** |
| `amount_iqd` | `bigint` | NOT NULL | — | `chk_term_prices_amount_iqd`: `>= 0`; whole IQD units |
| `currency` | `text` | NOT NULL | `'IQD'` | `chk_term_prices_currency`: `= 'IQD'` |
| `status` / `published_at` / `retired_at` | see lifecycle | | `'draft'` / NULL / NULL | `chk_term_prices_lifecycle` |
| `effective_from` / `effective_until` | `timestamptz` | NULL ×2 | — | `chk_term_prices_effective_window` |
| `created_at` | `timestamptz` | NOT NULL | `pg_catalog.now()` | — |

Shared lifecycle CHECK (`draft` → neither marker; `published` → `published_at` and no retirement marker; `retired` → both, `retired_at >= published_at`; all non-null times finite). **A `draft` row may carry NULL `effective_from`.**

Verified live counts: 4 tables (`relkind='r'`), 9 constraint-backed indexes (`relkind='i'`), 34 constraints, `RLS ENABLED` on all four tables with **zero** policies, no `pg_proc` entries, no user triggers, no publication membership. `commercial_private` namespace ACL is `{postgres=UC/postgres}` — no non-owner grantee. All four tables hold **zero rows**. All four private tables and the schema are owned by `postgres`.

**No M1a defect was found.** The NOT NULL, non-empty-checked `name_ar` versus OPEN Arabic copy is an accepted M1a design property, now resolved by `DR-1` (§9) rather than silently compensated. M1b proposes **no** M1a schema change.

### 5.3 Actual `public.plans` definition and live local state

Verified by live local catalog inspection (read-only) against the accepted `00008` DDL:

| Property | Verified value |
|---|---|
| Columns | `id uuid` PK `DEFAULT gen_random_uuid()`; `code text NOT NULL`; `name text NOT NULL`; `description text` (nullable); `is_active boolean NOT NULL DEFAULT true`; `created_at timestamptz NOT NULL DEFAULT now()`; `updated_at timestamptz NOT NULL DEFAULT now()` |
| Constraints | `plans_pkey` PRIMARY KEY `(id)`; `plans_code_key` UNIQUE `(code)` — **code uniqueness is global and case-sensitive** |
| Trigger | `trigger_set_updated_at` BEFORE UPDATE only → an explicit INSERT value for `updated_at` is preserved; **no BEFORE INSERT trigger exists** |
| RLS | `relrowsecurity = true`, `relforcerowsecurity = false`, single policy `plans_select_all` FOR SELECT TO PUBLIC USING (`true`) — **completely unfiltered** |
| Grants | `anon` SELECT; `authenticated` SELECT; `service_role` SELECT/INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER; `postgres` full |
| **Live local rows** | **`SELECT count(*) FROM public.plans` = 0** |
| `public.subscriptions` rows | **0** |

`name text NOT NULL` is precisely the column `DR-2` protects: any seeded row publishes a plan name under an unfiltered `SELECT TO PUBLIC` policy. There is no write-only path, no per-role column policy and no row filter available without changing the policy.

**Local emptiness does not prove deployed emptiness.** `00008` deliberately performed no seeding. M1a §2 states that repository evidence is not a deployed-schema / production-data audit; M1a §10 preserves the existing `public.plans(id)` identity reference. Accepted C1 §21 / §22 `AR-13` require explicit reviewed existing-data disposition; `AR-04` leaves legacy subscription enum/state mapping deferred. §23 defines the mandatory pre-deployment inventory for the future cutover.

### 5.4 Known consumers of `public.plans`

- **Zero Dart consumers.** A repository-wide search found no `from('plans')`, no `plans` table read, and no gateway/repository access to `public.plans`. `lib/core/access/plan_type.dart` / `plan_tier.dart` are legacy enums (`free`, `pro_engineer`, `supplier`, `company`, `owner`, `admin`, `moderator`, `support`) with hardcoded client feature matrices; they do not read `public.plans` Frozen §3.5 preserves the engineering-authority/mapping trace. C3 §28 retains PlanType/PlanTier temporarily only as unrelated accepted local-access scaffolding and explicitly prohibits their use as authority for new commercial pricing, ownership/staff, entitlement or publication decisions.
- **Code-uniqueness collision check:** none of the legacy `PlanType` keys equals or collides with `business`, `business_pro`, `business_plus` or `corporate`. Note `company` ≠ `corporate`; M1b performs **no** enum mapping, rename or deprecation.
- **No public RPC, view or nested join** currently exposes plans other than the raw unfiltered table SELECT.

### 5.5 Drafting-time feasibility probe (non-authorizing, disclosed)

During the first draft, the complete 40-row seed was executed inside an explicit `BEGIN … ROLLBACK` transaction on the **local** development database. Result: `plans=4 bundles=4 items=19 versions=4 prices=9`, i.e. the designed seed satisfies every implemented M1a CHECK, UNIQUE and FK constraint. Post-rollback counts returned `plans=0 prices=0`. A separate rolled-back probe proved that once a `plan_version` references a plan, `DELETE FROM public.plans` fails with **SQLSTATE 23503** on `fk_plan_versions_plan_id`.

Disclosure and status: the probe **never committed**, ran only against the local development database, and left zero rows (verified twice). Because it temporarily materialized four inactive plan-identity rows inside an uncommitted local transaction, it is recorded here rather than omitted. **It is feasibility evidence only. It is not an acceptance gate, not an authorization, and it must not be repeated** while `DR-2` stands. The §22 gates remain undefined until a future authorized cutover specifies them.

### 5.6 Structural derivation of the `DR-2` cascade

The M1a FK graph, read directly from `00022`:

```text
public.plans
      ^
      | fk_plan_versions_plan_id  (ON UPDATE RESTRICT ON DELETE RESTRICT)
      |
commercial_private.plan_versions
      ^
      | fk_term_prices_plan_version_pricing_mode (composite, RESTRICT)
      |
commercial_private.term_prices

commercial_private.entitlement_bundles      <-- no FK to public.plans
      ^
      | fk_bundle_items_bundle_version_id
      |
commercial_private.bundle_items
```

Consequences, each independently verified against the DDL:

1. `plan_versions` is **impossible** without a `public.plans` row. `DR-2` withholds those rows ⇒ `plan_versions` is deferred. No alternative anchor exists, and `DR-2.4` forbids inventing one.
2. `term_prices` FKs `plan_versions` ⇒ deferred.
3. `entitlement_bundles` has **no** FK to `public.plans` ⇒ structurally independent; its design remains fully valid and is preserved.
4. `bundle_items` FKs only `entitlement_bundles` ⇒ structurally independent.
5. Therefore SCOPE-A = 17 rows is unconditionally blocked by `DR-2`, and SCOPE-B = 23 rows is structurally independent but is **deferred by decision** `M1b-DEC-3` = **D3-A** (§3.2), which deliberately declines standalone draft-only seeding. **D3-A is a policy choice, not a structural necessity** — the FK graph would have permitted SCOPE-B alone; the Architect chose not to, to keep one atomic cutover.

---

## 6. Canonical plan identities — frozen design, seed DEFERRED by `DR-2`

Frozen §3.1 approves exactly four ordinary commercial plan families: **Business**, **Business Pro**, **Business Plus**, **Corporate**. Frozen §3.5 and C3 §3 reserve their machine codes. Verified against C3 §3 and the repository namespace, the canonical stable codes are:

| # | Family | Canonical `code` | Evidence | M1b status |
|---|---|---|---|---|
| 1 | Business | `business` | C3 §3 reserved codes; frozen §3.1 | **DEFERRED** |
| 2 | Business Pro | `business_pro` | C3 §3 reserved codes; frozen §3.1, §3.3 | **DEFERRED** |
| 3 | Business Plus | `business_plus` | C3 §3 reserved codes; frozen §3.1 | **DEFERRED** |
| 4 | Corporate | `corporate` | C3 §3 reserved codes; frozen §3.1, §31.1 | **DEFERRED** |

These codes and UUIDs are **reserved**, not written. No additional base plan is invented. Explicitly **prohibited** as a `public.plans` identity:

| Prohibited identity | Reason |
|---|---|
| Founding Partner | Not a base plan. Annual **paid** discounted pricing eligibility/history (frozen §5.1–§5.7, C3 §6). |
| Launch Partner | Not a base plan. A temporary **60-calendar-day Business Pro promotional entitlement** (frozen §32.2 / `L-89`, C3 §7, `C3-AD-03`). |
| Sponsored | A **separate commercial product**, not a plan feature (frozen §6.1.1, C3 §3, §38). |
| Free / trial / lifetime-free tier | Prohibited by frozen §2.1.2, §25.4 item 24, `L-88`. |
| Legacy `free` / `pro_engineer` / `supplier` / `company` | Legacy Flutter scaffolding, **not** commercial catalog (frozen §3.5, §5.8; C1/C3). M1b neither creates nor maps them. |

C3 §3 is explicit: "None gets a base-plan UUID disguised as a fifth retail plan."

---

## 7. Stable UUID strategy — decision **B: fixed canonical UUID constants**

| Option | Evaluation |
|---|---|
| A. Random per environment | **Rejected.** Breaks cross-environment reproducibility, makes seed fingerprints environment-specific, and guarantees referential drift for future subscriptions/agreements/public projections. |
| B. **Fixed canonical constants committed in the migration** | **SELECTED.** Fully deterministic, referentially stable forever, verifiable by both static and runtime tests, requires no extension, and is greppable/auditable. |
| C. Deterministic derivation (`uuid_generate_v5`) | **Rejected.** `uuid-ossp` is not installed; introducing an extension solely to derive UUIDs is explicitly disallowed. `pgcrypto`/`pg_catalog` provide no version-5 derivation. |
| D. Other | Not applicable. |

All **40** canonical rows (4 plan identities + 4 bundles + 19 bundle items + 4 plan versions + 9 term prices) have **fixed explicit UUIDs** with a **valid RFC 4122 version-4 shape** (version nibble `4`, variant nibble `8`). Family/type identity is represented in the leading group/prefix; row uniqueness is carried by the explicit fixed UUID mapping in §7.1–§7.2. The trailing group is **not necessarily a varying row index**. Each was verified to parse as `uuid` in PostgreSQL 17 and to be **absent from the entire repository** (zero grep matches for every prefix family).

### 7.1 SCOPE-A — reserved, DEFERRED by `DR-2` (17 UUIDs)

| Record | Canonical UUID | Status |
|---|---|---|
| `public.plans` — `business` | `1a7b0001-0000-4000-8000-000000000001` | DEFERRED |
| `public.plans` — `business_pro` | `1a7b0002-0000-4000-8000-000000000002` | DEFERRED |
| `public.plans` — `business_plus` | `1a7b0003-0000-4000-8000-000000000003` | DEFERRED |
| `public.plans` — `corporate` | `1a7b0004-0000-4000-8000-000000000004` | DEFERRED |
| plan_version — `business` v1 | `4c7b0001-0000-4000-8000-000000000001` | DEFERRED |
| plan_version — `business_pro` v1 | `4c7b0002-0000-4000-8000-000000000002` | DEFERRED |
| plan_version — `business_plus` v1 | `4c7b0003-0000-4000-8000-000000000003` | DEFERRED |
| plan_version — `corporate` v1 | `4c7b0004-0000-4000-8000-000000000004` | DEFERRED |
| price — `business` 1 month | `5d7b0001-0000-4000-8000-000000000001` | DEFERRED |
| price — `business` 3 months | `5d7b0002-0000-4000-8000-000000000002` | DEFERRED |
| price — `business` 12 months | `5d7b0003-0000-4000-8000-000000000003` | DEFERRED |
| price — `business_pro` 1 month | `5d7b0004-0000-4000-8000-000000000004` | DEFERRED |
| price — `business_pro` 3 months | `5d7b0005-0000-4000-8000-000000000005` | DEFERRED |
| price — `business_pro` 12 months | `5d7b0006-0000-4000-8000-000000000006` | DEFERRED |
| price — `business_plus` 1 month | `5d7b0007-0000-4000-8000-000000000007` | DEFERRED |
| price — `business_plus` 3 months | `5d7b0008-0000-4000-8000-000000000008` | DEFERRED |
| price — `business_plus` 12 months | `5d7b0009-0000-4000-8000-000000000009` | DEFERRED |

These 17 UUIDs are **reserved and unpublished**. None may be reused for a different record family, and none may be reallocated to a private replacement identity (`DR-2.4`).

### 7.2 SCOPE-B — frozen design, DEFERRED by `DR-2` and `M1b-DEC-3` (D3-A) (23 UUIDs)

| Record | Canonical UUID | Status |
|---|---|---|
| bundle — `business_entitlements` | `2e7b0001-0000-4000-8000-000000000001` | DEFERRED |
| bundle — `business_pro_entitlements` | `2e7b0002-0000-4000-8000-000000000002` | DEFERRED |
| bundle — `business_plus_entitlements` | `2e7b0003-0000-4000-8000-000000000003` | DEFERRED |
| bundle — `corporate_entitlements` | `2e7b0004-0000-4000-8000-000000000004` | DEFERRED |
| item — `business_entitlements` / `branches.included` | `3a7b0001-0000-4000-8000-000000000001` | DEFERRED |
| item — `business_entitlements` / `team.active_member_max` | `3a7b0002-0000-4000-8000-000000000002` | DEFERRED |
| item — `business_entitlements` / `media.upload_enabled` | `3a7b0003-0000-4000-8000-000000000003` | DEFERRED |
| item — `business_entitlements` / `analytics.available` | `3a7b0004-0000-4000-8000-000000000004` | DEFERRED |
| item — `business_entitlements` / `sponsored.purchase_eligible` | `3a7b0005-0000-4000-8000-000000000005` | DEFERRED |
| item — `business_pro_entitlements` / `branches.included` | `3a7b0006-0000-4000-8000-000000000001` | DEFERRED |
| item — `business_pro_entitlements` / `team.active_member_max` | `3a7b0007-0000-4000-8000-000000000001` | DEFERRED |
| item — `business_pro_entitlements` / `media.upload_enabled` | `3a7b0008-0000-4000-8000-000000000001` | DEFERRED |
| item — `business_pro_entitlements` / `analytics.available` | `3a7b0009-0000-4000-8000-000000000001` | DEFERRED |
| item — `business_pro_entitlements` / `sponsored.purchase_eligible` | `3a7b0010-0000-4000-8000-000000000001` | DEFERRED |
| item — `business_plus_entitlements` / `branches.included` | `3a7b0011-0000-4000-8000-000000000001` | DEFERRED |
| item — `business_plus_entitlements` / `team.active_member_max` | `3a7b0012-0000-4000-8000-000000000001` | DEFERRED |
| item — `business_plus_entitlements` / `media.upload_enabled` | `3a7b0013-0000-4000-8000-000000000001` | DEFERRED |
| item — `business_plus_entitlements` / `analytics.available` | `3a7b0014-0000-4000-8000-000000000001` | DEFERRED |
| item — `business_plus_entitlements` / `sponsored.purchase_eligible` | `3a7b0015-0000-4000-8000-000000000001` | DEFERRED |
| item — `corporate_entitlements` / `branches.included` | `3a7b0016-0000-4000-8000-000000000001` | DEFERRED |
| item — `corporate_entitlements` / `team.active_member_max` | `3a7b0017-0000-4000-8000-000000000001` | DEFERRED |
| item — `corporate_entitlements` / `media.upload_enabled` | `3a7b0018-0000-4000-8000-000000000001` | DEFERRED |
| item — `corporate_entitlements` / `analytics.available` | `3a7b0019-0000-4000-8000-000000000001` | DEFERRED |

**Canonical reference timestamp** — `TIMESTAMPTZ '2026-01-01 00:00:00+00'`, to be written explicitly to `created_at` on every seeded row and to both `public.plans` timestamps when the future cutover is authorized. Verified necessity: omitting it produced an environment-dependent `now()` value, which destroys reproducible fingerprints. This constant is **documentary only** — never a payment, publication, entitlement, term or offer anchor (§15).

---

## 8. Public plan display values — REJECTED for M1b by `DR-2`

The first draft proposed seeding `public.plans` with `is_active = false`, `description = NULL` and code-only English family labels, declaring a bounded public delta. **`DR-2.3` rejects this outright**: a code-only or machine-token `name` is still a **publicly readable plan-name surrogate** under `plans_select_all`.

| `code` | `name` | `description` | `is_active` | Status |
|---|---|---|---|---|
| `business` | `Business` | `NULL` | `false` | **NOT SEEDED — `DR-2`** |
| `business_pro` | `Business Pro` | `NULL` | `false` | **NOT SEEDED — `DR-2`** |
| `business_plus` | `Business Plus` | `NULL` | `false` | **NOT SEEDED — `DR-2`** |
| `corporate` | `Corporate` | `NULL` | `false` | **NOT SEEDED — `DR-2`** |

The table is retained **only** as the frozen design input for the future post-`HARDEN-1` cutover. It must not be read as an approved seed specification.

Standing observations, unchanged:

- `public.plans` is **not** the Arabic commercial marketing-copy SSOT. Arabic customer-facing commercial strings must enter the future authorized Arabic-first localization/copy SSOT (`D-27`, §28.14). Repository evidence: `flutter_localizations` **is declared as an SDK dependency** in `pubspec.yaml`; no `.arb` files, l10n directory, `l10n.yaml`, `generate: true` localization pipeline or direct `intl` dependency is configured. `lib/app.dart` wires the SDK's `GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations` and `GlobalCupertinoLocalizations` framework delegates; these are not an authorized commercial-copy SSOT. No generated commercial-copy localization delegates or SSOT pipeline are wired. Existing application localization does not supply approved final Arabic commercial copy. M1b invents **no** Arabic commercial copy, and `DR-1`'s `__AR_LOCALIZATION_PENDING__` remains a private draft-only sentinel.
- Final Arabic plan naming, badge wording and placement remain `OQ-14` / `P-12` / `D-27` and are untouched.

---

## 9. `DR-1` resolution — `name_ar` localization sentinel

### 9.1 The constraint

`chk_plan_versions_metadata` requires `name_ar` to be `NOT NULL` and trimmed-non-empty. Frozen policy supplies **no** approved Arabic plan label (`D-27`; `OQ-14` "final Arabic copy" OPEN; `OQ-69` `LEGAL/POLICY REVIEW`; §28.14 makes Arabic the controlling **customer-facing** language).

### 9.2 The decided sentinel

Per `DR-1`, `name_ar` takes a **private, draft-only localization sentinel**. The exact frozen value is:

```text
__AR_LOCALIZATION_PENDING__
```

The same uniform sentinel applies to all four plan versions. Properties that make a uniform sentinel the correct choice over a per-plan token:

| Property | Why it matters |
|---|---|
| Satisfies `btrim(name_ar) <> ''` | Valid M1a row; no schema change needed |
| Not Arabic, not marketing copy | Cannot be mistaken for approved localized content; no Arabic invented |
| Not a plan name or surrogate | Complies with the `DR-2.3` reasoning applied consistently to the private tier |
| Uniform across all four rows | Fail-closed detection is a single equality test: `name_ar = '__AR_LOCALIZATION_PENDING__'` |
| Greppable and self-describing | An operator or auditor can locate every placeholder row with one search |
| Unambiguously non-public | Never reaches catalog, API or UI (§9.3) |

`description_ar` is **`NULL`**.

### 9.3 Mandatory invariants — `M1b-AR-1` … `M1b-AR-6`

| ID | Invariant |
|---|---|
| `M1b-AR-1` | All sentinel-bearing `plan_versions` rows are **`draft`**. `published_at` and `retired_at` are NULL. |
| `M1b-AR-2` | **Fail closed on publication/activation.** No `status = 'published'` transition is permitted for any row whose `name_ar = '__AR_LOCALIZATION_PENDING__'`. Today this holds **by absence** — M1a implements no activation writer, publication gate or lifecycle function, so there is no code path that can violate it. The later authorized catalog publisher (M1a §14, C3 §4) **must** enforce it explicitly as a precondition. |
| `M1b-AR-3` | The sentinel is **private commercial metadata only**. It is never returned by any public catalog projection, bounded RPC, Data API response, DTO, view or Flutter renderer. Enforced structurally: `commercial_private` is outside `api.schemas`, outside `extra_search_path` and ACL-denied to `anon`, `authenticated` and `service_role`. |
| `M1b-AR-4` | Replacement must come **only** from the authorized Arabic localization/copy SSOT. M1b and any future migration may not substitute a hand-written Arabic string. |
| `M1b-AR-5` | `name_ar` is **not** the canonical machine identity; `code` and the bundle rows are. The sentinel therefore never becomes an identifier, sort key or join value. |
| `M1b-AR-6` | `description_ar` remains `NULL`. No partial Arabic copy is introduced anywhere in the private catalog. |

### 9.4 What `DR-1` explicitly does **not** do

- It does **not** close `OQ-14`, `P-12`, `P-35`, `D-27` or `OQ-69`. All remain OPEN/PROVISIONAL exactly as registered (§25).
- It does **not** authorize `plan_versions` seeding. `DR-1.8` keeps `plan_versions` and `term_prices` **in M1b scope**; they are withheld solely by `DR-2` (§5.6).
- It does **not** constitute a localization SSOT, a content-governance decision or a precedent for other untranslated fields.
- It does **not** create any Arabic marketing copy.

---

## 10. Entitlement bundles — SCOPE-B evidence matrix (LOCKED policy only)

Extracted from the Frozen Commercial Model. **No PROVISIONAL or OPEN value is seeded.**

| Policy fact | Frozen section / LOCK ID | Entitlement key | Value type | Business | Pro | Plus | Corporate | Design? | Reason |
|---|---|---|---|---|---|---|---|---|---|
| Included branches 1 / 2 / 3; Corporate per-quotation | §4.1; `L-84` for Corporate | `branches.included` | `integer` | `1` | `2` | `3` | `3` | DESIGNED (deferred) | §4.1 rows are `LOCKED`. Corporate takes the §31.1.2 `LOCKED` Business Plus floor (`3`). No numeric Corporate branch count is invented (`P-02` stays PROVISIONAL). |
| Ordinary team ceiling 5 active members | §28.11.1 (`L-81`); §28.11.2; §31.1.4 | `team.active_member_max` | `integer` | `5` | `5` | `5` | `5` | DESIGNED (deferred) | `LOCKED` for ordinary plans; Corporate inherits the §31.1.2 Plus floor. Frozen §28.11.2 and §31.1.4 establish custom Corporate team capacity as a `LOCKED` commercial variable; the exact/custom mechanism remains deferred under `D-29`. |
| Sponsored purchasable initially by Pro/Plus | §6.1.8; `L-73` (A5-12) | `sponsored.purchase_eligible` | `boolean` | `false` | `true` | `true` | **key absent** | DESIGNED (deferred) | Pro/Plus `true` and Business `false` are the direct complement of the `LOCKED` Pro/Plus rule. §6.1.8 does **not** name Corporate, so **no value is invented**: the key is omitted and absence denies the dependent capability (M1a §11). Corporate Sponsored eligibility belongs to approved Corporate terms (C3 §38) and the deferred Sponsored product (`D-14`, `D-15`). |
| Owners can upload their own media | §16 | `media.upload_enabled` | `boolean` | `true` | `true` | `true` | `true` | DESIGNED (deferred) | Capability is `LOCKED` and not plan-differentiated. **No quota/count is designed** — §16.1 counts 6/20/40 are `PROVISIONAL` (`P-14`) and `OQ-16` is OPEN. |
| Entry paid plan must have basic value evidence; analytics never describe sales | §17.1; §28.7 (`L-77`) | `analytics.available` | `boolean` | `true` | `true` | `true` | `true` | DESIGNED (deferred) | Availability is `LOCKED`; the specific metric set is `PROVISIONAL` (`P-15`, `P-16`) and retention/access is `OQ-17` (OPEN). **No metric is enumerated and no retention is asserted.** |

The `Design?` column records **policy fidelity of the design**, not seeding authorization. **All five rows and all 19 bundle items are DEFERRED** under `DR-2.6` and `M1b-DEC-3` = **D3-A** (§3.1, §3.2). Nothing in this matrix is written, and `D3-A` explicitly authorizes no partial materialization.

**Deliberately excluded — OPEN / PROVISIONAL / deferred:**

| Excluded | Status | Owner of the decision |
|---|---|---|
| Media counts 6 / 20 / 40, storage/size/type limits, per-category media limits | `PROVISIONAL` `P-14`; OPEN `OQ-16` | Entitlement review (`P-03`, `D-25`) |
| Analytics metric set, retention, aggregation, counting rules, export, post-expiry visibility | `PROVISIONAL` `P-15`/`P-16`; OPEN `OQ-17` | Analytics contract |
| Extra-Branch pricing, 3-month extra-branch price, branch cap | `PROVISIONAL` `P-01`; OPEN `OQ-03` | Add-on/branch contract |
| Corporate negotiated extras (branch scale, team capacity, support level, managed service, media/content scale, reporting) | `LOCKED` as **variables** only (`L-84`); technical storage `DEFERRED` (`P-03`, `P-25`, `OQ-77`, `D-29`) | Corporate quotation domain (C3 §37) |
| Grace-period management access | `PROVISIONAL` `P-05`; OPEN `OQ-12` | Later contract |
| Published Required Fields Gate per-category matrix | `OQ-76` = **OPEN**; Frozen §28.6.4 = **PROVISIONAL** | C2 §7 preserves the Required Fields Gate, **not an arbitrary public numerical score**, and explicitly defers the exact applicable matrix/validation and Business Center experience to `OQ-76` and the future authorized domain contracts. |
| Founding Partner badge/status and promotional eligibility | `PROVISIONAL` `P-12`; OPEN `OQ-14`, `OQ-02` | Founding domain (C3 §6) |
| Launch Partner / A8 promotional grant | OPEN `OQ-80`–`OQ-83` | Promotional grant domain (C3 §7) |
| Verification/ownership/RBAC capability mapping | `DEFERRED` `P-25`, `D-28` | Ownership/RBAC contract |

### 10.1 Bundle identity rows — design frozen, seeding DEFERRED (D3-A)

| Bundle `code` | `version` | `registry_version` | Binds to | Items |
|---|---|---|---|---|
| `business_entitlements` | `1` | `1` | Business v1 | 5 |
| `business_pro_entitlements` | `1` | `1` | Business Pro v1 | 5 |
| `business_plus_entitlements` | `1` | `1` | Business Plus v1 | 5 |
| `corporate_entitlements` | `1` | `1` | Corporate v1 | 4 |

Bundle codes must satisfy `^[a-z][a-z0-9_]*$` (**no dots permitted**), hence underscores. `corporate_entitlements` is byte-for-byte the Business Plus entitlement set minus `sponsored.purchase_eligible`; it carries no "plus"-suffixed alias, so there is exactly one concept per plan family and no duplicate concept under a second name.

**Total designed rows: 4 plans + 4 bundles + 19 bundle items + 4 plan versions + 9 term prices = 40, of which 0 are authorized to be written by this document.**

---

## 11. Entitlement key registry boundary

M1a stores typed capability keys but implements no evaluator registry. M1b defines the **exact approved initial key set — five keys, and no others**:

| Key | Kind | Stable meaning | Namespace check |
|---|---|---|---|
| `branches.included` | `integer` | Number of Branch locations included by the plan (§4.1). Not an add-on price and not a maximum. | `^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$` ✔ |
| `team.active_member_max` | `integer` | Maximum active team members (§28.11.1). Not a pricing lever. | ✔ |
| `media.upload_enabled` | `boolean` | Whether plan members may upload their own media (§16). Carries **no** quota. | ✔ |
| `analytics.available` | `boolean` | Whether analytics capability is available to the Business (§17.1). Carries **no** metric, retention or access rule. | ✔ |
| `sponsored.purchase_eligible` | `boolean` | Whether the plan family satisfies the initial Sponsored purchase prerequisite (§6.1.8, C3 §38). It is a **prerequisite result, not a campaign, reservation, grant or placement**. | ✔ |

Rules satisfied:

- Lowercase dot-separated, each segment matching M1a's validated pattern; total length ≤ 128.
- No UI-copy string used as a key. No sentinel value encoded in a key.
- No duplicate concept under different names.
- No OPEN-policy semantics, no "unlimited", no nullable-quota encoding.
- `is_required = true` on every designed item (uniform fail-closed compatibility flag; grants nothing).
- M1a §11 semantics preserved: an unknown **required** key denies the dependent capability; optional unknown data may never create a right; stored rows alone create no effective entitlement.

If a frozen distinction cannot yet be represented safely because its semantics belong to a later contract, **no key is invented for it** — absence in a bundle is the fail-closed representation, exactly as used for Corporate Sponsored eligibility.

---

## 12. Corporate bundle treatment

| Rule | Frozen evidence | M1b treatment |
|---|---|---|
| Custom Quote pricing | §31.1.1, §31.1.6 (`L-84`) | `pricing_mode = 'custom_quote'`; **zero** `term_prices` rows (the composite FK and `chk_term_prices_pricing_mode = 'retail'` make a Corporate retail row structurally impossible) |
| Minimum 12-month commitment | §31.1.5 | **Not seeded.** No `term_prices` row exists; the minimum belongs to the future `corporate_quotes` domain (C3 §37), not to reference data. |
| Business Plus entitlement floor | §31.1.2 | `corporate_entitlements` = exactly the Plus floor: `branches.included = 3`, `team.active_member_max = 5`, `media.upload_enabled = true`, `analytics.available = true` |
| May extend by negotiation | §31.1.3, §31.1.4 | **Nothing seeded** for the extension. No unlimited value, no custom override, no provisional extra-branch price, no custom team count. Future negotiated deltas live in versioned quotations (C3 §37) |
| Sponsored eligibility | §6.1.8 does not name Corporate; C3 §38 defers to approved Corporate terms | Key **omitted** → denies by absence; no decision invented |
| 30-day quotation validity | §31.1.7 | **Not seeded** — quotation domain |
| Corporate numeric branch count | `P-02` still PROVISIONAL | **Not seeded**; the floor value `3` is the inherited Plus value, not a Corporate decision |

Future Corporate quotation authority must treat `branches.included = 3` and `team.active_member_max = 5` as Business Plus **floors**, not Corporate caps, and express approved negotiated deltas separately. No custom values are chosen here.

---

## 13. Founding Partner — excluded from standard pricing

Frozen §5.7 `LOCKED` first-year values, preserved here verbatim for traceability: **Business 150,000 / Pro 300,000 / Plus 525,000 IQD**; derived −25 % is explicitly **not** a stated policy.

**Decision: DO NOT seed these into `commercial_private.term_prices`.**

Structural justification: `uq_term_prices_plan_duration_version` is UNIQUE `(plan_version_id, duration_months, version)`. Founding Partner pricing is **annual** (12 months), so a Founding row for the same plan version and duration would collide with the standard 12-month retail row. Founding pricing is also explicitly not standard retail: C3 §6 treats it as paid discounted **eligibility** with its own offer snapshot; M1a §12 states that "Founding adjustments, A8 promotional grants, Sponsored, add-ons and payment allocations are **not** encoded as term-price rows by M1a".

**Owning later domain:** the Founding Partner eligibility + discounted-offer snapshot records (`founding_eligibility` and the agreed order/term snapshot) per C3 §6, owned by the M4/M5-reviewed family. Also unresolved there: `OQ-01` (1/3-month first-term prices), `OQ-02` (first-50 counter/evidence), `OQ-14`/`P-12` (badge visibility/copy), `P-22`, and `D-18` (no later cohort).

Founding Partner is **not** a base plan, **not** Launch Partner (`L-89`, frozen §5.1a), **not** Sponsored, and **not** ordinary standard retail pricing.

---

## 14. Standard retail price data — SCOPE-A design, DEFERRED by `DR-2`

Verified row-by-row against frozen §3.2 (`LOCKED`) and C3 §4. Frozen §3.1 `LOCKED` durations: `1 month`, `3 months`, `12 months`.

| # | `code` | `duration_months` | `amount_iqd` | `currency` | `plan_version_id` | Status |
|---|---|---|---|---|---|---|
| 1 | `business` | `1` | `20000` | `IQD` | `4c7b0001-…-000000000001` | DEFERRED |
| 2 | `business` | `3` | `55000` | `IQD` | `4c7b0001-…-000000000001` | DEFERRED |
| 3 | `business` | `12` | `200000` | `IQD` | `4c7b0001-…-000000000001` | DEFERRED |
| 4 | `business_pro` | `1` | `40000` | `IQD` | `4c7b0002-…-000000000002` | DEFERRED |
| 5 | `business_pro` | `3` | `110000` | `IQD` | `4c7b0002-…-000000000002` | DEFERRED |
| 6 | `business_pro` | `12` | `400000` | `IQD` | `4c7b0002-…-000000000002` | DEFERRED |
| 7 | `business_plus` | `1` | `70000` | `IQD` | `4c7b0003-…-000000000003` | DEFERRED |
| 8 | `business_plus` | `3` | `190000` | `IQD` | `4c7b0003-…-000000000003` | DEFERRED |
| 9 | `business_plus` | `12` | `700000` | `IQD` | `4c7b0003-…-000000000003` | DEFERRED |
| — | `corporate` | — | — | — | **no retail price row** (Custom Quote) | — |

Assertions that hold by design and by the future gate:

- **Exactly nine** standard retail price rows.
- **No six-month term** exists — `chk_term_prices_duration_months` is IN `(1, 3, 12)`.
- **No Corporate retail price** exists and none is representable.
- All amounts are non-negative whole IQD units; `currency = 'IQD'` enforced.
- No discount, add-on, promotional, instalment, Founding, Launch, Sponsored, grace, tax, VAT, invoice or payment value is seeded. The derived §3.4 arithmetic and `OQ-42` remain untouched.

---

## 15. Version numbering and effective-time anchor

Applies to whichever tier a future authorization covers.

| Field | Value | Rationale |
|---|---|---|
| `entitlement_bundles.version` | `1` for all four bundles | Minimal value; `uq_entitlement_bundles_code_version` scoped per code |
| `entitlement_bundles.registry_version` | `1` for all four bundles | `CHECK > 0` is mandatory. It declares **the approved capability-registry generation of these five keys** (§11), not that any evaluator exists. M1a §11 requires future evaluators to match key/type/registry version and to deny unknown versions. |
| `plan_versions.version` | `1` | §7.1 / §9 |
| `term_prices.version` | `1` | §14 |
| `status` | `draft` everywhere | M1a lifecycle CHECK; also mandated by `DR-1.2` |
| `published_at` / `retired_at` | `NULL` everywhere | Lifecycle coherence |
| `effective_from` / `effective_until` | **`NULL` / `NULL`** everywhere | A `NULL` start is permitted for `draft` rows and avoids asserting a commercial effective instant. `NULL` end means **no catalog end is scheduled** — never an unlimited commercial entitlement (M1a §9). |
| `created_at` | `2026-01-01 00:00:00+00` everywhere | §7; deterministic across environments |

No `now()` is used in the seed. No commercial term-start, activation, renewal or publication semantics is invented here; the accepted anchors belong to C3 §12 and the later term/agreement family.

### 15.1 Sort / recommendation metadata

| Question | Answer |
|---|---|
| Does the implemented schema have a field capable of representing commercial ordering? | **Yes** — `plan_versions.sort_order integer NOT NULL DEFAULT 0 CHECK (>= 0)` |
| Design value | Frozen §3.1 lineup order: Business `1`, Business Pro `2`, Business Plus `3`, Corporate `4` |
| Is `sort_order` recommendation metadata? | **No.** M1a §10 defines it as "Non-negative commercial display order, **not** entitlement precedence" |
| Does any schema field represent "Business Pro is the default recommendation"? | **No.** Frozen §3.3 `LOCKED` that Business Pro is the intended primary/default recommendation, but **how, where and in what wording it is surfaced is `PROVISIONAL`** |
| M1b treatment | Populate lineup `sort_order` only. Add **no** schema column. Encode recommendation by **no** mechanism — not by abusing `sort_order`, `registry_version`, `is_required`, `name_ar`, `is_active` or the `DR-1` sentinel. Surfacing the recommendation is a later authorized consumer decision |

### 15.2 Term-price versioning (deferred)

| Property | Decision |
|---|---|
| Initial `term_prices.version` | `1` for all nine rows (`CHECK > 0`; UNIQUE `(plan_version_id, duration_months, version)`) |
| Uniqueness | `(plan_version_id, duration_months, version)` — one approved amount per plan version, duration and version |
| Future price change | **Append a new row with `version = 2`** and a new effective window. **Never** mutate or delete a version-1 row. C3 §4/§5 and frozen §26.3 (`L-58`): a price change never revalues an already-paid unexpired term |
| Retirement | Retiring a version stops **new offers**; it never rewrites purchased price or benefit history |
| Overlap | Only `draft` rows are designed, so no published-offer overlap is created. The overlapping-published-offer prohibition remains a prerequisite of the later authorized catalog writer (M1a §14, C3 §4) |
| Purchased terms | **Zero**. No order, agreement, term, payment or allocation exists |

---

## 16. Existing-row conflict policy — frozen for the future cutover

**M1b performs no writes, so no precondition or reconciliation runs today.** This policy is frozen now so the later authorized cutover inherits an unambiguous, fail-closed strategy.

That future migration **must not** perform `INSERT … ON CONFLICT DO UPDATE` over unknown deployed commercial data, and must not delete, rename, deactivate or rewrite any pre-existing row. The strategy is a **precondition assertion before any write**, followed by idempotent inserts, followed by an exact post-condition assertion.

### 16.1 Case classification

| Case | Deployed state | Classification | Required behaviour |
|---|---|---|---|
| **A** | Canonical `code` absent **and** canonical UUID absent **and** no case-insensitive near-collision | **SAFE INSERT** | Insert the canonical row exactly as specified in §7/§8. |
| **B** | Canonical `code` present **with exactly the canonical UUID** | **SAFE ACCEPT (idempotent)** | Perform **no** data modification. The row is already identity-compatible. Do not touch `name`, `description`, `is_active` or timestamps. |
| **C** | Canonical `code` present with a **different UUID** | **STOP** | `RAISE EXCEPTION`. Never rewrite the UUID — it may be referenced by `public.subscriptions` or unknown production data. Requires explicit migration review. |
| **D** | Canonical UUID present with a **different `code`** | **STOP** | `RAISE EXCEPTION`. Never rename. |
| **C′** | Any row whose `lower(btrim(code))` equals a canonical code but whose exact `code` differs (e.g. `Business`, `BUSINESS_PRO`, `business-pro`) | **STOP (near-collision)** | `RAISE EXCEPTION`. Never normalize, merge or rename. |
| **E** | Canonical row present with the canonical UUID but `name`, `description`, `is_active` **or `created_at`/`updated_at`** differs from §8 | **STOP** | `RAISE EXCEPTION`. A deployed `is_active = true` row must **never** be silently disabled — and a canonical row is never silently enabled. Divergence is an explicit deployment decision requiring review. |
| **F** | Unrelated/legacy plan rows exist (no canonical code, no canonical UUID, no near-collision) | **DEFER** | Leave completely untouched: no delete, rename, deactivation, merge or annotation. Record the presence as an operator-visible fact and route the disposition to the C3 §33 / M4 reviewed reconciliation family. Case F alone must **not** abort the migration. |
| **G** | A canonical identity already has `commercial_private.plan_versions` rows referencing a **different** plan UUID | **STOP** | Caught by cases C/D; additionally asserted in the final assertions. |

### 16.2 Idempotency rule

Private-table inserts use `ON CONFLICT DO NOTHING` **without a conflict target**. This is safe **only because** the §16.1 preconditions have already excluded every conflict case; it exists purely so an accidental re-run is a no-op. `ON CONFLICT … DO UPDATE` is prohibited. The public `plans` insert uses the same guarded form, with the precondition block running **before** it.

### 16.3 No duplicate identity

`public.plans.code` is globally UNIQUE and `id` is the PK, so one canonical code can map to at most one row and one canonical UUID to at most one row. M1b never creates a second identity for the same family, never renames a legacy row into a canonical code, and never adds a plan code, column, table or enum. `DR-2.4` reinforces this: **no duplicate or private replacement identity may be introduced to bypass the FK architecture.**

---

## 17. Zero entitlement effect

| Guarantee | Mechanism |
|---|---|
| No rows written at all | M1b is **documentary only**; no migration exists and no insert is authorized |
| No subscription | Zero `INSERT`/`UPDATE` on `public.subscriptions`; currently 0 rows |
| No purchased term | No order/agreement/term/payment/allocation table is created or written |
| No promotional grant | No `promotional_grants`/`program_versions` structure; no A8 or Founding value is seeded |
| No publication authority | No publication authority table, gate, snapshot or event; all designed rows are `draft` |
| No Verified status | No `directory_entities` row is touched |
| No Sponsored grant | Only a designed prerequisite boolean; §6.1.1 keeps Sponsored a separate product; `D-14` remains deferred |
| No Branch right | `branches.included` is designed reference data with no evaluator; no location/branch row is created |
| No entity-to-plan assignment | **Zero**. No mapping of any `directory_entities.id` to any plan |
| No runtime consumption | No evaluator, no RPC, no view, no Flutter consumer exists |
| `DR-2` compliance | No plan identity is published; the §14.3 / `L-37` prohibition is preserved rather than reinterpreted |

---

## 18. No runtime catalog API

M1b **must not**: expose `commercial_private` to the Data API; create a public catalog RPC, view, materialized projection or function; create a Flutter consumer or any production Dart file; create a Business Center or Admin Console surface; add routes, providers, DI wiring or navigation; create an entitlement evaluator or registry implementation; create a publication evaluator or authority; create a scheduler, worker, outbox, cron or webhook; create or grant any client capability; change `supabase/config.toml`, `api.schemas`, `extra_search_path`, Realtime publications or `supabase/seed.sql`.

This slice is **design documentation only**.

---

## 19. Public behavior delta — **EXACTLY ZERO**

Under `DR-2`, the first draft's declared non-zero public delta is withdrawn. M1b now matches M1a's posture exactly.

| Surface | Delta |
|---|---|
| `GET /rest/v1/plans` result set | **ZERO.** Unchanged: 0 rows locally. No row is created, modified or removed |
| `public.plans` row count | **ZERO.** Unchanged |
| `public.subscriptions` | **ZERO** |
| `commercial_private` row counts | **ZERO** — all four tables remain empty |
| New tables, columns, RPCs, views, routes, enums, policies, grants | **ZERO** |
| Data API schema set, `extra_search_path`, Realtime | **ZERO** |
| RLS / policies / triggers / functions / extensions / roles | **ZERO** |
| `supabase/config.toml`, `supabase/seed.sql` | **ZERO** |

### 19.1 `DR-2` compliance assertions

| # | Assertion | Status |
|---|---|---|
| 1 | No observable public plan-name exposure is accepted | **SATISFIED** — nothing is seeded |
| 2 | No Frozen policy addendum is created by M1b | **SATISFIED** — Frozen §14.3/§14.4/`L-37`/§25.4 unmodified |
| 3 | `public.plans.name` is not populated with code-only or machine-token surrogates | **SATISFIED** — rejected by `DR-2.3`, no workaround adopted |
| 4 | No duplicate/private replacement plan identity created | **SATISFIED** — §16.3 |
| 5 | M1b does not pretend the conflict is solved | **SATISFIED** — conflict recorded as `HARDEN-1`, scope honestly deferred (§3) |
| 6 | M1b does not silently become implementation-authorized | **SATISFIED** — `IMPLEMENTATION_AUTHORIZED = NO` (§27) |
| 7 | Sequencing dependency explicitly recorded | **SATISFIED** — §4 |
| 8 | Bundles designed but not activated as commercial authority, and not partially materialized | **SATISFIED** — §10 design only; `M1b-DEC-3` = **D3-A** (§3.2) defers SCOPE-B entirely with SCOPE-A |
| 9 | `D3-A` recorded with its five-point rationale, and `D3-B` carries no authority | **SATISFIED** — §3.2 |

---

## 20. Security

| Control | Requirement |
|---|---|
| `commercial_private` Data API exposure | Remains absent from `api.schemas` (`["public","graphql_public"]`), from `extra_search_path` (`["public","extensions"]`) and from every active PostgREST exposed-schema set. Config files unchanged |
| Client grants | No grant to `PUBLIC`, `anon`, `authenticated` or `service_role` on any private table; schema `USAGE`/`CREATE` denied; no new role, membership or capability |
| RLS | All four tables remain `RLS ENABLED` with **zero** policies. M1b creates **no** policy |
| New routines | **Zero**. No `SECURITY DEFINER` is required or created — nothing in M1b needs a runtime function, so MED-2 is satisfied by absence |
| Default ACLs | M1a's verified creator-level hardening is **not** re-run, altered or rolled back. No `ALTER DEFAULT PRIVILEGES` |
| Config | `supabase/config.toml`, `supabase/seed.sql`, Realtime publication membership, `max_rows`, Auth and the single production Supabase authority: untouched |
| `service_role` | Never in Flutter, never in a migration, never in a client path. Its existing `public.plans` grants are pre-existing state, not an M1b change |
| Authority | Reference-data insertion is **not** application authorization and grants no runtime capability |
| Cloud/production | No production or cloud action is taken during contract drafting; none is authorized here |
| Search path | Fully qualified `pg_catalog`/`commercial_private`/`public` references throughout; `commercial_private, pg_temp` ordering requirement is not triggered because no function is created |
| `DR-1` sentinel exposure | `M1b-AR-3`: unreachable through any public surface by structure, not by convention |
| `DR-2` raw exposure | Not weakened, not reinterpreted, and not used as a justification for seeding. Hardening is deferred to `HARDEN-1` (§4) under a separate contract and authorization |
| Drafting-time disclosure | §5.5 records the rolled-back local feasibility probe, which never committed and left zero rows |

---

## 21. Migration and test allowlist — nothing authorized

**Present drafting allowlist — one new file only (this document):**

```text
docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_M1B_CATALOG_REFERENCE_DATA_IMPLEMENTATION_CONTRACT_V1.md
```

**Maximum proposed future allowlist — three new files only, requiring a separate explicit authorization that does not exist:**

| Exact future path | Purpose | Prerequisite |
|---|---|---|
| `supabase/migrations/00023_commercial_catalog_reference_data.sql` | Single additive reference-data migration with fail-closed pre/post assertions | `HARDEN-1` landed and verified (§4) |
| `supabase/tests/commercial_m1b_catalog_reference_data_test.sql` | Focused transactional pgTAP runtime evidence | migration authorized |
| `test/commercial_m1b_catalog_reference_data_migration_test.dart` | Focused independent source/inventory/exclusion assertions | migration authorized |

These three would be **sufficient**: `test/v1_r09q_migration_lint_test.dart` accepts `00023` without modification (§5.1), and no existing migration, test, gate, CI or config file requires editing. **No production Flutter file. No wildcard scope.** Any additional file, harness, role, function, trigger, API test file, CI change or migration renumber requires Architect reauthorization.

**`00023` is not reserved. It is not claimed. It may be consumed by unrelated work**, in which case the implementing pass must STOP, report the actual next free number and obtain Architect reauthorization.

---

## 22. Test gates — deferred to the future authorized contracts

No gate is defined for this pass, because M1b authorizes no artifact. The following are the **requirements** a future cutover contract must re-state and satisfy; they are recorded here so the design is auditable and nothing is silently dropped.

### 22.1 Runtime SQL gate (future)

Environment: PostgreSQL 17 in an explicitly verified **disposable local** Supabase database. Tests use `BEGIN`, pgTAP assertions, `SET LOCAL ROLE`, controlled synthetic JWT identities, `RESET ROLE`, `finish()` and a final `ROLLBACK`, matching the existing M1a smoke convention. Transaction control belongs **only** in test files.

| Family | Required assertions |
|---|---|
| **PLAN IDENTITY** | Exactly four canonical identity rows; exact codes and exact canonical UUIDs from §7.1; `description IS NULL`; `is_active = false`; fixed timestamps; **case A** (absent → inserted), **case B** (exact row → accepted, no mutation), **cases C, D, C′, E, G** each **fail closed** with a raised exception; **case F** leaves unrelated legacy rows byte-identical and does not abort |
| **PRIVATE VERSION DATA** | Exactly 4 bundles / 19 items / 4 plan versions / 9 prices; each plan version links the correct `plan_id`, `bundle_version_id`, `pricing_mode`, `sort_order`; every row `status = 'draft'`; all lifecycle/effective markers NULL; exact key/value/kind matrix per bundle including the Corporate `sponsored.purchase_eligible` **absence**; `registry_version = 1` |
| **`DR-1` SENTINEL** | Every seeded `plan_version` has `name_ar = '__AR_LOCALIZATION_PENDING__'`; every such row is `draft` with NULL publication markers; `description_ar IS NULL`; no test fixture or RPC may return the sentinel to a client role; an attempted `published` transition is rejected (`M1b-AR-2`) |
| **PRICE MATRIX** | Exactly nine retail rows; exact IQD amounts per §14; exact durations `1/3/12`; `pricing_mode = 'retail'`; Corporate has zero price rows; six-month insert rejected by `chk_term_prices_duration_months`; Founding amounts absent; quote-mode price insert rejected by the composite FK |
| **EXCLUSIONS** | No Founding, Launch Partner or Sponsored plan row or bundle code; no base plan beyond the four; no media-count or analytics-retention key; no branch-cap or extra-branch-price key; zero rows written to `public.subscriptions`; zero entity-to-plan assignment |
| **SECURITY** | As `anon` and `authenticated` (ordinary, business and staff JWT shapes) private SELECT/INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER and schema CREATE all denied; `service_role` ACL denial verified separately (not merely RLS bypass); no client membership in the creator; schema/table ACLs and `pg_default_acl` unchanged from M1a; post-`HARDEN-1`, a live client read of `public.plans` proves no plan name is exposed |
| **REPEATABILITY** | `supabase db reset --local` from an empty database yields byte-identical canonical UUIDs and data; a second application is a no-op; simulated conflict fixtures fail closed; no silent overwrite in any fixture; runner-owned atomic rollback proven by a forced mid-file failure |

Static tests do **not** replace runtime evidence. Absence of runtime infrastructure means reporting the gate incomplete — never a static-only PASS.

### 22.2 Dart/static gate (future)

`test/commercial_m1b_catalog_reference_data_migration_test.dart` must freeze, from **independent** expectations written in the contract:

1. Migration name and path: `00023_commercial_catalog_reference_data.sql`; unique, increasing prefix; canonical filename form.
2. The four canonical codes and the four canonical plan UUIDs (§7.1).
3. Bundle codes, `version = 1`, `registry_version = 1`.
4. Expected counts: 4 plans, 4 bundles, 19 items, 4 plan versions, 9 prices.
5. Exact `capability_key` set — five keys only — with exact kinds and values per bundle, including the Corporate omission.
6. Exact nine-row retail price matrix with IQD amounts, and no `6`-month or Corporate value.
7. `name_ar` is exactly the `DR-1` sentinel on all four plan versions, and no Arabic string literal appears anywhere in the seed.
8. Prohibited: any `founding_partner`, `launch_partner`, `sponsored`, `founding`, `promo`, `trial` plan/bundle code or literal.
9. Prohibited patterns in the migration: `ON CONFLICT` … `DO UPDATE`, `BEGIN`/`COMMIT`/`ROLLBACK`/`START TRANSACTION`/`SAVEPOINT`, `transaction=false`, `DROP`, `TRUNCATE`, `DELETE`, `ALTER TABLE`, `CREATE TABLE`, `CREATE FUNCTION`, `CREATE POLICY`, `GRANT`.
10. Asserted invariants: every seeded `status = 'draft'`; all lifecycle/effective markers NULL; `is_active = false`; `description`/`description_ar` NULL; fixed `created_at` constant present and `now()` absent from seeded values.
11. Absence of any write to `public.subscriptions` and of any `directory_entities` reference.
12. `supabase/config.toml` unchanged (no `commercial_private` in `api.schemas`), `supabase/seed.sql` still empty, and no new Dart production consumer.

---

## 23. Existing data and deployment safety — frozen for the future cutover

**Repository and local database state do not prove deployed production state.** Local `public.plans` is empty; `00008` never seeded. M1a §2 limits repository evidence to a non-deployed-schema / non-production-data audit, while §10 preserves canonical plan identity references. Accepted C1 §21 / §22 `AR-13` require reviewed compatibility/disposition; `AR-04` leaves legacy subscription state mapping deferred. The frozen fail-closed conflict matrix (§16.1) is unchanged.

M1b applies nothing, so this applies only to the future authorized cutover. Its mandatory pre-deployment inventory (read-only, on the target environment, recorded **before** any apply):

| Query | Purpose |
|---|---|
| `SELECT code, count(*) FROM public.plans GROUP BY 1 ORDER BY 1;` | Detect unknown/legacy codes and near-collisions |
| `SELECT id, code, name, is_active FROM public.plans ORDER BY code;` | Cases C/D/E detection |
| `SELECT count(*) FROM public.plans p WHERE lower(btrim(p.code)) IN ('business','business_pro','business_plus','corporate');` | Near-collision count for case C′ |
| `SELECT s.id, s.entity_id, s.plan_id, p.code FROM public.subscriptions s LEFT JOIN public.plans p ON p.id = s.plan_id ORDER BY s.id;` | Which legacy plan identities are already referenced by subscriptions |
| `SELECT p.code, count(s.id) FROM public.plans p LEFT JOIN public.subscriptions s ON s.plan_id = p.id GROUP BY 1;` | Reference counts per plan identity |
| `SELECT count(*) FROM commercial_private.plan_versions;` (and each private table) | Confirm M1a is applied and the private catalog is empty |

Rules:

1. **Case C/D/E/C′/G ⇒ STOP.** No automatic rewriting of an identity that a subscription may reference. Automatic reconciliation of referenced IDs **cannot be proven safe** from repository evidence, so these cases require an explicit, separately reviewed migration.
2. **Case A ⇒ proceed.** Fully automatic and safe.
3. **Case B ⇒ proceed** with zero modification of the existing row.
4. **Case F ⇒ proceed**, leaving every unrelated row byte-identical; disposition is routed to the C3 §33 / M4 reviewed-reconciliation family. Row classification there is never an entitlement and never a launch decision.
5. Never import `planType`, `featured`, `foundingPartner`, `trialing` or entity `active`/`claim = claimed` status as canonical commercial evidence (C3 §1, §33; frozen §5.8).
6. The future migration's precondition block re-derives cases A–G at apply time, so a deployment that differs from the recorded inventory still fails closed rather than mutating unknown data.
7. No production or cloud action is taken during contract drafting, and none is authorized by this document.

---

## 24. Rollback boundary

| Situation | Rollback |
|---|---|
| **Current M1b pass** | **Nothing to roll back.** Only one Markdown file was created. No database, config, test or Git state changed. Deleting this document restores the repository exactly. |
| Pre-implementation (design rejected) | Delete nothing; the contract is documentation. No database state changed. |
| Future cutover applied, **no consumer exists yet** | **Preferred operational rollback is non-destructive:** stop the rollout and **leave the canonical reference rows inert**. They are all `draft`, no evaluator reads them, and no RPC/UI depends on them. Do not run a down migration. |
| Deletion considered safe? | Only while **all** hold: no consumer exists; every seeded row is still `draft`; no `plan_versions`/`term_prices`/`bundle_items` row is referenced by any future commercial record; no subscription or agreement references a seeded plan UUID. Under those conditions a separately authorized cleanup migration could delete the seeded rows and restore the exact prior state. |
| Deletion **not** safe | Once any later slice publishes a version, creates an agreement/term/grant/order, or records a purchased snapshot — `ON DELETE RESTRICT` FKs would either block deletion or, worse, a careless cleanup would destroy referenced history. After that point rollback is **operational only** (stop activation, deactivate a sale version, retain references). |
| Never | Never `DROP SCHEMA commercial_private`, never truncate, never a blanket down migration, never re-applying `00022`'s "schema already exists" failure as a rollback mechanism. A future explicit cleanup contract is required for any destructive removal. |

---

## 25. OPEN policy integrity

Every item below is **touched by proximity and deliberately left unresolved**. M1b silently resolves none.

| OPEN / PROVISIONAL item | Registered as | M1b treatment |
|---|---|---|
| Founding pricing mechanics beyond the locked annual values; 1/3-month first terms | `OQ-01`, `P-22` | Not seeded anywhere |
| "First 50" counter definition and evidence | `OQ-02` | Not seeded |
| Extra-Branch pricing, 3-month extra-branch price, maximum branch count | `P-01`, `OQ-03` | No price, no cap key |
| Extra-Branch cap/pricing awaiting owner | `D-25` | Unchanged |
| Media quotas, storage/size/type limits, per-category media limits | `OQ-16`, `P-14` | Only `media.upload_enabled = true` |
| Analytics retention, aggregation, counting rules, export, post-expiry visibility, advanced metrics | `OQ-17`, `P-15`, `P-16` | Only `analytics.available = true` |
| Plan entitlement matrix beyond branches and media | `P-03` | Only the five LOCKED keys |
| Grace-period management access | `P-05`, `OQ-12` | Not seeded |
| Corporate branch count / contents; negotiated extras; technical entitlement storage | `P-02`, `L-84` scope note, `D-29` | Plus floor only |
| Launch Partner cohort mechanics, selection, cap, revocation, continuity, draft lifecycle | `OQ-80`–`OQ-83` | Not seeded; no grant structure |
| Sponsored inventory, campaign implementation, branch-level Sponsored | `P-06`, `D-14`, `D-15` | Prerequisite boolean only |
| **Arabic final copy; badge wording/placement; governing language** | `OQ-14`, `P-12`, `P-35`, `D-27`, `OQ-69` | **Explicitly NOT closed by `DR-1`.** `description`/`description_ar` NULL; `name_ar` carries the §9.2 private draft-only sentinel |
| Discounts for multi-year/early payment/volume; whether discounts stack | `OQ-42`, `P-24` | No discount seeded |
| Known post-publication quality shortfall; approver model; Required Fields matrix; Business Center UX/RBAC | `OQ-48`, `OQ-49`, `OQ-76`, `OQ-77` | Not seeded |
| Multi-year / renewal / instalment / proration formulas | `P-34`, `OQ-42` | Not seeded |
| Existing seed/mock/launch-row disposition | `OQ-22`, `OQ-40` | Unchanged |
| Duplicate detection/merge mechanics | `OQ-72` | Unchanged |
| Post-promotion category re-gating | `OQ-84` | Unchanged — explicitly still unresolved |
| Technical catalog representation seam | `OQ-23` | Register entry unchanged; C3 proposes the seam, M1b does not close it |
| Proration, statutory retention, tax/invoice/VAT | `P-34`, `OQ-09`, `OQ-40`, `D-19`, `D-20` | Not seeded |
| Public catalog presentation / projection authority | `DR-2` prerequisite | **Deferred to `HARDEN-1`** (§4); no M1b decision |

No `OQ-nn` status, severity, owner or classification changes. No `P-nn` becomes `LOCKED`. No `D-nn` dependency is satisfied. `DR-1` explicitly closes no OPEN item. The Commercial Model is **not** amended by this contract.

---

## 26. Historical drafting acceptance gate (documentary)

The original drafting checks are retained below. Current documentary correction / acceptance evidence is recorded in §30.

| # | Requirement | Result |
|---|---|---|
| 1 | Only this Markdown file created | ✔ |
| 2 | No existing file modified | ✔ |
| 3 | Protected dirty baseline untouched | ✔ |
| 4 | `DR-1` recorded with concrete sentinel value and testable invariants | ✔ (§9) |
| 5 | `DR-2` recorded with all eight clauses and its cascade | ✔ (§2.2) |
| 6 | Scope partition derived from the actual M1a FK graph, not assumed | ✔ (§5.6) |
| 7 | Sequencing dependency `HARDEN-1` specified with required properties H-1…H-8 | ✔ (§4) |
| 8 | All 40 designed rows preserved with exact codes, UUIDs, matrices and evidence | ✔ (§7, §10, §14) |
| 9 | Public behavior delta is exactly zero and `DR-2` compliance is asserted | ✔ (§19) |
| 10 | No Frozen policy addendum, amendment or reinterpretation | ✔ (§19.1, §25) |
| 11 | No migration, no SQL test, no Dart test created | ✔ |
| 12 | Nothing staged, committed or pushed | ✔ |
| 13 | `IMPLEMENTATION_AUTHORIZED = NO` | ✔ |
| 14 | Drafting-time local probe disclosed rather than omitted | ✔ (§5.5) |
| 15 | Internal consistency: scope counts, UUID counts and status labels agree across all sections | ✔ |
| 16 | `M1b-DEC-3` = **D3-A** recorded with its five-point rationale; no standalone SCOPE-B seeding | ✔ (§3.2) |
| 17 | `D3-B` recorded as **REJECTED with no authority**, not as an available option | ✔ (§3.2) |
| 18 | SCOPE-A **and** SCOPE-B both explicitly `DEFERRED`; 40 rows designed, **0** authorized | ✔ (§3.1, §3.2.1) |
| 19 | `DR-1` and `DR-2` unchanged by this decision | ✔ (§2.1, §2.2) |
| 20 | `HARDEN-1` remains a **separate** prerequisite, unimplemented | ✔ (§4) |

---

## 27. Implementation authorization

**THIS PASS RECORDS ACCEPTED DESIGN / SEQUENCING ONLY; THE RE-SCOPED SLICE HAS NO AUTHORIZED SEED.**

```text
IMPLEMENTATION_AUTHORIZED = NO
```

Not done in this pass and not authorized by this document: creating `00023`; creating any M1b test; seeding any row of any tier; changing any migration, schema, config, grant, policy, RPC or Flutter file; running a reset, SQL test, Dart test or repository-wide suite; implementing `HARDEN-1`; any staging, commit or push; any production or cloud action.

`ARCHITECT_ACCEPTANCE` is **APPROVED** for canonical design / sequencing only (§30). Acceptance does **not** authorize implementation. Preconditions for any future implementation authorization:

1. Architect ratification of this re-scoped document — **completed in §30**, with zero rows authorized.
2. `HARDEN-1` separately **contracted, accepted, implementation-authorized, implemented, landed and verified** (§4) — required before any M1b seed of any tier; remains unauthorized.
3. A **separate explicit Architect authorization that reopens the M1b seed**, naming the tier authorized. `D3-A` does not pre-authorize the reopening; it defers it.
4. `M1b-DEC-3` is **decided** (`D3-A`) and is **no longer** an open precondition. Reverting or amending it requires a new explicit Architect decision.

Acceptance freezes design / sequencing only. It is distinct from implementation-contract or implementation authorization and does not reopen any seed tier.

---

## 28. Git safety and validation — historical drafting record

This section preserves the drafting-time evidence. The current documentary acceptance pass is recorded in §30.

| Check | Result |
|---|---|
| `HEAD` before drafting | `4977a35d4f982fa75ec8c04eee606358dc9126ab` |
| `HEAD` after drafting | `4977a35d4f982fa75ec8c04eee606358dc9126ab` |
| `origin/main` (local tracking ref) | `4977a35d4f982fa75ec8c04eee606358dc9126ab` |
| Match | Yes — exact full SHA before and after |
| Actual next free migration | `00023` (verified `00001`–`00022`, no gaps/duplicates) — **not reserved, not claimed** |
| Files created in this pass | This contract only |
| Files modified | None |
| Protected dirty baseline | Untouched — not reset, reverted, stashed or cleaned |
| Staged | Nothing |
| Committed | No |
| Pushed | No |
| Runtime actions | Read-only catalog inspection; two rolled-back local feasibility transactions from the first draft, disclosed in §5.5, both verified to leave zero rows. No reset, no SQL/Dart test run, no remote connection, no production action |
| Commercial policy decisions changed | 0 |
| Existing OQs closed/reclassified | 0 (`DR-1` closes none by decision) |
| Frozen policy amended or addended | 0 |
| C1 / C2 / C3 registers touched | 0 |
| M1a schema changed | 0 |
| Architect decisions folded in | **3** (`DR-1`, `DR-2`, `M1b-DEC-3` = **D3-A**) |

---

## 29. Recommendation — historical pre-acceptance record

The recommendation below is retained as the historical pre-acceptance drafting/review record. Current acceptance is **APPROVED** in the metadata and §30; its historical `PENDING` statements are superseded without rewriting their history. `HARDEN-1` remains unauthorized.

Ready for **Architect ratification of this re-scoped document**, and for **independent PostgreSQL / Supabase / commercial-catalog review**. The substantive engineering work is complete and the full 40-row design is preserved.

The three decisions did not merely delay M1b — they removed its seed. `DR-1` resolved the localization gap without inventing Arabic copy. `DR-2` found a genuine conflict between the M1a FK architecture and the Frozen §14.3 / `L-37` prohibition, and declined to resolve it by relaxing policy. `M1b-DEC-3` (**D3-A**) then closed the last remaining candidate by declining a standalone draft-only bundle seed, which the FK graph would have permitted but policy did not require. The result is a slice whose design is frozen and whose deliverable is currently a document.

Two items remain for the Architect:

1. **Ratify this re-scoped document.** `DR-1`, `DR-2` and `M1b-DEC-3` are decided and folded in; the derived scope, the zero-delta posture and the zero-authorized row count need endorsement.
2. **Authorize `HARDEN-1`** (§4) as the gating prerequisite, since no M1b seed can proceed without it. Note §4.3: because `public.plans` has zero consumers, revoking the raw public read is a pure hardening with no Flutter impact, which materially lowers the cost of this dependency.

No other blocking semantic defect was found. M1a is accepted, requires no schema change, and `DR-2` explicitly forbids working around it. The scope partition was derived from the actual foreign-key graph rather than assumed, so the deferral is provably minimal rather than convenient — and §5.6 records explicitly that SCOPE-B's deferral is a **policy choice under D3-A, not a structural necessity**, so a reviewer can see precisely what was declined and why.

The document is internally consistent and ready for independent review. No further Architect selection is pending within M1b.

```text
ARCHITECT_ACCEPTANCE = PENDING
IMPLEMENTATION_AUTHORIZED = NO
```

---

## 30. Final Architect acceptance record — 2026-10-03

- Initial independent review: **B — READY AFTER NON-SEMANTIC DOCUMENTARY CORRECTIONS**
- Semantic/architecture/policy corrections required: **0**
- Documentary corrections required: **NC-1…NC-7 — APPLIED**
- Optional trace polish applied: **NC-8, NC-9**
- Informational observations: **NC-10, NC-11** — Corporate values retained as Plus floors; the historical pre-DR-2 local probe disclosure is preserved and no probe was repeated.
- Architect Acceptance: **APPROVED**
- Accepted authority: **CANONICAL DESIGN + SEQUENCING ONLY**
- **D3-A ratified**; **D3-B remains REJECTED**. Reopening D3-B or any M1b seed requires an explicit new Architect decision.
- SCOPE-A: **17 rows — DEFERRED**
- SCOPE-B: **23 rows — DEFERRED**
- Canonical rows designed: **40**
- Rows authorized: **0**
- Commercial Model changes: **0**
- C1/C2/C3/M1a changes: **0**
- OPEN OQs closed/reclassified: **0**
- IMPLEMENTATION_AUTHORIZED: **NO**
- HARDEN-1 authorization: **NO**
- 00023 authorization: **NO**
- Authority: **ChatGPT Architect**

Acceptance is not implementation authorization or future implementation-contract authorization. `HARDEN-1` must be separately **contracted → accepted → implementation-authorized → implemented → landed → verified** before canonical `public.plans` identities may be seeded. Even then, M1b remains deferred until a separate explicit Architect authorization names the seed tier.

NC-1 evidence precision: the SDK dependency and wired Flutter framework delegates exist; no authorized commercial-copy localization SSOT/delegate pipeline exists. No OPEN localization item is closed. NC-2 leaves `OQ-17` analytics-only; NC-3 leaves `OQ-76` OPEN and Frozen §28.6.4 PROVISIONAL. NC-4 uses only the Founding `founding_eligibility` anchor in C3 §6; no A8 program semantics are moved into Founding Partner.

This pass changes documentary evidence traces and current acceptance metadata only. All 40 fixed UUID mappings, nine retail prices, 19 bundle items, `DR-1` invariants, `DR-2`, D3-A's scope disposition and the fail-closed conflict matrix are preserved. Public behavior delta remains **EXACTLY ZERO**.

Validation: only this contract changed; protected pre-existing dirty files, Commercial Model, C1/C2/C3/M1a, `00022`, configuration, seed, Flutter and roadmap are untouched. `00023` and M1b SQL/Dart tests are absent. No database action, probe, implementation, staging, commit or push occurred. HEAD and local `origin/main` remain `4977a35d4f982fa75ec8c04eee606358dc9126ab`; the index is empty.
