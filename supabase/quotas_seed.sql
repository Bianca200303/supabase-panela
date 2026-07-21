-- ============================================================
-- CUPOS DE PRODUCTORES (producer_quotas) — PLANTILLA CON DATOS FALSOS,
-- para ajustar cupo_kg/year cuando lleguen los valores reales.
--
-- Referencia: supabase/mi-proyecto/QUOTA_SYSTEM.md (arquitectura +
-- queries operacionales). Usa el patrón "Cupo único para toda la
-- cooperativa" de esa guía (sección "Queries operacionales").
--
-- Aplica el mismo cupo_kg (5000.00, FALSO) a los 80 productores reales
-- de Norandino ya cargados en real_users_seed.sql, para la certificación
-- Orgánica, año 2026. No hace falta conocer los producer_id: se resuelven
-- automáticamente vía el SELECT sobre producers (mismo cooperative_id).
--
-- ⚠️ cupo_kg = 5000.00 y year = 2026 son valores de ejemplo -- reemplazar
-- por los reales. Si hace falta un cupo distinto por certificación,
-- duplicar el bloque cambiando el batch_cert_id (ver tabla al final).
-- Si hace falta un cupo distinto por módulo en vez de uno solo para toda
-- la cooperativa, ver la plantilla "Cupos distintos por módulo" en
-- QUOTA_SYSTEM.md.
--
-- Carga manual: correr después de real_users_seed.sql (necesita que los
-- 80 productores ya existan).
-- ============================================================

INSERT INTO producer_quotas
  (producer_id, batch_cert_id, cooperative_id, coop_module_id, cupo_kg, year, notes)
SELECT
  p.id,
  '990e8400-e29b-41d4-a716-446655440004',  -- batch_cert_id: Orgánica (Norandino)
  p.cooperative_id,
  p.coop_module_id,
  5000.00,   -- cupo_kg FALSO -- reemplazar
  2026,      -- year FALSO -- reemplazar
  'Cupo de ejemplo (falso) — reemplazar por el valor real'
FROM producers p
WHERE p.cooperative_id = '550e8400-e29b-41d4-a716-446655440001'
  AND p.is_active = true
ON CONFLICT (producer_id, batch_cert_id, year) DO NOTHING;

-- ============================================================
-- Referencia rápida: batch_cert_id de Norandino (de supabase/seed.sql)
-- ============================================================
-- Orgánica     990e8400-e29b-41d4-a716-446655440004
-- FLO          990e8400-e29b-41d4-a716-446655440005
-- SPP          990e8400-e29b-41d4-a716-446655440006
-- Naturland    990e8400-e29b-41d4-a716-446655440007
-- Convencional 990e8400-e29b-41d4-a716-446655440008
