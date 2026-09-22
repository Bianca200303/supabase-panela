-- Backfill de formato_codigo para los registros de los 4 controles CAES que
-- ya existían ANTES de 20260921100000_add_codigo_to_remaining_caes_controls.sql
-- -- el código solo se genera al CREAR un registro (nunca al editar, mismo
-- criterio que la familia Verificación/Cloro/Plagas), así que los controles
-- de Higiene/Limpieza (mensuales, se editan con "Registrar hoy") y los
-- registros de Sellado/Envasado y Liberación creados antes de esa migración
-- quedaron con formato_codigo NULL para siempre si no se corrige acá.
--
-- Mismo criterio que la migración original (20260902110000): no se tocó a
-- los registros previos en su momento -- acá sí se decide hacerlo, a pedido
-- del usuario, para dejar consistentes los registros de prueba de la sesión.
-- Se numeran en el orden real en que se crearon (created_at), como si el
-- generador hubiera existido desde el principio.

DO $$
DECLARE
  r RECORD;
  v_next_num integer;
  v_coop_code text;
BEGIN
  -- Higiene CAES
  FOR r IN
    SELECT phc.id, phc.cooperative_id, c.code AS coop_code
    FROM public.plant_hygiene_controls_caes phc
    JOIN public.cooperatives c ON c.id = phc.cooperative_id
    WHERE phc.formato_codigo IS NULL
    ORDER BY phc.created_at
  LOOP
    SELECT COALESCE(MAX(CAST(SPLIT_PART(formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.plant_hygiene_controls_caes
    WHERE cooperative_id = r.cooperative_id
      AND formato_codigo ~ ('^' || r.coop_code || '-HYG-[0-9]+$');
    UPDATE public.plant_hygiene_controls_caes
    SET formato_codigo = r.coop_code || '-HYG-' || LPAD(v_next_num::text, 4, '0')
    WHERE id = r.id;
  END LOOP;

  -- Limpieza CAES
  FOR r IN
    SELECT pgc.id, pgc.cooperative_id, c.code AS coop_code
    FROM public.plant_general_cleaning_controls pgc
    JOIN public.cooperatives c ON c.id = pgc.cooperative_id
    WHERE pgc.formato_codigo IS NULL
    ORDER BY pgc.created_at
  LOOP
    SELECT COALESCE(MAX(CAST(SPLIT_PART(formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.plant_general_cleaning_controls
    WHERE cooperative_id = r.cooperative_id
      AND formato_codigo ~ ('^' || r.coop_code || '-LIM-[0-9]+$');
    UPDATE public.plant_general_cleaning_controls
    SET formato_codigo = r.coop_code || '-LIM-' || LPAD(v_next_num::text, 4, '0')
    WHERE id = r.id;
  END LOOP;

  -- Sellado, Envasado y Empaque
  FOR r IN
    SELECT ppscc.id, ppscc.cooperative_id, c.code AS coop_code
    FROM public.plant_packaging_seal_control_caes ppscc
    JOIN public.cooperatives c ON c.id = ppscc.cooperative_id
    WHERE ppscc.formato_codigo IS NULL
    ORDER BY ppscc.created_at
  LOOP
    SELECT COALESCE(MAX(CAST(SPLIT_PART(formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.plant_packaging_seal_control_caes
    WHERE cooperative_id = r.cooperative_id
      AND formato_codigo ~ ('^' || r.coop_code || '-SEE-[0-9]+$');
    UPDATE public.plant_packaging_seal_control_caes
    SET formato_codigo = r.coop_code || '-SEE-' || LPAD(v_next_num::text, 4, '0')
    WHERE id = r.id;
  END LOOP;

  -- Liberación de Producto Terminado
  FOR r IN
    SELECT pb.id, pb.cooperative_id, c.code AS coop_code
    FROM public.plant_production_batches pb
    JOIN public.cooperatives c ON c.id = pb.cooperative_id
    WHERE pb.liberacion_resultado IS NOT NULL
      AND pb.liberacion_formato_codigo IS NULL
    ORDER BY pb.calidad_registered_at
  LOOP
    SELECT COALESCE(MAX(CAST(SPLIT_PART(liberacion_formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.plant_production_batches
    WHERE cooperative_id = r.cooperative_id
      AND liberacion_formato_codigo ~ ('^' || r.coop_code || '-LIB-[0-9]+$');
    UPDATE public.plant_production_batches
    SET liberacion_formato_codigo = r.coop_code || '-LIB-' || LPAD(v_next_num::text, 4, '0')
    WHERE id = r.id;
  END LOOP;
END $$;
