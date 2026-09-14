-- =============================================================================
-- Sellado, Envasado y Empaque (CPR-003) pasa de ser un tab suelto en
-- "Controles de planta" a una acción por lote en Órdenes de producción,
-- igual que Norandino tiene "Control de objetos extraños"/"Control de
-- pesos y sellado" por lote (ver ForeignObjectControlModal.jsx). El papel
-- real es una inspección del producto YA envasado de un lote específico --
-- a diferencia de Monitoreo del Tamizado (CPR-002), que queda en el hub
-- porque su "N° Lote" es materia prima, no lote de envasado.
--
-- lote_code (texto libre) se mantiene por compatibilidad de datos/display
-- -- plant_batch_id es la referencia real que usa la UI de ahora en más.
-- Mismo patrón que plant_batch_foreign_object_forms
-- (20260722140000_create_foreign_object_control_forms.sql).
-- =============================================================================

ALTER TABLE public.plant_packaging_seal_control_caes
  ADD COLUMN plant_batch_id uuid NOT NULL REFERENCES public.plant_production_batches(id) ON DELETE CASCADE;

CREATE INDEX idx_ppscc_plant_batch ON public.plant_packaging_seal_control_caes (plant_batch_id);
