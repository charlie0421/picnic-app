import {createClient} from 'https://esm.sh/@supabase/supabase-js@2';
import * as postgres from 'https://deno.land/x/postgres@v0.17.0/mod.ts';

const databaseUrl = Deno.env.get('SUPABASE_DB_URL')!;
const pool = new postgres.Pool(databaseUrl, 3, true);

Deno.serve(async (req) => {
    try {
        const {vote_id, vote_item_id, amount, user_id} = await req.json();

        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
            {global: {headers: {Authorization: req.headers.get('Authorization')!}}}
        );

        // 사용자 정보에서 star_candy 가져오기
        const {data: user_profiles, error: userError} = await supabaseClient
            .from('user_profiles')
            .select('star_candy')
            .eq('id', user_id)
            .single();

        if (userError || !user_profiles) {
            return new Response(JSON.stringify({error: 'User not found or other error occurred'}), {
                headers: {'Content-Type': 'application/json'},
                status: 400,
            });
        }

        if (amount < 0 || user_profiles.star_candy < amount) {
            return new Response(JSON.stringify({error: 'Invalid amount or insufficient star_candy'}), {
                headers: {'Content-Type': 'application/json'},
                status: 400,
            });
        }

        const connection = await pool.connect();
        try {
            await connection.queryObject('BEGIN');

            // 투표 내역 추가
            const insertVoteQuery = `INSERT INTO vote_pick (vote_id, vote_item_id, amount, user_id)
                                     VALUES ($1, $2, $3, $4)`;
            await connection.queryObject(insertVoteQuery, [vote_id, vote_item_id, amount, user_id]);

            // 기존 투표수 가져오기
            const {rows: existingVoteRows} = await connection.queryObject(
                `SELECT vote_total
                 FROM vote_item
                 WHERE id = $1`, [vote_item_id]
            );
            const existingVoteTotal = existingVoteRows.length > 0 ? existingVoteRows[0].vote_total : 0;

            // 투표수 업데이트
            const updateVoteQuery = `UPDATE vote_item
                                     SET vote_total = vote_total + $1
                                     WHERE id = $2`;
            await connection.queryObject(updateVoteQuery, [amount, vote_item_id]);

            // 사용자 포인트 차감
            const updateUserQuery = `UPDATE user_profiles
                                     SET star_candy = star_candy - $1
                                     WHERE id = $2`;
            await connection.queryObject(updateUserQuery, [amount, user_id]);

            await connection.queryObject('COMMIT');
            connection.release();

            return new Response(
                JSON.stringify({
                    existingVoteTotal,
                    addedVoteTotal: amount,
                    updatedVoteTotal: existingVoteTotal + amount,
                    updatedAt: new Date().toISOString(),
                }),
                {
                    headers: {'Content-Type': 'application/json'},
                    status: 200,
                }
            );
        } catch (e) {
            await connection.queryObject('ROLLBACK');
            connection.release();
            throw e;
        }
    } catch (error) {
        return new Response(JSON.stringify({error: error.message}), {
            headers: {'Content-Type': 'application/json'},
            status: 500,
        });
    }
});
