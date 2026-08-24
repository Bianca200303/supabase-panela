-- =============================================================================
-- "Lado" del pallet (izquierda/derecha) en la carga del contenedor.
--
-- Antes no existía ningún dato de lado -- lo que se veía en el Packing
-- List (mitad izquierda / mitad derecha) era solo el PDF partiendo la
-- lista de pallets al medio (Math.ceil(length/2)), sin que nadie lo
-- hubiera elegido. El usuario pidió que se pueda indicar/elegir el lado
-- real al cargar cada pallet.
--
-- Nullable a propósito: los pallets ya cargados antes de esta migración
-- quedan sin lado (no se puede reconstruir cuál fue real), y la UI nueva
-- siempre lo va a completar de acá en adelante -- mismo criterio de no
-- pisar/inventar datos históricos ya usado en el resto del sistema.
-- =============================================================================

ALTER TABLE public.plant_container_loading_pallets
  ADD COLUMN lado text;

ALTER TABLE public.plant_container_loading_pallets
  ADD CONSTRAINT pclp_lado_check CHECK (lado IN ('izquierda', 'derecha'));
