 -- 1. Eliminar la vista (rompe la dependencia en order_id)
  DROP VIEW public.v_plant_order_summary;

  -- 2. Alterar las tablas
  ALTER TABLE plant_containers DROP CONSTRAINT plant_containers_order_id_key;
  ALTER TABLE plant_containers DROP CONSTRAINT plant_containers_order_id_fkey;
  ALTER TABLE plant_containers DROP COLUMN order_id;

  ALTER TABLE plant_orders ADD COLUMN container_id uuid REFERENCES plant_containers(id) ON DELETE SET NULL;

  -- 3. Recrear la vista (ahora container_id ya existe)
  CREATE VIEW public.v_plant_order_summary
  WITH (security_invoker = true) AS
  SELECT
      po.id AS order_id,
      po.order_code,
      po.market,
      po.total_kg AS planned_kg,
      po.status,
      po.planned_date,
      COUNT(ppb.id) AS total_batches,
      COUNT(CASE WHEN ppb.status = 'procesado' THEN 1 END) AS processed_batches,
      COALESCE(SUM(pbp.tamizada_kg), 0) AS total_tamizada_kg,
      COALESCE(SUM(pbp.descarte_kg), 0) AS total_descarte_kg,
      COALESCE(SUM(pbp.merma_kg), 0) AS total_merma_kg,
      COALESCE(SUM(phi_agg.total_input_kg), 0) AS total_homogenizado_kg,
      CASE
          WHEN COALESCE(SUM(phi_agg.total_input_kg), 0) > 0
          THEN ROUND(COALESCE(SUM(pbp.tamizada_kg), 0) / SUM(phi_agg.total_input_kg) * 100, 2)
          ELSE 0
      END AS rendimiento_pct,
      pc.container_number,
      pc.status AS container_status,
      pc.bill_of_lading,
      pc.destination_port,
      po.cooperative_id
  FROM plant_orders po
  LEFT JOIN plant_production_batches ppb ON ppb.order_id = po.id
  LEFT JOIN plant_batch_processing pbp ON pbp.plant_batch_id = ppb.id
  LEFT JOIN (
      SELECT plant_batch_id, SUM(quantity_kg) AS total_input_kg
      FROM plant_homogenization_inputs
      GROUP BY plant_batch_id
  ) phi_agg ON phi_agg.plant_batch_id = ppb.id
  LEFT JOIN plant_containers pc ON pc.id = po.container_id
  GROUP BY po.id, po.order_code, po.market, po.total_kg, po.status, po.planned_date,
           pc.container_number, pc.status, pc.bill_of_lading, pc.destination_port,
           po.cooperative_id;