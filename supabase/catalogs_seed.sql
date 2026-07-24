-- ============================================================
-- CATÁLOGOS de planta: marcas (plant_brand_catalog), por cooperativa.
--
-- Estos datos vivían embebidos en la migración
-- 20260712144100_create_presentation_brand_catalogs.sql como un INSERT
-- ... SELECT ... FROM cooperatives -- pero esa migración corre ANTES que
-- seed.sql (que es donde recién se insertan las cooperativas), así que en
-- un reset desde cero ese INSERT no inserta nada (0 filas, sin error).
-- Ver supabase/mi-proyecto/OPERATIONS.md, sección "Catálogos y datos de
-- referencia por cooperativa" para el detalle del bug.
--
-- Se separa acá como archivo de carga manual (mismo criterio que
-- modules_seed.sql / real_users_seed.sql), en vez de depender de que la
-- migración lo resuelva sola.
--
-- ⚠️ Norandino queda EXCLUIDA del CROSS JOIN de abajo: ya tiene su propia
-- lista real de marcas confirmada (ver supabase/norandino/catalogo_norandino.sql
-- -- NORANDINO y AYPATE, no las 5 placeholder que había acá). El resto de
-- cooperativas sin lista real todavía siguen recibiendo este placeholder
-- (2026-07-12) hasta que llegue la suya.
--
-- Se eliminó también el INSERT de plant_presentation_catalog: esa tabla se
-- borró en 20260722170000_client_defaults_and_product_catalog.sql (nunca se
-- llegó a leer desde ningún frontend; su función la cubre ahora
-- plant_clients.default_* + plant_product_catalog).
--
-- Carga manual: correr después de seed.sql (necesita que cooperatives ya
-- tenga filas), en cualquier orden respecto a modules_seed.sql /
-- real_users_seed.sql (no dependen entre sí).
-- ============================================================

INSERT INTO public.plant_brand_catalog (cooperative_id, label)
SELECT c.id, b.label
FROM public.cooperatives c
CROSS JOIN (VALUES
  ('NORANDINO'),
  ('CAES'),
  ('PanelaBio'),
  ('NaturPanela'),
  ('Andean Sweet')
) AS b(label)
WHERE c.id <> '550e8400-e29b-41d4-a716-446655440001' -- Norandino: tiene lista real propia
ON CONFLICT (cooperative_id, label) DO NOTHING;
