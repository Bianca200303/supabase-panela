-- ============================================================
-- USUARIOS REALES — Norandino
-- Reemplaza a test_seed.sql para este entorno: datos reales, no de
-- prueba. Fuente: usuarios_norandino.csv (123 personas), más 1 admin
-- de sistema, 1 admin web y 2 técnicos de campo inventados (sin datos
-- reales aún).
--
-- Requiere que modules_seed.sql ya se haya corrido antes (los
-- coop_modules referenciados acá deben existir).
--
-- Login móvil: usuario = DNI, contraseña = el mismo DNI (así está
-- diseñado el sistema, via setup_dni_user_auth).
--
-- No correr junto con test_seed.sql / test_dual_role_seed.sql —
-- son alternativos, no complementarios.
-- ============================================================

-- ── ADMIN WEB — Norandino ────────────────────────────────────
-- Usuario: biancaseminario / Contraseña: biancaseminario
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
    'biancaseminario.NORANDINO@web.local',
    crypt('biancaseminario', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '', '', ''
  ) RETURNING id INTO v_auth_id;
  INSERT INTO public.web_users (auth_user_id, cooperative_id, username, first_name, last_name, role, is_active)
  VALUES (v_auth_id, '550e8400-e29b-41d4-a716-446655440001', 'biancaseminario', 'Bianca', 'Seminario', 'admin_web', true);
END $$;

-- ── ADMIN DE SISTEMA — Bianca Seminario ─────────────────────
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('72709528', 'Bianca', 'Seminario', '550e8400-e29b-41d4-a716-446655440001', 'admin_sistema');
SELECT public.setup_dni_user_auth('72709528', '72709528', '550e8400-e29b-41d4-a716-446655440001'::uuid);

-- ── TÉCNICOS DE CAMPO (inventados — reemplazar cuando haya datos reales) ──
-- Técnico 1: Marco Antonio Reto Silva (DNI 99000001) — a cargo de:
--   Appagrop Jilili
--   Asoc Flor de caña
--   Cataratas de Limón
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('99000001', 'Marco Antonio', 'Reto Silva', '550e8400-e29b-41d4-a716-446655440001', 'tecnico_campo');
SELECT public.setup_dni_user_auth('99000001', '99000001', '550e8400-e29b-41d4-a716-446655440001'::uuid);
INSERT INTO public.user_module_assignments (user_id, cooperative_id, coop_module_id) VALUES
  ('99000001', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001'),
  ('99000001', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('99000001', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000003');

-- Técnico 2: Diana Elizabeth Correa Vega (DNI 99000002) — a cargo de:
--   Cruz de Silahua Frias
--   Cuatro Reynas
--   Dios Divino
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('99000002', 'Diana Elizabeth', 'Correa Vega', '550e8400-e29b-41d4-a716-446655440001', 'tecnico_campo');
SELECT public.setup_dni_user_auth('99000002', '99000002', '550e8400-e29b-41d4-a716-446655440001'::uuid);
INSERT INTO public.user_module_assignments (user_id, cooperative_id, coop_module_id) VALUES
  ('99000002', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000004'),
  ('99000002', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000005'),
  ('99000002', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000006');

-- ── PERSONAS REALES (usuarios_norandino.csv, 123 registros) ────

-- Usuarios (login móvil = DNI para los 123)
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('03103434', 'Alcivar', 'Abad Cordova', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('48056611', 'Antenor', 'Abad Culquicondor', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('47865597', 'Arsalio', 'Aniceto Chamba', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03100220', 'Eulalio', 'Aniceto Vasquez', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03097267', 'Sebastian', 'Castillo Huanca', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('43947198', 'Cesar Augusto', 'Chinchay Espinoza', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('47755270', 'Gabino', 'Chinchay Mija', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03101538', 'Pedro', 'Cordova Chamba', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('45427360', 'Afrodicio', 'Cordova Rea', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('42396540', 'Hipolito', 'Cordova Rea', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('42037856', 'Jose Confesor', 'Cordova Rea', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('42651825', 'Almilcar', 'Cordova Saguma', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03102853', 'Bacilio', 'Cruz Morocho', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('46966969', 'Jose', 'Culqicondor Vasquez', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('02645099', 'Anaximandro', 'Farfan Marchan', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03100105', 'Avilio', 'Farfan Marchan', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03101715', 'Sabino', 'Guerrero Correa', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('47217869', 'Milton', 'Herrera Alberca', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('80333458', 'Natividad', 'Juarez Navarro', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('02771828', 'Regulo', 'Mijahuanga Maza', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('42879754', 'Duberly', 'Niño Merino', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03128655', 'Silvino', 'Pardo Abad', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03099742', 'Jorge', 'Parrilla San Martin', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('80440237', 'Teofilo', 'Pinta Mija', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03097955', 'Victorino', 'Portocarrero Chuquihuanga', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03097656', 'Ramos', 'Abad Morocho', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03096997', 'Pedro Pablo', 'Rivera Giron', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03102852', 'Wilmer', 'Sanchez Niño', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('44464818', 'Serafin', 'Medina Cunyarache', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('44271269', 'Delmer', 'Soto Rivera', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('42633120', 'Oscar', 'Yangua Calle', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03089281', 'Rodolfo Gilberto', 'Yangua Chamba', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('46033683', 'Elfer', 'Yangua Rios', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03101595', 'Francisco', 'Yangua Valle', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('07621970', 'Segundo Polidoro', 'Maza Portocarrero', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('42615192', 'Jose Elias', 'Berru Yanayaco', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('80450990', 'Israel', 'Cordova Chininin', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03097689', 'Salazar', 'Culquicondor Valle', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03103003', 'Herlandes', 'Campos Cordova', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('44894036', 'Edwuar', 'Flores Calle', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('80336961', 'Arimeldes', 'Niño Rios', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03598688', 'Bartolo', 'Ordoñes Correa', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('42668723', 'Holguin', 'Rios Vicente', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03112614', 'Esban', 'Timoteo Chinchay', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03096470', 'Julio', 'Vicente Encalada', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('48472088', 'Hector Raul', 'Herrera Alberca', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03110877', 'Lider', 'Neyra Saavedra', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('80376773', 'Bladimiro', 'Medina Paucar', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03090543', 'Segundo Isaias', 'Culquicondor Cunya', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('45014680', 'Jilmer Leonel', 'Abad Valencia', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03096616', 'Romel Gabriel', 'Villavicencio Lazo', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03096883', 'Marleny del Socorro', 'Alvarado Saguma', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03112606', 'Pedro Pablo', 'Alvarado Jimenez', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03102898', 'Wilmer', 'Chininin Pintado', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('80550593', 'Patrocinia', 'Jimenez Vicente', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('80525537', 'Rolando', 'Campos Cordova', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('47434245', 'Elber', 'Chinchay Guerrero', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('42496406', 'Darwin', 'Morocho Rosales', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('44269205', 'Renelmo', 'Tocto Alberca', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('46558684', 'Ivan', 'Niño Soto', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('46078661', 'Rolando', 'Tocto Alberca', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('41951208', 'Serbulo Jose', 'Marchan Culquicondor', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03128720', 'Carlos', 'Cruz Morocho', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('80376755', 'Humberto', 'Portocarrero Torres', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('48587780', 'Alvaro', 'Chinchay Espinosa', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('80485588', 'Filadelfo', 'Flores Saavedra', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03097304', 'Juan', 'Rondoy Maza', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03097749', 'Arnoldo', 'Correa Yangua', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03097950', 'Aureliano', 'Rivera Portocarrero', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('41469245', 'Guillermo', 'Berru Calle', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('45228736', 'Joel', 'Berru Calle', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('80451731', 'Manuel', 'Yangua Chinchay', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03128746', 'Francisco', 'Chininin Yangua', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03122274', 'Adelmo', 'Campos Cordova', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03103044', 'Felicino', 'Marchan Culquicondor', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03101497', 'Maximo', 'Yangua Sarango', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03111364', 'Dorinda', 'Huaman de Huacchillo', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('46639962', 'Segundo Modesto', 'Abad Valencia', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03112634', 'Confesor', 'Maldonado Huanca', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('43642999', 'Misael', 'Culquicondor Giron', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('43171707', 'Tito', 'Cardenas Portocarrero', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03100556', 'Patricio', 'Silva Guerrero', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('42831629', 'Edwin Martin', 'Quinde Criollo', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03102855', 'Arcadio', 'Rios Jabo', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03089297', 'Felix', 'Chamba Yangua', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('41952266', 'Hedil', 'Correa Niño', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('43164788', 'Melber', 'Correa Niño', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('02863613', 'Francisco', 'Ocampos Giron', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03107898', 'Pedro', 'Valle Pardo', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('44950927', 'Segundo Hilario', 'Yangua Chuquicondor', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('42565433', 'Alexander', 'Niño Correa', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03103597', 'Anibal', 'Niño Abad', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('76444959', 'Brayam', 'Niño Abad', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('70016320', 'Cristian Anderson', 'Balarezo Marchan', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('42108534', 'Robert Charles', 'Culquicondor Avila', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('80666083', 'Eber', 'Rivera Aguilar', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03102374', 'Indalecio', 'Aguilar Niño', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('46681671', 'Martin', 'Parrilla Vasquez', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03879126', 'Etelvina', 'Rios Jabo', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03101523', 'Valerio', 'Chinchay Niño', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('43947154', 'Sabino', 'Yangua Chinchay', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('76358227', 'Manuel', 'Mendez Jimenez', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('77919171', 'Eduar', 'Yangua Valle', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('45170278', 'Draucin', 'Pardo Abad', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03127188', 'Jose Felizardo', 'Abad Robledo', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('43947145', 'Elena', 'Jimenez Yangua', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('48591655', 'Alicia', 'Chininin Rondoy', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('45406637', 'Jheyson Jhoan', 'Morocho Chinchay', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('03100765', 'Lilia Del Carmen', 'Chininin De Rios', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('43501140', 'Wilson', 'Tocto Campoverde', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('02806045', 'Ofelia', 'Cortez Rivera', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03112218', 'Franklin', 'Yanayaco Mijahuanga', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03111354', 'Nelso', 'Villalta Ulloa', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('02803982', 'Domingo', 'Llacsahuanga Rivera', '550e8400-e29b-41d4-a716-446655440001', 'admin_modulo'),
  ('73688715', 'Waldir Dennis', 'Yanayaco Valencia', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03099717', 'Fidel', 'Reyes Lloclla', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03110639', 'Senecio', 'Reyes Liviapoma', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03112220', 'Indalecio', 'Yanayaco Mijahuanga', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03110661', 'Jorge Raul', 'Jimenez Troncos', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03099598', 'Pascual', 'Llapapasca Ulloa', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03084424', 'Manuel', 'Cueva Rivera', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03081157', 'Elvira', 'Abad Rosillo', '550e8400-e29b-41d4-a716-446655440001', 'productor'),
  ('03087351', 'Amaro', 'Herrera Abad', '550e8400-e29b-41d4-a716-446655440001', 'productor');

SELECT public.setup_dni_user_auth('03103434', '03103434', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('48056611', '48056611', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('47865597', '47865597', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03100220', '03100220', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03097267', '03097267', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('43947198', '43947198', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('47755270', '47755270', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03101538', '03101538', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('45427360', '45427360', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('42396540', '42396540', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('42037856', '42037856', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('42651825', '42651825', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03102853', '03102853', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('46966969', '46966969', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('02645099', '02645099', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03100105', '03100105', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03101715', '03101715', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('47217869', '47217869', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('80333458', '80333458', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('02771828', '02771828', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('42879754', '42879754', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03128655', '03128655', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03099742', '03099742', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('80440237', '80440237', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03097955', '03097955', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03097656', '03097656', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03096997', '03096997', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03102852', '03102852', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('44464818', '44464818', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('44271269', '44271269', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('42633120', '42633120', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03089281', '03089281', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('46033683', '46033683', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03101595', '03101595', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('07621970', '07621970', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('42615192', '42615192', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('80450990', '80450990', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03097689', '03097689', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03103003', '03103003', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('44894036', '44894036', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('80336961', '80336961', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03598688', '03598688', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('42668723', '42668723', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03112614', '03112614', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03096470', '03096470', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('48472088', '48472088', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03110877', '03110877', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('80376773', '80376773', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03090543', '03090543', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('45014680', '45014680', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03096616', '03096616', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03096883', '03096883', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03112606', '03112606', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03102898', '03102898', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('80550593', '80550593', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('80525537', '80525537', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('47434245', '47434245', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('42496406', '42496406', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('44269205', '44269205', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('46558684', '46558684', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('46078661', '46078661', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('41951208', '41951208', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03128720', '03128720', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('80376755', '80376755', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('48587780', '48587780', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('80485588', '80485588', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03097304', '03097304', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03097749', '03097749', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03097950', '03097950', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('41469245', '41469245', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('45228736', '45228736', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('80451731', '80451731', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03128746', '03128746', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03122274', '03122274', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03103044', '03103044', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03101497', '03101497', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03111364', '03111364', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('46639962', '46639962', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03112634', '03112634', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('43642999', '43642999', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('43171707', '43171707', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03100556', '03100556', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('42831629', '42831629', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03102855', '03102855', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03089297', '03089297', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('41952266', '41952266', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('43164788', '43164788', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('02863613', '02863613', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03107898', '03107898', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('44950927', '44950927', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('42565433', '42565433', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03103597', '03103597', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('76444959', '76444959', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('70016320', '70016320', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('42108534', '42108534', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('80666083', '80666083', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03102374', '03102374', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('46681671', '46681671', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03879126', '03879126', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03101523', '03101523', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('43947154', '43947154', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('76358227', '76358227', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('77919171', '77919171', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('45170278', '45170278', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03127188', '03127188', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('43947145', '43947145', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('48591655', '48591655', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('45406637', '45406637', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03100765', '03100765', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('43501140', '43501140', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('02806045', '02806045', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03112218', '03112218', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03111354', '03111354', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('02803982', '02803982', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('73688715', '73688715', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03099717', '03099717', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03110639', '03110639', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03112220', '03112220', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03110661', '03110661', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03099598', '03099598', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03084424', '03084424', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03081157', '03081157', '550e8400-e29b-41d4-a716-446655440001'::uuid);
SELECT public.setup_dni_user_auth('03087351', '03087351', '550e8400-e29b-41d4-a716-446655440001'::uuid);

-- Asignación de módulo (admin_modulo, 43 personas)
INSERT INTO public.user_module_assignments (user_id, cooperative_id, coop_module_id) VALUES
  ('03103434', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000003'),
  ('48056611', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000029'),
  ('47865597', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000011'),
  ('03100220', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000020'),
  ('43947198', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000022'),
  ('47755270', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000018'),
  ('42037856', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000040'),
  ('42651825', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000012'),
  ('46966969', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000007'),
  ('02645099', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000036'),
  ('03101715', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000015'),
  ('47217869', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000027'),
  ('42879754', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000017'),
  ('03099742', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000033'),
  ('03097656', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000041'),
  ('44464818', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000013'),
  ('44271269', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000030'),
  ('03089281', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000008'),
  ('07621970', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000009'),
  ('44894036', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000024'),
  ('80336961', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000026'),
  ('03112614', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001'),
  ('03110877', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000035'),
  ('80376773', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000005'),
  ('03090543', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000028'),
  ('47434245', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000025'),
  ('42496406', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000037'),
  ('46558684', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000032'),
  ('41951208', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000019'),
  ('03097304', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000021'),
  ('03097950', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000016'),
  ('41469245', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000004'),
  ('80451731', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000038'),
  ('46639962', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000014'),
  ('43171707', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000042'),
  ('43164788', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000031'),
  ('44950927', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000006'),
  ('03103597', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000010'),
  ('76358227', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000034'),
  ('45170278', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('45406637', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000037'),
  ('43501140', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000023'),
  ('02803982', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000039');

-- Registro como productores (rol productor, 80 personas)
-- id de producers generado con gen_random_uuid() -- no hace falta fijo,
-- las parcelas de abajo lo resuelven por DNI con un subquery.
INSERT INTO public.producers (first_name, last_name, dni, cooperative_id, coop_module_id) VALUES
  ('Sebastian', 'Castillo Huanca', '03097267', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001'),
  ('Pedro', 'Cordova Chamba', '03101538', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000040'),
  ('Afrodicio', 'Cordova Rea', '45427360', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000040'),
  ('Hipolito', 'Cordova Rea', '42396540', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000040'),
  ('Bacilio', 'Cruz Morocho', '03102853', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Avilio', 'Farfan Marchan', '03100105', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000036'),
  ('Natividad', 'Juarez Navarro', '80333458', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000003'),
  ('Regulo', 'Mijahuanga Maza', '02771828', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001'),
  ('Silvino', 'Pardo Abad', '03128655', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Teofilo', 'Pinta Mija', '80440237', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001'),
  ('Victorino', 'Portocarrero Chuquihuanga', '03097955', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000030'),
  ('Pedro Pablo', 'Rivera Giron', '03096997', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001'),
  ('Wilmer', 'Sanchez Niño', '03102852', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Oscar', 'Yangua Calle', '42633120', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000008'),
  ('Elfer', 'Yangua Rios', '46033683', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Francisco', 'Yangua Valle', '03101595', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Jose Elias', 'Berru Yanayaco', '42615192', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001'),
  ('Israel', 'Cordova Chininin', '80450990', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000003'),
  ('Salazar', 'Culquicondor Valle', '03097689', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000003'),
  ('Herlandes', 'Campos Cordova', '03103003', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000003'),
  ('Bartolo', 'Ordoñes Correa', '03598688', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000036'),
  ('Holguin', 'Rios Vicente', '42668723', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Julio', 'Vicente Encalada', '03096470', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001'),
  ('Hector Raul', 'Herrera Alberca', '48472088', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000027'),
  ('Jilmer Leonel', 'Abad Valencia', '45014680', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000014'),
  ('Romel Gabriel', 'Villavicencio Lazo', '03096616', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001'),
  ('Marleny del Socorro', 'Alvarado Saguma', '03096883', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001'),
  ('Pedro Pablo', 'Alvarado Jimenez', '03112606', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001'),
  ('Wilmer', 'Chininin Pintado', '03102898', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Patrocinia', 'Jimenez Vicente', '80550593', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Rolando', 'Campos Cordova', '80525537', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000003'),
  ('Renelmo', 'Tocto Alberca', '44269205', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000032'),
  ('Rolando', 'Tocto Alberca', '46078661', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000032'),
  ('Carlos', 'Cruz Morocho', '03128720', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Humberto', 'Portocarrero Torres', '80376755', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000005'),
  ('Alvaro', 'Chinchay Espinosa', '48587780', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000022'),
  ('Filadelfo', 'Flores Saavedra', '80485588', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Arnoldo', 'Correa Yangua', '03097749', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000031'),
  ('Joel', 'Berru Calle', '45228736', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000004'),
  ('Francisco', 'Chininin Yangua', '03128746', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Adelmo', 'Campos Cordova', '03122274', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000003'),
  ('Felicino', 'Marchan Culquicondor', '03103044', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000019'),
  ('Maximo', 'Yangua Sarango', '03101497', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000003'),
  ('Dorinda', 'Huaman de Huacchillo', '03111364', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000035'),
  ('Confesor', 'Maldonado Huanca', '03112634', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000030'),
  ('Misael', 'Culquicondor Giron', '43642999', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000014'),
  ('Patricio', 'Silva Guerrero', '03100556', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Edwin Martin', 'Quinde Criollo', '42831629', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001'),
  ('Arcadio', 'Rios Jabo', '03102855', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Felix', 'Chamba Yangua', '03089297', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000008'),
  ('Hedil', 'Correa Niño', '41952266', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000031'),
  ('Francisco', 'Ocampos Giron', '02863613', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000027'),
  ('Pedro', 'Valle Pardo', '03107898', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Alexander', 'Niño Correa', '42565433', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000018'),
  ('Brayam', 'Niño Abad', '76444959', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000018'),
  ('Cristian Anderson', 'Balarezo Marchan', '70016320', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000015'),
  ('Robert Charles', 'Culquicondor Avila', '42108534', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000026'),
  ('Eber', 'Rivera Aguilar', '80666083', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000018'),
  ('Indalecio', 'Aguilar Niño', '03102374', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000018'),
  ('Martin', 'Parrilla Vasquez', '46681671', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000015'),
  ('Etelvina', 'Rios Jabo', '03879126', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Valerio', 'Chinchay Niño', '03101523', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000018'),
  ('Sabino', 'Yangua Chinchay', '43947154', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000018'),
  ('Eduar', 'Yangua Valle', '77919171', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000006'),
  ('Jose Felizardo', 'Abad Robledo', '03127188', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000008'),
  ('Elena', 'Jimenez Yangua', '43947145', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Alicia', 'Chininin Rondoy', '48591655', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Lilia Del Carmen', 'Chininin De Rios', '03100765', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002'),
  ('Ofelia', 'Cortez Rivera', '02806045', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000005'),
  ('Franklin', 'Yanayaco Mijahuanga', '03112218', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000039'),
  ('Nelso', 'Villalta Ulloa', '03111354', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000039'),
  ('Waldir Dennis', 'Yanayaco Valencia', '73688715', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000039'),
  ('Fidel', 'Reyes Lloclla', '03099717', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000039'),
  ('Senecio', 'Reyes Liviapoma', '03110639', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000039'),
  ('Indalecio', 'Yanayaco Mijahuanga', '03112220', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000039'),
  ('Jorge Raul', 'Jimenez Troncos', '03110661', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000039'),
  ('Pascual', 'Llapapasca Ulloa', '03099598', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000039'),
  ('Manuel', 'Cueva Rivera', '03084424', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000028'),
  ('Elvira', 'Abad Rosillo', '03081157', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000028'),
  ('Amaro', 'Herrera Abad', '03087351', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000028');

-- Parcelas: 3 por productor, "Parcela <Nombre Apellido> N" (N = 1..3).
-- Se resuelve el producer_id por DNI en vez de hardcodear UUIDs -- los
-- producers de arriba no fijaron id, dejaron que gen_random_uuid() lo genere.
INSERT INTO public.plots (producer_id, name)
SELECT p.id, 'Parcela ' || p.first_name || ' ' || p.last_name || ' ' || n
FROM public.producers p
CROSS JOIN generate_series(1, 3) AS n
WHERE p.cooperative_id = '550e8400-e29b-41d4-a716-446655440001'
  AND p.dni IN (
    '03097267','03101538','45427360','42396540','03102853','03100105','80333458',
    '02771828','03128655','80440237','03097955','03096997','03102852','42633120',
    '46033683','03101595','42615192','80450990','03097689','03103003','03598688',
    '42668723','03096470','48472088','45014680','03096616','03096883','03112606',
    '03102898','80550593','80525537','44269205','46078661','03128720','80376755',
    '48587780','80485588','03097749','45228736','03128746','03122274','03103044',
    '03101497','03111364','03112634','43642999','03100556','42831629','03102855',
    '03089297','41952266','02863613','03107898','42565433','76444959','70016320',
    '42108534','80666083','03102374','46681671','03879126','03101523','43947154',
    '77919171','03127188','43947145','48591655','03100765','02806045','03112218',
    '03111354','73688715','03099717','03110639','03112220','03110661','03099598',
    '03084424','03081157','03087351'
  );

-- ============================================================
-- RESUMEN
-- ============================================================
-- 1 admin_web (Bianca Seminario, real, usuario "biancaseminario")
-- 1 admin_sistema (Bianca Seminario, real, móvil)
-- 2 tecnico_campo (inventados, 3 módulos cada uno)
-- 43 admin_modulo (reales, 1 por módulo salvo San Francisco con 2)
-- 80 productor (reales), cada uno con 3 parcelas (240 plots total)
-- Total personas del CSV: 123
-- Contraseña de todos los usuarios móvil = su propio DNI
-- ============================================================
