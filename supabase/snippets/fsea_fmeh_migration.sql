-- ════════════════════════════════════════════════════════════════════════════
-- FSEA + FMEH — ejecutar en Supabase SQL Editor para la instancia existente
-- Idempotente: se puede ejecutar varias veces sin error.
-- ════════════════════════════════════════════════════════════════════════════

-- ── FSEA: Formato de Seguimiento de Enfermedades y Accidentes ────────────────

CREATE TABLE IF NOT EXISTS "public"."formatos_seguimiento_salud" (
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
    CONSTRAINT "fsea_pkey"       PRIMARY KEY ("id"),
    CONSTRAINT "fsea_code_key"   UNIQUE ("formato_codigo"),
    CONSTRAINT "fsea_status_chk" CHECK (status IN ('draft', 'emitted'))
);

ALTER TABLE "public"."formatos_seguimiento_salud" OWNER TO "postgres";
COMMENT ON TABLE "public"."formatos_seguimiento_salud" IS 'Formatos FSEA: seguimiento de enfermedades y accidentes por módulo y período.';

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fsea_coop_fkey') THEN
    ALTER TABLE ONLY "public"."formatos_seguimiento_salud"
      ADD CONSTRAINT "fsea_coop_fkey"
      FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fsea_module_fkey') THEN
    ALTER TABLE ONLY "public"."formatos_seguimiento_salud"
      ADD CONSTRAINT "fsea_module_fkey"
      FOREIGN KEY ("module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;
  END IF;
END $$;

ALTER TABLE "public"."formatos_seguimiento_salud" ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'formatos_seguimiento_salud' AND policyname = 'fsea_coop_isolation'
  ) THEN
    CREATE POLICY "fsea_coop_isolation" ON "public"."formatos_seguimiento_salud"
      FOR ALL USING (cooperative_id = auth_cooperative_id() OR is_service_role());
  END IF;
END $$;

GRANT ALL ON TABLE "public"."formatos_seguimiento_salud" TO "anon";
GRANT ALL ON TABLE "public"."formatos_seguimiento_salud" TO "authenticated";
GRANT ALL ON TABLE "public"."formatos_seguimiento_salud" TO "service_role";

CREATE OR REPLACE FUNCTION "public"."emit_formato_seguimiento_salud"(
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
$$;

ALTER FUNCTION "public"."emit_formato_seguimiento_salud"(text, uuid, uuid, date, date, uuid, text, jsonb) OWNER TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_seguimiento_salud"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_seguimiento_salud"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "service_role";


-- ── FMEH: Formato de Mantenimiento de Equipos y Hornillas ────────────────────

CREATE TABLE IF NOT EXISTS "public"."formatos_mantenimiento_equipos" (
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
    CONSTRAINT "fmeh_pkey"       PRIMARY KEY ("id"),
    CONSTRAINT "fmeh_code_key"   UNIQUE ("formato_codigo"),
    CONSTRAINT "fmeh_status_chk" CHECK (status IN ('draft', 'emitted'))
);

ALTER TABLE "public"."formatos_mantenimiento_equipos" OWNER TO "postgres";
COMMENT ON TABLE "public"."formatos_mantenimiento_equipos" IS 'Formatos FMEH: mantenimiento de equipos y hornillas por módulo y período.';

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fmeh_coop_fkey') THEN
    ALTER TABLE ONLY "public"."formatos_mantenimiento_equipos"
      ADD CONSTRAINT "fmeh_coop_fkey"
      FOREIGN KEY ("cooperative_id") REFERENCES "public"."cooperatives"("id") ON DELETE RESTRICT;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fmeh_module_fkey') THEN
    ALTER TABLE ONLY "public"."formatos_mantenimiento_equipos"
      ADD CONSTRAINT "fmeh_module_fkey"
      FOREIGN KEY ("module_id") REFERENCES "public"."coop_modules"("id") ON DELETE RESTRICT;
  END IF;
END $$;

ALTER TABLE "public"."formatos_mantenimiento_equipos" ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'formatos_mantenimiento_equipos' AND policyname = 'fmeh_coop_isolation'
  ) THEN
    CREATE POLICY "fmeh_coop_isolation" ON "public"."formatos_mantenimiento_equipos"
      FOR ALL USING (cooperative_id = auth_cooperative_id() OR is_service_role());
  END IF;
END $$;

GRANT ALL ON TABLE "public"."formatos_mantenimiento_equipos" TO "anon";
GRANT ALL ON TABLE "public"."formatos_mantenimiento_equipos" TO "authenticated";
GRANT ALL ON TABLE "public"."formatos_mantenimiento_equipos" TO "service_role";

CREATE OR REPLACE FUNCTION "public"."emit_formato_mantenimiento_equipos"(
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
$$;

ALTER FUNCTION "public"."emit_formato_mantenimiento_equipos"(text, uuid, uuid, date, date, uuid, text, jsonb) OWNER TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_mantenimiento_equipos"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."emit_formato_mantenimiento_equipos"(text, uuid, uuid, date, date, uuid, text, jsonb) TO "service_role";
