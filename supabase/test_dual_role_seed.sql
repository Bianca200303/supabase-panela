-- ============================================================
-- TEST DUAL-ROLE SEED — Norandino
-- Escenario: técnico de campo (5 módulos) + admin de módulo (1 módulo)
--            ambos son también productores en sus propios módulos
-- Cooperativa: Norandino (ya existente en seed.sql)
-- SOLO PARA PRUEBAS — no ejecutar en producción
-- Orden: seed.sql → este archivo (independiente de real_users_seed.sql)
-- DNIs usados: 11500001–11500002 (usuarios), 11600001–11600020 (productores extra)
-- ============================================================

-- ── MÓDULOS DE PRUEBA ─────────────────────────────────────────
-- 5 para el técnico + 1 para el admin = 6 módulos
INSERT INTO public.coop_modules (id, name, cooperative_id) VALUES
  ('bb020000-0000-0000-0000-000000000001', 'San Ignacio',             '550e8400-e29b-41d4-a716-446655440001'),
  ('bb020000-0000-0000-0000-000000000002', 'Jaén',                    '550e8400-e29b-41d4-a716-446655440001'),
  ('bb020000-0000-0000-0000-000000000003', 'Bagua',                   '550e8400-e29b-41d4-a716-446655440001'),
  ('bb020000-0000-0000-0000-000000000004', 'Utcubamba',               '550e8400-e29b-41d4-a716-446655440001'),
  ('bb020000-0000-0000-0000-000000000005', 'Bongará',                 '550e8400-e29b-41d4-a716-446655440001'),
  ('bb020000-0000-0000-0000-000000000006', 'Rodríguez de Mendoza',    '550e8400-e29b-41d4-a716-446655440001');


-- ── TÉCNICO DE CAMPO — Carlos Vásquez (11500001) ─────────────
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('11500001', 'Carlos', 'Vásquez', '550e8400-e29b-41d4-a716-446655440001', 'tecnico_campo');

SELECT public.setup_dni_user_auth('11500001', '11500001', '550e8400-e29b-41d4-a716-446655440001'::uuid);

-- Asignación a los 5 módulos
INSERT INTO public.user_module_assignments (user_id, cooperative_id, coop_module_id) VALUES
  ('11500001', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000001'),
  ('11500001', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000002'),
  ('11500001', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000003'),
  ('11500001', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000004'),
  ('11500001', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000005');

-- Carlos como productor en cada uno de sus 5 módulos (mismo DNI, distinto coop_module_id)
INSERT INTO public.producers (id, first_name, last_name, dni, cooperative_id, coop_module_id) VALUES
  ('cc020000-0000-0000-0001-000000000001', 'Carlos', 'Vásquez', '11500001', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000001'),
  ('cc020000-0000-0000-0001-000000000002', 'Carlos', 'Vásquez', '11500001', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000002'),
  ('cc020000-0000-0000-0001-000000000003', 'Carlos', 'Vásquez', '11500001', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000003'),
  ('cc020000-0000-0000-0001-000000000004', 'Carlos', 'Vásquez', '11500001', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000004'),
  ('cc020000-0000-0000-0001-000000000005', 'Carlos', 'Vásquez', '11500001', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000005');

-- Parcelas de Carlos (una por módulo, nombrada con el módulo)
INSERT INTO public.plots (id, code, producer_id, name) VALUES
  ('dd020000-0000-0000-0001-000000000001', '11500001-1', 'cc020000-0000-0000-0001-000000000001', 'Parcela Vásquez - San Ignacio'),
  ('dd020000-0000-0000-0001-000000000002', '11500001-2', 'cc020000-0000-0000-0001-000000000002', 'Parcela Vásquez - Jaén'),
  ('dd020000-0000-0000-0001-000000000003', '11500001-3', 'cc020000-0000-0000-0001-000000000003', 'Parcela Vásquez - Bagua'),
  ('dd020000-0000-0000-0001-000000000004', '11500001-4', 'cc020000-0000-0000-0001-000000000004', 'Parcela Vásquez - Utcubamba'),
  ('dd020000-0000-0000-0001-000000000005', '11500001-5', 'cc020000-0000-0000-0001-000000000005', 'Parcela Vásquez - Bongará');


-- ── ADMIN DE MÓDULO — María Flores (11500002) ─────────────────
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('11500002', 'María', 'Flores', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo');

SELECT public.setup_dni_user_auth('11500002', '11500002', '550e8400-e29b-41d4-a716-446655440001'::uuid);

-- Asignación a su único módulo
INSERT INTO public.user_module_assignments (user_id, cooperative_id, coop_module_id) VALUES
  ('11500002', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000006');

-- María como productora en su módulo
INSERT INTO public.producers (id, first_name, last_name, dni, cooperative_id, coop_module_id) VALUES
  ('cc020000-0000-0000-0001-000000000006', 'María', 'Flores', '11500002', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000006');

-- Parcela de María
INSERT INTO public.plots (id, code, producer_id, name) VALUES
  ('dd020000-0000-0000-0001-000000000006', '11500002-1', 'cc020000-0000-0000-0001-000000000006', 'Parcela Flores');


-- ── PRODUCTORES EXTRA — MÓDULO ADMIN (Rodríguez de Mendoza) ──
-- 5 productores adicionales al admin → 6 total en ese módulo
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('11600001', 'Juana',    'Quispe',   '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('11600002', 'Roberto',  'Díaz',     '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('11600003', 'Ana',      'Castillo', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('11600004', 'Luis',     'Meza',     '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('11600005', 'Teresa',   'Soto',     '550e8400-e29b-41d4-a716-446655440001', 'productor');

SELECT public.setup_dni_user_auth('11600001', '11600001', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('11600002', '11600002', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('11600003', '11600003', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('11600004', '11600004', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('11600005', '11600005', '550e8400-e29b-41d4-a716-446655440001'::uuid);

INSERT INTO public.producers (id, first_name, last_name, dni, cooperative_id, coop_module_id) VALUES
  ('cc020000-0000-0000-0002-000000000001', 'Juana',   'Quispe',   '11600001', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000006'),
  ('cc020000-0000-0000-0002-000000000002', 'Roberto', 'Díaz',     '11600002', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000006'),
  ('cc020000-0000-0000-0002-000000000003', 'Ana',     'Castillo', '11600003', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000006'),
  ('cc020000-0000-0000-0002-000000000004', 'Luis',    'Meza',     '11600004', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000006'),
  ('cc020000-0000-0000-0002-000000000005', 'Teresa',  'Soto',     '11600005', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000006');

INSERT INTO public.plots (id, code, producer_id, name) VALUES
  ('dd020000-0000-0000-0002-000000000001', '11600001-1', 'cc020000-0000-0000-0002-000000000001', 'Parcela Quispe'),
  ('dd020000-0000-0000-0002-000000000002', '11600002-1', 'cc020000-0000-0000-0002-000000000002', 'Parcela Díaz'),
  ('dd020000-0000-0000-0002-000000000003', '11600003-1', 'cc020000-0000-0000-0002-000000000003', 'Parcela Castillo'),
  ('dd020000-0000-0000-0002-000000000004', '11600004-1', 'cc020000-0000-0000-0002-000000000004', 'Parcela Meza'),
  ('dd020000-0000-0000-0002-000000000005', '11600005-1', 'cc020000-0000-0000-0002-000000000005', 'Parcela Soto');


-- ── PRODUCTORES EXTRA — MÓDULOS DEL TÉCNICO ──────────────────
-- 3 productores adicionales por módulo → 4 total por módulo (incluyendo Carlos)

-- Módulo 1: San Ignacio
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('11600006', 'Félix',   'Guevara', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('11600007', 'Hilda',   'Rojas',   '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('11600008', 'Mario',   'Cubas',   '550e8400-e29b-41d4-a716-446655440001', 'productor');

SELECT public.setup_dni_user_auth('11600006', '11600006', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('11600007', '11600007', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('11600008', '11600008', '550e8400-e29b-41d4-a716-446655440001'::uuid);

INSERT INTO public.producers (id, first_name, last_name, dni, cooperative_id, coop_module_id) VALUES
  ('cc020000-0000-0000-0003-000000000001', 'Félix', 'Guevara', '11600006', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000001'),
  ('cc020000-0000-0000-0003-000000000002', 'Hilda', 'Rojas',   '11600007', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000001'),
  ('cc020000-0000-0000-0003-000000000003', 'Mario', 'Cubas',   '11600008', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000001');

INSERT INTO public.plots (id, code, producer_id, name) VALUES
  ('dd020000-0000-0000-0003-000000000001', '11600006-1', 'cc020000-0000-0000-0003-000000000001', 'Parcela Guevara'),
  ('dd020000-0000-0000-0003-000000000002', '11600007-1', 'cc020000-0000-0000-0003-000000000002', 'Parcela Rojas'),
  ('dd020000-0000-0000-0003-000000000003', '11600008-1', 'cc020000-0000-0000-0003-000000000003', 'Parcela Cubas');

-- Módulo 2: Jaén
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('11600009', 'Celestina', 'Pérez',   '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('11600010', 'Domingo',   'Llanos',  '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('11600011', 'Rosa',      'Herrera', '550e8400-e29b-41d4-a716-446655440001', 'productor');

SELECT public.setup_dni_user_auth('11600009', '11600009', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('11600010', '11600010', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('11600011', '11600011', '550e8400-e29b-41d4-a716-446655440001'::uuid);

INSERT INTO public.producers (id, first_name, last_name, dni, cooperative_id, coop_module_id) VALUES
  ('cc020000-0000-0000-0003-000000000004', 'Celestina', 'Pérez',   '11600009', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000002'),
  ('cc020000-0000-0000-0003-000000000005', 'Domingo',   'Llanos',  '11600010', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000002'),
  ('cc020000-0000-0000-0003-000000000006', 'Rosa',      'Herrera', '11600011', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000002');

INSERT INTO public.plots (id, code, producer_id, name) VALUES
  ('dd020000-0000-0000-0003-000000000004', '11600009-1', 'cc020000-0000-0000-0003-000000000004', 'Parcela Pérez'),
  ('dd020000-0000-0000-0003-000000000005', '11600010-1', 'cc020000-0000-0000-0003-000000000005', 'Parcela Llanos'),
  ('dd020000-0000-0000-0003-000000000006', '11600011-1', 'cc020000-0000-0000-0003-000000000006', 'Parcela Herrera');

-- Módulo 3: Bagua
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('11600012', 'Augusto',  'Toro',   '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('11600013', 'Milagros', 'Cruz',   '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('11600014', 'Isidro',   'Vargas', '550e8400-e29b-41d4-a716-446655440001', 'productor');

SELECT public.setup_dni_user_auth('11600012', '11600012', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('11600013', '11600013', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('11600014', '11600014', '550e8400-e29b-41d4-a716-446655440001'::uuid);

INSERT INTO public.producers (id, first_name, last_name, dni, cooperative_id, coop_module_id) VALUES
  ('cc020000-0000-0000-0003-000000000007', 'Augusto',  'Toro',   '11600012', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000003'),
  ('cc020000-0000-0000-0003-000000000008', 'Milagros', 'Cruz',   '11600013', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000003'),
  ('cc020000-0000-0000-0003-000000000009', 'Isidro',   'Vargas', '11600014', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000003');

INSERT INTO public.plots (id, code, producer_id, name) VALUES
  ('dd020000-0000-0000-0003-000000000007', '11600012-1', 'cc020000-0000-0000-0003-000000000007', 'Parcela Toro'),
  ('dd020000-0000-0000-0003-000000000008', '11600013-1', 'cc020000-0000-0000-0003-000000000008', 'Parcela Cruz'),
  ('dd020000-0000-0000-0003-000000000009', '11600014-1', 'cc020000-0000-0000-0003-000000000009', 'Parcela Vargas');

-- Módulo 4: Utcubamba
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('11600015', 'Natividad', 'Reyes',   '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('11600016', 'Benigno',   'Chávez',  '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('11600017', 'Olga',      'Mendoza', '550e8400-e29b-41d4-a716-446655440001', 'productor');

SELECT public.setup_dni_user_auth('11600015', '11600015', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('11600016', '11600016', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('11600017', '11600017', '550e8400-e29b-41d4-a716-446655440001'::uuid);

INSERT INTO public.producers (id, first_name, last_name, dni, cooperative_id, coop_module_id) VALUES
  ('cc020000-0000-0000-0003-000000000010', 'Natividad', 'Reyes',   '11600015', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000004'),
  ('cc020000-0000-0000-0003-000000000011', 'Benigno',   'Chávez',  '11600016', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000004'),
  ('cc020000-0000-0000-0003-000000000012', 'Olga',      'Mendoza', '11600017', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000004');

INSERT INTO public.plots (id, code, producer_id, name) VALUES
  ('dd020000-0000-0000-0003-000000000010', '11600015-1', 'cc020000-0000-0000-0003-000000000010', 'Parcela Reyes'),
  ('dd020000-0000-0000-0003-000000000011', '11600016-1', 'cc020000-0000-0000-0003-000000000011', 'Parcela Chávez'),
  ('dd020000-0000-0000-0003-000000000012', '11600017-1', 'cc020000-0000-0000-0003-000000000012', 'Parcela Mendoza');

-- Módulo 5: Bongará
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('11600018', 'Rufino',  'Campos', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('11600019', 'Inés',    'Huamán', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('11600020', 'Pascual', 'Torres', '550e8400-e29b-41d4-a716-446655440001', 'productor');

SELECT public.setup_dni_user_auth('11600018', '11600018', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('11600019', '11600019', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('11600020', '11600020', '550e8400-e29b-41d4-a716-446655440001'::uuid);

INSERT INTO public.producers (id, first_name, last_name, dni, cooperative_id, coop_module_id) VALUES
  ('cc020000-0000-0000-0003-000000000013', 'Rufino',  'Campos', '11600018', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000005'),
  ('cc020000-0000-0000-0003-000000000014', 'Inés',    'Huamán', '11600019', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000005'),
  ('cc020000-0000-0000-0003-000000000015', 'Pascual', 'Torres', '11600020', '550e8400-e29b-41d4-a716-446655440001', 'bb020000-0000-0000-0000-000000000005');

INSERT INTO public.plots (id, code, producer_id, name) VALUES
  ('dd020000-0000-0000-0003-000000000013', '11600018-1', 'cc020000-0000-0000-0003-000000000013', 'Parcela Campos'),
  ('dd020000-0000-0000-0003-000000000014', '11600019-1', 'cc020000-0000-0000-0003-000000000014', 'Parcela Huamán'),
  ('dd020000-0000-0000-0003-000000000015', '11600020-1', 'cc020000-0000-0000-0003-000000000015', 'Parcela Torres');


-- ============================================================
-- RESUMEN
-- ============================================================
-- Técnico  : Carlos Vásquez   (DNI 11500001) — 5 módulos, productor en cada uno
-- Admin    : María Flores     (DNI 11500002) — 1 módulo,  productora en él
--
-- Módulo 1 San Ignacio       (4 prod): Carlos, Félix, Hilda, Mario
-- Módulo 2 Jaén              (4 prod): Carlos, Celestina, Domingo, Rosa
-- Módulo 3 Bagua             (4 prod): Carlos, Augusto, Milagros, Isidro
-- Módulo 4 Utcubamba         (4 prod): Carlos, Natividad, Benigno, Olga
-- Módulo 5 Bongará           (4 prod): Carlos, Rufino, Inés, Pascual
-- Módulo 6 Rodríguez Mendoza (6 prod): María, Juana, Roberto, Ana, Luis, Teresa
--
-- Contraseña de todos los usuarios = su propio DNI
-- ============================================================
