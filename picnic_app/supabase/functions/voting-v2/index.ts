// @ts-nocheck
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { Pool } from 'https://deno.land/x/postgres@v0.17.0/mod.ts';
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

const databaseUrl = Deno.env.get('DB_POOLED_URL') ?? Deno.env.get('SUPABASE_DB_URL') ?? '';
const parsedPoolSize = parseInt(Deno.env.get('DB_POOL_SIZE') ?? '1', 10);
const poolSize = Number.isFinite(parsedPoolSize) && parsedPoolSize > 0 ? parsedPoolSize : 1;
const pool = new Pool(databaseUrl, poolSize, true);

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

// Execute a query using an existing transaction/client
async function queryWithClient(client: any, query: string, ...args: any[]) {
  try {
    const result = await client.queryObject(query, args);
    return result;
  } catch (error) {
    console.error('Error executing query (tx):', { query, args, error });
    throw error;
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

// star_candy 차감 (사용량 기록 포함) — 트랜잭션 내 클라이언트 사용
async function deductStarCandy(client: any, user_id: string, amount: number, vote_pick_id: number) {
  const { rows } = await queryWithClient(client, `
    SELECT id, star_candy
    FROM user_profiles
    WHERE id = $1
    FOR UPDATE
  `, user_id);

  if (rows.length === 0) {
    throw new Error('User not found');
  }

  const { id } = rows[0];

  await queryWithClient(client, `
    INSERT INTO star_candy_history (type, user_id, amount, vote_pick_id)
    VALUES ('VOTE', $1, $2, $3)
  `, user_id, amount, vote_pick_id);

  await queryWithClient(client, `
    UPDATE user_profiles
    SET star_candy = GREATEST(star_candy - $1, 0)
    WHERE id = $2
  `, amount, id);
}

// star_candy_bonus 차감 (사용량 기록 포함) — 트랜잭션 내 클라이언트 사용
async function deductStarCandyBonus(client: any, user_id: string, amount: number, bonusId: string, vote_pick_id: number) {
  await queryWithClient(client, `
    UPDATE star_candy_bonus_history
    SET remain_amount = GREATEST(remain_amount - $1, 0),
        updated_at = NOW()
    WHERE id = $2
  `, amount, bonusId);

  await queryWithClient(client, `
    INSERT INTO star_candy_bonus_history (user_id, amount, remain_amount, parent_id, vote_pick_id)
    VALUES ($1, $2, $3, $4, $5)
  `, user_id, amount, amount, bonusId, vote_pick_id);

  await queryWithClient(client, `
    UPDATE user_profiles
    SET star_candy_bonus = GREATEST(star_candy_bonus - $1, 0)
    WHERE id = $2
  `, amount, user_id);
}

// 투표 가능 여부 확인 및 차감 (분리된 사용량 반환) — 트랜잭션 내 수행
async function canVoteAndDeduct(
  client: any,
  user_id: string,
  vote_amount: number,
  vote_pick_id: number
): Promise<{ success: boolean; star_candy_used: number; star_candy_bonus_used: number }> {
  try {
    const { rows } = await queryWithClient(client, `
      SELECT id, star_candy, star_candy_bonus
      FROM user_profiles
      WHERE id = $1
      FOR UPDATE
    `, user_id);
    
    if (rows.length === 0) {
      throw new Error('User not found');
    }
    
    const { id, star_candy, star_candy_bonus } = rows[0];
    const totalStarCandy = star_candy + star_candy_bonus;
    
    if (totalStarCandy < vote_amount || vote_amount <= 0) {
      return { success: false, star_candy_used: 0, star_candy_bonus_used: 0 };
    }
    
    let remainingAmount = vote_amount;
    let star_candy_bonus_used = 0;
    let star_candy_used = 0;
    
    // 1. 먼저 보너스 캔디 사용
    if (star_candy_bonus > 0 && remainingAmount > 0) {
      const { rows: bonusRows } = await queryWithClient(client, `
        SELECT id, remain_amount
        FROM star_candy_bonus_history
        WHERE user_id = $1
          AND expired_dt > NOW()
          AND remain_amount > 0
        ORDER BY created_at ASC
        FOR UPDATE
      `, user_id);
      
      for (const bonusRow of bonusRows) {
        const { id: bonusId, remain_amount: bonusAmount } = bonusRow;
        if (remainingAmount <= 0) break;
        
        if (bonusAmount >= remainingAmount) {
          await deductStarCandyBonus(client, user_id, remainingAmount, bonusId, vote_pick_id);
          star_candy_bonus_used += remainingAmount;
          remainingAmount = 0;
        } else {
          await deductStarCandyBonus(client, user_id, bonusAmount, bonusId, vote_pick_id);
          star_candy_bonus_used += bonusAmount;
          remainingAmount -= bonusAmount;
        }
      }
    }
    
    // 2. 남은 금액은 일반 캔디 사용
    if (remainingAmount > 0) {
      await deductStarCandy(client, user_id, remainingAmount, vote_pick_id);
      star_candy_used = remainingAmount;
    }
    
    return { 
      success: true, 
      star_candy_used, 
      star_candy_bonus_used 
    };
  } catch (error) {
    console.error('Error in canVoteAndDeduct function:', error);
    throw error;
  }
}



async function performTransaction(
  connection: any, 
  vote_id: number, 
  vote_item_id: number, 
  amount: number, 
  user_id: string,
  star_candy_usage: number,
  star_candy_bonus_usage: number
) {
  await connection.queryObject('BEGIN');
  
  try {
    // 1. vote_pick 레코드 생성 (분리된 사용량 포함)
    const votePickResult = await queryWithClient(connection, `
      INSERT INTO vote_pick (vote_id, vote_item_id, amount, user_id, star_candy_usage, star_candy_bonus_usage)
      VALUES ($1, $2, $3, $4, $5, $6) RETURNING id
    `, vote_id, vote_item_id, amount, user_id, star_candy_usage, star_candy_bonus_usage);
    
    const vote_pick_id = votePickResult.rows[0].id;
    
    // 2. 투표 가능 여부 확인 및 차감 (실제 사용량 산출)
    const voteResult = await canVoteAndDeduct(connection, user_id, amount, vote_pick_id);
    
    if (!voteResult.success) {
      throw new Error('Insufficient star_candy and star_candy_bonus to vote');
    }
    
    // 2-1. 실제 사용량으로 vote_pick 업데이트
    await queryWithClient(connection, `
      UPDATE vote_pick
      SET star_candy_usage = $1,
          star_candy_bonus_usage = $2
      WHERE id = $3
    `, voteResult.star_candy_used, voteResult.star_candy_bonus_used, vote_pick_id);
    
    // 3. 트리거가 반영한 최신 합계 조회 (덮어쓰기 없이 읽기만)
    const updatedTotalsResult = await queryWithClient(connection, `
      SELECT vote_total, star_candy_total, star_candy_bonus_total
      FROM vote_item
      WHERE id = $1
    `, vote_item_id);

    const updatedVoteTotal = updatedTotalsResult.rows.length > 0 ? updatedTotalsResult.rows[0].vote_total : 0;
    const existingVoteTotal = updatedVoteTotal - amount;

    await connection.queryObject('COMMIT');
    
    return {
      existingVoteTotal,
      addedVoteTotal: amount,
      updatedVoteTotal,
      starCandyUsed: voteResult.star_candy_used,
      starCandyBonusUsed: voteResult.star_candy_bonus_used,
      updatedAt: new Date().toISOString()
    };
  } catch (error) {
    await connection.queryObject('ROLLBACK');
    console.error('Error in performTransaction function:', error);
    throw error;
  }
}

Deno.serve(async (req) => {
  // CORS 처리
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    {
      global: {
        headers: {
          Authorization: req.headers.get('Authorization') ?? ''
        }
      }
    }
  );
  
  try {
    const { 
      vote_id, 
      vote_item_id, 
      amount, 
      user_id, 
      star_candy_usage, 
      star_candy_bonus_usage 
    } = await req.json();
    
    console.log('Request data:', {
      vote_id,
      vote_item_id,
      amount,
      user_id,
      star_candy_usage,
      star_candy_bonus_usage
    });
    
    // 입력 검증
    if (!vote_id || !vote_item_id || !amount || !user_id) {
      return new Response(JSON.stringify({
        error: 'Missing required fields'
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      });
    }
    
    if (star_candy_usage + star_candy_bonus_usage !== amount) {
      return new Response(JSON.stringify({
        error: 'Usage amounts do not match total amount'
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      });
    }
    

    
    // 사용자 확인
    const { user_profiles, error: userError } = await getUserProfiles(supabaseClient, user_id);
    if (userError || !user_profiles) {
      return new Response(JSON.stringify({
        error: 'User not found or other error occurred'
      }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400
      });
    }
    
    const connection = await pool.connect();
    
    try {
      const transactionResult = await performTransaction(
        connection, 
        vote_id, 
        vote_item_id, 
        amount, 
        user_id,
        star_candy_usage,
        star_candy_bonus_usage
      );
      
      return new Response(JSON.stringify(transactionResult), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      });
    } catch (e) {
      console.error('Error occurred during transaction:', e);
      throw e;
    } finally {
      try {
        connection.release();
      } catch (_) {
        // ignore release errors
      }
    }
  } catch (error) {
    console.error('Unexpected error occurred:', error);
    return new Response(JSON.stringify({
      error: 'Unexpected error occurred'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500
    });
  }
}); 