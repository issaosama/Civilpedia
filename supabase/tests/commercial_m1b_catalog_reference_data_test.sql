-- M1b: independent final-state, privilege and actual-file conflict evidence.
-- Disposable local PostgreSQL 17 database only. All fixture DML, privileges
-- and pg_temp helpers are rolled back. Actual CLI atomicity/HTTP are separate.
-- Run with the installed Supabase pg_prove image and a read-only repository
-- mount: the CLI test runner mounts tests alone, hiding the actual migration
-- required by the relative include. pgTAP setup also rolls back in this file.
\set ON_ERROR_STOP on
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path = public, extensions, pg_temp;
SELECT no_plan();
SELECT is(current_user::text,'postgres','accepted creator runs local fixtures');
SELECT is(session_user::text,'postgres','accepted login context');
SELECT is(current_setting('server_version_num')::integer / 10000,17,'PostgreSQL 17');

-- Independent frozen expectations from M1b sections 7-15, not migration output.
CREATE TEMP TABLE m1b_expected_plans AS
SELECT id::uuid,code,name,NULL::text AS description,false AS is_active,
  TIMESTAMPTZ '2026-01-01 00:00:00+00' AS created_at,
  TIMESTAMPTZ '2026-01-01 00:00:00+00' AS updated_at
FROM (VALUES
 ('1a7b0001-0000-4000-8000-000000000001','business','Business'),
 ('1a7b0002-0000-4000-8000-000000000002','business_pro','Business Pro'),
 ('1a7b0003-0000-4000-8000-000000000003','business_plus','Business Plus'),
 ('1a7b0004-0000-4000-8000-000000000004','corporate','Corporate')
) v(id,code,name);

CREATE TEMP TABLE m1b_expected_entitlement_bundles AS
SELECT id::uuid,code,1::integer AS version,1::integer AS registry_version,
  'draft'::text AS status,NULL::timestamptz AS published_at,NULL::timestamptz AS retired_at,
  TIMESTAMPTZ '2026-01-01 00:00:00+00' AS created_at
FROM (VALUES
 ('2e7b0001-0000-4000-8000-000000000001','business_entitlements'),
 ('2e7b0002-0000-4000-8000-000000000002','business_pro_entitlements'),
 ('2e7b0003-0000-4000-8000-000000000003','business_plus_entitlements'),
 ('2e7b0004-0000-4000-8000-000000000004','corporate_entitlements')
) v(id,code);

CREATE TEMP TABLE m1b_expected_plan_versions AS
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

CREATE TEMP TABLE m1b_expected_bundle_items AS
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

CREATE TEMP TABLE m1b_expected_term_prices AS
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

CREATE FUNCTION pg_temp.m1b_snapshot() RETURNS jsonb
LANGUAGE plpgsql SECURITY INVOKER SET search_path = pg_catalog, pg_temp AS $snapshot$
DECLARE scanned_relation record; digest text; data jsonb := '{}'::jsonb; metadata jsonb;
BEGIN
  FOR scanned_relation IN SELECT n.nspname,c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE (n.nspname IN ('public','commercial_private') AND c.relkind='r')
       OR (n.nspname='auth' AND c.relname IN ('users','identities','sessions','refresh_tokens','audit_log_entries') AND c.relkind='r')
    ORDER BY n.nspname,c.relname LOOP
    EXECUTE format('SELECT md5(coalesce(string_agg(to_jsonb(t)::text,E''\\n'' ORDER BY to_jsonb(t)::text),'''')) FROM ONLY %I.%I t',scanned_relation.nspname,scanned_relation.relname) INTO digest;
    data := data || jsonb_build_object(scanned_relation.nspname||'.'||scanned_relation.relname,digest);
  END LOOP;
  SELECT pg_catalog.jsonb_build_object(
  'schemas', (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_array(n.oid, n.nspname,
    n.nspowner, n.nspacl) ORDER BY n.oid) FROM pg_catalog.pg_namespace n
    WHERE n.nspname IN ('public', 'commercial_private')),
  'relations', (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_array(c.oid, c.relname,
    c.relkind, c.relowner, c.relrowsecurity, c.relforcerowsecurity,
    c.relacl, pg_catalog.obj_description(c.oid, 'pg_class')) ORDER BY c.oid)
    FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname IN ('public', 'commercial_private')),
  'columns', (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_array(a.attrelid, a.attnum,
    a.attname, a.atttypid, a.atttypmod, a.attnotnull, a.attacl,
    a.attidentity, a.attgenerated, pg_catalog.pg_get_expr(d.adbin, d.adrelid))
    ORDER BY a.attrelid, a.attnum)
    FROM pg_catalog.pg_attribute a JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_catalog.pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
    WHERE n.nspname IN ('public', 'commercial_private')
      AND a.attnum > 0 AND NOT a.attisdropped),
  'constraints', (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_array(k.oid, k.conname,
    k.conrelid, k.confrelid, k.convalidated, k.condeferrable,
    k.condeferred, pg_catalog.pg_get_constraintdef(k.oid)) ORDER BY k.oid)
    FROM pg_catalog.pg_constraint k JOIN pg_catalog.pg_namespace n ON n.oid = k.connamespace
    WHERE n.nspname IN ('public', 'commercial_private')),
  'policies', (SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(p) ORDER BY p.oid)
    FROM pg_catalog.pg_policy p JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname IN ('public', 'commercial_private')),
  'routines', (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_array(p.oid, p.proowner,
    p.proacl, pg_catalog.pg_get_functiondef(p.oid)) ORDER BY p.oid)
    FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('public', 'commercial_private')
      AND p.prokind IN ('f', 'p', 'w')),
  'triggers', (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_array(t.oid, t.tgrelid,
    pg_catalog.pg_get_triggerdef(t.oid)) ORDER BY t.oid)
    FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_class c ON c.oid = t.tgrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname IN ('public', 'commercial_private')),
  'defaults', (SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(d) ORDER BY d.oid)
    FROM pg_catalog.pg_default_acl d),
  'roles', (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_array(r.oid, r.rolname,
    r.rolsuper, r.rolinherit, r.rolcreaterole, r.rolcreatedb,
    r.rolcanlogin, r.rolreplication, r.rolbypassrls, r.rolconfig)
    ORDER BY r.oid) FROM pg_catalog.pg_roles r),
  'memberships', (SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(m) ORDER BY m.oid)
    FROM pg_catalog.pg_auth_members m),
  'extensions', (SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(e) ORDER BY e.oid)
    FROM pg_catalog.pg_extension e),
  'publications', (SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(p) ORDER BY p.oid)
    FROM pg_catalog.pg_publication p),
  'publication_tables', (SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(p)
    ORDER BY p.pubname, p.schemaname, p.tablename)
    FROM pg_catalog.pg_publication_tables p)
) INTO metadata;
  RETURN jsonb_build_object('data',data,'metadata',metadata);
END;
$snapshot$;
CREATE TEMP TABLE m1b_original AS SELECT pg_temp.m1b_snapshot() AS value;

-- Each exact JSON comparison checks EVERY column, including NULLs/timestamps.
SELECT is((SELECT count(*)::integer FROM public.plans),4,'exact plans count');
SELECT is(to_jsonb(a),to_jsonb(e),'exact plans row '||e.id)
FROM m1b_expected_plans e LEFT JOIN public.plans a ON a.id=e.id ORDER BY e.id;
SELECT is((SELECT count(*)::integer FROM commercial_private.entitlement_bundles),4,'exact entitlement_bundles count');
SELECT is(to_jsonb(a),to_jsonb(e),'exact entitlement_bundles row '||e.id)
FROM m1b_expected_entitlement_bundles e LEFT JOIN commercial_private.entitlement_bundles a ON a.id=e.id ORDER BY e.id;
SELECT is((SELECT count(*)::integer FROM commercial_private.bundle_items),19,'exact bundle_items count');
SELECT is(to_jsonb(a),to_jsonb(e),'exact bundle_items row '||e.id)
FROM m1b_expected_bundle_items e LEFT JOIN commercial_private.bundle_items a ON a.id=e.id ORDER BY e.id;
SELECT is((SELECT count(*)::integer FROM commercial_private.plan_versions),4,'exact plan_versions count');
SELECT is(to_jsonb(a),to_jsonb(e),'exact plan_versions row '||e.id)
FROM m1b_expected_plan_versions e LEFT JOIN commercial_private.plan_versions a ON a.id=e.id ORDER BY e.id;
SELECT is((SELECT count(*)::integer FROM commercial_private.term_prices),9,'exact term_prices count');
SELECT is(to_jsonb(a),to_jsonb(e),'exact term_prices row '||e.id)
FROM m1b_expected_term_prices e LEFT JOIN commercial_private.term_prices a ON a.id=e.id ORDER BY e.id;
SELECT is((SELECT count(*)::integer FROM (
SELECT id FROM public.plans
UNION ALL
SELECT id FROM commercial_private.entitlement_bundles
UNION ALL
SELECT id FROM commercial_private.bundle_items
UNION ALL
SELECT id FROM commercial_private.plan_versions
UNION ALL
SELECT id FROM commercial_private.term_prices
) all_rows),40,'total exactly forty reference rows');
SELECT results_eq($$SELECT b.code,count(i.id)::integer FROM commercial_private.entitlement_bundles b
 LEFT JOIN commercial_private.bundle_items i ON i.bundle_version_id=b.id GROUP BY b.code ORDER BY b.code$$,
 $$VALUES ('business_entitlements'::text,5),('business_plus_entitlements',5),('business_pro_entitlements',5),('corporate_entitlements',4)$$,
 'bundle distribution five/five/five/four');
SELECT is((SELECT count(*)::integer FROM commercial_private.bundle_items i
 JOIN commercial_private.entitlement_bundles b ON b.id=i.bundle_version_id
 WHERE b.code='corporate_entitlements' AND i.capability_key='sponsored.purchase_eligible'),0,
 'Corporate Sponsored key absent; Plus floor is not a custom cap');
SELECT is((SELECT count(*)::integer FROM commercial_private.term_prices
 WHERE duration_months NOT IN (1,3,12) OR amount_iqd IN (150000,300000,525000)),0,
 'no six-month or Founding price');
SELECT is((SELECT count(*)::integer FROM commercial_private.term_prices p
 JOIN commercial_private.plan_versions v ON v.id=p.plan_version_id
 WHERE v.pricing_mode='custom_quote'),0,'no Corporate retail price');
SELECT is((SELECT count(*)::integer FROM public.plans
 WHERE code IN ('founding_partner','launch_partner','sponsored','free','trial')),0,'no excluded base plan');
SELECT is((SELECT count(*)::integer FROM public.subscriptions),0,'reference rows assign no subscription');
SELECT is((SELECT count(*)::integer FROM public.directory_entities),0,'reference rows assign no entity');
SELECT is((SELECT count(*)::integer FROM public.business_memberships),0,'no business owner/team assignment');
SELECT is((SELECT count(*)::integer FROM commercial_private.plan_versions
 WHERE status <> 'draft' OR published_at IS NOT NULL OR effective_from IS NOT NULL),0,'no publication/activation');

CREATE FUNCTION pg_temp.m1b_result(statement text, role_name name DEFAULT NULL, subject text DEFAULT NULL)
RETURNS text LANGUAGE plpgsql SECURITY INVOKER SET search_path = pg_catalog, pg_temp AS $probe$
DECLARE state text; constraint_name text; message text;
BEGIN
  BEGIN
    IF subject IS NOT NULL THEN
      PERFORM set_config('request.jwt.claim.sub',subject,true);
      PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',subject,'role',role_name)::text,true);
    END IF;
    IF role_name IS NOT NULL THEN EXECUTE format('SET LOCAL ROLE %I',role_name); END IF;
    EXECUTE statement;
    RAISE EXCEPTION 'm1b_success_rollback' USING ERRCODE='P0T00';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS state=RETURNED_SQLSTATE,constraint_name=CONSTRAINT_NAME,message=MESSAGE_TEXT;
    IF state='P0T00' AND message='m1b_success_rollback' THEN RETURN 'NO_ERROR'; END IF;
    RETURN state||'|'||coalesce(constraint_name,'');
  END;
END;
$probe$;

SELECT is((SELECT count(*)::integer FROM pg_policy WHERE polrelid='public.plans'::regclass),0,'plans_select_all and replacement policies absent');
SELECT ok(relrowsecurity AND NOT relforcerowsecurity,'accepted plans RLS posture')
 FROM pg_class WHERE oid='public.plans'::regclass;
SELECT is((SELECT count(*)::integer FROM pg_class c
 CROSS JOIN LATERAL aclexplode(coalesce(c.relacl,acldefault('r',c.relowner))) a
 WHERE c.oid='public.plans'::regclass AND a.grantee=0),0,'PUBLIC has no plans ACL');
SELECT ok(NOT has_table_privilege(r.role_name,'public.plans',p.privilege),
 r.role_name||' denied plans '||p.privilege)
FROM (VALUES ('anon'),('authenticated')) r(role_name)
CROSS JOIN (VALUES ('SELECT'),('INSERT'),('UPDATE'),('DELETE'),('TRUNCATE'),('REFERENCES'),('TRIGGER'),('MAINTAIN')) p(privilege);
SELECT is(pg_temp.m1b_result(q.statement,r.role_name::name),'42501|',
 r.role_name||' populated plans denial: '||q.label)
FROM (VALUES ('anon'),('authenticated')) r(role_name)
CROSS JOIN (VALUES
 ('SELECT * FROM public.plans','all rows'),
 ('SELECT name FROM public.plans','plan names'),
 ('SELECT count(*) FROM public.plans','count'),
 ('SELECT to_jsonb(p) FROM public.plans p','JSON'),
 ('SELECT s.id,p.name FROM public.subscriptions s LEFT JOIN public.plans p ON p.id=s.plan_id','nested relationship')
) q(statement,label);
SELECT ok(NOT has_schema_privilege(r.role_name,'commercial_private',p.privilege),
 r.role_name||' denied private namespace '||p.privilege)
FROM (VALUES ('anon'),('authenticated'),('service_role')) r(role_name)
CROSS JOIN (VALUES ('USAGE'),('CREATE')) p(privilege);
SELECT ok(NOT has_table_privilege(r.role_name,c.oid,p.privilege),
 r.role_name||' denied '||c.relname||' '||p.privilege)
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
CROSS JOIN (VALUES ('anon'),('authenticated'),('service_role')) r(role_name)
CROSS JOIN (VALUES ('SELECT'),('INSERT'),('UPDATE'),('DELETE'),('TRUNCATE'),('REFERENCES'),('TRIGGER'),('MAINTAIN')) p(privilege)
WHERE n.nspname='commercial_private' AND c.relkind='r';
SELECT is(pg_temp.m1b_result(format(q.statement,c.relname),r.role_name::name),'42501|',
 r.role_name||' runtime private '||c.relname||' '||q.label)
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
CROSS JOIN (VALUES ('anon'),('authenticated'),('service_role')) r(role_name)
CROSS JOIN (VALUES
 ('SELECT * FROM commercial_private.%I','SELECT'),
 ('INSERT INTO commercial_private.%I DEFAULT VALUES','INSERT'),
 ('UPDATE commercial_private.%I SET id=id','UPDATE'),
 ('DELETE FROM commercial_private.%I','DELETE'),
 ('TRUNCATE commercial_private.%I','TRUNCATE')
) q(statement,label)
WHERE n.nspname='commercial_private' AND c.relkind='r';
SELECT is(pg_temp.m1b_result(
 $$UPDATE commercial_private.plan_versions SET status='published',published_at='2026-01-01',effective_from='2026-01-01'$$,
 r.role_name::name),'42501|',r.role_name||' cannot publish a sentinel-bearing version')
FROM (VALUES ('anon'),('authenticated'),('service_role')) r(role_name);
SELECT is((SELECT count(*)::integer FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='commercial_private'),0,'no publisher/evaluator/API routine exists');
SELECT is((SELECT count(*)::integer FROM pg_publication_tables
 WHERE schemaname='commercial_private' OR (schemaname='public' AND tablename='plans')),0,'no catalog Realtime exposure');
SELECT is((SELECT count(*)::integer FROM pg_policy p JOIN pg_class c ON c.oid=p.polrelid
 JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='commercial_private'),0,'private RLS has zero policies');
SELECT is(pg_temp.m1b_result(
 $$INSERT INTO commercial_private.term_prices(id,plan_version_id,version,duration_months,amount_iqd)
 VALUES ('a1b10000-0000-4000-8000-000000000001','4c7b0001-0000-4000-8000-000000000001',1,6,1)$$),
 '23514|chk_term_prices_duration_months','six-month price is structurally rejected');
SELECT is(pg_temp.m1b_result(
 $$INSERT INTO commercial_private.term_prices(id,plan_version_id,version,duration_months,amount_iqd)
 VALUES ('a1b10000-0000-4000-8000-000000000001','4c7b0004-0000-4000-8000-000000000004',1,12,1)$$),
 '23503|fk_term_prices_plan_version_pricing_mode','Corporate retail price is structurally rejected');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'privilege/negative probes leave no row or metadata delta');

-- Replay the ACTUAL migration file. These are not duplicate validator functions.

-- JWT role shapes with real owner/staff memberships remain unable to consume
-- the populated catalog; these are SQL probes, not genuine-Auth HTTP evidence.
SAVEPOINT m1b_actor_fixture;
INSERT INTO auth.users(id,email,created_at,updated_at) VALUES
 ('a1b40000-0000-4000-8000-000000000001','m1b-ordinary@example.invalid',now(),now()),
 ('a1b40000-0000-4000-8000-000000000002','m1b-owner@example.invalid',now(),now()),
 ('a1b40000-0000-4000-8000-000000000003','m1b-staff@example.invalid',now(),now());
INSERT INTO public.profiles(user_id,display_name) VALUES
 ('a1b40000-0000-4000-8000-000000000001','M1b ordinary fixture'),
 ('a1b40000-0000-4000-8000-000000000002','M1b owner fixture'),
 ('a1b40000-0000-4000-8000-000000000003','M1b staff fixture');
INSERT INTO public.directory_entities(id,entity_type,name,lifecycle_status)
VALUES ('a1b40000-0000-4000-8000-000000000004','company','M1b owner fixture','active');
INSERT INTO public.business_memberships(user_id,entity_id,role)
VALUES ('a1b40000-0000-4000-8000-000000000002','a1b40000-0000-4000-8000-000000000004','OWNER');
INSERT INTO public.staff_memberships(user_id,role_id)
SELECT 'a1b40000-0000-4000-8000-000000000003',id FROM public.roles WHERE code='application_reviewer';
SELECT is((SELECT count(*)::integer FROM public.business_memberships
 WHERE user_id='a1b40000-0000-4000-8000-000000000002' AND role='OWNER'),1,'real owner membership positive control');
SELECT is((SELECT count(*)::integer FROM public.staff_memberships
 WHERE user_id='a1b40000-0000-4000-8000-000000000003'),1,'real staff membership positive control');
SELECT is(pg_temp.m1b_result(q.statement,'authenticated',actor.subject),'42501|',
 actor.label||' JWT cannot read or activate reference metadata: '||q.label)
FROM (VALUES
 ('a1b40000-0000-4000-8000-000000000001','ordinary'),
 ('a1b40000-0000-4000-8000-000000000002','business owner'),
 ('a1b40000-0000-4000-8000-000000000003','staff')
) actor(subject,label)
CROSS JOIN (VALUES
 ('SELECT name FROM public.plans','plan names'),
 ('SELECT name_ar FROM commercial_private.plan_versions','sentinel'),
 ('SELECT code FROM commercial_private.entitlement_bundles','bundles'),
 ('SELECT value_integer FROM commercial_private.bundle_items','capabilities'),
 ('SELECT amount_iqd FROM commercial_private.term_prices','prices'),
 ('UPDATE commercial_private.plan_versions SET status=''published'',published_at=''2026-01-01'',effective_from=''2026-01-01''','publication')
) q(statement,label);
ROLLBACK TO SAVEPOINT m1b_actor_fixture;
RELEASE SAVEPOINT m1b_actor_fixture;
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'actor probes leave zero residual fixtures');
\ir ../migrations/00024_commercial_catalog_reference_data.sql
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'B: compatible rerun is byte-identical and idempotent');

SAVEPOINT m1b_case;
DELETE FROM commercial_private.term_prices;
DELETE FROM commercial_private.bundle_items;
DELETE FROM commercial_private.plan_versions;
DELETE FROM commercial_private.entitlement_bundles;
DELETE FROM public.plans;
\ir ../migrations/00024_commercial_catalog_reference_data.sql
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'A: absent catalog reproduces all forty exact rows');
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;

-- C exact code wrong UUID; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
DELETE FROM commercial_private.term_prices;
DELETE FROM commercial_private.bundle_items;
DELETE FROM commercial_private.plan_versions;
DELETE FROM commercial_private.entitlement_bundles;
DELETE FROM public.plans;
INSERT INTO public.plans(id,code,name,is_active) VALUES ('a1b20000-0000-4000-8000-000000000001','business_pro','fixture',false);
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'C exact code wrong UUID: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case C:','C exact code wrong UUID: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'C exact code wrong UUID: zero residual fixtures');

-- D canonical UUID with wrong_code; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
UPDATE public.plans SET code='wrong_code' WHERE code='business_pro';
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'D canonical UUID with wrong_code: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case D:','D canonical UUID with wrong_code: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'D canonical UUID with wrong_code: zero residual fixtures');

-- D canonical UUID with BUSINESS_PRO; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
UPDATE public.plans SET code='BUSINESS_PRO' WHERE code='business_pro';
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'D canonical UUID with BUSINESS_PRO: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case D:','D canonical UUID with BUSINESS_PRO: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'D canonical UUID with BUSINESS_PRO: zero residual fixtures');

-- D canonical UUID with business-pro; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
UPDATE public.plans SET code='business-pro' WHERE code='business_pro';
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'D canonical UUID with business-pro: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case D:','D canonical UUID with business-pro: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'D canonical UUID with business-pro: zero residual fixtures');

-- C-prime "BUSINESS_PRO"; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
DELETE FROM commercial_private.term_prices;
DELETE FROM commercial_private.bundle_items;
DELETE FROM commercial_private.plan_versions;
DELETE FROM commercial_private.entitlement_bundles;
DELETE FROM public.plans;
INSERT INTO public.plans(id,code,name,is_active) VALUES ('a1b20000-0000-4000-8000-000000000001','BUSINESS_PRO','fixture',false);
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'C-prime "BUSINESS_PRO": actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case C-prime:','C-prime "BUSINESS_PRO": correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'C-prime "BUSINESS_PRO": zero residual fixtures');

-- C-prime "Business_Pro"; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
DELETE FROM commercial_private.term_prices;
DELETE FROM commercial_private.bundle_items;
DELETE FROM commercial_private.plan_versions;
DELETE FROM commercial_private.entitlement_bundles;
DELETE FROM public.plans;
INSERT INTO public.plans(id,code,name,is_active) VALUES ('a1b20000-0000-4000-8000-000000000001','Business_Pro','fixture',false);
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'C-prime "Business_Pro": actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case C-prime:','C-prime "Business_Pro": correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'C-prime "Business_Pro": zero residual fixtures');

-- C-prime " business_pro"; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
DELETE FROM commercial_private.term_prices;
DELETE FROM commercial_private.bundle_items;
DELETE FROM commercial_private.plan_versions;
DELETE FROM commercial_private.entitlement_bundles;
DELETE FROM public.plans;
INSERT INTO public.plans(id,code,name,is_active) VALUES ('a1b20000-0000-4000-8000-000000000001',' business_pro','fixture',false);
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'C-prime " business_pro": actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case C-prime:','C-prime " business_pro": correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'C-prime " business_pro": zero residual fixtures');

-- C-prime "business_pro "; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
DELETE FROM commercial_private.term_prices;
DELETE FROM commercial_private.bundle_items;
DELETE FROM commercial_private.plan_versions;
DELETE FROM commercial_private.entitlement_bundles;
DELETE FROM public.plans;
INSERT INTO public.plans(id,code,name,is_active) VALUES ('a1b20000-0000-4000-8000-000000000001','business_pro ','fixture',false);
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'C-prime "business_pro ": actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case C-prime:','C-prime "business_pro ": correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'C-prime "business_pro ": zero residual fixtures');

-- C-prime " business_pro "; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
DELETE FROM commercial_private.term_prices;
DELETE FROM commercial_private.bundle_items;
DELETE FROM commercial_private.plan_versions;
DELETE FROM commercial_private.entitlement_bundles;
DELETE FROM public.plans;
INSERT INTO public.plans(id,code,name,is_active) VALUES ('a1b20000-0000-4000-8000-000000000001',' business_pro ','fixture',false);
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'C-prime " business_pro ": actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case C-prime:','C-prime " business_pro ": correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'C-prime " business_pro ": zero residual fixtures');

-- C-prime "business-pro"; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
DELETE FROM commercial_private.term_prices;
DELETE FROM commercial_private.bundle_items;
DELETE FROM commercial_private.plan_versions;
DELETE FROM commercial_private.entitlement_bundles;
DELETE FROM public.plans;
INSERT INTO public.plans(id,code,name,is_active) VALUES ('a1b20000-0000-4000-8000-000000000001','business-pro','fixture',false);
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'C-prime "business-pro": actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case C-prime:','C-prime "business-pro": correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'C-prime "business-pro": zero residual fixtures');

-- C-prime "business pro"; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
DELETE FROM commercial_private.term_prices;
DELETE FROM commercial_private.bundle_items;
DELETE FROM commercial_private.plan_versions;
DELETE FROM commercial_private.entitlement_bundles;
DELETE FROM public.plans;
INSERT INTO public.plans(id,code,name,is_active) VALUES ('a1b20000-0000-4000-8000-000000000001','business pro','fixture',false);
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'C-prime "business pro": actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case C-prime:','C-prime "business pro": correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'C-prime "business pro": zero residual fixtures');

-- C-prime "business.pro"; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
DELETE FROM commercial_private.term_prices;
DELETE FROM commercial_private.bundle_items;
DELETE FROM commercial_private.plan_versions;
DELETE FROM commercial_private.entitlement_bundles;
DELETE FROM public.plans;
INSERT INTO public.plans(id,code,name,is_active) VALUES ('a1b20000-0000-4000-8000-000000000001','business.pro','fixture',false);
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'C-prime "business.pro": actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case C-prime:','C-prime "business.pro": correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'C-prime "business.pro": zero residual fixtures');

-- C-prime "business__pro"; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
DELETE FROM commercial_private.term_prices;
DELETE FROM commercial_private.bundle_items;
DELETE FROM commercial_private.plan_versions;
DELETE FROM commercial_private.entitlement_bundles;
DELETE FROM public.plans;
INSERT INTO public.plans(id,code,name,is_active) VALUES ('a1b20000-0000-4000-8000-000000000001','business__pro','fixture',false);
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'C-prime "business__pro": actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case C-prime:','C-prime "business__pro": correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'C-prime "business__pro": zero residual fixtures');

-- C-prime "BUSINESS-PRO"; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
DELETE FROM commercial_private.term_prices;
DELETE FROM commercial_private.bundle_items;
DELETE FROM commercial_private.plan_versions;
DELETE FROM commercial_private.entitlement_bundles;
DELETE FROM public.plans;
INSERT INTO public.plans(id,code,name,is_active) VALUES ('a1b20000-0000-4000-8000-000000000001','BUSINESS-PRO','fixture',false);
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'C-prime "BUSINESS-PRO": actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case C-prime:','C-prime "BUSINESS-PRO": correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'C-prime "BUSINESS-PRO": zero residual fixtures');

-- E name; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
UPDATE public.plans SET name='wrong' WHERE code='business';
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'E name: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case E:','E name: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'E name: zero residual fixtures');

-- E description; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
UPDATE public.plans SET description='unexpected' WHERE code='business';
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'E description: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case E:','E description: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'E description: zero residual fixtures');

-- E is_active; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
UPDATE public.plans SET is_active=true WHERE code='business';
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'E is_active: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case E:','E is_active: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'E is_active: zero residual fixtures');

-- E created_at; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
UPDATE public.plans SET created_at='2026-02-01' WHERE code='business';
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'E created_at: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case E:','E created_at: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'E created_at: zero residual fixtures');

-- E updated_at; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
UPDATE public.plans SET updated_at='2026-02-01' WHERE code='business';
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'E updated_at: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b case E:','E updated_at: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'E updated_at: zero residual fixtures');

-- G wrong plan-version link; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
DELETE FROM commercial_private.term_prices;
DELETE FROM commercial_private.bundle_items;
DELETE FROM commercial_private.plan_versions;
DELETE FROM commercial_private.entitlement_bundles;
DELETE FROM public.plans;
INSERT INTO public.plans SELECT * FROM m1b_expected_plans;
INSERT INTO commercial_private.entitlement_bundles SELECT * FROM m1b_expected_entitlement_bundles;
INSERT INTO commercial_private.plan_versions SELECT * FROM m1b_expected_plan_versions WHERE sort_order=1;
UPDATE commercial_private.plan_versions SET plan_id='1a7b0002-0000-4000-8000-000000000002';
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'G wrong plan-version link: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b G plan-version','G wrong plan-version link: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'G wrong plan-version link: zero residual fixtures');

-- bundle metadata drift; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
UPDATE commercial_private.entitlement_bundles SET registry_version=2 WHERE code='business_entitlements';
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'bundle metadata drift: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b bundle conflict','bundle metadata drift: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'bundle metadata drift: zero residual fixtures');

-- item typed-value drift; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
UPDATE commercial_private.bundle_items SET value_integer=99 WHERE capability_key='branches.included';
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'item typed-value drift: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b bundle item conflict','item typed-value drift: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'item typed-value drift: zero residual fixtures');

-- price amount drift; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
UPDATE commercial_private.term_prices SET amount_iqd=amount_iqd+1 WHERE duration_months=1;
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'price amount drift: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b term price conflict','price amount drift: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'price amount drift: zero residual fixtures');

-- price natural-key UUID collision; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
UPDATE commercial_private.term_prices SET id='a1b20000-0000-4000-8000-000000000001' WHERE id='5d7b0001-0000-4000-8000-000000000001';
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'price natural-key UUID collision: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b term price conflict','price natural-key UUID collision: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'price natural-key UUID collision: zero residual fixtures');

-- unexpected frozen bundle capability; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
INSERT INTO commercial_private.bundle_items(id,bundle_version_id,capability_key,value_kind,value_boolean)
VALUES ('a1b20000-0000-4000-8000-000000000001','2e7b0001-0000-4000-8000-000000000001','fixture.extra','boolean',true);
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'unexpected frozen bundle capability: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b frozen bundle','unexpected frozen bundle capability: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'unexpected frozen bundle capability: zero residual fixtures');

-- public SELECT drift; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
GRANT SELECT ON public.plans TO anon;
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'public SELECT drift: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b public/private ACL','public SELECT drift: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'public SELECT drift: zero residual fixtures');

-- public policy drift; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
CREATE POLICY m1b_test_drift ON public.plans FOR SELECT TO anon USING (true);
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'public policy drift: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b M1a/HARDEN-1','public policy drift: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'public policy drift: zero residual fixtures');

-- public RLS drift; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
ALTER TABLE public.plans DISABLE ROW LEVEL SECURITY;
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'public RLS drift: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b M1a/HARDEN-1','public RLS drift: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'public RLS drift: zero residual fixtures');

-- private schema ACL drift; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
GRANT USAGE ON SCHEMA commercial_private TO authenticated;
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'private schema ACL drift: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b public/private ACL','private schema ACL drift: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'private schema ACL drift: zero residual fixtures');

-- creator default privilege drift; savepoint restoration is checked against the complete baseline.
SAVEPOINT m1b_case;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT EXECUTE ON FUNCTIONS TO PUBLIC;
\set ON_ERROR_STOP off
\ir ../migrations/00024_commercial_catalog_reference_data.sql
\set m1b_error_state :SQLSTATE
\set m1b_error_message :LAST_ERROR_MESSAGE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(:'m1b_error_state'::text,'P0001'::text,'creator default privilege drift: actual migration raises fail-closed exception');
SELECT matches(:'m1b_error_message'::text,'^M1b M1a default','creator default privilege drift: correct conflict classification');
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'creator default privilege drift: zero residual fixtures');

SAVEPOINT m1b_case;
INSERT INTO public.plans(id,code,name,description,is_active,created_at,updated_at)
VALUES ('a1b30000-0000-4000-8000-000000000001','business_legacy','legacy untouched','legacy description',true,'2025-01-01','2025-02-01');
INSERT INTO public.directory_entities(id,entity_type,name,lifecycle_status)
VALUES ('a1b30000-0000-4000-8000-000000000002','company','legacy subscription fixture','active');
INSERT INTO public.subscriptions(id,entity_id,plan_id,started_at,price_paid,currency)
VALUES ('a1b30000-0000-4000-8000-000000000003','a1b30000-0000-4000-8000-000000000002','a1b30000-0000-4000-8000-000000000001','2025-01-01',123.45,'IQD');
CREATE TEMP TABLE m1b_legacy_snapshot AS SELECT pg_temp.m1b_snapshot() AS value;
\ir ../migrations/00024_commercial_catalog_reference_data.sql
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_legacy_snapshot),'F business_legacy: legacy row, subscription and entity untouched; no abort');
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'F business_legacy: zero residual fixtures');

SAVEPOINT m1b_case;
INSERT INTO public.plans(id,code,name,description,is_active,created_at,updated_at)
VALUES ('a1b30000-0000-4000-8000-000000000001','company','legacy untouched','legacy description',true,'2025-01-01','2025-02-01');
INSERT INTO public.directory_entities(id,entity_type,name,lifecycle_status)
VALUES ('a1b30000-0000-4000-8000-000000000002','company','legacy subscription fixture','active');
INSERT INTO public.subscriptions(id,entity_id,plan_id,started_at,price_paid,currency)
VALUES ('a1b30000-0000-4000-8000-000000000003','a1b30000-0000-4000-8000-000000000002','a1b30000-0000-4000-8000-000000000001','2025-01-01',123.45,'IQD');
CREATE TEMP TABLE m1b_legacy_snapshot AS SELECT pg_temp.m1b_snapshot() AS value;
\ir ../migrations/00024_commercial_catalog_reference_data.sql
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_legacy_snapshot),'F company: legacy row, subscription and entity untouched; no abort');
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'F company: zero residual fixtures');

SAVEPOINT m1b_case;
INSERT INTO public.plans(id,code,name,description,is_active,created_at,updated_at)
VALUES ('a1b30000-0000-4000-8000-000000000001','pro_business','legacy untouched','legacy description',true,'2025-01-01','2025-02-01');
INSERT INTO public.directory_entities(id,entity_type,name,lifecycle_status)
VALUES ('a1b30000-0000-4000-8000-000000000002','company','legacy subscription fixture','active');
INSERT INTO public.subscriptions(id,entity_id,plan_id,started_at,price_paid,currency)
VALUES ('a1b30000-0000-4000-8000-000000000003','a1b30000-0000-4000-8000-000000000002','a1b30000-0000-4000-8000-000000000001','2025-01-01',123.45,'IQD');
CREATE TEMP TABLE m1b_legacy_snapshot AS SELECT pg_temp.m1b_snapshot() AS value;
\ir ../migrations/00024_commercial_catalog_reference_data.sql
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_legacy_snapshot),'F pro_business: legacy row, subscription and entity untouched; no abort');
ROLLBACK TO SAVEPOINT m1b_case;
RELEASE SAVEPOINT m1b_case;
SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'F pro_business: zero residual fixtures');

SELECT is(pg_temp.m1b_snapshot(),(SELECT value FROM m1b_original),'final complete data/security baseline preserved after all fixtures');
SELECT * FROM finish();
ROLLBACK;
