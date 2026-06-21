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
  {"key":"booking_number","label":"Nro. Reserva (Booking)","type":"text","required":false,"order":5},
  {"key":"bill_of_lading","label":"Conocimiento de embarque (BL)","type":"text","required":false,"order":6},
  {"key":"shipping_line","label":"Naviera","type":"text","required":false,"order":7},
  {"key":"destination_port","label":"Puerto destino","type":"text","required":false,"order":8},
  {"key":"departure_date","label":"Fecha de salida","type":"date","required":false,"order":9},
  {"key":"estimated_arrival","label":"Fecha estimada de llegada","type":"date","required":false,"order":10}
]'),

-- Despacho: campos de registro
(NULL, 'despacho', '[
  {"key":"dispatch_date","label":"Fecha de despacho","type":"date","required":true,"order":1},
  {"key":"total_loaded_kg","label":"Peso total cargado (kg)","type":"number","required":true,"min":0,"order":2},
  {"key":"seal_verified","label":"Sello verificado al cerrar","type":"checkbox","required":false,"default":false,"order":3},
  {"key":"temperature_at_load","label":"Temperatura al cargar (°C)","type":"number","required":false,"order":4},
  {"key":"humidity_at_load","label":"Humedad relativa al cargar (%)","type":"number","required":false,"min":0,"max":100,"order":5},
  {"key":"notes","label":"Observaciones","type":"textarea","required":false,"order":6}
]'),

-- Procesamiento/tamizado: límites del proceso (usa el campo "default" como valor del límite)
(NULL, 'procesamiento', '[
  {"key":"merma_threshold_pct","label":"Umbral merma esperada (%)","type":"number","required":false,"min":0,"max":100,"default":5,"order":1}
]');

RESET ALL;