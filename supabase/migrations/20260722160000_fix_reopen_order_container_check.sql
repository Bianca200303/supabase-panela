-- validate_order_completion() bloqueaba SIEMPRE reabrir una orden
-- completada, para cualquier orden, sin excepción -- revisaba
-- "container_id IS NOT NULL", pero desde
-- 20260714150000_reingenieria_ordenes_produccion_fase1.sql (o la migración
-- que introdujo la creación del contenedor junto con la orden, ver
-- handleCreateOrder en OrdenesPage.jsx) el contenedor se crea y se
-- vincula DESDE QUE SE CREA LA ORDEN, con solo el número (status
-- 'preparando') -- container_id nunca es null, ni siquiera para una orden
-- recién creada. La intención original de este chequeo (no reabrir si la
-- panela ya puede estar físicamente cargada/embarcada) hay que verificarla
-- contra si el contenedor ya tiene datos reales de embarque asignados
-- (booking_number), el mismo criterio que ya usa el frontend
-- (containerNeedsShipping en OrdenesPage.jsx) para distinguir "todavía es
-- solo un número" de "ya se asignó de verdad a un contenedor".

CREATE OR REPLACE FUNCTION public.validate_order_completion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
    total_batches   INTEGER;
    unprocessed     INTEGER;
    has_booking     BOOLEAN;
  BEGIN
    -- Reabrir una orden completada: solo si el contenedor todavía no tiene
    -- datos reales de embarque asignados (no alcanza con que exista el
    -- número, que ya se crea junto con la orden).
    IF OLD.status = 'completado' AND NEW.status <> 'completado' THEN
      SELECT (booking_number IS NOT NULL) INTO has_booking
      FROM plant_containers
      WHERE id = OLD.container_id;

      IF COALESCE(has_booking, false) THEN
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
