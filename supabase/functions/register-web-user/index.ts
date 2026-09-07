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
    // Verify caller is authenticated
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
    const { username, password, firstName, lastName, role, cooperativeId } = await req.json();
    if (!username || !password || !firstName || !lastName || !cooperativeId) {
      return new Response(JSON.stringify({
        error: 'Todos los campos son requeridos'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // Verify caller identity via JWT
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
    // Verify caller is an admin_web of the cooperative they are registering into
    const { data: callerProfile } = await supabaseAdmin.from('web_users').select('role, cooperative_id').eq('auth_user_id', callerUser.id).single();
    if (callerProfile?.role !== 'admin_web') {
      return new Response(JSON.stringify({
        error: 'Solo un administrador puede crear usuarios web'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 403
      });
    }
    if (callerProfile.cooperative_id !== cooperativeId) {
      return new Response(JSON.stringify({
        error: 'No puedes registrar usuarios en otra cooperativa'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 403
      });
    }
    // Validate role against known values -- never trust an arbitrary string
    const validRoles = [
      'admin_web',
      'operador'
    ];
    const targetRole = role ?? 'operador';
    if (!validRoles.includes(targetRole)) {
      return new Response(JSON.stringify({
        error: 'Rol inválido. Debe ser admin_web u operador'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // Check username not already taken in this cooperative
    const { data: existing } = await supabaseAdmin.from('web_users').select('id').eq('username', username).eq('cooperative_id', cooperativeId).single();
    if (existing) {
      return new Response(JSON.stringify({
        error: 'El nombre de usuario ya existe en esta cooperativa'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 409
      });
    }
    // Get cooperative code for virtual email
    const { data: cooperative } = await supabaseAdmin.from('cooperatives').select('code').eq('id', cooperativeId).single();
    if (!cooperative) {
      return new Response(JSON.stringify({
        error: 'Cooperativa no encontrada'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 404
      });
    }
    const virtualEmail = `${username}.${cooperative.code}@web.local`;
    // Create auth user
    const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: virtualEmail,
      password,
      email_confirm: true
    });
    if (authError) {
      return new Response(JSON.stringify({
        error: authError.message
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // Create web_user record
    const { error: insertError } = await supabaseAdmin.from('web_users').insert({
      auth_user_id: authUser.user.id,
      cooperative_id: cooperativeId,
      username,
      first_name: firstName,
      last_name: lastName,
      role: targetRole
    });
    if (insertError) {
      // Rollback: delete auth user
      await supabaseAdmin.auth.admin.deleteUser(authUser.user.id);
      return new Response(JSON.stringify({
        error: insertError.message
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    return new Response(JSON.stringify({
      success: true
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
      status: 400
    });
  }
});
