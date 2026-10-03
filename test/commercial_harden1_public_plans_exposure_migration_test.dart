import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Accepted HARDEN-1 facts are fixed here, independently of migration output.
// This source gate cannot prove live SQL/API denial or runner atomicity.
const _baseline = '6d064521307b57f17b45249fcfc3713882b59c61';
const _migrationName = '00023_commercial_public_plans_exposure_hardening.sql';
const _migrationPath = 'supabase/migrations/$_migrationName';
const _m1aTestPath =
    'supabase/tests/commercial_m1a_private_catalog_foundation_test.sql';
const _acceptedMigrationNames = <String>[
  '00001_extensions_and_updated_at_function.sql',
  '00002_regions.sql',
  '00003_profiles_and_staff_roles.sql',
  '00004_roles_permissions_and_staff.sql',
  '00005_directory_entities_and_categories.sql',
  '00006_entity_relationships.sql',
  '00007_business_applications.sql',
  '00008_plans_and_subscriptions.sql',
  '00009_audit_logs.sql',
  '00010_rls_authorization_baseline.sql',
  '00011_business_application_write_hardening.sql',
  '00012_region_reference_data_foundation.sql',
  '00013_region_preference_reference_data_correction.sql',
  '00014_business_application_claim_hardening.sql',
  '00015_business_application_claim_concurrency_hardening.sql',
  '00016_business_application_server_mutations.sql',
  '00017_business_application_creation_authorization_hardening.sql',
  '00018_business_application_activation_ownership_provisioning.sql',
  '00019_business_ownership_management_foundation.sql',
  '00020_business_profile_management.sql',
  '00021_staff_application_operations_foundation.sql',
  '00022_commercial_private_catalog_foundation.sql',
];

String _normalize(String text) => text.replaceAll('\r\n', '\n');
String _read(String path) => _normalize(File(path).readAsStringSync());

String _git(List<String> arguments) {
  // No shell and no Git mutation; the accepted commit is an independent input.
  final result = Process.runSync(
    'git',
    arguments,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    throw StateError('Read-only git $arguments failed: ${result.stderr}');
  }
  return _normalize(result.stdout as String);
}

String _baselineFile(String path) => _git(['show', '$_baseline:$path']);

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

String _compact(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

final _transactionControl = RegExp(
  r'^(?:BEGIN|START\s+TRANSACTION|COMMIT|END|ROLLBACK|ABORT|SAVEPOINT|'
  r'RELEASE\s+(?:SAVEPOINT\s+)?|PREPARE\s+TRANSACTION)\b',
  caseSensitive: false,
);
final _revoke = RegExp(
  r'^REVOKE\s+SELECT\s+ON\s+(?:TABLE\s+)?public\.plans\s+FROM\s+'
  r'([a-z_,\s]+?)(?:\s+RESTRICT)?$',
  caseSensitive: false,
);
final _dropPolicy = RegExp(
  r'^DROP\s+POLICY\s+"?plans_select_all"?\s+ON\s+public\.plans'
  r'(?:\s+RESTRICT)?$',
  caseSensitive: false,
);

void main() {
  late String raw;
  late List<String> statements;
  setUpAll(() {
    raw = _read(_migrationPath);
    statements = _statements(raw);
  });

  test('quoted DO bodies/comments are not top-level transaction control', () {
    final parsed = _statements(r'''
      -- BEGIN; COMMIT;
      /* ROLLBACK; /* SAVEPOINT hidden; */ still comment */
      DO $assertion$
      BEGIN
        IF true THEN RAISE EXCEPTION 'COMMIT; -- not a comment'; END IF;
      END;
      $assertion$;
      REVOKE SELECT ON public.plans FROM PUBLIC, anon, authenticated;
    ''');
    expect(parsed, hasLength(2));
    expect(parsed.any(_transactionControl.hasMatch), isFalse);
    expect(_doBody(parsed.first), isNotNull);
    expect(_revoke.hasMatch(parsed.last), isTrue);
  });

  test('real transaction control after quoted/commented text is detected', () {
    final parsed = _statements(r'''
      DO $$ BEGIN RAISE NOTICE 'quote '' ; COMMIT;'; END; $$;
      /* hidden ; */ COMMIT;
      SAVEPOINT outside;
      START TRANSACTION;
    ''');
    expect(parsed.where(_transactionControl.hasMatch), hasLength(3));
    expect(() => _statements(r'DO $x$ BEGIN;'), throwsFormatException);
    expect(() => _statements('/* unclosed'), throwsFormatException);
  });

  test(
    'standard strings and E-string escapes preserve statement boundaries',
    () {
      final standard = _statements(r"SELECT 'backslash \'; COMMIT;");
      expect(standard, hasLength(2));
      expect(_transactionControl.hasMatch(standard.last), isTrue);
      final escaped = _statements(
        r"SELECT E'quote \'; COMMIT; still literal'; ROLLBACK;",
      );
      expect(escaped, hasLength(2));
      expect(_transactionControl.hasMatch(escaped.last), isTrue);
    },
  );

  test('00023 is unique after the exact immutable 00001–00022 history', () {
    final names =
        Directory('supabase/migrations')
            .listSync(followLinks: false)
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .toList()
          ..sort();
    expect(names.take(22).toList(), _acceptedMigrationNames);
    expect(names.where((name) => name.startsWith('00023_')), [_migrationName]);
    expect(names.indexOf(_migrationName), 22);
    final form = RegExp(r'^\d{5}_[a-z0-9]+(?:_[a-z0-9]+)*\.sql$');
    final numbers = <int>[];
    for (final name in names) {
      expect(form.hasMatch(name), isTrue, reason: name);
      numbers.add(int.parse(name.substring(0, 5)));
    }
    expect(numbers.toSet(), hasLength(numbers.length));
    for (var index = 1; index < numbers.length; index++) {
      expect(numbers[index], greaterThan(numbers[index - 1]));
    }
    for (final name in _acceptedMigrationNames) {
      final path = 'supabase/migrations/$name';
      expect(
        _read(path),
        _baselineFile(path),
        reason: 'History changed: $name',
      );
    }
  });

  test(
    'only bounded locking, assertions, SELECT revocation and policy removal',
    () {
      final roleTargets = <String>[];
      var policyDrops = 0;
      final bodies = <String>[];
      for (final statement in statements) {
        final body = _doBody(statement);
        final revoke = _revoke.firstMatch(statement);
        if (body != null) {
          bodies.add(body);
        } else if (revoke != null) {
          roleTargets.addAll(
            revoke
                .group(1)!
                .split(',')
                .map((role) => role.trim().toLowerCase()),
          );
        } else if (_dropPolicy.hasMatch(statement)) {
          policyDrops++;
        } else {
          fail('Unauthorized migration operation: $statement');
        }
      }
      expect(roleTargets.toSet(), {'public', 'anon', 'authenticated'});
      expect(
        roleTargets,
        hasLength(3),
        reason: 'No duplicate/unrelated revocation',
      );
      expect(policyDrops, 1);
      expect(bodies.length, greaterThanOrEqualTo(2));
      final boundedLock = RegExp(
        r'\bLOCK\s+TABLE\s+ONLY\s+public\.plans\s+IN\s+ACCESS\s+'
        r'EXCLUSIVE\s+MODE\s+NOWAIT\s*;',
        caseSensitive: false,
      );
      expect(boundedLock.allMatches(bodies.join('\n')), hasLength(1));
      expect(boundedLock.hasMatch(bodies.first), isTrue);
      expect(
        bodies.first.indexOf('LOCK TABLE'),
        lessThan(bodies.first.indexOf('IF current_user')),
      );
    },
  );

  test('runner-owned atomicity excludes actual top-level transaction SQL', () {
    expect(statements.any(_transactionControl.hasMatch), isFalse);
    expect(
      raw,
      isNot(
        matches(
          RegExp(r'pg-delta:\s*transaction\s*=\s*false', caseSensitive: false),
        ),
      ),
    );
    expect(
      statements.any(
        (s) => RegExp(
          r'\bCONCURRENTLY\b|^VACUUM\b|^CREATE\s+DATABASE\b',
          caseSensitive: false,
        ).hasMatch(s),
      ),
      isFalse,
    );
  });

  test(
    'assertion blocks cannot hide dynamic commands, DML or persistent objects',
    () {
      final forbidden = RegExp(
        r'\b(?:EXECUTE|PERFORM|CALL|INSERT|UPDATE|DELETE|TRUNCATE|MERGE|COPY|'
        r'GRANT|REVOKE|CREATE|ALTER|DROP|NOTIFY|SET|RESET|COMMIT|ROLLBACK|'
        r'SAVEPOINT|VACUUM|REINDEX|LOCK)\b',
        caseSensitive: false,
      );
      for (final body in statements.map(_doBody).whereType<String>()) {
        // This transaction-local hash-only snapshot preserves pre/post evidence
        // without a persistent helper, data write, or additional catalog object.
        final withoutSnapshot = body.replaceAll(
          RegExp(
            r"\bPERFORM\s+pg_catalog\.set_config\(\s*"
            r"'civilpedia\.harden1_snapshot'\s*,\s*[a-z_][a-z_0-9]*\s*,\s*"
            r'true\s*\)\s*;',
            caseSensitive: false,
          ),
          ' ',
        );
        expect(
          _cleanSql(
            withoutSnapshot.replaceAll(
              RegExp(
                r'\bLOCK\s+TABLE\s+ONLY\s+public\.plans\s+IN\s+ACCESS\s+'
                r'EXCLUSIVE\s+MODE\s+NOWAIT\s*;',
                caseSensitive: false,
              ),
              ' ',
            ),
            maskLiterals: true,
          ),
          isNot(matches(forbidden)),
        );
        expect(
          body,
          matches(RegExp(r'\bRAISE\s+EXCEPTION\b', caseSensitive: false)),
          reason: 'Assertions must fail with an error',
        );
      }
    },
  );

  test(
    'fail-closed catalog assertions precede and follow the security delta',
    () {
      final firstDelta = statements.indexWhere((s) => _revoke.hasMatch(s));
      final drop = statements.indexWhere(_dropPolicy.hasMatch);
      expect(firstDelta, greaterThan(0));
      expect(drop, greaterThan(firstDelta));
      final before = statements
          .take(firstDelta)
          .map(_doBody)
          .whereType<String>()
          .join('\n');
      final after = statements
          .skip(drop + 1)
          .map(_doBody)
          .whereType<String>()
          .join('\n');
      for (final source in [before, after]) {
        for (final fact in [
          'relrowsecurity',
          'relforcerowsecurity',
          'pg_policy',
          'has_table_privilege',
          'has_any_column_privilege',
          'aclexplode',
        ]) {
          expect(source.toLowerCase(), contains(fact), reason: fact);
        }
        expect(
          source,
          matches(RegExp(r'\bRAISE\s+EXCEPTION\b', caseSensitive: false)),
        );
      }
      for (final fact in [
        'current_user',
        'session_user',
        'server_version_num',
        'pg_has_role',
        'attacl',
        'polcmd',
        'polpermissive',
        'polroles',
        'polqual',
        'polwithcheck',
        'plans_select_all',
        'subscriptions_plan_id_fkey',
        'fk_plan_versions_plan_id',
        'pg_constraint',
        'pg_attribute',
      ]) {
        expect(before.toLowerCase(), contains(fact), reason: fact);
      }
      expect(_doBody(statements.last), isNotNull);
    },
  );

  test(
    'no canonical commercial payload, replacement endpoint or config consumer',
    () {
      final executable = _cleanSql(raw).toLowerCase();
      expect(
        executable,
        isNot(
          matches(
            RegExp(
              r'\b(?:1a7b|2e7b|3a7b|4c7b|5d7b)[0-9a-f]{4}-'
              r'[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
            ),
          ),
        ),
      );
      for (final code in [
        'business',
        'business_pro',
        'business_plus',
        'corporate',
      ]) {
        expect(
          executable,
          isNot(contains("'$code'")),
          reason: 'Unauthorized identity',
        );
      }
      for (final surface in [
        'config.toml',
        'seed.sql',
        'remote_config',
        'transaction=false',
        'security definer',
        'alter default privileges',
      ]) {
        expect(executable, isNot(contains(surface)), reason: surface);
      }
      // Explicit operation allowlisting above also excludes projections/RPCs,
      // FORCE/DISABLE RLS, relation/FK rewrites and blanket schema revocation.
    },
  );

  test(
    'only original M1a raw-plans assertion and adjacent wording changed',
    () {
      final old = _baselineFile(_m1aTestPath);
      final current = _read(_m1aTestPath);
      final oldLines = old.split('\n');
      final prefix = oldLines.take(702).join('\n') + '\n';
      final suffix = oldLines.skip(709).join('\n');
      expect(current, startsWith(prefix));
      expect(
        current,
        endsWith(suffix),
        reason: 'Directory line 710 onward is exact',
      );
      final block = current.substring(
        prefix.length,
        current.length - suffix.length,
      );
      final code = _cleanSql(block);
      final assertions = _statements(code);
      expect(
        assertions,
        hasLength(1),
        reason: 'Same two-role assertion, no extra edits',
      );
      expect(code, contains('SELECT is(pg_temp.m1a_result('));
      expect(code, isNot(contains('pg_temp.m1a_read')));
      expect(code, contains("role_name::name), '42501|'"));
      expect(
        code,
        contains("FROM (VALUES ('anon'), ('authenticated')) roles(role_name)"),
      );
      for (var number = 1; number <= 4; number++) {
        expect(
          code,
          contains(
            'c1a20000-0000-4000-8000-'
            '${number.toString().padLeft(12, '0')}',
          ),
        );
      }
      final queries = RegExp(r'\$\$([\s\S]*?)\$\$').allMatches(code).toList();
      expect(queries, hasLength(1));
      final expectedQuery =
          "SELECT count(*)::text FROM public.plans "
          "WHERE id IN ('c1a20000-0000-4000-8000-000000000001', "
          "'c1a20000-0000-4000-8000-000000000002', "
          "'c1a20000-0000-4000-8000-000000000003', "
          "'c1a20000-0000-4000-8000-000000000004')";
      expect(_compact(queries.single.group(1)!), _compact(expectedQuery));
      expect(current, contains('SELECT no_plan()'));
    },
  );

  test('accepted config, seed and commercial authorities remain unchanged', () {
    const paths = <String>[
      'supabase/config.toml',
      'supabase/seed.sql',
      'docs/architecture/CIVILPEDIA_COMMERCIAL_MODEL_V1.md',
      'docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md',
      'docs/architecture/contracts/'
          'CIVILPEDIA_COMMERCIAL_CORE_AUTHORITY_RECONCILIATION_CONTRACT_V1.md',
      'docs/architecture/contracts/'
          'CIVILPEDIA_COMMERCIAL_PUBLICATION_ENTITLEMENT_CONTRACT_V1.md',
      'docs/architecture/contracts/'
          'CIVILPEDIA_COMMERCIAL_SUBSCRIPTION_ENTITLEMENT_ENFORCEMENT_CONTRACT_V1.md',
      'docs/architecture/contracts/'
          'CIVILPEDIA_COMMERCIAL_M1A_PRIVATE_CATALOG_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md',
      'docs/architecture/contracts/'
          'CIVILPEDIA_COMMERCIAL_M1B_CATALOG_REFERENCE_DATA_IMPLEMENTATION_CONTRACT_V1.md',
      'docs/architecture/contracts/'
          'CIVILPEDIA_COMMERCIAL_HARDEN1_PUBLIC_PLANS_EXPOSURE_IMPLEMENTATION_CONTRACT_V1.md',
    ];
    // Exact accepted provenance append; all historical content stays frozen.
    const acceptedAuthorizationAddendum =
        '\n'
        r'''## Post-Acceptance Implementation Authorization Record

```text
CONTRACT_ACCEPTANCE_COMMIT:
6d064521307b57f17b45249fcfc3713882b59c61

CONTRACT_STATE_AT_ACCEPTANCE:
IMPLEMENTATION_AUTHORIZED = NO

POST_ACCEPTANCE_ARCHITECT_IMPLEMENTATION_AUTHORIZATION:
YES

AUTHORIZATION_TIMING:
Issued by ChatGPT Architect in the Civilpedia project conversation
after contract commit/push 6d06452 and before HARDEN-1 implementation began.

AUTHORIZED_SCOPE:
1. supabase/migrations/00023_commercial_public_plans_exposure_hardening.sql
2. supabase/tests/commercial_harden1_public_plans_exposure_test.sql
3. test/commercial_harden1_public_plans_exposure_migration_test.dart
4. supabase/tests/commercial_m1a_private_catalog_foundation_test.sql

M1B_SEED_AUTHORIZED:
NO

ROWS_AUTHORIZED:
0

AUTHORITY:
ChatGPT Architect
```

This addendum persists the already-issued project-conversation authorization. Commit 6d06452 accepted the contract with implementation authorization still NO; that commit itself did not contain implementation authority. The ChatGPT Architect issued the separate YES authorization after the contract commit/push and before implementation began. This record documents that existing authorization and does not retroactively create authority that did not exist.

The authorized implementation scope is exactly the four paths above. The fourth path remains limited to the raw public.plans assertions intentionally invalidated by HARDEN-1 and immediately adjacent wording; the following Directory assertion and all other M1a test content remain preserved.

This provenance record changes no commercial policy, security architecture, executable SQL semantics, OQ status, M1b authority or implementation scope. M1b seed remains unauthorized and ROWS_AUTHORIZED remains 0. The original acceptance metadata and historical acceptance record above remain unchanged and describe the contract state at acceptance. No staging, commit or push is authorized by this addendum.
''';
    for (final path in paths) {
      final expected =
          _baselineFile(path) +
          (path ==
                  'docs/architecture/contracts/'
                      'CIVILPEDIA_COMMERCIAL_HARDEN1_PUBLIC_PLANS_EXPOSURE_IMPLEMENTATION_CONTRACT_V1.md'
              ? acceptedAuthorizationAddendum
              : '');
      expect(_read(path), expected, reason: path);
    }
    final config = _read('supabase/config.toml');
    expect(config, contains('schemas = ["public", "graphql_public"]'));
    expect(config, contains('extra_search_path = ["public", "extensions"]'));
    expect(_cleanSql(_read('supabase/seed.sql')).trim(), isEmpty);
  });

  test(
    'no production Flutter change or raw-plans consumer enters this slice',
    () {
      expect(
        _git(['diff', '--name-only', _baseline, '--', 'lib']).trim(),
        isEmpty,
      );
      expect(
        _git([
          'ls-files',
          '--others',
          '--exclude-standard',
          '--',
          'lib',
        ]).trim(),
        isEmpty,
      );
      final rawPlans = RegExp(
        r'''\.from\s*\(\s*['"]plans['"]|commercial_private''',
        caseSensitive: false,
      );
      for (final file
          in Directory('lib')
              .listSync(recursive: true, followLinks: false)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))) {
        expect(_read(file.path), isNot(matches(rawPlans)), reason: file.path);
      }
    },
  );
}
