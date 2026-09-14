-- =============================================================================
-- Control de Sellado, Envasado y Empaque de Producto Terminado
-- (CAESP-PP-BPM-RE-CPR-003) -- SOLO CAES, control nuevo de Fase 2 (ver
-- COOPERATIVE.features.controlesPlantaCAES en lib/config.js), sin
-- equivalente en Norandino.
--
-- Registro plano igual criterio que Monitoreo del Tamizado (CPR-002, ver
-- 20260913170000_create_tamizado_monitoring_caes.sql): cada fila es una
-- inspección de un lote/presentación en una fecha+hora, sin cabecera de
-- "control" que agrupe varias filas. 6 evaluaciones C/NC fijas (materias
-- extrañas, sellado/costura, peso completo, fecha de vencimiento completa
-- y legible, N° lote completo y legible, limpieza e integridad de envase).
-- =============================================================================

CREATE TABLE public.plant_packaging_seal_control_caes (
  id                     uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id         uuid        NOT NULL,
  control_date           date        NOT NULL,
  control_time           time,
  presentacion           text,
  lote_code              text,
  destino                text        CHECK (destino IN ('nacional', 'exportacion')),
  cliente                text,
  materias_extranas_ok   boolean     NOT NULL DEFAULT true,
  sellado_costura_ok     boolean     NOT NULL DEFAULT true,
  peso_completo_ok       boolean     NOT NULL DEFAULT true,
  fecha_vencimiento_ok   boolean     NOT NULL DEFAULT true,
  lote_legible_ok        boolean     NOT NULL DEFAULT true,
  limpieza_envase_ok     boolean     NOT NULL DEFAULT true,
  observaciones          text,
  acciones_correctivas   text,
  created_by             uuid        NOT NULL,
  created_at             timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_packaging_seal_control_caes_pkey PRIMARY KEY (id),
  CONSTRAINT ppscc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT ppscc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id)
);

CREATE INDEX idx_ppscc_cooperative_date ON public.plant_packaging_seal_control_caes (cooperative_id, control_date DESC);

ALTER TABLE public.plant_packaging_seal_control_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ppscc_select"
  ON public.plant_packaging_seal_control_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "ppscc_insert"
  ON public.plant_packaging_seal_control_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "ppscc_update"
  ON public.plant_packaging_seal_control_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "ppscc_delete"
  ON public.plant_packaging_seal_control_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_packaging_seal_control_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_packaging_seal_control_caes TO service_role;
