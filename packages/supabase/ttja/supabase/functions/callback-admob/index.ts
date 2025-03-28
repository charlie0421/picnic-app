import { AdServiceFactory } from '@shared/services/ad/index.ts';
import { AdMobAdCallbackResponse } from '@shared/services/ad/base-ad-service.ts';
const secretKey = Deno.env.get('ADMOB_SECRET_KEY') || '';
const adService = AdServiceFactory.createService('admob', secretKey);

async function handleRequest(req: Request) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
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

    if (!adService.validateParameters(params)) {
      return new Response(
        JSON.stringify({ error: '필수 파라미터가 누락되었습니다.' }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        },
      );
    }

    const result = (await adService.handleCallback(
      params,
    )) as AdMobAdCallbackResponse;

    return new Response(JSON.stringify(result.body), {
      status: result.status,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
    });
  } catch (error) {
    console.error('Error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
    });
  }
}

Deno.serve(handleRequest);
