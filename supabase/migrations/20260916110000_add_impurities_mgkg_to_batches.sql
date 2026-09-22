-- Impurezas del control de calidad del envasado / liberación
-- (plant_production_batches.calidad_impurezas_pct): mismo problema que ya
-- se resolvió para la recepción de materia prima (quality_evaluations,
-- ver migración 20260915130000) -- algunas veces se anota en % y otras en
-- mg/kg (un número grande), sin que el sistema distinga cuál es cuál. Se
-- aplica la misma solución: dos campos sincronizados (% y mg/kg, 1% =
-- 10000 mg/kg exacto) que se guardan ambos -- el resto de la app sigue
-- leyendo siempre calidad_impurezas_pct.
--
-- Se amplía la precisión de calidad_impurezas_pct (antes numeric(5,2))
-- para no perder los valores traza que resultan de convertir desde mg/kg
-- (ej. 150 mg/kg = 0.015%). Sin vistas que dependan de esta columna (a
-- diferencia de quality_evaluations.impurities_pct), no hace falta
-- dropear/recrear nada.

ALTER TABLE public.plant_production_batches
  ALTER COLUMN calidad_impurezas_pct TYPE numeric(9,6);

ALTER TABLE public.plant_production_batches
  ADD COLUMN calidad_impurezas_mgkg numeric(10,2);

ALTER TABLE public.plant_production_batches
  ADD CONSTRAINT chk_pb_calidad_impurezas_mgkg
  CHECK (calidad_impurezas_mgkg >= 0) NOT VALID;

ALTER TABLE public.plant_production_batches
  VALIDATE CONSTRAINT chk_pb_calidad_impurezas_mgkg;
