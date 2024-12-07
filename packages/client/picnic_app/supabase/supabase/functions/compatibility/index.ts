import {
    createErrorResponse,
    createSuccessResponse,
    getSupabaseClient,
    logError,
} from '.././_shared/index.ts';
import { CompatibilityService } from '../_shared/services/compatibility.ts';

Deno.serve(async (req) => {
    try {
        const { compatibility_id } = await req.json();
        const compatibilityService = new CompatibilityService();
        const supabase = getSupabaseClient();

        const { data: compatibility, error: fetchError } = await supabase
            .from('compatibility_results')
            .select('*, artist:artist_id(*)')
            .eq('id', compatibility_id)
            .single();

        if (fetchError || !compatibility) {
            throw new Error('Compatibility record not found');
        }

        // 결과 생성 및 저장
        const result = await compatibilityService.getOrGenerateResults(compatibility);
        const updatedResult = await compatibilityService.updateResults(compatibility_id, result);
        await compatibilityService.generateAndStoreTranslations(compatibility_id, updatedResult);

        return createSuccessResponse({ success: true });
    } catch (error) {
        logError(error, { context: 'compatibility-main' });
        return createErrorResponse(
            error.message,
            500,
            'COMPATIBILITY_ERROR',
            { shouldRetry: true },
        );
    }
});
