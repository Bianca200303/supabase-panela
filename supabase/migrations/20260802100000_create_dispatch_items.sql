-- =============================================================================
-- plant_dispatch_items -- desglose por lote de lo que se carga en un despacho,
-- para poder armar el "Balance de Masas" por orden (SALIDAS por producto/lote,
-- hoy solo existe plant_dispatches.total_loaded_kg agregado por contenedor).
--
-- total_loaded_kg pasa de ser un valor tipeado a mano a un valor derivado
-- (suma de estos items), mismo patrón que plant_orders.total_kg (ver
-- 20260715090000_order_total_kg_derivado_de_lotes.sql).
-- =============================================================================

CREATE TABLE public.plant_dispatch_items (
  id              uuid          NOT NULL DEFAULT gen_random_uuid(),
  cooperative_id  uuid          NOT NULL,
  dispatch_id     uuid          NOT NULL,
  plant_batch_id  uuid          NOT NULL,
  quantity_kg     numeric(10,3) NOT NULL CHECK (quantity_kg > 0),
  created_at      timestamptz   NOT NULL DEFAULT now(),

  CONSTRAINT plant_dispatch_items_pkey PRIMARY KEY (id),
  CONSTRAINT pdi_cooperative_fkey
    FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE,
  CONSTRAINT pdi_dispatch_fkey
    FOREIGN KEY (dispatch_id) REFERENCES public.plant_dispatches(id) ON DELETE CASCADE,
  CONSTRAINT pdi_plant_batch_fkey
    FOREIGN KEY (plant_batch_id) REFERENCES public.plant_production_batches(id),
  CONSTRAINT pdi_unique_dispatch_batch UNIQUE (dispatch_id, plant_batch_id)
);

CREATE INDEX idx_pdi_dispatch ON public.plant_dispatch_items (dispatch_id);
CREATE INDEX idx_pdi_cooperative ON public.plant_dispatch_items (cooperative_id);

ALTER TABLE public.plant_dispatch_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "plant_dispatch_items_select"
  ON public.plant_dispatch_items AS PERMISSIVE FOR SELECT TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_dispatch_items_insert"
  ON public.plant_dispatch_items AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_dispatch_items_update"
  ON public.plant_dispatch_items AS PERMISSIVE FOR UPDATE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role())
  WITH CHECK (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

CREATE POLICY "plant_dispatch_items_delete"
  ON public.plant_dispatch_items AS PERMISSIVE FOR DELETE TO authenticated
  USING (cooperative_id = public.auth_cooperative_id() OR public.is_service_role());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plant_dispatch_items TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.plant_dispatch_items TO service_role;

-- -----------------------------------------------------------------------------
-- total_loaded_kg derivado (mismo patrón que recalc_order_total_kg)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.recalc_dispatch_total_kg()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    target_dispatch_id uuid;
BEGIN
    target_dispatch_id := COALESCE(NEW.dispatch_id, OLD.dispatch_id);

    UPDATE public.plant_dispatches
    SET total_loaded_kg = (
        SELECT COALESCE(SUM(quantity_kg), 0)
        FROM public.plant_dispatch_items
        WHERE dispatch_id = target_dispatch_id
    )
    WHERE id = target_dispatch_id;

    RETURN NULL;
END;
$function$;

CREATE TRIGGER recalc_dispatch_total_kg_trigger
  AFTER INSERT OR UPDATE OR DELETE ON public.plant_dispatch_items
  FOR EACH ROW EXECUTE FUNCTION public.recalc_dispatch_total_kg();

-- -----------------------------------------------------------------------------
-- total_loaded_kg ya no se tipea a mano en el formulario de despacho -- se
-- saca el campo de la config existente (global y, si hubiera, por cooperativa).
-- -----------------------------------------------------------------------------
UPDATE public.form_configurations
SET fields = (
  SELECT COALESCE(jsonb_agg(f), '[]'::jsonb)
  FROM jsonb_array_elements(fields) f
  WHERE f->>'key' != 'total_loaded_kg'
)
WHERE step_key = 'despacho';
