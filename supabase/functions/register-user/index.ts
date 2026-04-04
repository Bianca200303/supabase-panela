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
    // Parse body first (stream can only be read once)
    const { dni, firstName, lastName, password, cooperativeId, role, coopModuleIds } = await req.json();
    // Get caller's auth user from token
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
    // Verify caller has admin role
    const { data: callerProfileByAuthId } = await supabaseAdmin.from('users').select('role').eq('auth_user_id', callerUser.id).single();
    // Fallback: extract DNI from virtual email (format: DNI.COOPCODE@dni.local)
    let callerProfile = callerProfileByAuthId;
    if (!callerProfile && callerUser.email) {
      const dniFromEmail = callerUser.email.split('.')[0];
      if (/^\d{8}$/.test(dniFromEmail)) {
        const { data: profileByDni } = await supabaseAdmin.from('users').select('role').eq('user_id', dniFromEmail).eq('cooperative_id', cooperativeId).single();
        callerProfile = profileByDni;
      }
    }
    const callerRole = callerProfile?.role;
    if (callerRole !== 'admin_sistema' && callerRole !== 'admin_modulo') {
      return new Response(JSON.stringify({
        error: 'Solo administradores pueden crear usuarios'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 403
      });
    }
    // admin_modulo can only create productor accounts
    if (callerRole === 'admin_modulo' && role !== 'productor') {
      return new Response(JSON.stringify({
        error: 'El administrador de módulo solo puede crear usuarios productores'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 403
      });
    }
    // Validate required fields
    if (!dni || !firstName || !lastName || !password || !cooperativeId || !role) {
      return new Response(JSON.stringify({
        error: 'DNI, nombres, apellidos, contraseña, cooperativa y rol son obligatorios'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // Validate role value
    const validRoles = [
      'admin_sistema',
      'admin_modulo',
      'tecnico_campo',
      'productor'
    ];
    if (!validRoles.includes(role)) {
      return new Response(JSON.stringify({
        error: 'Rol inválido. Debe ser admin_sistema, admin_modulo, tecnico_campo o productor'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // Validate DNI format (8 digits)
    if (!/^\d{8}$/.test(dni)) {
      return new Response(JSON.stringify({
        error: 'El DNI debe tener exactamente 8 dígitos'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // For admin_modulo, require exactly one module
    if (role === 'admin_modulo') {
      if (!coopModuleIds || !Array.isArray(coopModuleIds) || coopModuleIds.length === 0) {
        return new Response(JSON.stringify({
          error: 'Debe asignar exactamente 1 módulo al administrador de módulo'
        }), {
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          },
          status: 400
        });
      }
      if (coopModuleIds.length > 1) {
        return new Response(JSON.stringify({
          error: 'El administrador de módulo solo puede tener 1 módulo asignado'
        }), {
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          },
          status: 400
        });
      }
    }
    // For tecnico_campo, require at least one module
    if (role === 'tecnico_campo') {
      if (!coopModuleIds || !Array.isArray(coopModuleIds) || coopModuleIds.length === 0) {
        return new Response(JSON.stringify({
          error: 'Debe asignar al menos un módulo al técnico de campo'
        }), {
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          },
          status: 400
        });
      }
    }
    // Check if DNI already exists in this cooperative
    const { data: existingUserByDNI } = await supabaseAdmin.from('users').select('user_id').eq('user_id', dni).eq('cooperative_id', cooperativeId).single();
    if (existingUserByDNI) {
      return new Response(JSON.stringify({
        error: 'El DNI ya está registrado en esta cooperativa'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 409
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
    // Create virtual email for DNI user with cooperative code
    const virtualEmail = `${dni}.${cooperativeData.code}@dni.local`;
    // Create user in auth.users with virtual email
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: virtualEmail,
      password: password,
      email_confirm: true
    });
    if (authError) {
      return new Response(JSON.stringify({
        error: `Error al crear autenticación: ${authError.message}`
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // Create user in public.users table
    const { data: userData, error: userError } = await supabaseAdmin.from('users').insert({
      user_id: dni,
      first_name: firstName,
      last_name: lastName,
      email: virtualEmail,
      auth_user_id: authData.user.id,
      cooperative_id: cooperativeId,
      role: role
    }).select().single();
    if (userError) {
      // If user creation fails, delete the auth user
      await supabaseAdmin.auth.admin.deleteUser(authData.user.id);
      return new Response(JSON.stringify({
        error: `Error al crear usuario: ${userError.message}`
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // Insert module assignments for admin_modulo and tecnico_campo
    if ((role === 'admin_modulo' || role === 'tecnico_campo') && coopModuleIds?.length > 0) {
      const assignments = coopModuleIds.map((moduleId)=>({
          user_id: dni,
          cooperative_id: cooperativeId,
          coop_module_id: moduleId
        }));
      const { error: assignError } = await supabaseAdmin.from('user_module_assignments').insert(assignments);
      if (assignError) {
        // Rollback: delete auth user and public user
        await supabaseAdmin.from('users').delete().eq('user_id', dni).eq('cooperative_id', cooperativeId);
        await supabaseAdmin.auth.admin.deleteUser(authData.user.id);
        return new Response(JSON.stringify({
          error: `Error al asignar módulos: ${assignError.message}`
        }), {
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          },
          status: 400
        });
      }
    }
    // Return success
    return new Response(JSON.stringify({
      user_data: userData,
      message: 'Usuario registrado exitosamente'
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 201
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
