-- =============================================================================
-- Verificación Interna de Calibración de Balanzas (CAESP-CC-PP-BPM-RE-MYC-002)
-- -- SOLO CAES, control nuevo de Fase 2 (ver
-- COOPERATIVE.features.controlesPlantaCAES en lib/config.js), sin
-- equivalente en Norandino.
--
-- Registro plano por (fecha, balanza), mismo criterio que los demás
-- controles nuevos de Fase 2. 5 lecturas fijas (P1-P5) con su peso y
-- error/diferencia cada una -- columnas planas en vez de una sub-tabla,
-- porque la cantidad de lecturas es fija (5), no una lista abierta.
-- =============================================================================

CREATE TABLE public.plant_balance_calibration_caes (
  id                       uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id           uuid        NOT NULL,
  control_date             date        NOT NULL,
  balance_code             text,
  area                     text,
  equipment_name           text,
  error_maximo_permitido   text,
  peso_patron              text,
  p1_peso                  numeric,
  p1_error                 numeric,
  p2_peso                  numeric,
  p2_error                 numeric,
  p3_peso                  numeric,
  p3_error                 numeric,
  p4_peso                  numeric,
  p4_error                 numeric,
  p5_peso                  numeric,
  p5_error                 numeric,
  error_promedio           numeric,
  estado                   text        CHECK (estado IN ('conforme', 'no_conforme')),
  acciones_correctivas     text,
  created_by               uuid        NOT NULL,
  created_at               timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_balance_calibration_caes_pkey PRIMARY KEY (id),
  CONSTRAINT pbcc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pbcc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id)
);

CREATE INDEX idx_pbcc_cooperative_date ON public.plant_balance_calibration_caes (cooperative_id, control_date DESC);

ALTER TABLE public.plant_balance_calibration_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pbcc_select"
  ON public.plant_balance_calibration_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pbcc_insert"
  ON public.plant_balance_calibration_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pbcc_update"
  ON public.plant_balance_calibration_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pbcc_delete"
  ON public.plant_balance_calibration_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_balance_calibration_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_balance_calibration_caes TO service_role;
