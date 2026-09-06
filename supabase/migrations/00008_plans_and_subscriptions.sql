-- A5.2 — Migration 00008: plans + subscriptions
--
-- Foundation only. No payments. A subscription is linked to a Directory
-- Entity (not to a user). Subscription ≠ verification; Subscription ≠
-- sponsorship; Founding Partner is a separate marketing concept and is
-- intentionally NOT modeled here.

-- ============================================================
-- plans
-- ============================================================
CREATE TABLE public.plans (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  code        text        NOT NULL UNIQUE,
  name        text        NOT NULL,
  description text,
  is_active   boolean     NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trigger_set_updated_at
  BEFORE UPDATE ON public.plans
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

COMMENT ON TABLE public.plans IS
  'Commercial plan catalog (Foundation). Plans are referenced by '
  'subscriptions. No payments and no seeding in A5.2.';

-- ============================================================
-- subscriptions
-- ============================================================
CREATE TABLE public.subscriptions (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id   uuid        NOT NULL
                REFERENCES public.directory_entities(id) ON DELETE RESTRICT,
  plan_id     uuid        NOT NULL
                REFERENCES public.plans(id) ON DELETE RESTRICT,
  status      text        NOT NULL DEFAULT 'active'
                CHECK (status IN (
                  'trialing', 'active', 'past_due', 'canceled', 'paused'
                )),
  started_at  timestamptz NOT NULL,
  ends_at     timestamptz,
  price_paid  numeric(12, 2),
  currency    text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_subscription_dates
    CHECK (ends_at IS NULL OR ends_at >= started_at)
);

CREATE TRIGGER trigger_set_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

CREATE INDEX idx_subscriptions_entity_id
  ON public.subscriptions (entity_id);
CREATE INDEX idx_subscriptions_plan_id
  ON public.subscriptions (plan_id);
CREATE INDEX idx_subscriptions_status
  ON public.subscriptions (status);

COMMENT ON TABLE public.subscriptions IS
  'A paid-plan subscription linked to a Directory Entity. status is a '
  'subscription lifecycle value and is orthogonal to Directory verification. '
  'No payment processing in A5.2. Founding Partner / sponsorship are separate '
  'concepts and are not represented here.';