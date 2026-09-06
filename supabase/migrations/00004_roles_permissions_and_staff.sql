-- A5.2 — Migration 00004: role_permissions + staff_memberships
-- (manager/employee authorization; Directory entities are in 00005).

-- ============================================================
-- role_permissions (many-to-many: roles ↔ permissions)
-- ============================================================
CREATE TABLE public.role_permissions (
  role_id       uuid NOT NULL REFERENCES public.roles(id)        ON DELETE RESTRICT,
  permission_id uuid NOT NULL REFERENCES public.permissions(id)  ON DELETE RESTRICT,
  PRIMARY KEY (role_id, permission_id)
);

-- Index for "which roles have this permission?" lookups.
CREATE INDEX idx_role_permissions_permission_id
  ON public.role_permissions (permission_id);

COMMENT ON TABLE public.role_permissions IS
  'Many-to-many: staff roles ↔ permissions. ON DELETE RESTRICT prevents '
  'deleting a role or permission that is still assigned.';

-- ============================================================
-- staff_memberships (Civilpedia employee ↔ staff role)
-- ============================================================
-- One user may hold multiple staff roles; one role may be held by many users.
CREATE TABLE public.staff_memberships (
  user_id      uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role_id      uuid        NOT NULL REFERENCES public.roles(id) ON DELETE RESTRICT,
  is_active    boolean     NOT NULL DEFAULT true,
  effective_at timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (user_id, role_id),

  CONSTRAINT chk_staff_memberships_dates
    CHECK (expires_at IS NULL OR expires_at > effective_at)
);

COMMENT ON TABLE public.staff_memberships IS
  'Civilpedia employee identity ↔ staff role. Each row represents an '
  'active or historical assignment. ON DELETE CASCADE: removing the auth user '
  'removes their staff memberships. RESTRICT on role prevents deleting '
  'a role with active memberships.';
