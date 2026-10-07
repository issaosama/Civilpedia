-- CUI-2A0: bounded, ownerless, non-public staff Draft authority.
-- Frozen contract V1; Owner authorization a813b8c99309757bd7d03ac96dde0e7c12cfed79.
-- Runner owns one atomic migration transaction. No adoption/retry/backfill.
-- Committed ACL Security Addendum V1: metadata-only correction, rolled back
-- together with 00026 if any subsequent preflight or final assertion fails.
REVOKE EXECUTE ON FUNCTION
public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)
FROM PUBLIC, anon, authenticated, service_role;

DO $preflight$
DECLARE
  v_owner oid := 'postgres'::pg_catalog.regrole;
  v_role record;
  v_name text;
BEGIN
  IF current_user <> 'postgres' OR session_user <> 'postgres'
     OR pg_catalog.current_setting('role') <> 'none'
     OR pg_catalog.current_setting('server_version_num')::integer / 10000 <> 17 THEN
    RAISE EXCEPTION 'CUI2A0 execution context drift';
  END IF;
  IF pg_catalog.to_regnamespace('business_admin_private') IS NOT NULL THEN
    RAISE EXCEPTION 'CUI2A0 namespace occupied; no adoption or retry';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
      WHERE p.oid=pg_catalog.to_regprocedure('public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)')
      AND p.proowner=v_owner AND p.prosecdef AND p.prorettype='pg_catalog.void'::pg_catalog.regtype
      AND p.proconfig=ARRAY['search_path=public, pg_temp']
      AND p.prosrc=$accepted_audit$
BEGIN
  INSERT INTO public.audit_logs (
    actor_user_id, action, target_type, target_id,
    before_data, after_data, reason
  ) VALUES (
    p_actor_user_id, p_action, p_target_type, p_target_id,
    p_before_data, p_after_data, p_reason
  );
END;
$accepted_audit$)
     OR NOT pg_catalog.has_function_privilege('postgres',
       'public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)','EXECUTE')
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
       CROSS JOIN LATERAL pg_catalog.aclexplode(COALESCE(p.proacl,pg_catalog.acldefault('f',p.proowner))) a
       WHERE p.oid='public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)'::pg_catalog.regprocedure
       AND a.grantee=0 AND a.privilege_type='EXECUTE') THEN
    RAISE EXCEPTION 'CUI2A0 unchanged append helper metadata or hardened ACL drift';
  END IF;
  IF pg_catalog.to_regprocedure('extensions.digest(bytea,text)') IS NULL
     OR pg_catalog.to_regprocedure('public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)') IS NULL
     OR pg_catalog.to_regprocedure('public.is_valid_directory_entity_type(text)') IS NULL
     OR pg_catalog.to_regnamespace('commercial_private') IS NULL
     OR pg_catalog.to_regprocedure('commercial_private.m3_evaluate_entitlement_v1(jsonb,timestamp with time zone)') IS NULL THEN
    RAISE EXCEPTION 'CUI2A0 prerequisite chain drift';
  END IF;
  FOREACH v_name IN ARRAY ARRAY[
    'get_staff_business_capabilities','list_staff_business_entities',
    'get_staff_business_entity_detail','staff_create_business_draft',
    'staff_update_business_draft','list_staff_business_entity_audit'
  ] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
               JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace
               WHERE n.nspname='public' AND p.proname=v_name) THEN
      RAISE EXCEPTION 'CUI2A0 endpoint name occupied';
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_class c
             JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
             WHERE n.nspname='public' AND c.relname IN (
               'idx_directory_entities_cui2a0_staff_page',
               'idx_audit_logs_cui2a0_entity_page','uq_audit_logs_cui2a0_draft_create')) THEN
    RAISE EXCEPTION 'CUI2A0 index name occupied';
  END IF;
  IF EXISTS (SELECT 1 FROM public.permissions p
     JOIN (VALUES
       ('business_entities.read','Read scoped staff Business Entity list and Draft-editor detail'),
       ('business_entities.create_draft','Create a non-public ownerless Business Draft'),
       ('business_entities.edit_draft','Edit eligible staff-authored non-public Business Drafts'),
       ('business_entities.read_audit','Read sanitized entity-scoped Business Draft authoring audit')
     ) expected(code,description) ON p.code=expected.code
     WHERE p.description IS DISTINCT FROM expected.description) THEN
    RAISE EXCEPTION 'CUI2A0 conflicting permission definition';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
       WHERE t.tgrelid='public.business_applications'::pg_catalog.regclass
       AND t.tgname='trigger_guard_claim_insert' AND NOT t.tgisinternal
       AND t.tgfoid='public.guard_claim_application_insert()'::pg_catalog.regprocedure
       AND t.tgtype=7 AND t.tgenabled='O')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint
       WHERE conrelid='public.business_applications'::pg_catalog.regclass
       AND contype='f' AND confrelid='public.directory_entities'::pg_catalog.regclass)
     OR pg_catalog.to_regclass('public.uq_business_applications_live_claim') IS NULL THEN
    RAISE EXCEPTION 'CUI2A0 canonical CLAIM binding/constraints drift';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc
      WHERE oid='public.guard_claim_application_insert()'::pg_catalog.regprocedure
      AND proowner=v_owner AND prosecdef
      AND prosrc=$accepted_guard$
BEGIN
  IF NEW.application_type = 'CLAIM' THEN
    -- Lock the target row BEFORE validating claim_status. The lock covers the
    -- whole check-then-insert window (the trigger runs inside the INSERT
    -- transaction). A missing target locks nothing; the FK (23503) still fires
    -- on the final INSERT, preserving the distinct targetNotFound outcome.
    PERFORM 1
      FROM public.directory_entities
     WHERE id = NEW.target_entity_id
       FOR UPDATE;

    IF EXISTS (
      SELECT 1 FROM public.directory_entities
      WHERE id = NEW.target_entity_id
        AND claim_status <> 'unclaimed'
    ) THEN
      RAISE EXCEPTION 'target entity is not claimable (claim_status is not unclaimed)'
        USING ERRCODE = 'P0CLM';
    END IF;
  END IF;
  RETURN NEW;
END;
$accepted_guard$) THEN
    RAISE EXCEPTION 'CUI2A0 accepted 00015 guard definition drift';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
      JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid
      WHERE t.tgrelid='public.directory_entities'::pg_catalog.regclass
      AND t.tgname='trigger_set_updated_at' AND t.tgtype=19 AND t.tgenabled='O'
      AND p.oid='public.set_updated_at()'::pg_catalog.regprocedure
      AND p.prosrc=$updated_at$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$updated_at$) THEN
    RAISE EXCEPTION 'CUI2A0 canonical timestamp trigger drift';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_default_acl d
      CROSS JOIN LATERAL pg_catalog.aclexplode(d.defaclacl) a
      WHERE d.defaclrole=v_owner AND d.defaclnamespace=0 AND a.grantee<>v_owner) THEN
    RAISE EXCEPTION 'CUI2A0 global future-object defaults drift';
  END IF;
  IF position('business_admin_private' IN
       COALESCE(pg_catalog.current_setting('pgrst.db_schemas',true),''))>0 THEN
    RAISE EXCEPTION 'CUI2A0 private namespace configured for API exposure';
  END IF;
  FOREACH v_name IN ARRAY ARRAY[
    'directory_entities','entity_contacts','directory_entity_categories',
    'entity_locations','business_memberships','subscriptions','audit_logs',
    'staff_memberships','roles','permissions','role_permissions','business_applications'
  ] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class
       WHERE oid=pg_catalog.to_regclass('public.'||v_name) AND relowner=v_owner
       AND relrowsecurity AND NOT relforcerowsecurity) THEN
      RAISE EXCEPTION 'CUI2A0 prerequisite owner/RLS drift';
    END IF;
  END LOOP;
  FOR v_role IN SELECT oid,rolname,rolsuper FROM pg_catalog.pg_roles
       WHERE rolname IN ('anon','authenticated','service_role') LOOP
    IF v_role.rolsuper OR pg_catalog.pg_has_role(v_role.oid,v_owner,'MEMBER')
       OR (v_role.rolname IN ('anon','authenticated') AND pg_catalog.has_function_privilege(v_role.oid,
            'public.guard_claim_application_insert()','EXECUTE'))
       OR pg_catalog.has_function_privilege(v_role.oid,
            'public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)','EXECUTE') THEN
      RAISE EXCEPTION 'CUI2A0 existing private authority ACL drift';
    END IF;
    IF v_role.rolname IN ('anon','authenticated') THEN
      FOREACH v_name IN ARRAY ARRAY[
        'directory_entities','entity_contacts','directory_entity_categories',
        'entity_locations','business_memberships','subscriptions','audit_logs'
      ] LOOP
        IF pg_catalog.has_table_privilege(v_role.oid,
             pg_catalog.to_regclass('public.'||v_name),
             'INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
           OR pg_catalog.has_any_column_privilege(v_role.oid,
             pg_catalog.to_regclass('public.'||v_name),'INSERT,UPDATE,REFERENCES') THEN
          RAISE EXCEPTION 'CUI2A0 direct privileged client DML drift';
        END IF;
      END LOOP;
    END IF;
  END LOOP;

  IF EXISTS(SELECT 1 FROM pg_catalog.pg_proc p
     JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace
     WHERE n.nspname='public'
       AND p.prosrc ~* '(INSERT[[:space:]]+INTO|UPDATE|DELETE[[:space:]]+FROM)[[:space:]]+public[.](directory_entities|entity_contacts|directory_entity_categories|entity_locations|business_memberships|subscriptions)'
       AND p.proname NOT IN ('staff_activate_business_application','update_managed_business_profile')) THEN
    RAISE EXCEPTION 'CUI2A0 unexpected sanctioned entity writer';
  END IF;
  IF NOT public.is_valid_directory_entity_type('company')
     OR NOT public.is_valid_directory_entity_type('engineering_office')
     OR NOT public.is_valid_directory_entity_type('contractor')
     OR NOT public.is_valid_directory_entity_type('supplier')
     OR NOT public.is_valid_directory_entity_type('store')
     OR NOT public.is_valid_directory_entity_type('technician')
     OR NOT public.is_valid_directory_entity_type('laboratory')
     OR NOT public.is_valid_directory_entity_type('equipment_provider')
     OR NOT public.is_valid_directory_entity_type('service_provider')
     OR public.is_valid_directory_entity_type('invalid') THEN
    RAISE EXCEPTION 'CUI2A0 canonical nine-type validator drift';
  END IF;
END;
$preflight$;

CREATE SCHEMA business_admin_private AUTHORIZATION postgres;
REVOKE ALL ON SCHEMA business_admin_private FROM PUBLIC, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA business_admin_private
  REVOKE ALL ON TABLES FROM PUBLIC, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA business_admin_private
  REVOKE ALL ON SEQUENCES FROM PUBLIC, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA business_admin_private
  REVOKE ALL ON FUNCTIONS FROM PUBLIC, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA business_admin_private
  REVOKE ALL ON TYPES FROM PUBLIC, anon, authenticated, service_role;

CREATE TABLE business_admin_private.draft_create_requests (
  actor_user_id uuid NOT NULL CHECK (actor_user_id <> '00000000-0000-0000-0000-000000000000'::uuid),
  request_id uuid NOT NULL CHECK (request_id <> '00000000-0000-0000-0000-000000000000'::uuid),
  payload_fingerprint bytea NOT NULL CHECK (pg_catalog.octet_length(payload_fingerprint)=32),
  entity_id uuid NOT NULL UNIQUE CHECK (entity_id <> '00000000-0000-0000-0000-000000000000'::uuid),
  created_at timestamptz NOT NULL CHECK (pg_catalog.isfinite(created_at)),
  created_updated_at timestamptz NOT NULL CHECK (
    pg_catalog.isfinite(created_updated_at) AND created_updated_at=created_at),
  PRIMARY KEY (actor_user_id,request_id)
);
ALTER TABLE business_admin_private.draft_create_requests OWNER TO postgres;
ALTER TABLE business_admin_private.draft_create_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE business_admin_private.draft_create_requests
  FROM PUBLIC, anon, authenticated, service_role;

INSERT INTO public.permissions(code,description)
SELECT expected.code,expected.description FROM (VALUES
  ('business_entities.read','Read scoped staff Business Entity list and Draft-editor detail'),
  ('business_entities.create_draft','Create a non-public ownerless Business Draft'),
  ('business_entities.edit_draft','Edit eligible staff-authored non-public Business Drafts'),
  ('business_entities.read_audit','Read sanitized entity-scoped Business Draft authoring audit')
) expected(code,description)
WHERE NOT EXISTS (SELECT 1 FROM public.permissions p WHERE p.code=expected.code);

CREATE INDEX idx_directory_entities_cui2a0_staff_page
  ON public.directory_entities(created_at DESC,id DESC);
CREATE INDEX idx_audit_logs_cui2a0_entity_page
  ON public.audit_logs(target_id,created_at DESC,id DESC)
  WHERE target_type='directory_entity'
    AND action IN ('business_entity.draft_create','business_entity.draft_update');
CREATE UNIQUE INDEX uq_audit_logs_cui2a0_draft_create
  ON public.audit_logs(target_id)
  WHERE target_type='directory_entity' AND action='business_entity.draft_create';

CREATE FUNCTION business_admin_private.has_staff_business_permission(p_code text)
RETURNS boolean LANGUAGE plpgsql VOLATILE SECURITY INVOKER
SET search_path = pg_catalog, pg_temp
AS $fn$
DECLARE v_time timestamptz := pg_catalog.clock_timestamp();
BEGIN
  IF p_code IS NULL OR p_code NOT IN (
    'business_entities.read','business_entities.create_draft',
    'business_entities.edit_draft','business_entities.read_audit') THEN
    RETURN false;
  END IF;
  RETURN EXISTS (
    SELECT 1 FROM public.staff_memberships sm
    JOIN public.roles r ON r.id=sm.role_id
    JOIN public.role_permissions rp ON rp.role_id=r.id
    JOIN public.permissions p ON p.id=rp.permission_id
    WHERE sm.user_id=auth.uid() AND sm.is_active
      AND sm.effective_at<=v_time
      AND (sm.expires_at IS NULL OR sm.expires_at>v_time) AND p.code=p_code);
END;
$fn$;

CREATE FUNCTION business_admin_private.normalize_draft_payload(p_payload jsonb)
RETURNS jsonb LANGUAGE plpgsql IMMUTABLE SECURITY INVOKER
SET search_path = pg_catalog, pg_temp
AS $fn$
DECLARE
  v_item jsonb; v_location jsonb; v_type text; v_name text; v_description text;
  v_value text; v_contacts jsonb := '[]'; v_categories jsonb := '[]';
  v_region uuid; v_category uuid; v_address text; v_lat numeric; v_lon numeric;
BEGIN
  IF p_payload IS NULL OR pg_catalog.jsonb_typeof(p_payload)<>'object'
     OR pg_catalog.octet_length(pg_catalog.convert_to(p_payload::text,'UTF8'))>65536
     OR NOT (p_payload ?& ARRAY['entity_type','name','description','contacts','categories','primary_location'])
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(p_payload))<>6
     OR pg_catalog.jsonb_typeof(p_payload->'entity_type')<>'string'
     OR pg_catalog.jsonb_typeof(p_payload->'name')<>'string'
     OR pg_catalog.jsonb_typeof(p_payload->'description') NOT IN ('string','null')
     OR pg_catalog.jsonb_typeof(p_payload->'contacts')<>'array'
     OR pg_catalog.jsonb_typeof(p_payload->'categories')<>'array'
     OR pg_catalog.jsonb_typeof(p_payload->'primary_location') NOT IN ('object','null') THEN
    RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
  END IF;
  v_type:=p_payload->>'entity_type';
  v_name:=pg_catalog.btrim(p_payload->>'name');
  v_description:=NULLIF(pg_catalog.btrim(p_payload->>'description'),'');
  IF NOT public.is_valid_directory_entity_type(v_type)
     OR v_type NOT IN ('company','contractor','supplier','store')
     OR pg_catalog.char_length(v_name) NOT BETWEEN 1 AND 160
     OR pg_catalog.char_length(v_description)>2000
     OR pg_catalog.jsonb_array_length(p_payload->'contacts')>10
     OR pg_catalog.jsonb_array_length(p_payload->'categories')>10 THEN
    RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
  END IF;
  FOR v_item IN SELECT value FROM pg_catalog.jsonb_array_elements(p_payload->'contacts') LOOP
    IF pg_catalog.jsonb_typeof(v_item)<>'object'
       OR NOT (v_item ?& ARRAY['contact_type','value','is_primary'])
       OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(v_item))<>3
       OR pg_catalog.jsonb_typeof(v_item->'contact_type')<>'string'
       OR pg_catalog.jsonb_typeof(v_item->'value')<>'string'
       OR pg_catalog.jsonb_typeof(v_item->'is_primary')<>'boolean' THEN
      RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
    END IF;
    v_type:=pg_catalog.lower(pg_catalog.btrim(v_item->>'contact_type'));
    v_value:=pg_catalog.btrim(v_item->>'value');
    IF v_value='' OR v_type NOT IN ('phone','whatsapp','email','website','other')
       OR (v_type IN ('phone','whatsapp') AND (
          pg_catalog.char_length(v_value)>32 OR v_value !~ '^[0-9+(). /-]+$'
          OR pg_catalog.char_length(pg_catalog.regexp_replace(v_value,'[^0-9]','','g'))<3))
       OR (v_type='email' AND (pg_catalog.char_length(v_value)>254
          OR v_value !~* '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'))
       OR (v_type='website' AND (pg_catalog.char_length(v_value)>2048
          OR v_value !~* '^https?://[^[:space:]]+$'))
       OR (v_type='other' AND pg_catalog.char_length(v_value)>500) THEN
      RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
    END IF;
    v_contacts:=v_contacts||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'contact_type',v_type,'value',v_value,'is_primary',(v_item->>'is_primary')::boolean));
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_contacts) c
       GROUP BY c->>'contact_type',pg_catalog.lower(c->>'value') HAVING pg_catalog.count(*)>1)
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_contacts) c
       WHERE (c->>'is_primary')::boolean GROUP BY c->>'contact_type' HAVING pg_catalog.count(*)>1) THEN
    RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
  END IF;
  FOR v_item IN SELECT value FROM pg_catalog.jsonb_array_elements(p_payload->'categories') LOOP
    IF pg_catalog.jsonb_typeof(v_item)<>'object'
       OR NOT (v_item ?& ARRAY['category_id','is_primary'])
       OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(v_item))<>2
       OR pg_catalog.jsonb_typeof(v_item->'category_id')<>'string'
       OR pg_catalog.jsonb_typeof(v_item->'is_primary')<>'boolean'
       OR (v_item->>'category_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
      RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
    END IF;
    v_category:=(v_item->>'category_id')::uuid;
    IF v_category='00000000-0000-0000-0000-000000000000'::uuid THEN
      RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
    END IF;
    v_categories:=v_categories||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'category_id',v_category::text,'is_primary',(v_item->>'is_primary')::boolean));
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_categories) c
       GROUP BY c->>'category_id' HAVING pg_catalog.count(*)>1)
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_array_elements(v_categories) c
       WHERE (c->>'is_primary')::boolean)>1 THEN
    RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
  END IF;
  v_location:=p_payload->'primary_location';
  IF v_location<>'null'::jsonb THEN
    IF NOT (v_location ?& ARRAY['region_id','address','latitude','longitude'])
       OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(v_location))<>4
       OR pg_catalog.jsonb_typeof(v_location->'region_id') NOT IN ('string','null')
       OR pg_catalog.jsonb_typeof(v_location->'address') NOT IN ('string','null')
       OR pg_catalog.jsonb_typeof(v_location->'latitude') NOT IN ('number','null')
       OR pg_catalog.jsonb_typeof(v_location->'longitude') NOT IN ('number','null') THEN
      RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
    END IF;
    IF v_location->>'region_id' IS NOT NULL THEN
      IF (v_location->>'region_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
        RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
      END IF;
      v_region:=(v_location->>'region_id')::uuid;
      IF v_region='00000000-0000-0000-0000-000000000000'::uuid THEN
        RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
      END IF;
    END IF;
    v_address:=NULLIF(pg_catalog.btrim(v_location->>'address'),'');
    v_lat:=(v_location->>'latitude')::numeric; v_lon:=(v_location->>'longitude')::numeric;
    IF pg_catalog.char_length(v_address)>500 OR (v_lat IS NULL)<>(v_lon IS NULL)
       OR v_lat NOT BETWEEN -90 AND 90 OR v_lon NOT BETWEEN -180 AND 180
       OR v_lat<>pg_catalog.round(v_lat,6) OR v_lon<>pg_catalog.round(v_lon,6)
       OR (v_region IS NULL AND v_address IS NULL AND v_lat IS NULL) THEN
      RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
    END IF;
    v_location:=pg_catalog.jsonb_build_object('region_id',v_region::text,'address',v_address,
       'latitude',v_lat::numeric(9,6),'longitude',v_lon::numeric(9,6));
  END IF;
  SELECT COALESCE(pg_catalog.jsonb_agg(c ORDER BY
    c->>'contact_type',(c->>'value') COLLATE "C",(c->>'is_primary')::boolean),'[]'::jsonb)
    INTO v_contacts FROM pg_catalog.jsonb_array_elements(v_contacts) c;
  SELECT COALESCE(pg_catalog.jsonb_agg(c ORDER BY (c->>'category_id')::uuid),'[]'::jsonb)
    INTO v_categories FROM pg_catalog.jsonb_array_elements(v_categories) c;
  RETURN pg_catalog.jsonb_build_object('entity_type',p_payload->>'entity_type','name',v_name,
    'description',v_description,'contacts',v_contacts,'categories',v_categories,
    'primary_location',v_location);
EXCEPTION WHEN invalid_parameter_value OR invalid_text_representation OR numeric_value_out_of_range THEN
  RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
END;
$fn$;

-- Canonical existing trigger identity/binding is preserved.
CREATE OR REPLACE FUNCTION public.guard_claim_application_insert()
RETURNS trigger LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $fn$
DECLARE v_status text; v_protected boolean;
BEGIN
  IF NEW.application_type<>'CLAIM' OR NEW.target_entity_id IS NULL THEN
    RETURN NEW;
  END IF;
  SELECT de.claim_status INTO v_status FROM public.directory_entities AS de
    WHERE de.id=NEW.target_entity_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'claim target not found' USING ERRCODE='23503';
  END IF;
  -- A separate VOLATILE statement after the target lock/wait: fresh READ COMMITTED snapshot.
  SELECT EXISTS (
    SELECT 1 FROM business_admin_private.draft_create_requests AS receipt
    WHERE receipt.entity_id=NEW.target_entity_id
  ) INTO v_protected;
  IF v_status<>'unclaimed' OR v_protected THEN
    RAISE EXCEPTION 'target entity is not claimable' USING ERRCODE='P0CLM';
  END IF;
  RETURN NEW;
END;
$fn$;


CREATE FUNCTION public.get_staff_business_capabilities()
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $fn$
DECLARE v_codes jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE='P0AUT';
  END IF;
  SELECT COALESCE(pg_catalog.jsonb_agg(code ORDER BY ordinal),'[]'::jsonb)
    INTO v_codes FROM pg_catalog.unnest(ARRAY[
      'business_entities.read','business_entities.create_draft',
      'business_entities.edit_draft','business_entities.read_audit'
    ]) WITH ORDINALITY AS ordered(code,ordinal)
    WHERE business_admin_private.has_staff_business_permission(code);
  RETURN pg_catalog.jsonb_build_object('capabilities',v_codes);
END;
$fn$;

CREATE FUNCTION public.list_staff_business_entities(
  p_search text DEFAULT NULL, p_entity_type text DEFAULT NULL,
  p_lifecycle_status text DEFAULT NULL, p_limit integer DEFAULT 25,
  p_before_created_at timestamptz DEFAULT NULL, p_before_id uuid DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $fn$
DECLARE v_search text; v_items jsonb := '[]'; v_cursor jsonb := 'null';
  v_row record; v_count integer := 0;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE='P0AUT';
  END IF;
  IF NOT business_admin_private.has_staff_business_permission('business_entities.read') THEN
    RAISE EXCEPTION 'staff_business_permission_denied' USING ERRCODE='P0PER';
  END IF;
  v_search:=NULLIF(pg_catalog.btrim(p_search),'');
  IF p_limit IS NULL OR p_limit NOT BETWEEN 1 AND 50
     OR (p_entity_type IS NOT NULL AND NOT public.is_valid_directory_entity_type(p_entity_type))
     OR (p_lifecycle_status IS NOT NULL AND p_lifecycle_status NOT IN ('draft','active','inactive','suspended'))
     OR pg_catalog.char_length(v_search)>120
     OR (p_before_created_at IS NULL)<>(p_before_id IS NULL)
     OR NOT pg_catalog.isfinite(p_before_created_at)
     OR p_before_id='00000000-0000-0000-0000-000000000000'::uuid THEN
    RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
  END IF;
  v_search:=pg_catalog.replace(pg_catalog.replace(pg_catalog.replace(v_search,
       E'\\',E'\\\\'),'%',E'\\%'),'_',E'\\_');
  FOR v_row IN SELECT de.id,de.name,de.entity_type,de.lifecycle_status,
       de.verification_status,de.claim_status,de.created_at,de.updated_at
    FROM public.directory_entities de
    WHERE (v_search IS NULL OR de.name ILIKE '%'||v_search||'%' ESCAPE E'\\')
      AND (p_entity_type IS NULL OR de.entity_type=p_entity_type)
      AND (p_lifecycle_status IS NULL OR de.lifecycle_status=p_lifecycle_status)
      AND (p_before_created_at IS NULL OR (de.created_at,de.id)<(p_before_created_at,p_before_id))
    ORDER BY de.created_at DESC,de.id DESC LIMIT p_limit+1 LOOP
    v_count:=v_count+1;
    IF v_count>p_limit THEN
      v_cursor:=pg_catalog.jsonb_build_object('created_at',
        v_items->(p_limit-1)->'created_at','id',v_items->(p_limit-1)->'entity_id');
      EXIT;
    END IF;
    v_items:=v_items||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'entity_id',v_row.id,'name',v_row.name,'entity_type',v_row.entity_type,
      'lifecycle_status',v_row.lifecycle_status,'verification_status',v_row.verification_status,
      'claim_status',v_row.claim_status,'created_at',v_row.created_at,'updated_at',v_row.updated_at));
  END LOOP;
  RETURN pg_catalog.jsonb_build_object('items',v_items,'next_cursor',v_cursor);
END;
$fn$;

CREATE FUNCTION public.staff_create_business_draft(
  p_request_id uuid, p_payload jsonb, p_reason text
)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $fn$
DECLARE
  v_actor uuid := auth.uid(); v_payload jsonb; v_hash bytea;
  v_id uuid := pg_catalog.gen_random_uuid(); v_time timestamptz := pg_catalog.transaction_timestamp();
  v_receipt business_admin_private.draft_create_requests%ROWTYPE;
  v_entity public.directory_entities%ROWTYPE; v_new boolean;
  v_item jsonb; v_active boolean; v_a jsonb; v_before jsonb; v_after jsonb; v_fields jsonb;
  v_origin boolean;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE='P0AUT';
  END IF;
  IF NOT business_admin_private.has_staff_business_permission('business_entities.create_draft') THEN
    RAISE EXCEPTION 'staff_business_permission_denied' USING ERRCODE='P0PER';
  END IF;
  IF pg_catalog.current_setting('transaction_isolation')<>'read committed' THEN
    RAISE EXCEPTION 'unsupported_draft_transaction_context' USING ERRCODE='P0CTX';
  END IF;
  IF p_request_id IS NULL OR p_request_id='00000000-0000-0000-0000-000000000000'::uuid
     OR p_reason IS NULL OR p_reason NOT IN (
       'BUSINESS_SUPPLIED_INFORMATION','BUSINESS_AUTHORIZED_PREPARATION') THEN
    RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
  END IF;
  v_payload:=business_admin_private.normalize_draft_payload(p_payload);
  v_hash:=extensions.digest(pg_catalog.convert_to(pg_catalog.jsonb_build_object(
     'operation_version','cui2a0.create.v1','payload',v_payload,'reason',p_reason)::text,'UTF8'),'sha256');
  INSERT INTO business_admin_private.draft_create_requests(
     actor_user_id,request_id,payload_fingerprint,entity_id,created_at,created_updated_at)
    VALUES (v_actor,p_request_id,v_hash,v_id,v_time,v_time)
    ON CONFLICT (actor_user_id,request_id) DO NOTHING;
  v_new:=FOUND;
  -- Fresh statement after uniqueness wait. Never lock an existing entity on replay.
  IF NOT business_admin_private.has_staff_business_permission('business_entities.create_draft') THEN
    RAISE EXCEPTION 'staff_business_permission_denied' USING ERRCODE='P0PER';
  END IF;
  IF NOT v_new THEN
    SELECT receipt.actor_user_id,receipt.request_id,receipt.payload_fingerprint,
        receipt.entity_id,receipt.created_at,receipt.created_updated_at INTO v_receipt
      FROM business_admin_private.draft_create_requests receipt
      WHERE receipt.actor_user_id=v_actor AND receipt.request_id=p_request_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    IF v_receipt.payload_fingerprint IS DISTINCT FROM v_hash THEN
      RAISE EXCEPTION 'draft_create_request_conflict' USING ERRCODE='P0RPL';
    END IF;
    SELECT de.id,de.entity_type,de.name,de.description,de.lifecycle_status,
      de.verification_status,de.claim_status,de.created_at,de.updated_at
      INTO v_entity FROM public.directory_entities de WHERE de.id=v_receipt.entity_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    SELECT pg_catalog.to_jsonb(a) INTO v_a FROM public.audit_logs a
      WHERE a.target_type='directory_entity' AND a.target_id=v_receipt.entity_id
        AND a.action='business_entity.draft_create';

  v_origin:=false;
  IF v_receipt.entity_id IS NULL THEN
    IF v_a IS NOT NULL THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
  ELSE
    IF v_a IS NULL OR v_receipt.created_at IS DISTINCT FROM v_entity.created_at
       OR v_receipt.created_updated_at IS DISTINCT FROM v_receipt.created_at
       OR NOT pg_catalog.isfinite(v_entity.updated_at)
       OR v_entity.updated_at<v_receipt.created_updated_at
       OR pg_catalog.octet_length(v_receipt.payload_fingerprint)<>32 THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;

  -- Validate the entire typed event before using or projecting any summary.
  BEGIN
    IF v_a IS NULL OR pg_catalog.jsonb_typeof(v_a->'after_data')<>'object'
       OR (v_a->>'target_type')<>'directory_entity'
       OR (v_a->>'action') NOT IN ('business_entity.draft_create','business_entity.draft_update')
       OR NOT pg_catalog.isfinite((v_a->>'created_at')::timestamptz) THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    v_after:=v_a->'after_data'; v_before:=v_a->'before_data';
    IF NOT (v_after ?& ARRAY['format_version','request_id','changed_fields','updated_at',
        'contact_count','category_count','has_primary_location'])
       OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(v_after))<>7
       OR (v_after->>'format_version') IS DISTINCT FROM 'cui2a0.audit.v1'
       OR pg_catalog.jsonb_typeof(v_after->'request_id')<>'string'
       OR (v_after->>'request_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       OR (v_after->>'request_id')::uuid='00000000-0000-0000-0000-000000000000'::uuid
       OR pg_catalog.jsonb_typeof(v_after->'changed_fields')<>'array'
       OR pg_catalog.jsonb_typeof(v_after->'updated_at')<>'string'
       OR NOT pg_catalog.isfinite((v_after->>'updated_at')::timestamptz)
       OR pg_catalog.jsonb_typeof(v_after->'contact_count')<>'number'
       OR (v_after->>'contact_count') !~ '^(0|[1-9]|10)$'
       OR pg_catalog.jsonb_typeof(v_after->'category_count')<>'number'
       OR (v_after->>'category_count') !~ '^(0|[1-9]|10)$'
       OR pg_catalog.jsonb_typeof(v_after->'has_primary_location')<>'boolean' THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    SELECT COALESCE(pg_catalog.jsonb_agg(field ORDER BY ordinal),'[]'::jsonb)
      INTO v_fields FROM pg_catalog.unnest(ARRAY[
        'entity_type','name','description','contacts','categories','primary_location'
      ]) WITH ORDINALITY AS allowed(field,ordinal)
      WHERE v_after->'changed_fields' ? field;
    IF v_fields<>v_after->'changed_fields' OR pg_catalog.jsonb_array_length(v_fields)=0 THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    IF v_a->>'action'='business_entity.draft_create' THEN
      IF v_before<>'null'::jsonb OR v_fields<>
          '["entity_type","name","description","contacts","categories","primary_location"]'::jsonb
         OR (v_a->>'reason' IS NULL OR v_a->>'reason' NOT IN (
           'BUSINESS_SUPPLIED_INFORMATION','BUSINESS_AUTHORIZED_PREPARATION')) THEN
        RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
      END IF;
    ELSE
      IF pg_catalog.jsonb_typeof(v_before)<>'object'
         OR NOT (v_before ?& ARRAY['updated_at','contact_count','category_count','has_primary_location'])
         OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(v_before))<>4
         OR pg_catalog.jsonb_typeof(v_before->'updated_at')<>'string'
         OR NOT pg_catalog.isfinite((v_before->>'updated_at')::timestamptz)
         OR (v_before->>'updated_at')::timestamptz>=(v_after->>'updated_at')::timestamptz
         OR pg_catalog.jsonb_typeof(v_before->'contact_count')<>'number'
         OR (v_before->>'contact_count') !~ '^(0|[1-9]|10)$'
         OR pg_catalog.jsonb_typeof(v_before->'category_count')<>'number'
         OR (v_before->>'category_count') !~ '^(0|[1-9]|10)$'
         OR pg_catalog.jsonb_typeof(v_before->'has_primary_location')<>'boolean'
         OR (v_a->>'reason' IS NULL OR v_a->>'reason' NOT IN ('CORRECT_DRAFT_INFORMATION','COMPLETE_DRAFT_INFORMATION')) THEN
        RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
      END IF;
    END IF;
  EXCEPTION WHEN invalid_text_representation OR invalid_datetime_format
      OR datetime_field_overflow OR invalid_parameter_value OR numeric_value_out_of_range THEN
    RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
  END;

    IF (v_after->>'request_id')::uuid IS DISTINCT FROM v_receipt.request_id
       OR (v_after->>'updated_at')::timestamptz IS DISTINCT FROM v_receipt.created_updated_at
       OR ((v_a->>'actor_user_id')::uuid IS NOT NULL
           AND (v_a->>'actor_user_id')::uuid IS DISTINCT FROM v_receipt.actor_user_id) THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    v_origin:=true;
  END IF;
    RETURN pg_catalog.jsonb_build_object('outcome','REPLAY','request_id',p_request_id,
      'entity_id',v_receipt.entity_id,'created_at',v_receipt.created_at,
      'created_updated_at',v_receipt.created_updated_at);
  END IF;
  INSERT INTO public.directory_entities(id,entity_type,name,description,
    lifecycle_status,verification_status,claim_status,created_at,updated_at)
    VALUES(v_id,v_payload->>'entity_type',v_payload->>'name',v_payload->>'description',
      'draft','unverified','unclaimed',v_time,v_time)
    RETURNING id,entity_type,name,description,lifecycle_status,verification_status,
      claim_status,created_at,updated_at INTO v_entity;
  IF v_entity.id IS DISTINCT FROM v_id OR v_entity.created_at IS DISTINCT FROM v_time
      OR v_entity.updated_at IS DISTINCT FROM v_time THEN
    RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
  END IF;

  -- Deterministic taxonomy lock tier; activity is checked on the locked version.
  FOR v_item IN SELECT value FROM pg_catalog.jsonb_array_elements(v_payload->'categories')
       ORDER BY (value->>'category_id')::uuid LOOP
    SELECT c.is_active INTO v_active FROM public.directory_categories c
      WHERE c.id=(v_item->>'category_id')::uuid FOR SHARE;
    IF NOT FOUND OR NOT v_active THEN
      RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
    END IF;
  END LOOP;
  IF v_payload->'primary_location'->>'region_id' IS NOT NULL THEN
    SELECT r.is_active INTO v_active FROM public.regions r
      WHERE r.id=(v_payload->'primary_location'->>'region_id')::uuid FOR SHARE;
    IF NOT FOUND OR NOT v_active THEN
      RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
    END IF;
  END IF;

  IF NOT business_admin_private.has_staff_business_permission('business_entities.create_draft') THEN
    RAISE EXCEPTION 'staff_business_permission_denied' USING ERRCODE='P0PER';
  END IF;
  INSERT INTO public.entity_contacts(entity_id,contact_type,value,is_primary)
    SELECT v_id,c->>'contact_type',c->>'value',(c->>'is_primary')::boolean
    FROM pg_catalog.jsonb_array_elements(v_payload->'contacts') c;
  INSERT INTO public.directory_entity_categories(entity_id,category_id,is_primary)
    SELECT v_id,(c->>'category_id')::uuid,(c->>'is_primary')::boolean
    FROM pg_catalog.jsonb_array_elements(v_payload->'categories') c;
  IF v_payload->'primary_location'<>'null'::jsonb THEN
    INSERT INTO public.entity_locations(entity_id,region_id,address,latitude,longitude,is_primary)
      VALUES(v_id,(v_payload->'primary_location'->>'region_id')::uuid,
        v_payload->'primary_location'->>'address',
        (v_payload->'primary_location'->>'latitude')::numeric(9,6),
        (v_payload->'primary_location'->>'longitude')::numeric(9,6),true);
  END IF;
  BEGIN
    PERFORM public.append_audit_log(v_actor,'business_entity.draft_create','directory_entity',v_id,
      NULL,pg_catalog.jsonb_build_object('format_version','cui2a0.audit.v1','request_id',p_request_id,
        'changed_fields',pg_catalog.jsonb_build_array('entity_type','name','description','contacts','categories','primary_location'),
        'updated_at',v_time,'contact_count',pg_catalog.jsonb_array_length(v_payload->'contacts'),
        'category_count',pg_catalog.jsonb_array_length(v_payload->'categories'),
        'has_primary_location',v_payload->'primary_location'<>'null'::jsonb),p_reason);
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'draft_audit_write_failed' USING ERRCODE='P0AUD';
  END;
  RETURN pg_catalog.jsonb_build_object('outcome','CREATED','request_id',p_request_id,
    'entity_id',v_id,'created_at',v_time,'created_updated_at',v_time);
END;
$fn$;


CREATE FUNCTION public.get_staff_business_entity_detail(p_entity_id uuid)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $fn$
DECLARE
  v_blob jsonb; v_raw jsonb; v_normalized jsonb; v_entity public.directory_entities%ROWTYPE;
  v_receipt business_admin_private.draft_create_requests%ROWTYPE;
  v_a jsonb; v_before jsonb; v_after jsonb; v_fields jsonb;
  v_origin boolean; v_can_edit boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE='P0AUT';
  END IF;
  IF NOT business_admin_private.has_staff_business_permission('business_entities.read') THEN
    RAISE EXCEPTION 'staff_business_permission_denied' USING ERRCODE='P0PER';
  END IF;
  IF p_entity_id IS NULL OR p_entity_id='00000000-0000-0000-0000-000000000000'::uuid THEN
    RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
  END IF;
  -- One statement snapshot contains entity, scoped children and completeness evidence.
  WITH contacts AS MATERIALIZED (
    SELECT c.id,c.contact_type,c.value,c.is_primary FROM public.entity_contacts c
    WHERE c.entity_id=p_entity_id ORDER BY c.contact_type,c.is_primary DESC,c.id LIMIT 51
  ), categories AS MATERIALIZED (
    SELECT dc.category_id,c.code,c.name_ar,c.name_en,c.is_active,dc.is_primary
    FROM public.directory_entity_categories dc JOIN public.directory_categories c ON c.id=dc.category_id
    WHERE dc.entity_id=p_entity_id ORDER BY dc.is_primary DESC,dc.category_id LIMIT 51
  ), location AS MATERIALIZED (
    SELECT l.id,l.region_id,r.code AS region_code,r.name_ar AS region_name_ar,
      r.name_en AS region_name_en,r.is_active AS region_is_active,
      l.address,l.latitude,l.longitude,l.is_primary
    FROM public.entity_locations l LEFT JOIN public.regions r ON r.id=l.region_id
    WHERE l.entity_id=p_entity_id AND l.is_primary
  )
  SELECT pg_catalog.jsonb_build_object(
    'entity',pg_catalog.jsonb_build_object('entity_id',de.id,'entity_type',de.entity_type,
      'name',de.name,'description',de.description,'lifecycle_status',de.lifecycle_status,
      'verification_status',de.verification_status,'claim_status',de.claim_status,
      'created_at',de.created_at,'updated_at',de.updated_at),
    'contacts',COALESCE((SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(c)
       ORDER BY c.contact_type,c.is_primary DESC,c.id)
       FROM (SELECT id,contact_type,value,is_primary FROM contacts
         ORDER BY contact_type,is_primary DESC,id LIMIT 50) c),'[]'::jsonb),
    'categories',COALESCE((SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(c)
       ORDER BY c.is_primary DESC,c.category_id)
       FROM (SELECT category_id,code,name_ar,name_en,is_active,is_primary FROM categories
         ORDER BY is_primary DESC,category_id LIMIT 50) c),'[]'::jsonb),
    'primary_location',COALESCE((SELECT pg_catalog.to_jsonb(l) FROM location l),'null'::jsonb),
    'contacts_complete',(SELECT pg_catalog.count(*) FROM contacts)<=50,
    'categories_complete',(SELECT pg_catalog.count(*) FROM categories)<=50,
    'location_scope_complete',NOT EXISTS(SELECT 1 FROM public.entity_locations l
       WHERE l.entity_id=de.id AND NOT l.is_primary),
    '_entity',pg_catalog.jsonb_build_object('id',de.id,'entity_type',de.entity_type,
       'name',de.name,'description',de.description,'lifecycle_status',de.lifecycle_status,
       'verification_status',de.verification_status,'claim_status',de.claim_status,
       'created_at',de.created_at,'updated_at',de.updated_at),
    '_receipt',(SELECT pg_catalog.to_jsonb(receipt) FROM business_admin_private.draft_create_requests receipt
       WHERE receipt.entity_id=de.id),
    '_audit',(SELECT pg_catalog.to_jsonb(a) FROM public.audit_logs a
       WHERE a.target_id=de.id AND a.target_type='directory_entity'
         AND a.action='business_entity.draft_create'),
    '_eligible',de.lifecycle_status='draft' AND de.verification_status='unverified'
       AND de.claim_status='unclaimed' AND de.entity_type IN ('company','contractor','supplier','store')
       AND NOT EXISTS(SELECT 1 FROM public.business_memberships bm WHERE bm.entity_id=de.id)
       AND NOT EXISTS(SELECT 1 FROM public.subscriptions s WHERE s.entity_id=de.id)
       AND (SELECT pg_catalog.count(*) FROM contacts)<=10
       AND (SELECT pg_catalog.count(*) FROM categories)<=10
  ),pg_catalog.jsonb_build_object(
    'entity_type',de.entity_type,'name',de.name,'description',de.description,
    'contacts',COALESCE((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
       'contact_type',c.contact_type,'value',c.value,'is_primary',c.is_primary)
       ORDER BY c.contact_type,c.value COLLATE "C",c.is_primary) FROM contacts c),'[]'::jsonb),
    'categories',COALESCE((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
       'category_id',c.category_id::text,'is_primary',c.is_primary)
       ORDER BY c.category_id) FROM categories c),'[]'::jsonb),
    'primary_location',COALESCE((SELECT pg_catalog.jsonb_build_object(
       'region_id',l.region_id::text,'address',l.address,'latitude',l.latitude,'longitude',l.longitude)
       FROM location l),'null'::jsonb)
  ) INTO v_blob,v_raw FROM public.directory_entities de WHERE de.id=p_entity_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'entity_not_found' USING ERRCODE='P0NOT';
  END IF;
  v_entity:=pg_catalog.jsonb_populate_record(NULL::public.directory_entities,v_blob->'_entity');
  v_receipt:=pg_catalog.jsonb_populate_record(NULL::business_admin_private.draft_create_requests,
      NULLIF(v_blob->'_receipt','null'::jsonb));
  v_a:=NULLIF(v_blob->'_audit','null'::jsonb);

  v_origin:=false;
  IF v_receipt.entity_id IS NULL THEN
    IF v_a IS NOT NULL THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
  ELSE
    IF v_a IS NULL OR v_receipt.created_at IS DISTINCT FROM v_entity.created_at
       OR v_receipt.created_updated_at IS DISTINCT FROM v_receipt.created_at
       OR NOT pg_catalog.isfinite(v_entity.updated_at)
       OR v_entity.updated_at<v_receipt.created_updated_at
       OR pg_catalog.octet_length(v_receipt.payload_fingerprint)<>32 THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;

  -- Validate the entire typed event before using or projecting any summary.
  BEGIN
    IF v_a IS NULL OR pg_catalog.jsonb_typeof(v_a->'after_data')<>'object'
       OR (v_a->>'target_type')<>'directory_entity'
       OR (v_a->>'action') NOT IN ('business_entity.draft_create','business_entity.draft_update')
       OR NOT pg_catalog.isfinite((v_a->>'created_at')::timestamptz) THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    v_after:=v_a->'after_data'; v_before:=v_a->'before_data';
    IF NOT (v_after ?& ARRAY['format_version','request_id','changed_fields','updated_at',
        'contact_count','category_count','has_primary_location'])
       OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(v_after))<>7
       OR (v_after->>'format_version') IS DISTINCT FROM 'cui2a0.audit.v1'
       OR pg_catalog.jsonb_typeof(v_after->'request_id')<>'string'
       OR (v_after->>'request_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       OR (v_after->>'request_id')::uuid='00000000-0000-0000-0000-000000000000'::uuid
       OR pg_catalog.jsonb_typeof(v_after->'changed_fields')<>'array'
       OR pg_catalog.jsonb_typeof(v_after->'updated_at')<>'string'
       OR NOT pg_catalog.isfinite((v_after->>'updated_at')::timestamptz)
       OR pg_catalog.jsonb_typeof(v_after->'contact_count')<>'number'
       OR (v_after->>'contact_count') !~ '^(0|[1-9]|10)$'
       OR pg_catalog.jsonb_typeof(v_after->'category_count')<>'number'
       OR (v_after->>'category_count') !~ '^(0|[1-9]|10)$'
       OR pg_catalog.jsonb_typeof(v_after->'has_primary_location')<>'boolean' THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    SELECT COALESCE(pg_catalog.jsonb_agg(field ORDER BY ordinal),'[]'::jsonb)
      INTO v_fields FROM pg_catalog.unnest(ARRAY[
        'entity_type','name','description','contacts','categories','primary_location'
      ]) WITH ORDINALITY AS allowed(field,ordinal)
      WHERE v_after->'changed_fields' ? field;
    IF v_fields<>v_after->'changed_fields' OR pg_catalog.jsonb_array_length(v_fields)=0 THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    IF v_a->>'action'='business_entity.draft_create' THEN
      IF v_before<>'null'::jsonb OR v_fields<>
          '["entity_type","name","description","contacts","categories","primary_location"]'::jsonb
         OR (v_a->>'reason' IS NULL OR v_a->>'reason' NOT IN (
           'BUSINESS_SUPPLIED_INFORMATION','BUSINESS_AUTHORIZED_PREPARATION')) THEN
        RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
      END IF;
    ELSE
      IF pg_catalog.jsonb_typeof(v_before)<>'object'
         OR NOT (v_before ?& ARRAY['updated_at','contact_count','category_count','has_primary_location'])
         OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(v_before))<>4
         OR pg_catalog.jsonb_typeof(v_before->'updated_at')<>'string'
         OR NOT pg_catalog.isfinite((v_before->>'updated_at')::timestamptz)
         OR (v_before->>'updated_at')::timestamptz>=(v_after->>'updated_at')::timestamptz
         OR pg_catalog.jsonb_typeof(v_before->'contact_count')<>'number'
         OR (v_before->>'contact_count') !~ '^(0|[1-9]|10)$'
         OR pg_catalog.jsonb_typeof(v_before->'category_count')<>'number'
         OR (v_before->>'category_count') !~ '^(0|[1-9]|10)$'
         OR pg_catalog.jsonb_typeof(v_before->'has_primary_location')<>'boolean'
         OR (v_a->>'reason' IS NULL OR v_a->>'reason' NOT IN ('CORRECT_DRAFT_INFORMATION','COMPLETE_DRAFT_INFORMATION')) THEN
        RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
      END IF;
    END IF;
  EXCEPTION WHEN invalid_text_representation OR invalid_datetime_format
      OR datetime_field_overflow OR invalid_parameter_value OR numeric_value_out_of_range THEN
    RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
  END;

    IF (v_after->>'request_id')::uuid IS DISTINCT FROM v_receipt.request_id
       OR (v_after->>'updated_at')::timestamptz IS DISTINCT FROM v_receipt.created_updated_at
       OR ((v_a->>'actor_user_id')::uuid IS NOT NULL
           AND (v_a->>'actor_user_id')::uuid IS DISTINCT FROM v_receipt.actor_user_id) THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    v_origin:=true;
  END IF;
  v_can_edit:=v_origin AND (v_blob->>'_eligible')::boolean
    AND (v_blob->>'location_scope_complete')::boolean
    AND business_admin_private.has_staff_business_permission('business_entities.edit_draft');
  IF v_can_edit THEN
    BEGIN
      v_normalized:=business_admin_private.normalize_draft_payload(v_raw);
      v_can_edit:=v_normalized=v_raw;
    EXCEPTION WHEN SQLSTATE 'P0DAT' THEN
      v_can_edit:=false;
    END;
  END IF;
  RETURN (v_blob-ARRAY['_entity','_receipt','_audit','_eligible'])||
    pg_catalog.jsonb_build_object('draft_authoring',pg_catalog.jsonb_build_object(
      'origin',CASE WHEN v_origin THEN 'CUI2A0' ELSE 'UNESTABLISHED' END,
      'can_edit_draft',v_can_edit));
END;
$fn$;

CREATE FUNCTION public.staff_update_business_draft(
  p_entity_id uuid, p_expected_updated_at timestamptz,
  p_request_id uuid, p_payload jsonb, p_reason text
)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $fn$
DECLARE
  v_actor uuid := auth.uid(); v_payload jsonb; v_raw jsonb; v_old jsonb;
  v_entity public.directory_entities%ROWTYPE;
  v_receipt business_admin_private.draft_create_requests%ROWTYPE;
  v_a jsonb; v_before jsonb; v_after jsonb; v_fields jsonb; v_origin boolean;
  v_item jsonb; v_active boolean; v_location_id uuid; v_updated_at timestamptz; v_key text;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE='P0AUT';
  END IF;
  IF NOT business_admin_private.has_staff_business_permission('business_entities.edit_draft') THEN
    RAISE EXCEPTION 'staff_business_permission_denied' USING ERRCODE='P0PER';
  END IF;
  IF p_entity_id IS NULL OR p_entity_id='00000000-0000-0000-0000-000000000000'::uuid
     OR p_request_id IS NULL OR p_request_id='00000000-0000-0000-0000-000000000000'::uuid
     OR p_expected_updated_at IS NULL OR NOT pg_catalog.isfinite(p_expected_updated_at)
     OR p_reason IS NULL OR p_reason NOT IN ('CORRECT_DRAFT_INFORMATION','COMPLETE_DRAFT_INFORMATION') THEN
    RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
  END IF;
  v_payload:=business_admin_private.normalize_draft_payload(p_payload);
  IF pg_catalog.current_setting('transaction_isolation')<>'read committed' THEN
    RAISE EXCEPTION 'unsupported_draft_transaction_context' USING ERRCODE='P0CTX';
  END IF;
  SELECT de.id,de.entity_type,de.name,de.description,de.lifecycle_status,
    de.verification_status,de.claim_status,de.created_at,de.updated_at
    INTO v_entity FROM public.directory_entities de WHERE de.id=p_entity_id FOR UPDATE;
  -- Permission precedence holds even if a waiting target was deleted.
  IF NOT business_admin_private.has_staff_business_permission('business_entities.edit_draft') THEN
    RAISE EXCEPTION 'staff_business_permission_denied' USING ERRCODE='P0PER';
  END IF;
  IF v_entity.id IS NULL THEN
    RAISE EXCEPTION 'entity_not_found' USING ERRCODE='P0NOT';
  END IF;
  SELECT receipt.actor_user_id,receipt.request_id,receipt.payload_fingerprint,
    receipt.entity_id,receipt.created_at,receipt.created_updated_at
    INTO v_receipt FROM business_admin_private.draft_create_requests receipt WHERE receipt.entity_id=p_entity_id;
  SELECT pg_catalog.to_jsonb(a) INTO v_a FROM public.audit_logs a
    WHERE a.target_id=p_entity_id AND a.target_type='directory_entity'
      AND a.action='business_entity.draft_create';

  v_origin:=false;
  IF v_receipt.entity_id IS NULL THEN
    IF v_a IS NOT NULL THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
  ELSE
    IF v_a IS NULL OR v_receipt.created_at IS DISTINCT FROM v_entity.created_at
       OR v_receipt.created_updated_at IS DISTINCT FROM v_receipt.created_at
       OR NOT pg_catalog.isfinite(v_entity.updated_at)
       OR v_entity.updated_at<v_receipt.created_updated_at
       OR pg_catalog.octet_length(v_receipt.payload_fingerprint)<>32 THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;

  -- Validate the entire typed event before using or projecting any summary.
  BEGIN
    IF v_a IS NULL OR pg_catalog.jsonb_typeof(v_a->'after_data')<>'object'
       OR (v_a->>'target_type')<>'directory_entity'
       OR (v_a->>'action') NOT IN ('business_entity.draft_create','business_entity.draft_update')
       OR NOT pg_catalog.isfinite((v_a->>'created_at')::timestamptz) THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    v_after:=v_a->'after_data'; v_before:=v_a->'before_data';
    IF NOT (v_after ?& ARRAY['format_version','request_id','changed_fields','updated_at',
        'contact_count','category_count','has_primary_location'])
       OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(v_after))<>7
       OR (v_after->>'format_version') IS DISTINCT FROM 'cui2a0.audit.v1'
       OR pg_catalog.jsonb_typeof(v_after->'request_id')<>'string'
       OR (v_after->>'request_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       OR (v_after->>'request_id')::uuid='00000000-0000-0000-0000-000000000000'::uuid
       OR pg_catalog.jsonb_typeof(v_after->'changed_fields')<>'array'
       OR pg_catalog.jsonb_typeof(v_after->'updated_at')<>'string'
       OR NOT pg_catalog.isfinite((v_after->>'updated_at')::timestamptz)
       OR pg_catalog.jsonb_typeof(v_after->'contact_count')<>'number'
       OR (v_after->>'contact_count') !~ '^(0|[1-9]|10)$'
       OR pg_catalog.jsonb_typeof(v_after->'category_count')<>'number'
       OR (v_after->>'category_count') !~ '^(0|[1-9]|10)$'
       OR pg_catalog.jsonb_typeof(v_after->'has_primary_location')<>'boolean' THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    SELECT COALESCE(pg_catalog.jsonb_agg(field ORDER BY ordinal),'[]'::jsonb)
      INTO v_fields FROM pg_catalog.unnest(ARRAY[
        'entity_type','name','description','contacts','categories','primary_location'
      ]) WITH ORDINALITY AS allowed(field,ordinal)
      WHERE v_after->'changed_fields' ? field;
    IF v_fields<>v_after->'changed_fields' OR pg_catalog.jsonb_array_length(v_fields)=0 THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    IF v_a->>'action'='business_entity.draft_create' THEN
      IF v_before<>'null'::jsonb OR v_fields<>
          '["entity_type","name","description","contacts","categories","primary_location"]'::jsonb
         OR (v_a->>'reason' IS NULL OR v_a->>'reason' NOT IN (
           'BUSINESS_SUPPLIED_INFORMATION','BUSINESS_AUTHORIZED_PREPARATION')) THEN
        RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
      END IF;
    ELSE
      IF pg_catalog.jsonb_typeof(v_before)<>'object'
         OR NOT (v_before ?& ARRAY['updated_at','contact_count','category_count','has_primary_location'])
         OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(v_before))<>4
         OR pg_catalog.jsonb_typeof(v_before->'updated_at')<>'string'
         OR NOT pg_catalog.isfinite((v_before->>'updated_at')::timestamptz)
         OR (v_before->>'updated_at')::timestamptz>=(v_after->>'updated_at')::timestamptz
         OR pg_catalog.jsonb_typeof(v_before->'contact_count')<>'number'
         OR (v_before->>'contact_count') !~ '^(0|[1-9]|10)$'
         OR pg_catalog.jsonb_typeof(v_before->'category_count')<>'number'
         OR (v_before->>'category_count') !~ '^(0|[1-9]|10)$'
         OR pg_catalog.jsonb_typeof(v_before->'has_primary_location')<>'boolean'
         OR (v_a->>'reason' IS NULL OR v_a->>'reason' NOT IN ('CORRECT_DRAFT_INFORMATION','COMPLETE_DRAFT_INFORMATION')) THEN
        RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
      END IF;
    END IF;
  EXCEPTION WHEN invalid_text_representation OR invalid_datetime_format
      OR datetime_field_overflow OR invalid_parameter_value OR numeric_value_out_of_range THEN
    RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
  END;

    IF (v_after->>'request_id')::uuid IS DISTINCT FROM v_receipt.request_id
       OR (v_after->>'updated_at')::timestamptz IS DISTINCT FROM v_receipt.created_updated_at
       OR ((v_a->>'actor_user_id')::uuid IS NOT NULL
           AND (v_a->>'actor_user_id')::uuid IS DISTINCT FROM v_receipt.actor_user_id) THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    v_origin:=true;
  END IF;
  IF NOT v_origin OR v_entity.lifecycle_status<>'draft'
     OR v_entity.verification_status<>'unverified' OR v_entity.claim_status<>'unclaimed'
     OR v_entity.entity_type NOT IN ('company','contractor','supplier','store')
     OR EXISTS(SELECT 1 FROM public.business_memberships bm WHERE bm.entity_id=p_entity_id)
     OR EXISTS(SELECT 1 FROM public.subscriptions s WHERE s.entity_id=p_entity_id)
     OR EXISTS(SELECT 1 FROM public.entity_locations l WHERE l.entity_id=p_entity_id AND NOT l.is_primary) THEN
    RAISE EXCEPTION 'draft_not_editable' USING ERRCODE='P0TRA';
  END IF;
  SELECT pg_catalog.jsonb_build_object(
    'entity_type',v_entity.entity_type,'name',v_entity.name,'description',v_entity.description,
    'contacts',COALESCE((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
       'contact_type',c.contact_type,'value',c.value,'is_primary',c.is_primary)
       ORDER BY c.contact_type,c.value COLLATE "C",c.is_primary)
       FROM (SELECT contact_type,value,is_primary FROM public.entity_contacts
         WHERE entity_id=p_entity_id ORDER BY id LIMIT 11) c),'[]'::jsonb),
    'categories',COALESCE((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
       'category_id',c.category_id::text,'is_primary',c.is_primary) ORDER BY c.category_id)
       FROM (SELECT category_id,is_primary FROM public.directory_entity_categories
         WHERE entity_id=p_entity_id ORDER BY category_id LIMIT 11) c),'[]'::jsonb),
    'primary_location',COALESCE((SELECT pg_catalog.jsonb_build_object(
       'region_id',l.region_id::text,'address',l.address,'latitude',l.latitude,'longitude',l.longitude)
       FROM public.entity_locations l WHERE l.entity_id=p_entity_id AND l.is_primary),'null'::jsonb)
  ) INTO v_raw;
  BEGIN
    v_old:=business_admin_private.normalize_draft_payload(v_raw);
    IF v_old<>v_raw THEN
      RAISE EXCEPTION 'draft_not_editable' USING ERRCODE='P0TRA';
    END IF;
  EXCEPTION WHEN SQLSTATE 'P0DAT' THEN
    RAISE EXCEPTION 'draft_not_editable' USING ERRCODE='P0TRA';
  END;
  IF v_entity.updated_at IS DISTINCT FROM p_expected_updated_at THEN
    RAISE EXCEPTION 'stale_draft_version' USING ERRCODE='P0CON';
  END IF;
  IF v_old=v_payload THEN
    RETURN pg_catalog.jsonb_build_object('outcome','UNCHANGED','request_id',p_request_id,
      'entity_id',p_entity_id,'updated_at',v_entity.updated_at);
  END IF;

  -- Deterministic taxonomy lock tier; activity is checked on the locked version.
  FOR v_item IN SELECT value FROM pg_catalog.jsonb_array_elements(v_payload->'categories')
       ORDER BY (value->>'category_id')::uuid LOOP
    SELECT c.is_active INTO v_active FROM public.directory_categories c
      WHERE c.id=(v_item->>'category_id')::uuid FOR SHARE;
    IF NOT FOUND OR NOT v_active THEN
      RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
    END IF;
  END LOOP;
  IF v_payload->'primary_location'->>'region_id' IS NOT NULL THEN
    SELECT r.is_active INTO v_active FROM public.regions r
      WHERE r.id=(v_payload->'primary_location'->>'region_id')::uuid FOR SHARE;
    IF NOT FOUND OR NOT v_active THEN
      RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
    END IF;
  END IF;

  PERFORM c.id FROM public.entity_contacts c WHERE c.entity_id=p_entity_id ORDER BY c.id FOR UPDATE;
  PERFORM c.category_id FROM public.directory_entity_categories c
    WHERE c.entity_id=p_entity_id ORDER BY c.category_id FOR UPDATE;
  SELECT l.id INTO v_location_id FROM public.entity_locations l
    WHERE l.entity_id=p_entity_id AND l.is_primary FOR UPDATE;
  IF NOT business_admin_private.has_staff_business_permission('business_entities.edit_draft') THEN
    RAISE EXCEPTION 'staff_business_permission_denied' USING ERRCODE='P0PER';
  END IF;
  -- Existing BEFORE UPDATE uses now(), not clock_timestamp(). Never backdate/retain the token.
  IF pg_catalog.transaction_timestamp()<=v_entity.updated_at THEN
    RAISE EXCEPTION 'stale_draft_version' USING ERRCODE='P0CON';
  END IF;
  v_fields:='[]'::jsonb;
  FOREACH v_key IN ARRAY ARRAY['entity_type','name','description','contacts','categories','primary_location'] LOOP
    IF v_old->v_key IS DISTINCT FROM v_payload->v_key THEN
      v_fields:=v_fields||pg_catalog.jsonb_build_array(v_key);
    END IF;
  END LOOP;
  UPDATE public.directory_entities SET entity_type=v_payload->>'entity_type',
    name=v_payload->>'name',description=v_payload->>'description'
    WHERE id=p_entity_id RETURNING updated_at INTO v_updated_at;
  IF NOT pg_catalog.isfinite(v_updated_at) OR v_updated_at<=v_entity.updated_at THEN
    RAISE EXCEPTION 'stale_draft_version' USING ERRCODE='P0CON';
  END IF;
  IF v_old->'contacts' IS DISTINCT FROM v_payload->'contacts' THEN
    DELETE FROM public.entity_contacts WHERE entity_id=p_entity_id;
    INSERT INTO public.entity_contacts(entity_id,contact_type,value,is_primary)
      SELECT p_entity_id,c->>'contact_type',c->>'value',(c->>'is_primary')::boolean
      FROM pg_catalog.jsonb_array_elements(v_payload->'contacts') c;
  END IF;
  IF v_old->'categories' IS DISTINCT FROM v_payload->'categories' THEN
    DELETE FROM public.directory_entity_categories WHERE entity_id=p_entity_id;
    INSERT INTO public.directory_entity_categories(entity_id,category_id,is_primary)
      SELECT p_entity_id,(c->>'category_id')::uuid,(c->>'is_primary')::boolean
      FROM pg_catalog.jsonb_array_elements(v_payload->'categories') c;
  END IF;
  IF v_old->'primary_location' IS DISTINCT FROM v_payload->'primary_location' THEN
    IF v_payload->'primary_location'='null'::jsonb THEN
      DELETE FROM public.entity_locations WHERE entity_id=p_entity_id AND id=v_location_id AND is_primary;
    ELSIF v_location_id IS NOT NULL THEN
      UPDATE public.entity_locations SET region_id=(v_payload->'primary_location'->>'region_id')::uuid,
        address=v_payload->'primary_location'->>'address',
        latitude=(v_payload->'primary_location'->>'latitude')::numeric(9,6),
        longitude=(v_payload->'primary_location'->>'longitude')::numeric(9,6)
        WHERE entity_id=p_entity_id AND id=v_location_id AND is_primary;
    ELSE
      INSERT INTO public.entity_locations(entity_id,region_id,address,latitude,longitude,is_primary)
        VALUES(p_entity_id,(v_payload->'primary_location'->>'region_id')::uuid,
          v_payload->'primary_location'->>'address',
          (v_payload->'primary_location'->>'latitude')::numeric(9,6),
          (v_payload->'primary_location'->>'longitude')::numeric(9,6),true);
    END IF;
  END IF;
  BEGIN
    PERFORM public.append_audit_log(v_actor,'business_entity.draft_update','directory_entity',p_entity_id,
      pg_catalog.jsonb_build_object('updated_at',v_entity.updated_at,
        'contact_count',pg_catalog.jsonb_array_length(v_old->'contacts'),
        'category_count',pg_catalog.jsonb_array_length(v_old->'categories'),
        'has_primary_location',v_old->'primary_location'<>'null'::jsonb),
      pg_catalog.jsonb_build_object('format_version','cui2a0.audit.v1','request_id',p_request_id,
        'changed_fields',v_fields,'updated_at',v_updated_at,
        'contact_count',pg_catalog.jsonb_array_length(v_payload->'contacts'),
        'category_count',pg_catalog.jsonb_array_length(v_payload->'categories'),
        'has_primary_location',v_payload->'primary_location'<>'null'::jsonb),p_reason);
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'draft_audit_write_failed' USING ERRCODE='P0AUD';
  END;
  RETURN pg_catalog.jsonb_build_object('outcome','UPDATED','request_id',p_request_id,
    'entity_id',p_entity_id,'updated_at',v_updated_at);
END;
$fn$;


CREATE FUNCTION public.list_staff_business_entity_audit(
  p_entity_id uuid, p_limit integer DEFAULT 25,
  p_before_created_at timestamptz DEFAULT NULL, p_before_id uuid DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $fn$
DECLARE v_a jsonb; v_before jsonb; v_after jsonb; v_fields jsonb;
  v_items jsonb := '[]'; v_cursor jsonb := 'null'; v_count integer := 0;
  v_receipt business_admin_private.draft_create_requests%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE='P0AUT';
  END IF;
  IF NOT business_admin_private.has_staff_business_permission('business_entities.read_audit') THEN
    RAISE EXCEPTION 'staff_business_permission_denied' USING ERRCODE='P0PER';
  END IF;
  IF p_entity_id IS NULL OR p_entity_id='00000000-0000-0000-0000-000000000000'::uuid
     OR p_limit IS NULL OR p_limit NOT BETWEEN 1 AND 50
     OR (p_before_created_at IS NULL)<>(p_before_id IS NULL)
     OR NOT pg_catalog.isfinite(p_before_created_at)
     OR p_before_id='00000000-0000-0000-0000-000000000000'::uuid THEN
    RAISE EXCEPTION 'invalid_staff_business_input' USING ERRCODE='P0DAT';
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.directory_entities de WHERE de.id=p_entity_id) THEN
    RAISE EXCEPTION 'entity_not_found' USING ERRCODE='P0NOT';
  END IF;
  FOR v_a IN SELECT pg_catalog.to_jsonb(a) FROM public.audit_logs a
    WHERE a.target_id=p_entity_id AND a.target_type='directory_entity'
      AND a.action IN ('business_entity.draft_create','business_entity.draft_update')
      AND (p_before_created_at IS NULL OR (a.created_at,a.id)<(p_before_created_at,p_before_id))
    ORDER BY a.created_at DESC,a.id DESC LIMIT p_limit+1 LOOP
    v_count:=v_count+1;
    IF v_count>p_limit THEN
      v_cursor:=pg_catalog.jsonb_build_object(
        'created_at',v_items->(p_limit-1)->'created_at','id',v_items->(p_limit-1)->'audit_id');
      EXIT;
    END IF;

  -- Validate the entire typed event before using or projecting any summary.
  BEGIN
    IF v_a IS NULL OR pg_catalog.jsonb_typeof(v_a->'after_data')<>'object'
       OR (v_a->>'target_type')<>'directory_entity'
       OR (v_a->>'action') NOT IN ('business_entity.draft_create','business_entity.draft_update')
       OR NOT pg_catalog.isfinite((v_a->>'created_at')::timestamptz) THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    v_after:=v_a->'after_data'; v_before:=v_a->'before_data';
    IF NOT (v_after ?& ARRAY['format_version','request_id','changed_fields','updated_at',
        'contact_count','category_count','has_primary_location'])
       OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(v_after))<>7
       OR (v_after->>'format_version') IS DISTINCT FROM 'cui2a0.audit.v1'
       OR pg_catalog.jsonb_typeof(v_after->'request_id')<>'string'
       OR (v_after->>'request_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       OR (v_after->>'request_id')::uuid='00000000-0000-0000-0000-000000000000'::uuid
       OR pg_catalog.jsonb_typeof(v_after->'changed_fields')<>'array'
       OR pg_catalog.jsonb_typeof(v_after->'updated_at')<>'string'
       OR NOT pg_catalog.isfinite((v_after->>'updated_at')::timestamptz)
       OR pg_catalog.jsonb_typeof(v_after->'contact_count')<>'number'
       OR (v_after->>'contact_count') !~ '^(0|[1-9]|10)$'
       OR pg_catalog.jsonb_typeof(v_after->'category_count')<>'number'
       OR (v_after->>'category_count') !~ '^(0|[1-9]|10)$'
       OR pg_catalog.jsonb_typeof(v_after->'has_primary_location')<>'boolean' THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    SELECT COALESCE(pg_catalog.jsonb_agg(field ORDER BY ordinal),'[]'::jsonb)
      INTO v_fields FROM pg_catalog.unnest(ARRAY[
        'entity_type','name','description','contacts','categories','primary_location'
      ]) WITH ORDINALITY AS allowed(field,ordinal)
      WHERE v_after->'changed_fields' ? field;
    IF v_fields<>v_after->'changed_fields' OR pg_catalog.jsonb_array_length(v_fields)=0 THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    IF v_a->>'action'='business_entity.draft_create' THEN
      IF v_before<>'null'::jsonb OR v_fields<>
          '["entity_type","name","description","contacts","categories","primary_location"]'::jsonb
         OR (v_a->>'reason' IS NULL OR v_a->>'reason' NOT IN (
           'BUSINESS_SUPPLIED_INFORMATION','BUSINESS_AUTHORIZED_PREPARATION')) THEN
        RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
      END IF;
    ELSE
      IF pg_catalog.jsonb_typeof(v_before)<>'object'
         OR NOT (v_before ?& ARRAY['updated_at','contact_count','category_count','has_primary_location'])
         OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(v_before))<>4
         OR pg_catalog.jsonb_typeof(v_before->'updated_at')<>'string'
         OR NOT pg_catalog.isfinite((v_before->>'updated_at')::timestamptz)
         OR (v_before->>'updated_at')::timestamptz>=(v_after->>'updated_at')::timestamptz
         OR pg_catalog.jsonb_typeof(v_before->'contact_count')<>'number'
         OR (v_before->>'contact_count') !~ '^(0|[1-9]|10)$'
         OR pg_catalog.jsonb_typeof(v_before->'category_count')<>'number'
         OR (v_before->>'category_count') !~ '^(0|[1-9]|10)$'
         OR pg_catalog.jsonb_typeof(v_before->'has_primary_location')<>'boolean'
         OR (v_a->>'reason' IS NULL OR v_a->>'reason' NOT IN ('CORRECT_DRAFT_INFORMATION','COMPLETE_DRAFT_INFORMATION')) THEN
        RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
      END IF;
    END IF;
  EXCEPTION WHEN invalid_text_representation OR invalid_datetime_format
      OR datetime_field_overflow OR invalid_parameter_value OR numeric_value_out_of_range THEN
    RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
  END;

    -- Every projected authoring event needs established creation evidence.
    SELECT receipt.actor_user_id,receipt.request_id,receipt.payload_fingerprint,
      receipt.entity_id,receipt.created_at,receipt.created_updated_at INTO v_receipt
      FROM business_admin_private.draft_create_requests receipt WHERE receipt.entity_id=p_entity_id;
    IF NOT FOUND OR (v_a->>'action'='business_entity.draft_create' AND (
        (v_after->>'request_id')::uuid IS DISTINCT FROM v_receipt.request_id
        OR (v_after->>'updated_at')::timestamptz IS DISTINCT FROM v_receipt.created_updated_at
        OR ((v_a->>'actor_user_id')::uuid IS NOT NULL
          AND (v_a->>'actor_user_id')::uuid IS DISTINCT FROM v_receipt.actor_user_id))) THEN
      RAISE EXCEPTION 'draft_authority_invariant_conflict' USING ERRCODE='P0INV';
    END IF;
    v_items:=v_items||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'audit_id',v_a->'id','actor_user_id',v_a->'actor_user_id','action',v_a->'action',
      'created_at',v_a->'created_at','reason_code',v_a->'reason','request_id',v_after->'request_id',
      'change_summary',pg_catalog.jsonb_build_object(
        'changed_fields',v_fields,'before_updated_at',v_before->'updated_at',
        'after_updated_at',v_after->'updated_at','before_contact_count',v_before->'contact_count',
        'after_contact_count',v_after->'contact_count','before_category_count',v_before->'category_count',
        'after_category_count',v_after->'category_count',
        'before_has_primary_location',v_before->'has_primary_location',
        'after_has_primary_location',v_after->'has_primary_location')));
  END LOOP;
  RETURN pg_catalog.jsonb_build_object('items',v_items,'next_cursor',v_cursor);
END;
$fn$;

ALTER FUNCTION business_admin_private.has_staff_business_permission(text) OWNER TO postgres;
ALTER FUNCTION business_admin_private.normalize_draft_payload(jsonb) OWNER TO postgres;
ALTER FUNCTION public.guard_claim_application_insert() OWNER TO postgres;
ALTER FUNCTION public.get_staff_business_capabilities() OWNER TO postgres;
ALTER FUNCTION public.list_staff_business_entities(text,text,text,integer,timestamptz,uuid) OWNER TO postgres;
ALTER FUNCTION public.get_staff_business_entity_detail(uuid) OWNER TO postgres;
ALTER FUNCTION public.staff_create_business_draft(uuid,jsonb,text) OWNER TO postgres;
ALTER FUNCTION public.staff_update_business_draft(uuid,timestamptz,uuid,jsonb,text) OWNER TO postgres;
ALTER FUNCTION public.list_staff_business_entity_audit(uuid,integer,timestamptz,uuid) OWNER TO postgres;

REVOKE ALL ON FUNCTION business_admin_private.has_staff_business_permission(text),
  business_admin_private.normalize_draft_payload(jsonb), public.guard_claim_application_insert()
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.get_staff_business_capabilities(),
  public.list_staff_business_entities(text,text,text,integer,timestamptz,uuid),
  public.get_staff_business_entity_detail(uuid), public.staff_create_business_draft(uuid,jsonb,text),
  public.staff_update_business_draft(uuid,timestamptz,uuid,jsonb,text),
  public.list_staff_business_entity_audit(uuid,integer,timestamptz,uuid)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_staff_business_capabilities(),
  public.list_staff_business_entities(text,text,text,integer,timestamptz,uuid),
  public.get_staff_business_entity_detail(uuid), public.staff_create_business_draft(uuid,jsonb,text),
  public.staff_update_business_draft(uuid,timestamptz,uuid,jsonb,text),
  public.list_staff_business_entity_audit(uuid,integer,timestamptz,uuid)
  TO authenticated;

DO $final_assertions$
DECLARE v_owner oid := 'postgres'::pg_catalog.regrole;
  v_private oid := 'business_admin_private'::pg_catalog.regnamespace;
  v_function record; v_role record; v_guard text;
BEGIN
  IF (SELECT nspowner FROM pg_catalog.pg_namespace WHERE oid=v_private)<>v_owner
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_class
       WHERE relnamespace=v_private AND relkind='r')<>1
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc WHERE pronamespace=v_private)<>2
     OR EXISTS(SELECT 1 FROM pg_catalog.pg_policy
       WHERE polrelid='business_admin_private.draft_create_requests'::pg_catalog.regclass)
     OR NOT EXISTS(SELECT 1 FROM pg_catalog.pg_class
       WHERE oid='business_admin_private.draft_create_requests'::pg_catalog.regclass
       AND relowner=v_owner AND relrowsecurity AND NOT relforcerowsecurity)
     OR EXISTS(SELECT 1 FROM pg_catalog.pg_constraint
       WHERE conrelid='business_admin_private.draft_create_requests'::pg_catalog.regclass AND contype='f')
     OR EXISTS(SELECT 1 FROM pg_catalog.pg_publication_tables WHERE schemaname='business_admin_private') THEN
    RAISE EXCEPTION 'CUI2A0 private namespace/inventory exposure';
  END IF;
  FOR v_function IN SELECT p.oid,p.proowner,p.prosecdef,p.provolatile,p.proconfig,
       n.nspname,p.proname,COALESCE(p.proacl,pg_catalog.acldefault('f',p.proowner)) AS acl
      FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace
      WHERE n.oid=v_private OR (n.nspname='public' AND p.proname IN (
        'guard_claim_application_insert','get_staff_business_capabilities','list_staff_business_entities',
        'get_staff_business_entity_detail','staff_create_business_draft','staff_update_business_draft',
        'list_staff_business_entity_audit')) LOOP
    IF v_function.proowner<>v_owner
       OR v_function.proconfig IS DISTINCT FROM ARRAY['search_path=pg_catalog, pg_temp']
       OR (v_function.nspname='public' AND (NOT v_function.prosecdef OR v_function.provolatile<>'v'))
       OR (v_function.nspname='business_admin_private' AND v_function.prosecdef)
       OR (v_function.proname='normalize_draft_payload' AND v_function.provolatile<>'i')
       OR (v_function.proname='has_staff_business_permission' AND v_function.provolatile<>'v')
       OR EXISTS(SELECT 1 FROM pg_catalog.aclexplode(v_function.acl) a
          WHERE a.grantee<>v_owner AND (
            v_function.nspname<>'public' OR v_function.proname='guard_claim_application_insert'
            OR a.grantee<>'authenticated'::pg_catalog.regrole OR a.is_grantable
            OR a.privilege_type<>'EXECUTE')) THEN
      RAISE EXCEPTION 'CUI2A0 function owner/search_path/ACL drift';
    END IF;
    FOR v_role IN SELECT oid,rolname FROM pg_catalog.pg_roles
        WHERE rolname IN ('anon','authenticated','service_role') LOOP
      IF pg_catalog.has_function_privilege(v_role.oid,v_function.oid,'EXECUTE') IS DISTINCT FROM
         (v_role.rolname='authenticated' AND v_function.nspname='public'
           AND v_function.proname<>'guard_claim_application_insert') THEN
        RAISE EXCEPTION 'CUI2A0 effective function privilege drift';
      END IF;
    END LOOP;
  END LOOP;
  FOR v_role IN SELECT oid FROM pg_catalog.pg_roles
      WHERE rolname IN ('anon','authenticated','service_role') LOOP
    IF pg_catalog.pg_has_role(v_role.oid,v_owner,'MEMBER')
       OR pg_catalog.has_schema_privilege(v_role.oid,v_private,'USAGE,CREATE')
       OR pg_catalog.has_table_privilege(v_role.oid,
         'business_admin_private.draft_create_requests','SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       OR pg_catalog.has_any_column_privilege(v_role.oid,
         'business_admin_private.draft_create_requests','SELECT,INSERT,UPDATE,REFERENCES') THEN
      RAISE EXCEPTION 'CUI2A0 effective private privilege exposure';
    END IF;
  END LOOP;
  IF EXISTS(SELECT 1 FROM pg_catalog.pg_default_acl d
      CROSS JOIN LATERAL pg_catalog.aclexplode(d.defaclacl) a
      WHERE d.defaclrole=v_owner AND d.defaclnamespace IN (0,v_private) AND a.grantee<>v_owner)
     OR EXISTS(SELECT 1 FROM pg_catalog.aclexplode(
       COALESCE((SELECT nspacl FROM pg_catalog.pg_namespace WHERE oid=v_private),
         pg_catalog.acldefault('n',v_owner))) a WHERE a.grantee<>v_owner)
     OR EXISTS(SELECT 1 FROM pg_catalog.pg_attribute
       WHERE attrelid='business_admin_private.draft_create_requests'::pg_catalog.regclass
       AND attnum>0 AND attacl IS NOT NULL) THEN
    RAISE EXCEPTION 'CUI2A0 default/schema/column privilege exposure';
  END IF;
  SELECT prosrc INTO v_guard FROM pg_catalog.pg_proc
    WHERE oid='public.guard_claim_application_insert()'::pg_catalog.regprocedure;
  IF v_guard NOT LIKE '%WHERE de.id=NEW.target_entity_id FOR UPDATE;%'
     OR v_guard NOT LIKE '%IF NOT FOUND THEN%'
     OR v_guard NOT LIKE '%claim target not found%'
     OR v_guard NOT LIKE '%FROM business_admin_private.draft_create_requests AS receipt%'
     OR v_guard NOT LIKE '%WHERE receipt.entity_id=NEW.target_entity_id%'
     OR v_guard NOT LIKE '%target entity is not claimable%'
     OR NOT EXISTS(SELECT 1 FROM pg_catalog.pg_trigger t
       WHERE t.tgrelid='public.business_applications'::pg_catalog.regclass
       AND t.tgname='trigger_guard_claim_insert' AND t.tgtype=7 AND t.tgenabled='O'
       AND t.tgfoid='public.guard_claim_application_insert()'::pg_catalog.regprocedure) THEN
    RAISE EXCEPTION 'CUI2A0 canonical CLAIM isolation assertion failed';
  END IF;
  IF business_admin_private.normalize_draft_payload(
       '{"entity_type":"company","name":"  Draft  ","description":"","contacts":[],"categories":[],"primary_location":null}'::jsonb)
     IS DISTINCT FROM
       '{"entity_type":"company","name":"Draft","description":null,"contacts":[],"categories":[],"primary_location":null}'::jsonb THEN
    RAISE EXCEPTION 'CUI2A0 structural normalization assertion failed';
  END IF;
END;
$final_assertions$;

