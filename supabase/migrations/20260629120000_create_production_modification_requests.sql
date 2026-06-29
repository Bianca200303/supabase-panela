-- =============================================================================
-- Tabla: production_modification_requests
--
-- Flujo: el técnico de campo detecta un error en un lote registrado y emite
-- una solicitud de modificación desde la app móvil. Un usuario de planta
-- (rol aprobador, ej. Lenin Román) revisa y aprueba o rechaza desde la app web.
-- Solo cuando se aprueba se aplican los cambios al lote original.
--
-- Decisiones de diseño:
--   • field_changes JSONB: [{field, old_value, new_value}] — flexible ante
--     cualquier campo modificable sin esquema rígido.
--   • requested_by / reviewed_by como varchar(8) — DNI, consistente con el
--     patrón de auditoría del proyecto (created_by en otras tablas).
--   • status como varchar con CHECK — simple, legible en queries SQL directas.
--   • La aprobación es por ROL (usuario de planta), no por usuario específico,
--     para que cualquier aprobador autorizado pueda actuar.
--   • El lote original NO se toca hasta que status = 'aprobado'.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.production_modification_requests (
  id                    uuid          NOT NULL DEFAULT gen_random_uuid(),
  production_batch_id   uuid          NOT NULL,
  cooperative_id        uuid          NOT NULL,

  -- Solicitud
  requested_by          varchar(8)    NOT NULL,  -- DNI del técnico de campo
  requested_at          timestamptz   NOT NULL DEFAULT now(),
  field_changes         jsonb         NOT NULL,  -- [{field, old_value, new_value}]
  motivo                text          NOT NULL,

  -- Resolución (nulo mientras está pendiente)
  status                varchar(12)   NOT NULL DEFAULT 'pendiente'
                          CHECK (status IN ('pendiente', 'aprobado', 'rechazado')),
  reviewed_by           varchar(8),              -- DNI del usuario de planta aprobador
  reviewed_at           timestamptz,
  review_notes          text,

  created_at            timestamptz   NOT NULL DEFAULT now(),
  updated_at            timestamptz   NOT NULL DEFAULT now(),

  CONSTRAINT pmr_pkey PRIMARY KEY (id),
  CONSTRAINT pmr_batch_fkey
    FOREIGN KEY (production_batch_id)
    REFERENCES public.production_batches(id)
    ON DELETE RESTRICT,
  CONSTRAINT pmr_cooperative_fkey
    FOREIGN KEY (cooperative_id)
    REFERENCES public.cooperatives(id)
    ON DELETE CASCADE,
  -- Un lote no puede tener dos solicitudes pendientes simultáneas
  CONSTRAINT pmr_one_pending_per_batch
    EXCLUDE USING btree (production_batch_id WITH =)
    WHERE (status = 'pendiente')
);

-- -----------------------------------------------------------------------------
-- RLS — mismo patrón de cooperativa del proyecto
-- -----------------------------------------------------------------------------
ALTER TABLE public.production_modification_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pmr_select"
  ON public.production_modification_requests AS PERMISSIVE FOR SELECT
  TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pmr_insert"
  ON public.production_modification_requests AS PERMISSIVE FOR INSERT
  TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pmr_update"
  ON public.production_modification_requests AS PERMISSIVE FOR UPDATE
  TO authenticated
  USING  (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

-- Borrado no permitido — el historial de solicitudes es inmutable para auditoría
-- Solo service_role puede borrar (limpieza administrativa)
CREATE POLICY "pmr_delete"
  ON public.production_modification_requests AS PERMISSIVE FOR DELETE
  TO authenticated
  USING (public.is_service_role());

-- -----------------------------------------------------------------------------
-- Grants
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE
  ON TABLE public.production_modification_requests TO anon;
GRANT SELECT, INSERT, UPDATE
  ON TABLE public.production_modification_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON TABLE public.production_modification_requests TO service_role;

-- -----------------------------------------------------------------------------
-- Índices
-- -----------------------------------------------------------------------------

-- Técnico consulta sus solicitudes pendientes
CREATE INDEX idx_pmr_batch
  ON public.production_modification_requests (production_batch_id);

-- App web filtra por estado para cola de aprobación
CREATE INDEX idx_pmr_status_cooperative
  ON public.production_modification_requests (cooperative_id, status);

-- Auditoría por técnico
CREATE INDEX idx_pmr_requested_by
  ON public.production_modification_requests (requested_by);

-- -----------------------------------------------------------------------------
-- Trigger: updated_at
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_pmr_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_pmr_updated_at
  BEFORE UPDATE ON public.production_modification_requests
  FOR EACH ROW EXECUTE FUNCTION public.set_pmr_updated_at();
