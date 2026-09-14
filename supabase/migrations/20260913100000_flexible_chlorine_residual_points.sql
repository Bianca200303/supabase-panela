-- Cloro Residual tenía los 3 puntos de control de Norandino harcodeados
-- (CHECK point_code IN ('p1','p2','p3')) -- CAES usa otros puntos, y en
-- otra cantidad. Se libera la columna para que la lista de puntos sea
-- configurable por cooperativa vía form_configurations (step_key
-- 'cloro_residual_puntos'), mismo mecanismo que ya usan Limpieza de
-- Ambientes/Higiene del Personal para sus áreas.
--
-- Primero se saca la restricción vieja (que solo permite 'p1'/'p2'/'p3') --
-- si no, el UPDATE de abajo (que escribe la etiqueta completa) la viola.
DO $$
DECLARE
  constraint_name text;
BEGIN
  SELECT con.conname INTO constraint_name
  FROM pg_constraint con
  JOIN pg_attribute att ON att.attnum = ANY(con.conkey) AND att.attrelid = con.conrelid
  WHERE con.conrelid = 'public.plant_chlorine_residual_checks'::regclass
    AND con.contype = 'c'
    AND att.attname = 'point_code';

  IF constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.plant_chlorine_residual_checks DROP CONSTRAINT %I', constraint_name);
  END IF;
END $$;

-- point_code pasa a ser el mismo texto libre que ya se usa como "area" en
-- los demás controles de limpieza -- el código ES el nombre visible del
-- punto, no un id corto aparte (evita tener el label en dos lugares
-- distintos que se puedan desincronizar). Por eso se migran los códigos
-- cortos existentes ('p1'/'p2'/'p3') a su etiqueta completa -- los
-- controles ya guardados de Norandino siguen mostrando exactamente el
-- mismo texto que mostraban antes.
UPDATE public.plant_chlorine_residual_checks SET point_code = CASE point_code
  WHEN 'p1' THEN 'Punto 1: Aduana Sanitaria'
  WHEN 'p2' THEN 'Punto 2: Laboratorio'
  WHEN 'p3' THEN 'Punto 3: Área de Envasado'
  ELSE point_code
END
WHERE point_code IN ('p1', 'p2', 'p3');
