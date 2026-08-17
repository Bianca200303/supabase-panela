-- =============================================================================
-- RPC: get_producer_quotas_by_year
--
-- Propósito: soporta la vista "tabla global" de /cupos-produccion (admin) --
--   una fila por productor × certificación para un año dado, con el mismo
--   cálculo de acumulado/disponible/% usado que get_producer_quota_statuses
--   (20260629110000), pero para TODOS los productores de la cooperativa en
--   vez de uno solo. Evita hacer un round-trip por productor desde el
--   frontend para pintar la tabla completa.
--
-- Seguridad: SECURITY INVOKER + filtro por auth_cooperative_id(), mismo
--   criterio que el resto de RPCs de cupos. La escritura sobre
--   producer_quotas ya quedó restringida a admin_web en
--   20260806100000_restrict_producer_quotas_and_web_users_to_admin.sql;
--   esta consulta es de solo lectura y no necesita repetir esa restricción
--   (el SELECT de producer_quotas sigue abierto a cualquier autenticado de
--   la cooperativa, como lo necesita el móvil).
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_producer_quotas_by_year(
  p_year integer DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::integer
)
RETURNS TABLE (
  quota_id         uuid,
  producer_id      uuid,
  producer_name    text,
  producer_dni     character varying,
  module_name      text,
  cert_id          uuid,
  cert_name        text,
  cupo_kg          numeric,
  acumulado_kg     numeric,
  disponible_kg    numeric,
  porcentaje_usado numeric,
  superado         boolean,
  notes            text
)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path TO 'public'
AS $function$
BEGIN
  RETURN QUERY
  WITH certified_production AS (
    SELECT
      pb.producer_id,
      pbc.batch_cert_id,
      pb.panela_kg
    FROM production_batches pb
    JOIN production_batch_certs pbc ON pbc.production_batch_id = pb.id
    WHERE EXTRACT(YEAR FROM pb.process_date)::integer = p_year
  )
  SELECT
    pq.id                                                    AS quota_id,
    pq.producer_id,
    (p.first_name || ' ' || p.last_name)::text                AS producer_name,
    p.dni                                                     AS producer_dni,
    cm.name::text                                              AS module_name,
    bc.id                                                      AS cert_id,
    bc.name::text                                              AS cert_name,
    pq.cupo_kg,
    COALESCE(SUM(cp.panela_kg), 0)::numeric                  AS acumulado_kg,
    (pq.cupo_kg - COALESCE(SUM(cp.panela_kg), 0))::numeric   AS disponible_kg,
    ROUND(
      COALESCE(SUM(cp.panela_kg), 0) / NULLIF(pq.cupo_kg, 0) * 100,
      2
    )::numeric                                                 AS porcentaje_usado,
    (COALESCE(SUM(cp.panela_kg), 0) >= pq.cupo_kg)           AS superado,
    pq.notes
  FROM producer_quotas pq
  JOIN producers p
    ON p.id = pq.producer_id
  LEFT JOIN coop_modules cm
    ON cm.id = pq.coop_module_id
  JOIN batch_certs bc
    ON bc.id = pq.batch_cert_id
  LEFT JOIN certified_production cp
    ON  cp.producer_id   = pq.producer_id
    AND cp.batch_cert_id = pq.batch_cert_id
  WHERE pq.cooperative_id = public.auth_cooperative_id()
    AND pq.year           = p_year
  GROUP BY
    pq.id, p.first_name, p.last_name, p.dni, cm.name, bc.id, bc.name, pq.cupo_kg, pq.notes
  ORDER BY
    p.first_name, p.last_name, bc.name;
END;
$function$;

GRANT EXECUTE
  ON FUNCTION public.get_producer_quotas_by_year(integer)
  TO authenticated;
