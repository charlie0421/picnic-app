// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts"
import {createClient} from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);


Deno.serve(async (req) => {
    const {receipt, platform} = JSON.parse(event.body);

    let response;
    if (platform === 'ios') {
        response = await fetch('https://buy.itunes.apple.com/verifyReceipt', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                'receipt-data': receipt,
                'password': '52468d297ebc4777a3daefb2d12aabce', // App Store Connect에서 생성한 공유 비밀번호
            }),
        });
    } else if (platform === 'android') {
        response = await fetch('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/packageName/purchases/products/productId/tokens/token', {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${process.env.GOOGLE_API_KEY}`, // Google API Key
            },
        });
    }

    const data = await response.json();

    if (response.status === 200 && (platform === 'ios' ? data.status === 0 : true)) {
        // 영수증이 유효함
        await supabase
            .from('receipts')
            .insert([{receipt_data: receipt, status: 'valid', platform}]);

        grantReward(data.userId, data.productId);

        return {
            statusCode: 200,
            body: JSON.stringify({success: true, data: data}),
        };
    } else {
        // 영수증이 유효하지 않음
        await supabase
            .from('receipts')
            .insert([{receipt_data: receipt, status: 'invalid', platform}]);

        return {
            statusCode: 400,
            body: JSON.stringify({success: false, data: data}),
        };
    }

})

async function grantReward(userId: string, productId: string) {
    // 제품 ID에 따른 보상 로직
    if (productId === 'STAR100') {
        // 사용자 프로필 업데이트 예제
        await supabase
            .from('user_profiles')
            .update({star_candy: 100})
            .eq('id', userId);
    } else if (productId === 'STAR200') {
        await supabase
            .from('user_profiles')
            .update({star_candy: 200, star_candy_bonus: 25})
            .eq('id', userId);
    } else if (productId === 'STAR600') {
        await supabase
            .from('user_profiles')
            .update({star_candy: 600, star_candy_bonus: 85})
            .eq('id', userId);
    } else if (productId === 'STAR1000') {
        await supabase
            .from('user_profiles')
            .update({star_candy: 1000, star_candy_bonus: 150})
            .eq('id', userId);
    } else if (productId === 'STAR2000') {
        await supabase
            .from('user_profiles')
            .update({star_candy: 2000, star_candy_bonus: 320})
            .eq('id', userId);

    } else if ( productId === 'STAR3000') {
        await supabase
            .from('user_profiles')
            .update({star_candy: 3000, star_candy_bonus: 540})
            .eq('id', userId);
    } else if ( productId === 'STAR4000') {
        await supabase
            .from('user_profiles')
            .update({star_candy: 4000, star_candy_bonus: 760})
            .eq('id', userId);
    } else if (productId === 'STAR5000') {
        await supabase
            .from('user_profiles')
            .update({star_candy: 5000, star_candy_bonus: 1000})
            .eq('id', userId);
    }


}


/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/verify_receipt' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
