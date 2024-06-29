import {createClient} from 'https://esm.sh/@supabase/supabase-js@2';
import * as postgres from 'https://deno.land/x/postgres@v0.17.0/mod.ts';
import {config} from "https://deno.land/x/dotenv/mod.ts";

config(); // 환경 변수 로드

const databaseUrl = Deno.env.get('SUPABASE_DB_URL')!;
const pool = new postgres.Pool(databaseUrl, 3, true);

const secretKey = "c0bb7b4bcedf4db314aa7d0bbba4d4a784877bae45d89439ed83549798ccc923";

function base64UrlToBase64(base64Url: string): string {
    return base64Url.replace(/-/g, '+').replace(/_/g, '/').padEnd(base64Url.length + (4 - (base64Url.length % 4)) % 4, '=');
}

function safeAtob(base64: string): Uint8Array {
    try {
        return Uint8Array.from(atob(base64), c => c.charCodeAt(0));
    } catch (e) {
        console.error('Failed to decode Base64:', base64);
        throw new Error('Invalid Base64 string');
    }
}

async function verifySignature(transaction_id: string, user_id: string, reward_amount: number, signature: string, secretKey: string): Promise<boolean> {
    try {
        if (!secretKey) {
            throw new Error('Secret key is missing');
        }

        const encoder = new TextEncoder();
        const keyData = encoder.encode(secretKey);
        const data = encoder.encode(`${transaction_id}${user_id}${reward_amount}`);

        console.log('Data to be signed:', `${transaction_id}${user_id}${reward_amount}`);

        const key = await crypto.subtle.importKey(
            'raw',
            keyData,
            {name: 'HMAC', hash: 'SHA-256'},
            false,
            ['sign', 'verify']
        );

        const signatureArray = safeAtob(base64UrlToBase64(signature));

        const isValid = await crypto.subtle.verify('HMAC', key, signatureArray, data);
        console.log('Signature is valid:', isValid);

        return isValid;
    } catch (error) {
        console.error('Error during signature verification:', error);
        return false;
    }
}

Deno.serve(async (req) => {
    try {
        const url = new URL(req.url);
        const params = url.searchParams;
        const user_id = params.get('user_id');
        const reward_amount = parseInt(params.get('reward_amount') ?? '0', 10);
        const custom_data = params.get('custom_data');
        const ad_network = params.get('ad_network');
        const transaction_id = params.get('transaction_id');
        const signature = params.get('signature');
        const key_id = params.get('key_id');

        let reward_type = null;
        if (custom_data) {
            const parsedData = JSON.parse(custom_data);
            reward_type = parsedData.reward_type;
        }

        console.log('Request parameters:', {
            user_id,
            reward_amount,
            reward_type,
            ad_network,
            transaction_id,
            signature,
            key_id

        });

        if (!user_id || !reward_amount || !reward_type || !ad_network || !transaction_id || !signature || !key_id) {
            console.error('Invalid request parameters', {
                user_id,
                reward_amount,
                reward_type,
                ad_network,
                transaction_id,
                signature,
                key_id
            });
            return new Response(JSON.stringify({error: 'Invalid request'}), {
                headers: {'Content-Type': 'application/json'},
                status: 400,
            });
        }

        console.log('Verifying signature with secret key', secretKey);

        let isValid = await verifySignature(transaction_id, user_id, reward_amount, signature, secretKey);
        isValid = true; // TODO: Remove this line after testing
        if (!isValid) {
            console.error('Invalid signature', {transaction_id, user_id, reward_amount, signature});
            return new Response(JSON.stringify({error: 'Invalid signature'}), {
                headers: {'Content-Type': 'application/json'},
                status: 400,
            });
        }

        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
            {global: {headers: {Authorization: `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!}`}}}
        );

        console.log('Fetching user profile', user_id);
        const {data: user_profiles, error: userError} = await supabaseClient
            .from('user_profiles')
            .select('star_candy_bonus')
            .eq('id', user_id)
            .single();

        if (userError || !user_profiles) {
            console.error('User not found or other error occurred', userError);
            return new Response(JSON.stringify({error: 'User not found or other error occurred'}), {
                headers: {'Content-Type': 'application/json'},
                status: 400,
            });
        }

        const connection = await pool.connect();
        try {
            await connection.queryObject('BEGIN');

            console.log('Updating user rewards');
            const updateUserQuery = `UPDATE user_profiles
                                     SET star_candy_bonus = star_candy_bonus + $1
                                     WHERE id = $2`;
            await connection.queryObject(updateUserQuery, [reward_amount, user_id]);

            console.log('Inserting star_candy history');

            // 히스토리 저장
            const insertHistoryQuery: String = `INSERT INTO star_candy_bonus_history (type, amount, user_id, transaction_id)
                                                VALUES ($1, $2, $3, $4)`;
            await connection.queryObject(insertHistoryQuery, ['AD', reward_amount, user_id, transaction_id]);

            console.log('Inserting transaction');
            // 트랜잭션 저장
            const insertTransactionQuery: String = `INSERT INTO transaction_admob (transaction_id,
                                                                                   reward_type, reward_amount,
                                                                                   signature,
                                                                                   ad_network, key_id)
                                                    VALUES ($1, $2, $3, $4, $5, $6)`;
            await connection.queryObject(insertTransactionQuery, [transaction_id, reward_type, reward_amount, signature, ad_network, key_id]);


            await connection.queryObject('COMMIT');
            connection.release();

            return new Response(JSON.stringify({success: true}), {
                headers: {'Content-Type': 'application/json'},
                status: 200,
            });
        } catch (e) {
            await connection.queryObject('ROLLBACK');
            connection.release();
            console.error('Transaction failed', e);
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
``