-- =============================================================================
-- Verificación del Programa de Limpieza y Sanitización (SIG-GIA-RG-009).
--
-- Registro por FECHA exacta (no mensual como Ambientes/Equipos -- ver
-- 20260727150000_create_cleaning_ambientes_control.sql y
-- 20260731100000_create_cleaning_equipment_control.sql), independiente de
-- cualquier orden/lote (mismo criterio que Higiene de Personal -- ver
-- 20260727100000_replace_hygiene_personnel_control.sql). 1 control por
-- (cooperativa, fecha) -- a diferencia de Higiene, acá no hay turno/área en
-- el control: es una sola auditoría de planta completa por fecha, hecha por
-- el Coordinador SIG / Supervisor.
--
-- Es una auditoría general que combina en un solo formulario lo que
-- Ambientes (estructura física) y Equipos (equipos puntuales) cubren por
-- separado, más personal, plagas y residuos -- 11 áreas, ~80 ítems fijos en
-- código (ver CLEANING_VERIFICATION_AREAS en formatoUtils.js). Confirmado
-- con el usuario: es tabla independiente, sin relación con
-- plant_cleaning_checks ni plant_equipment_cleaning_checks aunque el nombre
-- de varias áreas/ítems coincida -- son auditorías distintas con su propio
-- código de formato.
--
-- A diferencia de Ambientes/Equipos, cada ítem lleva una sola condición
-- (correcto/no correcto, sin producto ni limpieza/sanitización separada)
-- MÁS una "acción correctiva" en texto libre por ítem.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. plant_cleaning_verification_controls -- 1 por (cooperativa, fecha)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_cleaning_verification_controls (
  id                  uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id      uuid        NOT NULL,
  control_date        date        NOT NULL,
  responsible_person  text,
  observations        text,
  created_by          uuid        NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_cleaning_verification_controls_pkey PRIMARY KEY (id),
  CONSTRAINT pcvc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pcvc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT pcvc_unique_date UNIQUE (cooperative_id, control_date)
);

CREATE INDEX idx_pcvc_cooperative_date ON public.plant_cleaning_verification_controls (cooperative_id, control_date DESC);

ALTER TABLE public.plant_cleaning_verification_controls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pcvc_select"
  ON public.plant_cleaning_verification_controls AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pcvc_insert"
  ON public.plant_cleaning_verification_controls AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pcvc_update"
  ON public.plant_cleaning_verification_controls AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pcvc_delete"
  ON public.plant_cleaning_verification_controls AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_cleaning_verification_controls TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_cleaning_verification_controls TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_cleaning_verification_checks -- 1 marca por (área, ítem)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_cleaning_verification_checks (
  id                 uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id         uuid    NOT NULL,
  area               text    NOT NULL,
  item               text    NOT NULL,
  status             text    NOT NULL CHECK (status IN ('correcto', 'no_correcto')),
  corrective_action  text,

  CONSTRAINT plant_cleaning_verification_checks_pkey PRIMARY KEY (id),
  CONSTRAINT pcvch_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_cleaning_verification_controls(id) ON DELETE CASCADE,
  CONSTRAINT pcvch_unique_cell UNIQUE (control_id, area, item)
);

CREATE INDEX idx_pcvch_control ON public.plant_cleaning_verification_checks (control_id);

ALTER TABLE public.plant_cleaning_verification_checks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pcvch_select"
  ON public.plant_cleaning_verification_checks AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_cleaning_verification_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcvch_insert"
  ON public.plant_cleaning_verification_checks AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_cleaning_verification_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcvch_update"
  ON public.plant_cleaning_verification_checks AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_cleaning_verification_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_cleaning_verification_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcvch_delete"
  ON public.plant_cleaning_verification_checks AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_cleaning_verification_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_cleaning_verification_checks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_cleaning_verification_checks TO service_role;
