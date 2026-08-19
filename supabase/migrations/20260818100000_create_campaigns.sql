-- =============================================================================
-- Tabla: campaigns
--
-- Primera entidad formal para "campaña" en el sistema. Hasta ahora el
-- concepto vivía suelto como un integer `year` dentro de producer_quotas
-- (el cupo máximo de producción asignado a un productor por campaña), sin
-- tabla propia ni forma de saber cuál está vigente. Esta tabla lo
-- centraliza, para que cualquier otra parte del sistema que necesite
-- "campaña vigente" (empezando por la numeración de bunques de tamizado,
-- ver 20260818110000) tenga una sola fuente de verdad.
--
-- Decisiones de diseño (confirmadas con el usuario, 2026-08-18):
--   • `is_active` es una bandera administrada a mano (abrir/cerrar desde la
--     UI de Catálogos), NO se infiere del reloj del sistema. Motivo: un
--     bunque de fin de campaña puede cargarse con retraso ya entrada la
--     campaña siguiente -- mientras nadie cierre la campaña a propósito,
--     sigue cayendo ahí. Solo puede haber una campaña activa por
--     cooperativa a la vez (índice único parcial más abajo).
--   • `year` sigue el mismo criterio ya validado en producer_quotas.year:
--     una campaña por año calendario, sin rango de fechas flexible.
--     start_date/end_date quedan como dato informativo opcional, no como
--     fuente de la campaña vigente.
--   • Backfill: se derivan campañas históricas de los años ya usados en
--     producer_quotas, marcando activa la más reciente de cada cooperativa
--     -- así la funcionalidad no arranca de cero en producción. En un
--     reset limpio de BD (producer_quotas vacía) este INSERT simplemente
--     no inserta nada, sin romper la migración.
-- =============================================================================

CREATE TABLE public.campaigns (
  id               uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id   uuid        NOT NULL,
  year             integer     NOT NULL,
  start_date       date,
  end_date         date,
  is_active        boolean     NOT NULL DEFAULT false,
  created_at       timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT campaigns_pkey PRIMARY KEY (id),
  CONSTRAINT campaigns_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT campaigns_unique_year_per_coop UNIQUE (cooperative_id, year)
);

-- Como máximo una campaña activa por cooperativa -- lo que hace de "campaña
-- vigente" una consulta directa (WHERE cooperative_id = ... AND is_active).
CREATE UNIQUE INDEX idx_campaigns_one_active_per_coop
  ON public.campaigns (cooperative_id)
  WHERE is_active;

-- -----------------------------------------------------------------------------
-- RLS -- mismo patrón del proyecto
-- -----------------------------------------------------------------------------
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "campaigns_select"
  ON public.campaigns AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "campaigns_insert"
  ON public.campaigns AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "campaigns_update"
  ON public.campaigns AS PERMISSIVE FOR UPDATE TO authenticated
  USING  (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "campaigns_delete"
  ON public.campaigns AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.campaigns TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.campaigns TO service_role;

-- -----------------------------------------------------------------------------
-- Backfill histórico desde producer_quotas.year (no-op en un reset limpio)
-- -----------------------------------------------------------------------------
INSERT INTO public.campaigns (cooperative_id, year)
SELECT DISTINCT cooperative_id, year
FROM public.producer_quotas
ON CONFLICT (cooperative_id, year) DO NOTHING;

-- Marca activa la campaña más reciente de cada cooperativa que haya quedado
-- creada por el backfill de arriba. Editable después desde Catálogos.
UPDATE public.campaigns c
SET is_active = true
WHERE c.year = (
  SELECT MAX(c2.year) FROM public.campaigns c2 WHERE c2.cooperative_id = c.cooperative_id
);
