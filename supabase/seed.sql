-- ============================================================
-- SEED BASE: Solo datos de referencia fijos
-- cooperativas, grupos de exclusión y certificados
-- ============================================================

SET session_replication_role = replica;

-- 1. Cooperativas
INSERT INTO "public"."cooperatives" ("id","name","code","created_at","updated_at","is_active","cane_density","access_code") VALUES
('550e8400-e29b-41d4-a716-446655440001','Cooperativa Agraria Norandino','NORANDINO','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true,1.0500,'NORA2025'),
('550e8400-e29b-41d4-a716-446655440002','Cooperativa Agraria Ecológica y Solidaria Piura','CAES','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true,1.0500,'CAES2025');

-- 2. Grupos de exclusión de certificados
INSERT INTO "public"."certificate_exclusion_groups" ("id","name","display_name","description","is_required","cooperative_id","created_at","updated_at","is_active") VALUES
('550e8400-e29b-41d4-a716-446655441001','production_type','Tipo de producción','Selecciona si la caña es orgánica o convencional',true,'550e8400-e29b-41d4-a716-446655440002','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true),
('550e8400-e29b-41d4-a716-446655441002','production_type','Tipo de producción','Selecciona si la caña es orgánica o convencional',true,'550e8400-e29b-41d4-a716-446655440001','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true);

-- 3. Certificados
INSERT INTO "public"."batch_certs" ("id","name","cooperative_id","created_at","updated_at","is_active","exclusion_group_id","is_default") VALUES
('990e8400-e29b-41d4-a716-446655440001','Orgánica','550e8400-e29b-41d4-a716-446655440002','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true,'550e8400-e29b-41d4-a716-446655441001',true),
('990e8400-e29b-41d4-a716-446655440002','SPP','550e8400-e29b-41d4-a716-446655440002','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true,NULL,false),
('990e8400-e29b-41d4-a716-446655440003','Convencional','550e8400-e29b-41d4-a716-446655440002','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true,'550e8400-e29b-41d4-a716-446655441001',false),
('990e8400-e29b-41d4-a716-446655440004','Orgánica','550e8400-e29b-41d4-a716-446655440001','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true,'550e8400-e29b-41d4-a716-446655441002',true),
('990e8400-e29b-41d4-a716-446655440005','FLO','550e8400-e29b-41d4-a716-446655440001','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true,NULL,false),
('990e8400-e29b-41d4-a716-446655440006','SPP','550e8400-e29b-41d4-a716-446655440001','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true,NULL,false),
('990e8400-e29b-41d4-a716-446655440007','Naturland','550e8400-e29b-41d4-a716-446655440001','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true,NULL,false),
('990e8400-e29b-41d4-a716-446655440008','Convencional','550e8400-e29b-41d4-a716-446655440001','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true,'550e8400-e29b-41d4-a716-446655441002',false),
('c23cb5e6-0330-4981-b5e8-55a018f60a5a','FLO','550e8400-e29b-41d4-a716-446655440002','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true,NULL,false),
('072d1ceb-6ef6-41af-9cbe-86309df253d8','Naturland','550e8400-e29b-41d4-a716-446655440002','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true,NULL,false);

-- 4. Configuraciones de formularios (globales, aplican a todas las cooperativas)
INSERT INTO "public"."form_configurations" ("cooperative_id", "step_key", "fields") VALUES

-- Calidad: campos de evaluación
(NULL, 'calidad', '[
  {"key":"humidity_pct","label":"Humedad %","type":"number","required":true,"min":0,"max":100,"order":1},
  {"key":"impurities_pct","label":"Impurezas %","type":"number","required":true,"min":0,"max":100,"order":2},
  {"key":"color","label":"Color","type":"select","required":true,"options":["amarillo claro","amarillo oscuro","verde","marron claro","marron oscuro"],"order":3},
  {"key":"sack_condition","label":"Estado del saco","type":"select","required":true,"options":["buena","regular","mala"],"order":4},
  {"key":"appearance","label":"Apariencia","type":"select","required":true,"options":["suelta","seca","cerosa"],"order":5},
  {"key":"notes","label":"Observaciones","type":"textarea","required":false,"order":6}
]'),

-- Checklist: Limpieza (nivel orden)
(NULL, 'checklist_limpieza', '[
  {"key":"pisos","label":"Pisos limpios y secos","type":"checkbox","required":false,"order":1},
  {"key":"paredes","label":"Paredes y techos sin suciedad","type":"checkbox","required":false,"order":2},
  {"key":"equipos","label":"Equipos y utensilios limpios","type":"checkbox","required":false,"order":3},
  {"key":"desagues","label":"Desagües despejados","type":"checkbox","required":false,"order":4},
  {"key":"desinfeccion","label":"Zona de trabajo desinfectada","type":"checkbox","required":false,"order":5},
  {"key":"residuos","label":"Residuos evacuados correctamente","type":"checkbox","required":false,"order":6}
]'),

-- Checklist: Mantenimiento de equipos (nivel lote)
(NULL, 'checklist_mantenimiento_equipos', '[
  {"key":"tamizadora","label":"Tamizadora en buen estado","type":"checkbox","required":false,"order":1},
  {"key":"tolvas","label":"Tolvas sin obstrucciones","type":"checkbox","required":false,"order":2},
  {"key":"bandas","label":"Bandas transportadoras funcionando","type":"checkbox","required":false,"order":3},
  {"key":"selladora","label":"Selladora calibrada","type":"checkbox","required":false,"order":4},
  {"key":"balanzas","label":"Balanzas calibradas","type":"checkbox","required":false,"order":5},
  {"key":"piezas","label":"Sin piezas sueltas o desgastadas","type":"checkbox","required":false,"order":6}
]'),

-- Checklist: Control de plagas (nivel orden)
(NULL, 'checklist_control_plagas', '[
  {"key":"roedores","label":"Sin evidencia de roedores","type":"checkbox","required":false,"order":1},
  {"key":"insectos","label":"Sin evidencia de insectos","type":"checkbox","required":false,"order":2},
  {"key":"trampas","label":"Trampas revisadas y activas","type":"checkbox","required":false,"order":3},
  {"key":"accesos","label":"Accesos sellados (puertas/ventanas)","type":"checkbox","required":false,"order":4},
  {"key":"rastros","label":"Sin heces ni rastros de animales","type":"checkbox","required":false,"order":5}
]'),

-- Checklist: Control de personal (nivel lote)
(NULL, 'checklist_control_personal', '[
  {"key":"uniforme","label":"Personal con uniforme completo","type":"checkbox","required":false,"order":1},
  {"key":"epp","label":"EPP correcto (guantes, mascarilla, cofia)","type":"checkbox","required":false,"order":2},
  {"key":"joyas","label":"Sin joyas ni accesorios","type":"checkbox","required":false,"order":3},
  {"key":"salud","label":"Personal sin síntomas de enfermedad","type":"checkbox","required":false,"order":4},
  {"key":"manos","label":"Manos limpias y desinfectadas","type":"checkbox","required":false,"order":5},
  {"key":"alimentos","label":"Sin alimentos en zona de producción","type":"checkbox","required":false,"order":6}
]'),

-- Contenedor: campos de registro
(NULL, 'contenedor', '[
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
]'),

-- Despacho: campos de registro
(NULL, 'despacho', '[
  {"key":"dispatch_date","label":"Fecha de despacho","type":"date","required":true,"order":1},
  {"key":"seal_verified","label":"Sello verificado al cerrar","type":"checkbox","required":false,"default":false,"order":3},
  {"key":"temperature_at_load","label":"Temperatura al cargar (°C)","type":"number","required":false,"order":4},
  {"key":"humidity_at_load","label":"Humedad relativa al cargar (%)","type":"number","required":false,"min":0,"max":100,"order":5},
  {"key":"notes","label":"Observaciones","type":"textarea","required":false,"order":6}
]'),

-- Procesamiento/tamizado: límites del proceso (usa el campo "default" como valor del límite)
(NULL, 'procesamiento', '[
  {"key":"merma_threshold_pct","label":"Umbral merma esperada (%)","type":"number","required":false,"min":0,"max":100,"default":5,"order":1}
]');

-- 5. Configuración de vida útil por cooperativa
-- Requerida por el código para calcular la fecha de vencimiento automáticamente
-- (calcBestBeforeDate en OrdenesPage.jsx). Movida acá desde la migración
-- 20260515160000: es por-cooperativa (no NULL/global como las de arriba), así
-- que necesita que "cooperatives" ya tenga filas -- por eso va en seed.sql,
-- que corre después de las migraciones, no en una migración.
-- default_months: meses base para todas las presentaciones.
-- overrides: primer match por texto en presentación gana.
INSERT INTO "public"."form_configurations" ("cooperative_id", "step_key", "fields") VALUES
('550e8400-e29b-41d4-a716-446655440001', 'shelf_life_config', '[
  {"key":"default_months","label":"Vida útil por defecto (meses)","type":"number","default":18},
  {"key":"overrides","label":"Excepciones por presentación","type":"json","default":[
    {"presentation_contains":"25 kg","months":12},
    {"presentation_contains":"50 kg","months":12},
    {"presentation_contains":"saco","months":12}
  ]}
]'),
('550e8400-e29b-41d4-a716-446655440002', 'shelf_life_config', '[
  {"key":"default_months","label":"Vida útil por defecto (meses)","type":"number","default":18},
  {"key":"overrides","label":"Excepciones por presentación","type":"json","default":[
    {"presentation_contains":"25 kg","months":12},
    {"presentation_contains":"50 kg","months":12},
    {"presentation_contains":"saco","months":12}
  ]}
]')
ON CONFLICT DO NOTHING;

-- Verificación de Limpieza (CAES): catálogo de áreas/ítems propio. Movida acá
-- desde la migración 20260913150000_verificacion_limpieza_areas_caes.sql por
-- el mismo motivo que "shelf_life_config" arriba: es por-cooperativa, así que
-- necesita que "cooperatives" ya tenga filas.
INSERT INTO "public"."form_configurations" ("cooperative_id", "step_key", "fields", "is_active") VALUES
('550e8400-e29b-41d4-a716-446655440002', 'verificacion_limpieza_areas', '[
  {
    "key": "areas",
    "label": "Áreas",
    "type": "grouped-list",
    "required": true,
    "order": 1,
    "options": [
      { "area": "Recepción", "items": [
        { "code": "paredes_techo", "label": "Paredes y Techo" },
        { "code": "pisos_ventanas", "label": "Pisos y ventanas" },
        { "code": "porton_puertas", "label": "Portón - puertas" },
        { "code": "parihuelas_tachos", "label": "Parihuelas y tachos de basura" },
        { "code": "personal", "label": "Personal *" },
        { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
      ] },
      { "area": "Almacén de Materia Prima", "items": [
        { "code": "paredes", "label": "Paredes" },
        { "code": "puertas_ventanas_mallas", "label": "Puertas, ventanas y mallas" },
        { "code": "pisos_techo", "label": "Pisos y techo" },
        { "code": "balanza_plataforma", "label": "Balanza plataforma" },
        { "code": "parihuelas", "label": "Parihuelas" },
        { "code": "personal", "label": "Personal *" },
        { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
      ] },
      { "area": "Tamizado, Homogenizado y Envasado", "items": [
        { "code": "paredes_pisos_canaletas", "label": "Paredes, pisos y canaletas" },
        { "code": "techo", "label": "Techo" },
        { "code": "zarandas_bunques", "label": "Zarandas y bunques" },
        { "code": "parihuelas", "label": "Parihuelas" },
        { "code": "utensilios", "label": "Utensilios" },
        { "code": "balanza_plataforma", "label": "Balanza plataforma" },
        { "code": "personal", "label": "Personal *" },
        { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
      ] },
      { "area": "Almacén de Producto Terminado", "items": [
        { "code": "paredes_pisos_techo", "label": "Paredes, pisos y techo" },
        { "code": "puertas_ventanas", "label": "Puertas y ventanas" },
        { "code": "parihuelas", "label": "Parihuelas" },
        { "code": "personal", "label": "Personal *" },
        { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
      ] },
      { "area": "Almacén de Materiales e Insumos", "items": [
        { "code": "paredes_pisos_techo", "label": "Paredes, pisos, techo" },
        { "code": "puertas_ventanas", "label": "Puertas y ventanas" },
        { "code": "parihuelas", "label": "Parihuelas" },
        { "code": "anaqueles_estantes", "label": "Anaqueles o estantes" },
        { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
      ] },
      { "area": "Laboratorio", "items": [
        { "code": "paredes_pisos_techo", "label": "Paredes, pisos, techo" },
        { "code": "puertas_ventanas", "label": "Puertas y ventanas" },
        { "code": "utensilios", "label": "Utensilios" },
        { "code": "material_vidrio", "label": "Material de vidrio" },
        { "code": "equipos", "label": "Equipos" },
        { "code": "estantes_mesas", "label": "Estantes y mesas" },
        { "code": "personal", "label": "Personal *" },
        { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
      ] },
      { "area": "Vestuarios", "items": [
        { "code": "paredes_pisos_techo", "label": "Paredes, pisos, techo" },
        { "code": "puertas_ventanas", "label": "Puertas y ventanas" },
        { "code": "armario_lockers", "label": "Armario/lockers" },
        { "code": "personal", "label": "Personal *" },
        { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
      ] },
      { "area": "Oficina", "items": [
        { "code": "paredes_pisos_techo", "label": "Paredes, pisos, techo" },
        { "code": "puertas_ventanas", "label": "Puertas y ventanas" },
        { "code": "estantes_escritorios_sillas", "label": "Estantes, escritorios, sillas, etc." },
        { "code": "equipos", "label": "Equipos" },
        { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
      ] },
      { "area": "Servicios Higiénicos", "items": [
        { "code": "paredes", "label": "Paredes" },
        { "code": "puertas_ventanas", "label": "Puertas y ventanas" },
        { "code": "pisos", "label": "Pisos" },
        { "code": "banos_lavatorios_duchas", "label": "Baños, lavatorios y duchas" }
      ] },
      { "area": "Utensilios de Limpieza", "items": [
        { "code": "cartilla_colores", "label": "Según cartilla colores" },
        { "code": "tachos_recipientes", "label": "Tachos y recipientes de basura" },
        { "code": "limpieza_orden", "label": "Limpieza y orden" }
      ] },
      { "area": "Reservorio", "items": [
        { "code": "tanque_1", "label": "Tanque N°01" },
        { "code": "tanque_2", "label": "Tanque N°02" },
        { "code": "tanque_3", "label": "Tanque N°03" }
      ] }
    ]
  }
]', true)
ON CONFLICT (cooperative_id, step_key) DO UPDATE SET fields = EXCLUDED.fields, updated_at = now();

-- Contenedor (CAES, venta nacional): fila cooperativa-específica del step
-- "contenedor" con 4 campos opcionales en vez de obligatorios. Movida acá
-- desde 20260913260000_contenedor_form_caes_nacional.sql por el mismo
-- motivo que las anteriores; ya incluye "packing_list_numero", agregado
-- después por 20260913270000_add_packing_list_numero_caes_nacional.sql.
INSERT INTO "public"."form_configurations" ("cooperative_id", "step_key", "fields", "is_active") VALUES
('550e8400-e29b-41d4-a716-446655440002', 'contenedor', '[
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
]', true)
ON CONFLICT (cooperative_id, step_key) DO UPDATE SET fields = EXCLUDED.fields, updated_at = now();

RESET ALL;