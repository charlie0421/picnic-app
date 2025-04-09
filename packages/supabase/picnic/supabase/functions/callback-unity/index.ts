import { serve } from 'http/server';
import { AdServiceFactory } from '@shared/services/ad/index.ts';
import { UnityAdCallbackResponse } from '@shared/services/ad/base-ad-service.ts';
import { UnityAdsParameters } from '@shared/services/ad/interfaces/ad-parameters.ts';

const secretKey = Deno.env.get('UNITY_SECRET_KEY') || '';
const adService = AdServiceFactory.createService('unity', secretKey);

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
    const params = adService.extractParameters(url) as UnityAdsParameters;
    const result = (await adService.handleCallback(
      params,
    )) as UnityAdCallbackResponse;

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

    return new Response(result.body || 'Internal server error', {
      status: result.status,
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/plain',
      },
    });
  } catch (error) {
    console.error('Error:', error);
    return new Response('Internal server error', {
      status: 500,
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/plain',
      },
    });
  }
}

serve(handleRequest);
