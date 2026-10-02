# Civilpedia — Commercial Publication & Entitlement Architecture Contract V1

CONTRACT_ID: C2
CONTRACT_VERSION: V1
DOCUMENT_STATUS: ACCEPTED — CANONICAL COMMERCIAL PUBLICATION & ENTITLEMENT CONCEPTUAL ARCHITECTURE AUTHORITY
FREEZE_STATE: ACCEPTED — CONCEPTUAL ARCHITECTURE ONLY
ARCHITECT_ACCEPTANCE: APPROVED
MODE: ARCHITECTURE / DOCUMENTATION ONLY
IMPLEMENTATION_AUTHORIZED: NO
PREPARED_DATE: 2026-10-02
REPOSITORY_BASELINE: main @ a3a161f15b90f8b0ae33c8e28cc8145628d3b542
LOCAL_ORIGIN_MAIN_BASELINE: a3a161f15b90f8b0ae33c8e28cc8145628d3b542
COMMERCIAL_POLICY_AUTHORITY: FROZEN Commercial Model V1, including A8 and §33
RECONCILIATION_AUTHORITY: ACCEPTED C1, including its §25 final acceptance record
ACCEPTANCE_AUTHORITY: ChatGPT Architect, under the existing Agent Operating Model
GIT_OWNER: User

## 1. Authority, purpose, and scope

C2 proposes the canonical conceptual architecture for commercial entitlement, publication eligibility and outcomes, paid and promotional clocks, Grace, renewal, reactivation, enforcement, closure, and launch-density qualification. It translates already frozen commercial behavior into explicit boundaries and precedence. It is a draft for Architect review; drafting does not constitute acceptance, freeze, or implementation authorization.

| Authority | Responsibility |
|---|---|
| [Commercial Model V1](../CIVILPEDIA_COMMERCIAL_MODEL_V1.md), current freeze §33 | Commercial-policy SSOT. Its LOCKED decisions govern; PROVISIONAL, DEFERRED, and OPEN items keep their existing classifications and owners. |
| [Accepted C1](CIVILPEDIA_COMMERCIAL_CORE_AUTHORITY_RECONCILIATION_CONTRACT_V1.md), current acceptance §25 | Reconciliation, state separation, security, foundation preservation, and compatibility boundaries. Earlier draft wording is superseded only as recorded by C1. |
| C2, once accepted | Publication and entitlement conceptual architecture within those authorities. No authority to amend commercial policy or reinterpret existing data. |
| Future explicitly authorized implementation contracts | Persistence, server enforcement, migration/compatibility, and focused verification within approved boundaries. Acceptance of a contract and authorization to implement remain separate. |

The authorized deliverable is this document alone. No table, column, stored enum, SQL predicate, RPC, RLS policy, scheduler/job, provider, state-management mechanism, cache/Realtime strategy, route, screen, or UI is chosen. No migration, production code, test, commercial-policy, C1, or roadmap edit is authorized. No staging, commit, or push is authorized.

The [Master Roadmap](../CIVILPEDIA_V1_MASTER_ROADMAP.md) remains phase/status SSOT: V1-R10.5-D is CURRENT for a focused pre-implementation audit, with implementation unauthorized. This separately requested C2 architecture document does not change that control or unlock any slice. The [Agent Operating Model](../CIVILPEDIA_AGENT_OPERATING_MODEL.md) continues to govern routing and acceptance.

Evidence is frozen policy and accepted C1 at the stated repository baseline. The latest relevant commercial review/acceptance evidence is C1 §25: independent focused re-review PASS / A and Architect acceptance APPROVED. C2 claims no new independent review or live/deployed commercial verification. Historical R05/R07/R08 reports cited by C1 and the current R10 contract's Appendix H remain historical evidence, not a fresh C2 runtime gate.

Principal policy anchors: §2, particularly §§2.1 and 2.5 (Paid-Only commercial model foundations); §§3, 5, 6 (Sponsored separation), 7–10, 13, 19; §§26.1–26.5 (L-55–L-61); §§27.1–27.3 (L-65–L-67); §§28.1–28.6, 28.8, 28.11–28.14; §§31.1–31.3; §§32.2, 32.5–32.7, 32.11; §33. Conceptual labels below are explanatory vocabulary, not persistence names.

## 2. Core state separation

These concerns must remain distinct even where one constrains another:

| Separation | Consequence |
|---|---|
| Payment Verification != Commercial Entitlement | Verified funds permit authorized paid activation under applicable terms; evidence or verification is not the complete entitlement decision. |
| Commercial Entitlement != Public Publication | An entitlement cannot satisfy missing quality, onboarding, moderation, or launch requirements. |
| Publication != Verification | A published profile does not gain Verified status by being public. |
| Verification != Sponsored | Trust checking does not create advertising rights or placement. |
| Entity Lifecycle != Subscription Lifecycle | Entity identity and operational condition survive changes in term validity. |
| Ownership != Entitlement | An owner association does not purchase or grant commercial benefits. |
| Moderation != Payment | Funds cannot approve content or override enforcement. |
| Application Activation != Publication | Existing application activation is not commercial publication approval. |
| Claimed != Primary Owner | A claim marker does not establish the accepted Primary Owner model. |
| Raw verification_status != Full Frozen Verified Authority | A raw engineering column cannot replace frozen evidence, authority, validity, and non-guarantee rules. |

Payment Verification Time != Subscription Term Start. Neither a single composite status nor a historical badge may erase the distinct authorities. A public projection may describe their combined outcome without becoming an authority source.

## 3. Commercial entitlement concept

A **Commercial Entitlement** is the authoritative commercial right of a genuine Business Entity to access the benefits of an approved commercial product and term, subject to its applicable eligibility, duration, and restrictions. It belongs to the Business Entity, not to the payer's or owner's personal account. The existence of the right, whether its term has begun, whether it is currently in effect, and whether public publication is permitted are separate questions.

| Frozen source | Conceptual treatment |
|---|---|
| Paid Business | Approved entry-plan benefits for the agreed paid term. |
| Paid Business Pro | Approved Pro benefits for the agreed paid term. |
| Paid Business Plus | Approved Plus benefits for the agreed paid term. |
| Corporate | Entitlement under an approved written quotation/agreement; see §23. |
| Eligible Founding Partner paid first-year term | Pricing treatment of an eligible paid term, with separate badge/history; not an additional free entitlement or a separate base plan. |
| A8 Launch Partner | Authorized temporary promotional Business Pro entitlement; see §14. |

Sponsored is a separate product. No mock/seed row, legacy plan value, Founding badge, ownership association, or receipt screenshot supplies entitlement. Paid terms require independently verified funds and satisfied approved commercial terms. Underpayment cannot activate until the required amount is satisfied or an explicitly approved adjustment exists. A third-party payer may be accepted only after explicit linkage to the intended Business/payment and gains no ownership by paying (policy §28.1).

Verified funds can support an authorized **pre-publication paid basis** whose clock is not yet running under §4. That basis must not be reported as successful publication or as an already consumed paid term. A valid promotional basis follows its own clock rather than fabricating a paid payment record. Rights for unrelated benefits and exact module access during pre-publication/Grace remain outside C2 where policy has not decided them.

## 4. Payment verification and paid term start

Policy §26.1 / L-55 governs ordinary paid subscriptions:

| Situation | Term anchor | Publication consequence |
|---|---|---|
| Payment awaiting verification | No paid activation on evidence alone. | Payment does not grant public presence. |
| Payment verified, preparation within the allowed window | Normal start awaits first successful public publication. | Profile still needs all applicable publication gates. |
| First successful public publication | Paid term normally starts on that successful publication. | Eligibility must have been established independently of the clock start. |
| Civilpedia delays publication | Start waits for actual successful publication. | A service delay does not fabricate publication or consume the paid term. |
| Still blocked after 14 calendar days solely by customer failure to supply required materials despite documented requests | Start is calendar day 15. | Starting the paid clock does not waive missing materials or publish the profile. |

The customer has **14 calendar days after payment verification** to supply required information/materials. The day-15 exception requires both sole customer responsibility and documented requests; elapsed time alone is insufficient. C2 does not broaden that exception to Civilpedia or mixed-cause delays.

**End date = start date + purchased duration.** Grace follows term expiry rather than consuming purchased days. Successful publication means actual public publication, not an instruction, an approval intent, an application activation, or a legacy lifecycle write. Implementation must later establish trustworthy evidence of these events and their causal basis. No event storage, date representation, timezone/day-boundary convention, calendar-month arithmetic mechanism, or scheduling mechanism is selected here.

The policy's §7.1 payment-flow “Active” step cannot override §26.1's later explicit term anchor or the separate quality/publication gates. A payment may be verified and a paid basis approved while publication and clock start remain pending.

## 5. Publication eligibility composition

**COMMERCIAL PUBLICATION ELIGIBLE** is a conceptual conclusion established from all applicable authoritative concerns, not a stored boolean or code predicate. Eligibility permits a publication transition; it is not proof that publication actually succeeded.

| Concern | Required conceptual evidence / boundary |
|---|---|
| Entity validity | A genuine valid Business Entity; stable canonical identity preserved under C1. |
| Commercial/category eligibility | The organization and category fit the approved model. §27.1 prohibits silently enrolling individual professionals and reserves engineering-office/consulting/laboratory/specialist models for their separate decisions. A8's illustrative cohort categories do not override that boundary. |
| Commercial basis | Approved paid entitlement/basis under its terms or an authorized A8 promotional basis. An explicit Grace continuation is treated separately under §12. |
| Required Fields Gate | Applicable pre-publication profile requirements are satisfied through authoritative validation, not an arbitrary public score. |
| Ownership/onboarding | Completed controlled owner-account/acceptance/required verification sequence for normal initial publication; see §8 for recovery continuity. |
| Moderation | Applicable content review, sensitive-change handling, and any specifically required verification are satisfied. No payment shortcut. |
| Enforcement and operation | No applicable suspension, termination, or confirmed permanent-closure override. |
| Launch context | Applicable category/geography launch constraints are satisfied for the intended public discovery context. Category opening is separately governed; see §§20–21. |

No universal **Verified badge** prerequisite is introduced. Required ownership verification or a circumstance-specific verification review is not equivalent to requiring every Business to hold the full public Verified trust state.

Distinguish **initial publication/republication readiness**, **continued visibility**, and **category discovery opening**. Grace explicitly preserves an already public profile subject to stronger overrides. Ownership recovery does not automatically remove it. Consequences of a known post-publication quality shortfall remain OQ-48; C2 must not convert an initial-publication gate into an invented automatic takedown policy.

Eligibility cannot be inferred solely from `lifecycle_status = active`, `claim_status = claimed`, application `ACTIVATED`, or subscription `status = active`. Missing or malformed required authoritative evidence does not establish eligibility (§24). Exact approval actor/process remains OQ-49; “server-enforced” does not decide staff-only approval versus authorized automated validation plus audit.

## 6. Publication outcomes

These are conceptual outcomes, not implementation enum names:

| Outcome | Meaning |
|---|---|
| Not yet publicly publishable | Initial requirements remain incomplete/unconfirmed; no normal commercial publication. The Business record and preparation may still exist. |
| Publicly visible / published | Successful public publication within applicable authority and launch constraints, or policy-permitted continued visibility such as Grace. Visibility alone does not prove an active paid term, Verified, or Sponsored. |
| Temporarily hidden | Normal public listing unavailable due to the applicable expiry/enforcement/review restriction; identity and retained data are not erased. Recovery depends on the reason for hiding. |
| Permanently closed / inactive public condition | Confirmed closure excludes discovery. A historic direct link must communicate inactivity rather than misleading active information; its exact experience remains OQ-68. |

Termination excludes ordinary publication/discovery under enforcement policy; it is not a payment-expiry label and does not imply the same historic-link experience as voluntary closure. C2 chooses no direct-link screen, retained public fields, or route behavior for hidden/terminated records.

Existing Directory lifecycle values remain engineering reality, not aliases of these outcomes. Publication eligibility and actual visibility must not be conflated in reporting or term anchoring.

## 7. Required Fields Gate

**Minimum Profile Quality = Required Fields Gate**, not an arbitrary public numerical score (policy §28.6 / L-76). Before initial publication, incomplete required information means Draft / not publishable. Payment or an A8 invitation cannot waive the gate.

C2 preserves the frozen minimum content areas in §28.6.2 without inventing exact field keys, validation thresholds, category-specific lists, media counts, or a score. The exact applicable matrix/validation and Business Center experience remain OQ-76, with Business / Branch and Taxonomy contracts supplying their authorized domain definitions. Media limits remain OQ-16.

The outcome when an **already published** profile later falls below the gate remains **OQ-48**. C2 does not choose automatic hiding, a cure window, partial display, or an exemption for that case. This residual differs from inability to establish required authority because it is missing/malformed: the latter cannot be converted into a grant under §24.

## 8. Ownership and onboarding interaction

For normal initial public commercial publication, a genuine Business must complete controlled onboarding: an identifiable owner creates their own Civilpedia account, receives the controlled ownership invitation/link, and accepts ownership with required verification before content review and publication (policy §27.2, §§32.5–32.7).

A Civilpedia-managed Draft may exist before an owner is attached. It is not ownership evidence or permission to publish. A pending invitation grants no ownership authority. Normal operation has exactly one Primary Business Owner, with optional verified Co-Owners under applicable limits (§31.2); existing `OWNER` / `ADMIN` / `MEMBER` values are not mapped by C2.

Direct assignment is an **admin-only exceptional** capability to an already identifiable account, with required ownership verification preserved and auditable acting admin, Business, target user, assigned capability, timestamp, and reason/context where required. Emergency override controls remain deferred. No shared account, password creation/handover, or open public Claim flow is permitted.

For an already operating Business in **OWNERSHIP RECOVERY PENDING**, entity data and subscription remain attached to that Business. Public visibility need not be automatically removed solely because recovery is pending; fraud/security/moderation restrictions may require removal. Ownership-sensitive actions may be restricted while Civilpedia verifies a replacement. This exception preserves §31.2.7, not a route for publishing never-owned Drafts.

OQ-79 ownership evidence, OQ-83 invitation lifecycle, OQ-82 never-owned Draft disposition, and OQ-71/OQ-78 transfer edge cases remain open. C2 chooses no roles, grants, storage/cardinality mechanism, invitation transport, or ownership-dispute procedure.

## 9. Verification interaction

Verification is an independent trust state (policy §28.4 / L-74; C1 §4.1): **Paid != Verified; Published != Verified; renewal != re-verification**. Only authorized Civilpedia authority grants or withdraws it using reasonably necessary accepted evidence.

There is no automatic fixed 12-month expiry merely because time passes. Material/sensitive changes, risk, suspected fraud, ownership or identity/location changes, and Civilpedia review requirements can trigger re-verification. Verification becomes inactive on suspension, termination, or permanent closure; false/forged evidence can cause withdrawal and enforcement.

Verified signifies checked defined identity/business information. It is not endorsement, a workmanship/quality guarantee, a commercial-outcome guarantee, or a guarantee of Business claims. No payment, promotion, renewal, or campaign can purchase it. Appropriate re-verification is required for reopening the same genuine permanently closed entity (§18); that circumstance does not become a universal initial-publication badge requirement.

Per-category evidence, workflow, granularity, appeals, reviewer capability/storage, and public wording remain with Verification / Moderation and their existing OQs. C2 does not redefine them or treat raw `verification_status` as full authority.

## 10. Ordinary paid lifecycle

| Conceptual situation | Commercial behavior | Publication boundary |
|---|---|---|
| Payment awaiting verification | Receipt/funds require independent authorized verification. | No paid activation or automatic publication. |
| Verified but pre-publication | Approved paid basis exists; normal clock awaits successful publication, subject to §4's narrow day-15 exception. | Required gates remain independent. |
| Paid term in effect | Purchased benefits apply under approved terms; clock follows its established anchor/end. | Eligible publication can continue; overrides still apply. |
| Approaching expiry | Existing entitlement remains until its end; frozen reminder rules apply. | No new publication or verification rights are created. |
| Term expired, within Grace | Exactly 5 calendar days after expiry; data retained and already public profile remains visible subject to stronger overrides. | Grace is a limited continuation basis, not an extra active paid term. |
| Grace ended without valid replacement | Business hidden from the public Directory, data retained. | Later payment follows reactivation. |
| Later reactivation | Independently verified payment plus continuing eligibility and successful republication. | New term is non-retroactive. |

Business / Pro / Plus offer **1, 3, or 12 months**; no 6-month term. Corporate is written/custom quotation with a **minimum 12-month commitment**. C2 changes no approved price or purchased duration and does not convert calendar months into invented fixed-day durations.

Identity, Branches, memberships, content, images, products/projects/offers, and history survive expiry under frozen retention rules. Hiding is not deletion or rebuilding. A day-15 term may run while a never-published profile is still incomplete: expiry/Grace do not give that profile an initial publication bypass.

## 11. Renewal

Renewal is manual only: **no auto-renewal, no auto-charge, no stored payment instrument**. Every renewal payment is independently verified (policy §26.2 / L-56).

| Verified renewal timing | Term consequence |
|---|---|
| Before the existing paid end date | Extend from that end date; preserve all remaining purchased days. |
| During Grace | Extend from the **original / previous paid expiry**, not the renewal date; continuity is preserved. |
| After Grace ended and hiding applies | Reactivation under §13, not retroactive renewal. |

Grace is not additional free paid-term time. Money sent or an unverified receipt does not postpone hiding or create continuity. Payment received after Grace expiry is reactivation under §28.1. Pending-verification cutover/event-order handling must be specified by later contracts without changing these policy outcomes; C2 chooses no additional deadline exception.

Renewal does not buy Verified or override suspension/closure. Official renewal pricing follows §26.3 unless an explicit approved promotion applies; an already-paid unexpired term is not retroactively repriced. Exact billing/payment reconciliation and proration remain deferred.

## 12. Grace

Grace is exactly **5 calendar days after term expiry**. It preserves public visibility of the already published profile, data, and identity while renewal/conversion is outstanding. It does not mean that the expired entitlement is still in effect, nor extend the purchased end date.

**Policy composition trace clarification:** the Commercial Model's general publication composition rule in §8.2 is read together with its specific frozen Grace visibility rule in §26.2.7. Grace visibility is an explicit exception / continuation after paid-term expiry; it does not make Grace a normal active paid entitlement or collapse entitlement and publication states. This records existing frozen meaning only.

The frozen reminder cadence in §26.2 / L-57 uses the term end as T, with Grace messaging T+4 and hiding T+5. Annual/monthly/3-month pre-expiry cadence, payment-pending messaging, immediate suppression once renewal is verified, and exact customer-facing dates remain policy obligations; C2 chooses no messaging/channel implementation. Calendar-boundary representation remains deferred, not a license to lengthen Grace.

Suspension, termination, or confirmed permanent closure overrides Grace visibility. Grace cannot first publish an incomplete Draft. At its end, absent valid renewal/replacement and applicable publication eligibility, the public profile is hidden.

Grace does not establish Sponsored eligibility or launch-density qualification by visibility alone. It supplies no A8 promotional counting after that entitlement expires. Business Center read/write mode and owner view during Grace remain **OQ-12**; analytics/history visibility remains **OQ-17**. C2 makes no broader benefit-access grant during Grace.

## 13. Reactivation

After Grace ended and the profile is hidden, later payment is **Reactivation**. It requires independently verified payment, continuing genuine Business and publication eligibility, removal of applicable publication blockers through their authorized processes, and successful republication.

The new paid term begins only after verified payment and successful republication, **never retroactively from the old expiry** (§26.2.10–§26.2.11). Verified payment alone cannot restore visibility. Earlier paid-term debt or forfeited days are not invented by C2. Reuse retained content/identity rather than requiring a rebuilt profile.

Reactivation after expiry is distinct from release of suspension, appeal of termination, and reopening a permanently closed Business. A payment cannot perform those transitions. C2 does not extend the initial day-15 exception into automatic publication or a retroactive reactivation anchor.

## 14. Launch Partner promotional entitlement

Policy §32.2 / L-89 controls the **Founding Launch Partner Program**, referred to here as Launch Partner to preserve its distinction from paid Founding Partner pricing:

| Dimension | Frozen behavior |
|---|---|
| Selection | Civilpedia-controlled, invitation-only initial cohort of approximately 20–30 eligible commercial Businesses; quality/category diversity over raw count. Not automatic for every Business. |
| Benefits and price | Business Pro at **0 IQD for 60 calendar days**. Temporary promotional entitlement, not a permanent free tier or ordinary paid term. |
| Start anchor | The **later of formal commercial launch or the Business's first successful public publication after that launch**. Draft creation does not start the clock. |
| Payment instrument | No card/payment instrument required; no automatic renewal or charge. Do not fabricate paid payment verification for a 0 IQD promotion. |
| Abuse/continuity | Normally once per genuine Business Entity; duplicate entities/accounts cannot farm access. |
| Expiry | May convert to eligible paid Business / Pro / Plus / Corporate. Without a verified paid subscription by expiry, normal 5-day Grace then public hiding applies; data is not automatically deleted. |

The 60-day period follows its explicit A8 anchor. The ordinary paid day-15 rule governs **paid subscriptions**, not this promotion. Selection/invitation, a prepared Draft, or a launch forecast is not proof that promotional time is already in effect.

At promotional expiry, A8-based launch-density counting stops immediately unless another valid qualifying entitlement applies, even while the profile remains visible under Grace. Pre-expiry factual metrics reporting does not extend eligibility or promotional days.

Conversion requires a separately approved paid basis and independent payment verification. Exact conversion scheduling, period overlap/cutover, and persistence must later preserve the frozen paid and promotional anchor rules without inventing an automatic grace-based paid anchor or forfeiting benefits. C2 chooses none of those mechanisms.

Cohort selection/cap tracking, exhaustion, revocation/withdrawal and remaining days are **OQ-80**. Exceptions to “normally once” and promotional continuity on ownership/entity change are **OQ-81**. Duplicate detection is **OQ-72**. They remain unresolved; C2 does not promise rollover, reset, forfeiture, or another promotion. Existing `trialing` is not mapped to Launch Partner.

## 15. Founding Partner interaction

Founding Partner is the eligible **initial first-50 cohort's paid first-year pricing**, separate from its historical badge/status (§5, §26.3). The discount is not permanent; subsequent renewal uses applicable standard/approved pricing. Badge/history continuity does not establish current entitlement or active operation.

A Business eligible for both programs may receive temporary Launch Partner Pro access first and eligible Founding Partner paid first-year pricing later under their respective rules. C2 does not expand eligibility, define the first-50 counter, promise a later cohort, or invent first-term 1/3-month Founding prices (OQ-01/OQ-02). Neither program is Sponsored, generic legacy `trialing`, or permanent free listing.

## 16. Suspension

The conceptual enforcement path is **Active → Warning / Correction Required → Suspended → Terminated**; this is not a required linear stored state machine. A non-serious correctable violation gets a **7-calendar-day correction window**. Serious violations may require immediate suspension; no mandatory warning delay is imposed in that case (policy §26.4 / L-59–L-60).

During suspension, the public profile is hidden, Sponsored suppressed, relevant restricted actions may be blocked, and data is retained. The owner retains Business Center access unless security/fraud circumstances require otherwise; exact capabilities are not designed here. Verification becomes inactive under §28.4.

Customer-caused suspension does not pause the paid clock. A suspension determined to be Civilpedia error requires equivalent service time restored as service credit/term extension. C2 selects no credit calculation or ledger mechanism. A surviving entitlement does not defeat the publication override; expiry and suspension remain independent and may coexist.

Payment for a suspended/closed/invalid Business is not activated as a bypass (§28.1). Later authorized restoration must address the enforcement cause and remaining publication gates; C2 does not make payment alone a release action or an automatic clock reset.

## 17. Termination

Frozen grounds include material fraud, forged evidence, impersonation, serious/repeated violations, and persistent failure to cure material violations (§26.4 / L-60). Termination removes the profile from discovery, stops Sponsored, and makes verification inactive. Valid historical payment or an unexpired term cannot compel publication after termination.

There is no automatic refund for customer-caused termination. Civilpedia-caused service failure may receive proportional refund/service credit under the future refund policy; amounts, timelines, and legal drafting are not chosen here.

The frozen termination appeal is **one appeal within 7 days**. Appeal is distinct from payment, renewal, and publication; serious-risk content may remain hidden during appeal. C2 chooses no appeal process or automatic reinstatement and does not generalize termination's appeal rule to content/verification appeals. Those procedures and policy residuals stay with their authorities.

## 18. Permanent closure

The operational concept is **Operating → Closure Requested → Permanently Closed** (policy §26.5 / L-61). C2 does not treat a request as confirmation or decide who confirms it or the request workflow.

Confirmed closure overrides ordinary publication independently of entitlement: remove discovery, stop Sponsored, make verification inactive, and close affected Branches appropriately. Retain private Business/history records under the applicable retention policy; no automatic deletion or refund for voluntary closure. A historical Founding badge cannot imply that the Business remains active.

A historic direct link must communicate that the Business is no longer active. Exact retained public content/screen behavior remains OQ-68. The same genuine Business may reopen after appropriate re-verification and satisfaction of applicable publication/entitlement requirements. Materially different ownership/legal identity requires controlled transfer/new-entity assessment. Closure-request authority, branch mechanics, and inactive-entity transfers remain unresolved where registered; reopening cannot be achieved merely by paying or restoring a legacy active value.

## 19. Entitlement / publication precedence matrix

These are conceptual outcomes, not SQL truth tables. Rows compose independent concerns; no row silently clears another restriction. Stronger enforcement/confirmed closure overrides ordinary entitlement and Grace. Missing required authority cannot be treated as a permissive default.

| Situation | Publication / term outcome | Other boundary |
|---|---|---|
| Valid approved entitlement/basis + all applicable publication gates | May be successfully published; then applicable clock anchor is established. | Eligibility alone is not actual publication. |
| Valid entitlement + suspension | Hidden. | Sponsored suppressed; customer-caused paid clock continues. |
| Historical/valid payment or entitlement + termination | No ordinary public publication/discovery. | Payment does not reverse enforcement; appeal separate. |
| Valid entitlement + confirmed permanent closure | Not in discovery; historic link communicates inactivity. | Sponsored stopped; verification inactive; no automatic deletion. |
| Term expired + within Grace + previously public + no stronger override | Remains visible for the 5-day Grace. | Paid/promotional term is not extended; benefits/counting cannot be inferred from visibility. |
| No replacement entitlement + Grace ended | Hidden. | Later payment is non-retroactive reactivation. |
| Verified payment + missing materials within the 14-day initial window | No publication; normal paid clock waits. | Civilpedia-caused delay still waits for actual publication. |
| Sole documented customer delay beyond that window | Paid term starts on calendar day 15, still unpublished if incomplete. | No quality/onboarding bypass. |
| Valid A8 entitlement/basis + applicable publication eligibility | May publish under A8; clock follows its anchor. | Count only while A8 entitlement is in effect and density requirements hold. |
| A8 expired + profile still visible in Grace | Grace visibility may continue. | A8-based density counting stops; metrics do not extend promotion. |
| Initial profile incomplete or normal ownership acceptance pending | Not publishable. | Paid/promo basis cannot complete missing prerequisites. |
| Existing operating Business in ownership recovery, no fraud/security/moderation blocker | Recovery alone need not remove visibility. | No grant to publish never-owned Drafts; sensitive actions may be restricted. |
| Known quality shortfall after publication | No new C2 automatic takedown/cure policy. | OQ-48 must be explicitly decided; required-authority uncertainty still fails closed. |
| Suspended/terminated/closed while otherwise in Grace | Enforcement/closure outcome wins. | Grace is not immunity from restrictions. |

Warning/correction required is not automatically identical to suspension. Lifting an override does not automatically confer entitlement, publication, verification, or Sponsored; each applicable authority must support the resulting state. C2 does not choose a priority code, reason enum, or mechanism for recording multiple simultaneous causes.

## 20. Launch-density qualification

Policy §31.3 / L-87, §32.11 / L-97, and C1 §7.1 / AR-14 govern **COMMERCIAL-ACTIVE** launch supply. Qualification is separate from visible profile count:

| Dimension | Conceptual requirement |
|---|---|
| Business | Genuine valid eligible Business Entity, not fake/mock/duplicate padding. |
| Commercial basis | Qualifying in-effect commercial entitlement: normal active paid basis, or the narrow authorized A8 basis during the initial Launch Partner phase. |
| Publishability | Profile satisfies applicable individual public-publication requirements, with no enforcement/closure blocker. An actually public record must remain appropriately publishable; a raw active marker is insufficient. |
| Category | Applicable approved launch category; unsupported categories cannot be counted by a label alone. |
| Geography | Applicable Baghdad launch market; presence elsewhere is not automatic expansion authority. |

The normal opening gate is **at least 5 qualifying Businesses** in the applicable Baghdad category. Preserve the approximately **8–10 active paid Businesses per category** growth target and approximately **30 active paid publishable Businesses** formal launch-push target as readiness targets, not customer guarantees. A8 does not lower the gate or turn the targets into guarantees.

To avoid conflating individual publishability with category opening, **per-Business readiness is assessed separately from the aggregate category-opening decision**. The count may rely on policy-qualified publicly publishable Businesses; it must not require a category already to be opened merely to evaluate its opening readiness. This conceptual separation chooses no pre-launch publication exception or counting algorithm. Prepared/selected but not yet in-effect promotions cannot be falsely counted as current A8 entitlement. Evidence of formal launch, publication, term validity, and coordinated opening remains a later enforcement obligation; no invented “active” placeholder may bypass the clocks.

During the initial Launch Partner phase, an authorized Launch Partner counts only while its promotional entitlement is **in effect** and the profile remains publicly publishable. At expiry, it stops counting on A8 even if visible in Grace, unless another valid qualifying entitlement applies. Ordinary post-launch paid operation retains its paid basis; pre-expiry metric reporting is unrelated to entitlement validity.

The 5-Business gate is an **initial launch gate**, not a perpetual automatic shutdown threshold: an ordinary launched category does not automatically close solely because count drops from 5 to 4. At zero active publishable Businesses, show an honest empty/unavailable state; no stale/fake padding. Below-gate categories must avoid misleading normal discovery and may be hidden or represented by Coming Soon under later UX decisions.

**OQ-84 remains open** for post-promotion treatment of a category initially opened partly with Launch Partners. C2 must not use the ordinary non-shutdown rule to choose among OQ-84's re-gating/Coming Soon/continuation alternatives. Category visibility cannot be a pure static admin flag bypassing frozen density rules. No counting SQL, aggregation, geography representation, stored launch state, job, UI, or freshness mechanism is selected.

## 21. Baghdad-first constraint

**BAGHDAD FIRST.** Initial launch uses a focused group of commercially meaningful categories in the applicable Baghdad market. Expansion beyond Baghdad requires supply/demand readiness and an **explicit later commercial/product decision** (§31.3.11). Technically valid entities, locations, taxonomy labels, or paid records elsewhere cannot imply global commercial launch.

C2 neither selects regions/coordinates nor automatically grants or cancels an out-of-market entitlement. It preserves the independent launch constraint on public discovery; any such commercial sale/publication scenario must be resolved under its proper explicit scope rather than by interpreting legacy geography data.

## 22. Sponsored interaction

Sponsored is separate from base entitlement, verification, and organic ranking. Every surface must clearly identify paid advertising; organic ranking remains commercially independent (§6, §28.3 / L-73).

Initial Pro/Plus eligibility follows frozen policy and additionally requires publishability, profile-quality compliance, and content related to the real Business. Verified is not required solely to buy Sponsored. A base Pro/Plus entitlement does not itself create a campaign, inventory slot, active delivery, or advertising payment approval. Grace visibility and A8 Pro access must not be silently interpreted as a complete Sponsored grant; apply the separate product rules and future authorized reconciliation.

Suspension suppresses Sponsored; termination/closure stops it. Sponsored time begins when placement actually becomes public/available. Customer-caused suppression does not automatically pause its time; Civilpedia-caused non-delivery restores equivalent placement time or appropriate credit/refund. C2 designs no inventory, rotation, payment, campaign storage, branch product, or delivery mechanism. Existing Sponsored seams remain evidence of reusable engineering, not an operational commercial backend.

## 23. Corporate

Corporate is a valid quotation-based commercial entitlement family: **Custom Quote**, **minimum 12-month commitment**, and **all Business Plus entitlements as a minimum floor** (§31.1 / L-84–L-85). A written quotation may extend permitted branch/team/service/media/analytics/add-on scale. It is not a fixed retail price row or an invented unlimited entitlement.

Default quotation validity is **30 calendar days unless explicitly stated otherwise**. The quotation identifies the Business, Corporate plan, subscription duration, total price/payment terms, included Branches, relevant team allowance, material benefits/services, separately priced add-ons, and expiry. Individually approved written Corporate payment terms follow §28.12; C2 does not impose a new blanket prepaid-only rule on them or invent instalment activation conditions. Payment verification, publication gates, clocks, and overrides still retain separate authority subject to approved written terms. Exact representation/enforcement is deferred.

## 24. Publication fail-closed principle

Where a required authoritative publication condition is missing, malformed, unknown, or unreconciled, **commercial publication must fail closed**: no affirmative grant based on incomplete authority. Do not self-grant from client input, a legacy active value, a cached projection, or an inferred payment/role mapping.

This does not delete data, revoke membership by inference, or authorize an immediate rewrite of accepted existing production behavior. Applying this boundary to existing rows requires the later explicit reconciliation/migration and authorized implementation. A known open policy case is not permission to invent its outcome; notably OQ-48 remains open rather than being silently “resolved” by a blanket post-publication quality takedown.

Later publication/freshness contracts must prevent stale public snapshots from restoring hidden/closed/revoked access and preserve safe known-good resilience where compatible. They must address complete/bounded public catalogs and trustworthy current decisions under C1 AR-12. No TTL, invalidation, polling, Realtime, Remote Config, pagination, or cache migration is chosen here.

## 25. Existing engineering reconciliation

| Existing artifact | Prohibited equivalence |
|---|---|
| `directory_entities.lifecycle_status` | Not the composite commercial publication decision or entitlement. |
| `subscriptions.status` | Not an accepted mapping of paid/promotional term, Grace, or publication behavior; `trialing` is not A8. |
| `business_applications.status` | Activation is not payment, accepted commercial onboarding completion, or publication. |
| `claim_status` | Claimed is not a unique accepted Primary Owner or permission for open public claiming. |
| `verification_status` | Not the full frozen Verified authority or a purchased trust state. |

C1 records that current public reads use entity lifecycle `active`, child reads follow active-parent authority, and subscriptions are not composed into that gate. That remains accepted engineering reality until separately authorized change. C2 does not re-label rows, backfill payment/entitlement, grandfather mock data, or reinterpret current statuses by naming alone.

Later implementation/migration must explicitly reconcile state/event meanings and existing rows, preserve canonical UUIDs, public/Saved references, memberships, applications/claim history, audit history, auth/session boundaries, and existing concurrency/validation protections. Any required changed public behavior needs an explicit cutover/compatibility contract. No destructive migration is permitted without its dedicated scope and validation/recovery obligations.

All **C1 AR-01 through AR-14 remain OPEN / deferred and unchanged**. C2 narrows conceptual ambiguity for future Publication / Entitlement work but closes no C1 implementation/data mapping and no future contract family. OQ-22 seed/legacy disposition is unchanged.

## 26. C2 architecture decision register

### 26.1 A — Resolved conceptual architecture in this draft

“RESOLVED — CONCEPTUAL DRAFT” means that C2 states a determinate policy-backed conceptual position for review. It does not self-declare Architect acceptance, implementation readiness, or resolution of a Frozen Commercial Model OQ/C1 AR. No item below defines persistence.

| ID | Draft conceptual position | Policy / C1 trace | Status |
|---|---|---|---|
| C2-AR-01 | Business-associated commercial rights; paid/Corporate/promo bases distinct; Founding is paid pricing/history. | Policy §2 (particularly §§2.1, 2.5), §§3, 5, 6, 31.1, 32.2; C1 §§4, 11–12 | RESOLVED — CONCEPTUAL DRAFT |
| C2-AR-02 | Publication eligibility composes entity/model, commercial basis, quality, onboarding, moderation, overrides, and launch context; eligibility != successful publication. | Policy §§19, 27.1–27.2, 28.6, 32.5.6; C1 §7 | RESOLVED — CONCEPTUAL DRAFT |
| C2-AR-03 | Payment verification separate from start; normal publication anchor; 14-day materials window and narrow documented customer-delay day-15 exception. | Policy §26.1 / L-55; C1 §11 | RESOLVED — CONCEPTUAL DRAFT |
| C2-AR-04 | Five-day Grace after expiry preserves prior visibility under stronger overrides, without extending active term or A8 counting. | Policy §26.2, §32.11; C1 §§7, 12 | RESOLVED — CONCEPTUAL DRAFT |
| C2-AR-05 | Manual independently verified renewal; early/Grace extension from previous paid end, never the Grace renewal date. | Policy §26.2 / L-56 | RESOLVED — CONCEPTUAL DRAFT |
| C2-AR-06 | After hiding, reactivation requires verified payment + eligibility + successful republication; non-retroactive. | Policy §§26.2.10–26.2.11, 28.1 | RESOLVED — CONCEPTUAL DRAFT |
| C2-AR-07 | A8 authorized Pro, 0 IQD/60 days, later-of-launch/publication anchor; normally once; distinct from paid Founding and legacy trialing. | Policy §32.2 / L-89; C1 §12 | RESOLVED — CONCEPTUAL DRAFT |
| C2-AR-08 | Suspension overrides public publication despite entitlement; customer-caused clock continues; error credit/extension preserved. | Policy §26.4 / L-59; C1 §§4, 7 | RESOLVED — CONCEPTUAL DRAFT |
| C2-AR-09 | Confirmed closure overrides discovery, stops Sponsored, inactivates verification, preserves private history; controlled genuine-entity reopening. | Policy §26.5 / L-61; C1 §§4, 21 | RESOLVED — CONCEPTUAL DRAFT |
| C2-AR-10 | Launch-density qualification requires valid in-effect basis + publishability + category/Baghdad geography; five is a launch gate; A8 expiry stops its counting. | Policy §§31.3, 32.11; C1 §7.1 / AR-14 | RESOLVED — CONCEPTUAL DRAFT; OQ-84 unchanged |
| C2-AR-11 | Existing engineering states have no automatic commercial equivalence; explicit mapping/migration required. | Policy §8.4; C1 §§3, 21–22 | RESOLVED — CONCEPTUAL BOUNDARY; mapping DEFERRED |
| C2-AR-12 | Missing/malformed/unreconciled required authority grants no publication; enforce on server in future authorized implementation. | C1 §§20–21; policy §§19, 32.5.6 | RESOLVED — CONCEPTUAL DRAFT; enforcement DEFERRED |

Termination override is explicit in §§17 and 19; independent verification is explicit in §9. They require no invented policy decision or storage choice.

### 26.2 B — Deferred implementation decisions

| Deferred decision | Required future obligation |
|---|---|
| Entitlement representation | Explicit approved-product/term/Corporate/promo mapping, compatible with existing subscriptions and rows; no legacy equivalence by default. |
| Clock/event evidence | Trustworthy payment verification, publication/republication, formal launch, sole-customer-delay evidence, start/end/Grace dates, and payment cutover; define date/calendar representation without altering frozen durations. |
| Publication enforcement | Approved server authority and eligibility/override handling; decide persistence, read/write enforcement, and event ordering only within a later authorized contract. |
| Paid/promo conversion and reconciliation | Preserve both anchors, approved terms, independently verified paid conversion, continuity, and no automatic promotional renewal/forfeiture invented by mechanism. |
| Ownership/moderation interfaces | Required authoritative capabilities and validation, without mapping existing roles or answering unresolved approval/evidence policy. |
| Density/geography integration | Supported taxonomy/geography, qualifying evidence, coordinated category opening, complete counts, and no static visibility bypass; OQ-84 decision kept separate. |
| Public freshness | Revocation/hidden-state safety, catalog completeness, offline compatibility, and snapshot reconciliation; mechanism unselected. |
| Finance/audit/security | Narrow explicit permissions, verified transfer linkage, antifraud mechanisms, private projections, auditable clock/override/credit decisions, and protected concurrent writes. |
| Migration/cutover | Existing data disposition, stable identity/reference preservation, compatibility, validation and recovery; no silent backfill or destructive conversion. |
| Product presentation | Business Center access modes, notifications, exact Arabic localization through the canonical SSOT, and inactive/direct-link UX; no new route/UI in C2. |

These are obligations for future contracting, not permission to begin those contracts or implementation.

### 26.3 C — Existing open commercial-policy and adjacent dependencies

The authoritative status, severity, owner, and classification remain those in **policy §24.3**. This dependency view is not a replacement register and changes none of them. Closed questions (such as OQ-25 term anchor, OQ-29 renewal, OQ-30 enforcement, OQ-36 closure, OQ-37 density, OQ-47 initial gate, and OQ-20 cardinality) are not reopened.

| Existing OPEN dependency | C2 boundary / remaining matter |
|---|---|
| OQ-01 / OQ-02 | Founding first-term short-duration prices and first-50 counter; no new eligibility/counter rule. |
| OQ-09 / OQ-10 / OQ-23 | Approved payment destinations/rails, antifraud mechanisms, plan/price/currency representation; IQD and exception outcomes already frozen. |
| OQ-12 | Grace management access/read-write mode and owner view; visibility/duration already decided. |
| OQ-13 / OQ-14 / OQ-52 / OQ-56 / OQ-57 | Verification evidence/appeals/granularity, badge/copy, reviewer roles/change history, and content-rejection appeal; no workflow chosen. |
| OQ-16 / OQ-76 / OQ-77 | Media limits, exact category gate matrix/UX, and Business Center architecture. |
| OQ-17 | Analytics counting/retention and expired/promotional history visibility; metrics are not entitlement. |
| OQ-19 / OQ-54 | Branch/legal-entity and lifecycle consequences; closure principle does not decide mechanics. |
| OQ-22 | Launch disposition of existing/seed rows; no grandfathered production entitlement. |
| OQ-40 | Exact statutory retention/deletion periods; private evidence remains private, no invented period. |
| OQ-48 / OQ-49 | Post-publication quality shortfall consequences; publication approval actor/process. Server enforcement does not settle either. |
| OQ-68 | Exact inactive direct-link experience; frozen inactivity honesty already applies. |
| OQ-71 / OQ-78 / OQ-79 | Non-active entity transfers, prior non-owner memberships, and ownership evidence/legal edges. |
| OQ-72 | Duplicate-entity detection basis and merge/retirement mechanics, including Launch Partner once-per-genuine-Entity enforcement. Remains OPEN under its existing policy §24.3 classification; no mechanism or answer chosen. |
| OQ-80 / OQ-81 | Launch cohort lifecycle/revocation and promotional continuity/once-only exceptions. |
| OQ-82 / OQ-83 | Never-owned Draft disposition and invitation expiry/decline/re-invitation/alternate invitee. |
| OQ-84 | Post-promotion treatment of categories opened partly with A8 supply; no re-gating/continuation decision. |
| P-34, §28.2, §30 / D-19 | Proration calculation, refund detail and legal-policy obligations; C2 specifies no formula, statutory period, or legal text. |

Unlisted unrelated OQs remain unchanged as well. If a later implementation boundary depends on an unresolved commercial decision, route it to its existing Owner/Architect/legal authority before that dependent behavior is frozen or implemented. A non-blocking commercial freeze classification is not permission to infer an answer.

## 27. Future contract dependencies

| Family | C2 dependency; no authorization granted |
|---|---|
| Subscription / Entitlement persistence | Approved term/product/source representation, clocks, renewal/conversion and Corporate enforcement. |
| Publication Lifecycle server enforcement | Composition, actual publication evidence, overrides, public access and cutover. |
| Ownership / Invitation / RBAC | Accepted ownership/capabilities, recovery continuity, invitation and transfer boundaries. |
| Taxonomy / Commercial Catalog | Eligible categories, launch geography/density, supported server-managed catalogs and complete projections. |
| Business / Branch | Genuine entity/Branch boundaries, required information and closure effects. |
| Verification / Moderation | Full Verified mapping, circumstance-specific checks, sensitive edits and authorized review. |
| Admin Authority | Explicit narrow payment/publication/enforcement permissions, provisioning and audit. |
| Business Center | Private status and authorized management, unresolved Grace access and exact UX. |
| Payment Operations | Authorized verification, approved rails, exception reconciliation, credits and private evidence. |
| Analytics | Honest interaction metrics, counting/retention and permitted business reporting. |
| Sponsored | Separate eligibility/inventory/delivery/payment and suppression lifecycle. |
| Migration / Compatibility | Existing row/state mapping, identity/history preservation, cutover, validation and recovery. |

Grouping, dependencies, order, and scope require later Architect decisions. C2 chooses no new roadmap slice or execution sequence and closes no C1 deferred family. A future accepted contract still needs separate implementation authorization and the appropriate authorized roadmap boundary.

## 28. Security invariants

1. Clients cannot self-grant entitlement, verify payment, self-publish, clear enforcement, or self-verify. UI, routes, local flags, caches, and personal profile roles are not authority.
2. Future publication and entitlement decisions are server-enforced against the authentic actor, target Business, and explicit capability. C2 chooses no SQL/RPC/RLS or staff-only-versus-automated approval model (OQ-49).
3. A screenshot/receipt alone is not activation. Only explicitly authorized finance/admin authority verifies/refunds/credits payment; independently verify every renewal and link third-party payments explicitly. Staff overrides cannot waive frozen policy by discretion.
4. Subscription/financial state, receipts, verification/ownership evidence, internal antifraud/staff notes, and sensitive references are private by default. Public catalog/marketing labels do not make Business billing public. Financial visibility follows policy §28.11; no broader membership-based grant.
5. Unknown/malformed required authority fails closed. Suspended/terminated/closed overrides cannot be defeated by historical payment, Grace, a badge, cache, or stale asynchronous result.
6. No Flutter `service_role` or equivalent privileged client secret. Preserve one production Supabase authority, one AuthProvider, canonical auth identity, session-generation guards, and private-data clearing on session or permission loss.
7. Staff decisions and exceptional assignments require attributable audit. Future invariant-bearing writes preserve server validation, transactional consistency, locking/version protections, and audit linkage; no blind automatic mutation retry.
8. Preserve canonical entity identity, memberships/history, Saved/public references, existing claim/application history, and compatibility. Hiding/expiry/enforcement is not authorization for destructive deletion or a silent authority backfill.
9. Pending invitation grants no authority; no password handover/shared account, open public commercial claiming, duplicate ownership authority, or payment-to-Verified shortcut.
10. No commercial rule or implementation interpretation may weaken C1's security boundaries. Detailed grants, access control, event serialization and audit persistence require later explicit contracts and focused verification.

## 29. Acceptance criteria and focused drafting validation

| Criterion | Draft position / review target |
|---|---|
| Frozen policy unchanged | References and derives locked behavior; no new price/plan/entitlement or OQ resolution. |
| C1 preserved | State separation, security, compatibility, AR-01–AR-14 OPEN; no C1 edit. |
| Entitlement/publication clarity | Distinct basis, clock, eligibility, actual visibility, and launch context. |
| Payment/term start | Normal successful-publication anchor and narrow documented customer-delay day-15 exception. |
| Renewal/Grace/reactivation | Manual verified renewal; five days after expiry; previous-end renewal anchors; later verified-payment/republication non-retroactive anchor. |
| A8 accuracy | 0 IQD/60-day Pro, explicit launch/publication anchor, normally once; no fabricated paid proof or trialing mapping. |
| Override precedence | Suspension/termination/confirmed closure defeat ordinary publication/Grace without collapsing entitlement or deleting identity. |
| Launch qualification | Baghdad-first, normal five gate and frozen targets; no A8 counting after expiry; OQ-84 unchanged. |
| Independent verification | No universal badge requirement or renewal shortcut; full meaning protected. |
| Open dependencies visible | OQ-48, OQ-49, ownership/promotion/Grace access and other relevant residuals explicitly preserved. |
| No implementation choices | No new persistence/schema/enums/SQL/RLS/RPC/jobs/Flutter/provider/UI/routes/cache/Realtime chosen. |
| No self-acceptance/authorization | C2 DRAFT / NOT FROZEN / acceptance PENDING; IMPLEMENTATION_AUTHORIZED: NO. |

The gate is focused document/policy review, local-link verification, scope and protected-file checks, `git diff --check`, an untracked-document whitespace check, empty `git diff --cached --name-only`, and unchanged HEAD/local origin/main. Flutter, SQL, deployed Supabase checks, and repository-wide tests are outside this architecture-only task. Drafting checks are not an independent review or Architect acceptance.

## 30. Git / scope safety and drafting record

Expected baseline: **HEAD == local origin/main == a3a161f15b90f8b0ae33c8e28cc8145628d3b542**. Local origin/main is the local remote-tracking reference; C2 does not claim a fresh remote fetch/deployment check.

Protected pre-existing dirty baseline:

```text
 M test/a5_6_profile_bootstrap_test.dart
 M test/v1_r08_cloud_profile_foundation_test.dart
 M test/v1_r08_profile_edit_screen_widget_test.dart
?? OpenCode_Usage_Report.txt
?? artifacts/
```

Only the new `docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_PUBLICATION_ENTITLEMENT_CONTRACT_V1.md` is created. C1, Frozen Commercial Model, roadmap, production files, tests, and all protected files remain outside the mutation boundary. The drafting final report must give actual validation results rather than infer them from this expected scope. No stage, commit, push, restore, reset, or clean is authorized/performed by C2 drafting.

Drafting record, 2026-10-02: C2 conceptual architecture documented for review; commercial policy decisions changed: **0**; C1 AR entries resolved: **0**; Frozen Commercial Model OQs closed/reclassified: **0**; future contract families authorized: **0**; implementation authorization: **NO**.

**Recommendation: C2 is ready for focused Architect review as a conceptual architecture draft. It is not accepted, frozen, or an implementation-ready persistence/server contract. Acceptance remains distinct from any future implementation-contract authorization.**

---

## 31. C2 final Architect acceptance record

Record date: 2026-10-02

- Independent review: PASS / A — C2 READY FOR ARCHITECT ACCEPTANCE
- Architect Acceptance: APPROVED
- Commercial policy decisions changed: 0
- Conceptual architecture rules changed by acceptance: 0
- C2-AR entries resolved during acceptance: 0
- Frozen Commercial OQs closed/reclassified: 0
- Implementation authorization: NO
- Authority: ChatGPT Architect

C2 is accepted as the canonical commercial publication and entitlement conceptual architecture authority. This record and the current header supersede earlier draft / acceptance-pending / not-accepted status wording; historical drafting and validation statements are retained unchanged. C2-AR-01 through C2-AR-12 remain as defined, with substantive meaning and existing register labels preserved. Acceptance resolves no additional register entry and does not authorize any future contract family or implementation. IMPLEMENTATION_AUTHORIZED remains NO; conceptual architecture acceptance is distinct from future implementation-contract authorization.

Acceptance-pass trace-only corrections: LOW-1 adds the already OPEN OQ-72 dependency to §26.3 without closing, narrowing, reclassifying, or answering it. LOW-2 extends the principal policy anchors and C2-AR-01 authority trace to the existing Paid-Only foundations (§2, particularly §§2.1 and 2.5) and Sponsored separation (§6). The §12 composition clarification traces the general policy §8.2 rule to the specific frozen Grace continuation in §26.2.7; it introduces no commercial or conceptual architecture rule. All passed substantive content, Frozen Commercial Model OQs, C1, and roadmap remain unchanged.
