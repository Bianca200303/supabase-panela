-- =============================================================================
-- Control y Liberación de Producto Terminado (CAESP-PP-BPM-RE-LPT-001) --
-- evolución del Control de calidad del envasado para CAES, ver
-- COOPERATIVE.features.liberacionProductoTerminado en lib/config.js.
--
-- Decidido con el usuario (2026-09-13): para CAES, Color/Sabor/Textura
-- dejan de ser requisito para cerrar el lote (su papel real no los pide) --
-- el requisito pasa a ser solo % Humedad y % Impurezas, igual que antes.
-- Los 4 campos nuevos de CAES (unidades por lote, formato/presentación,
-- muestreado por, resultado C/NC) son informativos, no bloquean el cierre.
-- Columnas nuevas en plant_production_batches, mismo criterio que
-- calidad_* (20260726100000_add_calidad_envasado_to_batches.sql): 1
-- registro por lote, editable.
-- =============================================================================

ALTER TABLE public.plant_production_batches
  ADD COLUMN IF NOT EXISTS liberacion_unidades_por_lote     integer,
  ADD COLUMN IF NOT EXISTS liberacion_formato_presentacion  text,
  ADD COLUMN IF NOT EXISTS liberacion_muestreado_por        text,
  ADD COLUMN IF NOT EXISTS liberacion_resultado             text
    CHECK (liberacion_resultado IN ('conforme', 'no_conforme'));
