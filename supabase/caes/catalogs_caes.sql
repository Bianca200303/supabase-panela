-- ============================================================
-- CATÁLOGOS de planta — CAES: marcas (plant_brand_catalog).
--
-- El archivo compartido supabase/catalogs_seed.sql ya inserta este catálogo
-- para las cooperativas sin lista real todavía (usa CROSS JOIN cooperatives,
-- excluyendo a Norandino). Si ya lo corriste, CAES ya tiene estas filas y
-- este archivo no insertará nada nuevo (ON CONFLICT DO NOTHING). Se deja
-- igual acá, filtrado explícitamente a CAES, para que la carpeta caes/
-- quede autocontenida y se pueda correr sin depender del archivo compartido.
--
-- ⚠️ Lista placeholder (misma que traía Norandino antes) -- reemplazar
-- cuando llegue la lista real de marcas de CAES.
--
-- Se eliminó el INSERT de plant_presentation_catalog: esa tabla se borró en
-- 20260722170000_client_defaults_and_product_catalog.sql (nunca se llegó a
-- leer desde ningún frontend).
--
-- Carga manual: no depende de módulos ni usuarios, se puede correr en
-- cualquier momento después de seed.sql.
-- ============================================================

INSERT INTO public.plant_brand_catalog (cooperative_id, label)
SELECT '550e8400-e29b-41d4-a716-446655440002', b.label
FROM (VALUES
  ('NORANDINO'),
  ('CAES'),
  ('PanelaBio'),
  ('NaturPanela'),
  ('Andean Sweet')
) AS b(label)
ON CONFLICT (cooperative_id, label) DO NOTHING;
