-- ============================================================
-- CATÁLOGOS de planta — CAES: marcas y presentaciones
-- (plant_brand_catalog, plant_presentation_catalog).
--
-- El archivo compartido supabase/catalogs_seed.sql ya inserta estos
-- catálogos para TODAS las cooperativas (usa CROSS JOIN cooperatives).
-- Si ya lo corriste, CAES ya tiene estas filas y este archivo no
-- insertará nada nuevo (ON CONFLICT DO NOTHING). Se deja igual acá,
-- filtrado explícitamente a CAES, para que la carpeta caes/ quede
-- autocontenida y se pueda correr sin depender del archivo compartido.
--
-- ⚠️ Lista placeholder (misma que Norandino) -- reemplazar cuando llegue
-- la lista real de marcas/presentaciones de CAES.
--
-- Carga manual: no depende de módulos ni usuarios, se puede correr en
-- cualquier momento después de seed.sql.
-- ============================================================

INSERT INTO public.plant_presentation_catalog (cooperative_id, label)
SELECT '550e8400-e29b-41d4-a716-446655440002', p.label
FROM (VALUES
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
SELECT '550e8400-e29b-41d4-a716-446655440002', b.label
FROM (VALUES
  ('NORANDINO'),
  ('CAES'),
  ('PanelaBio'),
  ('NaturPanela'),
  ('Andean Sweet')
) AS b(label)
ON CONFLICT (cooperative_id, label) DO NOTHING;
