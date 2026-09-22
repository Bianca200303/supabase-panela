-- =============================================================================
-- Packing List-Nacional (CAESP-PP-BPM-RE-CPR-006 -- el código real del papel
-- dice CPR-006, no CPR-008 como se había asumido antes en comentarios
-- viejos de packingListNacionalCaes.js/ContainerCard.jsx) -- SOLO CAES, ver
-- COOPERATIVE.features.ventaNacionalExportacion en config.js.
--
-- Hasta ahora este documento era un QuickDoc efímero: se armaba al vuelo
-- leyendo plant_containers.extra_data (packing_list_numero,
-- transporte_tramo1/2_guias) -- campos de texto suelto, editables en
-- cualquier momento desde "Registrar despacho nacional", sin ningún estado
-- de "terminado" que los bloquee. Se corrige acá siguiendo EXACTAMENTE el
-- mismo patrón que el Packing List real de exportación
-- (plant_container_loadings, 20260801100000_create_container_loading.sql):
-- 1 registro por contenedor (UNIQUE), con status en_progreso/terminado,
-- bloqueable, reabrible.
--
-- Investigado antes de codear leyendo el ejercicio real completo (50
-- páginas, "ejercicio de trazabilidad nacional completo.pdf") con fechas
-- reales: el Packing List se firma el mismo día que el primer Control de
-- Unidad de Transporte (23/06/2025), pero YA incluye la guía de remisión
-- del tramo final (Piura->Lima) aunque el CUT de ESE tramo recién se
-- complete 4 días después (27/06/2025) -- confirma que las 2 guías de
-- remisión (interno/final) son datos propios del Packing List, conocidos
-- de antemano, NO derivados de si ya existe o no el control de transporte
-- correspondiente. Ver plant_transport_unit_controls_caes
-- (20260916130000) para el detalle del control de transporte en sí.
--
-- factura_comercial y certificado_transaccion NO se mueven acá -- siguen
-- viviendo en plant_containers.extra_data porque son datos de la VENTA
-- (aplican tanto a Nacional como a Exportación), no del Packing List en sí.
-- =============================================================================

CREATE TABLE public.plant_packing_list_nacional_caes (
  id                   uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id       uuid        NOT NULL,
  container_id         uuid        NOT NULL,
  status               text        NOT NULL DEFAULT 'en_progreso' CHECK (status IN ('en_progreso', 'terminado')),
  responsible_person   text,
  packing_list_numero  text,
  guia_tramo_interno   text,
  guia_tramo_final     text,
  final_observations   text,
  created_by           uuid        NOT NULL,
  closed_by            uuid,
  closed_at            timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_packing_list_nacional_caes_pkey PRIMARY KEY (id),
  CONSTRAINT plncc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT plncc_container_fkey
    FOREIGN KEY (container_id) REFERENCES public.plant_containers(id) ON DELETE CASCADE,
  CONSTRAINT plncc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id),
  CONSTRAINT plncc_closed_by_fkey
    FOREIGN KEY (closed_by) REFERENCES public.web_users(id),
  CONSTRAINT plncc_unique_container UNIQUE (container_id)
);

CREATE INDEX idx_plncc_container ON public.plant_packing_list_nacional_caes (container_id);
CREATE INDEX idx_plncc_cooperative ON public.plant_packing_list_nacional_caes (cooperative_id);

ALTER TABLE public.plant_packing_list_nacional_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "plncc_select"
  ON public.plant_packing_list_nacional_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plncc_insert"
  ON public.plant_packing_list_nacional_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plncc_update"
  ON public.plant_packing_list_nacional_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_packing_list_nacional_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_packing_list_nacional_caes TO service_role;

CREATE TRIGGER trg_update_plncc_updated_at
  BEFORE UPDATE ON public.plant_packing_list_nacional_caes
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
