-- Código único por registro para los 4 controles CAES que quedaron sin
-- "formato_codigo" cuando se generalizó el patrón en
-- 20260902110000_add_codigo_to_plant_controls.sql -- esa migración solo
-- tocó las 5 tablas de Norandino (Higiene, Verificación de Limpieza, Cloro
-- Residual, Plagas, Almacén). Las versiones CAES de Higiene y Limpieza
-- viven en tablas nuevas y separadas que nunca recibieron el mismo trato,
-- y Sellado/Envasado + Liberación nunca se diseñaron con código porque son
-- controles "por lote", no "por fecha". El Resumen de Trazabilidad
-- mostraba "—" en la columna Código para estos 4 -- se corrige
-- agregándoles el mismo mecanismo (pg_advisory_xact_lock + MAX+1 sobre
-- formato_codigo), incluyendo desde el inicio la validación de
-- p_cooperative_id contra el usuario autenticado (bug que en la familia
-- original recién se cerró después, ver
-- 20260908100000_validate_cooperative_id_in_generate_control_code_rpcs.sql).

ALTER TABLE public.plant_hygiene_controls_caes
  ADD COLUMN IF NOT EXISTS formato_codigo text UNIQUE;
ALTER TABLE public.plant_general_cleaning_controls
  ADD COLUMN IF NOT EXISTS formato_codigo text UNIQUE;
ALTER TABLE public.plant_packaging_seal_control_caes
  ADD COLUMN IF NOT EXISTS formato_codigo text UNIQUE;
ALTER TABLE public.plant_production_batches
  ADD COLUMN IF NOT EXISTS liberacion_formato_codigo text UNIQUE;

CREATE OR REPLACE FUNCTION public.generate_hygiene_caes_control_code(p_cooperative_id uuid, p_coop_code text)
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
  FROM public.plant_hygiene_controls_caes
  WHERE cooperative_id = p_cooperative_id
    AND formato_codigo ~ ('^' || p_coop_code || '-HYG-[0-9]+$');
  RETURN p_coop_code || '-HYG-' || LPAD(v_next_num::text, 4, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_general_cleaning_control_code(p_cooperative_id uuid, p_coop_code text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_next_num integer;
BEGIN
  IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
    RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-LIM'));
  SELECT COALESCE(MAX(CAST(SPLIT_PART(formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.plant_general_cleaning_controls
  WHERE cooperative_id = p_cooperative_id
    AND formato_codigo ~ ('^' || p_coop_code || '-LIM-[0-9]+$');
  RETURN p_coop_code || '-LIM-' || LPAD(v_next_num::text, 4, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_packaging_seal_control_code(p_cooperative_id uuid, p_coop_code text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_next_num integer;
BEGIN
  IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
    RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-SEE'));
  SELECT COALESCE(MAX(CAST(SPLIT_PART(formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.plant_packaging_seal_control_caes
  WHERE cooperative_id = p_cooperative_id
    AND formato_codigo ~ ('^' || p_coop_code || '-SEE-[0-9]+$');
  RETURN p_coop_code || '-SEE-' || LPAD(v_next_num::text, 4, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_liberacion_control_code(p_cooperative_id uuid, p_coop_code text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_next_num integer;
BEGIN
  IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
    RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-LIB'));
  SELECT COALESCE(MAX(CAST(SPLIT_PART(liberacion_formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.plant_production_batches
  WHERE cooperative_id = p_cooperative_id
    AND liberacion_formato_codigo ~ ('^' || p_coop_code || '-LIB-[0-9]+$');
  RETURN p_coop_code || '-LIB-' || LPAD(v_next_num::text, 4, '0');
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_hygiene_caes_control_code(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_general_cleaning_control_code(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_packaging_seal_control_code(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_liberacion_control_code(uuid, text) TO authenticated;
