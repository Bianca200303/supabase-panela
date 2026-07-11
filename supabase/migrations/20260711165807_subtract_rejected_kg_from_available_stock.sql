-- Paso 3/5 del rechazo de calidad por lote individual.
--
-- v_plant_available_stock es la vista que usa el modal de Homogenizado
-- (OrdenesPage.jsx) para saber cuántos kg de cada lote se pueden usar.
-- Hasta ahora no descontaba lo rechazado por calidad, así que un lote
-- rechazado (o parcialmente rechazado) seguía apareciendo con su kg
-- completo disponible para homogeneizar.
--
-- Ahora kg_available también resta rejected_kg. Un lote 100% rechazado
-- queda en 0 kg disponibles y la UI ya lo grisea/deshabilita automáticamente
-- (mismo comportamiento que hoy tiene un lote ya usado por completo) — no
-- hace falta ningún cambio en el frontend para que esto tome efecto.
--
-- También se expone rejection_reason para poder mostrarlo como referencia
-- en el modal más adelante (paso 5).

create or replace view "public"."v_plant_available_stock" as  SELECT ei.id AS exit_item_id,
    ei.production_batch_id,
    pb.batch_code AS field_batch_code,
    (((p.first_name)::text || ' '::text) || (p.last_name)::text) AS producer_name,
    cm.name AS module_name,
    eri.quantity_kg_received,
    COALESCE(sum(phi.quantity_kg), (0)::numeric) AS kg_used,
    (eri.quantity_kg_received - COALESCE(sum(phi.quantity_kg), (0)::numeric) - qe.rejected_kg) AS kg_available,
    qe.humidity_pct,
    qe.impurities_pct,
    qe.color,
    qe.sack_condition,
    qe.appearance,
    qe.approval_status,
    ei.cooperative_id,
    qe.rejected_kg,
    qe.rejection_reason
   FROM ((((((public.exit_items ei
     JOIN public.exit_reception_items eri ON ((eri.exit_item_id = ei.id)))
     JOIN public.quality_evaluations qe ON ((qe.exit_item_id = ei.id)))
     JOIN public.production_batches pb ON ((pb.id = ei.production_batch_id)))
     JOIN public.producers p ON ((p.id = pb.producer_id)))
     LEFT JOIN public.coop_modules cm ON ((cm.id = p.coop_module_id)))
     LEFT JOIN public.plant_homogenization_inputs phi ON ((phi.source_exit_item_id = ei.id)))
  GROUP BY ei.id, ei.production_batch_id, pb.batch_code, p.first_name, p.last_name, cm.name, eri.quantity_kg_received, qe.humidity_pct, qe.impurities_pct, qe.color, qe.sack_condition, qe.appearance, qe.approval_status, qe.rejected_kg, qe.rejection_reason, ei.cooperative_id;
