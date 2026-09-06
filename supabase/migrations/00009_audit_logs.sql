-- A5.2 — Migration 00009: audit_logs
--
-- Foundation for sensitive-action audit records. Designed as append-only
-- conceptually. Actual RLS / server-side enforcement arrives in A5.3+.

CREATE TABLE public.audit_logs (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id uuid       REFERENCES auth.users(id) ON DELETE SET NULL,
  action       text        NOT NULL,
  target_type  text        NOT NULL,
  target_id    uuid,
  before_data  jsonb,
  after_data   jsonb,
  reason       text,
  created_at   timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_audit_logs_action_non_empty
    CHECK (length(trim(action)) > 0),
  CONSTRAINT chk_audit_logs_target_type_non_empty
    CHECK (length(trim(target_type)) > 0)
);

CREATE INDEX idx_audit_logs_actor_user_id
  ON public.audit_logs (actor_user_id);
CREATE INDEX idx_audit_logs_target
  ON public.audit_logs (target_type, target_id);
CREATE INDEX idx_audit_logs_created_at
  ON public.audit_logs (created_at);

COMMENT ON TABLE public.audit_logs IS
  'Append-only audit record for sensitive actions: actor user, action, '
  'target type/id, structured JSONB before/after snapshots, reason, timestamp. '
  'No UPDATE/DELETE triggers by design — inserts only. RLS/server append '
  'enforcement arrives in A5.3+.';