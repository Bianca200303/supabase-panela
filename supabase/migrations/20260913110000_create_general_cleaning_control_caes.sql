-- =============================================================================
-- Control de Limpieza (CAESP-PP-HYS-RE-HYS-001) -- SOLO CAES.
--
-- El papel real de CAES fusiona en UN registro lo que en Norandino son dos
-- controles separados: Limpieza de Ambientes (superficies físicas) y
-- Limpieza de Equipos - Utensilios (equipos puntuales) -- ver
-- COOPERATIVE.features.limpiezaUnificada en lib/config.js. Misma área puede
-- mezclar ítems físicos (paredes/pisos/techo) con equipos (ej. "Bunques",
-- "Balanza plataforma" en el área "Tamizado, Homogenizado y Envasado").
--
-- Registro MENSUAL de planta (mismo criterio que Ambientes/Equipos de
-- Norandino, ver 20260727150000/20260731100000): 1 control por (año, mes),
-- con un check por (área, ítem, día). A diferencia de Equipos, acá NO se
-- captura producto por celda -- el papel real trae el tipo de limpieza
-- (Diaria/General/Profunda) y el producto aplicable (Cloro/Detergente/
-- Alcohol) como metadata FIJA de cada ítem del catálogo (ver
-- limpieza_general_areas en formConfig.js), no como dato diario -- por eso
-- la grilla acá es un solo check por día, igual que los ítems "Otros" de
-- Equipos.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. plant_general_cleaning_controls -- 1 por (año, mes)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_general_cleaning_controls (
  id                  uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id      uuid        NOT NULL,
  year                integer     NOT NULL,
  month               integer     NOT NULL CHECK (month BETWEEN 1 AND 12),
  responsible_person  text,
  observations        text,
  created_by          uuid        NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_general_cleaning_controls_pkey PRIMARY KEY (id),
  CONSTRAINT pgcc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pgcc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT pgcc_unique_year_month UNIQUE (cooperative_id, year, month)
);

CREATE INDEX idx_pgcc_cooperative_year_month ON public.plant_general_cleaning_controls (cooperative_id, year DESC, month DESC);

ALTER TABLE public.plant_general_cleaning_controls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pgcc_select"
  ON public.plant_general_cleaning_controls AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pgcc_insert"
  ON public.plant_general_cleaning_controls AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pgcc_update"
  ON public.plant_general_cleaning_controls AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pgcc_delete"
  ON public.plant_general_cleaning_controls AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_general_cleaning_controls TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_general_cleaning_controls TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_general_cleaning_checks -- 1 marca por (área, ítem, día)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_general_cleaning_checks (
  id          uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id  uuid    NOT NULL,
  area        text    NOT NULL,
  item        text    NOT NULL,
  day         integer NOT NULL CHECK (day BETWEEN 1 AND 31),
  status      text    NOT NULL CHECK (status IN ('correcto', 'no_correcto')),

  CONSTRAINT plant_general_cleaning_checks_pkey PRIMARY KEY (id),
  CONSTRAINT pgcch_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_general_cleaning_controls(id) ON DELETE CASCADE,
  CONSTRAINT pgcch_unique_cell UNIQUE (control_id, area, item, day)
);

CREATE INDEX idx_pgcch_control ON public.plant_general_cleaning_checks (control_id);

ALTER TABLE public.plant_general_cleaning_checks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pgcch_select"
  ON public.plant_general_cleaning_checks AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_general_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pgcch_insert"
  ON public.plant_general_cleaning_checks AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_general_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pgcch_update"
  ON public.plant_general_cleaning_checks AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_general_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_general_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pgcch_delete"
  ON public.plant_general_cleaning_checks AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_general_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_general_cleaning_checks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_general_cleaning_checks TO service_role;
