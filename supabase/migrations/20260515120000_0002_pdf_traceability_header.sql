-- ─────────────────────────────────────────────────────────────────────────────
-- PDF de trazabilidad de contenedor
-- Encabezado: cliente (importador), número de venta, certificaciones por orden
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Nuevas columnas en plant_orders
ALTER TABLE "public"."plant_orders"
  ADD COLUMN IF NOT EXISTS "customer_name" text,
  ADD COLUMN IF NOT EXISTS "sale_number"   text;

-- 2. Tabla de certificaciones por orden de planta
CREATE TABLE "public"."plant_order_certs" (
  "id"             uuid not null default gen_random_uuid(),
  "order_id"       uuid not null,
  "batch_cert_id"  uuid not null,
  "cooperative_id" uuid not null,
  "created_at"     timestamp with time zone default now(),
  CONSTRAINT "plant_order_certs_pkey"           PRIMARY KEY (id),
  CONSTRAINT "plant_order_certs_order_fkey"     FOREIGN KEY (order_id)      REFERENCES public.plant_orders(id)  ON DELETE CASCADE,
  CONSTRAINT "plant_order_certs_cert_fkey"      FOREIGN KEY (batch_cert_id) REFERENCES public.batch_certs(id)   ON DELETE CASCADE,
  CONSTRAINT "plant_order_certs_unique"         UNIQUE (order_id, batch_cert_id)
);

ALTER TABLE "public"."plant_order_certs" ENABLE ROW LEVEL SECURITY;

-- 3. Grants
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."plant_order_certs" TO "anon";
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."plant_order_certs" TO "authenticated";
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."plant_order_certs" TO "service_role";

-- 4. RLS policies
CREATE POLICY "plant_order_certs_select"
  ON "public"."plant_order_certs" AS permissive FOR SELECT TO authenticated
  USING ((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role());

CREATE POLICY "plant_order_certs_insert"
  ON "public"."plant_order_certs" AS permissive FOR INSERT TO authenticated
  WITH CHECK ((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role());

CREATE POLICY "plant_order_certs_update"
  ON "public"."plant_order_certs" AS permissive FOR UPDATE TO authenticated
  USING ((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role())
  WITH CHECK ((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role());

CREATE POLICY "plant_order_certs_delete"
  ON "public"."plant_order_certs" AS permissive FOR DELETE TO authenticated
  USING ((cooperative_id = public.auth_cooperative_id()) OR public.is_service_role());
