-- =============================================================================
-- Permite editar y eliminar horas (y sus muestras) de Control de Pesos y
-- Sellado.
--
-- Contexto: plant_batch_weight_seal_checks y plant_batch_weight_seal_samples
-- solo tenían policies de SELECT e INSERT (20260731150000) -- no existía
-- forma de corregir una hora mal cargada (peso, sellado, limpieza de
-- alguna muestra) ni de borrarla. Mismo criterio ya usado en
-- 20260816100000_allow_edit_delete_foreign_object_checks.sql para el
-- módulo hermano (Control de Objetos Extraños): válido si el formulario
-- dueño (form_id, vía check_id para las muestras) pertenece a la
-- cooperativa del usuario autenticado. plant_batch_weight_seal_forms ya
-- tenía UPDATE (pbwsf_update, usada por "Terminar formulario") -- esa
-- misma policy ya cubre "Reabrir formulario", no hace falta agregar nada ahí.
-- =============================================================================

CREATE POLICY "pbwsc_update" ON "public"."plant_batch_weight_seal_checks"
  AS PERMISSIVE FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.plant_batch_weight_seal_forms f
      WHERE f.id = form_id AND (f.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.plant_batch_weight_seal_forms f
      WHERE f.id = form_id AND (f.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
    )
  );

CREATE POLICY "pbwsc_delete" ON "public"."plant_batch_weight_seal_checks"
  AS PERMISSIVE FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.plant_batch_weight_seal_forms f
      WHERE f.id = form_id AND (f.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
    )
  );

CREATE POLICY "pbwss_update" ON "public"."plant_batch_weight_seal_samples"
  AS PERMISSIVE FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.plant_batch_weight_seal_checks c
      JOIN public.plant_batch_weight_seal_forms f ON f.id = c.form_id
      WHERE c.id = check_id AND (f.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.plant_batch_weight_seal_checks c
      JOIN public.plant_batch_weight_seal_forms f ON f.id = c.form_id
      WHERE c.id = check_id AND (f.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
    )
  );

CREATE POLICY "pbwss_delete" ON "public"."plant_batch_weight_seal_samples"
  AS PERMISSIVE FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.plant_batch_weight_seal_checks c
      JOIN public.plant_batch_weight_seal_forms f ON f.id = c.form_id
      WHERE c.id = check_id AND (f.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
    )
  );
