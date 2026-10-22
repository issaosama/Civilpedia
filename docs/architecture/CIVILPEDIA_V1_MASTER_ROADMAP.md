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
CURRENT_PHASE_ID: V1-R10
CURRENT_PHASE_TITLE: UI/UX & Core App Experience
LAST_CLOSED_PHASE_ID: V1-R09Q
LAST_CLOSED_COMMIT: 6b4bf99
ROADMAP_STATUS: ACTIVE
R09Q-A_STATUS: CLOSED / ACCEPTED
R09Q-B_STATUS: CLOSED / ACCEPTED
R09Q-C_STATUS: CLOSED / ACCEPTED

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
| V1-R09 | Offline / Connectivity / Error Hardening | CLOSED | Big Pickle | TBD BY ARCHITECT | MEDIUM | c7702a6 |
| V1-R09Q | Post-R09 Cross-Cutting Quality Gate | CLOSED / ACCEPTED | Big Pickle (A) / Codex + Sol High (B) | GitHub Copilot Reviewer (A) / Copilot or independent strong reviewer (B) | MEDIUM | 6b4bf99 |
| V1-R10 | UI/UX & Core App Experience | CURRENT / AUTHORIZED | Big Pickle | TBD BY ARCHITECT | MEDIUM | — |
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

CURRENT_PHASE_ID: V1-R10
CURRENT_PHASE_TITLE: UI/UX & Core App Experience
CURRENT_PHASE_STATUS: CURRENT / AUTHORIZED — R10.5-B CLOSED / ACCEPTED — R10.5-C CLOSED / ACCEPTED — R10.5-D CURRENT / AUTHORIZED — PRE-IMPLEMENTATION AUDIT ONLY — IMPLEMENTATION NOT STARTED
CURRENT_PHASE_CONTRACT: docs/architecture/contracts/V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md
CURRENT_PHASE_CONTRACT_FREEZE: NOT FROZEN FOR V1-R10.5-D — FOCUSED AUDIT ONLY (R10.5-C IS CLOSED UNDER APPENDIX G WITH THE APPENDIX H CLOSURE RECORD)
IMPLEMENTATION_AUTHORIZED: NO — V1-R10.5-D PROFILE + USER AREA PRESENTATION PASS IS AUTHORIZED FOR ITS FOCUSED PRE-IMPLEMENTATION AUDIT ONLY; IMPLEMENTATION REQUIRES THE AUDIT AND A SUBSEQUENT ARCHITECT PRODUCTION-BOUNDARY FREEZE

A roadmap CURRENT status identifies execution order.
It does NOT by itself authorize implementation.

V1-R10.5-A (Article Production Visual Pass), V1-R10.5-B (Tools + Calculators
Presentation Pass), and V1-R10.5-C (Projects Presentation Pass) are CLOSED /
ACCEPTED (see their Formal Closure Records below). The current R10.5-D
(Profile + User Area Presentation Pass) slice is CURRENT / AUTHORIZED for its
focused pre-implementation audit only. R10.5-D implementation is NOT started,
IMPLEMENTATION_AUTHORIZED is NO, and no R10.5-D production boundary, file
list, or implementation detail is frozen yet. Do NOT invent the R10.5-D
production boundary; the next authorized task is the focused audit only.
R10.5-E, R10.5-F, R10.6, and R10.7 remain LOCKED. V1 user-facing language scope
= ARABIC-ONLY (see the V1 Owner Language-Scope Decision Record below).

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

STATUS: CLOSED / ACCEPTED — V1-R09 FORMALLY CLOSED (see V1-R09 Final Closure Record below)

Part 1: CLOSED / ACCEPTED — PASS - V1-R09 PART 1 ACCEPTED - PART 2 MAY BEGIN
Part 2: CLOSED — current within V1-R09 (V1-R09 is now formally closed)
Part 2 P2-A: ACCEPTED / CLOSED — PASS - P2-A ACCEPTED - P2-B MAY BEGIN
Part 2 P2-B: ACCEPTED / CLOSED
Part 2 P2-B1: ACCEPTED / CLOSED
Part 2 P2-B2: ACCEPTED / CLOSED
Part 2 P2-C: ACCEPTED / CLOSED
Part 2 P2-C1: ACCEPTED / CLOSED
Part 2 P2-C2: ACCEPTED / CLOSED
Part 2 P2-D: ACCEPTED / CLOSED — P2-D FORMALLY CLOSED
Part 2 P2-D1: ACCEPTED / CLOSED
Part 2 P2-D2: ACCEPTED / CLOSED
Part 2 P2-E: ACCEPTED / CLOSED — P2-E FORMALLY CLOSED
Part 2 P2-E1: ACCEPTED / CLOSED
Part 2 P2-E2: ACCEPTED / CLOSED
Part 2 P2-F: ACCEPTED / CLOSED — P2-F FORMALLY CLOSED — PASS — P2-F ACCEPTED — P2-G MAY BE UNLOCKED
Part 2 P2-G: ACCEPTED / CLOSED — P2-G FORMALLY CLOSED (see P2-G Formal Closure Record below)
Post-R09 Quality Gate (V1-R09Q): NEXT / AUTHORIZABLE (not started)
V1-R10 (UI/UX & Core App Experience): QUEUED after the Post-R09 Quality Gate
  (not started)

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

## V1-R09Q — Post-R09 Cross-Cutting Quality Gate

STATUS: CLOSED / ACCEPTED (see V1-R09Q Final Closure Record, V1-R09Q Contract
Freeze Record, R09Q-A Formal Closure Record, and R09Q-B Formal Closure Record
below)

Contract:

V1-R09Q_CROSS_CUTTING_QUALITY_GATE_CONTRACT.md (V1-R09Q-CONTRACT-v1)

Primary:

Big Pickle (R09Q-A — CI + Cross-Feature Smoke)

Codex / GPT-5.6 Sol High (R09Q-B — Supabase Reproducibility + Security Evidence)

R09Q-C — FORMAL CLOSURE ONLY (documentation; not a third implementation slice).

IMPLEMENTATION_AUTHORIZED: NO — implementation begins only after the Architect
checkpoint approves this frozen contract.

This is NOT a feature phase.

Purpose:

- establish/verify the CI baseline;
- run critical integration smoke tests;
- verify key auth/session/offline recovery paths together;
- verify current Supabase/RLS negative + positive security coverage where
  relevant;
- verify migration/reproducibility baseline;
- verify no known cross-feature trust-breaking regression before the V1 UI/UX
  redesign.

The gate must remain SMALLER than V1-R17 (Final End-to-End QA).

Do NOT turn this gate into a second full End-to-End phase.

V1-R10 does not begin until the Post-R09 Quality Gate completes.

---

## V1-R10 — UI/UX & Core App Experience

STATUS: QUEUED (after the Post-R09 Quality Gate)

Primary:

Big Pickle

Role:

V1-R10 is the PRIMARY V1 UI/UX / design-system phase. It defines the final V1
visual direction and core app experience BEFORE later major features
(V1-R11/V1-R12/V1-R13) are built.

Architect-defined sub-phases:

R10.1 — Visual Direction Freeze

Define Civilpedia's final V1 visual direction before later major features are
built. Include:

- visual identity;
- primary/supporting colors;
- typography hierarchy;
- spacing system;
- radii;
- shadows/elevation;
- iconography;
- motion principles;
- information density;
- engineering/professional visual tone.

Visual direction target:

- professional engineering product;
- + premium modern feel;
- + practical usability for engineers/site users.

Do NOT prescribe a copied third-party visual design.

R10.2 — Design System

Define/reconcile reusable primitives such as:

- buttons;
- cards;
- inputs;
- search;
- chips;
- list items;
- section headers;
- dialogs;
- bottom sheets;
- app bars;
- navigation primitives;
- loading states;
- skeletons where appropriate;
- empty states;
- error/remote-data states;
- status badges;
- common spacing/layout primitives.

Goal:

later V1-R11/V1-R12/V1-R13 features must consume the design system rather than
invent their own visual patterns.

R10.3 — Core Screen Redesign / Harmonization

Review and polish the major existing core application surfaces using the actual
repository architecture (no imaginary screens):

- Home;
- navigation/shell;
- profile/user area;
- saved;
- search;
- authentication entry screens;
- common/shared screens.

R10.4 — Responsive / Locale / Theme Hardening

Include:

- Arabic RTL;
- English LTR;
- dark mode;
- supported phone sizes;
- tablet/large-layout behavior where V1 supports it;
- text scaling / overflow resilience where relevant.

R10.5 — Visual QA / UX Regression

Before R10 closes verify:

- visual consistency;
- spacing consistency;
- no legacy component duplication where a design-system primitive exists;
- AR/EN;
- RTL/LTR;
- dark;
- responsive behavior;
- loading/error/empty states;
- navigation continuity;
- accessibility basics where applicable.

UI FREEZE PRINCIPLE (post-R10):

R10 is the main V1 visual redesign window.

After R10:

Allowed:
- polish;
- spacing refinements;
- icon improvements;
- micro-interactions;
- animation refinement;
- small visual consistency fixes;
- feature-specific extensions of frozen design primitives.

Not preferred without Architect decision:
- wholesale navigation redesign;
- global typography redesign;
- global card/layout philosophy replacement;
- major design-language reset.

Reason:

V1-R11/V1-R12/V1-R13 must be built on the final V1 design system rather than
requiring large UI rework near release.

This is NOT an absolute prohibition on later UX correction. Trust-breaking or
usability defects may always be corrected.

Language note (preserved):

Arabic-only may remain the intentional V1 product language unless the Owner
explicitly promotes English into V1.

If Arabic-only remains the decision, it is a production scope decision, not a
beta limitation.

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

# CROSS-CUTTING QUALITY, SECURITY & PLATFORM GOVERNANCE (V1-R09Q AND EVERY LATER PHASE)

These rules apply to the Post-R09 Quality Gate and every later phase. They do
not change current V1-R09 execution or any frozen contract.

## Continuous Security Rule

V1-R15 remains Security & Abuse FINAL AUDIT. Security must NOT begin only in
V1-R15.

Any phase that changes:

- authentication;
- authorization;
- Supabase;
- RLS;
- grants;
- RPC authority;
- ownership;
- role/staff access;
- sensitive mutation guards;

must include relevant positive AND negative security/authority tests inside
that same phase.

V1-R15 is the comprehensive final security gate, not the first security pass.

## Continuous E2E / Integration Rule

V1-R17 remains the FINAL comprehensive End-to-End phase. V1-R17 must NOT be the
first meaningful integration/E2E execution.

Require targeted critical-journey integration/smoke verification at least:

A. Post-R09 Quality Gate (V1-R09Q);

B. after a major backend-heavy milestone such as V1-R11 closure;

C. after V1-R14 Supabase Production Readiness;

D. comprehensive final E2E in V1-R17.

Intermediate gates remain targeted. Do NOT run huge full-system suites after
every tiny slice.

## CI Rule

Goal: CI becomes the stable automated evidence source.

The workflow should progressively support:

- focused unit/widget tests;
- critical integration tests;
- database/RLS tests where applicable;
- reproducibility/migration checks where applicable.

Agent-reported test counts remain useful evidence, but automated CI should
become the long-term deterministic baseline where practical.

CI implementation is not performed in any docs-only task; it is scheduled only
when authorized.

## Supabase Shift-Left Rule

V1-R14 remains Supabase Production Readiness FINALIZATION / GATE.
Production-readiness groundwork must begin earlier where relevant.

Any earlier phase introducing Supabase backend behavior must preserve:

- migration version control;
- deterministic/reproducible environment assumptions;
- RLS/security tests;
- no `service_role` client exposure;
- source-controlled backend contracts.

V1-R14 then performs the final production verification including applicable:

- RLS review;
- grants review;
- indexes/performance;
- environment separation/readiness;
- database tests;
- production configuration;
- security/performance advisor review where used;
- load/readiness checks where justified.

Backend changes are NOT implemented in this docs-only task.

## Observability Rule

Observability is a V1 production requirement.

Before release readiness / final E2E closes, Civilpedia must have an approved
strategy for applicable:

- crash reporting;
- production error visibility;
- analytics for critical product journeys;
- basic release diagnostics.

Existing planned technologies such as Crashlytics/Analytics may be used if
still architecturally appropriate at implementation time.

No telemetry implementation is introduced now.

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

# V1 NON-GOALS — NO OVERENGINEERING

Preserve these non-goals unless separately authorized:

- microservices for V1;
- generic offline mutation queue;
- conflict-resolution engine;
- background sync architecture for every feature;
- durable authoritative cache for every remote domain;
- oversized admin platform;
- AI features merely for novelty;
- excessive animation;
- speculative abstractions without current use.

The roadmap remains production-grade but intentionally scoped.

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

V1-R10 — UI/UX & Core App Experience (CURRENT / AUTHORIZED — IMPLEMENTATION
BEGINS ONLY AFTER ARCHITECT CONTRACT FREEZE)

NEXT AFTER V1-R10 CLOSES:

V1-R11 — Projects Production Pass (QUEUED after V1-R10)

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

### V1-R09 Part 2 P2-C2 / P2-C Closure Record

Slice: P2-C2 — Authenticated Profile Read Presentation (read facing)
Status: ACCEPTED / CLOSED
Final P2-C2 independent decision: PASS — P2-C2 ACCEPTED — P2-C MAY CLOSE
Final focused evidence: 172 PASS / 0 FAIL / 0 SKIPPED
  - test/v1_r09_p2_c_authenticated_profile_read_ux_test.dart: 23 PASS
  - test/v1_r08_profile_screen_widget_test.dart: 13 PASS
  - test/v1_r08_profile_edit_screen_widget_test.dart: 16 PASS
  - test/v1_r08_user_area_widget_test.dart: 14 PASS
  - test/v1_r09_p2_shared_ux_test.dart: 48 PASS
  - test/v1_r09_p2_c_authenticated_profile_read_foundation_test.dart: 21 PASS
  - test/user_area_route_test.dart: 37 PASS
Independent reviewer shell execution: UNAVAILABLE — no independent test
  execution claimed; the 172/0/0 evidence is implementer evidence only.
Findings: HIGH NONE / MEDIUM NONE / LOW NONE
P2-C: ACCEPTED / CLOSED
P2-D: NEXT — CONTRACT FREEZE ONLY (implementation NOT authorized)
P2-E through P2-G: LOCKED
Contract: V1-R09-P2-C-CONTRACT-v1 frozen semantics preserved unchanged; only
  the append-only final closure section added.
V1-R09 Part 2: CURRENT (V1-R09 overall not closed)
V1-R10: QUEUED (not started)

### V1-R09 Part 2 P2-D Contract Freeze Record

Phase: V1-R09 Part 2
Slice: P2-D — Business Remote Read UX
Status: CURRENT
Contract: V1-R09-P2-D-CONTRACT-v1
Contract status: FROZEN
Architect decision: FROZEN
P2-D1: IMPLEMENTATION_AUTHORIZED: YES (effective after contract persistence)
P2-D1 implementer: Codex / GPT-5.6 Sol High
P2-D1 reviewer: GPT-5.6 Sol High (separate read-only session)
P2-D2: LOCKED pending P2-D1 independent acceptance
P2-D2 implementer: Big Pickle
P2-D2 reviewer: GitHub Copilot Civilpedia Reviewer
P2-E through P2-G: LOCKED
V1-R10: QUEUED (not started)
Backend decision: no migration / RLS / schema / Edge / Realtime / service_role
  change; migration 00022 remains absent
V1-R09 status: CURRENT (not closed)
Owner approval: PENDING OWNER STAGING

### V1-R09 Part 2 P2-D1 Closure Record

Slice: P2-D1 — Typed Business Read / State / Lifecycle Foundation
Status: ACCEPTED / CLOSED
Independent review: PASS
Independent focused evidence: 359 PASS / 0 FAIL / 0 SKIPPED
Findings: HIGH NONE / MEDIUM NONE
LOW finding: implementer-reported total 364 overcounted five legacy-suite
  terminal counters by one each; independent actual total is 359.
  Reporting-only, non-blocking.
P2-D: CURRENT (not closed)
P2-D2: NEXT — IMPLEMENTATION AUTHORIZED (unlocked after this closure/checkpoint)
P2-E through P2-G: LOCKED
Contract: V1-R09-P2-D-CONTRACT-v1 frozen semantics preserved unchanged; only
  the append-only P2-D1 closure marker added.
V1-R09 Part 2: CURRENT (V1-R09 overall not closed)
V1-R10: QUEUED (not started)

### V1-R09 Part 2 P2-D2 / P2-D Closure Record

Slice: P2-D2 — Business Remote-Read Presentation UX
Status: ACCEPTED / CLOSED
Final independent decision: PASS — P2-D2 ACCEPTED — P2-D MAY CLOSE
Final focused evidence: 285 PASS / 0 FAIL / 0 SKIPPED
  - test/v1_r09_p2_d_business_remote_read_ux_test.dart: 62 PASS
  - test/v1_r04_business_application_ux_test.dart: 61 PASS
  - test/v1_r06_business_profile_management_test.dart: 85 PASS
  - test/user_area_route_test.dart: 37 PASS
  - test/v1_r09_p2_d_business_remote_read_foundation_test.dart: 40 PASS
Findings: HIGH NONE / MEDIUM NONE / LOW NONE
Accepted correction history:
  - first independent review found two active-locale defects
  - application-list empty-state localization corrected
  - claim verification labels corrected
  - first localization micro-review found deterministic assertion quality defect
  - J.58/J.59 hardened to exact full rendered-line cross-language assertions
  - final micro-review PASS
P2-D1: ACCEPTED / CLOSED
P2-D2: ACCEPTED / CLOSED
P2-D: ACCEPTED / CLOSED — P2-D FORMALLY CLOSED
P2-E: NEXT — CONTRACT FREEZE ONLY (implementation NOT authorized)
P2-E implementation: LOCKED pending frozen contract
P2-F through P2-G: LOCKED
Contract: V1-R09-P2-D-CONTRACT-v1 frozen semantics preserved unchanged; only
  the append-only P2-D2 / P2-D closure marker added.
V1-R09 Part 2: CURRENT (V1-R09 overall not closed)
V1-R10: QUEUED (not started)

### V1-R09 Part 2 P2-E Contract Freeze Record

Phase: V1-R09 Part 2
Slice: P2-E — Staff Remote Read UX
Status: CURRENT
Contract: V1-R09-P2-E-CONTRACT-v1
Contract status: FROZEN
Architect decision: FROZEN (ratified with amendments)
P2-E1: IMPLEMENTATION_AUTHORIZED: YES (effective after contract persistence)
P2-E1 implementer: Codex / GPT-5.6 Sol High
P2-E1 reviewer: GPT-5.6 Sol High (separate read-only session)
P2-E2: LOCKED pending P2-E1 independent acceptance
P2-E2 implementer: Big Pickle
P2-E2 reviewer: GitHub Copilot Civilpedia Reviewer
P2-F through P2-G: LOCKED
V1-R10: QUEUED (not started)
Backend decision: no migration / RLS / schema / Edge / Realtime / service_role
  change; migration 00022 remains absent
V1-R09 status: CURRENT (not closed)
Owner approval: PENDING OWNER STAGING

### Strategic Roadmap Amendment Record (Architect/Owner)

Date: 2026-09-17
Type: STRATEGIC ROADMAP PERSISTENCE (DOCS ONLY)

Decisions ratified:
- existing V1 roadmap direction and R11-R19 ordering RATIFIED (unchanged)
- Post-R09 quality gate inserted between V1-R09 and V1-R10: V1-R09Q
- V1-R10 redefined as the PRIMARY V1 UI/UX / design-system phase with
  Architect-defined sub-phases R10.1-R10.5 + post-R10 UI freeze principle
- continuous quality rules frozen: security shift-left; progressive
  E2E/integration smoke gates; CI as stable automated evidence source;
  Supabase shift-left; observability requirement; risk-based agent ceremony;
  V1 non-goals / no overengineering

Scope discipline:
- V1-R09 and frozen contract semantics NOT changed (including P2-E)
- V1-R09 NOT marked closed
- V1-R09Q NOT started; V1-R10 NOT started; V1-R11+ NOT authorized
- production code/tests/frozen contracts NOT modified

Status unchanged:
- V1-R09: CURRENT (not closed)
- Post-R09 Quality Gate (V1-R09Q): QUEUED after R09
- V1-R10 (UI/UX & Core App Experience): QUEUED after the Post-R09 Quality Gate
- V1-R11 through V1-R19: QUEUED (ordering unchanged)
- V1-R14 / V1-R15 / V1-R17 / V1-R19: final-gate roles unchanged

### V1-R09 Part 2 P2-E Closure Record

Slice: P2-E — Staff Remote Read UX
Contract: V1-R09-P2-E-CONTRACT-v1 frozen semantics preserved unchanged; only
  the append-only P2-E closure record added.
Status: CLOSED

P2-E1: CLOSED / ACCEPTED
  Implementation commit: cbc096b01e079a2627565c789d6a3bb9f5cfa537
  Acceptance: PASS after independent review + correction micro-review

P2-E2: CLOSED / ACCEPTED
  Implementation commit: b4c46a718a3919fb4953fc29dd460939a98f512a
  Acceptance: PASS — P2-E2 ACCEPTED — P2-E MAY CLOSE

Closure summary (accepted outcomes, without rewriting the contract):
  - typed Staff remote-read failure handling (StaffRemoteReadFailure +
    StaffRemoteReadFailureKind, seven kinds)
  - Staff domain outcome separation (P0AUT / P0PER / P0NOT / P0DAT remain
    StaffReadDenied domain causes; StaffReadUnavailable preserved distinct)
  - source-aware Staff RPC failure/domain classification
  - RemoteOperationPolicy.read 15-second deadline at the Staff data boundary
  - strict complete-response parsing (one malformed required row fails the
    read; canonical-ID mismatch → malformedResponse)
  - exact-key coalescing with request-epoch separation and stale-operation
    protection
  - session / auth-generation / resource-identity / disposal safety
  - exact-key known-good preservation (fail-soft queue/detail)
  - Staff mutation revision/read protection for queue and detail lanes
  - authoritative capability-loss cleanup
  - Staff queue/detail remote-read presentation (screen-scoped
    StaffRemoteReadNotice adapter over shared RemoteDataNotice)
  - manual retry only (no auto-refresh / polling / timers / reconnect reads)
  - offline derived only from network + canonical unavailable transport
  - shared RemoteDataNotice localization reuse; AR/EN and RTL/LTR presentation
  - post-mutation read-failure separation (refresh-after-mutation warning
    retained; committed outcome never cleared on read failure)
  - no backend change (migration 00022 remains absent)
  - no reconnect auto-refresh; no service_role

Accepted evidence:
  - P2-E1: implementation/correction evidence completed
  - P2-E1 final micro-review: PASS — P2-E1 ACCEPTED — P2-E2 MAY BE UNLOCKED
  - P2-E2 implementation focused evidence: 171 PASS / 0 FAIL / 0 SKIPPED
  - P2-E2 independent acceptance: PASS — P2-E2 ACCEPTED — P2-E MAY CLOSE
  - independent reviewer shell was unavailable; acceptance used static review
    plus implementer deterministic test evidence (no independent test
    execution is claimed)

Outcome:
  P2-E: CLOSED
  P2-F: NEXT — MAY BE AUTHORIZED AFTER THIS CLOSURE CHECKPOINT
    (implementation NOT authorized; NOT started)
  P2-G: LOCKED
  V1-R09: CURRENT (not closed)
  V1-R09Q: QUEUED after R09 (not started)
  V1-R10: QUEUED after V1-R09Q (not started)

### V1-R09 Part 2 P2-F Contract Freeze Record

Phase: V1-R09 Part 2
Slice: P2-F — Encyclopedia Local-Content Error Hardening
Status: CURRENT
Contract: V1-R09-P2-F-CONTRACT-v1
Contract status: FROZEN (docs only; no production code/test/content/generated
  output modified by this freeze)
Architect decision: FROZEN (per completed P2-F architecture inspection report)
Implementation: NOT STARTED — authorized only after Architect checkpoint
Implementation partition: ONE slice (no F1/F2)
Implementer: Big Pickle
Independent reviewer: GitHub Copilot Civilpedia Reviewer
Escalation: GPT-5.6 Sol High only for a genuine architecture/lifecycle conflict

P2-F decisions ratified:
- production runtime Encyclopedia authority = ONLY
  assets/encyclopedia/catalog.generated.json; no legacy catalog fallback; no
  mock fallback; no content substitution masquerading as success
- typed local-content taxonomy frozen:
  EncyclopediaContentFailureKind { assetUnavailable, malformedContent,
  unexpected }; no offline/network/timeout/serviceUnavailable variants
- meta gate: _meta.format == "civilpedia-catalog-generated",
  _meta.schemaVersion == 1, declared topicCount/sectionCount/blockCount must
  match; missing/wrong mandatory metadata => malformedContent
- any production CatalogParseSkip => malformedContent; zero partial
  authoritative publication; no silent block/section/topic drop
- known-good preservation full-catalog and same-topic; requested/current
  identity enforcement; Topic A -> Topic B failure NEVER renders A as B
- manual retry only, reattempting the authoritative generated lane; no
  legacy/mock/network/connectivity/timer/poll/auto-retry
- no raw e.toString()/parser/asset-loader/stack/filesystem text in normal UI;
  localized controlled AR/EN (RTL/LTR) copy; RemoteDataNotice and other
  remote/connectivity primitives NOT used for local-content failures
- search matcher keyTopics-vs-tags divergence OUT OF SCOPE (unchanged)
- no exporter/tooling overhaul (deferred to V1-R13 unless separately promoted);
  P2-F adds deterministic sync-gate + strict-load regression evidence only
- no section-granular retry; routing, image fallback, and image failure
  semantics preserved; backend unchanged (migration 00022 remains absent)

File boundary persisted (see contract §24 for exact paths):
- FOUNDATION MODIFY:
  lib/features/encyclopedia/data/datasources/encyclopedia_json_datasource.dart
  lib/features/encyclopedia/data/repositories/encyclopedia_repository_impl.dart
  lib/features/encyclopedia/presentation/providers/encyclopedia_provider.dart
- PRESENTATION MODIFY (only as needed): encyclopedia_screen.dart,
  categories_screen.dart, topic_list_screen.dart, topic_detail_screen.dart
  (home/saved surfaces conditional only where required)
- PRESENTATION ADD (at most one thin notice): under
  lib/features/encyclopedia/presentation/widgets/
- LOCALIZATION MODIFY: lib/localization/ar.dart, lib/localization/en.dart
- TEST MODIFY: test/encyclopedia_catalog_parser_test.dart (only for intended
  legacy/mock runtime fallback removal)
- TEST ADD: test/v1_r09_p2_f_encyclopedia_local_content_hardening_test.dart

Backend decision: no migration / RLS / schema / Edge / Realtime / service_role
  change; migration 00022 remains absent
V1-R09 status: CURRENT (not closed)
P2-F status: NOT marked implemented by this freeze
Owner approval: PENDING OWNER STAGING

Live state:
  P2-A: CLOSED
  P2-B: CLOSED
  P2-C: CLOSED
  P2-D: CLOSED
  P2-E: CLOSED
  P2-F: CLOSED — P2-F FORMALLY CLOSED (see P2-F Closure Record below)
  P2-G: CURRENT — VERIFICATION CONTRACT FROZEN (see P2-G Contract Freeze
    Record below)
  V1-R09Q: QUEUED after R09 (not started)
  V1-R10: QUEUED after V1-R09Q (not started)

### V1-R09 Part 2 P2-F Closure Record

Slice: P2-F — Encyclopedia Local-Content Error Hardening
Contract: V1-R09-P2-F-CONTRACT-v1 frozen semantics preserved unchanged; only
  the append-only P2-F closure record added.
Status: CLOSED / ACCEPTED

Implementation commit:
  8c7c780674152856f1d7dea8a935dc866a964291

Acceptance:
  PASS — P2-F ACCEPTED — P2-G MAY BE UNLOCKED

Closure summary (accepted outcomes, without rewriting the contract):
  - authoritative production Encyclopedia runtime source restricted to
    assets/encyclopedia/catalog.generated.json
  - production legacy/mock fallback removed
  - frozen local-content failure taxonomy:
    assetUnavailable / malformedContent / unexpected
  - authoritative empty / searchNoResults / topicNotFound kept separate from
    failures (never retryable content failures)
  - strict fail-closed catalog parsing; any CatalogParseSkip prevents
    authoritative success; zero partial authoritative publication
  - required generated-catalog _meta validation: format, schemaVersion,
    topicCount, sectionCount, blockCount
  - malformed topic/section/block or unsupported block payload fails
    authoritative content load
  - typed local-content failures propagated through repository/provider
  - raw exception/parser/internal diagnostic text suppressed from user UI
  - identity-safe known-good behavior: same-authority catalog reload failure
    preserves known-good; same-category reload failure preserves matching
    category topics; same-topic reload failure may preserve matching topic;
    cross-category/topic failure never masquerades old content as requested
    content
  - controlled local-content notice + manual retry for known-good reload
    failure; manual retry only, same local authoritative lane
  - no ConnectivityProvider / ReconnectGenerationGate / RemoteDataNotice /
    TransportStatusBanner / network-offline taxonomy / auto retry / polling /
    timers
  - existing ImageUnavailableFallback preserved for runtime image render
    failure
  - symmetric AR/EN P2-F local-content copy
  - deterministic app_ready/package catalog synchronization gate
  - generated production JSON remained unmodified
  - no backend change; no service_role; migration 00022 remains absent

Accepted evidence:
  - initial P2-F implementation: 132 PASS / 0 FAIL / 0 SKIPPED
    (focused sequential suites; no full repository suite; no analyzer)
  - correction on final corrected worktree: 115 PASS / 0 FAIL / 0 SKIPPED
    (focused sequential suites)
  - focused P2-F suite actual case count = 38
  - known-good catalog/category/list UX corrections included
  - independent review: initial static independent review found no foundation
    HIGH issues; final acceptance micro-review PASS across full-catalog
    known-good UX, categories known-good UX, topic-list identity,
    topicNotFound, notice priority, and regression check
  - reviewer limitation: independent reviewer shell was unavailable; final
    acceptance used static inspection plus implementer deterministic shell
    evidence (no independent test execution is claimed)

Outcome:
  P2-F: CLOSED / ACCEPTED — P2-F FORMALLY CLOSED
  P2-G: NEXT / AUTHORIZABLE AFTER THIS CLOSURE CHECKPOINT
    (implementation NOT authorized; NOT started)
  V1-R09: CURRENT (not closed)
  V1-R09Q: QUEUED after R09 (not started)
  V1-R10: QUEUED after V1-R09Q (not started)

### V1-R09 Part 2 P2-G Contract Freeze Record

Phase: V1-R09 Part 2
Slice: P2-G — Integrated UX Verification and Closure
Status: CURRENT
Contract: V1-R09-P2-G-CONTRACT-v1
Contract status: FROZEN (docs only; no production code / test / historical
  report artifact modified by this freeze)
Architect decision: FROZEN (per completed P2-G integrated verification
  inspection report)
Verification execution: NOT STARTED — authorized only after Architect
  checkpoint

P2-G decisions ratified:
- verification-first integrated closure gate for V1-R09 Part 2 (NOT a feature
  phase; NOT V1-R09Q; NOT R17 E2E; NOT full repository suite)
- ONE mandatory surgical production correction founded by inspection:
  lib/features/encyclopedia/presentation/widgets/encyclopedia_content_notice.dart
  must render Ar.retry / En.retry by active locale (currently hard-codes
  Ar.retry); reuse existing Ar.retry / En.retry keys; no new keys unless
  genuinely necessary; no broader Encyclopedia localization cleanup; no P2-F
  architecture redesign; may NOT be deferred to V1-R09Q
- ONE focused integrated suite authorized:
  test/v1_r09_p2_g_integrated_gate_test.dart
- transport policy split enforced under the SAME canonical connectivity
  authority where practical: Directory owns generation-gated reconnect (exactly
  once per recovery); Profile/Business/Staff manual retry only; Encyclopedia has
  no connectivity-driven behavior at all
- offline/network presentation mapping frozen: network + unavailable -> offline;
  network + available/unknown -> network; Encyclopedia local-content failure
  stays local regardless of connectivity state
- AppShell + Encyclopedia local-failure coexistence proven separately (no
  duplicate transport authority; no semantic merging)
- session/identity integration proven across the real coordinated reset seam
  (account-bound providers + StaffOperationsScope); Directory stays public;
  device-local Encyclopedia favorites are NOT cleared on auth change
- retry/mutation safety: no P2-G retry/reconnect path may invoke a mutation
- known-good priority preserved per frozen domain semantics
- mandatory EN-locale EncyclopediaNotice regression (En.retry rendered; Ar.retry
  MUST NOT render; Arabic behavior preserved)
- exact selected regression path list persisted in the frozen contract
  (verified to exist at freeze time)
- all selected regression suites run SEQUENTIALLY, ONE SUITE AT A TIME; no
  parallel execution; no flutter pub get / precache / pub cache repair /
  analyzer unless separately authorized
- production file boundary default: ONLY the one Encyclopedia notice widget for
  the mandatory correction; any further production edit requires ARCHITECT
  authorization with STOP-and-classify protocol
- closure-evidence authority: formal roadmap closure records + frozen contracts
  + accepted git commits + available acceptance evidence; no fabrication of
  missing report artifacts; historical P2-D2 report tail preserved, superseded
  by the formal P2-D closure record, with a reconciliation note at P2-G/V1-R09
  closure
- HIGH/MEDIUM blockers blocked; LOW recorded/deferred if no trust/behavior
  impact remains
- backend unchanged; migration 00022 remains absent

Live state:
  V1-R09:  CURRENT
  P2-A:    CLOSED
  P2-B:    CLOSED
  P2-C:    CLOSED
  P2-D:    CLOSED
  P2-E:    CLOSED
  P2-F:    CLOSED
  P2-G:    CURRENT — VERIFICATION CONTRACT FROZEN
  V1-R09Q: QUEUED after R09 (not started)
  V1-R10:  QUEUED after V1-R09Q (not started)

P2-G is NOT marked completed by this freeze.
V1-R09 is NOT marked closed by this freeze.
Owner approval: PENDING OWNER STAGING

---

### V1-R09 Part 2 P2-G Formal Closure Record

Slice: P2-G — Integrated Verification and Closure
Contract: V1-R09-P2-G-CONTRACT-v1 — frozen semantics preserved unchanged;
  only this append-only formal closure record is added.
Status: CLOSED / ACCEPTED

Implementation commit:
  c7702a6142a6c3f4dac22444b9b9a9544fa3dcff

Independent acceptance:
  PASS — P2-G ACCEPTED — V1-R09 MAY ENTER FORMAL CLOSURE

P2-G delivered:
  - one mandatory Encyclopedia AR/EN retry-label correction
    (lib/features/encyclopedia/presentation/widgets/encyclopedia_content_notice.dart:
    retry label now locale-aware — Arabic -> Ar.retry, English -> En.retry);
  - one focused integrated R09 verification suite
    (test/v1_r09_p2_g_integrated_gate_test.dart);
  - integrated transport-policy verification (Directory generation-gated
    auto-reconnect only; Profile/Business/Staff manual retry only; Encyclopedia
    has no connectivity-driven content reload);
  - offline/network presentation verification (network failure + confirmed
    unavailable transport -> offline; available/unknown transport -> network);
  - AppShell + local Encyclopedia-content-failure coexistence verification;
  - coordinated account-bound identity/session reset verification;
  - retry/mutation separation verification (read retries stay read-only);
  - known-good policy consistency verification;
  - EN/AR retry-label regression evidence;
  - selected R09 regression gate execution;
  - no backend change;
  - no broad production expansion.

Corrected execution evidence (verified arithmetic):
  - P2-G integrated gate:          23 PASS / 0 FAIL / 0 SKIPPED
  - selected frozen regression:    27 suites / 901 PASS / 0 FAIL / 0 SKIPPED
      P2-A..P2-F accepted suites:   431 PASS
      Shared / shell:                19 PASS
      Historical R05 Directory:     200 PASS
      R08 / auth / profile / user-area: 105 PASS
      R04 / R06 Business:           146 PASS
      431 + 19 + 200 + 105 + 146 = 901 PASS
  - grand total (regression + gate): 901 + 23 = 924 PASS / 0 FAIL / 0 SKIPPED

  Arithmetic correction note:
    earlier implementer report wording used 839 / 862 totals; those values were
    reporting arithmetic drift and are superseded. The verified persistent
    totals are the 901 selected-regression PASS and the 924 grand-total PASS.
    The regression total itself is 901 (not 924).

Architect-authorized test-only exception (narrow boundary):
  File: test/v1_r05_directory_cloud_integration_test.dart
  Reason: a stale historical literal assertion expected "Entity not found"
  while current accepted R09 behavior renders the localized Directory
  entity-not-found copy.
  Correction: a single assertion was updated to assert the accepted localized
  copy (Ar.directoryEntityNotFound rendered under the harness default Arabic
  LanguageProvider) while preserving the original behavioral intent:
    - message/error state remains asserted;
    - DirectoryProviderDetailScreen absence remains asserted;
    - no skip / delete / weaken; no production behavior changed.
  Classification: TEST/EVIDENCE RECONCILIATION ONLY — not a reopening of R05,
  not a change to Directory authority, not a broadening of P2-G production
  scope.
  Re-run after correction: 83/83 PASS.

Independent review:
  - independent reviewer performed static source/diff review;
  - independent shell execution was unavailable;
  - reviewer did NOT independently rerun the 27 suites;
  - implementer deterministic shell execution supplied the runtime evidence;
  - independent review found no HIGH, MEDIUM, or LOW findings;
  - file boundary, localization fix, integrated gate quality, identity reset,
    reconnect ownership, retry/mutation safety, R05 exception, backend
    protection, and direct regression were accepted.

P2-G closure invariants:
  - Directory remains the only R09 feature with generation-gated auto reconnect;
  - Profile / Business / Staff manual retry only;
  - Encyclopedia has no connectivity-driven content reload;
  - remote network failure may become offline only when canonical transport is
    confirmed unavailable; available/unknown never promotes network to offline;
  - Encyclopedia local-content failure remains local regardless of transport;
  - coordinated account-bound reset prevents stale User A authenticated state
    surfacing under User B / sign-out; Directory remains public; device-local
    Encyclopedia favorites are not cleared merely due to an auth change;
  - read retries remain read-only; no P2-G retry/reconnect path invokes
    mutation; accepted P2-A..P2-F authority boundaries unchanged;
  - EncyclopediaContentNotice retry label is now locale-aware: Arabic -> Ar.retry;
    English -> En.retry.

Live state:
  P2-G:    CLOSED / ACCEPTED
  V1-R09:  CLOSED / ACCEPTED (see V1-R09 Final Closure Record below)
  V1-R09Q: NEXT / AUTHORIZABLE (NOT started)
  V1-R10:  QUEUED after V1-R09Q (NOT started)

---

### V1-R09 Final Closure Record

Phase: V1-R09 — Offline / Connectivity / Error Hardening
Previous status: CURRENT
New status: CLOSED / ACCEPTED — V1-R09 FORMALLY CLOSED
Contracts: V1-R09-CONTRACT-v1 (+ part/slice contracts and appendices,
  incl. V1-R09-P2-G-CONTRACT-v1) — frozen semantics preserved unchanged; only
  this append-only final closure record is added.
Implementation commit: c7702a6142a6c3f4dac22444b9b9a9544fa3dcff
Independent acceptance: PASS — P2-G ACCEPTED — V1-R09 MAY ENTER FORMAL CLOSURE
Architect checkpoint: PENDING ARCHITECT CHECKPOINT
Owner staging/commit/push: PENDING OWNER (user is the sole Git owner)

V1-R09 delivered the full offline / connectivity / error-hardening program:
  - recovery/auth resilience foundation (Part 1);
  - shared transport UX (P2-A);
  - Directory cache-first + reconnect (P2-B, incl. P2-B1/P2-B2/Addendum-A);
  - authenticated Profile remote-read resilience (P2-C, incl. P2-C1/P2-C2);
  - Business remote-read resilience (P2-D, incl. P2-D1/P2-D2);
  - Staff remote-read resilience (P2-E, incl. P2-E1/P2-E2);
  - Encyclopedia local-content hardening (P2-F);
  - integrated P2-G verification and closure.

Slice closure state:
  P2-A: CLOSED / ACCEPTED
  P2-B: CLOSED / ACCEPTED (incl. P2-B1, P2-B2, Addendum-A)
  P2-C: CLOSED / ACCEPTED (incl. P2-C1, P2-C2)
  P2-D: CLOSED / ACCEPTED (incl. P2-D1, P2-D2)
  P2-E: CLOSED / ACCEPTED (incl. P2-E1, P2-E2)
  P2-F: CLOSED / ACCEPTED
  P2-G: CLOSED / ACCEPTED

Closure-evidence reconciliation (persisted rule):
  Formal roadmap closure records + frozen contracts + accepted git commits +
  available acceptance evidence are the authoritative closure trail.
  - historical P2-D2 artifact wording may show a transitional state; the later
    formal roadmap closure supersedes it;
  - missing standalone report artifacts for some accepted slices do NOT negate
    accepted contract/roadmap/git evidence;
  - no historical report artifact was edited; no missing report was fabricated;
  - old artifacts were not rewritten to appear current.

Backend / generated-protection (confirmed):
  - no Supabase / migrations / RLS / grants / RPC / Edge / Realtime /
    service_role change;
  - migration 00022 remains absent;
  - generated Encyclopedia JSON and Content Studio outputs unchanged;
  - no search-semantics change.

Live state (ONE authoritative live roadmap state):
  V1-R09:  CLOSED / ACCEPTED
  P2-A:    CLOSED
  P2-B:    CLOSED
  P2-C:    CLOSED
  P2-D:    CLOSED
  P2-E:    CLOSED
  P2-F:    CLOSED
  P2-G:    CLOSED
  V1-R09Q: CLOSED / ACCEPTED
  R09Q-A:  CLOSED / ACCEPTED
  R09Q-B:  CLOSED / ACCEPTED
  R09Q-C:  CLOSED / ACCEPTED
  V1-R10:  CURRENT / AUTHORIZED

V1-R09Q boundary (preserved):
  - V1-R09Q is the NEXT cross-cutting quality gate (CI baseline; selected
    cross-feature integration smoke; auth/session/offline cross-feature
    journeys; relevant Supabase/RLS positive + negative evidence;
    migration/reproducibility baseline);
  - no R09Q work is pulled back into this closure; R09Q claims only its own
    authorized scope and does not claim already-verified R09 behavior as a
    re-verification;
  - R09Q implementation is NOT started; it begins only after the Architect
    supplies its contract freeze / authorization;
  - no additional R09 technical gate is invented.

Owner approval: PENDING OWNER STAGING (per operating model, the user is the
sole Git staging/commit/push owner).

---

### V1-R09Q Contract Freeze Record

Phase: V1-R09Q — Post-R09 Cross-Cutting Quality Gate
Status: CURRENT — QUALITY CONTRACT FROZEN
Contract: V1-R09Q-CONTRACT-v1
Contract path: docs/architecture/contracts/V1-R09Q_CROSS_CUTTING_QUALITY_GATE_CONTRACT.md
Architect decision: QUALITY CONTRACT FROZEN (docs only; no production code,
  test, CI, Supabase, migration, seed, or staged file modified by this freeze)
IMPLEMENTATION_AUTHORIZED: NO — R09Q-A / R09Q-B implementation begins only
  after the Architect checkpoint approval

Structure (frozen exactly):
- R09Q-A — CI + Cross-Feature Smoke (implementer: Big Pickle; reviewer:
  GitHub Copilot Civilpedia Reviewer)
- R09Q-B — Supabase Reproducibility + Security Evidence (implementer:
  Codex / GPT-5.6 Sol High; reviewer: GitHub Copilot Civilpedia Reviewer or
  another independent strong reviewer)
- R09Q-C — FORMAL CLOSURE ONLY (documentation/closure, NOT a third
  implementation slice)

R09Q-A decisions ratified:
- ADD `.github/workflows/flutter_quality.yml` (ONE stable CI workflow; triggers:
  pull_request, push to main, workflow_dispatch; NO nightly job);
- ADD `tool/quality_gate.ps1` deterministic gate (runs
  `flutter test --no-pub <single-suite>`, ONE SUITE AT A TIME; no analyzer,
  no format enforcement, no Flutter build in the required fast gate);
- CI Flutter version FROZEN: Flutter 3.32.8 stable / Dart 3.8.1 (pubspec
  `sdk: ^3.8.1`; documented reports; local environment) — explicitly pinned,
  never silent "latest";
- CI: FRESH checkout -> setup pinned Flutter -> `flutter pub get` -> deterministic
  quality gate -> selected suites sequentially;
- selected CI test list FROZEN (exact paths in contract §10; 19 suites);
- MODIFY `test/v1_r06_profile_management_server_test.dart` to remove stale
  V1-R06 live-roadmap coupling (TEST/EVIDENCE reconciliation; preserve
  server-contract/security intent; assert durable facts; no skip/delete/weaken;
  no production change);
- ADD `test/v1_r09q_smoke_journeys_test.dart` (Journeys A recovered auth chain,
  B transport-flip coexistence, C sign-out only if a seam emerges);
- full Flutter repository suite NOT required to close R09Q; nightly NOT
  created; R17 remains the final comprehensive E2E gate;
- baseline dirty tests excluded from CI evidence and untouched.

R09Q-B decisions ratified:
- ADD `supabase/seed.sql` (minimal/no-op; makes configured `./seed.sql` path
  valid; no sample production data; no migration change to fix the reference);
- ADD `test/v1_r09q_migration_lint_test.dart` (canonical numeric naming,
  strictly increasing order, unique numbers, required historical baseline
  present, configured seed path resolves, no filename collision; MUST NOT
  assert "migration 00022 must not exist");
- ADD `test/v1_r09q_security_matrix_test.dart` (static high-value invariants:
  RLS where required, auth.uid() ownership anchors, revoked direct UPDATE stays
  revoked, staff/audit/billing grant protection, no RPC execute grant to anon,
  controlled search_path on SECURITY DEFINER, authenticated actor/capability
  checks, non-callable helpers remain revoked, no client/service-role bypass);
- runtime LOCAL Supabase security smoke MANDATORY (probe CLI/Docker READ ONLY
  first; no automatic tool install; local stack only; never linked/staging/
  prod); if tooling unavailable return
  `R09Q-B LOCAL SECURITY GATE REQUIRES ARCHITECT DECISION`;
- authorize local-only `supabase db reset` when tooling available; record CLI
  version, reset exit status, migration/seed application result;
- representative positive/negative profile/business/staff/RPC evidence only
  (no exhaustive R15 matrix);
- preferred runtime artifact `supabase/tests/v1_r09q_security_smoke.sql`
  (pgTAP / `supabase test db` if supported; no bespoke broad DB test
  framework);
- fixed non-production UUID/test-identity local fixtures only; no real data,
  no credentials, no service_role in Flutter; privileged local SQL fixture
  setup stays inside the local test harness only;
- no new migration / RLS / policy / RPC / grant modification authorized.

R09Q-C: documentation closure only after A + B acceptance; then
`V1-R09Q CLOSED` / `V1-R10 NEXT / AUTHORIZABLE`.

Boundary (ratified):
- R09Q is NOT R10 UI redesign, NOT R14 backend readiness, NOT R15 final
  security audit, NOT R17 full E2E, NOT performance/load testing, NOT
  observability rollout, NOT production deployment;
- production Flutter code: NONE by default; a real production defect -> STOP
  for Architect decision;
- no observability (Sentry/provider selection) in R09Q; deferred to later
  backend/release readiness;
- no service-role secret committed (inspection confirmed none); HIGH blocker if
  one is found;
- execution order: freeze -> A -> A review -> B (Codex/Sol High) -> B security
  review -> C closure -> R10 NEXT; no simultaneous A/B.

Closure blockers frozen:
- HIGH: unauthorized data access; stale authenticated data crossing identity;
  ownership/staff authority bypass; committed service-role secret; local clean
  DB cannot reproduce required schema due to migration defect; RLS/RPC bypass
  proven by runtime smoke.
- MEDIUM: CI fast gate absent/non-deterministic; stale R06 coupling not
  reconciled; missing cross-feature smoke; incomplete migration lint/security
  matrix; seed/config mismatch unresolved; local db reset not proven when
  tooling available; missing representative positive/negative runtime security
  evidence; selected CI suite failure.
- LOW: non-functional naming/readability; historical wording; nightly/full
  suite absence; analyzer exclusion.
- HIGH/MEDIUM: R09Q cannot close.

Git safety (this freeze):
- HEAD == origin/main == 91e162553d9f67606ff0e4a081a6c31c159f8d40;
- docs changes only: V1-R09Q contract + this roadmap update;
- nothing staged/committed/pushed;
- baseline dirty paths untouched.

Live state (ONE authoritative live roadmap state):
  V1-R09:  CLOSED
  R09Q-A:  CLOSED / ACCEPTED
  R09Q-B:  CLOSED / ACCEPTED
  R09Q-C:  CLOSED / ACCEPTED
  V1-R09Q: CLOSED / ACCEPTED
  V1-R10:  CURRENT / AUTHORIZED

R09Q-A, R09Q-B, and R09Q-C are formally closed. V1-R09Q is CLOSED / ACCEPTED.
V1-R10 is now CURRENT / AUTHORIZED and awaits the Architect's V1-R10 contract
freeze before implementation begins.
Owner approval: PENDING OWNER STAGING (user is the sole Git owner).

---

### R09Q-A Formal Closure Record

Slice: R09Q-A — CI + Cross-Feature Smoke
Status: CLOSED / ACCEPTED
Contract: V1-R09Q-CONTRACT-v1 + ARCHITECT ADDENDUM A — CI ACTIVATION SEQUENCING
Closure commit: c2b5c006b78398558b1aefc50cd71f6f97cdc637

R09Q-A delivered:
- first repository GitHub Actions Flutter quality workflow
  (`.github/workflows/flutter_quality.yml`);
- deterministic PowerShell quality-gate script (`tool/quality_gate.ps1`);
- sequential one-suite-at-a-time execution;
- fail-fast behavior;
- hard failure for missing required suite;
- no analyzer/format/build/Supabase in the required fast A-stage gate;
- pinned Flutter 3.32.8 stable;
- fresh CI `flutter pub get`;
- cross-feature recovered-auth smoke (Journey A);
- cross-feature transport-flip smoke (Journey B);
- durable R06 server-test reconciliation (removed stale live-roadmap coupling);
- no production Flutter changes;
- no Supabase/backend changes.

Implementation trail:
- Initial R09Q-A implementation:
  c460a69d91c7fbcc992ea0226a65d7e51f94624e
  `ci(r09q): establish cross-cutting Flutter quality gate`
- Hosted CI then exposed three historical Windows line-ending-sensitive
  server-source tests. Architect-authorized test/evidence corrections:
  - R03: 91da3b905d81a403607e52ce4312f4e7e52769e9
    `test(r09q): normalize R03 migration line endings`
  - R06: 87f727592919e19521756008277a8e2e2a0a7ef7
    `test(r09q): normalize R06 migration line endings`
  - R07: c2b5c006b78398558b1aefc50cd71f6f97cdc637
    `test(r09q): normalize R07 migration line endings`
- Each correction normalizes CRLF -> LF at the test source-read seam only, does
  NOT change migrations, does NOT change production, and does NOT weaken
  security assertions.

Local acceptance evidence:
- R09Q-A smoke suite: 2/2 PASS
- R06 reconciled suite: 15/15 PASS
- R03 after hosted correction: 21/21 PASS
- R06 after hosted correction: 15/15 PASS
- R07 after hosted correction: 28/28 PASS
- Complete A-stage quality gate: 17 selected suites / 17 PASS / 0 FAIL

Independent review:
- Initial independent review: FAIL — one MEDIUM stale R06 roadmap coupling.
- Surgical correction: accepted after final micro-review.
- R03 hosted correction: independent micro-review PASS.
- R06 hosted correction: independent micro-review PASS.
- R07 hosted correction: independent micro-review PASS.
- Reviewer shell was unavailable for those reviews; independent source/diff
  inspection supplied review evidence and implementer shell supplied local
  execution evidence. No independent test execution is claimed.

Hosted CI evidence:
- Repository: Civilpedia
- Workflow: flutter-quality
- Trigger: push to main
- Commit: c2b5c006b78398558b1aefc50cd71f6f97cdc637
- Run: #4
- Result: SUCCESS
- Job: selected-cross-cutting-suites — SUCCESS
- The permanent R09Q-A selected gate completed green under GitHub-hosted
  windows-latest. This satisfies the frozen formal-closure requirement that
  hosted CI be green.

Hosted failure history (test/evidence defects only; NOT production/migration
/security defects):
- Hosted run #1: R03 historical migration-source assertion failed due LF vs CRLF.
- Hosted run #2: R06 historical migration-source assertions failed due LF vs CRLF.
- Hosted run #3: R07 historical migration-source assertion failed due LF vs CRLF.
- Each was corrected narrowly at the test source-read seam.
- Final hosted run #4: SUCCESS.

Tooling note:
- Final hosted run contains a non-blocking GitHub Actions warning about Node.js
  20 deprecation / action runtime moved to Node.js 24.
- Severity: LOW / NON-BLOCKING TOOLING NOTE.
- The workflow completed SUCCESSFULLY.
- No R09Q-A correction required; no CI modification performed in this closure.

Addendum A state preserved:
- R09Q-A permanent gate contains the authorized A-stage suite list (17 suites).
- R09Q-B remains responsible for creating:
  - `test/v1_r09q_migration_lint_test.dart`
  - `test/v1_r09q_security_matrix_test.dart`
- R09Q-B is then authorized to modify ONLY `tool/quality_gate.ps1` to activate
  those two suites into the FINAL R09Q permanent CI gate.
- No test may remain silently optional at R09Q final closure.

R09Q-B unlock (superseded by R09Q-B Formal Closure Record below):
- Status after this closure checkpoint: NEXT / AUTHORIZABLE.
- Purpose: Supabase Reproducibility + Security Evidence.
- Preferred implementer: Codex / GPT-5.6 Sol High.
- R09Q-B remained responsible for:
  - `supabase/seed.sql`
  - migration lint
  - static security matrix
  - local Supabase CLI/Docker probe
  - local `supabase db reset`
  - representative positive/negative runtime RLS/RPC security smoke
  - activation of its two CI-safe tests in `tool/quality_gate.ps1`

Live state (ONE authoritative live roadmap state):
  V1-R09:    CLOSED / ACCEPTED
  R09Q-A:    CLOSED / ACCEPTED
  R09Q-B:    CLOSED / ACCEPTED
  R09Q-C:    CLOSED / ACCEPTED
  V1-R09Q:   CLOSED / ACCEPTED
  V1-R10:    CURRENT / AUTHORIZED

---

### R09Q-B Formal Closure Record

Slice: R09Q-B — Supabase Reproducibility + Security Evidence
Status: CLOSED / ACCEPTED
Contract: V1-R09Q-CONTRACT-v1 + ARCHITECT ADDENDUM A — CI ACTIVATION SEQUENCING
Implementation commit: 8a1f38694165b535fad6fd8b1924464a1dcb1f9c
Independent security review: PASS

R09Q-B delivered:
- `supabase/seed.sql` added to make the configured `./seed.sql` path valid;
- `test/v1_r09q_migration_lint_test.dart` permanent migration lint evidence;
- `test/v1_r09q_security_matrix_test.dart` permanent static RLS/RPC/grant
  security evidence;
- `tool/quality_gate.ps1` modified to activate the two B-owned suites into the
  permanent 19-suite CI gate;
- local Supabase reset proven clean (migrations 00001–00021 applied,
  seed applied);
- local pgTAP runtime security smoke covering Profile, Business/Application,
  Staff, and protected SECURITY DEFINER RPC positive + negative cases;
- no unauthorized runtime access;
- no security defects discovered;
- no existing migration, RLS, RPC, grant, or Flutter production code modified.

Local acceptance evidence:
- Migration lint: 5/5 PASS
- Static security matrix: 10/10 PASS
- Local `supabase db reset`: PASS
  - migrations 00001 through 00021 applied successfully
  - `supabase/seed.sql` applied successfully
- Runtime pgTAP security smoke: 12/12 PASS
- Local permanent Flutter quality gate: 19 selected suites / 19 PASS / 0 FAIL

Hosted CI evidence:
- Repository: Civilpedia
- Workflow: flutter-quality
- Commit: 8a1f38694165b535fad6fd8b1924464a1dcb1f9c
- Job: selected-cross-cutting-suites
- Status: SUCCESS
- The B-inclusive 19-suite permanent gate completed green under GitHub-hosted
  windows-latest.

Tooling note:
- Hosted annotation: Node.js 20 deprecation / actions being forced to Node.js 24.
- Severity: LOW / NON-BLOCKING TOOLING NOTE.
- Workflow completed SUCCESSFULLY; no R09Q remediation required.

Live state (ONE authoritative live roadmap state):
  V1-R09:    CLOSED / ACCEPTED
  R09Q-A:    CLOSED / ACCEPTED
  R09Q-B:    CLOSED / ACCEPTED
  R09Q-C:    CLOSED / ACCEPTED
  V1-R09Q:   CLOSED / ACCEPTED
  V1-R10:    CURRENT / AUTHORIZED

---

### R09Q-C Opening

Slice: R09Q-C — Formal Closure Only
Status: CLOSED / ACCEPTED
Contract: V1-R09Q-CONTRACT-v1

R09Q-C purpose:
- reconcile final R09Q evidence from R09Q-A and R09Q-B;
- verify A and B closures are complete and accepted;
- confirm the permanent quality gate remains active;
- formally close V1-R09Q;
- authorize transition to V1-R10.

R09Q-C did NOT introduce production code, tests, migrations, security changes,
UI work, or V1-R10 implementation.

Implementation authorized: YES — for documentation/closure only.
Preferred agent: Big Pickle.

Live state (ONE authoritative live roadmap state):
  V1-R09:    CLOSED / ACCEPTED
  R09Q-A:    CLOSED / ACCEPTED
  R09Q-B:    CLOSED / ACCEPTED
  R09Q-C:    CLOSED / ACCEPTED
  V1-R09Q:   CLOSED / ACCEPTED
  V1-R10:    CURRENT / AUTHORIZED

---

### V1-R09Q Final Closure Record

Phase: V1-R09Q — Post-R09 Cross-Cutting Quality Gate
Previous status: CURRENT
New status: CLOSED / ACCEPTED — V1-R09Q FORMALLY CLOSED
Contract: V1-R09Q-CONTRACT-v1 + ARCHITECT ADDENDUM A — CI ACTIVATION SEQUENCING
Closure commit: 6b4bf99ad9a8bfe1583cb02760bf40b5e037fd08
Owner approval: PENDING OWNER STAGING (user is the sole Git owner)

R09Q-A accepted:
- first repository GitHub Actions Flutter quality workflow established;
- `tool/quality_gate.ps1` selected-suite SSOT established;
- cross-feature smoke journeys added;
- sequential fail-fast 17-suite A-stage gate green locally and hosted.

R09Q-B accepted:
- implementation commit `8a1f38694165b535fad6fd8b1924464a1dcb1f9c`;
- independent security review PASS;
- migration lint 5/5 PASS;
- static security matrix 10/10 PASS;
- local `supabase db reset` PASS (migrations 00001–00021, seed applied);
- runtime pgTAP security smoke 12/12 PASS;
- representative enforcement verified for Profile, Business/Application, Staff,
  and protected SECURITY DEFINER RPC;
- no unauthorized success; no security defects;
- permanent quality gate expanded to 19 selected suites;
- local final quality gate 19/19 PASS;
- hosted GitHub Actions `selected-cross-cutting-suites` SUCCESS on commit
  `8a1f386`.

Unresolved findings:
- HIGH: none
- MEDIUM: none
- LOW: Node.js 20 deprecation / GitHub Actions forced Node.js 24 annotation —
  NON-BLOCKING TOOLING NOTE.

R09Q technical invariants surviving into V1-R10:
- 19-suite permanent fast quality gate;
- fail-fast sequential execution;
- migration lint;
- static security matrix;
- source-controlled `supabase/seed.sql`;
- local reproducibility evidence;
- no `service_role` in client/test paths;
- representative runtime security smoke artifact retained;
- no remote DB dependency in hosted fast CI.

Live state (ONE authoritative live roadmap state):
  V1-R09:    CLOSED / ACCEPTED
  R09Q-A:    CLOSED / ACCEPTED
  R09Q-B:    CLOSED / ACCEPTED
  R09Q-C:    CLOSED / ACCEPTED
  V1-R09Q:   CLOSED / ACCEPTED
  V1-R10:    CURRENT / AUTHORIZED

---

### V1-R10 Opening

Phase: V1-R10 — UI/UX & Core App Experience
Status: CURRENT / AUTHORIZED
Previous status: QUEUED after V1-R09Q

V1-R10 is the PRIMARY V1 UI/UX / design-system phase. It defines the final V1
visual direction and core app experience before later major features
(V1-R11/V1-R12/V1-R13) are built.

Implementation authorized: NO until ChatGPT Architect issues the V1-R10
Contract Freeze / implementation prompt.

Primary: Big Pickle.

Architect-defined sub-phases (preserved from V1-R10 roadmap section):
- R10.1 — Visual Direction Freeze
- R10.2 — Design System
- R10.3 — Core Screen Redesign / Harmonization
- R10.4 — Responsive / Locale / Theme Hardening
- R10.5 — Visual QA / UX Regression

UI FREEZE PRINCIPLE (post-R10):
- polish and small consistency fixes remain allowed;
- wholesale navigation, typography, or layout-philosophy redesigns require
  Architect decision.

Next after V1-R10 closes:
  V1-R11 — Projects Production Pass (QUEUED)

---

### V1-R10 Current Status Synchronization

This append-only synchronization supersedes the stale authorization wording in
the historical V1-R10 Opening record without rewriting that history.

Authoritative current state:

- R10.1: CLOSED / ACCEPTED;
- R10.2: CLOSED / ACCEPTED — Theme + Shared UI Foundation;
- R10.3: CLOSED / ACCEPTED — App Shell, Navigation & Global States;
- R10.4-A: CURRENT / OPEN — Home Production Visual Pass;
- R10.4-B: LOCKED / NOT AUTHORIZED;
- Search, Saved, broader R10.4 propagation, and R10.5 through R10.7: LOCKED.

Implementation authorization remains limited to V1-R10.4-A. R10.4-A is not
closed by this synchronization and still requires its remaining manual visual
closure actions and Architect acceptance.

---

### V1-R10.4-A Formal Closure Record

Slice: R10.4-A — Home Production Visual Pass
Contract: V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md (R10.4-A Home Production
  Visual Pass scope) — frozen semantics preserved unchanged; only this
  append-only formal closure record is added.
Architect decision: PASS — R10.4-A ACCEPTED
Status: CLOSED / ACCEPTED
Implementation commit: PENDING OWNER COMMIT (R10.4-A work remains accumulated
  and uncommitted above HEAD == origin/main == 658415ee46ffd774ddfab82205c4828a091129cc)
Owner approval: PENDING OWNER STAGING (user is the sole Git owner)

Acceptance evidence (all complete):
- final scope audit: COMPLETED
- audit correction implementation: COMPLETED
- post-correction independent re-review: PASS
- focused regression gate: 90 PASSED / 0 FAILED
- unresolved HIGH findings: NONE
- unresolved MEDIUM findings: NONE
- Directory manual runtime taps: PASS
  - الموردون
  - الشركات
  - المكاتب الهندسية
  - الخدمات
  - عرض الكل
- manual Home bottom-navigation clearance runtime check: PASS
- true-black governance amendment: synchronized / PASS
- Future Product Backlog roadmap addendum: independently verified PASS

Scope / non-change confirmation (R10.4-A):
- no routing semantic changes
- no auth/startup/backend changes
- no calculator formula changes
- no Directory business-authority changes
- no Encyclopedia SSOT changes
- no Search/Saved redesign performed inside R10.4-A

Live state (ONE authoritative live roadmap state):
  R10.1:    CLOSED / ACCEPTED
  R10.2:    CLOSED / ACCEPTED
  R10.3:    CLOSED / ACCEPTED
  R10.4-A:  CLOSED / ACCEPTED
  R10.4-B:  NEXT / CURRENT / AUTHORIZED — IMPLEMENTATION NOT STARTED
  R10.5:    future relative to the current R10.4-B slice
  Search / Saved / broader R10.4 propagation: LOCKED

---

### V1-R10.4-B Current / Authorized Record

Slice: R10.4-B — remaining R10.4 Core Discovery work (already-defined scope)
Previous status: LOCKED / NOT AUTHORIZED
New status: CURRENT / AUTHORIZED — IMPLEMENTATION NOT STARTED
IMPLEMENTATION_AUTHORIZED: YES — V1-R10.4-B ONLY (implementation NOT started)
Implementation: NOT STARTED

Decisions (unchanged by this documentation task):
- R10.4-B scope remains the already-defined remaining R10.4 Core Discovery work
  only.
- R10.4-B contract is NOT redefined or expanded in this documentation task.
- implementation is NOT started by this task.
- Article work is NOT pulled into R10.4-B.
- R10.5 is NOT authorized; R10.5 remains future relative to the current
  R10.4-B slice.
- Search / Saved redesign and broader R10.4 propagation remain outside this
  slice's already-defined scope (LOCKED).

---

### R10.4 Article Sequencing Note

Minimal Architect sequencing note (non-duplicative):
- Article visual/presentation work remains owned by the existing V1-R10.5
  Cross-Feature Visual Adoption scope.
- It MUST NOT be pulled into R10.4-B.
- No new phase ID is created.
- Article work is NOT added to the Future Product Backlog because V1-R10.5
  already owns article presentation.
- No Article source, Content Studio file, JSON, content, or Flutter file is
  edited by this documentation task.

Content Studio protection (unchanged by this task):
- no change to draft_jsons/**, app_ready_jsons/**, assets/encyclopedia/**,
  the generated catalog, Content Studio Editor, Content Studio Preview, the
  Exporter, article data/model, article rendering, or Article UI.
- The future R10.5 Article task will first perform a read-only ownership audit
  before any implementation.

---

### V1-R10.4-B Formal Closure Record

Slice: R10.4-B — Search + Saved Production Visual Pass
Contract: V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md APPENDIX B — V1-R10.4-B
  IMPLEMENTATION CONTRACT FREEZE (frozen semantics preserved unchanged; only
  this append-only formal closure record is added)
Architect decision: PASS — R10.4-B ACCEPTED
Status: CLOSED / ACCEPTED
Implementation commit: PENDING OWNER COMMIT (R10.4-B work remains accumulated
  and uncommitted above HEAD == origin/main == 00d09f1c8fc93be8f52e8ad0fad1d078daf56d75)
Owner approval: PENDING OWNER STAGING (user is the sole Git owner)

Acceptance evidence (all complete):
- implementation: COMPLETED
- Search focused gate: 58 PASS / 0 FAIL
- Saved focused gate: 122 PASS / 0 FAIL
- independent post-implementation review: PASS
- manual runtime / visual review: PASS
- Arabic RTL: PASS
- English LTR: PASS
- Light: PASS
- Dark: PASS
- responsive / readable-width behavior: PASS
- Search semantics: PRESERVED
- Saved persistence/resolution semantics: PRESERVED
- unresolved HIGH findings: NONE
- unresolved MEDIUM findings: NONE
- unresolved LOW findings: NONE

Scope / non-change confirmation (R10.4-B):
- no routing semantic changes
- no Search domain/data/navigation changes
- no Saved domain/data changes
- no Hive authority changes
- no Directory authority changes
- no Encyclopedia SSOT changes
- no Article / Content Studio changes
- no R10.5 implementation performed inside R10.4-B

---

### V1-R10.4 Formal Closure Record (parent slice)

Slice: R10.4 — Core Discovery: Home / Search / Saved
Status: CLOSED / ACCEPTED
Composed of:
- R10.4-A — Home Production Visual Pass: CLOSED / ACCEPTED
- R10.4-B — Search + Saved Production Visual Pass: CLOSED / ACCEPTED
Scope / non-change confirmation (R10.4 overall):
- no routing semantic changes
- no Search domain/data/navigation changes
- no Saved domain/data changes
- no Hive authority changes
- no Directory authority changes
- no Encyclopedia SSOT changes
- no Article / Content Studio changes
- no calculator formula changes
- no auth / startup / backend changes

---

### V1-R10.5 Current / Authorized Record

Slice: R10.5 — Cross-Feature Visual Adoption Pass
Previous status: future / locked relative to the current R10.4-B slice
New status: CURRENT / AUTHORIZED — IMPLEMENTATION NOT STARTED
IMPLEMENTATION_AUTHORIZED: YES — V1-R10.5 ONLY (implementation NOT started)
Implementation: NOT STARTED

Decisions (unchanged by this documentation task):
- R10.5 scope remains the existing V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT
  R10.5 Cross-Feature Visual Adoption Pass; existing R10.5 contract/scope is
  preserved and NOT redefined.
- implementation is NOT started by this task.
- R10.6 and R10.7 remain future / locked relative to R10.5.

Article sequencing (append-only, non-duplicative):
- Article presentation work is now eligible under the existing V1-R10.5
  Cross-Feature Visual Adoption scope.
- No separate phase ID is required.
- Future Article work must remain presentation-only unless a later Architect
  decision explicitly expands scope.
- Content Studio / content SSOT / article body ordering remain protected.
- The Article implementation design is NOT frozen by this documentation task.

### V1-R10.5-A Formal Closure Record

Slice: V1-R10.5-A — Article Production Visual Pass
Contract: V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md APPENDIX C —
          V1-R10.5-A ARTICLE PRODUCTION VISUAL PASS FREEZE
Previous status: CURRENT / AUTHORIZED — FROZEN
New status: CLOSED / ACCEPTED
Architect decision: PASS — V1-R10.5-A ACCEPTED
Closure baseline: HEAD == origin/main == 4e53d634d1c61f90e8a9cdd939d7fb501c3270ce

Acceptance evidence:
- implementation completed (3 Article screens presentation pass)
- focused presentation tests: 4 PASS / 0 FAIL
- Article-focused regression gate: 16 PASS / 0 FAIL
- independent post-implementation review: PASS
- HIGH findings: NONE; MEDIUM findings: NONE; LOW findings: 2 non-blocking /
  deferred
- manual runtime visual review: PASS (Light, Dark, Arabic RTL, Article list,
  Article detail)
- favorite / download presentation preserved
- no invented metadata
- Article data / body semantics preserved

Scope / non-change confirmation (V1-R10.5-A):
- ArticleModel unchanged; ArticleRepository unchanged; Hive unchanged
- ArticleImage unchanged; Article routes unchanged
- Content Studio untouched; Encyclopedia SSOT untouched
- no R10.5-B or later slice implementation performed inside R10.5-A
- no service_role; no new data source; no new provider/state authority

Non-blocking deferred content note (image/content mismatch):
- "طبقات الرصف للطرق" currently displays a residential-building image (observed
  during manual QA). NOT an R10.5-A presentation defect; R10.5-A preserved
  existing Article image/data sources. Do NOT change the image,
  ArticleRepository, or ArticleModel here. Classify for later content/media
  cleanup only.

Language scope (recorded):
- See the V1 Owner Language-Scope Decision Record below.

Status:
V1-R10.5-A:  CLOSED / ACCEPTED
V1-R10.5-B:  NEXT / CURRENT / AUTHORIZED — IMPLEMENTATION NOT STARTED
V1-R10.5-C through R10.5-F: LOCKED
V1-R10.6 / V1-R10.7: future / locked relative to R10.5

### V1-R10.5-B Current / Authorized Record

Slice: V1-R10.5-B — Tools + Calculators Presentation Pass
Previous status: future / locked relative to the current R10.5-A slice
New status: CURRENT / AUTHORIZED — IMPLEMENTATION NOT STARTED
IMPLEMENTATION_AUTHORIZED: YES — V1-R10.5-B ONLY (implementation NOT started)
Implementation: NOT STARTED

Decisions (recorded by this documentation task):
- R10.5-B scope remains the existing V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT
  R10.5 Cross-Feature Visual Adoption scope, Tools + Calculators presentation
  pass, as preserved in APPENDIX C.12 and the R10.5 slice plan.
- R10.5-B contract is NOT redefined or expanded by this documentation task.
- implementation is NOT started by this task.
- R10.5-C through R10.5-F remain LOCKED.
- R10.6 and R10.7 remain future / locked relative to R10.5.

### V1 Owner Language-Scope Decision Record

Decision: Civilpedia V1 user-facing product is ARABIC-ONLY.
Authority: ChatGPT Architect + explicit Owner product decision.
Status: ACTIVE / RECORDED — supersedes any R10 manual-acceptance wording that
requires English/LTR as an active user-facing V1 path.

Consequences:
- Arabic RTL is the active V1 user-facing locale requirement.
- English / LTR is NOT a manual runtime acceptance requirement while the
  user-facing language switch remains disabled.
- Do NOT enable an English switch.
- Do NOT treat unavailable user-facing English switching as a defect.
- Existing En localization resources may remain.
- Existing dormant English-support code / tests do NOT need to be removed merely
  because switching is disabled.
- Do NOT perform a broad localization cleanup or delete En keys.
- A future Owner / Architect decision may reactivate English.

Governance:
- Arabic RTL remains the required manual acceptance path for the active V1
  language scope.
- Do NOT retroactively rewrite historical test evidence.
- Do NOT reopen already accepted R10.4 (or any earlier) work.

---

## Future Product Backlog — Architect Notes

STATUS: PLANNING NOTES ONLY

IMPLEMENTATION_AUTHORIZED: NO

These items preserve future product intent only. They do NOT:

- modify the CURRENT phase;
- unlock a future slice;
- define final implementation scope;
- override future phase contracts;
- establish backend/schema requirements;
- authorize UI implementation.

Final scope, architecture, data model, UX, tests, and ownership must be frozen
through the relevant future phase/contract before implementation.

### Engineering Unit Converter

Probable owner: V1-R12 — Tools / Calculators Final Engineering QA

Status: FUTURE CANDIDATE / NOT AUTHORIZED

Product intent: Create an engineering-focused offline unit conversion tool.

Initial conversion families recorded as candidates:

- Length
- Area
- Volume
- Mass
- Force
- Pressure / Stress
- Moment / Torque
- Density
- Flow rate
- Velocity
- Temperature
- Angle

Potential later enhancements:

- fast bidirectional conversion
- recent conversions
- favorite units
- engineering-first unit ordering
- integration with calculator inputs/results
- contextual conversion from engineering content

Architecture principle: Conversion formulas must eventually have ONE canonical
conversion authority. Do not duplicate conversion formulas independently
across calculators. No implementation is authorized by this note.

### Additional Engineering Calculators

Probable owner: V1-R12

Status: FUTURE CANDIDATE / NOT AUTHORIZED

Intent: Expand Civilpedia's calculator library after a dedicated engineering
QA / scope freeze.

Candidate families may include:

- Quantity calculations
- Concrete calculations
- Reinforcement calculations
- Masonry / blockwork calculations
- Area / volume calculations
- Bar count / tonnage
- Development length
- Lap splice
- selected structural/site engineering checks where appropriate

Important: Do NOT freeze exact formulas or calculator inventory in this
roadmap note. R12 must later create the authoritative calculator master list
and validate engineering formulas, units, references, assumptions, and
limitations.

### Site Tools & Instruments Encyclopedia

Probable owner: V1-R13 — Encyclopedia / Content Studio Finalization

Status: FUTURE CANDIDATE / NOT AUTHORIZED

Intent: Create a visual engineering reference for tools, instruments, testing
devices, and small site equipment used in civil engineering.

Each future entry may contain:

- Arabic name
- English name
- common Iraqi/site name where useful
- image / illustration
- category
- primary function
- where it is used
- basic usage guidance
- safety notes
- common mistakes / misuse
- related Civilpedia topics
- related calculators/tools where applicable

Possible category groups:

- Surveying instruments
- Concrete tools
- Reinforcement tools
- Formwork/carpentry tools
- Earthworks/compaction tools
- Masonry/finishing tools
- Laboratory/testing equipment
- Measuring tools
- Safety equipment
- Lifting/handling tools
- General site equipment

Examples may later include:

- Total Station
- Auto Level
- Theodolite
- Slump Cone
- Cube Mould
- Concrete Vibrator / Poker Vibrator
- Rebar Cutter
- Rebar Bender
- Plate Compactor
- Rammer
- Core Drill

Do NOT create content records now. Respect the existing Civilpedia content SSOT
when R13 eventually implements it.

### Construction Machinery & Heavy Equipment Encyclopedia

Probable owner: V1-R13

Status: FUTURE CANDIDATE / NOT AUTHORIZED

Intent: Create a structured visual reference for major construction machinery
and heavy equipment, recorded as a distinct content family from hand
tools/instruments.

Potential examples:

- Excavator
- Backhoe Loader
- Bulldozer
- Wheel Loader
- Motor Grader
- Roller / Compactor
- Mobile Crane
- Tower Crane
- Concrete Pump
- Transit Mixer
- Piling Rig
- Forklift
- Telehandler

Each future entry may include:

- Arabic name
- English name
- common site/local name
- image
- equipment category
- primary function
- typical applications
- main types
- important specifications
- basic selection guidance
- safety considerations
- common misuse
- related Civilpedia construction activities/topics

Important: Site Tools / Instruments and Heavy Machinery should remain distinct
content families even if presented under a wider umbrella such as
"Site Tools & Equipment" or "معدات وأدوات الموقع". Final taxonomy belongs to
R13.

### Engineering Directory Media System

Probable owner: TBD BY ARCHITECT

Status: FUTURE CANDIDATE / NOT AUTHORIZED

Intent: Allow richer visual identity for real Directory entities in a future
Directory evolution.

Potential entity media:

- Company/provider logo
- Engineering-office logo
- Supplier/store logo
- Cover image
- Project/work gallery
- Material/product gallery
- default placeholder identity
- optimized/cached media

Important distinction: HOME DIRECTORY CATEGORY SHORTCUTS and REAL DIRECTORY
ENTITY MEDIA are NOT the same system.

For the Home category shortcuts (الموردون، الشركات، المكاتب الهندسية، الخدمات)
the current compact icon-based design remains accepted. A future visual pass may
optionally replace generic icons with custom Civilpedia engineering
illustrations/icons. Do NOT require photographic images on those compact Home
shortcut cards.

For individual Directory entities: logo should normally be the primary identity
for companies, suppliers, engineering offices, and stores/organizations.
Future individual-person profiles, if ever authorized by the Directory domain,
may use profile photography instead. Cover/gallery media is separate from the
entity's primary logo.

Do NOT design storage/schema/upload architecture in this roadmap note. Phase
ownership and backend/media architecture remain TBD BY ARCHITECT.

### Product Relationships

These future candidates should eventually support the Civilpedia product flow:

Engineering Knowledge → Engineering Decision → Engineering Action

Examples:

- Encyclopedia equipment entry → related calculator → unit conversion →
  related field/site guidance;
- Directory category → provider/company identity → future provider
  media/profile.

These are conceptual relationships only. Do NOT implement cross-feature
navigation now.

### Current Phase Protection

None of these backlog notes change:

- V1-R10.4-A scope;
- Home closure requirements;
- Search/Saved authorization;
- R10.4-B status;
- R11;
- R12 authorization state;
- R13 authorization state;
- Directory business authority;
- Encyclopedia SSOT;
- backend/storage/schema authority.

They are FUTURE PLANNING NOTES ONLY.

---

### V1-R10.5-B Formal Closure + V1-R10.5-C Transition Record

Slice: V1-R10.5-B — Tools + Calculators Presentation Pass

Contract: `V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md` APPENDIX E (frozen
implementation boundary preserved) and the append-only formal-closure addendum.

Previous status: CURRENT / AUTHORIZED

New status: CLOSED / ACCEPTED

Architect final acceptance: PASS — R10.5-B ACCEPTED

Implementation commit: PENDING OWNER COMMIT — implementation remains uncommitted

Closure baseline: HEAD == origin/main ==
`be7a4b322903c8fe8609fa175833b7002e37523d`

Acceptance evidence:

- implementation completed inside the frozen 7-file production boundary;
- presentation gate: 138 PASS / 0 FAIL;
- domain gate: 133 PASS / 0 FAIL;
- independent review: PASS;
- findings: HIGH 0; MEDIUM 0; LOW 1 — accepted/deferred, non-blocking;
- Owner manual visual review: PASS;
- Light / Dark visual review: PASS;
- Arabic RTL visual review: PASS.

Accepted deferred LOW finding:

- the new R10.5-B visual test does not explicitly assert that the Checklist
  `CivilAppBar` background differs from `AppColors.primary`;
- classification: LOW / NON-BLOCKING / ACCEPTED / DEFERRED;
- R10.5-B implementation MUST NOT be reopened for this finding.

Protected and unchanged:

- calculator formulas and engineering domain semantics;
- checklist state, progress, reset behavior, and persistence semantics;
- routes and application shell;
- localization resources and active Arabic RTL behavior;
- Tools landing;
- `ProjectPicker`;
- R10.5-C and all later-slice production implementation.

Next-slice transition:

- V1-R10.5-C — Projects Presentation Pass:
  CURRENT / AUTHORIZED FOR FOCUSED PRE-IMPLEMENTATION AUDIT — IMPLEMENTATION
  NOT STARTED;
- no V1-R10.5-C production boundary is frozen by this closure record;
- implementation requires the focused audit and a subsequent Architect
  production-boundary freeze;
- Projects domain, data, and persistence semantics remain protected until that
  audit and freeze;
- no R10.5-C production implementation is authorized or performed by this
  documentation closure.

Locked:

- V1-R10.5-D — Profile + User Area;
- V1-R10.5-E — Business + Staff;
- V1-R10.5-F — Encyclopedia Micro-polish;
- V1-R10.6;
- V1-R10.7.

Live state:

- V1-R10.5-A: CLOSED / ACCEPTED;
- V1-R10.5-B: CLOSED / ACCEPTED;
- V1-R10.5-C: CURRENT / AUTHORIZED — PRE-IMPLEMENTATION AUDIT ONLY —
  IMPLEMENTATION NOT STARTED;
- V1-R10.5-D through V1-R10.5-F: LOCKED;
- V1-R10.6 / V1-R10.7: LOCKED.

---

### V1-R10.5-C Authorization Synchronization Record

Record type: CURRENT phase-control / authorization synchronization
(append-only governance note; not a new historical audit record)

Status: ARCHITECT APPROVED / RECORDED

Synchronization baseline: HEAD == origin/main ==
`270c6423090f2f4c7e3a1dba85c4392109902ba7`

Contract:
`docs/architecture/contracts/V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md`
APPENDIX G — V1-R10.5-C PROJECTS PRESENTATION PASS FREEZE

Recorded facts:

- the R10.5-C focused pre-implementation audit is complete;
- the Architect accepted that audit;
- APPENDIX G is frozen and states `IMPLEMENTATION_AUTHORIZED: YES`;
- roadmap phase-control authorization is now
  `V1-R10.5-C CURRENT / AUTHORIZED` with `IMPLEMENTATION_AUTHORIZED: YES`,
  `CONTRACT: FROZEN — APPENDIX G`, and `IMPLEMENTATION: NOT STARTED`;
- the earlier R10.5-B closure-record transition wording and the `Live state`
  block quoted in that record are historical snapshots as of the R10.5-B
  closure baseline. They are NOT current phase control and are NOT rewritten
  by this synchronization. The `CURRENT PHASE CONTROL` section above and this
  record are the current authorization authority for R10.5-C;
- no R10.5-C production implementation has started;
- no production code was changed by this documentation synchronization;
- APPENDIX G was not altered, and the R10.5-C audit is not reopened;
- the frozen production boundary is unchanged and is defined only by APPENDIX G;
- Projects domain, data, persistence, storage keys, routes, shell, checklist,
  calculator, localization, and shared-theme protections remain exactly as
  frozen in APPENDIX G.

Locked:

- V1-R10.5-D — Profile + User Area;
- V1-R10.5-E — Business + Staff;
- V1-R10.5-F — Encyclopedia Micro-polish;
- V1-R10.6;
- V1-R10.7.

Unchanged governance:

- the existing Arabic-only V1 user-facing language decision remains active;
- the existing QA and AI-usage governance remain unchanged.

---

### V1-R10.5-C Formal Closure + V1-R10.5-D Transition Record

Record type: CURRENT phase closure / phase transition
(append-only governance record; no historical record is rewritten)

Slice: V1-R10.5-C — Projects Presentation Pass

Contract: `V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md` APPENDIX G (frozen
implementation boundary, including the G.21 test-gate correction / addendum) and
the append-only APPENDIX H formal-closure record.

Previous status: CURRENT / AUTHORIZED — IMPLEMENTATION_AUTHORIZED: YES —
IMPLEMENTATION NOT STARTED

New status: CLOSED / ACCEPTED

Architect final acceptance: PASS — R10.5-C ACCEPTED

Authority: ChatGPT Architect + Owner Visual Acceptance

Closure baseline: HEAD == origin/main ==
`eb9173086bbfbba4f3efe3073ff464e23fc719a7`

Implementation commit: PENDING OWNER COMMIT — the accepted R10.5-C
implementation remains uncommitted.

Acceptance evidence:

- focused R10.5-C visual gate: 11 PASS / 0 FAIL;
- corrected authoritative Projects regression gate: 333 PASS / 0 FAIL;
- independent focused review: initially CORRECTION REQUIRED within authorized
  scope;
- review findings: HIGH 0; MEDIUM 1; LOW 2;
- targeted post-correction gate: 20 PASS / 0 FAIL;
- Owner visual / UX acceptance: PASS;
- Arabic RTL review: PASS;
- Light / Dark review: PASS;
- no additional technical or visual review is required for R10.5-C.

Corrected findings:

- MEDIUM — hardcoded user-facing failure copy bypassing the Ar/En localization
  SSOT: CORRECTED by using the existing `Ar.errorOccurred` / `En.errorOccurred`
  and existing retry labels, with no localization-file change;
- LOW — missing leading `mounted` guard on the async load entry points:
  CORRECTED in both authorized files with no change to generation, stale-
  completion, or known-good-data behavior.

Remaining deferred LOW observations (non-blocking):

- Project List 1.3 text-scale test coverage;
- decorative state icon scale observation.

Accepted production boundary (unchanged):

- `lib/features/projects/presentation/project_list_screen.dart`;
- `lib/features/tools/presentation/widgets/project_picker_dialog.dart`.

Accepted focused test:

- `test/v1_r10_5c_projects_visual_test.dart`.

Accepted presentation outcomes:

- `CivilAppBar`;
- `CivilSurfaceCard` project rows;
- theme-aware Light / Dark roles;
- Arabic RTL;
- feature-local responsive gutters;
- approximately 760 dp readable width;
- loading / valid empty / failure / retry distinction;
- known-good project data preserved on later reload failure;
- safe async generation and mounted handling;
- `ProjectPicker` loading / success / empty / failure / retry states;
- no raw exception text.

Protected semantics confirmed:

- Projects domain unchanged;
- Projects data / persistence unchanged;
- project IDs / schema / ordering unchanged;
- create, rename, archive, restore, and delete semantics unchanged;
- `LocalChecklistRepository.clearProject(project.id)` cleanup ordering
  preserved;
- `ChecklistScreen(project: project)` exact association preserved;
- `ProjectPicker` active-only filtering and exact `Project` return preserved;
- routes and application shell unchanged;
- storage keys unchanged;
- localization files unchanged;
- shared theme / widget files unchanged;
- R10.5-D+ implementation untouched.

Next-slice transition:

- V1-R10.5-D — Profile + User Area Presentation Pass:
  CURRENT / AUTHORIZED — PRE-IMPLEMENTATION AUDIT ONLY;
- implementation authorization: NO;
- implementation: NOT STARTED;
- no R10.5-D production boundary, file list, or implementation detail is frozen
  by this record, and none may be invented;
- the next authorized task is the focused pre-implementation audit only.

Locked:

- V1-R10.5-E — Business + Staff;
- V1-R10.5-F — Encyclopedia Micro-polish;
- V1-R10.6;
- V1-R10.7.

Unchanged governance:

- V1 user-facing language: ARABIC-ONLY;
- English switch: DISABLED;
- Owner manual QA: subjective UI / UX acceptance by default;
- programmatic behavior: agent / automated verification by default;
- AI execution: highest reliable quality with lowest reasonable usage.

Protected dirty baseline — DO NOT touch:

- `test/a5_6_profile_bootstrap_test.dart`;
- `test/v1_r08_cloud_profile_foundation_test.dart`;
- `test/v1_r08_profile_edit_screen_widget_test.dart`;
- `OpenCode_Usage_Report.txt`;
- `artifacts/`.

This closure documentation task does not alter the uncommitted accepted R10.5-C
implementation and does not stage, commit, push, restore, reset, or clean.

# COMMERCIAL TRACK HISTORICAL M3 AUTHORIZATION

```text
COMMERCIAL_TRACK: ACTIVE
COMMERCIAL_CURRENT_SLICE: M3 — Entitlement Evaluator + Shadow
COMMERCIAL_CONTRACT: docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_M3_ENTITLEMENT_EVALUATOR_SHADOW_IMPLEMENTATION_CONTRACT_V1.md
CONTRACT_STATE: ACCEPTED / FROZEN
CONTRACT_COMMIT: f348e0609300858073e8a5143f685fef04362b6b
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES
AUTHORIZED_DATE: 2026-10-04
PUBLIC_BEHAVIOR_DELTA: ZERO
```

Authority: Owner + ChatGPT Architect. M1b is CLOSED / IMPLEMENTED / INDEPENDENTLY ACCEPTED / COMMITTED / PUSHED at `dcc736ba7a8dc0b068f6c8bfc11b74566ab756dc`. The accepted M3 contract is committed at the CONTRACT_COMMIT above.

This distinct commercial backend track runs in parallel with the existing UI control. UI CURRENT remains R10.5-D — Profile + User Area, CURRENT / AUTHORIZED — PRE-IMPLEMENTATION AUDIT ONLY, implementation NO / NOT STARTED. R10.5-D implementation, R10.5-E, R10.5-F, R10.6 and R10.7 remain LOCKED. The existing UI current-phase control is unchanged.

This record supplies the separately required commercial implementation authorization under Frozen Commercial Model §33.2 and accepted M3 §§31/34.2. The M3 contract's internal `IMPLEMENTATION_AUTHORIZED: NO` means **contract acceptance alone did not authorize execution**; its acceptance-time metadata remains unchanged. Execution becomes authorized only after the Owner commits this roadmap/control record. The implementation agent must begin from that committed governance baseline. This governance/static-compatibility pass performs NO M3 implementation.

Authorization applies ONLY to accepted M3: **INTERNAL EVALUATOR + SHADOW ONLY**, two private shadow tables and four internal functions, with **USER-VISIBLE DELTA = ZERO**. The [accepted M3 contract](contracts/CIVILPEDIA_COMMERCIAL_M3_ENTITLEMENT_EVALUATOR_SHADOW_IMPLEMENTATION_CONTRACT_V1.md), especially §§27–29, is the canonical detailed file/object/data/test-gate authority. All its preflight, checkpoint/composed-phase and focused SQL/security/API/atomicity obligations remain mandatory; this source gate does not discharge runtime evidence.

Expected NEW future implementation family — not created by this pass:

| Future path | Accepted boundary |
| --- | --- |
| supabase/migrations/00025_commercial_entitlement_evaluator_shadow.sql | Additive empty M3 evaluator/shadow infrastructure only; verify the free migration prefix before execution. |
| supabase/tests/commercial_m3_entitlement_evaluator_shadow_test.sql | Accepted focused SQL/pgTAP, security/composed-phase and rollback-fixture gates only. |
| test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart | Accepted focused M3 source/inventory/semantic gate only. |

Potential compatibility edits are limited to the exact paths and assertion boundaries permitted by accepted M3 §§27.2/29, only when mechanically required: `test/commercial_m1b_catalog_reference_data_migration_test.dart` and `test/commercial_harden1_public_plans_exposure_migration_test.dart`. Preserve historical checkpoints, unrelated-file protection and every security/catalog assertion. Any further path requires an explicit exact contract-boundary amendment; no wildcard repository edit is authorized. M1b static reconciliation remains deferred to the separately authorized M3 implementation compatibility pass.

This authorization excludes M4, M5, payment implementation, purchased production terms, production grants, real Launch Partner allocations, Founding allocations, publication cutover, Directory visibility change, lifecycle semantics change, Flutter UI change, cache authority change, public commercial API, worker/scheduler, public projection, OQ-84 decision, Profile/User Area implementation and later UI roadmap slices. No public behavior or commercial policy changes; staging, commit and push remain Owner-controlled and are not authorized by this record.

# COMMERCIAL TRACK CURRENT CONTROL

## M3 Formal Slice Closure — 2026-10-04

```text
COMMERCIAL_TRACK: ACTIVE
COMMERCIAL_LAST_CLOSED_SLICE: M3 — Entitlement Evaluator + Shadow
COMMERCIAL_CURRENT_SLICE: NONE — NEXT SLICE REQUIRES SEPARATE ARCHITECT AUTHORIZATION
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
COMMERCIAL_CONTRACT: docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_M3_ENTITLEMENT_EVALUATOR_SHADOW_IMPLEMENTATION_CONTRACT_V1.md
CONTRACT_STATE: ACCEPTED / FROZEN
CONTRACT_COMMIT: f348e0609300858073e8a5143f685fef04362b6b
M3_STATE: CLOSED
M3_IMPLEMENTATION_COMMIT: 8103b551813715feaa1c2b8b3e2b198ae44d75af
M3_ARCHITECT_ACCEPTANCE: ACCEPTED — 2026-10-04
M3_INDEPENDENT_REVIEW: A — READY FOR ARCHITECT ACCEPTANCE
M3_PUBLIC_BEHAVIOR_DELTA: ZERO
PUBLIC_BEHAVIOR_DELTA: ZERO
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
```

Authority: Owner-provided ChatGPT Architect implementation acceptance and formal closure decision.

This is the current commercial control and supersedes the active-slice meaning of the historical M3 authorization record above. That record's authorization, acceptance-time contract metadata and implementation boundary remain historical facts. COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO applies to every NEXT commercial slice after M3 closure; it does not revoke or rewrite M3's prior authorization.

M3 chronology: authorized → implemented → independently reviewed → Architect accepted → committed → CLOSED.

The governance authorization was committed before implementation at `611f2dd30a32b730fc254a247dd4701a98e8b4f6`. The accepted/frozen contract and committed §35 clarification at `7d1d671e7b837be8b1ffed55116aa495d4922eb5` remain unchanged. The accepted M3 implementation is committed at the exact M3_IMPLEMENTATION_COMMIT above. This closure does not reopen the contract or implementation.

### Final M3 acceptance evidence

The final independent focused implementation re-review verdict is **A — M3 IMPLEMENTATION READY FOR ARCHITECT ACCEPTANCE**. Architect implementation decision: **ACCEPTED — 2026-10-04**.

| Focused gate / invariant | Final accepted evidence |
| --- | --- |
| M3 SQL | 1725 / 1725 PASS |
| M3 Dart | 13 / 13 PASS |
| Composed commercial static | 66 PASS |
| Focused regressions | 268 PASS |
| M1a predecessor SQL | 719 / 719 PASS |
| HARDEN-1 predecessor SQL | 346 / 346 PASS |
| M1b predecessor SQL | 378 / 378 PASS |
| Security / ACL / HTTP | PASS |
| Concurrency / replay | PASS |
| Migration atomicity | PASS |
| DB lint | 0 errors; 141 reviewed warnings |
| Canonical M1b reference data | Exact preservation: 4 plans / 4 plan_versions / 4 bundles / 19 bundle_items / 9 term_prices |
| M3 runtime inventory | 2 M3 tables / 4 M3 functions / 4 M3-added indexes |
| Final shadow state | m3_shadow_heads and m3_shadow_runs empty |
| Public behavior delta | ZERO |

Final independent findings: **CRITICAL 0 / HIGH 0 / MEDIUM 0 / LOW 0 / INFO 2**.

INFO observations retained, neither a closure blocker:

- 141 reviewed PostgreSQL volatility warnings, with no accepted correctness blocker.
- Earlier non-reproduced PostgreSQL backend crashes, with unproven root cause and no reproduced M3 fault.

These are accepted review evidence, not new runtime results produced by this documentary closure. The post-shutdown finalization recreated canonical local 00025 state and independently reconfirmed the M3 SQL/Dart gates, inventory, empty shadow/fixture state and exact M1b preservation.

### Next-slice and carry-forward boundaries

**M4 — reviewed row classification / linking: NOT AUTHORIZED.** No M4 contract, migration, SQL, legacy reconciliation, row classification, purchased-term linkage, IQD conversion or publication cutover is created or authorized. M5 and new commercial runtime behavior remain NOT AUTHORIZED. A next commercial slice requires a separate Architect authorization and frozen scope.

M3 closure does not resolve or waive:

- M4 evidence-backed legacy row classification/linking;
- numeric(12,2) → canonical integer-IQD conversion and rounding rule;
- the known 00020 entity-lock/authorization issue for future integration work;
- PRE-M5-PROJECTION-AUTHORITY-GENERATION-RECONCILIATION;
- OQ-84, which remains unresolved;
- future production authority providers;
- future persistent publication projection;
- M5 cutover.

The UI track is unchanged: R10.5-D remains CURRENT / AUTHORIZED — PRE-IMPLEMENTATION AUDIT ONLY, implementation NO / NOT STARTED, with no frozen production boundary. R10.5-D implementation, R10.5-E, R10.5-F, R10.6 and R10.7 remain LOCKED.

This formal closure changes documentary control and exact static compatibility only. No production SQL, migration, Supabase configuration, Flutter implementation, contract, commercial policy or public behavior changes. Staging, commit and push remain Owner-controlled and are not authorized by this closure.

# COMMERCIAL CUI-1 IMPLEMENTATION AUTHORIZATION — 2026-10-05

## Current Commercial Track Control

```text
COMMERCIAL_TRACK: ACTIVE
COMMERCIAL_LAST_CLOSED_SLICE: M3 — Entitlement Evaluator + Shadow
COMMERCIAL_CURRENT_SLICE: CUI-1 — Commercial Business Experience Foundation
COMMERCIAL_CONTRACT: docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md
CONTRACT_STATE: ACCEPTED / FROZEN
CONTRACT_COMMIT: 889ff1da4389ba891247cfb5497554ca98fa58b3
CUI1_PREIMPLEMENTATION_BASELINE_COMMIT: 47096d45b98853af97ab5f3333b1b62b045dad81
CUI1_PREIMPLEMENTATION_BASELINE: 344 PASS / 0 FAIL
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES
AUTHORIZED_DATE: 2026-10-05
PUBLIC_BACKEND_AUTHORITY_DELTA: ZERO
COMMERCIAL_AUTHORITY_DELTA: ZERO
M3_STATE: CLOSED
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
IMPLEMENTATION: NOT STARTED
AUTHORIZATION_EFFECTIVE: ONLY AFTER OWNER COMMITS THIS GOVERNANCE RECORD
```

Authority: Owner-provided ChatGPT Architect production implementation authorization. This additive record is the current Commercial Track control and supersedes only the active-slice meaning of the earlier M3 closure control. The historical M3 authorization and closure records, accepted evidence and carry-forward boundaries remain intact. This governance pass performs no production implementation.

The frozen CUI-1 contract at the exact CONTRACT_COMMIT remains unchanged, including `IMPLEMENTATION_AUTHORIZED: NO`: contract acceptance alone never grants execution authority. CUI-1 implementation becomes authorized only after the Owner commits this governance record. The implementer must start from that committed governance baseline and reconfirm the frozen preflight before the first production edit. No implementation may begin during this documentary pass.

The committed pre-implementation correction at the exact CUI1_PREIMPLEMENTATION_BASELINE_COMMIT satisfies the contract's §14.1 committed GREEN prerequisite: the complete twelve-file focused gate passed **344 / 344, 0 FAIL**, with production behavior unchanged. The historical 341 PASS / 3 FAIL is chronology only, not the current baseline and not a waiver. No UI test rerun is performed by this governance record.

### Exact frozen production boundary — eight paths

```text
lib/features/directory/presentation/directory_landing_screen.dart
lib/features/directory/presentation/directory_search_screen.dart
lib/features/directory/presentation/directory_provider_card.dart
lib/features/directory/presentation/directory_provider_detail_screen.dart
lib/features/directory/presentation/directory_verification_badge.dart
lib/features/directory/presentation/widgets/directory_sponsored_provider_card.dart
lib/localization/ar.dart
lib/localization/en.dart
```

Only contract §§5–15 presentation is authorized: responsive Directory and public Business identity/detail polish, supplied locations/addresses, existing contacts, local Saved presentation, existing Directory verification, the isolated Sponsored seam, generic “إدارة أعمالي” entry, neutral commercial information and Arabic-first responsive polish. No new data authority. A ninth production file requires STOP. Any provider/domain/repository change requires STOP and a separate Architect-authorized authority/data slice.

### Exact frozen implementation test boundary — six paths

```text
test/commercial_cui1_business_experience_foundation_widget_test.dart (new)
test/w5_2_directory_landing_test.dart
test/w5_3_directory_search_screen_test.dart
test/w5_4_directory_provider_card_test.dart
test/w5_4_directory_provider_detail_screen_test.dart
test/w5_5_verification_display_test.dart
```

These tests are limited to frozen CUI-1 assertions after the committed authorization. The corrected `test/w7_2_directory_sponsored_search_screen_test.dart` and `test/v1_r09_p2_b_directory_ux_test.dart` are read-only regressions during production implementation; their separate harness-correction authorization is completed, not renewed. All other files remain read-only unless separately authorized. The contract's focused regression and executable visual-QA obligations remain mandatory; a source/static gate is not visual or runtime acceptance.

### Authority separations and exclusions

- Existing Directory Verification ≠ Commercial Verification V1.
- Sponsored ≠ Verified; Paid ≠ Verified ≠ Sponsored.
- Directory Location ≠ Commercial Branch.
- Saved ≠ Ownership.
- Claim ≠ Management authority; public entity ID ≠ Management authority.
- Commercial information shell ≠ catalog authority.

M4 and M5 remain NOT AUTHORIZED. No payments, subscription/plan purchase, upgrade/downgrade, commercial entitlement decisions, Commercial Verification V1 authority, Sponsored purchase/eligibility authority, commercial lifecycle authority, Branch authority/quotas, team quotas, ownership transfer, invitations, Launch Partner allocation or Founding allocation. No backend, SQL/migration, provider/domain/repository, route addition, DI, search/ranking, publication eligibility, Profile/User Area redesign or Business editor redesign. No M4 contract/migration, legacy classification/linking, IQD conversion, projection authority or publication cutover. The frozen contract's remaining exclusions and unresolved carry-forward continue unchanged.

The ordinary V1-R10 track is unchanged: R10.5-D remains CURRENT / AUTHORIZED FOR PRE-IMPLEMENTATION AUDIT ONLY, `IMPLEMENTATION_AUTHORIZED: NO`, implementation NOT STARTED. R10.5-E, R10.5-F, R10.6 and R10.7 remain LOCKED. CUI-1 is a separate Commercial UI track; its authorization grants no ordinary UI-track advancement.

This pass changes documentary governance and exact static compatibility only. No lib implementation, production localization, backend, SQL, migration or Supabase change. The frozen contracts and protected dirty baseline remain untouched. Staging, commit and push remain Owner-controlled and are not authorized by this record.

# COMMERCIAL CUI-1 MEDIA AUTHORITY RECONCILIATION — 2026-10-06

## Current CUI-1 media control — additive narrow exception

```text
COMMERCIAL_TRACK: ACTIVE
COMMERCIAL_LAST_CLOSED_SLICE: M3 — Entitlement Evaluator + Shadow
COMMERCIAL_CURRENT_SLICE: CUI-1 — Commercial Business Experience Foundation
COMMERCIAL_CONTRACT: docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md
CONTRACT_STATE: ACCEPTED / FROZEN — HISTORICAL CONTRACT PRESERVED
CUI1_MEDIA_ADDENDUM: docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_AUTHORITATIVE_MEDIA_ADDENDUM_V1.md
MEDIA_ADDENDUM_STATUS: ACCEPTED — CANONICAL CUI-1 MEDIA AUTHORITY ADDENDUM
MEDIA_ARCHITECT_ACCEPTANCE: ACCEPTED — 2026-10-06
MEDIA_FREEZE_STATE: FROZEN — CUI-1 AUTHORITATIVE MEDIA DELTA ONLY
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES — BOUNDED CUI-1 CORRECTION ONLY
CUI1_OWNER_VISUAL_QA: PASS / ACCEPTED
CUI1_INDEPENDENT_REVIEW: CONTRACT / MEDIA AUTHORITY CONFLICT IDENTIFIED — CORRECTION AND RE-REVIEW REQUIRED
CUI1_STATE: NOT CLOSED
CUI1_IMPLEMENTATION_CORRECTION: REQUIRED
PUBLIC_BACKEND_AUTHORITY_DELTA: ZERO
COMMERCIAL_AUTHORITY_DELTA: ZERO
M3_STATE: CLOSED
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO
CURRENT_PASS: ARCHITECTURE / GOVERNANCE ONLY — NO PRODUCTION OR TEST IMPLEMENTATION
```

Authority: Owner-provided Architect media-authority reconciliation instruction. The Owner confirms PASS / ACCEPTED visual intent for Business Detail with authoritative cover, logo/avatar and gallery, plus honest no-media fallback. Independent review, as recorded by that instruction, identified conflict with the frozen CUI-1 contract's older “No media loading in CUI-1” restriction and corresponding media/placeholder clauses.

The [Authoritative Media Addendum V1](contracts/CIVILPEDIA_COMMERCIAL_CUI1_AUTHORITATIVE_MEDIA_ADDENDUM_V1.md) is now the controlling narrow authority for that point. It supersedes only the blanket no-loading/media-deferral boundary to allow cover, logo/avatar and gallery thumbnails from existing authoritative typed Directory media fields, after HTTPS validation. No invented production URLs, fake/generated company media, QA fixture leakage or placeholder pretending to be real branding. Absent/invalid/unavailable media retains a neutral hero/type-icon avatar and omitted unavailable gallery. Media never implies verification, ownership, Sponsored, paid entitlement or Commercial Verification V1, and never changes organic search ranking.

The original frozen contract and all previous roadmap bytes remain historical records, including their acceptance-time status and prerequisites. All non-media requirements remain active. This record does not amend responsive geometry, categories/services copy or other independent-review points; implementation correction and independent re-review remain required. Owner Visual QA PASS does not close CUI-1 or establish overall contract compliance. No cleanup completion, independent-review PASS or implementation acceptance is asserted here.

The exact eight production paths and six CUI-1 test paths in the preceding authorization/original §13 remain unchanged; no ninth production file is authorized. No backend, SQL/migration, provider/repository/domain, route, DI, global theme, dependency/SDK, commercial static-guard, search/ranking or unrelated UI work is authorized. Tests may prove supplied typed/HTTPS media and honest fallback under the addendum without interpreting the superseded blanket media prohibition as active. The correction regressions remain read-only. Mechanically necessary static/documentary compatibility requires separate exact authorization; no guard is changed in this pass.

M3 remains CLOSED; M4/M5 remain NOT AUTHORIZED; R10.5-D remains CURRENT for audit only / IMPLEMENTATION NO. Later UI locks and unresolved commercial carry-forward remain unchanged. The future Engineering Directory Media System is not broadly activated: uploads, Storage/schema/delivery architecture and new authority providers remain outside this existing-field presentation exception.

This reconciliation is architecture/governance only. It records the supplied narrow correction authority, preserves the accepted visual implementation, and prepares the addendum for Architect review. No production/test implementation, reset/revert/clean, SQL/Supabase operation, staging, commit or push is performed or authorized by this pass. User retains Git ownership.

# COMMERCIAL CUI-1 FINAL CLOSURE — 2026-10-07

## Current Commercial Track Control — CUI-1 closed

```text
COMMERCIAL_TRACK: ACTIVE
COMMERCIAL_LAST_CLOSED_SLICE: CUI-1 — Commercial Business Experience Foundation
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
COMMERCIAL_CONTROL: CUI-1 CLOSED — NO NEXT COMMERCIAL IMPLEMENTATION SLICE AUTHORIZED
COMMERCIAL_CONTRACT: docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md
CONTRACT_STATE: ACCEPTED / FROZEN — HISTORICAL CONTRACT PRESERVED
CONTRACT_COMMIT: 889ff1da4389ba891247cfb5497554ca98fa58b3
CUI1_MEDIA_ADDENDUM: docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_AUTHORITATIVE_MEDIA_ADDENDUM_V1.md
CUI1_MEDIA_ADDENDUM_COMMIT: f94e96c2c510a6cef25f9f491163c5ce4f9320bb
MEDIA_ADDENDUM_STATUS: COMMITTED / CONTROLLING — ACCEPTED FROZEN NARROW MEDIA AUTHORITY
CUI1_IMPLEMENTATION_COMMIT: 47fba3f64581c9a24eefaee18265a437d8c55505
CUI1_IMPLEMENTATION_STATUS: COMMITTED / PUSHED — OWNER CONFIRMED
CUI1_STATE: CLOSED
CUI1_OWNER_VISUAL_QA: PASS / ACCEPTED
CUI1_INDEPENDENT_REVIEW: PASS
INDEPENDENT_FINAL_RE_REVIEW: PASS — READY FOR ARCHITECT ACCEPTANCE
CUI1_ARCHITECT_ACCEPTANCE: ACCEPTED
CUI1_IMPLEMENTATION_CORRECTION: COMPLETE — H1/H2/M1/M2 RESOLVED
PUBLIC_BACKEND_AUTHORITY_DELTA: ZERO
COMMERCIAL_AUTHORITY_DELTA: ZERO
M3_STATE: CLOSED
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO
CURRENT_PASS: GOVERNANCE / CLOSURE DOCUMENTATION ONLY
```

Authority: Owner-provided final CUI-1 closure instruction, recording **Owner Visual QA PASS / ACCEPTED**, **independent final re-review PASS — READY FOR ARCHITECT ACCEPTANCE**, and **Architect Final Acceptance ACCEPTED**. The implementation is committed/pushed at the exact implementation commit above, as confirmed by the Owner; local HEAD and origin/main both match it. This additive record is the current Commercial Track control and supersedes only the active CUI-1 implementation/correction/re-review status in earlier entries. All historical roadmap bytes, the original frozen contract and the committed authoritative media addendum remain intact. This is a documentary record of supplied acceptance, not agent self-acceptance or new runtime verification.

The [CUI-1 Closure Record](reports/CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_CLOSURE.md) records the exact accepted scope: **eight production files, six implementation-test files and three commercial static guards**. The final implementation commit contains exactly those 17 paths. No backend, SQL/migration, provider, repository, domain, routes, DI, global theme, dependency/SDK, publication-authority or entitlement-authority delta occurred. The media addendum remains controlling only for validated HTTPS cover, logo/avatar and gallery from existing authoritative typed Directory media, with honest absent/invalid/unavailable fallback; no broader media system or new data authority is activated.

### Final accepted gates and findings

| Accepted final gate | PASS | FAIL | SKIP |
| --- | ---: | ---: | ---: |
| CUI focused, CUI1_CAIRO_FONT_DIR unset | 357 | 0 | 0 |
| Modified Directory | 163 | 0 | 0 |
| Full frozen twelve-file baseline | 344 | 0 | 0 |
| Sponsored read-only regressions | 23 | 0 | 0 |
| Saved read-only regressions | 25 | 0 | 0 |
| Commercial static | 91 | 0 | 0 |

Commercial static breakdown: **HARDEN-1 18 PASS / M1a 24 PASS / M1b 21 PASS / M3 28 PASS**. These overlapping gates are accepted implementation/re-review evidence, not new runs in this documentation-only pass or a summed unique suite count.

Prior findings **H1 / H2 / M1 / M2: RESOLVED**. Final independent counts: **CRITICAL 0 / HIGH 0 / MEDIUM 0 / LOW 0**. Remaining INFO only: known Flutter 3.32.8 / Dart 3.8.1 SDK analyzer crash, `Bad state: No definition of type Enum` / `LibraryCycleLinkException`, independently classified as SDK/tooling rather than a repository-source defect. No SDK modification occurred; bounded source verification and focused compile/test gates remained green. This INFO is not an unresolved CUI-1 blocker.

### Authority separations and next-slice control

- Directory Verification ≠ Commercial Verification V1.
- Sponsored ≠ Verified; Paid ≠ Verified ≠ Sponsored.
- Location ≠ Commercial Branch.
- Saved ≠ Ownership.
- Public entity ID ≠ Management authority; Claim ≠ Management authority.
- Commercial information shell ≠ Catalog authority.
- Media ≠ Verification ≠ Ownership ≠ Sponsored ≠ Paid.

**CUI-1 CLOSED — NO NEXT COMMERCIAL IMPLEMENTATION SLICE AUTHORIZED.** M3 remains CLOSED; M4 and M5 remain NOT AUTHORIZED. No next commercial slice is created, promoted or authorized. Existing unresolved commercial carry-forward, including classification/linking, integer-IQD conversion, the known 00020 issue, projection-authority reconciliation, OQ-84, future authority providers, persistent publication projection and M5 cutover, remains unchanged. A future commercial implementation requires separate governing authorization and frozen scope.

The ordinary V1-R10 track is unchanged: R10.5-D remains CURRENT for pre-implementation audit only, `IMPLEMENTATION_AUTHORIZED: NO`, implementation NOT STARTED. R10.5-E, R10.5-F, R10.6 and R10.7 remain LOCKED. CUI-1 closure grants no ordinary UI-track advancement.

This closure pass changes only governance/closure documentation. Production, tests, commercial static guards, frozen contracts, the committed media addendum and protected dirty baseline are preserved. No backend operation, dependency/SDK change, staging, commit or push is performed or authorized. The Owner retains Git ownership; this documentary closure record is prepared for Architect review.

# COMMERCIAL CUI-2A0 CONTRACT ACCEPTANCE + FREEZE — 2026-10-07

## Candidate contract control — implementation not authorized

```text
COMMERCIAL_CANDIDATE_SLICE: CUI-2A0 — Admin Business Draft Authority Foundation
CUI2A0_CONTRACT: docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_ADMIN_BUSINESS_DRAFT_AUTHORITY_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md
CUI2A0_CONTRACT_STATE: ACCEPTED / FROZEN
CUI2A0_ARCHITECT_ACCEPTANCE: ACCEPTED — 2026-10-07
CUI2A0_IMPLEMENTATION_AUTHORIZED: NO
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
CUI1_STATE: CLOSED
M3_STATE: CLOSED
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO
CURRENT_PASS: GOVERNANCE ONLY — CONTRACT ACCEPTANCE / FREEZE RECORD
```

Authority: Owner-provided **CIVILPEDIA — COMMERCIAL CUI-2A0 ARCHITECT CONTRACT ACCEPTANCE + FREEZE RECORD**, recording the supplied Architect decision **ACCEPTED** after review of the corrected contract. The [CUI-2A0 contract](contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_ADMIN_BUSINESS_DRAFT_AUTHORITY_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md) is accepted as the canonical frozen implementation specification. Acceptance/freeze is not agent self-acceptance, implementation acceptance, a new runtime/test PASS or deployed readiness evidence.

CUI-2A0 remains a **CANDIDATE / CONTRACT FROZEN — IMPLEMENTATION NOT YET AUTHORIZED**. COMMERCIAL_CURRENT_SLICE remains NONE; no next commercial implementation slice is activated. No 00026 authorization or next implementation commit placeholder is created. CUI-1 and M3 remain CLOSED; M4/M5 remain NOT AUTHORIZED. The ordinary UI track remains R10.5-D AUDIT-ONLY / IMPLEMENTATION NO; no later UI slice is unlocked. All prior roadmap bytes and historical authorization/closure records remain intact.

### Static compatibility and preimplementation GREEN dependency

Implementation authorization remains blocked on **both**:

1. A narrow, separately and explicitly authorized reconciliation of stale commercial static expectations with the already committed CUI-1 final closure.
2. A fresh focused commercial static baseline **GREEN**.

This dependency is **NOT RESOLVED** by contract acceptance. No static guard is edited and no test is run in this freeze pass; historical CUI-1 evidence is not a fresh preimplementation gate. Subsequent explicit implementation authorization is required after those gates. This record itself authorizes no compatibility implementation, SQL/migration, lib/test/supabase change, provisioning or deployment. Frozen technical clauses and exclusions remain unchanged; production readiness remains a later separate gate.

This pass changes only the contract's acceptance/status metadata and acceptance record, plus this governance-only roadmap append. Protected baseline, production, tests, SQL and all other files remain untouched. Staging, commit and push remain User-controlled and are neither performed nor authorized here.

# COMMERCIAL CUI-2A0 IMPLEMENTATION AUTHORIZATION — 2026-10-07

## Current Commercial Track Control — bounded CUI-2A0 implementation authorized

```text
COMMERCIAL_TRACK: ACTIVE
COMMERCIAL_CONTRACT: docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_ADMIN_BUSINESS_DRAFT_AUTHORITY_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md
CUI2A0_CONTRACT_STATE: ACCEPTED / FROZEN
CUI2A0_CONTRACT_FREEZE_COMMIT: c60dbdda61bd656e281902b452ad937e14aa8c78
STATIC_COMPATIBILITY_GATE: GREEN / ACCEPTED
STATIC_COMPATIBILITY_COMMIT: 1031bfd00135e8891dc25164d222daa892f4e3c1
CUI2A0_IMPLEMENTATION_AUTHORIZED: YES
COMMERCIAL_CURRENT_SLICE: CUI-2A0 — Admin Business Draft Authority Foundation
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES — CUI-2A0 ONLY
CUI2A0_IMPLEMENTATION_STATE: NOT STARTED
AUTHORIZED_MIGRATION: 00026_commercial_admin_business_draft_foundation.sql
CUI1_STATE: CLOSED
M3_STATE: CLOSED
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO
CUI2A1_STATE: NOT AUTHORIZED
PUBLICATION_AUTHORITY_DELTA: ZERO
ENTITLEMENT_AUTHORITY_DELTA: ZERO
PAYMENT_AUTHORITY_DELTA: ZERO
UI_AUTHORITY_DELTA: ZERO
CURRENT_PASS: GOVERNANCE ONLY — IMPLEMENTATION AUTHORIZATION RECORD
```

Authority: Owner-provided **CIVILPEDIA — COMMERCIAL CUI-2A0 IMPLEMENTATION AUTHORIZATION GOVERNANCE RECORD**, supplying the Architect's separate decision to authorize implementation strictly within the [accepted frozen CUI-2A0 contract](contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_ADMIN_BUSINESS_DRAFT_AUTHORITY_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md). This records that supplied decision; it is not agent self-acceptance, implementation completion, deployment acceptance or production/live readiness.

### Chronology and controlling authorization

1. The contract was accepted/frozen at `c60dbdda61bd656e281902b452ad937e14aa8c78`. Contract acceptance alone did not authorize implementation.
2. The required preimplementation static compatibility prerequisite was completed and accepted at `1031bfd00135e8891dc25164d222daa892f4e3c1`.
3. The Architect now separately authorizes only the frozen CUI-2A0 Admin Business Draft Authority Foundation.

This later roadmap record supersedes the freeze-time **IMPLEMENTATION_AUTHORIZED: NO** only for the bounded CUI-2A0 implementation decision and supplies the current commercial slice/control above. The contract's historical header `IMPLEMENTATION_AUTHORIZED: NO` and the preceding freeze record remain unchanged as acceptance-time history. No frozen technical requirement is expanded, reinterpreted or waived. A later implementation pass must start from this Owner-committed authorization record, recheck its exact committed governance baseline and satisfy the frozen preflight/STOP requirements before any implementation edit.

### Accepted static GREEN prerequisite

The Owner-supplied accepted evidence records **Big Pickle focused verification: PASS** and **Kimi independent adversarial review: PASS**. The authoritative static-gate fact is that **all four focused commercial guard files pass with zero failures** at the STATIC_COMPATIBILITY_COMMIT above:

| Focused guard | Accepted state |
| --- | --- |
| M1a — commercial_m1a_private_catalog_migration_test.dart | GREEN / unchanged |
| HARDEN-1 — commercial_harden1_public_plans_exposure_migration_test.dart | GREEN |
| M1b — commercial_m1b_catalog_reference_data_migration_test.dart | GREEN |
| M3 — commercial_m3_entitlement_evaluator_shadow_migration_test.dart | GREEN |

Runner-count semantics are not an authority condition. This record persists the supplied accepted preimplementation evidence; no review or test is rerun in this governance pass, and no post-authorization or post-implementation GREEN result is asserted here.

### Exact future implementation boundary

Implementation must conform exactly to the frozen contract, including its private receipt namespace/table and helpers, four granular staff permissions, six public A0 RPCs, narrow replacement/hardening of the canonical CLAIM guard with preserved trigger binding and non-A0 CLAIM/NEW behavior, exact ACL/RLS/security-definer rules, and mandatory backend/static/security/concurrency evidence. CUI-2A0 remains **DRAFT-ONLY staff authority**: canonical Business identity, ownerless non-public Drafts, the frozen four authoring types and complete-location eligibility rules. Public discoverability/publication authority remains unchanged.

The exact future seven-file implementation/test boundary is frozen §19:

```text
supabase/migrations/00026_commercial_admin_business_draft_foundation.sql
supabase/tests/commercial_cui2a0_admin_business_draft_foundation_test.sql
test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
test/commercial_m1a_private_catalog_migration_test.dart
test/commercial_harden1_public_plans_exposure_migration_test.dart
test/commercial_m1b_catalog_reference_data_migration_test.dart
test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart
```

Existing-guard edits are permitted only when narrowly and mechanically necessary under the frozen compatibility boundary: recognize this exact separately Owner-committed authorization record, the exact authorized 00026 filename and the bounded A0 delta; preserve historical pins, migrations 00001–00025 and all retained security/catalog/authority checks and negative protections. No fifth existing guard, extra runner/implementation file, arbitrary future append or migration is authorized. Any scope expansion requires a new Architect decision and exact contract-boundary addendum.

### Preserved exclusions and execution status

Still NOT AUTHORIZED: M4; M5; publication entitlement; subscription-enforcement expansion; payment or Sponsored implementation; public Claim CTA; Business Center ownership/invitation workflow; CUI-2A1 Admin Draft Console UI; R10.5-D implementation; Branch system; media management system; production Flutter UI; ownership redesign; a second Business identity table or owner_id shortcut; arbitrary future migrations, including 00027+; or entitlement/publication authority beyond the already closed M3 shadow state. CUI-1 and M3 remain CLOSED; all existing unresolved policy/carry-forward and later UI locks remain unchanged.

**This is implementation authorization, not implementation completion.** Migration inventory at this governance pass remains exactly 00001–00025. **00026 remains absent until a later implementation pass.** No SQL, migration, Supabase, Flutter, test, configuration or data implementation occurs here; CUI-2A0 implementation is NOT STARTED. Production readiness remains the contract's separate later gate.

This pass appends only this roadmap governance record and preserves every prior roadmap byte, the frozen contract and the protected dirty baseline. Staging, commit and push remain User-controlled; none is performed or authorized by this governance pass.


# COMMERCIAL CUI-2A0 append_audit_log ACL SECURITY ADDENDUM — 2026-10-07

## Current Commercial Track Control — accepted security addendum, Owner commit required before resume

```text
COMMERCIAL_TRACK: ACTIVE
COMMERCIAL_CONTRACT: docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_ADMIN_BUSINESS_DRAFT_AUTHORITY_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md
CUI2A0_CONTRACT_STATE: ACCEPTED / FROZEN
CUI2A0_SECURITY_ADDENDUM: docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_APPEND_AUDIT_LOG_ACL_SECURITY_ADDENDUM_V1.md
DOCUMENT_STATUS: ACCEPTED — CUI-2A0 SECURITY ADDENDUM
ARCHITECT_ACCEPTANCE: ACCEPTED — 2026-10-07
FREEZE_STATE: FROZEN
ADDENDUM_IMPLEMENTATION_AUTHORIZED: YES — WITHIN CUI-2A0 ONLY
CUI2A0_IMPLEMENTATION_AUTHORIZED: YES
COMMERCIAL_CURRENT_SLICE: CUI-2A0 — Admin Business Draft Authority Foundation
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES — CUI-2A0 ONLY
CUI2A0_IMPLEMENTATION_STATE: PARTIAL / UNACCEPTED — SECURITY-BLOCKED
CUI2A0_EXECUTION_STATE: BLOCKED — PREDECESSOR SECURITY ACL DISCREPANCY
CUI2A0_SECURITY_STOP: ACCEPTED AS CORRECT
CUI2A0_PREDECESSOR_ACL_FINDING: HIGH / CONFIRMED
CUI2A0_SECURITY_STRATEGY: STRATEGY 1 — ACL CORRECTION INSIDE AUTHORIZED MIGRATION 00026
IMPLEMENTATION_RESUME_GATE: OWNER COMMIT OF SECURITY ADDENDUM AND THIS ROADMAP RECORD
AUTHORIZED_MIGRATION: 00026_commercial_admin_business_draft_foundation.sql
MAXIMUM_IMPLEMENTATION_SECURITY_TEST_FILES: 8
CUI2A0_SECURITY_REGRESSION_SUPPORT: test/v1_r09q_security_matrix_test.dart
PREDECESSOR_MIGRATION_CHAIN: VULNERABLE — CONFIRMED LOCALLY ON FRESH 00001–00025 BUILD
REMOTE_DEPLOYED_DATABASE: UNVERIFIED
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
CURRENT_PASS: GOVERNANCE ONLY — SECURITY ADDENDUM RECORD / NO IMPLEMENTATION
```

Authority: Owner-provided **CIVILPEDIA — CUI-2A0 append_audit_log ACL SECURITY ADDENDUM — GOVERNANCE-ONLY PASS**, supplying the Architect's accepted forensic finding, acceptance of the Codex STOP as correct and the exact narrow security decision. The [ACL Security Addendum V1](contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_APPEND_AUDIT_LOG_ACL_SECURITY_ADDENDUM_V1.md) records that supplied ACCEPTED / FROZEN decision. This is not agent self-acceptance, a newly executed forensic review/test PASS, implementation acceptance or deployed readiness.

### Confirmed predecessor discrepancy and exact correction authority

The supplied independent forensic review confirms a **HIGH** predecessor discrepancy: a fresh database built from committed migrations 00001–00025 grants direct EXECUTE on public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text) to anon, authenticated and service_role, while PUBLIC itself does not retain EXECUTE. Both anon and authenticated were independently proven able to directly insert audit events. No legitimate client flow requires direct helper EXECUTE; all legitimate production callers are internal postgres-owned SECURITY DEFINER functions, and direct-client revocation was proven not to break their nested legitimate calls.

**Strategy 1 is selected:** the future authorized 00026 implementation may place exactly the following ACL metadata correction before its security preflight:

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

The ensuing preflight must assert the complete effective ACL: postgres/owner EXECUTE allowed; PUBLIC, anon, authenticated and service_role EXECUTE denied. **No service_role re-grant.** The REVOKE, preflight and all remaining 00026 work must execute in the same migration transaction; any later failure must roll back the ACL correction with the rest of 00026. The permission discrepancy is a specifically reviewed normalization exception only for this exact helper ACL. All other original preflight/STOP requirements remain active.

Function signature, body/prosrc, postgres owner, SECURITY DEFINER state and existing search_path remain unchanged; audit_logs schema remains unchanged. No migration 00016 or any migration 00001–00025 edit, helper replacement, new helper or parallel audit path is authorized. The original frozen contract remains byte-identical; the addendum supplements only its narrowly affected ACL/preflight and file/evidence requirements.

### Implementation gate and exact expanded boundary

CUI-2A0 remains ACTIVE / IMPLEMENTATION AUTHORIZED — CUI-2A0 ONLY, with the partial implementation unaccepted and execution **security-blocked until this addendum and roadmap record are Owner-committed**. After that commit, a later implementation pass may resume under the original frozen contract plus this addendum, rechecking the committed baseline and retained preflight gates. No future commit hash is invented and no implementation is resumed in this governance pass.

The maximum authorized implementation/security/test boundary becomes **eight files**, adding only test/v1_r09q_security_matrix_test.dart as narrowly necessary CUI-2A0 security-regression support:

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

This does not require every path to change. Changes remain permitted only where required by the original frozen contract and addendum. The added security matrix support may correct textual PUBLIC-revoke expectations to complete effective ACL coverage while retaining unrelated protections. Composed commercial guards may recognize only the exact Owner-committed governance/addendum, bounded ACL correction and exact support path; no ninth implementation file, extra migration or production lib change is authorized.

Resumed implementation must prove all addendum ACL-01–ACL-14 requirements: complete principal/effective ACLs, unauthorized direct-call 42501 denials with no forged audit event, owner access, preserved legitimate nested SECURITY DEFINER auditing, mutation rollback on audit failure, unchanged function metadata/body and predecessor bytes. It must also prove migration failure rolls back the ACL correction itself. All original T01–T34 / T32A–H requirements remain mandatory; this governance record supplies no replacement runtime evidence.

### Deferred findings, remote status and preserved exclusions

Broader public-schema default-privilege remediation remains deferred: future postgres-created public functions may inherit client EXECUTE. Legacy sibling RPC ACL permissiveness from 00016 and region_preferences direct INSERT ACL, with RLS currently providing the effective deny, also remain separately deferred. No ALTER DEFAULT PRIVILEGES IN SCHEMA public correction, sibling RPC ACL change or region_preferences ACL/RLS change is authorized under this addendum or CUI-2A0.

**REMOTE DEPLOYED DATABASE: UNVERIFIED.** No remote production connection or remediation is authorized. Confirmed local predecessor vulnerability is not a deployed-state assertion.

M4, M5 and CUI-2A1 remain NOT AUTHORIZED; publication, entitlement, payment and UI authority deltas remain ZERO. CUI-1 and M3 remain CLOSED; R10.5-D remains AUDIT-ONLY / IMPLEMENTATION NO. No broader commercial scope or ordinary UI-track advancement is created.

This governance pass creates only the addendum and appends only this roadmap record, preserving all prior roadmap bytes and the original frozen contract. Existing partial implementation files/guards, their compilation errors and the protected dirty baseline remain untouched. No 00026/test/SQL/Supabase/lib modification, migration/backend operation, test execution, staging, commit, push, reset, revert, clean or stash is performed. User retains Git ownership; implementation remains blocked pending the Owner's addendum commit.


# COMMERCIAL CUI-2A0 FINAL IMPLEMENTATION CLOSURE — 2026-10-08

## Current Commercial Track Control — CUI-2A0 closed; no next implementation slice authorized

```text
CUI2A0_STATE: CLOSED
CUI2A0_IMPLEMENTATION_STATE: ACCEPTED / CLOSED
CUI2A0_IMPLEMENTATION_COMMIT: 41276132ba6a1606cd779f5ce92473bacfbcc7c8
CUI2A0_CONTRACT_STATE: ACCEPTED / FROZEN
CUI2A0_SECURITY_ADDENDUM: SATISFIED
CUI2A0_ARCHITECT_IMPLEMENTATION_ACCEPTANCE: PASS
CUI2A0_IMPLEMENTATION_AUTHORIZED: NO — SLICE CLOSED
APPEND_AUDIT_LOG_ACL_STATE: ACCEPTED — OWNER-ONLY DIRECT EXECUTE
LOCAL_MIGRATION_CHAIN_IMPLEMENTATION: VERIFIED
REMOTE_DEPLOYED_STATE: UNVERIFIED
REMOTE_DEPLOYED_DATABASE: UNVERIFIED
COMMERCIAL_LAST_CLOSED_SLICE: CUI-2A0 — Admin Business Draft Authority Foundation
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
COMMERCIAL_CONTROL: CUI-2A0 CLOSED — NO NEXT COMMERCIAL IMPLEMENTATION SLICE AUTHORIZED
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
CURRENT_PASS: GOVERNANCE / DOCUMENTATION ONLY — FINAL CLOSURE RECORD
```

Authority: Owner-provided **CIVILPEDIA — COMMERCIAL CUI-2A0 FINAL CLOSURE RECORD + ROADMAP CLOSURE**, supplying completed independent verification and Architect implementation acceptance for commit `41276132ba6a1606cd779f5ce92473bacfbcc7c8`. Local HEAD and local origin/main match that accepted implementation commit. This records the supplied final decision; it is not agent self-acceptance, a new review/test PASS or remote/deployed readiness.

The [CUI-2A0 final closure record](reports/CIVILPEDIA_COMMERCIAL_CUI2A0_ADMIN_BUSINESS_DRAFT_AUTHORITY_FOUNDATION_CLOSURE.md) records **CUI-2A0 CLOSED / IMPLEMENTATION ACCEPTED**, under the [frozen implementation contract](contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_ADMIN_BUSINESS_DRAFT_AUTHORITY_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md) and the [committed ACL Security Addendum](contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_APPEND_AUDIT_LOG_ACL_SECURITY_ADDENDUM_V1.md). The addendum is **SATISFIED**. This latest chronological control supersedes prior active CUI-2A0 implementation/security-blocked status only; all earlier roadmap bytes, frozen contract clauses and historical addendum wording remain intact.

### Accepted scope and security outcome

Accepted implementation: migration 00026; private business_admin_private schema and draft_create_requests receipt; two private helpers; four independent staff permission references; six public CUI-2A0 RPCs; canonical CLAIM guard hardening with preserved trigger; three bounded indexes; ACL/RLS/SECURITY DEFINER hardening; exact append_audit_log ACL correction; SQL runtime evidence; and Dart/static compatibility/security guards. The committed delta contains seven implementation/test paths; M1a is unchanged. No production lib/** or UI delta occurred; entitlement, publication and payment authority deltas remain ZERO.

**append_audit_log ACL: ACCEPTED — OWNER-ONLY DIRECT EXECUTE.** PUBLIC, anon, authenticated and service_role have **NO EXECUTE**; postgres/owner retains **EXECUTE**. The accepted local final ACL is `{postgres=X/postgres}`. The exact REVOKE is part of atomic 00026 before preflight, with no service_role regrant. Helper signature/body/prosrc/owner/SECURITY DEFINER/search_path/return type and audit schema are preserved; legitimate owner-executed audited callers and mutation rollback behavior remain accepted.

### Accepted evidence and non-blocking observations

| Evidence | Accepted outcome |
| --- | --- |
| Codex focused Dart/static, SQL runtime, concurrency/race, genuine local HTTP and migration rollback evidence | GREEN; no production/lib delta |
| Independent Big Pickle verification | PASS — CUI-2A0 IMPLEMENTATION VERIFIED |
| Independent adversarial review | PASS — CUI-2A0 IMPLEMENTATION SAFE TO ACCEPT |
| Architect implementation acceptance | PASS |

These are supplied accepted implementation/review outcomes and preceding implementation evidence, not new executions in this documentary pass. No unconfirmed numeric counts are introduced.

Accepted non-blocking/deferred observations: the audit wrapper may reclassify transaction/deadlock SQLSTATEs such as 40001 / 40P01 to P0AUD while retaining rollback; adversarial review identified minor static-guard coverage limitations without an exploitable authority path. These observations **do not reopen CUI-2A0** and grant no SQL or guard-fix authority here.

### Deferred security, deployment and follow-on controls

Still outside CUI-2A0 closure: Supabase public-schema defaults for future postgres-created public functions; legacy sibling RPC ACL permissiveness; and region_preferences ACL/RLS posture. These were not silently remediated and require future explicit Architect hardening authority.

**LOCAL MIGRATION-CHAIN / IMPLEMENTATION: VERIFIED. REMOTE DEPLOYED DATABASE: UNVERIFIED.** Repository implementation closure and deployment are separate states. No remote production migration, deployment, provisioning or live readiness is implied or performed.

COMMERCIAL_CURRENT_SLICE is **NONE** and COMMERCIAL_IMPLEMENTATION_AUTHORIZED is **NO**, until a later explicit Architect authorization record opens the next slice. M4, M5 and CUI-2A1 remain NOT AUTHORIZED; R10.5-D remains AUDIT-ONLY / IMPLEMENTATION NO. CUI-1 and M3 remain CLOSED. **No next slice is automatically authorized.**

This governance pass creates only the closure report and appends this single chronological roadmap record. Frozen governing documents, implementation/SQL/tests/lib/Supabase, protected dirty files and all prior roadmap bytes are preserved. No implementation, backend operation, migration/test run, staging, commit, push, reset, revert, clean or stash occurs. Staging remains EMPTY and the User retains Git ownership; these closure documents are prepared for Architect verification.


# COMMERCIAL CUI-2A1 CONTRACT ACCEPTANCE + FREEZE — 2026-10-08

## Current Commercial Track Control — contract accepted/frozen; no implementation authorized

```text
COMMERCIAL_CONTRACT: docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A1_ADMIN_BUSINESS_DRAFT_CONSOLE_IMPLEMENTATION_CONTRACT_V1.md
DOCUMENT_STATUS: ACCEPTED — CANONICAL CUI-2A1 IMPLEMENTATION CONTRACT
ARCHITECT_ACCEPTANCE: ACCEPTED — 2026-10-08
FREEZE_STATE: FROZEN
IMPLEMENTATION_AUTHORIZED: NO
CUI2A1_STATE: CONTRACT FROZEN — IMPLEMENTATION NOT AUTHORIZED
CUI2A1_CONTRACT_STATE: ACCEPTED / FROZEN
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
COMMERCIAL_CONTROL: CUI-2A1 CONTRACT FROZEN — NO COMMERCIAL IMPLEMENTATION SLICE AUTHORIZED
CUI2A0_STATE: CLOSED
CUI1_STATE: CLOSED
M3_STATE: CLOSED
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO
BACKEND_AUTHORITY_DELTA: ZERO
PUBLICATION_AUTHORITY_DELTA: ZERO
ENTITLEMENT_AUTHORITY_DELTA: ZERO
PAYMENT_AUTHORITY_DELTA: ZERO
REMOTE_DEPLOYED_DATABASE: UNVERIFIED
CUI2A1_STATIC_COMPATIBILITY_MODIFICATIONS_AUTHORIZED: NO
CUI2A1_PREIMPLEMENTATION_GREEN: NOT CLAIMED — FUTURE SEPARATE GATE
CURRENT_PASS: STRICT GOVERNANCE-ONLY ACCEPTANCE / FREEZE
GIT_OWNER: User
```

Authority: Owner-provided **CIVILPEDIA — CUI-2A1 Final Architect Acceptance + Contract Freeze**, supplying the Architect decision **ACCEPTED — 2026-10-08** and final independent pre-freeze contract review **PASS with zero CRITICAL, HIGH or MEDIUM findings**. This records supplied acceptance; it is not agent self-acceptance, a new independent review/test run, implementation acceptance, static GREEN or deployed-readiness evidence.

The [CUI-2A1 Implementation Contract V1](contracts/CIVILPEDIA_COMMERCIAL_CUI2A1_ADMIN_BUSINESS_DRAFT_CONSOLE_IMPLEMENTATION_CONTRACT_V1.md), current §23, is **ACCEPTED / FROZEN** as the canonical bounded Admin Business Draft Console consumer specification. Contract acceptance/freeze does not authorize implementation. Earlier CUI-2A1 draft/not-authorized status wording is superseded only as to contract maturity; all prior roadmap bytes, CUI-2A0/CUI-1/M3 closures, exclusions and technical/history records remain unchanged. **COMMERCIAL_CURRENT_SLICE is NONE; COMMERCIAL_IMPLEMENTATION_AUTHORIZED is NO. No new implementation slice is activated.**

### Frozen future manifest and preserved authority boundaries

The exact reconciled candidate is now frozen as a future boundary, not a present write allowance:

| Frozen boundary | Paths | NEW | MODIFIED |
| --- | ---: | ---: | ---: |
| Production | 18 | 10 | 8 |
| New focused tests | 6 | 6 | 0 |
| Existing UI tests | 5 | 0 | 5 |
| Separate compatibility guards | 4 | 0 | 4 |
| Total | **33** | **16** | **17** |

All exact production/test paths remain those in the frozen contract §§14–15. The four future compatibility guards are exactly:

```text
test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
test/commercial_harden1_public_plans_exposure_migration_test.dart
test/commercial_m1b_catalog_reference_data_migration_test.dart
test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart
```

Both test/commercial_m1a_private_catalog_migration_test.dart and test/v1_r09q_security_matrix_test.dart remain **READ-ONLY / UNMODIFIED** and mandatory focused preservation regressions. Historical CUI-1, A0, M1a, HARDEN-1, M1b, M3, R09q, ownership, SQL and ACL protections remain intact. No static guard modification is authorized now.

The frozen contract preserves the six accepted A0 RPC mappings; four independent permissions; three authenticated root routes; no-read creation/history/edit handling; exact six-key payloads; immutable create replay and optimistic update/unknown-result reconciliation; actor/session-generation private-state clearance; Draft-only/four-type authoring and primary-location completeness; Arabic/English compatibility and responsive design; narrow User Area navigation exception; and all commercial exclusions. Backend/publication/entitlement/payment authority deltas are ZERO. No new RPC, SQL/migration, production database operation, ownership/invitation, payment/publication/entitlement, M4/M5 or R10.5-D implementation is authorized.

### Separate compatibility, review and GREEN prerequisites

The exact contract §16 gate sequence is preserved unchanged, including strict historical CUI-1/A0 CLOSED predicates and the separately gated AUTHORIZED CUI-2A1 live/current predicate. Future authorized A1 implementation, if later opened, is restricted to the frozen 18 production plus 11 focused/UI-test paths; guard edits belong only to separate authorized four-guard compatibility passes. Positive/adversarial evidence must use the same live/current predicate, with committed authorization and zero A1 production/test changes at the preimplementation gate, and actual resulting committed source identities/exact bounded path set at final implementation acceptance. No nonexistent future implementation hashes are required or fabricated.

After focused independent freeze-diff review and the Owner's governance commit, the next future action is a **SEPARATELY AUTHORIZED compatibility-only governance pass**. Compatibility-only authorization, guard correction, focused GREEN on the four guards plus unchanged M1a/R09q, independent review and Owner compatibility commit remain mandatory and have not occurred for this freeze composition. Separate implementation authorization and both preimplementation/postimplementation focused GREEN remain required before implementation/acceptance, respectively. Contract freeze alone supplies none of those authorities or PASS outcomes.

The current four guards may reject the newly accepted documentation until that future separately authorized compatibility correction. This disclosed **LOW transitional condition** grants no waiver or implementation authority. No guards are changed to obtain GREEN now, no implementation/production/database tests run in this pass, and no GREEN is claimed for the new freeze composition. **REMOTE DEPLOYED DATABASE: UNVERIFIED**; local contract acceptance is not deployment, staff provisioning or live readiness.

### Git and historical preservation

Entry HEAD and local origin/main are both 3f4ce87381ea97b0f3f6a772827c4d77b58aee66. This pass updates acceptance/status governance only in the existing untracked CUI-2A1 contract and appends only this one roadmap section. Every prior roadmap byte and all protected dirty files/artifacts, other contracts/reports, lib/tests/SQL/Supabase are preserved. Staging remains EMPTY; no stage, commit, push, reset, revert, clean or stash. The Owner retains final Git ownership and will commit after focused independent governance review. No future acceptance commit SHA or circular source hash is inserted.


# COMMERCIAL CUI-2A1 STATIC COMPATIBILITY-ONLY AUTHORIZATION — 2026-10-09

```yaml
CUI2A1_STATIC_COMPATIBILITY_MODIFICATIONS_AUTHORIZED: YES — FOUR NAMED GUARDS ONLY
CUI2A1_IMPLEMENTATION_AUTHORIZED: NO
CUI2A1_STATE: CONTRACT FROZEN — IMPLEMENTATION NOT AUTHORIZED
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
CUI2A0_STATE: CLOSED
CUI1_STATE: CLOSED
M3_STATE: CLOSED
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO
BACKEND_AUTHORITY_DELTA: ZERO
PUBLICATION_AUTHORITY_DELTA: ZERO
ENTITLEMENT_AUTHORITY_DELTA: ZERO
PAYMENT_AUTHORITY_DELTA: ZERO
REMOTE_DEPLOYED_DATABASE: UNVERIFIED
IMPLEMENTATION_AUTHORIZED: NO
CURRENT_PASS: STRICT GOVERNANCE-ONLY / ROADMAP APPEND
COMPATIBILITY_EXECUTION_GATE: OWNER COMMIT OF THIS EXACT AUTHORIZATION REQUIRED
FOCUSED_GREEN: NOT CLAIMED — NO TESTS EXECUTED IN THIS PASS
GIT_OWNER: User
```

### Authority and verified committed documentary baseline

Authority: Owner-provided **CIVILPEDIA — CUI-2A1 STATIC COMPATIBILITY AUTHORIZATION — CONTINUATION**, implementing only the frozen CUI-2A1 Contract V1 §16 step 3. The contract remains ACCEPTED / FROZEN. This record authorizes a later, separately performed static-compatibility correction; it performs no guard correction and grants no Flutter, A1 production/UI-test, backend or commercial implementation authority.

| Verified Git input | Actual committed identity |
| --- | --- |
| Accepted/frozen governance commit; entry HEAD and local origin/main | `e767add487034171b0e8512ee6cfc8d56484004e` |
| Frozen contract path | `docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A1_ADMIN_BUSINESS_DRAFT_CONSOLE_IMPLEMENTATION_CONTRACT_V1.md` |
| Frozen contract blob at that commit | `8071f951ff336714c420a5216504d0d49183e055` |
| Roadmap path | `docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md` |
| Roadmap blob at that commit, before this append | `049dfcff25091616d80132c6db9402f095e02c56` |

These identities were derived from local Git objects, not invented or inferred from filenames. The Owner must commit this exact append before guard work. The later implementer must verify the actual committed authorization commit and roadmap blob, the exact append text, every preceding roadmap byte and the frozen contract identity. This pending record is not a committed execution grant. Its future commit/blob identities must be observed after they exist; no self-referential or nonexistent future implementation hash is required.

### Exact later four-guard correction boundary

Permission is limited to compatibility predicates and adversarial probes in exactly these four existing files:

```text
test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
test/commercial_harden1_public_plans_exposure_migration_test.dart
test/commercial_m1b_catalog_reference_data_migration_test.dart
test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart
```

Purpose: recognize only the exact committed frozen CUI-2A1 documentary composition, comprising the verified accepted/frozen contract and roadmap acceptance/freeze record plus this exact committed compatibility authorization, while preserving historical CUI-1/A0/HARDEN-1/M1b/M3 security and authority predicates. The later correction may not rewrite the contract, roadmap, other documentation, SQL/Supabase, production sources or any other test. The frozen 33-path manifest, API contracts, technical design, permissions and commercial scope remain unchanged.

These two preservation suites remain **READ-ONLY / UNMODIFIED**, outside the correction allowlist:

```text
test/commercial_m1a_private_catalog_migration_test.dart
test/v1_r09q_security_matrix_test.dart
```

### Mandatory later security and independent GREEN gate

Preserve strict historical CUI-1/A0 CLOSED predicates and their exact historical fixtures; all historical source, commit, SQL, ACL, ownership and security pins; the exact migration inventory 00001–00026; and accepted A0 backend behavior. Documentary recognition must be separately bounded to the fixed committed inputs above and the observed committed authorization. Never introduce dynamic HEAD acceptance, broad directory allowlists, arbitrary future-record acceptance or a generic dirty-file exception. Preserve the protected dirty baseline by exact paths and bytes.

Positive and adversarial negative checks must use the same live/current compatibility predicate and branch selection. Reject arbitrary future roadmap suffixes, extra documentation or other paths, A1 Flutter/production/UI-test additions, migration 00027 or any SQL/Supabase delta, changed historical pins, changes to unrelated protected sources, altered/uncommitted authorization, unauthorized contract/roadmap changes and premature CUI-2A1 implementation authorization. Retain historical positive/negative coverage, M1a/R09q protections and every unrelated security assertion. No skipping, weaker test-only predicate or bypass may manufacture GREEN.

The later focused gate must independently execute **all six suites**: each of the four named guards above, unchanged M1a and unchanged R09q. **Zero failures and independent Big Pickle review are mandatory before the Owner commits the guard correction.** Review must accept the exact documentary recognition, adversarial probes and preservation evidence. If this cannot be achieved inside the four-file boundary while M1a/R09q remain unchanged, STOP for independent audit and an exact Architect amendment; do not expand scope.

The currently expected transitional RED state grants no waiver and no implementation authority. No tests are executed or modified in this governance pass, and no GREEN or independent-review PASS is claimed.

### Retained implementation locks and historical preservation

This record satisfies only the separate authorization-record step, subject to Owner commit; it does not complete §16 steps 4–7. The future four-guard correction, focused GREEN, independent review and Owner compatibility commit remain prerequisites. The separately gated AUTHORIZED CUI-2A1 implementation current-composition predicate remains disabled: this record permits no anticipated implementation-YES append or A1 source changes.

A later exact implementation authorization and coordinated four-guard pass under §16 step 6 remain separately required. Both committed preimplementation focused GREEN with zero A1 production/test changes and postimplementation focused GREEN remain mandatory under §§16/22. Only that later authorization may permit the frozen 18 production plus 11 focused/UI-test paths; guard-source changes belong exclusively to separately authorized compatibility passes. Final implementation acceptance must verify actual resulting Owner-committed source identities and the exact bounded path set, without requiring nonexistent future implementation hashes beforehand.

This pass appends only this one roadmap section, preserving all previous roadmap bytes and historical controls, the frozen contract, guards, lib/tests/SQL/Supabase, other documents and protected dirty/untracked files. No stage, commit, push, reset, revert, clean, stash or remote/production database access occurs. Commercial CURRENT remains NONE, implementation remains NO and all authority deltas remain ZERO.

# OWNER PLANNING DIRECTION (2026-10-11)

## Authority, status and preserved execution control

Authority: Owner-provided **CIVILPEDIA — OWNER DECISIONS INTEGRATION / EXISTING ARCHITECTURE DOCUMENTATION UPDATE**. Status: **OWNER PLANNING DIRECTION — DOCUMENTATION UPDATED — OWNER REVIEW REQUIRED**. **IMPLEMENTATION NOT AUTHORIZED BY THIS UPDATE.** This chronological planning entry records the Owner's intended release and long-term direction; it is not Architect acceptance of new contracts, a commercial-policy amendment, a release-readiness PASS or an execution grant.

The existing CURRENT PHASE CONTROL, phase table and commercial controls remain unchanged: R10.5-D is CURRENT for pre-implementation audit only, implementation NO / NOT STARTED; later UI slices remain LOCKED. Commercial CURRENT remains NONE; commercial implementation remains NO. CUI-2A1 remains ACCEPTED / FROZEN — IMPLEMENTATION NOT AUTHORIZED; CUI-2A0, CUI-1 and M3 remain CLOSED; M4/M5 remain NOT AUTHORIZED. The 2026-10-09 four-guard compatibility authorization and frozen CUI-2A1 §16 gates are preserved without expansion. Entry branch is main; observed HEAD is ed9840084eb67b1bb295459b420093a37d8bccbb. Its four-guard compatibility commit is repository evidence only; no fresh GREEN or acceptance outcome is asserted here.

The [Frozen Commercial Model V1](CIVILPEDIA_COMMERCIAL_MODEL_V1.md), especially §§1.5/33, retains commercial-policy authority. Accepted [C1](contracts/CIVILPEDIA_COMMERCIAL_CORE_AUTHORITY_RECONCILIATION_CONTRACT_V1.md), [C2](contracts/CIVILPEDIA_COMMERCIAL_PUBLICATION_ENTITLEMENT_CONTRACT_V1.md) and [C3](contracts/CIVILPEDIA_COMMERCIAL_SUBSCRIPTION_ENTITLEMENT_ENFORCEMENT_CONTRACT_V1.md) retain reconciliation, publication/entitlement and technical architecture authority. Planning here does not alter their rules, registers, acceptance or history. The [Implementation Readiness & Gap Analysis](CIVILPEDIA_IMPLEMENTATION_READINESS_AND_ROADMAP.md), §§23–24/27, carries bounded release/backlog references to this entry; it does not replace this roadmap as phase/status SSOT.

## Full V1 release direction and scope reconciliation

Civilpedia V1 is intended to be a complete, professionally released engineering application with a real commercial Business Directory. Planned release scope includes the engineering encyclopedia, calculators and essential tools, existing core Projects functionality, Business Directory profiles and discovery, commercial subscription capability, authorized business management, and required security/privacy/release quality. A real paid commercial system belongs in this intended release; Directory presentation alone does not establish commercial completion.

Publication requires valid server-side commercial authority and satisfaction of the applicable accepted/frozen entitlement, profile-quality, ownership/onboarding, moderation/verification and launch requirements. Existing entity or subscription active status alone is insufficient. M3 Shadow is not operational publication authority; accepted CUI-1 presentation and CUI-2A0 Draft authoring do not prove production commercial readiness. **Current commercial implementation is not declared production-ready; remote deployed database remains UNVERIFIED.**

Earlier CORE ARCHITECTURE RULES item 17 and POST-V1 BY DEFAULT entries for payments/paid subscriptions/full monetization describe the preceding execution baseline and must not be presented as the current Owner's complete release target. Likewise, the older M8 Wave 7/§27 speculative plan wording and M6 Directory architecture §31's limited V1 scope are earlier planning context. They remain intact. Under SCOPE CHANGE PROTOCOL, the Architect/Owner must reconcile the intended paid Directory scope into separately accepted contracts and authorized execution boundaries before dependent implementation. This entry creates no new phase/slice, changes no CURRENT pointer or gate, and does not promote marketplace, e-commerce, commissions, RFQ, CRM or advanced advertising into V1.

## Android and iOS: one shared authority

The strategic target is **simultaneous public launch on Android / Google Play and iOS / Apple App Store**, using the existing Flutter application architecture where feasible. This is a target, not a guaranteed date or a claim that either platform has passed release acceptance.

Both platforms must consume one authoritative production Supabase backend: one canonical Business UUID per genuine entity; shared Directory records and category data; shared ownership/membership roles; shared subscription/entitlement state; shared publication authority and approved public content; and consistent authorized Business visibility. Preserve directory_entities.id, business_memberships, separation of auth.users.id/personal identity from Business identity, one production Supabase initialization/client authority and one AuthProvider. Independent Android/iOS Business databases, duplicate Business identities or competing subscription authorities are prohibited.

Native UI, build/signing, store compliance and permitted billing behavior may differ by platform. Future contracts and final acceptance must account for those differences while proving the same server authority, Business identity, ownership and commercial publication results. iOS build, dependency/plugin compatibility, physical-device acceptance, signing/provisioning, App Store submission/review and release gates are **PLANNED / UNVERIFIED**. No build/signing/dependency work is authorized here.

## Commercial packages and separate products

The Owner prefers retaining all three standard paid tiers plus negotiated Corporate: **Business**, **Business Pro**, **Business Plus**, **Corporate — Custom Quote**. Preserve frozen prices, durations, capabilities and their existing classifications, catalog identities, reference rows and historical data. Business Pro's frozen primary/default recommendation remains intact. Do not merge/delete tiers or reinterpret the entitlement matrix; provisional values remain provisional and unquotable.

Package differentiation should reflect genuine Business value. Quality profiles, specialized company discovery, approved project/product portfolios, genuine contact-interaction analytics, multiple branches and appropriately authorized management tools are **PRODUCT-DIRECTION CANDIDATES** where not already decided or implemented. They create no new entitlement keys, tier assignments, feature promises, commercial eligibility or implementation requirements. Personal Projects do not become Business portfolios by inference. Commercial expansion requires separate architectural decisions and accepted contracts; excluded professional/specialist categories are not silently enrolled. Paid status never automatically means Verified; organic ranking must not silently become paid ranking.

Preserve four distinct commercial product concepts: Business subscriptions; separately purchased Sponsored Listings/advertising; future Official Civilpedia Sponsorships; and Corporate negotiated services. An eligible subscription may permit a separate Sponsored purchase only under frozen policy; it does not automatically bundle advertising.

**Official Civilpedia Sponsorship is FUTURE PLANNING ONLY.** It may cover independently contracted support/sponsorship of the app, sections, content or campaigns, subject to later policy, disclosure, editorial independence, commercial and legal review. It is not a fifth subscription tier, Verified status, a Sponsored Listing or an automatic Corporate entitlement. No sponsor record, financial table, price schedule, contract, UI, entitlement or advertising implementation is created or authorized.

## Future Product Backlog clarification: RFQ and CRM

Read with the existing Future Product Backlog — Architect Notes and POST-V1 BY DEFAULT sections: **RFQ and CRM are LONG-TERM DEFERRED**, outside V1 release requirements and **not committed V1.1 deliverables**. RFQ means future request-for-quotation/business-opportunity workflows; CRM means future lead/customer-relationship management. The Owner may consider them much later, depending on Business growth and validated customer demand. Earlier M6 §32's V2+ / optional concept is not a delivery commitment.

Preserve only reasonable future extensibility through stable canonical Business UUIDs, separate user/Business identity, defined authorization and modular responsibility boundaries, forward-compatible API/data evolution, and server-authoritative Business-linked entitlements. No RFQ/CRM/opportunity schema, tables, placeholder endpoints, new authorization grants, UI, messaging infrastructure or speculative data models are authorized. Avoid overengineering the present release.

## Payment remains OPEN; frozen policy is preserved

The Owner wants a real paid commercial system, but the final permitted Android/iOS billing and collection architecture is **OPEN — NOT APPROVED**, pending independent Google Play and Apple App Store policy validation, technical validation and qualified legal/accounting review **before billing freeze**. Alternatives under review are external B2B contracting, locally supported Iraqi payment providers, applicable Apple in-app purchasing, applicable Google Play Billing and other officially permitted models. None is selected or certified compliant by this entry.

Commercial entitlements remain server-authoritative and linked to the canonical Business Entity. A payment provider or store platform does not become canonical Business identity or publication authority. WhatsApp payment links inside the app are not assumed automatically compliant, and separation of web/mobile applications is not an assumed exemption from store billing policies. No payment integration, financial grant or publication shortcut is authorized.

The following potential conflicts are recorded for later adjudication, not resolved:

| Candidate change / affected frozen sections | Required disposition |
| --- | --- |
| A chosen store/provider flow replacing the manual/assisted WhatsApp Business payment flow: Commercial Model §§7.1/7.5; automated gateway deferral §21.8 and §33.2.10 | **FORMAL AMENDMENT REQUIRED — NOT AUTHORIZED** if the selected design changes those frozen requirements/classifications. Policy validation alone does not rewrite the model. |
| Auto-renewal, auto-charge or stored instruments: Commercial Model §26.2.1–4 / L-56; C2 §11; A8 §32.2.2.6 | **FORMAL AMENDMENT REQUIRED — NOT AUTHORIZED** for any conflicting design. These are preserved rules, not newly open commercial choices. |
| Different purchased durations, payment/publication term anchors or lifecycle outcomes: Commercial Model §§3.1/26.1–26.2; C2 §§4/10–13; accepted C3 time/publication architecture | **FORMAL AMENDMENT REQUIRED — NOT AUTHORIZED** if a billing proposal cannot preserve them. Provider purchase/receipt events alone cannot redefine the term or publication. |

No amendment is made. Any actual frozen-policy change must follow Commercial Model §§1.5/33.1.10, including the required fresh independent audit and Architect acceptance, then reconcile affected accepted contracts before separate implementation authority. Frozen prices, IQD accounting, independently verified funds, renewal/Grace, A8/Launch Partner and Founding Partner separation, Corporate quotation rules, Baghdad-first launch density, identity/history preservation and no-open-public-CLAIM rules remain unchanged. C1 AR-01 through AR-14 remain OPEN/deferred; this entry resolves none and closes/reclassifies no commercial OQ.

## Release planning and timeline clarification

The planning basis is **FULL V1 + COMMERCIAL DIRECTORY + REAL PAID COMMERCIAL SYSTEM + ANDROID / iOS SIMULTANEOUS LAUNCH TARGET**. There is no evidence-backed committed public launch date. Earlier Android-only or limited-promotion estimates must not be reused as an accepted forecast for this expanded scope. Historical estimates/closure records remain intact; no optimistic, P50 or P80 date is invented.

Future contract/estimate work must include the following in the existing phase context; this is a planning mapping, not new gates, phase authorization or acceptance evidence:

| Existing context | Planning / acceptance coverage still required |
| --- | --- |
| R10–R11 / existing commercial contracts | Complete exposed core experience and Projects; paid subscription implementation, authorized Business management and commercial publication/enforcement through separately authorized slices. |
| R12–R13 | Required human engineering/calculator/content approval and protected draft_jsons authoring pipeline. |
| R14–R15 | One shared Supabase production authority/deployed verification; Auth/RLS/ownership/commercial security; privacy and account deletion, including applicable retention decisions. |
| R16 | Android release build/device acceptance; iOS release build/plugin compatibility, physical-device acceptance and platform performance/configuration — iOS **PLANNED / UNVERIFIED**. |
| R17 | Full Business E2E on both platforms against shared authority: canonical identity/roles, approved paid/promo entitlement, publication/visibility/enforcement, session changes, privacy/account deletion and existing offline/core journeys. No new public CLAIM authorization follows from the historical NEW/CLAIM journey list. |
| R18 | Billing decision and separate store-policy validation; Android signing/Google Play release artifacts; iOS signing/provisioning, App Store release artifacts/metadata/privacy declarations and submission/review — iOS **PLANNED / UNVERIFIED**; qualified legal/accounting and commercial-operations readiness. |
| R19 | Both store review outcomes and releasable artifacts, shared production verification, completed required acceptance and final Owner approval. Simultaneous launch remains a target subject to actual readiness and store review. |

This adds planning references to the existing R10–R19 sections, including Android-focused R16/R18, without rewriting their status or historical requirements. The earlier M8 release/navigation table is not sufficient evidence of full commercial or two-platform readiness.

## Documentary preservation and future compatibility

No frozen/accepted source contract, commercial decision register, historical closure or implementation file is changed. The approved M1–M7 architecture sources listed as read-only in M8 §2 remain intact; new direction resides in this mutable parent planning record. The only edits in this pass are this roadmap append and localized references in the existing M8 readiness document. All preceding roadmap bytes, pre-existing dirty/untracked files and existing commercial/UI controls are preserved; no new standalone document is created.

Exact documentary composition is protected by commercial static guards. This newly authorized planning delta is not automatically recognized by the earlier four-guard compatibility commit. Any later required recognition needs its own exact documentary authority/review within the existing gates; this task permits no guard change, bypass, broad suffix allowlist or manufactured GREEN. Validation here is documentary only. No test/runtime/SQL/remote deployment, staging, commit or push occurs.

# COMMERCIAL STATIC GUARD OWNER-PLANNING COMPATIBILITY-ONLY AUTHORIZATION — 2026-10-12

```yaml
OWNER_PLANNING_STATIC_COMPATIBILITY_MODIFICATIONS_AUTHORIZED: YES — FOUR NAMED EXISTING GUARDS ONLY, SUBJECT TO EXECUTION GATE
COMPATIBILITY_SCOPE: EXACT COMMITTED OWNER PLANNING DOCUMENTATION AND THIS EXACT AUTHORIZATION RECORD ONLY
COMPATIBILITY_EXECUTION_GATE: OWNER COMMIT OF THIS EXACT RECORD PLUS SEPARATE OWNER EXECUTION INSTRUCTION
IMPLEMENTATION_AUTHORIZED: NO
R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO
R10.5-D_IMPLEMENTATION_STATE: NOT STARTED
R10.5-D_CONTRACT_FREEZE: NOT AUTHORIZED BY THIS RECORD
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
CUI2A1_STATE: ACCEPTED / FROZEN — IMPLEMENTATION NOT AUTHORIZED
CUI2A1_IMPLEMENTATION_AUTHORIZED: NO
CUI2A0_STATE: CLOSED
CUI1_STATE: CLOSED
M3_STATE: CLOSED
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
BACKEND_AUTHORITY_DELTA: ZERO
UI_AUTHORITY_DELTA: ZERO
PUBLICATION_AUTHORITY_DELTA: ZERO
ENTITLEMENT_AUTHORITY_DELTA: ZERO
PAYMENT_AUTHORITY_DELTA: ZERO
REMOTE_DEPLOYED_DATABASE: UNVERIFIED
INDEPENDENT_REVIEWER: Big Pickle
FOCUSED_ACCEPTANCE_GATE: SIX NAMED SUITES — ZERO FAILURES
CURRENT_PASS: GOVERNANCE-ONLY / APPEND-ONLY ROADMAP RECORD
FOCUSED_GREEN: NOT CLAIMED BY THIS RECORD
INDEPENDENT_REVIEW_PASS: NOT CLAIMED BY THIS RECORD
GIT_OWNER: User
```

## Authority and exclusive purpose

Authority is the Owner's explicit adoption of this exact record, following the supplied Architect acceptance of the completed R10.5-D commercial static guard compatibility source audit and narrow successive recognition design.

That Architect acceptance accepted the analysis and proposed design; it did not authorize repository changes.

This record conditionally authorizes one later, separately instructed compatibility correction whose exclusive purpose is recognition of the already committed Owner planning direction. “Documentary compatibility” describes the purpose of the four Dart guard changes; it grants no production implementation authority.

The 2026-10-09 CUI-2A1 compatibility-only authorization remains preserved. Its exact input boundary is not silently enlarged. This new record supplies separate, additional authority only for the documentary transition enumerated below. Frozen CUI-2A1 §16/§22 implementation gates remain unchanged and unsatisfied by this record alone.

No R10.5-D contract freeze, production implementation or implementation-authorized recognition branch is included. No CUI-2A1, M4 or M5 activation is included. Every other future documentary or implementation state requires a separate decision and exact recognition authority.

## Exact committed inputs and permitted documentary transition

| Input | Exact identity |
| --- | --- |
| Required entry branch | main |
| Owner planning commit | ac64cd6275888fd2768db2a890e98fbfc9819ab1 |
| Owner planning commit parent; previously landed four-guard correction | ed9840084eb67b1bb295459b420093a37d8bccbb |
| Parent of that four-guard correction; prior compatibility authorization | acbcf9af85da749328b672234ce258b00cbb5c23 |
| Roadmap path | docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md |
| Approved planning roadmap blob | e2e239e08f14350b910ab22185c095387e5a2301 |
| Readiness-document path | docs/architecture/CIVILPEDIA_IMPLEMENTATION_READINESS_AND_ROADMAP.md |
| Approved planning readiness-document blob | ee696d6a4054fd5476f81f3d7c2c9b6e6e8cd7ab |
| Parent roadmap blob | 4da132714f60b7f10c02d5732acc1646b549632d |
| Parent readiness-document blob | 62d61b26fc3a32940b0f3b64058fd63c69eca74c |

The Owner planning commit changes exactly those two documentation paths: 82 roadmap insertions and 13 readiness-document insertions, with zero deletions. The roadmap change is the exact end-of-file Owner Planning Direction append. The readiness-document change is the exact localized planning-reference delta committed in that object; it is not an append-only transformation of that document.

The allowed successive documentary transition is exclusively:

1. Retain the exact historical compatibility composition and its historical predicates.
2. Verify the previously landed four-guard correction at ed9840084eb67b1bb295459b420093a37d8bccbb, including its parent and exact four-path delta.
3. Verify the Owner planning commit, its exact parent, its exact two-path delta and both approved document blobs.
4. Recognize the exact planning roadmap followed by this one literal Owner-approved authorization append.
5. Keep the readiness document exactly equal to its approved planning identity.
6. Preserve every other contract, source, security predicate and protected entry byte.

The governance-persistence pass may append only this record to the existing Master Roadmap, preserving every preceding roadmap byte. Its Owner commit must have the planning commit as its parent and change only the roadmap.

After that commit exists, the implementer must observe and verify its real commit and roadmap blob identities, compare the literal approved append exactly, and establish that it is committed in the execution ancestry. No future hash is invented. An absent, pending, altered or mismatched authorization must fail the execution gate.

A pending candidate may be inspected as documentary review evidence; it may not enable the live authorized compatibility state.

## Exact later four-file write boundary

Only compatibility recognition, directly corresponding documentary/source expectations and positive/adversarial probes may change in:

```text
test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
test/commercial_harden1_public_plans_exposure_migration_test.dart
test/commercial_m1b_catalog_reference_data_migration_test.dart
test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart
```

No new helper, guard, runner, report, fixture or other file is authorized.

The original four guard blobs at the planning baseline are:

| Guard | Original committed blob |
| --- | --- |
| CUI-2A0 | 3f57d0df207f7625d3d5a66e15ade3133d61b0ca |
| HARDEN1 | 489a7975a095ba0d194fa52c7079651f32c4fb95 |
| M1B | be632a82938259ba068ba3492691115d092f2871 |
| M3 | 93a46d1a4a36bbab6374e50470aac244cde66723 |

These are retained review inputs, not requirements that the corrected files remain unchanged.

The shared documentary recognizer belongs in the existing CUI-2A0 guard. HARDEN1, M1B and M3 must consume the same recognition consistently, including their direct roadmap reconstruction assertions.

M1B's historical HARDEN1 full-source oracle and existing reconstruction must remain intact. Any additional transformation must describe only the approved compatibility changes, validate its exact expected anchors and reject unrelated source changes. Expected HARDEN1 source must never be copied from the live file under test.

During guard correction, the roadmap, readiness document and all other documents are read-only. Documentary recognition is an exact identity/transition check, never a general permission to modify those paths.

## Immutable historical Git pins

Preserve all existing historical pin values, ancestry checks, checkpoint lookups, source comparisons, historical fixtures and their rejection semantics. Do not replace them with the planning commit, current HEAD or a wholesale new baseline.

The existing immutable commit-pin set in the four guards is:

```text
3c676f1042b5f8e6f6eff6b7cb4681417c7e140f
3f4ce87381ea97b0f3f6a772827c4d77b58aee66
41276132ba6a1606cd779f5ce92473bacfbcc7c8
47096d45b98853af97ab5f3333b1b62b045dad81
47fba3f64581c9a24eefaee18265a437d8c55505
5642f329dc5dbf096847a08b1e5a30d3fc9d7c4f
5d511256a4364a3226383c2a631d70bef02ecba6
611f2dd30a32b730fc254a247dd4701a98e8b4f6
6d064521307b57f17b45249fcfc3713882b59c61
798b2af358735e871463790e746c8f5761fbb989
7d1d671e7b837be8b1ffed55116aa495d4922eb5
8103b551813715feaa1c2b8b3e2b198ae44d75af
889ff1da4389ba891247cfb5497554ca98fa58b3
a813b8c99309757bd7d03ac96dde0e7c12cfed79
acbcf9af85da749328b672234ce258b00cbb5c23
c60dbdda61bd656e281902b452ad937e14aa8c78
d9bc74d42e0d3ebc56455b928f2dbc57d8ca6fb8
dcc736ba7a8dc0b068f6c8bfc11b74566ab756dc
e767add487034171b0e8512ee6cfc8d56484004e
ebaf5f7b4402366285e214eec99735a931b69d8d
f348e0609300858073e8a5143f685fef04362b6b
f4e1331cdca6ec87cb37d32d1d2473479ffb2852
f94e96c2c510a6cef25f9f491163c5ce4f9320bb
```

The existing documentary and accepted SQL blob pins remain:

| Historical object | Blob |
| --- | --- |
| CUI-2A1 freeze roadmap | 049dfcff25091616d80132c6db9402f095e02c56 |
| CUI-2A1 compatibility roadmap | 4da132714f60b7f10c02d5732acc1646b549632d |
| CUI-2A1 frozen contract | 8071f951ff336714c420a5216504d0d49183e055 |
| CUI-1 contract | 7a2ab8a4f9665726e86f59c0947ebf3fb6543fd7 |
| CUI-1 media addendum | 6bd5e0e41b52e5a8b4a4df481a09b7bc196e56ea |
| CUI-1 closure report | 309536865a922631a12db5db0111004c4822e695 |
| CUI-1 closure roadmap | f9e793b3d001d75fee5da822cb43a8be12264942 |
| CUI-2A0 freeze roadmap | d2ea2d137df6a002cd114494ddf60500653df900 |
| CUI-2A0 original authorization roadmap | a36067d0634ae36437006175f825e68d70f92d0a |
| CUI-2A0 security authorization roadmap | a5586dfdea1770f58d2333bcabad26ea00d8e747 |
| CUI-2A0 closure roadmap | 8fa8595cfe9cc21a00db8016f930b45cf76b52d2 |
| CUI-2A0 closure report | 068307bb6e3d64a0cb479f127d1c162a155cb0cd |
| CUI-2A0 frozen contract | ed23e9136a39f71d95f91da7dd22e087a59dfca8 |
| CUI-2A0 ACL security addendum | 38016765af82de2e5a25e3b2169536bcf5fab44b |
| Accepted migration 00026 | 0de3aef18e9687a24917442649e5ffe831f391e0 |
| Accepted CUI-2A0 SQL runtime test | 96a2bd1f6cff8d2bbe9ad6433eb223267da96b4b |

These enumerations supplement, and do not replace, the guards' existing fixed-checkpoint comparisons and source-derived historical object identities. Preserve the wrong-pin adversarial cases as well.

## Protected entry bytes and preservation suites

Preserve the exact existing dirty and untracked path sets. Preserve these raw Git hash-object --no-filters identities:

| Protected path | Raw-byte identity |
| --- | --- |
| test/a5_6_profile_bootstrap_test.dart | 3bf84c06d8de648c793b93168832dd3f4557f6c4 |
| test/v1_r08_cloud_profile_foundation_test.dart | ed2fdfeace5d815d6c6a36df01bcf828c69e2e20 |
| test/v1_r08_profile_edit_screen_widget_test.dart | 8044513a653f601c37c6c91d55638254b82554cc |
| OpenCode_Usage_Report.txt | e0c432a4b8bd72e94d3db203b59ba260597dd601 |
| artifacts/r10_4a/home_dark.png | 45e4ba795bbcffbf283b282e48ff0d436ecb6e20 |
| artifacts/r10_4a/home_light.png | c35bb2314dd916f64cba5794d729aa12bd7a8247 |
| test/commercial_m1a_private_catalog_migration_test.dart | 2f73cf52711fb78969741470724f2aa2567995a5 |
| test/v1_r09q_security_matrix_test.dart | 8dcd0a3089833354fa49174b5db2a3d8c26318b9 |

The final two paths are read/run-only preservation suites, outside the write boundary.

Retain the existing distinction between normalized documentary comparisons and raw protected-byte hashes. No normalization, snapshot regeneration or formatting conversion may conceal a protected-byte change.

## Historical commercial authority and security preservation

Preserve every existing historical/composed commercial assertion, including:

- Frozen Commercial Model V1, all decisions, prices, plan identities, durations, classifications, OQs and amendment requirements; accepted C1/C2/C3 and all frozen contracts/addenda.
- Strict CUI-1 and CUI-2A0 CLOSED fixtures and predicates; historical CUI-2A1 documentary recognition.
- Exact migration inventory 00001–00026, filenames, ordering and accepted bytes; no 00027 or SQL change.
- M1a foundation, HARDEN1 raw-plans denial and privacy, and M1B's exact 40 canonical rows, UUIDs, tuples, constraints, catalog relationships and C/C′/D/E/F/G semantics.
- M3 Shadow isolation, private schema/defaults/ACL/RLS, evaluator and generation/concurrency semantics, unresolved-policy blocking and zero operational publication/entitlement authority.
- CUI-2A0's six RPCs, four independent permissions, two private helpers, private receipt, Draft-only/four-type authoring, complete-location eligibility, replay, optimistic concurrency and sanitized atomic audit.
- Canonical CLAIM trigger/guard protections, receipt isolation, absent-target denial, locking, and preserved legacy CLAIM/NEW behavior.
- append_audit_log owner-only direct EXECUTE: denied to PUBLIC, anon, authenticated and service_role; retained postgres/owner access; unchanged signature, body, owner, SECURITY DEFINER, search_path and audit schema.
- All unrelated Auth, RLS, ownership, privacy, source-integrity and security-matrix assertions.
- Canonical Business UUID and user/Business separation; one production Supabase authority and one AuthProvider; no service_role in Flutter and no blind automatic mutation retry.
- All current implementation locks and separately deferred security findings.

This correction changes no commercial meaning or deployed behavior. Static GREEN is not SQL/runtime, remote deployment or production-readiness evidence.

## Recognition and adversarial acceptance requirements

Add an explicit, separately named current-documentary recognizer. Preserve historical predicates with their original fixtures and rejection semantics.

Validate the complete new extension before projecting it onto historical fixtures. Historical fallback must never certify an invalid live composition.

Positive and adversarial cases must invoke the same live/current recognizer and branch selection used by the actual repository checks.

Required positive evidence:

1. Retained historical fixtures pass their original predicates.
2. The exact planning commit/parent/two-document identities are recognized.
3. The exact Owner-committed authorization append is recognized.
4. The actual live repository passes with zero R10.5-D and CUI-2A1 production/test additions.
5. Only the authorized guard correction delta and exact protected entry baseline are present.
6. All three predecessor consumers and their direct documentary assertions agree with the shared recognizer.
7. M1B accepts only the exact approved HARDEN1 source transformation.

Required adversarial rejection evidence:

- Wrong commit, parent, ancestry, documentary blob, missing document or altered historical pin.
- Altered/truncated planning append, changed readiness content or arbitrary future roadmap suffix.
- Missing, uncommitted, altered or mismatched compatibility authorization.
- Any anticipated R10.5-D contract freeze or implementation-YES record.
- Any R10.5-D implementation source/test change, including the audit's candidate presentation paths.
- CUI-2A1 production/UI-test additions or activation; M4/M5 activation; reopened closures or authority deltas.
- Extra documentation, helper, guard, runner, test or other path; lookalike paths, unauthorized rename or deletion.
- Migration 00027, renamed migration, historical migration edit or any SQL/Supabase/configuration delta.
- Protected-byte change, missing protected entry or changed dirty/untracked inventory.
- Unauthorized committed or staged changes concealed by restoring the working copy.
- Unrelated source/assertion removal, broad HARDEN1 replacement or an expected snapshot derived from live actual source.
- An invalid current state accepted through historical fallback.

Committed, index, unstaged and untracked inventories must be checked independently. Exact document identity must be checked in the committed objects and live composition; a path-set match alone is insufficient.

No dynamic HEAD acceptance, broad path-prefix exception, generic dirty-file exception, arbitrary future-record acceptance, skip, comment-out, environment bypass or weaker test-only predicate is permitted.

## Six-suite focused validation and independent review

Run the following six suites sequentially in the separately authorized correction/review pass:

```text
flutter test --no-pub test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
flutter test --no-pub test/commercial_harden1_public_plans_exposure_migration_test.dart
flutter test --no-pub test/commercial_m1b_catalog_reference_data_migration_test.dart
flutter test --no-pub test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart
flutter test --no-pub test/commercial_m1a_private_catalog_migration_test.dart
flutter test --no-pub test/v1_r09q_security_matrix_test.dart
```

Acceptance requires all six suites executed, zero failures, preserved historical coverage, required live positive/adversarial evidence and unchanged M1a/R09q sources.

Big Pickle must independently review the exact four-file diff, execute all six focused suites and accept the documentary recognition, source coupling, inventory checks and preservation evidence before the Owner commits the correction. The implementer and reviewer must be independent.

If Big Pickle is unavailable, STOP for an explicit Owner decision on reviewer substitution. Do not infer a substitute from general routing defaults. Any substitution decision must identify the replacement and its authority explicitly.

Unresolved CRITICAL, HIGH or MEDIUM findings block acceptance. Record LOW findings and their explicit disposition. Test PASS alone is not independent acceptance.

No repository-wide suite is authorized. No SQL test, database connection, migration execution, reset, deployment or SDK/cache/global-package patch is authorized.

## Prohibited changes

The correction may not change:

- Flutter production source, UI/localization/navigation, providers, repositories, models or dependencies.
- Any test outside the four named guards, including M1a/R09q.
- Contracts, commercial policy, closure reports, roadmap or readiness document.
- SQL, migrations, schema, grants, ACL/RLS, Supabase configuration, seed or runtime data.
- Ownership, invitation/CLAIM authority, staff provisioning, publication, entitlement, payment, Sponsored, Branch or media authority.
- R10.5-D freeze/execution state, CUI-2A1 execution state, M4/M5 or later UI locks.

No staging, commit, push, reset, revert, clean, stash, migration or deployment is authorized to an agent by this record. Git remains Owner-controlled.

## Mandatory STOP conditions

STOP without broadening scope or attempting a bypass if:

1. Entry branch, required ancestry or any fixed commit/blob identity differs.
2. The planning commit is not exactly the approved two-document transition.
3. The authorization is absent, pending, altered, incorrectly committed or contains additional changes.
4. An unexplained committed, staged, unstaged or untracked path appears.
5. Any protected entry byte, historical source, contract, migration, security predicate or implementation lock differs.
6. Recognition requires a fifth file, a new helper/report, a document rewrite, a production change or a broad exception.
7. Exact HARDEN1 transformation anchors or historical reconstruction fail.
8. The same live recognizer cannot provide both positive and adversarial evidence, or historical fallback admits an invalid current state.
9. Any required suite fails, is skipped or cannot execute.
10. Six-suite GREEN cannot be achieved within the four-file boundary while M1a/R09q remain unchanged.
11. Independent Big Pickle review is unavailable or rejects the change; reviewer substitution lacks explicit Owner approval.
12. A blocking review finding remains, or commercial meaning/authority would change.
13. Closure evidence or explicit Owner acceptance is missing.

Report the exact blocker. Boundary expansion requires independent audit and a new exact Architect/Owner amendment; commercial-policy changes additionally require the frozen model's formal amendment process. No blind mutation retry, retroactive authorization or manufactured GREEN.

## Owner acceptance, Git ownership and closure evidence

Before the correction is eligible for Owner commit, provide:

- Actual authorization commit, parent and roadmap blob, with literal append/prefix verification.
- Planning commit/parent/two-document identity and transition evidence.
- Exact changed-path list and reviewed four-file diff.
- Historical pin/source preservation and migration 00001–00026 evidence.
- Protected raw-byte identities and independently checked repository inventories.
- Live positive and adversarial recognition results, including branch-selection and hidden-drift cases.
- Exact commands, environments, exit codes and observed counts for all six suites.
- Independent Big Pickle review verdict and finding dispositions, or the explicit Owner-approved substitution record.
- git diff --check, final status and index evidence.
- Explicit Owner acceptance of this exact correction.

Only the Owner may stage, commit and push the accepted correction unless separately and explicitly authorizing an agent. The guard correction commit must contain only accepted changes within the four named paths.

After the Owner commits, observe the real correction commit/parent and resulting guard blob identities, verify parity with the reviewed sources and verify that no out-of-scope committed delta occurred. Establish focused GREEN for that committed composition; identical-source precommit results may be traced to it, but any changed source/composition requires renewed focused validation and review.

Closure must identify the actual governance and correction identities, six-suite evidence, independent review and explicit Owner acceptance. This record itself claims none of those future outcomes.

Any later roadmap closure append requires separate documentary authority and exact compatibility recognition if needed. It is not implicitly covered here.

R10.5-D remains AUDIT-ONLY / IMPLEMENTATION NO. Commercial CURRENT remains NONE and commercial implementation remains NO. CUI-2A1/M4/M5 remain implementation-unauthorized. Repository compatibility closure does not certify remote deployment or production readiness.

# V1-R10.5-D CONTRACT ACCEPTANCE / FREEZE — 2026-10-12

```yaml
R10.5-D_CONTRACT: docs/architecture/contracts/V1-R10_5D_PROFILE_USER_AREA_PRESENTATION_IMPLEMENTATION_CONTRACT.md
R10.5-D_CONTRACT_ID: V1-R10.5-D-PRESENTATION-CONTRACT-v1
R10.5-D_CONTRACT_STATUS: ACCEPTED / FROZEN
R10.5-D_ARCHITECT_ACCEPTANCE: ACCEPTED — FOLLOWING INDEPENDENT A ACCEPTANCE
R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO
R10.5-D_IMPLEMENTATION_STATE: NOT STARTED
IMPLEMENTATION_AUTHORIZED: NO
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
CUI2A1_IMPLEMENTATION_AUTHORIZED: NO
CUI2A0_STATE: CLOSED
CUI1_STATE: CLOSED
M3_STATE: CLOSED
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
BACKEND_AUTHORITY_DELTA: ZERO
UI_IMPLEMENTATION_DELTA: ZERO
PUBLICATION_AUTHORITY_DELTA: ZERO
ENTITLEMENT_AUTHORITY_DELTA: ZERO
PAYMENT_AUTHORITY_DELTA: ZERO
COMMERCIAL_GUARD_MODIFICATIONS_AUTHORIZED: NO
FOCUSED_GREEN_FOR_THIS_DOCUMENTARY_TRANSITION: NOT CLAIMED
OWNER_GIT_REVIEW: PENDING
COMMIT_PUSH_AUTHORIZED: NO
```

## Authority and documentary acceptance

Authority: the Owner-provided **CIVILPEDIA — R10.5-D CONTRACT FREEZE** instruction conveys the Architect's acceptance of the reviewed contract following independent A acceptance and explicitly accepts the §O correction. It authorizes exactly this existing contract's freeze and this append-only roadmap acceptance record. No additional Owner write authorization is required for these two documentary changes. The supplied acceptance is recorded without inventing a reviewer identity, review artifact or fresh test result.

Verified entry branch: `main`; HEAD and local `origin/main`: `0ceb646621027e2ab902b13302c452038154ab11`; index empty. The corrected contract entered as an untracked document; protected modified/untracked files were already present and remain outside this task's write boundary.

| Documentary identity | Observed value / meaning |
| --- | --- |
| Corrected reviewed draft, individual raw SHA-256 before freeze | DEB8340F1650B8AC54C6733D08EA0D242E253D2E789290D6B4690FDC1B5C389C |
| Frozen contract working-tree Git blob identity | 0c8f38c87248d31a5aef23a4cfe9f20a546b1329 |
| Frozen contract individual raw SHA-256 | 43A9CB63C5E2DC2EFAF022AF01F164DCCCA8F0B2CD5369E1C6C30B86BEBBDE67 |
| Roadmap committed prefix blob at entry HEAD | dba35363152429ca78933e1669e80758cfaba48c |
| Owner planning readiness blob, unchanged | ee696d6a4054fd5476f81f3d7c2c9b6e6e8cd7ab |
| Freeze commit / parent / resulting roadmap blob | PENDING OWNER GIT REVIEW — observe actual identities after an explicitly authorized Owner commit |

The working-tree identities describe the exact pending documentary review inputs; they do not assert a committed freeze or enable execution. No future commit/hash is invented. This record asserts no repository-wide aggregate hash.

## Frozen future scope — implementation remains unauthorized

The accepted future implementation boundary is exactly:

```text
lib/features/profile/presentation/profile_screen.dart
lib/features/profile/presentation/screens/profile_setup_screen.dart
lib/features/profile/presentation/screens/profile_edit_screen.dart
lib/features/profile/presentation/screens/authenticated_profile_edit_screen.dart
lib/features/user_area/presentation/user_area_screen.dart
test/v1_r10_5d_profile_user_area_visual_test.dart
```

The first five are existing presentation screens; only the final focused visual-test path is new. None is changed or created by this freeze. All other implementation paths remain excluded.

The accepted contract's per-file requirements, Auth/Supabase/profile-save/recovery/navigation invariants, User Area tile inventory, component/token reuse, Arabic RTL/light/dark/text-scale matrix, Projects responsive conventions and 760 logical-pixel content cap remain unchanged. The exact 17 existing regression paths in §F remain read-only. Android visual QA and the mandatory future iPhone compatibility dependency retain their prescribed status/gates. The accepted §O correction, eight individual protected raw-byte identities, historical security predicates and formal amendment boundaries are preserved.

Earlier roadmap NOT FROZEN/no-frozen-file-list descriptions are superseded solely as to contract acceptance/freeze by this later record. All preceding roadmap bytes remain intact. R10.5-D remains CURRENT for audit only, IMPLEMENTATION_AUTHORIZED NO / NOT STARTED. Contract acceptance creates no production execution instruction. R10.5-E, R10.5-F, R10.6 and R10.7 remain LOCKED; Arabic-only active V1 and dormant English compatibility remain unchanged. Commercial CURRENT remains NONE, implementation NO; CUI-2A1/M4/M5 implementation remains unauthorized; CUI-1/CUI-2A0/M3 closures are preserved.

## Exact remaining commercial-guard compatibility prerequisite

The committed Owner-planning branch in the four commercial guards pins the roadmap to `dba35363152429ca78933e1669e80758cfaba48c` and independently restricts committed/index/unstaged/untracked inventories. This new contract path and this literal freeze append are additional documentary inputs outside that accepted composition. The prior planning-only compatibility authorization explicitly excludes R10.5-D freeze/implementation states. Its historical 178/178 GREEN does not certify this pending transition; no guard suites are run or fresh GREEN claimed in this freeze task.

Before later execution, a separate exact Architect/Owner compatibility authorization must identify the actual Owner-committed freeze commit/parent, this frozen contract blob and the resulting roadmap blob; verify the contract addition, exact append and preserved roadmap prefix, unchanged readiness and every other historical authority. The authorization must define any exact additional authorization append separately, then observe its real commit/blob identities. Pending documentary review evidence must not enable live production authority.

The potential future guard write boundary remains the four existing paths below, subject to that separate authorization; no write permission is granted here:

```text
test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
test/commercial_harden1_public_plans_exposure_migration_test.dart
test/commercial_m1b_catalog_reference_data_migration_test.dart
test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart
```

Recognize only the exact ACCEPTED/FROZEN / implementation-NO documentary stage through a shared successive recognizer, as designed in contract §L. Preserve all historical commit/blob pins, positive/adversarial fixtures, commercial/security predicates, source oracles and independent per-layer inventories. HARDEN1/M1B/M3 must agree with CUI-2A0; direct roadmap reconstruction and M1B's historical HARDEN1 source transformation must remain exact and reject unrelated drift. Do not replace expected source with live actual source.

Future positives must accept the exact committed freeze-only composition with zero R10.5-D production/test edits. Adversarial cases must reject altered/missing/uncommitted identities, arbitrary future roadmap suffixes, concealed committed/staged drift, unexpected paths/statuses, changed protected bytes/security sources, any SQL/Supabase/migration delta, premature R10.5-D implementation and commercial activation. No dynamic HEAD authority, broad path exception, skip, weakened assertion or historical fallback may certify an invalid live state.

Require all six focused suites sequentially with `flutter test --no-pub`: CUI-2A0, HARDEN1, M1B, M3, unchanged M1a and unchanged R09q security matrix; zero failures and meaningful live positive/adversarial evidence. Independent Big Pickle review remains mandatory for future guard work. If unavailable, STOP for an explicit Owner decision naming a substitute; do not silently substitute. Unresolved CRITICAL/HIGH/MEDIUM findings block acceptance. Owner acceptance and separately authorized Git closure remain required.

This record does not authorize the compatibility task, amend frozen CUI-2A1 §16/§22 gates, or approve an execution-active recognizer. Later implementation authorization and its exact six-path recognition require separate decisions after committed compatibility GREEN and the contract's preimplementation baseline gate. Any formally required frozen-contract amendment must itself be separately accepted.

## Current change control and handoff

Current write boundary: this existing R10.5-D contract and this append-only Master Roadmap record only. No Flutter/test/guard/SQL/Supabase/dependency/deployment/Git publication work. The contract's §Q records the supplied acceptance while retaining earlier drafting history and §O byte-for-byte.

Owner Git review is pending for the exact two-document diff. Verify protected raw hashes, tracked/untracked inventories, empty index, preserved roadmap prefix, unchanged accepted requirements and `git diff --check`; inspect the untracked contract separately. No staging, committing or pushing is authorized. The remaining compatibility prerequisite is explicit and unsatisfied; no implementation starts automatically.

**R10.5-D CONTRACT FROZEN — IMPLEMENTATION NOT AUTHORIZED — OWNER GIT REVIEW PENDING**

# R10.5-D FREEZE-ONLY FOUR-GUARD COMPATIBILITY AUTHORIZATION

The Owner prospectively authorizes completion of freeze-only commercial
guard compatibility. This record does not assert that committed
authorization existed when the current candidate was prepared.

Exact frozen inputs:
Freeze commit: bb59c7425527eed16a219c2043172ee9e523acfc
Parent: 0ceb646621027e2ab902b13302c452038154ab11
R10.5-D contract blob: 0c8f38c87248d31a5aef23a4cfe9f20a546b1329
Freeze roadmap blob: 7a2e58253ddd9a9795dde59da864019931d3c5ee
Unchanged readiness blob: ee696d6a4054fd5476f81f3d7c2c9b6e6e8cd7ab

The authorization-persistence commit must have the freeze commit as
parent and change only the Master Roadmap by this exact append.

After that commit exists and a separate Owner execution instruction is
issued, only the four guard paths enumerated at lines 4832–4835 of the
freeze commit's Master Roadmap may change.

Preserve the reviewed candidate except for the narrowly necessary
recognition and enforcement of this exact committed authorization.
Observe and pin its actual commit, parent and resulting roadmap blob.
Verify the preserved prefix and exact append. Missing, pending,
altered or mismatched authorization must fail live recognition.
No future hash is supplied or invented.

Retain the shared recognizer, all historical pins/security predicates,
negative tests, exact HARDEN1 source oracle, independent repository-layer
checks and all eight protected raw-byte identities. No broad exceptions,
live-derived expected source, skipped assertions or historical fallback
may admit unauthorized current states.

Run CUI-2A0, HARDEN1, M1B, M3, unchanged M1a and unchanged R09q
sequentially using flutter test --no-pub. Require zero failures,
meaningful live positive/adversarial evidence, git diff --check and
independent Big Pickle acceptance of the resulting exact composition.
Reviewer substitution requires an explicit Owner decision naming it.

STOP for any identity, scope, preservation, validation or review failure.
Existing 193/193 and independent PASS remain prior candidate evidence;
changed sources/composition require renewed focused validation/review.

R10.5-D remains ACCEPTED / FROZEN, AUDIT-ONLY / IMPLEMENTATION NO.
Commercial implementation remains NO; CUI-2A1/M4/M5 remain unauthorized.
No UI, visual-test, SQL/Supabase, policy, contract or other-file changes.
Git closure requires separate explicit Owner authorization.

# V1-R10.5-D CONDITIONAL PRESENTATION EXECUTION AUTHORIZATION

This is a prospective decision, effective only after explicit Owner adoption and an authorized Owner commit. It asserts no previous production implementation authority.

R10.5-D_CONTRACT_STATUS: ACCEPTED / FROZEN
IMPLEMENTATION_AUTHORIZED: YES — R10.5-D PRESENTATION ONLY, CONDITIONAL ON ALL EXECUTION GATES BELOW
R10.5-D_IMPLEMENTATION_STATE: NOT STARTED
R10.5-D_EXECUTION_STATE: BLOCKED UNTIL COMMITTED COMPATIBILITY GREEN, BASELINE/ANALYSIS DISPOSITION AND SEPARATE OWNER RELEASE
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
CUI2A1_IMPLEMENTATION_AUTHORIZED: NO
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
CUI1_STATE: CLOSED
CUI2A0_STATE: CLOSED
M3_STATE: CLOSED
R10.5-E/F_R10.6_R10.7: LOCKED
BACKEND_PUBLICATION_ENTITLEMENT_PAYMENT_AUTHORITY_DELTA: ZERO
COMMIT_PUSH_AUTHORIZED_TO_AGENTS: NO

## Exact existing authority and documentary boundary

Entry baseline: main at 48004703c8afe633a487f7612f07aecb459c7e7e.
Frozen contract: docs/architecture/contracts/V1-R10_5D_PROFILE_USER_AREA_PRESENTATION_IMPLEMENTATION_CONTRACT.md, Git blob 0c8f38c87248d31a5aef23a4cfe9f20a546b1329.
Roadmap prefix: docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md, Git blob d8a6511e1237efeebe62f745923550ce94609abc.
Readiness document remains at blob ee696d6a4054fd5476f81f3d7c2c9b6e6e8cd7ab.

Preserve every preceding roadmap byte and every frozen contract requirement. This later record supersedes only R10.5-D's ordinary UI implementation-NO/audit-only execution control, and only subject to the gates below. Historical records remain intact. No commercial phase is activated and no CUI-2A1 gate is satisfied or waived.

## Exclusive future UI write boundary

M lib/features/profile/presentation/profile_screen.dart
M lib/features/profile/presentation/screens/profile_setup_screen.dart
M lib/features/profile/presentation/screens/profile_edit_screen.dart
M lib/features/profile/presentation/screens/authenticated_profile_edit_screen.dart
M lib/features/user_area/presentation/user_area_screen.dart
A test/v1_r10_5d_profile_user_area_visual_test.dart

Only the new visual test may be untracked/added; once present it may be modified within the same authorized implementation. No deletion, rename, type change, seventh path, shared-component/provider/data/route/dependency/localization/native/SQL/Supabase change is permitted. Existing 17 regression files in frozen contract §F remain read-only. Preserve all eight literal raw Git identities in §O, including the existing three dirty tests and three untracked artifacts.

## Frozen behavior and presentation requirements

Implement §§A–E of the frozen R10.5-D contract without changing AuthProvider/Supabase authority, cloud-profile SSOT, local/guest fields and payloads, two-step setup/back/persistence, cloud save/single-flight/uncertain-save/manual retry, dirty/pending back protection, routes/destinations, whole-body Profile conflict versus header-only User Area conflict, five ordinary User Area entries and staff capability gates. No recovery parity redesign, new field, automatic retry, additional destination, backup-operation change or Google Play destination change.

Reuse CivilAppBar, CivilSurfaceCard and existing theme/tokens, true-black dark hierarchy, Arabic RTL and representative dormant English LTR compatibility. Apply 16/24/32 gutters at 600/840 breakpoints, centered 760 logical-pixel content cap, readable 320×568/2.0 text-scale layouts, effective 48×48 hit targets and exactly one shell-safe bottom clearance. Replace only raw backup failure interpolation with the established localized failure text.

## One coordinated compatibility pass, separately instructed

The Owner/Architect must separately approve and instruct the exact coordinated activation pass before any edits. Its exclusive write boundary is this single roadmap append plus:
test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
test/commercial_harden1_public_plans_exposure_migration_test.dart
test/commercial_m1b_catalog_reference_data_migration_test.dart
test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart

That pass performs zero UI implementation. It must implement one separately named shared R10.5-D recognition design for (a) the exact pending review pair, with live production execution disabled; (b) the committed authorization with zero UI changes; and (c) permitted partial and committed UI changes limited to the six paths above. A pending pair is review evidence only and cannot enable production execution. Preserve old exact historical/freeze-only fixtures, every security/hash predicate and independent committed/staged/unstaged/untracked inventories. Keep the three consumers and M1B's independently authored, unique-anchor HARDEN1 source oracle exact. Never derive expected source from the live file or accept arbitrary document suffixes, caller/environment bypass flags, directory exceptions or HEAD as expected authority.

Observe actual authorization/guard commit and document/source blob identities only after the accepted coordinated commit exists. Do not invent future hashes or require a guard's own future hash inside its source. During UI work, the approved committed guards, all documents and unrelated sources are immutable; only the six UI paths and exact protected entry dirt may differ. Final UI identities are recorded after accepted Owner Git closure. Closure-document recognition remains a separate later decision.

## Mandatory execution and acceptance gates

1. Owner/Architect accepts this exact record and finite-stage compatibility design. Any genuine frozen-contract/gate change requires its own formal accepted amendment; this record silently amends none.
2. Independently validate/review the exact coordinated roadmap/four-guard candidate, including meaningful positive/adversarial recognition. Owner separately authorizes and commits only its five paths, with entry baseline as parent. No UI edits occur in this pass.
3. Verify the actual committed identities and run the four guards plus unchanged commercial_m1a_private_catalog_migration_test.dart and v1_r09q_security_matrix_test.dart sequentially with flutter test --no-pub. Require zero failures/skips and live committed preimplementation GREEN with zero UI changes. Pending-candidate GREEN cannot substitute for this committed gate.
4. Satisfy frozen §G's 17-file baseline and targeted five-file analysis requirement. Reuse earlier test evidence only when exact source/test/toolchain inputs and composition traceability are verified and explicitly accepted; otherwise rerun the required baseline. The recorded internal Enum analyzer crash is not PASS; an explicit Architect tooling disposition or separately authorized successful analysis resolution is required. No SDK/dependency/global-cache patch is authorized.
5. Owner issues a separate UI release instruction naming the actual committed execution/guard baseline and accepted prerequisite evidence. Only then may the designated UI implementer edit the six UI paths.
6. After UI work, run the mandatory new visual suite, all 17 unchanged regressions and the same six security suites sequentially; require zero failures/skips, preserved raw identities and no new analyzer diagnostics under the accepted tooling disposition. Complete independent ordinary UI review and Owner Android visual acceptance with actual revision/device/settings evidence.
7. Keep R10.5-D-IOS-01 mandatory before iOS launch and UNVERIFIED until native iPhone evidence exists. Android/widget results certify no native iOS readiness.
8. Final Architect acceptance and separate Owner Git authorization are required. Stage only the accepted six-path UI scope, preserve unrelated dirt, inspect complete staged diff, run git diff --cached --check, verify actual parent and resulting source/test blobs, and use only normal expressly authorized Git publication. No automatic next-slice advancement.

Guard compatibility requires independent Big Pickle review. The prior fresh-Codex substitution applied to the closed freeze-only acceptance gate and does not silently extend here; any new substitution must be explicitly named and scoped by the Owner. Routine UI implementation/review follows the Operating Model with independent implementer and reviewer.

STOP for a missing/altered/uncommitted authority, failed required gate, protected-byte or source drift, unexpected path/status, weakened historical predicate, source-oracle mismatch, unresolved blocking review finding, missing analysis disposition, premature implementation or scope expansion. Report the exact required Owner/Architect decision; do not bypass, retry mutations blindly or edit protected tests.

# R10.5-D HISTORICAL FIXTURE REPAIR — BOUNDED SECURITY MAINTENANCE — 2026-10-18

This prospective record adopts the Owner/Architect's narrowly bounded maintenance instruction. It claims no earlier authority and grants no general guard-maintenance exception. UI implementation is PAUSED during this maintenance pass.

MAINTENANCE_BASELINE: main / 20fff015921ec6c55cf09258298c2a06c05f9d43
BASELINE_PARENT: 48004703c8afe633a487f7612f07aecb459c7e7e
BASELINE_ROADMAP_BLOB: e66690adbd7615f2a8300ad1b13560f3c82efda2
FROZEN_R10_5D_CONTRACT_BLOB: 0c8f38c87248d31a5aef23a4cfe9f20a546b1329
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
CUI2A1_M4_M5_IMPLEMENTATION_AUTHORIZED: NO
NEW_UI_IMPLEMENTATION_AUTHORIZED: NO
COMMIT_PUSH_AUTHORIZED: NO

The historical positive hasAuthorizedCui2a0Boundary assertion in _registerOwnerPlanningBoundaryTests omitted untrackedPaths and therefore combined historical inputs with today's untracked inventory. Its sole fixture correction is the explicit argument untrackedPaths: _cui2a1UntrackedPaths. The historical predicate, its literal three-path inventory and every negative outcome remain unchanged. Never filter the actual untracked inventory.

This one maintenance candidate may append only this literal record and change only technically necessary recognition/source-oracle coordination in the existing guards. The actual maintenance delta is exactly:
M docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md
M test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
M test/commercial_harden1_public_plans_exposure_migration_test.dart
M test/commercial_m1b_catalog_reference_data_migration_test.dart
The M3 guard remains unchanged. No other repository path may change in this pass.

Preserve the current UI candidate's six raw Git identities:
lib/features/profile/presentation/profile_screen.dart: 48153fe3d36b59c122371f85215551e687a95cd7
lib/features/profile/presentation/screens/profile_setup_screen.dart: 64da1f57fa4e6364c59b29c28c24256953460e7e
lib/features/profile/presentation/screens/profile_edit_screen.dart: 9c2b3fea3e0f8c16f9eb79b7e02597a4ede9e043
lib/features/profile/presentation/screens/authenticated_profile_edit_screen.dart: 8fa92706081297bd17cbeb95ff42d8448581470c
lib/features/user_area/presentation/user_area_screen.dart: 8db72d58ae85d61c3c46ec099a686fb5db2f3c8b
test/v1_r10_5d_profile_user_area_visual_test.dart: cfc81ef7be8d020771ccbebad07d31fffa01c782

Recognition retains the original approved UI state and adds only this maintenance transition:
1. Pending review: HEAD is the exact baseline above; index is empty; the four maintenance paths are modified, with their exact approved contents; all six UI identities remain exact. This is review evidence only. No new functionality, UI work or Git publication is authorized.
2. Committed maintenance: observe the actual direct-child commit of that baseline, containing exactly the four maintenance modifications above, the exact literal append and approved guard sources. No future commit hash is invented.
3. Subsequent UI closure: require unchanged maintenance documents/guards in every descendant, single-parent ancestry and only the original six UI paths with their original permitted statuses/modes. This supplies no additional UI execution permission; any further work requires its existing procedural Owner release. Closure-document recognition remains a separate decision.

Verify every committed, indexed, unstaged and untracked layer independently. Only after the exact maintenance inputs are validated may this one transition be projected onto the unchanged original R10.5-D classifier. Do not remove or filter any untracked entry. Reject missing/altered authority, unexpected paths/modes/statuses, changed protected bytes, hidden/restored history drift and unrelated future maintenance.

Source identity is exact after CRLF-to-LF normalization, as in existing source oracles. HARDEN1/M1B/M3 are checked against fixed complete Git blob identities. To avoid a circular future hash, the CUI-2A0 source fingerprint is the Git blob hash of its complete UTF-8 LF source with exactly one declaration, const _r10MaintenanceCuiFingerprint = '<40 lowercase hex>'; replaced by the identical declaration with forty zeroes. Require one unique declaration and its literal value to equal the compiled fixed fingerprint. No other source region is excluded. Compute with git hash-object --no-filters, without -w; independently reproduce before review. This fingerprint is not a raw protected-file identity. Actual complete committed guard blobs are observed and checked at closure; subsequent guard edits fail closed.

Preserve all historical pins, fixtures and security predicates; CUI-1/CUI-2A0 closures; HARDEN1 public-plan restrictions; M1B catalog and independently authored unique-anchor HARDEN1 source oracle; M3 shadow entitlement isolation; unchanged M1a/R09q; RLS, actor/capability, ownership/publication, audit/receipt/SQL protections; every frozen policy and all eight literal contract §O raw identities. No contract, SQL/Supabase, Auth/provider, route, dependency or SDK change. No commercial capability expands.

First validate the repaired historical assertion. Then run CUI-2A0, HARDEN1, M1B, M3, unchanged M1a and unchanged R09q sequentially with flutter test --no-pub; require zero failures/skips and live positive/adversarial evidence for all maintenance states. Previous 43/43 visual and 401/401 regression results remain previous evidence only while their exact inputs are preserved.

Independent Big Pickle High acceptance is required. Any substitute requires a newly explicit Owner decision naming and scoping it. Final Owner acceptance and separate Git authorization are required; no staging/commit/push is granted here. After accepted maintenance closure, guards and documents are again immutable during ordinary UI work. The analyzer Enum failure remains NOT PASS; Android Owner visual acceptance and native iPhone QA remain separate gates.

STOP for a genuinely required frozen-contract amendment, insecure transition, weakened historical protection, unexpected drift, failed mandatory validation/review or another native compiler/runtime crash. Preserve existing crash evidence. No automatic next-slice advancement.

# V1-R10.5-D ACCEPTANCE EVIDENCE / TOOLING DISPOSITION STATUS — 2026-10-22

The original Master Roadmap remains the phase/status authority. This record preserves all preceding bytes and frozen requirements. It records supplied Owner/Architect facts and prior evidence; it grants no implementation, final acceptance, Git publication or next-slice authority.

R10.5-D_STATUS: CURRENT — EXISTING CANDIDATE UNDER ACCEPTANCE REVIEW / NOT CLOSED
UI_CANDIDATE: FIVE MODIFIED PRESENTATION SCREENS + ONE UNTRACKED VISUAL TEST
INDEPENDENT_UI_REVIEW: OWNER-REPORTED BIG PICKLE HIGH — PASS WITH NONBLOCKING FINDINGS / READY FOR OWNER ANDROID QA; NO HIGH OR MEDIUM IMPLEMENTATION DEFECTS REPORTED
PREVIOUS_EVIDENCE: VISUAL 43/43; FUNCTIONAL 401/401; POST-CUI SECURITY 220/220; SEPARATE 2026-10-21 EMULATOR OBSERVATIONS 16/16 — ALL PREVIOUS PASS RESULTS, NOT RERUN FOR THIS RECORD
OWNER_VISUAL_APPROVAL: PROVISIONAL ONLY — NOT FINAL OWNER ACCEPTANCE
ANALYZER_STATUS: NOT PASS — INTERNAL ANALYSIS TOOLING FAILURE
FINAL_ARCHITECT_TOOLING_DISPOSITION: PENDING EXPLICIT ACCEPTANCE
NATIVE_FLUTTER_DART_CRASH_ROOT_CAUSE: UNKNOWN
R10.5-D-IOS-01: UNVERIFIED / REQUIRED BEFORE IOS LAUNCH
ROADMAP_UI_CLOSURE: NOT COMPLETED
UI_GIT_CLOSURE: NOT COMPLETED
PRODUCTION_EXECUTION_AUTHORIZED: NO
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
R10.5-E: LOCKED / NOT AUTHORIZED
COMMIT_PUSH_AUTHORIZED: NO

Owner provisional visual approval covers Profile, User Area, Profile Setup and Local Profile Edit on Pixel_9_Pro, Android 17/API 37. Future observations remain open and are not presumed cosmetic. Authenticated Profile Edit has independent code-review and previous widget evidence, but authenticated/cloud emulator runtime inspection was unavailable because the QA launch lacked configured Supabase. This is an evidence limitation, not an established cloud-feature defect.

LOW findings: F1/F2 — Architect recommends deferring protected-test hygiene; Owner approval of that recommendation remains pending. F3 — existing roadmap UI pins establish checkpoint provenance, not final committed UI closure. F4 — representative responsive combinations are permitted by frozen contract §E; required assertions remain mandatory.

Frozen §§G/P and the conditional execution record permit an explicit Architect tooling disposition. Proposed alternative, not yet accepted: retain Analyzer NOT PASS; accept only a bounded alternative evidence package for the exact reviewed candidate and toolchain, comprising independent review, successful Android compilation, preserved visual/functional/security results and emulator observations. Accept explicitly the residual absence of complete analyzer diagnostics, lint coverage and a verified no-new-diagnostics comparison. Tests and compilation do not prove analyzer cleanliness or resolve native crashes.

Final acceptance still requires explicit tooling disposition or separately authorized successful analysis, LOW-finding dispositions, completion or formally authorized adjudication of outstanding §H Android evidence, final Owner visual acceptance and final Architect acceptance. UI Git closure requires separate Owner authority and actual resulting identities. No emulator evidence certifies physical Android or native iPhone readiness.

Separate observations: Home image HTTP 404 responses, debug-emulator startup skipped-frame warnings and Android OnBackInvokedCallback warnings. No R10.5-D blocking attribution or root cause is established for them.

Arabic-only RTL remains active. No frozen requirement, protected identity, Auth/Supabase authority, commercial restriction or later-slice lock is waived.
