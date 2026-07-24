-- El panel "Stock acumulado de lotes de origen" (OrdenesPage.jsx) no tenía
-- forma de ordenar cronológicamente porque la vista no exponía ninguna
-- fecha -- se ordenaba por disponible ascendente (agotados primero), no por
-- cuándo entró el lote. Se expone exit_receptions.received_at (la fecha
-- real de recepción del lote en planta), uniendo la tabla que faltaba en
-- la cadena de joins (antes solo se unía exit_reception_items, que
-- referencia a exit_receptions pero no la traía).
--
-- received_at va al FINAL del SELECT a propósito: CREATE OR REPLACE VIEW
-- exige que las columnas ya existentes mantengan su nombre Y posición --
-- solo se pueden agregar columnas nuevas al final (insertarla en el medio
-- corre de lugar a kg_used/kg_available y Postgres lo rechaza con
-- "cannot change name of view column").

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
    er.document_number AS guia_remision,
    ei.item_document_number AS comprobante_acopio,
    er2.received_at
   FROM ((((((((public.exit_items ei
     JOIN public.exit_reception_items eri ON ((eri.exit_item_id = ei.id)))
     JOIN public.exit_receptions er2 ON ((er2.id = eri.exit_reception_id)))
     JOIN public.quality_evaluations qe ON ((qe.exit_item_id = ei.id)))
     JOIN public.production_batches pb ON ((pb.id = ei.production_batch_id)))
     JOIN public.producers p ON ((p.id = pb.producer_id)))
     JOIN public.exit_registrations er ON ((er.id = ei.exit_registration_id)))
     LEFT JOIN public.coop_modules cm ON ((cm.id = p.coop_module_id)))
     LEFT JOIN public.plant_homogenization_inputs phi ON ((phi.source_exit_item_id = ei.id)))
  WHERE (qe.approval_status IS NOT NULL)
  GROUP BY ei.id, ei.production_batch_id, pb.batch_code, p.first_name, p.last_name, cm.name, eri.quantity_kg_received, er2.received_at, qe.humidity_pct, qe.impurities_pct, qe.color, qe.sack_condition, qe.appearance, qe.approval_status, qe.rejected_kg, qe.rejection_reason, ei.cooperative_id, er.document_number, ei.item_document_number;
