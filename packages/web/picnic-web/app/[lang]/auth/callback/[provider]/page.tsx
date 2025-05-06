'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { createBrowserSupabaseClient } from '@/utils/supabase-client';
import { getStoredCodeVerifier, clearCodeVerifier } from '@/app/[lang]/(auth)/login/utils/pkceUtils';

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
  const [debugDetail, setDebugDetail] = useState<string | null>(null);
  
  useEffect(() => {
    const provider = params.provider as string;
    
    // 콜백 페이지 로딩 기록
    debugLog('Auth 콜백 페이지 로드', {
      provider,
      url: window.location.href,
      search: window.location.search,
      pathname: window.location.pathname
    });
    
    try {
      localStorage.setItem('auth_callback_page_load', 'true');
      localStorage.setItem('auth_callback_provider', provider);
      localStorage.setItem('auth_callback_url', window.location.href);
      localStorage.setItem('auth_callback_pathname', window.location.pathname);
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
        
        // PKCE 코드 검증자 가져오기
        const codeVerifier = getStoredCodeVerifier();
        
        // 디버깅 정보 기록
        debugLog('Auth 파라미터 분석', {
          code: code ? `${code.substring(0, 5)}...` : null,
          state,
          error,
          errorDescription,
          hasCodeVerifier: !!codeVerifier,
          codeVerifierLength: codeVerifier?.length
        });
        
        // 디버그 상세 정보 설정 (NgRok 디버깅용)
        setDebugDetail(JSON.stringify({
          code: code ? `${code.substring(0, 5)}...` : null,
          state: state ? JSON.parse(state) : null,
          error,
          errorDescription,
          hasCodeVerifier: !!codeVerifier,
          url: window.location.href
        }, null, 2));
        
        // 오류 파라미터가 있는지 확인
        if (error) {
          setError(`인증 오류: ${errorDescription || error}`);
          setStatus('인증 실패');
          
          // 코드 검증자 정리
          clearCodeVerifier();
          
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
          
          // 코드 검증자 정리
          clearCodeVerifier();
          
          // 3초 후 로그인 페이지로 리디렉션
          setTimeout(() => {
            window.location.href = '/en/login?error=missing_code';
          }, 3000);
          
          return;
        }
        
        // 상태 정보 분석
        let lang = 'en';
        let returnPath = '/';
        let isPkce = false;
        let isDirect = false;
        
        try {
          if (state) {
            const stateData = JSON.parse(state);
            debugLog('State 데이터 파싱', stateData);
            
            // 언어 정보 추출
            lang = stateData.lang || 'en';
            
            // PKCE 사용 여부 확인
            isPkce = !!stateData.pkce;
            
            // 직접 OAuth 사용 여부 확인
            isDirect = !!stateData.direct;
            
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
        
        // 경로 유형 감지 (프로덕션 URL vs 언어 포함 URL)
        const isLangPath = window.location.pathname.includes(`/${lang}/auth/callback/`);
        debugLog('경로 유형 감지', { 
          isLangPath,
          pathname: window.location.pathname,
          lang
        });
        
        // PKCE 사용 중인데 코드 검증자가 없는 경우
        if (isPkce && !codeVerifier) {
          setError('PKCE 코드 검증자가 없습니다. 로그인 과정을 처음부터 다시 시작해주세요.');
          setStatus('인증 실패 (코드 검증자 누락)');
          
          // 3초 후 로그인 페이지로 리디렉션
          setTimeout(() => {
            window.location.href = `/${lang}/login?error=missing_code_verifier`;
          }, 3000);
          
          return;
        }
        
        // Supabase 클라이언트 생성
        const supabase = createBrowserSupabaseClient();
        
        // 직접 OAuth를 사용한 경우
        if (isDirect) {
          debugLog('직접 OAuth 인증 감지 - 구글 토큰 교환 시작', {
            isPkce,
            hasCodeVerifier: !!codeVerifier
          });
          
          try {
            // 직접 로그인 시도
            setStatus('Google 계정으로 직접 로그인 중...');
            
            // 구글로부터 받은 코드로 Supabase 인증
            const { data, error } = await supabase.auth.signInWithOAuth({
              provider: 'google',
              options: {
                skipBrowserRedirect: true,
                queryParams: {
                  // 현재 페이지의 코드를 전달
                  code: code,
                  // PKCE 사용 중이면 코드 검증자도 전달
                  ...(isPkce && codeVerifier ? { code_verifier: codeVerifier } : {})
                }
              }
            });
            
            // 코드 검증자 정리 (사용 완료)
            clearCodeVerifier();
            
            if (error) {
              debugLog('직접 OAuth 인증 실패', { error: error.message });
              setError(`구글 계정으로 로그인 실패: ${error.message}`);
              setStatus('인증 실패');
              
              // 3초 후 로그인 페이지로 리디렉션
              setTimeout(() => {
                window.location.href = `/${lang}/login?error=direct_oauth&error_description=${encodeURIComponent(error.message)}`;
              }, 3000);
              
              return;
            }
            
            if (!data.session) {
              setError('세션 정보가 없습니다.');
              setStatus('세션 정보 누락');
              
              setTimeout(() => {
                window.location.href = `/${lang}/login?error=no_session`;
              }, 3000);
              
              return;
            }
            
            // 로그인 성공
            debugLog('직접 OAuth 인증 성공', { user: data.session.user.id });
            setStatus('로그인 성공! 리디렉션 중...');
            
            // 인증 성공 정보 저장
            try {
              localStorage.setItem('auth_success', 'true');
              localStorage.setItem('auth_provider', 'google');
              localStorage.setItem('auth_timestamp', Date.now().toString());
              localStorage.setItem('auth_direct_oauth', 'true');
            } catch (e) {
              // 저장 실패해도 진행
            }
            
            // 약간의 지연 후 홈으로 리디렉션
            setTimeout(() => {
              debugLog('로그인 완료, 홈으로 이동', { path: '/' + lang });
              window.location.href = '/' + lang;
            }, 1000);
            
            return;
          } catch (ex) {
            const errorMessage = ex instanceof Error ? ex.message : '알 수 없는 오류';
            debugLog('직접 OAuth 인증 예외', { error: errorMessage });
            
            setError(`직접 OAuth 처리 중 오류: ${errorMessage}`);
            setStatus('처리 오류');
            
            // 코드 검증자 정리
            clearCodeVerifier();
            
            // 3초 후 로그인 페이지로 리디렉션
            setTimeout(() => {
              window.location.href = `/${lang}/login?error=direct_oauth_exception`;
            }, 3000);
            
            return;
          }
        }
        
        // 일반적인 OAuth 콜백 처리 (Supabase의 리디렉션을 통한 경우)
        // 디버그 로그
        debugLog('세션 교환 시작', { 
          codePrefix: code.substring(0, 5) + '...',
          isPkce,
          codeVerifierLength: codeVerifier?.length
        });
        
        // PKCE 사용 여부에 따라 다른 메서드 호출
        let exchangeResult;
        
        if (isPkce && codeVerifier) {
          // PKCE 방식으로 코드 교환
          exchangeResult = await supabase.auth.exchangeCodeForSession(code, { codeVerifier });
        } else {
          // 일반 방식으로 코드 교환
          exchangeResult = await supabase.auth.exchangeCodeForSession(code);
        }
        
        const { data, error: exchangeError } = exchangeResult;
        
        // 코드 검증자 정리 (사용 완료)
        clearCodeVerifier();
        
        if (exchangeError) {
          debugLog('세션 교환 오류', { error: exchangeError.message, isPkce });
          setError(`세션 교환 오류: ${exchangeError.message}`);
          setStatus('세션 교환 실패');
          
          // 3초 후 로그인 페이지로 리디렉션
          setTimeout(() => {
            window.location.href = `/${lang}/login?error=session_exchange&error_description=${encodeURIComponent(exchangeError.message)}`;
          }, 3000);
          
          return;
        }
        
        if (!data.session) {
          debugLog('세션 없음', { data, isPkce });
          setError('세션 정보가 없습니다.');
          setStatus('세션 정보 누락');
          
          // 3초 후 로그인 페이지로 리디렉션
          setTimeout(() => {
            window.location.href = `/${lang}/login?error=no_session`;
          }, 3000);
          
          return;
        }
        
        // 세션 설정 성공
        debugLog('세션 교환 성공', { user: data.session.user.id, isPkce });
        setStatus('로그인 성공! 리디렉션 중...');
        
        // 인증 성공 정보 저장
        try {
          localStorage.setItem('auth_success', 'true');
          localStorage.setItem('auth_provider', provider);
          localStorage.setItem('auth_timestamp', Date.now().toString());
          localStorage.setItem('auth_pkce_used', isPkce ? 'true' : 'false');
        } catch (e) {
          // 저장 실패해도 진행
        }
        
        // 약간의 지연 후 홈 또는 원래 경로로 리디렉션
        setTimeout(() => {
          // 경로 유형에 따라 적절한 리디렉션 경로 사용
          const redirectPath = isLangPath ? returnPath : `/${lang}`;
          debugLog('로그인 완료, 리디렉션', { path: redirectPath, isLangPath });
          window.location.href = redirectPath;
        }, 1000);
        
      } catch (e) {
        const errorMessage = e instanceof Error ? e.message : '알 수 없는 오류';
        debugLog('인증 처리 예외', { error: errorMessage });
        setError(`인증 처리 중 예외 발생: ${errorMessage}`);
        setStatus('처리 오류');
        
        // 코드 검증자 정리
        clearCodeVerifier();
        
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
        
        {/* NgRok 환경에서 디버깅을 위한 상세 정보 */}
        {debugDetail && (
          <div className="mt-4 p-2 bg-gray-50 text-xs text-gray-600 rounded-md">
            <details>
              <summary className="cursor-pointer font-semibold">디버그 정보</summary>
              <pre className="mt-2 text-left overflow-auto">{debugDetail}</pre>
            </details>
          </div>
        )}
      </div>
    </div>
  );
} 