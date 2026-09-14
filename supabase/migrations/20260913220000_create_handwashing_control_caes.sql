-- =============================================================================
-- Lavado de Manos en la Operación de Tamizado (CAESP-PP-HYS-RE-HSP-004) --
-- SOLO CAES, control nuevo de Fase 2 (ver
-- COOPERATIVE.features.controlesPlantaCAES en lib/config.js), sin
-- equivalente en Norandino.
--
-- Registro plano por (fecha, persona), mismo criterio que los demás
-- controles nuevos de Fase 2. Área y horario de la operación se repiten
-- por fila (texto libre) en vez de una cabecera de "control" aparte -- el
-- papel real los muestra fijos en la parte superior de cada hoja, pero
-- las filas abarcan varios meses de fechas distintas, así que no hay una
-- agrupación real que valga la pena modelar aparte. Nombre y apellidos en
-- texto libre (no FK a plant_personnel) -- a diferencia de Higiene de
-- CAES, acá no hace falta gestionar catálogo/zona, alcanza con texto.
-- =============================================================================

CREATE TABLE public.plant_handwashing_control_caes (
  id                uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id    uuid        NOT NULL,
  control_date      date        NOT NULL,
  area              text,
  hora_inicio       time,
  hora_fin          time,
  nombre_apellidos  text,
  r1                boolean     NOT NULL DEFAULT true,
  r2                boolean     NOT NULL DEFAULT true,
  r3                boolean     NOT NULL DEFAULT true,
  r4                boolean     NOT NULL DEFAULT true,
  r5                boolean     NOT NULL DEFAULT true,
  observaciones     text,
  created_by        uuid        NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_handwashing_control_caes_pkey PRIMARY KEY (id),
  CONSTRAINT phwcc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT phwcc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id)
);

CREATE INDEX idx_phwcc_cooperative_date ON public.plant_handwashing_control_caes (cooperative_id, control_date DESC);

ALTER TABLE public.plant_handwashing_control_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "phwcc_select"
  ON public.plant_handwashing_control_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "phwcc_insert"
  ON public.plant_handwashing_control_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "phwcc_update"
  ON public.plant_handwashing_control_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "phwcc_delete"
  ON public.plant_handwashing_control_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_handwashing_control_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_handwashing_control_caes TO service_role;
