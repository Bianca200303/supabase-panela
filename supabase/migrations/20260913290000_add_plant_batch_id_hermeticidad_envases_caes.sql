-- =============================================================================
-- Hermeticidad de Envases (CPR-007) pasa de ser un tab suelto en
-- "Controles de planta" a una acción por lote en Órdenes de producción --
-- mismo motivo y mismo patrón que
-- 20260913280000_add_plant_batch_id_sellado_envasado_caes.sql.
-- =============================================================================

ALTER TABLE public.plant_container_tightness_control_caes
  ADD COLUMN plant_batch_id uuid NOT NULL REFERENCES public.plant_production_batches(id) ON DELETE CASCADE;

CREATE INDEX idx_pctcc_plant_batch ON public.plant_container_tightness_control_caes (plant_batch_id);
