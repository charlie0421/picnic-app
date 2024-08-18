import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';
serve(async (req)=>{
  const { nickname } = await req.json();
  const authHeader = req.headers.get('Authorization');
  const supabase = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_ANON_KEY') ?? '', {
    global: {
      headers: {
        Authorization: authHeader
      }
    }
  });
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return new Response(JSON.stringify({
      error: 'Unauthorized'
    }), {
      status: 401
    });
  }
  const { data: existingUser, error: checkError } = await supabase.from('user_profiles').select('id').neq('id', user.id).ilike('nickname', nickname.trim()).maybeSingle();
  if (checkError) {
    return new Response(JSON.stringify({
      error: 'Error checking nickname'
    }), {
      status: 500
    });
  }
  if (existingUser) {
    return new Response(JSON.stringify({
      error: 'Nickname already exists'
    }), {
      status: 400
    });
  }
  const { data, error: updateError } = await supabase.from('user_profiles').update({
    nickname: nickname.trim()
  }).eq('id', user.id).select().single();
  if (updateError) {
    return new Response(JSON.stringify({
      error: 'Error updating nickname'
    }), {
      status: 500
    });
  }
  return new Response(JSON.stringify({
    success: true,
    data
  }), {
    status: 200
  });
});
