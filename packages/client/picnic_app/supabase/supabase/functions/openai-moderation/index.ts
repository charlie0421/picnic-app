// supabase/functions/openai-moderation/index.ts

import {serve} from "https://deno.land/std@0.168.0/http/server.ts"
import OpenAI from "https://deno.land/x/openai@v4.20.1/mod.ts"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', {headers: corsHeaders})
    }

    try {
        console.log('Request received');

        const openAiKey = Deno.env.get('OPENAI_MODERATOR_API_KEY')
        if (!openAiKey) {
            throw new Error('Missing OpenAI API key')
        }

        // 요청 바디 파싱
        const requestText = await req.text();
        console.log('Raw request body:', requestText);

        let bodyJson;
        try {
            bodyJson = JSON.parse(requestText);
        } catch (e) {
            console.error('JSON parsing error:', e);
            throw new Error('Invalid JSON in request body');
        }

        const {text} = bodyJson;
        if (!text || typeof text !== 'string') {
            throw new Error('Invalid or missing text parameter');
        }

        console.log('Processing text:', text);

        // OpenAI 클라이언트 초기화
        const openai = new OpenAI({
            apiKey: openAiKey,
        });

        // 모더레이션 API 호출
        const moderationResult = await openai.moderations.create({
            input: text,
        });

        console.log('Moderation result:', moderationResult);

        return new Response(
            JSON.stringify({
                success: true,
                data: moderationResult.results[0],
            }),
            {
                headers: {...corsHeaders, 'Content-Type': 'application/json'},
                status: 200,
            }
        )

    } catch (error) {
        console.error('Error occurred:', error);

        return new Response(
            JSON.stringify({
                success: false,
                error: error.message,
                errorType: error.name,
                errorDetails: error.stack
            }),
            {
                headers: {...corsHeaders, 'Content-Type': 'application/json'},
                status: 400,
            }
        )
    }
})
