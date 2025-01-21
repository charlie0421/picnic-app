import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

function createSupabaseClient(req) {
  return createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}

function getAllowedOrigin(origin) {
  if (!origin) return '*';

  if (
    origin.endsWith('ttja.picnic.fan') ||
    origin.endsWith('www.ttja.net') ||
    origin.endsWith('ttja.net')
  ) {
    return origin;
  }

  return '*';
}

async function isIPBlocked(supabaseClient, ip) {
  const { data, error } = await supabaseClient
    .from('blocked_ips')
    .select('ip_address')
    .eq('ip_address', ip)
    .single();

  if (error && error.code !== 'PGRST116') {
    // PGRST116는 결과를 찾지 못했을 때의 에러
    console.error('IP 차단 확인 중 에러 발생:', error);
    return false;
  }

  return !!data;
}

function getNextMonth15thAt9AM() {
    const now = new Date();
    const nextMonth = now.getMonth() + 1;
    const nextMonth15th = new Date(now.getFullYear(), nextMonth, 15, 9, 0, 0);
    const year = nextMonth15th.getFullYear();
    const month = String(nextMonth15th.getMonth() + 1).padStart(2, '0');
    const day = String(nextMonth15th.getDate()).padStart(2, '0');
    const hours = String(nextMonth15th.getHours()).padStart(2, '0');
    const minutes = String(nextMonth15th.getMinutes()).padStart(2, '0');
    const seconds = String(nextMonth15th.getSeconds()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
}

Deno.serve(async (req) => {
  const origin = req.headers.get('origin');
  console.log('Request origin:', origin);
  console.log('getAllowedOrigin(origin):', getAllowedOrigin(origin));

  const corsHeaders = {
    'Access-Control-Allow-Origin': getAllowedOrigin(origin),
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabaseClient = createSupabaseClient(req);

  // IP 차단 확인
  const clientIP =
    req.headers.get('cf-connecting-ip') || // Cloudflare IP
    Deno.requestContext?.remoteAddr?.hostname || // Deno context IP
    'unknown';

  console.log('Client IP:', clientIP);

  const blocked = await isIPBlocked(supabaseClient, clientIP);

  if (blocked) {
    return new Response(
      JSON.stringify({
        error: 'Access Denied',
        message: 'Your IP address has been blocked',
      }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
        status: 403,
      },
    );
  }

  try {
    const { vote_id, vote_item_id, amount, user_id } = await req.json();
      const expired_dt = getNextMonth15thAt9AM();

    console.log('Request data:', { vote_id, vote_item_id, amount, user_id });

    const { data, error } = await supabaseClient.rpc(
      'perform_vote_transaction',
      {
        p_vote_id: vote_id,
        p_vote_item_id: vote_item_id,
        p_amount: amount,
        p_user_id: user_id,
      },
    );

    if (error) throw error;

    console.log('Response data:', data);

    return new Response(JSON.stringify(data), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
      status: 200,
    });
  } catch (error) {
    console.error('Error details:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Unexpected error occurred' }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
        status: 500,
      },
    );
  }
});
