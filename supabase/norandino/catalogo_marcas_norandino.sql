-- ============================================================
-- Marcas reales de Norandino (plant_brand_catalog).
--
-- Reemplaza el placeholder que traía supabase/catalogs_seed.sql
-- (NORANDINO, CAES, PanelaBio, NaturPanela, Andean Sweet -- ese archivo ya
-- excluye a Norandino de ese CROSS JOIN desde 2026-07-22 para no pisar esto).
--
-- Solo 2 marcas confirmadas en el catálogo de productos real:
--   - NORANDINO: marca propia de la cooperativa (línea orgánica, y el
--     producto genérico marcado como "coop" en el excel).
--   - AYPATE: marca del sachet (PANE02005015). No es un cliente/importador
--     de la lista de 6 -- es una marca, no un cliente.
-- Los productos de exportación para Alcenero/Ethiquable/La Siembra/etc. NO
-- llevan marca acá -- van directo con client_id (ver productos_norandino.sql),
-- para no duplicar el mismo nombre como cliente Y como marca.
--
-- Carga manual, correr antes de productos_norandino.sql (que busca estas
-- marcas por nombre).
-- ============================================================

INSERT INTO public.plant_brand_catalog (cooperative_id, label)
VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'NORANDINO'),
  ('550e8400-e29b-41d4-a716-446655440001', 'AYPATE')
ON CONFLICT (cooperative_id, label) DO NOTHING;
