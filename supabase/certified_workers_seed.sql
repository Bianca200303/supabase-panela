-- ============================================================
-- TRABAJADORES CERTIFICADOS (certified_workers) — PLANTILLA CON DATOS
-- FALSOS, para reemplazar nombres cuando llegue la lista real.
--
-- Referencia: supabase/mi-proyecto/CERTIFIED_WORKERS.md (queries de
-- gestión). Solo first_name, last_name, cooperative_id y coop_module_id
-- son obligatorios -- position/dni/certified_since/certified_until/notes
-- quedan sin completar acá a propósito.
--
-- 1 trabajador de ejemplo por cada uno de los 42 módulos reales de
-- Norandino (ver modules_seed.sql) -- el comentario al final de cada
-- fila indica a qué módulo corresponde, para que sea fácil ubicar cuál
-- reemplazar. Agregá más filas por módulo según haga falta (no hay
-- límite de 1 por módulo, esto es solo el punto de partida).
--
-- ⚠️ TODOS LOS NOMBRES SON FALSOS -- reemplazar antes de usar en serio.
--
-- Carga manual: correr después de modules_seed.sql (necesita que
-- coop_modules ya tenga las filas de Norandino).
-- ============================================================

INSERT INTO public.certified_workers (first_name, last_name, cooperative_id, coop_module_id) VALUES
  ('Juan', 'Gonzales', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001'),  -- Appagrop Jilili
  ('Maria', 'Rodriguez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),  -- Asoc Flor de caña
  ('Pedro', 'Perez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000003'),  -- Cataratas de Limón
  ('Ana', 'Sanchez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000004'),  -- Cruz de Silahua Frias
  ('Luis', 'Ramirez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000005'),  -- Cuatro Reynas
  ('Carmen', 'Torres', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000006'),  -- Dios Divino
  ('Jose', 'Flores', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000007'),  -- Dios es Amor
  ('Rosa', 'Rivera', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000008'),  -- Divino Jesus
  ('Carlos', 'Gomez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000009'),  -- Don Polo
  ('Elena', 'Diaz', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000010'),  -- El Anibal
  ('Miguel', 'Reyes', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000011'),  -- El Aniceto
  ('Laura', 'Morales', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000012'),  -- El Chavo
  ('Jorge', 'Ortiz', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000013'),  -- El Checo
  ('Sofia', 'Gutierrez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000014'),  -- El Hueco
  ('Diego', 'Chavez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000015'),  -- El Nogal
  ('Patricia', 'Ramos', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000016'),  -- El Papayal
  ('Manuel', 'Vargas', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000017'),  -- Flor de Caña
  ('Isabel', 'Castro', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000018'),  -- Fundo Chinchay
  ('Ricardo', 'Silva', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000019'),  -- Getsemani
  ('Cecilia', 'Rojas', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000020'),  -- Jesus el camino
  ('Fernando', 'Gonzales', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000021'),  -- Juan Angel
  ('Teresa', 'Rodriguez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000022'),  -- La Melchorita
  ('Alberto', 'Perez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000023'),  -- La Vega
  ('Silvia', 'Sanchez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000024'),  -- Los Flores
  ('Raul', 'Ramirez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000025'),  -- Los Gemelos
  ('Monica', 'Torres', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000026'),  -- Los Hermanos Niño
  ('Victor', 'Flores', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000027'),  -- Los Herrera
  ('Gloria', 'Rivera', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000028'),  -- Manos Unidas
  ('Hugo', 'Gomez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000029'),  -- Mi Cautivo
  ('Beatriz', 'Diaz', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000030'),  -- Mi lindo Belen
  ('Cesar', 'Reyes', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000031'),  -- Niño Jesus
  ('Norma', 'Morales', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000032'),  -- Niño Tocto
  ('Oscar', 'Ortiz', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000033'),  -- Pan de Azucar
  ('Rocio', 'Gutierrez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000034'),  -- Podero Cautivo
  ('Ivan', 'Chavez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000035'),  -- Rosita y Polito
  ('Susana', 'Ramos', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000036'),  -- San Antonio de Padua
  ('Marco', 'Vargas', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000037'),  -- San Francisco
  ('Julia', 'Castro', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000038'),  -- San Francisco de la Chorrera
  ('Alfredo', 'Silva', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000039'),  -- San Marcos de Sicchez
  ('Karina', 'Rojas', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000040'),  -- San Pedro
  ('Ruben', 'Gonzales', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000041'),  -- San Pedro de Seguiche
  ('Yolanda', 'Rodriguez', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000042');  -- Virgen del Cisne
