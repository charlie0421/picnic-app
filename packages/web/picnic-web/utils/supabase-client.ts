'use client';

import {createBrowserClient} from '@supabase/ssr';
import {AuthChangeEvent, Session} from '@supabase/supabase-js';

// ngrok 환경 감지 (브라우저에서만 실행)
const isNgrokEnvironment = typeof window !== 'undefined' && (
  window.location.hostname.includes('ngrok') ||
  /^[a-z0-9]+\.ngrok(?:-free)?\.(?:io|app)$/.test(window.location.hostname)
);

// 배포 환경인지 확인
const isProduction = process.env.NODE_ENV === 'production';

// 현재 언어 경로 감지
const getCurrentLangPath = (): string => {
  if (typeof window === 'undefined') return '';

  // URL 경로를 분석하여 언어 부분 추출
  const pathname = window.location.pathname;
  const match = pathname.match(/^\/([a-z]{2})(\/|$)/);

  // 매치되면 해당 언어 경로 반환, 없으면 빈 문자열 반환
  return match ? `/${match[1]}` : '';
};

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
    },
  }
);

// 초기화 시 로그
if (typeof window !== 'undefined') {
  console.log('Supabase 클라이언트 초기화 완료', {
    url: process.env.NEXT_PUBLIC_SUPABASE_URL,
    originalUrl: process.env.NEXT_PUBLIC_SUPABASE_URL,
    isNgrok: isNgrokEnvironment,
    isProduction,
    hostname: window.location.hostname,
    langPath: getCurrentLangPath()
  });
}

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
