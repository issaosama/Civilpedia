import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationPath =
    'supabase/migrations/00021_staff_application_operations_foundation.sql';
const _staffMutationsPath =
    'supabase/migrations/00016_business_application_server_mutations.sql';
const _activationPath =
    'supabase/migrations/00018_business_application_activation_ownership_provisioning.sql';

String _function(String sql, String name) {
  final start = sql.indexOf('CREATE OR REPLACE FUNCTION public.$name');
  expect(start, isNonNegative, reason: 'missing function $name');
  final end = sql.indexOf(r'$fn$;', start);
  expect(end, isNonNegative, reason: 'unterminated function $name');
  return sql.substring(start, end + r'$fn$;'.length);
}

String _squash(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  late String migration;
  late String capabilities;
  late String queue;
  late String detail;

  setUpAll(() {
    migration = File(_migrationPath).readAsStringSync();
    capabilities = _function(
      migration,
      'get_staff_application_capabilities',
    );
    queue = _function(migration, 'list_staff_business_applications');
    detail = _function(
      migration,
      'get_staff_business_application_detail',
    );
  });

  group('V1-R07 permission and canonical authority', () {
    test('adds business_applications.read and assigns only the existing role', () {
      final sql = _squash(migration);
      expect(sql, contains("'business_applications.read'"));
      expect(sql, contains("r.code = 'application_reviewer'"));
      expect(sql, contains("p.code = 'business_applications.read'"));
      expect(migration, isNot(contains('CREATE TABLE public.roles')));
      expect(migration, isNot(contains('INSERT INTO public.staff_memberships')));
    });

    test('capability RPC has no caller-supplied actor argument', () {
      expect(
        migration,
        contains(
          'CREATE OR REPLACE FUNCTION '
          'public.get_staff_application_capabilities()\nRETURNS jsonb',
        ),
      );
      expect(capabilities, contains('v_actor uuid := auth.uid()'));
      expect(capabilities, isNot(contains('p_user')));
      expect(capabilities, isNot(contains('p_actor')));
    });

    test('capabilities use only the canonical staff permission chain', () {
      expect(capabilities, contains('FROM public.staff_memberships sm'));
      expect(
        capabilities,
        contains('JOIN public.role_permissions rp ON rp.role_id = sm.role_id'),
      );
      expect(
        capabilities,
        contains('JOIN public.permissions perm ON perm.id = rp.permission_id'),
      );
      expect(capabilities, isNot(contains('public.profiles')));
      expect(capabilities, isNot(contains('public.business_memberships')));
      expect(capabilities.toLowerCase(), isNot(contains('email')));
      expect(capabilities.toLowerCase(), isNot(contains('metadata')));
    });

    test('inactive, future-effective, and expired memberships fail closed', () {
      expect(capabilities, contains('sm.is_active'));
      expect(capabilities, contains('sm.effective_at <= now()'));
      expect(
        _squash(capabilities),
        contains('(sm.expires_at IS NULL OR sm.expires_at > now())'),
      );
    });

    test('capabilities are granular, deterministic, and duplicate-free', () {
      for (final permission in [
        'business_applications.read',
        'business_applications.review',
        'business_applications.return_for_correction',
        'business_applications.mark_contacted',
        'business_applications.schedule_visit',
        'business_applications.approve',
        'business_applications.reject',
        'business_applications.activate',
      ]) {
        expect(capabilities, contains("'$permission'"));
      }
      expect(capabilities, contains('SELECT DISTINCT perm.code'));
      expect(capabilities, contains('ORDER BY granted.code'));
      expect(capabilities, contains("'[]'::jsonb"));
      expect(capabilities, isNot(contains('isAdmin')));
      expect(capabilities, isNot(contains('is_admin')));
    });

    test('guest capability discovery fails with P0AUT', () {
      expect(capabilities, contains("ERRCODE = 'P0AUT'"));
    });
  });

  group('V1-R07 queue security and validation', () {
    test('queue requires auth.uid and read permission independently', () {
      expect(queue, contains('v_actor uuid := auth.uid()'));
      expect(queue, contains("ERRCODE = 'P0AUT'"));
      expect(
        _squash(queue),
        contains(
          "public.has_staff_application_permission( "
          "'business_applications.read')",
        ),
      );
      expect(queue, contains("ERRCODE = 'P0PER'"));
    });

    test('default statuses are exactly the frozen actionable set', () {
      final defaultClause = RegExp(
        r'p_status IS NULL AND ba\.status IN \(([^)]*)\)',
        multiLine: true,
      ).firstMatch(queue);
      expect(defaultClause, isNotNull);
      final values = RegExp("'([A-Z_]+)'")
          .allMatches(defaultClause!.group(1)!)
          .map((match) => match.group(1))
          .toList();
      expect(
        values,
        ['SUBMITTED', 'UNDER_REVIEW', 'CONTACTED', 'VISIT_SCHEDULED'],
      );
      expect(values, isNot(contains('APPROVED')));
    });

    test('only frozen explicit status filters are accepted', () {
      for (final status in [
        'SUBMITTED',
        'UNDER_REVIEW',
        'CONTACTED',
        'VISIT_SCHEDULED',
        'NEEDS_CORRECTION',
        'APPROVED',
        'REJECTED',
        'ACTIVATED',
      ]) {
        expect(queue, contains("'$status'"));
      }
      expect(queue, contains('invalid_application_status_filter'));
      expect(queue, contains("ERRCODE = 'P0DAT'"));
    });

    test('type filter accepts only canonical NEW and CLAIM', () {
      expect(
        _squash(queue),
        contains("p_application_type NOT IN ('NEW', 'CLAIM')"),
      );
      expect(queue, contains('invalid_application_type_filter'));
    });

    test('page size is bounded from 1 through 50', () {
      expect(
        _squash(queue),
        contains('p_limit IS NULL OR p_limit < 1 OR p_limit > 50'),
      );
      expect(queue, contains('LIMIT p_limit + 1'));
      expect(queue, contains('LIMIT p_limit'));
    });

    test('cursor must be absent or supplied as a complete pair', () {
      expect(
        _squash(queue),
        contains(
          '(p_cursor_created_at IS NULL) <> (p_cursor_id IS NULL)',
        ),
      );
      expect(queue, contains('invalid_queue_cursor'));
    });

    test('keyset pagination and ordering match the frozen contract', () {
      expect(
        _squash(queue),
        contains(
          '(ba.created_at, ba.id) > (p_cursor_created_at, p_cursor_id)',
        ),
      );
      expect(queue, contains('ORDER BY ba.created_at ASC, ba.id ASC'));
      expect(
        _squash(migration),
        contains(
          'ON public.business_applications (status, created_at, id)',
        ),
      );
    });

    test('queue response has bounded items and last-item next cursor', () {
      expect(queue, contains("'items'"));
      expect(queue, contains("'next_cursor'"));
      expect(queue, contains("'created_at', page.cursor_created_at"));
      expect(queue, contains("'id', page.cursor_id"));
      expect(queue, contains('(SELECT count(*) FROM fetched) > p_limit'));
      expect(queue, isNot(contains('OFFSET')));
    });

    test('queue projection omits applicant PII and raw application rows', () {
      expect(queue, isNot(contains('applicant_user_id')));
      expect(queue, isNot(contains('display_name')));
      expect(queue, isNot(contains('phone')));
      expect(queue, isNot(contains('photo_url')));
      expect(queue, isNot(contains('SELECT ba.*')));
      expect(queue, isNot(contains('audit_logs')));
      expect(queue, isNot(contains('application_notes')));
    });

    test('queue projects canonical CLAIM target identity', () {
      expect(queue, contains('LEFT JOIN public.directory_entities de'));
      expect(queue, contains("'claim_target'"));
      expect(queue, contains("'id', de.id"));
      expect(queue, contains("'name', de.name"));
      expect(queue, contains("'entity_type', de.entity_type"));
    });
  });

  group('V1-R07 detail boundary', () {
    test('detail independently requires auth and read permission', () {
      expect(detail, contains('v_actor uuid := auth.uid()'));
      expect(detail, contains("ERRCODE = 'P0AUT'"));
      expect(detail, contains("'business_applications.read'"));
      expect(detail, contains("ERRCODE = 'P0PER'"));
    });

    test('missing application or canonical target returns P0NOT', () {
      expect(detail, contains("'application_not_found'"));
      expect(detail, contains("'entity_not_found'"));
      expect(
        RegExp("ERRCODE = 'P0NOT'").allMatches(detail).length,
        2,
      );
    });

    test('applicant PII is restricted to display name and phone', () {
      expect(detail, contains('SELECT p.display_name, p.phone'));
      expect(detail, contains("'display_name', v_applicant_display_name"));
      expect(detail, contains("'phone', v_applicant_phone"));
      for (final forbidden in [
        'photo_url',
        'preferred_region_id',
        'role_code',
        "'email'",
      ]) {
        expect(detail, isNot(contains(forbidden)));
      }
      expect(detail, isNot(contains('SELECT p.*')));
    });

    test('NEW context is an explicit minimal projection', () {
      expect(detail, contains("v_row.application_type = 'NEW'"));
      expect(detail, contains("'name', v_row.metadata ->> 'name'"));
      expect(
        detail,
        contains("'entity_type', v_row.metadata ->> 'entity_type'"),
      );
      expect(detail, isNot(contains("'metadata', v_row.metadata")));
    });

    test('CLAIM context uses canonical directory entity id', () {
      expect(detail, contains("v_row.application_type = 'CLAIM'"));
      expect(detail, contains("'id', v_target.id"));
      expect(detail, contains("'target_entity_id', v_row.target_entity_id"));
    });

    test('contact and visit histories are scoped and bounded', () {
      expect(detail, contains('FROM public.application_contacts history'));
      expect(detail, contains('FROM public.application_visits history'));
      expect(
        RegExp(r'LIMIT 50').allMatches(detail).length,
        2,
      );
      expect(detail, contains('history.application_id = v_row.id'));
    });

    test('detail excludes generic notes and audit logs', () {
      expect(detail, isNot(contains('application_notes')));
      expect(detail, isNot(contains('audit_logs')));
      expect(detail, isNot(contains('before_data')));
      expect(detail, isNot(contains('after_data')));
    });
  });

  group('V1-R07 migration and existing mutation protection', () {
    test('new RPCs use secure definer and fixed search path', () {
      for (final body in [capabilities, queue, detail]) {
        expect(body, contains('SECURITY DEFINER'));
        expect(body, contains('SET search_path = public, pg_temp'));
      }
    });

    test('client execute privileges are explicitly narrow', () {
      for (final name in [
        'get_staff_application_capabilities',
        'list_staff_business_applications',
        'get_staff_business_application_detail',
      ]) {
        final suffix = migration.substring(
          migration.indexOf('-- 5. Client execute lockdown'),
        );
        expect(suffix, contains('public.$name'));
      }
      expect(
        RegExp(r'FROM PUBLIC, anon;').allMatches(migration).length,
        3,
      );
      expect(
        RegExp(r'TO authenticated;').allMatches(migration).length,
        3,
      );
    });

    test('migration introduces no direct table grant or schema redesign', () {
      expect(migration, isNot(contains('GRANT SELECT')));
      expect(migration, isNot(contains('GRANT UPDATE')));
      expect(migration, isNot(contains('GRANT INSERT')));
      expect(migration, isNot(contains('CREATE TABLE')));
      expect(migration, isNot(contains('ALTER TABLE')));
      expect(migration.toLowerCase(), isNot(contains('service_role')));
    });

    test('migration does not replace any existing staff mutation', () {
      for (final name in [
        'staff_begin_application_review',
        'staff_return_application_for_correction',
        'staff_mark_application_contacted',
        'staff_schedule_application_visit',
        'staff_approve_business_application',
        'staff_reject_business_application',
        'staff_activate_business_application',
      ]) {
        expect(
          migration,
          isNot(contains('CREATE OR REPLACE FUNCTION public.$name')),
        );
      }
    });

    test('existing mutation authority, locks, and audits remain canonical', () {
      final mutations = File(_staffMutationsPath).readAsStringSync();
      final activation = File(_activationPath).readAsStringSync();
      expect(mutations, contains('FOR UPDATE'));
      expect(mutations, contains('public.has_staff_application_permission'));
      expect(mutations, contains('public.append_audit_log'));
      expect(activation, contains('FOR UPDATE'));
      expect(activation, contains('public.has_staff_application_permission'));
      expect(activation, contains('public.append_audit_log'));
    });
  });
}
