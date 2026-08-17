-- =============================================================================
-- Restringe a admin_web la gestión de cupos de producción por certificación
-- y el mantenimiento de usuarios web.
--
-- Contexto: producer_quotas se creó (20260626100000) con RLS solo por
-- cooperative_id, dejando la nota "se puede estrechar a roles web cuando la
-- autenticación web esté implementada" -- ya lo está (web_users.role,
-- inyectado como claim `app_role` por custom_access_token_hook). Esta
-- migración cierra ese hueco para producer_quotas y, de paso, para
-- web_users (hoy cualquier operador autenticado puede, vía cliente directo,
-- desactivar/reactivar u modificar otros usuarios -- solo se filtraba por
-- cooperativa, no por rol).
--
-- El SELECT de web_users NO se toca: authStore.init() lo usa para cargar el
-- propio perfil de cualquier usuario (admin u operador) al iniciar sesión.
-- =============================================================================

-- ─── 1. Helper is_admin_web() ────────────────────────────────────────────────
-- Espeja el patrón de auth_cooperative_id() / is_service_role(): lee el claim
-- `app_role` que custom_access_token_hook ya inyecta en el JWT desde
-- web_users.role (o users.role para el móvil, que nunca es 'admin_web').

CREATE OR REPLACE FUNCTION public.is_admin_web()
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  SELECT coalesce(
    current_setting('request.jwt.claims', true)::jsonb ->> 'app_role' = 'admin_web',
    false
  )
$function$
;

-- ─── 2. producer_quotas: escritura solo admin ────────────────────────────────

DROP POLICY IF EXISTS "producer_quotas_insert" ON public.producer_quotas;
CREATE POLICY "producer_quotas_insert"
  ON public.producer_quotas
  AS PERMISSIVE
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (cooperative_id = public.auth_cooperative_id() AND public.is_admin_web())
    OR public.is_service_role()
  );

DROP POLICY IF EXISTS "producer_quotas_update" ON public.producer_quotas;
CREATE POLICY "producer_quotas_update"
  ON public.producer_quotas
  AS PERMISSIVE
  FOR UPDATE
  TO authenticated
  USING (
    (cooperative_id = public.auth_cooperative_id() AND public.is_admin_web())
    OR public.is_service_role()
  )
  WITH CHECK (
    (cooperative_id = public.auth_cooperative_id() AND public.is_admin_web())
    OR public.is_service_role()
  );

DROP POLICY IF EXISTS "producer_quotas_delete" ON public.producer_quotas;
CREATE POLICY "producer_quotas_delete"
  ON public.producer_quotas
  AS PERMISSIVE
  FOR DELETE
  TO authenticated
  USING (
    (cooperative_id = public.auth_cooperative_id() AND public.is_admin_web())
    OR public.is_service_role()
  );

-- producer_quotas_select se deja igual (el móvil necesita leer el cupo para
-- alertar al técnico de campo, sin importar su rol).

-- ─── 3. web_users: mantenimiento (insert/update/delete) solo admin ──────────
-- register-web-user (edge function) usa la service role key y no depende de
-- estas policies. Lo que sí pasaba por el cliente directo era toggleActive()
-- en UsersPage.jsx -- eso queda cerrado a admin_web ahora.

DROP POLICY IF EXISTS "web_users_insert" ON public.web_users;
CREATE POLICY "web_users_insert"
  ON public.web_users
  AS PERMISSIVE
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (cooperative_id = public.auth_cooperative_id() AND public.is_admin_web())
    OR public.is_service_role()
  );

DROP POLICY IF EXISTS "web_users_update" ON public.web_users;
CREATE POLICY "web_users_update"
  ON public.web_users
  AS PERMISSIVE
  FOR UPDATE
  TO authenticated
  USING (
    (cooperative_id = public.auth_cooperative_id() AND public.is_admin_web())
    OR public.is_service_role()
  )
  WITH CHECK (
    (cooperative_id = public.auth_cooperative_id() AND public.is_admin_web())
    OR public.is_service_role()
  );

DROP POLICY IF EXISTS "web_users_delete" ON public.web_users;
CREATE POLICY "web_users_delete"
  ON public.web_users
  AS PERMISSIVE
  FOR DELETE
  TO authenticated
  USING (
    (cooperative_id = public.auth_cooperative_id() AND public.is_admin_web())
    OR public.is_service_role()
  );
