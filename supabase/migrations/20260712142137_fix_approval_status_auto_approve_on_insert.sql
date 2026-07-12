-- El trigger validate_quality_rejection_trigger calculaba approval_status
-- en cada INSERT o UPDATE de quality_evaluations. Como RecepcionPage.jsx
-- inserta una fila por lote al recepcionar (con rejected_kg en 0 por
-- default), el trigger dejaba approval_status = 'aprobado' desde el
-- instante de la recepción -- antes de que alguien de Calidad revisara
-- nada. En CalidadPage.jsx eso hacía que el lote apareciera directo en
-- "Revisadas" con la etiqueta "Aprobado", sin que nadie hubiera decidido.
--
-- Ahora approval_status solo se calcula en UPDATE (cuando Calidad guarda
-- una revisión real desde "Revisar / Rechazar lotes"). En INSERT queda en
-- NULL -- que ya es el valor que el frontend interpreta como "pendiente
-- de revisión" (getReceptionApprovalStatus ya contempla ese caso).
--
-- No afecta la disponibilidad para homogeneizado: v_plant_available_stock
-- calcula kg_available solo a partir de rejected_kg, nunca de
-- approval_status.

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

    IF TG_OP = 'UPDATE' THEN
        -- Update real de Calidad: acá sí se deriva el estado.
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

            IF NEW.rejected_kg IS DISTINCT FROM OLD.rejected_kg THEN
                NEW.rejected_at := now();
            END IF;
        END IF;
    ELSIF TG_OP = 'INSERT' AND NEW.rejected_kg > 0 THEN
        -- Caso borde: si algún día se inserta ya con rejected_kg > 0
        -- (hoy no ocurre, RecepcionPage siempre inserta con 0), igual se
        -- calcula el estado para no dejar una fila inconsistente.
        NEW.approval_status := CASE
            WHEN NEW.rejected_kg >= received_kg THEN 'rechazado'
            ELSE 'aprobado_con_observaciones'
        END;
        NEW.rejected_at := now();
    END IF;
    -- INSERT con rejected_kg = 0 (el caso normal de RecepcionPage.jsx):
    -- approval_status queda como venga en el INSERT, que es NULL por
    -- default -- "pendiente de revisión".

    RETURN NEW;
END;
$function$
;

-- Limpieza de datos ya afectados por el bug: recepciones guardadas
-- mientras el trigger anterior autoaprobaba en el INSERT. No hay forma de
-- distinguir "se autoaprobó por el bug" de "alguien lo revisó y confirmó
-- que estaba bien" con los datos actuales -- ambos casos quedan idénticos
-- (approval_status='aprobado', rejected_kg=0, rejected_at=NULL). Se
-- resetean a NULL para que vuelvan a "Sin revisar"; es una limpieza segura
-- porque estamos en desarrollo y el peor caso es revisar una vez más un
-- lote que ya estaba bien.
UPDATE public.quality_evaluations
SET approval_status = NULL
WHERE approval_status = 'aprobado' AND rejected_kg = 0;
