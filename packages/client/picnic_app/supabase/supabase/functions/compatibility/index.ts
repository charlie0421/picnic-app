import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import OpenAI from 'https://esm.sh/openai'

// 환경변수 설정
const DEEPL_API_KEY = Deno.env.get('DEEPL_API_KEY')
const DEEPL_API_URL = 'https://api-free.deepl.com/v2/translate'

const openai = new OpenAI({
    apiKey: Deno.env.get('OPENAI_COMPATIBILITY_API_KEY')
})

// 지원 언어 정의
const SUPPORTED_LANGUAGES = ['ko', 'en', 'ja', 'zh'] as const
type SupportedLanguage = typeof SUPPORTED_LANGUAGES[number]


// 유틸리티 함수
function formatDate(dateString: string): string {
    const date = new Date(dateString)
    return `${date.getFullYear()}년 ${date.getMonth() + 1}월 ${date.getDate()}일`
}

async function translateText(text: string, targetLang: string): Promise<string> {
    try {
        const response = await fetch(DEEPL_API_URL, {
            method: 'POST',
            headers: {
                'Authorization': `DeepL-Auth-Key ${DEEPL_API_KEY}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                text: [text],
                target_lang: targetLang.toUpperCase(),
                source_lang: 'KO'
            })
        })

        if (!response.ok) {
            throw new Error(`DeepL API error: ${response.statusText}`)
        }

        const data = await response.json()
        return data.translations[0].text
    } catch (error) {
        console.error('Translation error:', error);
        throw error;
    }
}

// 메인 서버 함수
serve(async (req) => {
    try {
        const { compatibility_id } = await req.json()

        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        const { data: compatibility, error: fetchError } = await supabaseClient
            .from('compatibility_results')
            .select('*, artist:artist_id(*)')
            .eq('id', compatibility_id)
            .single()

        if (fetchError || !compatibility) {
            throw new Error('Compatibility record not found')
        }

        // 결과 생성 및 저장
        const result = await getOrGenerateResults(supabaseClient, compatibility)
        await updateCompatibilityResults(supabaseClient, compatibility_id, result)
        await generateAndStoreTranslations(supabaseClient, compatibility_id, result)

        return new Response(JSON.stringify({ success: true }), {
            headers: { 'Content-Type': 'application/json' },
        })
    } catch (error) {
        console.error('Error:', error)
        return new Response(JSON.stringify({
            error: error.message,
            shouldRetry: true
        }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        })
    }
})

async function getOrGenerateResults(supabaseClient, currentCompatibility): Promise<CompatibilityResult> {
    try {
        const query = supabaseClient
            .from('compatibility_results')
            .select('compatibility_score, compatibility_summary, details, tips')
            .eq('artist_id', currentCompatibility.artist_id)
            .eq('idol_birth_date', currentCompatibility.idol_birth_date)
            .eq('user_birth_date', currentCompatibility.user_birth_date)
            .eq('gender', currentCompatibility.gender)
            .eq('status', 'completed')
            .neq('id', currentCompatibility.id)
            .order('completed_at', { ascending: false })
            .limit(1)

        const { data: existingResults, error } = await (
            currentCompatibility.user_birth_time === null
                ? query.is('user_birth_time', null)
                : query.eq('user_birth_time', currentCompatibility.user_birth_time)
        )

        if (error) throw error

        if (existingResults?.length > 0) {
            console.log('Reusing existing result')
            return existingResults[0]
        }

        console.log('Generating new result')
        return await generateNewResults(currentCompatibility)
    } catch (error) {
        console.error('Error in getOrGenerateResults:', error)
        throw error
    }
}

async function generateNewResults(compatibility): Promise<CompatibilityResult> {
    try {
        const prompt = `
궁합 분석 정보:
- 생년월일: ${formatDate(compatibility.idol_birth_date)}
- 사용자: ${formatDate(compatibility.user_birth_date)} ${compatibility.user_birth_time ? `(${compatibility.user_birth_time})` : ''}
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
}

- 응답은 반드시 유효한 JSON 형식이어야 합니다
- compatibility_score는 0~100 사이의 정수여야 합니다. 그리고 85는 예제입니다.
- compatibility_summary는 100자 이상 250자 이내여야 합니다
- tips는 반드시 길이가 3인 문자열 배열이어야 하며, 마지막 팁은 패션 아이템 추천이어야 합니다
- 결과는 K-POP 아이돌과 팬의 궁합을 분석하는 전문가의 관점에서 작성되어야 합니다
- MZ 세대 여성의 말투로 작성해주세요`

        const completion = await openai.chat.completions.create({
            model: 'gpt-4o-mini',
            response_format: { type: 'json_object' },
            messages: [
                {
                    role: 'system',
                    content: '당신은 K-POP 아이돌과 팬의 궁합을 분석하는 전문가입니다. 응답은 반드시 요청된 JSON 형식을 정확히 따라야 합니다.'
                },
                { role: 'user', content: prompt }
            ],
        })

        const result = JSON.parse(completion.choices[0].message.content)
        if (!Array.isArray(result.tips) || result.tips.length !== 3) {
            throw new Error('Tips must be an array of exactly 3 strings')
        }

        return result
    } catch (error) {
        console.error('Error in generateNewResults:', error)
        throw error
    }
}

async function generateAndStoreTranslations(supabaseClient, compatibility_id, result: CompatibilityResult) {
    try {
        for (const targetLang of SUPPORTED_LANGUAGES) {
            if (targetLang === 'ko') continue

            // details 객체의 각 필드 번역
            const translatedDetails = {
                style: {
                    idol_style: await translateText(result.details.style.idol_style, targetLang),
                    user_style: await translateText(result.details.style.user_style, targetLang),
                    couple_style: await translateText(result.details.style.couple_style, targetLang)
                },
                activities: {
                    recommended: await Promise.all(
                        result.details.activities.recommended.map(activity =>
                            translateText(activity, targetLang)
                        )
                    ),
                    description: await translateText(result.details.activities.description, targetLang)
                }
            };

            // tips 번역
            const translatedTips = await Promise.all(
                result.tips.map(tip => translateText(tip, targetLang))
            );

            // 기존 데이터 확인
            const { data: existingData } = await supabaseClient
                .from('compatibility_results_i18n')
                .select()
                .eq('compatibility_id', compatibility_id)
                .eq('language', targetLang)
                .maybeSingle();

            const translatedResult = {
                compatibility_id,
                language: targetLang,
                compatibility_score: result.compatibility_score,
                compatibility_summary: await translateText(
                    result.compatibility_summary,
                    targetLang
                ),
                details: translatedDetails,
                tips: translatedTips,
                updated_at: new Date().toISOString()
            };

            if (existingData) {
                // UPDATE
                const { error } = await supabaseClient
                    .from('compatibility_results_i18n')
                    .update(translatedResult)
                    .eq('compatibility_id', compatibility_id)
                    .eq('language', targetLang);

                if (error) {
                    console.error('Translation update error:', error);
                    throw error;
                }
            } else {
                // INSERT
                const { error } = await supabaseClient
                    .from('compatibility_results_i18n')
                    .insert(translatedResult);

                if (error) {
                    console.error('Translation insert error:', error);
                    throw error;
                }
            }
        }
    } catch (error) {
        console.error('Error in generateAndStoreTranslations:', error);
        throw error;
    }
}

async function updateCompatibilityResults(supabaseClient, compatibility_id, result: CompatibilityResult) {
    try {
        const { error } = await supabaseClient
            .from('compatibility_results')
            .update({
                compatibility_score: result.compatibility_score,
                compatibility_summary: result.compatibility_summary,
                details: result.details,
                tips: result.tips, // 배열로 직접 저장
                status: 'completed',
                completed_at: new Date().toISOString(),
                error_message: null
            })
            .eq('id', compatibility_id)

        if (error) {
            console.error('Main table update error:', error);
            throw error;
        }
    } catch (error) {
        console.error('Error in updateCompatibilityResults:', error);
        throw error;
    }
}

// 타입 정의 수정
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
