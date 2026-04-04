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
    const { username, password, cooperativeId } = await req.json();
    if (!username || !password || !cooperativeId) {
      return new Response(JSON.stringify({
        error: 'Usuario, contraseña y cooperativa son requeridos'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    const supabaseAdmin = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '');
    // Look up web user by username + cooperative
    const { data: webUser, error: userError } = await supabaseAdmin.from('web_users').select('id, auth_user_id, cooperative_id, first_name, last_name, role, is_active').eq('username', username).eq('cooperative_id', cooperativeId).single();
    if (userError || !webUser) {
      return new Response(JSON.stringify({
        error: 'Usuario no encontrado en esta cooperativa'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 401
      });
    }
    if (!webUser.is_active) {
      return new Response(JSON.stringify({
        error: 'Usuario inactivo. Contacte al administrador.'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 403
      });
    }
    // Get cooperative code to build virtual email
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
    // Virtual email: username.COOPCODE@web.local
    const virtualEmail = `${username}.${cooperative.code}@web.local`;
    // Authenticate with Supabase Auth
    const { data: authData, error: authError } = await supabaseAdmin.auth.signInWithPassword({
      email: virtualEmail,
      password
    });
    if (authError) {
      return new Response(JSON.stringify({
        error: 'Contraseña incorrecta'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 401
      });
    }
    return new Response(JSON.stringify({
      access_token: authData.session?.access_token,
      refresh_token: authData.session?.refresh_token,
      user_id: webUser.id,
      username: username,
      first_name: webUser.first_name,
      last_name: webUser.last_name,
      role: webUser.role,
      cooperative_id: webUser.cooperative_id
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
