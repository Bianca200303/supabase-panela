-- Permite reabrir una orden completada (status 'completado' -> 'en_proceso')
-- para corregir errores -- pero solo mientras todavía no tenga contenedor
-- asignado. Si ya tiene contenedor, la panela puede estar físicamente
-- cargada o incluso embarcada, así que reabrir en ese punto es riesgoso y
-- se bloquea acá, no solo en el frontend.
--
-- Extiende el mismo trigger que ya validaba el cierre de la orden
-- (validate_order_completion), agregando la validación de la transición
-- inversa al principio de la función.

CREATE OR REPLACE FUNCTION public.validate_order_completion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
    total_batches   INTEGER;
    unprocessed     INTEGER;
    planned_sum     NUMERIC;
  BEGIN
    -- Reabrir una orden completada: solo si todavía no tiene contenedor asignado.
    IF OLD.status = 'completado' AND NEW.status <> 'completado' THEN
      IF OLD.container_id IS NOT NULL THEN
        RAISE EXCEPTION 'No se puede reabrir la orden: ya está asignada a un contenedor.';
      END IF;
      RETURN NEW;
    END IF;

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
