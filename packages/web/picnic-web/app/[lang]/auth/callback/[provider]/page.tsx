'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { createBrowserSupabaseClient } from '@/utils/supabase-client';

// 디버깅 로그 함수
const debugLog = (message: string, data?: any) => {
  console.log(`[CALLBACK] ${message}`, data ? data : '');
  try {
    // 디버그 정보를 로컬 스토리지에 저장
    const debugLogs = JSON.parse(localStorage.getItem('callback_logs') || '[]');
    debugLogs.push({
      timestamp: Date.now(),
      message,
      data
    });
    // 최대 50개 항목만 유지
    while (debugLogs.length > 50) {
      debugLogs.shift();
    }
    localStorage.setItem('callback_logs', JSON.stringify(debugLogs));
  } catch (e) {
    // 저장 실패 시 무시
  }
};

export default function AuthCallbackPage() {
  const params = useParams();
  const router = useRouter();
  const [status, setStatus] = useState<string>('로드 중...');
  const [error, setError] = useState<string | null>(null);
  
  useEffect(() => {
    const provider = params.provider as string;
    
    // 콜백 페이지 로딩 기록
    debugLog('Auth 콜백 페이지 로드', {
      provider,
      url: window.location.href,
      search: window.location.search
    });
    
    try {
      localStorage.setItem('auth_callback_page_load', 'true');
      localStorage.setItem('auth_callback_provider', provider);
      localStorage.setItem('auth_callback_url', window.location.href);
    } catch (e) {
      // 저장 실패 시 무시
    }
    
    const handleAuth = async () => {
      try {
        setStatus('인증 처리 중...');
        
        // URL에서 코드와 state 파라미터 추출
        const searchParams = new URLSearchParams(window.location.search);
        const code = searchParams.get('code');
        const state = searchParams.get('state');
        const error = searchParams.get('error');
        const errorDescription = searchParams.get('error_description');
        
        // 디버깅 정보 기록
        debugLog('Auth 파라미터 분석', {
          code: code ? `${code.substring(0, 5)}...` : null,
          state,
          error,
          errorDescription
        });
        
        // 오류 파라미터가 있는지 확인
        if (error) {
          setError(`인증 오류: ${errorDescription || error}`);
          setStatus('인증 실패');
          
          // 3초 후 로그인 페이지로 리디렉션
          setTimeout(() => {
            window.location.href = '/en/login?error=' + encodeURIComponent(error);
          }, 3000);
          
          return;
        }
        
        // 코드가 없는 경우 확인
        if (!code) {
          setError('인증 코드가 없습니다.');
          setStatus('인증 실패');
          
          // 3초 후 로그인 페이지로 리디렉션
          setTimeout(() => {
            window.location.href = '/en/login?error=missing_code';
          }, 3000);
          
          return;
        }
        
        // 상태 정보 분석
        let lang = 'en';
        let returnPath = '/';
        
        try {
          if (state) {
            const stateData = JSON.parse(state);
            debugLog('State 데이터 파싱', stateData);
            
            // 언어 정보 추출
            lang = stateData.lang || 'en';
            
            // 리턴 경로 추출
            if (stateData.returnTo) {
              returnPath = stateData.returnTo;
            } else {
              returnPath = `/${lang}`;
            }
          }
        } catch (e) {
          debugLog('State 파싱 오류', { error: e instanceof Error ? e.message : '알 수 없는 오류' });
          // 기본값 사용
        }
        
        // Supabase 클라이언트 생성 및 세션 교환
        const supabase = createBrowserSupabaseClient();
        
        // 디버그 로그
        debugLog('세션 교환 시작', { codePrefix: code.substring(0, 5) + '...' });
        
        const { data, error: exchangeError } = await supabase.auth.exchangeCodeForSession(code);
        
        if (exchangeError) {
          debugLog('세션 교환 오류', { error: exchangeError.message });
          setError(`세션 교환 오류: ${exchangeError.message}`);
          setStatus('세션 교환 실패');
          
          // 3초 후 로그인 페이지로 리디렉션
          setTimeout(() => {
            window.location.href = `/${lang}/login?error=session_exchange&error_description=${encodeURIComponent(exchangeError.message)}`;
          }, 3000);
          
          return;
        }
        
        if (!data.session) {
          debugLog('세션 없음', { data });
          setError('세션 정보가 없습니다.');
          setStatus('세션 정보 누락');
          
          // 3초 후 로그인 페이지로 리디렉션
          setTimeout(() => {
            window.location.href = `/${lang}/login?error=no_session`;
          }, 3000);
          
          return;
        }
        
        // 세션 설정 성공
        debugLog('세션 교환 성공', { user: data.session.user.id });
        setStatus('로그인 성공! 리디렉션 중...');
        
        // 인증 성공 정보 저장
        try {
          localStorage.setItem('auth_success', 'true');
          localStorage.setItem('auth_provider', provider);
          localStorage.setItem('auth_timestamp', Date.now().toString());
        } catch (e) {
          // 저장 실패해도 진행
        }
        
        // 약간의 지연 후 홈 또는 원래 경로로 리디렉션
        setTimeout(() => {
          debugLog('로그인 완료, 리디렉션', { path: returnPath });
          window.location.href = returnPath;
        }, 1000);
        
      } catch (e) {
        const errorMessage = e instanceof Error ? e.message : '알 수 없는 오류';
        debugLog('인증 처리 예외', { error: errorMessage });
        setError(`인증 처리 중 예외 발생: ${errorMessage}`);
        setStatus('처리 오류');
        
        // 3초 후 로그인 페이지로 리디렉션
        setTimeout(() => {
          window.location.href = '/en/login?error=callback_error';
        }, 3000);
      }
    };
    
    handleAuth();
  }, [params]);
  
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full p-8 bg-white rounded-xl shadow-lg text-center">
        <h1 className="text-2xl font-bold mb-4">로그인 처리 중</h1>
        <div className="flex justify-center mb-6">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary-500"></div>
        </div>
        <p className="text-gray-700 mb-2">{status}</p>
        {error && (
          <div className="mt-4 p-4 bg-red-50 text-red-600 rounded-md">
            {error}
          </div>
        )}
        <p className="text-sm text-gray-500 mt-4">잠시 후 자동으로 이동합니다...</p>
      </div>
    </div>
  );
} 