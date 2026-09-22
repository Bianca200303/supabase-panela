-- =============================================================================
-- Manejo de Residuos CAES -- "Origen del residuo" pasa de texto único a
-- varias áreas por registro (ej. un mismo despacho de residuos puede venir
-- de Tamizado Y de Envasado a la vez). Mismo criterio que otros campos
-- multi-selección de la app (estado/species en Control de Plagas CAES):
-- columna text[] con toggle de chips en la UI, ver
-- ManejoResiduosCaesPage.jsx.
-- =============================================================================

ALTER TABLE public.plant_waste_management_caes
  ALTER COLUMN origen_residuo TYPE text[]
  USING CASE WHEN origen_residuo IS NULL THEN NULL ELSE ARRAY[origen_residuo] END;
