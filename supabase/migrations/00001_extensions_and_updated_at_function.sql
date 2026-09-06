-- A5.2 — Civilpedia PostgreSQL/Supabase Schema Foundation
-- Migration 00001: Required extensions and the single reusable updated_at
-- trigger pattern.
--
-- This function is used by a per-table BEFORE UPDATE trigger to keep
-- updated_at current automatically. The function is defined once; each
-- table with an updated_at column gets its own lightweight trigger
-- referencing this shared function.

-- Enable gen_random_uuid() for UUID primary keys.
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Reusable updated_at setter (single function, not duplicated per table).
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.set_updated_at() IS
  'Reusable BEFORE UPDATE trigger that sets updated_at = now(). '
  'Each table with an updated_at column calls: '
  'CREATE TRIGGER trigger_set_updated_at BEFORE UPDATE ON <table> '
  'FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();';
