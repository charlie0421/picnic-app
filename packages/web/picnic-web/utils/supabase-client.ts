'use client';

import { createBrowserClient } from '@supabase/ssr';
import { AuthChangeEvent, Session } from '@supabase/supabase-js';

// 전역 Supabase 클라이언트 인스턴스 직접 생성
export const supabase = createBrowserClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  {
    auth: {
      flowType: 'pkce',
      // 자동으로 URL에서 세션 정보 감지 - 항상 활성화
      detectSessionInUrl: true,
      autoRefreshToken: true,
      persistSession: true,
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

// 인증 상태 변경 리스너 추가
supabase.auth.onAuthStateChange((event: AuthChangeEvent, session: Session | null) => {
  console.log('Supabase 인증 상태 변경:', event, !!session);
  
  // 세션이 생성되었을 때 로컬 스토리지에 저장
  if (event === 'SIGNED_IN' && session) {
    try {
      localStorage.setItem('auth_success', 'true');
      localStorage.setItem('auth_provider', session.user?.app_metadata?.provider || 'unknown');
      localStorage.setItem('auth_timestamp', Date.now().toString());
    } catch (e) {
      console.warn('로컬 스토리지 저장 오류:', e);
    }
  }
}); 