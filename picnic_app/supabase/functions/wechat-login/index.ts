// @ts-nocheck
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

interface WeChatTokenResponse {
  access_token: string;
  expires_in: number;
  refresh_token: string;
  openid: string;
  scope: string;
  unionid?: string;
  errcode?: number;
  errmsg?: string;
}

async function fetchWeChatToken(appId: string, appSecret: string, code: string): Promise<WeChatTokenResponse> {
  const url = new URL('https://api.weixin.qq.com/sns/oauth2/access_token');
  url.searchParams.set('appid', appId);
  url.searchParams.set('secret', appSecret);
  url.searchParams.set('code', code);
  url.searchParams.set('grant_type', 'authorization_code');

  const res = await fetch(url.toString(), { method: 'GET' });
  const data = await res.json();
  return data as WeChatTokenResponse;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { code } = await req.json();
    if (!code) {
      return new Response(
        JSON.stringify({ error: 'Missing required field: code' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    const envAppId = Deno.env.get('WECHAT_APP_ID');
    const envAppSecret = Deno.env.get('WECHAT_APP_SECRET');
    if (!envAppId || !envAppSecret) {
      return new Response(
        JSON.stringify({ error: 'Server not configured', message: 'WECHAT_APP_ID/WECHAT_APP_SECRET missing' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Exchange code -> WeChat tokens
    const token = await fetchWeChatToken(envAppId, envAppSecret, code);
    if (token.errcode) {
      return new Response(
        JSON.stringify({ error: 'WeChat token error', detail: token }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const openid = token.openid;
    const unionid = token.unionid ?? openid;
    if (!openid) {
      return new Response(
        JSON.stringify({ error: 'Missing openid from WeChat response' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Construct deterministic email for Supabase user
    const email = `wechat_${unionid}@picnic.fan`;

    // Use service role to generate magic link and return OTP token
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { data, error } = await supabase.auth.admin.generateLink({
      type: 'magiclink',
      email,
    });
    if (error || !data) {
      return new Response(
        JSON.stringify({ error: 'Failed to generate magic link', detail: error?.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // data.properties.email_otp contains the one-time token for verifyOTP
    const otp = (data as any)?.properties?.email_otp;
    if (!otp) {
      return new Response(
        JSON.stringify({ error: 'Missing email_otp from generateLink response' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ email, otp }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: 'Internal server error', message: e?.message ?? String(e) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});


