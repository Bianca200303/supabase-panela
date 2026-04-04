import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
serve(async (req)=>{
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({
        error: 'No autorizado'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 401
      });
    }
    const supabaseAdmin = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '');
    // Verify caller identity
    const callerClient = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_ANON_KEY') ?? '', {
      global: {
        headers: {
          Authorization: authHeader
        }
      }
    });
    const { data: { user: callerUser }, error: callerAuthError } = await callerClient.auth.getUser();
    if (callerAuthError || !callerUser) {
      return new Response(JSON.stringify({
        error: 'Token inválido'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 401
      });
    }
    // Verify caller is admin_sistema
    const { data: callerProfile } = await supabaseAdmin.from('users').select('role').eq('auth_user_id', callerUser.id).single();
    if (callerProfile?.role !== 'admin_sistema') {
      return new Response(JSON.stringify({
        error: 'Solo el administrador del sistema puede cambiar roles'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 403
      });
    }
    const { userId, newRole, cooperativeId } = await req.json();
    if (!userId || !newRole || !cooperativeId) {
      return new Response(JSON.stringify({
        error: 'userId, newRole y cooperativeId son requeridos'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    const validRoles = [
      'admin_sistema',
      'admin_modulo',
      'tecnico_campo',
      'productor'
    ];
    if (!validRoles.includes(newRole)) {
      return new Response(JSON.stringify({
        error: 'Rol inválido'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // Prevent admin from changing their own role
    const { data: targetUser } = await supabaseAdmin.from('users').select('auth_user_id').eq('user_id', userId).eq('cooperative_id', cooperativeId).single();
    if (targetUser?.auth_user_id === callerUser.id) {
      return new Response(JSON.stringify({
        error: 'No puedes cambiar tu propio rol'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 403
      });
    }
    const { error: updateError } = await supabaseAdmin.from('users').update({
      role: newRole
    }).eq('user_id', userId).eq('cooperative_id', cooperativeId);
    if (updateError) {
      return new Response(JSON.stringify({
        error: `Error al actualizar rol: ${updateError.message}`
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    return new Response(JSON.stringify({
      message: 'Rol actualizado exitosamente'
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 200
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: error.message
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 500
    });
  }
});
