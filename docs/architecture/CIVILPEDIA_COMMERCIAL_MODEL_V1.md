# CIVILPEDIA — COMMERCIAL MODEL V1 (CANONICAL SSOT)

DOCUMENT_ID: `CIVILPEDIA_COMMERCIAL_MODEL_V1`
DOCUMENT_STATUS: ACTIVE DESIGN — CANONICAL COMMERCIAL SSOT — **NOT YET FROZEN**
FREEZE_STATE: NOT FROZEN. Commercial Model V1 is **not** complete, **not** final, and **not** frozen. See §1.6 (Document maturity and freeze status) and the Open Question register in §24.3.
DOCUMENT_AUTHORITY: OWNER + CHATGPT ARCHITECT (commercial decisions)
SCOPE: Documentation / consolidation only
IMPLEMENTATION_AUTHORIZED: NO — this document does not authorize any code, schema, contract, or phase change
BASELINE_COMMIT: `30aa1b23` (V1-R10.5-C closed / accepted)
ROADMAP_PHASE_AT_BASELINE: V1-R10 UI/UX & Core App Experience — R10.5-D CURRENT (pre-implementation audit only); R10.5-E Business + Staff LOCKED
SOURCE_OF_DECISIONS: Owner-approved commercial decisions consolidated by the Architect; conversation history is NOT a source of truth
AMENDMENT: A1 — Conflict Reconciliation (2026-09-27), authority: ChatGPT Architect. Reconciles C-1…C-10 by authority separation. No commercial intent changed. No production, schema, contract, or roadmap change authorized or performed.
AMENDMENT: A2 — Register Integrity + Documentary Corrections (2026-09-28), authority: ChatGPT Architect. **Register/governance amendment only.** Rebuilds the Open Question register (§24.3) so that every in-body unresolved commercial marker carries a registered Open Question ID, adds freeze-triage metadata (severity / owner / classification), corrects one LOCKED-rule **wording** contradiction in §2.4 (branch billing vs the approved Extra Branch add-on model), and records the document maturity as **ACTIVE DESIGN / NOT YET FROZEN**. A2 **creates no commercial decision, resolves no open question, changes no price, and changes no commercial intent.** No production, test, migration, Supabase, contract, UI, or roadmap change authorized or performed.

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
   Agents and authors must not invent it. Every such record must carry a
   registered Open Question ID (`OQ-nn`) and an in-body marker must cite that
   ID — see rule 6.
4. `DEFERRED` means "not in Commercial V1", not "rejected".
5. Commercial policy status is independent of implementation status. A concept or
   value may be `LOCKED` as policy while its database, enum, schema, or UI
   representation remains `PROVISIONAL` or unimplemented (§1.2).
6. **Open Question ID rule (mandatory, added by Amendment A2).** Any in-body
   marker that leaves a commercial rule unresolved — "Not decided",
   "not stated by the Owner", "Not defined", "→ open question", or any
   equivalent wording — **must** cite a registered `OQ-nn` ID from §24.3 in the
   same row or sentence. §24.3 is the single authoritative register of unresolved
   commercial rules. An unresolved marker without a registered `OQ-nn` ID is a
   **document defect**: it must be repaired by registering the item, not by
   answering it.
7. **Freeze rule (mandatory, added by Amendment A2).** While any §24.3 entry
   carries the classification `MUST RESOLVE BEFORE FREEZE`, this document is
   **NOT FROZEN** and must not be described as complete, final, closed, or
   approved for freeze (§1.6).

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
6. Amendment A2 adds a **register obligation**: the change log entry must also
   confirm that every new in-body unresolved marker cites a registered
   `OQ-nn` ID, or that no such marker was added (§1.3 rule 6).

**Known documentary gap (registered, not decided — Amendment A2).** This document
contains **no Terms, Privacy, or business-agreement policy register**. The policy
areas that will eventually require such language are identified in the audit that
prompted A2 and are registered as a single Owner decision — `OQ-41`. A2 does not
create, enumerate as decided, or pre-empt that register.

### 1.6 Document maturity and freeze status (added by Amendment A2)

| Statement | Meaning | Status |
|---|---|---|
| This document is the **CANONICAL COMMERCIAL SSOT**. | It is the only authority for the commercial model. | `LOCKED` (governance fact) |
| Its state is **ACTIVE DESIGN**. | Commercial content is still being designed and amended. | `LOCKED` (governance fact) |
| It is **NOT YET FROZEN**. | Commercial Model V1 is **not** complete, **not** final, and **not** closed. | `LOCKED` (governance fact) |

Consequences, mandatory:

1. No agent, document, message, or sales material may describe Commercial
   Model V1 as complete, final, frozen, closed, approved-for-freeze, or
   "the finished commercial model".
2. Values marked `PROVISIONAL` remain unquotable (§1.3 rule 2), and this
   remains true regardless of document maturity.
3. Freeze requires, at minimum:
   a. zero §24.3 entries classified `MUST RESOLVE BEFORE FREEZE`;
   b. every in-body unresolved marker citing a registered `OQ-nn` ID
      (§1.3 rule 6); and
   c. an explicit Owner update to this document per §1.5 that states the
      freeze. Only the Owner may declare the freeze.
4. A freeze declaration is a **commercial** act and is separate from
   implementation authority, which remains unchanged (§1.2, L-47).
5. The Open Question register in §24.3 is the **authoritative freeze-triage
   instrument**. Its severity, owner, and classification fields exist to make
   readiness reviewable; they are triage metadata and are not themselves
   commercial decisions.
6. **Terminology collision (registered, not decided).** "Owner" denotes both the
   business capability role (§11.1, §11.1a) and the document decision authority
   (§1.3, §1.5). This document does **not** resolve the collision and no glossary
   term may be introduced by an agent — `OQ-63`. Until it is decided, an agent
   must not infer a decision authority from the business role.
7. **Document housekeeping.** No named custodian and no next-review date are
   recorded for this SSOT — `OQ-70`. This is documentary only and has no
   commercial effect.

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
| A Branch is a location of a Business Entity (multi-location business). | A Branch is **not** a separately owned and **not** a separately subscribed Business Entity: it never requires its own complete Business subscription merely because it is a location. **Additional branches beyond the plan's included count may carry approved Extra Branch add-on pricing under the parent Business subscription** (§4.2). Wording corrected by Amendment A2; commercial intent unchanged. | `LOCKED` |
| Whether a Branch may ever be a separately owned legal entity inside a shared brand. | Not decided — `OQ-19`. | `PROVISIONAL` — see §24.3 |
| Branch as a first-class searchable/local-discovery unit while remaining part of one Business Entity. | Approved direction. | `PROVISIONAL` — see §18 |

### 2.5 Paid-Only scope: commercial production vs development data (C-9)

| Rule | Status |
|---|---|
| Paid-Only applies to the **future Commercial Production Directory**. | `LOCKED` |
| Paid-Only does **not** require immediate removal of development listings, mock listings, seed data, test fixtures, or preview/demo businesses. | `LOCKED` |
| Existing seed/mock/development data may continue to exist and be used during development. | `LOCKED` |
| Before commercial production launch, public production eligibility must follow the Paid-Only rule (§2.1) **and** the Publication Quality rule (§19). | `LOCKED` |
| The disposition of specific existing non-production rows at launch (convert, grandfather, or remove) remains undecided — `OQ-22`. | `PROVISIONAL` — open question §24.3 |
| Any enforcement, conversion, or cleanup action on existing data. | `PROVISIONAL` — requires a separately authorized slice |
| Launch density and sequencing: minimum paid businesses required per Category × Area before an area opens publicly, category rollout order, launch geography, and the user experience of an empty category or area. | Not decided → `OQ-37` |
| Which directory categories are eligible for a paid Business listing, and which are withheld pending the deferred professional/organisation models (§22). | Not decided → `OQ-26` |

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

The commercial **consequences** of a future price change are not decided and are
not implied by the sentence above: the effective moment of a change, its effect on
an already-paid unexpired term, its effect on the next renewal, and the customer
notice period and channel. → `OQ-28`. Whether instalment or deferred payment is
permitted at all is also not decided → `OQ-60`.

### 3.3 Default recommendation

| Rule | Status |
|---|---|
| Business Pro is the intended primary/default commercial recommendation. | `LOCKED` |
| Where, how, and in what wording that recommendation is surfaced (sales material, Business Center, comparison tables). | `PROVISIONAL` |
| Plan feature/entitlement matrix per tier beyond branches (§4) and media (§16). | `PROVISIONAL` — entitlement review (dependency D-3; registry P-03). This item is **not** an Owner open question; it is an entitlement-review dependency. |
| Corporate plan contents, minimum commitment, and quotation process. | `PROVISIONAL` — `OQ-04` |
| Discounts for multi-year, early payment, or volume beyond Founding Partner, and whether discounts stack. | Not decided — `OQ-42`. → `PROVISIONAL` / open question |

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
stays, is not stated by the Owner → `OQ-42`. → `PROVISIONAL`

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
| Whether a 3-month extra-branch price exists. | Not decided → `OQ-03` |
| Maximum branch count per entity, and behavior past the cap. | Not decided → `OQ-03` |
| Whether extra-branch pricing differs by city/area or branch type. | Not decided → `OQ-64` |
| Whether extra branches are transferable/resettable annually. | Not decided → `OQ-65` |

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
| Founding Partner price for a 1-month or 3-month first term. | Not decided → `OQ-01` (§24.3) |
| How the "first 50" counter is defined, incremented, and evidenced. | Not decided → `OQ-02` |
| What happens to businesses #51+ (standard pricing is implied, execution detail is not decided). | `PROVISIONAL` — see `OQ-02` |
| Whether the Founding Partner badge appears on search results, profile, and Business Center. | `PROVISIONAL` — see `OQ-14` |
| Whether Founding Partner is re-offered in a later cohort. | Not decided → `OQ-66` (`DEFERRED`-adjacent) |

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
| 6.1.11 | Minimum advertiser eligibility (whether a Verified state is required to buy a placement) and the prohibited advertiser categories / prohibited advertising content. | Not decided → `OQ-34` |

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
| Whether 2–3 is a hard cap, a soft target, or queue-based. | Not decided → `OQ-18` |
| How "Area" is defined for inventory purposes (governorate / district / custom radius). | Not decided → `OQ-18` |
| Oversubscription behaviour, rotation, and fairness policy. | Not decided → `OQ-18` |
| Campaign management tooling, creative rules, and disclosure copy. | `DEFERRED` (§21) |
| Sponsored renewal, cancellation, and refund terms, and the commercial outcome when an advertised entity becomes unavailable mid-campaign. | Not decided → `OQ-33` |

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
| 7.2.5 | The commercial **outcome** rules for payment exceptions (short, long, wrong account/agent, duplicate claim of one transfer, third-party payer, payment for an Expired or closed business). The 10th step above is reached only from a `Payment Verified` state and is never a bypass. | Not decided → `OQ-31` |
| 7.2.6 | Retention period, access control, business-facing visibility, and deletion of transfer receipts, business registration files, identification documents, and internal staff notes. | Not decided → `OQ-40` |

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
| Accepted bank accounts / transfer rails, supported currencies, and settlement accounts. | Not decided → `OQ-09` |
| Invoicing, receipts, tax/fiscal treatment, and accounting export. | Not decided → `OQ-08` |
| Refund, cancellation, and partial-refund policy. | Not decided → `OQ-07` |
| Anti-fraud controls beyond receipt verification (duplicate transfer, mismatched amount, third-party payer). | Not decided → `OQ-10` |
| Customer-outcome rules for payment exceptions: short payment, overpayment, wrong account/agent, duplicate claim of one transfer, third-party payer, and payment for an Expired or closed business. | Not decided → `OQ-31` |
| Staff handling rules for payment conversations (who may confirm, who may activate), and the expected verification turnaround. | Not decided → `OQ-11`, `OQ-62` |

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

**Known vocabulary gap (registered, not decided — Amendment A2).** The approved
vocabulary above has **no state for administrative suspension or termination for
policy violation**, and it has no date-anchor rule (no defined term start, end,
or renewal date). Both gaps are registered as `OQ-25` and `OQ-30` (§8.3.13,
§8.3.15) and are **not** resolved here. No state may be added, renamed, or
inferred to close them.

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
| Rejected / unresolved | Only where a later defined policy introduces it. | `PROVISIONAL` / not defined → `OQ-31` |

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
| 8.3.6 | Grace Period exact duration. | `PROVISIONAL` — `OQ-12` |
| 8.3.7 | Current Grace Period target: approximately **3–7 days**. | `PROVISIONAL` — target, not frozen — `OQ-12` |
| 8.3.8 | Whether management access continues during Grace Period (read/write), and what the owner sees. | `PROVISIONAL` — `OQ-12` |
| 8.3.9 | Renewal pricing, upgrade/downgrade mid-term, proration, and downgrade when branch count exceeds the new tier. | Not decided → `OQ-05`, `OQ-06` |
| 8.3.10 | Whether an expired business retains analytics history and internal records visibility. | Not decided → `OQ-17` |
| 8.3.11 | Grace-period expiry notices, channels, and language (Arabic-first). | Not decided → `OQ-29` |
| 8.3.12 | State-machine / persistence mapping to existing production state values. | `PROVISIONAL` — reconciled as C-3, see §8.4 |
| 8.3.13 | Subscription term anchor: when the paid term starts, when it ends, and when the renewal date falls. | Not decided → `OQ-25` |
| 8.3.14 | Renewal mechanics: whether renewal must remain manual through WhatsApp / manual payment verification, whether auto-charge is prohibited or merely deferred, and whether stored payment instruments are excluded from Commercial V1; plus early-renewal term extension and renewal notice cadence. | Not decided → `OQ-29` |
| 8.3.15 | Administrative suspension and termination for policy violation, including who may suspend, public visibility, whether the term clock pauses, money outcome, appeal, and re-entry condition. | Not decided → `OQ-30` |
| 8.3.16 | Permanent business closure as a commercial event distinct from expiry, including its effect on subscription, prepaid funds, badges, sponsorship, data, and reactivation. | Not decided → `OQ-36` |

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
triggers remain a **later detailed policy** — not decided here (`OQ-13`).

| Open item | Status |
|---|---|
| Verification policy document and per-category evidence checklists. | `DEFERRED` to a later policy — `OQ-13` |
| Who may verify, and whether verification is staff-only. | Not decided → `OQ-50` |
| Whether verification affects organic ranking. | `PROVISIONAL` (see §18.2) |
| Public display of verification state and its exact wording. | `PROVISIONAL` (see §14.5) — `OQ-14` |
| Verification validity period, reverification triggers, whether renewal requires re-verification, verification granularity for multi-branch entities, the consequence of false documents, and what the badge substantively asserts. | Not decided → `OQ-35`, `OQ-56` |

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
| Whether a User Account is mandatory before publication. | Not decided → `OQ-21` |
| Rejected/expired lead handling and re-application. | Not decided → `OQ-51` |
| Business claiming: which directory categories may hold a paid Business listing versus which are reserved for the deferred professional/organisation models (§22), and which parties may be listed at all. | Not decided → `OQ-26` |
| Claiming, competing claims, and duplicate real-world businesses: who may claim, what evidence resolves a claim, who arbitrates a competing claim, and what a false claim causes. | Not decided → `OQ-27` |
| Duplicate/overlapping Business Entity control: detection basis, merge authority, and consequence where one real business exists as several entities. | Not decided → `OQ-32` |

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

Not decided: team seat limits per plan, and which capability levels may view
payment and financial records inside Business Center → `OQ-46`. Also unresolved:
the "Owner" name is used both for this business capability role and for the
document decision authority → `OQ-63` (§1.6 item 6).

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
| — | Co-ownership, multiple simultaneous owners, or an entity without an owner. | Not decided → `OQ-20` |
| — | Ownership transfer of a Branch independent of the parent entity. | Not decided → `OQ-19` |
| — | Ownership transfer while the Business Entity is Expired or suspended, and transferability of a paid subscription when a business is sold to a new legal person. | Not decided → `OQ-30`, `OQ-39` |

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
| 12.7 | Which requests for managed service are accepted, priced, or bundled. | Not decided → `OQ-24` |
| 12.8 | Whether managed service is recorded in Business Center, and any audit expectations. | `PROVISIONAL` — `OQ-24` |
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
| Review turnaround, reviewer roles, and rejection messaging. | Not decided → `OQ-52` |
| Change history / audit visibility to the business, and rollback of an approved change. | `PROVISIONAL` — `OQ-52` |
| Appeal route for a **content** rejection (distinct from verification appeals, `OQ-13`), public abuse reporting against a business, and repeat-offender handling. | Not decided → `OQ-57` |
| Prohibited and misleading claim policy (superlatives, false certification, false institutional affiliation, fabricated projects). | Not decided → `OQ-45` |
| Rights declaration for uploaded media, takedown, and repeat media infringement. | `PROVISIONAL` — `OQ-45` |
| Accuracy responsibility for business-submitted prices, "price on request" content, and stale prices. | Not decided → `OQ-43` |
| Offer validity window and behaviour of an expired offer. | Not decided → `OQ-43` |
| Evidence required before a business may state that it is an authorised dealer, agent, or representative of a Brand. | Not decided → `OQ-44` |

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
| Founding Partner | May be visible according to policy. | `PROVISIONAL` — `OQ-14` |
| Verified | May be visible according to policy. | `PROVISIONAL` — `OQ-14` |
| Sponsored | Visible **only** when clearly labeled. | `LOCKED` |
| Business analytics | Not public. | `LOCKED` |

### 14.5 Open items

| Open item | Status |
|---|---|
| Exact badge wording, placement, and Arabic copy for Verified / Founding Partner / Sponsored. | `PROVISIONAL` — `OQ-14` |
| What the Verified badge substantively asserts, and what it expressly does not guarantee. | Not decided → `OQ-35` |
| Whether Sponsored labeling appears in search results, category lists, map views, and related-business rails. | `PROVISIONAL` — `OQ-14` |
| Whether similar-businesses ordering may be influenced commercially. | `PROVISIONAL` — must not become covert organic ranking (§6.1.4) |
| Public experience of an Expired, suspended, or removed listing reached by direct link, and whether its content is replaced or only marked. | Not decided → `OQ-68` |
| Whether a branch manager's personal contact details may be published on a branch page. | Not decided → `OQ-59` |

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
| Moderation, rights confirmation, and takedown handling. | `PROVISIONAL` — `OQ-45`, `OQ-57` |
| Storage limits, file size/type limits, and external hosting. | Not decided → `OQ-16` |
| Per-category module media limits. | Not decided → `OQ-16` |

### 16.1 Current working media baseline (NOT frozen)

| Plan | Working baseline | Status |
|---|---|---|
| Business | 6 images | `PROVISIONAL` |
| Business Pro | 20 images | `PROVISIONAL` |
| Business Plus | 40 images | `PROVISIONAL` |
| Corporate | not defined | `PROVISIONAL` — see P-02 / `OQ-04` |

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

Whether these four are guaranteed on **every** paid tier including Business is an
entitlement-review matter (`PROVISIONAL` — P-03 / dependency D-3); the metric
definitions themselves remain `PROVISIONAL` — `OQ-17`.

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
| Retention window, aggregation, and reset behaviour. | Not decided → `OQ-17` |
| Data export. | `PROVISIONAL` — `OQ-17` |
| Counting rules: unique vs total, bot filtering, self-view exclusion. | Not decided → `OQ-17` |
| Privacy/consent handling for viewer-side measurement. | Not decided → `OQ-55` |
| Definition and permitted commercial use of the approved framing word "Lead", and the mandatory qualifier wherever it is used, given that Civilpedia cannot identify or contact individuals. | Not decided → `OQ-38` |

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
document (consistent with the existing Directory architecture). Whether
verification may act as a ranking input at all is not decided here — `OQ-35`; it
must never become a purchasable or paid-adjacent signal (§6.1.4, L-42).

### 18.3 Branch-level local discovery

| Rule | Status |
|---|---|
| Branches may appear independently in local search results while remaining part of one Business Entity. | `PROVISIONAL` (approved direction) |
| Selecting a branch keeps the user within the same Business brand/profile relationship. | `PROVISIONAL` |
| Whether a branch result shows branch-only data or entity-level data. | `PROVISIONAL` |
| Branch-level deduplication and cannibalisation handling in results. | Not decided → `OQ-67` |
| Verification's effect on ranking. | `PROVISIONAL` — `OQ-35` |
| Example relationship (one brand, multiple named branches) is illustrative, not a data commitment. | `PROVISIONAL` |
| Whether a Sponsored placement may be bought at **branch** level rather than entity level, and how that interacts with Category × Area inventory. | Not decided → `OQ-53` |
| Branch lifecycle: activation and deactivation of a branch, branch closure, relocation, and the effect of relocation on verification. | Not decided → `OQ-54` |

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
| The quantitative Minimum Profile Quality standard and its validation mechanism. | Not decided → `OQ-47` |
| Per-category variation of the minimum (e.g. manufacturer vs. contractor). | `PROVISIONAL` — `OQ-47` |
| Consequence of falling below the minimum after publication (demotion, warning, grace). | Not decided → `OQ-48` |
| Who may approve publication (staff-only vs automated + audit). | Not decided → `OQ-49` |

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
| Payment status | `PROVISIONAL` (expected) — `OQ-58` |
| Verification status | `PROVISIONAL` (expected) — `OQ-58` |
| Pending changes | `PROVISIONAL` (expected) — `OQ-58` |
| Support / Contact Civilpedia | `PROVISIONAL` (expected) — `OQ-58` |
| Business switching (multiple Business Entities) | `PROVISIONAL` (expected; implied by L-06 / §2.1.6) — `OQ-58` |
| Verification evidence upload | `PROVISIONAL` (expected) — `OQ-40`, `OQ-58` |

The module **set** is the approved expectation. Order, navigation, screens, and
per-plan availability are unfrozen and must be produced by a Business Center design
and contract phase. The existing roadmap slice **V1-R10.5-E — Business + Staff**
remains `LOCKED`; this document does not unfreeze it and does not authorize it.

Team seat limits per plan, and which capability levels may see payment and
financial records, are commercial entitlement matters and are **not** decided
here — `OQ-46`.

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

**Amendment A2 note.** A2 added **no conflict** and resolved **no** conflict. It
corrected the **wording** of one `LOCKED` rule in §2.4 that contradicted the
approved Extra Branch add-on model (§4.2); the commercial intent — one Business
Entity, one Business subscription, branches as locations, add-on pricing for
additional branches, and no second full subscription merely because a location is
a branch — is unchanged. A2 also rebuilt the §24.3 register. The statement above
("unresolved blocking conflicts: none") remains true and is unaffected.

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
| D-9 | Language precedence for the commercial agreement (not decided — `OQ-69`) | D-5 covers user-interface strings only. Which language governs the commercial terms themselves is an Owner decision, not a localization task. |

### 24.3 Open Question register — undefined by the Owner (must not be invented)

Rebuilt by **Amendment A2** (2026-09-28) for register integrity. **No entry below
is answered, and A2 decided none of them.** The pre-A1/A1 wording of the first 24
items is preserved in meaning; each now carries a stable `OQ-nn` ID, a severity,
a decision owner, a freeze classification, and its dependent section.

#### 24.3.0 Register rules (mandatory)

1. This register is the **single authoritative list** of unresolved commercial
   rules. §1.3 rule 3 and rule 6 make it mandatory that every in-body
   unresolved marker cites one of these IDs.
2. Status of every entry: **`OPEN` — undefined by the Owner**. No agent may
   answer an entry, infer an answer, or present one as decided.
3. `MUST RESOLVE BEFORE FREEZE` means Commercial Model V1 cannot be frozen while
   the entry remains `OPEN` (§1.3 rule 7, §1.6).
4. `REGISTER BEFORE FREEZE` means the item must be visible and owned in the
   register, but does not by itself block the freeze.
5. `BUSINESS CENTER`, `IMPLEMENTATION ARCHITECTURE`, `LEGAL/POLICY REVIEW`, and
   `DEFERRED` mean the decision belongs to a later authorized phase; the entry
   records the dependency and must not be answered here.
6. Severity, owner, and classification are **triage metadata**, not commercial
   decisions. They were assigned by the Architect during A2 and carry no
   commercial meaning beyond freeze readiness.
7. An in-body unresolved marker without a registered ID is a **document defect**
   to be repaired by registering the item — never by answering it.

Severity scale: `CRITICAL` / `HIGH` / `MEDIUM` / `LOW`.
Classification values: `MUST RESOLVE BEFORE FREEZE` / `REGISTER BEFORE FREEZE` /
`BUSINESS CENTER` / `IMPLEMENTATION ARCHITECTURE` / `DEFERRED` /
`LEGAL/POLICY REVIEW`.
Owner values: `Owner` (commercial decision) / `Architect` (design proposal within
Owner authority) / `Future Architecture` / `Legal Review` / `Owner + Architect`.

#### 24.3.1 CRITICAL — must be resolved before any freeze

| ID | Title | Status | Severity | Owner | Classification | Dependency / affected section | Decision needed |
|---|---|---|---|---|---|---|---|
| OQ-25 | Subscription term anchor | `OPEN` | CRITICAL | Owner | MUST RESOLVE BEFORE FREEZE | §7.1, §8.1, §8.3.13 | When does the paid term start (agreement, payment verified, or first publication), when does it end, and what is the renewal date. |
| OQ-26 | Category eligibility vs the professionals boundary | `OPEN` | CRITICAL | Owner | MUST RESOLVE BEFORE FREEZE | §2.1, §2.5, §10.1, §22 | Which directory categories may hold a paid Business listing, which are withheld pending the deferred professional/organisation models, and what users see in withheld categories. |
| OQ-27 | Business claiming, competing claims, false claims | `OPEN` | CRITICAL | Owner | MUST RESOLVE BEFORE FREEZE | §10.1, §2.4 | Whether claiming exists in Commercial V1; if yes, eligibility, evidence, dispute arbiter, fee, and losing-claim outcome; if no, the explicit launch consequence. |

#### 24.3.2 HIGH — must be resolved before any freeze

| ID | Title | Status | Severity | Owner | Classification | Dependency / affected section | Decision needed |
|---|---|---|---|---|---|---|---|
| OQ-28 | Price change and grandfathering | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §3.2, §1.5 | Effective moment of a list-price change, its effect on a paid unexpired term, its effect on the next renewal, and the notice period and channel. |
| OQ-29 | Renewal mechanics and notices | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §8.3.11, §8.3.14 | Whether renewal must remain manual through WhatsApp / manual payment verification; whether auto-charge is prohibited or merely deferred; whether stored payment instruments are excluded from Commercial V1. Plus early-renewal term extension and renewal/expiry notice cadence, channel, and language. **None of this is decided by A2.** |
| OQ-30 | Suspension and termination for policy violation | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §8.1, §8.2-C, §8.3.15, §11.3 | Who may suspend or terminate, public visibility during suspension, whether the term clock pauses, the money outcome, appeal, re-entry condition, and ownership transfer while in a non-Active state. |
| OQ-31 | Payment exception outcomes | `OPEN` | HIGH | Owner + Architect | MUST RESOLVE BEFORE FREEZE | §7.2.5, §7.5 | Customer and staff outcome for short payment, overpayment, wrong account/agent, duplicate claim of one transfer, third-party payer, and payment for an Expired or closed business. |
| OQ-32 | Duplicate / overlapping Business Entity control | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §2.4, §10.1 | Detection basis, merge authority, and consequence where one real business exists as several entities (abuse of §2.4 / L-05 / L-06). |
| OQ-33 | Sponsored commercial lifecycle and terms | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §6.1.11, §6.3 | Sponsor campaign states, renewal, cancellation notice, refund, and the money outcome when the advertised entity becomes unavailable mid-campaign. |
| OQ-34 | Sponsored advertiser eligibility and prohibited advertisers | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §6.1.11, §9.1 | Minimum eligibility to buy a placement (including whether Verified is required) and the prohibited advertiser categories and prohibited advertising content. |
| OQ-35 | Verification validity, meaning, and fraud | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §9.3, §14.5, §18.2, §18.3 | Verification validity period and reverification triggers; whether renewal requires re-verification; the consequence of false documents; what the badge asserts and expressly does not guarantee; whether verification may act as a ranking input. |
| OQ-36 | Permanent business closure | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §8.3.16, §14.5 | Closure as a commercial event distinct from expiry: who declares it, effect on subscription and prepaid funds, badges, sponsorship, data retention and eventual anonymisation, and reactivation. |
| OQ-37 | Launch density, sequencing, and empty-area experience | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §2.5, §14 | Minimum paid businesses per Category × Area before an area opens; category rollout order; launch geography; user experience of an empty category or area. |
| OQ-38 | Definition and permitted use of the word "Lead" | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §17.1, §17.3 | What "Lead" means in Civilpedia's vocabulary given that individuals are neither identified nor contacted, and the mandatory qualifier wherever the word is used commercially. |
| OQ-39 | Subscription transferability | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §2.1.3, §11.3 | Whether a paid subscription transfers to a new legal person when a business is sold, and the evidence, fee, or credit outcome if it does not. |
| OQ-40 | Records retention, access, and deletion | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §7.2.6, §9.2, §20.1 | Retention period, access control, business-facing visibility, and deletion of transfer receipts, business registration files, identification documents, and internal staff notes. |
| OQ-41 | Terms / Privacy / business-agreement policy register | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §1.5 | Whether Civilpedia adopts a policy-obligations register covering content rights, accuracy, prohibited content, refunds, suspension/termination, verification disclaimer, Sponsored disclosure, analytics disclaimer, records handling, and limitations of guarantee. Content is a later legal review. |

#### 24.3.3 MEDIUM

| ID | Title | Status | Severity | Owner | Classification | Dependency / affected section | Decision needed |
|---|---|---|---|---|---|---|---|
| OQ-42 | Discounts beyond Founding Partner, and discount stacking | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §3.3, §3.4 | Whether multi-year, early-payment, or volume discounts exist, and whether any discount stacks with the Founding Partner price. |
| OQ-43 | Offer validity and price accuracy | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §13.2, §13.3; legal/policy review required before the rule is published | Offer validity window and expired-offer behaviour; who bears accuracy responsibility for displayed prices and "price on request" content; stale-price handling. |
| OQ-44 | Brand representation claims and Brand governance | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §2.2, §15.2 | Evidence required before a business may claim authorised dealer / agent / representative status for a Brand, and which authority governs the Brand concept. |
| OQ-45 | Prohibited and misleading claims; media rights | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §13.2, §13.3, §16; legal/policy review required before the rule is published | Prohibited claim categories, rights declaration for uploaded media, takedown, and repeat-offender handling. |
| OQ-46 | Team seat limits and financial visibility | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §11.1, §20.1 | Whether a seat limit applies per plan, and which capability levels may view payment and financial records in Business Center. |
| OQ-47 | Quantitative Minimum Profile Quality standard | `OPEN` | MEDIUM | Architect + Owner | REGISTER BEFORE FREEZE | §19, §19.1 | The quantitative thresholds, per-category variation, and the validation mechanism. |
| OQ-48 | Falling below the publication minimum after publication | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §19 | Consequence: warning, demotion, grace, or suspension, and who decides. |
| OQ-49 | Who may approve publication | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §19, §13.3 | Staff-only approval versus automated validation plus audit, and the reviewer authority. |
| OQ-50 | Verification authority | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §9.3, §7.5 | Who may verify, and whether verification is staff-only. |
| OQ-51 | Rejected / expired lead handling and re-application | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §10.1 | Re-application eligibility, cooldown, and any fee. |
| OQ-52 | Review turnaround, reviewer roles, rejection messaging, change history | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §13.3 | Internal review service expectation, reviewer roles, rejection messaging (Arabic-first, D-5), and business-visible audit/rollback expectations. |
| OQ-53 | Branch-level Sponsored placement | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §6.1.7, §6.3, §18.3 | Whether a Sponsored placement may be bought per branch rather than per entity, and how that interacts with Category × Area inventory. |
| OQ-54 | Branch lifecycle | `OPEN` | MEDIUM | Owner | BUSINESS CENTER | §4.2, §13.1, §18.3 | Branch activation and deactivation, branch closure, relocation, and the effect of relocation on verification. |
| OQ-55 | Privacy / consent for viewer-side measurement | `OPEN` | MEDIUM | Owner + Architect | IMPLEMENTATION ARCHITECTURE | §17.3 | Consent basis and data handling for viewer-side analytics measurement. |
| OQ-56 | Verification granularity for multi-branch entities | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §9.2, §9.3 | Whether verification is per Business Entity or per Branch. |
| OQ-57 | Content-rejection appeal, abuse reporting, repeat offenders | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §13.3, §16 | Appeal route for content rejection (distinct from verification appeals, OQ-13), public abuse reporting against a business, and repeat-offender policy. |
| OQ-58 | Business Center module set completeness | `OPEN` | MEDIUM | Architect | BUSINESS CENTER | §20.1 | Whether payment status, verification status, pending changes, support/contact, business switching, and verification evidence upload are required modules. |
| OQ-59 | Branch manager personal data and non-Active ownership transfer | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §11.3, §14.5; legal/policy review required before the rule is published | Whether a branch manager's personal contact details may be published, and how ownership transfer behaves for a non-Active entity. |
| OQ-60 | Instalments, deferred payment, and quotation validity | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §3.2, §3.3 | Whether any instalment or deferred payment structure is permitted, and how long a quotation or offer remains valid. |
| OQ-61 | Commercial measurement and pricing experiments | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §1.5, §3.2 | Which commercial KPIs are tracked (conversion, renewal, churn), and whether controlled pricing experiments are permitted given §1.5. |
| OQ-62 | Payment verification turnaround | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §7.1, §7.5 | The internal verification service expectation and the customer-facing wording while a payment sits in Payment Pending. |
| OQ-63 | "Owner" terminology collision | `OPEN` | MEDIUM | Owner + Architect | REGISTER BEFORE FREEZE | §1.3, §1.6, §11.1 | Whether the business capability role and the document decision authority keep the same word, and any glossary term. |

#### 24.3.4 LOW

| ID | Title | Status | Severity | Owner | Classification | Dependency / affected section | Decision needed |
|---|---|---|---|---|---|---|---|
| OQ-64 | Extra Branch price variation by area or branch type | `OPEN` | LOW | Owner | REGISTER BEFORE FREEZE | §4.2 | Whether extra-branch pricing differs by city/area or branch type. |
| OQ-65 | Extra Branch annual transferability / reset | `OPEN` | LOW | Owner | REGISTER BEFORE FREEZE | §4.2 | Whether extra branches are transferable or resettable annually. |
| OQ-66 | Founding Partner later cohorts | `OPEN` | LOW | Owner | DEFERRED | §5.7 | Whether Founding Partner pricing is re-offered in a later cohort. |
| OQ-67 | Branch-level deduplication and cannibalisation in results | `OPEN` | LOW | Architect | IMPLEMENTATION ARCHITECTURE | §18.3 | How multiple branches of one entity are represented in results without crowding out other businesses. |
| OQ-68 | Public experience of an expired, suspended, or removed listing | `OPEN` | LOW | Architect | IMPLEMENTATION ARCHITECTURE | §8.3.3, §14.5 | What a user sees on direct link, and whether content is replaced or only marked. |
| OQ-69 | Language precedence for commercial terms | `OPEN` | LOW | Owner | LEGAL/POLICY REVIEW | §1.6, D-5, D-9 | Which language governs the commercial agreement (UI localization is separate, D-5). |
| OQ-70 | SSOT custodian and next-review date | `OPEN` | LOW | Owner | REGISTER BEFORE FREEZE | §1.6 | The named document custodian and a review cadence. Documentary only. |

#### 24.3.5 Pre-existing entries (carried forward from A1, IDs assigned by A2)

Wording and meaning preserved from the original 24 numbered items. A2 added the
ID, severity, owner, and classification columns only.

| ID | Title | Status | Severity | Owner | Classification | Dependency / affected section | Decision needed |
|---|---|---|---|---|---|---|---|
| OQ-01 | Founding Partner price, 1-month and 3-month first terms | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §5.7 | The Founding Partner price for a 1-month or 3-month first term. |
| OQ-02 | "First 50" Founding Partner counter | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §5.7 | How the counter is defined, incremented, and evidenced; and the execution detail for businesses #51+. |
| OQ-03 | Extra Branch 3-month price, maximum branch cap | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §4.2 | Whether a 3-month extra-branch price exists; the maximum branch count per entity and behaviour past the cap. |
| OQ-04 | Corporate contents, minimum term, quotation process | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §3.1, §3.3, §4.1 | Corporate plan contents, included branch count, minimum commitment, and the quotation process. |
| OQ-05 | Renewal pricing | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §8.3.9 | Whether renewal pricing differs from first purchase. |
| OQ-06 | Upgrade, downgrade, proration | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §8.3.9 | Upgrade/downgrade mid-term, proration, and downgrade when branch count exceeds the new tier. |
| OQ-07 | Refund, cancellation, no-show | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §7.5, §8.3 | Refund, cancellation, partial-refund, and no-show policy. |
| OQ-08 | Invoicing, fiscal/tax treatment, accounting export | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §7.5; legal/policy review required before the rule is published | Invoicing, receipts, tax/fiscal treatment, and accounting export. |
| OQ-09 | Transfer rails, bank accounts, currencies | `OPEN` | MEDIUM | Owner | MUST RESOLVE BEFORE FREEZE | §7.5 | Accepted bank accounts / transfer rails, settlement accounts, and supported currencies. |
| OQ-10 | Payment anti-fraud controls | `OPEN` | MEDIUM | Owner | MUST RESOLVE BEFORE FREEZE | §7.5 | Anti-fraud controls beyond independent receipt verification (duplicate transfer, mismatched amount, third-party payer). Customer-outcome rules are OQ-31. |
| OQ-11 | Payment staff authority | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §7.5 | Which staff roles may confirm payment and which may activate a subscription. |
| OQ-12 | Grace Period duration and behaviour | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §8.1, §8.3.6–§8.3.8 | Exact Grace Period duration (target ~3–7 days is not frozen) and whether management access continues, in which mode, and what the owner sees. |
| OQ-13 | Verification evidence, turnaround, appeals | `OPEN` | MEDIUM | Owner | DEFERRED | §9.2, §9.3 | The verification policy document, per-category evidence checklists, turnaround, and appeals. Validity and meaning are OQ-35. |
| OQ-14 | Badge wording, placement, and Arabic copy | `OPEN` | MEDIUM | Owner + Architect | REGISTER BEFORE FREEZE | §5.6, §9.3, §14.4, §14.5 | Exact wording, placement, and Arabic copy for Verified / Founding Partner / Sponsored, and where Sponsored labeling appears. |
| OQ-15 | `CP-BIZ` / `CP-PAY` generation and visibility | `OPEN` | MEDIUM | Architect | IMPLEMENTATION ARCHITECTURE | §7.4 | Exact reference format, sequence source, uniqueness scope, and display surface. |
| OQ-16 | Media storage and per-category media limits | `OPEN` | MEDIUM | Architect | IMPLEMENTATION ARCHITECTURE | §16, §16.1 | Storage limits, file size/type limits, external hosting, and per-category module media limits. |
| OQ-17 | Analytics retention, counting rules, export, post-expiry visibility | `OPEN` | MEDIUM | Architect | REGISTER BEFORE FREEZE | §8.3.10, §17.2, §17.3 | Retention window, aggregation and reset behaviour, unique vs total counting, bot filtering, self-view exclusion, export, and whether an Expired business retains analytics history and internal records visibility. |
| OQ-18 | Sponsored inventory cap, Area, oversubscription | `OPEN` | HIGH | Owner | MUST RESOLVE BEFORE FREEZE | §6.3 | Whether 2–3 per Category × Area is a hard cap, soft target, or queue; the definition of "Area"; and oversubscription, rotation, and fairness policy. |
| OQ-19 | Branch as a separately owned legal entity; independent branch transfer | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §2.4, §11.3 | Whether a Branch may ever be a separately owned legal entity inside a shared brand, and whether a Branch's ownership may be transferred independently of the parent entity. |
| OQ-20 | Multiple, simultaneous, or absent owners | `OPEN` | MEDIUM | Owner | MUST RESOLVE BEFORE FREEZE | §11.3 | Co-ownership, multiple simultaneous owners, and an entity temporarily without an owner. |
| OQ-21 | User Account required before publication | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §10.1 | Whether a User Account is mandatory before a business can be published. |
| OQ-22 | Launch disposition of existing and seed listings | `OPEN` | MEDIUM | Owner | MUST RESOLVE BEFORE FREEZE | §2.5, C-9 | Whether existing and seed public listings are converted, grandfathered, or removed at launch. |
| OQ-23 | Plan code values, price storage, currency representation | `OPEN` | MEDIUM | Future Architecture | IMPLEMENTATION ARCHITECTURE | §3.5, C-2 | Plan catalog code values and price storage / currency representation. |
| OQ-24 | Managed service acceptance and pricing | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §12.7, §12.8 | Which managed-service requests are accepted at all, and whether managed service is ever separately priced, bundled, or recorded in Business Center. |

#### 24.3.6 Register totals (informational)

| Classification | Count |
|---|---|
| Registered Open Questions | 70 |
| `CRITICAL` | 3 |
| `HIGH` | 21 |
| `MEDIUM` | 39 |
| `LOW` | 7 |
| `MUST RESOLVE BEFORE FREEZE` | 28 |
| Entries answered by Amendment A2 | **0** |

Counts are informational. The tables in §24.3.1–§24.3.5 are the authority.

### 24.4 Change log (append-only)

| Date | Authority | Change | Previous | New | Implementation / sales impact |
|---|---|---|---|---|---|
| 2026-09-27 | Owner + ChatGPT Architect | Document created as Commercial Model V1 SSOT | none | Initial consolidation of §1–§25 | Documentation only. No production change. No sales change until separately communicated. |
| 2026-09-27 | ChatGPT Architect | **Amendment A1 — Conflict reconciliation (C-1…C-10)** | C-1…C-10 recorded as unresolved conflicts requiring Architect decisions | Added §1.2 commercial-policy vs implementation-authority rule; added §2.3, §2.5, §3.5, §5.8, §6.4, §8.2, §8.4, §11.1a, §11.4 reconciliation sections; restructured §8 into three separate conceptual workflows; rewrote §24.1 as a resolved conflict registry; updated §25 registry | **No commercial intent changed.** No production code, test, migration, Supabase, roadmap, or UI-contract change. No implementation authorized. |
| 2026-09-28 | ChatGPT Architect | **Amendment A2 — Register integrity + documentary corrections** | 24 plain-numbered open questions; 14 in-body unresolved markers with no registered entry and 4 more only partially covered; no severity/owner/classification fields; no statement of document maturity; §2.4 `LOCKED` wording ("never a separately **billed** … entity") contradicting the approved Extra Branch add-on model in §4.2; §3.3 pointed at §24.3 for an entitlement item that was never registered there | Rebuilt §24.3 as a single authoritative Open Question register with stable IDs `OQ-01`…`OQ-70`, per-entry status/severity/owner/classification/dependency/decision-needed fields (§24.3.1–§24.3.5, §24.3.6 totals); added the mandatory Open Question ID rule (§1.3 rule 6) and freeze rule (§1.3 rule 7); added §1.6 document maturity (**CANONICAL SSOT / ACTIVE DESIGN / NOT YET FROZEN**) with a freeze gate; added in-body `OQ-nn` citations to every unresolved marker and to registered gaps (§2.4, §2.5, §3.2, §3.3, §3.4, §4.2, §5.7, §6.1, §6.3, §7.2, §7.5, §8.1, §8.3, §9.3, §10.1, §11.1, §11.3, §12.7, §13.3, §14.4, §14.5, §16, §17.2, §17.3, §18.2, §18.3, §19, §20.1); corrected §2.4 branch wording to "not a separately owned and not a separately subscribed Business Entity … additional branches may carry approved Extra Branch add-on pricing under the parent Business subscription"; added dependency D-9 and standing prohibitions 11–12; added **no** `L-nn` registry entry (A2 governance rules stay outside the commercial decision registry) and updated §25.5 counts | **Documentation / governance only. No commercial decision, no price change, and no commercial intent change.** **0 open questions answered; 0 new commercial rules created.** Wording correction in §2.4 preserves the approved intent (one Business Entity, one subscription, add-on pricing, no second full subscription for a branch). No production code, test, migration, Supabase, contract, UI, or roadmap change. No implementation authorized. No sales impact: no `PROVISIONAL` value became quotable. |

---

## 25. FINAL STATUS — DECISION REGISTRY

Registry state after **Amendment A2** (2026-09-28). Amendment A1 reconciled
implementation-mapping conflicts and did **not** change any commercial intent, so
no previously approved rule was downgraded, removed, or reclassified. New entries
below record the authority-separation rules and the implementation mappings that
are deliberately `PROVISIONAL`.

**Amendment A2 effect on this registry.** A2 added **no** `LOCKED` entry and
changed **no** commercial decision, **no** price, **no** `PROVISIONAL` value, and
**no** `DEFERRED` item. It answered **none** of the open questions in §24.3. Its
own additions (§1.3 rules 6–7, §1.6) are mandatory **governance** rules and are
intentionally not registered as `L-nn` commercial decisions. The only registry
change is informational: §25.5 now also reports the §24.3 open-question counts.

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

**Amendment A2 note.** A2 added **no** `LOCKED` commercial decision. The `LOCKED`
count therefore remains **54**. The A2 additions — document maturity (§1.6), the
Open Question ID obligation (§1.3 rule 6), and the freeze rule (§1.3 rule 7) — are
**mandatory governance rules of this document**, not commercial decisions, and are
deliberately **not** registered as `L-nn` entries here. They create no commercial
policy and change no price, entitlement, or lifecycle.

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
11. Do not answer, infer, soften, or delete a registered Open Question without an
    explicit Owner update per §1.5; and do not introduce an in-body unresolved
    commercial marker that does not cite a registered `OQ-nn` ID (§1.3 rule 6,
    §24.3.0).
12. Do not describe Commercial Model V1 as complete, final, closed, or frozen, and
    do not treat §24.3 triage metadata as a commercial decision (§1.3 rule 7,
    §1.6).

### 25.5 Registry counts (informational)

| Classification | Count |
|---|---|
| `LOCKED` | 54 |
| `PROVISIONAL` | 33 |
| `DEFERRED` | 14 |
| OPEN QUESTIONS (`OPEN`, §24.3) | 70 |
| — of which `MUST RESOLVE BEFORE FREEZE` | 28 |
| Unresolved blocking conflicts | 0 |
| Commercial decisions changed by Amendment A2 | 0 |

Counts are informational. The tables in §25.1–§25.3 and §24.3.1–§24.3.5 are the
authority. Amendment A2 changed **no** `LOCKED`, `PROVISIONAL`, or `DEFERRED`
decision; the 54 / 33 / 14 counts are unchanged from Amendment A1. A2's own
additions (§1.3 rules 6–7, §1.6) are governance rules, not commercial decisions,
and are intentionally outside the `L-nn` registry.

---

END OF DOCUMENT
