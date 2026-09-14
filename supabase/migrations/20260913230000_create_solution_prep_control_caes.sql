-- =============================================================================
-- Control de Preparación de Soluciones (CAESP-PP-HYS-RE-HYS-003) -- SOLO
-- CAES, control nuevo de Fase 2 (ver
-- COOPERATIVE.features.controlesPlantaCAES en lib/config.js), sin
-- equivalente en Norandino.
--
-- Registro plano por (fecha, preparación), mismo criterio que los demás
-- controles nuevos de Fase 2. Concentración/cantidad/resultado quedan en
-- texto libre (combinan número+unidad de forma no uniforme en el papel
-- real: "7.5%", "26.67ml", "20L", "100ppm") -- mismo criterio que otros
-- campos similares de esta sesión (Cloro Residual CAES).
-- =============================================================================

CREATE TABLE public.plant_solution_prep_control_caes (
  id                      uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id          uuid        NOT NULL,
  control_date            date        NOT NULL,
  preparacion_de          text,
  concentracion_insumo    text,
  cantidad_insumo         text,
  resultado_volumen       text,
  concentracion_final     text,
  responsable             text,
  destino_uso             text,
  created_by              uuid        NOT NULL,
  created_at              timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_solution_prep_control_caes_pkey PRIMARY KEY (id),
  CONSTRAINT pspcc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pspcc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id)
);

CREATE INDEX idx_pspcc_cooperative_date ON public.plant_solution_prep_control_caes (cooperative_id, control_date DESC);

ALTER TABLE public.plant_solution_prep_control_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pspcc_select"
  ON public.plant_solution_prep_control_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pspcc_insert"
  ON public.plant_solution_prep_control_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pspcc_update"
  ON public.plant_solution_prep_control_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pspcc_delete"
  ON public.plant_solution_prep_control_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_solution_prep_control_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_solution_prep_control_caes TO service_role;
