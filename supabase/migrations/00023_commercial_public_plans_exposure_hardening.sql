-- HARDEN-1: revoke-only public.plans exposure hardening.
-- Accepted contract: CIVILPEDIA_COMMERCIAL_HARDEN1_PUBLIC_PLANS_EXPOSURE_IMPLEMENTATION_CONTRACT_V1.
-- Contract authority was accepted in commit 6d06452, without implementation authorization.
-- Explicit HARDEN-1 implementation authorization was issued separately by the
-- ChatGPT Architect after that contract commit/push and before implementation.
-- Persisted provenance: HARDEN-1 contract, Post-Acceptance Implementation Authorization Record.
-- M1b seed remains unauthorized; ROWS_AUTHORIZED = 0.
-- Zero data mutation, seed, replacement endpoint or default-privilege change.
-- The verified Supabase runner owns per-file atomicity, including history.
-- Migration-local snapshots contain hashes only and disappear with the transaction.

DO $harden1_preflight$
DECLARE
  plans_oid oid := pg_catalog.to_regclass('public.plans');
  owner_oid oid := 'postgres'::pg_catalog.regrole;
  private_oid oid := pg_catalog.to_regnamespace('commercial_private');
  client record;
  snapshot text;
BEGIN
  -- Internal locking is compatible with the runner's implicit transaction.
  -- NOWAIT bounds acquisition without authored transaction wrappers.
  LOCK TABLE ONLY public.plans IN ACCESS EXCLUSIVE MODE NOWAIT;
  IF current_user <> 'postgres' OR session_user <> 'postgres'
     OR pg_catalog.current_setting('role') <> 'none'
     OR pg_catalog.current_setting('server_version_num')::integer / 10000 <> 17 THEN
    RAISE EXCEPTION 'HARDEN-1 execution context differs from verified migration creator';
  END IF;
  IF plans_oid IS NULL OR NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_class
    WHERE oid = plans_oid AND relkind = 'r' AND relowner = owner_oid
      AND relrowsecurity AND NOT relforcerowsecurity
  ) THEN
    RAISE EXCEPTION 'HARDEN-1 public.plans identity, ownership or RLS baseline drift';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_roles
      WHERE rolname IN ('anon','authenticated','service_role')) <> 3
     OR NOT (SELECT rolbypassrls FROM pg_catalog.pg_roles WHERE rolname = 'service_role')
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname IN ('anon','authenticated')
                 AND (rolsuper OR rolbypassrls)) THEN
    RAISE EXCEPTION 'HARDEN-1 client/server role baseline drift';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_attribute
      WHERE attrelid = plans_oid AND attnum > 0 AND NOT attisdropped) <> 7
     OR EXISTS (
       SELECT 1 FROM (VALUES
         (1,'id','uuid',true,'gen_random_uuid()'),
         (2,'code','text',true,NULL),
         (3,'name','text',true,NULL),
         (4,'description','text',false,NULL),
         (5,'is_active','boolean',true,'true'),
         (6,'created_at','timestamp with time zone',true,'now()'),
         (7,'updated_at','timestamp with time zone',true,'now()')
       ) expected(position,column_name,type_name,required,default_expression)
       LEFT JOIN pg_catalog.pg_attribute a ON a.attrelid = plans_oid AND a.attnum = expected.position
       LEFT JOIN pg_catalog.pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
       WHERE a.attname IS DISTINCT FROM expected.column_name
         OR pg_catalog.format_type(a.atttypid,a.atttypmod) IS DISTINCT FROM expected.type_name
         OR a.attnotnull IS DISTINCT FROM expected.required
         OR pg_catalog.pg_get_expr(d.adbin,d.adrelid) IS DISTINCT FROM expected.default_expression
         OR a.attisdropped OR a.attacl IS NOT NULL OR a.attidentity <> '' OR a.attgenerated <> ''
     ) THEN
    RAISE EXCEPTION 'HARDEN-1 plans columns/defaults/column ACL drift';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_constraint WHERE conrelid = plans_oid) <> 2
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint
       WHERE conrelid = plans_oid AND conname = 'plans_pkey' AND contype = 'p' AND conkey = ARRAY[1]::smallint[]
         AND convalidated AND NOT condeferrable)
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint
       WHERE conrelid = plans_oid AND conname = 'plans_code_key' AND contype = 'u' AND conkey = ARRAY[2]::smallint[]
         AND convalidated AND NOT condeferrable)
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_index
         WHERE indrelid = plans_oid AND indisvalid AND indisready AND indisunique) <> 2
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_trigger
         WHERE tgrelid = plans_oid AND NOT tgisinternal) <> 1
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger
         WHERE tgrelid = plans_oid AND NOT tgisinternal AND tgname = 'trigger_set_updated_at'
           AND tgtype = 19 AND tgenabled = 'O' AND tgnargs = 0
           AND tgfoid = 'public.set_updated_at()'::pg_catalog.regprocedure) THEN
    RAISE EXCEPTION 'HARDEN-1 plans constraint/index/trigger baseline drift';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_policy WHERE polrelid = plans_oid) <> 1
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_policy p WHERE p.polrelid = plans_oid
         AND p.polname = 'plans_select_all' AND p.polcmd = 'r' AND p.polpermissive
         AND (SELECT pg_catalog.array_agg(x ORDER BY x) FROM pg_catalog.unnest(p.polroles) x)
           = (SELECT pg_catalog.array_agg(oid ORDER BY oid) FROM pg_catalog.pg_roles
              WHERE rolname IN ('anon','authenticated'))
         AND pg_catalog.pg_get_expr(p.polqual,p.polrelid) = 'true'
         AND p.polwithcheck IS NULL
     ) THEN
    RAISE EXCEPTION 'HARDEN-1 expected plans_select_all policy missing or drifted';
  END IF;
  IF EXISTS (
    WITH actual AS (
      SELECT a.grantee,a.privilege_type,a.grantor,a.is_grantable
      FROM pg_catalog.pg_class c
      CROSS JOIN LATERAL pg_catalog.aclexplode(coalesce(c.relacl,pg_catalog.acldefault('r',c.relowner))) a
      WHERE c.oid = plans_oid
    ), expected AS (
      SELECT r.oid AS grantee,p.privilege_type,owner_oid AS grantor,false AS is_grantable
      FROM pg_catalog.pg_roles r CROSS JOIN (VALUES
        ('SELECT'),('INSERT'),('UPDATE'),('DELETE'),('TRUNCATE'),('REFERENCES'),('TRIGGER'),('MAINTAIN')
      ) p(privilege_type) WHERE r.rolname IN ('postgres','service_role')
      UNION ALL SELECT oid,'SELECT',owner_oid,false FROM pg_catalog.pg_roles
        WHERE rolname IN ('anon','authenticated')
    )
    SELECT 1 FROM ((SELECT * FROM actual EXCEPT SELECT * FROM expected)
      UNION ALL (SELECT * FROM expected EXCEPT SELECT * FROM actual)) difference
  ) THEN
    RAISE EXCEPTION 'HARDEN-1 plans ACL/PUBLIC/grant-option baseline drift';
  END IF;
  FOR client IN SELECT oid,rolname FROM pg_catalog.pg_roles WHERE rolname IN ('anon','authenticated') LOOP
    IF NOT pg_catalog.has_table_privilege(client.oid,plans_oid,'SELECT')
       OR NOT pg_catalog.has_any_column_privilege(client.oid,plans_oid,'SELECT')
       OR pg_catalog.has_table_privilege(client.oid,plans_oid,'INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER,MAINTAIN')
       OR EXISTS (SELECT 1 FROM pg_catalog.pg_roles r
          WHERE r.oid <> client.oid AND pg_catalog.pg_has_role(client.oid,r.oid,'MEMBER')
            AND (r.rolsuper OR r.rolbypassrls OR r.rolname IN
              ('postgres','service_role','supabase_admin','pg_read_all_data','pg_write_all_data','pg_maintain'))) THEN
      RAISE EXCEPTION 'HARDEN-1 unexpected effective or inherited plans privilege for %',client.rolname;
    END IF;
  END LOOP;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_constraint
      WHERE contype = 'f' AND confrelid = plans_oid) <> 2
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint
       WHERE conrelid = 'public.subscriptions'::pg_catalog.regclass AND conname = 'subscriptions_plan_id_fkey'
         AND contype = 'f' AND confrelid = plans_oid AND confkey = ARRAY[1]::smallint[]
         AND conkey = ARRAY[(SELECT attnum FROM pg_catalog.pg_attribute
           WHERE attrelid = 'public.subscriptions'::pg_catalog.regclass AND attname = 'plan_id')]::smallint[]
         AND confupdtype = 'a' AND confdeltype = 'r' AND confmatchtype = 's'
         AND convalidated AND NOT condeferrable)
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint
       WHERE conrelid = 'commercial_private.plan_versions'::pg_catalog.regclass AND conname = 'fk_plan_versions_plan_id'
         AND contype = 'f' AND confrelid = plans_oid AND confkey = ARRAY[1]::smallint[] AND conkey = ARRAY[2]::smallint[]
         AND confupdtype = 'r' AND confdeltype = 'r' AND confmatchtype = 's'
         AND convalidated AND NOT condeferrable) THEN
    RAISE EXCEPTION 'HARDEN-1 public/private plan FK baseline drift';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_depend d JOIN pg_catalog.pg_rewrite w ON w.oid = d.objid
      JOIN pg_catalog.pg_class c ON c.oid = w.ev_class
      WHERE d.classid = 'pg_catalog.pg_rewrite'::pg_catalog.regclass AND d.refobjid = plans_oid
        AND c.relkind IN ('v','m'))
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname NOT LIKE 'pg_%' AND n.nspname <> 'information_schema'
          AND p.prosrc ~* '\m(public[.])?plans\M')
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_publication_tables WHERE schemaname = 'public' AND tablename = 'plans') THEN
    RAISE EXCEPTION 'HARDEN-1 unreviewed plans proxy or publication dependency';
  END IF;
  IF private_oid IS NULL
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_class WHERE relnamespace = private_oid AND relkind = 'r') <> 4
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_class WHERE relnamespace = private_oid AND relkind = 'r'
                  AND (relowner <> owner_oid OR NOT relrowsecurity OR relforcerowsecurity))
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_policy p JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
                  WHERE c.relnamespace = private_oid)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_namespace n
        CROSS JOIN LATERAL pg_catalog.aclexplode(coalesce(n.nspacl,pg_catalog.acldefault('n',n.nspowner))) a
        WHERE n.oid = private_oid AND a.grantee <> owner_oid)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_class c
        CROSS JOIN LATERAL pg_catalog.aclexplode(coalesce(c.relacl,pg_catalog.acldefault('r',c.relowner))) a
        WHERE c.relnamespace = private_oid AND c.relkind = 'r' AND a.grantee <> owner_oid) THEN
    RAISE EXCEPTION 'HARDEN-1 private M1a security baseline drift';
  END IF;
  IF EXISTS (
    SELECT 1 FROM (VALUES ('r'),('S'),('f'),('T')) kind(class)
    LEFT JOIN pg_catalog.pg_default_acl d ON d.defaclrole = owner_oid
      AND d.defaclnamespace = 0 AND d.defaclobjtype = kind.class::"char"
    CROSS JOIN LATERAL pg_catalog.aclexplode(coalesce(d.defaclacl,pg_catalog.acldefault(kind.class::"char",owner_oid))) a
    WHERE a.grantee <> owner_oid
  ) OR EXISTS (SELECT 1 FROM pg_catalog.pg_default_acl d
    CROSS JOIN LATERAL pg_catalog.aclexplode(d.defaclacl) a
    WHERE d.defaclrole = owner_oid AND d.defaclnamespace = private_oid AND a.grantee <> owner_oid) THEN
    RAISE EXCEPTION 'HARDEN-1 M1a creator defaults drift; no default ACL repair is permitted';
  END IF;
  -- Only hashes of data and unchanged metadata cross the assertion blocks.
  SELECT pg_catalog.md5(jsonb_build_object(
 'data',jsonb_build_object(
 'plans',(SELECT md5(coalesce(string_agg(row_to_json(x)::text,E'\n' ORDER BY id),'')) FROM public.plans x),
 'subscriptions',(SELECT md5(coalesce(string_agg(row_to_json(x)::text,E'\n' ORDER BY id),'')) FROM public.subscriptions x),
 'directory',(SELECT md5(coalesce(string_agg(row_to_json(x)::text,E'\n' ORDER BY id),'')) FROM public.directory_entities x),
 'plan_versions',(SELECT md5(coalesce(string_agg(row_to_json(x)::text,E'\n' ORDER BY id),'')) FROM commercial_private.plan_versions x),
 'bundles',(SELECT md5(coalesce(string_agg(row_to_json(x)::text,E'\n' ORDER BY id),'')) FROM commercial_private.entitlement_bundles x),
 'items',(SELECT md5(coalesce(string_agg(row_to_json(x)::text,E'\n' ORDER BY id),'')) FROM commercial_private.bundle_items x),
 'prices',(SELECT md5(coalesce(string_agg(row_to_json(x)::text,E'\n' ORDER BY id),'')) FROM commercial_private.term_prices x)),
 'unrelated_table_security',(SELECT md5(coalesce(string_agg(c.oid::text||':'||coalesce(c.relacl::text,'NULL')||':'||c.relrowsecurity::text||':'||c.relforcerowsecurity::text,E'\n' ORDER BY c.oid),'')) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','commercial_private') AND c.oid<>'public.plans'::regclass),
 'unrelated_policies',(SELECT md5(coalesce(string_agg(p.oid::text||':'||p.polname||':'||p.polroles::text||':'||coalesce(p.polqual::text,'NULL')||':'||coalesce(p.polwithcheck::text,'NULL'),E'\n' ORDER BY p.oid),'')) FROM pg_policy p JOIN pg_class c ON c.oid=p.polrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','commercial_private') AND p.polrelid<>'public.plans'::regclass),
 'functions',(SELECT md5(coalesce(string_agg(p.oid::text||':'||coalesce(p.proacl::text,'NULL')||':'||pg_get_functiondef(p.oid),E'\n' ORDER BY p.oid),'')) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ('public','commercial_private') AND p.prokind IN ('f','p','w')),
 'defaults',(SELECT md5(coalesce(string_agg(d.oid::text||':'||d.defaclrole::text||':'||d.defaclnamespace::text||':'||d.defaclobjtype::text||':'||d.defaclacl::text,E'\n' ORDER BY d.oid),'')) FROM pg_default_acl d),
 'structures',(SELECT md5(coalesce(string_agg(a.attrelid::text||':'||a.attnum::text||':'||a.attname||':'||a.atttypid::text||':'||a.attnotnull::text||':'||coalesce(a.attacl::text,'NULL')||':'||coalesce(pg_get_expr(d.adbin,d.adrelid),'NULL'),E'\n' ORDER BY a.attrelid,a.attnum),'')) FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid JOIN pg_namespace n ON n.oid=c.relnamespace LEFT JOIN pg_attrdef d ON d.adrelid=a.attrelid AND d.adnum=a.attnum WHERE n.nspname IN ('public','commercial_private') AND c.relkind='r' AND a.attnum>0 AND NOT a.attisdropped),
 'constraints',(SELECT md5(coalesce(string_agg(c.oid::text||':'||c.conname||':'||c.convalidated::text||':'||pg_get_constraintdef(c.oid),E'\n' ORDER BY c.oid),'')) FROM pg_constraint c JOIN pg_namespace n ON n.oid=c.connamespace WHERE n.nspname IN ('public','commercial_private')),
 'roles',(SELECT md5(coalesce(string_agg(oid::text||':'||rolname||':'||rolsuper::text||':'||rolbypassrls::text||':'||rolinherit::text||':'||coalesce(rolconfig::text,'NULL'),E'\n' ORDER BY oid),'')) FROM pg_roles),
 'memberships',(SELECT md5(coalesce(string_agg(roleid::text||':'||member::text||':'||grantor::text||':'||admin_option::text||':'||inherit_option::text||':'||set_option::text,E'\n' ORDER BY roleid,member,grantor),'')) FROM pg_auth_members),
 'schemas',(SELECT md5(coalesce(string_agg(oid::text||':'||nspname||':'||nspowner::text||':'||coalesce(nspacl::text,'NULL'),E'\n' ORDER BY oid),'')) FROM pg_namespace WHERE nspname IN ('public','commercial_private')),
 'publications',(SELECT md5(coalesce(string_agg(pubname||':'||schemaname||':'||tablename,E'\n' ORDER BY pubname,schemaname,tablename),'')) FROM pg_publication_tables),
 'extensions',(SELECT md5(coalesce(string_agg(extname||':'||extversion,E'\n' ORDER BY extname),'')) FROM pg_extension)
)::text) INTO snapshot;
  PERFORM pg_catalog.set_config('civilpedia.harden1_snapshot',snapshot,true);
END;
$harden1_preflight$;

REVOKE SELECT ON TABLE public.plans FROM PUBLIC, anon, authenticated RESTRICT;
DROP POLICY plans_select_all ON public.plans;

DO $harden1_postconditions$
DECLARE
  plans_oid oid := 'public.plans'::pg_catalog.regclass;
  owner_oid oid := 'postgres'::pg_catalog.regrole;
  client record;
  snapshot text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class
      WHERE oid = plans_oid AND relkind = 'r' AND relowner = owner_oid
        AND relrowsecurity AND NOT relforcerowsecurity)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_policy WHERE polrelid = plans_oid)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_attribute
        WHERE attrelid = plans_oid AND attnum > 0 AND NOT attisdropped AND attacl IS NOT NULL) THEN
    RAISE EXCEPTION 'HARDEN-1 final plans RLS/policy/column posture failed';
  END IF;
  IF EXISTS (
    WITH actual AS (
      SELECT a.grantee,a.privilege_type,a.grantor,a.is_grantable
      FROM pg_catalog.pg_class c
      CROSS JOIN LATERAL pg_catalog.aclexplode(coalesce(c.relacl,pg_catalog.acldefault('r',c.relowner))) a
      WHERE c.oid = plans_oid
    ), expected AS (
      SELECT r.oid AS grantee,p.privilege_type,owner_oid AS grantor,false AS is_grantable
      FROM pg_catalog.pg_roles r CROSS JOIN (VALUES
        ('SELECT'),('INSERT'),('UPDATE'),('DELETE'),('TRUNCATE'),('REFERENCES'),('TRIGGER'),('MAINTAIN')
      ) p(privilege_type) WHERE r.rolname IN ('postgres','service_role')
    )
    SELECT 1 FROM ((SELECT * FROM actual EXCEPT SELECT * FROM expected)
      UNION ALL (SELECT * FROM expected EXCEPT SELECT * FROM actual)) difference
  ) THEN
    RAISE EXCEPTION 'HARDEN-1 final ACL denial or retained owner/server authority failed';
  END IF;
  FOR client IN SELECT oid,rolname FROM pg_catalog.pg_roles WHERE rolname IN ('anon','authenticated') LOOP
    IF pg_catalog.has_table_privilege(client.oid,plans_oid,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER,MAINTAIN')
       OR pg_catalog.has_any_column_privilege(client.oid,plans_oid,'SELECT,INSERT,UPDATE,REFERENCES')
       OR pg_catalog.pg_has_role(client.oid,owner_oid,'MEMBER')
       OR pg_catalog.pg_has_role(client.oid,owner_oid,'SET') THEN
      RAISE EXCEPTION 'HARDEN-1 effective ordinary-client denial failed for %',client.rolname;
    END IF;
  END LOOP;
  SELECT pg_catalog.md5(jsonb_build_object(
 'data',jsonb_build_object(
 'plans',(SELECT md5(coalesce(string_agg(row_to_json(x)::text,E'\n' ORDER BY id),'')) FROM public.plans x),
 'subscriptions',(SELECT md5(coalesce(string_agg(row_to_json(x)::text,E'\n' ORDER BY id),'')) FROM public.subscriptions x),
 'directory',(SELECT md5(coalesce(string_agg(row_to_json(x)::text,E'\n' ORDER BY id),'')) FROM public.directory_entities x),
 'plan_versions',(SELECT md5(coalesce(string_agg(row_to_json(x)::text,E'\n' ORDER BY id),'')) FROM commercial_private.plan_versions x),
 'bundles',(SELECT md5(coalesce(string_agg(row_to_json(x)::text,E'\n' ORDER BY id),'')) FROM commercial_private.entitlement_bundles x),
 'items',(SELECT md5(coalesce(string_agg(row_to_json(x)::text,E'\n' ORDER BY id),'')) FROM commercial_private.bundle_items x),
 'prices',(SELECT md5(coalesce(string_agg(row_to_json(x)::text,E'\n' ORDER BY id),'')) FROM commercial_private.term_prices x)),
 'unrelated_table_security',(SELECT md5(coalesce(string_agg(c.oid::text||':'||coalesce(c.relacl::text,'NULL')||':'||c.relrowsecurity::text||':'||c.relforcerowsecurity::text,E'\n' ORDER BY c.oid),'')) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','commercial_private') AND c.oid<>'public.plans'::regclass),
 'unrelated_policies',(SELECT md5(coalesce(string_agg(p.oid::text||':'||p.polname||':'||p.polroles::text||':'||coalesce(p.polqual::text,'NULL')||':'||coalesce(p.polwithcheck::text,'NULL'),E'\n' ORDER BY p.oid),'')) FROM pg_policy p JOIN pg_class c ON c.oid=p.polrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','commercial_private') AND p.polrelid<>'public.plans'::regclass),
 'functions',(SELECT md5(coalesce(string_agg(p.oid::text||':'||coalesce(p.proacl::text,'NULL')||':'||pg_get_functiondef(p.oid),E'\n' ORDER BY p.oid),'')) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ('public','commercial_private') AND p.prokind IN ('f','p','w')),
 'defaults',(SELECT md5(coalesce(string_agg(d.oid::text||':'||d.defaclrole::text||':'||d.defaclnamespace::text||':'||d.defaclobjtype::text||':'||d.defaclacl::text,E'\n' ORDER BY d.oid),'')) FROM pg_default_acl d),
 'structures',(SELECT md5(coalesce(string_agg(a.attrelid::text||':'||a.attnum::text||':'||a.attname||':'||a.atttypid::text||':'||a.attnotnull::text||':'||coalesce(a.attacl::text,'NULL')||':'||coalesce(pg_get_expr(d.adbin,d.adrelid),'NULL'),E'\n' ORDER BY a.attrelid,a.attnum),'')) FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid JOIN pg_namespace n ON n.oid=c.relnamespace LEFT JOIN pg_attrdef d ON d.adrelid=a.attrelid AND d.adnum=a.attnum WHERE n.nspname IN ('public','commercial_private') AND c.relkind='r' AND a.attnum>0 AND NOT a.attisdropped),
 'constraints',(SELECT md5(coalesce(string_agg(c.oid::text||':'||c.conname||':'||c.convalidated::text||':'||pg_get_constraintdef(c.oid),E'\n' ORDER BY c.oid),'')) FROM pg_constraint c JOIN pg_namespace n ON n.oid=c.connamespace WHERE n.nspname IN ('public','commercial_private')),
 'roles',(SELECT md5(coalesce(string_agg(oid::text||':'||rolname||':'||rolsuper::text||':'||rolbypassrls::text||':'||rolinherit::text||':'||coalesce(rolconfig::text,'NULL'),E'\n' ORDER BY oid),'')) FROM pg_roles),
 'memberships',(SELECT md5(coalesce(string_agg(roleid::text||':'||member::text||':'||grantor::text||':'||admin_option::text||':'||inherit_option::text||':'||set_option::text,E'\n' ORDER BY roleid,member,grantor),'')) FROM pg_auth_members),
 'schemas',(SELECT md5(coalesce(string_agg(oid::text||':'||nspname||':'||nspowner::text||':'||coalesce(nspacl::text,'NULL'),E'\n' ORDER BY oid),'')) FROM pg_namespace WHERE nspname IN ('public','commercial_private')),
 'publications',(SELECT md5(coalesce(string_agg(pubname||':'||schemaname||':'||tablename,E'\n' ORDER BY pubname,schemaname,tablename),'')) FROM pg_publication_tables),
 'extensions',(SELECT md5(coalesce(string_agg(extname||':'||extversion,E'\n' ORDER BY extname),'')) FROM pg_extension)
)::text) INTO snapshot;
  IF snapshot IS DISTINCT FROM pg_catalog.current_setting('civilpedia.harden1_snapshot') THEN
    RAISE EXCEPTION 'HARDEN-1 data/structure/FK/unrelated security fingerprint changed';
  END IF;
END;
$harden1_postconditions$;
