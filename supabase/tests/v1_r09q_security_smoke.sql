BEGIN;

SELECT plan(12);

-- Local-only deterministic identities. These fixtures exist only inside this
-- transaction and are removed by the final ROLLBACK.
INSERT INTO auth.users (id, email, created_at, updated_at)
VALUES
  ('10000000-0000-0000-0000-000000000001', 'r09q-a@example.invalid', now(), now()),
  ('10000000-0000-0000-0000-000000000002', 'r09q-b@example.invalid', now(), now()),
  ('10000000-0000-0000-0000-000000000003', 'r09q-staff@example.invalid', now(), now());

INSERT INTO public.profiles (user_id, display_name)
VALUES
  ('10000000-0000-0000-0000-000000000001', 'R09Q User A'),
  ('10000000-0000-0000-0000-000000000002', 'R09Q User B'),
  ('10000000-0000-0000-0000-000000000003', 'R09Q Staff');

INSERT INTO public.staff_memberships (user_id, role_id)
SELECT '10000000-0000-0000-0000-000000000003', id
FROM public.roles
WHERE code = 'application_reviewer';

SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000001',
  true
);

SELECT lives_ok(
  $$
    UPDATE public.profiles
    SET display_name = 'R09Q User A Updated'
    WHERE user_id = '10000000-0000-0000-0000-000000000001'
  $$,
  'User A can update the permitted own-profile row'
);

SELECT results_eq(
  $$
    SELECT display_name
    FROM public.profiles
    WHERE user_id = '10000000-0000-0000-0000-000000000001'
  $$,
  $$ VALUES ('R09Q User A Updated'::text) $$,
  'User A can read the permitted own-profile row'
);

SELECT set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000002',
  true
);

SELECT results_eq(
  $$
    SELECT user_id
    FROM public.profiles
    WHERE user_id = '10000000-0000-0000-0000-000000000001'
  $$,
  $$ SELECT NULL::uuid WHERE false $$,
  'User B cannot read User A profile row'
);

SELECT results_eq(
  $$
    UPDATE public.profiles
    SET display_name = 'Unauthorized change'
    WHERE user_id = '10000000-0000-0000-0000-000000000001'
    RETURNING user_id
  $$,
  $$ SELECT NULL::uuid WHERE false $$,
  'User B cannot update User A profile row'
);

RESET ROLE;
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claim.sub', '', true);

SELECT throws_ok(
  $$
    UPDATE public.profiles
    SET display_name = 'Anonymous change'
    WHERE user_id = '10000000-0000-0000-0000-000000000001'
  $$,
  '42501',
  'permission denied for table profiles',
  'anon cannot mutate protected profiles'
);

RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000001',
  true
);

SELECT results_eq(
  $$
    SELECT (
      public.create_new_business_application(
        '{"name":"R09Q Synthetic Business","entity_type":"company"}'::jsonb
      )
    ).applicant_user_id
  $$,
  $$ VALUES ('10000000-0000-0000-0000-000000000001'::uuid) $$,
  'authorized applicant can create an own DRAFT through the protected RPC'
);

SELECT set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000002',
  true
);

SELECT results_eq(
  $$
    SELECT id
    FROM public.business_applications
    WHERE applicant_user_id = '10000000-0000-0000-0000-000000000001'
  $$,
  $$ SELECT NULL::uuid WHERE false $$,
  'different authenticated user cannot read the applicant protected row'
);

SELECT throws_ok(
  $$
    UPDATE public.business_applications
    SET status = 'SUBMITTED'
    WHERE applicant_user_id = '10000000-0000-0000-0000-000000000001'
  $$,
  '42501',
  'permission denied for table business_applications',
  'authenticated clients cannot use the revoked direct application update path'
);

SELECT set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000003',
  true
);

SELECT ok(
  public.get_staff_application_capabilities()
    -> 'permissions' @> '["business_applications.read"]'::jsonb,
  'properly provisioned staff receives the read capability'
);

SELECT is(
  jsonb_typeof(public.list_staff_business_applications()),
  'object',
  'capable staff can invoke the protected staff queue RPC'
);

SELECT set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000002',
  true
);

SELECT throws_ok(
  $$ SELECT public.list_staff_business_applications() $$,
  'P0PER',
  'staff_permission_denied',
  'ordinary authenticated user is denied the protected staff queue RPC'
);

RESET ROLE;
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claim.sub', '', true);

SELECT throws_ok(
  $$
    SELECT public.create_new_business_application(
      '{"name":"Anonymous Business","entity_type":"company"}'::jsonb
    )
  $$,
  '42501',
  'permission denied for function create_new_business_application',
  'anon cannot execute the protected SECURITY DEFINER creation RPC'
);

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
