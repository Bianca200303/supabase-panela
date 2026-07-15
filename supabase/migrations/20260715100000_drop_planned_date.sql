-- planned_date era la única fecha de la orden en el modelo viejo. La
-- reingeniería la reemplaza por 5 fechas específicas del flujo (tamizado
-- inicio/fin, envasado inicio/fin, envío) agregadas en la migración
-- 20260714150000 -- no deben convivir ambas, planned_date queda obsoleta.
--
-- v_plant_order_summary depende de esa columna (la selecciona en el SELECT y
-- en el GROUP BY), así que hay que recrearla sin esa columna antes de poder
-- soltarla -- CREATE OR REPLACE VIEW no permite quitar columnas, solo
-- agregarlas al final, por eso se dropea y se crea de nuevo.

DROP VIEW IF EXISTS public.v_plant_order_summary;

ALTER TABLE public.plant_orders DROP COLUMN IF EXISTS planned_date;

CREATE VIEW "public"."v_plant_order_summary" AS
 SELECT po.id AS order_id,
    po.order_code,
    po.market,
    po.total_kg AS planned_kg,
    po.status,
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
  GROUP BY po.id, po.order_code, po.market, po.total_kg, po.status, pc.container_number, pc.status, pc.bill_of_lading, pc.destination_port, po.cooperative_id;
