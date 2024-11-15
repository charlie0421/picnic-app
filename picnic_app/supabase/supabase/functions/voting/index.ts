import {createClient} from 'https://esm.sh/@supabase/supabase-js@2';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

function createSupabaseClient(req) {
    return createClient(supabaseUrl, supabaseServiceRoleKey, {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    });
}

function getAllowedOrigin(origin) {
    // origin이 없는 경우 (앱에서의 요청일 수 있음)
    if (!origin) return '*';

    // 웹 도메인 처리
    if (origin.endsWith('picnic.fan') ||
        origin.endsWith('www.picnic.fan')) {
        return origin;
    }

    return '*';
}

Deno.serve(async (req) => {
    const origin = req.headers.get('origin');
    console.log('Request origin:', origin);
    console.log('getAllowedOrigin(origin):', getAllowedOrigin(origin),);
    const corsHeaders = {
        'Access-Control-Allow-Origin': getAllowedOrigin(origin),
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Max-Age': '86400',
        'Vary': 'Origin'
    };


    if (req.method === 'OPTIONS') {
        return new Response('ok', {headers: corsHeaders});
    }

    const supabaseClient = createSupabaseClient(req);

    try {
        const {vote_id, vote_item_id, amount, user_id} = await req.json();
        console.log('Request data:', {vote_id, vote_item_id, amount, user_id});

        const {data, error} = await supabaseClient.rpc('perform_vote_transaction', {
            p_vote_id: vote_id,
            p_vote_item_id: vote_item_id,
            p_amount: amount,
            p_user_id: user_id
        });

        if (error) throw error;

        console.log('Response data:', data);

        return new Response(JSON.stringify(data), {
            headers: {
                ...corsHeaders,
                'Content-Type': 'application/json'
            },
            status: 200
        });
    } catch (error) {
        console.error('Error details:', error);
        return new Response(JSON.stringify({error: error.message || 'Unexpected error occurred'}), {
            headers: {'Content-Type': 'application/json'},
            status: 500
        });
    }
});
