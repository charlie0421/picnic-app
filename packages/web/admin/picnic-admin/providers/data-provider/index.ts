'use client';

import { dataProvider as dataProviderSupabase } from '@refinedev/supabase';
import { supabaseBrowserClient } from '@/lib/supabase/client';

export const dataProvider = dataProviderSupabase(supabaseBrowserClient);
