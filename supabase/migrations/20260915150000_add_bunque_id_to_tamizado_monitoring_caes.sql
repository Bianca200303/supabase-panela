-- SUPERSEDIDA por 20260916100000: esta migración partió de una premisa
-- equivocada (que el N° de lote del papel era materia prima, no lote de
-- envasado -- ver la corrección del comentario en 20260913170000). El
-- bunque_id agregado acá se elimina en 20260916100000 y se reemplaza por
-- plant_batch_id, siguiendo el mismo patrón que Sellado/Envasado (CPR-003)
-- y Hermeticidad de Envases (CPR-007), que comparten el mismo código de
-- lote en el papel real. Se deja este archivo tal cual (histórico de lo
-- aplicado) en vez de reescribirlo -- la corrección vive en la migración
-- siguiente.
--
-- Texto original (ya no vigente, ver arriba):
-- Monitoreo del Tamizado (CPR-002): el "N° Lote" de materia prima que pide
-- el papel real no tiene sentido atarlo a una orden ni a un lote de
-- envasado (un mismo lote de campo puede repartirse entre varios bunques a
-- lo largo del tiempo, y un mismo bunque puede repartirse entre varias
-- órdenes -- ver [[project_bunques_tamizado]]). Lo único concreto en el
-- momento de cada inspección es EL BUNQUE que se está tamizando ahí mismo.
--
-- bunque_id reemplaza la escritura manual del N° de lote: la UI pasa a
-- elegir primero el bunque y de ahí los insumos (lotes de campo) que ya
-- tiene cargados ese bunque (plant_homogenization_inputs), en vez de
-- tipear el código a mano. lote_code se mantiene (se sigue guardando texto
-- para el papel/reporte) pero ahora se completa solo, no se escribe.
--
-- Para armar los formatos de una orden: lotes de la orden -> bunques que
-- les asignaron kg (plant_bunque_batch_allocations) -> registros de este
-- control para esos bunques. Reemplaza el filtro por rango de fechas.

ALTER TABLE public.plant_sieve_monitoring_caes
  ADD COLUMN bunque_id uuid REFERENCES public.plant_batch_bunques(id) ON DELETE SET NULL;

CREATE INDEX idx_psmc_bunque ON public.plant_sieve_monitoring_caes (bunque_id);
