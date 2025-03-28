import { serve } from 'http/server';
import { AdServiceFactory } from '@shared/services/ad/index.ts';
import { AdMobAdCallbackResponse } from '@shared/services/ad/base-ad-service.ts';
import { AdMobParameters } from '@shared/services/ad/interfaces/ad-parameters.ts';

const secretKey = Deno.env.get('ADMOB_SECRET_KEY') || '';
const adService = AdServiceFactory.createService('admob', secretKey);

// admob 추가시 테스트 데이터
// 7ae352a2-74af-4d4d-90a5-cdd9d8c8310d
// {"reward_amount":1, "reward_type":"free_charge_station"}
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
    const params = adService.extractParameters(url) as AdMobParameters;

    // 디버그 모드 체크
    if (params.user_id === 'fakeForAdDebugLog') {
      console.log('디버깅 모드: 데이터베이스 업데이트를 건너뜁니다.');
      return new Response(JSON.stringify({ success: true }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      });
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

serve(handleRequest);
