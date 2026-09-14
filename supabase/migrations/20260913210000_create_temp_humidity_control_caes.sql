-- =============================================================================
-- Control de Temperatura y Humedad de Ambientes (CAESP-PP-BPM-RE-RMP-003)
-- -- SOLO CAES, control nuevo de Fase 2 (ver
-- COOPERATIVE.features.controlesPlantaCAES en lib/config.js), sin
-- equivalente en Norandino.
--
-- A diferencia de los otros controles planos de Fase 2 (1 fila = 1
-- inspección independiente), acá el papel real agrupa 4 ubicaciones fijas
-- por fecha (Almacén de Materia Prima, Almacén de Producto Terminado,
-- Tamizado/Homogenizado y Envasado, Laboratorio) -- 1 fila por
-- (fecha, ubicación), con UNIQUE para que no se dupliquen. La UI llena las
-- 4 ubicaciones juntas para una misma fecha (ver TempHumedadAmbientesCaesPage.jsx).
-- Promedios (t_promedio, hr_promedio) se calculan en el cliente a partir de
-- T1-T3/HR1-HR3, no se tipean a mano.
-- =============================================================================

CREATE TABLE public.plant_temp_humidity_control_caes (
  id                   uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id       uuid        NOT NULL,
  control_date         date        NOT NULL,
  ubicacion            text        NOT NULL,
  t1                   numeric,
  t2                   numeric,
  t3                   numeric,
  t_promedio           numeric,
  hr1                  numeric,
  hr2                  numeric,
  hr3                  numeric,
  hr_promedio          numeric,
  accion_correctiva    text,
  observaciones        text,
  created_by           uuid        NOT NULL,
  created_at           timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_temp_humidity_control_caes_pkey PRIMARY KEY (id),
  CONSTRAINT pthcc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pthcc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT pthcc_unique_cell UNIQUE (cooperative_id, control_date, ubicacion)
);

CREATE INDEX idx_pthcc_cooperative_date ON public.plant_temp_humidity_control_caes (cooperative_id, control_date DESC);

ALTER TABLE public.plant_temp_humidity_control_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pthcc_select"
  ON public.plant_temp_humidity_control_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pthcc_insert"
  ON public.plant_temp_humidity_control_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pthcc_update"
  ON public.plant_temp_humidity_control_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pthcc_delete"
  ON public.plant_temp_humidity_control_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_temp_humidity_control_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_temp_humidity_control_caes TO service_role;
