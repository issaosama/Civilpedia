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
CURRENT_PHASE_ID: V1-R09Q
CURRENT_PHASE_TITLE: Post-R09 Cross-Cutting Quality Gate
LAST_CLOSED_PHASE_ID: V1-R09
LAST_CLOSED_COMMIT: c7702a6
ROADMAP_STATUS: ACTIVE
R09Q-A_STATUS: CLOSED / ACCEPTED
R09Q-B_STATUS: CLOSED / ACCEPTED
R09Q-C_STATUS: CURRENT / AUTHORIZED — FORMAL CLOSURE ONLY

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
| V1-R09Q | Post-R09 Cross-Cutting Quality Gate | CURRENT — R09Q-A CLOSED / R09Q-B CLOSED / R09Q-C AUTHORIZED | Big Pickle (A) / Codex + Sol High (B) | GitHub Copilot Reviewer (A) / Copilot or independent strong reviewer (B) | MEDIUM | — |
| V1-R10 | UI/UX & Core App Experience | QUEUED | Big Pickle | TBD BY ARCHITECT | MEDIUM | — |
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

CURRENT_PHASE_ID: V1-R09Q
CURRENT_PHASE_TITLE: Post-R09 Cross-Cutting Quality Gate
CURRENT_PHASE_STATUS: CURRENT — R09Q-A CLOSED / ACCEPTED; R09Q-B CLOSED / ACCEPTED; R09Q-C CURRENT / AUTHORIZED
CURRENT_PHASE_CONTRACT: V1-R09Q-CONTRACT-v1
IMPLEMENTATION_AUTHORIZED: YES for R09Q-C formal closure only; R09Q-A and R09Q-B CLOSED

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

STATUS: CURRENT — R09Q-A CLOSED / ACCEPTED; R09Q-B CLOSED / ACCEPTED; R09Q-C
CURRENT / AUTHORIZED — FORMAL CLOSURE ONLY (see V1-R09Q Contract Freeze Record,
R09Q-A Formal Closure Record, and R09Q-B Formal Closure Record below)

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

V1-R09Q — Post-R09 Cross-Cutting Quality Gate (CURRENT — R09Q-A CLOSED /
ACCEPTED; R09Q-B CLOSED / ACCEPTED; R09Q-C CURRENT / AUTHORIZED — FORMAL
CLOSURE ONLY)

NEXT AFTER R09Q FULLY CLOSES:

V1-R10 — UI/UX & Core App Experience (QUEUED after V1-R09Q)

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
  V1-R09Q: CURRENT — R09Q-A CLOSED / ACCEPTED; R09Q-B CLOSED / ACCEPTED; R09Q-C CURRENT / AUTHORIZED
  V1-R10:  QUEUED after V1-R09Q

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
  R09Q-C:  CURRENT / AUTHORIZED — FORMAL CLOSURE ONLY
  V1-R09Q: CURRENT
  V1-R10:  QUEUED AFTER R09Q

R09Q-A and R09Q-B are formally closed. R09Q-C is now authorized as the final
formal closure slice; it must NOT introduce production code, tests, migrations,
security changes, UI work, or R10 implementation.
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
  R09Q-C:    CURRENT / AUTHORIZED — FORMAL CLOSURE ONLY
  V1-R09Q:   CURRENT
  V1-R10:    QUEUED AFTER R09Q

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
  R09Q-C:    CURRENT / AUTHORIZED — FORMAL CLOSURE ONLY
  V1-R09Q:   CURRENT
  V1-R10:    QUEUED AFTER R09Q

---

### R09Q-C Opening

Slice: R09Q-C — Formal Closure Only
Status: CURRENT / AUTHORIZED
Contract: V1-R09Q-CONTRACT-v1

R09Q-C purpose:
- reconcile final R09Q evidence from R09Q-A and R09Q-B;
- verify A and B closures are complete and accepted;
- confirm the permanent quality gate remains active;
- formally close V1-R09Q;
- authorize transition to V1-R10.

R09Q-C must NOT introduce:
- production code;
- tests;
- migrations;
- security changes;
- UI work;
- V1-R10 implementation.

Implementation authorized: YES — for documentation/closure only.
Preferred agent: Big Pickle.

Live state (ONE authoritative live roadmap state):
  V1-R09:    CLOSED / ACCEPTED
  R09Q-A:    CLOSED / ACCEPTED
  R09Q-B:    CLOSED / ACCEPTED
  R09Q-C:    CURRENT / AUTHORIZED — FORMAL CLOSURE ONLY
  V1-R09Q:   CURRENT
  V1-R10:    QUEUED AFTER R09Q
