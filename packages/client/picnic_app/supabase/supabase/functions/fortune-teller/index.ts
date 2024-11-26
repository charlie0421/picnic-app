import { FortuneService } from '../_shared/services/fortune.ts';
import { createErrorResponse, createSuccessResponse } from '../_shared/response.ts';

Deno.serve(async (req) => {
    try {
        const { artist_id, year } = await req.json();

        if (!artist_id || !year) {
            return createErrorResponse(
                'Artist ID와 연도가 필요합니다.',
                400,
                'INVALID_PARAMETERS',
            );
        }

        if (year < 2000 || year > 2100) {
            return createErrorResponse(
                '2000년에서 2100년 사이의 연도를 입력해주세요.',
                400,
                'INVALID_YEAR',
            );
        }

        const fortuneService = new FortuneService();

        // 운세 생성 또는 조회
        const fortune = await fortuneService.getOrGenerateFortune(artist_id, year);
        console.log('Fortune:', fortune);

        // 번역 생성 (비동기로 처리)
        fortuneService.generateTranslations(artist_id, year, fortune)
            .catch((error) => console.error('Translation error:', error));

        return createSuccessResponse({ fortune });
    } catch (error) {
        console.error('Fortune telling error:', error);

        return createErrorResponse(
            '운세 생성 중 오류가 발생했습니다.',
            500,
            'FORTUNE_GENERATION_ERROR',
            { shouldRetry: true },
        );
    }
});
