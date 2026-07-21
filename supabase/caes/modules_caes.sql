-- ============================================================
-- MÓDULOS — CAES
--
-- Estos 10 módulos ya existían en supabase/modules_seed.sql (no son
-- nuevos) -- se extraen acá, en su propia carpeta/archivo, para que el
-- set de "carga en la nube para CAES" quede autocontenido y separado del
-- de Norandino, como pediste.
--
-- ⚠️ Todavía no confirmados como reales (a diferencia de los 42 de
-- Norandino, que sí vienen de un CSV real) -- son los que ya estaban
-- placeholder desde el principio del proyecto. Reemplazar cuando llegue
-- la lista real de módulos de CAES.
--
-- Carga manual: correr primero (los usuarios de users_caes.sql dependen
-- de que estos módulos ya existan).
-- ============================================================

INSERT INTO public.coop_modules (id, name, cooperative_id) VALUES
  ('bb020000-0000-0000-0000-000000000001', 'Valle Quiroz', '550e8400-e29b-41d4-a716-446655440002'),
  ('bb020000-0000-0000-0000-000000000002', 'Valle Piura', '550e8400-e29b-41d4-a716-446655440002'),
  ('bb020000-0000-0000-0000-000000000003', 'Chulucanas', '550e8400-e29b-41d4-a716-446655440002'),
  ('bb020000-0000-0000-0000-000000000004', 'La Matanza', '550e8400-e29b-41d4-a716-446655440002'),
  ('bb020000-0000-0000-0000-000000000005', 'Bigote', '550e8400-e29b-41d4-a716-446655440002'),
  ('bb020000-0000-0000-0000-000000000006', 'Yamango', '550e8400-e29b-41d4-a716-446655440002'),
  ('bb020000-0000-0000-0000-000000000007', 'Palo Blanco', '550e8400-e29b-41d4-a716-446655440002'),
  ('bb020000-0000-0000-0000-000000000008', 'Serrán', '550e8400-e29b-41d4-a716-446655440002'),
  ('bb020000-0000-0000-0000-000000000009', 'San Juan', '550e8400-e29b-41d4-a716-446655440002'),
  ('bb020000-0000-0000-0000-000000000010', 'Vilcayal', '550e8400-e29b-41d4-a716-446655440002')
ON CONFLICT (id) DO NOTHING;
