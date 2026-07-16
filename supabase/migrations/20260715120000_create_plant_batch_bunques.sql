-- =============================================================================
-- Tabla: plant_batch_bunques
--
-- Por capacidad limitada del equipo de tamizado, un lote de envasado
-- (plant_production_batches) no se tamiza de una sola vez: se reparte en
-- varios "bunques". Cada bunque agrupa un subconjunto de los insumos del
-- lote (plant_homogenization_inputs, vía bunque_id) y tiene su propio
-- resultado de tamizado/reproceso/descarte/merma -- métricas globales del
-- bunque, no desagregables por insumo.
--
-- bunque_number lo escribe el usuario a mano (viene del registro físico de
-- planta) y NO se valida unicidad ni secuencia: es solo un dato de campo.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.plant_batch_bunques (
  id               uuid          NOT NULL DEFAULT gen_random_uuid(),
  plant_batch_id   uuid          NOT NULL,
  bunque_number    text          NOT NULL,

  -- Salida del bunque: NULL hasta que se registra (el bunque puede existir
  -- solo con insumos asignados, antes de tener resultado de tamizado).
  tamizada_kg      numeric(10,3),
  reproceso_kg     numeric(10,3),
  descarte_kg      numeric(10,3),
  merma_kg         numeric(10,3),
  processed_by     uuid,
  processed_at     timestamptz,

  cooperative_id   uuid          NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),

  CONSTRAINT pbb_pkey PRIMARY KEY (id),
  CONSTRAINT pbb_plant_batch_fkey
    FOREIGN KEY (plant_batch_id) REFERENCES public.plant_production_batches(id) ON DELETE CASCADE,
  CONSTRAINT chk_pbb_tamizada_non_negative  CHECK (tamizada_kg  >= 0),
  CONSTRAINT chk_pbb_reproceso_non_negative CHECK (reproceso_kg >= 0),
  CONSTRAINT chk_pbb_descarte_non_negative  CHECK (descarte_kg  >= 0),
  CONSTRAINT chk_pbb_merma_non_negative     CHECK (merma_kg     >= 0)
);

-- -----------------------------------------------------------------------------
-- RLS -- mismo patrón del proyecto
-- -----------------------------------------------------------------------------
ALTER TABLE public.plant_batch_bunques ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pbb_select"
  ON public.plant_batch_bunques AS PERMISSIVE FOR SELECT
  TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pbb_insert"
  ON public.plant_batch_bunques AS PERMISSIVE FOR INSERT
  TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pbb_update"
  ON public.plant_batch_bunques AS PERMISSIVE FOR UPDATE
  TO authenticated
  USING  (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pbb_delete"
  ON public.plant_batch_bunques AS PERMISSIVE FOR DELETE
  TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

-- -----------------------------------------------------------------------------
-- Grants
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.plant_batch_bunques TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON TABLE public.plant_batch_bunques TO service_role;

-- -----------------------------------------------------------------------------
-- Índices
-- -----------------------------------------------------------------------------
CREATE INDEX idx_pbb_plant_batch
  ON public.plant_batch_bunques (plant_batch_id);

CREATE INDEX idx_pbb_cooperative
  ON public.plant_batch_bunques (cooperative_id);
