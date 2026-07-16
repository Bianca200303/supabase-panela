-- =============================================================================
-- plant_batch_processing queda reemplazada por plant_batch_bunques (que ya
-- guarda las mismas 4 métricas, pero por bunque en vez de por lote).
-- No conviven -- v_plant_order_summary ya fue migrada a bunques en
-- 20260715160000, así que esta tabla ya no tiene lectores.
-- =============================================================================

DROP TABLE public.plant_batch_processing;  -- cascada: RLS, trigger, grants
DROP FUNCTION IF EXISTS public.validate_processing_totals();
