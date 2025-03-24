import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import CryptoJS from 'https://esm.sh/crypto-js';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const supabase = createClient(supabaseUrl, supabaseKey);

console.log('Callback Tapjoy 함수가 시작되었습니다.');
function getNextMonth15thAt9AM() {
  const now = new Date();
  const nextMonth = now.getMonth() + 1;
  const nextMonth15th = new Date(now.getFullYear(), nextMonth, 15, 9, 0, 0);
  const year = nextMonth15th.getFullYear();
  const month = String(nextMonth15th.getMonth() + 1).padStart(2, '0');
  const day = String(nextMonth15th.getDate()).padStart(2, '0');
  const hours = String(nextMonth15th.getHours()).padStart(2, '0');
  const minutes = String(nextMonth15th.getMinutes()).padStart(2, '0');
  const seconds = String(nextMonth15th.getSeconds()).padStart(2, '0');
  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
}

async function insertTransaction(id, snuid, currency, verifier, platform) {
  console.log('Tapjoy 거래 정보 저장');

  // transaction_tapjoy 테이블에 거래 정보 저장
  const { data, error } = await supabase.from('transaction_tapjoy').insert({
    transaction_id: id,
    user_id: snuid,
    reward_amount: currency,
    verifier: verifier,
    platform: platform,
    created_at: new Date().toISOString(),
  });

  if (error) {
    console.error('Tapjoy 거래 정보 저장 실패:', error);
    throw error;
  }

  return data;
}

Deno.serve(async (req) => {
  // CORS 헤더 설정
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };

  // OPTIONS 요청에 대한 응답
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  try {
    const url = new URL(req.url);
    const platform = url.searchParams.get('platform');
    const currency = parseInt(url.searchParams.get('currency') || '0', 10);
    const snuid = url.searchParams.get('snuid');
    const id = url.searchParams.get('id') || '';
    const mac_address = url.searchParams.get('mac_address') || '';
    const verifier = url.searchParams.get('verifier') || '';

    if (!platform || !currency || !snuid) {
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

    const params = {
      message: `id: ${id}, snuid: ${snuid}, currency: ${currency}, mac_address: ${mac_address}, platform: ${platform}, verifier: ${verifier}`,
    };

    console.log(params);

    const secret =
      platform === 'android'
        ? Deno.env.get('TAPJOY_SECRET_ANDROID')!
        : Deno.env.get('TAPJOY_SECRET_IOS')!;

    const source = `${id}:${snuid}:${currency}:${secret}`;
    const expectedVerifier = CryptoJS.MD5(source).toString();

    console.log(expectedVerifier);
    console.log(verifier);

    if (expectedVerifier !== verifier) {
      console.error('유효하지 않은 verifier입니다.', {
        expectedVerifier,
        providedVerifier: verifier,
      });
      return new Response(
        JSON.stringify({
          error: '유효하지 않은 서명입니다.',
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        },
      );
    }

    // 트랜잭션 시작
    const { data: userData, error: userError } = await supabase.rpc(
      'begin_transaction',
    );

    try {
      // Star Candy 보너스 히스토리 추가
      const { data, error } = await supabase
        .from('star_candy_bonus_history')
        .insert({
          user_id: snuid,
          amount: currency,
          type: 'MISSION',
          remain_amount: currency,
          expired_dt: getNextMonth15thAt9AM(),
          transaction_id: id,
        });

      if (error) throw error;

      // 사용자 프로필 정보 조회
      const { data: currentUser, error: fetchError } = await supabase
        .from('user_profiles')
        .select('star_candy_bonus')
        .eq('id', snuid)
        .single();

      console.log(currentUser);

      if (fetchError) throw fetchError;

      // 사용자 스타 캔디 보너스 업데이트
      const { data: updatedUser, error: userError } = await supabase
        .from('user_profiles')
        .update({
          star_candy_bonus: (currentUser?.star_candy_bonus || 0) + currency,
        })
        .eq('id', snuid)
        .select();

      if (userError) throw userError;

      // Tapjoy 거래 정보 저장
      await insertTransaction(id, snuid, currency, verifier, platform);

      // 트랜잭션 커밋
      await supabase.rpc('commit_transaction');

      return new Response(JSON.stringify({ success: true }), {
        headers: { 'Content-Type': 'application/json' },
      });
    } catch (error) {
      // 오류 발생 시 롤백
      await supabase.rpc('rollback_transaction');
      throw error;
    }
  } catch (error) {
    console.error('Error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/callback-tapjoy' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
