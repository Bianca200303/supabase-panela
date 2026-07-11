-- Hasta ahora "Completar orden" (plant_orders.status -> 'completado') no
-- validaba nada contra total_kg: solo requería que cada lote agregado ya
-- hubiera pasado por "Procesar" (plant_production_batches.status =
-- 'procesado'), sin importar si esos lotes sumaban lo planificado.
--
-- Este trigger bloquea la transición a 'completado' si la suma de lo
-- planificado (unit_weight_kg * planned_quantity de los lotes) no llega al
-- total_kg de la orden. No valida lo realmente tamizado (tamizada_kg) contra
-- el total: esa comparación queda como aviso en el frontend, no como bloqueo
-- duro, porque una diferencia por merma es esperable y a veces aceptable —
-- es una decisión humana, no una regla física que deba impedir el guardado.

CREATE OR REPLACE FUNCTION public.validate_order_completion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
    total_batches   INTEGER;
    unprocessed     INTEGER;
    planned_sum     NUMERIC;
  BEGIN
    IF NEW.status <> 'completado' OR OLD.status = 'completado' THEN
      RETURN NEW;
    END IF;

    SELECT COUNT(*), COUNT(*) FILTER (WHERE status <> 'procesado')
    INTO total_batches, unprocessed
    FROM plant_production_batches
    WHERE order_id = NEW.id;

    IF total_batches = 0 THEN
      RAISE EXCEPTION 'La orden no tiene lotes de envasado. Agrega al menos uno antes de completarla.';
    END IF;

    IF unprocessed > 0 THEN
      RAISE EXCEPTION '% lote(s) de la orden todavía no fueron procesados.', unprocessed;
    END IF;

    IF NEW.total_kg IS NOT NULL THEN
      SELECT COALESCE(SUM(unit_weight_kg * planned_quantity), 0)
      INTO planned_sum
      FROM plant_production_batches
      WHERE order_id = NEW.id;

      IF ABS(planned_sum - NEW.total_kg) > 0.01 THEN
        RAISE EXCEPTION
          'Los lotes planificados suman % kg, pero la orden planifica % kg. Deben coincidir antes de completar.',
          planned_sum, NEW.total_kg;
      END IF;
    END IF;

    RETURN NEW;
  END;
  $function$
;

CREATE TRIGGER trg_validate_order_completion
  BEFORE UPDATE ON public.plant_orders
  FOR EACH ROW EXECUTE FUNCTION public.validate_order_completion();
