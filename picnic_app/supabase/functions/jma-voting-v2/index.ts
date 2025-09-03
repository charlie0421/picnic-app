// @ts-nocheck
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { Pool } from 'https://deno.land/x/postgres@v0.17.0/mod.ts';
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
console.log("JMA Voting V2 function loaded");
const databaseUrl = Deno.env.get('DB_POOLED_URL') ?? Deno.env.get('SUPABASE_DB_URL') ?? '';
const parsedPoolSize = parseInt(Deno.env.get('DB_POOL_SIZE') ?? '1', 10);
const poolSize = Number.isFinite(parsedPoolSize) && parsedPoolSize > 0 ? parsedPoolSize : 1;
const pool = new Pool(databaseUrl, poolSize, true);
// 일반 별사탕 → 투표수 환산 비율 (예: 30개 = 1투표)
const REGULAR_CANDY_PER_VOTE = 30;
// KST(UTC+9) 기준 하루 시작/끝을 UTC 시각으로 반환
function getKstDayWindowUtc(now = new Date()) {
  const KST_OFFSET_MS = 9 * 60 * 60 * 1000;
  const kstNow = new Date(now.getTime() + KST_OFFSET_MS);
  const kstStart = new Date(kstNow);
  kstStart.setUTCHours(0, 0, 0, 0);
  const startUtc = new Date(kstStart.getTime() - KST_OFFSET_MS);
  const endUtc = new Date(startUtc.getTime() + 24 * 60 * 60 * 1000);
  return {
    startUtc,
    endUtc,
    kstStartIso: kstStart.toISOString()
  };
}
async function queryWithClient(client, query, ...args) {
  try {
    const result = await client.queryObject(query, args);
    console.log('Query executed:', {
      query,
      args
    });
    return result;
  } catch (error) {
    console.error('Error executing query:', {
      query,
      args,
      error
    });
    throw error;
  }
}
async function getUserProfiles(supabaseClient, user_id) {
  try {
    const { data: user_profiles, error } = await supabaseClient.from('user_profiles').select('*').eq('id', user_id).single();
    return {
      user_profiles,
      error
    };
  } catch (error) {
    console.error('Error fetching user profiles:', error);
    return {
      user_profiles: null,
      error
    };
  }
}
// JMA 일일 보너스 투표 제한 확인 (투표별로 하루 5개)
async function checkJmaBonusVoteLimit(client, user_id, vote_id) {
  const { startUtc, endUtc, kstStartIso } = getKstDayWindowUtc();
  // 특정 투표에 대한 오늘 보너스 별사탕 사용량 총합 확인
  const { rows } = await queryWithClient(client, `
    SELECT COALESCE(SUM(star_candy_bonus_usage), 0) as total_usage
    FROM vote_pick
    WHERE user_id = $1
    AND vote_id = $2
    AND star_candy_bonus_usage > 0
    AND created_at >= $3
    AND created_at < $4
  `, user_id, vote_id, startUtc.toISOString(), endUtc.toISOString());
  const rawTotal = rows?.[0]?.total_usage;
  const parsedInt = parseInt(rawTotal);
  const parsedNumber = Number(rawTotal);
  const bonusUsageTotal = Number.isFinite(parsedNumber) ? parsedNumber : parsedInt;
  console.log(`User ${user_id} bonus usage total for vote ${vote_id} today (KST window starting ${kstStartIso}): ${bonusUsageTotal}`);
  return {
    canVote: bonusUsageTotal < 5,
    dailyCount: bonusUsageTotal
  };
}
// star_candy와 star_candy_bonus 동시 차감 (분리된 사용량 기록)
async function deductStarCandyWithUsage(client, user_id, starCandyUsage, starCandyBonusUsage, vote_pick_id) {
  // 사용자 현재 잔액 확인
  const { rows: userRows } = await queryWithClient(client, `
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
  const { rows: deductRows } = await queryWithClient(client, `
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
async function createVotePick(client, vote_id, vote_item_id, user_id, amount, starCandyUsage, starCandyBonusUsage) {
  const regularVotesFromStarCandy = Math.floor(starCandyUsage / REGULAR_CANDY_PER_VOTE);
  const { rows } = await queryWithClient(client, `
    INSERT INTO vote_pick (
      vote_id, vote_item_id, user_id, amount, 
      star_candy_usage, star_candy_bonus_usage,
      created_at, updated_at
    )
    VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
    RETURNING id, amount, star_candy_usage, star_candy_bonus_usage, created_at
  `, vote_id, vote_item_id, user_id, amount, regularVotesFromStarCandy, starCandyBonusUsage);
  if (rows.length === 0) {
    throw new Error('Failed to create vote pick');
  }
  console.log(`Created vote_pick: ID=${rows[0].id}, amount=${amount}, star_candy_usage=${regularVotesFromStarCandy}, star_candy_bonus_usage=${starCandyBonusUsage}`);
  return rows[0];
}
// vote_item 최신 합계 재조회 (트리거 반영값 읽기)
async function readUpdatedVoteItem(client, vote_item_id) {
  const { rows } = await queryWithClient(client, `
    SELECT id, vote_total, star_candy_total, star_candy_bonus_total
    FROM vote_item
    WHERE id = $1
    FOR SHARE
  `, vote_item_id);
  if (rows.length === 0) {
    throw new Error('Vote item not found');
  }
  console.log(`Read vote_item totals: ID=${vote_item_id}, vote_total=${rows[0].vote_total}, star_candy_total=${rows[0].star_candy_total}, star_candy_bonus_total=${rows[0].star_candy_bonus_total}`);
  return rows[0];
}
// 투표 오픈 여부 확인 (end_at 기준)
async function ensureVoteOpen(client, vote_id) {
  try {
    const { rows } = await queryWithClient(client, `
      SELECT id, COALESCE(end_at, NULL) AS end_at
      FROM vote
      WHERE id = $1
      FOR SHARE
    `, vote_id);
    if (rows.length === 0) {
      return { open: false, reason: 'not_found' };
    }
    const row = rows[0];
    const now = new Date();
    const endAt = row.end_at ? new Date(row.end_at) : null;
    const ended = endAt ? now >= endAt : false;
    const isOpen = !ended;
    console.log(`Vote ${vote_id} open check (end_at only)`, { endAt, ended, isOpen });
    return { open: isOpen, meta: { endAt }, reason: { ended } };
  } catch (e) {
    // 컬럼 미존재 등 스키마 이슈는 로깅만 하고, 보수적으로 진행
    console.warn('ensureVoteOpen check failed; skipping with warning', e);
    return { open: true, reason: 'schema_unknown' };
  }
}
Deno.serve(async (req)=>{
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  // JMA 투표 전면 차단
  return new Response(JSON.stringify({
    error: 'JMA voting disabled',
    message: 'JMA 투표는 현재 중단되었습니다.'
  }), {
    status: 403,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json'
    }
  });
  try {
    const supabaseClient = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '');
    const { vote_id, vote_item_id, amount, star_candy_usage, star_candy_bonus_usage, user_id, bonus_votes_used = 0 } = await req.json();
    // 입력 정규화: 클라이언트가 star_candy_usage를 "투표 수"로 보낸 경우 호환 처리
    let scUsage = Number(star_candy_usage) || 0;
    // 보너스 사용량은 투표 수로 해석되므로 정수로 보정
    let scbUsage = Math.floor(Number(star_candy_bonus_usage) || 0);
    // 입력 검증
    if (!vote_id || !vote_item_id || amount === undefined || !user_id || star_candy_usage === undefined || star_candy_bonus_usage === undefined) {
      return new Response(JSON.stringify({
        error: 'Missing required fields: vote_id, vote_item_id, amount, star_candy_usage, star_candy_bonus_usage, user_id'
      }), {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      });
    }
    // 사용량 검증 (별사탕 사용량으로 계산한 투표 수가 amount와 일치해야 함)
    let calculatedVotes = Math.floor(scUsage / REGULAR_CANDY_PER_VOTE) + scbUsage;
    if (calculatedVotes !== amount) {
      // 호환 1: 별사탕만 사용했고 scUsage가 투표 수로 온 경우
      if (scbUsage === 0 && scUsage === amount) {
        scUsage = amount * REGULAR_CANDY_PER_VOTE;
        calculatedVotes = Math.floor(scUsage / REGULAR_CANDY_PER_VOTE) + scbUsage;
      } else if (scUsage + scbUsage === amount) {
        const votesFromRegular = amount - scbUsage;
        scUsage = votesFromRegular * REGULAR_CANDY_PER_VOTE;
        calculatedVotes = Math.floor(scUsage / REGULAR_CANDY_PER_VOTE) + scbUsage;
      }
    }
    if (calculatedVotes !== amount) {
      console.warn('[jma-v2] Usage validation failed', {
        vote_id,
        vote_item_id,
        user_id,
        amount,
        star_candy_usage: scUsage,
        star_candy_bonus_usage: scbUsage,
        calculatedVotes,
        rate: REGULAR_CANDY_PER_VOTE
      });
      return new Response(JSON.stringify({
        error: 'Usage validation failed',
        message: 'Calculated votes from star candy usage must equal amount',
        star_candy_usage: scUsage,
        star_candy_bonus_usage: scbUsage,
        calculated_votes: calculatedVotes,
        amount
      }), {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      });
    }
    // 트랜잭션 시작 - 모든 DB 작업을 순차적으로 수행 (단일 커넥션)
    const client = await pool.connect();
    try {
      await client.queryObject('BEGIN');
      // 투표 마감 여부 확인 (마감/비활성/미시작인 경우 차단)
      const openCheck = await ensureVoteOpen(client, vote_id);
      if (!openCheck.open) {
        await client.queryObject('ROLLBACK');
        return new Response(JSON.stringify({
          error: 'Vote closed',
          message: '투표가 마감되어 참여할 수 없습니다.',
          reason: openCheck.reason ?? null
        }), {
          status: 403,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          }
        });
      }
      // JMA 보너스 투표 일일 제한 확인 (투표별로 보너스 사용량이 있는 경우만)
      if (scbUsage > 0) {
        const limitCheck = await checkJmaBonusVoteLimit(client, user_id, vote_id);
        const remainingBonusVotes = Math.max(0, 5 - (limitCheck.dailyCount || 0));
        if (!limitCheck.canVote || scbUsage > remainingBonusVotes) {
          await client.queryObject('ROLLBACK');
          return new Response(JSON.stringify({
            error: 'JMA daily bonus vote limit exceeded',
            message: '이 투표에 대해 하루 최대 5번까지 보너스 투표할 수 있습니다.',
            dailyCount: limitCheck.dailyCount,
            requestedBonusVotes: scbUsage,
            remaining: remainingBonusVotes,
            limit: 5
          }), {
            status: 429,
            headers: {
              ...corsHeaders,
              'Content-Type': 'application/json'
            }
          });
        }
      }
      // 사용자 정보 확인
      const { user_profiles, error: userError } = await getUserProfiles(supabaseClient, user_id);
      if (userError || !user_profiles) {
        await client.queryObject('ROLLBACK');
        return new Response(JSON.stringify({
          error: 'User not found'
        }), {
          status: 404,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          }
        });
      }
      // 잔액 충분한지 확인
      if (user_profiles.star_candy < scUsage) {
        await client.queryObject('ROLLBACK');
        return new Response(JSON.stringify({
          error: 'Insufficient star_candy',
          required: scUsage,
          available: user_profiles.star_candy
        }), {
          status: 400,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          }
        });
      }
      if (user_profiles.star_candy_bonus < scbUsage) {
        await client.queryObject('ROLLBACK');
        return new Response(JSON.stringify({
          error: 'Insufficient star_candy_bonus',
          required: scbUsage,
          available: user_profiles.star_candy_bonus
        }), {
          status: 400,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          }
        });
      }
      // 1. vote_pick 생성
      const votePick = await createVotePick(client, vote_id, vote_item_id, user_id, amount, scUsage, scbUsage);
      // 2. 별사탕 차감
      const updatedUser = await deductStarCandyWithUsage(client, user_id, scUsage, scbUsage, votePick.id);
      // 3. 트리거가 반영한 최신 합계 읽기
      const updatedVoteItem = await readUpdatedVoteItem(client, vote_item_id);
      await client.queryObject('COMMIT');
      // 성공 응답
      return new Response(JSON.stringify({
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
            star_candy_usage: scUsage,
            star_candy_bonus_usage: scbUsage,
            total_amount: amount
          }
        }
      }), {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      });
    } catch (dbError) {
      await client.queryObject('ROLLBACK');
      console.error('Database transaction error:', dbError);
      throw dbError;
    } finally{
      try {
        client.release();
      } catch (_) {}
    }
  } catch (error) {
    console.error('JMA Voting V2 error:', error);
    return new Response(JSON.stringify({
      error: 'Internal server error',
      message: error.message
    }), {
      status: 500,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  }
});
