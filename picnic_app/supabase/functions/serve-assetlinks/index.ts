import { serve } from 'https://deno.land/std@0.131.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const supabase = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_ANON_KEY') ?? '');
serve(async (req)=>{
  const { data, error } = await supabase.storage.from('picnic').download('assetlinks.json');
  if (error) {
    return new Response(JSON.stringify({
      error: error.message
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
  return new Response(data, {
    status: 200,
    headers: {
      'Content-Type': 'application/json'
    }
  });
});
