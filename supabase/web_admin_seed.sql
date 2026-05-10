-- ============================================================
-- WEB ADMIN SEED — Administradores del portal web
-- Un admin_web por cooperativa para poder hacer login inicial.
-- Ejecutar manualmente: supabase db execute --remote --file supabase\web_admin_seed.sql
-- ============================================================

DO $$
DECLARE
  v_auth_id uuid;
BEGIN

  -- ── ADMIN NORANDINO ─────────────────────────────────────────
  INSERT INTO auth.users (
    instance_id, id, aud, role, email,
    encrypted_password, email_confirmed_at,
    created_at, updated_at,
    confirmation_token, email_change,
    email_change_token_new, recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated', 'authenticated',
    'admin_norandino.NORANDINO@web.local',
    crypt('Admin1234', gen_salt('bf')),
    NOW(), NOW(), NOW(),
    '', '', '', ''
  ) RETURNING id INTO v_auth_id;

  INSERT INTO public.web_users (
    auth_user_id, cooperative_id, username,
    first_name, last_name, role, is_active
  ) VALUES (
    v_auth_id,
    '550e8400-e29b-41d4-a716-446655440001',
    'admin_norandino',
    'Admin', 'Norandino', 'admin_web', true
  );

  RAISE NOTICE 'Admin Norandino creado (auth_id: %)', v_auth_id;

  -- ── ADMIN CAES ──────────────────────────────────────────────
  INSERT INTO auth.users (
    instance_id, id, aud, role, email,
    encrypted_password, email_confirmed_at,
    created_at, updated_at,
    confirmation_token, email_change,
    email_change_token_new, recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated', 'authenticated',
    'admin_caes.CAES@web.local',
    crypt('Admin1234', gen_salt('bf')),
    NOW(), NOW(), NOW(),
    '', '', '', ''
  ) RETURNING id INTO v_auth_id;

  INSERT INTO public.web_users (
    auth_user_id, cooperative_id, username,
    first_name, last_name, role, is_active
  ) VALUES (
    v_auth_id,
    '550e8400-e29b-41d4-a716-446655440002',
    'admin_caes',
    'Admin', 'CAES', 'admin_web', true
  );

  RAISE NOTICE 'Admin CAES creado (auth_id: %)', v_auth_id;

END $$;
