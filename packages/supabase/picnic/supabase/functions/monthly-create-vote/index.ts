// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
// 새로 추가: deno 표준 http 서버에서 serve 함수 임포트
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
// 새로운 서비스 호출을 위한 임포트 (경로는 실제 디렉토리 구조에 맞게 조정)
import { createMonthlyVote } from '../_shared/services/monthlyVoteService.ts';

console.log('Hello from Functions!');

// handler 함수 내부에서 서비스를 호출하여 월별 투표 생성 로직을 수행
const handler = async (req: Request) => {
  try {
    // 필요한 경우 요청 데이터를 파싱하여 인자로 전달할 수 있음
    const result = await createMonthlyVote();
    return new Response(
      JSON.stringify({ message: 'Vote created successfully', result }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('Error in create vote: ', err);
    return new Response(
      JSON.stringify({ error: 'Failed to create vote', details: err.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
};

serve(handler);

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/monthly-create-vote' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
