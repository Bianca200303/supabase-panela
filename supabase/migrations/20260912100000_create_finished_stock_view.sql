-- v_plant_finished_stock -- stock de producto terminado (envasado, todavía
-- sin despachar), para el pedido de CAES de mostrar "Producto terminado
-- disponible" en Inicio/Reportes junto al stock de materia prima
-- (v_plant_available_stock, que ya existía).
--
-- No convierte QQ a kg acá: envasado_qq se guarda en quintales y el factor
-- kg-por-quintal es configurable por cooperativa (form_configurations,
-- lib/formConfig.js loadKgPerQuintal) -- no es un dato de la fila, es
-- config de la app, así que la conversión final queda del lado del
-- cliente (mismo motivo por el que v_plant_available_stock tampoco hace
-- conversiones que dependan de config externa).
--
-- kg_despachado suma plant_dispatch_items por lote -- un lote se puede
-- despachar de a partes (contenedores distintos), por eso es SUM, no un
-- valor único. LEFT JOIN porque un lote recién envasado puede no tener
-- ningún despacho todavía (kg_despachado = 0, no NULL).
create or replace view "public"."v_plant_finished_stock" as
select
  pb.id as plant_batch_id,
  pb.cooperative_id,
  pb.order_id,
  pb.envasado_qq,
  pb.envasado_registered_at,
  coalesce(sum(pdi.quantity_kg), 0) as kg_despachado
from public.plant_production_batches pb
left join public.plant_dispatch_items pdi on pdi.plant_batch_id = pb.id
where pb.envasado_registered_at is not null
group by pb.id, pb.cooperative_id, pb.order_id, pb.envasado_qq, pb.envasado_registered_at;
