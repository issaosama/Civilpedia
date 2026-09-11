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
CURRENT_PHASE_ID: V1-R04
CURRENT_PHASE_TITLE: Business Application User Experience
LAST_CLOSED_PHASE_ID: V1-R03
LAST_CLOSED_COMMIT: PENDING OWNER COMMIT
ROADMAP_STATUS: ACTIVE

---

# PHASE CONTROL TABLE

| ID | Phase | Status | Main | Reviewer | Risk | Closure Commit |
| --- | --- | --- | --- | --- | --- | --- |
| A6.3.1 | Creation Authorization Hardening | CLOSED | Codex | Big Pickle | HIGH | 12b1918 |
| A6.4 | Business Activation & Ownership Provisioning | CLOSED | Codex | Big Pickle | HIGH | 7aafc9f |
| V1-R03 | Business Ownership & Management | CLOSED | Codex | Big Pickle | HIGH | PENDING OWNER COMMIT |
| V1-R04 | Business Application User Experience | CURRENT | Big Pickle | Codex (backend/security) | MEDIUM | — |
| V1-R05 | Directory Cloud Integration | QUEUED | Codex (persistence/cloud) | TBD BY ARCHITECT | HIGH | — |
| V1-R06 | Business / Provider Profile Management | QUEUED | Codex (backend) / Big Pickle (UI) | TBD BY ARCHITECT | HIGH | — |
| V1-R07 | Staff / Admin Operations Foundation | QUEUED | TBD BY ARCHITECT | TBD BY ARCHITECT | HIGH | — |
| V1-R08 | Auth + Profile Production Completion | QUEUED | Codex | TBD BY ARCHITECT | HIGH | — |
| V1-R09 | Offline / Connectivity / Error-State Hardening | QUEUED | Big Pickle | TBD BY ARCHITECT | MEDIUM | — |
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

CURRENT_PHASE_ID: V1-R04
CURRENT_PHASE_TITLE: Business Application User Experience
CURRENT_PHASE_STATUS: CURRENT
CURRENT_PHASE_CONTRACT: NOT_FROZEN
IMPLEMENTATION_AUTHORIZED: NO

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

STATUS: CURRENT

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

STATUS: QUEUED

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

STATUS: QUEUED

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

STATUS: QUEUED

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

STATUS: QUEUED

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

## V1-R09 — Offline / Connectivity / Error-State Hardening

STATUS: QUEUED

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

V1-R04 — Business Application User Experience

NEXT AFTER SUCCESSFUL CLOSE:

V1-R05 — Directory Cloud Integration

No other phase may be selected by inference.

---

# PHASE TRANSITION RECORD

Reusable template. Only the Architect/Owner-authorized closing entry fills this in; future phases must not pre-create records.

### Phase Transition Record

Phase: V1-R03 — Business Ownership & Management
Previous status: CURRENT
New status: CLOSED
Implementation agent: Codex
Reviewer: Big Pickle — PASS
Architect review: PASS
Tests/evidence: V1-R03 21/21; relevant regressions 143/143; full Flutter 1712/1712; analyzer zero new; DEV QA A–O PASS; migration parity 00019; DB lint clean
Commit: PENDING OWNER COMMIT
Push verified: NO — pending Owner commit/push
Next CURRENT phase: V1-R04 — Business Application User Experience
Contract status: NOT_FROZEN
Owner approval: PENDING COMMIT
