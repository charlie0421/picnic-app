import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import OpenAI from 'https://esm.sh/openai@4.20.1'

const openai = new OpenAI({
    apiKey: Deno.env.get('OPENAI_COMPATIBILITY_API_KEY')
})

serve(async (req) => {
    console.log(`${req.method} ${req.url}`)
    console.log(req.headers.get('content-type'))
    console.log(await req.text())
    try {
        const { compatibility_id } = await req.json()

        // Supabase 클라이언트 초기화
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // 궁합 데이터 조회
        const { data: compatibility, error: fetchError } = await supabaseClient
            .from('compatibility_results')
            .select('*')
            .eq('id', compatibility_id)
            .single()

        if (fetchError || !compatibility) {
            throw new Error('Compatibility record not found')
        }

        // OpenAI API 호출
        const prompt = `
궁합 분석 정보:
- 아이돌: ${compatibility.idol_name} (${compatibility.idol_birth_date})
- 사용자: ${compatibility.user_birth_date}
- 성별: ${compatibility.user_gender}
- 태어난 시간: ${compatibility.birth_time || '미상'}

위 정보를 바탕으로 두 사람의 궁합을 분석하여 다음 JSON 형식으로 결과를 알려주세요:
{
  "compatibility_score": 85,
  "compatibility_summary": "뜨겁고 활기찬 에너지의 완벽한 조합! (200자 이내로 요약)",
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

결과는 긍정적이고 구체적으로 작성해주되, 현실적인 조언을 포함해주세요.
    `

        const completion = await openai.chat.completions.create({
            model: 'gpt-3.5-turbo-1106',
            response_format: { type: 'json_object' },
            messages: [
                { role: 'system', content: '당신은 K-POP 아이돌과 팬의 궁합을 분석하는 전문가입니다.' },
                { role: 'user', content: prompt }
            ],
        })

        const result = JSON.parse(completion.choices[0].message.content)

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
