-- =============================================================================
-- Saca del formulario "contenedor" de CAES los 7 campos que se mudan a
-- tablas propias, ahora que existen plant_packing_list_nacional_caes
-- (20260916120000) y plant_transport_unit_controls_caes (20260916130000):
--
--   - packing_list_numero            -> plant_packing_list_nacional_caes.packing_list_numero
--   - transporte_tramo1_codigo       -> ya no existe como tal, era texto
--                                        libre sin control real detrás;
--                                        reemplazado por N registros de
--                                        plant_transport_unit_controls_caes
--   - transporte_tramo1_fecha        -> plant_transport_unit_controls_caes.control_date
--   - transporte_tramo1_guias        -> plant_packing_list_nacional_caes.guia_tramo_interno
--                                        (Packing List) + plant_transport_unit_controls_caes.guia_remision
--                                        (por cada control real, prefiltrado desde el Packing List)
--   - transporte_tramo2_codigo/fecha/guias -> ídem, tramo final
--
-- factura_comercial y certificado_transaccion NO se tocan -- son datos de
-- la VENTA (aplican a Nacional y Exportación), no del Packing List ni del
-- transporte, así que se quedan donde están.
-- =============================================================================

UPDATE public.form_configurations
SET fields = '[
  {"key":"container_number","label":"Serie de contenedor","type":"text","required":false,"order":1},
  {"key":"seal_number","label":"Nro. Sello","type":"text","required":false,"order":2},
  {"key":"precinto_aduana","label":"Precinto de aduana","type":"text","required":false,"order":3},
  {"key":"container_size","label":"Tamaño (pies)","type":"select","required":false,"options":["20","40"],"default":"20","order":4},
  {"key":"max_capacity_kg","label":"Capacidad máx. (kg)","type":"number","required":false,"min":0,"order":5},
  {"key":"booking_number","label":"Nro. Reserva (Booking)","type":"text","required":false,"order":6},
  {"key":"bill_of_lading","label":"Conocimiento de embarque (BL)","type":"text","required":false,"order":7},
  {"key":"shipping_line","label":"Naviera","type":"text","required":false,"order":8},
  {"key":"vessel","label":"Vessel","type":"text","required":false,"order":9},
  {"key":"destination_port","label":"Puerto destino","type":"text","required":false,"order":10},
  {"key":"departure_date","label":"Fecha de salida","type":"date","required":false,"order":11},
  {"key":"estimated_arrival","label":"Fecha estimada de llegada","type":"date","required":false,"order":12},
  {"key":"factura_comercial","label":"Factura Comercial","type":"text","required":false,"order":13},
  {"key":"certificado_transaccion","label":"N° Certificado de Transacción (TC)","type":"text","required":false,"order":14},
  {"key":"certificado_origen","label":"Certificado de Origen","type":"text","required":false,"order":15},
  {"key":"carta_rendimiento_azucar","label":"Carta de Rendimiento del Azúcar","type":"text","required":false,"order":16}
]'::jsonb,
    updated_at = now()
WHERE step_key = 'contenedor' AND cooperative_id = '550e8400-e29b-41d4-a716-446655440002';
