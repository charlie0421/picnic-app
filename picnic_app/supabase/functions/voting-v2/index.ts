import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { Pool } from 'https://deno.land/x/postgres@v0.17.0/mod.ts';
import { corsHeaders } from '../_shared/cors.ts';

const databaseUrl = Deno.env.get('SUPABASE_DB_URL');
const pool = new Pool(databaseUrl, 3, true);

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

// star_candy 차감 (사용량 기록 포함)
async function deductStarCandy(user_id: string, amount: number, vote_pick_id: number) {
  const { rows } = await queryDatabase(`
    SELECT id, star_candy
    FROM user_profiles
    WHERE id = $1
  `, user_id);
  
  if (rows.length === 0) {
    throw new Error('User not found');
  }
  
  const { id, star_candy } = rows[0];
  
  await queryDatabase(`
    INSERT INTO star_candy_history (type, user_id, amount, vote_pick_id)
    VALUES ('VOTE', $1, $2, $3)
  `, user_id, amount, vote_pick_id);
  
  await queryDatabase(`
    UPDATE user_profiles
    SET star_candy = GREATEST(star_candy - $1, 0)
    WHERE id = $2
  `, amount, id);
}

// star_candy_bonus 차감 (사용량 기록 포함)
async function deductStarCandyBonus(user_id: string, amount: number, bonusId: string, vote_pick_id: number) {
  await queryDatabase(`
    UPDATE star_candy_bonus_history
    SET remain_amount = GREATEST(remain_amount - $1, 0),
        updated_at = NOW()
    WHERE id = $2
  `, amount, bonusId);
  
  await queryDatabase(`
    INSERT INTO star_candy_bonus_history (user_id, amount, remain_amount, parent_id, vote_pick_id)
    VALUES ($1, $2, $3, $4, $5)
  `, user_id, amount, amount, bonusId, vote_pick_id);
  
  await queryDatabase(`
    UPDATE user_profiles
    SET star_candy_bonus = GREATEST(star_candy_bonus - $1, 0)
    WHERE id = $2
  `, amount, user_id);
}

// 투표 가능 여부 확인 및 차감 (분리된 사용량 반환)
async function canVoteAndDeduct(
  user_id: string, 
  vote_amount: number, 
  vote_pick_id: number
): Promise<{ success: boolean; star_candy_used: number; star_candy_bonus_used: number }> {
  try {
    const { rows } = await queryDatabase(`
      SELECT id, star_candy, star_candy_bonus
      FROM user_profiles
      WHERE id = $1
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
      const { rows: bonusRows } = await queryDatabase(`
        SELECT id, remain_amount
        FROM star_candy_bonus_history
        WHERE user_id = $1
          AND expired_dt > NOW()
          AND remain_amount > 0
        ORDER BY created_at ASC
      `, user_id);
      
      for (const bonusRow of bonusRows) {
        const { id: bonusId, remain_amount: bonusAmount } = bonusRow;
        if (remainingAmount <= 0) break;
        
        if (bonusAmount >= remainingAmount) {
          await deductStarCandyBonus(user_id, remainingAmount, bonusId, vote_pick_id);
          star_candy_bonus_used += remainingAmount;
          remainingAmount = 0;
        } else {
          await deductStarCandyBonus(user_id, bonusAmount, bonusId, vote_pick_id);
          star_candy_bonus_used += bonusAmount;
          remainingAmount -= bonusAmount;
        }
      }
    }
    
    // 2. 남은 금액은 일반 캔디 사용
    if (remainingAmount > 0) {
      await deductStarCandy(user_id, remainingAmount, vote_pick_id);
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
    const votePickResult = await queryDatabase(`
      INSERT INTO vote_pick (vote_id, vote_item_id, amount, user_id, star_candy_usage, star_candy_bonus_usage)
      VALUES ($1, $2, $3, $4, $5, $6) RETURNING id
    `, vote_id, vote_item_id, amount, user_id, star_candy_usage, star_candy_bonus_usage);
    
    const vote_pick_id = votePickResult.rows[0].id;
    
    // 2. 투표 가능 여부 확인 및 차감
    const voteResult = await canVoteAndDeduct(user_id, amount, vote_pick_id);
    
    if (!voteResult.success) {
      throw new Error('Insufficient star_candy and star_candy_bonus to vote');
    }
    
    // 3. vote_item 총계 업데이트 (분리된 사용량 포함)
    const voteTotalResult = await queryDatabase(`
      SELECT vote_total, star_candy_total, star_candy_bonus_total
      FROM vote_item
      WHERE id = $1
    `, vote_item_id);
    
    const existingVoteTotal = voteTotalResult.rows.length > 0 ? voteTotalResult.rows[0].vote_total : 0;
    const existingStarCandyTotal = voteTotalResult.rows.length > 0 ? voteTotalResult.rows[0].star_candy_total : 0;
    const existingStarCandyBonusTotal = voteTotalResult.rows.length > 0 ? voteTotalResult.rows[0].star_candy_bonus_total : 0;
    
    await queryDatabase(`
      UPDATE vote_item
      SET 
        vote_total = vote_total + $1,
        star_candy_total = star_candy_total + $2,
        star_candy_bonus_total = star_candy_bonus_total + $3
      WHERE id = $4
    `, amount, star_candy_usage, star_candy_bonus_usage, vote_item_id);
    
    await connection.queryObject('COMMIT');
    connection.release();
    
    return {
      existingVoteTotal,
      addedVoteTotal: amount,
      updatedVoteTotal: existingVoteTotal + amount,
      starCandyUsed: star_candy_usage,
      starCandyBonusUsed: star_candy_bonus_usage,
      updatedAt: new Date().toISOString()
    };
  } catch (error) {
    await connection.queryObject('ROLLBACK');
    connection.release();
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
      await connection.queryObject('ROLLBACK');
      connection.release();
      console.error('Error occurred during transaction:', e);
      throw e;
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