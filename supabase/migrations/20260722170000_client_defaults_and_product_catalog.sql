-- =============================================================================
-- Defaults de presentación por cliente + catálogo de productos (SKU) de planta.
--
-- Origen: cada cooperativa (ej. Norandino) maneja en un excel suelto una lista
-- de valores por defecto de presentación por importador (bolsas por caja, peso
-- por bolsa, pallets por lote) y un catálogo de códigos de producto (CODPROD)
-- que en la práctica son SKUs fijos: cada código ya trae resuelto marca y/o
-- cliente + peso de empaque. Son sugerencias para agilizar la carga de una
-- orden/lote, nunca una restricción — el usuario puede seguir escribiendo
-- cualquier valor a mano.
--
-- Esta migración solo crea la ESTRUCTURA. Los datos reales de cada cooperativa
-- se cargan aparte, a mano, desde supabase/<cooperativa>/ (mismo criterio que
-- certified_workers_seed.sql / catalogs_seed.sql — nunca automático).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. plant_clients — defaults de presentación por cliente/importador.
--    Todas nullable: un cliente puede no tener ningún default (ej. "Nacional"),
--    y default_units_per_box solo tiene sentido cuando el empaque es 'bolsa'
--    (no aplica a saco, que no se agrupa en cajas).
-- -----------------------------------------------------------------------------

ALTER TABLE public.plant_clients
  ADD COLUMN IF NOT EXISTS default_packaging_type text,
  ADD COLUMN IF NOT EXISTS default_units_per_box   integer,
  ADD COLUMN IF NOT EXISTS default_packaging_kg    numeric,
  ADD COLUMN IF NOT EXISTS default_pallet_count    integer;

ALTER TABLE public.plant_clients
  ADD CONSTRAINT plant_clients_default_packaging_type_check
    CHECK (default_packaging_type IS NULL OR default_packaging_type IN ('bolsa', 'saco'));

-- -----------------------------------------------------------------------------
-- 2. plant_product_catalog — catálogo de SKUs (CODPROD) por cooperativa.
--    client_id y brand_id son independientes entre sí y ambos opcionales:
--    un producto puede ser de un importador (ej. La Siembra), de marca propia
--    (ej. NORANDINO orgánico), de ambos, o genérico (ninguno de los dos).
--    packaging_kg a nivel producto pisa el default del cliente cuando el
--    producto ya lo trae explícito (ej. Ethiquable por defecto es bolsa de
--    500 g, pero también tiene un SKU propio de 25 kg en saco).
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.plant_product_catalog (
  id              uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id  uuid        NOT NULL,
  client_id       uuid,
  brand_id        uuid,
  code            text        NOT NULL,
  description     text        NOT NULL,
  packaging_type  text,
  packaging_kg    numeric,
  is_active       boolean     NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_product_catalog_pkey PRIMARY KEY (id),
  CONSTRAINT plant_product_catalog_code_unique UNIQUE (cooperative_id, code),
  CONSTRAINT plant_product_catalog_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT plant_product_catalog_client_fkey
    FOREIGN KEY (client_id) REFERENCES public.plant_clients(id) ON DELETE SET NULL,
  CONSTRAINT plant_product_catalog_brand_fkey
    FOREIGN KEY (brand_id) REFERENCES public.plant_brand_catalog(id) ON DELETE SET NULL,
  CONSTRAINT plant_product_catalog_packaging_type_check
    CHECK (packaging_type IS NULL OR packaging_type IN ('bolsa', 'saco'))
);

CREATE INDEX IF NOT EXISTS idx_plant_product_catalog_cooperative ON public.plant_product_catalog USING btree (cooperative_id);
CREATE INDEX IF NOT EXISTS idx_plant_product_catalog_client      ON public.plant_product_catalog USING btree (client_id);

ALTER TABLE public.plant_product_catalog ENABLE ROW LEVEL SECURITY;

CREATE POLICY "plant_product_catalog_select"
  ON public.plant_product_catalog AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_product_catalog_insert"
  ON public.plant_product_catalog AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_product_catalog_update"
  ON public.plant_product_catalog AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_product_catalog_delete"
  ON public.plant_product_catalog AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE TRIGGER trg_update_plant_product_catalog_updated_at
  BEFORE UPDATE ON public.plant_product_catalog
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 3. plant_orders — referencia opcional al producto elegido del catálogo.
--    El campo "product" (texto) se mantiene tal cual: se autocompleta desde
--    el catálogo pero sigue editable a mano para lo que no esté cargado ahí.
-- -----------------------------------------------------------------------------

ALTER TABLE public.plant_orders
  ADD COLUMN IF NOT EXISTS product_catalog_id uuid REFERENCES public.plant_product_catalog(id);

-- -----------------------------------------------------------------------------
-- 4. plant_presentation_catalog — nunca se llegó a leer desde ningún frontend
--    (ni web ni móvil, confirmado por búsqueda en todo el repo) y su función
--    queda cubierta, de forma real esta vez, por plant_clients.default_* +
--    plant_product_catalog.packaging_kg. Se elimina en vez de dejarla como
--    tabla fantasma en paralelo.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS public.plant_presentation_catalog CASCADE;
