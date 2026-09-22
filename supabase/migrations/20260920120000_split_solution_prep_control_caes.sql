-- =============================================================================
-- Control de Preparación de Soluciones CAES (CAESP-PP-HYS-RE-HYS-003) --
-- rediseño a cabecera + N filas. Identidad de la cabecera = (cooperativa,
-- fecha, "Preparación de") -- en una misma fecha puede haber más de un
-- control si son tipos de solución distintos (ej. Hipoclorito de Sodio Y
-- Detergente el mismo día son 2 controles separados), pero varias
-- preparaciones del MISMO tipo en la MISMA fecha son filas de un mismo
-- control. Confirmado con el usuario 2026-09-20 tras 2 vueltas erradas
-- (cabecera solo por "Preparación de" sin fecha, y luego cabecera solo por
-- fecha sin "Preparación de").
--
-- Responsable de preparación pasa a personnel_id (FK a plant_personnel,
-- desplegable) -- antes era texto libre.
--
-- Sin usuarios en producción todavía -- se elimina la tabla anterior
-- directamente, sin preservar sus datos de prueba.
-- =============================================================================

DROP TABLE IF EXISTS public.plant_solution_prep_control_caes;

-- -----------------------------------------------------------------------------
-- 1. plant_solution_prep_controls_caes -- 1 por (cooperativa, fecha, tipo)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_solution_prep_controls_caes (
  id              uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id  uuid        NOT NULL,
  control_date    date        NOT NULL,
  preparacion_de  text,
  created_by      uuid        NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_solution_prep_controls_caes_pkey PRIMARY KEY (id),
  CONSTRAINT pspcc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pspcc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT pspcc_unique_date_tipo UNIQUE (cooperative_id, control_date, preparacion_de)
);

CREATE INDEX idx_pspcc_cooperative_date ON public.plant_solution_prep_controls_caes (cooperative_id, control_date DESC);

ALTER TABLE public.plant_solution_prep_controls_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pspcc_select"
  ON public.plant_solution_prep_controls_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pspcc_insert"
  ON public.plant_solution_prep_controls_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pspcc_update"
  ON public.plant_solution_prep_controls_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pspcc_delete"
  ON public.plant_solution_prep_controls_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_solution_prep_controls_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_solution_prep_controls_caes TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_solution_prep_events_caes -- N filas (1 por preparación) por control
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_solution_prep_events_caes (
  id                    uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id            uuid    NOT NULL,
  personnel_id          uuid    NOT NULL,
  concentracion_insumo  text,
  cantidad_insumo       text,
  resultado_volumen     text,
  concentracion_final   text,
  destino_uso           text,

  CONSTRAINT plant_solution_prep_events_caes_pkey PRIMARY KEY (id),
  CONSTRAINT pspec_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_solution_prep_controls_caes(id) ON DELETE CASCADE,
  CONSTRAINT pspec_personnel_fkey
    FOREIGN KEY (personnel_id) REFERENCES public.plant_personnel(id)
);

CREATE INDEX idx_pspec_control ON public.plant_solution_prep_events_caes (control_id);

ALTER TABLE public.plant_solution_prep_events_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pspec_select"
  ON public.plant_solution_prep_events_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_solution_prep_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pspec_insert"
  ON public.plant_solution_prep_events_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_solution_prep_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pspec_update"
  ON public.plant_solution_prep_events_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_solution_prep_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_solution_prep_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pspec_delete"
  ON public.plant_solution_prep_events_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_solution_prep_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_solution_prep_events_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_solution_prep_events_caes TO service_role;
