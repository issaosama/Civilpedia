-- Independent fixtures: accepted M3 §§33/35; no live catalog reads or source-derived oracle.
BEGIN ISOLATION LEVEL REPEATABLE READ;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path=public,extensions,pg_temp;
SELECT no_plan();
CREATE FUNCTION pg_temp.m3_hash(j jsonb,k text) RETURNS jsonb LANGUAGE sql AS $$
 SELECT jsonb_set(j,ARRAY[k],to_jsonb(encode(extensions.digest(convert_to((j-k)::text,'UTF8'),'sha256'),'hex')))
$$;
CREATE FUNCTION pg_temp.m3_gate() RETURNS jsonb LANGUAGE sql AS $$
 SELECT '{"status":"PASS","entity_id":"a3000001-0000-4000-8000-000000000001","evidence_id":"a3000002-0000-4000-8000-000000000002","revision":1,"decided_at":"2026-01-01T00:00:00.000000Z","content_revision":null,"requirements_revision":null,"scope_id":null,"policy_dependency":null}'::jsonb
$$;
CREATE FUNCTION pg_temp.m3_e_input() RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE j jsonb; c jsonb; g jsonb:=pg_temp.m3_gate(); provider jsonb:='{"status":"COMPLETE","revision":1,"source_origin":"test_fixture"}';
BEGIN
 c:=pg_temp.m3_hash('{
 "plan_id":"1a7b0001-0000-4000-8000-000000000001","family":"business",
 "plan_version_id":"4c7b0001-0000-4000-8000-000000000001","plan_version":1,"pricing_mode":"retail",
 "plan_status":"PUBLISHED","plan_published_at":"2026-01-01T00:00:00.000000Z","plan_retired_at":null,
 "bundle_version_id":"2e7b0001-0000-4000-8000-000000000001","bundle_version":1,"registry_version":1,
 "bundle_status":"PUBLISHED","bundle_published_at":"2026-01-01T00:00:00.000000Z","bundle_retired_at":null,
 "approval_evidence_id":"a3000002-0000-4000-8000-000000000002","approved_at":"2026-01-01T00:00:00.000000Z","snapshot_revision":null,
 "items":[
 {"capability_key":"analytics.available","value_kind":"boolean","value_boolean":true,"value_integer":null,"value_text":null,"is_required":true},
 {"capability_key":"branches.included","value_kind":"integer","value_boolean":null,"value_integer":1,"value_text":null,"is_required":true},
 {"capability_key":"media.upload_enabled","value_kind":"boolean","value_boolean":true,"value_integer":null,"value_text":null,"is_required":true},
 {"capability_key":"sponsored.purchase_eligible","value_kind":"boolean","value_boolean":false,"value_integer":null,"value_text":null,"is_required":true},
 {"capability_key":"team.active_member_max","value_kind":"integer","value_boolean":null,"value_integer":5,"value_text":null,"is_required":true}]
 }','snapshot_revision');
 j:='{
 "envelope_kind":"ENTITLEMENT_INPUT","input_version":"m3.input.v1","evaluator_version":"m3.evaluator.v1","calendar_rule_version":"m3.baghdad_calendar.v1",
 "source_origin":"test_fixture","entity_id":"a3000001-0000-4000-8000-000000000001","as_of":"2026-02-15T00:00:00.000000Z",
 "input_revision":null,"synthetic_provider_revision":1,"providers":{},
 "model_eligibility":null,
 "agreement":{"agreement_id":"a3000003-0000-4000-8000-000000000003","entity_id":"a3000001-0000-4000-8000-000000000001","revision":1,"approval_state":"APPROVED","approval_evidence_id":"a3000002-0000-4000-8000-000000000002","approved_at":"2026-01-01T00:00:00.000000Z"},
 "catalog":[],
 "terms":[{"term_id":"a3000004-0000-4000-8000-000000000004","source_id":"a3000005-0000-4000-8000-000000000005","agreement_id":"a3000003-0000-4000-8000-000000000003","agreement_revision":1,
 "plan_version_id":"4c7b0001-0000-4000-8000-000000000001","bundle_version_id":"2e7b0001-0000-4000-8000-000000000001",
 "purpose":"INITIAL","predecessor_term_id":null,"duration_months":1,"purchased_at":"2026-01-20T00:00:00.000000Z",
 "authorization":{"kind":"VERIFIED_FUNDS","state":"APPROVED","evidence_id":"a3000002-0000-4000-8000-000000000002","decided_at":"2026-01-01T00:00:00.000000Z","quote_id":null,"quote_valid_from":null,"quote_valid_until":null,"quote_accepted_at":null,"commitment_months":null,"payment_condition":null},
 "anchor_rule":"PUBLICATION","anchor":{"anchor_event_id":"a3000006-0000-4000-8000-000000000006","entity_id":"a3000001-0000-4000-8000-000000000001","effective_at":"2026-01-31T00:00:00.000000Z","recorded_at":"2026-01-31T00:00:00.000000Z","publication_event_id":"a3000007-0000-4000-8000-000000000007","requests_evidence_id":null,"delay_evidence_id":null,"cause_at_deadline":null},
 "original_end":"2026-02-28T00:00:00.000000Z","effective_end":"2026-02-28T00:00:00.000000Z","extensions":[]}],
 "grants":[],"enforcement":{"context":"CLEAR","entity_id":"a3000001-0000-4000-8000-000000000001","evidence_id":"a3000002-0000-4000-8000-000000000002","revision":1,"effective_at":"2026-01-01T00:00:00.000000Z"},"prior_publication":null}';
 j:=jsonb_set(j,'{providers}',jsonb_build_object('eligibility',provider,'agreement_terms',provider,'grants',provider,'catalog',provider,'enforcement',provider,'publication_history',provider));
 j:=jsonb_set(jsonb_set(jsonb_set(j,'{model_eligibility}',g),'{terms,0,authorization,payment_condition}',g),'{catalog}',jsonb_build_array(c));
 RETURN pg_temp.m3_hash(j,'input_revision');
END $$;
CREATE FUNCTION pg_temp.m3_eval(j jsonb,p_time timestamptz DEFAULT '2026-02-15T00:00:00Z') RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE r jsonb;k text;
BEGIN
 SELECT to_jsonb(e) INTO r FROM commercial_private.m3_evaluate_entitlement_v1(j,p_time) e;
 FOREACH k IN ARRAY ARRAY['as_of','original_start','original_end','effective_end','grace_end','next_boundary'] LOOP
 IF r->>k IS NOT NULL THEN r:=jsonb_set(r,ARRAY[k],to_jsonb(to_char(timezone('UTC',(r->>k)::timestamptz),'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'))); END IF;
 END LOOP;
 RETURN r;
END $$;
CREATE FUNCTION pg_temp.m3_p_input(e jsonb) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE j jsonb;g jsonb:=pg_temp.m3_gate();cg jsonb;sg jsonb;scope_id text:='a3000008-0000-4000-8000-000000000008';
BEGIN
 cg:=jsonb_set(g,'{content_revision}','17'); sg:=jsonb_set(g,'{scope_id}',to_jsonb(scope_id));
 j:=jsonb_build_object('envelope_kind','PUBLICATION_INPUT','input_version','m3.input.v1','evaluator_version','m3.evaluator.v1',
 'calendar_rule_version','m3.baghdad_calendar.v1','entity_id',e->'entity_id','source_origin','test_fixture','as_of',e->'as_of',
 'synthetic_provider_revision',1,'entitlement_input_revision',e->'input_revision','entitlement_result_fingerprint',e->'result_fingerprint','publication_input_revision',NULL,
 'legacy_visible',true,'scope',jsonb_build_object('scope_id',scope_id,'category_id',scope_id,'market_id',scope_id,'market_context','BAGHDAD','revision',1),
 'content_revision',17,'required_fields',jsonb_set(cg,'{requirements_revision}','3'),'onboarding',g,'moderation',cg,
 'verification_requirement','NOT_REQUIRED','verification_state','UNVERIFIED','verification',g,
 'enforcement','{"context":"CLEAR","entity_id":"a3000001-0000-4000-8000-000000000001","evidence_id":"a3000002-0000-4000-8000-000000000002","revision":1,"effective_at":"2026-01-01T00:00:00.000000Z"}'::jsonb,
 'launch',sg,'projection',jsonb_build_object('descriptor_id',scope_id,'entity_id',e->'entity_id','content_revision',17,'kind','SELECTED','format_version','m3.public_descriptor.v1',
 'approval',cg,'public_field_paths','["approved_name"]'::jsonb,'conformance',cg,'projection_revision',9,'candidate_generation',7),
 'prior_publication',NULL,'authority_revision',9,'projection_revision',9,'authoritative_generation',7,'candidate_generation',7);
 RETURN pg_temp.m3_hash(j,'publication_input_revision');
END $$;
CREATE FUNCTION pg_temp.m3_pub(e jsonb,p jsonb) RETURNS jsonb LANGUAGE sql AS $$
 SELECT to_jsonb(r) FROM commercial_private.m3_evaluate_publication_v1(e,p,(p->>'as_of')::timestamptz) r
$$;
CREATE TEMP TABLE m3_expected_plans AS
SELECT id::uuid,code,name,NULL::text AS description,false AS is_active,
  TIMESTAMPTZ '2026-01-01 00:00:00+00' AS created_at,
  TIMESTAMPTZ '2026-01-01 00:00:00+00' AS updated_at
FROM (VALUES
 ('1a7b0001-0000-4000-8000-000000000001','business','Business'),
 ('1a7b0002-0000-4000-8000-000000000002','business_pro','Business Pro'),
 ('1a7b0003-0000-4000-8000-000000000003','business_plus','Business Plus'),
 ('1a7b0004-0000-4000-8000-000000000004','corporate','Corporate')
) v(id,code,name);

CREATE TEMP TABLE m3_expected_entitlement_bundles AS
SELECT id::uuid,code,1::integer AS version,1::integer AS registry_version,
  'draft'::text AS status,NULL::timestamptz AS published_at,NULL::timestamptz AS retired_at,
  TIMESTAMPTZ '2026-01-01 00:00:00+00' AS created_at
FROM (VALUES
 ('2e7b0001-0000-4000-8000-000000000001','business_entitlements'),
 ('2e7b0002-0000-4000-8000-000000000002','business_pro_entitlements'),
 ('2e7b0003-0000-4000-8000-000000000003','business_plus_entitlements'),
 ('2e7b0004-0000-4000-8000-000000000004','corporate_entitlements')
) v(id,code);

CREATE TEMP TABLE m3_expected_plan_versions AS
SELECT id::uuid,plan_id::uuid,1::integer AS version,bundle_version_id::uuid,pricing_mode,
  '__AR_LOCALIZATION_PENDING__'::text AS name_ar,NULL::text AS description_ar,sort_order,
  'draft'::text AS status,NULL::timestamptz AS published_at,NULL::timestamptz AS retired_at,
  NULL::timestamptz AS effective_from,NULL::timestamptz AS effective_until,
  TIMESTAMPTZ '2026-01-01 00:00:00+00' AS created_at
FROM (VALUES
 ('4c7b0001-0000-4000-8000-000000000001','1a7b0001-0000-4000-8000-000000000001','2e7b0001-0000-4000-8000-000000000001','retail',1),
 ('4c7b0002-0000-4000-8000-000000000002','1a7b0002-0000-4000-8000-000000000002','2e7b0002-0000-4000-8000-000000000002','retail',2),
 ('4c7b0003-0000-4000-8000-000000000003','1a7b0003-0000-4000-8000-000000000003','2e7b0003-0000-4000-8000-000000000003','retail',3),
 ('4c7b0004-0000-4000-8000-000000000004','1a7b0004-0000-4000-8000-000000000004','2e7b0004-0000-4000-8000-000000000004','custom_quote',4)
) v(id,plan_id,bundle_version_id,pricing_mode,sort_order);

CREATE TEMP TABLE m3_expected_bundle_items AS
SELECT id::uuid,bundle_version_id::uuid,capability_key,value_kind,
  value_boolean,value_integer::bigint,NULL::text AS value_text,true AS is_required,
  TIMESTAMPTZ '2026-01-01 00:00:00+00' AS created_at
FROM (VALUES
 ('3a7b0001-0000-4000-8000-000000000001','2e7b0001-0000-4000-8000-000000000001','branches.included','integer',NULL::boolean,1),
 ('3a7b0002-0000-4000-8000-000000000002','2e7b0001-0000-4000-8000-000000000001','team.active_member_max','integer',NULL,5),
 ('3a7b0003-0000-4000-8000-000000000003','2e7b0001-0000-4000-8000-000000000001','media.upload_enabled','boolean',true,NULL),
 ('3a7b0004-0000-4000-8000-000000000004','2e7b0001-0000-4000-8000-000000000001','analytics.available','boolean',true,NULL),
 ('3a7b0005-0000-4000-8000-000000000005','2e7b0001-0000-4000-8000-000000000001','sponsored.purchase_eligible','boolean',false,NULL),
 ('3a7b0006-0000-4000-8000-000000000001','2e7b0002-0000-4000-8000-000000000002','branches.included','integer',NULL,2),
 ('3a7b0007-0000-4000-8000-000000000001','2e7b0002-0000-4000-8000-000000000002','team.active_member_max','integer',NULL,5),
 ('3a7b0008-0000-4000-8000-000000000001','2e7b0002-0000-4000-8000-000000000002','media.upload_enabled','boolean',true,NULL),
 ('3a7b0009-0000-4000-8000-000000000001','2e7b0002-0000-4000-8000-000000000002','analytics.available','boolean',true,NULL),
 ('3a7b0010-0000-4000-8000-000000000001','2e7b0002-0000-4000-8000-000000000002','sponsored.purchase_eligible','boolean',true,NULL),
 ('3a7b0011-0000-4000-8000-000000000001','2e7b0003-0000-4000-8000-000000000003','branches.included','integer',NULL,3),
 ('3a7b0012-0000-4000-8000-000000000001','2e7b0003-0000-4000-8000-000000000003','team.active_member_max','integer',NULL,5),
 ('3a7b0013-0000-4000-8000-000000000001','2e7b0003-0000-4000-8000-000000000003','media.upload_enabled','boolean',true,NULL),
 ('3a7b0014-0000-4000-8000-000000000001','2e7b0003-0000-4000-8000-000000000003','analytics.available','boolean',true,NULL),
 ('3a7b0015-0000-4000-8000-000000000001','2e7b0003-0000-4000-8000-000000000003','sponsored.purchase_eligible','boolean',true,NULL),
 ('3a7b0016-0000-4000-8000-000000000001','2e7b0004-0000-4000-8000-000000000004','branches.included','integer',NULL,3),
 ('3a7b0017-0000-4000-8000-000000000001','2e7b0004-0000-4000-8000-000000000004','team.active_member_max','integer',NULL,5),
 ('3a7b0018-0000-4000-8000-000000000001','2e7b0004-0000-4000-8000-000000000004','media.upload_enabled','boolean',true,NULL),
 ('3a7b0019-0000-4000-8000-000000000001','2e7b0004-0000-4000-8000-000000000004','analytics.available','boolean',true,NULL)
) v(id,bundle_version_id,capability_key,value_kind,value_boolean,value_integer);

CREATE TEMP TABLE m3_expected_term_prices AS
SELECT id::uuid,plan_version_id::uuid,'retail'::text AS pricing_mode,1::integer AS version,
  duration_months,amount_iqd::bigint,'IQD'::text AS currency,'draft'::text AS status,
  NULL::timestamptz AS published_at,NULL::timestamptz AS retired_at,
  NULL::timestamptz AS effective_from,NULL::timestamptz AS effective_until,
  TIMESTAMPTZ '2026-01-01 00:00:00+00' AS created_at
FROM (VALUES
 ('5d7b0001-0000-4000-8000-000000000001','4c7b0001-0000-4000-8000-000000000001',1,20000),
 ('5d7b0002-0000-4000-8000-000000000002','4c7b0001-0000-4000-8000-000000000001',3,55000),
 ('5d7b0003-0000-4000-8000-000000000003','4c7b0001-0000-4000-8000-000000000001',12,200000),
 ('5d7b0004-0000-4000-8000-000000000004','4c7b0002-0000-4000-8000-000000000002',1,40000),
 ('5d7b0005-0000-4000-8000-000000000005','4c7b0002-0000-4000-8000-000000000002',3,110000),
 ('5d7b0006-0000-4000-8000-000000000006','4c7b0002-0000-4000-8000-000000000002',12,400000),
 ('5d7b0007-0000-4000-8000-000000000007','4c7b0003-0000-4000-8000-000000000003',1,70000),
 ('5d7b0008-0000-4000-8000-000000000008','4c7b0003-0000-4000-8000-000000000003',3,190000),
 ('5d7b0009-0000-4000-8000-000000000009','4c7b0003-0000-4000-8000-000000000003',12,700000)
) v(id,plan_version_id,duration_months,amount_iqd);

SELECT is((SELECT jsonb_agg(to_jsonb(x) ORDER BY id) FROM public.plans x),(SELECT jsonb_agg(to_jsonb(x) ORDER BY id) FROM m3_expected_plans x),'composed catalog plans: exact independent frozen tuple oracle');
SELECT is((SELECT jsonb_agg(to_jsonb(x) ORDER BY id) FROM commercial_private.entitlement_bundles x),(SELECT jsonb_agg(to_jsonb(x) ORDER BY id) FROM m3_expected_entitlement_bundles x),'composed catalog entitlement_bundles: exact independent frozen tuple oracle');
SELECT is((SELECT jsonb_agg(to_jsonb(x) ORDER BY id) FROM commercial_private.plan_versions x),(SELECT jsonb_agg(to_jsonb(x) ORDER BY id) FROM m3_expected_plan_versions x),'composed catalog plan_versions: exact independent frozen tuple oracle');
SELECT is((SELECT jsonb_agg(to_jsonb(x) ORDER BY id) FROM commercial_private.bundle_items x),(SELECT jsonb_agg(to_jsonb(x) ORDER BY id) FROM m3_expected_bundle_items x),'composed catalog bundle_items: exact independent frozen tuple oracle');
SELECT is((SELECT jsonb_agg(to_jsonb(x) ORDER BY id) FROM commercial_private.term_prices x),(SELECT jsonb_agg(to_jsonb(x) ORDER BY id) FROM m3_expected_term_prices x),'composed catalog term_prices: exact independent frozen tuple oracle');
SELECT ok(NOT EXISTS(SELECT 1 FROM pg_class c CROSS JOIN LATERAL aclexplode(COALESCE(c.relacl,acldefault('r',c.relowner))) a WHERE c.relnamespace='commercial_private'::regnamespace AND c.relkind='r' AND a.grantee<>c.relowner),'all six private table ACLs owner only');
SELECT ok(NOT EXISTS(SELECT 1 FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid WHERE c.relnamespace='commercial_private'::regnamespace AND a.attnum>0 AND a.attacl IS NOT NULL),'no private column ACL escape');
SELECT ok(NOT EXISTS(SELECT 1 FROM pg_namespace n CROSS JOIN LATERAL aclexplode(COALESCE(n.nspacl,acldefault('n',n.nspowner))) a WHERE n.nspname='commercial_private' AND a.grantee<>n.nspowner),'private schema owner only');
SELECT ok(NOT EXISTS(SELECT 1 FROM pg_publication_tables WHERE schemaname='commercial_private' OR (schemaname='public' AND tablename='plans')),'private and raw plans excluded from Realtime');
SELECT ok(NOT has_table_privilege('anon','public.plans','SELECT') AND NOT has_table_privilege('authenticated','public.plans','SELECT'),'ordinary roles cannot read raw plans');
SELECT ok(NOT EXISTS(SELECT 1 FROM pg_default_acl d CROSS JOIN LATERAL aclexplode(d.defaclacl) a WHERE d.defaclrole='postgres'::regrole AND d.defaclnamespace IN (0,'commercial_private'::regnamespace) AND a.grantee<>d.defaclrole),'M1a trusted default privileges remain hardened');
SELECT ok(NOT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.prosrc ~* '\m(commercial_private|plans)\M'),'no public private-catalog/M3 proxy');
-- Bounded rollback positive control: prove the catalog query detects a proxy.
CREATE FUNCTION public.m3_test_proxy_detection_v1() RETURNS boolean LANGUAGE sql
AS $$ SELECT commercial_private.m3_generation_matches_v1(0,0,0,0) $$;
SELECT ok(EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='m3_test_proxy_detection_v1' AND p.prosrc ~* '\m(commercial_private|plans)\M'),'proxy regex positive detection control');
DROP FUNCTION public.m3_test_proxy_detection_v1();

CREATE TEMP TABLE m3_checkpoint_columns (
  table_name text, column_name text, type_name text, required boolean,
  default_expression text, PRIMARY KEY (table_name, column_name)
);
INSERT INTO m3_checkpoint_columns VALUES
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

CREATE TEMP TABLE m3_checkpoint_constraints (
  table_name text, constraint_name text, kind text, columns text[],
  target_schema text, target_table text, target_columns text[],
  PRIMARY KEY (table_name, constraint_name)
);
INSERT INTO m3_checkpoint_constraints VALUES
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

SELECT is((SELECT count(*)::integer FROM m3_checkpoint_columns), 44,
  'independent expected inventory contains 44 columns');
SELECT is(format_type(a.atttypid, a.atttypmod), e.type_name,
  e.table_name || '.' || e.column_name || ' exact type')
FROM m3_checkpoint_columns e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = e.column_name
ORDER BY e.table_name, e.column_name;
SELECT is(a.attnotnull, e.required,
  e.table_name || '.' || e.column_name || ' exact nullability')
FROM m3_checkpoint_columns e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = e.column_name
ORDER BY e.table_name, e.column_name;
SELECT is(regexp_replace(pg_get_expr(d.adbin, d.adrelid), 'pg_catalog\.', '', 'g'),
  e.default_expression, e.table_name || '.' || e.column_name || ' exact default')
FROM m3_checkpoint_columns e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = e.column_name
LEFT JOIN pg_attrdef d ON d.adrelid = c.oid AND d.adnum = a.attnum
ORDER BY e.table_name, e.column_name;

SELECT results_eq(
  $$ SELECT c.relname::text COLLATE "C", k.conname::text COLLATE "C",
       k.contype::text COLLATE "C"
     FROM pg_constraint k JOIN pg_class c ON c.oid = k.conrelid
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'commercial_private' AND c.relname NOT LIKE 'm3_%' ORDER BY 1, 2 $$,
  $$ SELECT table_name COLLATE "C", constraint_name COLLATE "C", kind COLLATE "C"
     FROM m3_checkpoint_constraints ORDER BY 1, 2 $$,
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
FROM m3_checkpoint_constraints e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_constraint k ON k.conrelid = c.oid AND k.conname = e.constraint_name
ORDER BY e.table_name, e.constraint_name;
SELECT ok(k.convalidated AND NOT k.condeferrable AND NOT k.condeferred,
  e.constraint_name || ' validated immediate constraint')
FROM m3_checkpoint_constraints e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_constraint k ON k.conrelid = c.oid AND k.conname = e.constraint_name
ORDER BY e.table_name, e.constraint_name;
SELECT is(tn.nspname::text || '.' || tc.relname::text,
  e.target_schema || '.' || e.target_table, e.constraint_name || ' FK target')
FROM m3_checkpoint_constraints e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_constraint k ON k.conrelid = c.oid AND k.conname = e.constraint_name
JOIN pg_class tc ON tc.oid = k.confrelid JOIN pg_namespace tn ON tn.oid = tc.relnamespace
WHERE e.kind = 'f' ORDER BY e.constraint_name;
SELECT is(ARRAY(SELECT a.attname::text
    FROM unnest(k.confkey) WITH ORDINALITY key(attnum, ord)
    JOIN pg_attribute a ON a.attrelid = k.confrelid AND a.attnum = key.attnum
    ORDER BY key.ord), e.target_columns, e.constraint_name || ' ordered FK target columns')
FROM m3_checkpoint_constraints e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_constraint k ON k.conrelid = c.oid AND k.conname = e.constraint_name
WHERE e.kind = 'f' ORDER BY e.constraint_name;
SELECT ok(k.confupdtype = 'r' AND k.confdeltype = 'r' AND k.confmatchtype = 's',
  e.constraint_name || ' update/delete RESTRICT and MATCH SIMPLE')
FROM m3_checkpoint_constraints e JOIN pg_class c ON c.relname = e.table_name
JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'commercial_private'
JOIN pg_constraint k ON k.conrelid = c.oid AND k.conname = e.constraint_name
WHERE e.kind = 'f' ORDER BY e.constraint_name;
SELECT results_eq(
  $$ SELECT c.relname::text COLLATE "C" FROM pg_class c JOIN pg_namespace n
     ON n.oid = c.relnamespace WHERE n.nspname = 'commercial_private'
     AND c.relkind = 'i' AND c.relname NOT LIKE 'm3_%' ORDER BY c.relname $$,
  $$ SELECT constraint_name COLLATE "C" FROM m3_checkpoint_constraints
     WHERE kind IN ('p', 'u') ORDER BY constraint_name $$,
  'exact nine PK/UNIQUE backing index names and no extra index');


CREATE TEMP TABLE m3_fixture AS SELECT pg_temp.m3_e_input() AS input;
CREATE TEMP TABLE m3_results AS SELECT pg_temp.m3_eval(input) AS e FROM m3_fixture;
CREATE TEMP TABLE m3_publication AS SELECT pg_temp.m3_p_input(e) AS p FROM m3_results;

SELECT is((SELECT count(*)::integer FROM pg_class WHERE relnamespace='commercial_private'::regnamespace AND relkind='r'),6,'exact composed six-table inventory');
SELECT is((SELECT count(*)::integer FROM pg_proc WHERE pronamespace='commercial_private'::regnamespace),4,'exact four-function inventory');
SELECT is((SELECT count(*)::integer FROM pg_class WHERE relnamespace='commercial_private'::regnamespace AND relkind='i'),13,'nine predecessor plus four M3 indexes');
SELECT is((SELECT count(*)::integer FROM pg_policy p JOIN pg_class c ON c.oid=p.polrelid WHERE c.relnamespace='commercial_private'::regnamespace),0,'private zero policies');
SELECT is((SELECT count(*)::integer FROM pg_constraint k JOIN pg_class c ON c.oid=k.conrelid WHERE c.relnamespace='commercial_private'::regnamespace AND c.relname NOT LIKE 'm3_%'),34,'original 34 constraints retained');
SELECT is((SELECT count(*)::integer FROM commercial_private.plan_versions),4,'four canonical plan versions');
SELECT is((SELECT count(*)::integer FROM commercial_private.entitlement_bundles),4,'four canonical bundles');
SELECT is((SELECT count(*)::integer FROM commercial_private.bundle_items),19,'nineteen canonical capability rows');
SELECT is((SELECT count(*)::integer FROM commercial_private.term_prices),9,'nine canonical prices');
SELECT is((SELECT count(*)::integer FROM public.plans),4,'four dormant canonical public plan identities');
SELECT ok(NOT EXISTS(SELECT 1 FROM pg_proc p WHERE p.pronamespace='commercial_private'::regnamespace AND (p.prosecdef OR p.proowner<>'postgres'::regrole OR p.proconfig IS DISTINCT FROM ARRAY['search_path=commercial_private, pg_temp'])),'four invoker functions owned by postgres with fixed path');
SELECT ok(NOT EXISTS(SELECT 1 FROM pg_class WHERE relnamespace='commercial_private'::regnamespace AND relkind='r' AND (NOT relrowsecurity OR relforcerowsecurity OR relowner<>'postgres'::regrole)),'six private tables retain exact RLS/owner posture');
SELECT is((SELECT array_agg(a.attname::text ORDER BY a.attnum) FROM pg_attribute a WHERE a.attrelid='commercial_private.m3_shadow_heads'::regclass AND a.attnum>0 AND NOT a.attisdropped),ARRAY['entity_id','shadow_generation','created_at','updated_at'],'heads exact four columns');
SELECT is((SELECT array_agg(a.attname::text ORDER BY a.attnum) FROM pg_attribute a WHERE a.attrelid='commercial_private.m3_shadow_runs'::regclass AND a.attnum>0 AND NOT a.attisdropped),ARRAY['request_id','entity_id','expected_shadow_generation','shadow_generation','evaluator_version','input_version','calendar_rule_version','source_origin','input_fingerprint','observed_at','recorded_at','legacy_visible','authority_outcome','entitlement_outcome','publication_outcome','mismatch_category','reason_codes','result_summary','authority_revision','projection_revision','authoritative_generation','candidate_generation'],'runs exact twenty-two columns');

SELECT is((SELECT array_agg(p.proargnames[x.i] ORDER BY x.i) FROM pg_proc p CROSS JOIN LATERAL generate_subscripts(p.proargnames,1) x(i) WHERE p.pronamespace='commercial_private'::regnamespace AND p.proname='m3_evaluate_entitlement_v1' AND p.proargmodes[x.i]='t'),ARRAY['envelope_kind','input_version','evaluator_version','calendar_rule_version','entity_id','source_origin','as_of','input_revision','synthetic_provider_revision','authority_outcome','basis_context','source_kind','entitlement_outcome','enforcement_context','enforcement_revision','continuity_eligible','agreement_id','term_id','grant_id','plan_id','plan_version_id','plan_version','bundle_version_id','bundle_version','registry_version','snapshot_revision','original_start','original_end','effective_end','grace_end','prior_publication_event_id','capabilities','next_boundary','reason_codes','result_fingerprint'],'m3_evaluate_entitlement_v1 exact ordered return interface');
SELECT is((SELECT array_agg(p.proargnames[x.i] ORDER BY x.i) FROM pg_proc p CROSS JOIN LATERAL generate_subscripts(p.proargnames,1) x(i) WHERE p.pronamespace='commercial_private'::regnamespace AND p.proname='m3_evaluate_publication_v1' AND p.proargmodes[x.i]='t'),ARRAY['input_version','evaluator_version','calendar_rule_version','entity_id','source_origin','as_of','synthetic_provider_revision','entitlement_input_revision','publication_input_revision','authority_outcome','entitlement_outcome','enforcement_context','verification_requirement','verification_state','intrinsic_readiness','candidate_first_publication_ready','continuity_eligible','discoverability_outcome','gate_results','authority_revision','projection_revision','authoritative_generation','candidate_generation','generation_matches','legacy_visible','comparison_target','comparison_result','mismatch_category','reason_codes'],'m3_evaluate_publication_v1 exact ordered return interface');
SELECT is((SELECT array_agg(p.proargnames[x.i] ORDER BY x.i) FROM pg_proc p CROSS JOIN LATERAL generate_subscripts(p.proargnames,1) x(i) WHERE p.pronamespace='commercial_private'::regnamespace AND p.proname='m3_capture_shadow_v1' AND p.proargmodes[x.i]='t'),ARRAY['capture_status','is_historical','request_id','entity_id','expected_shadow_generation','shadow_generation','source_origin','input_version','evaluator_version','calendar_rule_version','observed_at','recorded_at','input_fingerprint','entitlement_input_revision','publication_input_revision','legacy_visible','authority_outcome','entitlement_outcome','publication_outcome','comparison_target','comparison_result','mismatch_category','authority_revision','projection_revision','authoritative_generation','candidate_generation','reason_codes','result_summary'],'m3_capture_shadow_v1 exact ordered return interface');
SELECT is((SELECT e->>'authority_outcome' FROM m3_results),'COMPLETE','independent paid fixture is complete');
SELECT is((SELECT e->>'entitlement_outcome' FROM m3_results),'ENTITLED','approved paid interval grants historical entitlement');
SELECT is((SELECT e->>'original_end' FROM m3_results),'2026-02-28T00:00:00.000000Z','January 31 clamps one true Baghdad month to February 28');
SELECT is((SELECT e->>'grace_end' FROM m3_results),'2026-03-05T00:00:00.000000Z','Grace exactly five calendar days');
SELECT is((SELECT e#>>'{capabilities,sponsored.purchase_eligible,value}' FROM m3_results),'false','Business Sponsored false remains explicit false');
SELECT is((SELECT e#>>'{capabilities,sponsored.purchase_eligible,commercial_permission}' FROM m3_results),'DENY','false Sponsored cannot grant purchase eligibility');
SELECT is((SELECT e#>>'{capabilities,branches.included,value}' FROM m3_results),'1','Business branch capability independent literal one');
SELECT is((SELECT e#>>'{capabilities,team.active_member_max,value}' FROM m3_results),'5','five active member floor retained');
SELECT is((SELECT pg_temp.m3_pub(e,p)->>'discoverability_outcome' FROM m3_results,m3_publication),'ALLOW','independent selected public-safe projection allows fixture discovery');
SELECT is((SELECT pg_temp.m3_pub(e,p)->>'comparison_result' FROM m3_results,m3_publication),'MATCH','visible positive fixture comparison matches');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{legacy_visible}','false'),'publication_input_revision'))->>'mismatch_category' FROM m3_results,m3_publication),'LEGACY_HIDDEN_CANONICAL_ALLOW','hidden legacy comparison does not manufacture publication');
SELECT is((SELECT count(*)::integer FROM public.directory_entities),0,'positive synthetic fixture creates no Directory entity');
SELECT is((SELECT count(*)::integer FROM public.subscriptions),0,'positive synthetic fixture creates no subscription');

SELECT is((SELECT reason_codes FROM commercial_private.m3_evaluate_entitlement_v1('{}'::jsonb,'2026-02-15T00:00:00Z')),ARRAY['MISSING_REQUIRED_FIELD'],'empty envelope');
SELECT is((SELECT reason_codes FROM commercial_private.m3_evaluate_entitlement_v1('null'::jsonb,'2026-02-15T00:00:00Z')),ARRAY['INVALID_ENVELOPE'],'JSON null envelope');
SELECT is((SELECT reason_codes FROM commercial_private.m3_evaluate_entitlement_v1('[]'::jsonb,'2026-02-15T00:00:00Z')),ARRAY['INVALID_ENVELOPE'],'array envelope');
SELECT is((SELECT reason_codes FROM commercial_private.m3_evaluate_entitlement_v1('17'::jsonb,'2026-02-15T00:00:00Z')),ARRAY['INVALID_ENVELOPE'],'number envelope');
SELECT is((SELECT reason_codes FROM commercial_private.m3_evaluate_entitlement_v1(NULL,'2026-02-15T00:00:00Z')),ARRAY['INVALID_ENVELOPE'],'SQL null envelope');
SELECT is((SELECT reason_codes FROM commercial_private.m3_evaluate_entitlement_v1(pg_temp.m3_e_input(),'infinity')),ARRAY['NONFINITE_TIMESTAMP'],'nonfinite native as-of fails closed');
SELECT is((SELECT reason_codes FROM commercial_private.m3_evaluate_entitlement_v1(pg_temp.m3_e_input(),NULL)),ARRAY['INVALID_TIMESTAMP'],'SQL null as-of fails closed');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'envelope_kind')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member envelope_kind');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'input_version')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member input_version');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'evaluator_version')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member evaluator_version');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'calendar_rule_version')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member calendar_rule_version');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'source_origin')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member source_origin');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'entity_id')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member entity_id');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'as_of')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member as_of');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'input_revision')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member input_revision');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'synthetic_provider_revision')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member synthetic_provider_revision');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'providers')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member providers');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'model_eligibility')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member model_eligibility');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'agreement')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member agreement');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'catalog')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member catalog');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'terms')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member terms');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'grants')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member grants');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'enforcement')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member enforcement');
SELECT is((pg_temp.m3_eval(pg_temp.m3_e_input()-'prior_publication')->'reason_codes'), '["MISSING_REQUIRED_FIELD"]'::jsonb,'required entitlement member prior_publication');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{entity_id}','"00000000-0000-0000-0000-000000000000"'::jsonb))->'reason_codes'),'["INVALID_UUID"]'::jsonb,'fail closed {entity_id} "00000000-0000-0000-0000-000000000000"');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{entity_id}','"A3000001-0000-4000-8000-000000000001"'::jsonb))->'reason_codes'),'["INVALID_UUID"]'::jsonb,'fail closed {entity_id} "A3000001-0000-4000-8000-000000000001"');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{as_of}','"2026-02-30T00:00:00.000000Z"'::jsonb))->'reason_codes'),'["INVALID_TIMESTAMP"]'::jsonb,'fail closed {as_of} "2026-02-30T00:00:00.000000Z"');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{as_of}','"2026-02-15T00:00:00Z"'::jsonb))->'reason_codes'),'["INVALID_TIMESTAMP"]'::jsonb,'fail closed {as_of} "2026-02-15T00:00:00Z"');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{as_of}','"infinity"'::jsonb))->'reason_codes'),'["NONFINITE_TIMESTAMP"]'::jsonb,'fail closed {as_of} "infinity"');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{source_origin}','"fixture"'::jsonb))->'reason_codes'),'["INVALID_ENUM"]'::jsonb,'fail closed {source_origin} "fixture"');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{synthetic_provider_revision}','"1"'::jsonb))->'reason_codes'),'["INVALID_FIELD_TYPE"]'::jsonb,'fail closed {synthetic_provider_revision} "1"');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{synthetic_provider_revision}','1.5'::jsonb))->'reason_codes'),'["INVALID_FIELD_TYPE"]'::jsonb,'fail closed {synthetic_provider_revision} 1.5');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{synthetic_provider_revision}','0'::jsonb))->'reason_codes'),'["INVALID_FIELD_TYPE"]'::jsonb,'fail closed {synthetic_provider_revision} 0');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{input_version}','"m3.input.v2"'::jsonb))->'reason_codes'),'["UNSUPPORTED_INPUT_VERSION"]'::jsonb,'fail closed {input_version} "m3.input.v2"');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{evaluator_version}','"m3.evaluator.v2"'::jsonb))->'reason_codes'),'["UNSUPPORTED_EVALUATOR_VERSION"]'::jsonb,'fail closed {evaluator_version} "m3.evaluator.v2"');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{calendar_rule_version}','"m3.baghdad_calendar.v2"'::jsonb))->'reason_codes'),'["UNSUPPORTED_CALENDAR_VERSION"]'::jsonb,'fail closed {calendar_rule_version} "m3.baghdad_calendar.v2"');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{model_eligibility,status}','"approved"'::jsonb))->'reason_codes'),'["INVALID_ENUM"]'::jsonb,'fail closed {model_eligibility,status} "approved"');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{model_eligibility,entity_id}','"a3000002-0000-4000-8000-000000000002"'::jsonb))->'reason_codes'),'["BINDING_MISMATCH"]'::jsonb,'fail closed {model_eligibility,entity_id} "a3000002-0000-4000-8000-000000000002"');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{model_eligibility,evidence_id}','null'::jsonb))->'reason_codes'),'["INVALID_FIELD_TYPE"]'::jsonb,'fail closed {model_eligibility,evidence_id} null');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{providers,eligibility,revision}','null'::jsonb))->'reason_codes'),'["INVALID_FIELD_TYPE"]'::jsonb,'fail closed {providers,eligibility,revision} null');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{providers,eligibility,revision}','-1'::jsonb))->'reason_codes'),'["INVALID_FIELD_TYPE"]'::jsonb,'fail closed {providers,eligibility,revision} -1');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{input_revision}','"0000000000000000000000000000000000000000000000000000000000000000"'::jsonb))->'reason_codes'),'["INPUT_REVISION_MISMATCH"]'::jsonb,'fail closed {input_revision} "0000000000000000000000000000000000000000000000000000000000000000"');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{catalog,0,registry_version}','2'::jsonb))->'reason_codes'),'["UNSUPPORTED_REGISTRY_VERSION"]'::jsonb,'fail closed {catalog,0,registry_version} 2');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{catalog,0,bundle_version}','2'::jsonb))->'reason_codes'),'["UNSUPPORTED_BUNDLE_VERSION"]'::jsonb,'fail closed {catalog,0,bundle_version} 2');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{catalog,0,plan_version}','2'::jsonb))->'reason_codes'),'["UNSUPPORTED_CATALOG_VERSION"]'::jsonb,'fail closed {catalog,0,plan_version} 2');
SELECT is((pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{terms,0,agreement_revision}','2'::jsonb),'input_revision'))->'reason_codes'),'["BINDING_MISMATCH"]'::jsonb,'fail closed {terms,0,agreement_revision} 2');
SELECT is((pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{catalog,0,items,0,is_required}','"true"'::jsonb))->'reason_codes'),'["INVALID_FIELD_TYPE"]'::jsonb,'fail closed {catalog,0,items,0,is_required} "true"');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()||'{"extra":1}'::jsonb)->'reason_codes','["UNKNOWN_FIELD"]'::jsonb,'unknown root never ignored');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{terms}',(pg_temp.m3_e_input()->'terms')||(pg_temp.m3_e_input()->'terms')),'input_revision'))->'reason_codes','["DUPLICATE_SOURCE_ID"]'::jsonb,'semantic multiplicity checked before hashes; ASCII path selects source duplicate');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{catalog,0,items}',(pg_temp.m3_e_input()#>'{catalog,0,items}')||(pg_temp.m3_e_input()#>'{catalog,0,items,4}')),'input_revision'))->'reason_codes','["DUPLICATE_CAPABILITY_KEY"]'::jsonb,'duplicate semantic capability cannot override');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{terms}','[]'),'input_revision'))->>'entitlement_outcome','NOT_ENTITLED','complete proven empty differs from unknown authority');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{providers,grants}','{"status":"UNAVAILABLE","revision":null,"source_origin":"test_fixture"}'),'input_revision'))->>'entitlement_outcome','UNKNOWN_FAIL_CLOSED','missing one canonical provider cannot grant');

SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{enforcement,context}','"WARNING"'::jsonb),'input_revision'))->>'entitlement_outcome','ENTITLED','WARNING preserves paid historical basis');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{enforcement,context}','"WARNING"'::jsonb),'input_revision'))#>>'{capabilities,branches.included,commercial_permission}','ALLOW','WARNING independent commercial permission');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{enforcement,context}','"SUSPENDED"'::jsonb),'input_revision'))->>'entitlement_outcome','ENTITLED','SUSPENDED preserves paid historical basis');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{enforcement,context}','"SUSPENDED"'::jsonb),'input_revision'))#>>'{capabilities,branches.included,commercial_permission}','DENY','SUSPENDED independent commercial permission');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{enforcement,context}','"TERMINATED"'::jsonb),'input_revision'))->>'entitlement_outcome','ENTITLED','TERMINATED preserves paid historical basis');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{enforcement,context}','"TERMINATED"'::jsonb),'input_revision'))#>>'{capabilities,branches.included,commercial_permission}','DENY','TERMINATED independent commercial permission');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{enforcement,context}','"CLOSED"'::jsonb),'input_revision'))->>'entitlement_outcome','ENTITLED','CLOSED preserves paid historical basis');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{enforcement,context}','"CLOSED"'::jsonb),'input_revision'))#>>'{capabilities,branches.included,commercial_permission}','DENY','CLOSED independent commercial permission');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{as_of}','"2026-01-31T00:00:00.000000Z"'::jsonb),'input_revision'),'2026-01-31T00:00:00.000000Z'::timestamptz)->>'basis_context','IN_EFFECT','half-open boundary 2026-01-31T00:00:00.000000Z');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{as_of}','"2026-02-28T00:00:00.000000Z"'::jsonb),'input_revision'),'2026-02-28T00:00:00.000000Z'::timestamptz)->>'basis_context','GRACE','half-open boundary 2026-02-28T00:00:00.000000Z');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{as_of}','"2026-03-04T23:59:59.999999Z"'::jsonb),'input_revision'),'2026-03-04T23:59:59.999999Z'::timestamptz)->>'basis_context','GRACE','half-open boundary 2026-03-04T23:59:59.999999Z');
SELECT is(pg_temp.m3_eval(pg_temp.m3_hash(jsonb_set(pg_temp.m3_e_input(),'{as_of}','"2026-03-05T00:00:00.000000Z"'::jsonb),'input_revision'),'2026-03-05T00:00:00.000000Z'::timestamptz)->>'basis_context','AFTER_GRACE','half-open boundary 2026-03-05T00:00:00.000000Z');
SELECT is((SELECT pg_temp.m3_pub(e,p-'envelope_kind')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member envelope_kind');
SELECT is((SELECT pg_temp.m3_pub(e,p-'input_version')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member input_version');
SELECT is((SELECT pg_temp.m3_pub(e,p-'evaluator_version')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member evaluator_version');
SELECT is((SELECT pg_temp.m3_pub(e,p-'calendar_rule_version')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member calendar_rule_version');
SELECT is((SELECT pg_temp.m3_pub(e,p-'entity_id')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member entity_id');
SELECT is((SELECT pg_temp.m3_pub(e,p-'source_origin')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member source_origin');
SELECT is((SELECT pg_temp.m3_pub(e,p-'as_of')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member as_of');
SELECT is((SELECT pg_temp.m3_pub(e,p-'synthetic_provider_revision')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member synthetic_provider_revision');
SELECT is((SELECT pg_temp.m3_pub(e,p-'entitlement_input_revision')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member entitlement_input_revision');
SELECT is((SELECT pg_temp.m3_pub(e,p-'entitlement_result_fingerprint')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member entitlement_result_fingerprint');
SELECT is((SELECT pg_temp.m3_pub(e,p-'publication_input_revision')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member publication_input_revision');
SELECT is((SELECT pg_temp.m3_pub(e,p-'legacy_visible')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member legacy_visible');
SELECT is((SELECT pg_temp.m3_pub(e,p-'scope')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member scope');
SELECT is((SELECT pg_temp.m3_pub(e,p-'content_revision')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member content_revision');
SELECT is((SELECT pg_temp.m3_pub(e,p-'required_fields')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member required_fields');
SELECT is((SELECT pg_temp.m3_pub(e,p-'onboarding')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member onboarding');
SELECT is((SELECT pg_temp.m3_pub(e,p-'moderation')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member moderation');
SELECT is((SELECT pg_temp.m3_pub(e,p-'verification_requirement')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member verification_requirement');
SELECT is((SELECT pg_temp.m3_pub(e,p-'verification_state')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member verification_state');
SELECT is((SELECT pg_temp.m3_pub(e,p-'verification')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member verification');
SELECT is((SELECT pg_temp.m3_pub(e,p-'enforcement')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member enforcement');
SELECT is((SELECT pg_temp.m3_pub(e,p-'launch')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member launch');
SELECT is((SELECT pg_temp.m3_pub(e,p-'projection')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member projection');
SELECT is((SELECT pg_temp.m3_pub(e,p-'prior_publication')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member prior_publication');
SELECT is((SELECT pg_temp.m3_pub(e,p-'authority_revision')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member authority_revision');
SELECT is((SELECT pg_temp.m3_pub(e,p-'projection_revision')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member projection_revision');
SELECT is((SELECT pg_temp.m3_pub(e,p-'authoritative_generation')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member authoritative_generation');
SELECT is((SELECT pg_temp.m3_pub(e,p-'candidate_generation')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required publication member candidate_generation');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{required_fields}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'publication_input_revision'))#>>'{gate_results,required_fields}' FROM m3_results,m3_publication),'BLOCKED_POLICY','required_fields exact OQ-84 blocks only its dimension');
SELECT ok((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{required_fields}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'publication_input_revision'))->'reason_codes' ? 'POLICY_DEPENDENCY_BLOCKED' FROM m3_results,m3_publication),'required_fields dependency retained as finite reason');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{required_fields}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{required_fields,policy_dependency}','null'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_FIELD_TYPE"]'::jsonb,'required_fields dependency null fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{required_fields}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{required_fields,policy_dependency}','"OQ-999"'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_ENUM"]'::jsonb,'required_fields dependency unsupported fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{required_fields}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{required_fields,policy_dependency}','"oq84"'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_ENUM"]'::jsonb,'required_fields dependency malformed fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(p,'{required_fields}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb)#-'{required_fields,policy_dependency}')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'required_fields omitted dependency fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(p,'{required_fields,policy_dependency}','"OQ-84"'))->'reason_codes' FROM m3_results,m3_publication),'["BINDING_MISMATCH"]'::jsonb,'required_fields PASS cannot carry blocked dependency');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{onboarding}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'publication_input_revision'))#>>'{gate_results,onboarding}' FROM m3_results,m3_publication),'BLOCKED_POLICY','onboarding exact OQ-84 blocks only its dimension');
SELECT ok((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{onboarding}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'publication_input_revision'))->'reason_codes' ? 'POLICY_DEPENDENCY_BLOCKED' FROM m3_results,m3_publication),'onboarding dependency retained as finite reason');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{onboarding}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{onboarding,policy_dependency}','null'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_FIELD_TYPE"]'::jsonb,'onboarding dependency null fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{onboarding}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{onboarding,policy_dependency}','"OQ-999"'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_ENUM"]'::jsonb,'onboarding dependency unsupported fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{onboarding}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{onboarding,policy_dependency}','"oq84"'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_ENUM"]'::jsonb,'onboarding dependency malformed fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(p,'{onboarding}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb)#-'{onboarding,policy_dependency}')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'onboarding omitted dependency fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(p,'{onboarding,policy_dependency}','"OQ-84"'))->'reason_codes' FROM m3_results,m3_publication),'["BINDING_MISMATCH"]'::jsonb,'onboarding PASS cannot carry blocked dependency');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{moderation}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'publication_input_revision'))#>>'{gate_results,moderation}' FROM m3_results,m3_publication),'BLOCKED_POLICY','moderation exact OQ-84 blocks only its dimension');
SELECT ok((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{moderation}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'publication_input_revision'))->'reason_codes' ? 'POLICY_DEPENDENCY_BLOCKED' FROM m3_results,m3_publication),'moderation dependency retained as finite reason');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{moderation}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{moderation,policy_dependency}','null'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_FIELD_TYPE"]'::jsonb,'moderation dependency null fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{moderation}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{moderation,policy_dependency}','"OQ-999"'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_ENUM"]'::jsonb,'moderation dependency unsupported fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{moderation}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{moderation,policy_dependency}','"oq84"'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_ENUM"]'::jsonb,'moderation dependency malformed fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(p,'{moderation}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb)#-'{moderation,policy_dependency}')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'moderation omitted dependency fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(p,'{moderation,policy_dependency}','"OQ-84"'))->'reason_codes' FROM m3_results,m3_publication),'["BINDING_MISMATCH"]'::jsonb,'moderation PASS cannot carry blocked dependency');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{verification}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'publication_input_revision'))#>>'{gate_results,verification}' FROM m3_results,m3_publication),'BLOCKED_POLICY','verification exact OQ-84 blocks only its dimension');
SELECT ok((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{verification}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'publication_input_revision'))->'reason_codes' ? 'POLICY_DEPENDENCY_BLOCKED' FROM m3_results,m3_publication),'verification dependency retained as finite reason');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{verification}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{verification,policy_dependency}','null'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_FIELD_TYPE"]'::jsonb,'verification dependency null fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{verification}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{verification,policy_dependency}','"OQ-999"'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_ENUM"]'::jsonb,'verification dependency unsupported fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{verification}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{verification,policy_dependency}','"oq84"'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_ENUM"]'::jsonb,'verification dependency malformed fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(p,'{verification}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb)#-'{verification,policy_dependency}')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'verification omitted dependency fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(p,'{verification,policy_dependency}','"OQ-84"'))->'reason_codes' FROM m3_results,m3_publication),'["BINDING_MISMATCH"]'::jsonb,'verification PASS cannot carry blocked dependency');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{launch}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'publication_input_revision'))#>>'{gate_results,launch}' FROM m3_results,m3_publication),'BLOCKED_POLICY','launch exact OQ-84 blocks only its dimension');
SELECT ok((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{launch}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'publication_input_revision'))->'reason_codes' ? 'POLICY_DEPENDENCY_BLOCKED' FROM m3_results,m3_publication),'launch dependency retained as finite reason');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{launch}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{launch,policy_dependency}','null'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_FIELD_TYPE"]'::jsonb,'launch dependency null fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{launch}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{launch,policy_dependency}','"OQ-999"'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_ENUM"]'::jsonb,'launch dependency unsupported fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{launch}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{launch,policy_dependency}','"oq84"'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_ENUM"]'::jsonb,'launch dependency malformed fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(p,'{launch}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb)#-'{launch,policy_dependency}')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'launch omitted dependency fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(p,'{launch,policy_dependency}','"OQ-84"'))->'reason_codes' FROM m3_results,m3_publication),'["BINDING_MISMATCH"]'::jsonb,'launch PASS cannot carry blocked dependency');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{projection,approval}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'publication_input_revision'))#>>'{gate_results,projection}' FROM m3_results,m3_publication),'BLOCKED_POLICY','projection,approval exact OQ-84 blocks only its dimension');
SELECT ok((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{projection,approval}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'publication_input_revision'))->'reason_codes' ? 'POLICY_DEPENDENCY_BLOCKED' FROM m3_results,m3_publication),'projection,approval dependency retained as finite reason');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{projection,approval}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{projection,approval,policy_dependency}','null'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_FIELD_TYPE"]'::jsonb,'projection,approval dependency null fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{projection,approval}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{projection,approval,policy_dependency}','"OQ-999"'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_ENUM"]'::jsonb,'projection,approval dependency unsupported fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{projection,approval}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{projection,approval,policy_dependency}','"oq84"'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_ENUM"]'::jsonb,'projection,approval dependency malformed fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(p,'{projection,approval}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb)#-'{projection,approval,policy_dependency}')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'projection,approval omitted dependency fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(p,'{projection,approval,policy_dependency}','"OQ-84"'))->'reason_codes' FROM m3_results,m3_publication),'["BINDING_MISMATCH"]'::jsonb,'projection,approval PASS cannot carry blocked dependency');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{projection,conformance}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'publication_input_revision'))#>>'{gate_results,projection}' FROM m3_results,m3_publication),'BLOCKED_POLICY','projection,conformance exact OQ-84 blocks only its dimension');
SELECT ok((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{projection,conformance}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'publication_input_revision'))->'reason_codes' ? 'POLICY_DEPENDENCY_BLOCKED' FROM m3_results,m3_publication),'projection,conformance dependency retained as finite reason');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{projection,conformance}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{projection,conformance,policy_dependency}','null'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_FIELD_TYPE"]'::jsonb,'projection,conformance dependency null fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{projection,conformance}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{projection,conformance,policy_dependency}','"OQ-999"'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_ENUM"]'::jsonb,'projection,conformance dependency unsupported fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(jsonb_set(p,'{projection,conformance}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb),'{projection,conformance,policy_dependency}','"oq84"'::jsonb))->'reason_codes' FROM m3_results,m3_publication),'["INVALID_ENUM"]'::jsonb,'projection,conformance dependency malformed fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(p,'{projection,conformance}',jsonb_set(jsonb_set(pg_temp.m3_gate(),'{status}','"BLOCKED_POLICY"'),'{evidence_id}','null')||'{"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'::jsonb)#-'{projection,conformance,policy_dependency}')->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'projection,conformance omitted dependency fails closed');
SELECT is((SELECT pg_temp.m3_pub(e,jsonb_set(p,'{projection,conformance,policy_dependency}','"OQ-84"'))->'reason_codes' FROM m3_results,m3_publication),'["BINDING_MISMATCH"]'::jsonb,'projection,conformance PASS cannot carry blocked dependency');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{candidate_generation}','6')||jsonb_build_object('projection',jsonb_set(p->'projection','{candidate_generation}','6')),'publication_input_revision'))->>'mismatch_category' FROM m3_results,m3_publication),'STALE_GENERATION','delayed G0 result cannot match G1');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{projection,public_field_paths}','["payment.amount"]'),'publication_input_revision'))->>'discoverability_outcome' FROM m3_results,m3_publication),'DENY','unsafe private recursive path denies');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(jsonb_set(p,'{verification_requirement}','"REQUIRED"'),'{verification,content_revision}','17'),'publication_input_revision'))->>'discoverability_outcome' FROM m3_results,m3_publication),'DENY','paid unverified cannot pass REQUIRED verification');
SELECT ok(commercial_private.m3_generation_matches_v1(9,9,7,7),'equal nonnegative pairs match');
SELECT ok(commercial_private.m3_generation_matches_v1(0,0,0,0),'zero pairs are predicate values only');
SELECT ok(NOT commercial_private.m3_generation_matches_v1(9,8,7,7),'revision mismatch');
SELECT ok(NOT commercial_private.m3_generation_matches_v1(9,9,7,6),'generation mismatch');
SELECT ok(NOT commercial_private.m3_generation_matches_v1(NULL,9,7,7),'null generation evidence false');
SELECT ok(NOT commercial_private.m3_generation_matches_v1(-1,-1,7,7),'negative generation evidence false');

SELECT ok(NOT has_function_privilege('anon','commercial_private.m3_evaluate_entitlement_v1(jsonb,timestamptz)','EXECUTE'),'anon cannot execute m3_evaluate_entitlement_v1(jsonb,timestamptz)');
SELECT ok(NOT has_function_privilege('anon','commercial_private.m3_evaluate_publication_v1(jsonb,jsonb,timestamptz)','EXECUTE'),'anon cannot execute m3_evaluate_publication_v1(jsonb,jsonb,timestamptz)');
SELECT ok(NOT has_function_privilege('anon','commercial_private.m3_generation_matches_v1(bigint,bigint,bigint,bigint)','EXECUTE'),'anon cannot execute m3_generation_matches_v1(bigint,bigint,bigint,bigint)');
SELECT ok(NOT has_function_privilege('anon','commercial_private.m3_capture_shadow_v1(uuid,uuid,bigint)','EXECUTE'),'anon cannot execute m3_capture_shadow_v1(uuid,uuid,bigint)');
SELECT ok(NOT has_table_privilege('anon','commercial_private.m3_shadow_heads','SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'),'anon has no table access m3_shadow_heads');
SELECT ok(NOT has_table_privilege('anon','commercial_private.m3_shadow_runs','SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'),'anon has no table access m3_shadow_runs');
SELECT ok(NOT has_schema_privilege('anon','commercial_private','USAGE,CREATE'),'anon cannot traverse private schema');
SELECT ok(NOT has_function_privilege('authenticated','commercial_private.m3_evaluate_entitlement_v1(jsonb,timestamptz)','EXECUTE'),'authenticated cannot execute m3_evaluate_entitlement_v1(jsonb,timestamptz)');
SELECT ok(NOT has_function_privilege('authenticated','commercial_private.m3_evaluate_publication_v1(jsonb,jsonb,timestamptz)','EXECUTE'),'authenticated cannot execute m3_evaluate_publication_v1(jsonb,jsonb,timestamptz)');
SELECT ok(NOT has_function_privilege('authenticated','commercial_private.m3_generation_matches_v1(bigint,bigint,bigint,bigint)','EXECUTE'),'authenticated cannot execute m3_generation_matches_v1(bigint,bigint,bigint,bigint)');
SELECT ok(NOT has_function_privilege('authenticated','commercial_private.m3_capture_shadow_v1(uuid,uuid,bigint)','EXECUTE'),'authenticated cannot execute m3_capture_shadow_v1(uuid,uuid,bigint)');
SELECT ok(NOT has_table_privilege('authenticated','commercial_private.m3_shadow_heads','SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'),'authenticated has no table access m3_shadow_heads');
SELECT ok(NOT has_table_privilege('authenticated','commercial_private.m3_shadow_runs','SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'),'authenticated has no table access m3_shadow_runs');
SELECT ok(NOT has_schema_privilege('authenticated','commercial_private','USAGE,CREATE'),'authenticated cannot traverse private schema');
SELECT ok(NOT has_function_privilege('service_role','commercial_private.m3_evaluate_entitlement_v1(jsonb,timestamptz)','EXECUTE'),'service_role cannot execute m3_evaluate_entitlement_v1(jsonb,timestamptz)');
SELECT ok(NOT has_function_privilege('service_role','commercial_private.m3_evaluate_publication_v1(jsonb,jsonb,timestamptz)','EXECUTE'),'service_role cannot execute m3_evaluate_publication_v1(jsonb,jsonb,timestamptz)');
SELECT ok(NOT has_function_privilege('service_role','commercial_private.m3_generation_matches_v1(bigint,bigint,bigint,bigint)','EXECUTE'),'service_role cannot execute m3_generation_matches_v1(bigint,bigint,bigint,bigint)');
SELECT ok(NOT has_function_privilege('service_role','commercial_private.m3_capture_shadow_v1(uuid,uuid,bigint)','EXECUTE'),'service_role cannot execute m3_capture_shadow_v1(uuid,uuid,bigint)');
SELECT ok(NOT has_table_privilege('service_role','commercial_private.m3_shadow_heads','SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'),'service_role has no table access m3_shadow_heads');
SELECT ok(NOT has_table_privilege('service_role','commercial_private.m3_shadow_runs','SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'),'service_role has no table access m3_shadow_runs');
SELECT ok(NOT has_schema_privilege('service_role','commercial_private','USAGE,CREATE'),'service_role cannot traverse private schema');

CREATE FUNCTION pg_temp.m3_refresh(j jsonb) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE c jsonb; a jsonb:='[]';
BEGIN
 FOR c IN SELECT value FROM jsonb_array_elements(j->'catalog') LOOP a:=a||jsonb_build_array(pg_temp.m3_hash(c,'snapshot_revision')); END LOOP;
 RETURN pg_temp.m3_hash(jsonb_set(j,'{catalog}',a),'input_revision');
END $$;
CREATE FUNCTION pg_temp.m3_family(n integer) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE j jsonb:=pg_temp.m3_e_input(); c jsonb; t jsonb;items jsonb;item jsonb;family text;pv text;bv text;
BEGIN
 family:=CASE n WHEN 2 THEN 'business_pro' WHEN 3 THEN 'business_plus' ELSE 'corporate' END;
 pv:=format('4c7b000%s-0000-4000-8000-00000000000%s',n,n);bv:=format('2e7b000%s-0000-4000-8000-00000000000%s',n,n);
 c:=j#>'{catalog,0}';t:=j#>'{terms,0}';items:='[]';
 FOR item IN SELECT value FROM jsonb_array_elements(c->'items') LOOP
 IF item->>'capability_key'='branches.included' THEN item:=jsonb_set(item,'{value_integer}',to_jsonb(LEAST(n,3))); END IF;
 IF item->>'capability_key'='sponsored.purchase_eligible' THEN
 IF n=4 THEN CONTINUE; END IF; item:=jsonb_set(item,'{value_boolean}','true');
 END IF;
 items:=items||jsonb_build_array(item);
 END LOOP;
 c:=c||jsonb_build_object('family',family,'plan_id',format('1a7b000%s-0000-4000-8000-00000000000%s',n,n),'plan_version_id',pv,'bundle_version_id',bv,'items',items);
 t:=t||jsonb_build_object('plan_version_id',pv,'bundle_version_id',bv);
 IF n=4 THEN
 c:=jsonb_set(c,'{pricing_mode}','"custom_quote"'); t:=t||'{"duration_months":12,"original_end":"2027-01-31T00:00:00.000000Z","effective_end":"2027-01-31T00:00:00.000000Z"}';
 t:=jsonb_set(t,'{authorization}',t->'authorization'||'{"kind":"CORPORATE_WRITTEN","quote_id":"a3000020-0000-4000-8000-000000000020","quote_valid_from":"2026-01-01T00:00:00.000000Z","quote_valid_until":"2026-01-31T00:00:00.000000Z","quote_accepted_at":"2026-01-10T00:00:00.000000Z","commitment_months":12}');
 END IF;
 RETURN pg_temp.m3_refresh(jsonb_set(jsonb_set(j,'{catalog}',jsonb_build_array(c)),'{terms}',jsonb_build_array(t)));
END $$;
CREATE FUNCTION pg_temp.m3_a8() RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE j jsonb:=pg_temp.m3_family(2);
BEGIN
 j:=jsonb_set(j,'{terms}','[]'); j:=jsonb_set(j,'{agreement}','null');
 j:=jsonb_set(j,'{grants}','[{
 "grant_id":"a3000030-0000-4000-8000-000000000030","source_id":"a3000031-0000-4000-8000-000000000031",
 "entity_id":"a3000001-0000-4000-8000-000000000001","program_id":"a3000032-0000-4000-8000-000000000032","program_version":1,
 "program_approval_evidence_id":"a3000033-0000-4000-8000-000000000033","grant_approval_evidence_id":"a3000034-0000-4000-8000-000000000034","once_per_entity_evidence_id":"a3000035-0000-4000-8000-000000000035",
 "plan_version_id":"4c7b0002-0000-4000-8000-000000000002","bundle_version_id":"2e7b0002-0000-4000-8000-000000000002","selected_at":"2026-01-20T00:00:00.000000Z",
 "formal_launch_event_id":"a3000036-0000-4000-8000-000000000036","formal_launch_at":"2026-01-25T00:00:00.000000Z",
 "first_post_launch_publication_event_id":"a3000037-0000-4000-8000-000000000037","first_post_launch_publication_at":"2026-01-31T00:00:00.000000Z",
 "start_at":"2026-01-31T00:00:00.000000Z","end_at":"2026-04-01T00:00:00.000000Z","exception_dependency":null
 }]');
 RETURN pg_temp.m3_refresh(j);
END $$;
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{model_eligibility,status}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested model_eligibility.status');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{model_eligibility,entity_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested model_eligibility.entity_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{model_eligibility,evidence_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested model_eligibility.evidence_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{model_eligibility,revision}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested model_eligibility.revision');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{model_eligibility,decided_at}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested model_eligibility.decided_at');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{model_eligibility,content_revision}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested model_eligibility.content_revision');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{model_eligibility,requirements_revision}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested model_eligibility.requirements_revision');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{model_eligibility,scope_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested model_eligibility.scope_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{model_eligibility,policy_dependency}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested model_eligibility.policy_dependency');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,plan_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.plan_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,family}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.family');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,plan_version_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.plan_version_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,plan_version}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.plan_version');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,pricing_mode}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.pricing_mode');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,plan_status}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.plan_status');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,plan_published_at}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.plan_published_at');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,plan_retired_at}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.plan_retired_at');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,bundle_version_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.bundle_version_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,bundle_version}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.bundle_version');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,registry_version}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.registry_version');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,bundle_status}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.bundle_status');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,bundle_published_at}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.bundle_published_at');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,bundle_retired_at}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.bundle_retired_at');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,approval_evidence_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.approval_evidence_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,approved_at}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.approved_at');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,snapshot_revision}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.snapshot_revision');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,items}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0.items');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,term_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.term_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,source_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.source_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,agreement_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.agreement_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,agreement_revision}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.agreement_revision');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,plan_version_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.plan_version_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,bundle_version_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.bundle_version_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,purpose}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.purpose');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,predecessor_term_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.predecessor_term_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,duration_months}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.duration_months');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,purchased_at}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.purchased_at');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,authorization}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.authorization');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,anchor_rule}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.anchor_rule');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,anchor}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.anchor');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,original_end}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.original_end');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,effective_end}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.effective_end');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,extensions}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0.extensions');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,authorization,kind}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,authorization.kind');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,authorization,state}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,authorization.state');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,authorization,evidence_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,authorization.evidence_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,authorization,decided_at}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,authorization.decided_at');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,authorization,quote_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,authorization.quote_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,authorization,quote_valid_from}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,authorization.quote_valid_from');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,authorization,quote_valid_until}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,authorization.quote_valid_until');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,authorization,quote_accepted_at}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,authorization.quote_accepted_at');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,authorization,commitment_months}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,authorization.commitment_months');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,authorization,payment_condition}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,authorization.payment_condition');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,anchor,anchor_event_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,anchor.anchor_event_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,anchor,entity_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,anchor.entity_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,anchor,effective_at}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,anchor.effective_at');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,anchor,recorded_at}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,anchor.recorded_at');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,anchor,publication_event_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,anchor.publication_event_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,anchor,requests_evidence_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,anchor.requests_evidence_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,anchor,delay_evidence_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,anchor.delay_evidence_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{terms,0,anchor,cause_at_deadline}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested terms,0,anchor.cause_at_deadline');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{agreement,agreement_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested agreement.agreement_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{agreement,entity_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested agreement.entity_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{agreement,revision}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested agreement.revision');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{agreement,approval_state}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested agreement.approval_state');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{agreement,approval_evidence_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested agreement.approval_evidence_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{agreement,approved_at}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested agreement.approved_at');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{enforcement,context}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested enforcement.context');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{enforcement,entity_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested enforcement.entity_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{enforcement,evidence_id}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested enforcement.evidence_id');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{enforcement,revision}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested enforcement.revision');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{enforcement,effective_at}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested enforcement.effective_at');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{providers,eligibility,status}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested providers,eligibility.status');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{providers,eligibility,revision}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested providers,eligibility.revision');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{providers,eligibility,source_origin}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested providers,eligibility.source_origin');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,items,0,capability_key}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0,items,0.capability_key');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,items,0,value_kind}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0,items,0.value_kind');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,items,0,value_boolean}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0,items,0.value_boolean');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,items,0,value_integer}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0,items,0.value_integer');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,items,0,value_text}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0,items,0.value_text');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()#-'{catalog,0,items,0,is_required}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'closed nested catalog,0,items,0.is_required');
SELECT is((SELECT pg_temp.m3_pub(e-'envelope_kind',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member envelope_kind');
SELECT is((SELECT pg_temp.m3_pub(e-'input_version',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member input_version');
SELECT is((SELECT pg_temp.m3_pub(e-'evaluator_version',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member evaluator_version');
SELECT is((SELECT pg_temp.m3_pub(e-'calendar_rule_version',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member calendar_rule_version');
SELECT is((SELECT pg_temp.m3_pub(e-'entity_id',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member entity_id');
SELECT is((SELECT pg_temp.m3_pub(e-'source_origin',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member source_origin');
SELECT is((SELECT pg_temp.m3_pub(e-'as_of',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member as_of');
SELECT is((SELECT pg_temp.m3_pub(e-'input_revision',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member input_revision');
SELECT is((SELECT pg_temp.m3_pub(e-'synthetic_provider_revision',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member synthetic_provider_revision');
SELECT is((SELECT pg_temp.m3_pub(e-'authority_outcome',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member authority_outcome');
SELECT is((SELECT pg_temp.m3_pub(e-'basis_context',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member basis_context');
SELECT is((SELECT pg_temp.m3_pub(e-'source_kind',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member source_kind');
SELECT is((SELECT pg_temp.m3_pub(e-'entitlement_outcome',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member entitlement_outcome');
SELECT is((SELECT pg_temp.m3_pub(e-'enforcement_context',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member enforcement_context');
SELECT is((SELECT pg_temp.m3_pub(e-'enforcement_revision',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member enforcement_revision');
SELECT is((SELECT pg_temp.m3_pub(e-'continuity_eligible',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member continuity_eligible');
SELECT is((SELECT pg_temp.m3_pub(e-'agreement_id',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member agreement_id');
SELECT is((SELECT pg_temp.m3_pub(e-'term_id',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member term_id');
SELECT is((SELECT pg_temp.m3_pub(e-'grant_id',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member grant_id');
SELECT is((SELECT pg_temp.m3_pub(e-'plan_id',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member plan_id');
SELECT is((SELECT pg_temp.m3_pub(e-'plan_version_id',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member plan_version_id');
SELECT is((SELECT pg_temp.m3_pub(e-'plan_version',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member plan_version');
SELECT is((SELECT pg_temp.m3_pub(e-'bundle_version_id',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member bundle_version_id');
SELECT is((SELECT pg_temp.m3_pub(e-'bundle_version',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member bundle_version');
SELECT is((SELECT pg_temp.m3_pub(e-'registry_version',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member registry_version');
SELECT is((SELECT pg_temp.m3_pub(e-'snapshot_revision',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member snapshot_revision');
SELECT is((SELECT pg_temp.m3_pub(e-'original_start',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member original_start');
SELECT is((SELECT pg_temp.m3_pub(e-'original_end',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member original_end');
SELECT is((SELECT pg_temp.m3_pub(e-'effective_end',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member effective_end');
SELECT is((SELECT pg_temp.m3_pub(e-'grace_end',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member grace_end');
SELECT is((SELECT pg_temp.m3_pub(e-'prior_publication_event_id',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member prior_publication_event_id');
SELECT is((SELECT pg_temp.m3_pub(e-'capabilities',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member capabilities');
SELECT is((SELECT pg_temp.m3_pub(e-'next_boundary',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member next_boundary');
SELECT is((SELECT pg_temp.m3_pub(e-'reason_codes',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member reason_codes');
SELECT is((SELECT pg_temp.m3_pub(e-'result_fingerprint',p)->'reason_codes' FROM m3_results,m3_publication),'["MISSING_REQUIRED_FIELD"]'::jsonb,'bound result required member result_fingerprint');
SELECT is(pg_temp.m3_eval(pg_temp.m3_family(2))#>>'{capabilities,branches.included,value}','2','Pro literal two branches');
SELECT is(pg_temp.m3_eval(pg_temp.m3_family(3))#>>'{capabilities,branches.included,value}','3','Plus literal three branches');
SELECT is(pg_temp.m3_eval(pg_temp.m3_family(4))->>'entitlement_outcome','ENTITLED','Corporate written annual quote without retail-price row');
SELECT is(pg_temp.m3_eval(pg_temp.m3_family(4))#>>'{capabilities,branches.included,value}','3','Corporate Plus branch floor');
SELECT is(pg_temp.m3_eval(pg_temp.m3_family(4))#>>'{capabilities,sponsored.purchase_eligible,commercial_permission}','DENY','Corporate absent Sponsored cannot infer eligibility');
SELECT ok(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(pg_temp.m3_family(4),'{terms,0,duration_months}','11')))->'reason_codes' ? 'CORPORATE_TERMS_INVALID','Corporate subannual commitment rejected');
SELECT ok(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(pg_temp.m3_family(4),'{terms,0,authorization,quote_accepted_at}','"2026-01-31T00:00:00.000000Z"')))->'reason_codes' ? 'CORPORATE_TERMS_INVALID','quote validity end is exclusive');
SELECT is(pg_temp.m3_eval(pg_temp.m3_a8())->>'entitlement_outcome','ENTITLED','formal launch plus first post-launch publication creates fixture A8 basis');
SELECT is(pg_temp.m3_eval(pg_temp.m3_a8())->>'effective_end','2026-04-01T00:00:00.000000Z','A8 sixty Baghdad calendar days');
SELECT ok(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(pg_temp.m3_a8(),'{grants,0,first_post_launch_publication_at}','"2026-01-24T00:00:00.000000Z"')))->'reason_codes' ? 'ANCHOR_CONFLICT','prelaunch publication cannot anchor A8');
SELECT is(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(pg_temp.m3_a8(),'{grants,0}',(pg_temp.m3_a8()#>'{grants,0}')||'{"first_post_launch_publication_event_id":null,"first_post_launch_publication_at":null,"start_at":null,"end_at":null}')))->>'basis_context','PENDING_ANCHOR','A8 reservation has no invented start');
SELECT is(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(pg_temp.m3_a8(),'{grants,0,program_version}','2')))->'reason_codes','["UNSUPPORTED_PROGRAM_VERSION"]'::jsonb,'unsupported A8 program never substituted');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()||'{"foundingPartner":true}')->'reason_codes','["UNKNOWN_FIELD"]'::jsonb,'Founding badge cannot become a free grant input');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()||'{"PlanTier":"plus"}')->'reason_codes','["UNKNOWN_FIELD"]'::jsonb,'legacy PlanTier cannot become authority');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()||'{"lifecycle_status":"active"}')->'reason_codes','["UNKNOWN_FIELD"]'::jsonb,'active lifecycle cannot become entitlement authority');
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()||jsonb_build_object('padding',repeat('x',65536)))->'reason_codes','["INPUT_BOUND_EXCEEDED"]'::jsonb,'size bound precedes unknown field');
SELECT is(pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{terms}',(SELECT jsonb_agg(pg_temp.m3_e_input()#>'{terms,0}') FROM generate_series(1,33))))->'reason_codes','["INPUT_BOUND_EXCEEDED"]'::jsonb,'terms cardinality precedes duplicates');
SELECT is(pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{catalog,0,items}',jsonb_build_array(pg_temp.m3_e_input()#>'{catalog,0,items,4}',pg_temp.m3_e_input()#>'{catalog,0,items,0}')))->'reason_codes','["INVALID_ENVELOPE"]'::jsonb,'array order is mandatory');
SELECT is(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(pg_temp.m3_e_input(),'{catalog,0,items}',(pg_temp.m3_e_input()#>'{catalog,0,items}')||'[{"capability_key":"z.optional","value_kind":"boolean","value_boolean":true,"value_integer":null,"value_text":null,"is_required":false}]')))->>'entitlement_outcome','ENTITLED','unknown optional capability grants no extra feature');
SELECT is(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(pg_temp.m3_e_input(),'{catalog,0,items}',(pg_temp.m3_e_input()#>'{catalog,0,items}')||'[{"capability_key":"z.required","value_kind":"boolean","value_boolean":true,"value_integer":null,"value_text":null,"is_required":true}]')))->>'authority_outcome','UNSUPPORTED_VERSION','unknown required capability cannot be ignored');
SELECT is(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(jsonb_set(jsonb_set(pg_temp.m3_e_input(),'{terms,0,anchor}','null'),'{terms,0,original_end}','null'),'{terms,0,effective_end}','null')))->>'entitlement_outcome','NOT_ENTITLED','pending paid basis does not grant capabilities');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{projection,format_version}','"m3.public_descriptor.v2"'),'publication_input_revision'))->'reason_codes' FROM m3_results,m3_publication),'["UNSUPPORTED_PROJECTION_FORMAT"]'::jsonb,'unknown projection version exact closed token');
SELECT ok(NOT jsonb_path_exists('{"approved_name":"safe","public_contacts":[]}'::jsonb,'$.**.payment'),'hand-authored public-safe content has no recursive payment field');
SELECT ok(jsonb_path_exists('{"public_contacts":[{"metadata":{"payment":{"amount":1}}}]}'::jsonb,'$.**.payment'),'nested unsafe content detected independently of descriptor manifest');



-- Hand-authored chain, extension and Grace vectors.
CREATE TEMP TABLE m3_pending AS SELECT pg_temp.m3_refresh(jsonb_set(jsonb_set(jsonb_set(pg_temp.m3_e_input(),'{terms,0,anchor}','null'),'{terms,0,original_end}','null'),'{terms,0,effective_end}','null')) AS j;
SELECT is((SELECT pg_temp.m3_eval(j)->>'basis_context' FROM m3_pending),'PENDING_ANCHOR','approved unanchored paid basis stays pending');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(pg_temp.m3_p_input(e),'{projection,kind}','"CANDIDATE"'),'publication_input_revision'))->>'candidate_first_publication_ready' FROM (SELECT pg_temp.m3_eval(j) e FROM m3_pending) t),'true','pending basis can be candidate-ready only');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(pg_temp.m3_p_input(e),'{projection,kind}','"CANDIDATE"'),'publication_input_revision'))->>'discoverability_outcome' FROM (SELECT pg_temp.m3_eval(j) e FROM m3_pending) t),'DENY','candidate ready is not published');
CREATE TEMP TABLE m3_grace AS SELECT pg_temp.m3_refresh(pg_temp.m3_e_input()||'{"as_of":"2026-03-01T00:00:00.000000Z","prior_publication":{"publication_event_id":"a3000040-0000-4000-8000-000000000040","entity_id":"a3000001-0000-4000-8000-000000000001","source_kind":"PAID_TERM","source_id":"a3000004-0000-4000-8000-000000000004","content_revision":17,"available_at":"2026-02-01T00:00:00.000000Z"}}') j;
SELECT is((SELECT pg_temp.m3_eval(j,'2026-03-01T00:00:00Z')->>'continuity_eligible' FROM m3_grace),'true','Grace requires attributable prior publication');
SELECT is((SELECT pg_temp.m3_eval(j,'2026-03-01T00:00:00Z')->>'entitlement_outcome' FROM m3_grace),'NOT_ENTITLED','Grace does not renew entitlement');
SELECT is((SELECT pg_temp.m3_eval(j,'2026-03-01T00:00:00Z')#>>'{capabilities,branches.included,commercial_permission}' FROM m3_grace),'DENY','Grace cannot grant commercial capabilities');
SELECT is((SELECT pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(j,'{enforcement,context}','"SUSPENDED"')),'2026-03-01T00:00:00Z')->>'continuity_eligible' FROM m3_grace),'false','enforcement denial overrides Grace continuity');
CREATE TEMP TABLE m3_renewal AS
SELECT pg_temp.m3_refresh(jsonb_set(j,'{prior_publication}','null')||jsonb_build_object('terms',(j->'terms')||jsonb_build_array((j#>'{terms,0}')||'{
 "term_id":"a3000041-0000-4000-8000-000000000041","source_id":"a3000042-0000-4000-8000-000000000042","purpose":"RENEWAL","predecessor_term_id":"a3000004-0000-4000-8000-000000000004",
 "purchased_at":"2026-02-27T00:00:00.000000Z","anchor_rule":"RENEWAL_BOUNDARY",
 "anchor":{"anchor_event_id":"a3000043-0000-4000-8000-000000000043","entity_id":"a3000001-0000-4000-8000-000000000001","effective_at":"2026-02-28T00:00:00.000000Z","recorded_at":"2026-02-27T00:00:00.000000Z","publication_event_id":null,"requests_evidence_id":null,"delay_evidence_id":null,"cause_at_deadline":null},
 "original_end":"2026-03-28T00:00:00.000000Z","effective_end":"2026-03-28T00:00:00.000000Z"
 }'::jsonb))) j FROM m3_grace;
SELECT is((SELECT pg_temp.m3_eval(j,'2026-03-01T00:00:00Z')->>'term_id' FROM m3_renewal),'a3000041-0000-4000-8000-000000000041','renewal starts at predecessor boundary without reset');
SELECT is((SELECT pg_temp.m3_eval(j,'2026-03-01T00:00:00Z')->>'entitlement_outcome' FROM m3_renewal),'ENTITLED','validated renewal interval entitled');
SELECT ok((SELECT pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(j,'{terms,1,predecessor_term_id}','"a3000099-0000-4000-8000-000000000099"')),'2026-03-01T00:00:00Z')->'reason_codes' ? 'INVALID_TERM_CHAIN' FROM m3_renewal),'absent predecessor cannot be substituted');
SELECT ok((SELECT pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(j,'{terms,1,anchor,effective_at}','"2026-02-27T00:00:00.000000Z"')),'2026-03-01T00:00:00Z')->'reason_codes' ? 'OVERLAPPING_BASIS' FROM m3_renewal),'overlap never picks a higher tier or newest term');
CREATE TEMP TABLE m3_extension AS SELECT pg_temp.m3_refresh(jsonb_set(jsonb_set(pg_temp.m3_e_input(),'{terms,0,effective_end}','"2026-03-02T00:00:00.000000Z"'),'{terms,0,extensions}','[
 {"extension_id":"a3000044-0000-4000-8000-000000000044","term_id":"a3000004-0000-4000-8000-000000000004","revision":1,"evidence_id":"a3000002-0000-4000-8000-000000000002","recorded_at":"2026-02-10T00:00:00.000000Z","effective_end":"2026-03-02T00:00:00.000000Z"}]')) j;
SELECT is((SELECT pg_temp.m3_eval(j)->>'original_end' FROM m3_extension),'2026-02-28T00:00:00.000000Z','extension preserves original term end');
SELECT is((SELECT pg_temp.m3_eval(j)->>'effective_end' FROM m3_extension),'2026-03-02T00:00:00.000000Z','approved extension advances effective end');
SELECT ok((SELECT pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(j,'{terms,0,extensions,0,revision}','2')))->'reason_codes' ? 'INVALID_TERM_CHAIN' FROM m3_extension),'extension revision must be contiguous from one');
SELECT ok((SELECT pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(j,'{terms,0,extensions,0,effective_end}','"2026-02-28T00:00:00.000000Z"')))->'reason_codes' ? 'INVALID_TERM_CHAIN' FROM m3_extension),'non-increasing extension cannot renew history');
SELECT is(pg_temp.m3_eval(jsonb_set(pg_temp.m3_e_input(),'{model_eligibility,content_revision}','17'))->'reason_codes','["BINDING_MISMATCH"]'::jsonb,'non-content eligibility cannot borrow content authority');
SELECT is(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(pg_temp.m3_e_input(),'{agreement,approved_at}','"2026-02-16T00:00:00.000000Z"')))->'reason_codes','["BINDING_MISMATCH"]'::jsonb,'future agreement approval cannot bind');
SELECT is(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(jsonb_set(pg_temp.m3_e_input(),'{catalog,0,plan_status}','"RETIRED"'),'{catalog,0,plan_retired_at}','"2025-12-31T00:00:00.000000Z"')))->'reason_codes','["BINDING_MISMATCH"]'::jsonb,'retirement cannot precede publication');
SELECT is((SELECT pg_temp.m3_pub(e,pg_temp.m3_hash(p||jsonb_build_object('required_fields',jsonb_set(p->'required_fields','{status}','"FAIL"'),'launch',pg_temp.m3_gate()||'{"status":"BLOCKED_POLICY","evidence_id":null,"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'),'publication_input_revision'))->>'discoverability_outcome' FROM m3_results,m3_publication),'DENY','known failure dominates an unresolved policy dependency');
CREATE TEMP TABLE m3_original_result AS SELECT e AS original FROM m3_results;
SET LOCAL TimeZone='America/New_York';
SET LOCAL DateStyle='SQL, DMY';
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input()),(SELECT original FROM m3_original_result),'kernel normalized result independent of session timezone and DateStyle');
SET LOCAL TimeZone='UTC';
SET LOCAL DateStyle='ISO, MDY';


-- Correction pass: independent contract oracles for M1/M2/M3/M4 and LOW-1.
CREATE TEMP TABLE m3_activation_cases AS
SELECT label,expected_authority,expected_entitlement,pg_temp.m3_refresh(jsonb_set(pg_temp.m3_e_input(),
 '{terms,0,authorization,payment_condition,decided_at}',to_jsonb(approval_time))) j
FROM (VALUES
 ('publication before activation','2026-02-10T00:00:00.000000Z','CONFLICTING_AUTHORITY','UNKNOWN_FAIL_CLOSED'),
 ('publication at activation','2026-01-31T00:00:00.000000Z','COMPLETE','ENTITLED'),
 ('publication after activation','2026-01-30T23:59:59.999999Z','COMPLETE','ENTITLED')
) v(label,approval_time,expected_authority,expected_entitlement);
SELECT is(pg_temp.m3_eval(j)->>'authority_outcome',expected_authority,label||' authority') FROM m3_activation_cases ORDER BY label;
SELECT is(pg_temp.m3_eval(j)->>'entitlement_outcome',expected_entitlement,label||' entitlement') FROM m3_activation_cases ORDER BY label;
SELECT ok(pg_temp.m3_eval(j)->'reason_codes' ? 'ANCHOR_CONFLICT','late activation has exact anchor conflict') FROM m3_activation_cases WHERE label='publication before activation';
SELECT isnt(pg_temp.m3_pub(e,pg_temp.m3_p_input(e))->>'discoverability_outcome','ALLOW','invalid chronology cannot publish')
FROM (SELECT pg_temp.m3_eval(j) e FROM m3_activation_cases WHERE label='publication before activation') x;
SELECT is(pg_temp.m3_eval(j)->>'original_start','2026-01-31T00:00:00.000000Z','activation approval never rewrites paid publication start') FROM m3_activation_cases WHERE label='publication after activation';
CREATE TEMP TABLE m3_reactivation_cases AS
SELECT label,expected,pg_temp.m3_refresh(jsonb_set(pg_temp.m3_e_input()||'{"as_of":"2026-03-15T00:00:00.000000Z"}',
 '{terms}',(pg_temp.m3_e_input()->'terms')||jsonb_build_array((pg_temp.m3_e_input()#>'{terms,0}')||jsonb_build_object(
 'term_id','a3000041-0000-4000-8000-000000000041','source_id','a3000042-0000-4000-8000-000000000042',
 'purpose','REACTIVATION','predecessor_term_id','a3000004-0000-4000-8000-000000000004','anchor_rule','REPUBLICATION',
 'purchased_at','2026-03-05T00:00:00.000000Z','original_end','2026-04-10T00:00:00.000000Z','effective_end','2026-04-10T00:00:00.000000Z',
 'authorization',jsonb_set((pg_temp.m3_e_input()#>'{terms,0,authorization}')||'{"decided_at":"2026-03-05T00:00:00.000000Z"}',
 '{payment_condition,decided_at}',to_jsonb(approval_time)),
 'anchor',(pg_temp.m3_e_input()#>'{terms,0,anchor}')||'{"effective_at":"2026-03-10T00:00:00.000000Z","recorded_at":"2026-03-10T00:00:00.000000Z"}'::jsonb)))) j
FROM (VALUES ('republication before activation','2026-03-10T00:00:00.000001Z','UNKNOWN_FAIL_CLOSED'),
 ('republication at activation','2026-03-10T00:00:00.000000Z','ENTITLED'),
 ('republication after activation','2026-03-09T23:59:59.999999Z','ENTITLED')) v(label,approval_time,expected);
SELECT is(pg_temp.m3_eval(j,'2026-03-15T00:00:00Z')->>'entitlement_outcome',expected,label) FROM m3_reactivation_cases ORDER BY label;
SELECT ok(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(pg_temp.m3_a8(),'{grants,0,first_post_launch_publication_at}','"2026-01-24T00:00:00.000000Z"')))->'reason_codes' ? 'ANCHOR_CONFLICT','A8 launch rule remains distinct from paid activation chronology');

-- All eleven frozen Boolean items, including both directions of mutation.
CREATE TEMP TABLE m3_boolean_cases AS
SELECT family_index,capability_key,frozen_value,pg_temp.m3_refresh(jsonb_set(
 CASE WHEN family_index=1 THEN pg_temp.m3_e_input() ELSE pg_temp.m3_family(family_index) END,
 ARRAY['catalog','0','items',item_index::text,'value_boolean'],to_jsonb(NOT frozen_value))) j
FROM (VALUES (1,'analytics.available',0,true),(1,'media.upload_enabled',2,true),(1,'sponsored.purchase_eligible',3,false),
 (2,'analytics.available',0,true),(2,'media.upload_enabled',2,true),(2,'sponsored.purchase_eligible',3,true),
 (3,'analytics.available',0,true),(3,'media.upload_enabled',2,true),(3,'sponsored.purchase_eligible',3,true),
 (4,'analytics.available',0,true),(4,'media.upload_enabled',2,true)) v(family_index,capability_key,item_index,frozen_value);
SELECT is(pg_temp.m3_eval(j)->>'authority_outcome','INCOMPLETE_AUTHORITY',format('frozen Boolean %s/%s cannot be redefined',family_index,capability_key)) FROM m3_boolean_cases ORDER BY family_index,capability_key;
SELECT is(pg_temp.m3_eval(j)->>'entitlement_outcome','UNKNOWN_FAIL_CLOSED',format('changed Boolean %s/%s fails closed',family_index,capability_key)) FROM m3_boolean_cases ORDER BY family_index,capability_key;
SELECT ok(pg_temp.m3_eval(j)->'reason_codes' ? 'MALFORMED_CAPABILITY',format('changed Boolean %s/%s diagnostic',family_index,capability_key)) FROM m3_boolean_cases ORDER BY family_index,capability_key;
SELECT is(pg_temp.m3_eval(j)#>>ARRAY['capabilities',capability_key,'commercial_permission'],'DENY',format('changed Boolean %s/%s grants nothing',family_index,capability_key)) FROM m3_boolean_cases ORDER BY family_index,capability_key;

CREATE TEMP TABLE m3_blocked_verification AS
SELECT e,pg_temp.m3_hash(jsonb_set(p,'{verification}',pg_temp.m3_gate()||'{"status":"BLOCKED_POLICY","evidence_id":null,"revision":null,"decided_at":null,"policy_dependency":"OQ-84"}'),'publication_input_revision') p FROM m3_results,m3_publication;
SELECT is(pg_temp.m3_pub(e,pg_temp.m3_hash(p||jsonb_build_object('verification_requirement',requirement,'verification_state',state),'publication_input_revision'))#>>'{gate_results,verification}',
 'BLOCKED_POLICY',format('blocked verification survives applicability %s/%s',requirement,state))
FROM m3_blocked_verification CROSS JOIN (VALUES ('UNKNOWN','UNKNOWN'),('UNKNOWN','UNVERIFIED'),('NOT_REQUIRED','UNVERIFIED'),('REQUIRED','UNVERIFIED'),('REQUIRED','UNKNOWN'),('REQUIRED','VERIFIED')) v(requirement,state);
SELECT ok(pg_temp.m3_pub(e,pg_temp.m3_hash(p||jsonb_build_object('verification_requirement',requirement,'verification_state',state),'publication_input_revision'))->'reason_codes' ? 'POLICY_DEPENDENCY_BLOCKED',
 format('blocked verification retains OQ-84 dependency %s/%s',requirement,state))
FROM m3_blocked_verification CROSS JOIN (VALUES ('UNKNOWN','UNKNOWN'),('UNKNOWN','UNVERIFIED'),('NOT_REQUIRED','UNVERIFIED'),('REQUIRED','UNVERIFIED'),('REQUIRED','UNKNOWN'),('REQUIRED','VERIFIED')) v(requirement,state);
SELECT is(pg_temp.m3_pub(e,pg_temp.m3_hash(p||'{"verification_requirement":"UNKNOWN"}'::jsonb,'publication_input_revision'))->>'discoverability_outcome','UNKNOWN_FAIL_CLOSED','valid blocked verification cannot discover') FROM m3_blocked_verification;
SELECT is(pg_temp.m3_pub(e,p#-'{verification,policy_dependency}')->'reason_codes','["MISSING_REQUIRED_FIELD"]'::jsonb,'blocked verification dependency omitted') FROM m3_blocked_verification;
SELECT is(pg_temp.m3_pub(e,jsonb_set(p,'{verification,policy_dependency}',value))->'reason_codes',jsonb_build_array(expected),'blocked verification dependency '||label)
FROM m3_blocked_verification CROSS JOIN (VALUES ('null','null'::jsonb,'INVALID_FIELD_TYPE'),('number','84'::jsonb,'INVALID_FIELD_TYPE'),('unsupported','"OQ-999"'::jsonb,'INVALID_ENUM'),('malformed','"oq84"'::jsonb,'INVALID_ENUM')) v(label,value,expected);
SELECT is(pg_temp.m3_pub(e,jsonb_set(p,'{verification}',pg_temp.m3_gate()||'{"policy_dependency":"OQ-84"}'))->'reason_codes','["BINDING_MISMATCH"]'::jsonb,'nonblocked verification cannot carry OQ-84') FROM m3_blocked_verification;
SELECT is(pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p||'{"verification_requirement":"UNKNOWN"}'::jsonb,'{required_fields,status}','"FAIL"'),'publication_input_revision'))->>'discoverability_outcome','DENY','stronger known denial survives blocked verification') FROM m3_blocked_verification;
SELECT is(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(pg_temp.m3_e_input(),'{catalog,0,items}',
 jsonb_build_array(pg_temp.m3_e_input()#>'{catalog,0,items,1}',pg_temp.m3_e_input()#>'{catalog,0,items,0}')||((pg_temp.m3_e_input()#>'{catalog,0,items}')-0-0))))->'reason_codes','["INVALID_ENVELOPE"]'::jsonb,'wrong capability array order exact primary reason');
SELECT is(pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{projection,public_field_paths}','["public_media","approved_name"]'),'publication_input_revision'))->'reason_codes','["INVALID_ENVELOPE"]'::jsonb,'wrong publication manifest order exact primary reason') FROM m3_results,m3_publication;

-- Integer-semantic audit: paths/expected domains are hand-authored from §§33.1–33.8.
-- E = entitlement input, R = actual serialized result, P = publication input.
CREATE TEMP TABLE m3_numeric_cases(kind text,path text[],j jsonb,e jsonb,nullable boolean,invalid_reason text DEFAULT 'INVALID_FIELD_TYPE');
INSERT INTO m3_numeric_cases(kind,path,j,nullable)
SELECT 'E',string_to_array(path,','),pg_temp.m3_e_input(),false FROM (VALUES
 ('synthetic_provider_revision'),('providers,eligibility,revision'),('providers,agreement_terms,revision'),
 ('providers,grants,revision'),('providers,catalog,revision'),('providers,enforcement,revision'),('providers,publication_history,revision'),
 ('model_eligibility,revision'),('agreement,revision'),('catalog,0,plan_version'),('catalog,0,bundle_version'),('catalog,0,registry_version'),
 ('catalog,0,items,1,value_integer'),('catalog,0,items,4,value_integer'),('terms,0,agreement_revision'),('terms,0,duration_months'),
 ('terms,0,authorization,payment_condition,revision'),('enforcement,revision')) v(path);
INSERT INTO m3_numeric_cases(kind,path,j,nullable) VALUES
 ('E','{terms,0,duration_months}',pg_temp.m3_family(4),false),
 ('E','{terms,0,authorization,commitment_months}',pg_temp.m3_family(4),false),
 ('E','{grants,0,program_version}',pg_temp.m3_a8(),false);
INSERT INTO m3_numeric_cases(kind,path,j,nullable) SELECT 'E','{terms,0,extensions,0,revision}',j,false FROM m3_extension;
INSERT INTO m3_numeric_cases(kind,path,j,nullable) SELECT 'E','{prior_publication,content_revision}',j,false FROM m3_grace;
INSERT INTO m3_numeric_cases(kind,path,j,e,nullable)
SELECT 'R',string_to_array(path,','),e,e,nullable FROM m3_results CROSS JOIN (VALUES
 ('synthetic_provider_revision',true),('enforcement_revision',true),('plan_version',true),('bundle_version',true),('registry_version',true),
 ('capabilities,branches.included,value',true),('capabilities,team.active_member_max,value',true)) v(path,nullable);
INSERT INTO m3_numeric_cases(kind,path,j,e,nullable,invalid_reason)
SELECT 'P',string_to_array(path,','),p,e,nullable,invalid_reason FROM m3_results,m3_publication CROSS JOIN (VALUES
 ('synthetic_provider_revision',false,'INVALID_FIELD_TYPE'),('scope,revision',false,'INVALID_FIELD_TYPE'),('content_revision',true,'INVALID_FIELD_TYPE'),
 ('required_fields,revision',false,'INVALID_FIELD_TYPE'),('required_fields,content_revision',false,'INVALID_FIELD_TYPE'),('required_fields,requirements_revision',false,'INVALID_FIELD_TYPE'),
 ('onboarding,revision',false,'INVALID_FIELD_TYPE'),('moderation,revision',false,'INVALID_FIELD_TYPE'),('moderation,content_revision',false,'INVALID_FIELD_TYPE'),
 ('verification,revision',false,'INVALID_FIELD_TYPE'),('enforcement,revision',false,'INVALID_FIELD_TYPE'),('launch,revision',false,'INVALID_FIELD_TYPE'),
 ('projection,content_revision',false,'INVALID_FIELD_TYPE'),('projection,approval,revision',false,'INVALID_FIELD_TYPE'),('projection,approval,content_revision',false,'INVALID_FIELD_TYPE'),
 ('projection,conformance,revision',false,'INVALID_FIELD_TYPE'),('projection,conformance,content_revision',false,'INVALID_FIELD_TYPE'),
 ('projection,projection_revision',true,'INVALID_GENERATION'),('projection,candidate_generation',true,'INVALID_GENERATION'),
 ('authority_revision',true,'INVALID_GENERATION'),('projection_revision',true,'INVALID_GENERATION'),('authoritative_generation',true,'INVALID_GENERATION'),('candidate_generation',true,'INVALID_GENERATION')) v(path,nullable,invalid_reason);
INSERT INTO m3_numeric_cases(kind,path,j,e,nullable)
SELECT 'P','{verification,content_revision}',pg_temp.m3_hash(jsonb_set(p||'{"verification_requirement":"REQUIRED","verification_state":"VERIFIED"}',
 '{verification,content_revision}','17'),'publication_input_revision'),e,false FROM m3_results,m3_publication;
INSERT INTO m3_numeric_cases(kind,path,j,e,nullable)
SELECT 'P','{prior_publication,content_revision}',pg_temp.m3_hash(jsonb_set(pg_temp.m3_p_input(e),'{prior_publication}',j->'prior_publication'),'publication_input_revision'),e,false
FROM (SELECT j,pg_temp.m3_eval(j,'2026-03-01T00:00:00Z') e FROM m3_grace) x;
CREATE FUNCTION pg_temp.m3_numeric_call(kind text,j jsonb,e jsonb) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE p jsonb;
BEGIN
 IF kind='E' THEN RETURN pg_temp.m3_eval(pg_temp.m3_refresh(j),(j->>'as_of')::timestamptz); END IF;
 IF kind='R' THEN
   j:=pg_temp.m3_hash(j,'result_fingerprint'); p:=pg_temp.m3_p_input(j);
   RETURN pg_temp.m3_pub(j,p);
 END IF;
 RETURN pg_temp.m3_pub(e,pg_temp.m3_hash(j,'publication_input_revision'));
END $$;
SELECT is((SELECT count(*) FROM m3_numeric_cases),55::bigint,'integer audit has all 55 applicable populated fixture paths');
-- Three spellings for every applicable path: outcomes are contract literals,
-- while binding fingerprints retain exact PostgreSQL JSONB transport text.
SELECT is(pg_temp.m3_numeric_call(kind,jsonb_set(j,path,((j#>>path)||suffix)::jsonb),e)->>'authority_outcome','COMPLETE',
 format('integral representation %s %s%s',kind,array_to_string(path,'.'),suffix))
FROM m3_numeric_cases CROSS JOIN (VALUES (''),('.0'),('.00')) v(suffix) ORDER BY kind,path,suffix;
SELECT is(pg_temp.m3_pub(actual_e,pg_temp.m3_hash(jsonb_set(pg_temp.m3_p_input(actual_e),'{prior_publication}',j->'prior_publication'),'publication_input_revision'))->>'discoverability_outcome',
 'ALLOW',format('typed numeric result binds publication %s%s',array_to_string(path,'.'),suffix))
FROM m3_numeric_cases CROSS JOIN (VALUES (''),('.0'),('.00')) v(suffix)
CROSS JOIN LATERAL (SELECT pg_temp.m3_numeric_call(kind,jsonb_set(j,path,((j#>>path)||suffix)::jsonb),e) actual_e) x
WHERE kind='E' ORDER BY path,suffix;
SELECT is(actual_e->>'result_fingerprint',pg_temp.m3_hash(actual_e,'result_fingerprint')->>'result_fingerprint',
 format('typed result fingerprint includes integral SQL serialization %s%s',array_to_string(path,'.'),suffix))
FROM m3_numeric_cases CROSS JOIN (VALUES (''),('.0'),('.00')) v(suffix)
CROSS JOIN LATERAL (SELECT pg_temp.m3_numeric_call(kind,jsonb_set(j,path,((j#>>path)||suffix)::jsonb),e) actual_e) x
WHERE kind='E' ORDER BY path,suffix;
SELECT is(pg_temp.m3_numeric_call(kind,jsonb_set(j,path,((j#>>path)||suffix)::jsonb),e)->>'discoverability_outcome','ALLOW',
 format('publication integral representation %s %s%s',kind,array_to_string(path,'.'),suffix))
FROM m3_numeric_cases CROSS JOIN (VALUES (''),('.0'),('.00')) v(suffix) WHERE kind IN ('P','R') ORDER BY kind,path,suffix;
SELECT is(pg_temp.m3_numeric_call(kind,jsonb_set(j,path,((j#>>path)||suffix)::jsonb),e)->>'entitlement_outcome',
 CASE WHEN path='{prior_publication,content_revision}'::text[] THEN 'NOT_ENTITLED' ELSE 'ENTITLED' END,
 format('integral value retains basis %s %s%s',kind,array_to_string(path,'.'),suffix))
FROM m3_numeric_cases CROSS JOIN (VALUES (''),('.0'),('.00')) v(suffix) ORDER BY kind,path,suffix;
SELECT is(pg_temp.m3_numeric_call(kind,jsonb_set(j,path,value),e)->'reason_codes',jsonb_build_array(invalid_reason),
 format('invalid integral domain %s %s %s',kind,array_to_string(path,'.'),label))
FROM m3_numeric_cases CROSS JOIN (VALUES ('negative','-1'::jsonb),('fraction','1.5'::jsonb),('overflow','9223372036854775808'::jsonb),
 ('huge','1e100'::jsonb),('numeric string','"1"'::jsonb),('Boolean','true'::jsonb)) v(label,value) ORDER BY kind,path,label;
SELECT is(pg_temp.m3_numeric_call(kind,jsonb_set(j,path,'null'),e)->'reason_codes',
 CASE WHEN kind='E' AND path[1]='catalog' AND path[3]='items' THEN '["MALFORMED_CAPABILITY"]'::jsonb ELSE '["INVALID_FIELD_TYPE"]'::jsonb END,
 format('required integral null %s %s',kind,array_to_string(path,'.'))) FROM m3_numeric_cases WHERE NOT nullable ORDER BY kind,path;
-- Legitimately nullable numbers retain their existing null/binding semantics.
CREATE TEMP TABLE m3_unused_numeric_cases(kind text,path text[],expected text);
INSERT INTO m3_unused_numeric_cases VALUES
 ('E','{model_eligibility,content_revision}','BINDING_MISMATCH'),('E','{model_eligibility,requirements_revision}','BINDING_MISMATCH'),
 ('E','{terms,0,authorization,payment_condition,content_revision}','BINDING_MISMATCH'),('E','{terms,0,authorization,payment_condition,requirements_revision}','BINDING_MISMATCH'),
 ('E','{terms,0,authorization,commitment_months}','INVALID_FIELD_TYPE'),
 ('P','{onboarding,content_revision}','BINDING_MISMATCH'),('P','{onboarding,requirements_revision}','BINDING_MISMATCH'),
 ('P','{moderation,requirements_revision}','BINDING_MISMATCH'),('P','{verification,content_revision}','BINDING_MISMATCH'),('P','{verification,requirements_revision}','BINDING_MISMATCH'),
 ('P','{launch,content_revision}','BINDING_MISMATCH'),('P','{launch,requirements_revision}','BINDING_MISMATCH'),
 ('P','{projection,approval,requirements_revision}','BINDING_MISMATCH'),('P','{projection,conformance,requirements_revision}','BINDING_MISMATCH');
SELECT is(pg_temp.m3_numeric_call(kind,jsonb_set(CASE WHEN kind='E' THEN pg_temp.m3_e_input() ELSE p END,path,value),e)->'reason_codes',
 jsonb_build_array(expected),format('not-applicable integral %s %s %s stays rejected',kind,array_to_string(path,'.'),value))
FROM m3_unused_numeric_cases,m3_results,m3_publication CROSS JOIN (VALUES ('1'::jsonb),('1.0'::jsonb),('1.00'::jsonb)) v(value) ORDER BY kind,path,value::text;
SELECT is(pg_temp.m3_numeric_call(kind,jsonb_set(CASE WHEN kind='E' THEN pg_temp.m3_e_input() ELSE p END,path,'null'),e)->>'authority_outcome',
 'COMPLETE',format('not-applicable integral null %s %s stays representable',kind,array_to_string(path,'.')))
FROM m3_unused_numeric_cases,m3_results,m3_publication ORDER BY kind,path;
SELECT is(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(pg_temp.m3_e_input(),'{providers,grants}',
 '{"status":"UNAVAILABLE","revision":null,"source_origin":"test_fixture"}')))->>'entitlement_outcome','UNKNOWN_FAIL_CLOSED','unavailable provider legitimately keeps null revision');
SELECT is(pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(jsonb_set(p,'{projection_revision}','null'),'{projection,projection_revision}','null'),'publication_input_revision'))->'reason_codes','["GENERATION_MISSING"]'::jsonb,'null paired projection revision stays missing') FROM m3_results,m3_publication;
SELECT is(pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(jsonb_set(p,'{candidate_generation}','null'),'{projection,candidate_generation}','null'),'publication_input_revision'))->'reason_codes','["GENERATION_MISSING"]'::jsonb,'null paired candidate generation stays missing') FROM m3_results,m3_publication;
SELECT is(pg_temp.m3_eval(pg_temp.m3_e_input())#>'{capabilities,sponsored.purchase_eligible,value}','false'::jsonb,'retail null commitment still valid');
SELECT is(pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{authority_revision}','null'),'publication_input_revision'))->'reason_codes','["GENERATION_MISSING"]'::jsonb,'null canonical authority revision stays missing') FROM m3_results,m3_publication;
SELECT is(pg_temp.m3_pub(e,pg_temp.m3_hash(jsonb_set(p,'{authoritative_generation}','null'),'publication_input_revision'))->'reason_codes','["GENERATION_MISSING"]'::jsonb,'null canonical authority generation stays missing') FROM m3_results,m3_publication;
-- Extension order and semantic uniqueness compare integral values, not spelling.
CREATE TEMP TABLE m3_decimal_extensions AS SELECT pg_temp.m3_refresh(jsonb_set(jsonb_set(j,'{terms,0,effective_end}','"2026-03-04T00:00:00.000000Z"'),
 '{terms,0,extensions}',jsonb_build_array(jsonb_set(j#>'{terms,0,extensions,0}','{revision}','1.00'),
 (j#>'{terms,0,extensions,0}')||'{"extension_id":"a3000045-0000-4000-8000-000000000045","revision":2.0,"effective_end":"2026-03-04T00:00:00.000000Z"}'::jsonb))) j FROM m3_extension;
SELECT is(pg_temp.m3_eval(j)->>'entitlement_outcome','ENTITLED','mixed decimal extension revisions preserve numeric order') FROM m3_decimal_extensions;
SELECT is(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(j,'{terms,0,extensions,1,revision}','1.0')))->'reason_codes','["DUPLICATE_REVISION_IDENTITY"]'::jsonb,'decimal extension duplicate cannot evade semantic identity') FROM m3_decimal_extensions;
SELECT is(pg_temp.m3_eval(pg_temp.m3_refresh(jsonb_set(j,'{terms,0,extensions}',jsonb_build_array(j#>'{terms,0,extensions,1}',j#>'{terms,0,extensions,0}'))))->'reason_codes','["INVALID_ENVELOPE"]'::jsonb,'decimal extension wrong order exact envelope diagnostic') FROM m3_decimal_extensions;

-- Labelled positive fixture rows cannot become runtime/public authority.
CREATE TEMP TABLE m3_positive_summary AS SELECT '{
"entitlement_input_revision":"0000000000000000000000000000000000000000000000000000000000000000","publication_input_revision":"1111111111111111111111111111111111111111111111111111111111111111",
"comparison_target":"fixture_visibility","comparison_result":"MATCH","basis_context":"IN_EFFECT","enforcement_context":"CLEAR","intrinsic_readiness":"READY","candidate_first_publication_ready":false,"continuity_eligible":false,
"gate_results":{"required_fields":"PASS","onboarding":"PASS","moderation":"PASS","verification":"PASS","enforcement":"PASS","launch":"PASS","projection":"PASS","generation":"PASS"},
"catalog_binding":{"plan_id":"1a7b0001-0000-4000-8000-000000000001","plan_version_id":"4c7b0001-0000-4000-8000-000000000001","plan_version":1,"bundle_version_id":"2e7b0001-0000-4000-8000-000000000001","bundle_version":1,"registry_version":1,"snapshot_revision":"2222222222222222222222222222222222222222222222222222222222222222"},
"snapshot_provenance":{"transaction_isolation":"fixture_snapshot","observation_time_basis":"fixed_fixture_instant"}
}'::jsonb s;
INSERT INTO commercial_private.m3_shadow_heads(entity_id,shadow_generation) VALUES('a3300001-0000-4000-8000-000000000001',1);
SELECT lives_ok($positive$
 INSERT INTO commercial_private.m3_shadow_runs(request_id,entity_id,expected_shadow_generation,shadow_generation,evaluator_version,input_version,calendar_rule_version,source_origin,input_fingerprint,observed_at,recorded_at,legacy_visible,authority_outcome,entitlement_outcome,publication_outcome,mismatch_category,reason_codes,result_summary,authority_revision,projection_revision,authoritative_generation,candidate_generation)
 SELECT 'a3300002-0000-4000-8000-000000000002','a3300001-0000-4000-8000-000000000001',0,1,'m3.evaluator.v1','m3.input.v1','m3.baghdad_calendar.v1','test_fixture',
 encode(extensions.digest(convert_to(jsonb_build_object('entitlement_input_revision',s->'entitlement_input_revision','publication_input_revision',s->'publication_input_revision')::text,'UTF8'),'sha256'),'hex'),
 '2026-02-15T00:00:00Z','2026-02-15T00:00:00Z',true,'COMPLETE','ENTITLED','ALLOW','MATCH_VISIBLE',ARRAY[]::text[],s,9,9,7,7 FROM m3_positive_summary
$positive$,'explicit positive fixture evidence allowed without creating authority');
SELECT throws_ok(format('UPDATE commercial_private.m3_shadow_runs SET %I=NULL WHERE request_id=''a3300002-0000-4000-8000-000000000002''',field),
 '23514',NULL,'fixture ALLOW requires '||field) FROM (VALUES ('authority_revision'),('projection_revision'),('authoritative_generation'),('candidate_generation')) v(field);
SELECT throws_ok($$UPDATE commercial_private.m3_shadow_runs SET candidate_generation=6 WHERE request_id='a3300002-0000-4000-8000-000000000002'$$,'23514',NULL,'fixture ALLOW rejects mismatched generations');
SELECT throws_ok($$UPDATE commercial_private.m3_shadow_runs SET projection_revision=8 WHERE request_id='a3300002-0000-4000-8000-000000000002'$$,'23514',NULL,'fixture ALLOW rejects mismatched revisions');
SELECT lives_ok($$UPDATE commercial_private.m3_shadow_runs SET authority_revision=0,projection_revision=0,authoritative_generation=0,candidate_generation=0 WHERE request_id='a3300002-0000-4000-8000-000000000002'$$,'equal zero fixture values satisfy predicate without proving production freshness');
SELECT ok(commercial_private.m3_generation_matches_v1(0,0,0,0),'generation helper proves equality only; stale equal values are not current authority');
SELECT lives_ok($$UPDATE commercial_private.m3_shadow_runs SET authority_revision=NULL,projection_revision=NULL,authoritative_generation=NULL,candidate_generation=NULL,
 authority_outcome='INCOMPLETE_AUTHORITY',entitlement_outcome='UNKNOWN_FAIL_CLOSED',publication_outcome='UNKNOWN_FAIL_CLOSED',mismatch_category='INPUT_OR_VERSION_CONFLICT',
 result_summary=result_summary||'{"comparison_result":"INCOMPARABLE","basis_context":null,"intrinsic_readiness":"UNKNOWN_FAIL_CLOSED","catalog_binding":null}'::jsonb
 WHERE request_id='a3300002-0000-4000-8000-000000000002'$$,'non-ALLOW fixture legitimately represents unavailable comparison evidence');
UPDATE commercial_private.m3_shadow_runs SET authority_revision=9,projection_revision=9,authoritative_generation=7,candidate_generation=7,
 authority_outcome='COMPLETE',entitlement_outcome='ENTITLED',publication_outcome='ALLOW',mismatch_category='MATCH_VISIBLE',result_summary=(SELECT s FROM m3_positive_summary)
 WHERE request_id='a3300002-0000-4000-8000-000000000002';
SELECT is((SELECT count(*) FROM public.directory_entities),0::bigint,'positive persisted fixture cannot create or publish Directory identity');
SELECT is((SELECT count(*) FROM public.subscriptions),0::bigint,'positive persisted fixture cannot grant subscriptions');
SELECT throws_ok($$SELECT capture_status FROM commercial_private.m3_capture_shadow_v1('a3300001-0000-4000-8000-000000000001','a3300002-0000-4000-8000-000000000002',0)$$,'P3MIS','existing request reused for a different origin/entity/original expected generation','fixture run cannot replay as runtime origin');
SELECT throws_ok($$UPDATE commercial_private.m3_shadow_runs SET source_origin='runtime_shadow' WHERE request_id='a3300002-0000-4000-8000-000000000002'$$,'23514',NULL,'positive fixture cannot be relabelled as runtime');
SELECT throws_ok($$UPDATE commercial_private.m3_shadow_runs SET result_summary=jsonb_set(result_summary,'{catalog_binding,snapshot_revision}','2222222222222222222222222222222222222222222222222222222222222222'::jsonb) WHERE request_id='a3300002-0000-4000-8000-000000000002'$$,'23514',NULL,'catalog observation hash must retain JSON string type');
SELECT throws_ok($$UPDATE commercial_private.m3_shadow_runs SET result_summary=jsonb_set(result_summary,'{catalog_binding}',(result_summary->'catalog_binding')||'{"payment":{}}') WHERE request_id='a3300002-0000-4000-8000-000000000002'$$,'23514',NULL,'redacted catalog binding rejects nested payment');
DELETE FROM commercial_private.m3_shadow_runs WHERE request_id='a3300002-0000-4000-8000-000000000002';
DELETE FROM commercial_private.m3_shadow_heads WHERE entity_id='a3300001-0000-4000-8000-000000000001';

-- Runtime direct-session capture and replay use no canonical authority adapters.
INSERT INTO public.directory_entities(id,entity_type,name,lifecycle_status)
 VALUES('a3000001-0000-4000-8000-000000000001','company','M3 rollback fixture','active');
CREATE TEMP TABLE m3_public_before AS SELECT to_jsonb(d) AS row FROM public.directory_entities d;
CREATE TEMP TABLE m3_first AS SELECT * FROM commercial_private.m3_capture_shadow_v1('a3000001-0000-4000-8000-000000000001','a3000010-0000-4000-8000-000000000010',0);
SELECT is((SELECT capture_status FROM m3_first),'FRESH','first direct capture fresh');
SELECT is((SELECT shadow_generation FROM m3_first),1::bigint,'only observation generation advances');
SELECT is((SELECT authority_outcome FROM m3_first),'INCOMPLETE_AUTHORITY','runtime missing canonical authority');
SELECT is((SELECT publication_outcome FROM m3_first),'UNKNOWN_FAIL_CLOSED','runtime capture cannot publish');
SELECT is((SELECT mismatch_category FROM m3_first),'AUTHORITY_GAP_VISIBLE','legacy active used for comparison only');
SELECT is((SELECT to_jsonb(r)-ARRAY['capture_status','is_historical'] FROM commercial_private.m3_capture_shadow_v1('a3000001-0000-4000-8000-000000000001','a3000010-0000-4000-8000-000000000010',0) r),(SELECT to_jsonb(r)-ARRAY['capture_status','is_historical'] FROM m3_first r),'replay returns identical original evidence');
SELECT throws_ok($$SELECT * FROM commercial_private.m3_capture_shadow_v1(NULL,'a3000010-0000-4000-8000-000000000010',0)$$,'P3ARG','NULL/nil/out-of-range argument','null argument class');
SELECT throws_ok($$SELECT * FROM commercial_private.m3_capture_shadow_v1('a3000001-0000-4000-8000-000000000001','a3000010-0000-4000-8000-000000000010',1)$$,'P3MIS','existing request reused for a different origin/entity/original expected generation','request semantic conflict precedes head check');
SELECT throws_ok($$SELECT * FROM commercial_private.m3_capture_shadow_v1('a3000001-0000-4000-8000-000000000001','a3000011-0000-4000-8000-000000000011',0)$$,'P3STA','new request''s expected head stale','stale new request exact class');
SELECT throws_ok($$SELECT * FROM commercial_private.m3_capture_shadow_v1('a3000099-0000-4000-8000-000000000099','a3000011-0000-4000-8000-000000000011',0)$$,'P3REF','fresh target entity absent','absent fresh source rolls head insertion back');
SELECT is((SELECT count(*) FROM commercial_private.m3_shadow_heads),1::bigint,'failed absent/stale captures leave zero partial heads');
SELECT is((SELECT count(*) FROM commercial_private.m3_shadow_runs),1::bigint,'failed captures leave zero partial runs');
SELECT is((SELECT to_jsonb(d) FROM public.directory_entities d),(SELECT row FROM m3_public_before),'capture has zero Directory mutation');
SELECT is((SELECT count(*) FROM public.subscriptions),0::bigint,'capture has zero payment/subscription effect');
SELECT lives_ok($$SELECT * FROM commercial_private.m3_capture_shadow_v1('a3000001-0000-4000-8000-000000000001','a3000012-0000-4000-8000-000000000012',1)$$,'next observation succeeds');

CREATE FUNCTION pg_temp.m3_corrupt_probe() RETURNS text LANGUAGE plpgsql AS $probe$
BEGIN
 EXECUTE $fault_definition$CREATE OR REPLACE FUNCTION commercial_private.m3_evaluate_entitlement_v1(p_input jsonb,p_as_of timestamptz) RETURNS TABLE(envelope_kind text,input_version text,evaluator_version text,calendar_rule_version text,entity_id uuid,source_origin text,as_of timestamptz,input_revision text,synthetic_provider_revision bigint,authority_outcome text,basis_context text,source_kind text,entitlement_outcome text,enforcement_context text,enforcement_revision bigint,continuity_eligible boolean,agreement_id uuid,term_id uuid,grant_id uuid,plan_id uuid,plan_version_id uuid,plan_version bigint,bundle_version_id uuid,bundle_version bigint,registry_version bigint,snapshot_revision text,original_start timestamptz,original_end timestamptz,effective_end timestamptz,grace_end timestamptz,prior_publication_event_id uuid,capabilities jsonb,next_boundary timestamptz,reason_codes text[],result_fingerprint text) LANGUAGE sql IMMUTABLE SECURITY INVOKER SET search_path=commercial_private,pg_temp AS $fault_body$ SELECT 'ENTITLEMENT_RESULT'::text,'m3.input.v1'::text,'m3.evaluator.v1'::text,'m3.baghdad_calendar.v1'::text,NULL::uuid,NULL::text,NULL::timestamptz,NULL::text,NULL::bigint,'INCOMPLETE_AUTHORITY'::text,NULL::text,NULL::text,'UNKNOWN_FAIL_CLOSED'::text,'UNKNOWN'::text,NULL::bigint,false,NULL::uuid,NULL::uuid,NULL::uuid,NULL::uuid,NULL::uuid,NULL::bigint,NULL::uuid,NULL::bigint,NULL::bigint,NULL::text,NULL::timestamptz,NULL::timestamptz,NULL::timestamptz,NULL::timestamptz,NULL::uuid,'{}'::jsonb,NULL::timestamptz,ARRAY['INVALID_ENVELOPE']::text[],'0000000000000000000000000000000000000000000000000000000000000000'::text $fault_body$;$fault_definition$;
 PERFORM r.capture_status FROM commercial_private.m3_capture_shadow_v1('a3000001-0000-4000-8000-000000000001','a3000050-0000-4000-8000-000000000050',2) r;
 RAISE EXCEPTION 'nonconforming output was incorrectly accepted';
EXCEPTION WHEN SQLSTATE 'P3COR' THEN RETURN SQLSTATE;
END $probe$;
CREATE TEMP TABLE m3_original_definition AS SELECT pg_get_functiondef('commercial_private.m3_evaluate_entitlement_v1(jsonb,timestamptz)'::regprocedure) AS definition;
SELECT is(pg_temp.m3_corrupt_probe(),'P3COR','nonconforming internal kernel output raises P3COR and rolls all writes back');
SELECT is(pg_get_functiondef('commercial_private.m3_evaluate_entitlement_v1(jsonb,timestamptz)'::regprocedure),(SELECT definition FROM m3_original_definition),'corruption rehearsal restores original function exactly');
SELECT is((SELECT count(*) FROM commercial_private.m3_shadow_runs),2::bigint,'P3COR cannot insert a successful run');
SELECT is((SELECT shadow_generation FROM commercial_private.m3_shadow_heads),2::bigint,'P3COR cannot advance shadow head');
CREATE FUNCTION pg_temp.m3_context_probe() RETURNS text LANGUAGE plpgsql AS $probe$
BEGIN
 SET LOCAL ROLE postgres;
 PERFORM r.capture_status FROM commercial_private.m3_capture_shadow_v1('a3000001-0000-4000-8000-000000000001','a3000010-0000-4000-8000-000000000010',0) r;
 RAISE EXCEPTION 'SET ROLE unexpectedly accepted';
EXCEPTION WHEN SQLSTATE 'P3CTX' THEN RETURN SQLSTATE;
END $probe$;
SELECT is(pg_temp.m3_context_probe(),'P3CTX','SET ROLE context rejected before matching replay lookup');
CREATE FUNCTION pg_temp.m3_denied(role_name text,statement text) RETURNS text LANGUAGE plpgsql AS $probe$
BEGIN
 EXECUTE format('SET LOCAL ROLE %I',role_name);
 EXECUTE statement;
 RETURN 'UNEXPECTED_SUCCESS';
EXCEPTION WHEN insufficient_privilege THEN RETURN SQLSTATE;
END $probe$;
SELECT is(pg_temp.m3_denied(r.role_name,s.statement),'42501',r.role_name||' actual access denial '||s.label)
FROM (VALUES('anon'),('authenticated'),('service_role')) r(role_name)
CROSS JOIN (VALUES
 ('heads read','SELECT entity_id FROM commercial_private.m3_shadow_heads'),
 ('runs read','SELECT request_id FROM commercial_private.m3_shadow_runs'),
 ('generation execute','SELECT commercial_private.m3_generation_matches_v1(1,1,1,1)'),
 ('entitlement execute','SELECT entity_id FROM commercial_private.m3_evaluate_entitlement_v1(''{}''::jsonb,NULL)'),
 ('capture execute','SELECT entity_id FROM commercial_private.m3_capture_shadow_v1(NULL,NULL,NULL)')
) s(label,statement) ORDER BY r.role_name,s.label;

DELETE FROM public.directory_entities WHERE id='a3000001-0000-4000-8000-000000000001';
SELECT is((SELECT capture_status FROM commercial_private.m3_capture_shadow_v1('a3000001-0000-4000-8000-000000000001','a3000010-0000-4000-8000-000000000010',0)),'REPLAY','historical replay survives source deletion and advanced head');
SELECT throws_ok($$UPDATE commercial_private.m3_shadow_runs SET result_summary=result_summary||'{"raw_input":{}}'$$,'23514',NULL,'summary extra/raw input rejected');
SELECT throws_ok($$UPDATE commercial_private.m3_shadow_runs SET reason_codes=ARRAY['RUNTIME_AUTHORITY_UNAVAILABLE','CANONICAL_PROVIDER_UNAVAILABLE']$$,'23514',NULL,'unsorted reasons rejected at persistence');
SELECT throws_ok($$UPDATE commercial_private.m3_shadow_runs SET publication_outcome='ALLOW'$$,'23514',NULL,'runtime positive persisted authority rejected');

SELECT throws_ok($$UPDATE commercial_private.m3_shadow_runs SET result_summary=jsonb_set(result_summary,'{comparison_target}','"fixture_visibility"')$$,'23514',NULL,'runtime provenance cannot be relabelled as fixture comparison');
SELECT * FROM finish();
ROLLBACK;

