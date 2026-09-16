# CIVILPEDIA — CREATE CANONICAL V1 MASTER ROADMAP

## ROLE

You are Big Pickle.

For this task you are NOT implementing a product feature.

Your only job is to persist the Owner/Architect-approved Civilpedia V1 roadmap as the repository's canonical roadmap authority so that future agents never guess the current or next phase.

Do NOT reinterpret, redesign, reorder, expand, or implement the roadmap.

Do NOT stage, commit, or push.

---

# CANONICAL FILE

Create:

docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md

If this exact file already exists:

STOP.

Do not overwrite it.

Report its contents and the conflict to the Architect.

Do not create an alternative roadmap file.

---

# AUTHORITY RULE

This file becomes the Single Source of Truth for Civilpedia V1 execution order.

Future agents MUST use it to answer:

- What phase are we currently in?
- What comes next?
- What has already closed?
- What is V1 scope?
- What is Post-V1?
- Which agent should implement the current phase?
- How much review/QA is required?

Agents MUST NOT infer the next phase from:
- chat memory;
- filenames;
- Git history alone;
- TODO comments;
- architecture speculation;
- unfinished UI;
- personal preference.

Repository reality may be used to VERIFY the roadmap, never silently replace it.

If repository reality materially contradicts the roadmap:

return exactly:

ROADMAP CONFLICT — ARCHITECT DECISION REQUIRED

and STOP.

---

# ROADMAP HEADER

Write this header near the top:

ROADMAP_VERSION: 1
ROADMAP_AUTHORITY: OWNER + CHATGPT ARCHITECT
PRODUCT_TARGET: PRODUCTION-GRADE CIVILPEDIA V1
CURRENT_PHASE_ID: V1-R09
CURRENT_PHASE_TITLE: Offline / Connectivity / Error Hardening
LAST_CLOSED_PHASE_ID: V1-R08
LAST_CLOSED_COMMIT: PENDING OWNER COMMIT
ROADMAP_STATUS: ACTIVE

---

# PHASE CONTROL TABLE

| ID | Phase | Status | Main | Reviewer | Risk | Closure Commit |
| --- | --- | --- | --- | --- | --- | --- |
| A6.3.1 | Creation Authorization Hardening | CLOSED | Codex | Big Pickle | HIGH | 12b1918 |
| A6.4 | Business Activation & Ownership Provisioning | CLOSED | Codex | Big Pickle | HIGH | 7aafc9f |
| V1-R03 | Business Ownership & Management | CLOSED | Codex | Big Pickle | HIGH | c7852ce |
| V1-R04 | Business Application User Experience | CLOSED | Big Pickle | Codex (backend/security) | MEDIUM | 55a624a |
| V1-R05 | Directory Cloud Integration | CLOSED | Codex (persistence/cloud) | Architect | HIGH | PENDING OWNER COMMIT |
| V1-R06 | Business / Provider Profile Management | CLOSED | Codex (backend) / Big Pickle (UI) | TBD BY ARCHITECT | HIGH | PENDING OWNER COMMIT |
| V1-R07 | Staff / Admin Operations Foundation | CLOSED | TBD BY ARCHITECT | TBD BY ARCHITECT | HIGH | PENDING OWNER COMMIT |
| V1-R08 | Auth + Profile Production Completion | CLOSED | Codex | TBD BY ARCHITECT | HIGH | PENDING OWNER COMMIT |
| V1-R09 | Offline / Connectivity / Error Hardening | CURRENT | Big Pickle | TBD BY ARCHITECT | MEDIUM | — |
| V1-R10 | Core App UX Production Completion | QUEUED | Big Pickle | TBD BY ARCHITECT | MEDIUM | — |
| V1-R11 | Projects Production Pass | QUEUED | Big Pickle | TBD BY ARCHITECT | MEDIUM | — |
| V1-R12 | Tools / Calculators Final Engineering QA | QUEUED | Big Pickle | TBD BY ARCHITECT | MEDIUM | — |
| V1-R13 | Encyclopedia / Content Studio Finalization | QUEUED | Big Pickle | TBD BY ARCHITECT | MEDIUM | — |
| V1-R14 | Supabase Production Readiness | QUEUED | Codex | TBD BY ARCHITECT | HIGH | — |
| V1-R15 | Security & Abuse Review | QUEUED | Codex | Big Pickle | HIGH | — |
| V1-R16 | Performance & Release Hardening | QUEUED | TBD BY ARCHITECT | TBD BY ARCHITECT | MEDIUM | — |
| V1-R17 | Final End-to-End QA | QUEUED | TBD BY ARCHITECT | TBD BY ARCHITECT | MEDIUM | — |
| V1-R18 | Release Preparation | QUEUED | TBD BY ARCHITECT | TBD BY ARCHITECT | HIGH | — |
| V1-R19 | Production Launch V1 | QUEUED | Owner (final authority) | TBD BY ARCHITECT | HIGH | — |

Rules for this table:

- `—` means not yet closed/assigned; closure commits exist only for CLOSED phases.
- Risk HIGH is assigned only where the phase clearly involves security/auth/database/production-backend/release-security concerns; ambiguous risk is resolved by the Architect, never inferred.
- This table is a routing view of the authoritative sections below, not a replacement for them.

---

# CURRENT PHASE CONTROL

CURRENT_PHASE_ID: V1-R09
CURRENT_PHASE_TITLE: Offline / Connectivity / Error Hardening
CURRENT_PHASE_STATUS: CURRENT
CURRENT_PHASE_CONTRACT: V1-R09-CONTRACT-v1
IMPLEMENTATION_AUTHORIZED: YES

A roadmap CURRENT status identifies execution order.
It does NOT by itself authorize implementation.

Implementation begins only after ChatGPT Architect supplies the phase-specific Contract Freeze / implementation prompt.

---

# PRODUCT TARGET

Civilpedia V1 is NOT:

- an MVP;
- beta;
- experimental release;
- prototype;
- preliminary release.

The target is a polished, stable, production-grade V1.

This does NOT mean Civilpedia will never evolve.

It means the functionality deliberately included in V1 must be production-complete.

Canonical principle:

SCOPE MAY BE LIMITED.
QUALITY MAY NOT BE LIMITED.

A feature may be deferred completely.

A feature included in V1 may NOT remain knowingly half-built, mocked, DEV-only, insecure, placeholder-driven, or structurally temporary in its primary user journey.

---

# CORE ARCHITECTURE RULES

Preserve these throughout all remaining phases:

1. Arabic-first / RTL product.
2. Offline-first where the product contract requires it.
3. Flutter client.
4. Supabase server authority for security-sensitive operations.
5. `auth.users.id` is canonical human identity.
6. Personal Profile is separate from Business/Directory identity.
7. `business_memberships` is canonical business ownership/access authority.
8. OWNER / ADMIN / MEMBER are business roles.
9. Directory verification, business ownership, application approval, application activation, subscriptions, sponsorship, and monetization are separate concepts.
10. No client-side shortcut may replace server authorization.
11. No duplicate ownership authority such as `directory_entities.owner_user_id`.
12. No hacks or unnecessary refactors.
13. Fix root cause.
14. Preserve compatibility unless a dedicated migration phase explicitly changes it.
15. Content Studio draft JSON remains encyclopedia authoring SSOT.
16. Generated encyclopedia outputs must never be manually edited.
17. Marketplace/payments/commissions/full monetization remain outside V1 unless the Owner explicitly promotes them.

---

# CONTENT SSOT

Canonical authoring flow:

draft_jsons/*.draft.json
→ Export
→ app_ready_jsons/
→ assets/encyclopedia/
→ catalog.generated.json
→ Flutter Encyclopedia

Generated files are derived outputs.

Never manually edit generated files as the primary fix.

Preview identity target:

Editor → Preview → Flutter

must remain visually/semantically aligned.

---

# AGENT WORKFLOW

## ChatGPT

Role:

Architect / Planner / Prompt Engineering / Contract Freeze / Final Review.

Responsibilities:

- read this roadmap;
- identify CURRENT phase;
- define exact scope;
- freeze architecture decisions;
- choose implementation agent;
- choose reasoning effort;
- review final evidence;
- authorize progression recommendation.

---

## Big Pickle

Main Implementer for:

- everyday Flutter features;
- UI;
- clear integration work;
- UX;
- local/offline features;
- normal feature implementation.

Also acts as Independent Reviewer when Codex is Main Implementer.

---

## Codex

Main Implementer for heavy/sensitive work involving:

- Supabase;
- Auth;
- PostgreSQL;
- migrations;
- RLS;
- RPCs;
- Security;
- ownership;
- permissions;
- architecture-sensitive persistence;
- concurrency;
- transactional integrity.

Also acts as Independent Reviewer when Big Pickle is Main Implementer and backend/security expertise is useful.

---

## Owner

Final authority.

Only the Owner authorizes:

- final commit;
- push;
- roadmap scope promotion;
- V1 scope expansion;
- production deployment;
- launch.

---

# ONE-WRITER RULE

Big Pickle and Codex MUST NOT modify the repository simultaneously.

One Main Implementer at a time.

The independent reviewer does NOT implement fixes.

If the reviewer finds a defect:

original implementer fixes it.

Reviewer then performs only the appropriate recheck.

---

# PROPORTIONAL VERIFICATION RULE

Verification depth must match change risk.

Previously successful evidence remains valid unless a later change could invalidate it.

Do NOT repeat expensive successful QA without a concrete reason.

## SMALL LOCAL CHANGE

Use:

- focused reviewer recheck;
- directly affected tests;
- `git diff --check`;
- diff review;
- `git status`.

Do NOT repeat full Live QA.

---

## MEDIUM FEATURE / UI / INTEGRATION CHANGE

Use:

- focused feature tests;
- relevant regression tests;
- appropriate visual/manual QA;
- focused reviewer review;
- analyzer for affected code or required repo baseline;
- diff/status integrity.

---

## HIGH-RISK CHANGE

Examples:

- migration;
- RLS;
- RPC;
- Auth;
- ownership;
- permission;
- security boundary;
- concurrency;
- transaction;
- architecture authority.

Use the necessary combination of:

- contract review;
- focused tests;
- broader regression;
- real authenticated DEV QA where runtime database behavior matters;
- concurrency/rollback verification where relevant;
- security review;
- analyzer;
- diff/status.

Do not use MAX/Extra High automatically.

Reserve highest reasoning effort for genuinely difficult architecture/security/concurrency blockers.

---

# COMMIT GATE

No phase may be committed until appropriate evidence is green.

Minimum repository integrity:

- intended diff only;
- tests required by risk level PASS;
- analyzer has no new relevant findings;
- `git diff --check` PASS;
- `git status` understood;
- reviewer decision PASS;
- Architect Final Review PASS.

Never use:

`git add .`

when unrelated files exist.

`OpenCode_Usage_Report.txt` is unrelated and must remain untouched unless the Owner explicitly changes that rule.

---

# GLOBAL ENTRY GATE

Before any phase implementation:

- roadmap file read;
- CURRENT phase confirmed;
- previous phase CLOSED;
- previous phase pushed if applicable;
- Git state understood;
- current contract frozen by Architect;
- implementer/reviewer assigned;
- scope/non-scope clear.

If any required item is missing:

`PHASE START BLOCKED — ARCHITECT DECISION REQUIRED`

---

# GLOBAL EXIT GATE

A phase becomes CLOSED only after the risk-appropriate set of:

- implementation complete;
- required affected tests PASS;
- analyzer has no new relevant findings;
- `git diff --check` PASS;
- repository scope understood;
- required runtime/DEV QA PASS where relevant;
- independent review PASS;
- Architect Final Review PASS;
- Owner-approved atomic commit;
- push verified;
- HEAD == expected upstream state.

Do NOT require expensive Live QA for a phase that does not need it.

---

# EVIDENCE REUSE RULE

Successful verification evidence remains valid until a later change touches or can invalidate the behavior/security property that evidence proved.

Therefore:

- small test-only/documentation/local fixes use focused recheck;
- unrelated full QA is not repeated;
- Live DEV QA is repeated only when relevant server/runtime behavior changed;
- full regression is repeated when risk or scope justifies it.

No agent may rerun broad expensive QA merely out of habit.

---

# KNOWN PRODUCTION DEBT REGISTER

This is a routing register, NOT permission to fix items early.

| Debt | Assigned phase | Blocks current phase? | Notes |
| --- | --- | --- | --- |
| Backup/recovery completeness | V1-R09 / V1-R17 | NO | Assessed in the phases indicated. |
| Auth/session lifecycle hardening | V1-R08 | NO | Routed to the auth completion phase. |
| Project persistence malformed-data/data hygiene review | V1-R11 | NO | Routed to the Projects production pass. |
| Encyclopedia/content runtime fallback and asset integrity | V1-R13 | NO | Routed to the content finalization phase. |
| Supabase grants/RLS/migrations/indexes/config | V1-R14 | NO | Routed to production readiness. |
| Security bypass/abuse cases | V1-R15 | NO | Routed to the security review. |
| Android/release configuration/signing/package consistency | V1-R16 / V1-R18 | NO | Routed to hardening/release phases. |
| Documentation drift/repository hygiene | Post-V1 (unless release-relevant) | NO | Addressed only if release-relevant. |

No new debt may be added by speculation.

---

# SCOPE CHANGE PROTOCOL

Only Owner + ChatGPT Architect may:

- add a V1 phase;
- reorder phases;
- split a phase;
- promote Post-V1 scope into V1;
- remove a V1 requirement;
- change CURRENT phase manually.

Big Pickle / Codex may report a conflict but may not silently alter roadmap scope.

Required conflict output:

`ROADMAP CHANGE REQUIRED — ARCHITECT/OWNER DECISION`

---

# COMPLETED / CARRY-FORWARD BASELINE

The project already contains substantial completed work.

Do NOT reopen or rebuild it merely because later production passes exist.

Later phases may AUDIT these systems and fix proven production defects.

Completed baseline includes established work across:

- Home;
- Encyclopedia;
- Encyclopedia search;
- persistent topic favorites;
- catalog parsing/hardening;
- real loading and refresh states;
- Saved;
- article offline image fallback;
- Concrete calculator;
- Steel calculator;
- Masonry/Brick calculator;
- Tile calculator;
- Checklist;
- local Projects foundations;
- Directory V1 foundations;
- navigation architecture;
- Google/Supabase authentication foundations;
- guest/account ownership foundations;
- personal profile ownership;
- region preference;
- business membership foundation;
- business application + CLAIM foundation;
- business application lifecycle mutations;
- business application creation authorization;
- business activation and ownership provisioning.

A production pass does NOT mean reimplementation.

It means:

AUDIT → identify actual remaining production gap → smallest root-cause fix → verify.

---

# CLOSED BUSINESS MILESTONES

## A6.3.1 — Creation Authorization Hardening

STATUS: CLOSED

Commit:

12b1918

Security contract includes narrow RPC-only business application creation and prevention of forged direct lifecycle insertion.

---

## A6.4 — Business Activation & Ownership Provisioning

STATUS: CLOSED

Commit:

7aafc9f

Includes:

- APPROVED → ACTIVATED;
- NEW provisioning;
- CLAIM provisioning;
- canonical OWNER membership;
- target_entity_id linkage;
- claim serialization;
- idempotent replay;
- concurrency handling;
- atomic rollback;
- activation audit;
- independent activation permission;
- no automatic subscription creation.

This phase must NOT be reopened without concrete regression evidence.

---

# RECENTLY CLOSED PHASE

## V1-R03 — Business Ownership & Management

STATUS: CLOSED

Main Implementer:

Codex

Independent Reviewer:

Big Pickle

Recommended default effort:

HIGH for architecture/security contract and implementation.

Do not implement from this roadmap document alone.

ChatGPT Architect must first issue the phase-specific Contract Freeze / implementation prompt.

High-level objective:

Turn the newly provisioned canonical ownership relationship into a secure production business-management foundation.

Expected areas:

- list businesses the authenticated user owns/manages;
- derive OWNER / ADMIN / MEMBER capabilities;
- server-authorized business management boundaries;
- management of canonical entity data only where permitted;
- prevent Flutter from bypassing RPC/RLS authority;
- preserve `business_memberships` as ownership authority;
- determine whether member invitations/member management belongs here or becomes an explicit sub-phase.

No implementation scope should be invented beyond the Architect contract.

---

# REMAINING V1 ROADMAP

## V1-R04 — Business Application User Experience

STATUS: CLOSED

Primary likely implementer:

Big Pickle

Reviewer:

Codex where backend integration/security is involved.

Goal:

Production UI for:

- NEW application;
- CLAIM application;
- application status;
- correction reason;
- resubmission;
- review progress where appropriate;
- approved state;
- activated state;
- clear failure/error states.

Must consume existing backend authority rather than reimplement lifecycle logic client-side.

---

## V1-R05 — Directory Cloud Integration

STATUS: CLOSED

Primary likely implementer:

Codex for persistence/cloud architecture.

UI integration may later be delegated to Big Pickle as a separately frozen sub-phase.

Goal:

Move production Directory reads from compatibility/local-only authority to a cloud-backed production flow while preserving offline-first behavior.

Includes as required:

- canonical directory entities;
- categories;
- regions;
- claimed/unclaimed state;
- verification state;
- details;
- search/filter;
- local cache;
- offline fallback;
- compatibility migration.

No duplicate cloud/local business authority may remain ambiguous at completion.

---

## V1-R06 — Business / Provider Profile Management

STATUS: CLOSED

Goal:

Allow authorized business users to manage their production provider/business profile.

Potential fields:

- name;
- description;
- contact details;
- region/location;
- services/specialties;
- other frozen V1 fields.

Media/images:

Either fully implement them through proper Storage/security if explicitly included in V1, or do not expose the feature.

No placeholder upload behavior.

Backend-sensitive mutations go to Codex.

Flutter UI goes to Big Pickle.

Never edit simultaneously.

---

## V1-R07 — Staff / Admin Operations Foundation

STATUS: CLOSED

Goal:

Provide the production operational surface required to actually run V1.

May include:

- application review queue;
- corrections;
- contacts;
- visits;
- approve;
- reject;
- activate.

Server permissions remain authoritative.

Do NOT build a giant speculative admin platform.

The operational V1 scope may be limited, but whatever is included must be production-complete.

---

## V1-R08 — Auth + Profile Production Completion

STATUS: CLOSED

Primary:

Codex

Goal:

Production audit and completion of:

- Google Sign-In;
- Supabase session lifecycle;
- session restore;
- logout;
- auth state changes;
- guest → account ownership continuity;
- personal profile cloud behavior;
- region preference;
- retry/error/offline behavior;
- account switching safety;
- removal of DEV-only assumptions/hooks/secrets.

---

## V1-R09 — Offline / Connectivity / Error Hardening

STATUS: CURRENT

Part 1: CLOSED / ACCEPTED — PASS - V1-R09 PART 1 ACCEPTED - PART 2 MAY BEGIN
Part 2: CURRENT — current within V1-R09 (overall V1-R09 remains CURRENT)
Part 2 P2-A: ACCEPTED / CLOSED — PASS - P2-A ACCEPTED - P2-B MAY BEGIN
Part 2 P2-B: ACCEPTED / CLOSED
Part 2 P2-B1: ACCEPTED / CLOSED
Part 2 P2-B2: ACCEPTED / CLOSED
Part 2 P2-C: CURRENT — CONTRACT V1-R09-P2-C-CONTRACT-v1 FROZEN
Part 2 P2-C1: ACCEPTED / CLOSED
Part 2 P2-C2: NEXT — IMPLEMENTATION AUTHORIZED
Part 2 P2-D through P2-G: LOCKED
V1-R10: QUEUED (not started)

Primary:

Big Pickle

Goal:

Finish offline-first product behavior.

Audit:

- cached reads;
- offline launch;
- reconnect;
- retries;
- empty states;
- error states;
- 404/missing entities;
- skeleton/loading states;
- refresh;
- data durability;
- failed network mutations;
- user-visible recovery.

No infinite loading.

No silent destructive loss.

No fake success.

---

## V1-R10 — Core App UX Production Completion

STATUS: QUEUED

Primary:

Big Pickle

Goal:

Production polish of the whole shell and primary journeys:

- Home;
- Knowledge/Encyclopedia;
- Tools;
- Projects;
- Directory;
- Saved;
- User/Profile;
- navigation;
- typography;
- RTL;
- dark mode;
- responsive layouts;
- shared cards/tokens;
- accessibility/touch targets;
- visual consistency.

Important:

Do not redesign already-good areas without evidence.

This is a production completion pass, not a speculative redesign.

Arabic-only may remain the intentional V1 product language unless the Owner explicitly promotes English into V1.

If Arabic-only remains the decision, it is a production scope decision, not a beta limitation.

---

## V1-R11 — Projects Production Pass

STATUS: QUEUED

Primary:

Big Pickle

Existing Projects work must be audited before adding anything.

Goal:

Determine the exact current production V1 contract and close only genuine gaps.

Existing work should be reused.

Do not build a huge project-management suite merely because future possibilities exist.

Any Projects capability exposed in V1 must be complete and stable.

Future functionality such as advanced reports, collaboration, cloud sync, attachments, etc. remains outside this phase unless explicitly promoted by the Owner.

---

## V1-R12 — Tools / Calculators Final Engineering QA

STATUS: QUEUED

Primary:

Big Pickle

Engineering correctness requires human/Owner engineering review where appropriate.

Audit:

- formulas;
- units;
- conversion;
- validation;
- precision;
- boundary cases;
- labels;
- input UX;
- result clarity.

The four previously hardened calculators must not be rewritten without a proven defect.

Additional calculators are added only when explicitly within frozen V1 scope.

---

## V1-R13 — Encyclopedia / Content Studio Finalization

STATUS: QUEUED

Primary:

Big Pickle for tooling/content integration.

Engineering content still requires human engineering review.

Preserve:

draft_jsons/*.draft.json

as authoring SSOT.

Final checks include:

- required V1 content coverage;
- schema validation;
- exporter;
- app-ready output;
- catalog build;
- preview parity;
- assets;
- broken references;
- search/indexing;
- Content Studio smoke/editor/preview tests;
- Flutter rendering parity.

Never manually patch generated outputs as the source fix.

---

## V1-R14 — Supabase Production Readiness

STATUS: QUEUED

Primary:

Codex

Recommended effort:

HIGH.

Goal:

Turn validated DEV backend architecture into production-ready deployment.

Audit:

- migration chain;
- RLS;
- grants;
- SECURITY DEFINER functions;
- RPC exposure;
- constraints;
- indexes;
- database integrity;
- Storage policies if Storage is used;
- DEV/STAGING/PROD separation;
- secrets/config;
- backups/restore plan;
- production environment configuration.

Never expose `service_role` in Flutter.

PROD migration/application requires explicit Owner authorization.

---

## V1-R15 — Security & Abuse Review

STATUS: QUEUED

Primary:

Codex

Independent reviewer:

Big Pickle

Recommended effort:

HIGH, with MAX/Extra High only for genuinely difficult findings.

Attack the production boundary outside normal Flutter flows.

Test as appropriate:

- forged PostgREST calls;
- direct table mutation attempts;
- IDOR;
- role escalation;
- ownership bypass;
- CLAIM races;
- activation replay;
- malformed metadata;
- RPC misuse;
- unauthorized membership changes;
- audit integrity;
- privilege widening;
- session/account-switch issues.

No security-through-client assumptions.

---

## V1-R16 — Performance & Release Hardening

STATUS: QUEUED

Implementer chosen by Architect based on bottleneck.

Audit:

- startup;
- memory;
- large lists;
- image behavior;
- database queries;
- indexes;
- unnecessary rebuilds;
- network behavior;
- APK/AAB size;
- release configuration;
- Android permissions;
- crash handling;
- supported screen sizes;
- physical-device behavior.

Fix measured/real issues, not speculative optimization.

---

## V1-R17 — Final End-to-End QA

STATUS: QUEUED

No broad feature development belongs here.

Goal:

Prove the production product works as a whole.

Critical journey includes:

Fresh install
→ onboarding
→ guest
→ sign-in/account
→ profile
→ Home
→ Encyclopedia
→ Tools
→ Projects
→ Directory
→ NEW/CLAIM application
→ staff review
→ correction
→ resubmit
→ approve
→ activation
→ business ownership
→ business management.

Also test:

- restart;
- session restore;
- logout/login;
- account switching where supported;
- offline launch;
- disconnect/reconnect;
- previous local data/upgrade path;
- saved data persistence;
- production error states.

Record PASS / FAIL.

Only real failures create new work.

Do not refactor during E2E without a specific defect.

---

## V1-R18 — Release Preparation

STATUS: QUEUED

Goal:

Create the actual production release candidate.

Includes as applicable:

- semantic version/build number;
- production config;
- package/application IDs;
- app name;
- icon;
- splash;
- Android signing;
- privacy policy;
- terms where required;
- Play Store metadata;
- screenshots;
- release APK;
- release AAB;
- analytics/crash policy;
- final installation test.

Release candidate must run against intended production configuration.

---

## V1-R19 — Production Launch V1

STATUS: QUEUED

Final authority:

Owner.

Requirements:

- previous gates PASS;
- no unresolved release blockers;
- clean Git state;
- release/tag strategy confirmed;
- production backend confirmed;
- signed release artifact confirmed;
- final Owner approval.

After launch:

- monitor crashes;
- monitor auth/backend failures;
- collect feedback;
- triage regressions.

Only after stable V1 launch should normal V1.1 feature development begin.

---

# POST-V1 BY DEFAULT

The following are NOT blockers for V1 unless the Owner explicitly promotes them:

- Marketplace;
- RFQ;
- bids/offers;
- orders;
- payments;
- commissions;
- paid subscriptions;
- full monetization;
- sponsored listing business model;
- advanced advertising;
- advanced push notifications;
- CRM;
- collaboration;
- advanced analytics.

Existing dormant/contract groundwork may remain if safe and honest.

Do not expose half-built monetization functionality to users.

---

# HISTORICAL WORK VS FINAL PRODUCTION STATUS

Important distinction:

A component previously marked complete remains a valid implementation baseline.

But:

"previously implemented"

does NOT automatically mean:

"entire final V1 product is release-approved."

Production passes later in this roadmap exist to verify cross-feature integration, release configuration, real devices, cloud authority, security, and final quality.

Do not unnecessarily redo old implementation.

Use existing evidence unless later changes invalidate it.

---

# ROADMAP TRANSITION PROTOCOL

This section is mandatory.

Before starting ANY task:

1. Open this file.
2. Read `CURRENT_PHASE_ID`.
3. Read the full CURRENT phase.
4. Confirm the immediately previous phase is CLOSED.
5. Check Git status.
6. Check HEAD against the expected project state.
7. Do NOT implement another phase.
8. Wait for the Architect's phase-specific prompt.

When the CURRENT phase passes:

- implementation;
- proportional tests;
- independent review;
- Architect Final Review;

then, BEFORE the Owner's atomic commit, the Architect may authorize the original implementer to update this roadmap in the same intended commit:

CURRENT phase:

CURRENT → CLOSED

Next queued phase:

QUEUED → CURRENT

Header:

CURRENT_PHASE_ID → next phase
CURRENT_PHASE_TITLE → next phase title
LAST_CLOSED_PHASE_ID → phase being closed

Do not invent new phases.

If a phase must be split:

ONLY the Architect may define subphase IDs.

Record them in this file before implementation.

---

# CURRENT POINTER

CURRENT:

V1-R09 — Offline / Connectivity / Error Hardening

NEXT AFTER SUCCESSFUL CLOSE:

V1-R10 — Core App UX Production Completion

No other phase may be selected by inference.

---

# PHASE TRANSITION RECORD

Reusable template. Only the Architect/Owner-authorized closing entry fills this in; future phases must not pre-create records.

### Phase Transition Record

Phase: V1-R04 — Business Application User Experience
Previous status: CURRENT
New status: CLOSED
Implementation agent: Big Pickle
Independent reviewer: Codex
Architect Final Review: PASS
Evidence summary:
- 205/205 relevant regressions PASS
- 1752/1752 full Flutter PASS
- analyzer zero new diagnostics
- V1-R04 correction suite 52/52 PASS
- User Area route tests 29/29 PASS
- combined focused correction verification 81/81 PASS
- final canonical CLAIM forwarding behavioral test 1/1 PASS
- Codex focused recheck completed
- Codex micro recheck PASS
- Architect Final Review PASS
Commit: 55a624a
Push verified: YES
Next CURRENT phase: V1-R05 — Directory Cloud Integration
Next contract: NOT_FROZEN
Implementation authorized: NO
Owner approval: APPROVED / COMMITTED

### Phase Transition Record

Phase: V1-R05 — Directory Cloud Integration
Previous status: CURRENT
New status: CLOSED
Implementation agent: Big Pickle
Independent reviewer: Codex
Architect Final Review: PASS
Independent Codex final decision: PASS — READY FOR ARCHITECT FINAL REVIEW
Evidence summary:
- V1-R05 focused suite 83/83 PASS
- previous full Flutter suite 1800+ PASS
- relevant regression evidence 266 PASS
- git diff --check PASS
- analyzer crash confirmed environment/SDK — V1-R05 NOT CAUSAL
- production SupabaseCloudDirectoryRepository behavioral tests PASS
- production SupabaseDirectoryReadGateway behavioral tests PASS
- sb_profiles behavioral isolation test PASS
- historical contract-restore blocker marked SUPERSEDED
- contract restored verbatim (V1-R05-CONTRACT-v1)
- Codex final micro recheck PASS
- Architect Final Review PASS
Commit: PENDING OWNER COMMIT
Push verified: NO (owner stages explicit files)
Next CURRENT phase: V1-R06 — Business / Provider Profile Management
Next contract: NOT_FROZEN
Implementation authorized: NO
Owner approval: PENDING OWNER STAGING

### Phase Transition Record

Phase: V1-R07 — Staff / Admin Operations Foundation
Previous status: CURRENT
New status: CLOSED
Implementation agent: Big Pickle
Independent reviewer: Codex
Architect Final Review: PASS
Independent Codex final decision: PASS — READY FOR ARCHITECT FINAL REVIEW
Evidence summary:
- Part 1 server/security focused 28/28 PASS
- Part 1 A6 server regression 37/37 PASS
- Part 2 R07 Flutter focused 75/75 PASS
- production gateway behavioral 17/17 PASS
- User Area routing 29/29 PASS
- A6.3 shared interface 38/38 PASS
- final focused Codex recheck PASS
- independent review PASS
- integrated phase gate final 2058/2058 PASS
- focused confirmations: Steel calculator 25/25 PASS; V1-R06 profile management 81/81 PASS
- phase-gate root causes resolved: 2 transient environment failures; 1 obsolete V1-R06 roadmap assertion (test-only); 1 W6.3 harness missing StaffAccessProvider (test-only)
- git diff --check PASS
- DEV server QA DEFERRED — CREDENTIALS UNAVAILABLE (mandatory in V1-R14)
- frozen V1-R07 contract preserved unchanged
Commit: PENDING OWNER COMMIT
Push verified: NO (owner stages explicit files)
Next CURRENT phase: V1-R08 — Auth + Profile Production Completion
Next contract: NOT_FROZEN
Implementation authorized: NO
Owner approval: PENDING OWNER STAGING

### Phase Transition Record

Phase: V1-R08 — Auth + Profile Production Completion
Previous status: CURRENT
New status: CLOSED
Implementation agent: Big Pickle
Independent reviewer: Codex
Architect Final Review: PASS
Independent Codex final decision: PASS — READY FOR ARCHITECT FINAL REVIEW
Evidence summary:
- Part 1 accepted: PASS — V1-R08 PART 1 ACCEPTED (auth/session lifecycle, auth event stream, epoch/session-generation protection, authoritative remote sign-out, reactive session loss, account-bound invalidation, second-account fail-closed, cloud profile SSOT, strict cloud parsing, typed profile provisioning, role_code + canonical region preference, protected routes/secure return destinations)
- Part 2 accepted: PASS — V1-R08 PART 2 ACCEPTED (auth/profile production UX, ownership-conflict recovery, authenticated vs guest profile-editor dispatch, Arabic/English R08 localization)
- final Part 2 correction evidence: 111/111 PASS
- phase gate: PHASE GATE PASS — READY FOR ARCHITECT FINAL REVIEW
- initial integrated gate run: 2147 PASS / 2 FAIL (both root causes resolved test-only)
- phase-gate root causes resolved: 1 obsolete V1-R06 roadmap live-marker assertion advanced to V1-R08 (test-only); 1 R07 Flutter test harness compatibility with accepted R08 interfaces/providers (test-only)
- final integrated Flutter suite: 2223/2223 PASS (0 FAIL, 0 SKIPPED)
- git diff --check PASS
- migration 00022 absent; OPTION A — NO MIGRATION REQUIRED; no schema/RLS/service_role change
- DEV server QA DEFERRED — CREDENTIALS UNAVAILABLE (mandatory in V1-R14)
- frozen V1-R08 contract preserved unchanged
Commit: PENDING OWNER COMMIT
Push verified: NO (owner stages explicit files)
Next CURRENT phase: V1-R09 — Offline / Connectivity / Error Hardening
Next contract: NOT_FROZEN
Implementation authorized: NO
Owner approval: PENDING OWNER STAGING

### Phase Contract Freeze Record

Phase: V1-R09 — Offline / Connectivity / Error Hardening
Status: CURRENT
Contract: V1-R09-CONTRACT-v1
Contract status: FROZEN
Architect decision: APPROVED FOR IMPLEMENTATION
Implementation authorized: YES
Baseline: e80fab8883a3631e58d1cc9bb83846c7f981d0fa
Evidence summary:
- pre-contract architecture audit: READY FOR ARCHITECT V1-R09 CONTRACT FREEZE
- one canonical injectable transport authority using existing connectivity_plus
- local-first startup and finite application-owned timeout policy frozen
- common infrastructure failure classification and no-raw-error policy frozen
- conservative read reconnect policy; blind automatic mutation retry forbidden
- Directory immediate-cache, bounded-refresh, and stale-empty behavior frozen
- V1-R08 auth/session/ownership protections explicitly preserved
- OPTION A — NO DATABASE MIGRATION REQUIRED; migration 00022 prohibited
- production Supabase readiness and DEV server QA remain deferred to V1-R14
- implementation split into independently reviewed Part 1 then Part 2
V1-R09 status: CURRENT (not closed)
Next queued phase: V1-R10 — Core App UX Production Completion
Owner approval: PENDING OWNER STAGING

### V1-R09 Part 2 P2-A Closure Record

Slice: P2-A — Shared Transport and Remote-State UX
Status: ACCEPTED / CLOSED
Final micro-review: PASS — P2-A ACCEPTED — P2-B MAY BEGIN
Final focused evidence: 57 PASS / 0 FAIL / 0 SKIPPED
Findings: HIGH NONE / MEDIUM NONE / LOW NONE
P2-A report: Civilpedia_V1-R09_P2-A_Report.txt (with append-only Appendix A)
P2-B: CURRENT — CONTRACT V1-R09-P2-B-CONTRACT-v1 FROZEN (P2-B1 authorized; P2-B2 locked pending P2-B1 acceptance)
V1-R10: QUEUED (not started)

### V1-R09 Part 2 P2-B Contract Freeze Record

Phase: V1-R09 Part 2
Slice: P2-B — Directory Cache-First + Reconnect
Status: CURRENT
Contract: V1-R09-P2-B-CONTRACT-v1
Contract status: FROZEN
Architect decision: FROZEN
P2-B1: IMPLEMENTATION_AUTHORIZED: YES (effective after contract persistence)
P2-B2: LOCKED pending P2-B1 independent acceptance
P2-C through P2-G: LOCKED
V1-R10: QUEUED (not started)
Backend decision: no migration / RLS / schema / Edge / Realtime / service_role change
V1-R09 status: CURRENT (not closed)
Owner approval: PENDING OWNER STAGING

### V1-R09 Part 2 P2-B1 Closure Record

Slice: P2-B1 — Directory Cache-First + Reconnect (correction pass)
Status: ACCEPTED / CLOSED
Final micro-review: PASS — P2-B1 ACCEPTED — P2-B2 MAY BE UNLOCKED
Final focused evidence: 183 PASS / 0 FAIL / 0 SKIPPED
  - test/v1_r09_p2_b_directory_data_test.dart: 100 PASS
  - test/v1_r05_directory_cloud_integration_test.dart: 83 PASS
Findings: HIGH NONE / MEDIUM NONE / LOW NONE
Corrected defects:
  - required relationship structure validation (remote + cache)
  - parser type safety (remote + cache)
  - PostgREST temporary-service classification by Postgres/PostgREST code family
  - http.ClientException mapped to network
  - invalid canonical UUID validated before availability/network logic
  - loadByCanonicalId cache-first compatibility preserved
  - location `is_primary` strict bool validation (remote + cache)
P2-B2: CURRENT — IMPLEMENTATION_AUTHORIZED: YES (NEXT)
P2-C through P2-G: LOCKED
V1-R10: QUEUED (not started)

### V1-R09 Part 2 P2-B Addendum-A Closure Record

Slice: P2-B — Directory Cache-First + Reconnect (Addendum-A: Shared Network Cause)
Status: ACCEPTED / CLOSED
Final micro-review: PASS — ADDENDUM-A ACCEPTED — P2-B2 MAY RESUME
Final focused evidence: 48 PASS / 0 FAIL / 0 SKIPPED
  - test/v1_r09_p2_shared_ux_test.dart: 48 PASS
Final regression evidence: 202 PASS / 0 FAIL / 0 SKIPPED
  - test/v1_r09_p2_b_directory_data_test.dart: 100 PASS
  - test/v1_r05_directory_cloud_integration_test.dart: 83 PASS
  - test/remote_operation_policy_test.dart: 9 PASS
  - test/app_shell_test.dart: 10 PASS
Findings: HIGH NONE / MEDIUM NONE / LOW NONE
Additive change:
  - RemoteDataCause.network added to lib/core/widgets/remote_data_notice.dart
  - Neutral Arabic/English localization added to lib/localization/ar.dart and lib/localization/en.dart
  - Frozen contract amended via append-only APPENDIX-A
P2-B2: CURRENT — IMPLEMENTATION_AUTHORIZED: YES (NEXT)
P2-C through P2-G: LOCKED
V1-R10: QUEUED (not started)

### V1-R09 Part 2 P2-B2 Closure Record

Slice: P2-B2 — Directory Search / Detail / Saved / Reconnect UX (correction pass)
Status: ACCEPTED / CLOSED
Final micro-review: PASS — P2-B2 ACCEPTED — P2-B MAY CLOSE
Final focused correction evidence: 205 PASS / 0 FAIL / 0 SKIPPED
  - test/v1_r09_p2_b_directory_ux_test.dart: 40 PASS
  - test/w5_3_directory_search_screen_test.dart: 24 PASS
  - test/w5_4_directory_search_integration_test.dart: 11 PASS
  - test/w5_4_directory_provider_detail_screen_test.dart: 31 PASS
  - test/w5_6_directory_provider_detail_save_test.dart: 13 PASS
  - test/w5_6_saved_screen_directory_test.dart: 12 PASS
  - test/saved_reference_resolver_test.dart: 16 PASS
  - test/w6_2_directory_route_test.dart: 10 PASS
  - test/v1_r09_p2_shared_ux_test.dart: 48 PASS
Findings: HIGH NONE / MEDIUM NONE / LOW NONE
Corrected defects:
  - post-dispose async publication in DirectoryRefreshController
    (disposed flag + operation epoch guards)
  - post-dispose async publication in DirectoryDetailController
    (disposed flag + request epoch invalidation on dispose)
  - valid cached-empty snapshot drowned by loading gate in
    DirectorySearchScreen (explicit hasSnapshot flag)
  - 18 deterministic tests added (T1-T18)
P2-B: ACCEPTED / CLOSED
P2-C: NEXT — AUTHORIZED FOR CONTRACT FREEZE ONLY (implementation NOT authorized)
V1-R10: QUEUED (not started)

### V1-R09 Part 2 P2-B Closure Record

Slice: P2-B — Directory Cache-First + Reconnect
Status: ACCEPTED / CLOSED
P2-B1: ACCEPTED / CLOSED
P2-B2: ACCEPTED / CLOSED
Addendum-A: ACCEPTED / CLOSED
Final micro-review: PASS — P2-B2 ACCEPTED — P2-B MAY CLOSE
Final focused correction evidence: 205 PASS / 0 FAIL / 0 SKIPPED
Findings: HIGH NONE / MEDIUM NONE / LOW NONE
Contract: V1-R09-P2-B-CONTRACT-v1 (+ ADDENDUM-A) preserved unchanged
P2-C: NEXT — AUTHORIZED FOR CONTRACT FREEZE ONLY
P2-D through P2-G: LOCKED
V1-R09 Part 2: CURRENT (V1-R09 overall not closed)
V1-R10: QUEUED (not started)

### V1-R09 Part 2 P2-C Contract Freeze Record

Phase: V1-R09 Part 2
Slice: P2-C — Authenticated Profile Read UX
Status: CURRENT
Contract: V1-R09-P2-C-CONTRACT-v1
Contract status: FROZEN
Architect decision: FROZEN
P2-C1: ACCEPTED / CLOSED
P2-C1 implementer: Codex
P2-C1 reviewer: GPT-5.6 Sol High
P2-C2: NEXT — IMPLEMENTATION AUTHORIZED
P2-C2 implementer: Big Pickle
P2-C2 reviewer: GitHub Copilot Civilpedia Reviewer
P2-D through P2-G: LOCKED
V1-R10: QUEUED (not started)
Backend decision: no migration / RLS / schema / Edge / Realtime / service_role change
V1-R09 status: CURRENT (not closed)
Owner approval: PENDING OWNER STAGING

### V1-R09 Part 2 P2-C1 Closure Record

Slice: P2-C1 — Typed Read & Lifecycle Foundation
Status: ACCEPTED / CLOSED
Independent review: PASS
Test evidence: 205 PASS / 0 FAIL / 0 SKIPPED
Findings: HIGH NONE / MEDIUM NONE / LOW NONE
P2-C: CURRENT (not closed)
P2-C2: may now be unlocked
Implementation boundary:
  lib/features/profile/data/personal_profile_remote_gateway.dart
  lib/features/profile/data/supabase_personal_profile_remote_gateway.dart
  lib/features/profile/presentation/providers/user_profile_provider.dart
  test/v1_r09_p2_c_authenticated_profile_read_foundation_test.dart
