-- ============================================================
-- ADMIN DE SISTEMA adicional — CAES
-- DNI 11111111 (fácil de recordar, pedido explícito para pruebas).
--
-- No depende de módulos (admin_sistema no requiere coop_module_id).
-- Carga manual: se puede correr en cualquier momento después de seed.sql.
-- ============================================================

INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role) VALUES
  ('11111111', 'Admin', 'Sistema CAES', '550e8400-e29b-41d4-a716-446655440002', 'admin_sistema');
SELECT public.setup_dni_user_auth('11111111', '11111111', '550e8400-e29b-41d4-a716-446655440002'::uuid);
