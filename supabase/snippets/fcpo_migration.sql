-- ════════════════════════════════════════════════════════════════════════════
-- FORMATO DE CONTROL DE PERSONAL OPERARIO (FCPO)
-- Idempotente: se puede ejecutar varias veces sin error.
-- ════════════════════════════════════════════════════════════════════════════

-- 1. Tabla principal
CREATE TABLE IF NOT EXISTS "public"."formatos_control_personal" (
    "id"                  uuid                     DEFAULT gen_random_uuid() NOT NULL,
    "formato_codigo"      character varying(30),
    "cooperative_id"      uuid                     NOT NULL,
    "production_batch_id" uuid                     NOT NULL,
    "emitted_by"          uuid,
    "emitted_by_name"     text,
    "emitted_at"          timestamp with time zone,
    "firmantes"           jsonb                    DEFAULT '[]'::jsonb NOT NULL,
    "status"              character varying(20)    DEFAULT 'draft' NOT NULL,
    "created_at"          timestamp with time zone DEFAULT now(),
    CONSTRAINT "fcpo_pkey"            PRIMARY KEY ("id"),
    CONSTRAINT "fcpo_unique_batch"    UNIQUE ("cooperative_id", "production_batch_id"),
    CONSTRAINT "fcpo_codigo_key"      UNIQUE ("formato_codigo"),
    CONSTRAINT "fcpo_status_check"    CHECK (status IN ('draft', 'emitted'))
);

ALTER TABLE "public"."formatos_control_personal" OWNER TO "postgres";
COMMENT ON TABLE "public"."formatos_control_personal" IS 'Formatos FCPO: control de personal operario por lote de campo.';

-- 2. FKs (idempotentes)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fcpo_cooperative_fkey') THEN
    ALTER TABLE ONLY "public"."formatos_control_personal"
      ADD CONSTRAINT "fcpo_cooperative_fkey"
      FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fcpo_batch_fkey') THEN
    ALTER TABLE ONLY "public"."formatos_control_personal"
      ADD CONSTRAINT "fcpo_batch_fkey"
      FOREIGN KEY ("production_batch_id") REFERENCES "public"."production_batches"("id") ON DELETE RESTRICT;
  END IF;
END $$;

-- 3. RLS
ALTER TABLE "public"."formatos_control_personal" ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'formatos_control_personal' AND policyname = 'fcpo_coop_isolation'
  ) THEN
    CREATE POLICY "fcpo_coop_isolation" ON "public"."formatos_control_personal"
      FOR ALL USING (cooperative_id = auth_cooperative_id() OR is_service_role());
  END IF;
END $$;

-- 4. Grants
GRANT ALL ON TABLE "public"."formatos_control_personal" TO "anon";
GRANT ALL ON TABLE "public"."formatos_control_personal" TO "authenticated";
GRANT ALL ON TABLE "public"."formatos_control_personal" TO "service_role";

-- 5. RPC: emit_formato_control_personal
CREATE OR REPLACE FUNCTION "public"."emit_formato_control_personal"(
    p_coop_code       text,
    p_cooperative_id  uuid,
    p_batch_id        uuid,
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
$$;

ALTER FUNCTION "public"."emit_formato_control_personal"(text, uuid, uuid, uuid, text, jsonb) OWNER TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_control_personal"(text, uuid, uuid, uuid, text, jsonb) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_control_personal"(text, uuid, uuid, uuid, text, jsonb) TO "service_role";
