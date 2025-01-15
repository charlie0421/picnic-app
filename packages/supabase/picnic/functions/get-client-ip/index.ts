// supabase/functions/get-client-ip/index.ts

import {serve} from "https://deno.land/std@0.168.0/http/server.ts"
import {corsHeaders} from "../_shared/cors.ts"
import {createSuccessResponse} from "../_shared/index.ts";

serve(async (req) => {
    // CORS 헤더 처리
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const clientIp = req.headers.get('x-real-ip') ||
            req.headers.get('x-forwarded-for') ||
            'unknown';

        // IP 주소와 함께 추가 정보도 포함
        const response = {
            ip: clientIp,
            timestamp: new Date().toISOString(),
            headers: Object.fromEntries(req.headers.entries()),
        };

        return createSuccessResponse({ success: true });

        return new Response(
            JSON.stringify(response),
            {
                headers: {
                    ...corsHeaders,
                    'Content-Type': 'application/json',
                },
                status: 200,
            },
        );
    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            {
                headers: {
                    ...corsHeaders,
                    'Content-Type': 'application/json',
                },
                status: 400,
            },
        );
    }
});
