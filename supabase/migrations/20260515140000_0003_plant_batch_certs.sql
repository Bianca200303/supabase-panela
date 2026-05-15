-- ─────────────────────────────────────────────────────────────────────────────
-- Reemplaza plant_order_certs por plant_batch_certs
-- Las certificaciones pertenecen al lote de planta (plant_production_batch),
-- no a la orden, porque dependen de la materia prima homogenizada en ese lote.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Eliminar tabla anterior (sin datos reales, creada en 0002)
DROP TABLE IF EXISTS "public"."plant_order_certs";

-- 2. Nueva tabla: certificaciones por lote de planta
CREATE TABLE "public"."plant_batch_certs" (
  "id"               uuid not null default gen_random_uuid(),
  "plant_batch_id"   uuid not null,
  "batch_cert_id"    uuid not null,
  "cooperative_id"   uuid not null,
  "created_at"       timestamp with time zone default now(),
  CONSTRAINT "plant_batch_certs_pkey"       PRIMARY KEY (id),
  CONSTRAINT "plant_batch_certs_batch_fkey" FOREIGN KEY (plant_batch_id) REFERENCES public.plant_production_batches(id) ON DELETE CASCADE,
  CONSTRAINT "plant_batch_certs_cert_fkey"  FOREIGN KEY (batch_cert_id)  REFERENCES public.batch_certs(id)             ON DELETE CASCADE,
  CONSTRAINT "plant_batch_certs_unique"     UNIQUE (plant_batch_id, batch_cert_id)
);

ALTER TABLE "public"."plant_batch_certs" ENABLE ROW LEVEL SECURITY;

-- 3. Grants
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."plant_batch_certs" TO "anon";
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."plant_batch_certs" TO "authenticated";
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."plant_batch_certs" TO "service_role";

-- 4. RLS policies
CREATE POLICY "plant_batch_certs_select"
  ON "public"."plant_batch_certs" AS permissive FOR SELECT TO authenticated
  USING ((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role());

CREATE POLICY "plant_batch_certs_insert"
  ON "public"."plant_batch_certs" AS permissive FOR INSERT TO authenticated
  WITH CHECK ((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role());

CREATE POLICY "plant_batch_certs_update"
  ON "public"."plant_batch_certs" AS permissive FOR UPDATE TO authenticated
  USING ((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role())
  WITH CHECK ((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role());

CREATE POLICY "plant_batch_certs_delete"
  ON "public"."plant_batch_certs" AS permissive FOR DELETE TO authenticated
  USING ((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role());
