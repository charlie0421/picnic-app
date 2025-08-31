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
// Rate limit configs
const RATE_LIMIT_WINDOW_SECONDS = 10;
const RATE_LIMIT_MAX_REQUESTS = 3; // per user or IP within window
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
async function withRetryOnDeadlock(fn, options = {}) {
  const {
    retries = 9,
    baseDelayMs = 150,
    maxDelayMs = 1500
  } = options;
  let attempt = 0;
  while (true) {
    try {
      return await fn();
    } catch (err) {
      const pgCode = err?.fields?.code;
      const isDeadlock = pgCode === '40P01';
      const isLockTimeout = pgCode === '55P03' || /lock timeout/i.test(String(err?.message ?? ''));
      if ((isDeadlock || isLockTimeout) && attempt < retries) {
        const delay = Math.min(maxDelayMs, baseDelayMs * Math.pow(2, attempt)) + Math.floor(Math.random() * 50);
        attempt += 1;
        console.warn(`[voting-v2] retrying due to ${isDeadlock ? 'deadlock' : 'lock timeout'} (attempt ${attempt}/${retries}) after ${delay}ms`);
        await sleep(delay);
        continue;
      }
      throw err;
    }
  }
}
async function queryDatabase(query, ...args) {
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
  } finally{
    client.release();
  }
}
// 트랜잭션 범위 advisory lock (vote_item 단위 직렬화)
async function acquireVoteItemAdvisoryLock(client, vote_item_id) {
  // 동일 vote_item_id에 대한 동시 트랜잭션을 직렬화하여 교착을 원천 차단
  // 두 인자 버전: (namespace int4, key int4)
  // 옵션 B에서는 advisory lock을 제거하여 전체 처리량을 높임 (함수 남겨두되 미사용)
  return;
}
// Execute a query using an existing transaction/client
async function queryWithClient(client, query, ...args) {
  try {
    const result = await client.queryObject(query, args);
    return result;
  } catch (error) {
    console.error('Error executing query (tx):', {
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
// --- Utility: client IP extraction ---
function getClientIp(req) {
  const xf = req.headers.get('x-forwarded-for') || req.headers.get('X-Forwarded-For') || '';
  if (xf) {
    const parts = xf.split(',').map((s)=>s.trim()).filter(Boolean);
    if (parts.length > 0) return parts[0];
  }
  return req.headers.get('x-real-ip') || req.headers.get('X-Real-IP') || 'unknown';
}

// --- Request logging (table with graceful fallback) ---
async function ensureRequestLogTable() {
  try {
    await queryDatabase(`
      CREATE TABLE IF NOT EXISTS function_request_log (
        id BIGSERIAL PRIMARY KEY,
        ts TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        function_name TEXT NOT NULL,
        user_id UUID,
        ip TEXT,
        ok BOOLEAN,
        code INT,
        reason TEXT,
        meta JSONB
      );
    `);
    await queryDatabase(`CREATE INDEX IF NOT EXISTS idx_frlog_user_ts ON function_request_log (user_id, ts DESC);`);
    await queryDatabase(`CREATE INDEX IF NOT EXISTS idx_frlog_ip_ts ON function_request_log (ip, ts DESC);`);
    await queryDatabase(`CREATE INDEX IF NOT EXISTS idx_frlog_fn_ts ON function_request_log (function_name, ts DESC);`);
  } catch (e) {
    console.warn('[voting-v2] ensureRequestLogTable failed (fallback to console only)', e);
  }
}

async function logRequestEvent({ functionName, userId, ip, ok, code, reason, meta }) {
  try {
    await queryDatabase(
      `INSERT INTO function_request_log (function_name, user_id, ip, ok, code, reason, meta)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      functionName, userId || null, ip || null, ok, code || null, reason || null, meta ? JSON.stringify(meta) : null
    );
  } catch (e) {
    console.warn('[voting-v2] logRequestEvent fallback console', { functionName, userId, ip, ok, code, reason, meta, error: String(e) });
  }
}

async function checkRateLimit({ functionName, userId, ip }) {
  try {
    const { rows } = await queryDatabase(
      `SELECT COUNT(*)::int AS cnt
         FROM function_request_log
        WHERE function_name = $1
          AND ts > NOW() - INTERVAL '${RATE_LIMIT_WINDOW_SECONDS} seconds'
          AND (user_id = $2 OR ip = $3)`,
      functionName, userId || null, ip || null
    );
    const cnt = rows?.[0]?.cnt ?? 0;
    return cnt >= RATE_LIMIT_MAX_REQUESTS;
  } catch (e) {
    console.warn('[voting-v2] checkRateLimit failed, skipping RL', e);
    return false;
  }
}
// 투표 오픈 여부 확인 (DB 시간 기준, KST/UTC 혼선 방지)
async function ensureVoteOpenDb(client, vote_id) {
  try {
    // 1) end_at 기준 시도
    try {
      const { rows } = await queryWithClient(client, `
        SELECT 
          (
            start_at IS NULL OR
            CASE WHEN pg_typeof(start_at)::text = 'timestamp without time zone'
                 THEN (now() AT TIME ZONE 'Asia/Seoul')::timestamp >= start_at
                 ELSE now() >= start_at
            END
          ) AS started,
          (
            end_at IS NULL OR 
            CASE WHEN pg_typeof(end_at)::text = 'timestamp without time zone'
                 THEN (now() AT TIME ZONE 'Asia/Seoul')::timestamp < end_at
                 ELSE now() < end_at
            END
          ) AS not_ended
        FROM vote
        WHERE id = $1
        FOR SHARE
      `, vote_id);
      if (!rows || rows.length === 0) {
        return { open: false, reason: 'not_found' };
      }
      const { started, not_ended } = rows[0];
      const open = Boolean(started) && Boolean(not_ended);
      let reason = null;
      if (!started) reason = 'not_started';
      else if (!not_ended) reason = 'ended';
      return { open, reason };
    } catch (e1) {
      console.warn('[voting-v2] end_at check failed; trying stop_at fallback', e1);
      // 2) stop_at 기준 폴백 (일부 스키마에서 사용)
      const { rows } = await queryWithClient(client, `
        SELECT 
          (
            start_at IS NULL OR
            CASE WHEN pg_typeof(start_at)::text = 'timestamp without time zone'
                 THEN (now() AT TIME ZONE 'Asia/Seoul')::timestamp >= start_at
                 ELSE now() >= start_at
            END
          ) AS started,
          (
            stop_at IS NULL OR 
            CASE WHEN pg_typeof(stop_at)::text = 'timestamp without time zone'
                 THEN (now() AT TIME ZONE 'Asia/Seoul')::timestamp < stop_at
                 ELSE now() < stop_at
            END
          ) AS not_ended
        FROM vote
        WHERE id = $1
        FOR SHARE
      `, vote_id);
      if (!rows || rows.length === 0) {
        return { open: false, reason: 'not_found' };
      }
      const { started, not_ended } = rows[0];
      const open = Boolean(started) && Boolean(not_ended);
      let reason = null;
      if (!started) reason = 'not_started';
      else if (!not_ended) reason = 'ended';
      return { open, reason };
    }
  } catch (e) {
    // 스키마에 start_at/end_at 중 일부가 없더라도 서비스 중단을 피하기 위해 경고 후 통과
    console.warn('[voting-v2] ensureVoteOpenDb check failed; skipping with warning', e);
    return { open: true, reason: 'schema_unknown' };
  }
}
// star_candy 차감 (사용량 기록 포함) — 트랜잭션 내 클라이언트 사용
async function deductStarCandy(client, user_id, amount, vote_pick_id) {
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
}
// star_candy_bonus 차감 (사용량 기록 포함) — 트랜잭션 내 클라이언트 사용
async function deductStarCandyBonus(client, user_id, amount, bonusId, vote_pick_id) {
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
}
// 투표 가능 여부 확인 및 차감 (분리된 사용량 반환) — 트랜잭션 내 수행
async function canVoteAndDeduct(client, user_id, vote_amount, vote_pick_id) {
  try {
    // 원자 차감: 단일 UPDATE에서 보너스 우선 사용을 계산하고 동시에 차감
    const updateRes = await queryWithClient(client, `
      UPDATE user_profiles u
      SET 
        star_candy_bonus = u.star_candy_bonus - LEAST(u.star_candy_bonus, $2),
        star_candy       = u.star_candy - GREATEST($2 - LEAST(u.star_candy_bonus, $2), 0),
        updated_at       = NOW()
      WHERE u.id = $1
        AND (u.star_candy + u.star_candy_bonus) >= $2
      RETURNING 
        GREATEST($2 - LEAST(u.star_candy_bonus, $2), 0)::int AS star_candy_used,
        LEAST(u.star_candy_bonus, $2)::int                AS star_candy_bonus_used
    `, user_id, vote_amount);
    if (updateRes.rows.length === 0) {
      return { success: false, star_candy_used: 0, star_candy_bonus_used: 0 };
    }
    const star_candy_used = updateRes.rows[0].star_candy_used;
    const star_candy_bonus_used = updateRes.rows[0].star_candy_bonus_used;
    // 히스토리 기록(경량)
    if (star_candy_bonus_used > 0) {
      await queryWithClient(client, `
        INSERT INTO star_candy_bonus_history (user_id, amount, remain_amount, parent_id, vote_pick_id)
        VALUES ($1, $2, $2, NULL, $3)
      `, user_id, star_candy_bonus_used, vote_pick_id);
    }
    if (star_candy_used > 0) {
      await queryWithClient(client, `
        INSERT INTO star_candy_history (type, user_id, amount, vote_pick_id)
        VALUES ('VOTE', $1, $2, $3)
      `, user_id, star_candy_used, vote_pick_id);
    }
    return { success: true, star_candy_used, star_candy_bonus_used };
  } catch (error) {
    console.error('Error in canVoteAndDeduct function:', error);
    throw error;
  }
}
async function performTransaction(connection, vote_id, vote_item_id, amount, user_id, star_candy_usage, star_candy_bonus_usage) {
  return withRetryOnDeadlock(async () => {
    await connection.queryObject('BEGIN');
    try {
      // 빠른 실패 설정 + 약간 여유를 두고 재시도 유도
      await connection.queryObject(`SET LOCAL lock_timeout = '10000ms'`);
      // 옵션 B: advisory lock 사용 안 함
      // 1. 먼저 vote_pick INSERT로 레코드 생성 (사용량은 일단 요청값, 실제는 뒤에서 확정)
      const votePickResult = await queryWithClient(connection, `
        INSERT INTO vote_pick (vote_id, vote_item_id, amount, user_id, star_candy_usage, star_candy_bonus_usage)
        VALUES ($1, $2, $3, $4, $5, $6) RETURNING id
      `, vote_id, vote_item_id, amount, user_id, star_candy_usage, star_candy_bonus_usage);
      const vote_pick_id = votePickResult.rows[0].id;
      // 2. 잔액 차감 및 실제 사용량 확정 (NOWAIT/ SKIP LOCKED 적용됨)
      const voteResult = await canVoteAndDeduct(connection, user_id, amount, vote_pick_id);
      if (!voteResult.success) {
        throw new Error('Insufficient star_candy and star_candy_bonus to vote');
      }
      await queryWithClient(connection, `
        UPDATE vote_pick
        SET star_candy_usage = $1,
            star_candy_bonus_usage = $2
        WHERE id = $3
      `, voteResult.star_candy_used, voteResult.star_candy_bonus_used, vote_pick_id);
      // 3. 트리거 반영은 결국 같은 트랜잭션 내에서 이뤄짐. 합계 조회는 COMMIT 이후 일반 SELECT로 수행
      await connection.queryObject('COMMIT');
      const updatedTotalsAfter = await queryWithClient(connection, `
        SELECT vote_total, star_candy_total, star_candy_bonus_total
        FROM vote_item
        WHERE id = $1
      `, vote_item_id);
      const updatedVoteTotal = updatedTotalsAfter.rows.length > 0 ? updatedTotalsAfter.rows[0].vote_total : 0;
      const existingVoteTotal = updatedVoteTotal - amount;
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
  });
}
Deno.serve(async (req)=>{
  // CORS 처리
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  const supabaseClient = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', {
    global: {
      headers: {
        Authorization: req.headers.get('Authorization') ?? ''
      }
    }
  });
  try {
    const ip = getClientIp(req);
    await ensureRequestLogTable();
    const { vote_id, vote_item_id, amount, user_id, star_candy_usage, star_candy_bonus_usage } = await req.json();
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
      await logRequestEvent({ functionName: 'voting-v2', userId: user_id, ip, ok: false, code: 400, reason: 'missing_fields', meta: { vote_id, vote_item_id } });
      return new Response(JSON.stringify({
        error: 'Missing required fields'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // 정규화 및 강력한 유효성 검사 (음수/비정수/NaN 차단)
    const voteIdNum = Number(vote_id);
    const voteItemIdNum = Number(vote_item_id);
    const amountNum = Number(amount);
    const starCandyUsageNum = Number(star_candy_usage);
    const starCandyBonusUsageNum = Number(star_candy_bonus_usage);
    if (!Number.isFinite(voteIdNum) || !Number.isInteger(voteIdNum) || voteIdNum <= 0) {
      await logRequestEvent({ functionName: 'voting-v2', userId: user_id, ip, ok: false, code: 400, reason: 'invalid_vote_id', meta: { vote_id } });
      return new Response(JSON.stringify({ error: 'Invalid vote_id' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
    }
    if (!Number.isFinite(voteItemIdNum) || !Number.isInteger(voteItemIdNum) || voteItemIdNum <= 0) {
      await logRequestEvent({ functionName: 'voting-v2', userId: user_id, ip, ok: false, code: 400, reason: 'invalid_vote_item_id', meta: { vote_item_id } });
      return new Response(JSON.stringify({ error: 'Invalid vote_item_id' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
    }
    if (!Number.isFinite(amountNum) || !Number.isInteger(amountNum) || amountNum <= 0) {
      await logRequestEvent({ functionName: 'voting-v2', userId: user_id, ip, ok: false, code: 400, reason: 'invalid_amount', meta: { amount } });
      return new Response(JSON.stringify({ error: 'Invalid amount' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
    }
    if (!Number.isFinite(starCandyUsageNum) || !Number.isInteger(starCandyUsageNum) || starCandyUsageNum < 0) {
      await logRequestEvent({ functionName: 'voting-v2', userId: user_id, ip, ok: false, code: 400, reason: 'invalid_star_candy_usage', meta: { star_candy_usage } });
      return new Response(JSON.stringify({ error: 'Invalid star_candy_usage' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
    }
    if (!Number.isFinite(starCandyBonusUsageNum) || !Number.isInteger(starCandyBonusUsageNum) || starCandyBonusUsageNum < 0) {
      await logRequestEvent({ functionName: 'voting-v2', userId: user_id, ip, ok: false, code: 400, reason: 'invalid_star_candy_bonus_usage', meta: { star_candy_bonus_usage } });
      return new Response(JSON.stringify({ error: 'Invalid star_candy_bonus_usage' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
    }
    if (starCandyUsageNum + starCandyBonusUsageNum !== amountNum) {
      await logRequestEvent({ functionName: 'voting-v2', userId: user_id, ip, ok: false, code: 400, reason: 'usage_mismatch', meta: { amount: amountNum, star_candy_usage: starCandyUsageNum, star_candy_bonus_usage: starCandyBonusUsageNum } });
      return new Response(JSON.stringify({
        error: 'Usage amounts do not match total amount'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // 사용자 확인
    const { user_profiles, error: userError } = await getUserProfiles(supabaseClient, user_id);
    if (userError || !user_profiles) {
      await logRequestEvent({ functionName: 'voting-v2', userId: user_id, ip, ok: false, code: 400, reason: 'user_not_found' });
      return new Response(JSON.stringify({
        error: 'User not found or other error occurred'
      }), {
        headers: {
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // 삭제(비활성) 사용자 차단: deleted_at이 null이 아니면 투표 불가
    if (user_profiles.deleted_at) {
      await logRequestEvent({ functionName: 'voting-v2', userId: user_id, ip, ok: false, code: 403, reason: 'user_deleted' });
      return new Response(JSON.stringify({ error: 'User is deleted or deactivated' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 });
    }
    // Rate limit check (user 또는 IP)
    const isRateLimited = await checkRateLimit({ functionName: 'voting-v2', userId: user_id, ip });
    if (isRateLimited) {
      await logRequestEvent({ functionName: 'voting-v2', userId: user_id, ip, ok: false, code: 429, reason: 'rate_limited' });
      return new Response(JSON.stringify({ error: 'Too many requests' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 429 });
    }
    // 보유 잔액(표 단위) 기준 절대 상한 검증: amount ≤ star_candy + star_candy_bonus
    {
      const regularAvailable = Number(user_profiles.star_candy) || 0;
      const bonusAvailable = Number(user_profiles.star_candy_bonus) || 0;
      const maxPossibleVotes = regularAvailable + bonusAvailable;
      if (amount > maxPossibleVotes) {
        return new Response(JSON.stringify({
          error: 'Vote amount exceeds available balance',
          message: '보유한 별사탕/보너스보다 많은 수의 투표는 할 수 없습니다.',
          requested: amount,
          max_possible: maxPossibleVotes,
          regular_available: regularAvailable,
          bonus_available: bonusAvailable
        }), {
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          },
          status: 400
        });
      }
    }
    const connection = await pool.connect();
    try {
      // 투표 오픈/마감 확인 (트랜잭션 시작 전 빠르게 차단)
      const openCheck = await ensureVoteOpenDb(connection, voteIdNum);
      if (!openCheck.open) {
        const message = openCheck.reason === 'ended'
          ? '투표가 마감되었습니다.'
          : (openCheck.reason === 'not_started' ? '투표가 아직 시작되지 않았습니다.' : '투표 참여가 불가합니다.');
        await logRequestEvent({ functionName: 'voting-v2', userId: user_id, ip, ok: false, code: 403, reason: 'vote_closed', meta: { reason: openCheck.reason } });
        return new Response(JSON.stringify({
          error: 'Vote closed',
          message,
          reason: openCheck.reason ?? null
        }), {
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          },
          status: 403
        });
      }
      const transactionResult = await performTransaction(connection, voteIdNum, voteItemIdNum, amountNum, user_id, starCandyUsageNum, starCandyBonusUsageNum);
      await logRequestEvent({ functionName: 'voting-v2', userId: user_id, ip, ok: true, code: 200, reason: 'ok', meta: { vote_id: voteIdNum, vote_item_id: voteItemIdNum, amount: amountNum } });
      return new Response(JSON.stringify(transactionResult), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 200
      });
    } catch (e) {
      console.error('Error occurred during transaction:', e);
      await logRequestEvent({ functionName: 'voting-v2', userId: user_id, ip, ok: false, code: 500, reason: 'tx_error', meta: { error: String(e?.message || e) } });
      throw e;
    } finally{
      try {
        connection.release();
      } catch (_) {
      // ignore release errors
      }
    }
  } catch (error) {
    console.error('Unexpected error occurred:', error);
    try {
      const ip = getClientIp(req);
      await logRequestEvent({ functionName: 'voting-v2', userId: null, ip, ok: false, code: 500, reason: 'unexpected', meta: { error: String(error?.message || error) } });
    } catch (_) {}
    return new Response(JSON.stringify({
      error: 'Unexpected error occurred'
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 500
    });
  }
});
