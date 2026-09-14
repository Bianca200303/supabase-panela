-- =============================================================================
-- Ventas nacionales de CAES (COOPERATIVE.features.ventaNacionalExportacion):
-- el papel real de CAES ("PACKING LIST-NACIONAL" CAESP-PP-BPM-RE-CPR-008 y
-- "Guía de Remisión Electrónica") confirma que una venta nacional NO usa
-- contenedor marítimo, booking, ni puerto de destino -- se despacha con una
-- Guía de Remisión (ya modelada en transporte_tramo1/2_guias, ver
-- 20260913250000). Pero el step "contenedor" (compartido con Norandino) hoy
-- exige container_number/container_size/booking_number/destination_port
-- como obligatorios -- eso bloquea guardar el registro para una orden
-- nacional antes de siquiera llegar a la pantalla de despacho.
--
-- Fila cooperativa-específica para CAES (misma herencia ya usada en
-- [[project_verificacion_limpieza_caes]]): mismos 22 campos que la fila
-- global (20260913250000), solo cambia required a false en esos 4 -- el
-- resto de la UI/validación no se toca. Norandino sigue usando la fila
-- global sin cambios (siempre exporta, esos 4 campos le siguen aplicando).
-- =============================================================================

INSERT INTO public.form_configurations (cooperative_id, step_key, fields, is_active)
VALUES (
  '550e8400-e29b-41d4-a716-446655440002',
  'contenedor',
  '[
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
    {"key":"transporte_tramo2_guias","label":"Transporte a destino final: N° guías de transporte (una por línea)","type":"textarea","required":false,"order":22}
  ]'::jsonb,
  true
)
ON CONFLICT (cooperative_id, step_key) DO UPDATE SET fields = EXCLUDED.fields, updated_at = now();
