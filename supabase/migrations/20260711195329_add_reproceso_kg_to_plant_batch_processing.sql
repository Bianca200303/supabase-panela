-- Agrega "Reproceso" como tercer destino de la panela procesada (además de
-- Tamizado y Descarte), por ahora solo informativo: se registra el kg pero
-- el sistema no le da seguimiento de stock (no vuelve a aparecer como
-- entrada disponible en otro lote). Si en el futuro hace falta trazarlo
-- como stock reutilizable, se puede agregar esa capa sin tocar esta
-- columna ni el balance de masa de acá.
--
-- Estas 3 piezas van juntas a propósito: columna, constraints y el trigger
-- de balance de masa. Si solo se agregara la columna sin actualizar el
-- trigger, cualquier guardado con reproceso_kg > 0 sería rechazado, porque
-- el trigger seguiría exigiendo tamizada + descarte + merma = total.

ALTER TABLE public.plant_batch_processing
  ADD COLUMN reproceso_kg numeric(10,3) NOT NULL DEFAULT 0;

ALTER TABLE public.plant_batch_processing
  ADD CONSTRAINT chk_pbp_reproceso_non_negative CHECK (reproceso_kg >= 0);

-- El check de "no todo en cero" debe incluir reproceso, si no un lote con
-- solo reproceso_kg > 0 (y el resto en 0) fallaría igual.
ALTER TABLE public.plant_batch_processing
  DROP CONSTRAINT chk_pbp_no_all_zero;

ALTER TABLE public.plant_batch_processing
  ADD CONSTRAINT chk_pbp_no_all_zero
  CHECK ((tamizada_kg + reproceso_kg + descarte_kg + merma_kg) > 0);

-- Balance de masa: ahora incluye reproceso en la suma que debe igualar el
-- total ingresado al homogeneizado.
CREATE OR REPLACE FUNCTION public.validate_processing_totals()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
    total_input NUMERIC;
  BEGIN
    SELECT COALESCE(SUM(quantity_kg), 0)
    INTO total_input
    FROM plant_homogenization_inputs
    WHERE plant_batch_id = NEW.plant_batch_id;

    IF total_input = 0 THEN
      RAISE EXCEPTION 'El lote no tiene homogenizado registrado';
    END IF;

    IF ABS((NEW.tamizada_kg + NEW.reproceso_kg + NEW.descarte_kg + NEW.merma_kg) - total_input) > 0.1 THEN
      RAISE EXCEPTION
        'La suma tamizada (%) + reproceso (%) + descarte (%) + merma (%) = % kg, pero el total homogenizado es % kg. Deben ser iguales.',
        NEW.tamizada_kg, NEW.reproceso_kg, NEW.descarte_kg, NEW.merma_kg,
        (NEW.tamizada_kg + NEW.reproceso_kg + NEW.descarte_kg + NEW.merma_kg),
        total_input;
    END IF;

    RETURN NEW;
  END;
  $function$
;
