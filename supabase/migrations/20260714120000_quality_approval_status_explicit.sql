-- Hasta ahora approval_status se derivaba automáticamente de rejected_kg:
--   rejected_kg = 0                -> 'aprobado'
--   0 < rejected_kg < kg recibido  -> 'aprobado_con_observaciones'
--   rejected_kg >= kg recibido     -> 'rechazado'
--
-- Requerimiento nuevo: "aprobado con observaciones" ya no depende de un
-- rechazo parcial de kg -- es simplemente aprobar el lote completo dejando
-- una nota escrita. Y "rechazado" ahora cubre tanto un rechazo parcial como
-- uno total (el lote completo), no solo cuando se rechaza el 100%.
--
-- Por eso approval_status pasa a ser elegido explícitamente por Calidad
-- (dropdown en CalidadPage.jsx) en vez de calculado. El trigger deja de
-- derivarlo y pasa a validar que la combinación (approval_status,
-- rejected_kg, notes, rejection_reason) sea consistente, para que nunca
-- queden desincronizados -- mismo objetivo que antes, distinta regla:
--
--   aprobado                    -> rejected_kg = 0
--   aprobado_con_observaciones  -> rejected_kg = 0, notes obligatorio
--   rechazado                   -> rejected_kg > 0, rejection_reason obligatorio
--
-- notes es una columna que ya existe en quality_evaluations pero nunca se
-- llena (RecepcionPage.jsx no la usa al insertar) -- se reutiliza acá como
-- observaciones de la revisión de calidad.
--
-- El INSERT normal de RecepcionPage.jsx (una fila por lote, rejected_kg=0,
-- approval_status sin especificar = NULL) se sigue dejando pasar tal cual:
-- "pendiente de revisión". Esto no cambia respecto al fix anterior
-- (20260712142137).

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

    IF TG_OP = 'INSERT' AND NEW.approval_status IS NULL THEN
        -- Caso normal de RecepcionPage.jsx: fila recién creada, todavía sin
        -- revisar -- approval_status queda NULL = "pendiente de revisión".
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
