-- ════════════════════════════════════════════════════════════════════════════
-- FCP: Formato de Control de Plagas
-- Idempotente: se puede ejecutar varias veces sin error.
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS "public"."formatos_control_plagas" (
    "id"              uuid                     DEFAULT gen_random_uuid() NOT NULL,
    "formato_codigo"  character varying(30),
    "cooperative_id"  uuid                     NOT NULL,
    "module_id"       uuid                     NOT NULL,
    "date_from"       date                     NOT NULL,
    "date_to"         date                     NOT NULL,
    "emitted_by"      uuid,
    "emitted_by_name" text,
    "emitted_at"      timestamp with time zone,
    "firmantes"       jsonb                    DEFAULT '[]'::jsonb NOT NULL,
    "status"          character varying(20)    DEFAULT 'draft' NOT NULL,
    "created_at"      timestamp with time zone DEFAULT now(),
    CONSTRAINT "fcp_pkey"       PRIMARY KEY ("id"),
    CONSTRAINT "fcp_code_key"   UNIQUE ("formato_codigo"),
    CONSTRAINT "fcp_status_chk" CHECK (status IN ('draft', 'emitted'))
);

ALTER TABLE "public"."formatos_control_plagas" OWNER TO "postgres";
COMMENT ON TABLE "public"."formatos_control_plagas" IS 'Formatos FCP: control de plagas por módulo y período.';

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fcp_coop_fkey') THEN
    ALTER TABLE ONLY "public"."formatos_control_plagas"
      ADD CONSTRAINT "fcp_coop_fkey"
      FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fcp_module_fkey') THEN
    ALTER TABLE ONLY "public"."formatos_control_plagas"
      ADD CONSTRAINT "fcp_module_fkey"
      FOREIGN KEY ("module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;
  END IF;
END $$;

ALTER TABLE "public"."formatos_control_plagas" ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'formatos_control_plagas' AND policyname = 'fcp_coop_isolation'
  ) THEN
    CREATE POLICY "fcp_coop_isolation" ON "public"."formatos_control_plagas"
      FOR ALL USING (cooperative_id = auth_cooperative_id() OR is_service_role());
  END IF;
END $$;

GRANT ALL ON TABLE "public"."formatos_control_plagas" TO "anon";
GRANT ALL ON TABLE "public"."formatos_control_plagas" TO "authenticated";
GRANT ALL ON TABLE "public"."formatos_control_plagas" TO "service_role";

CREATE OR REPLACE FUNCTION "public"."emit_formato_control_plagas"(
    p_coop_code       text,
    p_cooperative_id  uuid,
    p_module_id       uuid,
    p_date_from       date,
    p_date_to         date,
    p_emitted_by      uuid,
    p_emitted_by_name text,
    p_firmantes       jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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
$$;

ALTER FUNCTION "public"."emit_formato_control_plagas"(text, uuid, uuid, date, date, uuid, text, jsonb) OWNER TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_control_plagas"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_control_plagas"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "service_role";
