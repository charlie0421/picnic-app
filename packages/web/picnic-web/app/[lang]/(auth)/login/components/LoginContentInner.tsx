import { useEffect, useCallback, useRef, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { useLanguageStore } from '@/stores/languageStore';
import { useAuthHandlers } from '../hooks/useAuthHandlers';
import { useAppleSDK } from '../hooks/useAppleSDK';
import { SocialProvider } from '../types/auth';
import { debugLog } from '../utils/debugUtils';
import LoginForm from './LoginForm';

interface LoginContentInnerProps {
  sdkScriptLoaded: boolean;
}

export default function LoginContentInner({ sdkScriptLoaded }: LoginContentInnerProps) {
  const searchParams = useSearchParams();
  const { t } = useLanguageStore();
  const initialCheckDone = useRef(false);
  const [debugInfo, setDebugInfo] = useState<string | null>(null);
  
  // 인증 관련 상태 및 함수들
  const {
    error, 
    loading, 
    setError,
    handleSignIn,
    checkForAuthCode,
    processErrorParams,
    supabase
  } = useAuthHandlers();

  // Apple SDK 초기화
  const { appleSDKInitialized } = useAppleSDK(
    sdkScriptLoaded,
    (provider) => {
      // ngrok 환경 감지 (브라우저에서만 작동)
      const isNgrok = typeof window !== 'undefined' && 
        (window.location.hostname.includes('ngrok') || 
        window.location.host.includes('ngrok'));
      
      // 현재 호스트 감지
      const currentHost = typeof window !== 'undefined' ? window.location.host : '';
      const protocol = typeof window !== 'undefined' && window.location.protocol === 'https:' ? 'https' : 'http';
      
      // 콜백 URL 생성
      const redirectUrl = `${protocol}://${currentHost}/auth/callback/${provider}`;
      return redirectUrl;
    },
    setError
  );
  
  // 디버그 정보 표시를 위한 함수
  const getNgrokDebugInfo = useCallback(() => {
    // ngrok 환경이 아니면 null 반환
    if (typeof window === 'undefined' || !(
      window.location.hostname.includes('ngrok') || 
      window.location.host.includes('ngrok') ||
      /^[a-z0-9]+\.ngrok(?:-free)?\.(?:io|app)$/.test(window.location.hostname)
    )) {
      return null;
    }

    // 로컬 스토리지에서 디버그 정보 수집
    try {
      const lastOAuthRequest = localStorage.getItem('last_oauth_request');
      const lastOAuthAttempt = localStorage.getItem('last_oauth_attempt');
      const authRequestInfo = localStorage.getItem('auth_request_info');
      const debugLogs = localStorage.getItem('debug_logs');

      // 디버그 정보 구성
      return JSON.stringify({
        url: window.location.href,
        hostname: window.location.hostname,
        origin: window.location.origin,
        lastOAuthRequest: lastOAuthRequest ? JSON.parse(lastOAuthRequest) : null,
        lastOAuthAttempt: lastOAuthAttempt ? JSON.parse(lastOAuthAttempt) : null,
        authRequestInfo: authRequestInfo ? JSON.parse(authRequestInfo) : null,
        recentLogs: debugLogs ? JSON.parse(debugLogs).slice(-5) : null
      }, null, 2);
    } catch (e) {
      const errorMessage = e instanceof Error ? e.message : '알 수 없는 오류';
      return `디버그 정보 추출 오류: ${errorMessage}`;
    }
  }, []);

  // 마운트 시 NgRok 환경 디버그 정보 수집
  useEffect(() => {
    const debugInfoText = getNgrokDebugInfo();
    if (debugInfoText) {
      setDebugInfo(debugInfoText);
      console.log('NgRok 디버그 정보:', debugInfoText);
    }
  }, [getNgrokDebugInfo]);
  
  // 마운트 시 인증 코드 확인 - 한 번만 실행되도록 ref 사용
  useEffect(() => {
    // 브라우저 환경인지 확인 및 이미 실행했는지 확인
    if (typeof window === 'undefined' || initialCheckDone.current) return;
    
    // 초기 확인 플래그 설정
    initialCheckDone.current = true;
    
    // 현재 URL이 콜백 URL인지 확인
    const isCallbackUrl = window.location.pathname.includes('/auth/callback/');
    const hasCode = new URL(window.location.href).searchParams.get('code');
    
    // 디버그용 로그
    debugLog('Login 페이지 마운트', {
      url: window.location.href,
      origin: window.location.origin,
      host: window.location.host,
      isCallbackUrl,
      hasCode
    });
    
    if (isCallbackUrl || hasCode) {
      debugLog('콜백 URL 또는 코드 감지 - 인증 처리 시작', {
        path: window.location.pathname,
        search: window.location.search
      });
      
      // 콜백 처리 정보 저장
      try {
        localStorage.setItem('auth_callback_start', JSON.stringify({
          time: Date.now(),
          url: window.location.href,
          pathname: window.location.pathname
        }));
      } catch (e) {
        // 저장 실패해도 계속 진행
      }
    }
    
    // 코드 확인 및 세션 처리 시작 - 지연 없이 바로 실행
    checkForAuthCode();
  }, [checkForAuthCode]); // 의존성 배열에 checkForAuthCode 포함

  // 세션 상태 변경 감지 - 별도 useEffect로 분리
  useEffect(() => {
    const authListener = supabase.auth.onAuthStateChange((event: string, session: any) => {
      console.log('인증 상태 변경:', event, !!session);
      
      if (event === 'SIGNED_IN' && session) {
        debugLog('세션 획득 및 SIGNED_IN 이벤트 - 홈으로 이동', { event, userId: session?.user?.id });
        
        // 홈으로 이동 전 세션 정보 기록
        try {
          localStorage.setItem('auth_success', 'true');
          localStorage.setItem('auth_provider', 'oauth');
          localStorage.setItem('auth_signed_in_time', Date.now().toString());
        } catch (e) {
          // 저장 실패해도 계속 진행
        }
        
        // 홈으로 이동
        window.location.href = '/';
      }
    });
    
    return () => {
      authListener.data.subscription.unsubscribe();
    };
  }, [supabase]);

  // 오류 파라미터 처리 - searchParams가 변경될 때만 실행
  useEffect(() => {
    // 이미 로딩 중이면 실행하지 않음
    if (loading) return;
    processErrorParams();
  }, [searchParams, processErrorParams, loading]);

  // 로그인 처리 핸들러
  const handleLogin = useCallback((provider: SocialProvider) => {
    // 로그인 시도 정보 기록
    try {
      localStorage.setItem('login_attempt', JSON.stringify({
        provider,
        timestamp: Date.now(),
        url: window.location.href
      }));
    } catch (e) {
      // 저장 실패해도 계속 진행
    }
    
    handleSignIn(provider, appleSDKInitialized, sdkScriptLoaded);
  }, [handleSignIn, appleSDKInitialized, sdkScriptLoaded]);

  // NgRok 환경에서 디버그 정보 표시
  const renderDebugInfo = () => {
    if (!debugInfo) return null;
    
    return (
      <div className="mt-4 p-4 bg-gray-50 text-xs text-gray-600 rounded-md overflow-auto h-64">
        <h3 className="font-bold mb-2">디버그 정보 (NgRok 환경)</h3>
        <pre>{debugInfo}</pre>
      </div>
    );
  };

  return (
    <div className='min-h-screen flex items-center justify-center bg-gray-50'>
      <div className='max-w-md w-full space-y-8 p-8 bg-white rounded-xl shadow-lg'>
        <div className='text-center'>
          <h2 className='mt-6 text-3xl font-extrabold text-gray-900'>
            {t('button_login')}
          </h2>
          {error && (
            <div className='mt-4 p-4 bg-red-50 text-red-600 rounded-md'>
              {error}
            </div>
          )}
        </div>
        <LoginForm 
          error={error}
          loading={loading}
          t={t}
          onLogin={handleLogin}
        />
        {renderDebugInfo()}
      </div>
    </div>
  );
} 