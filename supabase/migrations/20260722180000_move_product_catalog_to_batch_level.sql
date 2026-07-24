-- Mueve la referencia al catálogo de productos de la ORDEN al LOTE de
-- envasado (plant_production_batches).
--
-- Al implementar la UI se detectó que estaba mal puesto a nivel de orden:
-- el tipo de empaque y el peso de empaque ya son campos por LOTE (una orden
-- puede perfectamente combinar varios lotes con distinta presentación para
-- el mismo cliente -- ej. una parte en bolsa de 0.5 kg y otra en saco de
-- 25 kg, en el mismo contenedor). El cliente sí es correcto a nivel de
-- orden (un solo cliente por orden/embarque); el producto/SKU específico
-- no lo es.
--
-- product_catalog_id en plant_orders se agregó recién en
-- 20260722170000_client_defaults_and_product_catalog.sql, sin datos reales
-- todavía -- se puede mover sin migrar filas existentes.

ALTER TABLE public.plant_orders
  DROP COLUMN IF EXISTS product_catalog_id;

ALTER TABLE public.plant_production_batches
  ADD COLUMN IF NOT EXISTS product_catalog_id uuid REFERENCES public.plant_product_catalog(id);
