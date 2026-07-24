-- Formulario de Control de Objetos Extraños (detector de metales durante
-- envasado). No es un "formato oficial" como FQD/FCPO (no se emite ningún
-- documento con código, no lleva firmantes) -- es solo un registro interno
-- por lote de envasado, que se va completando con inspecciones periódicas
-- durante el día hasta que el responsable lo da por terminado.
--
-- Cada inspección registra dos cosas independientes:
--  1) Si se separó alguna bolsa de la producción real (bags_separated).
--  2) El resultado de UNA prueba de calibración del detector con una pieza
--     de test (test_type: F / NF / AI), con su propio conforme/no conforme
--     -- esto se marca sí o sí, incluso si hubo rechazo de bolsas, porque
--     es la conformidad del EQUIPO, no de la producción.
--
-- Solo se completa desde la web (no aplica a la app móvil).

create table "public"."plant_batch_foreign_object_forms" (
  "id" uuid not null default gen_random_uuid(),
  "cooperative_id" uuid not null,
  "plant_batch_id" uuid not null,
  "control_date" date not null default CURRENT_DATE,
  "status" text not null default 'en_progreso',
  "responsible_person" text not null,
  "final_observations" text,
  "created_by" uuid not null,
  "closed_by" uuid,
  "closed_at" timestamp with time zone,
  "created_at" timestamp with time zone default now(),
  "updated_at" timestamp with time zone default now()
);

alter table "public"."plant_batch_foreign_object_forms" enable row level security;

alter table "public"."plant_batch_foreign_object_forms"
  add constraint "plant_batch_foreign_object_forms_pkey" primary key ("id");

alter table "public"."plant_batch_foreign_object_forms"
  add constraint "pbfof_status_check" check (status in ('en_progreso', 'terminado'));

alter table "public"."plant_batch_foreign_object_forms"
  add constraint "pbfof_plant_batch_id_fkey" foreign key (plant_batch_id) references public.plant_production_batches(id) on delete cascade;

alter table "public"."plant_batch_foreign_object_forms"
  add constraint "pbfof_cooperative_id_fkey" foreign key (cooperative_id) references public.cooperatives(id);

alter table "public"."plant_batch_foreign_object_forms"
  add constraint "pbfof_created_by_fkey" foreign key (created_by) references public.web_users(id);

alter table "public"."plant_batch_foreign_object_forms"
  add constraint "pbfof_closed_by_fkey" foreign key (closed_by) references public.web_users(id);

-- Un lote de envasado tiene a lo sumo un formulario por día.
alter table "public"."plant_batch_foreign_object_forms"
  add constraint "pbfof_unique_batch_date" unique (plant_batch_id, control_date);

create index "idx_pbfof_plant_batch" on "public"."plant_batch_foreign_object_forms" using btree (plant_batch_id);
create index "idx_pbfof_cooperative" on "public"."plant_batch_foreign_object_forms" using btree (cooperative_id);


create table "public"."plant_batch_foreign_object_checks" (
  "id" uuid not null default gen_random_uuid(),
  "form_id" uuid not null,
  "inspection_number" integer not null,
  "check_time" time without time zone not null,
  "bags_separated" integer not null default 0,
  "test_type" text not null,
  "conforme" boolean not null,
  "created_by" uuid not null,
  "created_at" timestamp with time zone default now()
);

alter table "public"."plant_batch_foreign_object_checks" enable row level security;

alter table "public"."plant_batch_foreign_object_checks"
  add constraint "plant_batch_foreign_object_checks_pkey" primary key ("id");

alter table "public"."plant_batch_foreign_object_checks"
  add constraint "pbfoc_form_id_fkey" foreign key (form_id) references public.plant_batch_foreign_object_forms(id) on delete cascade;

alter table "public"."plant_batch_foreign_object_checks"
  add constraint "pbfoc_created_by_fkey" foreign key (created_by) references public.web_users(id);

alter table "public"."plant_batch_foreign_object_checks"
  add constraint "pbfoc_test_type_check" check (test_type in ('F', 'NF', 'AI'));

alter table "public"."plant_batch_foreign_object_checks"
  add constraint "pbfoc_bags_separated_check" check (bags_separated >= 0);

alter table "public"."plant_batch_foreign_object_checks"
  add constraint "pbfoc_unique_form_inspection" unique (form_id, inspection_number);

create index "idx_pbfoc_form" on "public"."plant_batch_foreign_object_checks" using btree (form_id);


-- El número de inspección se asigna solo (correlativo dentro de su
-- formulario), no lo manda el cliente -- así nunca queda pisado ni
-- desincronizado aunque dos personas guarden casi al mismo tiempo.
CREATE OR REPLACE FUNCTION public.set_foreign_object_check_number()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  SELECT COALESCE(MAX(inspection_number), 0) + 1
  INTO NEW.inspection_number
  FROM plant_batch_foreign_object_checks
  WHERE form_id = NEW.form_id;

  RETURN NEW;
END;
$function$;

CREATE TRIGGER trg_set_foreign_object_check_number
  BEFORE INSERT ON public.plant_batch_foreign_object_checks
  FOR EACH ROW EXECUTE FUNCTION public.set_foreign_object_check_number();


-- created_by se completa solo a partir del usuario web autenticado -- este
-- formulario es exclusivamente web, no hace falta contemplar usuarios de
-- la app móvil como sí pasa en product_returns.
CREATE OR REPLACE FUNCTION public.set_created_by_foreign_object_web_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF NEW.created_by IS NULL THEN
    SELECT id INTO NEW.created_by FROM web_users WHERE auth_user_id = auth.uid();
    IF NEW.created_by IS NULL THEN
      RAISE EXCEPTION 'No se encontró usuario web autenticado para la sesión actual';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER trg_set_created_by_pbfof
  BEFORE INSERT ON public.plant_batch_foreign_object_forms
  FOR EACH ROW EXECUTE FUNCTION public.set_created_by_foreign_object_web_user();

CREATE TRIGGER trg_set_created_by_pbfoc
  BEFORE INSERT ON public.plant_batch_foreign_object_checks
  FOR EACH ROW EXECUTE FUNCTION public.set_created_by_foreign_object_web_user();

CREATE TRIGGER trg_update_pbfof_updated_at
  BEFORE UPDATE ON public.plant_batch_foreign_object_forms
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


-- RLS -- mismo criterio ya usado en toda la app (aislado por cooperativa,
-- vía el claim del JWT, no por lookup de tabla).
create policy "pbfof_select" on "public"."plant_batch_foreign_object_forms"
  as permissive for select to authenticated
  using (cooperative_id = public.auth_cooperative_id() or public.is_service_role());

create policy "pbfof_insert" on "public"."plant_batch_foreign_object_forms"
  as permissive for insert to authenticated
  with check (cooperative_id = public.auth_cooperative_id() or public.is_service_role());

create policy "pbfof_update" on "public"."plant_batch_foreign_object_forms"
  as permissive for update to authenticated
  using (cooperative_id = public.auth_cooperative_id() or public.is_service_role())
  with check (cooperative_id = public.auth_cooperative_id() or public.is_service_role());

create policy "pbfoc_select" on "public"."plant_batch_foreign_object_checks"
  as permissive for select to authenticated
  using (
    exists (
      select 1 from plant_batch_foreign_object_forms f
      where f.id = form_id and (f.cooperative_id = public.auth_cooperative_id() or public.is_service_role())
    )
  );

create policy "pbfoc_insert" on "public"."plant_batch_foreign_object_checks"
  as permissive for insert to authenticated
  with check (
    exists (
      select 1 from plant_batch_foreign_object_forms f
      where f.id = form_id and (f.cooperative_id = public.auth_cooperative_id() or public.is_service_role())
    )
  );
