import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

const allowedOrigins = [
  'https://www.picnic.fan',
  'http://localhost:3000', // 로컬 추가 ✅
];

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

  // 기존 PKCE OAuth 처리 코드 유지...

  return new Response(JSON.stringify({ url }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': allowedOrigins.includes(origin)
        ? origin
        : allowedOrigins[0],
      'Access-Control-Allow-Credentials': 'true',
    },
  });
});
