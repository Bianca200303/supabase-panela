-- =============================================================================
-- plant_production_batches.envasado_bolsas_rechazo_metal -- derivado, SUM de
-- bags_separated en Control de Objetos Extraños (plant_batch_foreign_object_checks)
-- del mismo lote.
--
-- Antes se recalculaba solo al abrir EnvasadoModal.jsx y quedaba fijo en la
-- BD recién cuando se guardaba ese formulario -- si después se agregaba,
-- editaba o borraba una inspección en Objetos Extraños (habilitado en
-- 20260816100000_allow_edit_delete_foreign_object_checks.sql) sin volver a
-- abrir y guardar Envasado, el número quedaba desactualizado. Ese valor
-- stale alimentaba directo el documento oficial "Control de Envasado"
-- (quickDocs.js) -- riesgo real de reportar un rechazo por detector de
-- metales que ya no coincide con la realidad.
--
-- Mismo patrón ya usado en este proyecto para el mismo tipo de problema:
-- plant_production_batches.tamizada_kg, derivado por trigger de
-- plant_batch_bunques (ver 20260715140000_batch_tamizada_kg_derivado_de_bunques.sql).
--
-- Solo aplica a lotes de packaging_type = 'bolsa' -- para 'saco' el campo
-- se deja en NULL (no aplica), igual criterio que ya tenía EnvasadoModal.jsx.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.recalc_batch_rechazo_metal()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    target_form_id  uuid := COALESCE(NEW.form_id, OLD.form_id);
    target_batch_id uuid;
BEGIN
    SELECT plant_batch_id INTO target_batch_id
    FROM public.plant_batch_foreign_object_forms
    WHERE id = target_form_id;

    UPDATE public.plant_production_batches
    SET envasado_bolsas_rechazo_metal = (
        SELECT COALESCE(SUM(c.bags_separated), 0)
        FROM public.plant_batch_foreign_object_checks c
        JOIN public.plant_batch_foreign_object_forms f ON f.id = c.form_id
        WHERE f.plant_batch_id = target_batch_id
    )
    WHERE id = target_batch_id
      AND packaging_type = 'bolsa';

    RETURN NULL;
END;
$function$
;

CREATE TRIGGER recalc_batch_rechazo_metal_trigger
  AFTER INSERT OR UPDATE OR DELETE ON public.plant_batch_foreign_object_checks
  FOR EACH ROW EXECUTE FUNCTION public.recalc_batch_rechazo_metal();

-- Backfill: corrige cualquier lote de bolsa cuyo valor guardado haya quedado
-- desincronizado antes de que existiera este trigger.
UPDATE public.plant_production_batches b
SET envasado_bolsas_rechazo_metal = sub.total
FROM (
  SELECT f.plant_batch_id, COALESCE(SUM(c.bags_separated), 0) AS total
  FROM public.plant_batch_foreign_object_checks c
  JOIN public.plant_batch_foreign_object_forms f ON f.id = c.form_id
  GROUP BY f.plant_batch_id
) sub
WHERE b.id = sub.plant_batch_id
  AND b.packaging_type = 'bolsa';
