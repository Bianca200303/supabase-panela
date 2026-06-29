-- =============================================================================
-- Reestructura producer_quotas según requerimientos definitivos:
--
--   1. Agrega coop_module_id como snapshot histórico del módulo al momento
--      de asignar el cupo. Si un productor cambia de módulo, el histórico
--      de cupos no se altera (trazabilidad BRC/HACCP).
--
--   2. Reemplaza period_start / period_end por year (integer).
--      El cupo es anual (enero–diciembre), no por campaña flexible.
--      UNIQUE pasa de (producer_id, batch_cert_id, period_start)
--              a      (producer_id, batch_cert_id, year).
--
-- Esta migración reemplaza 20260629100000_add_module_to_producer_quotas.sql
-- que aún no había sido ejecutada.
-- =============================================================================

-- ─── 1. coop_module_id ───────────────────────────────────────────────────────

ALTER TABLE public.producer_quotas
  ADD COLUMN coop_module_id uuid;

-- Backfill desde producers (snapshot del módulo actual)
UPDATE public.producer_quotas pq
SET coop_module_id = p.coop_module_id
FROM public.producers p
WHERE p.id = pq.producer_id;

ALTER TABLE public.producer_quotas
  ALTER COLUMN coop_module_id SET NOT NULL;

ALTER TABLE public.producer_quotas
  ADD CONSTRAINT producer_quotas_module_fkey
    FOREIGN KEY (coop_module_id)
    REFERENCES public.coop_modules(id)
    ON DELETE RESTRICT;

-- ─── 2. year — reemplaza period_start / period_end ───────────────────────────

ALTER TABLE public.producer_quotas
  ADD COLUMN year integer;

-- Backfill: extraer año de period_start
UPDATE public.producer_quotas
SET year = EXTRACT(YEAR FROM period_start)::integer;

ALTER TABLE public.producer_quotas
  ALTER COLUMN year SET NOT NULL;

-- Eliminar constraint de período y UNIQUE antiguo antes de borrar columnas
ALTER TABLE public.producer_quotas
  DROP CONSTRAINT producer_quotas_period_check;

ALTER TABLE public.producer_quotas
  DROP CONSTRAINT producer_quotas_no_overlap;

-- Nuevo UNIQUE: un cupo por productor × certificación × año
ALTER TABLE public.producer_quotas
  ADD CONSTRAINT producer_quotas_unique_per_year
    UNIQUE (producer_id, batch_cert_id, year);

-- Eliminar columnas de período ya reemplazadas
ALTER TABLE public.producer_quotas
  DROP COLUMN period_start,
  DROP COLUMN period_end;

-- ─── 3. Índices ───────────────────────────────────────────────────────────────

-- El índice por período ya no aplica
DROP INDEX IF EXISTS public.idx_producer_quotas_producer_period;

-- Nuevo índice principal: productor + año
CREATE INDEX idx_producer_quotas_producer_year
  ON public.producer_quotas (producer_id, year);

-- Módulo (para reportes y carga masiva por módulo)
CREATE INDEX idx_producer_quotas_module
  ON public.producer_quotas (coop_module_id);
