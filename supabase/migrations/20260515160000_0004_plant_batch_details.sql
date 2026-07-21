-- ─────────────────────────────────────────────────────────────────────────────
-- Detalle de lotes de envasado para PDF de trazabilidad
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Columnas nuevas en plant_production_batches
ALTER TABLE "public"."plant_production_batches"
  ADD COLUMN IF NOT EXISTS "description"      text,
  ADD COLUMN IF NOT EXISTS "best_before_date" date,
  ADD COLUMN IF NOT EXISTS "pallet_count"     integer CHECK (pallet_count > 0);

-- La config de vida útil por cooperativa (shelf_life_config) se movió a
-- seed.sql: esta migración corre antes de que existan filas en
-- "cooperatives" (esas se insertan recién en seed.sql, al final del
-- reset), así que un INSERT acá con cooperative_id hardcodeado violaba la
-- foreign key en cualquier reset desde cero. Bug real, encontrado 2026-07-15.
