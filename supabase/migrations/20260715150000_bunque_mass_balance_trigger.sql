-- =============================================================================
-- Balance de masa reubicado de lote a bunque.
--
-- Antes vivía en validate_processing_totals() (plant_batch_processing,
-- 1 fila por lote). Ahora cada bunque es su propia unidad de balance:
-- tamizada + reproceso + descarte + merma debe igualar lo que se le asignó
-- de insumos a ESE bunque (no al lote completo).
--
-- El WHEN evita que el trigger corra al solo crear el bunque o asignarle
-- insumos (tamizada_kg sigue NULL en ese momento) -- solo valida cuando ya
-- se registra la salida.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.validate_bunque_totals()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
    total_input NUMERIC;
  BEGIN
    SELECT COALESCE(SUM(quantity_kg), 0)
    INTO total_input
    FROM plant_homogenization_inputs
    WHERE bunque_id = NEW.id;

    IF total_input = 0 THEN
      RAISE EXCEPTION 'El bunque no tiene insumos asignados';
    END IF;

    IF ABS((NEW.tamizada_kg + NEW.reproceso_kg + NEW.descarte_kg + NEW.merma_kg) - total_input) > 0.1 THEN
      RAISE EXCEPTION
        'La suma tamizada (%) + reproceso (%) + descarte (%) + merma (%) = % kg, pero el total asignado al bunque es % kg. Deben ser iguales.',
        NEW.tamizada_kg, NEW.reproceso_kg, NEW.descarte_kg, NEW.merma_kg,
        (NEW.tamizada_kg + NEW.reproceso_kg + NEW.descarte_kg + NEW.merma_kg),
        total_input;
    END IF;

    RETURN NEW;
  END;
  $function$
;

CREATE TRIGGER trg_validate_bunque_totals
  BEFORE INSERT OR UPDATE ON public.plant_batch_bunques
  FOR EACH ROW
  WHEN (NEW.tamizada_kg IS NOT NULL)
  EXECUTE FUNCTION public.validate_bunque_totals();
