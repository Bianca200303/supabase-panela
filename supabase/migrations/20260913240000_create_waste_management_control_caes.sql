-- =============================================================================
-- Manejo de Residuos (CAESP-PP-HYS-RE-MDR-001) -- SOLO CAES, control nuevo
-- de Fase 2 (ver COOPERATIVE.features.controlesPlantaCAES en
-- lib/config.js), sin equivalente en Norandino. Último de los 8 controles
-- nuevos de Fase 2.
--
-- Registro plano por (fecha, hora), mismo criterio que los demás controles
-- nuevos de Fase 2. Clasificación de residuo: 4 checks no excluyentes
-- (puede ser más de uno por evento de recojo).
-- =============================================================================

CREATE TABLE public.plant_waste_management_caes (
  id                            uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id                uuid        NOT NULL,
  control_date                  date        NOT NULL,
  control_time                  time,
  es_organico                   boolean     NOT NULL DEFAULT false,
  es_aprovechable                boolean     NOT NULL DEFAULT false,
  es_no_aprovechable            boolean     NOT NULL DEFAULT false,
  es_peligroso                  boolean     NOT NULL DEFAULT false,
  origen_residuo                text,
  cantidad_bolsas                integer,
  disposicion_recolector_municipal boolean  NOT NULL DEFAULT false,
  disposicion_otro              text,
  observacion                   text,
  created_by                    uuid        NOT NULL,
  created_at                    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_waste_management_caes_pkey PRIMARY KEY (id),
  CONSTRAINT pwmc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pwmc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id)
);

CREATE INDEX idx_pwmc_cooperative_date ON public.plant_waste_management_caes (cooperative_id, control_date DESC);

ALTER TABLE public.plant_waste_management_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pwmc_select"
  ON public.plant_waste_management_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pwmc_insert"
  ON public.plant_waste_management_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pwmc_update"
  ON public.plant_waste_management_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pwmc_delete"
  ON public.plant_waste_management_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_waste_management_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_waste_management_caes TO service_role;
