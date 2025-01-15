import {createClient} from 'https://esm.sh/@supabase/supabase-js@2.44.4';

const supabaseUrl = Deno.env.get('SUPABASE_URL');
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const supabase = createClient(supabaseUrl, supabaseKey);

console.log('Supabase client created');

Deno.serve(async (request) => {
    try {
        const { message } = await request.json();
        const decodedData = JSON.parse(atob(message.data));

        console.log('Received notification:', decodedData);

        // 구독 취소와 1회성 구매 취소/환불 모두 처리
        if (
            decodedData.notificationType === 'SUBSCRIPTION_CANCELED' ||
            decodedData.notificationType === 'SUBSCRIPTION_REFUNDED' ||
            decodedData.notificationType === 'PURCHASE_CANCELED' ||
            decodedData.notificationType === 'REFUNDED'
        ) {
            const purchaseToken = decodedData.purchaseToken;

            // receipts 테이블에서 해당 구매 기록 찾기
            const { data: receipt, error: receiptError } = await supabase
                .from('receipts')
                .select('*')
                .eq('verification_data->purchaseToken', purchaseToken)
                .eq('status', 'valid')
                .single();

            if (receiptError) {
                console.error('Error finding receipt:', receiptError);
                throw receiptError;
            }

            if (!receipt) {
                console.log('No valid receipt found for purchase token:', purchaseToken);
                return new Response(
                    JSON.stringify({
                        success: false,
                        error: 'Receipt not found',
                    }),
                    {
                        status: 404,
                        headers: { 'Content-Type': 'application/json' },
                    },
                );
            }

            const cancellationType = decodedData.notificationType === 'SUBSCRIPTION_CANCELED' ||
                    decodedData.notificationType === 'PURCHASE_CANCELED'
                ? 'cancelled'
                : 'refunded';

            // receipts 상태 업데이트
            const { error: updateError } = await supabase
                .from('receipts')
                .update({
                    status: cancellationType,
                    cancelled_at: new Date().toISOString(),
                    cancellation_data: {
                        ...decodedData,
                        cancellation_type: cancellationType,
                    },
                })
                .eq('id', receipt.id);

            if (updateError) {
                console.error('Error updating receipt:', updateError);
                throw updateError;
            }

            // 리워드 회수
            await revokeReward(receipt.user_id, receipt.product_id, cancellationType);

            return new Response(
                JSON.stringify({
                    success: true,
                    message: `Purchase ${cancellationType} processed successfully`,
                }),
                {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' },
                },
            );
        }

        return new Response(
            JSON.stringify({
                success: true,
                message: 'Notification processed',
            }),
            {
                status: 200,
                headers: { 'Content-Type': 'application/json' },
            },
        );
    } catch (error) {
        console.error('Error processing notification:', error);
        return new Response(
            JSON.stringify({
                error: 'Internal server error',
                details: error.message,
            }),
            {
                status: 500,
                headers: { 'Content-Type': 'application/json' },
            },
        );
    }
});

async function revokeReward(userId: string, productId: string, cancellationType: string) {
    try {
        const rewardMap = {
            'star100': { star_candy: 100, star_candy_bonus: 0 },
            'star200': { star_candy: 200, star_candy_bonus: 25 },
            'star600': { star_candy: 600, star_candy_bonus: 85 },
            'star1000': { star_candy: 1000, star_candy_bonus: 150 },
            'star2000': { star_candy: 2000, star_candy_bonus: 320 },
            'star3000': { star_candy: 3000, star_candy_bonus: 540 },
            'star4000': { star_candy: 4000, star_candy_bonus: 760 },
            'star5000': { star_candy: 5000, star_candy_bonus: 1000 },
            'star7000': { star_candy: 7000, star_candy_bonus: 1500 },
            'star10000': { star_candy: 10000, star_candy_bonus: 2100 },
        };

        const reward = rewardMap[productId.toLowerCase()];
        if (!reward) {
            console.error(`Unknown product ID: ${productId}`);
            return;
        }

        const { star_candy, star_candy_bonus } = reward;

        // 현재 사용자 프로필 데이터 조회
        const { data: profileData, error: profileError } = await supabase
            .from('user_profiles')
            .select('star_candy, star_candy_bonus')
            .eq('id', userId)
            .single();

        if (profileError) throw profileError;

        // 스타캔디 차감 (음수가 되지 않도록 처리)
        const updatedStarCandy = Math.max(0, (profileData.star_candy || 0) - star_candy);
        const updatedStarCandyBonus = Math.max(
            0,
            (profileData.star_candy_bonus || 0) - star_candy_bonus,
        );

        // 프로필 업데이트
        const { error: updateError } = await supabase
            .from('user_profiles')
            .update({
                star_candy: updatedStarCandy,
                star_candy_bonus: updatedStarCandyBonus,
            })
            .eq('id', userId);

        if (updateError) throw updateError;

        // 취소/환불 기록 추가
        const transactionId = `${cancellationType}_${Date.now()}_${
            Math.random().toString(36).substr(2, 9)
        }`;

        const historyType = cancellationType === 'cancelled'
            ? 'PURCHASE_CANCEL'
            : 'PURCHASE_REFUND';

        const { error: historyError } = await supabase
            .from('star_candy_history')
            .insert({
                user_id: userId,
                amount: -star_candy,
                type: historyType,
                transaction_id: transactionId,
            });

        if (historyError) throw historyError;

        if (star_candy_bonus > 0) {
            const { error: bonusHistoryError } = await supabase
                .from('star_candy_bonus_history')
                .insert({
                    user_id: userId,
                    amount: -star_candy_bonus,
                    type: historyType,
                    expired_dt: new Date().toISOString(),
                    transaction_id: transactionId,
                    remain_amount: 0,
                });

            if (bonusHistoryError) throw bonusHistoryError;
        }

        console.log(
            `Reward revoked for user ${userId}: ${JSON.stringify(reward)}, Type: ${historyType}`,
        );
    } catch (error) {
        console.error(`Error revoking reward for user ${userId}:`, error);
        throw error;
    }
}
