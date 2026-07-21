-- Bug: al editar humedad/impurezas de un lote todavía pendiente de revisión
-- (RecepcionPage.jsx, UPDATE a quality_evaluations que no toca
-- approval_status), el trigger validate_quality_rejection() lanzaba
-- "Invalid approval_status: <NULL>".
--
-- La guarda que deja pasar approval_status = NULL ("pendiente de revisión",
-- ver 20260714120000) solo contemplaba TG_OP = 'INSERT'. Un UPDATE que deja
-- approval_status en NULL (porque no lo incluye en el SET y ya era NULL)
-- caía al CASE de abajo, no matcheaba ninguno de los tres estados válidos y
-- terminaba en el ELSE. La intención original (ver comentario de
-- 20260714120000: "se sigue dejando pasar tal cual: pendiente de revisión")
-- nunca distinguió INSERT de UPDATE -- se corrige acá para que aplique en
-- ambos casos.

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

    IF NEW.approval_status IS NULL THEN
        -- Lote sin revisar todavía -- ya sea recién creado por
        -- RecepcionPage.jsx (INSERT) o editado antes de pasar por Calidad
        -- (UPDATE de humedad/impurezas/estado de sacos/apariencia): sigue
        -- "pendiente de revisión", no hay nada que validar.
        RETURN NEW;
    END IF;

    -- Calidad está guardando una revisión real (UPDATE desde CalidadPage.jsx,
    -- o el caso borde de un INSERT que ya trae approval_status). El estado
    -- lo elige el revisor; acá solo se valida que sea consistente.
    IF NEW.approval_status = 'aprobado' THEN
        IF NEW.rejected_kg <> 0 THEN
            RAISE EXCEPTION 'approval_status=aprobado requires rejected_kg = 0';
        END IF;
        NEW.notes            := NULL;
        NEW.rejection_reason := NULL;
        NEW.rejected_by      := NULL;
        NEW.rejected_at      := NULL;

    ELSIF NEW.approval_status = 'aprobado_con_observaciones' THEN
        IF NEW.rejected_kg <> 0 THEN
            RAISE EXCEPTION 'approval_status=aprobado_con_observaciones requires rejected_kg = 0';
        END IF;
        IF NEW.notes IS NULL OR btrim(NEW.notes) = '' THEN
            RAISE EXCEPTION 'notes is required when approval_status = aprobado_con_observaciones';
        END IF;
        NEW.rejection_reason := NULL;
        NEW.rejected_by      := NULL;
        NEW.rejected_at      := NULL;

    ELSIF NEW.approval_status = 'rechazado' THEN
        IF NEW.rejected_kg <= 0 THEN
            RAISE EXCEPTION 'approval_status=rechazado requires rejected_kg > 0';
        END IF;
        IF NEW.rejection_reason IS NULL OR btrim(NEW.rejection_reason) = '' THEN
            RAISE EXCEPTION 'rejection_reason is required when approval_status = rechazado';
        END IF;
        NEW.notes := NULL;

        IF TG_OP = 'UPDATE' THEN
            IF NEW.rejected_kg IS DISTINCT FROM OLD.rejected_kg OR NEW.approval_status IS DISTINCT FROM OLD.approval_status THEN
                NEW.rejected_at := now();
            END IF;
        ELSE
            NEW.rejected_at := now();
        END IF;

    ELSE
        RAISE EXCEPTION 'Invalid approval_status: %', NEW.approval_status;
    END IF;

    RETURN NEW;
END;
$function$
;
