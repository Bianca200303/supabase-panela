-- La carga total del contenedor ya no se pide al crear la orden: sale de la
-- suma de los lotes de envasado que se van registrando (packaging_count *
-- packaging_kg), no al revés. plant_orders.total_kg pasa de ser un valor
-- declarado a mano a un valor calculado, mantenido en sync por este trigger
-- cada vez que se inserta, edita o borra un lote de la orden.

CREATE OR REPLACE FUNCTION public.recalc_order_total_kg()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    target_order_id uuid;
BEGIN
    target_order_id := COALESCE(NEW.order_id, OLD.order_id);

    UPDATE public.plant_orders
    SET total_kg = (
        SELECT COALESCE(SUM(packaging_count * packaging_kg), 0)
        FROM public.plant_production_batches
        WHERE order_id = target_order_id
    )
    WHERE id = target_order_id;

    RETURN NULL;
END;
$function$
;

CREATE TRIGGER recalc_order_total_kg_trigger
  AFTER INSERT OR UPDATE OR DELETE ON public.plant_production_batches
  FOR EACH ROW EXECUTE FUNCTION public.recalc_order_total_kg();
