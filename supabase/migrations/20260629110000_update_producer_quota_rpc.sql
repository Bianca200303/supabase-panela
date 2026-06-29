-- =============================================================================
-- Actualiza get_producer_quota_statuses para usar year en lugar de
-- period_start / period_end, siguiendo la reestructura de producer_quotas.
--
-- El parámetro p_process_date se mantiene (Flutter no cambia) — el año se
-- extrae server-side con EXTRACT(YEAR FROM p_process_date).
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_producer_quota_statuses(
  p_producer_id  uuid,
  p_process_date date DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  quota_id         uuid,
  cert_name        text,
  cupo_kg          numeric,
  acumulado_kg     numeric,
  disponible_kg    numeric,
  porcentaje_usado numeric,
  superado         boolean,
  year             integer,
  notes            text
)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path TO 'public'
AS $function$
DECLARE
  v_year integer := EXTRACT(YEAR FROM p_process_date)::integer;
BEGIN
  RETURN QUERY
  WITH certified_production AS (
    SELECT
      pb.producer_id,
      pbc.batch_cert_id,
      pb.panela_kg
    FROM production_batches pb
    JOIN production_batch_certs pbc ON pbc.production_batch_id = pb.id
    WHERE pb.producer_id = p_producer_id
      AND EXTRACT(YEAR FROM pb.process_date)::integer = v_year
  )
  SELECT
    pq.id                                                              AS quota_id,
    bc.name::text                                                      AS cert_name,
    pq.cupo_kg,
    COALESCE(SUM(cp.panela_kg), 0)::numeric                           AS acumulado_kg,
    (pq.cupo_kg - COALESCE(SUM(cp.panela_kg), 0))::numeric            AS disponible_kg,
    ROUND(
      COALESCE(SUM(cp.panela_kg), 0) / NULLIF(pq.cupo_kg, 0) * 100,
      2
    )::numeric                                                         AS porcentaje_usado,
    (COALESCE(SUM(cp.panela_kg), 0) >= pq.cupo_kg)                   AS superado,
    pq.year,
    pq.notes
  FROM producer_quotas pq
  JOIN batch_certs bc
    ON bc.id = pq.batch_cert_id
  LEFT JOIN certified_production cp
    ON cp.batch_cert_id = pq.batch_cert_id
  WHERE pq.producer_id    = p_producer_id
    AND pq.cooperative_id = public.auth_cooperative_id()
    AND pq.year           = v_year
  GROUP BY
    pq.id, bc.name, pq.cupo_kg, pq.year, pq.notes
  ORDER BY
    bc.name;
END;
$function$;
