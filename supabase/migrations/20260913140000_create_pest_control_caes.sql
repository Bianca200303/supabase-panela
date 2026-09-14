-- =============================================================================
-- Control de Roedores e Insectos (CAESP-PP-HYS-RE-CDP-001) -- SOLO CAES, ver
-- COOPERATIVE.features.plagasEventosMensuales en lib/config.js.
--
-- El papel real de CAES NO es "1 control por fecha exacta con catálogo fijo
-- de dispositivos" como Control de Plagas de Norandino
-- (plant_pest_controls, ver 20260902100000_create_warehouse_control_and_pest_ambientes.sql,
-- que CAES no usa). Es un registro MENSUAL con dos listas de eventos
-- (trampas de roedores T1-T7, insectocutores I01+) -- cada trampa/
-- insectocutor se evalúa varias veces durante el mes en fechas distintas
-- (mismo espíritu que Cloro Residual de CAES: N filas libres, no una
-- grilla), con su propio producto/cebo y cantidad como cabecera del
-- control. Especies de insectos: solo 3 (Mo=Moscas, A=Abejas, Ma=Mariposas),
-- muy distinto de las 10 especies de Norandino.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. plant_pest_controls_caes -- 1 por (año, mes)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_pest_controls_caes (
  id                    uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id        uuid        NOT NULL,
  year                  integer     NOT NULL,
  month                 integer     NOT NULL CHECK (month BETWEEN 1 AND 12),
  cebo_producto         text,
  cebo_cantidad         text,
  insecto_producto      text,
  insecto_cantidad      text,
  responsible_person    text,
  observations          text,
  formato_codigo        text UNIQUE,
  created_by            uuid        NOT NULL,
  created_at            timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_pest_controls_caes_pkey PRIMARY KEY (id),
  CONSTRAINT ppcc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT ppcc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT ppcc_unique_year_month UNIQUE (cooperative_id, year, month)
);

CREATE INDEX idx_ppcc_cooperative_year_month ON public.plant_pest_controls_caes (cooperative_id, year DESC, month DESC);

ALTER TABLE public.plant_pest_controls_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ppcc_select"
  ON public.plant_pest_controls_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "ppcc_insert"
  ON public.plant_pest_controls_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "ppcc_update"
  ON public.plant_pest_controls_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "ppcc_delete"
  ON public.plant_pest_controls_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_pest_controls_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_pest_controls_caes TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_pest_rodent_events_caes -- N evaluaciones de trampa por control
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_pest_rodent_events_caes (
  id            uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id    uuid    NOT NULL,
  trap_code     text    NOT NULL,
  event_date    date,
  trap_active   boolean,
  estado        text[]  NOT NULL DEFAULT '{}',
  observations  text,

  CONSTRAINT plant_pest_rodent_events_caes_pkey PRIMARY KEY (id),
  CONSTRAINT pprec_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_pest_controls_caes(id) ON DELETE CASCADE,
  -- Estado de trampa: S.C. (sin consumo), C.P. (consumo parcial), C.T. (consumo total), DET. (deteriorada).
  CONSTRAINT pprec_estado_valid CHECK (estado <@ ARRAY['sc', 'cp', 'ct', 'det']::text[])
);

CREATE INDEX idx_pprec_control ON public.plant_pest_rodent_events_caes (control_id);

ALTER TABLE public.plant_pest_rodent_events_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pprec_select"
  ON public.plant_pest_rodent_events_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_pest_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pprec_insert"
  ON public.plant_pest_rodent_events_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_pest_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pprec_update"
  ON public.plant_pest_rodent_events_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_pest_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_pest_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pprec_delete"
  ON public.plant_pest_rodent_events_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_pest_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_pest_rodent_events_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_pest_rodent_events_caes TO service_role;

-- -----------------------------------------------------------------------------
-- 3. plant_pest_insect_events_caes -- N evaluaciones de insectocutor por control
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_pest_insect_events_caes (
  id                 uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id         uuid    NOT NULL,
  insectocutor_code  text    NOT NULL,
  area               text,
  event_date         date,
  species            text[]  NOT NULL DEFAULT '{}',
  observations       text,

  CONSTRAINT plant_pest_insect_events_caes_pkey PRIMARY KEY (id),
  CONSTRAINT ppiec_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_pest_controls_caes(id) ON DELETE CASCADE,
  -- Especies: Mo (moscas), A (abejas), Ma (mariposas).
  CONSTRAINT ppiec_species_valid CHECK (species <@ ARRAY['mo', 'a', 'ma']::text[])
);

CREATE INDEX idx_ppiec_control ON public.plant_pest_insect_events_caes (control_id);

ALTER TABLE public.plant_pest_insect_events_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ppiec_select"
  ON public.plant_pest_insect_events_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_pest_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "ppiec_insert"
  ON public.plant_pest_insect_events_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_pest_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "ppiec_update"
  ON public.plant_pest_insect_events_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_pest_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_pest_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "ppiec_delete"
  ON public.plant_pest_insect_events_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_pest_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_pest_insect_events_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_pest_insect_events_caes TO service_role;

-- -----------------------------------------------------------------------------
-- 4. Código correlativo -- mismo mecanismo que los otros controles CAES.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_pest_control_caes_code(p_cooperative_id uuid, p_coop_code text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_next_num integer;
BEGIN
  IF NOT public.is_service_role() AND p_cooperative_id IS DISTINCT FROM public.auth_cooperative_id() THEN
    RAISE EXCEPTION 'p_cooperative_id no coincide con la cooperativa del usuario autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-CDP'));
  SELECT COALESCE(MAX(CAST(SPLIT_PART(formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.plant_pest_controls_caes
  WHERE cooperative_id = p_cooperative_id
    AND formato_codigo ~ ('^' || p_coop_code || '-CDP-[0-9]+$');
  RETURN p_coop_code || '-CDP-' || LPAD(v_next_num::text, 4, '0');
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_pest_control_caes_code(uuid, text) TO authenticated;
