-- =============================================================================
-- Lavado de Manos CAES (CAESP-PP-HYS-RE-HSP-004) -- rediseño a cabecera + N
-- filas, mismo patrón que Control de Consumo de Cloro CAES
-- (20260913120000_create_chlorine_control_caes.sql): 1 control por
-- (cooperativa, fecha) -- Área/Hora inicio/Hora fin son datos de la SESIÓN,
-- compartidos -- con varias personas evaluadas ese mismo día (aclarado por
-- el usuario 2026-09-20: "en esa fecha hay más de una persona evaluada").
-- Reemplaza el diseño anterior (plant_handwashing_control_caes, 1 fila =
-- 1 persona con Área/Hora repetidos en cada fila).
--
-- De paso, 2 mejoras ya decididas:
-- 1. "Nombre y Apellidos (texto, de una lista de personal)" -- pasa a
--    personnel_id (FK a plant_personnel), mismo catálogo y mismo patrón que
--    ya usa Higiene de Personal CAES.
-- 2. R1-R5 nullable (para poder marcar "No aplica" si esa revisión no
--    ocurrió) pero con DEFAULT true -- arrancan en Conforme, mismo criterio
--    de "arranca en bueno" que el resto de los checklists de la app.
--
-- Sin usuarios en producción todavía -- se elimina la tabla anterior
-- directamente, sin preservar sus datos de prueba.
-- =============================================================================

DROP TABLE IF EXISTS public.plant_handwashing_control_caes;

-- -----------------------------------------------------------------------------
-- 1. plant_handwashing_controls_caes -- 1 por (cooperativa, fecha)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_handwashing_controls_caes (
  id              uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id  uuid        NOT NULL,
  control_date    date        NOT NULL,
  area            text,
  hora_inicio     time,
  hora_fin        time,
  observaciones   text,
  created_by      uuid        NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_handwashing_controls_caes_pkey PRIMARY KEY (id),
  CONSTRAINT phwcc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT phwcc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT phwcc_unique_date UNIQUE (cooperative_id, control_date)
);

CREATE INDEX idx_phwcc_cooperative_date ON public.plant_handwashing_controls_caes (cooperative_id, control_date DESC);

ALTER TABLE public.plant_handwashing_controls_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "phwcc_select"
  ON public.plant_handwashing_controls_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "phwcc_insert"
  ON public.plant_handwashing_controls_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "phwcc_update"
  ON public.plant_handwashing_controls_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "phwcc_delete"
  ON public.plant_handwashing_controls_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_handwashing_controls_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_handwashing_controls_caes TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_handwashing_person_checks_caes -- N filas (1 por persona) por control
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_handwashing_person_checks_caes (
  id             uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id     uuid    NOT NULL,
  personnel_id   uuid    NOT NULL,
  r1             boolean DEFAULT true,
  r2             boolean DEFAULT true,
  r3             boolean DEFAULT true,
  r4             boolean DEFAULT true,
  r5             boolean DEFAULT true,
  observaciones  text,

  CONSTRAINT plant_handwashing_person_checks_caes_pkey PRIMARY KEY (id),
  CONSTRAINT phwpc_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_handwashing_controls_caes(id) ON DELETE CASCADE,
  CONSTRAINT phwpc_personnel_fkey
    FOREIGN KEY (personnel_id) REFERENCES public.plant_personnel(id),
  CONSTRAINT phwpc_unique_person UNIQUE (control_id, personnel_id)
);

CREATE INDEX idx_phwpc_control ON public.plant_handwashing_person_checks_caes (control_id);

ALTER TABLE public.plant_handwashing_person_checks_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "phwpc_select"
  ON public.plant_handwashing_person_checks_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_handwashing_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "phwpc_insert"
  ON public.plant_handwashing_person_checks_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_handwashing_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "phwpc_update"
  ON public.plant_handwashing_person_checks_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_handwashing_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_handwashing_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "phwpc_delete"
  ON public.plant_handwashing_person_checks_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_handwashing_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_handwashing_person_checks_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_handwashing_person_checks_caes TO service_role;
