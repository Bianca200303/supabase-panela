-- container_number quedó en varchar(20) en el esquema original, pensado para
-- el código ISO 6346 estándar (11 caracteres, ej. MSKU1234567). Ahora que se
-- ingresa manualmente al crear la orden (Fase 1 de la reingeniería), 20
-- caracteres resultan muy justos para cualquier variación real de dato
-- ingresado a mano. Se amplía a texto libre para no seguir topeando esto.
--
-- v_plant_order_summary también depende de esta columna (vía su regla
-- interna _RETURN), así que hay que dropearla antes de poder alterar el tipo
-- y volver a crearla después -- mismo caso que con planned_date.

DROP VIEW IF EXISTS public.v_plant_order_summary;

ALTER TABLE public.plant_containers
  ALTER COLUMN container_number TYPE text;

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
