-- ════════════════════════════════════════════════════════════════════════════
-- FIAE: Formato de Inspección de Ambientes, Equipo y Personal
-- Idempotente: se puede ejecutar varias veces sin error.
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS "public"."formatos_inspeccion_ambientes" (
    "id"              uuid                     DEFAULT gen_random_uuid() NOT NULL,
    "formato_codigo"  character varying(30),
    "cooperative_id"  uuid                     NOT NULL,
    "module_id"       uuid                     NOT NULL,
    "inspection_id"   uuid                     NOT NULL,
    "inspection_date" date                     NOT NULL,
    "emitted_by"      uuid,
    "emitted_by_name" text,
    "emitted_at"      timestamp with time zone,
    "firmantes"       jsonb                    DEFAULT '[]'::jsonb NOT NULL,
    "status"          character varying(20)    DEFAULT 'draft' NOT NULL,
    "created_at"      timestamp with time zone DEFAULT now(),
    CONSTRAINT "fiae_pkey"       PRIMARY KEY ("id"),
    CONSTRAINT "fiae_code_key"   UNIQUE ("formato_codigo"),
    CONSTRAINT "fiae_insp_key"   UNIQUE ("inspection_id"),
    CONSTRAINT "fiae_status_chk" CHECK (status IN ('draft', 'emitted'))
);

ALTER TABLE "public"."formatos_inspeccion_ambientes" OWNER TO "postgres";
COMMENT ON TABLE "public"."formatos_inspeccion_ambientes" IS 'Formatos FIAE: inspección de ambientes, equipo y personal, uno por registro de inspección.';

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fiae_coop_fkey') THEN
    ALTER TABLE ONLY "public"."formatos_inspeccion_ambientes"
      ADD CONSTRAINT "fiae_coop_fkey"
      FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fiae_module_fkey') THEN
    ALTER TABLE ONLY "public"."formatos_inspeccion_ambientes"
      ADD CONSTRAINT "fiae_module_fkey"
      FOREIGN KEY ("module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fiae_inspection_fkey') THEN
    ALTER TABLE ONLY "public"."formatos_inspeccion_ambientes"
      ADD CONSTRAINT "fiae_inspection_fkey"
      FOREIGN KEY ("inspection_id") REFERENCES "public"."environment_inspections"("id") ON DELETE RESTRICT;
  END IF;
END $$;

ALTER TABLE "public"."formatos_inspeccion_ambientes" ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'formatos_inspeccion_ambientes' AND policyname = 'fiae_coop_isolation'
  ) THEN
    CREATE POLICY "fiae_coop_isolation" ON "public"."formatos_inspeccion_ambientes"
      FOR ALL USING (cooperative_id = auth_cooperative_id() OR is_service_role());
  END IF;
END $$;

GRANT ALL ON TABLE "public"."formatos_inspeccion_ambientes" TO "anon";
GRANT ALL ON TABLE "public"."formatos_inspeccion_ambientes" TO "authenticated";
GRANT ALL ON TABLE "public"."formatos_inspeccion_ambientes" TO "service_role";

CREATE OR REPLACE FUNCTION "public"."emit_formato_inspeccion_ambientes"(
    p_coop_code       text,
    p_cooperative_id  uuid,
    p_module_id       uuid,
    p_inspection_id   uuid,
    p_inspection_date date,
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
$$;

ALTER FUNCTION "public"."emit_formato_inspeccion_ambientes"(text, uuid, uuid, uuid, date, uuid, text, jsonb) OWNER TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_inspeccion_ambientes"(text, uuid, uuid, uuid, date, uuid, text, jsonb) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_inspeccion_ambientes"(text, uuid, uuid, uuid, date, uuid, text, jsonb) TO "service_role";
