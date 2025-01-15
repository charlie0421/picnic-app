// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import {createClient} from 'https://esm.sh/@supabase/supabase-js@2';
import {decode} from 'https://deno.land/x/djwt/mod.ts';

console.log("Hello from Functions!")

// 가상의 보상 처리 엣지 함수를 호출하는 함수
async function callRewardEdgeFunction(userId: string, rewardAmount: number, rewardType: string, adNetwork: string, transaction_id: string): Promise<{
    success: boolean,
    message: string
}> {
    const supabaseClient = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    );

    try {
        const {data, error} = await supabaseClient.functions.invoke(`process-ads-reward?user_id=${userId}&reward_amount=${rewardAmount}&reward_type=${rewardType}&ad_network=${adNetwork}&transaction_id=${transaction_id}`, {
        });

        if (error) throw error;

        return data as { success: boolean, message: string };
    } catch (error) {
        console.error('Error calling reward edge function:', error);
        throw error;
    }
}

Deno.serve(async (req) => {
    try {
        const authHeader = req.headers.get('Authorization');

        if (!authHeader) {
            return new Response(JSON.stringify({
                error: 'No authorization header'
            }), {
                status: 401,
                headers: {
                    "Content-Type": "application/json"
                }
            });
        }
        const token = authHeader.split(' ')[1];
        const [_header, payload] = decode(token);
        const user_id = payload.sub;
        if (!user_id) {
            return new Response(JSON.stringify({
                error: 'Invalid token'
            }), {
                status: 401,
                headers: {
                    "Content-Type": "application/json"
                }
            });
        }

        const reward_amount = 1;
        const transaction_id = 'transaction_id';
        const reward_type = 'free_charge_station';
        const signature = 'signature';
        const ad_network = 'unity';
        const key_id = 'key_id';

        // 보상 처리 엣지 함수 호출
        const rewardResult = await callRewardEdgeFunction(user_id, reward_amount, reward_type, ad_network,transaction_id);

        // 보상 처리 결과를 응답으로 반환
        return new Response(
            JSON.stringify(rewardResult),
            {headers: {"Content-Type": "application/json"}},
        )
    } catch (error) {
        console.error('Unhandled error', error);
        return new Response(JSON.stringify({
            error: error.stack

        }), {
            headers: {
                'Content-Type': 'application/json'
            },
            status: 500
        });
    }
})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/reward-unity'    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsImtpZCI6IlBONWQwS1RhS2J2RDFwcUQiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3h0aWp0ZWZjeWNvZXFsdWRsbmdjLnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiIyNDdlNzA1MC1lMDQ4LTRkMGQtODQzZC1iYjdhNzQ5M2RhMmEiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzI1ODE0Njc5LCJpYXQiOjE3MjU4MTEwNzksImVtYWlsIjoiY2hhcmxpZS5oeXVuQGtha2FvLmNvbSIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoia2FrYW8iLCJwcm92aWRlcnMiOlsia2FrYW8iXX0sInVzZXJfbWV0YWRhdGEiOnsiZW1haWwiOiJjaGFybGllLmh5dW5Aa2FrYW8uY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlzcyI6Imh0dHBzOi8va2F1dGgua2FrYW8uY29tIiwibmFtZSI6IkNoYXJsaWUiLCJwaG9uZV92ZXJpZmllZCI6ZmFsc2UsInBpY3R1cmUiOiJodHRwczovL2sua2FrYW9jZG4ubmV0L2RuL200a2lkL2J0c3A5cEFjMXY5L0VjOGl3bHkxejdZY0xMNWFPaTExMTEvaW1nXzExMHgxMTAuanBnIiwicHJlZmVycmVkX3VzZXJuYW1lIjoiQ2hhcmxpZSIsInByb3ZpZGVyX2lkIjoiMzQ5MzA5NjA0MyIsInN1YiI6IjM0OTMwOTYwNDMifSwicm9sZSI6ImF1dGhlbnRpY2F0ZWQiLCJhYWwiOiJhYWwxIiwiYW1yIjpbeyJtZXRob2QiOiJvYXV0aCIsInRpbWVzdGFtcCI6MTcyNTgxMTA3OX1dLCJzZXNzaW9uX2lkIjoiN2U2MzBlZmQtZGQ3MC00ODA3LWI4ZjEtNTA3OTNiNTg0NWY2IiwiaXNfYW5vbnltb3VzIjpmYWxzZX0.K5GZb-p_5XnMmQ1VFvm1JVdUvnposTtPTRBDcMyY2PE'  --header 'Content-Type: application/json' --data '{"name":"Functions"}'

*/
