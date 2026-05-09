INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role)
VALUES ('11111111', 'Admin', 'Norandino',
        '550e8400-e29b-41d4-a716-446655440001', 'admin_sistema');

SELECT public.setup_dni_user_auth(
  '11111111',
  '11111111',
  '550e8400-e29b-41d4-a716-446655440001'::uuid
);
