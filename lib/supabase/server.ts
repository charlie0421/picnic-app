import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { Database } from '@/types/supabase';

// 쿠키 저장소 인터페이스
interface CookieStore {
  get(name: string): { name: string; value: string } | undefined;
  set(cookie: { name: string; value: string; [key: string]: any }): void;
}

/**
 * pages 라우터와 app 라우터 모두에서 사용할 수 있는 서버 Supabase 클라이언트 생성 함수
 * 
 * @param cookieStore 쿠키 저장소 (headers API 또는 req/res 객체)
 * @returns Supabase 클라이언트
 */
export function createServerSupabaseClientWithCookies(cookieStore: CookieStore) {
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

// 페이지 라우터용 임시 해결책 - 빈 쿠키 스토어로 인증 없는 클라이언트 생성
const emptyCookieStore: CookieStore = {
  get: () => undefined,
  set: () => {}
};

/**
 * 기본 서버 Supabase 클라이언트를 생성합니다.
 * 이 구현은 App Router와 Pages Router 모두에서 동작하지만 Pages Router에서는 인증 없는 기본 클라이언트만 제공합니다.
 * 
 * 중요: Pages Router에서는 createServerSupabaseClientWithRequest 함수를 대신 사용하세요.
 * 
 * @returns Supabase 클라이언트 인스턴스
 */
export function createServerSupabaseClient() {
  return createServerSupabaseClientWithCookies(emptyCookieStore);
}

/**
 * Pages Router에서 사용할 Supabase 클라이언트를 생성합니다.
 * req/res 객체를 통해 쿠키를 관리합니다.
 * 
 * @param req Next.js 요청 객체
 * @param res Next.js 응답 객체
 * @returns Supabase 클라이언트
 */
export function createServerSupabaseClientWithRequest(req: any, res: any) {
  // req/res 객체를 사용하여 쿠키 저장소 생성
  const cookieStore: CookieStore = {
    get: (name) => {
      const cookies = req.cookies;
      const value = cookies[name];
      return value ? { name, value } : undefined;
    },
    set: (cookie) => {
      const { name, value, maxAge, domain, path, sameSite, secure } = cookie;
      const cookieOptions = {
        maxAge: maxAge || 0,
        domain,
        path: path || '/',
        sameSite: sameSite || 'lax',
        secure: secure || false,
        httpOnly: true
      };
      
      res.setHeader('Set-Cookie', `${name}=${value}; ${Object.entries(cookieOptions)
        .filter(([_, v]) => v !== undefined)
        .map(([k, v]) => {
          if (k === 'httpOnly' || k === 'secure') return v ? k : '';
          if (k === 'maxAge') return v ? `Max-Age=${v}` : '';
          return `${k.charAt(0).toUpperCase() + k.slice(1)}=${v}`;
        })
        .filter(Boolean)
        .join('; ')}`);
    }
  };
  
  return createServerSupabaseClientWithCookies(cookieStore);
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