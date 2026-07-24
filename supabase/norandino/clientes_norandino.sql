-- ============================================================
-- Clientes/importadores de Norandino, con sus defaults reales de
-- presentación (bolsas por caja, peso por bolsa/saco, pallets por lote).
-- Fuente: excel suelto de la cooperativa (2026-07-22).
--
-- "code" es solo una clave interna para poder cargar esto de forma segura
-- (plant_clients no tiene unique en "name", el excel tampoco trae códigos
-- de cliente) -- sigue siendo editable desde la web, no es un dato oficial
-- del cliente.
--
-- Trade And Imports y Tregar trabajan en saco (no en caja), por eso no
-- tienen "bolsas por caja" ni pallets por lote definidos -- quedan en NULL,
-- no en 0, porque no es que el valor sea cero, es que el dato no aplica.
-- "Nacional" no trae ningún default en el excel -- se carga sin ellos.
--
-- Carga manual: no se ejecuta sola, solo cuando decidas insertarla.
-- Requiere la migración 20260722170000_client_defaults_and_product_catalog.sql
-- ya aplicada (agrega las columnas default_*).
-- ============================================================

INSERT INTO public.plant_clients
  (cooperative_id, name, code, default_packaging_type, default_units_per_box, default_packaging_kg, default_pallet_count)
VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'Alcenero SPA',             'ALCENERO',      'bolsa', 10,   0.5,  11),
  ('550e8400-e29b-41d4-a716-446655440001', 'Ethiquable SPA',           'ETHIQUABLE',    'bolsa', 6,    0.5,  12),
  ('550e8400-e29b-41d4-a716-446655440001', 'La Siembra',               'LA_SIEMBRA',    'bolsa', 6,    1.0,  11),
  ('550e8400-e29b-41d4-a716-446655440001', 'Trade And Imports Ltda',  'TRADE_IMPORTS', 'saco',  NULL, 25.0, NULL),
  ('550e8400-e29b-41d4-a716-446655440001', 'Tregar',                   'TREGAR',        'saco',  NULL, 25.0, NULL),
  ('550e8400-e29b-41d4-a716-446655440001', 'Nacional',                 'NACIONAL',      NULL,    NULL, NULL, NULL)
ON CONFLICT (cooperative_id, code) DO NOTHING;
