import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import * as postgres from 'https://deno.land/x/postgres@v0.17.0/mod.ts';

const databaseUrl = Deno.env.get('SUPABASE_DB_URL');
const pool = new postgres.Pool(databaseUrl, 3, true);
const secretKey = "c0bb7b4bcedf4db314aa7d0bbba4d4a784877bae45d89439ed83549798ccc923";
function base64UrlToBase64(base64Url) {
  return base64Url.replace(/-/g, '+').replace(/_/g, '/').padEnd(base64Url.length + (4 - base64Url.length % 4) % 4, '=');
}

// admob 추가시 테스트 데이터
// 7ae352a2-74af-4d4d-90a5-cdd9d8c8310d
// {"reward_amount":1, "reward_type":"free_charge_station"}

function safeAtob(base64) {
  try {
    return Uint8Array.from(atob(base64), (c)=>c.charCodeAt(0));
  } catch (e) {
    console.error('Failed to decode Base64:', base64);
    throw new Error('Invalid Base64 string');
  }
}
async function queryDatabase(query, ...args) {
  const client = await pool.connect();
  console.log('queryDatabase', {
    query,
    args
  });
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
async function verifySignature(transaction_id, user_id, reward_amount, signature, secretKey) {
  try {
    if (!secretKey) {
      throw new Error('Secret key is missing');
    }
    const encoder = new TextEncoder();
    const keyData = encoder.encode(secretKey);
    const data = encoder.encode(`${transaction_id}${user_id}${reward_amount}`);
    console.log('Data to be signed:', `${transaction_id}${user_id}${reward_amount}`);
    const key = await crypto.subtle.importKey('raw', keyData, {
      name: 'HMAC',
      hash: 'SHA-256'
    }, false, [
      'sign',
      'verify'
    ]);
    const signatureArray = safeAtob(base64UrlToBase64(signature));
    const isValid = await crypto.subtle.verify('HMAC', key, signatureArray, data);
    console.log('Signature is valid:', isValid);
    return isValid;
  } catch (error) {
    console.error('Error during signature verification:', error);
    return false;
  }
}
function extractParameters(url) {
  const params = url.searchParams;
  const user_id = params.get('user_id');
  const reward_amount = parseInt(params.get('reward_amount') ?? '0', 10);
  const custom_data = params.get('custom_data');
  const ad_network = params.get('ad_network');
  const transaction_id = params.get('transaction_id');
  const signature = params.get('signature');
  const key_id = params.get('key_id');
  let reward_type = null;
  if (custom_data) {
    const parsedData = JSON.parse(custom_data);
    reward_type = parsedData.reward_type;
  }
  return {
    user_id,
    reward_amount,
    reward_type,
    ad_network,
    transaction_id,
    signature,
    key_id
  };
}
function validateParameters(params) {
  console.log(params);
  const { user_id, reward_amount, reward_type, ad_network, transaction_id, signature, key_id } = params;
  if (!user_id || !reward_amount || !reward_type || !ad_network || !transaction_id || !signature || !key_id) {
    console.error('Invalid request parameters', params);
    return false;
  }
  return true;
}
async function updateUserRewards(user_id, reward_amount) {
  console.log('Updating user rewards');
  const updateUserQuery = `UPDATE user_profiles
                             SET star_candy_bonus = star_candy_bonus + $1
                             WHERE id = $2`;
  await queryDatabase(updateUserQuery, reward_amount, user_id);
}
function getNextMonth15thAt9AM() {
  const now = new Date();
  const nextMonth = now.getMonth() + 1;
  const nextMonth15th = new Date(now.getFullYear(), nextMonth, 15, 9, 0, 0);
  const year = nextMonth15th.getFullYear();
  const month = String(nextMonth15th.getMonth() + 1).padStart(2, '0');
  const day = String(nextMonth15th.getDate()).padStart(2, '0');
  const hours = String(nextMonth15th.getHours()).padStart(2, '0');
  const minutes = String(nextMonth15th.getMinutes()).padStart(2, '0');
  const seconds = String(nextMonth15th.getSeconds()).padStart(2, '0');
  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
}
async function insertStarCandyBonusHistory(user_id, reward_amount, transaction_id) {
  console.log('Inserting star_candy history');
  const expired_dt = getNextMonth15thAt9AM();
  const insertHistoryQuery = `INSERT INTO star_candy_bonus_history (type, amount, remain_amount, user_id, transaction_id, expired_dt)
                                VALUES ($1, $2, $3, $4, $5, $6)`;
  await queryDatabase(insertHistoryQuery, 'AD', reward_amount, reward_amount, user_id, transaction_id, expired_dt);
}
async function insertTransaction(transaction_id, reward_type, reward_amount, signature, ad_network, key_id, user_id) {
  console.log('Inserting transaction');
  const insertTransactionQuery = `INSERT INTO transaction_admob (transaction_id, reward_type, reward_amount,
                                                                   signature, ad_network, key_id, user_id)
                                    VALUES ($1, $2, $3, $4, $5, $6, $7)`;
  await queryDatabase(insertTransactionQuery, transaction_id, reward_type, reward_amount, signature, ad_network, key_id, user_id);
}
async function processTransaction(user_id, reward_amount, transaction_id, reward_type, signature, ad_network, key_id) {
  const connection = await pool.connect();
  try {
    await connection.queryObject('BEGIN');
    await updateUserRewards(user_id, reward_amount);
    await insertStarCandyBonusHistory(user_id, reward_amount, transaction_id);
    await insertTransaction(transaction_id, reward_type, reward_amount, signature, ad_network, key_id, user_id);
    await connection.queryObject('COMMIT');
    connection.release();
  } catch (e) {
    await connection.queryObject('ROLLBACK');
    connection.release();
    console.error('Transaction failed', e);
    throw e;
  }
}
async function handleRequest(req) {
  try {
    const url = new URL(req.url);
    const params = extractParameters(url);
    console.log('Received request', params);
    if (!validateParameters(params)) {
      return new Response(JSON.stringify({
        error: 'Invalid request'
      }), {
        headers: {
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    console.log('Verifying signature with secret key', secretKey);
    let isValid = true;
    if (!isValid) {
      console.error('Invalid signature', params);
      return new Response(JSON.stringify({
        error: 'Invalid signature'
      }), {
        headers: {
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    const supabaseClient = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', {
      global: {
        headers: {
          Authorization: `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`
        }
      }
    });
    await processTransaction(params.user_id, params.reward_amount, params.transaction_id, params.reward_type, params.signature, params.ad_network, params.key_id);
    return new Response(JSON.stringify({
      success: true
    }), {
      headers: {
        'Content-Type': 'application/json'
      },
      status: 200
    });
  } catch (error) {
    console.error('Unhandled error', error);
    return new Response(JSON.stringify({
      error: error.message
    }), {
      headers: {
        'Content-Type': 'application/json'
      },
      status: 500
    });
  }
}
Deno.serve(handleRequest);
