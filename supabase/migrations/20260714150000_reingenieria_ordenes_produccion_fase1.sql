-- Reingeniería de Órdenes de Producción — Fase 1 (creación de orden + lotes
-- pedidos). Estamos en etapa de desarrollo, sin datos reales que preservar,
-- así que este cambio reemplaza directamente el modelo viejo en vez de
-- convivir con él o migrar filas existentes.
--
-- order_code / batch_code (los códigos internos autogenerados) NO se tocan:
-- siguen siendo la identidad interna del sistema. Todo lo que agrega esta
-- migración son campos adicionales que ingresa el usuario/cliente.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. plant_clients — catálogo de clientes por cooperativa
-- ─────────────────────────────────────────────────────────────────────────────
-- Sin datos reales todavía (la lista la manda cada cooperativa más adelante).
-- `code` es el correlativo del cliente: texto libre porque puede incluir
-- letras o números según cómo lo maneje cada cooperativa.

CREATE TABLE IF NOT EXISTS public.plant_clients (
  id              uuid        NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id  uuid        NOT NULL,
  name            text        NOT NULL,
  code            text,
  is_active       boolean     NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT plant_clients_pkey PRIMARY KEY (id),
  CONSTRAINT plant_clients_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT plant_clients_code_unique UNIQUE (cooperative_id, code)
);

ALTER TABLE public.plant_clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "plant_clients_select"
  ON public.plant_clients AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_clients_insert"
  ON public.plant_clients AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_clients_update"
  ON public.plant_clients AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_clients_delete"
  ON public.plant_clients AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. plant_orders — campos nuevos del Paso 1 (creación de la orden)
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.plant_orders
  ADD COLUMN IF NOT EXISTS product               text NOT NULL DEFAULT 'Panela',
  ADD COLUMN IF NOT EXISTS client_id              uuid REFERENCES public.plant_clients(id),
  ADD COLUMN IF NOT EXISTS client_order_number    text,
  ADD COLUMN IF NOT EXISTS order_certification    text,
  ADD COLUMN IF NOT EXISTS tamizado_fecha_inicio   date,
  ADD COLUMN IF NOT EXISTS tamizado_fecha_fin      date,
  ADD COLUMN IF NOT EXISTS envasado_fecha_inicio   date,
  ADD COLUMN IF NOT EXISTS envasado_fecha_fin      date,
  ADD COLUMN IF NOT EXISTS fecha_envio             date;

-- customer_name (texto libre) se reemplaza por client_id (FK a plant_clients).
-- Sin datos que preservar en esta etapa.
ALTER TABLE public.plant_orders DROP COLUMN IF EXISTS customer_name;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. plant_production_batches — rediseño del "lote pedido"
-- ─────────────────────────────────────────────────────────────────────────────
-- presentation/unit_weight_kg/planned_quantity (modelo genérico) se
-- reemplazan por el desglose estructurado: cajas + tipo de empaque
-- (bolsa/saco) + cantidad + kg por unidad (variable, se ingresa cada vez).
-- El peso del lote pasa a salir de packaging_count × packaging_kg; las cajas
-- quedan como un dato de conteo logístico aparte, no aportan peso propio.

ALTER TABLE public.plant_production_batches
  ADD COLUMN IF NOT EXISTS client_batch_number  text,
  ADD COLUMN IF NOT EXISTS boxes_count           integer CHECK (boxes_count >= 0),
  ADD COLUMN IF NOT EXISTS packaging_type        text CHECK (packaging_type IN ('bolsa', 'saco')),
  ADD COLUMN IF NOT EXISTS packaging_count       integer CHECK (packaging_count > 0),
  ADD COLUMN IF NOT EXISTS packaging_kg          numeric(10,3) CHECK (packaging_kg > 0);

ALTER TABLE public.plant_production_batches
  DROP COLUMN IF EXISTS presentation,
  DROP COLUMN IF EXISTS unit_weight_kg,
  DROP COLUMN IF EXISTS planned_quantity;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Configuración de conversión kg → quintal (editable sin tocar código)
-- ─────────────────────────────────────────────────────────────────────────────
-- Mismo mecanismo que shelf_life_config / contenedor / despacho: vive en
-- form_configurations, con fallback en código (formConfig.js) si no hay fila.
-- Default 50 kg por quintal, confirmado con un caso real de la cooperativa
-- (17280 kg = 345.6 quintales = 17280 / 345.6 = 50 kg exactos).

INSERT INTO public.form_configurations (cooperative_id, step_key, fields)
VALUES (NULL, 'quintal_config', '[
  {"key":"kg_per_quintal","label":"Kg por quintal","type":"number","default":50}
]')
ON CONFLICT DO NOTHING;
