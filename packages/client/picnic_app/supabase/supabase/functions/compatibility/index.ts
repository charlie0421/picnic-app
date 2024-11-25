import {
    createErrorResponse,
    createSuccessResponse,
    formatDate,
    getSupabaseClient,
    logError,
} from '.././_shared/index.ts';

import {
    createChatCompletion,
    SUPPORTED_LANGUAGES,
    SupportedLanguage,
    translateBatch,
    translateText,
} from '.././_shared/ai/index.ts';

interface CompatibilityResult {
    compatibility_score: number;
    compatibility_summary: string;
    details: {
        style: {
            idol_style: string;
            user_style: string;
            couple_style: string;
        };
        activities: {
            recommended: string[];
            description: string;
        };
    };
    tips: string[];
}

interface Compatibility {
    id: string;
    idol_birth_date: string;
    user_birth_date: string;
    user_birth_time: string | null;
    gender: string;
    artist_id: string;
    artist: {
        name: string;
        // 기타 아티스트 관련 필드들...
    };
}

async function getOrGenerateResults(
    supabase: ReturnType<typeof getSupabaseClient>,
    currentCompatibility: Compatibility,
): Promise<CompatibilityResult> {
    try {
        // 동일한 조합의 기존 결과 검색
        const query = supabase
            .from('compatibility_results')
            .select('compatibility_score, compatibility_summary, details, tips')
            .eq('artist_id', currentCompatibility.artist_id)
            .eq('idol_birth_date', currentCompatibility.idol_birth_date)
            .eq('user_birth_date', currentCompatibility.user_birth_date)
            .eq('gender', currentCompatibility.gender)
            .eq('status', 'completed')
            .neq('id', currentCompatibility.id)
            .order('completed_at', { ascending: false })
            .limit(1);

        const { data: existingResults, error } = await (
            currentCompatibility.user_birth_time === null
                ? query.is('user_birth_time', null)
                : query.eq('user_birth_time', currentCompatibility.user_birth_time)
        );

        if (error) throw error;

        // 기존 결과가 있으면 재사용
        if (existingResults?.length > 0) {
            console.log('Reusing existing result');
            return existingResults[0];
        }

        // 새로운 결과 생성
        console.log('Generating new result');
        return await generateNewResults(currentCompatibility);
    } catch (error) {
        logError(error, {
            context: 'compatibility-result',
            compatibility: currentCompatibility,
        });
        throw error;
    }
}

async function generateNewResults(compatibility: Compatibility): Promise<CompatibilityResult> {
    const prompt = `
궁합 분석 정보:
- 아이돌: ${compatibility.artist.name}
- 아이돌 생년월일: ${formatDate(compatibility.idol_birth_date)}
- 사용자 생년월일: ${formatDate(compatibility.user_birth_date)} ${
        compatibility.user_birth_time ? `(${compatibility.user_birth_time})` : ''
    }
- 성별: ${compatibility.gender}
- 태어난 시간: ${compatibility.user_birth_time || '미상'}

위 정보를 바탕으로 두 사람의 궁합을 분석하여 다음 JSON 형식으로 결과를 알려주세요:
{
  "compatibility_score": 85,
  "compatibility_summary": "뜨겁고 활기찬 에너지의 완벽한 조합!",
  "details": {
    "style": {
      "idol_style": "아이돌의 패션과 스타일 특징 설명",
      "user_style": "사용자에게 어울리는 스타일 추천",
      "couple_style": "커플 스타일링 제안"
    },
    "activities": {
      "recommended": ["추천 활동 1", "추천 활동 2", "추천 활동 3"],
      "description": "추천 활동에 대한 상세 설명"
    }
  },
  "tips": [
    "궁합을 높이기 위한 팁 1",
    "궁합을 높이기 위한 팁 2",
    "패션 아이템 추천"
  ]
}`;

    try {
        const response = await createChatCompletion(prompt, {
            model: 'gpt-4o-mini',
            responseFormat: 'json_object',
            systemPrompt:
                '당신은 K-POP 아이돌과 팬의 궁합을 분석하는 전문가입니다. MZ 세대 여성의 말투로 작성해주세요.',
            temperature: 0.7,
        });

        const result = JSON.parse(response) as CompatibilityResult;

        if (!Array.isArray(result.tips) || result.tips.length !== 3) {
            throw new Error('Invalid tips format');
        }

        return result;
    } catch (error) {
        logError(error, {
            context: 'compatibility-generation',
            compatibility,
        });
        throw error;
    }
}

async function updateCompatibilityResults(
    supabase: ReturnType<typeof getSupabaseClient>,
    compatibilityId: string,
    result: CompatibilityResult,
): Promise<void> {
    try {
        const { error } = await supabase
            .from('compatibility_results')
            .update({
                ...result,
                status: 'completed',
                completed_at: new Date().toISOString(),
                error_message: null,
            })
            .eq('id', compatibilityId);

        if (error) throw error;
    } catch (error) {
        logError(error, {
            context: 'update-compatibility',
            compatibilityId,
            result,
        });
        throw error;
    }
}

async function generateAndStoreTranslations(
    supabase: ReturnType<typeof getSupabaseClient>,
    compatibilityId: string,
    result: CompatibilityResult,
): Promise<void> {
    try {
        // 기존 번역 삭제
        await supabase
            .from('compatibility_results_i18n')
            .delete()
            .eq('compatibility_id', compatibilityId);

        // 각 언어별 번역 생성 및 저장
        for (const lang of SUPPORTED_LANGUAGES) {
            try {
                const translatedResult = await translateCompatibilityResult(result, lang);

                await supabase
                    .from('compatibility_results_i18n')
                    .insert({
                        compatibility_id: compatibilityId,
                        language: lang,
                        ...translatedResult,
                        created_at: new Date().toISOString(),
                        updated_at: new Date().toISOString(),
                    });

                console.log(`Successfully saved ${lang} translation`);
            } catch (langError) {
                logError(langError, {
                    context: 'translation-processing',
                    language: lang,
                    compatibilityId,
                });
                // 개별 언어 처리 실패 시 다음 언어로 계속 진행
            }
        }
    } catch (error) {
        logError(error, {
            context: 'translations',
            compatibilityId,
        });
        throw error;
    }
}

async function translateCompatibilityResult(
    result: CompatibilityResult,
    targetLang: SupportedLanguage,
): Promise<CompatibilityResult> {
    if (targetLang === 'ko') return result;

    const translatedDetails = {
        style: {
            idol_style: await translateText(result.details.style.idol_style, targetLang),
            user_style: await translateText(result.details.style.user_style, targetLang),
            couple_style: await translateText(result.details.style.couple_style, targetLang),
        },
        activities: {
            recommended: await translateBatch(result.details.activities.recommended, targetLang),
            description: await translateText(result.details.activities.description, targetLang),
        },
    };

    return {
        ...result,
        compatibility_summary: await translateText(result.compatibility_summary, targetLang),
        details: translatedDetails,
        tips: await translateBatch(result.tips, targetLang),
    };
}

Deno.serve(async (req) => {
    try {
        const { compatibility_id } = await req.json();
        const supabase = getSupabaseClient();

        // 호환성 데이터 조회
        const { data: compatibility, error: fetchError } = await supabase
            .from('compatibility_results')
            .select('*, artist:artist_id(*)')
            .eq('id', compatibility_id)
            .single();

        if (fetchError || !compatibility) {
            throw new Error('Compatibility record not found');
        }

        // 결과 생성 및 저장
        const result = await getOrGenerateResults(supabase, compatibility);
        await updateCompatibilityResults(supabase, compatibility_id, result);
        await generateAndStoreTranslations(supabase, compatibility_id, result);

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
