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

void main() {
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
      // Retain the exact pre-implementation authority, allowing only the
      // historical heading designation and hand-authored formal closure.
      expect(
        _read(roadmapPath),
        authorizedRoadmap.replaceFirst(
              '# COMMERCIAL TRACK CURRENT CONTROL',
              '# COMMERCIAL TRACK HISTORICAL M3 AUTHORIZATION',
            ) +
            _m3FormalClosure,
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
          '--',
          'lib',
          'docs',
          'supabase/config.toml',
          'supabase/seed.sql',
        ]).trim(),
        roadmapPath,
      );
    },
  );
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
