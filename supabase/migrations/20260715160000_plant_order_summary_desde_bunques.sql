-- =============================================================================
-- v_plant_order_summary -- redefinida sobre plant_batch_bunques en vez de
-- plant_batch_processing.
--
-- bunque_agg pre-agrega a nivel de bunque (1 fila por bunque) antes de
-- unirse a plant_production_batches, para no perder precisión de insumos
-- por bunque. Pero ese join lote->bunque sigue siendo 1:N (un lote puede
-- tener varios bunques), así que cualquier conteo sobre ppb.id debe usar
-- DISTINCT -- si no, un lote con 3 bunques infla total_batches/
-- processed_batches x3.
-- =============================================================================

create or replace view "public"."v_plant_order_summary" as
SELECT
    po.id AS order_id,
    po.order_code,
    po.market,
    po.total_kg AS planned_kg,
    po.status,
    count(DISTINCT ppb.id) AS total_batches,
    count(DISTINCT CASE WHEN ppb.status = 'procesado' THEN ppb.id ELSE NULL END) AS processed_batches,
    COALESCE(sum(bunque_agg.tamizada_kg), 0)    AS total_tamizada_kg,
    COALESCE(sum(bunque_agg.descarte_kg), 0)    AS total_descarte_kg,
    COALESCE(sum(bunque_agg.merma_kg), 0)       AS total_merma_kg,
    COALESCE(sum(bunque_agg.total_input_kg), 0) AS total_homogenizado_kg,
    CASE
        WHEN COALESCE(sum(bunque_agg.total_input_kg), 0) > 0
        THEN round((COALESCE(sum(bunque_agg.tamizada_kg), 0) / sum(bunque_agg.total_input_kg)) * 100, 2)
        ELSE 0
    END AS rendimiento_pct,
    pc.container_number,
    pc.status AS container_status,
    pc.bill_of_lading,
    pc.destination_port,
    po.cooperative_id,
    COALESCE(sum(bunque_agg.reproceso_kg), 0) AS total_reproceso_kg
FROM public.plant_orders po
LEFT JOIN public.plant_production_batches ppb ON ppb.order_id = po.id
LEFT JOIN (
    SELECT
        pbb.id,
        pbb.plant_batch_id,
        pbb.tamizada_kg,
        pbb.reproceso_kg,
        pbb.descarte_kg,
        pbb.merma_kg,
        phi.total_input_kg
    FROM public.plant_batch_bunques pbb
    LEFT JOIN (
        SELECT bunque_id, sum(quantity_kg) AS total_input_kg
        FROM public.plant_homogenization_inputs
        GROUP BY bunque_id
    ) phi ON phi.bunque_id = pbb.id
) bunque_agg ON bunque_agg.plant_batch_id = ppb.id
LEFT JOIN public.plant_containers pc ON pc.id = po.container_id
GROUP BY
    po.id, po.order_code, po.market, po.total_kg, po.status,
    pc.container_number, pc.status, pc.bill_of_lading, pc.destination_port,
    po.cooperative_id;
