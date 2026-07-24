-- Permite registrar tamizada/reproceso/descarte por cantidad de sacos en vez
-- de kg directo -- pedido real de planta ("en la vida real también se puede
-- hacer por sacos"). El kg sigue siendo el dato que manda: estas columnas
-- solo guardan el conteo físico de sacos como referencia adicional, nunca
-- reemplazan tamizada_kg/reproceso_kg/descarte_kg como fuente de verdad del
-- balance de masas -- la web calcula kg = sacos × kg_per_saco (config
-- "saco_tamizado_config") solo como sugerencia precargada, editable, para
-- no introducir imprecisión en la Merma (que se sigue calculando como resto
-- exacto sobre los kg que efectivamente queden guardados).

ALTER TABLE public.plant_batch_bunques
  ADD COLUMN IF NOT EXISTS tamizada_sacos  integer CHECK (tamizada_sacos  >= 0),
  ADD COLUMN IF NOT EXISTS reproceso_sacos integer CHECK (reproceso_sacos >= 0),
  ADD COLUMN IF NOT EXISTS descarte_sacos  integer CHECK (descarte_sacos  >= 0);
