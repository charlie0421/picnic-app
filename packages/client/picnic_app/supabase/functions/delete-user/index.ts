import { serve } from 'https://deno.land/std@0.140.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { decode, verify } from "https://deno.land/x/djwt@v3.0.2/mod.ts";
import jwt from 'https://esm.sh/jsonwebtoken@8.5.1';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const jwtSecret = Deno.env.get('MY_SUPABASE_JWT_SECRET') ?? '';
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

serve(async (req) => {
  try {
    const { userId } = await req.json();
    const authHeader = req.headers.get('Authorization');

    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Authorization header is missing' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const token = authHeader.split(' ')[1];

    // Verify the JWT token
    console.log('Verifying token with secret key', jwtSecret);
    console.log('Token:', token);
    let payload;
    try {
      payload = jwt.verify(token, jwtSecret);
    } catch (err) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    console.log('Payload:', payload);

    if (payload.sub !== userId) {
        console.error('Unauthorized user');
      return new Response(JSON.stringify({ error: 'Unauthorized user' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (!userId) {
      console.error('User ID is required');
      return new Response(JSON.stringify({ error: 'User ID is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const deletedAt = new Date().toISOString();

    const { error: updateError } = await supabase
        .from('auth.users')
        .update({ deleted_at: deletedAt })
        .eq('id', userId);

    if (updateError) {
      console.error('Error updating user:', updateError);
      return new Response(JSON.stringify({ error: updateError.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Update related table user_profiles
    const { error: profileUpdateError } = await supabase
        .from('user_profiles')
        .update({ deleted_at: deletedAt })
        .eq('id', userId);

    if (profileUpdateError) {
      console.error('Error updating user profile:', profileUpdateError);
      return new Response(JSON.stringify({ error: profileUpdateError.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }


    return new Response(JSON.stringify({ message: 'User deleted successfully' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Unhandled error', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
