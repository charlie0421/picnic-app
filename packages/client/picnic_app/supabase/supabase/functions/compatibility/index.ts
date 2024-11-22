import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import OpenAI from 'https://esm.sh/openai'

const openai = new OpenAI({
    apiKey: Deno.env.get('OPENAI_COMPATIBILITY_API_KEY')
})

const SUPPORTED_LANGUAGES = ['ko', 'en', 'ja', 'zh'] as const
type SupportedLanguage = typeof SUPPORTED_LANGUAGES[number]

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

serve(async (req) => {
    try {
        const { compatibility_id } = await req.json()

        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // 현재 궁합 데이터 조회
        const { data: currentCompatibility, error: fetchError } = await supabaseClient
            .from('compatibility_results')
            .select('*')
            .eq('id', compatibility_id)
            .single()

        if (fetchError || !currentCompatibility) {
            throw new Error('Compatibility record not found')
        }

        // 기존 i18n 결과 검색
        const { data: existingI18nResults, error: searchError } = await supabaseClient
            .from('compatibility_results_i18n')
            .select('*')
            .eq('compatibility_id', compatibility_id)

        if (searchError) {
            throw searchError
        }

        const existingLanguages = new Set(existingI18nResults?.map(r => r.language) || [])
        let results: { [key: string]: CompatibilityResult } = {}

        // 각 언어별로 결과 생성 또는 재사용
        for (const lang of SUPPORTED_LANGUAGES) {
            if (existingLanguages.has(lang)) {
                // 기존 결과 재사용
                const existingResult = existingI18nResults?.find(r => r.language === lang)
                results[lang] = {
                    compatibility_score: existingResult.compatibility_score,
                    compatibility_summary: existingResult.compatibility_summary,
                    details: existingResult.details,
                    tips: existingResult.tips
                }
            } else {
                // 새로운 분석 수행
                results[lang] = await generateCompatibilityResult(currentCompatibility, lang)
            }
        }

        // 모든 언어 결과 upsert
        const { error: upsertError } = await supabaseClient
            .from('compatibility_results_i18n')
            .upsert(
                SUPPORTED_LANGUAGES.map(lang => ({
                    compatibility_id,
                    language: lang,
                    compatibility_score: results[lang].compatibility_score,
                    compatibility_summary: results[lang].compatibility_summary,
                    details: results[lang].details,
                    tips: results[lang].tips,
                    updated_at: new Date().toISOString()
                }))
            )

        if (upsertError) {
            throw upsertError
        }

        // 메인 결과 상태 업데이트
        const { error: updateError } = await supabaseClient
            .from('compatibility_results')
            .update({
                status: 'completed',
                completed_at: new Date().toISOString()
            })
            .eq('id', compatibility_id)

        if (updateError) {
            throw updateError
        }

        return new Response(JSON.stringify({ success: true }), {
            headers: { 'Content-Type': 'application/json' },
        })
    } catch (error) {
        // 에러 발생 시 상태 업데이트
        if (error.compatibility_id) {
            const supabaseClient = createClient(
                Deno.env.get('SUPABASE_URL') ?? '',
                Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
            )

            await supabaseClient
                .from('compatibility_results')
                .update({
                    status: 'error',
                    error_message: error.message,
                })
                .eq('id', error.compatibility_id)
        }

        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        })
    }
})

async function generateCompatibilityResult(compatibility: any, lang: SupportedLanguage): Promise<CompatibilityResult> {
    const languagePrompts = {
        ko: '한국의 MZ 세대 여성의 말투로 작성해주세요.',
        en: 'Write in a tone that appeals to Gen Z women in English-speaking countries.',
        ja: '日本の若い女性向けの文体で書いてください。',
        zh: '请用适合中国年轻女性的语气写作。'
    }

    const languageSystemPrompts = {
        ko: 'K-POP 아이돌과 팬의 궁합을 분석하는 전문가입니다.',
        en: 'You are an expert in analyzing compatibility between K-POP idols and their fans.',
        ja: 'K-POPアイドルとファンの相性を分析する専門家です。',
        zh: '您是分析K-POP偶像与粉丝相配度的专家。'
    }

    const prompt = `
${getLocalizedDateFormat(compatibility.idol_birth_date, lang)}
${getLocalizedGender(compatibility.gender, lang)}
${getLocalizedDateFormat(compatibility.user_birth_date, lang)}
${getLocalizedBirthTime(compatibility.user_birth_time, lang)}
${getLocalizedUserGender(compatibility.gender, lang)}

${getLocalizedPromptTemplate(lang)}

${languagePrompts[lang]}
    `

    const completion = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        response_format: { type: 'json_object' },
        messages: [
            { role: 'system', content: languageSystemPrompts[lang] },
            { role: 'user', content: prompt }
        ],
    })

    return JSON.parse(completion.choices[0].message.content)
}

function getLocalizedDateFormat(dateString: string, lang: SupportedLanguage): string {
    const date = new Date(dateString)

    const formats = {
        ko: `아티스트 생년월일: ${date.getFullYear()}년 ${date.getMonth() + 1}월 ${date.getDate()}일`,
        en: `Artist's birth date: ${date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}`,
        ja: `アーティストの生年月日: ${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`,
        zh: `艺人出生日期: ${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`
    }

    return formats[lang]
}

function getLocalizedGender(gender: string, lang: SupportedLanguage): string {
    const genderTranslations = {
        ko: `아티스트 성별: ${gender}`,
        en: `Artist's gender: ${gender}`,
        ja: `アーティストの性別: ${gender}`,
        zh: `艺人性别: ${gender}`
    }
    return genderTranslations[lang]
}

function getLocalizedBirthTime(birthTime: string | null, lang: SupportedLanguage): string {
    const unknown = {
        ko: '미상',
        en: 'Unknown',
        ja: '不明',
        zh: '未知'
    }

    const translations = {
        ko: `사용자 태어난 시간: ${birthTime || unknown[lang]}`,
        en: `User's birth time: ${birthTime || unknown[lang]}`,
        ja: `ユーザーの出生時刻: ${birthTime || unknown[lang]}`,
        zh: `用户出生时间: ${birthTime || unknown[lang]}`
    }
    return translations[lang]
}

function getLocalizedUserGender(gender: string, lang: SupportedLanguage): string {
    const translations = {
        ko: `사용자 성별: ${gender}`,
        en: `User's gender: ${gender}`,
        ja: `ユーザーの性別: ${gender}`,
        zh: `用户性别: ${gender}`
    }
    return translations[lang]
}

function getLocalizedPromptTemplate(lang: SupportedLanguage): string {
    const templates = {
        ko: `
위 정보를 바탕으로 두 사람의 궁합을 분석하여 다음 JSON 형식으로 결과를 알려주세요:
{
  "compatibility_score": 85,
  "compatibility_summary": "상세한 궁합 설명",
  "details": {
    "style": {
      "idol_style": "아이돌의 패션과 스타일 특징",
      "user_style": "사용자에게 어울리는 스타일",
      "couple_style": "커플 스타일링 제안"
    },
    "activities": {
      "recommended": ["추천 활동"],
      "description": "활동 설명"
    }
  },
  "tips": ["팁1", "팁2", "패션 팁"]
}`,
        en: `
Based on the above information, analyze the compatibility between these two people and provide the results in the following JSON format:
{
  "compatibility_score": 85,
  "compatibility_summary": "Detailed compatibility explanation",
  "details": {
    "style": {
      "idol_style": "Idol's fashion and style characteristics",
      "user_style": "Recommended style for user",
      "couple_style": "Couple styling suggestions"
    },
    "activities": {
      "recommended": ["Recommended activities"],
      "description": "Activity description"
    }
  },
  "tips": ["Tip 1", "Tip 2", "Fashion tip"]
}`,
        ja: `
上記の情報に基づいて二人の相性を分析し、以下のJSON形式で結果を提供してください：
{
  "compatibility_score": 85,
  "compatibility_summary": "詳細な相性説明",
  "details": {
    "style": {
      "idol_style": "アイドルのファッションとスタイルの特徴",
      "user_style": "ユーザーに似合うスタイル",
      "couple_style": "カップルスタイリングの提案"
    },
    "activities": {
      "recommended": ["おすすめの活動"],
      "description": "活動の説明"
    }
  },
  "tips": ["ヒント1", "ヒント2", "ファッションのヒント"]
}`,
        zh: `
根据上述信息，分析两人的相配度，并以以下JSON格式提供结果：
{
  "compatibility_score": 85,
  "compatibility_summary": "详细的相配度说明",
  "details": {
    "style": {
      "idol_style": "偶像的时尚和风格特点",
      "user_style": "适合用户的风格建议",
      "couple_style": "情侣造型建议"
    },
    "activities": {
      "recommended": ["推荐活动"],
      "description": "活动说明"
    }
  },
  "tips": ["建议1", "建议2", "时尚建议"]
}`,
    }
    return templates[lang]
}
