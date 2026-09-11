# CIVILPEDIA V1-R05 — DIRECTORY CLOUD INTEGRATION
## ARCHITECT CONTRACT FREEZE + IMPLEMENTATION AUTHORIZATION

CONTRACT_ID: V1-R05-CONTRACT-v1

You are Big Pickle.

ROLE:
Main Implementer for:

V1-R05 — Directory Cloud Integration

Independent Reviewer:
Codex

Recommended effort:
HIGH

Owner alone performs staging / commit / push.

This contract authorizes BOTH sequential implementation parts defined below.

Do not stop between Part 1 and Part 2 if the internal gate passes.

==================================================
0. EXECUTION PHILOSOPHY
==================================================

Optimize for:

QUALITY
+
LOW CODEX USAGE
+
FAST VERIFICATION

Implementation may be thorough.

Verification must be surgical.

Evidence reuse is mandatory.

Do NOT repeatedly run broad tests while developing.

Implement:

PART 1 — Canonical Authority / Data / Cache
then
PART 2 — UI / Routing / Compatibility Cutover

Both remain one canonical phase:

V1-R05

Do NOT invent roadmap subphase IDs.

==================================================
1. CANONICAL BASELINE
==================================================

Repository:

D:\Civilpedia

Expected branch:

main

Expected HEAD:

62cdc771d736b6263a8d634223dd3082934b0bc5

Expected commit:

62cdc77
docs: finalize V1-R04 closure record

Expected:

HEAD == origin/main

Expected working tree:

?? OpenCode_Usage_Report.txt

Do not touch:

OpenCode_Usage_Report.txt

Canonical roadmap:

docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md

Expected:

CURRENT_PHASE_ID: V1-R05
CURRENT_PHASE_TITLE: Directory Cloud Integration
CURRENT_PHASE_CONTRACT: NOT_FROZEN
IMPLEMENTATION_AUTHORIZED: NO

Before product implementation, update ONLY the control state to:

CURRENT_PHASE_CONTRACT: V1-R05-CONTRACT-v1
IMPLEMENTATION_AUTHORIZED: YES

Do NOT close V1-R05.
Do NOT promote V1-R06.

Persist this contract faithfully at:

docs/architecture/contracts/V1-R05_DIRECTORY_CLOUD_INTEGRATION_CONTRACT.md

If repository reality materially contradicts this contract:

ROADMAP CONFLICT — ARCHITECT DECISION REQUIRED

STOP.

==================================================
2. PHASE GOAL
==================================================

Replace the current local-only production Directory authority with:

public.directory_entities

and its canonical public child relationships.

At V1-R05 close:

- canonical cloud entity identity is authoritative;
- Directory list/search/filter/detail use canonical cloud-backed data;
- offline use is supported through a dedicated canonical cache;
- saved Directory references use canonical entity IDs;
- detail routing resolves by canonical entity ID;
- legacy `sb_profiles` no longer feeds production Directory;
- no ambiguous dual authority remains.

Do NOT destroy legacy local data.

Do NOT implement business-profile editing.

==================================================
3. FROZEN AUTHORITY RULE
==================================================

The ONLY production Directory entity identity is:

public.directory_entities.id

UUID.

The following MUST NOT act as canonical Directory identity:

- ServiceBusinessProfile.id
- sb_profiles IDs
- business name
- phone
- WhatsApp
- address
- category
- futureOwnerUserId
- any heuristic match

No fuzzy migration.

No name-based mapping.

No phone-based mapping.

No automatic local→cloud rebinding.

==================================================
4. CURRENT LEGACY DIRECTORY
==================================================

Existing production path is currently approximately:

Directory UI
→ DirectoryRepository
→ SbProfilesDirectoryRepository
→ LocalServiceBusinessRepository
→ ServiceBusinessDataSource
→ SharedPreferences["sb_profiles"]

ServiceBusinessProfile is legacy/local compatibility data after V1-R05.

It must NOT remain production Directory authority.

Preserve the legacy blob non-destructively.

==================================================
5. CANONICAL CLOUD SOURCES
==================================================

Use existing canonical public tables only:

directory_entities
directory_categories
directory_entity_categories
regions
entity_locations
entity_contacts
entity_media

Existing public RLS/grants remain authoritative.

Only active directory entities are publicly visible through existing RLS.

No Flutter service_role.

No privileged secret.

No DB bypass.

==================================================
6. DATABASE CONTRACT
==================================================

Expected DB migration:

NONE

Do NOT create migration 00020.

Do NOT change:

- RLS
- grants
- table structure
- triggers
- Business Application authority
- ownership authority

If implementation discovers a mandatory schema/security gap:

STOP and report:

IMPLEMENTATION BLOCKED — ARCHITECT DECISION REQUIRED

Do not silently add a migration.

==================================================
7. CANONICAL DIRECTORY DOMAIN MODEL
==================================================

Add the smallest canonical Directory model owned by the Directory feature.

It must use:

canonical entity ID
name
entityType
description
lifecycle / public state where needed
verificationStatus
claimStatus
createdAt / updatedAt where useful

and canonical public relationships needed by V1:

categories
locations
contacts
optional media

Do NOT clone unrelated business/application models.

ServiceBusinessProfile must no longer be the production Directory model.

Unknown enum/status values:

fail closed / neutral presentation.

Do not crash.

==================================================
8. CANONICAL ENTITY TYPES
==================================================

Canonical DB entity_type values are exactly:

company
engineering_office
contractor
supplier
store
technician
laboratory
equipment_provider
service_provider

Do NOT use the old 12-value BusinessType taxonomy as authority.

Avoid two independently maintained canonical lists.

Preferred:

reuse or minimally extract the already-proven canonical entity-type seam from V1-R04 if dependency direction remains clean.

If a small shared canonical seam is needed:

perform the smallest safe extraction.

Do NOT introduce incompatible copies that can drift.

Existing BusinessType may remain only as legacy/presentation compatibility code where still required outside the production Directory path.

==================================================
9. PART 1 — CLOUD READ GATEWAY
==================================================

Build a general read-only Supabase Directory data seam.

Unlike V1-R04 CLAIM target gateway:

the PUBLIC Directory gateway must support both:

anon
authenticated

under existing public RLS.

Do NOT require authentication for normal Directory reads.

Do NOT reuse the CLAIM gateway as the general repository.

The CLAIM gateway remains:

authenticated
+
unclaimed-only
+
narrow selector projection.

Reuse only safe patterns such as:

- Supabase availability handling
- fail-closed parsing
- canonical UUID identity
- existing public RLS assumptions

==================================================
10. CLOUD READ PROJECTION
==================================================

For Directory LIST/cache, canonical data must support at minimum:

- id
- name
- entity_type
- verification_status
- claim_status
- description if bounded and convenient
- assigned active categories
- primary/basic location
- stable region identity/code

For DETAIL, support:

- list projection
- description
- canonical locations
- addresses
- public contacts
- assigned categories/subcategories

Media:

optional if already safely available.

Do NOT make media a blocker for V1-R05.

Do NOT add opening-hours storage.

Do NOT add services tables.

==================================================
11. CHILD RELATIONSHIPS
==================================================

Use canonical relationships.

Categories:

directory_categories
+
directory_entity_categories

Regions / locations:

regions
+
entity_locations

Contacts:

entity_contacts

Media:

entity_media

Respect public RLS.

Only active categories/regions should drive user-facing filter/presentation when such status applies.

Malformed child rows:

must not crash the whole Directory.

==================================================
12. CATEGORY DATA READINESS
==================================================

The audited migration chain does not guarantee seeded category rows.

Therefore:

Do NOT fabricate cloud categories from legacy local categories.

Do NOT seed categories merely to preserve local taxonomy.

If canonical category relationships exist:

display/filter them.

If none exist:

the Directory must remain functional using:

- canonical entity type
- region
- text/name

Category UI should degrade honestly rather than fabricate authority.

Do not make an empty category table a schema blocker.

==================================================
13. REGION AUTHORITY
==================================================

Directory physical location authority is:

regions
+
entity_locations

Use stable canonical region IDs/codes.

Do NOT use:

region_preferences

for physical Directory location.

Existing BaghdadArea may remain presentation compatibility only where necessary during cutover.

It must not be canonical persistence identity after V1-R05.

==================================================
14. DEDICATED CANONICAL CACHE
==================================================

Create a NEW dedicated, versioned Directory cloud cache.

Do NOT reuse `sb_profiles` as the canonical cache.

Recommended bounded V1 storage:

SharedPreferences single versioned snapshot

unless an already-existing equally suitable abstraction makes this unnecessary.

The snapshot must include at minimum:

schema/cache version
refreshedAt
canonical entities keyed/resolvable by directory_entities.id
required cached relationships for offline list/search/detail

Use a clearly separate key from:

sb_profiles

==================================================
15. CACHE AUTHORITY RULES
==================================================

Cloud is authoritative.

Cache is only:

a stale offline snapshot.

Rules:

- successful complete cloud refresh → atomically replace snapshot;
- network failure → may use last valid snapshot;
- malformed cache → fail safely and attempt cloud refresh;
- failed/partial required cloud refresh → MUST NOT destroy last valid cache;
- cache exposes no public entity mutation authority;
- cached claim/verification state cannot be locally edited;
- legacy sb_profiles cannot overwrite canonical cached fields.

No optimistic Directory mutations.

==================================================
16. CACHE-FIRST UX SEMANTICS
==================================================

Preferred behavior:

1. Load valid canonical cache quickly if present.
2. Render it.
3. Refresh cloud.
4. On successful refresh:
   replace state + cache atomically.
5. On cloud failure:
   preserve/render stale cache if available.
6. If neither cache nor cloud succeeds:
   show production error + retry.

Expose enough state to distinguish:

fresh
stale/offline
empty
loading
error

Do not create infinite loading.

==================================================
17. SEARCH / FILTER AUTHORITY
==================================================

Cloud refresh obtains the bounded canonical dataset.

Search/filter execute locally over canonical cached models.

Do NOT perform server query for every keystroke.

Preserve useful existing behavior:

- trimmed text query
- case-insensitive search
- existing debounce if still useful
- AND semantics between active filters
- distinct empty-directory vs no-results UX

Canonical searchable fields:

- name
- canonical category labels/codes when available

Optional:
other already-public text fields only if current UX needs them.

==================================================
18. FILTERS
==================================================

Production filters after cutover should use canonical identities:

Entity type:
canonical entity_type

Region:
canonical region identity/code

Category:
canonical assigned category identity/code when category data exists

Do NOT treat legacy:

BusinessType
BaghdadArea
local category strings

as cloud authority.

No heuristic local→cloud taxonomy collapse.

==================================================
19. DETERMINISTIC ORDERING
==================================================

Provide deterministic Directory ordering.

No ranking invention.

No sponsored influence on organic authority.

A stable order such as:

normalized/name order
then canonical ID

is acceptable.

Do not implement advanced ranking.

==================================================
20. PRODUCTION DIRECTORY REPOSITORY
==================================================

At V1-R05 close, the production Directory repository must be READ-ONLY regarding public business entities.

Its production responsibilities should conceptually include:

load/list canonical entities
refresh
loadByCanonicalId
cache fallback

Search/filter may remain a pure local query engine over returned canonical models.

Remove or isolate from the production Directory contract:

save entity
delete entity
clear all entities

Legacy local repositories may retain old methods internally/tests if necessary for compatibility, but AppDependencies production Directory wiring must not expose local profile mutations as Directory authority.

Profile mutations belong V1-R06.

==================================================
21. LEGACY SB_PROFILES
==================================================

Do NOT delete or rewrite existing sb_profiles.

Do NOT heuristically migrate them.

After cutover:

- sb_profiles may physically remain;
- production Directory MUST NOT read from it;
- production Directory MUST NOT write through it;
- claim/verification/local-owner values from it MUST NOT affect Directory.

Legacy code can remain isolated if removing it would cause unrelated scope expansion.

==================================================
22. SAVED DIRECTORY REFERENCES
==================================================

New Directory saved references must use:

canonical directory_entities.id

Existing legacy saved references may contain local IDs.

Rules:

- do not delete unmatched legacy references automatically;
- do not map them heuristically;
- do not bind by name/phone/address;
- unresolved legacy references should fail safely / display unavailable state according to existing Saved UX patterns;
- user may still manually remove their saved reference through existing Saved behavior.

Do not corrupt other Saved item types.

==================================================
23. DETAIL ROUTING
==================================================

Stop transporting a complete ServiceBusinessProfile as authoritative detail state.

Use a stable canonical-ID route.

Preferred route:

/directory/entity/:id

or exact equivalent matching established route conventions.

The route identity must be:

directory_entities.id

Detail resolves the entity through the canonical Directory repository/cache.

Direct route entry:

- valid cached/cloud canonical ID → detail;
- unknown/not visible ID → safe unavailable/404-style Directory state;
- malformed ID → safe failure;
- no crash.

==================================================
24. DIRECTORY UI CUTOVER — PART 2
==================================================

After Part 1 focused tests pass, continue directly to Part 2.

Adapt existing Directory UI rather than redesigning it.

Preserve where practical:

DirectoryLandingScreen
DirectorySearchScreen
DirectoryProviderDetailScreen
current cards
verification badge
contact launch behavior
empty/error primitives
Civilpedia design tokens
RTL
dark mode

The source model and identity must become canonical.

No unrelated visual redesign.

==================================================
25. DIRECTORY LANDING / TYPE TAXONOMY
==================================================

The existing local fixed BusinessType taxonomy must not continue presenting itself as canonical if values disagree with cloud entity_type.

Adapt landing/filter choices to canonical entity types.

Use localized applicant-facing labels.

Do not expose raw DB codes.

No fake mappings such as:

local "material_shop" → cloud "store"

unless there is an explicitly frozen one-to-one mapping.

Prefer canonical cloud vocabulary.

==================================================
26. DIRECTORY SEARCH SCREEN
==================================================

Adapt current screen or introduce a small state/provider layer only where necessary.

Required states:

- loading
- cached/fresh data
- stale/offline cache
- empty cloud Directory
- no search results
- refresh error with cache
- fatal error without cache
- retry

Do not introduce an app-wide state-management rewrite.

==================================================
27. DIRECTORY DETAIL
==================================================

Display canonical public data available for the entity.

Required where available:

- name
- canonical type label
- verification state
- claim state where product UX reasonably exposes it
- description
- category information
- location/address
- public phone
- WhatsApp
- email/website if already canonical and public

Optional:
media

Do not expose:

- owner user IDs
- membership data
- applicant metadata
- staff information
- internal audit data

==================================================
28. CONTACT SAFETY
==================================================

Only public `entity_contacts` may be used.

Do not join private profiles.

Preserve existing contact-launcher safety.

Malformed contact values must not crash UI.

==================================================
29. CLAIM / VERIFICATION
==================================================

These fields are cloud authoritative:

claim_status
verification_status

Cache may be stale offline.

Local legacy values may NEVER override them.

V1-R05 adds no action that mutates these statuses.

Business Application / staff activation authority remains unchanged.

==================================================
30. V1-R04 CLAIM SEAM
==================================================

Keep:

BusinessClaimTarget
BusinessClaimTargetGateway
SupabaseBusinessClaimTargetGateway

separate unless the smallest safe shared canonical primitive extraction is justified.

Do NOT change its authenticated + unclaimed-only behavior.

V1-R05 must not regress:

canonical CLAIM ID forwarding
guest protection
claimability filtering

==================================================
31. SPONSORED / MONETIZATION
==================================================

Organic Directory authority must remain independent from:

featured
foundingPartner
planType
sponsored
subscriptions
payments

Existing dormant sponsored coordinator must not change canonical identity or organic search data.

Do not activate monetization behavior.

==================================================
32. V1-R06 BOUNDARY
==================================================

V1-R05 READS canonical public profile data.

V1-R06 owns mutations for:

- business name
- description
- phone
- WhatsApp
- email/website
- address/location
- categories/services
- media
- other provider-profile editing

Do not implement these mutations now.

==================================================
33. EXPLICIT NON-SCOPE
==================================================

Do NOT implement:

- business profile editing
- staff/admin operations
- ownership/membership changes
- invitations
- public reviews/ratings
- marketplace
- RFQ
- bids
- subscriptions
- payments
- monetization
- sponsorship redesign
- advanced ranking
- analytics
- CRM
- opening hours schema
- new service/specialty schema

==================================================
34. PART 1 INTERNAL GATE
==================================================

Before moving from Part 1 → Part 2, focused tests must prove:

1. canonical UUID parsing
2. malformed cloud entity fails safe
3. required child mapping
4. anon public read seam supported
5. authenticated public read seam supported
6. only canonical IDs exposed
7. dedicated cache key used
8. sb_profiles not used by new repository
9. successful refresh replaces cache
10. failed refresh preserves cache
11. malformed cache fails safely
12. cloud empty result can replace stale cache as an authoritative empty snapshot
13. cache lookup by canonical ID
14. claim/verification values originate from cloud/cache snapshot only
15. no production Directory mutation methods

If these focused tests fail:

fix root cause before Part 2.

No Codex review is required at the internal gate.

==================================================
35. FOCUSED V1-R05 TEST FILE
==================================================

Add an appropriate focused test such as:

test/v1_r05_directory_cloud_integration_test.dart

or the nearest established naming convention.

The final V1-R05 focused coverage should prove at minimum:

DATA / AUTHORITY
1. canonical cloud model
2. exact canonical ID
3. no ServiceBusinessProfile authority
4. no heuristic identity mapping
5. active public query shape
6. child relationships map safely
7. unknown codes fail safe

CACHE
8. cache-first read
9. successful refresh replaces snapshot
10. failure falls back to last valid snapshot
11. malformed cache recovery
12. cache version handling
13. authoritative empty cloud refresh replaces old snapshot
14. sb_profiles isolation

SEARCH / FILTER
15. text search
16. canonical entity-type filter
17. canonical region filter
18. category filter when canonical category data exists
19. combined AND semantics
20. deterministic ordering
21. empty vs no-results

ROUTING / DETAIL
22. detail uses canonical ID
23. direct canonical detail route
24. malformed/missing ID safe
25. whole ServiceBusinessProfile object is no longer authoritative

SAVED
26. newly saved Directory ref uses canonical ID
27. canonical saved ref reopens detail
28. unmatched legacy saved ref not rebound heuristically
29. unmatched legacy ref not automatically deleted

OFFLINE
30. stale cache renders on cloud failure
31. retry refresh works
32. no fake mutation success

V1-R04 COMPATIBILITY
33. CLAIM target gateway remains authenticated-only
34. canonical selected claim target behavior remains intact

==================================================
36. EXISTING RELEVANT REGRESSIONS
==================================================

Run only directly relevant Directory/Saved/Route tests after focused tests are green.

Identify them from repository reality.

Do not run unrelated A6 ownership/staff/backend suites.

Run V1-R04 claim-target focused coverage only where necessary to prove the shared/canonical-type changes did not regress it.

==================================================
37. DEV CLOUD SMOKE QA
==================================================

No migration QA is needed.

Perform only a SMALL real DEV read smoke test.

Confirm where current DEV data permits:

A. anon can read active directory entities
B. authenticated user can read active directory entities
C. inactive/suspended/draft entity rows are not publicly returned
D. allowed public child rows obey parent-active RLS
E. Flutter projection can parse the real response

Do NOT create a large QA matrix.

Do NOT use service_role as app behavior.

Controlled admin inspection is allowed only where necessary to confirm schema/data state.

If DEV has no suitable data for one smoke case:

document that limitation;
do not fabricate a large fixture campaign unless genuinely required.

==================================================
38. VISUAL QA
==================================================

Perform focused visual QA only on affected Directory surfaces:

- populated list
- canonical type filters
- region filters
- category behavior
- search
- detail
- verification/claim presentation
- empty Directory
- no-results
- stale/offline cache
- error/retry
- Saved → Directory reopening
- RTL
- dark mode

No unrelated full-app visual QA.

==================================================
39. FINAL QUALITY GATES
==================================================

After implementation is complete:

1. V1-R05 focused tests
2. directly relevant Directory/Saved/Route regressions
3. focused V1-R04 claim compatibility if touched
4. one full Flutter suite
5. flutter analyze lib/
6. full flutter analyze once
7. git diff --check
8. git status --short

Do not repeat the full suite during normal development.

Acceptance:

- focused tests PASS
- relevant regressions PASS
- full suite PASS
- no new analyzer diagnostics
- historical analyzer debt not cleaned here
- no scope creep

==================================================
40. GIT RULES
==================================================

Everything remains UNSTAGED.

Big Pickle MUST NOT:

git add
git commit
git push

Owner performs Git actions only after:

Big Pickle implementation
→ Codex independent focused review
→ Big Pickle fixes findings if needed
→ surgical Codex recheck if needed
→ Architect Final Review
→ Owner commit/push

==================================================
41. PROTECTED AREAS
==================================================

Do not manually edit generated Encyclopedia files.

Do not touch:

OpenCode_Usage_Report.txt

Do not change unrelated:

Encyclopedia
Projects
Calculators
Content Studio
Auth
staff operations
monetization

unless compilation requires a tiny direct compatibility change.

Any such change must be reported.

==================================================
42. REQUIRED FINAL REPORT
==================================================

Return:

# V1-R05 — Big Pickle Implementation Report

## Preflight
- branch
- HEAD
- origin parity
- git status
- roadmap
- contract
- authorization

## Part 1 — Canonical Authority
- canonical model
- entity identity
- cloud repository/gateway
- child relations
- anon/auth behavior

## Cache
- cache key/version
- cache structure
- atomic replacement
- fallback
- malformed cache behavior
- sb_profiles isolation

## Legacy Isolation
- ServiceBusinessProfile status
- sb_profiles status
- mutation surfaces
- heuristic mapping absent

## Search / Filter
- text
- entity type
- region
- category
- deterministic order

## Part 2 — UI Cutover
- landing
- search
- cards
- detail
- canonical routing
- states

## Saved Compatibility
- new canonical refs
- canonical reopen
- legacy unresolved refs
- no heuristic rebind

## V1-R04 CLAIM Compatibility
- claim gateway separation
- canonical ID behavior
- auth behavior

## DEV Smoke
- anon active read
- authenticated active read
- inactive exclusion
- child RLS
- real response parsing

## Visual QA
- surfaces checked
- RTL
- dark
- stale/offline

## Tests
- V1-R05 focused count/result
- relevant regression count/result
- V1-R04 compatibility result
- full suite result

## Analyzer
- lib/
- full
- new diagnostics

## Scope Audit
Confirm no:
- DB migration
- RLS/grant change
- profile editing
- staff UI
- membership mutation
- Directory heuristic mapping
- monetization
- unrelated refactor

## Git Integrity
- git diff --check
- git status
- staged NO
- committed NO
- pushed NO
- OpenCode_Usage_Report.txt untouched

## Final Decision

Use exactly one:

IMPLEMENTATION COMPLETE — READY FOR INDEPENDENT REVIEW

or

IMPLEMENTATION BLOCKED — ARCHITECT DECISION REQUIRED