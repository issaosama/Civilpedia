# Civilpedia — Subscription, Entitlement & Publication Enforcement Architecture V1

CONTRACT_ID: C3
CONTRACT_VERSION: V1
DOCUMENT_STATUS: ACCEPTED — CANONICAL COMMERCIAL SUBSCRIPTION, ENTITLEMENT & PUBLICATION ENFORCEMENT TECHNICAL ARCHITECTURE AUTHORITY
FREEZE_STATE: ACCEPTED — TECHNICAL ARCHITECTURE ONLY
ARCHITECT_ACCEPTANCE: APPROVED
MODE: TECHNICAL ARCHITECTURE / DOCUMENTATION ONLY
IMPLEMENTATION_AUTHORIZED: NO
PREPARED_DATE: 2026-10-02
REPOSITORY_BASELINE: main @ 27359f8c574e5d5c4e301a67368d7178e348fa74
LOCAL_ORIGIN_MAIN_BASELINE: 27359f8c574e5d5c4e301a67368d7178e348fa74
ACCEPTANCE_AUTHORITY: ChatGPT Architect
GIT_OWNER: User

## Authority and executive position

The [Frozen Commercial Model](../CIVILPEDIA_COMMERCIAL_MODEL_V1.md) is policy authority; [accepted C1](CIVILPEDIA_COMMERCIAL_CORE_AUTHORITY_RECONCILIATION_CONTRACT_V1.md), current acceptance §25, is reconciliation/security authority; [accepted C2](CIVILPEDIA_COMMERCIAL_PUBLICATION_ENTITLEMENT_CONTRACT_V1.md), current acceptance §31, is conceptual publication/entitlement authority. C3 recommends concrete future backend design under all three. Proposed object and operation names are design identifiers, not objects created by this document. Every technical recommendation remains subject to independent review and Architect acceptance.

**Recommendation:** retain `public.plans` as stable identity with a versioned companion catalog; retain existing `public.subscriptions` as legacy evidence and introduce private commercial agreements with immutable purchased terms. Represent A8 in a dedicated promotional-grant domain. Derive effective rights on the server. Serve an approved safe Directory snapshot through guarded read RPCs using current private publication authority, enforcement generation, and server-time deadlines. Use additive migration, evidence-based reconciliation, and a separately authorized public-access cutover; never reinterpret legacy `active`/`trialing` by naming alone.

Only this Markdown file may be created. No SQL, migrations, RLS, RPC, Flutter, tests, policy, C1, C2, or roadmap is modified. No stage, commit, push, reset, revert, or stash. The [Master Roadmap](../CIVILPEDIA_V1_MASTER_ROADMAP.md) still identifies R10.5-D as an audit-only CURRENT slice; this expressly authorized C3 design does not authorize implementation or advance it. The [Agent Operating Model](../CIVILPEDIA_AGENT_OPERATING_MODEL.md) retains routing/Git authority. Commercial freeze, C1/C2 acceptance, and later C3 acceptance are each distinct from implementation authorization.

Policy traces below use the policy's current frozen §33 and preserved amendments: §2/§§2.1, 2.5; §§3–10, 13, 19; §§26.1–26.7; §§27.1–27.3; §§28.1–28.6, 28.8, 28.11–28.14; §§31.1–31.3; §§32.2, 32.5–32.11. All OPEN OQs retain their SSOT status, severity, owner, and classification. C3 closes no policy OQ, C1 AR, or C2 register entry.

## 1. Re-inspected existing engineering baseline

Source was re-inspected at `27359f8`; these are repository definitions, not a deployed-schema/data audit. Migration inventory currently ends at 00021. No live Supabase queries, resets, runtime tests, or remote fetch were performed. C2 §31 records the latest relevant independent review PASS / A and Architect approval; prior R05/R07/R08 evidence is historical, not a C3 verification gate.

| Exact source | Verified existing behavior and C3 consequence |
|---|---|
| [00005_directory_entities_and_categories.sql](../../../supabase/migrations/00005_directory_entities_and_categories.sql) | Canonical entity UUID; nine supported types; lifecycle `draft/active/inactive/suspended`; verification `unverified/pending/verified/rejected/suspended`; claim `unclaimed/pending/claimed`. Categories have stable code/UUID, parent, bilingual labels, `is_active`; none is commercial authority by itself. |
| [00006_entity_relationships.sql](../../../supabase/migrations/00006_entity_relationships.sql) | Membership PK `(user_id, entity_id)` with OWNER/ADMIN/MEMBER; category assignments and one primary; locations with region/address/optional paired coordinates and one primary; contacts/media. Locations are not a fully reconciled commercial Branch model. |
| [00008_plans_and_subscriptions.sql](../../../supabase/migrations/00008_plans_and_subscriptions.sql) | Plans: UUID, unique text code, name/description, active flag. Subscriptions: entity/plan FKs, mandatory start, nullable end/price/currency, five legacy status values; no payment linkage, term chain, promo program, or catalog seeding in this migration. |
| [00007_business_applications.sql](../../../supabase/migrations/00007_business_applications.sql), [00011_business_application_write_hardening.sql](../../../supabase/migrations/00011_business_application_write_hardening.sql), [00014_business_application_claim_hardening.sql](../../../supabase/migrations/00014_business_application_claim_hardening.sql), [00015_business_application_claim_concurrency_hardening.sql](../../../supabase/migrations/00015_business_application_claim_concurrency_hardening.sql) | NEW/CLAIM workflow and operational contacts/visits/notes; subsequent write/claim hardening. Application approval/activation is separate from entity verification and commercial entitlement. Preserve history, not future open-claim authorization. Claimability is validated at insert only: 00015 locks the target entity by id and re-checks `claim_status` under that lock, and holds no reservation afterwards. The partial live-CLAIM index releases its own slot once the application is final (REJECTED/ACTIVATED) so a later claim insert is permitted, while an ACTIVATED target still fails insert-time validation because activation set `claim_status = 'claimed'` (never reset by any current migration). |
| [00003_profiles_and_staff_roles.sql](../../../supabase/migrations/00003_profiles_and_staff_roles.sql), [00004_roles_permissions_and_staff.sql](../../../supabase/migrations/00004_roles_permissions_and_staff.sql) | Staff roles/permissions and active/effective/unexpired staff memberships; separate from business memberships. Reuse authority chain, not existing application permissions for finance. |
| [00009_audit_logs.sql](../../../supabase/migrations/00009_audit_logs.sql), [00016_business_application_server_mutations.sql](../../../supabase/migrations/00016_business_application_server_mutations.sql) | Audit actor/action/target/before/after/reason/time; internal `append_audit_log` participates in mutation transaction. Staff helper derives actor from `auth.uid()`, permission chain; mutations lock rows and restrict EXECUTE. |
| [00017_business_application_creation_authorization_hardening.sql](../../../supabase/migrations/00017_business_application_creation_authorization_hardening.sql), [00018_business_application_activation_ownership_provisioning.sql](../../../supabase/migrations/00018_business_application_activation_ownership_provisioning.sql) | Creation through definer RPCs; activation locks application then entity, provisions OWNER and claimed state atomically with audit. Consistent ACTIVATED replay returns without another provisioning; corruption is rejected rather than self-healed. NEW entity starts from schema defaults, not commercial publication. |
| [00019_business_ownership_management_foundation.sql](../../../supabase/migrations/00019_business_ownership_management_foundation.sql) | `list_my_businesses`, `list_business_members`, internal `has_business_management_access`: current OWNER/ADMIN management, not canonical Primary/Co-Owner mapping or financial grants. |
| [00020_business_profile_management.sql](../../../supabase/migrations/00020_business_profile_management.sql) | `update_managed_business_profile` locks entity, checks expected timestamp, validates, immediately writes contacts/categories/location/profile and sanitizes audit. Verified name/location changes reset verification to pending. No proposed/published split; later commercial cutover must mediate this path. |
| [00021_staff_application_operations_foundation.sql](../../../supabase/migrations/00021_staff_application_operations_foundation.sql) | Narrow application capability discovery plus bounded keyset queue/detail; independent per-RPC permission checks. No commercial permissions or finance read surface. |
| [00010_rls_authorization_baseline.sql](../../../supabase/migrations/00010_rls_authorization_baseline.sql) | Public entity SELECT is lifecycle `active`; children use active parent. Category/plan reference SELECT is unfiltered. Subscriptions/staff/audit lack ordinary client table grants. New private state must not join into public payloads. Read 00010 with later hardening, not its superseded application write grants alone. |
| [supabase_directory_read_gateway.dart](../../../lib/features/directory/data/supabase_directory_read_gateway.dart) | Direct nested SELECT with explicit fields; list ordered by name, detail UUID limit one, strict whole-result parsing. Includes lifecycle/verification/claim fields. List has no explicit pagination or application limit; the configured PostgREST `max_rows = 1000` bounds local results, and the deployed value is unverified. |
| [canonical_directory_entity.dart](../../../lib/features/directory/domain/canonical_directory_entity.dart), [app_dependencies.dart](../../../lib/core/di/app_dependencies.dart) | Canonical UUID model, fail-closed supported state/type parsing, one production cloud read seam; no competing Directory identity. |
| [directory_cloud_cache.dart](../../../lib/features/directory/data/directory_cloud_cache.dart), [supabase_cloud_directory_repository.dart](../../../lib/features/directory/data/supabase_cloud_directory_repository.dart) | Version-1 complete SharedPreferences snapshot; known-good preservation, authoritative empty replacement, coalesced refresh, cache-first resolution; no commercial validity deadline/revocation lease. Refresh timestamp is currently device capture, not commercial time authority. |
| [directory_detail_controller.dart](../../../lib/features/directory/application/directory_detail_controller.dart), [directory_refresh_controller.dart](../../../lib/features/directory/application/directory_refresh_controller.dart) | Cached/seed versus authoritative detail distinction, guarded asynchronous refresh/reconnect; preserve generation safety while adding future public validity handling. |
| [plan_type.dart](../../../lib/core/access/plan_type.dart), [plan_tier.dart](../../../lib/core/access/plan_tier.dart), [service_business_profile.dart](../../../lib/features/profile/domain/service_business_profile.dart) | Legacy free/proEngineer/supplier/company product labels and owner/admin/moderator/support role labels mix products and roles in one enum; default feature matrix and legacy planType/featured/foundingPartner are not frozen commercial catalog or entitlement. |
| [config.toml](../../../supabase/config.toml) | Local DB major 17; API exposes public/graphql_public, max_rows 1000. Private companion schema is not to be added to exposed schemas. No claim that deployed configuration matches. |
| [R05 correction report](../reports/V1-R05_DIRECTORY_CLOUD_INTEGRATION_CORRECTION_REPORT.md), [R07 correction report](../reports/V1-R07_STAFF_ADMIN_OPERATIONS_CORRECTION_REPORT.md), [R08 closure report](../reports/V1-R08_CLOSURE_REPORT.md) | Historical strict parsing, complete-cache and permission/session evidence, not fresh commercial acceptance. |

Technical platform checks use primary [PostgreSQL 17 time documentation](https://www.postgresql.org/docs/17/functions-datetime.html), [function security documentation](https://www.postgresql.org/docs/17/sql-createfunction.html), and [row security documentation](https://www.postgresql.org/docs/17/ddl-rowsecurity.html): transaction time and wall time differ; definer functions require safe namespace/EXECUTE configuration; owners/privileged roles can bypass ordinary RLS. The proposed boundaries explicitly account for those behaviors.

## 2. No status collapse; proposed object boundaries

Payment != subscription agreement != entitlement interval != publication != verification != entity lifecycle != moderation/enforcement != ownership. Use separate typed domains and FKs/events, not a mega-status or an in-place rename of existing checks.

Recommend a **non-exposed `commercial_private` schema** for all new authority/history records. Existing canonical entity and plan UUIDs remain in public; public RPC wrappers return explicit safe DTOs. Below is a proposed logical schema inventory, not executable DDL or a grant of implementation scope:

| Proposed record family | Core keys/data; ownership of facts |
|---|---|
| `plan_versions`, `term_prices` | Plan FK/version, Arabic metadata/order, bundle FK, effective window, published/retired markers; currency/amount/duration/source/promo price context. Append new commercial versions. |
| `entitlement_bundles`, `bundle_items` | Immutable bundle UUID/version; supported typed capability keys, explicit limits/flags; no executable client configuration. |
| `commercial_agreements`, `commercial_terms`, `term_events` | One ordinary base-service agreement per entity; stable paid term/order FK, predecessor, purpose, immutable price/benefit snapshot; write-once anchor/end and append adjustments/cancellation history. |
| `founding_eligibility`, `program_versions`, `promotional_grants` | Business-linked evidence of approved Founding eligibility; versioned A8 policy parameters/launch reference and a dedicated grant with selection evidence, anchor events and interval. Programs are not base plans. |
| `commercial_orders`, `payment_records`, `payment_allocations`, `financial_adjustments`, `evidence_refs`, `corporate_quotes` | Agreed product/amount snapshot, intended term, independent payment decision, allocation ledger, explicit refund/credit/approved adjustment, private evidence/object references, versioned written quotation. No CRM or tax model. |
| `business_publication_authority`, `directory_public_snapshots`, `publication_events`, `enforcement_actions` | Per-entity revision, approved content/gate versions, publication evidence, current blockers and safe public payload; enforcement and publication history separate from financial history. |
| `launch_authorizations` | Category/market scope, checked supply evidence and authorization revision; dependency on future Taxonomy and OQ-84 decisions. |
| `command_receipts`, `commercial_outbox` | Actor/business/operation/key/payload-hash/result references; durable unique operational event delivery after commit. Neither is public. |

All Business FKs refer to `directory_entities.id`; use RESTRICT/retention-preserving behavior for history, not cascading destruction. No new owner_user_id or competing Business ID. Logical state codes use narrow checked text/reference definitions; unknown source/operation/status/capability is rejected. Final DDL/index/grant/function signatures require the later slice contract.

## 3. Existing plans — recommended option B

**Retain `public.plans` as identity, with companion commercial tables.** Its existing UUID and unique code are suitable stable anchors, but its mutable name/description/active flag cannot store historical price/bundle truth. Reserve machine codes `business`, `business_pro`, `business_plus`, `corporate` for the approved families after collision/data inventory; never rename an existing conflicting row automatically. Stable code cannot change meaning; new semantics require a new version or, if identity truly changes, an explicitly mapped new plan.

Reject putting all prices/limits into that row: it would overwrite historical meaning and leak internal future catalog drafts through current unfiltered public SELECT. Reject wholesale replacement: no demonstrated need to break existing FKs. C3 recommends technical values for the OQ-23 architecture seam without editing or closing its policy register entry.

Founding is paid pricing eligibility/history; A8 is a promotional source; Sponsored is its own product. None gets a base-plan UUID disguised as a fifth retail plan.

## 4. Commercial catalog and prices

`plan_versions` binds a plan UUID to immutable approved display/benefit metadata, bundle version, commercial ordering and availability windows. Retirement prevents new offers, not fulfillment of purchased terms. Published metadata can be replaced only by a new version; Arabic display copy enters the canonical localization/content authority, not ad hoc client constants. Public catalog RPC returns only currently published marketable metadata and approved offers; drafts, private approval identity and internal notes stay private.

**Price points belong in separate `term_prices`**, linked to plan version and calendar-month duration, with effective-from/to, integer IQD units and immutable version ID. No float amounts. Catalog validation disallows overlapping published standard offers for the same family/duration/time, negative amounts, unsupported currency or a six-month retail option. Corporate has no retail price point; a quotation supplies its price.

| Retail family | 1 month IQD | 3 months IQD | 12 months IQD |
|---|---|---|---|
| Business | 20,000 | 55,000 | 200,000 |
| Business Pro | 40,000 | 110,000 | 400,000 |
| Business Plus | 70,000 | 190,000 | 700,000 |

These reproduce frozen §3.2 exactly; not new prices. Include only 1/3/12-month availability; Corporate minimum is 12 months by quote. Future price change produces a new effective offer, policy notice metadata and audit; no purchased term revaluation. Extra-Branch exploratory prices and provisional media limits are not seeded as approved offers.

## 5. Price snapshots and historical integrity

An accepted order and each purchased term retain immutable `plan_id`, `plan_version_id`, `bundle_version_id`, duration/calendar convention, agreed gross amount/currency, price-version/source, written quotation where applicable, discount/program eligibility evidence, separately agreed add-ons, and approval/evidence references. Store snapshots of agreed material benefits as well as catalog references; verify their hash/version before activation. No naked arbitrary client JSON may grant a capability.

Payment allocations are distinct from agreed price: overpayment is not an upgrade, underpayment is not a shorter unauthorized term. Every refund/credit/adjustment has its own event and linkage; never edit an old price to make balances agree. Catalog deletion/retirement cannot delete historical references. New official price applies to a newly agreed renewal, with explicit promotions preserved per policy §26.3.

## 6. Founding Partner representation

Use private `founding_eligibility` keyed to the genuine entity and approved initial-cohort reference, with approval/evidence/audit, eligibility scope and retained history. A purchased annual term links the eligibility record and the actual discounted offer snapshot: Business 150,000, Pro 300,000, Plus 525,000 IQD for the eligible first year (§5.7). These are paid prices, not free benefit grants; no derived percentage becomes a new policy.

Badge/history survives independently of the consumed pricing benefit; its public exposure waits for OQ-14's approved presentation. A legacy foundingPartner boolean imports only as unverified evidence, never approved eligibility. No automatic “first 50 rows/payments” allocator: OQ-02 owns counter definition/evidence, OQ-01 owns 1/3-month first-term prices. The structure records eligibility attested under the eventual approved procedure and rejects duplicate normal first-year pricing redemption; it does not choose an ordinal algorithm or grant eligibility to #51+. No automatic later cohort.

## 7. A8 promotional representation — dedicated grants

Choose **dedicated `promotional_grants`**, with FK to entity, A8 program version, Pro bundle version, controlled invitation/selection evidence, accepted onboarding dependency, formal launch reference, first successful post-launch publication event, immutable start/end when anchored, and event history. A8 is 0 IQD/60 calendar days, not a fake zero-value payment or legacy `trialing` subscription. Normal ordinary grant uniqueness is enforced per program/genuine entity under serialized entity validation; duplicate detection authority is supplied by the OQ-72 contract, not a name-only heuristic.

Reserved/selected does not mean in effect. Activation requires the frozen later-of-launch/post-launch-publication anchor. At expiration, time evaluation removes A8 entitlement and density qualification even if an expiry worker is absent. Previously public profiles can continue through ordinary five-day Grace; no automatic payment instrument, renewal or charge.

OQ-80 controls cohort selection/cap/exhaustion/revocation and remaining-day consequences; OQ-81 controls normally-once exceptions and transfer/entity-change continuity. Preserve immutable evidence and an extension point for later approved exceptional decisions; no executable repeat/revocation/forfeiture path is enabled without those decisions. Expiry is deterministic time behavior, **not** policy-discretionary revocation. OQ-72 duplicate merge/retirement mechanics remain separate.

## 8. Canonical subscription and terms — new private aggregate

Recommend **wrap the legacy domain with new canonical agreement + term records**, not mutate the existing row into a loss-of-history aggregate. `commercial_agreements` identifies the entity's ordinary base service. `commercial_terms` records each paid initial purchase, early/Grace renewal, reactivation, conversion or approved Corporate term. Paid terms carry predecessor and order/payment authorization references; A8 intervals remain in their dedicated grant table and are joined by the evaluator, not duplicated as paid terms.

Immutable purchase facts are separated from a write-once anchor decision; pending initial/reactivation terms may have no start/end yet. No public validity derives from a NULL deadline. Once anchored, retain original start/paid expiry permanently. Cancellations, approved extension/credit and corrections append `term_events`; an effective interval is derived from the original facts plus authorized events. Never overwrite original expiry or history. A term correction needs attributable authority and explicit supersession, not deletion.

Under entity lock, enforce one selected ordinary base-service basis at an instant and a non-overlapping paid renewal chain. Do not sum Pro/Plus/promo limits or use an implicit “highest tier wins.” Future paid conversion can be prepared while A8 runs, but the selected paid service transition must preserve both frozen anchors and approved remaining days; its exact transition contract is a dependency (§43), not a hidden catalog default. Add-ons attach to that agreement/entity, never create duplicate Business identity.

Cancellation is recorded independently of expiry/enforcement. No automatic refund or early forfeiture is invented; apply frozen §28.2 and explicit approved terms. Suspension does not overwrite term state or pause a customer-caused clock.

## 9. Versioned entitlement design — recommended hybrid

Choose **versioned database bundles with a fixed server capability registry/evaluator**. DB versions hold approved values; server code recognizes allowed keys/types, composes time/source/authority, and rejects unknown capabilities. Flutter consumes safe results and cannot interpret a downloaded arbitrary rule language. Reject a hardcoded full server plan matrix: commercial changes would require code releases and lose version trace. Reject unconstrained JSON grants: weak typing or a misspelled key could grant unsafe rights.

Initial supported items include base plan family, included Branches (Business 1/Pro 2/Plus 3), ordinary team ceiling 5, approved profile/media/analytics feature availability, and plan-level Sponsored prerequisite. Corporate extends the Plus floor by approved quote. This is not a full entitlement inventory: undefined media quotas, access during Grace (OQ-12), analytics retention/visibility (OQ-17), extra-Branch cap/pricing (OQ-03), and detailed modules await their owners. Unknown required limits deny the dependent operation rather than becoming unlimited or zero-priced.

Operational capability = approved commercial benefit AND canonical actor capability AND applicable operational/enforcement constraints. Financial visibility is never granted by a generic team membership or a plan feature. Management access during suspension follows its distinct frozen owner/security rule, not generic expired-benefit behavior.

## 10. Effective Commercial Entitlement

One internal server evaluator, invoked with canonical entity and **server-captured authoritative time**, returns: approved commercial basis exists; currently in-effect paid/promo basis; source and agreement/term/grant IDs; selected family/bundle/version/approved limits; pending-anchor versus future versus active versus Grace versus after-Grace context; original/effective end and Grace end; enforcement context and denied-use reasons. The private result can include financial evidence references; the public projection never returns them.

Grace means a retained expired basis with a continuation window, **not active paid/promo entitlement**. The evaluator separately returns prior-publication continuity eligibility. Suspension/closure can leave historical purchased rights intact while suppressing their public use. Ownership recovery is a separate interface result, not a reason to detach entitlement from the entity.

The private evaluator must be deterministic over supported versioned records at the captured time. Missing/unreconciled basis, conflicting overlapping sources, unsupported capability/status or a stale dependency version does not yield a grant. Public discovery is a separate evaluator (§17), never a side effect of this result.

## 11. Manual payment domain and linkage

`commercial_orders` snapshot agreed plan/duration/price/Business and approved payment instructions. `payment_records` retain submitted amount/currency, intended order/entity, approved destination/channel reference, minimal payer/linkage data, private evidence refs, independent verification outcome, verifier/time and clarification/rejection reason. Verify actual received funds through authorized finance/admin authority; a screenshot never activates.

`payment_allocations` link reconciled verified funds/explicit credit to orders; unique transfer identity after reconciliation prevents one receipt/funds record buying two terms. Collect only minimum necessary transfer data. `financial_adjustments` track approved commercial short-payment adjustments, refund/credit and overpayment/duplicate dispositions; they do not quietly rewrite paid price.

Unclear evidence stays unverified; short payment cannot activate until satisfied or explicitly adjusted; overpayment is explicitly refunded/credited; duplicate receipt/transfer is reconciled; third-party payer requires explicit intended-Business linkage and gains no ownership; wrong destination rejected; forged evidence routed to fraud enforcement. Payment for a closed/suspended/invalid Business cannot activate (§28.1). Payment verification does not clear a publication blocker.

Evidence lives behind private object access and private metadata, not a public media bucket URL; Media/Payment Operations specify bucket policy/signed access later. Separate customer-facing financial status from internal fraud/staff notes. Never embed evidence or payer PII in public snapshots, telemetry or sanitized audit. Approved destinations, tax/invoice obligations and statutory retention are not invented (OQ-09/OQ-40 and §30).

## 12. Deterministic term anchors

Required trusted facts: verified-funds decision time and allocation; documented materials requests; outstanding required materials/reviewer readiness; cause-of-delay decision with evidence/version; publication availability event; formal-launch event; term purpose/predecessor; rule version. Client timestamps are observations only. Finance verification and content approval remain independent.

Initial paid publication transaction validates the approved paid basis and other gates, records successful public availability, and writes the term's initial anchor/end atomically. A failed/rolled-back publish transaction consumes no time or audit anchor. Success means the approved payload is durably made available under server discovery authority, not a user having opened a screen or just an application reaching ACTIVATED. The timestamp is captured late in the bounded publish transaction; it is not a backdated estimate of user views. No long-running transaction may claim an old availability time.

For the day-15 exception, trusted delay evidence must prove sole customer failure despite documented requests **at the deadline**. An authorized causal decision records the effective rule anchor at the 14-day-window end (§13). A server due-work processor materializes the write-once anchor/event; any dependent evaluation reconciles a due approved anchor before granting/use. Its effective time remains the rule deadline if processing is late; it never silently changes to worker run time. Civilpedia/mixed/unknown cause cannot trigger this exception. Materialized history records both effective rule time and later recorded time.

Later evidence must establish historical cause, not retroactively invent it. Missing approved cause/evidence keeps the exception unproven; staff may not backdate an anchor merely to clear a queue. Normal publication after a proven day-15 start does not reset or lengthen that term. Reactivation uses verified payment plus successful republication, with no inherited old-expiry/day-15 backdate.

## 13. Time authority and boundary convention

Propose **UTC instants in `timestamptz`, Asia/Baghdad policy-calendar arithmetic and Arabic business-facing dates**, with the calendar-rule version captured in terms/programs. Device clock/timezone never decides commercial validity. The host shell timezone is irrelevant.

For durations stated as N calendar days, add N Baghdad local calendar dates while retaining the anchor's local time of day, then convert the endpoint to UTC; no rounding the partial first day away. The 14-day window is `[verified_at, verified_at + 14 calendar days)`; day 15 starts at that endpoint. Grace is `[effective_expiry, effective_expiry + 5 calendar days)`; A8 is `[promo_start, promo_start + 60 calendar days)`. At an end instant the old interval no longer applies; exactly Grace-end is after Grace. This proposed consistent interpretation requires C3 acceptance; it changes no numeric duration or creates an extra free day.

Purchased months use calendar-month addition in Baghdad from the applicable term start/end anchor; clamp an absent day to the final valid day of the target month, retain local time-of-day, then persist the computed endpoint. No 30/90/365-day surrogate. Each new renewal starts at its actual prior paid end and adds its purchased months; carry no invented January-31 anniversary override across a February-clamped end. Leap/year/month-end fixtures must demonstrate the accepted convention before activation.

Capture DB wall time once **after required write locks are obtained** for deadline classification; revalidate if work crosses the boundary before committing a grant. Do not use a stale transaction-start time after a long lock wait. Read requests use one captured server-time instant with a bounded consistent snapshot. Deadline denial cannot rely solely on a worker-stored state. PostgreSQL distinguishes transaction and changing wall time; implementation chooses function volatility/signatures to match this requirement, not a client-supplied evaluator time.

Reminder events derive from effective paid expiry using frozen §26.2 cadence; dedupe by term/rule/offset/channel. Verified renewal suppresses obsolete reminders; pending-verification messaging is separate. Display exact Baghdad dates and deadlines. No scheduler/vendor chosen; bounded due-work/reconciliation and reminders have explicit lag monitoring and durable outbox requirements.

## 14. Renewal chains

Under canonical entity/term/order/funds serialization, validate the independent payment decision and expected agreement revision, then append a new term with predecessor and agreed current offer snapshot. Before expiry, start at the already committed paid end; during Grace, start at the original previous paid expiry (including approved effective extensions), not verification date. Original term data stays immutable; new paid interval covers elapsed Grace as frozen continuity, not an extra free extension.

After Grace ends, create a pending reactivation term, not a renewal backdated to old expiry. Payment arriving after Grace is classified as reactivation; C3 does not invent a receipt-submission cutoff exception for funds still unverified. Recheck deadline under lock; pending-payment reconciliation spanning the boundary requires Payment Operations' explicit evidence/order handling without weakening §28.1/C2.

Duplicate verification/allocation cannot append another renewal; unique source order/allocation consumption plus command receipt enforces this. A stale early-renewal screen cannot extend a superseded head silently: reject expected-version mismatch. Manual-only agreement, no stored payment instrument or automatic renewal/charge. A newly paid scheduled renewal may become current automatically at its committed start; that is fulfillment of a verified purchase, not a new charge/renewal.

## 15. Grace — computed, not a mutable entitlement

Choose **computed Grace from the effective term/grant expiry**, with append-only transition/reminder events for history. Do not persist a permissive `grace_active` flag that can outlive a worker. Derived five-day boundary is authoritative for read gating. Approved extension events modify effective end; recompute derived Grace accordingly while retaining the original expiry.

The policy's specific §26.2.7 is the explicit continuation of visibility after the general §8.2 composition's active paid basis expires (C2 §12 clarification). Require prior successful publication and no stronger override. A never-published day-15 incomplete Draft cannot use Grace to publish. At Grace-end without valid replacement, public reads deny immediately; a worker later records the effective hide event without extending visibility.

No A8 density counting during promotional Grace. Visibility alone grants no Sponsored, management-access mode or analytics visibility. Those interfaces remain conditional on OQ-12/OQ-17 and separate product rules.

## 16. Reactivation

Record a new order/verified allocation and new term purpose `reactivation`, linked to the preceding agreement/history but with pending anchor. After all current gates are satisfied, successful republication atomically starts the new term and creates a publication event. Never copy the old expiry into its start or apply old customer-delay evidence. Reuse canonical identity/retained content, not rebuild it.

Payment alone cannot release suspension/termination/closure. Reopening/appeal/re-entry evidence belongs to its domain and must precede eligible republication. Source payments/allocations are consumed once; replay returns the original committed reactivation result with no new clock.

## 17. Canonical publication authority

One private authority revision per Business records **selected approved public-content version**, initial/publication continuation mode, gate version/result, ownership-readiness version, moderation decision reference, operational/enforcement revision, qualified commercial basis and launch-scope revision. It is distinct from raw entity lifecycle and from the entitlement result.

Server evaluator answers “may this Business be discoverable at this time in this requested category/market?” by composing genuine eligible entity/model, valid approved paid/promo basis or prior-publication Grace continuation, applicable gate/onboarding/moderation, no suspension/termination/confirmed closure, and authorized launch scope. Missing/conflicting/unreconciled required authority denies. Separate intrinsic per-Business readiness from category-opening checks so counting does not recursively require an already-open category (§24).

A pre-publication paid/promotional reservation can support the publication transaction that establishes its anchor; it is **not** current in-effect supply before that transaction. For a previously operating Business, canonical ownership recovery does not automatically remove visibility absent risk; never equate this with publishing never-owned Drafts. Full Verified is not universally required; a circumstance-specific check comes from the independent Verification authority.

OQ-48 determines consequences of a known post-publication quality shortfall; OQ-49 determines approver/automation model. A stale/missing evidence version cannot grant a new publication, but C3 does not manufacture a post-publication cure/takedown policy to answer OQ-48. Cutover of affected cases requires the proper policy decision; unchanged approved content can remain distinct from an unapproved proposed edit.

## 18. Public read projection — recommended hybrid

Choose **transactionally maintained private publication authority + immutable safe content snapshots + secure read RPC with live guards**. Do not make complex public RLS join payment/ownership tables for every nested child. Do not trust a materialized “published” flag alone: time can expire without a write. A secure view alone risks accidentally broad owner privileges/SELECT expansion; explicit bounded RPC output is preferred at the API seam.

`directory_public_snapshots` stores only approved public identity/category/location/contact/media content, canonical entity UUID, projection format/content generation and optional approved public trust labels. It has no payment, owner IDs, raw claim state, staff/fraud/financial data. A pointer in authority selects its version. Read RPC joins only guarded publication/launch control and this snapshot; it rechecks server time, current deny/closure/enforcement revision, valid selected basis/Grace interval and dependency freshness on every request. Deny overrides are committed before returning successful enforcement mutation. A stale snapshot or generation mismatch can never rescue access.

Bounded page and UUID detail endpoints return safe DTO plus server observation time, opaque publication revision and conservative validity boundary; do not disclose private expiry/source/reason fields. Internally index entity, launch scope, authority revision and validity boundaries; verify execution plans under expected catalogs. The private control record holds financial-related deadlines; public leases must not reveal precise subscription expiry. Counts use the same intrinsic authority predicates (§24), not public row totals.

The live guard evaluates the committed agreement/term chain at request time, including already purchased scheduled successors and approved extensions. It does not require a worker to switch an old current-term pointer or refresh a cached expiry before recognizing the next paid interval. Projection/content revision remains separate from this time-derived commercial result. A request cannot use an old source's Grace window to override a newer denial or an unresolved source conflict.

First publication is an atomic **make-available transaction**: gate validation, chosen snapshot, term/grant anchor where required, authority revision, publication/audit events and outbox all commit or none. First request/user view is not the commercial anchor. A read request never writes term/payment facts. Read-time deadline enforcement is mandatory even if history/outbox/recompute jobs stop.

Content mutations, required-input/version changes, enforcement, commercial amendments and canonical ownership/verification decisions synchronously update/invalidate authority in the same transaction. Integrating existing immediate profile writes is a cutover prerequisite (§26); eventual-only invalidation is unsafe. Future Branch publication uses scoped child readiness under parent authority, not extra subscription identities.

## 19. Public data leakage boundary

Public output allowlist: canonical UUID/type, approved name/description, authorized categories/geography, intended public contacts/media and approved independent labels. Exclude payment evidence/amounts, financial details, internal subscription notes, payer/verifier/owner IDs, ownership-sensitive claim/invitation metadata, risk flags, staff notes, private audit IDs and denial reasons. No `SELECT *`, arbitrary table-row serialization or user-controlled nested selection.

The current gateway includes claim/lifecycle/verification raw fields; later DTO adaptation must separate safe public outcomes/trust from those engineering fields, not invent claim ownership or copy raw Verified. Preserve canonical UUID/routes and valid child presentation through a narrow gateway/domain adapter; exact DTO/Flutter mapping requires its authorized integration contract. Detail absence must not leak whether hidden UUIDs have outstanding debt/fraud. Historic closed direct-link output awaits OQ-68 and must never return misleading active contacts/claims by fallback.

## 20. Enforcement overrides

Private `enforcement_actions` records actor/source, effective/recorded time, warning/correction deadline, grounds/evidence refs, action scope and supersession. A current per-Business enforcement revision distinguishes warning from denial; no subscription-status overwrite. Seven calendar days for non-serious correction; serious risk can suspend immediately. Suspension denies publication/Sponsored despite entitlement; termination and confirmed closure exclude discovery, stop Sponsored and inactivate verification via its canonical dependency. Closure request alone is not confirmation.

Customer-caused suspension leaves paid clock running. Civilpedia-error remediation is an attributable extension/service-credit event, not mutation of historical price/start. Lifting a restriction requires its authorized evidence and separate gates; no payment/RPC retry auto-clears it. Keep owner management access during suspension unless fraud/security requires otherwise; exact RBAC remains a dependency. Termination appeal, closure/reopening, refund and re-entry policy are preserved without inventing extra appeal or reinstatement rights.

## 21. Publication and audit events

Reuse existing `public.audit_logs` and internal `append_audit_log` pattern; no new public audit writer. Retain its actor/action/target/before/after/reason/time; mutations append sanitized commercial IDs/revisions/decision codes and linkage to private domain events. If audit fails, roll back the state transition. Private typed term/publication/payment histories hold details needing domain consistency, not raw PII dumped into audit JSON.

Events include first publication, hide/republish, suspension hide, Grace-end expiry hide, reactivation publication, confirmed closure, anchor decision, extension/credit, and permitted staff override. Store **effective_at** distinct from **recorded_at** for delayed time-based history, cause/source rule version and predecessor/revision; unique event cause keys prevent duplicate hide/anchor history. Worker identity is a narrowly trusted server principal, not a fabricated human JWT or caller-supplied user ID. Client actors always derive from authenticated identity.

Publish durable outbox records in the same transaction for downstream refresh/reminders/reconciliation. Consumers are idempotent, bounded and reconcile current revision before applying an old event; no delivery message can re-publish a superseded snapshot. Outbox lag is observable, never the only public deny mechanism.

## 22. Required Fields technical interface

One server validator accepts canonical entity, **candidate approved-content revision**, category requirements version, applicable module/Branch/media projections, and returns satisfied/incomplete/unknown with internal structured reasons and evidence version/hash. Future Business/Taxonomy/Media contracts supply versioned schemas/requirements; C3 invents no exact field list or media quota. Supported typed validation rules, no downloaded executable policy.

Client validation assists UX only. Initial incomplete/unknown blocks publication; successful result binds to the exact content/requirements version used in publish. Concurrent profile/media/category edits cannot reuse an old pass. Do not infer that a raw known-good legacy row meets the commercial gate. Post-publication quality outcome/approver authority remain OQ-48/OQ-49, with exact matrix OQ-76.

## 23. Minimal Ownership / Onboarding dependency

Require an internal canonical interface returning genuine entity identity continuity, accepted normal onboarding readiness, accepted Primary Owner process evidence/version, recovery-pending continuation permission/risk, actor capabilities for nonfinancial/financial operations and invalidation generation. It derives from the future Ownership/RBAC authority, not a new owner UUID on the entity or a count of legacy OWNER rows.

Do not map OWNER/ADMIN/MEMBER to Primary/Co-Owner/Manager/Editor. Existing management helpers remain authoritative for accepted old features until explicitly changed, but cannot authorize new commercial finance reads or self-publication. Pending invitations grant nothing; no password handover/open claiming. OQ-71/78/79/81/82/83 remain with their existing owners. A missing interface blocks dependent commercial cutover, not the additive foundation recommendation.

## 24. Launch-density authority and bootstrap

Choose **hybrid derived supply + auditable administrative launch authorization**. Count DISTINCT genuine entity UUIDs per applicable category/Baghdad market from current intrinsic publishability and **in-effect qualifying commercial basis**; exclude duplicates, unknown readiness, suspended/terminated/closed, paid expiry/Grace-only and expired A8. Grace visibility does not itself constitute active paid/promo density. Future taxonomy defines applicable category assignments; multiple contacts/locations cannot inflate one category's Business count. Geography/Branch duplicates require the Business/Taxonomy interface, not a guessed legacy label.

`launch_authorizations` records scope, authorized actor, trusted time, evaluated count/source revisions, category eligibility and explicit commercial/product expansion reference where required. A static visibility flag cannot bypass the normal five-Business gate. Once ordinary paid launch is authorized, a drop from five to four does not automatically shut it; zero active publishable supply yields honest empty/unavailable discovery. Preserve ~8–10 per-category and ~30 overall active-paid targets as readiness targets, not new hard thresholds/guarantees.

**Cold-start circularity:** do not claim a reserved promotion is active supply to open the category. Use a bounded coordinated launch/publication transaction for a validated cohort: lock launch scope then entities in sorted UUID order; validate all individual readiness; stage their actual paid/promo anchors at the trusted formal-launch/publication instant; derive the five-qualifying-Business count from the resulting transaction state; record launch authorization and make those public snapshots available atomically. All prerequisites except that same opening/anchor transition must already be satisfied. If count, clock or any required readiness fails, roll back the entire make-available set. No pre-launch public bypass or pretend active grant is exposed. Subsequent ready individual publication uses the existing authorized scope.

This specifies technical atomicity, not cohort selection or OQ-49 approval policy. OQ-80 selection/administration must supply approved inputs. A later payment/promotional expiry removes counting on that source at its authoritative boundary, regardless of a worker. **OQ-84 post-promotion category treatment is not selected**: the authorization records whether it relied on A8 and identifies the unresolved decision boundary; no automatic re-gating/Coming Soon/continued-open default is hardcoded. Dependent post-promotion behavior must receive the explicit Owner decision before its implementation/cutover. Do not disguise that missing policy as an operational admin override.

## 25. Category visibility interface

Taxonomy supplies stable category/market identity, supported/eligible assignments, catalog version, independently controlled editorial visibility and proposed discovery scope. Commercial authority supplies intrinsic qualifying count, current launch authorization/evidence revision, zero-supply flag and any unresolved OQ-84 dependency. Normal discovery requires both eligible editorial scope and commercial launch authorization; neither substitutes for the other.

C3 designs only the commercial-side authorization record and count contract, not full category/Activity/media schema. Inactive/unsupported taxonomy versions invalidate candidate publication/count evidence; known post-publication policy consequences are handled through the proper taxonomy/moderation policy. Full catalog synchronization and empty states remain the Taxonomy/Cache contracts.

## 26. Public RLS compatibility and cutover

Before authorized cutover, preserve existing lifecycle-active RLS, gateway behavior and old profile/application operations as **legacy engineering behavior**, visibly separate from commercial readiness/shadow results. No write marks legacy rows entitled merely to maintain parity. New commercial grants/publication endpoints remain inaccessible except explicit isolated test/shadow permissions; shadow evaluation does not expose private financial joins.

At authorized M5, in one controlled deployment boundary: enable guarded public read endpoints/compatible DTO consumer, replace or revoke the old permissive base-table/child public read grants/policies, and mediate all exposed reads including alternate API/GraphQL/export/old-client paths. No coexistence with an old lifecycle-only path that bypasses the new commercial gate. Older clients can receive a safe compatibility endpoint or be required to upgrade under an explicitly accepted release plan; supporting indefinite unsafe direct SELECT is rejected.

Existing profile RPC, activation, privileged import/admin writes and any future category/media/ownership changes must participate in synchronous authority invalidation. Preserve their actor checks, entity row lock, expected-version and audit while routing approved-content changes through the required moderation boundary. Changing their semantics requires the corresponding explicit implementation contracts; C3 makes none of those edits now.

Pre-cutover rollback restores only additive feature activation/shadow mode, with original accepted reads unchanged. **Post-cutover rollback may revert an application/projection version only while retaining current denial/time gates**; never simply restore old lifecycle-only access to newly hidden or financially ineligible rows. If a version cannot serve safely, use a fail-closed safe-read outage/maintenance response and retain data; reopening the weaker legacy public authority needs an explicit separate security/Architect decision, not a routine rollback flag.

## 27. Legacy subscriptions reconciliation

Keep `public.subscriptions` and its `trialing/active/past_due/canceled/paused` check values unchanged during transition. Treat rows as legacy evidence; they do not grant the new evaluator rights. Inventory actual data, external consumers and FK usage before deprecation. C3 source inspection is not proof that the live table is empty.

Private reconciliation records link legacy row IDs to reviewed canonical orders/terms or an unresolved classification with actor/evidence/version. Paid start/end/amount claims need independent approved evidence; no automatic mapping from legacy active/trialing or mandatory historical started_at. Preserve original rows/status/history. New commercial mutations write only canonical history, not a second independently authoritative legacy ledger; compatibility outputs are derived labeled adapters. Later deprecation/cleanup requires evidence and separate scope, never renaming trialing into A8.

## 28. Flutter plan scaffolding boundary

Retain PlanType/PlanTier temporarily for unrelated accepted local access scaffolding; explicitly prohibit their use in new commercial price, ownership/staff, entitlement or publication decisions. No global replacement in C3. Introduce future typed commercial catalog/Business capability DTOs at dedicated gateways, with supported-version parsing and unknown-deny behavior.

A narrow migration adapter may support existing presentation keys but must never turn `free`, `supplier`, `company`, `owner`, `admin`, `moderator`, or `support` into purchased commercial rights. Legacy ServiceBusinessProfile fields remain serialized compatibility evidence only. Remove obsolete commercial usages only after call-site inventory/regression and separately authorized slice; preserve local unrelated features.

## 29. RLS / privilege boundaries

| Access class | Future surface and denial boundary |
|---|---|
| PUBLIC anon/authenticated | Guarded safe Directory/catalog RPC output only for commercial data; no private table SELECT or arbitrary entity-child joins. Other accepted app public reference surfaces remain separately scoped. |
| BUSINESS OWNER/TEAM | Capability-scoped Business DTO through authenticated read RPC; own entity membership/readiness rechecked. Financial/subscription fields only canonical Owner or explicitly finance-authorized capability (§28.11). No blanket authenticated/team finance access. |
| FINANCE/COMMERCIAL ADMIN | Explicit granular verification/refund/credit/catalog/grant capability; independent target/evidence checks. Finance permission is not ownership, publication approval or enforcement authority by default. |
| GENERAL STAFF | Only explicitly granted operations/read projections; application-review membership does not inherit commercial power. |
| TRUSTED SERVER OPERATIONS | Narrow due-work/reconciliation identity, bounded approved transitions and sanitized audit; no arbitrary client-supplied actor or self-provisioning. |

New private tables have no grants/USAGE to ordinary clients and are excluded from Data API schemas; enable defensive RLS/default-deny where appropriate with explicit function-owner access reviewed. Internal helpers are non-client-executable. Public wrappers are SECURITY DEFINER only where private access is required, owned by a constrained trusted role with necessary object privileges; fixed safe search path, qualified names, no caller-controlled SQL identifiers, temporary-schema shadowing, or public-schema object injection. Revoke default PUBLIC execute and grant only intended roles **in the same migration transaction**; no temporary exposure window.

Definer-owner RLS bypass is not authorization: every private Business/staff RPC derives actor from auth identity and independently checks permissions/target. Read-only public wrappers authorize output through live publication guards. Never rely on a cached UI capability, claimant-supplied user UUID or current `has_business_management_access` for financial authority. No Flutter service_role; one Supabase and one AuthProvider.

## 30. Server mutation families

Common contract: canonical target/actor, explicit expected authority/aggregate version, typed payload, stable command key and fingerprint, narrow capability, required evidence; locks, validate, append facts, synchronously update/invalidate authority, append sanitized audit/outbox, commit together. No partial financial/publication success. Replay rules in §31 apply to every family.

| Family | Authorized actor; preconditions | Transaction / audit / replay obligation |
|---|---|---|
| Verify/clarify/reject payment | Finance verifier; approved destination, intended Business/order, actual funds/evidence, expected payment version. | Serialize transfer/payment and entity; append decision/allocation/adjustment once; audit. Verification may approve a pending paid basis, never bypass publication. |
| Create/activate paid term | Authorized commercial operations; satisfied order/funds or approved written Corporate authorization, approved versions and actor capability. | Consume order/allocation once; write pending term or valid anchor depending on purpose; update evaluator generation; audit/idempotent receipt. |
| Renew | Authorized commercial operations under agreed customer intent; verified new order, current chain head/version. | Append predecessor term under entity lock; recheck paid/Grace boundary; one order-one term; audit. No automatic charge. |
| Reactivate | Authorized commercial operations plus canonical publication-approval interface; verified order, after-Grace, all gates. | Pending term then atomic eligible republication/anchor; replay cannot create another period; audit. |
| Reserve/grant A8 | Explicit Launch Partner administration; approved cohort/invitation/genuine entity and supported policy version. | Single ordinary grant, audit selection; anchor only at eligible launch/publication transaction. No trialing/fake payment. |
| Expire promotion / prospective revoke request | Trusted server expiry from immutable end; discretionary actor only after OQ-80 policy resolution. | Expiry derives from time even without event; dedup history/authority update. Discretionary revocation is disabled until rules exist, not equated with expiry. |
| Enforcement / confirmed closure / permitted release | Explicit enforcement/domain authority; frozen grounds, evidence, expected revision; no payment bypass. | Append action; immediately deny/invalidate; audit/outbox; lifting requires separate eligibility checks. Unknown re-entry policy blocks that path. |
| Publish / hide / recompute | Future approval authority consistent with OQ-49; gate/ownership/moderation/content/launch versions. Trusted timed hide allowed only for frozen expiry. | Atomic snapshot/anchor/authority/event; hide monotonic revision; unchanged recompute no duplicate event. No arbitrary staff “publish anyway.” |
| Catalog / bundle / quote administration | Explicit commercial catalog/quote capability; approved frozen terms/change authority, effective dates. | Append validated version, disallow conflicting offers/unsupported keys, audit; retire future sale only, not purchased history. |
| Remediation extension/credit | Explicit finance/service authority with Civilpedia-error or approved contractual basis. | Append linked adjustment, derive new effective end/credit; never edit original term; invalidate deadlines; audit/dedup. |

No final RPC signature/name or permission-code implementation is created. Exact endpoints/error DTOs, rate limits and data bounds are frozen in the later implementation slice; those cannot broaden these actors or preconditions.

## 31. Concurrency and idempotency

Use existing row-lock/expected-version/audit principles. Serialize commercial state by the canonical `directory_entities` row, then private agreement/term/order/payment rows in fixed UUID order; operations touching launch scope lock scope first, then sorted entity rows. Catalog/program locks precede scopes/entities when needed. **Do not call existing application-first activation while holding entity-first commercial locks**: its 00018 order is application then entity. Leave application activation separate or design an explicit combined lock-order addendum before integration. Profile management already starts with entity lock and must follow the common order when integrated.

The common lock hierarchy is: catalog/program version reservations, then normalized transfer reservations where involved, then launch scopes, then sorted canonical entity rows, then private aggregate/order/payment/term records in their declared fixed order. Acquire only needed tiers but never invert them. A verifier obtains its transfer reservation before any entity lock; a commercial command must not acquire a new transfer reservation after holding an entity. Batch commands use the same hierarchy. The final implementation contract enumerates individual relation ordering and proves it against every integrated writer.

Expected revisions prevent stale admin overwrites. Unique order-to-term, normalized transfer identity/allocation consumption, ordinary program/entity grant, predecessor-chain head and event-cause constraints backstop serialization. Different businesses claiming one transfer require transfer-level serialization before conflicting allocation; define the transfer reservation lock ahead of all entity locks for that family, with no inverse entity-to-transfer acquisition. Multi-entity reconciliation uses sorted targets. Every participant follows the declared hierarchy; deadlocks/conflicts roll back, no blind automatic mutation retry.

`command_receipts` has unique actor/operation/business/request key and payload hash. Reuse with different payload conflicts. Exact replay returns the original committed effect references after rechecking current actor authorization and invariants; it cannot re-grant rights that later expired/revoked. Return current state separately from historical success. Concurrent identical calls yield one effect/audit; corrupt or inconsistent original references fail, never self-heal. Command receipt and result references commit with the mutation; failure leaves no success receipt.

Concurrent expiry/renewal uses current time after locks and the current head: late worker cannot hide a newly renewed Business using old generation. Public reads use a bounded consistent snapshot; after a completed denial, new requests see the new revision, while an already running response cannot be recalled. Limit response/cache lease duration and document this revocation race (§35). Repeated activation/publish of the same source produces no new anchor/audit period. Catalog retirement/version races cannot reprice the accepted order. Unknown/malformed command outcomes require an explicit authorized status reread before user-directed replay.

## 32. Phased migration plan

All phases below are proposed, **not authorized**. Each gets an exact file/data boundary, independent review and focused gate. Avoid destructive big-bang migration; lock migrations against concurrent writers and verify privileges before enabling any endpoint.

| Phase | Allowed future change | Data risk / rollback point | Required evidence |
|---|---|---|---|
| M0 architecture acceptance | Review C3 and resolve dependency boundaries; no runtime changes. | No data mutation; C3 acceptance still not authorization. | Source/authority/independent architecture review. |
| M1 additive foundations | Private namespace, identity/version/term/audit/idempotency structures in focused sub-slices, deny-by-default grants. | No publication or legacy write change; disable new paths and retain empty/private records, not destructive down migration. | Forward migrations against current schema; permission/no-grant regression; keys/checks. |
| M2 catalog/reference | Explicit approved retail versions/bundles, collision review and safe catalog DTO. | No historical revaluation; deactivate new sale version, retain references. | Exact frozen prices/durations, unsupported values rejected, retired-history test. |
| M3 compatibility/shadow | Internal new evaluator/projection, narrowly scoped adapters; old accepted public authority still controls legacy reads. | Never OR shadow readiness with legacy public access; disable shadow/adapters without inventing entitlement. | Differential source/DTO tests, safe data allowlist, performance and complete paging. |
| M4 reviewed reconciliation | Classify existing rows and explicitly link approved evidence to canonical candidates. | No automatic granting/deletion; revoke activation of failed reconciliation batch, preserve original and correction history. | Row-by-row evidence, totals, duplicate/identity checks, resumable versioned ledger. |
| M5 publication cutover | Co-deploy safe consumers/read guards and close every old public bypass; mediate mutation invalidation; time/override gates active. | Read rollback must retain denials; safe outage if no approved compatible version. No revert to permissive lifecycle-only public access. | All interface/OQ prerequisites, RLS/direct API probes, no-gap expiry/renewal, cache/old-client readiness, deploy/rollback rehearsal. |
| M6 legacy deprecation | Remove obsolete commercial callers/compatibility writes after consumer inventory. | Preserve archived rows/reference maps; revert callers only through safe adapters. | No unexplained callers, retained history, app/DB regressions, external integration inventory. |
| M7 cleanup after evidence | Separately authorized retention-compliant removal of proven obsolete artifacts. | No assumed destructive down path; recoverable archives/data validation and explicit Owner scope. | Approved retention/legal decisions, restore rehearsal and reference integrity. |

Dual-read means internal reconciliation/shadow comparison, **not union of permissive and commercial public grants**. No broad full-suite run is part of this design task; a future integrated cutover gate may expressly authorize one.

## 33. Existing-data classification

An immutable reconciliation ledger records original IDs/status hashes, provenance, evidence, reviewer, category/genuine-entity/ownership assessment, commercial candidate outcome and dependency gaps. Recommended buckets: known production commercial **candidate** with evidence; internal/test/dev/mock/seed; requires review/ambiguous identity; ownerless controlled Draft; claimed/member-associated entity with no commercial basis; legacy subscription evidence unresolved; duplicate candidate pending canonical review.

Buckets are operational review classifications, not entitlements or final launch-disposition decisions. Even a production candidate must obtain verified approved commercial basis, canonical onboarding/gate and moderation/launch evidence. No granting from lifecycle active, claim claimed, OWNER row, planType, featured or foundingPartner. No deletion/unpublishing of currently accepted engineering rows before authorized cutover, no grandfathering or automatic duplicate merge. OQ-22/OQ-72 and future Migration authority govern actual disposition.

## 34. Compatibility mode versus final fail-closed mode

Compatibility mode retains the old accepted Directory read contract and labels new commercial authority as shadow/non-operational. New commercial publication is denied for unknown basis; it cannot silently influence old UX or authorize new paid listings. Migration-ready/contract-accepted does not flip this mode.

Final commercial mode requires explicit accepted cutover: only guarded public projection is reachable, all rows have reviewed applicable authority or are excluded from the commercial surface, and missing/unknown required state yields no grant. Known unresolved policy situations are not filled with fabricated technical defaults: scope them out or resolve their Owner dependency before dependent operation. No hardcoded exemption preserving legacy visible rows as “free commercial” is permitted.

## 35. Cache and revocation safety

Preserve cache-first content/resilience as presentation, not current entitlement. Future Cache/Directory contract must version the payload, distinguish server-observed validity from device refreshedAt, retain an opaque publication generation, bound display authorization, remove known-revoked UUIDs, and reject stale asynchronous restores. A failed/malformed/partial refresh does not erase retained content; retained content must nevertheless not be represented as currently authorized discovery after its lease/denial.

Server lease for active discovery must be conservative and capped by the next private publication-relevant boundary, without exposing private expiry. Revocation invalidates generation synchronously; current online requests immediately use that revision. Safety-critical suspension/termination/closure requires an online authoritative check at detail/contact actions and before new active discovery confirmation; exact offline historical display UX is separately frozen and must not imply current active listing/Verified/Sponsored. No cached source grants private management or mutation rights.

Public lease expiration is a generic conservative refresh boundary, not the private term endpoint copied into a DTO: use an accepted coarse refresh window no later than the internal boundary, rounding down where needed. If no positive privacy-safe lease remains, require online revalidation rather than return the exact financial expiry. Lease precision/window is a Cache-contract decision; snapshots never include the private deadline or entitlement source used to compute it.

**Offline clients cannot know an unseen revocation instantly.** No TTL/Realtime choice can recall already received public content. A cache contract must state the accepted bounded freshness and fail-closed action policy, conservative lease handling with server-time/elapsed-time observations, clock rollback/reboot behavior, and allowed historical/inactive presentation; unknown elapsed validity requires revalidation. Instant confidential-data revocation is never promised for public data. The M5 gate is blocked until this tradeoff and old-client behavior are explicitly accepted. C3 chooses no numeric TTL or transport/vendor.

## 36. Plan and entitlement versioning

Published catalog/bundle versions are immutable and referenced by orders/terms/grants. A live term uses its purchased material-benefit snapshot and approved corrections, not the current mutable catalog. Retirement stops new offers, not old fulfillment. Feature-key registry version and evaluator version must be compatible with the stored bundle; unknown versions deny dependent capability, never promote to Plus/unlimited.

Security revocation/enforcement remains current regardless of purchased version; version pinning cannot retain a forbidden action. A changed commercial package is a new approved offer; migrating existing benefits requires an explicit commercially permitted agreement/migration and audit, not silent recomputation. Registry schema changes preserve older supported snapshots or provide explicit adapters before retirement.

## 37. Corporate representation

`corporate_quotes` stores immutable versioned written quotation reference/evidence, Business, approved duration (minimum 12 months), total IQD price/payment terms, Plus-floor bundle and negotiated Branch/team/service/add-on deltas, expiry and acceptance references. Default validity is 30 Baghdad calendar days unless explicitly specified; accepted order captures the quotation effective within its validity. Amendment creates another version, not editing the accepted order.

Use materialized approved term benefits that validate the Plus floor; Corporate is never a fixed retail row or automatically unlimited. Individually approved written payment terms may authorize a staged payment schedule; exact activation obligations must be explicit in that agreement and independently approved, not a client “Corporate” bypass or a universal retail-prepaid constraint. No CRM, invoice/tax assumptions, bank integration or provisional numeric Branch default. Missing required quote terms blocks activation.

## 38. Sponsored boundary

Expose a narrow internal prerequisite result: supported plan-family eligibility (frozen initial Pro/Plus rule/approved Corporate terms as applicable), current public publishability/generation, profile-quality result, enforcement/closure blocker, and related real Business identity. It is **not** a campaign grant or reservation. A8 Pro access and Grace do not automatically buy advertising. Future Sponsored contract composes its own product/payment/inventory/delivery authority, clear disclosure and independent clock; organic ranking remains separate.

Current `EmptyCampaignSource`/placement rendering is not a backend authority. C3 does not design inventory/rotation, campaigns, Sponsored billing or branch advertising.

## 39. Admin authority dependency

Require separate capabilities for catalog administration, payment verification, refund/credit, paid-term administration, A8 selection/administration, permitted entitlement remediation, reactivation/publication approval, enforcement, and private audit inspection. These are descriptive capability families, not final codes/grants/UI. Future Admin contract maps the existing active/effective staff chain to narrowly scoped codes and proves permission loss/session clearing.

Never inherit authority from `business_applications.read/approve/activate` or a role label. Public/Business read capability and private finance visibility remain independent. Grant/revoke capability cannot invent unapproved free rights or OQ-80 withdrawal consequences. Separating sales request creation from final verification is preserved where scale permits. No client self-enrollment or special privileged Flutter path.

## 40. Observability and operations

Private operational signals: pending paid activation with age/cause; rejected stale-version command; replay/payload mismatch; failed allocation/duplicate transfer anomaly; projection/input-generation mismatch; due anchor/Grace/promo events and worker lag; failed recompute; outbox delivery failures; denied publication reason category; unauthorized call/permission loss; count/catalog incompleteness.

Use correlation IDs and aggregate/revision IDs with minimal data, not receipts, personal payer/owner details, internal notes or secret tokens. Separate customer-safe outcomes from restricted operational reasons. Reconciliation verifies projection generation against authoritative facts and alerts on drift; it never silently grants authority to repair a missing record. Bounded due-work safely materializes time events after a crash; read guards already deny expired access. Reminders must discard superseded obligations. No new vendor/tool selection or operational deployment is authorized.

## 41. Mandatory future test architecture

| Family | Required nontrivial cases / acceptance evidence |
|---|---|
| Unit/domain evaluator | All retail sources/version limits, unknown versions/keys, Corporate floor, pending versus in-effect versus Grace; no largest-tier/stacking fallback; entitlement != publication. |
| Time/anchors | Baghdad calendar offsets at exact before/equal/after instants; month-end/leap rules; 14-day solely documented customer exception versus Civilpedia/mixed delay; 60-day later-of-launch/publication; client clock spoof; lock wait across boundary; failed publication consumes no term. |
| Renewal/Grace/reactivation | Early extension preserves days; Grace starts from previous expiry; no free extension; pending funds cannot postpone hiding; late payment/new publication non-retroactive; never-published Draft cannot use Grace. |
| Promotion/density | Ordinary single grant/replay, duplicate genuine-entity rejection, no trialing import; promo expiry stops count in Grace; DISTINCT Business not Branch count; coordinated initial five opening rollback; drop 5→4 not automatic closure; zero honest state; OQ-84 dependent feature disabled until decision. |
| Database authorization | Anonymous/authenticated direct-table and arbitrary nested-select denial; safe public list/detail/catalog; cross-Business and general-team finance denial; expired staff/grant roles; direct helper EXECUTE denial; PUBLIC defaults/search-path injection; future GraphQL/old API bypass probes. |
| Database transactions/concurrency | Double verification/one transfer-many orders, same/different key payload replay, concurrent renew/expire, publish/suspend, category opening/expiry, stale profile input pass, term correction history; audit failure rolls back, no orphan receipt/outbox; lock hierarchy with existing activation. |
| Publication projection | Time denial without worker; generation mismatch denies; suppression committed despite existing entitlement; no private column/claim metadata in payload; opaque lease privacy; new requests after denial; delayed worker never republishes newer denial. |
| Migration/compatibility | Forward migration from 00021, privileges denied immediately, existing IDs/FKs/rows/history retained, no entitlement from old active/trialing/OWNER/booleans, evidence-classification totals, deterministic reviewed batch replay, safe post-cutover rollback and old-client behavior. |
| Flutter gateway/integration | Safe DTO strict parsing, paginated completeness and partial rejection, canonical Saved/routes retained, bounded offline lease and denial tombstones, stale result cannot restore removed record; private Business capability/session-generation/sign-out clearing. |
| Security/adversarial | Forged receipts/time/actor/category/promo/bundle, malformed grants, cross-entity substitution, password/claim shortcuts, plan-as-staff authority; no service_role/client self-grant; finance evidence never public. |

Existing seams include [v1_r09q_security_smoke.sql](../../../supabase/tests/v1_r09q_security_smoke.sql), [v1_r09q_security_matrix_test.dart](../../../test/v1_r09q_security_matrix_test.dart), [a6_4_business_application_activation_test.dart](../../../test/a6_4_business_application_activation_test.dart), [v1_r06_business_profile_management_test.dart](../../../test/v1_r06_business_profile_management_test.dart), and [v1_r05_directory_cloud_integration_test.dart](../../../test/v1_r05_directory_cloud_integration_test.dart). Add focused future tests rather than patch SDK/cache/global source. Protected pre-existing tests are not in C3's edit boundary. No tests in this table have been executed by C3 drafting; a future integrated gate must explicitly authorize repository-wide runs.

## 42. C3 architecture decision register

All entries below are **PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING**. A definite recommendation is not a self-declared freeze or implementation authorization. Rejected alternatives are rejected within this proposal, not by an invented Owner commercial decision. “Impact” describes future authorized integration, not repository changes performed now.

### C3-AD-01 — Canonical plan catalog

- **Decision:** Retain public plan UUID/code identity; versioned private metadata/bundles and separate term prices (§§3–4).
- **Why:** Reuse accepted FKs while preventing mutable-row pricing and public draft leakage.
- **Alternatives considered:** Extend the single plans row; replace all plans; companion catalog.
- **Rejected alternatives:** Single-row price/benefit truth loses history; replacement breaks identity without justification.
- **Existing-system impact:** Preserve plans/subscription references; later narrow public catalog reads.
- **Trace:** Policy §§2–3, 6, 31.1; C1 §§2–3; C2 §§3, 23, 25.
- **Implementation dependency:** Catalog collision/data inventory, additive schema and safe DTO contract; OQ-23 register unchanged.
- **Risk:** Existing code collisions and future default-grant leakage.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-02 — Historical price and term snapshot

- **Decision:** Immutable accepted-order and purchased-term material snapshots plus source/version/evidence linkage (§5).
- **Why:** Catalog changes cannot reprice/redefine an already paid term.
- **Alternatives considered:** Read today's catalog; mutable subscription row; immutable purchase facts.
- **Rejected alternatives:** Current-catalog lookup and overwriting erase the customer's agreement.
- **Existing-system impact:** Legacy price_paid/currency remain evidence, not silently converted history.
- **Trace:** Policy §§3.2, 5.7, 26.3, 28.1; C1 §§11, 21; C2 §§3, 11.
- **Implementation dependency:** Orders/term constraints, source hashes, approved correction event.
- **Risk:** Incomplete import evidence and arbitrary JSON benefit grants.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-03 — Launch Partner representation

- **Decision:** Dedicated versioned A8 promotional grants, reserved separately from in-effect intervals (§7).
- **Why:** Safely model 0 IQD/60-day Pro and its unique anchor without fake paid proof.
- **Alternatives considered:** Legacy trialing; source-tagged paid term; dedicated grant; fully generic grant engine.
- **Rejected alternatives:** Trialing is unreconciled; paid rows obscure absence of payment; generic engine adds unnecessary permission complexity.
- **Existing-system impact:** No subscriptions status rename or foundingPartner import grant.
- **Trace:** Policy §32.2 / L-89; C1 §12 / AR-05; C2 §14 / C2-AR-07.
- **Implementation dependency:** Genuine entity/OQ-72 interface, OQ-80/81 policy inputs and launch/publication transaction.
- **Risk:** Duplicate farming, inappropriate revocation/reset, circular premature counting.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-04 — Canonical agreement and terms

- **Decision:** New private agreement + immutable paid terms/events; retain legacy subscriptions as evidence (§8).
- **Why:** Renewal/reactivation/pending start/history cannot safely fit a mutable legacy row.
- **Alternatives considered:** Extend legacy row; replace/drop legacy table; new wrapped aggregate.
- **Rejected alternatives:** Mutable history and destructive replacement lose compatibility/evidence.
- **Existing-system impact:** Later canonical writers/adapters; legacy rows/FKs preserved.
- **Trace:** Policy §§8.4, 26.1–26.5; C1 §§11, 21; C2 §§10–13, 25.
- **Implementation dependency:** Agreements/orders/terms, anchor and correction event validation.
- **Risk:** Dual authority, overlapping intervals or consumed order twice.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-05 — Effective entitlement derivation

- **Decision:** DB versioned typed bundles + one server registry/evaluator, with independent actor/use constraints (§§9–10).
- **Why:** Auditable evolution, historical fulfillment and simple safe clients.
- **Alternatives considered:** Hardcoded server matrix; unrestricted DB JSON; versioned typed hybrid.
- **Rejected alternatives:** Hardcoding restricts commercial evolution; unrestricted rules permit malformed/unlimited grants.
- **Existing-system impact:** New commercial DTOs coexist with unrelated legacy scaffolding; no client entitlement authority.
- **Trace:** Policy §§4, 28.11, 31.1, 32.9; C1 §§3, 20; C2 §§3, 12, 28.
- **Implementation dependency:** Capability registry and reviewed product limits; OQ-12/16/17/76/77 where applicable.
- **Risk:** Treating missing limits as unlimited or Grace as active Pro.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-06 — Payment verification domain

- **Decision:** Private payment evidence/decision, allocation and explicit adjustment records linked to immutable orders (§11).
- **Why:** Independently verified money and each exception outcome remain auditable and separate from publication/ownership.
- **Alternatives considered:** Receipt boolean on subscription; reusable screenshot as credit; reconciled payment ledger.
- **Rejected alternatives:** Booleans/screenshots cannot prove actual funds or prevent double spending.
- **Existing-system impact:** Add domain beside existing staff/audit chain; no application permission inheritance.
- **Trace:** Policy §§7.2, 28.1, 28.8; C1 §§11, 14, 20; C2 §§3–4, 28.
- **Implementation dependency:** Payment Operations, approved rails OQ-09, antifraud OQ-10 and private evidence/retention scope.
- **Risk:** Duplicate transfer allocation, PII exposure, unauthorized adjustments.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-07 — Server time authority

- **Decision:** UTC instants, versioned Baghdad calendar arithmetic, time captured after write locks and fixed interval endpoints (§§12–13).
- **Why:** Deterministic calendars without device-clock or long-lock stale-time grants.
- **Alternatives considered:** Device time; UTC fixed 30-day months; rounding all endpoints to midnight; explicit local-calendar rule.
- **Rejected alternatives:** Device time untrusted; fixed months alter purchased durations; midnight rounding can shorten/lengthen windows.
- **Existing-system impact:** Existing device refreshedAt remains cache metadata, not commercial time.
- **Trace:** Policy §§26.1–26.2, 32.2; C2 §§4, 10–14.
- **Implementation dependency:** Acceptance of convention, calendar fixture tests, trusted launch/publication/delay evidence.
- **Risk:** Off-by-one dates, month-end handling and worker-lag backdating without proof.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-08 — Grace computation

- **Decision:** Compute five-day Grace from effective expiry; retain history events separately (§15).
- **Why:** Worker absence cannot prolong public access or grant an active entitlement.
- **Alternatives considered:** Mutable grace flag; scheduled-only hide; current-time computed gate.
- **Rejected alternatives:** Flags/jobs alone become stale and accidentally add free time.
- **Existing-system impact:** Legacy active/past_due are not Grace aliases; future projection guard handles continuation.
- **Trace:** Policy §§8.2, 26.2.6–26.2.11; accepted C2 §12 clarification / C2-AR-04.
- **Implementation dependency:** Effective paid/promo interval and prior-publication evidence; OQ-12 access mode remains open.
- **Risk:** Granting first publication in Grace or A8 density after expiry.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-09 — Publication authority projection

- **Decision:** Private transactional authority/safe snapshots + guarded bounded read RPC (§§17–19).
- **Why:** Avoid public sensitive joins and stale materialized flags while preserving fast safe reads.
- **Alternatives considered:** Complex join RLS; materialized flag; canonical table alone; view alone; guarded hybrid.
- **Rejected alternatives:** Sensitive join complexity and worker-stale flags; view alone lacks explicit defensive output control.
- **Existing-system impact:** Later gateway DTO adapter/public-grant cutover, UUID/routes retained.
- **Trace:** Policy §§19, 27.2, 32.5.6; C1 §§7, 19–20; C2 §§5–7, 24–25.
- **Implementation dependency:** Ownership/quality/moderation/taxonomy interfaces and OQ-48/49 decisions for affected operations.
- **Risk:** Unmediated writes/API bypass, stale input generation and incomplete pagination.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-10 — Enforcement precedence

- **Decision:** Separate attributable enforcement actions/current generation; denial overrides paid/promo/Grace (§20).
- **Why:** A surviving purchased term cannot force public presence or buy reinstatement.
- **Alternatives considered:** Subscription paused/canceled; entity active toggle; separate enforcement authority.
- **Rejected alternatives:** Collapsed legacy states lose customer-clock/appeal/closure distinctions.
- **Existing-system impact:** Later deny integration with independent Verification/Sponsored authorities, not automatic legacy status rewrite.
- **Trace:** Policy §§26.4–26.5, 28.4; C1 §§4, 20; C2 §§16–19.
- **Implementation dependency:** Admin/moderation authority, approved cause/credit, canonical verification inactivation and re-entry rules.
- **Risk:** Unauthorized release, automatic refund/clock pause or re-entry invented by a technical default.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-11 — Launch-density authority

- **Decision:** Derived distinct qualifying Business count + auditable scope authorization; coordinated atomic cold-start opening (§§24–25).
- **Why:** Avoid static visibility bypass, reserved-grant counting and category-opening recursion.
- **Alternatives considered:** Pure static admin flag; perpetual computed five threshold; hybrid checked launch event.
- **Rejected alternatives:** Static flag bypasses policy; perpetual threshold violates launch-not-shutdown rule.
- **Existing-system impact:** Future Taxonomy scope interface; lifecycle active/location counts cease being sufficient commercial counts.
- **Trace:** Policy §§31.3, 32.11; C1 §7.1 / AR-14; C2 §§20–21 / C2-AR-10.
- **Implementation dependency:** Category/market/genuine entity interfaces, OQ-49/80 approvals, explicit OQ-84 decision for post-promo behavior.
- **Risk:** Double counting, pre-launch entitlement fiction and silent resolution of post-promotion category policy.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-12 — Existing subscription reconciliation

- **Decision:** Retain original rows/check vocabulary, reviewed mapping ledger and derived compatibility output (§27).
- **Why:** Preserve evidence without converting legacy engineering values into commercial rights.
- **Alternatives considered:** Rename active/trialing; automatic paid backfill; preserve and review.
- **Rejected alternatives:** Renaming/backfill invent paid/A8 authority and lose original semantics.
- **Existing-system impact:** New canonical writers only after authorization; archive legacy evidence before any cleanup.
- **Trace:** Policy §§8.4, 2.5; C1 §§3, 21 / AR-04, AR-13; C2 §25 / C2-AR-11.
- **Implementation dependency:** Actual deployed inventory, OQ-22 disposition and explicit Migration contract.
- **Risk:** Incorrect grandfathering, lost links/history, competing ledgers.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-13 — Legacy Flutter plan boundary

- **Decision:** Retain unrelated scaffolding temporarily; new dedicated commercial DTOs with no authority mapping (§28).
- **Why:** Avoid broad app refactor and prevent product/role labels granting commercial rights.
- **Alternatives considered:** Reuse PlanType; immediate global removal; scoped deprecation adapter.
- **Rejected alternatives:** Reuse collapses role/product meaning; broad removal breaks accepted unrelated features.
- **Existing-system impact:** Later narrow gateway/domain consumer migration, read-compatible legacy fields retained.
- **Trace:** Policy §3.5; C1 §3; C2 §§2, 25, 28.
- **Implementation dependency:** Call-site inventory and focused Flutter integration contract.
- **Risk:** Unknown value fallback to free/privileged role or commercial logic creeping into constants.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-14 — RLS boundary

- **Decision:** Non-exposed private authority schema, deny direct client access, explicit guarded DTO RPCs and narrow definer privileges (§29).
- **Why:** Keep finance/evidence inaccessible while serving safe anon/authenticated public reads.
- **Alternatives considered:** Blanket authenticated SELECT; client-sensitive joins; safe read/mutation wrappers.
- **Rejected alternatives:** Broad SELECT/joins leak private facts and confuse membership with financial authority.
- **Existing-system impact:** Later public parent/child grant mediation; existing accepted noncommercial surfaces separately preserved.
- **Trace:** Policy §§28.8, 28.11; C1 §20; C2 §28.
- **Implementation dependency:** Admin/Ownership capability interface, grant/default-privilege/search-path review and bypass probes.
- **Risk:** Definer owner bypass, default PUBLIC execute or alternate API exposure.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-15 — RPC mutation boundary

- **Decision:** Capability-specific atomic commands with expected revisions, command receipts and same-transaction sanitized audit/outbox (§§30–31).
- **Why:** Prevent replayed money/grants and partial authority/history changes.
- **Alternatives considered:** Direct client writes; independent frontend steps; atomic server command families.
- **Rejected alternatives:** Clients/uncoordinated steps cannot preserve invariants or prove audit consistency.
- **Existing-system impact:** Reuse accepted auth/locking/audit pattern, not application grants or inverse activation lock order.
- **Trace:** Policy §§28.1, 32.7; C1 §20; C2 §§4, 28.
- **Implementation dependency:** Narrow command contracts, lock hierarchy, actor/data limits and idempotency invariants.
- **Risk:** Double allocation, stale screens, deadlock, historical replay regranting revoked rights.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-16 — Migration strategy

- **Decision:** M0–M7 additive/shadow/reviewed reconciliation, separately authorized cutover, evidence-based deprecation (§§32–34).
- **Why:** Preserve accepted behavior before cutover and prevent unsafe rollback after it.
- **Alternatives considered:** Destructive big bang; indefinite dual public authority; staged controlled cutover.
- **Rejected alternatives:** Big bang risks loss; dual permissive public access bypasses commercial enforcement.
- **Existing-system impact:** Existing UUID/data/auth foundations preserved; only authorized M5 changes public meaning.
- **Trace:** Policy §§1.2, 33; C1 §21 / AR-13; C2 §§25, 27, 30.
- **Implementation dependency:** Deployed inventory, affected OQs/contracts, old-client/cache readiness and rollback rehearsal.
- **Risk:** Unreviewed row disposition, partial bypass closure, rollback reopening denied records.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-17 — Cache and revocation safety

- **Decision:** Versioned content cache with independent bounded server-authorized display validity, revocation generation and online sensitive-action rechecks (§35).
- **Why:** Preserve resilience while preventing cached content from claiming indefinite current publication.
- **Alternatives considered:** Unlimited known-good active display; TTL-only; immediate offline revocation promise; bounded honest validity contract.
- **Rejected alternatives:** Unlimited/TTL-only ignores denial; instant unseen offline revocation is impossible.
- **Existing-system impact:** Later cache version/gateway/controller adapter, original data retention and generation guards preserved.
- **Trace:** C1 §19 / AR-12; C2 §24; policy §32.9.
- **Implementation dependency:** Cache/Directory offline UX and freshness acceptance, conservative time/lease tests before M5.
- **Risk:** Device clock rollback, out-of-order restoration, offline safety/availability tradeoff and lease information leakage.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-18 — Plan and bundle versioning

- **Decision:** Immutable published catalog/bundle references plus term snapshots; current security restrictions always override (§36).
- **Why:** Preserve purchased material terms without pinning forbidden access forever.
- **Alternatives considered:** Mutable current plan; copy untyped JSON; typed immutable versions/snapshots.
- **Rejected alternatives:** Mutable/untypeable snapshots lose history or permit unsupported benefits.
- **Existing-system impact:** Old plan UUID retained; supported readers/evaluators evolve through explicit adapters.
- **Trace:** Policy §26.3; C1 §§2–3, 21; C2 §§3, 11.
- **Implementation dependency:** Version compatibility and explicit benefit migration/change authority.
- **Risk:** Retiring supported snapshots too early or revaluing old terms silently.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-19 — Corporate representation

- **Decision:** Immutable versioned written quote/order/term with Plus floor, negotiated permitted deltas and explicit payment conditions (§37).
- **Why:** Corporate cannot be a fixed retail price or unlimited bypass.
- **Alternatives considered:** Fixed price row; unconstrained custom JSON; validated quotation-backed term.
- **Rejected alternatives:** Fixed row contradicts Custom Quote; arbitrary JSON defeats floor/authorization.
- **Existing-system impact:** Reuse plan identity and payment/evaluator infrastructure, not separate entity/account identity.
- **Trace:** Policy §§28.12, 31.1; C1 §11; C2 §23.
- **Implementation dependency:** Approved written terms, quote validation and benefit-key registry; no CRM.
- **Risk:** Missing minimum commitment/floor, expired quotes or instalment conditions mistaken for ordinary paid activation.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

### C3-AD-20 — Test and security acceptance architecture

- **Decision:** Focused domain/time, DB privileges/concurrency, migration, projection/cache and Flutter session tests before each dependent gate (§41).
- **Why:** Architecture safety requires adversarial time/access/race evidence, not static schema inspection alone.
- **Alternatives considered:** Happy-path UI tests; broad suite alone; layered focused/integration gates.
- **Rejected alternatives:** Happy paths miss authority races; broad suite alone does not prove deployed privileges/cutover.
- **Existing-system impact:** Reuse accepted fakes/security smoke seams, preserve protected dirty tests and SDK/global packages.
- **Trace:** C1 §§2, 20–24; C2 §§28–30; Agent Operating Model §6.
- **Implementation dependency:** Authorized per-slice tests, isolated DB fixtures, deployed smoke and explicit integrated gate.
- **Risk:** False confidence from historical PASS or mocks that bypass real grants.
- **Status:** PROPOSED TECHNICAL DESIGN — ACCEPTANCE PENDING.

## 43. Decided design, deferred details, open policy and other owners

### A. Proposed technical decisions awaiting acceptance

The twenty C3-AD recommendations specify catalog/price snapshots, private paid/promo records, typed entitlement evaluation, payment allocation, server calendars, computed Grace, guarded public read architecture, separate enforcement/density and additive migration. They can be reviewed as concrete architecture without any code/schema mutation. C3 does not claim to resolve C1 AR-01–AR-14 or alter C2-AR-01–12.

### B. Implementation details still deferred

Final DDL/nullability/index/exclusion constraints; RPC signatures/error DTOs; bounded page/snapshot protocol; physical safe payload format; trigger/internal hook placement; permission codes/provisioning; worker/scheduler/outbox transport; private evidence storage; audit correlation format; exact cache lease/freshness technology; notification implementation; deployment choreography. Later choices must preserve the concrete boundaries, especially no public financial tables, no worker-only expiry, and no inverse lock order.

Paid A8 conversion needs an explicit anchor-preserving source-switch contract: reserve a verified paid order separately from the running promotion, establish the paid service/publication event under its applicable purchased-term rules, and prove no lost promotional days, overlapping benefit stacking or promotional-Grace backdate. C3 chooses structures/interface and rejects silent defaults; it does not infer a missing conversion schedule from legacy trialing. Implementing conversion before that focused decision/test gate is excluded.

### C. Existing OPEN policy dependencies — no answers inferred

| SSOT OPEN item(s) | Retained issue / implementation gate |
|---|---|
| OQ-01 / OQ-02 / OQ-14 | Founding short first-term prices, initial first-50 counter/evidence, badge visibility/copy; no allocator or automatic public badge. |
| OQ-03 / OQ-16 | Branch caps/add-on pricing and media limits; do not seed provisional numbers as approved rights. |
| OQ-09 / OQ-10 / OQ-15 / OQ-23 | Approved rails, antifraud mechanisms, private reference format and technical catalog representation. C3 proposes architecture for technical seams; register status/owner/classification unchanged until proper acceptance process. |
| OQ-12 / OQ-17 | Grace management access and analytics/history visibility/retention; duration/public continuity already decided. |
| OQ-13 / OQ-52 / OQ-56 / OQ-57 | Verification evidence/workflow/granularity, review capability/history and content appeal; no blanket Verified prerequisite or invented appeal. |
| OQ-19 / OQ-54 | Branch/legal-entity/lifecycle details; entity closure principle does not decide independent Branch transitions. |
| OQ-22 / OQ-40 | Existing/seed launch disposition; statutory retention/deletion; review buckets are not final outcomes/legal rules. |
| OQ-48 / OQ-49 / OQ-76 / OQ-77 | Known post-publication quality shortfall, approver/staff-versus-automation, exact gate and Business Center/RBAC design. Cutover affected behaviors only after their required decisions. |
| OQ-68 / OQ-71 / OQ-78 / OQ-79 | Historic inactive link, transfer while non-active, old memberships, ownership/legal evidence. No unreviewed public/financial grant by adapter. |
| OQ-72 | Duplicate detection and merge/retirement mechanics, including promo genuine-entity enforcement; no name-only dedup or automatic merge. |
| OQ-80 / OQ-81 / OQ-82 / OQ-83 | A8 cohort/revocation/continuity exceptions and never-owned Draft/invitation lifecycle; ordinary safety constraints do not decide exceptions. |
| OQ-84 | Category post-promotion re-gating/Coming Soon/continuation decision; store dependence, do not choose policy via a flag/worker. |
| P-34, §28.2, §30 / D-19 | Exact proration/refund formulas, processing detail and legal drafting; structures support approved adjustments but invent no quantum/statutory period. |

Every unlisted OPEN policy question also remains unchanged; no closed OQ is reopened. Future Architecture classification does not authorize implementation, and non-freeze-blocking classification does not supply an answer.

### D. Other contract ownership

Ownership/Invitation/RBAC owns canonical readiness/capabilities/evidence; Taxonomy owns category/market/Activity and editorial scope; Business/Branch owns real domain/content/Branch mapping; Verification/Moderation owns full trust and proposed/published content; Admin owns capability codes/grants/provisioning; Payment Operations owns approved rails/funds workflows; Cache/Directory owns paging/freshness/offline compatibility; Sponsored owns campaigns/inventory; Analytics owns factual measurement/retention; Migration owns data disposition/cutover; legal/accounting review owns statutory obligations. C3 defines interfaces, not permission to commence these families or silently finish them.

## 44. Smallest safe first implementation slice — recommendation only

**Recommended future slice: M1a — private commercial catalog identity/version foundations, with no live commercial behavior.** Separate Architect authorization is required after C3 acceptance, and its own exact contract must be frozen. This recommendation does not unlock the roadmap.

- **Exact objective:** Add a deny-by-default private namespace and version/bundle/term-price structures referencing existing plan UUIDs; prove additive integrity/privileges without a public catalog or entitlement/publication activation.
- **Expected migration:** A proposed `supabase/migrations/00022_commercial_catalog_private_foundation.sql`, only if 00022 remains the next unused ID when authorized. It would create the private schema and `entitlement_bundles`, `bundle_items`, `plan_versions`, `term_prices`, with FKs/checks and explicit no-client/default-deny privileges. No alteration/redefinition of old plan/subscription rows or RLS. File is not created by C3.
- **Expected code areas:** That future SQL migration plus isolated database test fixtures only. No Flutter/server RPC/application API/runtime configuration change; no permission grants to end users. Reuse UUID/extensions already established, not a new backend client.
- **Expected tests:** Forward application atop 00021; FKs/version uniqueness/supported amount-currency-duration constraints; all four retail identities via isolated fixtures; public/authenticated cannot read/write/EXECUTE private objects; legacy entity/plan/subscription/membership data and current public reads unchanged. Extend focused SQL security harness in a new test file, keeping protected dirty tests outside scope.
- **Explicit exclusions:** Catalog seeding/public DTO, payment records/verifier UI, orders/terms/grants, real eligibility/backfill, A8/Founding allocation, publication/RLS/RPC cutover, workers/cache, Corporate quote integration, production data mutation and all policy OQ decisions.
- **Rollback boundary:** Original app/read behavior and data remain untouched. Disable activation/deployment of unused private additions; retain any subsequently referenced records. Destructive down migration/drop is not a default rollback; a future explicit cleanup contract is required. Reject deploying the slice if its privilege fixtures reveal any new client exposure.

This is intentionally the catalog identity/version layer before M2's approved reference data and all enforcement integration. It has a concrete testable boundary and depends on no invented paid listing or cohort eligibility.

## 45. Drafting validation, scope and authorization

Expected task delta is this one new untracked Markdown contract. Protected dirty baseline:

```text
 M test/a5_6_profile_bootstrap_test.dart
 M test/v1_r08_cloud_profile_foundation_test.dart
 M test/v1_r08_profile_edit_screen_widget_test.dart
?? OpenCode_Usage_Report.txt
?? artifacts/
```

Drafting validation: fingerprint pre-existing repository files; confirm policy/C1/C2/roadmap/protected files unchanged; all local links and tables valid; twenty unique decision IDs with all requested fields; `git diff --check`, untracked Markdown whitespace check, empty staged list; HEAD/local origin/main unchanged at `27359f8c574e5d5c4e301a67368d7178e348fa74`. Actual results belong in the final report. Local origin/main is a remote-tracking reference, not a fresh remote/deployment audit.

Commercial policy decisions changed: 0. Existing OQs closed/reclassified: 0. C1/C2 reconciliation entries resolved: 0. Production code/migrations/tests modified: 0. No implementation/runtime/SQL/full-suite tests run for this drafting task. No stage, commit, push, reset, revert, or stash. The independent C3 review has not been performed by the drafting agent.

Recommendation: **ready for independent backend/security architecture review as a technical draft**, with explicit open-policy/interface prerequisites before dependent implementation or M5. Acceptance later means technical architecture accepted; it is not implementation authorization. A separate Architect implementation authorization with frozen slice/data/test boundary is required.

## 46. Final Architect acceptance record — 2026-10-02

- Independent backend/security review: B initially
- Blocking acceptance findings: 0 semantic
- Required documentary corrections: 3 LOW
- Documentary corrections applied and revalidated: PASS
- Architect Acceptance: APPROVED
- Commercial policy decisions changed: 0
- Accepted technical architecture decisions changed during acceptance: 0
- C3-AD entries resolved/removed: 0
- Frozen Commercial OQs closed/reclassified: 0
- Implementation authorization: NO
- Authority: ChatGPT Architect

This record persists the supplied final Architect decision after successful independent revalidation of the three authorized documentary corrections. No further review is required for this acceptance. The current-state metadata and this record supersede earlier draft, review-pending, and acceptance-pending wording, which is preserved as historical drafting context, including the original C3-AD status labels. C3-AD-01 through C3-AD-20 retain their substantive meaning; no entry is resolved or removed by this acceptance. OQ-84 remains unresolved, and all OPEN OQs retain their existing status and meaning.

Acceptance is of technical architecture only. It does not authorize implementation or any future implementation contract or contract family. Separate Architect implementation authorization remains required before implementation.

## 47. Accepted hardening carry-forward requirements

The following are ACCEPTED CARRY-FORWARD REQUIREMENTS: non-blocking future implementation obligations recorded with this acceptance. They do not change the accepted technical decisions, the M0–M7 sequence, or the first M1a recommendation, and do not authorize implementation or resolve unrelated OQs.

| Future boundary | Accepted carry-forward requirement |
| --- | --- |
| M1a | Schema-level default privilege hardening using `ALTER DEFAULT PRIVILEGES` or an equivalent secure mechanism, avoiding reliance on manual per-function `PUBLIC` revokes. |
| M1a | `SECURITY DEFINER` `search_path` hardening using `commercial_private, pg_temp` and/or fully-qualified object references. |
| M4 | Explicit evidence-backed legacy `numeric(12,2)` → canonical integer-IQD conversion, including rounding policy. |
| Profile/commercial integration | Reconcile the existing `00020` entity-lock-before-authorization behavior and its lock-order/security implications. |
| Before M5 | An explicit publication-projection vs authoritative-generation reconciliation test. |

IMPLEMENTATION_AUTHORIZED = NO
