import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { Pool } from 'https://deno.land/x/postgres@v0.17.0/mod.ts';

const databaseUrl = Deno.env.get('SUPABASE_DB_URL');
const pool = new Pool(databaseUrl, 3, true);

async function queryDatabase(query, ...args) {
  const client = await pool.connect();
  try {
    const result = await client.queryObject(query, args);
    console.log('Query executed:', { query, args, result });
    return result;
  } catch (error) {
    console.error('Error executing query:', { query, args, error });
    throw error;
  } finally {
    client.release();
  }
}

async function getUserProfiles(supabaseClient, user_id) {
  try {
    console.log('Fetching user profiles:', user_id);
    const { data: user_profiles, error } = await supabaseClient
        .from('user_profiles')
        .select('id, star_candy, star_candy_bonus')
        .eq('id', user_id);
    if (error) {
      console.error('Error fetching user profiles:', error);
      throw error;
    }
    return { user_profiles, error: null };
  } catch (error) {
    return { user_profiles: null, error };
  }
}

async function canVote(user_id, vote_amount) {
  try {
    const { rows } = await queryDatabase(`
      SELECT id, star_candy, star_candy_bonus
      FROM user_profiles
      WHERE id = $1
    `, user_id);

    if (rows.length === 0) {
      throw new Error('User not found');
    }

    const { star_candy, star_candy_bonus } = rows[0];
    const totalStarCandy = star_candy + star_candy_bonus;

    if (totalStarCandy < vote_amount || vote_amount <= 0) {
      return false;
    }

    let remainingAmount = vote_amount;
    if (star_candy_bonus > 0) {
      const { rows: bonusRows } = await queryDatabase(`
        SELECT id, remain_amount
        FROM star_candy_bonus_history
        WHERE user_id = $1
          AND expired_dt > NOW()
          AND remain_amount > 0
        ORDER BY created_at ASC
      `, user_id);

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

async function deductStarCandy(user_id, amount, vote_pick_id) {
  const { rows } = await queryDatabase(`
    SELECT id, star_candy
    FROM user_profiles
    WHERE id = $1
  `, user_id);

  if (rows.length === 0) {
    throw new Error('User not found');
  }

  const { id, star_candy } = rows[0];

  await queryDatabase(`
    INSERT INTO star_candy_history (type, user_id, amount, vote_pick_id)
    VALUES ('VOTE', $1, $2, $3)
  `, user_id, amount, vote_pick_id);

  await queryDatabase(`
    UPDATE user_profiles
    SET star_candy = GREATEST(star_candy - $1, 0)
    WHERE id = $2
  `, amount, id);
}

async function deductStarCandyBonus(user_id, amount, bonusId, vote_pick_id) {
  await queryDatabase(`
    UPDATE star_candy_bonus_history
    SET remain_amount = GREATEST(remain_amount - $1, 0),
        updated_at = NOW()
    WHERE id = $2
  `, amount, bonusId);

  await queryDatabase(`
    INSERT INTO star_candy_bonus_history (user_id, amount, remain_amount, parent_id, vote_pick_id)
    VALUES ($1, $2, $3, $4, $5)
  `, user_id, amount, amount, bonusId, vote_pick_id);

  await queryDatabase(`
    UPDATE user_profiles
    SET star_candy_bonus = GREATEST(star_candy_bonus - $1, 0)
    WHERE id = $2
  `, amount, user_id);
}

async function performVoteDeduction(user_id, vote_amount, vote_pick_id) {
  try {
    const { rows } = await queryDatabase(`
      SELECT id, star_candy, star_candy_bonus
      FROM user_profiles
      WHERE id = $1
    `, user_id);

    if (rows.length === 0) {
      throw new Error('User not found');
    }

    const { star_candy, star_candy_bonus } = rows[0];
    let remainingAmount = vote_amount;

    if (star_candy_bonus > 0) {
      const { rows: bonusRows } = await queryDatabase(`
        SELECT id, remain_amount
        FROM star_candy_bonus_history
        WHERE user_id = $1
          AND expired_dt > NOW()
          AND remain_amount > 0
        ORDER BY created_at ASC
      `, user_id);

      for (const bonusRow of bonusRows) {
        const { id: bonusId, remain_amount: bonusAmount } = bonusRow;
        if (remainingAmount <= 0) break;
        if (bonusAmount >= remainingAmount) {
          await deductStarCandyBonus(user_id, remainingAmount, bonusId, vote_pick_id);
          remainingAmount = 0;
        } else {
          await deductStarCandyBonus(user_id, bonusAmount, bonusId, vote_pick_id);
          remainingAmount -= bonusAmount;
        }
      }
    }

    if (remainingAmount > 0) {
      await deductStarCandy(user_id, remainingAmount, vote_pick_id);
    }

    return true;
  } catch (error) {
    console.error('Error in performVoteDeduction function:', error);
    throw error;
  }
}

async function performTransaction(connection, vote_id, vote_item_id, amount, user_id) {
  await connection.queryObject('BEGIN');
  try {
    const voteTotalResult = await queryDatabase(`
      SELECT vote_total
      FROM vote_item
      WHERE id = $1
    `, vote_item_id);
    const existingVoteTotal = voteTotalResult.rows.length > 0 ? voteTotalResult.rows[0].vote_total : 0;

    const canVoteResult = await canVote(user_id, amount);
    if (!canVoteResult) {
      throw new Error('Insufficient star_candy and star_candy_bonus to vote');
    }

    const votePickResult = await queryDatabase(`
      INSERT INTO vote_pick (vote_id, vote_item_id, amount, user_id)
      VALUES ($1, $2, $3, $4) RETURNING id
    `, vote_id, vote_item_id, amount, user_id);
    const vote_pick_id = votePickResult.rows[0].id;

    await performVoteDeduction(user_id, amount, vote_pick_id);

    await connection.queryObject('COMMIT');
    connection.release();
    return {
      existingVoteTotal: existingVoteTotal,
      addedVoteTotal: amount,
      updatedVoteTotal: existingVoteTotal + amount,
      updatedAt: new Date().toISOString()
    };
  } catch (error) {
    await connection.queryObject('ROLLBACK');
    connection.release();
    console.error('Error in performTransaction function:', error);
    throw error;
  }
}

Deno.serve(async (req) => {
  const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization') ?? '' }
        }
      }
  );

  try {
    const { vote_id, vote_item_id, amount, user_id } = await req.json();
    console.log('Request data:', { vote_id, vote_item_id, amount, user_id });

    const { user_profiles, error: userError } = await getUserProfiles(supabaseClient, user_id);
    if (userError || !user_profiles) {
      return new Response(JSON.stringify({ error: 'User not found or other error occurred' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400
      });
    }

    const connection = await pool.connect();
    try {
      const transactionResult = await performTransaction(connection, vote_id, vote_item_id, amount, user_id);
      return new Response(JSON.stringify(transactionResult), {
        headers: { 'Content-Type': 'application/json' },
        status: 200
      });
    } catch (e) {
      await connection.queryObject('ROLLBACK');
      connection.release();
      console.error('Error occurred during transaction:', e);
      throw e;
    }
  } catch (error) {
    console.error('Unexpected error occurred:', error);
    return new Response(JSON.stringify({ error: 'Unexpected error occurred' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500
    });
  }
});