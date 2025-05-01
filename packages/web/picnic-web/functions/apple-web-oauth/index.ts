import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { generatePKCE } from 'https://deno.land/x/oauth2_client@v1.0.0/pkce.ts';

serve(async (req) => {
  // Preflight 요청 처리
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Credentials': 'true',
      },
    });
  }

  const { url } = await req.json();

  // PKCE 생성
  const { codeVerifier, codeChallenge } = await generatePKCE();

  // state에 리다이렉트 URL과 함께 nonce 추가
  const state = btoa(JSON.stringify({
    redirect_url: url,
    nonce: crypto.randomUUID(),
    code_verifier: codeVerifier, // state에 code_verifier 포함
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

  // code_verifier를 쿠키에 저장
  const response = new Response(JSON.stringify({ 
    url: appleOauthUrl,
    code_verifier: codeVerifier // 클라이언트에서도 사용할 수 있도록 응답에 포함
  }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Credentials': 'true',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Set-Cookie': `sb-xtijtefcycoeqludlngc-auth-token-code-verifier=${codeVerifier}; Path=/; Domain=.picnic.fan; HttpOnly; Secure; SameSite=None; Max-Age=300`, // 5분 유효
    },
  });

  return response;
}); 