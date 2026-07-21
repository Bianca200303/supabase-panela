-- ============================================================
-- CATÁLOGOS de planta: marcas y presentaciones (plant_brand_catalog,
-- plant_presentation_catalog), por cooperativa.
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
-- ⚠️ Los valores de abajo son los que YA estaban hardcodeados en la
-- migración -- probablemente placeholder, no confirmados como reales
-- todavía. Reemplazar cuando lleguen las listas reales de marcas y
-- presentaciones de cada cooperativa.
--
-- Carga manual: correr después de seed.sql (necesita que cooperatives ya
-- tenga filas), en cualquier orden respecto a modules_seed.sql /
-- real_users_seed.sql (no dependen entre sí).
-- ============================================================

INSERT INTO public.plant_presentation_catalog (cooperative_id, label)
SELECT c.id, p.label
FROM public.cooperatives c
CROSS JOIN (VALUES
  ('Polvo 500 g'),
  ('Polvo 1 kg'),
  ('Polvo 25 kg (saco)'),
  ('Piloncillo 400 g'),
  ('Bloque 500 g'),
  ('Caja 500 g × 10 und'),
  ('Caja 500 g × 20 und'),
  ('Caja 1 kg × 10 und'),
  ('Bolsa 5 kg'),
  ('Saco 25 kg'),
  ('Saco 50 kg')
) AS p(label)
ON CONFLICT (cooperative_id, label) DO NOTHING;

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
ON CONFLICT (cooperative_id, label) DO NOTHING;
