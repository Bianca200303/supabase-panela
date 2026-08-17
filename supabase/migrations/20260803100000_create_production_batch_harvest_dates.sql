-- =============================================================================
-- production_batch_harvest_dates -- fechas de corte ADICIONALES por lote de
-- producción (app móvil). La fecha de corte "principal" sigue siendo
-- production_batches.harvest_date (la que arma el código de lote, sin
-- cambios) -- esta tabla guarda las fechas de corte extra que se agregan
-- cuando la caña procesada en una misma fecha de proceso viene de varios
-- días de corte distintos. Mismo patrón que batch_temperatures (varias
-- temperaturas por lote).
-- =============================================================================

CREATE TABLE public.production_batch_harvest_dates (
  id                    uuid        NOT NULL DEFAULT gen_random_uuid(),
  production_batch_id   uuid        NOT NULL,
  harvest_date          date        NOT NULL,
  cooperative_id        uuid        NOT NULL,
  created_at            timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT production_batch_harvest_dates_pkey PRIMARY KEY (id),
  CONSTRAINT pbhd_production_batch_fkey
    FOREIGN KEY (production_batch_id) REFERENCES public.production_batches(id) ON DELETE CASCADE,
  CONSTRAINT pbhd_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT,
  CONSTRAINT pbhd_unique_batch_date UNIQUE (production_batch_id, harvest_date)
);

CREATE INDEX idx_pbhd_production_batch_id ON public.production_batch_harvest_dates (production_batch_id);
CREATE INDEX idx_pbhd_cooperative_id ON public.production_batch_harvest_dates (cooperative_id);

ALTER TABLE public.production_batch_harvest_dates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "production_batch_harvest_dates_select"
  ON public.production_batch_harvest_dates AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "production_batch_harvest_dates_insert"
  ON public.production_batch_harvest_dates AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "production_batch_harvest_dates_update"
  ON public.production_batch_harvest_dates AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "production_batch_harvest_dates_delete"
  ON public.production_batch_harvest_dates AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.production_batch_harvest_dates TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.production_batch_harvest_dates TO service_role;
