# Civilpedia — Commercial CUI-2A0 Closure Record

```text
SLICE: CUI-2A0 — Admin Business Draft Authority Foundation
RECORD_DATE: 2026-10-08
MODE: GOVERNANCE / DOCUMENTATION ONLY
CUI2A0_STATE: CLOSED
CUI2A0_IMPLEMENTATION_STATE: ACCEPTED / CLOSED
CUI2A0_IMPLEMENTATION_COMMIT: 41276132ba6a1606cd779f5ce92473bacfbcc7c8
CUI2A0_CONTRACT_STATE: ACCEPTED / FROZEN
CUI2A0_SECURITY_ADDENDUM: SATISFIED
CUI2A0_ARCHITECT_IMPLEMENTATION_ACCEPTANCE: PASS
APPEND_AUDIT_LOG_ACL_STATE: ACCEPTED — OWNER-ONLY DIRECT EXECUTE
LOCAL_MIGRATION_CHAIN_IMPLEMENTATION: VERIFIED
REMOTE_DEPLOYED_STATE: UNVERIFIED
REMOTE_DEPLOYED_DATABASE: UNVERIFIED
COMMERCIAL_LAST_CLOSED_SLICE: CUI-2A0 — Admin Business Draft Authority Foundation
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
CUI2A0_IMPLEMENTATION_AUTHORIZED: NO — SLICE CLOSED
CUI1_STATE: CLOSED
M3_STATE: CLOSED
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
CUI2A1_STATE: NOT AUTHORIZED
R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO
PRODUCTION_LIB_DELTA: ZERO
UI_AUTHORITY_DELTA: ZERO
ENTITLEMENT_AUTHORITY_DELTA: ZERO
PUBLICATION_AUTHORITY_DELTA: ZERO
PAYMENT_AUTHORITY_DELTA: ZERO
GIT_OWNER: User
```

## Authority and final closure decision

Authority: Owner-provided **CIVILPEDIA — COMMERCIAL CUI-2A0 FINAL CLOSURE RECORD + ROADMAP CLOSURE**, dated in this record on 2026-10-08. The Owner supplies completed independent verification and Architect implementation acceptance. This document records that accepted decision; it is not agent self-acceptance, a new independent review, a fresh test run or deployment certification.

Controlling records:

- [Frozen CUI-2A0 Implementation Contract V1](../contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_ADMIN_BUSINESS_DRAFT_AUTHORITY_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md).
- [Committed append_audit_log ACL Security Addendum V1](../contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_APPEND_AUDIT_LOG_ACL_SECURITY_ADDENDUM_V1.md).
- [Master Roadmap](../CIVILPEDIA_V1_MASTER_ROADMAP.md), including the chronological contract freeze, implementation authorization, security addendum and this final closure.
- Accepted implementation commit: `41276132ba6a1606cd779f5ce92473bacfbcc7c8`.

Local HEAD and the local origin/main reference both equal that implementation commit at closure entry. This is repository-reference evidence, not a fresh remote Git or deployed-database verification. The committed implementation was inspected read-only; its seven-file delta contains no production lib/** path.

**CUI-2A0 is CLOSED. CUI2A0_IMPLEMENTATION_STATE is ACCEPTED / CLOSED.** The Security Addendum is SATISFIED. No unresolved CUI-2A0 acceptance blocker is carried forward by the supplied final acceptance.

The frozen contract and Security Addendum remain byte-identical, including their historical authorization and security-blocked wording. The appended roadmap closure supersedes prior active implementation/security-blocked controls for the current slice state only. It does not rewrite history, change frozen technical clauses or reopen the accepted implementation.

## Accepted implementation scope

The accepted scope is the bounded backend Admin Business Draft Authority Foundation:

| Accepted component | Final scope |
| --- | --- |
| Forward migration | 00026_commercial_admin_business_draft_foundation.sql; complete atomic implementation on the accepted predecessor chain. |
| Private namespace and receipt | business_admin_private and business_admin_private.draft_create_requests; private actor/request create receipt and canonical fingerprint for historical replay. |
| Private helpers | has_staff_business_permission(text) and normalize_draft_payload(jsonb); permission-chain checks and bounded structural normalization. |
| Staff permission references | business_entities.read, business_entities.create_draft, business_entities.edit_draft and business_entities.read_audit; independent capabilities without automatic staff/role grants. |
| Six public CUI-2A0 RPCs | get_staff_business_capabilities; list_staff_business_entities; get_staff_business_entity_detail; staff_create_business_draft; staff_update_business_draft; list_staff_business_entity_audit. |
| Canonical CLAIM hardening | Existing guard_claim_application_insert replacement with preserved trigger binding, target-row locking, early absent-target denial and receipt-protected A0 denial. |
| Three bounded indexes | idx_directory_entities_cui2a0_staff_page; idx_audit_logs_cui2a0_entity_page; uq_audit_logs_cui2a0_draft_create. |
| Security | Explicit ACL/RLS and SECURITY DEFINER boundaries; private helper/receipt non-exposure; the exact append_audit_log ACL correction. |
| Evidence support | SQL runtime suite and Dart/static compatibility/security guards, including the narrow R09q security support. |

Canonical identity remains public.directory_entities.id. Accepted authoring is limited to company, contractor, supplier and store, with ownerless, non-public Draft/unverified/unclaimed creation; bounded scoped children; actor-scoped create replay; optimistic update versions; complete-location eligibility; and sanitized transactional audit. Existing non-A0 CLAIM and nine-type NEW application behavior remain preserved.

The committed implementation changes exactly these seven paths:

```text
supabase/migrations/00026_commercial_admin_business_draft_foundation.sql
supabase/tests/commercial_cui2a0_admin_business_draft_foundation_test.sql
test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
test/commercial_harden1_public_plans_exposure_migration_test.dart
test/commercial_m1b_catalog_reference_data_migration_test.dart
test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart
test/v1_r09q_security_matrix_test.dart
```

M1a is unchanged. The accepted scope has **no production `lib/**` delta** and no UI delta. Entitlement, publication and payment authority deltas remain **ZERO**. Closure grants no staff provisioning, active-entity editing, ownership/invitation, media, Branch, subscription-enforcement or broader commercial authority.

## Accepted security outcome

**append_audit_log ACL: ACCEPTED — OWNER-ONLY DIRECT EXECUTE.**

| Principal | Accepted direct EXECUTE |
| --- | --- |
| PUBLIC | NO EXECUTE |
| anon | NO EXECUTE |
| authenticated | NO EXECUTE |
| service_role | NO EXECUTE |
| postgres / owner | EXECUTE |

The accepted local final ACL is `{postgres=X/postgres}`. Migration 00026 implements the exact Security Addendum REVOKE before the ACL preflight, in the same migration transaction, without a service_role regrant. Late migration failure restores the predecessor ACL together with the rest of the migration rollback.

The helper's committed signature, body/prosrc, postgres owner, SECURITY DEFINER state, existing search_path=public, pg_temp, void return and audit_logs schema remain preserved. Legitimate owner-executed internal audited callers retain their existing path. Direct client audit forgery is denied; create/update audit failure rolls back the complete protected mutation.

This records the accepted local migration-chain/security outcome. It does not assert that a remote database has received 00026 or that remote privileges match this state.

## Accepted verification and review evidence

The following evidence is retained from the preceding Codex implementation evidence in conversation and the Owner-supplied final closure decision. No test, SQL suite, HTTP request, migration or review is rerun in this governance-only pass. No numeric test counts or new persisted independent-review filenames are asserted.

| Evidence | Accepted outcome |
| --- | --- |
| Codex focused Dart/static verification | GREEN |
| Codex SQL runtime/security verification | GREEN |
| Codex concurrency and real-session race verification | GREEN |
| Codex genuine local HTTP/RPC evidence | GREEN |
| Codex migration rollback/atomicity evidence | GREEN |
| Codex production/lib preservation evidence | No production/lib delta |
| Independent Big Pickle verification | PASS — CUI-2A0 IMPLEMENTATION VERIFIED |
| Independent adversarial review | PASS — CUI-2A0 IMPLEMENTATION SAFE TO ACCEPT |
| Architect implementation acceptance | PASS |

The accepted evidence includes permission/ACL/RLS boundaries, bounded payloads, create replay, optimistic update conflicts, complete-location exclusion, audit privacy and rollback, CLAIM isolation/races, legacy CLAIM/NEW compatibility, migration atomicity and predecessor preservation. These are accepted implementation results, not a fresh GREEN claim against the documentary closure append.

## Known accepted non-blocking observations

| Observation | Accepted disposition |
| --- | --- |
| Audit wrapper SQLSTATE classification | The wrapper may reclassify some transaction/deadlock SQLSTATEs, including 40001 / 40P01, to P0AUD while preserving rollback behavior. Accepted as non-blocking; no wrapper or SQL change is authorized here. |
| Minor static-guard coverage limitations | Adversarial review identified limited static coverage without an exploitable authority path. Accepted as non-blocking/deferred; no guard change is authorized here. |

These observations **do not reopen CUI-2A0** and do not constitute new implementation authority.

## Deferred security findings outside closure

The following remain explicitly outside CUI-2A0 closure and require future explicit Architect hardening authority:

1. Supabase public-schema default privilege posture for future postgres-created public functions.
2. Legacy sibling RPC ACL permissiveness from earlier migrations.
3. region_preferences ACL/RLS posture.

CUI-2A0 did not silently remediate these findings. The accepted append_audit_log correction does not close them. This record authorizes no public-schema default-privilege, sibling-RPC or region_preferences remediation.

## Repository closure and deployment are separate

```text
LOCAL MIGRATION-CHAIN / IMPLEMENTATION: VERIFIED
REMOTE DEPLOYED DATABASE: UNVERIFIED
```

Repository implementation closure does not imply production migration, remote deployment, remote staff provisioning or live readiness. No remote production operation occurs or is authorized by this closure pass. Production/deployment readiness remains separately governed.

## Follow-on authorization

```text
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
COMMERCIAL_CONTROL: CUI-2A0 CLOSED — NO NEXT COMMERCIAL IMPLEMENTATION SLICE AUTHORIZED
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
CUI2A1_STATE: NOT AUTHORIZED
R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO
```

CUI-1 and M3 remain CLOSED. No next commercial slice or ordinary UI implementation is automatically opened. A later Architect authorization record must explicitly identify and authorize the next slice; this closure supplies no such authority.

## Documentary preservation and Git ownership

This closure pass changes exactly this new report and one chronological append to the Master Roadmap. Every prior roadmap byte is retained. The frozen contract, Security Addendum, migrations, SQL/runtime tests, Dart/static/security guards, production lib/** and all other entry files remain unchanged.

Protected entry state:

```text
 M test/a5_6_profile_bootstrap_test.dart
 M test/v1_r08_cloud_profile_foundation_test.dart
 M test/v1_r08_profile_edit_screen_widget_test.dart
?? OpenCode_Usage_Report.txt
?? artifacts/r10_4a/home_dark.png
?? artifacts/r10_4a/home_light.png
```

The protected baseline remains byte-identical. No implementation, SQL/test/lib/Supabase modification, backend operation, migration/test execution, staging, commit, push, reset, revert, clean or stash occurs in this pass. Before the Owner's closure commit, HEAD and local origin/main remain `41276132ba6a1606cd779f5ce92473bacfbcc7c8`; staging is EMPTY. The Owner retains final Git ownership.

This records the supplied accepted implementation closure. The closure document and roadmap append are prepared for Architect verification.
