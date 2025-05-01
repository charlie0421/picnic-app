import { serve } from 'http/server';

async function generatePKCE() {
  const verifier = crypto.randomUUID().replace(/-/g, '');
  const encoder = new TextEncoder();
  const data = encoder.encode(verifier);
  const hash = await crypto.subtle.digest('SHA-256', data);
  const challenge = btoa(String.fromCharCode(...new Uint8Array(hash)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
  return { codeVerifier: verifier, codeChallenge: challenge };
}

serve(async (req) => {
  // Preflight 요청 처리
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': 'https://www.picnic.fan',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Credentials': 'true',
      },
    });
  }

  const { url } = await req.json();

  // PKCE 생성
  const { codeVerifier, codeChallenge } = await generatePKCE();
  const flowState = crypto.randomUUID();

  // state에 리다이렉트 URL과 함께 nonce 추가
  const state = btoa(JSON.stringify({
    redirect_url: url,
    nonce: crypto.randomUUID(),
    code_verifier: codeVerifier,
    flow_state: flowState,
    provider: 'apple',
    timestamp: Date.now()
  }));

  const params = new URLSearchParams({
    client_id: Deno.env.get('APPLE_WEB_CLIENT_ID')!,
    redirect_uri: Deno.env.get('APPLE_WEB_REDIRECT_URI')!,
    response_type: 'code',
    response_mode: 'form_post',
    scope: 'name email',
    state,
    code_challenge: codeChallenge,
    code_challenge_method: 'S256',
  });

  const appleOauthUrl = `https://appleid.apple.com/auth/authorize?${params.toString()}`;

  // code_verifier와 flow_state를 쿠키에 저장
  const response = new Response(JSON.stringify({ 
    url: appleOauthUrl,
    code_verifier: codeVerifier,
    flow_state: flowState
  }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': 'https://www.picnic.fan',
      'Access-Control-Allow-Credentials': 'true',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Set-Cookie': [
        `sb-xtijtefcycoeqludlngc-auth-token-code-verifier=${codeVerifier}; Path=/; Domain=picnic.fan; HttpOnly; Secure; SameSite=None; Max-Age=300`,
        `sb-xtijtefcycoeqludlngc-auth-token-flow-state=${flowState}; Path=/; Domain=picnic.fan; HttpOnly; Secure; SameSite=None; Max-Age=300`,
        `sb-xtijtefcycoeqludlngc-auth-token=${flowState}; Path=/; Domain=picnic.fan; HttpOnly; Secure; SameSite=None; Max-Age=300`
      ].join(', ')
    },
  });

  return response;
}); 