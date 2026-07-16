-- =============================================================================
-- plant_homogenization_inputs pasa a colgar de un bunque, no directo del lote.
--
-- No hay datos reales en producción que preservar (confirmado con el
-- usuario), así que se trunca en vez de hacer backfill.
--
-- Esta migración es breaking para el frontend viejo (handleSaveHomo
-- insertaba con plant_batch_id) y debe desplegarse junto con el corte de
-- UI a la nueva pantalla de bunques -- no dejar el sistema a mitad de
-- camino en producción.
--
-- Nota de orden: todavía NO se elimina la columna plant_batch_id acá.
-- v_plant_order_summary depende de ella y recién se redefine en
-- 20260715160000_plant_order_summary_desde_bunques.sql. Eliminarla antes
-- rompe esa vista (ALTER TABLE ... DROP COLUMN falla por dependencia).
-- La columna vieja se elimina en 20260715165000, después de migrar la vista.
-- =============================================================================

TRUNCATE public.plant_homogenization_inputs;

ALTER TABLE public.plant_homogenization_inputs
  ADD COLUMN bunque_id uuid NOT NULL
    REFERENCES public.plant_batch_bunques(id) ON DELETE CASCADE;

CREATE INDEX idx_phi_bunque
  ON public.plant_homogenization_inputs (bunque_id);

-- -----------------------------------------------------------------------------
-- Corrección obligatoria: validate_homogenization_stock() referenciaba
-- plant_batch_id directamente para excluir "lo ya usado en OTROS lotes"
-- del cálculo de disponible. Postgres no valida columnas referenciadas
-- dentro de un cuerpo plpgsql al hacer CREATE OR REPLACE, así que si no se
-- corrige acá queda rota (falla recién en el primer INSERT/UPDATE real).
--
-- La unidad atómica de "reemplazar insumos" pasa de ser el lote a ser el
-- bunque (así se guarda ahora desde el frontend: borrar-e-insertar por
-- bunque, no por lote), así que la exclusión baja de nivel: ya no
-- "distinto lote", sino "distinto bunque".
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_homogenization_stock()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
    kg_received     NUMERIC;
    kg_already_used NUMERIC;
    kg_available    NUMERIC;
  BEGIN
    -- Kg realmente recibidos de este lote de origen
    SELECT COALESCE(quantity_kg_received, 0)
    INTO kg_received
    FROM exit_reception_items
    WHERE exit_item_id = NEW.source_exit_item_id
    LIMIT 1;

    -- Kg ya usados en OTROS bunques (excluyendo el bunque actual)
    SELECT COALESCE(SUM(quantity_kg), 0)
    INTO kg_already_used
    FROM plant_homogenization_inputs
    WHERE source_exit_item_id = NEW.source_exit_item_id
      AND bunque_id <> NEW.bunque_id;

    kg_available := kg_received - kg_already_used;

    IF NEW.quantity_kg > kg_available + 0.01 THEN
      RAISE EXCEPTION
        'Cantidad solicitada (% kg) excede el disponible (% kg) para este lote de origen.',
        NEW.quantity_kg, kg_available;
    END IF;

    RETURN NEW;
  END;
  $function$
;
