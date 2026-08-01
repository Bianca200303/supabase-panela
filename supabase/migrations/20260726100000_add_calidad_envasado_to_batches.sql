-- Control de calidad del envasado: una vez que un lote termina de envasarse,
-- pasa por un control de calidad propio del producto terminado (humedad,
-- impurezas, color, sabor, textura, observaciones). Es un dominio distinto
-- de "quality_evaluations" (que evalúa la materia prima que entra en la
-- recepción, ligada a exit_item_id/exit_reception_id) -- acá se evalúa el
-- lote de planta ya envasado, así que va como columnas nuevas en
-- plant_production_batches, mismo criterio que envasado_*: 1 registro por
-- lote, editable (se vuelve a guardar completo si hubo que corregir algo).

ALTER TABLE public.plant_production_batches
  ADD COLUMN IF NOT EXISTS calidad_humedad_pct     numeric(5,2)
    CHECK (calidad_humedad_pct >= 0 AND calidad_humedad_pct <= 100),
  ADD COLUMN IF NOT EXISTS calidad_impurezas_pct   numeric(5,2)
    CHECK (calidad_impurezas_pct >= 0 AND calidad_impurezas_pct <= 100),
  ADD COLUMN IF NOT EXISTS calidad_color           text,
  ADD COLUMN IF NOT EXISTS calidad_sabor           text,
  ADD COLUMN IF NOT EXISTS calidad_textura         text,
  ADD COLUMN IF NOT EXISTS calidad_observaciones   text,
  ADD COLUMN IF NOT EXISTS calidad_registered_by   uuid,
  ADD COLUMN IF NOT EXISTS calidad_registered_at   timestamptz;
