-- =============================================================================
-- Control de Plagas (SIG-GIA-RG-007).
--
-- Registro por FECHA exacta, independiente de cualquier orden/lote (mismo
-- criterio que Higiene/Verificación/Cloro Residual). 1 control por
-- (cooperativa, fecha), con 2 sub-tablas para 2 tipos de dispositivo con
-- esquemas de datos distintos:
--
--   - plant_rodent_trap_checks: Jaulas mecánicas (J13-J18) y Trampas de
--     goma (T21-T26, T31, T32) UNIFICADAS en una sola tabla con
--     `device_type` -- en el papel físico comparten exactamente las mismas
--     columnas (Operatividad, Evidencia SI/NO, Roedores atrapados SI/NO,
--     N° de roedor atrapado, Observaciones, Acción correctiva), solo
--     cambia el tipo de dispositivo.
--   - plant_light_trap_checks: Trampas de luz (6 fijas, cada una con su
--     lugar -- Aduana Sanitaria, Envasado x3, Almacén PT, Almacén MP), con
--     conteo por especie de insecto en 10 columnas fijas (MD, MC, AB, E,
--     P, Z, MQ, AV, L, Otros -- según la leyenda del papel), confirmado
--     con el usuario en vez de normalizar en filas por especie.
--
-- Catálogos fijos en código (ver RODENT_TRAPS/LIGHT_TRAPS/INSECT_SPECIES en
-- formatoUtils.js), mismo criterio que Equipos/Verificación/Cloro Residual.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. plant_pest_controls -- 1 por (cooperativa, fecha)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_pest_controls (
  id                  uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id      uuid        NOT NULL,
  control_date        date        NOT NULL,
  responsible_person  text,
  created_by          uuid        NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_pest_controls_pkey PRIMARY KEY (id),
  CONSTRAINT ppc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT ppc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT ppc_unique_date UNIQUE (cooperative_id, control_date)
);

CREATE INDEX idx_ppc_cooperative_date ON public.plant_pest_controls (cooperative_id, control_date DESC);

ALTER TABLE public.plant_pest_controls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ppc_select"
  ON public.plant_pest_controls AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "ppc_insert"
  ON public.plant_pest_controls AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "ppc_update"
  ON public.plant_pest_controls AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "ppc_delete"
  ON public.plant_pest_controls AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_pest_controls TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_pest_controls TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_rodent_trap_checks -- jaulas mecánicas + trampas de goma
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_rodent_trap_checks (
  id                   uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id           uuid    NOT NULL,
  device_type          text    NOT NULL CHECK (device_type IN ('jaula', 'trampa_goma')),
  device_code          text    NOT NULL,
  operatividad         text    CHECK (operatividad IN ('operativo', 'no_operativo')),
  evidencia            text    CHECK (evidencia IN ('si', 'no')),
  atrapados            text    CHECK (atrapados IN ('si', 'no')),
  cantidad_atrapada    integer CHECK (cantidad_atrapada >= 0),
  observations         text,
  corrective_action    text,

  CONSTRAINT plant_rodent_trap_checks_pkey PRIMARY KEY (id),
  CONSTRAINT prtc_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_pest_controls(id) ON DELETE CASCADE,
  CONSTRAINT prtc_unique_device UNIQUE (control_id, device_type, device_code)
);

CREATE INDEX idx_prtc_control ON public.plant_rodent_trap_checks (control_id);

ALTER TABLE public.plant_rodent_trap_checks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "prtc_select"
  ON public.plant_rodent_trap_checks AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_pest_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "prtc_insert"
  ON public.plant_rodent_trap_checks AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_pest_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "prtc_update"
  ON public.plant_rodent_trap_checks AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_pest_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_pest_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "prtc_delete"
  ON public.plant_rodent_trap_checks AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_pest_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_rodent_trap_checks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_rodent_trap_checks TO service_role;

-- -----------------------------------------------------------------------------
-- 3. plant_light_trap_checks -- trampas de luz, conteo por especie
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_light_trap_checks (
  id             uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id     uuid    NOT NULL,
  trap_code      text    NOT NULL,
  operatividad   text    CHECK (operatividad IN ('operativo', 'no_operativo')),
  md_count       integer CHECK (md_count >= 0),
  mc_count       integer CHECK (mc_count >= 0),
  ab_count       integer CHECK (ab_count >= 0),
  e_count        integer CHECK (e_count >= 0),
  p_count        integer CHECK (p_count >= 0),
  z_count        integer CHECK (z_count >= 0),
  mq_count       integer CHECK (mq_count >= 0),
  av_count       integer CHECK (av_count >= 0),
  l_count        integer CHECK (l_count >= 0),
  otros_count    integer CHECK (otros_count >= 0),
  observations   text,
  corrective_action text,

  CONSTRAINT plant_light_trap_checks_pkey PRIMARY KEY (id),
  CONSTRAINT pltc_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_pest_controls(id) ON DELETE CASCADE,
  CONSTRAINT pltc_unique_trap UNIQUE (control_id, trap_code)
);

CREATE INDEX idx_pltc_control ON public.plant_light_trap_checks (control_id);

ALTER TABLE public.plant_light_trap_checks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pltc_select"
  ON public.plant_light_trap_checks AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_pest_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pltc_insert"
  ON public.plant_light_trap_checks AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_pest_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pltc_update"
  ON public.plant_light_trap_checks AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_pest_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_pest_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pltc_delete"
  ON public.plant_light_trap_checks AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_pest_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_light_trap_checks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_light_trap_checks TO service_role;
