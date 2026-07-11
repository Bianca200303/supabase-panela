-- Expone la Guía de remisión (document_number de exit_registrations) en
-- v_plant_available_stock, para poder mostrarla junto a cualquier dato de
-- rechazo/disponibilidad y así rastrear de qué envío físico vino cada lote.

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
    qe.rejection_reason,
    er.document_number AS guia_remision
   FROM (((((((public.exit_items ei
     JOIN public.exit_reception_items eri ON ((eri.exit_item_id = ei.id)))
     JOIN public.quality_evaluations qe ON ((qe.exit_item_id = ei.id)))
     JOIN public.production_batches pb ON ((pb.id = ei.production_batch_id)))
     JOIN public.producers p ON ((p.id = pb.producer_id)))
     JOIN public.exit_registrations er ON ((er.id = ei.exit_registration_id)))
     LEFT JOIN public.coop_modules cm ON ((cm.id = p.coop_module_id)))
     LEFT JOIN public.plant_homogenization_inputs phi ON ((phi.source_exit_item_id = ei.id)))
  GROUP BY ei.id, ei.production_batch_id, pb.batch_code, p.first_name, p.last_name, cm.name, eri.quantity_kg_received, qe.humidity_pct, qe.impurities_pct, qe.color, qe.sack_condition, qe.appearance, qe.approval_status, qe.rejected_kg, qe.rejection_reason, ei.cooperative_id, er.document_number;
