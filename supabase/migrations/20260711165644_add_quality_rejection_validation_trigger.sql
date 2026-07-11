-- Paso 2/5 del rechazo de calidad por lote individual.
--
-- approval_status deja de ser editable a mano: a partir de ahora se calcula
-- siempre a partir de rejected_kg, para que nunca puedan quedar
-- desincronizados (el mismo tipo de bug que ya arreglamos con el stock de
-- exit_items).
--
--   rejected_kg = 0                        -> 'aprobado'
--   0 < rejected_kg < kg recibido           -> 'aprobado_con_observaciones'
--   rejected_kg >= kg recibido              -> 'rechazado'
--
-- También valida que no se pueda rechazar más kg de los que quedan sin usar
-- en homogeneizado (no se puede rechazar panela que ya se mezcló en un lote
-- de planta), y que rejection_reason sea obligatorio cuando rejected_kg > 0.

CREATE OR REPLACE FUNCTION public.validate_quality_rejection()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    received_kg NUMERIC(10,2);
    used_kg     NUMERIC(10,2);
    unused_kg   NUMERIC(10,2);
BEGIN
    SELECT quantity_kg_received INTO received_kg
    FROM exit_reception_items
    WHERE exit_item_id = NEW.exit_item_id;

    IF received_kg IS NULL THEN
        RAISE EXCEPTION 'No reception item found for exit_item %', NEW.exit_item_id;
    END IF;

    SELECT COALESCE(SUM(quantity_kg), 0) INTO used_kg
    FROM plant_homogenization_inputs
    WHERE source_exit_item_id = NEW.exit_item_id;

    unused_kg := received_kg - used_kg;

    IF NEW.rejected_kg > unused_kg THEN
        RAISE EXCEPTION 'Rejected kg (%) exceeds kg still available (%). % kg of this lote are already committed to homogenization.',
            NEW.rejected_kg, unused_kg, used_kg;
    END IF;

    IF NEW.rejected_kg > 0 AND (NEW.rejection_reason IS NULL OR btrim(NEW.rejection_reason) = '') THEN
        RAISE EXCEPTION 'rejection_reason is required when rejected_kg > 0';
    END IF;

    IF NEW.rejected_kg = 0 THEN
        NEW.approval_status  := 'aprobado';
        NEW.rejection_reason := NULL;
        NEW.rejected_by      := NULL;
        NEW.rejected_at      := NULL;
    ELSE
        NEW.approval_status := CASE
            WHEN NEW.rejected_kg >= received_kg THEN 'rechazado'
            ELSE 'aprobado_con_observaciones'
        END;

        IF TG_OP = 'INSERT' OR NEW.rejected_kg IS DISTINCT FROM OLD.rejected_kg THEN
            NEW.rejected_at := now();
        END IF;
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE TRIGGER validate_quality_rejection_trigger
  BEFORE INSERT OR UPDATE ON public.quality_evaluations
  FOR EACH ROW EXECUTE FUNCTION public.validate_quality_rejection();
