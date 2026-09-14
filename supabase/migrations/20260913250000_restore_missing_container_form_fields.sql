-- =============================================================================
-- Bug preexistente encontrado al investigar el flujo de despacho de ventas
-- nacionales de CAES: lib/formConfig.js (DEFAULTS.contenedor, en código)
-- incluye 10 campos de transporte/certificados -- factura_comercial,
-- certificado_transaccion, certificado_origen, carta_rendimiento_azucar,
-- transporte_tramo1_codigo/fecha/guias, transporte_tramo2_codigo/fecha/guias
-- -- que resumenTrazabilidad.js y ordenSalida.js YA leen de
-- plant_containers.extra_data. Pero la fila de `form_configurations`
-- (step_key='contenedor', cooperative_id NULL) nunca se actualizó para
-- incluirlos -- la última migración que tocó esta fila
-- (20260825100000_update_container_form_fields.sql) se quedó en el campo 12
-- (estimated_arrival). Como esa fila de BD tiene prioridad sobre los
-- DEFAULTS del código (ver loadFormConfig en formConfig.js), esos 10 campos
-- nunca aparecieron en el modal "Registrar/Editar contenedor" -- nadie pudo
-- cargarlos nunca, para ninguna cooperativa. Se restaura la fila completa
-- (mismos 12 campos existentes + los 10 que faltaban), sin cambiar ningún
-- required existente.
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
  {"key":"estimated_arrival","label":"Fecha estimada de llegada","type":"date","required":false,"order":12},
  {"key":"factura_comercial","label":"Factura Comercial","type":"text","required":false,"order":13},
  {"key":"certificado_transaccion","label":"N° Certificado de Transacción (TC)","type":"text","required":false,"order":14},
  {"key":"certificado_origen","label":"Certificado de Origen","type":"text","required":false,"order":15},
  {"key":"carta_rendimiento_azucar","label":"Carta de Rendimiento del Azúcar","type":"text","required":false,"order":16},
  {"key":"transporte_tramo1_codigo","label":"Transporte Montero → Paita/Piura: código de control","type":"text","required":false,"order":17},
  {"key":"transporte_tramo1_fecha","label":"Transporte Montero → Paita/Piura: fecha","type":"date","required":false,"order":18},
  {"key":"transporte_tramo1_guias","label":"Transporte Montero → Paita/Piura: N° guías de transporte (una por línea)","type":"textarea","required":false,"order":19},
  {"key":"transporte_tramo2_codigo","label":"Transporte a destino final: código de control","type":"text","required":false,"order":20},
  {"key":"transporte_tramo2_fecha","label":"Transporte a destino final: fecha","type":"date","required":false,"order":21},
  {"key":"transporte_tramo2_guias","label":"Transporte a destino final: N° guías de transporte (una por línea)","type":"textarea","required":false,"order":22}
]'::jsonb
WHERE step_key = 'contenedor' AND cooperative_id IS NULL;
