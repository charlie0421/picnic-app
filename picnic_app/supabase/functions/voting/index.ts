import {createClient} from 'https://esm.sh/@supabase/supabase-js@2';
import * as postgres from 'https://deno.land/x/postgres@v0.17.0/mod.ts';

const databaseUrl = Deno.env.get('SUPABASE_DB_URL')!;
const pool = new postgres.Pool(databaseUrl, 3, true);

Deno.serve(async (req) => {
    try {
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
            {global: {headers: {Authorization: req.headers.get('Authorization')!}}}
        );

        const {
            vote_id,
            vote_item_id,
            amount,
            user_id,
        } = await req.json();

        console.log('Request data:', {vote_id, vote_item_id, amount, user_id});


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
            const insertVoteQuery: String = `INSERT INTO vote_pick (vote_id, vote_item_id, amount, user_id)
                                             VALUES ($1, $2, $3, $4) RETURNING id`;
            const vote_pick = await connection.queryObject(insertVoteQuery, [vote_id, vote_item_id, amount, user_id]);
            console.log(vote_pick);
            let vote_pick_id;
            if (vote_pick.rows.length > 0) {
                vote_pick_id = vote_pick.rows[0].id;
            } else {
                // Handle the case where no rows were inserted
                console.error('No rows were inserted');
            }
            // 기존 투표수 가져오기
            const {rows: existingVoteRows} = await connection.queryObject(
                `SELECT vote_total
                 FROM vote_item
                 WHERE id = $1`, [vote_item_id]
            );
            const existingVoteTotal = existingVoteRows.length > 0 ? existingVoteRows[0].vote_total : 0;

            // 투표수 업데이트
            console.log('Updating vote total');
            const updateVoteQuery: String = `UPDATE vote_item
                                             SET vote_total = vote_total + $1
                                             WHERE id = $2`;
            await connection.queryObject(updateVoteQuery, [amount, vote_item_id]);

            // 사용자 포인트 차감
            console.log('Updating user rewards');
            const updateUserQuery: String = `UPDATE user_profiles
                                             SET star_candy = star_candy - $1
                                             WHERE id = $2`;
            await connection.queryObject(updateUserQuery, [amount, user_id]);

            // 히스토리 저장
            console.log('Inserting star_candy history');
            const insertHistoryQuery: String = `INSERT INTO star_candy_history (type, user_id, amount, vote_pick_id)
                                                VALUES ($1, $2, $3, $4)`;
            await connection.queryObject(insertHistoryQuery, ['VOTE', user_id, amount, vote_pick_id]);


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
        console.error('Unhandled error', error);
        return new Response(JSON.stringify({error: error.message}), {
            headers: {'Content-Type': 'application/json'},
            status: 500,
        });
    }
});
