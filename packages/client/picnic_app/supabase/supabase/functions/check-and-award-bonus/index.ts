// supabase/functions/check-and-award-bonus/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const { votePickId, userId } = await req.json()

        console.log(votePickId)
        console.log(userId)

        const supabaseAdmin = createClient(
            Deno.env.get('SUPABASE_URL')!,
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        )

        // Check vote amount
        const { data: voteData, error: voteError } = await supabaseAdmin
            .from('vote_pick')
            .select('amount')
            .eq('id', votePickId)
            .eq('user_id', userId)
            .single()

        console.log(voteData)
        console.log(voteError)

        if (voteError || !voteData || voteData.amount < 100) {
            return new Response(
                JSON.stringify({ error: 'Not enough votes' }),
                { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
            )
        }

        // Check existing bonus
        const { data: existingBonus } = await supabaseAdmin
            .from('star_candy_bonus_history')
            .select('id')
            .eq('vote_pick_id', votePickId)
            .eq('user_id', userId)
            .eq('type', 'VOTE_SHARE_BONUS')
            .maybeSingle()

        if (existingBonus) {
            return new Response(
                JSON.stringify({ error: 'Bonus already awarded' }),
                { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
            )
        }

        // Award bonus
        const expiredDt = new Date()
        expiredDt.setDate(expiredDt.getDate() + 30)

        const { error: insertError } = await supabaseAdmin
            .from('star_candy_bonus_history')
            .insert({
                user_id: userId,
                amount: 1,
                type: 'VOTE_SHARE_BONUS',
                expired_dt: expiredDt.toISOString(),
                vote_pick_id: votePickId,
                remain_amount: 1,
                transaction_id: `vote_share_${votePickId}_${Date.now()}`
            })

        if (insertError) throw insertError

        const { error: updateError } = await supabaseAdmin.rpc(
            'increment_user_star_candy_bonus',
            { p_user_id: userId, p_amount: 1 }
        )

        if (updateError) throw updateError


        return new Response(
            JSON.stringify({ success: true }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
        )
    }
})
