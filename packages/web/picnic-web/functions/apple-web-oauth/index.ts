import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

serve(async (req) => {
  // Preflight 요청 처리
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      },
    });
  }

  const { url } = await req.json();

  // state에 리다이렉트 URL과 함께 nonce 추가
  const state = btoa(JSON.stringify({
    redirect_url: url,
    nonce: crypto.randomUUID(),
  }));

  const params = new URLSearchParams({
    client_id: Deno.env.get('APPLE_WEB_CLIENT_ID')!,
    redirect_uri: 'https://api.picnic.fan/auth/callback',  // Supabase callback URL이 아닌 우리 도메인으로 변경
    response_type: 'code',
    response_mode: 'form_post',
    scope: 'name email',
    state,
  });

  const appleOauthUrl = `https://appleid.apple.com/auth/authorize?${params.toString()}`;

  return new Response(JSON.stringify({ url: appleOauthUrl }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
    },
  });
}); 