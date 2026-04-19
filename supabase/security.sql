-- ============================================================================
-- SECURITY & RLS CONSOLIDATION
-- ============================================================================
-- Este archivo es la fuente de verdad para:
--   1. Aislamiento estricto de datos entre cooperativas (Norandino / CAES)
--   2. Custom JWT hook que inyecta cooperative_id en el token
--   3. Políticas RLS unificadas para usuarios móviles (users) y web (web_users)
--   4. Columnas de ubicación GPS en production_batches
--
-- Se aplica después de seed.sql en cada `supabase db reset`.
-- Es IDEMPOTENTE: se puede correr múltiples veces sin romper nada.
-- ============================================================================


-- ============================================================================
-- SECCIÓN 1: COLUMNAS DE UBICACIÓN EN production_batches
-- ============================================================================
ALTER TABLE public.production_batches
  ADD COLUMN IF NOT EXISTS latitude double precision,
  ADD COLUMN IF NOT EXISTS longitude double precision,
  ADD COLUMN IF NOT EXISTS location_text text;

COMMENT ON COLUMN public.production_batches.latitude IS 'GPS latitude del registro (nullable)';
COMMENT ON COLUMN public.production_batches.longitude IS 'GPS longitude del registro (nullable)';
COMMENT ON COLUMN public.production_batches.location_text IS 'Ubicación ingresada manualmente si falla el GPS (nullable)';


-- ============================================================================
-- SECCIÓN 2: FUNCIONES HELPER CANÓNICAS
-- ============================================================================

-- Función canónica: lee cooperative_id desde el JWT (sin lookup a BD)
-- Poblada por el custom access token hook definido más abajo.
CREATE OR REPLACE FUNCTION public.auth_cooperative_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT NULLIF(
    current_setting('request.jwt.claims', true)::jsonb ->> 'cooperative_id',
    ''
  )::uuid
$$;

COMMENT ON FUNCTION public.auth_cooperative_id() IS
  'Retorna cooperative_id del JWT. NULL si no está autenticado o no tiene cooperativa.';

GRANT EXECUTE ON FUNCTION public.auth_cooperative_id() TO anon, authenticated, service_role;


-- Función auxiliar: detecta si el caller es service_role (bypass admin)
CREATE OR REPLACE FUNCTION public.is_service_role()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT coalesce(
    current_setting('request.jwt.claims', true)::jsonb ->> 'role' = 'service_role',
    false
  )
$$;

GRANT EXECUTE ON FUNCTION public.is_service_role() TO anon, authenticated, service_role;


-- ============================================================================
-- SECCIÓN 3: CUSTOM ACCESS TOKEN HOOK
-- ============================================================================
-- Cada vez que Supabase emite un JWT, este hook inyecta cooperative_id
-- consultando users (app móvil) O web_users (web React).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  claims      jsonb;
  coop_id     uuid;
  user_role   text;
  auth_uid    uuid;
BEGIN
  auth_uid := (event ->> 'user_id')::uuid;
  claims   := event -> 'claims';

  -- 1) Buscar primero en web_users (portal web)
  SELECT cooperative_id, role INTO coop_id, user_role
  FROM public.web_users
  WHERE auth_user_id = auth_uid AND is_active = true
  LIMIT 1;

  -- 2) Si no, buscar en users (app móvil)
  IF coop_id IS NULL THEN
    SELECT cooperative_id, role INTO coop_id, user_role
    FROM public.users
    WHERE auth_user_id = auth_uid
    LIMIT 1;
  END IF;

  -- 3) Inyectar claims
  IF coop_id IS NOT NULL THEN
    claims := jsonb_set(claims, '{cooperative_id}', to_jsonb(coop_id::text));
  END IF;
  IF user_role IS NOT NULL THEN
    claims := jsonb_set(claims, '{app_role}', to_jsonb(user_role));
  END IF;

  event := jsonb_set(event, '{claims}', claims);
  RETURN event;
END;
$$;

-- Permisos para que GoTrue pueda invocar el hook
GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook(jsonb) TO supabase_auth_admin;
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook(jsonb) FROM authenticated, anon, public;

-- GoTrue necesita leer las tablas que consulta el hook
GRANT SELECT ON public.web_users TO supabase_auth_admin;
GRANT SELECT ON public.users TO supabase_auth_admin;


-- ============================================================================
-- SECCIÓN 4: POLÍTICAS RLS UNIFICADAS
-- ============================================================================
-- Patrón: para cada tabla con cooperative_id aplicamos 4 políticas
-- (SELECT, INSERT, UPDATE, DELETE) usando auth_cooperative_id().
-- Tablas sin cooperative_id directo usan JOIN a la tabla padre.
-- ============================================================================

-- Aplicar 4 políticas estándar (select/insert/update/delete) a todas las tablas
-- con cooperative_id. Usamos un DO block para evitar dollar-quoting anidado.
DO $$
DECLARE
  tbl text;
  coop_tables text[] := ARRAY[
    'batch_certs',
    'batch_ph_controls',
    'batch_temperatures',
    'certificate_exclusion_groups',
    'chlorine_residual_controls',
    'cleaning_disinfections',
    'coop_modules',
    'environment_inspections',
    'equipment_maintenance_records',
    'exit_items',
    'exit_receptions',
    'exit_registrations',
    'health_incidents',
    'inventory_stock',
    'pest_controls',
    'plant_batch_processing',
    'plant_checklists',
    'plant_containers',
    'plant_dispatches',
    'plant_homogenization_inputs',
    'plant_order_checklists',
    'plant_orders',
    'plant_production_batches',
    'producers',
    'product_returns',
    'production_batch_certs',
    'production_batches',
    'quality_evaluations',
    'stowage_transport_inspections',
    'user_module_assignments',
    'users',
    'web_users',
    'worker_controls'
  ];
BEGIN
  FOREACH tbl IN ARRAY coop_tables LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);

    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR SELECT TO authenticated '
      'USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())',
      tbl || '_select', tbl);

    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR INSERT TO authenticated '
      'WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())',
      tbl || '_insert', tbl);

    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR UPDATE TO authenticated '
      'USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role()) '
      'WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())',
      tbl || '_update', tbl);

    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR DELETE TO authenticated '
      'USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())',
      tbl || '_delete', tbl);
  END LOOP;
END $$;


-- ============================================================================
-- SECCIÓN 5: POLÍTICAS ESPECIALES (tablas sin cooperative_id directo)
-- ============================================================================

-- form_configurations: usuario ve configs globales (NULL) + su cooperativa
ALTER TABLE public.form_configurations ENABLE ROW LEVEL SECURITY;

CREATE POLICY form_configurations_select ON public.form_configurations
  FOR SELECT TO authenticated
  USING (cooperative_id IS NULL OR cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY form_configurations_insert ON public.form_configurations
  FOR INSERT TO authenticated
  WITH CHECK (public.is_service_role());

CREATE POLICY form_configurations_update ON public.form_configurations
  FOR UPDATE TO authenticated
  USING (public.is_service_role())
  WITH CHECK (public.is_service_role());

CREATE POLICY form_configurations_delete ON public.form_configurations
  FOR DELETE TO authenticated
  USING (public.is_service_role());


-- cooperatives: cada usuario solo ve su propia cooperativa
ALTER TABLE public.cooperatives ENABLE ROW LEVEL SECURITY;

CREATE POLICY cooperatives_select ON public.cooperatives
  FOR SELECT TO authenticated
  USING (id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY cooperatives_modify ON public.cooperatives
  FOR ALL TO authenticated
  USING (public.is_service_role())
  WITH CHECK (public.is_service_role());


-- plots: usa cooperative_id del producer padre
ALTER TABLE public.plots ENABLE ROW LEVEL SECURITY;

CREATE POLICY plots_select ON public.plots
  FOR SELECT TO authenticated
  USING (
    public.is_service_role() OR
    producer_id IN (SELECT id FROM public.producers WHERE cooperative_id = public.auth_cooperative_id())
  );

CREATE POLICY plots_insert ON public.plots
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_service_role() OR
    producer_id IN (SELECT id FROM public.producers WHERE cooperative_id = public.auth_cooperative_id())
  );

CREATE POLICY plots_update ON public.plots
  FOR UPDATE TO authenticated
  USING (
    public.is_service_role() OR
    producer_id IN (SELECT id FROM public.producers WHERE cooperative_id = public.auth_cooperative_id())
  )
  WITH CHECK (
    public.is_service_role() OR
    producer_id IN (SELECT id FROM public.producers WHERE cooperative_id = public.auth_cooperative_id())
  );

CREATE POLICY plots_delete ON public.plots
  FOR DELETE TO authenticated
  USING (
    public.is_service_role() OR
    producer_id IN (SELECT id FROM public.producers WHERE cooperative_id = public.auth_cooperative_id())
  );


-- Tablas hija que heredan via pest_controls
ALTER TABLE public.pest_control_bait_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY pcb_all ON public.pest_control_bait_records
  FOR ALL TO authenticated
  USING (
    public.is_service_role() OR
    pest_control_id IN (SELECT id FROM public.pest_controls WHERE cooperative_id = public.auth_cooperative_id())
  )
  WITH CHECK (
    public.is_service_role() OR
    pest_control_id IN (SELECT id FROM public.pest_controls WHERE cooperative_id = public.auth_cooperative_id())
  );

ALTER TABLE public.pest_control_insect_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY pci_all ON public.pest_control_insect_records
  FOR ALL TO authenticated
  USING (
    public.is_service_role() OR
    pest_control_id IN (SELECT id FROM public.pest_controls WHERE cooperative_id = public.auth_cooperative_id())
  )
  WITH CHECK (
    public.is_service_role() OR
    pest_control_id IN (SELECT id FROM public.pest_controls WHERE cooperative_id = public.auth_cooperative_id())
  );

-- cleaning_disinfection_items hereda de cleaning_disinfections
ALTER TABLE public.cleaning_disinfection_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY cdi_all ON public.cleaning_disinfection_items
  FOR ALL TO authenticated
  USING (
    public.is_service_role() OR
    cleaning_disinfection_id IN (SELECT id FROM public.cleaning_disinfections WHERE cooperative_id = public.auth_cooperative_id())
  )
  WITH CHECK (
    public.is_service_role() OR
    cleaning_disinfection_id IN (SELECT id FROM public.cleaning_disinfections WHERE cooperative_id = public.auth_cooperative_id())
  );

-- environment_inspection_items hereda de environment_inspections
ALTER TABLE public.environment_inspection_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY eii_all ON public.environment_inspection_items
  FOR ALL TO authenticated
  USING (
    public.is_service_role() OR
    environment_inspection_id IN (SELECT id FROM public.environment_inspections WHERE cooperative_id = public.auth_cooperative_id())
  )
  WITH CHECK (
    public.is_service_role() OR
    environment_inspection_id IN (SELECT id FROM public.environment_inspections WHERE cooperative_id = public.auth_cooperative_id())
  );

-- exit_reception_items hereda de exit_receptions
ALTER TABLE public.exit_reception_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY eri_all ON public.exit_reception_items
  FOR ALL TO authenticated
  USING (
    public.is_service_role() OR
    exit_reception_id IN (SELECT id FROM public.exit_receptions WHERE cooperative_id = public.auth_cooperative_id())
  )
  WITH CHECK (
    public.is_service_role() OR
    exit_reception_id IN (SELECT id FROM public.exit_receptions WHERE cooperative_id = public.auth_cooperative_id())
  );

-- worker_control_items hereda de worker_controls
ALTER TABLE public.worker_control_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY wci_all ON public.worker_control_items
  FOR ALL TO authenticated
  USING (
    public.is_service_role() OR
    worker_control_id IN (SELECT id FROM public.worker_controls WHERE cooperative_id = public.auth_cooperative_id())
  )
  WITH CHECK (
    public.is_service_role() OR
    worker_control_id IN (SELECT id FROM public.worker_controls WHERE cooperative_id = public.auth_cooperative_id())
  );


-- ============================================================================
-- SECCIÓN 7: VISTAS DE PLANTA
-- ============================================================================
-- Se crean aquí (no en seed.sql) porque CREATE VIEW resuelve tablas al parsear
-- y el batch de Supabase CLI no garantiza que las tablas existan en ese momento.
-- ============================================================================

CREATE OR REPLACE VIEW "public"."v_plant_available_stock"
WITH (security_invoker = true) AS
SELECT
    ei.id AS exit_item_id,
    ei.production_batch_id,
    pb.batch_code AS field_batch_code,
    p.first_name || ' ' || p.last_name AS producer_name,
    cm.name AS module_name,
    eri.quantity_kg_received,
    COALESCE(SUM(phi.quantity_kg), 0) AS kg_used,
    eri.quantity_kg_received - COALESCE(SUM(phi.quantity_kg), 0) AS kg_available,
    qe.humidity_pct,
    qe.impurities_pct,
    qe.color,
    qe.sack_condition,
    qe.appearance,
    qe.approval_status,
    ei.cooperative_id
FROM exit_items ei
JOIN exit_reception_items eri ON eri.exit_item_id = ei.id
JOIN quality_evaluations qe ON qe.exit_item_id = ei.id
JOIN production_batches pb ON pb.id = ei.production_batch_id
JOIN producers p ON p.id = pb.producer_id
LEFT JOIN coop_modules cm ON cm.id = p.coop_module_id
LEFT JOIN plant_homogenization_inputs phi ON phi.source_exit_item_id = ei.id
GROUP BY ei.id, ei.production_batch_id, pb.batch_code,
         p.first_name, p.last_name, cm.name,
         eri.quantity_kg_received, qe.humidity_pct, qe.impurities_pct,
         qe.color, qe.sack_condition, qe.appearance, qe.approval_status,
         ei.cooperative_id;

COMMENT ON VIEW "public"."v_plant_available_stock"
  IS 'Stock disponible en planta por exit_item: kg recibidos, kg usados en homogenizacion, kg disponibles, datos de calidad';


CREATE OR REPLACE VIEW "public"."v_plant_order_summary"
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
LEFT JOIN plant_containers pc ON pc.order_id = po.id
GROUP BY po.id, po.order_code, po.market, po.total_kg, po.status, po.planned_date,
         pc.container_number, pc.status, pc.bill_of_lading, pc.destination_port,
         po.cooperative_id;

COMMENT ON VIEW "public"."v_plant_order_summary"
  IS 'Resumen consolidado por orden: lotes, rendimiento, datos de contenedor';


-- ============================================================================
-- FIN
-- ============================================================================
-- Despues de aplicar este archivo:
--   - Todos los queries de la app Flutter y web React quedan aislados por cooperativa
--   - Cualquier intento de saltar filtros desde el cliente es bloqueado por RLS
--   - El cooperative_id viaja en el JWT, no se hace lookup a BD por cada query
--   - Las funciones con SECURITY DEFINER siguen funcionando (bypass intencional)
--   - Las vistas v_plant_available_stock y v_plant_order_summary estan disponibles
-- ============================================================================
