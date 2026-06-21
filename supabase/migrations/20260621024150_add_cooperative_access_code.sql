-- Agrega el código de acceso de cooperativa a la base de datos.
-- Antes vivía hardcodeado en el .env de la app; ahora se valida contra
-- esta columna vía RPC, sin exponerla nunca por SELECT directo (RLS
-- de "cooperatives" sigue bloqueando anon).

ALTER TABLE public.cooperatives ADD COLUMN access_code text;

ALTER TABLE public.cooperatives
  ADD CONSTRAINT cooperatives_access_code_key UNIQUE (access_code);

CREATE OR REPLACE FUNCTION public.validate_cooperative_access_code(p_access_code text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  matched_code text;
BEGIN
  SELECT code FROM public.cooperatives
  WHERE upper(access_code) = upper(p_access_code)
    AND is_active = true
  INTO matched_code;

  IF matched_code IS NULL THEN
    RETURN jsonb_build_object('success', false);
  END IF;

  RETURN jsonb_build_object('success', true, 'code', matched_code);
END;
$function$
;

GRANT EXECUTE ON FUNCTION public.validate_cooperative_access_code(text) TO anon;
