import { FortuneService } from '../_shared/services/fortune.ts';
import { createErrorResponse, createSuccessResponse } from '../_shared/response.ts';
import { SupportedLanguage } from '../_shared/types/openai.ts';

Deno.serve(async (req) => {
    try {
        const { artist_id, year, language } = await req.json();

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

        // 언어 파라미터가 있는 경우 유효성 검사
        if (language) {
            const supportedLanguages: SupportedLanguage[] = ['ko', 'en', 'ja', 'zh'];
            if (!supportedLanguages.includes(language as SupportedLanguage)) {
                return createErrorResponse(
                    '지원하지 않는 언어입니다.',
                    400,
                    'UNSUPPORTED_LANGUAGE',
                );
            }
        }

        const fortuneService = new FortuneService();

        // 먼저 운세 데이터를 가져오거나 생성 (이 과정에서 누락된 번역도 생성됨)
        const fortune = await fortuneService.getOrGenerateFortune(artist_id, year);

        // 요청된 언어의 운세 데이터 조회
        const translatedFortune = await fortuneService.getTranslatedFortune(fortune.id!, language);

        return createSuccessResponse({ fortune: translatedFortune });
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
