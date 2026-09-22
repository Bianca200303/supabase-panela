-- Corrige una regresión introducida por 20260914000000_fix_cross_cooperative_security_holes.sql.
--
-- Esa migración agregó el filtro `is_service_role() OR cooperative_id =
-- auth_cooperative_id()` a get_next_plot_code/generate_plot_code, asumiendo
-- (según su propio comentario) que correr real_users_seed.sql manualmente
-- "como postgres/service_role" alcanzaba para pasar el filtro. Eso es cierto
-- para los REVOKE EXECUTE de esa misma migración (un superusuario los
-- ignora), pero NO para is_service_role(): esa función lee el claim `role`
-- de `request.jwt.claims`, un GUC que solo existe cuando la consulta pasa
-- por PostgREST. Una conexión directa (SQL Editor de Supabase Studio, psql,
-- o cualquier script tipo real_users_seed.sql) no tiene ese GUC seteado en
-- absoluto -- is_service_role() da false y auth_cooperative_id() da NULL,
-- así que el filtro NO deja pasar a NINGÚN productor real, sin importar cuál
-- sea. Resultado: el trigger auto_assign_plot_code() falla con
-- "Producer not found: <uuid>" para cualquier parcela insertada por SQL
-- directo -- rompió el bootstrap real de usuarios (real_users_seed.sql
-- inserta productores + parcelas).
--
-- Fix: agregar una tercera condición que reconoce la conexión directa (sin
-- JWT en absoluto) como confiable -- current_setting('request.jwt.claims',
-- true) IS NULL. Ningún llamador anon/authenticated puede provocar esto:
-- PostgREST siempre setea ese GUC (aunque sea con role "anon"), así que solo
-- puede estar ausente en una conexión que no pasó por la API -- exactamente
-- el escenario de scripts de setup corridos a mano. No debilita la
-- protección multi-tenant del hallazgo 11 (ver
-- [[project_supabase_security]]): un request real de la app móvil/web
-- siempre trae request.jwt.claims seteado, así que sigue exigiendo
-- is_service_role() o cooperative_id = auth_cooperative_id() como antes.

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
    -- usuario que llama, si es service_role, o si es una conexión directa
    -- sin JWT en absoluto -- ver comentario de cabecera)
    SELECT dni INTO producer_dni
    FROM public.producers
    WHERE id = producer_id_param
      AND (
        public.is_service_role()
        OR cooperative_id = public.auth_cooperative_id()
        OR current_setting('request.jwt.claims', true) IS NULL
      );

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
    -- usuario que llama, si es service_role, o si es una conexión directa
    -- sin JWT en absoluto -- ver comentario de cabecera)
    SELECT dni INTO producer_dni
    FROM public.producers
    WHERE id = producer_id_param
      AND (
        public.is_service_role()
        OR cooperative_id = public.auth_cooperative_id()
        OR current_setting('request.jwt.claims', true) IS NULL
      );

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
