-- ════════════════════════════════════════════════════════════════════════════
-- Limpieza y Desinfección — reestructuración del tipo de limpieza
-- Ejecutar en Supabase SQL Editor para la instancia existente.
-- Idempotente: se puede ejecutar varias veces sin error.
-- ════════════════════════════════════════════════════════════════════════════

-- 1. Eliminar columna cleaning_type singular (si todavía existe de una migración anterior)
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'cleaning_disinfections'
      AND column_name  = 'cleaning_type'
  ) THEN
    ALTER TABLE "public"."cleaning_disinfections" DROP COLUMN "cleaning_type";
  END IF;
END $$;

-- 2. Agregar columna cleaning_types TEXT[] (array de tipos)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'cleaning_disinfections'
      AND column_name  = 'cleaning_types'
  ) THEN
    ALTER TABLE "public"."cleaning_disinfections"
      ADD COLUMN "cleaning_types" text[] NOT NULL DEFAULT ARRAY['daily']::text[];
    ALTER TABLE "public"."cleaning_disinfections"
      ALTER COLUMN "cleaning_types" DROP DEFAULT;
    ALTER TABLE "public"."cleaning_disinfections"
      ADD CONSTRAINT "cleaning_disinfections_types_chk"
      CHECK (cleaning_types <@ ARRAY['daily','general','deep']::text[] AND array_length(cleaning_types, 1) > 0);
  END IF;
END $$;

-- 3. Eliminar UNIQUE (module, date, type) si existe
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'cleaning_disinfections_module_date_type_key'
  ) THEN
    ALTER TABLE "public"."cleaning_disinfections"
      DROP CONSTRAINT "cleaning_disinfections_module_date_type_key";
  END IF;
END $$;

-- 4. Agregar UNIQUE (coop_module_id, cleaning_date) — una sesión por módulo por día
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'cleaning_disinfections_module_date_key'
  ) THEN
    ALTER TABLE "public"."cleaning_disinfections"
      ADD CONSTRAINT "cleaning_disinfections_module_date_key"
      UNIQUE (coop_module_id, cleaning_date);
  END IF;
END $$;

-- 5. Eliminar columnas de tipo de limpieza de cleaning_disinfection_items (si aún existen)
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'cleaning_disinfection_items'
      AND column_name  = 'is_daily_cleaning'
  ) THEN
    ALTER TABLE "public"."cleaning_disinfection_items"
      DROP COLUMN IF EXISTS "is_daily_cleaning",
      DROP COLUMN IF EXISTS "is_general_cleaning",
      DROP COLUMN IF EXISTS "is_deep_cleaning";
  END IF;
END $$;
