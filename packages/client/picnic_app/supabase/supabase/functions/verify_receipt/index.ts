import "https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.44.4';
import { create } from 'https://deno.land/x/djwt@v3.0.2/mod.ts';
const supabaseUrl = Deno.env.get('SUPABASE_URL');
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const supabase = createClient(supabaseUrl, supabaseKey);
console.log("Supabase client created");
const SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';
const PRODUCTION_URL = 'https://buy.itunes.apple.com/verifyReceipt';
const GOOGLE_PRIVATE_KEY = Deno.env.get('GOOGLE_PRIVATE_KEY').replace(/\\n/g, '\n');
const GOOGLE_CLIENT_EMAIL = Deno.env.get('GOOGLE_CLIENT_EMAIL');
console.log('Private key length:', GOOGLE_PRIVATE_KEY.length);
console.log('Private key first 100 characters:', GOOGLE_PRIVATE_KEY.substring(0, 100));
console.log('Private key last 100 characters:', GOOGLE_PRIVATE_KEY.substring(GOOGLE_PRIVATE_KEY.length - 100));
Deno.serve(async (request)=>{
  try {
    console.log("Received request");
    const { receipt, platform, productId, user_id, environment } = await request.json();
    console.log(`Received receipt for platform: ${platform}, productId: ${productId}, environment: ${environment}, user_id: ${user_id}`);
    let data;
    if (platform === 'ios') {
      data = await verifyIosPurchase(receipt, environment);
    } else if (platform === 'android') {
      data = await verifyAndroidPurchase(productId.toLowerCase(), receipt);
    } else {
      throw new Error(`Invalid platform: ${platform}`);
    }
    console.log("Verification response:", data);
    if (data.success) {
      console.log("Receipt is valid");
      await supabase.from('receipts').insert([
        {
          receipt_data: receipt,
          status: 'valid',
          platform,
          user_id: user_id,
          product_id: productId,
          environment: environment
        }
      ]);
      const transactionId = `${platform}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      await grantReward(user_id, platform === 'android' ? productId.toLowerCase() : productId, transactionId);
      return new Response(JSON.stringify({
        success: true,
        data: data
      }), {
        status: 200,
        headers: {
          'Content-Type': 'application/json'
        }
      });
    } else {
      console.log("Receipt is invalid");
      await supabase.from('receipts').insert([
        {
          receipt_data: receipt,
          status: 'invalid',
          platform
        }
      ]);
      return new Response(JSON.stringify({
        success: false,
        data: data
      }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json'
        }
      });
    }
  } catch (error) {
    console.error("Error processing request:", error);
    return new Response(JSON.stringify({
      error: "Internal server error",
      details: error.message
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
});
async function verifyIosPurchase(receipt, environment) {
  const verificationUrl = environment === 'production' ? PRODUCTION_URL : SANDBOX_URL;
  console.log("Verifying iOS receipt");
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
      console.error(`Unknown product ID: ${productId}`);
      return;
    }
    const { star_candy, star_candy_bonus } = reward;
    const now = new Date();
    const expireDate = new Date(now.getFullYear(), now.getMonth() + 1, 15);
    const { data: profileData, error: profileError } = await supabase.from('user_profiles').select('star_candy, star_candy_bonus').eq('id', userId).single();
    if (profileError) throw profileError;
    const updatedStarCandy = (profileData.star_candy || 0) + star_candy;
    const updatedStarCandyBonus = (profileData.star_candy_bonus || 0) + star_candy_bonus;
    const { error: updateError } = await supabase.from('user_profiles').update({
      star_candy: updatedStarCandy,
      star_candy_bonus: updatedStarCandyBonus
    }).eq('id', userId);
    if (updateError) throw updateError;
    const { error: historyError } = await supabase.from('star_candy_history').insert({
      user_id: userId,
      amount: star_candy,
      type: 'PURCHASE',
      transaction_id: transactionId
    });
    if (historyError) throw historyError;
    if (star_candy_bonus > 0) {
      const { error: bonusHistoryError } = await supabase.from('star_candy_bonus_history').insert({
        user_id: userId,
        amount: star_candy_bonus,
        type: 'PURCHASE',
        expired_dt: expireDate.toISOString(),
        transaction_id: transactionId,
        remain_amount: star_candy_bonus
      });
      if (bonusHistoryError) throw bonusHistoryError;
    }
    console.log(`Reward granted for user ${userId}: ${JSON.stringify(reward)}, Expiry: ${expireDate.toISOString()}`);
  } catch (error) {
    console.error(`Error granting reward for user ${userId}:`, error);
    throw error;
  }
}
