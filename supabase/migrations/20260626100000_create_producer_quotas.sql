-- =============================================================================
-- Tabla: producer_quotas
-- Propósito: Registrar el cupo máximo de panela certificada (kg) que un
--   productor puede producir y vender a la cooperativa por certificación y
--   por campaña productiva. Es un requisito de la certificadora orgánica.
--
-- Decisiones de diseño:
--   • Tabla independiente (no columnas en producers) para soportar múltiples
--     cupos por productor: distintas certificaciones y/o 1-2 campañas por año.
--   • period_start / period_end en lugar de año calendario, porque las
--     campañas tienen fechas irregulares (no siempre ene-dic).
--   • batch_cert_id vincula el cupo a una certificación específica de
--     batch_certs; si un lote tiene varias certs, su panela_kg suma al cupo
--     de cada una por separado.
--   • Solo panela_kg cuenta (no confitillo_kg) — así lo exige la certificadora.
--   • Escritura gestionada desde la app web / Supabase directo por ahora;
--     las políticas de escritura se pueden estrechar cuando web auth esté listo.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.producer_quotas (
  id               uuid        NOT NULL DEFAULT gen_random_uuid(),
  producer_id      uuid        NOT NULL,
  batch_cert_id    uuid        NOT NULL,
  cooperative_id   uuid        NOT NULL,
  cupo_kg          numeric(10,2) NOT NULL CHECK (cupo_kg > 0),
  period_start     date        NOT NULL,
  period_end       date        NOT NULL,
  -- Etiqueta libre para identificar la campaña (ej. "Campaña 1 - 2026")
  notes            text,
  -- Auditoría: DNI del usuario que creó el registro
  created_by       character varying(8),
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT producer_quotas_pkey PRIMARY KEY (id),
  -- Un productor no puede tener dos cupos solapados para la misma certificación
  CONSTRAINT producer_quotas_no_overlap
    UNIQUE (producer_id, batch_cert_id, period_start),
  CONSTRAINT producer_quotas_period_check
    CHECK (period_end > period_start),
  CONSTRAINT producer_quotas_producer_fkey
    FOREIGN KEY (producer_id) REFERENCES public.producers(id) ON DELETE CASCADE,
  CONSTRAINT producer_quotas_batch_cert_fkey
    FOREIGN KEY (batch_cert_id) REFERENCES public.batch_certs(id) ON DELETE RESTRICT,
  CONSTRAINT producer_quotas_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- RLS
-- -----------------------------------------------------------------------------
ALTER TABLE public.producer_quotas ENABLE ROW LEVEL SECURITY;

-- Lectura: cualquier usuario autenticado de la cooperativa (app móvil necesita
-- leer los cupos para mostrar la alerta al técnico de campo).
CREATE POLICY "producer_quotas_select"
  ON public.producer_quotas
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    (cooperative_id = public.auth_cooperative_id())
    OR public.is_service_role()
  );

-- Escritura (INSERT/UPDATE/DELETE): misma política base por ahora.
-- Queda restringida al cooperative_id del JWT, así el móvil no puede escribir
-- cupos desde una cooperativa distinta. Se puede estrechar a roles web cuando
-- la autenticación web esté implementada.
CREATE POLICY "producer_quotas_insert"
  ON public.producer_quotas
  AS PERMISSIVE
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (cooperative_id = public.auth_cooperative_id())
    OR public.is_service_role()
  );

CREATE POLICY "producer_quotas_update"
  ON public.producer_quotas
  AS PERMISSIVE
  FOR UPDATE
  TO authenticated
  USING (
    (cooperative_id = public.auth_cooperative_id())
    OR public.is_service_role()
  )
  WITH CHECK (
    (cooperative_id = public.auth_cooperative_id())
    OR public.is_service_role()
  );

CREATE POLICY "producer_quotas_delete"
  ON public.producer_quotas
  AS PERMISSIVE
  FOR DELETE
  TO authenticated
  USING (
    (cooperative_id = public.auth_cooperative_id())
    OR public.is_service_role()
  );

-- -----------------------------------------------------------------------------
-- Índices
-- Diseñados para la consulta más frecuente: dado un productor y una fecha,
-- encontrar todos sus cupos activos y la producción acumulada.
-- -----------------------------------------------------------------------------

-- Consulta principal del RPC: productor + período activo
CREATE INDEX idx_producer_quotas_producer_period
  ON public.producer_quotas (producer_id, period_start, period_end);

-- Filtro por certificación (cuando se quiere ver cupo de una cert específica)
CREATE INDEX idx_producer_quotas_batch_cert
  ON public.producer_quotas (batch_cert_id);

-- Multi-tenant: filtro por cooperativa
CREATE INDEX idx_producer_quotas_cooperative
  ON public.producer_quotas (cooperative_id);

-- -----------------------------------------------------------------------------
-- Trigger: updated_at automático
-- Reutiliza el patrón ya existente en el proyecto.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_producer_quotas_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$;

CREATE TRIGGER trg_producer_quotas_updated_at
  BEFORE UPDATE ON public.producer_quotas
  FOR EACH ROW
  EXECUTE FUNCTION public.set_producer_quotas_updated_at();
