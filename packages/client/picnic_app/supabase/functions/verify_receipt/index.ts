import "https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.44.3';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const supabase = createClient(supabaseUrl, supabaseKey);
console.log("Supabase client created");
const SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';
const PRODUCTION_URL = 'https://buy.itunes.apple.com/verifyReceipt';

// 환경 변수로 설정하거나, 요청에서 전달받은 환경 정보를 사용

Deno.serve(async (request: Request) => {
    try {
        console.log("Received request");
        const { receipt, platform, productId , user_id, environment} = await request.json();
        console.log(`Received receipt for platform: ${platform}, productId: ${productId}`);
        let verificationUrl: RequestInfo | URL;

          // verificationUrl = SANDBOX_URL;
        // 클라이언트에서 전송한 환경 정보를 사용할 경우
        if (environment === 'production') {
          verificationUrl = PRODUCTION_URL;
        } else {
          verificationUrl = SANDBOX_URL;
        }

        let response;
        if (platform === 'ios') {
            console.log("Verifying iOS receipt");
            response = await fetch(verificationUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    'receipt-data': receipt,
                    'password': '52468d297ebc4777a3daefb2d12aabce',
                }),
            });
        } else if (platform === 'android') {
            console.log("Verifying Android receipt");
            const packageName = 'io.iconcasting.picnic.app';
            response = await fetch(`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/products/${productId}/tokens/${receipt}`, {
                method: 'GET',
                headers: { 'Authorization': `Bearer AIzaSyDm0_bdB3-ky3Za-7H4Ysgj1zci6Yb-NzU` },
            });
        } else {
            throw new Error(`Invalid platform: ${platform}`);
        }

        const data = await response.json();
        console.log("Verification response:", data);

        if (response.status === 200 && (platform === 'ios' ? data.status === 0 : true)) {
            console.log("Receipt is valid");
            await supabase.from('receipts').insert([{receipt_data: receipt, status: 'valid', platform}]);

            // Generate a unique transaction ID
            const transactionId = `${platform}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

            await grantReward(user_id, productId, transactionId);

            return new Response(JSON.stringify({success: true, data: data}), {
                status: 200,
                headers: { 'Content-Type': 'application/json' }
            });
        } else {
            console.log("Receipt is invalid");
            await supabase.from('receipts').insert([{receipt_data: receipt, status: 'invalid', platform}]);

            return new Response(JSON.stringify({success: false, data: data}), {
                status: 400,
                headers: { 'Content-Type': 'application/json' }
            });
        }
    } catch (error) {
        console.error("Error processing request:", error);
        return new Response(JSON.stringify({ error: "Internal server error", details: error.message }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' }
        });
    }
});

async function grantReward(userId: string, productId: string, transactionId: string) {
    try {
        const rewardMap = {
        'STAR100': { star_candy: 100, star_candy_bonus: 0 },
        'STAR200': { star_candy: 200, star_candy_bonus: 25 },
        'STAR600': { star_candy: 600, star_candy_bonus: 85 },
        'STAR1000': { star_candy: 1000, star_candy_bonus: 150 },
        'STAR2000': { star_candy: 2000, star_candy_bonus: 320 },
        'STAR3000': { star_candy: 3000, star_candy_bonus: 540 },
        'STAR4000': { star_candy: 4000, star_candy_bonus: 760 },
        'STAR5000': { star_candy: 5000, star_candy_bonus: 1000 },
    };

    const reward = rewardMap[productId];
    if (!reward) {
        console.error(`Unknown product ID: ${productId}`);
        return;
    }

    const { star_candy, star_candy_bonus } = reward;

    // Calculate next month's 15th
    const now = new Date();
    const expireDate = new Date(now.getFullYear(), now.getMonth() + 1, 15);

        // Update user_profiles
        const { data: profileData, error: profileError } = await supabase
            .from('user_profiles')
            .select('star_candy, star_candy_bonus')
            .eq('id', userId)
            .single();

        if (profileError) throw profileError;

        const updatedStarCandy = (profileData.star_candy || 0) + star_candy;
        const updatedStarCandyBonus = (profileData.star_candy_bonus || 0) + star_candy_bonus;

        const { error: updateError } = await supabase
            .from('user_profiles')
            .update({
                star_candy: updatedStarCandy,
                star_candy_bonus: updatedStarCandyBonus
            })
            .eq('id', userId);

        if (updateError) throw updateError;

        // Insert into star_candy_history
        const { error: historyError } = await supabase
            .from('star_candy_history')
            .insert({
                user_id: userId,
                amount: star_candy,
                type: 'PURCHASE',
                transaction_id: transactionId
            });

        if (historyError) throw historyError;

        // Insert into star_candy_bonus_history if bonus > 0
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

            if (bonusHistoryError) throw bonusHistoryError;
        }

        console.log(`Reward granted for user ${userId}: ${JSON.stringify(reward)}, Expiry: ${expireDate.toISOString()}`);
    } catch (error) {
        console.error(`Error granting reward for user ${userId}:`, error);
        throw error;  // Re-throw the error to be handled by the caller
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
