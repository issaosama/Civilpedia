# Civilpedia — CUI-2A0 append_audit_log ACL Security Addendum V1

```text
DOCUMENT_STATUS: ACCEPTED — CUI-2A0 SECURITY ADDENDUM
ARCHITECT_ACCEPTANCE: ACCEPTED — 2026-10-07
FREEZE_STATE: FROZEN
DOCUMENT_VERSION: 1
RECORD_DATE: 2026-10-07
MODE: DOCUMENTATION / GOVERNANCE ONLY — NO IMPLEMENTATION IN THIS PASS
ADDENDUM_IMPLEMENTATION_AUTHORIZED: YES — WITHIN CUI-2A0 ONLY
CUI2A0_CONTRACT_STATE: ACCEPTED / FROZEN
CUI2A0_IMPLEMENTATION_AUTHORIZED: YES
COMMERCIAL_CURRENT_SLICE: CUI-2A0 — Admin Business Draft Authority Foundation
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES — CUI-2A0 ONLY
CUI2A0_EXECUTION_STATE: BLOCKED — PREDECESSOR SECURITY ACL DISCREPANCY
IMPLEMENTATION_RESUME_GATE: OWNER COMMIT OF THIS ADDENDUM AND ROADMAP RECORD
AUTHORIZED_STRATEGY: STRATEGY 1 — ACL CORRECTION INSIDE AUTHORIZED MIGRATION 00026
AUTHORIZED_MIGRATION: 00026_commercial_admin_business_draft_foundation.sql
MAXIMUM_IMPLEMENTATION_SECURITY_TEST_FILES: 8
CUI1_STATE: CLOSED
M3_STATE: CLOSED
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
CUI2A1_STATE: NOT AUTHORIZED
R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO
PUBLICATION_AUTHORITY_DELTA: ZERO
ENTITLEMENT_AUTHORITY_DELTA: ZERO
PAYMENT_AUTHORITY_DELTA: ZERO
UI_AUTHORITY_DELTA: ZERO
PREDECESSOR_MIGRATION_CHAIN: VULNERABLE — CONFIRMED LOCALLY ON FRESH 00001–00025 BUILD
REMOTE_DEPLOYED_DATABASE: UNVERIFIED
GIT_OWNER: User
```

## 1. Supplied authority, accepted finding and execution gate

Authority: Owner-provided **CIVILPEDIA — CUI-2A0 append_audit_log ACL SECURITY ADDENDUM — GOVERNANCE-ONLY PASS**, supplying the Architect's acceptance of the independent forensic finding and the exact security decision below. This document records that supplied acceptance; it does not self-accept implementation, independently rerun the forensic review, assert new test PASS results or certify deployed readiness.

The [original frozen CUI-2A0 contract](CIVILPEDIA_COMMERCIAL_CUI2A0_ADMIN_BUSINESS_DRAFT_AUTHORITY_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md) remains intact. The [Master Roadmap](../CIVILPEDIA_V1_MASTER_ROADMAP.md) remains the current authorization SSOT. Entry HEAD and local origin/main both equal a813b8c99309757bd7d03ac96dde0e7c12cfed79; this is local reference evidence, not a remote database or fresh remote Git verification.

**Codex STOP is accepted as correct.** The predecessor ACL discrepancy is confirmed **HIGH**. The supplied independent forensic review proved that a fresh database built from committed migrations 00001–00025 grants direct EXECUTE on public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text) to anon, authenticated and service_role; PUBLIC itself does not retain EXECUTE. Both anon and authenticated were independently proven able to directly insert audit events.

The accepted forensic finding establishes that no legitimate client flow requires direct append_audit_log EXECUTE. All legitimate production callers are internal postgres-owned SECURITY DEFINER functions. Revoking direct client EXECUTE was proven not to break their nested legitimate calls. These are supplied accepted forensic findings, not tests executed by this documentation pass.

CUI-2A0 remains ACTIVE and IMPLEMENTATION AUTHORIZED — CUI-2A0 ONLY, but execution remains security-blocked until the Owner commits this addendum and its accompanying roadmap record. After that commit, a later implementation pass may resume under the frozen original contract plus this addendum, rechecking the new committed governance baseline and all retained preflight/STOP conditions. This governance pass does not resume implementation or modify the partial working tree.

## 2. Exact ACL correction — Strategy 1

**STRATEGY 1 — ACL correction inside authorized migration 00026** is the supplied Architect decision. The future implementation of supabase/migrations/00026_commercial_admin_business_draft_foundation.sql is authorized to execute exactly:

```sql
REVOKE EXECUTE ON FUNCTION
public.append_audit_log(
  uuid,
  text,
  text,
  uuid,
  jsonb,
  jsonb,
  text
)
FROM PUBLIC, anon, authenticated, service_role;
```

Place this exact REVOKE before 00026's security preflight. The preflight must then assert the newly authorized complete expected ACL, including effective/inherited privileges rather than only a textual PUBLIC revoke:

| Principal | Expected direct EXECUTE after correction |
| --- | --- |
| postgres / function owner | Allowed |
| PUBLIC | Denied |
| anon | Denied |
| authenticated | Denied |
| service_role | Denied |

There is no service_role re-grant, client exception, role-name bypass or new audit execution path. Owner authority remains intentional so existing postgres-owned SECURITY DEFINER callers can continue to append audit events internally.

The normalization, preflight and all remaining 00026 statements must execute in the same runner-owned migration transaction. A later preflight, implementation or final-assertion failure must roll back the ACL correction together with all other 00026 effects. No standalone remediation, embedded COMMIT, transaction=false, partial application or blind automatic mutation retry is authorized.

This is the sole specifically authorized predecessor ACL normalization. Any other unreviewed privilege, owner or schema discrepancy still requires the original STOP behavior; do not broaden this exception to unrelated functions or global configuration.

## 3. Function and predecessor preservation

This is ACL metadata hardening only. Freeze all of the following:

- Exact signature remains public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text), with its existing return type unchanged.
- Function body and prosrc remain identical to the committed 00016 definition.
- Owner remains postgres.
- SECURITY DEFINER state remains unchanged.
- Existing search_path remains unchanged; do not apply the new A0 functions' search_path rule to this legacy helper.
- public.audit_logs schema remains unchanged.
- Migration 00016_business_application_server_mutations.sql and all migrations 00001–00025 remain byte-identical.
- No replacement/recreation of the append helper, new audit helper or parallel audit path.

This addendum supplements only the original contract's §§14–16 preservation/preflight requirements to allow the exact append helper ACL correction, and its §§19–20 file/evidence boundary to add the security-regression support below. It does not rewrite the original frozen contract or waive any other technical requirement. The original six A0 public RPCs, two private helpers, receipt semantics, canonical CLAIM hardening, four-type allowlist, complete-location eligibility, concurrency and sanitized atomic audit requirements remain mandatory.

## 4. Mandatory regression evidence for resumed implementation

All requirements below are future implementation evidence. None is claimed as newly executed in this governance pass.

| ID | Required security evidence |
| --- | --- |
| ACL-01 | PUBLIC has no direct EXECUTE grant on append_audit_log. Assert actual ACL metadata, not only source text. |
| ACL-02 | anon cannot directly execute append_audit_log; assert effective privilege denial. |
| ACL-03 | authenticated cannot directly execute append_audit_log; assert effective privilege denial. |
| ACL-04 | service_role cannot directly execute append_audit_log; no re-grant or inherited bypass. |
| ACL-05 | postgres / owner retains EXECUTE and can append through the existing helper. |
| ACL-06 | Direct unauthorized calls fail with permission denial / SQLSTATE 42501 and create no audit event. |
| ACL-07 | Legitimate existing postgres-owned SECURITY DEFINER callers still write their expected audit events through the unchanged helper. |
| ACL-08 | Audit failure still rolls back protected mutations; retain the original create/update audit-failure rollback requirements. |
| ACL-09 | Function owner remains postgres. |
| ACL-10 | SECURITY DEFINER state remains unchanged. |
| ACL-11 | Existing search_path remains unchanged. |
| ACL-12 | Function body / prosrc remains identical to the committed 00016 definition. |
| ACL-13 | Migrations 00001–00025 remain byte-identical. |
| ACL-14 | No unauthorized client can forge arbitrary actor/action/target/before/after/reason audit data through the append helper. |

Also prove migration atomicity for the ACL correction: a later 00026 failure restores the predecessor ACL and leaves no partial A0 effects; a successful migration commits the complete hardened ACL with the rest of 00026. This rollback probe is confined to the original contract's isolated disposable test environment.

test/v1_r09q_security_matrix_test.dart is explicitly authorized as **CUI-2A0 security-regression support**, solely for the narrowly necessary correction from textual PUBLIC-revoke coverage to complete effective ACL coverage. Its existing unrelated security protections must remain intact. Source/static evidence does not substitute for actual SQL privilege, direct-call, nested-caller or mutation-rollback evidence. All original T01–T34 / T32A–H gates remain required.

## 5. Exact maximum implementation/security/test boundary — eight files

The original maximum seven-file boundary is expanded by exactly one existing test path. After the Owner's addendum commit, the maximum authorized CUI-2A0 implementation/security/test boundary is exactly:

```text
supabase/migrations/00026_commercial_admin_business_draft_foundation.sql
supabase/tests/commercial_cui2a0_admin_business_draft_foundation_test.sql
test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
test/commercial_m1a_private_catalog_migration_test.dart
test/commercial_harden1_public_plans_exposure_migration_test.dart
test/commercial_m1b_catalog_reference_data_migration_test.dart
test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart
test/v1_r09q_security_matrix_test.dart
```

This does not require every path to change. Changes are permitted only where required by the original frozen contract and this addendum. Existing composed guards may recognize only this exact Owner-committed addendum, roadmap record, newly authorized support path and bounded ACL delta, while retaining historical pins and negative protections. No ninth implementation/security/test file, fifth commercial guard, additional migration or production lib file is authorized.

The two documentation paths in this governance pass are separately governed; they do not create additional implementation authority or permit this pass to modify any of the eight paths above.

## 6. Separately deferred findings — no remediation authority

Record the supplied findings without authorizing their correction:

| Deferred finding | Preserved boundary |
| --- | --- |
| Public-schema default-privilege gap | Future postgres-created public functions may inherit EXECUTE for client roles. Broader public-schema default-privilege remediation requires separate Architect authority. |
| Legacy sibling RPC ACL permissiveness from 00016 | Do not change sibling RPC ACLs under this addendum or CUI-2A0. |
| region_preferences direct INSERT ACL | RLS currently provides the effective deny. Do not change region_preferences ACL/RLS under this addendum or CUI-2A0. |

In particular, no ALTER DEFAULT PRIVILEGES IN SCHEMA public correction is authorized. The exact append helper REVOKE does not close these deferred findings. The original A0 requirements for explicitly secured new objects and preserved default-privilege hardening remain active.

## 7. Remote status and retained commercial exclusions

**PREDECESSOR MIGRATION CHAIN: VULNERABLE — CONFIRMED LOCALLY ON FRESH 00001–00025 BUILD.**

**REMOTE DEPLOYED DATABASE: UNVERIFIED.**

No remote production connection, deployment, remediation or staff provisioning is authorized by this pass. Local forensic evidence is not deployed-state certification.

M4, M5 and CUI-2A1 remain NOT AUTHORIZED. Publication, entitlement, payment and UI authority deltas remain ZERO. CUI-1 and M3 remain CLOSED; R10.5-D remains AUDIT-ONLY / IMPLEMENTATION NO. No wider commercial, ownership, publication, verification, media, Branch, default-privilege or sibling-RPC authority is granted.

## 8. Governance-only write and preservation boundary

This pass creates only this addendum and appends only the chronological security-addendum record to docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md. Every previous roadmap byte and the original frozen contract are preserved.

All entry partial implementation files, modified commercial guards, protected dirty tests, OpenCode_Usage_Report.txt and artifacts remain byte-identical to entry. Compilation errors in the partial implementation are not repaired in this pass.

No 00026/test/SQL/Supabase/lib modification, migration execution, backend operation, test run, staging, commit, push, reset, revert, clean or stash occurs in this governance pass. Documentation/Git/hash validation is separate from implementation/security regression execution. User retains Git ownership. Implementation remains security-blocked pending the Owner's commit; acceptance of this addendum is not implementation acceptance or closure.
