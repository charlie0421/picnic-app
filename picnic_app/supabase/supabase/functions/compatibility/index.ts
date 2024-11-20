import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import OpenAI from 'https://esm.sh/openai'

const openai = new OpenAI({
    apiKey: Deno.env.get('OPENAI_COMPATIBILITY_API_KEY')
})

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

        // 기본 쿼리 조건
        const query = supabaseClient
            .from('compatibility_results')
            .select('compatibility_score, compatibility_summary, details, tips')
            .eq('idol_birth_date', currentCompatibility.idol_birth_date)
            .eq('user_birth_date', currentCompatibility.user_birth_date)
            .eq('gender', currentCompatibility.gender)
            .eq('status', 'completed')
            .neq('id', compatibility_id)
            .order('completed_at', { ascending: false })
            .limit(1)

        // user_birth_time이 null인 경우와 아닌 경우를 구분하여 처리
        const { data: existingResults, error: searchError } = await (
            currentCompatibility.user_birth_time === null
                ? query.is('user_birth_time', null)
                : query.eq('user_birth_time', currentCompatibility.user_birth_time)
        )

        if (searchError) {
            throw searchError
        }

        let result

        if (existingResults && existingResults.length > 0) {
            // 기존 결과 재활용
            result = existingResults[0]
            console.log('Reusing existing result')
        } else {
            // 새로운 분석 수행
            const prompt = `
궁합 분석 정보:
- 생년월일: ${formatDate(currentCompatibility.idol_birth_date)}
- 사용자: ${formatDate(currentCompatibility.user_birth_date)} ${currentCompatibility.user_birth_time ? `(${currentCompatibility.user_birth_time})` : ''}
- 성별: ${currentCompatibility.gender}
- 태어난 시간: ${currentCompatibility.user_birth_time || '미상'}

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
    "궁합을 높이기 위한 팁 3"
  ]
}

compatibility_score : 0~100 사이의 숫자로 궁합의 점수를 나타냅니다. 높을수록 더 좋은 궁합입니다.
결과는 긍정적이고 구체적으로 작성해주되, 현실적인 조언을 포함해주세요.
compatibility_summary 항목은 200자 이내로 작성해주세요.
MZ 세대 여성의 말투로 작성해주세요.
            `

            const completion = await openai.chat.completions.create({
                model: 'gpt-4-mini',
                response_format: { type: 'json_object' },
                messages: [
                    { role: 'system', content: '당신은 K-POP 아이돌과 팬의 궁합을 분석하는 전문가입니다.' },
                    { role: 'user', content: prompt }
                ],
            })

            result = JSON.parse(completion.choices[0].message.content)
            console.log('Generated new result')
        }

        // 결과 업데이트
        const { error: updateError } = await supabaseClient
            .from('compatibility_results')
            .update({
                compatibility_score: result.compatibility_score,
                compatibility_summary: result.compatibility_summary,
                details: result.details,
                tips: result.tips,
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
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        })
    }
})

function formatDate(dateString: string): string {
    const date = new Date(dateString)
    return `${date.getFullYear()}년 ${date.getMonth() + 1}월 ${date.getDate()}일`
}
