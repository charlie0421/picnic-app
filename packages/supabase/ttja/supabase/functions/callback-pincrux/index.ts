import { AdServiceFactory } from '@shared/services/ad/index.ts';
import { PincruxAdCallbackResponse } from '@shared/services/ad/base-ad-service.ts';

const secretKey = Deno.env.get('PINCRUX_SECRET_KEY') || '';
const adService = AdServiceFactory.createService('pincrux', secretKey);

Deno.serve(async (req) => {
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

    const result = (await adService.handleCallback(
      params,
    )) as PincruxAdCallbackResponse;

    return new Response(
      JSON.stringify({
        status: result.status,
        code: result.body.code,
        msg: result.body.error,
      }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  } catch (error) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({
        code: '99',
        msg: 'Internal server error',
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  }
});
