-- Mismo problema que ya se corrigió en los 9 RPCs "emit_formato_*"
-- (20260907110000_validate_cooperative_id_in_emit_formato_rpcs.sql), pero
-- en la familia más nueva de códigos de control por FECHA: los 5 RPCs
-- "generate_*_control_code" son SECURITY DEFINER y reciben p_cooperative_id
-- del cliente sin validarlo contra el usuario autenticado. Riesgo menor que
-- el de emit_formato_* porque estos solo generan/leen un código (SELECT
-- MAX(...), sin INSERT) -- el INSERT real de estos controles lo hace cada
-- página con supabase.from(...).insert(), protegido por RLS -- pero es el
-- mismo patrón de bug y hay que cerrarlo igual: sin esta validación, un
-- usuario autenticado de una cooperativa podía pedir el "siguiente código"
-- de la OTRA cooperativa (filtración menor de información: cuántos
-- registros lleva la otra cooperativa).

CREATE OR REPLACE FUNCTION public.generate_hygiene_control_code(p_cooperative_id uuid, p_coop_code text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_next_num integer;
BEGIN
  IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
    RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-HYG'));
  SELECT COALESCE(MAX(CAST(SPLIT_PART(formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.plant_hygiene_controls
  WHERE cooperative_id = p_cooperative_id
    AND formato_codigo ~ ('^' || p_coop_code || '-HYG-[0-9]+$');
  RETURN p_coop_code || '-HYG-' || LPAD(v_next_num::text, 4, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_cleaning_verification_control_code(p_cooperative_id uuid, p_coop_code text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_next_num integer;
BEGIN
  IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
    RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-VLS'));
  SELECT COALESCE(MAX(CAST(SPLIT_PART(formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.plant_cleaning_verification_controls
  WHERE cooperative_id = p_cooperative_id
    AND formato_codigo ~ ('^' || p_coop_code || '-VLS-[0-9]+$');
  RETURN p_coop_code || '-VLS-' || LPAD(v_next_num::text, 4, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_chlorine_residual_control_code(p_cooperative_id uuid, p_coop_code text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_next_num integer;
BEGIN
  IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
    RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-CLR'));
  SELECT COALESCE(MAX(CAST(SPLIT_PART(formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.plant_chlorine_residual_controls
  WHERE cooperative_id = p_cooperative_id
    AND formato_codigo ~ ('^' || p_coop_code || '-CLR-[0-9]+$');
  RETURN p_coop_code || '-CLR-' || LPAD(v_next_num::text, 4, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_pest_control_code(p_cooperative_id uuid, p_coop_code text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_next_num integer;
BEGIN
  IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
    RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-PLG'));
  SELECT COALESCE(MAX(CAST(SPLIT_PART(formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.plant_pest_controls
  WHERE cooperative_id = p_cooperative_id
    AND formato_codigo ~ ('^' || p_coop_code || '-PLG-[0-9]+$');
  RETURN p_coop_code || '-PLG-' || LPAD(v_next_num::text, 4, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_warehouse_control_code(p_cooperative_id uuid, p_coop_code text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_next_num integer;
BEGIN
  IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
    RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-ALM'));
  SELECT COALESCE(MAX(CAST(SPLIT_PART(formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.plant_warehouse_controls
  WHERE cooperative_id = p_cooperative_id
    AND formato_codigo ~ ('^' || p_coop_code || '-ALM-[0-9]+$');
  RETURN p_coop_code || '-ALM-' || LPAD(v_next_num::text, 4, '0');
END;
$$;
