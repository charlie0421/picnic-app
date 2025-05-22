'use client';

import { createBrowserClient } from '@supabase/ssr';
import { Database } from '@/types/supabase';

// 브라우저 클라이언트 타입을 미리 정의
type BrowserSupabaseClient = ReturnType<typeof createBrowserClient<Database>>;

let browserSupabase: BrowserSupabaseClient | null = null;

/**
 * 브라우저 환경에서 사용할 Supabase 클라이언트를 생성합니다.
 * 싱글톤 패턴을 사용하여 단일 인스턴스를 생성하고 재사용합니다.
 * 
 * 이 함수는 클라이언트 컴포넌트에서만 사용해야 합니다.
 * 
 * @returns Supabase 클라이언트 인스턴스
 */
export function createBrowserSupabaseClient(): BrowserSupabaseClient {
  if (browserSupabase) {
    return browserSupabase;
  }

  // ngrok 환경 감지 (브라우저에서만 실행)
  const isNgrokEnvironment = typeof window !== 'undefined' && (
    window.location.hostname.includes('ngrok') ||
    /^[a-z0-9]+\.ngrok(?:-free)?\.(?:io|app)$/.test(window.location.hostname)
  );

  if (!process.env.NEXT_PUBLIC_SUPABASE_URL) {
    throw new Error('환경 변수 NEXT_PUBLIC_SUPABASE_URL이 설정되지 않았습니다.');
  }
  
  if (!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    throw new Error('환경 변수 NEXT_PUBLIC_SUPABASE_ANON_KEY가 설정되지 않았습니다.');
  }

  browserSupabase = createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      auth: {
        flowType: 'pkce',
        detectSessionInUrl: true,
        autoRefreshToken: true,
        persistSession: true,
        storage: {
          getItem: (key: string) => {
            // 먼저 로컬 스토리지에서 시도
            const localValue = globalThis.localStorage?.getItem(key) ?? null;
            if (localValue) return localValue;

            // 쿠키에서 시도 (ngrok 환경에서 더 안정적일 수 있음)
            const cookies = document.cookie.split('; ');
            for (const cookie of cookies) {
              const [cookieName, cookieValue] = cookie.split('=');
              if (cookieName === key) return decodeURIComponent(cookieValue);
            }
            return null;
          },
          setItem: (key: string, value: string) => {
            try {
              // 로컬 스토리지에 저장
              globalThis.localStorage?.setItem(key, value);

              // 쿠키에도 저장 (ngrok 환경에서는 SameSite=None 추가)
              const date = new Date();
              date.setTime(date.getTime() + 8 * 60 * 60 * 1000); // 8시간 유효
              const cookieOptions = isNgrokEnvironment ?
                `; expires=${date.toUTCString()}; path=/; SameSite=None; Secure` :
                `; expires=${date.toUTCString()}; path=/`;
              document.cookie = `${key}=${encodeURIComponent(value)}${cookieOptions}`;
            } catch (e) {
              console.warn('스토리지 저장 오류:', e);
            }
          },
          removeItem: (key: string) => {
            try {
              // 로컬 스토리지에서 제거
              globalThis.localStorage?.removeItem(key);

              // 쿠키에서도 제거
              document.cookie = `${key}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
            } catch (e) {
              console.warn('스토리지 제거 오류:', e);
            }
          }
        }
      },
    }
  );

  // 디버그 로그 (개발 환경에서만)
  if (process.env.NODE_ENV !== 'production' && typeof window !== 'undefined') {
    console.log('브라우저 Supabase 클라이언트 초기화 완료', {
      url: process.env.NEXT_PUBLIC_SUPABASE_URL,
      isNgrok: isNgrokEnvironment,
      hostname: window.location.hostname
    });
  }

  return browserSupabase;
}

/**
 * 현재 인증 사용자를 가져오는 편의 함수입니다.
 * 
 * @returns 현재 인증된 사용자 또는 null
 */
export async function getCurrentUser() {
  const supabase = createBrowserSupabaseClient();
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

/**
 * 현재 인증 세션을 가져오는 편의 함수입니다.
 * 
 * @returns 현재 인증 세션 또는 null
 */
export async function getCurrentSession() {
  const supabase = createBrowserSupabaseClient();
  const { data: { session } } = await supabase.auth.getSession();
  return session;
}

/**
 * 로그아웃 처리 함수입니다.
 * 모든 세션을 제거하고 스토리지를 정리합니다.
 * 
 * @returns 로그아웃 결과
 */
export async function signOut() {
  const supabase = createBrowserSupabaseClient();
  
  try {
    // 모든 세션 제거
    const { error } = await supabase.auth.signOut({
      scope: 'global'
    });

    // 로컬 스토리지에서 인증 관련 항목 제거
    try {
      localStorage.removeItem('auth_session_active');
      localStorage.removeItem('auth_provider');
    } catch (e) {
      // 로컬 스토리지 오류 무시
    }

    if (error) throw error;
    return { success: true };
  } catch (error) {
    console.error('로그아웃 중 오류 발생:', error);
    return { success: false, error };
  }
} 