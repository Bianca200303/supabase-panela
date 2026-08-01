-- =============================================================================
-- Control del Programa de Limpieza y Sanitización de Ambientes (SIG-GIA-RG-002).
--
-- Registro MENSUAL de planta (no depende de ninguna orden/lote, igual
-- criterio que Higiene de Personal -- ver
-- 20260727100000_replace_hygiene_personnel_control.sql): 1 control por
-- (año, mes), con un check por (área, elemento, tipo, día).
--
-- 9 áreas físicas de la planta (Aduana Sanitaria, Oficina Administrativa,
-- Almacenes, Operaciones, Envasado, Laboratorio, Productos Químicos,
-- Servicios Higiénicos, Pasadizos), cada una con 3 elementos: Techos y
-- Paredes, Puertas, Pisos. Techos/Paredes y Puertas solo llevan chequeo de
-- "limpieza"; Pisos lleva "limpieza" Y "sanitización" por separado
-- (confirmado con el usuario -- son 2 controles distintos, no 1).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. plant_cleaning_controls -- 1 por (año, mes)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_cleaning_controls (
  id                  uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id      uuid        NOT NULL,
  year                integer     NOT NULL,
  month               integer     NOT NULL CHECK (month BETWEEN 1 AND 12),
  responsible_person  text,
  observations        text,
  created_by          uuid        NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_cleaning_controls_pkey PRIMARY KEY (id),
  CONSTRAINT pcc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pcc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT pcc_unique_year_month UNIQUE (cooperative_id, year, month)
);

CREATE INDEX idx_pcc_cooperative_year_month ON public.plant_cleaning_controls (cooperative_id, year DESC, month DESC);

ALTER TABLE public.plant_cleaning_controls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pcc_select"
  ON public.plant_cleaning_controls AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pcc_insert"
  ON public.plant_cleaning_controls AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pcc_update"
  ON public.plant_cleaning_controls AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pcc_delete"
  ON public.plant_cleaning_controls AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_cleaning_controls TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_cleaning_controls TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_cleaning_checks -- 1 marca por (área, elemento, tipo, día)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_cleaning_checks (
  id          uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id  uuid    NOT NULL,
  area        text    NOT NULL,
  element     text    NOT NULL CHECK (element IN ('techos_paredes', 'puertas', 'pisos')),
  check_type  text    NOT NULL CHECK (check_type IN ('limpieza', 'sanitizacion')),
  day         integer NOT NULL CHECK (day BETWEEN 1 AND 31),
  status      text    NOT NULL CHECK (status IN ('correcto', 'no_correcto')),

  CONSTRAINT plant_cleaning_checks_pkey PRIMARY KEY (id),
  CONSTRAINT pcch_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_cleaning_controls(id) ON DELETE CASCADE,
  -- Sanitización solo aplica a Pisos -- Techos/Paredes y Puertas solo llevan Limpieza.
  CONSTRAINT pcch_sanitizacion_solo_pisos
    CHECK (check_type = 'limpieza' OR (check_type = 'sanitizacion' AND element = 'pisos')),
  CONSTRAINT pcch_unique_cell UNIQUE (control_id, area, element, check_type, day)
);

CREATE INDEX idx_pcch_control ON public.plant_cleaning_checks (control_id);

ALTER TABLE public.plant_cleaning_checks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pcch_select"
  ON public.plant_cleaning_checks AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcch_insert"
  ON public.plant_cleaning_checks AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcch_update"
  ON public.plant_cleaning_checks AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcch_delete"
  ON public.plant_cleaning_checks AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_cleaning_checks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_cleaning_checks TO service_role;
