import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationPath =
    'supabase/migrations/00017_business_application_creation_authorization_hardening.sql';
const _gatewayPath =
    'lib/features/business/data/supabase_business_application_gateway.dart';

String _between(String source, String start, String end) {
  final startIndex = source.indexOf(start);
  expect(startIndex, greaterThanOrEqualTo(0), reason: 'missing $start');
  final endIndex = source.indexOf(end, startIndex + start.length);
  expect(endIndex, greaterThan(startIndex), reason: 'missing $end after $start');
  return source.substring(startIndex, endIndex);
}

void main() {
  late String sql;
  late String gateway;

  setUpAll(() {
    sql = File(_migrationPath).readAsStringSync();
    gateway = File(_gatewayPath).readAsStringSync();
  });

  group('A6.3.1 privilege boundary', () {
    test('generic authenticated INSERT and its RLS policy are retired', () {
      expect(
        sql,
        contains(
          'REVOKE INSERT ON public.business_applications FROM authenticated;',
        ),
      );
      expect(
        sql,
        contains(
          'DROP POLICY "business_applications_insert_own"\n'
          '  ON public.business_applications;',
        ),
      );
    });

    test('creation functions are executable by authenticated only', () {
      for (final signature in [
        'public.create_new_business_application(jsonb)',
        'public.create_claim_business_application(uuid)',
      ]) {
        expect(sql, contains('REVOKE EXECUTE ON FUNCTION $signature'));
        expect(sql, contains('GRANT EXECUTE ON FUNCTION $signature'));
      }
      expect(sql, contains('FROM PUBLIC, anon;'));
      expect(sql, contains('TO authenticated;'));
    });

    test('the existing CLAIM trigger helper has no client EXECUTE grant', () {
      expect(
        sql,
        contains(
          'REVOKE EXECUTE ON FUNCTION public.guard_claim_application_insert()',
        ),
      );
      expect(sql, contains('FROM PUBLIC, anon, authenticated;'));
    });
  });

  group('A6.3.1 RPC contract', () {
    test('both RPCs derive identity from auth.uid and force DRAFT', () {
      final newFunction = _between(
        sql,
        'CREATE OR REPLACE FUNCTION public.create_new_business_application(',
        'COMMENT ON FUNCTION public.create_new_business_application',
      );
      final claimFunction = _between(
        sql,
        'CREATE OR REPLACE FUNCTION public.create_claim_business_application(',
        'COMMENT ON FUNCTION public.create_claim_business_application',
      );

      for (final function in [newFunction, claimFunction]) {
        expect(function, contains('v_actor uuid := auth.uid();'));
        expect(function, contains("'DRAFT'"));
        expect(function, contains("RAISE EXCEPTION 'unauthenticated'"));
        expect(function, contains('SECURITY DEFINER'));
        expect(function, contains('SET search_path = public, pg_temp'));
      }
    });

    test('RPC signatures expose only legitimate creation data', () {
      final newSignature = _between(
        sql,
        'CREATE OR REPLACE FUNCTION public.create_new_business_application(',
        ')\nRETURNS public.business_applications',
      );
      final claimSignature = _between(
        sql,
        'CREATE OR REPLACE FUNCTION public.create_claim_business_application(',
        ')\nRETURNS public.business_applications',
      );

      expect(newSignature, contains('p_metadata jsonb DEFAULT NULL'));
      expect(claimSignature, contains('p_target_entity_id uuid'));

      for (final signature in [newSignature, claimSignature]) {
        for (final forbidden in [
          'applicant_user_id',
          'status',
          'reviewed_by_user_id',
          'reviewed_at',
          'return_reason',
          'rejection_reason',
          'approved_at',
          'activated_at',
        ]) {
          expect(signature, isNot(contains(forbidden)));
        }
      }
    });

    test('NEW and CLAIM inserts keep lifecycle-owned columns server-clean', () {
      final newFunction = _between(
        sql,
        'CREATE OR REPLACE FUNCTION public.create_new_business_application(',
        'COMMENT ON FUNCTION public.create_new_business_application',
      );
      final claimFunction = _between(
        sql,
        'CREATE OR REPLACE FUNCTION public.create_claim_business_application(',
        'COMMENT ON FUNCTION public.create_claim_business_application',
      );

      expect(newFunction, contains("v_actor,\n    'NEW',\n    NULL,\n    'DRAFT',"));
      expect(claimFunction,
          contains("v_actor,\n    'CLAIM',\n    p_target_entity_id,\n    'DRAFT',\n    NULL"));
      for (final function in [newFunction, claimFunction]) {
        for (final staffColumn in [
          'reviewed_by_user_id',
          'reviewed_at',
          'return_reason',
          'rejection_reason',
          'approved_at',
          'activated_at',
        ]) {
          expect(function, isNot(contains(staffColumn)));
        }
      }
    });

    test('CLAIM keeps the 00014/00015 trigger as the single lock guard', () {
      final migration14 = File(
        'supabase/migrations/00014_business_application_claim_hardening.sql',
      ).readAsStringSync();
      final migration15 = File(
        'supabase/migrations/00015_business_application_claim_concurrency_hardening.sql',
      ).readAsStringSync();
      final claimFunction = _between(
        sql,
        'CREATE OR REPLACE FUNCTION public.create_claim_business_application(',
        'COMMENT ON FUNCTION public.create_claim_business_application',
      );

      expect(migration14, contains('uq_business_applications_live_claim'));
      expect(migration14, contains('trigger_guard_claim_insert'));
      expect(migration15, contains('FOR UPDATE;'));
      expect(claimFunction, isNot(contains('FOR UPDATE')),
          reason: 'claim locking must not be duplicated outside the trigger');
      expect(claimFunction, isNot(contains('claim_status')),
          reason: 'claimability must remain centralized in the trigger');
    });
  });

  group('A6.3.1 Flutter gateway', () {
    test('creation uses RPCs and exposes no generic table insert', () {
      expect(gateway, isNot(contains('.insert(')));
      expect(gateway, contains(".rpc(\n        'create_new_business_application'"));
      expect(gateway, contains(".rpc(\n        'create_claim_business_application'"));
    });

    test('creation RPC parameters contain no applicant or lifecycle fields', () {
      final newMethod = _between(
        gateway,
        'Future<BusinessApplicationCreateResult> createNewDraft(',
        'Future<BusinessApplicationCreateResult> createClaimDraft(',
      );
      final claimMethod = _between(
        gateway,
        'Future<BusinessApplicationCreateResult> createClaimDraft(',
        'Future<BusinessApplicationSubmitResult> submitApplication(',
      );

      expect(newMethod, contains("'p_metadata'"));
      expect(claimMethod, contains("'p_target_entity_id'"));
      for (final method in [newMethod, claimMethod]) {
        expect(method, isNot(contains("'applicant_user_id'")));
        expect(method, isNot(contains("'status'")));
        expect(method, isNot(contains("'reviewed_by_user_id'")));
        expect(method, isNot(contains("'approved_at'")));
        expect(method, isNot(contains("'activated_at'")));
      }
    });
  });
}
