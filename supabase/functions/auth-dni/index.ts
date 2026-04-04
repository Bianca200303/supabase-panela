import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
serve(async (req)=>{
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  try {
    const { identifier, password, cooperativeId } = await req.json();
    // Validate required fields
    if (!cooperativeId) {
      return new Response(JSON.stringify({
        error: 'ID de cooperativa requerido'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // Create Supabase client
    const supabaseAdmin = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '');
    // Determine if identifier is DNI (8 digits) or email
    const isDNI = /^\d{8}$/.test(identifier);
    let email = identifier;
    let userData = null;
    if (isDNI) {
      // Look up user by DNI and validate cooperative
      const { data: dniUserData, error: userError } = await supabaseAdmin.from('users').select('user_id, cooperative_id, role, first_name, last_name').eq('user_id', identifier).eq('cooperative_id', cooperativeId).single();
      userData = dniUserData;
      if (userError || !userData) {
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
      // Get cooperative code for virtual email
      const { data: cooperativeData, error: cooperativeError } = await supabaseAdmin.from('cooperatives').select('code').eq('id', cooperativeId).single();
      if (cooperativeError || !cooperativeData) {
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
      // For DNI login, create virtual email with cooperative code
      email = `${identifier}.${cooperativeData.code}@dni.local`;
    } else {
      // For email login, also validate cooperative membership
      const { data: emailUserData } = await supabaseAdmin.from('users').select('cooperative_id').eq('email', identifier).single();
      if (emailUserData && emailUserData.cooperative_id !== cooperativeId) {
        return new Response(JSON.stringify({
          error: 'Usuario no pertenece a esta cooperativa',
          code: 'WRONG_COOPERATIVE'
        }), {
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          },
          status: 403
        });
      }
    }
    // Try to authenticate with Supabase Auth
    const { data: authData, error: authError } = await supabaseAdmin.auth.signInWithPassword({
      email,
      password
    });
    if (authError) {
      // If user doesn't exist in auth.users but exists in public.users (DNI case)
      if (isDNI && authError.message.includes('Invalid login credentials')) {
        return new Response(JSON.stringify({
          error: 'Usuario no configurado para login. Contacte al administrador.',
          code: 'DNI_USER_NOT_SETUP'
        }), {
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          },
          status: 401
        });
      }
      return new Response(JSON.stringify({
        error: authError.message
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 401
      });
    }
    // Fetch full user profile (role, names) for the response
    const { data: profileByAuthId } = await supabaseAdmin.from('users').select('user_id, cooperative_id, role, first_name, last_name').eq('auth_user_id', authData.user.id).single();
    // For DNI login: fall back to userData from the initial lookup if profileByAuthId is null
    // This handles cases where auth_user_id may be mismatched
    const profileData = profileByAuthId ?? (isDNI ? userData : null);
    // Fetch assigned module IDs for this user (many-to-many)
    let moduleIds = [];
    if (profileData) {
      const { data: moduleData } = await supabaseAdmin.from('user_module_assignments').select('coop_module_id').eq('user_id', profileData.user_id).eq('cooperative_id', profileData.cooperative_id);
      moduleIds = moduleData?.map((m)=>m.coop_module_id) ?? [];
    }
    // Return tokens for client to set session
    return new Response(JSON.stringify({
      access_token: authData.session?.access_token,
      refresh_token: authData.session?.refresh_token,
      user: authData.user,
      user_id: isDNI ? identifier : null,
      role: profileData?.role ?? 'productor',
      first_name: profileData?.first_name ?? null,
      last_name: profileData?.last_name ?? null,
      coop_module_ids: moduleIds
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
