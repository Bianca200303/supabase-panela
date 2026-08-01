-- =============================================================================
-- Control de Cloro Residual (SIG-GIA-RG-001).
--
-- Registro por FECHA exacta, independiente de cualquier orden/lote (mismo
-- criterio que Higiene de Personal y Verificación de Limpieza -- ver
-- 20260727100000_replace_hygiene_personnel_control.sql y
-- 20260731120000_create_cleaning_verification_control.sql). 1 control por
-- (cooperativa, fecha), con un resultado por cada uno de los 3 puntos de
-- control fijos de la planta (P1: Aduana Sanitaria, P2: Laboratorio, P3:
-- Área de Envasado -- ver CHLORINE_RESIDUAL_POINTS en formatoUtils.js).
--
-- A diferencia de los controles de limpieza (Ambientes/Equipos/Verificación,
-- que marcan correcto/no correcto), acá el dato es una MEDICIÓN NUMÉRICA
-- (ppm de cloro libre residual), con un límite mínimo de referencia de
-- 0.5ppm (validación solo visual en la UI, no constraint en BD -- una
-- medición fuera de rango sigue siendo un dato real que hay que poder
-- guardar). Es tabla independiente del FCCLR ("Formato de Control de Cloro
-- Libre Residual") que ya existe para módulos de productores en campo --
-- mismo patrón que FLDH vs. Ambientes/Equipos: mismo concepto, dos
-- formatos físicos distintos, sin relación entre sí.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. plant_chlorine_residual_controls -- 1 por (cooperativa, fecha)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_chlorine_residual_controls (
  id                  uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id      uuid        NOT NULL,
  control_date        date        NOT NULL,
  responsible_person  text,
  created_by          uuid        NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_chlorine_residual_controls_pkey PRIMARY KEY (id),
  CONSTRAINT pcrc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pcrc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT pcrc_unique_date UNIQUE (cooperative_id, control_date)
);

CREATE INDEX idx_pcrc_cooperative_date ON public.plant_chlorine_residual_controls (cooperative_id, control_date DESC);

ALTER TABLE public.plant_chlorine_residual_controls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pcrc_select"
  ON public.plant_chlorine_residual_controls AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pcrc_insert"
  ON public.plant_chlorine_residual_controls AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pcrc_update"
  ON public.plant_chlorine_residual_controls AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pcrc_delete"
  ON public.plant_chlorine_residual_controls AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_chlorine_residual_controls TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_chlorine_residual_controls TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_chlorine_residual_checks -- 1 medición por (control, punto)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_chlorine_residual_checks (
  id                 uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id         uuid    NOT NULL,
  point_code         text    NOT NULL CHECK (point_code IN ('p1', 'p2', 'p3')),
  result_ppm         numeric(5,2),
  observations       text,
  corrective_action  text,

  CONSTRAINT plant_chlorine_residual_checks_pkey PRIMARY KEY (id),
  CONSTRAINT pcrch_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_chlorine_residual_controls(id) ON DELETE CASCADE,
  CONSTRAINT pcrch_unique_point UNIQUE (control_id, point_code)
);

CREATE INDEX idx_pcrch_control ON public.plant_chlorine_residual_checks (control_id);

ALTER TABLE public.plant_chlorine_residual_checks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pcrch_select"
  ON public.plant_chlorine_residual_checks AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_chlorine_residual_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcrch_insert"
  ON public.plant_chlorine_residual_checks AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_chlorine_residual_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcrch_update"
  ON public.plant_chlorine_residual_checks AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_chlorine_residual_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_chlorine_residual_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pcrch_delete"
  ON public.plant_chlorine_residual_checks AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_chlorine_residual_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_chlorine_residual_checks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_chlorine_residual_checks TO service_role;
