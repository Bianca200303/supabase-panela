import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Punto de entrada para que un sistema EXTERNO (no nuestra app) consulte
// datos nuestros. No usa login de usuario -- el externo no tiene cuenta acá
// -- se autentica con una API key propia (EXTERNAL_API_KEY), guardada como
// secreto de esta función y totalmente distinta de las keys de Supabase
// (anon / service_role). Si esa key se filtra, se revoca sin tocar nada más
// del sistema.
//
// El service_role se usa SOLO adentro de esta función -- nunca llega al
// llamador externo. Lo único que sale es lo que arma explícitamente el
// SELECT de más abajo: nunca las tablas completas.
//
// La base de datos es compartida por las 2 cooperativas (fila con
// cooperative_id, no un proyecto de Supabase por cooperativa) -- así que
// CUALQUIER consulta acá tiene que filtrar por cooperative_id o devuelve
// datos de ambas mezclados. Como el llamador es un sistema externo (no un
// usuario con JWT), no hay auth_cooperative_id() disponible -- en su lugar,
// cada deploy de esta función fija su propia cooperativa vía el secreto
// COOPERATIVE_ID (mismo patrón que VITE_COOPERATIVE_ID en el frontend: un
// deploy = una cooperativa).
//
// El SELECT de ejemplo es un placeholder -- reemplazarlo por la consulta
// real una vez que se sepa exactamente qué datos necesita el otro sistema,
// pero el .eq('cooperative_id', cooperativeId) de abajo tiene que quedarse
// en cualquier consulta que lo reemplace.

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'x-api-key, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    // ── Autenticación: API key propia del sistema externo ──────────────────
    const apiKey = req.headers.get('x-api-key');
    const expectedKey = Deno.env.get('EXTERNAL_API_KEY');
    if (!expectedKey) return error(500, 'Falta configurar el secreto EXTERNAL_API_KEY en esta función');
    if (!apiKey || apiKey !== expectedKey) return error(401, 'API key inválida o faltante');

    const cooperativeId = Deno.env.get('COOPERATIVE_ID');
    if (!cooperativeId) return error(500, 'Falta configurar el secreto COOPERATIVE_ID en esta función');

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL'),
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),
    );

    // ── Placeholder: reemplazar por la consulta real cuando se defina ──────
    // Ejemplo: solo órdenes completadas, con una forma curada (no la tabla
    // completa ni columnas internas). El filtro por cooperative_id es
    // obligatorio en cualquier consulta que reemplace a esta.
    const { data, error: dbErr } = await supabase
      .from('plant_orders')
      .select('order_code, market, status, total_kg')
      .eq('status', 'completado')
      .eq('cooperative_id', cooperativeId);

    if (dbErr) throw new Error(dbErr.message);

    return new Response(JSON.stringify({ data }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return error(500, err.message);
  }
});

function error(status: number, message: string) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
