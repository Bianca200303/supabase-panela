-- Paso 1/5 del rechazo de calidad por lote individual.
--
-- Agrega las columnas necesarias para registrar cuántos kg de un lote se
-- rechazan por calidad (total o parcial) y quién/cuándo lo hizo.
--
-- Este paso es solo estructura: no cambia ningún comportamiento existente.
-- approval_status sigue siendo editable manualmente hasta el paso 2, donde
-- se convierte en un valor derivado automáticamente por trigger.

ALTER TABLE public.quality_evaluations
  ADD COLUMN rejected_kg numeric(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN rejected_by uuid,
  ADD COLUMN rejected_at timestamp with time zone;

ALTER TABLE public.quality_evaluations
  ADD CONSTRAINT quality_evaluations_rejected_kg_check CHECK (rejected_kg >= 0);

ALTER TABLE public.quality_evaluations
  ADD CONSTRAINT quality_evaluations_rejected_by_fkey
  FOREIGN KEY (rejected_by) REFERENCES public.web_users(id) ON DELETE RESTRICT;
