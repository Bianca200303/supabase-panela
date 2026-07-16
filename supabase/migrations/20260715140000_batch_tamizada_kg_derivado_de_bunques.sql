-- =============================================================================
-- plant_production_batches.tamizada_kg -- derivado, SUM de sus bunques.
--
-- Mismo patrón que plant_orders.total_kg (ver
-- 20260715090000_order_total_kg_derivado_de_lotes.sql): la columna se
-- recalcula por trigger en vez de sumarse client-side, para que cualquier
-- lector (frontend, reportes, vistas) tenga siempre el total correcto sin
-- reimplementar la suma.
-- =============================================================================

ALTER TABLE public.plant_production_batches
  ADD COLUMN tamizada_kg numeric(10,3) NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION public.recalc_batch_tamizada_kg()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    target_batch_id uuid;
BEGIN
    target_batch_id := COALESCE(NEW.plant_batch_id, OLD.plant_batch_id);

    UPDATE public.plant_production_batches
    SET tamizada_kg = (
        SELECT COALESCE(SUM(tamizada_kg), 0)
        FROM public.plant_batch_bunques
        WHERE plant_batch_id = target_batch_id
    )
    WHERE id = target_batch_id;

    RETURN NULL;
END;
$function$
;

CREATE TRIGGER recalc_batch_tamizada_kg_trigger
  AFTER INSERT OR UPDATE OR DELETE ON public.plant_batch_bunques
  FOR EACH ROW EXECUTE FUNCTION public.recalc_batch_tamizada_kg();
