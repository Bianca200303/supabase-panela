-- =============================================================================
-- Código único por registro para los controles de planta por FECHA (Higiene,
-- Verificación de Limpieza, Cloro Residual, Plagas, Almacén).
--
-- Hoy estos 5 controles se guardan sin ningún código propio -- el Resumen de
-- Trazabilidad solo podía mostrar la fecha del control más reciente. CAES
-- pide mostrar también un código propio de cada registro, como ya pasa con
-- la otra familia de formatos (formatos_control_cloro/formatos_control_plagas,
-- de campo) vía sus RPC emit_formato_*.
--
-- Mismo mecanismo de generación que esa familia (pg_advisory_xact_lock +
-- MAX(...)+1 sobre el código existente, ver emit_formato_control_cloro en
-- 20260510202536_0001_baseline_schema.sql), pero acá el código se genera
-- SOLO al crear el registro (no hay estado draft/emitted en estos
-- controles) y no se acopla al insert -- cada página llama a la función
-- para obtener el código y lo manda como parte del insert normal, porque
-- cada página ya arma su propio insert con las sub-tablas de cada control.
-- =============================================================================

ALTER TABLE public.plant_hygiene_controls
  ADD COLUMN IF NOT EXISTS formato_codigo text UNIQUE;
ALTER TABLE public.plant_cleaning_verification_controls
  ADD COLUMN IF NOT EXISTS formato_codigo text UNIQUE;
ALTER TABLE public.plant_chlorine_residual_controls
  ADD COLUMN IF NOT EXISTS formato_codigo text UNIQUE;
ALTER TABLE public.plant_pest_controls
  ADD COLUMN IF NOT EXISTS formato_codigo text UNIQUE;
ALTER TABLE public.plant_warehouse_controls
  ADD COLUMN IF NOT EXISTS formato_codigo text UNIQUE;

CREATE OR REPLACE FUNCTION public.generate_hygiene_control_code(p_cooperative_id uuid, p_coop_code text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_next_num integer;
BEGIN
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
  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-ALM'));
  SELECT COALESCE(MAX(CAST(SPLIT_PART(formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.plant_warehouse_controls
  WHERE cooperative_id = p_cooperative_id
    AND formato_codigo ~ ('^' || p_coop_code || '-ALM-[0-9]+$');
  RETURN p_coop_code || '-ALM-' || LPAD(v_next_num::text, 4, '0');
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_hygiene_control_code(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_cleaning_verification_control_code(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_chlorine_residual_control_code(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_pest_control_code(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_warehouse_control_code(uuid, text) TO authenticated;
