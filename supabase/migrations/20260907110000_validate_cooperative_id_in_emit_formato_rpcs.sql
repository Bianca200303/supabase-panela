-- Los 9 RPCs "emit_formato_*" (usados por los Formatos*Section.jsx para
-- emitir cada documento) son SECURITY DEFINER y reciben p_cooperative_id
-- como parámetro del cliente SIN validarlo contra el usuario autenticado.
-- Como corren con privilegios elevados, RLS no los protege por dentro: un
-- usuario ya logueado de una cooperativa podía llamar a cualquiera de estos
-- RPCs pasando el cooperative_id de la OTRA cooperativa y el INSERT/UPDATE
-- se hacía igual.
--
-- Se agrega la misma validación en los 9: si el caller no es service_role
-- y el p_cooperative_id no coincide con el de su propio JWT
-- (auth_cooperative_id()), se rechaza. El resto del cuerpo de cada función
-- queda exactamente igual al definido en el baseline.

CREATE OR REPLACE FUNCTION public.emit_formato_control_cloro(p_coop_code text, p_cooperative_id uuid, p_module_id uuid, p_date_from date, p_date_to date, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
        RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
    END IF;

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
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_control_personal(p_coop_code text, p_cooperative_id uuid, p_batch_id uuid, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
        RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
    END IF;

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
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_control_plagas(p_coop_code text, p_cooperative_id uuid, p_module_id uuid, p_date_from date, p_date_to date, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
        RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
    END IF;

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
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_estiba_transporte(p_coop_code text, p_cooperative_id uuid, p_inspection_id uuid, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_next_num integer;
  v_code     text;
BEGIN
  IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
    RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
  END IF;

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
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_inspeccion_ambientes(p_coop_code text, p_cooperative_id uuid, p_module_id uuid, p_inspection_id uuid, p_inspection_date date, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
        RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
    END IF;

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
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_limpieza_desinfeccion(p_coop_code text, p_cooperative_id uuid, p_module_id uuid, p_date_from date, p_date_to date, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
        RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
    END IF;

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
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_mantenimiento_equipos(p_coop_code text, p_cooperative_id uuid, p_module_id uuid, p_date_from date, p_date_to date, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
        RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
    END IF;

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
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_mp_ph(p_coop_code text, p_cooperative_id uuid, p_module_id uuid, p_date_from date, p_date_to date, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb, p_batch_ids uuid[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_next_num   integer;
  v_code       text;
  v_formato_id uuid;
BEGIN
  IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
    RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
  END IF;

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
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_seguimiento_salud(p_coop_code text, p_cooperative_id uuid, p_module_id uuid, p_date_from date, p_date_to date, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
        RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
    END IF;

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
$function$
;
