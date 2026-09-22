-- Impurezas de recepción: algunas cooperativas anotan el dato en mg/kg en
-- vez de %. Son la misma magnitud a distinta escala (1% = 10000 mg/kg), así
-- que en vez de un flag de unidad se agrega una columna companion: la app
-- carga cualquiera de los dos campos y completa el otro por conversión
-- exacta, y ambos quedan guardados. El resto de la app sigue leyendo
-- siempre impurities_pct.
--
-- Se amplía la precisión de impurities_pct (antes numeric(5,2)) para no
-- perder los valores traza que resultan de convertir desde mg/kg
-- (ej. 150 mg/kg = 0.015%).
--
-- v_plant_available_stock depende de esta columna (rule _RETURN), así que
-- Postgres no deja hacer ALTER COLUMN TYPE con la vista viva -- se dropea y
-- se recrea idéntica a su última definición (20260721090000).

drop view "public"."v_plant_available_stock";

alter table "public"."quality_evaluations"
  alter column "impurities_pct" type numeric(9,6);

alter table "public"."quality_evaluations"
  add column "impurities_mgkg" numeric(10,2);

alter table "public"."quality_evaluations"
  add constraint "quality_evaluations_impurities_mgkg_check"
  check (impurities_mgkg >= 0) not valid;

alter table "public"."quality_evaluations"
  validate constraint "quality_evaluations_impurities_mgkg_check";

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

-- DROP VIEW no conserva privilegios que se hayan otorgado fuera de las
-- migraciones (ej. desde Supabase Studio) -- se reotorgan explícitamente,
-- igual que el resto de las tablas/vistas del proyecto.
grant select on table "public"."v_plant_available_stock" to "anon";
grant select on table "public"."v_plant_available_stock" to "authenticated";
grant select on table "public"."v_plant_available_stock" to "service_role";
