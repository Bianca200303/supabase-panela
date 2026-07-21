-- ============================================================
-- CUPOS DE PRODUCTORES (producer_quotas) — CAES, PLANTILLA CON DATOS
-- FALSOS, para ajustar cupo_kg/year cuando lleguen los valores reales.
--
-- Referencia: supabase/mi-proyecto/QUOTA_SYSTEM.md. Mismo criterio que
-- supabase/quotas_seed.sql de Norandino: aplica el mismo cupo_kg a todos
-- los productores de prueba de CAES (los 30 de users_caes.sql), para la
-- certificación Orgánica, año 2026.
--
-- ⚠️ cupo_kg = 3000.00 y year = 2026 son valores de ejemplo -- reemplazar
-- por los reales.
--
-- Carga manual: correr después de users_caes.sql (necesita que los 30
-- productores de prueba ya existan).
-- ============================================================

INSERT INTO producer_quotas
  (producer_id, batch_cert_id, cooperative_id, coop_module_id, cupo_kg, year, notes)
SELECT
  p.id,
  '990e8400-e29b-41d4-a716-446655440001',  -- batch_cert_id: Orgánica (CAES)
  p.cooperative_id,
  p.coop_module_id,
  3000.00,   -- cupo_kg FALSO -- reemplazar
  2026,      -- year FALSO -- reemplazar
  'Cupo de ejemplo (falso) — reemplazar por el valor real'
FROM producers p
WHERE p.cooperative_id = '550e8400-e29b-41d4-a716-446655440002'
  AND p.is_active = true
ON CONFLICT (producer_id, batch_cert_id, year) DO NOTHING;

-- ============================================================
-- Referencia rápida: batch_cert_id de CAES (de supabase/seed.sql)
-- ============================================================
-- Orgánica     990e8400-e29b-41d4-a716-446655440001
-- SPP          990e8400-e29b-41d4-a716-446655440002
-- Convencional 990e8400-e29b-41d4-a716-446655440003
-- FLO          c23cb5e6-0330-4981-b5e8-55a018f60a5a
-- Naturland    072d1ceb-6ef6-41af-9cbe-86309df253d8
