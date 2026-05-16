-- ─────────────────────────────────────────────────────────────────────────────
-- Status de certificación del productor, registrado en el momento de recepción
-- de materia prima. Input libre por ahora; seleccionable en futuras versiones.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE "public"."exit_reception_items"
  ADD COLUMN IF NOT EXISTS "cert_status" text;
