import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationPath =
    'supabase/migrations/00020_business_profile_management.sql';

String _functionBody(String sql, String functionName, {String? nextMarker}) {
  final start = sql.indexOf('CREATE OR REPLACE FUNCTION public.$functionName');
  expect(start, greaterThanOrEqualTo(0), reason: '$functionName is missing');
  final end = nextMarker == null
      ? sql.length
      : sql.indexOf(nextMarker, start + functionName.length);
  expect(end, greaterThan(start), reason: '$functionName boundary is missing');
  return sql.substring(start, end);
}

void main() {
  late String migration;
  late String readRpc;
  late String updateRpc;

  setUpAll(() {
    migration = File(_migrationPath).readAsStringSync();
    readRpc = _functionBody(
      migration,
      'get_managed_business_profile',
      nextMarker:
          'CREATE OR REPLACE FUNCTION public.update_managed_business_profile',
    );
    updateRpc = _functionBody(migration, 'update_managed_business_profile');
  });

  group('V1-R06 Part 1 contract and authorization', () {
    test('contract is frozen and roadmap records V1-R06 as closed', () {
      final contract = File(
        'docs/architecture/contracts/'
        'V1-R06_BUSINESS_PROVIDER_PROFILE_MANAGEMENT_CONTRACT.md',
      ).readAsStringSync();
      final roadmap = File(
        'docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md',
      ).readAsStringSync();
      expect(contract, matches(RegExp(r'CONTRACT_ID:\s*V1-R06-CONTRACT-v1')));
      expect(
        roadmap,
        contains(
          '| V1-R06 | Business / Provider Profile Management | CLOSED |',
        ),
      );
      expect(roadmap, contains('CURRENT_PHASE_ID: V1-R07'));
      expect(roadmap, contains('CURRENT_PHASE_CONTRACT: V1-R07-CONTRACT-v1'));
      expect(roadmap, contains('IMPLEMENTATION_AUTHORIZED: YES'));
      expect(
        roadmap,
        contains('| V1-R07 | Staff / Admin Operations Foundation | CURRENT |'),
      );
    });

    test('both client RPCs are SECURITY DEFINER with a safe search path', () {
      for (final rpc in [readRpc, updateRpc]) {
        expect(rpc, contains('SECURITY DEFINER'));
        expect(rpc, contains('SET search_path = public, pg_temp'));
        expect(rpc, contains('v_actor uuid := auth.uid()'));
        expect(rpc, contains("ERRCODE = 'P0AUT'"));
        expect(rpc, contains('has_business_management_access(p_entity_id)'));
        expect(rpc, contains("ERRCODE = 'P0PER'"));
      }
    });

    test('execution is authenticated-only and internal helper remains private', () {
      expect(
        migration,
        contains(
          'REVOKE EXECUTE ON FUNCTION public.get_managed_business_profile(uuid)\n'
          '  FROM PUBLIC, anon, authenticated;',
        ),
      );
      expect(
        migration,
        contains(
          'GRANT EXECUTE ON FUNCTION public.get_managed_business_profile(uuid)\n'
          '  TO authenticated;',
        ),
      );
      expect(
        migration,
        contains(
          'REVOKE EXECUTE ON FUNCTION public.managed_business_profile_projection(uuid)\n'
          '  FROM PUBLIC, anon, authenticated;',
        ),
      );
      expect(migration, isNot(contains('TO anon;')));
    });

    test('no direct Directory table writes are granted', () {
      expect(migration, isNot(contains('GRANT INSERT')));
      expect(migration, isNot(contains('GRANT UPDATE')));
      expect(migration, isNot(contains('GRANT DELETE')));
      expect(migration, isNot(contains('service_role')));
      expect(migration, isNot(contains('CREATE TABLE')));
    });
  });

  group('V1-R06 management read projection', () {
    test('returns the frozen entity and editable child projection', () {
      for (final field in [
        "'id', de.id",
        "'entity_type', de.entity_type",
        "'name', de.name",
        "'description', de.description",
        "'lifecycle_status', de.lifecycle_status",
        "'verification_status', de.verification_status",
        "'claim_status', de.claim_status",
        "'created_at', de.created_at",
        "'updated_at', de.updated_at",
        "'contacts'",
        "'primary_location'",
        "'categories'",
      ]) {
        expect(migration, contains(field));
      }
      expect(migration, contains('AND el.is_primary'));
      expect(migration, contains("COALESCE((\n      SELECT jsonb_agg"));
    });

    test('read is not restricted to active public-directory rows', () {
      expect(readRpc, isNot(contains("lifecycle_status = 'active'")));
      expect(readRpc, isNot(contains('directory_entities_select_active')));
    });
  });

  group('V1-R06 atomic mutation contract', () {
    test('signature exposes only frozen editable inputs', () {
      final signatureEnd = updateRpc.indexOf('RETURNS jsonb');
      final signature = updateRpc.substring(0, signatureEnd);
      for (final allowed in [
        'p_entity_id uuid',
        'p_expected_updated_at timestamptz',
        'p_name text',
        'p_description text',
        'p_contacts jsonb',
        'p_primary_location jsonb',
        'p_categories jsonb',
      ]) {
        expect(signature, contains(allowed));
      }
      for (final forbidden in [
        'entity_type',
        'claim_status',
        'lifecycle_status',
        'verification_status',
        'user_id',
        'owner',
      ]) {
        expect(signature, isNot(contains(forbidden)));
      }
    });

    test('locks and rejects stale expected_updated_at with P0CON', () {
      expect(updateRpc, contains('FOR UPDATE'));
      expect(
        updateRpc,
        contains('v_entity.updated_at IS DISTINCT FROM p_expected_updated_at'),
      );
      expect(updateRpc, contains("ERRCODE = 'P0CON'"));
      expect(updateRpc, contains('updated_at = clock_timestamp()'));
    });

    test('name and description bounds are server enforced', () {
      expect(updateRpc, contains('char_length(v_name) > 160'));
      expect(updateRpc, contains('char_length(v_description) > 2000'));
    });

    test('contacts are bounded, allow-listed, deduplicated and replaced', () {
      expect(updateRpc, contains('jsonb_array_length(v_contacts) > 10'));
      expect(
        updateRpc,
        contains("'phone', 'whatsapp', 'email', 'website', 'other'"),
      );
      expect(
        updateRpc,
        contains("key_name NOT IN ('contact_type', 'value', 'is_primary')"),
      );
      expect(updateRpc, contains('duplicate_contact'));
      expect(updateRpc, contains('duplicate_primary_contact_type'));
      expect(updateRpc, contains('DELETE FROM public.entity_contacts'));
      expect(updateRpc, contains('INSERT INTO public.entity_contacts'));
    });

    test(
      'primary location validates active region and preserves other rows',
      () {
        expect(
          updateRpc,
          contains(
            "key_name NOT IN ('region_id', 'address', 'latitude', 'longitude')",
          ),
        );
        expect(updateRpc, contains('char_length(v_address) > 500'));
        expect(updateRpc, contains('v_latitude < -90 OR v_latitude > 90'));
        expect(updateRpc, contains('v_longitude < -180 OR v_longitude > 180'));
        expect(updateRpc, contains('AND r.is_active'));
        expect(updateRpc, contains('WHERE el.id = v_old_primary.id'));
        expect(
          updateRpc,
          isNot(
            contains(
              'DELETE FROM public.entity_locations el WHERE el.entity_id',
            ),
          ),
        );
      },
    );

    test('categories are bounded, active, unique and replace-all', () {
      expect(updateRpc, contains('jsonb_array_length(v_categories) > 10'));
      expect(
        updateRpc,
        contains("key_name NOT IN ('category_id', 'is_primary')"),
      );
      expect(updateRpc, contains('duplicate_category'));
      expect(updateRpc, contains('multiple_primary_categories'));
      expect(updateRpc, contains('AND dc.is_active'));
      expect(
        updateRpc,
        contains('DELETE FROM public.directory_entity_categories'),
      );
      expect(
        updateRpc,
        contains('INSERT INTO public.directory_entity_categories'),
      );
    });

    test('verified transitions to pending only for name/location change', () {
      expect(updateRpc, contains('v_entity.name IS DISTINCT FROM v_name'));
      expect(
        updateRpc,
        contains('v_old_primary.region_id IS DISTINCT FROM v_region_id'),
      );
      expect(
        updateRpc,
        contains('v_old_primary.address IS DISTINCT FROM v_address'),
      );
      expect(
        updateRpc,
        contains('v_old_primary.latitude IS DISTINCT FROM v_latitude'),
      );
      expect(
        updateRpc,
        contains('v_old_primary.longitude IS DISTINCT FROM v_longitude'),
      );
      expect(
        updateRpc,
        contains(
          "WHEN de.verification_status = 'verified' AND v_sensitive_changed",
        ),
      );
      expect(updateRpc, contains("THEN 'pending'"));
      expect(updateRpc, contains('ELSE de.verification_status'));
    });

    test('one bounded audit call occurs after all mutations', () {
      expect(RegExp('append_audit_log').allMatches(updateRpc), hasLength(1));
      expect(updateRpc, contains("'business_profile.update'"));
      expect(
        updateRpc.indexOf('PERFORM public.append_audit_log'),
        greaterThan(
          updateRpc.indexOf('INSERT INTO public.directory_entity_categories'),
        ),
      );
    });
  });

  group('V1-R06 public primary-location compatibility', () {
    test('public projection carries is_primary and parser orders it first', () {
      final gateway = File(
        'lib/features/directory/data/supabase_directory_read_gateway.dart',
      ).readAsStringSync();
      final model = File(
        'lib/features/directory/domain/canonical_directory_entity.dart',
      ).readAsStringSync();
      expect(
        gateway,
        contains('regions(id, code, name_ar, name_en), is_primary'),
      );
      expect(gateway, contains("final isPrimary = item['is_primary'] == true"));
      expect(
        gateway,
        contains('...result.where((location) => location.isPrimary)'),
      );
      expect(model, contains('final bool isPrimary;'));
      expect(model, contains("'is_primary': isPrimary"));
    });
  });
}
