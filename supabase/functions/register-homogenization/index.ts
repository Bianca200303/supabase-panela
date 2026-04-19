import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
serve(async (req)=>{
  if (req.method === 'OPTIONS') return new Response('ok', {
    headers: corsHeaders
  });
  try {
    // ── 0. Verificar autenticación ───────────────────────────────────────────
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return error(401, 'No autorizado');

    const supabase = createClient(Deno.env.get('SUPABASE_URL'), Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'));

    // Verify caller identity via JWT
    const callerClient = createClient(Deno.env.get('SUPABASE_URL'), Deno.env.get('SUPABASE_ANON_KEY'), {
      global: { headers: { Authorization: authHeader } }
    });
    const { data: { user: callerUser }, error: callerAuthError } = await callerClient.auth.getUser();
    if (callerAuthError || !callerUser) return error(401, 'Token inválido');

    const { plant_batch_id, inputs, cooperative_id } = await req.json();

    // Verify caller belongs to the declared cooperative
    const { data: callerProfile } = await supabase
      .from('web_users')
      .select('cooperative_id')
      .eq('auth_user_id', callerUser.id)
      .single();
    if (!callerProfile || callerProfile.cooperative_id !== cooperative_id) {
      return error(403, 'No tienes acceso a esta cooperativa');
    }

    // ── 1. Validar que el lote de planta existe ──────────────────────────────
    const { data: plantBatch, error: batchErr } = await supabase.from('plant_production_batches').select('id, unit_weight_kg, planned_quantity, status, cooperative_id').eq('id', plant_batch_id).eq('cooperative_id', cooperative_id).single();
    if (batchErr || !plantBatch) return error(404, 'El lote de producción no existe');
    if (plantBatch.status === 'procesado') return error(400, 'El lote ya fue procesado y no puede modificarse');
    // ── 2. Validar que los inputs tienen kg > 0 ──────────────────────────────
    if (!inputs || inputs.length === 0) return error(400, 'Debe indicar al menos un lote de origen');
    for (const input of inputs){
      if (!input.source_exit_item_id) return error(400, 'Cada entrada debe tener un lote de origen válido');
      if (!input.quantity_kg || input.quantity_kg <= 0) return error(400, 'Los kg usados deben ser mayores a 0');
    }
    // ── 3. Validar total mezclado ≤ kg planificados ──────────────────────────
    const plannedKg = plantBatch.unit_weight_kg * plantBatch.planned_quantity;
    const totalMixed = inputs.reduce((s, h)=>s + Number(h.quantity_kg), 0);
    if (totalMixed > plannedKg + 0.01) return error(400, `La suma de kg usados en la mezcla (${totalMixed.toFixed(1)} kg) supera ` + `el total planificado para este lote (${plannedKg.toFixed(1)} kg)`);
    // ── 4. Validar stock disponible por cada lote de origen ──────────────────
    for (const input of inputs){
      const { data: recItem } = await supabase.from('exit_reception_items').select('quantity_kg_received').eq('exit_item_id', input.source_exit_item_id).single();
      if (!recItem) return error(404, `El lote de origen ${input.source_exit_item_id} no existe en el sistema`);
      const { data: usedRows } = await supabase.from('plant_homogenization_inputs').select('quantity_kg').eq('source_exit_item_id', input.source_exit_item_id).neq('plant_batch_id', plant_batch_id);
      const alreadyUsed = (usedRows ?? []).reduce((s, r)=>s + Number(r.quantity_kg), 0);
      const available = Number(recItem.quantity_kg_received) - alreadyUsed;
      if (input.quantity_kg > available + 0.01) return error(400, `El lote de origen no tiene suficiente cantidad disponible — ` + `disponible: ${available.toFixed(1)} kg, solicitado: ${input.quantity_kg.toFixed(1)} kg`);
    }
    // ── 5. Guardar (eliminar anteriores + insertar nuevos) ───────────────────
    await supabase.from('plant_homogenization_inputs').delete().eq('plant_batch_id', plant_batch_id);
    const { error: insErr } = await supabase.from('plant_homogenization_inputs').insert(inputs.map((h)=>({
        plant_batch_id,
        source_exit_item_id: h.source_exit_item_id,
        quantity_kg: Number(h.quantity_kg),
        cooperative_id
      })));
    if (insErr) throw new Error(insErr.message);
    await supabase.from('plant_production_batches').update({
      status: 'homogenizado'
    }).eq('id', plant_batch_id);
    return new Response(JSON.stringify({
      ok: true
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  } catch (err) {
    return error(500, err.message);
  }
});
function error(status, message) {
  return new Response(JSON.stringify({
    error: message
  }), {
    status,
    headers: {
      'Content-Type': 'application/json'
    }
  });
}
