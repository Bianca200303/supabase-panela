-- =============================================================================
-- Control de Pesos y Sellado (COA-PPA-GCA-RG-005).
--
-- A diferencia de todos los controles SIG anteriores (Higiene, Ambientes,
-- Equipos, Verificación, Cloro Residual, Plagas -- todos generales de
-- planta, independientes de cualquier orden/lote), este SÍ está atado a un
-- lote de envasado puntual (plant_batch_id) -- mismo patrón que Control de
-- Objetos Extraños (ver 20260722140000_create_foreign_object_control_forms.sql):
-- un formulario por (lote, fecha, turno) que se va completando con
-- inspecciones ("horas") agregadas una por una durante el turno, hasta que
-- el responsable lo da por terminado.
--
-- Confirmado con el usuario: 1 formulario por (lote, fecha, turno) --no
-- solo (lote, fecha) como Objetos Extraños-- porque el papel físico trae
-- FECHA y TURNO como campos separados por hoja, y un mismo lote puede
-- envasarse en mañana y tarde el mismo día con datos independientes.
--
-- Cada hora agregada (plant_batch_weight_seal_checks) trae 10 muestras
-- fijas (plant_batch_weight_seal_samples, la instrucción del papel dice
-- "10 muestras cada hora"), cada una con peso (gramos), sellado (A: buen
-- sellado / B: mal sellado) y limpieza (sí/no). El peso objetivo/tolerancia
-- (+1gr sobre el peso nominal de la bolsa) NO se guarda acá -- se calcula
-- en la UI a partir de plant_production_batches.packaging_kg del lote,
-- porque varía por lote (bolsas de 0.5/1/1.5 kg conviven en el sistema).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. plant_batch_weight_seal_forms -- 1 por (lote, fecha, turno)
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_batch_weight_seal_forms (
  id                   uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id       uuid        NOT NULL,
  plant_batch_id       uuid        NOT NULL,
  control_date         date        NOT NULL DEFAULT CURRENT_DATE,
  turno                text        NOT NULL CHECK (turno IN ('manana', 'tarde')),
  status               text        NOT NULL DEFAULT 'en_progreso' CHECK (status IN ('en_progreso', 'terminado')),
  responsible_person   text        NOT NULL,
  final_observations   text,
  created_by           uuid        NOT NULL,
  closed_by            uuid,
  closed_at            timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_batch_weight_seal_forms_pkey PRIMARY KEY (id),
  CONSTRAINT pbwsf_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pbwsf_plant_batch_fkey
    FOREIGN KEY (plant_batch_id) REFERENCES public.plant_production_batches(id) ON DELETE CASCADE,
  CONSTRAINT pbwsf_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT pbwsf_closed_by_fkey
    FOREIGN KEY (closed_by) REFERENCES public.web_users(id),
  CONSTRAINT pbwsf_unique_batch_date_turno UNIQUE (plant_batch_id, control_date, turno)
);

CREATE INDEX idx_pbwsf_plant_batch ON public.plant_batch_weight_seal_forms (plant_batch_id);
CREATE INDEX idx_pbwsf_cooperative ON public.plant_batch_weight_seal_forms (cooperative_id);

ALTER TABLE public.plant_batch_weight_seal_forms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pbwsf_select"
  ON public.plant_batch_weight_seal_forms AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pbwsf_insert"
  ON public.plant_batch_weight_seal_forms AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pbwsf_update"
  ON public.plant_batch_weight_seal_forms AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_batch_weight_seal_forms TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_batch_weight_seal_forms TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_batch_weight_seal_checks -- 1 por hora agregada durante el turno
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_batch_weight_seal_checks (
  id             uuid        NOT NULL DEFAULT gen_random_uuid(),
  form_id        uuid        NOT NULL,
  check_number   integer     NOT NULL,
  hora_label     text        NOT NULL,
  created_by     uuid        NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_batch_weight_seal_checks_pkey PRIMARY KEY (id),
  CONSTRAINT pbwsc_form_fkey
    FOREIGN KEY (form_id) REFERENCES public.plant_batch_weight_seal_forms(id) ON DELETE CASCADE,
  CONSTRAINT pbwsc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT pbwsc_unique_form_check_number UNIQUE (form_id, check_number)
);

CREATE INDEX idx_pbwsc_form ON public.plant_batch_weight_seal_checks (form_id);

ALTER TABLE public.plant_batch_weight_seal_checks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pbwsc_select"
  ON public.plant_batch_weight_seal_checks AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_batch_weight_seal_forms f
    WHERE f.id = form_id AND (f.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pbwsc_insert"
  ON public.plant_batch_weight_seal_checks AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_batch_weight_seal_forms f
    WHERE f.id = form_id AND (f.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_batch_weight_seal_checks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_batch_weight_seal_checks TO service_role;

-- -----------------------------------------------------------------------------
-- 3. plant_batch_weight_seal_samples -- 10 muestras fijas por hora
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_batch_weight_seal_samples (
  id               uuid    NOT NULL DEFAULT gen_random_uuid(),
  check_id         uuid    NOT NULL,
  muestra_number   integer NOT NULL CHECK (muestra_number BETWEEN 1 AND 10),
  peso_gr          numeric(6,2),
  sellado          text    CHECK (sellado IN ('A', 'B')),
  limpieza         boolean,

  CONSTRAINT plant_batch_weight_seal_samples_pkey PRIMARY KEY (id),
  CONSTRAINT pbwss_check_fkey
    FOREIGN KEY (check_id) REFERENCES public.plant_batch_weight_seal_checks(id) ON DELETE CASCADE,
  CONSTRAINT pbwss_unique_check_muestra UNIQUE (check_id, muestra_number)
);

CREATE INDEX idx_pbwss_check ON public.plant_batch_weight_seal_samples (check_id);

ALTER TABLE public.plant_batch_weight_seal_samples ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pbwss_select"
  ON public.plant_batch_weight_seal_samples AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_batch_weight_seal_checks c
    JOIN public.plant_batch_weight_seal_forms f ON f.id = c.form_id
    WHERE c.id = check_id AND (f.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pbwss_insert"
  ON public.plant_batch_weight_seal_samples AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_batch_weight_seal_checks c
    JOIN public.plant_batch_weight_seal_forms f ON f.id = c.form_id
    WHERE c.id = check_id AND (f.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_batch_weight_seal_samples TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_batch_weight_seal_samples TO service_role;

-- El número de hora se asigna solo (correlativo dentro de su formulario),
-- mismo criterio que inspection_number en Objetos Extraños.
CREATE OR REPLACE FUNCTION public.set_weight_seal_check_number()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  SELECT COALESCE(MAX(check_number), 0) + 1
  INTO NEW.check_number
  FROM plant_batch_weight_seal_checks
  WHERE form_id = NEW.form_id;

  RETURN NEW;
END;
$function$;

CREATE TRIGGER trg_set_weight_seal_check_number
  BEFORE INSERT ON public.plant_batch_weight_seal_checks
  FOR EACH ROW EXECUTE FUNCTION public.set_weight_seal_check_number();
