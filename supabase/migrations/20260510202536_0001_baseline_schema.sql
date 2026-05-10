create type "public"."inspection_condition_enum" as enum ('compliant', 'non_compliant');

create type "public"."sack_condition_enum" as enum ('good', 'regular', 'bad');

create type "public"."vehicle_condition_enum" as enum ('adequate', 'deficient');

create sequence "public"."plot_code_seq_03f07aea_bab1_4924_8df3_cb1143c88b3e";

create sequence "public"."plot_code_seq_0861d2d5_bf02_43a5_b5ec_da2aa1d2ef12";

create sequence "public"."plot_code_seq_1c0888c2_721b_473f_b29c_56c136bce99c";

create sequence "public"."plot_code_seq_2f8f7e65_667c_4304_a88c_78276ab50bed";

create sequence "public"."plot_code_seq_3e92d99c_eaad_46fc_8001_559624013be2";

create sequence "public"."plot_code_seq_4416e931_dc7a_4335_9fe6_11b9942415e7";

create sequence "public"."plot_code_seq_467daa44_b98f_4f2b_acfb_7bfe919e987b";

create sequence "public"."plot_code_seq_4e1d14d3_fa84_4514_bafb_de6431059712";

create sequence "public"."plot_code_seq_550e8400_e29b_41d4_a716_446655440001";

create sequence "public"."plot_code_seq_550e8400_e29b_41d4_a716_446655440002";

create sequence "public"."plot_code_seq_5c1ffcb5_dcc1_4d88_adaf_a1d467a222b0";

create sequence "public"."plot_code_seq_5d8a65f4_19f5_4d41_b156_39b7aeec1555";

create sequence "public"."plot_code_seq_62265d98_7f6d_409a_a522_8ebdd735a1c1";

create sequence "public"."plot_code_seq_69cefbe8_603e_4c1c_b37d_2971c16e89be";

create sequence "public"."plot_code_seq_6e8f21b3_7187_4735_9e56_69a262cc1b3f";

create sequence "public"."plot_code_seq_71485f07_3b10_4d09_94d9_6352569ae986";

create sequence "public"."plot_code_seq_85653e12_c855_4a1d_96b3_4c0e8ba26514";

create sequence "public"."plot_code_seq_88bd5093_5bd5_4a0f_9323_a0f27acd3511";

create sequence "public"."plot_code_seq_99be2690_72f0_4cff_9540_7675fe9913d2";

create sequence "public"."plot_code_seq_9cdfa200_7e71_4526_8256_8bccbce564f1";

create sequence "public"."plot_code_seq_9e44175c_3fc3_4bd8_a778_cf5abe3e2b45";

create sequence "public"."plot_code_seq_a0876aac_a532_481f_a31c_b61dd796e078";

create sequence "public"."plot_code_seq_b347f253_d11a_4e8b_a65e_3f7498354b3e";

create sequence "public"."plot_code_seq_ba0f08df_5a43_4cb1_be28_42e8dde39173";

create sequence "public"."plot_code_seq_bad0a93f_317c_4e2f_8176_a3c65753f7e5";

create sequence "public"."plot_code_seq_baf5424c_b5f2_45b9_a471_b75cd44d09a8";

create sequence "public"."plot_code_seq_e5e02cbe_4148_4c78_b8f6_805e446a611e";

create sequence "public"."plot_code_seq_eb0481df_90fd_4b27_94e2_e7615220fe2f";


  create table "public"."batch_certs" (
    "id" uuid not null default gen_random_uuid(),
    "name" character varying(100) not null,
    "cooperative_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "is_active" boolean default true,
    "exclusion_group_id" uuid,
    "is_default" boolean default false
      );


alter table "public"."batch_certs" enable row level security;


  create table "public"."batch_ph_controls" (
    "id" uuid not null default gen_random_uuid(),
    "production_batch_id" uuid not null,
    "record_date" timestamp with time zone default now(),
    "regulator_type" character varying(100) not null default 'cal'::character varying,
    "ph_initial" numeric(4,2) not null,
    "ph_final" numeric(4,2) not null,
    "brix" numeric(5,2),
    "corrective_action" text,
    "cooperative_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "regulator_quantity_kg" numeric(10,2),
    "regulator_quantity_value" numeric(10,2),
    "regulator_quantity_unit" character varying(10)
      );


alter table "public"."batch_ph_controls" enable row level security;


  create table "public"."batch_temperatures" (
    "id" uuid not null default gen_random_uuid(),
    "production_batch_id" uuid not null,
    "temperature" numeric(6,2) not null,
    "sequence_number" integer not null,
    "cooperative_id" uuid not null,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."batch_temperatures" enable row level security;


  create table "public"."certificate_exclusion_groups" (
    "id" uuid not null default gen_random_uuid(),
    "name" character varying(100) not null,
    "display_name" character varying(100) not null,
    "description" text,
    "is_required" boolean default true,
    "cooperative_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "is_active" boolean default true
      );


alter table "public"."certificate_exclusion_groups" enable row level security;


  create table "public"."chlorine_residual_controls" (
    "id" uuid not null default gen_random_uuid(),
    "cooperative_id" uuid not null,
    "coop_module_id" uuid not null,
    "control_date" date not null,
    "control_time" time without time zone not null default '06:00:00'::time without time zone,
    "measurement_point_1" numeric(4,2) not null,
    "measurement_point_2" numeric(4,2) not null,
    "corrective_actions" text,
    "observations" text,
    "responsible_person" text not null,
    "created_by" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."chlorine_residual_controls" enable row level security;


  create table "public"."cleaning_disinfection_items" (
    "id" uuid not null default gen_random_uuid(),
    "cleaning_disinfection_id" uuid not null,
    "area_code" character varying(50) not null,
    "point_code" character varying(50) not null,
    "point_description" text not null,
    "uses_chlorine" boolean not null default true,
    "uses_detergent" boolean not null default true,
    "uses_other_product" boolean not null default true,
    "observations" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."cleaning_disinfection_items" enable row level security;


  create table "public"."cleaning_disinfections" (
    "id" uuid not null default gen_random_uuid(),
    "cooperative_id" uuid not null,
    "coop_module_id" uuid not null,
    "cleaning_date" date not null,
    "cleaning_types" text[] not null,
    "general_observations" text,
    "created_by" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."cleaning_disinfections" enable row level security;


  create table "public"."coop_modules" (
    "id" uuid not null default gen_random_uuid(),
    "name" character varying(255) not null,
    "cooperative_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "is_active" boolean default true,
    "default_density" double precision default 1.08
      );


alter table "public"."coop_modules" enable row level security;


  create table "public"."cooperatives" (
    "id" uuid not null default gen_random_uuid(),
    "name" character varying(255) not null,
    "code" character varying(50) not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "is_active" boolean default true,
    "cane_density" numeric(5,4) default 1.05
      );


alter table "public"."cooperatives" enable row level security;


  create table "public"."environment_inspection_items" (
    "id" uuid not null default gen_random_uuid(),
    "environment_inspection_id" uuid not null,
    "area_code" character varying(50) not null,
    "item_code" character varying(50) not null,
    "item_description" text not null,
    "condition" public.inspection_condition_enum not null,
    "corrective_actions" text,
    "observations" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."environment_inspection_items" enable row level security;


  create table "public"."environment_inspections" (
    "id" uuid not null default gen_random_uuid(),
    "coop_module_id" uuid not null,
    "inspection_date" date not null default CURRENT_DATE,
    "cooperative_id" uuid not null,
    "created_by" character varying(8) not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."environment_inspections" enable row level security;


  create table "public"."equipment_maintenance_records" (
    "id" uuid not null default gen_random_uuid(),
    "cooperative_id" uuid not null,
    "coop_module_id" uuid not null,
    "maintenance_date" date not null,
    "equipment_name" text not null,
    "maintenance_type" text not null,
    "maintenance_cause" text not null,
    "materials_used" text,
    "duration_hours" numeric(10,2) not null,
    "responsible_person" text not null,
    "created_by" character varying(8) not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."equipment_maintenance_records" enable row level security;


  create table "public"."exit_items" (
    "id" uuid not null default gen_random_uuid(),
    "exit_registration_id" uuid not null,
    "production_batch_id" uuid not null,
    "quantity_kg" numeric(10,2) not null,
    "is_autoconsumo" boolean not null default false,
    "bags_count" numeric(10,2) default 0,
    "unit_price" numeric(10,2) default 0,
    "total_value" numeric(12,2) generated always as ((quantity_kg * unit_price)) stored,
    "notes" text,
    "cooperative_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "item_document_number" character varying(100)
      );


alter table "public"."exit_items" enable row level security;


  create table "public"."exit_reception_items" (
    "id" uuid not null default gen_random_uuid(),
    "exit_reception_id" uuid not null,
    "exit_item_id" uuid not null,
    "quantity_kg_sent" numeric(10,2) not null,
    "quantity_kg_received" numeric(10,2) not null,
    "discrepancy_kg" numeric(10,2) generated always as ((quantity_kg_sent - quantity_kg_received)) stored,
    "discrepancy_reason" text,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."exit_reception_items" enable row level security;


  create table "public"."exit_receptions" (
    "id" uuid not null default gen_random_uuid(),
    "exit_registration_id" uuid not null,
    "cooperative_id" uuid not null,
    "received_by" uuid not null,
    "received_at" timestamp with time zone not null default now(),
    "notes" text,
    "status" character varying(20) not null default 'recepcionado'::character varying,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."exit_receptions" enable row level security;


  create table "public"."exit_registrations" (
    "id" uuid not null default gen_random_uuid(),
    "exit_code" character varying(50) not null,
    "document_number" character varying(100),
    "exit_date" date not null default CURRENT_DATE,
    "total_kg" numeric(10,2) not null default 0,
    "exit_type" character varying(50) not null default 'SALIDA'::character varying,
    "destination" character varying(100),
    "notes" text,
    "cooperative_id" uuid not null,
    "created_by" character varying(8) not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."exit_registrations" enable row level security;


  create table "public"."form_configurations" (
    "id" uuid not null default gen_random_uuid(),
    "cooperative_id" uuid,
    "step_key" text not null,
    "fields" jsonb not null default '[]'::jsonb,
    "is_active" boolean not null default true,
    "version" integer not null default 1,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."form_configurations" enable row level security;


  create table "public"."formatos_control_cloro" (
    "id" uuid not null default gen_random_uuid(),
    "formato_codigo" character varying(30),
    "cooperative_id" uuid not null,
    "module_id" uuid not null,
    "date_from" date not null,
    "date_to" date not null,
    "emitted_by" uuid,
    "emitted_by_name" text,
    "emitted_at" timestamp with time zone,
    "firmantes" jsonb not null default '[]'::jsonb,
    "status" character varying(20) not null default 'draft'::character varying,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."formatos_control_cloro" enable row level security;


  create table "public"."formatos_control_mp_ph" (
    "id" uuid not null default gen_random_uuid(),
    "formato_codigo" character varying(30) not null,
    "cooperative_id" uuid not null,
    "module_id" uuid not null,
    "date_from" date not null,
    "date_to" date not null,
    "emitted_by" uuid,
    "emitted_by_name" text,
    "emitted_at" timestamp with time zone,
    "approved_at" timestamp with time zone,
    "firmantes" jsonb not null default '[]'::jsonb,
    "status" character varying(20) not null default 'draft'::character varying,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."formatos_control_mp_ph" enable row level security;


  create table "public"."formatos_control_mp_ph_lotes" (
    "formato_id" uuid not null,
    "lote_campo_id" uuid not null
      );


alter table "public"."formatos_control_mp_ph_lotes" enable row level security;


  create table "public"."formatos_control_personal" (
    "id" uuid not null default gen_random_uuid(),
    "formato_codigo" character varying(30),
    "cooperative_id" uuid not null,
    "production_batch_id" uuid not null,
    "emitted_by" uuid,
    "emitted_by_name" text,
    "emitted_at" timestamp with time zone,
    "firmantes" jsonb not null default '[]'::jsonb,
    "status" character varying(20) not null default 'draft'::character varying,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."formatos_control_personal" enable row level security;


  create table "public"."formatos_control_plagas" (
    "id" uuid not null default gen_random_uuid(),
    "formato_codigo" character varying(30),
    "cooperative_id" uuid not null,
    "module_id" uuid not null,
    "date_from" date not null,
    "date_to" date not null,
    "emitted_by" uuid,
    "emitted_by_name" text,
    "emitted_at" timestamp with time zone,
    "firmantes" jsonb not null default '[]'::jsonb,
    "status" character varying(20) not null default 'draft'::character varying,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."formatos_control_plagas" enable row level security;


  create table "public"."formatos_inspeccion_ambientes" (
    "id" uuid not null default gen_random_uuid(),
    "formato_codigo" character varying(30),
    "cooperative_id" uuid not null,
    "module_id" uuid not null,
    "inspection_id" uuid not null,
    "inspection_date" date not null,
    "emitted_by" uuid,
    "emitted_by_name" text,
    "emitted_at" timestamp with time zone,
    "firmantes" jsonb not null default '[]'::jsonb,
    "status" character varying(20) not null default 'draft'::character varying,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."formatos_inspeccion_ambientes" enable row level security;


  create table "public"."formatos_limpieza_desinfeccion" (
    "id" uuid not null default gen_random_uuid(),
    "formato_codigo" character varying(30),
    "cooperative_id" uuid not null,
    "module_id" uuid not null,
    "date_from" date not null,
    "date_to" date not null,
    "emitted_by" uuid,
    "emitted_by_name" text,
    "emitted_at" timestamp with time zone,
    "firmantes" jsonb not null default '[]'::jsonb,
    "status" character varying(20) not null default 'draft'::character varying,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."formatos_limpieza_desinfeccion" enable row level security;


  create table "public"."formatos_mantenimiento_equipos" (
    "id" uuid not null default gen_random_uuid(),
    "formato_codigo" character varying(30),
    "cooperative_id" uuid not null,
    "module_id" uuid not null,
    "date_from" date not null,
    "date_to" date not null,
    "emitted_by" uuid,
    "emitted_by_name" text,
    "emitted_at" timestamp with time zone,
    "firmantes" jsonb not null default '[]'::jsonb,
    "status" character varying(20) not null default 'draft'::character varying,
    "created_at" timestamp with time zone default now()
      );



  create table "public"."formatos_seguimiento_salud" (
    "id" uuid not null default gen_random_uuid(),
    "formato_codigo" character varying(30),
    "cooperative_id" uuid not null,
    "module_id" uuid not null,
    "date_from" date not null,
    "date_to" date not null,
    "emitted_by" uuid,
    "emitted_by_name" text,
    "emitted_at" timestamp with time zone,
    "firmantes" jsonb not null default '[]'::jsonb,
    "status" character varying(20) not null default 'draft'::character varying,
    "created_at" timestamp with time zone default now()
      );



  create table "public"."health_incidents" (
    "id" uuid not null default gen_random_uuid(),
    "coop_module_id" uuid not null,
    "employee_name" text not null,
    "work_area" text not null,
    "registration_date" date not null default CURRENT_DATE,
    "symptoms_description" text not null,
    "action_rest" boolean not null default false,
    "action_medical_attention" boolean not null default false,
    "action_relocation" boolean not null default false,
    "action_medication" boolean not null default false,
    "action_other" boolean not null default false,
    "other_action_detail" text,
    "return_date" date,
    "certificate_presented" boolean not null default false,
    "cooperative_id" uuid not null,
    "created_by" character varying(8) not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."health_incidents" enable row level security;


  create table "public"."inventory_stock" (
    "id" uuid not null default gen_random_uuid(),
    "production_batch_id" uuid not null,
    "current_kg" numeric(10,2) not null default 0,
    "reserved_kg" numeric(10,2) not null default 0,
    "available_kg" numeric(10,2) generated always as ((current_kg - reserved_kg)) stored,
    "cooperative_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."inventory_stock" enable row level security;


  create table "public"."pest_control_bait_records" (
    "id" uuid not null default gen_random_uuid(),
    "pest_control_id" uuid not null,
    "product_name" text not null,
    "quantity" numeric(10,2) not null,
    "unit" text not null,
    "bait_stations" jsonb not null default '[]'::jsonb,
    "bait_observations" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."pest_control_bait_records" enable row level security;


  create table "public"."pest_control_insect_records" (
    "id" uuid not null default gen_random_uuid(),
    "pest_control_id" uuid not null,
    "product_name" text not null,
    "quantity" numeric(10,2) not null,
    "unit" text not null,
    "insect_data" jsonb not null default '[]'::jsonb,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."pest_control_insect_records" enable row level security;


  create table "public"."pest_controls" (
    "id" uuid not null default gen_random_uuid(),
    "cooperative_id" uuid not null,
    "coop_module_id" uuid not null,
    "control_date" date not null,
    "created_by" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."pest_controls" enable row level security;


  create table "public"."plant_batch_processing" (
    "id" uuid not null default gen_random_uuid(),
    "plant_batch_id" uuid not null,
    "tamizada_kg" numeric(10,3) not null,
    "descarte_kg" numeric(10,3) not null,
    "merma_kg" numeric(10,3) not null,
    "processed_by" uuid not null,
    "processed_at" timestamp with time zone default now(),
    "cooperative_id" uuid not null
      );


alter table "public"."plant_batch_processing" enable row level security;


  create table "public"."plant_checklists" (
    "id" uuid not null default gen_random_uuid(),
    "plant_batch_id" uuid not null,
    "type" text not null,
    "items" jsonb not null default '[]'::jsonb,
    "general_notes" text,
    "filled_by" uuid not null,
    "filled_at" timestamp with time zone default now(),
    "cooperative_id" uuid not null
      );


alter table "public"."plant_checklists" enable row level security;


  create table "public"."plant_containers" (
    "id" uuid not null default gen_random_uuid(),
    "container_number" character varying(20),
    "seal_number" character varying(30),
    "container_size" character varying(10) default '20'::character varying,
    "max_capacity_kg" numeric(10,3),
    "booking_number" character varying(50),
    "bill_of_lading" character varying(50),
    "shipping_line" character varying(100),
    "destination_port" character varying(100),
    "departure_date" date,
    "estimated_arrival" date,
    "status" text not null default 'preparando'::text,
    "notes" text,
    "cooperative_id" uuid not null,
    "created_by" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "extra_data" jsonb default '{}'::jsonb
      );


alter table "public"."plant_containers" enable row level security;


  create table "public"."plant_dispatches" (
    "id" uuid not null default gen_random_uuid(),
    "container_id" uuid not null,
    "dispatch_date" date not null default CURRENT_DATE,
    "dispatch_code" text not null,
    "loaded_by" uuid not null,
    "verified_by" uuid,
    "total_loaded_kg" numeric(10,3),
    "seal_verified" boolean default false,
    "temperature_at_load" numeric(5,2),
    "humidity_at_load" numeric(5,2),
    "notes" text,
    "cooperative_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "extra_data" jsonb default '{}'::jsonb
      );


alter table "public"."plant_dispatches" enable row level security;


  create table "public"."plant_homogenization_inputs" (
    "id" uuid not null default gen_random_uuid(),
    "plant_batch_id" uuid not null,
    "source_exit_item_id" uuid not null,
    "quantity_kg" numeric(10,3) not null,
    "cooperative_id" uuid not null,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."plant_homogenization_inputs" enable row level security;


  create table "public"."plant_hygiene_areas" (
    "id" uuid not null default gen_random_uuid(),
    "cooperative_id" uuid not null,
    "control_date" date not null default CURRENT_DATE,
    "area_code" text not null,
    "observations" text,
    "created_by" uuid not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );



  create table "public"."plant_hygiene_worker_criteria" (
    "id" uuid not null default gen_random_uuid(),
    "worker_id" uuid not null,
    "item_code" text not null,
    "complies" boolean not null default true,
    "created_at" timestamp with time zone not null default now()
      );



  create table "public"."plant_hygiene_workers" (
    "id" uuid not null default gen_random_uuid(),
    "hygiene_area_id" uuid not null,
    "cooperative_id" uuid not null,
    "worker_name" text not null,
    "created_at" timestamp with time zone not null default now()
      );



  create table "public"."plant_order_checklists" (
    "id" uuid not null default gen_random_uuid(),
    "order_id" uuid not null,
    "type" text not null,
    "items" jsonb not null default '[]'::jsonb,
    "general_notes" text,
    "filled_by" uuid not null,
    "filled_at" timestamp with time zone default now(),
    "cooperative_id" uuid not null
      );


alter table "public"."plant_order_checklists" enable row level security;


  create table "public"."plant_orders" (
    "id" uuid not null default gen_random_uuid(),
    "order_code" text not null,
    "market" text not null,
    "planned_date" date not null,
    "status" text not null default 'en_proceso'::text,
    "cooperative_id" uuid not null,
    "created_by" uuid not null,
    "notes" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "total_kg" numeric(10,3),
    "container_id" uuid,
    "extra_data" jsonb default '{}'::jsonb
      );


alter table "public"."plant_orders" enable row level security;


  create table "public"."plant_production_batches" (
    "id" uuid not null default gen_random_uuid(),
    "batch_code" text not null,
    "order_id" uuid not null,
    "brand" text not null,
    "presentation" text not null,
    "unit_weight_kg" numeric(10,3) not null,
    "planned_quantity" integer not null,
    "status" text not null default 'pendiente_homogenizado'::text,
    "cooperative_id" uuid not null,
    "notes" text,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."plant_production_batches" enable row level security;


  create table "public"."plots" (
    "id" uuid not null default gen_random_uuid(),
    "code" character varying(100),
    "producer_id" uuid not null,
    "is_active" boolean default true,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "name" character varying(200) not null default ''::character varying,
    "default_extraction_percentage" numeric(5,2) default NULL::numeric,
    "default_cachaza_percentage" numeric(5,2) default NULL::numeric
      );


alter table "public"."plots" enable row level security;


  create table "public"."producers" (
    "id" uuid not null default gen_random_uuid(),
    "first_name" character varying(255) not null,
    "last_name" character varying(255) not null,
    "dni" character varying(8) not null,
    "cooperative_id" uuid not null,
    "coop_module_id" uuid not null,
    "is_member" boolean not null default true,
    "is_active" boolean default true,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "appagrop_code" character varying(50),
    "default_extraction_percentage" numeric(5,2) default 62.5,
    "default_cachaza_percentage" numeric(5,2) default 2.5
      );


alter table "public"."producers" enable row level security;


  create table "public"."product_returns" (
    "id" uuid not null default gen_random_uuid(),
    "production_batch_id" uuid not null,
    "cooperative_id" uuid not null,
    "client_name" text not null,
    "return_date" date not null default CURRENT_DATE,
    "quantity_kg" numeric not null,
    "quantity_sacks" integer not null default 0,
    "return_reason" text not null,
    "observations" text,
    "created_by" character varying(8) not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."product_returns" enable row level security;


  create table "public"."production_batch_certs" (
    "id" uuid not null default gen_random_uuid(),
    "production_batch_id" uuid not null,
    "batch_cert_id" uuid not null,
    "cooperative_id" uuid not null,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."production_batch_certs" enable row level security;


  create table "public"."production_batches" (
    "id" uuid not null default gen_random_uuid(),
    "batch_code" character varying(255) not null,
    "harvest_date" date not null,
    "process_date" date not null,
    "cane_kg" numeric(10,2) not null,
    "juice_liters" numeric(10,2) not null,
    "efficiency_percentage" numeric(5,2) default 0,
    "producer_id" uuid not null,
    "cooperative_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "plot_id" uuid,
    "panela_kg" numeric(10,2) default 0,
    "confitillo_kg" numeric(10,2) default 0,
    "porcentaje_extraccion" numeric(5,2),
    "cachaza_percentage" numeric(5,2),
    "cane_density" numeric(5,4) default 1.05,
    "latitude" double precision,
    "longitude" double precision,
    "location_text" text,
    "observations" text,
    "registered_by_user_id" character varying(8)
      );


alter table "public"."production_batches" enable row level security;


  create table "public"."quality_evaluations" (
    "id" uuid not null default gen_random_uuid(),
    "exit_reception_id" uuid not null,
    "exit_item_id" uuid not null,
    "cooperative_id" uuid not null,
    "evaluated_by" uuid not null,
    "evaluated_at" timestamp with time zone not null default now(),
    "humidity_pct" numeric(5,2),
    "impurities_pct" numeric(5,2),
    "color" character varying(50),
    "sack_condition" character varying(20),
    "appearance" character varying(20),
    "notes" text,
    "created_at" timestamp with time zone default now(),
    "approval_status" character varying(30) default NULL::character varying,
    "rejection_reason" text,
    "extra_data" jsonb default '{}'::jsonb
      );


alter table "public"."quality_evaluations" enable row level security;


  create table "public"."stowage_transport_inspections" (
    "id" uuid not null default gen_random_uuid(),
    "exit_registration_id" uuid not null,
    "inspection_date" date not null default CURRENT_DATE,
    "cooperative_id" uuid not null,
    "carrier_name" text not null,
    "carrier_ruc" character varying(11),
    "carrier_license" character varying(20),
    "vehicle_brand" text not null,
    "vehicle_plate" character varying(10) not null,
    "vehicle_condition" public.vehicle_condition_enum not null,
    "has_spare_tire" boolean not null default false,
    "has_valid_soat" boolean not null default false,
    "has_technical_review" boolean not null default false,
    "has_first_aid_kit" boolean not null default false,
    "has_fire_extinguisher" boolean not null default false,
    "has_gps" boolean not null default false,
    "has_cleaning_supplies" boolean not null default false,
    "floors_clean" boolean not null default false,
    "walls_clean" boolean not null default false,
    "ceilings_clean" boolean not null default false,
    "no_strange_odors" boolean not null default false,
    "tarp_clean" boolean not null default false,
    "pallets_clean" boolean not null default false,
    "sack_clean_condition" public.sack_condition_enum not null,
    "sack_tied_condition" public.sack_condition_enum not null,
    "observations" text,
    "created_by" character varying(8) not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "registered_by_user_id" character varying(8),
    "formato_codigo" character varying(30),
    "emitted_by" uuid,
    "emitted_by_name" text,
    "emitted_at" timestamp with time zone,
    "firmantes" jsonb not null default '[]'::jsonb,
    "status" character varying(20) not null default 'draft'::character varying
      );


alter table "public"."stowage_transport_inspections" enable row level security;


  create table "public"."user_module_assignments" (
    "user_id" character varying(8) not null,
    "cooperative_id" uuid not null,
    "coop_module_id" uuid not null,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."user_module_assignments" enable row level security;


  create table "public"."users" (
    "user_id" character varying(8) not null,
    "first_name" character varying(100) not null,
    "last_name" character varying(100) not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "email" character varying(255),
    "auth_user_id" uuid,
    "cooperative_id" uuid not null,
    "role" text not null default 'productor'::text,
    "coop_module_id" uuid,
    "is_support" boolean default false
      );


alter table "public"."users" enable row level security;


  create table "public"."web_users" (
    "id" uuid not null default gen_random_uuid(),
    "auth_user_id" uuid not null,
    "cooperative_id" uuid not null,
    "first_name" character varying(100) not null,
    "last_name" character varying(100) not null,
    "role" character varying(50) not null default 'recepcionista'::character varying,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "username" character varying(50) not null
      );


alter table "public"."web_users" enable row level security;


  create table "public"."worker_control_items" (
    "id" uuid not null default gen_random_uuid(),
    "worker_control_id" uuid,
    "worker_name" text not null,
    "uniform_complete" boolean default true,
    "no_makeup" boolean default true,
    "nails_short_clean" boolean default true,
    "nails_no_polish" boolean default true,
    "hands_clean" boolean default true,
    "no_jewelry" boolean default true,
    "hair_covered" boolean default true,
    "no_beard" boolean default true,
    "no_wounds" boolean default true,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."worker_control_items" enable row level security;


  create table "public"."worker_controls" (
    "id" uuid not null default gen_random_uuid(),
    "cooperative_id" uuid not null,
    "production_batch_id" uuid not null,
    "worker_name" text not null,
    "work_area" text not null,
    "uniform_complete" boolean not null default true,
    "no_makeup" boolean not null default true,
    "nails_short_clean" boolean not null default true,
    "nails_no_polish" boolean not null default true,
    "hands_clean" boolean not null default true,
    "no_jewelry" boolean not null default true,
    "hair_covered" boolean not null default true,
    "no_beard" boolean not null default true,
    "no_wounds" boolean not null default true,
    "observations" text,
    "created_by" character varying(8) not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."worker_controls" enable row level security;

CREATE UNIQUE INDEX batch_certs_pkey ON public.batch_certs USING btree (id);

CREATE UNIQUE INDEX batch_ph_controls_pkey ON public.batch_ph_controls USING btree (id);

CREATE UNIQUE INDEX batch_temperatures_pkey ON public.batch_temperatures USING btree (id);

CREATE UNIQUE INDEX batch_temperatures_production_batch_id_sequence_number_key ON public.batch_temperatures USING btree (production_batch_id, sequence_number);

CREATE UNIQUE INDEX certificate_exclusion_groups_pkey ON public.certificate_exclusion_groups USING btree (id);

CREATE UNIQUE INDEX chlorine_residual_controls_pkey ON public.chlorine_residual_controls USING btree (id);

CREATE UNIQUE INDEX cleaning_disinfection_items_pkey ON public.cleaning_disinfection_items USING btree (id);

CREATE UNIQUE INDEX cleaning_disinfections_module_date_key ON public.cleaning_disinfections USING btree (coop_module_id, cleaning_date);

CREATE UNIQUE INDEX cleaning_disinfections_pkey ON public.cleaning_disinfections USING btree (id);

CREATE UNIQUE INDEX coop_modules_pkey ON public.coop_modules USING btree (id);

CREATE UNIQUE INDEX cooperatives_code_key ON public.cooperatives USING btree (code);

CREATE UNIQUE INDEX cooperatives_name_key ON public.cooperatives USING btree (name);

CREATE UNIQUE INDEX cooperatives_pkey ON public.cooperatives USING btree (id);

CREATE UNIQUE INDEX environment_inspection_items_pkey ON public.environment_inspection_items USING btree (id);

CREATE UNIQUE INDEX environment_inspections_pkey ON public.environment_inspections USING btree (id);

CREATE UNIQUE INDEX equipment_maintenance_records_pkey ON public.equipment_maintenance_records USING btree (id);

CREATE UNIQUE INDEX exit_items_pkey ON public.exit_items USING btree (id);

CREATE UNIQUE INDEX exit_reception_items_exit_item_id_key ON public.exit_reception_items USING btree (exit_item_id);

CREATE UNIQUE INDEX exit_reception_items_pkey ON public.exit_reception_items USING btree (id);

CREATE UNIQUE INDEX exit_receptions_exit_registration_id_key ON public.exit_receptions USING btree (exit_registration_id);

CREATE UNIQUE INDEX exit_receptions_pkey ON public.exit_receptions USING btree (id);

CREATE UNIQUE INDEX exit_registrations_exit_code_key ON public.exit_registrations USING btree (exit_code);

CREATE UNIQUE INDEX exit_registrations_pkey ON public.exit_registrations USING btree (id);

CREATE UNIQUE INDEX fccl_code_key ON public.formatos_control_cloro USING btree (formato_codigo);

CREATE UNIQUE INDEX fccl_pkey ON public.formatos_control_cloro USING btree (id);

CREATE UNIQUE INDEX fcmptph_formato_codigo_key ON public.formatos_control_mp_ph USING btree (formato_codigo);

CREATE UNIQUE INDEX fcmptph_lotes_pkey ON public.formatos_control_mp_ph_lotes USING btree (formato_id, lote_campo_id);

CREATE UNIQUE INDEX fcmptph_pkey ON public.formatos_control_mp_ph USING btree (id);

CREATE UNIQUE INDEX fcp_code_key ON public.formatos_control_plagas USING btree (formato_codigo);

CREATE UNIQUE INDEX fcp_pkey ON public.formatos_control_plagas USING btree (id);

CREATE UNIQUE INDEX fcpo_codigo_key ON public.formatos_control_personal USING btree (formato_codigo);

CREATE UNIQUE INDEX fcpo_pkey ON public.formatos_control_personal USING btree (id);

CREATE UNIQUE INDEX fcpo_unique_batch ON public.formatos_control_personal USING btree (cooperative_id, production_batch_id);

CREATE UNIQUE INDEX fiae_code_key ON public.formatos_inspeccion_ambientes USING btree (formato_codigo);

CREATE UNIQUE INDEX fiae_insp_key ON public.formatos_inspeccion_ambientes USING btree (inspection_id);

CREATE UNIQUE INDEX fiae_pkey ON public.formatos_inspeccion_ambientes USING btree (id);

CREATE UNIQUE INDEX fldh_code_key ON public.formatos_limpieza_desinfeccion USING btree (formato_codigo);

CREATE UNIQUE INDEX fldh_pkey ON public.formatos_limpieza_desinfeccion USING btree (id);

CREATE UNIQUE INDEX fmeh_code_key ON public.formatos_mantenimiento_equipos USING btree (formato_codigo);

CREATE UNIQUE INDEX fmeh_pkey ON public.formatos_mantenimiento_equipos USING btree (id);

CREATE UNIQUE INDEX form_configurations_cooperative_step_key ON public.form_configurations USING btree (cooperative_id, step_key);

CREATE UNIQUE INDEX form_configurations_pkey ON public.form_configurations USING btree (id);

CREATE UNIQUE INDEX fsea_code_key ON public.formatos_seguimiento_salud USING btree (formato_codigo);

CREATE UNIQUE INDEX fsea_pkey ON public.formatos_seguimiento_salud USING btree (id);

CREATE UNIQUE INDEX health_incidents_pkey ON public.health_incidents USING btree (id);

CREATE INDEX idx_batch_certs_active ON public.batch_certs USING btree (is_active);

CREATE INDEX idx_batch_certs_cooperative_id ON public.batch_certs USING btree (cooperative_id);

CREATE INDEX idx_batch_certs_exclusion_group_id ON public.batch_certs USING btree (exclusion_group_id);

CREATE INDEX idx_batch_certs_is_default ON public.batch_certs USING btree (is_default) WHERE (is_default = true);

CREATE INDEX idx_batch_certs_name ON public.batch_certs USING btree (name);

CREATE INDEX idx_batch_ph_controls_cooperative_id ON public.batch_ph_controls USING btree (cooperative_id);

CREATE INDEX idx_batch_ph_controls_production_batch_id ON public.batch_ph_controls USING btree (production_batch_id);

CREATE INDEX idx_batch_ph_controls_record_date ON public.batch_ph_controls USING btree (record_date);

CREATE INDEX idx_batch_temperatures_cooperative_id ON public.batch_temperatures USING btree (cooperative_id);

CREATE INDEX idx_batch_temperatures_production_batch_id ON public.batch_temperatures USING btree (production_batch_id);

CREATE INDEX idx_batch_temperatures_sequence_number ON public.batch_temperatures USING btree (production_batch_id, sequence_number);

CREATE INDEX idx_certificate_exclusion_groups_active ON public.certificate_exclusion_groups USING btree (is_active);

CREATE INDEX idx_certificate_exclusion_groups_cooperative_id ON public.certificate_exclusion_groups USING btree (cooperative_id);

CREATE INDEX idx_certificate_exclusion_groups_name ON public.certificate_exclusion_groups USING btree (name);

CREATE INDEX idx_chlorine_controls_cooperative ON public.chlorine_residual_controls USING btree (cooperative_id);

CREATE INDEX idx_chlorine_controls_created_by ON public.chlorine_residual_controls USING btree (created_by);

CREATE INDEX idx_chlorine_controls_date_desc ON public.chlorine_residual_controls USING btree (control_date DESC);

CREATE INDEX idx_chlorine_controls_module ON public.chlorine_residual_controls USING btree (coop_module_id);

CREATE INDEX idx_chlorine_controls_module_date ON public.chlorine_residual_controls USING btree (coop_module_id, control_date DESC);

CREATE INDEX idx_cleaning_disinfections_cooperative ON public.cleaning_disinfections USING btree (cooperative_id);

CREATE INDEX idx_cleaning_disinfections_created_by ON public.cleaning_disinfections USING btree (created_by);

CREATE INDEX idx_cleaning_disinfections_date_desc ON public.cleaning_disinfections USING btree (cleaning_date DESC);

CREATE INDEX idx_cleaning_disinfections_module ON public.cleaning_disinfections USING btree (coop_module_id);

CREATE INDEX idx_cleaning_items_area ON public.cleaning_disinfection_items USING btree (area_code);

CREATE INDEX idx_cleaning_items_parent ON public.cleaning_disinfection_items USING btree (cleaning_disinfection_id);

CREATE INDEX idx_cleaning_items_uses_chlorine ON public.cleaning_disinfection_items USING btree (cleaning_disinfection_id) WHERE (uses_chlorine = true);

CREATE INDEX idx_cleaning_items_uses_detergent ON public.cleaning_disinfection_items USING btree (cleaning_disinfection_id) WHERE (uses_detergent = true);

CREATE INDEX idx_cleaning_items_uses_other ON public.cleaning_disinfection_items USING btree (cleaning_disinfection_id) WHERE (uses_other_product = true);

CREATE INDEX idx_coop_modules_active ON public.coop_modules USING btree (is_active);

CREATE INDEX idx_coop_modules_cooperative_id ON public.coop_modules USING btree (cooperative_id);

CREATE INDEX idx_coop_modules_name_coop ON public.coop_modules USING btree (name, cooperative_id);

CREATE INDEX idx_cooperatives_active ON public.cooperatives USING btree (is_active);

CREATE INDEX idx_cooperatives_code ON public.cooperatives USING btree (code);

CREATE INDEX idx_environment_inspection_items_area_code ON public.environment_inspection_items USING btree (area_code);

CREATE INDEX idx_environment_inspection_items_condition ON public.environment_inspection_items USING btree (condition);

CREATE INDEX idx_environment_inspection_items_inspection_id ON public.environment_inspection_items USING btree (environment_inspection_id);

CREATE INDEX idx_environment_inspections_cooperative_id ON public.environment_inspections USING btree (cooperative_id);

CREATE INDEX idx_environment_inspections_created_by ON public.environment_inspections USING btree (created_by, cooperative_id);

CREATE INDEX idx_environment_inspections_inspection_date ON public.environment_inspections USING btree (inspection_date);

CREATE INDEX idx_environment_inspections_module_id ON public.environment_inspections USING btree (coop_module_id);

CREATE INDEX idx_equipment_maintenance_cooperative ON public.equipment_maintenance_records USING btree (cooperative_id);

CREATE INDEX idx_equipment_maintenance_created_by ON public.equipment_maintenance_records USING btree (created_by);

CREATE INDEX idx_equipment_maintenance_date ON public.equipment_maintenance_records USING btree (maintenance_date DESC);

CREATE INDEX idx_equipment_maintenance_module ON public.equipment_maintenance_records USING btree (coop_module_id);

CREATE INDEX idx_equipment_maintenance_module_date ON public.equipment_maintenance_records USING btree (coop_module_id, maintenance_date DESC);

CREATE INDEX idx_equipment_maintenance_type ON public.equipment_maintenance_records USING btree (maintenance_type);

CREATE INDEX idx_exit_items_cooperative_id ON public.exit_items USING btree (cooperative_id);

CREATE INDEX idx_exit_items_exit_registration_id ON public.exit_items USING btree (exit_registration_id);

CREATE INDEX idx_exit_items_is_autoconsumo ON public.exit_items USING btree (is_autoconsumo);

CREATE INDEX idx_exit_items_production_batch_id ON public.exit_items USING btree (production_batch_id);

CREATE INDEX idx_exit_reception_items_reception ON public.exit_reception_items USING btree (exit_reception_id);

CREATE INDEX idx_exit_receptions_cooperative ON public.exit_receptions USING btree (cooperative_id);

CREATE INDEX idx_exit_receptions_exit_registration ON public.exit_receptions USING btree (exit_registration_id);

CREATE INDEX idx_exit_registrations_cooperative_id ON public.exit_registrations USING btree (cooperative_id);

CREATE INDEX idx_exit_registrations_created_by ON public.exit_registrations USING btree (created_by);

CREATE INDEX idx_exit_registrations_exit_code ON public.exit_registrations USING btree (exit_code);

CREATE INDEX idx_exit_registrations_exit_date ON public.exit_registrations USING btree (exit_date);

CREATE INDEX idx_exit_registrations_exit_type ON public.exit_registrations USING btree (exit_type);

CREATE INDEX idx_health_incidents_cooperative_id ON public.health_incidents USING btree (cooperative_id);

CREATE INDEX idx_health_incidents_created_by ON public.health_incidents USING btree (created_by, cooperative_id);

CREATE INDEX idx_health_incidents_module_id ON public.health_incidents USING btree (coop_module_id);

CREATE INDEX idx_health_incidents_registration_date ON public.health_incidents USING btree (registration_date);

CREATE INDEX idx_inventory_stock_available_kg ON public.inventory_stock USING btree (available_kg);

CREATE INDEX idx_inventory_stock_cooperative_id ON public.inventory_stock USING btree (cooperative_id);

CREATE INDEX idx_inventory_stock_production_batch_id ON public.inventory_stock USING btree (production_batch_id);

CREATE INDEX idx_pest_bait_records_parent ON public.pest_control_bait_records USING btree (pest_control_id);

CREATE INDEX idx_pest_bait_stations_gin ON public.pest_control_bait_records USING gin (bait_stations);

CREATE INDEX idx_pest_controls_cooperative ON public.pest_controls USING btree (cooperative_id);

CREATE INDEX idx_pest_controls_created_by ON public.pest_controls USING btree (created_by);

CREATE INDEX idx_pest_controls_date_desc ON public.pest_controls USING btree (control_date DESC);

CREATE INDEX idx_pest_controls_module ON public.pest_controls USING btree (coop_module_id);

CREATE INDEX idx_pest_insect_data_gin ON public.pest_control_insect_records USING gin (insect_data);

CREATE INDEX idx_pest_insect_records_parent ON public.pest_control_insect_records USING btree (pest_control_id);

CREATE INDEX idx_plant_hygiene_areas_coop_date ON public.plant_hygiene_areas USING btree (cooperative_id, control_date DESC);

CREATE INDEX idx_plant_hygiene_areas_created_by ON public.plant_hygiene_areas USING btree (created_by);

CREATE INDEX idx_plant_hygiene_worker_criteria_worker ON public.plant_hygiene_worker_criteria USING btree (worker_id);

CREATE INDEX idx_plant_hygiene_workers_area ON public.plant_hygiene_workers USING btree (hygiene_area_id);

CREATE INDEX idx_plots_active ON public.plots USING btree (is_active);

CREATE INDEX idx_plots_code ON public.plots USING btree (code);

CREATE INDEX idx_plots_code_producer ON public.plots USING btree (code, producer_id);

CREATE INDEX idx_plots_default_cachaza_percentage ON public.plots USING btree (default_cachaza_percentage);

CREATE INDEX idx_plots_default_extraction_percentage ON public.plots USING btree (default_extraction_percentage);

CREATE INDEX idx_plots_name ON public.plots USING btree (name);

CREATE INDEX idx_plots_name_code ON public.plots USING btree (name, code);

CREATE INDEX idx_plots_producer_id ON public.plots USING btree (producer_id);

CREATE INDEX idx_producers_active ON public.producers USING btree (is_active);

CREATE INDEX idx_producers_appagrop_code ON public.producers USING btree (appagrop_code);

CREATE INDEX idx_producers_coop_module_id ON public.producers USING btree (coop_module_id);

CREATE INDEX idx_producers_cooperative_id ON public.producers USING btree (cooperative_id);

CREATE INDEX idx_producers_default_cachaza_percentage ON public.producers USING btree (default_cachaza_percentage);

CREATE INDEX idx_producers_default_extraction_percentage ON public.producers USING btree (default_extraction_percentage);

CREATE INDEX idx_producers_dni ON public.producers USING btree (dni);

CREATE INDEX idx_producers_full_name ON public.producers USING btree (first_name, last_name);

CREATE INDEX idx_producers_member ON public.producers USING btree (is_member);

CREATE INDEX idx_product_returns_coop_date ON public.product_returns USING btree (cooperative_id, return_date DESC);

CREATE INDEX idx_product_returns_cooperative ON public.product_returns USING btree (cooperative_id);

CREATE INDEX idx_product_returns_created_by ON public.product_returns USING btree (created_by);

CREATE INDEX idx_product_returns_production_batch ON public.product_returns USING btree (production_batch_id);

CREATE INDEX idx_product_returns_return_date ON public.product_returns USING btree (return_date DESC);

CREATE INDEX idx_production_batch_certs_batch_cert_id ON public.production_batch_certs USING btree (batch_cert_id);

CREATE INDEX idx_production_batch_certs_cooperative_id ON public.production_batch_certs USING btree (cooperative_id);

CREATE INDEX idx_production_batch_certs_production_batch_id ON public.production_batch_certs USING btree (production_batch_id);

CREATE INDEX idx_production_batches_batch_code ON public.production_batches USING btree (batch_code);

CREATE INDEX idx_production_batches_cachaza_percentage ON public.production_batches USING btree (cachaza_percentage);

CREATE INDEX idx_production_batches_confitillo_kg ON public.production_batches USING btree (confitillo_kg) WHERE (confitillo_kg > (0)::numeric);

CREATE INDEX idx_production_batches_cooperative_id ON public.production_batches USING btree (cooperative_id);

CREATE INDEX idx_production_batches_harvest_date ON public.production_batches USING btree (harvest_date);

CREATE INDEX idx_production_batches_panela_kg ON public.production_batches USING btree (panela_kg) WHERE (panela_kg > (0)::numeric);

CREATE INDEX idx_production_batches_plot_id ON public.production_batches USING btree (plot_id);

CREATE INDEX idx_production_batches_porcentaje_extraccion ON public.production_batches USING btree (porcentaje_extraccion) WHERE (porcentaje_extraccion IS NOT NULL);

CREATE INDEX idx_production_batches_process_date ON public.production_batches USING btree (process_date);

CREATE INDEX idx_production_batches_producer_id ON public.production_batches USING btree (producer_id);

CREATE INDEX idx_quality_evaluations_cooperative ON public.quality_evaluations USING btree (cooperative_id);

CREATE INDEX idx_quality_evaluations_reception ON public.quality_evaluations USING btree (exit_reception_id);

CREATE INDEX idx_stowage_transport_inspections_cooperative_id ON public.stowage_transport_inspections USING btree (cooperative_id);

CREATE INDEX idx_stowage_transport_inspections_created_by ON public.stowage_transport_inspections USING btree (created_by, cooperative_id);

CREATE INDEX idx_stowage_transport_inspections_exit_registration_id ON public.stowage_transport_inspections USING btree (exit_registration_id);

CREATE INDEX idx_stowage_transport_inspections_inspection_date ON public.stowage_transport_inspections USING btree (inspection_date);

CREATE INDEX idx_user_module_assignments_user ON public.user_module_assignments USING btree (user_id, cooperative_id);

CREATE INDEX idx_users_auth_user_id ON public.users USING btree (auth_user_id);

CREATE INDEX idx_users_coop_module_id ON public.users USING btree (coop_module_id);

CREATE INDEX idx_users_cooperative_id ON public.users USING btree (cooperative_id);

CREATE INDEX idx_users_email ON public.users USING btree (email);

CREATE INDEX idx_users_full_name ON public.users USING btree (first_name, last_name);

CREATE INDEX idx_users_user_id ON public.users USING btree (user_id);

CREATE INDEX idx_worker_controls_cooperative ON public.worker_controls USING btree (cooperative_id);

CREATE INDEX idx_worker_controls_created_at ON public.worker_controls USING btree (created_at DESC);

CREATE INDEX idx_worker_controls_created_by ON public.worker_controls USING btree (created_by);

CREATE INDEX idx_worker_controls_production_batch ON public.worker_controls USING btree (production_batch_id);

CREATE INDEX idx_worker_controls_work_area ON public.worker_controls USING btree (work_area);

CREATE UNIQUE INDEX inventory_stock_pkey ON public.inventory_stock USING btree (id);

CREATE UNIQUE INDEX pest_control_bait_records_pkey ON public.pest_control_bait_records USING btree (id);

CREATE UNIQUE INDEX pest_control_insect_records_pkey ON public.pest_control_insect_records USING btree (id);

CREATE UNIQUE INDEX pest_controls_pkey ON public.pest_controls USING btree (id);

CREATE UNIQUE INDEX plant_batch_processing_pkey ON public.plant_batch_processing USING btree (id);

CREATE UNIQUE INDEX plant_batch_processing_plant_batch_id_key ON public.plant_batch_processing USING btree (plant_batch_id);

CREATE UNIQUE INDEX plant_checklists_pkey ON public.plant_checklists USING btree (id);

CREATE UNIQUE INDEX plant_checklists_plant_batch_id_type_key ON public.plant_checklists USING btree (plant_batch_id, type);

CREATE UNIQUE INDEX plant_containers_pkey ON public.plant_containers USING btree (id);

CREATE UNIQUE INDEX plant_dispatches_dispatch_code_key ON public.plant_dispatches USING btree (dispatch_code);

CREATE UNIQUE INDEX plant_dispatches_pkey ON public.plant_dispatches USING btree (id);

CREATE UNIQUE INDEX plant_homogenization_inputs_pkey ON public.plant_homogenization_inputs USING btree (id);

CREATE UNIQUE INDEX plant_hygiene_areas_cooperative_date_area_key ON public.plant_hygiene_areas USING btree (cooperative_id, control_date, area_code);

CREATE UNIQUE INDEX plant_hygiene_areas_pkey ON public.plant_hygiene_areas USING btree (id);

CREATE UNIQUE INDEX plant_hygiene_worker_criteria_pkey ON public.plant_hygiene_worker_criteria USING btree (id);

CREATE UNIQUE INDEX plant_hygiene_worker_criteria_worker_item_key ON public.plant_hygiene_worker_criteria USING btree (worker_id, item_code);

CREATE UNIQUE INDEX plant_hygiene_workers_pkey ON public.plant_hygiene_workers USING btree (id);

CREATE UNIQUE INDEX plant_order_checklists_order_id_type_key ON public.plant_order_checklists USING btree (order_id, type);

CREATE UNIQUE INDEX plant_order_checklists_pkey ON public.plant_order_checklists USING btree (id);

CREATE UNIQUE INDEX plant_orders_order_code_key ON public.plant_orders USING btree (order_code);

CREATE UNIQUE INDEX plant_orders_pkey ON public.plant_orders USING btree (id);

CREATE UNIQUE INDEX plant_production_batches_batch_code_key ON public.plant_production_batches USING btree (batch_code);

CREATE UNIQUE INDEX plant_production_batches_pkey ON public.plant_production_batches USING btree (id);

CREATE UNIQUE INDEX plots_pkey ON public.plots USING btree (id);

CREATE UNIQUE INDEX producers_pkey ON public.producers USING btree (id);

CREATE UNIQUE INDEX product_returns_pkey ON public.product_returns USING btree (id);

CREATE UNIQUE INDEX production_batch_certs_pkey ON public.production_batch_certs USING btree (id);

CREATE UNIQUE INDEX production_batch_certs_production_batch_id_batch_cert_id_key ON public.production_batch_certs USING btree (production_batch_id, batch_cert_id);

CREATE UNIQUE INDEX production_batches_batch_code_key ON public.production_batches USING btree (batch_code);

CREATE UNIQUE INDEX production_batches_pkey ON public.production_batches USING btree (id);

CREATE UNIQUE INDEX quality_evaluations_exit_item_id_key ON public.quality_evaluations USING btree (exit_item_id);

CREATE UNIQUE INDEX quality_evaluations_pkey ON public.quality_evaluations USING btree (id);

CREATE UNIQUE INDEX sti_formato_codigo_key ON public.stowage_transport_inspections USING btree (formato_codigo);

CREATE UNIQUE INDEX stowage_inspections_exit_unique ON public.stowage_transport_inspections USING btree (exit_registration_id);

CREATE UNIQUE INDEX stowage_transport_inspections_pkey ON public.stowage_transport_inspections USING btree (id);

CREATE UNIQUE INDEX unique_cert_per_cooperative ON public.batch_certs USING btree (name, cooperative_id);

CREATE UNIQUE INDEX unique_dni_per_module ON public.producers USING btree (dni, coop_module_id);

CREATE UNIQUE INDEX unique_exclusion_group_per_cooperative ON public.certificate_exclusion_groups USING btree (name, cooperative_id);

CREATE UNIQUE INDEX unique_item_per_inspection ON public.environment_inspection_items USING btree (environment_inspection_id, area_code, item_code);

CREATE UNIQUE INDEX unique_module_datetime ON public.chlorine_residual_controls USING btree (coop_module_id, control_date, control_time);

CREATE UNIQUE INDEX unique_module_name_per_cooperative ON public.coop_modules USING btree (name, cooperative_id);

CREATE UNIQUE INDEX unique_plot_name_code_per_producer ON public.plots USING btree (name, code, producer_id);

CREATE UNIQUE INDEX unique_stock_per_batch ON public.inventory_stock USING btree (production_batch_id);

CREATE UNIQUE INDEX user_module_assignments_pkey ON public.user_module_assignments USING btree (user_id, cooperative_id, coop_module_id);

CREATE UNIQUE INDEX users_auth_user_id_key ON public.users USING btree (auth_user_id);

CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email);

CREATE UNIQUE INDEX users_pkey ON public.users USING btree (user_id, cooperative_id);

CREATE UNIQUE INDEX web_users_auth_user_id_key ON public.web_users USING btree (auth_user_id);

CREATE UNIQUE INDEX web_users_pkey ON public.web_users USING btree (id);

CREATE UNIQUE INDEX web_users_username_key ON public.web_users USING btree (username);

CREATE UNIQUE INDEX worker_control_items_pkey ON public.worker_control_items USING btree (id);

CREATE UNIQUE INDEX worker_controls_pkey ON public.worker_controls USING btree (id);

alter table "public"."batch_certs" add constraint "batch_certs_pkey" PRIMARY KEY using index "batch_certs_pkey";

alter table "public"."batch_ph_controls" add constraint "batch_ph_controls_pkey" PRIMARY KEY using index "batch_ph_controls_pkey";

alter table "public"."batch_temperatures" add constraint "batch_temperatures_pkey" PRIMARY KEY using index "batch_temperatures_pkey";

alter table "public"."certificate_exclusion_groups" add constraint "certificate_exclusion_groups_pkey" PRIMARY KEY using index "certificate_exclusion_groups_pkey";

alter table "public"."chlorine_residual_controls" add constraint "chlorine_residual_controls_pkey" PRIMARY KEY using index "chlorine_residual_controls_pkey";

alter table "public"."cleaning_disinfection_items" add constraint "cleaning_disinfection_items_pkey" PRIMARY KEY using index "cleaning_disinfection_items_pkey";

alter table "public"."cleaning_disinfections" add constraint "cleaning_disinfections_pkey" PRIMARY KEY using index "cleaning_disinfections_pkey";

alter table "public"."coop_modules" add constraint "coop_modules_pkey" PRIMARY KEY using index "coop_modules_pkey";

alter table "public"."cooperatives" add constraint "cooperatives_pkey" PRIMARY KEY using index "cooperatives_pkey";

alter table "public"."environment_inspection_items" add constraint "environment_inspection_items_pkey" PRIMARY KEY using index "environment_inspection_items_pkey";

alter table "public"."environment_inspections" add constraint "environment_inspections_pkey" PRIMARY KEY using index "environment_inspections_pkey";

alter table "public"."equipment_maintenance_records" add constraint "equipment_maintenance_records_pkey" PRIMARY KEY using index "equipment_maintenance_records_pkey";

alter table "public"."exit_items" add constraint "exit_items_pkey" PRIMARY KEY using index "exit_items_pkey";

alter table "public"."exit_reception_items" add constraint "exit_reception_items_pkey" PRIMARY KEY using index "exit_reception_items_pkey";

alter table "public"."exit_receptions" add constraint "exit_receptions_pkey" PRIMARY KEY using index "exit_receptions_pkey";

alter table "public"."exit_registrations" add constraint "exit_registrations_pkey" PRIMARY KEY using index "exit_registrations_pkey";

alter table "public"."form_configurations" add constraint "form_configurations_pkey" PRIMARY KEY using index "form_configurations_pkey";

alter table "public"."formatos_control_cloro" add constraint "fccl_pkey" PRIMARY KEY using index "fccl_pkey";

alter table "public"."formatos_control_mp_ph" add constraint "fcmptph_pkey" PRIMARY KEY using index "fcmptph_pkey";

alter table "public"."formatos_control_mp_ph_lotes" add constraint "fcmptph_lotes_pkey" PRIMARY KEY using index "fcmptph_lotes_pkey";

alter table "public"."formatos_control_personal" add constraint "fcpo_pkey" PRIMARY KEY using index "fcpo_pkey";

alter table "public"."formatos_control_plagas" add constraint "fcp_pkey" PRIMARY KEY using index "fcp_pkey";

alter table "public"."formatos_inspeccion_ambientes" add constraint "fiae_pkey" PRIMARY KEY using index "fiae_pkey";

alter table "public"."formatos_limpieza_desinfeccion" add constraint "fldh_pkey" PRIMARY KEY using index "fldh_pkey";

alter table "public"."formatos_mantenimiento_equipos" add constraint "fmeh_pkey" PRIMARY KEY using index "fmeh_pkey";

alter table "public"."formatos_seguimiento_salud" add constraint "fsea_pkey" PRIMARY KEY using index "fsea_pkey";

alter table "public"."health_incidents" add constraint "health_incidents_pkey" PRIMARY KEY using index "health_incidents_pkey";

alter table "public"."inventory_stock" add constraint "inventory_stock_pkey" PRIMARY KEY using index "inventory_stock_pkey";

alter table "public"."pest_control_bait_records" add constraint "pest_control_bait_records_pkey" PRIMARY KEY using index "pest_control_bait_records_pkey";

alter table "public"."pest_control_insect_records" add constraint "pest_control_insect_records_pkey" PRIMARY KEY using index "pest_control_insect_records_pkey";

alter table "public"."pest_controls" add constraint "pest_controls_pkey" PRIMARY KEY using index "pest_controls_pkey";

alter table "public"."plant_batch_processing" add constraint "plant_batch_processing_pkey" PRIMARY KEY using index "plant_batch_processing_pkey";

alter table "public"."plant_checklists" add constraint "plant_checklists_pkey" PRIMARY KEY using index "plant_checklists_pkey";

alter table "public"."plant_containers" add constraint "plant_containers_pkey" PRIMARY KEY using index "plant_containers_pkey";

alter table "public"."plant_dispatches" add constraint "plant_dispatches_pkey" PRIMARY KEY using index "plant_dispatches_pkey";

alter table "public"."plant_homogenization_inputs" add constraint "plant_homogenization_inputs_pkey" PRIMARY KEY using index "plant_homogenization_inputs_pkey";

alter table "public"."plant_hygiene_areas" add constraint "plant_hygiene_areas_pkey" PRIMARY KEY using index "plant_hygiene_areas_pkey";

alter table "public"."plant_hygiene_worker_criteria" add constraint "plant_hygiene_worker_criteria_pkey" PRIMARY KEY using index "plant_hygiene_worker_criteria_pkey";

alter table "public"."plant_hygiene_workers" add constraint "plant_hygiene_workers_pkey" PRIMARY KEY using index "plant_hygiene_workers_pkey";

alter table "public"."plant_order_checklists" add constraint "plant_order_checklists_pkey" PRIMARY KEY using index "plant_order_checklists_pkey";

alter table "public"."plant_orders" add constraint "plant_orders_pkey" PRIMARY KEY using index "plant_orders_pkey";

alter table "public"."plant_production_batches" add constraint "plant_production_batches_pkey" PRIMARY KEY using index "plant_production_batches_pkey";

alter table "public"."plots" add constraint "plots_pkey" PRIMARY KEY using index "plots_pkey";

alter table "public"."producers" add constraint "producers_pkey" PRIMARY KEY using index "producers_pkey";

alter table "public"."product_returns" add constraint "product_returns_pkey" PRIMARY KEY using index "product_returns_pkey";

alter table "public"."production_batch_certs" add constraint "production_batch_certs_pkey" PRIMARY KEY using index "production_batch_certs_pkey";

alter table "public"."production_batches" add constraint "production_batches_pkey" PRIMARY KEY using index "production_batches_pkey";

alter table "public"."quality_evaluations" add constraint "quality_evaluations_pkey" PRIMARY KEY using index "quality_evaluations_pkey";

alter table "public"."stowage_transport_inspections" add constraint "stowage_transport_inspections_pkey" PRIMARY KEY using index "stowage_transport_inspections_pkey";

alter table "public"."user_module_assignments" add constraint "user_module_assignments_pkey" PRIMARY KEY using index "user_module_assignments_pkey";

alter table "public"."users" add constraint "users_pkey" PRIMARY KEY using index "users_pkey";

alter table "public"."web_users" add constraint "web_users_pkey" PRIMARY KEY using index "web_users_pkey";

alter table "public"."worker_control_items" add constraint "worker_control_items_pkey" PRIMARY KEY using index "worker_control_items_pkey";

alter table "public"."worker_controls" add constraint "worker_controls_pkey" PRIMARY KEY using index "worker_controls_pkey";

alter table "public"."batch_certs" add constraint "batch_certs_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE not valid;

alter table "public"."batch_certs" validate constraint "batch_certs_cooperative_id_fkey";

alter table "public"."batch_certs" add constraint "batch_certs_exclusion_group_id_fkey" FOREIGN KEY (exclusion_group_id) REFERENCES public.certificate_exclusion_groups(id) ON DELETE SET NULL not valid;

alter table "public"."batch_certs" validate constraint "batch_certs_exclusion_group_id_fkey";

alter table "public"."batch_certs" add constraint "unique_cert_per_cooperative" UNIQUE using index "unique_cert_per_cooperative";

alter table "public"."batch_ph_controls" add constraint "batch_ph_controls_brix_check" CHECK (((brix >= (0)::numeric) AND (brix <= (100)::numeric))) not valid;

alter table "public"."batch_ph_controls" validate constraint "batch_ph_controls_brix_check";

alter table "public"."batch_ph_controls" add constraint "batch_ph_controls_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."batch_ph_controls" validate constraint "batch_ph_controls_cooperative_id_fkey";

alter table "public"."batch_ph_controls" add constraint "batch_ph_controls_ph_final_check" CHECK (((ph_final >= (0)::numeric) AND (ph_final <= (14)::numeric))) not valid;

alter table "public"."batch_ph_controls" validate constraint "batch_ph_controls_ph_final_check";

alter table "public"."batch_ph_controls" add constraint "batch_ph_controls_ph_initial_check" CHECK (((ph_initial >= (0)::numeric) AND (ph_initial <= (14)::numeric))) not valid;

alter table "public"."batch_ph_controls" validate constraint "batch_ph_controls_ph_initial_check";

alter table "public"."batch_ph_controls" add constraint "batch_ph_controls_production_batch_id_fkey" FOREIGN KEY (production_batch_id) REFERENCES public.production_batches(id) ON DELETE CASCADE not valid;

alter table "public"."batch_ph_controls" validate constraint "batch_ph_controls_production_batch_id_fkey";

alter table "public"."batch_ph_controls" add constraint "batch_ph_controls_regulator_quantity_kg_check" CHECK ((regulator_quantity_kg >= (0)::numeric)) not valid;

alter table "public"."batch_ph_controls" validate constraint "batch_ph_controls_regulator_quantity_kg_check";

alter table "public"."batch_ph_controls" add constraint "valid_regulator_unit" CHECK (((regulator_quantity_unit IS NULL) OR ((regulator_quantity_unit)::text = ANY (ARRAY[('gr'::character varying)::text, ('mL'::character varying)::text, ('L'::character varying)::text])))) not valid;

alter table "public"."batch_ph_controls" validate constraint "valid_regulator_unit";

alter table "public"."batch_temperatures" add constraint "batch_temperatures_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."batch_temperatures" validate constraint "batch_temperatures_cooperative_id_fkey";

alter table "public"."batch_temperatures" add constraint "batch_temperatures_production_batch_id_fkey" FOREIGN KEY (production_batch_id) REFERENCES public.production_batches(id) ON DELETE CASCADE not valid;

alter table "public"."batch_temperatures" validate constraint "batch_temperatures_production_batch_id_fkey";

alter table "public"."batch_temperatures" add constraint "batch_temperatures_production_batch_id_sequence_number_key" UNIQUE using index "batch_temperatures_production_batch_id_sequence_number_key";

alter table "public"."batch_temperatures" add constraint "batch_temperatures_sequence_number_check" CHECK ((sequence_number > 0)) not valid;

alter table "public"."batch_temperatures" validate constraint "batch_temperatures_sequence_number_check";

alter table "public"."certificate_exclusion_groups" add constraint "certificate_exclusion_groups_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE not valid;

alter table "public"."certificate_exclusion_groups" validate constraint "certificate_exclusion_groups_cooperative_id_fkey";

alter table "public"."certificate_exclusion_groups" add constraint "unique_exclusion_group_per_cooperative" UNIQUE using index "unique_exclusion_group_per_cooperative";

alter table "public"."chlorine_residual_controls" add constraint "chlorine_residual_controls_coop_module_id_fkey" FOREIGN KEY (coop_module_id) REFERENCES public.coop_modules(id) not valid;

alter table "public"."chlorine_residual_controls" validate constraint "chlorine_residual_controls_coop_module_id_fkey";

alter table "public"."chlorine_residual_controls" add constraint "chlorine_residual_controls_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) not valid;

alter table "public"."chlorine_residual_controls" validate constraint "chlorine_residual_controls_cooperative_id_fkey";

alter table "public"."chlorine_residual_controls" add constraint "unique_module_datetime" UNIQUE using index "unique_module_datetime";

alter table "public"."chlorine_residual_controls" add constraint "valid_measurement_1" CHECK (((measurement_point_1 >= (0)::numeric) AND (measurement_point_1 <= (10)::numeric))) not valid;

alter table "public"."chlorine_residual_controls" validate constraint "valid_measurement_1";

alter table "public"."chlorine_residual_controls" add constraint "valid_measurement_2" CHECK (((measurement_point_2 >= (0)::numeric) AND (measurement_point_2 <= (10)::numeric))) not valid;

alter table "public"."chlorine_residual_controls" validate constraint "valid_measurement_2";

alter table "public"."cleaning_disinfection_items" add constraint "cleaning_disinfection_items_cleaning_disinfection_id_fkey" FOREIGN KEY (cleaning_disinfection_id) REFERENCES public.cleaning_disinfections(id) ON DELETE CASCADE not valid;

alter table "public"."cleaning_disinfection_items" validate constraint "cleaning_disinfection_items_cleaning_disinfection_id_fkey";

alter table "public"."cleaning_disinfections" add constraint "cleaning_disinfections_coop_module_id_fkey" FOREIGN KEY (coop_module_id) REFERENCES public.coop_modules(id) not valid;

alter table "public"."cleaning_disinfections" validate constraint "cleaning_disinfections_coop_module_id_fkey";

alter table "public"."cleaning_disinfections" add constraint "cleaning_disinfections_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) not valid;

alter table "public"."cleaning_disinfections" validate constraint "cleaning_disinfections_cooperative_id_fkey";

alter table "public"."cleaning_disinfections" add constraint "cleaning_disinfections_module_date_key" UNIQUE using index "cleaning_disinfections_module_date_key";

alter table "public"."cleaning_disinfections" add constraint "cleaning_disinfections_types_chk" CHECK (((cleaning_types <@ ARRAY['daily'::text, 'general'::text, 'deep'::text]) AND (array_length(cleaning_types, 1) > 0))) not valid;

alter table "public"."cleaning_disinfections" validate constraint "cleaning_disinfections_types_chk";

alter table "public"."coop_modules" add constraint "coop_modules_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE not valid;

alter table "public"."coop_modules" validate constraint "coop_modules_cooperative_id_fkey";

alter table "public"."coop_modules" add constraint "unique_module_name_per_cooperative" UNIQUE using index "unique_module_name_per_cooperative";

alter table "public"."cooperatives" add constraint "cooperatives_code_key" UNIQUE using index "cooperatives_code_key";

alter table "public"."cooperatives" add constraint "cooperatives_name_key" UNIQUE using index "cooperatives_name_key";

alter table "public"."environment_inspection_items" add constraint "environment_inspection_items_environment_inspection_id_fkey" FOREIGN KEY (environment_inspection_id) REFERENCES public.environment_inspections(id) ON DELETE CASCADE not valid;

alter table "public"."environment_inspection_items" validate constraint "environment_inspection_items_environment_inspection_id_fkey";

alter table "public"."environment_inspection_items" add constraint "unique_item_per_inspection" UNIQUE using index "unique_item_per_inspection";

alter table "public"."environment_inspections" add constraint "environment_inspections_coop_module_id_fkey" FOREIGN KEY (coop_module_id) REFERENCES public.coop_modules(id) ON DELETE RESTRICT not valid;

alter table "public"."environment_inspections" validate constraint "environment_inspections_coop_module_id_fkey";

alter table "public"."environment_inspections" add constraint "environment_inspections_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."environment_inspections" validate constraint "environment_inspections_cooperative_id_fkey";

alter table "public"."environment_inspections" add constraint "environment_inspections_created_by_fkey" FOREIGN KEY (created_by, cooperative_id) REFERENCES public.users(user_id, cooperative_id) ON DELETE RESTRICT not valid;

alter table "public"."environment_inspections" validate constraint "environment_inspections_created_by_fkey";

alter table "public"."equipment_maintenance_records" add constraint "equipment_maintenance_records_coop_module_id_fkey" FOREIGN KEY (coop_module_id) REFERENCES public.coop_modules(id) ON DELETE RESTRICT not valid;

alter table "public"."equipment_maintenance_records" validate constraint "equipment_maintenance_records_coop_module_id_fkey";

alter table "public"."equipment_maintenance_records" add constraint "equipment_maintenance_records_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."equipment_maintenance_records" validate constraint "equipment_maintenance_records_cooperative_id_fkey";

alter table "public"."equipment_maintenance_records" add constraint "equipment_maintenance_records_created_by_fkey" FOREIGN KEY (created_by, cooperative_id) REFERENCES public.users(user_id, cooperative_id) ON DELETE RESTRICT not valid;

alter table "public"."equipment_maintenance_records" validate constraint "equipment_maintenance_records_created_by_fkey";

alter table "public"."equipment_maintenance_records" add constraint "equipment_maintenance_records_duration_hours_check" CHECK ((duration_hours > (0)::numeric)) not valid;

alter table "public"."equipment_maintenance_records" validate constraint "equipment_maintenance_records_duration_hours_check";

alter table "public"."equipment_maintenance_records" add constraint "equipment_maintenance_records_maintenance_type_check" CHECK ((maintenance_type = ANY (ARRAY['P'::text, 'C'::text]))) not valid;

alter table "public"."equipment_maintenance_records" validate constraint "equipment_maintenance_records_maintenance_type_check";

alter table "public"."exit_items" add constraint "exit_items_bags_count_check" CHECK ((bags_count >= (0)::numeric)) not valid;

alter table "public"."exit_items" validate constraint "exit_items_bags_count_check";

alter table "public"."exit_items" add constraint "exit_items_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."exit_items" validate constraint "exit_items_cooperative_id_fkey";

alter table "public"."exit_items" add constraint "exit_items_exit_registration_id_fkey" FOREIGN KEY (exit_registration_id) REFERENCES public.exit_registrations(id) ON DELETE CASCADE not valid;

alter table "public"."exit_items" validate constraint "exit_items_exit_registration_id_fkey";

alter table "public"."exit_items" add constraint "exit_items_production_batch_id_fkey" FOREIGN KEY (production_batch_id) REFERENCES public.production_batches(id) ON DELETE RESTRICT not valid;

alter table "public"."exit_items" validate constraint "exit_items_production_batch_id_fkey";

alter table "public"."exit_items" add constraint "exit_items_quantity_kg_check" CHECK ((quantity_kg > (0)::numeric)) not valid;

alter table "public"."exit_items" validate constraint "exit_items_quantity_kg_check";

alter table "public"."exit_items" add constraint "exit_items_unit_price_check" CHECK ((unit_price >= (0)::numeric)) not valid;

alter table "public"."exit_items" validate constraint "exit_items_unit_price_check";

alter table "public"."exit_reception_items" add constraint "exit_reception_items_exit_item_id_fkey" FOREIGN KEY (exit_item_id) REFERENCES public.exit_items(id) ON DELETE RESTRICT not valid;

alter table "public"."exit_reception_items" validate constraint "exit_reception_items_exit_item_id_fkey";

alter table "public"."exit_reception_items" add constraint "exit_reception_items_exit_item_id_key" UNIQUE using index "exit_reception_items_exit_item_id_key";

alter table "public"."exit_reception_items" add constraint "exit_reception_items_exit_reception_id_fkey" FOREIGN KEY (exit_reception_id) REFERENCES public.exit_receptions(id) ON DELETE CASCADE not valid;

alter table "public"."exit_reception_items" validate constraint "exit_reception_items_exit_reception_id_fkey";

alter table "public"."exit_reception_items" add constraint "exit_reception_items_quantity_kg_received_check" CHECK ((quantity_kg_received >= (0)::numeric)) not valid;

alter table "public"."exit_reception_items" validate constraint "exit_reception_items_quantity_kg_received_check";

alter table "public"."exit_receptions" add constraint "exit_receptions_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."exit_receptions" validate constraint "exit_receptions_cooperative_id_fkey";

alter table "public"."exit_receptions" add constraint "exit_receptions_exit_registration_id_fkey" FOREIGN KEY (exit_registration_id) REFERENCES public.exit_registrations(id) ON DELETE RESTRICT not valid;

alter table "public"."exit_receptions" validate constraint "exit_receptions_exit_registration_id_fkey";

alter table "public"."exit_receptions" add constraint "exit_receptions_exit_registration_id_key" UNIQUE using index "exit_receptions_exit_registration_id_key";

alter table "public"."exit_receptions" add constraint "exit_receptions_received_by_fkey" FOREIGN KEY (received_by) REFERENCES public.web_users(id) ON DELETE RESTRICT not valid;

alter table "public"."exit_receptions" validate constraint "exit_receptions_received_by_fkey";

alter table "public"."exit_receptions" add constraint "exit_receptions_status_check" CHECK (((status)::text = ANY (ARRAY[('recepcionado'::character varying)::text, ('rechazado'::character varying)::text]))) not valid;

alter table "public"."exit_receptions" validate constraint "exit_receptions_status_check";

alter table "public"."exit_registrations" add constraint "exit_registrations_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."exit_registrations" validate constraint "exit_registrations_cooperative_id_fkey";

alter table "public"."exit_registrations" add constraint "exit_registrations_created_by_fkey" FOREIGN KEY (created_by, cooperative_id) REFERENCES public.users(user_id, cooperative_id) ON DELETE RESTRICT not valid;

alter table "public"."exit_registrations" validate constraint "exit_registrations_created_by_fkey";

alter table "public"."exit_registrations" add constraint "exit_registrations_exit_code_key" UNIQUE using index "exit_registrations_exit_code_key";

alter table "public"."exit_registrations" add constraint "exit_registrations_exit_type_check" CHECK (((exit_type)::text = ANY (ARRAY[('SALIDA'::character varying)::text, ('AJUSTE'::character varying)::text, ('MERMA'::character varying)::text]))) not valid;

alter table "public"."exit_registrations" validate constraint "exit_registrations_exit_type_check";

alter table "public"."exit_registrations" add constraint "exit_registrations_total_kg_check" CHECK ((total_kg >= (0)::numeric)) not valid;

alter table "public"."exit_registrations" validate constraint "exit_registrations_total_kg_check";

alter table "public"."form_configurations" add constraint "form_configurations_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE not valid;

alter table "public"."form_configurations" validate constraint "form_configurations_cooperative_id_fkey";

alter table "public"."form_configurations" add constraint "form_configurations_cooperative_step_key" UNIQUE using index "form_configurations_cooperative_step_key";

alter table "public"."formatos_control_cloro" add constraint "fccl_code_key" UNIQUE using index "fccl_code_key";

alter table "public"."formatos_control_cloro" add constraint "fccl_coop_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_control_cloro" validate constraint "fccl_coop_fkey";

alter table "public"."formatos_control_cloro" add constraint "fccl_module_fkey" FOREIGN KEY (module_id) REFERENCES public.coop_modules(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_control_cloro" validate constraint "fccl_module_fkey";

alter table "public"."formatos_control_cloro" add constraint "fccl_status_chk" CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'emitted'::character varying])::text[]))) not valid;

alter table "public"."formatos_control_cloro" validate constraint "fccl_status_chk";

alter table "public"."formatos_control_mp_ph" add constraint "fcmptph_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_control_mp_ph" validate constraint "fcmptph_cooperative_id_fkey";

alter table "public"."formatos_control_mp_ph" add constraint "fcmptph_formato_codigo_key" UNIQUE using index "fcmptph_formato_codigo_key";

alter table "public"."formatos_control_mp_ph" add constraint "fcmptph_module_id_fkey" FOREIGN KEY (module_id) REFERENCES public.coop_modules(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_control_mp_ph" validate constraint "fcmptph_module_id_fkey";

alter table "public"."formatos_control_mp_ph" add constraint "fcmptph_status_check" CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'emitted'::character varying])::text[]))) not valid;

alter table "public"."formatos_control_mp_ph" validate constraint "fcmptph_status_check";

alter table "public"."formatos_control_mp_ph_lotes" add constraint "fcmptph_lotes_formato_fkey" FOREIGN KEY (formato_id) REFERENCES public.formatos_control_mp_ph(id) ON DELETE CASCADE not valid;

alter table "public"."formatos_control_mp_ph_lotes" validate constraint "fcmptph_lotes_formato_fkey";

alter table "public"."formatos_control_mp_ph_lotes" add constraint "fcmptph_lotes_lote_fkey" FOREIGN KEY (lote_campo_id) REFERENCES public.production_batches(id) ON DELETE CASCADE not valid;

alter table "public"."formatos_control_mp_ph_lotes" validate constraint "fcmptph_lotes_lote_fkey";

alter table "public"."formatos_control_personal" add constraint "fcpo_batch_fkey" FOREIGN KEY (production_batch_id) REFERENCES public.production_batches(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_control_personal" validate constraint "fcpo_batch_fkey";

alter table "public"."formatos_control_personal" add constraint "fcpo_codigo_key" UNIQUE using index "fcpo_codigo_key";

alter table "public"."formatos_control_personal" add constraint "fcpo_cooperative_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_control_personal" validate constraint "fcpo_cooperative_fkey";

alter table "public"."formatos_control_personal" add constraint "fcpo_status_check" CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'emitted'::character varying])::text[]))) not valid;

alter table "public"."formatos_control_personal" validate constraint "fcpo_status_check";

alter table "public"."formatos_control_personal" add constraint "fcpo_unique_batch" UNIQUE using index "fcpo_unique_batch";

alter table "public"."formatos_control_plagas" add constraint "fcp_code_key" UNIQUE using index "fcp_code_key";

alter table "public"."formatos_control_plagas" add constraint "fcp_coop_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_control_plagas" validate constraint "fcp_coop_fkey";

alter table "public"."formatos_control_plagas" add constraint "fcp_module_fkey" FOREIGN KEY (module_id) REFERENCES public.coop_modules(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_control_plagas" validate constraint "fcp_module_fkey";

alter table "public"."formatos_control_plagas" add constraint "fcp_status_chk" CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'emitted'::character varying])::text[]))) not valid;

alter table "public"."formatos_control_plagas" validate constraint "fcp_status_chk";

alter table "public"."formatos_inspeccion_ambientes" add constraint "fiae_code_key" UNIQUE using index "fiae_code_key";

alter table "public"."formatos_inspeccion_ambientes" add constraint "fiae_coop_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_inspeccion_ambientes" validate constraint "fiae_coop_fkey";

alter table "public"."formatos_inspeccion_ambientes" add constraint "fiae_insp_key" UNIQUE using index "fiae_insp_key";

alter table "public"."formatos_inspeccion_ambientes" add constraint "fiae_inspection_fkey" FOREIGN KEY (inspection_id) REFERENCES public.environment_inspections(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_inspeccion_ambientes" validate constraint "fiae_inspection_fkey";

alter table "public"."formatos_inspeccion_ambientes" add constraint "fiae_module_fkey" FOREIGN KEY (module_id) REFERENCES public.coop_modules(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_inspeccion_ambientes" validate constraint "fiae_module_fkey";

alter table "public"."formatos_inspeccion_ambientes" add constraint "fiae_status_chk" CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'emitted'::character varying])::text[]))) not valid;

alter table "public"."formatos_inspeccion_ambientes" validate constraint "fiae_status_chk";

alter table "public"."formatos_limpieza_desinfeccion" add constraint "fldh_code_key" UNIQUE using index "fldh_code_key";

alter table "public"."formatos_limpieza_desinfeccion" add constraint "fldh_coop_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_limpieza_desinfeccion" validate constraint "fldh_coop_fkey";

alter table "public"."formatos_limpieza_desinfeccion" add constraint "fldh_module_fkey" FOREIGN KEY (module_id) REFERENCES public.coop_modules(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_limpieza_desinfeccion" validate constraint "fldh_module_fkey";

alter table "public"."formatos_limpieza_desinfeccion" add constraint "fldh_status_chk" CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'emitted'::character varying])::text[]))) not valid;

alter table "public"."formatos_limpieza_desinfeccion" validate constraint "fldh_status_chk";

alter table "public"."formatos_mantenimiento_equipos" add constraint "fmeh_code_key" UNIQUE using index "fmeh_code_key";

alter table "public"."formatos_mantenimiento_equipos" add constraint "fmeh_coop_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_mantenimiento_equipos" validate constraint "fmeh_coop_fkey";

alter table "public"."formatos_mantenimiento_equipos" add constraint "fmeh_module_fkey" FOREIGN KEY (module_id) REFERENCES public.coop_modules(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_mantenimiento_equipos" validate constraint "fmeh_module_fkey";

alter table "public"."formatos_mantenimiento_equipos" add constraint "fmeh_status_chk" CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'emitted'::character varying])::text[]))) not valid;

alter table "public"."formatos_mantenimiento_equipos" validate constraint "fmeh_status_chk";

alter table "public"."formatos_seguimiento_salud" add constraint "fsea_code_key" UNIQUE using index "fsea_code_key";

alter table "public"."formatos_seguimiento_salud" add constraint "fsea_coop_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_seguimiento_salud" validate constraint "fsea_coop_fkey";

alter table "public"."formatos_seguimiento_salud" add constraint "fsea_module_fkey" FOREIGN KEY (module_id) REFERENCES public.coop_modules(id) ON DELETE RESTRICT not valid;

alter table "public"."formatos_seguimiento_salud" validate constraint "fsea_module_fkey";

alter table "public"."formatos_seguimiento_salud" add constraint "fsea_status_chk" CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'emitted'::character varying])::text[]))) not valid;

alter table "public"."formatos_seguimiento_salud" validate constraint "fsea_status_chk";

alter table "public"."health_incidents" add constraint "health_incidents_coop_module_id_fkey" FOREIGN KEY (coop_module_id) REFERENCES public.coop_modules(id) ON DELETE RESTRICT not valid;

alter table "public"."health_incidents" validate constraint "health_incidents_coop_module_id_fkey";

alter table "public"."health_incidents" add constraint "health_incidents_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."health_incidents" validate constraint "health_incidents_cooperative_id_fkey";

alter table "public"."health_incidents" add constraint "health_incidents_created_by_fkey" FOREIGN KEY (created_by, cooperative_id) REFERENCES public.users(user_id, cooperative_id) ON DELETE RESTRICT not valid;

alter table "public"."health_incidents" validate constraint "health_incidents_created_by_fkey";

alter table "public"."inventory_stock" add constraint "inventory_stock_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."inventory_stock" validate constraint "inventory_stock_cooperative_id_fkey";

alter table "public"."inventory_stock" add constraint "inventory_stock_current_kg_check" CHECK ((current_kg >= (0)::numeric)) not valid;

alter table "public"."inventory_stock" validate constraint "inventory_stock_current_kg_check";

alter table "public"."inventory_stock" add constraint "inventory_stock_production_batch_id_fkey" FOREIGN KEY (production_batch_id) REFERENCES public.production_batches(id) ON DELETE CASCADE not valid;

alter table "public"."inventory_stock" validate constraint "inventory_stock_production_batch_id_fkey";

alter table "public"."inventory_stock" add constraint "inventory_stock_reserved_kg_check" CHECK ((reserved_kg >= (0)::numeric)) not valid;

alter table "public"."inventory_stock" validate constraint "inventory_stock_reserved_kg_check";

alter table "public"."inventory_stock" add constraint "unique_stock_per_batch" UNIQUE using index "unique_stock_per_batch";

alter table "public"."inventory_stock" add constraint "valid_reserved_stock" CHECK ((reserved_kg <= current_kg)) not valid;

alter table "public"."inventory_stock" validate constraint "valid_reserved_stock";

alter table "public"."pest_control_bait_records" add constraint "at_least_one_bait_station" CHECK ((jsonb_array_length(bait_stations) > 0)) not valid;

alter table "public"."pest_control_bait_records" validate constraint "at_least_one_bait_station";

alter table "public"."pest_control_bait_records" add constraint "pest_control_bait_records_pest_control_id_fkey" FOREIGN KEY (pest_control_id) REFERENCES public.pest_controls(id) ON DELETE CASCADE not valid;

alter table "public"."pest_control_bait_records" validate constraint "pest_control_bait_records_pest_control_id_fkey";

alter table "public"."pest_control_bait_records" add constraint "pest_control_bait_records_quantity_check" CHECK ((quantity > (0)::numeric)) not valid;

alter table "public"."pest_control_bait_records" validate constraint "pest_control_bait_records_quantity_check";

alter table "public"."pest_control_insect_records" add constraint "at_least_one_insect_record" CHECK ((jsonb_array_length(insect_data) > 0)) not valid;

alter table "public"."pest_control_insect_records" validate constraint "at_least_one_insect_record";

alter table "public"."pest_control_insect_records" add constraint "pest_control_insect_records_pest_control_id_fkey" FOREIGN KEY (pest_control_id) REFERENCES public.pest_controls(id) ON DELETE CASCADE not valid;

alter table "public"."pest_control_insect_records" validate constraint "pest_control_insect_records_pest_control_id_fkey";

alter table "public"."pest_control_insect_records" add constraint "pest_control_insect_records_quantity_check" CHECK ((quantity > (0)::numeric)) not valid;

alter table "public"."pest_control_insect_records" validate constraint "pest_control_insect_records_quantity_check";

alter table "public"."pest_controls" add constraint "pest_controls_coop_module_id_fkey" FOREIGN KEY (coop_module_id) REFERENCES public.coop_modules(id) not valid;

alter table "public"."pest_controls" validate constraint "pest_controls_coop_module_id_fkey";

alter table "public"."pest_controls" add constraint "pest_controls_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) not valid;

alter table "public"."pest_controls" validate constraint "pest_controls_cooperative_id_fkey";

alter table "public"."plant_batch_processing" add constraint "chk_pbp_descarte_non_negative" CHECK ((descarte_kg >= (0)::numeric)) not valid;

alter table "public"."plant_batch_processing" validate constraint "chk_pbp_descarte_non_negative";

alter table "public"."plant_batch_processing" add constraint "chk_pbp_merma_non_negative" CHECK ((merma_kg >= (0)::numeric)) not valid;

alter table "public"."plant_batch_processing" validate constraint "chk_pbp_merma_non_negative";

alter table "public"."plant_batch_processing" add constraint "chk_pbp_no_all_zero" CHECK ((((tamizada_kg + descarte_kg) + merma_kg) > (0)::numeric)) not valid;

alter table "public"."plant_batch_processing" validate constraint "chk_pbp_no_all_zero";

alter table "public"."plant_batch_processing" add constraint "chk_pbp_tamizada_non_negative" CHECK ((tamizada_kg >= (0)::numeric)) not valid;

alter table "public"."plant_batch_processing" validate constraint "chk_pbp_tamizada_non_negative";

alter table "public"."plant_batch_processing" add constraint "plant_batch_processing_plant_batch_id_fkey" FOREIGN KEY (plant_batch_id) REFERENCES public.plant_production_batches(id) ON DELETE CASCADE not valid;

alter table "public"."plant_batch_processing" validate constraint "plant_batch_processing_plant_batch_id_fkey";

alter table "public"."plant_batch_processing" add constraint "plant_batch_processing_plant_batch_id_key" UNIQUE using index "plant_batch_processing_plant_batch_id_key";

alter table "public"."plant_checklists" add constraint "plant_checklists_plant_batch_id_fkey" FOREIGN KEY (plant_batch_id) REFERENCES public.plant_production_batches(id) ON DELETE CASCADE not valid;

alter table "public"."plant_checklists" validate constraint "plant_checklists_plant_batch_id_fkey";

alter table "public"."plant_checklists" add constraint "plant_checklists_plant_batch_id_type_key" UNIQUE using index "plant_checklists_plant_batch_id_type_key";

alter table "public"."plant_checklists" add constraint "plant_checklists_type_check" CHECK ((type = ANY (ARRAY['limpieza'::text, 'mantenimiento_equipos'::text, 'control_plagas'::text, 'control_personal'::text]))) not valid;

alter table "public"."plant_checklists" validate constraint "plant_checklists_type_check";

alter table "public"."plant_containers" add constraint "plant_containers_status_check" CHECK ((status = ANY (ARRAY['preparando'::text, 'cargado'::text, 'despachado'::text, 'en_transito'::text, 'entregado'::text]))) not valid;

alter table "public"."plant_containers" validate constraint "plant_containers_status_check";

alter table "public"."plant_dispatches" add constraint "plant_dispatches_container_id_fkey" FOREIGN KEY (container_id) REFERENCES public.plant_containers(id) ON DELETE CASCADE not valid;

alter table "public"."plant_dispatches" validate constraint "plant_dispatches_container_id_fkey";

alter table "public"."plant_dispatches" add constraint "plant_dispatches_dispatch_code_key" UNIQUE using index "plant_dispatches_dispatch_code_key";

alter table "public"."plant_homogenization_inputs" add constraint "chk_phi_qty_positive" CHECK ((quantity_kg > (0)::numeric)) not valid;

alter table "public"."plant_homogenization_inputs" validate constraint "chk_phi_qty_positive";

alter table "public"."plant_homogenization_inputs" add constraint "plant_homogenization_inputs_plant_batch_id_fkey" FOREIGN KEY (plant_batch_id) REFERENCES public.plant_production_batches(id) ON DELETE CASCADE not valid;

alter table "public"."plant_homogenization_inputs" validate constraint "plant_homogenization_inputs_plant_batch_id_fkey";

alter table "public"."plant_homogenization_inputs" add constraint "plant_homogenization_inputs_source_exit_item_id_fkey" FOREIGN KEY (source_exit_item_id) REFERENCES public.exit_items(id) not valid;

alter table "public"."plant_homogenization_inputs" validate constraint "plant_homogenization_inputs_source_exit_item_id_fkey";

alter table "public"."plant_hygiene_areas" add constraint "plant_hygiene_areas_area_code_check" CHECK ((area_code = ANY (ARRAY['TH'::text, 'ENV'::text]))) not valid;

alter table "public"."plant_hygiene_areas" validate constraint "plant_hygiene_areas_area_code_check";

alter table "public"."plant_hygiene_areas" add constraint "plant_hygiene_areas_cooperative_date_area_key" UNIQUE using index "plant_hygiene_areas_cooperative_date_area_key";

alter table "public"."plant_hygiene_areas" add constraint "plant_hygiene_areas_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."plant_hygiene_areas" validate constraint "plant_hygiene_areas_cooperative_id_fkey";

alter table "public"."plant_hygiene_areas" add constraint "plant_hygiene_areas_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.web_users(id) ON DELETE RESTRICT not valid;

alter table "public"."plant_hygiene_areas" validate constraint "plant_hygiene_areas_created_by_fkey";

alter table "public"."plant_hygiene_worker_criteria" add constraint "plant_hygiene_worker_criteria_item_code_check" CHECK ((item_code = ANY (ARRAY['vestimenta_adecuada'::text, 'sin_maquillaje'::text, 'unas_cortas_limpias'::text, 'sin_joyas'::text, 'cabello_corto'::text, 'cabello_recogido'::text, 'afeitado'::text, 'sin_heridas_expuestas'::text]))) not valid;

alter table "public"."plant_hygiene_worker_criteria" validate constraint "plant_hygiene_worker_criteria_item_code_check";

alter table "public"."plant_hygiene_worker_criteria" add constraint "plant_hygiene_worker_criteria_worker_id_fkey" FOREIGN KEY (worker_id) REFERENCES public.plant_hygiene_workers(id) ON DELETE CASCADE not valid;

alter table "public"."plant_hygiene_worker_criteria" validate constraint "plant_hygiene_worker_criteria_worker_id_fkey";

alter table "public"."plant_hygiene_worker_criteria" add constraint "plant_hygiene_worker_criteria_worker_item_key" UNIQUE using index "plant_hygiene_worker_criteria_worker_item_key";

alter table "public"."plant_hygiene_workers" add constraint "plant_hygiene_workers_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."plant_hygiene_workers" validate constraint "plant_hygiene_workers_cooperative_id_fkey";

alter table "public"."plant_hygiene_workers" add constraint "plant_hygiene_workers_hygiene_area_id_fkey" FOREIGN KEY (hygiene_area_id) REFERENCES public.plant_hygiene_areas(id) ON DELETE CASCADE not valid;

alter table "public"."plant_hygiene_workers" validate constraint "plant_hygiene_workers_hygiene_area_id_fkey";

alter table "public"."plant_order_checklists" add constraint "plant_order_checklists_order_id_fkey" FOREIGN KEY (order_id) REFERENCES public.plant_orders(id) ON DELETE CASCADE not valid;

alter table "public"."plant_order_checklists" validate constraint "plant_order_checklists_order_id_fkey";

alter table "public"."plant_order_checklists" add constraint "plant_order_checklists_order_id_type_key" UNIQUE using index "plant_order_checklists_order_id_type_key";

alter table "public"."plant_order_checklists" add constraint "plant_order_checklists_type_check" CHECK ((type = ANY (ARRAY['limpieza'::text, 'control_plagas'::text]))) not valid;

alter table "public"."plant_order_checklists" validate constraint "plant_order_checklists_type_check";

alter table "public"."plant_orders" add constraint "chk_po_market_not_empty" CHECK ((TRIM(BOTH FROM market) <> ''::text)) not valid;

alter table "public"."plant_orders" validate constraint "chk_po_market_not_empty";

alter table "public"."plant_orders" add constraint "chk_po_status_valid" CHECK ((status = ANY (ARRAY['en_proceso'::text, 'completado'::text]))) not valid;

alter table "public"."plant_orders" validate constraint "chk_po_status_valid";

alter table "public"."plant_orders" add constraint "plant_orders_container_id_fkey" FOREIGN KEY (container_id) REFERENCES public.plant_containers(id) ON DELETE SET NULL not valid;

alter table "public"."plant_orders" validate constraint "plant_orders_container_id_fkey";

alter table "public"."plant_orders" add constraint "plant_orders_order_code_key" UNIQUE using index "plant_orders_order_code_key";

alter table "public"."plant_production_batches" add constraint "chk_ppb_brand_not_empty" CHECK ((TRIM(BOTH FROM brand) <> ''::text)) not valid;

alter table "public"."plant_production_batches" validate constraint "chk_ppb_brand_not_empty";

alter table "public"."plant_production_batches" add constraint "chk_ppb_planned_qty_positive" CHECK ((planned_quantity > 0)) not valid;

alter table "public"."plant_production_batches" validate constraint "chk_ppb_planned_qty_positive";

alter table "public"."plant_production_batches" add constraint "chk_ppb_presentation_not_empty" CHECK ((TRIM(BOTH FROM presentation) <> ''::text)) not valid;

alter table "public"."plant_production_batches" validate constraint "chk_ppb_presentation_not_empty";

alter table "public"."plant_production_batches" add constraint "chk_ppb_status_valid" CHECK ((status = ANY (ARRAY['pendiente_homogenizado'::text, 'homogenizado'::text, 'procesado'::text]))) not valid;

alter table "public"."plant_production_batches" validate constraint "chk_ppb_status_valid";

alter table "public"."plant_production_batches" add constraint "chk_ppb_unit_weight_positive" CHECK ((unit_weight_kg > (0)::numeric)) not valid;

alter table "public"."plant_production_batches" validate constraint "chk_ppb_unit_weight_positive";

alter table "public"."plant_production_batches" add constraint "plant_production_batches_batch_code_key" UNIQUE using index "plant_production_batches_batch_code_key";

alter table "public"."plant_production_batches" add constraint "plant_production_batches_order_id_fkey" FOREIGN KEY (order_id) REFERENCES public.plant_orders(id) ON DELETE CASCADE not valid;

alter table "public"."plant_production_batches" validate constraint "plant_production_batches_order_id_fkey";

alter table "public"."plots" add constraint "plots_default_cachaza_percentage_check" CHECK (((default_cachaza_percentage IS NULL) OR ((default_cachaza_percentage >= (0)::numeric) AND (default_cachaza_percentage <= (100)::numeric)))) not valid;

alter table "public"."plots" validate constraint "plots_default_cachaza_percentage_check";

alter table "public"."plots" add constraint "plots_default_extraction_percentage_check" CHECK (((default_extraction_percentage IS NULL) OR ((default_extraction_percentage >= (0)::numeric) AND (default_extraction_percentage <= (100)::numeric)))) not valid;

alter table "public"."plots" validate constraint "plots_default_extraction_percentage_check";

alter table "public"."plots" add constraint "plots_producer_id_fkey" FOREIGN KEY (producer_id) REFERENCES public.producers(id) ON DELETE CASCADE not valid;

alter table "public"."plots" validate constraint "plots_producer_id_fkey";

alter table "public"."plots" add constraint "unique_plot_name_code_per_producer" UNIQUE using index "unique_plot_name_code_per_producer";

alter table "public"."producers" add constraint "producers_coop_module_id_fkey" FOREIGN KEY (coop_module_id) REFERENCES public.coop_modules(id) ON DELETE RESTRICT not valid;

alter table "public"."producers" validate constraint "producers_coop_module_id_fkey";

alter table "public"."producers" add constraint "producers_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE CASCADE not valid;

alter table "public"."producers" validate constraint "producers_cooperative_id_fkey";

alter table "public"."producers" add constraint "producers_default_cachaza_percentage_check" CHECK (((default_cachaza_percentage >= (0)::numeric) AND (default_cachaza_percentage <= (100)::numeric))) not valid;

alter table "public"."producers" validate constraint "producers_default_cachaza_percentage_check";

alter table "public"."producers" add constraint "producers_default_extraction_percentage_check" CHECK (((default_extraction_percentage >= (0)::numeric) AND (default_extraction_percentage <= (100)::numeric))) not valid;

alter table "public"."producers" validate constraint "producers_default_extraction_percentage_check";

alter table "public"."producers" add constraint "unique_dni_per_module" UNIQUE using index "unique_dni_per_module";

alter table "public"."product_returns" add constraint "product_returns_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."product_returns" validate constraint "product_returns_cooperative_id_fkey";

alter table "public"."product_returns" add constraint "product_returns_created_by_fkey" FOREIGN KEY (created_by, cooperative_id) REFERENCES public.users(user_id, cooperative_id) ON DELETE RESTRICT not valid;

alter table "public"."product_returns" validate constraint "product_returns_created_by_fkey";

alter table "public"."product_returns" add constraint "product_returns_production_batch_id_fkey" FOREIGN KEY (production_batch_id) REFERENCES public.production_batches(id) ON DELETE RESTRICT not valid;

alter table "public"."product_returns" validate constraint "product_returns_production_batch_id_fkey";

alter table "public"."product_returns" add constraint "product_returns_quantity_kg_check" CHECK ((quantity_kg > (0)::numeric)) not valid;

alter table "public"."product_returns" validate constraint "product_returns_quantity_kg_check";

alter table "public"."product_returns" add constraint "product_returns_quantity_sacks_check" CHECK ((quantity_sacks >= 0)) not valid;

alter table "public"."product_returns" validate constraint "product_returns_quantity_sacks_check";

alter table "public"."production_batch_certs" add constraint "production_batch_certs_batch_cert_id_fkey" FOREIGN KEY (batch_cert_id) REFERENCES public.batch_certs(id) ON DELETE RESTRICT not valid;

alter table "public"."production_batch_certs" validate constraint "production_batch_certs_batch_cert_id_fkey";

alter table "public"."production_batch_certs" add constraint "production_batch_certs_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."production_batch_certs" validate constraint "production_batch_certs_cooperative_id_fkey";

alter table "public"."production_batch_certs" add constraint "production_batch_certs_production_batch_id_batch_cert_id_key" UNIQUE using index "production_batch_certs_production_batch_id_batch_cert_id_key";

alter table "public"."production_batch_certs" add constraint "production_batch_certs_production_batch_id_fkey" FOREIGN KEY (production_batch_id) REFERENCES public.production_batches(id) ON DELETE CASCADE not valid;

alter table "public"."production_batch_certs" validate constraint "production_batch_certs_production_batch_id_fkey";

alter table "public"."production_batches" add constraint "production_batches_batch_code_key" UNIQUE using index "production_batches_batch_code_key";

alter table "public"."production_batches" add constraint "production_batches_cachaza_percentage_check" CHECK (((cachaza_percentage >= (0)::numeric) AND (cachaza_percentage <= (100)::numeric))) not valid;

alter table "public"."production_batches" validate constraint "production_batches_cachaza_percentage_check";

alter table "public"."production_batches" add constraint "production_batches_cane_kg_check" CHECK ((cane_kg > (0)::numeric)) not valid;

alter table "public"."production_batches" validate constraint "production_batches_cane_kg_check";

alter table "public"."production_batches" add constraint "production_batches_confitillo_kg_check" CHECK ((confitillo_kg >= (0)::numeric)) not valid;

alter table "public"."production_batches" validate constraint "production_batches_confitillo_kg_check";

alter table "public"."production_batches" add constraint "production_batches_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."production_batches" validate constraint "production_batches_cooperative_id_fkey";

alter table "public"."production_batches" add constraint "production_batches_juice_liters_check" CHECK ((juice_liters > (0)::numeric)) not valid;

alter table "public"."production_batches" validate constraint "production_batches_juice_liters_check";

alter table "public"."production_batches" add constraint "production_batches_panela_kg_check" CHECK ((panela_kg >= (0)::numeric)) not valid;

alter table "public"."production_batches" validate constraint "production_batches_panela_kg_check";

alter table "public"."production_batches" add constraint "production_batches_plot_id_fkey" FOREIGN KEY (plot_id) REFERENCES public.plots(id) ON DELETE RESTRICT not valid;

alter table "public"."production_batches" validate constraint "production_batches_plot_id_fkey";

alter table "public"."production_batches" add constraint "production_batches_porcentaje_extraccion_check" CHECK (((porcentaje_extraccion >= (0)::numeric) AND (porcentaje_extraccion <= (100)::numeric))) not valid;

alter table "public"."production_batches" validate constraint "production_batches_porcentaje_extraccion_check";

alter table "public"."production_batches" add constraint "production_batches_producer_id_fkey" FOREIGN KEY (producer_id) REFERENCES public.producers(id) ON DELETE RESTRICT not valid;

alter table "public"."production_batches" validate constraint "production_batches_producer_id_fkey";

alter table "public"."production_batches" add constraint "production_batches_registered_by_fkey" FOREIGN KEY (registered_by_user_id, cooperative_id) REFERENCES public.users(user_id, cooperative_id) ON DELETE RESTRICT not valid;

alter table "public"."production_batches" validate constraint "production_batches_registered_by_fkey";

alter table "public"."quality_evaluations" add constraint "quality_evaluations_appearance_check" CHECK (((appearance)::text = ANY (ARRAY[('suelta'::character varying)::text, ('seca'::character varying)::text, ('cerosa'::character varying)::text]))) not valid;

alter table "public"."quality_evaluations" validate constraint "quality_evaluations_appearance_check";

alter table "public"."quality_evaluations" add constraint "quality_evaluations_approval_status_check" CHECK (((approval_status IS NULL) OR ((approval_status)::text = ANY (ARRAY[('aprobado'::character varying)::text, ('rechazado'::character varying)::text, ('aprobado_con_observaciones'::character varying)::text])))) not valid;

alter table "public"."quality_evaluations" validate constraint "quality_evaluations_approval_status_check";

alter table "public"."quality_evaluations" add constraint "quality_evaluations_color_check" CHECK (((color)::text = ANY (ARRAY[('amarillo claro'::character varying)::text, ('amarillo oscuro'::character varying)::text, ('verde'::character varying)::text, ('marron claro'::character varying)::text, ('marron oscuro'::character varying)::text]))) not valid;

alter table "public"."quality_evaluations" validate constraint "quality_evaluations_color_check";

alter table "public"."quality_evaluations" add constraint "quality_evaluations_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."quality_evaluations" validate constraint "quality_evaluations_cooperative_id_fkey";

alter table "public"."quality_evaluations" add constraint "quality_evaluations_evaluated_by_fkey" FOREIGN KEY (evaluated_by) REFERENCES public.web_users(id) ON DELETE RESTRICT not valid;

alter table "public"."quality_evaluations" validate constraint "quality_evaluations_evaluated_by_fkey";

alter table "public"."quality_evaluations" add constraint "quality_evaluations_exit_item_id_fkey" FOREIGN KEY (exit_item_id) REFERENCES public.exit_items(id) ON DELETE RESTRICT not valid;

alter table "public"."quality_evaluations" validate constraint "quality_evaluations_exit_item_id_fkey";

alter table "public"."quality_evaluations" add constraint "quality_evaluations_exit_item_id_key" UNIQUE using index "quality_evaluations_exit_item_id_key";

alter table "public"."quality_evaluations" add constraint "quality_evaluations_exit_reception_id_fkey" FOREIGN KEY (exit_reception_id) REFERENCES public.exit_receptions(id) ON DELETE RESTRICT not valid;

alter table "public"."quality_evaluations" validate constraint "quality_evaluations_exit_reception_id_fkey";

alter table "public"."quality_evaluations" add constraint "quality_evaluations_humidity_pct_check" CHECK (((humidity_pct >= (0)::numeric) AND (humidity_pct <= (100)::numeric))) not valid;

alter table "public"."quality_evaluations" validate constraint "quality_evaluations_humidity_pct_check";

alter table "public"."quality_evaluations" add constraint "quality_evaluations_impurities_pct_check" CHECK (((impurities_pct >= (0)::numeric) AND (impurities_pct <= (100)::numeric))) not valid;

alter table "public"."quality_evaluations" validate constraint "quality_evaluations_impurities_pct_check";

alter table "public"."quality_evaluations" add constraint "quality_evaluations_sack_condition_check" CHECK (((sack_condition)::text = ANY (ARRAY[('buena'::character varying)::text, ('regular'::character varying)::text, ('mala'::character varying)::text]))) not valid;

alter table "public"."quality_evaluations" validate constraint "quality_evaluations_sack_condition_check";

alter table "public"."stowage_transport_inspections" add constraint "sti_formato_codigo_key" UNIQUE using index "sti_formato_codigo_key";

alter table "public"."stowage_transport_inspections" add constraint "sti_status_check" CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'emitted'::character varying])::text[]))) not valid;

alter table "public"."stowage_transport_inspections" validate constraint "sti_status_check";

alter table "public"."stowage_transport_inspections" add constraint "stowage_inspections_exit_unique" UNIQUE using index "stowage_inspections_exit_unique";

alter table "public"."stowage_transport_inspections" add constraint "stowage_inspections_registered_by_fkey" FOREIGN KEY (registered_by_user_id, cooperative_id) REFERENCES public.users(user_id, cooperative_id) ON DELETE RESTRICT not valid;

alter table "public"."stowage_transport_inspections" validate constraint "stowage_inspections_registered_by_fkey";

alter table "public"."stowage_transport_inspections" add constraint "stowage_transport_inspections_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."stowage_transport_inspections" validate constraint "stowage_transport_inspections_cooperative_id_fkey";

alter table "public"."stowage_transport_inspections" add constraint "stowage_transport_inspections_created_by_fkey" FOREIGN KEY (created_by, cooperative_id) REFERENCES public.users(user_id, cooperative_id) ON DELETE RESTRICT not valid;

alter table "public"."stowage_transport_inspections" validate constraint "stowage_transport_inspections_created_by_fkey";

alter table "public"."stowage_transport_inspections" add constraint "stowage_transport_inspections_exit_registration_id_fkey" FOREIGN KEY (exit_registration_id) REFERENCES public.exit_registrations(id) ON DELETE RESTRICT not valid;

alter table "public"."stowage_transport_inspections" validate constraint "stowage_transport_inspections_exit_registration_id_fkey";

alter table "public"."user_module_assignments" add constraint "user_module_assignments_coop_module_id_fkey" FOREIGN KEY (coop_module_id) REFERENCES public.coop_modules(id) ON DELETE CASCADE not valid;

alter table "public"."user_module_assignments" validate constraint "user_module_assignments_coop_module_id_fkey";

alter table "public"."user_module_assignments" add constraint "user_module_assignments_user_id_cooperative_id_fkey" FOREIGN KEY (user_id, cooperative_id) REFERENCES public.users(user_id, cooperative_id) ON DELETE CASCADE not valid;

alter table "public"."user_module_assignments" validate constraint "user_module_assignments_user_id_cooperative_id_fkey";

alter table "public"."users" add constraint "users_auth_user_id_fkey" FOREIGN KEY (auth_user_id) REFERENCES auth.users(id) not valid;

alter table "public"."users" validate constraint "users_auth_user_id_fkey";

alter table "public"."users" add constraint "users_auth_user_id_key" UNIQUE using index "users_auth_user_id_key";

alter table "public"."users" add constraint "users_coop_module_id_fkey" FOREIGN KEY (coop_module_id) REFERENCES public.coop_modules(id) ON DELETE SET NULL not valid;

alter table "public"."users" validate constraint "users_coop_module_id_fkey";

alter table "public"."users" add constraint "users_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) not valid;

alter table "public"."users" validate constraint "users_cooperative_id_fkey";

alter table "public"."users" add constraint "users_email_key" UNIQUE using index "users_email_key";

alter table "public"."users" add constraint "users_role_check" CHECK ((role = ANY (ARRAY['admin_sistema'::text, 'admin_modulo'::text, 'tecnico_campo'::text, 'productor'::text]))) not valid;

alter table "public"."users" validate constraint "users_role_check";

alter table "public"."web_users" add constraint "web_users_auth_user_id_fkey" FOREIGN KEY (auth_user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."web_users" validate constraint "web_users_auth_user_id_fkey";

alter table "public"."web_users" add constraint "web_users_auth_user_id_key" UNIQUE using index "web_users_auth_user_id_key";

alter table "public"."web_users" add constraint "web_users_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."web_users" validate constraint "web_users_cooperative_id_fkey";

alter table "public"."web_users" add constraint "web_users_role_check" CHECK (((role)::text = ANY (ARRAY[('admin_web'::character varying)::text, ('operador'::character varying)::text]))) not valid;

alter table "public"."web_users" validate constraint "web_users_role_check";

alter table "public"."web_users" add constraint "web_users_username_key" UNIQUE using index "web_users_username_key";

alter table "public"."worker_control_items" add constraint "worker_control_items_worker_control_id_fkey" FOREIGN KEY (worker_control_id) REFERENCES public.worker_controls(id) ON DELETE CASCADE not valid;

alter table "public"."worker_control_items" validate constraint "worker_control_items_worker_control_id_fkey";

alter table "public"."worker_controls" add constraint "worker_controls_cooperative_id_fkey" FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE RESTRICT not valid;

alter table "public"."worker_controls" validate constraint "worker_controls_cooperative_id_fkey";

alter table "public"."worker_controls" add constraint "worker_controls_created_by_fkey" FOREIGN KEY (created_by, cooperative_id) REFERENCES public.users(user_id, cooperative_id) ON DELETE RESTRICT not valid;

alter table "public"."worker_controls" validate constraint "worker_controls_created_by_fkey";

alter table "public"."worker_controls" add constraint "worker_controls_production_batch_id_fkey" FOREIGN KEY (production_batch_id) REFERENCES public.production_batches(id) ON DELETE RESTRICT not valid;

alter table "public"."worker_controls" validate constraint "worker_controls_production_batch_id_fkey";

alter table "public"."worker_controls" add constraint "worker_controls_work_area_check" CHECK ((work_area = ANY (ARRAY['M'::text, 'H'::text, 'TT'::text, 'TEA'::text, 'rr'::text]))) not valid;

alter table "public"."worker_controls" validate constraint "worker_controls_work_area_check";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.auth_cooperative_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE
AS $function$
  SELECT NULLIF(
    current_setting('request.jwt.claims', true)::jsonb ->> 'cooperative_id',
    ''
  )::uuid
$function$
;

CREATE OR REPLACE FUNCTION public.auto_assign_plot_code()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Only assign code if it's not provided
    IF NEW.code IS NULL OR NEW.code = '' THEN
        -- Generate code based on producer_id directly (no need to lookup cooperative)
        NEW.code := generate_plot_code(NEW.producer_id);
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.auto_generate_exit_code()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Only generate if exit_code is not provided
    IF NEW.exit_code IS NULL OR NEW.exit_code = '' THEN
        NEW.exit_code := generate_exit_code(NEW.cooperative_id);
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_auth_user_for_dni(dni character varying, user_password text, cooperative_id uuid, user_email text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_auth_user_id UUID;
  virtual_email TEXT;
  coop_code VARCHAR(50);
BEGIN
  -- Get cooperative code
  SELECT get_cooperative_code($3) INTO coop_code;

  -- Use provided email or create virtual email for DNI with cooperative code
  IF user_email IS NULL THEN
    virtual_email := dni || '.' || coop_code || '@dni.local';
  ELSE
    virtual_email := user_email;
  END IF;

  -- Create user in auth.users table
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    virtual_email,
    crypt(user_password, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  ) RETURNING id INTO v_auth_user_id;

  -- Update users table with auth_user_id and email
  UPDATE public.users
  SET
    auth_user_id = v_auth_user_id,
    email = virtual_email
  WHERE user_id = dni AND public.users.cooperative_id = $3;

  RETURN v_auth_user_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_auth_user_for_dni(dni character varying, user_password text, user_email text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_auth_user_id UUID;
  virtual_email TEXT;
BEGIN
  -- Use provided email or create virtual email for DNI
  IF user_email IS NULL THEN
    virtual_email := dni || '@dni.local';
  ELSE
    virtual_email := user_email;
  END IF;

  -- Create user in auth.users table
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    virtual_email,
    crypt(user_password, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  ) RETURNING id INTO v_auth_user_id;

  -- Update users table with auth_user_id and email
  UPDATE public.users
  SET
    auth_user_id = v_auth_user_id,
    email = virtual_email
  WHERE user_id = dni;

  RETURN v_auth_user_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  claims      jsonb;
  coop_id     uuid;
  user_role   text;
  auth_uid    uuid;
BEGIN
  auth_uid := (event ->> 'user_id')::uuid;
  claims   := event -> 'claims';

  -- 1) Buscar primero en web_users (portal web)
  SELECT cooperative_id, role INTO coop_id, user_role
  FROM public.web_users
  WHERE auth_user_id = auth_uid AND is_active = true
  LIMIT 1;

  -- 2) Si no, buscar en users (app móvil)
  IF coop_id IS NULL THEN
    SELECT cooperative_id, role INTO coop_id, user_role
    FROM public.users
    WHERE auth_user_id = auth_uid
    LIMIT 1;
  END IF;

  -- 3) Inyectar claims
  IF coop_id IS NOT NULL THEN
    claims := jsonb_set(claims, '{cooperative_id}', to_jsonb(coop_id::text));
  END IF;
  IF user_role IS NOT NULL THEN
    claims := jsonb_set(claims, '{app_role}', to_jsonb(user_role));
  END IF;

  event := jsonb_set(event, '{claims}', claims);
  RETURN event;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_control_cloro(p_coop_code text, p_cooperative_id uuid, p_module_id uuid, p_date_from date, p_date_to date, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FCCLR'));

    SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.formatos_control_cloro f
    WHERE f.cooperative_id = p_cooperative_id
      AND f.formato_codigo ~ ('^' || p_coop_code || '-FCCLR-[0-9]+$');

    v_code := p_coop_code || '-FCCLR-' || LPAD(v_next_num::text, 4, '0');

    INSERT INTO public.formatos_control_cloro (
        cooperative_id, module_id, date_from, date_to, formato_codigo,
        emitted_by, emitted_by_name, emitted_at, firmantes, status
    ) VALUES (
        p_cooperative_id, p_module_id, p_date_from, p_date_to, v_code,
        p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
    );

    RETURN jsonb_build_object('formato_codigo', v_code);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_control_personal(p_coop_code text, p_cooperative_id uuid, p_batch_id uuid, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FCPO'));

    SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.formatos_control_personal f
    WHERE f.cooperative_id = p_cooperative_id
      AND f.formato_codigo ~ ('^' || p_coop_code || '-FCPO-[0-9]+$');

    v_code := p_coop_code || '-FCPO-' || LPAD(v_next_num::text, 4, '0');

    INSERT INTO public.formatos_control_personal (
        cooperative_id, production_batch_id, formato_codigo,
        emitted_by, emitted_by_name, emitted_at, firmantes, status
    ) VALUES (
        p_cooperative_id, p_batch_id, v_code,
        p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
    )
    ON CONFLICT (cooperative_id, production_batch_id)
    DO UPDATE SET
        formato_codigo  = v_code,
        emitted_by      = p_emitted_by,
        emitted_by_name = p_emitted_by_name,
        emitted_at      = now(),
        firmantes       = p_firmantes,
        status          = 'emitted';

    RETURN jsonb_build_object('formato_codigo', v_code);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_control_plagas(p_coop_code text, p_cooperative_id uuid, p_module_id uuid, p_date_from date, p_date_to date, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FCP'));

    SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.formatos_control_plagas f
    WHERE f.cooperative_id = p_cooperative_id
      AND f.formato_codigo ~ ('^' || p_coop_code || '-FCP-[0-9]+$');

    v_code := p_coop_code || '-FCP-' || LPAD(v_next_num::text, 4, '0');

    INSERT INTO public.formatos_control_plagas (
        cooperative_id, module_id, date_from, date_to, formato_codigo,
        emitted_by, emitted_by_name, emitted_at, firmantes, status
    ) VALUES (
        p_cooperative_id, p_module_id, p_date_from, p_date_to, v_code,
        p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
    );

    RETURN jsonb_build_object('formato_codigo', v_code);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_estiba_transporte(p_coop_code text, p_cooperative_id uuid, p_inspection_id uuid, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_next_num integer;
  v_code     text;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FET'));

  SELECT COALESCE(MAX(CAST(SPLIT_PART(s.formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.stowage_transport_inspections s
  WHERE s.cooperative_id = p_cooperative_id
    AND s.formato_codigo ~ ('^' || p_coop_code || '-FET-[0-9]+$');

  v_code := p_coop_code || '-FET-' || LPAD(v_next_num::text, 4, '0');

  UPDATE public.stowage_transport_inspections
  SET formato_codigo  = v_code,
      emitted_by      = p_emitted_by,
      emitted_by_name = p_emitted_by_name,
      emitted_at      = now(),
      firmantes       = p_firmantes,
      status          = 'emitted'
  WHERE id = p_inspection_id;

  RETURN jsonb_build_object('formato_codigo', v_code);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_inspeccion_ambientes(p_coop_code text, p_cooperative_id uuid, p_module_id uuid, p_inspection_id uuid, p_inspection_date date, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FIAE'));

    SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.formatos_inspeccion_ambientes f
    WHERE f.cooperative_id = p_cooperative_id
      AND f.formato_codigo ~ ('^' || p_coop_code || '-FIAE-[0-9]+$');

    v_code := p_coop_code || '-FIAE-' || LPAD(v_next_num::text, 4, '0');

    INSERT INTO public.formatos_inspeccion_ambientes (
        cooperative_id, module_id, inspection_id, inspection_date, formato_codigo,
        emitted_by, emitted_by_name, emitted_at, firmantes, status
    ) VALUES (
        p_cooperative_id, p_module_id, p_inspection_id, p_inspection_date, v_code,
        p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
    )
    ON CONFLICT (inspection_id)
    DO UPDATE SET
        formato_codigo  = v_code,
        emitted_by      = p_emitted_by,
        emitted_by_name = p_emitted_by_name,
        emitted_at      = now(),
        firmantes       = p_firmantes,
        status          = 'emitted';

    RETURN jsonb_build_object('formato_codigo', v_code);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_limpieza_desinfeccion(p_coop_code text, p_cooperative_id uuid, p_module_id uuid, p_date_from date, p_date_to date, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FLDH'));

    SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.formatos_limpieza_desinfeccion f
    WHERE f.cooperative_id = p_cooperative_id
      AND f.formato_codigo ~ ('^' || p_coop_code || '-FLDH-[0-9]+$');

    v_code := p_coop_code || '-FLDH-' || LPAD(v_next_num::text, 4, '0');

    INSERT INTO public.formatos_limpieza_desinfeccion (
        cooperative_id, module_id, date_from, date_to, formato_codigo,
        emitted_by, emitted_by_name, emitted_at, firmantes, status
    ) VALUES (
        p_cooperative_id, p_module_id, p_date_from, p_date_to, v_code,
        p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
    );

    RETURN jsonb_build_object('formato_codigo', v_code);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_mantenimiento_equipos(p_coop_code text, p_cooperative_id uuid, p_module_id uuid, p_date_from date, p_date_to date, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FMEH'));

    SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.formatos_mantenimiento_equipos f
    WHERE f.cooperative_id = p_cooperative_id
      AND f.formato_codigo ~ ('^' || p_coop_code || '-FMEH-[0-9]+$');

    v_code := p_coop_code || '-FMEH-' || LPAD(v_next_num::text, 4, '0');

    INSERT INTO public.formatos_mantenimiento_equipos (
        cooperative_id, module_id, date_from, date_to, formato_codigo,
        emitted_by, emitted_by_name, emitted_at, firmantes, status
    ) VALUES (
        p_cooperative_id, p_module_id, p_date_from, p_date_to, v_code,
        p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
    );

    RETURN jsonb_build_object('formato_codigo', v_code);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_mp_ph(p_coop_code text, p_cooperative_id uuid, p_module_id uuid, p_date_from date, p_date_to date, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb, p_batch_ids uuid[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_next_num   integer;
  v_code       text;
  v_formato_id uuid;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FCMPTPH'));

  SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
  INTO v_next_num
  FROM public.formatos_control_mp_ph f
  WHERE f.cooperative_id = p_cooperative_id
    AND f.formato_codigo ~ ('^' || p_coop_code || '-FCMPTPH-[0-9]+$');

  v_code := p_coop_code || '-FCMPTPH-' || LPAD(v_next_num::text, 4, '0');

  INSERT INTO public.formatos_control_mp_ph (
    formato_codigo, cooperative_id, module_id, date_from, date_to,
    emitted_by, emitted_by_name, emitted_at, firmantes, status
  )
  VALUES (
    v_code, p_cooperative_id, p_module_id, p_date_from, p_date_to,
    p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
  )
  RETURNING id INTO v_formato_id;

  INSERT INTO public.formatos_control_mp_ph_lotes (formato_id, lote_campo_id)
  SELECT v_formato_id, unnest(p_batch_ids);

  RETURN jsonb_build_object('formato_codigo', v_code, 'formato_id', v_formato_id);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.emit_formato_seguimiento_salud(p_coop_code text, p_cooperative_id uuid, p_module_id uuid, p_date_from date, p_date_to date, p_emitted_by uuid, p_emitted_by_name text, p_firmantes jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_next_num integer;
    v_code     text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext(p_coop_code || '-FSEA'));

    SELECT COALESCE(MAX(CAST(SPLIT_PART(f.formato_codigo, '-', 3) AS integer)), 0) + 1
    INTO v_next_num
    FROM public.formatos_seguimiento_salud f
    WHERE f.cooperative_id = p_cooperative_id
      AND f.formato_codigo ~ ('^' || p_coop_code || '-FSEA-[0-9]+$');

    v_code := p_coop_code || '-FSEA-' || LPAD(v_next_num::text, 4, '0');

    INSERT INTO public.formatos_seguimiento_salud (
        cooperative_id, module_id, date_from, date_to, formato_codigo,
        emitted_by, emitted_by_name, emitted_at, firmantes, status
    ) VALUES (
        p_cooperative_id, p_module_id, p_date_from, p_date_to, v_code,
        p_emitted_by, p_emitted_by_name, now(), p_firmantes, 'emitted'
    );

    RETURN jsonb_build_object('formato_codigo', v_code);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_exit_code(coop_id uuid)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
    coop_code VARCHAR(10);
    uuid_part VARCHAR(8);
    new_code VARCHAR(50);
BEGIN
    -- Get cooperative code
    SELECT code INTO coop_code
    FROM cooperatives
    WHERE id = coop_id;

    -- Generate UUID part (first 8 characters of UUID)
    uuid_part := SUBSTRING(gen_random_uuid()::TEXT, 1, 8);

    -- Generate new code: COOP-YYYYMMDD-{uuid_8chars}
    -- Example: NORANDINO-20251028-a1b2c3d4
    new_code := coop_code || '-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || uuid_part;

    RETURN new_code;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_plot_code(producer_id_param uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    producer_dni VARCHAR(8);
    next_code INTEGER;
    sequence_name TEXT;
BEGIN
    -- Get producer DNI
    SELECT dni INTO producer_dni
    FROM public.producers
    WHERE id = producer_id_param;

    IF producer_dni IS NULL THEN
        RAISE EXCEPTION 'Producer not found: %', producer_id_param;
    END IF;

    -- Create producer-specific sequence name
    sequence_name := 'plot_code_seq_' || REPLACE(producer_id_param::TEXT, '-', '_');

    -- Create sequence if it doesn't exist
    EXECUTE format('CREATE SEQUENCE IF NOT EXISTS %I START 1', sequence_name);

    -- Get next value from sequence
    EXECUTE format('SELECT nextval(%L)', sequence_name) INTO next_code;

    -- Return formatted code: DNI-CODE (no padding on number)
    RETURN producer_dni || '-' || next_code::TEXT;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_cooperative_code(coop_id uuid)
 RETURNS character varying
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  coop_code VARCHAR(50);
BEGIN
  SELECT code INTO coop_code
  FROM public.cooperatives
  WHERE id = coop_id;

  IF coop_code IS NULL THEN
    RAISE EXCEPTION 'Cooperative not found: %', coop_id;
  END IF;

  RETURN coop_code;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_next_plot_code(producer_id_param uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    producer_dni VARCHAR(8);
    next_code INTEGER;
    sequence_name TEXT;
BEGIN
    -- Get producer DNI
    SELECT dni INTO producer_dni
    FROM public.producers
    WHERE id = producer_id_param;

    IF producer_dni IS NULL THEN
        RAISE EXCEPTION 'Producer not found: %', producer_id_param;
    END IF;

    -- Create producer-specific sequence name
    sequence_name := 'plot_code_seq_' || REPLACE(producer_id_param::TEXT, '-', '_');

    -- Create sequence if it doesn't exist
    EXECUTE format('CREATE SEQUENCE IF NOT EXISTS %I START 1', sequence_name);

    -- Get current value without incrementing (for preview)
    EXECUTE format('SELECT last_value + CASE WHEN is_called THEN 1 ELSE 0 END FROM %I', sequence_name) INTO next_code;

    -- Return formatted code: DNI-CODE
    RETURN producer_dni || '-' || next_code::TEXT;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.initialize_stock_for_batch()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Initialize stock with panela quantity (sellable product)
    -- Confitillo is tracked separately but doesn't go into inventory
    INSERT INTO inventory_stock (production_batch_id, current_kg, cooperative_id)
    VALUES (NEW.id, COALESCE(NEW.panela_kg, 0), NEW.cooperative_id);

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.is_service_role()
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  SELECT coalesce(
    current_setting('request.jwt.claims', true)::jsonb ->> 'role' = 'service_role',
    false
  )
$function$
;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_created_by_from_auth()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Get user_id from users table matching the authenticated user
  SELECT user_id INTO NEW.created_by
  FROM users
  WHERE auth_user_id = auth.uid();

  -- If no user found, raise exception
  IF NEW.created_by IS NULL THEN
    RAISE EXCEPTION 'No user found for authenticated session';
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_created_by_from_auth_chlorine()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    NEW.created_by := auth.uid();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_created_by_from_auth_cleaning()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    NEW.created_by := auth.uid();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_created_by_from_auth_pest()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    NEW.created_by := auth.uid();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_equipment_maintenance_created_by()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Get user_id from users table based on auth.uid()
  SELECT user_id INTO NEW.created_by
  FROM users
  WHERE auth_user_id = auth.uid();

  -- Raise error if no user found
  IF NEW.created_by IS NULL THEN
    RAISE EXCEPTION 'No se encontró usuario autenticado para la sesión actual';
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_health_incident_created_by()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  SELECT user_id INTO NEW.created_by
  FROM users
  WHERE auth_user_id = auth.uid();

  IF NEW.created_by IS NULL THEN
    RAISE EXCEPTION 'No user found for authenticated session';
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_product_returns_created_by()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Get user_id from users table based on auth.uid()
  SELECT user_id INTO NEW.created_by
  FROM users
  WHERE auth_user_id = auth.uid();

  -- Raise error if no user found
  IF NEW.created_by IS NULL THEN
    RAISE EXCEPTION 'No se encontró usuario autenticado para la sesión actual';
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_registered_by_from_auth()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  SELECT user_id INTO NEW.registered_by_user_id
  FROM users
  WHERE auth_user_id = auth.uid();

  -- Si no se encuentra usuario, no bloquear el insert (puede ser sync offline con service_role)
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_worker_controls_created_by()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Get user_id from users table based on auth.uid()
  SELECT user_id INTO NEW.created_by
  FROM users
  WHERE auth_user_id = auth.uid();

  -- Raise error if no user found
  IF NEW.created_by IS NULL THEN
    RAISE EXCEPTION 'No se encontró usuario autenticado para la sesión actual';
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.setup_dni_user_auth(dni character varying, user_password text, cooperative_id uuid, user_email text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  user_exists BOOLEAN;
  auth_id UUID;
  result JSONB;
BEGIN
  -- Check if user exists in users table for this cooperative
  SELECT EXISTS(
    SELECT 1 FROM public.users
    WHERE user_id = dni AND public.users.cooperative_id = $3
  ) INTO user_exists;

  IF NOT user_exists THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Usuario con DNI ' || dni || ' no existe en esta cooperativa'
    );
  END IF;

  -- Check if user already has auth setup for this cooperative
  SELECT auth_user_id FROM public.users
  WHERE user_id = dni AND public.users.cooperative_id = $3
  INTO auth_id;

  IF auth_id IS NOT NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Usuario ya tiene autenticación configurada'
    );
  END IF;

  -- Create auth user
  SELECT create_auth_user_for_dni(dni, user_password, cooperative_id, user_email) INTO auth_id;

  RETURN jsonb_build_object(
    'success', true,
    'auth_user_id', auth_id,
    'message', 'Autenticación configurada exitosamente para DNI ' || dni
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.setup_dni_user_auth(dni character varying, user_password text, user_email text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  user_exists BOOLEAN;
  auth_id UUID;
  result JSONB;
BEGIN
  -- Check if user exists in users table
  SELECT EXISTS(SELECT 1 FROM public.users WHERE user_id = dni) INTO user_exists;
  
  IF NOT user_exists THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Usuario con DNI ' || dni || ' no existe'
    );
  END IF;

  -- Check if user already has auth setup
  SELECT auth_user_id FROM public.users WHERE user_id = dni INTO auth_id;
  
  IF auth_id IS NOT NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Usuario ya tiene autenticación configurada'
    );
  END IF;

  -- Create auth user
  SELECT create_auth_user_for_dni(dni, user_password, user_email) INTO auth_id;

  RETURN jsonb_build_object(
    'success', true,
    'auth_user_id', auth_id,
    'message', 'Autenticación configurada exitosamente para DNI ' || dni
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_exit_total()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    exit_id UUID;
    total_weight DECIMAL(10,2);
BEGIN
    -- Get exit registration ID
    IF TG_OP = 'DELETE' THEN
        exit_id := OLD.exit_registration_id;
    ELSE
        exit_id := NEW.exit_registration_id;
    END IF;
    
    -- Calculate new total
    SELECT COALESCE(SUM(quantity_kg), 0) INTO total_weight
    FROM exit_items
    WHERE exit_registration_id = exit_id;
    
    -- Update exit registration
    UPDATE exit_registrations 
    SET total_kg = total_weight,
        updated_at = NOW()
    WHERE id = exit_id;
    
    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_plot_default_percentages()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Only proceed if the inserted batch has percentage values AND a plot_id
    IF NEW.porcentaje_extraccion IS NOT NULL
       AND NEW.cachaza_percentage IS NOT NULL
       AND NEW.plot_id IS NOT NULL THEN

        -- Update plot defaults with the values from this batch
        UPDATE public.plots
        SET
            default_extraction_percentage = NEW.porcentaje_extraccion,
            default_cachaza_percentage = NEW.cachaza_percentage,
            updated_at = NOW()
        WHERE id = NEW.plot_id;

        -- Log the update for debugging (optional)
        RAISE NOTICE 'Updated plot % defaults: extraction=%, cachaza=% (from latest batch)',
            NEW.plot_id, NEW.porcentaje_extraccion, NEW.cachaza_percentage;
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_producer_default_percentages()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Only proceed if the inserted batch has percentage values
    IF NEW.porcentaje_extraccion IS NOT NULL AND NEW.cachaza_percentage IS NOT NULL THEN

        -- Update producer defaults with the values from this batch (not average)
        UPDATE public.producers
        SET
            default_extraction_percentage = NEW.porcentaje_extraccion,
            default_cachaza_percentage = NEW.cachaza_percentage,
            updated_at = NOW()
        WHERE id = NEW.producer_id;

        -- Log the update for debugging (optional)
        RAISE NOTICE 'Updated producer % defaults: extraction=%, cachaza=% (from latest batch)',
            NEW.producer_id, NEW.porcentaje_extraccion, NEW.cachaza_percentage;
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_stock_after_exit()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    old_quantity DECIMAL(10,2) := 0;
    new_quantity DECIMAL(10,2) := 0;
    stock_change DECIMAL(10,2);
BEGIN
    -- Handle different trigger events
    IF TG_OP = 'INSERT' THEN
        new_quantity := NEW.quantity_kg;
    ELSIF TG_OP = 'UPDATE' THEN
        old_quantity := OLD.quantity_kg;
        new_quantity := NEW.quantity_kg;
    ELSIF TG_OP = 'DELETE' THEN
        old_quantity := OLD.quantity_kg;
    END IF;
    
    -- Calculate stock change (negative means stock reduction)
    stock_change := old_quantity - new_quantity;
    
    -- Update inventory stock
    IF TG_OP = 'DELETE' THEN
        UPDATE inventory_stock 
        SET current_kg = current_kg + stock_change,
            updated_at = NOW()
        WHERE production_batch_id = OLD.production_batch_id;
    ELSE
        UPDATE inventory_stock 
        SET current_kg = current_kg + stock_change,
            updated_at = NOW()
        WHERE production_batch_id = NEW.production_batch_id;
    END IF;
    
    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.user_belongs_to_cooperative(coop_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.users 
        WHERE auth_user_id = auth.uid() 
        AND cooperative_id = coop_id
    );
END;
$function$
;

create or replace view "public"."v_plant_available_stock" as  SELECT ei.id AS exit_item_id,
    ei.production_batch_id,
    pb.batch_code AS field_batch_code,
    (((p.first_name)::text || ' '::text) || (p.last_name)::text) AS producer_name,
    cm.name AS module_name,
    eri.quantity_kg_received,
    COALESCE(sum(phi.quantity_kg), (0)::numeric) AS kg_used,
    (eri.quantity_kg_received - COALESCE(sum(phi.quantity_kg), (0)::numeric)) AS kg_available,
    qe.humidity_pct,
    qe.impurities_pct,
    qe.color,
    qe.sack_condition,
    qe.appearance,
    qe.approval_status,
    ei.cooperative_id
   FROM ((((((public.exit_items ei
     JOIN public.exit_reception_items eri ON ((eri.exit_item_id = ei.id)))
     JOIN public.quality_evaluations qe ON ((qe.exit_item_id = ei.id)))
     JOIN public.production_batches pb ON ((pb.id = ei.production_batch_id)))
     JOIN public.producers p ON ((p.id = pb.producer_id)))
     LEFT JOIN public.coop_modules cm ON ((cm.id = p.coop_module_id)))
     LEFT JOIN public.plant_homogenization_inputs phi ON ((phi.source_exit_item_id = ei.id)))
  GROUP BY ei.id, ei.production_batch_id, pb.batch_code, p.first_name, p.last_name, cm.name, eri.quantity_kg_received, qe.humidity_pct, qe.impurities_pct, qe.color, qe.sack_condition, qe.appearance, qe.approval_status, ei.cooperative_id;


create or replace view "public"."v_plant_order_summary" as  SELECT po.id AS order_id,
    po.order_code,
    po.market,
    po.total_kg AS planned_kg,
    po.status,
    po.planned_date,
    count(ppb.id) AS total_batches,
    count(
        CASE
            WHEN (ppb.status = 'procesado'::text) THEN 1
            ELSE NULL::integer
        END) AS processed_batches,
    COALESCE(sum(pbp.tamizada_kg), (0)::numeric) AS total_tamizada_kg,
    COALESCE(sum(pbp.descarte_kg), (0)::numeric) AS total_descarte_kg,
    COALESCE(sum(pbp.merma_kg), (0)::numeric) AS total_merma_kg,
    COALESCE(sum(phi_agg.total_input_kg), (0)::numeric) AS total_homogenizado_kg,
        CASE
            WHEN (COALESCE(sum(phi_agg.total_input_kg), (0)::numeric) > (0)::numeric) THEN round(((COALESCE(sum(pbp.tamizada_kg), (0)::numeric) / sum(phi_agg.total_input_kg)) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS rendimiento_pct,
    pc.container_number,
    pc.status AS container_status,
    pc.bill_of_lading,
    pc.destination_port,
    po.cooperative_id
   FROM ((((public.plant_orders po
     LEFT JOIN public.plant_production_batches ppb ON ((ppb.order_id = po.id)))
     LEFT JOIN public.plant_batch_processing pbp ON ((pbp.plant_batch_id = ppb.id)))
     LEFT JOIN ( SELECT plant_homogenization_inputs.plant_batch_id,
            sum(plant_homogenization_inputs.quantity_kg) AS total_input_kg
           FROM public.plant_homogenization_inputs
          GROUP BY plant_homogenization_inputs.plant_batch_id) phi_agg ON ((phi_agg.plant_batch_id = ppb.id)))
     LEFT JOIN public.plant_containers pc ON ((pc.id = po.container_id)))
  GROUP BY po.id, po.order_code, po.market, po.total_kg, po.status, po.planned_date, pc.container_number, pc.status, pc.bill_of_lading, pc.destination_port, po.cooperative_id;


CREATE OR REPLACE FUNCTION public.validate_certificate_exclusion_groups()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    exclusion_group_uuid UUID;
    conflict_count INTEGER;
    group_name VARCHAR(100);
BEGIN
    -- Get the exclusion group ID of the certificate being added
    SELECT bc.exclusion_group_id INTO exclusion_group_uuid
    FROM batch_certs bc
    WHERE bc.id = NEW.batch_cert_id;

    -- If certificate has no exclusion group, allow it
    IF exclusion_group_uuid IS NULL THEN
        RETURN NEW;
    END IF;

    -- Check if there are already certificates from the same exclusion group for this batch
    SELECT COUNT(*) INTO conflict_count
    FROM production_batch_certs pbc
    JOIN batch_certs bc ON pbc.batch_cert_id = bc.id
    WHERE pbc.production_batch_id = NEW.production_batch_id
      AND bc.exclusion_group_id = exclusion_group_uuid
      AND pbc.batch_cert_id != NEW.batch_cert_id; -- Exclude the current certificate (for updates)

    -- If there are conflicts, get group name for better error message
    IF conflict_count > 0 THEN
        SELECT ceg.display_name INTO group_name
        FROM certificate_exclusion_groups ceg
        WHERE ceg.id = exclusion_group_uuid;

        RAISE EXCEPTION 'Certificate exclusion group violation: Only one certificate from group "%" can be selected per batch', COALESCE(group_name, 'Unknown Group');
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_environment_inspection()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Ensure user belongs to the same cooperative
    IF NOT EXISTS (
        SELECT 1
        FROM users
        WHERE user_id = NEW.created_by
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'User must belong to the same cooperative';
    END IF;

    -- Ensure module belongs to the same cooperative
    IF NOT EXISTS (
        SELECT 1
        FROM coop_modules
        WHERE id = NEW.coop_module_id
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'Module must belong to the same cooperative';
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_equipment_maintenance_record()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Validate creator belongs to the same cooperative
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE user_id = NEW.created_by
    AND cooperative_id = NEW.cooperative_id
  ) THEN
    RAISE EXCEPTION 'El usuario creador no pertenece a la cooperativa especificada';
  END IF;

  -- Validate module belongs to the same cooperative
  IF NOT EXISTS (
    SELECT 1 FROM coop_modules
    WHERE id = NEW.coop_module_id
    AND cooperative_id = NEW.cooperative_id
  ) THEN
    RAISE EXCEPTION 'El módulo especificado no pertenece a la cooperativa';
  END IF;

  -- Validate non-empty text fields
  IF trim(NEW.equipment_name) = '' THEN
    RAISE EXCEPTION 'El nombre del equipo no puede estar vacío';
  END IF;

  IF trim(NEW.maintenance_cause) = '' THEN
    RAISE EXCEPTION 'La causa del mantenimiento no puede estar vacía';
  END IF;

  IF trim(NEW.responsible_person) = '' THEN
    RAISE EXCEPTION 'El responsable del mantenimiento no puede estar vacío';
  END IF;

  -- Validate materials_used if provided
  IF NEW.materials_used IS NOT NULL AND trim(NEW.materials_used) = '' THEN
    NEW.materials_used := NULL;  -- Convert empty string to NULL
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_exit_item()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
      available_stock DECIMAL(10,2);
      exit_coop_id UUID;
      batch_coop_id UUID;
  BEGIN
      SELECT cooperative_id INTO exit_coop_id
      FROM exit_registrations
      WHERE id = NEW.exit_registration_id;

      SELECT cooperative_id INTO batch_coop_id
      FROM production_batches
      WHERE id = NEW.production_batch_id;

      IF NEW.cooperative_id != exit_coop_id OR NEW.cooperative_id != batch_coop_id THEN
          RAISE EXCEPTION 'All records must belong to the same cooperative';
      END IF;

      SELECT available_kg INTO available_stock
      FROM inventory_stock
      WHERE production_batch_id = NEW.production_batch_id;

      IF available_stock IS NULL THEN
          RAISE EXCEPTION 'No stock record found for production batch';
      END IF;

      IF NEW.quantity_kg > available_stock THEN
          RAISE EXCEPTION 'Insufficient stock. Available: % kg, Requested: % kg', available_stock, NEW.quantity_kg;
      END IF;

      IF NOT NEW.is_autoconsumo THEN
          IF NEW.bags_count = 0 OR NEW.bags_count IS NULL THEN
              NEW.bags_count := ROUND(NEW.quantity_kg / 50.0, 2);
          END IF;

          IF NEW.bags_count * 50 < NEW.quantity_kg THEN
              RAISE EXCEPTION 'Bags count (%) insufficient for quantity (% kg). Need at least % bags',
                  NEW.bags_count, NEW.quantity_kg, ROUND(NEW.quantity_kg / 50.0, 2);
          END IF;
      ELSE
          NEW.bags_count := 0;
      END IF;

      RETURN NEW;
  END;
  $function$
;

CREATE OR REPLACE FUNCTION public.validate_exit_registration()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Ensure user belongs to the same cooperative
    IF NOT EXISTS (
        SELECT 1 
        FROM users 
        WHERE user_id = NEW.created_by 
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'User must belong to the same cooperative';
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_health_incident()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Ensure creator belongs to the same cooperative
    IF NOT EXISTS (
        SELECT 1 FROM users
        WHERE user_id = NEW.created_by
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'Creator must belong to the same cooperative';
    END IF;

    -- Ensure module belongs to the same cooperative
    IF NOT EXISTS (
        SELECT 1 FROM coop_modules
        WHERE id = NEW.coop_module_id
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'Module must belong to the same cooperative';
    END IF;

    -- If "other" action is selected, detail is required
    IF NEW.action_other = TRUE AND
       (NEW.other_action_detail IS NULL OR NEW.other_action_detail = '') THEN
        RAISE EXCEPTION 'Other action detail is required when "other" action is selected';
    END IF;

    -- At least one action must be selected
    IF NEW.action_rest = FALSE AND
       NEW.action_medical_attention = FALSE AND
       NEW.action_relocation = FALSE AND
       NEW.action_medication = FALSE AND
       NEW.action_other = FALSE THEN
        RAISE EXCEPTION 'At least one action must be selected';
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_homogenization_stock()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
    kg_received   NUMERIC;
    kg_already_used NUMERIC;
    kg_available  NUMERIC;
  BEGIN
    -- Kg realmente recibidos de este lote de origen
    SELECT COALESCE(quantity_kg_received, 0)
    INTO kg_received
    FROM exit_reception_items
    WHERE exit_item_id = NEW.source_exit_item_id
    LIMIT 1;

    -- Kg ya usados en OTROS lotes de planta (excluyendo el lote actual)
    SELECT COALESCE(SUM(quantity_kg), 0)
    INTO kg_already_used
    FROM plant_homogenization_inputs
    WHERE source_exit_item_id = NEW.source_exit_item_id
      AND plant_batch_id <> NEW.plant_batch_id;

    kg_available := kg_received - kg_already_used;

    IF NEW.quantity_kg > kg_available + 0.01 THEN
      RAISE EXCEPTION
        'El lote de origen no tiene suficiente cantidad disponible — disponible: % kg, solicitado: % kg.',
        ROUND(kg_available::numeric, 2),
        ROUND(NEW.quantity_kg::numeric, 2);
    END IF;

    RETURN NEW;
  END;
  $function$
;

CREATE OR REPLACE FUNCTION public.validate_processing_totals()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
    total_input NUMERIC;
  BEGIN
    -- Suma todos los kg del homogenizado para este lote
    SELECT COALESCE(SUM(quantity_kg), 0)
    INTO total_input
    FROM plant_homogenization_inputs
    WHERE plant_batch_id = NEW.plant_batch_id;

    IF total_input = 0 THEN
      RAISE EXCEPTION 'El lote no tiene homogenizado registrado';
    END IF;

    IF ABS((NEW.tamizada_kg + NEW.descarte_kg + NEW.merma_kg) - total_input) > 0.1 THEN
      RAISE EXCEPTION
        'La suma tamizada (%) + descarte (%) + merma (%) = % kg, pero el total homogenizado es % kg. Deben ser
  iguales.',
        NEW.tamizada_kg, NEW.descarte_kg, NEW.merma_kg,
        (NEW.tamizada_kg + NEW.descarte_kg + NEW.merma_kg),
        total_input;
    END IF;

    RETURN NEW;
  END;
  $function$
;

CREATE OR REPLACE FUNCTION public.validate_producer_module()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM public.coop_modules 
        WHERE id = NEW.coop_module_id 
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'Module must belong to the same cooperative as the producer';
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_product_return()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Validate creator belongs to the same cooperative
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE user_id = NEW.created_by
    AND cooperative_id = NEW.cooperative_id
  ) THEN
    RAISE EXCEPTION 'El usuario creador no pertenece a la cooperativa especificada';
  END IF;

  -- Validate production batch belongs to the same cooperative
  IF NOT EXISTS (
    SELECT 1 FROM production_batches
    WHERE id = NEW.production_batch_id
    AND cooperative_id = NEW.cooperative_id
  ) THEN
    RAISE EXCEPTION 'El lote de producción no pertenece a la cooperativa';
  END IF;

  -- Validate non-empty text fields
  IF trim(NEW.client_name) = '' THEN
    RAISE EXCEPTION 'El nombre del cliente no puede estar vacío';
  END IF;

  IF trim(NEW.return_reason) = '' THEN
    RAISE EXCEPTION 'La causa de devolución no puede estar vacía';
  END IF;

  -- Validate return date is not in the future
  IF NEW.return_date > CURRENT_DATE THEN
    RAISE EXCEPTION 'La fecha de devolución no puede ser futura';
  END IF;

  -- Validate observations if provided
  IF NEW.observations IS NOT NULL AND trim(NEW.observations) = '' THEN
    NEW.observations := NULL;  -- Convert empty string to NULL
  END IF;

  -- Validate quantity consistency (sacks -> kg conversion)
  -- If quantity_sacks is provided (> 0), quantity_kg should match (sacks * 50)
  IF NEW.quantity_sacks > 0 THEN
    DECLARE
      expected_kg NUMERIC := NEW.quantity_sacks * 50;
      tolerance NUMERIC := 0.01;  -- Allow small rounding differences
    BEGIN
      IF ABS(NEW.quantity_kg - expected_kg) > tolerance THEN
        RAISE WARNING 'Discrepancia entre kg (%) y bolsas (%): se esperaba % kg',
          NEW.quantity_kg, NEW.quantity_sacks, expected_kg;
      END IF;
    END;
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_production_batch_plot()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- If plot_id is provided, validate it belongs to the producer
    IF NEW.plot_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1
            FROM plots
            WHERE id = NEW.plot_id
            AND producer_id = NEW.producer_id
            AND is_active = true
        ) THEN
            RAISE EXCEPTION 'La parcela debe pertenecer al productor seleccionado';
        END IF;
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_stock_operation()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Ensure cooperative consistency
    IF NOT EXISTS (
        SELECT 1 
        FROM production_batches pb
        WHERE pb.id = NEW.production_batch_id 
        AND pb.cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'Production batch must belong to the same cooperative as stock record';
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_stowage_transport_inspection()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Ensure user belongs to the same cooperative
    IF NOT EXISTS (
        SELECT 1
        FROM users
        WHERE user_id = NEW.created_by
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'User must belong to the same cooperative';
    END IF;

    -- Ensure exit registration belongs to the same cooperative
    IF NOT EXISTS (
        SELECT 1
        FROM exit_registrations
        WHERE id = NEW.exit_registration_id
        AND cooperative_id = NEW.cooperative_id
    ) THEN
        RAISE EXCEPTION 'Exit registration must belong to the same cooperative';
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_worker_control()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Validate creator belongs to the same cooperative
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE user_id = NEW.created_by
    AND cooperative_id = NEW.cooperative_id
  ) THEN
    RAISE EXCEPTION 'El usuario creador no pertenece a la cooperativa especificada';
  END IF;

  -- Validate production batch belongs to the same cooperative
  IF NOT EXISTS (
    SELECT 1 FROM production_batches
    WHERE id = NEW.production_batch_id
    AND cooperative_id = NEW.cooperative_id
  ) THEN
    RAISE EXCEPTION 'El lote de producción no pertenece a la cooperativa';
  END IF;

  -- Validate non-empty text fields
  IF trim(NEW.worker_name) = '' THEN
    RAISE EXCEPTION 'El nombre del trabajador no puede estar vacío';
  END IF;

  -- Validate observations if provided
  IF NEW.observations IS NOT NULL AND trim(NEW.observations) = '' THEN
    NEW.observations := NULL;  -- Convert empty string to NULL
  END IF;

  RETURN NEW;
END;
$function$
;

grant delete on table "public"."batch_certs" to "anon";

grant insert on table "public"."batch_certs" to "anon";

grant references on table "public"."batch_certs" to "anon";

grant select on table "public"."batch_certs" to "anon";

grant trigger on table "public"."batch_certs" to "anon";

grant truncate on table "public"."batch_certs" to "anon";

grant update on table "public"."batch_certs" to "anon";

grant delete on table "public"."batch_certs" to "authenticated";

grant insert on table "public"."batch_certs" to "authenticated";

grant references on table "public"."batch_certs" to "authenticated";

grant select on table "public"."batch_certs" to "authenticated";

grant trigger on table "public"."batch_certs" to "authenticated";

grant truncate on table "public"."batch_certs" to "authenticated";

grant update on table "public"."batch_certs" to "authenticated";

grant delete on table "public"."batch_certs" to "service_role";

grant insert on table "public"."batch_certs" to "service_role";

grant references on table "public"."batch_certs" to "service_role";

grant select on table "public"."batch_certs" to "service_role";

grant trigger on table "public"."batch_certs" to "service_role";

grant truncate on table "public"."batch_certs" to "service_role";

grant update on table "public"."batch_certs" to "service_role";

grant delete on table "public"."batch_ph_controls" to "anon";

grant insert on table "public"."batch_ph_controls" to "anon";

grant references on table "public"."batch_ph_controls" to "anon";

grant select on table "public"."batch_ph_controls" to "anon";

grant trigger on table "public"."batch_ph_controls" to "anon";

grant truncate on table "public"."batch_ph_controls" to "anon";

grant update on table "public"."batch_ph_controls" to "anon";

grant delete on table "public"."batch_ph_controls" to "authenticated";

grant insert on table "public"."batch_ph_controls" to "authenticated";

grant references on table "public"."batch_ph_controls" to "authenticated";

grant select on table "public"."batch_ph_controls" to "authenticated";

grant trigger on table "public"."batch_ph_controls" to "authenticated";

grant truncate on table "public"."batch_ph_controls" to "authenticated";

grant update on table "public"."batch_ph_controls" to "authenticated";

grant delete on table "public"."batch_ph_controls" to "service_role";

grant insert on table "public"."batch_ph_controls" to "service_role";

grant references on table "public"."batch_ph_controls" to "service_role";

grant select on table "public"."batch_ph_controls" to "service_role";

grant trigger on table "public"."batch_ph_controls" to "service_role";

grant truncate on table "public"."batch_ph_controls" to "service_role";

grant update on table "public"."batch_ph_controls" to "service_role";

grant delete on table "public"."batch_temperatures" to "anon";

grant insert on table "public"."batch_temperatures" to "anon";

grant references on table "public"."batch_temperatures" to "anon";

grant select on table "public"."batch_temperatures" to "anon";

grant trigger on table "public"."batch_temperatures" to "anon";

grant truncate on table "public"."batch_temperatures" to "anon";

grant update on table "public"."batch_temperatures" to "anon";

grant delete on table "public"."batch_temperatures" to "authenticated";

grant insert on table "public"."batch_temperatures" to "authenticated";

grant references on table "public"."batch_temperatures" to "authenticated";

grant select on table "public"."batch_temperatures" to "authenticated";

grant trigger on table "public"."batch_temperatures" to "authenticated";

grant truncate on table "public"."batch_temperatures" to "authenticated";

grant update on table "public"."batch_temperatures" to "authenticated";

grant delete on table "public"."batch_temperatures" to "service_role";

grant insert on table "public"."batch_temperatures" to "service_role";

grant references on table "public"."batch_temperatures" to "service_role";

grant select on table "public"."batch_temperatures" to "service_role";

grant trigger on table "public"."batch_temperatures" to "service_role";

grant truncate on table "public"."batch_temperatures" to "service_role";

grant update on table "public"."batch_temperatures" to "service_role";

grant delete on table "public"."certificate_exclusion_groups" to "anon";

grant insert on table "public"."certificate_exclusion_groups" to "anon";

grant references on table "public"."certificate_exclusion_groups" to "anon";

grant select on table "public"."certificate_exclusion_groups" to "anon";

grant trigger on table "public"."certificate_exclusion_groups" to "anon";

grant truncate on table "public"."certificate_exclusion_groups" to "anon";

grant update on table "public"."certificate_exclusion_groups" to "anon";

grant delete on table "public"."certificate_exclusion_groups" to "authenticated";

grant insert on table "public"."certificate_exclusion_groups" to "authenticated";

grant references on table "public"."certificate_exclusion_groups" to "authenticated";

grant select on table "public"."certificate_exclusion_groups" to "authenticated";

grant trigger on table "public"."certificate_exclusion_groups" to "authenticated";

grant truncate on table "public"."certificate_exclusion_groups" to "authenticated";

grant update on table "public"."certificate_exclusion_groups" to "authenticated";

grant delete on table "public"."certificate_exclusion_groups" to "service_role";

grant insert on table "public"."certificate_exclusion_groups" to "service_role";

grant references on table "public"."certificate_exclusion_groups" to "service_role";

grant select on table "public"."certificate_exclusion_groups" to "service_role";

grant trigger on table "public"."certificate_exclusion_groups" to "service_role";

grant truncate on table "public"."certificate_exclusion_groups" to "service_role";

grant update on table "public"."certificate_exclusion_groups" to "service_role";

grant delete on table "public"."chlorine_residual_controls" to "anon";

grant insert on table "public"."chlorine_residual_controls" to "anon";

grant references on table "public"."chlorine_residual_controls" to "anon";

grant select on table "public"."chlorine_residual_controls" to "anon";

grant trigger on table "public"."chlorine_residual_controls" to "anon";

grant truncate on table "public"."chlorine_residual_controls" to "anon";

grant update on table "public"."chlorine_residual_controls" to "anon";

grant delete on table "public"."chlorine_residual_controls" to "authenticated";

grant insert on table "public"."chlorine_residual_controls" to "authenticated";

grant references on table "public"."chlorine_residual_controls" to "authenticated";

grant select on table "public"."chlorine_residual_controls" to "authenticated";

grant trigger on table "public"."chlorine_residual_controls" to "authenticated";

grant truncate on table "public"."chlorine_residual_controls" to "authenticated";

grant update on table "public"."chlorine_residual_controls" to "authenticated";

grant delete on table "public"."chlorine_residual_controls" to "service_role";

grant insert on table "public"."chlorine_residual_controls" to "service_role";

grant references on table "public"."chlorine_residual_controls" to "service_role";

grant select on table "public"."chlorine_residual_controls" to "service_role";

grant trigger on table "public"."chlorine_residual_controls" to "service_role";

grant truncate on table "public"."chlorine_residual_controls" to "service_role";

grant update on table "public"."chlorine_residual_controls" to "service_role";

grant delete on table "public"."cleaning_disinfection_items" to "anon";

grant insert on table "public"."cleaning_disinfection_items" to "anon";

grant references on table "public"."cleaning_disinfection_items" to "anon";

grant select on table "public"."cleaning_disinfection_items" to "anon";

grant trigger on table "public"."cleaning_disinfection_items" to "anon";

grant truncate on table "public"."cleaning_disinfection_items" to "anon";

grant update on table "public"."cleaning_disinfection_items" to "anon";

grant delete on table "public"."cleaning_disinfection_items" to "authenticated";

grant insert on table "public"."cleaning_disinfection_items" to "authenticated";

grant references on table "public"."cleaning_disinfection_items" to "authenticated";

grant select on table "public"."cleaning_disinfection_items" to "authenticated";

grant trigger on table "public"."cleaning_disinfection_items" to "authenticated";

grant truncate on table "public"."cleaning_disinfection_items" to "authenticated";

grant update on table "public"."cleaning_disinfection_items" to "authenticated";

grant delete on table "public"."cleaning_disinfection_items" to "service_role";

grant insert on table "public"."cleaning_disinfection_items" to "service_role";

grant references on table "public"."cleaning_disinfection_items" to "service_role";

grant select on table "public"."cleaning_disinfection_items" to "service_role";

grant trigger on table "public"."cleaning_disinfection_items" to "service_role";

grant truncate on table "public"."cleaning_disinfection_items" to "service_role";

grant update on table "public"."cleaning_disinfection_items" to "service_role";

grant delete on table "public"."cleaning_disinfections" to "anon";

grant insert on table "public"."cleaning_disinfections" to "anon";

grant references on table "public"."cleaning_disinfections" to "anon";

grant select on table "public"."cleaning_disinfections" to "anon";

grant trigger on table "public"."cleaning_disinfections" to "anon";

grant truncate on table "public"."cleaning_disinfections" to "anon";

grant update on table "public"."cleaning_disinfections" to "anon";

grant delete on table "public"."cleaning_disinfections" to "authenticated";

grant insert on table "public"."cleaning_disinfections" to "authenticated";

grant references on table "public"."cleaning_disinfections" to "authenticated";

grant select on table "public"."cleaning_disinfections" to "authenticated";

grant trigger on table "public"."cleaning_disinfections" to "authenticated";

grant truncate on table "public"."cleaning_disinfections" to "authenticated";

grant update on table "public"."cleaning_disinfections" to "authenticated";

grant delete on table "public"."cleaning_disinfections" to "service_role";

grant insert on table "public"."cleaning_disinfections" to "service_role";

grant references on table "public"."cleaning_disinfections" to "service_role";

grant select on table "public"."cleaning_disinfections" to "service_role";

grant trigger on table "public"."cleaning_disinfections" to "service_role";

grant truncate on table "public"."cleaning_disinfections" to "service_role";

grant update on table "public"."cleaning_disinfections" to "service_role";

grant delete on table "public"."coop_modules" to "anon";

grant insert on table "public"."coop_modules" to "anon";

grant references on table "public"."coop_modules" to "anon";

grant select on table "public"."coop_modules" to "anon";

grant trigger on table "public"."coop_modules" to "anon";

grant truncate on table "public"."coop_modules" to "anon";

grant update on table "public"."coop_modules" to "anon";

grant delete on table "public"."coop_modules" to "authenticated";

grant insert on table "public"."coop_modules" to "authenticated";

grant references on table "public"."coop_modules" to "authenticated";

grant select on table "public"."coop_modules" to "authenticated";

grant trigger on table "public"."coop_modules" to "authenticated";

grant truncate on table "public"."coop_modules" to "authenticated";

grant update on table "public"."coop_modules" to "authenticated";

grant delete on table "public"."coop_modules" to "service_role";

grant insert on table "public"."coop_modules" to "service_role";

grant references on table "public"."coop_modules" to "service_role";

grant select on table "public"."coop_modules" to "service_role";

grant trigger on table "public"."coop_modules" to "service_role";

grant truncate on table "public"."coop_modules" to "service_role";

grant update on table "public"."coop_modules" to "service_role";

grant delete on table "public"."cooperatives" to "anon";

grant insert on table "public"."cooperatives" to "anon";

grant references on table "public"."cooperatives" to "anon";

grant select on table "public"."cooperatives" to "anon";

grant trigger on table "public"."cooperatives" to "anon";

grant truncate on table "public"."cooperatives" to "anon";

grant update on table "public"."cooperatives" to "anon";

grant delete on table "public"."cooperatives" to "authenticated";

grant insert on table "public"."cooperatives" to "authenticated";

grant references on table "public"."cooperatives" to "authenticated";

grant select on table "public"."cooperatives" to "authenticated";

grant trigger on table "public"."cooperatives" to "authenticated";

grant truncate on table "public"."cooperatives" to "authenticated";

grant update on table "public"."cooperatives" to "authenticated";

grant delete on table "public"."cooperatives" to "service_role";

grant insert on table "public"."cooperatives" to "service_role";

grant references on table "public"."cooperatives" to "service_role";

grant select on table "public"."cooperatives" to "service_role";

grant trigger on table "public"."cooperatives" to "service_role";

grant truncate on table "public"."cooperatives" to "service_role";

grant update on table "public"."cooperatives" to "service_role";

grant delete on table "public"."environment_inspection_items" to "anon";

grant insert on table "public"."environment_inspection_items" to "anon";

grant references on table "public"."environment_inspection_items" to "anon";

grant select on table "public"."environment_inspection_items" to "anon";

grant trigger on table "public"."environment_inspection_items" to "anon";

grant truncate on table "public"."environment_inspection_items" to "anon";

grant update on table "public"."environment_inspection_items" to "anon";

grant delete on table "public"."environment_inspection_items" to "authenticated";

grant insert on table "public"."environment_inspection_items" to "authenticated";

grant references on table "public"."environment_inspection_items" to "authenticated";

grant select on table "public"."environment_inspection_items" to "authenticated";

grant trigger on table "public"."environment_inspection_items" to "authenticated";

grant truncate on table "public"."environment_inspection_items" to "authenticated";

grant update on table "public"."environment_inspection_items" to "authenticated";

grant delete on table "public"."environment_inspection_items" to "service_role";

grant insert on table "public"."environment_inspection_items" to "service_role";

grant references on table "public"."environment_inspection_items" to "service_role";

grant select on table "public"."environment_inspection_items" to "service_role";

grant trigger on table "public"."environment_inspection_items" to "service_role";

grant truncate on table "public"."environment_inspection_items" to "service_role";

grant update on table "public"."environment_inspection_items" to "service_role";

grant delete on table "public"."environment_inspections" to "anon";

grant insert on table "public"."environment_inspections" to "anon";

grant references on table "public"."environment_inspections" to "anon";

grant select on table "public"."environment_inspections" to "anon";

grant trigger on table "public"."environment_inspections" to "anon";

grant truncate on table "public"."environment_inspections" to "anon";

grant update on table "public"."environment_inspections" to "anon";

grant delete on table "public"."environment_inspections" to "authenticated";

grant insert on table "public"."environment_inspections" to "authenticated";

grant references on table "public"."environment_inspections" to "authenticated";

grant select on table "public"."environment_inspections" to "authenticated";

grant trigger on table "public"."environment_inspections" to "authenticated";

grant truncate on table "public"."environment_inspections" to "authenticated";

grant update on table "public"."environment_inspections" to "authenticated";

grant delete on table "public"."environment_inspections" to "service_role";

grant insert on table "public"."environment_inspections" to "service_role";

grant references on table "public"."environment_inspections" to "service_role";

grant select on table "public"."environment_inspections" to "service_role";

grant trigger on table "public"."environment_inspections" to "service_role";

grant truncate on table "public"."environment_inspections" to "service_role";

grant update on table "public"."environment_inspections" to "service_role";

grant delete on table "public"."equipment_maintenance_records" to "anon";

grant insert on table "public"."equipment_maintenance_records" to "anon";

grant references on table "public"."equipment_maintenance_records" to "anon";

grant select on table "public"."equipment_maintenance_records" to "anon";

grant trigger on table "public"."equipment_maintenance_records" to "anon";

grant truncate on table "public"."equipment_maintenance_records" to "anon";

grant update on table "public"."equipment_maintenance_records" to "anon";

grant delete on table "public"."equipment_maintenance_records" to "authenticated";

grant insert on table "public"."equipment_maintenance_records" to "authenticated";

grant references on table "public"."equipment_maintenance_records" to "authenticated";

grant select on table "public"."equipment_maintenance_records" to "authenticated";

grant trigger on table "public"."equipment_maintenance_records" to "authenticated";

grant truncate on table "public"."equipment_maintenance_records" to "authenticated";

grant update on table "public"."equipment_maintenance_records" to "authenticated";

grant delete on table "public"."equipment_maintenance_records" to "service_role";

grant insert on table "public"."equipment_maintenance_records" to "service_role";

grant references on table "public"."equipment_maintenance_records" to "service_role";

grant select on table "public"."equipment_maintenance_records" to "service_role";

grant trigger on table "public"."equipment_maintenance_records" to "service_role";

grant truncate on table "public"."equipment_maintenance_records" to "service_role";

grant update on table "public"."equipment_maintenance_records" to "service_role";

grant delete on table "public"."exit_items" to "anon";

grant insert on table "public"."exit_items" to "anon";

grant references on table "public"."exit_items" to "anon";

grant select on table "public"."exit_items" to "anon";

grant trigger on table "public"."exit_items" to "anon";

grant truncate on table "public"."exit_items" to "anon";

grant update on table "public"."exit_items" to "anon";

grant delete on table "public"."exit_items" to "authenticated";

grant insert on table "public"."exit_items" to "authenticated";

grant references on table "public"."exit_items" to "authenticated";

grant select on table "public"."exit_items" to "authenticated";

grant trigger on table "public"."exit_items" to "authenticated";

grant truncate on table "public"."exit_items" to "authenticated";

grant update on table "public"."exit_items" to "authenticated";

grant delete on table "public"."exit_items" to "service_role";

grant insert on table "public"."exit_items" to "service_role";

grant references on table "public"."exit_items" to "service_role";

grant select on table "public"."exit_items" to "service_role";

grant trigger on table "public"."exit_items" to "service_role";

grant truncate on table "public"."exit_items" to "service_role";

grant update on table "public"."exit_items" to "service_role";

grant delete on table "public"."exit_reception_items" to "anon";

grant insert on table "public"."exit_reception_items" to "anon";

grant references on table "public"."exit_reception_items" to "anon";

grant select on table "public"."exit_reception_items" to "anon";

grant trigger on table "public"."exit_reception_items" to "anon";

grant truncate on table "public"."exit_reception_items" to "anon";

grant update on table "public"."exit_reception_items" to "anon";

grant delete on table "public"."exit_reception_items" to "authenticated";

grant insert on table "public"."exit_reception_items" to "authenticated";

grant references on table "public"."exit_reception_items" to "authenticated";

grant select on table "public"."exit_reception_items" to "authenticated";

grant trigger on table "public"."exit_reception_items" to "authenticated";

grant truncate on table "public"."exit_reception_items" to "authenticated";

grant update on table "public"."exit_reception_items" to "authenticated";

grant delete on table "public"."exit_reception_items" to "service_role";

grant insert on table "public"."exit_reception_items" to "service_role";

grant references on table "public"."exit_reception_items" to "service_role";

grant select on table "public"."exit_reception_items" to "service_role";

grant trigger on table "public"."exit_reception_items" to "service_role";

grant truncate on table "public"."exit_reception_items" to "service_role";

grant update on table "public"."exit_reception_items" to "service_role";

grant delete on table "public"."exit_receptions" to "anon";

grant insert on table "public"."exit_receptions" to "anon";

grant references on table "public"."exit_receptions" to "anon";

grant select on table "public"."exit_receptions" to "anon";

grant trigger on table "public"."exit_receptions" to "anon";

grant truncate on table "public"."exit_receptions" to "anon";

grant update on table "public"."exit_receptions" to "anon";

grant delete on table "public"."exit_receptions" to "authenticated";

grant insert on table "public"."exit_receptions" to "authenticated";

grant references on table "public"."exit_receptions" to "authenticated";

grant select on table "public"."exit_receptions" to "authenticated";

grant trigger on table "public"."exit_receptions" to "authenticated";

grant truncate on table "public"."exit_receptions" to "authenticated";

grant update on table "public"."exit_receptions" to "authenticated";

grant delete on table "public"."exit_receptions" to "service_role";

grant insert on table "public"."exit_receptions" to "service_role";

grant references on table "public"."exit_receptions" to "service_role";

grant select on table "public"."exit_receptions" to "service_role";

grant trigger on table "public"."exit_receptions" to "service_role";

grant truncate on table "public"."exit_receptions" to "service_role";

grant update on table "public"."exit_receptions" to "service_role";

grant delete on table "public"."exit_registrations" to "anon";

grant insert on table "public"."exit_registrations" to "anon";

grant references on table "public"."exit_registrations" to "anon";

grant select on table "public"."exit_registrations" to "anon";

grant trigger on table "public"."exit_registrations" to "anon";

grant truncate on table "public"."exit_registrations" to "anon";

grant update on table "public"."exit_registrations" to "anon";

grant delete on table "public"."exit_registrations" to "authenticated";

grant insert on table "public"."exit_registrations" to "authenticated";

grant references on table "public"."exit_registrations" to "authenticated";

grant select on table "public"."exit_registrations" to "authenticated";

grant trigger on table "public"."exit_registrations" to "authenticated";

grant truncate on table "public"."exit_registrations" to "authenticated";

grant update on table "public"."exit_registrations" to "authenticated";

grant delete on table "public"."exit_registrations" to "service_role";

grant insert on table "public"."exit_registrations" to "service_role";

grant references on table "public"."exit_registrations" to "service_role";

grant select on table "public"."exit_registrations" to "service_role";

grant trigger on table "public"."exit_registrations" to "service_role";

grant truncate on table "public"."exit_registrations" to "service_role";

grant update on table "public"."exit_registrations" to "service_role";

grant delete on table "public"."form_configurations" to "anon";

grant insert on table "public"."form_configurations" to "anon";

grant references on table "public"."form_configurations" to "anon";

grant select on table "public"."form_configurations" to "anon";

grant trigger on table "public"."form_configurations" to "anon";

grant truncate on table "public"."form_configurations" to "anon";

grant update on table "public"."form_configurations" to "anon";

grant delete on table "public"."form_configurations" to "authenticated";

grant insert on table "public"."form_configurations" to "authenticated";

grant references on table "public"."form_configurations" to "authenticated";

grant select on table "public"."form_configurations" to "authenticated";

grant trigger on table "public"."form_configurations" to "authenticated";

grant truncate on table "public"."form_configurations" to "authenticated";

grant update on table "public"."form_configurations" to "authenticated";

grant delete on table "public"."form_configurations" to "service_role";

grant insert on table "public"."form_configurations" to "service_role";

grant references on table "public"."form_configurations" to "service_role";

grant select on table "public"."form_configurations" to "service_role";

grant trigger on table "public"."form_configurations" to "service_role";

grant truncate on table "public"."form_configurations" to "service_role";

grant update on table "public"."form_configurations" to "service_role";

grant delete on table "public"."formatos_control_cloro" to "anon";

grant insert on table "public"."formatos_control_cloro" to "anon";

grant references on table "public"."formatos_control_cloro" to "anon";

grant select on table "public"."formatos_control_cloro" to "anon";

grant trigger on table "public"."formatos_control_cloro" to "anon";

grant truncate on table "public"."formatos_control_cloro" to "anon";

grant update on table "public"."formatos_control_cloro" to "anon";

grant delete on table "public"."formatos_control_cloro" to "authenticated";

grant insert on table "public"."formatos_control_cloro" to "authenticated";

grant references on table "public"."formatos_control_cloro" to "authenticated";

grant select on table "public"."formatos_control_cloro" to "authenticated";

grant trigger on table "public"."formatos_control_cloro" to "authenticated";

grant truncate on table "public"."formatos_control_cloro" to "authenticated";

grant update on table "public"."formatos_control_cloro" to "authenticated";

grant delete on table "public"."formatos_control_cloro" to "service_role";

grant insert on table "public"."formatos_control_cloro" to "service_role";

grant references on table "public"."formatos_control_cloro" to "service_role";

grant select on table "public"."formatos_control_cloro" to "service_role";

grant trigger on table "public"."formatos_control_cloro" to "service_role";

grant truncate on table "public"."formatos_control_cloro" to "service_role";

grant update on table "public"."formatos_control_cloro" to "service_role";

grant delete on table "public"."formatos_control_mp_ph" to "anon";

grant insert on table "public"."formatos_control_mp_ph" to "anon";

grant references on table "public"."formatos_control_mp_ph" to "anon";

grant select on table "public"."formatos_control_mp_ph" to "anon";

grant trigger on table "public"."formatos_control_mp_ph" to "anon";

grant truncate on table "public"."formatos_control_mp_ph" to "anon";

grant update on table "public"."formatos_control_mp_ph" to "anon";

grant delete on table "public"."formatos_control_mp_ph" to "authenticated";

grant insert on table "public"."formatos_control_mp_ph" to "authenticated";

grant references on table "public"."formatos_control_mp_ph" to "authenticated";

grant select on table "public"."formatos_control_mp_ph" to "authenticated";

grant trigger on table "public"."formatos_control_mp_ph" to "authenticated";

grant truncate on table "public"."formatos_control_mp_ph" to "authenticated";

grant update on table "public"."formatos_control_mp_ph" to "authenticated";

grant delete on table "public"."formatos_control_mp_ph" to "service_role";

grant insert on table "public"."formatos_control_mp_ph" to "service_role";

grant references on table "public"."formatos_control_mp_ph" to "service_role";

grant select on table "public"."formatos_control_mp_ph" to "service_role";

grant trigger on table "public"."formatos_control_mp_ph" to "service_role";

grant truncate on table "public"."formatos_control_mp_ph" to "service_role";

grant update on table "public"."formatos_control_mp_ph" to "service_role";

grant delete on table "public"."formatos_control_mp_ph_lotes" to "anon";

grant insert on table "public"."formatos_control_mp_ph_lotes" to "anon";

grant references on table "public"."formatos_control_mp_ph_lotes" to "anon";

grant select on table "public"."formatos_control_mp_ph_lotes" to "anon";

grant trigger on table "public"."formatos_control_mp_ph_lotes" to "anon";

grant truncate on table "public"."formatos_control_mp_ph_lotes" to "anon";

grant update on table "public"."formatos_control_mp_ph_lotes" to "anon";

grant delete on table "public"."formatos_control_mp_ph_lotes" to "authenticated";

grant insert on table "public"."formatos_control_mp_ph_lotes" to "authenticated";

grant references on table "public"."formatos_control_mp_ph_lotes" to "authenticated";

grant select on table "public"."formatos_control_mp_ph_lotes" to "authenticated";

grant trigger on table "public"."formatos_control_mp_ph_lotes" to "authenticated";

grant truncate on table "public"."formatos_control_mp_ph_lotes" to "authenticated";

grant update on table "public"."formatos_control_mp_ph_lotes" to "authenticated";

grant delete on table "public"."formatos_control_mp_ph_lotes" to "service_role";

grant insert on table "public"."formatos_control_mp_ph_lotes" to "service_role";

grant references on table "public"."formatos_control_mp_ph_lotes" to "service_role";

grant select on table "public"."formatos_control_mp_ph_lotes" to "service_role";

grant trigger on table "public"."formatos_control_mp_ph_lotes" to "service_role";

grant truncate on table "public"."formatos_control_mp_ph_lotes" to "service_role";

grant update on table "public"."formatos_control_mp_ph_lotes" to "service_role";

grant delete on table "public"."formatos_control_personal" to "anon";

grant insert on table "public"."formatos_control_personal" to "anon";

grant references on table "public"."formatos_control_personal" to "anon";

grant select on table "public"."formatos_control_personal" to "anon";

grant trigger on table "public"."formatos_control_personal" to "anon";

grant truncate on table "public"."formatos_control_personal" to "anon";

grant update on table "public"."formatos_control_personal" to "anon";

grant delete on table "public"."formatos_control_personal" to "authenticated";

grant insert on table "public"."formatos_control_personal" to "authenticated";

grant references on table "public"."formatos_control_personal" to "authenticated";

grant select on table "public"."formatos_control_personal" to "authenticated";

grant trigger on table "public"."formatos_control_personal" to "authenticated";

grant truncate on table "public"."formatos_control_personal" to "authenticated";

grant update on table "public"."formatos_control_personal" to "authenticated";

grant delete on table "public"."formatos_control_personal" to "service_role";

grant insert on table "public"."formatos_control_personal" to "service_role";

grant references on table "public"."formatos_control_personal" to "service_role";

grant select on table "public"."formatos_control_personal" to "service_role";

grant trigger on table "public"."formatos_control_personal" to "service_role";

grant truncate on table "public"."formatos_control_personal" to "service_role";

grant update on table "public"."formatos_control_personal" to "service_role";

grant delete on table "public"."formatos_control_plagas" to "anon";

grant insert on table "public"."formatos_control_plagas" to "anon";

grant references on table "public"."formatos_control_plagas" to "anon";

grant select on table "public"."formatos_control_plagas" to "anon";

grant trigger on table "public"."formatos_control_plagas" to "anon";

grant truncate on table "public"."formatos_control_plagas" to "anon";

grant update on table "public"."formatos_control_plagas" to "anon";

grant delete on table "public"."formatos_control_plagas" to "authenticated";

grant insert on table "public"."formatos_control_plagas" to "authenticated";

grant references on table "public"."formatos_control_plagas" to "authenticated";

grant select on table "public"."formatos_control_plagas" to "authenticated";

grant trigger on table "public"."formatos_control_plagas" to "authenticated";

grant truncate on table "public"."formatos_control_plagas" to "authenticated";

grant update on table "public"."formatos_control_plagas" to "authenticated";

grant delete on table "public"."formatos_control_plagas" to "service_role";

grant insert on table "public"."formatos_control_plagas" to "service_role";

grant references on table "public"."formatos_control_plagas" to "service_role";

grant select on table "public"."formatos_control_plagas" to "service_role";

grant trigger on table "public"."formatos_control_plagas" to "service_role";

grant truncate on table "public"."formatos_control_plagas" to "service_role";

grant update on table "public"."formatos_control_plagas" to "service_role";

grant delete on table "public"."formatos_inspeccion_ambientes" to "anon";

grant insert on table "public"."formatos_inspeccion_ambientes" to "anon";

grant references on table "public"."formatos_inspeccion_ambientes" to "anon";

grant select on table "public"."formatos_inspeccion_ambientes" to "anon";

grant trigger on table "public"."formatos_inspeccion_ambientes" to "anon";

grant truncate on table "public"."formatos_inspeccion_ambientes" to "anon";

grant update on table "public"."formatos_inspeccion_ambientes" to "anon";

grant delete on table "public"."formatos_inspeccion_ambientes" to "authenticated";

grant insert on table "public"."formatos_inspeccion_ambientes" to "authenticated";

grant references on table "public"."formatos_inspeccion_ambientes" to "authenticated";

grant select on table "public"."formatos_inspeccion_ambientes" to "authenticated";

grant trigger on table "public"."formatos_inspeccion_ambientes" to "authenticated";

grant truncate on table "public"."formatos_inspeccion_ambientes" to "authenticated";

grant update on table "public"."formatos_inspeccion_ambientes" to "authenticated";

grant delete on table "public"."formatos_inspeccion_ambientes" to "service_role";

grant insert on table "public"."formatos_inspeccion_ambientes" to "service_role";

grant references on table "public"."formatos_inspeccion_ambientes" to "service_role";

grant select on table "public"."formatos_inspeccion_ambientes" to "service_role";

grant trigger on table "public"."formatos_inspeccion_ambientes" to "service_role";

grant truncate on table "public"."formatos_inspeccion_ambientes" to "service_role";

grant update on table "public"."formatos_inspeccion_ambientes" to "service_role";

grant delete on table "public"."formatos_limpieza_desinfeccion" to "anon";

grant insert on table "public"."formatos_limpieza_desinfeccion" to "anon";

grant references on table "public"."formatos_limpieza_desinfeccion" to "anon";

grant select on table "public"."formatos_limpieza_desinfeccion" to "anon";

grant trigger on table "public"."formatos_limpieza_desinfeccion" to "anon";

grant truncate on table "public"."formatos_limpieza_desinfeccion" to "anon";

grant update on table "public"."formatos_limpieza_desinfeccion" to "anon";

grant delete on table "public"."formatos_limpieza_desinfeccion" to "authenticated";

grant insert on table "public"."formatos_limpieza_desinfeccion" to "authenticated";

grant references on table "public"."formatos_limpieza_desinfeccion" to "authenticated";

grant select on table "public"."formatos_limpieza_desinfeccion" to "authenticated";

grant trigger on table "public"."formatos_limpieza_desinfeccion" to "authenticated";

grant truncate on table "public"."formatos_limpieza_desinfeccion" to "authenticated";

grant update on table "public"."formatos_limpieza_desinfeccion" to "authenticated";

grant delete on table "public"."formatos_limpieza_desinfeccion" to "service_role";

grant insert on table "public"."formatos_limpieza_desinfeccion" to "service_role";

grant references on table "public"."formatos_limpieza_desinfeccion" to "service_role";

grant select on table "public"."formatos_limpieza_desinfeccion" to "service_role";

grant trigger on table "public"."formatos_limpieza_desinfeccion" to "service_role";

grant truncate on table "public"."formatos_limpieza_desinfeccion" to "service_role";

grant update on table "public"."formatos_limpieza_desinfeccion" to "service_role";

grant delete on table "public"."formatos_mantenimiento_equipos" to "anon";

grant insert on table "public"."formatos_mantenimiento_equipos" to "anon";

grant references on table "public"."formatos_mantenimiento_equipos" to "anon";

grant select on table "public"."formatos_mantenimiento_equipos" to "anon";

grant trigger on table "public"."formatos_mantenimiento_equipos" to "anon";

grant truncate on table "public"."formatos_mantenimiento_equipos" to "anon";

grant update on table "public"."formatos_mantenimiento_equipos" to "anon";

grant delete on table "public"."formatos_mantenimiento_equipos" to "authenticated";

grant insert on table "public"."formatos_mantenimiento_equipos" to "authenticated";

grant references on table "public"."formatos_mantenimiento_equipos" to "authenticated";

grant select on table "public"."formatos_mantenimiento_equipos" to "authenticated";

grant trigger on table "public"."formatos_mantenimiento_equipos" to "authenticated";

grant truncate on table "public"."formatos_mantenimiento_equipos" to "authenticated";

grant update on table "public"."formatos_mantenimiento_equipos" to "authenticated";

grant delete on table "public"."formatos_mantenimiento_equipos" to "service_role";

grant insert on table "public"."formatos_mantenimiento_equipos" to "service_role";

grant references on table "public"."formatos_mantenimiento_equipos" to "service_role";

grant select on table "public"."formatos_mantenimiento_equipos" to "service_role";

grant trigger on table "public"."formatos_mantenimiento_equipos" to "service_role";

grant truncate on table "public"."formatos_mantenimiento_equipos" to "service_role";

grant update on table "public"."formatos_mantenimiento_equipos" to "service_role";

grant delete on table "public"."formatos_seguimiento_salud" to "anon";

grant insert on table "public"."formatos_seguimiento_salud" to "anon";

grant references on table "public"."formatos_seguimiento_salud" to "anon";

grant select on table "public"."formatos_seguimiento_salud" to "anon";

grant trigger on table "public"."formatos_seguimiento_salud" to "anon";

grant truncate on table "public"."formatos_seguimiento_salud" to "anon";

grant update on table "public"."formatos_seguimiento_salud" to "anon";

grant delete on table "public"."formatos_seguimiento_salud" to "authenticated";

grant insert on table "public"."formatos_seguimiento_salud" to "authenticated";

grant references on table "public"."formatos_seguimiento_salud" to "authenticated";

grant select on table "public"."formatos_seguimiento_salud" to "authenticated";

grant trigger on table "public"."formatos_seguimiento_salud" to "authenticated";

grant truncate on table "public"."formatos_seguimiento_salud" to "authenticated";

grant update on table "public"."formatos_seguimiento_salud" to "authenticated";

grant delete on table "public"."formatos_seguimiento_salud" to "service_role";

grant insert on table "public"."formatos_seguimiento_salud" to "service_role";

grant references on table "public"."formatos_seguimiento_salud" to "service_role";

grant select on table "public"."formatos_seguimiento_salud" to "service_role";

grant trigger on table "public"."formatos_seguimiento_salud" to "service_role";

grant truncate on table "public"."formatos_seguimiento_salud" to "service_role";

grant update on table "public"."formatos_seguimiento_salud" to "service_role";

grant delete on table "public"."health_incidents" to "anon";

grant insert on table "public"."health_incidents" to "anon";

grant references on table "public"."health_incidents" to "anon";

grant select on table "public"."health_incidents" to "anon";

grant trigger on table "public"."health_incidents" to "anon";

grant truncate on table "public"."health_incidents" to "anon";

grant update on table "public"."health_incidents" to "anon";

grant delete on table "public"."health_incidents" to "authenticated";

grant insert on table "public"."health_incidents" to "authenticated";

grant references on table "public"."health_incidents" to "authenticated";

grant select on table "public"."health_incidents" to "authenticated";

grant trigger on table "public"."health_incidents" to "authenticated";

grant truncate on table "public"."health_incidents" to "authenticated";

grant update on table "public"."health_incidents" to "authenticated";

grant delete on table "public"."health_incidents" to "service_role";

grant insert on table "public"."health_incidents" to "service_role";

grant references on table "public"."health_incidents" to "service_role";

grant select on table "public"."health_incidents" to "service_role";

grant trigger on table "public"."health_incidents" to "service_role";

grant truncate on table "public"."health_incidents" to "service_role";

grant update on table "public"."health_incidents" to "service_role";

grant delete on table "public"."inventory_stock" to "anon";

grant insert on table "public"."inventory_stock" to "anon";

grant references on table "public"."inventory_stock" to "anon";

grant select on table "public"."inventory_stock" to "anon";

grant trigger on table "public"."inventory_stock" to "anon";

grant truncate on table "public"."inventory_stock" to "anon";

grant update on table "public"."inventory_stock" to "anon";

grant delete on table "public"."inventory_stock" to "authenticated";

grant insert on table "public"."inventory_stock" to "authenticated";

grant references on table "public"."inventory_stock" to "authenticated";

grant select on table "public"."inventory_stock" to "authenticated";

grant trigger on table "public"."inventory_stock" to "authenticated";

grant truncate on table "public"."inventory_stock" to "authenticated";

grant update on table "public"."inventory_stock" to "authenticated";

grant delete on table "public"."inventory_stock" to "service_role";

grant insert on table "public"."inventory_stock" to "service_role";

grant references on table "public"."inventory_stock" to "service_role";

grant select on table "public"."inventory_stock" to "service_role";

grant trigger on table "public"."inventory_stock" to "service_role";

grant truncate on table "public"."inventory_stock" to "service_role";

grant update on table "public"."inventory_stock" to "service_role";

grant delete on table "public"."pest_control_bait_records" to "anon";

grant insert on table "public"."pest_control_bait_records" to "anon";

grant references on table "public"."pest_control_bait_records" to "anon";

grant select on table "public"."pest_control_bait_records" to "anon";

grant trigger on table "public"."pest_control_bait_records" to "anon";

grant truncate on table "public"."pest_control_bait_records" to "anon";

grant update on table "public"."pest_control_bait_records" to "anon";

grant delete on table "public"."pest_control_bait_records" to "authenticated";

grant insert on table "public"."pest_control_bait_records" to "authenticated";

grant references on table "public"."pest_control_bait_records" to "authenticated";

grant select on table "public"."pest_control_bait_records" to "authenticated";

grant trigger on table "public"."pest_control_bait_records" to "authenticated";

-- Grants de funciones helper (no capturados por db diff)
grant execute on function public.auth_cooperative_id() to anon, authenticated, service_role;
grant execute on function public.is_service_role() to anon, authenticated, service_role;

-- Permisos para el custom JWT hook (supabase_auth_admin invoca el hook)
grant usage on schema public to supabase_auth_admin;
grant execute on function public.custom_access_token_hook(jsonb) to supabase_auth_admin;
revoke execute on function public.custom_access_token_hook(jsonb) from authenticated, anon, public;

grant truncate on table "public"."pest_control_bait_records" to "authenticated";

grant update on table "public"."pest_control_bait_records" to "authenticated";

grant delete on table "public"."pest_control_bait_records" to "service_role";

grant insert on table "public"."pest_control_bait_records" to "service_role";

grant references on table "public"."pest_control_bait_records" to "service_role";

grant select on table "public"."pest_control_bait_records" to "service_role";

grant trigger on table "public"."pest_control_bait_records" to "service_role";

grant truncate on table "public"."pest_control_bait_records" to "service_role";

grant update on table "public"."pest_control_bait_records" to "service_role";

grant delete on table "public"."pest_control_insect_records" to "anon";

grant insert on table "public"."pest_control_insect_records" to "anon";

grant references on table "public"."pest_control_insect_records" to "anon";

grant select on table "public"."pest_control_insect_records" to "anon";

grant trigger on table "public"."pest_control_insect_records" to "anon";

grant truncate on table "public"."pest_control_insect_records" to "anon";

grant update on table "public"."pest_control_insect_records" to "anon";

grant delete on table "public"."pest_control_insect_records" to "authenticated";

grant insert on table "public"."pest_control_insect_records" to "authenticated";

grant references on table "public"."pest_control_insect_records" to "authenticated";

grant select on table "public"."pest_control_insect_records" to "authenticated";

grant trigger on table "public"."pest_control_insect_records" to "authenticated";

grant truncate on table "public"."pest_control_insect_records" to "authenticated";

grant update on table "public"."pest_control_insect_records" to "authenticated";

grant delete on table "public"."pest_control_insect_records" to "service_role";

grant insert on table "public"."pest_control_insect_records" to "service_role";

grant references on table "public"."pest_control_insect_records" to "service_role";

grant select on table "public"."pest_control_insect_records" to "service_role";

grant trigger on table "public"."pest_control_insect_records" to "service_role";

grant truncate on table "public"."pest_control_insect_records" to "service_role";

grant update on table "public"."pest_control_insect_records" to "service_role";

grant delete on table "public"."pest_controls" to "anon";

grant insert on table "public"."pest_controls" to "anon";

grant references on table "public"."pest_controls" to "anon";

grant select on table "public"."pest_controls" to "anon";

grant trigger on table "public"."pest_controls" to "anon";

grant truncate on table "public"."pest_controls" to "anon";

grant update on table "public"."pest_controls" to "anon";

grant delete on table "public"."pest_controls" to "authenticated";

grant insert on table "public"."pest_controls" to "authenticated";

grant references on table "public"."pest_controls" to "authenticated";

grant select on table "public"."pest_controls" to "authenticated";

grant trigger on table "public"."pest_controls" to "authenticated";

grant truncate on table "public"."pest_controls" to "authenticated";

grant update on table "public"."pest_controls" to "authenticated";

grant delete on table "public"."pest_controls" to "service_role";

grant insert on table "public"."pest_controls" to "service_role";

grant references on table "public"."pest_controls" to "service_role";

grant select on table "public"."pest_controls" to "service_role";

grant trigger on table "public"."pest_controls" to "service_role";

grant truncate on table "public"."pest_controls" to "service_role";

grant update on table "public"."pest_controls" to "service_role";

grant delete on table "public"."plant_batch_processing" to "anon";

grant insert on table "public"."plant_batch_processing" to "anon";

grant references on table "public"."plant_batch_processing" to "anon";

grant select on table "public"."plant_batch_processing" to "anon";

grant trigger on table "public"."plant_batch_processing" to "anon";

grant truncate on table "public"."plant_batch_processing" to "anon";

grant update on table "public"."plant_batch_processing" to "anon";

grant delete on table "public"."plant_batch_processing" to "authenticated";

grant insert on table "public"."plant_batch_processing" to "authenticated";

grant references on table "public"."plant_batch_processing" to "authenticated";

grant select on table "public"."plant_batch_processing" to "authenticated";

grant trigger on table "public"."plant_batch_processing" to "authenticated";

grant truncate on table "public"."plant_batch_processing" to "authenticated";

grant update on table "public"."plant_batch_processing" to "authenticated";

grant delete on table "public"."plant_batch_processing" to "service_role";

grant insert on table "public"."plant_batch_processing" to "service_role";

grant references on table "public"."plant_batch_processing" to "service_role";

grant select on table "public"."plant_batch_processing" to "service_role";

grant trigger on table "public"."plant_batch_processing" to "service_role";

grant truncate on table "public"."plant_batch_processing" to "service_role";

grant update on table "public"."plant_batch_processing" to "service_role";

grant delete on table "public"."plant_checklists" to "anon";

grant insert on table "public"."plant_checklists" to "anon";

grant references on table "public"."plant_checklists" to "anon";

grant select on table "public"."plant_checklists" to "anon";

grant trigger on table "public"."plant_checklists" to "anon";

grant truncate on table "public"."plant_checklists" to "anon";

grant update on table "public"."plant_checklists" to "anon";

grant delete on table "public"."plant_checklists" to "authenticated";

grant insert on table "public"."plant_checklists" to "authenticated";

grant references on table "public"."plant_checklists" to "authenticated";

grant select on table "public"."plant_checklists" to "authenticated";

grant trigger on table "public"."plant_checklists" to "authenticated";

grant truncate on table "public"."plant_checklists" to "authenticated";

grant update on table "public"."plant_checklists" to "authenticated";

grant delete on table "public"."plant_checklists" to "service_role";

grant insert on table "public"."plant_checklists" to "service_role";

grant references on table "public"."plant_checklists" to "service_role";

grant select on table "public"."plant_checklists" to "service_role";

grant trigger on table "public"."plant_checklists" to "service_role";

grant truncate on table "public"."plant_checklists" to "service_role";

grant update on table "public"."plant_checklists" to "service_role";

grant delete on table "public"."plant_containers" to "anon";

grant insert on table "public"."plant_containers" to "anon";

grant references on table "public"."plant_containers" to "anon";

grant select on table "public"."plant_containers" to "anon";

grant trigger on table "public"."plant_containers" to "anon";

grant truncate on table "public"."plant_containers" to "anon";

grant update on table "public"."plant_containers" to "anon";

grant delete on table "public"."plant_containers" to "authenticated";

grant insert on table "public"."plant_containers" to "authenticated";

grant references on table "public"."plant_containers" to "authenticated";

grant select on table "public"."plant_containers" to "authenticated";

grant trigger on table "public"."plant_containers" to "authenticated";

grant truncate on table "public"."plant_containers" to "authenticated";

grant update on table "public"."plant_containers" to "authenticated";

grant delete on table "public"."plant_containers" to "service_role";

grant insert on table "public"."plant_containers" to "service_role";

grant references on table "public"."plant_containers" to "service_role";

grant select on table "public"."plant_containers" to "service_role";

grant trigger on table "public"."plant_containers" to "service_role";

grant truncate on table "public"."plant_containers" to "service_role";

grant update on table "public"."plant_containers" to "service_role";

grant delete on table "public"."plant_dispatches" to "anon";

grant insert on table "public"."plant_dispatches" to "anon";

grant references on table "public"."plant_dispatches" to "anon";

grant select on table "public"."plant_dispatches" to "anon";

grant trigger on table "public"."plant_dispatches" to "anon";

grant truncate on table "public"."plant_dispatches" to "anon";

grant update on table "public"."plant_dispatches" to "anon";

grant delete on table "public"."plant_dispatches" to "authenticated";

grant insert on table "public"."plant_dispatches" to "authenticated";

grant references on table "public"."plant_dispatches" to "authenticated";

grant select on table "public"."plant_dispatches" to "authenticated";

grant trigger on table "public"."plant_dispatches" to "authenticated";

grant truncate on table "public"."plant_dispatches" to "authenticated";

grant update on table "public"."plant_dispatches" to "authenticated";

grant delete on table "public"."plant_dispatches" to "service_role";

grant insert on table "public"."plant_dispatches" to "service_role";

grant references on table "public"."plant_dispatches" to "service_role";

grant select on table "public"."plant_dispatches" to "service_role";

grant trigger on table "public"."plant_dispatches" to "service_role";

grant truncate on table "public"."plant_dispatches" to "service_role";

grant update on table "public"."plant_dispatches" to "service_role";

grant delete on table "public"."plant_homogenization_inputs" to "anon";

grant insert on table "public"."plant_homogenization_inputs" to "anon";

grant references on table "public"."plant_homogenization_inputs" to "anon";

grant select on table "public"."plant_homogenization_inputs" to "anon";

grant trigger on table "public"."plant_homogenization_inputs" to "anon";

grant truncate on table "public"."plant_homogenization_inputs" to "anon";

grant update on table "public"."plant_homogenization_inputs" to "anon";

grant delete on table "public"."plant_homogenization_inputs" to "authenticated";

grant insert on table "public"."plant_homogenization_inputs" to "authenticated";

grant references on table "public"."plant_homogenization_inputs" to "authenticated";

grant select on table "public"."plant_homogenization_inputs" to "authenticated";

grant trigger on table "public"."plant_homogenization_inputs" to "authenticated";

grant truncate on table "public"."plant_homogenization_inputs" to "authenticated";

grant update on table "public"."plant_homogenization_inputs" to "authenticated";

grant delete on table "public"."plant_homogenization_inputs" to "service_role";

grant insert on table "public"."plant_homogenization_inputs" to "service_role";

grant references on table "public"."plant_homogenization_inputs" to "service_role";

grant select on table "public"."plant_homogenization_inputs" to "service_role";

grant trigger on table "public"."plant_homogenization_inputs" to "service_role";

grant truncate on table "public"."plant_homogenization_inputs" to "service_role";

grant update on table "public"."plant_homogenization_inputs" to "service_role";

grant delete on table "public"."plant_hygiene_areas" to "anon";

grant insert on table "public"."plant_hygiene_areas" to "anon";

grant references on table "public"."plant_hygiene_areas" to "anon";

grant select on table "public"."plant_hygiene_areas" to "anon";

grant trigger on table "public"."plant_hygiene_areas" to "anon";

grant truncate on table "public"."plant_hygiene_areas" to "anon";

grant update on table "public"."plant_hygiene_areas" to "anon";

grant delete on table "public"."plant_hygiene_areas" to "authenticated";

grant insert on table "public"."plant_hygiene_areas" to "authenticated";

grant references on table "public"."plant_hygiene_areas" to "authenticated";

grant select on table "public"."plant_hygiene_areas" to "authenticated";

grant trigger on table "public"."plant_hygiene_areas" to "authenticated";

grant truncate on table "public"."plant_hygiene_areas" to "authenticated";

grant update on table "public"."plant_hygiene_areas" to "authenticated";

grant delete on table "public"."plant_hygiene_areas" to "service_role";

grant insert on table "public"."plant_hygiene_areas" to "service_role";

grant references on table "public"."plant_hygiene_areas" to "service_role";

grant select on table "public"."plant_hygiene_areas" to "service_role";

grant trigger on table "public"."plant_hygiene_areas" to "service_role";

grant truncate on table "public"."plant_hygiene_areas" to "service_role";

grant update on table "public"."plant_hygiene_areas" to "service_role";

grant delete on table "public"."plant_hygiene_worker_criteria" to "anon";

grant insert on table "public"."plant_hygiene_worker_criteria" to "anon";

grant references on table "public"."plant_hygiene_worker_criteria" to "anon";

grant select on table "public"."plant_hygiene_worker_criteria" to "anon";

grant trigger on table "public"."plant_hygiene_worker_criteria" to "anon";

grant truncate on table "public"."plant_hygiene_worker_criteria" to "anon";

grant update on table "public"."plant_hygiene_worker_criteria" to "anon";

grant delete on table "public"."plant_hygiene_worker_criteria" to "authenticated";

grant insert on table "public"."plant_hygiene_worker_criteria" to "authenticated";

grant references on table "public"."plant_hygiene_worker_criteria" to "authenticated";

grant select on table "public"."plant_hygiene_worker_criteria" to "authenticated";

grant trigger on table "public"."plant_hygiene_worker_criteria" to "authenticated";

grant truncate on table "public"."plant_hygiene_worker_criteria" to "authenticated";

grant update on table "public"."plant_hygiene_worker_criteria" to "authenticated";

grant delete on table "public"."plant_hygiene_worker_criteria" to "service_role";

grant insert on table "public"."plant_hygiene_worker_criteria" to "service_role";

grant references on table "public"."plant_hygiene_worker_criteria" to "service_role";

grant select on table "public"."plant_hygiene_worker_criteria" to "service_role";

grant trigger on table "public"."plant_hygiene_worker_criteria" to "service_role";

grant truncate on table "public"."plant_hygiene_worker_criteria" to "service_role";

grant update on table "public"."plant_hygiene_worker_criteria" to "service_role";

grant delete on table "public"."plant_hygiene_workers" to "anon";

grant insert on table "public"."plant_hygiene_workers" to "anon";

grant references on table "public"."plant_hygiene_workers" to "anon";

grant select on table "public"."plant_hygiene_workers" to "anon";

grant trigger on table "public"."plant_hygiene_workers" to "anon";

grant truncate on table "public"."plant_hygiene_workers" to "anon";

grant update on table "public"."plant_hygiene_workers" to "anon";

grant delete on table "public"."plant_hygiene_workers" to "authenticated";

grant insert on table "public"."plant_hygiene_workers" to "authenticated";

grant references on table "public"."plant_hygiene_workers" to "authenticated";

grant select on table "public"."plant_hygiene_workers" to "authenticated";

grant trigger on table "public"."plant_hygiene_workers" to "authenticated";

grant truncate on table "public"."plant_hygiene_workers" to "authenticated";

grant update on table "public"."plant_hygiene_workers" to "authenticated";

grant delete on table "public"."plant_hygiene_workers" to "service_role";

grant insert on table "public"."plant_hygiene_workers" to "service_role";

grant references on table "public"."plant_hygiene_workers" to "service_role";

grant select on table "public"."plant_hygiene_workers" to "service_role";

grant trigger on table "public"."plant_hygiene_workers" to "service_role";

grant truncate on table "public"."plant_hygiene_workers" to "service_role";

grant update on table "public"."plant_hygiene_workers" to "service_role";

grant delete on table "public"."plant_order_checklists" to "anon";

grant insert on table "public"."plant_order_checklists" to "anon";

grant references on table "public"."plant_order_checklists" to "anon";

grant select on table "public"."plant_order_checklists" to "anon";

grant trigger on table "public"."plant_order_checklists" to "anon";

grant truncate on table "public"."plant_order_checklists" to "anon";

grant update on table "public"."plant_order_checklists" to "anon";

grant delete on table "public"."plant_order_checklists" to "authenticated";

grant insert on table "public"."plant_order_checklists" to "authenticated";

grant references on table "public"."plant_order_checklists" to "authenticated";

grant select on table "public"."plant_order_checklists" to "authenticated";

grant trigger on table "public"."plant_order_checklists" to "authenticated";

grant truncate on table "public"."plant_order_checklists" to "authenticated";

grant update on table "public"."plant_order_checklists" to "authenticated";

grant delete on table "public"."plant_order_checklists" to "service_role";

grant insert on table "public"."plant_order_checklists" to "service_role";

grant references on table "public"."plant_order_checklists" to "service_role";

grant select on table "public"."plant_order_checklists" to "service_role";

grant trigger on table "public"."plant_order_checklists" to "service_role";

grant truncate on table "public"."plant_order_checklists" to "service_role";

grant update on table "public"."plant_order_checklists" to "service_role";

grant delete on table "public"."plant_orders" to "anon";

grant insert on table "public"."plant_orders" to "anon";

grant references on table "public"."plant_orders" to "anon";

grant select on table "public"."plant_orders" to "anon";

grant trigger on table "public"."plant_orders" to "anon";

grant truncate on table "public"."plant_orders" to "anon";

grant update on table "public"."plant_orders" to "anon";

grant delete on table "public"."plant_orders" to "authenticated";

grant insert on table "public"."plant_orders" to "authenticated";

grant references on table "public"."plant_orders" to "authenticated";

grant select on table "public"."plant_orders" to "authenticated";

grant trigger on table "public"."plant_orders" to "authenticated";

grant truncate on table "public"."plant_orders" to "authenticated";

grant update on table "public"."plant_orders" to "authenticated";

grant delete on table "public"."plant_orders" to "service_role";

grant insert on table "public"."plant_orders" to "service_role";

grant references on table "public"."plant_orders" to "service_role";

grant select on table "public"."plant_orders" to "service_role";

grant trigger on table "public"."plant_orders" to "service_role";

grant truncate on table "public"."plant_orders" to "service_role";

grant update on table "public"."plant_orders" to "service_role";

grant delete on table "public"."plant_production_batches" to "anon";

grant insert on table "public"."plant_production_batches" to "anon";

grant references on table "public"."plant_production_batches" to "anon";

grant select on table "public"."plant_production_batches" to "anon";

grant trigger on table "public"."plant_production_batches" to "anon";

grant truncate on table "public"."plant_production_batches" to "anon";

grant update on table "public"."plant_production_batches" to "anon";

grant delete on table "public"."plant_production_batches" to "authenticated";

grant insert on table "public"."plant_production_batches" to "authenticated";

grant references on table "public"."plant_production_batches" to "authenticated";

grant select on table "public"."plant_production_batches" to "authenticated";

grant trigger on table "public"."plant_production_batches" to "authenticated";

grant truncate on table "public"."plant_production_batches" to "authenticated";

grant update on table "public"."plant_production_batches" to "authenticated";

grant delete on table "public"."plant_production_batches" to "service_role";

grant insert on table "public"."plant_production_batches" to "service_role";

grant references on table "public"."plant_production_batches" to "service_role";

grant select on table "public"."plant_production_batches" to "service_role";

grant trigger on table "public"."plant_production_batches" to "service_role";

grant truncate on table "public"."plant_production_batches" to "service_role";

grant update on table "public"."plant_production_batches" to "service_role";

grant delete on table "public"."plots" to "anon";

grant insert on table "public"."plots" to "anon";

grant references on table "public"."plots" to "anon";

grant select on table "public"."plots" to "anon";

grant trigger on table "public"."plots" to "anon";

grant truncate on table "public"."plots" to "anon";

grant update on table "public"."plots" to "anon";

grant delete on table "public"."plots" to "authenticated";

grant insert on table "public"."plots" to "authenticated";

grant references on table "public"."plots" to "authenticated";

grant select on table "public"."plots" to "authenticated";

grant trigger on table "public"."plots" to "authenticated";

grant truncate on table "public"."plots" to "authenticated";

grant update on table "public"."plots" to "authenticated";

grant delete on table "public"."plots" to "service_role";

grant insert on table "public"."plots" to "service_role";

grant references on table "public"."plots" to "service_role";

grant select on table "public"."plots" to "service_role";

grant trigger on table "public"."plots" to "service_role";

grant truncate on table "public"."plots" to "service_role";

grant update on table "public"."plots" to "service_role";

grant delete on table "public"."producers" to "anon";

grant insert on table "public"."producers" to "anon";

grant references on table "public"."producers" to "anon";

grant select on table "public"."producers" to "anon";

grant trigger on table "public"."producers" to "anon";

grant truncate on table "public"."producers" to "anon";

grant update on table "public"."producers" to "anon";

grant delete on table "public"."producers" to "authenticated";

grant insert on table "public"."producers" to "authenticated";

grant references on table "public"."producers" to "authenticated";

grant select on table "public"."producers" to "authenticated";

grant trigger on table "public"."producers" to "authenticated";

grant truncate on table "public"."producers" to "authenticated";

grant update on table "public"."producers" to "authenticated";

grant delete on table "public"."producers" to "service_role";

grant insert on table "public"."producers" to "service_role";

grant references on table "public"."producers" to "service_role";

grant select on table "public"."producers" to "service_role";

grant trigger on table "public"."producers" to "service_role";

grant truncate on table "public"."producers" to "service_role";

grant update on table "public"."producers" to "service_role";

grant delete on table "public"."product_returns" to "anon";

grant insert on table "public"."product_returns" to "anon";

grant references on table "public"."product_returns" to "anon";

grant select on table "public"."product_returns" to "anon";

grant trigger on table "public"."product_returns" to "anon";

grant truncate on table "public"."product_returns" to "anon";

grant update on table "public"."product_returns" to "anon";

grant delete on table "public"."product_returns" to "authenticated";

grant insert on table "public"."product_returns" to "authenticated";

grant references on table "public"."product_returns" to "authenticated";

grant select on table "public"."product_returns" to "authenticated";

grant trigger on table "public"."product_returns" to "authenticated";

grant truncate on table "public"."product_returns" to "authenticated";

grant update on table "public"."product_returns" to "authenticated";

grant delete on table "public"."product_returns" to "service_role";

grant insert on table "public"."product_returns" to "service_role";

grant references on table "public"."product_returns" to "service_role";

grant select on table "public"."product_returns" to "service_role";

grant trigger on table "public"."product_returns" to "service_role";

grant truncate on table "public"."product_returns" to "service_role";

grant update on table "public"."product_returns" to "service_role";

grant delete on table "public"."production_batch_certs" to "anon";

grant insert on table "public"."production_batch_certs" to "anon";

grant references on table "public"."production_batch_certs" to "anon";

grant select on table "public"."production_batch_certs" to "anon";

grant trigger on table "public"."production_batch_certs" to "anon";

grant truncate on table "public"."production_batch_certs" to "anon";

grant update on table "public"."production_batch_certs" to "anon";

grant delete on table "public"."production_batch_certs" to "authenticated";

grant insert on table "public"."production_batch_certs" to "authenticated";

grant references on table "public"."production_batch_certs" to "authenticated";

grant select on table "public"."production_batch_certs" to "authenticated";

grant trigger on table "public"."production_batch_certs" to "authenticated";

grant truncate on table "public"."production_batch_certs" to "authenticated";

grant update on table "public"."production_batch_certs" to "authenticated";

grant delete on table "public"."production_batch_certs" to "service_role";

grant insert on table "public"."production_batch_certs" to "service_role";

grant references on table "public"."production_batch_certs" to "service_role";

grant select on table "public"."production_batch_certs" to "service_role";

grant trigger on table "public"."production_batch_certs" to "service_role";

grant truncate on table "public"."production_batch_certs" to "service_role";

grant update on table "public"."production_batch_certs" to "service_role";

grant delete on table "public"."production_batches" to "anon";

grant insert on table "public"."production_batches" to "anon";

grant references on table "public"."production_batches" to "anon";

grant select on table "public"."production_batches" to "anon";

grant trigger on table "public"."production_batches" to "anon";

grant truncate on table "public"."production_batches" to "anon";

grant update on table "public"."production_batches" to "anon";

grant delete on table "public"."production_batches" to "authenticated";

grant insert on table "public"."production_batches" to "authenticated";

grant references on table "public"."production_batches" to "authenticated";

grant select on table "public"."production_batches" to "authenticated";

grant trigger on table "public"."production_batches" to "authenticated";

grant truncate on table "public"."production_batches" to "authenticated";

grant update on table "public"."production_batches" to "authenticated";

grant delete on table "public"."production_batches" to "service_role";

grant insert on table "public"."production_batches" to "service_role";

grant references on table "public"."production_batches" to "service_role";

grant select on table "public"."production_batches" to "service_role";

grant trigger on table "public"."production_batches" to "service_role";

grant truncate on table "public"."production_batches" to "service_role";

grant update on table "public"."production_batches" to "service_role";

grant delete on table "public"."quality_evaluations" to "anon";

grant insert on table "public"."quality_evaluations" to "anon";

grant references on table "public"."quality_evaluations" to "anon";

grant select on table "public"."quality_evaluations" to "anon";

grant trigger on table "public"."quality_evaluations" to "anon";

grant truncate on table "public"."quality_evaluations" to "anon";

grant update on table "public"."quality_evaluations" to "anon";

grant delete on table "public"."quality_evaluations" to "authenticated";

grant insert on table "public"."quality_evaluations" to "authenticated";

grant references on table "public"."quality_evaluations" to "authenticated";

grant select on table "public"."quality_evaluations" to "authenticated";

grant trigger on table "public"."quality_evaluations" to "authenticated";

grant truncate on table "public"."quality_evaluations" to "authenticated";

grant update on table "public"."quality_evaluations" to "authenticated";

grant delete on table "public"."quality_evaluations" to "service_role";

grant insert on table "public"."quality_evaluations" to "service_role";

grant references on table "public"."quality_evaluations" to "service_role";

grant select on table "public"."quality_evaluations" to "service_role";

grant trigger on table "public"."quality_evaluations" to "service_role";

grant truncate on table "public"."quality_evaluations" to "service_role";

grant update on table "public"."quality_evaluations" to "service_role";

grant delete on table "public"."stowage_transport_inspections" to "anon";

grant insert on table "public"."stowage_transport_inspections" to "anon";

grant references on table "public"."stowage_transport_inspections" to "anon";

grant select on table "public"."stowage_transport_inspections" to "anon";

grant trigger on table "public"."stowage_transport_inspections" to "anon";

grant truncate on table "public"."stowage_transport_inspections" to "anon";

grant update on table "public"."stowage_transport_inspections" to "anon";

grant delete on table "public"."stowage_transport_inspections" to "authenticated";

grant insert on table "public"."stowage_transport_inspections" to "authenticated";

grant references on table "public"."stowage_transport_inspections" to "authenticated";

grant select on table "public"."stowage_transport_inspections" to "authenticated";

grant trigger on table "public"."stowage_transport_inspections" to "authenticated";

grant truncate on table "public"."stowage_transport_inspections" to "authenticated";

grant update on table "public"."stowage_transport_inspections" to "authenticated";

grant delete on table "public"."stowage_transport_inspections" to "service_role";

grant insert on table "public"."stowage_transport_inspections" to "service_role";

grant references on table "public"."stowage_transport_inspections" to "service_role";

grant select on table "public"."stowage_transport_inspections" to "service_role";

grant trigger on table "public"."stowage_transport_inspections" to "service_role";

grant truncate on table "public"."stowage_transport_inspections" to "service_role";

grant update on table "public"."stowage_transport_inspections" to "service_role";

grant delete on table "public"."user_module_assignments" to "anon";

grant insert on table "public"."user_module_assignments" to "anon";

grant references on table "public"."user_module_assignments" to "anon";

grant select on table "public"."user_module_assignments" to "anon";

grant trigger on table "public"."user_module_assignments" to "anon";

grant truncate on table "public"."user_module_assignments" to "anon";

grant update on table "public"."user_module_assignments" to "anon";

grant delete on table "public"."user_module_assignments" to "authenticated";

grant insert on table "public"."user_module_assignments" to "authenticated";

grant references on table "public"."user_module_assignments" to "authenticated";

grant select on table "public"."user_module_assignments" to "authenticated";

grant trigger on table "public"."user_module_assignments" to "authenticated";

grant truncate on table "public"."user_module_assignments" to "authenticated";

grant update on table "public"."user_module_assignments" to "authenticated";

grant delete on table "public"."user_module_assignments" to "service_role";

grant insert on table "public"."user_module_assignments" to "service_role";

grant references on table "public"."user_module_assignments" to "service_role";

grant select on table "public"."user_module_assignments" to "service_role";

grant trigger on table "public"."user_module_assignments" to "service_role";

grant truncate on table "public"."user_module_assignments" to "service_role";

grant update on table "public"."user_module_assignments" to "service_role";

grant delete on table "public"."users" to "anon";

grant insert on table "public"."users" to "anon";

grant references on table "public"."users" to "anon";

grant select on table "public"."users" to "anon";

grant trigger on table "public"."users" to "anon";

grant truncate on table "public"."users" to "anon";

grant update on table "public"."users" to "anon";

grant delete on table "public"."users" to "authenticated";

grant insert on table "public"."users" to "authenticated";

grant references on table "public"."users" to "authenticated";

grant select on table "public"."users" to "authenticated";

grant trigger on table "public"."users" to "authenticated";

grant truncate on table "public"."users" to "authenticated";

grant update on table "public"."users" to "authenticated";

grant delete on table "public"."users" to "service_role";

grant insert on table "public"."users" to "service_role";

grant references on table "public"."users" to "service_role";

grant select on table "public"."users" to "service_role";

grant trigger on table "public"."users" to "service_role";

grant truncate on table "public"."users" to "service_role";

grant update on table "public"."users" to "service_role";

grant select on table "public"."users" to "supabase_auth_admin";

grant delete on table "public"."web_users" to "anon";

grant insert on table "public"."web_users" to "anon";

grant references on table "public"."web_users" to "anon";

grant select on table "public"."web_users" to "anon";

grant trigger on table "public"."web_users" to "anon";

grant truncate on table "public"."web_users" to "anon";

grant update on table "public"."web_users" to "anon";

grant delete on table "public"."web_users" to "authenticated";

grant insert on table "public"."web_users" to "authenticated";

grant references on table "public"."web_users" to "authenticated";

grant select on table "public"."web_users" to "authenticated";

grant trigger on table "public"."web_users" to "authenticated";

grant truncate on table "public"."web_users" to "authenticated";

grant update on table "public"."web_users" to "authenticated";

grant delete on table "public"."web_users" to "service_role";

grant insert on table "public"."web_users" to "service_role";

grant references on table "public"."web_users" to "service_role";

grant select on table "public"."web_users" to "service_role";

grant trigger on table "public"."web_users" to "service_role";

grant truncate on table "public"."web_users" to "service_role";

grant update on table "public"."web_users" to "service_role";

grant select on table "public"."web_users" to "supabase_auth_admin";

grant delete on table "public"."worker_control_items" to "anon";

grant insert on table "public"."worker_control_items" to "anon";

grant references on table "public"."worker_control_items" to "anon";

grant select on table "public"."worker_control_items" to "anon";

grant trigger on table "public"."worker_control_items" to "anon";

grant truncate on table "public"."worker_control_items" to "anon";

grant update on table "public"."worker_control_items" to "anon";

grant delete on table "public"."worker_control_items" to "authenticated";

grant insert on table "public"."worker_control_items" to "authenticated";

grant references on table "public"."worker_control_items" to "authenticated";

grant select on table "public"."worker_control_items" to "authenticated";

grant trigger on table "public"."worker_control_items" to "authenticated";

grant truncate on table "public"."worker_control_items" to "authenticated";

grant update on table "public"."worker_control_items" to "authenticated";

grant delete on table "public"."worker_control_items" to "service_role";

grant insert on table "public"."worker_control_items" to "service_role";

grant references on table "public"."worker_control_items" to "service_role";

grant select on table "public"."worker_control_items" to "service_role";

grant trigger on table "public"."worker_control_items" to "service_role";

grant truncate on table "public"."worker_control_items" to "service_role";

grant update on table "public"."worker_control_items" to "service_role";

grant delete on table "public"."worker_controls" to "anon";

grant insert on table "public"."worker_controls" to "anon";

grant references on table "public"."worker_controls" to "anon";

grant select on table "public"."worker_controls" to "anon";

grant trigger on table "public"."worker_controls" to "anon";

grant truncate on table "public"."worker_controls" to "anon";

grant update on table "public"."worker_controls" to "anon";

grant delete on table "public"."worker_controls" to "authenticated";

grant insert on table "public"."worker_controls" to "authenticated";

grant references on table "public"."worker_controls" to "authenticated";

grant select on table "public"."worker_controls" to "authenticated";

grant trigger on table "public"."worker_controls" to "authenticated";

grant truncate on table "public"."worker_controls" to "authenticated";

grant update on table "public"."worker_controls" to "authenticated";

grant delete on table "public"."worker_controls" to "service_role";

grant insert on table "public"."worker_controls" to "service_role";

grant references on table "public"."worker_controls" to "service_role";

grant select on table "public"."worker_controls" to "service_role";

grant trigger on table "public"."worker_controls" to "service_role";

grant truncate on table "public"."worker_controls" to "service_role";

grant update on table "public"."worker_controls" to "service_role";


  create policy "batch_certs_delete"
  on "public"."batch_certs"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "batch_certs_insert"
  on "public"."batch_certs"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "batch_certs_select"
  on "public"."batch_certs"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "batch_certs_update"
  on "public"."batch_certs"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "batch_ph_controls_delete"
  on "public"."batch_ph_controls"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "batch_ph_controls_insert"
  on "public"."batch_ph_controls"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "batch_ph_controls_select"
  on "public"."batch_ph_controls"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "batch_ph_controls_update"
  on "public"."batch_ph_controls"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "batch_temperatures_delete"
  on "public"."batch_temperatures"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "batch_temperatures_insert"
  on "public"."batch_temperatures"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "batch_temperatures_select"
  on "public"."batch_temperatures"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "batch_temperatures_update"
  on "public"."batch_temperatures"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "certificate_exclusion_groups_delete"
  on "public"."certificate_exclusion_groups"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "certificate_exclusion_groups_insert"
  on "public"."certificate_exclusion_groups"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "certificate_exclusion_groups_select"
  on "public"."certificate_exclusion_groups"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "certificate_exclusion_groups_update"
  on "public"."certificate_exclusion_groups"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "chlorine_residual_controls_delete"
  on "public"."chlorine_residual_controls"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "chlorine_residual_controls_insert"
  on "public"."chlorine_residual_controls"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "chlorine_residual_controls_select"
  on "public"."chlorine_residual_controls"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "chlorine_residual_controls_update"
  on "public"."chlorine_residual_controls"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "cdi_all"
  on "public"."cleaning_disinfection_items"
  as permissive
  for all
  to authenticated
using ((public.is_service_role() OR (cleaning_disinfection_id IN ( SELECT cleaning_disinfections.id
   FROM public.cleaning_disinfections
  WHERE (cleaning_disinfections.cooperative_id = public.auth_cooperative_id())))))
with check ((public.is_service_role() OR (cleaning_disinfection_id IN ( SELECT cleaning_disinfections.id
   FROM public.cleaning_disinfections
  WHERE (cleaning_disinfections.cooperative_id = public.auth_cooperative_id())))));



  create policy "cleaning_disinfections_delete"
  on "public"."cleaning_disinfections"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "cleaning_disinfections_insert"
  on "public"."cleaning_disinfections"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "cleaning_disinfections_select"
  on "public"."cleaning_disinfections"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "cleaning_disinfections_update"
  on "public"."cleaning_disinfections"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "coop_modules_delete"
  on "public"."coop_modules"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "coop_modules_insert"
  on "public"."coop_modules"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "coop_modules_select"
  on "public"."coop_modules"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "coop_modules_update"
  on "public"."coop_modules"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "cooperatives_modify"
  on "public"."cooperatives"
  as permissive
  for all
  to authenticated
using (public.is_service_role())
with check (public.is_service_role());



  create policy "cooperatives_select"
  on "public"."cooperatives"
  as permissive
  for select
  to authenticated
using (((id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "eii_all"
  on "public"."environment_inspection_items"
  as permissive
  for all
  to authenticated
using ((public.is_service_role() OR (environment_inspection_id IN ( SELECT environment_inspections.id
   FROM public.environment_inspections
  WHERE (environment_inspections.cooperative_id = public.auth_cooperative_id())))))
with check ((public.is_service_role() OR (environment_inspection_id IN ( SELECT environment_inspections.id
   FROM public.environment_inspections
  WHERE (environment_inspections.cooperative_id = public.auth_cooperative_id())))));



  create policy "environment_inspections_delete"
  on "public"."environment_inspections"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "environment_inspections_insert"
  on "public"."environment_inspections"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "environment_inspections_select"
  on "public"."environment_inspections"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "environment_inspections_update"
  on "public"."environment_inspections"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "equipment_maintenance_records_delete"
  on "public"."equipment_maintenance_records"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "equipment_maintenance_records_insert"
  on "public"."equipment_maintenance_records"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "equipment_maintenance_records_select"
  on "public"."equipment_maintenance_records"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "equipment_maintenance_records_update"
  on "public"."equipment_maintenance_records"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "exit_items_delete"
  on "public"."exit_items"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "exit_items_insert"
  on "public"."exit_items"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "exit_items_select"
  on "public"."exit_items"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "exit_items_update"
  on "public"."exit_items"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "eri_all"
  on "public"."exit_reception_items"
  as permissive
  for all
  to authenticated
using ((public.is_service_role() OR (exit_reception_id IN ( SELECT exit_receptions.id
   FROM public.exit_receptions
  WHERE (exit_receptions.cooperative_id = public.auth_cooperative_id())))))
with check ((public.is_service_role() OR (exit_reception_id IN ( SELECT exit_receptions.id
   FROM public.exit_receptions
  WHERE (exit_receptions.cooperative_id = public.auth_cooperative_id())))));



  create policy "exit_receptions_delete"
  on "public"."exit_receptions"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "exit_receptions_insert"
  on "public"."exit_receptions"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "exit_receptions_select"
  on "public"."exit_receptions"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "exit_receptions_update"
  on "public"."exit_receptions"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "exit_registrations_delete"
  on "public"."exit_registrations"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "exit_registrations_insert"
  on "public"."exit_registrations"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "exit_registrations_select"
  on "public"."exit_registrations"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "exit_registrations_update"
  on "public"."exit_registrations"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "form_configurations_delete"
  on "public"."form_configurations"
  as permissive
  for delete
  to authenticated
using (public.is_service_role());



  create policy "form_configurations_insert"
  on "public"."form_configurations"
  as permissive
  for insert
  to authenticated
with check (public.is_service_role());



  create policy "form_configurations_select"
  on "public"."form_configurations"
  as permissive
  for select
  to authenticated
using (((cooperative_id IS NULL) OR (cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "form_configurations_update"
  on "public"."form_configurations"
  as permissive
  for update
  to authenticated
using (public.is_service_role())
with check (public.is_service_role());



  create policy "formatos_control_cloro_delete"
  on "public"."formatos_control_cloro"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_control_cloro_insert"
  on "public"."formatos_control_cloro"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_control_cloro_select"
  on "public"."formatos_control_cloro"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_control_cloro_update"
  on "public"."formatos_control_cloro"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_control_mp_ph_delete"
  on "public"."formatos_control_mp_ph"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_control_mp_ph_insert"
  on "public"."formatos_control_mp_ph"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_control_mp_ph_select"
  on "public"."formatos_control_mp_ph"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_control_mp_ph_update"
  on "public"."formatos_control_mp_ph"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "fcmptph_lotes_delete"
  on "public"."formatos_control_mp_ph_lotes"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.formatos_control_mp_ph f
  WHERE ((f.id = formatos_control_mp_ph_lotes.formato_id) AND ((f.cooperative_id = public.auth_cooperative_id()) OR public.is_service_role())))));



  create policy "fcmptph_lotes_insert"
  on "public"."formatos_control_mp_ph_lotes"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.formatos_control_mp_ph f
  WHERE ((f.id = formatos_control_mp_ph_lotes.formato_id) AND ((f.cooperative_id = public.auth_cooperative_id()) OR public.is_service_role())))));



  create policy "fcmptph_lotes_select"
  on "public"."formatos_control_mp_ph_lotes"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.formatos_control_mp_ph f
  WHERE ((f.id = formatos_control_mp_ph_lotes.formato_id) AND ((f.cooperative_id = public.auth_cooperative_id()) OR public.is_service_role())))));



  create policy "formatos_control_personal_delete"
  on "public"."formatos_control_personal"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_control_personal_insert"
  on "public"."formatos_control_personal"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_control_personal_select"
  on "public"."formatos_control_personal"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_control_personal_update"
  on "public"."formatos_control_personal"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_control_plagas_delete"
  on "public"."formatos_control_plagas"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_control_plagas_insert"
  on "public"."formatos_control_plagas"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_control_plagas_select"
  on "public"."formatos_control_plagas"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_control_plagas_update"
  on "public"."formatos_control_plagas"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_inspeccion_ambientes_delete"
  on "public"."formatos_inspeccion_ambientes"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_inspeccion_ambientes_insert"
  on "public"."formatos_inspeccion_ambientes"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_inspeccion_ambientes_select"
  on "public"."formatos_inspeccion_ambientes"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "formatos_inspeccion_ambientes_update"
  on "public"."formatos_inspeccion_ambientes"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "fldh_coop_isolation"
  on "public"."formatos_limpieza_desinfeccion"
  as permissive
  for all
  to public
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "health_incidents_delete"
  on "public"."health_incidents"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "health_incidents_insert"
  on "public"."health_incidents"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "health_incidents_select"
  on "public"."health_incidents"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "health_incidents_update"
  on "public"."health_incidents"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "inventory_stock_delete"
  on "public"."inventory_stock"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "inventory_stock_insert"
  on "public"."inventory_stock"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "inventory_stock_select"
  on "public"."inventory_stock"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "inventory_stock_update"
  on "public"."inventory_stock"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "pcb_all"
  on "public"."pest_control_bait_records"
  as permissive
  for all
  to authenticated
using ((public.is_service_role() OR (pest_control_id IN ( SELECT pest_controls.id
   FROM public.pest_controls
  WHERE (pest_controls.cooperative_id = public.auth_cooperative_id())))))
with check ((public.is_service_role() OR (pest_control_id IN ( SELECT pest_controls.id
   FROM public.pest_controls
  WHERE (pest_controls.cooperative_id = public.auth_cooperative_id())))));



  create policy "pci_all"
  on "public"."pest_control_insect_records"
  as permissive
  for all
  to authenticated
using ((public.is_service_role() OR (pest_control_id IN ( SELECT pest_controls.id
   FROM public.pest_controls
  WHERE (pest_controls.cooperative_id = public.auth_cooperative_id())))))
with check ((public.is_service_role() OR (pest_control_id IN ( SELECT pest_controls.id
   FROM public.pest_controls
  WHERE (pest_controls.cooperative_id = public.auth_cooperative_id())))));



  create policy "pest_controls_delete"
  on "public"."pest_controls"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "pest_controls_insert"
  on "public"."pest_controls"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "pest_controls_select"
  on "public"."pest_controls"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "pest_controls_update"
  on "public"."pest_controls"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_batch_processing_delete"
  on "public"."plant_batch_processing"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_batch_processing_insert"
  on "public"."plant_batch_processing"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_batch_processing_select"
  on "public"."plant_batch_processing"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_batch_processing_update"
  on "public"."plant_batch_processing"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_checklists_delete"
  on "public"."plant_checklists"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_checklists_insert"
  on "public"."plant_checklists"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_checklists_select"
  on "public"."plant_checklists"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_checklists_update"
  on "public"."plant_checklists"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_containers_delete"
  on "public"."plant_containers"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_containers_insert"
  on "public"."plant_containers"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_containers_select"
  on "public"."plant_containers"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_containers_update"
  on "public"."plant_containers"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_dispatches_delete"
  on "public"."plant_dispatches"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_dispatches_insert"
  on "public"."plant_dispatches"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_dispatches_select"
  on "public"."plant_dispatches"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_dispatches_update"
  on "public"."plant_dispatches"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_homogenization_inputs_delete"
  on "public"."plant_homogenization_inputs"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_homogenization_inputs_insert"
  on "public"."plant_homogenization_inputs"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_homogenization_inputs_select"
  on "public"."plant_homogenization_inputs"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_homogenization_inputs_update"
  on "public"."plant_homogenization_inputs"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_order_checklists_delete"
  on "public"."plant_order_checklists"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_order_checklists_insert"
  on "public"."plant_order_checklists"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_order_checklists_select"
  on "public"."plant_order_checklists"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_order_checklists_update"
  on "public"."plant_order_checklists"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_orders_delete"
  on "public"."plant_orders"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_orders_insert"
  on "public"."plant_orders"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_orders_select"
  on "public"."plant_orders"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_orders_update"
  on "public"."plant_orders"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_production_batches_delete"
  on "public"."plant_production_batches"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_production_batches_insert"
  on "public"."plant_production_batches"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_production_batches_select"
  on "public"."plant_production_batches"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plant_production_batches_update"
  on "public"."plant_production_batches"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "plots_delete"
  on "public"."plots"
  as permissive
  for delete
  to authenticated
using ((public.is_service_role() OR (producer_id IN ( SELECT producers.id
   FROM public.producers
  WHERE (producers.cooperative_id = public.auth_cooperative_id())))));



  create policy "plots_insert"
  on "public"."plots"
  as permissive
  for insert
  to authenticated
with check ((public.is_service_role() OR (producer_id IN ( SELECT producers.id
   FROM public.producers
  WHERE (producers.cooperative_id = public.auth_cooperative_id())))));



  create policy "plots_select"
  on "public"."plots"
  as permissive
  for select
  to authenticated
using ((public.is_service_role() OR (producer_id IN ( SELECT producers.id
   FROM public.producers
  WHERE (producers.cooperative_id = public.auth_cooperative_id())))));



  create policy "plots_update"
  on "public"."plots"
  as permissive
  for update
  to authenticated
using ((public.is_service_role() OR (producer_id IN ( SELECT producers.id
   FROM public.producers
  WHERE (producers.cooperative_id = public.auth_cooperative_id())))))
with check ((public.is_service_role() OR (producer_id IN ( SELECT producers.id
   FROM public.producers
  WHERE (producers.cooperative_id = public.auth_cooperative_id())))));



  create policy "producers_delete"
  on "public"."producers"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "producers_insert"
  on "public"."producers"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "producers_select"
  on "public"."producers"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "producers_update"
  on "public"."producers"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "product_returns_delete"
  on "public"."product_returns"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "product_returns_insert"
  on "public"."product_returns"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "product_returns_select"
  on "public"."product_returns"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "product_returns_update"
  on "public"."product_returns"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "production_batch_certs_delete"
  on "public"."production_batch_certs"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "production_batch_certs_insert"
  on "public"."production_batch_certs"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "production_batch_certs_select"
  on "public"."production_batch_certs"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "production_batch_certs_update"
  on "public"."production_batch_certs"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "production_batches_delete"
  on "public"."production_batches"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "production_batches_insert"
  on "public"."production_batches"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "production_batches_select"
  on "public"."production_batches"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "production_batches_update"
  on "public"."production_batches"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "quality_evaluations_delete"
  on "public"."quality_evaluations"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "quality_evaluations_insert"
  on "public"."quality_evaluations"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "quality_evaluations_select"
  on "public"."quality_evaluations"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "quality_evaluations_update"
  on "public"."quality_evaluations"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "stowage_transport_inspections_delete"
  on "public"."stowage_transport_inspections"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "stowage_transport_inspections_insert"
  on "public"."stowage_transport_inspections"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "stowage_transport_inspections_select"
  on "public"."stowage_transport_inspections"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "stowage_transport_inspections_update"
  on "public"."stowage_transport_inspections"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "user_module_assignments_delete"
  on "public"."user_module_assignments"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "user_module_assignments_insert"
  on "public"."user_module_assignments"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "user_module_assignments_select"
  on "public"."user_module_assignments"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "user_module_assignments_update"
  on "public"."user_module_assignments"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "users_delete"
  on "public"."users"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "users_insert"
  on "public"."users"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "users_select"
  on "public"."users"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "users_update"
  on "public"."users"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "web_users_delete"
  on "public"."web_users"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "web_users_insert"
  on "public"."web_users"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "web_users_select"
  on "public"."web_users"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "web_users_update"
  on "public"."web_users"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "wci_all"
  on "public"."worker_control_items"
  as permissive
  for all
  to authenticated
using ((public.is_service_role() OR (worker_control_id IN ( SELECT worker_controls.id
   FROM public.worker_controls
  WHERE (worker_controls.cooperative_id = public.auth_cooperative_id())))))
with check ((public.is_service_role() OR (worker_control_id IN ( SELECT worker_controls.id
   FROM public.worker_controls
  WHERE (worker_controls.cooperative_id = public.auth_cooperative_id())))));



  create policy "worker_controls_delete"
  on "public"."worker_controls"
  as permissive
  for delete
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "worker_controls_insert"
  on "public"."worker_controls"
  as permissive
  for insert
  to authenticated
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "worker_controls_select"
  on "public"."worker_controls"
  as permissive
  for select
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));



  create policy "worker_controls_update"
  on "public"."worker_controls"
  as permissive
  for update
  to authenticated
using (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()))
with check (((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role()));


CREATE TRIGGER update_batch_certs_updated_at BEFORE UPDATE ON public.batch_certs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_certificate_exclusion_groups_updated_at BEFORE UPDATE ON public.certificate_exclusion_groups FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_set_created_by_chlorine BEFORE INSERT ON public.chlorine_residual_controls FOR EACH ROW EXECUTE FUNCTION public.set_created_by_from_auth_chlorine();

CREATE TRIGGER trigger_update_chlorine_controls_updated_at BEFORE UPDATE ON public.chlorine_residual_controls FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_update_cleaning_items_updated_at BEFORE UPDATE ON public.cleaning_disinfection_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_set_created_by_cleaning BEFORE INSERT ON public.cleaning_disinfections FOR EACH ROW EXECUTE FUNCTION public.set_created_by_from_auth_cleaning();

CREATE TRIGGER trigger_update_cleaning_disinfections_updated_at BEFORE UPDATE ON public.cleaning_disinfections FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_coop_modules_updated_at BEFORE UPDATE ON public.coop_modules FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_cooperatives_updated_at BEFORE UPDATE ON public.cooperatives FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_environment_inspection_items_updated_at BEFORE UPDATE ON public.environment_inspection_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER set_created_by_before_insert BEFORE INSERT ON public.environment_inspections FOR EACH ROW EXECUTE FUNCTION public.set_created_by_from_auth();

CREATE TRIGGER update_environment_inspections_updated_at BEFORE UPDATE ON public.environment_inspections FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER validate_environment_inspection_trigger BEFORE INSERT OR UPDATE ON public.environment_inspections FOR EACH ROW EXECUTE FUNCTION public.validate_environment_inspection();

CREATE TRIGGER set_equipment_maintenance_created_by_trigger BEFORE INSERT ON public.equipment_maintenance_records FOR EACH ROW EXECUTE FUNCTION public.set_equipment_maintenance_created_by();

CREATE TRIGGER update_equipment_maintenance_updated_at BEFORE UPDATE ON public.equipment_maintenance_records FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER validate_equipment_maintenance_record_trigger BEFORE INSERT OR UPDATE ON public.equipment_maintenance_records FOR EACH ROW EXECUTE FUNCTION public.validate_equipment_maintenance_record();

CREATE TRIGGER update_exit_total_after_delete AFTER DELETE ON public.exit_items FOR EACH ROW EXECUTE FUNCTION public.update_exit_total();

CREATE TRIGGER update_exit_total_after_insert AFTER INSERT ON public.exit_items FOR EACH ROW EXECUTE FUNCTION public.update_exit_total();

CREATE TRIGGER update_exit_total_after_update AFTER UPDATE ON public.exit_items FOR EACH ROW EXECUTE FUNCTION public.update_exit_total();

CREATE TRIGGER update_stock_after_exit_delete AFTER DELETE ON public.exit_items FOR EACH ROW EXECUTE FUNCTION public.update_stock_after_exit();

CREATE TRIGGER update_stock_after_exit_insert AFTER INSERT ON public.exit_items FOR EACH ROW EXECUTE FUNCTION public.update_stock_after_exit();

CREATE TRIGGER update_stock_after_exit_update AFTER UPDATE ON public.exit_items FOR EACH ROW EXECUTE FUNCTION public.update_stock_after_exit();

CREATE TRIGGER validate_exit_item_trigger BEFORE INSERT OR UPDATE ON public.exit_items FOR EACH ROW EXECUTE FUNCTION public.validate_exit_item();

CREATE TRIGGER auto_generate_exit_code_trigger BEFORE INSERT ON public.exit_registrations FOR EACH ROW EXECUTE FUNCTION public.auto_generate_exit_code();

CREATE TRIGGER update_exit_registrations_updated_at BEFORE UPDATE ON public.exit_registrations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER validate_exit_registration_trigger BEFORE INSERT OR UPDATE ON public.exit_registrations FOR EACH ROW EXECUTE FUNCTION public.validate_exit_registration();

CREATE TRIGGER set_created_by_before_insert BEFORE INSERT ON public.health_incidents FOR EACH ROW EXECUTE FUNCTION public.set_health_incident_created_by();

CREATE TRIGGER update_health_incidents_updated_at BEFORE UPDATE ON public.health_incidents FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER validate_health_incident_trigger BEFORE INSERT OR UPDATE ON public.health_incidents FOR EACH ROW EXECUTE FUNCTION public.validate_health_incident();

CREATE TRIGGER update_inventory_stock_updated_at BEFORE UPDATE ON public.inventory_stock FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER validate_stock_operation_trigger BEFORE INSERT OR UPDATE ON public.inventory_stock FOR EACH ROW EXECUTE FUNCTION public.validate_stock_operation();

CREATE TRIGGER trigger_update_pest_bait_records_updated_at BEFORE UPDATE ON public.pest_control_bait_records FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_update_pest_insect_records_updated_at BEFORE UPDATE ON public.pest_control_insect_records FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_set_created_by_pest BEFORE INSERT ON public.pest_controls FOR EACH ROW EXECUTE FUNCTION public.set_created_by_from_auth_pest();

CREATE TRIGGER trigger_update_pest_controls_updated_at BEFORE UPDATE ON public.pest_controls FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_validate_processing BEFORE INSERT OR UPDATE ON public.plant_batch_processing FOR EACH ROW EXECUTE FUNCTION public.validate_processing_totals();

CREATE TRIGGER trg_validate_homo_stock BEFORE INSERT OR UPDATE ON public.plant_homogenization_inputs FOR EACH ROW EXECUTE FUNCTION public.validate_homogenization_stock();

CREATE TRIGGER trigger_auto_assign_plot_code BEFORE INSERT ON public.plots FOR EACH ROW EXECUTE FUNCTION public.auto_assign_plot_code();

CREATE TRIGGER update_plots_updated_at BEFORE UPDATE ON public.plots FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_producers_updated_at BEFORE UPDATE ON public.producers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER validate_producer_module_trigger BEFORE INSERT OR UPDATE ON public.producers FOR EACH ROW EXECUTE FUNCTION public.validate_producer_module();

CREATE TRIGGER set_product_returns_created_by_trigger BEFORE INSERT ON public.product_returns FOR EACH ROW EXECUTE FUNCTION public.set_product_returns_created_by();

CREATE TRIGGER update_product_returns_updated_at BEFORE UPDATE ON public.product_returns FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER validate_product_return_trigger BEFORE INSERT OR UPDATE ON public.product_returns FOR EACH ROW EXECUTE FUNCTION public.validate_product_return();

CREATE TRIGGER initialize_stock_trigger AFTER INSERT ON public.production_batches FOR EACH ROW EXECUTE FUNCTION public.initialize_stock_for_batch();

CREATE TRIGGER set_registered_by_before_insert BEFORE INSERT ON public.production_batches FOR EACH ROW EXECUTE FUNCTION public.set_registered_by_from_auth();

CREATE TRIGGER update_plot_defaults_trigger AFTER INSERT ON public.production_batches FOR EACH ROW EXECUTE FUNCTION public.update_plot_default_percentages();

CREATE TRIGGER update_producer_defaults_trigger AFTER INSERT ON public.production_batches FOR EACH ROW EXECUTE FUNCTION public.update_producer_default_percentages();

CREATE TRIGGER update_production_batches_updated_at BEFORE UPDATE ON public.production_batches FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER validate_production_batch_plot_trigger BEFORE INSERT OR UPDATE ON public.production_batches FOR EACH ROW EXECUTE FUNCTION public.validate_production_batch_plot();

CREATE TRIGGER set_stowage_registered_by_before_insert BEFORE INSERT ON public.stowage_transport_inspections FOR EACH ROW EXECUTE FUNCTION public.set_registered_by_from_auth();

CREATE TRIGGER update_stowage_transport_inspections_updated_at BEFORE UPDATE ON public.stowage_transport_inspections FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER validate_stowage_transport_inspection_trigger BEFORE INSERT OR UPDATE ON public.stowage_transport_inspections FOR EACH ROW EXECUTE FUNCTION public.validate_stowage_transport_inspection();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER set_worker_controls_created_by_trigger BEFORE INSERT ON public.worker_controls FOR EACH ROW EXECUTE FUNCTION public.set_worker_controls_created_by();

CREATE TRIGGER update_worker_controls_updated_at BEFORE UPDATE ON public.worker_controls FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER validate_worker_control_trigger BEFORE INSERT OR UPDATE ON public.worker_controls FOR EACH ROW EXECUTE FUNCTION public.validate_worker_control();


