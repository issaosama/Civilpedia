# CIVILPEDIA V1-R09Q — POST-R09 CROSS-CUTTING QUALITY GATE CONTRACT

PHASE: V1-R09Q
TITLE: Post-R09 Cross-Cutting Quality Gate
CONTRACT: V1-R09Q-CONTRACT-v1
STATUS: FROZEN — QUALITY CONTRACT FROZEN
IMPLEMENTATION_AUTHORIZED: NO — implementation of R09Q-A / R09Q-B begins only after Architect checkpoint approval of this freeze
MODE: DOCS ONLY for this freeze — no production code, no tests, no CI, no Supabase, no migration, no seed, no staging modified by this freeze

## 1. Authority and Purpose

This contract is the authoritative boundary for V1-R09Q, the Post-R09
Cross-Cutting Quality Gate that sits between formal V1-R09 closure and V1-R10.

V1-R09Q is NOT a feature phase. It is a cross-cutting quality verification gate:

- CI establishment;
- critical cross-feature smoke evidence;
- migration reproducibility evidence;
- targeted RLS/RPC positive + negative evidence;
- formal closure only where the gate actually passed.

It layers on the CLOSED V1-R09 program (V1-R09-CONTRACT-v1 + P2-A..P2-G
contracts) and on the accepted R08 auth/session authority. Everything already
accepted that this contract does not change remains in force. V1-R09Q claims
only its own authorized scope and does not re-verify already-verified R09
behavior as a fresh gate.

## 2. Baseline (persisted at freeze time)

Expected:

    HEAD == origin/main == 91e162553d9f67606ff0e4a081a6c31c159f8d40

Expected pre-existing dirty baseline ONLY (four paths; MUST NOT be touched,
reverted, formatted, or staged):

    M test/a5_6_profile_bootstrap_test.dart
    M test/v1_r08_cloud_profile_foundation_test.dart
    M test/v1_r08_profile_edit_screen_widget_test.dart
    ?? OpenCode_Usage_Report.txt

Inspection established at freeze time:

- `.github/workflows/` does not currently exist;
- migration 00001..00021 are present, ordered, unique, no numeric gaps;
- migration 00022 is absent;
- `supabase/config.toml` `[db.seed]` references `./seed.sql`;
- `supabase/seed.sql` is missing;
- no committed service-role secret exists (source references to `service_role`
  are rule/guard comments only);
- `test/v1_r06_profile_management_server_test.dart` contains assertions coupled
  to the OLD live roadmap state (V1-R09 CURRENT) — a TEST/EVIDENCE defect;
- authoritative repository Flutter metadata documents and matches:
  Flutter 3.32.8 stable / Dart 3.8.1 (`pubspec.yaml` `sdk: ^3.8.1`);
- historical report artifacts for some accepted R09 slices are absent or
  transitional; formal roadmap closure records + frozen contracts + accepted
  git commits + available acceptance evidence remain the authoritative closure
  trail.

## 3. R09Q Structure (frozen exactly)

- **R09Q-A — CI + Cross-Feature Smoke**
- **R09Q-B — Supabase Reproducibility + Security Evidence**
- **R09Q-C — FORMAL CLOSURE ONLY**

R09Q-C is documentation/closure, NOT a third implementation slice.

Implementer routing:

- R09Q-A preferred implementer: **Big Pickle**
- R09Q-B preferred implementer: **Codex / GPT-5.6 Sol High**

Reason: R09Q-B touches Supabase, migrations, RLS/RPC security evidence, and
local DB reproducibility and MUST NOT be implemented by a weaker routine agent
merely for convenience.

Reviewer routing:

- R09Q-A independent reviewer: **GitHub Copilot Civilpedia Reviewer**
- R09Q-B independent reviewer: **GitHub Copilot Civilpedia Reviewer** or another
  independent strong reviewer (security/backend sensitive).

## 4. Global R09Q Boundary

R09Q IS:

- cross-cutting quality verification;
- CI establishment;
- critical smoke evidence;
- migration reproducibility evidence;
- targeted RLS/RPC positive + negative evidence.

R09Q IS NOT:

- R10 UI redesign;
- R14 final backend readiness;
- R15 final security audit;
- R17 full E2E;
- performance/load testing;
- observability rollout;
- production deployment.

Production Flutter application code:

- NONE authorized by default.
- If a real production defect is discovered:
  STOP for Architect decision.

## 5. R09Q-A — CI Baseline

Freeze: establish ONE stable CI workflow.

Authorize ADD:

- `.github/workflows/flutter_quality.yml`
- `tool/quality_gate.ps1`

The exact workflow filename may be adjusted only if repository convention
requires it.

CI triggers:

- `pull_request`
- `push` to `main`
- `workflow_dispatch`

NO scheduled/nightly job in R09Q.

## 6. CI Environment

CI must:

1. checkout the repository;
2. install/setup the repository-compatible Flutter version (see §7);
3. run `flutter pub get` in the FRESH CI checkout;
4. execute the deterministic quality gate;
5. run selected suites sequentially.

The quality-gate script MUST run Flutter suites using:

    flutter test --no-pub <single-suite>

ONE SUITE AT A TIME.

Do NOT run test paths concurrently.

Reason: Civilpedia has a known NativeAssets `PathExistsException` risk under
parallel test execution.

Do NOT add analyzer to the required fast gate.
Do NOT add format enforcement.
Do NOT add Flutter build to the required R09Q fast gate.

Analyzer/build/nightly concerns remain later quality work unless separately
authorized.

## 7. CI Flutter Version (frozen)

Repository-supported authoritative Flutter version:

- **Flutter 3.32.8 (stable channel) / Dart 3.8.1**

Sources verified at freeze time:

- `pubspec.yaml`: `environment: sdk: ^3.8.1`;
- repository implementation/closure reports repeatedly document the evidence
  environment as Flutter 3.32.8 / Dart 3.8.1;
- the local repo working environment reports Flutter 3.32.8 stable / Dart 3.8.1.

CI MUST pin this version during R09Q-A. Do NOT silently use "latest".
If the pinned setup cannot reproduce this version, STOP for Architect decision.
No version was invented; this is the authoritative repository-compatible
version.

## 8. R09Q-A — Stale R06 Test Reconciliation

Inspection found: `test/v1_r06_profile_management_server_test.dart` contains
assertions coupled to old LIVE roadmap state such as V1-R09 CURRENT. This is a
TEST/EVIDENCE defect, not a production defect.

Authorize MODIFY:

- `test/v1_r06_profile_management_server_test.dart`

Required correction:

- remove dependence on mutable live roadmap status;
- preserve the original server-contract/security intent;
- assert durable accepted facts instead;
- prefer frozen contract/migration/RPC facts rather than CURRENT_PHASE text;
- no skip/delete/weaken;
- no production change.

Critical design rule:

- Do NOT create another test that will fail merely because the roadmap advances
  normally.
- Avoid repeating the V1-R06 live-state coupling defect.

## 9. R09Q-A — Cross-Feature Smoke

Authorize ADD:

- `test/v1_r09q_smoke_journeys_test.dart`

Keep ONE focused suite unless a hard technical reason requires separation.

### Journey A — RECOVERED AUTH CHAIN

Recovered authenticated session
-> correct identity restored
-> Profile bind/load seam
-> Business account-bound seam
-> Staff capability seam

Prove all three remain bound to the same authenticated identity. Do not
duplicate every provider unit test.

### Journey B — TRANSPORT-FLIP COEXISTENCE

transport unavailable
-> relevant R09 surfaces established
-> transport becomes available

Verify:

- Directory: eligible reconnect refresh exactly once.
- Profile: no automatic reconnect read.
- Business: no automatic reconnect read.
- Staff: no automatic reconnect read.
- Encyclopedia: no connectivity-driven content read.

Prove route/shell coexistence without reproducing P2-G wholesale.

### Journey C — SIGN-OUT

No new sign-out journey is required unless implementation reveals a seam not
already conclusively covered by C2/C3/P2-G.

## 10. R09Q-A — Selected CI Test List (frozen exact paths)

CI reuses only high-value clean committed evidence. Freeze the exact list
(verified present at freeze time except the explicitly flagged R09Q additions):

1. `test/v1_r09q_smoke_journeys_test.dart`  (R09Q-A ADD)
2. `test/v1_r09_p2_g_integrated_gate_test.dart`
3. `test/v1_r09_p2_shared_ux_test.dart`
4. `test/remote_operation_policy_test.dart`
5. `test/app_shell_test.dart`
6. `test/v1_r09_c2_sign_out_recovery_test.dart`
7. `test/v1_r09_c3_credential_exchange_quarantine_test.dart`
8. `test/v1_r09_p2_c_authenticated_profile_read_foundation_test.dart`
9. `test/v1_r08_auth_session_foundation_test.dart`
10. `test/v1_r08_router_auth_test.dart`
11. `test/auth_recovery_foundation_test.dart`
12. `test/auth_provider_test.dart`
13. `test/supabase_auth_gateway_test.dart`
14. `test/v1_r03_business_ownership_management_test.dart`
15. `test/v1_r06_profile_management_server_test.dart`  (R09Q-A MODIFY per §8)
16. `test/v1_r07_staff_operations_server_test.dart`
17. `test/v1_r07_staff_gateway_production_test.dart`
18. `test/v1_r09q_migration_lint_test.dart`  (R09Q-B ADD)
19. `test/v1_r09q_security_matrix_test.dart`  (R09Q-B ADD)

Rationale mapping:

- R09Q smoke journey suite (#1);
- P2-G integrated gate (#2);
- shared R09 transport UX (#3);
- remote operation policy (#4);
- AppShell (#5);
- committed clean auth/router/session recovery suites (#9-#13);
- C2 sign-out recovery (#6);
- C3 credential exchange quarantine (#7);
- appropriate P2-C foundation evidence (#8);
- directly relevant Business/Staff server-source/security suites (#14-#17);
- R09Q migration/security static suites (#18-#19).

Excluded (pre-existing dirty baseline — NOT CI truth for R09Q):

- `test/a5_6_profile_bootstrap_test.dart`
- `test/v1_r08_cloud_profile_foundation_test.dart`
- `test/v1_r08_profile_edit_screen_widget_test.dart`

Do NOT include the entire repository test set. This selected list is the full
required R09Q CI gate.

## 11. Full Suite Policy

- Required R09Q CI gate: SELECTED CROSS-CUTTING SUITES ONLY (§10).
- Full Flutter repository suite: NOT required to close R09Q.
- No nightly workflow is created in R09Q.
- The full suite remains optional/manual trend evidence until a later stable
  gate.
- V1-R17 remains the final comprehensive E2E gate.

## 12. R09Q-B — Migration Reproducibility

Current state (frozen):

- `supabase/migrations/00001..00021` — ordered, unique, no numeric gaps;
- migration 00022 currently absent;
- config references `./seed.sql`;
- `supabase/seed.sql` is missing.

Freeze mandatory correction:

- ADD `supabase/seed.sql`.

Purpose: make the existing configured seed path valid.

Requirements:

- intentionally minimal/no-op unless existing schema requires deterministic
  seed data for R09Q security smoke;
- do NOT add sample business/user production data merely for convenience;
- do NOT change migrations merely to fix the missing file reference;
- no existing migration modification is authorized.

## 13. Migration Lint Design

Authorize ADD: `test/v1_r09q_migration_lint_test.dart`.

Permanent assertions MUST verify:

- migration filenames use canonical numeric-prefix naming;
- numeric ordering is strictly increasing;
- migration numbers are unique;
- required historical migration files through the accepted baseline remain
  present;
- configured seed file path resolves to an existing source-controlled file;
- no accidental migration filename collision.

IMPORTANT:

- Do NOT permanently assert "migration 00022 must not exist" as a CI
  invariant. At R09Q freeze, 00022 is historically absent; future legitimate
  migrations MUST NOT make this permanent quality test stale.
- Avoid repeating the V1-R06 live-state coupling defect.

## 14. Static Security Matrix

Authorize ADD: `test/v1_r09q_security_matrix_test.dart`.

This is CI-safe source-level evidence. It MUST verify high-value durable
security invariants across current migrations (00001..00021):

- RLS enabled where required;
- ownership anchored to `auth.uid()`;
- protected direct UPDATE where intentionally revoked remains revoked;
- sensitive staff/audit/billing tables remain grant-protected;
- security-sensitive RPC execute grants are not exposed to `anon`;
- SECURITY DEFINER functions use a controlled `search_path`;
- relevant RPC authority uses authenticated actor/capability checks;
- internal helper functions intended to be non-callable remain revoked;
- no client/service-role bypass path is introduced.

Do NOT attempt exhaustive R15-level security auditing.

## 15. Runtime Local Supabase Security Smoke

R09Q-B MUST attempt REAL LOCAL database evidence (mandatory for R09Q closure
unless an environment blocker requires Architect decision).

First probe (READ ONLY):

- Supabase CLI availability/version;
- Docker/local runtime availability.

Do NOT install tools automatically.
Do NOT touch a linked/live/production project.
Only LOCAL Supabase is authorized.

If required tooling is unavailable:

- STOP R09Q-B and return exactly:
  `R09Q-B LOCAL SECURITY GATE REQUIRES ARCHITECT DECISION`
- do NOT silently defer runtime evidence to R14.

## 16. Local DB Reset

When local tooling is available, authorize:

    supabase db reset

ONLY against the local Supabase stack.

Purpose: prove source-controlled migrations + configured seed reproduce a clean
DB.

Never run reset against:

- linked remote project;
- staging remote database;
- production database.

Record:

- CLI version;
- local reset exit status;
- migration application success/failure;
- seed application success/failure.

## 17. Runtime Positive / Negative Security Scope

R09Q-B runtime DB evidence MUST remain SMALL — prove representative
enforcement, not every policy.

Required classes:

### A. PROFILE RLS
- Positive: authenticated User A can access the permitted own-profile operation.
- Negative: User B cannot access User A's protected profile row/operation.
- Negative: unauthenticated/anon cannot perform protected mutation.

### B. BUSINESS/APPLICATION AUTHORITY
- Positive: authorized applicant/owner can perform one representative permitted
  path.
- Negative: different authenticated user cannot mutate/read protected
  applicant-owned data where policy/RPC forbids it.

### C. STAFF AUTHORITY
- Positive: properly capable staff identity can invoke/read ONE representative
  staff path.
- Negative: ordinary authenticated user without capability is denied.

### D. RPC EXECUTE / AUTH
At least one protected SECURITY DEFINER mutation/read RPC must prove:

- authenticated authorized caller -> allowed;
- unauthenticated OR unauthorized caller -> denied.

Do NOT attempt exhaustive R15 matrix.

## 18. Runtime Security Test Artifact

During R09Q-B, inspect available Supabase local test conventions.

Preferred if supported cleanly:

- `supabase/tests/v1_r09q_security_smoke.sql`
  using the repository/local Supabase-supported SQL testing mechanism.

If pgTAP / `supabase test db` is already supported by the installed CLI,
prefer that.

If the repository/tooling cannot support this exact path without creating a
large framework:

- STOP and return Architect decision with the smallest alternative.
- Do NOT invent a broad bespoke DB test framework.

## 19. Security Test Data

Runtime security smoke may create LOCAL deterministic fixtures only.

- fixed non-production UUIDs / test identities;
- no real user data;
- no production credentials;
- no `service_role` in Flutter/client code;
- if privileged local SQL setup is needed solely to prepare fixtures, it must
  remain inside the local database test harness and never become application
  runtime behavior.

## 20. Service Role / Secrets

Inspection found no committed service-role secret.

Freeze permanent rule:

- no `service_role` in Flutter;
- no committed service-role key;
- no real credentials in tests;
- CI fast gate requires no Supabase secret;
- local Supabase security smoke uses the local test environment only.

If a committed real secret is discovered:
HIGH blocker — stop.

## 21. CI vs Local DB Gates

R09Q fast CI must remain deterministic without requiring hosted
Docker/Supabase unless implementation proves it stable with minimal complexity.

Required hosted CI:

- Flutter selected smoke/security-source tests;
- migration lint;
- static security matrix.

Required R09Q-B local acceptance evidence:

- local `supabase db reset`;
- representative positive/negative DB security smoke.

Do NOT automatically add a Docker/Supabase local stack to GitHub Actions in
R09Q (may be revisited in R14 if valuable).

## 22. Baseline Dirty Files

The three pre-existing dirty tests are explicitly OUT of R09Q implementation
and CI evidence:

- `test/a5_6_profile_bootstrap_test.dart`
- `test/v1_r08_cloud_profile_foundation_test.dart`
- `test/v1_r08_profile_edit_screen_widget_test.dart`

And:

- `OpenCode_Usage_Report.txt`

Do NOT modify. Do NOT revert. Do NOT format. Do NOT stage.

Do NOT use their local results as authoritative R09Q closure evidence.
Their drift requires separate future reconciliation if needed.

## 23. Observability

No observability implementation in R09Q.

Do NOT activate/configure Sentry or select any provider.

Defer to later backend/release readiness as already planned:

- crash reporting;
- production error visibility;
- critical journey analytics;
- release diagnostics.

## 24. File Boundaries

### R09Q-A (frozen)

Authorize ADD:

- `.github/workflows/flutter_quality.yml`
- `tool/quality_gate.ps1`
- `test/v1_r09q_smoke_journeys_test.dart`

Authorize MODIFY:

- `test/v1_r06_profile_management_server_test.dart`

Potential docs usage note: only if genuinely required by the frozen contract.

Production Flutter code: NONE.
If a production defect appears: STOP for Architect decision.

### R09Q-B (frozen)

Authorize ADD:

- `supabase/seed.sql`
- `test/v1_r09q_migration_lint_test.dart`
- `test/v1_r09q_security_matrix_test.dart`

Conditional ADD after tooling inspection:

- `supabase/tests/v1_r09q_security_smoke.sql`

No existing migration modification is authorized.
No RLS/policy/RPC/grant modification is authorized.

If runtime smoke exposes an actual security defect, STOP and return exactly:

    R09Q-B SECURITY DEFECT — ARCHITECT DECISION REQUIRED

### R09Q-C (frozen)

Documentation closure only after R09Q-A and R09Q-B acceptance. No
production/test/backend implementation. Records:

- CI baseline evidence;
- cross-feature smoke evidence;
- migration reproducibility evidence;
- static security matrix evidence;
- local Supabase reset evidence;
- runtime positive/negative security smoke evidence;
- any explicit environment limitations;
- independent reviews.

Closure state after acceptance:

    V1-R09Q CLOSED
    V1-R10 NEXT / AUTHORIZABLE

## 25. Implementer / Reviewer Policy

- R09Q-A: implementer Big Pickle; independent reviewer GitHub Copilot
  Civilpedia Reviewer.
- R09Q-B: implementer Codex / GPT-5.6 Sol High; independent reviewer GitHub
  Copilot Civilpedia Reviewer or another independent strong reviewer.
- R09Q-B (security/backend sensitive) MUST NOT be done by a weaker routine
  agent merely for convenience.
- No simultaneous A/B implementation.

## 26. Closure Blockers

### HIGH

- unauthorized data access discovered;
- stale authenticated data crosses identity;
- ownership/staff authority bypass;
- committed service-role secret;
- local clean DB cannot reproduce required schema because of an actual
  migration defect;
- runtime security smoke demonstrates RLS/RPC bypass.

### MEDIUM

- CI fast gate absent or non-deterministic;
- stale R06 roadmap coupling not reconciled;
- required cross-feature smoke evidence missing;
- migration lint / static security matrix incomplete;
- seed/config reproducibility mismatch unresolved;
- local DB reset not proven when tooling is available;
- required representative positive/negative runtime security evidence missing;
- selected CI suite failure.

### LOW

- non-functional CI naming/readability;
- historical docs wording;
- optional full-suite/nightly absence;
- analyzer not included in the R09Q gate.

HIGH/MEDIUM: R09Q cannot close.

## 27. Execution Order

1. Contract docs checkpoint (this freeze).
2. R09Q-A implementation.
3. R09Q-A independent review + checkpoint.
4. R09Q-B implementation using Codex / GPT-5.6 Sol High.
5. R09Q-B independent security review + checkpoint.
6. R09Q-C formal closure.
7. V1-R10 becomes NEXT.

No simultaneous A/B implementation.

## 28. Git Safety

After contract freeze:

    git diff --check
    git status --short
    git diff --name-only
    git diff --cached --name-only
    git rev-parse HEAD
    git rev-parse origin/main

Expected:

- HEAD == origin/main == 91e162553d9f67606ff0e4a081a6c31c159f8d40;
- expected docs changes only:
  - `docs/architecture/contracts/V1-R09Q_CROSS_CUTTING_QUALITY_GATE_CONTRACT.md`
  - `docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md`
- nothing staged, committed, or pushed;
- four baseline paths untouched.

## 29. Required Response

Report format is frozen in §31 of the Architect freeze instruction
(`# Civilpedia V1-R09Q — Quality Contract Freeze Report`). Result decision is
exactly one of:

    R09Q QUALITY CONTRACT FROZEN — READY FOR ARCHITECT CHECKPOINT

or

    R09Q CONTRACT FREEZE REQUIRES ARCHITECT DECISION

---

## Appendix A — Inspection Evidence (accepted at R09Q freeze)

- `.github/workflows/` absent; `tool/` absent.
- `supabase/migrations/` contains exactly 00001..00021 (no gaps, unique,
  ordered); 00022 absent.
- `supabase/config.toml` `[db.seed]`: `enabled = true`,
  `sql_paths = ["./seed.sql"]`; `supabase/seed.sql` does NOT exist.
- No committed service-role secret: every tracked `service_role` occurrence in
  `lib/**/*.dart` is a documentation/guard comment stating the "never use
  service_role" rule.
- `test/v1_r06_profile_management_server_test.dart` test
  "contract is frozen and roadmap records V1-R06 as closed" asserts live
  roadmap strings: `CURRENT_PHASE_ID: V1-R09`,
  `CURRENT_PHASE_CONTRACT: V1-R09-CONTRACT-v1`,
  `IMPLEMENTATION_AUTHORIZED: YES`, and
  `| V1-R09 | Offline / Connectivity / Error Hardening | CURRENT |` — the
  TEST/EVIDENCE defect authorized for reconciliation in §8.
- Flutter version authority: `pubspec.yaml` `sdk: ^3.8.1`; reports document
  "Flutter 3.32.8 / Dart 3.8.1"; local environment reports Flutter 3.32.8
  stable / Dart 3.8.1.
- P2-G frozen transport/identity policy remains in force: Directory is the ONLY
  reconnect generation-gated feature; Profile/Business/Staff manual retry only;
  Encyclopedia has no connectivity-driven read.

## Appendix B — Roadmap Live State (as updated by this freeze)

    V1-R09:    CLOSED
    V1-R09Q:   CURRENT — QUALITY CONTRACT FROZEN (implementation NOT authorized)
    V1-R10:    QUEUED AFTER R09Q

V1-R09Q is NOT marked implemented by this freeze.
IMPLEMENTATION_AUTHORIZED remains NO until the Architect checkpoint.