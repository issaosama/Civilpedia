import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// Independent frozen M1b expectations: accepted sections 7-15 and final C'.
// Static evidence does not replace PostgreSQL, HTTP or runner atomicity.
const _baseline = 'ebaf5f7b4402366285e214eec99735a931b69d8d';
const _path = 'supabase/migrations/00024_commercial_catalog_reference_data.sql';
const _time = '2026-01-01 00:00:00+00';
const _sentinel = '__AR_LOCALIZATION_PENDING__';
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
void main() {
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
      expect(files, hasLength(25));
      expect(
        files[23].uri.pathSegments.last,
        '00024_commercial_catalog_reference_data.sql',
      );
      expect(
        files.last.uri.pathSegments.last,
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
      expect(
        _read(hardenPath),
        retainedHarden.replaceFirst(
          "const contractCommit = 'f348e0609300858073e8a5143f685fef04362b6b';",
          "// Accepted contract plus committed §35 policy-dependency clarification.\n    const contractCommit = '$clarifiedContract';",
        ),
      );
      final approvedDocs = <String, String>{
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
        '--',
        'lib',
        'docs',
      ]).trim().split('\n')..sort();
      final approved = approvedDocs.keys.toList()..sort();
      expect(actual, approved);
      for (final entry in approvedDocs.entries) {
        expect(
          _read(entry.key),
          _git(['show', '${entry.value}:${entry.key}']),
          reason: entry.key,
        );
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
