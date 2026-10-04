import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Accepted HARDEN-1 facts are fixed here, independently of migration output.
// This source gate cannot prove live SQL/API denial or runner atomicity.
const _baseline = '6d064521307b57f17b45249fcfc3713882b59c61';
const _roadmapPath = 'docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md';
// Hand-authored Owner/Architect governance oracle; the historical Git checkpoint
// remains fixed and no expectation is generated from the current roadmap.
const _commercialTrackControl =
    '\n'
    r'''# COMMERCIAL TRACK CURRENT CONTROL

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
''';
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
    'original M1a HARDEN-1 checkpoint and accepted M1b compatibility stay exact',
    () {
      final old = _baselineFile(_m1aTestPath);
      // Retain the original HARDEN-1 proof at its accepted implementation
      // checkpoint; M1b later authorized phase-aware fixtures and cleanup.
      final current = _git([
        'show',
        '3c676f1042b5f8e6f6eff6b7cb4681417c7e140f:$_m1aTestPath',
      ]);
      expect(
        _read(_m1aTestPath),
        _git(['show', 'dcc736ba7a8dc0b068f6c8bfc11b74566ab756dc:$_m1aTestPath']),
        reason: 'Only the accepted M1b compatibility; no additional M1a drift',
      );
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
    const acceptedM1bReopeningAddendum =
        '\n'
        r'''## Post-HARDEN-1 M1b Seed Reopening Authorization Record

```text
HARDEN1_IMPLEMENTATION_COMMIT:
3c676f1

HARDEN1_STATUS:
CLOSED / ACCEPTED / IMPLEMENTED

HARDEN1_PREREQUISITE:
SATISFIED

M1B_SEED_REOPENED:
YES

SCOPE_A_AUTHORIZED:
YES — 17 rows

SCOPE_B_AUTHORIZED:
YES — 23 rows

TOTAL_CANONICAL_ROWS_AUTHORIZED:
40

CUTOVER_MODE:
ONE ATOMIC DETERMINISTIC REFERENCE-DATA CUTOVER

ARCHITECT_IMPLEMENTATION_AUTHORIZATION:
YES — M1b REFERENCE DATA ONLY

M1B_DEC_3:
D3-A RATIFIED AND NOW REOPENED AFTER HARDEN-1

AUTHORITY:
ChatGPT Architect
```

This record persists the new ChatGPT Architect decision issued after HARDEN-1 was contracted, accepted, implementation-authorized, implemented, independently security-reviewed, finally Architect-accepted, committed and pushed in `3c676f1` (`3c676f1042b5f8e6f6eff6b7cb4681417c7e140f`, `feat(commercial): harden public plans exposure`). HARDEN-1 satisfies the sequencing prerequisite in §4 and DR-2's blocking raw-public-exposure prerequisite. The Architect explicitly reopens both SCOPE-A and SCOPE-B together: 17 + 23 = 40 canonical reference-data rows, in one atomic deterministic full-catalog cutover. M1b-DEC-3 D3-A remains the governing choice; D3-B standalone SCOPE-B seeding remains rejected.

The original acceptance metadata and §§1–30 remain preserved as historical design, sequencing and acceptance records. This new decision supersedes their earlier deferred / zero-authorized seed disposition for the future full-catalog reference-data implementation only. It does not redesign the accepted catalog: all 40 canonical UUIDs, plan codes, plan versions, bundles, 19 bundle items, nine retail prices, DR-1 sentinel invariants, the fail-closed conflict matrix, Founding and Launch Partner exclusions, Sponsored base-plan exclusion and Corporate Plus-floor semantics remain unchanged. No OQ is closed or reclassified.

### Migration number consequence

M1b's earlier proposed `00023_commercial_catalog_reference_data.sql` is permanently superseded because HARDEN-1 consumed `00023`. The implementing pass must independently verify the actual next free migration number. The expected candidate is `00024_commercial_catalog_reference_data.sql`; it is not created or reserved by this documentation pass. If `00024` is occupied at implementation time, STOP and obtain Architect reauthorization for the actual migration number.

### Public exposure and runtime boundary

The future seed must preserve HARDEN-1: no ordinary raw `public.plans` SELECT, no public plan-name exposure, no price exposure and no entitlement metadata exposure. M1b must not restore grants, policies, proxies or any other access path that weakens HARDEN-1.

Authorization covers only the already-frozen canonical M1b reference-data seed. Reference data != entitlement. It excludes Business Entity subscription or entity-to-plan assignments, purchased terms, payment records, Launch Partner grants, Founding Partner promotion rows, Sponsored campaigns, publication authority, an entitlement evaluator, a Business Center runtime API, a public catalog API and Flutter commercial UI. No commercial runtime authority is added.

### Future implementation surface — not created in this pass

| Expected future path | Boundary |
| --- | --- |
| supabase/migrations/00024_commercial_catalog_reference_data.sql | Canonical reference-data cutover only; independently verify the next free prefix before implementation. |
| supabase/tests/commercial_m1b_catalog_reference_data_test.sql | Focused future M1b reference-data runtime/security gate. |
| test/commercial_m1b_catalog_reference_data_migration_test.dart | Focused future M1b source/inventory gate. |

No production Flutter file is authorized. This pass records authorization only: DO NOT IMPLEMENT YET. No migration, test or seed is created, no runtime action is taken, and no staging, commit or push is authorized.

## Architect Clarification — Conflict Case C′

Authority: **ChatGPT Architect**. Scope: **contract clarification only**.

The `business-pro` example in §16.1 must trigger **Case C′ — STOP** and must not fall through to Case F. The historical `lower(btrim(code))` predicate wording is incomplete relative to its examples. This appended clarification records the effective collision detector, C′ predicate, F boundary and classification precedence for §16.1 and its §23 pre-deployment inventory. The accepted historical text remains preserved.

### Canonical collision normalization

For collision-detection **only**, define exactly:

```text
normalized_code =
btrim(
  regexp_replace(
    lower(btrim(code)),
    '[-._[:space:]]+',
    '_',
    'g'
  ),
  '_'
)
```

Canonical plan codes remain exactly `business`, `business_pro`, `business_plus` and `corporate`.

This normalization is **only a conflict detector**. It must never rewrite a deployed code, rename a row, merge identities or automatically reconcile legacy data. A detected collision raises an exception; it does not authorize normalization of stored data.

### Case C′ — precise predicate

Case C′ applies when all three conditions hold:

1. The row has not already been classified as an exact UUID/code identity case requiring C or D.
2. `normalized_code` equals one of the canonical plan codes.
3. `lower(btrim(code))` is **not** exactly equal to that canonical code.

Result: **STOP / RAISE EXCEPTION**.

For a noncanonical UUID with no prior C/D classification, each of the following normalizes to `business_pro` and must trigger C′: `business-pro`, `business pro`, `business.pro`, `business__pro` and `BUSINESS-PRO`. These near-collisions must not be silently accepted, normalized, renamed, merged or treated as unrelated Case F rows.

### Case F — precise boundary

Case F applies only to unexpected legacy rows that:

- do not use a canonical UUID;
- do not use an exact canonical code;
- do not normalize under the C′ rule to any canonical code;
- do not otherwise trigger C, D, E or G.

`business_legacy`, `company` and `pro_business` may remain Case F if no other conflict rule applies. Case F rows remain untouched and do not abort. A normalized canonical collision cannot be classified as Case F.

### Effective conflict-classification precedence

**D / C → B or E for exact canonical identity → C′ near-collision → F unrelated legacy row.**

- Canonical UUID + different code ⇒ **D**, even if that different code also normalizes to a canonical code.
- Exact canonical code + different UUID ⇒ **C**.
- Exact canonical UUID/code identity ⇒ **B** only when the existing frozen metadata requirements match; incompatible metadata remains **E — STOP**.
- Noncanonical UUID + a near-collision code such as `business-pro` ⇒ **C′ — STOP**.
- **G** remains the plan-version linkage conflict rule and is **STOP**.

### Preserved design and execution boundary

This clarification changes only migration conflict-classification precision. All 40 canonical rows, UUIDs, plan codes, plan identity metadata, plan versions, DR-1 sentinel, bundles, 19 bundle items, nine retail prices, timestamps, exclusions and commercial policy remain unchanged. No OQ is closed, reclassified or otherwise changed. HARDEN-1 security and runtime exclusions remain intact.

M1b implementation remains **authorized in principle** for the existing **SCOPE-A = 17 + SCOPE-B = 23 = 40 rows** under the Post-HARDEN-1 M1b Seed Reopening Authorization Record. Implementation execution is **PAUSED until this clarification is persisted and committed**. This pass does not execute that authority: **do not create 00024, create M1b implementation tests or seed data**. No staging, commit or push is authorized in this pass.

## Architect Clarification #2 — Case-Only / Whitespace C′ Collisions

Authority: **ChatGPT Architect**. Scope: **contract clarification only**.

The Architect confirms that condition 3 in the preceding C′ clarification is incomplete. The following is the **final, controlling C′ predicate** for §16.1, the §23 conflict inventory and the preceding clarification. It supersedes the earlier condition 3 without rewriting historical text.

### Final collision-only normalization and C′ predicate

Keep the existing normalization exactly:

```text
normalized_code =
btrim(
  regexp_replace(
    lower(btrim(code)),
    '[-._[:space:]]+',
    '_',
    'g'
  ),
  '_'
)
```

Canonical codes remain exactly `business`, `business_pro`, `business_plus` and `corporate`.

Case C′ applies when **all** of the following hold:

1. The row has not already been classified by the higher-precedence exact canonical UUID/code cases C or D.
2. `normalized_code` equals one of the canonical plan codes.
3. The **original stored code** is not byte/SQL-text equal to that canonical code:

```sql
code IS DISTINCT FROM canonical_code
```

Result: **STOP / RAISE EXCEPTION**.

Condition 3 must compare the original stored code, without trimming, case conversion or separator normalization. **Do not use `lower(btrim(code)) IS DISTINCT FROM canonical_code`**: that incorrectly excludes case-only and surrounding-space variants from C′.

Normalization is a conflict detector only. No automatic normalization of stored data, rewrite, rename, merge or reconciliation is authorized.

### Classification examples

The table assumes a **noncanonical UUID** and no other conflict. Single quotes delimit the stored code; spaces inside those quotes are part of the stored value.

| Original stored code | `normalized_code` | Classification / result |
| --- | --- | --- |
| `'business_pro'` | `business_pro` | **C — STOP**: exact canonical code with a different UUID |
| `'BUSINESS_PRO'` | `business_pro` | **C′ — STOP** |
| `'Business_Pro'` | `business_pro` | **C′ — STOP** |
| `' business_pro'` | `business_pro` | **C′ — STOP** |
| `'business_pro '` | `business_pro` | **C′ — STOP** |
| `' business_pro '` | `business_pro` | **C′ — STOP** |
| `'business-pro'` | `business_pro` | **C′ — STOP** |
| `'business pro'` | `business_pro` | **C′ — STOP** |
| `'business.pro'` | `business_pro` | **C′ — STOP** |
| `'business__pro'` | `business_pro` | **C′ — STOP** |
| `'BUSINESS-PRO'` | `business_pro` | **C′ — STOP** |
| `'business_legacy'` | `business_legacy` | **F** when otherwise unrelated: untouched, no abort |
| `'company'` | `company` | **F** when otherwise unrelated: untouched, no abort |
| `'pro_business'` | `pro_business` | **F** when otherwise unrelated: untouched, no abort |

### Precedence and final Case F boundary

Preserve **D / C → B or E → C′ → F**.

- Canonical UUID + different stored code ⇒ **D — STOP**.
- Exact canonical stored code + different UUID ⇒ **C — STOP**.
- Exact canonical UUID/code identity ⇒ **B** only if the frozen metadata matches; otherwise **E — STOP**.
- Noncanonical UUID + any canonical-normalizing but non-exact stored code ⇒ **C′ — STOP**.
- Unrelated noncanonical UUID/code that does not normalize to a canonical code ⇒ **F**, provided no other conflict applies.
- **G** remains a separate plan-version linkage conflict requiring **STOP**.

Case F applies **only** when the row does not use a canonical UUID, does not use an exact canonical code, does not normalize to any canonical code, and does not otherwise trigger C, D, E or G. The `business_legacy`, `company` and `pro_business` examples remain untouched and do not abort when otherwise unrelated. Case F cannot capture a normalized canonical collision.

### Preserved design, authority and implementation pause

No canonical UUID or row definition changes. The four plan identities, four plan versions, four bundles, 19 bundle items, nine retail prices, DR-1 sentinel, timestamps, exclusions and commercial policy remain unchanged. No OQ is closed, reclassified or otherwise changed. HARDEN-1 remains intact.

M1b implementation authorization remains valid **in principle** for **SCOPE-A = 17 + SCOPE-B = 23 = 40 canonical rows**. Execution remains **PAUSED until clarification #2 is persisted and committed**. This pass creates no 00024, M1b SQL test, M1b Dart implementation test or seed, and does not modify 00022/00023 or production Flutter. Only this contract append and the exact corresponding M1b snapshot expectation in the HARDEN-1 Dart static test are authorized. No semantic HARDEN-1 assertion may be weakened. No staging, commit or push is authorized.

## Architect Clarification — Predecessor Gate Compatibility After Canonical Seed

Authority: **ChatGPT Architect**. Scope: **contract clarification only**.

Independent M1b implementation review reports that `00024` is technically correct, the M1b gate passes **378/378**, HARDEN-1 security remains correct, and atomicity and conflict handling pass. The accepted predecessor M1a and HARDEN-1 SQL gates are nevertheless RED after `00024`: they retain pre-M1b zero-seed assumptions, and M1a fixtures reuse the now-canonical plan codes. This is predecessor-test compatibility evidence, not a redesign of M1b.

### Superseded sufficiency premise and governing principle

The earlier statement that **"the three M1b implementation files are sufficient and no existing test/gate requires editing"** is **SUPERSEDED** by this independent runtime review evidence. This clarification supersedes the no-existing-test-edit sufficiency premise in §21 and inherited M1b implementation guidance. Historical text remains preserved.

The canonical catalog is an intentional accepted phase transition. Predecessor tests must preserve their original security and foundation purpose while accepting both the verified pre-M1b empty reference-data state and the exact accepted post-M1b canonical baseline. Security assertions must not be weakened to make tests green.

### M1a phase-aware reference-data expectations

| Verified phase | `plan_versions` | `entitlement_bundles` | `bundle_items` | `term_prices` | Accepted state |
| --- | ---: | ---: | ---: | ---: | --- |
| `00024` has NOT been applied | 0 | 0 | 0 | 0 | Preserve the original exact zero-seed expectations. |
| `00024` HAS been applied | 4 | 4 | 19 | 9 | Only the exact authorized M1b canonical reference-data baseline is accepted. |

Use verified local migration-history authority or another deterministic explicit phase detector. Non-empty tables alone never establish phase or acceptance. The post-`00024` state must match the frozen M1b identities, relationships, values and metadata; the counts are not permission for arbitrary rows. No unrelated or extra private row becomes acceptable.

### Narrow M1a fixture-code compatibility

Only the four colliding disposable fixture codes and directly corresponding expected literals may change:

| Historical fixture code | Authorized test-only replacement |
| --- | --- |
| `business` | `m1a_fixture_plan_01` |
| `business_pro` | `m1a_fixture_plan_02` |
| `business_plus` | `m1a_fixture_plan_03` |
| `corporate` | `m1a_fixture_plan_04` |

Preserve existing fixture UUIDs unless objectively impossible, and preserve fixture relationships and test purpose. Replacement codes must not normalize to any canonical M1b code and must not be interpreted as commercial product identities. No production migration or data is changed.

### HARDEN-1 phase-aware expectations and privacy

Before `00024`, retain the original exact zero expectations for production plans, canonical M1b identities and private catalog seed. After verified `00024`, expect exactly the frozen canonical baseline: **4 plans + 4 plan versions + 4 bundles + 19 items + 9 prices = 40**.

Both phases must still prove raw `public.plans` denial, no replacement public API, private `commercial_private` access boundaries, and that reference data creates no entitlement, subscription or publication authority. HARDEN-1 privacy, grants and RLS are not relaxed.

### Fixture cleanup — exact baseline restoration

Capture and validate the relevant accepted phase baseline **before** creating fixtures. After cleanup, prove that row counts, canonical identities, security state and relevant fingerprints return **exactly** to that pre-fixture baseline. This applies both before and after `00024`. Unconditional zero-row cleanup expectations must not replace a valid seeded baseline; baseline restoration must not permit residual fixture rows or changed canonical data.

### Future compatibility-edit surface and execution boundary

The smallest newly authorized future predecessor SQL compatibility surface is exactly:

1. `supabase/tests/commercial_m1a_private_catalog_foundation_test.sql`
2. `supabase/tests/commercial_harden1_public_plans_exposure_test.sql`

These compatibility edits begin **only after this clarification is persisted and committed**. This documentary pass does not edit either predecessor SQL test.

The existing three uncommitted M1b implementation files remain authorized and unchanged in principle. **M1b FINAL ACCEPTANCE IS PAUSED** pending predecessor-gate compatibility reconciliation. This pass must not modify `00024`, the M1b SQL test or the M1b Dart implementation test.

Because the HARDEN-1 Dart test freezes the exact M1b contract, this pass permits only the necessary mechanical expected-snapshot reconciliation in `test/commercial_harden1_public_plans_exposure_migration_test.dart`. No semantic assertion may be removed, weakened, broadened or bypassed. Only the focused snapshot/static test is run in this pass.

### Preserved design, authority and carry-forward observations

All 40 canonical rows, UUIDs, codes, price and bundle matrices, DR-1 sentinel, timestamps, exclusions, prior C′ clarifications and C/C′/D/E/F/G semantics remain unchanged. HARDEN-1 grants/RLS and `00024` executable SQL are unchanged. No OQ is closed, reclassified or otherwise changed. No M1b runtime entitlement, subscription, payment or publication authority is granted.

The independent review observations **Supabase CLI runner file-atomicity wording** and **broad ID-based fingerprint latent limitation** are recorded as non-blocking carry-forward observations only. Neither authorizes an implementation change in this pass, and neither is an M1b acceptance blocker.

No database operation, SQL-test correction, staging, commit or push is authorized in this clarification pass.
''';
    for (final path in paths) {
      final expected =
          _baselineFile(path) +
          (path ==
                  'docs/architecture/contracts/'
                      'CIVILPEDIA_COMMERCIAL_HARDEN1_PUBLIC_PLANS_EXPOSURE_IMPLEMENTATION_CONTRACT_V1.md'
              ? acceptedAuthorizationAddendum
              : path ==
                    'docs/architecture/contracts/'
                        'CIVILPEDIA_COMMERCIAL_M1B_CATALOG_REFERENCE_DATA_IMPLEMENTATION_CONTRACT_V1.md'
              ? acceptedM1bReopeningAddendum
              : path == _roadmapPath
              ? _commercialTrackControl
              : '');
      expect(_read(path), expected, reason: path);
    }
    final config = _read('supabase/config.toml');
    expect(config, contains('schemas = ["public", "graphql_public"]'));
    expect(config, contains('extra_search_path = ["public", "extensions"]'));
    expect(_cleanSql(_read('supabase/seed.sql')).trim(), isEmpty);
  });

  test('commercial M3 governance preserves the checkpoint and contract', () {
    final roadmap = _read(_roadmapPath);
    final checkpoint = _baselineFile(_roadmapPath);
    expect(roadmap.substring(0, checkpoint.length), checkpoint);
    expect(roadmap.substring(checkpoint.length), _commercialTrackControl);
    expect(
      RegExp(
        r'^# COMMERCIAL TRACK CURRENT CONTROL$',
        multiLine: true,
      ).allMatches(roadmap),
      hasLength(1),
    );
    // Accepted contract plus committed §35 policy-dependency clarification.
    const contractCommit = '7d1d671e7b837be8b1ffed55116aa495d4922eb5';
    const contractPath =
        'docs/architecture/contracts/'
        'CIVILPEDIA_COMMERCIAL_M3_ENTITLEMENT_EVALUATOR_SHADOW_IMPLEMENTATION_CONTRACT_V1.md';
    final contract = _read(contractPath);
    expect(contract, _git(['show', '$contractCommit:$contractPath']));
    expect(
      contract,
      contains('DOCUMENT_STATUS: ACCEPTED — CANONICAL M3 IMPLEMENTATION CONTRACT'),
    );
    expect(contract, contains('IMPLEMENTATION_AUTHORIZED: NO'));
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
