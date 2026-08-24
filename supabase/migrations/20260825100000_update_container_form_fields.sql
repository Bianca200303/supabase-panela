-- =============================================================================
-- Ajustes al formulario "Registrar/Editar contenedor" de Embarque, a pedido
-- del usuario:
--   - BL (bill_of_lading) y Naviera (shipping_line) pasan de obligatorios a
--     opcionales -- no siempre se conocen en el momento de registrar el
--     contenedor.
--   - Se agregan dos campos nuevos: "Precinto de aduana" (junto al Nro. de
--     Sello ya existente -- son dos precintos físicos distintos) y "Vessel"
--     (nombre del buque, junto a Naviera). Ninguno de los dos tiene columna
--     propia en plant_containers -- caen solos en extra_data, mismo
--     mecanismo ya usado para los 8 campos de Orden de Salida (ver
--     splitFixedAndExtra en formConfig.js / CONTAINER_FIXED_COLS en
--     EmbarquePage.jsx) -- no hace falta ALTER TABLE.
-- =============================================================================

UPDATE public.form_configurations
SET fields = '[
  {"key":"container_number","label":"Serie de contenedor","type":"text","required":true,"order":1},
  {"key":"seal_number","label":"Nro. Sello","type":"text","required":false,"order":2},
  {"key":"precinto_aduana","label":"Precinto de aduana","type":"text","required":false,"order":3},
  {"key":"container_size","label":"Tamaño (pies)","type":"select","required":true,"options":["20","40"],"default":"20","order":4},
  {"key":"max_capacity_kg","label":"Capacidad máx. (kg)","type":"number","required":false,"min":0,"order":5},
  {"key":"booking_number","label":"Nro. Reserva (Booking)","type":"text","required":true,"order":6},
  {"key":"bill_of_lading","label":"Conocimiento de embarque (BL)","type":"text","required":false,"order":7},
  {"key":"shipping_line","label":"Naviera","type":"text","required":false,"order":8},
  {"key":"vessel","label":"Vessel","type":"text","required":false,"order":9},
  {"key":"destination_port","label":"Puerto destino","type":"text","required":true,"order":10},
  {"key":"departure_date","label":"Fecha de salida","type":"date","required":false,"order":11},
  {"key":"estimated_arrival","label":"Fecha estimada de llegada","type":"date","required":false,"order":12}
]'::jsonb
WHERE step_key = 'contenedor' AND cooperative_id IS NULL;
