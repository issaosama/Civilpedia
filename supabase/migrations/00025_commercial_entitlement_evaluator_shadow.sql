-- M3: accepted v1 entitlement/publication kernels and internal shadow observations.

-- Accepted authority: M3 §§8, 33 and committed policy-dependency clarification §35.

-- The Supabase runner owns the complete migration transaction and history.

-- This migration creates no canonical entitlement/publication authority or public API.

DO $m3_preflight$
DECLARE
  reference_time constant timestamptz := TIMESTAMPTZ '2026-01-01 00:00:00+00';
  expected_plans public.plans[] := ARRAY[
    ROW('1a7b0001-0000-4000-8000-000000000001', 'business', 'Business', NULL, false, reference_time, reference_time)::public.plans,
    ROW('1a7b0002-0000-4000-8000-000000000002', 'business_pro', 'Business Pro', NULL, false, reference_time, reference_time)::public.plans,
    ROW('1a7b0003-0000-4000-8000-000000000003', 'business_plus', 'Business Plus', NULL, false, reference_time, reference_time)::public.plans,
    ROW('1a7b0004-0000-4000-8000-000000000004', 'corporate', 'Corporate', NULL, false, reference_time, reference_time)::public.plans
  ];
  expected_entitlement_bundles commercial_private.entitlement_bundles[] := ARRAY[
    ROW('2e7b0001-0000-4000-8000-000000000001', 'business_entitlements', 1, 1, 'draft', NULL, NULL, reference_time)::commercial_private.entitlement_bundles,
    ROW('2e7b0002-0000-4000-8000-000000000002', 'business_pro_entitlements', 1, 1, 'draft', NULL, NULL, reference_time)::commercial_private.entitlement_bundles,
    ROW('2e7b0003-0000-4000-8000-000000000003', 'business_plus_entitlements', 1, 1, 'draft', NULL, NULL, reference_time)::commercial_private.entitlement_bundles,
    ROW('2e7b0004-0000-4000-8000-000000000004', 'corporate_entitlements', 1, 1, 'draft', NULL, NULL, reference_time)::commercial_private.entitlement_bundles
  ];
  expected_bundle_items commercial_private.bundle_items[] := ARRAY[
    ROW('3a7b0001-0000-4000-8000-000000000001', '2e7b0001-0000-4000-8000-000000000001', 'branches.included', 'integer', NULL, 1, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0002-0000-4000-8000-000000000002', '2e7b0001-0000-4000-8000-000000000001', 'team.active_member_max', 'integer', NULL, 5, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0003-0000-4000-8000-000000000003', '2e7b0001-0000-4000-8000-000000000001', 'media.upload_enabled', 'boolean', true, NULL, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0004-0000-4000-8000-000000000004', '2e7b0001-0000-4000-8000-000000000001', 'analytics.available', 'boolean', true, NULL, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0005-0000-4000-8000-000000000005', '2e7b0001-0000-4000-8000-000000000001', 'sponsored.purchase_eligible', 'boolean', false, NULL, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0006-0000-4000-8000-000000000001', '2e7b0002-0000-4000-8000-000000000002', 'branches.included', 'integer', NULL, 2, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0007-0000-4000-8000-000000000001', '2e7b0002-0000-4000-8000-000000000002', 'team.active_member_max', 'integer', NULL, 5, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0008-0000-4000-8000-000000000001', '2e7b0002-0000-4000-8000-000000000002', 'media.upload_enabled', 'boolean', true, NULL, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0009-0000-4000-8000-000000000001', '2e7b0002-0000-4000-8000-000000000002', 'analytics.available', 'boolean', true, NULL, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0010-0000-4000-8000-000000000001', '2e7b0002-0000-4000-8000-000000000002', 'sponsored.purchase_eligible', 'boolean', true, NULL, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0011-0000-4000-8000-000000000001', '2e7b0003-0000-4000-8000-000000000003', 'branches.included', 'integer', NULL, 3, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0012-0000-4000-8000-000000000001', '2e7b0003-0000-4000-8000-000000000003', 'team.active_member_max', 'integer', NULL, 5, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0013-0000-4000-8000-000000000001', '2e7b0003-0000-4000-8000-000000000003', 'media.upload_enabled', 'boolean', true, NULL, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0014-0000-4000-8000-000000000001', '2e7b0003-0000-4000-8000-000000000003', 'analytics.available', 'boolean', true, NULL, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0015-0000-4000-8000-000000000001', '2e7b0003-0000-4000-8000-000000000003', 'sponsored.purchase_eligible', 'boolean', true, NULL, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0016-0000-4000-8000-000000000001', '2e7b0004-0000-4000-8000-000000000004', 'branches.included', 'integer', NULL, 3, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0017-0000-4000-8000-000000000001', '2e7b0004-0000-4000-8000-000000000004', 'team.active_member_max', 'integer', NULL, 5, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0018-0000-4000-8000-000000000001', '2e7b0004-0000-4000-8000-000000000004', 'media.upload_enabled', 'boolean', true, NULL, NULL, true, reference_time)::commercial_private.bundle_items,
    ROW('3a7b0019-0000-4000-8000-000000000001', '2e7b0004-0000-4000-8000-000000000004', 'analytics.available', 'boolean', true, NULL, NULL, true, reference_time)::commercial_private.bundle_items
  ];
  expected_plan_versions commercial_private.plan_versions[] := ARRAY[
    ROW('4c7b0001-0000-4000-8000-000000000001', '1a7b0001-0000-4000-8000-000000000001', 1, '2e7b0001-0000-4000-8000-000000000001', 'retail', '__AR_LOCALIZATION_PENDING__', NULL, 1, 'draft', NULL, NULL, NULL, NULL, reference_time)::commercial_private.plan_versions,
    ROW('4c7b0002-0000-4000-8000-000000000002', '1a7b0002-0000-4000-8000-000000000002', 1, '2e7b0002-0000-4000-8000-000000000002', 'retail', '__AR_LOCALIZATION_PENDING__', NULL, 2, 'draft', NULL, NULL, NULL, NULL, reference_time)::commercial_private.plan_versions,
    ROW('4c7b0003-0000-4000-8000-000000000003', '1a7b0003-0000-4000-8000-000000000003', 1, '2e7b0003-0000-4000-8000-000000000003', 'retail', '__AR_LOCALIZATION_PENDING__', NULL, 3, 'draft', NULL, NULL, NULL, NULL, reference_time)::commercial_private.plan_versions,
    ROW('4c7b0004-0000-4000-8000-000000000004', '1a7b0004-0000-4000-8000-000000000004', 1, '2e7b0004-0000-4000-8000-000000000004', 'custom_quote', '__AR_LOCALIZATION_PENDING__', NULL, 4, 'draft', NULL, NULL, NULL, NULL, reference_time)::commercial_private.plan_versions
  ];
  expected_term_prices commercial_private.term_prices[] := ARRAY[
    ROW('5d7b0001-0000-4000-8000-000000000001', '4c7b0001-0000-4000-8000-000000000001', 'retail', 1, 1, 20000, 'IQD', 'draft', NULL, NULL, NULL, NULL, reference_time)::commercial_private.term_prices,
    ROW('5d7b0002-0000-4000-8000-000000000002', '4c7b0001-0000-4000-8000-000000000001', 'retail', 1, 3, 55000, 'IQD', 'draft', NULL, NULL, NULL, NULL, reference_time)::commercial_private.term_prices,
    ROW('5d7b0003-0000-4000-8000-000000000003', '4c7b0001-0000-4000-8000-000000000001', 'retail', 1, 12, 200000, 'IQD', 'draft', NULL, NULL, NULL, NULL, reference_time)::commercial_private.term_prices,
    ROW('5d7b0004-0000-4000-8000-000000000004', '4c7b0002-0000-4000-8000-000000000002', 'retail', 1, 1, 40000, 'IQD', 'draft', NULL, NULL, NULL, NULL, reference_time)::commercial_private.term_prices,
    ROW('5d7b0005-0000-4000-8000-000000000005', '4c7b0002-0000-4000-8000-000000000002', 'retail', 1, 3, 110000, 'IQD', 'draft', NULL, NULL, NULL, NULL, reference_time)::commercial_private.term_prices,
    ROW('5d7b0006-0000-4000-8000-000000000006', '4c7b0002-0000-4000-8000-000000000002', 'retail', 1, 12, 400000, 'IQD', 'draft', NULL, NULL, NULL, NULL, reference_time)::commercial_private.term_prices,
    ROW('5d7b0007-0000-4000-8000-000000000007', '4c7b0003-0000-4000-8000-000000000003', 'retail', 1, 1, 70000, 'IQD', 'draft', NULL, NULL, NULL, NULL, reference_time)::commercial_private.term_prices,
    ROW('5d7b0008-0000-4000-8000-000000000008', '4c7b0003-0000-4000-8000-000000000003', 'retail', 1, 3, 190000, 'IQD', 'draft', NULL, NULL, NULL, NULL, reference_time)::commercial_private.term_prices,
    ROW('5d7b0009-0000-4000-8000-000000000009', '4c7b0003-0000-4000-8000-000000000003', 'retail', 1, 12, 700000, 'IQD', 'draft', NULL, NULL, NULL, NULL, reference_time)::commercial_private.term_prices
  ];
  owner_oid oid := 'postgres'::pg_catalog.regrole;
  private_oid oid := 'commercial_private'::pg_catalog.regnamespace;
  client record;
  relation record;
  pass integer;
  excluded_ids text[];
  row_digest text;
  data_snapshot jsonb;
  data_current jsonb;
  metadata_snapshot jsonb;
  metadata_current jsonb;
  legacy_count bigint;
BEGIN
  IF current_user <> 'postgres' OR session_user <> 'postgres'
     OR pg_catalog.current_setting('role') <> 'none'
     OR pg_catalog.current_setting('server_version_num')::integer / 10000 <> 17 THEN
    RAISE EXCEPTION 'M3 predecessor execution context differs from accepted creator';
  END IF;


  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_class
      WHERE oid IN ('public.plans'::pg_catalog.regclass,
        'commercial_private.entitlement_bundles'::pg_catalog.regclass,
        'commercial_private.bundle_items'::pg_catalog.regclass,
        'commercial_private.plan_versions'::pg_catalog.regclass,
        'commercial_private.term_prices'::pg_catalog.regclass)
        AND relkind = 'r' AND relowner = owner_oid
        AND relrowsecurity AND NOT relforcerowsecurity) <> 5
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_policy p
       JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
       WHERE c.oid = 'public.plans'::pg_catalog.regclass OR c.relnamespace = private_oid)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
       WHERE (c.oid = 'public.plans'::pg_catalog.regclass OR c.relnamespace = private_oid)
         AND a.attnum > 0 AND NOT a.attisdropped AND a.attacl IS NOT NULL)
     OR (SELECT nspowner FROM pg_catalog.pg_namespace WHERE oid = private_oid) <> owner_oid
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_class WHERE relnamespace = private_oid AND relkind = 'r') <> 4
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_proc WHERE pronamespace = private_oid)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_class c ON c.oid = t.tgrelid
       WHERE c.relnamespace = private_oid AND NOT t.tgisinternal)
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_trigger
       WHERE tgrelid = 'public.plans'::pg_catalog.regclass AND NOT tgisinternal) <> 1
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger
       WHERE tgrelid = 'public.plans'::pg_catalog.regclass AND NOT tgisinternal
         AND tgname = 'trigger_set_updated_at' AND tgtype = 19 AND tgenabled = 'O'
         AND tgfoid = 'public.set_updated_at()'::pg_catalog.regprocedure) THEN
    RAISE EXCEPTION 'M3 predecessor M1a/HARDEN-1 structure, RLS, policy or trigger drift';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_catalog.pg_namespace n
    CROSS JOIN LATERAL pg_catalog.aclexplode(coalesce(n.nspacl,pg_catalog.acldefault('n',n.nspowner))) a
    WHERE n.oid = private_oid AND a.grantee <> owner_oid)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_class c
       CROSS JOIN LATERAL pg_catalog.aclexplode(coalesce(c.relacl,pg_catalog.acldefault('r',c.relowner))) a
       WHERE c.relnamespace = private_oid AND c.relkind = 'r' AND a.grantee <> owner_oid)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_class c
       CROSS JOIN LATERAL pg_catalog.aclexplode(coalesce(c.relacl,pg_catalog.acldefault('r',c.relowner))) a
       WHERE c.oid = 'public.plans'::pg_catalog.regclass
         AND a.grantee NOT IN (owner_oid,'service_role'::pg_catalog.regrole))
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_publication_tables
       WHERE schemaname = 'commercial_private' OR (schemaname = 'public' AND tablename = 'plans'))
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_publication WHERE puballtables)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_depend d JOIN pg_catalog.pg_rewrite w ON w.oid = d.objid
       JOIN pg_catalog.pg_class c ON c.oid = w.ev_class
       WHERE d.classid = 'pg_catalog.pg_rewrite'::pg_catalog.regclass
         AND d.refobjid IN ('public.plans'::pg_catalog.regclass,
           'commercial_private.plan_versions'::pg_catalog.regclass,
           'commercial_private.entitlement_bundles'::pg_catalog.regclass,
           'commercial_private.bundle_items'::pg_catalog.regclass,
           'commercial_private.term_prices'::pg_catalog.regclass) AND c.relkind IN ('v','m'))
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = 'public' AND p.prosrc ~* '\m(commercial_private|plans)\M') THEN
    RAISE EXCEPTION 'M3 predecessor public/private ACL, proxy or publication exposure';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_roles
      WHERE rolname IN ('anon','authenticated','service_role')) <> 3 THEN
    RAISE EXCEPTION 'M3 predecessor required client roles missing';
  END IF;
  FOR client IN SELECT oid,rolname,rolsuper,rolbypassrls FROM pg_catalog.pg_roles
    WHERE rolname IN ('anon','authenticated','service_role') LOOP
    IF client.rolsuper OR (client.rolname <> 'service_role' AND client.rolbypassrls)
       OR pg_catalog.pg_has_role(client.oid,owner_oid,'MEMBER')
       OR pg_catalog.pg_has_role(client.oid,owner_oid,'SET')
       OR pg_catalog.has_schema_privilege(client.oid,private_oid,'USAGE,CREATE')
       OR EXISTS (SELECT 1 FROM pg_catalog.pg_class c WHERE c.relnamespace = private_oid AND c.relkind = 'r'
         AND (pg_catalog.has_table_privilege(client.oid,c.oid,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER,MAINTAIN')
           OR pg_catalog.has_any_column_privilege(client.oid,c.oid,'SELECT,INSERT,UPDATE,REFERENCES')))
       OR (client.rolname <> 'service_role'
         AND (pg_catalog.has_table_privilege(client.oid,'public.plans','SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER,MAINTAIN')
           OR pg_catalog.has_any_column_privilege(client.oid,'public.plans','SELECT,INSERT,UPDATE,REFERENCES'))) THEN
      RAISE EXCEPTION 'M3 predecessor effective client denial failed for %',client.rolname;
    END IF;
  END LOOP;
  IF EXISTS (
    SELECT 1 FROM (VALUES ('r'),('S'),('f'),('T')) kind(class)
    LEFT JOIN pg_catalog.pg_default_acl d ON d.defaclrole = owner_oid
      AND d.defaclnamespace = 0 AND d.defaclobjtype = kind.class::"char"
    CROSS JOIN LATERAL pg_catalog.aclexplode(coalesce(d.defaclacl,pg_catalog.acldefault(kind.class::"char",owner_oid))) a
    WHERE a.grantee <> owner_oid
  ) OR EXISTS (SELECT 1 FROM pg_catalog.pg_default_acl d
    CROSS JOIN LATERAL pg_catalog.aclexplode(d.defaclacl) a
    WHERE d.defaclrole = owner_oid AND d.defaclnamespace = private_oid AND a.grantee <> owner_oid) THEN
    RAISE EXCEPTION 'M3 predecessor M1a default privilege hardening drift';
  END IF;

  -- D / C precede exact-identity B/E, then C' and finally unrelated F.
  IF EXISTS (SELECT 1 FROM public.plans a JOIN pg_catalog.unnest(expected_plans) e ON a.id = e.id
             WHERE a.code IS DISTINCT FROM e.code) THEN
    RAISE EXCEPTION 'M3 predecessor case D: canonical UUID has different stored code';
  END IF;
  IF EXISTS (SELECT 1 FROM public.plans a JOIN pg_catalog.unnest(expected_plans) e ON a.code = e.code
             WHERE a.id IS DISTINCT FROM e.id) THEN
    RAISE EXCEPTION 'M3 predecessor case C: exact canonical code has different UUID';
  END IF;
  IF EXISTS (SELECT 1 FROM public.plans a JOIN pg_catalog.unnest(expected_plans) e ON a.id = e.id AND a.code = e.code
             WHERE pg_catalog.to_jsonb(a) IS DISTINCT FROM pg_catalog.to_jsonb(e)) THEN
    RAISE EXCEPTION 'M3 predecessor case E: canonical identity metadata differs';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.plans a CROSS JOIN pg_catalog.unnest(expected_plans) e
    WHERE pg_catalog.btrim(pg_catalog.regexp_replace(pg_catalog.lower(pg_catalog.btrim(a.code)),
      '[-._[:space:]]+', '_', 'g'), '_') = e.code
      AND a.code IS DISTINCT FROM e.code
  ) THEN
    RAISE EXCEPTION 'M3 predecessor case C-prime: normalized collision, original stored code differs';
  END IF;
  IF EXISTS (
    SELECT 1 FROM commercial_private.entitlement_bundles a
    JOIN pg_catalog.unnest(expected_entitlement_bundles) e ON a.id = e.id OR (a.code, a.version) = (e.code, e.version)
    WHERE pg_catalog.to_jsonb(a) IS DISTINCT FROM pg_catalog.to_jsonb(e)
  ) THEN
    RAISE EXCEPTION 'M3 predecessor bundle conflict';
  END IF;
  IF EXISTS (
    SELECT 1 FROM commercial_private.bundle_items a
    JOIN pg_catalog.unnest(expected_bundle_items) e ON a.id = e.id OR (a.bundle_version_id, a.capability_key) = (e.bundle_version_id, e.capability_key)
    WHERE pg_catalog.to_jsonb(a) IS DISTINCT FROM pg_catalog.to_jsonb(e)
  ) THEN
    RAISE EXCEPTION 'M3 predecessor bundle item conflict';
  END IF;
  IF EXISTS (
    SELECT 1 FROM commercial_private.plan_versions a
    JOIN pg_catalog.unnest(expected_plan_versions) e ON a.id = e.id OR (a.plan_id, a.version) = (e.plan_id, e.version)
    WHERE pg_catalog.to_jsonb(a) IS DISTINCT FROM pg_catalog.to_jsonb(e)
  ) THEN
    RAISE EXCEPTION 'M3 predecessor G plan-version linkage/metadata conflict';
  END IF;
  IF EXISTS (
    SELECT 1 FROM commercial_private.term_prices a
    JOIN pg_catalog.unnest(expected_term_prices) e ON a.id = e.id OR (a.plan_version_id, a.duration_months, a.version) = (e.plan_version_id, e.duration_months, e.version)
    WHERE pg_catalog.to_jsonb(a) IS DISTINCT FROM pg_catalog.to_jsonb(e)
  ) THEN
    RAISE EXCEPTION 'M3 predecessor term price conflict';
  END IF;
  -- A frozen bundle must not silently acquire extra capabilities on a re-run.
  IF EXISTS (SELECT 1 FROM commercial_private.bundle_items a
    JOIN pg_catalog.unnest(expected_entitlement_bundles) b ON b.id = a.bundle_version_id
    WHERE NOT EXISTS (SELECT 1 FROM pg_catalog.unnest(expected_bundle_items) e
      WHERE pg_catalog.to_jsonb(a) = pg_catalog.to_jsonb(e))) THEN
    RAISE EXCEPTION 'M3 predecessor frozen bundle has unexpected item';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM public.plans a
      JOIN pg_catalog.unnest(expected_plans) e ON a.id = e.id
      WHERE pg_catalog.to_jsonb(a) = pg_catalog.to_jsonb(e)) <> 4 THEN
    RAISE EXCEPTION 'M1b exact plans postcondition failed';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM commercial_private.entitlement_bundles a
      JOIN pg_catalog.unnest(expected_entitlement_bundles) e ON a.id = e.id
      WHERE pg_catalog.to_jsonb(a) = pg_catalog.to_jsonb(e)) <> 4 THEN
    RAISE EXCEPTION 'M1b exact entitlement_bundles postcondition failed';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM commercial_private.bundle_items a
      JOIN pg_catalog.unnest(expected_bundle_items) e ON a.id = e.id
      WHERE pg_catalog.to_jsonb(a) = pg_catalog.to_jsonb(e)) <> 19 THEN
    RAISE EXCEPTION 'M1b exact bundle_items postcondition failed';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM commercial_private.plan_versions a
      JOIN pg_catalog.unnest(expected_plan_versions) e ON a.id = e.id
      WHERE pg_catalog.to_jsonb(a) = pg_catalog.to_jsonb(e)) <> 4 THEN
    RAISE EXCEPTION 'M1b exact plan_versions postcondition failed';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM commercial_private.term_prices a
      JOIN pg_catalog.unnest(expected_term_prices) e ON a.id = e.id
      WHERE pg_catalog.to_jsonb(a) = pg_catalog.to_jsonb(e)) <> 9 THEN
    RAISE EXCEPTION 'M1b exact term_prices postcondition failed';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM commercial_private.entitlement_bundles)<>4
    OR (SELECT pg_catalog.count(*) FROM commercial_private.plan_versions)<>4
    OR (SELECT pg_catalog.count(*) FROM commercial_private.bundle_items)<>19
    OR (SELECT pg_catalog.count(*) FROM commercial_private.term_prices)<>9
    OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_constraint WHERE connamespace=private_oid)<>34
    OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_class WHERE relnamespace=private_oid AND relkind='i')<>9 THEN
    RAISE EXCEPTION 'M3 frozen catalog inventory drift';
  END IF;
END;
$m3_preflight$;


DO $m3_snapshot$
DECLARE v_relation record; v_digest text; v_data jsonb := '{}'::jsonb;
BEGIN
  FOR v_relation IN SELECT n.nspname,c.relname FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname IN ('public','commercial_private') AND c.relkind='r' AND c.relname NOT LIKE 'm3\_%' ESCAPE '\' ORDER BY n.nspname,c.relname LOOP
    EXECUTE pg_catalog.format('SELECT pg_catalog.md5(COALESCE(pg_catalog.string_agg(pg_catalog.to_jsonb(t)::text,E''\\n'' ORDER BY pg_catalog.to_jsonb(t)::text),'''')) FROM ONLY %I.%I t',v_relation.nspname,v_relation.relname) INTO v_digest;
    v_data := v_data||pg_catalog.jsonb_build_object(v_relation.nspname||'.'||v_relation.relname,v_digest);
  END LOOP;
 PERFORM pg_catalog.set_config('m3.entry_data',v_data::text,true);
 PERFORM pg_catalog.set_config('m3.entry_metadata',(pg_catalog.jsonb_build_object(
 'schemas',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(n) ORDER BY n.oid) FROM pg_catalog.pg_namespace n WHERE n.nspname IN ('public','commercial_private')),
 'relations',(SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_array(c.oid,c.relname,c.relkind,c.relowner,c.relacl,c.relrowsecurity,c.relforcerowsecurity) ORDER BY c.oid) FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','commercial_private') AND c.relname NOT LIKE 'm3\_%' ESCAPE '\'),
 'columns',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(a) ORDER BY a.attrelid,a.attnum) FROM pg_catalog.pg_attribute a JOIN pg_catalog.pg_class c ON c.oid=a.attrelid JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','commercial_private') AND c.relname NOT LIKE 'm3\_%' ESCAPE '\' AND a.attnum>0),
 'constraints',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(k) ORDER BY k.oid) FROM pg_catalog.pg_constraint k JOIN pg_catalog.pg_class c ON c.oid=k.conrelid JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','commercial_private') AND c.relname NOT LIKE 'm3\_%' ESCAPE '\'),
 'indexes',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(i) ORDER BY i.indexrelid) FROM pg_catalog.pg_index i JOIN pg_catalog.pg_class c ON c.oid=i.indrelid JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','commercial_private') AND c.relname NOT LIKE 'm3\_%' ESCAPE '\'),
 'routines',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(p) ORDER BY p.oid) FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ('public','commercial_private') AND p.proname NOT LIKE 'm3\_%' ESCAPE '\'),
 'triggers',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(t) ORDER BY t.oid) FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_class c ON c.oid=t.tgrelid JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','commercial_private') AND c.relname NOT LIKE 'm3\_%' ESCAPE '\'),
 'policies',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(p) ORDER BY p.oid) FROM pg_catalog.pg_policy p),
 'defaults',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(d) ORDER BY d.oid) FROM pg_catalog.pg_default_acl d),
 'roles',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(r) ORDER BY r.oid) FROM pg_catalog.pg_roles r),
 'memberships',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(m) ORDER BY m.oid) FROM pg_catalog.pg_auth_members m),
 'publications',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(p) ORDER BY p.oid) FROM pg_catalog.pg_publication p),
 'publication_tables',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(p) ORDER BY p.pubname,p.schemaname,p.tablename) FROM pg_catalog.pg_publication_tables p)))::text,true);
END;
$m3_snapshot$;


-- Observation control and redacted reconciliation evidence; no canonical authority.
CREATE TABLE commercial_private.m3_shadow_heads (
 entity_id uuid CONSTRAINT m3_shadow_heads_pkey PRIMARY KEY,
 shadow_generation bigint NOT NULL DEFAULT 0,
 created_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
 updated_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
 CONSTRAINT m3_shadow_heads_entity_check CHECK(entity_id<>'00000000-0000-0000-0000-000000000000'::uuid),
 CONSTRAINT m3_shadow_heads_generation_check CHECK(shadow_generation>=0),
 CONSTRAINT m3_shadow_heads_time_check CHECK(pg_catalog.isfinite(created_at) AND pg_catalog.isfinite(updated_at) AND updated_at>=created_at
 AND EXTRACT(YEAR FROM pg_catalog.timezone('UTC',created_at)) BETWEEN 1 AND 9999 AND EXTRACT(YEAR FROM pg_catalog.timezone('UTC',updated_at)) BETWEEN 1 AND 9999)
);
CREATE TABLE commercial_private.m3_shadow_runs (
 request_id uuid CONSTRAINT m3_shadow_runs_pkey PRIMARY KEY,
 entity_id uuid NOT NULL,
 expected_shadow_generation bigint NOT NULL,
 shadow_generation bigint NOT NULL,
 evaluator_version text NOT NULL,
 input_version text NOT NULL,
 calendar_rule_version text NOT NULL,
 source_origin text NOT NULL,
 input_fingerprint text NOT NULL,
 observed_at timestamptz NOT NULL,
 recorded_at timestamptz NOT NULL,
 legacy_visible boolean NOT NULL,
 authority_outcome text NOT NULL,
 entitlement_outcome text NOT NULL,
 publication_outcome text NOT NULL,
 mismatch_category text NOT NULL,
 reason_codes text[] NOT NULL,
 result_summary jsonb NOT NULL,
 authority_revision bigint,
 projection_revision bigint,
 authoritative_generation bigint,
 candidate_generation bigint,
 CONSTRAINT m3_shadow_runs_entity_fkey FOREIGN KEY(entity_id) REFERENCES commercial_private.m3_shadow_heads(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
 CONSTRAINT m3_shadow_runs_entity_generation_key UNIQUE(entity_id,shadow_generation),
 CONSTRAINT m3_shadow_runs_identity_check CHECK(request_id<>'00000000-0000-0000-0000-000000000000'::uuid),
 CONSTRAINT m3_shadow_runs_generation_check CHECK(expected_shadow_generation BETWEEN 0 AND 9223372036854775806 AND shadow_generation::numeric=expected_shadow_generation::numeric+1),
 CONSTRAINT m3_shadow_runs_versions_check CHECK(evaluator_version='m3.evaluator.v1' AND input_version='m3.input.v1' AND calendar_rule_version='m3.baghdad_calendar.v1'),
 CONSTRAINT m3_shadow_runs_origin_check CHECK(source_origin IN ('runtime_shadow','test_fixture')),
 CONSTRAINT m3_shadow_runs_fingerprint_check CHECK(input_fingerprint ~ '^[0-9a-f]{64}$' AND input_fingerprint=pg_catalog.encode(extensions.digest(pg_catalog.convert_to(pg_catalog.jsonb_build_object('entitlement_input_revision',result_summary->'entitlement_input_revision','publication_input_revision',result_summary->'publication_input_revision')::text,'UTF8'),'sha256'),'hex')),
 CONSTRAINT m3_shadow_runs_time_check CHECK(pg_catalog.isfinite(observed_at) AND pg_catalog.isfinite(recorded_at) AND recorded_at>=observed_at AND EXTRACT(YEAR FROM pg_catalog.timezone('UTC',observed_at)) BETWEEN 1 AND 9999 AND EXTRACT(YEAR FROM pg_catalog.timezone('UTC',recorded_at)) BETWEEN 1 AND 9999),
 CONSTRAINT m3_shadow_runs_outcomes_check CHECK(authority_outcome IN ('COMPLETE','INCOMPLETE_AUTHORITY','CONFLICTING_AUTHORITY','UNSUPPORTED_VERSION') AND entitlement_outcome IN ('ENTITLED','NOT_ENTITLED','UNKNOWN_FAIL_CLOSED') AND publication_outcome IN ('ALLOW','DENY','UNKNOWN_FAIL_CLOSED') AND mismatch_category IN ('MATCH_VISIBLE','MATCH_NOT_VISIBLE','LEGACY_VISIBLE_CANONICAL_DENY','LEGACY_HIDDEN_CANONICAL_ALLOW','AUTHORITY_GAP_VISIBLE','AUTHORITY_GAP_NOT_VISIBLE','STALE_GENERATION','INPUT_OR_VERSION_CONFLICT','EVALUATION_ERROR')),
 CONSTRAINT m3_shadow_runs_revisions_check CHECK(
   (authority_revision IS NULL OR authority_revision>=0)
   AND (projection_revision IS NULL OR projection_revision>=0)
   AND (authoritative_generation IS NULL OR authoritative_generation>=0)
   AND (candidate_generation IS NULL OR candidate_generation>=0)
   AND (publication_outcome<>'ALLOW' OR (
     authority_revision IS NOT NULL AND projection_revision IS NOT NULL
     AND authoritative_generation IS NOT NULL AND candidate_generation IS NOT NULL
     AND authority_revision=projection_revision
     AND authoritative_generation=candidate_generation))),
 CONSTRAINT m3_shadow_runs_reasons_check CHECK(pg_catalog.cardinality(reason_codes)<=64 AND (pg_catalog.cardinality(reason_codes)=0 OR (pg_catalog.array_ndims(reason_codes)=1 AND pg_catalog.array_lower(reason_codes,1)=1)) AND pg_catalog.array_position(reason_codes,NULL) IS NULL AND reason_codes <@ ARRAY['INVALID_ENVELOPE','MISSING_REQUIRED_FIELD','UNKNOWN_FIELD','INVALID_FIELD_TYPE','INVALID_ENUM','INVALID_UUID','INVALID_TIMESTAMP','NONFINITE_TIMESTAMP','INVALID_GENERATION','INPUT_BOUND_EXCEEDED','UNSUPPORTED_INPUT_VERSION','UNSUPPORTED_EVALUATOR_VERSION','UNSUPPORTED_CALENDAR_VERSION','UNSUPPORTED_CATALOG_VERSION','UNSUPPORTED_BUNDLE_VERSION','UNSUPPORTED_REGISTRY_VERSION','UNSUPPORTED_PROGRAM_VERSION','UNSUPPORTED_PROJECTION_FORMAT','BINDING_MISMATCH','INPUT_REVISION_MISMATCH','DUPLICATE_TERM_ID','DUPLICATE_GRANT_ID','DUPLICATE_SOURCE_ID','DUPLICATE_CAPABILITY_KEY','DUPLICATE_REVISION_IDENTITY','CANONICAL_PROVIDER_UNAVAILABLE','RUNTIME_AUTHORITY_UNAVAILABLE','ELIGIBILITY_NOT_PROVEN','APPROVAL_NOT_PROVEN','CATALOG_NOT_APPROVED','BUNDLE_MISSING','CAPABILITY_MISSING','CAPABILITY_DISABLED','UNKNOWN_REQUIRED_CAPABILITY','MALFORMED_CAPABILITY','NO_APPLICABLE_BASIS','AUTHORIZATION_NOT_PROVEN','CORPORATE_TERMS_INVALID','INVALID_TERM_CHAIN','OVERLAPPING_BASIS','ANCHOR_PENDING','ANCHOR_EVIDENCE_MISSING','ANCHOR_CONFLICT','A8_PUBLICATION_ANCHOR_MISSING','POLICY_DEPENDENCY_BLOCKED','FUTURE_BASIS','TERM_EXPIRED','GRACE_CONTINUITY','GRACE_ENDED','PRIOR_PUBLICATION_NOT_PROVEN','ENFORCEMENT_UNKNOWN','ENFORCEMENT_DENIED','REQUIRED_FIELDS_NOT_PROVEN','ONBOARDING_NOT_PROVEN','MODERATION_NOT_PROVEN','VERIFICATION_NOT_PROVEN','LAUNCH_NOT_PROVEN','PROJECTION_NOT_PROVEN','GENERATION_MISSING','GENERATION_MISMATCH','ENTITLEMENT_NOT_IN_EFFECT','STALE_SHADOW_GENERATION','REQUEST_ID_CONFLICT','INTERNAL_EVALUATION_ERROR']::text[] AND (reason_codes[1] IS NULL OR reason_codes[2] IS NULL OR reason_codes[1] COLLATE "C"<reason_codes[2] COLLATE "C")
    AND (reason_codes[2] IS NULL OR reason_codes[3] IS NULL OR reason_codes[2] COLLATE "C"<reason_codes[3] COLLATE "C")
    AND (reason_codes[3] IS NULL OR reason_codes[4] IS NULL OR reason_codes[3] COLLATE "C"<reason_codes[4] COLLATE "C")
    AND (reason_codes[4] IS NULL OR reason_codes[5] IS NULL OR reason_codes[4] COLLATE "C"<reason_codes[5] COLLATE "C")
    AND (reason_codes[5] IS NULL OR reason_codes[6] IS NULL OR reason_codes[5] COLLATE "C"<reason_codes[6] COLLATE "C")
    AND (reason_codes[6] IS NULL OR reason_codes[7] IS NULL OR reason_codes[6] COLLATE "C"<reason_codes[7] COLLATE "C")
    AND (reason_codes[7] IS NULL OR reason_codes[8] IS NULL OR reason_codes[7] COLLATE "C"<reason_codes[8] COLLATE "C")
    AND (reason_codes[8] IS NULL OR reason_codes[9] IS NULL OR reason_codes[8] COLLATE "C"<reason_codes[9] COLLATE "C")
    AND (reason_codes[9] IS NULL OR reason_codes[10] IS NULL OR reason_codes[9] COLLATE "C"<reason_codes[10] COLLATE "C")
    AND (reason_codes[10] IS NULL OR reason_codes[11] IS NULL OR reason_codes[10] COLLATE "C"<reason_codes[11] COLLATE "C")
    AND (reason_codes[11] IS NULL OR reason_codes[12] IS NULL OR reason_codes[11] COLLATE "C"<reason_codes[12] COLLATE "C")
    AND (reason_codes[12] IS NULL OR reason_codes[13] IS NULL OR reason_codes[12] COLLATE "C"<reason_codes[13] COLLATE "C")
    AND (reason_codes[13] IS NULL OR reason_codes[14] IS NULL OR reason_codes[13] COLLATE "C"<reason_codes[14] COLLATE "C")
    AND (reason_codes[14] IS NULL OR reason_codes[15] IS NULL OR reason_codes[14] COLLATE "C"<reason_codes[15] COLLATE "C")
    AND (reason_codes[15] IS NULL OR reason_codes[16] IS NULL OR reason_codes[15] COLLATE "C"<reason_codes[16] COLLATE "C")
    AND (reason_codes[16] IS NULL OR reason_codes[17] IS NULL OR reason_codes[16] COLLATE "C"<reason_codes[17] COLLATE "C")
    AND (reason_codes[17] IS NULL OR reason_codes[18] IS NULL OR reason_codes[17] COLLATE "C"<reason_codes[18] COLLATE "C")
    AND (reason_codes[18] IS NULL OR reason_codes[19] IS NULL OR reason_codes[18] COLLATE "C"<reason_codes[19] COLLATE "C")
    AND (reason_codes[19] IS NULL OR reason_codes[20] IS NULL OR reason_codes[19] COLLATE "C"<reason_codes[20] COLLATE "C")
    AND (reason_codes[20] IS NULL OR reason_codes[21] IS NULL OR reason_codes[20] COLLATE "C"<reason_codes[21] COLLATE "C")
    AND (reason_codes[21] IS NULL OR reason_codes[22] IS NULL OR reason_codes[21] COLLATE "C"<reason_codes[22] COLLATE "C")
    AND (reason_codes[22] IS NULL OR reason_codes[23] IS NULL OR reason_codes[22] COLLATE "C"<reason_codes[23] COLLATE "C")
    AND (reason_codes[23] IS NULL OR reason_codes[24] IS NULL OR reason_codes[23] COLLATE "C"<reason_codes[24] COLLATE "C")
    AND (reason_codes[24] IS NULL OR reason_codes[25] IS NULL OR reason_codes[24] COLLATE "C"<reason_codes[25] COLLATE "C")
    AND (reason_codes[25] IS NULL OR reason_codes[26] IS NULL OR reason_codes[25] COLLATE "C"<reason_codes[26] COLLATE "C")
    AND (reason_codes[26] IS NULL OR reason_codes[27] IS NULL OR reason_codes[26] COLLATE "C"<reason_codes[27] COLLATE "C")
    AND (reason_codes[27] IS NULL OR reason_codes[28] IS NULL OR reason_codes[27] COLLATE "C"<reason_codes[28] COLLATE "C")
    AND (reason_codes[28] IS NULL OR reason_codes[29] IS NULL OR reason_codes[28] COLLATE "C"<reason_codes[29] COLLATE "C")
    AND (reason_codes[29] IS NULL OR reason_codes[30] IS NULL OR reason_codes[29] COLLATE "C"<reason_codes[30] COLLATE "C")
    AND (reason_codes[30] IS NULL OR reason_codes[31] IS NULL OR reason_codes[30] COLLATE "C"<reason_codes[31] COLLATE "C")
    AND (reason_codes[31] IS NULL OR reason_codes[32] IS NULL OR reason_codes[31] COLLATE "C"<reason_codes[32] COLLATE "C")
    AND (reason_codes[32] IS NULL OR reason_codes[33] IS NULL OR reason_codes[32] COLLATE "C"<reason_codes[33] COLLATE "C")
    AND (reason_codes[33] IS NULL OR reason_codes[34] IS NULL OR reason_codes[33] COLLATE "C"<reason_codes[34] COLLATE "C")
    AND (reason_codes[34] IS NULL OR reason_codes[35] IS NULL OR reason_codes[34] COLLATE "C"<reason_codes[35] COLLATE "C")
    AND (reason_codes[35] IS NULL OR reason_codes[36] IS NULL OR reason_codes[35] COLLATE "C"<reason_codes[36] COLLATE "C")
    AND (reason_codes[36] IS NULL OR reason_codes[37] IS NULL OR reason_codes[36] COLLATE "C"<reason_codes[37] COLLATE "C")
    AND (reason_codes[37] IS NULL OR reason_codes[38] IS NULL OR reason_codes[37] COLLATE "C"<reason_codes[38] COLLATE "C")
    AND (reason_codes[38] IS NULL OR reason_codes[39] IS NULL OR reason_codes[38] COLLATE "C"<reason_codes[39] COLLATE "C")
    AND (reason_codes[39] IS NULL OR reason_codes[40] IS NULL OR reason_codes[39] COLLATE "C"<reason_codes[40] COLLATE "C")
    AND (reason_codes[40] IS NULL OR reason_codes[41] IS NULL OR reason_codes[40] COLLATE "C"<reason_codes[41] COLLATE "C")
    AND (reason_codes[41] IS NULL OR reason_codes[42] IS NULL OR reason_codes[41] COLLATE "C"<reason_codes[42] COLLATE "C")
    AND (reason_codes[42] IS NULL OR reason_codes[43] IS NULL OR reason_codes[42] COLLATE "C"<reason_codes[43] COLLATE "C")
    AND (reason_codes[43] IS NULL OR reason_codes[44] IS NULL OR reason_codes[43] COLLATE "C"<reason_codes[44] COLLATE "C")
    AND (reason_codes[44] IS NULL OR reason_codes[45] IS NULL OR reason_codes[44] COLLATE "C"<reason_codes[45] COLLATE "C")
    AND (reason_codes[45] IS NULL OR reason_codes[46] IS NULL OR reason_codes[45] COLLATE "C"<reason_codes[46] COLLATE "C")
    AND (reason_codes[46] IS NULL OR reason_codes[47] IS NULL OR reason_codes[46] COLLATE "C"<reason_codes[47] COLLATE "C")
    AND (reason_codes[47] IS NULL OR reason_codes[48] IS NULL OR reason_codes[47] COLLATE "C"<reason_codes[48] COLLATE "C")
    AND (reason_codes[48] IS NULL OR reason_codes[49] IS NULL OR reason_codes[48] COLLATE "C"<reason_codes[49] COLLATE "C")
    AND (reason_codes[49] IS NULL OR reason_codes[50] IS NULL OR reason_codes[49] COLLATE "C"<reason_codes[50] COLLATE "C")
    AND (reason_codes[50] IS NULL OR reason_codes[51] IS NULL OR reason_codes[50] COLLATE "C"<reason_codes[51] COLLATE "C")
    AND (reason_codes[51] IS NULL OR reason_codes[52] IS NULL OR reason_codes[51] COLLATE "C"<reason_codes[52] COLLATE "C")
    AND (reason_codes[52] IS NULL OR reason_codes[53] IS NULL OR reason_codes[52] COLLATE "C"<reason_codes[53] COLLATE "C")
    AND (reason_codes[53] IS NULL OR reason_codes[54] IS NULL OR reason_codes[53] COLLATE "C"<reason_codes[54] COLLATE "C")
    AND (reason_codes[54] IS NULL OR reason_codes[55] IS NULL OR reason_codes[54] COLLATE "C"<reason_codes[55] COLLATE "C")
    AND (reason_codes[55] IS NULL OR reason_codes[56] IS NULL OR reason_codes[55] COLLATE "C"<reason_codes[56] COLLATE "C")
    AND (reason_codes[56] IS NULL OR reason_codes[57] IS NULL OR reason_codes[56] COLLATE "C"<reason_codes[57] COLLATE "C")
    AND (reason_codes[57] IS NULL OR reason_codes[58] IS NULL OR reason_codes[57] COLLATE "C"<reason_codes[58] COLLATE "C")
    AND (reason_codes[58] IS NULL OR reason_codes[59] IS NULL OR reason_codes[58] COLLATE "C"<reason_codes[59] COLLATE "C")
    AND (reason_codes[59] IS NULL OR reason_codes[60] IS NULL OR reason_codes[59] COLLATE "C"<reason_codes[60] COLLATE "C")
    AND (reason_codes[60] IS NULL OR reason_codes[61] IS NULL OR reason_codes[60] COLLATE "C"<reason_codes[61] COLLATE "C")
    AND (reason_codes[61] IS NULL OR reason_codes[62] IS NULL OR reason_codes[61] COLLATE "C"<reason_codes[62] COLLATE "C")
    AND (reason_codes[62] IS NULL OR reason_codes[63] IS NULL OR reason_codes[62] COLLATE "C"<reason_codes[63] COLLATE "C")
    AND (reason_codes[63] IS NULL OR reason_codes[64] IS NULL OR reason_codes[63] COLLATE "C"<reason_codes[64] COLLATE "C")),
 CONSTRAINT m3_shadow_runs_summary_check CHECK((pg_catalog.jsonb_typeof(result_summary)='object'
 AND result_summary ?& ARRAY['entitlement_input_revision','publication_input_revision','comparison_target','comparison_result','basis_context','enforcement_context','intrinsic_readiness','candidate_first_publication_ready','continuity_eligible','gate_results','catalog_binding','snapshot_provenance'] AND (result_summary - ARRAY['entitlement_input_revision','publication_input_revision','comparison_target','comparison_result','basis_context','enforcement_context','intrinsic_readiness','candidate_first_publication_ready','continuity_eligible','gate_results','catalog_binding','snapshot_provenance'])='{}'::jsonb
 AND pg_catalog.jsonb_typeof(result_summary->'entitlement_input_revision')='string' AND result_summary->>'entitlement_input_revision' ~ '^[0-9a-f]{64}$'
 AND pg_catalog.jsonb_typeof(result_summary->'publication_input_revision')='string' AND result_summary->>'publication_input_revision' ~ '^[0-9a-f]{64}$'
 AND result_summary->>'comparison_target'=(CASE source_origin WHEN 'runtime_shadow' THEN 'legacy_active_rls' ELSE 'fixture_visibility' END)
 AND result_summary->>'comparison_result' IN ('MATCH','DIFFERENT','INCOMPARABLE')
 AND (result_summary->'basis_context'='null'::jsonb OR result_summary->>'basis_context' IN ('NONE','PENDING_ANCHOR','FUTURE','IN_EFFECT','GRACE','AFTER_GRACE'))
 AND result_summary->>'enforcement_context' IN ('CLEAR','WARNING','SUSPENDED','TERMINATED','CLOSED','UNKNOWN')
 AND result_summary->>'intrinsic_readiness' IN ('READY','NOT_READY','UNKNOWN_FAIL_CLOSED')
 AND pg_catalog.jsonb_typeof(result_summary->'candidate_first_publication_ready')='boolean'
 AND pg_catalog.jsonb_typeof(result_summary->'continuity_eligible')='boolean'
 AND pg_catalog.jsonb_typeof(result_summary->'gate_results')='object'
 AND result_summary->'gate_results' ?& ARRAY['required_fields','onboarding','moderation','verification','enforcement','launch','projection','generation'] AND ((result_summary->'gate_results') - ARRAY['required_fields','onboarding','moderation','verification','enforcement','launch','projection','generation'])='{}'::jsonb
 AND result_summary#>>'{gate_results,required_fields}' IN ('PASS','FAIL','UNKNOWN','BLOCKED_POLICY')
 AND result_summary#>>'{gate_results,onboarding}' IN ('PASS','FAIL','UNKNOWN','BLOCKED_POLICY')
 AND result_summary#>>'{gate_results,moderation}' IN ('PASS','FAIL','UNKNOWN','BLOCKED_POLICY')
 AND result_summary#>>'{gate_results,verification}' IN ('PASS','FAIL','UNKNOWN','BLOCKED_POLICY')
 AND result_summary#>>'{gate_results,enforcement}' IN ('PASS','FAIL','UNKNOWN','BLOCKED_POLICY')
 AND result_summary#>>'{gate_results,launch}' IN ('PASS','FAIL','UNKNOWN','BLOCKED_POLICY')
 AND result_summary#>>'{gate_results,projection}' IN ('PASS','FAIL','UNKNOWN','BLOCKED_POLICY')
 AND result_summary#>>'{gate_results,generation}' IN ('PASS','FAIL','UNKNOWN','BLOCKED_POLICY')
 AND pg_catalog.jsonb_typeof(result_summary->'snapshot_provenance')='object'
 AND result_summary->'snapshot_provenance'=CASE source_origin WHEN 'runtime_shadow' THEN '{"transaction_isolation":"repeatable_read","observation_time_basis":"server_wall_after_shadow_lock"}'::jsonb ELSE '{"transaction_isolation":"fixture_snapshot","observation_time_basis":"fixed_fixture_instant"}'::jsonb END
 AND (result_summary->'catalog_binding'='null'::jsonb OR (
 pg_catalog.jsonb_typeof(result_summary->'catalog_binding')='object'
 AND result_summary->'catalog_binding' ?& ARRAY['plan_id','plan_version_id','plan_version','bundle_version_id','bundle_version','registry_version','snapshot_revision']
 AND (result_summary->'catalog_binding') - ARRAY['plan_id','plan_version_id','plan_version','bundle_version_id','bundle_version','registry_version','snapshot_revision']='{}'::jsonb
 AND result_summary#>'{catalog_binding,plan_version}'='1'::jsonb
 AND result_summary#>'{catalog_binding,bundle_version}'='1'::jsonb
 AND result_summary#>'{catalog_binding,registry_version}'='1'::jsonb
 AND pg_catalog.jsonb_typeof(result_summary#>'{catalog_binding,snapshot_revision}')='string'
 AND result_summary#>>'{catalog_binding,snapshot_revision}' ~ '^[0-9a-f]{64}$'
 AND ((result_summary#>>'{catalog_binding,plan_id}',result_summary#>>'{catalog_binding,plan_version_id}',result_summary#>>'{catalog_binding,bundle_version_id}') IN
 (('1a7b0001-0000-4000-8000-000000000001','4c7b0001-0000-4000-8000-000000000001','2e7b0001-0000-4000-8000-000000000001'),('1a7b0002-0000-4000-8000-000000000002','4c7b0002-0000-4000-8000-000000000002','2e7b0002-0000-4000-8000-000000000002'),('1a7b0003-0000-4000-8000-000000000003','4c7b0003-0000-4000-8000-000000000003','2e7b0003-0000-4000-8000-000000000003'),('1a7b0004-0000-4000-8000-000000000004','4c7b0004-0000-4000-8000-000000000004','2e7b0004-0000-4000-8000-000000000004')))
 ))) IS TRUE AND pg_catalog.octet_length(pg_catalog.convert_to(result_summary::text,'UTF8'))<=16384),
 CONSTRAINT m3_shadow_runs_runtime_check CHECK(source_origin<>'runtime_shadow' OR (
 authority_outcome='INCOMPLETE_AUTHORITY' AND entitlement_outcome='UNKNOWN_FAIL_CLOSED' AND publication_outcome='UNKNOWN_FAIL_CLOSED'
 AND authority_revision IS NULL AND projection_revision IS NULL AND authoritative_generation IS NULL AND candidate_generation IS NULL
 AND mismatch_category=CASE WHEN legacy_visible THEN 'AUTHORITY_GAP_VISIBLE' ELSE 'AUTHORITY_GAP_NOT_VISIBLE' END
 AND reason_codes @> ARRAY['CANONICAL_PROVIDER_UNAVAILABLE','RUNTIME_AUTHORITY_UNAVAILABLE']
 AND result_summary->>'comparison_result'='INCOMPARABLE' AND result_summary->'basis_context'='null'::jsonb AND result_summary->'catalog_binding'='null'::jsonb
 AND result_summary->>'enforcement_context'='UNKNOWN' AND result_summary->>'intrinsic_readiness'='UNKNOWN_FAIL_CLOSED'
 AND result_summary->'candidate_first_publication_ready'='false'::jsonb AND result_summary->'continuity_eligible'='false'::jsonb
 AND result_summary->'gate_results'='{"required_fields":"UNKNOWN","onboarding":"UNKNOWN","moderation":"UNKNOWN","verification":"UNKNOWN","enforcement":"UNKNOWN","launch":"UNKNOWN","projection":"UNKNOWN","generation":"UNKNOWN"}'::jsonb))
);
CREATE INDEX m3_shadow_runs_recorded_at_request_id_idx ON commercial_private.m3_shadow_runs(recorded_at,request_id);
ALTER TABLE commercial_private.m3_shadow_heads ENABLE ROW LEVEL SECURITY;
ALTER TABLE commercial_private.m3_shadow_runs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE commercial_private.m3_shadow_heads,commercial_private.m3_shadow_runs FROM PUBLIC,anon,authenticated,service_role;



CREATE FUNCTION commercial_private.m3_evaluate_entitlement_v1(p_input jsonb, p_as_of timestamptz)
RETURNS TABLE (
  envelope_kind text,
  input_version text,
  evaluator_version text,
  calendar_rule_version text,
  entity_id uuid,
  source_origin text,
  as_of timestamptz,
  input_revision text,
  synthetic_provider_revision bigint,
  authority_outcome text,
  basis_context text,
  source_kind text,
  entitlement_outcome text,
  enforcement_context text,
  enforcement_revision bigint,
  continuity_eligible boolean,
  agreement_id uuid,
  term_id uuid,
  grant_id uuid,
  plan_id uuid,
  plan_version_id uuid,
  plan_version bigint,
  bundle_version_id uuid,
  bundle_version bigint,
  registry_version bigint,
  snapshot_revision text,
  original_start timestamptz,
  original_end timestamptz,
  effective_end timestamptz,
  grace_end timestamptz,
  prior_publication_event_id uuid,
  capabilities jsonb,
  next_boundary timestamptz,
  reason_codes text[],
  result_fingerprint text
)
LANGUAGE plpgsql IMMUTABLE SECURITY INVOKER
SET search_path = commercial_private, pg_temp
AS $m3_entitlement$
DECLARE
  v_rank integer; v_best_rank integer;

  v_shapes constant jsonb := '{"Provider":{"status":"E:provider_status","revision":"I+?","source_origin":"E:source_origin"},"Providers":{"eligibility":"Provider","agreement_terms":"Provider","grants":"Provider","catalog":"Provider","enforcement":"Provider","publication_history":"Provider"},"Gate":{"status":"E:gate_status","entity_id":"UUID","evidence_id":"UUID?","revision":"I+?","decided_at":"TS?","content_revision":"I+?","requirements_revision":"I+?","scope_id":"UUID?","policy_dependency":"E:policy_dependency?"},"Agreement":{"agreement_id":"UUID","entity_id":"UUID","revision":"I+","approval_state":"E:approval_state","approval_evidence_id":"UUID?","approved_at":"TS?"},"Enforcement":{"context":"E:enforcement_context","entity_id":"UUID","evidence_id":"UUID?","revision":"I+?","effective_at":"TS?"},"History":{"publication_event_id":"UUID","entity_id":"UUID","source_kind":"E:source_kind","source_id":"UUID","content_revision":"I+","available_at":"TS"},"Item":{"capability_key":"Key","value_kind":"E:value_kind","value_boolean":"B?","value_integer":"I?","value_text":"Text?","is_required":"B"},"Catalog":{"plan_id":"UUID","family":"E:family","plan_version_id":"UUID","plan_version":"V:CATALOG","pricing_mode":"E:pricing_mode","plan_status":"E:catalog_status","plan_published_at":"TS?","plan_retired_at":"TS?","bundle_version_id":"UUID","bundle_version":"V:BUNDLE","registry_version":"V:REGISTRY","bundle_status":"E:catalog_status","bundle_published_at":"TS?","bundle_retired_at":"TS?","approval_evidence_id":"UUID?","approved_at":"TS?","snapshot_revision":"H","items":"A:Item:0:64:capability_key"},"Authorization":{"kind":"E:authorization_kind","state":"E:approval_state","evidence_id":"UUID?","decided_at":"TS?","quote_id":"UUID?","quote_valid_from":"TS?","quote_valid_until":"TS?","quote_accepted_at":"TS?","commitment_months":"I+?","payment_condition":"Gate"},"Anchor":{"anchor_event_id":"UUID","entity_id":"UUID","effective_at":"TS","recorded_at":"TS","publication_event_id":"UUID?","requests_evidence_id":"UUID?","delay_evidence_id":"UUID?","cause_at_deadline":"E:delay_cause?"},"Extension":{"extension_id":"UUID","term_id":"UUID","revision":"I+","evidence_id":"UUID","recorded_at":"TS","effective_end":"TS"},"Term":{"term_id":"UUID","source_id":"UUID","agreement_id":"UUID","agreement_revision":"I+","plan_version_id":"UUID","bundle_version_id":"UUID","purpose":"E:term_purpose","predecessor_term_id":"UUID?","duration_months":"I+","purchased_at":"TS","authorization":"Authorization","anchor_rule":"E:anchor_rule","anchor":"Anchor?","original_end":"TS?","effective_end":"TS?","extensions":"A:Extension:0:32:revision,extension_id"},"Grant":{"grant_id":"UUID","source_id":"UUID","entity_id":"UUID","program_id":"UUID","program_version":"V:PROGRAM","program_approval_evidence_id":"UUID","grant_approval_evidence_id":"UUID","once_per_entity_evidence_id":"UUID","plan_version_id":"UUID","bundle_version_id":"UUID","selected_at":"TS","formal_launch_event_id":"UUID?","formal_launch_at":"TS?","first_post_launch_publication_event_id":"UUID?","first_post_launch_publication_at":"TS?","start_at":"TS?","end_at":"TS?","exception_dependency":"E:policy_dependency?"},"EntitlementInput":{"envelope_kind":"K:ENTITLEMENT_INPUT","input_version":"V:INPUT","evaluator_version":"V:EVALUATOR","calendar_rule_version":"V:CALENDAR","source_origin":"E:source_origin","entity_id":"UUID","as_of":"TS","input_revision":"H","synthetic_provider_revision":"I+?","providers":"Providers","model_eligibility":"Gate","agreement":"Agreement?","catalog":"A:Catalog:0:40:plan_version_id","terms":"A:Term:0:32:term_id","grants":"A:Grant:0:8:grant_id","enforcement":"Enforcement","prior_publication":"History?"},"Capability":{"value_kind":"E:value_kind","value":"Scalar?","commercial_permission":"E:commercial_permission","reason_codes":"A:Reason:0:64:"},"Capabilities":{"branches.included":"Capability","team.active_member_max":"Capability","media.upload_enabled":"Capability","analytics.available":"Capability","sponsored.purchase_eligible":"Capability"},"Scope":{"scope_id":"UUID","category_id":"UUID","market_id":"UUID","market_context":"E:market_context","revision":"I+"},"Projection":{"descriptor_id":"UUID","entity_id":"UUID","content_revision":"I+","kind":"E:projection_kind","format_version":"V:PROJECTION_FORMAT","approval":"Gate","public_field_paths":"A:Path:1:32:","conformance":"Gate","projection_revision":"G?","candidate_generation":"G?"},"PublicationInput":{"envelope_kind":"K:PUBLICATION_INPUT","input_version":"V:INPUT","evaluator_version":"V:EVALUATOR","calendar_rule_version":"V:CALENDAR","entity_id":"UUID","source_origin":"E:source_origin","as_of":"TS","synthetic_provider_revision":"I+?","entitlement_input_revision":"H?","entitlement_result_fingerprint":"H","publication_input_revision":"H","legacy_visible":"B","scope":"Scope?","content_revision":"I+?","required_fields":"Gate","onboarding":"Gate","moderation":"Gate","verification_requirement":"E:verification_requirement","verification_state":"E:verification_state","verification":"Gate","enforcement":"Enforcement","launch":"Gate","projection":"Projection?","prior_publication":"History?","authority_revision":"G?","projection_revision":"G?","authoritative_generation":"G?","candidate_generation":"G?"},"EntitlementResult":{"envelope_kind":"K:ENTITLEMENT_RESULT","input_version":"V:INPUT","evaluator_version":"V:EVALUATOR","calendar_rule_version":"V:CALENDAR","entity_id":"UUID?","source_origin":"E:source_origin?","as_of":"TS?","input_revision":"H?","synthetic_provider_revision":"I?","authority_outcome":"E:authority_outcome","basis_context":"E:basis_context?","source_kind":"E:source_kind?","entitlement_outcome":"E:entitlement_outcome","enforcement_context":"E:enforcement_context","enforcement_revision":"I?","continuity_eligible":"B","agreement_id":"UUID?","term_id":"UUID?","grant_id":"UUID?","plan_id":"UUID?","plan_version_id":"UUID?","plan_version":"V:CATALOG?","bundle_version_id":"UUID?","bundle_version":"V:BUNDLE?","registry_version":"V:REGISTRY?","snapshot_revision":"H?","original_start":"TS?","original_end":"TS?","effective_end":"TS?","grace_end":"TS?","prior_publication_event_id":"UUID?","capabilities":"Capabilities","next_boundary":"TS?","reason_codes":"A:Reason:0:64:","result_fingerprint":"H"}}'::jsonb;
  v_vocab constant jsonb := '{"provider_status":["COMPLETE","UNAVAILABLE"],"source_origin":["runtime_shadow","test_fixture"],"gate_status":["PASS","FAIL","UNKNOWN","BLOCKED_POLICY"],"policy_dependency":["OQ-48","OQ-49","OQ-72","OQ-76","OQ-77","OQ-79","OQ-80","OQ-81","OQ-82","OQ-83","OQ-84"],"approval_state":["APPROVED","PENDING","REJECTED","UNKNOWN"],"enforcement_context":["CLEAR","WARNING","SUSPENDED","TERMINATED","CLOSED","UNKNOWN"],"source_kind":["PAID_TERM","A8_PROMOTIONAL_GRANT"],"family":["business","business_pro","business_plus","corporate"],"pricing_mode":["retail","custom_quote"],"catalog_status":["DRAFT","PUBLISHED","RETIRED"],"value_kind":["boolean","integer","text"],"authorization_kind":["VERIFIED_FUNDS","CORPORATE_WRITTEN"],"term_purpose":["INITIAL","RENEWAL","REACTIVATION"],"anchor_rule":["PUBLICATION","CUSTOMER_DELAY_DAY15","RENEWAL_BOUNDARY","REPUBLICATION"],"delay_cause":["CUSTOMER_ONLY","CIVILPEDIA","MIXED","UNKNOWN"],"commercial_permission":["ALLOW","DENY"],"market_context":["BAGHDAD"],"projection_kind":["CANDIDATE","SELECTED"],"verification_requirement":["REQUIRED","NOT_REQUIRED","UNKNOWN"],"verification_state":["VERIFIED","UNVERIFIED","UNKNOWN"],"authority_outcome":["COMPLETE","INCOMPLETE_AUTHORITY","CONFLICTING_AUTHORITY","UNSUPPORTED_VERSION"],"basis_context":["NONE","PENDING_ANCHOR","FUTURE","IN_EFFECT","GRACE","AFTER_GRACE"],"entitlement_outcome":["ENTITLED","NOT_ENTITLED","UNKNOWN_FAIL_CLOSED"]}'::jsonb;
  v_reason_vocabulary constant jsonb := '["INVALID_ENVELOPE","MISSING_REQUIRED_FIELD","UNKNOWN_FIELD","INVALID_FIELD_TYPE","INVALID_ENUM","INVALID_UUID","INVALID_TIMESTAMP","NONFINITE_TIMESTAMP","INVALID_GENERATION","INPUT_BOUND_EXCEEDED","UNSUPPORTED_INPUT_VERSION","UNSUPPORTED_EVALUATOR_VERSION","UNSUPPORTED_CALENDAR_VERSION","UNSUPPORTED_CATALOG_VERSION","UNSUPPORTED_BUNDLE_VERSION","UNSUPPORTED_REGISTRY_VERSION","UNSUPPORTED_PROGRAM_VERSION","UNSUPPORTED_PROJECTION_FORMAT","BINDING_MISMATCH","INPUT_REVISION_MISMATCH","DUPLICATE_TERM_ID","DUPLICATE_GRANT_ID","DUPLICATE_SOURCE_ID","DUPLICATE_CAPABILITY_KEY","DUPLICATE_REVISION_IDENTITY","CANONICAL_PROVIDER_UNAVAILABLE","RUNTIME_AUTHORITY_UNAVAILABLE","ELIGIBILITY_NOT_PROVEN","APPROVAL_NOT_PROVEN","CATALOG_NOT_APPROVED","BUNDLE_MISSING","CAPABILITY_MISSING","CAPABILITY_DISABLED","UNKNOWN_REQUIRED_CAPABILITY","MALFORMED_CAPABILITY","NO_APPLICABLE_BASIS","AUTHORIZATION_NOT_PROVEN","CORPORATE_TERMS_INVALID","INVALID_TERM_CHAIN","OVERLAPPING_BASIS","ANCHOR_PENDING","ANCHOR_EVIDENCE_MISSING","ANCHOR_CONFLICT","A8_PUBLICATION_ANCHOR_MISSING","POLICY_DEPENDENCY_BLOCKED","FUTURE_BASIS","TERM_EXPIRED","GRACE_CONTINUITY","GRACE_ENDED","PRIOR_PUBLICATION_NOT_PROVEN","ENFORCEMENT_UNKNOWN","ENFORCEMENT_DENIED","REQUIRED_FIELDS_NOT_PROVEN","ONBOARDING_NOT_PROVEN","MODERATION_NOT_PROVEN","VERIFICATION_NOT_PROVEN","LAUNCH_NOT_PROVEN","PROJECTION_NOT_PROVEN","GENERATION_MISSING","GENERATION_MISMATCH","ENTITLEMENT_NOT_IN_EFFECT","STALE_SHADOW_GENERATION","REQUEST_ID_CONFLICT","INTERNAL_EVALUATION_ERROR"]'::jsonb;
  v_queue jsonb[]; v_errors jsonb := '[]'::jsonb; v_valid jsonb := '{}'::jsonb;
  v_cursor integer := 0; v_node jsonb; v_value jsonb; v_path text; v_type text;
  v_key text; v_descriptor text; v_code text; v_priority integer; v_entry jsonb;
  v_index bigint; v_parts text[]; v_previous text; v_sort text; v_number numeric;
  v_text text; v_expected text; v_timestamp timestamptz; v_failure text;
  v_root jsonb; v_root_path text; v_required text[]; v_null text[];

  v_out jsonb := '{"envelope_kind":"ENTITLEMENT_RESULT","input_version":"m3.input.v1","evaluator_version":"m3.evaluator.v1","calendar_rule_version":"m3.baghdad_calendar.v1","entity_id":null,"source_origin":null,"as_of":null,"input_revision":null,"synthetic_provider_revision":null,"authority_outcome":"INCOMPLETE_AUTHORITY","basis_context":null,"source_kind":null,"entitlement_outcome":"UNKNOWN_FAIL_CLOSED","enforcement_context":"UNKNOWN","enforcement_revision":null,"continuity_eligible":false,"agreement_id":null,"term_id":null,"grant_id":null,"plan_id":null,"plan_version_id":null,"plan_version":null,"bundle_version_id":null,"bundle_version":null,"registry_version":null,"snapshot_revision":null,"original_start":null,"original_end":null,"effective_end":null,"grace_end":null,"prior_publication_event_id":null,"capabilities":{"branches.included":{"value_kind":"integer","value":null,"commercial_permission":"DENY","reason_codes":[]},"team.active_member_max":{"value_kind":"integer","value":null,"commercial_permission":"DENY","reason_codes":[]},"media.upload_enabled":{"value_kind":"boolean","value":null,"commercial_permission":"DENY","reason_codes":[]},"analytics.available":{"value_kind":"boolean","value":null,"commercial_permission":"DENY","reason_codes":[]},"sponsored.purchase_eligible":{"value_kind":"boolean","value":null,"commercial_permission":"DENY","reason_codes":[]}},"next_boundary":null,"reason_codes":[],"result_fingerprint":null}'::jsonb;
  v_terms jsonb; v_grants jsonb; v_catalogs jsonb; v_extensions jsonb;
  v_term jsonb; v_grant jsonb; v_catalog jsonb; v_auth jsonb; v_anchor jsonb; v_ext jsonb;
  v_sources jsonb := '[]'::jsonb; v_source jsonb; v_other jsonb; v_selected jsonb;
  v_duplicate record; v_extension_count integer; v_revision bigint;
  v_reasons text[] := ARRAY[]::text[]; v_bad boolean := false; v_conflict boolean := false;
  v_unsupported boolean := false; v_provider_missing boolean := false;
  v_family text; v_family_index integer; v_items jsonb; v_item jsonb; v_known text[];
  v_start timestamptz; v_end timestamptz; v_original_end timestamptz; v_grace timestamptz;
  v_expected_end timestamptz; v_purchase timestamptz; v_previous_end timestamptz;
  v_months bigint; v_context text; v_predecessor jsonb; v_pending integer := 0;
  v_capabilities jsonb; v_cap jsonb; v_cap_value jsonb; v_cap_reasons text[];
  v_permission text; v_selected_catalog jsonb;
BEGIN
  v_root := p_input; v_root_path := 'input';
  v_queue := ARRAY[pg_catalog.jsonb_build_object('path','input','type','EntitlementInput','value',p_input)];
  IF pg_catalog.octet_length(pg_catalog.convert_to(p_input::text,'UTF8'))>65536 THEN
    v_errors := v_errors||'[{"priority":1,"path":"input","code":"INPUT_BOUND_EXCEEDED"}]'::jsonb;
  END IF;

  IF p_as_of IS NULL THEN
    v_errors := v_errors || '[{"priority":7,"path":"$p_as_of","code":"INVALID_TIMESTAMP"}]'::jsonb;
  ELSIF NOT pg_catalog.isfinite(p_as_of) THEN
    v_errors := v_errors || '[{"priority":7,"path":"$p_as_of","code":"NONFINITE_TIMESTAMP"}]'::jsonb;
  ELSIF EXTRACT(YEAR FROM pg_catalog.timezone('UTC',p_as_of)) NOT BETWEEN 1 AND 9999 THEN
    v_errors := v_errors || '[{"priority":7,"path":"$p_as_of","code":"INVALID_TIMESTAMP"}]'::jsonb;
  END IF;


  -- The queue traverses closed shapes; diagnostics are selected by normative
  -- priority and ASCII path, independent of JSONB's storage key order.
  WHILE v_cursor < pg_catalog.cardinality(v_queue) LOOP
    v_node := (v_queue[v_cursor+1]::text)::jsonb; v_cursor := v_cursor + 1;
    v_value := v_node -> 'value'; v_path := v_node ->> 'path';
    v_type := v_node ->> 'type'; v_code := NULL; v_priority := 5;
    IF pg_catalog.right(v_type,1) = '?' THEN
      v_type := pg_catalog.left(v_type,pg_catalog.length(v_type)-1);
      IF v_value = 'null'::jsonb THEN CONTINUE; END IF;
    END IF;
    IF v_shapes ? v_type THEN
      IF pg_catalog.jsonb_typeof(v_value) IS DISTINCT FROM 'object' THEN
        v_code := CASE WHEN v_path IN ('input','entitlement_result','publication_input')
          THEN 'INVALID_ENVELOPE' ELSE 'INVALID_FIELD_TYPE' END;
        v_priority := CASE WHEN v_code='INVALID_ENVELOPE' THEN 2 ELSE 5 END;
      ELSE
        FOR v_key,v_descriptor IN SELECT k.key,k.value FROM pg_catalog.jsonb_each_text(v_shapes -> v_type) k ORDER BY k.key COLLATE "C" LOOP
          IF NOT (v_value ? v_key) THEN
            v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',3,'path',v_path||'.'||v_key,'code','MISSING_REQUIRED_FIELD'));
          ELSE
            v_queue := pg_catalog.array_append(v_queue,pg_catalog.jsonb_build_object('path',v_path||'.'||v_key,'type',v_descriptor,'value',v_value -> v_key));
          END IF;
        END LOOP;
        FOR v_key IN SELECT k.key FROM pg_catalog.jsonb_object_keys(v_value) k(key) WHERE NOT ((v_shapes -> v_type) ? k.key) ORDER BY k.key COLLATE "C" LOOP
          v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',4,'path',v_path||'.'||v_key,'code','UNKNOWN_FIELD'));
        END LOOP;
      END IF;
    ELSIF pg_catalog.left(v_type,2)='A:' THEN
      v_parts := pg_catalog.string_to_array(v_type,':');
      IF pg_catalog.jsonb_typeof(v_value) IS DISTINCT FROM 'array' THEN v_code := 'INVALID_FIELD_TYPE';
      ELSIF pg_catalog.jsonb_array_length(v_value) < v_parts[3]::integer OR pg_catalog.jsonb_array_length(v_value) > v_parts[4]::integer THEN
        v_code := 'INPUT_BOUND_EXCEEDED'; v_priority := 1;
      ELSE
        v_previous := NULL;
        FOR v_entry,v_index IN SELECT a.value,a.ordinality FROM pg_catalog.jsonb_array_elements(v_value) WITH ORDINALITY a(value,ordinality) LOOP
          v_queue := pg_catalog.array_append(v_queue,pg_catalog.jsonb_build_object('path',v_path||'['||pg_catalog.lpad(v_index::text,5,'0')||']','type',v_parts[2],'value',v_entry));
          v_sort := CASE WHEN v_parts[5]='revision,extension_id' THEN NULL
            WHEN v_parts[5]<>'' THEN v_entry ->> v_parts[5]
            WHEN v_parts[2] IN ('Reason','Path') THEN v_entry #>> '{}'
            ELSE NULL END;
          -- Numeric spelling is not revision order. Validate before conversion;
          -- malformed revisions are diagnosed by the queued scalar validator.
          IF v_parts[5]='revision,extension_id' AND pg_catalog.jsonb_typeof(v_entry -> 'revision')='number' THEN
            v_number := (v_entry ->> 'revision')::numeric;
            IF v_number=pg_catalog.trunc(v_number) AND v_number BETWEEN 1 AND 9223372036854775807 THEN
              v_sort := pg_catalog.lpad(pg_catalog.trunc(v_number)::text,19,'0')||':'||(v_entry ->> 'extension_id');
            END IF;
          END IF;
          IF v_sort IS NOT NULL AND v_previous IS NOT NULL AND v_sort COLLATE "C" < v_previous COLLATE "C" THEN
            v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',5,'path',v_path,'code','INVALID_ENVELOPE'));
          END IF;
          IF v_parts[2] IN ('Reason','Path') AND v_sort IS NOT NULL AND v_sort=v_previous THEN
            v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',5,'path',v_path,'code','INVALID_FIELD_TYPE'));
          END IF;
          v_previous := v_sort;
        END LOOP;
      END IF;
    ELSIF v_type='B' THEN
      IF pg_catalog.jsonb_typeof(v_value) IS DISTINCT FROM 'boolean' THEN v_code := 'INVALID_FIELD_TYPE'; END IF;
    ELSIF v_type IN ('I','I+','G') OR pg_catalog.left(v_type,2)='V:' AND v_type IN ('V:CATALOG','V:BUNDLE','V:REGISTRY','V:PROGRAM') THEN
      IF pg_catalog.jsonb_typeof(v_value) IS DISTINCT FROM 'number' THEN v_code := CASE WHEN v_type='G' THEN 'INVALID_GENERATION' ELSE 'INVALID_FIELD_TYPE' END;
      ELSE
        v_number := (v_value #>> '{}')::numeric;
        IF v_number<>pg_catalog.trunc(v_number) OR v_number<0 OR v_number>9223372036854775807 OR v_type='I+' AND v_number<1 THEN
          v_code := CASE WHEN v_type='G' THEN 'INVALID_GENERATION' ELSE 'INVALID_FIELD_TYPE' END;
        ELSIF pg_catalog.left(v_type,2)='V:' AND v_number<>1 THEN v_code := CASE WHEN v_type='V:PROJECTION_FORMAT' THEN 'UNSUPPORTED_PROJECTION_FORMAT' ELSE 'UNSUPPORTED_'||pg_catalog.substr(v_type,3)||'_VERSION' END; v_priority := 8;
        END IF;
      END IF;
    ELSIF v_type='Scalar' THEN
      IF pg_catalog.jsonb_typeof(v_value) NOT IN ('boolean','number') THEN v_code := 'INVALID_FIELD_TYPE'; END IF;
    ELSE
      IF pg_catalog.jsonb_typeof(v_value) IS DISTINCT FROM 'string' THEN v_code := 'INVALID_FIELD_TYPE';
      ELSE
        v_text := v_value #>> '{}';
        IF v_type='UUID' THEN
          IF v_text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' OR v_text='00000000-0000-0000-0000-000000000000' THEN v_code := 'INVALID_UUID'; v_priority := 6; END IF;
        ELSIF v_type='TS' THEN
          v_priority := 7;
          IF v_text IN ('infinity','-infinity') THEN v_code := 'NONFINITE_TIMESTAMP';
          ELSIF v_text !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{6}Z$'
            OR pg_catalog.left(v_text,4)='0000' OR pg_catalog.substr(v_text,18,2)='60' THEN v_code := 'INVALID_TIMESTAMP';
          ELSE
            BEGIN
              v_timestamp := v_text::timestamptz;
              IF pg_catalog.to_char(pg_catalog.timezone('UTC',v_timestamp),'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')<>v_text THEN v_code := 'INVALID_TIMESTAMP'; END IF;
            EXCEPTION WHEN invalid_datetime_format OR datetime_field_overflow THEN v_code := 'INVALID_TIMESTAMP';
            END;
          END IF;
        ELSIF v_type='H' THEN
          IF v_text !~ '^[0-9a-f]{64}$' THEN v_code := 'INVALID_FIELD_TYPE'; END IF;
        ELSIF pg_catalog.left(v_type,2)='V:' THEN
          v_expected := CASE v_type WHEN 'V:INPUT' THEN 'm3.input.v1' WHEN 'V:EVALUATOR' THEN 'm3.evaluator.v1'
            WHEN 'V:CALENDAR' THEN 'm3.baghdad_calendar.v1' WHEN 'V:PROJECTION_FORMAT' THEN 'm3.public_descriptor.v1' END;
          IF v_text IS DISTINCT FROM v_expected THEN v_code := CASE WHEN v_type='V:PROJECTION_FORMAT' THEN 'UNSUPPORTED_PROJECTION_FORMAT' ELSE 'UNSUPPORTED_'||pg_catalog.substr(v_type,3)||'_VERSION' END; v_priority := 8; END IF;
        ELSIF pg_catalog.left(v_type,2)='E:' THEN
          IF NOT ((v_vocab -> pg_catalog.substr(v_type,3)) ? v_text) THEN v_code := 'INVALID_ENUM'; v_priority := 9; END IF;
        ELSIF pg_catalog.left(v_type,2)='K:' THEN
          IF v_text IS DISTINCT FROM pg_catalog.substr(v_type,3) THEN v_code := 'INVALID_ENUM'; v_priority := 9; END IF;
        ELSIF v_type='Reason' THEN
          IF NOT (v_reason_vocabulary ? v_text) THEN v_code := 'INVALID_ENUM'; v_priority := 9; END IF;
        ELSIF v_type='Key' THEN
          IF pg_catalog.length(v_text) NOT BETWEEN 1 AND 128 OR v_text !~ '^[\x01-\x7f]+$' THEN v_code := 'INVALID_FIELD_TYPE'; END IF;
        ELSIF v_type='Text' THEN
          IF pg_catalog.length(v_text) NOT BETWEEN 1 AND 256 OR pg_catalog.btrim(v_text)='' THEN v_code := 'INVALID_FIELD_TYPE'; END IF;
        ELSIF v_type='Path' THEN
          IF pg_catalog.length(v_text)=0 OR v_text !~ '^[\x01-\x7f]+$' THEN v_code := 'INVALID_FIELD_TYPE'; END IF;
        END IF;
      END IF;
    END IF;
    IF v_code IS NOT NULL THEN
      v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',v_priority,'path',v_path,'code',v_code));
    ELSE
      v_valid := v_valid || pg_catalog.jsonb_build_object(v_path,true);
    END IF;
  END LOOP;


  -- Conditional nulls and supplied fact links are validated before semantic
  -- evaluation. Dependency identifiers belong to their own existing Gate.
  FOR v_node IN SELECT n.value FROM pg_catalog.unnest(v_queue) n(value) LOOP
    v_value := v_node -> 'value'; v_path := v_node ->> 'path';
    v_type := pg_catalog.rtrim(v_node ->> 'type','?');
    IF pg_catalog.jsonb_typeof(v_value)<>'object' THEN CONTINUE; END IF;
    IF v_value ? 'entity_id' AND v_path NOT IN ('input','publication_input','entitlement_result')
       AND v_value ->> 'entity_id' IS DISTINCT FROM v_root ->> 'entity_id' THEN
      v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.entity_id','code','BINDING_MISMATCH'));
    END IF;
    v_required := ARRAY[]::text[]; v_null := ARRAY[]::text[];
    IF v_type='Gate' THEN
      IF v_value ->> 'status' IN ('PASS','FAIL') THEN
        v_required := ARRAY['evidence_id','revision','decided_at'];
      ELSIF v_value ->> 'status' IN ('UNKNOWN','BLOCKED_POLICY') THEN
        v_null := ARRAY['evidence_id','revision','decided_at','content_revision','requirements_revision','scope_id'];
      END IF;
      IF v_value ->> 'status'='BLOCKED_POLICY' THEN v_required := v_required||ARRAY['policy_dependency'];
      ELSIF v_value -> 'policy_dependency'<>'null'::jsonb THEN
        v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.policy_dependency','code','BINDING_MISMATCH'));
      END IF;
      IF v_valid ? (v_path||'.decided_at') AND (v_value ->> 'decided_at')::timestamptz > p_as_of THEN
        v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.decided_at','code','BINDING_MISMATCH'));
      END IF;
    ELSIF v_type='Provider' THEN
      IF v_value ->> 'status'='COMPLETE' THEN v_required := ARRAY['revision'];
      ELSIF v_value ->> 'status'='UNAVAILABLE' THEN v_null := ARRAY['revision']; END IF;
      IF v_value ->> 'source_origin' IS DISTINCT FROM v_root ->> 'source_origin' THEN
        v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.source_origin','code','BINDING_MISMATCH'));
      END IF;
    ELSIF v_type='Enforcement' THEN
      IF v_value ->> 'context'='UNKNOWN' THEN v_null := ARRAY['evidence_id','revision','effective_at'];
      ELSIF v_value ->> 'context' IN ('CLEAR','WARNING','SUSPENDED','TERMINATED','CLOSED') THEN v_required := ARRAY['evidence_id','revision','effective_at']; END IF;
      IF v_valid ? (v_path||'.effective_at') AND (v_value ->> 'effective_at')::timestamptz > p_as_of THEN
        v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.effective_at','code','BINDING_MISMATCH'));
      END IF;
    ELSIF v_type='Agreement' THEN
      IF v_value ->> 'approval_state'='APPROVED' THEN v_required := ARRAY['approval_evidence_id','approved_at'];
      ELSIF v_value ->> 'approval_state' IN ('PENDING','REJECTED','UNKNOWN') THEN v_null := ARRAY['approved_at']; END IF;

    ELSIF v_type='Authorization' THEN
      IF v_value ->> 'state'='APPROVED' THEN
        v_required := ARRAY['evidence_id','decided_at'];
        IF v_value ->> 'kind'='CORPORATE_WRITTEN' THEN
          v_required := v_required||ARRAY['quote_id','quote_valid_from','quote_valid_until','quote_accepted_at','commitment_months'];
        END IF;
      ELSIF v_value ->> 'state' IN ('PENDING','REJECTED','UNKNOWN') THEN v_null := ARRAY['decided_at']; END IF;
      IF v_value ->> 'kind'='VERIFIED_FUNDS' THEN v_null := v_null||ARRAY['quote_id','quote_valid_from','quote_valid_until','quote_accepted_at','commitment_months']; END IF;
    ELSIF v_type='Catalog' THEN
      IF v_valid ? (v_path||'.approved_at') AND (v_value ->> 'approved_at')::timestamptz>p_as_of THEN
        v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.approved_at','code','BINDING_MISMATCH'));
      END IF;
      FOREACH v_key IN ARRAY ARRAY['plan','bundle'] LOOP
        IF v_valid ? (v_path||'.'||v_key||'_retired_at') AND v_valid ? (v_path||'.'||v_key||'_published_at')
          AND (v_value ->> (v_key||'_retired_at'))::timestamptz < (v_value ->> (v_key||'_published_at'))::timestamptz THEN
          v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.'||v_key||'_retired_at','code','BINDING_MISMATCH'));
        END IF;
        IF v_value ->> (v_key||'_status')='DRAFT' THEN
          v_null := v_null||ARRAY[v_key||'_published_at',v_key||'_retired_at'];
        ELSIF v_value ->> (v_key||'_status')='PUBLISHED' THEN
          v_required := v_required||ARRAY[v_key||'_published_at']; v_null := v_null||ARRAY[v_key||'_retired_at'];
        ELSIF v_value ->> (v_key||'_status')='RETIRED' THEN
          v_required := v_required||ARRAY[v_key||'_published_at',v_key||'_retired_at'];
        END IF;
      END LOOP;
    END IF;
    IF v_type='Gate' AND v_root_path='input' THEN
      FOREACH v_key IN ARRAY ARRAY['content_revision','requirements_revision','scope_id'] LOOP
        IF v_value ? v_key AND v_value -> v_key<>'null'::jsonb THEN
          v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.'||v_key,'code','BINDING_MISMATCH'));
        END IF;
      END LOOP;
    END IF;
    IF v_type='Agreement' AND v_valid ? (v_path||'.approved_at') AND (v_value ->> 'approved_at')::timestamptz>p_as_of THEN
      v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.approved_at','code','BINDING_MISMATCH'));
    END IF;
    FOREACH v_key IN ARRAY v_required LOOP
      IF v_value -> v_key='null'::jsonb THEN
        v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',5,'path',v_path||'.'||v_key,'code','INVALID_FIELD_TYPE'));
      END IF;
    END LOOP;
    FOREACH v_key IN ARRAY v_null LOOP
      IF v_value ? v_key AND v_value -> v_key<>'null'::jsonb THEN
        v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',5,'path',v_path||'.'||v_key,'code','INVALID_FIELD_TYPE'));
      END IF;
    END LOOP;
  END LOOP;
  IF v_root ->> 'source_origin'='test_fixture' AND v_root -> 'synthetic_provider_revision'='null'::jsonb THEN
    v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',5,'path',v_root_path||'.synthetic_provider_revision','code','INVALID_FIELD_TYPE'));
  ELSIF v_root ->> 'source_origin'='runtime_shadow' AND v_root -> 'synthetic_provider_revision'<>'null'::jsonb THEN
    v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_root_path||'.synthetic_provider_revision','code','BINDING_MISMATCH'));
  END IF;
  IF v_valid ? (v_root_path||'.as_of') AND (v_root ->> 'as_of')::timestamptz IS DISTINCT FROM p_as_of THEN
    v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_root_path||'.as_of','code','BINDING_MISMATCH'));
  END IF;


  v_terms := CASE WHEN pg_catalog.jsonb_typeof(p_input -> 'terms')='array' THEN p_input -> 'terms' ELSE '[]'::jsonb END;
  v_grants := CASE WHEN pg_catalog.jsonb_typeof(p_input -> 'grants')='array' THEN p_input -> 'grants' ELSE '[]'::jsonb END;
  v_catalogs := CASE WHEN pg_catalog.jsonb_typeof(p_input -> 'catalog')='array' THEN p_input -> 'catalog' ELSE '[]'::jsonb END;


  -- Multiplicity, not JSONB containment, detects semantic identities.
  FOR v_duplicate IN
    SELECT 10 AS priority,'input.terms.term_id' AS path,'DUPLICATE_TERM_ID' AS code WHERE EXISTS
      (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_terms) a GROUP BY a ->> 'term_id' HAVING count(*)>1)
    UNION ALL SELECT 10,'input.grants.grant_id','DUPLICATE_GRANT_ID' WHERE EXISTS
      (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_grants) a GROUP BY a ->> 'grant_id' HAVING count(*)>1)
    UNION ALL SELECT 10,'input.sources.source_id','DUPLICATE_SOURCE_ID' WHERE EXISTS
      (SELECT 1 FROM (SELECT a ->> 'source_id' id FROM pg_catalog.jsonb_array_elements(v_terms||v_grants) a) s GROUP BY s.id HAVING count(*)>1)
    UNION ALL SELECT 10,'input.catalog.plan_version_id','DUPLICATE_REVISION_IDENTITY' WHERE EXISTS
      (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_catalogs) a GROUP BY a -> 'plan_version_id',a -> 'plan_version' HAVING count(*)>1)
    UNION ALL SELECT 10,'input.catalog.bundle_version_id','DUPLICATE_REVISION_IDENTITY' WHERE EXISTS
      (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_catalogs) a GROUP BY a -> 'bundle_version_id',a -> 'bundle_version' HAVING count(*)>1)
  LOOP v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.to_jsonb(v_duplicate)); END LOOP;
  v_extension_count := 0; v_extensions := '[]'::jsonb;
  FOR v_term IN SELECT a.value FROM pg_catalog.jsonb_array_elements(v_terms) a(value) LOOP
    IF pg_catalog.jsonb_typeof(v_term -> 'extensions')='array' THEN
      v_extension_count := v_extension_count + pg_catalog.jsonb_array_length(v_term -> 'extensions');
      v_extensions := v_extensions||(v_term -> 'extensions');
    END IF;
  END LOOP;
  IF v_extension_count>32 THEN v_errors := v_errors||'[{"priority":1,"path":"input.terms.extensions","code":"INPUT_BOUND_EXCEEDED"}]'::jsonb; END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_extensions) a GROUP BY a ->> 'extension_id' HAVING count(*)>1)
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_extensions) a GROUP BY a ->> 'term_id',a -> 'revision' HAVING count(*)>1)
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_terms) a WHERE a ->> 'predecessor_term_id' IS NOT NULL GROUP BY a ->> 'predecessor_term_id' HAVING count(*)>1) THEN
    v_errors := v_errors||'[{"priority":10,"path":"input.terms.extensions","code":"DUPLICATE_REVISION_IDENTITY"}]'::jsonb;
  END IF;
  FOR v_catalog IN SELECT a.value FROM pg_catalog.jsonb_array_elements(v_catalogs) a(value) LOOP
    IF pg_catalog.jsonb_typeof(v_catalog -> 'items')='array' AND EXISTS
      (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_catalog -> 'items') a GROUP BY a ->> 'capability_key' HAVING count(*)>1) THEN
      v_errors := v_errors||'[{"priority":10,"path":"input.catalog.items","code":"DUPLICATE_CAPABILITY_KEY"}]'::jsonb;
    END IF;
  END LOOP;

  IF pg_catalog.jsonb_array_length(v_errors)=0 THEN
    -- Fingerprints are checked only after structural/duplicate validation.
    IF p_input ->> 'input_revision' IS DISTINCT FROM pg_catalog.encode(extensions.digest(pg_catalog.convert_to((p_input - 'input_revision')::text,'UTF8'),'sha256'),'hex') THEN
      v_errors := v_errors||'[{"priority":11,"path":"input.input_revision","code":"INPUT_REVISION_MISMATCH"}]'::jsonb;
    END IF;
    FOR v_catalog IN SELECT a.value FROM pg_catalog.jsonb_array_elements(v_catalogs) a(value) LOOP
      IF v_catalog ->> 'snapshot_revision' IS DISTINCT FROM pg_catalog.encode(extensions.digest(pg_catalog.convert_to((v_catalog - 'snapshot_revision')::text,'UTF8'),'sha256'),'hex') THEN
        v_errors := v_errors||'[{"priority":11,"path":"input.catalog.snapshot_revision","code":"INPUT_REVISION_MISMATCH"}]'::jsonb;
      END IF;
      v_family_index := CASE v_catalog ->> 'family' WHEN 'business' THEN 1 WHEN 'business_pro' THEN 2 WHEN 'business_plus' THEN 3 WHEN 'corporate' THEN 4 END;
      IF v_catalog ->> 'plan_id'<>pg_catalog.format('1a7b000%s-0000-4000-8000-00000000000%s',v_family_index,v_family_index)
         OR v_catalog ->> 'plan_version_id'<>pg_catalog.format('4c7b000%s-0000-4000-8000-00000000000%s',v_family_index,v_family_index)
         OR v_catalog ->> 'bundle_version_id'<>pg_catalog.format('2e7b000%s-0000-4000-8000-00000000000%s',v_family_index,v_family_index)
         OR v_catalog ->> 'pricing_mode'<>(CASE WHEN v_family_index=4 THEN 'custom_quote' ELSE 'retail' END) THEN
        v_errors := v_errors||'[{"priority":11,"path":"input.catalog.identity","code":"BINDING_MISMATCH"}]'::jsonb;
      END IF;
    END LOOP;
    FOR v_term IN SELECT a.value FROM pg_catalog.jsonb_array_elements(v_terms) a(value) LOOP
      IF v_term ->> 'agreement_id' IS DISTINCT FROM p_input #>> '{agreement,agreement_id}'
         OR v_term -> 'agreement_revision' IS DISTINCT FROM p_input #> '{agreement,revision}'
         OR (v_term ->> 'purchased_at')::timestamptz > p_as_of THEN
        v_errors := v_errors||'[{"priority":11,"path":"input.terms.agreement","code":"BINDING_MISMATCH"}]'::jsonb;
      END IF;
    END LOOP;
    FOR v_grant IN SELECT a.value FROM pg_catalog.jsonb_array_elements(v_grants) a(value) LOOP
      IF (v_grant ->> 'selected_at')::timestamptz > p_as_of
         OR v_grant ->> 'exception_dependency' IS NOT NULL AND v_grant ->> 'exception_dependency' NOT IN ('OQ-72','OQ-80','OQ-81') THEN
        v_errors := v_errors||'[{"priority":11,"path":"input.grants.binding","code":"BINDING_MISMATCH"}]'::jsonb;
      END IF;
    END LOOP;
  END IF;
  IF v_valid ? 'input.entity_id' THEN v_out := pg_catalog.jsonb_set(v_out,'{entity_id}',p_input -> 'entity_id'); END IF;
  IF v_valid ? 'input.source_origin' THEN v_out := pg_catalog.jsonb_set(v_out,'{source_origin}',p_input -> 'source_origin'); END IF;
  IF v_valid ? 'input.as_of' AND p_as_of IS NOT NULL AND pg_catalog.isfinite(p_as_of)
     AND (p_input ->> 'as_of')::timestamptz=p_as_of THEN v_out := pg_catalog.jsonb_set(v_out,'{as_of}',p_input -> 'as_of'); END IF;
  IF v_valid ? 'input.synthetic_provider_revision' THEN v_out := pg_catalog.jsonb_set(v_out,'{synthetic_provider_revision}',p_input -> 'synthetic_provider_revision'); END IF;
  SELECT x.value ->> 'code' INTO v_failure FROM pg_catalog.jsonb_array_elements(v_errors) x(value)
    ORDER BY (x.value ->> 'priority')::integer,(x.value ->> 'path') COLLATE "C",x.value ->> 'code' LIMIT 1;
  <<evaluate>>
  BEGIN
    IF v_failure IS NOT NULL THEN
      v_reasons := ARRAY[v_failure];
      v_out := v_out||pg_catalog.jsonb_build_object('authority_outcome',CASE WHEN v_failure LIKE 'UNSUPPORTED_%' THEN 'UNSUPPORTED_VERSION' WHEN v_failure LIKE 'DUPLICATE_%' THEN 'CONFLICTING_AUTHORITY' ELSE 'INCOMPLETE_AUTHORITY' END);
      EXIT evaluate;
    END IF;
    v_out := pg_catalog.jsonb_set(v_out,'{input_revision}',p_input -> 'input_revision');
    IF p_input ->> 'source_origin'='runtime_shadow' THEN
      v_reasons := ARRAY['CANONICAL_PROVIDER_UNAVAILABLE','RUNTIME_AUTHORITY_UNAVAILABLE'];
      EXIT evaluate;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_each(p_input -> 'providers') x WHERE x.value ->> 'status'<>'COMPLETE') THEN
      v_provider_missing := true; v_bad := true; v_reasons := v_reasons||ARRAY['CANONICAL_PROVIDER_UNAVAILABLE'];
    END IF;
    IF p_input #>> '{model_eligibility,status}'<>'PASS' THEN v_bad := true; v_reasons := v_reasons||ARRAY['ELIGIBILITY_NOT_PROVEN']; END IF;
    FOR v_node IN SELECT x.value FROM pg_catalog.unnest(v_queue) x(value) WHERE x.value ->> 'type'='Gate' LOOP
      IF v_node #>> '{value,status}'='BLOCKED_POLICY' THEN v_bad := true; v_reasons := v_reasons||ARRAY['POLICY_DEPENDENCY_BLOCKED']; END IF;
    END LOOP;
    v_out := v_out||pg_catalog.jsonb_build_object('enforcement_context',p_input #>> '{enforcement,context}','enforcement_revision',p_input #> '{enforcement,revision}');
    IF p_input #>> '{enforcement,context}'='UNKNOWN' THEN v_bad := true; v_reasons := v_reasons||ARRAY['ENFORCEMENT_UNKNOWN'];
    ELSIF p_input #>> '{enforcement,context}' IN ('SUSPENDED','TERMINATED','CLOSED') THEN v_reasons := v_reasons||ARRAY['ENFORCEMENT_DENIED']; END IF;
    IF pg_catalog.jsonb_array_length(v_terms)>0 AND p_input #>> '{agreement,approval_state}' IS DISTINCT FROM 'APPROVED' THEN
      v_bad := true; v_reasons := v_reasons||ARRAY['APPROVAL_NOT_PROVEN'];
    END IF;
    -- Every relevant chain record is validated before source selection.
    FOR v_term IN SELECT a.value FROM pg_catalog.jsonb_array_elements(v_terms) a(value) LOOP
      v_auth := v_term -> 'authorization'; v_anchor := v_term -> 'anchor';
      v_purchase := (v_term ->> 'purchased_at')::timestamptz; v_months := (v_term ->> 'duration_months')::numeric::bigint;
      SELECT a.value INTO v_catalog FROM pg_catalog.jsonb_array_elements(v_catalogs) a(value) WHERE a.value -> 'plan_version_id'=v_term -> 'plan_version_id';
      IF v_catalog IS NULL THEN v_bad := true; v_reasons := v_reasons||ARRAY['BUNDLE_MISSING']; CONTINUE; END IF;
      IF v_term -> 'bundle_version_id'<>v_catalog -> 'bundle_version_id' THEN v_failure := 'BINDING_MISMATCH'; EXIT evaluate; END IF;
      v_family := v_catalog ->> 'family';
      IF v_auth ->> 'state'<>'APPROVED' OR v_auth #>> '{payment_condition,status}'<>'PASS' THEN
        v_bad := true; v_reasons := v_reasons||ARRAY['AUTHORIZATION_NOT_PROVEN'];
      END IF;
      IF (v_auth ->> 'decided_at')::timestamptz>v_purchase OR (p_input #>> '{agreement,approved_at}')::timestamptz>v_purchase THEN
        v_failure := 'BINDING_MISMATCH'; EXIT evaluate;
      END IF;
      IF v_family='corporate' THEN
        IF v_auth ->> 'kind'<>'CORPORATE_WRITTEN' OR v_months<12 OR (v_auth ->> 'commitment_months')::numeric::bigint IS DISTINCT FROM v_months
           OR (v_auth ->> 'quote_valid_until')::timestamptz <= (v_auth ->> 'quote_valid_from')::timestamptz
           OR (v_auth ->> 'quote_accepted_at')::timestamptz < (v_auth ->> 'quote_valid_from')::timestamptz
           OR (v_auth ->> 'quote_accepted_at')::timestamptz >= (v_auth ->> 'quote_valid_until')::timestamptz
           OR (v_auth ->> 'quote_accepted_at')::timestamptz > v_purchase THEN
          v_bad := true; v_reasons := v_reasons||ARRAY['CORPORATE_TERMS_INVALID'];
        END IF;
      ELSIF v_months NOT IN (1,3,12) OR v_auth ->> 'kind'<>'VERIFIED_FUNDS' THEN
        v_bad := true; v_reasons := v_reasons||ARRAY['AUTHORIZATION_NOT_PROVEN'];
      END IF;
      IF v_catalog ->> 'plan_status'='DRAFT' OR v_catalog ->> 'bundle_status'='DRAFT'
        OR v_catalog ->> 'approval_evidence_id' IS NULL OR v_catalog ->> 'approved_at' IS NULL
        OR (v_catalog ->> 'approved_at')::timestamptz>v_purchase
        OR (v_catalog ->> 'plan_published_at')::timestamptz>v_purchase OR (v_catalog ->> 'bundle_published_at')::timestamptz>v_purchase
        OR v_catalog ->> 'plan_status'='RETIRED' AND v_purchase >= (v_catalog ->> 'plan_retired_at')::timestamptz
        OR v_catalog ->> 'bundle_status'='RETIRED' AND v_purchase >= (v_catalog ->> 'bundle_retired_at')::timestamptz THEN
        v_bad := true; v_reasons := v_reasons||ARRAY['CATALOG_NOT_APPROVED'];
      END IF;
      v_start := NULL; v_end := NULL; v_original_end := NULL; v_grace := NULL;
      IF v_anchor='null'::jsonb THEN
        IF v_term ->> 'original_end' IS NOT NULL OR v_term ->> 'effective_end' IS NOT NULL OR pg_catalog.jsonb_array_length(v_term -> 'extensions')>0 THEN
          v_bad := true; v_reasons := v_reasons||ARRAY['ANCHOR_EVIDENCE_MISSING'];
        ELSIF v_term ->> 'anchor_rule'='CUSTOMER_DELAY_DAY15' AND p_as_of >= pg_catalog.timezone('Asia/Baghdad',pg_catalog.timezone('Asia/Baghdad',(v_auth ->> 'decided_at')::timestamptz)+pg_catalog.make_interval(days=>14)) THEN
          v_bad := true; v_reasons := v_reasons||ARRAY['ANCHOR_EVIDENCE_MISSING'];
        ELSE v_reasons := v_reasons||ARRAY['ANCHOR_PENDING']; END IF;
      ELSE
        v_start := (v_anchor ->> 'effective_at')::timestamptz;
        IF (v_anchor ->> 'recorded_at')::timestamptz>p_as_of OR v_term ->> 'anchor_rule'<>'RENEWAL_BOUNDARY' AND (v_anchor ->> 'recorded_at')::timestamptz<v_start THEN
          v_failure := 'BINDING_MISMATCH'; EXIT evaluate;
        END IF;
        IF v_term ->> 'anchor_rule' IN ('PUBLICATION','REPUBLICATION') THEN
          IF v_anchor ->> 'publication_event_id' IS NULL THEN v_bad := true; v_reasons := v_reasons||ARRAY['ANCHOR_EVIDENCE_MISSING']; END IF;
          IF v_start<v_purchase OR v_start<(v_auth ->> 'decided_at')::timestamptz
            OR v_start<(v_auth #>> '{payment_condition,decided_at}')::timestamptz
            OR v_anchor ->> 'requests_evidence_id' IS NOT NULL
            OR v_anchor ->> 'delay_evidence_id' IS NOT NULL OR v_anchor ->> 'cause_at_deadline' IS NOT NULL THEN
            v_conflict := true; v_reasons := v_reasons||ARRAY['ANCHOR_CONFLICT'];
          END IF;
        ELSIF v_term ->> 'anchor_rule'='CUSTOMER_DELAY_DAY15' THEN
          IF v_anchor ->> 'requests_evidence_id' IS NULL OR v_anchor ->> 'delay_evidence_id' IS NULL THEN v_bad := true; v_reasons := v_reasons||ARRAY['ANCHOR_EVIDENCE_MISSING']; END IF;
          IF v_auth ->> 'kind'<>'VERIFIED_FUNDS' OR v_anchor ->> 'cause_at_deadline' IS DISTINCT FROM 'CUSTOMER_ONLY'
            OR v_anchor ->> 'publication_event_id' IS NOT NULL
            OR v_start IS DISTINCT FROM pg_catalog.timezone('Asia/Baghdad',pg_catalog.timezone('Asia/Baghdad',(v_auth ->> 'decided_at')::timestamptz)+pg_catalog.make_interval(days=>14)) THEN
            v_conflict := true; v_reasons := v_reasons||ARRAY['ANCHOR_CONFLICT'];
          END IF;
        ELSIF v_anchor ->> 'publication_event_id' IS NOT NULL OR v_anchor ->> 'requests_evidence_id' IS NOT NULL
           OR v_anchor ->> 'delay_evidence_id' IS NOT NULL OR v_anchor ->> 'cause_at_deadline' IS NOT NULL THEN
          v_conflict := true; v_reasons := v_reasons||ARRAY['ANCHOR_CONFLICT'];
        END IF;
        BEGIN
          IF v_months>2147483647 THEN v_failure := 'INVALID_TIMESTAMP'; EXIT evaluate; END IF;
          v_expected_end := pg_catalog.timezone('Asia/Baghdad',pg_catalog.timezone('Asia/Baghdad',v_start)+pg_catalog.make_interval(months=>v_months::integer));
          IF EXTRACT(YEAR FROM pg_catalog.timezone('UTC',v_expected_end)) NOT BETWEEN 1 AND 9999 THEN v_failure := 'INVALID_TIMESTAMP'; EXIT evaluate; END IF;
        EXCEPTION WHEN datetime_field_overflow THEN v_failure := 'INVALID_TIMESTAMP'; EXIT evaluate;
        END;
        v_original_end := (v_term ->> 'original_end')::timestamptz; v_end := (v_term ->> 'effective_end')::timestamptz;
        IF v_original_end IS NULL OR v_end IS NULL THEN v_bad := true; v_reasons := v_reasons||ARRAY['ANCHOR_EVIDENCE_MISSING'];
        ELSIF v_original_end<>v_expected_end THEN v_conflict := true; v_reasons := v_reasons||ARRAY['ANCHOR_CONFLICT']; END IF;
        v_previous_end := v_original_end; v_revision := 0;
        FOR v_ext IN SELECT a.value FROM pg_catalog.jsonb_array_elements(v_term -> 'extensions') a(value) LOOP
          v_revision := v_revision+1;
          IF v_ext -> 'term_id'<>v_term -> 'term_id' OR (v_ext ->> 'revision')::numeric::bigint<>v_revision
            OR (v_ext ->> 'recorded_at')::timestamptz>p_as_of OR (v_ext ->> 'effective_end')::timestamptz<=v_previous_end THEN
            v_conflict := true; v_reasons := v_reasons||ARRAY['INVALID_TERM_CHAIN'];
          END IF;
          v_previous_end := (v_ext ->> 'effective_end')::timestamptz;
        END LOOP;
        IF v_end IS DISTINCT FROM v_previous_end THEN v_conflict := true; v_reasons := v_reasons||ARRAY['ANCHOR_CONFLICT']; END IF;
        v_grace := pg_catalog.timezone('Asia/Baghdad',pg_catalog.timezone('Asia/Baghdad',v_end)+pg_catalog.make_interval(days=>5));
        IF EXTRACT(YEAR FROM pg_catalog.timezone('UTC',v_grace)) NOT BETWEEN 1 AND 9999 THEN v_failure := 'INVALID_TIMESTAMP'; EXIT evaluate; END IF;
      END IF;
      IF v_term ->> 'purpose'='INITIAL' THEN
        IF v_term ->> 'predecessor_term_id' IS NOT NULL OR v_term ->> 'anchor_rule' NOT IN ('PUBLICATION','CUSTOMER_DELAY_DAY15') THEN v_conflict := true; v_reasons := v_reasons||ARRAY['INVALID_TERM_CHAIN']; END IF;
      ELSE
        SELECT a.value INTO v_predecessor FROM pg_catalog.jsonb_array_elements(v_terms) a(value) WHERE a.value -> 'term_id'=v_term -> 'predecessor_term_id';
        IF v_predecessor IS NULL OR v_predecessor ->> 'effective_end' IS NULL OR v_predecessor -> 'term_id'=v_term -> 'term_id' THEN
          v_conflict := true; v_reasons := v_reasons||ARRAY['INVALID_TERM_CHAIN'];
        ELSE
          v_previous_end := (v_predecessor ->> 'effective_end')::timestamptz;
          IF v_term ->> 'purpose'='RENEWAL' THEN
            IF v_term ->> 'anchor_rule'<>'RENEWAL_BOUNDARY' OR v_start IS DISTINCT FROM v_previous_end
              OR v_purchase >= pg_catalog.timezone('Asia/Baghdad',pg_catalog.timezone('Asia/Baghdad',v_previous_end)+pg_catalog.make_interval(days=>5)) THEN
              v_conflict := true; v_reasons := v_reasons||ARRAY['INVALID_TERM_CHAIN'];
            END IF;
          ELSIF v_term ->> 'anchor_rule'<>'REPUBLICATION' OR v_purchase < pg_catalog.timezone('Asia/Baghdad',pg_catalog.timezone('Asia/Baghdad',v_previous_end)+pg_catalog.make_interval(days=>5))
             OR v_start IS NOT NULL AND v_start<v_purchase THEN v_conflict := true; v_reasons := v_reasons||ARRAY['INVALID_TERM_CHAIN'];
          END IF;
        END IF;
      END IF;
      v_sources := v_sources||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('id',v_term -> 'term_id','kind','PAID_TERM','record',v_term,'catalog',v_catalog,
        'start',v_term #> '{anchor,effective_at}','original_end',v_term -> 'original_end','end',v_term -> 'effective_end',
        'grace',CASE WHEN v_grace IS NULL THEN NULL ELSE pg_catalog.to_char(pg_catalog.timezone('UTC',v_grace),'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') END));
    END LOOP;
    FOR v_grant IN SELECT a.value FROM pg_catalog.jsonb_array_elements(v_grants) a(value) LOOP
      SELECT a.value INTO v_catalog FROM pg_catalog.jsonb_array_elements(v_catalogs) a(value) WHERE a.value -> 'plan_version_id'=v_grant -> 'plan_version_id';
      IF v_catalog IS NULL THEN v_bad := true; v_reasons := v_reasons||ARRAY['BUNDLE_MISSING']; CONTINUE; END IF;
      IF v_catalog ->> 'family'<>'business_pro' OR v_grant -> 'bundle_version_id'<>v_catalog -> 'bundle_version_id' THEN v_failure := 'BINDING_MISMATCH'; EXIT evaluate; END IF;
      v_purchase := (v_grant ->> 'selected_at')::timestamptz;
      IF v_catalog ->> 'plan_status'='DRAFT' OR v_catalog ->> 'bundle_status'='DRAFT'
        OR v_catalog ->> 'approval_evidence_id' IS NULL OR v_catalog ->> 'approved_at' IS NULL
        OR (v_catalog ->> 'approved_at')::timestamptz>v_purchase
        OR (v_catalog ->> 'plan_published_at')::timestamptz>v_purchase OR (v_catalog ->> 'bundle_published_at')::timestamptz>v_purchase
        OR v_catalog ->> 'plan_status'='RETIRED' AND v_purchase >= (v_catalog ->> 'plan_retired_at')::timestamptz
        OR v_catalog ->> 'bundle_status'='RETIRED' AND v_purchase >= (v_catalog ->> 'bundle_retired_at')::timestamptz THEN
        v_bad := true; v_reasons := v_reasons||ARRAY['CATALOG_NOT_APPROVED'];
      END IF;
      IF v_grant ->> 'exception_dependency' IS NOT NULL THEN v_bad := true; v_reasons := v_reasons||ARRAY['POLICY_DEPENDENCY_BLOCKED']; END IF;
      IF (v_grant ->> 'formal_launch_event_id' IS NULL)<>(v_grant ->> 'formal_launch_at' IS NULL)
        OR (v_grant ->> 'first_post_launch_publication_event_id' IS NULL)<>(v_grant ->> 'first_post_launch_publication_at' IS NULL)
        OR (v_grant ->> 'start_at' IS NULL)<>(v_grant ->> 'end_at' IS NULL)
        OR (v_grant ->> 'formal_launch_at')::timestamptz>p_as_of OR (v_grant ->> 'first_post_launch_publication_at')::timestamptz>p_as_of THEN
        v_conflict := true; v_reasons := v_reasons||ARRAY['ANCHOR_CONFLICT'];
      END IF;
      v_start := (v_grant ->> 'start_at')::timestamptz; v_end := (v_grant ->> 'end_at')::timestamptz; v_grace := NULL;
      IF v_start IS NULL THEN v_reasons := v_reasons||ARRAY['A8_PUBLICATION_ANCHOR_MISSING'];
      ELSE
        IF v_grant ->> 'formal_launch_at' IS NULL OR v_grant ->> 'first_post_launch_publication_at' IS NULL
          OR (v_grant ->> 'first_post_launch_publication_at')::timestamptz<(v_grant ->> 'formal_launch_at')::timestamptz
          OR v_start IS DISTINCT FROM GREATEST((v_grant ->> 'formal_launch_at')::timestamptz,(v_grant ->> 'first_post_launch_publication_at')::timestamptz)
          OR v_end IS DISTINCT FROM pg_catalog.timezone('Asia/Baghdad',pg_catalog.timezone('Asia/Baghdad',v_start)+pg_catalog.make_interval(days=>60)) THEN
          v_conflict := true; v_reasons := v_reasons||ARRAY['ANCHOR_CONFLICT'];
        END IF;
        v_grace := pg_catalog.timezone('Asia/Baghdad',pg_catalog.timezone('Asia/Baghdad',v_end)+pg_catalog.make_interval(days=>5));
        IF EXTRACT(YEAR FROM pg_catalog.timezone('UTC',v_grace)) NOT BETWEEN 1 AND 9999 THEN v_failure := 'INVALID_TIMESTAMP'; EXIT evaluate; END IF;
      END IF;
      v_sources := v_sources||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('id',v_grant -> 'grant_id','kind','A8_PROMOTIONAL_GRANT','record',v_grant,'catalog',v_catalog,
        'start',v_grant -> 'start_at','original_end',v_grant -> 'end_at','end',v_grant -> 'end_at',
        'grace',CASE WHEN v_grace IS NULL THEN NULL ELSE pg_catalog.to_char(pg_catalog.timezone('UTC',v_grace),'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') END));
    END LOOP;
    -- Normally-once ordinary A8 semantic identity is the genuine entity,
    -- independent of renamed program/grant UUIDs (DUPLICATE_GRANT_ID class).
    IF pg_catalog.jsonb_array_length(v_grants)>1 THEN v_conflict := true; v_reasons := v_reasons||ARRAY['DUPLICATE_GRANT_ID']; END IF;
    FOR v_source IN SELECT a.value FROM pg_catalog.jsonb_array_elements(v_sources) a(value) LOOP
      v_catalog := v_source -> 'catalog'; v_items := v_catalog -> 'items';
      v_known := ARRAY['analytics.available','branches.included','media.upload_enabled','sponsored.purchase_eligible','team.active_member_max'];
      FOREACH v_key IN ARRAY v_known LOOP
        SELECT a.value INTO v_item FROM pg_catalog.jsonb_array_elements(v_items) a(value) WHERE a.value ->> 'capability_key'=v_key;
        IF v_item IS NULL THEN
          IF v_catalog ->> 'family'<>'corporate' OR v_key<>'sponsored.purchase_eligible' THEN v_bad := true; v_reasons := v_reasons||ARRAY['CAPABILITY_MISSING']; END IF;
          CONTINUE;
        END IF;
        IF v_item ->> 'value_kind' IS DISTINCT FROM (CASE WHEN v_key IN ('branches.included','team.active_member_max') THEN 'integer' ELSE 'boolean' END)
          OR pg_catalog.num_nonnulls(v_item ->> 'value_boolean',v_item ->> 'value_integer',v_item ->> 'value_text')<>1
          OR v_item ->> 'value_kind'='integer' AND v_item ->> 'value_integer' IS NULL
          OR v_item ->> 'value_kind'='boolean' AND v_item ->> 'value_boolean' IS NULL THEN
          v_bad := true; v_reasons := v_reasons||ARRAY['MALFORMED_CAPABILITY'];
        ELSIF v_key='branches.included' AND (v_item ->> 'value_integer')::numeric::bigint<>(CASE v_catalog ->> 'family' WHEN 'business' THEN 1 WHEN 'business_pro' THEN 2 ELSE 3 END)
          OR v_key='team.active_member_max' AND (v_item ->> 'value_integer')::numeric::bigint<>5 THEN
          v_bad := true; v_reasons := v_reasons||ARRAY['MALFORMED_CAPABILITY'];
        END IF;
        -- Frozen M1b v1 values; no live catalog read or new approval authority.
        -- Corporate Sponsored is separately governed by approved written terms.
        IF v_key IN ('analytics.available','media.upload_enabled') AND v_item -> 'value_boolean' IS DISTINCT FROM 'true'::jsonb
          OR v_key='sponsored.purchase_eligible' AND v_catalog ->> 'family'<>'corporate'
             AND v_item -> 'value_boolean' IS DISTINCT FROM pg_catalog.to_jsonb(v_catalog ->> 'family'<>'business') THEN
          v_bad := true; v_reasons := v_reasons||ARRAY['MALFORMED_CAPABILITY'];
        END IF;
      END LOOP;
      FOR v_item IN SELECT a.value FROM pg_catalog.jsonb_array_elements(v_items) a(value) WHERE NOT (a.value ->> 'capability_key'=ANY(v_known)) LOOP
        IF (v_item ->> 'is_required')::boolean THEN v_unsupported := true; v_reasons := v_reasons||ARRAY['UNKNOWN_REQUIRED_CAPABILITY']; END IF;
      END LOOP;
      FOR v_other IN SELECT a.value FROM pg_catalog.jsonb_array_elements(v_sources) a(value) WHERE a.value ->> 'id'>v_source ->> 'id' COLLATE "C" LOOP
        IF v_source ->> 'start' IS NOT NULL AND v_other ->> 'start' IS NOT NULL
          AND (v_source ->> 'start')::timestamptz < (v_other ->> 'end')::timestamptz
          AND (v_other ->> 'start')::timestamptz < (v_source ->> 'end')::timestamptz THEN
          v_conflict := true; v_reasons := v_reasons||ARRAY['OVERLAPPING_BASIS'];
        END IF;
      END LOOP;
    END LOOP;
    SELECT count(*) INTO v_pending FROM pg_catalog.jsonb_array_elements(v_sources) a WHERE a ->> 'start' IS NULL;
    IF v_pending>1 THEN v_conflict := true; v_reasons := v_reasons||ARRAY['OVERLAPPING_BASIS']; END IF;
    IF pg_catalog.jsonb_array_length(v_terms)>0 AND pg_catalog.jsonb_array_length(v_grants)>0 THEN
      v_bad := true; v_reasons := v_reasons||ARRAY['POLICY_DEPENDENCY_BLOCKED'];
    END IF;
    -- Bounded deterministic source selection avoids planning a computed-time sort.
    v_best_rank := 4;
    FOR v_source IN SELECT a.value FROM pg_catalog.jsonb_array_elements(v_sources) a(value) LOOP
      v_rank := CASE WHEN v_source ->> 'start' IS NULL THEN 1
        WHEN p_as_of < (v_source ->> 'start')::timestamptz THEN 2
        WHEN p_as_of < (v_source ->> 'end')::timestamptz THEN 0 ELSE 3 END;
      IF v_rank<v_best_rank OR (v_rank=v_best_rank AND (
        (v_rank=2 AND (v_source ->> 'start')::timestamptz < (v_selected ->> 'start')::timestamptz)
        OR ((v_rank<>2 OR v_source -> 'start'=v_selected -> 'start') AND
          ((v_source ->> 'end')::timestamptz > (v_selected ->> 'end')::timestamptz
            OR (v_source -> 'end' IS NOT DISTINCT FROM v_selected -> 'end' AND
              v_source ->> 'id' COLLATE "C" < v_selected ->> 'id' COLLATE "C"))))) THEN
        v_selected := v_source; v_best_rank := v_rank;
      END IF;
    END LOOP;
    v_out := v_out||pg_catalog.jsonb_build_object('authority_outcome',CASE WHEN v_unsupported THEN 'UNSUPPORTED_VERSION' WHEN v_conflict THEN 'CONFLICTING_AUTHORITY' WHEN v_bad THEN 'INCOMPLETE_AUTHORITY' ELSE 'COMPLETE' END);
    IF v_conflict OR v_unsupported OR v_provider_missing THEN EXIT evaluate; END IF;
    IF v_selected IS NULL THEN
      v_out := v_out||'{"basis_context":"NONE"}'::jsonb;
      IF NOT v_bad THEN v_out := v_out||'{"entitlement_outcome":"NOT_ENTITLED"}'::jsonb; END IF;
      v_reasons := v_reasons||ARRAY['NO_APPLICABLE_BASIS']; EXIT evaluate;
    END IF;
    v_selected_catalog := v_selected -> 'catalog';
    v_start := (v_selected ->> 'start')::timestamptz; v_end := (v_selected ->> 'end')::timestamptz; v_grace := (v_selected ->> 'grace')::timestamptz;
    v_context := CASE WHEN v_start IS NULL THEN 'PENDING_ANCHOR' WHEN p_as_of<v_start THEN 'FUTURE'
      WHEN p_as_of<v_end THEN 'IN_EFFECT' WHEN p_as_of<v_grace THEN 'GRACE' ELSE 'AFTER_GRACE' END;
    v_out := v_out||pg_catalog.jsonb_build_object('basis_context',v_context,'source_kind',v_selected -> 'kind','original_start',v_selected -> 'start',
      'original_end',v_selected -> 'original_end','effective_end',v_selected -> 'end','grace_end',v_selected -> 'grace',
      'plan_id',v_selected_catalog -> 'plan_id','plan_version_id',v_selected_catalog -> 'plan_version_id','plan_version',v_selected_catalog -> 'plan_version',
      'bundle_version_id',v_selected_catalog -> 'bundle_version_id','bundle_version',v_selected_catalog -> 'bundle_version','registry_version',v_selected_catalog -> 'registry_version','snapshot_revision',v_selected_catalog -> 'snapshot_revision',
      'term_id',CASE WHEN v_selected ->> 'kind'='PAID_TERM' THEN v_selected -> 'id' ELSE 'null'::jsonb END,
      'grant_id',CASE WHEN v_selected ->> 'kind'='A8_PROMOTIONAL_GRANT' THEN v_selected -> 'id' ELSE 'null'::jsonb END,
      'agreement_id',CASE WHEN v_selected ->> 'kind'='PAID_TERM' THEN p_input #> '{agreement,agreement_id}' ELSE 'null'::jsonb END);
    IF NOT v_bad THEN v_out := v_out||pg_catalog.jsonb_build_object('entitlement_outcome',CASE WHEN v_context='IN_EFFECT' THEN 'ENTITLED' ELSE 'NOT_ENTITLED' END); END IF;
    IF p_input -> 'prior_publication'<>'null'::jsonb THEN
      IF p_input #>> '{prior_publication,source_id}' IS DISTINCT FROM v_selected ->> 'id'
         OR p_input #>> '{prior_publication,source_kind}' IS DISTINCT FROM v_selected ->> 'kind'
         OR (p_input #>> '{prior_publication,available_at}')::timestamptz>p_as_of
         OR v_start IS NULL OR (p_input #>> '{prior_publication,available_at}')::timestamptz<v_start
         OR (p_input #>> '{prior_publication,available_at}')::timestamptz>=v_end THEN
        v_failure := 'BINDING_MISMATCH'; EXIT evaluate;
      END IF;
      v_out := v_out||pg_catalog.jsonb_build_object('prior_publication_event_id',p_input #> '{prior_publication,publication_event_id}');
    END IF;
    IF v_context='FUTURE' THEN v_reasons := v_reasons||ARRAY['FUTURE_BASIS'];
    ELSIF v_context IN ('GRACE','AFTER_GRACE') THEN v_reasons := v_reasons||ARRAY['TERM_EXPIRED'];
      IF v_context='AFTER_GRACE' THEN v_reasons := v_reasons||ARRAY['GRACE_ENDED'];
      ELSIF p_input -> 'prior_publication'='null'::jsonb THEN v_reasons := v_reasons||ARRAY['PRIOR_PUBLICATION_NOT_PROVEN'];
      ELSIF NOT v_bad AND p_input #>> '{enforcement,context}' IN ('CLEAR','WARNING') THEN
        v_out := v_out||'{"continuity_eligible":true}'::jsonb; v_reasons := v_reasons||ARRAY['GRACE_CONTINUITY'];
      END IF;
    END IF;
    v_capabilities := v_out -> 'capabilities';
    FOR v_key,v_cap IN SELECT x.key,x.value FROM pg_catalog.jsonb_each(v_capabilities) x LOOP
      SELECT a.value INTO v_item FROM pg_catalog.jsonb_array_elements(v_selected_catalog -> 'items') a(value) WHERE a.value ->> 'capability_key'=v_key;
      v_cap_value := CASE WHEN v_cap ->> 'value_kind'='integer' THEN v_item -> 'value_integer' ELSE v_item -> 'value_boolean' END;
      v_permission := 'DENY'; v_cap_reasons := ARRAY[]::text[];
      IF v_item IS NULL THEN v_cap_value := 'null'::jsonb; v_cap_reasons := ARRAY['CAPABILITY_MISSING'];
      ELSIF v_bad THEN v_cap_value := 'null'::jsonb; v_cap_reasons := v_reasons;
      ELSIF v_cap_value='false'::jsonb OR v_cap_value='0'::jsonb THEN v_cap_reasons := ARRAY['CAPABILITY_DISABLED'];
      ELSIF v_out ->> 'enforcement_context' IN ('SUSPENDED','TERMINATED','CLOSED') THEN v_cap_reasons := ARRAY['ENFORCEMENT_DENIED'];
      ELSIF v_out ->> 'entitlement_outcome'<>'ENTITLED' THEN v_cap_reasons := ARRAY['ENTITLEMENT_NOT_IN_EFFECT'];
      ELSIF v_out ->> 'enforcement_context' IN ('CLEAR','WARNING') THEN v_permission := 'ALLOW';
      ELSE v_cap_reasons := ARRAY['ENFORCEMENT_UNKNOWN']; END IF;
      SELECT COALESCE(pg_catalog.array_agg(DISTINCT (x.code COLLATE "C") ORDER BY x.code COLLATE "C"),ARRAY[]::text[]) INTO v_cap_reasons FROM pg_catalog.unnest(v_cap_reasons) x(code);
      v_capabilities := pg_catalog.jsonb_set(v_capabilities,ARRAY[v_key],v_cap||pg_catalog.jsonb_build_object('value',v_cap_value,'commercial_permission',v_permission,'reason_codes',v_cap_reasons));
    END LOOP;
    v_out := pg_catalog.jsonb_set(v_out,'{capabilities}',v_capabilities);
    v_timestamp := NULL;
    FOR v_source IN SELECT a.value FROM pg_catalog.jsonb_array_elements(v_sources) a(value) LOOP
      FOREACH v_key IN ARRAY ARRAY['start','end','grace'] LOOP
        IF (v_source ->> v_key)::timestamptz>p_as_of AND (v_timestamp IS NULL OR (v_source ->> v_key)::timestamptz<v_timestamp) THEN
          v_timestamp := (v_source ->> v_key)::timestamptz;
        END IF;
      END LOOP;
    END LOOP;
    IF v_timestamp IS NOT NULL THEN v_out := pg_catalog.jsonb_set(v_out,'{next_boundary}',pg_catalog.to_jsonb(pg_catalog.to_char(pg_catalog.timezone('UTC',v_timestamp),'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'))); END IF;
  END evaluate;
  IF v_failure IS NOT NULL THEN
    v_out := '{"envelope_kind":"ENTITLEMENT_RESULT","input_version":"m3.input.v1","evaluator_version":"m3.evaluator.v1","calendar_rule_version":"m3.baghdad_calendar.v1","entity_id":null,"source_origin":null,"as_of":null,"input_revision":null,"synthetic_provider_revision":null,"authority_outcome":"INCOMPLETE_AUTHORITY","basis_context":null,"source_kind":null,"entitlement_outcome":"UNKNOWN_FAIL_CLOSED","enforcement_context":"UNKNOWN","enforcement_revision":null,"continuity_eligible":false,"agreement_id":null,"term_id":null,"grant_id":null,"plan_id":null,"plan_version_id":null,"plan_version":null,"bundle_version_id":null,"bundle_version":null,"registry_version":null,"snapshot_revision":null,"original_start":null,"original_end":null,"effective_end":null,"grace_end":null,"prior_publication_event_id":null,"capabilities":{"branches.included":{"value_kind":"integer","value":null,"commercial_permission":"DENY","reason_codes":[]},"team.active_member_max":{"value_kind":"integer","value":null,"commercial_permission":"DENY","reason_codes":[]},"media.upload_enabled":{"value_kind":"boolean","value":null,"commercial_permission":"DENY","reason_codes":[]},"analytics.available":{"value_kind":"boolean","value":null,"commercial_permission":"DENY","reason_codes":[]},"sponsored.purchase_eligible":{"value_kind":"boolean","value":null,"commercial_permission":"DENY","reason_codes":[]}},"next_boundary":null,"reason_codes":[],"result_fingerprint":null}'::jsonb||pg_catalog.jsonb_build_object('entity_id',v_out -> 'entity_id','source_origin',v_out -> 'source_origin','as_of',v_out -> 'as_of','synthetic_provider_revision',v_out -> 'synthetic_provider_revision',
      'authority_outcome',CASE WHEN v_failure LIKE 'UNSUPPORTED_%' THEN 'UNSUPPORTED_VERSION' WHEN v_failure LIKE 'DUPLICATE_%' THEN 'CONFLICTING_AUTHORITY' ELSE 'INCOMPLETE_AUTHORITY' END);
    v_reasons := ARRAY[v_failure];
    FOR v_key,v_cap IN SELECT x.key,x.value FROM pg_catalog.jsonb_each(v_out -> 'capabilities') x LOOP
      v_out := pg_catalog.jsonb_set(v_out,ARRAY['capabilities',v_key,'reason_codes'],pg_catalog.to_jsonb(v_reasons));
    END LOOP;
  END IF;
  SELECT COALESCE(pg_catalog.array_agg(DISTINCT (x.code COLLATE "C") ORDER BY x.code COLLATE "C"),ARRAY[]::text[]) INTO v_reasons FROM pg_catalog.unnest(v_reasons) x(code);
  v_out := pg_catalog.jsonb_set(v_out,'{reason_codes}',pg_catalog.to_jsonb(v_reasons));
  -- The fingerprint binds the serialized SQL row, whose bigint columns have
  -- integral spelling. Preserve the original input/snapshot fingerprints.
  FOREACH v_key IN ARRAY ARRAY['synthetic_provider_revision','enforcement_revision','plan_version','bundle_version','registry_version'] LOOP
    IF v_out ->> v_key IS NOT NULL THEN
      v_out := pg_catalog.jsonb_set(v_out,ARRAY[v_key],pg_catalog.to_jsonb((v_out ->> v_key)::numeric::bigint));
    END IF;
  END LOOP;
  v_out := pg_catalog.jsonb_set(v_out,'{result_fingerprint}',pg_catalog.to_jsonb(pg_catalog.encode(extensions.digest(pg_catalog.convert_to((v_out - 'result_fingerprint')::text,'UTF8'),'sha256'),'hex')));
  RETURN QUERY SELECT (v_out ->> 'envelope_kind')::text,
    (v_out ->> 'input_version')::text,
    (v_out ->> 'evaluator_version')::text,
    (v_out ->> 'calendar_rule_version')::text,
    (v_out ->> 'entity_id')::uuid,
    (v_out ->> 'source_origin')::text,
    (v_out ->> 'as_of')::timestamptz,
    (v_out ->> 'input_revision')::text,
    (v_out ->> 'synthetic_provider_revision')::numeric::bigint,
    (v_out ->> 'authority_outcome')::text,
    (v_out ->> 'basis_context')::text,
    (v_out ->> 'source_kind')::text,
    (v_out ->> 'entitlement_outcome')::text,
    (v_out ->> 'enforcement_context')::text,
    (v_out ->> 'enforcement_revision')::numeric::bigint,
    (v_out ->> 'continuity_eligible')::boolean,
    (v_out ->> 'agreement_id')::uuid,
    (v_out ->> 'term_id')::uuid,
    (v_out ->> 'grant_id')::uuid,
    (v_out ->> 'plan_id')::uuid,
    (v_out ->> 'plan_version_id')::uuid,
    (v_out ->> 'plan_version')::numeric::bigint,
    (v_out ->> 'bundle_version_id')::uuid,
    (v_out ->> 'bundle_version')::numeric::bigint,
    (v_out ->> 'registry_version')::numeric::bigint,
    (v_out ->> 'snapshot_revision')::text,
    (v_out ->> 'original_start')::timestamptz,
    (v_out ->> 'original_end')::timestamptz,
    (v_out ->> 'effective_end')::timestamptz,
    (v_out ->> 'grace_end')::timestamptz,
    (v_out ->> 'prior_publication_event_id')::uuid,
    v_out -> 'capabilities',
    (v_out ->> 'next_boundary')::timestamptz,
    ARRAY(SELECT x.value FROM pg_catalog.jsonb_array_elements_text(v_out -> 'reason_codes') x(value)),
    (v_out ->> 'result_fingerprint')::text;
END;
$m3_entitlement$;



CREATE FUNCTION commercial_private.m3_generation_matches_v1(
  p_authority_revision bigint,p_projection_revision bigint,p_authoritative_generation bigint,p_candidate_generation bigint
) RETURNS boolean
LANGUAGE sql IMMUTABLE SECURITY INVOKER
SET search_path = commercial_private, pg_temp
AS $m3_generation$
  SELECT COALESCE(p_authority_revision>=0 AND p_projection_revision>=0 AND p_authoritative_generation>=0 AND p_candidate_generation>=0
    AND p_authority_revision=p_projection_revision AND p_authoritative_generation=p_candidate_generation,false);
$m3_generation$;



CREATE FUNCTION commercial_private.m3_evaluate_publication_v1(p_entitlement_result jsonb, p_publication_input jsonb, p_as_of timestamptz)
RETURNS TABLE (
  input_version text,
  evaluator_version text,
  calendar_rule_version text,
  entity_id uuid,
  source_origin text,
  as_of timestamptz,
  synthetic_provider_revision bigint,
  entitlement_input_revision text,
  publication_input_revision text,
  authority_outcome text,
  entitlement_outcome text,
  enforcement_context text,
  verification_requirement text,
  verification_state text,
  intrinsic_readiness text,
  candidate_first_publication_ready boolean,
  continuity_eligible boolean,
  discoverability_outcome text,
  gate_results jsonb,
  authority_revision bigint,
  projection_revision bigint,
  authoritative_generation bigint,
  candidate_generation bigint,
  generation_matches boolean,
  legacy_visible boolean,
  comparison_target text,
  comparison_result text,
  mismatch_category text,
  reason_codes text[]
)
LANGUAGE plpgsql IMMUTABLE SECURITY INVOKER
SET search_path = commercial_private, pg_temp
AS $m3_publication$
DECLARE

  v_shapes constant jsonb := '{"Provider":{"status":"E:provider_status","revision":"I+?","source_origin":"E:source_origin"},"Providers":{"eligibility":"Provider","agreement_terms":"Provider","grants":"Provider","catalog":"Provider","enforcement":"Provider","publication_history":"Provider"},"Gate":{"status":"E:gate_status","entity_id":"UUID","evidence_id":"UUID?","revision":"I+?","decided_at":"TS?","content_revision":"I+?","requirements_revision":"I+?","scope_id":"UUID?","policy_dependency":"E:policy_dependency?"},"Agreement":{"agreement_id":"UUID","entity_id":"UUID","revision":"I+","approval_state":"E:approval_state","approval_evidence_id":"UUID?","approved_at":"TS?"},"Enforcement":{"context":"E:enforcement_context","entity_id":"UUID","evidence_id":"UUID?","revision":"I+?","effective_at":"TS?"},"History":{"publication_event_id":"UUID","entity_id":"UUID","source_kind":"E:source_kind","source_id":"UUID","content_revision":"I+","available_at":"TS"},"Item":{"capability_key":"Key","value_kind":"E:value_kind","value_boolean":"B?","value_integer":"I?","value_text":"Text?","is_required":"B"},"Catalog":{"plan_id":"UUID","family":"E:family","plan_version_id":"UUID","plan_version":"V:CATALOG","pricing_mode":"E:pricing_mode","plan_status":"E:catalog_status","plan_published_at":"TS?","plan_retired_at":"TS?","bundle_version_id":"UUID","bundle_version":"V:BUNDLE","registry_version":"V:REGISTRY","bundle_status":"E:catalog_status","bundle_published_at":"TS?","bundle_retired_at":"TS?","approval_evidence_id":"UUID?","approved_at":"TS?","snapshot_revision":"H","items":"A:Item:0:64:capability_key"},"Authorization":{"kind":"E:authorization_kind","state":"E:approval_state","evidence_id":"UUID?","decided_at":"TS?","quote_id":"UUID?","quote_valid_from":"TS?","quote_valid_until":"TS?","quote_accepted_at":"TS?","commitment_months":"I+?","payment_condition":"Gate"},"Anchor":{"anchor_event_id":"UUID","entity_id":"UUID","effective_at":"TS","recorded_at":"TS","publication_event_id":"UUID?","requests_evidence_id":"UUID?","delay_evidence_id":"UUID?","cause_at_deadline":"E:delay_cause?"},"Extension":{"extension_id":"UUID","term_id":"UUID","revision":"I+","evidence_id":"UUID","recorded_at":"TS","effective_end":"TS"},"Term":{"term_id":"UUID","source_id":"UUID","agreement_id":"UUID","agreement_revision":"I+","plan_version_id":"UUID","bundle_version_id":"UUID","purpose":"E:term_purpose","predecessor_term_id":"UUID?","duration_months":"I+","purchased_at":"TS","authorization":"Authorization","anchor_rule":"E:anchor_rule","anchor":"Anchor?","original_end":"TS?","effective_end":"TS?","extensions":"A:Extension:0:32:revision,extension_id"},"Grant":{"grant_id":"UUID","source_id":"UUID","entity_id":"UUID","program_id":"UUID","program_version":"V:PROGRAM","program_approval_evidence_id":"UUID","grant_approval_evidence_id":"UUID","once_per_entity_evidence_id":"UUID","plan_version_id":"UUID","bundle_version_id":"UUID","selected_at":"TS","formal_launch_event_id":"UUID?","formal_launch_at":"TS?","first_post_launch_publication_event_id":"UUID?","first_post_launch_publication_at":"TS?","start_at":"TS?","end_at":"TS?","exception_dependency":"E:policy_dependency?"},"EntitlementInput":{"envelope_kind":"K:ENTITLEMENT_INPUT","input_version":"V:INPUT","evaluator_version":"V:EVALUATOR","calendar_rule_version":"V:CALENDAR","source_origin":"E:source_origin","entity_id":"UUID","as_of":"TS","input_revision":"H","synthetic_provider_revision":"I+?","providers":"Providers","model_eligibility":"Gate","agreement":"Agreement?","catalog":"A:Catalog:0:40:plan_version_id","terms":"A:Term:0:32:term_id","grants":"A:Grant:0:8:grant_id","enforcement":"Enforcement","prior_publication":"History?"},"Capability":{"value_kind":"E:value_kind","value":"Scalar?","commercial_permission":"E:commercial_permission","reason_codes":"A:Reason:0:64:"},"Capabilities":{"branches.included":"Capability","team.active_member_max":"Capability","media.upload_enabled":"Capability","analytics.available":"Capability","sponsored.purchase_eligible":"Capability"},"Scope":{"scope_id":"UUID","category_id":"UUID","market_id":"UUID","market_context":"E:market_context","revision":"I+"},"Projection":{"descriptor_id":"UUID","entity_id":"UUID","content_revision":"I+","kind":"E:projection_kind","format_version":"V:PROJECTION_FORMAT","approval":"Gate","public_field_paths":"A:Path:1:32:","conformance":"Gate","projection_revision":"G?","candidate_generation":"G?"},"PublicationInput":{"envelope_kind":"K:PUBLICATION_INPUT","input_version":"V:INPUT","evaluator_version":"V:EVALUATOR","calendar_rule_version":"V:CALENDAR","entity_id":"UUID","source_origin":"E:source_origin","as_of":"TS","synthetic_provider_revision":"I+?","entitlement_input_revision":"H?","entitlement_result_fingerprint":"H","publication_input_revision":"H","legacy_visible":"B","scope":"Scope?","content_revision":"I+?","required_fields":"Gate","onboarding":"Gate","moderation":"Gate","verification_requirement":"E:verification_requirement","verification_state":"E:verification_state","verification":"Gate","enforcement":"Enforcement","launch":"Gate","projection":"Projection?","prior_publication":"History?","authority_revision":"G?","projection_revision":"G?","authoritative_generation":"G?","candidate_generation":"G?"},"EntitlementResult":{"envelope_kind":"K:ENTITLEMENT_RESULT","input_version":"V:INPUT","evaluator_version":"V:EVALUATOR","calendar_rule_version":"V:CALENDAR","entity_id":"UUID?","source_origin":"E:source_origin?","as_of":"TS?","input_revision":"H?","synthetic_provider_revision":"I?","authority_outcome":"E:authority_outcome","basis_context":"E:basis_context?","source_kind":"E:source_kind?","entitlement_outcome":"E:entitlement_outcome","enforcement_context":"E:enforcement_context","enforcement_revision":"I?","continuity_eligible":"B","agreement_id":"UUID?","term_id":"UUID?","grant_id":"UUID?","plan_id":"UUID?","plan_version_id":"UUID?","plan_version":"V:CATALOG?","bundle_version_id":"UUID?","bundle_version":"V:BUNDLE?","registry_version":"V:REGISTRY?","snapshot_revision":"H?","original_start":"TS?","original_end":"TS?","effective_end":"TS?","grace_end":"TS?","prior_publication_event_id":"UUID?","capabilities":"Capabilities","next_boundary":"TS?","reason_codes":"A:Reason:0:64:","result_fingerprint":"H"}}'::jsonb;
  v_vocab constant jsonb := '{"provider_status":["COMPLETE","UNAVAILABLE"],"source_origin":["runtime_shadow","test_fixture"],"gate_status":["PASS","FAIL","UNKNOWN","BLOCKED_POLICY"],"policy_dependency":["OQ-48","OQ-49","OQ-72","OQ-76","OQ-77","OQ-79","OQ-80","OQ-81","OQ-82","OQ-83","OQ-84"],"approval_state":["APPROVED","PENDING","REJECTED","UNKNOWN"],"enforcement_context":["CLEAR","WARNING","SUSPENDED","TERMINATED","CLOSED","UNKNOWN"],"source_kind":["PAID_TERM","A8_PROMOTIONAL_GRANT"],"family":["business","business_pro","business_plus","corporate"],"pricing_mode":["retail","custom_quote"],"catalog_status":["DRAFT","PUBLISHED","RETIRED"],"value_kind":["boolean","integer","text"],"authorization_kind":["VERIFIED_FUNDS","CORPORATE_WRITTEN"],"term_purpose":["INITIAL","RENEWAL","REACTIVATION"],"anchor_rule":["PUBLICATION","CUSTOMER_DELAY_DAY15","RENEWAL_BOUNDARY","REPUBLICATION"],"delay_cause":["CUSTOMER_ONLY","CIVILPEDIA","MIXED","UNKNOWN"],"commercial_permission":["ALLOW","DENY"],"market_context":["BAGHDAD"],"projection_kind":["CANDIDATE","SELECTED"],"verification_requirement":["REQUIRED","NOT_REQUIRED","UNKNOWN"],"verification_state":["VERIFIED","UNVERIFIED","UNKNOWN"],"authority_outcome":["COMPLETE","INCOMPLETE_AUTHORITY","CONFLICTING_AUTHORITY","UNSUPPORTED_VERSION"],"basis_context":["NONE","PENDING_ANCHOR","FUTURE","IN_EFFECT","GRACE","AFTER_GRACE"],"entitlement_outcome":["ENTITLED","NOT_ENTITLED","UNKNOWN_FAIL_CLOSED"]}'::jsonb;
  v_reason_vocabulary constant jsonb := '["INVALID_ENVELOPE","MISSING_REQUIRED_FIELD","UNKNOWN_FIELD","INVALID_FIELD_TYPE","INVALID_ENUM","INVALID_UUID","INVALID_TIMESTAMP","NONFINITE_TIMESTAMP","INVALID_GENERATION","INPUT_BOUND_EXCEEDED","UNSUPPORTED_INPUT_VERSION","UNSUPPORTED_EVALUATOR_VERSION","UNSUPPORTED_CALENDAR_VERSION","UNSUPPORTED_CATALOG_VERSION","UNSUPPORTED_BUNDLE_VERSION","UNSUPPORTED_REGISTRY_VERSION","UNSUPPORTED_PROGRAM_VERSION","UNSUPPORTED_PROJECTION_FORMAT","BINDING_MISMATCH","INPUT_REVISION_MISMATCH","DUPLICATE_TERM_ID","DUPLICATE_GRANT_ID","DUPLICATE_SOURCE_ID","DUPLICATE_CAPABILITY_KEY","DUPLICATE_REVISION_IDENTITY","CANONICAL_PROVIDER_UNAVAILABLE","RUNTIME_AUTHORITY_UNAVAILABLE","ELIGIBILITY_NOT_PROVEN","APPROVAL_NOT_PROVEN","CATALOG_NOT_APPROVED","BUNDLE_MISSING","CAPABILITY_MISSING","CAPABILITY_DISABLED","UNKNOWN_REQUIRED_CAPABILITY","MALFORMED_CAPABILITY","NO_APPLICABLE_BASIS","AUTHORIZATION_NOT_PROVEN","CORPORATE_TERMS_INVALID","INVALID_TERM_CHAIN","OVERLAPPING_BASIS","ANCHOR_PENDING","ANCHOR_EVIDENCE_MISSING","ANCHOR_CONFLICT","A8_PUBLICATION_ANCHOR_MISSING","POLICY_DEPENDENCY_BLOCKED","FUTURE_BASIS","TERM_EXPIRED","GRACE_CONTINUITY","GRACE_ENDED","PRIOR_PUBLICATION_NOT_PROVEN","ENFORCEMENT_UNKNOWN","ENFORCEMENT_DENIED","REQUIRED_FIELDS_NOT_PROVEN","ONBOARDING_NOT_PROVEN","MODERATION_NOT_PROVEN","VERIFICATION_NOT_PROVEN","LAUNCH_NOT_PROVEN","PROJECTION_NOT_PROVEN","GENERATION_MISSING","GENERATION_MISMATCH","ENTITLEMENT_NOT_IN_EFFECT","STALE_SHADOW_GENERATION","REQUEST_ID_CONFLICT","INTERNAL_EVALUATION_ERROR"]'::jsonb;
  v_queue jsonb[]; v_errors jsonb := '[]'::jsonb; v_valid jsonb := '{}'::jsonb;
  v_cursor integer := 0; v_node jsonb; v_value jsonb; v_path text; v_type text;
  v_key text; v_descriptor text; v_code text; v_priority integer; v_entry jsonb;
  v_index bigint; v_parts text[]; v_previous text; v_sort text; v_number numeric;
  v_text text; v_expected text; v_timestamp timestamptz; v_failure text;
  v_root jsonb; v_root_path text; v_required text[]; v_null text[];

  v_out jsonb := '{"input_version":"m3.input.v1","evaluator_version":"m3.evaluator.v1","calendar_rule_version":"m3.baghdad_calendar.v1","entity_id":null,"source_origin":null,"as_of":null,"synthetic_provider_revision":null,"entitlement_input_revision":null,"publication_input_revision":null,"authority_outcome":"INCOMPLETE_AUTHORITY","entitlement_outcome":"UNKNOWN_FAIL_CLOSED","enforcement_context":"UNKNOWN","verification_requirement":"UNKNOWN","verification_state":"UNKNOWN","intrinsic_readiness":"UNKNOWN_FAIL_CLOSED","candidate_first_publication_ready":false,"continuity_eligible":false,"discoverability_outcome":"UNKNOWN_FAIL_CLOSED","gate_results":{"required_fields":"UNKNOWN","onboarding":"UNKNOWN","moderation":"UNKNOWN","verification":"UNKNOWN","enforcement":"UNKNOWN","launch":"UNKNOWN","projection":"UNKNOWN","generation":"UNKNOWN"},"authority_revision":null,"projection_revision":null,"authoritative_generation":null,"candidate_generation":null,"generation_matches":false,"legacy_visible":null,"comparison_target":null,"comparison_result":"INCOMPARABLE","mismatch_category":"INPUT_OR_VERSION_CONFLICT","reason_codes":[]}'::jsonb;
  v_gate jsonb; v_projection jsonb; v_status text; v_reasons text[] := ARRAY[]::text[];
  v_gate_results jsonb; v_dependency boolean := false; v_unknown boolean := false;
  v_intrinsic_fail boolean := false; v_intrinsic_unknown boolean := false;
  v_strong_denial boolean := false; v_basis_ready boolean; v_matches boolean;
  v_cap jsonb; v_expected_kind text; v_intrinsic text; v_candidate boolean; v_continuity boolean;
  v_discover text; v_compare text; v_mismatch text; v_authority text; v_runtime boolean;
BEGIN
  v_root := p_publication_input; v_root_path := 'publication_input';
  v_queue := ARRAY[pg_catalog.jsonb_build_object('path','entitlement_result','type','EntitlementResult','value',p_entitlement_result),
    pg_catalog.jsonb_build_object('path','publication_input','type','PublicationInput','value',p_publication_input)];
  IF COALESCE(pg_catalog.octet_length(pg_catalog.convert_to(p_entitlement_result::text,'UTF8')),0)
    +COALESCE(pg_catalog.octet_length(pg_catalog.convert_to(p_publication_input::text,'UTF8')),0)>65536 THEN
    v_errors := v_errors||'[{"priority":1,"path":"input","code":"INPUT_BOUND_EXCEEDED"}]'::jsonb;
  END IF;

  IF p_as_of IS NULL THEN
    v_errors := v_errors || '[{"priority":7,"path":"$p_as_of","code":"INVALID_TIMESTAMP"}]'::jsonb;
  ELSIF NOT pg_catalog.isfinite(p_as_of) THEN
    v_errors := v_errors || '[{"priority":7,"path":"$p_as_of","code":"NONFINITE_TIMESTAMP"}]'::jsonb;
  ELSIF EXTRACT(YEAR FROM pg_catalog.timezone('UTC',p_as_of)) NOT BETWEEN 1 AND 9999 THEN
    v_errors := v_errors || '[{"priority":7,"path":"$p_as_of","code":"INVALID_TIMESTAMP"}]'::jsonb;
  END IF;


  -- The queue traverses closed shapes; diagnostics are selected by normative
  -- priority and ASCII path, independent of JSONB's storage key order.
  WHILE v_cursor < pg_catalog.cardinality(v_queue) LOOP
    v_node := (v_queue[v_cursor+1]::text)::jsonb; v_cursor := v_cursor + 1;
    v_value := v_node -> 'value'; v_path := v_node ->> 'path';
    v_type := v_node ->> 'type'; v_code := NULL; v_priority := 5;
    IF pg_catalog.right(v_type,1) = '?' THEN
      v_type := pg_catalog.left(v_type,pg_catalog.length(v_type)-1);
      IF v_value = 'null'::jsonb THEN CONTINUE; END IF;
    END IF;
    IF v_shapes ? v_type THEN
      IF pg_catalog.jsonb_typeof(v_value) IS DISTINCT FROM 'object' THEN
        v_code := CASE WHEN v_path IN ('input','entitlement_result','publication_input')
          THEN 'INVALID_ENVELOPE' ELSE 'INVALID_FIELD_TYPE' END;
        v_priority := CASE WHEN v_code='INVALID_ENVELOPE' THEN 2 ELSE 5 END;
      ELSE
        FOR v_key,v_descriptor IN SELECT k.key,k.value FROM pg_catalog.jsonb_each_text(v_shapes -> v_type) k ORDER BY k.key COLLATE "C" LOOP
          IF NOT (v_value ? v_key) THEN
            v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',3,'path',v_path||'.'||v_key,'code','MISSING_REQUIRED_FIELD'));
          ELSE
            v_queue := pg_catalog.array_append(v_queue,pg_catalog.jsonb_build_object('path',v_path||'.'||v_key,'type',v_descriptor,'value',v_value -> v_key));
          END IF;
        END LOOP;
        FOR v_key IN SELECT k.key FROM pg_catalog.jsonb_object_keys(v_value) k(key) WHERE NOT ((v_shapes -> v_type) ? k.key) ORDER BY k.key COLLATE "C" LOOP
          v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',4,'path',v_path||'.'||v_key,'code','UNKNOWN_FIELD'));
        END LOOP;
      END IF;
    ELSIF pg_catalog.left(v_type,2)='A:' THEN
      v_parts := pg_catalog.string_to_array(v_type,':');
      IF pg_catalog.jsonb_typeof(v_value) IS DISTINCT FROM 'array' THEN v_code := 'INVALID_FIELD_TYPE';
      ELSIF pg_catalog.jsonb_array_length(v_value) < v_parts[3]::integer OR pg_catalog.jsonb_array_length(v_value) > v_parts[4]::integer THEN
        v_code := 'INPUT_BOUND_EXCEEDED'; v_priority := 1;
      ELSE
        v_previous := NULL;
        FOR v_entry,v_index IN SELECT a.value,a.ordinality FROM pg_catalog.jsonb_array_elements(v_value) WITH ORDINALITY a(value,ordinality) LOOP
          v_queue := pg_catalog.array_append(v_queue,pg_catalog.jsonb_build_object('path',v_path||'['||pg_catalog.lpad(v_index::text,5,'0')||']','type',v_parts[2],'value',v_entry));
          v_sort := CASE WHEN v_parts[5]='revision,extension_id' THEN NULL
            WHEN v_parts[5]<>'' THEN v_entry ->> v_parts[5]
            WHEN v_parts[2] IN ('Reason','Path') THEN v_entry #>> '{}'
            ELSE NULL END;
          IF v_parts[5]='revision,extension_id' AND pg_catalog.jsonb_typeof(v_entry -> 'revision')='number' THEN
            v_number := (v_entry ->> 'revision')::numeric;
            IF v_number=pg_catalog.trunc(v_number) AND v_number BETWEEN 1 AND 9223372036854775807 THEN
              v_sort := pg_catalog.lpad(pg_catalog.trunc(v_number)::text,19,'0')||':'||(v_entry ->> 'extension_id');
            END IF;
          END IF;
          IF v_sort IS NOT NULL AND v_previous IS NOT NULL AND v_sort COLLATE "C" < v_previous COLLATE "C" THEN
            v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',5,'path',v_path,'code','INVALID_ENVELOPE'));
          END IF;
          IF v_parts[2] IN ('Reason','Path') AND v_sort IS NOT NULL AND v_sort=v_previous THEN
            v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',5,'path',v_path,'code','INVALID_FIELD_TYPE'));
          END IF;
          v_previous := v_sort;
        END LOOP;
      END IF;
    ELSIF v_type='B' THEN
      IF pg_catalog.jsonb_typeof(v_value) IS DISTINCT FROM 'boolean' THEN v_code := 'INVALID_FIELD_TYPE'; END IF;
    ELSIF v_type IN ('I','I+','G') OR pg_catalog.left(v_type,2)='V:' AND v_type IN ('V:CATALOG','V:BUNDLE','V:REGISTRY','V:PROGRAM') THEN
      IF pg_catalog.jsonb_typeof(v_value) IS DISTINCT FROM 'number' THEN v_code := CASE WHEN v_type='G' THEN 'INVALID_GENERATION' ELSE 'INVALID_FIELD_TYPE' END;
      ELSE
        v_number := (v_value #>> '{}')::numeric;
        IF v_number<>pg_catalog.trunc(v_number) OR v_number<0 OR v_number>9223372036854775807 OR v_type='I+' AND v_number<1 THEN
          v_code := CASE WHEN v_type='G' THEN 'INVALID_GENERATION' ELSE 'INVALID_FIELD_TYPE' END;
        ELSIF pg_catalog.left(v_type,2)='V:' AND v_number<>1 THEN v_code := CASE WHEN v_type='V:PROJECTION_FORMAT' THEN 'UNSUPPORTED_PROJECTION_FORMAT' ELSE 'UNSUPPORTED_'||pg_catalog.substr(v_type,3)||'_VERSION' END; v_priority := 8;
        END IF;
      END IF;
    ELSIF v_type='Scalar' THEN
      IF pg_catalog.jsonb_typeof(v_value) NOT IN ('boolean','number') THEN v_code := 'INVALID_FIELD_TYPE'; END IF;
    ELSE
      IF pg_catalog.jsonb_typeof(v_value) IS DISTINCT FROM 'string' THEN v_code := 'INVALID_FIELD_TYPE';
      ELSE
        v_text := v_value #>> '{}';
        IF v_type='UUID' THEN
          IF v_text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' OR v_text='00000000-0000-0000-0000-000000000000' THEN v_code := 'INVALID_UUID'; v_priority := 6; END IF;
        ELSIF v_type='TS' THEN
          v_priority := 7;
          IF v_text IN ('infinity','-infinity') THEN v_code := 'NONFINITE_TIMESTAMP';
          ELSIF v_text !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{6}Z$'
            OR pg_catalog.left(v_text,4)='0000' OR pg_catalog.substr(v_text,18,2)='60' THEN v_code := 'INVALID_TIMESTAMP';
          ELSE
            BEGIN
              v_timestamp := v_text::timestamptz;
              IF pg_catalog.to_char(pg_catalog.timezone('UTC',v_timestamp),'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')<>v_text THEN v_code := 'INVALID_TIMESTAMP'; END IF;
            EXCEPTION WHEN invalid_datetime_format OR datetime_field_overflow THEN v_code := 'INVALID_TIMESTAMP';
            END;
          END IF;
        ELSIF v_type='H' THEN
          IF v_text !~ '^[0-9a-f]{64}$' THEN v_code := 'INVALID_FIELD_TYPE'; END IF;
        ELSIF pg_catalog.left(v_type,2)='V:' THEN
          v_expected := CASE v_type WHEN 'V:INPUT' THEN 'm3.input.v1' WHEN 'V:EVALUATOR' THEN 'm3.evaluator.v1'
            WHEN 'V:CALENDAR' THEN 'm3.baghdad_calendar.v1' WHEN 'V:PROJECTION_FORMAT' THEN 'm3.public_descriptor.v1' END;
          IF v_text IS DISTINCT FROM v_expected THEN v_code := CASE WHEN v_type='V:PROJECTION_FORMAT' THEN 'UNSUPPORTED_PROJECTION_FORMAT' ELSE 'UNSUPPORTED_'||pg_catalog.substr(v_type,3)||'_VERSION' END; v_priority := 8; END IF;
        ELSIF pg_catalog.left(v_type,2)='E:' THEN
          IF NOT ((v_vocab -> pg_catalog.substr(v_type,3)) ? v_text) THEN v_code := 'INVALID_ENUM'; v_priority := 9; END IF;
        ELSIF pg_catalog.left(v_type,2)='K:' THEN
          IF v_text IS DISTINCT FROM pg_catalog.substr(v_type,3) THEN v_code := 'INVALID_ENUM'; v_priority := 9; END IF;
        ELSIF v_type='Reason' THEN
          IF NOT (v_reason_vocabulary ? v_text) THEN v_code := 'INVALID_ENUM'; v_priority := 9; END IF;
        ELSIF v_type='Key' THEN
          IF pg_catalog.length(v_text) NOT BETWEEN 1 AND 128 OR v_text !~ '^[\x01-\x7f]+$' THEN v_code := 'INVALID_FIELD_TYPE'; END IF;
        ELSIF v_type='Text' THEN
          IF pg_catalog.length(v_text) NOT BETWEEN 1 AND 256 OR pg_catalog.btrim(v_text)='' THEN v_code := 'INVALID_FIELD_TYPE'; END IF;
        ELSIF v_type='Path' THEN
          IF pg_catalog.length(v_text)=0 OR v_text !~ '^[\x01-\x7f]+$' THEN v_code := 'INVALID_FIELD_TYPE'; END IF;
        END IF;
      END IF;
    END IF;
    IF v_code IS NOT NULL THEN
      v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',v_priority,'path',v_path,'code',v_code));
    ELSE
      v_valid := v_valid || pg_catalog.jsonb_build_object(v_path,true);
    END IF;
  END LOOP;


  -- Conditional nulls and supplied fact links are validated before semantic
  -- evaluation. Dependency identifiers belong to their own existing Gate.
  FOR v_node IN SELECT n.value FROM pg_catalog.unnest(v_queue) n(value) LOOP
    v_value := v_node -> 'value'; v_path := v_node ->> 'path';
    v_type := pg_catalog.rtrim(v_node ->> 'type','?');
    IF pg_catalog.jsonb_typeof(v_value)<>'object' THEN CONTINUE; END IF;
    IF v_value ? 'entity_id' AND v_path NOT IN ('input','publication_input','entitlement_result')
       AND v_value ->> 'entity_id' IS DISTINCT FROM v_root ->> 'entity_id' THEN
      v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.entity_id','code','BINDING_MISMATCH'));
    END IF;
    v_required := ARRAY[]::text[]; v_null := ARRAY[]::text[];
    IF v_type='Gate' THEN
      IF v_value ->> 'status' IN ('PASS','FAIL') THEN
        v_required := ARRAY['evidence_id','revision','decided_at'];
      ELSIF v_value ->> 'status' IN ('UNKNOWN','BLOCKED_POLICY') THEN
        v_null := ARRAY['evidence_id','revision','decided_at','content_revision','requirements_revision','scope_id'];
      END IF;
      IF v_value ->> 'status'='BLOCKED_POLICY' THEN v_required := v_required||ARRAY['policy_dependency'];
      ELSIF v_value -> 'policy_dependency'<>'null'::jsonb THEN
        v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.policy_dependency','code','BINDING_MISMATCH'));
      END IF;
      IF v_valid ? (v_path||'.decided_at') AND (v_value ->> 'decided_at')::timestamptz > p_as_of THEN
        v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.decided_at','code','BINDING_MISMATCH'));
      END IF;
    ELSIF v_type='Provider' THEN
      IF v_value ->> 'status'='COMPLETE' THEN v_required := ARRAY['revision'];
      ELSIF v_value ->> 'status'='UNAVAILABLE' THEN v_null := ARRAY['revision']; END IF;
      IF v_value ->> 'source_origin' IS DISTINCT FROM v_root ->> 'source_origin' THEN
        v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.source_origin','code','BINDING_MISMATCH'));
      END IF;
    ELSIF v_type='Enforcement' THEN
      IF v_value ->> 'context'='UNKNOWN' THEN v_null := ARRAY['evidence_id','revision','effective_at'];
      ELSIF v_value ->> 'context' IN ('CLEAR','WARNING','SUSPENDED','TERMINATED','CLOSED') THEN v_required := ARRAY['evidence_id','revision','effective_at']; END IF;
      IF v_valid ? (v_path||'.effective_at') AND (v_value ->> 'effective_at')::timestamptz > p_as_of THEN
        v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.effective_at','code','BINDING_MISMATCH'));
      END IF;
    ELSIF v_type='Agreement' THEN
      IF v_value ->> 'approval_state'='APPROVED' THEN v_required := ARRAY['approval_evidence_id','approved_at'];
      ELSIF v_value ->> 'approval_state' IN ('PENDING','REJECTED','UNKNOWN') THEN v_null := ARRAY['approved_at']; END IF;

    ELSIF v_type='Authorization' THEN
      IF v_value ->> 'state'='APPROVED' THEN
        v_required := ARRAY['evidence_id','decided_at'];
        IF v_value ->> 'kind'='CORPORATE_WRITTEN' THEN
          v_required := v_required||ARRAY['quote_id','quote_valid_from','quote_valid_until','quote_accepted_at','commitment_months'];
        END IF;
      ELSIF v_value ->> 'state' IN ('PENDING','REJECTED','UNKNOWN') THEN v_null := ARRAY['decided_at']; END IF;
      IF v_value ->> 'kind'='VERIFIED_FUNDS' THEN v_null := v_null||ARRAY['quote_id','quote_valid_from','quote_valid_until','quote_accepted_at','commitment_months']; END IF;
    ELSIF v_type='Catalog' THEN
      IF v_valid ? (v_path||'.approved_at') AND (v_value ->> 'approved_at')::timestamptz>p_as_of THEN
        v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.approved_at','code','BINDING_MISMATCH'));
      END IF;
      FOREACH v_key IN ARRAY ARRAY['plan','bundle'] LOOP
        IF v_valid ? (v_path||'.'||v_key||'_retired_at') AND v_valid ? (v_path||'.'||v_key||'_published_at')
          AND (v_value ->> (v_key||'_retired_at'))::timestamptz < (v_value ->> (v_key||'_published_at'))::timestamptz THEN
          v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.'||v_key||'_retired_at','code','BINDING_MISMATCH'));
        END IF;
        IF v_value ->> (v_key||'_status')='DRAFT' THEN
          v_null := v_null||ARRAY[v_key||'_published_at',v_key||'_retired_at'];
        ELSIF v_value ->> (v_key||'_status')='PUBLISHED' THEN
          v_required := v_required||ARRAY[v_key||'_published_at']; v_null := v_null||ARRAY[v_key||'_retired_at'];
        ELSIF v_value ->> (v_key||'_status')='RETIRED' THEN
          v_required := v_required||ARRAY[v_key||'_published_at',v_key||'_retired_at'];
        END IF;
      END LOOP;
    END IF;
    IF v_type='Gate' AND v_root_path='input' THEN
      FOREACH v_key IN ARRAY ARRAY['content_revision','requirements_revision','scope_id'] LOOP
        IF v_value ? v_key AND v_value -> v_key<>'null'::jsonb THEN
          v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.'||v_key,'code','BINDING_MISMATCH'));
        END IF;
      END LOOP;
    END IF;
    IF v_type='Agreement' AND v_valid ? (v_path||'.approved_at') AND (v_value ->> 'approved_at')::timestamptz>p_as_of THEN
      v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.approved_at','code','BINDING_MISMATCH'));
    END IF;
    FOREACH v_key IN ARRAY v_required LOOP
      IF v_value -> v_key='null'::jsonb THEN
        v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',5,'path',v_path||'.'||v_key,'code','INVALID_FIELD_TYPE'));
      END IF;
    END LOOP;
    FOREACH v_key IN ARRAY v_null LOOP
      IF v_value ? v_key AND v_value -> v_key<>'null'::jsonb THEN
        v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',5,'path',v_path||'.'||v_key,'code','INVALID_FIELD_TYPE'));
      END IF;
    END LOOP;
  END LOOP;
  IF v_root ->> 'source_origin'='test_fixture' AND v_root -> 'synthetic_provider_revision'='null'::jsonb THEN
    v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',5,'path',v_root_path||'.synthetic_provider_revision','code','INVALID_FIELD_TYPE'));
  ELSIF v_root ->> 'source_origin'='runtime_shadow' AND v_root -> 'synthetic_provider_revision'<>'null'::jsonb THEN
    v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_root_path||'.synthetic_provider_revision','code','BINDING_MISMATCH'));
  END IF;
  IF v_valid ? (v_root_path||'.as_of') AND (v_root ->> 'as_of')::timestamptz IS DISTINCT FROM p_as_of THEN
    v_errors := v_errors || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_root_path||'.as_of','code','BINDING_MISMATCH'));
  END IF;

  IF pg_catalog.jsonb_array_length(v_errors)=0 THEN
    FOR v_key,v_cap IN SELECT x.key,x.value FROM pg_catalog.jsonb_each(p_entitlement_result -> 'capabilities') x LOOP
      v_expected_kind := CASE WHEN v_key IN ('branches.included','team.active_member_max') THEN 'integer' ELSE 'boolean' END;
      IF v_cap ->> 'value_kind'<>v_expected_kind OR v_cap -> 'value'<>'null'::jsonb
         AND (v_expected_kind='boolean' AND pg_catalog.jsonb_typeof(v_cap -> 'value')<>'boolean'
           OR v_expected_kind='integer' AND (pg_catalog.jsonb_typeof(v_cap -> 'value')<>'number')) THEN
        v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',5,'path','entitlement_result.capabilities.'||v_key,'code','INVALID_FIELD_TYPE'));
      ELSIF v_expected_kind='integer' AND v_cap -> 'value'<>'null'::jsonb THEN
        v_number := (v_cap ->> 'value')::numeric;
        IF v_number<0 OR v_number>9223372036854775807 OR pg_catalog.trunc(v_number)<>v_number THEN
          v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',5,'path','entitlement_result.capabilities.'||v_key,'code','INVALID_FIELD_TYPE'));
        END IF;
      END IF;
      IF v_cap ->> 'commercial_permission'='ALLOW' AND (p_entitlement_result ->> 'authority_outcome'<>'COMPLETE'
        OR p_entitlement_result ->> 'entitlement_outcome'<>'ENTITLED' OR p_entitlement_result ->> 'enforcement_context' NOT IN ('CLEAR','WARNING')
        OR v_cap -> 'value' IN ('null'::jsonb,'false'::jsonb,'0'::jsonb)) THEN
        v_errors := v_errors||'[{"priority":11,"path":"entitlement_result.capabilities","code":"BINDING_MISMATCH"}]'::jsonb;
      END IF;
    END LOOP;
    IF p_entitlement_result ->> 'result_fingerprint' IS DISTINCT FROM pg_catalog.encode(extensions.digest(pg_catalog.convert_to((p_entitlement_result - 'result_fingerprint')::text,'UTF8'),'sha256'),'hex')
      OR p_publication_input ->> 'publication_input_revision' IS DISTINCT FROM pg_catalog.encode(extensions.digest(pg_catalog.convert_to((p_publication_input - 'publication_input_revision')::text,'UTF8'),'sha256'),'hex') THEN
      v_errors := v_errors||'[{"priority":11,"path":"fingerprint","code":"INPUT_REVISION_MISMATCH"}]'::jsonb;
    END IF;
    FOREACH v_key IN ARRAY ARRAY['entity_id','source_origin','as_of','input_version','evaluator_version','calendar_rule_version','synthetic_provider_revision'] LOOP
      IF p_publication_input -> v_key IS DISTINCT FROM p_entitlement_result -> v_key THEN
        v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path','publication_input.'||v_key,'code','BINDING_MISMATCH'));
      END IF;
    END LOOP;
    IF p_publication_input -> 'entitlement_input_revision' IS DISTINCT FROM p_entitlement_result -> 'input_revision'
       OR p_publication_input -> 'entitlement_result_fingerprint' IS DISTINCT FROM p_entitlement_result -> 'result_fingerprint' THEN
      v_errors := v_errors||'[{"priority":11,"path":"publication_input.entitlement_binding","code":"BINDING_MISMATCH"}]'::jsonb;
    END IF;
    IF p_publication_input #>> '{enforcement,context}' IS DISTINCT FROM p_entitlement_result ->> 'enforcement_context'
       OR p_publication_input #> '{enforcement,revision}' IS DISTINCT FROM p_entitlement_result -> 'enforcement_revision' THEN
      v_errors := v_errors||'[{"priority":11,"path":"publication_input.enforcement","code":"BINDING_MISMATCH"}]'::jsonb;
    END IF;
    IF p_publication_input -> 'prior_publication'<>'null'::jsonb THEN
      IF p_publication_input #> '{prior_publication,publication_event_id}' IS DISTINCT FROM p_entitlement_result -> 'prior_publication_event_id'
        OR p_publication_input #>> '{prior_publication,source_kind}' IS DISTINCT FROM p_entitlement_result ->> 'source_kind'
        OR p_publication_input #>> '{prior_publication,source_id}' IS DISTINCT FROM COALESCE(p_entitlement_result ->> 'term_id',p_entitlement_result ->> 'grant_id')
        OR (p_publication_input #>> '{prior_publication,available_at}')::timestamptz>p_as_of THEN
        v_errors := v_errors||'[{"priority":11,"path":"publication_input.prior_publication","code":"BINDING_MISMATCH"}]'::jsonb;
      END IF;
    ELSIF p_entitlement_result -> 'prior_publication_event_id'<>'null'::jsonb THEN
      v_errors := v_errors||'[{"priority":11,"path":"publication_input.prior_publication","code":"BINDING_MISMATCH"}]'::jsonb;
    END IF;
    FOR v_node IN SELECT x.value FROM pg_catalog.unnest(v_queue) x(value) WHERE x.value ->> 'type'='Gate' LOOP
      v_path := v_node ->> 'path'; v_gate := v_node -> 'value'; v_status := v_gate ->> 'status';
      IF v_status='BLOCKED_POLICY' THEN v_dependency := true; END IF;
      IF v_status IN ('PASS','FAIL') THEN
        IF v_path IN ('publication_input.required_fields','publication_input.moderation','publication_input.projection.approval','publication_input.projection.conformance')
          OR v_path='publication_input.verification' AND p_publication_input ->> 'verification_requirement'='REQUIRED' THEN
          IF v_gate ->> 'content_revision' IS NULL THEN
            v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',5,'path',v_path||'.content_revision','code','INVALID_FIELD_TYPE'));
          ELSIF v_gate -> 'content_revision' IS DISTINCT FROM p_publication_input -> 'content_revision' THEN
            v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.content_revision','code','BINDING_MISMATCH'));
          END IF;
        ELSIF v_gate -> 'content_revision'<>'null'::jsonb THEN
          v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.content_revision','code','BINDING_MISMATCH'));
        END IF;
        IF v_path='publication_input.required_fields' AND v_gate -> 'requirements_revision'='null'::jsonb THEN
          v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',5,'path',v_path||'.requirements_revision','code','INVALID_FIELD_TYPE'));
        ELSIF v_path<>'publication_input.required_fields' AND v_gate -> 'requirements_revision'<>'null'::jsonb THEN
          v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.requirements_revision','code','BINDING_MISMATCH'));
        END IF;
        IF v_path='publication_input.launch' THEN
          IF p_publication_input -> 'scope'='null'::jsonb OR v_gate -> 'scope_id' IS DISTINCT FROM p_publication_input #> '{scope,scope_id}'
            OR v_gate -> 'revision' IS DISTINCT FROM p_publication_input #> '{scope,revision}' THEN
            v_errors := v_errors||'[{"priority":11,"path":"publication_input.launch.scope","code":"BINDING_MISMATCH"}]'::jsonb;
          END IF;
        ELSIF v_gate -> 'scope_id'<>'null'::jsonb THEN
          v_errors := v_errors||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('priority',11,'path',v_path||'.scope_id','code','BINDING_MISMATCH'));
        END IF;
      END IF;
    END LOOP;
    IF (p_entitlement_result -> 'reason_codes') ? 'POLICY_DEPENDENCY_BLOCKED' AND NOT v_dependency THEN
      v_errors := v_errors||'[{"priority":11,"path":"publication_input.policy_dependency","code":"BINDING_MISMATCH"}]'::jsonb;
    END IF;
    v_projection := p_publication_input -> 'projection';
    IF v_projection<>'null'::jsonb AND (v_projection -> 'content_revision' IS DISTINCT FROM p_publication_input -> 'content_revision'
      OR v_projection -> 'projection_revision' IS DISTINCT FROM p_publication_input -> 'projection_revision'
      OR v_projection -> 'candidate_generation' IS DISTINCT FROM p_publication_input -> 'candidate_generation') THEN
      v_errors := v_errors||'[{"priority":11,"path":"publication_input.projection.binding","code":"BINDING_MISMATCH"}]'::jsonb;
    END IF;
  END IF;
  IF v_valid ? 'publication_input.entity_id' THEN v_out := pg_catalog.jsonb_set(v_out,'{entity_id}',p_publication_input -> 'entity_id'); END IF;
  IF v_valid ? 'publication_input.source_origin' THEN v_out := v_out||pg_catalog.jsonb_build_object('source_origin',p_publication_input -> 'source_origin','comparison_target',CASE WHEN p_publication_input ->> 'source_origin'='runtime_shadow' THEN 'legacy_active_rls' ELSE 'fixture_visibility' END); END IF;
  IF v_valid ? 'publication_input.as_of' AND p_as_of IS NOT NULL AND pg_catalog.isfinite(p_as_of)
    AND (p_publication_input ->> 'as_of')::timestamptz=p_as_of THEN v_out := pg_catalog.jsonb_set(v_out,'{as_of}',p_publication_input -> 'as_of'); END IF;
  IF v_valid ? 'publication_input.synthetic_provider_revision' THEN v_out := pg_catalog.jsonb_set(v_out,'{synthetic_provider_revision}',p_publication_input -> 'synthetic_provider_revision'); END IF;
  IF v_valid ? 'publication_input.legacy_visible' THEN v_out := pg_catalog.jsonb_set(v_out,'{legacy_visible}',p_publication_input -> 'legacy_visible'); END IF;
  SELECT x.value ->> 'code' INTO v_failure FROM pg_catalog.jsonb_array_elements(v_errors) x(value)
    ORDER BY (x.value ->> 'priority')::integer,(x.value ->> 'path') COLLATE "C",x.value ->> 'code' LIMIT 1;
  <<evaluate>>
  BEGIN
    IF v_failure IS NOT NULL THEN
      v_out := v_out||pg_catalog.jsonb_build_object('authority_outcome',CASE WHEN v_failure LIKE 'UNSUPPORTED_%' THEN 'UNSUPPORTED_VERSION' WHEN v_failure LIKE 'DUPLICATE_%' THEN 'CONFLICTING_AUTHORITY' ELSE 'INCOMPLETE_AUTHORITY' END);
      v_reasons := ARRAY[v_failure]; EXIT evaluate;
    END IF;
    v_out := v_out||pg_catalog.jsonb_build_object('entitlement_input_revision',p_entitlement_result -> 'input_revision','publication_input_revision',p_publication_input -> 'publication_input_revision');
    SELECT COALESCE(pg_catalog.array_agg(x.value),ARRAY[]::text[]) INTO v_reasons FROM pg_catalog.jsonb_array_elements_text(p_entitlement_result -> 'reason_codes') x(value);
    IF p_entitlement_result ->> 'authority_outcome' IN ('UNSUPPORTED_VERSION','CONFLICTING_AUTHORITY') THEN
      v_out := v_out||pg_catalog.jsonb_build_object('authority_outcome',p_entitlement_result -> 'authority_outcome'); EXIT evaluate;
    END IF;
    v_runtime := p_publication_input ->> 'source_origin'='runtime_shadow';
    IF v_runtime THEN
      v_reasons := v_reasons||ARRAY['CANONICAL_PROVIDER_UNAVAILABLE','RUNTIME_AUTHORITY_UNAVAILABLE'];
      v_out := v_out||pg_catalog.jsonb_build_object('mismatch_category',CASE WHEN (p_publication_input ->> 'legacy_visible')::boolean THEN 'AUTHORITY_GAP_VISIBLE' ELSE 'AUTHORITY_GAP_NOT_VISIBLE' END);
      EXIT evaluate;
    END IF;
    v_gate_results := v_out -> 'gate_results';
    FOREACH v_key IN ARRAY ARRAY['required_fields','onboarding','moderation','verification','launch'] LOOP
      v_status := p_publication_input #>> ARRAY[v_key,'status'];
      IF v_key='verification' AND v_status<>'BLOCKED_POLICY' THEN
        IF p_publication_input ->> 'verification_requirement'='UNKNOWN' THEN v_status := 'UNKNOWN';
        ELSIF p_publication_input ->> 'verification_requirement'='REQUIRED' AND p_publication_input ->> 'verification_state'<>'VERIFIED' THEN
          v_status := CASE WHEN p_publication_input ->> 'verification_state'='UNKNOWN' THEN 'UNKNOWN' ELSE 'FAIL' END;
        END IF;
      END IF;
      v_gate_results := pg_catalog.jsonb_set(v_gate_results,ARRAY[v_key],pg_catalog.to_jsonb(v_status));
      IF v_status<>'PASS' THEN
        v_reasons := v_reasons||ARRAY[CASE v_key WHEN 'required_fields' THEN 'REQUIRED_FIELDS_NOT_PROVEN' WHEN 'onboarding' THEN 'ONBOARDING_NOT_PROVEN'
          WHEN 'moderation' THEN 'MODERATION_NOT_PROVEN' WHEN 'verification' THEN 'VERIFICATION_NOT_PROVEN' ELSE 'LAUNCH_NOT_PROVEN' END];
        IF v_status='BLOCKED_POLICY' THEN v_reasons := v_reasons||ARRAY['POLICY_DEPENDENCY_BLOCKED']; END IF;
      END IF;
    END LOOP;
    v_status := CASE p_publication_input #>> '{enforcement,context}' WHEN 'CLEAR' THEN 'PASS' WHEN 'WARNING' THEN 'PASS'
      WHEN 'UNKNOWN' THEN 'UNKNOWN' ELSE 'FAIL' END;
    v_gate_results := pg_catalog.jsonb_set(v_gate_results,'{enforcement}',pg_catalog.to_jsonb(v_status));
    v_projection := p_publication_input -> 'projection'; v_status := 'UNKNOWN';
    IF v_projection<>'null'::jsonb THEN
      IF v_projection #>> '{approval,status}'='FAIL' OR v_projection #>> '{conformance,status}'='FAIL'
        OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements_text(v_projection -> 'public_field_paths') x(value) WHERE x.value NOT IN
          ('canonical_identity','entity_type','approved_name','approved_description','authorized_categories','authorized_geography','public_contacts','public_media','approved_trust_labels')) THEN v_status := 'FAIL';
      ELSIF v_projection #>> '{approval,status}'='BLOCKED_POLICY' OR v_projection #>> '{conformance,status}'='BLOCKED_POLICY' THEN
        v_status := 'BLOCKED_POLICY'; v_reasons := v_reasons||ARRAY['POLICY_DEPENDENCY_BLOCKED'];
      ELSIF v_projection #>> '{approval,status}'='PASS' AND v_projection #>> '{conformance,status}'='PASS' THEN v_status := 'PASS'; END IF;
    END IF;
    v_gate_results := pg_catalog.jsonb_set(v_gate_results,'{projection}',pg_catalog.to_jsonb(v_status));
    IF v_status<>'PASS' THEN v_reasons := v_reasons||ARRAY['PROJECTION_NOT_PROVEN']; END IF;
    v_matches := commercial_private.m3_generation_matches_v1((p_publication_input ->> 'authority_revision')::numeric::bigint,(p_publication_input ->> 'projection_revision')::numeric::bigint,
      (p_publication_input ->> 'authoritative_generation')::numeric::bigint,(p_publication_input ->> 'candidate_generation')::numeric::bigint);
    IF p_publication_input ->> 'authority_revision' IS NULL OR p_publication_input ->> 'projection_revision' IS NULL
      OR p_publication_input ->> 'authoritative_generation' IS NULL OR p_publication_input ->> 'candidate_generation' IS NULL THEN
      v_status := 'UNKNOWN'; v_reasons := v_reasons||ARRAY['GENERATION_MISSING'];
    ELSIF NOT v_matches THEN v_status := 'FAIL'; v_reasons := v_reasons||ARRAY['GENERATION_MISMATCH'];
    ELSE v_status := 'PASS'; END IF;
    v_gate_results := pg_catalog.jsonb_set(v_gate_results,'{generation}',pg_catalog.to_jsonb(v_status));
    v_basis_ready := p_entitlement_result ->> 'authority_outcome'='COMPLETE' AND
      (p_entitlement_result ->> 'entitlement_outcome'='ENTITLED' OR p_entitlement_result ->> 'basis_context'='PENDING_ANCHOR' OR (p_entitlement_result ->> 'continuity_eligible')::boolean);
    v_intrinsic_fail := NOT v_basis_ready AND p_entitlement_result ->> 'authority_outcome'='COMPLETE';
    v_intrinsic_unknown := p_entitlement_result ->> 'authority_outcome'<>'COMPLETE';
    FOREACH v_key IN ARRAY ARRAY['required_fields','onboarding','moderation','verification','enforcement'] LOOP
      IF v_gate_results ->> v_key='FAIL' THEN v_intrinsic_fail := true;
      ELSIF v_gate_results ->> v_key IN ('UNKNOWN','BLOCKED_POLICY') THEN v_intrinsic_unknown := true; END IF;
    END LOOP;
    v_intrinsic := CASE WHEN v_intrinsic_fail THEN 'NOT_READY' WHEN v_intrinsic_unknown THEN 'UNKNOWN_FAIL_CLOSED' ELSE 'READY' END;
    SELECT EXISTS (SELECT 1 FROM pg_catalog.jsonb_each_text(v_gate_results) x WHERE x.value IN ('UNKNOWN','BLOCKED_POLICY')) INTO v_unknown;
    SELECT EXISTS (SELECT 1 FROM pg_catalog.jsonb_each_text(v_gate_results) x WHERE x.value='FAIL') INTO v_strong_denial;
    v_unknown := v_unknown OR p_entitlement_result ->> 'authority_outcome'<>'COMPLETE';
    v_strong_denial := v_strong_denial OR p_entitlement_result ->> 'authority_outcome'='COMPLETE'
      AND p_entitlement_result ->> 'entitlement_outcome'='NOT_ENTITLED' AND NOT (p_entitlement_result ->> 'continuity_eligible')::boolean;
    v_candidate := p_entitlement_result ->> 'basis_context'='PENDING_ANCHOR' AND v_intrinsic='READY' AND v_gate_results ->> 'launch'='PASS'
      AND v_gate_results ->> 'projection'='PASS' AND v_matches AND v_projection ->> 'kind'='CANDIDATE';
    v_continuity := (p_entitlement_result ->> 'continuity_eligible')::boolean AND v_intrinsic='READY' AND v_gate_results ->> 'launch'='PASS'
      AND v_gate_results ->> 'projection'='PASS' AND v_matches AND v_projection ->> 'kind'='SELECTED';
    IF v_intrinsic='READY' AND v_gate_results ->> 'launch'='PASS' AND v_gate_results ->> 'projection'='PASS' AND v_matches
      AND v_projection ->> 'kind'='SELECTED' AND (p_entitlement_result ->> 'entitlement_outcome'='ENTITLED' OR v_continuity) THEN v_discover := 'ALLOW';
    ELSIF v_strong_denial OR NOT v_unknown THEN v_discover := 'DENY'; ELSE v_discover := 'UNKNOWN_FAIL_CLOSED'; END IF;
    IF p_entitlement_result ->> 'entitlement_outcome'='NOT_ENTITLED' AND NOT v_continuity THEN v_reasons := v_reasons||ARRAY['ENTITLEMENT_NOT_IN_EFFECT']; END IF;
    v_authority := CASE WHEN v_unknown THEN 'INCOMPLETE_AUTHORITY' ELSE 'COMPLETE' END;
    v_compare := 'INCOMPARABLE'; v_mismatch := 'INPUT_OR_VERSION_CONFLICT';
    IF v_gate_results ->> 'generation'='FAIL' THEN v_mismatch := 'STALE_GENERATION';
    ELSIF v_authority='COMPLETE' AND v_discover IN ('ALLOW','DENY') THEN
      IF (p_publication_input ->> 'legacy_visible')::boolean THEN
        v_compare := CASE WHEN v_discover='ALLOW' THEN 'MATCH' ELSE 'DIFFERENT' END;
        v_mismatch := CASE WHEN v_discover='ALLOW' THEN 'MATCH_VISIBLE' ELSE 'LEGACY_VISIBLE_CANONICAL_DENY' END;
      ELSE v_compare := CASE WHEN v_discover='DENY' THEN 'MATCH' ELSE 'DIFFERENT' END;
        v_mismatch := CASE WHEN v_discover='DENY' THEN 'MATCH_NOT_VISIBLE' ELSE 'LEGACY_HIDDEN_CANONICAL_ALLOW' END;
      END IF;
    END IF;
    v_out := v_out||pg_catalog.jsonb_build_object('authority_outcome',v_authority,'entitlement_outcome',p_entitlement_result -> 'entitlement_outcome',
      'enforcement_context',p_publication_input #> '{enforcement,context}','verification_requirement',p_publication_input -> 'verification_requirement',
      'verification_state',p_publication_input -> 'verification_state','intrinsic_readiness',v_intrinsic,'candidate_first_publication_ready',COALESCE(v_candidate,false),
      'continuity_eligible',COALESCE(v_continuity,false),'discoverability_outcome',v_discover,'gate_results',v_gate_results,
      'authority_revision',p_publication_input -> 'authority_revision','projection_revision',p_publication_input -> 'projection_revision',
      'authoritative_generation',p_publication_input -> 'authoritative_generation','candidate_generation',p_publication_input -> 'candidate_generation',
      'generation_matches',v_matches,'comparison_result',v_compare,'mismatch_category',v_mismatch);
  END evaluate;
  SELECT COALESCE(pg_catalog.array_agg(DISTINCT (x.code COLLATE "C") ORDER BY x.code COLLATE "C"),ARRAY[]::text[]) INTO v_reasons FROM pg_catalog.unnest(v_reasons) x(code);
  v_out := pg_catalog.jsonb_set(v_out,'{reason_codes}',pg_catalog.to_jsonb(v_reasons));
  RETURN QUERY SELECT (v_out ->> 'input_version')::text,
    (v_out ->> 'evaluator_version')::text,
    (v_out ->> 'calendar_rule_version')::text,
    (v_out ->> 'entity_id')::uuid,
    (v_out ->> 'source_origin')::text,
    (v_out ->> 'as_of')::timestamptz,
    (v_out ->> 'synthetic_provider_revision')::numeric::bigint,
    (v_out ->> 'entitlement_input_revision')::text,
    (v_out ->> 'publication_input_revision')::text,
    (v_out ->> 'authority_outcome')::text,
    (v_out ->> 'entitlement_outcome')::text,
    (v_out ->> 'enforcement_context')::text,
    (v_out ->> 'verification_requirement')::text,
    (v_out ->> 'verification_state')::text,
    (v_out ->> 'intrinsic_readiness')::text,
    (v_out ->> 'candidate_first_publication_ready')::boolean,
    (v_out ->> 'continuity_eligible')::boolean,
    (v_out ->> 'discoverability_outcome')::text,
    v_out -> 'gate_results',
    (v_out ->> 'authority_revision')::numeric::bigint,
    (v_out ->> 'projection_revision')::numeric::bigint,
    (v_out ->> 'authoritative_generation')::numeric::bigint,
    (v_out ->> 'candidate_generation')::numeric::bigint,
    (v_out ->> 'generation_matches')::boolean,
    (v_out ->> 'legacy_visible')::boolean,
    (v_out ->> 'comparison_target')::text,
    (v_out ->> 'comparison_result')::text,
    (v_out ->> 'mismatch_category')::text,
    ARRAY(SELECT x.value FROM pg_catalog.jsonb_array_elements_text(v_out -> 'reason_codes') x(value));
END;
$m3_publication$;



CREATE FUNCTION commercial_private.m3_capture_shadow_v1(p_entity_id uuid, p_request_id uuid, p_expected_shadow_generation bigint)
RETURNS TABLE (
  capture_status text,
  is_historical boolean,
  request_id uuid,
  entity_id uuid,
  expected_shadow_generation bigint,
  shadow_generation bigint,
  source_origin text,
  input_version text,
  evaluator_version text,
  calendar_rule_version text,
  observed_at timestamptz,
  recorded_at timestamptz,
  input_fingerprint text,
  entitlement_input_revision text,
  publication_input_revision text,
  legacy_visible boolean,
  authority_outcome text,
  entitlement_outcome text,
  publication_outcome text,
  comparison_target text,
  comparison_result text,
  mismatch_category text,
  authority_revision bigint,
  projection_revision bigint,
  authoritative_generation bigint,
  candidate_generation bigint,
  reason_codes text[],
  result_summary jsonb
)
LANGUAGE plpgsql VOLATILE SECURITY INVOKER
SET search_path = commercial_private, pg_temp
AS $m3_capture$
DECLARE
  v_run commercial_private.m3_shadow_runs%ROWTYPE;
  v_head_generation bigint; v_historical boolean := true;
  v_observed timestamptz; v_recorded timestamptz; v_time text; v_source_id uuid;
  v_legacy_visible boolean; v_provider jsonb; v_gate jsonb; v_enforcement jsonb;
  v_entitlement_input jsonb; v_publication_input jsonb; v_entitlement_json jsonb;
  v_e record; v_p record; v_key text; v_summary jsonb; v_pair_hash text;
  v_expected_summary jsonb; v_ordered text[];
  v_reasons constant text[] := ARRAY['INVALID_ENVELOPE','MISSING_REQUIRED_FIELD','UNKNOWN_FIELD','INVALID_FIELD_TYPE','INVALID_ENUM','INVALID_UUID','INVALID_TIMESTAMP','NONFINITE_TIMESTAMP','INVALID_GENERATION','INPUT_BOUND_EXCEEDED','UNSUPPORTED_INPUT_VERSION','UNSUPPORTED_EVALUATOR_VERSION','UNSUPPORTED_CALENDAR_VERSION','UNSUPPORTED_CATALOG_VERSION','UNSUPPORTED_BUNDLE_VERSION','UNSUPPORTED_REGISTRY_VERSION','UNSUPPORTED_PROGRAM_VERSION','UNSUPPORTED_PROJECTION_FORMAT','BINDING_MISMATCH','INPUT_REVISION_MISMATCH','DUPLICATE_TERM_ID','DUPLICATE_GRANT_ID','DUPLICATE_SOURCE_ID','DUPLICATE_CAPABILITY_KEY','DUPLICATE_REVISION_IDENTITY','CANONICAL_PROVIDER_UNAVAILABLE','RUNTIME_AUTHORITY_UNAVAILABLE','ELIGIBILITY_NOT_PROVEN','APPROVAL_NOT_PROVEN','CATALOG_NOT_APPROVED','BUNDLE_MISSING','CAPABILITY_MISSING','CAPABILITY_DISABLED','UNKNOWN_REQUIRED_CAPABILITY','MALFORMED_CAPABILITY','NO_APPLICABLE_BASIS','AUTHORIZATION_NOT_PROVEN','CORPORATE_TERMS_INVALID','INVALID_TERM_CHAIN','OVERLAPPING_BASIS','ANCHOR_PENDING','ANCHOR_EVIDENCE_MISSING','ANCHOR_CONFLICT','A8_PUBLICATION_ANCHOR_MISSING','POLICY_DEPENDENCY_BLOCKED','FUTURE_BASIS','TERM_EXPIRED','GRACE_CONTINUITY','GRACE_ENDED','PRIOR_PUBLICATION_NOT_PROVEN','ENFORCEMENT_UNKNOWN','ENFORCEMENT_DENIED','REQUIRED_FIELDS_NOT_PROVEN','ONBOARDING_NOT_PROVEN','MODERATION_NOT_PROVEN','VERIFICATION_NOT_PROVEN','LAUNCH_NOT_PROVEN','PROJECTION_NOT_PROVEN','GENERATION_MISSING','GENERATION_MISMATCH','ENTITLEMENT_NOT_IN_EFFECT','STALE_SHADOW_GENERATION','REQUEST_ID_CONFLICT','INTERNAL_EVALUATION_ERROR'];
BEGIN
  IF current_user::text<>'postgres' OR session_user::text<>'postgres' OR pg_catalog.current_setting('role')<>'none'
    OR pg_catalog.current_setting('transaction_isolation')<>'repeatable read' THEN
    RAISE EXCEPTION USING ERRCODE='P3CTX', MESSAGE='wrong direct role/session/transaction context';
  END IF;
  IF p_entity_id IS NULL OR p_request_id IS NULL OR p_entity_id='00000000-0000-0000-0000-000000000000'::uuid
    OR p_request_id='00000000-0000-0000-0000-000000000000'::uuid OR p_expected_shadow_generation IS NULL
    OR p_expected_shadow_generation<0 OR p_expected_shadow_generation>9223372036854775806 THEN
    RAISE EXCEPTION USING ERRCODE='P3ARG', MESSAGE='NULL/nil/out-of-range argument';
  END IF;
  -- Initial replay lookup precedes all head/source/time work. The second lookup
  -- precedes stale-head rejection after private-head serialization.
  FOR v_pass IN 0..1 LOOP
    SELECT r.request_id,r.entity_id,r.expected_shadow_generation,r.shadow_generation,r.evaluator_version,r.input_version,r.calendar_rule_version,r.source_origin,r.input_fingerprint,r.observed_at,r.recorded_at,r.legacy_visible,r.authority_outcome,r.entitlement_outcome,r.publication_outcome,r.mismatch_category,r.reason_codes,r.result_summary,r.authority_revision,r.projection_revision,r.authoritative_generation,r.candidate_generation INTO v_run
      FROM commercial_private.m3_shadow_runs r WHERE r.request_id=p_request_id;
    IF FOUND THEN EXIT; END IF;
    IF v_pass=0 THEN
      INSERT INTO commercial_private.m3_shadow_heads AS h (entity_id) VALUES (p_entity_id)
        ON CONFLICT ON CONSTRAINT m3_shadow_heads_pkey DO NOTHING;
      SELECT h.shadow_generation INTO v_head_generation FROM commercial_private.m3_shadow_heads h
        WHERE h.entity_id=p_entity_id FOR UPDATE;
    END IF;
  END LOOP;
  IF v_run.request_id IS NOT NULL THEN
    IF v_run.entity_id<>p_entity_id OR v_run.source_origin<>'runtime_shadow'
      OR v_run.expected_shadow_generation<>p_expected_shadow_generation THEN
      RAISE EXCEPTION USING ERRCODE='P3MIS', MESSAGE='existing request reused for a different origin/entity/original expected generation';
    END IF;
    SELECT COALESCE(pg_catalog.array_agg(DISTINCT (x.code COLLATE "C") ORDER BY x.code COLLATE "C"),ARRAY[]::text[]) INTO v_ordered
      FROM pg_catalog.unnest(v_run.reason_codes) x(code);
    v_expected_summary := pg_catalog.jsonb_build_object(
      'entitlement_input_revision',v_run.result_summary -> 'entitlement_input_revision',
      'publication_input_revision',v_run.result_summary -> 'publication_input_revision',
      'comparison_target','legacy_active_rls','comparison_result','INCOMPARABLE','basis_context',NULL,
      'enforcement_context','UNKNOWN','intrinsic_readiness','UNKNOWN_FAIL_CLOSED',
      'candidate_first_publication_ready',false,'continuity_eligible',false,
      'gate_results','{"required_fields":"UNKNOWN","onboarding":"UNKNOWN","moderation":"UNKNOWN","verification":"UNKNOWN","enforcement":"UNKNOWN","launch":"UNKNOWN","projection":"UNKNOWN","generation":"UNKNOWN"}'::jsonb,
      'catalog_binding',NULL,'snapshot_provenance','{"transaction_isolation":"repeatable_read","observation_time_basis":"server_wall_after_shadow_lock"}'::jsonb);
    v_pair_hash := pg_catalog.encode(extensions.digest(pg_catalog.convert_to(pg_catalog.jsonb_build_object(
      'entitlement_input_revision',v_run.result_summary -> 'entitlement_input_revision',
      'publication_input_revision',v_run.result_summary -> 'publication_input_revision')::text,'UTF8'),'sha256'),'hex');
    IF v_run.shadow_generation::numeric<>p_expected_shadow_generation::numeric+1
      OR v_run.input_version<>'m3.input.v1' OR v_run.evaluator_version<>'m3.evaluator.v1' OR v_run.calendar_rule_version<>'m3.baghdad_calendar.v1'
      OR NOT pg_catalog.isfinite(v_run.observed_at) OR NOT pg_catalog.isfinite(v_run.recorded_at) OR v_run.recorded_at<v_run.observed_at
      OR EXTRACT(YEAR FROM pg_catalog.timezone('UTC',v_run.observed_at)) NOT BETWEEN 1 AND 9999
      OR EXTRACT(YEAR FROM pg_catalog.timezone('UTC',v_run.recorded_at)) NOT BETWEEN 1 AND 9999
      OR v_run.authority_outcome<>'INCOMPLETE_AUTHORITY' OR v_run.entitlement_outcome<>'UNKNOWN_FAIL_CLOSED' OR v_run.publication_outcome<>'UNKNOWN_FAIL_CLOSED'
      OR v_run.authority_revision IS NOT NULL OR v_run.projection_revision IS NOT NULL OR v_run.authoritative_generation IS NOT NULL OR v_run.candidate_generation IS NOT NULL
      OR v_run.mismatch_category<>(CASE WHEN v_run.legacy_visible THEN 'AUTHORITY_GAP_VISIBLE' ELSE 'AUTHORITY_GAP_NOT_VISIBLE' END)
      OR v_run.result_summary IS DISTINCT FROM v_expected_summary
      OR COALESCE(v_run.result_summary ->> 'entitlement_input_revision','') !~ '^[0-9a-f]{64}$'
      OR COALESCE(v_run.result_summary ->> 'publication_input_revision','') !~ '^[0-9a-f]{64}$'
      OR v_run.input_fingerprint IS DISTINCT FROM v_pair_hash
      OR v_run.reason_codes IS DISTINCT FROM v_ordered OR pg_catalog.cardinality(v_run.reason_codes)>64
      OR NOT (v_run.reason_codes <@ v_reasons) OR NOT (v_run.reason_codes @> ARRAY['CANONICAL_PROVIDER_UNAVAILABLE','RUNTIME_AUTHORITY_UNAVAILABLE'])
      OR pg_catalog.octet_length(pg_catalog.convert_to(v_run.result_summary::text,'UTF8'))>16384 THEN
      RAISE EXCEPTION USING ERRCODE='P3COR', MESSAGE='corrupt original run/summary, unsafe server timestamp, nonconforming internal runtime output';
    END IF;
  ELSE
    v_historical := false;
    IF v_head_generation<>p_expected_shadow_generation THEN
      RAISE EXCEPTION USING ERRCODE='P3STA', MESSAGE='new request''s expected head stale';
    END IF;
    v_observed := pg_catalog.clock_timestamp();
    IF NOT pg_catalog.isfinite(v_observed) OR EXTRACT(YEAR FROM pg_catalog.timezone('UTC',v_observed)) NOT BETWEEN 1 AND 9999 THEN
      RAISE EXCEPTION USING ERRCODE='P3COR', MESSAGE='corrupt original run/summary, unsafe server timestamp, nonconforming internal runtime output';
    END IF;
    SELECT d.id,d.lifecycle_status='active' INTO v_source_id,v_legacy_visible
      FROM public.directory_entities d WHERE d.id=p_entity_id;
    IF NOT FOUND OR v_source_id IS NULL THEN RAISE EXCEPTION USING ERRCODE='P3REF', MESSAGE='fresh target entity absent'; END IF;
    v_time := pg_catalog.to_char(pg_catalog.timezone('UTC',v_observed),'YYYY-MM-DD"T"HH24:MI:SS.US"Z"');
    v_provider := '{"status":"UNAVAILABLE","revision":null,"source_origin":"runtime_shadow"}'::jsonb;
    v_gate := pg_catalog.jsonb_build_object('status','UNKNOWN','entity_id',p_entity_id,'evidence_id',NULL,'revision',NULL,'decided_at',NULL,
      'content_revision',NULL,'requirements_revision',NULL,'scope_id',NULL,'policy_dependency',NULL);
    v_enforcement := pg_catalog.jsonb_build_object('context','UNKNOWN','entity_id',p_entity_id,'evidence_id',NULL,'revision',NULL,'effective_at',NULL);
    v_entitlement_input := pg_catalog.jsonb_build_object('envelope_kind','ENTITLEMENT_INPUT','input_version','m3.input.v1','evaluator_version','m3.evaluator.v1',
      'calendar_rule_version','m3.baghdad_calendar.v1','source_origin','runtime_shadow','entity_id',p_entity_id,'as_of',v_time,
      'input_revision',NULL,'synthetic_provider_revision',NULL,
      'providers',pg_catalog.jsonb_build_object('eligibility',v_provider,'agreement_terms',v_provider,'grants',v_provider,'catalog',v_provider,'enforcement',v_provider,'publication_history',v_provider),
      'model_eligibility',v_gate,'agreement',NULL,'catalog','[]'::jsonb,'terms','[]'::jsonb,'grants','[]'::jsonb,'enforcement',v_enforcement,'prior_publication',NULL);
    v_entitlement_input := pg_catalog.jsonb_set(v_entitlement_input,'{input_revision}',pg_catalog.to_jsonb(pg_catalog.encode(extensions.digest(
      pg_catalog.convert_to((v_entitlement_input - 'input_revision')::text,'UTF8'),'sha256'),'hex')));
    SELECT e.envelope_kind,e.input_version,e.evaluator_version,e.calendar_rule_version,e.entity_id,e.source_origin,e.as_of,e.input_revision,e.synthetic_provider_revision,e.authority_outcome,e.basis_context,e.source_kind,e.entitlement_outcome,e.enforcement_context,e.enforcement_revision,e.continuity_eligible,e.agreement_id,e.term_id,e.grant_id,e.plan_id,e.plan_version_id,e.plan_version,e.bundle_version_id,e.bundle_version,e.registry_version,e.snapshot_revision,e.original_start,e.original_end,e.effective_end,e.grace_end,e.prior_publication_event_id,e.capabilities,e.next_boundary,e.reason_codes,e.result_fingerprint INTO v_e FROM commercial_private.m3_evaluate_entitlement_v1(v_entitlement_input,v_observed) e;
    v_entitlement_json := pg_catalog.to_jsonb(v_e);
    FOREACH v_key IN ARRAY ARRAY['as_of','original_start','original_end','effective_end','grace_end','next_boundary'] LOOP
      IF v_entitlement_json ->> v_key IS NOT NULL THEN
        v_entitlement_json := pg_catalog.jsonb_set(v_entitlement_json,ARRAY[v_key],pg_catalog.to_jsonb(
          pg_catalog.to_char(pg_catalog.timezone('UTC',(v_entitlement_json ->> v_key)::timestamptz),'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')));
      END IF;
    END LOOP;
    v_publication_input := pg_catalog.jsonb_build_object('envelope_kind','PUBLICATION_INPUT','input_version','m3.input.v1','evaluator_version','m3.evaluator.v1',
      'calendar_rule_version','m3.baghdad_calendar.v1','entity_id',p_entity_id,'source_origin','runtime_shadow','as_of',v_time,
      'synthetic_provider_revision',NULL,'entitlement_input_revision',v_e.input_revision,'entitlement_result_fingerprint',v_e.result_fingerprint,'publication_input_revision',NULL,
      'legacy_visible',v_legacy_visible,'scope',NULL,'content_revision',NULL,'required_fields',v_gate,'onboarding',v_gate,'moderation',v_gate,
      'verification_requirement','UNKNOWN','verification_state','UNKNOWN','verification',v_gate,'enforcement',v_enforcement,'launch',v_gate,'projection',NULL,
      'prior_publication',NULL,'authority_revision',NULL,'projection_revision',NULL,'authoritative_generation',NULL,'candidate_generation',NULL);
    v_publication_input := pg_catalog.jsonb_set(v_publication_input,'{publication_input_revision}',pg_catalog.to_jsonb(pg_catalog.encode(extensions.digest(
      pg_catalog.convert_to((v_publication_input - 'publication_input_revision')::text,'UTF8'),'sha256'),'hex')));
    SELECT p.input_version,p.evaluator_version,p.calendar_rule_version,p.entity_id,p.source_origin,p.as_of,p.synthetic_provider_revision,p.entitlement_input_revision,p.publication_input_revision,p.authority_outcome,p.entitlement_outcome,p.enforcement_context,p.verification_requirement,p.verification_state,p.intrinsic_readiness,p.candidate_first_publication_ready,p.continuity_eligible,p.discoverability_outcome,p.gate_results,p.authority_revision,p.projection_revision,p.authoritative_generation,p.candidate_generation,p.generation_matches,p.legacy_visible,p.comparison_target,p.comparison_result,p.mismatch_category,p.reason_codes INTO v_p FROM commercial_private.m3_evaluate_publication_v1(v_entitlement_json,v_publication_input,v_observed) p;
    IF v_e.authority_outcome<>'INCOMPLETE_AUTHORITY' OR v_e.entitlement_outcome<>'UNKNOWN_FAIL_CLOSED'
      OR v_p.authority_outcome<>'INCOMPLETE_AUTHORITY' OR v_p.discoverability_outcome<>'UNKNOWN_FAIL_CLOSED'
      OR v_p.comparison_target<>'legacy_active_rls' OR v_p.comparison_result<>'INCOMPARABLE'
      OR v_p.mismatch_category<>(CASE WHEN v_legacy_visible THEN 'AUTHORITY_GAP_VISIBLE' ELSE 'AUTHORITY_GAP_NOT_VISIBLE' END)
      OR v_p.authority_revision IS NOT NULL OR v_p.projection_revision IS NOT NULL OR v_p.authoritative_generation IS NOT NULL OR v_p.candidate_generation IS NOT NULL
      OR v_p.intrinsic_readiness<>'UNKNOWN_FAIL_CLOSED' OR v_p.candidate_first_publication_ready OR v_p.continuity_eligible OR v_p.generation_matches
      OR NOT (v_p.reason_codes @> ARRAY['CANONICAL_PROVIDER_UNAVAILABLE','RUNTIME_AUTHORITY_UNAVAILABLE']) THEN
      RAISE EXCEPTION USING ERRCODE='P3COR', MESSAGE='corrupt original run/summary, unsafe server timestamp, nonconforming internal runtime output';
    END IF;
    v_summary := pg_catalog.jsonb_build_object('entitlement_input_revision',v_e.input_revision,'publication_input_revision',v_p.publication_input_revision,
      'comparison_target',v_p.comparison_target,'comparison_result',v_p.comparison_result,'basis_context',v_e.basis_context,'enforcement_context',v_p.enforcement_context,
      'intrinsic_readiness',v_p.intrinsic_readiness,'candidate_first_publication_ready',v_p.candidate_first_publication_ready,'continuity_eligible',v_p.continuity_eligible,
      'gate_results',v_p.gate_results,'catalog_binding',NULL,'snapshot_provenance','{"transaction_isolation":"repeatable_read","observation_time_basis":"server_wall_after_shadow_lock"}'::jsonb);
    v_pair_hash := pg_catalog.encode(extensions.digest(pg_catalog.convert_to(pg_catalog.jsonb_build_object('entitlement_input_revision',v_e.input_revision,
      'publication_input_revision',v_p.publication_input_revision)::text,'UTF8'),'sha256'),'hex');
    v_recorded := pg_catalog.clock_timestamp();
    IF NOT pg_catalog.isfinite(v_recorded) OR v_recorded<v_observed OR EXTRACT(YEAR FROM pg_catalog.timezone('UTC',v_recorded)) NOT BETWEEN 1 AND 9999
      OR pg_catalog.octet_length(pg_catalog.convert_to(v_summary::text,'UTF8'))>16384 THEN
      RAISE EXCEPTION USING ERRCODE='P3COR', MESSAGE='corrupt original run/summary, unsafe server timestamp, nonconforming internal runtime output';
    END IF;
    INSERT INTO commercial_private.m3_shadow_runs AS r (request_id,entity_id,expected_shadow_generation,shadow_generation,evaluator_version,input_version,calendar_rule_version,source_origin,input_fingerprint,observed_at,recorded_at,legacy_visible,authority_outcome,entitlement_outcome,publication_outcome,mismatch_category,reason_codes,result_summary,authority_revision,projection_revision,authoritative_generation,candidate_generation)
      VALUES (p_request_id,p_entity_id,p_expected_shadow_generation,p_expected_shadow_generation+1,'m3.evaluator.v1','m3.input.v1','m3.baghdad_calendar.v1',
        'runtime_shadow',v_pair_hash,v_observed,v_recorded,v_legacy_visible,v_p.authority_outcome,v_e.entitlement_outcome,v_p.discoverability_outcome,
        v_p.mismatch_category,v_p.reason_codes,v_summary,NULL,NULL,NULL,NULL)
      RETURNING r.request_id,r.entity_id,r.expected_shadow_generation,r.shadow_generation,r.evaluator_version,r.input_version,r.calendar_rule_version,r.source_origin,r.input_fingerprint,r.observed_at,r.recorded_at,r.legacy_visible,r.authority_outcome,r.entitlement_outcome,r.publication_outcome,r.mismatch_category,r.reason_codes,r.result_summary,r.authority_revision,r.projection_revision,r.authoritative_generation,r.candidate_generation INTO v_run;
    UPDATE commercial_private.m3_shadow_heads h SET shadow_generation=p_expected_shadow_generation+1,updated_at=v_recorded WHERE h.entity_id=p_entity_id;
  END IF;
  RETURN QUERY SELECT
    CASE WHEN v_historical THEN 'REPLAY'::text ELSE 'FRESH'::text END,v_historical,
    v_run.request_id,v_run.entity_id,v_run.expected_shadow_generation,v_run.shadow_generation,v_run.source_origin,v_run.input_version,v_run.evaluator_version,
    v_run.calendar_rule_version,v_run.observed_at,v_run.recorded_at,v_run.input_fingerprint,
    v_run.result_summary ->> 'entitlement_input_revision',v_run.result_summary ->> 'publication_input_revision',
    v_run.legacy_visible,v_run.authority_outcome,v_run.entitlement_outcome,v_run.publication_outcome,
    v_run.result_summary ->> 'comparison_target',v_run.result_summary ->> 'comparison_result',v_run.mismatch_category,
    v_run.authority_revision,v_run.projection_revision,v_run.authoritative_generation,v_run.candidate_generation,v_run.reason_codes,v_run.result_summary;
END;
$m3_capture$;


REVOKE ALL ON FUNCTION commercial_private.m3_evaluate_entitlement_v1(jsonb,timestamptz) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION commercial_private.m3_evaluate_publication_v1(jsonb,jsonb,timestamptz) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION commercial_private.m3_generation_matches_v1(bigint,bigint,bigint,bigint) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION commercial_private.m3_capture_shadow_v1(uuid,uuid,bigint) FROM PUBLIC,anon,authenticated,service_role;

DO $m3_postconditions$
DECLARE v_relation record; v_digest text; v_data jsonb := '{}'::jsonb; v_owner oid := 'postgres'::pg_catalog.regrole;
BEGIN
  FOR v_relation IN SELECT n.nspname,c.relname FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname IN ('public','commercial_private') AND c.relkind='r' AND c.relname NOT LIKE 'm3\_%' ESCAPE '\' ORDER BY n.nspname,c.relname LOOP
    EXECUTE pg_catalog.format('SELECT pg_catalog.md5(COALESCE(pg_catalog.string_agg(pg_catalog.to_jsonb(t)::text,E''\\n'' ORDER BY pg_catalog.to_jsonb(t)::text),'''')) FROM ONLY %I.%I t',v_relation.nspname,v_relation.relname) INTO v_digest;
    v_data := v_data||pg_catalog.jsonb_build_object(v_relation.nspname||'.'||v_relation.relname,v_digest);
  END LOOP;
 IF v_data::text IS DISTINCT FROM pg_catalog.current_setting('m3.entry_data')
 OR (pg_catalog.jsonb_build_object(
 'schemas',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(n) ORDER BY n.oid) FROM pg_catalog.pg_namespace n WHERE n.nspname IN ('public','commercial_private')),
 'relations',(SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_array(c.oid,c.relname,c.relkind,c.relowner,c.relacl,c.relrowsecurity,c.relforcerowsecurity) ORDER BY c.oid) FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','commercial_private') AND c.relname NOT LIKE 'm3\_%' ESCAPE '\'),
 'columns',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(a) ORDER BY a.attrelid,a.attnum) FROM pg_catalog.pg_attribute a JOIN pg_catalog.pg_class c ON c.oid=a.attrelid JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','commercial_private') AND c.relname NOT LIKE 'm3\_%' ESCAPE '\' AND a.attnum>0),
 'constraints',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(k) ORDER BY k.oid) FROM pg_catalog.pg_constraint k JOIN pg_catalog.pg_class c ON c.oid=k.conrelid JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','commercial_private') AND c.relname NOT LIKE 'm3\_%' ESCAPE '\'),
 'indexes',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(i) ORDER BY i.indexrelid) FROM pg_catalog.pg_index i JOIN pg_catalog.pg_class c ON c.oid=i.indrelid JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','commercial_private') AND c.relname NOT LIKE 'm3\_%' ESCAPE '\'),
 'routines',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(p) ORDER BY p.oid) FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ('public','commercial_private') AND p.proname NOT LIKE 'm3\_%' ESCAPE '\'),
 'triggers',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(t) ORDER BY t.oid) FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_class c ON c.oid=t.tgrelid JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','commercial_private') AND c.relname NOT LIKE 'm3\_%' ESCAPE '\'),
 'policies',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(p) ORDER BY p.oid) FROM pg_catalog.pg_policy p),
 'defaults',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(d) ORDER BY d.oid) FROM pg_catalog.pg_default_acl d),
 'roles',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(r) ORDER BY r.oid) FROM pg_catalog.pg_roles r),
 'memberships',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(m) ORDER BY m.oid) FROM pg_catalog.pg_auth_members m),
 'publications',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(p) ORDER BY p.oid) FROM pg_catalog.pg_publication p),
 'publication_tables',(SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(p) ORDER BY p.pubname,p.schemaname,p.tablename) FROM pg_catalog.pg_publication_tables p)))::text IS DISTINCT FROM pg_catalog.current_setting('m3.entry_metadata') THEN
 RAISE EXCEPTION 'M3 predecessor data/metadata preservation failed'; END IF;
 IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_class WHERE relnamespace='commercial_private'::pg_catalog.regnamespace AND relkind='r')<>6
 OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_class WHERE relnamespace='commercial_private'::pg_catalog.regnamespace AND relkind='i')<>13
 OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc WHERE pronamespace='commercial_private'::pg_catalog.regnamespace)<>4
 OR EXISTS(SELECT 1 FROM pg_catalog.pg_class WHERE relnamespace='commercial_private'::pg_catalog.regnamespace AND relkind NOT IN ('r','i'))
 OR EXISTS(SELECT 1 FROM pg_catalog.pg_policy p JOIN pg_catalog.pg_class c ON c.oid=p.polrelid WHERE c.relnamespace='commercial_private'::pg_catalog.regnamespace)
 OR EXISTS(SELECT 1 FROM pg_catalog.pg_class c WHERE c.relnamespace='commercial_private'::pg_catalog.regnamespace AND c.relkind='r' AND (c.relowner<>v_owner OR NOT c.relrowsecurity OR c.relforcerowsecurity))
 OR EXISTS(SELECT 1 FROM pg_catalog.pg_class c CROSS JOIN LATERAL pg_catalog.aclexplode(COALESCE(c.relacl,pg_catalog.acldefault('r',c.relowner))) a WHERE c.relnamespace='commercial_private'::pg_catalog.regnamespace AND c.relkind='r' AND a.grantee<>v_owner)
 OR EXISTS(SELECT 1 FROM pg_catalog.pg_attribute a JOIN pg_catalog.pg_class c ON c.oid=a.attrelid WHERE c.relnamespace='commercial_private'::pg_catalog.regnamespace AND a.attnum>0 AND a.attacl IS NOT NULL)
 OR EXISTS(SELECT 1 FROM pg_catalog.pg_proc p CROSS JOIN LATERAL pg_catalog.aclexplode(COALESCE(p.proacl,pg_catalog.acldefault('f',p.proowner))) a WHERE p.pronamespace='commercial_private'::pg_catalog.regnamespace AND a.grantee<>v_owner)
 OR EXISTS(SELECT 1 FROM pg_catalog.pg_proc p WHERE p.pronamespace='commercial_private'::pg_catalog.regnamespace AND (p.proowner<>v_owner OR p.prosecdef OR p.proconfig IS DISTINCT FROM ARRAY['search_path=commercial_private, pg_temp'] OR p.provolatile<>(CASE WHEN p.proname='m3_capture_shadow_v1' THEN 'v'::"char" ELSE 'i'::"char" END)))
 OR EXISTS(SELECT 1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_class c ON c.oid=t.tgrelid WHERE c.relnamespace='commercial_private'::pg_catalog.regnamespace AND NOT t.tgisinternal)
 OR EXISTS(SELECT 1 FROM pg_catalog.pg_publication_tables WHERE schemaname='commercial_private')
 OR EXISTS(SELECT 1 FROM commercial_private.m3_shadow_heads)
 OR EXISTS(SELECT 1 FROM commercial_private.m3_shadow_runs) THEN
 RAISE EXCEPTION 'M3 inventory/security/empty-state postcondition failed'; END IF;
END;
$m3_postconditions$;



