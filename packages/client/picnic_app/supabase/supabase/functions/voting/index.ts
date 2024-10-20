import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

function createSupabaseClient(req) {
    return createClient(supabaseUrl, supabaseServiceRoleKey, {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    });
}

async function getUserProfiles(supabaseClient, user_id) {
    try {
        console.log('Fetching user profiles:', user_id);
        const { data: user_profiles, error } = await supabaseClient
            .from('user_profiles')
            .select('id, star_candy, star_candy_bonus')
            .eq('id', user_id)
            .single();
        if (error) throw error;
        return { user_profiles, error: null };
    } catch (error) {
        console.error('Error fetching user profiles:', error);
        return { user_profiles: null, error };
    }
}

async function canVote(supabaseClient, user_id, vote_amount) {
    try {
        const { data: user, error } = await supabaseClient
            .from('user_profiles')
            .select('star_candy, star_candy_bonus')
            .eq('id', user_id)
            .single();

        if (error) throw error;
        if (!user) throw new Error('User not found');

        const { star_candy, star_candy_bonus } = user;
        const totalStarCandy = star_candy + star_candy_bonus;

        if (totalStarCandy < vote_amount || vote_amount <= 0) {
            return false;
        }

        let remainingAmount = vote_amount;
        if (star_candy_bonus > 0) {
            const { data: bonusRows, error: bonusError } = await supabaseClient
                .from('star_candy_bonus_history')
                .select('id, remain_amount')
                .eq('user_id', user_id)
                .gt('expired_dt', 'now()')
                .gt('remain_amount', 0)
                .order('created_at', { ascending: true });

            if (bonusError) throw bonusError;

            for (const bonusRow of bonusRows) {
                const { remain_amount: bonusAmount } = bonusRow;
                if (remainingAmount <= 0) break;
                if (bonusAmount >= remainingAmount) {
                    remainingAmount = 0;
                } else {
                    remainingAmount -= bonusAmount;
                }
            }
        }

        return remainingAmount <= star_candy;
    } catch (error) {
        console.error('Error in canVote function:', error);
        throw error;
    }
}

async function deductStarCandy(supabaseClient, user_id, amount, vote_pick_id) {
    const { data, error } = await supabaseClient.rpc('deduct_star_candy', {
        p_user_id: user_id,
        p_amount: amount,
        p_vote_pick_id: vote_pick_id
    });

    if (error) throw error;
    return data;
}

async function deductStarCandyBonus(supabaseClient, user_id, amount, bonusId, vote_pick_id) {
    const { data, error } = await supabaseClient.rpc('deduct_star_candy_bonus', {
        p_user_id: user_id,
        p_amount: amount,
        p_bonus_id: bonusId,
        p_vote_pick_id: vote_pick_id
    });

    if (error) throw error;
    return data;
}

async function performVoteDeduction(supabaseClient, user_id, vote_amount, vote_pick_id) {
    try {
        const { data: user, error: userError } = await supabaseClient
            .from('user_profiles')
            .select('star_candy, star_candy_bonus')
            .eq('id', user_id)
            .single();

        if (userError) throw userError;
        if (!user) throw new Error('User not found');

        const { star_candy, star_candy_bonus } = user;
        let remainingAmount = vote_amount;

        if (star_candy_bonus > 0) {
            const { data: bonusRows, error: bonusError } = await supabaseClient
                .from('star_candy_bonus_history')
                .select('id, remain_amount')
                .eq('user_id', user_id)
                .gt('expired_dt', 'now()')
                .gt('remain_amount', 0)
                .order('created_at', { ascending: true });

            if (bonusError) throw bonusError;

            for (const bonusRow of bonusRows) {
                const { id: bonusId, remain_amount: bonusAmount } = bonusRow;
                if (remainingAmount <= 0) break;
                if (bonusAmount >= remainingAmount) {
                    await deductStarCandyBonus(supabaseClient, user_id, remainingAmount, bonusId, vote_pick_id);
                    remainingAmount = 0;
                } else {
                    await deductStarCandyBonus(supabaseClient, user_id, bonusAmount, bonusId, vote_pick_id);
                    remainingAmount -= bonusAmount;
                }
            }
        }

        if (remainingAmount > 0) {
            await deductStarCandy(supabaseClient, user_id, remainingAmount, vote_pick_id);
        }

        return true;
    } catch (error) {
        console.error('Error in performVoteDeduction function:', error);
        throw error;
    }
}

async function isVoteOpen(supabaseClient, vote_id) {
    const { data, error } = await supabaseClient
        .from('vote')
        .select('stop_at')
        .eq('id', vote_id)
        .single();

    if (error) throw error;
    if (!data) throw new Error('Vote not found');

    const { stop_at } = data;
    const currentTime = new Date();
    console.log('stop_at:', stop_at);
    console.log('Current time:', currentTime);

    return currentTime < new Date(stop_at);
}

async function performTransaction(supabaseClient, vote_id, vote_item_id, amount, user_id) {
    const { data, error } = await supabaseClient.rpc('perform_vote_transaction', {
        p_vote_id: vote_id,
        p_vote_item_id: vote_item_id,
        p_amount: amount,
        p_user_id: user_id
    });

    if (error) throw error;
    return data;
}

Deno.serve(async (req) => {
    const supabaseClient = createSupabaseClient(req);

    try {
        const { vote_id, vote_item_id, amount, user_id } = await req.json();
        console.log('Request data:', { vote_id, vote_item_id, amount, user_id });

        const { data, error } = await supabaseClient.rpc('perform_vote_transaction', {
            p_vote_id: vote_id,
            p_vote_item_id: vote_item_id,
            p_amount: amount,
            p_user_id: user_id
        });

        if (error) throw error;

        return new Response(JSON.stringify(data), {
            headers: { 'Content-Type': 'application/json' },
            status: 200
        });
    } catch (error) {
        console.error('Error details:', error);
        return new Response(JSON.stringify({ error: error.message || 'Unexpected error occurred' }), {
            headers: { 'Content-Type': 'application/json' },
            status: 500
        });
    }
});
