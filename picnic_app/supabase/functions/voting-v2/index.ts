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
// (removed) function_request_log 관련 기능 비활성화
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
// 사용자 단위 중복 요청 뮤텍스 (인스턴스 로컬)
const userMutex = new Map();
const USER_MUTEX_TTL_MS = parseInt(Deno.env.get('USER_MUTEX_TTL_MS') ?? '1000', 10);
function tryAcquireUserMutex(userId) {
  const now = Date.now();
  const until = userMutex.get(userId) ?? 0;
  if (until > now) return false;
  userMutex.set(userId, now + USER_MUTEX_TTL_MS);
  return true;
}
function releaseUserMutex(userId) {
  userMutex.delete(userId);
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
      const msg = String(err?.message ?? '');
      const isOccConflict = msg.includes('USER_BALANCE_CHANGED') || msg.includes('USER_BUSY');
      if ((isDeadlock || isLockTimeout || isOccConflict) && attempt < retries) {
        const delay = Math.min(maxDelayMs, baseDelayMs * Math.pow(2, attempt)) + Math.floor(Math.random() * 50);
        attempt += 1;
        console.warn(`[voting-v2] retrying due to ${isDeadlock ? 'deadlock' : (isLockTimeout ? 'lock timeout' : 'occ conflict')} (attempt ${attempt}/${retries}) after ${delay}ms`);
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
  // 큐 기반 집계로 전환되어 행 경합이 크게 줄었으므로 advisory lock은 비활성화
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

// 보너스 버킷에서 사용량 차감 (가까운 만료일 순)
async function spendBonusBuckets(client, user_id, bonusToUse, vote_pick_id) {
  let remaining = Number(bonusToUse) || 0;
  if (remaining <= 0) return 0;
  // 만료 임박 순서로 버킷 잠금 후 차감
  const { rows } = await queryWithClient(client, `
    SELECT id, remain_amount::int AS remain_amount
    FROM star_candy_bonus_history
    WHERE user_id = $1
      AND parent_id IS NULL
      AND deleted_at IS NULL
      AND remain_amount > 0
      AND expired_dt > (now() AT TIME ZONE 'Asia/Seoul')
    ORDER BY expired_dt ASC
    FOR UPDATE SKIP LOCKED
  `, user_id);
  let consumed = 0;
  for (const row of rows) {
    if (remaining <= 0) break;
    const bucketId = row.id;
    const bucketRemain = Number(row.remain_amount) || 0;
    if (bucketRemain <= 0) continue;
    const use = Math.min(bucketRemain, remaining);
    // 버킷 차감
    await queryWithClient(client, `
      UPDATE star_candy_bonus_history
      SET remain_amount = GREATEST(remain_amount - $1, 0), updated_at = NOW()
      WHERE id = $2
    `, use, bucketId);
    // 사용 로그(잔액은 트리거 합산 대상 아님: NULL)
    await queryWithClient(client, `
      INSERT INTO star_candy_bonus_history (user_id, amount, remain_amount, parent_id, vote_pick_id)
      VALUES ($1, $2, 0, $3, $4)
    `, user_id, use, bucketId, (vote_pick_id ?? null));
    remaining -= use;
    consumed += use;
  }
  return consumed;
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
// function_request_log/레이트리밋 제거
// 투표 오픈 여부 확인 (DB 시간 기준, KST/UTC 혼선 방지)
async function ensureVoteOpenDb(client, vote_id) {
  try {
    // 스키마 점검: end_at/stop_at 존재 여부 확인
    const meta = await queryWithClient(client, `
      SELECT
        MAX(CASE WHEN column_name = 'end_at' THEN 1 ELSE 0 END)::int AS has_end,
        MAX(CASE WHEN column_name = 'stop_at' THEN 1 ELSE 0 END)::int AS has_stop
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'vote'
    `);
    const hasEnd = (meta.rows?.[0]?.has_end ?? 0) === 1;
    const hasStop = (meta.rows?.[0]?.has_stop ?? 0) === 1;

    if (!hasEnd && !hasStop) {
      console.warn('[voting-v2] vote table has no end_at/stop_at; allowing by default');
      return { open: true, reason: 'no_end_or_stop' };
    }

    const timeCol = hasEnd ? 'end_at' : 'stop_at';
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
          ${hasEnd ? 'end_at' : 'stop_at'} IS NULL OR 
          CASE WHEN pg_typeof(${hasEnd ? 'end_at' : 'stop_at'})::text = 'timestamp without time zone'
               THEN (now() AT TIME ZONE 'Asia/Seoul')::timestamp < ${hasEnd ? 'end_at' : 'stop_at'}
               ELSE now() < ${hasEnd ? 'end_at' : 'stop_at'}
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
  } catch (e) {
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
    // 1) 현재 잔액 조회 (락 없이)
    const sel = await queryWithClient(client, `
      SELECT star_candy::int AS star_candy, star_candy_bonus::int AS star_candy_bonus
      FROM user_profiles
      WHERE id = $1
    `, user_id);
    if (sel.rows.length === 0) {
      throw new Error('User not found');
    }
    const origStar = Number(sel.rows[0].star_candy) || 0;
    const origBonus = Number(sel.rows[0].star_candy_bonus) || 0;
    const total = origStar + origBonus;
    if (total < vote_amount) {
      return { success: false, star_candy_used: 0, star_candy_bonus_used: 0 };
    }
    // 2) 사용량 계산 (보너스 우선)
    const useBonus = Math.min(origBonus, vote_amount);
    const useRegular = Math.max(vote_amount - useBonus, 0);
    // 3) 낙관적 갱신: 원본 값이 그대로일 때만 차감
    const upd = await queryWithClient(client, `
      UPDATE user_profiles u
      SET
        star_candy_bonus = u.star_candy_bonus - $2,
        star_candy       = u.star_candy - $3,
        updated_at       = NOW()
      WHERE u.id = $1
        AND u.star_candy = $4
        AND u.star_candy_bonus = $5
      RETURNING $3::int AS star_candy_used, $2::int AS star_candy_bonus_used
    `, user_id, useBonus, useRegular, origStar, origBonus);
    if (upd.rows.length === 0) {
      // 동시 변경으로 실패 → 상위 재시도 로직으로 넘겨 빠르게 재시도
      throw new Error('USER_BALANCE_CHANGED');
    }
    const star_candy_used = upd.rows[0].star_candy_used;
    const star_candy_bonus_used = upd.rows[0].star_candy_bonus_used;
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
      await connection.queryObject(`SET LOCAL lock_timeout = '2000ms'`);
      // 동일 vote_item_id 단위로 직렬화하여 트리거의 vote_item 갱신 경합을 완화
      await acquireVoteItemAdvisoryLock(connection, vote_item_id);
      // 사용자 행 사전 잠금 제거 (표준 FOR UPDATE 경합은 재시도 로직이 처리)
      // 옵션 B: advisory lock 사용 안 함
      // 0. 인스턴스 간 분산 뮤텍스: user_id 기반 트랜잭션 범위 advisory try-lock (즉시 실패)
      {
        const lockRes = await queryWithClient(connection, `
          SELECT pg_try_advisory_xact_lock((('x' || substr(md5($1), 1, 16))::bit(64))::bigint) AS ok
        `, user_id);
        const ok = Boolean(lockRes.rows?.[0]?.ok);
        if (!ok) {
          throw new Error('USER_BUSY');
        }
      }
      // 1. 먼저 vote_pick INSERT로 레코드 생성 (사용량은 일단 요청값, 실제는 뒤에서 확정)
      const votePickResult = await queryWithClient(connection, `
        INSERT INTO vote_pick (vote_id, vote_item_id, amount, user_id, star_candy_usage, star_candy_bonus_usage)
        VALUES ($1, $2, $3, $4, $5, $6) RETURNING id
      `, vote_id, vote_item_id, amount, user_id, star_candy_usage, star_candy_bonus_usage);
      const vote_pick_id = votePickResult.rows[0].id;
      // 2. 잔액 차감 및 실제 사용량 확정 (행 잠금은 표준 FOR UPDATE로 처리)
      const voteResult = await canVoteAndDeduct(connection, user_id, amount, vote_pick_id);
      if (!voteResult.success) {
        throw new Error('Insufficient star_candy and star_candy_bonus to vote');
      }
      // 3. COMMIT 이후: 현재 집계값을 조회하고, 응답은 "예측값"(현재값 + 이번 투표량)으로 반환
      await connection.queryObject('COMMIT');
      // 보너스 버킷 차감 및 vote_pick 사용량 업데이트는 커밋 후에 비차단으로 처리하여 user_profiles 락 보유 시간을 단축
      try {
        if (voteResult.star_candy_bonus_used > 0) {
          await spendBonusBuckets(connection, user_id, voteResult.star_candy_bonus_used, vote_pick_id);
        }
        await queryWithClient(connection, `
          UPDATE vote_pick
          SET star_candy_usage = $1,
              star_candy_bonus_usage = $2
          WHERE id = $3
        `, voteResult.star_candy_used, voteResult.star_candy_bonus_used, vote_pick_id);
      } catch (_) {}

      const currentTotals = await queryWithClient(connection, `
        SELECT vote_total, star_candy_total, star_candy_bonus_total
        FROM vote_item
        WHERE id = $1
      `, vote_item_id);
      const currentVoteTotal = currentTotals.rows.length > 0 ? (Number(currentTotals.rows[0].vote_total) || 0) : 0;
      const predictedUpdatedVoteTotal = currentVoteTotal + amount;

      // 4. Lazy flush: 1초 대기 후 집계 실행 (요청당 ~1.1s 추가 지연)
      try {
        await sleep(1100);
        await queryWithClient(connection, 'SELECT public.process_vote_item_queue($1)', vote_item_id);
      } catch (e) {
        console.warn('[voting-v2] process_vote_item_queue warn (ignored):', String(e?.message ?? e));
      }

      return {
        existingVoteTotal: currentVoteTotal,
        addedVoteTotal: amount,
        updatedVoteTotal: predictedUpdatedVoteTotal,
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
    const { vote_id, vote_item_id, amount, user_id, star_candy_usage, star_candy_bonus_usage } = await req.json();
    let __mutexAcquired = false;
    try {
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
      console.warn('[voting-v2] missing_fields', { ip, vote_id, vote_item_id, amount, user_id });
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
      console.warn('[voting-v2] invalid_vote_id', { ip, vote_id });
      return new Response(JSON.stringify({ error: 'Invalid vote_id' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
    }
    if (!Number.isFinite(voteItemIdNum) || !Number.isInteger(voteItemIdNum) || voteItemIdNum <= 0) {
      console.warn('[voting-v2] invalid_vote_item_id', { ip, vote_item_id });
      return new Response(JSON.stringify({ error: 'Invalid vote_item_id' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
    }
    if (!Number.isFinite(amountNum) || !Number.isInteger(amountNum) || amountNum <= 0) {
      console.warn('[voting-v2] invalid_amount', { ip, amount });
      return new Response(JSON.stringify({ error: 'Invalid amount' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
    }
    if (!Number.isFinite(starCandyUsageNum) || !Number.isInteger(starCandyUsageNum) || starCandyUsageNum < 0) {
      console.warn('[voting-v2] invalid_star_candy_usage', { ip, star_candy_usage });
      return new Response(JSON.stringify({ error: 'Invalid star_candy_usage' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
    }
    if (!Number.isFinite(starCandyBonusUsageNum) || !Number.isInteger(starCandyBonusUsageNum) || starCandyBonusUsageNum < 0) {
      console.warn('[voting-v2] invalid_star_candy_bonus_usage', { ip, star_candy_bonus_usage });
      return new Response(JSON.stringify({ error: 'Invalid star_candy_bonus_usage' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
    }
    if (starCandyUsageNum + starCandyBonusUsageNum !== amountNum) {
      console.warn('[voting-v2] usage_mismatch', { ip, amount: amountNum, star_candy_usage: starCandyUsageNum, star_candy_bonus_usage: starCandyBonusUsageNum });
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
    // 사용자 단위 중복 요청 뮤텍스 (1초 TTL, 대기 없이 즉시 거절)
    if (!tryAcquireUserMutex(user_id)) {
      return new Response(JSON.stringify({ error: 'Too many requests. Please retry shortly.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 429
      });
    }
    __mutexAcquired = true;
    // 사용자 확인
    const { user_profiles, error: userError } = await getUserProfiles(supabaseClient, user_id);
    if (userError || !user_profiles) {
      console.warn('[voting-v2] user_not_found', { ip, user_id, userError });
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
      console.warn('[voting-v2] user_deleted', { ip, user_id, deleted_at: user_profiles.deleted_at });
      return new Response(JSON.stringify({ error: 'User is deleted or deactivated' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 });
    }
    // Rate limit check (user 또는 IP)
    // (rate limit removed)
    // 보유 잔액(표 단위) 기준 절대 상한 검증: amount ≤ star_candy + star_candy_bonus
    {
      const regularAvailable = Number(user_profiles.star_candy) || 0;
      const bonusAvailable = Number(user_profiles.star_candy_bonus) || 0;
      const maxPossibleVotes = regularAvailable + bonusAvailable;
      if (amount > maxPossibleVotes) {
        console.warn('[voting-v2] exceeds_balance', { ip, user_id, amount, maxPossibleVotes, regularAvailable, bonusAvailable });
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
        console.warn('[voting-v2] vote_closed', { ip, user_id, vote_id: voteIdNum, reason: openCheck.reason });
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
      return new Response(JSON.stringify(transactionResult), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 200
      });
    } catch (e) {
      console.error('[voting-v2] tx_error', { ip, user_id, vote_id: voteIdNum, vote_item_id: voteItemIdNum, amount: amountNum, error: String(e?.message || e) });
      throw e;
    } finally{
      try {
        connection.release();
      } catch (_) {
      // ignore release errors
      }
    }
    } finally {
      if (__mutexAcquired) {
        releaseUserMutex(user_id);
      }
    }
  } catch (error) {
    console.error('[voting-v2] unexpected', { error: String(error?.message || error) });
    // removed function_request_log
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
