-- Al registrar el contenedor/embarque, Booking, Naviera, BL y Puerto destino
-- pasan a ser obligatorios. La config de este formulario vive en
-- form_configurations (sembrada en seed.sql), no en columnas NOT NULL de
-- plant_containers -- así es como ya funciona el resto de estos formularios
-- dinámicos (calidad, despacho, checklists), así que se actualiza el mismo
-- mecanismo en vez de agregar constraints de tabla nuevos.

UPDATE public.form_configurations
SET fields = '[
  {"key":"container_number","label":"Nro. Contenedor","type":"text","required":true,"order":1},
  {"key":"seal_number","label":"Nro. Sello","type":"text","required":false,"order":2},
  {"key":"container_size","label":"Tamaño (pies)","type":"select","required":true,"options":["20","40"],"default":"20","order":3},
  {"key":"max_capacity_kg","label":"Capacidad máx. (kg)","type":"number","required":false,"min":0,"order":4},
  {"key":"booking_number","label":"Nro. Reserva (Booking)","type":"text","required":true,"order":5},
  {"key":"bill_of_lading","label":"Conocimiento de embarque (BL)","type":"text","required":true,"order":6},
  {"key":"shipping_line","label":"Naviera","type":"text","required":true,"order":7},
  {"key":"destination_port","label":"Puerto destino","type":"text","required":true,"order":8},
  {"key":"departure_date","label":"Fecha de salida","type":"date","required":false,"order":9},
  {"key":"estimated_arrival","label":"Fecha estimada de llegada","type":"date","required":false,"order":10}
]'::jsonb
WHERE step_key = 'contenedor' AND cooperative_id IS NULL;
