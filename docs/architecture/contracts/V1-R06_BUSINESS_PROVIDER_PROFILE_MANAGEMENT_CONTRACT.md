# CIVILPEDIA V1-R06 — BUSINESS / PROVIDER PROFILE MANAGEMENT
## CONTRACT FREEZE + PART 1 SERVER IMPLEMENTATION

You are Codex.

ROLE:
Server/security implementer for PART 1 of:

V1-R06 — Business / Provider Profile Management

CONTRACT_ID:
V1-R06-CONTRACT-v1

Recommended effort:
HIGH

This is security-sensitive work.

You are authorized to implement PART 1 only:
Secure server read/mutation authority.

Do NOT implement Flutter management UI yet.

Owner alone stages / commits / pushes.

==================================================
0. ARCHITECT DECISION
==================================================

The V1-R06 micro-audit is accepted.

Final contract direction:

OPTION B —
SMALL SECURE SERVER MUTATION LAYER
+
FLUTTER MANAGEMENT UX

Implementation shape:

PART 1 — Codex
Secure DB/RPC/validation/concurrency/audit foundation

PART 2 — Big Pickle
Flutter management gateway/state/UI/routing/cache refresh

Do NOT work concurrently with Big Pickle.

==================================================
1. CANONICAL BASELINE
==================================================

Repository:

D:\Civilpedia

Expected branch:

main

Expected HEAD:

df70fb811a9e5940a779dca7d0252f32cfa9dd86

Expected commit:

df70fb8
feat(directory): complete V1-R05 cloud integration

Expected:

HEAD == origin/main

Expected working tree:

?? OpenCode_Usage_Report.txt

Never touch:

OpenCode_Usage_Report.txt

Roadmap expected:

CURRENT_PHASE_ID: V1-R06
CURRENT_PHASE_TITLE: Business / Provider Profile Management
CURRENT_PHASE_CONTRACT: NOT_FROZEN
IMPLEMENTATION_AUTHORIZED: NO

Before implementation:

1. Persist this frozen contract faithfully at:

docs/architecture/contracts/V1-R06_BUSINESS_PROVIDER_PROFILE_MANAGEMENT_CONTRACT.md

2. Update roadmap phase controls to:

CURRENT_PHASE_CONTRACT: V1-R06-CONTRACT-v1
IMPLEMENTATION_AUTHORIZED: YES

Do NOT close V1-R06.
Do NOT promote V1-R07.

==================================================
2. PHASE GOAL
==================================================

V1-R06 allows an authorized business OWNER or ADMIN to manage the public profile of an EXISTING canonical Directory entity.

Canonical identity:

public.directory_entities.id

Canonical management authority:

business_memberships

Human authority:

auth.uid()

Authorized roles:

OWNER
ADMIN

Unauthorized:

MEMBER
guest
unrelated authenticated users

No ownership inference from:

email
name
phone
local profiles
Directory cache
legacy sb_profiles

==================================================
3. SERVER AUTHORIZATION
==================================================

Reuse:

has_business_management_access(p_entity_id uuid)

It already represents:

OWNER OR ADMIN

for the supplied canonical entity.

Do NOT duplicate membership authorization logic unless technically unavoidable.

All client-facing management RPCs:

- SECURITY DEFINER
- use auth.uid()
- explicit safe search_path
- revoke PUBLIC/default execution
- no anon execution
- authenticated only

No service_role in Flutter.

Do NOT grant direct INSERT/UPDATE/DELETE privileges on public Directory tables.

==================================================
4. REQUIRED MIGRATION
==================================================

Create the next migration after 00019.

Expected:

00020_<appropriate_profile_management_name>.sql

Keep it SMALL and ADDITIVE.

Do NOT add new tables unless repository reality proves absolutely mandatory.

Expected DB classification:

SMALL ADDITIVE MIGRATION REQUIRED

==================================================
5. MANAGEMENT READ RPC
==================================================

Add a narrowly scoped client-facing RPC conceptually equivalent to:

get_managed_business_profile(p_entity_id uuid)

Purpose:

Return the authoritative management projection for an existing business that the current user may manage.

This RPC is required because public RLS may hide:

draft
inactive
suspended

entities.

Authorization:

1. auth.uid() must exist
2. target entity must exist
3. caller must have OWNER/ADMIN management access
4. unauthorized access fails closed

Do NOT leak whether a guessed UUID belongs to a business beyond the established typed-error convention.

Use existing project SQLSTATE conventions where possible:

P0AUT — unauthenticated
P0PER — unauthorized
P0NOT — not found
P0DAT — invalid data/reference

==================================================
6. FROZEN MANAGEMENT PROJECTION
==================================================

Return the minimum authoritative management data needed for Part 2.

Preferred shape may be JSONB if consistent with repository conventions.

It must contain:

ENTITY
- id
- entity_type
- name
- description
- lifecycle_status
- verification_status
- claim_status
- created_at
- updated_at

CONTACTS
- id if useful for read projection
- contact_type
- value
- is_primary

PRIMARY LOCATION
- id if useful
- region_id
- region code
- region name_ar
- region name_en
- address
- latitude
- longitude
- is_primary

CATEGORIES
- category_id
- code
- name_ar
- name_en
- is_primary

Existing public media may remain read-only and does NOT need mutation metadata.

Do NOT return:

membership roster
private user details
application metadata
staff data
payment/subscription data

==================================================
7. FROZEN EDITABILITY
==================================================

OWNER/ADMIN editable:

directory_entities:
- name
- description

contacts:
- bounded contact list using existing contact types

primary location only:
- region_id
- address
- latitude
- longitude

categories:
- assignments
- at most one primary assignment

NOT editable:

- id
- entity_type
- lifecycle_status
- claim_status
- created_at
- updated_at
- ownership/membership
- taxonomy rows
- additional locations
- media

verification_status is NEVER a client parameter.

It may change only through the frozen derived server rule below.

==================================================
8. VERIFICATION SIDE-EFFECT POLICY
==================================================

This is an explicit Architect decision.

The client MUST NOT submit verification_status.

Server-derived rule:

If current:

verification_status = 'verified'

AND the mutation materially changes any of:

- entity name
- primary region_id
- primary address
- primary latitude
- primary longitude

THEN server sets:

verification_status = 'pending'

within the same transaction.

Changes only to:

- description
- contacts
- category assignments

MUST NOT alter verification_status.

If current verification state is:

unverified
pending
rejected
suspended

preserve it during V1-R06 profile editing.

Entity type remains immutable.

Claim status remains unchanged.

Lifecycle status remains unchanged.

This derived transition is server-only.

V1-R07 will own staff verification/review operations.

==================================================
9. MUTATION RPC
==================================================

Add one narrow atomic mutation RPC conceptually equivalent to:

update_managed_business_profile(...)

The precise PostgreSQL signature may follow repo conventions, but its logical payload must include:

- p_entity_id uuid
- p_expected_updated_at timestamptz
- name
- description
- contacts
- primary_location
- categories

Do NOT accept arbitrary full-row JSON that permits status-field injection.

JSON child payloads are acceptable if each allowed key is explicitly validated.

Reject unknown keys.

Do not accept client-supplied:

entity_id inside children
owner/user IDs
status fields
timestamps
child rows targeting another business

==================================================
10. VALIDATION LIMITS
==================================================

Freeze the following V1 bounds.

NAME
- required
- trimmed
- 1–160 characters

DESCRIPTION
- nullable
- trimmed
- max 2000 characters

ADDRESS
- nullable
- trimmed
- max 500 characters

CONTACT COUNT
- maximum 10 total

CATEGORY COUNT
- maximum 10 unique assignments

EMAIL
- max 254 characters
- basic valid email format

WEBSITE
- max 2048 characters
- HTTP or HTTPS only

PHONE / WHATSAPP
- trimmed
- bounded to max 32 characters
- reject clearly invalid/empty values
- allow international/local formatting characters reasonably required for real phone input
- do not impose an Iraq-only prefix

OTHER CONTACT
- non-empty
- bounded server-side

Do not make validation so strict that legitimate international values become impossible.

Flutter may later duplicate validation for UX, but server validation is authoritative.

==================================================
11. CONTACT RULES
==================================================

Allowed contact types exactly:

phone
whatsapp
email
website
other

Use replace-all semantics INSIDE the atomic transaction.

Validate:

- count <= 10
- allowed type
- trimmed non-empty value
- type-specific rules
- at most one primary per contact type

All inserted rows MUST have entity_id assigned server-side from p_entity_id.

Do not trust child entity IDs from client.

Duplicate identical contact entries should be rejected or safely normalized according to the smallest deterministic design.

==================================================
12. PRIMARY LOCATION
==================================================

V1-R06 manages:

PRIMARY LOCATION ONLY

The schema may support multiple branches, but they are outside this UI scope.

The mutation must:

- update/create the primary location;
- preserve non-primary historical/additional locations;
- enforce at most one primary;
- assign entity_id server-side.

Primary location payload may support:

region_id
address
latitude
longitude

Coordinates:

- nullable
- must be supplied as a pair
- latitude -90..90
- longitude -180..180

Region:

- nullable if existing schema/product permits no region;
- when present, must reference an existing ACTIVE physical region.

If the bounded payload represents clearing the primary location, implement the smallest deterministic safe behavior and document it.

Do not mutate region taxonomy.

==================================================
13. CATEGORY ASSIGNMENTS
==================================================

V1-R06 manages:

CATEGORY ASSIGNMENTS ONLY

No service/specialty table.

Use replace-all semantics in the profile transaction.

Rules:

- <= 10 unique categories
- every category must exist
- every category must be active
- reject duplicates
- at most one primary
- category taxonomy itself is read-only
- empty assignment is allowed

All entity linkage must be server-side.

==================================================
14. MEDIA
==================================================

MEDIA MANAGEMENT IS OUT OF SCOPE FOR V1-R06.

Reason:

Supabase Storage security infrastructure is not ready.

Do NOT add:

- buckets
- storage policies
- upload RPCs
- image picker wiring
- arbitrary media URL mutation

Existing canonical media remains public read-only.

Media management is deferred.

==================================================
15. CONCURRENCY
==================================================

Use:

OPTIMISTIC CONCURRENCY
+
ATOMIC SERVER TRANSACTION

The mutation RPC must:

1. lock the target directory_entities row FOR UPDATE;
2. read current updated_at;
3. compare with p_expected_updated_at;
4. if stale, fail with typed conflict;
5. perform all permitted scalar/child changes atomically;
6. explicitly advance directory_entities.updated_at even for child-only changes;
7. return the authoritative new management projection/version.

Add typed SQLSTATE:

P0CON

for stale-write concurrency conflict.

Do not silently last-write-wins.

==================================================
16. TRANSACTIONALITY
==================================================

One save action is ONE atomic server mutation.

It includes:

- scalar entity fields
- contacts replacement
- primary location mutation
- category assignments
- derived verification transition
- audit log
- version touch

Any validation/error must roll back ALL mutations.

No partial profile save.

==================================================
17. AUDIT LOG
==================================================

Use the existing:

audit_logs

in the same established format as prior migrations.

Do NOT invent a parallel audit mechanism.

Write exactly one bounded audit event on successful profile mutation.

Include as supported by existing schema:

- actor auth.uid()
- target entity
- profile-update action
- bounded before/after or changed-section metadata

Do not log secrets.

Do not insert a success audit row for rolled-back/failed mutations.

==================================================
18. PUBLIC DIRECTORY LOCATION COMPATIBILITY
==================================================

Audit found the current public Directory may consume the first location rather than deterministically the primary location.

Because V1-R06 manages the primary location, make the smallest necessary compatibility correction so public Directory reads/display prefer:

is_primary = true

deterministically.

Do NOT redesign V1-R05.

Only change this if required for a saved primary location to display correctly in the public profile.

Add focused regression coverage if touched.

==================================================
19. CACHE AUTHORITY
==================================================

Do NOT write directly to:

directory_cloud_cache

from server or future management UI.

Frozen post-save architecture for Part 2:

successful server mutation
→ authoritative management result/reread
→ CloudDirectoryRepository.refresh()
→ canonical public cache replacement

No optimistic local authority.

If public cache refresh later fails after server save:
the save remains successful;
Flutter will show a refresh warning.

==================================================
20. OFFLINE MUTATIONS
==================================================

Frozen policy:

ONLINE-ONLY SAVE WITH CLEAR OFFLINE STATE

Do NOT create queued offline writes.

Do NOT create a sync engine.

Read-only cached data may still be displayed offline.

==================================================
21. SECURITY NEGATIVE PATHS
==================================================

Server tests/verification must prove:

- guest denied
- MEMBER denied
- unrelated authenticated user denied
- OWNER allowed
- ADMIN allowed
- guessed UUID cannot bypass authorization
- entity not found handled safely
- client cannot mutate:
  - entity_type
  - claim_status
  - lifecycle_status
  - verification_status directly
- inactive/nonexistent categories rejected
- invalid region rejected
- foreign child/entity IDs cannot target another business
- duplicate/unknown child JSON keys rejected
- stale expected_updated_at returns P0CON
- failed transaction leaves no partial child mutations

==================================================
22. READ/WRITE GRANTS
==================================================

Keep public Directory table writes unavailable to client roles.

For new client RPCs:

REVOKE ALL / PUBLIC execution as appropriate.

Grant execution only to:

authenticated

Do not grant anon execution.

Internal helper functions remain internal.

==================================================
23. SERVER TEST STRATEGY
==================================================

Use existing repo/Supabase DB verification patterns.

Add the smallest focused server/security evidence necessary.

Do NOT run Flutter full suite.

Verify where environment permits:

OWNER read/save
ADMIN read/save
MEMBER denied
unrelated user denied
guest denied
immutable states protected
derived verification transition
non-sensitive edit preserves verification
active category validation
region validation
contact validation
P0CON conflict
transaction rollback
successful audit event
failed mutation has no success audit
management read can access authorized draft/inactive profile

If linked DEV credentials are unavailable:

do NOT fabricate a DEV PASS.

Use:

DEV SERVER QA DEFERRED — CREDENTIALS UNAVAILABLE

but still perform all local/static/database verification available.

==================================================
24. ERROR CONTRACT
==================================================

Reuse:

P0AUT — unauthenticated
P0PER — unauthorized
P0NOT — not found
P0DAT — invalid data/reference

Add:

P0CON — stale optimistic-concurrency conflict

Do not invent unnecessary SQLSTATEs.

Document exact RPC error behavior for Part 2 Flutter mapping.

==================================================
25. PART 2 INTERFACE HANDOFF
==================================================

At the end of Part 1, provide Big Pickle an exact stable contract:

READ RPC:
- exact function name
- parameters
- return JSON/row shape
- typed errors

UPDATE RPC:
- exact function name
- parameters
- child payload shapes
- returned projection
- typed errors

Also report:

- which fields trigger verification → pending;
- validation bounds;
- nullable behavior;
- expected_updated_at semantics.

Do not leave Flutter to infer the server contract.

==================================================
26. NON-SCOPE
==================================================

Do NOT implement:

- Flutter management screens
- Flutter management controller
- system staff UI
- verification approval/rejection UI
- lifecycle moderation
- orphan remediation
- membership invitations
- media uploads
- multi-location editing
- taxonomy editing
- reviews/ratings
- marketplace
- RFQ/bids
- payments
- subscriptions
- CRM
- advanced analytics
- monetization

==================================================
27. FILE / GIT SAFETY
==================================================

Never touch:

OpenCode_Usage_Report.txt

Do NOT:

git add
git commit
git push

Everything remains unstaged.

Do not alter unrelated features.

==================================================
28. TARGETED VERIFICATION
==================================================

Do not run broad Flutter verification.

Run only server/database checks directly relevant to the migration and any tiny regression directly caused by the primary-location compatibility correction if required.

Then:

git diff --check
git status --short

No full flutter test.

No flutter analyze unless compilation specifically requires a narrow check.

==================================================
29. REQUIRED FINAL REPORT
==================================================

Return:

# V1-R06 Part 1 — Secure Profile Management Server Report

## Preflight
- HEAD
- origin parity
- roadmap
- contract
- authorization
- git status

## Migration
- migration file
- additive only YES/NO
- new tables NO/YES
- direct table grants added NO/YES

## Authorization
- auth.uid
- OWNER
- ADMIN
- MEMBER
- unrelated user
- guest
- reusable helper

## Read RPC
- exact name
- signature
- projection
- draft/inactive access
- grants

## Update RPC
- exact name
- signature
- atomicity
- return projection
- grants

## Editable Fields
- name
- description
- contacts
- primary location
- categories

## Protected Fields
- id
- entity_type
- claim
- lifecycle
- verification direct input
- timestamps

## Verification Side Effect
- sensitive fields
- verified → pending behavior
- non-sensitive edits
- other verification states

## Validation
- name
- description
- contacts
- region
- address
- coordinates
- categories
- unknown payload fields

## Concurrency
- FOR UPDATE
- expected_updated_at
- P0CON
- child-only version touch

## Transaction
- rollback behavior
- partial writes possible YES/NO

## Audit
- audit_logs
- success event
- failure behavior

## Public Directory Compatibility
- primary-location deterministic read/display change needed YES/NO
- exact change if YES

## Tests / QA
- focused server checks
- security negatives
- conflict
- rollback
- audit
- DEV status

## Part 2 RPC Handoff
Provide exact machine-readable-ish request/response shapes for Big Pickle.

## Scope Audit
Confirm no:
- Flutter management UI
- media upload
- staff operations
- membership expansion
- service_role
- unrelated refactor

## Git Integrity
- diff --check
- staged NO
- committed NO
- pushed NO
- OpenCode_Usage_Report.txt untouched

## Final Decision

Use exactly one:

PART 1 COMPLETE — READY FOR BIG PICKLE PART 2

or

PART 1 BLOCKED — ARCHITECT DECISION REQUIRED