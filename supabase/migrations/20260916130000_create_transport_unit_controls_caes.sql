-- =============================================================================
-- Control de la Unidad de Transporte (CAESP-PP-BPM-RE-CUT-001) -- SOLO
-- CAES, ver COOPERATIVE.features.ventaNacionalExportacion en config.js.
-- Aplica a Nacional Y Exportación (decidido con el usuario 2026-09-16): el
-- tramo Montero->Paita de una exportación también es un camión real que
-- necesita esta misma inspección -- un solo control reusable, en vez de
-- mantener dos versiones del mismo concepto.
--
-- Reemplaza a transporte_tramo1_codigo/transporte_tramo2_codigo (texto
-- libre en plant_containers.extra_data, sin ningún control real detrás) --
-- ver [[project_despacho_nacional_caes]]. Es un registro NUEVO por cada
-- tramo de transporte real, no dos campos fijos: el papel real no fuerza
-- "Montero -> Piura -> Lima" -- el "lugar o punto de destino" es texto
-- libre, y puede haber cualquier cantidad de tramos (no siempre 2). Cada
-- despacho (contenedor) tiene 0..N controles de este tipo, agregados de a
-- uno según van ocurriendo -- mismo patrón "+ Nuevo registro" que
-- MonitoreoTamizadoCaesModal.jsx/SelladoEnvasadoCaesModal.jsx.
--
-- Campos leídos directamente del papel real (página 10 y 13 del ejercicio
-- de trazabilidad nacional completo) -- NO tiene casillero de correlativo
-- propio (nada de "CUT-045"): cada instancia se identifica por
-- fecha + guía + lugar de partida/destino, igual criterio "registro plano
-- por fecha" que CPR-002/CPR-003/CPR-007 (sin formato_codigo autogenerado
-- como sí tienen Cloro/Plagas/Verificación).
--
-- guia_remision: se prefiltra (no se fuerza por FK) con la guía
-- correspondiente de plant_packing_list_nacional_caes cuando el despacho es
-- Nacional -- confirmado con el usuario que ambas guías "deben coincidir",
-- pero como el Packing List se completa ANTES de que exista el CUT del
-- tramo final (evidencia real: PL firmado 23/06, CUT del tramo final
-- recién 27/06), no puede ser un vínculo rígido -- se sincroniza al crear
-- el registro (prefill editable), no con FK ni trigger.
-- =============================================================================

CREATE TABLE public.plant_transport_unit_controls_caes (
  id                            uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id                uuid        NOT NULL,
  container_id                  uuid        NOT NULL,
  control_date                  date        NOT NULL,

  lugar_partida                 text,
  lugar_destino                 text,
  guia_remision                 text,

  -- Datos transportista
  transportista_razon_social    text,
  transportista_constancia_mtc  text,
  chofer_nombre                 text,
  chofer_licencia               text,

  -- Datos del vehículo
  vehiculo_marca                text,
  vehiculo_placa                text,
  vehiculo_tipo                 text,
  cuenta_soat                   boolean     NOT NULL DEFAULT true,
  cuenta_revision_tecnica       boolean     NOT NULL DEFAULT true,
  cuenta_botiquin                boolean     NOT NULL DEFAULT true,
  cuenta_extintor                boolean     NOT NULL DEFAULT true,
  vehiculo_limpio                boolean     NOT NULL DEFAULT true,
  libre_olores_extranos          boolean     NOT NULL DEFAULT true,
  carga_en_buen_estado           boolean     NOT NULL DEFAULT true,
  observaciones_vehiculo         text,
  accion_correctiva_vehiculo     text,

  -- Datos de la carga
  presentacion                  text,
  total_unidades                integer,
  limpieza_carga_limpio         boolean     NOT NULL DEFAULT true,
  hermeticidad_carga            text        CHECK (hermeticidad_carga IN ('B', 'R', 'M')),
  transporto_otros_productos    boolean     NOT NULL DEFAULT false,
  evidencia_combustible          boolean     NOT NULL DEFAULT false,
  libre_fisuras                  boolean     NOT NULL DEFAULT true,
  observaciones_carga            text,

  -- Desinfección
  desinfeccion_producto          text        CHECK (desinfeccion_producto IN ('cloro', 'alcohol')),
  responsable_desinfeccion       text,

  observaciones_generales        text,
  created_by                     uuid        NOT NULL,
  created_at                     timestamptz NOT NULL DEFAULT now(),
  updated_at                     timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_transport_unit_controls_caes_pkey PRIMARY KEY (id),
  CONSTRAINT ptucc_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT ptucc_container_fkey
    FOREIGN KEY (container_id) REFERENCES public.plant_containers(id) ON DELETE CASCADE,
  CONSTRAINT ptucc_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.web_users(id)
);

CREATE INDEX idx_ptucc_container ON public.plant_transport_unit_controls_caes (container_id);
CREATE INDEX idx_ptucc_cooperative ON public.plant_transport_unit_controls_caes (cooperative_id);

ALTER TABLE public.plant_transport_unit_controls_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ptucc_select"
  ON public.plant_transport_unit_controls_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "ptucc_insert"
  ON public.plant_transport_unit_controls_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "ptucc_update"
  ON public.plant_transport_unit_controls_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "ptucc_delete"
  ON public.plant_transport_unit_controls_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_transport_unit_controls_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_transport_unit_controls_caes TO service_role;

CREATE TRIGGER trg_update_ptucc_updated_at
  BEFORE UPDATE ON public.plant_transport_unit_controls_caes
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- Estibadores -- tabla hija, N por control (mismo patrón que
-- plant_container_loading_people de Norandino: nombre, DNI, rol/vestimenta).
-- -----------------------------------------------------------------------------
CREATE TABLE public.plant_transport_unit_control_estibadores_caes (
  id                    uuid    NOT NULL DEFAULT gen_random_uuid(),
  control_id            uuid    NOT NULL,
  full_name             text    NOT NULL,
  dni                   text,
  vestimenta_completa   boolean NOT NULL DEFAULT true,
  epp_zapatos_cerrados  boolean NOT NULL DEFAULT true,
  epp_mascarilla        boolean NOT NULL DEFAULT true,
  epp_guantes           boolean NOT NULL DEFAULT true,
  epp_otro              text,
  observacion           text,
  accion_correctiva     text,
  created_at            timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_transport_unit_control_estibadores_caes_pkey PRIMARY KEY (id),
  CONSTRAINT ptuce_control_fkey
    FOREIGN KEY (control_id) REFERENCES public.plant_transport_unit_controls_caes(id) ON DELETE CASCADE
);

CREATE INDEX idx_ptuce_control ON public.plant_transport_unit_control_estibadores_caes (control_id);

ALTER TABLE public.plant_transport_unit_control_estibadores_caes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ptuce_select"
  ON public.plant_transport_unit_control_estibadores_caes AS PERMISSIVE FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_transport_unit_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "ptuce_insert"
  ON public.plant_transport_unit_control_estibadores_caes AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_transport_unit_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "ptuce_update"
  ON public.plant_transport_unit_control_estibadores_caes AS PERMISSIVE FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_transport_unit_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.plant_transport_unit_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

CREATE POLICY "ptuce_delete"
  ON public.plant_transport_unit_control_estibadores_caes AS PERMISSIVE FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.plant_transport_unit_controls_caes c
    WHERE c.id = control_id AND (c.cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_transport_unit_control_estibadores_caes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_transport_unit_control_estibadores_caes TO service_role;
