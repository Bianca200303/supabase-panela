-- Nacional vs Exportación (CAES): hasta ahora no había ningún campo en el
-- sistema que dijera esto -- se preguntaba cada vez que se generaba el
-- Resumen de Trazabilidad (needsTipoSelector, ver QuickDocsModal.jsx /
-- resumenTrazabilidad.js) y no quedaba guardado en ningún lado. Se elige
-- una sola vez, al crear la orden (o corregible después en "Editar orden"),
-- y desde ahí alimenta el documento sin volver a preguntar.
--
-- Solo aplica a cooperativas con COOPERATIVE.features.ventaNacionalExportacion
-- (hoy CAES) -- para el resto (Norandino, que solo exporta) queda NULL.

ALTER TABLE public.plant_orders
  ADD COLUMN IF NOT EXISTS sale_type text;

ALTER TABLE public.plant_orders
  ADD CONSTRAINT chk_po_sale_type_valid
  CHECK (sale_type IS NULL OR sale_type = ANY (ARRAY['nacional', 'exportacion'])) NOT VALID;

ALTER TABLE public.plant_orders
  VALIDATE CONSTRAINT chk_po_sale_type_valid;
