import { createClient } from '@supabase/supabase-js';

let supabase: ReturnType<typeof createClient>;

if (typeof window !== 'undefined') {
  const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  
  console.log(supabaseUrl);
  console.log(supabaseAnonKey);
  supabase = createClient(supabaseUrl, supabaseAnonKey);
} else {
  // 서버 사이드에서는 더미 객체를 생성하거나 필요에 따라 처리
  supabase = {} as ReturnType<typeof createClient>;
}

export { supabase };
