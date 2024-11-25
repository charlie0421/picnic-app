// lib/database.ts

import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js';

let supabaseInstance: SupabaseClient | null = null;

export function getSupabaseClient(): SupabaseClient {
    if (!supabaseInstance) {
        const supabaseUrl = Deno.env.get('SUPABASE_URL');
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

        if (!supabaseUrl || !supabaseKey) {
            throw new Error('Missing Supabase credentials');
        }

        supabaseInstance = createClient(supabaseUrl, supabaseKey, {
            auth: {
                autoRefreshToken: false,
                persistSession: false,
            },
        });
    }

    return supabaseInstance;
}

export async function closeSupabaseConnection(): Promise<void> {
    if (supabaseInstance) {
        await supabaseInstance.auth.signOut();
        supabaseInstance = null;
    }
}

export function generateUUID(): string {
    return crypto.randomUUID();
}
