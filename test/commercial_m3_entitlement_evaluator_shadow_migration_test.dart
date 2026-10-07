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
bool _matchesCui1Roadmap(String actual, String closedCheckpoint, {
  bool includeFrozenGovernance = false,
}) =>
    actual == closedCheckpoint + _cui1Authorization + _cui1MediaReconciliation +
        (includeFrozenGovernance ? _currentRoadmapAdditions : '');

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
const _cui1MediaCommit = 'f94e96c2c510a6cef25f9f491163c5ce4f9320bb';
const _cui1MediaAddendumPath =
    'docs/architecture/contracts/'
    'CIVILPEDIA_COMMERCIAL_CUI1_AUTHORITATIVE_MEDIA_ADDENDUM_V1.md';
const _cui1MediaReconciliation =
    '\n'
    r"""# COMMERCIAL CUI-1 MEDIA AUTHORITY RECONCILIATION — 2026-10-06

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
""";
const _cui1RoadmapPath = 'docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md';
const _cui1ContractPath =
    'docs/architecture/contracts/'
    'CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md';
const _cui1DocumentPaths = <String>{_cui1RoadmapPath, _cui1MediaAddendumPath};
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
  String mediaCommit = _cui1MediaCommit,
}) =>
    governanceCommit == '5d511256a4364a3226383c2a631d70bef02ecba6' &&
    contractCommit == '889ff1da4389ba891247cfb5497554ca98fa58b3' &&
    baselineCommit == '47096d45b98853af97ab5f3333b1b62b045dad81' &&
    mediaCommit == 'f94e96c2c510a6cef25f9f491163c5ce4f9320bb' &&
    committedRoadmap.endsWith(_cui1Authorization + _cui1MediaReconciliation) &&
    roadmap == committedRoadmap &&
    changedPaths
        .where((path) => !_cui1NonProductionPaths.contains(path) && !_cui1DocumentPaths.contains(path))
        .every(_cui1ProductionPaths.contains);

// Current preimplementation composition; historical CUI-1 oracles stay fixed.
const _cui1ImplementationCommit = '47fba3f64581c9a24eefaee18265a437d8c55505';
const _cui1ClosureCommit = 'f4e1331cdca6ec87cb37d32d1d2473479ffb2852';
const _cui2a0FreezeCommit = 'c60dbdda61bd656e281902b452ad937e14aa8c78';
const _cui1ClosureReportPath =
    'docs/architecture/reports/'
    'CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_CLOSURE.md';
const _cui2a0ContractPath =
    'docs/architecture/contracts/'
    'CIVILPEDIA_COMMERCIAL_CUI2A0_ADMIN_BUSINESS_DRAFT_AUTHORITY_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md';
const _cui1ImplementationTestPaths = <String>{
  'test/commercial_cui1_business_experience_foundation_widget_test.dart',
  'test/w5_2_directory_landing_test.dart',
  'test/w5_3_directory_search_screen_test.dart',
  'test/w5_4_directory_provider_card_test.dart',
  'test/w5_4_directory_provider_detail_screen_test.dart',
  'test/w5_5_verification_display_test.dart',
};
const _currentDocumentBlobs = <String, String>{
  _cui1ContractPath: '7a2ab8a4f9665726e86f59c0947ebf3fb6543fd7',
  _cui1MediaAddendumPath: '6bd5e0e41b52e5a8b4a4df481a09b7bc196e56ea',
  _cui1ClosureReportPath: '309536865a922631a12db5db0111004c4822e695',
  _cui2a0ContractPath: 'ed23e9136a39f71d95f91da7dd22e087a59dfca8',
};
// These immutable Git objects are documentary authority, never live snapshots.
final _historicalMediaRoadmap =
    _git(['show', '$_cui1MediaCommit:$_cui1RoadmapPath']);
final _cui1ClosedRoadmap =
    _git(['cat-file', 'blob', 'f9e793b3d001d75fee5da822cb43a8be12264942']);
final _cui2a0FrozenRoadmap =
    _git(['cat-file', 'blob', 'd2ea2d137df6a002cd114494ddf60500653df900']);
final _cui1ClosureAppend =
    _cui1ClosedRoadmap.substring(_historicalMediaRoadmap.length);
final _cui2a0FreezeAppend =
    _cui2a0FrozenRoadmap.substring(_cui1ClosedRoadmap.length);
final _currentRoadmapAdditions = _cui1ClosureAppend + _cui2a0FreezeAppend;
final _currentCommittedDocuments = _currentDocumentBlobs.map(
  (path, blob) => MapEntry(path, _git(['cat-file', 'blob', blob])),
);
const _currentClosedControls = <String>[
  'COMMERCIAL_CURRENT_SLICE: NONE',
  'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO',
  'CUI1_STATE: CLOSED',
  'M3_STATE: CLOSED',
  'M4_STATE: NOT AUTHORIZED',
  'M5_STATE: NOT AUTHORIZED',
  'R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO',
];

bool _allowsCurrentComposition(
  Iterable<String> changedPaths,
  String roadmap,
  Map<String, String> documents,
  Iterable<String> postClosureImplementationChanges,
) =>
    _allowsCui1Composition(
      changedPaths.where(
        (path) => path != _cui1ClosureReportPath && path != _cui2a0ContractPath,
      ),
      _historicalMediaRoadmap,
      _historicalMediaRoadmap,
    ) &&
    _cui1ClosedRoadmap.startsWith(_historicalMediaRoadmap) &&
    _cui2a0FrozenRoadmap.startsWith(_cui1ClosedRoadmap) &&
    roadmap == _historicalMediaRoadmap + _currentRoadmapAdditions &&
    _currentClosedControls.every(
      (control) => _cui1ClosureAppend.contains(control) &&
          _cui2a0FreezeAppend.contains(control),
    ) &&
    _cui2a0FreezeAppend.contains('CUI2A0_CONTRACT_STATE: ACCEPTED / FROZEN') &&
    _cui2a0FreezeAppend.contains('CUI2A0_IMPLEMENTATION_AUTHORIZED: NO') &&
    documents.length == _currentCommittedDocuments.length &&
    _currentCommittedDocuments.entries.every(
      (entry) => documents[entry.key] == entry.value,
    ) &&
    postClosureImplementationChanges.isEmpty;

bool _matchesCui1MediaAuthority(String actual, String committed) => actual == committed;

List<String> _cui1ChangedPaths(String output) =>
    output.trim().isEmpty ? <String>[] : output.trim().split('\n');

void _registerCui1CompatibilityTests({bool roadmapControlsCovered = false}) {
  // A committed, fixed input; never a snapshot of the current working tree.
  final committedRoadmap = _git([
    'show',
    '$_cui1MediaCommit:$_cui1RoadmapPath',
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
      // The new authority is a fixed committed input, never the live tree.
      expect(
        _git(['merge-base', _cui1GovernanceCommit, _cui1MediaCommit]).trim(),
        _cui1GovernanceCommit,
      );
      expect(
        committedRoadmap,
        _git(['show', '$_cui1GovernanceCommit:$_cui1RoadmapPath']) +
            _cui1MediaReconciliation,
      );
      expect(
        _git(['diff', '--name-only', '$_cui1MediaCommit^', _cui1MediaCommit])
            .trim().split('\n')..sort(),
        [_cui1RoadmapPath, _cui1MediaAddendumPath]..sort(),
      );
      final committedMedia = _git(['show', '$_cui1MediaCommit:$_cui1MediaAddendumPath']);
      expect(_matchesCui1MediaAuthority(_read(_cui1MediaAddendumPath), committedMedia), isTrue);
      expect(_matchesCui1MediaAuthority(committedMedia + '\n# Arbitrary future authority', committedMedia), isFalse);
      for (final mutation in <String, String>{
        'PUBLIC_BACKEND_AUTHORITY_DELTA: ZERO': 'PUBLIC_BACKEND_AUTHORITY_DELTA: NONZERO',
        'COMMERCIAL_AUTHORITY_DELTA: ZERO': 'COMMERCIAL_AUTHORITY_DELTA: NONZERO',
        'FROZEN — CUI-1 AUTHORITATIVE MEDIA DELTA ONLY': 'FROZEN — UNBOUNDED COMMERCIAL AUTHORITY',
      }.entries) {
        expect(committedMedia, contains(mutation.key));
        expect(_matchesCui1MediaAuthority(committedMedia.replaceFirst(mutation.key, mutation.value), committedMedia), isFalse);
      }
      for (final mutation in <String, String>{
        'CUI1_STATE: NOT CLOSED': 'CUI1_STATE: CLOSED',
        'M3_STATE: CLOSED': 'M3_STATE: OPEN',
        'M4_STATE: NOT AUTHORIZED': 'M4_STATE: AUTHORIZED',
        'M5_STATE: NOT AUTHORIZED': 'M5_STATE: AUTHORIZED',
        'R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO': 'R10.5-D_STATE: IMPLEMENTATION YES',
        'PUBLIC_BACKEND_AUTHORITY_DELTA: ZERO': 'PUBLIC_BACKEND_AUTHORITY_DELTA: NONZERO',
        'COMMERCIAL_AUTHORITY_DELTA: ZERO': 'COMMERCIAL_AUTHORITY_DELTA: NONZERO',
      }.entries) {
        expect(_cui1MediaReconciliation, contains(mutation.key));
        final alteredMedia = _cui1MediaReconciliation.replaceFirst(mutation.key, mutation.value);
        final alteredRoadmap = committedRoadmap.substring(0, committedRoadmap.length - _cui1MediaReconciliation.length) + alteredMedia;
        expect(_allowsCui1Composition([], alteredRoadmap, committedRoadmap), isFalse);
      }
      final paths = <String>[
        ..._cui1ChangedPaths(
          _git(['diff', '--name-only', '--no-renames', _cui1GovernanceCommit]),
        ),
        ..._cui1ChangedPaths(
          _git(['ls-files', '--others', '--exclude-standard']),
        ),
      ];
      // Bind the exact documentary objects to their authorized commits.
      for (final pin in <(String, String, String)>[
        (_cui1ContractCommit, _cui1ContractPath, _currentDocumentBlobs[_cui1ContractPath]!),
        (_cui1MediaCommit, _cui1MediaAddendumPath, _currentDocumentBlobs[_cui1MediaAddendumPath]!),
        (_cui1ClosureCommit, _cui1ClosureReportPath, _currentDocumentBlobs[_cui1ClosureReportPath]!),
        (_cui2a0FreezeCommit, _cui2a0ContractPath, _currentDocumentBlobs[_cui2a0ContractPath]!),
        (_cui1ClosureCommit, _cui1RoadmapPath, 'f9e793b3d001d75fee5da822cb43a8be12264942'),
        (_cui2a0FreezeCommit, _cui1RoadmapPath, 'd2ea2d137df6a002cd114494ddf60500653df900'),
      ]) {
        expect(_git(['rev-parse', '${pin.$1}:${pin.$2}']).trim(), pin.$3);
      }
      for (final boundary in <(String, List<String>)>[
        (_cui1ClosureCommit, [_cui1RoadmapPath, _cui1ClosureReportPath]),
        (_cui2a0FreezeCommit, [_cui1RoadmapPath, _cui2a0ContractPath]),
      ]) {
        expect(
          _cui1ChangedPaths(_git(['diff', '--name-only', '${boundary.$1}^', boundary.$1]))..sort(),
          boundary.$2..sort(),
        );
      }
      for (final ancestor in <(String, String)>[
        (_cui1MediaCommit, _cui1ImplementationCommit),
        (_cui1ImplementationCommit, _cui1ClosureCommit),
        (_cui1ClosureCommit, _cui2a0FreezeCommit),
      ]) {
        expect(_git(['merge-base', ancestor.$1, ancestor.$2]).trim(), ancestor.$1);
      }
      expect(
        _cui1ChangedPaths(_git(['diff', '--name-only', '$_cui1ImplementationCommit^', _cui1ImplementationCommit]))..sort(),
        [
          ..._cui1ProductionPaths,
          ..._cui1ImplementationTestPaths,
          'test/commercial_harden1_public_plans_exposure_migration_test.dart',
          'test/commercial_m1b_catalog_reference_data_migration_test.dart',
          'test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart',
        ]..sort(),
      );
      final currentRoadmap = _read(_cui1RoadmapPath);
      final currentDocuments = <String, String>{
        for (final path in _currentDocumentBlobs.keys) path: _read(path),
      };
      // Accepted production/test paths are immutable after CUI-1 closure.
      final postClosureChanges = _cui1ChangedPaths(_git([
        'diff', '--name-only', '--no-renames', _cui1ImplementationCommit,
        '--', 'lib', ..._cui1ImplementationTestPaths,
      ]));
      bool acceptsCurrent({
        Iterable<String>? changedPaths,
        String? roadmap,
        Map<String, String>? documents,
        Iterable<String>? implementationChanges,
      }) => _allowsCurrentComposition(
        changedPaths ?? paths,
        roadmap ?? currentRoadmap,
        documents ?? currentDocuments,
        implementationChanges ?? postClosureChanges,
      );
      expect(acceptsCurrent(), isTrue, reason: 'Exact frozen current composition: $paths');
      for (final path in [_cui1ClosureReportPath, _cui2a0ContractPath]) {
        expect(acceptsCurrent(changedPaths: [path]), isTrue, reason: path);
      }

      // All probes use the live predicate and mutate inputs only in memory.
      for (final path in <String>[
        _cui2a0ContractPath.replaceFirst('_V1.md', '_V2.md'),
        _cui2a0ContractPath.replaceFirst('_V1.md', '_RENAMED_V1.md'),
        '$_cui2a0ContractPath.bak',
        'supabase/migrations/00026_commercial_admin_business_draft_foundation.sql',
        'supabase/migrations/00026_renamed.sql',
        'supabase/migrations/00027_unauthorized.sql',
        'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_AUTHORITATIVE_MEDIA_ADDENDUM_V2.md',
        'docs/architecture/contracts/ARBITRARY_MEDIA_ADDENDUM.md',
        'docs/architecture/ARBITRARY_GOVERNANCE.md',
        'lib/features/directory/presentation/ninth.dart',
      ]) {
        expect(acceptsCurrent(changedPaths: [...paths, path]), isFalse, reason: path);
      }
      final migrations = Directory('supabase/migrations').listSync().whereType<File>().toList();
      expect(migrations, hasLength(25));
      for (final migration in migrations) {
        final path = 'supabase/migrations/${migration.uri.pathSegments.last}';
        expect(acceptsCurrent(changedPaths: [...paths, path]), isFalse, reason: 'Historical migration mutation: $path');
      }
      for (final path in [..._cui1ProductionPaths, ..._cui1ImplementationTestPaths]) {
        expect(acceptsCurrent(implementationChanges: [path]), isFalse, reason: 'Closed implementation mutation: $path');
      }
      for (final mutation in <String, String>{
        'CUI2A0_CONTRACT_STATE: ACCEPTED / FROZEN': 'CUI2A0_CONTRACT_STATE: DRAFT',
        'CUI2A0_IMPLEMENTATION_AUTHORIZED: NO': 'CUI2A0_IMPLEMENTATION_AUTHORIZED: YES',
        'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO': 'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES',
        'COMMERCIAL_CURRENT_SLICE: NONE': 'COMMERCIAL_CURRENT_SLICE: CUI-2A0',
        'CUI1_STATE: CLOSED': 'CUI1_STATE: OPEN',
        'M3_STATE: CLOSED': 'M3_STATE: OPEN',
        'M4_STATE: NOT AUTHORIZED': 'M4_STATE: AUTHORIZED',
        'M5_STATE: NOT AUTHORIZED': 'M5_STATE: AUTHORIZED',
        'R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO': 'R10.5-D_STATE: IMPLEMENTATION YES',
      }.entries) {
        expect(_cui2a0FreezeAppend, contains(mutation.key));
        expect(acceptsCurrent(roadmap:
          committedRoadmap + _cui1ClosureAppend +
          _cui2a0FreezeAppend.replaceFirst(mutation.key, mutation.value),
        ), isFalse, reason: mutation.key);
      }
      expect(_cui1ClosureAppend, contains('CUI1_STATE: CLOSED'));
      expect(acceptsCurrent(roadmap: committedRoadmap +
        _cui1ClosureAppend.replaceFirst('CUI1_STATE: CLOSED', 'CUI1_STATE: OPEN') +
        _cui2a0FreezeAppend,
      ), isFalse, reason: 'Reopened closure');
      expect(currentRoadmap, contains('ROADMAP_VERSION: 1'));
      for (final altered in [
        committedRoadmap,
        _cui1ClosedRoadmap,
        committedRoadmap + _cui2a0FreezeAppend,
        currentRoadmap.replaceFirst('ROADMAP_VERSION: 1', 'ROADMAP_VERSION: 2'),
        currentRoadmap + '\n# Arbitrary future governance\n',
      ]) {
        expect(acceptsCurrent(roadmap: altered), isFalse, reason: 'Missing/altered historical or current governance');
      }
      for (final entry in currentDocuments.entries) {
        expect(acceptsCurrent(documents: {
          ...currentDocuments, entry.key: '${entry.value}\n# Altered bytes\n',
        }), isFalse, reason: 'Frozen document mutation: ${entry.key}');
      }
      for (final probe in <(String, String, String)>[
        (_cui2a0ContractPath, 'IMPLEMENTATION_AUTHORIZED: NO', 'IMPLEMENTATION_AUTHORIZED: YES'),
        (_cui1ClosureReportPath, 'CUI1_STATE: CLOSED', 'CUI1_STATE: OPEN'),
        (_cui1MediaAddendumPath, 'PUBLIC_BACKEND_AUTHORITY_DELTA: ZERO', 'PUBLIC_BACKEND_AUTHORITY_DELTA: NONZERO'),
      ]) {
        expect(currentDocuments[probe.$1], contains(probe.$2));
        expect(acceptsCurrent(documents: {
          ...currentDocuments,
          probe.$1: currentDocuments[probe.$1]!.replaceFirst(probe.$2, probe.$3),
        }), isFalse, reason: 'Frozen authority mutation: ${probe.$1}');
      }
      for (final alternate in [
        _cui2a0ContractPath.replaceFirst('_V1.md', '_V2.md'),
        _cui2a0ContractPath.replaceFirst('_V1.md', '_RENAMED_V1.md'),
        '$_cui2a0ContractPath.bak',
      ]) {
        final substitutedDocuments = {...currentDocuments}
          ..remove(_cui2a0ContractPath);
        substitutedDocuments[alternate] = currentDocuments[_cui2a0ContractPath]!;
        expect(acceptsCurrent(documents: substitutedDocuments), isFalse, reason: alternate);
      }
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
    expect(_cui1DocumentPaths, {
      'docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md',
      'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_AUTHORITATIVE_MEDIA_ADDENDUM_V1.md',
    });
    for (final path in _cui1DocumentPaths) {
      expect(_allowsCui1Composition([path], committedRoadmap, committedRoadmap), isTrue, reason: path);
    }

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
        'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_AUTHORITATIVE_MEDIA_ADDENDUM_V2.md',
        'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_AUTHORITATIVE_MEDIA_ADDENDUM_V1.md.bak',
        'docs/architecture/contracts/ARBITRARY_MEDIA_ADDENDUM.md',
        'lib/features/auth/presentation/providers/auth_provider.dart',
        'lib/core/theme/app_theme.dart',
        'pubspec.lock',
        'sdk/unauthorized.dart',
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
        _allowsCui1Composition([], committedRoadmap, committedRoadmap, mediaCommit: wrong),
        isFalse,
      );

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
        _matchesCui1Roadmap(_read(roadmapPath), closedCheckpoint,
          includeFrozenGovernance: true,
        ),
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
      expect(_matchesCui1Roadmap(closedCheckpoint + _cui1Authorization + _cui1MediaReconciliation, closedCheckpoint), isTrue);
      expect(_cui1Authorization, contains(mutation.value.first));
      final changedRecord = _cui1Authorization.replaceFirst(
        mutation.value.first, mutation.value.last,
      );
      expect(_matchesCui1Roadmap(closedCheckpoint + changedRecord + _cui1MediaReconciliation, closedCheckpoint), isFalse);
    });
  }
  test('CUI-1 governance rejects unrelated historical roadmap mutation', () {
    const path = 'docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md';
    final closedCheckpoint = _git([
      'show', '798b2af358735e871463790e746c8f5761fbb989:$path',
    ]);
    expect(closedCheckpoint, contains('ROADMAP_VERSION: 1'));
    expect(_matchesCui1Roadmap(
      closedCheckpoint.replaceFirst('ROADMAP_VERSION: 1', 'ROADMAP_VERSION: 2') + _cui1Authorization + _cui1MediaReconciliation,
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
