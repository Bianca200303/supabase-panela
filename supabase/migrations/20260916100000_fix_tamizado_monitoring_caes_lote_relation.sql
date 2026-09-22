-- =============================================================================
-- Corrección: Monitoreo y Verificación del Tamizado (CAESP-PP-BPM-RE-CPR-002)
-- NO se relaciona con el bunque -- se relaciona con el LOTE DE ENVASADO,
-- igual que Sellado/Envasado (CPR-003) y Hermeticidad de Envases (CPR-007).
--
-- La migración 20260915150000 (bunque_id) partió de una lectura equivocada
-- del papel real, escrita en el comentario de 20260913170000 ("el N° Lote
-- corresponde al lote de materia prima que pasa por el tamiz, no al lote
-- de envasado"). Es falso: se decodificó el propio código de lote del
-- papel (formato DDD+YY+NNN -- día juliano + año + correlativo anual de
-- planta) contra las fechas manuscritas en los 4 formatos físicos
-- disponibles y coincide exacto en los 5 casos verificados. Además,
-- CPR-002 y CPR-007 (Hermeticidad de Envases) comparten LITERALMENTE los
-- mismos códigos de lote en las mismas fechas en el papel real -- y CPR-007
-- es inequívocamente producto envasado (tamaño de lote en UNIDADES,
-- muestreo AQL 2.5%, producto conforme/no conforme). Un lote de campo o un
-- bunque se miden en kg, nunca en unidades ni se muestrean por
-- hermeticidad -- así que el código que comparten ambos formatos es el
-- lote de envasado (plant_production_batches), no materia prima.
--
-- La tabla plant_sieve_monitoring_caes está vacía (0 filas, confirmado) --
-- se corrige de una sola vez, sin backfill.
-- =============================================================================

ALTER TABLE public.plant_sieve_monitoring_caes
  DROP COLUMN bunque_id;

ALTER TABLE public.plant_sieve_monitoring_caes
  ADD COLUMN plant_batch_id uuid NOT NULL REFERENCES public.plant_production_batches(id) ON DELETE CASCADE;

CREATE INDEX idx_psmc_plant_batch ON public.plant_sieve_monitoring_caes (plant_batch_id);
