-- HARDEN-1: final-state PostgreSQL evidence independent of migration source.
-- Disposable local chain only, run as the verified PostgreSQL 17 creator.
-- Before/after MIGRATION fingerprints and genuine Auth HTTP probes are separate
-- required gates; snapshots here prove fixture cleanup, not migration history.
-- Every fixture is noncanonical and all helpers/rows disappear with ROLLBACK.
BEGIN;

SELECT no_plan();

SELECT is(current_setting('server_version_num')::integer / 10000, 17,
  'runtime is the accepted PostgreSQL 17 context');
SELECT is(session_user::text, 'postgres', 'verified local migration login');
SELECT is(current_user::text, 'postgres', 'owner executes pgTAP and fixtures');
SELECT is((SELECT count(*)::integer FROM pg_roles
  WHERE rolname IN ('anon', 'authenticated')), 2, 'both ordinary API roles exist');
SELECT is((SELECT count(*)::integer FROM pg_roles
  WHERE rolname IN ('postgres', 'service_role', 'supabase_admin')), 3,
  'all trusted membership targets exist');

-- A forced success exception rolls successful attempts back too. Role and JWT
-- settings revert with that inner subtransaction; clients never execute pgTAP.
CREATE FUNCTION pg_temp.harden1_result(
  p_sql text, p_role name DEFAULT NULL, p_subject text DEFAULT NULL
)
RETURNS text LANGUAGE plpgsql SECURITY INVOKER
SET search_path = pg_catalog, pg_temp AS $body$
DECLARE state text; constraint_name text; message text;
BEGIN
  BEGIN
    IF p_subject IS NOT NULL THEN
      PERFORM set_config('request.jwt.claim.sub', p_subject, true);
      PERFORM set_config('request.jwt.claims',
        jsonb_build_object('sub', p_subject, 'role', p_role)::text, true);
    END IF;
    IF p_role IS NOT NULL THEN
      EXECUTE format('SET LOCAL ROLE %I', p_role);
    END IF;
    EXECUTE p_sql;
    RAISE EXCEPTION 'harden1_success_rollback' USING ERRCODE = 'P0T00';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS state = RETURNED_SQLSTATE,
      constraint_name = CONSTRAINT_NAME, message = MESSAGE_TEXT;
    IF state = 'P0T00' AND message = 'harden1_success_rollback' THEN
      RETURN 'NO_ERROR';
    END IF;
    RETURN state || '|' || coalesce(constraint_name, '');
  END;
END;
$body$;

CREATE FUNCTION pg_temp.harden1_read(p_sql text, p_role name)
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

CREATE FUNCTION pg_temp.harden1_data_fingerprint(p_relation regclass)
RETURNS text LANGUAGE plpgsql SECURITY INVOKER
SET search_path = pg_catalog, pg_temp AS $body$
DECLARE value text;
BEGIN
  EXECUTE format('SELECT md5(coalesce(string_agg(to_jsonb(t)::text,
    E''\n'' ORDER BY to_jsonb(t)::text), '''')) FROM %s t', p_relation)
    INTO value;
  RETURN value;
END;
$body$;

-- Only stable metadata is fingerprinted: no row estimates or volatile stats.
CREATE FUNCTION pg_temp.harden1_metadata_fingerprint()
RETURNS jsonb LANGUAGE sql SECURITY INVOKER
SET search_path = pg_catalog, pg_temp AS $body$
SELECT jsonb_build_object(
  'schemas', (SELECT jsonb_agg(jsonb_build_array(n.oid, n.nspname,
    n.nspowner, n.nspacl) ORDER BY n.oid) FROM pg_namespace n
    WHERE n.nspname IN ('public', 'commercial_private')),
  'relations', (SELECT jsonb_agg(jsonb_build_array(c.oid, c.relname,
    c.relkind, c.relowner, c.relrowsecurity, c.relforcerowsecurity,
    c.relacl, obj_description(c.oid, 'pg_class')) ORDER BY c.oid)
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname IN ('public', 'commercial_private')),
  'columns', (SELECT jsonb_agg(jsonb_build_array(a.attrelid, a.attnum,
    a.attname, a.atttypid, a.atttypmod, a.attnotnull, a.attacl,
    a.attidentity, a.attgenerated, pg_get_expr(d.adbin, d.adrelid))
    ORDER BY a.attrelid, a.attnum)
    FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
    WHERE n.nspname IN ('public', 'commercial_private')
      AND a.attnum > 0 AND NOT a.attisdropped),
  'constraints', (SELECT jsonb_agg(jsonb_build_array(k.oid, k.conname,
    k.conrelid, k.confrelid, k.convalidated, k.condeferrable,
    k.condeferred, pg_get_constraintdef(k.oid)) ORDER BY k.oid)
    FROM pg_constraint k JOIN pg_namespace n ON n.oid = k.connamespace
    WHERE n.nspname IN ('public', 'commercial_private')),
  'policies', (SELECT jsonb_agg(to_jsonb(p) ORDER BY p.oid)
    FROM pg_policy p JOIN pg_class c ON c.oid = p.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname IN ('public', 'commercial_private')),
  'routines', (SELECT jsonb_agg(jsonb_build_array(p.oid, p.proowner,
    p.proacl, pg_get_functiondef(p.oid)) ORDER BY p.oid)
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('public', 'commercial_private')
      AND p.prokind IN ('f', 'p', 'w')),
  'triggers', (SELECT jsonb_agg(jsonb_build_array(t.oid, t.tgrelid,
    pg_get_triggerdef(t.oid)) ORDER BY t.oid)
    FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname IN ('public', 'commercial_private')),
  'defaults', (SELECT jsonb_agg(to_jsonb(d) ORDER BY d.oid)
    FROM pg_default_acl d),
  'roles', (SELECT jsonb_agg(jsonb_build_array(r.oid, r.rolname,
    r.rolsuper, r.rolinherit, r.rolcreaterole, r.rolcreatedb,
    r.rolcanlogin, r.rolreplication, r.rolbypassrls, r.rolconfig)
    ORDER BY r.oid) FROM pg_roles r),
  'memberships', (SELECT jsonb_agg(to_jsonb(m) ORDER BY m.oid)
    FROM pg_auth_members m),
  'extensions', (SELECT jsonb_agg(to_jsonb(e) ORDER BY e.oid)
    FROM pg_extension e),
  'publications', (SELECT jsonb_agg(to_jsonb(p) ORDER BY p.oid)
    FROM pg_publication p),
  'publication_tables', (SELECT jsonb_agg(to_jsonb(p)
    ORDER BY p.pubname, p.schemaname, p.tablename)
    FROM pg_publication_tables p)
);
$body$;

CREATE TEMP TABLE harden1_data_snapshot AS
SELECT c.oid AS relation_id, n.nspname || '.' || c.relname AS relation_name,
  pg_temp.harden1_data_fingerprint(c.oid) AS fingerprint
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE (n.nspname IN ('public', 'commercial_private') AND c.relkind = 'r')
  OR (n.nspname = 'auth' AND c.relname = 'users' AND c.relkind = 'r');
CREATE TEMP TABLE harden1_metadata_snapshot AS
SELECT pg_temp.harden1_metadata_fingerprint() AS fingerprint;

-- Exact final ACL, independently declared: PostgreSQL 17 includes MAINTAIN.
SELECT results_eq(
  $$ SELECT CASE WHEN a.grantee = 0 THEN 'PUBLIC'
         ELSE pg_get_userbyid(a.grantee)::text END COLLATE "C",
       a.privilege_type COLLATE "C", pg_get_userbyid(a.grantor)::text COLLATE "C",
       a.is_grantable
     FROM pg_class c CROSS JOIN LATERAL
       aclexplode(coalesce(c.relacl, acldefault('r', c.relowner))) a
     WHERE c.oid = 'public.plans'::regclass ORDER BY 1, 2 $$,
  $$ SELECT role_name COLLATE "C", privilege COLLATE "C",
       'postgres'::text COLLATE "C", false
     FROM (VALUES ('postgres'::text), ('service_role'::text)) roles(role_name)
     CROSS JOIN (VALUES ('SELECT'::text), ('INSERT'), ('UPDATE'), ('DELETE'),
       ('TRUNCATE'), ('REFERENCES'), ('TRIGGER'), ('MAINTAIN')) rights(privilege)
     ORDER BY 1, 2 $$,
  'plans ACL is exactly the retained owner/server grants without grant options');
SELECT is((SELECT count(*)::integer FROM pg_class c
  CROSS JOIN LATERAL aclexplode(coalesce(c.relacl, acldefault('r', c.relowner))) a
  WHERE c.oid = 'public.plans'::regclass AND a.grantee = 0), 0,
  'PUBLIC OID 0 has no plans table privilege');
SELECT is((SELECT count(*)::integer FROM pg_attribute a
  WHERE a.attrelid = 'public.plans'::regclass AND a.attnum > 0
    AND NOT a.attisdropped AND a.attacl IS NOT NULL), 0,
  'no residual or newly introduced plans column ACL');
SELECT is((SELECT count(*)::integer FROM pg_attribute a
  CROSS JOIN LATERAL aclexplode(a.attacl) g
  WHERE a.attrelid = 'public.plans'::regclass AND a.attnum > 0
    AND NOT a.attisdropped AND g.grantee = 0), 0,
  'PUBLIC OID 0 has no plans column privilege');
SELECT ok(NOT has_table_privilege(r.oid, 'public.plans'::regclass, privilege),
  r.rolname || ' lacks effective plans ' || privilege)
FROM pg_roles r CROSS JOIN (VALUES ('SELECT'), ('INSERT'), ('UPDATE'),
  ('DELETE'), ('TRUNCATE'), ('REFERENCES'), ('TRIGGER'), ('MAINTAIN')) p(privilege)
WHERE r.rolname IN ('anon', 'authenticated') ORDER BY r.rolname, privilege;
SELECT ok(NOT has_any_column_privilege(r.oid, 'public.plans'::regclass, 'SELECT'),
  r.rolname || ' lacks effective SELECT on every plans column')
FROM pg_roles r WHERE r.rolname IN ('anon', 'authenticated') ORDER BY r.rolname;
SELECT ok(NOT has_column_privilege(r.oid, a.attrelid, a.attnum, privilege),
  r.rolname || ' lacks effective ' || a.attname || ' ' || privilege)
FROM pg_roles r CROSS JOIN pg_attribute a
CROSS JOIN (VALUES ('SELECT'), ('INSERT'), ('UPDATE'), ('REFERENCES')) p(privilege)
WHERE r.rolname IN ('anon', 'authenticated')
  AND a.attrelid = 'public.plans'::regclass AND a.attnum > 0
  AND NOT a.attisdropped ORDER BY r.rolname, a.attnum, privilege;
SELECT ok(NOT r.rolsuper AND NOT r.rolbypassrls,
  r.rolname || ' has no superuser or BYPASSRLS escape')
FROM pg_roles r WHERE r.rolname IN ('anon', 'authenticated') ORDER BY r.rolname;
SELECT ok(NOT pg_has_role(client.oid, trusted.oid, membership),
  client.rolname || ' has no ' || membership || ' path to ' || trusted.rolname)
FROM pg_roles client CROSS JOIN pg_roles trusted
CROSS JOIN (VALUES ('MEMBER'), ('USAGE'), ('SET')) paths(membership)
WHERE client.rolname IN ('anon', 'authenticated')
  AND trusted.rolname IN ('postgres', 'service_role', 'supabase_admin')
ORDER BY client.rolname, trusted.rolname, membership;
SELECT ok(has_table_privilege(r.oid, 'public.plans'::regclass, privilege),
  r.rolname || ' retains plans ' || privilege)
FROM pg_roles r CROSS JOIN (VALUES ('SELECT'), ('INSERT'), ('UPDATE'),
  ('DELETE'), ('TRUNCATE'), ('REFERENCES'), ('TRIGGER'), ('MAINTAIN')) p(privilege)
WHERE r.rolname IN ('postgres', 'service_role') ORDER BY r.rolname, privilege;
SELECT is((SELECT pg_get_userbyid(relowner)::text FROM pg_class
  WHERE oid = 'public.plans'::regclass), 'postgres', 'plans owner unchanged');
SELECT is((SELECT relkind::text FROM pg_class WHERE oid = 'public.plans'::regclass),
  'r', 'plans remains its existing ordinary table');
SELECT ok((SELECT relrowsecurity AND NOT relforcerowsecurity FROM pg_class
  WHERE oid = 'public.plans'::regclass), 'plans RLS enabled and not forced');
SELECT is((SELECT count(*)::integer FROM pg_policy
  WHERE polrelid = 'public.plans'::regclass AND polname = 'plans_select_all'), 0,
  'exact legacy permissive policy is absent');
SELECT is((SELECT count(*)::integer FROM pg_policy
  WHERE polrelid = 'public.plans'::regclass), 0,
  'no replacement plans policy exists for any role or command');

SELECT results_eq(
  $$ SELECT a.attname::text COLLATE "C", format_type(a.atttypid, a.atttypmod) COLLATE "C",
       a.attnotnull, pg_get_expr(d.adbin, d.adrelid) COLLATE "C"
     FROM pg_attribute a LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid
       AND d.adnum = a.attnum
     WHERE a.attrelid = 'public.plans'::regclass AND a.attnum > 0
       AND NOT a.attisdropped ORDER BY a.attnum $$,
  $$ SELECT column_name COLLATE "C", type_name COLLATE "C", required, default_expression COLLATE "C"
     FROM (VALUES
       (1, 'id'::text, 'uuid'::text, true, 'gen_random_uuid()'::text),
       (2, 'code', 'text', true, NULL), (3, 'name', 'text', true, NULL),
       (4, 'description', 'text', false, NULL),
       (5, 'is_active', 'boolean', true, 'true'),
       (6, 'created_at', 'timestamp with time zone', true, 'now()'),
       (7, 'updated_at', 'timestamp with time zone', true, 'now()'))
       expected(position, column_name, type_name, required, default_expression)
     ORDER BY position $$,
  'all seven plans columns, types, defaults and nullability unchanged');
SELECT results_eq(
  $$ SELECT conname::text COLLATE "C", contype::text COLLATE "C",
       pg_get_constraintdef(oid) COLLATE "C"
     FROM pg_constraint WHERE conrelid = 'public.plans'::regclass ORDER BY 1 $$,
  $$ SELECT name COLLATE "C", kind COLLATE "C", definition COLLATE "C"
     FROM (VALUES ('plans_code_key'::text, 'u'::text, 'UNIQUE (code)'::text),
       ('plans_pkey', 'p', 'PRIMARY KEY (id)')) expected(name, kind, definition)
     ORDER BY 1 $$,
  'original plans identity constraints unchanged');
SELECT is((SELECT count(*)::integer FROM pg_trigger
  WHERE tgrelid = 'public.plans'::regclass AND NOT tgisinternal
    AND tgname = 'trigger_set_updated_at' AND tgtype = 19
    AND tgfoid = 'public.set_updated_at()'::regprocedure), 1,
  'original BEFORE UPDATE row trigger unchanged');
SELECT is((SELECT count(*)::integer FROM pg_trigger
  WHERE tgrelid = 'public.plans'::regclass AND NOT tgisinternal), 1,
  'no new user trigger on plans');

-- FK definitions are checked structurally, avoiding search_path-dependent text.
SELECT results_eq(
  $$ SELECT (sn.nspname::text || '.' || source.relname::text) COLLATE "C",
       k.conname::text COLLATE "C",
       ARRAY(SELECT a.attname::text FROM unnest(k.conkey) WITH ORDINALITY key(attnum, ord)
         JOIN pg_attribute a ON a.attrelid = k.conrelid AND a.attnum = key.attnum
         ORDER BY key.ord) COLLATE "C",
       (tn.nspname::text || '.' || target.relname::text) COLLATE "C",
       ARRAY(SELECT a.attname::text FROM unnest(k.confkey) WITH ORDINALITY key(attnum, ord)
         JOIN pg_attribute a ON a.attrelid = k.confrelid AND a.attnum = key.attnum
         ORDER BY key.ord) COLLATE "C",
       k.confupdtype::text COLLATE "C", k.confdeltype::text COLLATE "C", k.confmatchtype::text COLLATE "C",
       k.convalidated, k.condeferrable, k.condeferred
     FROM pg_constraint k JOIN pg_class source ON source.oid = k.conrelid
     JOIN pg_namespace sn ON sn.oid = source.relnamespace
     JOIN pg_class target ON target.oid = k.confrelid
     JOIN pg_namespace tn ON tn.oid = target.relnamespace
     WHERE k.contype = 'f' AND k.confrelid = 'public.plans'::regclass ORDER BY 1, 2 $$,
  $$ SELECT * FROM (VALUES
       ('commercial_private.plan_versions'::text COLLATE "C", 'fk_plan_versions_plan_id'::text COLLATE "C",
         ARRAY['plan_id']::text[] COLLATE "C", 'public.plans'::text COLLATE "C", ARRAY['id']::text[] COLLATE "C",
         'r'::text COLLATE "C", 'r'::text COLLATE "C", 's'::text COLLATE "C", true, false, false),
       ('public.subscriptions', 'subscriptions_plan_id_fkey',
         ARRAY['plan_id'], 'public.plans', ARRAY['id'],
         'a', 'r', 's', true, false, false)) expected
     ORDER BY 1, 2 $$,
  'exact two inbound plan FKs retain columns, targets, actions and validation');
SELECT is((SELECT format_type(atttypid, atttypmod) FROM pg_attribute
  WHERE attrelid = 'public.subscriptions'::regclass AND attname = 'price_paid'),
  'numeric(12,2)', 'legacy amount is untouched; conversion remains M4');

SELECT is((SELECT count(*)::integer FROM pg_publication_tables
  WHERE schemaname = 'public' AND tablename = 'plans'), 0,
  'no plans Realtime publication exposure');
SELECT is((SELECT count(*)::integer FROM pg_proc p JOIN pg_namespace n
  ON n.oid = p.pronamespace WHERE n.nspname IN ('public', 'commercial_private')
    AND p.prosrc ~* '(^|[^a-z_0-9])plans([^a-z_0-9]|$)'), 0,
  'no public/private persistent routine body is a raw plans reader/proxy');
SELECT is((WITH RECURSIVE dependents(relation_id) AS (
  SELECT 'public.plans'::regclass::oid
  UNION
  SELECT rw.ev_class FROM dependents parent JOIN pg_depend d
    ON d.refclassid = 'pg_class'::regclass AND d.refobjid = parent.relation_id
    AND d.classid = 'pg_rewrite'::regclass
  JOIN pg_rewrite rw ON rw.oid = d.objid
)
SELECT count(*)::integer FROM dependents d JOIN pg_class c ON c.oid = d.relation_id
WHERE c.relkind IN ('v', 'm')), 0, 'no direct or chained view reads raw plans');

-- M1a's independent gate exercises fresh-object defaults and all 34 constraints.
-- These final-state checks ensure HARDEN-1 has retained the private boundary.
SELECT results_eq(
  $$ SELECT c.relname::text COLLATE "C" FROM pg_class c
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'commercial_private' AND c.relkind = 'r' ORDER BY 1 $$,
  $$ SELECT name COLLATE "C" FROM (VALUES ('bundle_items'::text),
     ('entitlement_bundles'), ('plan_versions'), ('term_prices')) expected(name)
     ORDER BY 1 $$, 'exact four private foundation tables remain');
SELECT ok(c.relrowsecurity AND NOT c.relforcerowsecurity
  AND pg_get_userbyid(c.relowner) = 'postgres',
  c.relname || ' retains creator ownership and defensive unforced RLS')
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'commercial_private' AND c.relkind = 'r' ORDER BY c.relname;
SELECT is((SELECT count(*)::integer FROM pg_policy p JOIN pg_class c
  ON c.oid = p.polrelid JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'commercial_private'), 0, 'private policy inventory remains empty');
SELECT is((SELECT pg_get_userbyid(nspowner)::text FROM pg_namespace
  WHERE nspname = 'commercial_private'), 'postgres', 'private namespace owner unchanged');
SELECT is((SELECT count(*)::integer FROM pg_namespace n CROSS JOIN LATERAL
  aclexplode(coalesce(n.nspacl, acldefault('n', n.nspowner))) a
  WHERE n.nspname = 'commercial_private' AND a.grantee <> n.nspowner), 0,
  'private schema has no PUBLIC/client/server or other nonowner grant');
SELECT is((SELECT count(*)::integer FROM pg_class c JOIN pg_namespace n
  ON n.oid = c.relnamespace CROSS JOIN LATERAL
  aclexplode(coalesce(c.relacl, acldefault('r', c.relowner))) a
  WHERE n.nspname = 'commercial_private' AND c.relkind = 'r'
    AND a.grantee <> c.relowner), 0, 'private tables have no nonowner ACL');
SELECT is((SELECT count(*)::integer FROM pg_attribute a JOIN pg_class c
  ON c.oid = a.attrelid JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'commercial_private' AND a.attnum > 0
    AND NOT a.attisdropped AND a.attacl IS NOT NULL), 0,
  'private table columns have no separately granted privilege');
SELECT ok(NOT has_schema_privilege(r.oid, n.oid, privilege),
  r.rolname || ' retains private schema ' || privilege || ' denial')
FROM pg_roles r CROSS JOIN pg_namespace n
CROSS JOIN (VALUES ('USAGE'), ('CREATE')) p(privilege)
WHERE r.rolname IN ('anon', 'authenticated', 'service_role')
  AND n.nspname = 'commercial_private' ORDER BY r.rolname, privilege;
SELECT ok(NOT has_table_privilege(r.oid, c.oid, privilege),
  r.rolname || ' retains ' || c.relname || ' ' || privilege || ' denial')
FROM pg_roles r CROSS JOIN pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
CROSS JOIN (VALUES ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'), ('TRUNCATE'),
  ('REFERENCES'), ('TRIGGER'), ('MAINTAIN')) p(privilege)
WHERE r.rolname IN ('anon', 'authenticated', 'service_role')
  AND n.nspname = 'commercial_private' AND c.relkind = 'r'
ORDER BY r.rolname, c.relname, privilege;
SELECT is((SELECT count(*)::integer FROM pg_roles r
  LEFT JOIN pg_default_acl d ON d.defaclrole = r.oid AND d.defaclnamespace = 0
    AND d.defaclobjtype = kind.object_class
  CROSS JOIN LATERAL aclexplode(coalesce(d.defaclacl,
    acldefault(kind.object_class, r.oid))) a
  WHERE r.rolname = 'postgres' AND a.grantee <> r.oid), 0,
  'creator global ' || kind.description || ' default remains owner-only')
FROM (VALUES ('r'::"char", 'TABLES'::text), ('S'::"char", 'SEQUENCES'),
  ('f'::"char", 'FUNCTIONS/ROUTINES'), ('T'::"char", 'TYPES')) kind(object_class, description);
SELECT is((SELECT count(*)::integer FROM pg_default_acl d JOIN pg_namespace n
  ON n.oid = d.defaclnamespace CROSS JOIN LATERAL aclexplode(d.defaclacl) a
  WHERE d.defaclrole = 'postgres'::regrole AND n.nspname = 'commercial_private'
    AND a.grantee <> d.defaclrole), 0,
  'private-schema additions do not restore nonowner default privileges');
SELECT is((SELECT count(*)::integer FROM pg_proc p JOIN pg_namespace n
  ON n.oid = p.pronamespace WHERE n.nspname = 'commercial_private'), 0,
  'no persistent commercial routine');
SELECT is((SELECT count(*)::integer FROM pg_trigger t JOIN pg_class c
  ON c.oid = t.tgrelid JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'commercial_private' AND NOT t.tgisinternal), 0,
  'no private user trigger');
SELECT is((SELECT count(*)::integer FROM pg_class c JOIN pg_namespace n
  ON n.oid = c.relnamespace WHERE n.nspname = 'commercial_private'
    AND c.relkind NOT IN ('r', 'i')), 0, 'no extra private relation or projection');
SELECT is((SELECT count(*)::integer FROM pg_publication_tables
  WHERE schemaname = 'commercial_private'), 0, 'private tables remain outside Realtime');
SELECT is((SELECT count(*)::integer FROM pg_publication WHERE puballtables), 0,
  'no blanket all-table Realtime publication');

-- The accepted disposable clean chain has zero catalog/subscription rows.
-- This does not assert emptiness of an unknown deployed environment.
SELECT is((SELECT count(*)::integer FROM public.plans), 0, 'no production plan seed');
SELECT is((SELECT count(*)::integer FROM public.subscriptions), 0,
  'no production subscription or entity-to-plan assignment');
SELECT is((SELECT count(*)::integer FROM public.plans
  WHERE lower(btrim(code)) IN ('business', 'business_pro', 'business_plus', 'corporate')), 0,
  'no canonical M1b commercial identity is present');
SELECT is((SELECT count(*)::integer FROM commercial_private.entitlement_bundles), 0,
  'no production bundle seed');
SELECT is((SELECT count(*)::integer FROM commercial_private.bundle_items), 0,
  'no production bundle-item seed');
SELECT is((SELECT count(*)::integer FROM commercial_private.plan_versions), 0,
  'no production plan-version seed');
SELECT is((SELECT count(*)::integer FROM commercial_private.term_prices), 0,
  'no production retail price seed');

-- Independent, noncanonical identities: never the 40 M1b reserved UUIDs/codes.
INSERT INTO auth.users (id, email, created_at, updated_at) VALUES
  ('a11e1000-0000-4000-8000-000000000001', 'harden1-ordinary@example.invalid', now(), now()),
  ('a11e1000-0000-4000-8000-000000000002', 'harden1-business@example.invalid', now(), now()),
  ('a11e1000-0000-4000-8000-000000000003', 'harden1-staff@example.invalid', now(), now());
INSERT INTO public.profiles (user_id, display_name) VALUES
  ('a11e1000-0000-4000-8000-000000000001', 'HARDEN-1 ordinary fixture'),
  ('a11e1000-0000-4000-8000-000000000002', 'HARDEN-1 business fixture'),
  ('a11e1000-0000-4000-8000-000000000003', 'HARDEN-1 staff fixture');
INSERT INTO public.directory_entities (id, entity_type, name, lifecycle_status) VALUES
  ('a11e2000-0000-4000-8000-000000000001', 'company', 'HARDEN-1 active fixture', 'active'),
  ('a11e2000-0000-4000-8000-000000000002', 'company', 'HARDEN-1 draft fixture', 'draft');
INSERT INTO public.business_memberships (user_id, entity_id, role) VALUES
  ('a11e1000-0000-4000-8000-000000000002', 'a11e2000-0000-4000-8000-000000000001', 'OWNER');
INSERT INTO public.staff_memberships (user_id, role_id)
SELECT 'a11e1000-0000-4000-8000-000000000003', id
FROM public.roles WHERE code = 'application_reviewer';
SELECT is((SELECT count(*)::integer FROM public.business_memberships
  WHERE user_id = 'a11e1000-0000-4000-8000-000000000002' AND role = 'OWNER'), 1,
  'business actor has a real accepted OWNER membership');
SELECT is((SELECT count(*)::integer FROM public.staff_memberships
  WHERE user_id = 'a11e1000-0000-4000-8000-000000000003'), 1,
  'staff actor has a real accepted staff membership');
INSERT INTO public.entity_contacts (id, entity_id, contact_type, value) VALUES
  ('a11e3000-0000-4000-8000-000000000001', 'a11e2000-0000-4000-8000-000000000001', 'email', 'harden1-active@example.invalid'),
  ('a11e3000-0000-4000-8000-000000000002', 'a11e2000-0000-4000-8000-000000000002', 'email', 'harden1-draft@example.invalid');
INSERT INTO public.plans (id, code, name, is_active) VALUES
  ('a11e4000-0000-4000-8000-000000000001', 'harden1_subscription_fixture', 'HARDEN-1 legacy reference fixture', true),
  ('a11e4000-0000-4000-8000-000000000002', 'harden1_version_fixture', 'HARDEN-1 private reference fixture', false);
INSERT INTO public.subscriptions (id, entity_id, plan_id, started_at) VALUES
  ('a11e5000-0000-4000-8000-000000000001', 'a11e2000-0000-4000-8000-000000000001',
   'a11e4000-0000-4000-8000-000000000001', '2026-01-01 00:00:00+00');
INSERT INTO commercial_private.entitlement_bundles (id, code, version, registry_version) VALUES
  ('a11e6000-0000-4000-8000-000000000001', 'harden1_fk_fixture', 1, 1);
INSERT INTO commercial_private.plan_versions
  (id, plan_id, version, bundle_version_id, pricing_mode, name_ar) VALUES
  ('a11e7000-0000-4000-8000-000000000001', 'a11e4000-0000-4000-8000-000000000002',
   1, 'a11e6000-0000-4000-8000-000000000001', 'retail', 'HARDEN-1 synthetic FK fixture');

-- Actual SELECT errors with populated active/inactive plans, not empty RLS sets.
SELECT is(pg_temp.harden1_result(statement, role_name::name), '42501|',
  role_name || ' raw plans ' || description || ' raises permission denial')
FROM (VALUES ('anon'), ('authenticated')) roles(role_name)
CROSS JOIN (VALUES ('SELECT * FROM public.plans', 'all columns'),
  ('SELECT id, code, name FROM public.plans', 'bounded fields'),
  ('SELECT count(*) FROM public.plans', 'count'),
  ('SELECT id FROM public.plans WHERE NOT is_active', 'inactive identity')) probes(statement, description)
ORDER BY role_name, description;
SELECT is(pg_temp.harden1_result('SELECT id, code, name FROM public.plans',
  'authenticated', actor.id), '42501|', actor.description || ' cannot read raw plans')
FROM (VALUES ('a11e1000-0000-4000-8000-000000000001', 'ordinary authenticated'),
  ('a11e1000-0000-4000-8000-000000000002', 'business OWNER'),
  ('a11e1000-0000-4000-8000-000000000003', 'provisioned staff')) actor(id, description)
ORDER BY actor.description;
SELECT is(pg_temp.harden1_read($$ SELECT count(*)::text FROM public.plans
  WHERE id IN ('a11e4000-0000-4000-8000-000000000001',
    'a11e4000-0000-4000-8000-000000000002') $$, role_name::name), '2',
  role_name || ' retains trusted reads of active and inactive plan identities')
FROM (VALUES ('postgres'), ('service_role')) roles(role_name);

SELECT is((SELECT count(*)::integer FROM public.subscriptions s JOIN public.plans p
  ON p.id = s.plan_id WHERE s.id = 'a11e5000-0000-4000-8000-000000000001'), 1,
  'owner successfully created and joined the retained legacy plan FK');
SELECT is((SELECT count(*)::integer FROM commercial_private.plan_versions v
  JOIN public.plans p ON p.id = v.plan_id
  WHERE v.id = 'a11e7000-0000-4000-8000-000000000001'), 1,
  'owner successfully created and joined the retained private plan FK');
SELECT is(pg_temp.harden1_result($$ INSERT INTO public.subscriptions
  (id, entity_id, plan_id, started_at) VALUES
  ('a11e5000-0000-4000-8000-000000000002', 'a11e2000-0000-4000-8000-000000000001',
   'a11e4000-0000-4000-8000-000000000001', '2026-01-01 00:00:00+00') $$,
  'service_role'), 'NO_ERROR', 'trusted server can still create a valid legacy reference');
SELECT is(pg_temp.harden1_result($$ INSERT INTO commercial_private.plan_versions
  (id, plan_id, version, bundle_version_id, pricing_mode, name_ar) VALUES
  ('a11e7000-0000-4000-8000-000000000002', 'a11e4000-0000-4000-8000-000000000002',
   2, 'a11e6000-0000-4000-8000-000000000001', 'retail', 'HARDEN-1 valid owner fixture') $$),
  'NO_ERROR', 'owner can still create another valid private plan reference');
SELECT is(pg_temp.harden1_result(statement), expected, description)
FROM (VALUES
  ($$ UPDATE public.subscriptions SET plan_id = 'a11effff-0000-4000-8000-000000000001'
       WHERE id = 'a11e5000-0000-4000-8000-000000000001' $$,
   '23503|subscriptions_plan_id_fkey', 'legacy FK rejects an orphan plan'),
  ($$ DELETE FROM public.plans WHERE id = 'a11e4000-0000-4000-8000-000000000001' $$,
   '23503|subscriptions_plan_id_fkey', 'legacy FK restricts parent deletion'),
  ($$ UPDATE public.plans SET id = 'a11effff-0000-4000-8000-000000000001'
       WHERE id = 'a11e4000-0000-4000-8000-000000000001' $$,
   '23503|subscriptions_plan_id_fkey', 'legacy FK rejects referenced ID rewriting'),
  ($$ UPDATE commercial_private.plan_versions SET plan_id = 'a11effff-0000-4000-8000-000000000002'
       WHERE id = 'a11e7000-0000-4000-8000-000000000001' $$,
   '23503|fk_plan_versions_plan_id', 'private FK rejects an orphan plan'),
  ($$ DELETE FROM public.plans WHERE id = 'a11e4000-0000-4000-8000-000000000002' $$,
   '23503|fk_plan_versions_plan_id', 'private FK restricts parent deletion'),
  ($$ UPDATE public.plans SET id = 'a11effff-0000-4000-8000-000000000002'
       WHERE id = 'a11e4000-0000-4000-8000-000000000002' $$,
   '23503|fk_plan_versions_plan_id', 'private FK restricts referenced ID rewriting'))
  probes(statement, expected, description) ORDER BY description;

SELECT is(pg_temp.harden1_result('SELECT * FROM commercial_private.plan_versions',
  role_name::name), '42501|', role_name || ' still cannot read private version metadata')
FROM (VALUES ('anon'), ('authenticated'), ('service_role')) roles(role_name);
SELECT is(pg_temp.harden1_read($$ SELECT count(*)::text FROM public.directory_entities
  WHERE id IN ('a11e2000-0000-4000-8000-000000000001',
    'a11e2000-0000-4000-8000-000000000002') $$, role_name::name), '1',
  role_name || ' Directory public read retains active-only filtering')
FROM (VALUES ('anon'), ('authenticated')) roles(role_name);
SELECT is(pg_temp.harden1_read($$ SELECT count(*)::text FROM public.entity_contacts
  WHERE id IN ('a11e3000-0000-4000-8000-000000000001',
    'a11e3000-0000-4000-8000-000000000002') $$, role_name::name), '1',
  role_name || ' Directory child retains active-parent filtering')
FROM (VALUES ('anon'), ('authenticated')) roles(role_name);
SELECT is(pg_temp.harden1_result($$ UPDATE public.directory_entities SET name = 'denied'
  WHERE id = 'a11e2000-0000-4000-8000-000000000001' $$, role_name::name), '42501|',
  role_name || ' Directory mutation is still denied')
FROM (VALUES ('anon'), ('authenticated')) roles(role_name);
SELECT is(pg_temp.harden1_result('SELECT * FROM public.subscriptions', role_name::name),
  '42501|', role_name || ' subscriptions remain unavailable to ordinary clients')
FROM (VALUES ('anon'), ('authenticated')) roles(role_name);
SELECT is(current_user::text, 'postgres', 'all client attempts restored the owner');

-- Delete only this test's fixed noncanonical rows, then independently compare
-- every public/private table plus auth.users with its entry fingerprint.
DELETE FROM commercial_private.plan_versions
WHERE id = 'a11e7000-0000-4000-8000-000000000001';
DELETE FROM commercial_private.entitlement_bundles
WHERE id = 'a11e6000-0000-4000-8000-000000000001';
DELETE FROM public.subscriptions WHERE id = 'a11e5000-0000-4000-8000-000000000001';
DELETE FROM public.plans WHERE id IN
  ('a11e4000-0000-4000-8000-000000000001', 'a11e4000-0000-4000-8000-000000000002');
DELETE FROM public.entity_contacts WHERE id IN
  ('a11e3000-0000-4000-8000-000000000001', 'a11e3000-0000-4000-8000-000000000002');
DELETE FROM public.business_memberships
WHERE user_id = 'a11e1000-0000-4000-8000-000000000002'
  AND entity_id = 'a11e2000-0000-4000-8000-000000000001';
DELETE FROM public.directory_entities WHERE id IN
  ('a11e2000-0000-4000-8000-000000000001', 'a11e2000-0000-4000-8000-000000000002');
DELETE FROM public.staff_memberships WHERE user_id = 'a11e1000-0000-4000-8000-000000000003';
DELETE FROM public.profiles WHERE user_id IN
  ('a11e1000-0000-4000-8000-000000000001', 'a11e1000-0000-4000-8000-000000000002',
   'a11e1000-0000-4000-8000-000000000003');
DELETE FROM auth.users WHERE id IN
  ('a11e1000-0000-4000-8000-000000000001', 'a11e1000-0000-4000-8000-000000000002',
   'a11e1000-0000-4000-8000-000000000003');

SELECT is(pg_temp.harden1_data_fingerprint(relation_id), fingerprint,
  relation_name || ' original rows are byte-equivalent after fixture cleanup')
FROM harden1_data_snapshot ORDER BY relation_name;
SELECT is(pg_temp.harden1_metadata_fingerprint()::text, fingerprint::text,
  'all captured schema/ACL/default/policy/RPC/FK/role/extension metadata preserved by probes')
FROM harden1_metadata_snapshot;
SELECT is((SELECT count(*)::integer FROM public.plans), 0,
  'fixture cleanup leaves zero public plan rows');
SELECT is((SELECT count(*)::integer FROM public.subscriptions), 0,
  'fixture cleanup leaves zero legacy subscription rows');
SELECT is((SELECT count(*)::integer FROM commercial_private.entitlement_bundles), 0,
  'fixture cleanup leaves zero bundles');
SELECT is((SELECT count(*)::integer FROM commercial_private.bundle_items), 0,
  'fixture cleanup leaves zero bundle items');
SELECT is((SELECT count(*)::integer FROM commercial_private.plan_versions), 0,
  'fixture cleanup leaves zero private versions');
SELECT is((SELECT count(*)::integer FROM commercial_private.term_prices), 0,
  'fixture cleanup leaves zero term prices');

SELECT * FROM finish();
ROLLBACK;
