import * as postgres from 'https://deno.land/x/postgres@v0.17.0/mod.ts';

const databaseUrl = Deno.env.get('SUPABASE_DB_URL');
const pool = new postgres.Pool(databaseUrl, 3, true);

async function queryDatabase(query, ...args) {
    const client = await pool.connect();
    console.log('queryDatabase', {
        query,
        args
    });
    try {
        const result = await client.queryObject(query, args);
        console.log('Query executed:', {
            query,
            args,
            result
        });
        return result;
    } catch (error) {
        console.error('Error executing query:', {
            query,
            args,
            error
        });
        throw error;
    } finally {
        client.release();
    }
}

function extractParameters(url) {
    console.log('url', url);
    const params = url.searchParams;
    const user_id = params.get('user_id');
    const reward_amount = parseInt(params.get('reward_amount') ?? '0', 10);
    const reward_type = params.get('reward_type');
    const ad_network = params.get('ad_network');
    const transaction_id = params.get('transaction_id');
    const signature = params.get('signature');
    const key_id = params.get('key_id');
    return {
        user_id,
        reward_amount,
        reward_type,
        ad_network,
        transaction_id,
        signature,
        key_id
    };
}

function validateParameters(params) {
    const {user_id, reward_amount, reward_type, ad_network, transaction_id} = params;

    if (!user_id  || !reward_amount || !reward_type || !ad_network || !transaction_id
    ) {
        console.error('Invalid request parameters', params);
        return false;
    }
    return true;
}

async function updateUserRewards(user_id, reward_amount) {
    console.log('Updating user rewards');
    const updateUserQuery = `UPDATE user_profiles
                             SET star_candy_bonus = star_candy_bonus + $1
                             WHERE id = $2`;
    await queryDatabase(updateUserQuery, reward_amount, user_id);
}

function getNextMonth14thAt15UTC() {
    const now = new Date();
    let nextMonth = now.getUTCMonth() + 1;
    let year = now.getUTCFullYear();

    // 12월인 경우 다음 해의 1월로 설정
    if (nextMonth > 11) {
        nextMonth = 0;
        year++;
    }

    // UTC 기준으로 다음 달 14일 15:00:00 설정
    const nextMonth14th = new Date(Date.UTC(year, nextMonth, 14, 15, 0, 0));

    // ISO 8601 형식의 문자열로 변환 (YYYY-MM-DD HH:mm:ss)
    return nextMonth14th.toISOString().replace('T', ' ').substr(0, 19);
}

async function insertStarCandyBonusHistory(user_id, reward_amount, transaction_id) {
    console.log('Inserting star_candy history');
    const expired_dt = getNextMonth14thAt15UTC();
    const insertHistoryQuery = `INSERT INTO star_candy_bonus_history (type, amount, remain_amount, user_id, transaction_id, expired_dt)
                                VALUES ($1, $2, $3, $4, $5, $6)`;
    await queryDatabase(insertHistoryQuery, 'AD', reward_amount, reward_amount, user_id, transaction_id, expired_dt);
}

async function insertTransaction(transaction_id, reward_type, reward_amount, signature, ad_network, key_id, user_id) {
    console.log('Inserting transaction');
    const insertTransactionQuery = `INSERT INTO transaction_admob (transaction_id, reward_type, reward_amount,
                                                                   signature, ad_network, key_id, user_id)
                                    VALUES ($1, $2, $3, $4, $5, $6, $7)`;
    await queryDatabase(insertTransactionQuery, transaction_id, reward_type, reward_amount, signature, ad_network, key_id, user_id);
}

async function processTransaction(user_id, reward_amount, transaction_id, reward_type, signature, ad_network, key_id) {
    const connection = await pool.connect();
    try {
        await connection.queryObject('BEGIN');
        await updateUserRewards(user_id, reward_amount);
        await insertStarCandyBonusHistory(user_id, reward_amount, transaction_id);
        await insertTransaction(transaction_id, reward_type, reward_amount, signature, ad_network, key_id, user_id);
        await connection.queryObject('COMMIT');
        connection.release();
    } catch (e) {
        await connection.queryObject('ROLLBACK');
        connection.release();
        console.error('Transaction failed', e);
        throw e;
    }
}

async function handleRequest(req) {
    try {
        const url = new URL(req.url);
        const params = extractParameters(url);
        console.log('Received request', params);
        if (!validateParameters(params)) {
            return new Response(JSON.stringify({
                error: 'Invalid request'
            }), {
                headers: {
                    'Content-Type': 'application/json'
                },
                status: 400
            });
        }

        await processTransaction(params.user_id, params.reward_amount, params.transaction_id, params.reward_type, params.signature, params.ad_network, params.key_id);
        return new Response(JSON.stringify({
            success: true
        }), {
            headers: {
                'Content-Type': 'application/json'
            },
            status: 200
        });
    } catch (error) {
        console.error('Unhandled error', error);
        return new Response(JSON.stringify({
            error: error.message
        }), {
            headers: {
                'Content-Type': 'application/json'
            },
            status: 500
        });
    }
}

Deno.serve(handleRequest);
