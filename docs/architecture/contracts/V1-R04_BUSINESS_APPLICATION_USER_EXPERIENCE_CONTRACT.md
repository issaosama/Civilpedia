# CIVILPEDIA V1-R04 — BUSINESS APPLICATION USER EXPERIENCE
## Architect Contract Freeze + Implementation Authorization

CONTRACT_ID: V1-R04-CONTRACT-v1

You are Big Pickle.

ROLE:
Main Implementer for Civilpedia V1-R04.

This is a presentation-layer / user-experience phase for the existing production
business-application backend.

You MUST follow the repository's canonical roadmap:

docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md

Do not infer another phase.

The Architect now explicitly freezes V1-R04 and authorizes implementation under
THIS contract.

Main Implementer: Big Pickle
Independent Reviewer: Codex
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

7c05c2926b883b343ffb9d563c92239ad994b7b5
docs: finalize V1-R03 closure record

Expected prior production milestones:

c7852ce
V1-R03 — Business Ownership & Management (CLOSED)

12b1918
A6.3.1 — Creation Authorization Hardening

7aafc9f
A6.4 — Business Activation & Ownership Provisioning

Expected migration history:

00001 → 00019

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

HEAD == origin/main == 7c05c2926b883b343ffb9d563c92239ad994b7b5

and no tracked modifications.

If repository reality materially contradicts this contract:

PREFLIGHT BLOCKED — ARCHITECT DECISION REQUIRED

STOP.

Do not improvise.

==================================================
2. ROADMAP CONTROL TRANSITION
==================================================

The roadmap currently says:

CURRENT_PHASE_ID: V1-R04
CURRENT_PHASE_TITLE: Business Application User Experience
CURRENT_PHASE_CONTRACT: NOT_FROZEN
IMPLEMENTATION_AUTHORIZED: NO

This Architect prompt is the authorization.

Before product-code changes, update ONLY the control state necessary to reflect
this contract:

CURRENT_PHASE_CONTRACT: V1-R04-CONTRACT-v1
IMPLEMENTATION_AUTHORIZED: YES

Do NOT:
- close V1-R04;
- advance V1-R05;
- alter roadmap order;
- change V1/Post-V1 scope.

Also persist this Architect contract as:

docs/architecture/contracts/V1-R04_BUSINESS_APPLICATION_USER_EXPERIENCE_CONTRACT.md

Preserve the contract faithfully.
Do not reinterpret or expand it.

This documentation remains part of the eventual atomic V1-R04 commit.

==================================================
3. PHASE GOAL
==================================================

Build the production Applicant-facing Business Application user experience on
top of the existing, already-authorized backend seams (A6.2, A6.3.1, A6.4,
V1-R03).

At completion an authenticated user must be able to:

A. see their own business applications (My Applications list);

B. open an application and see its canonical snapshot: application type,
   status, created date, metadata, target entity, return reason, and valid
   next actions for the CURRENT status only;

C. file a NEW business application (business name + canonical entity type) as
   a server-authorized DRAFT (createNewDraft) and then submit it
   (submitApplication);

D. select a claimable/unclaimed public directory entity and file a CLAIM
   application for it as a server-authorized DRAFT (createClaimDraft) — using
   the canonical directory_entities identity, NEVER a local
   ServiceBusinessProfile id — and then submit it (submitApplication);

E. when an application is returned for correction, read the authoritative
   returnReason and resubmit it (resubmitApplication);

F. understand life-cycle state at a glance through one reusable Arabic-first
   Business Application status chip.

This phase builds the Applicant UX.

It does NOT build:
- Staff/admin operations UI;
- Business profile management/editing;
- Membership mutation UI;
- Directory cloud migration;
- any new database migration;
- any new RPC outside the single defined claim-target read.

==================================================
4. CANONICAL AUTHORITIES
==================================================

These are frozen.

Human identity authority:

auth.users.id / auth.uid()

Business application authority:

business_applications

Directory/business entity authority:

directory_entities

Claimability authority (DO NOT soften, duplicate, or bypass):

directory_entities.claim_status
- 'unclaimed' → CLAIM possible
- 'pending'   → NOT claimable (fail closed)
- 'claimed'   → NOT claimable (fail closed)

Application life-cycle states are exactly the nine canonical statuses:

DRAFT
SUBMITTED
UNDER_REVIEW
NEEDS_CORRECTION
CONTACTED
VISIT_SCHEDULED
APPROVED
REJECTED
ACTIVATED

Unknown/unrecognized status: fail safe. Show a neutral label; expose NO
destructive or provisional action.

APPROVED remains live until activation. ACTIVATED and REJECTED are final.

Application status, claim state, verification state, subscription state and
business membership role remain separate concepts.

==================================================
5. SCOPE BOUNDARIES — DO NOT
==================================================

Do NOT touch:
- business_applications table DDL or RLS;
- migrations 00001-00019 content;
- create_new_business_application /
  create_claim_business_application /
  submit_business_application /
  resubmit_business_application;
- ANY staff_* RPC (staff_begin_application_review,
  staff_return_application_for_correction, staff_mark_application_contacted,
  staff_schedule_application_visit, staff_approve_business_application,
  staff_activate_business_application, staff_reject_business_application);
- the A6.1/A6.3/V1-R03 membership and ownership domain;
- DirectoryRepository, SbProfilesDirectoryRepository,
  LocalServiceBusinessRepository, ServiceBusinessProfile,
  DirectoryQueryEngine;
- plan/tier/subscription features;
- any offline write queue (that is V1-R09 scope).

Do NOT create a database migration (no 00020) for this phase.
The single defined claim-target read MUST use an existing table and existing
RLS via authenticated PostgREST SELECT.

==================================================
6. CLAIM-TARGET READ SEAM (narrow, additive, read-only)
==================================================

Rationale — local Directory identity is NOT the claim identity:
- LocalServiceBusinessProfile / ServiceBusinessProfile rows are local Directory
  projections. Their id is a local value and MUST NOT be passed as
  createClaimDraft(p_target_entity_id). Passing it would be a type confusion.
- The canonical claim target identity is public.directory_entities.id.

Required delivery — ONE narrow additive seam:

NEW model: BusinessClaimTarget
NEW gateway: BusinessClaimTargetGateway

Seam definition:
- authenticated PostgREST SELECT on public.directory_entities;
- projection (minimal, exactly needed for claim selection and display):
  id, name, entity_type, claim_status, and optionally verification_status;
- client filter: claim_status = 'unclaimed';
- read ONLY active rows already visible under existing RLS
  (directory_entities_select_active);
- NO new table, NO new RPC, NO migration;
- do NOT modify DirectoryRepository / SbProfilesDirectoryRepository /
  LocalServiceBusinessRepository / ServiceBusinessProfile /
  DirectoryQueryEngine.

If the authenticated directory_entities SELECT cannot supply unclaimed active
targets under the existing database contract, STOP:

IMPLEMENTATION BLOCKED — ARCHITECT DECISION REQUIRED

and report exactly that.

==================================================
7. NEW-APPLICATION FORM — CANONICAL ENTITY TYPES
==================================================

The NEW form collects exactly:

- name (metadata key 'name', per BusinessApplicationMetadata.name)
- entity_type (metadata key 'entity_type', per
  BusinessApplicationMetadata.entityType)

Entity-type options MUST come from the exact canonical database CHECK values
(migration 00005), NOT from the profile's BusinessType vocabulary:

company
engineering_office
contractor
supplier
store
technician
laboratory
equipment_provider
service_provider

Add the smallest canonical Flutter source of these nine canonical values if
none already exists. Both name and entity_type are required before the user can
file the DRAFT. The draft is created with createNewDraft and is NOT
auto-submitted.

==================================================
8. STATUS UX CONTRACT
==================================================

One reusable Business Application status chip/badge widget (Business domain).
Shared by the list and the detail screen.

Requirements:
- all nine canonical statuses have an Arabic-first localized label;
- the chip includes BOTH an icon and a text label (never color-only);
- unknown status fails safe (neutral display, no action);
- chip colors derive from existing AppColors / design tokens.

Do NOT reuse DirectoryVerificationBadge / DirectoryVerificationPresentation
(different domain, different semantics).

==================================================
9. CORRECTION / RESUBMIT CONTRACT
==================================================

When status == NEEDS_CORRECTION:
- display the authoritative returnReason verbatim (localized container label
  "سبب الإعادة" / equivalent);
- the ONLY applicant action allowed by the system is resubmit via
  resubmitApplication();
- show the valid actions for NEEDS_CORRECTION only.

Repository reality (from the A6.x audit):
- There is NO generic applicant metadata-update RPC and NO table UPDATE path
  for applicants (authenticated UPDATE is revoked; creation/lifecycle are
  server-authorized RPCs only).
- Therefore DO NOT invent application metadata editing in this phase.

If a required correction cannot be performed with the existing authorized
backend (i.e., the correction genuinely requires editing metadata that the
applicant cannot edit under the authorized seams), then BEFORE inventing any
mutation, STOP and report:

CORRECTION FLOW BLOCKED — ARCHITECT DECISION REQUIRED

with the precise scenario.

Resubmitting MUST call resubmitApplication() and reflect the authoritative
returned application.

==================================================
10. SUBMIT / RESUBMIT CONTRACT
==================================================

Submit and resubmit are server-authorized RPC mutations
(submit_business_application / resubmit_business_application).

Client requirements:
- NEVER send application status, applicant id, or metadata to these RPCs;
- prevent double-taps while a submit/resubmit is in flight;
- after success, replace the displayed application with the authoritative
  application returned by the RPC (no fake optimistic state change);
- on typed denial, map each BusinessApplicationSubmitCause to a concise
  Arabic-first message;
- never surface a raw PostgrestException or SQLSTATE.

==================================================
11. GUEST / OFFLINE / ERROR CONTRACT
==================================================

Guest: An application list/entry requires authentication. A signed-out user
sees the sign-in-required UX (no local/guest applications, no fake empty
state implying "no applications yet").

Offline/error:
- retry is always available;
- form input is retained across transient failures (no silent data loss);
- never show an infinite spinner;
- never show fake success;
- errors are presented via the existing EmptyStateWidget / ErrorStateWidget /
  AsyncValueWidget family.

No offline write queue (that is V1-R09 scope).

==================================================
12. DESIGN SYSTEM CONTRACT
==================================================

Reuse existing primitives:
- CivilAppBar
- CivilSurfaceCard
- SectionHeader
- AsyncValueWidget
- EmptyStateWidget
- ErrorStateWidget
- SearchBarWidget
- AnimatedListItem
- AppColors / AppSpacing / DesignTokens / AppTypography
- ShellContentInsets

Arabic-first, RTL-correct, dark-mode compatible.

State management: Provider (ChangeNotifier). No Riverpod, no BLoC, no GetX.

Widgets must not call Supabase directly; all reads/writes go through gateways
wired in AppDependencies.

==================================================
13. ROUTES / ENTRY POINT
==================================================

Add routes to the existing AppRoutes + app_router conventions:

/business/applications
/business/applications/new
/business/applications/claim
/business/applications/:id

Entry points:
- User Area (/user) MUST expose the My Applications entry point, labeled via
  localization keys (e.g. Arabic "طلباتي التجارية").
- NO new bottom-navigation tab.
- NO staff navigation.

If new providers are route-scoped, create them via ChangeNotifierProvider under
router builders consistent with existing patterns.

==================================================
14. DELIVERABLE STRUCTURE
==================================================

Create (extend nothing outside this list):

lib/features/business/presentation/
  providers/
    business_application_provider.dart        (application list + detail +
                                               submit/resubmit/create flows)
    business_claim_target_provider.dart       (claim target list/selection)
  screens/
    my_applications_screen.dart
    application_detail_screen.dart
    application_new_form_screen.dart
    application_claim_form_screen.dart
  widgets/
    business_application_status_chip.dart     (reusable, single source)
    business_application_status_labels.dart   (if needed for labels/icons)

lib/features/business/domain/
  business_claim_target.dart                  (new model)
  directory_entity_types.dart                 (canonical nine values)

lib/features/business/data/
  business_claim_target_gateway.dart          (interface)
  supabase_business_claim_target_gateway.dart (PostgREST implementation)

lib localizations:
  add keys to lib/localization/ar.dart and lib/localization/en.dart

Tests:
  test/v1_r04_business_application_ux_test.dart

==================================================
15. MY APPLICATIONS LIST
==================================================

Screen: /business/applications

Sources: BusinessApplicationProvider.loadApplications() →
ApplicantGateway.listOwnApplications(currentUserId).

Title via localization keys. Rows are Business-application cards (CivilSurfaceCard
family), showing: name (from metadata), entity type label (if NEW), target name
(if CLAIM), status chip, created date.

Empty state uses EmptyStateWidget (never a fake "authenticate later" message;
distinct for guest sign-in required).

Refresh (pull-to-refresh or refresh action) reloads authoritatively.

==================================================
16. APPLICATION DETAIL
==================================================

Screen: /business/applications/:id

Sources: BusinessApplicationProvider.getApplication(id) →
ApplicantGateway.getOwnApplication(currentUserId, id).

Layout:
- CivilAppBar with application title (back navigation);
- status chip (canonical);
- Life-cycle info: application type, created date, current status;
- metadata section (name, entity_type) for NEW applications;
- claim target section (target name, entity_type, claim status) for CLAIM
  applications;
- return-reason card when status == NEEDS_CORRECTION (localized header +
  returnReason verbatim);
- actions section that renders valid actions for the CURRENT status only:
  DRAFT → Submit (and only for NEW: Edit remains a navigation to the form? No:
  editing is out of scope under §9 — DRAFT shows Submit only);
  NEEDS_CORRECTION → Resubmit;
  all other statuses → no applicant action.

Wait — §9 forbids invented metadata editing; editing a DRAFT is also metadata
mutation and is out of scope. DRAFT shows Submit. New drafts are filed from the
form once.

Action taps are debounced/disabled while in flight.

For the target, the DETAIL screen may display only what is already present on
the application row (target_entity_id, and the target's name/entity_type if
available). The claim-target read seam is for the CLAIM selector screen only.

==================================================
17. NEW APPLICATION FORM
==================================================

Screen: /business/applications/new

Collects name + entity_type using the canonical DirectoryEntityType source.

Validation:
- name required, trimmed non-empty;
- entity_type required, one of the nine canonical values.

Submit behavior:
- createNewDraft → BusinessApplicationCreated (DRAFT) → navigate to detail or
  back to list with the created DRAFT in view;
- on typed denial, map the BusinessApplicationRejectionCause to an Arabic-first
  message;
- guest → sign-in-required UX.

DRAFT is NOT auto-submitted.

==================================================
18. CLAIM APPLICATION FORM
==================================================

Screen: /business/applications/claim

Behavior:
- load unclaimed active claim targets via BusinessClaimTargetGateway;
- represent each as a BusinessClaimTarget card/filterable list (SearchBarWidget
  families if needed);
- selecting a target files createClaimDraft(target.targetEntityId) — the
  canonical directory_entities.id;
- never pass a local ServiceBusinessProfile.id as targetEntityId;

Wait — the gateway signature must be unambiguous. The seam names the canonical
column:

BusinessClaimTarget { id (directory_entities.id), name, entity_type,
claimStatus, verificationStatus }

and createClaimDraft receives BusinessClaimTarget.id.

- on typed denial (duplicateClaim, targetNotClaimable, targetNotFound,
  missingTarget, guestUser, alreadyOwner), map to Arabic-first messages;
- refresh reloads the unclaimed list (authoritative).

==================================================
19. PROVIDER / STATE CONTRACT
==================================================

BusinessApplicationProvider (ChangeNotifier):
- authenticated session user id: taken from AuthProvider.session.userId (must
  exist; otherwise the provider reports the sign-in-required state);
- states for list: loading / data / error / empty / signInRequired;
- states for detail: loading / data (current application) / error /
  signInRequired;
- one mutation at a time (in-flight guard) with typed result exposure;
- after an in-flight mutation the authoritative returned application replaces
  the held application.

BusinessClaimTargetProvider (ChangeNotifier):
- states: loading / data / error / empty;
- reload() re-queries the authoritative unclaimed set.

State classes are immutable / simple value types. Keep logic lean; do not
duplicate policy evaluation that already lives in BusinessApplicationPolicy /
gateways.

==================================================
20. LOCALIZATION
==================================================

Add all Business Application strings to the central localization files
(lib/localization/ar.dart and lib/localization/en.dart).

Arabic strings are authoritative.
English strings remain secondary/fallback.

Patterns already in use: static const String getters in Ar and En classes.
Keep RTL-correct Arabic and the existing key style.

==================================================
21. QUALITY GATES
==================================================

Run in this order:

1. Focused V1-R04 tests:
   flutter test test\v1_r04_business_application_ux_test.dart

2. Relevant business regressions (must stay green):
   flutter test test\a6_1_business_membership_test.dart
   flutter test test\a6_2_business_application_test.dart
   flutter test test\a6_3_business_application_mutation_test.dart
   flutter test test\a6_3_1_business_application_creation_authorization_test.dart
   flutter test test\a6_4_business_application_activation_test.dart
   flutter test test\v1_r03_business_ownership_management_test.dart
   flutter test test\service_business_profile_test.dart

3. Full analyzer:
   flutter analyze lib/
   flutter analyze

4. Full Flutter suite:
   flutter test

All must be green before the phase can be considered complete.

==================================================
22. FOCUSED TESTS (minimum 32 cases)
==================================================

test/v1_r04_business_application_ux_test.dart must cover at least:

A. BusinessApplicationStatusChip (canonical, reusable):
  1. renders a label for every one of the nine canonical statuses;
  2. every canonical status chip includes a semantic icon and text label;
  3. unknown status fails safe (no action, neutral label, no crash);
  4. the nine canonical statuses match the domain BusinessApplicationStatus
     values exactly.

B. DirectoryEntityType canonical source:
  5. exactly nine canonical values;
  6. values match the migration 00005 CHECK list exactly;
  7. isKnown(type) fails closed for an unknown value.

C. BusinessClaimTarget model + gateway (unit):
  8. parses a canonical row (id/name/entity_type/claim_status);
  9. parses claim_status unclaimed/pending/claimed only, fails safe otherwise;
 10. unknown claim_status → fails safe (not claimable);
 11. request filters do NOT encode a local ServiceBusinessProfile id (no
     cross-domain id leakage);
 12. gateway returns only unclaimed targets from the server (authoritative
     filter held client-side as UX guard only).

D. NEW form state (controller/model-level):
 13. name required: blank/whitespace is rejected;
 14. entity_type required: none selected is rejected;
 15. entity_type options are exactly the canonical nine;
 16. valid input produces the exact metadata map (name/entity_type) using
     BusinessApplicationMetadata keys;
 17. no auto-submit after draft creation (draft creation and submit are
     separate explicit actions).

E. CLAIM form state:
 18. selecting a target produces createClaimDraft(canonical target id);
 19. the canonical target id passed is BusinessClaimTarget.id
     (directory_entities.id), never a local service-business profile id;
 20. duplicateClaim, targetNotClaimable, targetNotFound, missingTarget typed
     denials map to localized messages.

F. Provider list/detail semantics:
 21. list maps to SignInRequired when there is no authenticated session;
 22. list shows official empty state when the user has zero applications;
 23. detail resolves the application by id from the authoritative list/read;
 24. detail refuses / shows not-found for an application owned by another user;
 25. refresh reloads authoritatively (no cache-only truth).

G. Submit/resubmit semantics:
 26. submitApplication is called only from DRAFT (valid-action gating);
 27. resubmitApplication is called only from NEEDS_CORRECTION;
 28. no double-submit: a second tap while in flight is ignored;
 29. after success the held application is replaced by the authoritative
     returned application;
 30. typed submit denials map to Arabic-first messages and never surface raw
     SQLSTATE/PostgrestException.

H. Guest / offline / error:
 31. guest sees the sign-in-required UI, never a misleading empty state;
 32. error state exposes retry; form input is retained across a transient
     failure (no silent data loss).

==================================================
23. REPORT
==================================================

Final report must be produced by the Main Implementer as:

# V1-R04 — Big Pickle Implementation Report

Sections:
- Preflight
- Roadmap Control
- Contract Persistence
- Claim-Target Seam (§6)
- Status UX (§8)
- NEW form (§17)
- CLAIM form (§18)
- Detail + resubmit (§9, §16)
- Routes / Entry (§13)
- Localization (§20)
- Tests (§22)
- Quality gates (§21)
- Boundaries respected (§5)
- Known limitations / decisions

Final Decision (exactly one of):

IMPLEMENTATION COMPLETE — READY FOR INDEPENDENT REVIEW

or

IMPLEMENTATION BLOCKED — ARCHITECT DECISION REQUIRED

==================================================
24. STOP CONDITIONS
==================================================

STOP and report IMPLEMENTATION BLOCKED — ARCHITECT DECISION REQUIRED when any
of:

1. preflight contradicts §1;
2. the CLAIM read seam cannot produce unclaimed active targets under the
   existing database contract (§6);
3. a required correction genuinely cannot be performed under the authorized
   backend seams and would require inventing a new mutation (§9);
4. any of the §5 "do not touch" boundaries is required to satisfy user flow.

Otherwise complete per §21 order and report per §23.