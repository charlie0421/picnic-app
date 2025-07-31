import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// AdServiceFactory는 더 이상 사용하지 않음
import { UnityService } from '@shared/services/ad/platforms/unity-service.ts';

// iOS와 Android를 위한 별도의 Secret Key를 환경 변수에서 읽어옴
const secretKeys = {
  ios: Deno.env.get('UNITY_SECRET_KEY_IOS') || '',
  android: Deno.env.get('UNITY_SECRET_KEY_ANDROID') || '',
};

// AdServiceFactory를 거치지 않고 UnityService를 직접 생성
const adService = new UnityService(secretKeys);

async function handleRequest(req: Request) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };

  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  try {
    const url = new URL(req.url);
    const params = adService.extractParameters(url);
    const result = await adService.handleCallback(params);

    // 성공 시 '1' 반환 (Unity Ads 요구사항)
    if (result.status === 200) {
      return new Response('1', {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'text/plain',
        },
      });
    }

    const responseBody = typeof result.body === 'object' ? JSON.stringify(result.body) : result.body || 'Internal server error';
    return new Response(responseBody, {
      status: result.status,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
    });

  } catch (error) {
    console.error('Error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error', message: error.message }), {
      status: 500,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
    });
  }
}

serve(handleRequest);
