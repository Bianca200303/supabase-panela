-- =============================================================================
-- Registro de envasado por lote (plant_production_batches). A diferencia del
-- tamizado (que se subdivide en bunques), el envasado es un segundo proceso
-- posterior con exactamente 1 registro por lote -- se agregan como columnas
-- directas en vez de una tabla hija, igual criterio que tamizada_kg.
--
-- Puede registrarse en cualquier momento (no depende de status = 'procesado').
-- envasado_registered_at NULL = todavía no se registró envasado para el lote.
--
-- envasado_turno se guarda en ASCII ('manana'/'tarde') para no depender de
-- que el CHECK y el cliente manejen bien la tilde -- la UI sigue mostrando
-- "Mañana"/"Tarde".
-- =============================================================================

ALTER TABLE public.plant_production_batches
  ADD COLUMN IF NOT EXISTS envasado_turno                        text
    CHECK (envasado_turno IN ('manana', 'tarde')),
  ADD COLUMN IF NOT EXISTS envasado_qq                            numeric(10,3)
    CHECK (envasado_qq >= 0),
  ADD COLUMN IF NOT EXISTS envasado_descarte_barrido_kg           numeric(10,3)
    CHECK (envasado_descarte_barrido_kg >= 0),
  ADD COLUMN IF NOT EXISTS envasado_cajas_envasadas               integer
    CHECK (envasado_cajas_envasadas >= 0),
  ADD COLUMN IF NOT EXISTS envasado_cajas_descarte                integer
    CHECK (envasado_cajas_descarte >= 0),
  ADD COLUMN IF NOT EXISTS envasado_bolsas_envasadas              integer
    CHECK (envasado_bolsas_envasadas >= 0),
  ADD COLUMN IF NOT EXISTS envasado_sacos_envasados               integer
    CHECK (envasado_sacos_envasados >= 0),
  ADD COLUMN IF NOT EXISTS envasado_bolsas_rechazo_metal          integer
    CHECK (envasado_bolsas_rechazo_metal >= 0),
  ADD COLUMN IF NOT EXISTS envasado_bolsas_descarte_fabrica       integer
    CHECK (envasado_bolsas_descarte_fabrica >= 0),
  ADD COLUMN IF NOT EXISTS envasado_bolsas_descarte_sellado       integer
    CHECK (envasado_bolsas_descarte_sellado >= 0),
  ADD COLUMN IF NOT EXISTS envasado_bolsas_descarte_codificado    integer
    CHECK (envasado_bolsas_descarte_codificado >= 0),
  ADD COLUMN IF NOT EXISTS envasado_registered_by                 uuid,
  ADD COLUMN IF NOT EXISTS envasado_registered_at                 timestamptz;
