-- =============================================================================
-- Fase 1 de "reparto de bunques entre lotes": un bunque puede terminar
-- aportando su resultado tamizado a más de un lote de envasado (confirmado
-- con el usuario: pasa seguido en la operación real, y no está restringido
-- a lotes de la misma orden -- puede repartirse a cualquier lote de la
-- planta). Hoy `plant_batch_bunques.plant_batch_id` fuerza un único dueño;
-- esta migración agrega el modelo de reparto SIN tocar la pantalla actual
-- (HomogenizadoBunquesModal.jsx, que sigue viva tal cual hasta la Fase 2).
--
-- Estrategia: la tabla nueva se mantiene sincronizada automáticamente con
-- el modelo viejo (1 bunque = 1 lote, vía plant_batch_id + tamizada_kg de
-- plant_batch_bunques) mediante un trigger espejo. Así:
--   - Nada de lo que ya funciona se rompe -- la UI actual sigue escribiendo
--     exactamente igual que siempre.
--   - El cálculo de kg tamizado por lote (plant_production_batches.tamizada_kg)
--     pasa a leerse desde la tabla de reparto, probando ya en producción que
--     el camino nuevo da los mismos resultados que el viejo.
--   - La Fase 2 (pantalla de bunques independiente de un lote, con reparto
--     real a mano) solo tiene que dejar de escribir plant_batch_id en
--     plant_batch_bunques y empezar a escribir esta tabla directo -- el
--     trigger espejo se puede desactivar en ese momento sin tocar el
--     cálculo de balance de masas, que ya está apuntando a la fuente correcta.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Tabla de reparto
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_bunque_batch_allocations (
  id               uuid          NOT NULL DEFAULT gen_random_uuid(),
  bunque_id        uuid          NOT NULL,
  plant_batch_id   uuid          NOT NULL,
  kg               numeric(10,3) NOT NULL CHECK (kg > 0),
  cooperative_id   uuid          NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),

  CONSTRAINT plant_bunque_batch_allocations_pkey PRIMARY KEY (id),
  CONSTRAINT pbba_bunque_fkey
    FOREIGN KEY (bunque_id) REFERENCES public.plant_batch_bunques(id) ON DELETE CASCADE,
  CONSTRAINT pbba_plant_batch_fkey
    FOREIGN KEY (plant_batch_id) REFERENCES public.plant_production_batches(id),
  CONSTRAINT pbba_unique_bunque_batch UNIQUE (bunque_id, plant_batch_id)
);

CREATE INDEX idx_pbba_bunque ON public.plant_bunque_batch_allocations (bunque_id);
CREATE INDEX idx_pbba_plant_batch ON public.plant_bunque_batch_allocations (plant_batch_id);
CREATE INDEX idx_pbba_cooperative ON public.plant_bunque_batch_allocations (cooperative_id);

ALTER TABLE public.plant_bunque_batch_allocations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pbba_select"
  ON public.plant_bunque_batch_allocations AS PERMISSIVE FOR SELECT
  TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pbba_insert"
  ON public.plant_bunque_batch_allocations AS PERMISSIVE FOR INSERT
  TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pbba_update"
  ON public.plant_bunque_batch_allocations AS PERMISSIVE FOR UPDATE
  TO authenticated
  USING  (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pbba_delete"
  ON public.plant_bunque_batch_allocations AS PERMISSIVE FOR DELETE
  TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_bunque_batch_allocations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_bunque_batch_allocations TO service_role;

-- -----------------------------------------------------------------------------
-- 2. Reemplaza el trigger de balance de masas: en vez de sumar
--    plant_batch_bunques.tamizada_kg agrupado por plant_batch_id (dueño
--    único), suma plant_bunque_batch_allocations.kg -- misma tabla que
--    alimentará la Fase 2. Recalcula tanto el lote nuevo (INSERT/UPDATE)
--    como el lote viejo si una fila se borra o cambia de lote.
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS recalc_batch_tamizada_kg_trigger ON public.plant_batch_bunques;
DROP FUNCTION IF EXISTS public.recalc_batch_tamizada_kg();

CREATE OR REPLACE FUNCTION public.recalc_batch_tamizada_kg_from_allocations()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        UPDATE public.plant_production_batches
        SET tamizada_kg = (
            SELECT COALESCE(SUM(kg), 0)
            FROM public.plant_bunque_batch_allocations
            WHERE plant_batch_id = NEW.plant_batch_id
        )
        WHERE id = NEW.plant_batch_id;
    END IF;

    IF (TG_OP = 'UPDATE' AND OLD.plant_batch_id IS DISTINCT FROM NEW.plant_batch_id) OR TG_OP = 'DELETE' THEN
        UPDATE public.plant_production_batches
        SET tamizada_kg = (
            SELECT COALESCE(SUM(kg), 0)
            FROM public.plant_bunque_batch_allocations
            WHERE plant_batch_id = OLD.plant_batch_id
        )
        WHERE id = OLD.plant_batch_id;
    END IF;

    RETURN NULL;
END;
$function$
;

CREATE TRIGGER recalc_batch_tamizada_kg_from_allocations_trigger
  AFTER INSERT OR UPDATE OR DELETE ON public.plant_bunque_batch_allocations
  FOR EACH ROW EXECUTE FUNCTION public.recalc_batch_tamizada_kg_from_allocations();

-- -----------------------------------------------------------------------------
-- 3. Trigger espejo: mientras la Fase 2 no exista, la pantalla actual sigue
--    escribiendo plant_batch_id + tamizada_kg en plant_batch_bunques como
--    siempre -- este trigger refleja ese único reparto (100% al lote de
--    plant_batch_id) en la tabla nueva, sin que la UI se entere.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sync_bunque_allocation()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- Por si algún día cambia el plant_batch_id de un bunque ya repartido
  -- (la UI actual no lo permite, pero no cuesta nada cubrirlo): limpia el
  -- reparto espejo de cualquier lote que ya no sea el actual.
  DELETE FROM public.plant_bunque_batch_allocations
  WHERE bunque_id = NEW.id AND plant_batch_id IS DISTINCT FROM NEW.plant_batch_id;

  IF NEW.tamizada_kg IS NOT NULL AND NEW.tamizada_kg > 0 THEN
    INSERT INTO public.plant_bunque_batch_allocations (bunque_id, plant_batch_id, kg, cooperative_id)
    VALUES (NEW.id, NEW.plant_batch_id, NEW.tamizada_kg, NEW.cooperative_id)
    ON CONFLICT (bunque_id, plant_batch_id) DO UPDATE SET kg = EXCLUDED.kg;
  ELSE
    DELETE FROM public.plant_bunque_batch_allocations
    WHERE bunque_id = NEW.id AND plant_batch_id = NEW.plant_batch_id;
  END IF;

  RETURN NULL;
END;
$function$
;

CREATE TRIGGER sync_bunque_allocation_trigger
  AFTER INSERT OR UPDATE OF plant_batch_id, tamizada_kg ON public.plant_batch_bunques
  FOR EACH ROW EXECUTE FUNCTION public.sync_bunque_allocation();

-- -----------------------------------------------------------------------------
-- 4. Backfill: un reparto 100% al lote actual por cada bunque que ya tiene
--    resultado registrado. Dispara el trigger de balance de masas de arriba
--    fila por fila, así plant_production_batches.tamizada_kg termina en el
--    mismo valor que ya tenía -- mismo dato, calculado por el camino nuevo.
-- -----------------------------------------------------------------------------
INSERT INTO public.plant_bunque_batch_allocations (bunque_id, plant_batch_id, kg, cooperative_id)
SELECT id, plant_batch_id, tamizada_kg, cooperative_id
FROM public.plant_batch_bunques
WHERE tamizada_kg IS NOT NULL AND tamizada_kg > 0
ON CONFLICT (bunque_id, plant_batch_id) DO NOTHING;
