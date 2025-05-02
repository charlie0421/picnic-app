import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

const allowedOrigins = ['https://www.picnic.fan', 'http://localhost:3000'];

async function generatePKCE() {
  const codeVerifier = crypto.randomUUID() + crypto.randomUUID();
  const encoder = new TextEncoder();
  const data = encoder.encode(codeVerifier);
  const hash = await crypto.subtle.digest('SHA-256', data);
  const codeChallenge = btoa(String.fromCharCode(...new Uint8Array(hash)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
  return { codeVerifier, codeChallenge };
}

serve(async (req) => {
  const origin = req.headers.get('origin') || '';

  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': allowedOrigins.includes(origin)
          ? origin
          : allowedOrigins[0],
        'Access-Control-Allow-Headers':
          'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Credentials': 'true',
      },
    });
  }

  const { url } = await req.json();

  const { codeVerifier, codeChallenge } = await generatePKCE();
  const state = btoa(
    JSON.stringify({
      redirect_url: url,
      code_verifier: codeVerifier,
      timestamp: Date.now(),
    }),
  );

  const redirectUri = 'https://www.picnic.fan/auth/callback/apple'; // 명확히 고정된 URL로 설정

  const params = new URLSearchParams({
    client_id: Deno.env.get('APPLE_WEB_CLIENT_ID')!,
    redirect_uri: redirectUri,
    response_type: 'code',
    response_mode: 'form_post',
    scope: 'name email',
    state,
    code_challenge: codeChallenge,
    code_challenge_method: 'S256',
  });

  const oauthUrl = `https://appleid.apple.com/auth/authorize?${params}`;

  return new Response(JSON.stringify({ url: oauthUrl }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': allowedOrigins.includes(origin)
        ? origin
        : allowedOrigins[0],
      'Access-Control-Allow-Credentials': 'true',
    },
  });
});
