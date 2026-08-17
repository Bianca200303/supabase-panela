-- =============================================================================
-- Permite editar y eliminar inspecciones de Control de objetos extraños.
--
-- Contexto: plant_batch_foreign_object_checks solo tenía policies de SELECT
-- e INSERT (20260722140000) -- no existía forma de corregir un dato mal
-- cargado en una inspección puntual (hora, bolsas separadas, tipo de test,
-- conforme) ni de borrarla. Se agregan UPDATE y DELETE con el mismo
-- criterio ya usado en SELECT/INSERT: válido si el formulario dueño
-- (form_id) pertenece a la cooperativa del usuario autenticado.
-- =============================================================================

CREATE POLICY "pbfoc_update" ON "public"."plant_batch_foreign_object_checks"
  AS PERMISSIVE FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM plant_batch_foreign_object_forms f
      WHERE f.id = form_id AND (f.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM plant_batch_foreign_object_forms f
      WHERE f.id = form_id AND (f.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
    )
  );

CREATE POLICY "pbfoc_delete" ON "public"."plant_batch_foreign_object_checks"
  AS PERMISSIVE FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM plant_batch_foreign_object_forms f
      WHERE f.id = form_id AND (f.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
    )
  );
