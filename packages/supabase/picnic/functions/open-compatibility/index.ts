import {
    createErrorResponse,
    createSuccessResponse,
    formatDate,
    getSupabaseClient,
    logError,
} from '.././_shared/index.ts';

interface PaymentRequest {
    userId: string;
    compatibilityId: string;
}

interface PaymentResult {
    success: boolean;
    error?: string;
}

export async function processCompatibilityPayment(
    userId: string,
    compatibilityId: string,
    starCandyAmount: number = 100,
): Promise<PaymentResult> {
    const supabase = getSupabaseClient();

    try {
        // 1. Check if user has enough star candy and get current balance
        const { data: userData, error: userError } = await supabase
            .from('user_profiles')
            .select('star_candy')
            .eq('id', userId)
            .single();

        if (userError) throw new Error(`Failed to get user data: ${userError.message}`);
        if (!userData || userData.star_candy < starCandyAmount) {
            throw new Error('스타캔디가 부족합니다');
        }

        // 2. Update user's star candy balance and mark compatibility as paid in a single transaction
        const { data, error: updateError } = await supabase
            .rpc('process_compatibility_payment', {
                p_user_id: userId,
                p_compatibility_id: compatibilityId,
                p_star_candy_amount: starCandyAmount,
            });

        if (updateError) {
            throw new Error(`결제 처리 중 오류가 발생했습니다: ${updateError.message}`);
        }

        return { success: true };
    } catch (error) {
        console.error('Payment processing error:', error);
        return {
            success: false,
            error: error instanceof Error ? error.message : '알 수 없는 오류가 발생했습니다',
        };
    }
}

Deno.serve(async (req: Request) => {
    // CORS 헤더 설정
    const headers = new Headers({
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json',
    });

    // OPTIONS 요청 처리 (CORS preflight)
    if (req.method === 'OPTIONS') {
        headers.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
        headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
        return new Response(null, { headers, status: 204 });
    }

    // POST 메소드만 허용
    if (req.method !== 'POST') {
        throw new Error('Method not allowed');
    }

    try {
        // 요청 본문 파싱
        const body: PaymentRequest = await req.json();

        // 필수 파라미터 검증
        if (!body.userId || !body.compatibilityId) {
            throw new Error('필수 파라미터가 누락되었습니다.');
        }

        // 결제 처리
        const result = await processCompatibilityPayment(
            body.userId,
            body.compatibilityId,
        );

        if (!result.success) {
            throw new Error(result.error);
        }

        return createSuccessResponse({ success: true });
    } catch (error) {
        logError(error, { context: 'open-compatibility' });
        return createErrorResponse(
            error.message,
            500,
            'OPEN-COMPATIBILITY_ERROR',
            { shouldRetry: true },
        );
    }
});
