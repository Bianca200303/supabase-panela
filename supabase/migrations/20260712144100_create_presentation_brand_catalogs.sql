-- =============================================================================
-- Tablas: plant_presentation_catalog, plant_brand_catalog
-- Propósito: reemplazar las listas de "Presentación" y "Marca" que hoy están
--   hardcodeadas en OrdenesPage.jsx (un único <datalist> compartido por todas
--   las cooperativas, sin distinguir cooperative_id).
--
-- Cada cooperativa tiene su propia forma de envasar y sus propias marcas —
-- el jefe de cada cooperativa manda su lista y se carga acá directamente
-- por SQL (sin pantalla de administración por ahora). El frontend arma el
-- datalist consultando estas tablas filtradas por cooperative_id, igual que
-- todo lo demás en el sistema.
--
-- Se seedean con la lista actual hardcodeada, para las dos cooperativas que
-- ya existen (Norandino, CAES), así no se pierde nada de lo que ya funciona
-- hasta que lleguen las listas reales de cada jefe.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.plant_presentation_catalog (
  id              uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id  uuid        NOT NULL,
  label           text        NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_presentation_catalog_pkey PRIMARY KEY (id),
  CONSTRAINT plant_presentation_catalog_unique UNIQUE (cooperative_id, label),
  CONSTRAINT plant_presentation_catalog_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.plant_brand_catalog (
  id              uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id  uuid        NOT NULL,
  label           text        NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_brand_catalog_pkey PRIMARY KEY (id),
  CONSTRAINT plant_brand_catalog_unique UNIQUE (cooperative_id, label),
  CONSTRAINT plant_brand_catalog_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- RLS: mismo patrón usado en todo el sistema (cooperative_id = auth_cooperative_id())
-- -----------------------------------------------------------------------------

ALTER TABLE public.plant_presentation_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plant_brand_catalog        ENABLE ROW LEVEL SECURITY;

CREATE POLICY "plant_presentation_catalog_select"
  ON public.plant_presentation_catalog AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_presentation_catalog_insert"
  ON public.plant_presentation_catalog AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_presentation_catalog_update"
  ON public.plant_presentation_catalog AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_presentation_catalog_delete"
  ON public.plant_presentation_catalog AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_brand_catalog_select"
  ON public.plant_brand_catalog AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_brand_catalog_insert"
  ON public.plant_brand_catalog AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_brand_catalog_update"
  ON public.plant_brand_catalog AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_brand_catalog_delete"
  ON public.plant_brand_catalog AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

-- -----------------------------------------------------------------------------
-- Seed: la lista actual hardcodeada, para ambas cooperativas existentes.
-- -----------------------------------------------------------------------------

INSERT INTO public.plant_presentation_catalog (cooperative_id, label)
SELECT c.id, p.label
FROM public.cooperatives c
CROSS JOIN (VALUES
  ('Polvo 500 g'),
  ('Polvo 1 kg'),
  ('Polvo 25 kg (saco)'),
  ('Piloncillo 400 g'),
  ('Bloque 500 g'),
  ('Caja 500 g × 10 und'),
  ('Caja 500 g × 20 und'),
  ('Caja 1 kg × 10 und'),
  ('Bolsa 5 kg'),
  ('Saco 25 kg'),
  ('Saco 50 kg')
) AS p(label)
ON CONFLICT (cooperative_id, label) DO NOTHING;

INSERT INTO public.plant_brand_catalog (cooperative_id, label)
SELECT c.id, b.label
FROM public.cooperatives c
CROSS JOIN (VALUES
  ('NORANDINO'),
  ('CAES'),
  ('PanelaBio'),
  ('NaturPanela'),
  ('Andean Sweet')
) AS b(label)
ON CONFLICT (cooperative_id, label) DO NOTHING;
