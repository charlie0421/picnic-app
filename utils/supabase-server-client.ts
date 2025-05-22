import {createServerClient} from '@supabase/ssr';
import {cookies} from 'next/headers';
import { cache } from 'react';

// createClient 함수를 캐싱하여 동일한 요청 내에서 재사용
export const createClient = cache(() => {
  const cookieStore = cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value;
        },
        set(name: string, value: string, options: any) {
          cookieStore.set({ name, value, ...options });
        },
        remove(name: string, options: any) {
          cookieStore.set({ name, value: '', ...options });
        },
      },
    }
  );
});

// 서버 컴포넌트에서 사용할 수 있는 캐싱 포함 Supabase 클라이언트
export const createServerComponentClient = cache(() => {
  return createClient();
});
