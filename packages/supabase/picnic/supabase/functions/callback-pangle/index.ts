import { serve } from 'http/server';
import { AdServiceFactory } from '@shared/services/ad/index.ts';
import { PangleAdCallbackResponse } from '@shared/services/ad/base-ad-service.ts';

const secretKey = Deno.env.get('PANGLE_SECRET_KEY') || '';
const adService = AdServiceFactory.createService('pangle', secretKey);

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

    const result = (await adService.handleCallback(
      params,
    )) as PangleAdCallbackResponse;

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

serve(handleRequest);
