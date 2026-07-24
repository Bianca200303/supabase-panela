-- ============================================================
-- Catálogo de productos (CODPROD) de Norandino -- plant_product_catalog.
-- Fuente: excel suelto de la cooperativa (2026-07-22), 17 códigos.
--
-- El código sigue el patrón PANE + categoría(2) + peso en decikg(3) +
-- correlativo(3). Ej: PANE 01 005 001 -> categoría 01, 005/10 = 0.5 kg.
-- Se usó ese patrón para inferir packaging_kg cuando la descripción no lo
-- decía explícito (a granel, reproceso, descarte, merma -> sin peso fijo,
-- quedan en NULL).
--
-- Categorías:
--   01, 02 -- productos de exportación reales (vendibles).
--   03 (reproceso), 04 (descarte), 05 (merma) -- categorías internas de
--   pérdida/reproceso, "por kg", sin empaque fijo. NO son productos que se
--   vendan en una orden -- el sistema ya trackea esto por otro lado
--   (plant_batch_bunques.reproceso_kg/descarte_kg/merma_kg). Se incluyen
--   igual en el catálogo por pedido explícito, pero sin packaging_type ni
--   packaging_kg (no aplica) y sin client_id/brand_id.
--
-- ⚠️ INCONSISTENCIA A CONFIRMAR CON LA COOPERATIVA:
--   PANE01250023 -- el código indica 25 kg (segmento "250"), pero la
--   descripción del excel dice "por 20 kg". Se cargó con packaging_kg=20
--   (lo que dice el texto, que es lo comercialmente visible), pero conviene
--   confirmar cuál de los dos está mal en el excel original.
--
-- ⚠️ SUPUESTO: PANE02005015 "Panela sachet aypate" no trae peso en la
--   descripción -- se infirió 0.5 kg del propio código (segmento "005"),
--   igual que el resto de la familia "005". Confirmar con la cooperativa.
--
-- Requiere que clientes_norandino.sql y catalogo_marcas_norandino.sql ya
-- se hayan cargado (busca client_id/brand_id por code/label).
-- Carga manual: no se ejecuta sola, solo cuando decidas insertarla.
-- ============================================================

INSERT INTO public.plant_product_catalog
  (cooperative_id, client_id, brand_id, code, description, packaging_type, packaging_kg)
SELECT
  '550e8400-e29b-41d4-a716-446655440001',
  (SELECT id FROM public.plant_clients      WHERE cooperative_id = '550e8400-e29b-41d4-a716-446655440001' AND code  = v.client_code),
  (SELECT id FROM public.plant_brand_catalog WHERE cooperative_id = '550e8400-e29b-41d4-a716-446655440001' AND label = v.brand_label),
  v.code, v.description, v.packaging_type, v.packaging_kg
FROM (VALUES
  -- code,          description,                                                    client_code,     brand_label,  packaging_type, packaging_kg
  ('PANE01005001', 'Panela exportacion x 0.5 kg ethiquable- francia',             'ETHIQUABLE',    NULL,        'bolsa', 0.5),
  ('PANE01005002', 'Panela exportacion x 0.5 kg ethiquable-bélgica',              'ETHIQUABLE',    NULL,        'bolsa', 0.5),
  ('PANE01005004', 'Panela exportacion x 0.5 kg coop',                           NULL,             'NORANDINO', 'bolsa', 0.5),
  ('PANE01005005', 'Panela exportación x 0.5 kg alcenero',                       'ALCENERO',       NULL,        'bolsa', 0.5),
  ('PANE01005010', 'Panela exportacion x 0.5 kg ethiquable-terra etica',         'ETHIQUABLE',     NULL,        'bolsa', 0.5),
  ('PANE01010006', 'Panela exportacion x 1 kg la siembra',                       'LA_SIEMBRA',     NULL,        'bolsa', 1.0),
  ('PANE01250011', 'Panela exportacion x 25 kg ethiquable-francia',              'ETHIQUABLE',     NULL,        'saco',  25.0),
  ('PANE01250018', 'Panela exportación x 25 kg la siembra',                      'LA_SIEMBRA',     NULL,        'saco',  25.0),
  ('PANE01250022', 'Panela de exportación por 25 kg',                            NULL,             NULL,        'saco',  25.0),
  ('PANE01250023', 'Panela de exportación por 20 kg',                            NULL,             NULL,        'saco',  20.0),
  ('PANE02000015', 'Panela a granel organica x kg',                              NULL,             NULL,        NULL,    NULL),
  ('PANE02005013', 'Panela norandino organico x 0.5 kg',                        NULL,             'NORANDINO', 'bolsa', 0.5),
  ('PANE02005015', 'Panela sachet aypate',                                       NULL,             'AYPATE',    'bolsa', 0.5),
  ('PANE02010013', 'Panela norandino x 1 kg',                                    NULL,             'NORANDINO', 'bolsa', 1.0),
  ('PANE03000015', 'Panela reproceso convencional x kg',                         NULL,             NULL,        NULL,    NULL),
  ('PANE04000016', 'Panela descarte convencional x kg',                          NULL,             NULL,        NULL,    NULL),
  ('PANE05000014', 'Panela merma x kg',                                          NULL,             NULL,        NULL,    NULL)
) AS v(code, description, client_code, brand_label, packaging_type, packaging_kg)
ON CONFLICT (cooperative_id, code) DO NOTHING;
