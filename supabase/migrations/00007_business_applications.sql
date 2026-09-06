-- A5.2 — Migration 00007: business_applications + application_contacts
-- + application_visits + application_notes
--
-- Business application workflow (NEW / CLAIM) with operational history.
-- Application status is intentionally SEPARATE from directory entity
-- verification_status: an application passing is one thing; the Directory
-- entity's verification_badge state is another.

-- ============================================================
-- business_applications
-- ============================================================
CREATE TABLE public.business_applications (
  id                  uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  applicant_user_id   uuid    REFERENCES auth.users(id) ON DELETE SET NULL,
  application_type    text    NOT NULL CHECK (application_type IN ('NEW', 'CLAIM')),
  target_entity_id    uuid    REFERENCES public.directory_entities(id) ON DELETE SET NULL,
  status              text    NOT NULL DEFAULT 'DRAFT'
                        CHECK (status IN (
                          'DRAFT', 'SUBMITTED', 'UNDER_REVIEW',
                          'NEEDS_CORRECTION', 'CONTACTED', 'VISIT_SCHEDULED',
                          'APPROVED', 'REJECTED', 'ACTIVATED'
                        )),
  -- Payload: candidate user-provided profile/contact/geography for a NEW
  -- application (before an entity row exists). JSONB keeps this flexible
  -- without a hard-coded schema before UI/workflow is designed.
  metadata            jsonb,
  reviewed_by_user_id uuid    REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at         timestamptz,
  return_reason       text,
  rejection_reason    text,
  approved_at         timestamptz,
  activated_at        timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_app_requires_target_for_claim
    CHECK (
      (application_type = 'CLAIM' AND target_entity_id IS NOT NULL)
      OR
      (application_type = 'NEW')
    ),
  CONSTRAINT chk_application_review_together
    CHECK (
      (reviewed_by_user_id IS NULL) = (reviewed_at IS NULL)
    )
);

CREATE TRIGGER trigger_set_updated_at
  BEFORE UPDATE ON public.business_applications
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

CREATE INDEX idx_business_applications_applicant
  ON public.business_applications (applicant_user_id);
CREATE INDEX idx_business_applications_target_entity
  ON public.business_applications (target_entity_id);
CREATE INDEX idx_business_applications_status
  ON public.business_applications (status);

COMMENT ON TABLE public.business_applications IS
  'Business application lifecycle. application_type: NEW (create new entity) '
  'or CLAIM (claim existing entity). status is a full operational lifecycle '
  '(DRAFT→SUBMITTED→UNDER_REVIEW→NEEDS_CORRECTION→CONTACTED→VISIT_SCHEDULED→'
  'APPROVED→REJECTED→ACTIVATED). Do not collapse this into the Directory '
  'entity verification_status; the two are orthogonal.';

-- ============================================================
-- application_contacts (operational history: who/when/result)
-- ============================================================
CREATE TABLE public.application_contacts (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id    uuid        NOT NULL
                      REFERENCES public.business_applications(id) ON DELETE CASCADE,
  contacted_by_user_id uuid     NOT NULL
                      REFERENCES auth.users(id) ON DELETE RESTRICT,
  contacted_at      timestamptz NOT NULL DEFAULT now(),
  contact_type      text        NOT NULL CHECK (contact_type IN (
                      'phone', 'whatsapp', 'email', 'visit', 'other'
                    )),
  result            text,
  notes             text
);

CREATE INDEX idx_application_contacts_application_id
  ON public.application_contacts (application_id);

COMMENT ON TABLE public.application_contacts IS
  'Operational history of contact attempts on a business application: '
  'who contacted, when, via what channel, and the outcome.';

-- ============================================================
-- application_visits (site-visit scheduling/completion)
-- ============================================================
CREATE TABLE public.application_visits (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id    uuid        NOT NULL
                      REFERENCES public.business_applications(id) ON DELETE CASCADE,
  scheduled_at      timestamptz NOT NULL,
  completed_at      timestamptz,
  status            text        NOT NULL DEFAULT 'scheduled'
                      CHECK (status IN (
                        'scheduled', 'completed', 'cancelled', 'no_show'
                      )),
  location          text,
  notes             text,
  visited_by_user_id uuid       REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_visit_completed_after_scheduled
    CHECK (completed_at IS NULL OR completed_at >= scheduled_at)
);

CREATE TRIGGER trigger_set_updated_at
  BEFORE UPDATE ON public.application_visits
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

CREATE INDEX idx_application_visits_application_id
  ON public.application_visits (application_id);

COMMENT ON TABLE public.application_visits IS
  'Operational history of site visits for a business application: '
  'scheduled time, completion, outcome, notes.';

-- ============================================================
-- application_notes (free-form operational notes)
-- ============================================================
CREATE TABLE public.application_notes (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid       NOT NULL
                  REFERENCES public.business_applications(id) ON DELETE CASCADE,
  author_user_id uuid       REFERENCES auth.users(id) ON DELETE SET NULL,
  body          text        NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_application_notes_body_non_empty
    CHECK (length(trim(body)) > 0)
);

CREATE INDEX idx_application_notes_application_id
  ON public.application_notes (application_id);

COMMENT ON TABLE public.application_notes IS
  'Free-form operational notes attached to a business application, preserving '
  'staff workflow history. No UI/workflow UI implemented in A5.2.';