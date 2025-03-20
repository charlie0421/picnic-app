import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { crypto } from 'https://deno.land/std@0.208.0/crypto/mod.ts';
import * as postgres from 'https://deno.land/x/postgres@v0.17.0/mod.ts';

const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

const databaseUrl = Deno.env.get('SUPABASE_DB_URL');
const pool = new postgres.Pool(databaseUrl, 3, true);

function getSupabaseClient() {
  return createClient(supabaseUrl, supabaseServiceKey);
}

async function queryDatabase(query, ...args) {
  const client = await pool.connect();
  console.log('queryDatabase', {
    query,
    args,
  });
  try {
    const result = await client.queryObject(query, args);
    console.log('Query executed:', {
      query,
      args,
      result,
    });
    return result;
  } catch (error) {
    console.error('Error executing query:', {
      query,
      args,
      error,
    });
    throw error;
  } finally {
    client.release();
  }
}

async function updateUserRewards(user_id: string, reward_amount: number) {
  console.log('Updating user rewards');
  const updateUserQuery = `
    UPDATE user_profiles
    SET star_candy_bonus = star_candy_bonus + $1,
        updated_at = NOW()
    WHERE id = $2
    RETURNING star_candy_bonus as new_balance
  `;
  const result = await queryDatabase(updateUserQuery, reward_amount, user_id);
  if (!result.rows?.[0]) {
    throw new Error('Failed to update user rewards');
  }
  return result.rows[0];
}

async function insertStarCandyBonusHistory(
  user_id: string,
  amount: number,
  transaction_id: string,
) {
  console.log('Inserting star candy bonus history');
  const insertHistoryQuery = `
    INSERT INTO star_candy_history (
      user_id,
      amount,
      type,
      transaction_id,
      created_at
    ) VALUES (
      $1, $2, 'AD'::candy_history_type, $3, NOW()
    )
    RETURNING id
  `;
  const result = await queryDatabase(
    insertHistoryQuery,
    user_id,
    amount,
    transaction_id,
  );
  if (!result.rows?.[0]) {
    throw new Error('Failed to insert history');
  }
  return result.rows[0];
}

async function insertTransaction(
  transaction_id: string,
  reward_type: string,
  reward_amount: number,
  signature: string,
  platform: string,
  user_id: string,
) {
  console.log('Inserting transaction');
  const insertTransactionQuery = `
    INSERT INTO transaction_pangle (
      transaction_id,
      reward_type,
      reward_amount,
      signature,
      platform,
      user_id,
      created_at
    ) VALUES ($1, $2, $3, $4, $5, $6, NOW())
  `;
  await queryDatabase(
    insertTransactionQuery,
    transaction_id,
    reward_type,
    reward_amount,
    signature,
    platform,
    user_id,
  );
}

async function processTransaction(
  user_id: string,
  reward_amount: number,
  transaction_id: string,
  reward_type: string,
  signature: string,
  platform: string,
) {
  const connection = await pool.connect();
  try {
    await connection.queryObject('BEGIN');

    // 1. Update user rewards
    const userUpdate = await updateUserRewards(user_id, reward_amount);
    console.log('User rewards updated:', userUpdate);

    // 2. Insert history
    const history = await insertStarCandyBonusHistory(
      user_id,
      reward_amount,
      transaction_id,
    );
    console.log('History inserted:', history);

    // 3. Insert transaction
    await insertTransaction(
      transaction_id,
      reward_type,
      reward_amount,
      signature,
      platform,
      user_id,
    );
    console.log('Transaction inserted');

    await connection.queryObject('COMMIT');
    console.log('Transaction committed successfully');

    return {
      previousBalance: userUpdate.new_balance - reward_amount,
      newBalance: userUpdate.new_balance,
      addedAmount: reward_amount,
      historyId: history.id,
    };
  } catch (e) {
    await connection.queryObject('ROLLBACK');
    console.error('Transaction failed:', e);
    throw e;
  } finally {
    connection.release();
  }
}

function extractParameters(url) {
  const params = url.searchParams;
  // Pangle 파라미터 추출
  const trans_id = params.get('trans_id');
  const reward_name = params.get('reward_name');
  const reward_amount = parseInt(params.get('reward_amount') ?? '0', 10);
  const extra = params.get('extra');
  const sign = params.get('sign');

  // URL에서 직접 user_id 추출
  let user_id = params.get('user_id') || '';
  let reward_type = 'free_charge_station'; // 기본값
  let platform = '';
  // user_id가 'defaultUser'이면 extra 값을 사용
  if (user_id === 'defaultUser' && extra) {
    const extraArray = extra.split(',');
    user_id = extraArray[0];
    platform = extraArray[1];
  }

  // extra가 JSON인 경우 reward_type 추출 시도
  if (extra) {
    try {
      const parsedData = JSON.parse(extra);
      if (user_id === '') {
        user_id = parsedData.user_id || '';
      }
      reward_type = parsedData.reward_type || reward_type;
    } catch (error) {
      console.log(`JSON 파싱 실패, extra: ${extra}. 기본값 사용`);
    }
  }

  return {
    user_id,
    reward_amount,
    reward_type,
    reward_name,
    transaction_id: trans_id,
    signature: sign,
    platform,
  };
}

function validateParameters(params) {
  console.log('Validating parameters:', params);
  const {
    user_id,
    reward_amount,
    reward_type,
    transaction_id,
    signature,
    reward_name,
  } = params;

  if (!user_id) {
    console.log('Missing user_id');
    return false;
  }
  if (reward_amount === undefined || reward_amount === null) {
    console.log('Missing reward_amount');
    return false;
  }
  if (!reward_type) {
    console.log('Missing reward_type');
    return false;
  }
  if (!transaction_id) {
    console.log('Missing transaction_id');
    return false;
  }
  if (!signature) {
    console.log('Missing signature');
    return false;
  }
  if (!reward_name) {
    console.log('Missing reward_name');
    return false;
  }

  return true;
}

async function verifyPangleSignature(
  transactionId: string,
  secretKey: string,
  signature: string,
): Promise<boolean> {
  const message = `${secretKey}:${transactionId}`;
  console.log('Verifying signature:');
  console.log('- Transaction ID:', transactionId);
  console.log('- Secret Key:', secretKey);
  console.log('- Message:', message);
  console.log('- Expected signature:', signature);

  const msgUint8 = new TextEncoder().encode(message);
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const calculatedSignature = hashArray
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');

  console.log('- Calculated signature:', calculatedSignature);
  console.log('- Signatures match:', calculatedSignature === signature);

  return calculatedSignature === signature;
}

async function handleRequest(req: Request) {
  try {
    const url = new URL(req.url);
    const params = extractParameters(url);
    console.log('Received request', params);

    if (!validateParameters(params)) {
      console.error('Invalid request parameters', params);
      return new Response(JSON.stringify({ isValid: false }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    const secretKey =
      params.platform === 'android'
        ? Deno.env.get('PANGLE_ANDROID_APP_SECURITY_KEY')
        : Deno.env.get('PANGLE_IOS_APP_SECURITY_KEY');

    const isValid = await verifyPangleSignature(
      params.transaction_id,
      secretKey,
      params.signature,
    );

    if (!isValid) {
      console.error('Invalid signature', params);
      return new Response(JSON.stringify({ isValid: false }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    await processTransaction(
      params.user_id,
      params.reward_amount,
      params.transaction_id,
      params.reward_type,
      params.signature,
      params.platform,
    );

    return new Response(JSON.stringify({ isValid: true }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    console.error('Error processing request:', error);
    return new Response(JSON.stringify({ isValid: false }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
}

serve(handleRequest);
