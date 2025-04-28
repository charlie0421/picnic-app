import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function createClient() {
    const cookieStore = await cookies();

    return createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
            cookies: {
                async get(name: string) {
                    const cookie = await cookieStore.get(name);
                    return cookie?.value;
                },
                async set(name: string, value: string, options: any) {
                    try {
                        await cookieStore.set({ name, value, ...options });
                    } catch (error) {
                        // 쿠키 설정 실패 시 무시
                    }
                },
                async remove(name: string, options: any) {
                    try {
                        await cookieStore.delete({ name, ...options });
                    } catch (error) {
                        // 쿠키 삭제 실패 시 무시
                    }
                },
            },
        }
    );
} 