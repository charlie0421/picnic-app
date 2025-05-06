'use client';

import { createBrowserClient } from '@supabase/ssr';

let supabaseClient: ReturnType<typeof createBrowserClient> | null = null;

export const createBrowserSupabaseClient = () => {
  if (supabaseClient) {
    return supabaseClient;
  }

  // PKCE 흐름을 사용하기 위한 설정
  supabaseClient = createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      auth: {
        flowType: 'pkce',
        // 자동으로 URL에서 세션 정보 감지
        detectSessionInUrl: true,
        // 로컬 스토리지 대신 쿠키도 지원하는 스토리지 설정
        storage: {
          getItem: (key) => {
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
          setItem: (key, value) => {
            try {
              // 로컬 스토리지에 저장
              globalThis.localStorage?.setItem(key, value);
              
              // 쿠키에도 저장
              const date = new Date();
              date.setTime(date.getTime() + 8 * 60 * 60 * 1000); // 8시간 유효
              document.cookie = `${key}=${encodeURIComponent(value)}; expires=${date.toUTCString()}; path=/`;
            } catch (e) {
              console.warn('스토리지 저장 오류:', e);
            }
          },
          removeItem: (key) => {
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
      }
    }
  );

  return supabaseClient;
};

// 전역 Supabase 클라이언트 인스턴스
export const supabase = createBrowserSupabaseClient(); 