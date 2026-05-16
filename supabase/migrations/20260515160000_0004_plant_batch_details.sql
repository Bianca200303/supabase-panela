-- ─────────────────────────────────────────────────────────────────────────────
-- Detalle de lotes de envasado para PDF de trazabilidad
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Columnas nuevas en plant_production_batches
ALTER TABLE "public"."plant_production_batches"
  ADD COLUMN IF NOT EXISTS "description"      text,
  ADD COLUMN IF NOT EXISTS "best_before_date" date,
  ADD COLUMN IF NOT EXISTS "pallet_count"     integer CHECK (pallet_count > 0);

-- 2. Configuración de vida útil por cooperativa
-- Esta config es requerida por el código para calcular fecha de vencimiento automáticamente.
-- default_months: meses base para todas las presentaciones.
-- overrides: primer match por texto en presentación gana.
INSERT INTO "public"."form_configurations" ("cooperative_id", "step_key", "fields") VALUES
('550e8400-e29b-41d4-a716-446655440001', 'shelf_life_config', '[
  {"key":"default_months","label":"Vida útil por defecto (meses)","type":"number","default":18},
  {"key":"overrides","label":"Excepciones por presentación","type":"json","default":[
    {"presentation_contains":"25 kg","months":12},
    {"presentation_contains":"50 kg","months":12},
    {"presentation_contains":"saco","months":12}
  ]}
]'),
('550e8400-e29b-41d4-a716-446655440002', 'shelf_life_config', '[
  {"key":"default_months","label":"Vida útil por defecto (meses)","type":"number","default":18},
  {"key":"overrides","label":"Excepciones por presentación","type":"json","default":[
    {"presentation_contains":"25 kg","months":12},
    {"presentation_contains":"50 kg","months":12},
    {"presentation_contains":"saco","months":12}
  ]}
]')
ON CONFLICT DO NOTHING;
