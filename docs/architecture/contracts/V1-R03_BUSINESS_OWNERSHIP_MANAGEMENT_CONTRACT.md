# CIVILPEDIA V1-R03 — BUSINESS OWNERSHIP & MANAGEMENT
## Architect Contract Freeze + Implementation Authorization

CONTRACT_ID: V1-R03-CONTRACT-v1

You are Codex.

ROLE:
Main Implementer for Civilpedia V1-R03.

This is a backend / authorization / ownership-sensitive phase.

You MUST follow the repository's canonical roadmap:

docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md

Do not infer another phase.

The Architect now explicitly freezes V1-R03 and authorizes implementation under THIS contract.

Main Implementer: Codex
Independent Reviewer: Big Pickle
Owner alone authorizes staging/commit/push.

Recommended reasoning effort: HIGH.

Do NOT use MAX/Extra High unless a genuine architecture/security blocker appears.

==================================================
1. EXPECTED BASELINE
==================================================

Repository root:

D:\Civilpedia

Expected branch:

main

Expected committed baseline:

e0446f6
docs: establish Civilpedia V1 master roadmap

Expected prior production milestones:

12b1918
A6.3.1 — Creation Authorization Hardening

7aafc9f
A6.4 — Business Activation & Ownership Provisioning

Expected migration history:

00001 → 00018

Expected unrelated local artifact:

?? OpenCode_Usage_Report.txt

This file is user-owned and MUST remain untouched and outside Git.

At preflight verify:

git status --short
git log -5 --oneline
git rev-parse HEAD
git rev-parse origin/main
git diff --check

Expected:

HEAD == origin/main == e0446f6

and no tracked modifications.

If repository reality materially contradicts this contract:

PREFLIGHT BLOCKED — ARCHITECT DECISION REQUIRED

STOP.

Do not improvise.

==================================================
2. ROADMAP CONTROL TRANSITION
==================================================

The roadmap currently says:

CURRENT_PHASE_ID: V1-R03
CURRENT_PHASE_TITLE: Business Ownership & Management
CURRENT_PHASE_CONTRACT: NOT_FROZEN
IMPLEMENTATION_AUTHORIZED: NO

This Architect prompt is the authorization.

Before product-code changes, update ONLY the control state necessary to reflect this contract:

CURRENT_PHASE_CONTRACT: V1-R03-CONTRACT-v1
IMPLEMENTATION_AUTHORIZED: YES

Do NOT:
- close V1-R03;
- advance V1-R04;
- alter roadmap order;
- change V1/Post-V1 scope.

Also persist this Architect contract as:

docs/architecture/contracts/V1-R03_BUSINESS_OWNERSHIP_MANAGEMENT_CONTRACT.md

Preserve the contract faithfully.
Do not reinterpret or expand it.

This documentation remains part of the eventual atomic V1-R03 commit.

==================================================
3. PHASE GOAL
==================================================

Turn the existing A6.1 + A6.4 ownership foundation into a production-safe business-management read and authorization foundation.

At completion an authenticated user must be able to:

A. retrieve the canonical business entities associated with their own business memberships;

B. know their authoritative role for each entity;

C. derive management capability from the canonical membership role;

D. if OWNER or ADMIN, obtain an authorized membership roster for that entity;

E. rely on a reusable SERVER-SIDE management-authorization seam that later phases such as Business/Provider Profile Management can use.

This phase establishes authority.

It does NOT build the final Business Profile editing UI.

==================================================
4. CANONICAL AUTHORITIES
==================================================

These are frozen.

Human identity authority:

auth.users.id / auth.uid()

Business ownership/access authority:

business_memberships

Business roles are exactly:

OWNER
ADMIN
MEMBER

Directory/business entity authority:

directory_entities

There MUST NOT be:

directory_entities.owner_user_id

or any equivalent second ownership authority.

Do NOT use ownership derived from:

- email;
- Google provider ID;
- LocalUserProfile;
- futureOwnerUserId;
- local sb_profiles;
- PlanType;
- PlanTier;
- featured;
- foundingPartner;
- subscriptions;
- staff_memberships.

Staff authorization and business authorization remain separate systems.

Application status, claim state, verification state, subscription state, sponsorship state and business membership role remain separate concepts.

==================================================
5. ROLE / CAPABILITY CONTRACT
==================================================

Preserve the existing semantics.

OWNER:

isOwner = true
canManageEntity = true

ADMIN:

isOwner = false
canManageEntity = true

MEMBER:

isOwner = false
canManageEntity = false

Unknown role:

fail closed
no management capability

No membership:

no management capability

Do not introduce plan-based or account-type-based business management.

Do not create a second competing capability resolver.

Reuse/extend the existing:

BusinessRole
BusinessMembership
BusinessMembershipCapabilities
BusinessMembershipCapabilityResolver

where compatible.

==================================================
6. MY BUSINESSES READ CONTRACT
==================================================

Add one narrow authenticated server-authoritative RPC:

list_my_businesses()

Actor:

auth.uid()

Client supplies:

NO user ID
NO email
NO role
NO account type

Behavior:

- P0AUT if no authenticated actor.
- Return ONLY entities linked to auth.uid() through business_memberships.
- Include OWNER, ADMIN and MEMBER associations.
- Authenticated user with zero memberships returns an empty list, NOT an error.
- Never infer ownership from local data.
- Never expose another user's association.

Return the smallest useful management projection.

Canonical fields:

entity_id
name
entity_type
membership_role
claim_status
verification_status

Do NOT include:

contacts
locations
media
subscriptions
sponsorship
payment data
application metadata
private staff data

unless repository inspection proves a required field is structurally unavoidable.

If an exact existing canonical model can represent this projection without semantic distortion, reuse it.

Otherwise create the smallest business-management read projection, e.g.:

ManagedBusinessSummary

Do NOT clone the full Directory entity model.

Ordering is NOT a business/security contract in V1-R03.
Tests must not depend on incidental database row ordering.

==================================================
7. BUSINESS MEMBER ROSTER
==================================================

A6.1 deliberately left entity-member listing unavailable until this server-authorized phase.

Now implement the existing intended capability.

Add one narrow RPC:

list_business_members(p_entity_id uuid)

Authorization:

actor = auth.uid()

Allowed:

OWNER
ADMIN

Denied:

MEMBER
no membership
guest

OWNER and ADMIN may read the membership rows for the requested entity.

Return only canonical BusinessMembership data needed by the domain contract.

Do NOT return:

email
phone
provider identities
tokens
staff roles
personal profile data

unless an existing BusinessMembership field already requires it.

A MEMBER can already know their own membership through the existing own-membership read.
MEMBER must NOT receive the full roster.

For non-manager/no-membership access:

P0PER

Prefer failing closed rather than revealing whether a target entity exists.

==================================================
8. SERVER-SIDE MANAGEMENT AUTHORIZATION SEAM
==================================================

Add the smallest reusable internal server helper needed for this and future business-management RPCs.

Recommended canonical helper:

has_business_management_access(p_entity_id uuid)

Semantics:

auth.uid() has business_memberships.role IN ('OWNER', 'ADMIN')

The helper must:

- derive actor only from auth.uid();
- return false/fail closed for guest;
- use business_memberships only;
- NOT use PlanTier;
- NOT use staff roles;
- NOT use local ownership;
- NOT trust caller-supplied user IDs.

Security:

internal/server-only execution.

No anon execute.
No authenticated direct execute if it is purely an internal helper.

Client-facing RPCs call it from controlled server context.

If repository conventions indicate a safer equivalent helper name/shape, STOP before inventing a competing framework and report the precise conflict.

Do NOT create a generic overengineered permission engine in V1-R03.

==================================================
9. BUSINESS MEMBERSHIP GATEWAY
==================================================

Inspect the existing BusinessMembershipGateway.

Preserve:

listOwnMemberships(...)

and all existing A6.1 behavior.

The previously unsupported entity-member-list capability must now use the new authorized server RPC.

Do NOT create a second parallel member-list implementation.

Do NOT add direct client table mutation methods.

No client:

insert business_memberships
update business_memberships
delete business_memberships

==================================================
10. MEMBERSHIP MUTATIONS — EXPLICITLY OUT OF SCOPE
==================================================

V1-R03 does NOT implement:

- invite member;
- accept invitation;
- reject invitation;
- add member;
- remove member;
- change role;
- promote MEMBER → ADMIN;
- demote ADMIN → MEMBER;
- assign OWNER;
- transfer ownership;
- leave business;
- delete owner membership.

Reason:

Civilpedia V1 currently has no frozen production invitation/member-management user journey.

We will not invent a partial invitation system.

If the Owner later decides member-management UI is required for V1, the Architect will create an explicit sub-phase before implementation.

Do NOT silently pull it into V1-R03.

==================================================
11. ENTITY MUTATIONS — OUT OF SCOPE
==================================================

Do NOT implement business profile field editing here.

Specifically no mutation of:

- business name;
- description;
- phone;
- WhatsApp;
- address;
- region/location;
- services;
- categories;
- media;
- images;
- opening hours;
- website.

Those belong to:

V1-R06 — Business / Provider Profile Management

V1-R03 only establishes ownership and authorization foundations required by that future phase.

==================================================
12. DIRECTORY CLOUD INTEGRATION BOUNDARY
==================================================

Do NOT migrate the public Directory to cloud in this phase.

That belongs to:

V1-R05 — Directory Cloud Integration

V1-R03 may read the minimal canonical directory_entities fields necessary for the management projection.

It must NOT replace:

ServiceBusinessRepository
sb_profiles
DirectoryQueryEngine
Directory UI

in this phase.

==================================================
13. APPLICATION / ACTIVATION BOUNDARY
==================================================

A6.2 / A6.3 / A6.3.1 / A6.4 are CLOSED.

Do NOT redesign them.

A6.4 remains the only activation/provisioning authority.

Activation already establishes:

- canonical directory entity;
- OWNER business_membership;
- claim_status;
- application ACTIVATED;
- audit;
- target_entity_id traceability.

V1-R03 consumes that result.

It must NOT create a second ownership-provisioning path.

Do NOT repeat A6.4 Live QA unless V1-R03 changes an A6.4-owned behavior.

==================================================
14. DATABASE / MIGRATION
==================================================

Expected new migration:

00019_business_ownership_management_foundation.sql

Do NOT edit migrations 00001–00018.

Migration should be additive.

Expected responsibilities:

- internal business-management authorization helper;
- list_my_businesses RPC;
- list_business_members RPC;
- narrow grants/revokes;
- any strictly necessary comments/constraints only.

Do NOT add unrelated tables.

Do NOT add invitation tables.

Do NOT alter subscription schema.

Do NOT alter application lifecycle states.

Do NOT widen direct table privileges.

==================================================
15. RLS / GRANT CONTRACT
==================================================

Preserve least privilege.

Client-facing RPCs:

authenticated execute only.

anon:

no execute.

Internal authorization helper:

not directly executable by anon/authenticated unless repository security conventions absolutely require otherwise.

Do NOT grant authenticated direct INSERT/UPDATE/DELETE on:

business_memberships

Do NOT widen direct mutations on:

directory_entities
business_applications
audit_logs
staff tables

Existing own-membership RLS must remain safe.

If current grants are broader than this contract expects:

DO NOT paper over it.

Report the exact existing privilege conflict and fix only if it is directly within V1-R03 ownership security scope.

==================================================
16. TYPED ERROR CONTRACT
==================================================

Reuse established SQLSTATEs where semantically correct.

Required:

P0AUT = unauthenticated actor
P0PER = authenticated but not authorized

Do NOT create a new SQLSTATE unless an actual distinct failure needs one.

For:

list_my_businesses()

zero memberships = success + empty list.

For:

list_business_members()

no OWNER/ADMIN management membership = P0PER.

Do not leak target existence unnecessarily.

Flutter must map server failures into the project's existing typed-result/error style.

No raw PostgrestException should become normal presentation contract.

==================================================
17. AUDIT LOGGING
==================================================

V1-R03 operations defined here are READ operations.

Do NOT create audit-log noise for normal reads.

No audit record is required for:

list_my_businesses
list_business_members

Future membership mutations, if ever implemented, will require a separate audit contract.

==================================================
18. UI / ROUTING
==================================================

UI = NO for V1-R03.

Do NOT add:

- My Businesses screen;
- member management screen;
- routes;
- navigation items;
- business editor UI;
- application UI.

V1-R04 and V1-R06 own later presentation.

Domain/data/DI changes only.

==================================================
19. FLUTTER ARCHITECTURE
==================================================

Follow existing feature-first architecture.

Prefer:

presentation → domain contracts → gateways → Supabase

No networking/database logic inside widgets.

Wire through AppDependencies using existing conventions.

Do not introduce another state-management package.

Do not refactor unrelated Provider/go_router architecture.

No unnecessary abstractions.

==================================================
20. TEST CONTRACT
==================================================

Add focused V1-R03 tests.

Expected test file naming:

test/v1_r03_business_ownership_management_test.dart

or the repository's nearest established naming convention.

At minimum prove:

1. guest cannot call list_my_businesses;
2. authenticated zero-membership user gets empty list;
3. OWNER membership appears in My Businesses;
4. ADMIN membership appears in My Businesses;
5. MEMBER membership appears in My Businesses but remains non-managing;
6. multiple entity memberships are returned without ownership invention;
7. different user's entity is not leaked;
8. unknown role fails closed;
9. OWNER can list entity members;
10. ADMIN can list entity members;
11. MEMBER cannot list full entity membership roster;
12. non-member cannot list roster;
13. client cannot spoof actor user ID;
14. no email/provider-ID ownership path exists;
15. legacy futureOwnerUserId does not grant canonical ownership;
16. existing own-membership reads remain compatible;
17. no direct client membership mutation API is introduced;
18. list_my_businesses projection contains only the frozen fields;
19. roster result contains no private profile/contact data;
20. migration grants/revokes match the frozen contract.

Also run relevant regressions for:

- existing business-membership foundation;
- A6.4 activation/OWNER provisioning;
- auth/session ownership tests that are directly relevant.

Do not repeat unrelated Content Studio or visual tests.

==================================================
21. DEV DATABASE VALIDATION
==================================================

This phase changes server authorization.

Real DEV validation is REQUIRED.

But it must be FOCUSED.

Do NOT rerun the old A6.3.1 A–H QA.
Do NOT rerun all A6.4 40 cases.

Validate only V1-R03 behavior.

Use real authenticated Supabase sessions.

Do NOT emulate auth.uid() with fake session variables.

Do NOT use service_role inside Flutter/client behavior.

Administrative SQL may be used only to create controlled DEV QA fixtures where needed.

Minimum focused DEV matrix:

A. anonymous list_my_businesses → denied;

B. authenticated user with no memberships → empty list;

C. activated OWNER → own entity returned with OWNER role;

D. another user's entity → not leaked;

E. OWNER list_business_members → allowed;

F. ADMIN list_business_members → allowed;

G. MEMBER list_business_members → P0PER;

H. non-member list_business_members → P0PER;

I. authenticated direct INSERT business_memberships → denied;

J. authenticated direct UPDATE business_memberships → denied;

K. authenticated direct DELETE business_memberships → denied;

L. anon execution grants absent;

M. helper direct execution absent if frozen as internal-only;

N. no application / claim / verification / subscription rows mutate during reads;

O. temporary QA fixture cleanup → zero unintended residue.

If existing A6.4 QA identities/fixtures safely support these checks, reuse them.

Do not recreate unnecessary QA infrastructure.

==================================================
22. MIGRATION VALIDATION
==================================================

Before apply:

Supabase migration dry-run / equivalent established workflow.

Confirm only 00019 is pending.

After apply to linked civilpedia-dev:

- local/remote migration parity through 00019;
- DB lint/schema validation;
- function signatures;
- ACL/grants;
- helper visibility;
- authenticated/anon execution boundaries.

Do NOT deploy to production.

DEV only.

==================================================
23. REGRESSION / QUALITY GATES
==================================================

Because this is security/backend-sensitive:

Run one appropriate full Flutter regression after focused tests are green.

Expected:

flutter test

Also run:

flutter analyze lib/

and repository-wide:

flutter analyze

Acceptance:

no new relevant diagnostics.

Established repository analyzer debt must not be cleaned in this phase.

Run:

git diff --check
git status --short

No APK build is required unless compilation cannot otherwise be proven or a concrete build issue appears.

No UI visual QA is required because UI = NO.

==================================================
24. PROTECTED / NON-SCOPE AREAS
==================================================

Do NOT touch unless required by a proven V1-R03 dependency:

Content Studio
draft_jsons
app_ready_jsons
generated catalogs
Encyclopedia
Tools
Projects
Saved
Home UI
Directory UI
monetization
ads
subscriptions
payments
marketplace
RFQ
push notifications
release configuration

Do NOT edit generated files.

Do NOT touch:

OpenCode_Usage_Report.txt

==================================================
25. IMPLEMENTATION PHILOSOPHY
==================================================

Fix root cause only.

No hacks.

No speculative cleanup.

No unrelated refactors.

No duplicate logic.

No second ownership authority.

No widening permissions for convenience.

No client-trusted authorization.

No hidden scope expansion.

==================================================
26. REVIEW / GIT RULES
==================================================

Everything remains UNSTAGED after implementation.

Codex MUST NOT:

git add
git commit
git push

The Owner performs final staging and commit only after:

Codex implementation complete
→ Big Pickle independent review
→ Codex fixes findings if any
→ focused reviewer recheck if fixes are small
→ ChatGPT Architect Final Review
→ Owner staging/commit/push.

==================================================
27. REQUIRED FINAL REPORT
==================================================

Return:

# V1-R03 — Codex Implementation Report

## Preflight
- branch
- starting HEAD
- origin parity
- initial git status
- roadmap current phase
- contract pointer
- implementation authorization

## Repository Audit
- existing BusinessMembership model
- existing gateway
- existing capability resolver
- relevant RLS/grants
- relevant A6.4 ownership result
- conflicts found or none

## Architect Contract Compliance
- identity authority
- ownership authority
- roles
- capability semantics
- no duplicate ownership authority

## Migration 00019
- exact functions
- ACLs
- direct grants unchanged
- migration parity

## My Businesses
- projection fields
- auth behavior
- empty behavior
- isolation behavior

## Member Roster
- OWNER
- ADMIN
- MEMBER
- non-member
- privacy fields

## Server Authorization Helper
- exact behavior
- execution grants

## Flutter
- models/projections
- gateways
- typed results/errors
- DI

## Focused Tests
- counts/results

## Relevant Regressions
- results

## DEV QA
- A–O results
- real auth confirmation
- cleanup result

## Full Flutter Test
- result

## Analyzer
- lib/
- full baseline
- new findings

## Database Validation
- dry-run
- apply
- parity
- lint

## Scope Audit
Confirm NO:
- invitations
- membership mutations
- profile editing
- Directory cloud migration
- UI/routes
- subscriptions/monetization
- generated content changes

## Git Integrity
- git diff --check
- git status
- staged = NO
- committed = NO
- pushed = NO
- OpenCode_Usage_Report.txt untouched

## Final Decision

Use exactly one:

IMPLEMENTATION COMPLETE — READY FOR INDEPENDENT REVIEW

or

IMPLEMENTATION BLOCKED — ARCHITECT DECISION REQUIRED
