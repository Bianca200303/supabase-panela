-- =============================================================================
-- Reemplazo completo del Control de Higiene de Personal.
--
-- Las tablas viejas (plant_hygiene_areas / plant_hygiene_workers /
-- plant_hygiene_worker_criteria, de la migración baseline) se armaron sin
-- mirar el formato físico real (SIG-GIA-RG-005). Comparado con el papel,
-- tenían: criterios repartidos distinto por área (deberían ser los mismos 9
-- en Envasado y Tamizado), sin estado "no aplica" (solo cumple/no cumple),
-- trabajadores tipeados a mano cada vez (sin catálogo), y sin turno.
-- Confirmado con el usuario: no hay datos reales que preservar, se
-- reemplaza en vez de migrar.
--
-- Modelo nuevo:
--   - plant_personnel: catálogo de personal de planta (se carga una vez,
--     se reutiliza día a día -- a diferencia de los productores de campo,
--     que son otra tabla completamente distinta).
--   - plant_hygiene_controls: 1 por (fecha, turno, área) -- INDEPENDIENTE
--     de cualquier orden/lote (confirmado con el usuario: una misma
--     inspección puede aplicar a varios contenedores activos ese día, así
--     que no lleva order_id ni plant_batch_id). El documento para una
--     orden se arma después cruzando por fecha contra el rango de trabajo
--     de esa orden (tamizado_fecha_inicio..envasado_fecha_fin).
--   - plant_hygiene_control_workers: roster de esa inspección puntual,
--     trabajador por trabajador, con si asistió o no.
--   - plant_hygiene_control_criteria: los 9 criterios del papel físico,
--     por trabajador, en 3 estados (cumple/no_cumple/na) -- solo aplica si
--     asistió.
-- =============================================================================

DROP TABLE IF EXISTS public.plant_hygiene_worker_criteria CASCADE;
DROP TABLE IF EXISTS public.plant_hygiene_workers CASCADE;
DROP TABLE IF EXISTS public.plant_hygiene_areas CASCADE;

-- -----------------------------------------------------------------------------
-- 1. plant_personnel -- catálogo de personal de planta
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_personnel (
  id              uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id  uuid        NOT NULL,
  first_name      text        NOT NULL,
  last_name       text        NOT NULL,
  is_active       boolean     NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_personnel_pkey PRIMARY KEY (id),
  CONSTRAINT plant_personnel_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE
);

CREATE INDEX idx_plant_personnel_cooperative ON public.plant_personnel (cooperative_id);

ALTER TABLE public.plant_personnel ENABLE ROW LEVEL SECURITY;

CREATE POLICY "plant_personnel_select"
  ON public.plant_personnel AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_personnel_insert"
  ON public.plant_personnel AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_personnel_update"
  ON public.plant_personnel AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_personnel_delete"
  ON public.plant_personnel AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_personnel TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_personnel TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_hygiene_controls -- 1 por (fecha, turno, área), sin relación a
--    orden ni lote a propósito.
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_hygiene_controls (
  id                  uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id      uuid        NOT NULL,
  control_date        date        NOT NULL,
  turno               text        NOT NULL CHECK (turno IN ('manana', 'tarde')),
  area                text        NOT NULL,
  responsible_person  text,
  observations        text,
  created_by          uuid        NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_hygiene_controls_pkey PRIMARY KEY (id),
  CONSTRAINT phc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT phc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  -- A lo sumo un control por fecha+turno+área -- mismo criterio que
  -- Cuerpos Extraños (1 formulario por lote+fecha).
  CONSTRAINT phc_unique_date_turno_area UNIQUE (cooperative_id, control_date, turno, area)
);

CREATE INDEX idx_phc_cooperative_date ON public.plant_hygiene_controls (cooperative_id, control_date DESC);

ALTER TABLE public.plant_hygiene_controls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "phc_select"
  ON public.plant_hygiene_controls AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "phc_insert"
  ON public.plant_hygiene_controls AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "phc_update"
  ON public.plant_hygiene_controls AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "phc_delete"
  ON public.plant_hygiene_controls AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_hygiene_controls TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_hygiene_controls TO service_role;

-- -----------------------------------------------------------------------------
-- 3. plant_hygiene_control_workers -- roster de una inspección puntual
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_hygiene_control_workers (
  id            uuid        NOT NULL DEFAULT gen_random_uuid(),
  control_id    uuid        NOT NULL,
  personnel_id  uuid        NOT NULL,
  attended      boolean     NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_hygiene_control_workers_pkey PRIMARY KEY (id),
  CONSTRAINT phcw_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_hygiene_controls(id) ON DELETE CASCADE,
  CONSTRAINT phcw_personnel_fkey
    FOREIGN KEY (personnel_id) REFERENCES public.plant_personnel(id),
  CONSTRAINT phcw_unique_control_personnel UNIQUE (control_id, personnel_id)
);

CREATE INDEX idx_phcw_control ON public.plant_hygiene_control_workers (control_id);

ALTER TABLE public.plant_hygiene_control_workers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "phcw_select"
  ON public.plant_hygiene_control_workers AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_hygiene_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "phcw_insert"
  ON public.plant_hygiene_control_workers AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_hygiene_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "phcw_update"
  ON public.plant_hygiene_control_workers AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_hygiene_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_hygiene_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "phcw_delete"
  ON public.plant_hygiene_control_workers AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_hygiene_controls c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_hygiene_control_workers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_hygiene_control_workers TO service_role;

-- -----------------------------------------------------------------------------
-- 4. plant_hygiene_control_criteria -- los 9 criterios del papel físico,
--    por trabajador, en 3 estados.
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_hygiene_control_criteria (
  id                  uuid        NOT NULL DEFAULT gen_random_uuid(),
  control_worker_id   uuid        NOT NULL,
  item_code           text        NOT NULL,
  status              text        NOT NULL CHECK (status IN ('cumple', 'no_cumple', 'na')),

  CONSTRAINT plant_hygiene_control_criteria_pkey PRIMARY KEY (id),
  CONSTRAINT phcc_control_worker_fkey
    FOREIGN KEY (control_worker_id) REFERENCES public.plant_hygiene_control_workers(id) ON DELETE CASCADE,
  CONSTRAINT phcc_item_code_check CHECK (item_code IN (
    'unas_manos_limpias', 'uniforme', 'cabello', 'rostro_sin_maquillaje', 'barba',
    'sin_joyas_accesorios_perfume', 'gafas', 'ausencia_cortes_heridas', 'ausencia_signos_enfermedad'
  )),
  CONSTRAINT phcc_unique_worker_item UNIQUE (control_worker_id, item_code)
);

CREATE INDEX idx_phcc_control_worker ON public.plant_hygiene_control_criteria (control_worker_id);

ALTER TABLE public.plant_hygiene_control_criteria ENABLE ROW LEVEL SECURITY;

CREATE POLICY "phcc_select"
  ON public.plant_hygiene_control_criteria AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_hygiene_control_workers w
    JOIN public.plant_hygiene_controls c ON c.id = w.control_id
    WHERE w.id = control_worker_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "phcc_insert"
  ON public.plant_hygiene_control_criteria AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_hygiene_control_workers w
    JOIN public.plant_hygiene_controls c ON c.id = w.control_id
    WHERE w.id = control_worker_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "phcc_update"
  ON public.plant_hygiene_control_criteria AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_hygiene_control_workers w
    JOIN public.plant_hygiene_controls c ON c.id = w.control_id
    WHERE w.id = control_worker_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_hygiene_control_workers w
    JOIN public.plant_hygiene_controls c ON c.id = w.control_id
    WHERE w.id = control_worker_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "phcc_delete"
  ON public.plant_hygiene_control_criteria AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_hygiene_control_workers w
    JOIN public.plant_hygiene_controls c ON c.id = w.control_id
    WHERE w.id = control_worker_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_hygiene_control_criteria TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_hygiene_control_criteria TO service_role;
