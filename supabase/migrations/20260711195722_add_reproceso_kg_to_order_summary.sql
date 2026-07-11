-- Completa v_plant_order_summary con total_reproceso_kg, para que quede
-- consistente con el resto de columnas (tamizada/descarte/merma) ahora que
-- existe reproceso_kg en plant_batch_processing. Esta vista todavía no la
-- consume el frontend, pero conviene no dejarla desactualizada.
--
-- La columna nueva va al final (no se puede insertar en el medio con
-- CREATE OR REPLACE VIEW sin romper el orden de columnas existente).

create or replace view "public"."v_plant_order_summary" as  SELECT po.id AS order_id,
    po.order_code,
    po.market,
    po.total_kg AS planned_kg,
    po.status,
    po.planned_date,
    count(ppb.id) AS total_batches,
    count(
        CASE
            WHEN (ppb.status = 'procesado'::text) THEN 1
            ELSE NULL::integer
        END) AS processed_batches,
    COALESCE(sum(pbp.tamizada_kg), (0)::numeric) AS total_tamizada_kg,
    COALESCE(sum(pbp.descarte_kg), (0)::numeric) AS total_descarte_kg,
    COALESCE(sum(pbp.merma_kg), (0)::numeric) AS total_merma_kg,
    COALESCE(sum(phi_agg.total_input_kg), (0)::numeric) AS total_homogenizado_kg,
        CASE
            WHEN (COALESCE(sum(phi_agg.total_input_kg), (0)::numeric) > (0)::numeric) THEN round(((COALESCE(sum(pbp.tamizada_kg), (0)::numeric) / sum(phi_agg.total_input_kg)) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS rendimiento_pct,
    pc.container_number,
    pc.status AS container_status,
    pc.bill_of_lading,
    pc.destination_port,
    po.cooperative_id,
    COALESCE(sum(pbp.reproceso_kg), (0)::numeric) AS total_reproceso_kg
   FROM ((((public.plant_orders po
     LEFT JOIN public.plant_production_batches ppb ON ((ppb.order_id = po.id)))
     LEFT JOIN public.plant_batch_processing pbp ON ((pbp.plant_batch_id = ppb.id)))
     LEFT JOIN ( SELECT plant_homogenization_inputs.plant_batch_id,
            sum(plant_homogenization_inputs.quantity_kg) AS total_input_kg
           FROM public.plant_homogenization_inputs
          GROUP BY plant_homogenization_inputs.plant_batch_id) phi_agg ON ((phi_agg.plant_batch_id = ppb.id)))
     LEFT JOIN public.plant_containers pc ON ((pc.id = po.container_id)))
  GROUP BY po.id, po.order_code, po.market, po.total_kg, po.status, po.planned_date, pc.container_number, pc.status, pc.bill_of_lading, pc.destination_port, po.cooperative_id;
