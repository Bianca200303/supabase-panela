-- ============================================================
-- USUARIOS DE PRUEBA — CAES (TODO FALSO, para desplegar en la nube
-- sin datos reales todavía). Mismo mecanismo técnico que
-- real_users_seed.sql de Norandino, pero con nombres/DNIs inventados.
--
-- Requiere que modules_caes.sql ya se haya corrido antes.
-- DNIs usados: 91000000, 91000001-91000040 (admin_modulo + productores),
-- 91000098-91000099 (técnicos) -- rango exclusivo de CAES, no pisa con
-- los DNIs reales de Norandino ni con sus técnicos 99000001/02.
--
-- Login móvil: usuario = DNI, contraseña = el mismo DNI.
-- ============================================================

-- ── ADMIN WEB — CAES ─────────────────────────────────────────
-- Usuario: admincaes / Contraseña: admincaes
DO $$
DECLARE v_auth_id uuid;
BEGIN
  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(),
    'authenticated', 'authenticated',
    'admincaes.CAES@web.local',
    crypt('admincaes', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '', '', ''
  ) RETURNING id INTO v_auth_id;
  INSERT INTO public.web_users (auth_user_id, cooperative_id, username, first_name, last_name, role, is_active)
  VALUES (v_auth_id, '550e8400-e29b-41d4-a716-446655440002', 'admincaes', 'Admin', 'CAES', 'admin_web', true);
END $$;

-- ── ADMIN DE SISTEMA (inventado) — Carla Mendoza (DNI 91000000) ──
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('91000000', 'Carla', 'Mendoza', '550e8400-e29b-41d4-a716-446655440002', 'admin_sistema');
SELECT public.setup_dni_user_auth('91000000', '91000000', '550e8400-e29b-41d4-a716-446655440002'::uuid);

-- ── TÉCNICOS DE CAMPO (inventados) ────────────────────────────
-- Técnico 1: Elmer Vite (DNI 91000098) — a cargo de:
--   Valle Quiroz
--   Valle Piura
--   Chulucanas
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('91000098', 'Elmer', 'Vite', '550e8400-e29b-41d4-a716-446655440002', 'tecnico_campo');
SELECT public.setup_dni_user_auth('91000098', '91000098', '550e8400-e29b-41d4-a716-446655440002'::uuid);
INSERT INTO public.user_module_assignments (user_id, cooperative_id, coop_module_id) VALUES
  ('91000098', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000001'),
  ('91000098', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000002'),
  ('91000098', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000003');

-- Técnico 2: Yesenia Panta (DNI 91000099) — a cargo de:
--   La Matanza
--   Bigote
--   Yamango
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('91000099', 'Yesenia', 'Panta', '550e8400-e29b-41d4-a716-446655440002', 'tecnico_campo');
SELECT public.setup_dni_user_auth('91000099', '91000099', '550e8400-e29b-41d4-a716-446655440002'::uuid);
INSERT INTO public.user_module_assignments (user_id, cooperative_id, coop_module_id) VALUES
  ('91000099', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000004'),
  ('91000099', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000005'),
  ('91000099', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000006');

-- ── PERSONAS DE PRUEBA (10 admin_modulo + 30 productor, FALSOS) ──
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('91000001', 'Rosa', 'Vilchez', '550e8400-e29b-41d4-a716-446655440002', 'admin_modulo'),  -- Valle Quiroz
  ('91000005', 'Flor', 'Cruz', '550e8400-e29b-41d4-a716-446655440002', 'admin_modulo'),  -- Valle Piura
  ('91000009', 'Yesenia', 'Juarez', '550e8400-e29b-41d4-a716-446655440002', 'admin_modulo'),  -- Chulucanas
  ('91000013', 'Marisol', 'Zeta', '550e8400-e29b-41d4-a716-446655440002', 'admin_modulo'),  -- La Matanza
  ('91000017', 'Gladys', 'More', '550e8400-e29b-41d4-a716-446655440002', 'admin_modulo'),  -- Bigote
  ('91000021', 'Nora', 'Vilchez', '550e8400-e29b-41d4-a716-446655440002', 'admin_modulo'),  -- Yamango
  ('91000025', 'Petronila', 'Cruz', '550e8400-e29b-41d4-a716-446655440002', 'admin_modulo'),  -- Palo Blanco
  ('91000029', 'Yesica', 'Juarez', '550e8400-e29b-41d4-a716-446655440002', 'admin_modulo'),  -- Serrán
  ('91000033', 'Teresa', 'Zeta', '550e8400-e29b-41d4-a716-446655440002', 'admin_modulo'),  -- San Juan
  ('91000037', 'Nancy', 'More', '550e8400-e29b-41d4-a716-446655440002', 'admin_modulo'),  -- Vilcayal
  ('91000002', 'Manuel', 'Nunura', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Valle Quiroz
  ('91000003', 'Teresa', 'Puican', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Valle Quiroz
  ('91000004', 'Andres', 'Zapata', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Valle Quiroz
  ('91000006', 'Julio', 'Neira', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Valle Piura
  ('91000007', 'Nancy', 'Coronado', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Valle Piura
  ('91000008', 'Wilder', 'Palacios', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Valle Piura
  ('91000010', 'Percy', 'Chapilliquen', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Chulucanas
  ('91000011', 'Consuelo', 'Ramos', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Chulucanas
  ('91000012', 'Anibal', 'Vite', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Chulucanas
  ('91000014', 'Elmer', 'Guerrero', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- La Matanza
  ('91000015', 'Yolanda', 'Panta', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- La Matanza
  ('91000016', 'Nestor', 'Sandoval', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- La Matanza
  ('91000018', 'Wilfredo', 'Ancajima', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Bigote
  ('91000019', 'Katherine', 'Ruiz', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Bigote
  ('91000020', 'Reynaldo', 'Chero', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Bigote
  ('91000022', 'Segundo', 'Nunura', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Yamango
  ('91000023', 'Vilma', 'Puican', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Yamango
  ('91000024', 'Alcides', 'Zapata', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Yamango
  ('91000026', 'Marino', 'Neira', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Palo Blanco
  ('91000027', 'Zoila', 'Coronado', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Palo Blanco
  ('91000028', 'Eleuterio', 'Palacios', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Palo Blanco
  ('91000030', 'Abelardo', 'Chapilliquen', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Serrán
  ('91000031', 'Rosa', 'Ramos', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Serrán
  ('91000032', 'Manuel', 'Vite', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Serrán
  ('91000034', 'Andres', 'Guerrero', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- San Juan
  ('91000035', 'Flor', 'Panta', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- San Juan
  ('91000036', 'Julio', 'Sandoval', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- San Juan
  ('91000038', 'Wilder', 'Ancajima', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Vilcayal
  ('91000039', 'Yesenia', 'Ruiz', '550e8400-e29b-41d4-a716-446655440002', 'productor'),  -- Vilcayal
  ('91000040', 'Percy', 'Chero', '550e8400-e29b-41d4-a716-446655440002', 'productor');  -- Vilcayal

-- setup_dni_user_auth para todos (admin_modulo + productores)
SELECT public.setup_dni_user_auth('91000001', '91000001', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000005', '91000005', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000009', '91000009', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000013', '91000013', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000017', '91000017', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000021', '91000021', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000025', '91000025', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000029', '91000029', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000033', '91000033', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000037', '91000037', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000002', '91000002', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000003', '91000003', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000004', '91000004', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000006', '91000006', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000007', '91000007', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000008', '91000008', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000010', '91000010', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000011', '91000011', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000012', '91000012', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000014', '91000014', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000015', '91000015', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000016', '91000016', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000018', '91000018', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000019', '91000019', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000020', '91000020', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000022', '91000022', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000023', '91000023', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000024', '91000024', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000026', '91000026', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000027', '91000027', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000028', '91000028', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000030', '91000030', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000031', '91000031', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000032', '91000032', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000034', '91000034', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000035', '91000035', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000036', '91000036', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000038', '91000038', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000039', '91000039', '550e8400-e29b-41d4-a716-446655440002'::uuid);
SELECT public.setup_dni_user_auth('91000040', '91000040', '550e8400-e29b-41d4-a716-446655440002'::uuid);

-- Asignación de módulo (admin_modulo, 10 personas)
INSERT INTO public.user_module_assignments (user_id, cooperative_id, coop_module_id) VALUES
  ('91000001', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000001'),  -- Valle Quiroz
  ('91000005', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000002'),  -- Valle Piura
  ('91000009', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000003'),  -- Chulucanas
  ('91000013', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000004'),  -- La Matanza
  ('91000017', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000005'),  -- Bigote
  ('91000021', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000006'),  -- Yamango
  ('91000025', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000007'),  -- Palo Blanco
  ('91000029', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000008'),  -- Serrán
  ('91000033', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000009'),  -- San Juan
  ('91000037', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000010');  -- Vilcayal

-- Registro como productores (30 personas)
-- id de producers generado con gen_random_uuid() -- no hace falta fijo,
-- las parcelas de abajo lo resuelven por DNI con un subquery.
INSERT INTO public.producers (first_name, last_name, dni, cooperative_id, coop_module_id) VALUES
  ('Manuel', 'Nunura', '91000002', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000001'),  -- Valle Quiroz
  ('Teresa', 'Puican', '91000003', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000001'),  -- Valle Quiroz
  ('Andres', 'Zapata', '91000004', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000001'),  -- Valle Quiroz
  ('Julio', 'Neira', '91000006', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000002'),  -- Valle Piura
  ('Nancy', 'Coronado', '91000007', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000002'),  -- Valle Piura
  ('Wilder', 'Palacios', '91000008', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000002'),  -- Valle Piura
  ('Percy', 'Chapilliquen', '91000010', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000003'),  -- Chulucanas
  ('Consuelo', 'Ramos', '91000011', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000003'),  -- Chulucanas
  ('Anibal', 'Vite', '91000012', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000003'),  -- Chulucanas
  ('Elmer', 'Guerrero', '91000014', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000004'),  -- La Matanza
  ('Yolanda', 'Panta', '91000015', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000004'),  -- La Matanza
  ('Nestor', 'Sandoval', '91000016', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000004'),  -- La Matanza
  ('Wilfredo', 'Ancajima', '91000018', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000005'),  -- Bigote
  ('Katherine', 'Ruiz', '91000019', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000005'),  -- Bigote
  ('Reynaldo', 'Chero', '91000020', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000005'),  -- Bigote
  ('Segundo', 'Nunura', '91000022', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000006'),  -- Yamango
  ('Vilma', 'Puican', '91000023', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000006'),  -- Yamango
  ('Alcides', 'Zapata', '91000024', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000006'),  -- Yamango
  ('Marino', 'Neira', '91000026', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000007'),  -- Palo Blanco
  ('Zoila', 'Coronado', '91000027', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000007'),  -- Palo Blanco
  ('Eleuterio', 'Palacios', '91000028', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000007'),  -- Palo Blanco
  ('Abelardo', 'Chapilliquen', '91000030', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000008'),  -- Serrán
  ('Rosa', 'Ramos', '91000031', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000008'),  -- Serrán
  ('Manuel', 'Vite', '91000032', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000008'),  -- Serrán
  ('Andres', 'Guerrero', '91000034', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000009'),  -- San Juan
  ('Flor', 'Panta', '91000035', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000009'),  -- San Juan
  ('Julio', 'Sandoval', '91000036', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000009'),  -- San Juan
  ('Wilder', 'Ancajima', '91000038', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000010'),  -- Vilcayal
  ('Yesenia', 'Ruiz', '91000039', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000010'),  -- Vilcayal
  ('Percy', 'Chero', '91000040', '550e8400-e29b-41d4-a716-446655440002', 'bb020000-0000-0000-0000-000000000010');  -- Vilcayal

-- Parcelas: 3 por productor, "Parcela <Nombre Apellido> N" (N = 1..3).
INSERT INTO public.plots (producer_id, name)
SELECT p.id, 'Parcela ' || p.first_name || ' ' || p.last_name || ' ' || n
FROM public.producers p
CROSS JOIN generate_series(1, 3) AS n
WHERE p.cooperative_id = '550e8400-e29b-41d4-a716-446655440002'
  AND p.dni IN (
    '91000002', '91000003', '91000004', '91000006', '91000007', '91000008', '91000010', '91000011', '91000012', '91000014', '91000015', '91000016', '91000018', '91000019', '91000020', '91000022', '91000023', '91000024', '91000026', '91000027', '91000028', '91000030', '91000031', '91000032', '91000034', '91000035', '91000036', '91000038', '91000039', '91000040'
  );

-- ============================================================
-- RESUMEN
-- ============================================================
-- 1 admin_web (falso, usuario "admincaes")
-- 1 admin_sistema (falso, Carla Mendoza)
-- 2 tecnico_campo (falsos, 3 módulos cada uno)
-- 10 admin_modulo (falsos, 1 por módulo)
-- 30 productor (falsos, 3 por módulo), cada uno con 3 parcelas (90 plots)
-- Contraseña de todos los usuarios móvil = su propio DNI
-- ============================================================
