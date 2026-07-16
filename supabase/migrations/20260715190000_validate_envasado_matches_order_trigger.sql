-- =============================================================================
-- Validación de negocio del envasado: los conteos registrados deben coincidir
-- con lo planificado en el lote (boxes_count / packaging_count según
-- packaging_type). Defensa en profundidad -- el frontend ya bloquea el
-- guardado si no coincide, esto cubre updates directos vía API/SQL.
--
-- El WHEN evita que el trigger corra en updates que no tocan el envasado
-- (p.ej. el recalc de tamizada_kg disparado desde plant_batch_bunques) --
-- solo valida cuando ya hay un registro de envasado guardado.
--
-- La validación de "panela envasada (QQ) x kg_per_quintal == peso
-- planificado" NO vive acá: kg_per_quintal es config editable en
-- form_configurations, no una columna fija de esta tabla -- queda solo en
-- el frontend, donde ese valor ya se resuelve por cooperativa.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.validate_envasado_matches_order()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.boxes_count IS NOT NULL
     AND NEW.envasado_cajas_envasadas IS DISTINCT FROM NEW.boxes_count THEN
    RAISE EXCEPTION
      'Cajas envasadas (%) no coincide con las cajas planificadas del lote (%)',
      NEW.envasado_cajas_envasadas, NEW.boxes_count;
  END IF;

  IF NEW.packaging_type = 'bolsa' THEN
    IF NEW.packaging_count IS NOT NULL
       AND NEW.envasado_bolsas_envasadas IS DISTINCT FROM NEW.packaging_count THEN
      RAISE EXCEPTION
        'Bolsas envasadas (%) no coincide con la cantidad de bolsas planificada del lote (%)',
        NEW.envasado_bolsas_envasadas, NEW.packaging_count;
    END IF;
    IF NEW.envasado_sacos_envasados IS NOT NULL THEN
      RAISE EXCEPTION 'El lote es de bolsa: no corresponde registrar sacos envasados';
    END IF;

  ELSIF NEW.packaging_type = 'saco' THEN
    IF NEW.packaging_count IS NOT NULL
       AND NEW.envasado_sacos_envasados IS DISTINCT FROM NEW.packaging_count THEN
      RAISE EXCEPTION
        'Sacos envasados (%) no coincide con la cantidad de sacos planificada del lote (%)',
        NEW.envasado_sacos_envasados, NEW.packaging_count;
    END IF;
    IF NEW.envasado_bolsas_envasadas IS NOT NULL
       OR NEW.envasado_bolsas_rechazo_metal IS NOT NULL
       OR NEW.envasado_bolsas_descarte_fabrica IS NOT NULL
       OR NEW.envasado_bolsas_descarte_sellado IS NOT NULL
       OR NEW.envasado_bolsas_descarte_codificado IS NOT NULL THEN
      RAISE EXCEPTION
        'El lote es de saco: los campos de descarte de bolsas (detector de metales, fábrica, sellado, codificado) no aplican';
    END IF;
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE TRIGGER trg_validate_envasado_matches_order
  BEFORE INSERT OR UPDATE ON public.plant_production_batches
  FOR EACH ROW
  WHEN (NEW.envasado_registered_at IS NOT NULL)
  EXECUTE FUNCTION public.validate_envasado_matches_order();
