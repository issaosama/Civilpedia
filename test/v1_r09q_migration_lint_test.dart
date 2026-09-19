import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationDirectoryPath = 'supabase/migrations';
const _configPath = 'supabase/config.toml';

const _acceptedBaseline = <int, String>{
  1: '00001_extensions_and_updated_at_function.sql',
  2: '00002_regions.sql',
  3: '00003_profiles_and_staff_roles.sql',
  4: '00004_roles_permissions_and_staff.sql',
  5: '00005_directory_entities_and_categories.sql',
  6: '00006_entity_relationships.sql',
  7: '00007_business_applications.sql',
  8: '00008_plans_and_subscriptions.sql',
  9: '00009_audit_logs.sql',
  10: '00010_rls_authorization_baseline.sql',
  11: '00011_business_application_write_hardening.sql',
  12: '00012_region_reference_data_foundation.sql',
  13: '00013_region_preference_reference_data_correction.sql',
  14: '00014_business_application_claim_hardening.sql',
  15: '00015_business_application_claim_concurrency_hardening.sql',
  16: '00016_business_application_server_mutations.sql',
  17: '00017_business_application_creation_authorization_hardening.sql',
  18: '00018_business_application_activation_ownership_provisioning.sql',
  19: '00019_business_ownership_management_foundation.sql',
  20: '00020_business_profile_management.sql',
  21: '00021_staff_application_operations_foundation.sql',
};

String _readNormalized(String path) =>
    File(path).readAsStringSync().replaceAll('\r\n', '\n');

void main() {
  late List<String> migrationNames;
  late List<int> migrationNumbers;

  setUpAll(() {
    migrationNames = Directory(_migrationDirectoryPath)
        .listSync(followLinks: false)
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .toList()
      ..sort();
    migrationNumbers = migrationNames
        .map((name) => int.parse(name.substring(0, 5)))
        .toList();
  });

  test('migration filenames use one canonical numeric-prefix form', () {
    final canonicalName = RegExp(r'^\d{5}_[a-z0-9]+(?:_[a-z0-9]+)*\.sql$');

    expect(migrationNames, isNotEmpty);
    for (final name in migrationNames) {
      expect(
        canonicalName.hasMatch(name),
        isTrue,
        reason: 'Non-canonical migration filename: $name',
      );
    }
  });

  test('numeric migration prefixes are unique and strictly increasing', () {
    expect(migrationNumbers.toSet(), hasLength(migrationNumbers.length));
    for (var index = 1; index < migrationNumbers.length; index++) {
      expect(
        migrationNumbers[index],
        greaterThan(migrationNumbers[index - 1]),
        reason: 'Migration prefixes must increase in filename order.',
      );
    }
  });

  test('accepted historical baseline through 00021 remains exact', () {
    for (final entry in _acceptedBaseline.entries) {
      final matchingPrefix =
          '${entry.key.toString().padLeft(5, '0')}_';
      final matches = migrationNames
          .where((name) => name.startsWith(matchingPrefix))
          .toList();

      expect(
        matches,
        [entry.value],
        reason: 'Historical migration ${entry.key} drifted or collided.',
      );
    }
  });

  test('migration inventory is deterministic and collision-free', () {
    final secondRead = Directory(_migrationDirectoryPath)
        .listSync(followLinks: false)
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .toList()
      ..sort();

    expect(secondRead, migrationNames);
    expect(migrationNames.toSet(), hasLength(migrationNames.length));
  });

  test('configured seed path resolves inside supabase to an existing file', () {
    final config = _readNormalized(_configPath);
    final seedSection = RegExp(
      r'^\[db\.seed\]\n(?<body>.*?)(?=^\[|\z)',
      multiLine: true,
      dotAll: true,
    ).firstMatch(config);
    expect(seedSection, isNotNull, reason: 'Missing [db.seed] configuration.');

    final body = seedSection!.namedGroup('body')!;
    expect(
      RegExp(r'^enabled\s*=\s*true$', multiLine: true).hasMatch(body),
      isTrue,
    );
    final paths = RegExp(
      r'^sql_paths\s*=\s*\[\s*"([^"]+)"\s*\]$',
      multiLine: true,
    ).firstMatch(body);
    expect(paths, isNotNull, reason: 'Expected one configured seed path.');

    final configuredPath = paths!.group(1)!;
    expect(configuredPath, './seed.sql');
    final seed = File('supabase/${configuredPath.substring(2)}');
    expect(seed.existsSync(), isTrue, reason: '${seed.path} is missing.');
    expect(
      seed.absolute.path.startsWith(Directory('supabase').absolute.path),
      isTrue,
      reason: 'Configured seed must stay inside supabase/.',
    );
  });
}
