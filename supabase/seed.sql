


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."inspection_condition_enum" AS ENUM (
    'compliant',
    'non_compliant'
);


ALTER TYPE "public"."inspection_condition_enum" OWNER TO "postgres";


CREATE TYPE "public"."sack_condition_enum" AS ENUM (
    'good',
    'regular',
    'bad'
);


ALTER TYPE "public"."sack_condition_enum" OWNER TO "postgres";


CREATE TYPE "public"."vehicle_condition_enum" AS ENUM (
    'adequate',
    'deficient'
);


ALTER TYPE "public"."vehicle_condition_enum" OWNER TO "postgres";


-- ============================================================================
-- FUNCIONES BASE DE SEGURIDAD
-- Deben estar antes de cualquier política RLS que las use.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.auth_cooperative_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT NULLIF(
    current_setting('request.jwt.claims', true)::jsonb ->> 'cooperative_id',
    ''
  )::uuid
$$;

COMMENT ON FUNCTION public.auth_cooperative_id() IS
  'Retorna cooperative_id del JWT. NULL si no está autenticado o no tiene cooperativa.';

GRANT EXECUTE ON FUNCTION public.auth_cooperative_id() TO anon, authenticated, service_role;


CREATE OR REPLACE FUNCTION public.is_service_role()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT coalesce(
    current_setting('request.jwt.claims', true)::jsonb ->> 'role' = 'service_role',
    false
  )
$$;

GRANT EXECUTE ON FUNCTION public.is_service_role() TO anon, authenticated, service_role;

-- ============================================================================


CREATE OR REPLACE FUNCTION "public"."auto_assign_plot_code"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    -- Only assign code if it's not provided
    IF NEW.code IS NULL OR NEW.code = '' THEN
        -- Generate code based on producer_id directly (no need to lookup cooperative)
        NEW.code := generate_plot_code(NEW.producer_id);
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."auto_assign_plot_code"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."auto_assign_plot_code"() IS 'Trigger function that automatically assigns plot codes in DNI-NUMBER format when code is NULL or empty - SECURITY DEFINER';



CREATE OR REPLACE FUNCTION "public"."auto_generate_exit_code"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Only generate if exit_code is not provided
    IF NEW.exit_code IS NULL OR NEW.exit_code = '' THEN
        NEW.exit_code := generate_exit_code(NEW.cooperative_id);
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."auto_generate_exit_code"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_auth_user_for_dni"("dni" character varying, "user_password" "text", "user_email" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_auth_user_id UUID;
  virtual_email TEXT;
BEGIN
  -- Use provided email or create virtual email for DNI
  IF user_email IS NULL THEN
    virtual_email := dni || '@dni.local';
  ELSE
    virtual_email := user_email;
  END IF;

  -- Create user in auth.users table
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    virtual_email,
    crypt(user_password, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  ) RETURNING id INTO v_auth_user_id;

  -- Update users table with auth_user_id and email
  UPDATE public.users
  SET
    auth_user_id = v_auth_user_id,
    email = virtual_email
  WHERE user_id = dni;

  RETURN v_auth_user_id;
END;
$$;


ALTER FUNCTION "public"."create_auth_user_for_dni"("dni" character varying, "user_password" "text", "user_email" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_auth_user_for_dni"("dni" character varying, "user_password" "text", "cooperative_id" "uuid", "user_email" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_auth_user_id UUID;
  virtual_email TEXT;
  coop_code VARCHAR(50);
BEGIN
  -- Get cooperative code
  SELECT get_cooperative_code($3) INTO coop_code;

  -- Use provided email or create virtual email for DNI with cooperative code
  IF user_email IS NULL THEN
    virtual_email := dni || '.' || coop_code || '@dni.local';
  ELSE
    virtual_email := user_email;
  END IF;

  -- Create user in auth.users table
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    virtual_email,
    crypt(user_password, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  ) RETURNING id INTO v_auth_user_id;

  -- Update users table with auth_user_id and email
  UPDATE public.users
  SET
    auth_user_id = v_auth_user_id,
    email = virtual_email
  WHERE user_id = dni AND public.users.cooperative_id = $3;

  RETURN v_auth_user_id;
END;
$$;


ALTER FUNCTION "public"."create_auth_user_for_dni"("dni" character varying, "user_password" "text", "cooperative_id" "uuid", "user_email" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."create_auth_user_for_dni"("dni" character varying, "user_password" "text", "cooperative_id" "uuid", "user_email" "text") IS 'Creates auth user with virtual email format: dni.COOPERATIVECODE@dni.local';



CREATE OR REPLACE FUNCTION "public"."generate_exit_code"("coop_id" "uuid") RETURNS character varying
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    coop_code VARCHAR(10);
    uuid_part VARCHAR(8);
    new_code VARCHAR(50);
BEGIN
    -- Get cooperative code
    SELECT code INTO coop_code
    FROM cooperatives
    WHERE id = coop_id;

    -- Generate UUID part (first 8 characters of UUID)
    uuid_part := SUBSTRING(gen_random_uuid()::TEXT, 1, 8);

    -- Generate new code: COOP-YYYYMMDD-{uuid_8chars}
    -- Example: NORANDINO-20251028-a1b2c3d4
    new_code := coop_code || '-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || uuid_part;

    RETURN new_code;
END;
$$;


ALTER FUNCTION "public"."generate_exit_code"("coop_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_plot_code"("producer_id_param" "uuid") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    producer_dni VARCHAR(8);
    next_code INTEGER;
    sequence_name TEXT;
BEGIN
    -- Get producer DNI
    SELECT dni INTO producer_dni
    FROM public.producers
    WHERE id = producer_id_param;

    IF producer_dni IS NULL THEN
        RAISE EXCEPTION 'Producer not found: %', producer_id_param;
    END IF;

    -- Create producer-specific sequence name
    sequence_name := 'plot_code_seq_' || REPLACE(producer_id_param::TEXT, '-', '_');

    -- Create sequence if it doesn't exist
    EXECUTE format('CREATE SEQUENCE IF NOT EXISTS %I START 1', sequence_name);

    -- Get next value from sequence
    EXECUTE format('SELECT nextval(%L)', sequence_name) INTO next_code;

    -- Return formatted code: DNI-CODE (no padding on number)
    RETURN producer_dni || '-' || next_code::TEXT;
END;
$$;


ALTER FUNCTION "public"."generate_plot_code"("producer_id_param" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."generate_plot_code"("producer_id_param" "uuid") IS 'Generates next plot code for a producer in format DNI-NUMBER (e.g., 12345678-1, 12345678-2) - SECURITY DEFINER';



CREATE OR REPLACE FUNCTION "public"."get_cooperative_code"("coop_id" "uuid") RETURNS character varying
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  coop_code VARCHAR(50);
BEGIN
  SELECT code INTO coop_code
  FROM public.cooperatives
  WHERE id = coop_id;

  IF coop_code IS NULL THEN
    RAISE EXCEPTION 'Cooperative not found: %', coop_id;
  END IF;

  RETURN coop_code;
END;
$$;


ALTER FUNCTION "public"."get_cooperative_code"("coop_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_cooperative_code"("coop_id" "uuid") IS 'Returns cooperative code for building unique virtual emails per cooperative';





CREATE OR REPLACE FUNCTION "public"."get_next_plot_code"("producer_id_param" "uuid") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    producer_dni VARCHAR(8);
    next_code INTEGER;
    sequence_name TEXT;
BEGIN
    -- Get producer DNI
    SELECT dni INTO producer_dni
    FROM public.producers
    WHERE id = producer_id_param;

    IF producer_dni IS NULL THEN
        RAISE EXCEPTION 'Producer not found: %', producer_id_param;
    END IF;

    -- Create producer-specific sequence name
    sequence_name := 'plot_code_seq_' || REPLACE(producer_id_param::TEXT, '-', '_');

    -- Create sequence if it doesn't exist
    EXECUTE format('CREATE SEQUENCE IF NOT EXISTS %I START 1', sequence_name);

    -- Get current value without incrementing (for preview)
    EXECUTE format('SELECT last_value + CASE WHEN is_called THEN 1 ELSE 0 END FROM %I', sequence_name) INTO next_code;

    -- Return formatted code: DNI-CODE
    RETURN producer_dni || '-' || next_code::TEXT;
END;
$$;


ALTER FUNCTION "public"."get_next_plot_code"("producer_id_param" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_next_plot_code"("producer_id_param" "uuid") IS 'Preview the next available plot code for a producer without incrementing the sequence - SECURITY DEFINER';




CREATE OR REPLACE FUNCTION "public"."initialize_stock_for_batch"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Initialize stock with panela quantity (sellable product)
    -- Confitillo is tracked separately but doesn't go into inventory
    INSERT INTO inventory_stock (production_batch_id, current_kg, cooperative_id)
    VALUES (NEW.id, COALESCE(NEW.panela_kg, 0), NEW.cooperative_id);

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."initialize_stock_for_batch"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."initialize_stock_for_batch"() IS 'Initializes inventory stock with panela_kg (sellable product). Confitillo is tracked in production_batches but does not affect inventory.';



CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_created_by_from_auth"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Get user_id from users table matching the authenticated user
  SELECT user_id INTO NEW.created_by
  FROM users
  WHERE auth_user_id = auth.uid();

  -- If no user found, raise exception
  IF NEW.created_by IS NULL THEN
    RAISE EXCEPTION 'No user found for authenticated session';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_created_by_from_auth"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_created_by_from_auth_chlorine"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    NEW.created_by := auth.uid();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_created_by_from_auth_chlorine"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_created_by_from_auth_cleaning"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    NEW.created_by := auth.uid();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_created_by_from_auth_cleaning"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_created_by_from_auth_pest"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    NEW.created_by := auth.uid();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_created_by_from_auth_pest"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_equipment_maintenance_created_by"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Get user_id from users table based on auth.uid()
  SELECT user_id INTO NEW.created_by
  FROM users
  WHERE auth_user_id = auth.uid();

  -- Raise error if no user found
  IF NEW.created_by IS NULL THEN
    RAISE EXCEPTION 'No se encontró usuario autenticado para la sesión actual';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_equipment_maintenance_created_by"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_health_incident_created_by"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  SELECT user_id INTO NEW.created_by
  FROM users
  WHERE auth_user_id = auth.uid();

  IF NEW.created_by IS NULL THEN
    RAISE EXCEPTION 'No user found for authenticated session';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_health_incident_created_by"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_product_returns_created_by"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Get user_id from users table based on auth.uid()
  SELECT user_id INTO NEW.created_by
  FROM users
  WHERE auth_user_id = auth.uid();

  -- Raise error if no user found
  IF NEW.created_by IS NULL THEN
    RAISE EXCEPTION 'No se encontró usuario autenticado para la sesión actual';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_product_returns_created_by"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_worker_controls_created_by"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Get user_id from users table based on auth.uid()
  SELECT user_id INTO NEW.created_by
  FROM users
  WHERE auth_user_id = auth.uid();

  -- Raise error if no user found
  IF NEW.created_by IS NULL THEN
    RAISE EXCEPTION 'No se encontró usuario autenticado para la sesión actual';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_worker_controls_created_by"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."setup_dni_user_auth"("dni" character varying, "user_password" "text", "user_email" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  user_exists BOOLEAN;
  auth_id UUID;
  result JSONB;
BEGIN
  -- Check if user exists in users table
  SELECT EXISTS(SELECT 1 FROM public.users WHERE user_id = dni) INTO user_exists;
  
  IF NOT user_exists THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Usuario con DNI ' || dni || ' no existe'
    );
  END IF;

  -- Check if user already has auth setup
  SELECT auth_user_id FROM public.users WHERE user_id = dni INTO auth_id;
  
  IF auth_id IS NOT NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Usuario ya tiene autenticación configurada'
    );
  END IF;

  -- Create auth user
  SELECT create_auth_user_for_dni(dni, user_password, user_email) INTO auth_id;

  RETURN jsonb_build_object(
    'success', true,
    'auth_user_id', auth_id,
    'message', 'Autenticación configurada exitosamente para DNI ' || dni
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;


ALTER FUNCTION "public"."setup_dni_user_auth"("dni" character varying, "user_password" "text", "user_email" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."setup_dni_user_auth"("dni" character varying, "user_password" "text", "cooperative_id" "uuid", "user_email" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  user_exists BOOLEAN;
  auth_id UUID;
  result JSONB;
BEGIN
  -- Check if user exists in users table for this cooperative
  SELECT EXISTS(
    SELECT 1 FROM public.users
    WHERE user_id = dni AND public.users.cooperative_id = $3
  ) INTO user_exists;

  IF NOT user_exists THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Usuario con DNI ' || dni || ' no existe en esta cooperativa'
    );
  END IF;

  -- Check if user already has auth setup for this cooperative
  SELECT auth_user_id FROM public.users
  WHERE user_id = dni AND public.users.cooperative_id = $3
  INTO auth_id;

  IF auth_id IS NOT NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Usuario ya tiene autenticación configurada'
    );
  END IF;

  -- Create auth user
  SELECT create_auth_user_for_dni(dni, user_password, cooperative_id, user_email) INTO auth_id;

  RETURN jsonb_build_object(
    'success', true,
    'auth_user_id', auth_id,
    'message', 'Autenticación configurada exitosamente para DNI ' || dni
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;


ALTER FUNCTION "public"."setup_dni_user_auth"("dni" character varying, "user_password" "text", "cooperative_id" "uuid", "user_email" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_exit_total"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    exit_id UUID;
    total_weight DECIMAL(10,2);
BEGIN
    -- Get exit registration ID
    IF TG_OP = 'DELETE' THEN
        exit_id := OLD.exit_registration_id;
    ELSE
        exit_id := NEW.exit_registration_id;
    END IF;
    
    -- Calculate new total
    SELECT COALESCE(SUM(quantity_kg), 0) INTO total_weight
    FROM exit_items
    WHERE exit_registration_id = exit_id;
    
    -- Update exit registration
    UPDATE exit_registrations 
    SET total_kg = total_weight,
        updated_at = NOW()
    WHERE id = exit_id;
    
    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION "public"."update_exit_total"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_plot_default_percentages"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Only proceed if the inserted batch has percentage values AND a plot_id
    IF NEW.porcentaje_extraccion IS NOT NULL
       AND NEW.cachaza_percentage IS NOT NULL
       AND NEW.plot_id IS NOT NULL THEN

        -- Update plot defaults with the values from this batch
        UPDATE public.plots
        SET
            default_extraction_percentage = NEW.porcentaje_extraccion,
            default_cachaza_percentage = NEW.cachaza_percentage,
            updated_at = NOW()
        WHERE id = NEW.plot_id;

        -- Log the update for debugging (optional)
        RAISE NOTICE 'Updated plot % defaults: extraction=%, cachaza=% (from latest batch)',
            NEW.plot_id, NEW.porcentaje_extraccion, NEW.cachaza_percentage;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_plot_default_percentages"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_plot_default_percentages"() IS 'Automatically updates plot default percentages using values from the most recent production batch';



CREATE OR REPLACE FUNCTION "public"."update_producer_default_percentages"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Only proceed if the inserted batch has percentage values
    IF NEW.porcentaje_extraccion IS NOT NULL AND NEW.cachaza_percentage IS NOT NULL THEN

        -- Update producer defaults with the values from this batch (not average)
        UPDATE public.producers
        SET
            default_extraction_percentage = NEW.porcentaje_extraccion,
            default_cachaza_percentage = NEW.cachaza_percentage,
            updated_at = NOW()
        WHERE id = NEW.producer_id;

        -- Log the update for debugging (optional)
        RAISE NOTICE 'Updated producer % defaults: extraction=%, cachaza=% (from latest batch)',
            NEW.producer_id, NEW.porcentaje_extraccion, NEW.cachaza_percentage;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_producer_default_percentages"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_producer_default_percentages"() IS 'Automatically updates producer default percentages using values from the most recent production batch (not average)';



CREATE OR REPLACE FUNCTION "public"."update_stock_after_exit"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    old_quantity DECIMAL(10,2) := 0;
    new_quantity DECIMAL(10,2) := 0;
    stock_change DECIMAL(10,2);
BEGIN
    -- Handle different trigger events
    IF TG_OP = 'INSERT' THEN
        new_quantity := NEW.quantity_kg;
    ELSIF TG_OP = 'UPDATE' THEN
        old_quantity := OLD.quantity_kg;
        new_quantity := NEW.quantity_kg;
    ELSIF TG_OP = 'DELETE' THEN
        old_quantity := OLD.quantity_kg;
    END IF;
    
    -- Calculate stock change (negative means stock reduction)
    stock_change := old_quantity - new_quantity;
    
    -- Update inventory stock
    IF TG_OP = 'DELETE' THEN
        UPDATE inventory_stock 
        SET current_kg = current_kg + stock_change,
            updated_at = NOW()
        WHERE production_batch_id = OLD.production_batch_id;
    ELSE
        UPDATE inventory_stock 
        SET current_kg = current_kg + stock_change,
            updated_at = NOW()
        WHERE production_batch_id = NEW.production_batch_id;
    END IF;
    
    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION "public"."update_stock_after_exit"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."user_belongs_to_cooperative"("coop_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.users 
        WHERE auth_user_id = auth.uid() 
        AND cooperative_id = coop_id
    );
END;
$$;


ALTER FUNCTION "public"."user_belongs_to_cooperative"("coop_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_certificate_exclusion_groups"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    exclusion_group_uuid UUID;
    conflict_count INTEGER;
    group_name VARCHAR(100);
BEGIN
    -- Get the exclusion group ID of the certificate being added
    SELECT bc.exclusion_group_id INTO exclusion_group_uuid
    FROM batch_certs bc
    WHERE bc.id = NEW.batch_cert_id;

    -- If certificate has no exclusion group, allow it
    IF exclusion_group_uuid IS NULL THEN
        RETURN NEW;
    END IF;

    -- Check if there are already certificates from the same exclusion group for this batch
    SELECT COUNT(*) INTO conflict_count
    FROM production_batch_certs pbc
    JOIN batch_certs bc ON pbc.batch_cert_id = bc.id
    WHERE pbc.production_batch_id = NEW.production_batch_id
      AND bc.exclusion_group_id = exclusion_group_uuid
      AND pbc.batch_cert_id != NEW.batch_cert_id; -- Exclude the current certificate (for updates)

    -- If there are conflicts, get group name for better error message
    IF conflict_count > 0 THEN
        SELECT ceg.display_name INTO group_name
        FROM certificate_exclusion_groups ceg
        WHERE ceg.id = exclusion_group_uuid;

        RAISE EXCEPTION 'Certificate exclusion group violation: Only one certificate from group "%" can be selected per batch', COALESCE(group_name, 'Unknown Group');
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_certificate_exclusion_groups"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_environment_inspection"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Ensure user belongs to the same cooperative
    IF NOT EXISTS (
        SELECT 1
        FROM users
        WHERE user_id = NEW.created_by
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'User must belong to the same cooperative';
    END IF;

    -- Ensure module belongs to the same cooperative
    IF NOT EXISTS (
        SELECT 1
        FROM coop_modules
        WHERE id = NEW.coop_module_id
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'Module must belong to the same cooperative';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_environment_inspection"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_equipment_maintenance_record"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Validate creator belongs to the same cooperative
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE user_id = NEW.created_by
    AND cooperative_id = NEW.cooperative_id
  ) THEN
    RAISE EXCEPTION 'El usuario creador no pertenece a la cooperativa especificada';
  END IF;

  -- Validate module belongs to the same cooperative
  IF NOT EXISTS (
    SELECT 1 FROM coop_modules
    WHERE id = NEW.coop_module_id
    AND cooperative_id = NEW.cooperative_id
  ) THEN
    RAISE EXCEPTION 'El módulo especificado no pertenece a la cooperativa';
  END IF;

  -- Validate non-empty text fields
  IF trim(NEW.equipment_name) = '' THEN
    RAISE EXCEPTION 'El nombre del equipo no puede estar vacío';
  END IF;

  IF trim(NEW.maintenance_cause) = '' THEN
    RAISE EXCEPTION 'La causa del mantenimiento no puede estar vacía';
  END IF;

  IF trim(NEW.responsible_person) = '' THEN
    RAISE EXCEPTION 'El responsable del mantenimiento no puede estar vacío';
  END IF;

  -- Validate materials_used if provided
  IF NEW.materials_used IS NOT NULL AND trim(NEW.materials_used) = '' THEN
    NEW.materials_used := NULL;  -- Convert empty string to NULL
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_equipment_maintenance_record"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_exit_item"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
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

      SELECT available_kg INTO available_stock
      FROM inventory_stock
      WHERE production_batch_id = NEW.production_batch_id;

      IF available_stock IS NULL THEN
          RAISE EXCEPTION 'No stock record found for production batch';
      END IF;

      IF NEW.quantity_kg > available_stock THEN
          RAISE EXCEPTION 'Insufficient stock. Available: % kg, Requested: % kg', available_stock, NEW.quantity_kg;
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
  $$;


ALTER FUNCTION "public"."validate_exit_item"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_exit_registration"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Ensure user belongs to the same cooperative
    IF NOT EXISTS (
        SELECT 1 
        FROM users 
        WHERE user_id = NEW.created_by 
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'User must belong to the same cooperative';
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_exit_registration"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_health_incident"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Ensure creator belongs to the same cooperative
    IF NOT EXISTS (
        SELECT 1 FROM users
        WHERE user_id = NEW.created_by
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'Creator must belong to the same cooperative';
    END IF;

    -- Ensure module belongs to the same cooperative
    IF NOT EXISTS (
        SELECT 1 FROM coop_modules
        WHERE id = NEW.coop_module_id
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'Module must belong to the same cooperative';
    END IF;

    -- If "other" action is selected, detail is required
    IF NEW.action_other = TRUE AND
       (NEW.other_action_detail IS NULL OR NEW.other_action_detail = '') THEN
        RAISE EXCEPTION 'Other action detail is required when "other" action is selected';
    END IF;

    -- At least one action must be selected
    IF NEW.action_rest = FALSE AND
       NEW.action_medical_attention = FALSE AND
       NEW.action_relocation = FALSE AND
       NEW.action_medication = FALSE AND
       NEW.action_other = FALSE THEN
        RAISE EXCEPTION 'At least one action must be selected';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_health_incident"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_homogenization_stock"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
  DECLARE
    kg_received   NUMERIC;
    kg_already_used NUMERIC;
    kg_available  NUMERIC;
  BEGIN
    -- Kg realmente recibidos de este lote de origen
    SELECT COALESCE(quantity_kg_received, 0)
    INTO kg_received
    FROM exit_reception_items
    WHERE exit_item_id = NEW.source_exit_item_id
    LIMIT 1;

    -- Kg ya usados en OTROS lotes de planta (excluyendo el lote actual)
    SELECT COALESCE(SUM(quantity_kg), 0)
    INTO kg_already_used
    FROM plant_homogenization_inputs
    WHERE source_exit_item_id = NEW.source_exit_item_id
      AND plant_batch_id <> NEW.plant_batch_id;

    kg_available := kg_received - kg_already_used;

    IF NEW.quantity_kg > kg_available + 0.01 THEN
      RAISE EXCEPTION
        'El lote de origen no tiene suficiente cantidad disponible — disponible: % kg, solicitado: % kg.',
        ROUND(kg_available::numeric, 2),
        ROUND(NEW.quantity_kg::numeric, 2);
    END IF;

    RETURN NEW;
  END;
  $$;


ALTER FUNCTION "public"."validate_homogenization_stock"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_processing_totals"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
  DECLARE
    total_input NUMERIC;
  BEGIN
    -- Suma todos los kg del homogenizado para este lote
    SELECT COALESCE(SUM(quantity_kg), 0)
    INTO total_input
    FROM plant_homogenization_inputs
    WHERE plant_batch_id = NEW.plant_batch_id;

    IF total_input = 0 THEN
      RAISE EXCEPTION 'El lote no tiene homogenizado registrado';
    END IF;

    IF ABS((NEW.tamizada_kg + NEW.descarte_kg + NEW.merma_kg) - total_input) > 0.1 THEN
      RAISE EXCEPTION
        'La suma tamizada (%) + descarte (%) + merma (%) = % kg, pero el total homogenizado es % kg. Deben ser
  iguales.',
        NEW.tamizada_kg, NEW.descarte_kg, NEW.merma_kg,
        (NEW.tamizada_kg + NEW.descarte_kg + NEW.merma_kg),
        total_input;
    END IF;

    RETURN NEW;
  END;
  $$;


ALTER FUNCTION "public"."validate_processing_totals"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_producer_module"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM public.coop_modules 
        WHERE id = NEW.coop_module_id 
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'Module must belong to the same cooperative as the producer';
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_producer_module"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_product_return"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Validate creator belongs to the same cooperative
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE user_id = NEW.created_by
    AND cooperative_id = NEW.cooperative_id
  ) THEN
    RAISE EXCEPTION 'El usuario creador no pertenece a la cooperativa especificada';
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
$$;


ALTER FUNCTION "public"."validate_product_return"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_production_batch_plot"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- If plot_id is provided, validate it belongs to the producer
    IF NEW.plot_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1
            FROM plots
            WHERE id = NEW.plot_id
            AND producer_id = NEW.producer_id
            AND is_active = true
        ) THEN
            RAISE EXCEPTION 'La parcela debe pertenecer al productor seleccionado';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_production_batch_plot"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_stock_operation"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Ensure cooperative consistency
    IF NOT EXISTS (
        SELECT 1 
        FROM production_batches pb
        WHERE pb.id = NEW.production_batch_id 
        AND pb.cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'Production batch must belong to the same cooperative as stock record';
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_stock_operation"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_stowage_transport_inspection"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Ensure user belongs to the same cooperative
    IF NOT EXISTS (
        SELECT 1
        FROM users
        WHERE user_id = NEW.created_by
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'User must belong to the same cooperative';
    END IF;

    -- Ensure exit registration belongs to the same cooperative
    IF NOT EXISTS (
        SELECT 1
        FROM exit_registrations
        WHERE id = NEW.exit_registration_id
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'Exit registration must belong to the same cooperative';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_stowage_transport_inspection"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_worker_control"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Validate creator belongs to the same cooperative
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE user_id = NEW.created_by
    AND cooperative_id = NEW.cooperative_id
  ) THEN
    RAISE EXCEPTION 'El usuario creador no pertenece a la cooperativa especificada';
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
  IF trim(NEW.worker_name) = '' THEN
    RAISE EXCEPTION 'El nombre del trabajador no puede estar vacío';
  END IF;

  -- Validate observations if provided
  IF NEW.observations IS NOT NULL AND trim(NEW.observations) = '' THEN
    NEW.observations := NULL;  -- Convert empty string to NULL
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_worker_control"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."batch_certs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(100) NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "is_active" boolean DEFAULT true,
    "exclusion_group_id" "uuid",
    "is_default" boolean DEFAULT false
);


ALTER TABLE "public"."batch_certs" OWNER TO "postgres";


COMMENT ON TABLE "public"."batch_certs" IS 'Certificates available for batches - each cooperative has their own predefined set';



COMMENT ON COLUMN "public"."batch_certs"."name" IS 'Certificate name (e.g., Orgánica, SPP, Convencional, FLO, Naturland)';



COMMENT ON COLUMN "public"."batch_certs"."cooperative_id" IS 'Links certificate to cooperative for multi-tenant isolation';



COMMENT ON COLUMN "public"."batch_certs"."exclusion_group_id" IS 'References certificate_exclusion_groups table for abstract group management';



COMMENT ON COLUMN "public"."batch_certs"."is_default" IS 'Whether this certificate should be pre-selected by default in the UI';



CREATE TABLE IF NOT EXISTS "public"."batch_ph_controls" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "production_batch_id" "uuid" NOT NULL,
    "record_date" timestamp with time zone DEFAULT "now"(),
    "regulator_type" character varying(100) DEFAULT 'cal'::character varying NOT NULL,
    "ph_initial" numeric(4,2) NOT NULL,
    "ph_final" numeric(4,2) NOT NULL,
    "brix" numeric(5,2),
    "corrective_action" "text",
    "cooperative_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "regulator_quantity_kg" numeric(10,2),
    "regulator_quantity_value" numeric(10,2),
    "regulator_quantity_unit" character varying(10),
    CONSTRAINT "batch_ph_controls_brix_check" CHECK ((("brix" >= (0)::numeric) AND ("brix" <= (100)::numeric))),
    CONSTRAINT "batch_ph_controls_ph_final_check" CHECK ((("ph_final" >= (0)::numeric) AND ("ph_final" <= (14)::numeric))),
    CONSTRAINT "batch_ph_controls_ph_initial_check" CHECK ((("ph_initial" >= (0)::numeric) AND ("ph_initial" <= (14)::numeric))),
    CONSTRAINT "batch_ph_controls_regulator_quantity_kg_check" CHECK (("regulator_quantity_kg" >= (0)::numeric)),
    CONSTRAINT "valid_regulator_unit" CHECK ((("regulator_quantity_unit" IS NULL) OR (("regulator_quantity_unit")::"text" = ANY ((ARRAY['gr'::character varying, 'mL'::character varying, 'L'::character varying])::"text"[]))))
);


ALTER TABLE "public"."batch_ph_controls" OWNER TO "postgres";


COMMENT ON COLUMN "public"."batch_ph_controls"."regulator_quantity_kg" IS 'Cantidad de regulador de pH utilizado en kilogramos';



COMMENT ON COLUMN "public"."batch_ph_controls"."regulator_quantity_value" IS 'Cantidad de regulador de pH utilizado en su unidad original';



COMMENT ON COLUMN "public"."batch_ph_controls"."regulator_quantity_unit" IS 'Unidad de medida del regulador: gr, mL o L';



CREATE TABLE IF NOT EXISTS "public"."batch_temperatures" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "production_batch_id" "uuid" NOT NULL,
    "temperature" numeric(6,2) NOT NULL,
    "sequence_number" integer NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "batch_temperatures_sequence_number_check" CHECK (("sequence_number" > 0))
);


ALTER TABLE "public"."batch_temperatures" OWNER TO "postgres";


COMMENT ON COLUMN "public"."batch_temperatures"."temperature" IS 'Temperatura registrada en grados Celsius (DECIMAL 6,2)';



CREATE TABLE IF NOT EXISTS "public"."certificate_exclusion_groups" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(100) NOT NULL,
    "display_name" character varying(100) NOT NULL,
    "description" "text",
    "is_required" boolean DEFAULT true,
    "cooperative_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "is_active" boolean DEFAULT true
);


ALTER TABLE "public"."certificate_exclusion_groups" OWNER TO "postgres";


COMMENT ON TABLE "public"."certificate_exclusion_groups" IS 'Abstract table for managing mutually exclusive certificate groups with configurable defaults';



COMMENT ON COLUMN "public"."certificate_exclusion_groups"."name" IS 'Internal identifier for the group (e.g., production_type, quality_level)';



COMMENT ON COLUMN "public"."certificate_exclusion_groups"."display_name" IS 'User-friendly name shown in the UI (e.g., Tipo de producción)';



COMMENT ON COLUMN "public"."certificate_exclusion_groups"."is_required" IS 'Whether user must select a certificate from this group';



CREATE TABLE IF NOT EXISTS "public"."chlorine_residual_controls" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "coop_module_id" "uuid" NOT NULL,
    "control_date" "date" NOT NULL,
    "control_time" time without time zone DEFAULT '06:00:00'::time without time zone NOT NULL,
    "measurement_point_1" numeric(4,2) NOT NULL,
    "measurement_point_2" numeric(4,2) NOT NULL,
    "corrective_actions" "text",
    "observations" "text",
    "responsible_person" "text" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "valid_measurement_1" CHECK ((("measurement_point_1" >= (0)::numeric) AND ("measurement_point_1" <= (10)::numeric))),
    CONSTRAINT "valid_measurement_2" CHECK ((("measurement_point_2" >= (0)::numeric) AND ("measurement_point_2" <= (10)::numeric)))
);


ALTER TABLE "public"."chlorine_residual_controls" OWNER TO "postgres";


COMMENT ON TABLE "public"."chlorine_residual_controls" IS 'Daily chlorine control records with two measurement points (M1: sanitization, M2: process/sieving). One record per module per date/time.';



COMMENT ON COLUMN "public"."chlorine_residual_controls"."control_date" IS 'Date when the chlorine control was performed.';



COMMENT ON COLUMN "public"."chlorine_residual_controls"."control_time" IS 'Time when the chlorine control was performed. Defaults to 06:00:00 (6:00 AM).';



COMMENT ON COLUMN "public"."chlorine_residual_controls"."measurement_point_1" IS 'M1: Chlorine measurement (ppm) from sanitization water supply. Safe range: 0.5-2.0 ppm.';



COMMENT ON COLUMN "public"."chlorine_residual_controls"."measurement_point_2" IS 'M2: Chlorine measurement (ppm) from process/sieving water supply. Safe range: 0.5-2.0 ppm.';



COMMENT ON COLUMN "public"."chlorine_residual_controls"."corrective_actions" IS 'Corrective actions taken if measurements are outside safe range (e.g., "Certified to 3 ppm").';



COMMENT ON COLUMN "public"."chlorine_residual_controls"."responsible_person" IS 'Name of the person who performed the measurement (free text field).';



COMMENT ON CONSTRAINT "valid_measurement_1" ON "public"."chlorine_residual_controls" IS 'Ensures M1 measurement is within valid range (0-10 ppm).';



COMMENT ON CONSTRAINT "valid_measurement_2" ON "public"."chlorine_residual_controls" IS 'Ensures M2 measurement is within valid range (0-10 ppm).';



CREATE TABLE IF NOT EXISTS "public"."cleaning_disinfection_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cleaning_disinfection_id" "uuid" NOT NULL,
    "area_code" character varying(50) NOT NULL,
    "point_code" character varying(50) NOT NULL,
    "point_description" "text" NOT NULL,
    "uses_chlorine" boolean DEFAULT true NOT NULL,
    "uses_detergent" boolean DEFAULT true NOT NULL,
    "uses_other_product" boolean DEFAULT true NOT NULL,
    "observations" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cleaning_disinfection_items" OWNER TO "postgres";


COMMENT ON TABLE "public"."cleaning_disinfection_items" IS 'Child table storing individual cleaning points. Each record represents one cleaning point from one area.';



COMMENT ON COLUMN "public"."cleaning_disinfection_items"."area_code" IS 'Area code (e.g., reception_milling, thermal_treatment). See CleaningAreas constants in Flutter models.';



COMMENT ON COLUMN "public"."cleaning_disinfection_items"."point_code" IS 'Point code within the area (e.g., walls, floors, equipment). See CleaningPointTemplates in Flutter models.';



COMMENT ON COLUMN "public"."cleaning_disinfection_items"."uses_chlorine" IS 'DEFAULT TRUE: Assume chlorine was used unless explicitly unchecked.';



COMMENT ON COLUMN "public"."cleaning_disinfection_items"."uses_detergent" IS 'DEFAULT TRUE: Assume detergent was used unless explicitly unchecked.';



COMMENT ON COLUMN "public"."cleaning_disinfection_items"."uses_other_product" IS 'DEFAULT TRUE: Assume other products were used unless explicitly unchecked.';



CREATE TABLE IF NOT EXISTS "public"."cleaning_disinfections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "coop_module_id" "uuid" NOT NULL,
    "cleaning_date" "date" NOT NULL,
    "cleaning_types" "text"[] NOT NULL,
    "general_observations" "text",
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "cleaning_disinfections_types_chk" CHECK (cleaning_types <@ ARRAY['daily','general','deep']::text[] AND array_length(cleaning_types, 1) > 0),
    CONSTRAINT "cleaning_disinfections_module_date_key" UNIQUE (coop_module_id, cleaning_date)
);


ALTER TABLE "public"."cleaning_disinfections" OWNER TO "postgres";


COMMENT ON TABLE "public"."cleaning_disinfections" IS 'Parent table for cleaning and disinfection sessions. One record per module per day. cleaning_types stores which types were performed (daily, general, deep).';



COMMENT ON COLUMN "public"."cleaning_disinfections"."general_observations" IS 'Optional general observations about the entire cleaning session.';



CREATE TABLE IF NOT EXISTS "public"."coop_modules" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(255) NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "is_active" boolean DEFAULT true,
    "default_density" double precision DEFAULT 1.08
);


ALTER TABLE "public"."coop_modules" OWNER TO "postgres";


COMMENT ON TABLE "public"."coop_modules" IS 'Work areas/modules available within each cooperative for organizing business activities';



COMMENT ON COLUMN "public"."coop_modules"."name" IS 'Name of the work area/module (e.g., Production, Sales, Inventory)';



COMMENT ON COLUMN "public"."coop_modules"."cooperative_id" IS 'Reference to the cooperative that owns this module';



CREATE TABLE IF NOT EXISTS "public"."cooperatives" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(255) NOT NULL,
    "code" character varying(50) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "is_active" boolean DEFAULT true,
    "cane_density" numeric(5,4) DEFAULT 1.05
);


ALTER TABLE "public"."cooperatives" OWNER TO "postgres";


COMMENT ON TABLE "public"."cooperatives" IS 'Cooperatives table with Norandino and CAES for B2B multi-tenancy';



CREATE TABLE IF NOT EXISTS "public"."environment_inspection_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "environment_inspection_id" "uuid" NOT NULL,
    "area_code" character varying(50) NOT NULL,
    "item_code" character varying(50) NOT NULL,
    "item_description" "text" NOT NULL,
    "condition" "public"."inspection_condition_enum" NOT NULL,
    "corrective_actions" "text",
    "observations" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."environment_inspection_items" OWNER TO "postgres";


COMMENT ON TABLE "public"."environment_inspection_items" IS 'Individual checklist items for environment inspections';



COMMENT ON COLUMN "public"."environment_inspection_items"."area_code" IS 'Code identifying the inspection area (e.g., reception_milling, thermal_treatment)';



COMMENT ON COLUMN "public"."environment_inspection_items"."item_code" IS 'Code identifying the specific item within the area (e.g., walls, floors, personnel)';



COMMENT ON COLUMN "public"."environment_inspection_items"."condition" IS 'Inspection result: compliant or non_compliant';



COMMENT ON COLUMN "public"."environment_inspection_items"."corrective_actions" IS 'Required corrective actions when item is non-compliant';



COMMENT ON COLUMN "public"."environment_inspection_items"."observations" IS 'Additional observations about the item';



CREATE TABLE IF NOT EXISTS "public"."environment_inspections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "coop_module_id" "uuid" NOT NULL,
    "inspection_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "created_by" character varying(8) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."environment_inspections" OWNER TO "postgres";


COMMENT ON TABLE "public"."environment_inspections" IS 'Tracks environment, equipment, and personnel inspection reports';



COMMENT ON COLUMN "public"."environment_inspections"."coop_module_id" IS 'Reference to the cooperative module being inspected';



COMMENT ON COLUMN "public"."environment_inspections"."inspection_date" IS 'Date when the inspection was performed';



CREATE TABLE IF NOT EXISTS "public"."equipment_maintenance_records" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "coop_module_id" "uuid" NOT NULL,
    "maintenance_date" "date" NOT NULL,
    "equipment_name" "text" NOT NULL,
    "maintenance_type" "text" NOT NULL,
    "maintenance_cause" "text" NOT NULL,
    "materials_used" "text",
    "duration_hours" numeric(10,2) NOT NULL,
    "responsible_person" "text" NOT NULL,
    "created_by" character varying(8) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "equipment_maintenance_records_duration_hours_check" CHECK (("duration_hours" > (0)::numeric)),
    CONSTRAINT "equipment_maintenance_records_maintenance_type_check" CHECK (("maintenance_type" = ANY (ARRAY['P'::"text", 'C'::"text"])))
);


ALTER TABLE "public"."equipment_maintenance_records" OWNER TO "postgres";


COMMENT ON TABLE "public"."equipment_maintenance_records" IS 'Registros de mantenimiento de hornilla, maquinaria y equipos. Basado en formulario COOP-MP-RE-BPM-09.';



COMMENT ON COLUMN "public"."equipment_maintenance_records"."id" IS 'Identificador único del registro de mantenimiento';



COMMENT ON COLUMN "public"."equipment_maintenance_records"."cooperative_id" IS 'ID de la cooperativa a la que pertenece el registro';



COMMENT ON COLUMN "public"."equipment_maintenance_records"."coop_module_id" IS 'ID del módulo donde se realizó el mantenimiento';



COMMENT ON COLUMN "public"."equipment_maintenance_records"."maintenance_date" IS 'Fecha en que se realizó el mantenimiento';



COMMENT ON COLUMN "public"."equipment_maintenance_records"."equipment_name" IS 'Nombre del equipo, maquinaria u hornilla (ej: Trapiche, Motor, Hornilla)';



COMMENT ON COLUMN "public"."equipment_maintenance_records"."maintenance_type" IS 'Tipo de mantenimiento: P (Preventivo) o C (Correctivo)';



COMMENT ON COLUMN "public"."equipment_maintenance_records"."maintenance_cause" IS 'Descripción de la causa o razón del mantenimiento';



COMMENT ON COLUMN "public"."equipment_maintenance_records"."materials_used" IS 'Materiales y repuestos utilizados durante el mantenimiento (opcional)';



COMMENT ON COLUMN "public"."equipment_maintenance_records"."duration_hours" IS 'Duración del mantenimiento en horas (puede ser decimal, ej: 4.5)';



COMMENT ON COLUMN "public"."equipment_maintenance_records"."responsible_person" IS 'Nombre de la persona responsable que realizó el mantenimiento';



COMMENT ON COLUMN "public"."equipment_maintenance_records"."created_by" IS 'ID del usuario que creó el registro (auto-poblado por trigger)';



COMMENT ON COLUMN "public"."equipment_maintenance_records"."created_at" IS 'Fecha y hora de creación del registro';



COMMENT ON COLUMN "public"."equipment_maintenance_records"."updated_at" IS 'Fecha y hora de última actualización del registro';



CREATE TABLE IF NOT EXISTS "public"."form_configurations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cooperative_id" "uuid",
    "step_key" "text" NOT NULL,
    "fields" "jsonb" NOT NULL DEFAULT '[]'::"jsonb",
    "is_active" boolean DEFAULT true NOT NULL,
    "version" integer DEFAULT 1 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."form_configurations" OWNER TO "postgres";


COMMENT ON TABLE "public"."form_configurations" IS 'Configuracion de campos de formulario por paso y cooperativa. cooperative_id NULL = config global para todas.';

COMMENT ON COLUMN "public"."form_configurations"."step_key" IS 'Identificador del formulario: calidad, contenedor, despacho, checklist_limpieza, etc.';
COMMENT ON COLUMN "public"."form_configurations"."fields" IS 'Array JSON de definiciones de campo: [{key, label, type, required, options, min, max, default, order}]';
COMMENT ON COLUMN "public"."form_configurations"."cooperative_id" IS 'NULL = aplica a todas las cooperativas. UUID = override para cooperativa especifica.';


CREATE TABLE IF NOT EXISTS "public"."exit_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "exit_registration_id" "uuid" NOT NULL,
    "production_batch_id" "uuid" NOT NULL,
    "quantity_kg" numeric(10,2) NOT NULL,
    "is_autoconsumo" boolean DEFAULT false NOT NULL,
    "bags_count" numeric(10,2) DEFAULT 0,
    "unit_price" numeric(10,2) DEFAULT 0,
    "total_value" numeric(12,2) GENERATED ALWAYS AS (("quantity_kg" * "unit_price")) STORED,
    "notes" "text",
    "cooperative_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "item_document_number" character varying(100),
    CONSTRAINT "exit_items_bags_count_check" CHECK (("bags_count" >= (0)::numeric)),
    CONSTRAINT "exit_items_quantity_kg_check" CHECK (("quantity_kg" > (0)::numeric)),
    CONSTRAINT "exit_items_unit_price_check" CHECK (("unit_price" >= (0)::numeric))
);


ALTER TABLE "public"."exit_items" OWNER TO "postgres";


COMMENT ON TABLE "public"."exit_items" IS 'Individual items within each exit registration';



COMMENT ON COLUMN "public"."exit_items"."quantity_kg" IS 'Quantity in kilograms for this item';



COMMENT ON COLUMN "public"."exit_items"."is_autoconsumo" IS 'Whether this item is for autoconsumo (true) or regular sale (false)';



COMMENT ON COLUMN "public"."exit_items"."bags_count" IS 'Number of bags (for non-autoconsumo items, 0 for autoconsumo)';



COMMENT ON COLUMN "public"."exit_items"."unit_price" IS 'Price per kilogram';



COMMENT ON COLUMN "public"."exit_items"."total_value" IS 'Total value (quantity_kg * unit_price)';



COMMENT ON COLUMN "public"."exit_items"."item_document_number" IS 'Optional receipt/voucher number for this specific exit item (acopio comprobante)';



CREATE TABLE IF NOT EXISTS "public"."exit_reception_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "exit_reception_id" "uuid" NOT NULL,
    "exit_item_id" "uuid" NOT NULL,
    "quantity_kg_sent" numeric(10,2) NOT NULL,
    "quantity_kg_received" numeric(10,2) NOT NULL,
    "discrepancy_kg" numeric(10,2) GENERATED ALWAYS AS (("quantity_kg_sent" - "quantity_kg_received")) STORED,
    "discrepancy_reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "exit_reception_items_quantity_kg_received_check" CHECK (("quantity_kg_received" >= (0)::numeric))
);


ALTER TABLE "public"."exit_reception_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."exit_receptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "exit_registration_id" "uuid" NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "received_by" "uuid" NOT NULL,
    "received_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "notes" "text",
    "status" character varying(20) DEFAULT 'recepcionado'::character varying NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "exit_receptions_status_check" CHECK ((("status")::"text" = ANY ((ARRAY['recepcionado'::character varying, 'rechazado'::character varying])::"text"[])))
);


ALTER TABLE "public"."exit_receptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."exit_registrations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "exit_code" character varying(50) NOT NULL,
    "document_number" character varying(100),
    "exit_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "total_kg" numeric(10,2) DEFAULT 0 NOT NULL,
    "exit_type" character varying(50) DEFAULT 'SALIDA'::character varying NOT NULL,
    "destination" character varying(100),
    "notes" "text",
    "cooperative_id" "uuid" NOT NULL,
    "created_by" character varying(8) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "exit_registrations_exit_type_check" CHECK ((("exit_type")::"text" = ANY ((ARRAY['SALIDA'::character varying, 'AJUSTE'::character varying, 'MERMA'::character varying])::"text"[]))),
    CONSTRAINT "exit_registrations_total_kg_check" CHECK (("total_kg" >= (0)::numeric))
);


ALTER TABLE "public"."exit_registrations" OWNER TO "postgres";


COMMENT ON TABLE "public"."exit_registrations" IS 'Tracks outbound movements from inventory';



COMMENT ON COLUMN "public"."exit_registrations"."exit_code" IS 'Unique code for the exit (auto-generated)';



COMMENT ON COLUMN "public"."exit_registrations"."document_number" IS 'External document number (guía de remisión)';



COMMENT ON COLUMN "public"."exit_registrations"."total_kg" IS 'Total weight of the exit in kilograms';



COMMENT ON COLUMN "public"."exit_registrations"."exit_type" IS 'Type of exit: SALIDA, AJUSTE, MERMA';



COMMENT ON COLUMN "public"."exit_registrations"."destination" IS 'Where the product is going (Norandino, etc.)';



CREATE TABLE IF NOT EXISTS "public"."health_incidents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "coop_module_id" "uuid" NOT NULL,
    "employee_name" "text" NOT NULL,
    "work_area" "text" NOT NULL,
    "registration_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "symptoms_description" "text" NOT NULL,
    "action_rest" boolean DEFAULT false NOT NULL,
    "action_medical_attention" boolean DEFAULT false NOT NULL,
    "action_relocation" boolean DEFAULT false NOT NULL,
    "action_medication" boolean DEFAULT false NOT NULL,
    "action_other" boolean DEFAULT false NOT NULL,
    "other_action_detail" "text",
    "return_date" "date",
    "certificate_presented" boolean DEFAULT false NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "created_by" character varying(8) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."health_incidents" OWNER TO "postgres";


COMMENT ON TABLE "public"."health_incidents" IS 'Tracks health incidents and accidents for employees with follow-up information';



COMMENT ON COLUMN "public"."health_incidents"."coop_module_id" IS 'Reference to the cooperative module where incident occurred';



COMMENT ON COLUMN "public"."health_incidents"."employee_name" IS 'Name of the affected employee';



COMMENT ON COLUMN "public"."health_incidents"."work_area" IS 'Free text description of work area where incident occurred';



COMMENT ON COLUMN "public"."health_incidents"."registration_date" IS 'Date when the incident was registered';



COMMENT ON COLUMN "public"."health_incidents"."symptoms_description" IS 'Description of symptoms or injuries presented';



COMMENT ON COLUMN "public"."health_incidents"."action_rest" IS 'Whether rest was taken as action';



COMMENT ON COLUMN "public"."health_incidents"."action_medical_attention" IS 'Whether medical attention was provided';



COMMENT ON COLUMN "public"."health_incidents"."action_relocation" IS 'Whether employee was relocated';



COMMENT ON COLUMN "public"."health_incidents"."action_medication" IS 'Whether medication was administered';



COMMENT ON COLUMN "public"."health_incidents"."action_other" IS 'Whether other action was taken';



COMMENT ON COLUMN "public"."health_incidents"."other_action_detail" IS 'Details when "other" action is selected';



COMMENT ON COLUMN "public"."health_incidents"."return_date" IS 'Date when employee returned to work (optional)';



COMMENT ON COLUMN "public"."health_incidents"."certificate_presented" IS 'Whether medical clearance certificate was presented';



COMMENT ON COLUMN "public"."health_incidents"."created_by" IS 'Module administrator who created the record (auto-populated)';



CREATE TABLE IF NOT EXISTS "public"."inventory_stock" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "production_batch_id" "uuid" NOT NULL,
    "current_kg" numeric(10,2) DEFAULT 0 NOT NULL,
    "reserved_kg" numeric(10,2) DEFAULT 0 NOT NULL,
    "available_kg" numeric(10,2) GENERATED ALWAYS AS (("current_kg" - "reserved_kg")) STORED,
    "cooperative_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "inventory_stock_current_kg_check" CHECK (("current_kg" >= (0)::numeric)),
    CONSTRAINT "inventory_stock_reserved_kg_check" CHECK (("reserved_kg" >= (0)::numeric)),
    CONSTRAINT "valid_reserved_stock" CHECK (("reserved_kg" <= "current_kg"))
);


ALTER TABLE "public"."inventory_stock" OWNER TO "postgres";


COMMENT ON TABLE "public"."inventory_stock" IS 'Tracks current stock levels for each production batch';



COMMENT ON COLUMN "public"."inventory_stock"."current_kg" IS 'Total current stock in kilograms';



COMMENT ON COLUMN "public"."inventory_stock"."reserved_kg" IS 'Stock reserved for pending exits';



COMMENT ON COLUMN "public"."inventory_stock"."available_kg" IS 'Available stock (current - reserved)';



CREATE TABLE IF NOT EXISTS "public"."pest_control_bait_records" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pest_control_id" "uuid" NOT NULL,
    "product_name" "text" NOT NULL,
    "quantity" numeric(10,2) NOT NULL,
    "unit" "text" NOT NULL,
    "bait_stations" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "bait_observations" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "at_least_one_bait_station" CHECK (("jsonb_array_length"("bait_stations") > 0)),
    CONSTRAINT "pest_control_bait_records_quantity_check" CHECK (("quantity" > (0)::numeric))
);


ALTER TABLE "public"."pest_control_bait_records" OWNER TO "postgres";


COMMENT ON TABLE "public"."pest_control_bait_records" IS 'Bait control data with JSONB array of bait stations. Each station tracks if bait was eaten.';



COMMENT ON COLUMN "public"."pest_control_bait_records"."bait_stations" IS 'JSONB array: [{"station_number": 1, "ate": false}, ...]. Tracks bait consumption per station.';



CREATE TABLE IF NOT EXISTS "public"."pest_control_insect_records" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pest_control_id" "uuid" NOT NULL,
    "product_name" "text" NOT NULL,
    "quantity" numeric(10,2) NOT NULL,
    "unit" "text" NOT NULL,
    "insect_data" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "at_least_one_insect_record" CHECK (("jsonb_array_length"("insect_data") > 0)),
    CONSTRAINT "pest_control_insect_records_quantity_check" CHECK (("quantity" > (0)::numeric))
);


ALTER TABLE "public"."pest_control_insect_records" OWNER TO "postgres";


COMMENT ON TABLE "public"."pest_control_insect_records" IS 'Insect control data with JSONB array of insect counts by type and area.';



COMMENT ON COLUMN "public"."pest_control_insect_records"."insect_data" IS 'JSONB array: [{"flies": 0, "bees": 1, "ants": 0, "cockroaches": 0, "area": "TT - TEA", "observations": "..."}, ...]. Tracks insect counts by type and location.';



CREATE TABLE IF NOT EXISTS "public"."pest_controls" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "coop_module_id" "uuid" NOT NULL,
    "control_date" "date" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."pest_controls" OWNER TO "postgres";


COMMENT ON TABLE "public"."pest_controls" IS 'Parent table for daily pest control records. One record per module per day.';



CREATE TABLE IF NOT EXISTS "public"."plant_batch_processing" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "plant_batch_id" "uuid" NOT NULL,
    "tamizada_kg" numeric(10,3) NOT NULL,
    "descarte_kg" numeric(10,3) NOT NULL,
    "merma_kg" numeric(10,3) NOT NULL,
    "processed_by" "uuid" NOT NULL,
    "processed_at" timestamp with time zone DEFAULT "now"(),
    "cooperative_id" "uuid" NOT NULL,
    CONSTRAINT "chk_pbp_descarte_non_negative" CHECK (("descarte_kg" >= (0)::numeric)),
    CONSTRAINT "chk_pbp_merma_non_negative" CHECK (("merma_kg" >= (0)::numeric)),
    CONSTRAINT "chk_pbp_no_all_zero" CHECK (((("tamizada_kg" + "descarte_kg") + "merma_kg") > (0)::numeric)),
    CONSTRAINT "chk_pbp_tamizada_non_negative" CHECK (("tamizada_kg" >= (0)::numeric))
);


ALTER TABLE "public"."plant_batch_processing" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."plant_checklists" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "plant_batch_id" "uuid" NOT NULL,
    "type" "text" NOT NULL,
    "items" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "general_notes" "text",
    "filled_by" "uuid" NOT NULL,
    "filled_at" timestamp with time zone DEFAULT "now"(),
    "cooperative_id" "uuid" NOT NULL,
    CONSTRAINT "plant_checklists_type_check" CHECK (("type" = ANY (ARRAY['limpieza'::"text", 'mantenimiento_equipos'::"text", 'control_plagas'::"text", 'control_personal'::"text"])))
);


ALTER TABLE "public"."plant_checklists" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."plant_order_checklists" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "uuid" NOT NULL,
    "type" "text" NOT NULL,
    "items" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "general_notes" "text",
    "filled_by" "uuid" NOT NULL,
    "filled_at" timestamp with time zone DEFAULT "now"(),
    "cooperative_id" "uuid" NOT NULL,
    CONSTRAINT "plant_order_checklists_type_check" CHECK (("type" = ANY (ARRAY['limpieza'::"text", 'control_plagas'::"text"])))
);


ALTER TABLE "public"."plant_order_checklists" OWNER TO "postgres";


COMMENT ON TABLE "public"."plant_order_checklists" IS 'Checklists a nivel de orden/jornada (limpieza y control de plagas aplican a la planta, no al lote individual)';


CREATE TABLE IF NOT EXISTS "public"."plant_dispatches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "container_id" "uuid" NOT NULL,
    "dispatch_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "dispatch_code" "text" NOT NULL,
    "loaded_by" "uuid" NOT NULL,
    "verified_by" "uuid",
    "total_loaded_kg" numeric(10,3),
    "seal_verified" boolean DEFAULT false,
    "temperature_at_load" numeric(5,2),
    "humidity_at_load" numeric(5,2),
    "notes" "text",
    "cooperative_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "extra_data" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "public"."plant_dispatches" OWNER TO "postgres";


COMMENT ON TABLE "public"."plant_dispatches" IS 'Registro de despacho/embarque vinculado a un contenedor de exportación';

COMMENT ON COLUMN "public"."plant_dispatches"."dispatch_code" IS 'Código único de despacho';
COMMENT ON COLUMN "public"."plant_dispatches"."loaded_by" IS 'Usuario que supervisó la carga';
COMMENT ON COLUMN "public"."plant_dispatches"."verified_by" IS 'Usuario que verificó el despacho (opcional)';
COMMENT ON COLUMN "public"."plant_dispatches"."seal_verified" IS 'Si el sello de seguridad fue verificado al cerrar';
COMMENT ON COLUMN "public"."plant_dispatches"."temperature_at_load" IS 'Temperatura ambiente al momento de la carga (°C)';
COMMENT ON COLUMN "public"."plant_dispatches"."humidity_at_load" IS 'Humedad relativa al momento de la carga (%)';


CREATE TABLE IF NOT EXISTS "public"."plant_homogenization_inputs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "plant_batch_id" "uuid" NOT NULL,
    "source_exit_item_id" "uuid" NOT NULL,
    "quantity_kg" numeric(10,3) NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "chk_phi_qty_positive" CHECK (("quantity_kg" > (0)::numeric))
);


ALTER TABLE "public"."plant_homogenization_inputs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."plant_orders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_code" "text" NOT NULL,
    "market" "text" NOT NULL,
    "planned_date" "date" NOT NULL,
    "status" "text" DEFAULT 'en_proceso'::"text" NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "total_kg" numeric(10,3),
    "container_id" "uuid",
    "extra_data" "jsonb" DEFAULT '{}'::"jsonb",
    CONSTRAINT "chk_po_market_not_empty" CHECK ((TRIM(BOTH FROM "market") <> ''::"text")),
    CONSTRAINT "chk_po_status_valid" CHECK (("status" = ANY (ARRAY['en_proceso'::"text", 'completado'::"text"])))
);


ALTER TABLE "public"."plant_orders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."plant_containers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "container_number" character varying(20),
    "seal_number" character varying(30),
    "container_size" character varying(10) DEFAULT '20'::character varying,
    "max_capacity_kg" numeric(10,3),
    "booking_number" character varying(50),
    "bill_of_lading" character varying(50),
    "shipping_line" character varying(100),
    "destination_port" character varying(100),
    "departure_date" "date",
    "estimated_arrival" "date",
    "status" "text" DEFAULT 'preparando'::"text" NOT NULL,
    "notes" "text",
    "cooperative_id" "uuid" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "extra_data" "jsonb" DEFAULT '{}'::"jsonb",
    CONSTRAINT "plant_containers_status_check" CHECK (("status" = ANY (ARRAY['preparando'::"text", 'cargado'::"text", 'despachado'::"text", 'en_transito'::"text", 'entregado'::"text"])))
);


ALTER TABLE "public"."plant_containers" OWNER TO "postgres";


COMMENT ON TABLE "public"."plant_containers" IS 'Contenedores de exportación. Cada orden apunta al contenedor que la contiene (plant_orders.container_id).';


COMMENT ON COLUMN "public"."plant_containers"."container_number" IS 'Número del contenedor físico (ej: BLU-1234567)';
COMMENT ON COLUMN "public"."plant_containers"."seal_number" IS 'Número de sello de seguridad';
COMMENT ON COLUMN "public"."plant_containers"."container_size" IS 'Tamaño del contenedor: 20 o 40 (pies)';
COMMENT ON COLUMN "public"."plant_containers"."max_capacity_kg" IS 'Capacidad máxima del contenedor en kg';
COMMENT ON COLUMN "public"."plant_containers"."booking_number" IS 'Número de reserva con la naviera';
COMMENT ON COLUMN "public"."plant_containers"."bill_of_lading" IS 'Conocimiento de embarque (BL)';
COMMENT ON COLUMN "public"."plant_containers"."shipping_line" IS 'Nombre de la naviera';
COMMENT ON COLUMN "public"."plant_containers"."destination_port" IS 'Puerto de destino';


CREATE TABLE IF NOT EXISTS "public"."plant_production_batches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "batch_code" "text" NOT NULL,
    "order_id" "uuid" NOT NULL,
    "brand" "text" NOT NULL,
    "presentation" "text" NOT NULL,
    "unit_weight_kg" numeric(10,3) NOT NULL,
    "planned_quantity" integer NOT NULL,
    "status" "text" DEFAULT 'pendiente_homogenizado'::"text" NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "chk_ppb_brand_not_empty" CHECK ((TRIM(BOTH FROM "brand") <> ''::"text")),
    CONSTRAINT "chk_ppb_planned_qty_positive" CHECK (("planned_quantity" > 0)),
    CONSTRAINT "chk_ppb_presentation_not_empty" CHECK ((TRIM(BOTH FROM "presentation") <> ''::"text")),
    CONSTRAINT "chk_ppb_status_valid" CHECK (("status" = ANY (ARRAY['pendiente_homogenizado'::"text", 'homogenizado'::"text", 'procesado'::"text"]))),
    CONSTRAINT "chk_ppb_unit_weight_positive" CHECK (("unit_weight_kg" > (0)::numeric))
);


ALTER TABLE "public"."plant_production_batches" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_03f07aea_bab1_4924_8df3_cb1143c88b3e"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_03f07aea_bab1_4924_8df3_cb1143c88b3e" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_0861d2d5_bf02_43a5_b5ec_da2aa1d2ef12"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_0861d2d5_bf02_43a5_b5ec_da2aa1d2ef12" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_1c0888c2_721b_473f_b29c_56c136bce99c"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_1c0888c2_721b_473f_b29c_56c136bce99c" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_2f8f7e65_667c_4304_a88c_78276ab50bed"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_2f8f7e65_667c_4304_a88c_78276ab50bed" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_3e92d99c_eaad_46fc_8001_559624013be2"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_3e92d99c_eaad_46fc_8001_559624013be2" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_4416e931_dc7a_4335_9fe6_11b9942415e7"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_4416e931_dc7a_4335_9fe6_11b9942415e7" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_467daa44_b98f_4f2b_acfb_7bfe919e987b"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_467daa44_b98f_4f2b_acfb_7bfe919e987b" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_4e1d14d3_fa84_4514_bafb_de6431059712"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_4e1d14d3_fa84_4514_bafb_de6431059712" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_550e8400_e29b_41d4_a716_446655440001"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_550e8400_e29b_41d4_a716_446655440001" OWNER TO "postgres";


COMMENT ON SEQUENCE "public"."plot_code_seq_550e8400_e29b_41d4_a716_446655440001" IS 'Plot code sequence for Norandino cooperative - synchronized with seed data max value 13';



CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_550e8400_e29b_41d4_a716_446655440002"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_550e8400_e29b_41d4_a716_446655440002" OWNER TO "postgres";


COMMENT ON SEQUENCE "public"."plot_code_seq_550e8400_e29b_41d4_a716_446655440002" IS 'Plot code sequence for CAES cooperative - synchronized with seed data max value 11';



CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_5c1ffcb5_dcc1_4d88_adaf_a1d467a222b0"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_5c1ffcb5_dcc1_4d88_adaf_a1d467a222b0" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_5d8a65f4_19f5_4d41_b156_39b7aeec1555"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_5d8a65f4_19f5_4d41_b156_39b7aeec1555" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_62265d98_7f6d_409a_a522_8ebdd735a1c1"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_62265d98_7f6d_409a_a522_8ebdd735a1c1" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_69cefbe8_603e_4c1c_b37d_2971c16e89be"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_69cefbe8_603e_4c1c_b37d_2971c16e89be" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_6e8f21b3_7187_4735_9e56_69a262cc1b3f"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_6e8f21b3_7187_4735_9e56_69a262cc1b3f" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_71485f07_3b10_4d09_94d9_6352569ae986"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_71485f07_3b10_4d09_94d9_6352569ae986" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_85653e12_c855_4a1d_96b3_4c0e8ba26514"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_85653e12_c855_4a1d_96b3_4c0e8ba26514" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_88bd5093_5bd5_4a0f_9323_a0f27acd3511"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_88bd5093_5bd5_4a0f_9323_a0f27acd3511" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_99be2690_72f0_4cff_9540_7675fe9913d2"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_99be2690_72f0_4cff_9540_7675fe9913d2" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_9cdfa200_7e71_4526_8256_8bccbce564f1"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_9cdfa200_7e71_4526_8256_8bccbce564f1" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_9e44175c_3fc3_4bd8_a778_cf5abe3e2b45"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_9e44175c_3fc3_4bd8_a778_cf5abe3e2b45" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_a0876aac_a532_481f_a31c_b61dd796e078"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_a0876aac_a532_481f_a31c_b61dd796e078" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_b347f253_d11a_4e8b_a65e_3f7498354b3e"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_b347f253_d11a_4e8b_a65e_3f7498354b3e" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_ba0f08df_5a43_4cb1_be28_42e8dde39173"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_ba0f08df_5a43_4cb1_be28_42e8dde39173" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_bad0a93f_317c_4e2f_8176_a3c65753f7e5"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_bad0a93f_317c_4e2f_8176_a3c65753f7e5" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_baf5424c_b5f2_45b9_a471_b75cd44d09a8"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_baf5424c_b5f2_45b9_a471_b75cd44d09a8" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_e5e02cbe_4148_4c78_b8f6_805e446a611e"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_e5e02cbe_4148_4c78_b8f6_805e446a611e" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."plot_code_seq_eb0481df_90fd_4b27_94e2_e7615220fe2f"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."plot_code_seq_eb0481df_90fd_4b27_94e2_e7615220fe2f" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."plots" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" character varying(100),
    "producer_id" "uuid" NOT NULL,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "name" character varying(200) DEFAULT ''::character varying NOT NULL,
    "default_extraction_percentage" numeric(5,2) DEFAULT NULL::numeric,
    "default_cachaza_percentage" numeric(5,2) DEFAULT NULL::numeric,
    CONSTRAINT "plots_default_cachaza_percentage_check" CHECK ((("default_cachaza_percentage" IS NULL) OR (("default_cachaza_percentage" >= (0)::numeric) AND ("default_cachaza_percentage" <= (100)::numeric)))),
    CONSTRAINT "plots_default_extraction_percentage_check" CHECK ((("default_extraction_percentage" IS NULL) OR (("default_extraction_percentage" >= (0)::numeric) AND ("default_extraction_percentage" <= (100)::numeric))))
);


ALTER TABLE "public"."plots" OWNER TO "postgres";


COMMENT ON TABLE "public"."plots" IS 'Agricultural plots belonging to producers within cooperatives';



COMMENT ON COLUMN "public"."plots"."code" IS 'Auto-generated plot code in format DNI-NUMBER (e.g., 12345678-1, 12345678-2) - unique per producer';



COMMENT ON COLUMN "public"."plots"."producer_id" IS 'Reference to the producer who owns this plot';



COMMENT ON COLUMN "public"."plots"."is_active" IS 'Whether the plot record is active';



COMMENT ON COLUMN "public"."plots"."name" IS 'Human-readable name for the plot (e.g., "Parcela Norte", "Campo Principal")';



COMMENT ON COLUMN "public"."plots"."default_extraction_percentage" IS 'Plot-specific default extraction percentage. NULL means use producer defaults.';



COMMENT ON COLUMN "public"."plots"."default_cachaza_percentage" IS 'Plot-specific default cachaza percentage. NULL means use producer defaults.';



CREATE TABLE IF NOT EXISTS "public"."producers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "first_name" character varying(255) NOT NULL,
    "last_name" character varying(255) NOT NULL,
    "dni" character varying(8) NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "coop_module_id" "uuid" NOT NULL,
    "is_member" boolean DEFAULT true NOT NULL,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "appagrop_code" character varying(50),
    "default_extraction_percentage" numeric(5,2) DEFAULT 62.5,
    "default_cachaza_percentage" numeric(5,2) DEFAULT 2.5,
    CONSTRAINT "producers_default_cachaza_percentage_check" CHECK ((("default_cachaza_percentage" >= (0)::numeric) AND ("default_cachaza_percentage" <= (100)::numeric))),
    CONSTRAINT "producers_default_extraction_percentage_check" CHECK ((("default_extraction_percentage" >= (0)::numeric) AND ("default_extraction_percentage" <= (100)::numeric)))
);


ALTER TABLE "public"."producers" OWNER TO "postgres";


COMMENT ON TABLE "public"."producers" IS 'Producers registered within each cooperative';



COMMENT ON COLUMN "public"."producers"."first_name" IS 'Producer first name';



COMMENT ON COLUMN "public"."producers"."last_name" IS 'Producer last name';



COMMENT ON COLUMN "public"."producers"."dni" IS 'National identification number (8 digits)';



COMMENT ON COLUMN "public"."producers"."cooperative_id" IS 'Reference to the cooperative the producer belongs to';



COMMENT ON COLUMN "public"."producers"."coop_module_id" IS 'Reference to the cooperative module/work area';



COMMENT ON COLUMN "public"."producers"."is_member" IS 'Whether the producer is a member (SOCIO) or not (NO SOCIO) of the cooperative';



COMMENT ON COLUMN "public"."producers"."is_active" IS 'Whether the producer record is active';



COMMENT ON COLUMN "public"."producers"."appagrop_code" IS 'APPAGROP identification code - used only by specific cooperatives like Norandino. Duplicates are now allowed within the same cooperative.';



COMMENT ON COLUMN "public"."producers"."default_extraction_percentage" IS 'Producer default extraction percentage (60-65% typical industry range)';



COMMENT ON COLUMN "public"."producers"."default_cachaza_percentage" IS 'Producer default cachaza percentage (2-3% typical industry range)';



CREATE TABLE IF NOT EXISTS "public"."product_returns" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "production_batch_id" "uuid" NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "client_name" "text" NOT NULL,
    "return_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "quantity_kg" numeric NOT NULL,
    "quantity_sacks" integer DEFAULT 0 NOT NULL,
    "return_reason" "text" NOT NULL,
    "observations" "text",
    "created_by" character varying(8) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "product_returns_quantity_kg_check" CHECK (("quantity_kg" > (0)::numeric)),
    CONSTRAINT "product_returns_quantity_sacks_check" CHECK (("quantity_sacks" >= 0))
);


ALTER TABLE "public"."product_returns" OWNER TO "postgres";


COMMENT ON TABLE "public"."product_returns" IS 'Registros de quejas y devoluciones de producto, vinculados a lotes de producción específicos para trazabilidad.';



COMMENT ON COLUMN "public"."product_returns"."id" IS 'Identificador único del registro de devolución';



COMMENT ON COLUMN "public"."product_returns"."production_batch_id" IS 'ID del lote de producción devuelto (para trazabilidad)';



COMMENT ON COLUMN "public"."product_returns"."cooperative_id" IS 'ID de la cooperativa a la que pertenece el registro';



COMMENT ON COLUMN "public"."product_returns"."client_name" IS 'Nombre del cliente que realizó la devolución';



COMMENT ON COLUMN "public"."product_returns"."return_date" IS 'Fecha en que se realizó la devolución (default: hoy)';



COMMENT ON COLUMN "public"."product_returns"."quantity_kg" IS 'Cantidad devuelta en kilogramos';



COMMENT ON COLUMN "public"."product_returns"."quantity_sacks" IS 'Cantidad devuelta en bolsas (0 si es medida en kg directo)';



COMMENT ON COLUMN "public"."product_returns"."return_reason" IS 'Causa o motivo de la devolución (campo obligatorio)';



COMMENT ON COLUMN "public"."product_returns"."observations" IS 'Observaciones adicionales sobre la devolución (opcional)';



COMMENT ON COLUMN "public"."product_returns"."created_by" IS 'ID del usuario que registró la devolución (auto-poblado por trigger)';



COMMENT ON COLUMN "public"."product_returns"."created_at" IS 'Fecha y hora de creación del registro';



COMMENT ON COLUMN "public"."product_returns"."updated_at" IS 'Fecha y hora de última actualización del registro';



CREATE TABLE IF NOT EXISTS "public"."production_batch_certs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "production_batch_id" "uuid" NOT NULL,
    "batch_cert_id" "uuid" NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."production_batch_certs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."production_batches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "batch_code" character varying(255) NOT NULL,
    "harvest_date" "date" NOT NULL,
    "process_date" "date" NOT NULL,
    "cane_kg" numeric(10,2) NOT NULL,
    "juice_liters" numeric(10,2) NOT NULL,
    "efficiency_percentage" numeric(5,2) DEFAULT 0,
    "producer_id" "uuid" NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "plot_id" "uuid",
    "panela_kg" numeric(10,2) DEFAULT 0,
    "confitillo_kg" numeric(10,2) DEFAULT 0,
    "porcentaje_extraccion" numeric(5,2),
    "cachaza_percentage" numeric(5,2),
    "cane_density" numeric(5,4) DEFAULT 1.05,
    "latitude" double precision,
    "longitude" double precision,
    "location_text" text,
    "observations" text,
    "registered_by_user_id" character varying(8),
    CONSTRAINT "production_batches_cachaza_percentage_check" CHECK ((("cachaza_percentage" >= (0)::numeric) AND ("cachaza_percentage" <= (100)::numeric))),
    CONSTRAINT "production_batches_cane_kg_check" CHECK (("cane_kg" > (0)::numeric)),
    CONSTRAINT "production_batches_confitillo_kg_check" CHECK (("confitillo_kg" >= (0)::numeric)),
    CONSTRAINT "production_batches_juice_liters_check" CHECK (("juice_liters" > (0)::numeric)),
    CONSTRAINT "production_batches_panela_kg_check" CHECK (("panela_kg" >= (0)::numeric)),
    CONSTRAINT "production_batches_porcentaje_extraccion_check" CHECK ((("porcentaje_extraccion" >= (0)::numeric) AND ("porcentaje_extraccion" <= (100)::numeric)))
);


ALTER TABLE "public"."production_batches" OWNER TO "postgres";


COMMENT ON TABLE "public"."production_batches" IS 'Production batches table capturing sugar cane processing data including cane (kg), juice (L), panela (kg), and confitillo (kg) quantities';



COMMENT ON COLUMN "public"."production_batches"."cane_kg" IS 'Amount of sugar cane processed in kilograms';



COMMENT ON COLUMN "public"."production_batches"."juice_liters" IS 'Amount of juice extracted in liters';



COMMENT ON COLUMN "public"."production_batches"."efficiency_percentage" IS 'Production efficiency percentage - can be any numeric value without restrictions';



COMMENT ON COLUMN "public"."production_batches"."plot_id" IS 'Reference to the specific plot where production took place (optional)';



COMMENT ON COLUMN "public"."production_batches"."panela_kg" IS 'Amount of panela produced in kilograms';



COMMENT ON COLUMN "public"."production_batches"."confitillo_kg" IS 'Amount of confitillo produced in kilograms';



COMMENT ON COLUMN "public"."production_batches"."porcentaje_extraccion" IS 'Extraction percentage captured from user input - used for process calculations (0-100%)';



CREATE TABLE IF NOT EXISTS "public"."quality_evaluations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "exit_reception_id" "uuid" NOT NULL,
    "exit_item_id" "uuid" NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "evaluated_by" "uuid" NOT NULL,
    "evaluated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "humidity_pct" numeric(5,2),
    "impurities_pct" numeric(5,2),
    "color" character varying(50),
    "sack_condition" character varying(20),
    "appearance" character varying(20),
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "approval_status" character varying(30) DEFAULT NULL,
    "rejection_reason" "text",
    "extra_data" "jsonb" DEFAULT '{}'::"jsonb",
    CONSTRAINT "quality_evaluations_appearance_check" CHECK ((("appearance")::"text" = ANY ((ARRAY['suelta'::character varying, 'seca'::character varying, 'cerosa'::character varying])::"text"[]))),
    CONSTRAINT "quality_evaluations_color_check" CHECK ((("color")::"text" = ANY ((ARRAY['amarillo claro'::character varying, 'amarillo oscuro'::character varying, 'verde'::character varying, 'marron claro'::character varying, 'marron oscuro'::character varying])::"text"[]))),
    CONSTRAINT "quality_evaluations_humidity_pct_check" CHECK ((("humidity_pct" >= (0)::numeric) AND ("humidity_pct" <= (100)::numeric))),
    CONSTRAINT "quality_evaluations_impurities_pct_check" CHECK ((("impurities_pct" >= (0)::numeric) AND ("impurities_pct" <= (100)::numeric))),
    CONSTRAINT "quality_evaluations_sack_condition_check" CHECK ((("sack_condition")::"text" = ANY ((ARRAY['buena'::character varying, 'regular'::character varying, 'mala'::character varying])::"text"[]))),
    CONSTRAINT "quality_evaluations_approval_status_check" CHECK (("approval_status" IS NULL OR ("approval_status")::"text" = ANY ((ARRAY['aprobado'::character varying, 'rechazado'::character varying, 'aprobado_con_observaciones'::character varying])::"text"[])))
);


ALTER TABLE "public"."quality_evaluations" OWNER TO "postgres";


COMMENT ON COLUMN "public"."quality_evaluations"."approval_status" IS 'Estado de aprobación post-evaluación: aprobado, rechazado, aprobado_con_observaciones (NULL = pendiente de aprobación)';
COMMENT ON COLUMN "public"."quality_evaluations"."rejection_reason" IS 'Motivo del rechazo (requerido cuando approval_status = rechazado)';


CREATE TABLE IF NOT EXISTS "public"."stowage_transport_inspections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "exit_registration_id" "uuid" NOT NULL,
    "inspection_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "carrier_name" "text" NOT NULL,
    "carrier_ruc" character varying(11),
    "carrier_license" character varying(20),
    "vehicle_brand" "text" NOT NULL,
    "vehicle_plate" character varying(10) NOT NULL,
    "vehicle_condition" "public"."vehicle_condition_enum" NOT NULL,
    "has_spare_tire" boolean DEFAULT false NOT NULL,
    "has_valid_soat" boolean DEFAULT false NOT NULL,
    "has_technical_review" boolean DEFAULT false NOT NULL,
    "has_first_aid_kit" boolean DEFAULT false NOT NULL,
    "has_fire_extinguisher" boolean DEFAULT false NOT NULL,
    "has_gps" boolean DEFAULT false NOT NULL,
    "has_cleaning_supplies" boolean DEFAULT false NOT NULL,
    "floors_clean" boolean DEFAULT false NOT NULL,
    "walls_clean" boolean DEFAULT false NOT NULL,
    "ceilings_clean" boolean DEFAULT false NOT NULL,
    "no_strange_odors" boolean DEFAULT false NOT NULL,
    "tarp_clean" boolean DEFAULT false NOT NULL,
    "pallets_clean" boolean DEFAULT false NOT NULL,
    "sack_clean_condition" "public"."sack_condition_enum" NOT NULL,
    "sack_tied_condition" "public"."sack_condition_enum" NOT NULL,
    "observations" "text",
    "created_by" character varying(8) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."stowage_transport_inspections" OWNER TO "postgres";


COMMENT ON TABLE "public"."stowage_transport_inspections" IS 'Tracks stowage and transport inspection reports for exit registrations';



COMMENT ON COLUMN "public"."stowage_transport_inspections"."exit_registration_id" IS 'Reference to the exit registration being inspected';



COMMENT ON COLUMN "public"."stowage_transport_inspections"."inspection_date" IS 'Date when the inspection was performed';



COMMENT ON COLUMN "public"."stowage_transport_inspections"."carrier_name" IS 'Name or business name of the carrier/transporter';



COMMENT ON COLUMN "public"."stowage_transport_inspections"."carrier_ruc" IS 'RUC (tax ID) of the carrier';



COMMENT ON COLUMN "public"."stowage_transport_inspections"."carrier_license" IS 'Driver license number';



COMMENT ON COLUMN "public"."stowage_transport_inspections"."vehicle_brand" IS 'Brand/make of the vehicle';



COMMENT ON COLUMN "public"."stowage_transport_inspections"."vehicle_plate" IS 'License plate number of the vehicle';



COMMENT ON COLUMN "public"."stowage_transport_inspections"."vehicle_condition" IS 'Overall vehicle condition: adequate or deficient';



COMMENT ON COLUMN "public"."stowage_transport_inspections"."sack_clean_condition" IS 'Condition of sack cleanliness: good, regular, or bad';



COMMENT ON COLUMN "public"."stowage_transport_inspections"."sack_tied_condition" IS 'Condition of sack tying/sewing: good, regular, or bad';



COMMENT ON COLUMN "public"."stowage_transport_inspections"."observations" IS 'General observations about the inspection';



CREATE TABLE IF NOT EXISTS "public"."user_module_assignments" (
    "user_id" character varying(8) NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "coop_module_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_module_assignments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "user_id" character varying(8) NOT NULL,
    "first_name" character varying(100) NOT NULL,
    "last_name" character varying(100) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "email" character varying(255),
    "auth_user_id" "uuid",
    "cooperative_id" "uuid" NOT NULL,
    "role" "text" DEFAULT 'productor'::"text" NOT NULL,
    "coop_module_id" "uuid",
    "is_support" boolean DEFAULT false,
    CONSTRAINT "users_role_check" CHECK (("role" = ANY (ARRAY['admin_sistema'::"text", 'admin_modulo'::"text", 'tecnico_campo'::"text", 'productor'::"text"])))
);


ALTER TABLE "public"."users" OWNER TO "postgres";


COMMENT ON COLUMN "public"."users"."cooperative_id" IS 'Links user to their cooperative for multi-tenant data isolation';



CREATE TABLE IF NOT EXISTS "public"."web_users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "auth_user_id" "uuid" NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "first_name" character varying(100) NOT NULL,
    "last_name" character varying(100) NOT NULL,
    "role" character varying(50) DEFAULT 'recepcionista'::character varying NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "username" character varying(50) NOT NULL,
    CONSTRAINT "web_users_role_check" CHECK ((("role")::"text" = ANY ((ARRAY['admin_web'::character varying, 'operador'::character varying])::"text"[])))
);


ALTER TABLE "public"."web_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."worker_control_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "worker_control_id" "uuid",
    "worker_name" "text" NOT NULL,
    "uniform_complete" boolean DEFAULT true,
    "no_makeup" boolean DEFAULT true,
    "nails_short_clean" boolean DEFAULT true,
    "nails_no_polish" boolean DEFAULT true,
    "hands_clean" boolean DEFAULT true,
    "no_jewelry" boolean DEFAULT true,
    "hair_covered" boolean DEFAULT true,
    "no_beard" boolean DEFAULT true,
    "no_wounds" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."worker_control_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."worker_controls" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "production_batch_id" "uuid" NOT NULL,
    "worker_name" "text" NOT NULL,
    "work_area" "text" NOT NULL,
    "uniform_complete" boolean DEFAULT true NOT NULL,
    "no_makeup" boolean DEFAULT true NOT NULL,
    "nails_short_clean" boolean DEFAULT true NOT NULL,
    "nails_no_polish" boolean DEFAULT true NOT NULL,
    "hands_clean" boolean DEFAULT true NOT NULL,
    "no_jewelry" boolean DEFAULT true NOT NULL,
    "hair_covered" boolean DEFAULT true NOT NULL,
    "no_beard" boolean DEFAULT true NOT NULL,
    "no_wounds" boolean DEFAULT true NOT NULL,
    "observations" "text",
    "created_by" character varying(8) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "worker_controls_work_area_check" CHECK (("work_area" = ANY (ARRAY['M'::"text", 'H'::"text", 'TT'::"text", 'TEA'::"text", 'rr'::"text"])))
);


ALTER TABLE "public"."worker_controls" OWNER TO "postgres";


COMMENT ON TABLE "public"."worker_controls" IS 'Registros de cumplimiento de higiene y seguridad de trabajadores operarios durante lotes de producción.';



COMMENT ON COLUMN "public"."worker_controls"."id" IS 'Identificador único del registro de control';



COMMENT ON COLUMN "public"."worker_controls"."cooperative_id" IS 'ID de la cooperativa a la que pertenece el registro';



COMMENT ON COLUMN "public"."worker_controls"."production_batch_id" IS 'ID del lote de producción durante el cual se registró el control';



COMMENT ON COLUMN "public"."worker_controls"."worker_name" IS 'Nombre del trabajador operario';



COMMENT ON COLUMN "public"."worker_controls"."work_area" IS 'Área de trabajo: M (Molienda), H (Hornilla), TT (Tratamiento Térmico), TEA (Taller Empaque), rr (Otros)';



COMMENT ON COLUMN "public"."worker_controls"."uniform_complete" IS 'Uso de uniforme completo (default TRUE)';



COMMENT ON COLUMN "public"."worker_controls"."no_makeup" IS 'Rostro sin maquillaje (default TRUE)';



COMMENT ON COLUMN "public"."worker_controls"."nails_short_clean" IS 'Uñas cortas limpias (default TRUE)';



COMMENT ON COLUMN "public"."worker_controls"."nails_no_polish" IS 'Uñas no esmaltadas (default TRUE)';



COMMENT ON COLUMN "public"."worker_controls"."hands_clean" IS 'Manos limpias (default TRUE)';



COMMENT ON COLUMN "public"."worker_controls"."no_jewelry" IS 'Sin joyas, accesorios ni perfume (default TRUE)';



COMMENT ON COLUMN "public"."worker_controls"."hair_covered" IS 'Cabello corto o recogido (default TRUE)';



COMMENT ON COLUMN "public"."worker_controls"."no_beard" IS 'Sin barba (default TRUE)';



COMMENT ON COLUMN "public"."worker_controls"."no_wounds" IS 'Ausencia de heridas y cortes (default TRUE)';



COMMENT ON COLUMN "public"."worker_controls"."observations" IS 'Observaciones adicionales (opcional)';



COMMENT ON COLUMN "public"."worker_controls"."created_by" IS 'ID del usuario que creó el registro (auto-poblado por trigger)';



COMMENT ON COLUMN "public"."worker_controls"."created_at" IS 'Fecha y hora de creación del registro';



COMMENT ON COLUMN "public"."worker_controls"."updated_at" IS 'Fecha y hora de última actualización del registro';



ALTER TABLE ONLY "public"."batch_certs"
    ADD CONSTRAINT "batch_certs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."batch_ph_controls"
    ADD CONSTRAINT "batch_ph_controls_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."batch_temperatures"
    ADD CONSTRAINT "batch_temperatures_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."batch_temperatures"
    ADD CONSTRAINT "batch_temperatures_production_batch_id_sequence_number_key" UNIQUE ("production_batch_id", "sequence_number");



ALTER TABLE ONLY "public"."certificate_exclusion_groups"
    ADD CONSTRAINT "certificate_exclusion_groups_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chlorine_residual_controls"
    ADD CONSTRAINT "chlorine_residual_controls_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cleaning_disinfection_items"
    ADD CONSTRAINT "cleaning_disinfection_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cleaning_disinfections"
    ADD CONSTRAINT "cleaning_disinfections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."coop_modules"
    ADD CONSTRAINT "coop_modules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cooperatives"
    ADD CONSTRAINT "cooperatives_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."cooperatives"
    ADD CONSTRAINT "cooperatives_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."cooperatives"
    ADD CONSTRAINT "cooperatives_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."environment_inspection_items"
    ADD CONSTRAINT "environment_inspection_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."environment_inspections"
    ADD CONSTRAINT "environment_inspections_pkey" PRIMARY KEY ("id");




ALTER TABLE ONLY "public"."equipment_maintenance_records"
    ADD CONSTRAINT "equipment_maintenance_records_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."form_configurations"
    ADD CONSTRAINT "form_configurations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."form_configurations"
    ADD CONSTRAINT "form_configurations_cooperative_step_key" UNIQUE ("cooperative_id", "step_key");



ALTER TABLE ONLY "public"."exit_items"
    ADD CONSTRAINT "exit_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."exit_reception_items"
    ADD CONSTRAINT "exit_reception_items_exit_item_id_key" UNIQUE ("exit_item_id");



ALTER TABLE ONLY "public"."exit_reception_items"
    ADD CONSTRAINT "exit_reception_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."exit_receptions"
    ADD CONSTRAINT "exit_receptions_exit_registration_id_key" UNIQUE ("exit_registration_id");



ALTER TABLE ONLY "public"."exit_receptions"
    ADD CONSTRAINT "exit_receptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."exit_registrations"
    ADD CONSTRAINT "exit_registrations_exit_code_key" UNIQUE ("exit_code");



ALTER TABLE ONLY "public"."exit_registrations"
    ADD CONSTRAINT "exit_registrations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."health_incidents"
    ADD CONSTRAINT "health_incidents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory_stock"
    ADD CONSTRAINT "inventory_stock_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pest_control_bait_records"
    ADD CONSTRAINT "pest_control_bait_records_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pest_control_insect_records"
    ADD CONSTRAINT "pest_control_insect_records_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pest_controls"
    ADD CONSTRAINT "pest_controls_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."plant_batch_processing"
    ADD CONSTRAINT "plant_batch_processing_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."plant_batch_processing"
    ADD CONSTRAINT "plant_batch_processing_plant_batch_id_key" UNIQUE ("plant_batch_id");



ALTER TABLE ONLY "public"."plant_checklists"
    ADD CONSTRAINT "plant_checklists_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."plant_checklists"
    ADD CONSTRAINT "plant_checklists_plant_batch_id_type_key" UNIQUE ("plant_batch_id", "type");



ALTER TABLE ONLY "public"."plant_homogenization_inputs"
    ADD CONSTRAINT "plant_homogenization_inputs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."plant_orders"
    ADD CONSTRAINT "plant_orders_order_code_key" UNIQUE ("order_code");



ALTER TABLE ONLY "public"."plant_orders"
    ADD CONSTRAINT "plant_orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."plant_containers"
    ADD CONSTRAINT "plant_containers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."plant_orders"
    ADD CONSTRAINT "plant_orders_container_id_fkey" FOREIGN KEY ("container_id") REFERENCES "public"."plant_containers"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."plant_order_checklists"
    ADD CONSTRAINT "plant_order_checklists_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."plant_order_checklists"
    ADD CONSTRAINT "plant_order_checklists_order_id_type_key" UNIQUE ("order_id", "type");



ALTER TABLE ONLY "public"."plant_dispatches"
    ADD CONSTRAINT "plant_dispatches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."plant_dispatches"
    ADD CONSTRAINT "plant_dispatches_dispatch_code_key" UNIQUE ("dispatch_code");



ALTER TABLE ONLY "public"."plant_production_batches"
    ADD CONSTRAINT "plant_production_batches_batch_code_key" UNIQUE ("batch_code");



ALTER TABLE ONLY "public"."plant_production_batches"
    ADD CONSTRAINT "plant_production_batches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."plots"
    ADD CONSTRAINT "plots_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."producers"
    ADD CONSTRAINT "producers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."product_returns"
    ADD CONSTRAINT "product_returns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."production_batch_certs"
    ADD CONSTRAINT "production_batch_certs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."production_batch_certs"
    ADD CONSTRAINT "production_batch_certs_production_batch_id_batch_cert_id_key" UNIQUE ("production_batch_id", "batch_cert_id");



ALTER TABLE ONLY "public"."production_batches"
    ADD CONSTRAINT "production_batches_batch_code_key" UNIQUE ("batch_code");



ALTER TABLE ONLY "public"."production_batches"
    ADD CONSTRAINT "production_batches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."quality_evaluations"
    ADD CONSTRAINT "quality_evaluations_exit_item_id_key" UNIQUE ("exit_item_id");



ALTER TABLE ONLY "public"."quality_evaluations"
    ADD CONSTRAINT "quality_evaluations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stowage_transport_inspections"
    ADD CONSTRAINT "stowage_transport_inspections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."batch_certs"
    ADD CONSTRAINT "unique_cert_per_cooperative" UNIQUE ("name", "cooperative_id");



COMMENT ON CONSTRAINT "unique_cert_per_cooperative" ON "public"."batch_certs" IS 'Ensures unique certificate names within each cooperative';



ALTER TABLE ONLY "public"."producers"
    ADD CONSTRAINT "unique_dni_per_module" UNIQUE ("dni", "coop_module_id");



ALTER TABLE ONLY "public"."certificate_exclusion_groups"
    ADD CONSTRAINT "unique_exclusion_group_per_cooperative" UNIQUE ("name", "cooperative_id");



ALTER TABLE ONLY "public"."environment_inspection_items"
    ADD CONSTRAINT "unique_item_per_inspection" UNIQUE ("environment_inspection_id", "area_code", "item_code");






ALTER TABLE ONLY "public"."chlorine_residual_controls"
    ADD CONSTRAINT "unique_module_datetime" UNIQUE ("coop_module_id", "control_date", "control_time");



COMMENT ON CONSTRAINT "unique_module_datetime" ON "public"."chlorine_residual_controls" IS 'Prevents duplicate chlorine control records for the same module on the same date and time.';



ALTER TABLE ONLY "public"."coop_modules"
    ADD CONSTRAINT "unique_module_name_per_cooperative" UNIQUE ("name", "cooperative_id");






ALTER TABLE ONLY "public"."plots"
    ADD CONSTRAINT "unique_plot_name_code_per_producer" UNIQUE ("name", "code", "producer_id");



ALTER TABLE ONLY "public"."inventory_stock"
    ADD CONSTRAINT "unique_stock_per_batch" UNIQUE ("production_batch_id");



ALTER TABLE ONLY "public"."user_module_assignments"
    ADD CONSTRAINT "user_module_assignments_pkey" PRIMARY KEY ("user_id", "cooperative_id", "coop_module_id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_auth_user_id_key" UNIQUE ("auth_user_id");



COMMENT ON CONSTRAINT "users_auth_user_id_key" ON "public"."users" IS 'Each auth.users record maps to exactly one public.users record';



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_email_key" UNIQUE ("email");



COMMENT ON CONSTRAINT "users_email_key" ON "public"."users" IS 'Virtual email must be unique (format: dni.COOPERATIVECODE@dni.local)';



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("user_id", "cooperative_id");



COMMENT ON CONSTRAINT "users_pkey" ON "public"."users" IS 'Composite primary key allows same DNI across different cooperatives';



ALTER TABLE ONLY "public"."web_users"
    ADD CONSTRAINT "web_users_auth_user_id_key" UNIQUE ("auth_user_id");



ALTER TABLE ONLY "public"."web_users"
    ADD CONSTRAINT "web_users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."web_users"
    ADD CONSTRAINT "web_users_username_key" UNIQUE ("username");



ALTER TABLE ONLY "public"."worker_control_items"
    ADD CONSTRAINT "worker_control_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."worker_controls"
    ADD CONSTRAINT "worker_controls_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_batch_certs_active" ON "public"."batch_certs" USING "btree" ("is_active");



CREATE INDEX "idx_batch_certs_cooperative_id" ON "public"."batch_certs" USING "btree" ("cooperative_id");



CREATE INDEX "idx_batch_certs_exclusion_group_id" ON "public"."batch_certs" USING "btree" ("exclusion_group_id");



CREATE INDEX "idx_batch_certs_is_default" ON "public"."batch_certs" USING "btree" ("is_default") WHERE ("is_default" = true);



CREATE INDEX "idx_batch_certs_name" ON "public"."batch_certs" USING "btree" ("name");



CREATE INDEX "idx_batch_ph_controls_cooperative_id" ON "public"."batch_ph_controls" USING "btree" ("cooperative_id");



CREATE INDEX "idx_batch_ph_controls_production_batch_id" ON "public"."batch_ph_controls" USING "btree" ("production_batch_id");



CREATE INDEX "idx_batch_ph_controls_record_date" ON "public"."batch_ph_controls" USING "btree" ("record_date");



CREATE INDEX "idx_batch_temperatures_cooperative_id" ON "public"."batch_temperatures" USING "btree" ("cooperative_id");



CREATE INDEX "idx_batch_temperatures_production_batch_id" ON "public"."batch_temperatures" USING "btree" ("production_batch_id");



CREATE INDEX "idx_batch_temperatures_sequence_number" ON "public"."batch_temperatures" USING "btree" ("production_batch_id", "sequence_number");



CREATE INDEX "idx_certificate_exclusion_groups_active" ON "public"."certificate_exclusion_groups" USING "btree" ("is_active");



CREATE INDEX "idx_certificate_exclusion_groups_cooperative_id" ON "public"."certificate_exclusion_groups" USING "btree" ("cooperative_id");



CREATE INDEX "idx_certificate_exclusion_groups_name" ON "public"."certificate_exclusion_groups" USING "btree" ("name");



CREATE INDEX "idx_chlorine_controls_cooperative" ON "public"."chlorine_residual_controls" USING "btree" ("cooperative_id");



CREATE INDEX "idx_chlorine_controls_created_by" ON "public"."chlorine_residual_controls" USING "btree" ("created_by");



CREATE INDEX "idx_chlorine_controls_date_desc" ON "public"."chlorine_residual_controls" USING "btree" ("control_date" DESC);



CREATE INDEX "idx_chlorine_controls_module" ON "public"."chlorine_residual_controls" USING "btree" ("coop_module_id");



CREATE INDEX "idx_chlorine_controls_module_date" ON "public"."chlorine_residual_controls" USING "btree" ("coop_module_id", "control_date" DESC);



CREATE INDEX "idx_cleaning_disinfections_cooperative" ON "public"."cleaning_disinfections" USING "btree" ("cooperative_id");



CREATE INDEX "idx_cleaning_disinfections_created_by" ON "public"."cleaning_disinfections" USING "btree" ("created_by");



CREATE INDEX "idx_cleaning_disinfections_date_desc" ON "public"."cleaning_disinfections" USING "btree" ("cleaning_date" DESC);



CREATE INDEX "idx_cleaning_disinfections_module" ON "public"."cleaning_disinfections" USING "btree" ("coop_module_id");



CREATE INDEX "idx_cleaning_items_area" ON "public"."cleaning_disinfection_items" USING "btree" ("area_code");



CREATE INDEX "idx_cleaning_items_parent" ON "public"."cleaning_disinfection_items" USING "btree" ("cleaning_disinfection_id");



CREATE INDEX "idx_cleaning_items_uses_chlorine" ON "public"."cleaning_disinfection_items" USING "btree" ("cleaning_disinfection_id") WHERE ("uses_chlorine" = true);



CREATE INDEX "idx_cleaning_items_uses_detergent" ON "public"."cleaning_disinfection_items" USING "btree" ("cleaning_disinfection_id") WHERE ("uses_detergent" = true);



CREATE INDEX "idx_cleaning_items_uses_other" ON "public"."cleaning_disinfection_items" USING "btree" ("cleaning_disinfection_id") WHERE ("uses_other_product" = true);



CREATE INDEX "idx_coop_modules_active" ON "public"."coop_modules" USING "btree" ("is_active");



CREATE INDEX "idx_coop_modules_cooperative_id" ON "public"."coop_modules" USING "btree" ("cooperative_id");



CREATE INDEX "idx_coop_modules_name_coop" ON "public"."coop_modules" USING "btree" ("name", "cooperative_id");



CREATE INDEX "idx_cooperatives_active" ON "public"."cooperatives" USING "btree" ("is_active");



CREATE INDEX "idx_cooperatives_code" ON "public"."cooperatives" USING "btree" ("code");



CREATE INDEX "idx_environment_inspection_items_area_code" ON "public"."environment_inspection_items" USING "btree" ("area_code");



CREATE INDEX "idx_environment_inspection_items_condition" ON "public"."environment_inspection_items" USING "btree" ("condition");



CREATE INDEX "idx_environment_inspection_items_inspection_id" ON "public"."environment_inspection_items" USING "btree" ("environment_inspection_id");



CREATE INDEX "idx_environment_inspections_cooperative_id" ON "public"."environment_inspections" USING "btree" ("cooperative_id");



CREATE INDEX "idx_environment_inspections_created_by" ON "public"."environment_inspections" USING "btree" ("created_by", "cooperative_id");



CREATE INDEX "idx_environment_inspections_inspection_date" ON "public"."environment_inspections" USING "btree" ("inspection_date");



CREATE INDEX "idx_environment_inspections_module_id" ON "public"."environment_inspections" USING "btree" ("coop_module_id");



CREATE INDEX "idx_equipment_maintenance_cooperative" ON "public"."equipment_maintenance_records" USING "btree" ("cooperative_id");



CREATE INDEX "idx_equipment_maintenance_created_by" ON "public"."equipment_maintenance_records" USING "btree" ("created_by");



CREATE INDEX "idx_equipment_maintenance_date" ON "public"."equipment_maintenance_records" USING "btree" ("maintenance_date" DESC);



CREATE INDEX "idx_equipment_maintenance_module" ON "public"."equipment_maintenance_records" USING "btree" ("coop_module_id");



CREATE INDEX "idx_equipment_maintenance_module_date" ON "public"."equipment_maintenance_records" USING "btree" ("coop_module_id", "maintenance_date" DESC);



CREATE INDEX "idx_equipment_maintenance_type" ON "public"."equipment_maintenance_records" USING "btree" ("maintenance_type");



CREATE INDEX "idx_exit_items_cooperative_id" ON "public"."exit_items" USING "btree" ("cooperative_id");



CREATE INDEX "idx_exit_items_exit_registration_id" ON "public"."exit_items" USING "btree" ("exit_registration_id");



CREATE INDEX "idx_exit_items_is_autoconsumo" ON "public"."exit_items" USING "btree" ("is_autoconsumo");



CREATE INDEX "idx_exit_items_production_batch_id" ON "public"."exit_items" USING "btree" ("production_batch_id");



CREATE INDEX "idx_exit_reception_items_reception" ON "public"."exit_reception_items" USING "btree" ("exit_reception_id");



CREATE INDEX "idx_exit_receptions_cooperative" ON "public"."exit_receptions" USING "btree" ("cooperative_id");



CREATE INDEX "idx_exit_receptions_exit_registration" ON "public"."exit_receptions" USING "btree" ("exit_registration_id");



CREATE INDEX "idx_exit_registrations_cooperative_id" ON "public"."exit_registrations" USING "btree" ("cooperative_id");



CREATE INDEX "idx_exit_registrations_created_by" ON "public"."exit_registrations" USING "btree" ("created_by");



CREATE INDEX "idx_exit_registrations_exit_code" ON "public"."exit_registrations" USING "btree" ("exit_code");



CREATE INDEX "idx_exit_registrations_exit_date" ON "public"."exit_registrations" USING "btree" ("exit_date");



CREATE INDEX "idx_exit_registrations_exit_type" ON "public"."exit_registrations" USING "btree" ("exit_type");



CREATE INDEX "idx_health_incidents_cooperative_id" ON "public"."health_incidents" USING "btree" ("cooperative_id");



CREATE INDEX "idx_health_incidents_created_by" ON "public"."health_incidents" USING "btree" ("created_by", "cooperative_id");



CREATE INDEX "idx_health_incidents_module_id" ON "public"."health_incidents" USING "btree" ("coop_module_id");



CREATE INDEX "idx_health_incidents_registration_date" ON "public"."health_incidents" USING "btree" ("registration_date");



CREATE INDEX "idx_inventory_stock_available_kg" ON "public"."inventory_stock" USING "btree" ("available_kg");



CREATE INDEX "idx_inventory_stock_cooperative_id" ON "public"."inventory_stock" USING "btree" ("cooperative_id");



CREATE INDEX "idx_inventory_stock_production_batch_id" ON "public"."inventory_stock" USING "btree" ("production_batch_id");



CREATE INDEX "idx_pest_bait_records_parent" ON "public"."pest_control_bait_records" USING "btree" ("pest_control_id");



CREATE INDEX "idx_pest_bait_stations_gin" ON "public"."pest_control_bait_records" USING "gin" ("bait_stations");



CREATE INDEX "idx_pest_controls_cooperative" ON "public"."pest_controls" USING "btree" ("cooperative_id");



CREATE INDEX "idx_pest_controls_created_by" ON "public"."pest_controls" USING "btree" ("created_by");



CREATE INDEX "idx_pest_controls_date_desc" ON "public"."pest_controls" USING "btree" ("control_date" DESC);



CREATE INDEX "idx_pest_controls_module" ON "public"."pest_controls" USING "btree" ("coop_module_id");



CREATE INDEX "idx_pest_insect_data_gin" ON "public"."pest_control_insect_records" USING "gin" ("insect_data");



CREATE INDEX "idx_pest_insect_records_parent" ON "public"."pest_control_insect_records" USING "btree" ("pest_control_id");



CREATE INDEX "idx_plots_active" ON "public"."plots" USING "btree" ("is_active");



CREATE INDEX "idx_plots_code" ON "public"."plots" USING "btree" ("code");



CREATE INDEX "idx_plots_code_producer" ON "public"."plots" USING "btree" ("code", "producer_id");



CREATE INDEX "idx_plots_default_cachaza_percentage" ON "public"."plots" USING "btree" ("default_cachaza_percentage");



CREATE INDEX "idx_plots_default_extraction_percentage" ON "public"."plots" USING "btree" ("default_extraction_percentage");



CREATE INDEX "idx_plots_name" ON "public"."plots" USING "btree" ("name");



CREATE INDEX "idx_plots_name_code" ON "public"."plots" USING "btree" ("name", "code");



CREATE INDEX "idx_plots_producer_id" ON "public"."plots" USING "btree" ("producer_id");



CREATE INDEX "idx_producers_active" ON "public"."producers" USING "btree" ("is_active");



CREATE INDEX "idx_producers_appagrop_code" ON "public"."producers" USING "btree" ("appagrop_code");



CREATE INDEX "idx_producers_coop_module_id" ON "public"."producers" USING "btree" ("coop_module_id");



CREATE INDEX "idx_producers_cooperative_id" ON "public"."producers" USING "btree" ("cooperative_id");



CREATE INDEX "idx_producers_default_cachaza_percentage" ON "public"."producers" USING "btree" ("default_cachaza_percentage");



CREATE INDEX "idx_producers_default_extraction_percentage" ON "public"."producers" USING "btree" ("default_extraction_percentage");



CREATE INDEX "idx_producers_dni" ON "public"."producers" USING "btree" ("dni");



CREATE INDEX "idx_producers_full_name" ON "public"."producers" USING "btree" ("first_name", "last_name");



CREATE INDEX "idx_producers_member" ON "public"."producers" USING "btree" ("is_member");



CREATE INDEX "idx_product_returns_coop_date" ON "public"."product_returns" USING "btree" ("cooperative_id", "return_date" DESC);



CREATE INDEX "idx_product_returns_cooperative" ON "public"."product_returns" USING "btree" ("cooperative_id");



CREATE INDEX "idx_product_returns_created_by" ON "public"."product_returns" USING "btree" ("created_by");



CREATE INDEX "idx_product_returns_production_batch" ON "public"."product_returns" USING "btree" ("production_batch_id");



CREATE INDEX "idx_product_returns_return_date" ON "public"."product_returns" USING "btree" ("return_date" DESC);



CREATE INDEX "idx_production_batch_certs_batch_cert_id" ON "public"."production_batch_certs" USING "btree" ("batch_cert_id");



CREATE INDEX "idx_production_batch_certs_cooperative_id" ON "public"."production_batch_certs" USING "btree" ("cooperative_id");



CREATE INDEX "idx_production_batch_certs_production_batch_id" ON "public"."production_batch_certs" USING "btree" ("production_batch_id");



CREATE INDEX "idx_production_batches_batch_code" ON "public"."production_batches" USING "btree" ("batch_code");



CREATE INDEX "idx_production_batches_cachaza_percentage" ON "public"."production_batches" USING "btree" ("cachaza_percentage");



CREATE INDEX "idx_production_batches_confitillo_kg" ON "public"."production_batches" USING "btree" ("confitillo_kg") WHERE ("confitillo_kg" > (0)::numeric);



CREATE INDEX "idx_production_batches_cooperative_id" ON "public"."production_batches" USING "btree" ("cooperative_id");



CREATE INDEX "idx_production_batches_harvest_date" ON "public"."production_batches" USING "btree" ("harvest_date");



CREATE INDEX "idx_production_batches_panela_kg" ON "public"."production_batches" USING "btree" ("panela_kg") WHERE ("panela_kg" > (0)::numeric);



CREATE INDEX "idx_production_batches_plot_id" ON "public"."production_batches" USING "btree" ("plot_id");



CREATE INDEX "idx_production_batches_porcentaje_extraccion" ON "public"."production_batches" USING "btree" ("porcentaje_extraccion") WHERE ("porcentaje_extraccion" IS NOT NULL);



CREATE INDEX "idx_production_batches_process_date" ON "public"."production_batches" USING "btree" ("process_date");



CREATE INDEX "idx_production_batches_producer_id" ON "public"."production_batches" USING "btree" ("producer_id");



CREATE INDEX "idx_quality_evaluations_cooperative" ON "public"."quality_evaluations" USING "btree" ("cooperative_id");



CREATE INDEX "idx_quality_evaluations_reception" ON "public"."quality_evaluations" USING "btree" ("exit_reception_id");



CREATE INDEX "idx_stowage_transport_inspections_cooperative_id" ON "public"."stowage_transport_inspections" USING "btree" ("cooperative_id");



CREATE INDEX "idx_stowage_transport_inspections_created_by" ON "public"."stowage_transport_inspections" USING "btree" ("created_by", "cooperative_id");



CREATE INDEX "idx_stowage_transport_inspections_exit_registration_id" ON "public"."stowage_transport_inspections" USING "btree" ("exit_registration_id");



CREATE INDEX "idx_stowage_transport_inspections_inspection_date" ON "public"."stowage_transport_inspections" USING "btree" ("inspection_date");



CREATE INDEX "idx_user_module_assignments_user" ON "public"."user_module_assignments" USING "btree" ("user_id", "cooperative_id");



CREATE INDEX "idx_users_auth_user_id" ON "public"."users" USING "btree" ("auth_user_id");



CREATE INDEX "idx_users_coop_module_id" ON "public"."users" USING "btree" ("coop_module_id");



CREATE INDEX "idx_users_cooperative_id" ON "public"."users" USING "btree" ("cooperative_id");



CREATE INDEX "idx_users_email" ON "public"."users" USING "btree" ("email");



CREATE INDEX "idx_users_full_name" ON "public"."users" USING "btree" ("first_name", "last_name");



CREATE INDEX "idx_users_user_id" ON "public"."users" USING "btree" ("user_id");



CREATE INDEX "idx_worker_controls_cooperative" ON "public"."worker_controls" USING "btree" ("cooperative_id");



CREATE INDEX "idx_worker_controls_created_at" ON "public"."worker_controls" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_worker_controls_created_by" ON "public"."worker_controls" USING "btree" ("created_by");



CREATE INDEX "idx_worker_controls_production_batch" ON "public"."worker_controls" USING "btree" ("production_batch_id");



CREATE INDEX "idx_worker_controls_work_area" ON "public"."worker_controls" USING "btree" ("work_area");



CREATE OR REPLACE TRIGGER "auto_generate_exit_code_trigger" BEFORE INSERT ON "public"."exit_registrations" FOR EACH ROW EXECUTE FUNCTION "public"."auto_generate_exit_code"();



CREATE OR REPLACE TRIGGER "initialize_stock_trigger" AFTER INSERT ON "public"."production_batches" FOR EACH ROW EXECUTE FUNCTION "public"."initialize_stock_for_batch"();



CREATE OR REPLACE TRIGGER "set_created_by_before_insert" BEFORE INSERT ON "public"."environment_inspections" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_by_from_auth"();



CREATE OR REPLACE TRIGGER "set_created_by_before_insert" BEFORE INSERT ON "public"."health_incidents" FOR EACH ROW EXECUTE FUNCTION "public"."set_health_incident_created_by"();



CREATE OR REPLACE TRIGGER "set_equipment_maintenance_created_by_trigger" BEFORE INSERT ON "public"."equipment_maintenance_records" FOR EACH ROW EXECUTE FUNCTION "public"."set_equipment_maintenance_created_by"();



CREATE OR REPLACE TRIGGER "set_product_returns_created_by_trigger" BEFORE INSERT ON "public"."product_returns" FOR EACH ROW EXECUTE FUNCTION "public"."set_product_returns_created_by"();



CREATE OR REPLACE TRIGGER "set_worker_controls_created_by_trigger" BEFORE INSERT ON "public"."worker_controls" FOR EACH ROW EXECUTE FUNCTION "public"."set_worker_controls_created_by"();



CREATE OR REPLACE TRIGGER "trg_validate_homo_stock" BEFORE INSERT OR UPDATE ON "public"."plant_homogenization_inputs" FOR EACH ROW EXECUTE FUNCTION "public"."validate_homogenization_stock"();



CREATE OR REPLACE TRIGGER "trg_validate_processing" BEFORE INSERT OR UPDATE ON "public"."plant_batch_processing" FOR EACH ROW EXECUTE FUNCTION "public"."validate_processing_totals"();



CREATE OR REPLACE TRIGGER "trigger_auto_assign_plot_code" BEFORE INSERT ON "public"."plots" FOR EACH ROW EXECUTE FUNCTION "public"."auto_assign_plot_code"();



CREATE OR REPLACE TRIGGER "trigger_set_created_by_chlorine" BEFORE INSERT ON "public"."chlorine_residual_controls" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_by_from_auth_chlorine"();



CREATE OR REPLACE TRIGGER "trigger_set_created_by_cleaning" BEFORE INSERT ON "public"."cleaning_disinfections" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_by_from_auth_cleaning"();



CREATE OR REPLACE TRIGGER "trigger_set_created_by_pest" BEFORE INSERT ON "public"."pest_controls" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_by_from_auth_pest"();



CREATE OR REPLACE TRIGGER "trigger_update_chlorine_controls_updated_at" BEFORE UPDATE ON "public"."chlorine_residual_controls" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_update_cleaning_disinfections_updated_at" BEFORE UPDATE ON "public"."cleaning_disinfections" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_update_cleaning_items_updated_at" BEFORE UPDATE ON "public"."cleaning_disinfection_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_update_pest_bait_records_updated_at" BEFORE UPDATE ON "public"."pest_control_bait_records" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_update_pest_controls_updated_at" BEFORE UPDATE ON "public"."pest_controls" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_update_pest_insect_records_updated_at" BEFORE UPDATE ON "public"."pest_control_insect_records" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_batch_certs_updated_at" BEFORE UPDATE ON "public"."batch_certs" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_certificate_exclusion_groups_updated_at" BEFORE UPDATE ON "public"."certificate_exclusion_groups" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_coop_modules_updated_at" BEFORE UPDATE ON "public"."coop_modules" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_cooperatives_updated_at" BEFORE UPDATE ON "public"."cooperatives" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_environment_inspection_items_updated_at" BEFORE UPDATE ON "public"."environment_inspection_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_environment_inspections_updated_at" BEFORE UPDATE ON "public"."environment_inspections" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_equipment_maintenance_updated_at" BEFORE UPDATE ON "public"."equipment_maintenance_records" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_exit_registrations_updated_at" BEFORE UPDATE ON "public"."exit_registrations" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_exit_total_after_delete" AFTER DELETE ON "public"."exit_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_exit_total"();



CREATE OR REPLACE TRIGGER "update_exit_total_after_insert" AFTER INSERT ON "public"."exit_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_exit_total"();



CREATE OR REPLACE TRIGGER "update_exit_total_after_update" AFTER UPDATE ON "public"."exit_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_exit_total"();



CREATE OR REPLACE TRIGGER "update_health_incidents_updated_at" BEFORE UPDATE ON "public"."health_incidents" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_inventory_stock_updated_at" BEFORE UPDATE ON "public"."inventory_stock" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_plot_defaults_trigger" AFTER INSERT ON "public"."production_batches" FOR EACH ROW EXECUTE FUNCTION "public"."update_plot_default_percentages"();



COMMENT ON TRIGGER "update_plot_defaults_trigger" ON "public"."production_batches" IS 'Triggers automatic update of plot default percentages using latest batch values';



CREATE OR REPLACE TRIGGER "update_plots_updated_at" BEFORE UPDATE ON "public"."plots" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_producer_defaults_trigger" AFTER INSERT ON "public"."production_batches" FOR EACH ROW EXECUTE FUNCTION "public"."update_producer_default_percentages"();



COMMENT ON TRIGGER "update_producer_defaults_trigger" ON "public"."production_batches" IS 'Triggers automatic update of producer default percentages using latest batch values';



CREATE OR REPLACE TRIGGER "update_producers_updated_at" BEFORE UPDATE ON "public"."producers" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_product_returns_updated_at" BEFORE UPDATE ON "public"."product_returns" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_production_batches_updated_at" BEFORE UPDATE ON "public"."production_batches" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_stock_after_exit_delete" AFTER DELETE ON "public"."exit_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_stock_after_exit"();



CREATE OR REPLACE TRIGGER "update_stock_after_exit_insert" AFTER INSERT ON "public"."exit_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_stock_after_exit"();



CREATE OR REPLACE TRIGGER "update_stock_after_exit_update" AFTER UPDATE ON "public"."exit_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_stock_after_exit"();



CREATE OR REPLACE TRIGGER "update_stowage_transport_inspections_updated_at" BEFORE UPDATE ON "public"."stowage_transport_inspections" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_users_updated_at" BEFORE UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_worker_controls_updated_at" BEFORE UPDATE ON "public"."worker_controls" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "validate_environment_inspection_trigger" BEFORE INSERT OR UPDATE ON "public"."environment_inspections" FOR EACH ROW EXECUTE FUNCTION "public"."validate_environment_inspection"();



CREATE OR REPLACE TRIGGER "validate_equipment_maintenance_record_trigger" BEFORE INSERT OR UPDATE ON "public"."equipment_maintenance_records" FOR EACH ROW EXECUTE FUNCTION "public"."validate_equipment_maintenance_record"();



CREATE OR REPLACE TRIGGER "validate_exit_item_trigger" BEFORE INSERT OR UPDATE ON "public"."exit_items" FOR EACH ROW EXECUTE FUNCTION "public"."validate_exit_item"();



CREATE OR REPLACE TRIGGER "validate_exit_registration_trigger" BEFORE INSERT OR UPDATE ON "public"."exit_registrations" FOR EACH ROW EXECUTE FUNCTION "public"."validate_exit_registration"();



CREATE OR REPLACE TRIGGER "validate_health_incident_trigger" BEFORE INSERT OR UPDATE ON "public"."health_incidents" FOR EACH ROW EXECUTE FUNCTION "public"."validate_health_incident"();



CREATE OR REPLACE TRIGGER "validate_producer_module_trigger" BEFORE INSERT OR UPDATE ON "public"."producers" FOR EACH ROW EXECUTE FUNCTION "public"."validate_producer_module"();



CREATE OR REPLACE TRIGGER "validate_product_return_trigger" BEFORE INSERT OR UPDATE ON "public"."product_returns" FOR EACH ROW EXECUTE FUNCTION "public"."validate_product_return"();



CREATE OR REPLACE TRIGGER "validate_production_batch_plot_trigger" BEFORE INSERT OR UPDATE ON "public"."production_batches" FOR EACH ROW EXECUTE FUNCTION "public"."validate_production_batch_plot"();



CREATE OR REPLACE TRIGGER "validate_stock_operation_trigger" BEFORE INSERT OR UPDATE ON "public"."inventory_stock" FOR EACH ROW EXECUTE FUNCTION "public"."validate_stock_operation"();



CREATE OR REPLACE TRIGGER "validate_stowage_transport_inspection_trigger" BEFORE INSERT OR UPDATE ON "public"."stowage_transport_inspections" FOR EACH ROW EXECUTE FUNCTION "public"."validate_stowage_transport_inspection"();



CREATE OR REPLACE TRIGGER "validate_worker_control_trigger" BEFORE INSERT OR UPDATE ON "public"."worker_controls" FOR EACH ROW EXECUTE FUNCTION "public"."validate_worker_control"();



ALTER TABLE ONLY "public"."batch_certs"
    ADD CONSTRAINT "batch_certs_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."batch_certs"
    ADD CONSTRAINT "batch_certs_exclusion_group_id_fkey" FOREIGN KEY ("exclusion_group_id") REFERENCES "public"."certificate_exclusion_groups"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."batch_ph_controls"
    ADD CONSTRAINT "batch_ph_controls_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."batch_ph_controls"
    ADD CONSTRAINT "batch_ph_controls_production_batch_id_fkey" FOREIGN KEY ("production_batch_id") REFERENCES "public"."production_batches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."batch_temperatures"
    ADD CONSTRAINT "batch_temperatures_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."batch_temperatures"
    ADD CONSTRAINT "batch_temperatures_production_batch_id_fkey" FOREIGN KEY ("production_batch_id") REFERENCES "public"."production_batches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."certificate_exclusion_groups"
    ADD CONSTRAINT "certificate_exclusion_groups_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."chlorine_residual_controls"
    ADD CONSTRAINT "chlorine_residual_controls_coop_module_id_fkey" FOREIGN KEY ("coop_module_id") REFERENCES "public"."coop_modules"("id");



ALTER TABLE ONLY "public"."chlorine_residual_controls"
    ADD CONSTRAINT "chlorine_residual_controls_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id");



ALTER TABLE ONLY "public"."cleaning_disinfection_items"
    ADD CONSTRAINT "cleaning_disinfection_items_cleaning_disinfection_id_fkey" FOREIGN KEY ("cleaning_disinfection_id") REFERENCES "public"."cleaning_disinfections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cleaning_disinfections"
    ADD CONSTRAINT "cleaning_disinfections_coop_module_id_fkey" FOREIGN KEY ("coop_module_id") REFERENCES "public"."coop_modules"("id");



ALTER TABLE ONLY "public"."cleaning_disinfections"
    ADD CONSTRAINT "cleaning_disinfections_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id");



ALTER TABLE ONLY "public"."coop_modules"
    ADD CONSTRAINT "coop_modules_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."environment_inspection_items"
    ADD CONSTRAINT "environment_inspection_items_environment_inspection_id_fkey" FOREIGN KEY ("environment_inspection_id") REFERENCES "public"."environment_inspections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."environment_inspections"
    ADD CONSTRAINT "environment_inspections_coop_module_id_fkey" FOREIGN KEY ("coop_module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."environment_inspections"
    ADD CONSTRAINT "environment_inspections_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."environment_inspections"
    ADD CONSTRAINT "environment_inspections_created_by_fkey" FOREIGN KEY ("created_by", "cooperative_id") REFERENCES "public"."users"("user_id", "cooperative_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."equipment_maintenance_records"
    ADD CONSTRAINT "equipment_maintenance_records_coop_module_id_fkey" FOREIGN KEY ("coop_module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."equipment_maintenance_records"
    ADD CONSTRAINT "equipment_maintenance_records_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."equipment_maintenance_records"
    ADD CONSTRAINT "equipment_maintenance_records_created_by_fkey" FOREIGN KEY ("created_by", "cooperative_id") REFERENCES "public"."users"("user_id", "cooperative_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."form_configurations"
    ADD CONSTRAINT "form_configurations_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exit_items"
    ADD CONSTRAINT "exit_items_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."exit_items"
    ADD CONSTRAINT "exit_items_exit_registration_id_fkey" FOREIGN KEY ("exit_registration_id") REFERENCES "public"."exit_registrations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exit_items"
    ADD CONSTRAINT "exit_items_production_batch_id_fkey" FOREIGN KEY ("production_batch_id") REFERENCES "public"."production_batches"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."exit_reception_items"
    ADD CONSTRAINT "exit_reception_items_exit_item_id_fkey" FOREIGN KEY ("exit_item_id") REFERENCES "public"."exit_items"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."exit_reception_items"
    ADD CONSTRAINT "exit_reception_items_exit_reception_id_fkey" FOREIGN KEY ("exit_reception_id") REFERENCES "public"."exit_receptions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exit_receptions"
    ADD CONSTRAINT "exit_receptions_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."exit_receptions"
    ADD CONSTRAINT "exit_receptions_exit_registration_id_fkey" FOREIGN KEY ("exit_registration_id") REFERENCES "public"."exit_registrations"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."exit_receptions"
    ADD CONSTRAINT "exit_receptions_received_by_fkey" FOREIGN KEY ("received_by") REFERENCES "public"."web_users"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."exit_registrations"
    ADD CONSTRAINT "exit_registrations_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."exit_registrations"
    ADD CONSTRAINT "exit_registrations_created_by_fkey" FOREIGN KEY ("created_by", "cooperative_id") REFERENCES "public"."users"("user_id", "cooperative_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."health_incidents"
    ADD CONSTRAINT "health_incidents_coop_module_id_fkey" FOREIGN KEY ("coop_module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."health_incidents"
    ADD CONSTRAINT "health_incidents_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."health_incidents"
    ADD CONSTRAINT "health_incidents_created_by_fkey" FOREIGN KEY ("created_by", "cooperative_id") REFERENCES "public"."users"("user_id", "cooperative_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."inventory_stock"
    ADD CONSTRAINT "inventory_stock_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."inventory_stock"
    ADD CONSTRAINT "inventory_stock_production_batch_id_fkey" FOREIGN KEY ("production_batch_id") REFERENCES "public"."production_batches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pest_control_bait_records"
    ADD CONSTRAINT "pest_control_bait_records_pest_control_id_fkey" FOREIGN KEY ("pest_control_id") REFERENCES "public"."pest_controls"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pest_control_insect_records"
    ADD CONSTRAINT "pest_control_insect_records_pest_control_id_fkey" FOREIGN KEY ("pest_control_id") REFERENCES "public"."pest_controls"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pest_controls"
    ADD CONSTRAINT "pest_controls_coop_module_id_fkey" FOREIGN KEY ("coop_module_id") REFERENCES "public"."coop_modules"("id");



ALTER TABLE ONLY "public"."pest_controls"
    ADD CONSTRAINT "pest_controls_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id");



ALTER TABLE ONLY "public"."plant_batch_processing"
    ADD CONSTRAINT "plant_batch_processing_plant_batch_id_fkey" FOREIGN KEY ("plant_batch_id") REFERENCES "public"."plant_production_batches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."plant_checklists"
    ADD CONSTRAINT "plant_checklists_plant_batch_id_fkey" FOREIGN KEY ("plant_batch_id") REFERENCES "public"."plant_production_batches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."plant_homogenization_inputs"
    ADD CONSTRAINT "plant_homogenization_inputs_plant_batch_id_fkey" FOREIGN KEY ("plant_batch_id") REFERENCES "public"."plant_production_batches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."plant_homogenization_inputs"
    ADD CONSTRAINT "plant_homogenization_inputs_source_exit_item_id_fkey" FOREIGN KEY ("source_exit_item_id") REFERENCES "public"."exit_items"("id");



ALTER TABLE ONLY "public"."plant_production_batches"
    ADD CONSTRAINT "plant_production_batches_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."plant_orders"("id") ON DELETE CASCADE;






ALTER TABLE ONLY "public"."plant_order_checklists"
    ADD CONSTRAINT "plant_order_checklists_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."plant_orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."plant_dispatches"
    ADD CONSTRAINT "plant_dispatches_container_id_fkey" FOREIGN KEY ("container_id") REFERENCES "public"."plant_containers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."plots"
    ADD CONSTRAINT "plots_producer_id_fkey" FOREIGN KEY ("producer_id") REFERENCES "public"."producers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."producers"
    ADD CONSTRAINT "producers_coop_module_id_fkey" FOREIGN KEY ("coop_module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."producers"
    ADD CONSTRAINT "producers_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."product_returns"
    ADD CONSTRAINT "product_returns_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."product_returns"
    ADD CONSTRAINT "product_returns_created_by_fkey" FOREIGN KEY ("created_by", "cooperative_id") REFERENCES "public"."users"("user_id", "cooperative_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."product_returns"
    ADD CONSTRAINT "product_returns_production_batch_id_fkey" FOREIGN KEY ("production_batch_id") REFERENCES "public"."production_batches"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."production_batch_certs"
    ADD CONSTRAINT "production_batch_certs_batch_cert_id_fkey" FOREIGN KEY ("batch_cert_id") REFERENCES "public"."batch_certs"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."production_batch_certs"
    ADD CONSTRAINT "production_batch_certs_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."production_batch_certs"
    ADD CONSTRAINT "production_batch_certs_production_batch_id_fkey" FOREIGN KEY ("production_batch_id") REFERENCES "public"."production_batches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."production_batches"
    ADD CONSTRAINT "production_batches_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."production_batches"
    ADD CONSTRAINT "production_batches_plot_id_fkey" FOREIGN KEY ("plot_id") REFERENCES "public"."plots"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."production_batches"
    ADD CONSTRAINT "production_batches_producer_id_fkey" FOREIGN KEY ("producer_id") REFERENCES "public"."producers"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."quality_evaluations"
    ADD CONSTRAINT "quality_evaluations_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."quality_evaluations"
    ADD CONSTRAINT "quality_evaluations_evaluated_by_fkey" FOREIGN KEY ("evaluated_by") REFERENCES "public"."web_users"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."quality_evaluations"
    ADD CONSTRAINT "quality_evaluations_exit_item_id_fkey" FOREIGN KEY ("exit_item_id") REFERENCES "public"."exit_items"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."quality_evaluations"
    ADD CONSTRAINT "quality_evaluations_exit_reception_id_fkey" FOREIGN KEY ("exit_reception_id") REFERENCES "public"."exit_receptions"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."stowage_transport_inspections"
    ADD CONSTRAINT "stowage_transport_inspections_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."stowage_transport_inspections"
    ADD CONSTRAINT "stowage_transport_inspections_created_by_fkey" FOREIGN KEY ("created_by", "cooperative_id") REFERENCES "public"."users"("user_id", "cooperative_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."stowage_transport_inspections"
    ADD CONSTRAINT "stowage_transport_inspections_exit_registration_id_fkey" FOREIGN KEY ("exit_registration_id") REFERENCES "public"."exit_registrations"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."user_module_assignments"
    ADD CONSTRAINT "user_module_assignments_coop_module_id_fkey" FOREIGN KEY ("coop_module_id") REFERENCES "public"."coop_modules"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_module_assignments"
    ADD CONSTRAINT "user_module_assignments_user_id_cooperative_id_fkey" FOREIGN KEY ("user_id", "cooperative_id") REFERENCES "public"."users"("user_id", "cooperative_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_auth_user_id_fkey" FOREIGN KEY ("auth_user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_coop_module_id_fkey" FOREIGN KEY ("coop_module_id") REFERENCES "public"."coop_modules"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id");



ALTER TABLE ONLY "public"."web_users"
    ADD CONSTRAINT "web_users_auth_user_id_fkey" FOREIGN KEY ("auth_user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."web_users"
    ADD CONSTRAINT "web_users_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."worker_control_items"
    ADD CONSTRAINT "worker_control_items_worker_control_id_fkey" FOREIGN KEY ("worker_control_id") REFERENCES "public"."worker_controls"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."worker_controls"
    ADD CONSTRAINT "worker_controls_cooperative_id_fkey" FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."worker_controls"
    ADD CONSTRAINT "worker_controls_created_by_fkey" FOREIGN KEY ("created_by", "cooperative_id") REFERENCES "public"."users"("user_id", "cooperative_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."worker_controls"
    ADD CONSTRAINT "worker_controls_production_batch_id_fkey" FOREIGN KEY ("production_batch_id") REFERENCES "public"."production_batches"("id") ON DELETE RESTRICT;







-- =============================================
-- HIGIENE DE PERSONAL (WEB - PLANTA)
-- =============================================

CREATE TABLE IF NOT EXISTS "public"."plant_hygiene_areas" (
    "id"             uuid DEFAULT gen_random_uuid() NOT NULL,
    "cooperative_id" uuid NOT NULL,
    "control_date"   date NOT NULL DEFAULT CURRENT_DATE,
    "area_code"      text NOT NULL,
    "observations"   text,
    "created_by"     uuid NOT NULL,
    "created_at"     timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at"     timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT "plant_hygiene_areas_area_code_check" CHECK (area_code IN ('TH', 'ENV'))
);

ALTER TABLE "public"."plant_hygiene_areas" OWNER TO "postgres";

COMMENT ON TABLE "public"."plant_hygiene_areas" IS 'Registro de higiene de personal por area evaluada (web). TH=Tamizado y Homogenizado, ENV=Envasado. Una fila por area por fecha por cooperativa.';
COMMENT ON COLUMN "public"."plant_hygiene_areas"."area_code" IS 'TH: Tamizado y Homogenizado | ENV: Envasado';
COMMENT ON COLUMN "public"."plant_hygiene_areas"."control_date" IS 'Fecha del registro de higiene. Libre: no esta vinculada obligatoriamente a un lote de envasado.';
COMMENT ON COLUMN "public"."plant_hygiene_areas"."created_by" IS 'web_users.id del usuario web que creo el registro';


CREATE TABLE IF NOT EXISTS "public"."plant_hygiene_workers" (
    "id"              uuid DEFAULT gen_random_uuid() NOT NULL,
    "hygiene_area_id" uuid NOT NULL,
    "cooperative_id"  uuid NOT NULL,
    "worker_name"     text NOT NULL,
    "created_at"      timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE "public"."plant_hygiene_workers" OWNER TO "postgres";

COMMENT ON TABLE "public"."plant_hygiene_workers" IS 'Trabajador evaluado dentro de un area de higiene. Una fila por trabajador por area.';
COMMENT ON COLUMN "public"."plant_hygiene_workers"."worker_name" IS 'Nombre del trabajador ingresado manualmente';


CREATE TABLE IF NOT EXISTS "public"."plant_hygiene_worker_criteria" (
    "id"         uuid DEFAULT gen_random_uuid() NOT NULL,
    "worker_id"  uuid NOT NULL,
    "item_code"  text NOT NULL,
    "complies"   boolean NOT NULL DEFAULT true,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT "plant_hygiene_worker_criteria_item_code_check" CHECK (item_code IN (
        'vestimenta_adecuada',
        'sin_maquillaje',
        'unas_cortas_limpias',
        'sin_joyas',
        'cabello_corto',
        'cabello_recogido',
        'afeitado',
        'sin_heridas_expuestas'
    ))
);

ALTER TABLE "public"."plant_hygiene_worker_criteria" OWNER TO "postgres";

COMMENT ON TABLE "public"."plant_hygiene_worker_criteria" IS 'Criterio de higiene evaluado por trabajador. TH: vestimenta_adecuada, sin_maquillaje, unas_cortas_limpias, sin_joyas. ENV: cabello_corto, cabello_recogido, afeitado, sin_heridas_expuestas.';
COMMENT ON COLUMN "public"."plant_hygiene_worker_criteria"."item_code" IS 'TH: vestimenta_adecuada | sin_maquillaje | unas_cortas_limpias | sin_joyas — ENV: cabello_corto | cabello_recogido | afeitado | sin_heridas_expuestas';
COMMENT ON COLUMN "public"."plant_hygiene_worker_criteria"."complies" IS 'TRUE = cumple, FALSE = no cumple';


-- Primary keys
ALTER TABLE ONLY "public"."plant_hygiene_areas"
    ADD CONSTRAINT "plant_hygiene_areas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."plant_hygiene_workers"
    ADD CONSTRAINT "plant_hygiene_workers_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."plant_hygiene_worker_criteria"
    ADD CONSTRAINT "plant_hygiene_worker_criteria_pkey" PRIMARY KEY ("id");


-- Unique constraints
ALTER TABLE ONLY "public"."plant_hygiene_areas"
    ADD CONSTRAINT "plant_hygiene_areas_cooperative_date_area_key"
    UNIQUE ("cooperative_id", "control_date", "area_code");

ALTER TABLE ONLY "public"."plant_hygiene_worker_criteria"
    ADD CONSTRAINT "plant_hygiene_worker_criteria_worker_item_key"
    UNIQUE ("worker_id", "item_code");


-- Indexes
CREATE INDEX "idx_plant_hygiene_areas_coop_date"
    ON "public"."plant_hygiene_areas" USING btree ("cooperative_id", "control_date" DESC);

CREATE INDEX "idx_plant_hygiene_areas_created_by"
    ON "public"."plant_hygiene_areas" USING btree ("created_by");

CREATE INDEX "idx_plant_hygiene_workers_area"
    ON "public"."plant_hygiene_workers" USING btree ("hygiene_area_id");

CREATE INDEX "idx_plant_hygiene_worker_criteria_worker"
    ON "public"."plant_hygiene_worker_criteria" USING btree ("worker_id");


-- Foreign keys
ALTER TABLE ONLY "public"."plant_hygiene_areas"
    ADD CONSTRAINT "plant_hygiene_areas_cooperative_id_fkey"
    FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;

ALTER TABLE ONLY "public"."plant_hygiene_areas"
    ADD CONSTRAINT "plant_hygiene_areas_created_by_fkey"
    FOREIGN KEY ("created_by") REFERENCES "public"."web_users"("id") ON DELETE RESTRICT;

ALTER TABLE ONLY "public"."plant_hygiene_workers"
    ADD CONSTRAINT "plant_hygiene_workers_hygiene_area_id_fkey"
    FOREIGN KEY ("hygiene_area_id") REFERENCES "public"."plant_hygiene_areas"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."plant_hygiene_workers"
    ADD CONSTRAINT "plant_hygiene_workers_cooperative_id_fkey"
    FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;

ALTER TABLE ONLY "public"."plant_hygiene_worker_criteria"
    ADD CONSTRAINT "plant_hygiene_worker_criteria_worker_id_fkey"
    FOREIGN KEY ("worker_id") REFERENCES "public"."plant_hygiene_workers"("id") ON DELETE CASCADE;


ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."auto_assign_plot_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."auto_assign_plot_code"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."auto_assign_plot_code"() TO "service_role";



GRANT ALL ON FUNCTION "public"."auto_generate_exit_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."auto_generate_exit_code"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."auto_generate_exit_code"() TO "service_role";



GRANT ALL ON FUNCTION "public"."create_auth_user_for_dni"("dni" character varying, "user_password" "text", "user_email" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_auth_user_for_dni"("dni" character varying, "user_password" "text", "user_email" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_auth_user_for_dni"("dni" character varying, "user_password" "text", "user_email" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_auth_user_for_dni"("dni" character varying, "user_password" "text", "cooperative_id" "uuid", "user_email" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_auth_user_for_dni"("dni" character varying, "user_password" "text", "cooperative_id" "uuid", "user_email" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_auth_user_for_dni"("dni" character varying, "user_password" "text", "cooperative_id" "uuid", "user_email" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_exit_code"("coop_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."generate_exit_code"("coop_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_exit_code"("coop_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_plot_code"("producer_id_param" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."generate_plot_code"("producer_id_param" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_plot_code"("producer_id_param" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_cooperative_code"("coop_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_cooperative_code"("coop_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_cooperative_code"("coop_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_next_plot_code"("producer_id_param" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_next_plot_code"("producer_id_param" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_next_plot_code"("producer_id_param" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."initialize_stock_for_batch"() TO "anon";
GRANT ALL ON FUNCTION "public"."initialize_stock_for_batch"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."initialize_stock_for_batch"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_created_by_from_auth"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_created_by_from_auth"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_created_by_from_auth"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_created_by_from_auth_chlorine"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_created_by_from_auth_chlorine"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_created_by_from_auth_chlorine"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_created_by_from_auth_cleaning"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_created_by_from_auth_cleaning"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_created_by_from_auth_cleaning"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_created_by_from_auth_pest"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_created_by_from_auth_pest"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_created_by_from_auth_pest"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_equipment_maintenance_created_by"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_equipment_maintenance_created_by"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_equipment_maintenance_created_by"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_health_incident_created_by"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_health_incident_created_by"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_health_incident_created_by"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_product_returns_created_by"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_product_returns_created_by"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_product_returns_created_by"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_worker_controls_created_by"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_worker_controls_created_by"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_worker_controls_created_by"() TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_dni_user_auth"("dni" character varying, "user_password" "text", "user_email" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_dni_user_auth"("dni" character varying, "user_password" "text", "user_email" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_dni_user_auth"("dni" character varying, "user_password" "text", "user_email" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_dni_user_auth"("dni" character varying, "user_password" "text", "cooperative_id" "uuid", "user_email" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_dni_user_auth"("dni" character varying, "user_password" "text", "cooperative_id" "uuid", "user_email" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_dni_user_auth"("dni" character varying, "user_password" "text", "cooperative_id" "uuid", "user_email" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_exit_total"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_exit_total"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_exit_total"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_plot_default_percentages"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_plot_default_percentages"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_plot_default_percentages"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_producer_default_percentages"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_producer_default_percentages"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_producer_default_percentages"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_stock_after_exit"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_stock_after_exit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_stock_after_exit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."user_belongs_to_cooperative"("coop_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."user_belongs_to_cooperative"("coop_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."user_belongs_to_cooperative"("coop_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_certificate_exclusion_groups"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_certificate_exclusion_groups"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_certificate_exclusion_groups"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_environment_inspection"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_environment_inspection"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_environment_inspection"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_equipment_maintenance_record"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_equipment_maintenance_record"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_equipment_maintenance_record"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_exit_item"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_exit_item"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_exit_item"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_exit_registration"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_exit_registration"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_exit_registration"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_health_incident"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_health_incident"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_health_incident"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_homogenization_stock"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_homogenization_stock"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_homogenization_stock"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_processing_totals"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_processing_totals"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_processing_totals"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_producer_module"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_producer_module"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_producer_module"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_product_return"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_product_return"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_product_return"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_production_batch_plot"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_production_batch_plot"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_production_batch_plot"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_stock_operation"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_stock_operation"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_stock_operation"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_stowage_transport_inspection"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_stowage_transport_inspection"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_stowage_transport_inspection"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_worker_control"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_worker_control"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_worker_control"() TO "service_role";


















-- VIEWS: Se crearán en security.sql después del seed



GRANT ALL ON TABLE "public"."batch_certs" TO "anon";
GRANT ALL ON TABLE "public"."batch_certs" TO "authenticated";
GRANT ALL ON TABLE "public"."batch_certs" TO "service_role";



GRANT ALL ON TABLE "public"."batch_ph_controls" TO "anon";
GRANT ALL ON TABLE "public"."batch_ph_controls" TO "authenticated";
GRANT ALL ON TABLE "public"."batch_ph_controls" TO "service_role";



GRANT ALL ON TABLE "public"."batch_temperatures" TO "anon";
GRANT ALL ON TABLE "public"."batch_temperatures" TO "authenticated";
GRANT ALL ON TABLE "public"."batch_temperatures" TO "service_role";



GRANT ALL ON TABLE "public"."certificate_exclusion_groups" TO "anon";
GRANT ALL ON TABLE "public"."certificate_exclusion_groups" TO "authenticated";
GRANT ALL ON TABLE "public"."certificate_exclusion_groups" TO "service_role";



GRANT ALL ON TABLE "public"."chlorine_residual_controls" TO "anon";
GRANT ALL ON TABLE "public"."chlorine_residual_controls" TO "authenticated";
GRANT ALL ON TABLE "public"."chlorine_residual_controls" TO "service_role";



GRANT ALL ON TABLE "public"."cleaning_disinfection_items" TO "anon";
GRANT ALL ON TABLE "public"."cleaning_disinfection_items" TO "authenticated";
GRANT ALL ON TABLE "public"."cleaning_disinfection_items" TO "service_role";



GRANT ALL ON TABLE "public"."cleaning_disinfections" TO "anon";
GRANT ALL ON TABLE "public"."cleaning_disinfections" TO "authenticated";
GRANT ALL ON TABLE "public"."cleaning_disinfections" TO "service_role";



GRANT ALL ON TABLE "public"."coop_modules" TO "anon";
GRANT ALL ON TABLE "public"."coop_modules" TO "authenticated";
GRANT ALL ON TABLE "public"."coop_modules" TO "service_role";



GRANT ALL ON TABLE "public"."cooperatives" TO "anon";
GRANT ALL ON TABLE "public"."cooperatives" TO "authenticated";
GRANT ALL ON TABLE "public"."cooperatives" TO "service_role";



GRANT ALL ON TABLE "public"."environment_inspection_items" TO "anon";
GRANT ALL ON TABLE "public"."environment_inspection_items" TO "authenticated";
GRANT ALL ON TABLE "public"."environment_inspection_items" TO "service_role";



GRANT ALL ON TABLE "public"."environment_inspections" TO "anon";
GRANT ALL ON TABLE "public"."environment_inspections" TO "authenticated";
GRANT ALL ON TABLE "public"."environment_inspections" TO "service_role";



GRANT ALL ON TABLE "public"."equipment_maintenance_records" TO "anon";
GRANT ALL ON TABLE "public"."equipment_maintenance_records" TO "authenticated";
GRANT ALL ON TABLE "public"."equipment_maintenance_records" TO "service_role";



GRANT ALL ON TABLE "public"."form_configurations" TO "anon";
GRANT ALL ON TABLE "public"."form_configurations" TO "authenticated";
GRANT ALL ON TABLE "public"."form_configurations" TO "service_role";



GRANT ALL ON TABLE "public"."exit_items" TO "anon";
GRANT ALL ON TABLE "public"."exit_items" TO "authenticated";
GRANT ALL ON TABLE "public"."exit_items" TO "service_role";



GRANT ALL ON TABLE "public"."exit_reception_items" TO "anon";
GRANT ALL ON TABLE "public"."exit_reception_items" TO "authenticated";
GRANT ALL ON TABLE "public"."exit_reception_items" TO "service_role";



GRANT ALL ON TABLE "public"."exit_receptions" TO "anon";
GRANT ALL ON TABLE "public"."exit_receptions" TO "authenticated";
GRANT ALL ON TABLE "public"."exit_receptions" TO "service_role";



GRANT ALL ON TABLE "public"."exit_registrations" TO "anon";
GRANT ALL ON TABLE "public"."exit_registrations" TO "authenticated";
GRANT ALL ON TABLE "public"."exit_registrations" TO "service_role";



GRANT ALL ON TABLE "public"."health_incidents" TO "anon";
GRANT ALL ON TABLE "public"."health_incidents" TO "authenticated";
GRANT ALL ON TABLE "public"."health_incidents" TO "service_role";



GRANT ALL ON TABLE "public"."inventory_stock" TO "anon";
GRANT ALL ON TABLE "public"."inventory_stock" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_stock" TO "service_role";



GRANT ALL ON TABLE "public"."pest_control_bait_records" TO "anon";
GRANT ALL ON TABLE "public"."pest_control_bait_records" TO "authenticated";
GRANT ALL ON TABLE "public"."pest_control_bait_records" TO "service_role";



GRANT ALL ON TABLE "public"."pest_control_insect_records" TO "anon";
GRANT ALL ON TABLE "public"."pest_control_insect_records" TO "authenticated";
GRANT ALL ON TABLE "public"."pest_control_insect_records" TO "service_role";



GRANT ALL ON TABLE "public"."pest_controls" TO "anon";
GRANT ALL ON TABLE "public"."pest_controls" TO "authenticated";
GRANT ALL ON TABLE "public"."pest_controls" TO "service_role";



GRANT ALL ON TABLE "public"."plant_batch_processing" TO "anon";
GRANT ALL ON TABLE "public"."plant_batch_processing" TO "authenticated";
GRANT ALL ON TABLE "public"."plant_batch_processing" TO "service_role";



GRANT ALL ON TABLE "public"."plant_checklists" TO "anon";
GRANT ALL ON TABLE "public"."plant_checklists" TO "authenticated";
GRANT ALL ON TABLE "public"."plant_checklists" TO "service_role";



GRANT ALL ON TABLE "public"."plant_homogenization_inputs" TO "anon";
GRANT ALL ON TABLE "public"."plant_homogenization_inputs" TO "authenticated";
GRANT ALL ON TABLE "public"."plant_homogenization_inputs" TO "service_role";



GRANT ALL ON TABLE "public"."plant_orders" TO "anon";
GRANT ALL ON TABLE "public"."plant_orders" TO "authenticated";
GRANT ALL ON TABLE "public"."plant_orders" TO "service_role";



GRANT ALL ON TABLE "public"."plant_production_batches" TO "anon";
GRANT ALL ON TABLE "public"."plant_production_batches" TO "authenticated";
GRANT ALL ON TABLE "public"."plant_production_batches" TO "service_role";



GRANT ALL ON TABLE "public"."plant_containers" TO "anon";
GRANT ALL ON TABLE "public"."plant_containers" TO "authenticated";
GRANT ALL ON TABLE "public"."plant_containers" TO "service_role";



GRANT ALL ON TABLE "public"."plant_order_checklists" TO "anon";
GRANT ALL ON TABLE "public"."plant_order_checklists" TO "authenticated";
GRANT ALL ON TABLE "public"."plant_order_checklists" TO "service_role";



GRANT ALL ON TABLE "public"."plant_dispatches" TO "anon";
GRANT ALL ON TABLE "public"."plant_dispatches" TO "authenticated";
GRANT ALL ON TABLE "public"."plant_dispatches" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_03f07aea_bab1_4924_8df3_cb1143c88b3e" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_03f07aea_bab1_4924_8df3_cb1143c88b3e" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_03f07aea_bab1_4924_8df3_cb1143c88b3e" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_0861d2d5_bf02_43a5_b5ec_da2aa1d2ef12" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_0861d2d5_bf02_43a5_b5ec_da2aa1d2ef12" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_0861d2d5_bf02_43a5_b5ec_da2aa1d2ef12" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_1c0888c2_721b_473f_b29c_56c136bce99c" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_1c0888c2_721b_473f_b29c_56c136bce99c" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_1c0888c2_721b_473f_b29c_56c136bce99c" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_2f8f7e65_667c_4304_a88c_78276ab50bed" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_2f8f7e65_667c_4304_a88c_78276ab50bed" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_2f8f7e65_667c_4304_a88c_78276ab50bed" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_3e92d99c_eaad_46fc_8001_559624013be2" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_3e92d99c_eaad_46fc_8001_559624013be2" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_3e92d99c_eaad_46fc_8001_559624013be2" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_4416e931_dc7a_4335_9fe6_11b9942415e7" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_4416e931_dc7a_4335_9fe6_11b9942415e7" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_4416e931_dc7a_4335_9fe6_11b9942415e7" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_467daa44_b98f_4f2b_acfb_7bfe919e987b" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_467daa44_b98f_4f2b_acfb_7bfe919e987b" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_467daa44_b98f_4f2b_acfb_7bfe919e987b" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_4e1d14d3_fa84_4514_bafb_de6431059712" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_4e1d14d3_fa84_4514_bafb_de6431059712" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_4e1d14d3_fa84_4514_bafb_de6431059712" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_550e8400_e29b_41d4_a716_446655440001" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_550e8400_e29b_41d4_a716_446655440001" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_550e8400_e29b_41d4_a716_446655440001" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_550e8400_e29b_41d4_a716_446655440002" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_550e8400_e29b_41d4_a716_446655440002" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_550e8400_e29b_41d4_a716_446655440002" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_5c1ffcb5_dcc1_4d88_adaf_a1d467a222b0" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_5c1ffcb5_dcc1_4d88_adaf_a1d467a222b0" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_5c1ffcb5_dcc1_4d88_adaf_a1d467a222b0" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_5d8a65f4_19f5_4d41_b156_39b7aeec1555" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_5d8a65f4_19f5_4d41_b156_39b7aeec1555" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_5d8a65f4_19f5_4d41_b156_39b7aeec1555" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_62265d98_7f6d_409a_a522_8ebdd735a1c1" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_62265d98_7f6d_409a_a522_8ebdd735a1c1" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_62265d98_7f6d_409a_a522_8ebdd735a1c1" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_69cefbe8_603e_4c1c_b37d_2971c16e89be" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_69cefbe8_603e_4c1c_b37d_2971c16e89be" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_69cefbe8_603e_4c1c_b37d_2971c16e89be" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_6e8f21b3_7187_4735_9e56_69a262cc1b3f" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_6e8f21b3_7187_4735_9e56_69a262cc1b3f" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_6e8f21b3_7187_4735_9e56_69a262cc1b3f" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_71485f07_3b10_4d09_94d9_6352569ae986" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_71485f07_3b10_4d09_94d9_6352569ae986" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_71485f07_3b10_4d09_94d9_6352569ae986" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_85653e12_c855_4a1d_96b3_4c0e8ba26514" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_85653e12_c855_4a1d_96b3_4c0e8ba26514" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_85653e12_c855_4a1d_96b3_4c0e8ba26514" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_88bd5093_5bd5_4a0f_9323_a0f27acd3511" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_88bd5093_5bd5_4a0f_9323_a0f27acd3511" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_88bd5093_5bd5_4a0f_9323_a0f27acd3511" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_99be2690_72f0_4cff_9540_7675fe9913d2" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_99be2690_72f0_4cff_9540_7675fe9913d2" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_99be2690_72f0_4cff_9540_7675fe9913d2" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_9cdfa200_7e71_4526_8256_8bccbce564f1" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_9cdfa200_7e71_4526_8256_8bccbce564f1" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_9cdfa200_7e71_4526_8256_8bccbce564f1" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_9e44175c_3fc3_4bd8_a778_cf5abe3e2b45" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_9e44175c_3fc3_4bd8_a778_cf5abe3e2b45" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_9e44175c_3fc3_4bd8_a778_cf5abe3e2b45" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_a0876aac_a532_481f_a31c_b61dd796e078" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_a0876aac_a532_481f_a31c_b61dd796e078" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_a0876aac_a532_481f_a31c_b61dd796e078" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_b347f253_d11a_4e8b_a65e_3f7498354b3e" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_b347f253_d11a_4e8b_a65e_3f7498354b3e" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_b347f253_d11a_4e8b_a65e_3f7498354b3e" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_ba0f08df_5a43_4cb1_be28_42e8dde39173" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_ba0f08df_5a43_4cb1_be28_42e8dde39173" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_ba0f08df_5a43_4cb1_be28_42e8dde39173" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_bad0a93f_317c_4e2f_8176_a3c65753f7e5" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_bad0a93f_317c_4e2f_8176_a3c65753f7e5" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_bad0a93f_317c_4e2f_8176_a3c65753f7e5" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_baf5424c_b5f2_45b9_a471_b75cd44d09a8" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_baf5424c_b5f2_45b9_a471_b75cd44d09a8" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_baf5424c_b5f2_45b9_a471_b75cd44d09a8" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_e5e02cbe_4148_4c78_b8f6_805e446a611e" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_e5e02cbe_4148_4c78_b8f6_805e446a611e" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_e5e02cbe_4148_4c78_b8f6_805e446a611e" TO "service_role";



GRANT ALL ON SEQUENCE "public"."plot_code_seq_eb0481df_90fd_4b27_94e2_e7615220fe2f" TO "anon";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_eb0481df_90fd_4b27_94e2_e7615220fe2f" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."plot_code_seq_eb0481df_90fd_4b27_94e2_e7615220fe2f" TO "service_role";



GRANT ALL ON TABLE "public"."plots" TO "anon";
GRANT ALL ON TABLE "public"."plots" TO "authenticated";
GRANT ALL ON TABLE "public"."plots" TO "service_role";



GRANT ALL ON TABLE "public"."producers" TO "anon";
GRANT ALL ON TABLE "public"."producers" TO "authenticated";
GRANT ALL ON TABLE "public"."producers" TO "service_role";



GRANT ALL ON TABLE "public"."product_returns" TO "anon";
GRANT ALL ON TABLE "public"."product_returns" TO "authenticated";
GRANT ALL ON TABLE "public"."product_returns" TO "service_role";



GRANT ALL ON TABLE "public"."production_batch_certs" TO "anon";
GRANT ALL ON TABLE "public"."production_batch_certs" TO "authenticated";
GRANT ALL ON TABLE "public"."production_batch_certs" TO "service_role";



GRANT ALL ON TABLE "public"."production_batches" TO "anon";
GRANT ALL ON TABLE "public"."production_batches" TO "authenticated";
GRANT ALL ON TABLE "public"."production_batches" TO "service_role";



GRANT ALL ON TABLE "public"."quality_evaluations" TO "anon";
GRANT ALL ON TABLE "public"."quality_evaluations" TO "authenticated";
GRANT ALL ON TABLE "public"."quality_evaluations" TO "service_role";



GRANT ALL ON TABLE "public"."stowage_transport_inspections" TO "anon";
GRANT ALL ON TABLE "public"."stowage_transport_inspections" TO "authenticated";
GRANT ALL ON TABLE "public"."stowage_transport_inspections" TO "service_role";



GRANT ALL ON TABLE "public"."user_module_assignments" TO "anon";
GRANT ALL ON TABLE "public"."user_module_assignments" TO "authenticated";
GRANT ALL ON TABLE "public"."user_module_assignments" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";



GRANT ALL ON TABLE "public"."web_users" TO "anon";
GRANT ALL ON TABLE "public"."web_users" TO "authenticated";
GRANT ALL ON TABLE "public"."web_users" TO "service_role";



GRANT ALL ON TABLE "public"."worker_control_items" TO "anon";
GRANT ALL ON TABLE "public"."worker_control_items" TO "authenticated";
GRANT ALL ON TABLE "public"."worker_control_items" TO "service_role";



GRANT ALL ON TABLE "public"."worker_controls" TO "anon";
GRANT ALL ON TABLE "public"."worker_controls" TO "authenticated";
GRANT ALL ON TABLE "public"."worker_controls" TO "service_role";









-- ============================================================================
-- FORMATOS DE CONTROL DE PRODUCCIÓN Y MATERIA PRIMA (CAMPO)
-- ============================================================================
-- FORMATOS FCMPTPH: CONTROL DE MATERIA PRIMA, PRODUCCIÓN, pH Y TEMPERATURA
-- Un documento puede cubrir múltiples lotes de campo (para ahorro de papel).
-- En trazabilidad, cada lote muestra su propia data + referencia al código.
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."formatos_control_mp_ph" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "formato_codigo" character varying(30) NOT NULL,
    "cooperative_id" "uuid" NOT NULL,
    "module_id" "uuid" NOT NULL,
    "date_from" "date" NOT NULL,
    "date_to" "date" NOT NULL,
    "emitted_by" "uuid",
    "emitted_by_name" text,
    "emitted_at" timestamp with time zone,
    "approved_at" timestamp with time zone,
    "firmantes" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "status" character varying(20) DEFAULT 'draft' NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "fcmptph_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "fcmptph_formato_codigo_key" UNIQUE ("formato_codigo"),
    CONSTRAINT "fcmptph_status_check" CHECK (("status" IN ('draft', 'emitted')))
);

ALTER TABLE "public"."formatos_control_mp_ph" OWNER TO "postgres";

COMMENT ON TABLE "public"."formatos_control_mp_ph" IS 'Formatos FCMPTPH: control de materia prima, producción, pH y temperatura. Un documento puede cubrir N lotes de campo.';
COMMENT ON COLUMN "public"."formatos_control_mp_ph"."formato_codigo" IS 'Código único: NORA-FCMPTPH-0001 / CAES-FCMPTPH-0001';

-- Lotes de campo incluidos en cada documento FCMPTPH
CREATE TABLE IF NOT EXISTS "public"."formatos_control_mp_ph_lotes" (
    "formato_id" "uuid" NOT NULL,
    "lote_campo_id" "uuid" NOT NULL,
    CONSTRAINT "fcmptph_lotes_pkey" PRIMARY KEY ("formato_id", "lote_campo_id"),
    CONSTRAINT "fcmptph_lotes_formato_fkey" FOREIGN KEY ("formato_id") REFERENCES "public"."formatos_control_mp_ph"("id") ON DELETE CASCADE,
    CONSTRAINT "fcmptph_lotes_lote_fkey" FOREIGN KEY ("lote_campo_id") REFERENCES "public"."production_batches"("id") ON DELETE CASCADE
);

ALTER TABLE "public"."formatos_control_mp_ph_lotes" OWNER TO "postgres";

COMMENT ON TABLE "public"."formatos_control_mp_ph_lotes" IS 'Lotes de campo incluidos en cada documento FCMPTPH';


-- Función trigger: setea registered_by_user_id en production_batches desde auth.uid()
CREATE OR REPLACE FUNCTION "public"."set_registered_by_from_auth"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  SELECT user_id INTO NEW.registered_by_user_id
  FROM users
  WHERE auth_user_id = auth.uid();

  -- Si no se encuentra usuario, no bloquear el insert (puede ser sync offline con service_role)
  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."set_registered_by_from_auth"() OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."set_registered_by_from_auth"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_registered_by_from_auth"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_registered_by_from_auth"() TO "service_role";


-- Trigger: setea registered_by_user_id automáticamente al insertar un lote
CREATE OR REPLACE TRIGGER "set_registered_by_before_insert"
  BEFORE INSERT ON "public"."production_batches"
  FOR EACH ROW EXECUTE FUNCTION "public"."set_registered_by_from_auth"();


-- FK: registered_by_user_id → users(user_id, cooperative_id)
ALTER TABLE ONLY "public"."production_batches"
    DROP CONSTRAINT IF EXISTS "production_batches_registered_by_fkey";
ALTER TABLE ONLY "public"."production_batches"
    ADD CONSTRAINT "production_batches_registered_by_fkey"
    FOREIGN KEY ("registered_by_user_id", "cooperative_id")
    REFERENCES "public"."users"("user_id", "cooperative_id") ON DELETE RESTRICT;


-- Una salida solo puede tener una inspección
ALTER TABLE ONLY "public"."stowage_transport_inspections"
  DROP CONSTRAINT IF EXISTS "stowage_inspections_exit_unique";
ALTER TABLE ONLY "public"."stowage_transport_inspections"
  ADD CONSTRAINT "stowage_inspections_exit_unique" UNIQUE ("exit_registration_id");


-- registered_by_user_id en stowage_transport_inspections (mismo patrón que production_batches)
ALTER TABLE "public"."stowage_transport_inspections"
  ADD COLUMN IF NOT EXISTS "registered_by_user_id" character varying(8);

CREATE OR REPLACE TRIGGER "set_stowage_registered_by_before_insert"
  BEFORE INSERT ON "public"."stowage_transport_inspections"
  FOR EACH ROW EXECUTE FUNCTION "public"."set_registered_by_from_auth"();

ALTER TABLE ONLY "public"."stowage_transport_inspections"
  DROP CONSTRAINT IF EXISTS "stowage_inspections_registered_by_fkey";
ALTER TABLE ONLY "public"."stowage_transport_inspections"
  ADD CONSTRAINT "stowage_inspections_registered_by_fkey"
  FOREIGN KEY ("registered_by_user_id", "cooperative_id")
  REFERENCES "public"."users"("user_id", "cooperative_id") ON DELETE RESTRICT;


-- FKs de formatos_control_mp_ph
ALTER TABLE ONLY "public"."formatos_control_mp_ph"
    ADD CONSTRAINT "fcmptph_cooperative_id_fkey"
    FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;

ALTER TABLE ONLY "public"."formatos_control_mp_ph"
    ADD CONSTRAINT "fcmptph_module_id_fkey"
    FOREIGN KEY ("module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;

-- RPC atómica: genera código FCMPTPH, inserta formato + lotes en una transacción
CREATE OR REPLACE FUNCTION "public"."emit_formato_mp_ph"(
  p_coop_code       text,
  p_cooperative_id  uuid,
  p_module_id       uuid,
  p_date_from       date,
  p_date_to         date,
  p_emitted_by      uuid,
  p_emitted_by_name text,
  p_firmantes       jsonb,
  p_batch_ids       uuid[]
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_next_num   integer;
  v_code       text;
  v_formato_id uuid;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FCMPTPH'));

  SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.formatos_control_mp_ph f
  WHERE f.cooperative_id = p_cooperative_id
    AND f.formato_codigo ~ ('^' || p_coop_code || '-FCMPTPH-[0-9]+$');

  v_code := p_coop_code || '-FCMPTPH-' || LPAD(v_next_num::text, 4, '0');

  INSERT INTO public.formatos_control_mp_ph (
    formato_codigo, cooperative_id, module_id, date_from, date_to,
    emitted_by, emitted_by_name, emitted_at, firmantes, status
  )
  VALUES (
    v_code, p_cooperative_id, p_module_id, p_date_from, p_date_to,
    p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
  )
  RETURNING id INTO v_formato_id;

  INSERT INTO public.formatos_control_mp_ph_lotes (formato_id, lote_campo_id)
  SELECT v_formato_id, unnest(p_batch_ids);

  RETURN jsonb_build_object('formato_codigo', v_code, 'formato_id', v_formato_id);
END;
$$;

ALTER FUNCTION "public"."emit_formato_mp_ph"(text, uuid, uuid, date, date, uuid, text, jsonb, uuid[]) OWNER TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."emit_formato_mp_ph"(text, uuid, uuid, date, date, uuid, text, jsonb, uuid[]) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_mp_ph"(text, uuid, uuid, date, date, uuid, text, jsonb, uuid[]) TO "service_role";


-- GRANTs
GRANT ALL ON TABLE "public"."formatos_control_mp_ph" TO "anon";
GRANT ALL ON TABLE "public"."formatos_control_mp_ph" TO "authenticated";
GRANT ALL ON TABLE "public"."formatos_control_mp_ph" TO "service_role";

GRANT ALL ON TABLE "public"."formatos_control_mp_ph_lotes" TO "anon";
GRANT ALL ON TABLE "public"."formatos_control_mp_ph_lotes" TO "authenticated";
GRANT ALL ON TABLE "public"."formatos_control_mp_ph_lotes" TO "service_role";



-- Columnas de documento para estiba/transporte (ALTER TABLE sobre tabla existente)
ALTER TABLE "public"."stowage_transport_inspections"
  ADD COLUMN IF NOT EXISTS "formato_codigo" character varying(30),
  ADD COLUMN IF NOT EXISTS "emitted_by" "uuid",
  ADD COLUMN IF NOT EXISTS "emitted_by_name" text,
  ADD COLUMN IF NOT EXISTS "emitted_at" timestamp with time zone,
  ADD COLUMN IF NOT EXISTS "firmantes" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
  ADD COLUMN IF NOT EXISTS "status" character varying(20) DEFAULT 'draft' NOT NULL;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sti_formato_codigo_key') THEN
    ALTER TABLE public.stowage_transport_inspections ADD CONSTRAINT sti_formato_codigo_key UNIQUE (formato_codigo);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sti_status_check') THEN
    ALTER TABLE public.stowage_transport_inspections ADD CONSTRAINT sti_status_check CHECK (status IN ('draft', 'emitted'));
  END IF;
END $$;

-- RPC atómica para emitir FET
CREATE OR REPLACE FUNCTION "public"."emit_formato_estiba_transporte"(
  p_coop_code       text,
  p_cooperative_id  uuid,
  p_inspection_id   uuid,
  p_emitted_by      uuid,
  p_emitted_by_name text,
  p_firmantes       jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_next_num integer;
  v_code     text;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FET'));

  SELECT COALESCE(MAX(CAST(SPLIT_PART(s.formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.stowage_transport_inspections s
  WHERE s.cooperative_id = p_cooperative_id
    AND s.formato_codigo ~ ('^' || p_coop_code || '-FET-[0-9]+$');

  v_code := p_coop_code || '-FET-' || LPAD(v_next_num::text, 4, '0');

  UPDATE public.stowage_transport_inspections
  SET formato_codigo  = v_code,
      emitted_by      = p_emitted_by,
      emitted_by_name = p_emitted_by_name,
      emitted_at      = now(),
      firmantes       = p_firmantes,
      status          = 'emitted'
  WHERE id = p_inspection_id;

  RETURN jsonb_build_object('formato_codigo', v_code);
END;
$$;

ALTER FUNCTION "public"."emit_formato_estiba_transporte"(text, uuid, uuid, uuid, text, jsonb) OWNER TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_estiba_transporte"(text, uuid, uuid, uuid, text, jsonb) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_estiba_transporte"(text, uuid, uuid, uuid, text, jsonb) TO "service_role";


-- ── FCCLR: Formato de Control de Cloro Libre Residual ────────────────────────

CREATE TABLE IF NOT EXISTS "public"."formatos_control_cloro" (
    "id"              uuid                     DEFAULT gen_random_uuid() NOT NULL,
    "formato_codigo"  character varying(30),
    "cooperative_id"  uuid                     NOT NULL,
    "module_id"       uuid                     NOT NULL,
    "date_from"       date                     NOT NULL,
    "date_to"         date                     NOT NULL,
    "emitted_by"      uuid,
    "emitted_by_name" text,
    "emitted_at"      timestamp with time zone,
    "firmantes"       jsonb                    DEFAULT '[]'::jsonb NOT NULL,
    "status"          character varying(20)    DEFAULT 'draft' NOT NULL,
    "created_at"      timestamp with time zone DEFAULT now(),
    CONSTRAINT "fccl_pkey"       PRIMARY KEY ("id"),
    CONSTRAINT "fccl_code_key"   UNIQUE ("formato_codigo"),
    CONSTRAINT "fccl_status_chk" CHECK (status IN ('draft', 'emitted'))
);

ALTER TABLE "public"."formatos_control_cloro" OWNER TO "postgres";
COMMENT ON TABLE "public"."formatos_control_cloro" IS 'Formatos FCCLR: control de cloro libre residual por módulo y período.';

ALTER TABLE ONLY "public"."formatos_control_cloro"
    ADD CONSTRAINT "fccl_coop_fkey"
    FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;

ALTER TABLE ONLY "public"."formatos_control_cloro"
    ADD CONSTRAINT "fccl_module_fkey"
    FOREIGN KEY ("module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;

CREATE OR REPLACE FUNCTION "public"."emit_formato_control_cloro"(
    p_coop_code       text,
    p_cooperative_id  uuid,
    p_module_id       uuid,
    p_date_from       date,
    p_date_to         date,
    p_emitted_by      uuid,
    p_emitted_by_name text,
    p_firmantes       jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FCCLR'));

    SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.formatos_control_cloro f
    WHERE f.cooperative_id = p_cooperative_id
      AND f.formato_codigo ~ ('^' || p_coop_code || '-FCCLR-[0-9]+$');

    v_code := p_coop_code || '-FCCLR-' || LPAD(v_next_num::text, 4, '0');

    INSERT INTO public.formatos_control_cloro (
        cooperative_id, module_id, date_from, date_to, formato_codigo,
        emitted_by, emitted_by_name, emitted_at, firmantes, status
    ) VALUES (
        p_cooperative_id, p_module_id, p_date_from, p_date_to, v_code,
        p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
    );

    RETURN jsonb_build_object('formato_codigo', v_code);
END;
$$;

ALTER FUNCTION "public"."emit_formato_control_cloro"(text, uuid, uuid, date, date, uuid, text, jsonb) OWNER TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_control_cloro"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_control_cloro"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "service_role";

GRANT ALL ON TABLE "public"."formatos_control_cloro" TO "anon";
GRANT ALL ON TABLE "public"."formatos_control_cloro" TO "authenticated";
GRANT ALL ON TABLE "public"."formatos_control_cloro" TO "service_role";


-- ── FCPO: Formato de Control de Personal Operario ────────────────────────────

CREATE TABLE IF NOT EXISTS "public"."formatos_control_personal" (
    "id"                  uuid                     DEFAULT gen_random_uuid() NOT NULL,
    "formato_codigo"      character varying(30),
    "cooperative_id"      uuid                     NOT NULL,
    "production_batch_id" uuid                     NOT NULL,
    "emitted_by"          uuid,
    "emitted_by_name"     text,
    "emitted_at"          timestamp with time zone,
    "firmantes"           jsonb                    DEFAULT '[]'::jsonb NOT NULL,
    "status"              character varying(20)    DEFAULT 'draft' NOT NULL,
    "created_at"          timestamp with time zone DEFAULT now(),
    CONSTRAINT "fcpo_pkey"         PRIMARY KEY ("id"),
    CONSTRAINT "fcpo_unique_batch" UNIQUE ("cooperative_id", "production_batch_id"),
    CONSTRAINT "fcpo_codigo_key"   UNIQUE ("formato_codigo"),
    CONSTRAINT "fcpo_status_check" CHECK (status IN ('draft', 'emitted'))
);

ALTER TABLE "public"."formatos_control_personal" OWNER TO "postgres";
COMMENT ON TABLE "public"."formatos_control_personal" IS 'Formatos FCPO: control de personal operario por lote de campo.';

ALTER TABLE ONLY "public"."formatos_control_personal"
    ADD CONSTRAINT "fcpo_cooperative_fkey"
    FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;

ALTER TABLE ONLY "public"."formatos_control_personal"
    ADD CONSTRAINT "fcpo_batch_fkey"
    FOREIGN KEY ("production_batch_id") REFERENCES "public"."production_batches"("id") ON DELETE RESTRICT;

CREATE OR REPLACE FUNCTION "public"."emit_formato_control_personal"(
    p_coop_code       text,
    p_cooperative_id  uuid,
    p_batch_id        uuid,
    p_emitted_by      uuid,
    p_emitted_by_name text,
    p_firmantes       jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FCPO'));

    SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.formatos_control_personal f
    WHERE f.cooperative_id = p_cooperative_id
      AND f.formato_codigo ~ ('^' || p_coop_code || '-FCPO-[0-9]+$');

    v_code := p_coop_code || '-FCPO-' || LPAD(v_next_num::text, 4, '0');

    INSERT INTO public.formatos_control_personal (
        cooperative_id, production_batch_id, formato_codigo,
        emitted_by, emitted_by_name, emitted_at, firmantes, status
    ) VALUES (
        p_cooperative_id, p_batch_id, v_code,
        p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
    )
    ON CONFLICT (cooperative_id, production_batch_id)
    DO UPDATE SET
        formato_codigo  = v_code,
        emitted_by      = p_emitted_by,
        emitted_by_name = p_emitted_by_name,
        emitted_at      = now(),
        firmantes       = p_firmantes,
        status          = 'emitted';

    RETURN jsonb_build_object('formato_codigo', v_code);
END;
$$;

ALTER FUNCTION "public"."emit_formato_control_personal"(text, uuid, uuid, uuid, text, jsonb) OWNER TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_control_personal"(text, uuid, uuid, uuid, text, jsonb) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_control_personal"(text, uuid, uuid, uuid, text, jsonb) TO "service_role";

GRANT ALL ON TABLE "public"."formatos_control_personal" TO "anon";
GRANT ALL ON TABLE "public"."formatos_control_personal" TO "authenticated";
GRANT ALL ON TABLE "public"."formatos_control_personal" TO "service_role";

-- ════════════════════════════════════════════════════════════════════════════
-- FIAE: Formato de Inspección de Ambientes, Equipo y Personal
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS "public"."formatos_inspeccion_ambientes" (
    "id"              uuid                     DEFAULT gen_random_uuid() NOT NULL,
    "formato_codigo"  character varying(30),
    "cooperative_id"  uuid                     NOT NULL,
    "module_id"       uuid                     NOT NULL,
    "inspection_id"   uuid                     NOT NULL,
    "inspection_date" date                     NOT NULL,
    "emitted_by"      uuid,
    "emitted_by_name" text,
    "emitted_at"      timestamp with time zone,
    "firmantes"       jsonb                    DEFAULT '[]'::jsonb NOT NULL,
    "status"          character varying(20)    DEFAULT 'draft' NOT NULL,
    "created_at"      timestamp with time zone DEFAULT now(),
    CONSTRAINT "fiae_pkey"       PRIMARY KEY ("id"),
    CONSTRAINT "fiae_code_key"   UNIQUE ("formato_codigo"),
    CONSTRAINT "fiae_insp_key"   UNIQUE ("inspection_id"),
    CONSTRAINT "fiae_status_chk" CHECK (status IN ('draft', 'emitted'))
);

ALTER TABLE "public"."formatos_inspeccion_ambientes" OWNER TO "postgres";
COMMENT ON TABLE "public"."formatos_inspeccion_ambientes" IS 'Formatos FIAE: inspección de ambientes, equipo y personal, uno por registro de inspección.';

ALTER TABLE ONLY "public"."formatos_inspeccion_ambientes"
    ADD CONSTRAINT "fiae_coop_fkey"
    FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;

ALTER TABLE ONLY "public"."formatos_inspeccion_ambientes"
    ADD CONSTRAINT "fiae_module_fkey"
    FOREIGN KEY ("module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;

ALTER TABLE ONLY "public"."formatos_inspeccion_ambientes"
    ADD CONSTRAINT "fiae_inspection_fkey"
    FOREIGN KEY ("inspection_id") REFERENCES "public"."environment_inspections"("id") ON DELETE RESTRICT;

CREATE OR REPLACE FUNCTION "public"."emit_formato_inspeccion_ambientes"(
    p_coop_code       text,
    p_cooperative_id  uuid,
    p_module_id       uuid,
    p_inspection_id   uuid,
    p_inspection_date date,
    p_emitted_by      uuid,
    p_emitted_by_name text,
    p_firmantes       jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FIAE'));

    SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.formatos_inspeccion_ambientes f
    WHERE f.cooperative_id = p_cooperative_id
      AND f.formato_codigo ~ ('^' || p_coop_code || '-FIAE-[0-9]+$');

    v_code := p_coop_code || '-FIAE-' || LPAD(v_next_num::text, 4, '0');

    INSERT INTO public.formatos_inspeccion_ambientes (
        cooperative_id, module_id, inspection_id, inspection_date, formato_codigo,
        emitted_by, emitted_by_name, emitted_at, firmantes, status
    ) VALUES (
        p_cooperative_id, p_module_id, p_inspection_id, p_inspection_date, v_code,
        p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
    )
    ON CONFLICT (inspection_id)
    DO UPDATE SET
        formato_codigo  = v_code,
        emitted_by      = p_emitted_by,
        emitted_by_name = p_emitted_by_name,
        emitted_at      = now(),
        firmantes       = p_firmantes,
        status          = 'emitted';

    RETURN jsonb_build_object('formato_codigo', v_code);
END;
$$;

ALTER FUNCTION "public"."emit_formato_inspeccion_ambientes"(text, uuid, uuid, uuid, date, uuid, text, jsonb) OWNER TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_inspeccion_ambientes"(text, uuid, uuid, uuid, date, uuid, text, jsonb) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_inspeccion_ambientes"(text, uuid, uuid, uuid, date, uuid, text, jsonb) TO "service_role";

GRANT ALL ON TABLE "public"."formatos_inspeccion_ambientes" TO "anon";
GRANT ALL ON TABLE "public"."formatos_inspeccion_ambientes" TO "authenticated";
GRANT ALL ON TABLE "public"."formatos_inspeccion_ambientes" TO "service_role";

-- ════════════════════════════════════════════════════════════════════════════
-- FCP: Formato de Control de Plagas
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS "public"."formatos_control_plagas" (
    "id"              uuid                     DEFAULT gen_random_uuid() NOT NULL,
    "formato_codigo"  character varying(30),
    "cooperative_id"  uuid                     NOT NULL,
    "module_id"       uuid                     NOT NULL,
    "date_from"       date                     NOT NULL,
    "date_to"         date                     NOT NULL,
    "emitted_by"      uuid,
    "emitted_by_name" text,
    "emitted_at"      timestamp with time zone,
    "firmantes"       jsonb                    DEFAULT '[]'::jsonb NOT NULL,
    "status"          character varying(20)    DEFAULT 'draft' NOT NULL,
    "created_at"      timestamp with time zone DEFAULT now(),
    CONSTRAINT "fcp_pkey"       PRIMARY KEY ("id"),
    CONSTRAINT "fcp_code_key"   UNIQUE ("formato_codigo"),
    CONSTRAINT "fcp_status_chk" CHECK (status IN ('draft', 'emitted'))
);

ALTER TABLE "public"."formatos_control_plagas" OWNER TO "postgres";
COMMENT ON TABLE "public"."formatos_control_plagas" IS 'Formatos FCP: control de plagas por módulo y período.';

ALTER TABLE ONLY "public"."formatos_control_plagas"
    ADD CONSTRAINT "fcp_coop_fkey"
    FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;

ALTER TABLE ONLY "public"."formatos_control_plagas"
    ADD CONSTRAINT "fcp_module_fkey"
    FOREIGN KEY ("module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;

CREATE OR REPLACE FUNCTION "public"."emit_formato_control_plagas"(
    p_coop_code       text,
    p_cooperative_id  uuid,
    p_module_id       uuid,
    p_date_from       date,
    p_date_to         date,
    p_emitted_by      uuid,
    p_emitted_by_name text,
    p_firmantes       jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FCP'));

    SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.formatos_control_plagas f
    WHERE f.cooperative_id = p_cooperative_id
      AND f.formato_codigo ~ ('^' || p_coop_code || '-FCP-[0-9]+$');

    v_code := p_coop_code || '-FCP-' || LPAD(v_next_num::text, 4, '0');

    INSERT INTO public.formatos_control_plagas (
        cooperative_id, module_id, date_from, date_to, formato_codigo,
        emitted_by, emitted_by_name, emitted_at, firmantes, status
    ) VALUES (
        p_cooperative_id, p_module_id, p_date_from, p_date_to, v_code,
        p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
    );

    RETURN jsonb_build_object('formato_codigo', v_code);
END;
$$;

ALTER FUNCTION "public"."emit_formato_control_plagas"(text, uuid, uuid, date, date, uuid, text, jsonb) OWNER TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_control_plagas"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_control_plagas"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "service_role";

GRANT ALL ON TABLE "public"."formatos_control_plagas" TO "anon";
GRANT ALL ON TABLE "public"."formatos_control_plagas" TO "authenticated";
GRANT ALL ON TABLE "public"."formatos_control_plagas" TO "service_role";


-- ════════════════════════════════════════════════════════════════════════════
-- FSEA: Formato de Seguimiento de Enfermedades y Accidentes
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS "public"."formatos_seguimiento_salud" (
    "id"              uuid                     DEFAULT gen_random_uuid() NOT NULL,
    "formato_codigo"  character varying(30),
    "cooperative_id"  uuid                     NOT NULL,
    "module_id"       uuid                     NOT NULL,
    "date_from"       date                     NOT NULL,
    "date_to"         date                     NOT NULL,
    "emitted_by"      uuid,
    "emitted_by_name" text,
    "emitted_at"      timestamp with time zone,
    "firmantes"       jsonb                    DEFAULT '[]'::jsonb NOT NULL,
    "status"          character varying(20)    DEFAULT 'draft' NOT NULL,
    "created_at"      timestamp with time zone DEFAULT now(),
    CONSTRAINT "fsea_pkey"       PRIMARY KEY ("id"),
    CONSTRAINT "fsea_code_key"   UNIQUE ("formato_codigo"),
    CONSTRAINT "fsea_status_chk" CHECK (status IN ('draft', 'emitted'))
);

ALTER TABLE "public"."formatos_seguimiento_salud" OWNER TO "postgres";
COMMENT ON TABLE "public"."formatos_seguimiento_salud" IS 'Formatos FSEA: seguimiento de enfermedades y accidentes por módulo y período.';

ALTER TABLE ONLY "public"."formatos_seguimiento_salud"
    ADD CONSTRAINT "fsea_coop_fkey"
    FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;

ALTER TABLE ONLY "public"."formatos_seguimiento_salud"
    ADD CONSTRAINT "fsea_module_fkey"
    FOREIGN KEY ("module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;

CREATE OR REPLACE FUNCTION "public"."emit_formato_seguimiento_salud"(
    p_coop_code       text,
    p_cooperative_id  uuid,
    p_module_id       uuid,
    p_date_from       date,
    p_date_to         date,
    p_emitted_by      uuid,
    p_emitted_by_name text,
    p_firmantes       jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FSEA'));

    SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.formatos_seguimiento_salud f
    WHERE f.cooperative_id = p_cooperative_id
      AND f.formato_codigo ~ ('^' || p_coop_code || '-FSEA-[0-9]+$');

    v_code := p_coop_code || '-FSEA-' || LPAD(v_next_num::text, 4, '0');

    INSERT INTO public.formatos_seguimiento_salud (
        cooperative_id, module_id, date_from, date_to, formato_codigo,
        emitted_by, emitted_by_name, emitted_at, firmantes, status
    ) VALUES (
        p_cooperative_id, p_module_id, p_date_from, p_date_to, v_code,
        p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
    );

    RETURN jsonb_build_object('formato_codigo', v_code);
END;
$$;

ALTER FUNCTION "public"."emit_formato_seguimiento_salud"(text, uuid, uuid, date, date, uuid, text, jsonb) OWNER TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_seguimiento_salud"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_seguimiento_salud"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "service_role";

GRANT ALL ON TABLE "public"."formatos_seguimiento_salud" TO "anon";
GRANT ALL ON TABLE "public"."formatos_seguimiento_salud" TO "authenticated";
GRANT ALL ON TABLE "public"."formatos_seguimiento_salud" TO "service_role";


-- ════════════════════════════════════════════════════════════════════════════
-- FMEH: Formato de Mantenimiento de Equipos y Hornillas
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS "public"."formatos_mantenimiento_equipos" (
    "id"              uuid                     DEFAULT gen_random_uuid() NOT NULL,
    "formato_codigo"  character varying(30),
    "cooperative_id"  uuid                     NOT NULL,
    "module_id"       uuid                     NOT NULL,
    "date_from"       date                     NOT NULL,
    "date_to"         date                     NOT NULL,
    "emitted_by"      uuid,
    "emitted_by_name" text,
    "emitted_at"      timestamp with time zone,
    "firmantes"       jsonb                    DEFAULT '[]'::jsonb NOT NULL,
    "status"          character varying(20)    DEFAULT 'draft' NOT NULL,
    "created_at"      timestamp with time zone DEFAULT now(),
    CONSTRAINT "fmeh_pkey"       PRIMARY KEY ("id"),
    CONSTRAINT "fmeh_code_key"   UNIQUE ("formato_codigo"),
    CONSTRAINT "fmeh_status_chk" CHECK (status IN ('draft', 'emitted'))
);

ALTER TABLE "public"."formatos_mantenimiento_equipos" OWNER TO "postgres";
COMMENT ON TABLE "public"."formatos_mantenimiento_equipos" IS 'Formatos FMEH: mantenimiento de equipos y hornillas por módulo y período.';

ALTER TABLE ONLY "public"."formatos_mantenimiento_equipos"
    ADD CONSTRAINT "fmeh_coop_fkey"
    FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;

ALTER TABLE ONLY "public"."formatos_mantenimiento_equipos"
    ADD CONSTRAINT "fmeh_module_fkey"
    FOREIGN KEY ("module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;

CREATE OR REPLACE FUNCTION "public"."emit_formato_mantenimiento_equipos"(
    p_coop_code       text,
    p_cooperative_id  uuid,
    p_module_id       uuid,
    p_date_from       date,
    p_date_to         date,
    p_emitted_by      uuid,
    p_emitted_by_name text,
    p_firmantes       jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FMEH'));

    SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.formatos_mantenimiento_equipos f
    WHERE f.cooperative_id = p_cooperative_id
      AND f.formato_codigo ~ ('^' || p_coop_code || '-FMEH-[0-9]+$');

    v_code := p_coop_code || '-FMEH-' || LPAD(v_next_num::text, 4, '0');

    INSERT INTO public.formatos_mantenimiento_equipos (
        cooperative_id, module_id, date_from, date_to, formato_codigo,
        emitted_by, emitted_by_name, emitted_at, firmantes, status
    ) VALUES (
        p_cooperative_id, p_module_id, p_date_from, p_date_to, v_code,
        p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
    );

    RETURN jsonb_build_object('formato_codigo', v_code);
END;
$$;

ALTER FUNCTION "public"."emit_formato_mantenimiento_equipos"(text, uuid, uuid, date, date, uuid, text, jsonb) OWNER TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_mantenimiento_equipos"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_mantenimiento_equipos"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "service_role";

GRANT ALL ON TABLE "public"."formatos_mantenimiento_equipos" TO "anon";
GRANT ALL ON TABLE "public"."formatos_mantenimiento_equipos" TO "authenticated";
GRANT ALL ON TABLE "public"."formatos_mantenimiento_equipos" TO "service_role";


-- ── FLDH: Formato de Limpieza y Desinfección ─────────────────────────────────

CREATE TABLE IF NOT EXISTS "public"."formatos_limpieza_desinfeccion" (
    "id"              uuid                     DEFAULT gen_random_uuid() NOT NULL,
    "formato_codigo"  character varying(30),
    "cooperative_id"  uuid                     NOT NULL,
    "module_id"       uuid                     NOT NULL,
    "date_from"       date                     NOT NULL,
    "date_to"         date                     NOT NULL,
    "emitted_by"      uuid,
    "emitted_by_name" text,
    "emitted_at"      timestamp with time zone,
    "firmantes"       jsonb                    DEFAULT '[]'::jsonb NOT NULL,
    "status"          character varying(20)    DEFAULT 'draft' NOT NULL,
    "created_at"      timestamp with time zone DEFAULT now(),
    CONSTRAINT "fldh_pkey"       PRIMARY KEY ("id"),
    CONSTRAINT "fldh_code_key"   UNIQUE ("formato_codigo"),
    CONSTRAINT "fldh_status_chk" CHECK (status IN ('draft', 'emitted'))
);

ALTER TABLE "public"."formatos_limpieza_desinfeccion" OWNER TO "postgres";
COMMENT ON TABLE "public"."formatos_limpieza_desinfeccion" IS 'Formatos FLDH: limpieza y desinfección por módulo y período.';

ALTER TABLE ONLY "public"."formatos_limpieza_desinfeccion"
    ADD CONSTRAINT "fldh_coop_fkey"
    FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;

ALTER TABLE ONLY "public"."formatos_limpieza_desinfeccion"
    ADD CONSTRAINT "fldh_module_fkey"
    FOREIGN KEY ("module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;

ALTER TABLE "public"."formatos_limpieza_desinfeccion" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "fldh_coop_isolation" ON "public"."formatos_limpieza_desinfeccion"
    FOR ALL USING (cooperative_id = auth_cooperative_id() OR is_service_role());

CREATE OR REPLACE FUNCTION "public"."emit_formato_limpieza_desinfeccion"(
    p_coop_code       text,
    p_cooperative_id  uuid,
    p_module_id       uuid,
    p_date_from       date,
    p_date_to         date,
    p_emitted_by      uuid,
    p_emitted_by_name text,
    p_firmantes       jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FLDH'));

    SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.formatos_limpieza_desinfeccion f
    WHERE f.cooperative_id = p_cooperative_id
      AND f.formato_codigo ~ ('^' || p_coop_code || '-FLDH-[0-9]+$');

    v_code := p_coop_code || '-FLDH-' || LPAD(v_next_num::text, 4, '0');

    INSERT INTO public.formatos_limpieza_desinfeccion (
        cooperative_id, module_id, date_from, date_to, formato_codigo,
        emitted_by, emitted_by_name, emitted_at, firmantes, status
    ) VALUES (
        p_cooperative_id, p_module_id, p_date_from, p_date_to, v_code,
        p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
    );

    RETURN jsonb_build_object('formato_codigo', v_code);
END;
$$;

ALTER FUNCTION "public"."emit_formato_limpieza_desinfeccion"(text, uuid, uuid, date, date, uuid, text, jsonb) OWNER TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_limpieza_desinfeccion"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_limpieza_desinfeccion"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "service_role";

GRANT ALL ON TABLE "public"."formatos_limpieza_desinfeccion" TO "anon";
GRANT ALL ON TABLE "public"."formatos_limpieza_desinfeccion" TO "authenticated";
GRANT ALL ON TABLE "public"."formatos_limpieza_desinfeccion" TO "service_role";


ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































