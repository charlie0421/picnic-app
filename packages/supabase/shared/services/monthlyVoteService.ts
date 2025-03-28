import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

export async function createMonthlyVote() {
  // 환경 변수에서 Supabase 관련 URL 및 서비스 역할 키를 가져옴
  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // RPC 호출을 통해 월별 투표 생성 로직 실행 (RPC 명칭은 실제 저장 프로시저에 맞게 조정)
  const { data, error } = await supabase.rpc('create_monthly_votes');
  if (error) {
    console.error('RPC 호출 실패: ', error);
    throw new Error('RPC 호출 실패: ' + error.message);
  }
  return data;
}
