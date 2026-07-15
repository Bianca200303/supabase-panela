-- Permite corregir quantity_kg_received (kg recibidos) después de
-- confirmada la recepción, pero solo mientras ese lote todavía no tenga kg
-- metidos en un homogeneizado. Si ya se usó, corregirlo rompería el
-- balance de masa que ya validan otros triggers (validate_quality_rejection,
-- validate_processing_totals), así que se bloquea a nivel de base de datos
-- -- no solo con una restricción en el frontend.

CREATE OR REPLACE FUNCTION public.validate_reception_item_edit()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    used_kg NUMERIC(10,2);
BEGIN
    IF NEW.quantity_kg_received IS DISTINCT FROM OLD.quantity_kg_received THEN
        SELECT COALESCE(SUM(quantity_kg), 0) INTO used_kg
        FROM plant_homogenization_inputs
        WHERE source_exit_item_id = NEW.exit_item_id;

        IF used_kg > 0 THEN
            RAISE EXCEPTION 'No se puede corregir el kg recibido: % kg de este lote ya están en un homogeneizado.', used_kg;
        END IF;
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE TRIGGER trg_validate_reception_item_edit
  BEFORE UPDATE ON public.exit_reception_items
  FOR EACH ROW EXECUTE FUNCTION public.validate_reception_item_edit();
