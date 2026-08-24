-- =============================================================================
-- "Contenedor N°" -- código interno que la propia cooperativa le asigna a la
-- orden, DISTINTO del número de serie del contenedor físico real
-- (plant_containers.container_number, ahora renombrado en la UI a "Serie de
-- contenedor" más abajo en esta misma migración).
--
-- Por qué van separados: container_number (la serie física) recién se
-- conoce cuando la orden llega a Embarque y se le asigna un contenedor real
-- -- "normalmente todavía no se conoce" al crear la orden ni durante
-- tamizado/envasado (ver comentario en OrdenesPage.jsx, sección Nueva
-- Orden). El "Contenedor N°" interno, en cambio, lo asigna la cooperativa
-- desde el vamos y es el que quieren ver impreso en los primeros 5
-- documentos rápidos (Orden de Producción, Registro de Trazabilidad,
-- Registro de Homogenizado y Tamizado, Control de Envasado, Control de
-- Calidad por Lote) -- generados normalmente antes de que exista una serie
-- de contenedor física asignada.
--
-- Vive en plant_orders (no en plant_containers) por eso mismo: es un dato
-- de la ORDEN, editable en cualquier momento, sin relación con el flujo de
-- Embarque -- mismo patrón ya usado para client_order_number/sale_number
-- (texto libre, opcional, sin validar).
-- =============================================================================

ALTER TABLE public.plant_orders
  ADD COLUMN IF NOT EXISTS internal_container_number text;

-- Renombra la etiqueta del campo físico en el formulario de Embarque
-- ("Registrar/Editar contenedor") de "Nro. Contenedor" a "Serie de
-- contenedor", para no confundirlo con el "Contenedor N°" interno de
-- arriba. La config de ese formulario vive en form_configurations
-- (sembrada en seed.sql, ajustada en 20260711203731), no hay columna que
-- tocar -- mismo mecanismo que el resto de los formularios dinámicos.
UPDATE public.form_configurations
SET fields = '[
  {"key":"container_number","label":"Serie de contenedor","type":"text","required":true,"order":1},
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
