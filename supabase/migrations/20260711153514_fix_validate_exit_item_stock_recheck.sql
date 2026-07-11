-- Evita el falso "Insufficient stock" al actualizar exit_items en campos
-- que no cambian quantity_kg (ej: item_document_number / comprobante de acopio).
--
-- El trigger validate_exit_item_trigger corre en BEFORE INSERT OR UPDATE y
-- revalidaba stock disponible en cada UPDATE, sin importar qué campo cambió.
-- Como el stock ya fue descontado por este mismo item al crearse (INSERT),
-- cualquier UPDATE posterior comparaba quantity_kg contra el stock ya
-- descontado y fallaba aunque no se estuviera pidiendo stock nuevo.
--
-- Ahora solo se revalida stock cuando es un INSERT o cuando quantity_kg
-- realmente cambia.

CREATE OR REPLACE FUNCTION public.validate_exit_item()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
      available_stock DECIMAL(10,2);
      exit_coop_id UUID;
      batch_coop_id UUID;
  BEGIN
      SELECT cooperative_id INTO exit_coop_id
      FROM exit_registrations
      WHERE id = NEW.exit_registration_id;

      SELECT cooperative_id INTO batch_coop_id
      FROM production_batches
      WHERE id = NEW.production_batch_id;

      IF NEW.cooperative_id != exit_coop_id OR NEW.cooperative_id != batch_coop_id THEN
          RAISE EXCEPTION 'All records must belong to the same cooperative';
      END IF;

      IF TG_OP = 'INSERT' OR NEW.quantity_kg IS DISTINCT FROM OLD.quantity_kg THEN
          SELECT available_kg INTO available_stock
          FROM inventory_stock
          WHERE production_batch_id = NEW.production_batch_id;

          IF available_stock IS NULL THEN
              RAISE EXCEPTION 'No stock record found for production batch';
          END IF;

          IF NEW.quantity_kg > available_stock THEN
              RAISE EXCEPTION 'Insufficient stock. Available: % kg, Requested: % kg', available_stock, NEW.quantity_kg;
          END IF;
      END IF;

      IF NOT NEW.is_autoconsumo THEN
          IF NEW.bags_count = 0 OR NEW.bags_count IS NULL THEN
              NEW.bags_count := ROUND(NEW.quantity_kg / 50.0, 2);
          END IF;

          IF NEW.bags_count * 50 < NEW.quantity_kg THEN
              RAISE EXCEPTION 'Bags count (%) insufficient for quantity (% kg). Need at least % bags',
                  NEW.bags_count, NEW.quantity_kg, ROUND(NEW.quantity_kg / 50.0, 2);
          END IF;
      ELSE
          NEW.bags_count := 0;
      END IF;

      RETURN NEW;
  END;
  $function$
;
