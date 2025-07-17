import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { Pool } from 'https://deno.land/x/postgres@v0.17.0/mod.ts';
import { corsHeaders } from '../_shared/cors.ts';

console.log("JMA Voting V2 function loaded");

const databaseUrl = Deno.env.get('SUPABASE_DB_URL');
const pool = new Pool(databaseUrl, 3, true);

interface JmaVotingRequest {
  vote_id: number;
  vote_item_id: number;
  amount: number;
  star_candy_usage: number;
  star_candy_bonus_usage: number;
  user_id: string;
  bonus_votes_used?: number;
}

async function queryDatabase(query: string, ...args: any[]) {
  const client = await pool.connect();
  try {
    const result = await client.queryObject(query, args);
    console.log('Query executed:', {
      query,
      args,
      result
    });
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

async function getUserProfiles(supabaseClient: any, user_id: string) {
  try {
    const { data: user_profiles, error } = await supabaseClient
      .from('user_profiles')
      .select('*')
      .eq('id', user_id)
      .single();
    return { user_profiles, error };
  } catch (error) {
    console.error('Error fetching user profiles:', error);
    return { user_profiles: null, error };
  }
}

// JMA 일일 보너스 투표 제한 확인 (투표별로 하루 5회)
async function checkJmaBonusVoteLimit(user_id: string, vote_id: number): Promise<{ canVote: boolean, dailyCount: number }> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  // 특정 투표에 대한 오늘 보너스 투표 횟수 확인 (star_candy_bonus_usage > 0인 경우)
  const { rows } = await queryDatabase(`
    SELECT COUNT(*) as count
    FROM vote_pick
    WHERE user_id = $1
    AND vote_id = $2
    AND star_candy_bonus_usage > 0
    AND created_at >= $3
    AND created_at < $4
  `, user_id, vote_id, today.toISOString(), tomorrow.toISOString());

  const bonusVoteCount = parseInt(rows[0].count);
  console.log(`User ${user_id} bonus vote count for vote ${vote_id} today: ${bonusVoteCount}`);
  
  return {
    canVote: bonusVoteCount < 5, // 5회 미만이면 허용
    dailyCount: bonusVoteCount
  };
}

// star_candy와 star_candy_bonus 동시 차감 (분리된 사용량 기록)
async function deductStarCandyWithUsage(
  user_id: string, 
  starCandyUsage: number, 
  starCandyBonusUsage: number,
  vote_pick_id: number
) {
  // 사용자 현재 잔액 확인
  const { rows: userRows } = await queryDatabase(`
    SELECT id, star_candy, star_candy_bonus
    FROM user_profiles
    WHERE id = $1
  `, user_id);
  
  if (userRows.length === 0) {
    throw new Error('User not found');
  }

  const user = userRows[0];
  const currentStarCandy = user.star_candy;
  const currentStarCandyBonus = user.star_candy_bonus;

  // 잔액 부족 검증
  if (currentStarCandy < starCandyUsage) {
    throw new Error(`Insufficient star_candy. Required: ${starCandyUsage}, Available: ${currentStarCandy}`);
  }
  if (currentStarCandyBonus < starCandyBonusUsage) {
    throw new Error(`Insufficient star_candy_bonus. Required: ${starCandyBonusUsage}, Available: ${currentStarCandyBonus}`);
  }

  // 별사탕 차감
  const { rows: deductRows } = await queryDatabase(`
    UPDATE user_profiles
    SET 
      star_candy = star_candy - $2,
      star_candy_bonus = star_candy_bonus - $3,
      updated_at = NOW()
    WHERE id = $1
    RETURNING star_candy, star_candy_bonus
  `, user_id, starCandyUsage, starCandyBonusUsage);

  if (deductRows.length === 0) {
    throw new Error('Failed to deduct star candy');
  }

  // 히스토리 기록 없이 진행

  console.log(`Deducted star candy for user ${user_id}: regular=${starCandyUsage}, bonus=${starCandyBonusUsage}`);
  console.log(`Remaining: regular=${deductRows[0].star_candy}, bonus=${deductRows[0].star_candy_bonus}`);

  return deductRows[0];
}

// vote_pick 생성 (분리된 사용량 포함)
async function createVotePick(
  vote_id: number,
  vote_item_id: number,
  user_id: string,
  amount: number,
  starCandyUsage: number,
  starCandyBonusUsage: number
) {
  const { rows } = await queryDatabase(`
    INSERT INTO vote_pick (
      vote_id, vote_item_id, user_id, amount, 
      star_candy_usage, star_candy_bonus_usage,
      created_at, updated_at
    )
    VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
    RETURNING id, amount, star_candy_usage, star_candy_bonus_usage, created_at
  `, vote_id, vote_item_id, user_id, amount, starCandyUsage, starCandyBonusUsage);

  if (rows.length === 0) {
    throw new Error('Failed to create vote pick');
  }

  console.log(`Created vote_pick: ID=${rows[0].id}, amount=${amount}, star_candy_usage=${starCandyUsage}, star_candy_bonus_usage=${starCandyBonusUsage}`);
  return rows[0];
}

// vote_item 업데이트 (분리된 총합 포함)
async function updateVoteItem(vote_item_id: number, amount: number, starCandyUsage: number, starCandyBonusUsage: number) {
  const { rows } = await queryDatabase(`
    UPDATE vote_item
    SET 
      vote_total = vote_total + $2,
      star_candy_total = star_candy_total + $3,
      star_candy_bonus_total = star_candy_bonus_total + $4,
      updated_at = NOW()
    WHERE id = $1
    RETURNING id, vote_total, star_candy_total, star_candy_bonus_total
  `, vote_item_id, amount, starCandyUsage, starCandyBonusUsage);

  if (rows.length === 0) {
    throw new Error('Vote item not found');
  }

  console.log(`Updated vote_item: ID=${vote_item_id}, new vote_total=${rows[0].vote_total}, star_candy_total=${rows[0].star_candy_total}, star_candy_bonus_total=${rows[0].star_candy_bonus_total}`);
  return rows[0];
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const {
      vote_id,
      vote_item_id,
      amount,
      star_candy_usage,
      star_candy_bonus_usage,
      user_id,
      bonus_votes_used = 0
    }: JmaVotingRequest = await req.json();

    // 입력 검증
    if (!vote_id || !vote_item_id || amount === undefined || !user_id || 
        star_candy_usage === undefined || star_candy_bonus_usage === undefined) {
      return new Response(
        JSON.stringify({ 
          error: 'Missing required fields: vote_id, vote_item_id, amount, star_candy_usage, star_candy_bonus_usage, user_id' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // 사용량 검증 (별사탕 사용량으로 계산한 투표 수가 amount와 일치해야 함)
    const calculatedVotes = Math.floor(star_candy_usage / 3) + star_candy_bonus_usage;
    if (calculatedVotes !== amount) {
      return new Response(
        JSON.stringify({ 
          error: 'Usage validation failed',
          message: 'Calculated votes from star candy usage must equal amount',
          star_candy_usage,
          star_candy_bonus_usage,
          calculated_votes: calculatedVotes,
          amount
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // JMA 보너스 투표 일일 제한 확인 (투표별로 보너스 사용량이 있는 경우만)
    if (star_candy_bonus_usage > 0) {
      const limitCheck = await checkJmaBonusVoteLimit(user_id, vote_id);
      if (!limitCheck.canVote) {
        return new Response(
          JSON.stringify({ 
            error: 'JMA daily bonus vote limit exceeded',
            message: '이 투표에 대해 하루 최대 5번까지 보너스 투표할 수 있습니다.',
            dailyCount: limitCheck.dailyCount,
            limit: 5
          }),
          { 
            status: 429, // Too Many Requests
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        );
      }
    }

    // 사용자 정보 확인
    const { user_profiles, error: userError } = await getUserProfiles(supabaseClient, user_id);
    if (userError || !user_profiles) {
      return new Response(
        JSON.stringify({ error: 'User not found' }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // 잔액 충분한지 확인
    if (user_profiles.star_candy < star_candy_usage) {
      return new Response(
        JSON.stringify({ 
          error: 'Insufficient star_candy',
          required: star_candy_usage,
          available: user_profiles.star_candy
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    if (user_profiles.star_candy_bonus < star_candy_bonus_usage) {
      return new Response(
        JSON.stringify({ 
          error: 'Insufficient star_candy_bonus',
          required: star_candy_bonus_usage,
          available: user_profiles.star_candy_bonus
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // 트랜잭션 시작 - 모든 DB 작업을 순차적으로 수행
    try {
      // 1. vote_pick 생성
      const votePick = await createVotePick(
        vote_id, 
        vote_item_id, 
        user_id, 
        amount, 
        star_candy_usage, 
        star_candy_bonus_usage
      );

      // 2. 별사탕 차감
      const updatedUser = await deductStarCandyWithUsage(
        user_id, 
        star_candy_usage, 
        star_candy_bonus_usage,
        votePick.id
      );

      // 3. vote_item 업데이트
      const updatedVoteItem = await updateVoteItem(
        vote_item_id, 
        amount, 
        star_candy_usage, 
        star_candy_bonus_usage
      );

      // 성공 응답
      return new Response(
        JSON.stringify({
          success: true,
          votePickId: votePick.id,
          updatedAt: votePick.created_at,
          // 투표 완료 다이얼로그에서 사용하는 필드들 추가
          existingVoteTotal: updatedVoteItem.vote_total - amount,
          addedVoteTotal: amount,
          updatedVoteTotal: updatedVoteItem.vote_total,
          message: 'JMA vote processed successfully',
          data: {
            vote_pick: votePick,
            updated_vote_item: updatedVoteItem,
            user_balance: {
              star_candy: updatedUser.star_candy,
              star_candy_bonus: updatedUser.star_candy_bonus
            },
            usage: {
              star_candy_usage,
              star_candy_bonus_usage,
              total_amount: amount
            }
          }
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );

    } catch (dbError) {
      console.error('Database transaction error:', dbError);
      throw dbError;
    }

  } catch (error) {
    console.error('JMA Voting V2 error:', error);
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
}); 