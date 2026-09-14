-- =============================================================================
-- Control de Higiene del Personal (CAESP-PP-HYS-RE-HSP-003) -- SOLO CAES, ver
-- COOPERATIVE.features.higieneGrillaMensual en lib/config.js.
--
-- El papel real de CAES NO es "1 control por (fecha, turno, área) con un
-- roster de personal y 9 criterios" como el Control de Salud e Higiene del
-- Personal de Norandino (plant_hygiene_controls, ver
-- 20260727100000_replace_hygiene_personnel_control.sql, que CAES no usa).
-- Es un registro MENSUAL (año, mes, turno) con una grilla persona × ítem ×
-- día del mes (1-31): 8 ítems fijos por persona (vestimenta adecuada, sin
-- maquillaje, uñas cortas y limpias, sin joyas, cabello corto, cabello
-- recogido, afeitado, heridas o cortes descubiertos) -- mismo shape que
-- Limpieza de Equipos (área/equipo × día), con "persona" haciendo de área.
--
-- La zona de trabajo (Tamizado y Homogenizado / Envasado) es un dato de la
-- persona dentro de ESE control (puede cambiar mes a mes), no un catálogo
-- separado -- se guarda repetida en cada fila de check en vez de una tabla
-- de "workers" aparte, mismo criterio flexible que area/equipment de
-- Limpieza de Equipos (columnas de texto, no catálogos rígidos).
--
-- Reusa el catálogo plant_personnel ya existente (Norandino lo usa para su
-- propio Higiene) -- ver HigienePage.jsx para el patrón de roster/alta de
-- personal, reusado en HigienePersonalCaesPage.jsx.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. plant_hygiene_controls_caes -- 1 por (año, mes, turno)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_hygiene_controls_caes (
  id                  uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id      uuid        NOT NULL,
  year                integer     NOT NULL,
  month               integer     NOT NULL CHECK (month BETWEEN 1 AND 12),
  turno               text        NOT NULL CHECK (turno IN ('manana', 'tarde')),
  responsible_person  text,
  observations        text,
  created_by          uuid        NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_hygiene_controls_caes_pkey PRIMARY KEY (id),
  CONSTRAINT phcc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT phcc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT phcc_unique_year_month_turno UNIQUE (cooperative_id, year, month, turno)
);

CREATE INDEX idx_phcc_cooperative_year_month ON public.plant_hygiene_controls_caes (cooperative_id, year DESC, month DESC);

ALTER TABLE public.plant_hygiene_controls_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "phcc_select"
  ON public.plant_hygiene_controls_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "phcc_insert"
  ON public.plant_hygiene_controls_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "phcc_update"
  ON public.plant_hygiene_controls_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "phcc_delete"
  ON public.plant_hygiene_controls_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_hygiene_controls_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_hygiene_controls_caes TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_hygiene_checks_caes -- 1 marca por (persona, ítem, día)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_hygiene_checks_caes (
  id            uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id    uuid    NOT NULL,
  personnel_id  uuid    NOT NULL,
  zona          text    NOT NULL CHECK (zona IN ('tamizado_homogenizado', 'envasado')),
  item          text    NOT NULL CHECK (item IN (
    'vestimenta', 'sin_maquillaje', 'unas_limpias', 'sin_joyas',
    'cabello_corto', 'cabello_recogido', 'afeitado', 'heridas_cortes'
  )),
  day           integer NOT NULL CHECK (day BETWEEN 1 AND 31),
  status        text    NOT NULL CHECK (status IN ('correcto', 'no_correcto')),

  CONSTRAINT plant_hygiene_checks_caes_pkey PRIMARY KEY (id),
  CONSTRAINT phchc_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_hygiene_controls_caes(id) ON DELETE CASCADE,
  CONSTRAINT phchc_personnel_fkey
    FOREIGN KEY (personnel_id) REFERENCES public.plant_personnel(id),
  CONSTRAINT phchc_unique_cell UNIQUE (control_id, personnel_id, item, day)
);

CREATE INDEX idx_phchc_control ON public.plant_hygiene_checks_caes (control_id);

ALTER TABLE public.plant_hygiene_checks_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "phchc_select"
  ON public.plant_hygiene_checks_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_hygiene_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "phchc_insert"
  ON public.plant_hygiene_checks_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_hygiene_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "phchc_update"
  ON public.plant_hygiene_checks_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_hygiene_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_hygiene_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "phchc_delete"
  ON public.plant_hygiene_checks_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_hygiene_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_hygiene_checks_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_hygiene_checks_caes TO service_role;
