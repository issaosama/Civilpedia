-- M1b: one deterministic 40-row reference-data cutover; no runtime authority.
-- Authority: accepted M1b contract, reopening record and final C' clarification.
-- Baseline: ebaf5f7b4402366285e214eec99735a931b69d8d; HARDEN-1 is prerequisite.
-- The Supabase runner owns the entire file transaction, including history.
-- All conflicts are checked BEFORE the first insert. Existing rows are never
-- rewritten. Fixed draft metadata is neither publication nor entitlement.
-- Corporate bundle values are Plus floors; its Sponsored key is absent.
-- No persistent helper, API, policy, permission or schema object is introduced.

DO $m1b_reference_data$
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
    RAISE EXCEPTION 'M1b execution context differs from accepted creator';
  END IF;

  -- Fixed lock order; NOWAIT fails closed instead of waiting indefinitely.
  LOCK TABLE ONLY public.plans, commercial_private.entitlement_bundles,
    commercial_private.bundle_items, commercial_private.plan_versions,
    commercial_private.term_prices IN ACCESS EXCLUSIVE MODE NOWAIT;

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
    RAISE EXCEPTION 'M1b M1a/HARDEN-1 structure, RLS, policy or trigger drift';
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
    RAISE EXCEPTION 'M1b public/private ACL, proxy or publication exposure';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_roles
      WHERE rolname IN ('anon','authenticated','service_role')) <> 3 THEN
    RAISE EXCEPTION 'M1b required client roles missing';
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
      RAISE EXCEPTION 'M1b effective client denial failed for %',client.rolname;
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
    RAISE EXCEPTION 'M1b M1a default privilege hardening drift';
  END IF;

  -- D / C precede exact-identity B/E, then C' and finally unrelated F.
  IF EXISTS (SELECT 1 FROM public.plans a JOIN pg_catalog.unnest(expected_plans) e ON a.id = e.id
             WHERE a.code IS DISTINCT FROM e.code) THEN
    RAISE EXCEPTION 'M1b case D: canonical UUID has different stored code';
  END IF;
  IF EXISTS (SELECT 1 FROM public.plans a JOIN pg_catalog.unnest(expected_plans) e ON a.code = e.code
             WHERE a.id IS DISTINCT FROM e.id) THEN
    RAISE EXCEPTION 'M1b case C: exact canonical code has different UUID';
  END IF;
  IF EXISTS (SELECT 1 FROM public.plans a JOIN pg_catalog.unnest(expected_plans) e ON a.id = e.id AND a.code = e.code
             WHERE pg_catalog.to_jsonb(a) IS DISTINCT FROM pg_catalog.to_jsonb(e)) THEN
    RAISE EXCEPTION 'M1b case E: canonical identity metadata differs';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.plans a CROSS JOIN pg_catalog.unnest(expected_plans) e
    WHERE pg_catalog.btrim(pg_catalog.regexp_replace(pg_catalog.lower(pg_catalog.btrim(a.code)),
      '[-._[:space:]]+', '_', 'g'), '_') = e.code
      AND a.code IS DISTINCT FROM e.code
  ) THEN
    RAISE EXCEPTION 'M1b case C-prime: normalized collision, original stored code differs';
  END IF;
  IF EXISTS (
    SELECT 1 FROM commercial_private.entitlement_bundles a
    JOIN pg_catalog.unnest(expected_entitlement_bundles) e ON a.id = e.id OR (a.code, a.version) = (e.code, e.version)
    WHERE pg_catalog.to_jsonb(a) IS DISTINCT FROM pg_catalog.to_jsonb(e)
  ) THEN
    RAISE EXCEPTION 'M1b bundle conflict';
  END IF;
  IF EXISTS (
    SELECT 1 FROM commercial_private.bundle_items a
    JOIN pg_catalog.unnest(expected_bundle_items) e ON a.id = e.id OR (a.bundle_version_id, a.capability_key) = (e.bundle_version_id, e.capability_key)
    WHERE pg_catalog.to_jsonb(a) IS DISTINCT FROM pg_catalog.to_jsonb(e)
  ) THEN
    RAISE EXCEPTION 'M1b bundle item conflict';
  END IF;
  IF EXISTS (
    SELECT 1 FROM commercial_private.plan_versions a
    JOIN pg_catalog.unnest(expected_plan_versions) e ON a.id = e.id OR (a.plan_id, a.version) = (e.plan_id, e.version)
    WHERE pg_catalog.to_jsonb(a) IS DISTINCT FROM pg_catalog.to_jsonb(e)
  ) THEN
    RAISE EXCEPTION 'M1b G plan-version linkage/metadata conflict';
  END IF;
  IF EXISTS (
    SELECT 1 FROM commercial_private.term_prices a
    JOIN pg_catalog.unnest(expected_term_prices) e ON a.id = e.id OR (a.plan_version_id, a.duration_months, a.version) = (e.plan_version_id, e.duration_months, e.version)
    WHERE pg_catalog.to_jsonb(a) IS DISTINCT FROM pg_catalog.to_jsonb(e)
  ) THEN
    RAISE EXCEPTION 'M1b term price conflict';
  END IF;
  -- A frozen bundle must not silently acquire extra capabilities on a re-run.
  IF EXISTS (SELECT 1 FROM commercial_private.bundle_items a
    JOIN pg_catalog.unnest(expected_entitlement_bundles) b ON b.id = a.bundle_version_id
    WHERE NOT EXISTS (SELECT 1 FROM pg_catalog.unnest(expected_bundle_items) e
      WHERE pg_catalog.to_jsonb(a) = pg_catalog.to_jsonb(e))) THEN
    RAISE EXCEPTION 'M1b frozen bundle has unexpected item';
  END IF;
  SELECT pg_catalog.count(*) INTO legacy_count FROM public.plans a
    WHERE NOT EXISTS (SELECT 1 FROM pg_catalog.unnest(expected_plans) e WHERE a.id = e.id);
  IF legacy_count > 0 THEN
    RAISE NOTICE 'M1b case F: % unrelated legacy plans preserved; disposition remains C3 section 33 / M4',legacy_count;
  END IF;

  -- Snapshot every unrelated public/private row and stable security metadata.
  -- Only the forty named canonical rows are excluded from the data comparison.
  FOR pass IN 1..2 LOOP
    data_current := '{}'::jsonb;
    FOR relation IN SELECT n.nspname,c.relname,c.oid FROM pg_catalog.pg_class c
      JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname IN ('public','commercial_private') AND c.relkind = 'r'
      ORDER BY n.nspname,c.relname LOOP
      excluded_ids := CASE relation.oid
        WHEN 'public.plans'::pg_catalog.regclass THEN (SELECT pg_catalog.array_agg(e.id::text) FROM pg_catalog.unnest(expected_plans) e)
        WHEN 'commercial_private.entitlement_bundles'::pg_catalog.regclass THEN (SELECT pg_catalog.array_agg(e.id::text) FROM pg_catalog.unnest(expected_entitlement_bundles) e)
        WHEN 'commercial_private.bundle_items'::pg_catalog.regclass THEN (SELECT pg_catalog.array_agg(e.id::text) FROM pg_catalog.unnest(expected_bundle_items) e)
        WHEN 'commercial_private.plan_versions'::pg_catalog.regclass THEN (SELECT pg_catalog.array_agg(e.id::text) FROM pg_catalog.unnest(expected_plan_versions) e)
        WHEN 'commercial_private.term_prices'::pg_catalog.regclass THEN (SELECT pg_catalog.array_agg(e.id::text) FROM pg_catalog.unnest(expected_term_prices) e)
        ELSE ARRAY[]::text[] END;
      EXECUTE pg_catalog.format(
        'SELECT pg_catalog.md5(coalesce(pg_catalog.string_agg(pg_catalog.to_jsonb(t)::text, E''\\n'' ORDER BY pg_catalog.to_jsonb(t)::text),'''')) FROM ONLY %I.%I t WHERE NOT (pg_catalog.to_jsonb(t)->>''id'' = ANY($1))',
        relation.nspname,relation.relname) INTO row_digest USING excluded_ids;
      data_current := data_current || pg_catalog.jsonb_build_object(relation.nspname || '.' || relation.relname,row_digest);
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
) INTO metadata_current;
    IF pass = 1 THEN
      data_snapshot := data_current;
      metadata_snapshot := metadata_current;

      -- Exact absence or compatibility was proven for ALL families above.
      INSERT INTO public.plans (id, code, name, description, is_active, created_at, updated_at)
      SELECT id, code, name, description, is_active, created_at, updated_at FROM pg_catalog.unnest(expected_plans)
      ON CONFLICT DO NOTHING;

      INSERT INTO commercial_private.entitlement_bundles (id, code, version, registry_version, status, published_at, retired_at, created_at)
      SELECT id, code, version, registry_version, status, published_at, retired_at, created_at FROM pg_catalog.unnest(expected_entitlement_bundles)
      ON CONFLICT DO NOTHING;

      INSERT INTO commercial_private.bundle_items (id, bundle_version_id, capability_key, value_kind, value_boolean, value_integer, value_text, is_required, created_at)
      SELECT id, bundle_version_id, capability_key, value_kind, value_boolean, value_integer, value_text, is_required, created_at FROM pg_catalog.unnest(expected_bundle_items)
      ON CONFLICT DO NOTHING;

      INSERT INTO commercial_private.plan_versions (id, plan_id, version, bundle_version_id, pricing_mode, name_ar, description_ar, sort_order, status, published_at, retired_at, effective_from, effective_until, created_at)
      SELECT id, plan_id, version, bundle_version_id, pricing_mode, name_ar, description_ar, sort_order, status, published_at, retired_at, effective_from, effective_until, created_at FROM pg_catalog.unnest(expected_plan_versions)
      ON CONFLICT DO NOTHING;

      INSERT INTO commercial_private.term_prices (id, plan_version_id, pricing_mode, version, duration_months, amount_iqd, currency, status, published_at, retired_at, effective_from, effective_until, created_at)
      SELECT id, plan_version_id, pricing_mode, version, duration_months, amount_iqd, currency, status, published_at, retired_at, effective_from, effective_until, created_at FROM pg_catalog.unnest(expected_term_prices)
      ON CONFLICT DO NOTHING;
    ELSE
      IF data_current IS DISTINCT FROM data_snapshot OR metadata_current IS DISTINCT FROM metadata_snapshot THEN
        RAISE EXCEPTION 'M1b unrelated data or security/structure fingerprint changed';
      END IF;
    END IF;
  END LOOP;

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
END;
$m1b_reference_data$;
