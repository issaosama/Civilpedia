import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readNormalized(String path) =>
    File(path).readAsStringSync().replaceAll('\r\n', '\n');

String _function(String sql, String name) {
  final start = sql.indexOf('CREATE OR REPLACE FUNCTION public.$name');
  expect(start, isNonNegative, reason: 'Missing function $name');
  final nextFunction = sql.indexOf('CREATE OR REPLACE FUNCTION public.', start + 1);
  return sql.substring(start, nextFunction < 0 ? sql.length : nextFunction);
}

void main() {
  late String rls;
  late String writeHardening;
  late String mutations;
  late String creation;
  late String activation;
  late String ownership;
  late String profileManagement;
  late String staff;
  late String allSecurityMigrations;

  setUpAll(() {
    rls = _readNormalized(
      'supabase/migrations/00010_rls_authorization_baseline.sql',
    );
    writeHardening = _readNormalized(
      'supabase/migrations/00011_business_application_write_hardening.sql',
    );
    mutations = _readNormalized(
      'supabase/migrations/00016_business_application_server_mutations.sql',
    );
    creation = _readNormalized(
      'supabase/migrations/00017_business_application_creation_authorization_hardening.sql',
    );
    activation = _readNormalized(
      'supabase/migrations/00018_business_application_activation_ownership_provisioning.sql',
    );
    ownership = _readNormalized(
      'supabase/migrations/00019_business_ownership_management_foundation.sql',
    );
    profileManagement = _readNormalized(
      'supabase/migrations/00020_business_profile_management.sql',
    );
    staff = _readNormalized(
      'supabase/migrations/00021_staff_application_operations_foundation.sql',
    );
    allSecurityMigrations = [
      rls,
      _readNormalized(
        'supabase/migrations/00013_region_preference_reference_data_correction.sql',
      ),
      _readNormalized(
        'supabase/migrations/00014_business_application_claim_hardening.sql',
      ),
      _readNormalized(
        'supabase/migrations/00015_business_application_claim_concurrency_hardening.sql',
      ),
      mutations,
      creation,
      activation,
      ownership,
      profileManagement,
      staff,
    ].join('\n');
  });

  group('RLS and direct-table authority', () {
    test('all accepted protected tables have RLS enabled', () {
      for (final table in [
        'profiles',
        'roles',
        'permissions',
        'role_permissions',
        'staff_memberships',
        'business_memberships',
        'business_applications',
        'application_contacts',
        'application_visits',
        'application_notes',
        'subscriptions',
        'audit_logs',
      ]) {
        expect(
          RegExp(
            'ALTER TABLE public\\.$table\\s+ENABLE ROW LEVEL SECURITY;',
          ).hasMatch(rls),
          isTrue,
          reason: 'RLS enablement missing for public.$table',
        );
      }
      final preferences = _readNormalized(
        'supabase/migrations/00013_region_preference_reference_data_correction.sql',
      );
      expect(
        preferences,
        contains(
          'ALTER TABLE public.region_preferences ENABLE ROW LEVEL SECURITY;',
        ),
      );
    });

    test('profile ownership is anchored to auth.uid for every write/read path', () {
      expect(
        rls,
        contains(
          'CREATE POLICY "profiles_select_own" ON public.profiles\n'
          '  FOR SELECT TO authenticated\n'
          '  USING (user_id = auth.uid());',
        ),
      );
      expect(
        rls,
        contains(
          'CREATE POLICY "profiles_insert_own" ON public.profiles\n'
          '  FOR INSERT TO authenticated\n'
          '  WITH CHECK (user_id = auth.uid());',
        ),
      );
      expect(
        rls,
        contains(
          'CREATE POLICY "profiles_update_own" ON public.profiles\n'
          '  FOR UPDATE TO authenticated\n'
          '  USING (user_id = auth.uid())\n'
          '  WITH CHECK (user_id = auth.uid());',
        ),
      );
      expect(rls, isNot(contains('GRANT DELETE ON public.profiles')));
    });

    test('business ownership reads remain actor-bound and mutations stay RPC-only', () {
      expect(
        rls,
        contains(
          'CREATE POLICY "business_memberships_select_own" ON public.business_memberships\n'
          '  FOR SELECT TO authenticated\n'
          '  USING (user_id = auth.uid());',
        ),
      );
      expect(
        rls,
        contains(
          'CREATE POLICY "business_applications_select_own" ON public.business_applications\n'
          '  FOR SELECT TO authenticated\n'
          '  USING (applicant_user_id = auth.uid());',
        ),
      );
      expect(
        writeHardening,
        contains(
          'REVOKE UPDATE ON public.business_applications FROM authenticated;',
        ),
      );
      expect(
        writeHardening,
        contains(
          'DROP POLICY "business_applications_update_own" ON public.business_applications;',
        ),
      );
      expect(
        creation,
        contains(
          'REVOKE INSERT ON public.business_applications FROM authenticated;',
        ),
      );
      expect(
        creation,
        contains(
          'DROP POLICY "business_applications_insert_own"\n'
          '  ON public.business_applications;',
        ),
      );
    });

    test('staff, audit, billing, and workflow tables receive no client grants', () {
      for (final table in [
        'roles',
        'permissions',
        'role_permissions',
        'staff_memberships',
        'subscriptions',
        'audit_logs',
        'application_contacts',
        'application_visits',
        'application_notes',
      ]) {
        expect(
          RegExp(
            'GRANT\\s+[^;]+\\s+ON\\s+public\\.$table\\s+TO\\s+(?:anon|authenticated)',
            caseSensitive: false,
          ).hasMatch(allSecurityMigrations),
          isFalse,
          reason: 'Unexpected client table grant on public.$table',
        );
      }
      expect(
        rls,
        contains('REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;'),
      );
      expect(
        rls,
        contains(
          'REVOKE ALL ON ALL TABLES IN SCHEMA public FROM authenticated;',
        ),
      );
    });
  });

  group('SECURITY DEFINER and actor authority', () {
    test('security-sensitive RPCs use a controlled search path', () {
      final functions = <String, String>{
        'submit_business_application': mutations,
        'staff_begin_application_review': mutations,
        'staff_approve_business_application': mutations,
        'create_new_business_application': activation,
        'staff_activate_business_application': activation,
        'list_my_businesses': ownership,
        'list_business_members': ownership,
        'get_managed_business_profile': profileManagement,
        'update_managed_business_profile': profileManagement,
        'get_staff_application_capabilities': staff,
        'list_staff_business_applications': staff,
        'get_staff_business_application_detail': staff,
      };

      for (final entry in functions.entries) {
        final body = _function(entry.value, entry.key);
        expect(body, contains('SECURITY DEFINER'), reason: entry.key);
        expect(
          body,
          contains('SET search_path = public, pg_temp'),
          reason: entry.key,
        );
      }
    });

    test('client-facing RPC identities derive from auth.uid, not parameters', () {
      for (final entry in <String, String>{
        'submit_business_application': mutations,
        'staff_begin_application_review': mutations,
        'create_new_business_application': activation,
        'staff_activate_business_application': activation,
        'list_my_businesses': ownership,
        'list_business_members': ownership,
        'get_managed_business_profile': profileManagement,
        'update_managed_business_profile': profileManagement,
        'get_staff_application_capabilities': staff,
        'list_staff_business_applications': staff,
        'get_staff_business_application_detail': staff,
      }.entries) {
        final body = _function(entry.value, entry.key);
        expect(body, contains('v_actor uuid := auth.uid()'), reason: entry.key);
        expect(body, isNot(contains('p_actor_user_id')), reason: entry.key);
        expect(body, isNot(contains('p_user_id')), reason: entry.key);
      }
    });

    test('business and staff RPCs enforce canonical permission checks', () {
      expect(
        _function(ownership, 'list_business_members'),
        contains('has_business_management_access(p_entity_id)'),
      );
      for (final name in [
        'staff_begin_application_review',
        'staff_approve_business_application',
      ]) {
        expect(
          _function(mutations, name),
          contains('public.has_staff_application_permission'),
          reason: name,
        );
      }
      for (final name in [
        'list_staff_business_applications',
        'get_staff_business_application_detail',
      ]) {
        expect(
          _function(staff, name),
          contains("'business_applications.read'"),
          reason: name,
        );
        expect(_function(staff, name), contains("ERRCODE = 'P0PER'"));
      }
    });
  });

  group('execute grants and secret safety', () {
    test('protected RPCs are revoked from anon and granted only as intended', () {
      for (final migration in [creation, activation, ownership, profileManagement, staff]) {
        expect(
          RegExp(
            r'GRANT EXECUTE ON FUNCTION[\s\S]*?TO anon;',
            caseSensitive: false,
          ).hasMatch(migration),
          isFalse,
        );
      }
      for (final expectedGrant in [
        'GRANT EXECUTE ON FUNCTION public.create_new_business_application(jsonb)\n'
            '  TO authenticated;',
        'GRANT EXECUTE ON FUNCTION public.list_my_businesses()\n'
            '  TO authenticated;',
        'GRANT EXECUTE ON FUNCTION public.get_staff_application_capabilities()\n'
            '  TO authenticated;',
      ]) {
        expect(allSecurityMigrations, contains(expectedGrant));
      }
    });

    test('internal helpers remain non-client-executable', () {
      expect(
        creation,
        contains(
          'REVOKE EXECUTE ON FUNCTION public.guard_claim_application_insert()\n'
          '  FROM PUBLIC, anon, authenticated;',
        ),
      );
      expect(
        ownership,
        contains(
          'REVOKE EXECUTE ON FUNCTION public.has_business_management_access(uuid)\n'
          '  FROM PUBLIC, anon, authenticated;',
        ),
      );
      expect(
        profileManagement,
        contains(
          'REVOKE EXECUTE ON FUNCTION public.managed_business_profile_projection(uuid)\n'
          '  FROM PUBLIC, anon, authenticated;',
        ),
      );
      expect(
        mutations,
        contains(
          'REVOKE EXECUTE ON FUNCTION public.has_staff_application_permission(text) FROM PUBLIC;',
        ),
      );
      expect(
        mutations,
        contains(
          'REVOKE EXECUTE ON FUNCTION public.append_audit_log(\n'
          '  uuid, text, text, uuid, jsonb, jsonb, text\n'
          ') FROM PUBLIC;',
        ),
      );
    });

    test('client and CI sources contain no real privileged key material', () {
      final sourceFiles = <File>[];
      for (final root in ['lib', 'test']) {
        sourceFiles.addAll(
          Directory(root)
              .listSync(recursive: true, followLinks: false)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart')),
        );
      }
      final jwt = RegExp(
        r'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}',
      );
      final secretKey = RegExp(r'sb_secret_[A-Za-z0-9_-]{16,}');
      for (final file in sourceFiles) {
        final source = _readNormalized(file.path);
        expect(jwt.hasMatch(source), isFalse, reason: file.path);
        expect(secretKey.hasMatch(source), isFalse, reason: file.path);
      }

      final flutterSources = Directory('lib')
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      for (final file in flutterSources) {
        final source = _readNormalized(file.path);
        expect(
          RegExp(r'''['"]service_role['"]''').hasMatch(source),
          isFalse,
          reason: file.path,
        );
        expect(
          source.contains('SUPABASE_SERVICE_ROLE'),
          isFalse,
          reason: file.path,
        );
      }

      final workflow = _readNormalized('.github/workflows/flutter_quality.yml');
      expect(workflow, isNot(contains('SUPABASE_SERVICE_ROLE')));
      expect(workflow, isNot(contains('sb_secret_')));
      expect(workflow, isNot(contains(r'${{ secrets.')));
    });
  });
}
