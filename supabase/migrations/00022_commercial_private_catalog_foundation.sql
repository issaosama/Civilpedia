-- M1a: empty, private commercial catalog/version foundation only.
-- Accepted authority: CIVILPEDIA_COMMERCIAL_M1A_PRIVATE_CATALOG_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.
-- Live local CLI 2.116.0 preflight verified PostgreSQL 17, session/current user
-- postgres, role none, CREATE/REFERENCES authority and no client inheritance.
-- The actual migration runner's failure probe proved per-file atomicity.
-- All statements must remain in that runner-owned transaction; no consumers,
-- production data, persistent routines, user triggers or publication authority.

DO $preflight$
DECLARE
  creator_oid oid := current_user::pg_catalog.regrole;
BEGIN
  IF current_user <> 'postgres' OR session_user <> 'postgres'
     OR pg_catalog.current_setting('role') <> 'none'
     OR pg_catalog.current_setting('server_version_num')::integer / 10000 <> 17
     OR NOT pg_catalog.has_database_privilege(current_user, pg_catalog.current_database(), 'CREATE')
     OR NOT pg_catalog.has_schema_privilege(current_user, 'public', 'USAGE')
     OR NOT pg_catalog.has_table_privilege(current_user, 'public.plans', 'REFERENCES') THEN
    RAISE EXCEPTION 'M1a creator/execution context differs from verified preflight';
  END IF;
  IF pg_catalog.to_regnamespace('commercial_private') IS NOT NULL THEN
    RAISE EXCEPTION 'M1a private schema already exists; no adoption or retry is permitted';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_roles
      WHERE rolname IN ('anon', 'authenticated', 'service_role')) <> 3
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_roles
                WHERE rolname IN ('anon', 'authenticated', 'service_role')
                  AND (rolsuper OR pg_catalog.pg_has_role(oid, creator_oid, 'MEMBER'))) THEN
    RAISE EXCEPTION 'M1a client role/creator membership preflight failed';
  END IF;
  -- An unreviewed global grantee could flow into the new private namespace.
  -- Only the explicitly accepted grantees may be neutralized by this slice.
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_default_acl d
    CROSS JOIN LATERAL pg_catalog.aclexplode(d.defaclacl) a
    WHERE d.defaclrole = creator_oid AND d.defaclnamespace = 0
      AND a.grantee <> creator_oid AND a.grantee <> 0
      AND a.grantee NOT IN (SELECT oid FROM pg_catalog.pg_roles
                            WHERE rolname IN ('anon', 'authenticated', 'service_role'))
  ) THEN
    RAISE EXCEPTION 'M1a unexpected creator-global default grantee; Architect review required';
  END IF;
END;
$preflight$;

-- Global defaults apply to this creator's FUTURE objects throughout the DB.
-- Existing object ACLs and IN SCHEMA public/storage additions are untouched.
DO $global_defaults$
DECLARE creator name := current_user;
BEGIN
  EXECUTE pg_catalog.format('ALTER DEFAULT PRIVILEGES FOR ROLE %I REVOKE ALL ON TABLES FROM PUBLIC, anon, authenticated, service_role', creator);
  EXECUTE pg_catalog.format('ALTER DEFAULT PRIVILEGES FOR ROLE %I REVOKE ALL ON SEQUENCES FROM PUBLIC, anon, authenticated, service_role', creator);
  EXECUTE pg_catalog.format('ALTER DEFAULT PRIVILEGES FOR ROLE %I REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon, authenticated, service_role', creator);
  EXECUTE pg_catalog.format('ALTER DEFAULT PRIVILEGES FOR ROLE %I REVOKE USAGE ON TYPES FROM PUBLIC, anon, authenticated, service_role', creator);
END;
$global_defaults$;

CREATE SCHEMA commercial_private;
REVOKE ALL ON SCHEMA commercial_private FROM PUBLIC, anon, authenticated, service_role;

-- Schema-specific defaults are ADDITIONS, not replacements for global ACLs.
DO $private_defaults$
DECLARE creator name := current_user;
BEGIN
  EXECUTE pg_catalog.format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA commercial_private REVOKE ALL ON TABLES FROM PUBLIC, anon, authenticated, service_role', creator);
  EXECUTE pg_catalog.format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA commercial_private REVOKE ALL ON SEQUENCES FROM PUBLIC, anon, authenticated, service_role', creator);
  EXECUTE pg_catalog.format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA commercial_private REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon, authenticated, service_role', creator);
  EXECUTE pg_catalog.format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA commercial_private REVOKE USAGE ON TYPES FROM PUBLIC, anon, authenticated, service_role', creator);
END;
$private_defaults$;

CREATE TABLE commercial_private.entitlement_bundles (
  id uuid NOT NULL DEFAULT pg_catalog.gen_random_uuid(),
  code text NOT NULL,
  version integer NOT NULL,
  registry_version integer NOT NULL,
  status text NOT NULL DEFAULT 'draft',
  published_at timestamptz,
  retired_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CONSTRAINT entitlement_bundles_pkey PRIMARY KEY (id),
  CONSTRAINT uq_entitlement_bundles_code_version UNIQUE (code, version),
  CONSTRAINT chk_entitlement_bundles_code CHECK (
    pg_catalog.char_length(code) BETWEEN 1 AND 64 AND code ~ '^[a-z][a-z0-9_]*$'
  ),
  CONSTRAINT chk_entitlement_bundles_version CHECK (version > 0),
  CONSTRAINT chk_entitlement_bundles_registry_version CHECK (registry_version > 0),
  CONSTRAINT chk_entitlement_bundles_lifecycle CHECK (
    (published_at IS NULL OR pg_catalog.isfinite(published_at))
    AND (retired_at IS NULL OR pg_catalog.isfinite(retired_at))
    AND (
      (status = 'draft' AND published_at IS NULL AND retired_at IS NULL)
      OR (status = 'published' AND published_at IS NOT NULL AND retired_at IS NULL)
      OR (status = 'retired' AND published_at IS NOT NULL AND retired_at IS NOT NULL
          AND retired_at >= published_at)
    )
  )
);

CREATE TABLE commercial_private.bundle_items (
  id uuid NOT NULL DEFAULT pg_catalog.gen_random_uuid(),
  bundle_version_id uuid NOT NULL,
  capability_key text NOT NULL,
  value_kind text NOT NULL,
  value_boolean boolean,
  value_integer bigint,
  value_text text,
  is_required boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CONSTRAINT bundle_items_pkey PRIMARY KEY (id),
  CONSTRAINT fk_bundle_items_bundle_version_id FOREIGN KEY (bundle_version_id)
    REFERENCES commercial_private.entitlement_bundles (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT uq_bundle_items_bundle_key UNIQUE (bundle_version_id, capability_key),
  CONSTRAINT chk_bundle_items_capability_key CHECK (
    pg_catalog.char_length(capability_key) BETWEEN 1 AND 128
    AND capability_key ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$'
  ),
  CONSTRAINT chk_bundle_items_typed_value CHECK (
    (value_kind = 'boolean' AND value_boolean IS NOT NULL AND value_integer IS NULL AND value_text IS NULL)
    OR (value_kind = 'integer' AND value_integer IS NOT NULL AND value_boolean IS NULL AND value_text IS NULL)
    OR (value_kind = 'text' AND value_text IS NOT NULL AND value_boolean IS NULL AND value_integer IS NULL)
  ),
  CONSTRAINT chk_bundle_items_integer_value CHECK (value_integer IS NULL OR value_integer >= 0),
  CONSTRAINT chk_bundle_items_text_value CHECK (
    value_text IS NULL OR (pg_catalog.btrim(value_text) <> '' AND pg_catalog.char_length(value_text) <= 256)
  )
);

CREATE TABLE commercial_private.plan_versions (
  id uuid NOT NULL DEFAULT pg_catalog.gen_random_uuid(),
  plan_id uuid NOT NULL,
  version integer NOT NULL,
  bundle_version_id uuid NOT NULL,
  pricing_mode text NOT NULL,
  name_ar text NOT NULL,
  description_ar text,
  sort_order integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'draft',
  published_at timestamptz,
  retired_at timestamptz,
  effective_from timestamptz,
  effective_until timestamptz,
  created_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CONSTRAINT plan_versions_pkey PRIMARY KEY (id),
  CONSTRAINT fk_plan_versions_plan_id FOREIGN KEY (plan_id)
    REFERENCES public.plans (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_plan_versions_bundle_version_id FOREIGN KEY (bundle_version_id)
    REFERENCES commercial_private.entitlement_bundles (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT uq_plan_versions_plan_version UNIQUE (plan_id, version),
  CONSTRAINT uq_plan_versions_id_pricing_mode UNIQUE (id, pricing_mode),
  CONSTRAINT chk_plan_versions_version CHECK (version > 0),
  CONSTRAINT chk_plan_versions_pricing_mode CHECK (pricing_mode IN ('retail', 'custom_quote')),
  CONSTRAINT chk_plan_versions_metadata CHECK (
    pg_catalog.btrim(name_ar) <> '' AND (description_ar IS NULL OR pg_catalog.btrim(description_ar) <> '')
  ),
  CONSTRAINT chk_plan_versions_sort_order CHECK (sort_order >= 0),
  CONSTRAINT chk_plan_versions_lifecycle CHECK (
    (published_at IS NULL OR pg_catalog.isfinite(published_at))
    AND (retired_at IS NULL OR pg_catalog.isfinite(retired_at))
    AND (
      (status = 'draft' AND published_at IS NULL AND retired_at IS NULL)
      OR (status = 'published' AND published_at IS NOT NULL AND retired_at IS NULL)
      OR (status = 'retired' AND published_at IS NOT NULL AND retired_at IS NOT NULL
          AND retired_at >= published_at)
    )
  ),
  CONSTRAINT chk_plan_versions_effective_window CHECK (
    (effective_from IS NULL OR pg_catalog.isfinite(effective_from))
    AND (effective_until IS NULL OR pg_catalog.isfinite(effective_until))
    AND (effective_until IS NULL OR (effective_from IS NOT NULL AND effective_until > effective_from))
    AND (status = 'draft' OR effective_from IS NOT NULL)
  )
);

CREATE TABLE commercial_private.term_prices (
  id uuid NOT NULL DEFAULT pg_catalog.gen_random_uuid(),
  plan_version_id uuid NOT NULL,
  pricing_mode text NOT NULL DEFAULT 'retail',
  version integer NOT NULL,
  duration_months integer NOT NULL,
  amount_iqd bigint NOT NULL,
  currency text NOT NULL DEFAULT 'IQD',
  status text NOT NULL DEFAULT 'draft',
  published_at timestamptz,
  retired_at timestamptz,
  effective_from timestamptz,
  effective_until timestamptz,
  created_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CONSTRAINT term_prices_pkey PRIMARY KEY (id),
  CONSTRAINT fk_term_prices_plan_version_pricing_mode FOREIGN KEY (plan_version_id, pricing_mode)
    REFERENCES commercial_private.plan_versions (id, pricing_mode) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT uq_term_prices_plan_duration_version UNIQUE (plan_version_id, duration_months, version),
  CONSTRAINT chk_term_prices_version CHECK (version > 0),
  CONSTRAINT chk_term_prices_pricing_mode CHECK (pricing_mode = 'retail'),
  CONSTRAINT chk_term_prices_duration_months CHECK (duration_months IN (1, 3, 12)),
  CONSTRAINT chk_term_prices_amount_iqd CHECK (amount_iqd >= 0),
  CONSTRAINT chk_term_prices_currency CHECK (currency = 'IQD'),
  CONSTRAINT chk_term_prices_lifecycle CHECK (
    (published_at IS NULL OR pg_catalog.isfinite(published_at))
    AND (retired_at IS NULL OR pg_catalog.isfinite(retired_at))
    AND (
      (status = 'draft' AND published_at IS NULL AND retired_at IS NULL)
      OR (status = 'published' AND published_at IS NOT NULL AND retired_at IS NULL)
      OR (status = 'retired' AND published_at IS NOT NULL AND retired_at IS NOT NULL
          AND retired_at >= published_at)
    )
  ),
  CONSTRAINT chk_term_prices_effective_window CHECK (
    (effective_from IS NULL OR pg_catalog.isfinite(effective_from))
    AND (effective_until IS NULL OR pg_catalog.isfinite(effective_until))
    AND (effective_until IS NULL OR (effective_from IS NOT NULL AND effective_until > effective_from))
    AND (status = 'draft' OR effective_from IS NOT NULL)
  )
);

ALTER TABLE commercial_private.entitlement_bundles ENABLE ROW LEVEL SECURITY;
ALTER TABLE commercial_private.bundle_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE commercial_private.plan_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE commercial_private.term_prices ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE commercial_private.entitlement_bundles, commercial_private.bundle_items,
  commercial_private.plan_versions, commercial_private.term_prices
  FROM PUBLIC, anon, authenticated, service_role;

DO $final_assertions$
DECLARE
  creator_oid oid := current_user::pg_catalog.regrole;
  private_oid oid := 'commercial_private'::pg_catalog.regnamespace;
  client record;
BEGIN
  IF current_user <> 'postgres'
     OR (SELECT nspowner FROM pg_catalog.pg_namespace WHERE oid = private_oid) <> creator_oid
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_class WHERE relnamespace = private_oid AND relowner <> creator_oid)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_type WHERE typnamespace = private_oid AND typowner <> creator_oid) THEN
    RAISE EXCEPTION 'M1a final owner differs from verified creator';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_class WHERE relnamespace = private_oid AND relkind = 'r') <> 4
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_class WHERE relnamespace = private_oid AND relkind = 'i') <> 9
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_class WHERE relnamespace = private_oid AND relkind NOT IN ('r', 'i'))
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_proc WHERE pronamespace = private_oid)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_class c ON c.oid = t.tgrelid
                WHERE c.relnamespace = private_oid AND NOT t.tgisinternal)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_policy p JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
                WHERE c.relnamespace = private_oid)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_class WHERE relnamespace = private_oid AND relkind = 'r' AND NOT relrowsecurity)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_publication_tables WHERE schemaname = 'commercial_private')
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_publication WHERE puballtables) THEN
    RAISE EXCEPTION 'M1a unexpected object, policy, RLS or Realtime exposure';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_namespace n
    CROSS JOIN LATERAL pg_catalog.aclexplode(coalesce(n.nspacl, pg_catalog.acldefault('n', n.nspowner))) a
    WHERE n.oid = private_oid AND a.grantee <> creator_oid
  ) OR EXISTS (
    SELECT 1 FROM pg_catalog.pg_class c
    CROSS JOIN LATERAL pg_catalog.aclexplode(coalesce(c.relacl, pg_catalog.acldefault('r', c.relowner))) a
    WHERE c.relnamespace = private_oid AND c.relkind = 'r' AND a.grantee <> creator_oid
  ) THEN
    RAISE EXCEPTION 'M1a private schema/table ACL has a non-owner grantee';
  END IF;
  -- Missing global ACL rows mean PostgreSQL built-in defaults, not empty ACLs.
  IF EXISTS (
    SELECT 1 FROM (VALUES ('r'), ('S'), ('f'), ('T')) kind(class)
    LEFT JOIN pg_catalog.pg_default_acl d ON d.defaclrole = creator_oid
      AND d.defaclnamespace = 0 AND d.defaclobjtype = kind.class::"char"
    CROSS JOIN LATERAL pg_catalog.aclexplode(coalesce(d.defaclacl, pg_catalog.acldefault(kind.class::"char", creator_oid))) a
    WHERE a.grantee <> creator_oid
  ) OR EXISTS (
    SELECT 1 FROM pg_catalog.pg_default_acl d
    CROSS JOIN LATERAL pg_catalog.aclexplode(d.defaclacl) a
    WHERE d.defaclrole = creator_oid AND d.defaclnamespace = private_oid AND a.grantee <> creator_oid
  ) THEN
    RAISE EXCEPTION 'M1a creator defaults permit non-owner future access';
  END IF;
  FOR client IN SELECT oid, rolname FROM pg_catalog.pg_roles WHERE rolname IN ('anon', 'authenticated', 'service_role') LOOP
    IF pg_catalog.pg_has_role(client.oid, creator_oid, 'MEMBER')
       OR pg_catalog.has_schema_privilege(client.oid, private_oid, 'USAGE,CREATE')
       OR EXISTS (SELECT 1 FROM pg_catalog.pg_class c WHERE c.relnamespace = private_oid AND c.relkind = 'r'
                  AND pg_catalog.has_table_privilege(client.oid, c.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')) THEN
      RAISE EXCEPTION 'M1a effective private privilege exists for client role %', client.rolname;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM commercial_private.entitlement_bundles)
     OR EXISTS (SELECT 1 FROM commercial_private.bundle_items)
     OR EXISTS (SELECT 1 FROM commercial_private.plan_versions)
     OR EXISTS (SELECT 1 FROM commercial_private.term_prices) THEN
    RAISE EXCEPTION 'M1a foundation must contain zero production rows';
  END IF;
END;
$final_assertions$;

-- Row types/implicit arrays are dependent objects owned by the table creator;
-- TYPES defaults are independently hardened for future standalone types.
-- No publisher/immutability guard or entitlement evaluator is authorized here.
-- MED-3 stays M4; MED-4 stays future integration; projection proof stays before M5.
