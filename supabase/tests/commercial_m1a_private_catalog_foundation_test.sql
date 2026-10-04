-- M1a: disposable-local PostgreSQL evidence, independent of source assertions.
-- Run as the migration creator verified through the actual local CLI runner.
-- Fixture/probe objects and all row changes disappear with the final rollback.
BEGIN;

SELECT no_plan();

SELECT is(current_setting('server_version_num')::integer / 10000, 17,
  'runtime server is PostgreSQL 17');
SELECT is(session_user::text, 'postgres', 'verified local migration login');
SELECT is(current_user::text, 'postgres', 'verified local object creator');

-- Phase authority is migration history, never arbitrary row presence.
CREATE TEMP TABLE m1a_phase AS
SELECT EXISTS (SELECT 1 FROM supabase_migrations.schema_migrations
  WHERE version = '00023') AS harden1_applied,
  EXISTS (SELECT 1 FROM supabase_migrations.schema_migrations
  WHERE version = '00024') AS m1b_applied;
SELECT is((SELECT name FROM supabase_migrations.schema_migrations
  WHERE version = '00022'), 'commercial_private_catalog_foundation',
  'verified M1a migration-history identity');
SELECT is((SELECT name FROM supabase_migrations.schema_migrations
  WHERE version = '00023'),
  CASE WHEN harden1_applied THEN 'commercial_public_plans_exposure_hardening' END,
  'verified HARDEN-1 migration-history identity') FROM m1a_phase;
SELECT is((SELECT name FROM supabase_migrations.schema_migrations
  WHERE version = '00024'),
  CASE WHEN m1b_applied THEN 'commercial_catalog_reference_data' END,
  'verified M1b migration-history identity') FROM m1a_phase;
SELECT ok(NOT m1b_applied OR harden1_applied,
  'M1b phase requires the recorded HARDEN-1 predecessor') FROM m1a_phase;

-- Independent expected values from frozen M1b §§7–15, including every UUID,
-- relationship, typed value, timestamp and NULL. Never read migration source.
CREATE TEMP TABLE m1a_catalog_expected (
  relation_name text PRIMARY KEY, expected_rows jsonb NOT NULL
);
INSERT INTO m1a_catalog_expected
SELECT 'commercial_private.entitlement_bundles', jsonb_agg(jsonb_build_object(
  'id', id, 'code', code, 'version', 1, 'registry_version', 1,
  'status', 'draft', 'published_at', NULL, 'retired_at', NULL, 'created_at', TIMESTAMPTZ '2026-01-01 00:00:00+00') ORDER BY id)
FROM (VALUES
  ('2e7b0001-0000-4000-8000-000000000001', 'business_entitlements'),
  ('2e7b0002-0000-4000-8000-000000000002', 'business_pro_entitlements'),
  ('2e7b0003-0000-4000-8000-000000000003', 'business_plus_entitlements'),
  ('2e7b0004-0000-4000-8000-000000000004', 'corporate_entitlements')) e(id, code);
INSERT INTO m1a_catalog_expected
SELECT 'commercial_private.bundle_items', jsonb_agg(jsonb_build_object(
  'id', id, 'bundle_version_id', bundle_id, 'capability_key', capability_key,
  'value_kind', value_kind, 'value_boolean', value_boolean,
  'value_integer', value_integer, 'value_text', NULL, 'is_required', true,
  'created_at', TIMESTAMPTZ '2026-01-01 00:00:00+00') ORDER BY id)
FROM (VALUES
  ('3a7b0001-0000-4000-8000-000000000001', '2e7b0001-0000-4000-8000-000000000001', 'branches.included', 'integer', NULL::boolean, 1),
  ('3a7b0002-0000-4000-8000-000000000002', '2e7b0001-0000-4000-8000-000000000001', 'team.active_member_max', 'integer', NULL, 5),
  ('3a7b0003-0000-4000-8000-000000000003', '2e7b0001-0000-4000-8000-000000000001', 'media.upload_enabled', 'boolean', true, NULL),
  ('3a7b0004-0000-4000-8000-000000000004', '2e7b0001-0000-4000-8000-000000000001', 'analytics.available', 'boolean', true, NULL),
  ('3a7b0005-0000-4000-8000-000000000005', '2e7b0001-0000-4000-8000-000000000001', 'sponsored.purchase_eligible', 'boolean', false, NULL),
  ('3a7b0006-0000-4000-8000-000000000001', '2e7b0002-0000-4000-8000-000000000002', 'branches.included', 'integer', NULL, 2),
  ('3a7b0007-0000-4000-8000-000000000001', '2e7b0002-0000-4000-8000-000000000002', 'team.active_member_max', 'integer', NULL, 5),
  ('3a7b0008-0000-4000-8000-000000000001', '2e7b0002-0000-4000-8000-000000000002', 'media.upload_enabled', 'boolean', true, NULL),
  ('3a7b0009-0000-4000-8000-000000000001', '2e7b0002-0000-4000-8000-000000000002', 'analytics.available', 'boolean', true, NULL),
  ('3a7b0010-0000-4000-8000-000000000001', '2e7b0002-0000-4000-8000-000000000002', 'sponsored.purchase_eligible', 'boolean', true, NULL),
  ('3a7b0011-0000-4000-8000-000000000001', '2e7b0003-0000-4000-8000-000000000003', 'branches.included', 'integer', NULL, 3),
  ('3a7b0012-0000-4000-8000-000000000001', '2e7b0003-0000-4000-8000-000000000003', 'team.active_member_max', 'integer', NULL, 5),
  ('3a7b0013-0000-4000-8000-000000000001', '2e7b0003-0000-4000-8000-000000000003', 'media.upload_enabled', 'boolean', true, NULL),
  ('3a7b0014-0000-4000-8000-000000000001', '2e7b0003-0000-4000-8000-000000000003', 'analytics.available', 'boolean', true, NULL),
  ('3a7b0015-0000-4000-8000-000000000001', '2e7b0003-0000-4000-8000-000000000003', 'sponsored.purchase_eligible', 'boolean', true, NULL),
  ('3a7b0016-0000-4000-8000-000000000001', '2e7b0004-0000-4000-8000-000000000004', 'branches.included', 'integer', NULL, 3),
  ('3a7b0017-0000-4000-8000-000000000001', '2e7b0004-0000-4000-8000-000000000004', 'team.active_member_max', 'integer', NULL, 5),
  ('3a7b0018-0000-4000-8000-000000000001', '2e7b0004-0000-4000-8000-000000000004', 'media.upload_enabled', 'boolean', true, NULL),
  ('3a7b0019-0000-4000-8000-000000000001', '2e7b0004-0000-4000-8000-000000000004', 'analytics.available', 'boolean', true, NULL)) e(id, bundle_id, capability_key, value_kind, value_boolean, value_integer);
INSERT INTO m1a_catalog_expected
SELECT 'commercial_private.plan_versions', jsonb_agg(jsonb_build_object(
  'id', id, 'plan_id', plan_id, 'version', 1, 'bundle_version_id', bundle_id,
  'pricing_mode', pricing_mode, 'name_ar', '__AR_LOCALIZATION_PENDING__',
  'description_ar', NULL, 'sort_order', sort_order, 'status', 'draft', 'published_at', NULL, 'retired_at', NULL,
  'effective_from', NULL, 'effective_until', NULL, 'created_at', TIMESTAMPTZ '2026-01-01 00:00:00+00') ORDER BY id)
FROM (VALUES
  ('4c7b0001-0000-4000-8000-000000000001', '1a7b0001-0000-4000-8000-000000000001', '2e7b0001-0000-4000-8000-000000000001', 'retail', 1),
  ('4c7b0002-0000-4000-8000-000000000002', '1a7b0002-0000-4000-8000-000000000002', '2e7b0002-0000-4000-8000-000000000002', 'retail', 2),
  ('4c7b0003-0000-4000-8000-000000000003', '1a7b0003-0000-4000-8000-000000000003', '2e7b0003-0000-4000-8000-000000000003', 'retail', 3),
  ('4c7b0004-0000-4000-8000-000000000004', '1a7b0004-0000-4000-8000-000000000004', '2e7b0004-0000-4000-8000-000000000004', 'custom_quote', 4)) e(id, plan_id, bundle_id, pricing_mode, sort_order);
INSERT INTO m1a_catalog_expected
SELECT 'commercial_private.term_prices', jsonb_agg(jsonb_build_object(
  'id', id, 'plan_version_id', plan_version_id, 'pricing_mode', 'retail',
  'version', 1, 'duration_months', duration_months, 'amount_iqd', amount_iqd,
  'currency', 'IQD', 'status', 'draft', 'published_at', NULL, 'retired_at', NULL, 'effective_from', NULL, 'effective_until', NULL,
  'created_at', TIMESTAMPTZ '2026-01-01 00:00:00+00') ORDER BY id)
FROM (VALUES
  ('5d7b0001-0000-4000-8000-000000000001', '4c7b0001-0000-4000-8000-000000000001', 1, 20000),
  ('5d7b0002-0000-4000-8000-000000000002', '4c7b0001-0000-4000-8000-000000000001', 3, 55000),
  ('5d7b0003-0000-4000-8000-000000000003', '4c7b0001-0000-4000-8000-000000000001', 12, 200000),
  ('5d7b0004-0000-4000-8000-000000000004', '4c7b0002-0000-4000-8000-000000000002', 1, 40000),
  ('5d7b0005-0000-4000-8000-000000000005', '4c7b0002-0000-4000-8000-000000000002', 3, 110000),
  ('5d7b0006-0000-4000-8000-000000000006', '4c7b0002-0000-4000-8000-000000000002', 12, 400000),
  ('5d7b0007-0000-4000-8000-000000000007', '4c7b0003-0000-4000-8000-000000000003', 1, 70000),
  ('5d7b0008-0000-4000-8000-000000000008', '4c7b0003-0000-4000-8000-000000000003', 3, 190000),
  ('5d7b0009-0000-4000-8000-000000000009', '4c7b0003-0000-4000-8000-000000000003', 12, 700000)) e(id, plan_version_id, duration_months, amount_iqd);

CREATE FUNCTION pg_temp.m1a_catalog_rows(p_relation regclass)
RETURNS jsonb LANGUAGE plpgsql SECURITY INVOKER
SET search_path = pg_catalog, pg_temp AS $body$
DECLARE rows jsonb;
BEGIN
  EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY id),
    ''[]''::jsonb) FROM %s t', p_relation) INTO rows;
  RETURN rows;
END;
$body$;

-- Capture before any catalog fixture/probe; validate the accepted phase below.
CREATE TEMP TABLE m1a_catalog_snapshot AS
SELECT relation_name, row_data, jsonb_array_length(row_data) AS row_count
FROM (SELECT relation_name,
  pg_temp.m1a_catalog_rows(relation_name::regclass) AS row_data
  FROM m1a_catalog_expected) baseline;

CREATE FUNCTION pg_temp.m1a_private_security()
RETURNS jsonb LANGUAGE sql SECURITY INVOKER
SET search_path = pg_catalog, pg_temp AS $body$
SELECT jsonb_build_object(
  'schema', (SELECT jsonb_build_array(nspowner, nspacl)
    FROM pg_namespace WHERE nspname = 'commercial_private'),
  'relations', (SELECT jsonb_agg(jsonb_build_array(c.oid, c.relowner,
    c.relacl, c.relrowsecurity, c.relforcerowsecurity) ORDER BY c.oid)
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'commercial_private'),
  'columns', (SELECT jsonb_agg(jsonb_build_array(a.attrelid, a.attnum,
    a.attacl) ORDER BY a.attrelid, a.attnum)
    FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'commercial_private' AND a.attnum > 0
      AND NOT a.attisdropped),
  'policies', (SELECT jsonb_agg(to_jsonb(p) ORDER BY p.oid)
    FROM pg_policy p JOIN pg_class c ON c.oid = p.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'commercial_private'));
$body$;
CREATE TEMP TABLE m1a_private_security_snapshot AS
SELECT pg_temp.m1a_private_security() AS fingerprint;

CREATE TEMP TABLE m1a_public_snapshot AS
SELECT
  (SELECT md5(coalesce(string_agg(row_to_json(p)::text, E'\n' ORDER BY id), ''))
    FROM public.plans p) AS plans_data,
  (SELECT md5(coalesce(string_agg(row_to_json(s)::text, E'\n' ORDER BY id), ''))
    FROM public.subscriptions s) AS subscriptions_data,
  (SELECT md5(coalesce(string_agg(row_to_json(e)::text, E'\n' ORDER BY id), ''))
    FROM public.directory_entities e) AS directory_data,
  (SELECT md5(coalesce(string_agg(row_to_json(m)::text, E'\n'
    ORDER BY user_id, entity_id), ''))
    FROM public.business_memberships m) AS membership_data,
  (SELECT md5(coalesce(string_agg(
    c.oid::text || ':' || coalesce(c.relacl::text, '<implicit>'), E'\n'
    ORDER BY c.oid), ''))
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public') AS public_table_acls,
  (SELECT md5(coalesce(string_agg(
    p.oid::text || ':' || coalesce(p.proacl::text, '<implicit>') || ':' ||
    pg_get_functiondef(p.oid), E'\n' ORDER BY p.oid), ''))
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.prokind IN ('f', 'p', 'w')) AS public_rpcs,
  (SELECT md5(coalesce(string_agg(
    d.defaclrole::text || ':' || d.defaclnamespace::text || ':' ||
    d.defaclobjtype::text || ':' || d.defaclacl::text, E'\n'
    ORDER BY d.defaclrole, d.defaclnamespace, d.defaclobjtype), ''))
    FROM pg_default_acl d) AS default_acls;

-- Temporary assertion helpers preserve owner execution of pgTAP itself.
-- A nested exception rolls back each attempted operation, even if it succeeds.
-- Role/JWT denial therefore never requires client EXECUTE on pgTAP routines.
CREATE FUNCTION pg_temp.m1a_result(
  p_sql text, p_role name DEFAULT NULL, p_subject text DEFAULT NULL
)
RETURNS text LANGUAGE plpgsql SECURITY INVOKER
SET search_path = pg_catalog, pg_temp AS $body$
DECLARE
  state text;
  constraint_name text;
  message text;
BEGIN
  BEGIN
    IF p_subject IS NOT NULL THEN
      PERFORM set_config('request.jwt.claim.sub', p_subject, true);
    END IF;
    IF p_role IS NOT NULL THEN
      EXECUTE format('SET LOCAL ROLE %I', p_role);
    END IF;
    EXECUTE p_sql;
    RAISE EXCEPTION 'm1a_assertion_success_rollback' USING ERRCODE = 'P0T00';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS state = RETURNED_SQLSTATE,
      constraint_name = CONSTRAINT_NAME, message = MESSAGE_TEXT;
    IF state = 'P0T00' AND message = 'm1a_assertion_success_rollback' THEN
      RETURN 'NO_ERROR';
    END IF;
    RETURN state || '|' || coalesce(constraint_name, '');
  END;
END;
$body$;

CREATE FUNCTION pg_temp.m1a_read(p_sql text, p_role name)
RETURNS text LANGUAGE plpgsql SECURITY INVOKER
SET search_path = pg_catalog, pg_temp AS $body$
DECLARE value text;
BEGIN
  EXECUTE format('SET LOCAL ROLE %I', p_role);
  EXECUTE p_sql INTO value;
  RESET ROLE;
  RETURN value;
EXCEPTION WHEN OTHERS THEN
  RESET ROLE;
  RAISE;
END;
$body$;

CREATE TEMP TABLE m1a_expected_columns (
  table_name text, column_name text, type_name text, required boolean,
  default_expression text, PRIMARY KEY (table_name, column_name)
);
INSERT INTO m1a_expected_columns VALUES
  ('entitlement_bundles', 'id', 'uuid', true, 'gen_random_uuid()'),
  ('entitlement_bundles', 'code', 'text', true, NULL),
  ('entitlement_bundles', 'version', 'integer', true, NULL),
  ('entitlement_bundles', 'registry_version', 'integer', true, NULL),
  ('entitlement_bundles', 'status', 'text', true, '''draft''::text'),
  ('entitlement_bundles', 'published_at', 'timestamp with time zone', false, NULL),
  ('entitlement_bundles', 'retired_at', 'timestamp with time zone', false, NULL),
  ('entitlement_bundles', 'created_at', 'timestamp with time zone', true, 'now()'),
  ('bundle_items', 'id', 'uuid', true, 'gen_random_uuid()'),
  ('bundle_items', 'bundle_version_id', 'uuid', true, NULL),
  ('bundle_items', 'capability_key', 'text', true, NULL),
  ('bundle_items', 'value_kind', 'text', true, NULL),
  ('bundle_items', 'value_boolean', 'boolean', false, NULL),
  ('bundle_items', 'value_integer', 'bigint', false, NULL),
  ('bundle_items', 'value_text', 'text', false, NULL),
  ('bundle_items', 'is_required', 'boolean', true, 'true'),
  ('bundle_items', 'created_at', 'timestamp with time zone', true, 'now()'),
  ('plan_versions', 'id', 'uuid', true, 'gen_random_uuid()'),
  ('plan_versions', 'plan_id', 'uuid', true, NULL),
  ('plan_versions', 'version', 'integer', true, NULL),
  ('plan_versions', 'bundle_version_id', 'uuid', true, NULL),
  ('plan_versions', 'pricing_mode', 'text', true, NULL),
  ('plan_versions', 'name_ar', 'text', true, NULL),
  ('plan_versions', 'description_ar', 'text', false, NULL),
  ('plan_versions', 'sort_order', 'integer', true, '0'),
  ('plan_versions', 'status', 'text', true, '''draft''::text'),
  ('plan_versions', 'published_at', 'timestamp with time zone', false, NULL),
  ('plan_versions', 'retired_at', 'timestamp with time zone', false, NULL),
  ('plan_versions', 'effective_from', 'timestamp with time zone', false, NULL),
  ('plan_versions', 'effective_until', 'timestamp with time zone', false, NULL),
  ('plan_versions', 'created_at', 'timestamp with time zone', true, 'now()'),
  ('term_prices', 'id', 'uuid', true, 'gen_random_uuid()'),
  ('term_prices', 'plan_version_id', 'uuid', true, NULL),
  ('term_prices', 'pricing_mode', 'text', true, '''retail''::text'),
  ('term_prices', 'version', 'integer', true, NULL),
  ('term_prices', 'duration_months', 'integer', true, NULL),
  ('term_prices', 'amount_iqd', 'bigint', true, NULL),
  ('term_prices', 'currency', 'text', true, '''IQD''::text'),
  ('term_prices', 'status', 'text', true, '''draft''::text'),
  ('term_prices', 'published_at', 'timestamp with time zone', false, NULL),
  ('term_prices', 'retired_at', 'timestamp with time zone', false, NULL),
  ('term_prices', 'effective_from', 'timestamp with time zone', false, NULL),
  ('term_prices', 'effective_until', 'timestamp with time zone', false, NULL),
  ('term_prices', 'created_at', 'timestamp with time zone', true, 'now()');

CREATE TEMP TABLE m1a_expected_constraints (
  table_name text, constraint_name text, kind text, columns text[],
  target_schema text, target_table text, target_columns text[],
  PRIMARY KEY (table_name, constraint_name)
);
INSERT INTO m1a_expected_constraints VALUES
  ('entitlement_bundles', 'entitlement_bundles_pkey', 'p', ARRAY['id'], NULL, NULL, NULL),
  ('entitlement_bundles', 'uq_entitlement_bundles_code_version', 'u', ARRAY['code','version'], NULL, NULL, NULL),
  ('entitlement_bundles', 'chk_entitlement_bundles_code', 'c', ARRAY['code'], NULL, NULL, NULL),
  ('entitlement_bundles', 'chk_entitlement_bundles_version', 'c', ARRAY['version'], NULL, NULL, NULL),
  ('entitlement_bundles', 'chk_entitlement_bundles_registry_version', 'c', ARRAY['registry_version'], NULL, NULL, NULL),
  ('entitlement_bundles', 'chk_entitlement_bundles_lifecycle', 'c', ARRAY['status','published_at','retired_at'], NULL, NULL, NULL),
  ('bundle_items', 'bundle_items_pkey', 'p', ARRAY['id'], NULL, NULL, NULL),
  ('bundle_items', 'fk_bundle_items_bundle_version_id', 'f', ARRAY['bundle_version_id'], 'commercial_private', 'entitlement_bundles', ARRAY['id']),
  ('bundle_items', 'uq_bundle_items_bundle_key', 'u', ARRAY['bundle_version_id','capability_key'], NULL, NULL, NULL),
  ('bundle_items', 'chk_bundle_items_capability_key', 'c', ARRAY['capability_key'], NULL, NULL, NULL),
  ('bundle_items', 'chk_bundle_items_typed_value', 'c', ARRAY['value_kind','value_boolean','value_integer','value_text'], NULL, NULL, NULL),
  ('bundle_items', 'chk_bundle_items_integer_value', 'c', ARRAY['value_integer'], NULL, NULL, NULL),
  ('bundle_items', 'chk_bundle_items_text_value', 'c', ARRAY['value_text'], NULL, NULL, NULL),
  ('plan_versions', 'plan_versions_pkey', 'p', ARRAY['id'], NULL, NULL, NULL),
  ('plan_versions', 'fk_plan_versions_plan_id', 'f', ARRAY['plan_id'], 'public', 'plans', ARRAY['id']),
  ('plan_versions', 'fk_plan_versions_bundle_version_id', 'f', ARRAY['bundle_version_id'], 'commercial_private', 'entitlement_bundles', ARRAY['id']),
  ('plan_versions', 'uq_plan_versions_plan_version', 'u', ARRAY['plan_id','version'], NULL, NULL, NULL),
  ('plan_versions', 'uq_plan_versions_id_pricing_mode', 'u', ARRAY['id','pricing_mode'], NULL, NULL, NULL),
  ('plan_versions', 'chk_plan_versions_version', 'c', ARRAY['version'], NULL, NULL, NULL),
  ('plan_versions', 'chk_plan_versions_pricing_mode', 'c', ARRAY['pricing_mode'], NULL, NULL, NULL),
  ('plan_versions', 'chk_plan_versions_metadata', 'c', ARRAY['name_ar','description_ar'], NULL, NULL, NULL),
  ('plan_versions', 'chk_plan_versions_sort_order', 'c', ARRAY['sort_order'], NULL, NULL, NULL),
  ('plan_versions', 'chk_plan_versions_lifecycle', 'c', ARRAY['status','published_at','retired_at'], NULL, NULL, NULL),
  ('plan_versions', 'chk_plan_versions_effective_window', 'c', ARRAY['status','effective_from','effective_until'], NULL, NULL, NULL),
  ('term_prices', 'term_prices_pkey', 'p', ARRAY['id'], NULL, NULL, NULL),
  ('term_prices', 'fk_term_prices_plan_version_pricing_mode', 'f', ARRAY['plan_version_id','pricing_mode'], 'commercial_private', 'plan_versions', ARRAY['id','pricing_mode']),
  ('term_prices', 'uq_term_prices_plan_duration_version', 'u', ARRAY['plan_version_id','duration_months','version'], NULL, NULL, NULL),
  ('term_prices', 'chk_term_prices_version', 'c', ARRAY['version'], NULL, NULL, NULL),
  ('term_prices', 'chk_term_prices_pricing_mode', 'c', ARRAY['pricing_mode'], NULL, NULL, NULL),
  ('term_prices', 'chk_term_prices_duration_months', 'c', ARRAY['duration_months'], NULL, NULL, NULL),
  ('term_prices', 'chk_term_prices_amount_iqd', 'c', ARRAY['amount_iqd'], NULL, NULL, NULL),
  ('term_prices', 'chk_term_prices_currency', 'c', ARRAY['currency'], NULL, NULL, NULL),
  ('term_prices', 'chk_term_prices_lifecycle', 'c', ARRAY['status','published_at','retired_at'], NULL, NULL, NULL),
  ('term_prices', 'chk_term_prices_effective_window', 'c', ARRAY['status','effective_from','effective_until'], NULL, NULL, NULL);

SELECT is((SELECT count(*)::integer FROM m1a_expected_columns), 44,
  'independent expected inventory contains 44 columns');
SELECT is((SELECT count(*)::integer FROM m1a_expected_constraints), 34,
  'independent expected inventory contains 34 constraints');
SELECT is((SELECT count(*)::integer FROM pg_namespace
  WHERE nspname = 'commercial_private'), 1, 'exact private namespace exists');
SELECT is((SELECT pg_get_userbyid(nspowner)::text FROM pg_namespace
  WHERE nspname = 'commercial_private'), 'postgres', 'private schema owned by creator');
SELECT results_eq(
  $$ SELECT c.relname::text COLLATE "C" FROM pg_class c JOIN pg_namespace n
       ON n.oid = c.relnamespace
     WHERE n.nspname = 'commercial_private' AND c.relkind = 'r'
     ORDER BY c.relname $$,
  $$ SELECT table_name COLLATE "C" FROM (VALUES ('bundle_items'::text),
     ('entitlement_bundles'::text), ('plan_versions'::text),
     ('term_prices'::text)) expected(table_name) $$,
  'exactly the four accepted tables');
SELECT is((SELECT count(*)::integer FROM pg_class c JOIN pg_namespace n
  ON n.oid = c.relnamespace WHERE n.nspname = 'commercial_private'
  AND c.relkind NOT IN ('r', 'i')), 0,
  'no private view, materialized view, sequence or other relation');
SELECT is((SELECT count(*)::integer FROM pg_proc p JOIN pg_namespace n
  ON n.oid = p.pronamespace WHERE n.nspname = 'commercial_private'), 0,
  'no persistent private routine');
SELECT is((SELECT count(*)::integer FROM pg_trigger t JOIN pg_class c
  ON c.oid = t.tgrelid JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'commercial_private' AND NOT t.tgisinternal), 0,
  'no persistent user trigger; internal restrictive-FK triggers are permitted');
SELECT is((SELECT count(*)::integer FROM pg_publication_tables
  WHERE schemaname = 'commercial_private'), 0,
  'private tables absent from all publication table inventories');

SELECT is((SELECT count(*)::integer FROM pg_attribute a JOIN pg_class c
  ON c.oid = a.attrelid JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'commercial_private' AND c.relkind = 'r'
  AND a.attnum > 0 AND NOT a.attisdropped), 44, 'exact runtime column count');
SELECT results_eq(
  $$ SELECT c.relname::text COLLATE "C", a.attname::text COLLATE "C"
     FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'commercial_private' AND c.relkind = 'r'
       AND a.attnum > 0 AND NOT a.attisdropped ORDER BY 1, 2 $$,
  $$ SELECT table_name COLLATE "C", column_name COLLATE "C"
     FROM m1a_expected_columns ORDER BY 1, 2 $$,
  'exact column names, without extra columns');
SELECT is(format_type(a.atttypid, a.atttypmod), e.type_name,
  e.table_name || '.' || e.column_name || ' exact type')
FROM m1a_expected_columns e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = e.column_name
ORDER BY e.table_name, e.column_name;
SELECT is(a.attnotnull, e.required,
  e.table_name || '.' || e.column_name || ' exact nullability')
FROM m1a_expected_columns e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = e.column_name
ORDER BY e.table_name, e.column_name;
SELECT is(regexp_replace(pg_get_expr(d.adbin, d.adrelid), 'pg_catalog\.', '', 'g'),
  e.default_expression, e.table_name || '.' || e.column_name || ' exact default')
FROM m1a_expected_columns e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = e.column_name
LEFT JOIN pg_attrdef d ON d.adrelid = c.oid AND d.adnum = a.attnum
ORDER BY e.table_name, e.column_name;

SELECT results_eq(
  $$ SELECT c.relname::text COLLATE "C", k.conname::text COLLATE "C",
       k.contype::text COLLATE "C"
     FROM pg_constraint k JOIN pg_class c ON c.oid = k.conrelid
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'commercial_private' ORDER BY 1, 2 $$,
  $$ SELECT table_name COLLATE "C", constraint_name COLLATE "C", kind COLLATE "C"
     FROM m1a_expected_constraints ORDER BY 1, 2 $$,
  'exact 34 names, table association and constraint kinds');
SELECT is(
  CASE WHEN e.kind = 'c' THEN
    ARRAY(SELECT a.attname::text FROM unnest(k.conkey) key(attnum)
      JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = key.attnum
      ORDER BY a.attname)
  ELSE
    ARRAY(SELECT a.attname::text FROM unnest(k.conkey) WITH ORDINALITY key(attnum, ord)
      JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = key.attnum
      ORDER BY key.ord)
  END,
  CASE WHEN e.kind = 'c' THEN ARRAY(SELECT value FROM unnest(e.columns) value ORDER BY value)
    ELSE e.columns END,
  e.constraint_name || ' correct constrained columns')
FROM m1a_expected_constraints e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_constraint k ON k.conrelid = c.oid AND k.conname = e.constraint_name
ORDER BY e.table_name, e.constraint_name;
SELECT ok(k.convalidated AND NOT k.condeferrable AND NOT k.condeferred,
  e.constraint_name || ' validated immediate constraint')
FROM m1a_expected_constraints e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_constraint k ON k.conrelid = c.oid AND k.conname = e.constraint_name
ORDER BY e.table_name, e.constraint_name;
SELECT is(tn.nspname::text || '.' || tc.relname::text,
  e.target_schema || '.' || e.target_table, e.constraint_name || ' FK target')
FROM m1a_expected_constraints e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_constraint k ON k.conrelid = c.oid AND k.conname = e.constraint_name
JOIN pg_class tc ON tc.oid = k.confrelid JOIN pg_namespace tn ON tn.oid = tc.relnamespace
WHERE e.kind = 'f' ORDER BY e.constraint_name;
SELECT is(ARRAY(SELECT a.attname::text
    FROM unnest(k.confkey) WITH ORDINALITY key(attnum, ord)
    JOIN pg_attribute a ON a.attrelid = k.confrelid AND a.attnum = key.attnum
    ORDER BY key.ord), e.target_columns, e.constraint_name || ' ordered FK target columns')
FROM m1a_expected_constraints e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_constraint k ON k.conrelid = c.oid AND k.conname = e.constraint_name
WHERE e.kind = 'f' ORDER BY e.constraint_name;
SELECT ok(k.confupdtype = 'r' AND k.confdeltype = 'r' AND k.confmatchtype = 's',
  e.constraint_name || ' update/delete RESTRICT and MATCH SIMPLE')
FROM m1a_expected_constraints e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_constraint k ON k.conrelid = c.oid AND k.conname = e.constraint_name
WHERE e.kind = 'f' ORDER BY e.constraint_name;
SELECT results_eq(
  $$ SELECT c.relname::text COLLATE "C" FROM pg_class c JOIN pg_namespace n
     ON n.oid = c.relnamespace WHERE n.nspname = 'commercial_private'
     AND c.relkind = 'i' ORDER BY c.relname $$,
  $$ SELECT constraint_name COLLATE "C" FROM m1a_expected_constraints
     WHERE kind IN ('p', 'u') ORDER BY constraint_name $$,
  'exact nine PK/UNIQUE backing index names and no extra index');
SELECT ok(i.indisunique AND i.indisvalid AND i.indisready
  AND i.indpred IS NULL AND i.indexprs IS NULL AND ic.relname = e.constraint_name,
  e.constraint_name || ' valid plain unique backing index')
FROM m1a_expected_constraints e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_constraint k ON k.conrelid = c.oid AND k.conname = e.constraint_name
JOIN pg_index i ON i.indexrelid = k.conindid JOIN pg_class ic ON ic.oid = i.indexrelid
WHERE e.kind IN ('p', 'u') ORDER BY e.constraint_name;
SELECT is(pg_get_userbyid(c.relowner)::text, 'postgres', c.relname || ' owned by creator')
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'commercial_private' ORDER BY c.relname;
SELECT is(pg_get_userbyid(t.typowner)::text, 'postgres', t.typname || ' dependent type owned by creator')
FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
WHERE n.nspname = 'commercial_private' ORDER BY t.typname;
SELECT ok(c.relrowsecurity AND NOT c.relforcerowsecurity,
  c.relname || ' defensive RLS without changing owner administration')
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'commercial_private' AND c.relkind = 'r' ORDER BY c.relname;
SELECT is((SELECT count(*)::integer FROM pg_policy p JOIN pg_class c
  ON c.oid = p.polrelid JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'commercial_private'), 0, 'zero private policies');

-- PUBLIC is grantee OID 0, never a fictional role named PUBLIC.
SELECT is((SELECT count(*)::integer FROM pg_namespace n
  CROSS JOIN LATERAL aclexplode(coalesce(n.nspacl, acldefault('n', n.nspowner))) a
  WHERE n.nspname = 'commercial_private' AND a.grantee <> n.nspowner), 0,
  'schema has no PUBLIC or other nonowner ACL');
SELECT is((SELECT count(*)::integer FROM pg_class c JOIN pg_namespace n
  ON n.oid = c.relnamespace
  CROSS JOIN LATERAL aclexplode(coalesce(c.relacl, acldefault('r', c.relowner))) a
  WHERE n.nspname = 'commercial_private' AND c.relkind = 'r'
    AND a.grantee <> c.relowner), 0, 'private tables have no nonowner ACL');
SELECT ok(NOT pg_has_role(r.oid, 'postgres'::regrole, 'MEMBER'),
  r.rolname || ' cannot acquire creator membership')
FROM pg_roles r WHERE r.rolname IN ('anon', 'authenticated', 'service_role') ORDER BY r.rolname;
SELECT ok(NOT pg_has_role(r.oid, 'postgres'::regrole, 'SET'),
  r.rolname || ' has no SET membership path to creator')
FROM pg_roles r WHERE r.rolname IN ('anon', 'authenticated', 'service_role') ORDER BY r.rolname;
SELECT ok(NOT has_schema_privilege(r.oid, n.oid, privilege),
  r.rolname || ' lacks private schema ' || privilege)
FROM pg_roles r CROSS JOIN pg_namespace n CROSS JOIN (VALUES ('USAGE'), ('CREATE')) p(privilege)
WHERE r.rolname IN ('anon', 'authenticated', 'service_role')
  AND n.nspname = 'commercial_private' ORDER BY r.rolname, privilege;
SELECT ok(NOT has_table_privilege(r.oid, c.oid, privilege),
  r.rolname || ' lacks ' || c.relname || ' ' || privilege)
FROM pg_roles r CROSS JOIN pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
CROSS JOIN (VALUES ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'), ('TRUNCATE'),
  ('REFERENCES'), ('TRIGGER'), ('MAINTAIN')) p(privilege)
WHERE r.rolname IN ('anon', 'authenticated', 'service_role')
  AND n.nspname = 'commercial_private' AND c.relkind = 'r'
ORDER BY r.rolname, c.relname, privilege;

-- Missing global ACL means PostgreSQL's built-in defaults; missing schema ACL
-- means no additive grants. TYPES is inspected directly, without a custom type.
SELECT is((SELECT count(*)::integer
  FROM pg_roles r CROSS JOIN (VALUES ('r'::"char"), ('S'::"char"),
    ('f'::"char"), ('T'::"char")) object_class(kind)
  LEFT JOIN pg_default_acl d ON d.defaclrole = r.oid AND d.defaclnamespace = 0
    AND d.defaclobjtype = object_class.kind
  CROSS JOIN LATERAL aclexplode(coalesce(d.defaclacl, acldefault(object_class.kind, r.oid))) a
  WHERE r.rolname = 'postgres' AND a.grantee <> r.oid), 0,
  'creator global TABLES/SEQUENCES/FUNCTIONS/TYPES defaults have no nonowner grants');
SELECT is((SELECT count(*)::integer FROM pg_default_acl d JOIN pg_roles r
  ON r.oid = d.defaclrole JOIN pg_namespace n ON n.oid = d.defaclnamespace
  CROSS JOIN LATERAL aclexplode(d.defaclacl) a
  WHERE r.rolname = 'postgres' AND n.nspname = 'commercial_private'
    AND d.defaclobjtype IN ('r', 'S', 'f', 'T') AND a.grantee <> r.oid), 0,
  'private-schema default additions cannot restore nonowner authority');
SELECT is((SELECT count(*)::integer FROM pg_roles r
  CROSS JOIN (VALUES ('f'::"char"), ('T'::"char")) object_class(kind)
  LEFT JOIN pg_default_acl d ON d.defaclrole = r.oid AND d.defaclnamespace = 0
    AND d.defaclobjtype = object_class.kind
  CROSS JOIN LATERAL aclexplode(coalesce(d.defaclacl, acldefault(object_class.kind, r.oid))) a
  WHERE r.rolname = 'postgres' AND a.grantee = 0), 0,
  'built-in PUBLIC function EXECUTE and type USAGE removed globally');

SELECT is((SELECT count(*)::integer FROM commercial_private.entitlement_bundles),
  CASE WHEN (SELECT m1b_applied FROM m1a_phase) THEN 4 ELSE 0 END, 'exact accepted phase bundle count');
SELECT is((SELECT count(*)::integer FROM commercial_private.bundle_items),
  CASE WHEN (SELECT m1b_applied FROM m1a_phase) THEN 19 ELSE 0 END, 'exact accepted phase item count');
SELECT is((SELECT count(*)::integer FROM commercial_private.plan_versions),
  CASE WHEN (SELECT m1b_applied FROM m1a_phase) THEN 4 ELSE 0 END, 'exact accepted phase plan-version count');
SELECT is((SELECT count(*)::integer FROM commercial_private.term_prices),
  CASE WHEN (SELECT m1b_applied FROM m1a_phase) THEN 9 ELSE 0 END, 'exact accepted phase price count');

SELECT is(pg_temp.m1a_catalog_rows(relation_name::regclass)::text,
  (CASE WHEN m1b_applied THEN expected_rows ELSE '[]'::jsonb END)::text,
  relation_name || ' exact accepted phase rows; no extra catalog seed')
FROM m1a_catalog_expected CROSS JOIN m1a_phase ORDER BY relation_name;

-- Fresh objects are ordinary commercial_private objects under the verified R.
-- There is deliberately no per-probe privilege adjustment before assertions.
CREATE TABLE commercial_private.m1a_acl_probe_table (value integer);
CREATE SEQUENCE commercial_private.m1a_acl_probe_sequence;
CREATE FUNCTION commercial_private.m1a_acl_probe_function()
RETURNS integer LANGUAGE sql SECURITY INVOKER SET search_path = pg_catalog
AS 'SELECT 7';
SELECT is(current_user::text, 'postgres', 'fresh probes created under verified R');
SELECT is((SELECT count(*)::integer FROM pg_class c JOIN pg_namespace n
  ON n.oid = c.relnamespace
  CROSS JOIN LATERAL aclexplode(coalesce(c.relacl,
    acldefault(CASE WHEN c.relkind = 'S' THEN 'S'::"char" ELSE 'r'::"char" END, c.relowner))) a
  WHERE n.nspname = 'commercial_private'
    AND c.relname IN ('m1a_acl_probe_table', 'm1a_acl_probe_sequence')
    AND a.grantee <> c.relowner), 0, 'fresh table/sequence effective ACL has no nonowner grant');
SELECT is((SELECT count(*)::integer FROM pg_proc p JOIN pg_namespace n
  ON n.oid = p.pronamespace
  CROSS JOIN LATERAL aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
  WHERE n.nspname = 'commercial_private' AND p.proname = 'm1a_acl_probe_function'
    AND a.grantee <> p.proowner), 0, 'fresh function effective ACL independently denies PUBLIC');
SELECT ok(NOT has_function_privilege(r.oid, 'commercial_private.m1a_acl_probe_function()'::regprocedure, 'EXECUTE'),
  r.rolname || ' lacks fresh function EXECUTE independent of schema visibility')
FROM pg_roles r WHERE r.rolname IN ('anon', 'authenticated', 'service_role') ORDER BY r.rolname;
SELECT ok(NOT has_table_privilege(r.oid, 'commercial_private.m1a_acl_probe_table'::regclass, privilege),
  r.rolname || ' lacks fresh table ' || privilege)
FROM pg_roles r CROSS JOIN (VALUES ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
  ('TRUNCATE'), ('REFERENCES'), ('TRIGGER'), ('MAINTAIN')) p(privilege)
WHERE r.rolname IN ('anon', 'authenticated', 'service_role') ORDER BY r.rolname, privilege;
SELECT ok(NOT has_sequence_privilege(r.oid, 'commercial_private.m1a_acl_probe_sequence'::regclass, privilege),
  r.rolname || ' lacks fresh sequence ' || privilege)
FROM pg_roles r CROSS JOIN (VALUES ('USAGE'), ('SELECT'), ('UPDATE')) p(privilege)
WHERE r.rolname IN ('anon', 'authenticated', 'service_role') ORDER BY r.rolname, privilege;
SELECT is(pg_temp.m1a_result('INSERT INTO commercial_private.m1a_acl_probe_table VALUES (7)'),
  'NO_ERROR', 'owner can perform fresh table baseline operation');
SELECT is(pg_temp.m1a_result('SELECT nextval(''commercial_private.m1a_acl_probe_sequence'')'),
  'NO_ERROR', 'owner can perform fresh sequence baseline operation');
SELECT is(commercial_private.m1a_acl_probe_function(), 7, 'owner executes harmless invoker probe');
SELECT is(pg_temp.m1a_result(statement, role_name::name), '42501|',
  role_name || ' denied fresh ' || description)
FROM (VALUES ('anon'), ('authenticated')) roles(role_name)
CROSS JOIN (VALUES
  ('SELECT * FROM commercial_private.m1a_acl_probe_table', 'table SELECT'),
  ('SELECT nextval(''commercial_private.m1a_acl_probe_sequence'')', 'sequence operation'),
  ('SELECT commercial_private.m1a_acl_probe_function()', 'function execution')) operations(statement, description)
ORDER BY role_name, description;

-- Test identities, catalog rows and frozen amounts are never production seed.
INSERT INTO auth.users (id, email, created_at, updated_at) VALUES
  ('c1a10000-0000-4000-8000-000000000001', 'm1a-ordinary@example.invalid', now(), now()),
  ('c1a10000-0000-4000-8000-000000000002', 'm1a-business@example.invalid', now(), now()),
  ('c1a10000-0000-4000-8000-000000000003', 'm1a-staff@example.invalid', now(), now());
INSERT INTO public.profiles (user_id, display_name) VALUES
  ('c1a10000-0000-4000-8000-000000000001', 'M1a ordinary fixture'),
  ('c1a10000-0000-4000-8000-000000000002', 'M1a business fixture'),
  ('c1a10000-0000-4000-8000-000000000003', 'M1a staff fixture');
INSERT INTO public.directory_entities (id, entity_type, name, lifecycle_status) VALUES
  ('c1a50000-0000-4000-8000-000000000001', 'company', 'M1a active fixture', 'active'),
  ('c1a50000-0000-4000-8000-000000000002', 'company', 'M1a draft fixture', 'draft');
INSERT INTO public.business_memberships (user_id, entity_id, role) VALUES
  ('c1a10000-0000-4000-8000-000000000002', 'c1a50000-0000-4000-8000-000000000001', 'OWNER');
INSERT INTO public.staff_memberships (user_id, role_id)
SELECT 'c1a10000-0000-4000-8000-000000000003', id FROM public.roles WHERE code = 'application_reviewer';
SELECT is((SELECT count(*)::integer FROM public.staff_memberships
  WHERE user_id = 'c1a10000-0000-4000-8000-000000000003'), 1, 'staff fixture has real accepted staff membership');
INSERT INTO public.entity_contacts (id, entity_id, contact_type, value) VALUES
  ('c1a60000-0000-4000-8000-000000000001', 'c1a50000-0000-4000-8000-000000000001', 'email', 'active@example.invalid'),
  ('c1a60000-0000-4000-8000-000000000002', 'c1a50000-0000-4000-8000-000000000002', 'email', 'draft@example.invalid');
INSERT INTO public.plans (id, code, name, is_active) VALUES
  ('c1a20000-0000-4000-8000-000000000001', 'm1a_fixture_plan_01', 'M1a Business fixture', true),
  ('c1a20000-0000-4000-8000-000000000002', 'm1a_fixture_plan_02', 'M1a Pro fixture', true),
  ('c1a20000-0000-4000-8000-000000000003', 'm1a_fixture_plan_03', 'M1a Plus fixture', true),
  ('c1a20000-0000-4000-8000-000000000004', 'm1a_fixture_plan_04', 'M1a Corporate fixture', false);
INSERT INTO commercial_private.entitlement_bundles (id, code, version, registry_version) VALUES
  ('c1a00000-0000-4000-8000-000000000001', 'm1a_fixture', 1, 1),
  ('c1a00000-0000-4000-8000-000000000002', 'm1a_fixture', 2, 1);
INSERT INTO commercial_private.bundle_items
  (id, bundle_version_id, capability_key, value_kind, value_boolean, value_integer, value_text) VALUES
  ('c1a40000-0000-4000-8000-000000000001', 'c1a00000-0000-4000-8000-000000000001', 'fixture.boolean', 'boolean', false, NULL, NULL),
  ('c1a40000-0000-4000-8000-000000000002', 'c1a00000-0000-4000-8000-000000000001', 'fixture.integer', 'integer', NULL, 0, NULL),
  ('c1a40000-0000-4000-8000-000000000003', 'c1a00000-0000-4000-8000-000000000001', 'fixture.text', 'text', NULL, NULL, 'fixture');
INSERT INTO commercial_private.plan_versions
  (id, plan_id, version, bundle_version_id, pricing_mode, name_ar) VALUES
  ('c1a30000-0000-4000-8000-000000000001', 'c1a20000-0000-4000-8000-000000000001', 1, 'c1a00000-0000-4000-8000-000000000001', 'retail', 'اختبار الأعمال'),
  ('c1a30000-0000-4000-8000-000000000002', 'c1a20000-0000-4000-8000-000000000002', 1, 'c1a00000-0000-4000-8000-000000000001', 'retail', 'اختبار المحترف'),
  ('c1a30000-0000-4000-8000-000000000003', 'c1a20000-0000-4000-8000-000000000003', 1, 'c1a00000-0000-4000-8000-000000000001', 'retail', 'اختبار بلس'),
  ('c1a30000-0000-4000-8000-000000000004', 'c1a20000-0000-4000-8000-000000000004', 1, 'c1a00000-0000-4000-8000-000000000001', 'custom_quote', 'اختبار المؤسسة'),
  ('c1a30000-0000-4000-8000-000000000005', 'c1a20000-0000-4000-8000-000000000001', 2, 'c1a00000-0000-4000-8000-000000000002', 'retail', 'اختبار إصدار تاريخي');
INSERT INTO commercial_private.term_prices
  (id, plan_version_id, version, duration_months, amount_iqd) VALUES
  ('c1a70000-0000-4000-8000-000000000001', 'c1a30000-0000-4000-8000-000000000001', 1, 1, 20000),
  ('c1a70000-0000-4000-8000-000000000002', 'c1a30000-0000-4000-8000-000000000001', 1, 3, 55000),
  ('c1a70000-0000-4000-8000-000000000003', 'c1a30000-0000-4000-8000-000000000001', 1, 12, 200000),
  ('c1a70000-0000-4000-8000-000000000004', 'c1a30000-0000-4000-8000-000000000002', 1, 1, 40000),
  ('c1a70000-0000-4000-8000-000000000005', 'c1a30000-0000-4000-8000-000000000002', 1, 3, 110000),
  ('c1a70000-0000-4000-8000-000000000006', 'c1a30000-0000-4000-8000-000000000002', 1, 12, 400000),
  ('c1a70000-0000-4000-8000-000000000007', 'c1a30000-0000-4000-8000-000000000003', 1, 1, 70000),
  ('c1a70000-0000-4000-8000-000000000008', 'c1a30000-0000-4000-8000-000000000003', 1, 3, 190000),
  ('c1a70000-0000-4000-8000-000000000009', 'c1a30000-0000-4000-8000-000000000003', 1, 12, 700000);
SELECT results_eq(
  $$ SELECT p.code COLLATE "C", t.duration_months, t.amount_iqd FROM commercial_private.term_prices t
     JOIN commercial_private.plan_versions v ON v.id = t.plan_version_id
     JOIN public.plans p ON p.id = v.plan_id
     WHERE v.id IN ('c1a30000-0000-4000-8000-000000000001',
       'c1a30000-0000-4000-8000-000000000002',
       'c1a30000-0000-4000-8000-000000000003') ORDER BY 1, 2 $$,
  $$ SELECT code COLLATE "C", duration_months, amount_iqd FROM (VALUES
     ('m1a_fixture_plan_01'::text, 1, 20000::bigint), ('m1a_fixture_plan_01', 3, 55000::bigint),
     ('m1a_fixture_plan_01', 12, 200000::bigint), ('m1a_fixture_plan_03', 1, 70000::bigint),
     ('m1a_fixture_plan_03', 3, 190000::bigint), ('m1a_fixture_plan_03', 12, 700000::bigint),
     ('m1a_fixture_plan_02', 1, 40000::bigint), ('m1a_fixture_plan_02', 3, 110000::bigint),
     ('m1a_fixture_plan_02', 12, 400000::bigint)) expected(code, duration_months, amount_iqd) ORDER BY 1, 2 $$,
  'all nine frozen amount/duration shapes representable in bigint');
SELECT is((SELECT count(*)::integer FROM commercial_private.term_prices
  WHERE plan_version_id = 'c1a30000-0000-4000-8000-000000000004'), 0,
  'custom-quote Corporate requires no retail price');
SELECT is((SELECT count(*)::integer FROM commercial_private.plan_versions
  WHERE plan_id = 'c1a20000-0000-4000-8000-000000000001'), 2,
  'two historical plan-version IDs coexist');
SELECT is((SELECT count(*)::integer FROM commercial_private.bundle_items
  WHERE bundle_version_id = 'c1a00000-0000-4000-8000-000000000001'
    AND is_required AND created_at IS NOT NULL), 3,
  'default-required typed false/zero/text items representable');

CREATE TEMP TABLE m1a_fixture_rows (table_name text, id uuid);
INSERT INTO m1a_fixture_rows VALUES
  ('entitlement_bundles', 'c1a00000-0000-4000-8000-000000000001'),
  ('bundle_items', 'c1a40000-0000-4000-8000-000000000001'),
  ('plan_versions', 'c1a30000-0000-4000-8000-000000000001'),
  ('term_prices', 'c1a70000-0000-4000-8000-000000000001');
SELECT is(pg_temp.m1a_result(format('UPDATE commercial_private.%I SET %I = NULL WHERE id = %L',
  e.table_name, e.column_name, f.id)), '23502|',
  e.table_name || '.' || e.column_name || ' rejects explicit NULL')
FROM m1a_expected_columns e JOIN m1a_fixture_rows f USING (table_name)
WHERE e.required ORDER BY e.table_name, e.column_name;
SELECT is(pg_temp.m1a_result(format('UPDATE commercial_private.%I SET version = %s WHERE id = %L',
  f.table_name, value, f.id)), '23514|chk_' || f.table_name || '_version',
  f.table_name || ' rejects version ' || value)
FROM m1a_fixture_rows f CROSS JOIN (VALUES (0), (-1)) bad(value)
WHERE f.table_name <> 'bundle_items' ORDER BY f.table_name, value;
SELECT is(pg_temp.m1a_result(format('UPDATE commercial_private.entitlement_bundles SET registry_version = %s WHERE id = %L',
  value, 'c1a00000-0000-4000-8000-000000000001')), '23514|chk_entitlement_bundles_registry_version',
  'reject registry version ' || value) FROM (VALUES (0), (-1)) bad(value);

-- Named failure expectations are independent accepted names, not inferred SQL.
CREATE TEMP TABLE m1a_negative_cases (description text, statement text, expected text);
INSERT INTO m1a_negative_cases VALUES
  ('bundle PK', $$ INSERT INTO commercial_private.entitlement_bundles (id, code, version, registry_version)
    VALUES ('c1a00000-0000-4000-8000-000000000001', 'pk_duplicate', 99, 1) $$, '23505|entitlement_bundles_pkey'),
  ('item PK', $$ INSERT INTO commercial_private.bundle_items (id, bundle_version_id, capability_key, value_kind, value_boolean)
    VALUES ('c1a40000-0000-4000-8000-000000000001', 'c1a00000-0000-4000-8000-000000000001', 'pk.duplicate', 'boolean', true) $$, '23505|bundle_items_pkey'),
  ('plan PK', $$ INSERT INTO commercial_private.plan_versions (id, plan_id, version, bundle_version_id, pricing_mode, name_ar)
    VALUES ('c1a30000-0000-4000-8000-000000000001', 'c1a20000-0000-4000-8000-000000000001', 99, 'c1a00000-0000-4000-8000-000000000001', 'retail', 'fixture') $$, '23505|plan_versions_pkey'),
  ('price PK', $$ INSERT INTO commercial_private.term_prices (id, plan_version_id, version, duration_months, amount_iqd)
    VALUES ('c1a70000-0000-4000-8000-000000000001', 'c1a30000-0000-4000-8000-000000000001', 99, 1, 1) $$, '23505|term_prices_pkey'),
  ('bundle code/version duplicate', $$ INSERT INTO commercial_private.entitlement_bundles (code, version, registry_version)
    VALUES ('m1a_fixture', 1, 1) $$, '23505|uq_entitlement_bundles_code_version'),
  ('bundle item/key duplicate', $$ INSERT INTO commercial_private.bundle_items (bundle_version_id, capability_key, value_kind, value_boolean)
    VALUES ('c1a00000-0000-4000-8000-000000000001', 'fixture.boolean', 'boolean', true) $$, '23505|uq_bundle_items_bundle_key'),
  ('plan/version duplicate', $$ INSERT INTO commercial_private.plan_versions (plan_id, version, bundle_version_id, pricing_mode, name_ar)
    VALUES ('c1a20000-0000-4000-8000-000000000001', 1, 'c1a00000-0000-4000-8000-000000000001', 'retail', 'fixture') $$, '23505|uq_plan_versions_plan_version'),
  ('price plan/duration/version duplicate', $$ INSERT INTO commercial_private.term_prices (plan_version_id, version, duration_months, amount_iqd)
    VALUES ('c1a30000-0000-4000-8000-000000000001', 1, 1, 1) $$, '23505|uq_term_prices_plan_duration_version'),
  ('item orphan bundle', $$ UPDATE commercial_private.bundle_items SET bundle_version_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
    WHERE id = 'c1a40000-0000-4000-8000-000000000001' $$, '23503|fk_bundle_items_bundle_version_id'),
  ('plan orphan public identity', $$ UPDATE commercial_private.plan_versions SET plan_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
    WHERE id = 'c1a30000-0000-4000-8000-000000000001' $$, '23503|fk_plan_versions_plan_id'),
  ('plan orphan bundle', $$ UPDATE commercial_private.plan_versions SET bundle_version_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
    WHERE id = 'c1a30000-0000-4000-8000-000000000001' $$, '23503|fk_plan_versions_bundle_version_id'),
  ('price orphan plan version', $$ UPDATE commercial_private.term_prices SET plan_version_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
    WHERE id = 'c1a70000-0000-4000-8000-000000000001' $$, '23503|fk_term_prices_plan_version_pricing_mode'),
  ('price points at Corporate quote', $$ UPDATE commercial_private.term_prices SET plan_version_id = 'c1a30000-0000-4000-8000-000000000004'
    WHERE id = 'c1a70000-0000-4000-8000-000000000001' $$, '23503|fk_term_prices_plan_version_pricing_mode'),
  ('parent plan delete restrictive', $$ DELETE FROM public.plans WHERE id = 'c1a20000-0000-4000-8000-000000000001' $$, '23503|fk_plan_versions_plan_id'),
  ('parent plan identity update restrictive', $$ UPDATE public.plans SET id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
    WHERE id = 'c1a20000-0000-4000-8000-000000000001' $$, '23503|fk_plan_versions_plan_id'),
  ('price parent delete restrictive', $$ DELETE FROM commercial_private.plan_versions
    WHERE id = 'c1a30000-0000-4000-8000-000000000001' $$, '23503|fk_term_prices_plan_version_pricing_mode'),
  ('price parent update restrictive', $$ UPDATE commercial_private.plan_versions SET id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
    WHERE id = 'c1a30000-0000-4000-8000-000000000001' $$, '23503|fk_term_prices_plan_version_pricing_mode'),
  ('unknown item kind', $$ UPDATE commercial_private.bundle_items SET value_kind = 'json'
    WHERE id = 'c1a40000-0000-4000-8000-000000000001' $$, '23514|chk_bundle_items_typed_value'),
  ('missing boolean value', $$ UPDATE commercial_private.bundle_items SET value_boolean = NULL
    WHERE id = 'c1a40000-0000-4000-8000-000000000001' $$, '23514|chk_bundle_items_typed_value'),
  ('missing integer value', $$ UPDATE commercial_private.bundle_items SET value_integer = NULL
    WHERE id = 'c1a40000-0000-4000-8000-000000000002' $$, '23514|chk_bundle_items_typed_value'),
  ('missing text value', $$ UPDATE commercial_private.bundle_items SET value_text = NULL
    WHERE id = 'c1a40000-0000-4000-8000-000000000003' $$, '23514|chk_bundle_items_typed_value'),
  ('multiple boolean/integer values', $$ UPDATE commercial_private.bundle_items SET value_integer = 0
    WHERE id = 'c1a40000-0000-4000-8000-000000000001' $$, '23514|chk_bundle_items_typed_value'),
  ('multiple integer/text values', $$ UPDATE commercial_private.bundle_items SET value_text = 'extra'
    WHERE id = 'c1a40000-0000-4000-8000-000000000002' $$, '23514|chk_bundle_items_typed_value'),
  ('multiple text/boolean values', $$ UPDATE commercial_private.bundle_items SET value_boolean = true
    WHERE id = 'c1a40000-0000-4000-8000-000000000003' $$, '23514|chk_bundle_items_typed_value'),
  ('negative integer scalar', $$ UPDATE commercial_private.bundle_items SET value_integer = -1
    WHERE id = 'c1a40000-0000-4000-8000-000000000002' $$, '23514|chk_bundle_items_integer_value'),
  ('empty text scalar', $$ UPDATE commercial_private.bundle_items SET value_text = ''
    WHERE id = 'c1a40000-0000-4000-8000-000000000003' $$, '23514|chk_bundle_items_text_value'),
  ('whitespace text scalar', $$ UPDATE commercial_private.bundle_items SET value_text = '   '
    WHERE id = 'c1a40000-0000-4000-8000-000000000003' $$, '23514|chk_bundle_items_text_value'),
  ('oversize text scalar', $$ UPDATE commercial_private.bundle_items SET value_text = repeat('a', 257)
    WHERE id = 'c1a40000-0000-4000-8000-000000000003' $$, '23514|chk_bundle_items_text_value'),
  ('empty Arabic metadata', $$ UPDATE commercial_private.plan_versions SET name_ar = ''
    WHERE id = 'c1a30000-0000-4000-8000-000000000001' $$, '23514|chk_plan_versions_metadata'),
  ('whitespace Arabic metadata', $$ UPDATE commercial_private.plan_versions SET name_ar = '   '
    WHERE id = 'c1a30000-0000-4000-8000-000000000001' $$, '23514|chk_plan_versions_metadata'),
  ('empty optional description', $$ UPDATE commercial_private.plan_versions SET description_ar = ''
    WHERE id = 'c1a30000-0000-4000-8000-000000000001' $$, '23514|chk_plan_versions_metadata'),
  ('whitespace optional description', $$ UPDATE commercial_private.plan_versions SET description_ar = '   '
    WHERE id = 'c1a30000-0000-4000-8000-000000000001' $$, '23514|chk_plan_versions_metadata'),
  ('negative sort order', $$ UPDATE commercial_private.plan_versions SET sort_order = -1
    WHERE id = 'c1a30000-0000-4000-8000-000000000001' $$, '23514|chk_plan_versions_sort_order'),
  ('unsupported plan pricing mode', $$ UPDATE commercial_private.plan_versions SET pricing_mode = 'trial'
    WHERE id = 'c1a30000-0000-4000-8000-000000000005' $$, '23514|chk_plan_versions_pricing_mode'),
  ('unsupported price pricing mode', $$ UPDATE commercial_private.term_prices SET pricing_mode = 'custom_quote'
    WHERE id = 'c1a70000-0000-4000-8000-000000000001' $$, '23514|chk_term_prices_pricing_mode'),
  ('negative IQD amount', $$ UPDATE commercial_private.term_prices SET amount_iqd = -1
    WHERE id = 'c1a70000-0000-4000-8000-000000000001' $$, '23514|chk_term_prices_amount_iqd'),
  ('wrong currency', $$ UPDATE commercial_private.term_prices SET currency = 'USD'
    WHERE id = 'c1a70000-0000-4000-8000-000000000001' $$, '23514|chk_term_prices_currency');
SELECT is(pg_temp.m1a_result(statement), expected, description || ' SQLSTATE and named constraint')
FROM m1a_negative_cases ORDER BY description;
SELECT is(pg_temp.m1a_result(format('UPDATE commercial_private.entitlement_bundles SET code = %L WHERE id = %L',
  value, 'c1a00000-0000-4000-8000-000000000001')), '23514|chk_entitlement_bundles_code',
  'malformed bundle code ' || quote_literal(value))
FROM (VALUES (''), ('Upper'), ('9start'), ('has.dot'), ('has space'),
  ('valid;select'), (repeat('a', 65)), (E'valid\n')) bad(value);
SELECT is(pg_temp.m1a_result(format('UPDATE commercial_private.bundle_items SET capability_key = %L WHERE id = %L',
  value, 'c1a40000-0000-4000-8000-000000000001')), '23514|chk_bundle_items_capability_key',
  'malformed capability key ' || quote_literal(value))
FROM (VALUES (''), ('Upper'), ('9start'), ('.leading'), ('trailing.'), ('double..dot'),
  ('has space'), ('one.2two'), ('sql;expression'), (repeat('a', 129)), (E'valid\n')) bad(value);
SELECT is(pg_temp.m1a_result(format('UPDATE commercial_private.term_prices SET duration_months = %s WHERE id = %L',
  value, 'c1a70000-0000-4000-8000-000000000001')), '23514|chk_term_prices_duration_months',
  'invalid retail duration ' || value) FROM (VALUES (-1), (0), (2), (6)) bad(value);

-- Lifecycle and finite/window semantics tested across every relevant table.
CREATE TEMP TABLE m1a_lifecycle_failures (description text, assignment text);
INSERT INTO m1a_lifecycle_failures VALUES
  ('unsupported status', $$ status = 'active' $$),
  ('draft publication marker', $$ published_at = '2026-01-01 00:00:00+00' $$),
  ('draft retirement marker', $$ retired_at = '2026-01-01 00:00:00+00' $$),
  ('published missing publication', $$ status = 'published' $$),
  ('published unexpected retirement', $$ status = 'published', published_at = '2026-01-01 00:00:00+00', retired_at = '2026-01-02 00:00:00+00' $$),
  ('retired missing both markers', $$ status = 'retired' $$),
  ('retired missing retirement', $$ status = 'retired', published_at = '2026-01-01 00:00:00+00' $$),
  ('retired missing publication', $$ status = 'retired', retired_at = '2026-01-01 00:00:00+00' $$),
  ('retirement before publication', $$ status = 'retired', published_at = '2026-01-02 00:00:00+00', retired_at = '2026-01-01 00:00:00+00' $$),
  ('infinite publication', $$ status = 'published', published_at = 'infinity' $$),
  ('negative infinite publication', $$ status = 'published', published_at = '-infinity' $$),
  ('infinite retirement', $$ status = 'retired', published_at = '2026-01-01 00:00:00+00', retired_at = 'infinity' $$);
SELECT is(pg_temp.m1a_result(format('UPDATE commercial_private.%I SET %s%s WHERE id = %L',
  f.table_name, bad.assignment,
  CASE WHEN f.table_name <> 'entitlement_bundles' THEN ', effective_from = ''2026-01-01 00:00:00+00''' ELSE '' END,
  f.id)), '23514|chk_' || f.table_name || '_lifecycle',
  f.table_name || ' lifecycle rejects ' || bad.description)
FROM m1a_fixture_rows f CROSS JOIN m1a_lifecycle_failures bad
WHERE f.table_name <> 'bundle_items' ORDER BY f.table_name, bad.description;
CREATE TEMP TABLE m1a_window_failures (description text, assignment text);
INSERT INTO m1a_window_failures VALUES
  ('end without start', $$ effective_until = '2026-02-01 00:00:00+00' $$),
  ('equal endpoints', $$ effective_from = '2026-01-01 00:00:00+00', effective_until = '2026-01-01 00:00:00+00' $$),
  ('reversed endpoints', $$ effective_from = '2026-02-01 00:00:00+00', effective_until = '2026-01-01 00:00:00+00' $$),
  ('infinite start', $$ effective_from = 'infinity' $$),
  ('negative infinite start', $$ effective_from = '-infinity' $$),
  ('infinite end', $$ effective_from = '2026-01-01 00:00:00+00', effective_until = 'infinity' $$),
  ('negative infinite end', $$ effective_from = '2026-01-01 00:00:00+00', effective_until = '-infinity' $$),
  ('published without effective start', $$ status = 'published', published_at = '2026-01-01 00:00:00+00' $$),
  ('retired without effective start', $$ status = 'retired', published_at = '2026-01-01 00:00:00+00', retired_at = '2026-01-02 00:00:00+00' $$);
SELECT is(pg_temp.m1a_result(format('UPDATE commercial_private.%I SET %s WHERE id = %L',
  f.table_name, bad.assignment, f.id)), '23514|chk_' || f.table_name || '_effective_window',
  f.table_name || ' window rejects ' || bad.description)
FROM m1a_fixture_rows f CROSS JOIN m1a_window_failures bad
WHERE f.table_name IN ('plan_versions', 'term_prices') ORDER BY f.table_name, bad.description;
SELECT is(pg_temp.m1a_result(format('UPDATE commercial_private.%I SET status = ''published'', published_at = ''2026-01-01 00:00:00+00''%s WHERE id = %L',
  f.table_name, CASE WHEN f.table_name <> 'entitlement_bundles'
    THEN ', effective_from = ''2026-01-01 00:00:00+00''' ELSE '' END, f.id)), 'NO_ERROR',
  f.table_name || ' valid finite published shape')
FROM m1a_fixture_rows f WHERE f.table_name <> 'bundle_items' ORDER BY f.table_name;
SELECT is(pg_temp.m1a_result(format('UPDATE commercial_private.%I SET status = ''retired'', published_at = ''2026-01-01 00:00:00+00'', retired_at = ''2026-01-01 00:00:00+00''%s WHERE id = %L',
  f.table_name, CASE WHEN f.table_name <> 'entitlement_bundles'
    THEN ', effective_from = ''2026-01-01 00:00:00+00'', effective_until = ''2026-02-01 00:00:00+00''' ELSE '' END,
  f.id)), 'NO_ERROR', f.table_name || ' valid retirement equality and finite interval')
FROM m1a_fixture_rows f WHERE f.table_name <> 'bundle_items' ORDER BY f.table_name;
SELECT is(pg_temp.m1a_result(format('UPDATE commercial_private.%I SET effective_from = ''2026-01-01 00:00:00+00'', effective_until = NULL WHERE id = %L',
  f.table_name, f.id)), 'NO_ERROR', f.table_name || ' planned draft with null end allowed')
FROM m1a_fixture_rows f WHERE f.table_name IN ('plan_versions', 'term_prices') ORDER BY f.table_name;
SELECT is(pg_temp.m1a_result($$ UPDATE commercial_private.bundle_items SET value_text = repeat('a', 256)
  WHERE id = 'c1a40000-0000-4000-8000-000000000003' $$), 'NO_ERROR', '256-character scalar accepted');
SELECT is(pg_temp.m1a_result($$ UPDATE commercial_private.entitlement_bundles SET code = repeat('a', 64)
  WHERE id = 'c1a00000-0000-4000-8000-000000000001' $$), 'NO_ERROR', '64-character code accepted');
SELECT is(pg_temp.m1a_result($$ UPDATE commercial_private.bundle_items SET capability_key = repeat('a', 128)
  WHERE id = 'c1a40000-0000-4000-8000-000000000001' $$), 'NO_ERROR', '128-character key accepted');
SELECT is(pg_temp.m1a_result($$ UPDATE commercial_private.term_prices SET amount_iqd = 0
  WHERE id = 'c1a70000-0000-4000-8000-000000000001' $$), 'NO_ERROR', 'zero is storage-representable without authorizing a free tier');

-- Actual role-bound SQL, including valid ordinary/business/staff identities.
SELECT set_config('request.jwt.claim.sub', '', true);
SELECT is(pg_temp.m1a_result(format('%s commercial_private.%I%s', operation.prefix, f.table_name, operation.suffix), 'anon'),
  '42501|', 'anon denied ' || f.table_name || ' ' || operation.description)
FROM m1a_fixture_rows f CROSS JOIN (VALUES
  ('SELECT * FROM', '', 'SELECT'), ('INSERT INTO', ' DEFAULT VALUES', 'INSERT'),
  ('UPDATE', ' SET id = id', 'UPDATE'), ('DELETE FROM', '', 'DELETE'),
  ('TRUNCATE TABLE', '', 'TRUNCATE')) operation(prefix, suffix, description)
ORDER BY f.table_name, operation.description;
SELECT is(pg_temp.m1a_result(format('%s commercial_private.%I%s', operation.prefix, f.table_name, operation.suffix), 'authenticated', actor.id),
  '42501|', actor.description || ' denied ' || f.table_name || ' ' || operation.description)
FROM (VALUES ('c1a10000-0000-4000-8000-000000000001', 'ordinary authenticated'),
  ('c1a10000-0000-4000-8000-000000000002', 'business OWNER'),
  ('c1a10000-0000-4000-8000-000000000003', 'provisioned staff')) actor(id, description)
CROSS JOIN m1a_fixture_rows f CROSS JOIN (VALUES
  ('SELECT * FROM', '', 'SELECT'), ('INSERT INTO', ' DEFAULT VALUES', 'INSERT'),
  ('UPDATE', ' SET id = id', 'UPDATE'), ('DELETE FROM', '', 'DELETE'),
  ('TRUNCATE TABLE', '', 'TRUNCATE')) operation(prefix, suffix, description)
ORDER BY actor.description, f.table_name, operation.description;
SELECT is(pg_temp.m1a_result('CREATE TABLE commercial_private.m1a_client_injection (id integer)', role_name::name),
  '42501|', role_name || ' denied private schema CREATE')
FROM (VALUES ('anon'), ('authenticated'), ('service_role')) roles(role_name);
-- SET ROLE authorization is based on session_user: a postgres test login can
-- always restore itself. The independent MEMBER/SET catalog assertions above
-- test client escalation rather than misrepresenting owner-session switching.
SELECT is(current_user::text, 'postgres', 'role attempts restored owner for pgTAP');

-- Verified 00023 denies raw plans; the 00022 phase retains its historical
-- fixture read. Unrelated active-parent Directory filtering
-- remains preserved. Operational HTTP probes remain an external gate.
SELECT is(CASE WHEN harden1_applied THEN
  pg_temp.m1a_result(statement, role_name::name)
  ELSE pg_temp.m1a_read(statement, role_name::name) END,
  CASE WHEN harden1_applied THEN '42501|' ELSE '4' END,
  role_name || CASE WHEN harden1_applied
    THEN ' raw public plans read denied after HARDEN-1'
    ELSE ' historical raw plans fixture read before HARDEN-1' END)
FROM (VALUES ('anon'), ('authenticated')) roles(role_name)
CROSS JOIN m1a_phase CROSS JOIN (VALUES
  ($$ SELECT count(*)::text FROM public.plans
     WHERE id IN ('c1a20000-0000-4000-8000-000000000001',
       'c1a20000-0000-4000-8000-000000000002',
       'c1a20000-0000-4000-8000-000000000003',
       'c1a20000-0000-4000-8000-000000000004') $$)) probe(statement);
SELECT is(pg_temp.m1a_read($$ SELECT count(*)::text FROM public.directory_entities
  WHERE id IN ('c1a50000-0000-4000-8000-000000000001', 'c1a50000-0000-4000-8000-000000000002') $$,
  role_name::name), '1', role_name || ' Directory retains active-only filtering')
FROM (VALUES ('anon'), ('authenticated')) roles(role_name);
SELECT is(pg_temp.m1a_read($$ SELECT count(*)::text FROM public.entity_contacts
  WHERE id IN ('c1a60000-0000-4000-8000-000000000001', 'c1a60000-0000-4000-8000-000000000002') $$,
  role_name::name), '1', role_name || ' Directory child retains active-parent filtering')
FROM (VALUES ('anon'), ('authenticated')) roles(role_name);
SELECT is(pg_temp.m1a_result($$ UPDATE public.directory_entities SET name = 'denied'
  WHERE id = 'c1a50000-0000-4000-8000-000000000001' $$, role_name::name),
  '42501|', role_name || ' Directory mutation still denied')
FROM (VALUES ('anon'), ('authenticated')) roles(role_name);
SELECT is(pg_temp.m1a_result('SELECT * FROM public.subscriptions', role_name::name),
  '42501|', role_name || ' legacy subscriptions remain inaccessible')
FROM (VALUES ('anon'), ('authenticated')) roles(role_name);
SELECT is((SELECT format_type(a.atttypid, a.atttypmod) FROM pg_attribute a
  WHERE a.attrelid = 'public.subscriptions'::regclass AND a.attname = 'price_paid'),
  'numeric(12,2)', 'legacy numeric amount remains unchanged for M4');

-- Remove only deterministic fixture rows before fingerprint comparisons; the
-- final transaction rollback independently removes every test-side change.
DELETE FROM commercial_private.term_prices WHERE plan_version_id IN
  ('c1a30000-0000-4000-8000-000000000001', 'c1a30000-0000-4000-8000-000000000002', 'c1a30000-0000-4000-8000-000000000003');
DELETE FROM commercial_private.plan_versions WHERE id IN
  ('c1a30000-0000-4000-8000-000000000001', 'c1a30000-0000-4000-8000-000000000002',
   'c1a30000-0000-4000-8000-000000000003', 'c1a30000-0000-4000-8000-000000000004', 'c1a30000-0000-4000-8000-000000000005');
DELETE FROM commercial_private.bundle_items WHERE bundle_version_id = 'c1a00000-0000-4000-8000-000000000001';
DELETE FROM commercial_private.entitlement_bundles WHERE id IN
  ('c1a00000-0000-4000-8000-000000000001', 'c1a00000-0000-4000-8000-000000000002');
DELETE FROM public.plans WHERE id IN
  ('c1a20000-0000-4000-8000-000000000001', 'c1a20000-0000-4000-8000-000000000002',
   'c1a20000-0000-4000-8000-000000000003', 'c1a20000-0000-4000-8000-000000000004');
DELETE FROM public.entity_contacts WHERE id IN
  ('c1a60000-0000-4000-8000-000000000001', 'c1a60000-0000-4000-8000-000000000002');
DELETE FROM public.business_memberships WHERE user_id = 'c1a10000-0000-4000-8000-000000000002'
  AND entity_id = 'c1a50000-0000-4000-8000-000000000001';
DELETE FROM public.directory_entities WHERE id IN
  ('c1a50000-0000-4000-8000-000000000001', 'c1a50000-0000-4000-8000-000000000002');
DELETE FROM public.staff_memberships WHERE user_id = 'c1a10000-0000-4000-8000-000000000003';
DELETE FROM public.profiles WHERE user_id IN
  ('c1a10000-0000-4000-8000-000000000001', 'c1a10000-0000-4000-8000-000000000002', 'c1a10000-0000-4000-8000-000000000003');
DELETE FROM auth.users WHERE id IN
  ('c1a10000-0000-4000-8000-000000000001', 'c1a10000-0000-4000-8000-000000000002', 'c1a10000-0000-4000-8000-000000000003');
DROP FUNCTION commercial_private.m1a_acl_probe_function();
DROP SEQUENCE commercial_private.m1a_acl_probe_sequence;
DROP TABLE commercial_private.m1a_acl_probe_table;

SELECT is((SELECT count(*)::integer FROM commercial_private.entitlement_bundles),
  (SELECT row_count FROM m1a_catalog_snapshot WHERE relation_name = 'commercial_private.entitlement_bundles'),
  'fixture cleanup restores accepted commercial_private.entitlement_bundles count');
SELECT is((SELECT count(*)::integer FROM commercial_private.bundle_items),
  (SELECT row_count FROM m1a_catalog_snapshot WHERE relation_name = 'commercial_private.bundle_items'),
  'fixture cleanup restores accepted commercial_private.bundle_items count');
SELECT is((SELECT count(*)::integer FROM commercial_private.plan_versions),
  (SELECT row_count FROM m1a_catalog_snapshot WHERE relation_name = 'commercial_private.plan_versions'),
  'fixture cleanup restores accepted commercial_private.plan_versions count');
SELECT is((SELECT count(*)::integer FROM commercial_private.term_prices),
  (SELECT row_count FROM m1a_catalog_snapshot WHERE relation_name = 'commercial_private.term_prices'),
  'fixture cleanup restores accepted commercial_private.term_prices count');
SELECT is((SELECT count(*)::integer FROM pg_proc p JOIN pg_namespace n
  ON n.oid = p.pronamespace WHERE n.nspname = 'commercial_private'), 0, 'no remaining private probe function');
SELECT is((SELECT count(*)::integer FROM pg_class c JOIN pg_namespace n
  ON n.oid = c.relnamespace WHERE n.nspname = 'commercial_private' AND c.relkind = 'S'), 0,
  'no remaining private probe sequence');
SELECT is((SELECT count(*)::integer FROM pg_class c JOIN pg_namespace n
  ON n.oid = c.relnamespace WHERE n.nspname = 'commercial_private' AND c.relkind = 'r'), 4,
  'only four accepted tables remain after probes');
SELECT is((SELECT md5(coalesce(string_agg(row_to_json(p)::text, E'\n' ORDER BY id), '')) FROM public.plans p),
  plans_data, 'existing public plan rows unchanged') FROM m1a_public_snapshot;
SELECT is((SELECT md5(coalesce(string_agg(row_to_json(s)::text, E'\n' ORDER BY id), '')) FROM public.subscriptions s),
  subscriptions_data, 'existing legacy subscription rows unchanged') FROM m1a_public_snapshot;
SELECT is((SELECT md5(coalesce(string_agg(row_to_json(e)::text, E'\n' ORDER BY id), '')) FROM public.directory_entities e),
  directory_data, 'existing Directory entity rows unchanged') FROM m1a_public_snapshot;
SELECT is((SELECT md5(coalesce(string_agg(row_to_json(m)::text, E'\n' ORDER BY user_id, entity_id), '')) FROM public.business_memberships m),
  membership_data, 'existing business memberships unchanged') FROM m1a_public_snapshot;
SELECT is((SELECT md5(coalesce(string_agg(c.oid::text || ':' || coalesce(c.relacl::text, '<implicit>'), E'\n' ORDER BY c.oid), ''))
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public'),
  public_table_acls, 'fresh defaults probes did not alter existing public table ACLs') FROM m1a_public_snapshot;
SELECT is((SELECT md5(coalesce(string_agg(p.oid::text || ':' || coalesce(p.proacl::text, '<implicit>') || ':' || pg_get_functiondef(p.oid),
  E'\n' ORDER BY p.oid), '')) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.prokind IN ('f', 'p', 'w')),
  public_rpcs, 'existing public RPC definitions/ACLs unchanged by fresh defaults') FROM m1a_public_snapshot;
SELECT is((SELECT md5(coalesce(string_agg(d.defaclrole::text || ':' || d.defaclnamespace::text || ':' || d.defaclobjtype::text || ':' || d.defaclacl::text,
  E'\n' ORDER BY d.defaclrole, d.defaclnamespace, d.defaclobjtype), '')) FROM pg_default_acl d),
  default_acls, 'probe creation preserved all creator/schema defaults') FROM m1a_public_snapshot;

SELECT is(pg_temp.m1a_catalog_rows(relation_name::regclass)::text,
  row_data::text, relation_name || ' exact baseline identities/values restored')
FROM m1a_catalog_snapshot ORDER BY relation_name;
SELECT is(pg_temp.m1a_private_security()::text, fingerprint::text,
  'private owner/ACL/RLS/column/policy baseline restored after probes')
FROM m1a_private_security_snapshot;

SELECT * FROM finish();
ROLLBACK;
