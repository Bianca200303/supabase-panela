-- =============================================================================
-- Control del Programa de Limpieza y Sanitización de Equipos - Utensilios
-- (SIG-GIA-RG-003).
--
-- Registro MENSUAL de planta (no depende de ninguna orden/lote, mismo
-- criterio que Ambientes -- ver 20260727150000_create_cleaning_ambientes_control.sql
-- e Higiene de Personal -- 20260727100000_replace_hygiene_personnel_control.sql):
-- 1 control por (año, mes), con un check por (área, equipo, día).
--
-- A diferencia de Ambientes (que separa limpieza/sanitización por elemento),
-- acá cada equipo lleva UN solo chequeo por día (correcto/no correcto), pero
-- además registra qué producto(s) se usaron (H: Hipoclorito de sodio 7.5%,
-- A: Alcohol 70%, D: Detergente Industrial -- pueden combinarse, ej. "DH" en
-- el papel real). La lista de áreas/equipos es fija en código (ver
-- EQUIPMENT_CLEANING_AREAS en formatoUtils.js), no configurable como las
-- áreas de Ambientes.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. plant_equipment_cleaning_controls -- 1 por (año, mes)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_equipment_cleaning_controls (
  id                  uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id      uuid        NOT NULL,
  year                integer     NOT NULL,
  month               integer     NOT NULL CHECK (month BETWEEN 1 AND 12),
  responsible_person  text,
  observations        text,
  created_by          uuid        NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_equipment_cleaning_controls_pkey PRIMARY KEY (id),
  CONSTRAINT pecc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pecc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT pecc_unique_year_month UNIQUE (cooperative_id, year, month)
);

CREATE INDEX idx_pecc_cooperative_year_month ON public.plant_equipment_cleaning_controls (cooperative_id, year DESC, month DESC);

ALTER TABLE public.plant_equipment_cleaning_controls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pecc_select"
  ON public.plant_equipment_cleaning_controls AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pecc_insert"
  ON public.plant_equipment_cleaning_controls AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pecc_update"
  ON public.plant_equipment_cleaning_controls AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pecc_delete"
  ON public.plant_equipment_cleaning_controls AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_equipment_cleaning_controls TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_equipment_cleaning_controls TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_equipment_cleaning_checks -- 1 marca por (área, equipo, día)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_equipment_cleaning_checks (
  id          uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id  uuid    NOT NULL,
  area        text    NOT NULL,
  equipment   text    NOT NULL,
  day         integer NOT NULL CHECK (day BETWEEN 1 AND 31),
  status      text    NOT NULL CHECK (status IN ('correcto', 'no_correcto')),
  products    text[]  NOT NULL DEFAULT '{}',

  CONSTRAINT plant_equipment_cleaning_checks_pkey PRIMARY KEY (id),
  CONSTRAINT pecch_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_equipment_cleaning_controls(id) ON DELETE CASCADE,
  -- Productos válidos: H (Hipoclorito de sodio 7.5%), A (Alcohol 70%), D (Detergente Industrial).
  CONSTRAINT pecch_products_valid CHECK (products <@ ARRAY['H', 'A', 'D']::text[]),
  CONSTRAINT pecch_unique_cell UNIQUE (control_id, area, equipment, day)
);

CREATE INDEX idx_pecch_control ON public.plant_equipment_cleaning_checks (control_id);

ALTER TABLE public.plant_equipment_cleaning_checks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pecch_select"
  ON public.plant_equipment_cleaning_checks AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_equipment_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pecch_insert"
  ON public.plant_equipment_cleaning_checks AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_equipment_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pecch_update"
  ON public.plant_equipment_cleaning_checks AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_equipment_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_equipment_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pecch_delete"
  ON public.plant_equipment_cleaning_checks AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_equipment_cleaning_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_equipment_cleaning_checks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_equipment_cleaning_checks TO service_role;
