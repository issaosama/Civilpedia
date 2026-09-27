# CIVILPEDIA — COMMERCIAL MODEL V1 (CANONICAL SSOT)

DOCUMENT_ID: `CIVILPEDIA_COMMERCIAL_MODEL_V1`
DOCUMENT_STATUS: ACTIVE — CANONICAL COMMERCIAL SSOT
DOCUMENT_AUTHORITY: OWNER + CHATGPT ARCHITECT (commercial decisions)
SCOPE: Documentation / consolidation only
IMPLEMENTATION_AUTHORIZED: NO — this document does not authorize any code, schema, contract, or phase change
BASELINE_COMMIT: `30aa1b23` (V1-R10.5-C closed / accepted)
ROADMAP_PHASE_AT_BASELINE: V1-R10 UI/UX & Core App Experience — R10.5-D CURRENT (pre-implementation audit only); R10.5-E Business + Staff LOCKED
SOURCE_OF_DECISIONS: Owner-approved commercial decisions consolidated by the Architect; conversation history is NOT a source of truth
AMENDMENT: A1 — Conflict Reconciliation (2026-09-27), authority: ChatGPT Architect. Reconciles C-1…C-10 by authority separation. No commercial intent changed. No production, schema, contract, or roadmap change authorized or performed.

---

## 1. GOVERNANCE

### 1.1 Purpose

This document is the single source of truth for the Civilpedia **commercial model**.
It governs what is sold, to whom, at what price, under which entitlements, and
under which lifecycle, verification, and publication rules.

It does **not** govern phase execution, file boundaries, test gates, or
engineering ceremony. That authority remains
`docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md`.

### 1.2 Commercial policy authority != implementation authority (mandatory)

> This document defines Civilpedia's target commercial/business policy.
> It does **not** independently authorize changes to production code, database
> schema, enums, migrations, RLS, routing, authentication, persistence, billing
> infrastructure, Directory architecture, or roadmap phase scope.
> Any implementation of these policies requires a separately authorized
> architecture/implementation slice.

Consequences of this rule:

1. A `LOCKED` commercial outcome is a **policy** decision, not an engineering
   instruction. It binds product behaviour and sales/commercial language; it does
   not create a schema, enum, table, column, flag, or screen.
2. Naming a concept in this document (for example `Brand`, `Branch`,
   `Manager`, `Editor`, `Business Pro`, `Payment Verified`) does **not** imply
   that a corresponding database object, enum value, field, route, or service
   exists or is authorized to be created.
3. Where existing production artifacts use different names, enumerations, or
   structures, those artifacts remain **unchanged and authoritative for
   engineering** until a separately authorized slice deliberately maps, extends,
   or migrates them. See §24.1.
4. No agent may use this document to justify a migration, RLS change, enum
   change, entitlement backfill, or feature flag change.
5. Reconciliation of any conflict in §24.1 is achieved by **separating
   commercial policy from implementation mapping**, not by changing production
   code or by weakening the commercial policy.

### 1.3 Status classification (mandatory)

Every rule in this document carries exactly one status:

| Status | Meaning | Change authority |
|---|---|---|
| `LOCKED` | Owner-approved commercial decision. Binding. May not be silently reinterpreted, softened, or implemented around. | Owner, by explicit update to this document |
| `PROVISIONAL` | Approved direction or working value, not a final commitment. Explicitly not frozen. | Owner / Architect, by explicit update to this document |
| `DEFERRED` | Intentionally out of Commercial V1 scope. Not decided. May be researched later. | Owner, by explicit update to this document |

Rules for classification:

1. A number described as "current", "target", "exploratory", "baseline", or
   "intended" is **never** automatically `LOCKED`.
2. `PROVISIONAL` values must not be presented to customers, in UI copy, in
   contracts, or in sales conversations as final pricing or final policy.
3. A missing rule stays missing. It is recorded in §24.3 as an open question.
   Agents and authors must not invent it.
4. `DEFERRED` means "not in Commercial V1", not "rejected".
5. Commercial policy status is independent of implementation status. A concept or
   value may be `LOCKED` as policy while its database, enum, schema, or UI
   representation remains `PROVISIONAL` or unimplemented (§1.2).

### 1.4 Relationship to existing repository authority

| Authority | Domain | Relationship to this document |
|---|---|---|
| `CIVILPEDIA_V1_MASTER_ROADMAP.md` | Phase/status, authorization, scope | Unchanged. This document never grants implementation authorization. |
| `CIVILPEDIA_AGENT_OPERATING_MODEL.md` | Agent roles, escalation, Git policy | Unchanged. |
| `CIVILPEDIA_DIRECTORY_AND_SERVICES_ARCHITECTURE.md` | Directory domain ownership, organic vs sponsored, verification | Aligned; reinforced by §6, §9, §18. |
| `CIVILPEDIA_DATA_OWNERSHIP_AND_DOMAIN_CONTRACTS.md` | Domain ownership, Monetization vs Directory | Aligned; reinforced by §6, §2. |
| Frozen contracts V1-R03 / V1-R06 / V1-R07 / V1-R08 | Ownership, profile management, staff ops, auth | **Reconciled by authority separation — see §24.1 (C-1, C-5).** Existing role and commercial-like field implementations are unchanged and remain engineering-authoritative. |
| `supabase/migrations/*` | Production schema, RLS | **Not modified by this document.** Reconciliation is a separate authorized phase. |
| `lib/**` | Production code | **Not modified by this document.** |

### 1.5 Change protocol (append-only)

Future commercial decisions must be applied as follows:

1. Amend or add the affected section explicitly.
2. Update §25 (Decision Registry) so the status of the rule is unambiguous.
3. Append a dated entry to §24.4 (Change Log). Never delete a superseded rule —
   mark it `SUPERSEDED` and point to its replacement.
4. Record in the change log: date, authority, what changed, previous value,
   new value, and whether implementation/sales impact is immediate.
5. Conversation history, chat memory, ad-hoc notes, and verbal statements are
   never sufficient. If it is not in this document, it is not decided.

---

## 2. LOCKED BUSINESS MODEL

### 2.1 Core rules

| # | Rule | Status |
|---|---|---|
| 2.1.1 | The Public Business Directory is **paid-only**. | `LOCKED` |
| 2.1.2 | There is **no permanent free public listing**. No tier, trial, or lifetime-free public listing exists. | `LOCKED` |
| 2.1.3 | A Business subscription belongs to the **Business Entity**, not to a User Account. | `LOCKED` |
| 2.1.4 | `Brand`, `Business Entity`, `Branch`, and `User` are **four distinct concepts** and must never be conflated in data, UI, or sales language. | `LOCKED` |
| 2.1.5 | A user's departure, deletion, or loss of access never destroys the Business Entity, its subscription, or its content. | `LOCKED` |
| 2.1.6 | One User may hold memberships in multiple, unrelated Business Entities. | `LOCKED` |
| 2.1.7 | Commercial presence in the public directory is an entitlement of a paid Business Entity. A user account alone confers no public commercial presence. | `LOCKED` |
| 2.1.8 | The Paid-Only rule applies to the **future Commercial Production Directory** (§2.5). | `LOCKED` |

### 2.2 Concept relationships (canonical diagram)

```
Brand
  -> Business Entity            (commercial + legal/operational unit; subscription owner)
      -> Branch(es)             (operating locations of that entity)

User
  -> Business Membership / Role (user-side access to a Business Entity)
      -> Business Entity
```

### 2.3 Conceptual model vs persistence (non-authorization)

| Element | Status |
|---|---|
| The **conceptual** model Brand → Business Entity → Branch, and User → Business Membership → Business Entity. | `LOCKED` |
| The exact tables, foreign keys, and relations used to persist Brand, Business Entity, Branch, or Membership. | `PROVISIONAL` — future architecture |
| Whether `Brand` is persisted as its own entity, derived, or an attribute. | `PROVISIONAL` |
| Branch / location modelling (address, service area, geolocation, per-branch data). | `PROVISIONAL` |
| Ownership mapping between users, memberships, branches, and the entity. | `PROVISIONAL` |
| Migration or schema design for any of the above. | `PROVISIONAL` — a future authorized architecture slice |

**No schema exists solely because this document defines the concept.** This
document does not create, require, or authorize any table, column, foreign key,
enum, or migration. See §1.2 and §24.1 (C-6).

### 2.4 Multi-branch vs multi-entity rules

| Situation | Rule | Status |
|---|---|---|
| Same ownership **and** same operating business, multiple locations | **One** Business Entity, **one** Business subscription, multiple Branches. | `LOCKED` |
| Same brand name, but independently owned and/or independently operated entities | **Separate** Business Entities and **separate** subscriptions. | `LOCKED` |
| A Branch is a location of a Business Entity; it is never a separately billed or separately owned entity by default. | `LOCKED` |
| Whether a Branch may ever be a separately owned legal entity inside a shared brand. | Not decided. | `PROVISIONAL` — see §24.3 |
| Branch as a first-class searchable/local-discovery unit while remaining part of one Business Entity. | Approved direction. | `PROVISIONAL` — see §18 |

### 2.5 Paid-Only scope: commercial production vs development data (C-9)

| Rule | Status |
|---|---|
| Paid-Only applies to the **future Commercial Production Directory**. | `LOCKED` |
| Paid-Only does **not** require immediate removal of development listings, mock listings, seed data, test fixtures, or preview/demo businesses. | `LOCKED` |
| Existing seed/mock/development data may continue to exist and be used during development. | `LOCKED` |
| Before commercial production launch, public production eligibility must follow the Paid-Only rule (§2.1) **and** the Publication Quality rule (§19). | `LOCKED` |
| The disposition of specific existing non-production rows at launch (convert, grandfather, or remove) remains undecided. | `PROVISIONAL` — open question §24.3 |
| Any enforcement, conversion, or cleanup action on existing data. | `PROVISIONAL` — requires a separately authorized slice |

No seed data, mock data, fixture, or preview record was modified by this document.

---

## 3. PLANS

### 3.1 Approved plan structure

| Plan | Position in lineup | Status |
|---|---|---|
| Business | Entry paid plan | `LOCKED` |
| Business Pro | **Primary / default commercial recommendation** | `LOCKED` |
| Business Plus | Upper self-serve plan | `LOCKED` |
| Corporate | Quotation-based enterprise plan | `LOCKED` |

Approved durations: `1 month`, `3 months`, `12 months`. — `LOCKED`

### 3.2 Current approved price list (IQD)

| Plan | 1 month | 3 months | 12 months |
|---|---|---|---|
| Business | 20,000 | 55,000 | 200,000 |
| Business Pro | 40,000 | 110,000 | 400,000 |
| Business Plus | 70,000 | 190,000 | 700,000 |
| Corporate | custom quotation | custom quotation | custom quotation |

Status of the table above: `LOCKED` as the **current approved Commercial V1 price
baseline**. It is a baseline, not an immutable constant: any change must be made by
an explicit update to this document per §1.5, and no agent may quote a different
price from memory or inference.

### 3.3 Default recommendation

| Rule | Status |
|---|---|
| Business Pro is the intended primary/default commercial recommendation. | `LOCKED` |
| Where, how, and in what wording that recommendation is surfaced (sales material, Business Center, comparison tables). | `PROVISIONAL` |
| Plan feature/entitlement matrix per tier beyond branches (§4) and media (§16). | `PROVISIONAL` — see §24.3 |
| Corporate plan contents, minimum commitment, and quotation process. | `PROVISIONAL` |
| Discounts for multi-year, early payment, or volume beyond Founding Partner. | Not decided. → `PROVISIONAL` / open question |

### 3.4 Derived arithmetic observations (non-binding)

These are arithmetic consequences of §3.2 only. They introduce no new rule and
create no new price.

| Plan | 3-month ÷ 3 | 12-month ÷ 12 | Annual vs monthly list |
|---|---|---|---|
| Business | 18,333 | 16,667 | annual = 10 × monthly |
| Business Pro | 36,667 | 33,333 | annual = 10 × monthly |
| Business Plus | 63,333 | 58,333 | annual = 10 × monthly |

Observation: longer durations are priced at roughly a 10-month effective cost for
a 12-month term. Whether this discount structure is intentional, and whether it
stays, is not stated by the Owner. → `PROVISIONAL`

### 3.5 Commercial catalog vs existing plan implementation (non-authorization)

The commercial catalog in §3.1–§3.2 is `LOCKED` and unchanged by Amendment A1.
Its **implementation mapping** is explicitly `PROVISIONAL`:

| Element | Status |
|---|---|
| Commercial plan catalog: Business, Business Pro, Business Plus, Corporate. | `LOCKED` |
| Commercial durations and prices (§3.1, §3.2). | `LOCKED` |
| Mapping the commercial catalog onto `lib/core/access/plan_type.dart` (`PlanType`) and `plan_tier.dart` (`PlanTier`). | `PROVISIONAL` — future monetization architecture task |
| Mapping the commercial catalog onto the `public.plans` table and any entitlement records. | `PROVISIONAL` — future monetization architecture task |
| Whether the existing enums are renamed, extended, superseded, or coexist with the commercial catalog. | `PROVISIONAL` |
| Plan code values, price storage, and currency representation. | `PROVISIONAL` |
| Any enum, table, column, or seed change. | **Not authorized by this document** — requires a separately authorized architecture/implementation slice (§1.2) |

The existing `PlanType` / `PlanTier` scaffolding and the `plans` table remain
**unchanged and engineering-authoritative** for current builds. Their known
plan-coupling debt is a pre-existing architecture concern recorded in
`CIVILPEDIA_IMPLEMENTATION_READINESS_AND_ROADMAP.md`; this document neither fixes
nor worsens it. See §24.1 (C-2).

---

## 4. BRANCH ENTITLEMENTS

### 4.1 Included branches

| Plan | Included branches | Status |
|---|---|---|
| Business | 1 | `LOCKED` |
| Business Pro | 2 | `LOCKED` |
| Business Plus | 3 | `LOCKED` |
| Corporate | custom | `PROVISIONAL` (depends on §3.3 Corporate definition) |

### 4.2 Extra branches

| Rule | Status |
|---|---|
| Additional branches are sold as an **Add-on**, not as a requirement to buy a second complete subscription. | `LOCKED` |
| The Extra Branch add-on attaches to the existing Business Entity and its single subscription. | `LOCKED` |
| Exact Extra Branch pricing. | `PROVISIONAL` |
| Current exploratory range: **10,000–15,000 IQD / month** or **100,000–150,000 IQD / year**. | `PROVISIONAL` — exploratory only, **not final pricing**, not quotable |
| Whether a 3-month extra-branch price exists. | Not decided → open question |
| Maximum branch count per entity, and behavior past the cap. | Not decided → open question |
| Whether extra-branch pricing differs by city/area or branch type. | Not decided → open question |
| Whether extra branches are transferable/resettable annually. | Not decided → open question |

Derived observation only: the annual range equals 10 × the monthly range, which is
consistent with the annual pricing factor observed in §3.4. This is arithmetic, not
a pricing decision.

---

## 5. FOUNDING PARTNER

| # | Rule | Status |
|---|---|---|
| 5.1 | The **first 50 businesses** may receive Founding Partner pricing. | `LOCKED` |
| 5.2 | Founding Partner pricing applies to the **first year only**. | `LOCKED` |
| 5.3 | The discount does **not** remain permanently. Renewal returns to standard pricing. | `LOCKED` |
| 5.4 | The Founding Partner badge / status / history may remain permanently. | `LOCKED` |
| 5.5 | The badge and the discount are two different things and must be modeled and displayed separately. | `LOCKED` |
| 5.6 | Public visibility rules for the badge. | `PROVISIONAL` (see §14.5) |

### 5.7 Current approved Founding Partner first-year prices (IQD)

| Plan | Founding Partner first year | Standard 12-month (§3.2) | Derived difference |
|---|---|---|---|
| Business | 150,000 | 200,000 | −50,000 (−25%) |
| Business Pro | 300,000 | 400,000 | −100,000 (−25%) |
| Business Plus | 525,000 | 700,000 | −175,000 (−25%) |

Status of the table: `LOCKED` as the current approved first-year figures.
The −25% column is a **derived observation**, not a stated policy.

| Open item | Status |
|---|---|
| Founding Partner price for a 1-month or 3-month first term. | Not decided → open question (§24.3) |
| How the "first 50" counter is defined, incremented, and evidenced. | Not decided → open question |
| What happens to businesses #51+ (standard pricing is implied, execution detail is not decided). | `PROVISIONAL` |
| Whether the Founding Partner badge appears on search results, profile, and Business Center. | `PROVISIONAL` |
| Whether Founding Partner is re-offered in a later cohort. | Not decided → `DEFERRED`-adjacent open question |

### 5.8 Founding Partner storage is non-canonical (C-5)

| Rule | Status |
|---|---|
| The Founding Partner **policy** in §5.1–§5.7 is `LOCKED` and unchanged by Amendment A1. | `LOCKED` |
| Existing production fields or seed/mock concepts that look commercial — including `featured`, `planType`, and any Founding-Partner-like markers on the Directory entity — do **not** automatically become canonical commercial storage. | `LOCKED` (non-canonical) |
| Those existing fields remain current/legacy implementation details until deliberately mapped or migrated under future architecture authority. | `LOCKED` (preservation) |
| Canonical storage design for badge vs discount, and re-parenting out of Directory core. | `PROVISIONAL` — future architecture slice |
| Any removal, rename, backfill, or migration of those existing fields. | **Not authorized by this document** |

No existing field was modified, removed, or reinterpreted by this document. See
§1.2 and §24.1 (C-5).

---

## 6. SPONSORED

### 6.1 Positioning rules

| # | Rule | Status |
|---|---|---|
| 6.1.1 | Sponsored placement is a **separate commercial product**. It is not a feature of a subscription tier. | `LOCKED` |
| 6.1.2 | Sponsored is **not equivalent to** subscription, **not equivalent to** verification, and **not equivalent to** organic ranking. | `LOCKED` |
| 6.1.3 | Sponsored results must be **visibly labeled** to users. | `LOCKED` |
| 6.1.4 | **Organic ordering must not be purchasable** through a higher subscription tier. No tier buys better organic position. | `LOCKED` |
| 6.1.5 | Sponsored status must never be presented or used as a verification signal. | `LOCKED` |
| 6.1.6 | Sponsored placement must not mutate the underlying Directory entity to imply quality. | `LOCKED` |
| 6.1.7 | Sponsored inventory is limited by **Category × Area**. | `LOCKED` |
| 6.1.8 | Sponsored is purchasable initially by **Business Pro / Business Plus** businesses. | `LOCKED` (explicitly changeable by Owner) |
| 6.1.9 | Sponsored impressions/clicks must be counted separately from organic and never inflated into organic. | `LOCKED` |
| 6.1.10 | If a sponsored entity is unavailable, the placement is suppressed; no blank or broken slot. | `LOCKED` |

### 6.2 Current approved Sponsored pricing (IQD)

| Duration | Price |
|---|---|
| 1 month | 30,000 |
| 3 months | 80,000 |
| 12 months | 300,000 |

Status: `LOCKED` as the current approved Commercial V1 price baseline.

### 6.3 Inventory target

| Rule | Status |
|---|---|
| Target of approximately **2–3 active sponsored positions per Category × Area**. | `PROVISIONAL` — a target, not a frozen cap |
| Whether 2–3 is a hard cap, a soft target, or queue-based. | Not decided → open question |
| How "Area" is defined for inventory purposes (governorate / district / custom radius). | Not decided → open question |
| Oversubscription behaviour, rotation, and fairness policy. | Not decided → open question |
| Campaign management tooling, creative rules, and disclosure copy. | `DEFERRED` (§21) |
| Sponsored renewal, cancellation, and refund terms. | Not decided → open question |

### 6.4 Product approved vs production implementation deferred (C-4)

| Layer | Status |
|---|---|
| **Commercial product definition** — Sponsored as a separate, labeled, inventory-limited product with the approved §6.1 rules and §6.2 pricing. | `APPROVED / LOCKED` |
| **Production implementation** of Sponsored placement, campaign gating, inventory, labeling, and sponsored-vs-organic separation in the product. | `DEFERRED` |

Clarifications:

1. Current `LocalAdDataSource` mock ads, plan-coupled Directory seed, and the
   existing Directory/Monetization architecture must **not** be interpreted as
   implementing the commercial Sponsored product.
2. No current mock, seed, scaffolding, or architectural placeholder constitutes
   Sponsored delivery, and none may be surfaced to users as if it did.
3. Sponsored implementation requires a **future separately authorized
   monetization slice** (§1.2, §1.4 roadmap authority).
4. The existing honest-ads rule (no placement without an active campaign) remains
   in force and is unchanged by this document.
5. Until that slice exists, Sponsored remains a `LOCKED` commercial policy with
   **no** production behavior. Policy approval and implementation are tracked
   separately (§24.1 C-4, §24.2 D-4).

---

## 7. PAYMENT / WHATSAPP

### 7.1 Approved Commercial V1 payment flow

| Step | Actor | Action | Status |
|---|---|---|---|
| 1 | Customer | Subscribe / Join intent | `LOCKED` |
| 2 | Civilpedia | WhatsApp Business conversation opened | `LOCKED` |
| 3 | Both | Plan agreement reached (plan, duration, price, branches, add-ons) | `LOCKED` |
| 4 | Civilpedia | Payment instructions issued | `LOCKED` |
| 5 | Customer | Transfers payment | `LOCKED` |
| 6 | Customer | Sends transfer receipt | `LOCKED` |
| 7 | System/Civilpedia | State: **Payment Pending Verification** | `LOCKED` |
| 8 | Civilpedia | **Independently verifies actual receipt of funds** | `LOCKED` |
| 9 | System | State: **Payment Verified** | `LOCKED` |
| 10 | System | Subscription becomes **Active** | `LOCKED` |

### 7.2 Verification-of-payment rules

| # | Rule | Status |
|---|---|---|
| 7.2.1 | A screenshot or receipt is **NOT** final proof of payment. | `LOCKED` |
| 7.2.2 | Activation occurs **only after funds are independently verified**. | `LOCKED` |
| 7.2.3 | Civilpedia may share the approved transfer identifier needed to reconcile the payment. | `LOCKED` |
| 7.2.4 | Civilpedia must follow a least-data principle: collect the minimum needed to identify the transfer. | `LOCKED` |

### 7.3 Never requested, never distributed

Civilpedia must **not** request, accept, store, or distribute:

- full 16-digit PAN, unless formally required by a future regulated flow;
- CVV;
- PIN;
- OTP;
- expiry date.

Status: `LOCKED` (prohibition). The "unless formally required by a future
regulated flow" exception for the 16-digit PAN is the only conditional clause and
requires an explicit Owner-approved regulated flow before it may be applied.

### 7.4 Internal references

| Reference | Purpose | Status |
|---|---|---|
| `CP-BIZ-xxxxx` | Internal business/commercial reference | `LOCKED` |
| `CP-PAY-xxxxx` | Internal payment reference | `LOCKED` |
| Exact reference format, sequence source, uniqueness scope, and display surface. | | `PROVISIONAL` |

### 7.5 Payment channel scope

| Rule | Status |
|---|---|
| Commercial V1 payment is manual/assisted via WhatsApp Business and verified by Civilpedia. | `LOCKED` |
| No automated payment gateway in Commercial V1. | `DEFERRED` (§21) |
| Accepted bank accounts / transfer rails, supported currencies, and settlement accounts. | Not decided → open question |
| Invoicing, receipts, tax/fiscal treatment, and accounting export. | Not decided → open question |
| Refund, cancellation, and partial-refund policy. | Not decided → open question |
| Anti-fraud controls beyond receipt verification (duplicate transfer, mismatched amount, third-party payer). | Not decided → open question |
| Staff handling rules for payment conversations (who may confirm, who may activate). | Not decided → open question |

---

## 8. SUBSCRIPTION LIFECYCLE

### 8.1 State vocabulary (commercial concept, not a database enum)

The states below are the approved **commercial workflow vocabulary**. They are
**not** required to live in one database column, one enum, or one table.

| State | Meaning | Status |
|---|---|---|
| Draft | Commercial record exists; no payment commitment completed. | `LOCKED` |
| Payment Pending | Payment instruction issued / transfer expected; funds not yet verified. | `LOCKED` |
| Payment Verified | Funds independently confirmed; activation may proceed. | `LOCKED` |
| Active | Subscription live; public publication subject to §19 quality gate. | `LOCKED` |
| Grace Period | Term ended; business retains its data and its management access during a defined window. | `LOCKED` |
| Expired | Grace Period ended; public directory presence hidden. | `LOCKED` |

### 8.2 Three separate conceptual workflows

The commercial lifecycle is the composition of **three independent concerns**.
They must not be conflated, and no single storage representation is implied.

**A. Business onboarding / publication workflow**

| State | Meaning | Status |
|---|---|---|
| Draft | Business record being prepared. | `PROVISIONAL` (mechanism) — concept is `LOCKED` (§8.1) |
| Pending Review | Content or sensitive change submitted and awaiting review (§13). | `PROVISIONAL` (mechanism) — concept is `LOCKED` |
| Published / Hidden | Public directory visibility outcome. | `PROVISIONAL` (mechanism) — concept is `LOCKED` |

**B. Payment workflow**

| State | Meaning | Status |
|---|---|---|
| Pending Verification | Payment instruction issued / transfer expected, funds not yet confirmed. | `LOCKED` (behavior, §7.2) |
| Verified | Funds independently confirmed. | `LOCKED` (behavior, §7.2) |
| Rejected / unresolved | Only where a later defined policy introduces it. | `PROVISIONAL` / not defined |

**C. Subscription entitlement lifecycle**

| State | Meaning | Status |
|---|---|---|
| Active | Paid entitlement currently live. | `LOCKED` |
| Grace Period | Term ended, defined retention window running. | `LOCKED` |
| Expired | Grace Period ended; public presence hidden, data retained. | `LOCKED` |

**Composition rule (`LOCKED`):** a business is publicly visible only when its
publication state is published **and** its payment state is verified **and** its
entitlement state is active. Failure of any one of the three is sufficient to
withhold public presence; none of the three may be satisfied by purchasing
another (§9.1, §6.1.4, §19).

### 8.3 Lifecycle rules (commercial behavior)

| # | Rule | Status |
|---|---|---|
| 8.3.1 | Expiration must **NOT delete the Business**. | `LOCKED` |
| 8.3.2 | Business data, images, products, projects, offers, and ownership are **retained** through expiry. | `LOCKED` |
| 8.3.3 | After Grace Period, an expired business is **hidden from the public directory**. | `LOCKED` |
| 8.3.4 | Renewal **restores publication without rebuilding the profile**. | `LOCKED` |
| 8.3.5 | The Business Entity, its Branches, and its memberships survive expiry. | `LOCKED` |
| 8.3.6 | Grace Period exact duration. | `PROVISIONAL` |
| 8.3.7 | Current Grace Period target: approximately **3–7 days**. | `PROVISIONAL` — target, not frozen |
| 8.3.8 | Whether management access continues during Grace Period (read/write), and what the owner sees. | `PROVISIONAL` |
| 8.3.9 | Renewal pricing, upgrade/downgrade mid-term, proration, and downgrade when branch count exceeds the new tier. | Not decided → open question |
| 8.3.10 | Whether an expired business retains analytics history and internal records visibility. | Not decided → open question |
| 8.3.11 | Grace-period expiry notices, channels, and language (Arabic-first). | Not decided → open question |
| 8.3.12 | State-machine / persistence mapping to existing production state values. | `PROVISIONAL` — reconciled as C-3, see §8.4 |

### 8.4 State machines, enum names, and persistence mapping (C-3 — non-authorization)

| Element | Status |
|---|---|
| The **commercial behaviors** in §8.3.1–§8.3.5 and the payment rules in §7.2. | `LOCKED` and unchanged |
| The exact onboarding/publication state machine, its transitions, and its persisted representation. | `PROVISIONAL` |
| The exact payment state machine and its persisted representation. | `PROVISIONAL` |
| The exact entitlement lifecycle state machine and its persisted representation. | `PROVISIONAL` |
| Enum names, column names, table names, and field types for any of the three workflows. | `PROVISIONAL` |
| Mapping to the existing `subscriptions.status` CHECK values `trialing`, `active`, `past_due`, `canceled`, `paused`. | `PROVISIONAL` |
| Whether any new states, columns, or tables are required, and any migration. | **Not authorized by this document** — separately authorized slice required (§1.2) |

**This document does not imply that a single database `subscription_status` enum
must contain all commercial workflow states.** The three concerns in §8.2 may be
represented separately, or combined under different names, as a future authorized
architecture slice decides.

**Existing backend state definitions are unchanged by this document.** The current
`subscriptions.status` CHECK constraint, and the existing rule that subscription
status is orthogonal to Directory verification, remain exactly as they are. See
§24.1 (C-3).

---

## 9. VERIFICATION

### 9.1 Locked rule

| Rule | Status |
|---|---|
| **PAID ≠ VERIFIED ≠ SPONSORED.** Payment never purchases verification. Verification is never implied by sponsorship, and sponsorship is never implied by verification. | `LOCKED` |
| A paid, active subscription does not confer a Verified state. | `LOCKED` |
| A sponsored placement does not confer a Verified state and must not be displayed as one. | `LOCKED` |
| An unverified sponsored listing must still be disclosed as unverified. | `LOCKED` |

### 9.2 Possible verification evidence

Approved as a **candidate** evidence set — this is not an exhaustive or final policy:

- phone verification;
- physical location;
- business identity;
- relevant registration / documents where applicable;
- Civilpedia field visit where required.

Status: `PROVISIONAL`

### 9.3 Possible verification states

| State | Status |
|---|---|
| Unverified | `PROVISIONAL` |
| Verification Pending | `PROVISIONAL` |
| Verified | `PROVISIONAL` |
| Verification Suspended | `PROVISIONAL` |

The **state vocabulary** is approved as the intended set; the exact verification
policy, thresholds, evidence per category, turnaround, appeals, and suspension
triggers remain a **later detailed policy** — not decided here.

| Open item | Status |
|---|---|
| Verification policy document and per-category evidence checklists. | `DEFERRED` to a later policy |
| Who may verify, and whether verification is staff-only. | Not decided → open question |
| Whether verification affects organic ranking. | `PROVISIONAL` (see §18.2) |
| Public display of verification state and its exact wording. | `PROVISIONAL` (see §14.5) |

---

## 10. BUSINESS ONBOARDING

### 10.1 Model

| Rule | Status |
|---|---|
| Onboarding is **Hybrid**: Civilpedia may perform substantial setup work, and the business owner completes ownership and identity steps personally. | `LOCKED` |
| Preferred flow: Lead → Agreement → Payment Verified → Civilpedia creates a professional Business Draft → Business owner creates their own Civilpedia User Account → Civilpedia links/invites the owner → Owner accepts Business ownership → Content review → Published. | `LOCKED` (approved sequence) |
| Civilpedia staff must **NOT** create and hand over passwords to business owners. | `LOCKED` |
| The Business remains an entity **separate** from the user's login account. | `LOCKED` |
| A business may exist as a Business Entity before any owner user account exists. | `LOCKED` (implied by the draft/ownership sequence) |
| Exact UI, invitation mechanics, and acceptance screens for ownership transfer-in during onboarding. | `PROVISIONAL` |
| Handling of a pre-existing Civilpedia User Account that later owns a business. | `PROVISIONAL` |
| Whether a User Account is mandatory before publication. | Not decided → open question |
| Rejected/expired lead handling and re-application. | Not decided → open question |

---

## 11. BUSINESS OWNERSHIP / ROLES

### 11.1 Initial role model (commercial product names)

| Role (commercial) | Intent | Status |
|---|---|---|
| Owner | Highest business authority. | `LOCKED` (capability concept, §11.1a) |
| Manager | Business operational / profile management. | `LOCKED` (capability concept, §11.1a) |
| Editor | Content-focused permissions. | `LOCKED` (capability concept, §11.1a) |
| Civilpedia Admin | Platform-side management access, **not** a business membership. | `LOCKED` |

These are **commercial product role names**. They are not asserted to exist as
stored roles, enum values, or permission checks. See §11.1a.

Descriptive intent of each role: `PROVISIONAL`.
Exact permission matrix: **`PROVISIONAL` until Business Center design** — not frozen.

### 11.1a Capability levels vs stored role vocabulary (C-1 — non-authorization)

The commercial product defines three **capability levels** conceptually. These are
`LOCKED` as product intent:

| Capability level | Intent | Status |
|---|---|---|
| Business owner / highest authority | Final business authority. | `LOCKED` (capability concept) |
| Business operational manager | Business operational and profile management. | `LOCKED` (capability concept) |
| Content-focused editor | Content-focused permissions. | `LOCKED` (capability concept) |

The **mapping** from these capability levels to any stored role vocabulary is
explicitly `PROVISIONAL`:

| Mapping element | Status |
|---|---|
| Mapping of Owner → `OWNER`, Manager → `ADMIN`, Editor → `MEMBER`. | `PROVISIONAL` — **illustrative only, not a decision** |
| Whether the existing stored roles are renamed, extended, or left unchanged with the mapping held at the application/policy layer. | `PROVISIONAL` — future RBAC design |
| Whether Manager maps to `ADMIN` alone or to `ADMIN` plus part of `MEMBER`. | `PROVISIONAL` |
| Exact per-capability permission matrix. | `PROVISIONAL` — Business Center design |
| Any new role, enum value, column, RLS policy, or migration. | **Not authorized by this document** |

**Existing backend role definitions are unchanged by this document.**
`business_memberships.role IN ('OWNER','ADMIN','MEMBER')` as used by migration
00019 and the V1-R03 / V1-R06 contracts and their RLS remains exactly as it is.
This document neither renames nor redefines those values. See §1.2 and §24.1 (C-1).

### 11.2 Platform vs business authority

| Rule | Status |
|---|---|
| Civilpedia Admin is platform-side and separate from business membership. | `LOCKED` |
| A user may be a Civilpedia staff member and a business member; the two authorities do not merge. | `LOCKED` |
| No client-side shortcut may replace server authorization for business actions. | `LOCKED` (existing repository rule; preserved) |

### 11.3 Ownership transfer

| Step | Rule | Status |
|---|---|---|
| 1 | Current owner requests transfer. | `LOCKED` |
| 2 | New owner accepts. | `LOCKED` |
| 3 | Civilpedia verifies. | `LOCKED` |
| 4 | Transfer completes. | `LOCKED` |
| — | **No instant, uncontrolled transfer.** | `LOCKED` |
| — | Exact request/accept UI, evidence, timeouts, and rejection handling. | `PROVISIONAL` |
| — | What happens to other memberships when ownership moves. | `PROVISIONAL` |
| — | Co-ownership, multiple simultaneous owners, or an entity without an owner. | Not decided → open question |
| — | Ownership transfer of a Branch independent of the parent entity. | Not decided → open question |

### 11.4 Naming reconciliation summary (C-1)

| Layer | Status |
|---|---|
| Commercial capability levels: owner / highest authority, operational manager, content editor. | `LOCKED` |
| Commercial role product names: Owner, Manager, Editor. | `LOCKED` |
| Stored role vocabulary `OWNER` / `ADMIN` / `MEMBER` in production. | Unchanged; remains engineering-authoritative |
| Mapping between the two. | `PROVISIONAL` — future RBAC design (§11.1a) |
| Any rename, migration, or RLS change. | **Not authorized by this document** |

The two vocabularies are allowed to coexist. Commercial language (sales, customer
communication, Business Center labels) uses Owner / Manager / Editor. Engineering
artifacts keep `OWNER` / `ADMIN` / `MEMBER` until a separately authorized slice
maps them deliberately. This document does not require them to be identical.

---

## 12. SELF-SERVICE + MANAGED SERVICE

| # | Rule | Status |
|---|---|---|
| 12.1 | Businesses may manage their own profiles (self-service). | `LOCKED` |
| 12.2 | Civilpedia may also manage profiles on behalf of customers when requested (managed service). | `LOCKED` |
| 12.3 | This is an **intentional hybrid service model**, not an interim state. | `LOCKED` |
| 12.4 | The Business retains **ownership of its presence and content**. | `LOCKED` |
| 12.5 | Civilpedia controls **platform publication standards, verification, and commercial entitlements**. | `LOCKED` |
| 12.6 | Managed service does not transfer business ownership to Civilpedia. | `LOCKED` |
| 12.7 | Which requests for managed service are accepted, priced, or bundled. | Not decided → open question |
| 12.8 | Whether managed service is recorded in Business Center, and any audit expectations. | `PROVISIONAL` |
| 12.9 | Staff-side tooling and permissioning for managed service. | `PROVISIONAL` (V1-R07 foundation exists) |

---

## 13. EDIT / MODERATION MODEL

### 13.1 Sensitive changes (require review or verification)

| Field class | Examples | Status |
|---|---|---|
| Identity | primary business name | `LOCKED` (sensitive class) |
| Location | principal location | `LOCKED` (sensitive class) |
| Contact | primary phone | `LOCKED` (sensitive class) |
| Classification | primary category | `LOCKED` (sensitive class) |
| Authority | ownership | `LOCKED` (sensitive class) |
| Trust | verification state | `LOCKED` (sensitive class) |
| Exact per-field sensitivity list and which review depth applies to each. | | `PROVISIONAL` |

### 13.2 Routine content (self-service, subject to validation/moderation)

| Field class | Examples | Status |
|---|---|---|
| Availability | hours | `LOCKED` (routine class) |
| Narrative | descriptions | `LOCKED` (routine class) |
| Media | gallery | `LOCKED` (routine class) |
| Catalogue | services / products | `LOCKED` (routine class) |
| Evidence | projects | `LOCKED` (routine class) |
| Promotions | offers | `LOCKED` (routine class) |
| Presence | social links | `LOCKED` (routine class) |
| Whether routine content is published immediately, queued, or sampled for moderation. | | `PROVISIONAL` |
| Automated validation rules, profanity/policy filters, and duplicate detection. | | `PROVISIONAL` |

### 13.3 Pending-review behaviour

| Rule | Status |
|---|---|
| For sensitive changes, the **currently published value is preserved** while the new value is `Pending Review`, whenever practical. | `LOCKED` (with an explicit "whenever practical" qualifier) |
| The "whenever practical" exception set — cases where the published value may be replaced or removed immediately (e.g. illegal content, a verified complaint, safety). | `PROVISIONAL` |
| Review turnaround, reviewer roles, and rejection messaging. | Not decided → open question |
| Change history / audit visibility to the business. | `PROVISIONAL` |

---

## 14. PUBLIC BUSINESS PROFILE

### 14.1 Approved information/visual direction

| Order | Section | Status |
|---|---|---|
| 1 | Gallery | `PROVISIONAL` (approved direction; exact order not frozen) |
| 2 | Identity | `PROVISIONAL` |
| 3 | Primary actions | `PROVISIONAL` |
| 4 | Quick Facts | `PROVISIONAL` |
| 5 | About | `PROVISIONAL` |
| 6 | Products / Services | `PROVISIONAL` |
| 7 | Portfolio / Projects | `PROVISIONAL` |
| 8 | Offers | `PROVISIONAL` |
| 9 | Map / Branches | `PROVISIONAL` |
| 10 | Verification | `PROVISIONAL` |
| 11 | Similar Businesses | `PROVISIONAL` |

The **section set and its sequence** are the approved direction. Final layout,
visual treatment, and responsive behaviour are not frozen and belong to the
authorized UI phases.

### 14.2 Primary actions

| Action | Status |
|---|---|
| WhatsApp | `LOCKED` (required primary action) |
| Call | `LOCKED` |
| Directions | `LOCKED` |
| Save | `LOCKED` |
| Exact placement, priority order, and per-platform affordance. | `PROVISIONAL` |

### 14.3 Never publicly exposed

| Never public | Status |
|---|---|
| Subscription plan name | `LOCKED` |
| Subscription price | `LOCKED` |
| Payment details | `LOCKED` |
| Subscription expiry date | `LOCKED` |
| Internal owner / admin data | `LOCKED` |
| Internal analytics | `LOCKED` |
| Commercial entitlement metadata | `LOCKED` |

### 14.4 Commercial metadata exposure summary

| Item | Publicly visible? | Status |
|---|---|---|
| Paid subscription existence | Implied by presence; the plan/price itself is not exposed. | `LOCKED` |
| Founding Partner | May be visible according to policy. | `PROVISIONAL` |
| Verified | May be visible according to policy. | `PROVISIONAL` |
| Sponsored | Visible **only** when clearly labeled. | `LOCKED` |
| Business analytics | Not public. | `LOCKED` |

### 14.5 Open items

| Open item | Status |
|---|---|
| Exact badge wording, placement, and Arabic copy for Verified / Founding Partner / Sponsored. | `PROVISIONAL` |
| Whether Sponsored labeling appears in search results, category lists, map views, and related-business rails. | `PROVISIONAL` |
| Whether similar-businesses ordering may be influenced commercially. | `PROVISIONAL` — must not become covert organic ranking (§6.1.4) |

---

## 15. CATEGORY-AWARE PROFILE ARCHITECTURE

### 15.1 Architecture decision

| Rule | Status |
|---|---|
| The public business profile is **Core Business Profile + Category Modules**. | `LOCKED` |
| A single generic profile must **not** be forced onto all categories. | `LOCKED` |
| The core profile carries identity, contact, location, verification, and public actions; category modules carry category-specific content. | `LOCKED` |
| Which category modules exist, their exact fields, and their per-plan availability. | `PROVISIONAL` |
| Branch selector and branch-specific detail behaviour. | `PROVISIONAL` |

### 15.2 Approved module direction by category type

| Category type | Directional module content | Status |
|---|---|---|
| Supplier / store | products, brands, delivery, wholesale/retail | `PROVISIONAL` (approved direction) |
| Contractor | services, projects, service area | `PROVISIONAL` |
| Manufacturer | products, technical information, facilities | `PROVISIONAL` |
| Equipment rental | equipment, specifications, operator availability, service area | `PROVISIONAL` |
| Ready-mix | mix/service information, supply areas, pumps/lab | `PROVISIONAL` |
| Waterproofing / MEP / specialist company | systems, services, brands, portfolio | `PROVISIONAL` |
| Multi-branch company | branch selector, branch-specific details | `PROVISIONAL` |

These are approved **directions**, not a frozen module specification. A Business
Center design phase must produce the frozen module contract.

---

## 16. MEDIA

| Rule | Status |
|---|---|
| Business owners can upload their own media. | `LOCKED` |
| Media must support distinct roles/categories rather than one undifferentiated gallery. | `LOCKED` |
| Recognised media roles: `Logo`, `Cover`, `Business Gallery`, `Products`, `Projects`, `Offers`. | `LOCKED` (role set) |
| Media role semantics, ordering, cropping rules, and required/optional status. | `PROVISIONAL` |
| Moderation, rights confirmation, and takedown handling. | `PROVISIONAL` |
| Storage limits, file size/type limits, and external hosting. | Not decided → open question |
| Per-category module media limits. | Not decided → open question |

### 16.1 Current working media baseline (NOT frozen)

| Plan | Working baseline | Status |
|---|---|---|
| Business | 6 images | `PROVISIONAL` |
| Business Pro | 20 images | `PROVISIONAL` |
| Business Plus | 40 images | `PROVISIONAL` |
| Corporate | not defined | `PROVISIONAL` |

These counts are a **current working baseline only**. They must **not** be marked
permanently frozen, presented as contractual limits, or quoted to customers until
an entitlement review is completed and recorded in this document per §1.5.

---

## 17. ANALYTICS

### 17.1 Value principle

| Rule | Status |
|---|---|
| Even the **entry paid plan** must have basic value evidence. | `LOCKED` |
| Analytics must never be described as **confirmed sales**. | `LOCKED` |
| Permitted framing concepts: `Interactions`, `Leads`, `Engagement`. | `LOCKED` (approved vocabulary) |
| Organic and sponsored interactions must be distinguishable and never merged. | `LOCKED` |
| Analytics are visible to the business in Business Center, not publicly (§14.3). | `LOCKED` |

### 17.2 Minimum target analytics

| Metric | Status |
|---|---|
| Profile Views | `PROVISIONAL` (approved V1 target) |
| Call Clicks | `PROVISIONAL` |
| WhatsApp Clicks | `PROVISIONAL` |
| Directions Clicks | `PROVISIONAL` |

Whether these four are guaranteed on **every** paid tier including Business, and the
metric definitions themselves, remain `PROVISIONAL`.

### 17.3 Possible advanced-tier analytics

| Metric | Status |
|---|---|
| Search Appearances | `PROVISIONAL` |
| Saves | `PROVISIONAL` |
| Offer Views | `PROVISIONAL` |
| Top Services | `PROVISIONAL` |
| Traffic Trends | `PROVISIONAL` |
| Area-based interest | `PROVISIONAL` |
| Branch-level analytics | `PROVISIONAL` |

| Open item | Status |
|---|---|
| Retention window, aggregation, and reset behaviour. | Not decided → open question |
| Data export. | `PROVISIONAL` |
| Counting rules: unique vs total, bot filtering, self-view exclusion. | Not decided → open question |
| Privacy/consent handling for viewer-side measurement. | Not decided → open question |

---

## 18. SEARCH / LOCAL DISCOVERY

### 18.1 Locked discovery rules

| # | Rule | Status |
|---|---|---|
| 18.1.1 | **Organic ranking is independent of subscription price.** | `LOCKED` |
| 18.1.2 | No plan tier may buy a better organic position (§6.1.4). | `LOCKED` |
| 18.1.3 | Sponsored placement is structurally separate from organic results and clearly labeled. | `LOCKED` |
| 18.1.4 | Sponsored status is never a relevance filter; users do not filter "sponsored" as a quality signal. | `LOCKED` |
| 18.1.5 | Organic results remain available and complete when there is no active campaign. | `LOCKED` |

### 18.2 Possible organic ranking inputs

Candidate inputs only — **not** an algorithm and **not** a freeze:

- location relevance;
- category match;
- service match;
- profile completeness;
- data quality / freshness.

Status: `PROVISIONAL`. Ranking algorithm design is explicitly out of scope for this
document (consistent with the existing Directory architecture).

### 18.3 Branch-level local discovery

| Rule | Status |
|---|---|
| Branches may appear independently in local search results while remaining part of one Business Entity. | `PROVISIONAL` (approved direction) |
| Selecting a branch keeps the user within the same Business brand/profile relationship. | `PROVISIONAL` |
| Whether a branch result shows branch-only data or entity-level data. | `PROVISIONAL` |
| Branch-level deduplication and cannibalisation handling in results. | Not decided → open question |
| Verification's effect on ranking. | `PROVISIONAL` |
| Example relationship (one brand, multiple named branches) is illustrative, not a data commitment. | `PROVISIONAL` |

---

## 19. PUBLICATION QUALITY

| Rule | Status |
|---|---|
| Payment alone does **not** guarantee publication. | `LOCKED` |
| A **Minimum Profile Quality** standard is required before Public status. | `LOCKED` |
| Civilpedia's judgment of quality remains necessary even where automated validation passes. | `LOCKED` (hybrid service model, §12) |

### 19.1 Expected minimum quality areas

| Area | Status |
|---|---|
| valid business name | `PROVISIONAL` (approved as an expected area) |
| category | `PROVISIONAL` |
| valid contact | `PROVISIONAL` |
| location / service area, as applicable | `PROVISIONAL` |
| logo / cover | `PROVISIONAL` |
| basic description | `PROVISIONAL` |
| minimum media | `PROVISIONAL` |
| at least one meaningful service/product, where applicable | `PROVISIONAL` |

**Exact thresholds remain `PROVISIONAL`.** No count, length, or quality score is
frozen by this document.

| Open item | Status |
|---|---|
| The quantitative Minimum Profile Quality standard and its validation mechanism. | Not decided → open question |
| Per-category variation of the minimum (e.g. manufacturer vs. contractor). | `PROVISIONAL` |
| Consequence of falling below the minimum after publication (demotion, warning, grace). | Not decided → open question |
| Who may approve publication (staff-only vs automated + audit). | Not decided → open question |

---

## 20. BUSINESS CENTER

| Rule | Status |
|---|---|
| Business Center is the **owner-facing, private** management experience. It is not public. | `LOCKED` |
| It is the surface where §12 self-service and §12 managed service meet. | `LOCKED` (architecture intent) |
| Detailed UX and plan entitlements are **NOT frozen**. | `PROVISIONAL` — explicitly unfrozen |

### 20.1 Expected modules

| Module | Status |
|---|---|
| Dashboard | `PROVISIONAL` (expected) |
| Edit Profile | `PROVISIONAL` |
| Gallery / Media | `PROVISIONAL` |
| Products / Services | `PROVISIONAL` |
| Projects / Portfolio | `PROVISIONAL` |
| Offers | `PROVISIONAL` |
| Branches | `PROVISIONAL` |
| Analytics | `PROVISIONAL` |
| Team / Roles | `PROVISIONAL` |
| Subscription / Renewal | `PROVISIONAL` |

The module **set** is the approved expectation. Order, navigation, screens, and
per-plan availability are unfrozen and must be produced by a Business Center design
and contract phase. The existing roadmap slice **V1-R10.5-E — Business + Staff**
remains `LOCKED`; this document does not unfreeze it and does not authorize it.

---

## 21. DEFERRED FEATURES

The following are **explicitly deferred** from the initial Business commercial V1:

| # | Deferred feature | Status |
|---|---|---|
| 21.1 | Public reviews | `DEFERRED` |
| 21.2 | Verified-interaction reviews | `DEFERRED` |
| 21.3 | RFQ (request for quotation) | `DEFERRED` |
| 21.4 | Internal chat / messaging | `DEFERRED` |
| 21.5 | In-app product checkout / e-commerce | `DEFERRED` |
| 21.6 | Service booking | `DEFERRED` |
| 21.7 | Complex pay-per-lead model | `DEFERRED` |
| 21.8 | Automated payment gateway | `DEFERRED` |
| 21.9 | Complex campaign manager | `DEFERRED` |

These may be researched later. `DEFERRED` is not a rejection and not a commitment.
Deferring them does not permit partial, mocked, or placeholder implementations in
the primary Business journey (existing V1 product rule: scope may be limited,
quality may not).

**Consistency check (C-8, unchanged by Amendment A1):** the existing Directory
architecture already excludes reviews, claiming UI, messaging, e-commerce, and
booking from V1. The classifications above are therefore consistent with existing
repository direction; no change was required and none was made. Recorded as
`CONSISTENT / NO ACTION` in §24.1.

---

## 22. PROFESSIONALS / OTHER ENGINEERING SECTORS

### 22.1 Do not automatically apply the Business plan model to individuals

| Category | Status |
|---|---|
| individual structural designers | Do **not** auto-apply — separate commercial research required |
| architects | Do **not** auto-apply |
| electrical designers | Do **not** auto-apply |
| mechanical designers | Do **not** auto-apply |
| MEP professionals | Do **not** auto-apply |
| surveyors | Do **not** auto-apply |
| individual consultants | Do **not** auto-apply |

Governance rule: the Business/Business-Entity/Branch subscription model **must not**
be silently reused for individual professionals. Status: `LOCKED` (boundary).

### 22.2 Do not yet assume an identical model for organisations

| Category | Status |
|---|---|
| engineering offices | `PROVISIONAL` — not assumed identical |
| consulting firms | `PROVISIONAL` |
| testing laboratories | `PROVISIONAL` |
| specialist engineering service providers | `PROVISIONAL` |

These require separate commercial research before any reuse of the Business plan
structure or pricing.

---

## 23. FUTURE STRATEGIC RESEARCH

Recorded as approved research directions. None of these is a decision, a price, or
a roadmap commitment.

### A. Professional marketplace model

Scope: designers, surveyors, engineers, freelancers, consultants.
Status: `DEFERRED` (research planned).

### B. Engineering organization model

Scope: design offices, consulting offices, laboratories, BIM firms, geotechnical
companies, NDT / testing, QS / cost services, supervision, specialist engineering
services.
Status: `DEFERRED` (research planned).

### C. Civilpedia Construction Ecosystem

A deep strategic study of whether Civilpedia can become an end-to-end construction
ecosystem spanning knowledge, tools, project workflows, professionals, suppliers,
contractors, services, equipment, testing, jobs, RFQ, and other valuable
construction workflows.
Status: `DEFERRED` (strategic study). Note: RFQ itself is `DEFERRED` (§21); it may
appear in this ecosystem study only as a studied possibility.

---

## 24. CONFLICTS, DEPENDENCIES, AND OPEN QUESTIONS

### 24.1 Conflict registry (reconciled by Amendment A1)

Amendment A1 reconciled C-1…C-10 **without changing any Owner-approved commercial
intent** and **without modifying any production artifact**. Each conflict is
resolved by **separating commercial policy authority from implementation
authority** (§1.2), not by editing code, migrations, contracts, or the roadmap.

| ID | Conflict | Commercial V1 position (unchanged intent) | Existing artifact (unchanged) | Resolution | Status |
|---|---|---|---|---|---|
| C-1 | Business role vocabulary | Three capability levels: owner / operational manager / content editor (§11.1, §11.1a) | `business_memberships.role IN ('OWNER','ADMIN','MEMBER')` in migration 00019; V1-R03 / V1-R06 contracts and RLS | Capability concepts `LOCKED`; mapping to stored enum names `PROVISIONAL`; no DB enum name locked; no migration authorized | `RESOLVED BY AUTHORITY SEPARATION` |
| C-2 | Plan catalog vocabulary | Business, Business Pro, Business Plus, Corporate with approved durations and prices (§3) | `lib/core/access/plan_type.dart`, `plan_tier.dart`; `plans` table in migration 00008 | Commercial catalog and prices `LOCKED`; mapping onto PlanType / PlanTier / plans / entitlements `PROVISIONAL`, deferred to a future monetization architecture task; no enum/schema migration authorized | `RESOLVED BY COMMERCIAL/IMPLEMENTATION MAPPING SEPARATION` |
| C-3 | Subscription state vocabulary | Three separate conceptual workflows: onboarding/publication, payment, entitlement lifecycle (§8.2) | `subscriptions.status` CHECK `trialing, active, past_due, canceled, paused` in migration 00008 | No single `subscription_status` enum implied; exact state machines, enum names, persistence fields, and mapping to existing CHECK values `PROVISIONAL`; existing backend state definitions unchanged; LOCKED behaviors preserved (§8.3.1–§8.3.5, §7.2) | `RESOLVED BY STATE-MACHINE SEPARATION` |
| C-4 | Sponsored launch timing | Sponsored is an approved commercial product with approved pricing and rules (§6) | Directory architecture: Sponsored architecture-only in V1; `LocalAdDataSource` returns mock ads; plan-coupled seed | Product definition `APPROVED / LOCKED`; production implementation `DEFERRED`; mocks/seed/architecture are **not** the commercial product; implementation requires a future authorized monetization slice | `RESOLVED — PRODUCT APPROVED / IMPLEMENTATION DEFERRED` |
| C-5 | Founding Partner / commercial-like Directory fields | Founding Partner: first 50, first year only, badge may be permanent, discount is not (§5) | `foundingPartner`, `featured`, `planType` embedded in the Directory entity model; Founding Partner deliberately not modeled in 00008; flagged "premature / needs re-parenting" | Existing fields are **non-canonical** legacy implementation details; preserved unchanged; canonical storage design and re-parenting `PROVISIONAL`; no removal/rename/backfill authorized | `RESOLVED — EXISTING FIELDS NON-CANONICAL` |
| C-6 | Brand / Business / Branch modeling | Conceptual model Brand → Business Entity → Branch; User → Membership → Entity is `LOCKED` (§2.2, §2.3) | Directory architecture models a single entity; no Brand layer; no Branch-as-location entity | Concept `LOCKED`; tables, foreign keys, branch/location modelling, Brand persistence, ownership mappings, and migration design `PROVISIONAL`; no schema exists because of this document | `RESOLVED — CONCEPT LOCKED / SCHEMA PROVISIONAL` |
| C-7 | V1 scope boundary | Commercial model is planning authority only | Roadmap CORE ARCHITECTURE RULE 17: monetization/payments remain outside V1 unless the Owner explicitly promotes them | Roadmap authority preserved verbatim; monetization implementation remains outside currently authorized V1 scope unless separately opened by the Master Roadmap / Architect; this document is not implementation authorization | `RESOLVED — ROADMAP AUTHORITY PRESERVED` |
| C-8 | Reviews / RFQ / booking / messaging / e-commerce | Explicitly `DEFERRED` (§21) | Directory V1 already excludes reviews, claiming-UI, messaging, e-commerce, booking | Classifications consistent; no change | `CONSISTENT / NO ACTION` |
| C-9 | Paid-Only rule vs existing seed/mock listings | Paid-Only applies to the future Commercial Production Directory, together with Publication Quality (§2.1, §2.5) | Directory seed contains public listings and is plan-coupled to monetization scaffolding | Paid-Only does not require immediate removal of development/mock/seed/fixture/preview data; such data may continue during development; launch-time disposition of existing rows remains undecided and `PROVISIONAL` | `RESOLVED — COMMERCIAL PRODUCTION VS DEV/SEED DISTINCTION` |
| C-10 | Roadmap header vs phase-control inconsistency | Not a commercial matter | Roadmap `ROADMAP HEADER` `CURRENT_PHASE_ID: V1-R10` vs `CURRENT PHASE CONTROL` R10.5-D | Not fixed here; the Commercial document does not rewrite roadmap authority; tracked as separate housekeeping | `DEFERRED TO SEPARATE GOVERNANCE CLEANUP` — **NON-BLOCKING TO COMMERCIAL SSOT** |

**Unresolved blocking conflicts: none.** No genuinely new contradiction was found
during Amendment A1. Every remaining implementation question is explicitly
`PROVISIONAL` and routed to a future authorized slice (§24.2) or recorded as an
open question (§24.3).

### 24.2 Dependencies (not conflicts)

| ID | Dependency | Note |
|---|---|---|
| D-1 | Business Center design phase | Required before §11 permission matrix, §15 modules, §16 media, §20 UX can be frozen. |
| D-2 | Verification policy | Required before §9 evidence, states, and display can be frozen. |
| D-3 | Entitlement review | Required before §16 media baselines and the §3 tier matrix can be frozen. |
| D-4 | Monetization slice (honest ad/campaign gating) | Required before §6 Sponsored can be implemented or shown to users. |
| D-5 | Arabic-first localization SSOT | Any customer-facing commercial string (badges, plan names, states) must enter the localization SSOT, not hardcoded copy. |
| D-6 | Future RBAC design slice | Required before any capability-level → stored-role mapping is frozen (C-1). |
| D-7 | Future monetization architecture slice | Required before commercial catalog → PlanType/PlanTier/plans mapping is frozen (C-2). |
| D-8 | Future entitlement/persistence design slice | Required before §8 state machines and §2.3 Brand/Branch persistence are frozen (C-3, C-6). |


### 24.3 Open questions — undefined by the Owner (must not be invented)

1. Founding Partner price for 1-month and 3-month first terms.
2. Mechanism and evidence for the "first 50 businesses" Founding Partner counter.
3. Extra Branch add-on price for a 3-month term; maximum branch cap; behaviour past the cap.
4. Corporate plan contents, minimum term, and quotation process.
5. Renewal pricing and whether renewal differs from first purchase.
6. Upgrade / downgrade mid-term, proration, and downgrade when branch count exceeds the tier.
7. Refund, cancellation, and no-show policy.
8. Invoicing, fiscal/tax treatment, and accounting export.
9. Accepted transfer rails, bank accounts, and supported currencies.
10. Anti-fraud controls beyond independent receipt verification.
11. Which staff roles may confirm payment and activate a subscription.
12. Grace Period exact duration and behaviour inside it.
13. Verification evidence per category; verification turnaround; appeals.
14. Exact public wording/placement of Verified, Founding Partner, and Sponsored badges.
15. `CP-BIZ-xxxxx` / `CP-PAY-xxxxx` generation rules and visibility surface.
16. Media storage limits and per-category module media limits.
17. Analytics retention, counting rules, and export.
18. Sponsored inventory: hard cap vs target; definition of "Area"; oversubscription policy.
19. A Branch that is a separately owned legal entity inside a shared brand.
20. Multiple simultaneous owners, or an entity temporarily without an owner.
21. Whether a User Account is mandatory before a business can be published.
22. Launch-time disposition of existing and seed public listings under the paid-only rule (§2.5, C-9).
23. Plan catalog code values and price storage/currency representation.
24. Whether managed service (§12) is ever separately priced.

### 24.4 Change log (append-only)

| Date | Authority | Change | Previous | New | Implementation / sales impact |
|---|---|---|---|---|---|
| 2026-09-27 | Owner + ChatGPT Architect | Document created as Commercial Model V1 SSOT | none | Initial consolidation of §1–§25 | Documentation only. No production change. No sales change until separately communicated. |
| 2026-09-27 | ChatGPT Architect | **Amendment A1 — Conflict reconciliation (C-1…C-10)** | C-1…C-10 recorded as unresolved conflicts requiring Architect decisions | Added §1.2 commercial-policy vs implementation-authority rule; added §2.3, §2.5, §3.5, §5.8, §6.4, §8.2, §8.4, §11.1a, §11.4 reconciliation sections; restructured §8 into three separate conceptual workflows; rewrote §24.1 as a resolved conflict registry; updated §25 registry | **No commercial intent changed.** No production code, test, migration, Supabase, roadmap, or UI-contract change. No implementation authorized. |

---

## 25. FINAL STATUS — DECISION REGISTRY

Registry state after **Amendment A1** (2026-09-27). Amendment A1 reconciled
implementation-mapping conflicts and did **not** change any commercial intent, so
no previously approved rule was downgraded, removed, or reclassified. New entries
below record the authority-separation rules and the implementation mappings that
are deliberately `PROVISIONAL`.

### 25.1 LOCKED

| # | Locked decision |
|---|---|
| L-01 | Public Business Directory is paid-only. |
| L-02 | No permanent free public listing. |
| L-03 | Business subscription belongs to the Business Entity, not the User Account. |
| L-04 | Brand, Business Entity, Branch, and User are distinct concepts. |
| L-05 | One ownership + one operating business → one subscription with multiple branches. |
| L-06 | Same brand, independently owned/operated → separate entities and separate subscriptions. |
| L-07 | Plan structure: Business, Business Pro, Business Plus, Corporate. |
| L-08 | Durations: 1 month, 3 months, 12 months. |
| L-09 | Current approved price list (§3.2). |
| L-10 | Business Pro is the primary/default commercial recommendation. |
| L-11 | Included branches: 1 / 2 / 3 / custom. |
| L-12 | Extra branches use an Add-on model, not a second subscription. |
| L-13 | Founding Partner limited to the first 50 businesses, first year only. |
| L-14 | Founding Partner badge/history may be permanent; the discount is not. |
| L-15 | Founding Partner first-year prices (§5.7). |
| L-16 | Sponsored is a separate product, not subscription/verification/organic ranking. |
| L-17 | Sponsored pricing (§6.2) and initial Pro/Plus availability. |
| L-18 | Sponsored must be visibly labeled; inventory limited by Category × Area. |
| L-19 | Organic ordering must not be purchasable through a higher subscription tier. |
| L-20 | Commercial V1 payment flow: WhatsApp → agreement → instructions → transfer → receipt → pending verification → verified → active. |
| L-21 | A screenshot/receipt is not final proof; activation only after independent verification. |
| L-22 | Never request/distribute full 16-digit PAN (unless a future regulated flow formally requires it), CVV, PIN, OTP, expiry date. |
| L-23 | Internal references `CP-BIZ-xxxxx` and `CP-PAY-xxxxx`. |
| L-24 | Commercial lifecycle vocabulary: Draft, Payment Pending, Payment Verified, Active, Grace Period, Expired — a commercial concept, **not** a single database enum (§8.1, §8.4). |
| L-25 | Expiration never deletes the Business; data/media/products/projects/ownership are retained. |
| L-26 | After Grace Period, an expired business is hidden from the public directory. |
| L-27 | Renewal restores publication without rebuilding the profile. |
| L-28 | PAID ≠ VERIFIED ≠ SPONSORED; payment never purchases verification. |
| L-29 | Hybrid onboarding; staff never hand over passwords; Business ≠ user account. |
| L-30 | Initial commercial role names and capability levels: Owner (highest authority), Manager (operational), Editor (content-focused). Civilpedia Admin is platform-side and separate. Mapping to stored roles is `PROVISIONAL` (§11.1a). |
| L-31 | Ownership transfer is a controlled request → acceptance → verification workflow; never instant. |
| L-32 | Hybrid self-service + managed service; the business owns its content; Civilpedia owns publication standards, verification, and entitlements. |
| L-33 | Sensitive change classes: primary name, principal location, primary phone, primary category, ownership, verification state. |
| L-34 | Routine self-service classes: hours, descriptions, gallery, services/products, projects, offers, social links. |
| L-35 | Sensitive changes preserve the published value while the new value is Pending Review, whenever practical. |
| L-36 | Primary public actions: WhatsApp, Call, Directions, Save. |
| L-37 | Never public: plan name, price, payment details, expiry, internal owner/admin data, internal analytics, entitlement metadata. |
| L-38 | Sponsored is publicly visible only when clearly labeled. |
| L-39 | Profile architecture = Core Business Profile + Category Modules; no single generic profile for all categories. |
| L-40 | Owners upload their own media; media supports distinct roles (Logo, Cover, Business Gallery, Products, Projects, Offers). |
| L-41 | Entry paid plan must carry basic value evidence; analytics are never "confirmed sales"; use Interactions / Leads / Engagement. |
| L-42 | Organic ranking is independent of subscription price. |
| L-43 | Payment alone does not guarantee publication; a Minimum Profile Quality standard is required. |
| L-44 | Business Center is the private owner-facing management experience. |
| L-45 | The Business plan model must not be silently applied to individual professionals or assumed identical for engineering organisations. |
| L-46 | Every future commercial change must update this document explicitly; conversation history is not a source of truth. |
| L-47 | Commercial policy authority ≠ implementation authority (§1.2). This document authorizes no code, schema, enum, migration, RLS, routing, auth, persistence, billing, Directory-architecture, or roadmap-scope change. |
| L-48 | Paid-Only applies to the future Commercial Production Directory and does not require removal of development/mock/seed/fixture/preview data (§2.5). |
| L-49 | Conceptual Brand → Business Entity → Branch, and User → Business Membership → Business Entity, are locked as concepts only; no table, key, or migration is implied (§2.3). |
| L-50 | Publication, payment, and entitlement lifecycles are three separate conceptual workflows composed by a single visibility rule (§8.2). |
| L-51 | Existing commercial-like Directory fields/markers (e.g. `featured`, `planType`, Founding-Partner-like markers) are non-canonical legacy implementation details and are preserved unchanged (§5.8). |
| L-52 | Roadmap remains the sole phase/implementation authority; monetization implementation stays outside the currently authorized V1 scope unless separately opened by the Master Roadmap / Architect (§24.1 C-7). |
| L-53 | Existing backend role values, plan enums, `plans` table, and `subscriptions.status` definitions are unchanged by this document (C-1, C-2, C-3). |
| L-54 | Sponsored is an approved commercial product with no current production behavior; mock/seed/architecture artifacts are not the commercial product (§6.4). |

### 25.2 PROVISIONAL

| # | Provisional item |
|---|---|
| P-01 | Extra Branch pricing (exploratory 10,000–15,000 IQD/month, 100,000–150,000 IQD/year — not final). |
| P-02 | Corporate plan branch count and contents. |
| P-03 | Plan entitlement matrix per tier (beyond branches and media). |
| P-04 | Grace Period duration (target ~3–7 days). |
| P-05 | Management access behaviour inside Grace Period. |
| P-06 | Sponsored inventory target (~2–3 per Category × Area) and "Area" definition. |
| P-07 | Role intent descriptions and the exact permission matrix (until Business Center design); see also P-25. |
| P-08 | Ownership-transfer mechanics detail. |
| P-09 | Managed-service acceptance/pricing. |
| P-10 | Per-field sensitivity depth and review mechanics; the "whenever practical" exception set. |
| P-11 | Public profile section set is the approved direction; exact layout/order not frozen. |
| P-12 | Public visibility of Verified and Founding Partner badges. |
| P-13 | Category module field sets and per-plan availability. |
| P-14 | Media baseline counts: Business 6, Business Pro 20, Business Plus 40 — explicitly not frozen. |
| P-15 | Minimum target analytics (Profile Views, Call Clicks, WhatsApp Clicks, Directions Clicks) and their definitions. |
| P-16 | Advanced analytics set (Search Appearances, Saves, Offer Views, Top Services, Traffic Trends, Area interest, Branch-level). |
| P-17 | Organic ranking candidate inputs (not an algorithm). |
| P-18 | Branch-level local discovery behaviour. |
| P-19 | Minimum Profile Quality areas and thresholds. |
| P-20 | Business Center module set and expected UX. |
| P-21 | Verification evidence set and the intended state vocabulary (policy is deferred to a later document). |
| P-22 | Founding Partner counting mechanism; price for 1/3-month first terms. |
| P-23 | Brand / Branch identity model at data level — full provisional scope in P-26. |
| P-24 | Effective annual discount structure (derived observation, not a stated policy). |
| P-25 | Exact RBAC enum mapping: capability levels (owner / operational manager / content editor) ↔ stored roles `OWNER` / `ADMIN` / `MEMBER`; and the future RBAC design (C-1, §11.1a). |
| P-26 | Exact DB schema for Brand, Business Entity, Branch, and Memberships: tables, foreign keys, branch/location modelling, Brand persistence, ownership mappings, and migration design (C-6, §2.3). |
| P-27 | Exact plan enum/table mapping: commercial catalog ↔ `PlanType`, `PlanTier`, `plans` table, and entitlement records; requires a future monetization architecture task (C-2, §3.5). |
| P-28 | Exact onboarding/publication state machine and its persistence (§8.2 A, §8.4). |
| P-29 | Exact payment state machine and its persistence (§8.2 B, §8.4). |
| P-30 | Exact subscription entitlement state machine, its persistence, and the mapping to existing `subscriptions.status` CHECK values (C-3, §8.4). |
| P-31 | Entitlement implementation: storage, enforcement points, and feature gating mechanics. |
| P-32 | Backend Sponsored implementation: campaign gating, inventory control, labeling, and sponsored-vs-organic tracking (C-4, §6.4). |
| P-33 | Exact moderation mechanics beyond the `LOCKED` sensitive/routine classification (§13.1, §13.2). |

### 25.3 DEFERRED

| # | Deferred item |
|---|---|
| D-01 | Public reviews. |
| D-02 | Verified-interaction reviews. |
| D-03 | RFQ. |
| D-04 | Internal chat / messaging. |
| D-05 | In-app product checkout / e-commerce. |
| D-06 | Service booking. |
| D-07 | Complex pay-per-lead model. |
| D-08 | Automated payment gateway. |
| D-09 | Complex campaign manager. |
| D-10 | Detailed verification policy document. |
| D-11 | Professional marketplace commercial model (designers, surveyors, engineers, freelancers, consultants). |
| D-12 | Engineering organisation commercial model (design offices, consulting offices, laboratories, BIM, geotechnical, NDT/testing, QS/cost, supervision, specialist services). |
| D-13 | Civilpedia end-to-end Construction Ecosystem strategic study. |
| D-14 | Sponsored **production implementation** (C-4). The commercial product definition and pricing remain `LOCKED`; only the build is deferred to a future authorized monetization slice. |

### 25.4 Standing prohibitions

1. Do not convert a `PROVISIONAL` number into a `LOCKED` decision, a customer
   quote, or a contractual limit without an explicit update per §1.5.
2. Do not invent a missing business rule. Use §24.3 and escalate to the Architect.
3. Do not treat conversation history as authority.
4. Do not implement, migrate, or refactor against this document without an
   authorized phase, frozen contract, and `IMPLEMENTATION_AUTHORIZED: YES`.
5. Do not expose commercial metadata publicly (L-37).
6. Do not let paid status imply verification or organic rank (L-28, L-42).
7. Do not treat a `LOCKED` commercial concept as authorization to create a schema
   object, enum value, field, route, flag, or entitlement (L-47, §1.2).
8. Do not rename, remap, or migrate existing backend role values, plan enums,
   `plans`/`subscriptions` definitions, or Directory commercial-like fields under
   this document (L-51, L-53).
9. Do not present dev/mock/seed/fixture listings as Commercial Production
   Directory eligibility evidence, and do not enforce Paid-Only against them during
   development (L-48, §2.5).
10. Do not surface Sponsored, mock ads, or plan-coupled seed as delivery of the
    commercial Sponsored product (L-54, D-14).

### 25.5 Registry counts (informational)

| Classification | Count |
|---|---|
| `LOCKED` | 54 |
| `PROVISIONAL` | 33 |
| `DEFERRED` | 14 |
| Unresolved blocking conflicts | 0 |

Counts are informational. The tables in §25.1–§25.3 are the authority.

---

END OF DOCUMENT
