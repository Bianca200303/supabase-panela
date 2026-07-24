-- Hasta ahora "devoluciones" (product_returns) solo se registraba desde la
-- app móvil. Se agrega la posibilidad de registrarla también desde la web
-- (FormatoDevolucionSection.jsx), manteniendo la trazabilidad de quién la
-- registró en ambos casos.
--
-- created_by (varchar(8), FK a users.user_id) está pensado específicamente
-- para el formato de usuario de la app móvil -- un usuario web (web_users,
-- uuid) no calza ahí. En vez de aflojar esa FK (debilitando la validación
-- que ya protege los registros existentes del móvil), se agrega una
-- columna paralela created_by_web_user_id para el caso web. Cada fila
-- debe tener EXACTAMENTE UNO de los dos set -- nunca ninguno, nunca los
-- dos -- así siempre se sabe quién la registró, sea cual sea el origen.

alter table "public"."product_returns"
  alter column "created_by" drop not null;

alter table "public"."product_returns"
  add column "created_by_web_user_id" uuid null;

alter table "public"."product_returns"
  add constraint "product_returns_created_by_web_user_id_fkey"
  foreign key (created_by_web_user_id) references public.web_users(id) on delete restrict;

alter table "public"."product_returns"
  add constraint "product_returns_created_by_xor_web"
  check (
    (created_by is not null and created_by_web_user_id is null)
    or
    (created_by is null and created_by_web_user_id is not null)
  );

-- El trigger que completa created_by solo miraba la tabla "users" (móvil).
-- Ahora prueba primero móvil, y si no encuentra, prueba web_users.
CREATE OR REPLACE FUNCTION public.set_product_returns_created_by()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- No pisar un valor ya asignado explícitamente (por si alguna vez se
  -- necesita setearlo a mano, ej. desde un script de migración de datos).
  IF NEW.created_by IS NOT NULL OR NEW.created_by_web_user_id IS NOT NULL THEN
    RETURN NEW;
  END IF;

  SELECT user_id INTO NEW.created_by
  FROM users
  WHERE auth_user_id = auth.uid();

  IF NEW.created_by IS NULL THEN
    SELECT id INTO NEW.created_by_web_user_id
    FROM web_users
    WHERE auth_user_id = auth.uid();
  END IF;

  IF NEW.created_by IS NULL AND NEW.created_by_web_user_id IS NULL THEN
    RAISE EXCEPTION 'No se encontró usuario autenticado para la sesión actual';
  END IF;

  RETURN NEW;
END;
$function$
;

-- La validación de "el creador pertenece a la cooperativa" solo revisaba
-- la tabla "users". Ahora revisa la que corresponda según cuál de las dos
-- columnas viene con valor.
CREATE OR REPLACE FUNCTION public.validate_product_return()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF NEW.created_by IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM users
      WHERE user_id = NEW.created_by
      AND cooperative_id = NEW.cooperative_id
    ) THEN
      RAISE EXCEPTION 'El usuario creador no pertenece a la cooperativa especificada';
    END IF;
  ELSIF NEW.created_by_web_user_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM web_users
      WHERE id = NEW.created_by_web_user_id
      AND cooperative_id = NEW.cooperative_id
    ) THEN
      RAISE EXCEPTION 'El usuario creador no pertenece a la cooperativa especificada';
    END IF;
  ELSE
    RAISE EXCEPTION 'La devolución debe tener un usuario creador (móvil o web)';
  END IF;

  -- Validate production batch belongs to the same cooperative
  IF NOT EXISTS (
    SELECT 1 FROM production_batches
    WHERE id = NEW.production_batch_id
    AND cooperative_id = NEW.cooperative_id
  ) THEN
    RAISE EXCEPTION 'El lote de producción no pertenece a la cooperativa';
  END IF;

  -- Validate non-empty text fields
  IF trim(NEW.client_name) = '' THEN
    RAISE EXCEPTION 'El nombre del cliente no puede estar vacío';
  END IF;

  IF trim(NEW.return_reason) = '' THEN
    RAISE EXCEPTION 'La causa de devolución no puede estar vacía';
  END IF;

  -- Validate return date is not in the future
  IF NEW.return_date > CURRENT_DATE THEN
    RAISE EXCEPTION 'La fecha de devolución no puede ser futura';
  END IF;

  -- Validate observations if provided
  IF NEW.observations IS NOT NULL AND trim(NEW.observations) = '' THEN
    NEW.observations := NULL;  -- Convert empty string to NULL
  END IF;

  -- Validate quantity consistency (sacks -> kg conversion)
  -- If quantity_sacks is provided (> 0), quantity_kg should match (sacks * 50)
  IF NEW.quantity_sacks > 0 THEN
    DECLARE
      expected_kg NUMERIC := NEW.quantity_sacks * 50;
      tolerance NUMERIC := 0.01;  -- Allow small rounding differences
    BEGIN
      IF ABS(NEW.quantity_kg - expected_kg) > tolerance THEN
        RAISE WARNING 'Discrepancia entre kg (%) y bolsas (%): se esperaba % kg',
          NEW.quantity_kg, NEW.quantity_sacks, expected_kg;
      END IF;
    END;
  END IF;

  RETURN NEW;
END;
$function$
;
