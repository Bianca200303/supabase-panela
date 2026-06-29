-- =============================================================================
-- Tabla: certified_workers
--
-- Lista de trabajadores certificados por módulo. Se usa en los formularios
-- de control operario (control del personal operario) como fuente del
-- desplegable "Nombre y apellidos".
--
-- Solo first_name, last_name, cooperative_id y coop_module_id son
-- obligatorios. El resto de campos son opcionales para permitir carga
-- mínima inicial desde SQL y enriquecimiento posterior.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.certified_workers (
  id               uuid          NOT NULL DEFAULT gen_random_uuid(),
  first_name       varchar(100)  NOT NULL,
  last_name        varchar(100)  NOT NULL,
  cooperative_id   uuid          NOT NULL,
  coop_module_id   uuid          NOT NULL,

  -- Campos opcionales
  dni              varchar(8),
  position         varchar(100),           -- cargo (ej. "Operario de planta")
  certified_since  date,                   -- inicio de certificación
  certified_until  date,                   -- vencimiento (para alertas futuras)
  is_active        boolean       NOT NULL DEFAULT true,
  notes            text,

  created_at       timestamptz   NOT NULL DEFAULT now(),
  updated_at       timestamptz   NOT NULL DEFAULT now(),

  CONSTRAINT cw_pkey PRIMARY KEY (id),
  CONSTRAINT cw_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT cw_module_fkey
    FOREIGN KEY (coop_module_id) REFERENCES public.coop_modules(id) ON DELETE RESTRICT
);

-- DNI único por módulo solo cuando se proporciona (permite carga sin DNI)
CREATE UNIQUE INDEX idx_cw_unique_dni_per_module
  ON public.certified_workers (dni, coop_module_id)
  WHERE dni IS NOT NULL;

-- -----------------------------------------------------------------------------
-- RLS — mismo patrón del proyecto
-- -----------------------------------------------------------------------------
ALTER TABLE public.certified_workers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "cw_select"
  ON public.certified_workers AS PERMISSIVE FOR SELECT
  TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "cw_insert"
  ON public.certified_workers AS PERMISSIVE FOR INSERT
  TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "cw_update"
  ON public.certified_workers AS PERMISSIVE FOR UPDATE
  TO authenticated
  USING  (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "cw_delete"
  ON public.certified_workers AS PERMISSIVE FOR DELETE
  TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

-- -----------------------------------------------------------------------------
-- Grants
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.certified_workers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON TABLE public.certified_workers TO service_role;

-- -----------------------------------------------------------------------------
-- Índices
-- -----------------------------------------------------------------------------
CREATE INDEX idx_cw_module
  ON public.certified_workers (coop_module_id, is_active);

CREATE INDEX idx_cw_cooperative
  ON public.certified_workers (cooperative_id);

-- -----------------------------------------------------------------------------
-- Trigger: updated_at
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_cw_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_cw_updated_at
  BEFORE UPDATE ON public.certified_workers
  FOR EACH ROW EXECUTE FUNCTION public.set_cw_updated_at();
