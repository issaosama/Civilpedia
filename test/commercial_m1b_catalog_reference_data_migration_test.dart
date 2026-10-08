import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'commercial_cui2a0_admin_business_draft_foundation_migration_test.dart' as cui2a0;

// Independent frozen M1b expectations: accepted sections 7-15 and final C'.
// Static evidence does not replace PostgreSQL, HTTP or runner atomicity.
const _baseline = 'ebaf5f7b4402366285e214eec99735a931b69d8d';
const _path = 'supabase/migrations/00024_commercial_catalog_reference_data.sql';
const _time = '2026-01-01 00:00:00+00';
const _sentinel = '__AR_LOCALIZATION_PENDING__';
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
const _plans = <List<Object?>>[
  ['1a7b0001-0000-4000-8000-000000000001', 'business', 'Business'],
  ['1a7b0002-0000-4000-8000-000000000002', 'business_pro', 'Business Pro'],
  ['1a7b0003-0000-4000-8000-000000000003', 'business_plus', 'Business Plus'],
  ['1a7b0004-0000-4000-8000-000000000004', 'corporate', 'Corporate'],
];
const _bundles = <List<Object?>>[
  ['2e7b0001-0000-4000-8000-000000000001', 'business_entitlements'],
  ['2e7b0002-0000-4000-8000-000000000002', 'business_pro_entitlements'],
  ['2e7b0003-0000-4000-8000-000000000003', 'business_plus_entitlements'],
  ['2e7b0004-0000-4000-8000-000000000004', 'corporate_entitlements'],
];
const _versions = <List<Object?>>[
  ['4c7b0001-0000-4000-8000-000000000001', 0, 'retail', 1],
  ['4c7b0002-0000-4000-8000-000000000002', 1, 'retail', 2],
  ['4c7b0003-0000-4000-8000-000000000003', 2, 'retail', 3],
  ['4c7b0004-0000-4000-8000-000000000004', 3, 'custom_quote', 4],
];
// UUID suffixes 6-19 are deliberately all 000000000001.
const _items = <List<Object?>>[
  ['3a7b0001-0000-4000-8000-000000000001', 0, 'branches.included', 1],
  ['3a7b0002-0000-4000-8000-000000000002', 0, 'team.active_member_max', 5],
  ['3a7b0003-0000-4000-8000-000000000003', 0, 'media.upload_enabled', true],
  ['3a7b0004-0000-4000-8000-000000000004', 0, 'analytics.available', true],
  [
    '3a7b0005-0000-4000-8000-000000000005',
    0,
    'sponsored.purchase_eligible',
    false,
  ],
  ['3a7b0006-0000-4000-8000-000000000001', 1, 'branches.included', 2],
  ['3a7b0007-0000-4000-8000-000000000001', 1, 'team.active_member_max', 5],
  ['3a7b0008-0000-4000-8000-000000000001', 1, 'media.upload_enabled', true],
  ['3a7b0009-0000-4000-8000-000000000001', 1, 'analytics.available', true],
  [
    '3a7b0010-0000-4000-8000-000000000001',
    1,
    'sponsored.purchase_eligible',
    true,
  ],
  ['3a7b0011-0000-4000-8000-000000000001', 2, 'branches.included', 3],
  ['3a7b0012-0000-4000-8000-000000000001', 2, 'team.active_member_max', 5],
  ['3a7b0013-0000-4000-8000-000000000001', 2, 'media.upload_enabled', true],
  ['3a7b0014-0000-4000-8000-000000000001', 2, 'analytics.available', true],
  [
    '3a7b0015-0000-4000-8000-000000000001',
    2,
    'sponsored.purchase_eligible',
    true,
  ],
  ['3a7b0016-0000-4000-8000-000000000001', 3, 'branches.included', 3],
  ['3a7b0017-0000-4000-8000-000000000001', 3, 'team.active_member_max', 5],
  ['3a7b0018-0000-4000-8000-000000000001', 3, 'media.upload_enabled', true],
  ['3a7b0019-0000-4000-8000-000000000001', 3, 'analytics.available', true],
];
const _prices = <List<Object?>>[
  ['5d7b0001-0000-4000-8000-000000000001', 0, 1, 20000],
  ['5d7b0002-0000-4000-8000-000000000002', 0, 3, 55000],
  ['5d7b0003-0000-4000-8000-000000000003', 0, 12, 200000],
  ['5d7b0004-0000-4000-8000-000000000004', 1, 1, 40000],
  ['5d7b0005-0000-4000-8000-000000000005', 1, 3, 110000],
  ['5d7b0006-0000-4000-8000-000000000006', 1, 12, 400000],
  ['5d7b0007-0000-4000-8000-000000000007', 2, 1, 70000],
  ['5d7b0008-0000-4000-8000-000000000008', 2, 3, 190000],
  ['5d7b0009-0000-4000-8000-000000000009', 2, 12, 700000],
];
String _read(String path) =>
    File(path).readAsStringSync().replaceAll('\r\n', '\n');
String _git(List<String> args) {
  final r = Process.runSync(
    'git',
    args,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (r.exitCode != 0) throw StateError('Read-only git failed: ${r.stderr}');
  return (r.stdout as String).replaceAll('\r\n', '\n');
}

String _compact(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
String? _dollarDelimiter(String sql, int offset) => RegExp(
  r'^\$(?:[A-Za-z_][A-Za-z_0-9]*)?\$',
).firstMatch(sql.substring(offset))?.group(0);

int _quotedEnd(String sql, int start) {
  final quote = sql[start];
  final escaped =
      quote == "'" &&
      start > 0 &&
      (sql[start - 1] == 'E' || sql[start - 1] == 'e') &&
      (start == 1 || !RegExp(r'[A-Za-z_0-9]').hasMatch(sql[start - 2]));
  var index = start + 1;
  while (index < sql.length) {
    // Backslashes escape E-strings only. Standard-conforming SQL strings use
    // doubled quotes; a backslash must not hide a real following statement.
    if (escaped && sql[index] == r'\' && index + 1 < sql.length) {
      index += 2;
    } else if (sql[index] == quote) {
      if (index + 1 < sql.length && sql[index + 1] == quote) {
        index += 2;
      } else {
        return index + 1;
      }
    } else {
      index++;
    }
  }
  throw FormatException('Unclosed SQL quote');
}

// Preserve strings/dollar bodies while removing comments; with maskLiterals,
// string contents cannot masquerade as DML or DDL. Nested block comments and
// comment markers inside quoted text are handled separately.
String _cleanSql(String sql, {bool maskLiterals = false}) {
  final output = StringBuffer();
  var index = 0;
  while (index < sql.length) {
    if (sql.startsWith('--', index)) {
      final end = sql.indexOf('\n', index + 2);
      output.write(' ');
      index = end < 0 ? sql.length : end;
    } else if (sql.startsWith('/*', index)) {
      var depth = 1;
      index += 2;
      while (index < sql.length && depth > 0) {
        if (sql.startsWith('/*', index)) {
          depth++;
          index += 2;
        } else if (sql.startsWith('*/', index)) {
          depth--;
          index += 2;
        } else {
          index++;
        }
      }
      if (depth != 0) throw FormatException('Unclosed SQL block comment');
      output.write(' ');
    } else if (sql[index] == "'" || sql[index] == '"') {
      final end = _quotedEnd(sql, index);
      output.write(
        maskLiterals && sql[index] == "'" ? "''" : sql.substring(index, end),
      );
      index = end;
    } else if (sql[index] == r'$' && _dollarDelimiter(sql, index) != null) {
      final delimiter = _dollarDelimiter(sql, index)!;
      final end = sql.indexOf(delimiter, index + delimiter.length);
      if (end < 0) throw FormatException('Unclosed dollar-quoted SQL body');
      final after = end + delimiter.length;
      output.write(maskLiterals ? "''" : sql.substring(index, after));
      index = after;
    } else {
      output.write(sql[index++]);
    }
  }
  return output.toString();
}

List<String> _statements(String sql) {
  final text = _cleanSql(sql);
  final result = <String>[];
  var start = 0;
  var index = 0;
  while (index < text.length) {
    if (text[index] == "'" || text[index] == '"') {
      index = _quotedEnd(text, index);
      continue;
    }
    if (text[index] == r'$' && _dollarDelimiter(text, index) != null) {
      final delimiter = _dollarDelimiter(text, index)!;
      final end = text.indexOf(delimiter, index + delimiter.length);
      if (end < 0) throw FormatException('Unclosed dollar-quoted SQL body');
      index = end + delimiter.length;
      continue;
    }
    if (text[index] == ';') {
      final statement = text.substring(start, index).trim();
      if (statement.isNotEmpty) result.add(statement);
      start = index + 1;
    }
    index++;
  }
  final remainder = text.substring(start).trim();
  if (remainder.isNotEmpty) result.add(remainder);
  return result;
}

String? _doBody(String statement) => RegExp(
  r'^DO\s+(\$(?:[A-Za-z_][A-Za-z_0-9]*)?\$)([\s\S]*)\1'
  r'(?:\s+LANGUAGE\s+plpgsql)?$',
  caseSensitive: false,
).firstMatch(statement)?.group(2);

Object? _literal(String token) {
  token = token.trim();
  if (token == 'reference_time') return _time;
  if (token == 'NULL') return null;
  if (token == 'true') return true;
  if (token == 'false') return false;
  if (RegExp(r'^\d+$').hasMatch(token)) return int.parse(token);
  if (token.startsWith("'") && _quotedEnd(token, 0) == token.length) {
    return token.substring(1, token.length - 1).replaceAll("''", "'");
  }
  throw FormatException('Unexpected executable row expression: $token');
}

Map<String, List<List<Object?>>> _rows(String body) {
  final result = <String, List<List<Object?>>>{};
  for (final m in RegExp(
    r'ROW\(([^()]*)\)::(public|commercial_private)\.(\w+)',
  ).allMatches(body)) {
    final contents = m.group(1)!;
    final cells = <Object?>[];
    var start = 0;
    var i = 0;
    while (i < contents.length) {
      if (contents[i] == "'") {
        i = _quotedEnd(contents, i);
      } else if (contents[i] == ',') {
        cells.add(_literal(contents.substring(start, i)));
        start = ++i;
      } else {
        i++;
      }
    }
    cells.add(_literal(contents.substring(start)));
    (result['${m.group(2)}.${m.group(3)}'] ??= []).add(cells);
  }
  return result;
}

Map<String, List<List<Object?>>> _expected() => {
  'public.plans': [
    for (final p in _plans) [...p, null, false, _time, _time],
  ],
  'commercial_private.entitlement_bundles': [
    for (final b in _bundles) [...b, 1, 1, 'draft', null, null, _time],
  ],
  'commercial_private.bundle_items': [
    for (final i in _items)
      [
        i[0],
        _bundles[i[1] as int][0],
        i[2],
        i[3] is bool ? 'boolean' : 'integer',
        i[3] is bool ? i[3] : null,
        i[3] is int ? i[3] : null,
        null,
        true,
        _time,
      ],
  ],
  'commercial_private.plan_versions': [
    for (final v in _versions)
      [
        v[0],
        _plans[v[1] as int][0],
        1,
        _bundles[v[1] as int][0],
        v[2],
        _sentinel,
        null,
        v[3],
        'draft',
        null,
        null,
        null,
        null,
        _time,
      ],
  ],
  'commercial_private.term_prices': [
    for (final p in _prices)
      [
        p[0],
        _versions[p[1] as int][0],
        'retail',
        1,
        p[2],
        p[3],
        'IQD',
        'draft',
        null,
        null,
        null,
        null,
        _time,
      ],
  ],
};
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
  'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_APPEND_AUDIT_LOG_ACL_SECURITY_ADDENDUM_V1.md': '38016765af82de2e5a25e3b2169536bcf5fab44b',
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
// Exact Owner-committed authorization; historical freeze controls stay intact.
const _cui2a0AuthorizationCommit = 'a813b8c99309757bd7d03ac96dde0e7c12cfed79';
final _cui2a0AuthorizedRoadmap =
    _git(['cat-file', 'blob', 'a36067d0634ae36437006175f825e68d70f92d0a']);
final _cui2a0AuthorizationAppend =
    _cui2a0AuthorizedRoadmap.substring(_cui2a0FrozenRoadmap.length);
const _cui2a0SecurityCommit = 'd9bc74d42e0d3ebc56455b928f2dbc57d8ca6fb8';
const _cui2a0SecurityPath = 'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_APPEND_AUDIT_LOG_ACL_SECURITY_ADDENDUM_V1.md';
final _cui2a0SecurityRoadmap = _git(['cat-file', 'blob', 'a5586dfdea1770f58d2333bcabad26ea00d8e747']);
final _cui2a0SecurityAppend = _cui2a0SecurityRoadmap.substring(_cui2a0AuthorizedRoadmap.length);
final _currentRoadmapAdditions =
    _cui1ClosureAppend + _cui2a0FreezeAppend + _cui2a0AuthorizationAppend + _cui2a0SecurityAppend;
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
        (path) => path != _cui1ClosureReportPath && path != _cui2a0ContractPath && path != _cui2a0SecurityPath && !cui2a0.cui2a0ImplementationPaths.contains(path),
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
    _cui2a0AuthorizedRoadmap.startsWith(_cui2a0FrozenRoadmap) &&
    _git(['rev-parse', '$_cui2a0AuthorizationCommit:$_cui1RoadmapPath']).trim() ==
        'a36067d0634ae36437006175f825e68d70f92d0a' &&
    _cui2a0AuthorizationAppend.contains('CUI2A0_IMPLEMENTATION_AUTHORIZED: YES') &&
    _cui2a0AuthorizationAppend.contains('COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES — CUI-2A0 ONLY') &&
    _cui2a0AuthorizationAppend.contains('M4_STATE: NOT AUTHORIZED') &&
    _cui2a0AuthorizationAppend.contains('M5_STATE: NOT AUTHORIZED') &&
    _cui2a0AuthorizationAppend.contains('CUI2A1_STATE: NOT AUTHORIZED') &&
    _cui2a0SecurityRoadmap.startsWith(_cui2a0AuthorizedRoadmap) &&
    _git(['rev-parse', '$_cui2a0SecurityCommit:$_cui1RoadmapPath']).trim() == 'a5586dfdea1770f58d2333bcabad26ea00d8e747' &&
    _git(['rev-parse', '$_cui2a0SecurityCommit:$_cui2a0SecurityPath']).trim() == '38016765af82de2e5a25e3b2169536bcf5fab44b' &&
    _cui2a0SecurityAppend.contains('MAXIMUM_IMPLEMENTATION_SECURITY_TEST_FILES: 8') &&
    documents.length == _currentCommittedDocuments.length &&
    _currentCommittedDocuments.entries.every(
      (entry) => documents[entry.key] == entry.value,
    ) &&
    postClosureImplementationChanges.isEmpty && cui2a0.hasAuthorizedCui2a0Boundary();

// Exact post-closure recognition; the predecessor predicates and pins remain
// historical. This path accepts no future A1 contract, source or authority.
const _cui2a0ClosureReportPath = cui2a0.cui2a0ClosureReportPath;
final _cui2a0ClosedRoadmap =
    _git(['cat-file', 'blob', '8fa8595cfe9cc21a00db8016f930b45cf76b52d2']);
final _cui2a0ClosureAppend =
    _cui2a0ClosedRoadmap.substring(_cui2a0SecurityRoadmap.length);
final _closedRoadmapAdditions = _currentRoadmapAdditions + _cui2a0ClosureAppend;
final _closedCommittedDocuments = <String, String>{
  ..._currentCommittedDocuments,
  _cui2a0ClosureReportPath:
      _git(['cat-file', 'blob', '068307bb6e3d64a0cb479f127d1c162a155cb0cd']),
};
bool _allowsClosedCui2a0Composition(
  Iterable<String> changedPaths,
  String roadmap,
  Map<String, String> documents,
  Iterable<String> postClosureImplementationChanges,
) =>
    roadmap == _cui2a0ClosedRoadmap &&
    _cui2a0ClosedRoadmap == _historicalMediaRoadmap + _closedRoadmapAdditions &&
    documents.length == _closedCommittedDocuments.length &&
    _closedCommittedDocuments.entries.every(
      (entry) => documents[entry.key] == entry.value,
    ) &&
    _allowsCurrentComposition(
      changedPaths.where((path) => path != _cui2a0ClosureReportPath),
      _cui2a0SecurityRoadmap,
      Map.fromEntries(documents.entries.where((entry) => entry.key != _cui2a0ClosureReportPath)),
      postClosureImplementationChanges,
    );

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
        for (final path in _closedCommittedDocuments.keys) path: _read(path),
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
      }) => _allowsClosedCui2a0Composition(
        changedPaths ?? paths,
        roadmap ?? currentRoadmap,
        documents ?? currentDocuments,
        implementationChanges ?? postClosureChanges,
      );
      expect(acceptsCurrent(), isTrue, reason: 'Exact frozen current composition: $paths');
      for (final path in [_cui1ClosureReportPath, _cui2a0ContractPath, _cui2a0ClosureReportPath, ...cui2a0.cui2a0ImplementationPaths]) {
        expect(acceptsCurrent(changedPaths: [path]), isTrue, reason: path);
      }

      // All probes use the live predicate and mutate inputs only in memory.
      // Mutate the final closure controls, not an earlier historical block.
      for (final mutation in <String, String>{
        'CUI2A0_STATE: CLOSED': 'CUI2A0_STATE: OPEN',
        'CUI2A0_IMPLEMENTATION_AUTHORIZED: NO — SLICE CLOSED': 'CUI2A0_IMPLEMENTATION_AUTHORIZED: YES',
        'CUI2A1_STATE: NOT AUTHORIZED': 'CUI2A1_STATE: IMPLEMENTATION AUTHORIZED',
        'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO': 'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES',
        'COMMERCIAL_CURRENT_SLICE: NONE': 'COMMERCIAL_CURRENT_SLICE: CUI-2A1',
        'M4_STATE: NOT AUTHORIZED': 'M4_STATE: AUTHORIZED',
        'M5_STATE: NOT AUTHORIZED': 'M5_STATE: AUTHORIZED',
        'R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO': 'R10.5-D_STATE: IMPLEMENTATION YES',
      }.entries) {
        expect(_cui2a0ClosureAppend, contains(mutation.key));
        expect(acceptsCurrent(roadmap: _cui2a0SecurityRoadmap +
          _cui2a0ClosureAppend.replaceFirst(mutation.key, mutation.value)),
          isFalse, reason: 'Closed authority must remain denied: ${mutation.key}');
      }
      for (final path in <String>[
        _cui2a0ContractPath.replaceFirst('_V1.md', '_V2.md'),
        _cui2a0ContractPath.replaceFirst('_V1.md', '_RENAMED_V1.md'),
        '$_cui2a0ContractPath.bak',
        'supabase/migrations/00026_renamed.sql',
        'supabase/migrations/00027_unauthorized.sql',
        'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_AUTHORITATIVE_MEDIA_ADDENDUM_V2.md',
        'docs/architecture/contracts/ARBITRARY_MEDIA_ADDENDUM.md',
        'docs/architecture/ARBITRARY_GOVERNANCE.md',
        'lib/features/directory/presentation/ninth.dart',
        'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A1_ADMIN_BUSINESS_DRAFT_CONSOLE_IMPLEMENTATION_CONTRACT_V1.md',
        'docs/unauthorized.md',
        'lib/features/business/data/supabase_commercial_admin_gateway.dart',
        'lib/features/business/presentation/providers/commercial_admin_provider.dart',
        'lib/features/business/presentation/screens/admin_businesses_screen.dart',
        'lib/features/business/presentation/screens/admin_business_draft_screen.dart',
      ]) {
        expect(acceptsCurrent(changedPaths: [...paths, path]), isFalse, reason: path);
      }
      final migrations = Directory('supabase/migrations').listSync().whereType<File>().toList();
      expect(migrations, hasLength(26));
      for (final migration in migrations) {
        if (migration.uri.pathSegments.last == cui2a0.cui2a0MigrationName) continue;
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
        (_cui2a0ClosureReportPath, 'CUI2A0_STATE: CLOSED', 'CUI2A0_STATE: OPEN'),
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

const _cui1GuardSupportSource = r'''// CUI-1 composition: fixed historical evidence plus only the frozen UI delta.
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
  'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_APPEND_AUDIT_LOG_ACL_SECURITY_ADDENDUM_V1.md': '38016765af82de2e5a25e3b2169536bcf5fab44b',
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
// Exact Owner-committed authorization; historical freeze controls stay intact.
const _cui2a0AuthorizationCommit = 'a813b8c99309757bd7d03ac96dde0e7c12cfed79';
final _cui2a0AuthorizedRoadmap =
    _git(['cat-file', 'blob', 'a36067d0634ae36437006175f825e68d70f92d0a']);
final _cui2a0AuthorizationAppend =
    _cui2a0AuthorizedRoadmap.substring(_cui2a0FrozenRoadmap.length);
const _cui2a0SecurityCommit = 'd9bc74d42e0d3ebc56455b928f2dbc57d8ca6fb8';
const _cui2a0SecurityPath = 'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_APPEND_AUDIT_LOG_ACL_SECURITY_ADDENDUM_V1.md';
final _cui2a0SecurityRoadmap = _git(['cat-file', 'blob', 'a5586dfdea1770f58d2333bcabad26ea00d8e747']);
final _cui2a0SecurityAppend = _cui2a0SecurityRoadmap.substring(_cui2a0AuthorizedRoadmap.length);
final _currentRoadmapAdditions =
    _cui1ClosureAppend + _cui2a0FreezeAppend + _cui2a0AuthorizationAppend + _cui2a0SecurityAppend;
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
        (path) => path != _cui1ClosureReportPath && path != _cui2a0ContractPath && path != _cui2a0SecurityPath && !cui2a0.cui2a0ImplementationPaths.contains(path),
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
    _cui2a0AuthorizedRoadmap.startsWith(_cui2a0FrozenRoadmap) &&
    _git(['rev-parse', '$_cui2a0AuthorizationCommit:$_cui1RoadmapPath']).trim() ==
        'a36067d0634ae36437006175f825e68d70f92d0a' &&
    _cui2a0AuthorizationAppend.contains('CUI2A0_IMPLEMENTATION_AUTHORIZED: YES') &&
    _cui2a0AuthorizationAppend.contains('COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES — CUI-2A0 ONLY') &&
    _cui2a0AuthorizationAppend.contains('M4_STATE: NOT AUTHORIZED') &&
    _cui2a0AuthorizationAppend.contains('M5_STATE: NOT AUTHORIZED') &&
    _cui2a0AuthorizationAppend.contains('CUI2A1_STATE: NOT AUTHORIZED') &&
    _cui2a0SecurityRoadmap.startsWith(_cui2a0AuthorizedRoadmap) &&
    _git(['rev-parse', '$_cui2a0SecurityCommit:$_cui1RoadmapPath']).trim() == 'a5586dfdea1770f58d2333bcabad26ea00d8e747' &&
    _git(['rev-parse', '$_cui2a0SecurityCommit:$_cui2a0SecurityPath']).trim() == '38016765af82de2e5a25e3b2169536bcf5fab44b' &&
    _cui2a0SecurityAppend.contains('MAXIMUM_IMPLEMENTATION_SECURITY_TEST_FILES: 8') &&
    documents.length == _currentCommittedDocuments.length &&
    _currentCommittedDocuments.entries.every(
      (entry) => documents[entry.key] == entry.value,
    ) &&
    postClosureImplementationChanges.isEmpty && cui2a0.hasAuthorizedCui2a0Boundary();

// Exact post-closure recognition; the predecessor predicates and pins remain
// historical. This path accepts no future A1 contract, source or authority.
const _cui2a0ClosureReportPath = cui2a0.cui2a0ClosureReportPath;
final _cui2a0ClosedRoadmap =
    _git(['cat-file', 'blob', '8fa8595cfe9cc21a00db8016f930b45cf76b52d2']);
final _cui2a0ClosureAppend =
    _cui2a0ClosedRoadmap.substring(_cui2a0SecurityRoadmap.length);
final _closedRoadmapAdditions = _currentRoadmapAdditions + _cui2a0ClosureAppend;
final _closedCommittedDocuments = <String, String>{
  ..._currentCommittedDocuments,
  _cui2a0ClosureReportPath:
      _git(['cat-file', 'blob', '068307bb6e3d64a0cb479f127d1c162a155cb0cd']),
};
bool _allowsClosedCui2a0Composition(
  Iterable<String> changedPaths,
  String roadmap,
  Map<String, String> documents,
  Iterable<String> postClosureImplementationChanges,
) =>
    roadmap == _cui2a0ClosedRoadmap &&
    _cui2a0ClosedRoadmap == _historicalMediaRoadmap + _closedRoadmapAdditions &&
    documents.length == _closedCommittedDocuments.length &&
    _closedCommittedDocuments.entries.every(
      (entry) => documents[entry.key] == entry.value,
    ) &&
    _allowsCurrentComposition(
      changedPaths.where((path) => path != _cui2a0ClosureReportPath),
      _cui2a0SecurityRoadmap,
      Map.fromEntries(documents.entries.where((entry) => entry.key != _cui2a0ClosureReportPath)),
      postClosureImplementationChanges,
    );

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
        for (final path in _closedCommittedDocuments.keys) path: _read(path),
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
      }) => _allowsClosedCui2a0Composition(
        changedPaths ?? paths,
        roadmap ?? currentRoadmap,
        documents ?? currentDocuments,
        implementationChanges ?? postClosureChanges,
      );
      expect(acceptsCurrent(), isTrue, reason: 'Exact frozen current composition: $paths');
      for (final path in [_cui1ClosureReportPath, _cui2a0ContractPath, _cui2a0ClosureReportPath, ...cui2a0.cui2a0ImplementationPaths]) {
        expect(acceptsCurrent(changedPaths: [path]), isTrue, reason: path);
      }

      // All probes use the live predicate and mutate inputs only in memory.
      // Mutate the final closure controls, not an earlier historical block.
      for (final mutation in <String, String>{
        'CUI2A0_STATE: CLOSED': 'CUI2A0_STATE: OPEN',
        'CUI2A0_IMPLEMENTATION_AUTHORIZED: NO — SLICE CLOSED': 'CUI2A0_IMPLEMENTATION_AUTHORIZED: YES',
        'CUI2A1_STATE: NOT AUTHORIZED': 'CUI2A1_STATE: IMPLEMENTATION AUTHORIZED',
        'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO': 'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES',
        'COMMERCIAL_CURRENT_SLICE: NONE': 'COMMERCIAL_CURRENT_SLICE: CUI-2A1',
        'M4_STATE: NOT AUTHORIZED': 'M4_STATE: AUTHORIZED',
        'M5_STATE: NOT AUTHORIZED': 'M5_STATE: AUTHORIZED',
        'R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO': 'R10.5-D_STATE: IMPLEMENTATION YES',
      }.entries) {
        expect(_cui2a0ClosureAppend, contains(mutation.key));
        expect(acceptsCurrent(roadmap: _cui2a0SecurityRoadmap +
          _cui2a0ClosureAppend.replaceFirst(mutation.key, mutation.value)),
          isFalse, reason: 'Closed authority must remain denied: ${mutation.key}');
      }
      for (final path in <String>[
        _cui2a0ContractPath.replaceFirst('_V1.md', '_V2.md'),
        _cui2a0ContractPath.replaceFirst('_V1.md', '_RENAMED_V1.md'),
        '$_cui2a0ContractPath.bak',
        'supabase/migrations/00026_renamed.sql',
        'supabase/migrations/00027_unauthorized.sql',
        'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_AUTHORITATIVE_MEDIA_ADDENDUM_V2.md',
        'docs/architecture/contracts/ARBITRARY_MEDIA_ADDENDUM.md',
        'docs/architecture/ARBITRARY_GOVERNANCE.md',
        'lib/features/directory/presentation/ninth.dart',
        'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A1_ADMIN_BUSINESS_DRAFT_CONSOLE_IMPLEMENTATION_CONTRACT_V1.md',
        'docs/unauthorized.md',
        'lib/features/business/data/supabase_commercial_admin_gateway.dart',
        'lib/features/business/presentation/providers/commercial_admin_provider.dart',
        'lib/features/business/presentation/screens/admin_businesses_screen.dart',
        'lib/features/business/presentation/screens/admin_business_draft_screen.dart',
      ]) {
        expect(acceptsCurrent(changedPaths: [...paths, path]), isFalse, reason: path);
      }
      final migrations = Directory('supabase/migrations').listSync().whereType<File>().toList();
      expect(migrations, hasLength(26));
      for (final migration in migrations) {
        if (migration.uri.pathSegments.last == cui2a0.cui2a0MigrationName) continue;
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
        (_cui2a0ClosureReportPath, 'CUI2A0_STATE: CLOSED', 'CUI2A0_STATE: OPEN'),
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

''';

void main() {
  _registerCui1CompatibilityTests();
  late String raw;
  late String body;
  late String executable;
  late Map<String, List<List<Object?>>> rows;
  setUpAll(() {
    raw = _read(_path);
    final statements = _statements(raw);
    expect(
      statements,
      hasLength(1),
      reason: 'One anonymous block; no hidden top-level SQL',
    );
    body = _doBody(statements.single)!;
    executable = _cleanSql(body, maskLiterals: true);
    rows = _rows(_cleanSql(body));
  });
  test('SQL lexer separates strings/comments from transaction control', () {
    expect(
      _statements(r"DO $x$ BEGIN RAISE NOTICE 'COMMIT;'; END; $x$;"),
      hasLength(1),
    );
    expect(_statements(r"DO $x$ BEGIN NULL; END; $x$; COMMIT;"), hasLength(2));
    expect(
      _cleanSql(
        "/* outer /* nested */ */ SELECT 'DELETE';",
        maskLiterals: true,
      ).trim(),
      "SELECT '';",
    );
  });
  test(
    '00024 checkpoint and explicit authorized 00025 suffix are preserved',
    () {
      final files =
          Directory('supabase/migrations').listSync().whereType<File>().toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      expect(files, hasLength(26));
      expect(files.last.uri.pathSegments.last, cui2a0.cui2a0MigrationName);
      expect(
        files[23].uri.pathSegments.last,
        '00024_commercial_catalog_reference_data.sql',
      );
      expect(
        files[24].uri.pathSegments.last,
        '00025_commercial_entitlement_evaluator_shadow.sql',
      );
      expect(
        _read(_path),
        _git(['show', 'dcc736ba7a8dc0b068f6c8bfc11b74566ab756dc:$_path']),
      );
      for (var i = 0; i < files.length; i++) {
        final name = files[i].uri.pathSegments.last;
        expect(
          name.startsWith('${(i + 1).toString().padLeft(5, '0')}_'),
          isTrue,
        );
        if (i < 23)
          expect(
            _read(files[i].path),
            _git(['show', '$_baseline:supabase/migrations/$name']),
          );
      }
    },
  );
  for (final family in _expected().keys) {
    test(
      'exact frozen rows and every column: $family',
      () => expect(rows[family], _expected()[family]),
    );
  }
  test('exact forty UUIDs, five families and deterministic timestamps', () {
    expect(rows.keys.toSet(), _expected().keys.toSet());
    expect(rows.values.expand((v) => v), hasLength(40));
    final ids = _expected().values.expand((v) => v).map((r) => r.first).toSet();
    expect(ids, hasLength(40));
    expect(
      RegExp(
        r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
      ).allMatches(body).map((m) => m.group(0)).toSet(),
      ids,
    );
    expect(raw, contains("TIMESTAMPTZ '$_time'"));
    expect(
      executable,
      isNot(
        matches(
          RegExp(
            r'\b(now|gen_random_uuid|uuid_generate|random|clock_timestamp)\s*\(',
            caseSensitive: false,
          ),
        ),
      ),
    );
  });
  test('five insert targets only; no schema, API or runtime mutation', () {
    final targets = RegExp(
      r'\bINSERT\s+INTO\s+([a-z_]+\.[a-z_]+)',
      caseSensitive: false,
    ).allMatches(executable).map((m) => m.group(1)!).toList();
    expect(targets, _expected().keys.toList());
    expect(
      executable,
      isNot(
        matches(
          RegExp(
            r'\b(UPDATE|DELETE|TRUNCATE|MERGE|CREATE|ALTER|DROP|GRANT|REVOKE|COPY|CALL|PERFORM)\b',
            caseSensitive: false,
          ),
        ),
      ),
    );
    expect(
      executable,
      isNot(
        matches(
          RegExp(
            r'\b(public\.(subscriptions|directory_entities|business_memberships)|auth\.)',
            caseSensitive: false,
          ),
        ),
      ),
    );
    expect(raw, isNot(contains('config.toml')));
    expect(
      executable,
      isNot(matches(RegExp(r'\b(INSERT|SELECT)\s+\*', caseSensitive: false))),
    );
  });
  test('runner-owned atomicity and bounded locking', () {
    expect(
      executable,
      isNot(
        matches(
          RegExp(
            r'\b(BEGIN\s*;|COMMIT\b|ROLLBACK\b|SAVEPOINT\b|START\s+TRANSACTION|PREPARE\s+TRANSACTION)',
            caseSensitive: false,
          ),
        ),
      ),
    );
    expect(
      raw,
      isNot(matches(RegExp(r'transaction\s*=\s*false', caseSensitive: false))),
    );
    expect(_compact(executable), contains('IN ACCESS EXCLUSIVE MODE NOWAIT;'));
  });
  test('all fail-closed checks precede five guarded idempotent inserts', () {
    expect(
      RegExp(
        r'\bON\s+CONFLICT\s+DO\s+NOTHING\b',
        caseSensitive: false,
      ).allMatches(executable),
      hasLength(5),
    );
    expect(
      RegExp(r'\bON\s+CONFLICT\b', caseSensitive: false).allMatches(executable),
      hasLength(5),
    );
    final firstInsert = body.indexOf('INSERT INTO');
    for (final message in [
      'M1b case D:',
      'M1b case C:',
      'M1b case E:',
      'M1b case C-prime:',
      'M1b bundle conflict',
      'M1b bundle item conflict',
      'M1b G plan-version linkage/metadata conflict',
      'M1b term price conflict',
    ])
      expect(
        body.indexOf(message),
        inInclusiveRange(0, firstInsert - 1),
        reason: message,
      );
    expect(body.indexOf('M1b case D:'), lessThan(body.indexOf('M1b case C:')));
    expect(body.indexOf('M1b case C:'), lessThan(body.indexOf('M1b case E:')));
    expect(
      body.indexOf('M1b case E:'),
      lessThan(body.indexOf('M1b case C-prime:')),
    );
    expect(
      body,
      contains(
        'ON a.id = e.id OR (a.plan_id, a.version) = (e.plan_id, e.version)',
      ),
    );
    expect(
      body,
      contains(
        'pg_catalog.to_jsonb(a) IS DISTINCT FROM pg_catalog.to_jsonb(e)',
      ),
    );
  });
  test('final C-prime detector compares original stored code', () {
    expect(
      _compact(body),
      contains(
        "pg_catalog.btrim(pg_catalog.regexp_replace(pg_catalog.lower(pg_catalog.btrim(a.code)), "
        "'[-._[:space:]]+', '_', 'g'), '_') = e.code AND a.code IS DISTINCT FROM e.code",
      ),
    );
    expect(body, contains('RAISE NOTICE \'M1b case F:'));
    expect(
      body,
      isNot(contains('lower(pg_catalog.btrim(a.code)) IS DISTINCT FROM')),
    );
  });
  test('HARDEN-1 and M1a deny-by-default preflight is preserved', () {
    for (final marker in [
      'relrowsecurity AND NOT relforcerowsecurity',
      'a.attacl IS NOT NULL',
      'pg_catalog.has_any_column_privilege',
      'pg_catalog.has_table_privilege',
      'pg_catalog.has_schema_privilege',
      'pg_catalog.pg_has_role',
      'pg_catalog.pg_policy',
      'pg_catalog.pg_default_acl',
      'pg_catalog.acldefault',
      'pg_catalog.pg_publication_tables',
      'pg_catalog.pg_depend',
      'pg_catalog.pg_proc',
      'M1b public/private ACL, proxy or publication exposure',
      'M1b M1a default privilege hardening drift',
    ])
      expect(body, contains(marker), reason: marker);
  });
  test(
    'fingerprints protect unrelated data and metadata; all exact postconditions',
    () {
      expect(
        body,
        contains(
          "n.nspname IN ('public','commercial_private') AND c.relkind = 'r'",
        ),
      );
      expect(
        body,
        contains(
          "FROM ONLY %I.%I t WHERE NOT (pg_catalog.to_jsonb(t)->>''id'' = ANY(\$1))",
        ),
      );
      expect(body, contains('data_current IS DISTINCT FROM data_snapshot'));
      expect(
        body,
        contains('metadata_current IS DISTINCT FROM metadata_snapshot'),
      );
      expect(RegExp(r'\bEXECUTE\b').allMatches(executable), hasLength(1));
      expect(
        body.substring(body.indexOf('EXECUTE pg_catalog.format(')).trimLeft(),
        startsWith('EXECUTE pg_catalog.format(\n        \'SELECT'),
      );
      for (final table in [
        'plans',
        'entitlement_bundles',
        'bundle_items',
        'plan_versions',
        'term_prices',
      ]) {
        expect(body, contains('M1b exact $table postcondition failed'));
      }
    },
  );
  test('SQL gate replays actual migration and rolls all fixtures back', () {
    final sql = _read(
      'supabase/tests/commercial_m1b_catalog_reference_data_test.sql',
    );
    expect(
      RegExp(
        r'\\ir \.\./migrations/00024_commercial_catalog_reference_data\.sql',
      ).allMatches(sql).length,
      greaterThanOrEqualTo(35),
    );
    for (final marker in [
      'C exact code wrong UUID',
      'D canonical UUID',
      'C-prime',
      'E is_active',
      'G wrong plan-version link',
      'F business_legacy',
      'business__pro',
      'BUSINESS_PRO',
      'zero residual fixtures',
    ]) {
      expect(sql, contains(marker), reason: marker);
    }
    expect(sql.trimRight(), endsWith('ROLLBACK;'));
    expect(sql, contains('SELECT * FROM finish();'));
  });
  test(
    'authorities, existing tests, config, seed and production sources unchanged',
    () {
      // Exact accepted checkpoint pins; the original M1b authority remains
      // _baseline for configuration, seed and 00001-00023 source.
      for (final path in ['supabase/config.toml', 'supabase/seed.sql']) {
        expect(_read(path), _git(['show', '$_baseline:$path']), reason: path);
      }
      const catalogCheckpoint = 'dcc736ba7a8dc0b068f6c8bfc11b74566ab756dc';
      const governanceCheckpoint = '611f2dd30a32b730fc254a247dd4701a98e8b4f6';
      const clarifiedContract = '7d1d671e7b837be8b1ffed55116aa495d4922eb5';
      for (final path in [
        'supabase/tests/commercial_m1a_private_catalog_foundation_test.sql',
        'supabase/tests/commercial_harden1_public_plans_exposure_test.sql',
        'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_M1B_CATALOG_REFERENCE_DATA_IMPLEMENTATION_CONTRACT_V1.md',
      ]) {
        expect(
          _read(path),
          _git(['show', '$catalogCheckpoint:$path']),
          reason: path,
        );
      }
      const hardenPath =
          'test/commercial_harden1_public_plans_exposure_migration_test.dart';
      final retainedHarden = _git([
        'show',
        '$governanceCheckpoint:$hardenPath',
      ]);
      final retainedClarifiedHarden = retainedHarden.replaceFirst(
        "const contractCommit = 'f348e0609300858073e8a5143f685fef04362b6b';",
        "// Accepted contract plus committed §35 policy-dependency clarification.\n    const contractCommit = '$clarifiedContract';",
      );
      // Preserve the governance checkpoint and accepted implementation bytes.
      expect(
        retainedClarifiedHarden,
        _git(['show', '8103b551813715feaa1c2b8b3e2b198ae44d75af:$hardenPath']),
      );
      // Only the hand-authored closure declaration and its two exact consumers
      // may extend HARDEN-1; every other historical source byte remains pinned.
      final closureCompatibility =
          "const _m3FormalClosure =\n    '\\n'\n    r'''"
          '${_m3FormalClosure.substring(1)}'
          "''';\n"
          r'''final _closedCommercialTrackControl =
    _commercialTrackControl.replaceFirst(
      '# COMMERCIAL TRACK CURRENT CONTROL',
      '# COMMERCIAL TRACK HISTORICAL M3 AUTHORIZATION',
    ) +
    _m3FormalClosure;
''';
      final retainedClosedHarden = retainedClarifiedHarden
          .replaceFirst(
            'const _migrationName =',
            '${closureCompatibility}const _migrationName =',
          )
          .replaceFirst(
            '? _commercialTrackControl',
            '? _closedCommercialTrackControl',
          )
          .replaceFirst(
            'expect(roadmap.substring(checkpoint.length), _commercialTrackControl);',
            'expect(roadmap.substring(checkpoint.length), _closedCommercialTrackControl);',
          );
      expect(
        retainedClosedHarden,
        _git(['show', '798b2af358735e871463790e746c8f5761fbb989:$hardenPath']),
      );
      // Only the independently hand-authored CUI-1 record and the same two
      // documentary consumers extend the retained HARDEN-1 source.
      final cui1Compatibility =
          "const _cui1Authorization =\n    '\\n'\n    r'''"
          '${_cui1Authorization.substring(1)}'
          "''';\n"
          'final _authorizedCommercialTrackControl =\n'
          '    _closedCommercialTrackControl + _cui1Authorization;\n';
      final authorizedHarden = retainedClosedHarden
            .replaceFirst(
              'const _migrationName =',
              '${cui1Compatibility}const _migrationName =',
            )
            .replaceFirst(
              '? _closedCommercialTrackControl',
              '? _authorizedCommercialTrackControl',
            )
            .replaceFirst(
              'expect(roadmap.substring(checkpoint.length), _closedCommercialTrackControl);',
              'expect(roadmap.substring(checkpoint.length), _authorizedCommercialTrackControl);',
            );
      expect(authorizedHarden, _git(['show', '$_cui1GovernanceCommit:$hardenPath']));
      expect(
        _read(hardenPath),
        authorizedHarden.replaceFirst(
          "import 'package:flutter_test/flutter_test.dart';",
          "import 'package:flutter_test/flutter_test.dart';\nimport 'commercial_cui2a0_admin_business_draft_foundation_migration_test.dart' as cui2a0;",
        ).replaceFirst(
          'void main() {',
          '${_cui1GuardSupportSource}void main() {\n  _registerCui1CompatibilityTests();',
        ).replaceFirst(
          "_git(['diff', '--name-only', _baseline, '--', 'lib']).trim(),",
          "_git(['diff', '--name-only', _baseline, _cui1GovernanceCommit, '--', 'lib']).trim(),",
        ).replaceFirst(
          '? _authorizedCommercialTrackControl\n',
          '? _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions\n',
        ).replaceFirst(
          'expect(roadmap.substring(checkpoint.length), _authorizedCommercialTrackControl);',
          'expect(roadmap.substring(checkpoint.length), _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions);',
        ),
      );
      final approvedDocs = <String, String>{
        'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md':
            '889ff1da4389ba891247cfb5497554ca98fa58b3',
        'docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md':
            governanceCheckpoint,
        'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_M1B_CATALOG_REFERENCE_DATA_IMPLEMENTATION_CONTRACT_V1.md':
            catalogCheckpoint,
        'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_M3_ENTITLEMENT_EVALUATOR_SHADOW_IMPLEMENTATION_CONTRACT_V1.md':
            clarifiedContract,
      };
      final actual = _git([
        'diff',
        '--name-only',
        _baseline,
        _cui1GovernanceCommit,
        '--',
        'lib',
        'docs',
      ]).trim().split('\n')..sort();
      final approved = approvedDocs.keys.toList()..sort();
      expect(actual, approved);
      for (final entry in approvedDocs.entries) {
        final checkpoint = _git(['show', '${entry.value}:${entry.key}']);
        final expected =
            entry.key == 'docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md'
            ? checkpoint.replaceFirst(
                    '# COMMERCIAL TRACK CURRENT CONTROL',
                    '# COMMERCIAL TRACK HISTORICAL M3 AUTHORIZATION',
                  ) +
                  _m3FormalClosure +
                  _cui1Authorization +
                  _cui1MediaReconciliation +
                  _closedRoadmapAdditions
            : checkpoint;
        expect(_read(entry.key), expected, reason: entry.key);
      }
      expect(
        _git([
          'ls-files',
          '--others',
          '--exclude-standard',
          '--',
          'lib',
          'docs',
        ]).trim(),
        isEmpty,
      );
    },
  );
}
