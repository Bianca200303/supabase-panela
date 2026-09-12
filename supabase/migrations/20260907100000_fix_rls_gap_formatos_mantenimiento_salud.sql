-- Corrige un hueco de aislamiento: formatos_mantenimiento_equipos y
-- formatos_seguimiento_salud se crearon en el baseline con grants por
-- defecto a "anon"/"authenticated" pero SIN Row Level Security habilitado.
-- Sin RLS, esos grants mandan: cualquiera con la anon key pública podía
-- leer/escribir/borrar filas de CUALQUIER cooperativa sin loguearse.
--
-- Se replica exactamente el mismo patrón ya usado en las tablas hermanas
-- (formatos_control_cloro, formatos_control_personal, etc.): RLS habilitado
-- + policies "to authenticated" filtrando por cooperative_id, permitiendo
-- también al service_role (usado por los backends/triggers internos).

alter table "public"."formatos_mantenimiento_equipos" enable row level security;
alter table "public"."formatos_seguimiento_salud"     enable row level security;

create policy "formatos_mantenimiento_equipos_select"
  on "public"."formatos_mantenimiento_equipos"
  as permissive
  for select
  to authenticated
  using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));

create policy "formatos_mantenimiento_equipos_insert"
  on "public"."formatos_mantenimiento_equipos"
  as permissive
  for insert
  to authenticated
  with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));

create policy "formatos_mantenimiento_equipos_update"
  on "public"."formatos_mantenimiento_equipos"
  as permissive
  for update
  to authenticated
  using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
  with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));

create policy "formatos_mantenimiento_equipos_delete"
  on "public"."formatos_mantenimiento_equipos"
  as permissive
  for delete
  to authenticated
  using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));

create policy "formatos_seguimiento_salud_select"
  on "public"."formatos_seguimiento_salud"
  as permissive
  for select
  to authenticated
  using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));

create policy "formatos_seguimiento_salud_insert"
  on "public"."formatos_seguimiento_salud"
  as permissive
  for insert
  to authenticated
  with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));

create policy "formatos_seguimiento_salud_update"
  on "public"."formatos_seguimiento_salud"
  as permissive
  for update
  to authenticated
  using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
  with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));

create policy "formatos_seguimiento_salud_delete"
  on "public"."formatos_seguimiento_salud"
  as permissive
  for delete
  to authenticated
  using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));
