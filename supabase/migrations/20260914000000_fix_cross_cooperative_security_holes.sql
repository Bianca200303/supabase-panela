-- Corrige 2 hallazgos de la auditoria de seguridad multi-cooperativa (2026-09-14):
--
-- 1) create_auth_user_for_dni / setup_dni_user_auth (ambas sobrecargas):
--    SECURITY DEFINER, sin ningun chequeo de cooperativa/rol, con EXECUTE
--    otorgado a anon/authenticated. Permiten a cualquier llamador (con la
--    clave publica anon) configurar contrasena para CUALQUIER DNI de
--    CUALQUIER cooperativa -- secuestro de cuenta. No se usan desde ninguna
--    pantalla real (confirmado: setupDNIUserAuth en el movil esta definida
--    pero nunca invocada, comentario "admin function"); el bootstrap real
--    de usuarios se hace corriendo real_users_seed.sql manualmente como
--    postgres/service_role, que no depende de estos GRANTs. Se les saca
--    EXECUTE de anon/authenticated, quedan solo para service_role/postgres.
--
-- 2) get_next_plot_code / generate_plot_code (producer_id_param uuid):
--    SECURITY DEFINER, tambien con EXECUTE en anon/authenticated, pero SIN
--    filtrar por cooperativa al buscar el productor -- devuelven el DNI de
--    CUALQUIER productor (de cualquier cooperativa) a partir de su UUID.
--    A diferencia del punto 1, estas SI se usan de verdad (app movil,
--    plot_service.dart, para previsualizar/asignar el codigo de parcela),
--    asi que no se les saca el EXECUTE -- se les agrega el mismo filtro de
--    cooperativa que ya usan las demas generate_*_code (auth_cooperative_id()),
--    reusando el mensaje "Producer not found" tanto para "no existe" como
--    para "es de otra cooperativa" (no revela si el UUID existe en otro
--    tenant).

-- 1) Revocar EXECUTE de anon/authenticated en las 4 firmas.
REVOKE EXECUTE ON FUNCTION public.create_auth_user_for_dni(character varying, text, uuid, text) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.create_auth_user_for_dni(character varying, text, text) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.setup_dni_user_auth(character varying, text, uuid, text) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.setup_dni_user_auth(character varying, text, text) FROM anon, authenticated;

-- 2) get_next_plot_code: agregar filtro de cooperativa.
CREATE OR REPLACE FUNCTION public.get_next_plot_code(producer_id_param uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    producer_dni VARCHAR(8);
    next_code INTEGER;
    sequence_name TEXT;
BEGIN
    -- Get producer DNI (solo si el productor pertenece a la cooperativa del
    -- usuario que llama, o si es service_role)
    SELECT dni INTO producer_dni
    FROM public.producers
    WHERE id = producer_id_param
      AND (public.is_service_role() OR cooperative_id = public.auth_cooperative_id());

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
$function$;

-- 3) generate_plot_code: mismo filtro (esta es la que de verdad asigna el
--    codigo via el trigger auto_assign_plot_code al insertar una parcela).
CREATE OR REPLACE FUNCTION public.generate_plot_code(producer_id_param uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    producer_dni VARCHAR(8);
    next_code INTEGER;
    sequence_name TEXT;
BEGIN
    -- Get producer DNI (solo si el productor pertenece a la cooperativa del
    -- usuario que llama, o si es service_role)
    SELECT dni INTO producer_dni
    FROM public.producers
    WHERE id = producer_id_param
      AND (public.is_service_role() OR cooperative_id = public.auth_cooperative_id());

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
$function$;
