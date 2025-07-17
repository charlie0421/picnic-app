import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { Pool } from 'https://deno.land/x/postgres@v0.17.0/mod.ts';

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
    console.log('Fetching user profiles:', user_id);
    const { data: user_profiles, error } = await supabaseClient
      .from('user_profiles')
      .select('id, star_candy, jma_candy')
      .eq('id', user_id);
    
    if (error) {
      console.error('Error fetching user profiles:', error);
      throw error;
    }
    
    return {
      user_profiles,
      error: null
    };
  } catch (error) {
    return {
      user_profiles: null,
      error
    };
  }
}

async function deductStarCandy(user_id: string, amount: number, exchange_id: string) {
  await queryDatabase(`
    UPDATE user_profiles
    SET star_candy = GREATEST(star_candy - $1, 0)
    WHERE id = $2
  `, amount, user_id);

  // 별사탕 사용 히스토리 기록  
  await queryDatabase(`
    INSERT INTO star_candy_history (user_id, amount, remain_amount, parent_id, exchange_id, type)
    VALUES ($1, $2, 0, NULL, $3, 'EXCHANGE_TO_JMA')
  `, user_id, amount, exchange_id);
}

async function addJmaCandy(user_id: string, amount: number, exchange_id: string) {
  await queryDatabase(`
    UPDATE user_profiles
    SET jma_candy = COALESCE(jma_candy, 0) + $1
    WHERE id = $2
  `, amount, user_id);

  // JMA 캔디 추가 히스토리 기록
  await queryDatabase(`
    INSERT INTO jma_candy_history (type, user_id, amount, exchange_id)
    VALUES ('EXCHANGE_FROM_STAR', $1, $2, $3)
  `, user_id, amount, exchange_id);
}

async function performExchange(connection: any, user_id: string, star_candy_amount: number, jma_candy_amount: number) {
  await connection.queryObject('BEGIN');
  
  try {
    // 사용자 현재 보유량 확인
    const { rows } = await queryDatabase(`
      SELECT id, star_candy, jma_candy
      FROM user_profiles
      WHERE id = $1
    `, user_id);
    
    if (rows.length === 0) {
      throw new Error('User not found');
    }
    
    const { id, star_candy, jma_candy } = rows[0];
    
    // 교환 비율 검증 (3:1)
    if (star_candy_amount !== jma_candy_amount * 3) {
      throw new Error('Invalid exchange ratio. Must be 3:1 (star_candy:jma_candy)');
    }
    
    // 보유 별사탕 확인
    if (star_candy < star_candy_amount) {
      throw new Error('Insufficient star_candy');
    }
    
    // 교환 기록 생성
    const exchangeResult = await queryDatabase(`
      INSERT INTO jma_exchange_history (user_id, star_candy_amount, jma_candy_amount, exchange_rate)
      VALUES ($1, $2, $3, 3) RETURNING id
    `, user_id, star_candy_amount, jma_candy_amount);
    
    const exchange_id = exchangeResult.rows[0].id;
    
    // 별사탕 차감
    await deductStarCandy(user_id, star_candy_amount, exchange_id);
    
    // JMA 캔디 추가
    await addJmaCandy(user_id, jma_candy_amount, exchange_id);
    
    await connection.queryObject('COMMIT');
    connection.release();
    
    return {
      exchange_id,
      star_candy_bonus_used: star_candy_amount,
      jma_candy_received: jma_candy_amount,
      previous_star_candy_bonus: star_candy_bonus,
      previous_jma_candy: jma_candy || 0,
      new_star_candy_bonus: star_candy_bonus - star_candy_amount,
      new_jma_candy: (jma_candy || 0) + jma_candy_amount,
      exchange_rate: '3:1',
      exchanged_at: new Date().toISOString()
    };
  } catch (error) {
    await connection.queryObject('ROLLBACK');
    connection.release();
    console.error('Error in performExchange function:', error);
    throw error;
  }
}

Deno.serve(async (req) => {
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
    const { user_id, star_candy_amount, jma_candy_amount } = await req.json();
    
    console.log('Star Candy to JMA Exchange request:', {
      user_id,
      star_candy_amount,
      jma_candy_amount
    });
    
    // 입력 검증
    if (!user_id || !star_candy_amount || !jma_candy_amount) {
      return new Response(JSON.stringify({
        error: 'Missing required fields: user_id, star_candy_amount, jma_candy_amount'
      }), {
        headers: {
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    
    if (star_candy_amount <= 0 || jma_candy_amount <= 0) {
      return new Response(JSON.stringify({
        error: 'Amounts must be positive numbers'
      }), {
        headers: {
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    
    // 3:1 비율 검증
    if (star_candy_amount !== jma_candy_amount * 3) {
      return new Response(JSON.stringify({
        error: 'Invalid exchange ratio. Must be 3:1 (star_candy:jma_candy)'
      }), {
        headers: {
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    
    const { user_profiles, error: userError } = await getUserProfiles(supabaseClient, user_id);
    
    if (userError || !user_profiles || user_profiles.length === 0) {
      return new Response(JSON.stringify({
        error: 'User not found'
      }), {
        headers: {
          'Content-Type': 'application/json'
        },
        status: 404
      });
    }
    
    const connection = await pool.connect();
    
    try {
      const exchangeResult = await performExchange(connection, user_id, star_candy_amount, jma_candy_amount);
      
      return new Response(JSON.stringify({
        success: true,
        data: exchangeResult
      }), {
        headers: {
          'Content-Type': 'application/json'
        },
        status: 200
      });
    } catch (e) {
      await connection.queryObject('ROLLBACK');
      connection.release();
      console.error('Error occurred during exchange transaction:', e);
      throw e;
    }
  } catch (error) {
    console.error('Unexpected error occurred in exchange:', error);
    return new Response(JSON.stringify({
      error: error.message || 'Unexpected error occurred'
    }), {
      headers: {
        'Content-Type': 'application/json'
      },
      status: 500
    });
  }
}); 