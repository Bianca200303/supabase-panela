-- ─────────────────────────────────────────────────────────────────────────────
-- Inserta una inspección de ambientes y todos sus ítems en una sola operación.
-- Antes se hacía en 2 inserts separados desde Flutter: si el segundo fallaba
-- (ej. se corta la conexión a medio camino), quedaba una inspección "padre"
-- sin ningún ítem, indistinguible de una real. SECURITY INVOKER a propósito:
-- corre con los permisos del usuario que llama, así las políticas RLS ya
-- existentes (cooperative_id = auth_cooperative_id()) siguen aplicando igual
-- que con los inserts directos.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.create_environment_inspection(
  p_coop_module_id uuid,
  p_inspection_date date,
  p_cooperative_id uuid,
  p_items jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SET search_path TO 'public'
AS $function$
DECLARE
  v_inspection_id uuid;
BEGIN
  INSERT INTO public.environment_inspections (coop_module_id, inspection_date, cooperative_id)
  VALUES (p_coop_module_id, p_inspection_date, p_cooperative_id)
  RETURNING id INTO v_inspection_id;

  INSERT INTO public.environment_inspection_items (
    environment_inspection_id, area_code, item_code, item_description,
    condition, corrective_actions, observations
  )
  SELECT
    v_inspection_id,
    item->>'area_code',
    item->>'item_code',
    item->>'item_description',
    (item->>'condition')::public.inspection_condition_enum,
    item->>'corrective_actions',
    item->>'observations'
  FROM jsonb_array_elements(p_items) AS item;

  RETURN v_inspection_id;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.create_environment_inspection(uuid, date, uuid, jsonb) TO authenticated;
