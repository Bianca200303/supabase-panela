-- =============================================================================
-- Control de Consumo de Cloro y Verificación de Cloro Residual
-- (CAESP-PP-HYS-RE-CDA-001) -- SOLO CAES, ver
-- COOPERATIVE.features.cloroPreparacionMonitoreo en lib/config.js.
--
-- El papel real de CAES NO es "1 lectura ppm por punto fijo por fecha"
-- como el Cloro Residual de Norandino (plant_chlorine_residual_controls,
-- ver 20260731130000_create_chlorine_residual_control.sql, que CAES no
-- usa). Es un registro por FECHA con DOS listas de eventos independientes,
-- cada una con varias filas por día:
--   1) Preparación/cloración de la solución (hora, concentración deseada,
--      cantidad de agua a clorar, cantidad de cloro a adicionar,
--      responsable de cloración, observaciones).
--   2) Monitoreo del cloro residual en puntos de muestreo -- el punto es
--      TEXTO LIBRE (ej. "Zona de Envasado", "SS.HH."), no un catálogo fijo
--      como en Norandino (hora, punto de muestreo, ppm medido, responsable
--      de medición, acciones correctivas).
--
-- 1 control por (cooperative_id, control_date), igual criterio que
-- Verificación de Limpieza / Plagas / Almacén (formato_codigo propio, ver
-- 20260902110000_add_codigo_to_plant_controls.sql).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. plant_chlorine_controls_caes -- 1 por fecha
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_chlorine_controls_caes (
  id              uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id  uuid        NOT NULL,
  control_date    date        NOT NULL,
  observations    text,
  formato_codigo  text UNIQUE,
  created_by      uuid        NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_chlorine_controls_caes_pkey PRIMARY KEY (id),
  CONSTRAINT pccc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pccc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT pccc_unique_date UNIQUE (cooperative_id, control_date)
);

CREATE INDEX idx_pccc_cooperative_date ON public.plant_chlorine_controls_caes (cooperative_id, control_date DESC);

ALTER TABLE public.plant_chlorine_controls_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pccc_select"
  ON public.plant_chlorine_controls_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pccc_insert"
  ON public.plant_chlorine_controls_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pccc_update"
  ON public.plant_chlorine_controls_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pccc_delete"
  ON public.plant_chlorine_controls_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_chlorine_controls_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_chlorine_controls_caes TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_chlorine_prep_events_caes -- N filas de preparación/cloración por control
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_chlorine_prep_events_caes (
  id                        uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id                uuid    NOT NULL,
  event_time                time,
  concentracion_deseada_ppm numeric,
  cantidad_agua_l           numeric,
  cantidad_cloro_ml         numeric,
  responsable_cloracion     text,
  observations              text,

  CONSTRAINT plant_chlorine_prep_events_caes_pkey PRIMARY KEY (id),
  CONSTRAINT pcpec_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_chlorine_controls_caes(id) ON DELETE CASCADE
);

CREATE INDEX idx_pcpec_control ON public.plant_chlorine_prep_events_caes (control_id);

ALTER TABLE public.plant_chlorine_prep_events_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pcpec_select"
  ON public.plant_chlorine_prep_events_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_chlorine_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcpec_insert"
  ON public.plant_chlorine_prep_events_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_chlorine_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcpec_update"
  ON public.plant_chlorine_prep_events_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_chlorine_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_chlorine_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcpec_delete"
  ON public.plant_chlorine_prep_events_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_chlorine_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_chlorine_prep_events_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_chlorine_prep_events_caes TO service_role;

-- -----------------------------------------------------------------------------
-- 3. plant_chlorine_monitoring_events_caes -- N filas de monitoreo por control
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_chlorine_monitoring_events_caes (
  id                     uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id             uuid    NOT NULL,
  event_time             time,
  sampling_point         text,
  result_ppm             numeric,
  responsable_medicion   text,
  corrective_action      text,

  CONSTRAINT plant_chlorine_monitoring_events_caes_pkey PRIMARY KEY (id),
  CONSTRAINT pcmec_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_chlorine_controls_caes(id) ON DELETE CASCADE
);

CREATE INDEX idx_pcmec_control ON public.plant_chlorine_monitoring_events_caes (control_id);

ALTER TABLE public.plant_chlorine_monitoring_events_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pcmec_select"
  ON public.plant_chlorine_monitoring_events_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_chlorine_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcmec_insert"
  ON public.plant_chlorine_monitoring_events_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_chlorine_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcmec_update"
  ON public.plant_chlorine_monitoring_events_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_chlorine_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_chlorine_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcmec_delete"
  ON public.plant_chlorine_monitoring_events_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_chlorine_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_chlorine_monitoring_events_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_chlorine_monitoring_events_caes TO service_role;

-- -----------------------------------------------------------------------------
-- 4. Código correlativo -- mismo mecanismo que los otros controles por fecha
--    (ver 20260902110000_add_codigo_to_plant_controls.sql).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_chlorine_control_caes_code(p_cooperative_id uuid, p_coop_code text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_next_num integer;
BEGIN
  IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
    RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-CDA'));
  SELECT COALESCE(MAX(CAST(SPLIT_PART(formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.plant_chlorine_controls_caes
  WHERE cooperative_id = p_cooperative_id
    AND formato_codigo ~ ('^' || p_coop_code || '-CDA-[0-9]+$');
  RETURN p_coop_code || '-CDA-' || LPAD(v_next_num::text, 4, '0');
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_chlorine_control_caes_code(uuid, text) TO authenticated;
