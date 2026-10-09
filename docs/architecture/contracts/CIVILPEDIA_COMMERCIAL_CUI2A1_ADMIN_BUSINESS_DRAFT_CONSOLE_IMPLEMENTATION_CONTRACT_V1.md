# Civilpedia — CUI-2A1 Admin Business Draft Console Implementation Contract V1

## 1. Status and authority

```text
DOCUMENT_STATUS: ACCEPTED — CANONICAL CUI-2A1 IMPLEMENTATION CONTRACT
ARCHITECT_ACCEPTANCE: ACCEPTED — 2026-10-08
FREEZE_STATE: FROZEN
IMPLEMENTATION_AUTHORIZED: NO
CUI2A1_STATE: CONTRACT FROZEN — IMPLEMENTATION NOT AUTHORIZED
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
CUI2A0_STATE: CLOSED
CUI1_STATE: CLOSED
M3_STATE: CLOSED
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO
DOCUMENT_VERSION: 1
DRAFT_DATE: 2026-10-08
ARCHITECT_CORRECTION_DATE: 2026-10-08
MODE: STRICT GOVERNANCE-ONLY ACCEPTANCE / FREEZE — NO IMPLEMENTATION
PROPOSED_SLICE: CUI-2A1 — Admin Business Draft Console
BACKEND_AUTHORITY_DELTA: ZERO
PUBLICATION_AUTHORITY_DELTA: ZERO
ENTITLEMENT_AUTHORITY_DELTA: ZERO
PAYMENT_AUTHORITY_DELTA: ZERO
REMOTE_DEPLOYED_DATABASE: UNVERIFIED
GIT_OWNER: User
```

The initial Owner-supplied drafting/correction requests authorized creation and correction of this document. Authority for the current pass is the Owner-supplied **CUI-2A1 Final Architect Acceptance + Contract Freeze**, supplying **ACCEPTED — 2026-10-08** and final independent pre-freeze review **PASS, with zero CRITICAL/HIGH/MEDIUM findings**. This pass records formal acceptance/freeze in this contract and one append-only roadmap section; it grants no implementation, static guard modification, provisioning or deployment authority. Current control is the ACCEPTED / FROZEN contract and §23 acceptance record. COMMERCIAL_CURRENT_SLICE remains NONE and COMMERCIAL_IMPLEMENTATION_AUTHORIZED remains NO; no new slice is activated. Earlier draft/candidate/correction status statements are historical where superseded by §23.

The [Agent Operating Model](../CIVILPEDIA_AGENT_OPERATING_MODEL.md) governs routing and escalation. The [Master Roadmap](../CIVILPEDIA_V1_MASTER_ROADMAP.md) is the phase/status SSOT; its appended CUI-2A1 acceptance/freeze record retains no-current-slice/no-implementation control and all prior closures. The [Commercial Model V1](../CIVILPEDIA_COMMERCIAL_MODEL_V1.md), current §33, remains frozen policy. The [A0 frozen contract](CIVILPEDIA_COMMERCIAL_CUI2A0_ADMIN_BUSINESS_DRAFT_AUTHORITY_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md), [ACL Security Addendum](CIVILPEDIA_COMMERCIAL_CUI2A0_APPEND_AUDIT_LOG_ACL_SECURITY_ADDENDUM_V1.md) and [A0 closure](../reports/CIVILPEDIA_COMMERCIAL_CUI2A0_ADMIN_BUSINESS_DRAFT_AUTHORITY_FOUNDATION_CLOSURE.md) govern accepted backend behavior. Preserve the [CUI-1 closure](../reports/CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_CLOSURE.md) and its original contract/media addendum. No other contract/report or prior roadmap byte is changed here.

## 2. Dependency and baseline evidence

Entry evidence, obtained locally without fetch or database contact:

| Evidence | Observed baseline |
| --- | --- |
| Repository | `D:\Civilpedia` |
| HEAD and local origin/main | Both `3f4ce87381ea97b0f3f6a772827c4d77b58aee66` |
| Index | Empty |
| Accepted A0 implementation | `41276132ba6a1606cd779f5ce92473bacfbcc7c8`, as recorded in the committed closure |
| Post-A0 static compatibility | Accepted and committed at the entry HEAD above; no fresh test PASS is asserted |
| Roadmap | CUI-2A0 CLOSED; commercial CURRENT NONE; implementation NO; CUI-1/M3 CLOSED |
| Backend consumer source | `supabase/migrations/00026_commercial_admin_business_draft_foundation.sql` |
| Migration inventory | 26 existing migrations; no new migration proposed |
| Deployed database | UNVERIFIED |

The governing documents are clean tracked files at this baseline and were inspected with committed/source evidence. Relevant Flutter evidence includes `lib/main.dart`, `lib/core/di/app_dependencies.dart`, `lib/core/di/staff_operations_scope.dart`, `lib/routes/app_routes.dart`, `lib/routes/app_router.dart`, `lib/features/auth/domain/auth_return_destination.dart`, the existing AuthProvider, staff providers/gateways, business profile gateway, User Area, canonical Directory types, shared remote-operation policy and V1 design primitives. Existing staff application and business membership authority are separate from A0.

Protected entry state:

```text
 M test/a5_6_profile_bootstrap_test.dart
 M test/v1_r08_cloud_profile_foundation_test.dart
 M test/v1_r08_profile_edit_screen_widget_test.dart
?? OpenCode_Usage_Report.txt
?? artifacts/r10_4a/home_dark.png
?? artifacts/r10_4a/home_light.png
```

Preserve all protected files and all other entry bytes outside the two authorized governance paths. No reset, revert, clean, stash, staging, commit or push. This acceptance/freeze pass runs documentary/Git validation only; historical local SQL/HTTP/static results remain supplied accepted evidence, not new execution. The supplied final independent contract-review PASS is recorded in §23; no implementation tests or freeze-composition GREEN are asserted.

Historical drafting/correction evidence: the initial request supplied the completed audit's counts and the correction request supplied its exact production/test candidates. §§14–15 retain the original-versus-revised reconciliation and source-supported rationale. The 18 production, six new test, five modified UI-test and four compatibility paths are now frozen under §23; original audit alternatives remain evidence only. Read-only `git show --stat HEAD` confirms that accepted post-A0 compatibility at the entry commit changed exactly A0, HARDEN-1, M1b and M3; M1a was not part of that four-file change. §16 retains the unchanged separate future compatibility authorization/GREEN prerequisite inside this four-file boundary.

## 3. Explicit scope and exclusions

The future console consumes accepted A0 to list/search/filter permitted canonical Drafts, create non-public ownerless Drafts, inspect detail, edit eligible A0 Drafts, and read permission-scoped A0 authoring history. Canonical identity is `directory_entities.id`; no owner field, second Business identity, creator-derived management right or membership shortcut.

Scope is one bounded list screen, one shared create/detail/editor screen, an embedded history section, and one capability-driven Commercial Admin navigation tile in User Area. The tile is the Owner-supplied narrow navigation-only exception to R10.5-D; it does not authorize a Profile/User Area presentation redesign or unlock R10.5-E.

Explicitly excluded: M4/M5; payment, subscriptions, pricing and commercial catalog consumption; publication/activation or active-entity editing; entitlement/commercial-readiness evaluation; ownership linking, invitations and direct assignment; verification/moderation; media upload, Storage and media administration; Branches/team management; suspension/closure; taxonomy administration; public Claim; public Directory authority/ranking changes; backend migrations/new RPCs; unauthorized staff provisioning. No application workflow change, global theme/refactor, new dependency, SDK/cache/package-source patch, public-cache fallback, broad audit reader, offline private persistence, batch mutation or export.

Creation/editing accepts only `company`, `contractor`, `supplier`, `store`. Read filters can use the nine existing Directory types. Legacy/non-A0 Drafts and non-Drafts can be read under A0 permission but remain ineligible for editing unless the current server detail explicitly establishes eligibility. Reading a Draft never adopts it.

## 4. Exact RPC, payload, DTO and error contracts

### 4.1 Six existing public RPCs

These are JSONB-returning public-schema functions from committed 00026. Named arguments are exact, with no actor, role, tenant, owner or capability argument. Widgets call domain/provider methods only.

```sql
get_staff_business_capabilities() -> jsonb

list_staff_business_entities(
  p_search text DEFAULT NULL,
  p_entity_type text DEFAULT NULL,
  p_lifecycle_status text DEFAULT NULL,
  p_limit integer DEFAULT 25,
  p_before_created_at timestamptz DEFAULT NULL,
  p_before_id uuid DEFAULT NULL
) -> jsonb

get_staff_business_entity_detail(p_entity_id uuid) -> jsonb

staff_create_business_draft(
  p_request_id uuid,
  p_payload jsonb,
  p_reason text
) -> jsonb

staff_update_business_draft(
  p_entity_id uuid,
  p_expected_updated_at timestamptz,
  p_request_id uuid,
  p_payload jsonb,
  p_reason text
) -> jsonb

list_staff_business_entity_audit(
  p_entity_id uuid,
  p_limit integer DEFAULT 25,
  p_before_created_at timestamptz DEFAULT NULL,
  p_before_id uuid DEFAULT NULL
) -> jsonb
```

| RPC | Exact client parameter keys | Independent authority / response |
| --- | --- | --- |
| capabilities | Empty parameter map / no arguments | Authenticated discovery; `{"capabilities": [...]}` |
| list | `p_search`, `p_entity_type`, `p_lifecycle_status`, `p_limit`, `p_before_created_at`, `p_before_id` | `business_entities.read`; list page |
| detail | `p_entity_id` | `business_entities.read`; detail DTO |
| create | `p_request_id`, `p_payload`, `p_reason` | `business_entities.create_draft`; create receipt |
| update | `p_entity_id`, `p_expected_updated_at`, `p_request_id`, `p_payload`, `p_reason` | `business_entities.edit_draft`; update receipt |
| audit | `p_entity_id`, `p_limit`, `p_before_created_at`, `p_before_id` | `business_entities.read_audit`; audit page |

Explicit client list calls send `p_lifecycle_status = 'draft'`, `p_limit = 25`; initial cursor pair is null. Do not rely on list's backend lifecycle default, which is NULL/all states. The proposed list UI retains Draft-only lifecycle filtering, with optional type/name filters; detail deep links can display other states read-only. History sends 25 and its own cursor. No seventh RPC is added.

### 4.2 Exact full replacement payload

Create and update require all **six** top-level keys, exactly; missing, unknown or wrong-kind keys fail server validation. JSON null is distinct from omission. Empty arrays explicitly clear the corresponding authored collection.

```text
{
  entity_type: string,
  name: string,
  description: string | null,
  contacts: [{contact_type: string, value: string, is_primary: boolean}],
  categories: [{category_id: UUID-string, is_primary: boolean}],
  primary_location: null | {
    region_id: UUID-string | null,
    address: string | null,
    latitude: number | null,
    longitude: number | null
  }
}
```

Each contact/category/location object has exactly the displayed keys, including all four nullable location keys. Never submit child IDs, entity ID, status, timestamps, origin, is_active, location is_primary, audit fields or ownership information inside p_payload. A0 assigns child identity and primary-location status.

| Field | Server validation to preserve; client feedback must be compatible |
| --- | --- |
| Full JSONB | Maximum 65,536 UTF-8 bytes of PostgreSQL JSONB text before normalization; client serialization size is only advisory |
| entity_type | Exact canonical code and exact four-type authoring allowlist; no alias/case coercion |
| name | PostgreSQL btrim; 1–160 characters, case/language preserved |
| description | Null/string; btrim; blank becomes NULL; at most 2,000 characters |
| contacts | 0–10; allowed codes phone/whatsapp/email/website/other; type lower+btrim, value btrim; nonempty; duplicate normalized type+lower(value) rejected; at most one primary per type |
| phone/whatsapp | At most 32 characters; `^[0-9+(). /-]+$`; at least three ASCII digits |
| email | At most 254; case-insensitive `^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$` |
| website | At most 2,048; case-insensitive `^https?://[^[:space:]]+$` |
| other contact | At most 500 |
| categories | 0–10 unique non-nil canonical UUIDs; at most one primary; every reference active for a new/material effect |
| primary_location | Null or zero/one bounded primary; at least region, nonblank address or paired coordinates present |
| region/address | Referenced region active for a new/material effect; address btrim/blank→NULL, at most 500 |
| coordinates | Both null or both JSON numbers; finite; latitude −90…90, longitude −180…180; exactly representable at six decimal places; reject precision loss |

UUID input is ordinary hyphenated UUID text, non-nil; JSON booleans/numbers are not strings. Accept decimal input explicitly and locale-safely, including Arabic digits where supported by the form, then validate before producing JSON numbers. Never silently round or coerce invalid input. Client checks improve feedback; canonical SQL remains the authority. Dart Unicode/whitespace and byte counting must not be represented as an exact replacement for PostgreSQL validation.

Read-only selector queries are the A0 §21 exception already permitted by existing RLS, through the new gateway:

```text
directory_categories:
  select id, parent_category_id, code, name_ar, name_en, is_active
  where is_active = true
regions:
  select id, parent_id, code, region_type, name_ar, name_en, is_active
  where is_active = true
```

They assign existing references only, use typed identity/nullable label DTOs and finite known region types, and never write taxonomy. Physical regions are distinct from user region_preferences. Existing inactive assignments come from detail and must remain visible even though absent from active option lists. No direct private/business table read accompanies these public taxonomy reads.

### 4.3 Capability/list/detail projections

```text
Capabilities:
{capabilities: [permission-code, ...]}

List page:
{
  items: [{entity_id, name, entity_type, lifecycle_status,
           verification_status, claim_status, created_at, updated_at}],
  next_cursor: null | {created_at, id}
}

Detail:
{
  entity: {entity_id, entity_type, name, description,
           lifecycle_status, verification_status, claim_status,
           created_at, updated_at},
  contacts: [{id, contact_type, value, is_primary}],
  categories: [{category_id, code, name_ar, name_en, is_active, is_primary}],
  primary_location: null | {
    id, region_id, region_code, region_name_ar, region_name_en,
    region_is_active, address, latitude, longitude, is_primary
  },
  contacts_complete: boolean,
  categories_complete: boolean,
  location_scope_complete: boolean,
  draft_authoring: {origin: "CUI2A0" | "UNESTABLISHED", can_edit_draft: boolean}
}
```

UUIDs/timestamps are strings. List's eight fields are required and non-null. Detail entity description is nullable; other entity fields match list. Contact fields are required: id UUID, type/value strings, primary boolean. Category ID/code and flags are required; name_ar/name_en are nullable strings. Primary-location id is required, is_primary is true; region UUID and joined region labels/code/activity can be null when no region is attached; address/coordinates can be null. Coordinates are finite numbers, preserving six-place precision; do not use displayed rounding for subsequent saves. Contacts/categories detail truncates at 50 each using a 51st-row completeness probe. Client must not truncate again into a replacement payload.

Finite state vocabularies: lifecycle `draft / active / inactive / suspended`; verification `unverified / pending / verified / rejected / suspended`; claim `unclaimed / pending / claimed`; origin exactly the two displayed codes. Read entity types: `company / engineering_office / contractor / supplier / store / technician / laboratory / equipment_provider / service_provider`. Contact codes are the five above. Unknown states/types do not become draft/editable by a default enum value.

Capabilities are distinct members of the four-code vocabulary in A0's read/create/edit/audit order; an ordinary authenticated user's valid empty array means no capability. Reject malformed/unknown capability data rather than grant access. The server detail hint can_edit_draft is present eligibility plus edit permission, not a transferable authority token. location_scope_complete=false denotes unsupported non-primary locations; the projection does not reveal or authorize adoption of them.

### 4.4 Exact mutation receipts and reason vocabulary

```text
Create:
{outcome: "CREATED" | "REPLAY", request_id, entity_id,
 created_at, created_updated_at}

Update:
{outcome: "UPDATED" | "UNCHANGED", request_id, entity_id, updated_at}
```

All receipt IDs/timestamps are required strings and must correlate with the submitted request/entity where applicable. Create timestamps are original immutable creation evidence and equal at creation; they are not the current edit version after replay. UPDATED advances the expected timestamp strictly; UNCHANGED preserves it. A malformed/mismatched mutation receipt after dispatch is an uncertain outcome, never fabricated success or permission to retry as a new operation.

| Operation | Exact p_reason codes |
| --- | --- |
| Create | `BUSINESS_SUPPLIED_INFORMATION`, `BUSINESS_AUTHORIZED_PREPARATION` |
| Update | `CORRECT_DRAFT_INFORMATION`, `COMPLETE_DRAFT_INFORMATION` |

The form requires a localized selection of these exact codes. No free-form reason/evidence/consent notes. A selected code records the operator context; it does not establish verified consent, ownership or publication rights.

### 4.5 Audit DTO and cursor

```text
{
  items: [{
    audit_id, actor_user_id, action, created_at, reason_code, request_id,
    change_summary: {
      changed_fields, before_updated_at, after_updated_at,
      before_contact_count, after_contact_count,
      before_category_count, after_category_count,
      before_has_primary_location, after_has_primary_location
    }
  }],
  next_cursor: null | {created_at, id}
}
```

audit_id/request_id are non-nil UUID strings; actor_user_id is UUID string/null because deleted actors can be SET NULL. No actor-name/email lookup. action is exactly `business_entity.draft_create` or `business_entity.draft_update`. reason_code matches that action's vocabulary. created_at/after_updated_at are finite timestamp strings. changed_fields is a nonempty unique ordered subset of `entity_type, name, description, contacts, categories, primary_location`; create contains all six in that order. Before timestamp/counts/location boolean are null for create and typed for update. After counts are integers 0–10, after location is boolean; update before counts are 0–10 and after timestamp exceeds before. The server validates `cui2a0.audit.v1` internally; format_version, target_type, target_id, before_data/after_data and receipt/fingerprint are **not** returned fields.

Both paginated RPCs use order `(created_at DESC, id DESC)` and exclusive before comparison. Backend p_limit accepts 1–50; console uses 25. A cursor is null or exactly a finite created_at string and non-nil id UUID string, with both parameters present or both null. List cursor id refers to the last returned entity_id; history cursor id refers to the last returned audit_id, and appears only when an extra row exists. Keep cursor timestamp precision intact. No offset, page number, total count or exhaustive cross-request snapshot guarantee. Empty items/null cursor is valid success.

### 4.6 Strict parsing and transport outcomes

Decode the returned JSONB object as the documented object shape, with exact projection allowlists, required keys, explicit nullability, typed nested arrays and finite values. No permissive SELECT-* model or guessed field. If a real transport requires an envelope adapter, demonstrate it in focused tests and keep the adapter bounded to one documented response; never unwrap arbitrary lists until something parses. Fail a malformed page atomically; never partially accept it as a complete detail or infer eligibility from it. Do not expose unknown extra fields. Validate target/request correlation, page size/cursor consistency and status vocabularies before publishing state. Preserve raw timestamp tokens for round-trip; parsed DateTime is for display/comparison, never a millisecond-truncated replacement.

| SQLSTATE | Exact server message | Typed UI behavior |
| --- | --- | --- |
| P0AUT | unauthenticated | Clear private console state; use existing auth/recovery gate |
| P0PER | staff_business_permission_denied | Revoke observed action, clear all private console state, refresh capabilities explicitly |
| P0DAT | invalid_staff_business_input | Localized bounded validation failure; keep authorized inputs; no raw value/SQL |
| P0NOT | entity_not_found | Authorized target unavailable; clear that target and editor/history |
| P0TRA | draft_not_editable | Stop editing; reread with read permission; no repair/adoption |
| P0CON | stale_draft_version | Explicit conflict/reload/reconciliation; no overwrite/retry loop |
| P0RPL | draft_create_request_conflict | Stop replay; retain immutable intent; explain request conflict; no new key as recovery |
| P0INV | draft_authority_invariant_conflict | Fail closed; no partial/raw fallback, repair or mutation retry |
| P0AUD | draft_audit_write_failed | Received authoritative failed transaction; no success; no automatic retry |
| P0CTX | unsupported_draft_transaction_context | Controlled unavailable mutation state; no isolation/backend change |
| 42501 / HTTP auth restriction | ACL/authorization before RPC entry | No promise of P0AUT; deny/clear private data and require capability revalidation |
| 40001 / 40P01 / timeout/cancel/unexpected | Other DB/transport failure | Bounded failure; dispatched mutation reconciled if commit outcome unproven |

Authentication/permission checks precede target lookup, and mutations recheck permission after waits. A0's accepted audit wrapper may report 40001/40P01 as P0AUD while rolling back; consume that actual classification without reopening A0. Invalid PostgreSQL arguments rejected before function entry may produce transport SQLSTATEs rather than P0DAT. Missing-function/API availability failures never trigger direct-table fallback or new backend scaffolding.

Use existing RemoteOperationPolicy: read 15 seconds, mutation 20 seconds, with injected shorter deadlines only for tests. A deadline bounds waiting and does not cancel the underlying request or prove rollback. Service unavailable/pre-dispatch validation is distinguishable from dispatched/unknown result. Unexpected errors, offline/network failures, malformed responses and raw PostgREST text stay inside the gateway; UI receives typed safe outcomes. No payload, contact/address, JWT, private DTO or actor data in logs, analytics, crash attachments or exception text.

### 4.7 Creation replay and update concurrency

Create reserves `(auth.uid(), p_request_id)` privately and fingerprints normalized payload+reason under `cui2a0.create.v1`. Canonicalization includes normalized UUIDs/nulls/six-place coordinates, sorted contacts/categories, preserved case in values and exact reason. SQL performs the hash; the client does not implement a competing receipt authority. Identical canonical request returns original REPLAY with no duplicate entity/audit. Same actor/key with changed fingerprint is P0RPL; another actor's key is a separate request. Replay checks current create permission and original effect evidence, even after reference retirement/entity later changes; corrupt/missing evidence is P0INV. Replay never grants current read/edit rights or restores Draft status.

An in-memory immutable create intent records actor ID, auth generation, scope/route generation, request UUID, deep-copied serialized payload and reason **before dispatch**. Unknown create outcome freezes that intent. Explicit Retry creation sends exactly the same p_request_id/p_payload/p_reason; do not rebuild from controllers, renormalize differently or mint a replacement key. Ignore a delayed original response after a newer attempt/clearance. See §8 for leaving and starting another intentional Draft.

Update p_request_id is **audit correlation, not idempotency**. Each intentional update captures exact original detail updated_at, full six-field replacement, entity and reason. Server locks the entity, rechecks provenance/eligibility/permission, compares the expected token, then updates atomically. A no-op requires all guards and equal version; UNCHANGED writes no audit/version. Material child-only edits also advance entity updated_at. The unchanged shared trigger uses now(); transaction-start/version advancement can itself yield P0CON. There is no timestamp repair, trigger patch, new version field or sleep/retry workaround.

Two competing changes from one version yield one successful material update and one conflict. Unknown update outcome blocks further Save until an authorized reread/reconciliation. Never replay the old update blindly, even with the same request UUID. History is optional corroboration only when audit permission exists; it is not an update-idempotency query or mandatory read substitute.

## 5. Capability matrix

Let R=`business_entities.read`, C=`business_entities.create_draft`, E=`business_entities.edit_draft`, A=`business_entities.read_audit`. Test all 16 combinations. Each column is independently gated; generic staff/application reviewer/OWNER/ADMIN/MEMBER and route visibility supply no grant.

| R C E A | List/detail | Create | Full editor | Embedded history / known UUID |
| --- | --- | --- | --- | --- |
| 0 0 0 0 | No | No | No | No |
| 0 0 0 1 | No | No | No | History only |
| 0 0 1 0 | No | No | Unavailable: read required | No |
| 0 0 1 1 | No | No | Unavailable: read required | History only |
| 0 1 0 0 | No | Receipt only | No | No |
| 0 1 0 1 | No | Receipt only | No | History only |
| 0 1 1 0 | No | Receipt only | Unavailable: read required | No |
| 0 1 1 1 | No | Receipt only | Unavailable: read required | History only |
| 1 0 0 0 | Yes | No | No | No |
| 1 0 0 1 | Yes | No | No | Yes |
| 1 0 1 0 | Yes | No | Eligible detail only | No |
| 1 0 1 1 | Yes | No | Eligible detail only | Yes |
| 1 1 0 0 | Yes | Yes | No | No |
| 1 1 0 1 | Yes | Yes | No | Yes |
| 1 1 1 0 | Yes | Yes | Eligible detail only | No |
| 1 1 1 1 | Yes | Yes | Eligible detail only | Yes |

"Eligible detail only" also requires server can_edit_draft=true, established origin, complete bounded detail and a current session/capability snapshot. A read grant is repository-wide canonical minimal profile/list scope per A0, without invented regional/tenant filtering. All mutation authorization remains server-side.

Create-only can enter /new directly without a list/detail request. Audit-only can open /:entityId and obtain history without entity detail. Edit-only sees a controlled read-required explanation and no full replacement editor or synthesized defaults. A-capable users without R enter a known UUID; no entity autocomplete/name search/list is implied. UUID syntax checking does not establish entity existence or permission.

## 6. Routes and navigation

Exact proposed routes on the authenticated **root navigator**, outside shell branches/bottom navigation:

```text
/staff/businesses
/staff/businesses/new
/staff/businesses/:entityId
```

Register /new before the parameterized route. AppRoutes owns canonical constants and a UUID detail-path helper; no localization-dependent identity. Extend the existing auth-required family and AuthReturnDestination's exact segment allowlist for just these shapes. Preserve external URL, protocol-relative, authority, traversal and extra-segment rejection; validate a non-nil UUID before target RPC dispatch. No DTO/payload/private search text in route extras or query strings, no separate history route, no route that bypasses canonical auth recovery.

Route dispatch watches the existing AuthProvider as well as router refresh: resolving, sign-out pending, cleanup/conflict/quarantine/observation-unavailable or blocked authority renders only existing safe auth/recovery surfaces. A router match alone does not authorize access. Refresh A0 capabilities on console entry and appropriate return/app resume before actions; load only permitted lanes. Authenticated users with no applicable capability see a safe no-access state, not a public Directory fallback.

One Commercial Admin tile is visible only after successful discovery of at least one A0 capability. Its dispatch priority is R → /staff/businesses list; otherwise C → /staff/businesses/new; otherwise A → known-UUID dialog then /:entityId; otherwise E-only → /staff/businesses controlled read-required explanation. The bounded list screen therefore also hosts no-read access explanations/UUID entry when reached directly; it does not issue list RPC without R. If C and A exist without R, /new can offer a secondary known-UUID history action. No second User Area tile or extra route is needed.

Discovery loading/failure never implies permission or removes existing User Area entries. All existing header, Profile, Saved, Downloads, managed-business, application and staff-application behavior/design remain intact. Refresh the tile on hub re-entry; use A0 access provider rather than StaffAccessProvider's application-review permissions. Any UUID dialog is scoped and cleared under §11. Existing business routes/return destinations and public routes are preserved.

## 7. List-screen specification

Use one AdminBusinessesScreen. Header: localized Business Drafts, truthful Draft-only context, optional Create Draft action gated C. Search is name only, up to 120 trimmed server characters; submitted/debounced read searches may be coalesced, with old completions invalidated. Type filter is optional, exact nine-code canonical options or All types; changing it/search resets list items/cursor/page epoch. No lifecycle-edit control or publication action; backend supports other read lifecycle filters but this bounded UI keeps draft explicit.

Show only the returned list fields: name, canonical type label, Draft lifecycle/status context, existing verification/claim labels if useful, timestamps and optionally entity UUID. Never show inferred creator, ownerless/owner badge, address, contact, image, subscription, entitlement, published-ready state or total count. Existing verification text is engineering status and does not grant Commercial Verified status. Rows open canonical detail only while R is current. No edit action based on list lifecycle.

Page size 25, explicit Load More only with next_cursor, one in-flight page per query. Maintain exact cursor; deduplicate visible entity IDs defensively without fabricating count/continuation. Refresh resets pagination. Loading, valid empty Draft list, no search matches, malformed response, unavailable/offline, permission denial and error remain distinct. First-page failure is not empty success. Later-page failure leaves same-actor authorized items visible with bounded Retry load-more; permission/identity loss always clears them. Read retry is explicit and uses current query/cursor; no mutation is triggered. No infinite scroll/export/snapshot guarantee or private persistent cache.

Without R, render capability-appropriate create/known-UUID access or read-required/no-access explanation; keep list/search/filter controls absent. Loading capabilities never transiently renders a previous actor's list.

## 8. Create-screen specification

Use the shared AdminBusinessDraftScreen in create mode. Require C and settled current authentication, independently of R. Sections: Identity/type/name, Description, Contacts, Categories, Primary Location, and reason selection. Show only the four authoring types. Arrays are bounded at ten; contact-primary toggles are per type and category-primary at most one. Description and primary location may be empty/null; no publication-required-field gate. Optional active taxonomy selects load through the new gateway only; failures remain retryable controlled states, not invented IDs.

Keep form/controller state in memory and scoped. Validate all six keys and compatible technical limits, show localized inline errors and focus the first invalid field. Review the submitted content and reason before deliberate Create Draft. Disable concurrent/double submit and editing the dispatched immutable intent. Generate one non-nil request UUID for that intentional submission, not on every rebuild/network attempt. No automatic create on route entry, retry, reconnect or auth refresh.

On CREATED/REPLAY, show a localized receipt with entity UUID, request UUID, original creation time and outcome; no current version/editability/ownership/publication assertion. Without R, stay in receipt-only success, with no detail fetch or Open detail link. With R, offer an explicit Open detail action and load a fresh authorized detail; do not treat created_updated_at as the current editor token after replay. A-capable receipt-only users may explicitly open history for the returned UUID without fetching detail.

Unknown outcome presents Outcome not confirmed and an explicit Retry same creation request action retaining the exact intent/reason. No replacement key, edited request retry, optimistic row insertion or success notification until a valid receipt. P0RPL/P0INV stop the recovery path and preserve only still-authorized scoped intent for diagnosis; no automatic repair. A deliberate new Draft after a resolved receipt is a separate user action with a new key. While an outcome remains unknown, starting another Draft requires an explicit duplicate-risk acknowledgment and disposal of the old local intent; do not label that as retry/reconciliation. No promise of cross-device/restart recovery, receipt enumeration or durable private intent storage.

Leaving/disposal/logout/actor or permission loss clears intent and inputs. If the operator intentionally leaves while a dispatched create is uncertain, explain before leaving that server completion is possible and local recovery intent will be lost; never block security clearance or copy that intent into another route/actor. A delayed server result cannot restore it.

## 9. Detail/editor specification

The shared screen in entity mode validates route UUID and independently resolves capabilities. R authorizes detail; A separately authorizes history. E without R never fetches/constructs a full editor. Detail-only is a valid read-only mode; audit-only is history-only mode with UUID context and no entity name, contacts, type or other private-detail fetch.

Read-only sections reflect exact detail fields and nulls. No guessed owner/creator facts. Show meaningful controlled reason text when authoring is unavailable, based only on returned signals: unestablished origin, incomplete projection/location scope, unavailable read/edit capability or server-declared ineligibility. Do not diagnose memberships/subscriptions absent from DTOs. Non-Draft/current out-of-four type is read-only. can_edit_draft=false always disables editing; can_edit_draft=true never overrides current auth/capability loss.

Full editing requires current R and E, origin CUI2A0, can_edit_draft=true, contacts_complete/categories_complete/location_scope_complete true, and representation within ten-item authored collection bounds with valid canonical values. Do not turn false/missing/malformed flags into true. Unsupported additional locations cannot be listed, removed, adopted or silently ignored by an editor. No scalar-only save when location_scope_complete=false. Display Primary Location as Location / الموقع, never Branch / فرع.

Seed the six-field form from a complete detail snapshot; preserve exact version and values. Map reference labels for display, not identity; include inactive assigned references as marked read-only/retired choices rather than dropping them. On a material save, every submitted category and non-null region must be active. Require deliberate removal/replacement of inactive references first, including for otherwise unrelated scalar changes. No silent filtering or auto-conversion. A normalized no-op can return UNCHANGED without active-reference revalidation, as A0 does; do not advertise a material save until reconciliation is complete.

Select one update reason, validate and deliberately Save. Single flight, immutable captured expected_updated_at and request correlation; no status/owner/media actions. UPDATED/UNCHANGED is a receipt, not detail; while R remains current reload detail before resuming editing, and refresh permitted history independently. Clear the submitted editor revision on resolved success so later edits use a freshly read token. A detail reload failure does not erase confirmed server success or invent new profile data; show confirmed receipt plus unavailable detail, with Save disabled until a valid read. Refresh list on appropriate return using the normal permitted read lane.

P0CON enters conflict state with Save disabled. Preserve local unsaved candidate only within the same authorized actor/route while fetching fresh detail. Show current server content and local proposed field-group differences using exact six scoped fields; offer discard/reload or deliberate reconciliation into a new candidate on the new version. No silent merge/rebase/overwrite or automatic save. If fresh detail is ineligible, remove the editor; no field/status repair to restore access. Cancelling reload/reconciliation cannot re-enable the stale token.

Unknown update result similarly blocks Save and requires fresh detail. Compare refreshed scoped content/version with the submitted candidate and, if A exists, display request-correlated authoring history as corroboration. Equality does not prove that this operator's call committed; another writer could produce the same content. A new save is only a deliberate reconciled operation with a fresh current token/correlation ID/reason. If reread fails or R disappears, the editor stays unavailable. Do not use same request UUID as update replay authority.

Back/cancel/route replacement clears target/editor/controller/dialog state after any deliberate unsaved-discard confirmation. Security loss clears immediately without a discard veto. Re-entering a route starts fresh permitted reads; no retained old target seed masquerades as current authority.

## 10. History specification

AdminBusinessHistorySection sits below detail content on the shared screen; no separate route. With A and no R it is the sole private-data section, headed by known canonical UUID. With R but no A, history is unavailable and no audit RPC is sent. Losing A clears all console private state under §11, including existing history; revalidation can reload permitted detail subsequently.

Load 25 events per page with explicit Load More. Render action, localized reason code, event time, request correlation, nullable actor UUID (neutral deleted/unavailable label), ordered changed-field labels, before/after version/count/location-presence summary. Show only returned sanitized fields. No actor profile enrichment, raw before/after payload, contact/address history or generic application/membership/payment history. Label it A0 Draft authoring history; empty history on a readable legacy Draft is not a broken full-history promise.

Audit loading/empty/no permission/P0NOT/P0INV/offline/error are independent of detail loading. Audit RPC denial clears private console state; a routine history read failure does not transform valid detail into editor authority. Target/route/cursor changes invalidate old history responses. Do not silently drop corrupt events or use raw audit table fallback.

## 11. Session and permission-loss clearance

Use the **existing** AuthProvider `session.userId`, `generation`, `isCurrentSession(userId: ..., generation: ...)`, `isLoggedIn`, `canAccountAuthorityBeGranted` and blocked/recovery state. isCurrentSession alone only checks authenticated identity/generation; combine it with the authority gate and console epochs. No AuthProvider, auth subscription authority or Supabase initialization duplication.

Every read, mutation, option lookup, dialog result and success notification captures `(actorId, authGeneration, consoleEpoch, routeEpoch, laneEpoch)` plus entity/query/cursor/intent identity as relevant. A completion can publish only when not disposed, the captured epochs/key still match, the existing AuthProvider accepts that identity/generation and account authority, and the lane's capability remains currently valid. Newer query/capability refresh/route changes invalidate older responses even for the same actor. Late timeout completions never enter a newer lane.

| Trigger | Required synchronous local transition |
| --- | --- |
| Logout begins / sign-out pending; identity/session replacement | Invalidate console/lane epochs and clear private state before new identity paints |
| Ownership conflict, blocked cleanup/quarantine, observation loss or authority gate false | Clear; safe existing recovery UI; no new credential flow |
| Capability refresh removes any previously held A0 grant | Clear **all** private console state; adopt only fresh grants after clearance |
| Authoritative P0PER/P0AUT/ACL auth denial in any lane | Clear all; invalidate old discovery too; fresh capability/auth resolution required |
| Target/mode route replacement, pop, leave or disposal | Clear departed route/provider state and invalidate outstanding responses; no private payload migration |

Clearance includes list/items/cursors/detail/history; editor values and comparison snapshots; text/search/filter/reference selections where private; controllers/focus-backed content/validation messages; dialogs including known-UUID and conflict/discard/retry prompts; pending immutable create/update intents; receipts; pending success/error notifications and SnackBars; operation flags, stale errors and cached private read keys. Dismiss dialogs/clear SnackBars owned by this console without closing unrelated app dialogs. Mounted controller widgets must clear immediately upon an epoch change, not wait for disposal/rebuild. Suppress delayed dialog callbacks, messenger actions and delayed provider notifications. Do not retain old data as a known-good fallback after authority loss.

Access discovery refreshes on console entry and appropriate route return/app resume; User Area tile also refreshes on hub entry. During refresh, actions are gated until success. A successful refresh without grant loss may retain authorized same-actor form state; if loss is observed, clear before new grants are exposed. Failure/unknown refresh grants no new action; hide private rendering until successful revalidation, and clear on authoritative denial. RPCs remain authoritative between refreshes. No claim of instantaneous server-push revocation or cancellation of an already executing server transaction.

CommercialAdminScope coordinates clear/reset/denial across access/list/draft/history state. Main's existing onAccountBoundReset calls its reset method; providers additionally observe auth gate changes so blocked states with unchanged user ID cannot retain data. Route activation/deactivation is explicit, not inferred solely from widget build; use route lifecycle/keys through the bounded router/screens. Pushed-over/returned routes revalidate before private rendering and mutation. Tests must prove clearance happens before stale completions, including same-user new-generation and route reuse. One component owns disposal of each child/provider/controller/listener; no duplicate disposal or app-lifetime orphan listener.

## 12. Domain, gateway and provider design

Small dedicated A0 consumer under the existing business feature; no membership-authority reuse:

```text
existing SupabaseService / production Supabase client
  -> SupabaseCommercialAdminGateway
  -> CommercialAdminGateway + strict immutable models/results
  -> CommercialAdminScope
       -> CommercialAdminAccessProvider
       -> CommercialAdminListProvider
       -> CommercialAdminDraftProvider (detail/editor/history/create receipts)
  -> AdminBusinessesScreen / AdminBusinessDraftScreen / embedded history
```

CommercialAdminModels groups capabilities, list/detail/history DTOs, cursor/version tokens, six-field draft/immutable intents, reason enums, taxonomy DTOs and typed read/mutation outcomes in one bounded file. Reuse existing canonical Directory type constants and contact labels as read-only dependencies; derive the separate four-code authoring list explicitly. No parallel global Directory vocabulary. Define success/denied/not-found/malformed/infrastructure/unknown outcome distinctly; no exception-driven widget authorization.

Gateway exposes discovery/list/detail/create/update/audit plus the two existing read-only taxonomy option operations. Inject the existing SupabaseService and production `Supabase.instance.client` convention via AppDependencies, with a test client seam; no Supabase.initialize/new production client. Gateway owns exact RPC arguments, strict parsing, deadlines and error mapping. It issues no DML and reads no directory_entities/private child/membership/subscription/audit/receipt tables directly. No public Directory repository/cache, M3 evaluator, managed profile mutation or staff application authority call supplies private admin behavior.

Access owns independent grants and revalidation. List owns private query/pages and query-generation guards. Draft owns current mode/entity, detail/edit draft/immutable mutation intent/receipt and a distinct history lane/cursor; history is not a fourth global provider. Scope wires denials/reset/capability reduction and resolved mutation invalidation. Scope is the sole disposal owner of its children if they are exposed via value registrations; provider wrappers must not also own/dispose those instances. Widgets own only view controllers/focus/dialog handles and clear them when scope epochs change; no widget performs an RPC.

Main creates/wires this scope after existing auth/dependencies, includes it in account reset, and registers required providers. Preserve startupReady and existing bootstrap ordering; reset callbacks tolerate scope initialization order and cannot race partially initialized state. Do not edit AuthProvider, SupabaseService, StaffOperationsScope, membership/profile/application providers, shared network policy or global design primitives. Add only dedicated DI, bounded routing/return shapes, navigation entry and localization.

## 13. Localization and design system

Arabic RTL first, with English LTR compatibility and paired Ar/En strings for every new label, reason, validation/error, receipt/conflict/history/access state and accessibility description. Production V1's Arabic-only/disabled English switch decision remains unchanged; English is a compatibility/test surface, not a new product language switch. Display Arabic taxonomy label first in Arabic, English first in English, then available alternate label/code; labels never become identity. No raw SQLSTATE, enum code or technical lifecycle text used as primary user copy.

Reuse CivilAppBar, CivilSurfaceCard, existing form/buttons/state/remote notices, AppSpacing, DesignTokens and active ColorScheme. Feature-local LayoutBuilder adopts established conventions: compact <600 dp with 16 dp gutters; medium 600–839 with 24 dp; expanded >=840 with 32 dp, centered readable content up to 760 dp. Compact forms/list/history use one column; wider layouts may pair short fields while preserving reading/focus order, with descriptions/reason/conflict/history full width. No permanent sidebar, global breakpoint/theme changes or extra responsive screen.

Use directional padding/alignment/icons; LTR isolate phone/email/URL/UUID/coordinate values inside RTL content without switching the whole screen. Wrap long names/reasons/labels. Minimum 48 dp new interactive targets, keyboard navigation/focus, semantics labels and error announcements, readable contrast, scroll access with keyboard open, and text scale 1.0/1.3/2.0. Avoid fixed-height cards/fields that clip scaled text. Preserve light/dark and existing Cairo/theme behavior. Owner visual QA governs subjective polish; automated tests govern programmatic gates.

## 14. Exact future production file manifest

**Frozen future boundary, not implementation authorization.** Exactly 18 production paths: 10 NEW (absent at baseline), eight MODIFIED (present). Revalidated against source; no whole-directory allowlist. These paths are not created/modified in this acceptance/freeze pass.

| # | Path | Future bounded purpose |
| --- | --- | --- |
| N1 | `lib/features/business/domain/commercial_admin_models.dart` | Strict A0 DTOs/results/capabilities/payload/intents/taxonomy tokens |
| N2 | `lib/features/business/domain/commercial_admin_gateway.dart` | Dedicated gateway interface; no membership authority |
| N3 | `lib/features/business/data/supabase_commercial_admin_gateway.dart` | Six RPCs/two public read-only selectors/error mapping |
| N4 | `lib/features/business/presentation/providers/commercial_admin_access_provider.dart` | Independent grants, entry/return refresh |
| N5 | `lib/features/business/presentation/providers/commercial_admin_list_provider.dart` | Query/pagination/clearance |
| N6 | `lib/features/business/presentation/providers/commercial_admin_draft_provider.dart` | Create/detail/editor/history lanes/reconciliation |
| N7 | `lib/features/business/presentation/screens/admin_businesses_screen.dart` | Bounded list and no-read access states |
| N8 | `lib/features/business/presentation/screens/admin_business_draft_screen.dart` | Shared create/detail/editor/history-only modes |
| N9 | `lib/features/business/presentation/widgets/admin_business_history_section.dart` | Embedded sanitized history presentation |
| N10 | `lib/core/di/commercial_admin_scope.dart` | Reset/denial coordination; explicit disposal ownership |
| M1 | `lib/core/di/app_dependencies.dart` | Construct/get dedicated gateway using existing backend |
| M2 | `lib/main.dart` | Scope/provider composition and existing identity-reset hook |
| M3 | `lib/routes/app_routes.dart` | Three constants/pattern and UUID path helper |
| M4 | `lib/routes/app_router.dart` | Auth root route registration, lifecycle dispatch, /new precedence |
| M5 | `lib/features/auth/domain/auth_return_destination.dart` | Exact three-shape auth return allowlist extension |
| M6 | `lib/features/user_area/presentation/user_area_screen.dart` | Exactly one capability-driven navigation tile/UUID prompt |
| M7 | `lib/localization/ar.dart` | Arabic strings only |
| M8 | `lib/localization/en.dart` | Matching English compatibility strings only |

Read-only dependencies are not write allowance: existing AuthProvider, SupabaseService, remote policy, DirectoryEntityType, shared widgets/tokens/labels and existing staff/business authority. If implementation needs another model/fake/classifier/helper file, fit it into this bounded proposal or STOP for an exact reviewed manifest amendment. No scaffolding/dependency/config files are implicitly allowed.

### 14.1 Original audit reconciliation — Architect correction

The original ten NEW production candidates supplied by the Architect were:

```text
lib/features/business/domain/commercial_admin_gateway.dart
lib/features/business/domain/admin_business_summary.dart
lib/features/business/domain/admin_business_draft.dart
lib/features/business/domain/admin_business_audit.dart
lib/features/business/data/supabase_commercial_admin_gateway.dart
lib/features/business/presentation/providers/commercial_admin_provider.dart
lib/features/business/presentation/commercial_admin_messages.dart
lib/features/business/presentation/screens/admin_businesses_screen.dart
lib/features/business/presentation/screens/admin_business_draft_screen.dart
lib/features/business/presentation/widgets/commercial_admin_entry_tile.dart
```

The original eight MODIFIED production paths match M1–M8 above exactly. The current N1–N10 replace the original NEW candidate set with no count or authority expansion:

| Original candidate responsibility | Revised exact allocation and rationale |
| --- | --- |
| commercial_admin_gateway.dart; supabase_commercial_admin_gateway.dart; the two admin screens | Retained unchanged as paths N2/N3/N7/N8; same dedicated consumer and screen boundary |
| admin_business_summary.dart; admin_business_draft.dart; admin_business_audit.dart | N1 commercial_admin_models.dart combines immutable list/detail/draft/audit/cursor/result models, keeping one strict A0 vocabulary and correlation contract instead of several narrowly separated model files |
| commercial_admin_provider.dart | N4/N5/N6 split access, query/pagination and draft/detail/editor/history state into three specialized providers, with independent lane epochs and bounded responsibilities |
| Cross-provider lifecycle/reset coordination inside one broad provider | N10 CommercialAdminScope coordinates auth/reset/denial and disposal explicitly, preserving one AuthProvider and avoiding repeated cross-provider security wiring |
| Embedded history inside the shared screen | N9 admin_business_history_section.dart provides a dedicated embedded widget; no history route or additional provider |
| commercial_admin_entry_tile.dart | The tile is implemented within M6's narrowly authorized User Area integration, avoiding a standalone entry-tile file while retaining exactly one conditional navigation entry |
| commercial_admin_messages.dart | Typed outcomes stay in the bounded domain/gateway; localized message presentation is integrated in the feature/UI and M7/M8 Ar/En files, without a separate message file |

This allocation removes six original NEW paths and adds six revised NEW paths while retaining four, so the total remains **10 NEW + 8 MODIFIED = 18 production paths**. The supplied Architect decision accepts this revised architecture as the candidate for final freeze. Original candidate paths absent from N1–N10 are historical audit evidence only, not an alternative or additive implementation allowlist. Preserve the current exact 18 paths; a genuine later defect requires an exact reviewed amendment.

## 15. Exact future test file manifest

Six NEW focused tests, absent at baseline. Inline fakes/fixtures belong in these six files; no extra fake/support directory allowance:

| Path | Coverage |
| --- | --- |
| `test/commercial_cui2a1_admin_business_draft_domain_test.dart` | Strict projections/nulls/vocabularies/version/cursor/full payload |
| `test/commercial_cui2a1_admin_business_draft_gateway_test.dart` | Six exact RPC mappings/selectors/error/deadline/outcome distinctions |
| `test/commercial_cui2a1_admin_business_draft_provider_test.dart` | 16 capability combinations, epochs/clearance/replay/conflicts/history |
| `test/commercial_cui2a1_admin_business_draft_list_widget_test.dart` | List/search/filter/paging/navigation/entry states/design |
| `test/commercial_cui2a1_admin_business_draft_editor_widget_test.dart` | Create/detail/editor/history-only/receipts/conflict/design/accessibility |
| `test/commercial_cui2a1_admin_business_draft_boundary_test.dart` | Exact manifest/routes/zero backend delta/forbidden controls/authority preservation |

Five existing UI-test MODIFIED candidates, present and inspected for route/User Area harness dependencies:

```text
test/app_routes_test.dart
test/user_area_route_test.dart
test/v1_r08_router_auth_test.dart
test/v1_r08_user_area_widget_test.dart
test/v1_r07_staff_operations_flutter_test.dart
```

Changes are limited to new route assertions, dedicated provider injection into harnesses and exact capability-dependent extra tile/UUID entry. Retain existing guest counts, recovery/ownership/session-return behavior and staff application gates; no general count relaxation. These five are separate from the protected dirty test trio, which remain untouched. New acceptance cases can reside in the six new tests without widening existing changes.

### 15.1 Original audit test reconciliation

The original six NEW test/support proposals supplied by the Architect were:

```text
test/commercial_cui2a1_admin_business_gateway_test.dart
test/commercial_cui2a1_admin_business_provider_test.dart
test/commercial_cui2a1_admin_business_widget_test.dart
test/commercial_cui2a1_admin_business_routes_test.dart
test/commercial_cui2a1_admin_business_boundary_test.dart
test/fakes/fake_commercial_admin_gateway.dart
```

Retain the current six NEW paths in the table above as the revised candidate. Domain parsing/payload/version tests now have their own domain file; gateway/provider/boundary coverage retains its responsibility in the corresponding renamed draft test files. The original general widget coverage is split into list and shared editor/history widget files. Route/deep-link/capability dispatch coverage is redistributed to those widget files and the explicitly affected existing canonical-route/auth-return tests, rather than a separate new routes file. Deterministic gateway/client fakes and delayed Futures are inline in the six focused files, replacing the standalone fake path without adding a support-file allowance. This produces six substantive domain/gateway/provider/list/editor/boundary test paths while retaining all required route/lifecycle/security coverage.

Original five MODIFIED UI-test candidates:

```text
test/user_area_route_test.dart
test/v1_r08_user_area_widget_test.dart
test/v1_r07_staff_operations_flutter_test.dart
test/v1_r09_p2_c_authenticated_profile_read_ux_test.dart
test/w6_3_nav_transition_test.dart
```

The revised candidate retains the first three and replaces only the final two with `test/app_routes_test.dart` and `test/v1_r08_router_auth_test.dart`. Source evidence supports this redistribution: app_routes_test.dart directly tests canonical path identities/helpers and shell linkage; v1_r08_router_auth_test.dart directly tests AuthReturnDestination's protected-family shapes, scheme/authority/traversal/lookalike rejection and live protected-route auth dispatch. Those are the exact requirements changed by production M3–M5. The retained three cover the narrowly added User Area tile and existing staff/application behavior.

The two displaced original tests remain **READ-ONLY / UNMODIFIED regression candidates**:

```text
test/v1_r09_p2_c_authenticated_profile_read_ux_test.dart
test/w6_3_nav_transition_test.dart
```

The former protects authenticated profile-read UX; the latter protects shell/Avatar/User Area navigation and uses the production router/provider harness. Their displacement is not evidence that integration cannot affect them. Include both in §18's focused regression gate. If later implementation proves either needs a harness or expectation edit, **STOP for an exact manifest amendment**; do not silently modify them or omit failing cases. Original test/support candidates outside the revised tables are evidence only, not allowed alternative write paths.

### 15.2 Exact four-file compatibility boundary and preservation

These **four** existing compatibility paths match the accepted post-A0 correction boundary and form a **separate future authorization**, not UI implementation permission:

```text
test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
test/commercial_harden1_public_plans_exposure_migration_test.dart
test/commercial_m1b_catalog_reference_data_migration_test.dart
test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart
```

Both following files remain **READ-ONLY / UNMODIFIED**, outside every proposed modification boundary, and must pass focused regressions:

```text
test/commercial_m1a_private_catalog_migration_test.dart
test/v1_r09q_security_matrix_test.dart
```

The A0 guard already belongs to this four-file boundary. Its live hasAuthorizedCui2a0Boundary checks the closed lib/docs/roadmap composition, so future exact A1 documentary recognition must be addressed there together with HARDEN-1/M1b/M3 wrappers. Keep historical closed-A0 checks on their exact historical fixture; future separately authorized composition recognition must preserve SQL/runtime blobs, security support, historical pins, 26-migration inventory and all negative authority/security tests. No general live-roadmap relaxation or continuing A0 backend authority. Architect must approve exact guard mechanics/probes under §16 before edits.

M1a must not be added to the modification boundary unless a later independent audit proves a specific unavoidable requirement and obtains separate Architect approval. R09q's ACL/security assertions and source remain unchanged. Historical CUI-1, A0, M1a, HARDEN-1, M1b, M3, R09q, ownership, SQL and ACL protections remain mandatory.

Corrected future count: **18 production + 6 new tests + 5 modified UI tests + 4 compatibility guards = 33 distinct paths**, comprising **16 NEW + 17 MODIFIED** (10+6 new; 8+5+4 modified). The current exact manifests govern; original/displaced audit candidates and read-only regressions do not add write paths. Governance documents for future freeze/roadmap authorization require their own explicit pass; they are not part of this production/test count.

## 16. Static-compatibility prerequisite and GREEN gate

At baseline `3f4ce87381ea97b0f3f6a772827c4d77b58aee66`, the four accepted post-A0 compatibility guards are **A0, HARDEN-1, M1b and M3**, exactly §15.2. They correctly reject unauthorized A1 paths, including this exact draft contract path. M1a/R09q remain read-only regressions. A drafting-time strict-governance failure is not permission to alter guards, historical status, SQL, pins or roadmap. No Flutter/static suite is run or GREEN asserted in this correction pass.

The following is a concrete **future gate sequence**, not authorization to execute it now. Stage labels are explanatory and are not invented commit hashes or new document paths:

1. **Correction/re-review:** complete this document-only pass. Architect re-reviews the supplied audit reconciliation, corrected 33-path manifest and unchanged technical design. All draft/NO/NONE status controls remain current until a separately supplied final acceptance/freeze decision.
2. **Acceptance/freeze and Owner governance commit:** after that decision, a separately authorized governance-only pass may update this contract's acceptance/freeze record and append the exact corresponding record to `docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md`. The boundary for that pass is this contract plus that one append-only roadmap path; no tests/lib/SQL. Commercial CURRENT remains NONE and implementation NO. Owner commits the accepted governance. Record the actual observed commit/blob identities afterwards. Existing guards may still reject the new authorized documentation until the separately authorized compatibility work; that expected chronological state is not a waiver of the later GREEN gate.
3. **Separate compatibility authorization, recorded before guard edits:** Architect/Owner explicitly authorize only the four §15.2 guard paths and their exact documentary composition/probe delta. A separately authorized governance-only pass appends the literal compatibility-only authorization to the roadmap, with commercial implementation NO/CURRENT NONE, exact frozen contract identity and the four-file allowlist. Owner commits that record before guard work. The guard implementer now has concrete committed contract/roadmap inputs; no dependency on an uncreated production implementation or a future commit hash.
4. **Compatibility work/GREEN/independent review:** change only those four guards, recognizing the exact committed frozen contract, acceptance/freeze record and compatibility authorization from steps 2–3. Validate their real observed commit/blob identities, retain the entire preceding roadmap bytes and compare the specifically authorized append text exactly. Keep historical CUI-1/A0 closure fixtures and SQL/ACL/ownership invariants intact; no arbitrary suffix or anticipated implementation-YES append. Run the four guards plus unchanged `test/commercial_m1a_private_catalog_migration_test.dart` and unchanged `test/v1_r09q_security_matrix_test.dart`, all zero failures, with adversarial path/status/source/append probes. Independent review must accept the bounded documentary recognition and preservation evidence.
5. **Owner compatibility commit:** Owner commits only the accepted four-guard correction. Record its actual identity and the focused GREEN/review evidence. This commit still authorizes no UI/backend implementation. A later implementation-authorization append is not implicitly accepted by these guards, and no broad future-record wildcard is introduced.
6. **Separate implementation authorization with coordinated guard composition recognition:** after step 5, Architect/Owner must supply the exact A1 consumer authorization and separate authority for the four guards to recognize both that literal roadmap append and the AUTHORIZED CUI-2A1 current-composition predicate defined below. If coordinated edits are needed, the future pass has exactly five write paths: `docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md` (the single authorization append) and the same four §15.2 guards (the explicitly approved predicate/probe changes). No contract rewrite, new guard/report, A1 production/UI-test implementation, SQL or M1a/R09q edit. Review the exact append, predicate and adversarial probes together; require four-plus-two focused GREEN with zero A1 implementation changes and independent acceptance before Owner commit. Before that commit, the live AUTHORIZED branch must remain disabled and its tests must assert rejection of uncommitted authorization; reviewed candidate recognition supplies no implementation grant. After commit, step 7 requires the live committed positive case. The append authorizes only the frozen A1 consumer scope, preserves CUI-1/A0 CLOSED and all commercial exclusions, and conditions execution on that commit plus step 7's fresh GREEN. No production implementation occurs in this coordinated pass.
7. **Committed preimplementation and postimplementation GREEN:** after step 6's Owner commit, verify the actual committed authorization baseline, frozen contract and approved guard sources. Run the four compatibility guards and unchanged M1a/R09q against the live AUTHORIZED CUI-2A1 current-composition predicate with zero A1 production/test changes, plus its negative probes. Zero failures are required before implementation. During separately authorized implementation, that same predicate permits only the 29 A1 implementation paths defined below. After implementation, rerun those six regressions and the exact focused A1 acceptance suite for mandatory postimplementation GREEN. No earlier/precommit PASS substitutes for either gate. Failure requires STOP, without skipped assertions, read-only source edits or retroactive authorization; no repository-wide suite without a separate integrated gate.

**Historical versus authorized predicates:** preserve the strict historical CUI-1/A0 CLOSED predicate, its exact closure composition, accepted source/commit pins and adversarial rejection cases. Add a separate AUTHORIZED CUI-2A1 current-composition predicate; enable it only when the exact frozen contract and literal implementation-authorization roadmap controls are committed and verified against the already accepted prerequisite identities. The controls must identify CUI-2A1 as CURRENT, authorize only this consumer slice and retain CUI-1/A0 CLOSED, M4/M5 NOT AUTHORIZED and the R10.5-D restriction. The authorized predicate validates preserved historical sources/pins without requiring the live A1 composition to equal the old closed-only lib/test set. An absent, uncommitted, altered or mismatched authorization cannot enable that branch; historical fallback must not make an invalid current composition pass. Step 6's explicitly authorized pending pair is review evidence only, never an enabled production-implementation branch.

**Exact current-composition delta:** measure the complete committed, staged, unstaged and untracked repository change set against the verified committed authorization baseline, accounting separately for the exact preserved dirty entry paths/bytes. During authorized implementation, permit only the exact 18 production paths in §14 and 11 focused/UI-test paths in §15 (six NEW plus five MODIFIED): 29 paths, with partial progress allowed inside that set. The four guard paths remain outside this implementation delta; their source changes belong exclusively to separately authorized compatibility passes and must match the approved committed guard baseline during UI work. Reject every extra path, unauthorized rename/deletion, SQL/Supabase/migration delta, contract/roadmap change after authorization, and unrelated protected-source change. The protected dirty entry baseline is preserved by exact paths/bytes, not a generic dirty-file exception. Shared historical, SQL, ACL, ownership and M1a/R09q protections remain mandatory; an allowed filename alone does not certify behavior or authority safety.

**Live positive and adversarial evidence:** positive filesystem/composition checks and in-memory negative mutations must invoke the same live/current predicate and branch selection. Preimplementation it must accept the exact committed authorization with zero A1 production/test changes, while rejecting unauthorized additions. Probes must demonstrate that permitted partial A1 changes stay bounded to the 29 paths and that removing/changing authorization, adding an extra path, editing a guard during UI work, changing protected sources or modifying SQL/contracts/roadmap fails. Keep strict historical positive/negative fixtures as separate preserved coverage; do not substitute a weaker test-only predicate or bypass historical pins to obtain current GREEN.

**Resulting source identities:** no nonexistent future A1 implementation commit/blob hashes are prerequisites for authorization or preimplementation GREEN. Those gates verify existing prerequisite/authorization/guard identities, exact frozen paths and preserved source invariants. Final implementation acceptance must additionally verify the actual resulting Owner-committed A1 source identities and exact changed-path set, including required new files, absence of out-of-scope changes and traceability to the verified authorization baseline. The changed implementation set must be a subset of the 29 paths; any unchanged MODIFIED candidate is recorded as unchanged rather than requiring an artificial edit. Check working-tree parity with accepted committed sources and record the real commit/blob identities only after they exist. Reuse the same current predicate for postimplementation positive/negative evidence, and require postimplementation focused GREEN; no source pin, historical protection or M1a/R09q assertion is weakened.

This avoids a circular requirement to know a guard's own future commit hash: source recognition pins already committed prerequisite identities and the exact Owner/Architect-supplied new append bytes. Step 6 can validate the specifically authorized pending pair as a **review candidate**; production execution remains blocked. Step 7 additionally compares the actual committed document/source objects and records the resulting real commit in validation evidence after it exists. No guard accepts an arbitrary future append, infers authorization from filenames, or equates a pending candidate/test PASS with committed implementation permission. Any change to supplied append text, file set, prior bytes or controls needs a new exact authorization and review.

Every focused gate above includes exactly the four compatibility guards plus the two read-only preservation regressions. No skip/comment-out/environment bypass of live boundary assertions to claim GREEN. If safe composition cannot be achieved inside the four approved guard paths while M1a/R09q remain unchanged, STOP for an independent audit and exact Architect amendment; do not expand the boundary by convenience. Compatibility-only authorization never opens UI/backend implementation by itself.

## 17. Security and concurrency invariants

| Invariant | Required preservation |
| --- | --- |
| One identity/backend authority | One existing AuthProvider and production Supabase initialization/client; no service_role credentials in Flutter |
| Permission independence | Exact four codes; no role-name/staff/application-review/membership inference; RPC final authority |
| Private read boundary | Six A0 projections only; public active taxonomy selectors exception only; no raw private table/cache fallback |
| Draft write boundary | Six-field full payload; only four authoring types; ownerless non-public creation; eligible established A0 Draft updates |
| Incomplete data | False/missing completeness/can_edit prevents whole editor; no additional-location adoption/removal or truncated replacement |
| Unknown outcomes | Immutable actor-scoped create replay only by explicit action; update reread/reconcile; no blind automatic mutation retry |
| Optimistic version | Preserve microseconds/raw token; no stale overwrite, trigger alteration or millisecond truncation |
| Audit | Sanitized permission-scoped A0 history; no raw audit/profile enrichment; helper owner-only direct EXECUTE retained |
| Canonical CLAIM isolation | Preserve receipt protection and existing trigger/non-A0 behavior; no public Claim route/control or ownership shortcut |
| Session isolation | Synchronous local clear and stale-response/dialog/notification suppression before new actor/generation paints |
| Backend delta | 00001–00026, SQL runtime, ACL/RLS/helper/receipt/index/permission definitions unchanged; no migration 00027/RPC additions |
| Commercial separation | Draft/status/verification/claim/media/Saved do not establish payment/Verified/Sponsored/ownership/publication readiness |

Client tests prove transport and UI behavior, not server lock/ACL/RLS truth. Accepted A0 server evidence remains closed and preserved. Deferred public-schema default privilege, legacy sibling RPC ACL and region_preferences findings stay outside A1; no silent remediation. An executing authorized server transaction can complete after local clearance; local generation checks prevent its response from entering another actor's UI but do not claim server cancellation.

## 18. Focused validation and acceptance matrix

All rows below are **future required evidence**, not implementation PASS claims from this contract acceptance. Run processes sequentially if NativeAssets/build collisions occur. No repository-wide suite unless a separately authorized integrated gate explicitly requires it.

| ID | Scenario / required assertion | Primary test file(s), as listed in §15 |
| --- | --- | --- |
| A1-01 | Exact six function names/all named keys/default Draft/25/cursor/null payload values, no actor/extra RPC | gateway |
| A1-02 | Full six keys, exact nested shapes, four authoring/nine read types, bounds/nulls/strict DTO/status/cursor/receipt correlation; malformed page fails whole parse | domain, gateway |
| A1-03 | All 16 R/C/E/A combinations; application reviewer and OWNER/ADMIN/MEMBER confer zero A0 grant | provider, editor, boundary |
| A1-04 | Three root routes; /new precedence; guest redirect/auth return safe allowlist; malformed UUID/no extra; blocked/unresolved auth no private flash | list, editor, existing route tests |
| A1-05 | C without R sends create/options only; receipt-only success, no detail/list/Open detail; A without R known UUID sends audit only | gateway, provider, editor |
| A1-06 | E without R has explanation/no full editor; A and R independence; absent A sends zero audit calls | provider, editor |
| A1-07 | Permission reduction and authoritative denial clear all private lanes/controllers/dialogs/search/filters/intents/messages; fresh capability discovery required | provider, list, editor |
| A1-08 | Actor replacement and same-actor new generation, blocked authority without identity change, logout pending, disposal clear synchronously | provider, editor |
| A1-09 | Delayed capabilities/list/detail/options/audit/create/update/dialog/notification completion cannot repopulate after clear/query/route change; timeout-late-success race | provider, editor |
| A1-10 | Double submit single flight; identical explicit create retry retains request/payload/reason; REPLAY historical timestamps do not seed edit version; P0RPL/P0INV stop; no automatic retry/new key | gateway, provider, editor |
| A1-11 | Unknown create/malformed receipt preserves immutable intent, receipt success only when proven; leaving clears; deliberate new-Draft duplicate-risk acknowledgment | provider, editor |
| A1-12 | Exact microsecond expected timestamp; P0CON conflict/reload/no overwrite; new fresh-version reconciliation; no-op UNCHANGED; update request UUID not replay authority | domain, gateway, provider, editor |
| A1-13 | Unknown update requires reread; audit optional, no permission invented; reread failure/ineligible outcome keeps Save unavailable; same content not proof of caller commit | provider, editor |
| A1-14 | Legacy/unestablished/non-Draft/four-type-ineligible/can_edit=false remains read-only; incomplete collections/non-primary scope blocks any full replacement | domain, provider, editor |
| A1-15 | Inactive assignments stay visible; material save requires deliberate active-reference reconciliation; no-op server semantics preserved; location null/paired precise coordinates | domain, gateway, editor |
| A1-16 | Independent sanitized history, nullable actor, exact action/reason/changed fields, cursor paging/empty/error/P0INV; no raw/legacy events/actor enrichment | domain, gateway, provider, editor |
| A1-17 | List Draft default/name search/type filters/reset/cursor/25/Load More; no total/creator/address/owner inference; old-query race; no-read entry behavior | provider, list |
| A1-18 | First load/empty/search-empty/unavailable/offline/retry/malformed/later-page failure distinct; deny clears stale known-good data | list, editor, provider |
| A1-19 | Arabic/English, RTL/LTR, light/dark at compact/medium/expanded boundaries; long text, keyboard and text scale 1/1.3/2; no overflow, 48 dp targets/semantics/focus | list, editor |
| A1-20 | Forbidden publish/payment/ownership/invite/verify/media/Branch/team/taxonomy/suspension controls absent across capability combinations | list, editor, boundary |
| A1-21 | Exact manifest; no SQL/Supabase/permission/helper/direct-DML delta; one client/AuthProvider; no widget RPC/private-cache fallback; preserved security pins | boundary, A0/security/commercial regressions |
| A1-22 | Existing User Area/profile/staff/application/shell/navigation/design behavior remains; exactly one conditional Commercial Admin tile; auth-return regressions | five existing UI tests + regressions below |
| A1-23 | Future static composition accepts only exact authorized A1 and rejects extra path/contract/roadmap/backend authority; all historical negatives retained | separately authorized §16 guards |

In this matrix domain/gateway/provider/list/editor/boundary abbreviate, in order, the six full filenames in §15; they are not unspecified test directories. Use deterministic gateway/client fakes and delayed Futures, no remote DB, no production authoring fixtures. Tests must inspect actual outbound params/received data/visible controls and lifecycle cleanup, not merely repeat implementation constants.

Exact focused regressions, present at baseline; only the four §15.2 compatibility guards may later change under their separate authorization, all other paths in this list are read-only:

```text
test/auth_provider_test.dart
test/app_shell_test.dart
test/profile_edit_route_test.dart
test/v1_r09_p2_c_authenticated_profile_read_ux_test.dart
test/w6_3_nav_transition_test.dart
test/v1_r07_staff_gateway_production_test.dart
test/v1_r09_p2_e_staff_remote_read_foundation_test.dart
test/v1_r09_p2_e_staff_remote_read_ux_test.dart
test/v1_r03_business_ownership_management_test.dart
test/v1_r06_business_profile_management_test.dart
test/a6_3_1_business_application_creation_authorization_test.dart
test/a6_4_business_application_activation_test.dart
test/commercial_cui1_business_experience_foundation_widget_test.dart
test/w5_4_directory_provider_detail_screen_test.dart
test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
test/v1_r09q_security_matrix_test.dart
test/commercial_m1a_private_catalog_migration_test.dart
test/commercial_harden1_public_plans_exposure_migration_test.dart
test/commercial_m1b_catalog_reference_data_migration_test.dart
test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart
```

The four A0/HARDEN-1/M1b/M3 compatibility guards are read-only during UI implementation and may be edited only in the separately authorized §16 compatibility passes. M1a and R09q remain READ-ONLY / UNMODIFIED and must pass. The displaced authenticated-profile-read and navigation-transition tests remain read-only regression candidates; if either needs modification, STOP for an exact manifest amendment. Protected dirty tests are preserved and excluded from modification; do not repair them to claim A1 GREEN. Run the six new/five affected UI tests and this bounded regression set at the future acceptance gate; record commands, environment, failures and review evidence. Analyze changed production sources with available tooling and report real limitations; never patch SDK/global packages. SQL/runtime/HTTP migration gates are not rerun or claimed by a Flutter contract-drafting pass. Any future integrated/local backend or genuine deployed smoke gate needs its own explicit authorization/environment.

## 19. Owner visual QA criteria

Owner QA is future subjective acceptance, using approved non-production fixtures/dedicated authorized accounts at a later gate. No production/live Draft is created for QA by this draft. At widths 360/599, 600/839, 840 and 1200 dp verify correct layout at exact edges, Arabic RTL first and English LTR compatibility, light/dark, long Arabic business names, nullable/retired references and text scales 1.0/1.3/2.0.

Required visual journeys: permitted list → search/type filter → Load More → detail; create with contacts/categories/no location or one primary location → receipt; receipt-only create; known-UUID audit-only; edit-only unavailable; read-only legacy/incomplete Draft; eligible edit → confirmed receipt/refreshed detail; conflict → server/local comparison and deliberate reconciliation; uncertain create and uncertain update controls; independent history loading/empty/error. Check typography, spacing, active theme contrast, keyboard scroll, focus/error placement, directional icons/value isolation, accessible targets and no scaled-text clipping.

Check the single User Area tile alongside every existing entry/header without redesign; public Directory/CUI-1 media/management entry remains visually unchanged. Confirm all excluded controls absent. Security/auth clearance, generation races and exact params are automated acceptance criteria, not waived by an attractive screenshot. Owner visual PASS, independent focused engineering/security review and Architect acceptance are separate recorded gates.

## 20. Remote deployment and readiness boundary

**REMOTE DEPLOYED DATABASE: UNVERIFIED.** Matching local HEAD/origin/main and accepted migration source are not deployed verification. No remote database/HTTP contact, credentials gathering, provisioning or deployment occurs here; no staff-authoring use is implicitly ready.

Before live console operation, require separately authorized evidence of exact deployed 00026/prerequisites, six RPC signatures/projections/effective ACL, private receipt/helper/API/Realtime non-exposure, append-audit owner-only ACL and canonical CLAIM protection. Trusted accountable staff provisioning must specify real actors/roles/exact capability grants/effective/expiry windows through existing authority; no self-enrollment or application-reviewer inheritance. Require genuine authorized staff/ordinary/anon HTTP smoke, resulting Draft public non-readability, exact replay/conflict/permission behavior and accepted A1 clearance/parsing. Fault-injection rollback/concurrency evidence belongs in isolated disposable environments, not production.

Missing deployed A0 yields a controlled unavailable console; never create SQL/RPC grants or direct table work as fallback. Local UI fixtures must not masquerade as live commercial records. Owner data intake remains governed by Commercial Model §32.5.2; reason codes are context, not consent/ownership proof. Publication/payment/entitlement and M4/M5 remain unavailable even after A1 UI acceptance. Disabling an A1 entry under future explicit authority does not remove protecting receipts/CLAIM isolation or authorize destructive database rollback.

## 21. Architect decisions and unresolved blockers

Adopted from the Owner-supplied Architect decisions: exact three authenticated root routes with /new first; Draft default/name/nine-type read filtering and four-type authoring; 25/Load More/no totals; one list plus shared create/detail/editor and embedded history; one navigation-only Commercial Admin tile; independent R/C/E/A and no-read modes; explicit P0CON reconciliation; exact creation replay/update-uncertain treatment; whole-edit completeness/inactive-reference reconciliation; Arabic RTL/design-token/breakpoint/accessibility requirements. These design requirements are accepted/frozen by the supplied final decision recorded in §23, without implementation authority.

**Architect correction record — 2026-10-08:** the Owner supplies the original audit manifests and accepts the current revised 18-file production allocation as the candidate for final freeze with §§14.1/15.1 rationale. The revised six new/five modified UI-test candidates are retained on source evidence; the two displaced tests are explicitly read-only regressions. The corrected compatibility boundary is A0/HARDEN-1/M1b/M3, with M1a/R09q unchanged, totaling 33 future write paths (16 NEW + 17 MODIFIED). §16 defines the separate governance/compatibility/implementation gates. This records supplied correction decisions, not final document acceptance/freeze or authorization. All accepted technical design in §§3–13/17/19–20 is preserved unchanged.

The preceding correction record is retained as history. §23 supersedes its candidate/pending acceptance state with final ACCEPTED / FROZEN control; the reconciliation, technical requirements, file paths and future gates remain unchanged.

| ID | Unresolved issue / disposition | Required owner/gate |
| --- | --- | --- |
| A1-OPEN-01 — RESOLVED | Original audit paths are supplied; §§14.1/15.1 record exact differences and rationale. The revised 33-path manifest is accepted/frozen under §23; no manifest-provenance or contract-freeze blocker remains. | Contract acceptance/freeze SATISFIED — 2026-10-08; implementation gates remain separate |
| A1-OPEN-02 — RESOLVED AT BOUNDARY LEVEL | A0 is already one of the exact four accepted compatibility paths. §15.2 corrects that set/count and preserves M1a/R09q; §16 supplies concrete separate future recognition/GREEN gates. No additional guard-path decision is pending. | Exact guard mechanics, fresh GREEN and independent review still required in the separately authorized future pass |
| A1-OPEN-03 | Final document acceptance/freeze is SATISFIED under §23. Owner acceptance-governance commit, separate compatibility authorization/review/GREEN/commit and subsequent committed roadmap implementation authorization/final fresh GREEN remain pending. §16's exact non-circular sequence is unchanged; no future commit or GREEN is invented. | Architect + Owner before implementation |
| A1-OPEN-04 | Actual deployed A0/provisioned staff/live readiness remains unverified; review/test agent assignment and gate environment must be supplied under operating model. | Architect/Owner before respective implementation/live gates |

No unspecified backend signature, payload, cursor, DTO or reason is delegated to implementer invention. Routine local view details can be resolved within frozen accepted boundaries, but any new route/provider/file/backend authority or persistence mechanism is a STOP. Default routing remains the operating model: routine UI to its designated implementer; security/auth/concurrency to Codex and independent review; Architect owns freeze/acceptance, User owns final Git. No team role renegotiation or self-acceptance.

Policy carry-forward stays unchanged: OQ-40/OQ-82 receipt/audit retention/never-owned Draft disposition; OQ-72 genuine duplicate/merge policy; OQ-77/OQ-83 broader RBAC/invitation semantics; OQ-79 ownership/disputes; required-field/publication/verification residuals and M4/pre-M5 reconciliation/OQ-84. This acceptance/freeze resolves/reclassifies none of them. No guessed prices, commercial eligibility, retention/cleanup, ownership or legal evidence policy.

## 22. Implementation gate conditions and drafting preservation

Before implementation, all conditions must be satisfied:

1. **Contract acceptance/freeze SATISFIED — 2026-10-08:** the Architect accepts/freezes the corrected document, UI/security decisions and **33-path manifest (16 NEW + 17 MODIFIED)** under §23. This condition does not satisfy the pending Owner commit, compatibility or implementation gates. Amendments to frozen history remain explicit append-only addenda under separate authority.
2. Owner commits the acceptance/freeze governance with implementation NO/CURRENT NONE, followed by the separately authorized compatibility-only governance record before guard edits, as §16 steps 2–3 require. No future record is silently accepted or authorized by this correction.
3. Complete and Owner-commit the separately authorized four-guard compatibility work after focused GREEN with unchanged M1a/R09q and independent review (§16 steps 4–5). Separately review/accept/Owner-commit the exact implementation authorization and the historical/current predicate separation within §16 step 6's bounded coordinated pass if needed. Step 7's committed preimplementation GREEN must prove the live AUTHORIZED CUI-2A1 predicate passes with zero A1 production/test changes and rejects unauthorized additions. Only then may implementation change the exact 18 production plus 11 focused/UI-test paths; guard-source changes remain restricted to separately authorized compatibility passes. Preserve historical pins, commercial closure and ordinary UI locks; no broad R10.5-D authorization or guard edits under this acceptance/freeze alone.
4. Preflight rechecks exact HEAD/local origin/main, index, dirty protected baseline, frozen governing versions, six existing RPC mappings, 26 migrations, exact new/modified path existence and retained A0/security/CUI-1 invariants. Drift/collision/out-of-boundary dependency requires STOP, not renaming/adoption/retry.
5. Dedicated architecture/clearance/error/mutation tests and UI/visual criteria remain mandatory, together with both §16 preimplementation and postimplementation focused GREEN gates. Final acceptance verifies the actual resulting Owner-committed A1 source identities, exact implementation changed-path set bounded to the 29 frozen implementation paths, required new files and preserved unrelated/protected sources; nonexistent future implementation hashes are never preimplementation prerequisites. Positive and adversarial checks use the same live/current predicate, retain strict historical pins and preserve unchanged M1a/R09q. Approved focused regressions run without repository-wide expansion; required reviewers and Owner visual QA are assigned before acceptance, with no inferred PASS.
6. Remote production use remains blocked pending §20's separately authorized readiness/provisioning evidence, even if local A1 implementation is accepted.

Current acceptance/freeze write boundary is **exactly two governance paths**: this existing untracked contract and one append-only section in `docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md`. No lib/test/SQL/Supabase, other contract/report, dependency or configuration change; no implementation or remote operation. Validation must reread both documents, verify matching acceptance/NO/NONE controls, unchanged technical requirements/manifest paths and byte-identical §16, and prove every prior roadmap byte remains intact. Run `git rev-parse HEAD`, `git rev-parse origin/main`, `git diff --cached --name-only`, `git status --porcelain=v1 --untracked-files=all` and `git diff --check`; compare protected hashes/entry diff and inspect this untracked Markdown's trailing whitespace/final newline. Expected end state is the unchanged protected baseline, this same untracked contract and the single roadmap append, empty index and unchanged baseline HEAD/local origin/main. Actual validation belongs in the final governance report; no implementation-test or freeze-composition GREEN is implied.

## 23. Final Architect acceptance and contract freeze — 2026-10-08

Authority: Owner-provided **CUI-2A1 Final Architect Acceptance + Contract Freeze**, supplying the final independent pre-freeze contract-review outcome **PASS with zero CRITICAL, HIGH or MEDIUM findings** and the Architect decision **ACCEPTED — 2026-10-08**. This records that supplied decision; it is not agent self-acceptance, a newly executed independent review, implementation acceptance, a test/GREEN claim or deployed readiness evidence.

**DOCUMENT_STATUS: ACCEPTED — CANONICAL CUI-2A1 IMPLEMENTATION CONTRACT. ARCHITECT_ACCEPTANCE: ACCEPTED — 2026-10-08. FREEZE_STATE: FROZEN. CUI2A1_STATE: CONTRACT FROZEN — IMPLEMENTATION NOT AUTHORIZED.** The corrected V1 specification, its original-versus-revised reconciliation and final pre-freeze predicate clarification are accepted/frozen. This header/record supersedes earlier draft/candidate/pending status wording only. Historical correction and §16 chronology remain intact; no technical clause, manifestation of authority, payload, DTO, permission, route, UI decision, security invariant, test requirement or exclusion changes.

The exact frozen future manifest is **33 distinct paths: 18 production (10 NEW + 8 MODIFIED), six NEW focused tests, five MODIFIED UI tests, and four MODIFIED compatibility guards; total 16 NEW + 17 MODIFIED**. Implementation work, if separately authorized later, remains bounded to the 18 production plus 11 focused/UI-test paths. The separate four-guard compatibility boundary is exactly A0, HARDEN-1, M1b and M3 as listed in §15.2; M1a and R09q remain **READ-ONLY / UNMODIFIED**. Freeze creates no write authority over any of these paths. Original audit alternatives/displaced read-only regressions remain evidence/regression dependencies, not extra permitted paths.

**IMPLEMENTATION_AUTHORIZED: NO. COMMERCIAL_CURRENT_SLICE: NONE. COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO.** CUI-2A0, CUI-1 and M3 remain CLOSED; M4/M5 remain NOT AUTHORIZED; R10.5-D remains AUDIT-ONLY / IMPLEMENTATION NO. Backend/publication/entitlement/payment authority deltas remain ZERO. No Flutter implementation, static guard change, SQL/migration/RPC, production database operation, payment/publication/entitlement, ownership/invitation or broader UI implementation is authorized by this acceptance.

The entire §16 security gate sequence is preserved byte-identically. Contract review/acceptance and recording the freeze portion of its governance stage are complete; Owner governance commit and all subsequent compatibility/implementation gates remain pending. After independent freeze-diff review and the Owner's governance commit, the next future action is a **SEPARATELY AUTHORIZED compatibility-only governance pass**, followed by the exact separate compatibility authorization, focused GREEN, independent review and Owner commit gates. Later implementation authorization and both preimplementation/postimplementation focused GREEN remain mandatory. No future acceptance commit identity or circular source hash is inserted here; actual commit identities are recorded only after they exist.

The four current guards may reject this new accepted documentation until the future separately authorized compatibility correction. That transitional condition is disclosed as **LOW** and supplies no waiver, implementation authority or permission to alter guards now. No guard is modified, no implementation/production/database tests are run, and no GREEN is claimed for the new freeze composition in this pass. **REMOTE DEPLOYED DATABASE: UNVERIFIED.** Repository contract acceptance does not establish deployment, provisioning or live readiness.

Only this contract and one chronological Master Roadmap append change in this governance pass. Prior roadmap bytes, other contracts/reports, lib/tests/SQL/Supabase and the protected dirty baseline remain untouched. No stage, commit, push, reset, revert, clean or stash; the User retains Git ownership and will commit after focused independent governance review.

**ACCEPTED / FROZEN — IMPLEMENTATION_AUTHORIZED: NO.**
