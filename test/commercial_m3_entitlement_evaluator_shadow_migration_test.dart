import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// Hand-authored accepted M3 interface and boundary expectations.
// PostgreSQL, API and runner atomicity are separate mandatory gates.
const _migration =
    'supabase/migrations/00025_commercial_entitlement_evaluator_shadow.sql';
const _m3FormalClosure =
    '\n'
    r'''# COMMERCIAL TRACK CURRENT CONTROL

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
''';
const _cui1Authorization =
    '\n'
    r'''# COMMERCIAL CUI-1 IMPLEMENTATION AUTHORIZATION — 2026-10-05

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
''';
bool _matchesCui1Roadmap(String actual, String closedCheckpoint) =>
    actual == closedCheckpoint + _cui1Authorization;

String _read(String p) => File(p).readAsStringSync().replaceAll('\r\n', '\n');
String _git(List<String> args) {
  final r = Process.runSync(
    'git',
    args,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (r.exitCode != 0) throw StateError(r.stderr.toString());
  return r.stdout.toString().replaceAll('\r\n', '\n');
}

String _body(String source, String name) {
  final m = RegExp(
    'CREATE FUNCTION commercial_private\\.' +
        name +
        r'\([^;]*?AS (\$[A-Za-z_0-9]*\$)([\s\S]*?)\1;',
    caseSensitive: false,
  ).firstMatch(source);
  if (m == null) throw StateError('Missing exact function ' + name);
  return m.group(2)!;
}

List<String> _returns(String source, String name) {
  final m = RegExp(
    'CREATE FUNCTION commercial_private\\.' +
        name +
        r'\([^;]*?RETURNS TABLE\s*\(([\s\S]*?)\)\s*LANGUAGE',
  ).firstMatch(source)!;
  return m
      .group(1)!
      .split(',')
      .map((s) => s.trim().replaceAll(RegExp(r'\s+'), ' '))
      .toList();
}

// CUI-1 composition: fixed historical evidence plus only the frozen UI delta.
const _cui1GovernanceCommit = '5d511256a4364a3226383c2a631d70bef02ecba6';
const _cui1ContractCommit = '889ff1da4389ba891247cfb5497554ca98fa58b3';
const _cui1BaselineCommit = '47096d45b98853af97ab5f3333b1b62b045dad81';
const _cui1RoadmapPath = 'docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md';
const _cui1ContractPath =
    'docs/architecture/contracts/'
    'CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md';
const _cui1ProductionPaths = <String>{
  'lib/features/directory/presentation/directory_landing_screen.dart',
  'lib/features/directory/presentation/directory_search_screen.dart',
  'lib/features/directory/presentation/directory_provider_card.dart',
  'lib/features/directory/presentation/directory_provider_detail_screen.dart',
  'lib/features/directory/presentation/directory_verification_badge.dart',
  'lib/features/directory/presentation/widgets/directory_sponsored_provider_card.dart',
  'lib/localization/ar.dart',
  'lib/localization/en.dart',
};
// Separate exact test boundaries and incoming dirty artifacts, never lib/docs
// prefixes. Preservation of incoming dirty bytes is independently checked.
const _cui1NonProductionPaths = <String>{
  'test/commercial_harden1_public_plans_exposure_migration_test.dart',
  'test/commercial_m1b_catalog_reference_data_migration_test.dart',
  'test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart',
  'test/commercial_cui1_business_experience_foundation_widget_test.dart',
  'test/w5_2_directory_landing_test.dart',
  'test/w5_3_directory_search_screen_test.dart',
  'test/w5_4_directory_provider_card_test.dart',
  'test/w5_4_directory_provider_detail_screen_test.dart',
  'test/w5_5_verification_display_test.dart',
  'test/a5_6_profile_bootstrap_test.dart',
  'test/v1_r08_cloud_profile_foundation_test.dart',
  'test/v1_r08_profile_edit_screen_widget_test.dart',
  'OpenCode_Usage_Report.txt',
  'artifacts/r10_4a/home_dark.png',
  'artifacts/r10_4a/home_light.png',
};
bool _allowsCui1Composition(
  Iterable<String> changedPaths,
  String roadmap,
  String committedRoadmap, {
  String governanceCommit = _cui1GovernanceCommit,
  String contractCommit = _cui1ContractCommit,
  String baselineCommit = _cui1BaselineCommit,
}) =>
    governanceCommit == '5d511256a4364a3226383c2a631d70bef02ecba6' &&
    contractCommit == '889ff1da4389ba891247cfb5497554ca98fa58b3' &&
    baselineCommit == '47096d45b98853af97ab5f3333b1b62b045dad81' &&
    committedRoadmap.endsWith(_cui1Authorization) &&
    roadmap == committedRoadmap &&
    changedPaths
        .where((path) => !_cui1NonProductionPaths.contains(path))
        .every(_cui1ProductionPaths.contains);

List<String> _cui1ChangedPaths(String output) =>
    output.trim().isEmpty ? <String>[] : output.trim().split('\n');

void _registerCui1CompatibilityTests({bool roadmapControlsCovered = false}) {
  // A committed, fixed input; never a snapshot of the current working tree.
  final committedRoadmap = _git([
    'show',
    '$_cui1GovernanceCommit:$_cui1RoadmapPath',
  ]);
  test(
    'CUI-1 composed delta pins authorities and rejects unrelated live drift',
    () {
      expect(
        _git(['merge-base', _cui1ContractCommit, _cui1BaselineCommit]).trim(),
        _cui1ContractCommit,
      );
      expect(
        _git(['merge-base', _cui1BaselineCommit, _cui1GovernanceCommit]).trim(),
        _cui1BaselineCommit,
      );
      // Baseline repair and governance were both production/backend-free.
      expect(
        _git([
          'diff',
          '--name-only',
          _cui1ContractCommit,
          _cui1BaselineCommit,
          '--',
          'lib',
          'docs',
          'supabase',
        ]).trim(),
        isEmpty,
      );
      expect(
        _git([
          'diff',
          '--name-only',
          _cui1BaselineCommit,
          _cui1GovernanceCommit,
          '--',
          'lib',
          'supabase',
        ]).trim(),
        isEmpty,
      );
      expect(
        _read(_cui1ContractPath),
        _git(['show', '$_cui1ContractCommit:$_cui1ContractPath']),
      );
      final paths = <String>[
        ..._cui1ChangedPaths(
          _git(['diff', '--name-only', '--no-renames', _cui1GovernanceCommit]),
        ),
        ..._cui1ChangedPaths(
          _git(['ls-files', '--others', '--exclude-standard']),
        ),
      ];
      expect(
        _allowsCui1Composition(
          paths,
          _read(_cui1RoadmapPath),
          committedRoadmap,
        ),
        isTrue,
        reason: 'Exact CUI-1 production/test paths only: $paths',
      );
    },
  );
  test('CUI-1 composition accepts empty and each of the frozen eight paths', () {
    // Independently fixed positive cases also catch an accidentally narrowed
    // or expanded implementation set; the negative cases catch a ninth path.
    const expected = <String>[
      'lib/features/directory/presentation/directory_landing_screen.dart',
      'lib/features/directory/presentation/directory_search_screen.dart',
      'lib/features/directory/presentation/directory_provider_card.dart',
      'lib/features/directory/presentation/directory_provider_detail_screen.dart',
      'lib/features/directory/presentation/directory_verification_badge.dart',
      'lib/features/directory/presentation/widgets/directory_sponsored_provider_card.dart',
      'lib/localization/ar.dart',
      'lib/localization/en.dart',
    ];
    expect(_cui1ProductionPaths, expected.toSet());
    expect(
      _allowsCui1Composition([], committedRoadmap, committedRoadmap),
      isTrue,
    );
    for (final path in expected) {
      expect(
        _allowsCui1Composition([path], committedRoadmap, committedRoadmap),
        isTrue,
        reason: path,
      );
    }
    expect(
      _allowsCui1Composition(expected, committedRoadmap, committedRoadmap),
      isTrue,
    );
  });
  test(
    'CUI-1 composition rejects exact out-of-scope production and document paths',
    () {
      const denied = <String>[
        'lib/features/directory/presentation/ninth.dart',
        'lib/features/directory/presentation/providers/directory_provider.dart',
        'lib/features/directory/data/supabase_directory_read_gateway.dart',
        'lib/features/directory/domain/cloud_directory_repository.dart',
        'lib/features/directory/domain/canonical_directory_entity.dart',
        'lib/routes/app_router.dart',
        'lib/routes/app_routes.dart',
        'lib/core/di/app_dependencies.dart',
        'lib/core/theme/app_colors.dart',
        'supabase/functions/new_public_authority/index.ts',
        'supabase/config.toml',
        'supabase/seed.sql',
        'supabase/tests/commercial_m3_entitlement_evaluator_shadow_test.sql',
        'supabase/migrations/00026_unauthorized.sql',
        'lib/features/profile/presentation/profile_screen.dart',
        'lib/localization/fr.dart',
        'lib/localization/ar.dart.bak',
        'docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md',
        'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md',
        'docs/unrelated.md',
        'assets/unauthorized.png',
        'pubspec.yaml',
        'test/unrelated_test.dart',
        'test/w7_2_directory_sponsored_search_screen_test.dart',
        'test/v1_r09_p2_b_directory_ux_test.dart',
        'artifacts/unrelated.png',
      ];
      for (final path in denied) {
        expect(
          _allowsCui1Composition(
            ['lib/localization/ar.dart', path],
            committedRoadmap,
            committedRoadmap,
          ),
          isFalse,
          reason: path,
        );
      }
    },
  );
  test(
    'CUI-1 composition rejects substituted contract, baseline and governance commits',
    () {
      const wrong = '0000000000000000000000000000000000000000';
      expect(
        _allowsCui1Composition(
          [],
          committedRoadmap,
          committedRoadmap,
          contractCommit: wrong,
        ),
        isFalse,
      );
      expect(
        _allowsCui1Composition(
          [],
          committedRoadmap,
          committedRoadmap,
          baselineCommit: wrong,
        ),
        isFalse,
      );
      expect(
        _allowsCui1Composition(
          [],
          committedRoadmap,
          committedRoadmap,
          governanceCommit: wrong,
        ),
        isFalse,
      );
    },
  );
  // M3 already has exact live-roadmap controls for these cases. Retain them
  // instead of registering duplicate rejection tests in that suite.
  if (!roadmapControlsCovered) {
    test(
      'CUI-1 composition rejects unauthorized governance and historical drift',
      () {
        const mutations = <String, String>{
          'M4_STATE: NOT AUTHORIZED': 'M4_STATE: AUTHORIZED',
          'M5_STATE: NOT AUTHORIZED': 'M5_STATE: AUTHORIZED',
          '`IMPLEMENTATION_AUTHORIZED: NO`, implementation NOT STARTED':
              '`IMPLEMENTATION_AUTHORIZED: YES`, implementation STARTED',
          'PUBLIC_BACKEND_AUTHORITY_DELTA: ZERO':
              'PUBLIC_BACKEND_AUTHORITY_DELTA: NONZERO',
          'COMMERCIAL_AUTHORITY_DELTA: ZERO':
              'COMMERCIAL_AUTHORITY_DELTA: NONZERO',
          'COMMERCIAL_CONTRACT: docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md':
              'COMMERCIAL_CONTRACT: docs/architecture/contracts/ARBITRARY.md',
          'ROADMAP_VERSION: 1': 'ROADMAP_VERSION: 2',
        };
        for (final mutation in mutations.entries) {
          expect(committedRoadmap, contains(mutation.key));
          expect(
            _allowsCui1Composition(
              [],
              committedRoadmap.replaceFirst(mutation.key, mutation.value),
              committedRoadmap,
            ),
            isFalse,
            reason: mutation.key,
          );
        }
      },
    );
  }
}

void main() {
  _registerCui1CompatibilityTests(roadmapControlsCovered: true);
  final source = _read(_migration);
  test('00025 unique additive suffix; all predecessor migrations byte exact', () {
    final names =
        Directory('supabase/migrations')
            .listSync()
            .whereType<File>()
            .map((f) => f.uri.pathSegments.last)
            .toList()
          ..sort();
    expect(names, hasLength(25));
    expect(names.last, '00025_commercial_entitlement_evaluator_shadow.sql');
    for (var i = 0; i < 24; i++) {
      expect(
        names[i].startsWith('${(i + 1).toString().padLeft(5, '0')}_'),
        isTrue,
      );
      expect(
        _read('supabase/migrations/${names[i]}'),
        _git([
          'show',
          '7d1d671e7b837be8b1ffed55116aa495d4922eb5:supabase/migrations/${names[i]}',
        ]),
      );
    }
  });
  test(
    'exactly two tables, four functions, one index; no other new object',
    () {
      expect(
        RegExp(
          r'^CREATE TABLE commercial_private\.(\w+)',
          multiLine: true,
        ).allMatches(source).map((m) => m.group(1)).toList(),
        ['m3_shadow_heads', 'm3_shadow_runs'],
      );
      expect(
        RegExp(
          r'^CREATE FUNCTION commercial_private\.(\w+)',
          multiLine: true,
        ).allMatches(source).map((m) => m.group(1)).toSet(),
        {
          'm3_evaluate_entitlement_v1',
          'm3_evaluate_publication_v1',
          'm3_generation_matches_v1',
          'm3_capture_shadow_v1',
        },
      );
      expect(
        RegExp(r'^CREATE INDEX ', multiLine: true).allMatches(source),
        hasLength(1),
      );
      expect(
        RegExp(
          r'^CREATE\s+(VIEW|TYPE|ROLE|TRIGGER|POLICY|SCHEMA|SEQUENCE)\b',
          multiLine: true,
          caseSensitive: false,
        ).hasMatch(source),
        isFalse,
      );
      expect(
        RegExp(
          r'^GRANT\b',
          multiLine: true,
          caseSensitive: false,
        ).hasMatch(source),
        isFalse,
      );
    },
  );
  test('m3_evaluate_entitlement_v1 exact ordered typed interface', () {
    expect(_returns(source, 'm3_evaluate_entitlement_v1'), <String>[
      'envelope_kind text',
      'input_version text',
      'evaluator_version text',
      'calendar_rule_version text',
      'entity_id uuid',
      'source_origin text',
      'as_of timestamptz',
      'input_revision text',
      'synthetic_provider_revision bigint',
      'authority_outcome text',
      'basis_context text',
      'source_kind text',
      'entitlement_outcome text',
      'enforcement_context text',
      'enforcement_revision bigint',
      'continuity_eligible boolean',
      'agreement_id uuid',
      'term_id uuid',
      'grant_id uuid',
      'plan_id uuid',
      'plan_version_id uuid',
      'plan_version bigint',
      'bundle_version_id uuid',
      'bundle_version bigint',
      'registry_version bigint',
      'snapshot_revision text',
      'original_start timestamptz',
      'original_end timestamptz',
      'effective_end timestamptz',
      'grace_end timestamptz',
      'prior_publication_event_id uuid',
      'capabilities jsonb',
      'next_boundary timestamptz',
      'reason_codes text[]',
      'result_fingerprint text',
    ]);
  });
  test('m3_evaluate_publication_v1 exact ordered typed interface', () {
    expect(_returns(source, 'm3_evaluate_publication_v1'), <String>[
      'input_version text',
      'evaluator_version text',
      'calendar_rule_version text',
      'entity_id uuid',
      'source_origin text',
      'as_of timestamptz',
      'synthetic_provider_revision bigint',
      'entitlement_input_revision text',
      'publication_input_revision text',
      'authority_outcome text',
      'entitlement_outcome text',
      'enforcement_context text',
      'verification_requirement text',
      'verification_state text',
      'intrinsic_readiness text',
      'candidate_first_publication_ready boolean',
      'continuity_eligible boolean',
      'discoverability_outcome text',
      'gate_results jsonb',
      'authority_revision bigint',
      'projection_revision bigint',
      'authoritative_generation bigint',
      'candidate_generation bigint',
      'generation_matches boolean',
      'legacy_visible boolean',
      'comparison_target text',
      'comparison_result text',
      'mismatch_category text',
      'reason_codes text[]',
    ]);
  });
  test('m3_capture_shadow_v1 exact ordered typed interface', () {
    expect(_returns(source, 'm3_capture_shadow_v1'), <String>[
      'capture_status text',
      'is_historical boolean',
      'request_id uuid',
      'entity_id uuid',
      'expected_shadow_generation bigint',
      'shadow_generation bigint',
      'source_origin text',
      'input_version text',
      'evaluator_version text',
      'calendar_rule_version text',
      'observed_at timestamptz',
      'recorded_at timestamptz',
      'input_fingerprint text',
      'entitlement_input_revision text',
      'publication_input_revision text',
      'legacy_visible boolean',
      'authority_outcome text',
      'entitlement_outcome text',
      'publication_outcome text',
      'comparison_target text',
      'comparison_result text',
      'mismatch_category text',
      'authority_revision bigint',
      'projection_revision bigint',
      'authoritative_generation bigint',
      'candidate_generation bigint',
      'reason_codes text[]',
      'result_summary jsonb',
    ]);
  });
  test('four invoker functions, exact volatility and fixed safe path', () {
    expect(
      RegExp(
        r'LANGUAGE (?:plpgsql|sql) (?:IMMUTABLE|VOLATILE) SECURITY INVOKER\nSET search_path = commercial_private, pg_temp',
      ).allMatches(source),
      hasLength(4),
    );
    expect(source.contains('SECURITY DEFINER'), isFalse);
    expect(
      RegExp(r'LANGUAGE (?:sql|plpgsql) IMMUTABLE').allMatches(source),
      hasLength(3),
    );
    expect(
      RegExp(r'LANGUAGE plpgsql VOLATILE').allMatches(source),
      hasLength(1),
    );
    for (final fn in [
      'm3_evaluate_entitlement_v1(jsonb,timestamptz)',
      'm3_evaluate_publication_v1(jsonb,jsonb,timestamptz)',
      'm3_generation_matches_v1(bigint,bigint,bigint,bigint)',
      'm3_capture_shadow_v1(uuid,uuid,bigint)',
    ]) {
      expect(
        source,
        contains(
          'REVOKE ALL ON FUNCTION commercial_private.$fn FROM PUBLIC,anon,authenticated,service_role;',
        ),
      );
    }
  });
  for (final fn in [
    'm3_evaluate_entitlement_v1',
    'm3_evaluate_publication_v1',
  ]) {
    test('$fn pure deterministic boundary', () {
      final body = _body(source, fn);
      final executable = body.replaceAll(
        RegExp(r"'(?:''|[^'])*'|--[^\n]*|/\*[\s\S]*?\*/"),
        "",
      );
      expect(
        RegExp(
          r'\b(INSERT|UPDATE|DELETE|TRUNCATE|GRANT|REVOKE|set_config|clock_timestamp|now)\b',
          caseSensitive: false,
        ).hasMatch(executable),
        isFalse,
      );
      expect(
        RegExp(
          r'\bFROM\s+(public|auth|commercial_private)\.',
          caseSensitive: false,
        ).hasMatch(executable),
        isFalse,
      );
      expect(
        RegExp(r'WHEN\s+OTHERS\b', caseSensitive: false).hasMatch(executable),
        isFalse,
      );
      expect(body, contains('extensions.digest'));
      expect(body, contains('pg_catalog.jsonb_each'));
      expect(body, contains('INPUT_REVISION_MISMATCH'));
    });
  }
  test(
    'capture writes private observations only; lookup precedes stale rejection',
    () {
      final b = _body(source, 'm3_capture_shadow_v1');
      expect(
        b.indexOf(
          'FROM commercial_private.m3_shadow_runs r WHERE r.request_id=p_request_id',
        ),
        lessThan(b.indexOf("ERRCODE='P3STA'")),
      );
      expect(
        b,
        contains(
          "pg_catalog.current_setting('transaction_isolation')<>'repeatable read'",
        ),
      );
      for (final code in ['P3ARG', 'P3CTX', 'P3REF', 'P3MIS', 'P3STA', 'P3COR'])
        expect(b, contains("ERRCODE='$code'"));
      expect(
        RegExp(
          r'\b(INSERT INTO|UPDATE|DELETE FROM)\s+(public|auth)\.',
          caseSensitive: false,
        ).hasMatch(b),
        isFalse,
      );
      expect(
        b,
        contains('FROM public.directory_entities d WHERE d.id=p_entity_id;'),
      );
      expect(
        b,
        contains('ON CONFLICT ON CONSTRAINT m3_shadow_heads_pkey DO NOTHING'),
      );
      expect(b, contains('server_wall_after_shadow_lock'));
      expect(
        RegExp(r'SELECT\s+[ep]\.\*', caseSensitive: false).hasMatch(b),
        isFalse,
      );
    },
  );
  test('runner owns transaction and persistence remains redacted', () {
    expect(
      RegExp(
        r'^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT)\s*;',
        multiLine: true,
        caseSensitive: false,
      ).hasMatch(source),
      isFalse,
    );
    expect(source.contains('transaction=false'), isFalse);
    expect(source, contains('m3_shadow_runs_summary_check'));
    expect(source, contains('m3_shadow_runs_runtime_check'));
    expect(source, contains('m3.entry_metadata'));
    expect(source, contains('m3.entry_data'));
    expect(source, contains('ON UPDATE RESTRICT ON DELETE RESTRICT'));
  });
  test('integer JSON cannot bypass validated numeric conversion', () {
    for (final fn in [
      'm3_evaluate_entitlement_v1',
      'm3_evaluate_publication_v1',
    ]) {
      final body = _body(source, fn);
      expect(
        RegExp(r"\((?:v_term|v_auth|v_ext|v_item|v_out|p_publication_input)\s*->>\s*'[^']+'\)::(?:bigint|integer)")
            .hasMatch(body),
        isFalse,
        reason: 'Integral JSON decimal spellings require numeric conversion',
      );
    }
    final sql = _read(
      'supabase/tests/commercial_m3_entitlement_evaluator_shadow_test.sql',
    );
    for (final marker in [
      'integral representation',
      'invalid integral domain',
      'mixed decimal extension revisions',
      'fixture ALLOW requires',
      'proxy regex positive detection control',
      'frozen Boolean',
      'publication before activation',
      'blocked verification survives applicability',
    ]) {
      expect(sql, contains(marker));
    }
  });
  test(
    'contract and roadmap retain committed authority; zero production/config delta',
    () {
      const roadmapPath = 'docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md';
      final authorizedRoadmap = _git([
        'show',
        '7d1d671e7b837be8b1ffed55116aa495d4922eb5:$roadmapPath',
      ]);
      // Keep every historical byte; only the exact additive CUI-1 record is new.
      final closedCheckpoint = authorizedRoadmap.replaceFirst(
            '# COMMERCIAL TRACK CURRENT CONTROL',
            '# COMMERCIAL TRACK HISTORICAL M3 AUTHORIZATION',
          ) +
          _m3FormalClosure;
      expect(
        _matchesCui1Roadmap(_read(roadmapPath), closedCheckpoint),
        isTrue,
      );
      const cui1ContractPath =
          'docs/architecture/contracts/'
          'CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md';
      expect(
        _read(cui1ContractPath),
        _git(['show', '889ff1da4389ba891247cfb5497554ca98fa58b3:$cui1ContractPath']),
      );
      for (final path in [
        'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_M3_ENTITLEMENT_EVALUATOR_SHADOW_IMPLEMENTATION_CONTRACT_V1.md',
        'supabase/config.toml',
        'supabase/seed.sql',
      ]) {
        expect(
          _read(path),
          _git(['show', '7d1d671e7b837be8b1ffed55116aa495d4922eb5:$path']),
        );
      }
      expect(
        _git([
          'diff',
          '--name-only',
          '7d1d671e7b837be8b1ffed55116aa495d4922eb5',
          _cui1GovernanceCommit,
          '--',
          'lib',
          'docs',
          'supabase/config.toml',
          'supabase/seed.sql',
        ]).trim().split('\n')..sort(),
        [roadmapPath, cui1ContractPath]..sort(),
      );
    },
  );
  // Mutations stay in memory: use the same exact guard as the live roadmap gate.
  for (final mutation in <String, List<String>>{
    'M4 authorization': ['M4_STATE: NOT AUTHORIZED', 'M4_STATE: AUTHORIZED'],
    'M5 authorization': ['M5_STATE: NOT AUTHORIZED', 'M5_STATE: AUTHORIZED'],
    'next commercial slice': [
      'COMMERCIAL_CURRENT_SLICE: CUI-1 — Commercial Business Experience Foundation',
      'COMMERCIAL_CURRENT_SLICE: CUI-2 — Arbitrary next slice',
    ],
    'ordinary R10.5-D implementation': [
      '`IMPLEMENTATION_AUTHORIZED: NO`, implementation NOT STARTED',
      '`IMPLEMENTATION_AUTHORIZED: YES`, implementation STARTED',
    ],
    'contract substitution': [
      'COMMERCIAL_CONTRACT: docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md',
      'COMMERCIAL_CONTRACT: docs/architecture/contracts/ARBITRARY_CONTRACT.md',
    ],
    'contract commit': [
      'CONTRACT_COMMIT: 889ff1da4389ba891247cfb5497554ca98fa58b3',
      'CONTRACT_COMMIT: 0000000000000000000000000000000000000000',
    ],
    'baseline-fix commit': [
      'CUI1_PREIMPLEMENTATION_BASELINE_COMMIT: 47096d45b98853af97ab5f3333b1b62b045dad81',
      'CUI1_PREIMPLEMENTATION_BASELINE_COMMIT: 0000000000000000000000000000000000000000',
    ],
    'ninth production path': [
      'lib/localization/en.dart\n```',
      'lib/localization/en.dart\nlib/features/directory/presentation/ninth.dart\n```',
    ],
    'backend authority expansion': [
      'PUBLIC_BACKEND_AUTHORITY_DELTA: ZERO',
      'PUBLIC_BACKEND_AUTHORITY_DELTA: NONZERO',
    ],
    'provider authority expansion': [
      'Any provider/domain/repository change requires STOP',
      'Any provider/domain/repository change is authorized',
    ],
  }.entries) {
    test('CUI-1 governance rejects ${mutation.key}', () {
      const path = 'docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md';
      final closedCheckpoint = _git([
        'show', '798b2af358735e871463790e746c8f5761fbb989:$path',
      ]);
      expect(_matchesCui1Roadmap(closedCheckpoint + _cui1Authorization, closedCheckpoint), isTrue);
      expect(_cui1Authorization, contains(mutation.value.first));
      final changedRecord = _cui1Authorization.replaceFirst(
        mutation.value.first, mutation.value.last,
      );
      expect(_matchesCui1Roadmap(closedCheckpoint + changedRecord, closedCheckpoint), isFalse);
    });
  }
  test('CUI-1 governance rejects unrelated historical roadmap mutation', () {
    const path = 'docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md';
    final closedCheckpoint = _git([
      'show', '798b2af358735e871463790e746c8f5761fbb989:$path',
    ]);
    expect(closedCheckpoint, contains('ROADMAP_VERSION: 1'));
    expect(_matchesCui1Roadmap(
      closedCheckpoint.replaceFirst('ROADMAP_VERSION: 1', 'ROADMAP_VERSION: 2') + _cui1Authorization,
      closedCheckpoint,
    ), isFalse);
  });
  test(
    'SQL gate carries explicit clarification cases and rolls fixtures back',
    () {
      final sql = _read(
        'supabase/tests/commercial_m3_entitlement_evaluator_shadow_test.sql',
      );
      for (final marker in [
        'OQ-84',
        'POLICY_DEPENDENCY_BLOCKED',
        'MISSING_REQUIRED_FIELD',
        'INVALID_FIELD_TYPE',
        'INVALID_ENUM',
        'BINDING_MISMATCH',
        'STALE_GENERATION',
        'historical replay',
        'paid unverified',
      ])
        expect(sql, contains(marker));
      expect(sql, contains('SELECT * FROM finish();'));
      expect(sql.trimRight(), endsWith('ROLLBACK;'));
    },
  );
}
