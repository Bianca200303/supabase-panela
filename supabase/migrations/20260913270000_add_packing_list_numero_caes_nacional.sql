-- =============================================================================
-- Packing List-Nacional (CAESP-PP-BPM-RE-CPR-008, ver
-- [[project_packing_list_nacional_caes]]): el papel real trae un N° de
-- documento propio (ej. "N-25-90", esquina superior derecha) que en
-- exportación sale de plant_container_loadings.documento_number
-- ("Registrar carga") -- pero una venta nacional no pasa por ese flujo (no
-- tiene pallets/contenedor real que cargar), así que nunca hay dónde
-- escribirlo. Se agrega como campo nuevo "N° Packing List"
-- (packing_list_numero) SOLO en la fila cooperativa-específica de CAES del
-- step "contenedor" -- mismo lugar donde ya viven Factura Comercial y las
-- Guías de Remisión. No se toca la fila global (Norandino ya tiene su
-- propio número vía Registrar carga).
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
  {"key":"carta_rendimiento_azucar","label":"Carta de Rendimiento del Azúcar","type":"text","required":false,"order":16},
  {"key":"transporte_tramo1_codigo","label":"Transporte Montero → Paita/Piura: código de control","type":"text","required":false,"order":17},
  {"key":"transporte_tramo1_fecha","label":"Transporte Montero → Paita/Piura: fecha","type":"date","required":false,"order":18},
  {"key":"transporte_tramo1_guias","label":"Transporte Montero → Paita/Piura: N° guías de transporte (una por línea)","type":"textarea","required":false,"order":19},
  {"key":"transporte_tramo2_codigo","label":"Transporte a destino final: código de control","type":"text","required":false,"order":20},
  {"key":"transporte_tramo2_fecha","label":"Transporte a destino final: fecha","type":"date","required":false,"order":21},
  {"key":"transporte_tramo2_guias","label":"Transporte a destino final: N° guías de transporte (una por línea)","type":"textarea","required":false,"order":22},
  {"key":"packing_list_numero","label":"N° Packing List","type":"text","required":false,"order":23}
]'::jsonb,
    updated_at = now()
WHERE step_key = 'contenedor' AND cooperative_id = '550e8400-e29b-41d4-a716-446655440002';
