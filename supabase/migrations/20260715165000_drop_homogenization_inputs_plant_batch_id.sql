-- =============================================================================
-- Ahora sí se puede eliminar plant_homogenization_inputs.plant_batch_id:
-- v_plant_order_summary ya fue redefinida sobre bunques en
-- 20260715160000_plant_order_summary_desde_bunques.sql, así que nada
-- depende de esta columna. bunque_id (agregada en 20260715130000) es la
-- única forma de llegar al lote desde acá de ahora en adelante.
-- =============================================================================

ALTER TABLE public.plant_homogenization_inputs
  DROP CONSTRAINT plant_homogenization_inputs_plant_batch_id_fkey,
  DROP COLUMN plant_batch_id;
