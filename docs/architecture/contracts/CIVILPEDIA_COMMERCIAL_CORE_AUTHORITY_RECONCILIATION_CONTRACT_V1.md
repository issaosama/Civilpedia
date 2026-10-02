# Civilpedia — Commercial Core Authority & Existing-System Reconciliation Contract V1

CONTRACT_ID: C1
CONTRACT_VERSION: V1
DOCUMENT_STATUS: ACCEPTED — CANONICAL COMMERCIAL ARCHITECTURE RECONCILIATION AUTHORITY
FREEZE_STATE: ACCEPTED — ARCHITECTURE RECONCILIATION ONLY
ARCHITECT_ACCEPTANCE: APPROVED
MODE: DOCUMENTATION / ARCHITECTURE ONLY
IMPLEMENTATION_AUTHORIZED: NO
PREPARED_DATE: 2026-10-01
REPOSITORY_BASELINE: main @ 70928c805b30e26783a65391e3c0072bf1dc21ef
LOCAL_ORIGIN_MAIN_BASELINE: 70928c805b30e26783a65391e3c0072bf1dc21ef
COMMERCIAL_POLICY_BASELINE: FROZEN V1, including A8 and the §33 freeze declaration, at 70928c8
ACCEPTANCE_AUTHORITY: ChatGPT Architect, under the existing Agent Operating Model
GIT_OWNER: User

## Purpose, scope, and evidence

C1 defines the architectural boundaries between the Frozen Commercial Model V1 and the accepted existing implementation. Civilpedia has substantial reusable Directory, membership, profile-management, staff-authority, and audit foundations. Those foundations do not constitute implementation of the frozen commercial model.

The Architect's acceptance of the Commercial Pre-Implementation Repository Audit is supplied by the C1 drafting request. The accepted audit was delivered in the preceding conversation; C1 does not invent a persisted audit report or claim that this draft has been accepted. This document is the first commercial architecture contract draft. Its reconciliation requirements become accepted architecture authority only through the Architect's acceptance process.

The authorized file boundary is this document alone: `docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CORE_AUTHORITY_RECONCILIATION_CONTRACT_V1.md`. No production implementation, schema, migration, RLS, auth, route, model, provider, repository, test, roadmap, or commercial-policy edit is authorized. No staging, commit, or push is authorized.

The [Master Roadmap](../CIVILPEDIA_V1_MASTER_ROADMAP.md) remains the phase/status SSOT. Its CURRENT PHASE CONTROL retains V1-R10.5-D as a focused pre-implementation audit, with implementation unauthorized. This separate, explicitly requested C1 documentation task does not change that control or unlock another slice. The [Agent Operating Model](../CIVILPEDIA_AGENT_OPERATING_MODEL.md) remains authoritative for routing and acceptance; C1 assigns no new team roles.

Evidence is repository code and migration definitions at the stated baseline, together with accepted historical reports. It describes what is implemented in the repository, not independently verified deployed data or live production configuration. No runtime, Flutter, Supabase reset, database, or repository-wide test suite was executed for this documentation task. Historical test results must not be reported as a fresh commercial acceptance gate.

Source anchors used throughout:

| Reference | Authority / evidence |
|---|---|
| Policy | [Frozen Commercial Model V1](../CIVILPEDIA_COMMERCIAL_MODEL_V1.md), particularly §§2–17, §§27–31, A8 §32, and current freeze §33. `LOCKED`, `PROVISIONAL`, `DEFERRED`, and OQ classifications retain their existing meaning. |
| Identity / taxonomy | [00005](../../../supabase/migrations/00005_directory_entities_and_categories.sql) and [00006](../../../supabase/migrations/00006_entity_relationships.sql). |
| Subscription foundation | [00008](../../../supabase/migrations/00008_plans_and_subscriptions.sql). |
| Current public RLS | [00010](../../../supabase/migrations/00010_rls_authorization_baseline.sql), read with subsequent hardening migrations. |
| Applications / activation | [00017](../../../supabase/migrations/00017_business_application_creation_authorization_hardening.sql) and [00018](../../../supabase/migrations/00018_business_application_activation_ownership_provisioning.sql), read with the preceding application, claim-concurrency, and server-mutation migrations. |
| Membership / editing | [00019](../../../supabase/migrations/00019_business_ownership_management_foundation.sql) and [00020](../../../supabase/migrations/00020_business_profile_management.sql). |
| Staff / audit | [00004](../../../supabase/migrations/00004_roles_permissions_and_staff.sql), [00009](../../../supabase/migrations/00009_audit_logs.sql), [00016](../../../supabase/migrations/00016_business_application_server_mutations.sql), and [00021](../../../supabase/migrations/00021_staff_application_operations_foundation.sql). |
| Directory integration | [production dependencies](../../../lib/core/di/app_dependencies.dart), [read gateway](../../../lib/features/directory/data/supabase_directory_read_gateway.dart), [cloud repository](../../../lib/features/directory/data/supabase_cloud_directory_repository.dart), and [cache](../../../lib/features/directory/data/directory_cloud_cache.dart). |
| Historical review context | [R05 correction report](../reports/V1-R05_DIRECTORY_CLOUD_INTEGRATION_CORRECTION_REPORT.md), [R07 correction report](../reports/V1-R07_STAFF_ADMIN_OPERATIONS_CORRECTION_REPORT.md), and [R08 closure report](../reports/V1-R08_CLOSURE_REPORT.md). These retain their original scope and historical verification dates. |
| Current slice contract | [V1-R10 contract, Appendix H](V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md#appendix-h---v1-r105-c-formal-closure--r105-d-phase-transition). Historical acceptance of other slices is not commercial implementation authorization. |

## 1. Authority order

1. **Frozen `CIVILPEDIA_COMMERCIAL_MODEL_V1.md`: commercial-policy authority.** Its locked requirements govern commercial meaning. The §33 freeze did not finalize provisional values, resolve open questions, or authorize implementation.
2. **Current accepted repository, migrations, and security boundaries: current engineering reality.** Their actual behavior governs the existing system until a separately authorized change is implemented. Describing a policy gap does not change that behavior.
3. **C1: architecture reconciliation authority, once accepted.** It identifies preserved foundations, prohibited semantic shortcuts, concept boundaries, and matters requiring future contracts. Drafting C1 is not its acceptance or freeze.
4. **Future implementation contracts: implementation-detail authority only after explicit authorization.** They must preserve commercial policy and accepted security boundaries, identify their file/data boundaries, and pass the required review and focused gate. Implementation additionally requires the authorized roadmap slice.

This order separates responsibilities; it does not grant C1 power to rewrite policy or override existing code. Commercial policy MUST NOT silently reinterpret an engineering field. Engineering artifacts MUST NOT silently redefine frozen policy. A discrepancy requires an explicit future reconciliation contract and, where data or storage changes are necessary, an explicit migration/compatibility contract.

If resolution would change a locked commercial rule or answer an Owner-level commercial OQ, it must return to the commercial change/decision process. C1 and later technical contracts cannot supply that decision by inference. Existing open questions retain their status, severity, classification, and owner.

## 2. Preserve existing canonical foundations

The following are **PRESERVE unless a later explicit contract proves migration necessary**. Preservation protects their identity, authority, and safety properties; it does not declare commercial completeness.

| Foundation | Preserve boundary |
|---|---|
| `directory_entities.id` UUID | Canonical public real-world entity identity and references. |
| `business_memberships` | Current authenticated business-association authority, with existing role semantics until explicitly reconciled. |
| Supabase auth identity | Canonical signed-in user ID; one production Supabase authority. |
| Central `AuthProvider` and session-generation behavior | One auth/session authority; stale asynchronous results and private data must remain scoped to the correct session. |
| Gateway / domain / provider separation | Backend decisions remain authoritative; presentation consumes validated projections and typed capabilities. |
| Fail-closed parsing | Malformed or unknown authority-bearing data must not grant capabilities or fabricate valid state. |
| Cloud Directory repository, cache, refresh, reconnect | Existing resilience, canonical resolution, known-good-data behavior, and guarded asynchronous updates, subject to explicit freshness reconciliation. |
| Canonical Directory routes and resolution | Existing canonical UUID links, including detail resolution and Saved references. |
| Profile row lock / expected-version check | Atomic writes, concurrent-edit rejection, validation, and audit consistency. |
| Validation and audit behavior | Server validation, sanitized audit projections, and no blind mutation retry. |
| `role_permissions` / `staff_memberships` chain | Current active staff membership, permission resolution, fail-closed discovery, and narrow staff application authority. |
| `append_audit_log` foundation | Server-side audit linkage and existing client restrictions; reuse is not a claim of complete commercial audit coverage. |
| Call / WhatsApp launcher | Existing interaction actions and test seams; launching an action does not establish analytics or a sale. |
| Saved canonical references | Stable personal saved-entity association, independent of commercial measurement. |
| Sponsored rendering / disclosure seam | Separate placement and disclosed rendering foundation, independent of an operational Sponsored backend. |
| Testing / fakes / pgTAP / security infrastructure | Existing regression evidence, gateway fakes, static security checks, focused SQL smoke tests, and quality gates. Later contracts add appropriate coverage rather than discard accepted safety checks. |

There is no authorization to replace these foundations wholesale, duplicate auth, introduce a competing directory authority, or perform a broad refactor.

## 3. Non-canonical commercial semantics

The following artifacts may remain for compatibility, but MUST NOT be treated as frozen commercial truth without explicit reconciliation:

| Current artifact | Prohibited inference |
|---|---|
| `PlanType` | The approved commercial plan catalog, business entitlement, or business/staff authority. |
| `PlanTier.defaultTiers` | Frozen prices, durations, limits, feature grants, or Sponsored eligibility. |
| Legacy `featured` | Paid organic ranking, a Sponsored campaign, or guaranteed placement. |
| Legacy `foundingPartner` boolean | Complete Founding Partner eligibility/pricing/history, or Launch Partner status. |
| Legacy `planType` field | Authoritative subscription or entitlement state. |
| `futureOwnerUserId` | Present ownership or a completed invitation/acceptance process. |
| `sb_profiles` | Production commercial identity, authoritative membership, or entitlement catalog. |
| Legacy `BusinessType` | A decided mapping to canonical Directory types or future commercial eligibility. |
| `lifecycle_status = active` | Valid paid or A8 promotional entitlement. |
| Application `ACTIVATED` | Public publication, payment, commercial entitlement, or complete commercial onboarding. |
| `claim_status = claimed` | A unique Primary Business Owner or accepted ownership invitation. |
| `directory_entities.verification_status` | The complete frozen commercial Verified meaning, evidence, validity, re-verification, withdrawal/inactivation, or permitted public claims. |
| Membership `OWNER` / `ADMIN` / `MEMBER` | An already-decided mapping to Primary Owner, Co-Owner, Manager, or Editor. |
| Subscription `trialing` | A valid A8 Launch Partner entitlement. |
| `entity_locations` | A complete commercial Branch model. |
| Mock Home ads | Civilpedia-owned acquisition campaign administration or production inventory authority. |
| `EmptyCampaignSource` | An operational Sponsored backend. |
| Saved | Canonical commercial analytics or a qualified lead. |
| Personal profile role / role preference | Authority over a Business or its finances, team, or content. |
| Personal Projects | Commercial Business portfolio content. |

This is a restriction on semantic reuse, not authorization to delete compatibility fields or rewrite existing readers. Current canonical domain parsing and legacy fallback behavior must not be conflated; C1 does not change either implementation.

## 4. Core concept separation

| Concept | Architectural responsibility |
|---|---|
| A. Business identity | The persistent real-world Business Entity, reconciled to canonical Directory identity. |
| B. Brand | Branding/grouping concept, distinct from legal or operational entity identity. |
| C. Branch | A subordinate operational location/unit of a Business Entity. |
| D. User account | A natural person's authenticated account, independent of Business ownership and subscription continuity. |
| E. Business membership | An authorized association and capabilities between a user and a Business. |
| F. Commercial entitlement | Time-bounded rights and limits under approved paid or expressly permitted promotional access. |
| G. Payment state | Payment evidence and financial processing state; not itself publication, ownership, or verification. |
| H. Publication state | Eligibility and actual public availability under the applicable commercial gates. |
| I. Verification state | Evidence-based verification and its review lifecycle; payment does not buy Verified status. |
| J. Moderation state | Review, approval/rejection, restrictions, and proposed-content disposition. |
| K. Sponsored campaign state | Separately authorized campaign eligibility, placement, disclosure, and delivery. |

**None of these states may be inferred solely from another unless an explicit future contract defines the derivation and preserves frozen policy and security.** A composite public projection may report several concepts; it must not erase their distinct authorities.

Required distinctions include: `PAID != PUBLISHED`; `PUBLISHED != VERIFIED`; `VERIFIED != SPONSORED`; `ACTIVE ENTITY != PAID ENTITLEMENT`; `CLAIMED != PRIMARY OWNER`; and `APPLICATION ACTIVATED != PUBLISHED`. These prohibit equivalence shortcuts, not legitimate policy-defined relationships. A Business may retain identity, content, history, or membership while another state changes; later contracts must define the permitted transitions.

### 4.1 Verification semantic reuse boundary — F-02

**`RAW VERIFICATION COLUMN != FULL COMMERCIAL VERIFIED AUTHORITY`.** Existing `directory_entities.verification_status` may remain reusable engineering plumbing, but the raw value alone MUST NOT be treated as satisfying frozen Verified policy. A future explicit Verification / Moderation reconciliation contract must define any mapping; C1 chooses no schema, enum, state persistence, checklist, or workflow.

Frozen §28.4 / L-74 includes the following meaning and constraints beyond the existing column:

- Verified means Civilpedia has checked defined identity/business information using accepted, reasonably necessary evidence. Only authorized Civilpedia staff/authority may grant or withdraw it; there is no self-verification.
- There is no automatic fixed time-based expiry solely because time passed.
- Re-verification triggers include material sensitive changes, risk signals, suspected fraud, ownership changes, identity/location changes, or Civilpedia review requirements.
- Subscription renewal alone does not automatically equal verification renewal or re-verification.
- Verification becomes inactive under applicable suspension, termination, and permanent-closure rules; false/forged evidence may cause verification withdrawal and enforcement under frozen policy.
- Verified implies no Civilpedia endorsement/recommendation or guarantee of quality, workmanship, commercial outcome, or Business claims.

The future contract must reconcile these policy dimensions with existing verification data and authorized operations. Deferred evidence/checklists, appeals, and remaining verification OQs retain their classifications and owners. This boundary does not redesign verification or change current verification behavior; its publication-related risk is recorded in AR-01.

## 5. Business Entity / Brand / Branch boundary

`directory_entities` remains the canonical public real-world entity identity foundation. The frozen Business Entity concept must reconcile to that identity. A competing Business ID system requires explicit migration justification, reference mapping, compatibility provisions, and acceptance; naming a future domain object does not justify duplicating identity.

Brand remains conceptually separate from Business Entity. Branch remains subordinate to a Business Entity and is not automatically another independently subscribed Business. The frozen included/extra-branch policy must be preserved without turning each location into a second full subscription or promoting provisional branch prices/limits into final architecture decisions.

`entity_locations` is reusable geographic infrastructure. It contains entity-linked locations, region/address/coordinates, and a primary-location relationship; it does not independently establish branch identity, team authority, entitlement consumption, lifecycle, media, or branch-specific discovery. Current entity-level contacts are not branch contacts by implication.

Brand storage, Branch storage and identifiers, branch contacts, managers, lifecycle, media, discovery, geographic validation, and entitlement accounting remain deferred to the Business / Branch Domain contract and its dependencies. C1 selects no table, column, or mapping.

## 6. Taxonomy authority boundary

Preserve `directory_categories`, `directory_entity_categories`, stable category UUID/code identity, the self-parent hierarchy, Arabic/English names, `is_active`, and the primary-category relationship. Labels are display data; existing stable identity must survive ordinary editorial changes.

Current gaps are explicit:

- The public landing and type presentation/order/icons are fixed in Flutter; Home directory shortcuts are also hardcoded.
- Categories have no category sort-order or category-media authority and no explicit Activity semantic layer.
- The public Directory projection supplies category display fields from loaded entities. There is no independent complete taxonomy cache; empty categories and the full hierarchy are not established by those entity-derived filters.
- Current public category SELECT policy does not filter `is_active`; profile-edit category validation does check active categories. These are different enforcement boundaries.
- Canonical entity-type parsing fails closed on unsupported types. New server labels/categories cannot imply that the installed app can render an arbitrary new entity/UI type.

Under A8 §32.9, ordinary category/activity/subcategory administration, labels/descriptions, visibility, ordering, media, assignments, and supported commercial records must be server/admin-managed without requiring a mobile release. This includes supported business/branch changes and Civilpedia acquisition content within the frozen requirement. Flutter consumes supported data/configuration. Arbitrary downloaded executable code/UI is prohibited; genuinely new renderable capability/block types may require an app update.

C1 chooses no schema, taxonomy cache format, synchronization protocol, Realtime, polling, Remote Config, admin screen, or permission code. The Taxonomy / Commercial Catalog contract must reconcile the gaps and define supported-data validation, completeness, and public visibility without weakening fail-closed behavior.

## 7. Commercial publication boundary

The current public-read rule in migration 00010 is `directory_entities.lifecycle_status = 'active'`; child public reads depend on an active parent. The production Directory gateway relies on that RLS authority. This is accepted existing engineering behavior, **not sufficient evidence of frozen commercial publication compliance**. Existing subscription rows are not composed into that public gate.

Future publication architecture must explicitly compose, where applicable, entity lifecycle, valid commercial entitlement, Required Fields/profile quality, ownership/onboarding, verification/moderation requirements, and suspension/closure restrictions. It must distinguish eligibility from actual publication and identify which authority establishes each component.

Ordinary commercial operation uses the frozen paid basis; A8's valid temporary Launch Partner access is an expressly permitted commercial entitlement, not a permanent free listing. Payment alone does not satisfy publication or ownership checks. Verified badge status is not a universal prerequisite for every public profile, and a paid or promotional entitlement does not buy verification. Ownership recovery must preserve the frozen possibility of continued publication absent risk restrictions; C1 must not impose an invented blanket takedown for every missing-owner condition.

The Publication Lifecycle contract must define the applicable gates, transitions, authorized writers/readers, and compatibility handling. C1 defines no exact SQL predicate, enum, computed column, job, RPC, state machine, or automatic cleanup rule. The gap remains AR-01.

### 7.1 Launch density / geographic launch gate boundary — F-01

Frozen L-87 / §31.3, read with A8 §32.11 / L-97, constrains category discovery and launch sequencing separately from an individual Business's publication eligibility:

- **BAGHDAD FIRST.** Initial launch uses a focused group of commercially meaningful categories in the applicable Baghdad launch market. Expansion outside Baghdad is **not automatic**; sufficient supply/demand readiness and an explicit later commercial/product decision are required.
- **Normal Category Launch Gate: at least 5 qualifying COMMERCIAL-ACTIVE Businesses** in that applicable Baghdad market before the category opens as normal public discovery. The normal basis is active, paid, publicly publishable Businesses; only the narrow initial A8 Launch Partner allowance below permits promotional entitlement to qualify. The gate is not lowered by A8.
- **Growth target: approximately 8–10 active paid Businesses per launched category before strong promotion.** **Formal launch-push target: approximately 30 active paid publicly publishable Businesses across initial categories.** These are readiness/growth targets, not contractual guarantees to customers.
- A below-gate category must not present a misleading normal populated category. It may be hidden from primary discovery/navigation or clearly represented as **Coming Soon / قريباً**. These are frozen presentation concepts, not a selected UI or final localized string. No fake or permanent-free production listing may be used to pad density, and Civilpedia must not broadly launch an obviously sparse paid-only directory.
- The **5-Business gate is a launch gate, not a perpetual automatic shutdown rule**. An opened category does not automatically close solely because an expiry reduces the qualifying count from 5 to 4. A launched category with zero active publicly publishable Businesses must show an honest empty/unavailable state rather than stale or fake listings; exact UX remains deferred.
- During the initial Launch Partner phase, an authorized Launch Partner may count only with a valid Business Entity, an **in-effect A8 promotional commercial entitlement**, and a publicly publishable profile. This is the frozen COMMERCIAL-ACTIVE rule, not free-listing eligibility. After promotional entitlement expires, it stops counting on that basis unless another valid commercial entitlement applies, such as a verified paid subscription. Pre-expiry metric reporting does not extend entitlement or counting validity. Ordinary post-launch paid operation retains its paid basis.

**CATEGORY DISCOVERY VISIBILITY MUST NOT BE MODELED AS A PURE STATIC ADMIN FLAG THAT CAN BYPASS THE FROZEN LAUNCH-DENSITY RULE.** Server-managed category visibility under §6 does not create discretion to bypass this policy. Future architecture must compose at least qualifying commercial entitlement, publicly publishable state, category, geography, and the applicable launch-density condition. A Business's raw lifecycle or a category's `is_active`/visibility value alone cannot establish launch eligibility.

Taxonomy / Commercial Catalog and Publication Lifecycle contracts must explicitly reconcile this category/geography gate, launch sequencing, and individual Business eligibility. C1 chooses no counting algorithm, geographic representation, persisted launch state, schema, SQL/RLS, flag, job, UI, or cache/Realtime mechanism. The distinction between initial launch gating and later category treatment must be preserved; remaining OQ-84 and related post-publication/presentation questions remain unresolved. The architecture risk is AR-14.

## 8. Ownership / membership reconciliation

Current `business_memberships` stores `OWNER`, `ADMIN`, and `MEMBER`. Current OWNER and ADMIN memberships authorize profile management and membership-roster reads; MEMBER does not receive those management capabilities. The current management helper is server-derived from the authenticated user and target entity. Listing associated businesses does not grant management to every listed member. Existing membership storage does not establish Primary Owner cardinality or invitation acceptance.

Existing roles MUST NOT be renamed or reinterpreted in place without an explicit mapping/migration contract. Neither ADMIN → Manager nor OWNER → Primary Owner/Co-Owner is decided here. Staff roles are separately scoped; a business ADMIN is not a Civilpedia administrator by name.

The future Ownership / Invitation / RBAC contract must preserve the frozen properties:

- Exactly one Primary Business Owner in normal operation, with optional verified Co-Owners.
- Primary Owner accountable ownership authority; Co-Owner participation does not imply equivalent sensitive-transfer authority.
- Manager operational authority without ownership authority; Editor limited content authority.
- Routine onboarding through invitation, required acceptance/verification checks, and explicit authority activation. A pending invitation grants no silent authority.
- Controlled admin-only exceptional Direct Assignment to an identifiable existing account, without bypassing required ownership verification.
- Ownership Recovery Pending, preserving Business identity, data, subscription continuity, and policy-permitted public availability while recovery is resolved. A Business must not remain indefinitely in a normal active ownership state without a Primary Owner; Civilpedia verifies an eligible replacement and assigns it through the controlled ownership process. Ownership-sensitive actions may be restricted during recovery, and disputed/deceased-owner evidence requirements remain with their existing policy/legal-review question.
- Auditability, transactional invariants, personally held accounts, and no password creation/handover or shared credentials.

Stored roles, capability matrices, seat/financial access enforcement, cardinality storage, transfer/recovery mechanics, invitations, and migration of existing memberships remain deferred. Open ownership/invitation policy questions remain with their existing owners. AR-02 remains open.

## 9. Claim flow reconciliation

The repository has authenticated NEW and CLAIM application creation/workflows, server validation, duplicate/concurrent-claim protections, staff review, and atomic activation/ownership provisioning. Authentication and staff review do not by themselves make this the frozen future commercial onboarding policy.

Frozen Commercial V1 prohibits open public claiming. **This is a HIGH reconciliation point, AR-03.** Until explicitly reconciled, the existing CLAIM path remains engineering reality and must not be represented as commercially authorized future claiming. No new feature may expand or promote public Claim behavior under C1.

The future onboarding/ownership contract must determine whether the current CLAIM facility is disabled, made staff-only, migrated, repurposed, or retired, while preserving relevant application/history/audit data. C1 selects none of these alternatives and authorizes no behavior change. Any eventual option must satisfy the no-open-public-claim boundary; a technical contract cannot authorize a new open claim product around it.

## 10. Business Draft / onboarding boundary

Four distinct current or policy concepts must remain separate:

| Draft concept | Boundary |
|---|---|
| Application `DRAFT` | Application workflow record, subject to the existing narrow server write paths; not a published Business. |
| Flutter profile editing draft | In-memory/editing representation and proposed input to the current profile RPC; not an independently moderated published-value model. |
| `directory_entities.lifecycle_status = draft` | Existing entity lifecycle value; not proof of Civilpedia-created onboarding, entitlement, or pending invitation. |
| A8 Civilpedia-created Business Draft | Policy concept allowing controlled ownerless preparation before ownership and publication gates are satisfied. |

A future onboarding contract must define Civilpedia-created ownerless Drafts, Owner not yet attached, pending invitation, accepted ownership, and publication eligibility. Ownerless entity storage being structurally possible does not prove that this complete administrative workflow exists.

Current NEW activation creates/provisions an entity and OWNER association through the accepted server path; it does not establish payment or publication. A8 Draft creation does not start the promotional clock or prove accepted ownership. C1 chooses no draft schema, routing, invitation transport, or workflow transition.

## 11. Subscription / entitlement boundary

Preserve the reusable `plans` and `subscriptions` foundation: plan identity/code, entity FK, plan FK, `started_at`, `ends_at`, `price_paid`, currency, and current date relationship constraint. Subscription linkage is to the entity, supporting Business continuity independently of a user account.

The current status vocabulary is `trialing / active / past_due / canceled / paused`. These are existing engineering values, **not a decided mapping of frozen commercial lifecycle semantics**. `trialing` is not Launch Partner by implication; `active` is not proof of approved payment, a complete commercial entitlement matrix, or public availability. The migrations provide no complete payment, term/renewal, Grace, promotional, extra-branch, or Sponsored implementation, and there is no production subscription-management consumer establishing those semantics.

The Subscription / Entitlement contract must explicitly represent or reconcile Business, Business Pro, Business Plus, Corporate, approved durations and term anchors, entitlement limits, Grace, expiry, manual renewal, reactivation, suspension interactions, Launch Partner, Founding Partner, and extra Branch allowances/add-ons. Locked commercial durations, Grace, and manual-renewal rules remain in the SSOT; unfinalized technical representations and provisional values do not become decided through C1.

Sponsored remains a separate commercial product/authority. A plan may affect eligibility where frozen policy says so; this does not create a campaign, delivery guarantee, verification grant, or organic-ranking right. Financial/subscription data remains private by default, distinct from currently public plan-catalog reads; frozen §28.11 restricts Business financial/subscription visibility to the Business Owner and explicitly finance-authorized roles. The exact stored RBAC mapping remains deferred. C1 chooses no plan seed, price record, billing integration, enum mapping, or entitlement calculation. AR-04 remains open.

## 12. Launch Partner / Founding Partner boundary

Launch Partner is Civilpedia-controlled temporary Business Pro promotional access under A8: **0 IQD for 60 calendar days**, without a card/payment instrument, automatic renewal, or automatic charge. It is not automatic for every Business and is not a permanent free tier. The clock does not start on Draft creation: the locked anchor is the later of formal commercial launch or the Business's first successful public publication after that launch.

The genuine-entity promotional limit and duplicate-abuse prohibition must be preserved; the SSOT's normally-once qualification and its open exceptions remain unchanged. Expiry follows the frozen Grace/conversion/data-retention rules. Launch-density counting on the A8 basis is valid only while the promotional entitlement is in effect and the profile remains publicly publishable; pre-expiry reporting timing is not a rule extending entitlement validity. Post-promotion category treatment remains an open commercial question.

Founding Partner is the separate first-50, first-year **paid** pricing/history/badge program under §5. Discounted first-year payment is not the 0 IQD promotional period, and badge/history continuity is not perpetual discounted entitlement. Sequential eligibility for both is permitted only under their respective policy rules: temporary Launch Partner first, eligible Founding Partner paid pricing later.

The legacy `foundingPartner` boolean implements neither complete mechanism. Representation, cohort administration, timing evidence, continuity, eligibility recording, enforcement, and conversion remain future contract work. C1 chooses no `trialing` mapping, plan row, flag, job, or schema. AR-05 remains open.

## 13. Sensitive edit reconciliation

The current profile RPC writes accepted edits immediately. It locks the entity, checks `p_expected_updated_at`, validates input, and audits atomically. Material name/primary-location changes on a verified entity reset verification to pending; phone/category edits do not have that same sensitivity treatment. It does not maintain separate proposed and previously published values awaiting reviewer approval.

Frozen §13 sensitive-change policy includes name, primary location, primary phone, primary category, and ownership/verification concerns. Applicable review must preserve the published value until approval where practical. Existing verification reset behavior must not be represented as that complete moderation workflow.

**AR-06 is HIGH.** Preserve row-lock, version-check, validation, sanitized audit, and concurrency protections. The future moderation/publication/profile contract must define proposed value, published value, reviewer authority, acceptance/rejection, and verification interaction, including the policy's practical-preservation qualification and authorized exceptions. It must reconcile current immediate-write history and prevent unauthorized privilege escalation through editing.

C1 selects no proposal table, shadow column, new verification enum, UI queue, RPC, or restoration algorithm. It does not retrofit review into current behavior by declaration.

## 14. Admin authority boundary

Current `roles`, `permissions`, `role_permissions`, and active `staff_memberships` support narrowly permission-gated application operations and scoped capability discovery. Existing staff application read/write permissions do not imply authority to administer commercial categories, activities, Businesses, subscriptions, Launch Partner status, ownership/invitations, Branches, acquisition campaigns, Sponsored, analytics, or general verification/moderation.

Future commercial admin actions require explicit permission expansion through an authorized Admin Authority contract, preserving server-side validation, fail-closed capability discovery, narrow grants, audit, and session/permission-loss data clearance. No blanket staff role, client flag, business ADMIN role, or personal profile role may substitute for those permissions.

A8 §32.10 records future tooling requirements, not implemented authority. C1 chooses no permission code, role grant, staff provisioning path, admin panel, or route. AR-09 remains open.

## 15. Business Center boundary

Existing managed-business selection and profile editing are useful foundations. Their gateway/domain/provider separation, server-derived membership checks, expected-version editing, guarded asynchronous loads, and auth-generation behavior remain reusable. A membership-roster server seam does not establish complete team-management UI or invitation authority.

The existing feature is not the complete commercial Business Center. Later authorized contracts must cover appropriate Business/profile content, Products, business Projects/portfolio, Offers, media, Branches, team/ownership/invitations, subscription/status visibility, and analytics, as allowed by frozen module, entitlement, financial-visibility, moderation, and sensitive-change rules. Personal Projects must remain separate unless an explicit content/compatibility contract provides a safe relationship.

Entitled-user access and business-specific permissions must be composed from authoritative sources; merely showing a module or listing a Business grants nothing. Exact screens, routes, layouts, forms, module field sets, role matrices, and feature limits remain deferred. C1 authorizes no UI.

## 16. Media authority boundary

`entity_media` is reusable metadata infrastructure for logo, cover, and gallery URLs/type/position. That does not prove a commercial upload service, storage bucket authority, object ownership, validation, access policy, moderation, product/project/offer media, or complete public rendering. Existing public Directory identity presentation and metadata availability must not be described as a finished gallery/upload system.

The Media contract must define buckets/object identity if required, authorization and Business association, content validation, ownership/access restrictions, moderation, allowed usage, and retention/deletion compatibility, together with separate product/project/offer requirements. Accepted auth and membership authority must remain the basis of access.

C1 chooses no bucket, path convention, signed/public URL policy, file limit, upload library, schema, or media entitlement value. Provisional media limits remain provisional. AR-10 remains open.

## 17. Analytics authority boundary

There is no canonical commercial analytics event/storage/reporting implementation established by the accepted repository. Call/WhatsApp launching, Saved, navigation, campaign rendering, Supabase platform diagnostics, and app error diagnostics do not establish Business measurement authority.

The Analytics contract must define approved events and attribution, counting and uniqueness, bot/self-interaction treatment, retention, authenticated/private reporting access, and separation of organic, Sponsored, and Civilpedia acquisition measurements. It must reconcile promotional reporting and post-expiry visibility/retention without answering the remaining OQ-17 by assumption.

Profile views and Call/WhatsApp/Directions clicks are interactions, not automatically guaranteed leads or confirmed sales. Any permitted qualified-lead metric requires its own frozen-policy-compatible definition and evidence. Reports must describe actual measured behavior honestly and must not invent values where no event authority exists. A8 calls for factual value reporting before promotional expiry where available; this is not a promise of guaranteed results.

C1 chooses no analytics provider, event schema, tracking SDK, counting window, dashboard, or access grant. AR-11 remains open.

## 18. Civilpedia acquisition vs Sponsored boundary

Civilpedia-owned acquisition banners/campaigns and paid Business Sponsored campaigns are separate commercial authorities. Acquisition promotes Civilpedia onboarding/programs under A8; Sponsored is the distinct paid product under §6 and its amendments. Neither can silently consume or redefine the other's inventory, entitlement, eligibility, reporting attribution, or disclosure semantics.

Current Home mock/local ad sources and carousel presentation are presentation scaffolding, not administratively managed acquisition authority. The production `EmptyCampaignSource` supplies no operational Sponsored inventory. The separate campaign resolver/coordinator and disclosure/rendering seam are reusable but do not implement commercial sales, administration, payment, allocation, or analytics.

Shared presentation may be reused under a later contract without merging semantic authorities. The Campaigns / Sponsored / Acquisition family must define their respective ownership, eligibility, inventory, delivery, disclosure, and attribution boundaries. C1 chooses no backend, placement inventory, pricing, source implementation, or campaign UI.

## 19. Cache / catalog freshness boundary

Preserve current Cloud Directory resilience: validated authoritative snapshots, cache restoration, refresh/reconnect behavior, guarded asynchronous results, and known-good data preservation on later read failure. Current cache format/version is engineering reality, not a frozen commercial freshness strategy.

The current snapshot cache has no commercial TTL or independent full taxonomy authority. Cache-first entity resolution and preserved stale snapshots require explicit treatment for revoked/expired/suspended/unpublished records. Public-read updates, taxonomy visibility changes, entitlement expiry, permission revocation, and private session clearance have distinct authority requirements; a cached item must not grant a write or management capability.

Future contracts must reconcile acceptable offline/stale presentation with authoritative public eligibility and promptly removed access where required. They must define snapshot completeness, pagination/maximum-row handling, and taxonomy/catalog synchronization. Current reads lack explicit pagination, and Supabase configuration includes a maximum-row bound; a successful bounded response must not be assumed to be the entire future catalog.

C1 chooses no TTL, cache key/format migration, Realtime channel, polling interval, invalidation protocol, Remote Config, or retention strategy. AR-12 remains open; existing resilience may be changed only under an explicit compatibility/freshness contract.

## 20. Security invariants

The following invariants bind future reconciliation; commercial freeze does not weaken existing security:

1. UI, routes, local flags, cached projections, and personal profile roles never grant authority by themselves.
2. Membership/ownership checks are server-validated against the authenticated user, target Business, and applicable capability. Client-supplied actor identity is not authoritative.
3. Financial/subscription data is non-public by default. Public plan-catalog information and public marketing labels are separate from private Business billing/subscription records.
4. Admin actions require explicit server permission checks. Existing application permissions do not authorize broader commercial administration.
5. Exceptional ownership assignment is controlled and auditable, including acting admin, Business, target user, assigned role/capability, timestamp, and reason/context where required. It must not bypass required verification.
6. Pending invitations do not grant authority. Required identity, acceptance, verification, and consistency checks precede effective normal authority; exact mechanisms remain deferred.
7. Unknown or malformed authority-bearing roles/statuses fail closed. No future parser may promote an unknown value into an owner, staff, entitlement, or publication grant. This does not authorize modifying compatibility parsers in C1.
8. No `service_role` secret or equivalent privileged credential enters Flutter/client paths. Preserve one production Supabase authority and one `AuthProvider`.
9. Invariant-bearing writes remain server-authorized and transactional, with locking/version checks and consistent audit as appropriate. Do not introduce blind automatic mutation retries or remove existing concurrency protections.
10. Auth/session-generation guards and private-data clearing on sign-out, session replacement, or permission loss remain protected. Stale asynchronous results must not reinstate prior-user authority.
11. No open public commercial claiming, shared account/password handover, weaker RLS, or invented payment-to-verification grant may be introduced through technical reconciliation.
12. Raw `directory_entities.verification_status` is not full commercial Verified authority. Any future mapping requires an explicit Verification / Moderation reconciliation contract preserving frozen evidence/checking meaning, authorized grant/withdrawal, validity and re-verification rules, inactivation, and non-guarantee semantics; a raw column or client badge cannot substitute for that authority.

C1 creates no policy, grant, definer function, credential, RPC, or server configuration. Later security changes require their own explicit contract and focused authority/concurrency verification.

## 21. Compatibility obligations

Future commercial work must preserve unless explicitly migrated:

- Canonical entity UUIDs, existing public Directory links/resolution, and Saved canonical references.
- Accepted auth identity/session authority and its private-data lifecycle.
- Directory cache/resilience behavior where compatible, with any necessary freshness/cache migration explicitly specified.
- Existing membership data and current effective roles until an accepted mapping/cutover is implemented.
- Existing application records, workflow/history, and audit history, including CLAIM records even if future claim exposure changes.
- Existing tests, security/quality gates, and accepted profile-management validation, locking/version checks, and audit behavior.

No destructive migration is allowed without an explicit data-migration contract. Such a contract must identify affected existing data, identity/reference mapping, authority changes, preservation/cutover behavior, validation, and recovery expectations. A policy gap is not permission to delete records, fabricate paid/promotional eligibility, assign a Primary Owner from ambiguous legacy data, or relabel current statuses.

Existing development/legacy rows require explicit disposition under frozen policy and remaining compatibility questions. C1 does not backfill, grandfather, publish, unpublish, or retire them by inference. AR-13 remains open.

## 22. Current high-risk reconciliation register

These **AR IDs are architecture reconciliation records, not commercial OQs**. They do not close, narrow, reclassify, or duplicate decisions in the SSOT. The risk describes consequences of semantic reuse without an explicit contract. The responsible future contract owner is the ChatGPT Architect for scope/mapping acceptance, with technical drafting/review routed by the existing Agent Operating Model; this register dispatches no agent or implementation work.

| ID / reconciliation point | Current evidence | Frozen requirement | Risk | Future contract owner | Status |
|---|---|---|---|---|---|
| **AR-01 Publication vs entitlement** | 00010 public entity reads use lifecycle `active`; child reads use active parent; 00008 subscriptions are not composed into publication. The 00005 raw `verification_status` column is not evidence of the complete frozen Verified meaning. | §§2, 8, 12, 28.4, 28.6 and A8 require applicable entitlement/quality/onboarding/moderation gates; paid and valid temporary promotional bases remain distinct. §28.4 / L-74 also requires explicit reconciliation of Verified evidence, validity, re-verification, authorized withdrawal/inactivation, and non-guarantee meaning. | **HIGH:** commercially ineligible publication or unintended removal of eligible records if `active` is equated with entitlement; misleading Verified authority if a raw verification value substitutes for full policy. | Architect — Publication Lifecycle, coordinated with Subscription / Entitlement and an explicit Verification / Moderation reconciliation contract; Codex for server/RLS authority. | **OPEN — DEFERRED TO EXPLICIT RECONCILIATION CONTRACT.** |
| **AR-02 Primary Owner / role mapping** | 00006/00019 store OWNER/ADMIN/MEMBER; OWNER/ADMIN manage; no Primary/Co-Owner or invitation/cardinality model. | §31.2 and §§32.6–32.8: one Primary Owner normally, verified optional Co-Owners, distinct Manager/Editor intent, controlled recovery/assignment. | **HIGH:** privilege escalation, ambiguous primary accountability, unauthorized transfer, or loss of accepted memberships. | Architect — Ownership / Invitation / RBAC, coordinated with Migration / Compatibility; Codex for ownership/security/concurrency. | **OPEN — NO STORED ROLE MAPPING CHOSEN.** |
| **AR-03 Claim flow vs no-open-claim policy** | 00017/00018 and current application forms support authenticated CLAIM creation, staff review, and ownership activation. | §27.2 / L-66: no open public commercial claiming; A8 controlled onboarding does not expand claim rights. | **HIGH:** treating a technically guarded legacy workflow as future commercial authorization. | Architect — Ownership / Onboarding and Migration / Compatibility; Codex for claim authority/history/invariants. | **OPEN — DISABLE / STAFF-ONLY / MIGRATE / REPURPOSE / RETIRE CHOICE DEFERRED.** |
| **AR-04 Subscription state vocabulary** | 00008 contains trialing/active/past_due/canceled/paused and entity/plan/date/price fields; no complete commercial lifecycle implementation. | §§3, 8 and amendments: approved plan/term/Grace/renewal/expiry rules and separate payment/publication/verification. | **HIGH:** invalid entitlement, expiry/renewal errors, or privacy leaks from inferred legacy status meaning. | Architect — Subscription / Entitlement, coordinated with Publication and Migration; Codex for backend/private authority. | **OPEN — ENUM / STATE MAPPING DEFERRED.** |
| **AR-05 Launch Partner representation** | No canonical A8 cohort/clock/entitlement authority; `trialing` and legacy Founding boolean do not supply it. | §32.2: selected temporary Pro, 0 IQD/60 days, locked start anchor, no card/auto-charge, distinct Founding paid program and preserved open exceptions. | **HIGH:** permanent-free precedent, lost promotional days, duplicate abuse, or conflated paid discount/promotion. | Architect — Subscription / Entitlement and Launch Partner administration; remaining commercial OQs stay with existing owners. | **OPEN — REPRESENTATION / TIMING ENFORCEMENT DEFERRED.** |
| **AR-06 Sensitive edit / published-value preservation** | 00020 immediate writes; verified name/location changes → pending; phone/category do not receive the same sensitivity behavior. | §13: applicable sensitive review and published-value preservation until approval where practical, including broader sensitive concerns. | **HIGH:** premature unreviewed public changes, verification misrepresentation, or loss of accepted concurrency/audit safety. | Architect — Moderation / Publication / Profile Management; Codex for transactional authority and versioning. | **OPEN — PROPOSED / PUBLISHED MODEL DEFERRED.** |
| **AR-07 Server-managed public taxonomy** | 00005/00006 taxonomy foundation; fixed Flutter type landing/order/icons/Home shortcuts; no sort/media/Activity layer/full taxonomy cache; public category reads not active-filtered. | §32.9: supported ordinary category/activity/visibility/ordering/media/assignment administration without an app release; no arbitrary executable UI. | **HIGH:** inactive/unsupported exposure, incomplete catalogs, or mobile-release dependence contrary to policy. | Architect — Taxonomy / Commercial Catalog; directory/data-flow and server security work routed by the operating model. | **OPEN — SCHEMA / PRESENTATION DATA CONTRACT DEFERRED.** |
| **AR-08 Branch vs entity_locations** | 00006 stores geographic locations and entity-level contacts; public location projection is not a complete operational Branch aggregate. | §§2.3, 4 and §32.9: distinct subordinate Branches and preserved included/extra-branch rules. | **HIGH:** duplicate Business identities, wrong subscription charging, cross-branch authority leaks, or lost geographic references. | Architect — Business / Branch Domain, coordinated with Entitlement / Media / Migration; Codex for identity/security boundaries. | **OPEN — LOCATION / BRANCH MAPPING DEFERRED.** |
| **AR-09 Admin permission expansion** | 00004/00016/00021 provide scoped staff application permission checks and capability discovery. | §§32.7, 32.9–32.10 require controlled, audited future commercial administration, with no implied implementation. | **HIGH:** blanket staff authority over ownership, billing, verification, or campaigns. | Architect — Admin Authority with domain owners; Codex for permission/RLS/audit engineering. | **OPEN — NEW CAPABILITIES / GRANTS DEFERRED.** |
| **AR-10 Commercial media authority** | `entity_media` metadata exists; no established commercial upload/bucket/object-policy/moderation authority. | §§15–16: appropriately entitled Business content/media and review/quality requirements; provisional limits remain provisional. | **HIGH:** unauthorized objects/content, Business association errors, or an invented public storage grant. | Architect — Media, coordinated with Business Center / Admin / Moderation; Codex for storage authorization. | **OPEN — STORAGE / VALIDATION / ACCESS CONTRACT DEFERRED.** |
| **AR-11 Analytics semantics** | Launchers, Saved, rendering, and diagnostics exist; no canonical commercial event/reporting system. | §17, A5 analytics honesty, §32.3 and remaining OQ-17: factual measurements, qualified definitions, privacy and unresolved retention/visibility. | **HIGH:** misleading leads/sales claims, conflated attribution, or disclosure of private Business reporting. | Architect — Analytics, coordinated with Campaigns / Entitlement; Owner-level OQ-17 decisions remain separately routed. | **OPEN — EVENT / COUNTING / REPORTING CONTRACT DEFERRED.** |
| **AR-12 Catalog / cache freshness** | Snapshot cache preserves known-good data without commercial TTL; cache-first detail; no independent taxonomy cache or explicit public pagination. | §32.9 allows resilient caching under future architecture; current entitlement/publication/revocation authority must remain correct. | **HIGH:** stale ineligible public records, incomplete catalogs, or cached authority surviving revocation. | Architect — Taxonomy / Directory Freshness with Publication and Compatibility; critical access behavior routed to Codex. | **OPEN — FRESHNESS / COMPLETENESS STRATEGY DEFERRED.** |
| **AR-13 Existing data compatibility** | Canonical UUIDs, memberships, applications/history, Saved, caches, and audits coexist with legacy fields and development rows. | §§2, 27, 33 and unresolved data questions: preserve policy and history; no silent entitlement/role backfill or destructive migration. | **HIGH:** broken links, lost history, invented commercial eligibility, or incorrect ownership migration. | Architect — Migration / Compatibility with each affected domain; User retains Git ownership. | **OPEN — EXPLICIT DATA DISPOSITION / MIGRATION CONTRACT REQUIRED.** |
| **AR-14 Launch Density / Geographic Launch Gate Reconciliation** | Current Directory landing renders fixed canonical entity types without entity reads or density counts; category SELECT in 00010 is unfiltered reference taxonomy, and public entity reads use lifecycle `active`. Current presentation/RLS does not compose a qualifying commercial count with category/geography launch eligibility. | L-87 / §31.3 and §32.11: BAGHDAD FIRST; explicit later expansion decision; normal 5-qualifying-Business launch gate; ~8–10 category / ~30 formal-launch targets; honest below-gate/empty states; no static admin bypass, fake padding, or perpetual count-based auto-shutdown; A8 counts only while its qualifying entitlement and publishability remain valid. | **HIGH:** sparse or misleading public category launch, unauthorized geographic expansion, expired promotional density, or static visibility overriding the frozen launch gate. | Architect — Taxonomy / Commercial Catalog + Publication Lifecycle contracts, coordinated with Subscription / Entitlement; remaining commercial expansion/post-promotion decisions stay with their existing owners. | **OPEN — CATEGORY / GEOGRAPHY / DENSITY RECONCILIATION DEFERRED; NO IMPLEMENTATION CHOSEN.** |

C1 resolves the architectural prohibition on silent equivalence/reuse; it does **not** resolve these implementation/data mappings. No AR is marked implementation-complete. Remaining commercial OQ decisions cannot be replaced by an AR resolution.

## 23. Deferred follow-up contract families

The following are recommended domains of future contracting, **not authorized work, a chosen sequence, or new roadmap slices**. Their grouping, dependencies, exact boundaries, and order require later Architect decisions.

| Family | Deferred decisions / obligations |
|---|---|
| Taxonomy / Commercial Catalog | Supported server-managed taxonomy/catalog projections, administration, ordering/visibility/media, and complete synchronization. With Publication Lifecycle, reconcile AR-14's qualifying category/geography launch-density gate and sequencing without a static admin visibility bypass. |
| Business / Branch Domain | Canonical Business reconciliation, Brand separation, operational Branch/location relationship, discovery and entitlement accounting. |
| Ownership / Invitation / RBAC | Primary/Co-Owner/Manager/Editor capabilities and storage mapping, claim disposition, invitation acceptance, controlled assignment, recovery, seats/financial access. |
| Subscription / Entitlement | Catalog/state representation, approved terms/Grace/renewal/expiry, payment evidence, Launch/Founding separation, extra Branches, suspension interactions. |
| Publication Lifecycle | Composite public eligibility, publication evidence/transitions, commercial and promotional bases, required quality, recovery/suspension/closure handling. With Taxonomy / Commercial Catalog, reconcile AR-14's Baghdad-first category launch gate, geographic decision boundary, and launch-vs-post-launch behavior. |
| Moderation / Sensitive Profile Changes | Proposed/published values, reviewer authority, accept/reject, verification interactions, and practical preservation rules; may be coordinated with Publication. An explicit Verification / Moderation reconciliation contract must also fence/map raw verification status to frozen Verified meaning, evidence, validity, re-verification, authorized withdrawal/inactivation, and non-guarantee semantics. |
| Admin Authority | Domain-specific permission expansion, provisioning/discovery, audit and private-data boundaries, without blanket staff authority. |
| Business Center | Entitled content/modules, existing profile-management reuse, team/branch/subscription/reporting integration, and later UI/routes. |
| Media | Object/storage authority, upload validation, Business association, moderation, module-specific media, and compatible retention/deletion. |
| Analytics | Events/counting/attribution, honest metric definitions, access, retention/reporting, and separately resolved commercial questions. |
| Campaigns / Sponsored / Acquisition | Separate campaign authorities, eligibility/inventory/disclosure/delivery, and separate attribution. |
| Migration / Compatibility | Existing row disposition, role/status/reference mapping, identity preservation, history retention, cutover/validation/recovery. |

**Localization dependency — F-04.** Frozen commercial Arabic copy must enter the canonical localization SSOT (D-27, §28.14, and A8 §32.4.2). Architecture/implementation contracts must not hardcode final commercial Arabic strings ad hoc, including acquisition and launch-state copy. Exact localization integration remains future engineering work; this documentary seam authorizes no UI or localization-code change.

An accepted future contract must still receive separate implementation authorization. Commercial freeze, C1 acceptance, inclusion in this table, and existence of a reusable seam are insufficient authorization.

## 24. Acceptance criteria and drafting validation

The Architect may accept C1 only if all the following hold:

| Criterion | C1 drafting position |
|---|---|
| No production implementation changed | Authorized deliverable is this new Markdown document alone. |
| No schema or migration chosen | All representations, storage mappings, and migration choices remain deferred. |
| No enum or role mapping chosen | Existing values are described; no commercial equivalence is assigned. |
| No Realtime / polling / Remote Config / cache strategy chosen | Freshness/completeness obligations are registered without a mechanism. |
| No new UI or routes chosen | Existing surfaces are evidence; future Business Center/admin/presentation design is deferred. |
| Frozen commercial rules preserved | No price/plan/entitlement change; no provisional value finalized; no OQ closed or reclassified. |
| Current engineering behavior accurate | Current RLS, memberships, activation, immediate profile writes, taxonomy, cache, and absent commercial services are distinguished from policy. |
| Conflicts explicitly registered | AR-01 through AR-14 remain open for named future contract families; AR-01 also fences full Verified meaning from the raw verification column. |
| Reuse boundaries explicit | §2 protects accepted foundations; §3 prohibits semantic shortcuts; §§4–21 define reconciliation boundaries. |
| Security and compatibility retained | No weaker authorization, privileged client path, identity replacement, or destructive migration is permitted by C1. |
| Implementation remains unauthorized | `IMPLEMENTATION_AUTHORIZED: NO`; roadmap/current slice and frozen commercial document remain unchanged. |
| Acceptance / freeze not self-declared | This is a draft ready for Architect review, not an accepted or frozen implementation contract. |

The drafting validation gate is document/source review, local-link verification, scope/protected-baseline checks, `git status --short`, `git diff --check`, `git diff --cached --name-only`, and confirmation of unchanged HEAD/local origin/main at 70928c8. A fresh Flutter/SQL/integrated test run is outside this documentation-only task; accepted historical checks remain historical evidence.

Protected pre-existing baseline:

```text
 M test/a5_6_profile_bootstrap_test.dart
 M test/v1_r08_cloud_profile_foundation_test.dart
 M test/v1_r08_profile_edit_screen_widget_test.dart
?? OpenCode_Usage_Report.txt
?? artifacts/
```

The expected task delta is exactly one new untracked contract document, with this protected baseline untouched and no staged files. No staging, commit, or push is authorized. The drafting agent's final report records actual validation results separately; an expected delta is not a claim of Architect acceptance.

**Recommendation: ready for focused independent re-review of the F-01–F-04 corrections before Architect acceptance. C1 remains DRAFT / NOT FROZEN / ARCHITECT ACCEPTANCE PENDING. Implementation remains unauthorized; the registered reconciliation and commercial open questions remain unresolved.**

---

## 25. C1 final Architect acceptance record

Record date: 2026-10-02

- Independent focused re-review: PASS / A — C1 READY FOR ARCHITECT ACCEPTANCE
- Architect Acceptance: APPROVED
- Commercial decisions changed: 0
- Architecture reconciliation rules changed in this pass: 0
- AR entries resolved: 0
- Implementation authorization: NO
- Authority: ChatGPT Architect

C1 is accepted as the canonical commercial architecture reconciliation authority. This record and the current header supersede earlier draft / acceptance-pending status wording; the passed content and historical drafting evidence remain unchanged. Acceptance is NOT implementation authorization and is distinct from any future implementation-contract authorization or freeze. AR-01 through AR-14 remain unchanged and OPEN / deferred; no future contract family is resolved or authorized by this acceptance. The Frozen Commercial Model and roadmap remain unchanged.
