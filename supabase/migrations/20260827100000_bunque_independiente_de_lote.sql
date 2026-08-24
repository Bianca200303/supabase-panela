-- =============================================================================
-- Fase 2 de "reparto de bunques entre lotes" (ver Fase 1,
-- 20260826100000_bunque_lote_allocations.sql y [[project_bunques_tamizado]]):
-- el bunque deja de ser hijo de un lote de envasado y pasa a ser un recurso
-- independiente de planta (gestionado en la nueva pantalla BunquesPage.jsx,
-- /bunques) -- se crea, se le cargan insumos y resultado, y RECIÉN AHÍ se
-- reparte ("Repartir a lotes") a uno o varios lotes de envasado por kg,
-- escribiendo directo en plant_bunque_batch_allocations (sin restricción de
-- que compartan la misma orden).
--
-- Dos cambios sobre el modelo de Fase 1:
--   1. plant_batch_bunques.plant_batch_id pasa a ser NULLABLE -- un bunque
--      nuevo, independiente, no tiene "dueño" hasta que se reparte, y aun
--      después de repartido puede no tener un único dueño (repartido a 2+
--      lotes). La columna queda en la tabla por compatibilidad con bunques
--      históricos (creados antes de esta fase, con plant_batch_id todavía
--      seteado) -- no se usa para nada nuevo de acá en adelante.
--   2. Se desactiva el trigger espejo de la Fase 1 (sync_bunque_allocation),
--      que reflejaba automáticamente plant_batch_id+tamizada_kg de
--      plant_batch_bunques hacia la tabla de reparto. Ya no aplica: la
--      pantalla nueva escribe la tabla de reparto directamente y un bunque
--      nuevo nunca vuelve a setear plant_batch_id. Si se dejara activo,
--      fallaría apenas un bunque independiente (plant_batch_id NULL)
--      registrara resultado, porque intentaría insertar una fila de reparto
--      con plant_batch_id NULL -- columna NOT NULL en
--      plant_bunque_batch_allocations.
--
-- El trigger de balance de masas de la Fase 1
-- (recalc_batch_tamizada_kg_from_allocations_trigger) NO se toca -- ya lee
-- de plant_bunque_batch_allocations, que es exactamente donde la pantalla
-- nueva escribe. plant_production_batches.tamizada_kg sigue siempre
-- correcto sin cambios acá.
-- =============================================================================

ALTER TABLE public.plant_batch_bunques
  ALTER COLUMN plant_batch_id DROP NOT NULL;

DROP TRIGGER IF EXISTS sync_bunque_allocation_trigger ON public.plant_batch_bunques;
DROP FUNCTION IF EXISTS public.sync_bunque_allocation();
