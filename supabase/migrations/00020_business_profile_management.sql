-- V1-R06 Part 1 — secure business/provider profile management.
--
-- Public Directory tables remain SELECT-only for Data API roles. OWNER and
-- ADMIN profile management is exposed only through the two narrow SECURITY
-- DEFINER RPCs below. Identity comes from auth.uid(), business authority comes
-- only from business_memberships through has_business_management_access(),
-- and one update is one atomic transaction.

-- ============================================================
-- Part 1 — Internal authoritative management projection
-- ============================================================

CREATE OR REPLACE FUNCTION public.managed_business_profile_projection(
  p_entity_id uuid
)
RETURNS jsonb
LANGUAGE sql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
  SELECT jsonb_build_object(
    'entity', jsonb_build_object(
      'id', de.id,
      'entity_type', de.entity_type,
      'name', de.name,
      'description', de.description,
      'lifecycle_status', de.lifecycle_status,
      'verification_status', de.verification_status,
      'claim_status', de.claim_status,
      'created_at', de.created_at,
      'updated_at', de.updated_at
    ),
    'contacts', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', ec.id,
          'contact_type', ec.contact_type,
          'value', ec.value,
          'is_primary', ec.is_primary
        ) ORDER BY ec.contact_type, ec.is_primary DESC, ec.id
      )
      FROM public.entity_contacts ec
      WHERE ec.entity_id = de.id
    ), '[]'::jsonb),
    'primary_location', (
      SELECT jsonb_build_object(
        'id', el.id,
        'region_id', el.region_id,
        'region_code', r.code,
        'region_name_ar', r.name_ar,
        'region_name_en', r.name_en,
        'address', el.address,
        'latitude', el.latitude,
        'longitude', el.longitude,
        'is_primary', el.is_primary
      )
      FROM public.entity_locations el
      LEFT JOIN public.regions r ON r.id = el.region_id
      WHERE el.entity_id = de.id
        AND el.is_primary
      ORDER BY el.id
      LIMIT 1
    ),
    'categories', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'category_id', dec.category_id,
          'code', dc.code,
          'name_ar', dc.name_ar,
          'name_en', dc.name_en,
          'is_primary', dec.is_primary
        ) ORDER BY dec.is_primary DESC, dc.code, dec.category_id
      )
      FROM public.directory_entity_categories dec
      JOIN public.directory_categories dc ON dc.id = dec.category_id
      WHERE dec.entity_id = de.id
    ), '[]'::jsonb)
  )
  FROM public.directory_entities de
  WHERE de.id = p_entity_id;
$fn$;

COMMENT ON FUNCTION public.managed_business_profile_projection(uuid) IS
  'V1-R06 internal authoritative profile projection. Includes no membership '
  'roster, user identity, application, staff, billing, or media mutation data. '
  'Not executable by client roles.';

REVOKE EXECUTE ON FUNCTION public.managed_business_profile_projection(uuid)
  FROM PUBLIC, anon, authenticated;

-- ============================================================
-- Part 2 — OWNER/ADMIN management read
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_managed_business_profile(
  p_entity_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_actor uuid := auth.uid();
  v_result jsonb;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.directory_entities de WHERE de.id = p_entity_id
  ) THEN
    RAISE EXCEPTION 'entity_not_found' USING ERRCODE = 'P0NOT';
  END IF;

  IF NOT public.has_business_management_access(p_entity_id) THEN
    RAISE EXCEPTION 'business_management_permission_denied'
      USING ERRCODE = 'P0PER';
  END IF;

  v_result := public.managed_business_profile_projection(p_entity_id);
  IF v_result IS NULL THEN
    RAISE EXCEPTION 'entity_not_found' USING ERRCODE = 'P0NOT';
  END IF;
  RETURN v_result;
END;
$fn$;

COMMENT ON FUNCTION public.get_managed_business_profile(uuid) IS
  'V1-R06 OWNER/ADMIN management read for an existing canonical Directory '
  'entity. Uses auth.uid() plus business_memberships and can return authorized '
  'draft/inactive/suspended profiles hidden by public Directory RLS.';

REVOKE EXECUTE ON FUNCTION public.get_managed_business_profile(uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_managed_business_profile(uuid)
  TO authenticated;

-- ============================================================
-- Part 3 — Atomic OWNER/ADMIN profile mutation
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_managed_business_profile(
  p_entity_id uuid,
  p_expected_updated_at timestamptz,
  p_name text,
  p_description text,
  p_contacts jsonb,
  p_primary_location jsonb,
  p_categories jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_actor uuid := auth.uid();
  v_entity public.directory_entities%ROWTYPE;
  v_old_primary public.entity_locations%ROWTYPE;
  v_had_primary boolean := false;
  v_name text;
  v_description text;
  v_contacts jsonb := COALESCE(p_contacts, '[]'::jsonb);
  v_categories jsonb := COALESCE(p_categories, '[]'::jsonb);
  v_location jsonb := p_primary_location;
  v_item jsonb;
  v_contact_type text;
  v_contact_value text;
  v_contact_primary boolean;
  v_contact_key text;
  v_seen_contacts text[] := ARRAY[]::text[];
  v_primary_contact_types text[] := ARRAY[]::text[];
  v_category_id uuid;
  v_category_primary boolean;
  v_seen_categories uuid[] := ARRAY[]::uuid[];
  v_primary_category_count integer := 0;
  v_region_id uuid;
  v_address text;
  v_latitude numeric;
  v_longitude numeric;
  v_location_present boolean := false;
  v_sensitive_changed boolean := false;
  v_before_audit jsonb;
  v_after_audit jsonb;
  v_result jsonb;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'unauthenticated' USING ERRCODE = 'P0AUT';
  END IF;

  SELECT de.* INTO v_entity
    FROM public.directory_entities de
   WHERE de.id = p_entity_id
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'entity_not_found' USING ERRCODE = 'P0NOT';
  END IF;

  IF NOT public.has_business_management_access(p_entity_id) THEN
    RAISE EXCEPTION 'business_management_permission_denied'
      USING ERRCODE = 'P0PER';
  END IF;

  IF p_expected_updated_at IS NULL THEN
    RAISE EXCEPTION 'expected_updated_at_required' USING ERRCODE = 'P0DAT';
  END IF;
  IF v_entity.updated_at IS DISTINCT FROM p_expected_updated_at THEN
    RAISE EXCEPTION 'stale_profile_version' USING ERRCODE = 'P0CON';
  END IF;

  v_name := trim(p_name);
  IF p_name IS NULL OR char_length(v_name) < 1 OR char_length(v_name) > 160 THEN
    RAISE EXCEPTION 'invalid_name' USING ERRCODE = 'P0DAT';
  END IF;

  v_description := NULLIF(trim(p_description), '');
  IF v_description IS NOT NULL AND char_length(v_description) > 2000 THEN
    RAISE EXCEPTION 'invalid_description' USING ERRCODE = 'P0DAT';
  END IF;

  IF jsonb_typeof(v_contacts) IS DISTINCT FROM 'array'
     OR jsonb_array_length(v_contacts) > 10 THEN
    RAISE EXCEPTION 'invalid_contacts' USING ERRCODE = 'P0DAT';
  END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(v_contacts)
  LOOP
    IF jsonb_typeof(v_item) IS DISTINCT FROM 'object'
       OR EXISTS (
         SELECT 1 FROM jsonb_object_keys(v_item) AS k(key_name)
          WHERE key_name NOT IN ('contact_type', 'value', 'is_primary')
       )
       OR jsonb_typeof(v_item -> 'contact_type') IS DISTINCT FROM 'string'
       OR jsonb_typeof(v_item -> 'value') IS DISTINCT FROM 'string'
       OR (
         v_item ? 'is_primary'
         AND jsonb_typeof(v_item -> 'is_primary') IS DISTINCT FROM 'boolean'
       ) THEN
      RAISE EXCEPTION 'invalid_contact_payload' USING ERRCODE = 'P0DAT';
    END IF;

    v_contact_type := lower(trim(v_item ->> 'contact_type'));
    v_contact_value := trim(v_item ->> 'value');
    v_contact_primary := COALESCE((v_item ->> 'is_primary')::boolean, false);

    IF v_contact_type NOT IN ('phone', 'whatsapp', 'email', 'website', 'other')
       OR char_length(v_contact_value) = 0 THEN
      RAISE EXCEPTION 'invalid_contact' USING ERRCODE = 'P0DAT';
    END IF;

    IF v_contact_type IN ('phone', 'whatsapp') AND (
      char_length(v_contact_value) > 32
      OR v_contact_value !~ '^[0-9+(). /-]+$'
      OR char_length(regexp_replace(v_contact_value, '[^0-9]', '', 'g')) < 3
    ) THEN
      RAISE EXCEPTION 'invalid_phone_contact' USING ERRCODE = 'P0DAT';
    ELSIF v_contact_type = 'email' AND (
      char_length(v_contact_value) > 254
      OR v_contact_value !~* '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
    ) THEN
      RAISE EXCEPTION 'invalid_email_contact' USING ERRCODE = 'P0DAT';
    ELSIF v_contact_type = 'website' AND (
      char_length(v_contact_value) > 2048
      OR v_contact_value !~* '^https?://[^[:space:]]+$'
    ) THEN
      RAISE EXCEPTION 'invalid_website_contact' USING ERRCODE = 'P0DAT';
    ELSIF v_contact_type = 'other' AND char_length(v_contact_value) > 500 THEN
      RAISE EXCEPTION 'invalid_other_contact' USING ERRCODE = 'P0DAT';
    END IF;

    v_contact_key := v_contact_type || E'\x1f' || lower(v_contact_value);
    IF v_contact_key = ANY(v_seen_contacts) THEN
      RAISE EXCEPTION 'duplicate_contact' USING ERRCODE = 'P0DAT';
    END IF;
    v_seen_contacts := array_append(v_seen_contacts, v_contact_key);

    IF v_contact_primary THEN
      IF v_contact_type = ANY(v_primary_contact_types) THEN
        RAISE EXCEPTION 'duplicate_primary_contact_type'
          USING ERRCODE = 'P0DAT';
      END IF;
      v_primary_contact_types := array_append(
        v_primary_contact_types,
        v_contact_type
      );
    END IF;
  END LOOP;

  IF jsonb_typeof(v_categories) IS DISTINCT FROM 'array'
     OR jsonb_array_length(v_categories) > 10 THEN
    RAISE EXCEPTION 'invalid_categories' USING ERRCODE = 'P0DAT';
  END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(v_categories)
  LOOP
    IF jsonb_typeof(v_item) IS DISTINCT FROM 'object'
       OR EXISTS (
         SELECT 1 FROM jsonb_object_keys(v_item) AS k(key_name)
          WHERE key_name NOT IN ('category_id', 'is_primary')
       )
       OR jsonb_typeof(v_item -> 'category_id') IS DISTINCT FROM 'string'
       OR (
         v_item ? 'is_primary'
         AND jsonb_typeof(v_item -> 'is_primary') IS DISTINCT FROM 'boolean'
       ) THEN
      RAISE EXCEPTION 'invalid_category_payload' USING ERRCODE = 'P0DAT';
    END IF;

    BEGIN
      v_category_id := (v_item ->> 'category_id')::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'invalid_category_id' USING ERRCODE = 'P0DAT';
    END;
    v_category_primary := COALESCE((v_item ->> 'is_primary')::boolean, false);

    IF v_category_id = ANY(v_seen_categories) THEN
      RAISE EXCEPTION 'duplicate_category' USING ERRCODE = 'P0DAT';
    END IF;
    v_seen_categories := array_append(v_seen_categories, v_category_id);
    IF v_category_primary THEN
      v_primary_category_count := v_primary_category_count + 1;
      IF v_primary_category_count > 1 THEN
        RAISE EXCEPTION 'multiple_primary_categories'
          USING ERRCODE = 'P0DAT';
      END IF;
    END IF;

    IF NOT EXISTS (
      SELECT 1
        FROM public.directory_categories dc
       WHERE dc.id = v_category_id
         AND dc.is_active
    ) THEN
      RAISE EXCEPTION 'inactive_or_unknown_category'
        USING ERRCODE = 'P0DAT';
    END IF;
  END LOOP;

  SELECT el.* INTO v_old_primary
    FROM public.entity_locations el
   WHERE el.entity_id = p_entity_id
     AND el.is_primary
   ORDER BY el.id
   LIMIT 1;
  v_had_primary := FOUND;

  IF v_location IS NOT NULL AND jsonb_typeof(v_location) <> 'null' THEN
    IF jsonb_typeof(v_location) IS DISTINCT FROM 'object'
       OR EXISTS (
         SELECT 1 FROM jsonb_object_keys(v_location) AS k(key_name)
          WHERE key_name NOT IN ('region_id', 'address', 'latitude', 'longitude')
       )
       OR (
         v_location ? 'region_id'
         AND jsonb_typeof(v_location -> 'region_id') NOT IN ('string', 'null')
       )
       OR (
         v_location ? 'address'
         AND jsonb_typeof(v_location -> 'address') NOT IN ('string', 'null')
       )
       OR (
         v_location ? 'latitude'
         AND jsonb_typeof(v_location -> 'latitude') NOT IN ('number', 'null')
       )
       OR (
         v_location ? 'longitude'
         AND jsonb_typeof(v_location -> 'longitude') NOT IN ('number', 'null')
       ) THEN
      RAISE EXCEPTION 'invalid_primary_location_payload'
        USING ERRCODE = 'P0DAT';
    END IF;

    BEGIN
      v_region_id := NULLIF(v_location ->> 'region_id', '')::uuid;
      v_latitude := (v_location ->> 'latitude')::numeric;
      v_longitude := (v_location ->> 'longitude')::numeric;
    EXCEPTION
      WHEN invalid_text_representation OR numeric_value_out_of_range THEN
        RAISE EXCEPTION 'invalid_primary_location_value'
          USING ERRCODE = 'P0DAT';
    END;
    v_address := NULLIF(trim(v_location ->> 'address'), '');

    IF v_address IS NOT NULL AND char_length(v_address) > 500 THEN
      RAISE EXCEPTION 'invalid_address' USING ERRCODE = 'P0DAT';
    END IF;
    IF (v_latitude IS NULL) <> (v_longitude IS NULL)
       OR (v_latitude IS NOT NULL AND (v_latitude < -90 OR v_latitude > 90))
       OR (v_longitude IS NOT NULL AND (v_longitude < -180 OR v_longitude > 180)) THEN
      RAISE EXCEPTION 'invalid_coordinates' USING ERRCODE = 'P0DAT';
    END IF;
    IF v_region_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.regions r
       WHERE r.id = v_region_id
         AND r.is_active
    ) THEN
      RAISE EXCEPTION 'inactive_or_unknown_region' USING ERRCODE = 'P0DAT';
    END IF;
    IF v_region_id IS NULL AND v_address IS NULL AND v_latitude IS NULL THEN
      RAISE EXCEPTION 'empty_primary_location' USING ERRCODE = 'P0DAT';
    END IF;
    v_location_present := true;
  END IF;

  v_sensitive_changed := v_entity.name IS DISTINCT FROM v_name;
  IF v_location_present THEN
    v_sensitive_changed := v_sensitive_changed
      OR NOT v_had_primary
      OR v_old_primary.region_id IS DISTINCT FROM v_region_id
      OR v_old_primary.address IS DISTINCT FROM v_address
      OR v_old_primary.latitude IS DISTINCT FROM v_latitude
      OR v_old_primary.longitude IS DISTINCT FROM v_longitude;
  ELSE
    v_sensitive_changed := v_sensitive_changed OR v_had_primary;
  END IF;

  v_before_audit := jsonb_build_object(
    'updated_at', v_entity.updated_at,
    'verification_status', v_entity.verification_status,
    'contact_count', (
      SELECT count(*) FROM public.entity_contacts ec
       WHERE ec.entity_id = p_entity_id
    ),
    'has_primary_location', v_had_primary,
    'category_count', (
      SELECT count(*) FROM public.directory_entity_categories dec
       WHERE dec.entity_id = p_entity_id
    )
  );

  UPDATE public.directory_entities de
     SET name = v_name,
         description = v_description,
         verification_status = CASE
           WHEN de.verification_status = 'verified' AND v_sensitive_changed
             THEN 'pending'
           ELSE de.verification_status
         END,
         updated_at = clock_timestamp()
   WHERE de.id = p_entity_id
   RETURNING de.* INTO v_entity;

  DELETE FROM public.entity_contacts ec WHERE ec.entity_id = p_entity_id;
  FOR v_item IN SELECT value FROM jsonb_array_elements(v_contacts)
  LOOP
    INSERT INTO public.entity_contacts (
      entity_id, contact_type, value, is_primary
    ) VALUES (
      p_entity_id,
      lower(trim(v_item ->> 'contact_type')),
      trim(v_item ->> 'value'),
      COALESCE((v_item ->> 'is_primary')::boolean, false)
    );
  END LOOP;

  IF v_location_present THEN
    IF v_had_primary THEN
      UPDATE public.entity_locations el
         SET region_id = v_region_id,
             address = v_address,
             latitude = v_latitude,
             longitude = v_longitude,
             is_primary = true
       WHERE el.id = v_old_primary.id;
    ELSE
      INSERT INTO public.entity_locations (
        entity_id, region_id, address, latitude, longitude, is_primary
      ) VALUES (
        p_entity_id, v_region_id, v_address, v_latitude, v_longitude, true
      );
    END IF;
  ELSIF v_had_primary THEN
    -- SQL NULL / JSON null means clear only the primary location. Additional
    -- non-primary historical branches remain untouched.
    DELETE FROM public.entity_locations el WHERE el.id = v_old_primary.id;
  END IF;

  DELETE FROM public.directory_entity_categories dec
   WHERE dec.entity_id = p_entity_id;
  FOR v_item IN SELECT value FROM jsonb_array_elements(v_categories)
  LOOP
    INSERT INTO public.directory_entity_categories (
      entity_id, category_id, is_primary
    ) VALUES (
      p_entity_id,
      (v_item ->> 'category_id')::uuid,
      COALESCE((v_item ->> 'is_primary')::boolean, false)
    );
  END LOOP;

  v_after_audit := jsonb_build_object(
    'updated_at', v_entity.updated_at,
    'verification_status', v_entity.verification_status,
    'contact_count', jsonb_array_length(v_contacts),
    'has_primary_location', v_location_present,
    'category_count', jsonb_array_length(v_categories),
    'sensitive_identity_changed', v_sensitive_changed
  );

  PERFORM public.append_audit_log(
    v_actor,
    'business_profile.update',
    'directory_entity',
    p_entity_id,
    v_before_audit,
    v_after_audit,
    NULL
  );

  v_result := public.managed_business_profile_projection(p_entity_id);
  IF v_result IS NULL THEN
    RAISE EXCEPTION 'entity_not_found' USING ERRCODE = 'P0NOT';
  END IF;
  RETURN v_result;
END;
$fn$;

COMMENT ON FUNCTION public.update_managed_business_profile(
  uuid, timestamptz, text, text, jsonb, jsonb, jsonb
) IS
  'V1-R06 OWNER/ADMIN atomic profile mutation. Supports name, description, '
  'replace-all contacts, one primary location, and replace-all active category '
  'assignments. Uses expected updated_at concurrency and derives verified to '
  'pending for material name/primary-location changes. No status, identity, '
  'membership, taxonomy, additional-location, or media input is accepted.';

REVOKE EXECUTE ON FUNCTION public.update_managed_business_profile(
  uuid, timestamptz, text, text, jsonb, jsonb, jsonb
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.update_managed_business_profile(
  uuid, timestamptz, text, text, jsonb, jsonb, jsonb
) TO authenticated;
