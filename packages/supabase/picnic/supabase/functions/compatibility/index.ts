import {
  createErrorResponse,
  createSuccessResponse,
  getSupabaseClient,
  logError,
} from '@shared/index.ts';
import { CompatibilityService } from '@shared/services/compatibility.ts';
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
    const similarResults = await compatibilityService.existSimilarResults(
      compatibility,
    );
    console.log('similarResults', similarResults);
    console.log('similarResults.length', similarResults.length);
    console.log('similarResults[0]', similarResults[0]);
    if (similarResults.length > 0) {
      await compatibilityService.copyExistingResults(
        similarResults[0],
        compatibility_id,
      );
    } else {
      await compatibilityService.generateNewResults(compatibility);
      await compatibilityService.updateCompleted(compatibility_id);
    }
    return createSuccessResponse({
      success: true,
    });
  } catch (error) {
    logError(error, {
      context: 'compatibility-main',
    });
    return createErrorResponse(error.message, 500, 'COMPATIBILITY_ERROR', {
      shouldRetry: true,
    });
  }
});
