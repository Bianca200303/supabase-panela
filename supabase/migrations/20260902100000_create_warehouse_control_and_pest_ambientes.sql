-- =============================================================================
-- Resumen de Trazabilidad (antes "Ejercicio de Trazabilidad de Exportación")
-- -- campos que faltaban contra los formatos físicos de referencia de CAES
-- (Nacional y Exportación) y que no tenían ninguna fuente de datos en el
-- sistema. Todos opcionales -- este documento tiene que poder generarse aun
-- si nadie cargó estos datos todavía (sale "Sin registrar").
--
-- Reemplaza una versión anterior de esta migración (nunca aplicada) que
-- agregaba temperatura/humedad de almacén como columnas de
-- plant_production_batches (por LOTE). Se cambia de diseño: un almacén
-- guarda varios lotes a la vez, la temperatura/humedad no es una propiedad
-- de un lote puntual sino del ambiente en un momento dado -- va como control
-- periódico por FECHA, mismo patrón que Cloro Residual/Plagas
-- (20260731130000_create_chlorine_residual_control.sql /
-- 20260731140000_create_pest_control.sql), no por lote.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. plant_warehouse_controls -- Temperatura/Humedad de almacén + Control de
--    Agua (4 puntos fijos), 1 control por (cooperativa, fecha).
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_warehouse_controls (
  id                  uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id      uuid        NOT NULL,
  control_date        date        NOT NULL,
  responsible_person  text,
  temperatura_c       numeric(5,2),
  humedad_pct         numeric(5,2) CHECK (humedad_pct >= 0 AND humedad_pct <= 100),
  created_by          uuid        NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_warehouse_controls_pkey PRIMARY KEY (id),
  CONSTRAINT pwc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pwc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT pwc_unique_date UNIQUE (cooperative_id, control_date)
);

CREATE INDEX idx_pwc_cooperative_date ON public.plant_warehouse_controls (cooperative_id, control_date DESC);

ALTER TABLE public.plant_warehouse_controls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pwc_select"
  ON public.plant_warehouse_controls AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pwc_insert"
  ON public.plant_warehouse_controls AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pwc_update"
  ON public.plant_warehouse_controls AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pwc_delete"
  ON public.plant_warehouse_controls AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_warehouse_controls TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_warehouse_controls TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_warehouse_water_checks -- Control de Agua: 1 medición por
--    (control, punto). 4 puntos fijos del papel físico de CAES.
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_warehouse_water_checks (
  id                 uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id         uuid    NOT NULL,
  point_code         text    NOT NULL CHECK (point_code IN (
    'ingreso_planta', 'sshh', 'tamizado_homog_envasado', 'tanques_rotoplast'
  )),
  result_ppm         numeric(5,2),
  check_time         time,
  observations       text,

  CONSTRAINT plant_warehouse_water_checks_pkey PRIMARY KEY (id),
  CONSTRAINT pwwc_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_warehouse_controls(id) ON DELETE CASCADE,
  CONSTRAINT pwwc_unique_point UNIQUE (control_id, point_code)
);

CREATE INDEX idx_pwwc_control ON public.plant_warehouse_water_checks (control_id);

ALTER TABLE public.plant_warehouse_water_checks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pwwc_select"
  ON public.plant_warehouse_water_checks AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_warehouse_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pwwc_insert"
  ON public.plant_warehouse_water_checks AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_warehouse_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pwwc_update"
  ON public.plant_warehouse_water_checks AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_warehouse_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_warehouse_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pwwc_delete"
  ON public.plant_warehouse_water_checks AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_warehouse_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_warehouse_water_checks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_warehouse_water_checks TO service_role;

-- -----------------------------------------------------------------------------
-- 3. Inspección de Ambientes, Equipo y Personal -- el 3er sub-control de
--    Plagas del papel físico de CAES (los otros 2, Trampas Mecánicas e
--    Insectocutores, ya existen vía plant_rodent_trap_checks/
--    plant_light_trap_checks). No es una tabla propia con catálogo de áreas
--    -- el papel solo pide un código+fecha de referencia, así que va como 2
--    columnas opcionales más en el mismo plant_pest_controls (mismo control
--    del día, no un registro aparte), igual criterio que "responsible_person".
-- -----------------------------------------------------------------------------
ALTER TABLE public.plant_pest_controls
  ADD COLUMN IF NOT EXISTS ambientes_equipo_personal_ok text
    CHECK (ambientes_equipo_personal_ok IN ('correcto', 'no_correcto')),
  ADD COLUMN IF NOT EXISTS ambientes_equipo_personal_observaciones text;
