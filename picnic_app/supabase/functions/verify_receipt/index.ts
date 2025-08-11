// /supabase/functions/verify-purchase/index.ts
import "https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.44.4';
import { create } from 'https://deno.land/x/djwt@v3.0.2/mod.ts';
const supabaseUrl = Deno.env.get('SUPABASE_URL');
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const supabase = createClient(supabaseUrl, supabaseKey);
const SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';
const PRODUCTION_URL = 'https://buy.itunes.apple.com/verifyReceipt';
const GOOGLE_PRIVATE_KEY = (Deno.env.get('GOOGLE_PRIVATE_KEY') ?? '').replace(/\\n/g, '\n');
const GOOGLE_CLIENT_EMAIL = Deno.env.get('GOOGLE_CLIENT_EMAIL') ?? '';
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS'
};
/** Util: hex encoder for ArrayBuffer */
function toHex(buffer) {
  const bytes = new Uint8Array(buffer);
  const hex: string[] = [];
  for (let i = 0; i < bytes.length; i++) {
    const h = bytes[i].toString(16).padStart(2, '0');
    hex.push(h);
  }
  return hex.join('');
}
/** Util: sha256 as hex */
async function sha256Hex(message) {
  const data = new TextEncoder().encode(message);
  const digest = await crypto.subtle.digest('SHA-256', data);
  return toHex(digest);
}
/* -------------------- JWT utils (원복 수준) -------------------- */ function decodeJWT(jwt) {
  try {
    const parts = jwt.split('.');
    if (parts.length !== 3) return null;
    const decode = (s)=>{
      s = s.replace(/-/g, '+').replace(/_/g, '/');
      while(s.length % 4)s += '=';
      return JSON.parse(atob(s));
    };
    return {
      header: decode(parts[0]),
      payload: decode(parts[1]),
      signature: parts[2]
    };
  } catch (error) {
    console.error('JWT 디코딩 실패:', error);
    return null;
  }
}
function isStoreKit2JWT(receipt) {
  if (!receipt || typeof receipt !== 'string') return false;
  const parts = receipt.split('.');
  if (parts.length !== 3) return false;
  const pat = /^[A-Za-z0-9_-]+$/;
  if (!pat.test(parts[0]) || !pat.test(parts[1]) || !pat.test(parts[2])) return false;
  const p = decodeJWT(receipt)?.payload;
  return !!(p?.transactionId || p?.originalTransactionId || p?.productId || p?.bundleId || p?.signedDate);
}
/**
 * 결정적 transaction_id 생성
 * - iOS(StoreKit2 JWT): payload.transactionId/originalTransactionId 사용
 * - iOS(StoreKit1): verify.data.receipt.in_app[0].transaction_id 사용
 * - Android: receipt(=purchaseToken) 사용
 * - 위 모두 실패 시 receipt/user_id/product/environment 기반 sha256 해시 사용
 */
async function deriveTransactionId({
  receipt,
  platform,
  userId,
  productId,
  environment,
  verify,
  format
}) {
  try {
    const plat = String(platform || '').toLowerCase();
    // Android: receipt 가 purchaseToken 이므로 그대로 사용
    if (plat === 'android' && typeof receipt === 'string' && receipt.length > 0) {
      return receipt;
    }

    // iOS - StoreKit2 JWT 우선
    if (isStoreKit2JWT(receipt)) {
      const p = decodeJWT(receipt)?.payload || {};
      const time = p.signedDate || p.purchaseDate || p.originalPurchaseDate || '';
      if (p?.transactionId) {
        // iOS(StoreKit2): 멱등키 = transactionId + 시간(서버만으로 재구매 구분)
        if (time) return `sk2_${p.transactionId}_${time}`;
        const base = `sk2_tx:${p.transactionId}|${plat}|${userId}|${productId}|${environment}`;
        const hex = await sha256Hex(base);
        return `sk2_${p.transactionId}_${hex.slice(0, 16)}`;
      }
      if (p?.originalTransactionId) {
        // originalTransactionId → 시간 결합
        if (time) return `sk2_${p.originalTransactionId}_${time}`;
        const base = `sk2_orig:${p.originalTransactionId}|${plat}|${userId}|${productId}|${environment}`;
        const hex = await sha256Hex(base);
        return `sk2_${p.originalTransactionId}_${hex.slice(0, 16)}`;
      }
    }

    // iOS - StoreKit1 응답에서 in_app[0].transaction_id 사용
    const inAppTx = verify?.data?.receipt?.in_app?.[0]?.transaction_id;
    if (inAppTx) return String(inAppTx);

    // 마지막 수단: 결정적 해시
    const base = [plat, userId || '', productId || '', environment || '',
      typeof receipt === 'string' ? receipt.slice(0, 256) : String(receipt || '')
    ].join('|');
    const hex = await sha256Hex(base);
    return `tx_${hex.slice(0, 40)}`; // 40자 트렁케이트
  } catch (_) {
    // 최후 보루: 매우 낮은 확률이지만 해시 생성 오류 시 시간+랜덤 혼합 (여전히 비교적 결정적 아님)
    return `tx_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 10)}`;
  }
}
/* -------------------- StoreKit2 JWT 검증 -------------------- */ async function verifyStoreKit2JWT(jwtToken, environment) {
  try {
    const p = decodeJWT(jwtToken)?.payload;
    if (!p) throw new Error('JWT 디코딩 실패');
    const hasTx = p.transactionId || p.originalTransactionId;
    if (!p.productId || !hasTx) throw new Error('필수 필드 누락: productId/transactionId');
    const jwtEnvironment = p.environment || (environment === 'production' ? 'Production' : 'Sandbox');
    const purchaseDate = p.purchaseDate ?? p.signedDate ?? Date.now();
    const originalPurchaseDate = p.originalPurchaseDate ?? purchaseDate;
    return {
      success: true,
      data: {
        status: 0,
        environment: jwtEnvironment,
        receipt: {
          bundle_id: p.bundleId ?? '',
          application_version: "1.0",
          in_app: [
            {
              transaction_id: p.transactionId ?? p.originalTransactionId,
              original_transaction_id: p.originalTransactionId ?? p.transactionId,
              product_id: p.productId,
              purchase_date_ms: String(purchaseDate),
              original_purchase_date_ms: String(originalPurchaseDate),
            quantity: "1",
            is_trial_period: "false"
            }
          ]
        },
        storekit2: true,
        jwt_payload: p
      }
    };
  } catch (error) {
    return {
      success: false,
      data: {
        status: 21002,
        error: error?.message ?? 'JWT 검증 실패'
      }
    };
  }
}
/* -------------------- iOS/Android 검증 -------------------- */ async function verifyIosPurchase(receipt, environment, format) {
  if (format === 'storekit2_jwt' || isStoreKit2JWT(receipt)) {
    return await verifyStoreKit2JWT(receipt, environment);
  }
  const url = environment === 'production' ? PRODUCTION_URL : SANDBOX_URL;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      'receipt-data': receipt,
      'password': '52468d297ebc4777a3daefb2d12aabce'
    })
  });
  const data = await response.json();
  return {
    success: response.ok && data?.status === 0,
    data
  };
}
function pemToDer(pem) {
  const pemContents = pem.replace(/-----BEGIN PRIVATE KEY-----/, '').replace(/-----END PRIVATE KEY-----/, '').replace(/\s/g, '');
  const binary = atob(pemContents);
  const der = new Uint8Array(binary.length);
  for(let i = 0; i < binary.length; i++)der[i] = binary.charCodeAt(i);
  return der.buffer;
}
async function createGoogleJWT() {
  const iat = Math.floor(Date.now() / 1000), exp = iat + 3600;
  const header = {
    alg: 'RS256',
    typ: 'JWT'
  };
  const payload = {
    iss: GOOGLE_CLIENT_EMAIL,
    scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token',
    iat,
    exp
  };
  const key = await crypto.subtle.importKey('pkcs8', pemToDer(GOOGLE_PRIVATE_KEY), {
    name: 'RSASSA-PKCS1-v1_5',
    hash: 'SHA-256'
  }, false, [
    'sign'
  ]);
  const jwt = await create(header, payload, key);
  const tr = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt
    })
  });
  const td = await tr.json();
  if (!tr.ok) throw new Error(`Google OAuth error: ${JSON.stringify(td)}`);
  return td.access_token;
}
async function verifyAndroidPurchase(productId, purchaseToken) {
  const packageName = 'io.iconcasting.picnic.app';
  const accessToken = await createGoogleJWT();
  const response = await fetch(`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/products/${productId}/tokens/${purchaseToken}`, {
    headers: {
      Authorization: `Bearer ${accessToken}`
    }
  });
  if (!response.ok) {
    const errorText = await response.text();
    return {
      success: false,
      data: {
        status: response.status,
        body: errorText
      }
    };
  }
  const data = await response.json();
  return {
    success: true,
    data
  };
}
/* -------------------- 보상 (idempotent) -------------------- */ async function grantReward(userId, productId, transactionId) {
  // 상품 ID 정규화: 접두사 제거(com.example.PROD) 및 대문자화
  const normalizedId = String(productId || '')
    .trim()
    .split('.')
    .pop()
    ?.toUpperCase();
  const nowIso = new Date().toISOString();

  // 상품 기간 체크 (서버 시간 now 대체: ISO 비교)
  const { data: productData, error: productError } = await supabase
    .from('products')
    .select('id, star_candy, star_candy_bonus')
    .eq('id', normalizedId)
    .lte('start_at', nowIso)
    .gte('end_at', nowIso)
    .single();
  if (productError || !productData) {
    const { data: anyProductData } = await supabase
      .from('products')
      .select('id, start_at, end_at')
      .eq('id', normalizedId)
      .single();
    if (!anyProductData) throw new Error(`존재하지 않는 상품 ID: ${normalizedId}`);
    throw new Error(`판매 기간이 아닌 상품: ${normalizedId}`);
  }
  const { star_candy, star_candy_bonus } = productData;
  // 1) 사전 존재 확인 (결정적 transaction_id 사용 시 빠른 차단)
  if (transactionId) {
    const { data: existTx } = await supabase
      .from('star_candy_history')
      .select('id')
      .eq('transaction_id', transactionId)
      .maybeSingle();
    if (existTx) {
      console.log(`[grantReward] tx exists, skip credit user=${userId} product=${productId} tx=${transactionId}`);
      // 이미 기록됨 → 이후 업데이트 스킵
      return;
    }
  }
  // 2) 기본 적립 히스토리 먼저 삽입 → 동시성 시 23505로 최종 차단
  try {
    const { error: historyError } = await supabase.from('star_candy_history').insert({
      user_id: userId,
      amount: star_candy ?? 0,
      type: 'PURCHASE',
      transaction_id: transactionId
    });
    if (historyError) throw historyError;
    console.log(`[grantReward] history inserted user=${userId} product=${productId} amount=${star_candy ?? 0} tx=${transactionId}`);
  } catch (e) {
    if (e?.code === '23505') {
      console.log(`[grantReward] unique conflict(23505), skip credit user=${userId} product=${productId} tx=${transactionId}`);
      // 이미 적립된 거래 → 프로필/보너스 업데이트 스킵 (idempotent)
      return;
    }
    throw e;
  }
  // 2) 프로필 증가 (히스토리 삽입 성공시에만)
  const { data: profileData, error: profileError } = await supabase.from('user_profiles').select('star_candy, star_candy_bonus').eq('id', userId).single();
  if (profileError) throw profileError;
  const updatedStarCandy = (profileData?.star_candy ?? 0) + (star_candy ?? 0);
  const updatedStarCandyBonus = (profileData?.star_candy_bonus ?? 0) + (star_candy_bonus ?? 0);
  const { error: updateError } = await supabase.from('user_profiles').update({
    star_candy: updatedStarCandy,
    star_candy_bonus: updatedStarCandyBonus
  }).eq('id', userId);
  if (updateError) throw updateError;
  // 3) 보너스 히스토리 (있을 때만). 23505는 무시
  if ((star_candy_bonus ?? 0) > 0) {
    const now = new Date();
    const expireDate = new Date(now.getFullYear(), now.getMonth() + 1, 15).toISOString();
    const { error: bonusHistoryError } = await supabase.from('star_candy_bonus_history').insert({
      user_id: userId,
      amount: star_candy_bonus ?? 0,
      type: 'PURCHASE',
      expired_dt: expireDate,
      transaction_id: transactionId,
      remain_amount: star_candy_bonus ?? 0
    });
    if (bonusHistoryError && bonusHistoryError.code !== '23505') {
      throw bonusHistoryError;
    }
  }
}
/* -------------------- Entrypoint -------------------- */ Deno.serve(async (request)=>{
  const reqId = (crypto as any).randomUUID ? (crypto as any).randomUUID() : `${Date.now().toString(36)}_${Math.random().toString(36).slice(2,10)}`;
  try {
    // CORS preflight
  if (request.method === 'OPTIONS') {
      console.log(`[verify_receipt] reqId=${reqId} OPTIONS preflight`);
    return new Response(null, {
      status: 204,
      headers: corsHeaders
    });
  }
    console.log(`[verify_receipt] reqId=${reqId} start method=${request.method}`);
  try {
    const { receipt, platform, productId, user_id, environment, format } = await request.json();
    console.log(`[verify_receipt] reqId=${reqId} body parsed platform=${platform} productId=${productId} user=${user_id} env=${environment} receiptLen=${typeof receipt==='string'?receipt.length:0}`);
    if (!receipt || !platform || !productId || !user_id || !environment) {
      console.warn(`[verify_receipt] reqId=${reqId} missing params`);
      return new Response(JSON.stringify({
        error: 'Missing params'
      }), {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      });
    }
    // 플랫폼별 productId 처리 (원복 정책 유지)
    let processedProductId = productId;
    let dbProductId = productId;
    if (platform === 'android') {
      processedProductId = productId.toLowerCase();
      dbProductId = productId.split('.').pop()?.toUpperCase();
    } else if (platform === 'ios') {
      dbProductId = productId.split('.').pop()?.toUpperCase();
    }
    // 검증
    let verify;
    if (platform === 'ios') {
      console.log(`[verify_receipt] reqId=${reqId} verify iOS format=${format||'auto'}`);
      verify = await verifyIosPurchase(receipt, environment, format);
    } else if (platform === 'android') {
      console.log(`[verify_receipt] reqId=${reqId} verify Android`);
      verify = await verifyAndroidPurchase(processedProductId, receipt);
    } else {
      console.warn(`[verify_receipt] reqId=${reqId} invalid platform=${platform}`);
      return new Response(JSON.stringify({
        error: 'Invalid platform'
      }), {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      });
    }
    const platNorm = String(platform).trim().toLowerCase();
    const envNorm = String(environment).trim().toLowerCase();
    // 실패 → invalid 저장 후 400
    if (!verify?.success) {
      console.warn(`[verify_receipt] reqId=${reqId} verification failed status=${verify?.data?.status}`);
      await supabase.from('receipts').insert([
        {
          receipt_data: receipt,
          status: 'invalid',
          platform: platNorm,
          user_id,
          product_id: dbProductId,
          environment: envNorm,
          verification_data: verify?.data ?? null
        }
      ]);
      return new Response(JSON.stringify({
        success: false,
        data: verify
      }), {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      });
    }
    // 성공 → receipts 먼저 저장
    try {
      await supabase.from('receipts').insert([
        {
          receipt_data: receipt,
          status: 'valid',
          platform: platNorm,
          user_id,
          product_id: dbProductId,
          environment: envNorm,
          verification_data: verify.data
        }
      ]);
      console.log(`[verify_receipt] reqId=${reqId} receipt saved as valid`);
    } catch (e) {
      // 유니크 충돌 = 이미 처리된 구매
      if (e?.code === '23505') {
        console.log(`[verify_receipt] reqId=${reqId} duplicate receipt (skip)`);
        return new Response(JSON.stringify({
          success: false,
          code: 'DUPLICATE_RECEIPT',
          message: '이미 처리된 구매입니다.'
        }), {
          status: 409,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          }
        });
      }
      throw e;
    }
    // 보상 (idempotent): 결정적 transaction_id 생성 후 지급 시도
    const txId = await deriveTransactionId({
      receipt,
      platform: platNorm,
      userId: user_id,
      productId: dbProductId,
      environment: envNorm,
      verify,
      format
    });
    console.log(`[verify_receipt] reqId=${reqId} derived txId=${txId}`);
    await grantReward(user_id, processedProductId, txId);
    console.log(`[verify_receipt] reqId=${reqId} reward processed OK`);
    return new Response(JSON.stringify({
      success: true,
      data: verify.data
    }), {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  } catch (error) {
    console.error(`[verify_receipt] reqId=${reqId} error:`, error);
    return new Response(JSON.stringify({
      error: "Internal server error",
      details: error?.message ?? String(error)
    }), {
      status: 500,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  }
  } finally {
    console.log(`[verify_receipt] reqId=${reqId} end`);
  }
});
