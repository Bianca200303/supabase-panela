-- =============================================================================
-- Control de Hermeticidad de Envases (CAESP-PP-BPM-RE-CPR-007) -- SOLO
-- CAES, control nuevo de Fase 2 (ver COOPERATIVE.features.controlesPlantaCAES
-- en lib/config.js), sin equivalente en Norandino.
--
-- Muestreo AQL tipo ISO 2859-1: registro plano, cada fila es una
-- inspección de hermeticidad de un lote en una fecha, mismo criterio que
-- Monitoreo del Tamizado / Sellado-Envasado (sin cabecera de "control").
-- =============================================================================

CREATE TABLE public.plant_container_tightness_control_caes (
  id                     uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id         uuid        NOT NULL,
  control_date           date        NOT NULL,
  lote_code              text,
  tamano_lote            integer,
  nivel_inspeccion       text,
  letra_codigo           text,
  nivel_calidad_aceptable text,
  tamano_muestra         integer,
  numero_aceptacion      integer,
  numero_rechazo         integer,
  producto_conforme      integer,
  producto_no_conforme   integer,
  accion_tomada          text,
  acciones_correctivas   text,
  created_by             uuid        NOT NULL,
  created_at             timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_container_tightness_control_caes_pkey PRIMARY KEY (id),
  CONSTRAINT pctcc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pctcc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id)
);

CREATE INDEX idx_pctcc_cooperative_date ON public.plant_container_tightness_control_caes (cooperative_id, control_date DESC);

ALTER TABLE public.plant_container_tightness_control_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pctcc_select"
  ON public.plant_container_tightness_control_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pctcc_insert"
  ON public.plant_container_tightness_control_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pctcc_update"
  ON public.plant_container_tightness_control_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pctcc_delete"
  ON public.plant_container_tightness_control_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_container_tightness_control_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_container_tightness_control_caes TO service_role;
