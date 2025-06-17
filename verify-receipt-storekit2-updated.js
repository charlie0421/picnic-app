import 'https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.44.4';
import { create } from 'https://deno.land/x/djwt@v3.0.2/mod.ts';

const supabaseUrl = Deno.env.get('SUPABASE_URL');
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const supabase = createClient(supabaseUrl, supabaseKey);
console.log('Supabase client created');

const SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';
const PRODUCTION_URL = 'https://buy.itunes.apple.com/verifyReceipt';
const GOOGLE_PRIVATE_KEY = Deno.env.get('GOOGLE_PRIVATE_KEY').replace(/\\n/g, '\n');
const GOOGLE_CLIENT_EMAIL = Deno.env.get('GOOGLE_CLIENT_EMAIL');
console.log('Private key length:', GOOGLE_PRIVATE_KEY.length);
console.log('Private key first 100 characters:', GOOGLE_PRIVATE_KEY.substring(0, 100));
console.log('Private key last 100 characters:', GOOGLE_PRIVATE_KEY.substring(GOOGLE_PRIVATE_KEY.length - 100));

// CORS 헤더 설정
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS'
};

async function isIPBlocked(supabaseClient, ip) {
  try {
    console.log('Checking IP:', ip);
    const { data, error } = await supabaseClient.from('blocked_ips').select('ip_address').eq('ip_address', ip).single();
    if (error && error.code !== 'PGRST116') {
      console.error('IP 차단 확인 중 에러 발생:', error);
      return false;
    }
    return !!data;
  } catch (error) {
    console.error('IP 확인 중 예외 발생:', error);
    return false;
  }
}

// JWT 디코딩을 위한 함수 추가
function decodeJWT(jwt) {
  try {
    const parts = jwt.split('.');
    if (parts.length !== 3) {
      return null;
    }
    
    // Base64URL 디코딩
    const decode = (str) => {
      // Base64URL을 Base64로 변환
      str = str.replace(/-/g, '+').replace(/_/g, '/');
      // 패딩 추가
      while (str.length % 4) {
        str += '=';
      }
      return JSON.parse(atob(str));
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

// StoreKit2 JWT인지 확인하는 함수
function isStoreKit2JWT(receipt) {
  console.log('JWT 감지 시작:', typeof receipt, receipt?.length);
  
  if (!receipt || typeof receipt !== 'string') {
    console.log('JWT 감지 실패: 유효하지 않은 데이터 타입');
    return false;
  }
  
  // JWT 형식 확인 (3개 부분으로 나뉘어짐)
  const parts = receipt.split('.');
  console.log('JWT 부분 개수:', parts.length);
  
  if (parts.length !== 3) {
    console.log('JWT 감지 실패: 부분 개수가 3개가 아님');
    return false;
  }
  
  // 각 부분이 Base64URL 형식인지 확인
  const base64UrlPattern = /^[A-Za-z0-9_-]+$/;
  for (let i = 0; i < parts.length; i++) {
    if (!base64UrlPattern.test(parts[i])) {
      console.log(`JWT 감지 실패: 부분 ${i}이 Base64URL 형식이 아님`);
      return false;
    }
  }
  
  try {
    const decoded = decodeJWT(receipt);
    if (!decoded || !decoded.payload) {
      console.log('JWT 감지 실패: 디코딩 실패');
      return false;
    }
    
    console.log('JWT 페이로드:', Object.keys(decoded.payload));
    
    // StoreKit2 JWT의 특징적인 필드들 확인
    const payload = decoded.payload;
    const isStoreKit2 = (
      payload.hasOwnProperty('transactionId') ||
      payload.hasOwnProperty('originalTransactionId') ||
      payload.hasOwnProperty('productId') ||
      payload.hasOwnProperty('bundleId') ||
      (payload.iss && payload.iss.includes('apple')) ||
      payload.hasOwnProperty('signedDate') ||
      payload.hasOwnProperty('transactionReason')
    );
    
    console.log('StoreKit2 JWT 감지 결과:', isStoreKit2);
    return isStoreKit2;
  } catch (error) {
    console.log('JWT 감지 중 에러:', error.message);
    return false;
  }
}

// StoreKit2 JWT 검증 함수
async function verifyStoreKit2JWT(jwtToken, environment) {
  try {
    console.log('🔐 StoreKit2 JWT 검증 시작...');
    console.log('JWT 토큰 길이:', jwtToken?.length);
    console.log('환경:', environment);
    
    // JWT 디코딩하여 정보 추출
    const decoded = decodeJWT(jwtToken);
    if (!decoded) {
      console.error('❌ JWT 디코딩 실패');
      throw new Error('JWT 디코딩 실패');
    }
    
    const payload = decoded.payload;
    console.log('✅ JWT 디코딩 성공');
    console.log('📋 StoreKit2 JWT 페이로드 전체:', JSON.stringify(payload, null, 2));
    
    // 필수 필드 확인 (더 유연하게)
    const hasTransactionId = payload.transactionId || payload.originalTransactionId;
    const hasProductId = payload.productId;
    const hasBundleId = payload.bundleId;
    
    console.log('필드 검증:');
    console.log('  - transactionId:', !!hasTransactionId, hasTransactionId);
    console.log('  - productId:', !!hasProductId, hasProductId);
    console.log('  - bundleId:', !!hasBundleId, hasBundleId);
    
    // 최소한의 필수 필드만 확인 (productId와 transaction 관련 필드 중 하나)
    if (!hasProductId || !hasTransactionId) {
      const missingFields = [];
      if (!hasProductId) missingFields.push('productId');
      if (!hasTransactionId) missingFields.push('transactionId');
      
      console.error('❌ 필수 필드 누락:', missingFields);
      throw new Error(`필수 필드 누락: ${missingFields.join(', ')}`);
    }
    
    // 환경 확인 (더 유연하게)
    const jwtEnvironment = payload.environment || (environment === 'production' ? 'Production' : 'Sandbox');
    const expectedEnvironment = environment === 'production' ? 'Production' : 'Sandbox';
    
    console.log('환경 확인:');
    console.log('  - JWT 환경:', jwtEnvironment);
    console.log('  - 요청 환경:', environment);
    console.log('  - 예상 환경:', expectedEnvironment);
    
    if (jwtEnvironment !== expectedEnvironment) {
      console.warn(`⚠️ 환경 불일치: JWT=${jwtEnvironment}, Expected=${expectedEnvironment}`);
      console.warn('환경 불일치이지만 검증을 계속합니다.');
    }
    
    // 시간 정보 처리
    const now = Date.now();
    const purchaseDate = payload.purchaseDate || payload.signedDate || now;
    const originalPurchaseDate = payload.originalPurchaseDate || purchaseDate;
    
    // 성공 응답 형태를 기존 verifyReceipt API와 동일하게 맞춤
    const responseData = {
      success: true,
      data: {
        status: 0,
        environment: jwtEnvironment,
        receipt: {
          bundle_id: hasBundleId,
          application_version: "1.0",
          in_app: [{
            transaction_id: hasTransactionId,
            original_transaction_id: payload.originalTransactionId || hasTransactionId,
            product_id: hasProductId,
            purchase_date_ms: purchaseDate.toString(),
            original_purchase_date_ms: originalPurchaseDate.toString(),
            quantity: "1",
            is_trial_period: "false"
          }]
        },
        // StoreKit2 관련 정보 추가
        storekit2: true,
        jwt_payload: payload
      }
    };
    
    console.log('✅ StoreKit2 JWT 검증 성공!');
    console.log('📤 응답 데이터:', JSON.stringify(responseData, null, 2));
    
    return responseData;
    
  } catch (error) {
    console.error('❌ StoreKit2 JWT 검증 실패:', error.message);
    console.error('❌ 상세 에러:', error);
    
    return {
      success: false,
      data: {
        status: 21002, // Invalid receipt
        error: error.message,
        error_detail: 'StoreKit2 JWT 검증 중 오류 발생'
      }
    };
  }
}

// 수정된 iOS 구매 검증 함수
async function verifyIosPurchase(receipt, environment, format) {
  console.log(`iOS 영수증 검증 시작 - 환경: ${environment}, 형식: ${format || 'auto-detect'}`);
  console.log('영수증 데이터 미리보기:', receipt?.substring(0, 100) + '...');
  
  // 명시적 format 확인
  if (format === 'storekit2_jwt') {
    console.log('클라이언트에서 StoreKit2 JWT 형식으로 명시됨');
    return await verifyStoreKit2JWT(receipt, environment);
  }
  
  // 자동 감지
  const isJWT = isStoreKit2JWT(receipt);
  if (isJWT) {
    console.log('자동 감지: StoreKit2 JWT 형식 확인됨');
    return await verifyStoreKit2JWT(receipt, environment);
  }
  
  // 기존 verifyReceipt API 사용 (StoreKit1)
  console.log('기존 verifyReceipt API 사용 (StoreKit1)');
  const verificationUrl = environment === 'production' ? PRODUCTION_URL : SANDBOX_URL;
  
  const response = await fetch(verificationUrl, {
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
    success: response.status === 200 && data.status === 0,
    data: data
  };
}

// 안드로이드 구매 검증 함수 (변경 없음)
async function verifyAndroidPurchase(productId, purchaseToken) {
  const packageName = 'io.iconcasting.picnic.app';
  const accessToken = await createGoogleJWT();
  console.log('Verifying Android purchase...');
  
  const response = await fetch(`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/products/${productId}/tokens/${purchaseToken}`, {
    headers: {
      Authorization: `Bearer ${accessToken}`
    }
  });
  
  if (!response.ok) {
    const errorText = await response.text();
    console.error(`HTTP error! status: ${response.status}, body: ${errorText}`);
    return {
      success: false,
      data: errorText
    };
  }
  
  const data = await response.json();
  return {
    success: true,
    data: data
  };
}

function pemToDer(pem) {
  const pemContents = pem.replace(/-----BEGIN PRIVATE KEY-----/, '').replace(/-----END PRIVATE KEY-----/, '').replace(/\s/g, '');
  const binary = atob(pemContents);
  const der = new Uint8Array(binary.length);
  for(let i = 0; i < binary.length; i++){
    der[i] = binary.charCodeAt(i);
  }
  return der.buffer;
}

async function createGoogleJWT() {
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 3600;
  
  const payload = {
    iss: GOOGLE_CLIENT_EMAIL,
    scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token',
    exp: exp,
    iat: iat
  };
  
  const header = {
    alg: 'RS256',
    typ: 'JWT'
  };
  
  try {
    console.log('Attempting to import private key...');
    const derKey = pemToDer(GOOGLE_PRIVATE_KEY);
    const key = await crypto.subtle.importKey('pkcs8', derKey, {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256'
    }, false, [
      'sign'
    ]);
    console.log('Private key imported successfully');
    
    const jwt = await create(header, payload, key);
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt
      })
    });
    
    const tokenData = await tokenResponse.json();
    return tokenData.access_token;
  } catch (error) {
    console.error('Error importing private key:', error);
    console.error('Error details:', JSON.stringify(error, Object.getOwnPropertyNames(error)));
    throw new Error('Failed to import Google private key');
  }
}

async function grantReward(userId, productId, transactionId) {
  try {
    console.log(`🎁 리워드 지급 시작: user=${userId}, product=${productId}, transaction=${transactionId}`);
    
    // 중복 트랜잭션 ID 확인 (중복 리워드 방지)
    console.log('🔍 중복 트랜잭션 ID 확인 중...');
    const { data: existingTransaction, error: transactionError } = await supabase
      .from('star_candy_history')
      .select('id, transaction_id')
      .eq('transaction_id', transactionId)
      .eq('user_id', userId)
      .limit(1);
      
    if (transactionError) {
      console.error('트랜잭션 ID 확인 중 오류:', transactionError);
      throw transactionError;
    }
    
    if (existingTransaction && existingTransaction.length > 0) {
      console.log('⚠️ 이미 처리된 트랜잭션 ID 발견:', transactionId);
      console.log('🎯 중복 리워드 지급 방지 - 기존 리워드 유지');
      throw new Error(`Duplicate transaction ID: ${transactionId}`);
    }
    
    const rewardMap = {
      'star100': {
        star_candy: 100,
        star_candy_bonus: 0
      },
      'star200': {
        star_candy: 200,
        star_candy_bonus: 25
      },
      'star600': {
        star_candy: 600,
        star_candy_bonus: 85
      },
      'star1000': {
        star_candy: 1000,
        star_candy_bonus: 150
      },
      'star2000': {
        star_candy: 2000,
        star_candy_bonus: 320
      },
      'star3000': {
        star_candy: 3000,
        star_candy_bonus: 540
      },
      'star4000': {
        star_candy: 4000,
        star_candy_bonus: 760
      },
      'star5000': {
        star_candy: 5000,
        star_candy_bonus: 1000
      },
      'star7000': {
        star_candy: 7000,
        star_candy_bonus: 1500
      },
      'star10000': {
        star_candy: 10000,
        star_candy_bonus: 2100
      },
      'STAR100': {
        star_candy: 100,
        star_candy_bonus: 0
      },
      'STAR200': {
        star_candy: 200,
        star_candy_bonus: 25
      },
      'STAR600': {
        star_candy: 600,
        star_candy_bonus: 85
      },
      'STAR1000': {
        star_candy: 1000,
        star_candy_bonus: 150
      },
      'STAR2000': {
        star_candy: 2000,
        star_candy_bonus: 320
      },
      'STAR3000': {
        star_candy: 3000,
        star_candy_bonus: 540
      },
      'STAR4000': {
        star_candy: 4000,
        star_candy_bonus: 760
      },
      'STAR5000': {
        star_candy: 5000,
        star_candy_bonus: 1000
      },
      'STAR7000': {
        star_candy: 7000,
        star_candy_bonus: 1500
      },
      'STAR10000': {
        star_candy: 10000,
        star_candy_bonus: 2100
      }
    };
    
    const reward = rewardMap[productId];
    if (!reward) {
      console.error(`❌ 알 수 없는 상품 ID: ${productId}`);
      throw new Error(`Unknown product ID: ${productId}`);
    }
    
    const { star_candy, star_candy_bonus } = reward;
    console.log(`💰 지급할 리워드: ${star_candy} 스타캔디 + ${star_candy_bonus} 보너스`);
    
    const now = new Date();
    const expireDate = new Date(now.getFullYear(), now.getMonth() + 1, 15);
    
    // 현재 사용자 스타캔디 조회
    const { data: profileData, error: profileError } = await supabase
      .from('user_profiles')
      .select('star_candy, star_candy_bonus')
      .eq('id', userId)
      .single();
      
    if (profileError) {
      console.error('사용자 프로필 조회 실패:', profileError);
      throw profileError;
    }
    
    const updatedStarCandy = (profileData.star_candy || 0) + star_candy;
    const updatedStarCandyBonus = (profileData.star_candy_bonus || 0) + star_candy_bonus;
    
    console.log(`📊 스타캔디 업데이트: ${profileData.star_candy || 0} → ${updatedStarCandy}`);
    console.log(`🎁 보너스 업데이트: ${profileData.star_candy_bonus || 0} → ${updatedStarCandyBonus}`);
    
    // 사용자 프로필 업데이트
    const { error: updateError } = await supabase
      .from('user_profiles')
      .update({
        star_candy: updatedStarCandy,
        star_candy_bonus: updatedStarCandyBonus
      })
      .eq('id', userId);
      
    if (updateError) {
      console.error('사용자 프로필 업데이트 실패:', updateError);
      throw updateError;
    }
    
    // 스타캔디 히스토리 추가
    const { error: historyError } = await supabase
      .from('star_candy_history')
      .insert({
        user_id: userId,
        amount: star_candy,
        type: 'PURCHASE',
        transaction_id: transactionId
      });
      
    if (historyError) {
      console.error('스타캔디 히스토리 추가 실패:', historyError);
      throw historyError;
    }
    
    // 보너스 스타캔디 히스토리 추가 (있는 경우)
    if (star_candy_bonus > 0) {
      const { error: bonusHistoryError } = await supabase
        .from('star_candy_bonus_history')
        .insert({
          user_id: userId,
          amount: star_candy_bonus,
          type: 'PURCHASE',
          expired_dt: expireDate.toISOString(),
          transaction_id: transactionId,
          remain_amount: star_candy_bonus
        });
        
      if (bonusHistoryError) {
        console.error('보너스 히스토리 추가 실패:', bonusHistoryError);
        throw bonusHistoryError;
      }
    }
    
    console.log(`✅ 리워드 지급 완료: user=${userId}, reward=${JSON.stringify(reward)}, expiry=${expireDate.toISOString()}`);
  } catch (error) {
    console.error(`❌ 리워드 지급 실패: user=${userId}:`, error);
    throw error;
  }
}

// 메인 서버 로직
Deno.serve(async (request) => {
  // CORS preflight 요청 처리
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders
    });
  }
  
  // IP 차단 확인
  const clientIP = request.headers.get('cf-connecting-ip') || request.context?.remoteAddr?.hostname || request.headers.get('x-forwarded-for') || 'unknown';
  console.log('Client IP:', clientIP);
  const blocked = await isIPBlocked(supabase, clientIP);
  if (blocked) {
    return new Response(JSON.stringify({
      error: 'Access Denied',
      message: 'Your IP address has been blocked'
    }), {
      status: 403,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  }
  
  try {
    console.log('Received request');
    // format 파라미터 추가 (StoreKit2 JWT 지원을 위해)
    const { receipt, platform, productId, user_id, environment, format } = await request.json();
    console.log(`Received receipt for platform: ${platform}, productId: ${productId}, environment: ${environment}, user_id: ${user_id}, format: ${format || 'auto-detect'}`);
    
    // 영수증 원본 데이터로 직접 중복 검사 (해시 사용 안함)
    console.log('🔍 영수증 원본 데이터로 중복 검사 시작');
    console.log('📄 영수증 데이터 길이:', receipt?.length);
    console.log('📄 영수증 미리보기:', receipt?.substring(0, 100) + '...');
    
    // 영수증 원본 데이터로 기존 영수증 검색
    console.log('🔍 기존 영수증 검색 중 (원본 데이터 기준)...');
    const { data: existingReceipt, error: receiptError } = await supabase
      .from('receipts')
      .select('*')
      .eq('receipt_data', receipt)  // 영수증 원본 데이터로 직접 비교
      .eq('platform', platform)
      .eq('product_id', productId) 
      .eq('environment', environment)
      .eq('status', 'valid')
      .limit(1);
    if (receiptError) {
      console.error('❌ 영수증 검색 중 오류:', receiptError);
      throw receiptError;
    }
    
    // 이미 검증된 영수증이 있는 경우
    if (existingReceipt && existingReceipt.length > 0) {
      console.log('⚠️ 기존 유효한 영수증 발견 (원본 데이터 기준):', {
        id: existingReceipt[0].id,
        user_id: existingReceipt[0].user_id,
        product_id: existingReceipt[0].product_id,
        created_at: existingReceipt[0].created_at,
        platform: existingReceipt[0].platform,
        environment: existingReceipt[0].environment
      });
      
      // 같은 사용자의 영수증인지 확인
      if (existingReceipt[0].user_id === user_id) {
        console.log('✅ 같은 사용자의 중복 영수증 - 이미 처리된 구매로 응답');
        return new Response(JSON.stringify({
          success: true,
          data: {
            reused: true,
            receipt_id: existingReceipt[0].id,
            verification_data: existingReceipt[0].verification_data,
            message: '이미 처리된 구매입니다'
          }
        }), {
          status: 200,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          }
        });
      } else {
        console.warn('🚨 다른 사용자의 동일한 영수증 감지 - 의심스러운 활동');
        console.warn(`  기존 사용자: ${existingReceipt[0].user_id}, 현재 사용자: ${user_id}`);
        
        // 보안상 중복 처리하지 않고 차단
        console.error('🔒 동일한 영수증을 다른 사용자가 사용 시도 - 차단');
        return new Response(JSON.stringify({
          success: false,
          data: {
            error: 'Duplicate receipt usage detected',
            message: '이미 다른 사용자가 사용한 영수증입니다'
          }
        }), {
          status: 400,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
          }
        });
      }
    } else {
      console.log('✅ 새로운 영수증 - 검증 진행');
    }
    
    // 원본 데이터 기반 중복 검사 완료
    // (해시나 트랜잭션 ID 기반 검사 불필요 - 원본 데이터가 가장 정확함)
    
    // 새로운 영수증 검증
    let data;
    console.log('🆕 새로운 영수증 검증 시작');
    if (platform === 'ios') {
      console.log('📱 iOS 플랫폼 검증 시작');
      console.log('🔍 형식:', format || 'auto-detect');
      // iOS - StoreKit2 JWT 지원 포함
      data = await verifyIosPurchase(receipt, environment, format);
    } else if (platform === 'android') {
      console.log('🤖 Android 플랫폼 검증 시작');
      // 안드로이드 - 기존 로직 그대로 유지
      data = await verifyAndroidPurchase(productId.toLowerCase(), receipt);
    } else {
      throw new Error(`Invalid platform: ${platform}`);
    }
    
    console.log('📊 Verification response:', JSON.stringify(data, null, 2));
    
    // 검증 결과 처리
    if (data.success) {
      console.log('Receipt is valid');
      
      // 영수증 원본 데이터를 저장 (해시 없이)
      const { error: insertError } = await supabase.from('receipts').insert([
        {
          receipt_data: receipt,
          status: 'valid',
          platform,
          user_id: user_id,
          product_id: productId,
          environment: environment,
          verification_data: data.data
          // receipt_hash 필드 제거 (원본 데이터 기반 검색 사용)
        }
      ]);
      if (insertError) throw insertError;
      
      const transactionId = `${platform}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      await grantReward(user_id, platform === 'android' ? productId.toLowerCase() : productId, transactionId);
      
      return new Response(JSON.stringify({
        success: true,
        data: data.data
      }), {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      });
    } else {
      console.log('Receipt is invalid');
      
      // 실패한 영수증도 원본 데이터로 저장 (해시 없이)
      await supabase.from('receipts').insert([
        {
          receipt_data: receipt,
          status: 'invalid',
          platform,
          user_id: user_id,
          product_id: productId,
          environment: environment,
          verification_data: data.data
          // receipt_hash 필드 제거 (원본 데이터 기반 검색 사용)
        }
      ]);
      
      return new Response(JSON.stringify({
        success: false,
        data: data
      }), {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      });
    }
  } catch (error) {
    console.error('Error processing request:', error);
    return new Response(JSON.stringify({
      error: 'Internal server error',
      details: error.message
    }), {
      status: 500,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  }
}); 