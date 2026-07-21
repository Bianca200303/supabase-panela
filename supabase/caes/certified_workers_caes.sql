-- ============================================================
-- TRABAJADORES CERTIFICADOS (certified_workers) — CAES, PLANTILLA CON
-- DATOS FALSOS, para reemplazar nombres cuando llegue la lista real.
--
-- Referencia: supabase/mi-proyecto/CERTIFIED_WORKERS.md. Mismo criterio
-- que supabase/certified_workers_seed.sql de Norandino: 1 trabajador de
-- ejemplo por cada uno de los 10 módulos de CAES (comentario indica el
-- módulo). Agregá más filas por módulo según haga falta.
--
-- ⚠️ TODOS LOS NOMBRES SON FALSOS.
--
-- Carga manual: correr después de modules_caes.sql.
-- ============================================================

INSERT INTO public.certified_workers (first_name, last_name, cooperative_id, coop_module_id) VALUES
  ('Rocio', 'Vilchez', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000001'),  -- Valle Quiroz
  ('Ivan', 'Nunura', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000002'),  -- Valle Piura
  ('Susana', 'Puican', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000003'),  -- Chulucanas
  ('Marco', 'Zapata', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000004'),  -- La Matanza
  ('Julia', 'Cruz', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000005'),  -- Bigote
  ('Alfredo', 'Neira', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000006'),  -- Yamango
  ('Karina', 'Coronado', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000007'),  -- Palo Blanco
  ('Ruben', 'Palacios', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000008'),  -- Serrán
  ('Yolanda', 'Juarez', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000009'),  -- San Juan
  ('Cesar', 'Chapilliquen', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000010');  -- Vilcayal
