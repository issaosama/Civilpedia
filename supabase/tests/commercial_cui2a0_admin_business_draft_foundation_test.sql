-- CUI-2A0 frozen T01-T34 / T32A-H and Security Addendum ACL-01-ACL-14.
-- Run ONLY in a fresh disposable local stack:
-- psql -v ON_ERROR_STOP=1 -v cui2a0_disposable=1 -v cui2a0_mode=unit -f this_file
-- Modes: unit, race, http_provision, cleanup, migration_rollback.
-- Run race controller as supabase_admin solely because local loopback pg_hba
-- uses trust and dblink rejects trust for a nonsuperuser controller. Both remote
-- production-call backends connect as postgres and switch to authenticated.
-- Real HTTP T34 / T32H uses ordinary and staff GoTrue tokens against that stack;
-- http_provision accepts their fixture UUIDs, never production credentials.
\if :{?cui2a0_disposable}
\else
\echo 'Explicit disposable-environment opt-in required.'
\quit 1
\endif
SELECT :'cui2a0_disposable'='1' AS has_disposable_opt_in \gset
\if :has_disposable_opt_in
\else
\echo 'Disposable opt-in must equal 1.'
\quit 1
\endif
\if :{?cui2a0_mode}
\else
\set cui2a0_mode unit
\endif
SELECT :'cui2a0_mode'='unit' AS is_unit,
       :'cui2a0_mode'='race' AS is_race,
       :'cui2a0_mode'='http_provision' AS is_http,
       :'cui2a0_mode'='cleanup' AS is_cleanup,
       :'cui2a0_mode'='migration_rollback' AS is_migration_rollback \gset
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET search_path=public,extensions,pg_temp;

-- Session-local harness: role switching is invoker-only, and no harness helper
-- or fixture authority is added to the production schema/function inventory.
CREATE FUNCTION pg_temp.cui_call(p_role text,p_actor uuid,p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $test$
DECLARE v_result jsonb; v_state text; v_message text; v_detail text; v_hint text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub',COALESCE(p_actor::text,''),true);
  PERFORM pg_catalog.set_config('request.jwt.claims',pg_catalog.jsonb_build_object('sub',p_actor)::text,true);
  PERFORM pg_catalog.set_config('role',p_role,true);
  EXECUTE p_sql INTO v_result;
  PERFORM pg_catalog.set_config('role','none',true);
  RETURN pg_catalog.jsonb_build_object('state','00000','result',v_result);
EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT,
    v_detail=PG_EXCEPTION_DETAIL,v_hint=PG_EXCEPTION_HINT;
  PERFORM pg_catalog.set_config('role','none',true);
  RETURN pg_catalog.jsonb_build_object('state',v_state,'message',v_message,'detail',v_detail,'hint',v_hint);
END;
$test$;
CREATE FUNCTION pg_temp.cui_payload(p_type text DEFAULT 'company') RETURNS jsonb
LANGUAGE sql IMMUTABLE AS $test$
SELECT jsonb_build_object('entity_type',p_type,'name',E'A0%_\\ literal','description','Private fixture body',
 'contacts',jsonb_build_array(
   jsonb_build_object('contact_type','phone','value','+964 123456','is_primary',true),
   jsonb_build_object('contact_type','email','value','Fixture@example.invalid','is_primary',false)),
 'categories',jsonb_build_array(
   jsonb_build_object('category_id','c2a00020-0000-4000-8000-000000000001','is_primary',true),
   jsonb_build_object('category_id','c2a00020-0000-4000-8000-000000000002','is_primary',false)),
 'primary_location',jsonb_build_object('region_id','c2a00030-0000-4000-8000-000000000001',
   'address','Private fixture address','latitude',33.123456,'longitude',44.123456))
$test$;
CREATE FUNCTION pg_temp.cui_create(p_payload jsonb,p_request uuid DEFAULT gen_random_uuid(),
  p_reason text DEFAULT 'BUSINESS_SUPPLIED_INFORMATION',p_actor uuid DEFAULT 'c2a00001-0000-4000-8000-000000000001')
RETURNS jsonb LANGUAGE sql AS $test$
 SELECT pg_temp.cui_call('authenticated',p_actor,format(
   'SELECT public.staff_create_business_draft(%L::uuid,%L::jsonb,%L)',p_request,p_payload,p_reason))
$test$;
CREATE FUNCTION pg_temp.cui_update(p_entity uuid,p_payload jsonb,p_expected timestamptz DEFAULT NULL)
RETURNS jsonb LANGUAGE sql AS $test$
 SELECT pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',format(
  'SELECT public.staff_update_business_draft(%L::uuid,%L::timestamptz,%L::uuid,%L::jsonb,%L)',
   p_entity,COALESCE(p_expected,(SELECT updated_at FROM public.directory_entities WHERE id=p_entity)),
   gen_random_uuid(),p_payload,'CORRECT_DRAFT_INFORMATION'))
$test$;
CREATE FUNCTION pg_temp.cui_detail(p_entity uuid) RETURNS jsonb LANGUAGE sql AS $test$
 SELECT pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',
   format('SELECT public.get_staff_business_entity_detail(%L::uuid)',p_entity))->'result'
$test$;
CREATE FUNCTION pg_temp.cui_audit(p_entity uuid) RETURNS jsonb LANGUAGE sql AS $test$
 SELECT pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',
   format('SELECT public.list_staff_business_entity_audit(%L::uuid)',p_entity))
$test$;

\if :is_unit
SELECT no_plan();
SELECT is((SELECT count(*)::integer FROM public.permissions WHERE permissions.code LIKE 'business_entities.%'),4,'T01 exactly four references');
SELECT is((SELECT count(*)::integer FROM public.role_permissions rp JOIN public.roles r ON r.id=rp.role_id
 JOIN public.permissions p ON p.id=rp.permission_id WHERE r.code='application_reviewer' AND p.code LIKE 'business_entities.%'),
 0,'T01 no automatic application_reviewer grant');
SELECT is((SELECT count(*)::integer FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='business_admin_private'),2,'T02 exactly two private helpers');
SELECT is((SELECT count(*)::integer FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname='business_admin_private' AND c.relkind='r'),1,'T02 one receipt table');
SELECT is((SELECT count(*)::integer FROM pg_proc WHERE oid IN (
 'public.get_staff_business_capabilities()'::regprocedure,
 'public.list_staff_business_entities(text,text,text,integer,timestamptz,uuid)'::regprocedure,
 'public.get_staff_business_entity_detail(uuid)'::regprocedure,
 'public.staff_create_business_draft(uuid,jsonb,text)'::regprocedure,
 'public.staff_update_business_draft(uuid,timestamptz,uuid,jsonb,text)'::regprocedure,
 'public.list_staff_business_entity_audit(uuid,integer,timestamptz,uuid)'::regprocedure)),6,'T02 six exact signatures');
SELECT is((SELECT count(*)::integer FROM pg_class WHERE relname IN(
 'idx_directory_entities_cui2a0_staff_page','idx_audit_logs_cui2a0_entity_page','uq_audit_logs_cui2a0_draft_create')),
 3,'T02 exact three explicit indexes');
SELECT ok(NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='business_admin_private.draft_create_requests'::regclass AND contype='f'),'T02 receipt has no FK');
SELECT ok(NOT EXISTS(SELECT 1 FROM pg_policy WHERE polrelid='business_admin_private.draft_create_requests'::regclass),'T14 no receipt policies');
SELECT ok((SELECT relrowsecurity AND NOT relforcerowsecurity FROM pg_class WHERE oid='business_admin_private.draft_create_requests'::regclass),'T14 receipt RLS');
SELECT ok(NOT EXISTS(SELECT 1 FROM pg_publication_tables WHERE schemaname='business_admin_private'),'T30 no private Realtime publication');

-- ACL-01 PUBLIC is an ACL grantee, not an impersonatable PostgreSQL role.
SELECT ok(NOT EXISTS(SELECT 1 FROM pg_proc p CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) a
 WHERE p.oid='public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)'::regprocedure AND a.grantee=0 AND a.privilege_type='EXECUTE'),'ACL-01 PUBLIC denied');
SELECT ok(NOT has_function_privilege('anon','public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)','EXECUTE'),'ACL-02 anon denied');
SELECT ok(NOT has_function_privilege('authenticated','public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)','EXECUTE'),'ACL-03 authenticated denied');
SELECT ok(NOT has_function_privilege('service_role','public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)','EXECUTE'),'ACL-04 service_role denied');
SELECT ok(has_function_privilege('postgres','public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)','EXECUTE'),'ACL-05 owner allowed');
SELECT is(pg_get_userbyid(proowner),'postgres','ACL-09 owner') FROM pg_proc WHERE oid='public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)'::regprocedure;
SELECT ok(prosecdef,'ACL-10 SECURITY DEFINER') FROM pg_proc WHERE oid='public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)'::regprocedure;
SELECT is(proconfig,ARRAY['search_path=public, pg_temp'],'ACL-11 unchanged legacy search_path') FROM pg_proc WHERE oid='public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)'::regprocedure;
SELECT is(prosrc,$expected$
BEGIN
  INSERT INTO public.audit_logs (
    actor_user_id, action, target_type, target_id,
    before_data, after_data, reason
  ) VALUES (
    p_actor_user_id, p_action, p_target_type, p_target_id,
    p_before_data, p_after_data, p_reason
  );
END;
$expected$,'ACL-12 committed 00016 prosrc') FROM pg_proc WHERE oid='public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)'::regprocedure;

BEGIN;
INSERT INTO auth.users(id,email) VALUES
 ('c2a00001-0000-4000-8000-000000000001','staff@cui2a0.invalid'),
 ('c2a00001-0000-4000-8000-000000000002','ordinary@cui2a0.invalid'),
 ('c2a00001-0000-4000-8000-000000000003','other-staff@cui2a0.invalid');
INSERT INTO public.profiles(user_id,phone) VALUES
 ('c2a00001-0000-4000-8000-000000000001','123456'),
 ('c2a00001-0000-4000-8000-000000000002','123456'),
 ('c2a00001-0000-4000-8000-000000000003','123456');
INSERT INTO public.roles(id,code,name) VALUES('c2a00002-0000-4000-8000-000000000001','cui2a0_fixture_staff','Disposable A0 fixture');
INSERT INTO public.role_permissions SELECT 'c2a00002-0000-4000-8000-000000000001',id FROM public.permissions WHERE permissions.code LIKE 'business_entities.%';
INSERT INTO public.staff_memberships(user_id,role_id,effective_at) VALUES
 ('c2a00001-0000-4000-8000-000000000001','c2a00002-0000-4000-8000-000000000001',now()-interval '1 day'),
 ('c2a00001-0000-4000-8000-000000000003','c2a00002-0000-4000-8000-000000000001',now()-interval '1 day');
INSERT INTO public.directory_categories(id,code,name_ar,name_en) VALUES
 ('c2a00020-0000-4000-8000-000000000001','cui2a0_fixture_1','تجربة','Fixture 1'),
 ('c2a00020-0000-4000-8000-000000000002','cui2a0_fixture_2','تجربة','Fixture 2');
INSERT INTO public.regions(id,code,region_type,name_ar,name_en) VALUES
 ('c2a00030-0000-4000-8000-000000000001','cui2a0_fixture_country','country','تجربة','Fixture country');
INSERT INTO public.directory_entities(id,entity_type,name,lifecycle_status) VALUES
 ('c2a00040-0000-4000-8000-000000000001','engineering_office','Legacy private fixture','draft'),
 ('c2a00040-0000-4000-8000-000000000002','company','Legacy active fixture','active');
INSERT INTO public.entity_contacts(entity_id,contact_type,value) VALUES
 ('c2a00040-0000-4000-8000-000000000001','other','B preserved');
INSERT INTO public.entity_media(entity_id,media_type,url) VALUES
 ('c2a00040-0000-4000-8000-000000000001','logo','https://example.invalid/fixture.png');
COMMIT;
CREATE ROLE cui2a0_public_probe NOLOGIN;
SELECT is(pg_temp.cui_call('cui2a0_public_probe',NULL,
 'SELECT to_jsonb(public.append_audit_log(NULL,''forged'',''fixture'',NULL,''{}'',''{}'',''forged''))')->>'state',
 '42501','ACL-06 PUBLIC-only role cannot forge audit');
SELECT is(pg_temp.cui_call(role,'c2a00001-0000-4000-8000-000000000002',
 'SELECT to_jsonb(public.append_audit_log(NULL,''forged'',''fixture'',NULL,''{}'',''{}'',''forged''))')->>'state',
 '42501','ACL-06/ACL-14 direct audit denial '||role) FROM unnest(ARRAY['anon','authenticated','service_role']) role;
SELECT is((SELECT count(*)::integer FROM public.audit_logs WHERE action='forged'),0,'ACL-14 no forged actor/action/target/before/after/reason event');

CREATE TEMP TABLE cui_state(k text PRIMARY KEY,v jsonb);
INSERT INTO cui_state VALUES('create',pg_temp.cui_create(pg_temp.cui_payload(),'c2a00050-0000-4000-8000-000000000001'));
CREATE FUNCTION pg_temp.cui_id() RETURNS uuid LANGUAGE sql AS $test$
 SELECT (v->'result'->>'entity_id')::uuid FROM pg_temp.cui_state WHERE k='create'
$test$;
SELECT is(v->>'state','00000','T06 authorized create') FROM cui_state WHERE k='create';
SELECT is(v->'result'->>'outcome','CREATED','T06 created receipt') FROM cui_state WHERE k='create';
SELECT is((SELECT lifecycle_status||'/'||verification_status||'/'||claim_status FROM public.directory_entities WHERE id=pg_temp.cui_id()),'draft/unverified/unclaimed','T06 forced truthful statuses');
SELECT is((SELECT count(*)::integer FROM business_admin_private.draft_create_requests WHERE entity_id=pg_temp.cui_id()),1,'T06 one receipt');
SELECT is((SELECT count(*)::integer FROM public.audit_logs WHERE target_id=pg_temp.cui_id()),1,'T06 one create audit');
SELECT is((SELECT count(*)::integer FROM public.business_memberships WHERE entity_id=pg_temp.cui_id()),0,'T08 ownerless');
SELECT is((SELECT count(*)::integer FROM public.subscriptions WHERE entity_id=pg_temp.cui_id()),0,'T08 no subscription');
SELECT is((SELECT count(*)::integer FROM public.business_applications WHERE target_entity_id=pg_temp.cui_id()),0,'T08 no application');
SELECT is((SELECT count(*)::integer FROM public.entity_media WHERE entity_id=pg_temp.cui_id()),0,'T08 no media');

CREATE FUNCTION pg_temp.cui_permissions() RETURNS SETOF text LANGUAGE plpgsql AS $test$
<<cui_permissions>>
DECLARE cmd text; kind text; code text; r jsonb; q text;
  cmds text[]:=ARRAY[
    'SELECT public.list_staff_business_entities()',
    format('SELECT public.get_staff_business_entity_detail(%L::uuid)',pg_temp.cui_id()),
    format('SELECT public.staff_create_business_draft(%L::uuid,%L::jsonb,%L)',gen_random_uuid(),pg_temp.cui_payload(),'BUSINESS_SUPPLIED_INFORMATION'),
    format('SELECT public.staff_update_business_draft(%L::uuid,%L::timestamptz,%L::uuid,%L::jsonb,%L)',
      pg_temp.cui_id(),(SELECT updated_at FROM public.directory_entities WHERE id=pg_temp.cui_id()),gen_random_uuid(),pg_temp.cui_payload(),'CORRECT_DRAFT_INFORMATION'),
    format('SELECT public.list_staff_business_entity_audit(%L::uuid)',pg_temp.cui_id())];
BEGIN
  RETURN NEXT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000002','SELECT public.get_staff_business_capabilities()')->'result',
    '{"capabilities":[]}'::jsonb,'T03 ordinary discovery empty');
  FOREACH cmd IN ARRAY cmds LOOP
    RETURN NEXT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000002',cmd)->>'state','P0PER','T03 ordinary denied');
    RETURN NEXT is(pg_temp.cui_call('authenticated',NULL,cmd)->>'state','P0AUT','T03 executable empty-auth denied');
    RETURN NEXT is(pg_temp.cui_call('anon',NULL,cmd)->>'state','42501','T14 anon ACL denied');
  END LOOP;
  FOREACH kind IN ARRAY ARRAY['OWNER','ADMIN','MEMBER'] LOOP
    INSERT INTO public.business_memberships(user_id,entity_id,role) VALUES('c2a00001-0000-4000-8000-000000000002','c2a00040-0000-4000-8000-000000000001',kind);
    FOREACH cmd IN ARRAY cmds LOOP
      RETURN NEXT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000002',cmd)->>'state','P0PER','T03 business '||kind||' has no staff authority');
    END LOOP;
    DELETE FROM public.business_memberships WHERE user_id='c2a00001-0000-4000-8000-000000000002';
  END LOOP;
  FOREACH kind IN ARRAY ARRAY['inactive','future','expired','revoked'] LOOP
    UPDATE public.staff_memberships SET is_active=kind<>'inactive',
      effective_at=CASE WHEN kind='future' THEN clock_timestamp()+interval '1 hour' ELSE clock_timestamp()-interval '2 hours' END,
      expires_at=CASE WHEN kind='expired' THEN clock_timestamp()-interval '1 hour' ELSE NULL END
      WHERE user_id='c2a00001-0000-4000-8000-000000000001';
    IF kind='revoked' THEN DELETE FROM public.role_permissions WHERE role_id='c2a00002-0000-4000-8000-000000000001'; END IF;
    FOREACH cmd IN ARRAY cmds LOOP
      RETURN NEXT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',cmd)->>'state','P0PER','T04 '||kind||' denied');
    END LOOP;
    IF kind='revoked' THEN INSERT INTO public.role_permissions SELECT 'c2a00002-0000-4000-8000-000000000001',id FROM public.permissions WHERE permissions.code LIKE 'business_entities.%'; END IF;
  END LOOP;
  UPDATE public.staff_memberships SET is_active=true,effective_at=now(),expires_at=NULL WHERE user_id='c2a00001-0000-4000-8000-000000000001';
  FOREACH code IN ARRAY ARRAY['read','create_draft','edit_draft','read_audit'] LOOP
    DELETE FROM public.role_permissions WHERE role_id='c2a00002-0000-4000-8000-000000000001';
    INSERT INTO public.role_permissions SELECT 'c2a00002-0000-4000-8000-000000000001',id FROM public.permissions WHERE permissions.code='business_entities.'||cui_permissions.code;
    RETURN NEXT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001','SELECT public.get_staff_business_capabilities()')->'result',
      jsonb_build_object('capabilities',jsonb_build_array('business_entities.'||code)),'T05 independent capability '||code);
    FOR q IN SELECT unnest(cmds) LOOP
      r:=pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',q);
      RETURN NEXT is(r->>'state',CASE
        WHEN code='read' AND (q LIKE '%list_staff_business_entities%' OR q LIKE '%get_staff_business_entity_detail%') THEN '00000'
        WHEN code='create_draft' AND q LIKE '%staff_create_business_draft%' THEN '00000'
        WHEN code='edit_draft' AND q LIKE '%staff_update_business_draft%' THEN '00000'
        WHEN code='read_audit' AND q LIKE '%list_staff_business_entity_audit%' THEN '00000'
        ELSE 'P0PER' END,'T05 permission works alone');
    END LOOP;
  END LOOP;
  DELETE FROM public.role_permissions WHERE role_id='c2a00002-0000-4000-8000-000000000001';
  INSERT INTO public.role_permissions SELECT 'c2a00002-0000-4000-8000-000000000001',id FROM public.permissions WHERE permissions.code LIKE 'business_entities.%';
END;
$test$;
SELECT * FROM pg_temp.cui_permissions();


-- T07/T10/T11/T12: malformed caller input is tested through BOTH mutation RPCs.
CREATE FUNCTION pg_temp.cui_invalid_inputs() RETURNS SETOF text LANGUAGE plpgsql AS $test$
DECLARE p jsonb; item jsonb; key text; code text; i integer; before_count bigint;
  bad jsonb[]:=ARRAY[
    'null'::jsonb,'[]'::jsonb,'{}'::jsonb,
    pg_temp.cui_payload()-'description',
    jsonb_set(pg_temp.cui_payload(),'{name}','null'),
    jsonb_set(pg_temp.cui_payload(),'{name}','""'),
    jsonb_set(pg_temp.cui_payload(),'{name}','"   "'),
    jsonb_set(pg_temp.cui_payload(),'{name}',to_jsonb(repeat('n',161))),
    jsonb_set(pg_temp.cui_payload(),'{description}',to_jsonb(repeat('d',2001))),
    jsonb_set(pg_temp.cui_payload(),'{description}','true'),
    jsonb_set(pg_temp.cui_payload(),'{contacts}','null'),
    jsonb_set(pg_temp.cui_payload(),'{contacts}','{}'),
    jsonb_set(pg_temp.cui_payload(),'{categories}','null'),
    jsonb_set(pg_temp.cui_payload(),'{contacts}',jsonb_build_array(pg_temp.cui_payload()->'contacts'->0,pg_temp.cui_payload()->'contacts'->0)),
    jsonb_set(pg_temp.cui_payload(),'{categories}',jsonb_build_array(pg_temp.cui_payload()->'categories'->0,pg_temp.cui_payload()->'categories'->0)),
    jsonb_set(pg_temp.cui_payload(),'{categories,1,is_primary}','true'),
    jsonb_set(pg_temp.cui_payload(),'{contacts,0,is_primary}','"true"'),
    jsonb_set(pg_temp.cui_payload(),'{contacts,0,value}','"ab"'),
    jsonb_set(pg_temp.cui_payload(),'{contacts,1,value}','"bad-email"'),
    jsonb_set(pg_temp.cui_payload(),'{contacts,0,contact_type}','"fax"'),
    jsonb_set(pg_temp.cui_payload(),'{contacts,0,contact_type}','"website"'),
    jsonb_set(pg_temp.cui_payload(),'{categories,0,category_id}','"invalid"'),
    jsonb_set(pg_temp.cui_payload(),'{categories,0,category_id}','"00000000-0000-0000-0000-000000000000"'),
    jsonb_set(pg_temp.cui_payload(),'{categories,0,category_id}','"c2a00020-0000-4000-8000-000000000099"'),
    jsonb_set(pg_temp.cui_payload(),'{primary_location}','{}'),
    jsonb_set(pg_temp.cui_payload(),'{primary_location,region_id}','"c2a00030-0000-4000-8000-000000000099"'),
    jsonb_set(pg_temp.cui_payload(),'{primary_location,region_id}','"00000000-0000-0000-0000-000000000000"'),
    jsonb_set(pg_temp.cui_payload(),'{primary_location,latitude}','"33"'),
    jsonb_set(pg_temp.cui_payload(),'{primary_location,latitude}','"NaN"'),
    jsonb_set(pg_temp.cui_payload(),'{primary_location,latitude}','91'),
    jsonb_set(pg_temp.cui_payload(),'{primary_location,longitude}','181'),
    jsonb_set(pg_temp.cui_payload(),'{primary_location,latitude}','33.1234567'),
    jsonb_set(pg_temp.cui_payload(),'{primary_location,longitude}','null'),
    jsonb_set(pg_temp.cui_payload(),'{primary_location,address}',to_jsonb(repeat('a',501))),
    jsonb_set(pg_temp.cui_payload(),'{primary_location}','{"region_id":null,"address":" ","latitude":null,"longitude":null}'),
    jsonb_set(pg_temp.cui_payload(),'{contacts,0}',(pg_temp.cui_payload()->'contacts'->0)-'value'),
    jsonb_set(pg_temp.cui_payload(),'{contacts,0}',(pg_temp.cui_payload()->'contacts'->0)||'{"id":"c2a00040-0000-4000-8000-000000000001"}'),
    jsonb_set(pg_temp.cui_payload(),'{categories,0}',(pg_temp.cui_payload()->'categories'->0)||'{"entity_id":"c2a00040-0000-4000-8000-000000000001"}'),
    jsonb_set(pg_temp.cui_payload(),'{primary_location}',(pg_temp.cui_payload()->'primary_location')||'{"id":"c2a00040-0000-4000-8000-000000000001"}'),
    jsonb_set(pg_temp.cui_payload(),'{contacts}',(SELECT jsonb_agg(pg_temp.cui_payload()->'contacts'->0) FROM generate_series(1,11))),
    jsonb_set(pg_temp.cui_payload(),'{categories}',(SELECT jsonb_agg(pg_temp.cui_payload()->'categories'->0) FROM generate_series(1,11)))];
BEGIN
  SELECT count(*) INTO before_count FROM business_admin_private.draft_create_requests;
  FOREACH key IN ARRAY ARRAY['lifecycle_status','verification_status','claim_status','actor_user_id','owner_user_id',
      'memberships','subscriptions','media','publication','entity_id','payload_hash'] LOOP
    bad:=array_append(bad,pg_temp.cui_payload()||jsonb_build_object(key,'forged'));
  END LOOP;
  FOREACH code IN ARRAY ARRAY['engineering_office','technician','laboratory','equipment_provider','service_provider','invalid','Company'] LOOP
    bad:=array_append(bad,jsonb_set(pg_temp.cui_payload(),'{entity_type}',to_jsonb(code)));
  END LOOP;
  FOREACH p IN ARRAY bad LOOP
    RETURN NEXT is(pg_temp.cui_create(p)->>'state','P0DAT','T07/T10-T12 invalid create '||array_position(bad,p));
    RETURN NEXT is(pg_temp.cui_update(pg_temp.cui_id(),p)->>'state','P0DAT','T07/T10-T12 invalid update '||array_position(bad,p));
  END LOOP;
  UPDATE public.directory_categories SET is_active=false WHERE id='c2a00020-0000-4000-8000-000000000001';
  RETURN NEXT is(pg_temp.cui_create(pg_temp.cui_payload())->>'state','P0DAT','T11 inactive category create');
  RETURN NEXT is(pg_temp.cui_update(pg_temp.cui_id(),jsonb_set(pg_temp.cui_payload(),'{name}','"changed"'))->>'state','P0DAT','T11 inactive category update');
  UPDATE public.directory_categories SET is_active=true WHERE id='c2a00020-0000-4000-8000-000000000001';
  UPDATE public.regions SET is_active=false WHERE id='c2a00030-0000-4000-8000-000000000001';
  RETURN NEXT is(pg_temp.cui_create(pg_temp.cui_payload())->>'state','P0DAT','T12 inactive region');
  UPDATE public.regions SET is_active=true WHERE id='c2a00030-0000-4000-8000-000000000001';
  RETURN NEXT is((SELECT count(*) FROM business_admin_private.draft_create_requests),before_count,'T11 rejected creates leave no reservation');
END;
$test$;
SELECT * FROM pg_temp.cui_invalid_inputs();
SELECT is(pg_temp.cui_create(jsonb_set(pg_temp.cui_payload(),'{name}',to_jsonb(repeat('n',65537))))->>'state','P0DAT','T12 payload bytes >65536');
SELECT is(pg_temp.cui_create(pg_temp.cui_payload(code))->>'state','00000','T10 author type '||code)
 FROM unnest(ARRAY['company','contractor','supplier','store']) code;
SELECT ok(public.is_valid_directory_entity_type(code),'T10 canonical validator retains '||code)
 FROM unnest(ARRAY['company','contractor','supplier','store','engineering_office','technician','laboratory','equipment_provider','service_provider']) code;
SELECT is(pg_temp.cui_detail('c2a00040-0000-4000-8000-000000000001')->'entity'->>'entity_type','engineering_office','T10 excluded author type remains readable');

CREATE FUNCTION pg_temp.cui_snapshot(p_id uuid) RETURNS jsonb LANGUAGE sql AS $test$
 SELECT jsonb_build_object('entity',(SELECT to_jsonb(e) FROM public.directory_entities e WHERE id=p_id),
 'contacts',(SELECT jsonb_agg(to_jsonb(c) ORDER BY id) FROM public.entity_contacts c WHERE entity_id=p_id),
 'categories',(SELECT jsonb_agg(to_jsonb(c) ORDER BY category_id) FROM public.directory_entity_categories c WHERE entity_id=p_id),
 'locations',(SELECT jsonb_agg(to_jsonb(c) ORDER BY id) FROM public.entity_locations c WHERE entity_id=p_id),
 'media',(SELECT jsonb_agg(to_jsonb(c) ORDER BY id) FROM public.entity_media c WHERE entity_id=p_id),
 'audit',(SELECT jsonb_agg(to_jsonb(c) ORDER BY id) FROM public.audit_logs c WHERE target_id=p_id))
$test$;
INSERT INTO cui_state VALUES('noop_before',pg_temp.cui_snapshot(pg_temp.cui_id())),
 ('b_before',pg_temp.cui_snapshot('c2a00040-0000-4000-8000-000000000001'));
SELECT is(pg_temp.cui_update(pg_temp.cui_id(),pg_temp.cui_payload())->'result'->>'outcome','UNCHANGED','T16 no-op succeeds');
SELECT is(pg_temp.cui_snapshot(pg_temp.cui_id()),(SELECT v FROM cui_state WHERE k='noop_before'),'T16 no writes/token/child IDs/audit');
INSERT INTO cui_state VALUES('old_token',to_jsonb((SELECT updated_at FROM public.directory_entities WHERE id=pg_temp.cui_id())));
SELECT is(pg_temp.cui_update(pg_temp.cui_id(),jsonb_set(pg_temp.cui_payload(),'{name}','"Material update"'))->'result'->>'outcome','UPDATED','T15 scalar material update');
SELECT ok((SELECT updated_at FROM public.directory_entities WHERE id=pg_temp.cui_id())>
 ((SELECT v FROM cui_state WHERE k='old_token')#>>'{}')::timestamptz,'T15 returned token advances');
SELECT is(pg_temp.cui_update(pg_temp.cui_id(),pg_temp.cui_payload(),((SELECT v FROM cui_state WHERE k='old_token')#>>'{}')::timestamptz)->>'state','P0CON','T15 stale version');
SELECT is(pg_temp.cui_update(pg_temp.cui_id(),pg_temp.cui_payload())->'result'->>'outcome','UPDATED','T15 restore material profile');
INSERT INTO cui_state VALUES('child_token',to_jsonb((SELECT updated_at FROM public.directory_entities WHERE id=pg_temp.cui_id())));
SELECT is(pg_temp.cui_update(pg_temp.cui_id(),jsonb_set(pg_temp.cui_payload(),'{contacts}','[]'))->'result'->>'outcome','UPDATED','T15 child-only edit');
SELECT ok((SELECT updated_at FROM public.directory_entities WHERE id=pg_temp.cui_id())>
 ((SELECT v FROM cui_state WHERE k='child_token')#>>'{}')::timestamptz,'T15 child-only token advances');
SELECT is(pg_temp.cui_update(pg_temp.cui_id(),pg_temp.cui_payload())->'result'->>'outcome','UPDATED','T15 restore children');
SELECT is(pg_temp.cui_update(pg_temp.cui_id(),pg_temp.cui_payload()||'{"description":null,"contacts":[],"categories":[],"primary_location":null}')->'result'->>'outcome',
 'UPDATED','T13 clear optional groups');
SELECT is(pg_temp.cui_update(pg_temp.cui_id(),pg_temp.cui_payload())->'result'->>'outcome','UPDATED','T13 primary location upsert');
SELECT is(pg_temp.cui_snapshot('c2a00040-0000-4000-8000-000000000001'),(SELECT v FROM cui_state WHERE k='b_before'),'T08/T18 B and media unchanged');

-- Eligibility predicates are tested independently, with fixture state restored.
CREATE FUNCTION pg_temp.cui_ineligible() RETURNS SETOF text LANGUAGE plpgsql AS $test$
DECLARE key text; val text; snap jsonb;
BEGIN
  FOREACH key IN ARRAY ARRAY['lifecycle_status','verification_status','claim_status','entity_type'] LOOP
    FOREACH val IN ARRAY CASE key WHEN 'lifecycle_status' THEN ARRAY['active','inactive','suspended']
      WHEN 'verification_status' THEN ARRAY['pending','verified','rejected']
      WHEN 'claim_status' THEN ARRAY['pending','claimed'] ELSE ARRAY['engineering_office'] END LOOP
      EXECUTE format('UPDATE public.directory_entities SET %I=%L WHERE id=$1',key,val) USING pg_temp.cui_id();
      snap:=pg_temp.cui_snapshot(pg_temp.cui_id());
      RETURN NEXT is(pg_temp.cui_update(pg_temp.cui_id(),pg_temp.cui_payload())->>'state','P0TRA','T17 '||key||'='||val);
      RETURN NEXT is(pg_temp.cui_snapshot(pg_temp.cui_id()),snap,'T17 rejected transition preserved');
      EXECUTE format('UPDATE public.directory_entities SET %I=%L WHERE id=$1',key,
        CASE key WHEN 'lifecycle_status' THEN 'draft' WHEN 'verification_status' THEN 'unverified'
          WHEN 'claim_status' THEN 'unclaimed' ELSE 'company' END) USING pg_temp.cui_id();
    END LOOP;
  END LOOP;
  INSERT INTO public.business_memberships(user_id,entity_id,role) VALUES('c2a00001-0000-4000-8000-000000000002',pg_temp.cui_id(),'OWNER');
  RETURN NEXT is(pg_temp.cui_update(pg_temp.cui_id(),pg_temp.cui_payload())->>'state','P0TRA','T17 any membership denies');
  DELETE FROM public.business_memberships WHERE entity_id=pg_temp.cui_id();
  INSERT INTO public.entity_contacts(entity_id,contact_type,value)
    SELECT pg_temp.cui_id(),'other','extra-'||i FROM generate_series(1,9) i;
  RETURN NEXT is(pg_temp.cui_update(pg_temp.cui_id(),pg_temp.cui_payload())->>'state','P0TRA','T17 >10 contacts denies');
  DELETE FROM public.entity_contacts WHERE entity_id=pg_temp.cui_id() AND contact_type='other';
  RETURN NEXT is(pg_temp.cui_update('c2a00040-0000-4000-8000-000000000001',pg_temp.cui_payload())->>'state','P0TRA','T17 legacy origin denies');
  INSERT INTO public.entity_locations(entity_id,address,is_primary) VALUES(pg_temp.cui_id(),'Preserved extra location',false);
  snap:=pg_temp.cui_snapshot(pg_temp.cui_id());
  RETURN NEXT is(pg_temp.cui_detail(pg_temp.cui_id())->>'location_scope_complete','false','T22 truthful extra-location scope');
  RETURN NEXT is(pg_temp.cui_detail(pg_temp.cui_id())->'draft_authoring'->>'can_edit_draft','false','T22 extra-location read-only');
  RETURN NEXT is(pg_temp.cui_update(pg_temp.cui_id(),pg_temp.cui_payload())->>'state','P0TRA','T18 extra-location no-op denies');
  RETURN NEXT is(pg_temp.cui_update(pg_temp.cui_id(),jsonb_set(pg_temp.cui_payload(),'{name}','"blocked"'))->>'state','P0TRA','T18 entire material edit denies');
  RETURN NEXT is(pg_temp.cui_snapshot(pg_temp.cui_id()),snap,'T18 every parent/child/audit byte preserved');
  DELETE FROM public.entity_locations WHERE entity_id=pg_temp.cui_id() AND NOT is_primary;
END;
$test$;
SELECT * FROM pg_temp.cui_ineligible();

-- T19/T23 exact scoped audit projection and corruption is fail-closed.
SELECT ok(NOT (pg_temp.cui_audit(pg_temp.cui_id())->'result')::text LIKE ANY(
 ARRAY['%Private fixture body%','%Fixture@example.invalid%','%payload_hash%','%Private fixture address%']),'T19 no raw PII/hash audit projection');
SELECT is((SELECT count(*)::integer FROM public.audit_logs WHERE target_id=pg_temp.cui_id() AND actor_user_id='c2a00001-0000-4000-8000-000000000001'),7,'T19 one create + six material edits');
CREATE FUNCTION pg_temp.cui_corrupt_audit() RETURNS SETOF text LANGUAGE plpgsql AS $test$
<<cui_corrupt_audit>>
DECLARE id uuid; original jsonb; snap jsonb;
BEGIN
 SELECT a.id,a.after_data INTO id,original FROM public.audit_logs a WHERE a.target_id=pg_temp.cui_id() AND action='business_entity.draft_create';
 UPDATE public.audit_logs a SET after_data=original||'{"raw_profile":"secret"}' WHERE a.id=cui_corrupt_audit.id;
 RETURN NEXT is(pg_temp.cui_audit(pg_temp.cui_id())->>'state','P0INV','T23 extra raw field rejected');
 RETURN NEXT is(pg_temp.cui_create(pg_temp.cui_payload(),'c2a00050-0000-4000-8000-000000000001')->>'state','P0INV','T25 corrupt original no replay/repair');
 UPDATE public.audit_logs a SET after_data=original WHERE a.id=cui_corrupt_audit.id;
 INSERT INTO public.audit_logs(action,target_type,target_id,after_data) VALUES('legacy.event','directory_entity',pg_temp.cui_id(),'{"raw":"secret"}');
 RETURN NEXT is(jsonb_array_length(pg_temp.cui_audit(pg_temp.cui_id())->'result'->'items'),7,'T23 excludes legacy raw event');
 DELETE FROM public.audit_logs WHERE target_id=pg_temp.cui_id() AND action='legacy.event';
END;
$test$;
SELECT * FROM pg_temp.cui_corrupt_audit();
CREATE FUNCTION pg_temp.cui_reject_audit() RETURNS trigger LANGUAGE plpgsql AS $test$
BEGIN IF NEW.action LIKE 'business_entity.draft_%' THEN RAISE EXCEPTION 'fixture audit failure'; END IF; RETURN NEW; END;
$test$;
CREATE TRIGGER cui2a0_fixture_audit_failure BEFORE INSERT ON public.audit_logs FOR EACH ROW EXECUTE FUNCTION pg_temp.cui_reject_audit();
INSERT INTO cui_state VALUES('failure_before',pg_temp.cui_snapshot(pg_temp.cui_id())),
 ('receipt_count',to_jsonb((SELECT count(*) FROM business_admin_private.draft_create_requests)));
SELECT is(pg_temp.cui_create(pg_temp.cui_payload())->>'state','P0AUD','T20 create audit failure');
SELECT is(pg_temp.cui_update(pg_temp.cui_id(),jsonb_set(pg_temp.cui_payload(),'{contacts}','[]'))->>'state','P0AUD','T20 update audit failure');
SELECT is(pg_temp.cui_snapshot(pg_temp.cui_id()),(SELECT v FROM cui_state WHERE k='failure_before'),'T20 update wholly rolled back');
SELECT is(to_jsonb((SELECT count(*) FROM business_admin_private.draft_create_requests)),(SELECT v FROM cui_state WHERE k='receipt_count'),'T20 reservation wholly rolled back');
DROP TRIGGER cui2a0_fixture_audit_failure ON public.audit_logs;
SELECT is(pg_temp.cui_create(pg_temp.cui_payload(),'c2a00050-0000-4000-8000-000000000001')->'result'->>'outcome','REPLAY','T24 replay historical receipt');
SELECT is(pg_temp.cui_create(jsonb_set(pg_temp.cui_payload(),'{contacts}',jsonb_build_array(pg_temp.cui_payload()->'contacts'->1,pg_temp.cui_payload()->'contacts'->0)),
 'c2a00050-0000-4000-8000-000000000001')->'result'->>'outcome','REPLAY','T24 reordered arrays canonicalize');
SELECT is(pg_temp.cui_create(jsonb_set(pg_temp.cui_payload(),'{name}','"different"'),'c2a00050-0000-4000-8000-000000000001')->>'state','P0RPL','T24 changed retained value conflicts');
SELECT is(pg_temp.cui_create(pg_temp.cui_payload(),'c2a00050-0000-4000-8000-000000000001','BUSINESS_AUTHORIZED_PREPARATION')->>'state','P0RPL','T24 changed allowed reason conflicts');
UPDATE public.directory_categories SET is_active=false WHERE id='c2a00020-0000-4000-8000-000000000001';
SELECT is(pg_temp.cui_create(pg_temp.cui_payload(),'c2a00050-0000-4000-8000-000000000001')->'result'->>'outcome','REPLAY','T25 taxonomy retirement retains historical receipt');
SELECT is(pg_temp.cui_detail(pg_temp.cui_id())->'categories'->0->>'is_active','false','T22 inactive label truthful');
UPDATE public.directory_categories SET is_active=true WHERE id='c2a00020-0000-4000-8000-000000000001';

-- T09/T14 direct reads and writes through actual client roles.
SELECT is(pg_temp.cui_call(role,'c2a00001-0000-4000-8000-000000000002',
 format('SELECT to_jsonb(count(*)) FROM public.directory_entities WHERE id=%L::uuid',pg_temp.cui_id()))->'result','0'::jsonb,'T09 private parent invisible '||role)
 FROM unnest(ARRAY['anon','authenticated']) role;
SELECT is(pg_temp.cui_call(role,'c2a00001-0000-4000-8000-000000000002',
 format('SELECT to_jsonb(count(*)) FROM public.%I WHERE entity_id=%L::uuid',tab,pg_temp.cui_id()))->'result','0'::jsonb,'T09 child invisible '||role||'/'||tab)
 FROM unnest(ARRAY['anon','authenticated']) role CROSS JOIN unnest(ARRAY['entity_contacts','entity_locations','directory_entity_categories','entity_media']) tab;
SELECT is(pg_temp.cui_call('anon',NULL,'SELECT to_jsonb(count(*)) FROM public.directory_entities WHERE id=''c2a00040-0000-4000-8000-000000000002''')->'result','1'::jsonb,'T09 active public remains visible');
SELECT is(pg_temp.cui_call(role,NULL,format('SELECT to_jsonb(count(*)) FROM %s',tab))->>'state','42501','T14 private authority denied '||role||'/'||tab)
 FROM unnest(ARRAY['anon','authenticated','service_role']) role CROSS JOIN
 unnest(ARRAY['business_admin_private.draft_create_requests','business_admin_private.normalize_draft_payload(''{}'')','business_admin_private.has_staff_business_permission(''business_entities.read'')']) tab;
SELECT ok(NOT has_table_privilege(role,tab,priv),'T14 no direct '||priv||' '||role||'/'||tab)
 FROM unnest(ARRAY['anon','authenticated']) role CROSS JOIN unnest(ARRAY['public.directory_entities','public.entity_contacts','public.entity_locations','public.directory_entity_categories','public.entity_media','public.business_applications','public.audit_logs']) tab
 CROSS JOIN unnest(ARRAY['INSERT','UPDATE','DELETE','TRUNCATE']) priv;
SELECT ok(NOT has_function_privilege(role,p.oid,'EXECUTE'),'T30 helpers/guard not client executable '||role||'/'||p.proname)
 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace CROSS JOIN unnest(ARRAY['anon','authenticated','service_role']) role
 WHERE n.nspname='business_admin_private' OR p.oid='public.guard_claim_application_insert()'::regprocedure;

-- T21 exact bounds, paired cursors and literal wildcard search.
SELECT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',format('SELECT public.list_staff_business_entities(p_limit := %s)',n))->>'state','P0DAT','T21 invalid list limit')
 FROM unnest(ARRAY['NULL','0','51','-1']) n;
SELECT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',format('SELECT public.list_staff_business_entity_audit(%L::uuid,%s)',pg_temp.cui_id(),n))->>'state','P0DAT','T21 invalid audit limit')
 FROM unnest(ARRAY['NULL','0','51','-1']) n;
SELECT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001','SELECT public.list_staff_business_entities(p_before_id:=gen_random_uuid())')->>'state','P0DAT','T21 paired cursor required');
SELECT is(jsonb_array_length(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',
 'SELECT public.list_staff_business_entities(p_search:=''A0%_\ literal'')')->'result'->'items'),6,'T21 percent underscore backslash literal search');
SELECT is(jsonb_array_length(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',
 'SELECT public.list_staff_business_entities(p_search:=''missing literal'')')->'result'->'items'),0,'T21 empty search result');
SELECT ok(pg_temp.cui_detail(pg_temp.cui_id())->>'location_scope_complete'='true','T22 normal location scope complete');
INSERT INTO public.entity_contacts(entity_id,contact_type,value)
 SELECT 'c2a00040-0000-4000-8000-000000000001','other','legacy-cap-'||i FROM generate_series(1,51) i;
SELECT is(jsonb_array_length(pg_temp.cui_detail('c2a00040-0000-4000-8000-000000000001')->'contacts'),50,'T22 cap 50');
SELECT is(pg_temp.cui_detail('c2a00040-0000-4000-8000-000000000001')->>'contacts_complete','false','T22 incomplete collection truthful');
DELETE FROM public.entity_contacts WHERE entity_id='c2a00040-0000-4000-8000-000000000001' AND value LIKE 'legacy-cap-%';

-- T30 deliberately shadow public tables in pg_temp; qualified production paths win.
CREATE TEMP TABLE directory_entities(id uuid,name text);
CREATE TEMP TABLE staff_memberships(user_id uuid,role_id uuid,is_active boolean,effective_at timestamptz,expires_at timestamptz);
SELECT is(pg_temp.cui_detail(pg_temp.cui_id())->'entity'->>'name',E'A0%_\\ literal','T30 temp shadow cannot redirect directory read');
DROP TABLE pg_temp.directory_entities,pg_temp.staff_memberships;

-- T32A-H legacy guard compatibility with actual trigger and nested audited RPC.
SELECT is(pg_temp.cui_call('postgres','c2a00001-0000-4000-8000-000000000002',format(
 'INSERT INTO public.business_applications(application_type,applicant_user_id,target_entity_id) VALUES(''CLAIM'',''c2a00001-0000-4000-8000-000000000002'',%L::uuid) RETURNING to_jsonb(id)',pg_temp.cui_id()))->>'state','P0CLM','T32A trusted INSERT hits normal trigger');
SELECT is(pg_temp.cui_call('authenticated',actor,format('SELECT to_jsonb(public.create_claim_business_application(%L::uuid))',pg_temp.cui_id()))->>'state','P0CLM','T32B staff/ordinary cannot bypass receipt')
 FROM unnest(ARRAY['c2a00001-0000-4000-8000-000000000001'::uuid,'c2a00001-0000-4000-8000-000000000002'::uuid]) actor;
SELECT is((SELECT count(*)::integer FROM public.business_applications WHERE target_entity_id=pg_temp.cui_id()),0,'T32C no failed CLAIM effects');
SELECT is((SELECT lifecycle_status||'/'||verification_status||'/'||claim_status FROM public.directory_entities WHERE id=pg_temp.cui_id()),'draft/unverified/unclaimed','T32D truthful unclaimed state preserved');
SELECT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000002',
 'SELECT to_jsonb(public.create_claim_business_application(''c2a00040-0000-4000-8000-000000000001''))')->>'state','00000','T32E legacy private Draft still claimable');
SELECT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000002',
 'SELECT to_jsonb(public.create_claim_business_application(''c2a00040-0000-4000-8000-000000000001''))')->>'state','23505','T32E duplicate live claim');
SELECT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000002',
 'SELECT to_jsonb(public.create_claim_business_application(NULL))')->>'state','P0DAT','T32E RPC null');
SELECT is(pg_temp.cui_call('postgres',NULL,
 'INSERT INTO public.business_applications(application_type,applicant_user_id,target_entity_id) VALUES(''CLAIM'',''c2a00001-0000-4000-8000-000000000002'',NULL) RETURNING to_jsonb(id)')->>'state','23514','T32E raw null CHECK preserved');
SELECT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000002',
 'SELECT to_jsonb(public.create_claim_business_application(''c2a00040-0000-4000-8000-000000000099''))')->>'state','23503','T32E absent target rejected before FK');
UPDATE public.directory_entities SET claim_status='claimed' WHERE id='c2a00040-0000-4000-8000-000000000002';
SELECT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000002',format('SELECT to_jsonb(public.create_claim_business_application(%L::uuid))',pg_temp.cui_id()))-'result',
 pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000002','SELECT to_jsonb(public.create_claim_business_application(''c2a00040-0000-4000-8000-000000000002''))')-'result','T32H identical state/message/empty detail/hint');
UPDATE public.directory_entities SET claim_status='unclaimed' WHERE id='c2a00040-0000-4000-8000-000000000002';
-- Remaining edge boundaries use isolated savepoints, not mutation retries.
CREATE FUNCTION pg_temp.cui_edges() RETURNS SETOF text LANGUAGE plpgsql AS $test$
DECLARE cmd text; p jsonb; original jsonb; event uuid; snap jsonb; page jsonb; cursor jsonb;
 ids uuid[]:='{}'; expected uuid[]; row jsonb; n integer; field text; value jsonb;
BEGIN
 -- Missing IDs cannot leak existence to an unprivileged caller.
 FOREACH cmd IN ARRAY ARRAY[
 'SELECT public.get_staff_business_entity_detail(''c2a00040-0000-4000-8000-000000000099'')',
 'SELECT public.list_staff_business_entity_audit(''c2a00040-0000-4000-8000-000000000099'')',
 format('SELECT public.staff_update_business_draft(''c2a00040-0000-4000-8000-000000000099'',now(),gen_random_uuid(),%L::jsonb,%L)',pg_temp.cui_payload(),'CORRECT_DRAFT_INFORMATION')] LOOP
   RETURN NEXT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000002',cmd)->>'state','P0PER','T03 guessed missing still permission denial');
   RETURN NEXT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',cmd)->>'state','P0NOT','T15 authorized missing target');
 END LOOP;
 RETURN NEXT is(pg_temp.cui_create(pg_temp.cui_payload(),NULL)->>'state','P0DAT','T12 null create request');
 RETURN NEXT is(pg_temp.cui_create(pg_temp.cui_payload(),'00000000-0000-0000-0000-000000000000')->>'state','P0DAT','T12 nil request');
 RETURN NEXT is(pg_temp.cui_create(pg_temp.cui_payload(),gen_random_uuid(),'arbitrary private reason')->>'state','P0DAT','T07 no free-form private reason');
 RETURN NEXT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',format(
  'SELECT public.staff_update_business_draft(%L::uuid,NULL,gen_random_uuid(),%L::jsonb,%L)',pg_temp.cui_id(),pg_temp.cui_payload(),'CORRECT_DRAFT_INFORMATION'))->>'state','P0DAT','T15 null expected timestamp');
 UPDATE public.staff_memberships SET effective_at=clock_timestamp()-interval '1 hour',expires_at=clock_timestamp()
 WHERE user_id='c2a00001-0000-4000-8000-000000000001';
 RETURN NEXT is(pg_temp.cui_create(pg_temp.cui_payload())->>'state','P0PER','T04 expiry equality is denied');
 UPDATE public.staff_memberships SET expires_at=NULL WHERE user_id='c2a00001-0000-4000-8000-000000000001';
 -- Every optional/reference boundary can be supplied without publication.
 p:=pg_temp.cui_payload()||jsonb_build_object('name',repeat('n',160),'description',repeat('d',2000),
 'contacts',(SELECT jsonb_agg(jsonb_build_object('contact_type','other','value','boundary-'||i,'is_primary',false)) FROM generate_series(1,10)i),
 'categories','[]'::jsonb,'primary_location',jsonb_build_object('region_id',NULL,'address',repeat('a',500),'latitude',-90,'longitude',180));
 RETURN NEXT is(pg_temp.cui_create(p)->>'state','00000','T10-T13 max name/description/contact/address and coordinate boundary accepted');
 RETURN NEXT is(pg_temp.cui_create(pg_temp.cui_payload()||'{"description":null,"contacts":[],"categories":[],"primary_location":null}')->>'state','00000','T13 minimal partial content permitted');
 -- Canonical duplicate variants and malformed nested keys.
 FOREACH p IN ARRAY ARRAY[
  jsonb_set(pg_temp.cui_payload(),'{contacts}',jsonb_build_array(
    jsonb_build_object('contact_type','email','value','Case@example.invalid','is_primary',false),
    jsonb_build_object('contact_type','email','value','case@example.invalid','is_primary',false))),
  jsonb_set(pg_temp.cui_payload(),'{contacts}',jsonb_build_array(
    jsonb_build_object('contact_type','phone','value','12345','is_primary',true),
    jsonb_build_object('contact_type','phone','value','56789','is_primary',true))),
  jsonb_set(pg_temp.cui_payload(),'{contacts,0,value}',to_jsonb(repeat('1',33))),
  jsonb_set(pg_temp.cui_payload(),'{contacts,1,value}',to_jsonb(repeat('a',243)||'@example.invalid')),
  jsonb_set(pg_temp.cui_payload(),'{contacts}',jsonb_build_array(jsonb_build_object('contact_type','website','value','ftp://invalid','is_primary',false))),
  jsonb_set(pg_temp.cui_payload(),'{categories,0,is_primary}','null'),
  jsonb_set(pg_temp.cui_payload(),'{primary_location,latitude}','true'),
  jsonb_set(pg_temp.cui_payload(),'{primary_location}',(pg_temp.cui_payload()->'primary_location')-'address')] LOOP
   RETURN NEXT is(pg_temp.cui_create(p)->>'state','P0DAT','T11 nested duplicate/bound/kind rejected');
   RETURN NEXT is(pg_temp.cui_update(pg_temp.cui_id(),p)->>'state','P0DAT','T11 update nested duplicate/bound/kind rejected');
 END LOOP;
 -- Any status legacy subscription is an exclusion, preserved by A0.
 INSERT INTO public.subscriptions(entity_id,plan_id,status,started_at)
 SELECT pg_temp.cui_id(),id,'canceled',now() FROM public.plans ORDER BY code LIMIT 1;
 snap:=pg_temp.cui_snapshot(pg_temp.cui_id());
 RETURN NEXT is(pg_temp.cui_update(pg_temp.cui_id(),pg_temp.cui_payload())->>'state','P0TRA','T17 canceled legacy subscription still excludes');
 RETURN NEXT is(pg_temp.cui_snapshot(pg_temp.cui_id()),snap,'T17 subscribed parent/children/audit preserved');
 DELETE FROM public.subscriptions WHERE entity_id=pg_temp.cui_id();
 -- Corrupt evidence must never produce a partial audit projection or replay.
 SELECT a.id,a.after_data INTO event,original FROM public.audit_logs a WHERE target_id=pg_temp.cui_id() AND action='business_entity.draft_create';
 FOREACH value IN ARRAY ARRAY[
   jsonb_set(original,'{contact_count}','null'),jsonb_set(original,'{contact_count}','11'),
   jsonb_set(original,'{request_id}','"00000000-0000-0000-0000-000000000000"'),
   jsonb_set(original,'{updated_at}','"infinity"'),
   jsonb_set(original,'{changed_fields}','["name","name"]'),
   jsonb_set(original,'{has_primary_location}','"true"')] LOOP
   UPDATE public.audit_logs SET after_data=value WHERE id=event;
   RETURN NEXT is(pg_temp.cui_audit(pg_temp.cui_id())->>'state','P0INV','T23 corrupt selected typed event fail-closed');
   RETURN NEXT is(pg_temp.cui_create(pg_temp.cui_payload(),'c2a00050-0000-4000-8000-000000000001')->>'state','P0INV','T25 corrupt historical receipt reference fails');
 END LOOP;
 UPDATE public.audit_logs SET after_data=original WHERE id=event;
 -- Missing original entity tested inside an exception subtransaction; restore
 -- the fixture rather than create/repair an orphan from the receipt.
 BEGIN
   DELETE FROM public.directory_entities WHERE id=pg_temp.cui_id();
   RETURN NEXT is(pg_temp.cui_create(pg_temp.cui_payload(),'c2a00050-0000-4000-8000-000000000001')->>'state','P0INV','T25 missing original entity no repair');
   RAISE SQLSTATE 'PTFIX';
 EXCEPTION WHEN SQLSTATE 'PTFIX' THEN NULL;
 END;
 -- List and audit paired finite non-nil cursors, all filters and limits.
 FOREACH cmd IN ARRAY ARRAY[
 'SELECT public.list_staff_business_entities(p_entity_type:=''invalid'')',
 'SELECT public.list_staff_business_entities(p_lifecycle_status:=''APPROVED'')',
 'SELECT public.list_staff_business_entities(p_search:=repeat(''s'',121))',
 'SELECT public.list_staff_business_entities(p_before_created_at:=''infinity'',p_before_id:=gen_random_uuid())',
 'SELECT public.list_staff_business_entities(p_before_created_at:=now(),p_before_id:=''00000000-0000-0000-0000-000000000000'')',
 format('SELECT public.list_staff_business_entity_audit(%L::uuid,1,NULL,gen_random_uuid())',pg_temp.cui_id()),
 format('SELECT public.list_staff_business_entity_audit(%L::uuid,1,''infinity'',gen_random_uuid())',pg_temp.cui_id())] LOOP
   RETURN NEXT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',cmd)->>'state','P0DAT','T21 invalid filter/cursor');
 END LOOP;
 -- Same timestamp UUID tie order and exhaustive fixed-filter pages.
 INSERT INTO public.directory_entities(id,entity_type,name,created_at)
 SELECT ('c2a00060-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,'company','CUI tie fixture',timestamptz '2026-01-01 UTC' FROM generate_series(1,53)i;
 SELECT array_agg(id ORDER BY created_at DESC,id DESC) INTO expected FROM public.directory_entities WHERE name='CUI tie fixture';
 cursor:='null'; ids:='{}';
 LOOP
   page:=pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',format(
     'SELECT public.list_staff_business_entities(%L,NULL,NULL,25,%L::timestamptz,%L::uuid)','CUI tie fixture',cursor->>'created_at',cursor->>'id'))->'result';
   RETURN NEXT ok(jsonb_array_length(page->'items')<=25,'T21 page default 25 bounded');
   FOR row IN SELECT jsonb_array_elements(page->'items') LOOP ids:=array_append(ids,(row->>'entity_id')::uuid); END LOOP;
   cursor:=page->'next_cursor'; EXIT WHEN cursor='null';
 END LOOP;
 RETURN NEXT is(ids,expected,'T21 no overlap/gap with same-time UUID tie pagination');
 DELETE FROM public.directory_entities WHERE name='CUI tie fixture' AND id::text LIKE 'c2a00060-%';
-- Typed audit pagination: same-time UUID tie order, default and max bounds.
 BEGIN
   INSERT INTO public.audit_logs(actor_user_id,action,target_type,target_id,before_data,after_data,reason)
   SELECT a.actor_user_id,a.action,a.target_type,a.target_id,a.before_data,
     jsonb_set(a.after_data,'{request_id}',to_jsonb(gen_random_uuid())),a.reason
   FROM (SELECT * FROM public.audit_logs WHERE target_id=pg_temp.cui_id() AND action='business_entity.draft_update' LIMIT 1) a
   CROSS JOIN generate_series(1,51);
   UPDATE public.audit_logs SET created_at=timestamptz '2026-01-02 UTC'
    WHERE target_id=pg_temp.cui_id() AND action IN('business_entity.draft_create','business_entity.draft_update');
   SELECT array_agg(id ORDER BY created_at DESC,id DESC) INTO expected FROM public.audit_logs
    WHERE target_id=pg_temp.cui_id() AND action IN('business_entity.draft_create','business_entity.draft_update');
   RETURN NEXT is(jsonb_array_length(pg_temp.cui_audit(pg_temp.cui_id())->'result'->'items'),25,'T21 audit default25');
   RETURN NEXT is(jsonb_array_length(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',
    format('SELECT public.list_staff_business_entity_audit(%L::uuid,50)',pg_temp.cui_id()))->'result'->'items'),50,'T21 audit max50 no overflow');
   cursor:='null'; ids:='{}';
   LOOP
     page:=pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',format(
       'SELECT public.list_staff_business_entity_audit(%L::uuid,25,%L::timestamptz,%L::uuid)',pg_temp.cui_id(),cursor->>'created_at',cursor->>'id'))->'result';
     FOR row IN SELECT jsonb_array_elements(page->'items') LOOP ids:=array_append(ids,(row->>'audit_id')::uuid); END LOOP;
     cursor:=page->'next_cursor'; EXIT WHEN cursor='null';
   END LOOP;
   RETURN NEXT is(ids,expected,'T21 typed audit pagination tie order/no overlap/end cursor');
   RAISE SQLSTATE 'PTFIX';
 EXCEPTION WHEN SQLSTATE 'PTFIX' THEN NULL;
 END;
END;
$test$;
SELECT * FROM pg_temp.cui_edges();
-- ACL-07 legacy nested SECURITY DEFINER callers retain owner EXECUTE.
-- T19 exact persisted typed event, actor/target/reason and ordered field list.
SELECT is((SELECT after_data FROM public.audit_logs WHERE target_id=pg_temp.cui_id() AND action='business_entity.draft_create'),
 jsonb_build_object('format_version','cui2a0.audit.v1','request_id','c2a00050-0000-4000-8000-000000000001',
 'changed_fields',jsonb_build_array('entity_type','name','description','contacts','categories','primary_location'),
 'updated_at',(SELECT updated_at FROM public.directory_entities WHERE id=pg_temp.cui_id())::text,
 'contact_count',2,'category_count',2,'has_primary_location',true) - 'updated_at' ||
 jsonb_build_object('updated_at',(SELECT to_jsonb(created_updated_at) FROM business_admin_private.draft_create_requests WHERE entity_id=pg_temp.cui_id())),
 'T19 exact creation summary');
SELECT is((SELECT actor_user_id::text||'/'||target_type||'/'||reason FROM public.audit_logs WHERE target_id=pg_temp.cui_id() AND action='business_entity.draft_create'),
 'c2a00001-0000-4000-8000-000000000001/directory_entity/BUSINESS_SUPPLIED_INFORMATION','T19 server actor/target/reason');
CREATE FUNCTION pg_temp.cui_provenance_edges() RETURNS SETOF text LANGUAGE plpgsql AS $test$
DECLARE r jsonb; p jsonb; snap jsonb; code text;
BEGIN
 snap:=pg_temp.cui_snapshot(pg_temp.cui_id());
 -- State/ownership changes are privileged fixture probes and are rolled back.
 BEGIN
   UPDATE public.directory_entities SET lifecycle_status='active',claim_status='claimed' WHERE id=pg_temp.cui_id();
   INSERT INTO public.business_memberships(user_id,entity_id,role) VALUES('c2a00001-0000-4000-8000-000000000002',pg_temp.cui_id(),'OWNER');
   r:=pg_temp.cui_create(pg_temp.cui_payload(),'c2a00050-0000-4000-8000-000000000001');
   RETURN NEXT is(r->'result',(SELECT v->'result'||'{"outcome":"REPLAY"}' FROM pg_temp.cui_state WHERE k='create'),'T25 historical receipt unchanged after ownership/status');
   RETURN NEXT is(pg_temp.cui_update(pg_temp.cui_id(),pg_temp.cui_payload())->>'state','P0TRA','T25 replay never restores editability');
   RETURN NEXT is(pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000002',format('SELECT to_jsonb(public.create_claim_business_application(%L::uuid))',pg_temp.cui_id()))->>'state','P0CLM','T32B OWNER cannot bypass receipt');
   RAISE SQLSTATE 'PTFIX';
 EXCEPTION WHEN SQLSTATE 'PTFIX' THEN NULL;
 END;
 RETURN NEXT is(pg_temp.cui_snapshot(pg_temp.cui_id()),snap,'T25 trusted fixture state restored');
 -- Ten valid references and >50 read labels; fixture subtransaction restores all.
 BEGIN
   INSERT INTO public.directory_categories(id,code,name_ar,name_en)
   SELECT ('c2a00062-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,'cui2a0_extra_'||i,'تجربة','Extra '||i FROM generate_series(1,51)i;
   p:=pg_temp.cui_payload();
   -- Explicit bounded UUID range avoids any label-dependent authority.
   p:=jsonb_set(p,'{categories}',(SELECT jsonb_agg(jsonb_build_object('category_id',('c2a00062-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,'is_primary',false)) FROM generate_series(1,10)i));
   RETURN NEXT is(pg_temp.cui_create(p)->>'state','00000','T11 exactly ten valid categories accepted');
   INSERT INTO public.directory_entity_categories(entity_id,category_id)
   SELECT 'c2a00040-0000-4000-8000-000000000001',id FROM public.directory_categories WHERE id::text LIKE 'c2a00062-%';
   RETURN NEXT is(jsonb_array_length(pg_temp.cui_detail('c2a00040-0000-4000-8000-000000000001')->'categories'),50,'T22 category detail cap50');
   RETURN NEXT is(pg_temp.cui_detail('c2a00040-0000-4000-8000-000000000001')->>'categories_complete','false','T22 category completeness truthful');
   INSERT INTO public.directory_entity_categories(entity_id,category_id)
   SELECT pg_temp.cui_id(),id FROM public.directory_categories WHERE id::text LIKE 'c2a00062-%' LIMIT 9;
   RETURN NEXT is(pg_temp.cui_update(pg_temp.cui_id(),pg_temp.cui_payload())->>'state','P0TRA','T17 >10 assigned categories excludes full update');
   RAISE SQLSTATE 'PTFIX';
 EXCEPTION WHEN SQLSTATE 'PTFIX' THEN NULL;
 END;
END;
$test$;
SELECT * FROM pg_temp.cui_provenance_edges();
CREATE FUNCTION pg_temp.has_staff_business_permission(text) RETURNS boolean LANGUAGE sql AS $test$ SELECT true $test$;
SELECT is(pg_temp.cui_create(pg_temp.cui_payload(),gen_random_uuid(),'BUSINESS_SUPPLIED_INFORMATION','c2a00001-0000-4000-8000-000000000002')->>'state','P0PER','T30 temp authority helper shadow cannot authorize');
DROP FUNCTION pg_temp.has_staff_business_permission(text);
-- ACL-07 legacy nested SECURITY DEFINER callers retain owner EXECUTE.
CREATE FUNCTION pg_temp.cui_legacy_new() RETURNS SETOF text LANGUAGE plpgsql AS $test$
<<cui_legacy_new>>
DECLARE code text; r jsonb; app uuid; id uuid;
BEGIN
 INSERT INTO public.staff_memberships(user_id,role_id,effective_at)
 SELECT 'c2a00001-0000-4000-8000-000000000001',roles.id,now()-interval '1 day' FROM public.roles WHERE roles.code='application_reviewer';
 FOREACH code IN ARRAY ARRAY['company','engineering_office','contractor','supplier','store','technician','laboratory','equipment_provider','service_provider'] LOOP
   r:=pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000002',format(
    'SELECT to_jsonb(public.create_new_business_application(%L::jsonb))',jsonb_build_object('name','Legacy NEW '||code,'entity_type',code)));
   RETURN NEXT is(r->>'state','00000','T32F original NEW type '||code);
   app:=(r->'result'->>'id')::uuid;
   UPDATE public.business_applications SET status='APPROVED',approved_at=now() WHERE business_applications.id=app;
   r:=pg_temp.cui_call('authenticated','c2a00001-0000-4000-8000-000000000001',format('SELECT to_jsonb(public.staff_activate_business_application(%L::uuid))',app));
   RETURN NEXT is(r->>'state','00000','ACL-07/T32F audited activation '||code);
   id:=(r->'result'->>'target_entity_id')::uuid;
   RETURN NEXT is((SELECT entity_type||'/'||lifecycle_status||'/'||claim_status FROM public.directory_entities e WHERE e.id=cui_legacy_new.id),code||'/draft/claimed','T32F entity/private/claim semantics');
   RETURN NEXT is((SELECT count(*)::integer FROM public.business_memberships bm WHERE bm.entity_id=cui_legacy_new.id AND role='OWNER'),1,'T32F original OWNER');
   RETURN NEXT is((SELECT count(*)::integer FROM public.subscriptions s WHERE s.entity_id=cui_legacy_new.id),0,'T32F no automatic subscription');
 END LOOP;
 DELETE FROM public.staff_memberships WHERE user_id='c2a00001-0000-4000-8000-000000000001' AND role_id IN(SELECT roles.id FROM public.roles WHERE roles.code='application_reviewer');
END;
$test$;
SELECT * FROM pg_temp.cui_legacy_new();
-- This key is actor-scoped; another authorized actor creates independently.
SELECT is(pg_temp.cui_create(pg_temp.cui_payload(),'c2a00050-0000-4000-8000-000000000001',
 'BUSINESS_SUPPLIED_INFORMATION','c2a00001-0000-4000-8000-000000000003')->'result'->>'outcome','CREATED','T24 actor scoped key');
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT pg_temp.cui_create(pg_temp.cui_payload())->>'state' AS isolated_mutation_state \gset
ROLLBACK;
SELECT is(:'isolated_mutation_state'::text,'P0CTX','T27 stronger mutation isolation denied');
SELECT * FROM finish();
\endif


\if :is_race
-- T26-T29/T32G independent PostgreSQL backends, asynchronous commands and
-- observed pg_stat_activity.wait_event_type='Lock'; no simulated wait result.
CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA extensions;
SELECT no_plan();
SELECT dblink_connect('cui_a','dbname=postgres host=127.0.0.1 user=postgres password=postgres');
SELECT dblink_connect('cui_b','dbname=postgres host=127.0.0.1 user=postgres password=postgres');
SELECT dblink_exec('cui_a',regexp_replace(pg_get_functiondef('pg_temp.cui_call(text,uuid,text)'::regprocedure),'pg_temp_[0-9]+[.]','pg_temp.','g'));
SELECT dblink_exec('cui_b',regexp_replace(pg_get_functiondef('pg_temp.cui_call(text,uuid,text)'::regprocedure),'pg_temp_[0-9]+[.]','pg_temp.','g'));
CREATE FUNCTION pg_temp.cui_remote(p_conn text,p_sql text,p_actor uuid DEFAULT 'c2a00001-0000-4000-8000-000000000001') RETURNS jsonb LANGUAGE plpgsql AS $test$
DECLARE r jsonb;
BEGIN
 SELECT v INTO r FROM extensions.dblink(p_conn,format('SELECT pg_temp.cui_call(%L,%L::uuid,%L)','authenticated',p_actor,p_sql)) AS t(v jsonb);
 RETURN r;
END;
$test$;
CREATE FUNCTION pg_temp.cui_send(p_conn text,p_sql text,p_actor uuid DEFAULT 'c2a00001-0000-4000-8000-000000000001') RETURNS integer LANGUAGE sql AS $test$
 SELECT extensions.dblink_send_query(p_conn,format('SELECT pg_temp.cui_call(%L,%L::uuid,%L)','authenticated',p_actor,p_sql))
$test$;
-- Record remote PIDs before sending asynchronous queries (a busy connection
-- cannot execute a second SELECT merely to fetch its PID).
CREATE TEMP TABLE cui_pids(conn text PRIMARY KEY,pid integer);
INSERT INTO cui_pids SELECT 'cui_a',n FROM dblink('cui_a','SELECT pg_backend_pid()') AS t(n integer);
INSERT INTO cui_pids SELECT 'cui_b',n FROM dblink('cui_b','SELECT pg_backend_pid()') AS t(n integer);
CREATE FUNCTION pg_temp.cui_wait(p_conn text) RETURNS boolean LANGUAGE plpgsql AS $test$
DECLARE deadline timestamptz:=clock_timestamp()+interval '5 seconds';
BEGIN
 LOOP
   PERFORM pg_stat_clear_snapshot();
   IF EXISTS(SELECT 1 FROM pg_stat_activity a JOIN pg_temp.cui_pids p ON a.pid=p.pid WHERE p.conn=p_conn AND a.wait_event_type='Lock') THEN RETURN true; END IF;
   IF clock_timestamp()>deadline THEN RETURN false; END IF;
   PERFORM pg_sleep(0.01);
 END LOOP;
END;
$test$;
CREATE FUNCTION pg_temp.cui_take(p_conn text) RETURNS jsonb LANGUAGE plpgsql AS $test$
DECLARE r jsonb;
BEGIN
 SELECT v INTO r FROM extensions.dblink_get_result(p_conn) AS t(v jsonb);
 PERFORM v FROM extensions.dblink_get_result(p_conn) AS t(v jsonb);
 RETURN r;
END;
$test$;
CREATE FUNCTION pg_temp.cui_create_sql(p_key uuid,p_name text DEFAULT NULL) RETURNS text LANGUAGE sql AS $test$
 SELECT format('SELECT public.staff_create_business_draft(%L::uuid,%L::jsonb,%L)',p_key,
 CASE WHEN p_name IS NULL THEN pg_temp.cui_payload() ELSE jsonb_set(pg_temp.cui_payload(),'{name}',to_jsonb(p_name)) END,'BUSINESS_SUPPLIED_INFORMATION')
$test$;
CREATE FUNCTION pg_temp.cui_races() RETURNS SETOF text LANGUAGE plpgsql AS $test$
<<cui_races>>
DECLARE r jsonb; r2 jsonb; id uuid; key uuid; sql text; token timestamptz; claim text; kind text;
BEGIN
 key:=gen_random_uuid(); sql:=pg_temp.cui_create_sql(key);
 PERFORM extensions.dblink_exec('cui_a','BEGIN');
 r:=pg_temp.cui_remote('cui_a',sql); id:=(r->'result'->>'entity_id')::uuid;
 RETURN NEXT is(r->>'state','00000','T26 first uncommitted create');
 PERFORM pg_temp.cui_send('cui_b',sql);
 RETURN NEXT ok(pg_temp.cui_wait('cui_b'),'T26 duplicate create genuinely waits on reservation');
 PERFORM extensions.dblink_exec('cui_a','COMMIT');
 r2:=pg_temp.cui_take('cui_b');
 RETURN NEXT is(r2->'result'->>'outcome','REPLAY','T26 one effect, one historical replay');
 RETURN NEXT is((SELECT count(*)::integer FROM public.audit_logs WHERE target_id=cui_races.id),1,'T26 one audit');
 RETURN NEXT is(pg_temp.cui_remote('cui_b',pg_temp.cui_create_sql(key,'Conflict'))->>'state','P0RPL','T26 conflicting same key');
key:=gen_random_uuid();
 PERFORM extensions.dblink_exec('cui_a','BEGIN');
 r:=pg_temp.cui_remote('cui_a',pg_temp.cui_create_sql(key));
 id:=(r->'result'->>'entity_id')::uuid;
 PERFORM pg_temp.cui_send('cui_b',pg_temp.cui_create_sql(key,'Concurrent conflicting payload'));
 RETURN NEXT ok(pg_temp.cui_wait('cui_b'),'T26 changed same-key payload genuinely waits');
 PERFORM extensions.dblink_exec('cui_a','COMMIT');
 RETURN NEXT is(pg_temp.cui_take('cui_b')->>'state','P0RPL','T26 concurrent changed same-key payload conflicts');
 RETURN NEXT is((SELECT count(*)::integer FROM public.audit_logs WHERE target_id=cui_races.id),1,'T26 concurrent conflict leaves one original effect');
 key:=gen_random_uuid();
 PERFORM extensions.dblink_exec('cui_a','BEGIN');
 r:=pg_temp.cui_remote('cui_a',pg_temp.cui_create_sql(key));
 PERFORM pg_temp.cui_send('cui_b',pg_temp.cui_create_sql(key));
 RETURN NEXT ok(pg_temp.cui_wait('cui_b'),'T26 rollback reservation blocks second session');
 PERFORM extensions.dblink_exec('cui_a','ROLLBACK');
 r2:=pg_temp.cui_take('cui_b');
 RETURN NEXT is(r2->'result'->>'outcome','CREATED','T26 rollback releases abandoned reservation');

 -- T32G creator UUID is known before visibility: absent-target guard is immediate.
 key:=gen_random_uuid();
 PERFORM extensions.dblink_exec('cui_a','BEGIN');
 r:=pg_temp.cui_remote('cui_a',pg_temp.cui_create_sql(key)); id:=(r->'result'->>'entity_id')::uuid;
 claim:=format('SELECT to_jsonb(public.create_claim_business_application(%L::uuid))',id);
 PERFORM extensions.dblink_exec('cui_b','SET statement_timeout=''2s''');
 RETURN NEXT is(pg_temp.cui_remote('cui_b',claim,'c2a00001-0000-4000-8000-000000000002')->>'state','23503','T32G uncommitted target fails immediately before FK');
 PERFORM extensions.dblink_exec('cui_a','COMMIT');
 RETURN NEXT is(pg_temp.cui_remote('cui_b',claim,'c2a00001-0000-4000-8000-000000000002')->>'state','P0CLM','T32G after visibility receipt denies');
 PERFORM extensions.dblink_exec('cui_b','SET statement_timeout=''10s''');
 PERFORM extensions.dblink_exec('cui_a','BEGIN');
 PERFORM v FROM extensions.dblink('cui_a',format('SELECT id::text FROM public.directory_entities WHERE id=%L::uuid FOR UPDATE',id)) AS t(v text);
 PERFORM pg_temp.cui_send('cui_b',claim,'c2a00001-0000-4000-8000-000000000002');
 RETURN NEXT ok(pg_temp.cui_wait('cui_b'),'T32G CLAIM actually waits on entity row');
 PERFORM extensions.dblink_exec('cui_a','COMMIT');
 RETURN NEXT is(pg_temp.cui_take('cui_b')->>'state','P0CLM','T32G postwait fresh receipt denies');
 PERFORM extensions.dblink_exec('cui_b','BEGIN ISOLATION LEVEL REPEATABLE READ');
 PERFORM v FROM extensions.dblink('cui_b','SELECT count(*)::text FROM public.directory_entities') AS t(v text);
 key:=gen_random_uuid(); r:=pg_temp.cui_remote('cui_a',pg_temp.cui_create_sql(key)); id:=(r->'result'->>'entity_id')::uuid;
 RETURN NEXT is(pg_temp.cui_remote('cui_b',format('SELECT to_jsonb(public.create_claim_business_application(%L::uuid))',id),'c2a00001-0000-4000-8000-000000000002')->>'state','23503','T32G old stronger snapshot fails closed');
 RETURN NEXT is(pg_temp.cui_remote('cui_b',pg_temp.cui_create_sql(gen_random_uuid()))->>'state','P0CTX','T27 unsupported isolation mutation denied');
 PERFORM extensions.dblink_exec('cui_b','ROLLBACK');

 -- T27 same observed version: winner changes token while loser holds old input.
 SELECT updated_at INTO token FROM public.directory_entities WHERE directory_entities.id=cui_races.id;
 sql:=format('SELECT public.staff_update_business_draft(%L::uuid,%L::timestamptz,%L::uuid,%L::jsonb,%L)',
 id,token,gen_random_uuid(),jsonb_set(pg_temp.cui_payload(),'{name}','"race winner"'),'CORRECT_DRAFT_INFORMATION');
 PERFORM extensions.dblink_exec('cui_a','BEGIN');
 r:=pg_temp.cui_remote('cui_a',sql);
 RETURN NEXT is(r->'result'->>'outcome','UPDATED','T27 material winner');
 PERFORM pg_temp.cui_send('cui_b',sql);
 RETURN NEXT ok(pg_temp.cui_wait('cui_b'),'T27 loser genuinely waits on entity lock');
 PERFORM extensions.dblink_exec('cui_a','COMMIT');
 RETURN NEXT is(pg_temp.cui_take('cui_b')->>'state','P0CON','T27 stale loser denied');

 -- Postwait permission, state and location changes use separate committed backends.
 FOREACH kind IN ARRAY ARRAY['revoked','expired','status','membership','location'] LOOP
   r:=pg_temp.cui_remote('cui_a',pg_temp.cui_create_sql(gen_random_uuid()));
   id:=(r->'result'->>'entity_id')::uuid;
   SELECT updated_at INTO token FROM public.directory_entities WHERE directory_entities.id=cui_races.id;
   PERFORM extensions.dblink_exec('cui_a','BEGIN');
   PERFORM v FROM extensions.dblink('cui_a',format('SELECT id::text FROM public.directory_entities WHERE id=%L::uuid FOR UPDATE',id)) AS t(v text);
   sql:=format('SELECT public.staff_update_business_draft(%L::uuid,%L::timestamptz,%L::uuid,%L::jsonb,%L)',id,token,gen_random_uuid(),
    jsonb_set(pg_temp.cui_payload(),'{name}','"blocked late"'),'CORRECT_DRAFT_INFORMATION');
   PERFORM pg_temp.cui_send('cui_b',sql);
   RETURN NEXT ok(pg_temp.cui_wait('cui_b'),'T28 wait before '||kind);
   IF kind='revoked' THEN
     PERFORM extensions.dblink_exec('cui_a','DELETE FROM public.role_permissions WHERE role_id=''c2a00002-0000-4000-8000-000000000001'' AND permission_id=(SELECT id FROM public.permissions WHERE code=''business_entities.edit_draft'')');
   ELSIF kind='expired' THEN
     PERFORM extensions.dblink_exec('cui_a','UPDATE public.staff_memberships SET expires_at=clock_timestamp() WHERE user_id=''c2a00001-0000-4000-8000-000000000001''');
   ELSIF kind='status' THEN
     PERFORM extensions.dblink_exec('cui_a',format('UPDATE public.directory_entities SET lifecycle_status=''active'' WHERE id=%L::uuid',id));
   ELSIF kind='membership' THEN
     PERFORM extensions.dblink_exec('cui_a',format('INSERT INTO public.business_memberships(user_id,entity_id,role) VALUES(''c2a00001-0000-4000-8000-000000000002'',%L::uuid,''OWNER'')',id));
   ELSE
     PERFORM extensions.dblink_exec('cui_a',format('INSERT INTO public.entity_locations(entity_id,address,is_primary) VALUES(%L::uuid,''concurrent sanctioned extra'',false)',id));
   END IF;
   PERFORM extensions.dblink_exec('cui_a','COMMIT');
   RETURN NEXT is(pg_temp.cui_take('cui_b')->>'state',CASE WHEN kind IN ('revoked','expired') THEN 'P0PER' ELSE 'P0TRA' END,'T28/T22 fresh postwait '||kind||' denied');
   PERFORM extensions.dblink_exec('cui_a','UPDATE public.staff_memberships SET expires_at=NULL WHERE user_id=''c2a00001-0000-4000-8000-000000000001''');
   PERFORM extensions.dblink_exec('cui_a','INSERT INTO public.role_permissions SELECT ''c2a00002-0000-4000-8000-000000000001'',id FROM public.permissions WHERE code=''business_entities.edit_draft'' ON CONFLICT DO NOTHING');
 END LOOP;
 -- Shared taxonomy: A0 create retains FOR SHARE until transaction completion.
 PERFORM extensions.dblink_exec('cui_a','BEGIN');
 r:=pg_temp.cui_remote('cui_a',pg_temp.cui_create_sql(gen_random_uuid()));
 PERFORM extensions.dblink_send_query('cui_b','UPDATE public.directory_categories SET is_active=false WHERE id=''c2a00020-0000-4000-8000-000000000001'' RETURNING to_jsonb(is_active)');
 RETURN NEXT ok(pg_temp.cui_wait('cui_b'),'T29 retirement genuinely waits on shared taxonomy');
 PERFORM extensions.dblink_exec('cui_a','COMMIT');
 RETURN NEXT is(pg_temp.cui_take('cui_b'),'false'::jsonb,'T29 retirement proceeds without deadlock');
 PERFORM extensions.dblink_exec('cui_a','UPDATE public.directory_categories SET is_active=true WHERE id=''c2a00020-0000-4000-8000-000000000001''');
-- T32G creator rollback leaves no target, receipt, application or audit.
 key:=gen_random_uuid();
 PERFORM extensions.dblink_exec('cui_a','BEGIN');
 r:=pg_temp.cui_remote('cui_a',pg_temp.cui_create_sql(key)); id:=(r->'result'->>'entity_id')::uuid;
 claim:=format('SELECT to_jsonb(public.create_claim_business_application(%L::uuid))',id);
 RETURN NEXT is(pg_temp.cui_remote('cui_b',claim,'c2a00001-0000-4000-8000-000000000002')->>'state','23503','T32G rollback target invisible before rollback');
 PERFORM extensions.dblink_exec('cui_a','ROLLBACK');
 RETURN NEXT is(pg_temp.cui_remote('cui_b',claim,'c2a00001-0000-4000-8000-000000000002')->>'state','23503','T32G rollback target remains missing');
 RETURN NEXT ok(NOT EXISTS(SELECT 1 FROM business_admin_private.draft_create_requests WHERE entity_id=cui_races.id)
  AND NOT EXISTS(SELECT 1 FROM public.directory_entities WHERE directory_entities.id=cui_races.id)
  AND NOT EXISTS(SELECT 1 FROM public.business_applications WHERE target_entity_id=cui_races.id)
  AND NOT EXISTS(SELECT 1 FROM public.audit_logs WHERE target_id=cui_races.id),'T32G no rollback remnants');
 -- T27 same transaction cannot retain the token on a second material effect.
 r:=pg_temp.cui_remote('cui_a',pg_temp.cui_create_sql(gen_random_uuid()));id:=(r->'result'->>'entity_id')::uuid;
 SELECT updated_at INTO token FROM public.directory_entities WHERE directory_entities.id=cui_races.id;
 PERFORM extensions.dblink_exec('cui_a','BEGIN');
 sql:=format('SELECT public.staff_update_business_draft(%L::uuid,%L::timestamptz,gen_random_uuid(),%L::jsonb,%L)',id,token,
 jsonb_set(pg_temp.cui_payload(),'{name}','"first same txn"'),'CORRECT_DRAFT_INFORMATION');
 r:=pg_temp.cui_remote('cui_a',sql);
 RETURN NEXT is(r->'result'->>'outcome','UPDATED','T27 same transaction first material edit');
 token:=(r->'result'->>'updated_at')::timestamptz;
 sql:=format('SELECT public.staff_update_business_draft(%L::uuid,%L::timestamptz,gen_random_uuid(),%L::jsonb,%L)',id,token,
 jsonb_set(pg_temp.cui_payload(),'{name}','"second same txn"'),'CORRECT_DRAFT_INFORMATION');
 RETURN NEXT is(pg_temp.cui_remote('cui_a',sql)->>'state','P0CON','T27 second material edit cannot retain token');
 PERFORM extensions.dblink_exec('cui_a','COMMIT');
 -- Earlier-start transaction supplied the current version still cannot backdate.
 PERFORM extensions.dblink_exec('cui_a','BEGIN');
 PERFORM v FROM extensions.dblink('cui_a','SELECT transaction_timestamp()::text') AS t(v text);
 sql:=format('SELECT public.staff_update_business_draft(%L::uuid,%L::timestamptz,gen_random_uuid(),%L::jsonb,%L)',id,token,
 jsonb_set(pg_temp.cui_payload(),'{name}','"newer transaction"'),'CORRECT_DRAFT_INFORMATION');
 r:=pg_temp.cui_remote('cui_b',sql);
 RETURN NEXT is(r->'result'->>'outcome','UPDATED','T27 newer independent transaction advances version');
 token:=(r->'result'->>'updated_at')::timestamptz;
 sql:=format('SELECT public.staff_update_business_draft(%L::uuid,%L::timestamptz,gen_random_uuid(),%L::jsonb,%L)',id,token,
 jsonb_set(pg_temp.cui_payload(),'{name}','"backdated attempt"'),'CORRECT_DRAFT_INFORMATION');
 RETURN NEXT is(pg_temp.cui_remote('cui_a',sql)->>'state','P0CON','T27 older transaction cannot backdate even current input version');
 PERFORM extensions.dblink_exec('cui_a','ROLLBACK');

 -- T28 explicit after-final-check limit: work already authorized may commit.
 PERFORM extensions.dblink_exec('cui_a','BEGIN');
 r:=pg_temp.cui_remote('cui_a',pg_temp.cui_create_sql(gen_random_uuid()));id:=(r->'result'->>'entity_id')::uuid;
 RETURN NEXT is(r->'result'->>'outcome','CREATED','T28 create has completed final check and audit');
 PERFORM extensions.dblink_exec('cui_b','DELETE FROM public.role_permissions WHERE role_id=''c2a00002-0000-4000-8000-000000000001'' AND permission_id=(SELECT id FROM public.permissions WHERE code=''business_entities.create_draft'')');
 PERFORM extensions.dblink_exec('cui_a','COMMIT');
 RETURN NEXT ok(EXISTS(SELECT 1 FROM public.directory_entities WHERE directory_entities.id=cui_races.id),'T28 documented in-flight overlap commits after final-check revocation');
 RETURN NEXT is(pg_temp.cui_remote('cui_a',pg_temp.cui_create_sql(gen_random_uuid()))->>'state','P0PER','T28 later calls deny completed revocation');
 PERFORM extensions.dblink_exec('cui_b','INSERT INTO public.role_permissions SELECT ''c2a00002-0000-4000-8000-000000000001'',id FROM public.permissions WHERE code=''business_entities.create_draft''');

 -- T29 existing sanctioned OWNER profile writer holds the canonical row;
 -- A0 waits then denies ownership/origin before acquiring child/reference locks.
 SELECT e.id,e.updated_at INTO id,token FROM public.directory_entities e WHERE name='Legacy NEW company';
 PERFORM extensions.dblink_exec('cui_a','BEGIN');
 r:=pg_temp.cui_remote('cui_a',format('SELECT public.update_managed_business_profile(%L::uuid,%L::timestamptz,%L,NULL,''[]''::jsonb,NULL,''[]''::jsonb)',id,token,'Legacy sanctioned managed race'),
 'c2a00001-0000-4000-8000-000000000002');
 RETURN NEXT is(r->>'state','00000','ACL-07/T29 existing managed-profile nested audit succeeds');
 sql:=format('SELECT public.staff_update_business_draft(%L::uuid,%L::timestamptz,gen_random_uuid(),%L::jsonb,%L)',id,token,pg_temp.cui_payload(),'CORRECT_DRAFT_INFORMATION');
 PERFORM pg_temp.cui_send('cui_b',sql);
 RETURN NEXT ok(pg_temp.cui_wait('cui_b'),'T29 A0 waits on sanctioned writer row');
 PERFORM extensions.dblink_exec('cui_a','COMMIT');
 RETURN NEXT is(pg_temp.cui_take('cui_b')->>'state','P0TRA','T29 sanctioned writer coexistence no deadlock');
-- Application -> entity writer uses its existing lock order and audited body.
 SELECT ba.id INTO key FROM public.business_applications ba WHERE target_entity_id='c2a00040-0000-4000-8000-000000000001' AND application_type='CLAIM';
 SELECT updated_at INTO token FROM public.directory_entities WHERE directory_entities.id='c2a00040-0000-4000-8000-000000000001';
 PERFORM extensions.dblink_exec('cui_a','INSERT INTO public.staff_memberships(user_id,role_id,effective_at) SELECT ''c2a00001-0000-4000-8000-000000000001'',id,now()-interval ''1 day'' FROM public.roles WHERE code=''application_reviewer''');
 PERFORM extensions.dblink_exec('cui_a','BEGIN');
 PERFORM extensions.dblink_exec('cui_a',format('UPDATE public.business_applications SET status=''APPROVED'',approved_at=now() WHERE id=%L::uuid',key));
 r:=pg_temp.cui_remote('cui_a',format('SELECT to_jsonb(public.staff_activate_business_application(%L::uuid))',key));
 RETURN NEXT is(r->>'state','00000','ACL-07/T29 existing CLAIM activation nested audit succeeds');
 sql:=format('SELECT public.staff_update_business_draft(''c2a00040-0000-4000-8000-000000000001'',%L::timestamptz,gen_random_uuid(),%L::jsonb,%L)',token,pg_temp.cui_payload(),'CORRECT_DRAFT_INFORMATION');
 PERFORM pg_temp.cui_send('cui_b',sql);
 RETURN NEXT ok(pg_temp.cui_wait('cui_b'),'T29 A0 waits behind application to entity activation');
 PERFORM extensions.dblink_exec('cui_a','COMMIT');
 RETURN NEXT is(pg_temp.cui_take('cui_b')->>'state','P0TRA','T29 activation/A0 no deadlock or ownership reset');
 PERFORM extensions.dblink_exec('cui_a','DELETE FROM public.staff_memberships WHERE user_id=''c2a00001-0000-4000-8000-000000000001'' AND role_id IN(SELECT id FROM public.roles WHERE code=''application_reviewer'')');
END;
$test$;
SELECT * FROM pg_temp.cui_races();
SELECT dblink_disconnect('cui_a'),dblink_disconnect('cui_b');
SELECT * FROM finish();
\endif

\if :is_http
-- Genuine HTTP T34/ACL-08/T32H: externally acquired disposable GoTrue IDs.
BEGIN;
INSERT INTO public.profiles(user_id,phone) VALUES (:'staff_uid'::uuid,'123456'),(:'ordinary_uid'::uuid,'123456') ON CONFLICT(user_id) DO NOTHING;
INSERT INTO public.staff_memberships(user_id,role_id,effective_at) VALUES
 (:'staff_uid'::uuid,'c2a00002-0000-4000-8000-000000000001',now()-interval '1 day');
COMMIT;
\endif

\if :is_migration_rollback
SELECT no_plan();
SELECT ok(to_regnamespace('business_admin_private') IS NULL,'T31 no partial private schema');
SELECT ok(to_regprocedure('public.staff_create_business_draft(uuid,jsonb,text)') IS NULL,'T31 no partial create RPC');
SELECT is((SELECT count(*)::integer FROM public.permissions WHERE permissions.code LIKE 'business_entities.%'),0,'T31 no partial references');
SELECT ok(has_function_privilege('anon','public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)','EXECUTE')
 AND has_function_privilege('authenticated','public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)','EXECUTE')
 AND has_function_privilege('service_role','public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)','EXECUTE'),'ACL-13 original grants restored atomically');
SELECT ok(NOT (SELECT prosrc FROM pg_proc WHERE oid='public.guard_claim_application_insert()'::regprocedure) LIKE '%draft_create_requests%','T31 original guard restored');
SELECT * FROM finish();
\endif

\if :is_cleanup
-- Only declared disposable fixture actors/targets are removed. This is never
-- invoked against the ordinary local or any remote database.
BEGIN;
CREATE TEMP TABLE cui_owned_entities AS
 SELECT entity_id AS id FROM business_admin_private.draft_create_requests
 WHERE actor_user_id IN('c2a00001-0000-4000-8000-000000000001','c2a00001-0000-4000-8000-000000000003')
 UNION SELECT target_entity_id FROM public.business_applications
 WHERE applicant_user_id IN('c2a00001-0000-4000-8000-000000000001','c2a00001-0000-4000-8000-000000000002') AND target_entity_id IS NOT NULL
 UNION SELECT unnest(ARRAY['c2a00040-0000-4000-8000-000000000001'::uuid,'c2a00040-0000-4000-8000-000000000002'::uuid]);
\if :{?staff_uid}
INSERT INTO cui_owned_entities SELECT entity_id FROM business_admin_private.draft_create_requests WHERE actor_user_id=:'staff_uid'::uuid;
DELETE FROM public.audit_logs WHERE actor_user_id IN(:'staff_uid'::uuid,:'ordinary_uid'::uuid);
DELETE FROM public.business_applications WHERE applicant_user_id IN(:'staff_uid'::uuid,:'ordinary_uid'::uuid);
DELETE FROM public.staff_memberships WHERE user_id IN(:'staff_uid'::uuid,:'ordinary_uid'::uuid);
\endif
DELETE FROM public.audit_logs WHERE target_id IN(SELECT id FROM cui_owned_entities)
 OR actor_user_id IN('c2a00001-0000-4000-8000-000000000001','c2a00001-0000-4000-8000-000000000002','c2a00001-0000-4000-8000-000000000003');
DELETE FROM public.business_applications WHERE applicant_user_id IN('c2a00001-0000-4000-8000-000000000001','c2a00001-0000-4000-8000-000000000002');
DELETE FROM public.business_memberships WHERE entity_id IN(SELECT id FROM cui_owned_entities);
DELETE FROM business_admin_private.draft_create_requests WHERE entity_id IN(SELECT id FROM cui_owned_entities);
DELETE FROM public.directory_entities WHERE id IN(SELECT id FROM cui_owned_entities);
DELETE FROM public.staff_memberships WHERE role_id='c2a00002-0000-4000-8000-000000000001';
DELETE FROM public.role_permissions WHERE role_id='c2a00002-0000-4000-8000-000000000001';
DELETE FROM public.roles WHERE id='c2a00002-0000-4000-8000-000000000001';
DELETE FROM auth.users WHERE id IN('c2a00001-0000-4000-8000-000000000001','c2a00001-0000-4000-8000-000000000002','c2a00001-0000-4000-8000-000000000003');
DELETE FROM public.directory_categories WHERE id IN('c2a00020-0000-4000-8000-000000000001','c2a00020-0000-4000-8000-000000000002');
DELETE FROM public.regions WHERE id='c2a00030-0000-4000-8000-000000000001';
DROP ROLE IF EXISTS cui2a0_public_probe;
\if :{?staff_uid}
DELETE FROM auth.users WHERE id IN(:'staff_uid'::uuid,:'ordinary_uid'::uuid);
\endif
COMMIT;
\endif

