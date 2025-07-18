import { Pool } from 'https://deno.land/x/postgres@v0.17.0/mod.ts';
import { corsHeaders } from '../_shared/cors.ts';

console.log("JMA Voting Usage function loaded");

const databaseUrl = Deno.env.get('SUPABASE_DB_URL');
const pool = new Pool(databaseUrl, 3, true);

// 일일 사용량 조회 응답 인터페이스
interface DailyUsageResponse {
  dailyVoteCount: number;
  maxDailyVotes: number;
  remainingVotes: number;
  canVote: boolean;
}

async function queryDatabase(query: string, ...args: any[]) {
  const client = await pool.connect();
  try {
    const result = await client.queryObject(query, args);
    return result;
  } catch (error) {
    console.error('Error executing query:', {
      query,
      args,
      error
    });
    throw error;
  } finally {
    client.release();
  }
}

// JMA 일일 보너스 투표 제한 확인 (투표별로 하루 5개) - UTC 기준
async function checkJmaBonusVoteLimit(user_id: string, vote_id: number): Promise<{ canVote: boolean, dailyCount: number }> {
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0); // UTC 기준으로 설정
  const tomorrow = new Date(today);
  tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);

  // 특정 투표에 대한 오늘 보너스 별사탕 사용량 총합 확인
  const { rows } = await queryDatabase(`
    SELECT COALESCE(SUM(star_candy_bonus_usage), 0) as total_usage
    FROM vote_pick
    WHERE user_id = $1
    AND vote_id = $2
    AND star_candy_bonus_usage > 0
    AND created_at >= $3
    AND created_at < $4
  `, user_id, vote_id, today.toISOString(), tomorrow.toISOString());

  const bonusUsageTotal = parseInt(rows[0].total_usage);
  console.log(`User ${user_id} bonus usage total for vote ${vote_id} today: ${bonusUsageTotal}`);
  
  return {
    canVote: bonusUsageTotal < 5, // 5개 미만이면 허용
    dailyCount: bonusUsageTotal
  };
}

// 일일 사용량 조회 함수
async function getDailyUsage(user_id: string, vote_id: number): Promise<DailyUsageResponse> {
  const limitCheck = await checkJmaBonusVoteLimit(user_id, vote_id);
  const maxDailyVotes = 5;
  
  return {
    dailyVoteCount: limitCheck.dailyCount,
    maxDailyVotes,
    remainingVotes: Math.max(0, maxDailyVotes - limitCheck.dailyCount),
    canVote: limitCheck.canVote
  };
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // GET 요청만 처리 (사용량 조회 전용)
  if (req.method === 'GET') {
    try {
      const url = new URL(req.url);
      const user_id = url.searchParams.get('user_id');
      const vote_id = url.searchParams.get('vote_id');

      if (!user_id || !vote_id) {
        return new Response(
          JSON.stringify({ 
            error: 'Missing required parameters: user_id, vote_id' 
          }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        );
      }

      const dailyUsage = await getDailyUsage(user_id, parseInt(vote_id));
      
      return new Response(
        JSON.stringify(dailyUsage),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );

    } catch (error) {
      console.error('JMA Voting Usage error:', error);
      return new Response(
        JSON.stringify({ 
          error: 'Internal server error',
          message: error.message 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }
  }

  // GET 요청이 아닌 경우
  return new Response(
    JSON.stringify({ error: 'Only GET method is allowed' }),
    { 
      status: 405, 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    }
  );
}); 