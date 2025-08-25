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
    console.log('[expiring-bonus] query OK', { query, args, rows: result?.rows?.length ?? 0 });
    return result;
  } finally {
    client.release();
  }
}

// expired_dt를 KST 기준으로 현재 시점 이후부터 "향후 2달"만 반환
// 경계는 매달 15일 00:00 (KST) 를 기준으로 한다
async function getExpiringBonusByMonth(user_id: string) {
  const sql = `
    WITH params AS (
      SELECT (NOW() AT TIME ZONE 'Asia/Seoul') AS kst_now
    ), bounds AS (
      SELECT CASE
        WHEN EXTRACT(day FROM kst_now) < 15
          THEN date_trunc('month', kst_now) + INTERVAL '15 days'
        ELSE date_trunc('month', kst_now) + INTERVAL '1 month' + INTERVAL '15 days'
      END AS next_15_kst,
      kst_now
      FROM params
    ), win_bounds AS (
      SELECT next_15_kst, (next_15_kst + INTERVAL '1 month') AS second_15_kst, kst_now FROM bounds
    )
    SELECT 
      to_char((expired_dt AT TIME ZONE 'Asia/Seoul'), 'YYYY-MM') AS prediction_month,
      COALESCE(SUM(remain_amount), 0)::bigint AS expiring_amount
    FROM star_candy_bonus_history, win_bounds
    WHERE user_id = $1
      AND remain_amount > 0
      AND (expired_dt AT TIME ZONE 'Asia/Seoul') >= win_bounds.kst_now
      AND (expired_dt AT TIME ZONE 'Asia/Seoul') < win_bounds.second_15_kst
    GROUP BY 1
    ORDER BY 1
    LIMIT 2
  `;
  const { rows } = await queryDatabase(sql, user_id);
  return rows.map((r: any) => ({
    prediction_month: r.prediction_month,
    expiring_amount: Number(r.expiring_amount) || 0
  }));
}

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Supabase 클라이언트: 사용자 인증정보를 전달받아 사용
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
    // 사용자 식별: Authorization 헤더 기반 (JWT 필수)
    const {
      data: { user },
      error: userError
    } = await supabaseClient.auth.getUser();
    if (userError || !user?.id) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    console.log('[expiring-bonus] user', user.id);
    const result = await getExpiringBonusByMonth(user.id);
    console.log('[expiring-bonus] result', result);
    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('[expiring-bonus] error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});


