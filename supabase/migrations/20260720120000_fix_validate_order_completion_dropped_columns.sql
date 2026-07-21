-- validate_order_completion() quedó rota tras la reingeniería de bunques:
-- 20260714150000_reingenieria_ordenes_produccion_fase1.sql eliminó las
-- columnas unit_weight_kg y planned_quantity de plant_production_batches
-- (reemplazadas por packaging_kg / packaging_count), pero esta función
-- (redefinida por última vez en 20260712154347_allow_reopen_order.sql)
-- nunca se actualizó -- "Completar orden" fallaba con
-- 'column "unit_weight_kg" does not exist'.
--
-- Además, ese bloque de validación (planned_sum vs NEW.total_kg) ya no tiene
-- sentido: desde 20260715090000_order_total_kg_derivado_de_lotes.sql,
-- plant_orders.total_kg se recalcula automáticamente como
-- SUM(packaging_count * packaging_kg) de los lotes -- exactamente lo mismo
-- que este bloque volvía a sumar. Comparar un valor contra sí mismo no
-- valida nada, así que se elimina en vez de repetir la fórmula con los
-- nombres de columna corregidos.

CREATE OR REPLACE FUNCTION public.validate_order_completion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
    total_batches   INTEGER;
    unprocessed     INTEGER;
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

    RETURN NEW;
  END;
  $function$
;
