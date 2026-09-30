# CIVILPEDIA — COMMERCIAL MODEL V1 (CANONICAL SSOT)

DOCUMENT_ID: `CIVILPEDIA_COMMERCIAL_MODEL_V1`
DOCUMENT_STATUS: **FROZEN** — CANONICAL COMMERCIAL SSOT
FREEZE_STATE: **FROZEN.** Commercial Model V1 is complete and final **as a commercial-policy document** and is **frozen** as the **canonical commercial-policy baseline for Civilpedia V1**, by explicit Document Owner declaration dated 2026-10-01. **See §33 (Commercial Model V1 freeze declaration) — the single authoritative current freeze record** — and §1.6 (Document maturity and freeze status) and the Open Question register in §24.3. **Freeze history, retained for traceability:** Amendments Amendments A3–A5 (2026-09-29) recorded the commercial spine (§26), the eligibility/claiming boundary (§27), and the terms/trust/payments/Sponsored decisions (§§28–§30), and closed 33 registered Open Questions. **Amendment A6** (2026-09-29) then applied documentary and register-hygiene corrections only: it decided **no** commercial question and moved the register from 77 to **78** entries (44 → **45** `OPEN`) by registering one **non-blocking** entry, `OQ-78`. **Amendment A7** (2026-09-29) then recorded three Owner commercial decisions in **§31** — Corporate quotation terms (`L-84`, `L-85`), business-ownership cardinality and recovery (`L-86`), and launch density and sequencing (`L-87`) — and closed the last three `MUST RESOLVE BEFORE FREEZE` entries, **`OQ-04`**, **`OQ-20`**, and **`OQ-37`**, moving the register to **79** entries (**43** `OPEN` / **36** `CLOSED`) after registering one **non-blocking** legal/policy entry, `OQ-79`, as required by §1.3 rule 6. **Zero** `MUST RESOLVE BEFORE FREEZE` entries remain. **Amendment A8** (2026-09-30) then **intentionally reopened the pre-freeze commercial design** at Document Owner + Architect direction to address **cold-start acquisition and first-business onboarding**, recording ten decisions in **§32** (`L-88`…`L-97`) and registering **5** new **non-blocking** entries (`OQ-80`…`OQ-84`) plus **2** new dependency records (`D-32`, `D-33`), moving the register to **84** entries (**48** `OPEN` / **36** `CLOSED`). A8 closed **0** entries and changed **no** price. **Freeze declaration (2026-10-01).** Commercial Model V1 is now **`FROZEN`** as the canonical commercial-policy baseline for Civilpedia V1, on the basis of **all three** freeze preconditions being **`SATISFIED`**: the **final A8-inclusive independent Freeze Readiness Audit was completed**, **Architect Acceptance was issued**, and the **Document Owner explicitly approved freeze** (§1.6 items 3, 8, 9, 10; §33). `MUST RESOLVE BEFORE FREEZE` = **0**. All **48** remaining `OPEN` Open Questions **retain their existing classifications** (status, severity, owner, classification) and **remain routed to their proper later phases**; **no** `OPEN` entry is **implicitly closed** by the freeze; **no** `PROVISIONAL` or `DEFERRED` item becomes `LOCKED` merely because the document is frozen; **no** commercial meaning changed and **0** commercial decisions were changed. **Commercial freeze does NOT authorize implementation.** `IMPLEMENTATION_AUTHORIZED` remains **`NO`** (§1.2, L-47). Any future commercial-model change requires a **new explicit post-freeze amendment** under the §1.5 change protocol.
DOCUMENT_AUTHORITY: OWNER + CHATGPT ARCHITECT (commercial decisions)
SCOPE: Documentation / consolidation only
IMPLEMENTATION_AUTHORIZED: NO — this document does not authorize any code, schema, contract, or phase change
BASELINE_COMMIT: `30aa1b23` (V1-R10.5-C closed / accepted)
ROADMAP_PHASE_AT_BASELINE: V1-R10 UI/UX & Core App Experience — R10.5-D CURRENT (pre-implementation audit only); R10.5-E Business + Staff LOCKED
SOURCE_OF_DECISIONS: Owner-approved commercial decisions consolidated by the Architect; conversation history is NOT a source of truth
AMENDMENT: A1 — Conflict Reconciliation (2026-09-27), authority: ChatGPT Architect. Reconciles C-1…C-10 by authority separation. No commercial intent changed. No production, schema, contract, or roadmap change authorized or performed.
AMENDMENT: A2 — Register Integrity + Documentary Corrections (2026-09-28), authority: ChatGPT Architect. **Register/governance amendment only.** Rebuilds the Open Question register (§24.3) so that every in-body unresolved commercial marker carries a registered Open Question ID, adds freeze-triage metadata (severity / owner / classification), corrects one LOCKED-rule **wording** contradiction in §2.4 (branch billing vs the approved Extra Branch add-on model), and records the document maturity as **ACTIVE DESIGN / NOT YET FROZEN**. A2 **creates no commercial decision, resolves no open question, changes no price, and changes no commercial intent.** No production, test, migration, Supabase, contract, UI, or roadmap change authorized or performed.
AMENDMENT: A3 — Commercial Spine (2026-09-29), authority: Owner + ChatGPT Architect. Records the Owner commercial decisions in **§26**: subscription term anchor and activation window, manual renewal and Grace, price changes and grandfathering, suspension and termination, permanent business closure, duplicates, and business sale / ownership transfer. A3 closes **9** registered Open Questions (including `CRITICAL` **OQ-25**) and registers **2** new ones. A3 authorizes **no** code, schema, migration, RLS, route, auth, backend, contract, phase, or roadmap change, and does **not** freeze the document.
AMENDMENT: A4 — Eligibility + Claiming Boundary (2026-09-29), authority: Owner + ChatGPT Architect. Records the Owner commercial decisions in **§27**: category eligibility for the Business commercial plan, and the absence of an open public "Claim this business" workflow in Commercial V1. A4 closes **3** registered Open Questions (including `CRITICAL` **OQ-26** and **OQ-27**) and narrows **OQ-22**. A4 authorizes **no** implementation and does **not** freeze the document.
AMENDMENT: A5 — Terms, Trust, Payments, Sponsored (2026-09-29), authority: Owner + ChatGPT Architect. Records the Owner commercial decisions in **§§28–§30**: payment exceptions and verification authority, cancellation/refunds/plan changes, Sponsored, verification, content/offers/brand claims, the publication Required Fields Gate, analytics honesty, records/privacy, the Legal/Policy Obligations Register, Business Center commercial inputs, the team ceiling, quotations/instalments, pricing experiments and commercial measurement, the controlling customer-facing language, and the Iraqi/regulatory caution. A5 closes **21** registered Open Questions, narrows several others, and registers **5** new ones. A5 drafts **no** legal terms; qualified Iraqi legal/accounting review is recorded as required. A5 authorizes **no** implementation and does **not** freeze the document.
AMENDMENT: A6 — **Documentary Corrections + Register Integrity (2026-09-29)**, authority: ChatGPT Architect (implementing a prior independent Owner-commissioned audit). **Documentary and register-hygiene amendment only.** A6 repairs 16 identified documentary defects and **decides no commercial question, changes no price, no plan, no lifecycle rule, and no commercial intent**. Specifically: removes a `LOCKED` pre-emption of `OQ-12` from the §8.1 Grace row (Grace data retention is `LOCKED`; management access remains open); marks `P-04` `SUPERSEDED`; normalizes the `D-nn` namespace by renumbering §24.2 dependency records to `D-20`…`D-31` with an explicit pre-A6 mapping and by retiring the collision-prone `D-n` renewal-cadence notation in favour of `T-n`; corrects the §30.2 completeness rule so dependency records route to §24.2; repairs six semantically incorrect cross-references (`L-52`, `D-17`, `P-09`, `P-14`, `P-15`, `P-19`); removes a stale `OQ-62` implementation citation; replaces schema-looking persistence names with conceptual labels; attributes the 7 register reclassifications to the amendment that made each; and registers **one** new **non-blocking** entry, `OQ-78` (disposition of non-owner memberships on ownership transfer), which is explicitly **separate from** the still-open, freeze-blocking `OQ-20`. A6 closes **0**, narrows **0**, and reclassifies **0** commercial entries; it moves the register from 77 to **78** entries and from 44 to **45** `OPEN`. The commercial-freeze blocker set is **unchanged**: **`OQ-04`, `OQ-20`, `OQ-37`**. A6 authorizes **no** code, schema, migration, RLS, route, auth, backend, contract, test, UI, or roadmap change, and does **not** freeze the document.
AMENDMENT: A7 — **Final Commercial Freeze-Blocker Decisions (2026-09-29)**, authority: Owner + ChatGPT Architect. **Documentation-only decision-recording pass.** A7 records three explicit Owner commercial decisions in **§31** and closes the last three `MUST RESOLVE BEFORE FREEZE` entries: **`OQ-04`** (Corporate is a quotation-based enterprise plan flooring at ALL Business Plus entitlements, extendable by written quotation, with a **12-month minimum commitment**, **Custom Quote** pricing, and a **30-calendar-day** quotation default validity — `L-84`, `L-85`); **`OQ-20`** (exactly **ONE Primary Business Owner** in normal operation plus optional verified **Co-Owners**, with the conceptual **OWNERSHIP RECOVERY PENDING** state — `L-86`); and **`OQ-37`** (**BAGHDAD FIRST**, a **5 active paid publishable Business** Category Launch Gate, ~8–10 per-category and ~30 overall launch **targets**, and an honest empty state rather than fake listings — `L-87`). A7 adds **4 `LOCKED`** and **no** `PROVISIONAL` / `DEFERRED` entry, registers **1** new non-blocking legal/policy entry **`OQ-79`** (ownership-dispute, deceased-owner, and quorum evidence requirements) as required by §1.3 rule 6, changes **no** price outside the Corporate rules, and preserves the Paid-Only rule, the Business/Professional boundary, and all A3–A6 meaning. **`MUST RESOLVE BEFORE FREEZE` is now 0.** A7 authorizes **no** code, schema, migration, RLS, route, auth, backend, contract, test, UI, or roadmap change, and **does not declare the document `FROZEN`**.
AMENDMENT: A8 — **Cold-Start Acquisition + Business Onboarding Policy (2026-09-30)**, authority: Owner + ChatGPT Architect. **Documentation-only decision-recording pass. The commercial design was intentionally REOPENED before freeze**, at Document Owner + Architect direction, to address cold-start / first-business acquisition. A8 records **ten** explicit Owner commercial decisions in **§32**: **A8-1** there is **no permanent free commercial Business tier** (a free user account and free non-commercial capabilities remain possible, but persistent public commercial presence stays a paid product; Individual Professionals / Workforce remain a separate, undefined future model) — `L-88`; **A8-2** the **Founding Launch Partner Program**: an invitation-only, Civilpedia-selected cohort of approximately **20–30** commercial Businesses receiving **Business Pro at 0 IQD for 60 calendar days**, with the promotional clock starting at the **later** of formal commercial launch or the Business's first successful public publication, **no** card, **no** automatic renewal or charge, once per genuine Business Entity, no duplicate-entity abuse, ordinary expiry/Grace/public-hiding and data-retention rules at expiry, **no** permanent free-plan precedent, and **explicitly distinct from the Founding Partner annual pricing programme** — `L-89`; **A8-3** Launch Partner **value/conversion reporting** using factual interaction metrics that are **never** leads or sales — `L-90`; **A8-4** a **Civilpedia-owned business acquisition CTA** that is **not** third-party Sponsored inventory and must never imply that commercial listing is permanently free — `L-91`; **A8-5** **Civilpedia-created Business Drafts**, which may exist with **no owner attached** (`CIVILPEDIA-MANAGED / OWNER NOT YET ATTACHED`) and do **not** prove ownership — `L-92`; **A8-6** **ownership invitation as the default** assignment method, with **no** Civilpedia-created password and **no** credential handover — `L-93`; **A8-7** **direct assignment as an admin-only exceptional, audited capability** that may not bypass ownership verification — `L-93`; **A8-8** the preserved **Business team capability intent** (Primary Business Owner / Co-Owner / Manager / Editor) with the stored role enum, RBAC matrix, and RLS implementation explicitly `DEFERRED` — `L-94`; **A8-9** the **server-managed commercial catalog requirement** — ordinary category, subcategory, business, branch, visibility, label/media, and acquisition-campaign changes must **not** require a new mobile-app release, while **no** downloaded executable UI/code authority is created — `L-95`; **A8-10** **future admin / Business Center control requirements** recorded as requirements only, with no screen, route, or schema designed — `L-96`; and **A8-11** the **narrow launch-density reconciliation**: during the Launch Partner phase an authorized Launch Partner holding an active A8 promotional commercial entitlement **MAY** count toward launch-category supply density as a **COMMERCIAL-ACTIVE BUSINESS**, which is **not** a free listing and does **not** weaken the Paid-Only rule, the 5-Business Launch Gate, the ~8–10 growth target, the ~30 formal launch target, Baghdad First, or the ban on fake listings — `L-97`. A8 adds **10 `LOCKED`**, **2 `PROVISIONAL`** (`P-35`, `P-36`), **1 `DEFERRED`** (`D-34`), and **7 standing prohibitions** (24–30); registers **5** new **non-blocking** entries (`OQ-80`…`OQ-84`); **narrowed 3** existing entries (`OQ-17`, `OQ-42`, `OQ-72`); and **closed 0**. A8 changes **no** price in §3.2, §5.7, or §6.2, creates **no** permanent free commercial tier, preserves the A3–A7 meaning (including `L-01`, `L-02`, `L-55`, `L-56`, `L-62`, `L-66`, `L-74`, `L-76`, `L-77`, `L-81`, `L-86`, `L-87`), and does **not** define the Professionals/Workforce monetization model. **The prior Final Freeze Readiness Audit is `VALID FOR THE PRE-A8 STATE` ONLY and is no longer sufficient by itself for final freeze** (§1.6 item 8, §32.12). A8 authorizes **no** code, schema, migration, RLS, route, auth, backend, contract, test, UI, or roadmap change, does **not** authorize implementation, and **does not declare the document `FROZEN`**.

FREEZE_DECLARATION: **2026-10-01** — authority: **Document Owner + ChatGPT Architect**. Commercial Model V1 is **`FROZEN`** as the canonical commercial-policy baseline for Civilpedia V1. Basis: the **final A8-inclusive independent Freeze Readiness Audit was completed (`SATISFIED`)**, **Architect Acceptance was issued (`SATISFIED`)**, and the **Document Owner explicitly approved freeze (`SATISFIED`)** — §1.6 items 3, 8, 9, 10; **§33**. **`MUST RESOLVE BEFORE FREEZE` = 0.** Commercial decisions changed: **0**. Open Questions closed/reclassified: **0**; all remaining `OPEN` entries retain their existing classifications and remain routed to their proper later phases. **FROZEN COMMERCIAL MODEL != IMPLEMENTATION AUTHORIZATION** — this freeze authorizes **no** code, schema, migration, Supabase/RLS, auth, route, Business Center, Admin Console, subscription backend, payment gateway, Sponsored backend, Professional Marketplace, or Construction Ecosystem work; each requires a separately authorized architecture/implementation slice. `IMPLEMENTATION_AUTHORIZED` remains **`NO`** (§1.2, L-47) and the roadmap is unchanged. Any future commercial-model change requires a **new explicit post-freeze amendment** under the §1.5 change protocol.

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

   **Scope of rule 6 — two distinct cases (clarified post-audit; this is a
   documentary rule-clarification, not a commercial decision, and it closes no
   OQ, reclassifies no OQ, and changes no OQ count).** Rule 6 governs
   *unresolved commercial / Document Owner decisions*. It is not, and must never
   become, a mechanism for manufacturing an `OQ-nn` entry out of a matter that is
   already registered in its own canonical registry. Two cases are distinguished:

   * **(a) — Unresolved commercial decision (Document Owner / Architect
     authority).** Rule 6 applies in full. The in-body marker **must** cite a
     registered `OQ-nn` from §24.3 in the same row or sentence, and an uncited
     marker is a **document defect** to be repaired by **registering** the item,
     never by answering it.
   * **(b) — Already-registered implementation / entitlement / architecture
     dependency.** Where the unresolved matter is **already** registered as a
     `P-nn` `PROVISIONAL` value in §25.2 and/or as a `D-nn` dependency record in
     §24.2, the marker **may cite that canonical `P-nn` / `D-nn` identifier
     instead of** creating an `OQ-nn` entry — provided the row (i) states
     explicitly that the item is **not** a Document Owner commercial decision, and
     (ii) names the deferred authority that owns it. Creating a synthetic
     `OQ-nn` for such an item would misclassify implementation, entitlement, or
     architecture work as an Owner commercial decision, would inflate §24.3, and
     would breach the authority separation in §1.2 and §1.4 (L-45, L-65). The
     canonical registry reference is the satisfying citation for case (b).

   **Worked example (case (b)):** the per-tier entitlement matrix in §3.3 is
   `PROVISIONAL`, is registered as `P-03`, is routed by dependency record
   `D-25`, and is explicitly **not** an Owner open question — therefore it is
   case (b), and its citation of `P-03` / `D-25` satisfies rule 6 without
   requiring a fabricated `OQ-nn`.

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
7. Amendment A8 adds a **reopening and freeze-readiness obligation**: because A8
   intentionally reopened the commercial design **before** freeze, any later
   change log entry must state whether it (a) is **independent** of the reopened
   A8 work, and (b) preserves the rule that **only the Document Owner may declare
   a freeze** by explicit update to this document (§1.6 items 8 and 9, §32.12). A
   change-log entry **may not** describe Commercial Model V1 as frozen, complete,
   final, or closed, and may not treat the prior Final Freeze Readiness Audit as
   sufficient on its own for a freeze decision.

   **Freeze-declaration note (2026-10-01; documentary).** Rule 7 constrained
   **ordinary change-log entries made during the pre-freeze design period**. It
   does not prohibit the **Document Owner's own explicit freeze declaration**,
   which §1.5 item 3(c), §1.6 item 3(c), and §1.6 item 10 expressly require to be
   made by explicit update to this document. The 2026-10-01 change-log freeze row
   and **§33** are exactly that declaration; they are **not** an ordinary
   change-log entry describing a commercial change.

**Policy-obligations register (gap closed by Amendment A5).** As of Amendment A2
this document contained **no Terms, Privacy, or business-agreement policy
register**, and the gap was registered as a single Owner decision — `OQ-41`.
A5 closes `OQ-41` and creates the register itself in **§30 — Legal / Policy
Obligations Register**, enumerating the eleven policy areas the Owner requires
Civilpedia to maintain. A5 drafts **no** legal text: every entry in §30 records a
dependency and a deferred authority, and qualified Iraqi legal/accounting review
is recorded as required before production commercial launch.

### 1.6 Document maturity and freeze status (added by Amendment A2)

| Statement | Meaning | Status |
|---|---|---|
| This document is the **CANONICAL COMMERCIAL SSOT**. | It is the only authority for the commercial model. | `LOCKED` (governance fact) |
| It is **FROZEN**. | Commercial Model V1 is the **canonical commercial-policy baseline for Civilpedia V1**, frozen by explicit Document Owner declaration on **2026-10-01** after a completed final A8-inclusive independent Freeze Readiness Audit and recorded Architect Acceptance (**§33**). A commercial freeze is **not** implementation authorization (§1.2, L-47). | `LOCKED` (governance fact) — **current status; §33 is the single authoritative current freeze record** |
| Its pre-freeze state was **ACTIVE DESIGN**, and it was **NOT YET FROZEN**. | **Historical.** Accurate for the period from A2 until the 2026-10-01 freeze declaration. **Superseded** by the `FROZEN` row above; retained per §1.5 rule 3. Not current status. | `SUPERSEDED` (historical — not current status) |

Consequences, mandatory:

1. **Freeze state is `FROZEN`.** No agent, document, message, or sales material
   may describe Commercial Model V1 as an **incomplete, in-design, draft, or
   provisional** commercial model. Describing it as **frozen, final, and
   canonical** is now truthful and required by this row. In **both** the pre-freeze
   and post-freeze states, no material may describe Commercial Model V1 as
   **implemented, engineered, shipped, or live**, because implementation remains
   unauthorized (§1.2, L-47).
2. Values marked `PROVISIONAL` remain unquotable (§1.3 rule 2), and this
   remains true regardless of document maturity and regardless of the freeze.
3. Freeze requires, at minimum:
   a. zero §24.3 entries classified `MUST RESOLVE BEFORE FREEZE`;
   b. every in-body unresolved marker citing a registered `OQ-nn` ID
      (§1.3 rule 6); and
   c. an explicit Owner update to this document per §1.5 that states the
      freeze. Only the Owner may declare the freeze.

   **All three conditions were `SATISFIED` on 2026-10-01** — `MUST RESOLVE BEFORE
   FREEZE` = **0**; the final A8-inclusive independent Freeze Readiness Audit was
   completed and Architect Acceptance recorded (§1.6 items 8 and 9); and the
   Document Owner explicitly approved freeze by explicit update to this document
   (§1.5). See **§33**.
4. A freeze declaration is a **commercial** act and is separate from
   implementation authority, which remains unchanged (§1.2, L-47).
5. The Open Question register in §24.3 is the **authoritative freeze-triage
   instrument**. Its severity, owner, and classification fields exist to make
   readiness reviewable; they are triage metadata and are not themselves
   commercial decisions.
6. **Terminology collision (recorded by A2; closed by Amendments A3–A5).** As of
   A2, "Owner" denoted both the business capability role (§11.1, §11.1a) and the
   document decision authority (§1.3, §1.5), and the collision was registered as
   `OQ-63`. A3–A5 close it: the terms are now **Business Owner** (capability
   role) and **Document Owner** (decision authority) — §26.0, L-64. The two
   authorities remain separate and are never merged.
7. **Document housekeeping.** No named custodian and no next-review date are
   recorded for this SSOT — `OQ-70`. This is documentary only and has no
   commercial effect.
8. **Freeze requires independent re-audit and Architect acceptance (added by
   Amendments A3–A5).** Recording A3–A5, **A6**, **A7**, or **A8** in this document
   does **not** by itself move it toward freeze. Before the Document Owner may consider
   a freeze declaration under item 3, an **independent re-audit** of this document
   must be performed and **Architect acceptance** must be recorded. **As written
   pre-freeze, neither had occurred.**
   **Freeze gate `SATISFIED` (2026-10-01).** The **final A8-inclusive independent
   Freeze Readiness Audit was completed**, **Architect Acceptance was issued**,
   and the **Document Owner explicitly approved freeze** (§33). This item is
   **discharged** and is preserved as a standing governance rule: because the
   commercial record is now frozen, any **post-freeze** amendment requires a
   **fresh** independent Freeze Readiness Audit and **fresh** Architect Acceptance
   before the amended text may be represented as final.
   **A6 specifically does not satisfy item 8.** A6 is a documentary
   correction-only amendment: it closes no commercial entry, narrows none,
   reclassifies none, and resolves **none** of the `MUST RESOLVE BEFORE FREEZE`
   entries. As of A6 the commercial-freeze blocker set was unchanged at
   **`OQ-04`, `OQ-20`, `OQ-37`**. The independent re-audit required by this item
   had **not** been performed and Architect acceptance had **not** been recorded.
   **A7 also does not satisfy item 8.** A7 closed those three entries, so
   `MUST RESOLVE BEFORE FREEZE` is now **0**, but A7 is a **documentation-only
   decision-recording pass**: it is itself the amendment under audit, and it
   performs **no** independent re-audit of the result and records **no** Architect
acceptance of it. As of A7, the independent Freeze Readiness Audit and
    Architect acceptance required by this item **had still not occurred**, and A7
    explicitly did not declare the document frozen (§31.4). *That statement
    remains accurate as history about the A7 state; it is superseded as current
    status by the 2026-10-01 freeze (§33).*
9. **A8 reopening, and the status of the prior Final Freeze Readiness Audit (added
   by Amendment A8).** A **Final Freeze Readiness Audit** was performed at
   Document Owner request and found the model commercially complete **in its
   pre-A8 state**. The Document Owner and the Architect then **intentionally
   reopened the commercial design before freeze** in order to address cold-start /
   first-business acquisition, and A8 recorded the resulting decisions in §32.
   Consequences, mandatory:
   1. The prior Final Freeze Readiness Audit is **VALID FOR THE PRE-A8 STATE
      ONLY**. It remains a valid record of the pre-A8 audit and is **preserved**
      as history; it is **not** withdrawn and **not** invalidated retroactively.
2. That audit is **no longer sufficient by itself** to support a final freeze
       decision, because the commercial record changed after it was performed.
       A **fresh independent Freeze Readiness Audit over the A8-inclusive
       document** was therefore required before the Document Owner could consider
       a freeze declaration, together with recorded **Architect acceptance**.
       **This requirement was `SATISFIED` on 2026-10-01**: the final A8-inclusive
       independent Freeze Readiness Audit was completed over the A8-inclusive
       document and Architect Acceptance was issued (§33).
    3. **A8 itself does not satisfy this item.** A8 is a **documentation-only
       decision-recording pass** by the same authority that commissioned the prior
       audit; it performs no independent re-audit of its own result and records no
       Architect acceptance of it. *Accurate as history about A8; the freeze basis
       is the later A8-inclusive audit and Architect Acceptance, not A8 itself
       (§33).*
   4. `IMPLEMENTATION_AUTHORIZED` remains `NO`, the roadmap is unchanged, and
      §1.2 (L-47) is unchanged.
5. Because A8 reopened the design **before** freeze, no statement could
       describe Commercial Model V1 as complete, final, closed, or frozen
       (§1.6 items 1 and 3). *That prohibition governed the pre-freeze period
       only and ended with the 2026-10-01 freeze declaration (§33). It never
       extended to implementation: in **both** states no statement may describe
       Commercial Model V1 as implemented (§1.2, L-47).*
10. **Only the Document Owner may declare the freeze**, by explicit update to this
    document per §1.5. (Recorded by A2 and restated here unchanged.)
11. **Freeze declared (2026-10-01).** The Document Owner exercised the authority in
    item 10: the **final A8-inclusive independent Freeze Readiness Audit =
    `SATISFIED`**, **Architect Acceptance = `SATISFIED`**, **explicit Document
    Owner freeze declaration = `SATISFIED`**, **`MUST RESOLVE BEFORE FREEZE` = 0**,
    and **freeze state = `FROZEN`** (§33). The freeze changed **0** commercial
    decisions, closed **0** and reclassified **0** Open Questions, converted **0**
    `PROVISIONAL` or `DEFERRED` items to `LOCKED`, and grants **no** implementation
    authorization (§1.2, L-47). Items 3, 8, and 9 remain preserved as the standing
    governance rules that any post-freeze amendment must satisfy again.

---

## 2. LOCKED BUSINESS MODEL

### 2.1 Core rules

| # | Rule | Status |
|---|---|---|
| 2.1.1 | The Public Business Directory is **paid-only**. | `LOCKED` — **reinforced by A8-1** (§32.1 → L-88): paid-only remains the rule and no permanent free commercial tier was introduced. A8-11 (§32.11 → L-97) permits an explicitly **temporary** Launch Partner promotional commercial entitlement to count toward launch-category supply density; that is **not** a weakening of paid-only publication (§2.5, §31.3). |
| 2.1.2 | There is **no permanent free public listing**. No **permanent** free tier and no lifetime-free public listing exists. | `LOCKED` — **second sentence narrowed by A8-1 and A8-2** (§32.1, §32.2 → L-88, L-89). The pre-A8 wording of the second sentence — "No tier, trial, or lifetime-free public listing exists" — is **`SUPERSEDED` in its absolute form** and must be read as: no **permanent** free tier or lifetime-free public listing exists. A8-2 authorizes exactly one class of **explicitly temporary** commercial access (the Launch Partner promotional period of **60 calendar days** of Business Pro at **0 IQD**), which is **not** a tier, **not** permanent, and creates **no** free-plan precedent. The first sentence — "no permanent free public listing" — is **unchanged and reinforced** (L-02, L-88). Historical wording preserved per §1.5 rule 3. |
| 2.1.3 | A Business subscription belongs to the **Business Entity**, not to a User Account. | `LOCKED` |
| 2.1.4 | `Brand`, `Business Entity`, `Branch`, and `User` are **four distinct concepts** and must never be conflated in data, UI, or sales language. | `LOCKED` |
| 2.1.5 | A user's departure, deletion, or loss of access never destroys the Business Entity, its subscription, or its content. | `LOCKED` |
| 2.1.6 | One User may hold memberships in multiple, unrelated Business Entities. | `LOCKED` |
| 2.1.7 | Commercial presence in the public directory is an entitlement of a paid Business Entity. A user account alone confers no public commercial presence. | `LOCKED` — **clarified by A8-2/A8-11**: a paid Business Entity normally holds a paid subscription, and during the initial Launch Partner phase a selected Launch Partner Business Entity may hold an **explicitly temporary promotional commercial entitlement** instead. Either way the entitlement belongs to the **Business Entity**, never to a user account, and neither a free user account nor a Civilpedia-created Draft confers public commercial presence (L-03, L-88, L-89, L-92). |
| 2.1.8 | The Paid-Only rule applies to the **future Commercial Production Directory** (§2.5). | `LOCKED` |
| 2.1.9 | Only **commercial organisations** inside the §27.1 eligibility boundary may hold a paid Business listing. Individual professionals are excluded, and engineering/consulting/laboratory organisations remain reserved for the deferred models. | `LOCKED` — added by A4-8 (§27.1) |

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
| The disposition of specific existing non-production rows at launch (convert or remove) remains undecided — `OQ-22`. **Grandfathering them as entitled production listings is excluded by A4-9** (§27.2); the disposition action itself is routed to a future architecture/launch slice. | `PROVISIONAL` — open question §24.3 |
| Any enforcement, conversion, or cleanup action on existing data. | `PROVISIONAL` — requires a separately authorized slice |
| Launch density and sequencing: minimum paid businesses required per Category × Area before an area opens publicly, category rollout order, launch geography, and the user experience of an empty category or area. | **Decided by A7-3** (§31.3 → L-87) — `OQ-37` **CLOSED**. Baghdad first; Category Launch Gate of 5 active paid publicly publishable Businesses; ~8–10 per-category and ~30 overall launch **targets**; below-gate categories hidden or shown as "Coming Soon / قريباً" and never padded with fake/free listings; the 5-Business threshold is a launch gate, not an automatic shutdown threshold; a category at zero shows an honest empty/unavailable state (exact UX: `OQ-68`, `OQ-76`). **Narrowed by A8-11** (§32.11 → L-97): during the **initial Launch Partner phase only**, an authorized Launch Partner holding a valid Business Entity, an **active A8 promotional commercial entitlement**, and a publicly publishable profile **MAY** count toward launch-category supply density as a **COMMERCIAL-ACTIVE BUSINESS**. This is **not** a free listing, **not** a new tier, and does **not** weaken the Paid-Only rule; for ordinary post-launch paid operation a **paid subscription remains the normal entitlement basis**. Post-promotion treatment of a category that reached the gate partly this way → `OQ-84`. |
| Which directory categories are eligible for a paid Business listing, and which are withheld pending the deferred professional/organisation models (§22). | **Decided by A4-8** (§27.1) — commercial organisations only; individual professionals excluded; engineering/consulting/laboratory organisations withheld pending the §23 research |

No seed data, mock data, fixture, or preview record was modified by this document.

---

## 3. PLANS

### 3.1 Approved plan structure

| Plan | Position in lineup | Status |
|---|---|---|
| Business | Entry paid plan | `LOCKED` |
| Business Pro | **Primary / default commercial recommendation** | `LOCKED` |
| Business Plus | Upper self-serve plan | `LOCKED` |
| Corporate | Quotation-based enterprise plan | `LOCKED` (A3; structure confirmed and extended by A7-1 → L-84, §31.1) |

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

The commercial **consequences** of a future price change are **decided** by A3-3
(§26.3): a price change never alters an already-paid unexpired term, no
retroactive price difference is collected, and the new official price applies at
the next renewal after its effective date — `OQ-28` **CLOSED**. Whether instalment
or deferred payment is permitted is **decided** by A5-21 (§28.12): Business,
Business Pro, and Business Plus are prepaid, Corporate may use individually
approved written terms — `OQ-60` **CLOSED**.

### 3.3 Default recommendation

| Rule | Status |
|---|---|
| Business Pro is the intended primary/default commercial recommendation. | `LOCKED` |
| Where, how, and in what wording that recommendation is surfaced (sales material, Business Center, comparison tables). | `PROVISIONAL` |
| Plan feature/entitlement matrix per tier beyond branches (§4) and media (§16). | `PROVISIONAL` — entitlement review (dependency D-25; registry P-03). This item is **not** an Owner open question; it is an entitlement-review dependency, correctly registered as `P-03` (§25.2) and routed by `D-25` (§24.2) and therefore falling under **§1.3 rule 6(b)** rather than rule 6(a). |
| Corporate plan contents, minimum commitment, and quotation process. | **Decided by A7-1** (§31.1 → L-84, L-85) — `OQ-04` **CLOSED**. Corporate is quotation-based, floors at ALL Business Plus entitlements, may extend by written quotation, has a **12-month minimum commitment**, is priced **Custom Quote** with no fixed public price, and its quotation has a **30-calendar-day default validity** (preserving A5-21 / §28.12.3). A7 sets **no** numeric included branch count, so `P-02` remains `PROVISIONAL`. |
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
| 5.1a | **Founding Partner ≠ Launch Partner (A8-2, §32.2.4 → L-89).** Founding Partner is an **annual first-year discounted-pricing programme** for the initial first-50 cohort (§5.7). **Launch Partner** (A8-2, §32.2) is a separate **temporary, invitation-only, 60-calendar-day Business Pro promotional entitlement** for a Civilpedia-selected cold-start cohort of approximately 20–30 businesses. They are **distinct concepts with distinct commercial mechanisms, and must not be merged, substituted, or presented as one programme.** A Business Entity that satisfies the eligibility rules of both may receive **both**, in the approved order: first the temporary Launch Partner promotional Pro access, and later the eligible Founding Partner first-year **paid** discounted pricing. | `LOCKED` — added by A8-2 (§32.2.4) |
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
| Whether Founding Partner is re-offered in a later cohort. | **Decided by A3-3** (§26.3): Founding Partner is the **initial first-50 cohort**; no future Founding Partner cohort is promised or implied. A later cohort requires a new explicit Owner commercial decision and is `DEFERRED` (D-18) — `OQ-66` **CLOSED**. |

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
| 6.1.11 | Minimum advertiser eligibility (whether a Verified state is required to buy a placement) and the prohibited advertiser categories / prohibited advertising content. | **Decided by A5-12** (§28.3) — `OQ-34` **CLOSED**. Sponsored does **not** require Verified; eligibility is an eligible active plan where §6.1.8 requires Pro/Plus, publishability, profile-quality compliance, and advertising content related to the actual Business. |
| 6.1.12 | The Civilpedia-owned **business acquisition CTA** is **NOT** Sponsored inventory and does **not** consume, occupy, or compete for Sponsored Category × Area inventory. | `LOCKED` — added by A8-4.1 (§32.4 → L-91). The acquisition CTA is a **first-party Civilpedia promotional surface** inviting businesses to join the commercial directory. It must never be counted, labelled, reported, or sold as third-party Sponsored advertising, must never be bought by an advertiser, and must never be attributed to Sponsored campaigns (L-16, L-73). |

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
| Target of approximately **2–3 active sponsored positions per Category × Area**. | `PROVISIONAL` — a target, not a frozen cap (P-06) |
| Whether 2–3 is a hard cap, a soft target, or queue-based. | `PROVISIONAL` — exact cap mechanics may remain provisional for launch tuning unless already `LOCKED` elsewhere (A5-12, §28.3); P-06. `OQ-18` **CLOSED**. |
| How "Area" is defined for inventory purposes (governorate / district / custom radius). | `PROVISIONAL` — A5-12, §28.3; P-06. `OQ-18` **CLOSED**. |
| Oversubscription behaviour, rotation, and fairness policy. | Not decided → `OQ-73` (registered by A5-12) |
| Campaign management tooling, creative rules, and disclosure copy. | `DEFERRED` (§21) |
| Sponsored inventory is **finite** per Category × Area; Civilpedia must **not oversell unavailable slots**, and **waitlisting is preferable to selling non-existent inventory**. | `LOCKED` — added by A5-12 (§28.3) |
| Sponsored renewal, cancellation, and refund terms, and the commercial outcome when an advertised entity becomes unavailable mid-campaign. | **Decided by A5-12** (§28.3) — `OQ-33` **CLOSED** |

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
   separately (§24.1 C-4, §24.2 D-26).

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
| 7.2.5 | The commercial **outcome** rules for payment exceptions (short, long, wrong account/agent, duplicate claim of one transfer, third-party payer, payment for an Expired or closed business). The 10th step above is reached only from a `Payment Verified` state and is never a bypass. | **Decided by A5-10** (§28.1) — `OQ-31` **CLOSED** |
| 7.2.6 | Retention period, access control, business-facing visibility, and deletion of transfer receipts, business registration files, identification documents, and internal staff notes. | Privacy boundary **decided by A5-17** (§28.8). Exact statutory retention/deletion periods are **not** invented here and are routed to Iraqi legal/accounting review — `OQ-40` reclassified `LEGAL/POLICY REVIEW` |

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
| Commercial V1 canonical pricing and accounting currency is **IQD**. Payment must use **Civilpedia-approved payment destinations / rails**; future electronic-payment integration must use appropriately authorized/regulated providers. | `LOCKED` — A5-10 (§28.1), L-70 |
| No automated payment gateway in Commercial V1. | `DEFERRED` (§21) |
| Accepted bank accounts / transfer rails, supported currencies, and settlement accounts. | The **currency** is `LOCKED` (IQD, A5-10). The specific approved destinations, bank accounts, and settlement accounts remain undecided and are routed to Iraqi e-payment/regulatory review — `OQ-09` reclassified `LEGAL/POLICY REVIEW` |
| Invoicing, receipts, tax/fiscal treatment, and accounting export. | Not decided — explicitly routed to qualified Iraqi accounting/legal review; **no** VAT, invoice, tax, or consumer-law requirement may be invented here — `OQ-08` reclassified `LEGAL/POLICY REVIEW` |
| Refund, cancellation, and partial-refund policy. | **Decided by A5-11** (§28.2) — `OQ-07` **CLOSED** |
| Anti-fraud controls beyond receipt verification (duplicate transfer, mismatched amount, third-party payer). | **Policy outcomes decided by A5-10** (§28.1). The concrete control mechanisms are a future architecture task — `OQ-10` reclassified `IMPLEMENTATION ARCHITECTURE` |
| Customer-outcome rules for payment exceptions: short payment, overpayment, wrong account/agent, duplicate claim of one transfer, third-party payer, and payment for an Expired or closed business. | **Decided by A5-10** (§28.1) — `OQ-31` **CLOSED** |
| Staff handling rules for payment conversations (who may confirm, who may activate), and the expected verification turnaround. | **Decided by A5-10** (§28.1) — `OQ-11` and `OQ-62` **CLOSED** |

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
| Grace Period | Term ended; the business **retains its data** throughout a defined window. Whether **management access continues** during Grace, and in what mode, is **not decided by this row** — `OQ-12`. | `LOCKED` (data retention only, L-25) — access mode `PROVISIONAL`, `OQ-12` |
| Expired | Grace Period ended; public directory presence hidden. | `LOCKED` |

**Known vocabulary gap (recorded by A2; closed by Amendment A3).** As of A2 the
approved vocabulary above had **no state for administrative suspension or
termination for policy violation**, and it had no date-anchor rule (no defined
term start, end, or renewal date). A3 closes both gaps: `OQ-25` is closed by
A3-1 (§26.1) and `OQ-30` is closed by A3-4 (§26.4). The Owner has now additionally
approved the distinct commercial concepts **Suspended**, **Terminated** (§26.4)
and **Permanently Closed** (§26.5), recorded in §§26.4–§26.5 and registered as
`LOCKED` commercial concepts. They are **not** database enums and imply no
persistence (§8.4, §24.1 C-3, L-47).

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
| Rejected / unresolved | Only where a later defined policy introduces it. | `LOCKED` as a concept — **A5-10** (§28.1) introduces a **Needs Clarification** (remains unverified) outcome and a rejection → enforcement/fraud-review route. `OQ-31` **CLOSED**. Persistence remains `PROVISIONAL` (§8.4). |

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
| 8.3.6 | Grace Period exact duration. | **Decided by A3-2** (§26.2) — **5 calendar days** — `OQ-12` **CLOSED** on duration |
| 8.3.7 | Current Grace Period target: approximately **3–7 days**. | **Superseded by A3-2** (§26.2): Grace is exactly 5 calendar days and occurs **after** paid term expiry, not inside the paid term. The 3–7 day target is historical and no longer quotable. |
| 8.3.8 | Whether management access continues during Grace Period (read/write), and what the owner sees. | Not decided → `OQ-12` (narrowed by A3-2 to the Grace-period access mode and owner view only; routed to Business Center design) |
| 8.3.9 | Renewal pricing, upgrade/downgrade mid-term, proration, and downgrade when branch count exceeds the new tier. | **Decided** — renewal pricing by A3-3 (§26.3); upgrade/downgrade/proration by A5-11 (§28.2). `OQ-05` and `OQ-06` **CLOSED**. The exact proration formula is a future architecture/finance design value (P-34). |
| 8.3.10 | Whether an expired business retains analytics history and internal records visibility. | Not decided → `OQ-17` |
| 8.3.11 | Grace-period expiry notices, channels, and language (Arabic-first). | **Decided by A3-2** (§26.2) — cadence, suppression rules, and channels are `LOCKED`; the customer-facing language is Arabic (§28.14). `OQ-29` **CLOSED**. |
| 8.3.12 | State-machine / persistence mapping to existing production state values. | `PROVISIONAL` — reconciled as C-3, see §8.4 |
| 8.3.13 | Subscription term anchor: when the paid term starts, when it ends, and when the renewal date falls. | **Decided by A3-1** (§26.1) — `OQ-25` **CLOSED** |
| 8.3.14 | Renewal mechanics: whether renewal must remain manual through WhatsApp / manual payment verification, whether auto-charge is prohibited or merely deferred, and whether stored payment instruments are excluded from Commercial V1; plus early-renewal term extension and renewal notice cadence. | **Decided by A3-2** (§26.2) — `OQ-29` **CLOSED** |
| 8.3.15 | Administrative suspension and termination for policy violation, including who may suspend, public visibility, whether the term clock pauses, money outcome, appeal, and re-entry condition. | **Decided by A3-4** (§26.4) — `OQ-30` **CLOSED**; the residual transfer-while-not-Active question is registered as `OQ-71` |
| 8.3.16 | Permanent business closure as a commercial event distinct from expiry, including its effect on subscription, prepaid funds, badges, sponsorship, data, and reactivation. | **Decided by A3-5** (§26.5) — `OQ-36` **CLOSED** |

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

Approved as a **candidate** evidence set — this is not an exhaustive or final policy.
A5-13 (§28.4) constrains this set: verification evidence may include **only what is
reasonably necessary**.

- phone verification;
- physical location;
- business identity;
- relevant registration / documents where applicable;
- Civilpedia field visit where required.

Status: `PROVISIONAL`. The per-category evidence checklists remain deferred to the
verification policy document — `OQ-13`.

### 9.3 Possible verification states

| State | Status |
|---|---|
| Unverified | `PROVISIONAL` |
| Verification Pending | `PROVISIONAL` |
| Verified | `PROVISIONAL` |
| Verification Suspended | `PROVISIONAL` |

The **state vocabulary** is approved as the intended set; the exact verification
policy, thresholds, per-category evidence checklists, turnaround, appeals, and
suspension triggers remain a **later detailed policy** — narrowed by A5-13
(§28.4) to the policy document and its per-category checklists only — `OQ-13`
(reclassified `DEFERRED`).

| Open item | Status |
|---|---|
| Verification policy document and per-category evidence checklists. | `DEFERRED` to a later policy — `OQ-13` |
| Who may verify, and whether verification is staff-only. | **Decided by A5-13** (§28.4): only authorized Civilpedia staff/authority may grant or withdraw Verified; there is **no self-verification**. `OQ-50` **CLOSED**. |
| Whether verification affects organic ranking. | `PROVISIONAL` — see §18.2; residual registered as `OQ-74` |
| Public display of verification state and its exact wording. | `PROVISIONAL` — see §14.5 — `OQ-14` |
| Verification validity period, reverification triggers, whether renewal requires re-verification, verification granularity for multi-branch entities, the consequence of false documents, and what the badge substantively asserts. | **Decided by A5-13** (§28.4) for validity, reverification triggers, renewal, the meaning/non-guarantees of the badge, and the consequence of false documents — `OQ-35` **CLOSED**. Multi-branch granularity remains with the deferred verification policy — `OQ-56`. Whether Verified may act as an **organic ranking input** is a separate residual — `OQ-74`. |

---

## 10. BUSINESS ONBOARDING

### 10.1 Model

| Rule | Status |
|---|---|
| Onboarding is **Hybrid**: Civilpedia may perform substantial setup work, and the business owner completes ownership and identity steps personally. | `LOCKED` — **reinforced by A8-5** (§32.5 → L-92): the substantial setup work is expressly permitted and may include a Business Draft created before any owner is attached. |
| Preferred flow: Lead → Agreement → Payment Verified → Civilpedia creates a professional Business Draft → Business owner creates their own Civilpedia User Account → Civilpedia links/invites the owner → Owner accepts Business ownership → Content review → Published. | `LOCKED` (approved sequence) — **reinforced by A8-6** (§32.6 → L-93), which makes **INVITATION** the preferred and default ownership-assignment method and confirms the "Civilpedia links/invites the owner" step. |
| Civilpedia staff must **NOT** create and hand over passwords to business owners. | `LOCKED` — **reaffirmed by A8-6.3 and A8-7.2** (§32.6, §32.7 → L-93): Civilpedia must not create a password and hand the credentials to the Business; each natural person uses their own Civilpedia account; and direct ownership assignment must not involve shared credentials or password handover. |
| The Business remains an entity **separate** from the user's login account. | `LOCKED` |
| A business may exist as a Business Entity before any owner user account exists. | `LOCKED` (implied by the draft/ownership sequence) — **made explicit by A8-5.3/A8-5.4** (§32.5 → L-92): such a record is `CIVILPEDIA-MANAGED / OWNER NOT YET ATTACHED` until ownership is assigned and accepted, and the staff-created Draft does **not** itself prove ownership. |
| Exact UI, invitation mechanics, and acceptance screens for ownership transfer-in during onboarding. | `PROVISIONAL` — **narrowed by A8-6** (§32.6 → L-93). The **method** is now decided: ownership assignment is by **invitation and acceptance**. Remaining mechanics (invitation expiry/timeout, re-invitation, decline handling, alternate invitee) → **`OQ-83`**; persistence, route, and screen implementation → `OQ-77`, P-25, D-28. *(Repaired by A8: the pre-A8 text of this row carried an unresolved marker with no registered `OQ-nn` citation, which was a defect under §1.3 rule 6.)* |
| Handling of a pre-existing Civilpedia User Account that later owns a business. | `PROVISIONAL` |
| Whether a User Account is mandatory before publication. | **Resolved by A4-9** (§27.2) together with the already-`LOCKED` onboarding sequence in §10.1: the owner creates their own account and accepts Business ownership **before** Content review and Published. `OQ-21` **CLOSED**. This is a consequence of the existing `LOCKED` sequence, not a new decision. |
| Rejected/expired lead handling and re-application. | Not decided → `OQ-51` |
| **Launch Partner** promotional onboarding: the order and interaction between Civilpedia-selected Launch Partner status, the temporary 0 IQD / 60-day Business Pro promotional entitlement, Business Draft creation, ownership invitation, and first successful public publication. | **Decided in principle by A8-2** (§32.2 → L-89): Civilpedia staff may create the Draft; the promotional clock starts at the **later** of formal commercial launch or the Business's first successful public publication; publication still requires entitlement, Minimum Profile Quality, ownership/onboarding, and moderation (§32.5.6). Remaining cohort-administration and status-lifecycle decisions → **`OQ-80`**; promotional-continuity on ownership/entity change → **`OQ-81`**. |
| **Civilpedia-managed Business Drafts with no attached owner**: retention, disposition, and whether a different business may later be attached. | **Decided in part by A8-5** (§32.5 → L-92): such a Draft is `CIVILPEDIA-MANAGED / OWNER NOT YET ATTACHED`, is not ownership evidence, and cannot be published without all applicable requirements. Remaining retention/disposition/attachment questions → **`OQ-82`**. |
| Business claiming: which directory categories may hold a paid Business listing versus which are reserved for the deferred professional/organisation models (§22), and which parties may be listed at all. | Not decided → `OQ-26` |
| Claiming, competing claims, and duplicate real-world businesses: who may claim, what evidence resolves a claim, who arbitrates a competing claim, and what a false claim causes. | **Decided for Commercial V1 by A4-9** (§27.2): there is **no** open public "Claim this business" workflow; open/competing claims are deferred until a dedicated evidence/dispute model exists. `OQ-27` **CLOSED** |
| Duplicate/overlapping Business Entity control: detection basis, merge authority, and consequence where one real business exists as several entities. | Consequence and merge authority **decided by A3-6** (§26.6) — `OQ-32` **CLOSED**; the detection basis and merge/retirement mechanics are a future architecture task — `OQ-72` |

---

## 11. BUSINESS OWNERSHIP / ROLES

### 11.1 Initial role model (commercial product names)

| Role (commercial) | Intent | Status |
|---|---|---|
| Owner | Highest business authority. | `LOCKED` (capability concept, §11.1a) — **A8-8** (§32.8 → L-94) preserves the concept and states its operational intent as **Primary Business Owner: highest accountable ownership authority**. |
| Co-Owner | Ownership participation; not automatically equivalent to the Primary Business Owner for sensitive ownership transfer. | `LOCKED` (capability concept) — **added by A8-8** (§32.8 → L-94), consistent with A7-2 / `L-86`, which permits one or more verified **Co-Owners** alongside exactly **one Primary Business Owner**. |
| Manager | Business operational / profile management. | `LOCKED` (capability concept, §11.1a) — **A8-8** (§32.8 → L-94) states its operational intent as **operational management without ownership authority**. |
| Editor | Content-focused permissions. | `LOCKED` (capability concept, §11.1a) — **A8-8** (§32.8 → L-94) states its operational intent as **limited content-management capability**. |
| Civilpedia Admin | Platform-side management access, **not** a business membership. | `LOCKED` — **A8-7** (§32.7 → L-93) makes direct ownership assignment an **admin-only exceptional capability**; this does **not** merge platform authority into business membership (§11.2). |

These are **commercial product role names**. They are not asserted to exist as
stored roles, enum values, or permission checks. See §11.1a.

Descriptive intent of each role: `PROVISIONAL`.
Exact permission matrix: **`PROVISIONAL` until Business Center design** — not frozen.

Not decided: nothing further on team seat limits per plan or on which capability
levels may view payment and financial records — **both are decided by A5-20**
(§28.11): an operational default ceiling of 5 active team members for ordinary
Business plans, Corporate custom, and financial/subscription information visible
only to the **Business Owner** and explicitly finance-authorized roles — `OQ-46`
**CLOSED**. Exact RBAC/storage mapping remains deferred (P-25, D-28).
Resolved by A3–A5, so no longer open: the "Owner" name used for both the
business capability role and the document decision authority — `OQ-63`
**CLOSED**; the two are now **Business Owner** and **Document Owner**
respectively (§26.0, L-64).

### 11.1a Capability levels vs stored role vocabulary (C-1 — non-authorization)

The commercial product defines three **capability levels** conceptually. These are
`LOCKED` as product intent:

| Capability level | Intent | Status |
|---|---|---|
| Business owner / highest authority | Final business authority. | `LOCKED` (capability concept) — **A8-8** (§32.8 → L-94): **Primary Business Owner — highest accountable ownership authority**. |
| Business operational manager | Business operational and profile management. | `LOCKED` (capability concept) — **A8-8** (§32.8 → L-94): **operational management without ownership authority**. |
| Content-focused editor | Content-focused permissions. | `LOCKED` (capability concept) — **A8-8** (§32.8 → L-94): **limited content-management capability**. |
| Business co-owner (**added by A8-8**) | Ownership participation; **not** automatically equivalent to the Primary Business Owner for sensitive ownership transfer. | `LOCKED` (capability concept) — A7-2 / `L-86`, §32.8 |

**Amendment A8-8 (additive — §32.8).** A8-8 **preserves** these capability
concepts and locks **only their operational intent**. A8-8 explicitly creates **no**
stored role enum, **no** new stored role value, **no** RBAC matrix, and **no** RLS
policy. The **exact stored role enum / RBAC matrix / RLS implementation remains
`DEFERRED`** (P-25, D-28, `OQ-77`) and is **not** decided by A8.

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
| 2 | New owner accepts. | `LOCKED` — **A8-6** (§32.6 → L-93) makes **invitation and acceptance** the preferred and default ownership-assignment method; a **pending invitation must not silently grant ownership before acceptance**. |
| 3 | Civilpedia verifies. | `LOCKED` — **A8-7.7** (§32.7 → L-93): a direct assignment **must not bypass ownership verification** where verification is otherwise required. |
| 4 | Transfer completes. | `LOCKED` |
| — | **No instant, uncontrolled transfer.** | `LOCKED` |
| — | Exact request/accept UI, evidence, timeouts, and rejection handling. | `PROVISIONAL` — invitation **mechanics** (expiry, re-invitation, decline, alternate invitee) → `OQ-83`; evidence → `OQ-79`; implementation → `OQ-77`, P-25, D-28 |
| — | **Admin-only exceptional direct assignment** (as distinct from invitation). | **Decided by A8-7** (§32.7 → L-93): may exist as an **admin-only exceptional capability**; may only target an **already identifiable Civilpedia user account**; must not involve shared credentials or password handover; must create an **auditable record** (acting Civilpedia admin, affected Business, target user, role/capability assigned, timestamp, reason/context where required); routine onboarding still prefers invitation/acceptance; Primary Business Owner assignment should normally require acceptance/verification; emergency/override behaviour, exact security controls, and audit persistence → D-28, **D-33** |
| — | What happens to other memberships when ownership moves. | `PROVISIONAL` — `OQ-78` |
| — | Co-ownership, multiple simultaneous owners, or an entity without an owner. | **Decided by A7-2** (§31.2 → L-86) — `OQ-20` **CLOSED**: exactly **ONE Primary Business Owner** in normal operation, plus optional verified **Co-Owners** subject to team limits; Primary Owner holds accountable authority for sensitive ownership operations and a Co-Owner does not automatically match it; an entity with no available Primary Owner enters the conceptual **OWNERSHIP RECOVERY PENDING** state (§11.3, `OQ-79` for evidence requirements) |
| — | Ownership transfer of a Branch independent of the parent entity. | Not decided → `OQ-19` (branch closure is addressed by A3-5, §26.5) |
| — | Ownership transfer while the Business Entity is Expired, Suspended, or Permanently Closed. | Not decided → `OQ-71` (residual registered by A3-4/A3-7) |
| — | Transferability of a paid subscription when a business is sold to a new legal person. | **Decided by A3-7** (§26.7): the subscription belongs to the Business Entity; remaining value may remain with the same genuine Business Entity after a verified legitimate transfer; a materially new entity requires new-entity assessment. `OQ-39` **CLOSED**. |

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
| Review turnaround, reviewer roles, and rejection messaging. | Review service targets **decided by A5-13** (§28.4): sensitive-content review ≈ 2 business days; verification/appeal up to 5 business days where practicable (internal expectations, not guarantees). Reviewer roles, rejection messaging, and audit/rollback remain → `OQ-52` (narrowed) |
| Change history / audit visibility to the business, and rollback of an approved change. | `PROVISIONAL` — `OQ-52` |
| Appeal route for a **content** rejection (distinct from verification appeals `OQ-13`, and from the termination appeal decided by A3-4), public abuse reporting against a business, and repeat-offender handling. | Not decided → `OQ-57` |
| Prohibited and misleading claim policy (superlatives, false certification, false institutional affiliation, fabricated projects). | **Decided by A5-14** (§28.5) — `OQ-45` **CLOSED** for prohibited claims; uploaded-media rights declaration, takedown, and repeat infringement remain → `OQ-75` (registered by A5-14) |
| Rights declaration for uploaded media, takedown, and repeat media infringement. | `PROVISIONAL` — `OQ-75` (was partly `OQ-45`; legal/policy review required before the rule is published) |
| Accuracy responsibility for business-submitted prices, "price on request" content, and stale prices. | **Decided by A5-14** (§28.5) — `OQ-43` **CLOSED** |
| Offer validity window and behaviour of an expired offer. | **Decided by A5-14** (§28.5) — `OQ-43` **CLOSED** |
| Evidence required before a business may state that it is an authorised dealer, agent, or representative of a Brand. | **Decided by A5-14** (§28.5) — `OQ-44` narrowed and **CLOSED** on the evidence question; Brand-concept governance remains → `OQ-44` |

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
| Payment receipts, payment identifiers, plan/payment admin data, internal verification notes, internal fraud/risk notes, and sensitive identity evidence | `LOCKED` — added by A5-17 (§28.8) |

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
| Exact badge wording, placement, and Arabic copy for Verified / Founding Partner / Sponsored. | `PROVISIONAL` — `OQ-14`. **Narrowed by A5-13** (§28.4): the preferred public wording concept for Verified is recorded ("تم التحقق من معلومات النشاط بواسطة Civilpedia"); final Arabic copy and placement remain open. |
| What the Verified badge substantively asserts, and what it expressly does not guarantee. | **Decided by A5-13** (§28.4) — `OQ-35` **CLOSED** |
| Whether Sponsored labeling appears in search results, category lists, map views, and related-business rails. | `PROVISIONAL` — `OQ-14` (A5-12, §28.3 makes clear labeling mandatory on **every** Sponsored surface) |
| Whether similar-businesses ordering may be influenced commercially. | `PROVISIONAL` — must not become covert organic ranking (§6.1.4) |
| Public experience of an Expired, suspended, or removed listing reached by direct link, and whether its content is replaced or only marked. | **Narrowed by A3-5** (§26.5): a direct historic link must communicate that the business is **no longer active** and must not present misleading active business information. The exact presentation remains → `OQ-68` (Implementation Architecture) |
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
| Moderation, rights confirmation, and takedown handling. | `PROVISIONAL` — `OQ-75`, `OQ-57` |
| Storage limits, file size/type limits, and external hosting. | Not decided → `OQ-16` |
| Per-category module media limits. | Not decided → `OQ-16` |

### 16.1 Current working media baseline (NOT frozen)

| Plan | Working baseline | Status |
|---|---|---|
| Business | 6 images | `PROVISIONAL` |
| Business Pro | 20 images | `PROVISIONAL` |
| Business Plus | 40 images | `PROVISIONAL` |
| Corporate | not defined (per-quotation commercial variable) | `PROVISIONAL` — see P-02; `OQ-04` **CLOSED** by A7-1 (§31.1), which floors Corporate at ALL Business Plus entitlements and treats included branch count as a negotiated quotation variable rather than a fixed public value |

These counts are a **current working baseline only**. They must **not** be marked
permanently frozen, presented as contractual limits, or quoted to customers until
an entitlement review is completed and recorded in this document per §1.5.

---

## 17. ANALYTICS

### 17.1 Value principle

| Rule | Status |
|---|---|
| Even the **entry paid plan** must have basic value evidence. | `LOCKED` |
| Analytics must never be described as **confirmed sales**. | `LOCKED` — reinforced by A5-16 (§28.7) |
| Permitted framing concepts: `Interactions`, `Engagement`, and `Leads` **only** under the A5-16 measurement rule. | `LOCKED` (approved vocabulary), **narrowed by A5-16** (§28.7, L-76) |
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
entitlement-review matter (`PROVISIONAL` — P-03 / dependency D-25); the metric
definitions themselves remain `PROVISIONAL` — `OQ-17`.

**Amendment A8-3 (additive — §32.3).** Before Launch Partner promotional expiry,
Civilpedia should **where available** show the Business its factual usage metrics,
including Profile Views, WhatsApp Clicks, Call Clicks, Directions Clicks, and other
approved interaction metrics. These are **interaction metrics only** — they are
**not** guaranteed leads and **not** confirmed sales — and the A5-16 honesty rule
(L-77) continues to apply without exception. The commercial purpose is to let the
Business evaluate **actual observed value** before deciding whether to subscribe.
The **exact reporting UX and analytics storage** remain architecture/design work
(P-36, `OQ-77`); **pre-expiry promotional-period reporting visibility and
post-expiry retention** are registered as `OQ-17`. No metric, threshold, or
guarantee was invented by A8.

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
| Definition and permitted commercial use of the approved framing word "Lead", and the mandatory qualifier wherever it is used, given that Civilpedia cannot identify or contact individuals. | **Decided by A5-16** (§28.7) — `OQ-38` **CLOSED** |

**Metric naming preference (`LOCKED` — A5-16, §28.7).** Prefer exact metric
names: Profile Views, WhatsApp Clicks, Call Clicks, Directions Clicks, Offer
Views, Saves, Search Appearances, and so on. Civilpedia must not call profile
views or generic taps confirmed customers or sales, and no analytics metric may
imply a completed sale.

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
verification may act as a ranking input at all is **still not decided** — A5-13
(§28.4) fixed what the badge *means* but did not decide its ranking effect — the
residual is registered as `OQ-74`. It must never become a purchasable or
paid-adjacent signal (§6.1.4, L-42).

### 18.3 Branch-level local discovery

| Rule | Status |
|---|---|
| Branches may appear independently in local search results while remaining part of one Business Entity. | `PROVISIONAL` (approved direction) |
| Selecting a branch keeps the user within the same Business brand/profile relationship. | `PROVISIONAL` |
| Whether a branch result shows branch-only data or entity-level data. | `PROVISIONAL` |
| Branch-level deduplication and cannibalisation handling in results. | Not decided → `OQ-67` |
| Verification's effect on ranking. | `PROVISIONAL` — `OQ-74` (residual registered by A5-13) |
| Example relationship (one brand, multiple named branches) is illustrative, not a data commitment. | `PROVISIONAL` |
| Whether a Sponsored placement may be bought at **branch** level rather than entity level, and how that interacts with Category × Area inventory. | **Decided by A5-12** (§28.3): a branch-level Sponsored product is **`DEFERRED`** for V1; the initial Sponsored product attaches to the Business Entity. `OQ-53` **CLOSED** |
| Branch lifecycle: activation and deactivation of a branch, branch closure, relocation, and the effect of relocation on verification. | Not decided → `OQ-54` (A3-5, §26.5 decides only that affected branches are closed appropriately on confirmed permanent closure of the Business) |

---

## 19. PUBLICATION QUALITY

| Rule | Status |
|---|---|
| Payment alone does **not** guarantee publication. | `LOCKED` |
| A **Minimum Profile Quality** standard is required before Public status. | `LOCKED` |
| The publication gate is a **Required Fields Gate**, not an arbitrary public numerical quality score. | `LOCKED` — A5-15 (§28.6) |
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
| The quantitative Minimum Profile Quality standard and its validation mechanism. | **Decided by A5-15** (§28.6): there is **no** arbitrary public numerical quality score; publication uses a **Required Fields Gate** with the minimum areas in §19.1. `OQ-47` **CLOSED**. |
| Per-category variation of the minimum (e.g. manufacturer vs. contractor). | `PROVISIONAL` — the exact per-category field matrix/UX is Business Center/design work — `OQ-76` (registered by A5-15) |
| Consequence of falling below the minimum after publication (demotion, warning, grace). | Not decided → `OQ-48` (A5-15 decides the **pre-publication** case only: an incomplete profile remains Draft/not publishable) |
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

**Amendment A5-19 (additive — §28.10).** The expected Business Center commercial
capabilities are now enumerated by the Owner and are `LOCKED` as expectations:
subscription status; renewal / expiry / Grace state; payment status; verification
status; support / contact; evidence upload where allowed; Team; business switching
for users managing multiple Businesses; profile / media / products / services /
projects / offers / branches; analytics according to entitlement; and
subscription / renewal surfaces. `OQ-58` is **CLOSED**. Exact UX, routes, schema,
and RBAC remain separate architecture/design work — `OQ-77` (registered by A5-19).

Team seat limits and which capability levels may see payment and financial
records are **decided by A5-20** (§28.11) — `OQ-46` **CLOSED**; exact RBAC and
storage mapping remain deferred (P-25, D-28).

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

**Amendment A8-1.5 / A8-1.6 (additive — §32.1).** The Owner **reaffirms** this
boundary: **Individual Professionals / Workforce are a separate future model** and
are **NOT** converted into paid Business listings by A8. A8 creates **no** free
individual listing as a consolation, and A8 **does NOT define the future
Professionals/Workforce monetization model**. The Professional Marketplace and
Engineering Organisation commercial models remain `DEFERRED` (D-11, D-12) and must be
decided by a **separate explicit Owner decision** before any monetization is
described (`OQ-45`, L-45, L-65, §25.4 prohibition 13). **No statement may present an
A8 Launch Partner promotional entitlement as available to, or as pricing for, an
individual professional.**

**Amendment A4-8 (additive — §27.1).** The Owner has now **decided** the
Commercial V1 eligibility boundary in commercial terms: the Business commercial
plan is for **commercial organisations** such as companies, contractors, suppliers,
stores, manufacturers, equipment providers / rental businesses, and other
commercial or service businesses appropriate to the Business model. Individual
professionals — including individual structural designers, architects,
electrical/mechanical/MEP professionals, surveyors, and individual consultants —
must **not** be silently placed into this model. `OQ-26` **CLOSED**.

### 22.2 Do not yet assume an identical model for organisations

| Category | Status |
|---|---|
| engineering offices | `PROVISIONAL` — not assumed identical |
| consulting firms | `PROVISIONAL` |
| testing laboratories | `PROVISIONAL` |
| specialist engineering service providers | `PROVISIONAL` |

These require separate commercial research before any reuse of the Business plan
structure or pricing.

**Amendment A4-8 (additive — §27.1).** Engineering offices, consulting
organisations, laboratories, and specialist engineering organisations remain
**reserved for separate research/model decisions** where the SSOT already defers
them. They must **not** be silently treated as identical to ordinary Business
plans. The Professional Marketplace and Engineering Organisation commercial models
remain separate and `DEFERRED` (§23 A and B).

---

## 23. FUTURE STRATEGIC RESEARCH

Recorded as approved research directions. None of these is a decision, a price, or
a roadmap commitment.

**Amendment A4-8 confirmation (§27.1).** A4 did not open, narrow, or close either
deferred model. It **preserved** them: the Business commercial plan is not extended
to individuals or to engineering organisations by analogy, and their commercial
models remain separate research.

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
| C-9 | Paid-Only rule vs existing seed/mock listings | Paid-Only applies to the future Commercial Production Directory, together with Publication Quality (§2.1, §2.5) | Directory seed contains public listings and is plan-coupled to monetization scaffolding | Paid-Only does not require immediate removal of development/mock/seed/fixture/preview data; such data may continue during development; launch-time disposition of existing rows remains undecided and `PROVISIONAL` — `OQ-22` | `RESOLVED — COMMERCIAL PRODUCTION VS DEV/SEED DISTINCTION` |
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

**Amendment A8 note.** A8 added **no conflict** and resolved **no conflict**. A8
narrowed the **absolute** wording of the §2.1.2 sentence "No tier, trial, or
lifetime-free public listing exists" so that it is consistent with the single
**explicitly temporary** Launch Partner promotional period authorized by A8-2,
while leaving the governing rule "**no permanent free public listing**"
(`L-02`, `L-88`) **unchanged and reinforced**. That is a **documentary
reconciliation in favour of the existing `LOCKED` intent**, not the introduction of
a free tier, and it did **not** create, remove, or resolve a conflict. A8 also
recorded that `OQ-17` and `OQ-72` gained new dimensions and that
`OQ-80`…`OQ-84` are new open entries — none of which is a conflict.

### 24.2 Dependencies (not conflicts)

**Identifier namespace (Amendment A6, documentary; extended by A8).** Three
different `D` meanings existed before A6 and are now disjoint by construction:

1. **§24.2 dependency records** — `D-20`…`D-33` (this table).
2. **§25.3 `DEFERRED` commercial registry** — `D-01`…`D-19` (zero-padded), plus
   `D-34` added by A8. The identifiers `D-20`…`D-33` are **reserved** for §24.2 and
   are **not** §25.3 registry identifiers; A8 therefore numbered its new `DEFERRED`
   item `D-34` rather than reusing an occupied dependency-record string.
3. **§26.2 renewal-cadence date offsets** — now written `T-n` / `T+n`, where
   `T` = the paid term end date. These are **offsets, not identifiers**; the
   pre-A6 `D-n` spelling collided with the two registries above and is retired.

**A6 identifier mapping (dependency records).** Renumbered so that a padded
`D-nn` string resolves to exactly one registry. **Meanings are unchanged; only
the identifier string changed.** No `D-01`…`D-19` `DEFERRED` identifier was
reused, renumbered, or altered.

| Pre-A6 ID | A6 ID | Dependency |
|---|---|---|
| D-1 | D-23 | Business Center design phase |
| D-2 | D-24 | Verification policy |
| D-3 | D-25 | Entitlement review |
| D-4 | D-26 | Monetization slice (honest ad/campaign gating) |
| D-5 | D-27 | Arabic-first localization SSOT |
| D-6 | D-28 | Future RBAC design slice |
| D-7 | D-29 | Future monetization architecture slice |
| D-8 | D-30 | Future entitlement/persistence design slice |
| D-9 | D-31 | Language precedence for the commercial agreement |
| D-20 … D-22 | unchanged | already outside the `D-01`…`D-19` range |

| ID | Dependency | Note |
|---|---|---|
| D-20 | Legal / Policy Obligations Register review (added by A5) | §30 registers eleven policy-obligations areas that Civilpedia must maintain. Each requires qualified Iraqi legal/accounting review before production commercial launch. A5 drafts no legal text. |
| D-21 | Business Center commercial-surface design contract (added by A5-19) | Required before §20 commercial modules, §11 permission matrix, and §15 modules can be frozen — `OQ-77`. |
| D-22 | Iraqi e-payment compliance route (added by A5) | Any future integrated/electronic payment provider must be selected and implemented under the Central Bank of Iraq electronic-payment framework, including Electronic Payment Services Regulation No. 2 of 2024 — §29, `OQ-09`. |
| D-23 | Business Center design phase | Required before §11 permission matrix, §15 modules, §16 media, §20 UX can be frozen. |
| D-24 | Verification policy | Required before §9 evidence, states, and display can be frozen. |
| D-25 | Entitlement review | Required before §16 media baselines and the §3 tier matrix can be frozen. |
| D-26 | Monetization slice (honest ad/campaign gating) | Required before §6 Sponsored can be implemented or shown to users. |
| D-27 | Arabic-first localization SSOT | Any customer-facing commercial string (badges, plan names, states) must enter the localization SSOT, not hardcoded copy. |
| D-28 | Future RBAC design slice | Required before any capability-level → stored-role mapping is frozen (C-1). |
| D-29 | Future monetization architecture slice | Required before commercial catalog → PlanType/PlanTier/plans mapping is frozen (C-2). |
| D-30 | Future entitlement/persistence design slice | Required before §8 state machines and §2.3 Brand/Branch persistence are frozen (C-3, C-6). |
| D-31 | Language precedence for the commercial agreement (not decided — `OQ-69`) | D-27 covers user-interface strings only. Which language governs the commercial terms themselves is an Owner decision, not a localization task. **Narrowed by A5** (§28.14): Arabic is the controlling V1 **customer-facing** language; only the governing-language clause of the future commercial agreement remains open. |
| D-32 | Server-managed commercial catalog and admin-control architecture (added by A8) | Required before the A8-9 server-managed catalog requirement (§32.9) or the A8-10 administration requirement (§32.10) can be implemented. Covers taxonomy tables, category/subcategory/branch/visibility administration, caching, offline resilience, realtime strategy, Remote Config usage, admin-panel implementation, permissions, RLS, and synchronization. A8-9.5 explicitly **excludes** downloadable executable UI/code. **Not** a Document Owner commercial decision — routed here under §1.3 rule 6(b). |
| D-33 | Administrative ownership-override security, audit, and entitlement-administration policy (added by A8) | Required before the A8-7 admin-only direct-assignment path (§32.7), the A8-7.3 audit record, the A8-10 audit-log administration surface, or Launch Partner entitlement administration (§32.2) can be implemented. Covers emergency/administrative override behaviour, exact security controls, audit persistence and retention, and who may act. Complements D-28 (RBAC design) and D-30 (entitlement/persistence). **Not** a Document Owner commercial decision — routed here under §1.3 rule 6(b). |

### 24.3 Open Question register — commercial rules not yet defined (must not be invented)

Built by **Amendment A2** (2026-09-28). **Reconciled by Amendments A3, A4, and A5**
(2026-09-29). **Documentary correction by Amendment A6** (2026-09-29). A3–A5
recorded real Owner commercial decisions and therefore **closed 33 entries**
(including all three `CRITICAL` entries and every `CRITICAL`/`HIGH` payment,
suspension, closure, verification, transfer, claiming, and "Lead" question),
**narrowed 22 open entries**, **reclassified 7 open entries** to the correct
deferred authority, and **registered 7 new residual entries** (`OQ-71`…`OQ-77`)
that the Owner decisions exposed. A6 recorded **no** commercial decision: it
**closed 0**, **narrowed 0**, **reclassified 0**, and registered exactly **one**
new non-blocking documentary entry, `OQ-78`. **Amendment A7** (2026-09-29) then
recorded the three final Owner commercial decisions in **§31** and **closed 3
entries** — `OQ-04` (Corporate plan), `OQ-20` (ownership cardinality), and `OQ-37`
(launch density) — the last three `MUST RESOLVE BEFORE FREEZE` items — and
registered **one** new non-blocking entry, `OQ-79`, required by §1.3 rule 6 for the
ownership-evidence deferral in §31.2.12. **Amendment A8** (2026-09-30) then recorded
ten Owner commercial decisions in **§32** and **closed 0** entries. A8 **narrowed 3**
existing entries (`OQ-17`, `OQ-42`, `OQ-72`) to absorb the new cold-start dimensions without
creating duplicates, and registered **5** new **non-blocking** entries (`OQ-80`…`OQ-84`),
moving the register to **84** entries (**48** `OPEN` / **36** `CLOSED`). A8 also added
dependency records **`D-32`** and **`D-33`** so that the A8 implementation-architecture
matters route to §24.2 under §1.3 rule 6(b) instead of being mis-registered as Owner
commercial decisions. Entries marked `OPEN` remain undefined and must still not be
invented.

#### 24.3.0 Register rules (mandatory)

1. This register is the **single authoritative list** of unresolved commercial
   rules. §1.3 rule 3 and rule 6 make it mandatory that every in-body
   unresolved marker cites one of these IDs.
2. Status values in force:
   - `OPEN` — undefined by the Document Owner. No agent may answer an entry,
     infer an answer, or present one as decided.
   - `CLOSED` — answered by an explicit Owner commercial decision recorded in
     this document. A closed entry keeps its ID, its original question, and an
     explicit **trace** to the amending section. Closing an entry never deletes
     it and never silently rewrites history.
3. `MUST RESOLVE BEFORE FREEZE` means Commercial Model V1 cannot be frozen while
   the entry remains `OPEN` (§1.3 rule 7, §1.6).
4. `REGISTER BEFORE FREEZE` means the item must be visible and owned in the
   register, but does not by itself block the freeze.
5. `BUSINESS CENTER`, `IMPLEMENTATION ARCHITECTURE`, `LEGAL/POLICY REVIEW`, and
   `DEFERRED` mean the decision belongs to a later authorized phase; the entry
   records the dependency and must not be answered here.
6. Severity, owner, and classification are **triage metadata**, not commercial
   decisions. They were assigned by the Architect during A2 and carry no
   commercial meaning beyond freeze readiness. A3–A5 may **reclassify** them to
   route an item to its correct authority; reclassification is bookkeeping, not a
   commercial decision, and never changes the severity of a commercial risk that
   has actually been decided.
7. An in-body unresolved marker without a registered ID is a **document defect**
   to be repaired by registering the item — never by answering it.
8. **Residual registration rule (added by A3–A5).** Where an Owner decision
   answers most of a registered question but leaves an implementation-specific,
   design-specific, or legally-specific remainder, the Owner decision **closes**
   the parent entry with a trace and the remainder is **registered as a new
   `OQ-nn` entry** carrying the correct deferred authority. The remainder must not
   be left unregistered.
9. **A8 registration discipline (added by A8).** A8 inspected every existing `OPEN`
   entry touching onboarding, ownership invitations, Business Center, admin
   management, catalog/taxonomy, launch, promotions/trials, and subscriptions
   **before** registering anything, and applied these rules:
1. An existing entry is **reused or narrowed** only where A8 **explicitly**
   answers part of it. A8 narrowed `OQ-17` (analytics retention/counting, extended
   to promotional-period reporting), `OQ-42` (Launch Partner/Founding Partner
   interaction boundaries), and `OQ-72` (duplicate-entity detection,
   extended to launch-trial abuse).
   2. A question that is **implementation architecture** is **not** registered as an
      `OQ-nn`. It routes to a §24.2 dependency record (`D-32`, `D-33`) under §1.3
      rule 6(b). A8 uses this route for the server-managed catalog mechanism
      (§32.9.7), the admin ownership-override security/audit policy (§32.7.6), and
      the admin/Business control surfaces (§32.10.1–§32.10.2).
   3. A question that is **design/marketing configuration** is registered as
      `PROVISIONAL` in §25.2 (`P-35`, `P-36`), not as an `OQ-nn`.
   4. A **new** `OQ-nn` is registered only where A8 creates a genuine **unresolved
      Owner-level decision** with no existing register home. A8 registered exactly
      **5** (`OQ-80`…`OQ-84`).
   5. A8 **closed 0** entries. A commercial/product requirement does **not** close an
      implementation question (§24.3.0 rule 6(b)).
   6. Every register total in §24.3.7 and §25.5 was **recomputed by direct row
      count** after the A8 changes.

Severity scale: `CRITICAL` / `HIGH` / `MEDIUM` / `LOW`.
Classification values: `MUST RESOLVE BEFORE FREEZE` / `REGISTER BEFORE FREEZE` /
`BUSINESS CENTER` / `IMPLEMENTATION ARCHITECTURE` / `DEFERRED` /
`LEGAL/POLICY REVIEW`.
Owner values: `Owner` (commercial decision) / `Architect` (design proposal within
Document Owner authority) / `Future Architecture` / `Legal Review` /
`Owner + Architect`.

#### 24.3.1 OPEN — CRITICAL

**None.** A2 registered **three** `CRITICAL` entries — `OQ-25` (subscription term
anchor), `OQ-26` (category eligibility), and `OQ-27` (claiming). All three are
**CLOSED**: `OQ-25` by A3-1 (§26.1), `OQ-26` by A4-8 (§27.1), and `OQ-27` by
A4-9 (§27.2). This is a fact about the register, **not** a freeze declaration
(§1.6 items 3 and 8).

#### 24.3.2 OPEN — HIGH

| ID | Title | Status | Severity | Owner | Classification | Dependency / affected section | Decision needed |
|---|---|---|---|---|---|---|---|
| OQ-40 | Records retention, access, and deletion | `OPEN` | HIGH | Legal Review | LEGAL/POLICY REVIEW | §7.2.6, §9.2, §20.1, §28.8 | **Narrowed by A5-17** (§28.8), which decided the privacy boundary: receipts, verification evidence, staff notes, and sensitive ownership/payment information are private and never public; the Business Owner sees customer-facing transaction/status information but not internal antifraud/staff notes. Remaining: exact statutory retention/deletion periods, which A5 forbids inventing and routes to qualified Iraqi legal/accounting review. **Reclassified from `MUST RESOLVE BEFORE FREEZE` by A3–A5.** |

#### 24.3.3 OPEN — MEDIUM

| ID | Title | Status | Severity | Owner | Classification | Dependency / affected section | Decision needed |
|---|---|---|---|---|---|---|---|
| OQ-01 | Founding Partner price, 1-month and 3-month first terms | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §5.7 | The Founding Partner price for a 1-month or 3-month first term. Unaffected by A3–A5. |
| OQ-02 | "First 50" Founding Partner counter | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §5.7 | How the counter is defined, incremented, and evidenced; and the execution detail for businesses #51+. Unaffected by A3–A5 (A3-3 only confirms there is no automatic later cohort). |
| OQ-03 | Extra Branch 3-month price, maximum branch cap | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §4.2 | Whether a 3-month extra-branch price exists; the maximum branch count per entity and behaviour past the cap. Unaffected by A3–A5. |
| OQ-08 | Invoicing, fiscal/tax treatment, accounting export | `OPEN` | MEDIUM | Legal Review | LEGAL/POLICY REVIEW | §7.5, §29, §30 | Invoicing, receipts, tax/fiscal treatment, and accounting export. **Reclassified by A3–A5:** A5 explicitly forbids inventing VAT, invoice, tax, statutory retention, or consumer-law requirements and routes them to qualified Iraqi accounting/legal review. |
| OQ-09 | Approved payment destinations, rails, and settlement accounts | `OPEN` | MEDIUM | Owner | LEGAL/POLICY REVIEW | §7.5, §28.1, §29, D-22 | **Narrowed by A5-10** (§28.1): the canonical Commercial V1 pricing and accounting currency is `LOCKED` as **IQD**, payment must use Civilpedia-approved payment destinations/rails, and future electronic-payment integration must use appropriately authorized/regulated providers. Remaining: which specific bank accounts / transfer rails / settlement accounts Civilpedia approves, and the Central Bank of Iraq electronic-payment compliance route. **Reclassified from `MUST RESOLVE BEFORE FREEZE` by A3–A5.** |
| OQ-10 | Payment anti-fraud control mechanisms | `OPEN` | MEDIUM | Future Architecture | IMPLEMENTATION ARCHITECTURE | §7.5, §28.1 | **Narrowed by A5-10** (§28.1), which decided the customer and staff **outcomes** for short payment, overpayment, duplicate claim of one transfer, third-party payer, wrong destination, and suspected fraud. Remaining: the concrete detection/prevention/control mechanisms. Customer-outcome rules are closed with `OQ-31`. **Reclassified by A3–A5.** |
| OQ-12 | Management access during Grace Period | `OPEN` | MEDIUM | Owner + Architect | BUSINESS CENTER | §8.1, §8.3.6–§8.3.8, §26.2 | **Narrowed by A3-2** (§26.2), which decided the Grace duration exactly (**5 calendar days**), that Grace occurs **after** paid term expiry, that the public profile remains visible during Grace, and the reactivation rule after hiding. Remaining: whether management access continues during Grace (read/write), in which mode, and what the Business Owner sees. **Reclassified from `MUST RESOLVE BEFORE FREEZE` by A3–A5.** |
| OQ-13 | Verification evidence checklists, turnaround, appeals | `OPEN` | MEDIUM | Owner | DEFERRED | §9.2, §9.3, §28.4 | **Narrowed by A5-13** (§28.4), which decided the meaning of Verified, the no-automatic-12-month-expiry rule, the re-verification triggers, the "reasonable necessity" evidence constraint, the review service targets, and that no self-verification exists. Remaining: the verification policy document, per-category evidence checklists, and the detailed appeals procedure. |
| OQ-14 | Badge wording, placement, and Arabic copy | `OPEN` | MEDIUM | Owner + Architect | REGISTER BEFORE FREEZE | §5.6, §9.3, §14.4, §14.5, §28.14 | **Narrowed by A5-13** (§28.4) and §28.14: the customer-facing language is Arabic, and the preferred public wording concept for Verified is recorded ("تم التحقق من معلومات النشاط بواسطة Civilpedia") with its meaning and non-guarantees. Remaining: final Arabic copy, exact placement, and where the Founding Partner and Sponsored labeling appears. |
| OQ-15 | `CP-BIZ` / `CP-PAY` generation and visibility | `OPEN` | MEDIUM | Architect | IMPLEMENTATION ARCHITECTURE | §7.4 | Exact reference format, sequence source, uniqueness scope, and display surface. Unaffected by A3–A5 (A5-17 confirms these are never public). |
| OQ-16 | Media storage and per-category media limits | `OPEN` | MEDIUM | Architect | IMPLEMENTATION ARCHITECTURE | §16, §16.1, §28.6 | Storage limits, file size/type limits, external hosting, and per-category module media limits. **Narrowed by A5-15** (§28.6), which requires appropriate identity/cover/logo media at the publication gate but fixes no count. |
| OQ-17 | Analytics retention, counting rules, export, post-expiry visibility | `OPEN` | MEDIUM | Architect | REGISTER BEFORE FREEZE | §8.3.10, §17.2, §17.3, §28.7, **§32.3.6** | **Narrowed by A5-16** (§28.7), which fixed metric naming and the honesty rule only. **Further narrowed by A8-3** (§32.3 → L-90), which decided that before Launch Partner promotional expiry Civilpedia should **where available** show the Business its factual interaction metrics (Profile Views, WhatsApp Clicks, Call Clicks, Directions Clicks, other approved metrics), and that these are **interaction metrics only — never guaranteed leads and never confirmed sales**. Remaining: retention window, aggregation and reset, unique vs total counting, bot filtering, self-view exclusion, export, whether an Expired business retains analytics history, and the specific counting/retention treatment of the Launch Partner **pre-expiry** reporting window and **post-expiry** history. Reporting UX/analytics storage → P-36, D-25, `OQ-77`. |
| OQ-19 | Branch as a separately owned legal entity; independent branch transfer | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §2.4, §11.3, §26.5 | **Narrowed by A3-5** (§26.5), which decides only that affected branches are closed appropriately on confirmed permanent closure of the Business Entity. Remaining: whether a Branch may ever be a separately owned legal entity, and whether a Branch's ownership may transfer independently of the parent. |
| OQ-22 | Launch disposition of existing and seed listings | `OPEN` | MEDIUM | Future Architecture | IMPLEMENTATION ARCHITECTURE | §2.5, §26.2, C-9 | **Narrowed by A4-9** (§27.2), which excludes **grandfathering**: mock/dev/test/seed entities do not become entitled production commercial listings merely because they exist in data, and production publication requires the canonical onboarding/payment/publication rules. Remaining: the convert-or-remove disposition action for specific existing non-production rows at launch. **Reclassified from `MUST RESOLVE BEFORE FREEZE` by A3–A5.** |
| OQ-23 | Plan code values, price storage, currency representation | `OPEN` | MEDIUM | Future Architecture | IMPLEMENTATION ARCHITECTURE | §3.5, §28.1, C-2 | Plan catalog code values and price storage / currency representation. **Narrowed by A5-10** (§28.1), which fixes the commercial accounting currency as IQD. |
| OQ-24 | Managed service acceptance and pricing | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §12.7, §12.8 | Which managed-service requests are accepted at all, and whether managed service is ever separately priced, bundled, or recorded in Business Center. Unaffected by A3–A5. |
| OQ-42 | Discounts beyond Founding Partner, and discount stacking | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §3.3, §3.4, §26.3, §28.13, **§5.1a, §32.2.4** | **Narrowed by A3-3** (§26.3) and A5-22 (§28.13): promotions/contracts may define their own explicit terms, pricing experiments must be explicit, time-bounded, documented offers, and official base price changes follow the price-change rule. **Further narrowed by A8-2** (§32.2.4 → L-89), which decided the Launch Partner / Founding Partner interaction: the two programmes are **distinct and must not be merged**, a Business eligible under both receives the **temporary Launch Partner promotional Pro access first** and, later, the eligible **Founding Partner first-year paid price** — the Launch Partner 0 IQD period is therefore **not** a discount that stacks with, replaces, or defers Founding Partner pricing, and it consumes no Founding Partner cohort place. Remaining: whether multi-year, early-payment, or volume discounts exist, and whether any **other** discount stacks with the Founding Partner price. |
| OQ-44 | Brand-concept governance | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §2.2, §2.3, §13.3, §15.2, P-26, §28.5 | **Narrowed by A5-14** (§28.5), which closed the evidence question: authorised-dealer / agent / exclusive-distributor / official-affiliation claims require appropriate evidence and unsupported official affiliation claims are prohibited. Remaining: which authority governs the **Brand concept** — who may create, validate, or curate a Brand entry and how it is administered (data-level modelling is already `PROVISIONAL`, P-26). |
| OQ-48 | Falling below the publication minimum after publication | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §19, §28.6 | **Narrowed by A5-15** (§28.6), which decided the **pre-publication** case: an incomplete profile remains Draft / not publishable until the Required Fields Gate is met. Remaining: the consequence of falling below the gate **after** publication (warning, demotion, grace, or suspension) and who decides. |
| OQ-49 | Who may approve publication | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §19, §13.3, §28.6 | Staff-only approval versus automated validation plus audit, and the reviewer authority for the Required Fields Gate. Unaffected by A3–A5. |
| OQ-51 | Rejected / expired lead handling and re-application | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §10.1, §27.2 | Re-application eligibility, cooldown, and any fee. **Narrowed by A4-9** (§27.2), which fixes the Commercial V1 onboarding path as Civilpedia-controlled rather than open-claim based. |
| OQ-52 | Reviewer roles, rejection messaging, change history | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §13.3, §28.4 | **Narrowed by A5-13** (§28.4), which set the service targets (sensitive-content review ≈ 2 business days; verification/appeal up to 5 business days where practicable) as internal expectations, not guarantees. Remaining: reviewer roles, rejection messaging (Arabic-first, D-27), and business-visible audit/rollback expectations. |
| OQ-54 | Branch lifecycle | `OPEN` | MEDIUM | Owner | BUSINESS CENTER | §4.2, §13.1, §18.3, §26.5 | **Narrowed by A3-5** (§26.5), which decides only that affected branches are closed appropriately on confirmed permanent closure. Remaining: branch activation and deactivation, branch relocation, and the effect of relocation on verification. |
| OQ-55 | Privacy / consent for viewer-side measurement | `OPEN` | MEDIUM | Owner + Architect | IMPLEMENTATION ARCHITECTURE | §17.3 | Consent basis and data handling for viewer-side analytics measurement. Unaffected by A3–A5. |
| OQ-56 | Verification granularity for multi-branch entities | `OPEN` | MEDIUM | Owner | DEFERRED | §9.2, §9.3, §28.4 | **Reclassified by A3–A5** to `DEFERRED`: per-Business-Entity vs per-Branch verification belongs to the deferred verification policy document (`OQ-13`). A5-13 supplied "relevant location evidence" and location-change re-verification triggers but did not decide the granularity. |
| OQ-57 | Content-rejection appeal, abuse reporting, repeat offenders | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §13.3, §16, §26.4, §28.5 | **Narrowed by A3-4** (§26.4), which provides one appeal within 7 days for **termination** only, and by A5-14 (§28.5), which routes prohibited claims to takedown/enforcement. Remaining: the appeal route for a **content** rejection (distinct from verification appeals `OQ-13` and the termination appeal), public abuse reporting against a business, and repeat-offender policy. |
| OQ-59 | Branch manager personal data | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §11.3, §14.5, §28.8 | **Narrowed by A3–A5**: the non-Active-entity ownership-transfer part moved to `OQ-71`. Remaining: whether a branch manager's personal contact details may be published on a branch page; legal/policy review is required before the rule is published. |

#### 24.3.4 OPEN — LOW

| ID | Title | Status | Severity | Owner | Classification | Dependency / affected section | Decision needed |
|---|---|---|---|---|---|---|---|
| OQ-64 | Extra Branch price variation by area or branch type | `OPEN` | LOW | Owner | REGISTER BEFORE FREEZE | §4.2 | Whether extra-branch pricing differs by city/area or branch type. Unaffected by A3–A5. |
| OQ-65 | Extra Branch annual transferability / reset | `OPEN` | LOW | Owner | REGISTER BEFORE FREEZE | §4.2 | Whether extra branches are transferable or resettable annually. Unaffected by A3–A5. |
| OQ-67 | Branch-level deduplication and cannibalisation in results | `OPEN` | LOW | Architect | IMPLEMENTATION ARCHITECTURE | §18.3 | How multiple branches of one entity are represented in results without crowding out other businesses. Unaffected by A3–A5. |
| OQ-68 | Public experience of an inactive listing on direct link | `OPEN` | LOW | Architect | IMPLEMENTATION ARCHITECTURE | §8.3.3, §14.5, §26.5 | **Narrowed by A3-5** (§26.5), which locked the principle: a direct historic link must communicate that the business is **no longer active** and must not present misleading active business information. Remaining: the exact presentation (replaced content vs marked content) and the screen behaviour. |
| OQ-69 | Governing language of the commercial agreement | `OPEN` | LOW | Legal Review | LEGAL/POLICY REVIEW | §1.6, §28.14, D-27, D-31, §30 | **Narrowed by §28.14**: Arabic is the controlling **customer-facing** language for Commercial V1 unless future legal review requires a different governing-language provision. Remaining: the governing-language clause of the future commercial agreement, which is a legal-review question. |
| OQ-70 | SSOT custodian and next-review date | `OPEN` | LOW | Owner | REGISTER BEFORE FREEZE | §1.6 | The named document custodian and a review cadence. Documentary only. Unaffected by A3–A5. |

#### 24.3.5 New entries registered by A3–A8 (residual rule §24.3.0 item 8)

| ID | Title | Status | Severity | Owner | Classification | Dependency / affected section | Decision needed |
|---|---|---|---|---|---|---|---|
| OQ-71 | Ownership transfer while the Business Entity is not Active | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §11.3, §26.4, §26.7 | A3-4 (§26.4) and A3-7 (§26.7) decided suspension, termination, closure, and the verified-transfer rules, but not whether an ownership transfer may be initiated or completed while the entity is Expired, Suspended, Terminated, or Permanently Closed, nor what happens to a paid term in that case. |
| OQ-72 | Duplicate-entity detection basis and merge/retirement mechanics | `OPEN` | MEDIUM | Future Architecture | IMPLEMENTATION ARCHITECTURE | §2.4, §10.1, §26.6, **§32.2.3.2** | A3-6 (§26.6) locked the commercial principle (one real operating Business Entity must not hold duplicate commercial profiles; verified duplicates may be merged/retired under Civilpedia control; deliberate duplication may trigger enforcement). The detection basis and the merge/retirement mechanics are implementation. **Extended by A8-2** (§32.2.3.2 → L-89): duplicate entities/accounts may not be used to obtain repeated Launch Partner promotional trials, so duplicate detection must also be able to establish "once per genuine Business Entity" for promotional entitlement purposes. Still `OPEN`; A8 recorded the **use**, not the **mechanism**. |
| OQ-73 | Sponsored oversubscription, rotation, and fairness mechanics | `OPEN` | LOW | Architect | IMPLEMENTATION ARCHITECTURE | §6.3, §28.3 | A5-12 (§28.3) locked finite Category × Area inventory, no overselling of unavailable slots, and waitlisting as the preferred response. The rotation, queue, and fairness mechanics, and the final cap/Area definition, remain provisional for launch tuning (P-06). |
| OQ-74 | Verification as an organic ranking input | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §9.3, §14.5, §18.2, §18.3, §28.4 | A5-13 (§28.4) fixed what Verified means and expressly does not guarantee, but did not decide whether a Verified state may act at all as an organic ranking input. It must never become a purchasable or paid-adjacent signal (L-19, L-42). |
| OQ-75 | Media rights declaration, takedown, and repeat infringement | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §13.3, §16, §28.5 | A5-14 (§28.5) closed the prohibited-claims policy, which does not decide uploaded-media rights: what declaration a Business Owner gives for uploaded media, the takedown path, and repeat-infringement handling. Legal/policy review is required before the rule is published. |
| OQ-76 | Per-category required-fields matrix and gate UX | `OPEN` | MEDIUM | Architect | BUSINESS CENTER | §19, §19.1, §28.6 | A5-15 (§28.6) decided that publication uses a Required Fields Gate with a minimum content set and no arbitrary public numerical score. The exact per-category field matrix, the gate validation mechanics, and the Business Center UX remain design work. |
| OQ-77 | Business Center commercial-surface design contract | `OPEN` | MEDIUM | Architect | BUSINESS CENTER | §20, §20.1, §28.10, D-21 | A5-19 (§28.10) enumerated the expected Business Center commercial capabilities. The exact UX, routes, schema, and RBAC contract that must be produced before those capabilities can be frozen remains a Business Center design and architecture task. |
| OQ-78 | Disposition of non-owner memberships when Business ownership transfers | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §11.3, §26.7, P-08 | **Registered by A6 (2026-09-29) as a documentary correction**, not a commercial decision. A3-7 (§26.7) and L-63 lock the requirement for a verified, formal ownership-transfer workflow and the entity-continuity test, but they do not decide the disposition of the other (non-owner) memberships that existed under the prior owner — for example whether they are revoked, suspended, retained, or must re-accept under the new owner. A6 does **not** decide this matter. It is deliberately kept **separate from `OQ-20`**, which concerns the number of owners, co-ownership, and the state of an entity without an owner. **Historical, as-of-A6 wording:** that entry then "remained `OPEN` and freeze-blocking"; **A7-2 has since `CLOSED` `OQ-20`** — see the current A7 status below. `OQ-78` is **non-blocking**: it does not gate the §1.6 item 8 re-audit or any freeze decision, and it is not an `IMPLEMENTATION ARCHITECTURE` item. **A7 status: still `OPEN`.** A7-2 closed `OQ-20` (ownership cardinality) and did **not** decide or close this entry. **Post-audit documentary correction (pre-freeze cleanup, no commercial decision):** the A6-era "remains `OPEN` and freeze-blocking" clause above is **historical and does not describe the current register state**; `OQ-20` is `CLOSED` (§24.3.6, A7-2), and `OQ-78` itself remains `OPEN`, `MEDIUM`, Owner, `REGISTER BEFORE FREEZE`, and non-freeze-blocking. **This correction changes no status, severity, owner, classification, dependency, or decision meaning, and does not close, narrow, or reclassify `OQ-78`.** |
| OQ-79 | Ownership-dispute, deceased-owner, and quorum/legal-document evidence requirements | `OPEN` | MEDIUM | Owner | LEGAL/POLICY REVIEW | §11.3, §26.7, §31.2, §30 | **Registered by A7 (2026-09-29)** to satisfy §1.3 rule 6 for the ownership-policy deferral recorded in §31.2.12. A7-2 decided **ownership cardinality** (exactly one Primary Business Owner, optional verified Co-Owners, and the conceptual OWNERSHIP RECOVERY PENDING state) but explicitly deferred the **evidence and legal-document requirements** that a future ownership policy must define: ownership disputes, deceased-owner evidence, and quorum/legal-document evidence. A7 does **not** decide any of these and did not invent an answer. Any such rule will require qualified Iraqi legal review (§29.4, §29.5, D-19) and must be recorded as a further explicit Owner commercial decision. **Non-freeze-blocking**: this is a `LEGAL/POLICY REVIEW` item, not a `MUST RESOLVE BEFORE FREEZE` item, and it does not gate the §1.6 item 8 independent Freeze Readiness Audit. **A8 status: still `OPEN`.** A8-6/A8-7 reaffirm A7 ownership rules and change nothing here. |
| OQ-80 | Launch Partner cohort administration and status lifecycle | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §32.2.1.5, §32.2.2.8, §32.2.3.8, §10.1 | **Registered by A8 (2026-09-30).** A8-2 (§32.2 → L-89) locked the commercial policy: an invitation-only, Civilpedia-selected cohort of approximately **20–30** commercial Businesses; quality and category diversity over raw count; Business Pro at **0 IQD** for **60 calendar days**; start anchor = the **later** of formal commercial launch or first successful public publication; no card; no automatic renewal or charge. What A8 deliberately did **not** decide is the **administration** of that cohort: the selection criteria and selection authority's operating procedure; how the ~20–30 cohort cap is tracked and what happens when it is exhausted; whether Launch Partner status may be withdrawn or revoked; the effect of withdrawal/revocation on **remaining promotional days**; and re-invitation rules. These are genuine **Owner-level** commercial decisions with no existing register home (`OQ-02` concerns the Founding Partner counter, not Launch Partner). Entitlement/persistence mechanics → D-33, P-30. **Non-freeze-blocking** (`REGISTER BEFORE FREEZE`). |
| OQ-81 | Launch Partner promotional-continuity: the "normally once per Business Entity" qualifier, and what happens on ownership or entity change mid-promotion | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §32.2.3.1, §32.2.3.7 | **Registered by A8 (2026-09-30).** A8-2 (§32.2.3.1 → L-89) locks that the promotional period is "**normally** available once per genuine Business Entity" and §32.2.3.2 prohibits duplicate entities/accounts to obtain repeated launch trials. A8 did **not** decide (a) whether any exception to the "normally" qualifier exists and on what basis, or (b) whether **remaining promotional days survive** a verified ownership transfer of the same genuine Business Entity, or what happens where the same real business is later represented by a **materially new** Business Entity (`L-63` new-entity assessment). `OQ-71` concerns transfer while the entity is **not Active** and `OQ-19` concerns branch-level legal-entity separateness; neither answers this. Duplicate-abuse **detection mechanics** → `OQ-72`. **Non-freeze-blocking** (`REGISTER BEFORE FREEZE`). |
| OQ-82 | Retention, disposition, and re-attachment of a Civilpedia-managed Business Draft that never receives an accepted owner | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §32.5.7, §10.1 | **Registered by A8 (2026-09-30).** A8-5 (§32.5 → L-92) locked that Civilpedia staff may create a Business Draft before an owner is attached, that such a record is `CIVILPEDIA-MANAGED / OWNER NOT YET ATTACHED`, that the Draft is **not** ownership evidence, and that publication still requires entitlement + Minimum Profile Quality + ownership/onboarding + moderation. A8 did **not** decide what happens to such a Draft **if no owner is ever attached**: whether it may ever be visible publicly (it must not be publishable), how long it is retained, whether and when it is purged, whether Civilpedia may attach a **different** business to it later, and whether a prospective customer may withdraw consent for a Draft built from their supplied information. Related but distinct: `OQ-22` (seed/mock row disposition at launch) and D-17 (open claiming). **Non-freeze-blocking** (`REGISTER BEFORE FREEZE`). |
| OQ-83 | Ownership-invitation lifecycle: expiry, re-invitation, decline, and alternate invitee | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §32.6.7, §10.1, §11.3 | **Registered by A8 (2026-09-30)**, and simultaneously repairs a pre-A8 documentary defect: the §10.1 row "Exact UI, invitation mechanics, and acceptance screens for ownership transfer-in during onboarding" was an unresolved in-body marker that cited **no** registered `OQ-nn`, which was a defect under §1.3 rule 6(a). A8-6 (§32.6 → L-93) decided the **method** — invitation and acceptance is the preferred and default ownership-assignment method, with no Civilpedia-created password, no credential handover, one account per natural person, and no silent ownership grant before acceptance. A8 did **not** decide the invitation **lifecycle**: expiry/timeout, whether a lapsed invitation may be re-issued and how often, decline handling and messaging (Arabic-first, D-27), and whether an invitation may be redirected to a different person. Implementation (transport, persistence, deep links, screens) → `OQ-77`, P-25, D-28. **Non-freeze-blocking** (`REGISTER BEFORE FREEZE`). |
| OQ-84 | Post-promotion treatment of a category that reached the Category Launch Gate partly through Commercial-Active Launch Partners | `OPEN` | MEDIUM | Owner | REGISTER BEFORE FREEZE | §32.11.6, §31.3.14–§31.3.16, §2.5 | **Registered by A8 (2026-09-30).** A8-11 (§32.11 → L-97) decided that during the initial Launch Partner phase an authorized Launch Partner holding a valid Business Entity, an active promotional commercial entitlement, and a publicly publishable profile **MAY** count toward launch-category supply density as a **COMMERCIAL-ACTIVE BUSINESS** — and that this is **not** a free listing and does not weaken the Paid-Only rule, the 5-Business gate, the ~8–10 growth target, or the ~30 formal launch target. A8 did **not** decide what happens **after** the promotional period ends to a category that was launched on a count that included Commercial-Active Launch Partners: whether such a category must be re-gated once those businesses are no longer commercially active, whether it reverts to the "Coming Soon / قريباً" state, or whether it simply falls under the normal launch-gate-not-shutdown-threshold rule (`L-87`, §31.3.8). Distinct from `OQ-48` (falling below the **publication** gate after publication) and `OQ-68` (empty-state UX). **Non-freeze-blocking** (`REGISTER BEFORE FREEZE`). |

#### 24.3.6 CLOSED by A3–A8 (trace required — never deleted)

Every entry below was `OPEN` after Amendment A2 and is now answered by an
explicit Owner commercial decision recorded in this document. The original
question is preserved. **Closing an entry does not authorize any implementation.**
**Amendment A8 closed 0 entries and added no rows to this table.**

| ID | Original question | Closed by | Owner decision recorded in |
|---|---|---|---|
| OQ-05 | Does renewal pricing differ from first purchase? | A3-3 | §26.3 — renewal takes the official price effective on the renewal date; promotions/contracts may define their own explicit terms; the Founding Partner first-year discount is not a lifetime price. |
| OQ-06 | Upgrade/downgrade mid-term, proration, and downgrade when branch count exceeds the new tier? | A5-11 | §28.2 — upgrade may take effect immediately for the prorated difference using a simple auditable Civilpedia method (exact formula = P-34, a future architecture/finance design); downgrade normally at next renewal with no retroactive removal of paid term value. Branch counts above a tier's included count are governed by the existing Extra Branch add-on model (§4.2). |
| OQ-07 | Refund, cancellation, partial-refund, and no-show policy. | A5-11 | §28.2 — voluntary cancellation takes effect at the end of the paid period; refund/credit is appropriate for duplicate payment, verified overpayment, material Civilpedia failure, and other mandatory legal/customer rights. |
| OQ-11 | Which staff roles may confirm payment and which may activate a subscription? | A5-10 | §28.1 — only explicitly authorized Civilpedia finance/admin authority may mark a payment Verified, refunded, or credited; sales request creation may be separated from final verification at scale. |
| OQ-18 | Is 2–3 per Category × Area a hard cap, soft target, or queue; what is "Area"; and oversubscription, rotation, fairness policy? | A5-12 | §28.3 — finite inventory, no overselling, waitlisting preferred. Cap and Area mechanics remain `PROVISIONAL` (P-06); rotation/queue/fairness mechanics are registered as `OQ-73`. |
| OQ-21 | Is a User Account mandatory before publication? | A4-9 | §27.2 — the owner creates their own account and accepts Business ownership before Content review and Published, per the already-`LOCKED` §10.1 sequence. A consequence of the existing sequence, not a new decision. |
| OQ-25 | When does the paid term start, when does it end, and what is the renewal date? | A3-1 | §26.1 — payment verification and subscription start are distinct; the paid term normally starts on the first successful public publication; 14-day customer activation window with a day-15 start where the customer alone caused the block; end = start + purchased duration. |
| OQ-26 | Which categories may hold a paid Business listing, which are withheld, and what users see in withheld categories? | A4-8 | §27.1 — commercial organisations only; individual professionals excluded; engineering/consulting/laboratory organisations withheld pending the §23 research. |
| OQ-27 | Does claiming exist in Commercial V1? | A4-9 | §27.2 — no open public "Claim this business" workflow; Civilpedia creates the Business Draft through controlled onboarding and links/invites the verified owner; open/competing claims deferred until a dedicated evidence/dispute model exists. |
| OQ-28 | Price-change effective moment, effect on a paid unexpired term and next renewal, and notice period/channel. | A3-3 | §26.3 — a price change never changes an already-paid unexpired term; no retroactive increase or price-difference collection; the new official price applies at future renewal; decreases also apply at future renewal; minimum 30-day notice target. |
| OQ-29 | Manual renewal, auto-charge, stored instruments, early renewal, and notice cadence/channel/language. | A3-2 | §26.2 — manual renewal only; no automatic charge; no stored payment instrument; every renewal independently verified; early renewal extends from the existing paid end date; Grace = 5 calendar days; cadence and channels recorded; Arabic customer-facing language (§28.14). |
| OQ-30 | Suspension/termination authority, visibility, term clock, money outcome, appeal, re-entry, and transfer while non-Active. | A3-4 | §26.4 — correction window 7 days for non-serious violations; immediate suspension for serious violations; visibility/access/Sponsored/data effects; customer-caused suspension does not pause the clock; termination grounds, effects, and one appeal within 7 days. The transfer-while-not-Active remainder is registered as `OQ-71`. |
| OQ-31 | Customer and staff outcome for payment exceptions. | A5-10 | §28.1 — underpayment, overpayment, unclear receipt, duplicate transfer, third-party payer, incorrect/unapproved destination, payment after Grace expiry, payment for a closed/suspended/invalid Business, and suspected fraud all have recorded outcomes. |
| OQ-32 | Duplicate/overlapping Business Entity detection, merge authority, and consequence. | A3-6 | §26.6 — no duplicate commercial profiles for one real operating Business Entity; verified duplicates may be merged/retired under Civilpedia control; deliberate duplication to manipulate visibility, promotions, Sponsored inventory, or commercial rules may trigger enforcement. Detection/merge mechanics are registered as `OQ-72`. |
| OQ-33 | Sponsored campaign states, renewal, cancellation notice, refund, and mid-campaign unavailability. | A5-12 | §28.3 — Scheduled / Active / Ended / Cancelled-Withdrawn; paid time begins when the placement actually becomes available/public; Civilpedia-caused non-delivery restores equivalent time or credit/refund; customer-caused suppression does not automatically pause Sponsored time. |
| OQ-34 | Minimum Sponsored eligibility (including whether Verified is required) and prohibited advertisers/content. | A5-12 | §28.3 — Verified is not required; eligibility is plan + publishability + profile quality + advertising content related to the actual Business; prohibited content enumerated. |
| OQ-35 | Verification validity, re-verification, renewal, false documents, and what the badge asserts. | A5-13 | §28.4 — no automatic fixed 12-month expiry; re-verification triggers enumerated; renewal alone is not re-verification; badge meaning and non-guarantees recorded; false/forged evidence may cause immediate suspension, verification withdrawal, and enforcement. The ranking-input remainder is registered as `OQ-74`. |
| OQ-36 | Permanent closure as an event distinct from expiry. | A3-5 | §26.5 — Operating / Closure Requested / Permanently Closed; discovery removal, Sponsored stops, verification inactive, branch closure, retained private records, no automatic deletion, no automatic refund, direct links must not misrepresent an inactive business, and reopening rules. |
| OQ-38 | Definition and permitted commercial use of "Lead". | A5-16 | §28.7 — views/taps must not be called customers or sales; exact metric names are preferred; "Lead" only under an explicit measurement rule; no metric implies a completed sale. |
| OQ-39 | Does a paid subscription transfer to a new legal person when a business is sold? | A3-7 | §26.7 — the subscription belongs to the Business Entity; transfer never happens by credential sharing; remaining value may remain with the same genuine Business Entity after a verified legitimate transfer; a materially new entity requires new-entity assessment. |
| OQ-41 | Does Civilpedia adopt a policy-obligations register? | A5-18 | §30 — the register is adopted and enumerates the eleven policy areas the Owner requires Civilpedia to maintain. **No legal text is drafted**; every entry carries a deferred authority and qualified Iraqi legal/accounting review is required. |
| OQ-43 | Offer validity window, expired-offer behaviour, and price/accuracy responsibility. | A5-14 | §28.5 — every time-limited offer must carry validity/start-end information; expired offers cease public promotion; the business is responsible for commercial price/offer accuracy; Civilpedia may remove stale or deceptive content. |
| OQ-45 | Prohibited claim categories, media rights declaration, takedown, repeat offenders. | A5-14 | §28.5 — prohibited claims enumerated (fake certificates, false affiliations, deceptive discounts, fabricated achievements, impersonation, materially misleading content) and routed to takedown/enforcement. The media-rights remainder is registered as `OQ-75`. |
| OQ-46 | Team seat limits per plan and which capability levels may view payment/financial records. | A5-20 | §28.11 — operational default ceiling of 5 active team members for ordinary Business plans; Corporate custom; team count is not the primary pricing value proposition; financial/subscription information visible only to the Business Owner and explicitly finance-authorized roles; exact RBAC/storage mapping deferred (P-25, D-28). |
| OQ-47 | The quantitative Minimum Profile Quality standard and its validation mechanism. | A5-15 | §28.6 — publication uses a **Required Fields Gate**, not an arbitrary public numerical quality score, with a minimum content set; an incomplete profile remains Draft/not publishable. The per-category matrix is registered as `OQ-76`. |
| OQ-50 | Who may verify, and whether verification is staff-only. | A5-13 | §28.4 — only authorized Civilpedia staff/authority may grant or withdraw Verified; there is no self-verification. |
| OQ-53 | May a Sponsored placement be bought per branch rather than per entity? | A5-12 | §28.3 — a separate branch-level Sponsored product is `DEFERRED` for V1; the initial Sponsored product attaches to the Business Entity. |
| OQ-58 | Are payment status, verification status, pending changes, support/contact, business switching, and evidence upload required Business Center modules? | A5-19 | §28.10 — the expected Business Center commercial capabilities are enumerated, including subscription status, renewal/expiry/Grace, payment status, verification status, support/contact, evidence upload, Team, business switching, profile/media/products/services/projects/offers/branches, analytics by entitlement, and subscription/renewal surfaces. The design contract is registered as `OQ-77`. |
| OQ-60 | Is any instalment or deferred payment structure permitted, and how long is a quotation valid? | A5-21 | §28.12 — Business, Business Pro, and Business Plus are prepaid with no deferred debt or instalment structure in ordinary V1; Corporate may use individually approved written terms; Corporate quotation default validity is 30 calendar days unless the quotation states otherwise. |
| OQ-61 | Which commercial KPIs are tracked, and are controlled pricing experiments permitted? | A5-22 | §28.13 — no silent personalization of prices to equivalent customers; experiments/promotions must be explicit, time-bounded, documented commercial offers; base price changes follow the price-change rule; commercially meaningful KPIs tracked without misrepresenting interaction metrics as sales. |
| OQ-62 | Payment verification turnaround | A5-10 | §28.1 — L-71 sets a target customer-facing verification within **one business day** after clear evidence/funds are available, aiming for same-day where operationally possible, explicitly as a service target and **not** a guaranteed bank settlement promise; the pending-payment customer wording is Arabic-first (§28.14). |
| OQ-63 | Does the "Owner" name stay shared by the business role and the document authority? | A3–A5 §26.0 | §26.0 — the terms are now **Business Owner** (capability role) and **Document Owner** (decision authority). L-64. |
| OQ-66 | Is Founding Partner pricing re-offered in a later cohort? | A3-3 | §26.3 — Founding Partner is the initial first-50 cohort; no later cohort is promised or implied, and any later cohort requires a new explicit Owner commercial decision (`DEFERRED`, D-18). |
| OQ-04 | Corporate contents, minimum term, quotation process. | **A7-1** | **§31.1 → L-84, L-85** — Corporate remains a quotation-based enterprise plan whose **minimum commercial floor is ALL Business Plus entitlements**; it may extend beyond Business Plus by written quotation; commercial variables include included branch count, additional branch scale, team-member capacity, support/service level, managed-service scope, media/content scale, analytics/reporting, and other permitted enterprise services; **minimum subscription commitment 12 months**; pricing is **Custom Quote** with **no** fixed public Corporate price; quotation **default validity 30 calendar days** (§28.12.3, L-82, preserved); every quotation must state the nine required items. A7-3 does not change §3.2 prices. A7 creates no entitlement/storage schema (P-03, P-25, `OQ-77`, D-29). |
| OQ-20 | Multiple, simultaneous, or absent Business Owners. | **A7-2** | **§31.2 → L-86** — exactly **ONE Primary Business Owner** during normal operation, plus optional verified **Co-Owners** subject to team limits; Primary Owner is the accountable authority for sensitive ownership operations; a Co-Owner does **not** automatically have equal authority; the entity must not remain indefinitely active with no Primary Owner; unavailability triggers the conceptual **OWNERSHIP RECOVERY PENDING** state, after which Civilpedia verifies a replacement and assigns it through the controlled ownership process (§26.7, L-63); data and subscription stay with the Business Entity; public visibility is not automatically removed solely because recovery is pending unless fraud/security/moderation risk requires it; shared passwords/account handover remain prohibited. Owner/Co-Owner remain commercial/capability concepts — exact RBAC/UX/state persistence deferred (P-25, D-28, `OQ-77`). Disputes, deceased-owner evidence, and quorum/legal-document evidence → `OQ-79`. **`OQ-78` and `OQ-71` are NOT closed by A7.** |
| OQ-37 | Launch density, sequencing, and empty-area experience. | **A7-3** | **§31.3 → L-87** — **BAGHDAD FIRST**; no broad launch of an obviously sparse paid-only directory; **Category Launch Gate of 5 active, paid, publicly publishable Businesses** in the applicable Baghdad market; growth **target** ~8–10 active paid Businesses per launched category; overall initial launch **target** ~30 active paid publishable Businesses; both are targets, not guarantees. Below-gate categories must not present a misleading normal experience (hidden from primary discovery, or a clear "Coming Soon / قريباً" state) and must **never** be padded with fake or free production listings. The 5-Business threshold is a **Launch Gate, not an automatic shutdown threshold** — a launched category is not auto-closed solely for falling below 5. A category at **zero** must show an honest empty/unavailable state, not stale or fake listings. Launch a focused initial category group; the exact list may be chosen operationally **without changing the 5-business gate**. Expansion outside Baghdad is **not automatic** and needs a later explicit decision. Founding Partner acquisition may help reach density but does **not** weaken Paid-Only (§2.1, §2.5, §27.2). Exact UX → `OQ-68`, `OQ-76`. **`OQ-48` and `OQ-68` are NOT closed by A7.** |

#### 24.3.7 Register totals (informational, after A3–A8)

All figures below were **recomputed by direct count of the rows** in
§24.3.1–§24.3.6, not estimated. The "After A2" column is the **A2 register as
recorded at its own baseline**; the "After A6" column is the accepted
post-A6 state; the "After A7" column is the post-A7 state; the **"After A8"**
column is the current state.

| Metric | After A2 | After A6 | After A7 | **After A8** |
|---|---|---|---|---|
| Registered Open Question IDs | 70 | **78** | **79** | **84** |
| `OPEN` | 70 | **45** | **43** | **48** |
| `CLOSED` (with trace, §24.3.6) | 0 | **33** | **36** | **36** |
| — `CRITICAL` (open) | 3 | **0** | **0** | **0** |
| — `HIGH` (open) | 21 | **3** | **1** | **1** |
| — `MEDIUM` (open) | 39 | **35** | **35** | **40** |
| — `LOW` (open) | 7 | **7** | **7** | **7** |
| `MUST RESOLVE BEFORE FREEZE` (open) | 28 | **3** | **0** | **0** |
| `REGISTER BEFORE FREEZE` (open) | 31 | **22** | **22** | **27** |
| `BUSINESS CENTER` (open) | 2 | **4** | **4** | **4** |
| `IMPLEMENTATION ARCHITECTURE` (open) | 6 | **10** | **10** | **10** |
| `DEFERRED` (open) | 2 | **2** | **2** | **2** |
| `LEGAL/POLICY REVIEW` (open) | 1 | **4** | **5** | **5** |
| New entries registered by A3–A5 | 0 | **7** | **7** | **7** |
| New entries registered by A6 (documentary) | 0 | **1** | **1** | **1** |
| New entries registered by A7 (legal/policy) | 0 | **0** | **1** | **1** |
| **New entries registered by A8** | 0 | **0** | **0** | **5** |
| Entries closed by A3–A5 | 0 | **33** | **33** | **33** |
| Entries closed by A6 | 0 | **0** | **0** | **0** |
| Entries closed by A7 | 0 | **0** | **3** | **3** |
| **Entries closed by A8** | 0 | **0** | **0** | **0** |
| **Entries narrowed by A8** | 0 | **0** | **0** | **3** |

**A8 arithmetic check (recomputed from the rows).** `OPEN` 48 + `CLOSED` 36 =
**84** registered. Severity: 0 `CRITICAL` + 1 `HIGH` + 40 `MEDIUM` + 7 `LOW` =
**48**. Classification: **0** `MUST RESOLVE BEFORE FREEZE` + 27 `REGISTER BEFORE
FREEZE` + 4 `BUSINESS CENTER` + 10 `IMPLEMENTATION ARCHITECTURE` + 2 `DEFERRED` +
5 `LEGAL/POLICY REVIEW` = **48**.

**A8 movement relative to A7 (exactly one kind of change).** A8 **closed 0**
entries and **registered 5** new non-blocking entries — `OQ-80`, `OQ-81`, `OQ-82`,
`OQ-83`, `OQ-84` (all `MEDIUM`, `Owner`, `REGISTER BEFORE FREEZE`) — and
**narrowed 3** existing open entries (`OQ-17`, `OQ-42`, `OQ-72`) without changing their
status, severity, owner, or classification. No entry changed classification. **`MUST
RESOLVE BEFORE FREEZE` remains 0.** The remaining single `HIGH` entry is `OQ-40`,
which is `LEGAL/POLICY REVIEW` and **not** a freeze blocker; severity and
classification are independent triage fields (§24.3.0 rule 4).

**Expected-vs-actual note (A8).** A8's tasking anticipated a cold-start expansion of
the register. A8 closed 0 entries by design (§1.3 rule 6(b) and §24.3.0 rule 6(b)
route implementation-architecture matters to §24.2, not §24.3). The **actual** count
is **84 total / 48 `OPEN` / 36 `CLOSED`**, because A8 narrowed three existing entries
rather than duplicating them, routed five implementation/design matters to `D-32`,
`D-33`, `P-35`, and `P-36` instead of `OQ-nn`, and registered exactly **5** genuine
residual Owner-level entries. The freeze-gate outcome (`MUST RESOLVE BEFORE FREEZE`
= 0) is unchanged.

**A7 arithmetic check (recomputed from the rows — preserved unchanged by A8).**
`OPEN` 43 + `CLOSED` 36 = **79** registered. Severity: 0 `CRITICAL` + 1 `HIGH` +
35 `MEDIUM` + 7 `LOW` = **43**. Classification: **0** `MUST RESOLVE BEFORE FREEZE`
+ 22 `REGISTER BEFORE FREEZE` + 4 `BUSINESS CENTER` + 10 `IMPLEMENTATION
ARCHITECTURE` + 2 `DEFERRED` + 5 `LEGAL/POLICY REVIEW` = **43**.

**Historical A7 movement relative to A6 (superseded by A8; preserved per §1.5
rule 3).** A7 **closed 3** entries — `OQ-04` and `OQ-37` (both `HIGH`, `MUST
RESOLVE BEFORE FREEZE`) and `OQ-20` (`MEDIUM`, `MUST RESOLVE BEFORE FREEZE`) — and
**registered 1** new non-blocking entry, `OQ-79` (`MEDIUM`, `LEGAL/POLICY REVIEW`).
No other entry changed status, severity, or classification. **`MUST RESOLVE BEFORE
FREEZE` became 0.** This statement describes the **post-A7** state and is
superseded by the **A8** figures in the tables above.

**Historical A7 expected-vs-actual note (superseded by A8; preserved per §1.5
rule 3).** A7's tasking anticipated 78 total / 42 `OPEN` / 36 `CLOSED`. The
**actual** post-A7 count was **79 total / 43 `OPEN` / 36 `CLOSED`**, because §1.3
rule 6 (mandatory) requires the ownership-evidence deferral recorded in §31.2.12 to
carry a registered `OQ-nn`; that entry is `OQ-79`. Per the A6 precedent, the
mandatory fix is to **register** the item, not to leave an unresolved marker uncited
and not to answer it. `OQ-79` is `LEGAL/POLICY REVIEW` and non-freeze-blocking, so
the freeze-gate outcome (`MUST RESOLVE BEFORE FREEZE` = 0) was unaffected.

Counts are informational. The tables in §24.3.1–§24.3.6 are the authority.

**Closure attribution (sums to 33).** A3 closed **9**; A4 closed **3**; A5 closed
**21** (including the jointly recorded terminology closure `OQ-63` via
L-64/§26.0). New entries: A3 registered **2** (`OQ-71`, `OQ-72`); A5 registered
**5** (`OQ-73`–`OQ-77`); **A6 registered `1`** (`OQ-78`, documentary and
non-blocking); **A7 registered `1`** (`OQ-79`, legal/policy, non-blocking). In
addition, **22** remaining open entries were **narrowed** and
**7** were **reclassified** to their correct authority. *This paragraph is the
A6-era attribution and is preserved unchanged as history; see the A7 and A8
attributions below for the current state.*

**Closure attribution (sums to 36).** A3 closed **9**; A4 closed **3**; A5 closed
**21** (including the jointly recorded terminology closure `OQ-63` via
L-64/§26.0); **A7 closed 3** (`OQ-04` by A7-1, `OQ-20` by A7-2, `OQ-37` by A7-3);
**A8 closed 0**. Current closed total = 9 + 3 + 21 + 3 + 0 = **36**.

**New-entry attribution (current state).** A3 **2** (`OQ-71`, `OQ-72`); A5 **5**
(`OQ-73`–`OQ-77`); A6 **1** (`OQ-78`, documentary, non-blocking); A7 **1**
(`OQ-79`, legal/policy, non-blocking); **A8 5** (`OQ-80`–`OQ-84`, all
`MEDIUM` / `Owner` / `REGISTER BEFORE FREEZE`, all **non-freeze-blocking**).
Total new entries = 2 + 5 + 1 + 1 + 5 = **14**; plus the 70 A2-baseline IDs =
**84** registered.

**Narrowing attribution (A8 = 3).**

| Narrowed by | Count | Entries |
|---|---|---|
| A8-3 (32.3  L-90) | **1** | `OQ-17` (analytics retention/counting extended to the Launch Partner pre-expiry reporting window and post-expiry history) |
| A8-2 (32.2.3.2, 32.2.4  L-89) | **2** | `OQ-42` (Launch Partner/Founding Partner interaction boundaries clarified), `OQ-72` (duplicate-entity detection extended to establish "once per genuine Business Entity" for promotional entitlement) |
| **Total** | **3** | |

Narrowing adds a dimension to an existing entry; it does **not** change any entry's
status, severity, owner, or classification (§24.3.0 rule 4).

**Reclassification attribution (sums to 7) — A6 documentary correction.** The seven
reclassified entries are now attributed to the amendment that actually decided the
substance, replacing the earlier blanket "A3–A5" label that did not name which
amendment carried each:

| Reclassified by | Count | Entries |
|---|---|---|
| A3 | **1** | `OQ-12` (Grace management access routed to Business Center design by A3-2) |
| A4 | **1** | `OQ-22` (seed-listing launch disposition routed to architecture by A4-9) |
| A5 | **5** | `OQ-08`, `OQ-09`, `OQ-10`, `OQ-40`, `OQ-56` |
| **Total** | **7** | |

The per-entry `**Reclassified by A3–A5**` markers on the `OQ-08` and `OQ-56` rows
are retained for traceability, with the specific amendment now supplied by this
table. Reclassification remains bookkeeping only (§24.3.0 rule 4); no severity,
status, or freeze-gate meaning changes.

**Correction to an earlier working note (recorded for audit).** An intermediate
draft of this amendment asserted that the A2 baseline for
`MUST RESOLVE BEFORE FREEZE` was **27** and that the A2 figure **28** was a
misprint. **That assertion was wrong and is withdrawn.** A direct row count of the
A2 register at its own baseline yields **28** `MUST RESOLVE BEFORE FREEZE` and
**31** `REGISTER BEFORE FREEZE` (3 + 21 + 2 + 6 + 1 + 31 = 70 total), which is
exactly the A2 total. **A2's original figures were correct; no A2 number was
altered.** The current "After A2" column reproduces the A2 baseline faithfully.

### 24.4 Change log (append-only)

| Date | Authority | Change | Previous | New | Implementation / sales impact |
|---|---|---|---|---|---|
| 2026-09-27 | Owner + ChatGPT Architect | Document created as Commercial Model V1 SSOT | none | Initial consolidation of §1–§25 | Documentation only. No production change. No sales change until separately communicated. |
| 2026-09-27 | ChatGPT Architect | **Amendment A1 — Conflict reconciliation (C-1…C-10)** | C-1…C-10 recorded as unresolved conflicts requiring Architect decisions | Added §1.2 commercial-policy vs implementation-authority rule; added §2.3, §2.5, §3.5, §5.8, §6.4, §8.2, §8.4, §11.1a, §11.4 reconciliation sections; restructured §8 into three separate conceptual workflows; rewrote §24.1 as a resolved conflict registry; updated §25 registry | **No commercial intent changed.** No production code, test, migration, Supabase, roadmap, or UI-contract change. No implementation authorized. |
| 2026-09-28 | ChatGPT Architect | **Amendment A2 — Register integrity + documentary corrections** | 24 plain-numbered open questions; 14 in-body unresolved markers with no registered entry and 4 more only partially covered; no severity/owner/classification fields; no statement of document maturity; §2.4 `LOCKED` wording ("never a separately **billed** … entity") contradicting the approved Extra Branch add-on model in §4.2; §3.3 pointed at §24.3 for an entitlement item that was never registered there | Rebuilt §24.3 as a single authoritative Open Question register with stable IDs `OQ-01`…`OQ-70`, per-entry status/severity/owner/classification/dependency/decision-needed fields (§24.3.1–§24.3.5, §24.3.6 totals); added the mandatory Open Question ID rule (§1.3 rule 6) and freeze rule (§1.3 rule 7); added §1.6 document maturity (**CANONICAL SSOT / ACTIVE DESIGN / NOT YET FROZEN**) with a freeze gate; added in-body `OQ-nn` citations to every unresolved marker and to registered gaps (§2.4, §2.5, §3.2, §3.3, §3.4, §4.2, §5.7, §6.1, §6.3, §7.2, §7.5, §8.1, §8.3, §9.3, §10.1, §11.1, §11.3, §12.7, §13.3, §14.4, §14.5, §16, §17.2, §17.3, §18.2, §18.3, §19, §20.1); corrected §2.4 branch wording to "not a separately owned and not a separately subscribed Business Entity … additional branches may carry approved Extra Branch add-on pricing under the parent Business subscription"; added dependency D-9 (identifier later renumbered to D-31 by Amendment A6; see the §24.2 A6 identifier mapping) and standing prohibitions 11–12; added **no** `L-nn` registry entry (A2 governance rules stay outside the commercial decision registry) and updated §25.5 counts | **Documentation / governance only. No commercial decision, no price change, and no commercial intent change.** **0 open questions answered; 0 new commercial rules created.** Wording correction in §2.4 preserves the approved intent (one Business Entity, one subscription, add-on pricing, no second full subscription for a branch). No production code, test, migration, Supabase, contract, UI, or roadmap change. No implementation authorized. No sales impact: no `PROVISIONAL` value became quotable. |
| 2026-09-29 | Owner + ChatGPT Architect | **Amendment A3 — Commercial Spine** | Subscription term, renewal mechanics, price-change consequences, suspension/termination, permanent closure, duplicates, and business-sale transfer were all `OPEN` (`OQ-25`, `OQ-29`, `OQ-28`, `OQ-30`, `OQ-36`, `OQ-32`, `OQ-39`, `OQ-05`, `OQ-66`) | Added **§26** (A3-1…A3-7) and registered **L-55…L-64**; added the **§26.0** terminology rule **Business Owner** vs **Document Owner** (L-64); added **D-18** and the new entries **OQ-71** / **OQ-72**; updated in-body rows in §1.6, §2.5, §3.2, §3.3, §5.7, §6.3, §7.2, §7.5, §8.1, §8.3, §10.1, §11.1, §11.3, §13.3, §14.5, §18.3, §24.2 | **Real Owner commercial decisions recorded. 9 open questions closed, 0 invented.** Grace is now exactly **5 calendar days** after paid term expiry, superseding the 3–7 day `PROVISIONAL` target in §8.3.7. **No** code, schema, migration, RLS, route, auth, backend, contract, phase, or roadmap change; **no** implementation authorized; document remains **NOT YET FROZEN**. |
| 2026-09-29 | Owner + ChatGPT Architect | **Amendment A4 — Eligibility + Claiming Boundary** | Category eligibility and the entire claiming question were `OPEN` (`OQ-26`, `OQ-27`); the user-account/publication and seed-listing questions were unresolved (`OQ-21`, `OQ-22`) | Added **§27** (A4-8, A4-9) and registered **L-65…L-67**; added rule **§2.1.9**; added **D-17**; added in-body A4-8 confirmations in §22.1, §22.2, §23; updated §2.5 and §10.1 | **Real Owner commercial decisions recorded. 3 open questions closed, 1 narrowed and reclassified, 0 invented.** **No** implementation authorized; the Professional Marketplace and Engineering Organisation models remain `DEFERRED`; the roadmap is unchanged; document remains **NOT YET FROZEN**. |
| 2026-09-29 | Owner + ChatGPT Architect | **Amendment A5 — Terms, Trust, Payments, Sponsored** | Payment exceptions, payment authority and turnaround, refunds, upgrade/downgrade, Sponsored lifecycle/eligibility/branch-level/inventory, verification validity and meaning, offer and claim policy, the publication threshold, "Lead" wording, records privacy, the policy-obligations register, Business Center module completeness, team seats, instalments/quotations, and commercial measurement were `OPEN`. **Closed by A5 (21):** `OQ-06`, `OQ-07`, `OQ-11`, `OQ-18`, `OQ-31`, `OQ-33`, `OQ-34`, `OQ-35`, `OQ-38`, `OQ-41`, `OQ-43`, `OQ-45`, `OQ-46`, `OQ-47`, `OQ-50`, `OQ-53`, `OQ-58`, `OQ-60`, `OQ-61`, `OQ-62`, `OQ-63`. **Narrowed by A5 (14):** `OQ-04`, `OQ-09`, `OQ-10`, `OQ-13`, `OQ-14`, `OQ-16`, `OQ-17`, `OQ-23`, `OQ-40`, `OQ-42`, `OQ-44`, `OQ-48`, `OQ-52`, `OQ-57`. **Reclassified by A5 (4):** `OQ-09`, `OQ-10`, `OQ-40`, `OQ-56` | Added **§28** (A5-10…A5-22), **§29** (Iraqi/regulatory caution), and **§30** (Legal/Policy Obligations Register); registered **L-68…L-83**, **P-34**, **D-15…D-19**, and **OQ-73…OQ-77**; added dependencies **D-20…D-22** and standing prohibitions **13–23**; added §14.3 rows and the §17.3 metric-naming rule; updated §6.1, §6.3, §7.2, §7.5, §8.2, §8.3, §9.2, §9.3, §13.3, §14.3, §14.5, §16, §17.1, §17.3, §18.2, §18.3, §19, §20.1, §24.2 | **Real Owner commercial decisions recorded. 21 open questions closed, 14 narrowed, 4 reclassified to the correct deferred authority, 5 new residual entries registered (`OQ-73`…`OQ-77`), 0 invented.** **No legal text was drafted**; qualified Iraqi legal/accounting review is recorded as required (§29, §30, D-10). **No** code, schema, migration, RLS, route, auth, backend, contract, phase, or roadmap change; **no** implementation authorized; document remains **NOT YET FROZEN**. |
| 2026-09-29 | ChatGPT Architect | **A3–A5 register and count reconciliation** | §24.3.6 reported `MUST RESOLVE BEFORE FREEZE` = 28, which did not match the A2 register rows | **Verified the A2 baseline rather than changing it** — a direct row count of the A2 register yields `MUST RESOLVE BEFORE FREEZE` = **28** and `REGISTER BEFORE FREEZE` = **31** (3 + 21 + 2 + 6 + 1 + 31 = 70), so **A2's figure was correct and no A2 number was altered**; an earlier working draft of this amendment that asserted the baseline was 27 is **withdrawn** (§24.3.7). Rebuilt the register into §24.3.1–§24.3.7 with explicit `OPEN` / `CLOSED` status, a close-trace table (§24.3.6), the residual-registration rule (§24.3.0 item 8), and recomputed totals: **77 registered, 44 open, 33 closed, 0 `CRITICAL`, 3 `HIGH`, 34 `MEDIUM`, 7 `LOW`, 3 `MUST RESOLVE BEFORE FREEZE`** | **Count and register-integrity reconciliation only. No commercial decision, classification intent, decided-risk severity, price, or commercial intent changed.** A misleading interim assertion about the A2 baseline was corrected in favour of the verified A2 figures. |
| 2026-09-29 | ChatGPT Architect | **Amendment A6 — Documentary corrections + register integrity** | 77 registered Open Questions; 16 documentary defects identified by an independent post-A5 audit, including a `LOCKED` row pre-empting `OQ-12`, a `PROVISIONAL` `P-04` already decided by A3-2, a `D-nn` namespace collision across the §24.2 dependency table, the §25.3 `DEFERRED` registry, and the §26.2 renewal-cadence offsets, six semantically incorrect cross-references, a stale `OQ-62` implementation citation, unattributed reclassifications, and un-normalized summary counts | Repaired all 16 defects **documentarily only**: §8.1 Grace row now `LOCKED` for data retention with management access left open to `OQ-12`; `P-04` marked **SUPERSEDED** by A3-2 / `L-56` / §26.2.6; §24.2 dependency records renumbered `D-1`…`D-9` → **`D-23`…`D-31`** with an explicit pre-A6 mapping table and **no `D-01`…`D-19` identifier reused or altered**, and the §26.2 cadence notation retired from `D-n` to **`T-n`** (offsets from term end) to remove the collision, with all 12 live references updated and the historical A2 mention annotated rather than rewritten; §30.2 completeness rule corrected so `D-nn` **dependency records** route to §24.2, which resolves the `D-20`/`D-21`/`D-22` defect without changing the §25.3 `DEFERRED` count of 19; six cross-references corrected - and, **corrected post-audit for narrative precision, three were repointed** to their real authorities (`L-52`→§29.8, `D-17`→`OQ-55`, `P-09`→§29.5 + D-19), while **three incorrect citations were removed without any repoint** (`P-14`, `P-15`, `P-19`); the earlier "rerouted" phrasing recorded `P-14`→`OQ-40`, `P-15`→`D-10`, and `P-19`→§30.1.2 + D-19 as if each had been repointed, and the Final Independent Freeze Readiness Audit confirmed **no such repoint is observable in the current document**: `P-14`, `P-15`, and `P-19` now carry **no in-body citation whatsoever** (each appears only in its own §25.2 registry row), while `OQ-40`, `D-10`, and §30.1.2/`D-19` are cited only at their own semantically correct locations (§7.2.6/§9.2/§20.1/§28.8; §28.4/§30.1.5; §28.0/§28.2/§30.1.2 respectively) and were never the subject of these three A6 removals. **This is a historical change-log narrative precision correction only:** it changes no current authority, citation, registry entry, ID, or commercial policy, and it asserts no new decision.; stale `OQ-62` implementation citation removed; `payment_verified_at` / `subscription_start_at` replaced by the conceptual labels **Payment Verification Time** / **Subscription Term Start**; §28.11 and §26.7 no longer claim to "narrow" the freeze-blocking `OQ-20`; §27.3 now records that `OQ-21` is `CLOSED` by §27.2; C-9 and §28.2.6 rule-6 citation hygiene repaired; the 7 reclassifications attributed per amendment (A3: `OQ-12`; A4: `OQ-22`; A5: `OQ-08`, `OQ-09`, `OQ-10`, `OQ-40`, `OQ-56`); summary counts corrected to 33 closed / 22 narrowed / 7 reclassified; and **`OQ-78`** registered as a **non-blocking** `REGISTER BEFORE FREEZE` entry for the disposition of non-owner memberships on ownership transfer, kept **separate from** the still-open `OQ-20`. Recomputed totals: **78 registered, 45 open, 33 closed, 0 `CRITICAL`, 3 `HIGH`, 35 `MEDIUM`, 7 `LOW`, 3 `MUST RESOLVE BEFORE FREEZE`, 22 `REGISTER BEFORE FREEZE`** | **Documentation and register hygiene only. No commercial decision, no price, plan, lifecycle rule, entitlement, or commercial intent changed; no commercial entry closed, narrowed, or reclassified.** A6 registered exactly one new non-blocking entry, so `MUST RESOLVE BEFORE FREEZE` is unchanged at 3 and the commercial-freeze blockers `OQ-04`, `OQ-20`, `OQ-37` all remain open. Identifier renaming is a presentation change with an explicit mapping; no `D-nn` dependency meaning changed. **No** code, test, schema, migration, RLS, route, auth, backend, contract, UI, or roadmap change was authorized or performed, and the document is **not** frozen. |
| 2026-09-29 | Owner + ChatGPT Architect | **Amendment A7 — Final commercial freeze-blocker decisions** | The three remaining `MUST RESOLVE BEFORE FREEZE` entries were all `OPEN`: `OQ-04` (Corporate plan basis, entitlements, variables, and term), `OQ-20` (number of owners, co-ownership, and an entity without an owner), and `OQ-37` (launch density and launch sequencing). Register stood at 78 entries / 45 `OPEN` / 33 `CLOSED` with **3** `MUST RESOLVE BEFORE FREEZE` and **3** `HIGH` | Added **§31** (A7-1…A7-3 plus §31.4) and registered **`L-84`** (Corporate = all Business Plus entitlements as the minimum commercial floor, extendable by written quotation, 12-month minimum commitment), **`L-85`** (Corporate priced as **Custom Quote**, no fixed public Corporate price, 30-calendar-day default quotation validity, minimum required quotation fields, Business/Pro/Plus pricing unchanged), **`L-86`** (exactly **ONE Primary Business Owner** in normal operation, optional verified **Co-Owners**, Primary Owner as the accountable authority for sensitive ownership actions, no indefinite ownerless active state, conceptual **OWNERSHIP RECOVERY PENDING** with controlled verified replacement, shared-password handover prohibited), and **`L-87`** (**BAGHDAD FIRST**, Category Launch Gate of normally ≥ 5 active + paid + publicly publishable Businesses, growth targets of ~8–10 per category and ~30 overall, no fake/free padding, no automatic shutdown below the gate, honest empty state, focused initial category set, non-automatic geographic expansion, Founding Partners do not weaken paid-only rules). **Closed 3**: `OQ-04`, `OQ-20`, `OQ-37`, each with an A7 close trace in §24.3.6. **Registered 1**: `OQ-79` (ownership-dispute, deceased-owner, and quorum/legal-document evidence requirements) as a **non-blocking** `LEGAL/POLICY REVIEW` item required by §1.3 rule 6. Updated §24.3.5, §24.3.7, §25.1, §25.5, §1.6 item 8, the header, and the in-body rows in §2.5, §3.3, §4.1, §11.3, §26.7, §28.11, §28.12.4 | **Real Owner commercial decisions recorded as supplied. 3 freeze blockers closed, 0 invented, 1 non-blocking residual entry registered.** Register is now **79 registered / 43 `OPEN` / 36 `CLOSED`**, severity 0 `CRITICAL` / 1 `HIGH` / 35 `MEDIUM` / 7 `LOW`, classification 0 `MUST RESOLVE BEFORE FREEZE` / 22 `REGISTER BEFORE FREEZE` / 4 `BUSINESS CENTER` / 10 `IMPLEMENTATION ARCHITECTURE` / 2 `DEFERRED` / 5 `LEGAL/POLICY REVIEW`. **No price changed outside the Corporate quotation rules**; the Paid-Only rule and the Business/Professional boundary are unchanged; `OQ-78` remains `OPEN` and was explicitly **not** closed; A3–A6 meaning is preserved. **Zero** `MUST RESOLVE BEFORE FREEZE` entries remain, which is **not** a freeze declaration: the final independent Freeze Readiness Audit, Architect acceptance, and an explicit Document Owner freeze declaration have **not** occurred. **No** code, test, schema, migration, RLS, route, auth, backend, contract, UI, or roadmap change was authorized or performed; `IMPLEMENTATION_AUTHORIZED` remains `NO`; the document remains **NOT YET FROZEN**. |
| 2026-09-30 | Owner + ChatGPT Architect | **Amendment A8 — Cold-Start Acquisition + Business Onboarding Policy (pre-freeze REOPENING)** | A Final Freeze Readiness Audit had found the model commercially complete **in its pre-A8 state**, and the commercial design was then **intentionally reopened before freeze** by the Document Owner + Architect to address cold-start / first-business acquisition. Register stood at 79 entries / 43 `OPEN` / 36 `CLOSED` with **0** `MUST RESOLVE BEFORE FREEZE`, **1** `HIGH`, and 22 `REGISTER BEFORE FREEZE` | Added **§32** (A8-1…A8-11 plus §32.0 governance and §32.12 freeze status) and registered **`L-88`** (no permanent free commercial Business tier; free account and free non-commercial capabilities permitted; commercial presence stays paid; Professionals/Workforce remain a separate undefined model), **`L-89`** (Founding Launch Partner Program: invitation-only Civilpedia-selected cohort of approximately 20–30; Business Pro at **0 IQD** for **60 calendar days**; start anchor = the **later** of formal commercial launch or first successful public publication, so the clock does not burn while Civilpedia is unavailable; **no card**; **no** auto-renewal or auto-charge; once per genuine Business Entity; duplicate-entity abuse prohibited; ordinary expiry/Grace/hiding and data-retention at expiry; **no permanent free-plan precedent**; **distinct from Founding Partner**), **`L-90`** (Launch Partner pre-expiry value reporting from factual interaction metrics that are **never** leads or sales), **`L-91`** (Civilpedia-owned business acquisition CTA — **not** Sponsored inventory, must never imply listing is permanently free), **`L-92`** (Civilpedia-created Business Drafts; `CIVILPEDIA-MANAGED / OWNER NOT YET ATTACHED`; Draft is **not** ownership evidence; publication still requires entitlement + quality + ownership + moderation), **`L-93`** (ownership **invitation** is the preferred/default method, no Civilpedia-created password, one account per natural person, no silent pre-acceptance grant; **direct assignment is an admin-only exceptional, audited capability** that may not bypass verification), **`L-94`** (Business team capability intent: Primary Business Owner / Co-Owner / Manager / Editor; stored role enum, RBAC matrix, and RLS remain `DEFERRED`), **`L-95`** (server-managed commercial catalog requirement — ordinary category/subcategory/business/branch/visibility/label/media/acquisition-campaign changes must **not** require a new app release; **no** downloaded executable UI/code; new unrenderable UI types may still require an app update), **`L-96`** (future admin/Business Center control requirements — requirement only, no screens/routes/schema designed), and **`L-97`** (narrow launch-density reconciliation: during the Launch Partner phase an authorized Launch Partner with a valid Business Entity + active promotional entitlement + publicly publishable profile **MAY** count as a **COMMERCIAL-ACTIVE BUSINESS**; **not** a free listing; paid subscription remains the normal post-launch basis; Baghdad First, the 5-business gate, the ~8–10 and ~30 targets, and the no-fake-listings rule all preserved). **Closed 0.** **Narrowed 2**: `OQ-17`, `OQ-72`. **Registered 5**: `OQ-80`–`OQ-84`, all **non-blocking** `MEDIUM` / `Owner` / `REGISTER BEFORE FREEZE`. Added **2** dependency records (`D-32` server-managed catalog/admin-control architecture; `D-33` admin ownership-override security/audit/entitlement-administration policy), **`P-35`**/`P-36`, **`D-34`**, and standing prohibitions **24–30**. Amended §1.6 (new item 9 on the reopened pre-freeze state), §2.1.1/§2.1.2/§2.1.7, §2.5, §5.1a, §6.1.12, §10.1, §11.1/§11.1a, §11.3, §17.2, §22.1, §31.3, §24.2, §24.3.0 (new item 9), §24.3.3, §24.3.5, §24.3.6, §24.3.7, §25.1–§25.5, and the document header | **Real Owner commercial decisions recorded. 0 open questions closed, 3 narrowed, 5 new residual entries registered, 0 invented.** **No price changed** (§3.2, §5.7, §6.2 all unchanged) and **no permanent free commercial tier was created**. **The prior Final Freeze Readiness Audit is `VALID FOR THE PRE-A8 STATE` ONLY and is no longer sufficient by itself for final freeze** (§1.6 item 9, §32.12). **No** code, schema, migration, RLS, route, auth, backend, contract, test, UI, or roadmap change; **no** implementation authorized; document remains **ACTIVE DESIGN / NOT YET FROZEN**. |

| 2026-10-01 | **Document Owner + ChatGPT Architect** | **FINAL FREEZE DECLARATION — Commercial Model V1 `FROZEN`** (documentation-only; **not** a commercial amendment and **not** an implementation authorization) | `DOCUMENT_STATUS: ACTIVE DESIGN — CANONICAL COMMERCIAL SSOT — **NOT YET FROZEN**`; `FREEZE_STATE: NOT FROZEN`; §1.6 maturity row "It is **NOT YET FROZEN**" and state row "**ACTIVE DESIGN**"; §1.6 items 8 and 9 freeze gate unsatisfied; post-A8 state **`ACTIVE DESIGN` / `CANONICAL COMMERCIAL SSOT` / `NOT YET FROZEN`** (§32.12). Register stood at 84 registered / **48** `OPEN` / **36** `CLOSED` / **0** `MUST RESOLVE BEFORE FREEZE`; 97 `LOCKED` / 36 `PROVISIONAL` / 20 `DEFERRED`; **0** blocking conflicts | **`DOCUMENT_STATUS: FROZEN — CANONICAL COMMERCIAL SSOT`**; **`FREEZE_STATE: FROZEN`**; added header `FREEZE_DECLARATION` line and **§33 — Commercial Model V1 Freeze Declaration**, recorded as the **single authoritative current freeze record** (§33.0 single-current-state rule). Recorded as `SATISFIED`: **Independent A8-inclusive Freeze Readiness Audit completed**, **Architect Acceptance issued**, **explicit Document Owner freeze declaration**, **`MUST RESOLVE BEFORE FREEZE` = 0**, **freeze state = `FROZEN`** (§1.6 items 3, 8, 9, 10, 11; §33.0). Recorded the **post-freeze authority boundary** `FROZEN COMMERCIAL MODEL != IMPLEMENTATION AUTHORIZATION` with the full not-authorized list (§33.2): code, schema, migrations, Supabase/RLS, auth, routes, Business Center, Admin Console, subscription backend, payment gateway, Sponsored backend, Professional Marketplace, Construction Ecosystem. Updated §1.6 maturity table, consequence 1, item 3(c) satisfaction, item 8 satisfaction, item 9 sub-items 2–3 and 5, new §1.6 item 11, §1.5 rule 7 freeze-declaration note, §24.3.7 / §25.5 A8 freeze-gate statement, the post-A7 freeze-gate statement, §31.4, and §32.12 — all marked **historical/superseded** and repointed to §33. **No historical amendment row was rewritten, deleted, or reordered** (§1.5 rule 3). **Commercial decisions changed: 0. Open Questions closed: 0. Reclassified: 0. Narrowed: 0. Registered: 0. `LOCKED`/`PROVISIONAL`/`DEFERRED` added: 0. Prices changed: 0.** Registry unchanged at **84** / **48** `OPEN` / **36** `CLOSED` / **0** `MUST RESOLVE BEFORE FREEZE`, **97** `LOCKED` / **36** `PROVISIONAL` / **20** `DEFERRED**. All **48** remaining `OPEN` entries retain their existing status, severity, owner, and classification and remain routed to their proper later phases; **no** `OPEN` entry is implicitly closed by the freeze; **no** `PROVISIONAL` or `DEFERRED` item becomes `LOCKED` by the freeze | **Documentation / governance only.** Basis: **Final A8-inclusive independent Freeze Readiness Audit** + **Architect Acceptance** + **explicit Document Owner freeze declaration** (§33). This entry is **independent of the reopened A8 work**: it records no A8 commercial change and answers none of the A8 residuals (`OQ-80`…`OQ-84` all remain `OPEN`). It **preserves** the rule that **only the Document Owner may declare a freeze** by explicit update to this document (§1.5, §1.6 item 10). **`IMPLEMENTATION_AUTHORIZED` = `NO`** (§1.2, L-47); the roadmap is unchanged; no code, schema, migration, Supabase/RLS, auth, route, backend, contract, test, UI, or phase change. Any future commercial-model change requires a **new explicit post-freeze amendment** under §1.5 plus a fresh independent Freeze Readiness Audit and fresh Architect Acceptance. |

---

## 25. FINAL STATUS — DECISION REGISTRY

Registry state after **Amendments A3, A4, A5, A6, A7, and A8** (A3–A5 on
2026-09-29; A7 on 2026-09-29; A8 on 2026-09-30). Amendment A1
reconciled implementation-mapping conflicts and did **not** change any commercial
intent, so no previously approved rule was downgraded, removed, or reclassified.
Amendment A2 added governance rules only. Amendments A3–A5 **added** new Owner
commercial decisions (§§26–§30, registered as `L-55`…`L-83`, `P-34`, `D-15`…`D-19`)
and **closed** 33 registered Open Questions with explicit traces (§24.3.6);
Amendment A7 then closed 3 more (§24.3.6, `OQ-04`/`OQ-20`/`OQ-37`), giving the
cumulative **36** `CLOSED` rows. A2
and A3–A5 did **not** remove, weaken, or silently reinterpret any existing `LOCKED`
rule; where A5 narrows an existing rule (the "Leads" framing vocabulary, L-41),
the narrowing is recorded in place and as a new binding rule. **A8 added ten
further `LOCKED` decisions (`L-88`…`L-97`), two `PROVISIONAL` values (`P-35`,
`P-36`), one `DEFERRED` item (`D-34`), and standing prohibitions 24–30, while
closing `0` and narrowing `2` registered Open Questions. A8 removed, weakened, or
reinterpreted no existing `LOCKED` decision and changed no price.**

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
| L-41 | Entry paid plan must carry basic value evidence; analytics are never "confirmed sales"; use Interactions / Leads / Engagement. **Narrowed by A5-16 (L-76): "Leads" may be used only under the explicit A5-16 measurement rule.** |
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
| L-55 | **Subscription term anchor (A3-1, §26.1).** Payment verification and subscription start are distinct concepts. The paid term normally starts on the first successful public publication of the Business Profile; payment verification alone does not normally consume subscription days. After Payment Verified the customer has **14 calendar days** to provide the material required for publication. Civilpedia-caused delay does not start the subscription. If publication is still blocked on calendar day 15 solely because the customer failed to provide required materials despite documented requests, the term starts on day 15. End date = start date + purchased duration. Grace occurs **after** paid term expiry, never inside the paid term. |
| L-56 | **Manual renewal, early renewal, and Grace (A3-2, §26.2).** Commercial V1 renewal is **manual only**: no automatic charge, no stored payment instrument, and every renewal payment is independently verified. Early renewal extends from the existing paid term end date, so the customer never loses remaining paid days. Grace = **5 calendar days** after paid term expiry; the public profile remains visible during Grace; renewal during Grace preserves continuity and extends from the previous paid expiry date, so Grace is not extra free subscription time. If Grace expires the public Business is hidden, and a later payment is a **Reactivation** whose term starts after payment verification and successful republication — never retroactively from the old expiry date. |
| L-57 | **Renewal and expiry communications (A3-2, §26.2).** Cadence, expressed as offsets from **T** = the paid term end date: annual T-14, T-7, T0, Grace T+4, Hidden T+5; 3-month T-7, T0, Grace T+4, Hidden T+5; monthly T-3, T0, Grace T+4, Hidden T+5. (`T-n`/`T+n` are **date offsets, not identifiers**; the pre-A6 `D-n` spelling was retired by Amendment A6 to remove a namespace collision with `D-nn` registry/dependency identifiers — the cadence values are unchanged.) All renewal reminders stop immediately once renewal is verified; automated sales reminders may be suppressed while a renewal conversation is handled manually; while Payment is Pending Verification, "renew now" reminders stop and payment-status messaging is sent instead; customer messages use exact dates. One optional later win-back/reactivation communication is allowed and is not part of the core sequence. Channels: the in-app Business Center banner/state is the primary persistent status; FCM push is the primary automated reminder channel; WhatsApp Business manual messages are used for important renewal/expiry/hiding touchpoints at initial commercial scale; automated WhatsApp Business Platform/API is `DEFERRED` until scale justifies its cost and complexity. WhatsApp communication must follow applicable consent, template, and platform requirements. |
| L-58 | **Price changes and grandfathering (A3-3, §26.3).** A price change never changes an already-paid unexpired term; no retroactive price increase and no collection of a price difference. The new official price applies on future renewal after its effective date, and price decreases also apply at future renewal. Minimum price-change notice target = **30 days**. Founding Partner badge/history may remain, but the first-year discounted price is **not** a permanent lifetime price. No lifetime grandfathering exists unless explicitly granted in a written Civilpedia commercial offer. Promotions/contracts may define their own explicit terms. |
| L-59 | **Suspension (A3-4, §26.4).** Suspension is distinct from Expired. A non-serious correctable violation requires a warning/correction with a **7 calendar day** correction window; a serious violation may be suspended immediately where required for platform/user protection. During suspension: public profile hidden; the Business Owner retains Business Center access unless security/fraud circumstances require otherwise; Sponsored becomes inactive/suppressed; relevant restricted actions may be blocked; data is **not** automatically deleted. A customer-caused suspension does **not** pause the subscription clock; where suspension is determined to be Civilpedia error, equivalent service time is restored as service credit or term extension. |
| L-60 | **Termination (A3-4, §26.4).** Termination is permitted for material fraud, forged evidence, impersonation, serious or repeated violation, or persistent failure to cure material violations. Effects: removal from discovery, Sponsored stops, verification becomes inactive, no automatic refund for customer-caused termination, and proportional refund or service credit for Civilpedia-caused service failure under the future refund policy. **One appeal may be filed within 7 days**; serious-risk content may remain hidden during the appeal. |
| L-61 | **Permanent business closure (A3-5, §26.5).** Permanent closure is distinct from Expired. Operational concept: Operating → Closure Requested → Permanently Closed. After confirmed permanent closure: removed from discovery; Sponsored stops; active verification becomes inactive; affected branches are closed appropriately; private business/history records are retained per the retention policy; the Business Entity is **not** automatically deleted; and there is no automatic refund merely because the customer voluntarily closed the business. A direct historic link must communicate that the business is no longer active rather than presenting misleading active business information. Reopening is permitted for the same genuine Business Entity after appropriate re-verification; materially different ownership/legal entity routes to ownership-transfer/new-entity rules. Historical Founding Partner status may remain historical but must not imply that a closed business is currently active. |
| L-62 | **Duplicates (A3-6, §26.6).** One real operating Business Entity must not have duplicate commercial profiles. Verified duplicates may be merged or retired under Civilpedia control. Deliberate duplicate creation to manipulate visibility, promotions, Sponsored inventory, or commercial rules may trigger enforcement. |
| L-63 | **Business sale / ownership transfer (A3-7, §26.7).** The subscription belongs to the Business Entity, not a user account, and ownership transfer does not happen merely by sharing login credentials — a formal ownership-transfer workflow is required. Where the same genuine Business Entity continues after a legitimate transfer and Civilpedia verifies the transfer, remaining subscription value may remain with that Business Entity. A materially new entity/business identity requires new-entity assessment. Verification evidence must be refreshed where ownership-sensitive information changed. |
| L-64 | **Terminology (A3–A5, §26.0).** **Business Owner** denotes the business capability role; **Document Owner** denotes the document decision authority. The two are never merged, and the decision authority is never inferred from the business role. This closes `OQ-63`. |
| L-65 | **Category eligibility (A4-8, §27.1).** The Business commercial plan is for commercial organisations such as companies, contractors, suppliers, stores, manufacturers, equipment providers/rental businesses, and other commercial or service businesses appropriate to the Business model. Individual professionals — individual structural designers, architects, electrical/mechanical/MEP professionals, surveyors, and individual consultants and similar — must **not** be silently placed into this model. Engineering offices, consulting organisations, laboratories, and specialist engineering organisations remain reserved for separate research/model decisions and must not be silently treated as identical to ordinary Business plans. The Professional Marketplace and Engineering Organisation commercial models remain separate and `DEFERRED`. |
| L-66 | **Claiming boundary (A4-9, §27.2).** Commercial V1 has **no** open public "Claim this business" workflow. Civilpedia creates/onboards the Business Draft through the controlled commercial onboarding process; the Business Owner creates their own Civilpedia account; Civilpedia links/invites the verified owner to the Business; Civilpedia never creates and hands over a customer password. Open claiming and competing claims are `DEFERRED` until a dedicated evidence/dispute model exists. |
| L-67 | **Production paid-only (A4-9, §27.2).** Mock, dev, test, and seed entities do not become entitled production commercial listings merely because they exist in data. Production publication requires the canonical commercial onboarding, payment, and publication rules. |
| L-68 | **Payment exception outcomes (A5-10, §28.1).** No subscription activation on the basis of an uploaded receipt or screenshot alone; activation requires actual payment verification. Underpayment: no activation until the required amount is satisfied or an explicitly approved commercial adjustment exists. Overpayment: the difference is refunded or recorded as explicit customer credit after verification, and is never silently retained. Unclear evidence: **Needs Clarification** and remains unverified. Duplicate transfer/payment: refund or explicit credit after reconciliation. Third-party payer: may be accepted after explicit linkage to the intended Business/payment and does **not** establish Business ownership. Payment to an incorrect/unapproved destination, payment received after Grace expiry, and payment for a closed/suspended/invalid Business follow the recorded outcomes. Suspected fraudulent or forged proof is rejected and routed to enforcement/fraud review. |
| L-69 | **Payment verification authority (A5-10, §28.1).** Only explicitly authorized Civilpedia finance/admin authority may mark a payment Verified, refunded, or credited. Where operational scale permits, sales request creation is separated from final payment verification. |
| L-70 | **Currency and payment rails (A5-10, §28.1).** Commercial V1 canonical pricing and accounting currency is **IQD**. Payment must use Civilpedia-approved payment destinations/rails, and future electronic-payment integration must use appropriately authorized/regulated providers. No unsupported assumptions may be made about tax invoice law or payment-provider legal obligations. |
| L-71 | **Payment verification service target (A5-10, §28.1).** Target customer-facing verification within **one business day** after clear evidence/funds are available, aiming for same-day completion where operationally possible. This is a service target, **not** a guaranteed bank settlement promise. |
| L-72 | **Cancellation, refunds, and plan changes (A5-11, §28.2).** Voluntary cancellation normally takes effect at the end of the already-paid period, service continues through the paid end date unless immediate removal is requested or required, and there is no automatic prorated refund merely because the customer stops using the service. Refund or credit is appropriate where validated: duplicate payment, verified overpayment, material Civilpedia failure to provide the purchased service, and other mandatory legal/customer rights. Upgrade may take effect immediately, charging only the appropriate prorated difference for the remaining paid service period using a simple auditable Civilpedia proration method (exact formula = P-34). Downgrade normally takes effect at the next renewal, with no retroactive removal of already-paid term value unless explicitly requested and commercially agreed. |
| L-73 | **Sponsored rules (A5-12, §28.3).** Sponsored is separate from subscription and never equals Verified. Eligibility: an eligible active plan where §6.1.8 requires Pro/Plus, publishability and profile-quality compliance, and advertising content related to the actual Business. Prohibited: false affiliation, fake certification, deceptive discount, misleading superlative presented as fact, impersonation, illegal/prohibited content, and unsupported authorized-dealer/official-agent claims. Every Sponsored surface must be clearly and consistently identified as paid advertising; Sponsored must never masquerade as organic ranking, which remains commercially independent. Campaign lifecycle concept: Scheduled, Active, Ended, Cancelled/Withdrawn. Sponsored paid time begins when the placement actually becomes available/public, not merely when money is received. Civilpedia-caused non-delivery restores equivalent placement time or appropriate commercial credit/refund. Customer-caused suppression or suspension does not automatically pause Sponsored time unless Civilpedia explicitly approves otherwise. The initial Sponsored product attaches to the Business Entity. Inventory is finite per Category × Area, Civilpedia does not oversell unavailable slots, and waitlisting is preferable to selling non-existent inventory. |
| L-74 | **Verification meaning and validity (A5-13, §28.4).** **PAID ≠ VERIFIED ≠ SPONSORED.** Verified means Civilpedia has checked defined identity/business information using accepted evidence. It does **not** mean that Civilpedia recommends the business, guarantees quality, guarantees workmanship, guarantees commercial outcome, or guarantees every claim made by the business. There is **no** automatic fixed 12-month expiry solely because time passed; re-verification is triggered by material sensitive changes, risk signals, suspected fraud, ownership changes, identity/location changes, or Civilpedia review requirements, and subscription renewal alone does not automatically equal verification renewal. Evidence may include only what is reasonably necessary (e.g. official business/registration evidence where applicable, authorized owner/representative identity evidence, control of the official contact channel, relevant location evidence, and optional additional evidence or field verification where justified). False or forged evidence may cause immediate suspension, verification withdrawal, and enforcement. Only authorized Civilpedia staff/authority may grant or withdraw Verified, and there is no self-verification. |
| L-75 | **Content, offers, and brand claims (A5-14, §28.5).** Every time-limited offer must carry validity/start-end information; expired offers cease public promotion; the business is responsible for commercial price/offer accuracy; Civilpedia may remove stale or deceptive content. "Sells/products from Brand X" is **not** equivalent to "Authorized Dealer / Official Agent / Exclusive Distributor"; claims of an official or authorized relationship require appropriate evidence, and unsupported official affiliation claims are prohibited. Prohibited generally: fake certificates, false affiliations, deceptive discounts, fabricated achievements, impersonation, and materially misleading content, any of which may trigger takedown/enforcement. |
| L-76 | **Publication Required Fields Gate (A5-15, §28.6).** Publication requires a **Required Fields Gate**, not an arbitrary public numerical quality score. At minimum the profile must contain appropriate identity/name, category, area/location or service area, a usable contact method, a meaningful description, appropriate identity/cover/logo media, and minimum category-relevant service/product/content. An incomplete profile remains Draft / not publishable until the gate is met. The exact per-category field matrix and UX remain Business Center/design work. |
| L-77 | **Analytics honesty (A5-16, §28.7).** Civilpedia must not call profile views or generic taps confirmed customers or sales. Exact metric names are preferred (Profile Views, WhatsApp Clicks, Call Clicks, Directions Clicks, Offer Views, Saves, Search Appearances, etc.). "Lead" may be used only where a defined intentional contact/action qualifies under an explicit measurement rule, and no analytics metric implies a completed sale. |
| L-78 | **Records and privacy (A5-17, §28.8).** Payment receipts, verification evidence, staff notes, and sensitive ownership/payment information are private. The public profile must **never** expose payment receipts, internal verification notes, payment identifiers, plan/payment admin data, sensitive identity evidence, or internal fraud/risk notes. The Business Owner may see appropriate customer-facing transaction/status information, but not necessarily internal antifraud/staff notes. Exact statutory retention/deletion periods are **not** invented here and require Iraqi legal/accounting/privacy review. |
| L-79 | **Legal / policy obligations register (A5-18, §30).** Civilpedia maintains an explicit Legal/Policy Obligations Register covering the eleven areas enumerated in §30. No legal terms are drafted in this document, and qualified Iraqi legal/accounting review is recorded as required before production commercial launch where applicable. |
| L-80 | **Business Center commercial inputs (A5-19, §28.10).** Expected future Business Center capabilities must include subscription status, renewal/expiry/Grace state, payment status, verification status, support/contact, evidence upload where allowed, Team, business switching for users managing multiple Businesses, profile/media/products/services/projects/offers/branches, analytics according to entitlement, and subscription/renewal surfaces. Exact UX, routes, schema, and RBAC remain separate architecture/design work. |
| L-81 | **Team (A5-20, §28.11).** For V1 commercial policy the operational default ceiling is **5 active team members** for ordinary Business plans; Corporate may have custom team requirements. Team count is **not** positioned as the primary pricing value proposition. Financial/subscription information is visible only to the Business Owner and explicitly finance-authorized roles. Exact RBAC/storage mapping remains deferred architecture work. |
| L-82 | **Quotations and instalments (A5-21, §28.12).** Business, Business Pro, and Business Plus are **prepaid**; there is no deferred debt or instalment structure in ordinary V1. Corporate may use individually approved written terms, and the Corporate quotation default validity is **30 calendar days** unless the quotation explicitly states otherwise. |
| L-83 | **Pricing experiments, commercial measurement, language, and Iraqi regulatory caution (A5-22, §28.13, §28.14, §29).** Prices must not be silently personalized for equivalent customers; pricing experiments and promotions must be explicit, time-bounded, documented commercial offers; official base price changes follow L-58. Commercially meaningful KPIs (paid activations, sales-to-paid conversion, renewal rate, churn, average revenue per paid Business) are tracked without misrepresenting interaction metrics as sales. **Arabic is the controlling V1 customer-facing language** unless future legal review requires a different governing-language provision. Global SaaS practice must **not** be presented as Iraqi law: the Central Bank of Iraq electronic-payment regulatory framework, including **Electronic Payment Services Regulation No. 2 of 2024**, applies to future integrated payment providers, and tax, invoice, and record-retention requirements remain subject to qualified Iraqi accounting/legal review. No VAT, invoice, tax, statutory retention, or consumer-law requirement may be invented here. |
| L-84 | **Corporate plan (A7-1, §31.1).** Corporate remains a **quotation-based enterprise plan**. It includes **ALL Business Plus entitlements as its minimum commercial floor** and may **extend beyond Business Plus** through a written quotation / enterprise agreement. Corporate commercial variables may include included branch count, additional branch scale, team-member capacity, support/service level, managed-service scope, media/content scale, analytics/reporting requirements, and other enterprise-specific commercial services already permitted by this Commercial Model. Corporate **minimum subscription commitment is 12 months.** Corporate pricing is **Custom Quote**; A7 creates **no** fixed public Corporate price. **Ordinary Business / Business Pro / Business Plus pricing is unchanged** (§3.2, §5.7). Closes `OQ-04`. |
| L-85 | **Corporate quotation content and validity (A7-1, §31.1).** The Corporate quotation **default validity is 30 calendar days** unless the quotation explicitly states otherwise, preserving the A5-21 rule (§28.12.3, L-82) unchanged. Every Corporate quotation must explicitly state at minimum: **Business identity; plan = Corporate; subscription duration; total quoted price / payment terms; included branches; relevant team allowance; material included services/entitlements; any separately priced add-ons; and quotation expiry date.** A7 does not set a numeric included branch count for Corporate; that remains a per-quotation commercial variable (`P-02`, `PROVISIONAL`). |
| L-86 | **Business ownership cardinality and ownership recovery (A7-2, §31.2).** Every Business Entity has **exactly ONE Primary Business Owner** during normal operation, and may additionally have **one or more verified Co-Owners** subject to team/member operational limits (L-81). The **Primary Business Owner** is the accountable authority for high-sensitivity ownership operations (initiating/approving controlled ownership transfer, primary ownership recovery, and other ownership-sensitive actions defined by future RBAC/security architecture). A **Co-Owner does not automatically have equal authority** to the Primary Business Owner for sensitive ownership-transfer actions. A Business Entity must **not** remain indefinitely in a normal active ownership state with **no** Primary Business Owner. If that owner becomes unavailable, loses access, dies, resigns, or otherwise cannot fulfil the role, the Business enters the conceptual state **OWNERSHIP RECOVERY PENDING**: Civilpedia verifies an eligible replacement, Business data and subscription remain attached to the Business Entity, ownership-sensitive actions may be restricted, and public visibility does **not** have to be removed solely because recovery is pending unless fraud/security/moderation risk requires it; the verified replacement is assigned through the controlled ownership process (§26.7, L-63). **Shared passwords and account handover remain prohibited** (§26.7.2, L-63). Owner and Co-Owner are commercial/capability concepts (§11.1, L-30); exact RBAC mapping and exact recovery UX/RBAC/state persistence remain architecture/policy work (P-25, D-28, `OQ-77`). Ownership disputes, deceased-owner evidence, and quorum/legal-document evidence remain future ownership-policy/legal-review matters (`OQ-79`). Closes `OQ-20`. |
| L-87 | **Business Directory V1 launch density and sequencing (A7-3, §31.3).** Initial commercial launch geography is **BAGHDAD FIRST**, and Civilpedia does **not** broadly launch an obviously **sparse paid-only directory**. The **Category Launch Gate** is at least **5 active, paid, publicly publishable Businesses** in the applicable Baghdad launch market before a category opens as a normal public discovery category. Growth **target** is approximately **8–10 active paid Businesses per launched category** before strong/promoted marketing, and the **overall initial directory launch target** is approximately **30 active paid publicly publishable Businesses** across the initial launch categories before the formal commercial/public launch push; both are **targets, not contractual or customer guarantees**. Categories below the Launch Gate must not present a misleading normal category experience — they may be hidden from primary discovery/navigation or shown as a clear **"Coming Soon / قريباً"** state — and must **never** be populated with fake or free production listings to create density. The 5-Business threshold is a **Launch Gate, not a perpetual automatic shutdown threshold**: a launched category is not automatically closed merely because its count later falls below 5. A launched category that falls to **zero** active publishable Businesses must show an **honest empty/unavailable state** rather than stale or fake listings. Civilpedia launches a **focused initial group** of commercially meaningful categories rather than all categories simultaneously; the exact initial category list may be selected operationally on sales-readiness and inventory grounds **without changing the 5-business Launch Gate**. **Expansion outside Baghdad is not automatic** and requires an explicit later commercial/product decision. **Founding Partner** acquisition may help reach launch density but does **not** weaken the paid-only publication rule (§2.1, §2.5, §27.2). Closes `OQ-37`. **Narrowed by A8-11** (§32.11 → `L-97`): during the **initial Launch Partner phase**, an authorized Launch Partner with a valid Business Entity, an **active A8 promotional commercial entitlement**, and a publicly publishable profile **MAY** count toward launch-category supply density as a **COMMERCIAL-ACTIVE BUSINESS**. This is **not** a free listing, **not** a new tier, and does **not** lower or weaken the 5-Business gate or any A7-3 rule. |

**A8 additions to the LOCKED registry (added 2026-09-30, Amendment A8 — recorded in §32)**

| # | Locked decision |
|---|---|
| L-88 | **No permanent free commercial Business tier (A8-1, §32.1).** Civilpedia will **NOT** create a permanent free commercial listing tier for companies, contractors, suppliers, stores, manufacturers, equipment providers / rental businesses, ready-mix businesses, or any other commercial Business-plan-eligible organisation. **Creating a Civilpedia user/account may be free**, and **using non-commercial Civilpedia capabilities may be free**, but **persistent public commercial presence** for an eligible Business Entity remains a **paid commercial product**, except for the explicitly authorized **temporary** launch/promotional access in `L-89`. **Individual Professionals / Workforce are a separate future model**, are **NOT** converted into paid Business listings by A8, and the future Professionals/Workforce monetization model is **NOT** defined by A8. This **reinforces and does not weaken** `L-01` and `L-02`. |
| L-89 | **Founding Launch Partner Program (A8-2, §32.2).** Civilpedia may select an **invitation-only** initial cohort of approximately **20–30 commercial Businesses** for cold-start seeding; **selection is controlled by Civilpedia** and is **not** an automatic entitlement. An approved Launch Partner receives **BUSINESS PRO at a promotional price of 0 IQD for 60 calendar days**. The 60-day period **does not begin merely when Civilpedia creates the Business Draft**; the **trial start anchor is the LATER of** (a) the **Civilpedia formal commercial launch date** and (b) the **Business's first successful public publication after that launch**, so that a business does not lose promotional days while Civilpedia is not genuinely available to users. **No card or payment instrument is required**, and there is **no automatic renewal and no automatic charge** (preserving `L-56`). The promotional period is normally available **once per genuine Business Entity**, and **duplicate entities or accounts may not be used to obtain repeated launch trials** (applying `L-62`). At expiry the business **may convert** to Business / Pro / Plus / Corporate according to applicable eligibility; if **no paid subscription is verified**, the ordinary expiry / Grace / public-hiding rules apply; and **data is not automatically deleted** (`L-25`, `L-61`). Launch Partner promotional access creates **no permanent free-plan precedent** and **does not create a free tier**. **Launch Partner is distinct from the Founding Partner annual pricing programme** and the two must not be merged; a business eligible under both receives the temporary promotional Pro access first and, later, the eligible Founding Partner first-year **paid** pricing (§5.1a, §5.7). |
| L-90 | **Launch Partner value and conversion (A8-3, §32.3).** Before promotional expiry, Civilpedia **should, where available**, show the Business its **factual usage metrics** — Profile Views, WhatsApp Clicks, Call Clicks, Directions Clicks, and other approved interaction metrics. These metrics are **interaction metrics only**; they are **NOT guaranteed leads** and **NOT confirmed sales**. The commercial purpose is to allow the Business to evaluate actual observed value before deciding whether to subscribe. This restates, and does not soften, `L-77` and `L-41`. |
| L-91 | **Business acquisition CTA (A8-4, §32.4).** Civilpedia may display **first-party promotional surfaces** inviting businesses to join the commercial directory (approved intent, not final copy: "هل لديك نشاط في قطاع البناء؟ اعرض نشاطك التجاري على Civilpedia." / "اشترك الآن لعرض نشاطك على Civilpedia."). This is a **Civilpedia-owned acquisition CTA, NOT third-party Sponsored inventory**, and it neither consumes nor competes for Sponsored Category × Area inventory. It may lead to Business subscription information, Business application/onboarding, an approved WhatsApp Business sales contact, or a future approved sales flow, and may appear on a Home promotional banner, in the Business Directory, in empty or under-supplied commercial categories, or on other appropriate Civilpedia-owned surfaces. **Civilpedia must not imply that commercial listing is permanently free.** Exact copy, visual design, campaign timing, targeting, and destination are design/marketing configuration (`P-35`, D-27). |
| L-92 | **Civilpedia-created Business Drafts (A8-5, §32.5).** Civilpedia staff **may create a Business Draft** on behalf of a prospective customer or Launch Partner and may prepare business identity, category/activity, description, contact information, logo/media, products/services, portfolio/projects, branches, and other permitted commercial profile content, **using information supplied or authorized by the Business**. A Draft **may exist before a Business Owner is attached** and is then **`CIVILPEDIA-MANAGED / OWNER NOT YET ATTACHED`** until ownership is assigned and accepted. **A staff-created Draft does NOT itself prove ownership.** **Publication still requires all applicable:** subscription/promotional entitlement, Minimum Profile Quality / Required Fields Gate, ownership/onboarding, and moderation/verification requirements (`L-76`, §19, §13, §9). |
| L-93 | **Ownership invitation default, and admin-only direct assignment (A8-6 and A8-7, §32.6, §32.7).** The **preferred and default** ownership-assignment method is **INVITATION**: Civilpedia creates the Business Draft → the Business representative creates or uses **their own** Civilpedia account → Civilpedia sends the ownership invitation → the user reviews and accepts → controlled ownership linkage occurs. **Civilpedia must NOT create a password and hand the credentials to the Business**, each natural person uses their own account, and a **pending invitation must not silently grant ownership before acceptance**. **Primary Business Owner rules approved in A7 remain authoritative** (`L-86`, §31.2). **Direct assignment may exist as an ADMIN-ONLY EXCEPTIONAL capability**: it may only target an **already identifiable Civilpedia user account**, must not involve shared credentials or password handover, and must create an **auditable record** recording at minimum the acting Civilpedia admin, the affected Business, the target user, the role/capability assigned, the timestamp, and the reason/context where required. Routine onboarding still prefers invitation/acceptance; Primary Business Owner assignment should normally require acceptance/verification; **a direct assignment must not bypass ownership verification** where verification is otherwise required; and emergency/override behaviour, exact security controls, and audit persistence remain architecture/security-policy work (D-28, D-33). |
| L-94 | **Business team capability intent (A8-8, §32.8).** The capability concepts are **preserved**: **Primary Business Owner** = highest accountable ownership authority; **Co-Owner** = ownership participation but **not** automatically equivalent to the Primary Business Owner for sensitive ownership transfer; **Manager** = operational management **without** ownership authority; **Editor** = limited content-management capability. A8-8 locks **only this operational intent**: the **exact stored role enum / RBAC matrix / RLS implementation remains `DEFERRED`** (P-25, D-28, `OQ-77`), `L-81` is unchanged, and no new role, enum value, column, RLS policy, or migration is created or authorized. |
| L-95 | **Server-managed commercial catalog requirement (A8-9, §32.9).** Commercial catalog content must **NOT** require a new mobile-app release merely in order to add a commercial category, add a subcategory/activity, add/remove/reorder a Business, change category visibility, change category labels/descriptions/media, add/update branches, activate/deactivate eligible commercial records, or change Civilpedia-owned acquisition campaign/banner content. The commercial taxonomy/catalog must be **administratively manageable from backend / admin-controlled data**, Flutter should consume supported commercial data/configuration rather than hard-code every future record, and the app **may** cache the last valid catalog for resilience/offline behaviour. This does **NOT** authorize **arbitrary downloaded executable UI/code**, and **new UI capability/block types the installed app cannot render may still require an app update**. Exact schema, taxonomy tables, caching, realtime strategy, Remote Config usage, admin-panel implementation, permissions, RLS, and synchronization remain **IMPLEMENTATION ARCHITECTURE** decisions (D-32, D-28, D-30). A8-9 is a **product/architecture requirement only** and authorizes no implementation. |
| L-96 | **Admin and Business control requirements (A8-10, §32.10).** Recorded as **future implementation requirements, not authorization**: future authorized administration tooling should support at minimum Categories; Activities/Subcategories; Businesses; Branches; Ownership & Team; Invitations; Launch Partner status; Subscription/status management; Civilpedia acquisition banners/campaigns; Moderation; and Audit logs, and Business Center should later allow entitled users to manage appropriate Business content subject to moderation and sensitive-change rules. A8 designs **no** exact screen, route, or schema (D-32, D-33, D-21, `OQ-77`). |
| L-97 | **Launch density reconciliation (A8-11, §32.11).** During the **initial Launch Partner phase**, an authorized Launch Partner with a **valid Business Entity**, an **active A8 promotional commercial entitlement**, and a **publicly publishable profile** **MAY count toward launch-category supply density**; the preferred term is **COMMERCIAL-ACTIVE BUSINESS**. Such a Business must **NOT** be described, presented, or sold as a **free listing**, a free tier, or a permanent free plan. For ordinary **post-launch paid operation**, a **paid subscription remains the normal entitlement basis**. A8-11 **preserves unchanged**: **BAGHDAD FIRST**, focused initial categories, the normal **5-Business launch gate**, the **~8–10** growth target, the **~30** formal launch target, the ban on fake listings, and the ban on a permanent free commercial tier. A8-11 **does not lower** the 5-Business gate; it states whose entitlement may be counted toward it during the initial Launch Partner phase. |

**Amendment A8 note.** A8 added **ten** `LOCKED` commercial decisions (`L-88`–`L-97`)
and **closed 0** `MUST RESOLVE BEFORE FREEZE` entries. A8 added **2** `PROVISIONAL`
(`P-35`, `P-36`) and **1** `DEFERRED` (`D-34`) entry, **2** dependency records
(`D-32`, `D-33`), and standing prohibitions **24–30**. A8 created **no** commercial
decision beyond those recorded in §32, changed **no** price, and created **no**
permanent free commercial tier.

**Amendment A7 note.** A7 added **four** `LOCKED` commercial decisions (`L-84`–`L-87`)
closing the last three `MUST RESOLVE BEFORE FREEZE` entries (`OQ-04`, `OQ-20`,
`OQ-37`). A7 added **no** `PROVISIONAL` and **no** `DEFERRED` registry entry, and
created **no** new commercial decision beyond those recorded in §31.

**Amendment A2 note.** A2 added **no** `LOCKED` commercial decision. The `LOCKED`
count therefore remained **54 at that point** (later amendments raised it to **83**
in A3–A5, **87** in A7, and **97** in A8). The A2 additions — document maturity (§1.6), the
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
| P-04 | **SUPERSEDED by A3-2 / `L-56` (§26.2.6) — marked by A6, 2026-09-29.** Grace Period duration is `LOCKED` at **exactly 5 calendar days**. The former "~3–7 days" target is historical, is **no longer provisional**, and must not be quoted, reused, or treated as an open target. |
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
| P-34 | Upgrade proration method and exact formula (A5-11, §28.2). A5-11 requires a **simple auditable Civilpedia proration method** and explicitly routes the exact implementation formula to architecture/finance design. |
| P-35 | Business acquisition CTA **copy, visual design, campaign timing, targeting, and destination** (A8-4.4, §32.4.7 → L-91). A8 locks the **approved intent** and the honesty constraint; the concrete configuration is design/marketing work and must enter the Arabic localization SSOT (D-27, §28.14). **Not** a Document Owner commercial decision. |
| P-36 | Launch Partner **value-reporting UX and analytics storage presentation** (A8-3, §32.3.5 → L-90). A8 locks that factual interaction metrics should be shown where available before promotional expiry; the reporting UX and analytics storage are design/architecture work (D-25, `OQ-77`). Retention/counting/pre-expiry-window rules remain `OQ-17`. **Not** a Document Owner commercial decision. |

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
| D-15 | Branch-level Sponsored product (A5-12, §28.3). The initial Commercial V1 Sponsored product attaches to the Business Entity. |
| D-16 | Automated WhatsApp Business Platform / API (A3-2, §26.2). Deferred until scale justifies its cost and operational complexity. Manual WhatsApp Business messaging remains in force. |
| D-17 | Open public business claiming and competing-claim dispute model (A4-9, §27.2). Deferred until a dedicated evidence/dispute model exists. |
| D-18 | Additional Founding Partner cohorts beyond the initial first 50 (A3-3, §26.3). Not promised or implied; any later cohort requires a new explicit Document Owner commercial decision. |
| D-19 | Legal drafting of the §30 Legal/Policy Obligations Register content, and the Iraqi legal/accounting review itself. A5 records the dependency and drafts no legal text. |
| D-34 | **Additional Launch Partner cohorts beyond the initial cold-start cohort** (A8-2, §32.2). A8 authorizes exactly **one** invitation-only initial cohort of approximately 20–30 businesses for cold-start seeding. **No later Launch Partner cohort is promised or implied**; any later cohort requires a new explicit Document Owner commercial decision. Mirrors the D-18 treatment of Founding Partner cohorts. `D-34` is used rather than `D-20` because `D-20`…`D-33` are reserved §24.2 dependency-record identifiers (§24.2 namespace note). |

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
13. Do not apply the Business subscription model to individual professionals, or
    to engineering/consulting/laboratory organisations by analogy (L-45, L-65,
    §27.1).
14. Do not start, extend, or restore a paid subscription term on any basis other
    than A3-1 (§26.1, L-55). Payment verification alone must not consume
    subscription days.
15. Do not auto-charge, store a payment instrument, or treat a renewal as verified
    without independent verification, and do not treat the 5-day Grace period as
    extra free subscription time (L-56).
16. Do not activate a subscription on a receipt or screenshot alone, and never
    silently retain an overpayment (L-21, L-68).
17. Do not grant or withdraw Verified except through authorized Civilpedia
    staff/authority, and never permit self-verification (L-74).
18. Do not present profile views or generic taps as customers, sales, or completed
    transactions, and do not use "Lead" outside an explicit measurement rule
    (L-77, L-41).
19. Do not expose payment receipts, payment identifiers, internal verification
    notes, internal fraud/risk notes, plan/payment admin data, or sensitive
    identity evidence on a public profile (L-37, L-78).
20. Do not present a global SaaS practice as Iraqi law, and do not invent VAT,
    invoice, tax, statutory retention, or consumer-law requirements (L-83, §29).
21. Do not present Sponsored as organic, present it without a clear paid-advertising
    label, or use it as a verification signal (L-16, L-18, L-73).
22. Do not use a bare "Owner" for either authority; write **Business Owner** or
    **Document Owner** (L-64, §26.0).
23. Do not close, answer, or reclassify a registered Open Question except by an
    explicit Document Owner decision recorded in this document, and do not leave
    a residual of a decided question unregistered (§24.3.0 items 2 and 8).

**Standing prohibitions 24–30 (added by Amendment A8).**

24. Do not create, publish, sell, or imply a **permanent free commercial Business
    listing tier**, a "free forever" commercial presence, or a permanent free plan
    for any Business-plan-eligible organisation (L-02, L-88, §32.1). A free user
    account and free non-commercial capabilities are permitted; paid commercial
    presence is not free.
25. Do not start, burn, or expire Launch Partner **promotional days** before the
    A8 trial start anchor (the later of formal commercial launch or the Business's
    first successful public publication), and do not create any card requirement
    or any automatic renewal/charge for a promotional entitlement
    (L-89, §32.2.2).
26. Do not **merge Launch Partner and Founding Partner** into one concept, price,
    badge, or sales message, and do not present a Launch Partner promotional
    entitlement as a Founding Partner price or as a permanent free plan
    (L-89, §5.1a, §32.2.4).
27. Do not create a Civilpedia password for a Business or hand over credentials;
    do not treat a staff-created Business Draft as proof of ownership; do not grant
    ownership before acceptance except through the audited **admin-only**
    direct-assignment path; and do not let direct assignment bypass ownership
    verification where verification is required (L-29, L-66, L-92, L-93, §32.5–§32.7).
28. Do not present Launch Partner interaction metrics as guaranteed leads,
    customers, or sales, and do not use "Lead" outside the A5-16 measurement rule
    (L-41, L-77, L-90, §32.3).
29. Do not deliver, download, execute, or authorize **downloaded executable UI/code**
    to satisfy the server-managed commercial catalog requirement, and do not treat
    that requirement as authorization for arbitrary remote code execution
    (L-95, §32.9.5).
30. Do not present the Civilpedia business acquisition CTA as **third-party
    Sponsored** inventory, do not charge for it, and do not imply that commercial
    listing is permanently free (L-16, L-73, L-91, §32.4).

### 25.5 Registry counts (informational)

| Classification | After A1 | After A2 | After A3–A5 | After A6 | After A7 | **After A8** |
|---|---|---|---|---|---|---|
| `LOCKED` | 54 | 54 | **83** | **83** | **87** | **97** |
| `PROVISIONAL` | 33 | 33 | **34** | **34** | **34** | **36** |
| `DEFERRED` | 14 | 14 | **19** | **19** | **19** | **20** |
| §24.2 dependency records (`D-20`…`D-nn`) | — | — | — | **12** | **12** | **14** |
| Registered Open Question IDs | 24 | 70 | **77** | **78** | **79** | **84** |
| OPEN QUESTIONS (`OPEN`, §24.3) | 24 | 70 | **44** | **45** | **43** | **48** |
| — of which `MUST RESOLVE BEFORE FREEZE` | 28 | 28 | **3** | **3** | **0** | **0** |
| CLOSED Open Questions (with trace, §24.3.6) | 0 | 0 | **33** | **33** | **36** | **36** |
| Unresolved blocking conflicts | 0 | 0 | **0** | **0** | **0** | **0** |
| Commercial decisions **changed** by the amendment | 0 (A1) | 0 (A2) | 0 removed or weakened (A3–A5 **added** 29 `LOCKED`, 1 `PROVISIONAL`, 5 `DEFERRED`; narrowed L-41) | **0** removed, weakened, or reinterpreted (A6 added **no** `LOCKED` / `PROVISIONAL` / `DEFERRED` entry and decided **no** commercial question) | **0** removed or weakened (A7 **added 4 `LOCKED`**: `L-84`–`L-87`; **no** `PROVISIONAL` or `DEFERRED` entry added; **no** existing decision removed, weakened, or reinterpreted) | **0** removed or weakened (A8 **added 10 `LOCKED`**: `L-88`–`L-97`, plus 2 `PROVISIONAL`, 1 `DEFERRED`, 7 standing prohibitions; **no** existing decision removed, weakened, or reinterpreted; **no price changed**; **closed 0** Open Questions; **narrowed 3**) |

Counts are informational. The tables in §25.1–§25.3 and §24.3.1–§24.3.6 are the
authority. A1 and A2 changed **no** `LOCKED`, `PROVISIONAL`, or `DEFERRED`
decision. A3–A5 **added** decisions and **closed** registered Open Questions; they
removed, weakened, or silently reinterpreted **no** existing decision. **A6
changed no `L-nn`, `P-nn`, or `DEFERRED` registry entry**; it added no `L-nn`,
no `P-nn`, and no `DEFERRED` item, so the `LOCKED` **83**, `PROVISIONAL` **34**,
and `DEFERRED` **19** figures are unchanged by A6. **A8 added only**: it removed,
weakened, or reinterpreted **no** existing entry, changed **no** price in §3.2,
§5.7, or §6.2, closed **0** registered Open Questions, narrowed **3**, and created
**no** permanent free commercial tier.

**Registry-count verification (recomputed by direct row count after A8).**
`LOCKED` 54 + 29 + 4 + 10 = **97** (A3–A5 added L-55…L-83; A7 added L-84…L-87;
A8 added L-88…L-97); `PROVISIONAL` 33 + 1 + 2 = **36** (A5 added P-34; A8 added
P-35, P-36); `DEFERRED` 14 + 5 + 1 = **20** (A5 added D-15…D-19; A8 added D-34).
Dependency records in §24.2 are **14** after A8 (`D-20`…`D-33`). Open-Question
arithmetic: **48 open + 36 closed = 84 registered IDs**, and
48 = 0 `CRITICAL` + 1 `HIGH` + 40 `MEDIUM` + 7 `LOW`; and
48 = 0 `MUST RESOLVE BEFORE FREEZE` + 27 `REGISTER BEFORE FREEZE` +
4 `BUSINESS CENTER` + 10 `IMPLEMENTATION ARCHITECTURE` + 2 `DEFERRED` +
5 `LEGAL/POLICY REVIEW`. (The 84 total includes `OQ-78` registered by A6,
`OQ-79` registered by A7, and `OQ-80`…`OQ-84` registered by A8. The pre-A8
figures were **79** registered / **43** open / **36** closed, with **1** `HIGH`,
**0** `MUST RESOLVE BEFORE FREEZE`, **22** `REGISTER BEFORE FREEZE`, and **4**
`LEGAL/POLICY REVIEW`; after A8 they are **84** / **48** / **36`, with the same
**1** `HIGH` and the same **0** `MUST RESOLVE BEFORE FREEZE`, **22→27**
`REGISTER BEFORE FREEZE`, and **4→5** `LEGAL/POLICY REVIEW`. A8 changed no
`CRITICAL`, `MEDIUM`, `LOW`, `BUSINESS CENTER`, `DEFERRED`, or
`IMPLEMENTATION ARCHITECTURE` classification.)

**A8 freeze-gate statement (historical; superseded by the 2026-10-01 freeze).**
`MUST RESOLVE BEFORE FREEZE` is **0** and was already
**0** before A8. **That is not a freeze declaration.** §1.6 items 8 and 9 still
require a **fresh independent Freeze Readiness Audit over the A8-inclusive
document**, **Architect acceptance**, and then an **explicit Document Owner freeze
declaration** per §1.5. **None has occurred.** A8 intentionally reopened the
pre-freeze commercial record after the previous Final Freeze Readiness Audit had
found it commercially complete; that audit is **`VALID FOR THE PRE-A8 STATE` ONLY**
and is no longer sufficient by itself. **At that time (post-A8, pre-freeze)** the
document remained **`ACTIVE DESIGN` /
`CANONICAL COMMERCIAL SSOT` / `NOT YET FROZEN`**, `IMPLEMENTATION_AUTHORIZED`
remained **`NO`** (§32.12).

**Current status: Commercial Model V1 is `FROZEN` (2026-10-01).** The
A8 freeze-gate statement above is preserved as the pre-freeze historical record
and is **not** current status (§1.5 rule 3). The freeze basis was the **final
A8-inclusive independent Freeze Readiness Audit** + **Architect Acceptance** +
**explicit Document Owner freeze declaration**, all `SATISFIED` (§33). **See §33
for the single authoritative current freeze record.**

**Post-A7 freeze-gate statement (historical; superseded by A8 and by the
2026-10-01 freeze).**

The `MUST RESOLVE BEFORE FREEZE` figure falling from 28 to **0** is **not** a
freeze declaration. §1.6 item 8 still requires an **independent Freeze Readiness
Audit** and **Architect acceptance** before the Document Owner may consider a
freeze declaration, and **neither has occurred**. A7 closed `OQ-04`, `OQ-20`, and
`OQ-37`, so **no** `MUST RESOLVE BEFORE FREEZE` entry remains, but the document
remains **`NOT YET FROZEN`** and `IMPLEMENTATION_AUTHORIZED` remains **`NO`**
(§31.4).

**Superseded A6-era note (historical).** The pre-A7 text read: "The `MUST RESOLVE
BEFORE FREEZE` figure falling from 28 to 3 is **not** a freeze declaration …
three freeze-blocking questions remain genuinely open: `OQ-04`, `OQ-20`, `OQ-37`."
That statement was accurate as of A6 and is **superseded by A7**, which closed all
three. It is retained here as a historical record, not as current status
(§1.5 rule 3: never delete a superseded rule — mark it superseded and point to its
replacement).

**Superseded A7-era freeze note (historical).** The pre-A8 text read: "The `MUST
RESOLVE BEFORE FREEZE` figure falling from 28 to **0** is **not** a freeze
declaration … A7 closed `OQ-04`, `OQ-20`, and `OQ-37`, so **no** `MUST RESOLVE
BEFORE FREEZE` entry remains, but the document remains **`NOT YET FROZEN`** and
`IMPLEMENTATION_AUTHORIZED` remains **`NO`** (§31.4)." That statement was accurate
as of A7 and is **superseded by A8** (§1.6 item 9, §32.12), which additionally
records that the commercial design was **intentionally reopened before freeze** and
that the prior Final Freeze Readiness Audit is **`VALID FOR THE PRE-A8 STATE`
ONLY**. It is retained here as a historical record, not as current status (§1.5
rule 3). **Current status is the freeze declaration of 2026-10-01 (§33).**

---

---

## 26. AMENDMENT A3 — COMMERCIAL SPINE (added 2026-09-29)

### 26.0 Amendment governance, authority, and terminology

1. **Authority.** §26 records explicit **Document Owner** commercial decisions,
   consolidated by the ChatGPT Architect. These are decisions, not proposals, and
   not inferences from conversation history (§1.5).
2. **Non-authorization.** §26 creates **no** code, schema, table, column, enum,
   migration, RLS policy, route, screen, entitlement, backend behaviour, or
   roadmap change, and authorizes **no** implementation slice. Commercial policy
   authority remains separate from implementation authority (§1.2, L-47). The
   conceptual states in §26.4 and §26.5 are **not** database enums (§8.4, C-3).
3. **Traceability.** Each subsection cites the `OQ-nn` entries it closes in
   §24.3.6 and the `L-nn` entries it registers in §25.1.
4. **Append-only.** A3 supersedes, and never deletes, the `PROVISIONAL` Grace
   target in §8.3.7; the superseded value is marked in place.
5. **Terminology (`L-64`).** **Business Owner** is the business capability role
   (§11.1, §11.1a). **Document Owner** is the decision authority (§1.3, §1.5).
   The two are never merged and the decision authority is never inferred from the
   business role. Wherever §§26–§30 use a bare "owner" in a business context it
   means **Business Owner**; wherever they discuss authority it means **Document
   Owner**.

### 26.1 Subscription term anchor (A3-1 → L-55; closes `OQ-25`)

| # | Rule | Status |
|---|---|---|
| 26.1.1 | **Payment Verification Time** and **Subscription Term Start** are **distinct commercial concepts**. These are **conceptual labels, not persistence field names, column names, or an authorized schema**. | `LOCKED` |
| 26.1.2 | The paid subscription term **normally starts on the first successful public publication** of the Business Profile. | `LOCKED` |
| 26.1.3 | Payment verification alone does **not** normally consume subscription days. | `LOCKED` |
| 26.1.4 | After **Payment Verified**, the customer receives **14 calendar days** to provide the information/material required for publication. | `LOCKED` |
| 26.1.5 | If publication is delayed by Civilpedia, the subscription does **not** start until actual successful publication. | `LOCKED` |
| 26.1.6 | If publication remains blocked after the 14-day activation window **solely** because the customer failed to provide required materials **despite documented requests**, the term starts on **calendar day 15**. | `LOCKED` |
| 26.1.7 | **End date = start date + purchased duration.** | `LOCKED` |
| 26.1.8 | Grace occurs **after** paid term expiry, **not** inside the paid term. | `LOCKED` |

These are **commercial date rules**. Their persistence, field names, and
date-anchor representation remain `PROVISIONAL` (§8.4, P-30) and are not
authorized here.

### 26.2 Renewal, early renewal, and Grace (A3-2 → L-56, L-57; closes `OQ-29`; narrows `OQ-12`)

**Renewal model (Commercial V1).**

| # | Rule | Status |
|---|---|---|
| 26.2.1 | **Manual renewal only.** | `LOCKED` |
| 26.2.2 | **No automatic charge.** | `LOCKED` |
| 26.2.3 | **No stored payment instrument.** | `LOCKED` |
| 26.2.4 | **Every renewal payment is independently verified.** | `LOCKED` |
| 26.2.5 | **Early renewal** extends from the existing paid term end date; the customer never loses remaining paid days. | `LOCKED` |
| 26.2.6 | **Grace = 5 calendar days.** | `LOCKED` — supersedes the §8.3.7 `PROVISIONAL` 3–7 day target |
| 26.2.7 | The **public profile remains visible during Grace**. | `LOCKED` |
| 26.2.8 | Renewal **during Grace** preserves continuity and extends from the **previous paid expiry date**; Grace is therefore **not** extra free subscription time. | `LOCKED` |
| 26.2.9 | If Grace expires, the public Business is **hidden**. | `LOCKED` |
| 26.2.10 | A later payment after hiding is a **Reactivation**. | `LOCKED` |
| 26.2.11 | A Reactivation term starts **after** payment verification and successful republication — **never retroactively** from the old expiry date. | `LOCKED` |

**Renewal and expiry communications (L-57).** Offsets are expressed from
**T = the paid term end date**. `T-n` / `T+n` are **date offsets, not
identifiers** (the pre-A6 `D-n` spelling was retired by Amendment A6 to remove a
namespace collision with `D-nn` registry and dependency identifiers; the cadence
values are unchanged).

| Term | Cadence |
|---|---|
| Annual (12 months) | T-14, T-7, T0, Grace T+4, Hidden T+5 |
| 3 months | T-7, T0, Grace T+4, Hidden T+5 |
| Monthly (1 month) | T-3, T0, Grace T+4, Hidden T+5 |

| # | Rule | Status |
|---|---|---|
| 26.2.12 | Stop **all** renewal reminders immediately once renewal is **verified**. | `LOCKED` |
| 26.2.13 | If a renewal conversation is being handled manually, automated sales reminders may be suppressed. | `LOCKED` |
| 26.2.14 | While **Payment Pending Verification**, stop "renew now" reminders and send payment-status messaging instead. | `LOCKED` |
| 26.2.15 | Customer messages must use **exact dates**. | `LOCKED` |
| 26.2.16 | **One optional** win-back/reactivation communication may occur later; it is **not** part of the core renewal sequence. | `LOCKED` |

**Notification channels.**

| Channel | Role | Status |
|---|---|---|
| In-app Business Center banner / state | **Primary persistent status** | `LOCKED` |
| Firebase Cloud Messaging (FCM) push | **Primary automated reminder channel** | `LOCKED` |
| WhatsApp Business — manual messages | Important renewal / expiry / hiding touchpoints during initial commercial scale | `LOCKED` |
| WhatsApp Business Platform / API — automated | Deferred until scale justifies its cost and operational complexity | `DEFERRED` (D-16) |
| Consent, template, and platform requirements | All WhatsApp communication must follow applicable consent/template/platform requirements. | `LOCKED` |

Cadence, channel, and mechanism implementation remain `PROVISIONAL` (§8.4, P-29,
P-30). Customer-facing language is Arabic (§28.14).

### 26.3 Price changes and grandfathering (A3-3 → L-58; closes `OQ-28`, `OQ-05`, `OQ-66`)

| # | Rule | Status |
|---|---|---|
| 26.3.1 | A price change **never** changes an already-paid unexpired term. | `LOCKED` |
| 26.3.2 | **No retroactive price increase** and **no collection of a price difference**. | `LOCKED` |
| 26.3.3 | The **new official price applies on future renewal** after its effective date. | `LOCKED` |
| 26.3.4 | **Price decreases** also apply at future renewal. | `LOCKED` |
| 26.3.5 | Minimum price-change **notice target = 30 days**. | `LOCKED` |
| 26.3.6 | Founding Partner **badge/history may remain**, but the first-year discounted pricing is **not** a permanent lifetime price. | `LOCKED` |
| 26.3.7 | **No lifetime grandfathering** unless explicitly granted in a written Civilpedia commercial offer. | `LOCKED` |
| 26.3.8 | Promotions/contracts may define **their own explicit terms**. | `LOCKED` |
| 26.3.9 | **Renewal pricing:** renewal takes the official price effective on the renewal date unless an explicit promotion applies. Renewal carries no separate price rule. | `LOCKED` — closes `OQ-05` |
| 26.3.10 | **Founding Partner cohorts:** Founding Partner is the **initial first-50 cohort**. No later cohort is promised or implied; a later cohort requires a new explicit Document Owner commercial decision. | `LOCKED` — closes `OQ-66` (`DEFERRED`, D-18) |

No price in §3.2 or §5.7 is changed by A3.

### 26.4 Suspension and termination (A3-4 → L-59, L-60; closes `OQ-30`; registers `OQ-71`)

**Separation rule (`LOCKED`).** Suspension and Termination are **distinct from
Expired**. Expiry is a commercial non-renewal outcome; Suspension and Termination
are enforcement outcomes.

| Situation | Rule | Status |
|---|---|---|
| Non-serious correctable violation | Warning/correction required; **correction window = 7 calendar days**. | `LOCKED` |
| Serious violation | Civilpedia may **immediately suspend** where required for platform/user protection. | `LOCKED` |

**During Suspension (L-59).**

| # | Rule | Status |
|---|---|---|
| 26.4.1 | Public profile is **hidden**. | `LOCKED` |
| 26.4.2 | The Business Owner **retains Business Center access**, unless security/fraud circumstances require otherwise. | `LOCKED` |
| 26.4.3 | Sponsored becomes **inactive / suppressed**. | `LOCKED` |
| 26.4.4 | Relevant restricted actions may be blocked. | `LOCKED` |
| 26.4.5 | Data is **not automatically deleted**. | `LOCKED` |
| 26.4.6 | A **customer-caused** suspension does **not** pause subscription time. | `LOCKED` |
| 26.4.7 | Where suspension is determined to be **Civilpedia error**, equivalent service time is restored as **service credit / term extension**. | `LOCKED` |

**Termination (L-60).**

| Aspect | Rule | Status |
|---|---|---|
| Grounds | Material fraud, forged evidence, impersonation, serious or repeated violation, or persistent failure to cure material violations. | `LOCKED` |
| Discovery | Public profile removed from discovery. | `LOCKED` |
| Sponsored | Sponsored stops. | `LOCKED` |
| Verification | Verification becomes inactive. | `LOCKED` |
| Refund | **No automatic refund** for customer-caused termination. Civilpedia-caused service failure may receive proportional refund or service credit per the future refund policy (§28.2, §30). | `LOCKED` |
| Appeal | **One** appeal may be filed **within 7 days**. | `LOCKED` |
| Appeal effect | Serious-risk content may remain **hidden during the appeal**. | `LOCKED` |

**Residual registered by A3-4:** whether an ownership transfer may be initiated or
completed while the Business Entity is Expired, Suspended, Terminated, or
Permanently Closed — `OQ-71`. A3 did **not** decide it.

### 26.5 Permanent business closure (A3-5 → L-61; closes `OQ-36`; narrows `OQ-68`, `OQ-19`, `OQ-54`)

**Separation rule (`LOCKED`).** Permanent closure is **distinct from Expired**.

| # | Rule | Status |
|---|---|---|
| 26.5.1 | Operational closure concept: **Operating → Closure Requested → Permanently Closed**. | `LOCKED` |
| 26.5.2 | After confirmed permanent closure the Business is removed from **discovery**. | `LOCKED` |
| 26.5.3 | **Sponsored stops.** | `LOCKED` |
| 26.5.4 | Active **verification becomes inactive**. | `LOCKED` |
| 26.5.5 | Affected **branches are closed appropriately**. | `LOCKED` |
| 26.5.6 | Private business/history records are **retained** according to the retention policy (§28.8, §30). | `LOCKED` |
| 26.5.7 | The Business Entity is **not automatically deleted**. | `LOCKED` |
| 26.5.8 | **No automatic refund** merely because the customer voluntarily closed the business. | `LOCKED` |
| 26.5.9 | A **direct historic link** must communicate that the business is **no longer active** rather than presenting misleading active business information. | `LOCKED` — narrows `OQ-68` |
| 26.5.10 | **Reopening:** the same genuine Business Entity may reopen after appropriate re-verification. | `LOCKED` |
| 26.5.11 | Materially different ownership/legal entity routes to **ownership-transfer / new-entity** rules (§26.7). | `LOCKED` |
| 26.5.12 | Historical **Founding Partner** status may remain historical but must **not** imply that a closed business is currently active. | `LOCKED` |

A3 did not decide the exact closure-request workflow, who may declare closure, or
the branch-closure mechanics; those remain `OQ-19` / `OQ-54` and Business Center
design.

### 26.6 Duplicates (A3-6 → L-62; closes `OQ-32`; registers `OQ-72`)

| # | Rule | Status |
|---|---|---|
| 26.6.1 | One real operating Business Entity must **not** have duplicate commercial profiles. | `LOCKED` |
| 26.6.2 | **Verified duplicates may be merged or retired under Civilpedia control.** | `LOCKED` |
| 26.6.3 | **Deliberate** duplicate creation to manipulate visibility, promotions, Sponsored inventory, or commercial rules may trigger **enforcement**. | `LOCKED` |

Detection basis and merge/retirement mechanics are implementation work — `OQ-72`.

### 26.7 Business sale and ownership transfer (A3-7 → L-63; closes `OQ-39`; registers `OQ-71`)

| # | Rule | Status |
|---|---|---|
| 26.7.1 | The subscription belongs to the **Business Entity**, not a user account (reinforces L-03). | `LOCKED` |
| 26.7.2 | Ownership transfer does **not** happen merely by sharing login credentials. | `LOCKED` |
| 26.7.3 | A **formal ownership-transfer workflow is required** (reinforces L-31). | `LOCKED` |
| 26.7.4 | Where the **same genuine Business Entity** continues after a legitimate transfer **and Civilpedia verifies the transfer**, remaining subscription value **may remain** with that Business Entity. | `LOCKED` |
| 26.7.5 | A **materially new entity / business identity requires new-entity assessment.** | `LOCKED` |
| 26.7.6 | **Verification evidence must be refreshed** where ownership-sensitive information changed. | `LOCKED` |

A3 did not decide the transfer request/accept UI, timeouts, evidence handling, or
what happens to other memberships; those remain `PROVISIONAL` (§11.3, P-08).
The **disposition of non-owner memberships on transfer** is registered separately
as `OQ-78` and **remains `OPEN`** — A7 did not decide or close it. `OQ-20`
concerned the number of owners, co-ownership, and the state of an entity without
an owner; it is now **`CLOSED` by A7-2** (§31.2 → L-86), which locks exactly one
**Primary Business Owner** in normal operation plus optional verified
**Co-Owners**, and introduces the conceptual **OWNERSHIP RECOVERY PENDING** state.
The controlled ownership-transfer workflow locked by L-63 is **unchanged** by A7.
Ownership-transfer while the entity is not Active remains `OQ-71` (**`OPEN`**),
and ownership-dispute/deceased-owner/quorum evidence requirements remain
`OQ-79` (**`OPEN`**).

END OF A3 RECORD

---

## 27. AMENDMENT A4 — ELIGIBILITY AND CLAIMING BOUNDARY (added 2026-09-29)

### 27.0 Amendment governance

Authority, non-authorization, traceability, and terminology rules in §26.0 apply
in full to §27. A4 changes **no** price, plan, or entitlement value.

### 27.1 Category eligibility (A4-8 → L-65; closes `OQ-26`)

| # | Rule | Status |
|---|---|---|
| 27.1.1 | The Business commercial plan is for **commercial organisations**: companies, contractors, suppliers, stores, manufacturers, equipment providers/rental businesses, and other commercial or service businesses appropriate to the Business model. | `LOCKED` |
| 27.1.2 | **Individual professionals must not be silently placed into this model** — individual structural designers, architects, electrical/mechanical/MEP professionals, surveyors, individual consultants, and similar. | `LOCKED` |
| 27.1.3 | Engineering offices, consulting organisations, laboratories, and specialist engineering organisations remain reserved for **separate research/model decisions** and must **not** be silently treated as identical to ordinary Business plans. | `LOCKED` |
| 27.1.4 | The **Professional Marketplace** and **Engineering Organisation** commercial models remain **separate and `DEFERRED`** (§23). | `LOCKED` |

A "Business Account" is the owned commercial profile (§11.1a); it is **not** a
personal account. The **account owner is not automatically a technically verified
professional**; account creation alone conveys no professional validation.

### 27.2 Claiming boundary and the account-before-publication sequence (A4-9 → L-66; closes `OQ-27`, `OQ-21`)

| # | Rule | Status |
|---|---|---|
| 27.2.1 | Commercial V1 has **no** open public "Claim this business" workflow. | `LOCKED` |
| 27.2.2 | Civilpedia creates/onboards the Business Draft through the **controlled commercial onboarding** process. | `LOCKED` |
| 27.2.3 | The Business Owner **creates their own** Civilpedia account. | `LOCKED` |
| 27.2.4 | Civilpedia **links/invites the verified owner** to the Business. | `LOCKED` |
| 27.2.5 | Civilpedia **never creates and hands over a customer password**. | `LOCKED` |
| 27.2.6 | The owner creates their own account and **accepts Business ownership** before Content review and Published — the already-`LOCKED` §10.1 sequence, a consequence of that sequence and not a new decision. | `LOCKED` |
| 27.2.7 | Open claiming and competing claims are **`DEFERRED`** until a dedicated evidence/dispute model exists. | `LOCKED` |
| 27.2.8 | One account may hold a Business Profile **only for a genuinely different real entity**; duplicate or near-duplicate profiles created for search visibility, promotional manipulation, or ranking manipulation are prohibited — reinforces A3-6 (§26.6). | `LOCKED` |

A4 resolved the **claiming risk and the duplicate-creation risk**, not the
**duplicate-detection mechanism** — `OQ-72`.

### 27.3 Production paid-only (A4-9 → L-67; `OQ-21` is **CLOSED** by §27.2 and is **not** narrowed here)

| # | Rule | Status |
|---|---|---|
| 27.3.1 | Mock, dev, test, and seed entities do **not** become entitled production commercial listings merely because they exist in data. | `LOCKED` |
| 27.3.2 | Production publication requires the canonical commercial **onboarding, payment, and publication** rules. | `LOCKED` |

END OF A4 RECORD

---

## 28. AMENDMENT A5 — COMMERCIAL TERMS, TRUST, PAYMENT, AND SPONSORED (added 2026-09-29)

### 28.0 Amendment governance

Authority, non-authorization, traceability, and terminology rules in §26.0 apply
in full to §28. A5 changes **no** price value in §3.2 or §5.7. A5 does **not** set
a legal basis — this document is a commercial product decision document, not a
legal contract or legal compliance manual (§29.5), and legal drafting itself
remains `DEFERRED` (D-19). A5 does **not** decide refund quantum or processing
timelines (§30.1.2, D-19), the proration formula (P-34, §28.2.6), or retention
periods (`OQ-40`). A5 **drafts no legal text** (§30).

### 28.1 Payment exceptions, verification authority, and currency (A5-10 → L-68, L-69, L-70, L-71; closes `OQ-31`, `OQ-11`, `OQ-62`; narrows `OQ-09`, `OQ-10`, `OQ-23`)

**Payment exception outcomes (`L-68`, `LOCKED`).** A subscription is **never**
activated on the basis of an uploaded receipt or screenshot alone (§7.2.1).

| Situation | Recorded outcome | Status |
|---|---|---|
| Underpayment / short payment | **No activation** until the required amount is satisfied, or an explicitly approved commercial adjustment exists. | `LOCKED` |
| Overpayment | The difference is **refunded or recorded as explicit customer credit** after verification, and is **never silently retained**. | `LOCKED` |
| Unclear evidence | **Needs Clarification** — remains unverified. | `LOCKED` |
| Duplicate transfer / duplicate claim of one transfer | **Refund or explicit credit** after reconciliation. | `LOCKED` |
| Third-party payer | May be **accepted after explicit linkage** to the intended Business/payment, and does **not** establish Business ownership. | `LOCKED` |
| Payment to an incorrect/unapproved destination | Rejected as payment; the customer is instructed to use an approved destination, and the §30 financial-recordkeeping obligations apply. | `LOCKED` |
| Payment received after Grace expiry | Treated as **Reactivation** (§26.2.10–§26.2.11), never as retroactive term restoration. | `LOCKED` |
| Payment for a closed / suspended / invalid Business | Not activated; handled under §26.5 / §26.4. | `LOCKED` |
| Suspected fraudulent or forged proof | **Rejected** and routed to enforcement / fraud review. | `LOCKED` |

The 10th step of the §7.1 flow is reached only from a `Payment Verified` state and
is **never a bypass** (§8.2).

**Payment verification authority (`L-69`, `LOCKED`).** Only explicitly authorized
Civilpedia **finance/admin authority** may mark a payment Verified, refunded, or
credited. Where operational scale permits, **sales request creation is separated
from final payment verification**.

**Payment verification service target (`L-71`, `LOCKED`).** Target customer-facing
verification within **one business day** after clear evidence/funds are available,
aiming for same-day completion where operationally possible. This is a **service
target, not a guaranteed bank settlement promise**.

**Currency and payment rails (`L-70`, `LOCKED`).** Commercial V1 canonical pricing
and accounting currency is **IQD**. Payment must use **Civilpedia-approved payment
destinations/rails**, and future electronic-payment integration must use
appropriately authorized/regulated providers. No unsupported assumptions may be
made about tax-invoice law or payment-provider legal obligations. The **specific**
approved destinations, bank accounts, and settlement accounts remain `OPEN` —
`OQ-09` (routed to Iraqi e-payment/regulatory review, D-22), and the concrete
anti-fraud control mechanisms remain `OQ-10` implementation. (`OQ-62` payment
verification turnaround was **CLOSED** by A5-10 above and is **not** an open
implementation matter.)

### 28.2 Cancellation, refunds, and plan changes (A5-11 → L-72; closes `OQ-07`, `OQ-06`; registers `P-34`)

| # | Rule | Status |
|---|---|---|
| 28.2.1 | Voluntary cancellation normally takes effect at the **end of the already-paid period**. | `LOCKED` |
| 28.2.2 | Service continues through the paid end date **unless immediate removal is requested or required**. | `LOCKED` |
| 28.2.3 | There is **no automatic prorated refund** merely because the customer stops using the service. | `LOCKED` |
| 28.2.4 | Refund or credit is appropriate where **validated**: duplicate payment, verified overpayment, material Civilpedia failure to provide the purchased service, and other mandatory legal/customer rights. | `LOCKED` |
| 28.2.5 | **Upgrade** may take effect **immediately**, charging only the appropriate **prorated difference** for the remaining paid service period, using a **simple auditable Civilpedia proration method**. | `LOCKED` |
| 28.2.6 | The **exact proration formula is out of Commercial V1 scope** and is registered as a `PROVISIONAL` architecture/finance design value — `P-34` (§25.2). | `DEFERRED` (P-34) |
| 28.2.7 | **Downgrade** normally takes effect at the **next renewal**, with no retroactive removal of already-paid term value unless explicitly requested and commercially agreed. | `LOCKED` |
| 28.2.8 | Branch counts above a tier's included count are governed by the existing **Extra Branch add-on** model (§4.2), not by a downgrade rule. | `LOCKED` |

A5 did **not** decide refund quantum or processing timelines (§30.1.2, D-19), and did
**not** decide the "no-show" concept, which is subsumed by §28.2.3.

### 28.3 Sponsored rules (A5-12 → L-73, D-15; closes `OQ-33`, `OQ-34`, `OQ-53`, `OQ-18`; registers `OQ-73`)

**Separation (`L-73`, `LOCKED`).** Sponsored is **separate from subscription** and
**never equals Verified**.

| # | Rule | Status |
|---|---|---|
| 28.3.1 | Eligibility requires an **eligible active plan** where §6.1.8 requires Pro/Plus, **publishability**, **profile-quality compliance**, and advertising content **related to the actual Business**. | `LOCKED` |
| 28.3.2 | Sponsored does **not** require a Verified state. | `LOCKED` — closes `OQ-34` |
| 28.3.3 | Every Sponsored surface must be **clearly and consistently identified as paid advertising**. | `LOCKED` |
| 28.3.4 | Sponsored must **never masquerade as organic ranking**; organic ranking remains commercially independent. | `LOCKED` |
| 28.3.5 | Sponsored is **not** an `ADVERTISEMENT` entry and creates no `ADVERTISEMENT` rights; it is a separate product from subscription, verification, and organic ranking (L-16, L-18, L-19). | `LOCKED` |
| 28.3.6 | Campaign lifecycle concept: **Scheduled / Active / Ended / Cancelled-Withdrawn**. | `LOCKED` — closes `OQ-33` |
| 28.3.7 | Sponsored paid time begins when the placement **actually becomes available/public**, not merely when money is received. | `LOCKED` |
| 28.3.8 | **Civilpedia-caused** non-delivery restores equivalent placement time or appropriate commercial credit/refund. | `LOCKED` |
| 28.3.9 | **Customer-caused** suppression or suspension does **not** automatically pause Sponsored time unless Civilpedia explicitly approves otherwise. | `LOCKED` |

**Prohibited advertisers and content (`L-73`, `LOCKED`).** False affiliation; fake
certification; deceptive discount; a misleading superlative presented as fact;
impersonation; illegal/prohibited content; and unsupported authorized-dealer or
official-agent claims.

**Entity vs branch (`L-73`, D-15, `LOCKED`).** The initial Sponsored product
attaches to the **Business Entity**. A separate **branch-level Sponsored product is
`DEFERRED` for V1** — closes `OQ-53`.

**Inventory (`L-73`, `LOCKED`).** Sponsored inventory is **finite** per
Category × Area. Civilpedia **does not oversell** unavailable slots, and
**waitlisting is preferable to selling non-existent inventory**. Whether 2–3 is a
hard cap, soft target, or queue, the definition of "Area", and the rotation /
queue / fairness mechanics remain `PROVISIONAL` (P-06) and are registered as
`OQ-73` — closes `OQ-18` only on the finite-inventory principle.

### 28.4 Verification meaning, validity, and authority (A5-13 → L-74; closes `OQ-35`, `OQ-50`; narrows `OQ-13`, `OQ-14`, `OQ-52`, `OQ-56`; registers `OQ-74`)

**Meaning (`L-74`, `LOCKED`).** **PAID ≠ VERIFIED ≠ SPONSORED.** Verified means
Civilpedia has checked **defined identity/business information** using accepted
evidence. It does **not** mean that Civilpedia recommends the business, guarantees
quality, guarantees workmanship, guarantees a commercial outcome, or guarantees
any claim made by the business.

**Validity (`L-74`, `LOCKED`).**

| # | Rule | Status |
|---|---|---|
| 28.4.1 | There is **no** automatic fixed 12-month expiry solely because time passed. | `LOCKED` |
| 28.4.2 | Re-verification is triggered by **material sensitive changes, risk signals, suspected fraud, ownership changes, identity/location changes, or Civilpedia review requirements**. | `LOCKED` |
| 28.4.3 | **Subscription renewal alone does not automatically equal verification renewal.** | `LOCKED` |
| 28.4.4 | Verification becomes **inactive** on suspension, termination, or permanent closure (§26.4, §26.5). | `LOCKED` |

**Evidence constraint (`L-74`, `LOCKED`).** Evidence may include **only what is
reasonably necessary** — e.g. official business/registration evidence where
applicable, authorized owner/representative identity evidence, control of the
official contact channel, relevant location evidence, and optional additional
evidence or field verification **where justified**. The full evidence set and the
per-category checklists remain with the deferred verification policy (`OQ-13`,
`OQ-56`).

**Authority (`L-74`, `LOCKED`).** Only **authorized Civilpedia staff/authority**
may grant or withdraw Verified, and there is **no self-verification**. The
verification **workflow, checklist, turnaround implementation, and appeal
procedure** remain `DEFERRED` (`OQ-13`, D-10).

**False evidence (`L-74`, `LOCKED`).** False or forged evidence may cause
**immediate suspension, verification withdrawal, and enforcement**, consistent with
the suspension and termination grounds in §26.4.

**Review service targets (`LOCKED` as internal expectations, not guarantees).**
Sensitive-content review ≤ **2 business days**; verification and appeal up to
**5 business days** where practicable. Reviewer roles, rejection messaging, and
audit/rollback remain `OQ-52` (narrowed).

**Residual registered by A5-13.** Whether a Verified state may act at all as an
**organic ranking input** — `OQ-74`. It must never become a purchasable or
paid-adjacent signal (L-19, L-42, §18.2 rule 3).

### 28.5 Content, offers, and brand claims (A5-14 → L-75; closes `OQ-43`, `OQ-45`; narrows `OQ-44`; registers `OQ-75`)

**Offers and price accuracy (`L-75`, `LOCKED`).**

| # | Rule | Status |
|---|---|---|
| 28.5.1 | Every **time-limited offer** must carry **validity / start–end information**. | `LOCKED` |
| 28.5.2 | **Expired offers** cease public promotion. | `LOCKED` |
| 28.5.3 | The **business is responsible** for commercial price/offer accuracy. | `LOCKED` |
| 28.5.4 | Civilpedia may **remove stale or deceptive content**. | `LOCKED` |

**Brand claims (`L-75`, `LOCKED`).** "Sells / products from Brand X" is **not**
equivalent to "Authorized Dealer / Official Agent / Exclusive Distributor". Claims
of an official or authorized relationship **require appropriate evidence**, and
unsupported official-affiliation claims are **prohibited**. This closes the
evidence question of `OQ-44`; **Brand-concept governance remains `OPEN`** — `OQ-44`.

**Prohibited claims generally (`L-75`, `LOCKED`).** Fake certificates; false
affiliations; deceptive discounts; fabricated achievements; impersonation; and
materially misleading content — any of which may trigger takedown/enforcement.
This closes `OQ-45` for prohibited claims; **uploaded-media rights declaration,
takedown, and repeat infringement remain `OPEN`** — `OQ-75`.

### 28.6 Publication Required Fields Gate (A5-15 → L-76; closes `OQ-47`; narrows `OQ-16`, `OQ-48`; registers `OQ-76`)

| # | Rule | Status |
|---|---|---|
| 28.6.1 | Publication requires a **Required Fields Gate**, **not** an arbitrary public numerical quality score. | `LOCKED` |
| 28.6.2 | At minimum the profile must contain: appropriate **identity/name**, **category**, **area/location or service area**, a usable **contact method**, a meaningful **description**, appropriate **identity/cover/logo media**, and minimum **category-relevant service/product/content**. | `LOCKED` |
| 28.6.3 | An **incomplete profile remains Draft / not publishable** until the gate is met. | `LOCKED` |
| 28.6.4 | The **exact per-category field matrix and UX** remain Business Center / design work — `OQ-76`. | `PROVISIONAL` |
| 28.6.5 | A5-15 decides the **pre-publication** case only; the consequence of **falling below the gate after publication** remains `OQ-48`. | `PROVISIONAL` |
| 28.6.6 | A5-15 **fixes no media count**; storage and per-category media limits remain `OQ-16`. | `PROVISIONAL` |

### 28.7 Analytics honesty and "Lead" (A5-16 → L-77; closes `OQ-38`; narrows `OQ-17`, L-41)

| # | Rule | Status |
|---|---|---|
| 28.7.1 | Civilpedia must **never** call profile views or generic taps **confirmed customers or sales**. | `LOCKED` |
| 28.7.2 | **Exact metric names are preferred** — Profile Views, WhatsApp Clicks, Call Clicks, Directions Clicks, Offer Views, Saves, Search Appearances, and similar. | `LOCKED` |
| 28.7.3 | **"Lead" may be used only** where a defined intentional contact/action qualifies under an **explicit measurement rule**. | `LOCKED` |
| 28.7.4 | **No analytics metric implies a completed sale.** | `LOCKED` |
| 28.7.5 | The approved framing vocabulary is `Interactions`, `Engagement`, and `Leads` **only** under the §28.7.3 rule. | `LOCKED` — narrows L-41 |
| 28.7.6 | Retention, aggregation/reset, unique vs total counting, bot filtering, self-view exclusion, export, and post-expiry visibility remain `OQ-17`. | `PROVISIONAL` |

Civilpedia measures **internal platform usage behavior**; it never measures or
implies external real-world web traffic (see §17.3, `OQ-55`).

### 28.8 Records and privacy boundary (A5-17 → L-78; narrows `OQ-40`, `OQ-59`)

| # | Rule | Status |
|---|---|---|
| 28.8.1 | Payment receipts, verification evidence, staff notes, and sensitive ownership/payment information are **private**. | `LOCKED` |
| 28.8.2 | The public profile must **never** expose payment receipts, internal verification notes, payment identifiers, plan/payment admin data, sensitive identity evidence, or internal fraud/risk notes. | `LOCKED` |
| 28.8.3 | The Business Owner **may** see appropriate customer-facing transaction/status information, but **not** internal antifraud/staff notes. | `LOCKED` |
| 28.8.4 | The canonical `CP-BIZ` / `CP-PAY` reference format is **never public** (narrows `OQ-15`). | `LOCKED` |
| 28.8.5 | Exact **statutory retention/deletion periods are not invented here** and require qualified Iraqi legal/accounting/privacy review. | `DEFERRED` (`OQ-40`, D-20, D-19) |

`OQ-40` is narrowed to the retention/deletion periods and remains `LEGAL/POLICY
REVIEW`; `OQ-59` (branch-manager personal data) is narrowed to whether a branch
manager's personal contact details may be published on a branch page and also
requires legal/policy review before any rule is published.

### 28.9 Numbering note

No A5 decision maps to §28.9. **A5-18** — adoption of the Legal/Policy Obligations
Register (`L-79`) — is recorded in **§30**, not in §28. This subsection exists
solely to keep the §28.x numbering stable and gap-free, because the amendment
sequence is A5-10 → §28.1, A5-11 → §28.2, A5-12 → §28.3, A5-13 → §28.4,
A5-14 → §28.5, A5-15 → §28.6, A5-16 → §28.7, A5-17 → §28.8, **A5-18 → §30**,
A5-19 → §28.10, A5-20 → §28.11, A5-21 → §28.12, A5-22 → §28.13, and language
(Arabic-first) → §28.14. **No decision is recorded, removed, or hidden by this
note.**

### 28.10 Business Center commercial inputs (A5-19 → L-80; closes `OQ-58`; registers `OQ-77`)

The expected future Business Center commercial capabilities are **enumerated as a
requirement**, not as a design:

| # | Capability | Status |
|---|---|---|
| 28.10.1 | Subscription status and renewal / expiry / Grace state. | `LOCKED` as required capability |
| 28.10.2 | Payment status. | `LOCKED` as required capability |
| 28.10.3 | Verification status. | `LOCKED` as required capability |
| 28.10.4 | Support / contact. | `LOCKED` as required capability |
| 28.10.5 | Evidence upload where allowed (§28.4). | `LOCKED` as required capability |
| 28.10.6 | Team. | `LOCKED` as required capability |
| 28.10.7 | Business switching for users managing multiple Businesses. | `LOCKED` as required capability |
| 28.10.8 | profile / media / products / services / projects / offers / branches. | `LOCKED` as required capability |
| 28.10.9 | Analytics according to entitlement (§28.7). | `LOCKED` as required capability |
| 28.10.10 | Subscription / renewal surfaces. | `LOCKED` as required capability |
| 28.10.11 | Exact **UX, routes, schema, and RBAC** remain separate architecture/design work. | `PROVISIONAL` — `OQ-77`, D-21 |

This closes `OQ-58` on **module completeness** only; it does **not** design or
authorize the Business Center.

### 28.11 Team and financial visibility (A5-20 → L-81; closes `OQ-46`; **partially scoped** `OQ-20`, which A7-2 has now `CLOSED` in §31.2)

| # | Rule | Status |
|---|---|---|
| 28.11.1 | The operational **default ceiling is 5 active team members** for ordinary Business plans. | `LOCKED` |
| 28.11.2 | **Corporate** may have **custom team requirements**. | `LOCKED` |
| 28.11.3 | Team count is **not** positioned as the primary pricing value proposition. | `LOCKED` |
| 28.11.4 | Financial/subscription information is visible only to the **Business Owner** and **explicitly finance-authorized roles**. | `LOCKED` |
| 28.11.5 | Exact **RBAC and storage mapping** remain deferred architecture work. | `DEFERRED` (P-25, D-28) |

A5-20 sets a team ceiling but **does not decide the number of Business Owners**.
**A7-2 (§31.2 → L-86) now decides it and `OQ-20` is `CLOSED`:** exactly one
**Primary Business Owner** in normal operation, plus optional verified
**Co-Owners** subject to the team ceiling above, with the conceptual
**OWNERSHIP RECOVERY PENDING** state covering an unavailable Primary Owner.

### 28.12 Quotations and instalments (A5-21 → L-82; closes `OQ-60`; **partially narrowed** `OQ-04` by A5, which A7-1 has now `CLOSED` in §31.1)

| # | Rule | Status |
|---|---|---|
| 28.12.1 | **Business, Business Pro, and Business Plus are prepaid** — there is **no** deferred debt or instalment structure in ordinary V1. | `LOCKED` |
| 28.12.2 | **Corporate may use individually approved written terms.** | `LOCKED` |
| 28.12.3 | The Corporate **quotation default validity is 30 calendar days** unless the quotation explicitly states otherwise. | `LOCKED` |
| 28.12.4 | Corporate plan contents, minimum commitment, and the quotation process. | **Decided by A7-1** (§31.1 → L-84, L-85) — `OQ-04` **CLOSED**. A7 sets **no** numeric included branch count, so `P-02` stays `PROVISIONAL` and included branch count is a per-quotation commercial variable. |

### 28.13 Pricing experiments and commercial measurement (A5-22 → L-83; closes `OQ-61`; narrows `OQ-42`)

| # | Rule | Status |
|---|---|---|
| 28.13.1 | Prices must **not** be **silently personalized** for equivalent customers. | `LOCKED` |
| 28.13.2 | Pricing experiments and promotions must be **explicit, time-bounded, documented commercial offers**. | `LOCKED` |
| 28.13.3 | An experiment is **not** a permanent pricing change and does **not** modify an `L-nn` registry decision. | `LOCKED` |
| 28.13.4 | Official **base** price changes follow the price-change rule (L-58, §26.3). | `LOCKED` |
| 28.13.5 | Commercially meaningful KPIs are tracked: **paid activations, sales-to-paid conversion, renewal rate, churn, average revenue per paid Business**. | `LOCKED` |
| 28.13.6 | KPIs must be tracked **without misrepresenting interaction metrics as sales** (§28.7). | `LOCKED` |
| 28.13.7 | Whether multi-year, early-payment, or volume discounts exist, and whether any discount stacks with the Founding Partner price, remain `OQ-42`. | `PROVISIONAL` |

### 28.14 Language policy (A5 §28.14 → L-83; narrows `OQ-14`, `OQ-69`)

| # | Rule | Status |
|---|---|---|
| 28.14.1 | **Arabic is the controlling V1 customer-facing language** for commercial, payment, subscription, verification, and moderation messaging. | `LOCKED` |
| 28.14.2 | User-generated content may be in **any language**. | `LOCKED` |
| 28.14.3 | Internal staff tools may use **English**. | `LOCKED` |
| 28.14.4 | Arabic is the controlling customer-facing language **unless future legal review requires a different governing-language provision**; the governing-language clause of the future commercial agreement remains `OQ-69` (`LEGAL/POLICY REVIEW`). | `LOCKED` |

Arabic applies to **customer-facing** strings. It does **not** change the §7.4
internal-reference rule set, and it does **not** alter the language policy for
technical/scientific content, which is governed **separately** with the
ACI/Iraqi Code content pipeline (§29.8) and is outside the scope of this
document.

END OF A5 RECORD

---

## 29. IRAQI / REGULATORY CAUTION (added 2026-09-29)

Authority, non-authorization, traceability, and terminology rules in §26.0 apply
in full to §29.

| # | Statement | Status |
|---|---|---|
| 29.1 | **Global SaaS practice must not be presented as Iraqi law.** | `LOCKED` |
| 29.2 | The **Central Bank of Iraq electronic-payment regulatory framework**, including **Electronic Payment Services Regulation No. 2 of 2024**, applies to any future integrated/electronic payment provider (D-22, `OQ-09`). | `LOCKED` |
| 29.3 | Any future electronic payment integration must use **appropriately authorized and regulated providers** (§28.1, L-70). | `LOCKED` |
| 29.4 | Civilpedia has **no full-time Iraqi legal counsel** and is not represented as providing formal legal advice. | `LOCKED` |
| 29.5 | This document is a **commercial product decision document** — not a legal contract, not a final legal compliance manual, and not a substitute for a licensed Iraqi lawyer or accountant. | `LOCKED` |
| 29.6 | **No VAT, invoice, tax, statutory retention, or consumer-law requirement may be invented here.** Tax, invoice, and record-retention requirements remain subject to qualified Iraqi accounting/legal review. | `LOCKED` |
| 29.7 | References to Iraqi standards are **domain context and content-quality intent only** — never customer-facing legal or compliance advice. | `LOCKED` |
| 29.8 | Nothing here changes or interprets the design, implementation, or authority position of the ACI/Iraqi Code content pipeline, which is governed separately. | `LOCKED` |

**Out of scope for A3–A5:** a full Iraqi legal/tax/compliance/tender framework for
civil engineering works. The boundaries already recorded in **§22.1** (individuals
are not silently placed in the Business model) and **§22.2** (do not yet assume an
identical model for organisations) stand unchanged, and the **Professional
Marketplace** and **Engineering Organisation** commercial models remain
**`DEFERRED`** research models — §23, D-11, D-12.

---

## 30. LEGAL / POLICY OBLIGATIONS REGISTER (added 2026-09-29)

### 30.0 Status of this register

**Adopted by A5-18 (`L-79`).** Civilpedia maintains an explicit Legal/Policy
Obligations Register covering the **eleven areas** enumerated in §30.1.

**This register drafts no legal text.** It records that a policy obligation
**exists** and **must be maintained**; it is not a contract, a policy text, or a
statement of Iraqi law. Every area requires **qualified Iraqi legal and accounting
review** before production commercial launch (D-20, D-19, §29).

**Scope.** §30 records **no** new `L-nn` commercial decision. It is a governance
index over decisions already registered in §25.

### 30.1 The eleven registered areas

| # | Area | Related decision | Legal/Policy authority | Status |
|---|---|---|---|---|
| 30.1.1 | **Payment acceptance, approved destinations, and financial recordkeeping** | §28.1, L-70, D-22, `OQ-09` | Central Bank of Iraq electronic-payment framework, incl. Electronic Payment Services Regulation No. 2 of 2024 | `DEFERRED` — legal/accounting review required |
| 30.1.2 | **Payment exception outcomes, credits, and refunds** | §28.1, §28.2, L-68, L-72, D-19 | Civilpedia refund policy text (not drafted); mandatory legal/customer rights reserved | `DEFERRED` — legal review required |
| 30.1.3 | **Subscription cancellation and renewal terms** | §26.2, §28.2, L-56, L-72 | Civilpedia terms text (not drafted) | `DEFERRED` — legal review required |
| 30.1.4 | **Records retention, access control, and deletion** | §28.8, L-78, `OQ-40` | Applicable Iraqi privacy/retention law; periods **not invented** | `DEFERRED` — legal/accounting review required |
| 30.1.5 | **Verification evidence handling and false-evidence enforcement** | §28.4, L-74, D-10, `OQ-13` | Deferred verification policy document | `DEFERRED` — legal review required |
| 30.1.6 | **Content moderation, prohibited claims, and uploaded-media rights** | §28.5, L-75, `OQ-57`, `OQ-75` | Takedown, copyright, and repeat-infringement policy (not drafted) | `DEFERRED` — legal review required |
| 30.1.7 | **Offer validity, price accuracy, and brand/affiliation claims** | §28.5, L-75, `OQ-44` | Consumer/advertising law review of prohibited claims | `DEFERRED` — legal review required |
| 30.1.8 | **Sponsored and advertising labeling, and prohibited advertisers** | §28.3, L-73, L-18, L-19 | Advertising disclosure requirements; platform labeling rules | `DEFERRED` — legal review required |
| 30.1.9 | **Personal data of owners, representatives, and branch managers** | §14.3, §28.8, L-78, `OQ-59` | Personal-data publication rules (not decided; must not be published before review) | `DEFERRED` — legal/privacy review required |
| 30.1.10 | **Governing language of the commercial agreement** | §28.14, L-83, `OQ-69`, D-31 | Governing-language clause of the future commercial agreement | `DEFERRED` — legal review required |
| 30.1.11 | **Drafting of the Legal Terms and Privacy Policy themselves** | D-19, §29.5 | Licensed Iraqi legal counsel and accountant | `DEFERRED` — **no legal text is drafted in this document** |

### 30.2 Registration completeness rule

**Corrected by Amendment A6 (documentary).** Every `L-nn` and `P-nn` decision
referenced by §§26–§30 **must** appear in §25.1 or §25.2; every `D-nn`
**`DEFERRED` commercial item** referenced by §§26–§30 **must** appear in §25.3;
and every `D-nn` **dependency record** referenced by §§26–§30 **must** appear in
§24.2. A referenced ID missing from its canonical registry is a documentation
defect and must be repaired before any freeze consideration (§1.6 item 8).

**A6 rationale.** The pre-A6 wording required *every* `D-nn` referenced by
§§26–§30 to appear in §25.1–§25.3, but §24.2 — not §25.3 — is the canonical
dependency registry. Read literally, that rule was violated by `D-20` (Legal /
Policy Obligations Register review), `D-21` (Business Center commercial-surface
design contract), and `D-22` (Iraqi e-payment compliance route), all of which
were already correctly registered in §24.2. The A6 correction routes dependency
records to §24.2 instead of creating duplicate registry entries, so that the
§25.3 `DEFERRED` count (19) and the meaning of every identifier are unchanged.
All three of `D-20`, `D-21`, and `D-22` are now fully and correctly registered in
§24.2 and remain traceable to §30, §20, and §29 respectively.

### 30.3 Relationship to the freeze gate

The existence of §30 **does not** satisfy, reduce, or substitute for the
independent re-audit and Architect acceptance required by §1.6 item 8. All eleven
areas remain **`DEFERRED`**; none is closed by adopting this register.

---

## 31. FREEZE-BLOCKER RESOLUTIONS (added 2026-09-29, Amendment A7)

A7 is a **documentation-only Owner + Architect decision-recording pass**. It records
exactly the three supplied commercial decisions that were the only remaining
`MUST RESOLVE BEFORE FREEZE` entries, as `L-84`…`L-87`, and it records **no**
commercial decision **beyond those three** — nothing was invented, extrapolated, or
decided on the Owner's behalf. A7 changes **no** price outside the Corporate rules,
**no** plan, **no** entitlement, and **no** A3–A6 meaning. A7 authorizes **no** code,
schema, migration, RLS, route, auth, backend, contract, test, UI, or roadmap change,
and it does **not** declare the document `FROZEN`.

### 31.1 Corporate plan (A7-1 → L-84, L-85; closes `OQ-04`)

| # | Rule | Status |
|---|---|---|
| 31.1.1 | **Corporate remains a quotation-based enterprise plan.** | `LOCKED` |
| 31.1.2 | Corporate includes **ALL Business Plus entitlements** as its **minimum commercial floor**. | `LOCKED` |
| 31.1.3 | Corporate may **extend beyond Business Plus** through a written quotation / enterprise agreement. | `LOCKED` |
| 31.1.4 | Corporate commercial variables may include: included branch count; additional branch scale; team-member capacity; support/service level; managed-service scope; media/content scale; analytics/reporting requirements; and other enterprise-specific commercial services already permitted by this Commercial Model. | `LOCKED` |
| 31.1.5 | Corporate **minimum subscription commitment: 12 months.** | `LOCKED` |
| 31.1.6 | Corporate pricing is **Custom Quote**. A7 creates **no** fixed public Corporate price. | `LOCKED` |
| 31.1.7 | Corporate quotation **default validity: 30 calendar days** unless the quotation explicitly states otherwise. This **preserves** the A5-21 rule (§28.12.3, L-82) unchanged. | `LOCKED` |
| 31.1.8 | Every Corporate quotation must explicitly state at minimum: Business identity; plan = Corporate; subscription duration; total quoted price / payment terms; included branches; relevant team allowance; material included services/entitlements; any separately priced add-ons; quotation expiry date. | `LOCKED` |
| 31.1.9 | **Ordinary Business / Business Pro / Business Plus pricing remains unchanged** (§3.2, §5.7). | `LOCKED` |
| 31.1.10 | The **exact technical entitlement and storage implementation** for Corporate remains architecture work. A7 creates **no** schema and **no** backend logic. | `DEFERRED` (P-03, P-25, `OQ-77`, D-29) |

**A7-1 scope notes.** A7-1 decides the Corporate commercial **structure** and closes
`OQ-04`. It does **not** set a numeric included branch count for Corporate; that
value remains a per-quotation commercial variable and the existing registered
`P-02` entry stays `PROVISIONAL`. The A3–A5 statement that Corporate is a
quotation-based enterprise plan with custom quotation pricing (§3.1, §3.2) is
**unchanged and consistent** with A7-1.

### 31.2 Business ownership cardinality and ownership recovery (A7-2 → L-86; closes `OQ-20`)

| # | Rule | Status |
|---|---|---|
| 31.2.1 | Every Business Entity must have **exactly ONE PRIMARY BUSINESS OWNER** during normal operation. | `LOCKED` |
| 31.2.2 | A Business may also have **one or more verified Co-Owners**, subject to applicable team/member operational limits (§28.11, L-81). | `LOCKED` |
| 31.2.3 | The **Primary Business Owner** is the accountable ownership authority for high-sensitivity ownership operations, including initiating/approving controlled ownership transfer, primary ownership recovery, and other ownership-sensitive actions defined by future RBAC/security architecture. | `LOCKED` |
| 31.2.4 | A **Co-Owner does NOT automatically have equal authority** to the Primary Business Owner for sensitive ownership-transfer actions. | `LOCKED` |
| 31.2.5 | A Business Entity must **not** remain indefinitely in a normal active ownership state with **no** Primary Business Owner. | `LOCKED` |
| 31.2.6 | If the Primary Business Owner becomes unavailable, loses access, dies, resigns, or otherwise cannot fulfil the role, the Business enters the conceptual state **OWNERSHIP RECOVERY PENDING**. | `LOCKED` |
| 31.2.7 | During **OWNERSHIP RECOVERY PENDING**: Civilpedia verifies an eligible replacement Primary Business Owner; Business data and subscription remain attached to the Business Entity; ownership-sensitive actions may be restricted; and public visibility does **not** have to be automatically removed solely because recovery is pending, unless fraud/security/moderation risk requires it. | `LOCKED` |
| 31.2.8 | After Civilpedia verifies the replacement, the new Primary Business Owner is assigned through the **controlled ownership process** (§26.7, L-63). | `LOCKED` |
| 31.2.9 | **Shared passwords and account handover remain prohibited.** Each natural person uses their own Civilpedia account (§26.7.2, L-63). | `LOCKED` |
| 31.2.10 | Owner and Co-Owner are **commercial / capability concepts** (§11.1). Exact RBAC mapping remains deferred architecture work. | `DEFERRED` (P-25, D-28) |
| 31.2.11 | Exact UX, RBAC, and state persistence for OWNERSHIP RECOVERY PENDING remain architecture/policy work. | `DEFERRED` (P-25, D-28, `OQ-77`) |
| 31.2.12 | Ownership disputes, deceased-owner evidence requirements, quorum/legal-document evidence, and related edge cases remain **future ownership-policy / legal-review matters** — `OQ-79`. | `DEFERRED` (`OQ-79`) |

**A7-2 scope notes.** A7-2 decides **ownership cardinality** and closes `OQ-20`. It
does **not** close `OQ-78` (disposition of non-owner memberships on ownership
transfer) or `OQ-71` (ownership transfer while the entity is not Active); both remain
`OPEN` and `REGISTER BEFORE FREEZE`. OWNERSHIP RECOVERY PENDING is a
**conceptual** commercial state; A7 creates no enum, no state machine, and no schema.

### 31.3 Business Directory V1 launch density and sequencing (A7-3 → L-87; closes `OQ-37`)

| # | Rule | Status |
|---|---|---|
| 31.3.1 | Initial commercial launch geography is **BAGHDAD FIRST**. | `LOCKED` |
| 31.3.2 | Civilpedia does **NOT** broadly launch an obviously **sparse paid-only directory**. | `LOCKED` |
| 31.3.3 | **Category Launch Gate:** a commercial category should normally reach at least **5 ACTIVE, PAID, PUBLICLY PUBLISHABLE BUSINESSES** in the applicable Baghdad launch market before that category is opened as a normal public discovery category. | `LOCKED` |
| 31.3.4 | **Growth target:** aim for approximately **8–10 active paid Businesses per launched category** before strong/promoted marketing of that category. This is a **target, not a contractual guarantee**. | `LOCKED` |
| 31.3.5 | **Overall initial directory launch target:** approximately **30 active paid publicly publishable Businesses** across the initial launch categories before the Business Directory receives its formal commercial/public launch push. This is a **launch-readiness target, not a customer guarantee**. | `LOCKED` |
| 31.3.6 | Categories **below** the Launch Gate must not present a misleading normal category experience; they may be hidden from primary discovery/navigation, or represented by a clear **"Coming Soon / قريباً"** state where product UX chooses to expose them. | `LOCKED` |
| 31.3.7 | Below-gate categories must **NOT** be populated with fake or free production listings merely to create density. | `LOCKED` |
| 31.3.8 | The **5-Business threshold is a LAUNCH GATE, not a perpetual automatic shutdown threshold.** A category that opens with 5+ businesses is **not** automatically closed solely because one subscription later expires and the count becomes 4. | `LOCKED` |
| 31.3.9 | If a launched category falls to **zero** active publishable Businesses, Civilpedia must show an **honest empty/unavailable state** rather than stale or fake listings. | `LOCKED` |
| 31.3.10 | Civilpedia should launch a **focused initial group** of commercially meaningful categories rather than every possible category simultaneously. The exact initial category list may be selected **operationally** on sales-readiness and inventory grounds **without changing the core 5-business Launch Gate**. | `LOCKED` |
| 31.3.11 | **Expansion outside Baghdad is not automatic.** It should occur after sufficient supply/demand readiness and an **explicit later commercial/product decision**. | `LOCKED` |
| 31.3.12 | **Founding Partner** acquisition may be used to help reach launch density but does **not** weaken the paid-only publication rule (§2.1, §2.5, §27.2). | `LOCKED` |
| 31.3.13 | Exact UX for the Coming Soon / empty / unavailable presentation. | `DEFERRED` (`OQ-68`, `OQ-76`) |
| 31.3.14 | **Narrow cold-start reconciliation added by A8-11** (§32.11 → L-97): during the **initial Launch Partner phase**, an authorized Launch Partner that has (a) a **valid Business Entity**, (b) an **active A8 promotional commercial entitlement**, and (c) a **publicly publishable profile**, **MAY** count toward launch-category supply density. The preferred term is **COMMERCIAL-ACTIVE BUSINESS**. This is **NOT** a free listing, **NOT** a new tier, and **NOT** a change to the Paid-Only publication rule. | `LOCKED` — added by A8-11 (§32.11) |
| 31.3.15 | For ordinary **post-launch paid operation**, a **paid subscription remains the normal entitlement basis**. The A8-11 reconciliation is a **cold-start-only** allowance. | `LOCKED` — added by A8-11 (§32.11.3) |
| 31.3.16 | Post-promotion treatment of a category that reached the Launch Gate partly through Commercial-Active Launch Partners. | Not decided → **`OQ-84`** (`REGISTER BEFORE FREEZE`, non-blocking) |

**A7-3 scope notes.** A7-3 decides launch **density, gating, sequencing, and launch
geography**, and closes `OQ-37`. The Paid-Only rule (§2.1, §2.5) and the
production/seed distinction (C-9, §2.5) are **unchanged**. A7-3 does **not** close
`OQ-48` (consequence of falling below the publication gate **after** publication) or
`OQ-68`; both remain `OPEN`. A7-3 does not change the §27.1 category-eligibility
boundary.

**A8-11 amendment note (narrow; A7-3 preserved).** A8-11 adds **only** rows 31.3.14
and 31.3.15 and the `OQ-84` citation in 31.3.16. Everything A7-3 locked is
**preserved unchanged**: **BAGHDAD FIRST** (31.3.1), no broad sparse launch (31.3.2),
the normal **5 active paid publishable Business** Category Launch Gate (31.3.3),
the ~8–10 per-category growth target (31.3.4), the ~30 overall formal launch target
(31.3.5), no fake-listing padding (31.3.7), the launch-gate-not-shutdown-threshold
rule (31.3.8), the honest empty state (31.3.9), the focused initial category group
(31.3.10), and non-automatic geographic expansion (31.3.11). The 5-Business gate
itself is **not** lowered; A8-11 only states **whose entitlement may be counted
toward it during the initial Launch Partner phase**.

**A8 reading clarification (documentary; not a commercial decision).** The word
**"active"** in 31.3.14(b) and §32.11.1(b) means **the A8 promotional commercial
entitlement is currently in effect**. A Launch Partner **MAY** count toward launch
density as a `COMMERCIAL-ACTIVE BUSINESS` only while that entitlement **is active**
**and** its profile **remains publicly publishable**; once the promotional entitlement
**expires** it no longer counts on that basis, unless another valid commercial
entitlement applies, such as a **verified paid subscription**. The A8-3 phrase
**"Before promotional expiry"** (§32.3.1) refers **only** to the **timing of presenting
factual interaction/value metrics** and does **NOT** define entitlement validity,
launch-density eligibility, Grace, or post-expiry publication status. The existing
expiry, Grace, and conversion rules (§32.2.3.3–§32.2.3.6, §8.3, `L-56`, `L-61`) are
**preserved unchanged**. This clarification adds **no** commercial decision, changes
**no** `LOCKED` rule, price, plan, or entitlement, and does **not** weaken §31.3 or
§32.11; `OQ-84` remains the registered residual question.

### 31.4 Freeze status after A7

The `MUST RESOLVE BEFORE FREEZE` count is now **0**. **This is not a freeze
declaration.** §1.6 item 8 still requires an **independent Freeze Readiness Audit**
and **Architect acceptance** before the Document Owner may consider a freeze
declaration. Neither has occurred. The document therefore remains
**`NOT YET FROZEN`**, and `IMPLEMENTATION_AUTHORIZED` remains **`NO`**. A7 does
**not** grant roadmap authorization and does not change §1.2 (L-47).

**Superseded 2026-10-01 (post-freeze).** The paragraph above records the
**post-A7, pre-freeze** state accurately and is preserved as history (§1.5
rule 3). On 2026-10-01 the **final A8-inclusive independent Freeze Readiness
Audit** was completed, **Architect Acceptance** was issued, and the **Document
Owner explicitly approved freeze**; the document is now **`FROZEN`** as the
canonical commercial-policy baseline for Civilpedia V1, with `MUST RESOLVE BEFORE
FREEZE` = **0** and `IMPLEMENTATION_AUTHORIZED` = **`NO`** (§1.2, L-47).
**Current status is §33.** A7 itself still did **not** freeze the document, and
it changed **no** commercial decision.

---

## 32. AMENDMENT A8 — COLD-START ACQUISITION AND BUSINESS ONBOARDING POLICY (added 2026-09-30)

### 32.0 Amendment governance, authority, and non-authorization

1. **Authority.** §32 records explicit **Document Owner** commercial decisions,
   consolidated by the Architect. These are decisions, not proposals, and not
   inferences from conversation history (§1.5).
2. **The design was intentionally reopened before freeze.** A Final Freeze
   Readiness Audit had found the model commercially complete **in its pre-A8
   state**. The Document Owner and the Architect then deliberately **reopened** the
   commercial design to address **cold-start acquisition / first-business
   onboarding**. That reopening is a normal, recorded use of §1.5 and is **not** a
   freeze, a rollback of prior decisions, or a defect in the prior audit. The prior
   audit is preserved as history and is **`VALID FOR THE PRE-A8 STATE` ONLY**
   (§1.6 item 9, §32.12).
3. **Non-authorization.** §32 defines a **product/commercial policy requirement
   only**. A8 creates **no** code, table, column, enum, migration, RLS policy,
   route, screen, auth flow, backend service, contract, phase, or roadmap change, and
   authorizes **no** implementation. `IMPLEMENTATION_AUTHORIZED` remains **`NO`**.
   §1.2 (L-47) is unchanged.
4. **Nothing invented.** A8 records exactly the supplied Owner decisions. It decided
   **no** price, **no** plan change, **no** entitlement tier, and **no** rule outside
   §§32.1–32.11. Where A8 explicitly left a matter open, it is routed to §24.3
   (Owner-level), §24.2 (architecture/dependency), or §25.2 (`PROVISIONAL`) — never
   answered by inference.
5. **Terminology.** **Business Owner** vs **Document Owner** (§26.0, L-64) is
   unchanged. A8 uses **Business Entity** (§2.2) and never creates a new entity type.
   **Launch Partner** and **Founding Partner** are **distinct** (§5.1a, §32.2.4).
6. **A8 preserves all A3–A7 meaning**, including `L-01`/`L-02` (paid-only, no
   permanent free listing), `L-55`/`L-56` (term anchor, manual renewal), `L-62`
   (duplicates), `L-66`/`L-67` (claiming boundary, production paid-only), `L-74`
   (verification), `L-76` (Required Fields Gate), `L-77` (analytics honesty), `L-81`
   (team), `L-86` (ownership cardinality), and `L-87` (launch density).

### 32.1 No permanent free commercial Business tier (A8-1 → L-88)

| # | Rule | Status |
|---|---|---|
| 32.1.1 | Civilpedia will **NOT** create a **permanent free commercial listing tier** for: companies; contractors; suppliers; stores; manufacturers; equipment providers / rental businesses; ready-mix businesses; or any other commercial Business-plan-eligible organisation. | `LOCKED` |
| 32.1.2 | **Creating a Civilpedia user/account may be free.** | `LOCKED` |
| 32.1.3 | **Using non-commercial Civilpedia capabilities may be free.** | `LOCKED` |
| 32.1.4 | **Persistent public commercial presence** for an eligible Business Entity remains a **paid commercial product**, except for the **explicitly authorized temporary** launch/promotional access in §32.2. | `LOCKED` |
| 32.1.5 | **Individual Professionals / Workforce are a separate future model** and are **NOT** converted into paid Business listings by A8. | `LOCKED` |
| 32.1.6 | A8 **does NOT define** the future Professionals/Workforce monetization model. | `LOCKED` (explicit non-decision) |
| 32.1.7 | The only class of non-paid commercial public access A8 authorizes is the **temporary Launch Partner promotional period** in §32.2, which is **not** a tier and creates **no** permanent free plan (§32.2.3.6). | `LOCKED` |
| 32.1.8 | No customer-facing, sales, or UI material may state or imply that a Civilpedia commercial listing is **permanently free** (§32.4.5). | `LOCKED` |

**A8-1 scope notes.** A8-1 confirms and **reinforces** `L-02`; it does not create a
free tier. A8-1's only commercial effect is to make explicit that a free *account*
and free *non-commercial* capabilities are permitted while commercial *presence*
remains paid. A8-1 leaves the Professionals/Workforce model entirely undecided
(`DEFERRED`, D-11, D-12) and adds no pricing, tier, or entitlement for it.

### 32.2 Founding Launch Partner Program (A8-2 → L-89)

#### 32.2.1 Cohort, selection, and categories

| # | Rule | Status |
|---|---|---|
| 32.2.1.1 | Civilpedia may select an **invitation-only** initial cohort of approximately **20–30 commercial Businesses** for cold-start seeding. | `LOCKED` |
| 32.2.1.2 | **Selection is controlled by Civilpedia.** It is **NOT** an automatic entitlement for every business. | `LOCKED` |
| 32.2.1.3 | Cohort membership may include: contractors; suppliers; construction-material stores; ready-mix; equipment/rental; waterproofing / construction chemicals; MEP / HVAC / electrical; laboratories / testing; surveying / GIS; fire/safety; and other strategically useful construction categories. | `LOCKED` (illustrative category list — **note** the §27.1 / `L-65` eligibility boundary still governs: an individual professional is never eligible) |
| 32.2.1.4 | **Cohort quality and category diversity are more important than maximizing raw count.** | `LOCKED` |
| 32.2.1.5 | Cohort-administration mechanics (selection criteria, cap enforcement, exhaustion behaviour, status tracking, withdrawal/re-invitation) | `DEFERRED` → **`OQ-80`** |

#### 32.2.2 Promotional entitlement, clock, and start anchor

| # | Rule | Status |
|---|---|---|
| 32.2.2.1 | An approved Launch Partner receives **BUSINESS PRO** at a **promotional price of 0 IQD** for **60 calendar days**. | `LOCKED` |
| 32.2.2.2 | The **60-day period does NOT begin** merely when Civilpedia creates the Business Draft. | `LOCKED` |
| 32.2.2.3 | **Trial start anchor: the LATER of** (a) the **Civilpedia formal commercial launch date**, or (b) the **Business's first successful public publication after that launch.** | `LOCKED` |
| 32.2.2.4 | Intent of 32.2.2.3, recorded as the governing commercial rationale: a business must not lose promotional days while Civilpedia is **not genuinely available to users**. | `LOCKED` (rationale) |
| 32.2.2.5 | **No card or payment instrument is required** to begin the promotional period. | `LOCKED` |
| 32.2.2.6 | **No automatic renewal and no automatic charge.** This preserves A3-2 (`L-56`: manual renewal only, no stored instrument) unchanged. | `LOCKED` |
| 32.2.2.7 | Interaction with A3-1 (`L-55`): the A8 promotional period is a **fixed 60-calendar-day promotional entitlement**, not a paid term. The A3-1 paid-term anchor rule is **unchanged** and continues to govern **paid** subscriptions only. A8 creates no second, conflicting term-anchor rule. | `LOCKED` (non-conflict clarification) |
| 32.2.2.8 | How the anchor and the 60-day clock are computed, stored, and displayed. | `DEFERRED` — implementation architecture (P-30, D-30) and administration (`OQ-80`) |

#### 32.2.3 Eligibility guards, expiry, and non-precedent

| # | Rule | Status |
|---|---|---|
| 32.2.3.1 | The promotional period is normally available **once per genuine Business Entity**. | `LOCKED` |
| 32.2.3.2 | **Duplicate entities/accounts may not be used to obtain repeated launch trials.** Enforcement is an application of A3-6 (`L-62`, §26.6); the detection/merge mechanics remain `OQ-72`. | `LOCKED` |
| 32.2.3.3 | At promotional expiry, the business **may convert** to Business / Pro / Plus / Corporate according to applicable eligibility. | `LOCKED` |
| 32.2.3.4 | If **no paid subscription is verified** by expiry, the ordinary expiry / Grace / public-hiding rules apply (§8.3, L-56: Grace = 5 calendar days, then hidden from the public directory). | `LOCKED` |
| 32.2.3.5 | **Data is not automatically deleted** at promotional expiry (`L-25`, `L-61` unchanged). | `LOCKED` |
| 32.2.3.6 | **Launch Partner promotional access does NOT create a permanent free-plan precedent.** | `LOCKED` |
| 32.2.3.7 | The "normally" qualifier in 32.2.3.1, and any exception to it. | Not decided → **`OQ-81`** (with ownership/entity-change continuity) |
| 32.2.3.8 | Cohort exhaustion, withdrawal/revocation of Launch Partner status, and the effect on remaining promotional days. | Not decided → **`OQ-80`** |

#### 32.2.4 Distinctness from Founding Partner

| # | Rule | Status |
|---|---|---|
| 32.2.4.1 | **Launch Partner is DISTINCT from the Founding Partner annual pricing program** (§5). The two must not be merged. | `LOCKED` |
| 32.2.4.2 | A business may qualify for **both** if the eligibility rules permit: **first**, temporary Launch Partner promotional Pro access; **later**, eligible Founding Partner **first-year paid** pricing (§5.7). | `LOCKED` |
| 32.2.4.3 | Founding Partner discounted pricing is a **paid** first-year price; a Launch Partner promotional entitlement is a **0 IQD temporary** access period. Presenting either as the other is prohibited (§5.1a, §25.4 prohibition 26). | `LOCKED` |

**A8-2 scope notes.** A8-2 decides the Launch Partner **commercial policy**: cohort
size and control, promotional plan, price, duration, start anchor, absence of card
and auto-charge, per-entity limit, duplicate-abuse prohibition, expiry outcome, and
non-precedent. It changes **no** price in §3.2, §5.7, or §6.2. It creates **no**
`plans` row, **no** subscription record, **no** entitlement flag, and **no** schema.
Whether the promotional access is represented in production, and how, is
implementation architecture (P-30, D-30, `OQ-80`).

### 32.3 Launch Partner value and conversion (A8-3 → L-90)

| # | Rule | Status |
|---|---|---|
| 32.3.1 | Before promotional expiry, Civilpedia **should, where available**, show the Business its **factual usage metrics**, such as: **Profile Views**, **WhatsApp Clicks**, **Call Clicks**, **Directions Clicks**, and other approved interaction metrics. | `LOCKED` |
| 32.3.2 | These metrics are **interaction metrics only**. | `LOCKED` |
| 32.3.3 | They are **NOT guaranteed leads** and **NOT confirmed sales**. This restates and does not soften `L-77` (A5-16) or `L-41`. | `LOCKED` |
| 32.3.4 | The commercial purpose is to allow the Business to evaluate **actual observed value** before deciding whether to subscribe. | `LOCKED` (purpose) |
| 32.3.5 | Exact reporting UX and analytics storage. | `DEFERRED` — implementation/design (P-36, `OQ-77`, D-25) |
| 32.3.6 | Pre-expiry promotional-period reporting visibility, counting/retention rules, and post-expiry retention of the Launch Partner's analytics history. | Not decided → **`OQ-17`** (**narrowed** by A8) |

**A8-3 reading clarification (documentary; not a commercial decision).** The phrase
**"Before promotional expiry"** in 32.3.1 refers **only** to the **timing of presenting
factual interaction/value metrics** to the Business before the promotional period ends
(32.3.4). It does **NOT** define entitlement validity, launch-density or
`COMMERCIAL-ACTIVE BUSINESS` eligibility, Grace, or post-expiry publication status;
those remain governed by §32.2.2, §32.2.3, §8.3, §32.11, and `L-56`. A Launch Partner
stops counting toward launch density when its A8 promotional entitlement expires,
unless another valid commercial entitlement applies — see the **A8 reading
clarification** in §32.11. This adds **no** commercial decision and changes **no**
`LOCKED` rule; the residual question of post-promotion category treatment remains
**`OQ-84`**.

### 32.4 Business acquisition CTA (A8-4 → L-91)

| # | Rule | Status |
|---|---|---|
| 32.4.1 | Civilpedia may display **first-party promotional surfaces** inviting businesses to join the commercial directory. | `LOCKED` |
| 32.4.2 | **Approved intent examples** (illustrative, **not** final copy): "هل لديك نشاط في قطاع البناء؟ اعرض نشاطك التجاري على Civilpedia." and "اشترك الآن لعرض نشاطك على Civilpedia." | `LOCKED` (approved intent) — final Arabic copy is configuration, must enter the localization SSOT (D-27, §28.14) |
| 32.4.3 | This is a **Civilpedia-owned acquisition CTA, NOT third-party Sponsored inventory.** It does not consume Sponsored inventory and is never sold, labelled, or reported as advertising (§6.1.12, L-73). | `LOCKED` |
| 32.4.4 | The CTA may lead to: Business subscription information; Business application / onboarding; an approved WhatsApp Business sales contact; or a future approved sales flow. | `LOCKED` |
| 32.4.5 | **Civilpedia must not imply that commercial listing is permanently free.** | `LOCKED` |
| 32.4.6 | Placement may include: a Home promotional banner; the Business Directory; empty or under-supplied commercial categories; and other appropriate Civilpedia-owned surfaces. | `LOCKED` |
| 32.4.7 | Exact copy, visual design, campaign timing, targeting, and destination. | `PROVISIONAL` — design/marketing configuration (P-35, D-27). **Not** a Document Owner commercial decision (§1.3 rule 6(b)). |

### 32.5 Civilpedia-created Business Drafts (A8-5 → L-92)

| # | Rule | Status |
|---|---|---|
| 32.5.1 | **Civilpedia staff may create a Business Draft on behalf of a prospective customer or Launch Partner.** | `LOCKED` — consistent with the already-`LOCKED` §10.1 hybrid onboarding and §27.2 (`L-66`) |
| 32.5.2 | Civilpedia may prepare, using information **supplied or authorized by the Business**: business identity; category/activity; description; contact information; logo/media; products/services; portfolio/projects; branches; and other permitted commercial profile content. | `LOCKED` |
| 32.5.3 | A Business Draft **may exist before a Business Owner is attached**. | `LOCKED` |
| 32.5.4 | Such a record is **`CIVILPEDIA-MANAGED / OWNER NOT YET ATTACHED`** until ownership is assigned/accepted. This is a **conceptual commercial state only**; A8 creates no enum, flag, or column. | `LOCKED` (concept) — persistence `DEFERRED` (P-28, D-30) |
| 32.5.5 | **A staff-created Draft does NOT itself prove ownership.** | `LOCKED` |
| 32.5.6 | **Publication still requires all applicable:** subscription/promotional entitlement; Minimum Profile Quality / Required Fields Gate (§19, §28.6, L-76); ownership/onboarding (§32.6); and moderation/verification requirements (§13, §9). | `LOCKED` |
| 32.5.7 | Retention, disposition, and re-attachment of a Civilpedia-managed Draft that **never** receives an accepted owner, and whether such a Draft may ever appear publicly. | Not decided → **`OQ-82`** |

**A8-5 scope notes.** A8-5 **expands nothing** in §10.1 or §27.2: the controlled
Civilpedia-created Draft was already the approved flow. A8-5 makes explicit that the
Draft may precede ownership, that it is not ownership evidence, and that publication
still requires the full entitlement + quality + ownership + moderation chain. A8-5
does **not** reintroduce any form of open public claiming (`L-66`, D-17 unchanged).

### 32.6 Owner invitation is the default (A8-6 → L-93)

| # | Rule | Status |
|---|---|---|
| 32.6.1 | The **preferred and default** ownership-assignment method is **INVITATION**. | `LOCKED` |
| 32.6.2 | **Normal flow:** Civilpedia creates the Business Draft → the Business representative creates or uses **their own** Civilpedia account → Civilpedia sends the ownership invitation → the user reviews and accepts → controlled ownership linkage occurs. | `LOCKED` |
| 32.6.3 | **Civilpedia must NOT create a password and hand the credentials to the Business.** This reaffirms `L-29` and §10.1 unchanged. | `LOCKED` |
| 32.6.4 | **Each natural person uses their own Civilpedia account.** | `LOCKED` |
| 32.6.5 | **Pending invitations must not silently grant ownership before acceptance.** | `LOCKED` |
| 32.6.6 | **Primary Business Owner rules approved in A7 remain authoritative** (`L-86`, §31.2): exactly one Primary Business Owner in normal operation, optional verified Co-Owners, and OWNERSHIP RECOVERY PENDING. A8 changes none of it. | `LOCKED` (preservation) |
| 32.6.7 | Invitation expiry/timeout, re-invitation limits, decline handling, and whether an invitation may be redirected to a different person. | Not decided → **`OQ-83`** |
| 32.6.8 | Invitation transport, persistence, deep links, and screens. | `DEFERRED` — implementation (`OQ-77`, P-25, D-28) |

### 32.7 Direct assignment (A8-7 → L-93)

| # | Rule | Status |
|---|---|---|
| 32.7.1 | **Direct assignment may exist as an ADMIN-ONLY EXCEPTIONAL capability.** | `LOCKED` |
| 32.7.2 | It may only target an **already identifiable Civilpedia user account**, and must **not** involve shared credentials or password handover. | `LOCKED` |
| 32.7.3 | Direct assignment must create an **auditable record** including at minimum: the acting Civilpedia admin; the affected Business; the target user; the role/capability assigned; the **timestamp**; and **reason/context** where required. | `LOCKED` |
| 32.7.4 | **Routine ownership onboarding still prefers invitation/acceptance** (§32.6). | `LOCKED` |
| 32.7.5 | **Primary Business Owner assignment should normally require acceptance/verification.** | `LOCKED` |
| 32.7.6 | Emergency/administrative override behaviour, exact security controls, and audit persistence. | `DEFERRED` — architecture/security-policy work (D-28, **D-33**) |
| 32.7.7 | **A direct assignment must not bypass ownership verification** where verification is otherwise required. | `LOCKED` |

### 32.8 Business team capability concept (A8-8 → L-94)

A8-8 **preserves** the existing capability concepts and locks **only their
operational intent**.

| Capability concept | Operational intent (A8-8) | Status |
|---|---|---|
| **Primary Business Owner** | Highest accountable ownership authority. | `LOCKED` (concept + intent) — consistent with `L-86` |
| **Co-Owner** | Ownership participation, but **not** automatically equivalent to the Primary Business Owner for sensitive ownership transfer. | `LOCKED` (concept + intent) |
| **Manager** | Operational management **without** ownership authority. | `LOCKED` (concept + intent) |
| **Editor** | Limited content-management capability. | `LOCKED` (concept + intent) |

| # | Rule | Status |
|---|---|---|
| 32.8.1 | The exact **stored role enum / RBAC matrix / RLS implementation** | `DEFERRED` (P-25, D-28, `OQ-77`) |
| 32.8.2 | Any new role, enum value, column, RLS policy, or migration | **Not authorized by A8** (§1.2, L-47) |
| 32.8.3 | Team seat ceilings and financial visibility remain as decided by A5-20 (`L-81`, §28.11) — unchanged. | `LOCKED` (preservation) |

**A8-8 scope notes.** A8-8 adds **no** stored role and **no** RBAC decision. It is
a **capability-intent** restatement layered on A7-2's Primary/Co-Owner model and the
pre-existing Owner/Manager/Editor vocabulary (§11.1, §11.1a). `business_memberships.role IN ('OWNER','ADMIN','MEMBER')`
is **unchanged** (C-1, L-53).

### 32.9 Server-managed commercial catalog requirement (A8-9 → L-95)

> This section defines a **PRODUCT / ARCHITECTURE REQUIREMENT ONLY**. It does
> **not** authorize implementation.

| # | Requirement | Status |
|---|---|---|
| 32.9.1 | Commercial catalog content must **NOT** require a new mobile-app release merely in order to: add a new commercial category; add a subcategory/activity; add, remove, or reorder a Business; change category visibility; change category labels/descriptions/media; add or update branches; activate or deactivate eligible commercial records; or change Civilpedia-owned acquisition campaign/banner content. | `LOCKED` (product requirement) |
| 32.9.2 | The commercial taxonomy/catalog must be **administratively manageable from backend / admin-controlled data**. | `LOCKED` (product requirement) |
| 32.9.3 | Flutter should **consume supported commercial data/configuration** rather than hard-code every future business or category record. | `LOCKED` (product requirement) |
| 32.9.4 | The app **may** cache the last valid catalog for resilience/offline behaviour, according to future architecture. | `LOCKED` (permitted direction) — caching strategy `DEFERRED` (D-32) |
| 32.9.5 | This does **NOT** authorize **arbitrary downloaded executable UI/code**. | `LOCKED` (prohibition) |
| 32.9.6 | **New UI capability/block types** that the installed app does not know how to render **may still require an app update.** | `LOCKED` (limitation) |
| 32.9.7 | Exact database schema, taxonomy tables, caching, realtime strategy, Remote Config usage, admin-panel implementation, permissions, RLS, and synchronization. | `DEFERRED` — **IMPLEMENTATION ARCHITECTURE** decisions (D-32, D-28, D-30). **Not** Document Owner commercial decisions (§1.3 rule 6(b)) |

**A8-9 scope notes.** A8-9 locks a **capability requirement** that keeps ordinary
commercial catalog administration off the mobile release train. It deliberately
**excludes** downloadable executable UI/code (32.9.5) and deliberately **preserves**
the legitimate need for an app update for genuinely new renderable UI types
(32.9.6). A8-9 creates **no** table, no Remote Config project, no flag, and no
admin surface.

### 32.10 Admin and Business control requirements (A8-10 → L-96)

> Recorded as **future implementation requirements**, **not** authorization.

| # | Requirement | Status |
|---|---|---|
| 32.10.1 | Future **authorized administration tooling** should support at minimum: **Categories**; **Activities/Subcategories**; **Businesses**; **Branches**; **Ownership & Team**; **Invitations**; **Launch Partner status**; **Subscription/status management**; **Civilpedia acquisition banners/campaigns**; **Moderation**; **Audit logs**. | `DEFERRED` — future implementation requirement (D-32, D-33, `OQ-77`) |
| 32.10.2 | **Business Center** should later allow **entitled users** to manage appropriate Business content, subject to moderation and sensitive-change rules (§13.1). | `DEFERRED` — future implementation requirement (`OQ-77`, D-21) |
| 32.10.3 | A8 **does not design** exact screens, routes, or schema for any of the above. | `LOCKED` (explicit non-decision) |

### 32.11 Launch density reconciliation (A8-11 → L-97)

A7-3 (`L-87`, §31.3) used **5 ACTIVE + PAID + PUBLICLY PUBLISHABLE Businesses** as the
normal Category Launch Gate. Because A8 introduces an **approved temporary
promotional commercial access**, A8-11 amends the **cold-start** launch rule
**narrowly** only.

| # | Rule | Status |
|---|---|---|
| 32.11.1 | During the **initial Launch Partner phase**, an authorized Launch Partner with: (a) a **valid Business Entity**; (b) an **active A8 promotional commercial entitlement**; and (c) a **publicly publishable profile**, **MAY count toward launch-category supply density**. | `LOCKED` |
| 32.11.2 | The preferred term for such a counted Business is **COMMERCIAL-ACTIVE BUSINESS**. | `LOCKED` (terminology) |
| 32.11.3 | For ordinary **post-launch paid operation**, a **paid subscription remains the normal entitlement basis.** | `LOCKED` |
| 32.11.4 | A Commercial-Active Business must **NOT** be described, presented, sold, or documented as a **free listing**, a free tier, or a permanent free plan (§32.1, L-02, L-88). | `LOCKED` |
| 32.11.5 | **Preserved unchanged from A7-3:** **BAGHDAD FIRST**; focused initial categories; the normal **5-Business launch gate**; the **~8–10** per-category growth target; the **~30** formal launch target; **no fake listings**; and **no permanent free commercial tier**. | `LOCKED` (preservation) |
| 32.11.6 | Post-promotion treatment of a category that reached the gate partly through Commercial-Active Launch Partners. | Not decided → **`OQ-84`** |

**A8-11 scope notes.** A8-11 **does not lower the 5-Business gate**. It states whose
**entitlement** may be **counted toward** that gate during the initial Launch Partner
phase. It does not weaken §2.1 (paid-only), §2.5 (production paid-only), §27.2
(`L-67`), or §31.3.7 (no fake/free padding). A promotional Business that is not
publicly publishable because it fails the Required Fields Gate does **not** count.

**A8 reading clarification (documentary; not a commercial decision).** The word
**"active"** in 32.11.1(b) and §31.3.14(b) means **the A8 promotional commercial
entitlement is currently in effect**, and it is read together with the A8-3 phrase
**"Before promotional expiry"** in §32.3.1 as follows:

1. A Launch Partner **MAY** count toward launch-category supply density as a
   `COMMERCIAL-ACTIVE BUSINESS` **only while** its A8 promotional commercial
   entitlement **is active** **and** its Business profile **remains publicly
   publishable**.
2. Once the promotional entitlement **expires**, it **no longer counts** on the basis
   of the A8 promotional entitlement itself. It **may** continue to count **only** if
   another valid commercial entitlement applies, such as a **verified paid
   subscription**.
3. The A8-3 phrase **"Before promotional expiry"** (§32.3.1) refers **only** to the
   **timing of presenting factual interaction/value metrics** to the Business before
   the promotional period ends.
4. That phrase **does NOT define** entitlement validity, launch-density eligibility,
   Grace, or post-expiry publication status. Those remain governed by §32.2.2, §32.2.3,
   §8.3, and `L-56`.
5. The existing expiry, Grace, and conversion rules (§32.2.3.3, §32.2.3.4, §32.2.3.5,
   §32.2.3.6, `L-56`, `L-61`) are **preserved unchanged**.

This clarification **adds no commercial decision**, changes **no** `LOCKED` rule,
`PROVISIONAL` value, price, plan, entitlement, or OQ status, and does **not** weaken
§31.3 or §32.11. It records only the reading the Owner and Architect already
intended, so that 32.11.1(b) and §32.3.1 cannot be read as conflicting. The residual
question of post-promotion category treatment remains **`OQ-84`** (`OQ-17` remains
narrowed for reporting visibility, counting/retention, and post-expiry history).

### 32.12 Freeze status after A8

The `MUST RESOLVE BEFORE FREEZE` count remains **0**. **This is not a freeze
declaration.**

1. A8 **intentionally reopened** the pre-freeze commercial record after the previous
   Final Freeze Readiness Audit had found the model commercially complete.
2. The previous Final Freeze Readiness Audit is therefore **`VALID FOR THE
   PRE-A8 STATE`** and remains a preserved historical record. It is **not**
   sufficient **by itself** for a final freeze decision, because the commercial
   record changed after it was performed.
3. §1.6 items 8 and 9 still require a **fresh independent Freeze Readiness Audit
   over the A8-inclusive document**, **Architect acceptance**, and then an
   **explicit Document Owner freeze declaration** per §1.5. **None has occurred.**
4. The document therefore remains **`ACTIVE DESIGN` / `CANONICAL COMMERCIAL SSOT`
   / `NOT YET FROZEN`**, `IMPLEMENTATION_AUTHORIZED` remains **`NO`**, the roadmap
   is unchanged, and §1.2 (L-47) is unchanged.
5. A8 authorizes **no** code, schema, migration, RLS, route, auth, backend, contract,
   test, UI, or roadmap change, and does **not** grant roadmap authorization.

**Superseded 2026-10-01 (post-freeze).** Items 1–5 above record the **post-A8,
pre-freeze** state accurately and are preserved as history (§1.5 rule 3); in
particular item 3's "**None has occurred**" is accurate **as of A8** and is
superseded as current status. On 2026-10-01 the **final A8-inclusive independent
Freeze Readiness Audit was completed**, **Architect Acceptance was issued**, and
the **Document Owner explicitly approved freeze**, satisfying §1.6 items 8 and 9.
The document is now **`FROZEN`** as the canonical commercial-policy baseline for
Civilpedia V1, with `MUST RESOLVE BEFORE FREEZE` = **0** and
`IMPLEMENTATION_AUTHORIZED` = **`NO`**; item 5 remains fully in force.
**Current status is §33 — not item 3 or item 4 above.**

---

## 33. COMMERCIAL MODEL V1 — FREEZE DECLARATION (2026-10-01)

### 33.0 Authority, basis, and the single-current-state rule

**Authority.** **Document Owner + ChatGPT Architect.** Only the Document Owner may
declare the freeze (§1.5, §1.6 item 10); the Architect records and consolidates it.

**Basis.** The freeze is declared on the basis of **all** of the following, each
recorded as **`SATISFIED`**:

| # | Freeze precondition | Authority | State |
|---|---|---|---|
| 33.0.1 | **`MUST RESOLVE BEFORE FREEZE` = 0** | §24.3.6, §25.5 | **`SATISFIED`** |
| 33.0.2 | **Independent A8-inclusive Freeze Readiness Audit completed** over the A8-inclusive document | §1.6 items 8 and 9 | **`SATISFIED`** |
| 33.0.3 | **Architect Acceptance issued** and recorded | §1.6 item 8 | **`SATISFIED`** |
| 33.0.4 | **Explicit Document Owner freeze declaration** recorded by explicit update to this document | §1.5, §1.6 items 3(c) and 10 | **`SATISFIED`** |
| 33.0.5 | **Freeze state** | §1.6 | **`FROZEN`** |

**Single-current-state rule.** **§33 is the single authoritative current freeze
record of this document.** The header `DOCUMENT_STATUS` / `FREEZE_STATE` /
`FREEZE_DECLARATION` lines and the §1.6 maturity table restate it. Every other
freeze-status statement in this document — the pre-freeze header history, the
A2/A3–A5/A6/A7/A8 amendment records, §1.6 items 8 and 9, the §24.3.7 and §25.5
A8 freeze-gate statements, §31.4, and §32.12 — is **historical or superseded**,
retained per §1.5 rule 3, and is **not** current status.

### 33.1 The freeze declaration

**Commercial Model V1 is `FROZEN`** as the **canonical commercial-policy
baseline for Civilpedia V1**, effective **2026-10-01**, by explicit Document Owner
declaration. `DOCUMENT_STATUS` is **`FROZEN — CANONICAL COMMERCIAL SSOT`**,
`FREEZE_STATE` is **`FROZEN`**, and `IMPLEMENTATION_AUTHORIZED` remains **`NO`**.

Consequences, mandatory:

1. **The Final A8-inclusive independent Freeze Readiness Audit was completed**, and
   **Architect Acceptance was issued**. The pre-A8 Final Freeze Readiness Audit
   remains a valid preserved record of the pre-A8 state (§1.6 item 9) and is
   **retained unchanged**; the freeze rests on the later **A8-inclusive** audit.
2. **The Document Owner explicitly approved freeze** (§1.5, §1.6 item 10).
3. **`MUST RESOLVE BEFORE FREEZE` = 0** (§24.3.6, §25.5).
4. **Commercial Model V1 is frozen as the canonical commercial-policy baseline for
   Civilpedia V1.** Its `LOCKED` commercial decisions are binding policy and may not
   be silently reinterpreted, softened, or implemented around (§1.3).
5. **All remaining `OPEN` Open Questions retain their existing classifications** —
   status, severity, owner, and classification are unchanged — and **remain routed
   to their proper later phases** (§1.2, §1.3, §24.3, §30.3). The freeze **does not**
   resolve, narrow, reclassify, or answer any of them.
6. **No `OPEN` Open Question is implicitly closed by the freeze.** A closed entry
   exists only with an explicit close trace in §24.3.6; the freeze adds **none**.
7. **No `PROVISIONAL` or `DEFERRED` item becomes `LOCKED` merely because the
   document is frozen.** `PROVISIONAL` values remain unquotable and non-final
   (§1.3 rule 2); `DEFERRED` remains "not in Commercial V1", not "rejected"
   (§1.3 rule 4). The `LOCKED` / `PROVISIONAL` / `DEFERRED` counts are unchanged.
8. **The freeze changed no commercial meaning.** **0** commercial decisions changed;
   **0** prices, plans, or entitlements changed; **0** `LOCKED`, `PROVISIONAL`, or
   `DEFERRED` entries added; all A3–A8 meaning is preserved unchanged (§1.5 rule 3).
9. **IMPLEMENTATION_AUTHORIZED remains `NO`.** Commercial freeze does **not**
   authorize implementation (§1.2, L-47; §33.3 below).
10. **Any future change to the commercial model requires a new explicit post-freeze
    amendment** under the §1.5 change protocol, recorded with its authority, its
    previous and new value, and its implementation/sales impact. Because such an
    amendment changes a frozen record, it additionally requires a **fresh
    independent Freeze Readiness Audit** and **fresh Architect Acceptance** before
    the amended text may be represented as final (§1.6 item 8). No freeze may be
    declared by any other authority or inferred from conversation history (§1.5).

### 33.2 Post-freeze authority boundary

> **`FROZEN COMMERCIAL MODEL != IMPLEMENTATION AUTHORIZATION`**

The commercial freeze authorizes **no** implementation of any kind. It authorizes
**no** item in the following list:

| # | Not authorized by this freeze | Existing routing |
|---|---|---|
| 33.2.1 | **code** of any kind — `lib/**` or otherwise | §1.4, §1.2 rule 1 |
| 33.2.2 | **schema** — table, column, enum, flag, or field | §1.2 rules 1–2 |
| 33.2.3 | **migrations** | §1.4 (`supabase/migrations/*`) |
| 33.2.4 | **Supabase / RLS** policy or configuration | §1.4 |
| 33.2.5 | **auth** flow, credential, session, or role-enum change | `L-29`, `L-63`, `L-86`, `OQ-77` |
| 33.2.6 | **routes**, screens, or navigation | §1.2 rule 1 |
| 33.2.7 | **Business Center** | `DEFERRED` — P-25, D-21, `OQ-77` |
| 33.2.8 | **Admin Console** / admin tooling | `DEFERRED` — D-32, D-33, `OQ-77` |
| 33.2.9 | **subscription backend** behaviour | `DEFERRED` — D-28, D-30, P-30 |
| 33.2.10 | **payment gateway** or e-payment integration | `DEFERRED` — §28.1, `L-70`, D-22, `OQ-09` |
| 33.2.11 | **Sponsored backend** or inventory behaviour | §28.3, `L-70`…`L-73` |
| 33.2.12 | **Professional Marketplace** commercial model | `DEFERRED` — §23, D-11, D-12 |
| 33.2.13 | **Construction Ecosystem** commercial model | `DEFERRED` — §23, D-11, D-12 |

Each of the above requires a **separately authorized architecture/implementation
slice**, with its own frozen contract, its own file boundary, its own test gate,
and its own `IMPLEMENTATION_AUTHORIZED: YES` in
`docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md`. **The roadmap is unchanged by
this declaration**, and this declaration grants no roadmap, phase, contract, or
file authorization (§1.2, L-47; §1.4).

### 33.3 Registry state at freeze (unchanged — informational)

| Metric | Value at freeze | Changed by the freeze |
|---|---|---|
| Registered Open Question IDs (§24.3) | **84** | **0** |
| — `OPEN` | **48** | **0** |
| — `CLOSED` (§24.3.6) | **36** | **0** |
| — of which `MUST RESOLVE BEFORE FREEZE` | **0** | **0** |
| `LOCKED` decisions (§25.1) | **97** | **0** |
| `PROVISIONAL` values (§25.2) | **36** | **0** |
| `DEFERRED` items (§25.3) | **20** | **0** |
| §24.2 dependency records | **14** | **0** |
| Commercial decisions changed | **0** | **0** |

Severity and classification splits are informational and **unchanged**: 0
`CRITICAL` + 1 `HIGH` + 40 `MEDIUM` + 7 `LOW` = **48**; and **0** `MUST RESOLVE
BEFORE FREEZE` + 27 `REGISTER BEFORE FREEZE` + 4 `BUSINESS CENTER` + 10
`IMPLEMENTATION ARCHITECTURE` + 2 `DEFERRED` + 5 `LEGAL/POLICY REVIEW` = **48**.

**Counts are informational.** The tables in §24.3.1–§24.3.6 and §25.1–§25.3
remain the authority. The freeze **changed no count**; the figures above are the
post-A8 figures, unchanged.

### 33.4 Freeze integrity statement

This freeze declaration is **documentation and governance only**. It changes **0**
commercial decisions, closes **0** Open Questions, reclassifies **0** Open
Questions, adds **0** `LOCKED` / `PROVISIONAL` / `DEFERRED` entries, changes **0**
prices, and preserves all A3–A8 meaning. Nothing was invented, extrapolated, or
decided on the Document Owner's behalf. No commercial rule, price, plan,
entitlement, lifecycle, verification, publication, Sponsored, launch-density,
ownership, legal/policy, or language rule is added, removed, weakened, or
reinterpreted by this section.

END OF DOCUMENT