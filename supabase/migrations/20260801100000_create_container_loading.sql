-- =============================================================================
-- Packing List (COA-GCA-RG-001) -- registro de la CARGA física de un
-- contenedor: pallet por pallet, más inspección del vehículo/contenedor,
-- verificación del producto, y personas presentes en el embarque.
--
-- Es un paso NUEVO en el flujo, distinto de "Registrar despacho" (Orden de
-- Salida, COA-OIM-RG-007) -- son 2 documentos físicos distintos, con
-- firmantes distintos (Packing List lo firma Calidad/Supervisor al cargar;
-- Orden de Salida lo firma Comercialización al salir el camión). Activa el
-- estado 'cargado' de plant_containers, que ya estaba contemplado en el
-- CHECK constraint del esquema baseline pero nunca se usaba desde la UI.
--
-- Investigado antes de codear (sin encontrar nada reusable): no existe hoy
-- ningún concepto de "pallet individual" en el sistema -- plant_production_batches.pallet_count
-- es solo un total por lote, y los "bunques" (plant_batch_bunques) son una
-- subdivisión del tamizado/homogenizado, anterior al envasado, sin relación
-- con pallets de producto terminado ni con la carga al camión.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. plant_container_loadings -- 1 por contenedor
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_container_loadings (
  id                          uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id              uuid        NOT NULL,
  container_id                uuid        NOT NULL,
  status                      text        NOT NULL DEFAULT 'en_progreso' CHECK (status IN ('en_progreso', 'terminado')),
  responsible_person          text,
  documento_number            text,

  -- Datos de la carga (papel: Tara, Payload, Weight, Placa, Precintos, Horas)
  tara_kg                     numeric(10,2),
  payload_kg                  numeric(10,2),
  placa_camion                text,
  placa_carreta                text,
  precinto_inicial            text,
  precinto_linea              text,
  -- Precinto de Norandino se coloca en este momento (carga), no en el
  -- despacho -- se sacó del step "despacho" en formConfig.js para no
  -- pedirlo dos veces; Orden de Salida lo lee de acá.
  precinto_norandino          text,
  hora_inicio                 time,
  hora_fin                    time,

  -- Control y verificación del vehículo/contenedor
  limpio                      boolean,
  abolladuras_internas        boolean,
  abolladuras_internas_cant   integer,
  abolladuras_externas        boolean,
  abolladuras_externas_cant   integer,
  contenedor_forrado          boolean,
  correcto_forrado            boolean,
  libre_olores                boolean,
  libre_plagas                boolean,
  observaciones_parte_interna text,
  observaciones_parte_externa text,

  -- Control y verificación del producto
  envases_limpios             boolean,
  peso_correcto                boolean,
  etiquetado_correcto          boolean,
  cierre_sellado_adecuado     boolean,
  accion_correctiva           text,

  final_observations          text,
  created_by                  uuid        NOT NULL,
  closed_by                   uuid,
  closed_at                   timestamptz,
  created_at                  timestamptz NOT NULL DEFAULT now(),
  updated_at                  timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_container_loadings_pkey PRIMARY KEY (id),
  CONSTRAINT pcl_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pcl_container_fkey
    FOREIGN KEY (container_id) REFERENCES public.plant_containers(id) ON DELETE CASCADE,
  CONSTRAINT pcl_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT pcl_closed_by_fkey
    FOREIGN KEY (closed_by) REFERENCES public.web_users(id),
  CONSTRAINT pcl_unique_container UNIQUE (container_id)
);

CREATE INDEX idx_pcl_container ON public.plant_container_loadings (container_id);
CREATE INDEX idx_pcl_cooperative ON public.plant_container_loadings (cooperative_id);

ALTER TABLE public.plant_container_loadings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pcl_select"
  ON public.plant_container_loadings AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pcl_insert"
  ON public.plant_container_loadings AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "pcl_update"
  ON public.plant_container_loadings AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_container_loadings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_container_loadings TO service_role;

-- -----------------------------------------------------------------------------
-- 2. plant_container_loading_pallets -- se agregan de a uno, "+ Agregar pallet"
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_container_loading_pallets (
  id                uuid    NOT NULL DEFAULT gen_random_uuid(),
  loading_id        uuid    NOT NULL,
  pallet_number     text    NOT NULL,
  boxes_count       integer,
  plant_batch_id    uuid,
  humidity_pct      numeric(5,2),
  created_by        uuid    NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_container_loading_pallets_pkey PRIMARY KEY (id),
  CONSTRAINT pclp_loading_fkey
    FOREIGN KEY (loading_id) REFERENCES public.plant_container_loadings(id) ON DELETE CASCADE,
  CONSTRAINT pclp_plant_batch_fkey
    FOREIGN KEY (plant_batch_id) REFERENCES public.plant_production_batches(id),
  CONSTRAINT pclp_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT pclp_unique_loading_pallet UNIQUE (loading_id, pallet_number)
);

CREATE INDEX idx_pclp_loading ON public.plant_container_loading_pallets (loading_id);

ALTER TABLE public.plant_container_loading_pallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pclp_select"
  ON public.plant_container_loading_pallets AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_container_loadings l
    WHERE l.id = loading_id AND (l.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pclp_insert"
  ON public.plant_container_loading_pallets AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_container_loadings l
    WHERE l.id = loading_id AND (l.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pclp_delete"
  ON public.plant_container_loading_pallets AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_container_loadings l
    WHERE l.id = loading_id AND (l.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_container_loading_pallets TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_container_loading_pallets TO service_role;

-- -----------------------------------------------------------------------------
-- 3. plant_container_loading_people -- personas presentes en el embarque
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_container_loading_people (
  id            uuid    NOT NULL DEFAULT gen_random_uuid(),
  loading_id    uuid    NOT NULL,
  full_name     text    NOT NULL,
  dni           text,
  role_label    text,
  created_at    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_container_loading_people_pkey PRIMARY KEY (id),
  CONSTRAINT pclpe_loading_fkey
    FOREIGN KEY (loading_id) REFERENCES public.plant_container_loadings(id) ON DELETE CASCADE
);

CREATE INDEX idx_pclpe_loading ON public.plant_container_loading_people (loading_id);

ALTER TABLE public.plant_container_loading_people ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pclpe_select"
  ON public.plant_container_loading_people AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_container_loadings l
    WHERE l.id = loading_id AND (l.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pclpe_insert"
  ON public.plant_container_loading_people AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_container_loadings l
    WHERE l.id = loading_id AND (l.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "pclpe_delete"
  ON public.plant_container_loading_people AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_container_loadings l
    WHERE l.id = loading_id AND (l.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_container_loading_people TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_container_loading_people TO service_role;

CREATE TRIGGER trg_update_pcl_updated_at
  BEFORE UPDATE ON public.plant_container_loadings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
