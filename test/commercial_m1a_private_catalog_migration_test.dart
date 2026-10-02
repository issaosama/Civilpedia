import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationName = '00022_commercial_private_catalog_foundation.sql';
const _migrationPath = 'supabase/migrations/$_migrationName';
const _tables = <String>[
  'entitlement_bundles',
  'bundle_items',
  'plan_versions',
  'term_prices',
];

// Independent accepted-contract expectations, not an inventory derived from DDL.
// These are source assertions; live ownership, ACLs, atomicity and Data API
// denial are established by the separate PostgreSQL/API evidence gate.
const _columns = <String, Map<String, String>>{
  'entitlement_bundles': {
    'id': 'uuid!',
    'code': 'text!',
    'version': 'integer!',
    'registry_version': 'integer!',
    'status': 'text!',
    'published_at': 'timestamptz?',
    'retired_at': 'timestamptz?',
    'created_at': 'timestamptz!',
  },
  'bundle_items': {
    'id': 'uuid!',
    'bundle_version_id': 'uuid!',
    'capability_key': 'text!',
    'value_kind': 'text!',
    'value_boolean': 'boolean?',
    'value_integer': 'bigint?',
    'value_text': 'text?',
    'is_required': 'boolean!',
    'created_at': 'timestamptz!',
  },
  'plan_versions': {
    'id': 'uuid!',
    'plan_id': 'uuid!',
    'version': 'integer!',
    'bundle_version_id': 'uuid!',
    'pricing_mode': 'text!',
    'name_ar': 'text!',
    'description_ar': 'text?',
    'sort_order': 'integer!',
    'status': 'text!',
    'published_at': 'timestamptz?',
    'retired_at': 'timestamptz?',
    'effective_from': 'timestamptz?',
    'effective_until': 'timestamptz?',
    'created_at': 'timestamptz!',
  },
  'term_prices': {
    'id': 'uuid!',
    'plan_version_id': 'uuid!',
    'pricing_mode': 'text!',
    'version': 'integer!',
    'duration_months': 'integer!',
    'amount_iqd': 'bigint!',
    'currency': 'text!',
    'status': 'text!',
    'published_at': 'timestamptz?',
    'retired_at': 'timestamptz?',
    'effective_from': 'timestamptz?',
    'effective_until': 'timestamptz?',
    'created_at': 'timestamptz!',
  },
};

const _constraints = <String, Map<String, String>>{
  'entitlement_bundles': {
    'entitlement_bundles_pkey': 'primary key (id)',
    'uq_entitlement_bundles_code_version': 'unique (code, version)',
    'chk_entitlement_bundles_code': 'check',
    'chk_entitlement_bundles_version': 'check',
    'chk_entitlement_bundles_registry_version': 'check',
    'chk_entitlement_bundles_lifecycle': 'check',
  },
  'bundle_items': {
    'bundle_items_pkey': 'primary key (id)',
    'fk_bundle_items_bundle_version_id':
        'foreign key (bundle_version_id) references '
        'commercial_private.entitlement_bundles (id)',
    'uq_bundle_items_bundle_key': 'unique (bundle_version_id, capability_key)',
    'chk_bundle_items_capability_key': 'check',
    'chk_bundle_items_typed_value': 'check',
    'chk_bundle_items_integer_value': 'check',
    'chk_bundle_items_text_value': 'check',
  },
  'plan_versions': {
    'plan_versions_pkey': 'primary key (id)',
    'fk_plan_versions_plan_id':
        'foreign key (plan_id) references public.plans (id)',
    'fk_plan_versions_bundle_version_id':
        'foreign key (bundle_version_id) references '
        'commercial_private.entitlement_bundles (id)',
    'uq_plan_versions_plan_version': 'unique (plan_id, version)',
    'uq_plan_versions_id_pricing_mode': 'unique (id, pricing_mode)',
    'chk_plan_versions_version': 'check',
    'chk_plan_versions_pricing_mode': 'check',
    'chk_plan_versions_metadata': 'check',
    'chk_plan_versions_sort_order': 'check',
    'chk_plan_versions_lifecycle': 'check',
    'chk_plan_versions_effective_window': 'check',
  },
  'term_prices': {
    'term_prices_pkey': 'primary key (id)',
    'fk_term_prices_plan_version_pricing_mode':
        'foreign key (plan_version_id, pricing_mode) references '
        'commercial_private.plan_versions (id, pricing_mode)',
    'uq_term_prices_plan_duration_version':
        'unique (plan_version_id, duration_months, version)',
    'chk_term_prices_version': 'check',
    'chk_term_prices_pricing_mode': 'check',
    'chk_term_prices_duration_months': 'check',
    'chk_term_prices_amount_iqd': 'check',
    'chk_term_prices_currency': 'check',
    'chk_term_prices_lifecycle': 'check',
    'chk_term_prices_effective_window': 'check',
  },
};

String _read(String path) =>
    File(path).readAsStringSync().replaceAll('\r\n', '\n');

String _withoutComments(String sql) => sql.replaceAllMapped(
  RegExp(r"('(?:''|[^'])*')|(--[^\n]*)|(/\*[\s\S]*?\*/)"),
  (match) => match.group(1) ?? ' ',
);

String _compact(String sql) => sql
    .toLowerCase()
    .replaceAll('pg_catalog.', '')
    .replaceAll(RegExp(r'\s+'), '');

String _withoutLiterals(String sql) =>
    sql.replaceAll(RegExp(r"'(?:''|[^'])*'"), "''");

// Skip quoted strings and dollar-quoted DO bodies when finding statement
// boundaries. A PL/pgSQL BEGIN is deliberately not top-level transaction SQL.
List<String> _statements(String sql) {
  final result = <String>[];
  var start = 0;
  var index = 0;
  while (index < sql.length) {
    if (sql[index] == "'") {
      index++;
      while (index < sql.length) {
        if (sql[index] != "'") {
          index++;
        } else if (index + 1 < sql.length && sql[index + 1] == "'") {
          index += 2;
        } else {
          index++;
          break;
        }
      }
      continue;
    }
    if (sql[index] == r'$') {
      final delimiter = RegExp(
        r'^\$(?:[a-zA-Z_][a-zA-Z_0-9]*)?\$',
      ).firstMatch(sql.substring(index))?.group(0);
      if (delimiter != null) {
        final end = sql.indexOf(delimiter, index + delimiter.length);
        if (end < 0) throw FormatException('Unclosed dollar-quoted SQL body');
        index = end + delimiter.length;
        continue;
      }
    }
    if (sql[index] == ';') {
      final statement = sql.substring(start, index).trim();
      if (statement.isNotEmpty) result.add(statement);
      start = index + 1;
    }
    index++;
  }
  final remainder = sql.substring(start).trim();
  if (remainder.isNotEmpty) result.add(remainder);
  return result;
}

// CREATE TABLE clauses are comma-separated only at parenthesis depth zero.
List<String> _tableClauses(String statement) {
  final start = statement.indexOf('(');
  final end = statement.lastIndexOf(')');
  if (start < 0 || end <= start) throw FormatException('Missing table body');
  final body = statement.substring(start + 1, end);
  final clauses = <String>[];
  var depth = 0;
  var quoted = false;
  var clauseStart = 0;
  for (var index = 0; index < body.length; index++) {
    final character = body[index];
    if (character == "'") {
      if (quoted && index + 1 < body.length && body[index + 1] == "'") {
        index++;
      } else {
        quoted = !quoted;
      }
    } else if (!quoted) {
      if (character == '(') depth++;
      if (character == ')') depth--;
      if (character == ',' && depth == 0) {
        clauses.add(body.substring(clauseStart, index).trim());
        clauseStart = index + 1;
      }
    }
  }
  clauses.add(body.substring(clauseStart).trim());
  return clauses;
}

void _includes(String source, String fragment, {String? reason}) =>
    expect(_compact(source), contains(_compact(fragment)), reason: reason);

void main() {
  late String sql;
  late List<String> statements;
  late Map<String, List<String>> clauses;
  late Map<String, Map<String, String>> columns;
  late Map<String, String> constraints;

  setUpAll(() {
    sql = _withoutComments(_read(_migrationPath));
    statements = _statements(sql);
    clauses = {};
    columns = {};
    constraints = {};
    for (final statement in statements) {
      final table = RegExp(
        r'^CREATE\s+TABLE\s+commercial_private\.([a-z_]+)\s*\(',
        caseSensitive: false,
      ).firstMatch(statement)?.group(1);
      if (table == null) continue;
      expect(
        clauses.containsKey(table),
        isFalse,
        reason: 'Duplicate $table DDL',
      );
      clauses[table] = _tableClauses(statement);
      columns[table] = {};
      for (final clause in clauses[table]!) {
        final constraint = RegExp(
          r'^CONSTRAINT\s+([a-z_]+)\s+([\s\S]+)$',
          caseSensitive: false,
        ).firstMatch(clause);
        if (constraint != null) {
          final name = constraint.group(1)!;
          expect(constraints.containsKey(name), isFalse);
          constraints[name] = constraint.group(2)!;
        } else {
          final column = RegExp(
            r'^([a-z_]+)\s+([a-z]+)\b',
          ).firstMatch(clause.toLowerCase());
          expect(
            column,
            isNotNull,
            reason: 'Unnamed constraint/column: $clause',
          );
          columns[table]![column!.group(1)!] = clause;
        }
      }
    }
  });

  test('00022 has its unique accepted filename after the historical chain', () {
    final names =
        Directory('supabase/migrations')
            .listSync(followLinks: false)
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .toList()
          ..sort();
    expect(names.where((name) => name.startsWith('00022_')), [_migrationName]);
    expect(names.indexOf(_migrationName), 21);
    expect(names[20], '00021_staff_application_operations_foundation.sql');
  });

  test(
    'runner owns atomicity; DO blocks do not author transaction control',
    () {
      expect(sql, isNot(contains('-- pg-delta: transaction=false')));
      // Check the unstripped text too, since the directive is a comment.
      expect(
        _read(_migrationPath),
        isNot(
          matches(
            RegExp(
              r'pg-delta:\s*transaction\s*=\s*false',
              caseSensitive: false,
            ),
          ),
        ),
      );
      final transactionControl = RegExp(
        r'^(?:BEGIN|START\s+TRANSACTION|COMMIT|END|ROLLBACK|ABORT|'
        r'PREPARE\s+TRANSACTION)\b',
        caseSensitive: false,
      );
      for (final statement in statements) {
        expect(
          transactionControl.hasMatch(statement),
          isFalse,
          reason: 'Authored transaction control: $statement',
        );
        expect(
          RegExp(
            r'\bCONCURRENTLY\b|^VACUUM\b|^CREATE\s+DATABASE\b',
            caseSensitive: false,
          ).hasMatch(statement),
          isFalse,
        );
      }
    },
  );

  test(
    'exact private schema and four tables have no extra persistent objects',
    () {
      expect(clauses.keys.toList(), _tables);
      expect(
        statements.where(
          (statement) => RegExp(
            r'^CREATE\s+TABLE\b',
            caseSensitive: false,
          ).hasMatch(statement),
        ),
        hasLength(4),
      );
      final schemaStatements = statements
          .where(
            (statement) => RegExp(
              r'^CREATE\s+SCHEMA\b',
              caseSensitive: false,
            ).hasMatch(statement),
          )
          .toList();
      expect(schemaStatements, hasLength(1));
      _includes(schemaStatements.single, 'CREATE SCHEMA commercial_private');
      expect(
        sql,
        isNot(matches(RegExp(r'\bIF\s+NOT\s+EXISTS\b', caseSensitive: false))),
      );
      expect(
        sql,
        isNot(
          matches(
            RegExp(
              r'\bCREATE\s+(?:OR\s+REPLACE\s+)?(?:FUNCTION|PROCEDURE|TRIGGER|'
              r'VIEW|MATERIALIZED\s+VIEW|SEQUENCE|TYPE|DOMAIN|ROLE|EXTENSION|INDEX)\b',
              caseSensitive: false,
            ),
          ),
        ),
      );
      expect(
        sql,
        isNot(matches(RegExp(r'\bSECURITY\s+DEFINER\b', caseSensitive: false))),
      );
    },
  );

  for (final table in _tables) {
    test('$table has exact columns, storage types and nullability', () {
      expect(columns[table]!.keys.toList(), _columns[table]!.keys.toList());
      for (final entry in _columns[table]!.entries) {
        final definition = columns[table]![entry.key]!;
        final type = entry.value.substring(0, entry.value.length - 1);
        expect(
          RegExp(
            '^${entry.key}\\s+$type\\b',
            caseSensitive: false,
          ).hasMatch(definition),
          isTrue,
        );
        expect(
          RegExp(r'\bNOT\s+NULL\b', caseSensitive: false).hasMatch(definition),
          entry.value.endsWith('!'),
        );
      }
      _includes(columns[table]!['id']!, 'DEFAULT pg_catalog.gen_random_uuid()');
      _includes(columns[table]!['created_at']!, 'DEFAULT pg_catalog.now()');
      for (final entry in columns[table]!.entries) {
        if (![
          'id',
          'created_at',
          'status',
          'is_required',
          'sort_order',
          if (table == 'term_prices') 'pricing_mode',
          'currency',
        ].contains(entry.key)) {
          expect(
            entry.value,
            isNot(matches(RegExp(r'\bDEFAULT\b', caseSensitive: false))),
          );
        }
      }
    });

    test('$table has exact named constraint kinds and ordered keys', () {
      final actualNames = clauses[table]!
          .map(
            (clause) => RegExp(
              r'^CONSTRAINT\s+([a-z_]+)',
              caseSensitive: false,
            ).firstMatch(clause)?.group(1),
          )
          .whereType<String>()
          .toSet();
      expect(actualNames, _constraints[table]!.keys.toSet());
      for (final entry in _constraints[table]!.entries) {
        _includes(constraints[entry.key]!, entry.value);
        if (entry.key.startsWith('fk_')) {
          _includes(constraints[entry.key]!, 'ON UPDATE RESTRICT');
          _includes(constraints[entry.key]!, 'ON DELETE RESTRICT');
          expect(
            constraints[entry.key],
            isNot(
              matches(
                RegExp(r'\bCASCADE\b|\bDEFERRABLE\b', caseSensitive: false),
              ),
            ),
          );
        }
      }
    });
  }

  test(
    'all 34 names are unique; no inline or extra indexes hide constraints',
    () {
      expect(constraints, hasLength(34));
      for (final table in _tables) {
        for (final definition in columns[table]!.values) {
          expect(
            definition,
            isNot(
              matches(
                RegExp(
                  r'\bPRIMARY\s+KEY\b|\bUNIQUE\b|\bREFERENCES\b|\bCHECK\s*\(',
                  caseSensitive: false,
                ),
              ),
            ),
          );
        }
      }
    },
  );

  test('accepted defaults do not assume a retail plan family', () {
    for (final table in [
      'entitlement_bundles',
      'plan_versions',
      'term_prices',
    ]) {
      _includes(columns[table]!['status']!, "DEFAULT 'draft'");
    }
    _includes(columns['bundle_items']!['is_required']!, 'DEFAULT true');
    _includes(columns['plan_versions']!['sort_order']!, 'DEFAULT 0');
    expect(
      columns['plan_versions']!['pricing_mode'],
      isNot(matches(RegExp(r'\bDEFAULT\b', caseSensitive: false))),
    );
    _includes(columns['term_prices']!['pricing_mode']!, "DEFAULT 'retail'");
    _includes(columns['term_prices']!['currency']!, "DEFAULT 'IQD'");
  });

  test(
    'positive versions, retail duration and integer IQD checks remain exact',
    () {
      for (final table in [
        'entitlement_bundles',
        'plan_versions',
        'term_prices',
      ]) {
        _includes(constraints['chk_${table}_version']!, 'version > 0');
      }
      _includes(
        constraints['chk_entitlement_bundles_registry_version']!,
        'registry_version > 0',
      );
      _includes(
        constraints['chk_plan_versions_pricing_mode']!,
        "pricing_mode IN ('retail', 'custom_quote')",
      );
      _includes(
        constraints['chk_term_prices_pricing_mode']!,
        "pricing_mode = 'retail'",
      );
      _includes(
        constraints['chk_term_prices_duration_months']!,
        'duration_months IN (1, 3, 12)',
      );
      _includes(constraints['chk_term_prices_amount_iqd']!, 'amount_iqd >= 0');
      _includes(constraints['chk_term_prices_currency']!, "currency = 'IQD'");
      expect(
        sql,
        isNot(
          matches(
            RegExp(
              r'\bnumeric\s*\(|\bdouble\s+precision\b|'
              r'\bjsonb?\b|\bprice_paid\b',
              caseSensitive: false,
            ),
          ),
        ),
      );
    },
  );

  test('typed scalar items require exactly their own non-null value', () {
    final check = constraints['chk_bundle_items_typed_value']!;
    for (final kind in ['boolean', 'integer', 'text']) {
      final otherKinds = [
        'boolean',
        'integer',
        'text',
      ].where((other) => other != kind);
      _includes(
        check,
        "(value_kind = '$kind' AND value_$kind IS NOT NULL "
        'AND ${otherKinds.map((other) => 'value_$other IS NULL').join(' AND ')})',
      );
    }
    expect(
      RegExp(r'\bOR\b', caseSensitive: false).allMatches(check),
      hasLength(2),
    );
    _includes(
      constraints['chk_bundle_items_integer_value']!,
      'value_integer IS NULL OR value_integer >= 0',
    );
    final textCheck = constraints['chk_bundle_items_text_value']!;
    _includes(textCheck, 'value_text IS NULL OR');
    _includes(textCheck, "btrim(value_text) <> ''");
    _includes(textCheck, 'char_length(value_text) <= 256');
  });

  test('machine identifiers and Arabic metadata retain accepted checks', () {
    final code = constraints['chk_entitlement_bundles_code']!;
    _includes(code, "code ~ '^[a-z][a-z0-9_]*\$'");
    _includes(code, 'char_length(code) BETWEEN 1 AND 64');
    final key = constraints['chk_bundle_items_capability_key']!;
    _includes(key, 'char_length(capability_key) BETWEEN 1 AND 128');
    expect(key, contains(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$'));
    final metadata = constraints['chk_plan_versions_metadata']!;
    _includes(metadata, "btrim(name_ar) <> ''");
    _includes(metadata, 'description_ar IS NULL OR');
    _includes(metadata, "btrim(description_ar) <> ''");
    _includes(constraints['chk_plan_versions_sort_order']!, 'sort_order >= 0');
  });

  for (final table in ['entitlement_bundles', 'plan_versions', 'term_prices']) {
    test(
      '$table lifecycle retains finite explicit null-aware alternatives',
      () {
        final check = constraints['chk_${table}_lifecycle']!;
        _includes(
          check,
          "(status = 'draft' AND published_at IS NULL "
          'AND retired_at IS NULL)',
        );
        _includes(
          check,
          "(status = 'published' AND published_at IS NOT NULL "
          'AND retired_at IS NULL)',
        );
        _includes(
          check,
          "(status = 'retired' AND published_at IS NOT NULL "
          'AND retired_at IS NOT NULL AND retired_at >= published_at)',
        );
        for (final marker in ['published_at', 'retired_at']) {
          _includes(check, '($marker IS NULL OR isfinite($marker))');
        }
        _includes(check, 'retired_at >= published_at');
      },
    );
  }

  for (final table in ['plan_versions', 'term_prices']) {
    test('$table effective windows require finite ordered endpoints', () {
      final check = constraints['chk_${table}_effective_window']!;
      for (final endpoint in ['effective_from', 'effective_until']) {
        _includes(check, '($endpoint IS NULL OR isfinite($endpoint))');
      }
      _includes(
        check,
        '(effective_until IS NULL OR (effective_from IS NOT NULL '
        'AND effective_until > effective_from))',
      );
      _includes(check, "status = 'draft' OR effective_from IS NOT NULL");
    });
  }

  test(
    'verified creator assertions and all four default classes are explicit',
    () {
      _includes(sql, "current_user <> 'postgres'");
      _includes(sql, "session_user <> 'postgres'");
      _includes(sql, "current_setting('role') <> 'none'");
      _includes(sql, 'pg_catalog.pg_has_role');
      _includes(sql, "'MEMBER'");
      _includes(sql, 'pg_catalog.pg_default_acl');
      expect(sql, contains('RAISE EXCEPTION'));
      // Dynamic commands quote the verified creator identifier, not caller data.
      expect(sql, contains('%I'));
      for (final kind in ['TABLES', 'SEQUENCES', 'FUNCTIONS', 'TYPES']) {
        final privilege = switch (kind) {
          'FUNCTIONS' => 'EXECUTE',
          'TYPES' => 'USAGE',
          _ => 'ALL',
        };
        _includes(
          sql,
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I '
          'REVOKE $privilege ON $kind FROM PUBLIC, anon, authenticated, service_role',
        );
        _includes(
          sql,
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I '
          'IN SCHEMA commercial_private REVOKE $privilege ON $kind '
          'FROM PUBLIC, anon, authenticated, service_role',
        );
      }
      expect(
        sql,
        isNot(
          matches(
            RegExp(
              r'ALTER\s+DEFAULT\s+PRIVILEGES[^;\n]*IN\s+SCHEMA\s+public\b',
              caseSensitive: false,
            ),
          ),
        ),
      );
    },
  );

  test('new schema/tables are revoked, RLS enabled and policies absent', () {
    _includes(
      sql,
      'REVOKE ALL ON SCHEMA commercial_private '
      'FROM PUBLIC, anon, authenticated, service_role',
    );
    for (final table in _tables) {
      _includes(
        sql,
        'ALTER TABLE commercial_private.$table '
        'ENABLE ROW LEVEL SECURITY',
      );
    }
    _includes(
      sql,
      'REVOKE ALL ON TABLE commercial_private.entitlement_bundles, '
      'commercial_private.bundle_items, commercial_private.plan_versions, '
      'commercial_private.term_prices FROM PUBLIC, anon, authenticated, service_role',
    );
    expect(
      sql,
      isNot(
        matches(
          RegExp(r'\bCREATE\s+POLICY\b|\bGRANT\s+', caseSensitive: false),
        ),
      ),
    );
  });

  test('no seed, existing-object mutation, exposure or commercial consumer', () {
    expect(
      _withoutLiterals(sql),
      isNot(
        matches(
          RegExp(
            r'\bINSERT\s+INTO\b|\bDELETE\s+FROM\b|\bTRUNCATE\b|'
            r'\bALTER\s+(?:TABLE|FUNCTION|POLICY|SCHEMA)\s+public\.|'
            r'\bUPDATE\s+public\.|\bDROP\s+(?:TABLE|SCHEMA|FUNCTION|POLICY)\b|'
            r'\bALTER\s+PUBLICATION\b',
            caseSensitive: false,
          ),
        ),
      ),
    );
    final seed = _withoutComments(_read('supabase/seed.sql')).trim();
    expect(seed, isEmpty);
    final config = _read(
      'supabase/config.toml',
    ).split('\n').where((line) => !line.trimLeft().startsWith('#')).join('\n');
    final api = RegExp(
      r'^\[api\]\n([\s\S]*?)(?=^\[|\z)',
      multiLine: true,
    ).firstMatch(config)!.group(1)!;
    expect(api, contains('schemas = ["public", "graphql_public"]'));
    expect(api, contains('extra_search_path = ["public", "extensions"]'));
    expect(api, isNot(contains('commercial_private')));
    for (final file
        in Directory('lib')
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      expect(
        file.readAsStringSync(),
        isNot(contains('commercial_private')),
        reason: 'Unexpected M1a application consumer in ${file.path}',
      );
    }
  });
}
