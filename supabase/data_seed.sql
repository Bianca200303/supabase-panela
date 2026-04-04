-- ============================================================
-- SEED BASE: Solo datos de referencia fijos
-- cooperativas, grupos de exclusión y certificados
-- ============================================================

SET session_replication_role = replica;

-- 1. Cooperativas
INSERT INTO "public"."cooperatives" ("id","name","code","created_at","updated_at","is_active","cane_density") VALUES
('550e8400-e29b-41d4-a716-446655440001','Cooperativa Agraria Norandino','NORANDINO','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true,1.0500),
('550e8400-e29b-41d4-a716-446655440002','Cooperativa Agraria Ecológica y Solidaria Piura','CAES','2026-03-10 20:56:08.357766-05','2026-03-10 20:56:08.357766-05',true,1.0500);

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

RESET ALL;