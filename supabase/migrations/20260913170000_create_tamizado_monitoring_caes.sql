-- =============================================================================
-- Monitoreo y Verificación del Tamizado / PCC (CAESP-PP-BPM-RE-CPR-002) --
-- SOLO CAES, control nuevo de Fase 2 (ver
-- COOPERATIVE.features.controlesPlantaCAES en lib/config.js), sin
-- equivalente en Norandino.
--
-- El papel real es un registro plano (no agrupado por mes/control): cada
-- fila es una inspección de integridad del tamiz para UN lote en UNA fecha
-- (5 checks fijos: sin abolladuras, sin fisuras, sin desgaste, sin
-- deformaciones, sin obstrucciones), con desviación Sí/No + causa raíz +
-- acciones correctivas si aplica. No hay cabecera de "control" que agrupe
-- varias filas (a diferencia de los controles de Fase 1) -- por eso es una
-- sola tabla, sin tabla padre. N° de lote es texto libre (no FK): en el
-- papel real corresponde al lote de materia prima que pasa por el tamiz en
-- ese momento, no al lote de envasado de planta.
-- =============================================================================

CREATE TABLE public.plant_sieve_monitoring_caes (
  id                   uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id       uuid        NOT NULL,
  monitoring_date      date        NOT NULL,
  lote_code            text,
  sin_abolladuras      boolean     NOT NULL DEFAULT true,
  sin_fisuras          boolean     NOT NULL DEFAULT true,
  sin_desgaste         boolean     NOT NULL DEFAULT true,
  sin_deformaciones    boolean     NOT NULL DEFAULT true,
  sin_obstrucciones    boolean     NOT NULL DEFAULT true,
  hubo_desviacion      boolean     NOT NULL DEFAULT false,
  causa_raiz           text,
  acciones_correctivas text,
  created_by           uuid        NOT NULL,
  created_at           timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_sieve_monitoring_caes_pkey PRIMARY KEY (id),
  CONSTRAINT psmc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT psmc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id)
);

CREATE INDEX idx_psmc_cooperative_date ON public.plant_sieve_monitoring_caes (cooperative_id, monitoring_date DESC);

ALTER TABLE public.plant_sieve_monitoring_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "psmc_select"
  ON public.plant_sieve_monitoring_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "psmc_insert"
  ON public.plant_sieve_monitoring_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "psmc_update"
  ON public.plant_sieve_monitoring_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "psmc_delete"
  ON public.plant_sieve_monitoring_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_sieve_monitoring_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_sieve_monitoring_caes TO service_role;
