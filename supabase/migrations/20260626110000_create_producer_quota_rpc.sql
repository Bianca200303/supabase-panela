-- =============================================================================
-- Grants faltantes para producer_quotas + RPC get_producer_quota_statuses
--
-- Contexto: la tabla producer_quotas fue creada en la migration anterior
-- (20260626100000). Se agregan aquí los GRANTs estándar del proyecto y el
-- RPC que calcula el estado de cupo de un productor para una fecha dada.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Grants para producer_quotas (patrón estándar del proyecto)
-- -----------------------------------------------------------------------------
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE
  ON TABLE public.producer_quotas TO anon;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE
  ON TABLE public.producer_quotas TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE
  ON TABLE public.producer_quotas TO service_role;

-- =============================================================================
-- RPC: get_producer_quota_statuses
--
-- Propósito: dado un productor y la fecha del lote que se va a registrar,
--   devuelve todos los cupos activos para ese productor en ese período, con
--   el acumulado real de panela certificada producida contra cada cupo.
--
-- Parámetros:
--   p_producer_id  → id del productor seleccionado en el formulario
--   p_process_date → fecha de procesamiento del lote (DEFAULT = hoy).
--                    Se usa la fecha del lote (no "hoy") para que el cupo
--                    correcto sea el que rige en la campaña del lote.
--
-- Retorna: una fila por cada cupo activo del productor para la fecha dada.
--   Retorna vacío si el productor no tiene cupos configurados en ese período
--   → la app interpreta esto como "sin restricción, sin alerta".
--
-- Lógica de acumulado:
--   Solo cuenta panela_kg de lotes que tengan la certificación específica
--   del cupo (vía production_batch_certs). Si un lote tiene 2 certificaciones,
--   su panela_kg suma al cupo de cada una por separado.
--   Confitillo NO se cuenta — el cupo es de panela certificada únicamente.
--
-- Seguridad:
--   SECURITY INVOKER → corre con los permisos del usuario que llama, así las
--   políticas RLS de todas las tablas involucradas siguen aplicando igual
--   que con consultas directas. Mismo criterio que create_environment_inspection.
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
  period_start     date,
  period_end       date,
  notes            text
)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path TO 'public'
AS $function$
BEGIN
  RETURN QUERY
  -- CTE: lotes certificados ya registrados para este productor.
  -- Pre-une production_batches con production_batch_certs para que el JOIN
  -- posterior sea limpio y no cuente lotes sin la cert específica del cupo.
  WITH certified_production AS (
    SELECT
      pb.producer_id,
      pbc.batch_cert_id,
      pb.process_date,
      pb.panela_kg
    FROM production_batches  pb
    JOIN production_batch_certs pbc ON pbc.production_batch_id = pb.id
    WHERE pb.producer_id = p_producer_id
  )
  SELECT
    pq.id                                                             AS quota_id,
    bc.name::text                                                     AS cert_name,
    pq.cupo_kg,
    COALESCE(SUM(cp.panela_kg), 0)::numeric                          AS acumulado_kg,
    (pq.cupo_kg - COALESCE(SUM(cp.panela_kg), 0))::numeric           AS disponible_kg,
    -- NULLIF protege ante cupo_kg = 0 aunque el CHECK lo impide en BD
    ROUND(
      COALESCE(SUM(cp.panela_kg), 0) / NULLIF(pq.cupo_kg, 0) * 100,
      2
    )::numeric                                                        AS porcentaje_usado,
    (COALESCE(SUM(cp.panela_kg), 0) >= pq.cupo_kg)                  AS superado,
    pq.period_start,
    pq.period_end,
    pq.notes
  FROM producer_quotas pq
  JOIN batch_certs bc
    ON bc.id = pq.batch_cert_id
  LEFT JOIN certified_production cp
    ON  cp.batch_cert_id = pq.batch_cert_id
    AND cp.process_date  BETWEEN pq.period_start AND pq.period_end
  WHERE pq.producer_id    = p_producer_id
    AND pq.cooperative_id = public.auth_cooperative_id()
    AND p_process_date    BETWEEN pq.period_start AND pq.period_end
  GROUP BY
    pq.id, bc.name, pq.cupo_kg, pq.period_start, pq.period_end, pq.notes
  ORDER BY
    pq.period_start, bc.name;
END;
$function$;

GRANT EXECUTE
  ON FUNCTION public.get_producer_quota_statuses(uuid, date)
  TO authenticated;
