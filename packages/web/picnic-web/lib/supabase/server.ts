import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { Database } from '@/types/supabase';

/**
 * 서버 측에서 사용할 Supabase 클라이언트를 생성합니다.
 * 
 * 이 함수는 서버 컴포넌트, API 라우트 또는 서버 액션에서만 사용해야 합니다.
 * 쿠키를 통해 인증 상태를 유지하므로 클라이언트 컴포넌트에서는 사용하지 마세요.
 * 
 * @returns Supabase 클라이언트 인스턴스
 */
export function createServerSupabaseClient() {
  const cookieStore = cookies();
  
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL) {
    throw new Error('환경 변수 NEXT_PUBLIC_SUPABASE_URL이 설정되지 않았습니다.');
  }
  
  if (!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    throw new Error('환경 변수 NEXT_PUBLIC_SUPABASE_ANON_KEY가 설정되지 않았습니다.');
  }

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value;
        },
        set(name: string, value: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value, ...options });
          } catch (error) {
            // 쿠키 설정 실패 시 로깅 (개발 환경에서만)
            if (process.env.NODE_ENV !== 'production') {
              console.warn('서버 Supabase 클라이언트: 쿠키 설정 실패', error);
            }
          }
        },
        remove(name: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value: '', ...options, maxAge: 0 });
          } catch (error) {
            // 쿠키 삭제 실패 시 로깅 (개발 환경에서만)
            if (process.env.NODE_ENV !== 'production') {
              console.warn('서버 Supabase 클라이언트: 쿠키 삭제 실패', error);
            }
          }
        },
      },
    }
  );
}

/**
 * 서버 컴포넌트에서 현재 인증 세션을 가져옵니다.
 * @returns 현재 인증 세션 또는 null
 */
export async function getServerSession() {
  const supabase = createServerSupabaseClient();
  return await supabase.auth.getSession();
}

/**
 * 서버 컴포넌트에서 현재 사용자 정보를 가져옵니다.
 * @returns 현재 사용자 정보 또는 null
 */
export async function getServerUser() {
  const { data: { session } } = await getServerSession();
  return session?.user || null;
}

/**
 * 주어진 콜백을 인증된 사용자 컨텍스트에서 실행하는 유틸리티 함수입니다.
 * 인증되지 않은 경우 오류를 발생시킵니다.
 * 
 * @example
 * const result = await withAuth(async (userId) => {
 *   // 인증된 사용자에 대한 작업 수행
 *   return await db.users.findUnique({ where: { id: userId } });
 * });
 * 
 * @param callback 인증된 사용자 ID를 인자로 받는 콜백 함수
 * @returns 콜백 함수의 결과
 * @throws 인증되지 않은 경우 오류
 */
export async function withAuth<T>(
  callback: (userId: string) => Promise<T>
): Promise<T> {
  const { data: { session } } = await getServerSession();
  
  if (!session) {
    throw new Error('인증이 필요합니다');
  }
  
  return callback(session.user.id);
} 