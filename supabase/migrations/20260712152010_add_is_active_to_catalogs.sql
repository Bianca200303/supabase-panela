-- Permite desactivar una presentación/marca sin borrarla del catálogo
-- (para conservar el registro de qué se usó alguna vez, sin seguir
-- ofreciéndola como sugerencia). Se gestiona directo por SQL, sin pantalla
-- de administración:
--   UPDATE plant_presentation_catalog SET is_active = false WHERE id = '...';

ALTER TABLE public.plant_presentation_catalog
  ADD COLUMN is_active boolean NOT NULL DEFAULT true;

ALTER TABLE public.plant_brand_catalog
  ADD COLUMN is_active boolean NOT NULL DEFAULT true;
