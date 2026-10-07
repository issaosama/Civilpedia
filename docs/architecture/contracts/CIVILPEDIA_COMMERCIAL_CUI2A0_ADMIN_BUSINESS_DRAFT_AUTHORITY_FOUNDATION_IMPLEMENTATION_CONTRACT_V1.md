# Civilpedia — CUI-2A0 Admin Business Draft Authority Foundation Implementation Contract V1

```text
DOCUMENT_STATUS: ACCEPTED — CANONICAL CUI-2A0 IMPLEMENTATION CONTRACT
ARCHITECT_ACCEPTANCE: ACCEPTED — 2026-10-07
FREEZE_STATE: FROZEN
IMPLEMENTATION_AUTHORIZED: NO
PUBLIC_BACKEND_AUTHORITY_DELTA: FROZEN PROPOSED DELTA — DRAFT-ONLY STAFF AUTHORITY, IMPLEMENTATION NOT YET AUTHORIZED
COMMERCIAL_AUTHORITY_DELTA: ZERO — NO ENTITLEMENT/PUBLICATION/PAYMENT AUTHORITY
CUI2A0_STATE: CONTRACT FROZEN — IMPLEMENTATION NOT YET AUTHORIZED
DOCUMENT_VERSION: 1
DRAFT_DATE: 2026-10-07
ARCHITECT_CORRECTION_DATE: 2026-10-07
MODE: GOVERNANCE ONLY — ARCHITECT ACCEPTANCE / CONTRACT FREEZE
PROPOSED_SLICE: CUI-2A0 — Admin Business Draft Authority Foundation
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
CUI1_STATE: CLOSED
M3_STATE: CLOSED
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO
GIT_OWNER: User
```

## 1. Status, authority and evidence

This document is the canonical **ACCEPTED / FROZEN** CUI-2A0 implementation specification. The prior Architect correction cycle is complete; its CLAIM isolation, four-type authoring scope and location-completeness requirements are incorporated as mandatory A0 implementation requirements. Architect contract acceptance and freeze have been supplied and recorded in §26. Implementation remains **NOT AUTHORIZED**; this acceptance/freeze does not authorize SQL, 00026, Supabase, Flutter, M4, M5, publication, payment, entitlement or any implementation. Acceptance, contract freeze, committed roadmap authorization, implementation acceptance and deployed production readiness are separate gates. None is self-issued here. The initial drafting task created this document; the current correction task permits editing this document only, with no roadmap change.

Repository baseline: `D:\Civilpedia`; HEAD and the local `origin/main` reference both equal `f4e1331cdca6ec87cb37d32d1d2473479ffb2852`. Local reference equality is not a fresh remote or deployment verification. The completed CUI-2 pre-implementation audit was delivered in conversation; this document does not invent a persisted audit report. Source inspection supports engineering behavior, not certification of deployed objects, data or permissions.

Authority order: [Agent Operating Model](../CIVILPEDIA_AGENT_OPERATING_MODEL.md) for routing; [Master Roadmap](../CIVILPEDIA_V1_MASTER_ROADMAP.md) for current authorization; [Frozen Commercial Model V1](../CIVILPEDIA_COMMERCIAL_MODEL_V1.md), current §33, for commercial policy; accepted [C1](CIVILPEDIA_COMMERCIAL_CORE_AUTHORITY_RECONCILIATION_CONTRACT_V1.md), [C2](CIVILPEDIA_COMMERCIAL_PUBLICATION_ENTITLEMENT_CONTRACT_V1.md) and [C3](CIVILPEDIA_COMMERCIAL_SUBSCRIPTION_ENTITLEMENT_ENFORCEMENT_CONTRACT_V1.md) for reconciliation, publication/entitlement separation and security/concurrency. The [CUI-1 contract](CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md), [media addendum](CIVILPEDIA_COMMERCIAL_CUI1_AUTHORITATIVE_MEDIA_ADDENDUM_V1.md) and [closure](../reports/CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_CLOSURE.md) remain unchanged.

Relevant source: migrations 00001–00010 for canonical storage/RLS; 00015/00017 for CLAIM creation; 00016/00018–00021 for staff, audit, activation, memberships and profiles; 00022–00025 for accepted private catalog and shadow boundaries. Current staff/profile/membership gateways and their focused server tests supply reusable conventions. Historical PASS counts remain historical. Drafting executes no Flutter tests, SQL, migrations, Supabase, HTTP, deployment or repository-wide suite.

## 2. Purpose and canonical identity

The later Admin Console needs narrow server authority to list and inspect canonical entities, create a real non-public ownerless Draft, edit eligible Draft content, and inspect its sanitized authoring audit. A0 supplies SQL/security authority only. No production Flutter gateway, domain object, provider, screen, route, DI, localization or theme change belongs to A0.

`public.directory_entities.id` is the sole canonical Business/Directory entity ID. A Business Entity is distinct from a user account. Do not add `owner_id`, a creator column, a second Business identity table, a new commercial lifecycle enum or a conceptual OWNER NOT YET ATTACHED flag. `public.business_memberships` retains its existing separate `OWNER / ADMIN / MEMBER` authority. Creator provenance confers no membership, management right or ownership.

Every successful create explicitly writes `lifecycle_status = 'draft'`, `verification_status = 'unverified'`, and the existing default `claim_status = 'unclaimed'`. These are existing engineering values. Unclaimed does not prove ownerlessness; ownerlessness at creation is the absence of any membership write/row. Draft existence does not confer paid/promotional entitlement, publication readiness, Sponsored, verification, Launch Partner selection or a permanent free commercial tier.

## 3. Exact authoring fields and validation

Both mutations accept a full replacement `p_payload jsonb` object with **exactly all six required keys** below. SQL NULL, wrong JSON kinds, omitted keys and unknown keys are rejected. Description/location may be JSON null; contacts/categories must be arrays, including empty arrays. Payload limit: 65,536 bytes of `convert_to(p_payload::text, 'UTF8')` before normalization. Limits are technical input bounds, not plan quotas or publication requirements.

| Payload key | Canonical storage | Proposed validation / semantics |
| --- | --- | --- |
| `entity_type` | `directory_entities.entity_type` | String passing the existing canonical validator AND equal to one of the four A0 authoring codes in §4; applies to CREATE and UPDATE. No alias, case conversion or invented type. Out-of-scope input is P0DAT invalid_staff_business_input. |
| `name` | `directory_entities.name` | String; PostgreSQL `btrim` normalization; 1–160 characters. Preserve language, spelling and case; no separate English name or inferred legal identity. |
| `description` | `directory_entities.description` | Null or string; `btrim`; empty becomes SQL NULL; maximum 2,000 characters. No HTML execution or services/products model. |
| `contacts` | `entity_contacts(contact_type, value, is_primary)` | 0–10 objects; exact required keys `contact_type`, `value`, `is_primary`; string/string/boolean. Normalize type with lower/btrim and value with btrim. See below. IDs/entity IDs/timestamps are server-owned. |
| `categories` | `directory_entity_categories(category_id, is_primary)` | 0–10 objects; exact required keys `category_id`, `is_primary`; UUID string/boolean. Unique category UUIDs, at most one primary. New writes require each referenced `directory_categories.is_active = true`; no taxonomy mutation or mandatory publication category. |
| `primary_location` | `entity_locations(region_id, address, latitude, longitude, is_primary)` | Null or one object with exactly all four required nullable keys `region_id`, `address`, `latitude`, `longitude`. UUID string/null; string/null; number/null; number/null. New writes require an active referenced region. Address btrim, blank→NULL, maximum 500 characters. Coordinates paired, finite, latitude −90…90, longitude −180…180, exactly representable at scale 6; reject precision loss rather than silently round. At least region/address/coordinate pair must be present. Server forces `is_primary = true`. |

Allowed contact types remain `phone`, `whatsapp`, `email`, `website`, `other`. Nonempty normalized values are required. Phone/WhatsApp: maximum 32 characters, regex `^[0-9+(). /-]+$`, at least three ASCII digits after stripping other characters. Email: maximum 254, case-insensitive regex `^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$`. Website: maximum 2,048, case-insensitive regex `^https?://[^[:space:]]+$`. Other: maximum 500. These reuse 00020's format checks; they do not verify channel control. Reject duplicate `(normalized type, lower(normalized value))` pairs and more than one primary per contact type. Retain the original normalized value's case in storage/fingerprints.

UUID strings must use the ordinary hyphenated UUID form, parsed to canonical UUID values; reject the nil UUID. JSON booleans are not strings/numbers. JSON numeric coordinates must satisfy `value = round(value, 6)` before storage. No string coercion or locale-dependent number parsing. Transport rejection before SQL entry remains a transport error; the function cannot promise custom SQLSTATE for an invalid PostgreSQL argument representation rejected by PostgREST itself.

On a material update, replace the selected entity's contacts and category assignments only when that respective normalized collection changed. Clearing uses an empty array. Upsert the existing primary location by its server-resolved ID, or insert one if absent; JSON null deletes only the existing primary location. Never accept a contact/location ID from the caller. Never update/delete another entity's children. If any non-primary location exists, the whole update is ineligible: P0TRA, no scalar/profile/location/child/version/audit mutation, including a proposed no-op. Do not delete or adopt additional locations. Media and all out-of-scope data remain untouched. Name/type/description change only their canonical columns after all eligibility checks.

## 4. Directory type validity and commercial eligibility

Reuse `public.is_valid_directory_entity_type(text)` from 00018. Its exact accepted set, also constrained by 00005, is:

```text
company
engineering_office
contractor
supplier
store
technician
laboratory
equipment_provider
service_provider
```

The lower-level nine-code validator and global Directory constraint remain unchanged. The exact **A0 V1 authoring allowlist**, applied independently after canonical validation to both CREATE and entity_type UPDATE, is:

```text
company
contractor
supplier
store
```

`engineering_office`, `technician`, `laboratory`, `equipment_provider` and `service_provider` are excluded from A0 creation/conversion. Invalid or canonical-but-out-of-A0-scope input raises `P0DAT / invalid_staff_business_input`, not an eligibility grant or automatic type substitution. All nine remain valid existing Directory data and may be read/filtered under business_entities.read within the fixed DTOs. A1's authoring choices must expose only the four A0 codes; read filters may use all nine.

This is a bounded authoring decision, not a global type change or commercial eligibility determination. The four-code restriction does not propagate to the existing NEW-application metadata validator/activation flow, which retains its original nine-code canonical behavior. Commercial Model §27.1/L-65 excludes individual professionals from ordinary Business plans and reserves engineering/consulting/laboratory organisation models; a Directory code alone cannot determine whether an organisation qualifies. No code is mapped to a plan, commercial eligibility, paid status or promotional access. Broader eligibility and any future authoring expansion remain separately governed. No new global enum/table or validator replacement is proposed.

## 5. Exact staff capabilities and provisioning

| Permission code | Definition to seed | Independently authorizes |
| --- | --- | --- |
| `business_entities.read` | `Read scoped staff Business Entity list and Draft-editor detail` | List and detail only. |
| `business_entities.create_draft` | `Create a non-public ownerless Business Draft` | Create and authorized historical create replay only. |
| `business_entities.edit_draft` | `Edit eligible staff-authored non-public Business Drafts` | Eligible Draft update only. |
| `business_entities.read_audit` | `Read sanitized entity-scoped Business Draft authoring audit` | A0 audit projection only. |

The scope of `read` is repository-wide canonical entity identity/profile data, including non-public rows, within the exact DTO; no region/tenant assignment model exists or is invented. A filter is not a security boundary. Grant this capability only to staff whose duties require that scope. Permissions do not imply one another. Create/edit success returns a receipt, not private detail; a separate read grant is needed to load detail. Audit permission alone does not confer profile editing or generic audit access.

Every privileged RPC derives `auth.uid()` and independently checks its exact permission before target existence, payload-dependent lookup or locking. The private checker joins `staff_memberships → roles → role_permissions → permissions`, requires `is_active`, `effective_at <= t`, and `expires_at IS NULL OR expires_at > t`, where `t = clock_timestamp()` captured once per checker call. Only the four exact codes are accepted; unknown/null code is false. Mutation permission is checked again after waiting for locks and immediately before writes. This uses a fresh statement snapshot under READ COMMITTED, not the old helper's transaction-start `now()` for elapsed expiry checks. No role/email/profile/UI shortcut, business membership shortcut or caller-supplied actor is permitted.

The proposal defines permission reference rows only. It creates no role, staff membership or role-permission assignment, and does not extend `application_reviewer`. Existing application capabilities do not inherit A0 powers. Trusted Document Owner/authorized administrator provisioning is a separate reviewed operation against the existing chain, identifying actual accounts, roles, exact grants, effective/expiry windows and accountable provisioning evidence. There is no self-enrollment or provisioning RPC in A0. Provisioning details/account identities remain OPEN for the later readiness gate.

Revocation semantics: a completed revocation visible before the final permission check denies the mutation. Revocation after that check may overlap an already executing transaction; this design does not lock the entire staff grant graph or promise cancellation of in-flight work. Later calls must deny. Reads similarly authorize an in-flight response once; future A1 must clear private state on observed denial/session change. If stronger grant-lock serialization is required, STOP for an explicit addendum.

## 6. Exact public RPC inventory and common errors

All six new client functions are public-schema JSONB RPCs, with no overloads, no actor argument and no extra endpoints. The separately specified replacement of the existing non-client CLAIM trigger function in §18 adds no A0 RPC or public Claim authority. List defaults apply only when arguments are omitted; explicit invalid/null page sizes are rejected.

```text
public.get_staff_business_capabilities() -> jsonb

public.list_staff_business_entities(
  p_search text DEFAULT NULL,
  p_entity_type text DEFAULT NULL,
  p_lifecycle_status text DEFAULT NULL,
  p_limit integer DEFAULT 25,
  p_before_created_at timestamptz DEFAULT NULL,
  p_before_id uuid DEFAULT NULL
) -> jsonb

public.get_staff_business_entity_detail(p_entity_id uuid) -> jsonb

public.staff_create_business_draft(
  p_request_id uuid, p_payload jsonb, p_reason text
) -> jsonb

public.staff_update_business_draft(
  p_entity_id uuid, p_expected_updated_at timestamptz,
  p_request_id uuid, p_payload jsonb, p_reason text
) -> jsonb

public.list_staff_business_entity_audit(
  p_entity_id uuid,
  p_limit integer DEFAULT 25,
  p_before_created_at timestamptz DEFAULT NULL,
  p_before_id uuid DEFAULT NULL
) -> jsonb
```

| SQLSTATE | Stable message / use |
| --- | --- |
| `P0AUT` | `unauthenticated`: auth identity absent inside an executable function. |
| `P0PER` | `staff_business_permission_denied`: exact required capability absent. Same error irrespective of target existence. |
| `P0DAT` | `invalid_staff_business_input`: invalid/null/nil ID, payload, reason, filter, page bound or cursor; no submitted value in error text/detail. |
| `P0NOT` | `entity_not_found`: target absent, after permission authorization. |
| `P0TRA` | `draft_not_editable`: target exists but fails §9 eligibility. |
| `P0CON` | `stale_draft_version`: expected version differs, or a material update cannot advance the existing timestamp token. |
| `P0RPL` | `draft_create_request_conflict`: same actor/key with a different canonical fingerprint. |
| `P0INV` | `draft_authority_invariant_conflict`: inconsistent receipt/provenance/created reference or malformed required A0 audit evidence. No repair. |
| `P0AUD` | `draft_audit_write_failed`: trusted append failed; rethrow as failure, roll back the complete mutation. |
| `P0CTX` | `unsupported_draft_transaction_context`: mutation isolation is not READ COMMITTED. |

Authentication, then exact permission, then argument validation, then authorized target/state checks determine application error precedence. SQL/ACL/transport errors before function entry, cancellation, lock timeout, deadlock `40P01`, serialization `40001`, and unexpected database failures remain failures, not fabricated success. Future clients map them to bounded typed outcomes and never display raw SQL, payload, stack or financial data. No function swallows an exception and commits partial work; no blind automatic mutation retry.

Capability discovery returns exactly `{"capabilities": [permission_code, ...]}`, in the §5 table order, distinct and containing only currently held A0 codes. Ordinary authenticated users receive an empty array; discovery is not a privilege grant. An absent auth identity raises P0AUT. Other five RPCs require their individual permission even if discovery previously reported it.

## 7. List projection and pagination

`list_staff_business_entities` requires `business_entities.read`. Optional type filter is one exact code from §4's nine-code canonical Directory list, not restricted to its four-code authoring subset; lifecycle filter is one exact existing `draft / active / inactive / suspended` value. NULL means no filter. Search is name only: btrim, blank→no filter, otherwise 1–120 characters; case-insensitive literal substring matching under the database collation. Escape backslash, `%` and `_` before ILIKE. No email/phone/actor/financial search, fuzzy match, transliteration, uniqueness decision or ranking change.

Limit 1–50, default 25. Order is immutable `(created_at DESC, id DESC)`; a subsequent page uses `(created_at, id) < (p_before_created_at, p_before_id)`. Cursor fields must both be NULL or both present; timestamps finite and IDs non-nil. Validate cursors, but they are pagination positions, never authority. Fetch at most limit+1 for continuation; return at most limit. No OFFSET or total-count query. Empty page is success with empty items and null cursor. Keep filters fixed across pages; changed filters require a restart. READ COMMITTED pages are not a frozen cross-request snapshot: filter/status changes may change later results; no exhaustive export guarantee.

Exact response:

```text
{
  items: [{entity_id, name, entity_type, lifecycle_status,
           verification_status, claim_status, created_at, updated_at}],
  next_cursor: null | {created_at, id}
}
```

UUIDs/timestamps are JSON strings; name/type/statuses strings. Cursor is the last returned item only when the extra matching row exists. Return source identity text faithfully, not fabricated/truncated identity. No `SELECT *` projection, membership role/roster/count, owner/creator inference, subscription/plan/billing, entitlement, application, verification evidence, media or private user PII. This minimum privileged read is not the public Directory cache or a publication result.

## 8. Detail projection

`get_staff_business_entity_detail` requires `business_entities.read`, permission before target lookup. Existing non-Draft and legacy entities are readable through the same minimal editor projection; reading them grants no write authority. Use one entity/children projection statement so content is internally snapshot-consistent. Exact outer and nested fields:

```text
{
  entity: {entity_id, entity_type, name, description,
           lifecycle_status, verification_status, claim_status,
           created_at, updated_at},
  contacts: [{id, contact_type, value, is_primary}],
  categories: [{category_id, code, name_ar, name_en, is_active, is_primary}],
  primary_location: null | {id, region_id, region_code, region_name_ar,
                           region_name_en, region_is_active,
                           address, latitude, longitude, is_primary},
  contacts_complete: boolean,
  categories_complete: boolean,
  location_scope_complete: boolean,
  draft_authoring: {origin: "CUI2A0" | "UNESTABLISHED", can_edit_draft: boolean}
}
```

Description and optional reference/location fields may be null; coordinates numbers/null; primary-location `is_primary` is true. Contacts order `(contact_type ASC, is_primary DESC, id ASC)`, categories `(is_primary DESC, category_id ASC)`. Return at most 50 each, using a 51st-row probe to set the corresponding completeness flag. Never silently describe a partial collection as complete or save it as a replacement. A0-created editable entities have at most ten of each; larger/invalid authoring collections fail eligibility. Assigned inactive references remain truthfully visible on reads; no active-only read filter erases existing assignments.

Exact new top-level signal: `location_scope_complete` is true if and only if `COUNT(*) FROM public.entity_locations WHERE entity_id = selected_entity_id AND is_primary = false` equals zero (equivalently NOT EXISTS). The existing NOT NULL flag and unique-primary index establish zero or one primary. Compute this in the same detail projection snapshot, including for legacy/non-Draft entities. A normal A0 Draft with zero or one primary and no non-primary locations returns true; any additional non-primary location returns false, leaves detail readable, and forces can_edit_draft=false. Do not return/adopt/delete those additional rows or reinterpret them as Branches. This is scoped editor completeness, not publication/ownership/commercial completeness.

`origin` is established only by a matching committed create receipt and the unique typed A0 create audit, not by lifecycle, creator name or ownerlessness. `can_edit_draft` requires the current edit permission and every §9 eligibility predicate, including complete contacts/categories within authoring bounds and location_scope_complete=true; no diagnostic membership/subscription facts are returned. It is a present server capability hint, not an authority token, ownership/finance proof or a promise that a later write succeeds. The mutation independently rechecks every predicate under its lock. Read-only does not mean not owned. No owner field, membership join DTO, creator profile, application notes, financial fields, raw audit, media or publication-readiness result.

## 9. Eligible Draft update domain

Editing is limited to entities created through this A0 authority. All predicates are required together:

1. Existing canonical entity, with matching valid A0 creation receipt and unique create audit marker/request/target; no automatic adoption/backfill of application-created or legacy Drafts.
2. Current `lifecycle_status = 'draft'`, `verification_status = 'unverified'`, `claim_status = 'unclaimed'`.
3. No `business_memberships` row for the entity, of any role; no legacy `subscriptions` row for the entity, of any status. These are internal exclusion checks, never a commercial entitlement evaluation or exposed finance/ownership inference.
4. Contacts/categories are fully represented within the ten-item authoring bounds, with valid canonical data that can be compared without lossy normalization. New payload references are validated independently.
5. Zero non-primary `entity_locations` rows for the selected entity; location_scope_complete=true. Any additional non-primary row makes the entire update P0TRA with no mutation, even if the proposed fields do not include a location change.
6. Current entity_type belongs to the four-code A0 authoring allowlist; payload entity_type independently must belong to it. A current entity changed outside that scope by a separately governed writer is read-only to A0 (P0TRA); out-of-scope mutation input is P0DAT.
7. Authenticated actor currently holds `business_entities.edit_draft`.

Expected timestamp equality is an additional mandatory UPDATE precondition (§12), not an input to the detail DTO's can_edit_draft calculation. Detail has no caller-supplied expected version; its boolean reports only present eligibility/capability, and the mutation independently compares the submitted version under lock.

An entity leaving these bounds becomes read-only to A0. Do not reset status, remove memberships/subscriptions, downgrade verification or reclassify data to recover edit access. Missing target is P0NOT; existing ineligible target P0TRA; corrupt claimed A0 creation evidence P0INV. An unestablished legacy origin is ordinary ineligibility, not automatically corruption. Privileged non-A0 writers remain separately governed; new integrated writers must serialize relevant eligibility changes through the canonical entity lock.

## 10. Create transaction and replay receipt

Creation reason is required and exactly `BUSINESS_SUPPLIED_INFORMATION` or `BUSINESS_AUTHORIZED_PREPARATION`. It records the operator's context under policy §32.5.2; it is not proof of consent, identity, ownership or publication rights. No free-form private notes/evidence collection is introduced.

Transaction sequence:

1. Derive actor, require exact create permission; reject unsupported isolation; validate non-nil request UUID, reason and structurally normalize the bounded full payload.
2. Compute §11 fingerprint. Generate a candidate entity UUID and transaction timestamp server-side. Attempt to insert the receipt keyed `(actor_user_id, request_id)` with `ON CONFLICT (actor_user_id, request_id) DO NOTHING`. Other uniqueness failures remain failures. Receipt reservation comes before entity/child locks; there is no committed pending/success state flag.
3. A conflicting insertion waits on the same key. In a **fresh statement snapshot** after that wait, recheck current permission, read the committed receipt, compare fingerprint and verify original entity/create-audit linkage. Exact valid replay returns the original receipt (§11); changed payload returns P0RPL. Do not write or lock/recreate the target on replay. Missing/inconsistent original evidence returns P0INV.
4. A new key inserts exactly one canonical entity with explicit forced statuses. Returned ID/created/version timestamps must equal the reserved receipt's values; otherwise fail P0INV. No business membership, subscription, application, private commercial record or media insert.
5. Validate active category/region references under §13 locks, write selected entity's bounded children, recheck create permission after waits and before effect writes; append the typed create audit in the same transaction through `public.append_audit_log`.
6. Return the receipt only after successful audit. Commit entity, children, receipt and audit together. Any failure rolls back all of them; no failed/pending receipt survives. The §18 canonical CLAIM insertion guard is already hardened in the same deployed 00026 migration; no successful A0 create may be enabled without it. A0 always inserts a new entity UUID, never attaches a receipt to/adopts an existing entity. Committed entity visibility therefore cannot precede its protecting receipt.

Exact response: `{outcome: "CREATED" | "REPLAY", request_id, entity_id, created_at, created_updated_at}`. Timestamps are immutable original creation evidence, not the current editor version. Replay can return historical success after the entity was edited, claimed or moved out of Draft, provided the original entity/create evidence remains consistent. It does not re-establish authoring eligibility, repair data, reset statuses, grant rights or promise current ownerlessness. Load detail separately with read permission before further editing.

## 11. Minimal replay storage and canonical fingerprint

Propose one non-exposed schema `business_admin_private`, separate from `commercial_private`, and one operational receipt table `business_admin_private.draft_create_requests`. This is request serialization/history, not a second entity, membership, commercial ledger or provenance SSOT. It avoids uniqueness races in arbitrary audit JSON and avoids changing M3's exact private-schema inventory. The existing audit remains creator/action provenance.

| Receipt column | Exact type / constraint |
| --- | --- |
| `actor_user_id` | UUID NOT NULL, non-nil; derived from auth.uid. |
| `request_id` | UUID NOT NULL, non-nil; opaque create request key. |
| `payload_fingerprint` | BYTEA NOT NULL, octet length exactly 32. |
| `entity_id` | UUID NOT NULL, non-nil, UNIQUE; original effect reference. |
| `created_at` | TIMESTAMPTZ NOT NULL, finite; actual canonical creation timestamp. |
| `created_updated_at` | TIMESTAMPTZ NOT NULL, finite and equal to created_at at creation. |

Primary key `(actor_user_id, request_id)`; no additional surrogate ID, pending state, payload/PII blob, owner association, sequence or entity author column. No foreign keys to auth/entity: receipt retention must neither block account deletion nor cascade away duplicate-submit evidence. The logical effect reference is validated on replay; a deleted/missing entity is P0INV, never a new create. No client ACLs, UPDATE/DELETE path, cleanup job or TTL. Receipt presence also supplies the narrow §18 CLAIM-denial predicate; the guard uses entity_id presence regardless of current lifecycle or other receipt/audit fields, without an ownership inference. Retention/disposition remains OPEN under OQ-40/OQ-82; current safe behavior retains receipts until a separately authorized retention contract. Any later retention/rollback design must preserve server-side CLAIM isolation for retained A0 entities, rather than silently remove that protection by deleting receipts. This is not a statutory/permanent-retention policy.

Fingerprint version is `cui2a0.create.v1`. Hash exactly `extensions.digest(convert_to(canonical_jsonb::text, 'UTF8'), 'sha256')`. Canonical JSONB has exactly `operation_version`, `payload`, `reason`; operation_version is that literal. Payload is the six-field normalized object from §3. Canonicalize UUID strings through UUID→text; description/address blank→null; required booleans explicit; coordinates convert to NUMERIC(9,6) before JSONB serialization (paired JSON null otherwise). Sort contacts by `(contact_type, value COLLATE "C", is_primary)` and categories by UUID ASC before aggregation. Case changes in retained values and any primary-flag change are material. Array ordering, JSON object-key ordering and UUID-letter case are not material. No name case folding, business deduplication or identity inference.

Structural normalization is independent of current category/region activity: an authorized exact replay of a committed creation still works after those references are retired. Validate active references only on new effects. Same key is actor-scoped; another actor's same UUID is a separate intentional create, not a business duplicate determination. Same actor/different key may create another same-name Draft. Name uniqueness/merge is not added. One key produces exactly one entity and one create audit under concurrent calls. Corrupt evidence fails closed without self-healing or automatic retry. Unknown network outcome permits user-directed replay of the identical create request key/payload/reason after authorization, never generation of a replacement key by an automatic retry loop.

## 12. Update transaction and version behavior

Update reason is exactly `CORRECT_DRAFT_INFORMATION` or `COMPLETE_DRAFT_INFORMATION`. `p_request_id` is a required non-nil audit correlation UUID, **not an update idempotency key**. No generic mutation ledger is added.

1. Derive actor and require edit permission **before any target lock/existence lookup**; validate request UUID, finite non-null expected timestamp, full payload and reason; require READ COMMITTED.
2. Lock exactly the selected `directory_entities` row FOR UPDATE. After any wait, recheck current edit permission using fresh time/snapshot, re-evaluate every §9 predicate under the lock and compare the actual timestamp to the expected timestamp. No old cached capability or pre-lock state is sufficient.
3. Normalize the existing scoped content and compare values to normalized input, ignoring server-generated child IDs and array presentation order. A no-op still requires all guards and matching version; return `{outcome: "UNCHANGED", request_id, entity_id, updated_at}` with no writes/audit/version bump.
4. For material change, validate/lock active references (§13), perform the final permission check, require `transaction_timestamp() > current_entity.updated_at`, write changed canonical scalar/child groups atomically, and use the actual entity UPDATE RETURNING timestamp. The entity is updated even for child-only changes so all scoped edits invalidate its version token. Require actual returned timestamp strictly greater than the old token; otherwise fail P0CON and roll back.
5. Append one sanitized update audit; return `{outcome: "UPDATED", request_id, entity_id, updated_at}`. Never modify lifecycle, verification, claim, created_at, memberships, subscriptions, applications or commercial data.

The existing shared BEFORE UPDATE trigger sets `updated_at = now()` and overrides an assigned `clock_timestamp()`. A0 must account for that fact, not claim clock_timestamp guarantees advancement. The explicit advancement guard rejects same-transaction repeated material edits or a transaction that started before the last committed update. It requires a fresh transaction/read, not a trigger patch, new version column, automatic sleep/retry or false success. Preserve exact database microsecond precision when A1 round-trips versions.

Two concurrent material updates with one old version yield one success and one P0CON. A repeated successful update with the old expected version yields P0CON, even with the same request UUID. After an unknown update outcome, A1 must explicitly reread authorized detail/audit and ask the operator to reconcile; it must not replay blindly. No-op replays do not create artificial history.

## 13. Shared lock order and known 00020 reconciliation

All A0 mutations are single-entity READ COMMITTED commands; no batch endpoint or transaction control inside functions. The migration runner owns migration atomicity; PostgREST/caller owns each RPC transaction.

Proposed order, acquiring only necessary tiers:

```text
initial exact permission check
create only: actor/request receipt uniqueness reservation
canonical entity row (new INSERT for create; FOR UPDATE for edit)
directory_categories reference rows in UUID ASC, FOR SHARE
regions reference row if supplied, FOR SHARE
selected entity_contacts rows in UUID ASC
selected directory_entity_categories rows in category UUID ASC
selected primary entity_locations row
same-transaction audit insert
```

FOR SHARE on taxonomy references, rather than FOR KEY SHARE alone, prevents concurrent `is_active` changes before the write; recheck activity after waiting. New A0 writers follow the same order. Create permission is rechecked after the receipt wait and after reference waits; final child writes/audit cannot follow a failed recheck. Entity insertion before later validation remains uncommitted and rolls back on denial. Detail/list/audit reads acquire no authoring row locks. Receipt replay takes no existing entity mutation lock. Update never takes a receipt reservation while holding an entity lock.

00018/00016 application transitions use application→entity; A0 authoring RPCs acquire **no application lock and call no application activation/mutation**, including while holding an entity. The one bounded existing CLAIM insert-guard replacement in §18 retains its target-entity FOR UPDATE lock and reads the receipt with a plain existence SELECT only: no receipt reservation/FOR UPDATE/FOR SHARE/advisory lock after an entity lock, so it adds no inverse receipt→entity dependency against create. 00020 locks entity before membership authorization; A0 instead checks its staff capability before the entity lock and repeats it after waiting. This satisfies the new authority's boundary while carrying 00020's existing issue forward unchanged (C3 §47). Do not call its profile update/projection as an authorization substitute or silently patch its source.

No catalog/program/transfer/launch-scope/commercial aggregate lock or M3 invocation is needed here. A future integrated writer requiring those tiers must preserve C3 §31's hierarchy and obtain a separate contract. Relevant membership/status/subscription changes by integrated writers must hold the canonical entity lock first; current CLAIM activation does. Arbitrary trusted administrative SQL bypass is not prevented by A0, and production readiness must verify sanctioned writers. Deadlock/cancellation rolls back; no blind mutation retry. A1 retries only after explicit reread/operator action.

## 14. Audit writes, sanitized history and provenance

Exact actions: `business_entity.draft_create` and `business_entity.draft_update`; target_type exactly `directory_entity`, target_id the canonical entity UUID, actor derived auth.uid. Reuse `public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)` unchanged. Its server timestamp supplies audit created_at. Failure becomes P0AUD and aborts the whole mutation. There is no client audit insert or general audit reader.

Typed audit format is `cui2a0.audit.v1`. Create before_data is SQL NULL. Create after_data has exactly `format_version`, `request_id`, `changed_fields`, `updated_at`, `contact_count`, `category_count`, `has_primary_location`; changed_fields is the six §3 field names in that table order. Update before_data has exactly `updated_at`, `contact_count`, `category_count`, `has_primary_location`; update after_data has the same create after_data keys, with changed_fields containing only materially changed scoped fields, unique and in §3 order. Counts are 0–10, location flag boolean, timestamps finite, request UUID non-nil. Reason is the matching exact §10/§12 reason code. No name/description/contact/address/coordinate values, evidence, actor profile, payload fingerprint, receipt raw row, private notes, money or subscription values in the audit summary.

`list_staff_business_entity_audit` independently requires `business_entities.read_audit`, before entity existence/lookup; missing entity P0NOT. Return only records for that target, target_type and the two exact actions. Legacy `business_profile.update`, application events and every other audit family are excluded. Limit/cursor/order/continuation match §7, with audit `(created_at DESC, id DESC)` and the same finite paired-cursor validation. Do not return raw before_data/after_data.

Exact response:

```text
{
  items: [{audit_id, actor_user_id, action, created_at, reason_code, request_id,
           change_summary: {changed_fields, before_updated_at, after_updated_at,
                            before_contact_count, after_contact_count,
                            before_category_count, after_category_count,
                            before_has_primary_location, after_has_primary_location}}],
  next_cursor: null | {created_at, id}
}
```

Actor UUID is nullable because existing audit FK uses ON DELETE SET NULL; no actor email/name/phone/profile lookup. Create before-values are null; update before-values typed as above. Whitelist fields and validate action-specific format/types/reason/request linkage; malformed required A0 evidence on the selected page fails the whole page P0INV, never a permissive raw/partial fallback. Extra corrupt raw keys are never exposed and constitute invariant failure. A0 history means **A0 Draft authoring history**, not complete Business history or ownership/legal evidence.

A unique create audit for the entity, together with its consistent receipt correlation, proves this authority authored that entity. Creator identity lives in existing audit evidence, subject to existing account-deletion behavior; receipt actor is operational replay scoping, not an owner/creator entity column. No backfill, arbitrary creator assignment or ownership inference. No-op updates/read denials are not successful authoring events.

## 15. Exact proposed migration/object inventory

Current source has 25 migrations, highest `00025_commercial_entitlement_evaluator_shadow.sql`. Proposed next filename:

```text
supabase/migrations/00026_commercial_admin_business_draft_foundation.sql
```

**Do not create this migration during drafting.** If 00026 is occupied or the baseline changes before authorization, STOP and obtain a revised exact contract; never rename/retry blindly.

Proposed objects/data changes, and no others:

| Kind | Exact inventory |
| --- | --- |
| Namespace | `business_admin_private`, owner postgres, outside exposed API schemas. No change to commercial_private. |
| Table | `business_admin_private.draft_create_requests`, exact §11 columns/checks, PK and UNIQUE(entity_id); defensive RLS enabled, no policies. |
| Internal functions | `business_admin_private.has_staff_business_permission(text) RETURNS boolean`, VOLATILE, SECURITY INVOKER; `business_admin_private.normalize_draft_payload(jsonb) RETURNS jsonb`, IMMUTABLE, SECURITY INVOKER. Both owner postgres; no client EXECUTE. Normalizer is structural only; no active-reference lookup, actor/capability inference or mutation. |
| Public functions | Exactly the six signatures in §6; VOLATILE, SECURITY DEFINER, owner postgres. Definer is necessary to read/write existing RLS/grant-protected staff/entity/child/audit data without direct client privileges; it does not replace authorization. |
| Existing CLAIM guard replacement | `CREATE OR REPLACE FUNCTION public.guard_claim_application_insert() RETURNS trigger`, exact §18 hardening; VOLATILE, SECURITY DEFINER, owner postgres, fixed search_path=pg_catalog,pg_temp and no client EXECUTE. Preserve the existing function identity and `trigger_guard_claim_insert` BEFORE INSERT binding on public.business_applications; no new trigger or competing workflow. |
| New explicit index | `public.idx_directory_entities_cui2a0_staff_page` on directory_entities `(created_at DESC, id DESC)`. |
| New explicit audit indexes | `public.idx_audit_logs_cui2a0_entity_page` on audit_logs `(target_id, created_at DESC, id DESC)` WHERE target_type='directory_entity' AND action IN the two §14 actions; `public.uq_audit_logs_cui2a0_draft_create` UNIQUE on audit_logs `(target_id)` WHERE target_type='directory_entity' AND action='business_entity.draft_create'. |
| Permission data | Exactly four §5 definitions; zero role/role_permissions/staff_memberships changes. |
| Privilege metadata | Explicit owners, scoped schema defaults, RLS enablement and ACLs in §16; no exposed-schema/Realtime/GraphQL configuration change. |

Implicit receipt PK/unique indexes and dependent row/array types are expected; no new enum/sequence/view/trigger/RLS policy or other helper. The unique audit index prevents ambiguous multiple A0 creators without imposing business-name uniqueness. Original `audit_logs` schema/append helper and every prior migration remain unchanged. No entity/child/membership/subscription schema alteration, catalog seed/change, M3 provider/evaluator/table/index change or other existing-function replacement. The only existing authority function change is the exact §18 CLAIM guard replacement in new 00026; original 00014/00015/00017 remain byte-exact. Existing table structural changes are only the three explicit indexes; historical application rows, constraints, indexes and trigger binding are preserved.

Migration preflight verifies actual current_user postgres, expected predecessors/owners/RLS/ACLs/defaults, extensions.digest availability, canonical validator/types/columns/trigger behavior, unused exact new names, non-exposure of the private namespace and absence of unexpected sanctioned writers. Verify the existing guard's accepted 00015 definition, 00017 execution denial, trigger binding and canonical target FK/live-CLAIM index before its sole authorized replacement; unexpected drift is a STOP. Create the private receipt table before replacing the guard, with final assertions covering the protected predicate/error/lock behavior and absence of client EXECUTE. Seed permission codes only when absent; an existing conflicting A0 code/definition or new object is a STOP, not an ON CONFLICT overwrite/ignored discrepancy. Runner executes the complete migration atomically; no staff-create availability/provisioning before the guard is installed. A failed final assertion leaves no partial A0 additions/grants and restores the pre-00026 guard. No embedded COMMIT, transaction=false or production backfill. Abort an unreviewed privilege/owner discrepancy rather than normalize existing global configuration silently.

## 16. RLS, owner, EXECUTE and default privileges

Every new function and the narrowly replaced CLAIM guard have fixed `SET search_path = pg_catalog, pg_temp` and explicitly qualified public/private/auth/extensions objects. Private helpers execute under the calling definer's owner context; they need no SECURITY DEFINER of their own. No unqualified application relation/function, dynamic SQL identifier, caller search_path, temporary object, session role label or caller actor may affect authority.

In the same migration transaction: owner postgres explicitly; REVOKE ALL on private schema/table/helpers from PUBLIC, anon, authenticated, service_role; schema USAGE/CREATE absent for all those roles, no Realtime/publication membership, no private client policies. Receipt RLS enabled with no policies; owner access is intentional, FORCE RLS not added. Assert effective/inherited privileges, schema CREATE access, ownership and table/function ACLs, not just textual REVOKE statements. No client membership in the owning role. Postgres is the verified existing backend function-owner convention; no new broad admin/BYPASSRLS role is created.

Each new public A0 RPC: revoke EXECUTE from PUBLIC, anon, authenticated, service_role, then explicitly grant EXECUTE to authenticated only. Internally require auth identity plus exact capability as specified (discovery evaluates all four). No grants to PUBLIC/anon/service_role, no grant option, and no helper execution grant. Anonymous calls can fail at ACL before P0AUT; tests must distinguish that from an executable but empty-auth call.

The existing CLAIM trigger function remains non-client-executable and owned by postgres; explicitly revoke EXECUTE from PUBLIC, anon, authenticated, service_role. Its SECURITY DEFINER context is necessary to inspect private receipts independently of caller RLS. It is invoked only through the preserved table trigger for every applicable INSERT, including trusted direct SQL, without a staff-permission exception or new ordinary-client grant. Trigger invocation does not require the inserting client's function EXECUTE privilege (existing 00017 convention). Existing create_claim_business_application signature/ACL/body and all application mutation/activation functions remain unchanged; their INSERT inherits the same canonical guard.

00022 already hardens postgres global future-object defaults. Preflight/final assertions retain those defaults and commercial_private's existing scope. Explicitly deny non-owner defaults in the new business_admin_private namespace for tables/functions/types/sequences, with no broad alteration to public-schema legacy defaults/grants. Default PUBLIC function EXECUTE must never be assumed safe or allowed during a partial migration; all actual ACLs are asserted before commit. A privileged function is not secured by RLS bypass alone.

No INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER grant is added over directory_entities, entity_contacts, directory_entity_categories, entity_locations, business_memberships, subscriptions or audit_logs. Existing RLS/SELECT policies and public Directory reads remain byte/behavior compatible. Active public rows/children retain existing visibility; new Draft parent and children remain unreadable through ordinary anon/authenticated public queries, including ID-based/nested reads. No general authenticated table SELECT over private Drafts, no plan/private commercial query and no public read cutover. No service-role secret in Flutter; preserve one production Supabase authority and one AuthProvider.

## 17. Boundaries preserved from frozen policy

| Domain | Exact A0 boundary / future owner |
| --- | --- |
| Location / الموقع | Zero or one primary Directory location only. Directory Location != Commercial Branch. Any non-primary row makes the entire A0 edit ineligible; detail remains readable with location_scope_complete=false. No deletion/adoption or Branch identity/lifecycle/team/contact/quota model. |
| Media | No input/read-management projection/upload/delete/order/moderation/MIME infrastructure/Storage/bucket/object ownership. CUI-1 may present existing authoritative typed HTTPS media under its addendum; A0 does not create fake/company media. Future media authority is deferred. |
| Ownership / invitation | Ownerless creation only. No Invite Owner, direct arbitrary assignment, membership mutation, Primary Owner/Co-Owner/Manager/Editor/Finance mapping, recovery/transfer/password handover/public Claim CTA. CUI-2C1 separately governs these; existing NEW activation unchanged. |
| Publication | No active transition or publish/activate/hide/suspend/reopen/close/terminate RPC/action/button/readiness field. Existing active RLS != completed commercial publication authority. M5 remains unauthorized. |
| Payment / entitlement | No plan activation, subscriptions/payment/order/term/grant writes, catalog reads, M3 runtime composition, Sponsored/Launch Partner/Founding allocation or entitlement consumption. Absence of such writes is not commercial eligibility approval. M4/M5 remain unauthorized. |
| Moderation | Only non-public Draft edits. No active/entity staff edit, published/proposed content mechanism, sensitive-change review or verification grant/withdrawal. Existing immediate member profile writes are carried to CUI-2C2; do not patch them here. |
| Deduplication | Staff name search before creation is available. No similar-name rejection, automatic merge/retirement, owner assignment or inferred duplicate identity; OQ-72 remains OPEN. Technical request/UUID/primary-child uniqueness is not commercial deduplication. |
| Taxonomy | Assign existing active categories/region only. No category/activity/subcategory/label/order/visibility administration or new type. |

## 18. Mandatory A0 CLAIM isolation and separate legacy carry-forward

**CF-CLAIM-01 — A0 Draft isolation: CLOSED AT CONTRACT REQUIREMENT LEVEL; IMPLEMENTATION AND RUNTIME EVIDENCE PENDING.** The supplied Architect correction requires the following protection as part of A0, not an unresolved pre-live operating-posture choice. The contract is ACCEPTED / FROZEN; implementation remains NOT AUTHORIZED; this is not a claim that the current deployed/source guard is already hardened.

Source evidence: 00014 binds `trigger_guard_claim_insert` BEFORE INSERT, FOR EACH ROW, on `public.business_applications` to `public.guard_claim_application_insert() RETURNS trigger`. 00015 replaces that same function to lock the target entity FOR UPDATE before claim-status validation. 00017 revokes its ordinary client EXECUTE and routes CLAIM creation through `public.create_claim_business_application(uuid)`, whose INSERT invokes the trigger. No later migration replaces the guard. Current source accepts an unclaimed private target without an active-lifecycle check; the UI's active-target filter does not close that server-side gap.

### 18.1 Exact narrow replacement and predicate

Future 00026 must **CREATE OR REPLACE only `public.guard_claim_application_insert()`**, preserving RETURNS trigger, plpgsql, existing function identity/dependent trigger and table constraints/indexes. Declare VOLATILE / SECURITY DEFINER, owner postgres, fixed search_path=pg_catalog,pg_temp, fully qualified relations and explicit no-client EXECUTE (§16). No new trigger, predicate helper, RPC, competing CLAIM workflow, staff bypass or patch to prior migration files.

For `NEW.application_type = 'CLAIM'` with a non-null target, the additional denial predicate is exactly:

```text
EXISTS (
  SELECT 1 FROM business_admin_private.draft_create_requests AS receipt
  WHERE receipt.entity_id = NEW.target_entity_id
)
```

Presence of the protecting receipt is sufficient to deny; do not condition the denial on lifecycle, current claim status, verification, actor, audit availability, permission or receipt fingerprint validity. No audit/membership/financial join. The original entity stays draft/unverified/unclaimed and ownerless; do not fake claimed status, attach membership or alter verification to block CLAIM. The protection remains while the receipt exists, including after separately authorized later state changes. There is no implicit override/exception in A0.

### 18.2 Exact lock/read/error sequence

1. If application_type is not CLAIM, return NEW unchanged. A raw CLAIM with NULL target also returns NEW to the existing `chk_app_requires_target_for_claim` check (23514); the ordinary CLAIM RPC retains its existing P0DAT target_required before INSERT. Do not change NEW behavior or other constraint errors.
2. For a non-null CLAIM target, `SELECT de.claim_status INTO the local status FROM public.directory_entities AS de WHERE de.id = NEW.target_entity_id FOR UPDATE`. Acquire by ID regardless of status. Inspect FOUND immediately, before a receipt query can replace it; the row lock is held for the inserting transaction.
3. If no target row was visible/lockable, immediately raise SQLSTATE **23503**, message **`claim target not found`**, with no DETAIL/HINT. The existing targetNotFound mapping is preserved; the target FK remains installed. This deliberately moves absent-target rejection from a later FK check to the canonical guard. Returning NEW in this branch is forbidden: a concurrently inserted A0 entity could commit after an empty lock lookup and before the later FK check, allowing an otherwise unchecked CLAIM. NULL handling remains as step 1.
4. If the target was locked, inspect receipt existence in a **separate ordinary SELECT after acquiring/waiting for the target lock**. Under READ COMMITTED this is a fresh statement snapshot and must see a protecting committed receipt. The caller's own transaction receipt is also visible and denies. Do not select FOR UPDATE/FOR SHARE on receipt rows, reserve a request key, or acquire any advisory/application lock. Capture the original claim-status value from the locked row.
5. If that status is not unclaimed **OR** the receipt exists, raise **`P0CLM / target entity is not claimable`**, with no DETAIL/HINT. Use the identical generic message/SQLSTATE for receipt-protected and otherwise unclaimable targets. Do not emit a special A0 code, private table name, creator/request IDs, provenance, audit or receipt fields. Existing Flutter maps P0CLM to targetNotClaimable; no Flutter change is required. No caller can infer specifically "staff-authored A0 Draft" from a distinct denial. Database-generated context names only the existing canonical guard; no custom private-provenance context is supplied.
6. Otherwise return NEW and preserve normal INSERT/FK/live-CLAIM unique-index enforcement. The function performs no data mutation; failed CLAIM creates no application/ownership/audit effect.

Existing non-A0 unclaimed targets remain eligible under the same legacy rules, including non-public/non-active targets previously allowed by the server; no global lifecycle/type/membership restriction is added. Pending/claimed targets remain P0CLM, missing non-null targets remain 23503, raw NULL targets retain their CHECK behavior, and duplicate live claims retain 23505. The only deliberate compatibility adjustments are generic truthful P0CLM wording and the earlier 23503 timing required to close the absent-row race; current client error mappings are unchanged. Existing NEW application creation/activation, ordinary CLAIM RPC signature/ACL, application transitions, historical rows, target FK and `uq_business_applications_live_claim` are untouched. No history rewrite or retroactive ownership change.

### 18.3 Race-safety requirement

A0 writes receipt → new entity → bounded children → audit in one transaction, with no adoption of an existing entity and no partial commit. If a CLAIM guard sees and locks the newly committed A0 entity, the protecting receipt was committed in that same transaction; its post-lock SELECT denies P0CLM. If a CLAIM starts before that entity is committed/visible, the empty lock lookup fails immediately with 23503, so a later create commit/FK wait cannot admit the application. A transaction seeing its own A0 creation also sees its receipt and denies. A rolled-back A0 create leaves neither entity nor receipt and cannot admit a CLAIM. UUID knowledge/secrecy and public RLS visibility are irrelevant to this protection.

VOLATILE ensures fresh post-wait statement visibility under READ COMMITTED. At stricter isolation, a snapshot containing the A0 entity also contains its atomic receipt; a snapshot predating both hits the early absent-target denial, or serialization/cancellation remains a rolled-back failure. There is no allowed stale-receipt fallback. No server-side receipt cleanup/adoption in A0 can create a later gap. Mandatory multi-session evidence covers pre-commit guessed IDs, post-commit IDs, rollback and target-lock waits; it cannot be replaced by a UI/filter test or a sequential happy path.

Receipt existence is a plain read after the existing entity lock, not a reciprocal receipt lock; it cannot create an entity→receipt reservation cycle against A0 create's receipt→new-entity order. If inspection/implementation proves this canonical function cannot be hardened within these exact semantics without broader application changes, STOP and report **BLOCKED — ARCHITECT REVIEW REQUIRED**, rather than introduce parallel authority.

### 18.4 Remaining separate legacy policy issue

The broader authenticated public CLAIM route/button/RPC conflicts with Commercial Model §27.2/L-66 and C1 AR-03 for controlled Commercial V1 onboarding. That governance reconciliation remains separate; A0 does not promote/reuse/remove the CTA, decide disable/staff-only/retire behavior for non-A0 entities, or provide an invitation substitute. A0-created entities themselves are protected by the mandatory database guard and are no longer left claimable pending later disposition.

The known 00020 permission-after-lock and immediate sensitive-member-write findings remain **CF-PROFILE-01 / CF-MODERATION-01**. The new RPC order addresses A0 itself; this does not close the old finding or create the future sensitive-change system. Relevant separately authorized ownership/state changes make A0 editing ineligible under the shared entity lock. They do not permit legacy CLAIM takeover or turn member authoring into staff authority.

## 19. Future implementation file boundary and composed guards

Proposed new implementation/test files, only after separate authorization:

```text
supabase/migrations/00026_commercial_admin_business_draft_foundation.sql
supabase/tests/commercial_cui2a0_admin_business_draft_foundation_test.sql
test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
```

No production lib file. Existing static guards contain exact historical migration counts and source/governance comparisons: M1b and M3 currently require 25 migrations. HARDEN-1 independently compares the roadmap to the older CUI-1 authorization/media suffix and does not name the later CUI-1 final-closure record. This is source evidence of a current governance-expectation mismatch, not a fresh executed test failure. Its historical PASS is not proof of this drafting baseline. Therefore the following **four existing test paths only** are proposed for necessary composed compatibility, separate from new A0 assertions:

```text
test/commercial_m1a_private_catalog_migration_test.dart
test/commercial_harden1_public_plans_exposure_migration_test.dart
test/commercial_m1b_catalog_reference_data_migration_test.dart
test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart
```

Retain all fixed historical checkpoints/source hashes and accepted CUI-1/M3 records. First require an explicitly authorized, independently reviewed documentary/static compatibility correction recognizing the already committed CUI-1 closure in HARDEN-1 and its composed source expectations; prove the focused preimplementation baseline freshly GREEN before any new A0 SQL work. This dependency is handled in a separate expressly authorized compatibility pass after contract review; no correction/test is performed or claimed here. Add hand-authored recognition of only the exact separately committed A0 authorization record, exact 00026 filename and bounded A0 delta, including the sole §18 guard replacement; retain exact preservation of migrations 00001–00025, lib, commercial_private schema/functions/reference rows and unrelated governance. Test that an extra migration, historical-byte edit, unauthorized lib path, commercial data/authority grant, mutated authorization record or removed/bypassed A0 CLAIM protection still fails. No dynamic expectation copied from current implementation, broad path prefix, relaxed historical count without suffix validation, deleted guard or blanket acceptance of future migrations. All four guards remain untouched during current drafting/correction.

This is a proposed **seven-file SQL/security/test boundary**, not permission to edit any test now. Later governance authorization must supply its own exact committed record/path/bytes; this draft cannot invent a future commit SHA or self-activate that control. If compatibility needs a fifth existing guard or another implementation file, STOP for an exact addendum. The contract's later acceptance/authorization documentation is separately governed; it is not permission for implementation to rewrite frozen records.

## 20. Focused verification matrix for later implementation

All cells are mandatory future evidence, not tests run by this draft. Static Dart/source checks establish exact interface/inventory/preservation; pgTAP in an isolated disposable local Supabase database establishes actual SQL/ACL/RLS/transaction behavior. Multi-session tests must prove waits/races, not simulate PostgreSQL locks only in Dart. Use SQL test-script modes in the new test file plus explicit independent psql sessions; no extra runner file without addendum. Each mode uses declared fixture UUIDs, explicit transactions and rollback/cleanup in that disposable database. Production fixtures/provisioning/deployment are excluded.

| ID | Required evidence / expected result |
| --- | --- |
| T01 | Exactly four code/description rows; zero new roles/staff/role_permissions rows; application_reviewer has no automatically assigned A0 capability. |
| T02 | Six exact new A0 client RPC signatures/JSON fields, two private helpers, one receipt table/private schema, three explicit indexes, and only the specified existing guard replacement with unchanged trigger binding; no additional function/role/view/policy/trigger. |
| T03 | Ordinary authenticated user and business OWNER/ADMIN/MEMBER without staff permission: discovery empty; list/detail/create/edit/audit P0PER even for guessed existing/missing IDs. |
| T04 | Inactive, future-effective, expired staff and revoked role-permission: denied independently on every applicable RPC; exact effective boundary permits, expiry equality denies. |
| T05 | Each permission works alone only for its own operations; read does not grant edit/audit/create and existing application read/approve/activate grants no A0 capability. |
| T06 | Correctly provisioned permitted create succeeds with real canonical UUID, Draft/unverified/unclaimed, selected children and exactly one audit/receipt. |
| T07 | Forged lifecycle/positive verification/claim/actor/owner/member/subscription/media/publication keys rejected P0DAT; no positive state or unauthorized side effect. |
| T08 | No membership/subscription/application/commercial_private/media row created or changed; counts and pre-existing records preserved. |
| T09 | Anon and ordinary authenticated direct/ID/nested Directory queries cannot read Draft parent/children; existing active public projection unchanged. |
| T10 | CREATE/UPDATE authoring allows exactly company/contractor/supplier/store; other five canonical codes and invalid codes return P0DAT invalid_staff_business_input. No excluded-type creation/conversion or entitlement inference. Canonical validator/read filters retain all nine; other-type existing entities remain readable. Type/name/description boundary coverage. |
| T11 | Arrays >10, null arrays, unknown/missing/wrong-kind keys, duplicate contacts/categories/primary flags, invalid formats, unknown/inactive refs rejected atomically. |
| T12 | Invalid/nil UUID, coordinate string/nonfinite/unpaired/out-of-range/precision-loss, empty location/address overflow/payload byte overflow rejected; no coercion. |
| T13 | Partial optional Draft content is permitted; clearing description/contacts/categories/primary location works without publication inference. |
| T14 | Direct INSERT/UPDATE/DELETE/TRUNCATE on protected tables/receipt and private helper EXECUTE/USAGE denied; permission-table reads/writes do not become client authority. |
| T15 | Eligible current Draft material update works; stale/null version rejected; exact returned token advances and child-only edit also invalidates it. |
| T16 | No-op validates permission/eligibility/version but writes no entity/children/audit and preserves timestamp/child IDs. |
| T17 | Active/inactive/suspended, owned, subscribed, non-unverified/non-unclaimed, legacy/application-created, current-type-outside-A0 or >10-child Draft update denied; no status/owner/finance resets. |
| T18 | Another entity's child ID/entity ID cannot be supplied. Normal eligible A primary upsert/clear leaves B/media untouched. Any non-primary A location makes the entire update P0TRA: no profile/primary/other-child/version/audit mutation, deletion/adoption or no-op bypass; preserve all additional location rows. |
| T19 | Audit exact action/actor/target/reason/request/typed counts/changed fields, no raw profile/PII/finance/payload hash values. |
| T20 | Test-only audit failure injection in isolated transaction: create/update wholly roll back, including receipt/version/children; no success response or retry. Restore fixture injection. |
| T21 | List/audit default25/min1/max50, invalid bounds/filter/cursor denial, literal wildcard search, same-time UUID tie order, empty/end/multi-page no overflow. |
| T22 | Detail arrays capped50 with truthful completeness; editable collections complete≤10; non-Draft reads truthful and read-only; inactive assigned labels preserved. Exact location_scope_complete is true iff no non-primary location exists; false still permits detail read but forces can_edit_draft=false. Mutation rechecks independently under entity lock, including after a concurrent sanctioned location change; DTO flag cannot authorize a write. |
| T23 | Audit scope excludes other entity/application/legacy raw events; only two typed A0 actions; corrupt matching event fails P0INV without raw or partial fallback. |
| T24 | Same actor/key/canonical payload returns original receipt with no second entity/audit; reordered arrays/keys and UUID case canonicalize; retained-value/reason change conflicts. |
| T25 | Replay after entity edit/separately authorized ownership/status change or taxonomy retirement returns historical receipt only; current permission loss denies; missing/corrupt original reference P0INV without repair. Receipt-protected entity remains unavailable to legacy CLAIM; no historical replay lifts the guard. |
| T26 | Two concurrent same-key creates: exactly one effect/audit; different payload same key conflicts; first transaction rollback lets a later new attempt create once, no abandoned reservation. |
| T27 | Two concurrent updates with same version: one material success, one P0CON. Same transaction/earlier-start version cannot silently retain/backdate token. |
| T28 | Wait across permission expiry/revocation or entity status/ownership change: fresh post-lock check denies; no late unauthorized effect. Characterize after-final-check in-flight revocation limit. |
| T29 | Shared taxonomy retirement waits under FOR SHARE; no deadlock cycle introduced with sanctioned current application→entity/member entity writer or hardened CLAIM guard. No A0 authoring application lock and no receipt row/reservation/advisory lock in guard. |
| T30 | Temp/public search_path shadow injection cannot alter tables/helpers/auth/CLAIM predicate; postgres owner and exact effective ACL/defaults, guard non-client EXECUTE and preserved trigger, private non-exposure/Realtime absence asserted. |
| T31 | Complete forward migration on accepted 00025 baseline; conflict/preflight/late-final-assertion failure leaves zero partial A0 objects/grants/data and restores original guard; prior migration bytes unchanged. Successful deployment cannot expose create without the hardened guard. |
| T32A | Direct CLAIM against A0 entity rejected: ordinary direct table DML remains ACL-denied; trusted isolated-fixture INSERT with normal trigger enabled must hit P0CLM, proving guard enforcement independently of RPC/UI/caller discipline. |
| T32B | Ordinary authenticated create_claim_business_application(A0_entity_id), using its existing EXECUTE grant and knowing UUID, rejected server-side P0CLM. Repeat and business OWNER/staff callers do not bypass receipt predicate. |
| T32C | Failed CLAIM creates zero business_applications rows; no activation/ownership/receipt/create-audit change and no successful CLAIM effect. Check transactional state, not just returned error. |
| T32D | Protected A0 entity remains draft/unverified/unclaimed with zero business_memberships and subscriptions; public non-readability unchanged. No fake claimed/verification/member state. |
| T32E | Non-A0 valid legacy CLAIM unchanged, including unclaimed legacy private Draft; pending/claimed P0CLM, missing non-null target 23503, raw null CHECK 23514, RPC null P0DAT, duplicate live claim 23505 and historical rows/index/FK preserved. |
| T32F | Existing NEW application creation/activation unchanged, including original nine-code metadata validity: canonical new entity/OWNER linkage/claim behavior/audit, with no automatic subscription/publication. No application function replacement beyond the canonical insert guard. |
| T32G | Real independent-session race: know creator's generated UUID while create transaction is uncommitted; CLAIM before visibility fails with 23503 immediately, after create commit/target-lock wait sees receipt and fails with P0CLM. No empty-lock→late-FK admission window; creator rollback leaves neither entity/receipt/CLAIM. Probe stricter isolation as fail-closed, no partial success. |
| T32H | A0 receipt denial and ordinary unavailable pending/claimed denial have identical P0CLM/message and no private DETAIL/HINT/provenance fields. Compare actual SQL and HTTP payloads; no special A0 error/creator/receipt leak. |
| T33 | Composed guard negative probes reject unauthorized 00027/renamed 00026, historical migration edit, lib/governance weakening and attempted deletion/bypass of receipt predicate, early absent-target rejection, row lock, private ACL or four-type/location guards. Preserved predecessor gates green. |
| T34 | Genuine authenticated local HTTP/RPC: staff success, ordinary-user denial for A0 staff RPCs, ordinary legacy CLAIM denial for A0 target, anon denial, Draft public non-readability. SQL SET LOCAL role alone is not HTTP evidence. |

Use focused regressions: `test/a6_2_business_application_test.dart`, `test/a6_3_1_business_application_creation_authorization_test.dart`, `test/a6_4_business_application_activation_test.dart`, `test/v1_r03_business_ownership_management_test.dart`, `test/v1_r06_profile_management_server_test.dart`, `test/v1_r06_business_profile_management_test.dart`, `test/v1_r07_staff_operations_server_test.dart`, `test/v1_r07_staff_gateway_production_test.dart`, `test/v1_r05_directory_cloud_integration_test.dart`; all four composed commercial guards. CLAIM regressions remain read-only and run against preserved historical migration sources, with new A0 SQL/runtime tests proving the deployed guard's sole bounded difference. Run affected processes sequentially where NativeAssets/build collisions occur. Disposable predecessor SQL gates for M1a/HARDEN-1/M1b/M3 require scope-aware execution retaining historical prefix inventory before applying A0, plus post-A0 preservation assertions; do not alter their frozen SQL to accept new authority. No full repository suite without a separately authorized integrated gate. No SDK/global package patch, baseline dirty test edit or historical evidence counted as a new PASS.

## 21. Future CUI-2A1 consumption surface

Candidate future routes `/staff/businesses`, `/staff/businesses/new`, `/staff/businesses/:entityId` require a separate A1 contract/authorization. Proposed experience: Commercial Admin → Businesses → Drafts → Add Business Draft → Draft editor → scoped audit. Sections: Identity, Classification, Description, Contacts, Primary Location only. No media, ownership/invitations, verification, publication, subscription/plan, Sponsored, Branches or team controls. Existing Arabic product/localization/design system governs A1; Location / الموقع is distinct from Branch / فرع.

A1 may consume only the six RPCs/DTOs above plus existing read-only active category/region selectors (`directory_categories` and `regions`) already permitted by existing RLS. Authoring type options are exactly the four §4 A0 codes; read filters may show all nine canonical types. No new taxonomy endpoint/table grant or raw entity/membership/audit query. Show only supported capabilities; each mutation still server-authorized. Non-Draft/ineligible or incomplete detail, including location_scope_complete=false, is read-only. Do not infer ownership from claim/origin/can_edit or manufacture an entitlement/publication-ready badge; never use that DTO boolean as a mutation authority token.

Future A1 requirements: strict finite DTO/status parsing; account/session generation-scoped private state; clear on sign-out/account change/permission denial; no reuse of public Directory offline cache for private drafts; exact timestamp round-trip; retain create key and canonical submission for explicit outcome reconciliation; no blind automatic mutation retry. Read errors must not re-enable revoked private actions. A0 changes none of the current gateways/providers/routes to establish these future behaviors. If Flutter evidence becomes necessary in A0, STOP for a separately bounded addition; no speculative production gateway scaffold.

## 22. Production-readiness gate, acceptance and rollback boundary

Repository acceptance is not deployed readiness. Before the Document Owner uses a later live Admin Console, require explicit production-readiness authorization and evidence of:

1. Exact deployed 00026 source/version/checksum and accepted prerequisite chain; no drift/conflicting object. Verified postgres ownership, fixed search_path, exact six RPC/two-helper inventory plus canonical CLAIM guard replacement/preserved trigger, actual effective EXECUTE and schema/table/default ACLs.
2. Receipt RLS/default-deny/private API and Realtime non-exposure; original entity/child/public RLS, staff/membership/application/audit authority preserved; no financial/catalog exposure or direct client DML.
3. Explicit trusted staff provisioning for real intended accounts and narrowly selected capabilities, with expiry/revocation checked. No role-name assumption or automatic reviewer grant.
4. Genuine HTTP/RPC smoke using ordinary authenticated and provisioned staff sessions, successful staff create/edit/audit with correct receipts, ordinary/anon denial, and public ID/nested queries unable to see the resulting Draft/children. Fixture/live-data creation and cleanup need that later gate's exact authorized boundary.
5. Proven server-side A0 CLAIM isolation (T32A–H), including general privacy-safe denial through genuine ordinary authenticated legacy CLAIM HTTP; no unresolved A0-specific safety disposition. Sanctioned-writer/lock compatibility, four-type authoring bounds and truthful location completeness/ineligible update denial; exact create replay and optimistic conflict behavior; audit-failure/concurrency rollback evidence from the isolated test environment, not destructive fault injection in production.
6. Accepted A1 strict parsing/session clearing/error handling and approved real-data operation; authorized information intake under §32.5.2. No Owner access before gate completion.

No live deployment, staff provisioning, credentials collection or HTTP call occurs in drafting/correction. Later rollback normally disables new endpoint EXECUTE/use and A1 entry points under explicit authority, retains referenced Draft/audit/receipt records and the hardened canonical CLAIM guard, and preserves non-A0 behavior. Do not revert/remove the receipt predicate while retained A0 entities exist, or delete protecting receipts to reopen CLAIM. No default destructive down migration, record deletion, ownership reset or old-permission weakening. Migration failure rolls back atomically before A0 creation is enabled; post-use removal requires a separate data-retention/compatibility decision preserving isolation.

## 23. OPEN questions and STOP rules

| ID | OPEN / carried issue | Gate / owner |
| --- | --- | --- |
| A0-OPEN-01 (historical acceptance prerequisite — satisfied) | Architect acceptance of this exact technical specification has been supplied and recorded in §26, including global staff read scope, A0-origin-only editing, separate private receipt and timestamp-advancement rejection. | ACCEPTED / FROZEN — 2026-10-07. This contract-acceptance prerequisite is complete; implementation remains NOT AUTHORIZED and other gates remain unchanged. |
| A0-OPEN-02 | Actual staff accounts/roles/grants/effective windows and accountable trusted provisioning procedure. | Before live operation; Document Owner/authorized administrator; no migration assignment. |
| A0-OPEN-04 | Exact later committed governance authorization record/commit and independent reviewer/runtime environment. | Before implementation; Owner + Architect. Cannot invent future hashes or green results. |
| A0-OPEN-05 | Source-observed HARDEN-1 expectation predates the committed CUI-1 final closure; exact composed documentary/static correction and fresh focused GREEN baseline. | Before new A0 SQL work; separate explicit Architect authorization/review within the four proposed guard paths. No repair/test run during drafting. |
| Policy OQ-40 / OQ-82 | Receipt/audit retention/deletion and never-owned Draft disposition/re-attachment; no TTL, cleanup, different-business reassignment or publication rule inferred. | Governing policy/legal review and future ownership/onboarding contracts. |
| Policy OQ-72 | Genuine-entity duplicate detection, merge/retirement; request uniqueness does not decide it. | Separate deduplication authority. |
| Policy OQ-77 / OQ-83 / OQ-79 | Broader Business Center/RBAC, invitation expiry/decline/redirection, ownership/dispute/evidence. | CUI-2C1 and applicable policy/legal decisions. |
| Policy OQ-76 / OQ-48 / OQ-49 and verification residuals | Required Fields/publication gate, post-publication deficiency, approval/moderation authority and full commercial Verified model. | CUI-2C2/publication/verification; excluded A0. |
| Other existing OPENs / M4 / pre-M5 | All other registered OQs, classification/linking, integer-IQD conversion, generation reconciliation, OQ-84 and publication cutover retain existing status. | Their governing later contracts; none closed/narrowed/reclassified here. |

Former A0-OPEN-03 is removed as an unresolved live-safety prerequisite: the supplied Architect correction replaces it with mandatory §18 A0 CLAIM protection. CF-CLAIM-01 is closed at contract-requirement level, with implementation/tests still pending; broader non-A0 public CLAIM policy reconciliation remains separate and is not promoted by A0. This technical correction closes/reclassifies no Frozen Commercial Model OQ or broader C1 AR-03 policy issue.

No technical signature/input/DTO/error/validation/locking/replay/audit/object/file boundary is left to an unspecified "manage" or "validate as needed" operation. Material changes to this proposal require a reviewed draft revision/addendum. Evidence insufficient for a claim stays OPEN; governance acceptance is not supplied by implementation convenience.

Future implementation must STOP if it requires a second canonical Business table/owner column; M4/M5; classification/backfill/IQD conversion; publication/active editing; subscription/payment/entitlement consumption; owner invitation/direct assignment/membership mutation/new role mapping; media/Storage; Branch domain; verification grant/withdrawal; broad admin bypass/client self-grant; service-role Flutter secret; global auth/Supabase duplication; application changes beyond the exact §18 guard or any legacy profile patch; additional endpoint/helper/file/compatibility guard beyond the exact inventory; occupied00026; unreviewed privilege drift; or automatic mutation retry. If the canonical CLAIM guard cannot meet §18 safely without broader application architecture changes, report BLOCKED — ARCHITECT REVIEW REQUIRED. Do not weaken a test/security gate to continue. Obtain exact additional authority before dependent implementation.

## 24. Drafting scope and preservation record

The initial drafting pass created this contract. The current Architect correction pass modifies only this same untracked contract document; no other file is created/edited. Roadmap unchanged: CUI-1 CLOSED, commercial CURRENT NONE, implementation NO, M3 CLOSED, M4/M5 NOT AUTHORIZED; R10.5-D audit-only. Existing contracts/addenda/closure/policy, lib/test/supabase/dependencies and protected dirty files are outside the current write boundary.

Protected original draft entry status (unchanged through correction; the contract itself is additionally untracked at correction entry):

```text
 M test/a5_6_profile_bootstrap_test.dart
 M test/v1_r08_cloud_profile_foundation_test.dart
 M test/v1_r08_profile_edit_screen_widget_test.dart
?? OpenCode_Usage_Report.txt
?? artifacts/r10_4a/home_dark.png
?? artifacts/r10_4a/home_light.png
```

Draft validation: compare entry/end file hashes, verify local reference links, exact metadata/six RPCs/four codes/proposed migration absence, untracked Markdown whitespace, `git diff --check`, exact porcelain status, empty staged list, and unchanged HEAD/local origin/main. Actual results belong in the final report; this expected boundary is not itself a PASS, independent review or Architect acceptance. No production implementation, SQL migration, Supabase change, test execution/edit, stage/commit/push/reset/revert/clean/stash is authorized by this draft. The User retains Git ownership.

## 25. Architect correction record — 2026-10-07

Historical record: Owner-provided **CIVILPEDIA — CUI-2A0 ARCHITECT CONTRACT CORRECTION PASS**. Before final acceptance, the draft underwent a correction cycle requiring additional Architect review. That cycle is now complete; Architect contract acceptance and freeze have been supplied and recorded in §26. This records prior correction history, not implementation or agent self-acceptance.

The initial draft's all-nine authoring scope is superseded by four authoring types (§4); its A0 Draft CLAIM exposure/deferred operating-posture alternative is superseded by mandatory canonical guard replacement/receipt denial and explicit absent-target race closure (§18); its partial location-edit posture is superseded by location_scope_complete and whole-edit denial with any non-primary row (§§3/8/9). Corresponding DTO/object/test/readiness/rollback/OPEN/STOP clauses are corrected. A0-OPEN-03 is removed as a live-safety choice; broader legacy CLAIM policy remains separate. These are the supplied bounded corrections and their necessary consistency updates, not broader commercial decisions.

Canonical entity, no owner_id, four permissions, six A0 client RPC signatures, private receipt/schema, actor/request create replay, expected-version update, permission-before-lock/post-wait recheck, sanitized transactional audit and all M4/M5/payment/entitlement/publication/media/invitation/active-edit/Flutter exclusions remain preserved. HARDEN-1/static compatibility requires a separate explicitly authorized pass and fresh focused GREEN baseline before A0 SQL implementation; it is neither repaired nor tested here. No implementation/test/migration/Supabase/roadmap change, staging, commit or push. Actual integrity results are reported separately after validation.

**The earlier correction cycle is complete. Current control is the ACCEPTED / FROZEN contract and §26 acceptance record; IMPLEMENTATION_AUTHORIZED remains NO.**

## 26. Architect acceptance and contract freeze — 2026-10-07

Authority: Owner-provided **CIVILPEDIA — COMMERCIAL CUI-2A0 ARCHITECT CONTRACT ACCEPTANCE + FREEZE RECORD**. The Architect has completed review of the corrected contract and supplied the decision **ACCEPTED**. This record persists that decision; it is not agent self-acceptance, a new independent review, implementation acceptance or deployed readiness evidence.

**DOCUMENT_STATUS: ACCEPTED — CANONICAL CUI-2A0 IMPLEMENTATION CONTRACT. ARCHITECT_ACCEPTANCE: ACCEPTED — 2026-10-07. FREEZE_STATE: FROZEN.** The corrected technical specification is now the canonical frozen CUI-2A0 implementation contract. The header and this record supersede earlier draft and correction-cycle status wording, including the historical correction record and A0-OPEN-01's former acceptance prerequisite. That acceptance prerequisite is satisfied only for contract acceptance; every technical clause and historical record remains preserved unchanged. No Frozen Commercial Model OQ or broader legacy CLAIM governance issue is closed or reclassified.

The accepted technical scope remains byte-for-byte intact: canonical directory_entities identity without owner_id/second identity; ownerless non-public Drafts; four granular staff permissions; six A0 client RPCs; private create receipt/idempotency; optimistic concurrency, permission-before-lock/post-wait recheck and transactional sanitized audit; four authoring types; readable other Directory types; zero/one primary Location with non-primary presence making A0 read-only/P0TRA; canonical database CLAIM isolation for A0 targets with non-A0 CLAIM and NEW behavior preserved. This freezes implementation requirements, not a claim that the current database implements them. All publication, active-entity editing, ownership/invitation, media, M4/M5, payment/subscription/entitlement and Flutter-implementation exclusions remain unchanged.

**IMPLEMENTATION_AUTHORIZED: NO. CUI2A0_STATE: CONTRACT FROZEN — IMPLEMENTATION NOT YET AUTHORIZED. COMMERCIAL_CURRENT_SLICE: NONE. COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO.** CUI-1 and M3 remain CLOSED; M4/M5 remain NOT AUTHORIZED; R10.5-D remains AUDIT-ONLY / IMPLEMENTATION NO. CUI-2A0 is a frozen candidate, not an active implementation slice. No 00026 authorization, implementation commit placeholder, SQL/migration, lib/test/supabase change, staff provisioning or deployment is created by acceptance.

Implementation authorization remains blocked on both existing prerequisites: **(A)** narrow reconciliation of stale commercial static expectations with the already committed CUI-1 final closure, in a separate explicitly authorized compatibility pass; **(B)** a fresh focused commercial static baseline GREEN. Neither dependency is resolved or tested in this freeze pass; no static guard is edited. A subsequent explicit implementation authorization remains required after those gates, in addition to the contract freeze. Production readiness remains separately governed by §22.

This governance pass changes only contract metadata/status and this acceptance record, plus an append-only acceptance/freeze record in the Master Roadmap. Staging, commit and push remain User-controlled and are not performed or authorized here. Current final state: **ACCEPTED / FROZEN — IMPLEMENTATION NOT AUTHORIZED**.
