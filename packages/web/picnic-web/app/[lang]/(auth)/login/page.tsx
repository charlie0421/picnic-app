'use client';

import { useState, useEffect, useCallback, Suspense } from 'react';
import { createBrowserSupabaseClient } from '@/utils/supabase-client';
import Image from 'next/image';
import { useRouter, useSearchParams } from 'next/navigation';
import { useLanguageStore } from '@/stores/languageStore';
import Script from 'next/script';

// AppleID 타입 정의
declare global {
  interface Window {
    AppleID?: {
      auth: {
        init(params: any): void;
        signIn(): Promise<{
          authorization: {
            id_token?: string;
            code?: string;
            state?: string;
          };
        }>;
      };
    };
  }
}

// 간단한 디버깅 함수 추가
const debugLog = (message: string, data?: any) => {
  console.log(`[DEBUG] ${message}`, data ? data : '');
  try {
    // 디버그 정보를 로컬 스토리지에 저장
    const debugLogs = JSON.parse(localStorage.getItem('debug_logs') || '[]');
    debugLogs.push({
      timestamp: Date.now(),
      message,
      data
    });
    // 최대 50개 항목만 유지
    while (debugLogs.length > 50) {
      debugLogs.shift();
    }
    localStorage.setItem('debug_logs', JSON.stringify(debugLogs));
  } catch (e) {
    // 저장 실패 시 무시
  }
};

// SearchParams를 사용하는 컴포넌트
function LoginContentInner({ sdkScriptLoaded }: { sdkScriptLoaded: boolean }) {
  const [supabase] = useState(() => createBrowserSupabaseClient());
  const router = useRouter();
  const searchParams = useSearchParams();
  const { t } = useLanguageStore();
  const [error, setError] = useState<string | null>(null);
  const [appleSDKInitialized, setAppleSDKInitialized] = useState(false);
  const [loading, setLoading] = useState(false);
  
  // 인증 성공 후 처리를 위한 함수
  const handleAuthSuccess = useCallback((data: any, provider: string = 'apple') => {
    const session = data.session;
    if (!session) {
      console.error('세션 정보가 없습니다');
      setError('인증은 성공했으나 세션 정보가 없습니다.');
      return false;
    }

    // 로딩 상태로 UI 변경 - 로그인 폼 숨김
    setLoading(true);

    // 세션 정보 저장
    try {
      localStorage.setItem('auth_session_active', 'true');
      localStorage.setItem('auth_provider', provider);
    } catch (e) {
      // 무시: 저장 실패해도 인증 과정에는 영향 없음
    }
    
    // 직접 홈으로 이동 (라우터 사용하지 않음)
    console.log('로그인 성공, 홈으로 이동합니다.');
    window.location.href = '/';
    
    return true;
  }, []);
  
  // 컴포넌트 마운트 시 현재 인증 상태 확인
  useEffect(() => {
    // 브라우저 환경인지 확인
    if (typeof window === 'undefined') return;
    
    // 디버그용 로그
    debugLog('Login 페이지 마운트', {
      url: window.location.href,
      origin: window.location.origin,
      host: window.location.host
    });
    
    // URL에서 인증 코드 확인 (OAuth 콜백)
    const checkForAuthCode = async () => {
      try {
        // 로딩 상태 표시
        setLoading(true);
        
        if (typeof window !== 'undefined') {
          // 현재 URL 검사
          const url = new URL(window.location.href);
          const code = url.searchParams.get('code');
          const state = url.searchParams.get('state');
          const error = url.searchParams.get('error');
          const errorDescription = url.searchParams.get('error_description');
          
          // 오류 파라미터가 있는지 확인
          if (error) {
            console.error('URL에서 OAuth 오류 파라미터 감지:', error, errorDescription);
            setError(`OAuth 인증 오류: ${errorDescription || error}`);
            setLoading(false);
            return;
          }
          
          if (code) {
            debugLog('인증 코드 감지', {
              codePrefix: code.substring(0, 5) + '...',
              state,
              url: window.location.href
            });
            
            console.log('인증 코드 감지:', code.substring(0, 5) + '...');
            console.log('상태 값:', state);
            
            // 디버깅을 위한 정보 기록
            console.log('URL 전체 정보: ', window.location.href);
            console.log('URL 검색 파라미터: ', url.search);
            
            // 인증 시도 기록
            try {
              localStorage.setItem('auth_code_detected', 'true');
              localStorage.setItem('auth_code_timestamp', Date.now().toString());
            } catch (e) {
              // 저장 실패해도 진행
            }
            
            // URL에서 코드 제거 (히스토리에 남지 않도록)
            window.history.replaceState({}, document.title, window.location.pathname);
            
            try {
              // 세션 교환 시작 로그
              debugLog('세션 교환 시작', { codePrefix: code.substring(0, 5) + '...' });
              
              // 수동으로 코드 교환 시도
              console.log('세션 교환 시작...');
              const { data, error } = await supabase.auth.exchangeCodeForSession(code);
              
              if (error) {
                console.error('세션 교환 오류:', error.message);
                debugLog('세션 교환 오류', { error: error.message });
                
                // 5초 후 페이지 새로고침 (가끔 오류 후에도 세션이 설정됨)
                setTimeout(() => {
                  console.log('세션 교환 오류 후 페이지 새로고침');
                  window.location.reload();
                }, 5000);
                
                setError('로그인 처리 중 오류가 발생했습니다: ' + error.message);
                setLoading(false);
                return;
              }
              
              if (data?.session) {
                debugLog('세션 교환 성공', { userId: data.session.user?.id });
                console.log('세션 교환 성공:', data.session.user?.id);
                
                // 수동으로 세션 설정
                await supabase.auth.setSession({
                  access_token: data.session.access_token,
                  refresh_token: data.session.refresh_token,
                });
                
                // localStorage에 성공 표시
                try {
                  localStorage.setItem('auth_success', 'true');
                  localStorage.setItem('auth_provider', 'google');
                  localStorage.setItem('auth_timestamp', Date.now().toString());
                } catch (e) {
                  // 실패해도 진행
                }
                
                // 인증 이벤트 발생
                window.dispatchEvent(new Event('auth.state.changed'));
                
                // 약간의 지연 후 홈으로 리디렉션 (이벤트가 처리될 시간을 주기 위함)
                setTimeout(() => {
                  debugLog('로그인 완료, 홈으로 이동');
                  console.log('로그인 완료, 홈으로 이동합니다');
                  window.location.href = '/';
                }, 500);
                
                return;
              } else {
                console.warn('세션 교환은 성공했으나 세션이 없음');
                debugLog('세션 없음', { data });
                
                // 3초 후 페이지 새로고침
                setTimeout(() => {
                  console.log('세션 없음 - 페이지 새로고침');
                  window.location.reload();
                }, 3000);
              }
            } catch (err: any) {
              console.error('세션 교환 중 예외 발생:', err);
              debugLog('세션 교환 예외', { error: err.message });
              setError('로그인 처리 중 오류가 발생했습니다');
              
              // 5초 후 페이지 새로고침 (가끔 오류 후에도 세션이 설정됨)
              setTimeout(() => {
                console.log('오류 후 페이지 새로고침');
                window.location.reload();
              }, 5000);
            }
          }
        }
        
        // 코드가 없거나 처리 후에는 일반 체크 계속
        await checkAuth();
      } catch (e: any) {
        console.error('인증 코드 확인 중 오류:', e);
        debugLog('인증 코드 확인 오류', { error: e.message });
        setLoading(false);
      }
    };
    
    // 인증 상태 확인
    const checkAuth = async () => {
      try {
        const { data } = await supabase.auth.getSession();
        
        // 이미 로그인된 경우 즉시 홈으로 리디렉션
        if (data.session) {
          console.log('이미 로그인 상태, 홈으로 리디렉션합니다.');
          window.location.href = '/';
          return;
        }
        
        // 로그인이 필요한 경우에만 로딩 상태 해제
        setLoading(false);
      } catch (e) {
        // 세션 확인 실패 - 로그인 화면 표시
        console.error('세션 확인 실패:', e);
        setLoading(false);
      }
    };
    
    // 코드 확인 및 세션 처리 시작
    checkForAuthCode();
    
    // 세션 상태 변경 감지
    const authListener = supabase.auth.onAuthStateChange((event: string, session: any) => {
      console.log('인증 상태 변경:', event, !!session);
      
      if (event === 'SIGNED_IN' && session) {
        // 로딩 상태로 UI 변경 - 로그인 폼 숨김
        setLoading(true);
        
        // 직접 홈으로 이동 (라우터 사용하지 않음)
        window.location.href = '/';
      }
    });
    
    return () => {
      authListener.data.subscription.unsubscribe();
    };
  }, [supabase]);
  
  // SDK가 로드되면 초기화
  useEffect(() => {
    if (!sdkScriptLoaded || !window.AppleID || appleSDKInitialized) return;
    
    try {
      // 리디렉션 URL 설정 - ngrok 고려
      const redirectURI = getRedirectUrl('apple');
      
      // state 파라미터 준비 (원래 URL 정보 포함)
      const stateParams = {
        redirectUrl: typeof window !== 'undefined' ? window.location.origin : '',
        timestamp: Date.now(),
      };
      
      console.log('Apple SDK 초기화:', {
        redirectURI,
        originalUrl: stateParams.redirectUrl
      });
      
      // Apple SDK 초기화 - nonce 사용하지 않음
      const initOptions = {
        clientId: 'fan.picnic.web',
        scope: 'name email',
        redirectURI: redirectURI,
        usePopup: true,
        state: JSON.stringify(stateParams)
      };
      
      window.AppleID.auth.init(initOptions);
      
      // 이벤트 리스너 등록
      const successHandler = () => {};
      const failureHandler = () => {
        setError('Apple 로그인 중 오류가 발생했습니다.');
      };
      
      document.addEventListener('AppleIDSignInOnSuccess', successHandler);
      document.addEventListener('AppleIDSignInOnFailure', failureHandler);
      
      setAppleSDKInitialized(true);
      
      return () => {
        document.removeEventListener('AppleIDSignInOnSuccess', successHandler);
        document.removeEventListener('AppleIDSignInOnFailure', failureHandler);
      };
    } catch (error) {
      setError('Apple 로그인을 초기화하는 중 오류가 발생했습니다.');
    }
  }, [sdkScriptLoaded, appleSDKInitialized]);

  // 오류 파라미터 처리
  useEffect(() => {
    const error = searchParams.get('error');
    const errorDescription = searchParams.get('error_description');
    const provider = searchParams.get('provider');

    if (error) {
      switch (error) {
        case 'missing_params':
          setError('필수 파라미터가 누락되었습니다.');
          break;
        case 'server_error':
          setError(`서버 오류가 발생했습니다: ${errorDescription || '알 수 없는 오류'}`);
          break;
        case 'oauth_error':
          setError(provider === 'apple' 
            ? 'Apple 로그인 중 오류가 발생했습니다. 다시 시도해주세요.'
            : '소셜 로그인 중 오류가 발생했습니다.');
          break;
        case 'callback_error':
          setError('인증 처리 중 오류가 발생했습니다.');
          break;
        default:
          setError('알 수 없는 오류가 발생했습니다.');
      }
    }
  }, [searchParams]);

  // ngrok URL을 감지하여 올바른 리디렉션 URL 생성
  const getRedirectUrl = (provider: string) => {
    // ngrok 환경 감지 (브라우저에서만 작동)
    const isNgrok = typeof window !== 'undefined' && 
      (window.location.hostname.includes('ngrok') || 
       window.location.host.includes('ngrok'));
    
    // 현재 호스트 감지
    const currentHost = typeof window !== 'undefined' ? window.location.host : '';
    const protocol = typeof window !== 'undefined' && window.location.protocol === 'https:' ? 'https' : 'http';
    
    console.log('현재 환경:', {
      isNgrok,
      host: currentHost,
      protocol
    });
    
    // 콜백 URL 생성
    const redirectUrl = `${protocol}://${currentHost}/auth/callback/${provider}`;
    console.log(`리디렉션 URL: ${redirectUrl}`);
    
    return redirectUrl;
  };

  // 간소화된 Apple 로그인 처리 함수
  const handleAppleSignIn = async () => {
    if (!window.AppleID || !appleSDKInitialized) {
      if (sdkScriptLoaded && !window.AppleID) {
        setError('이 브라우저에서는 Apple 로그인이 지원되지 않습니다. 다른 로그인 방법을 이용하세요.');
      } else {
        setError('Apple 로그인이 아직 준비되지 않았습니다. 잠시 후 다시 시도해주세요.');
      }
      return;
    }

    try {
      setLoading(true);
      
      // ID 토큰 획득
      const appleResponse = await window.AppleID.auth.signIn();
      if (!appleResponse.authorization.id_token) {
        throw new Error('Apple에서 ID 토큰을 받지 못했습니다.');
      }

      const idToken = appleResponse.authorization.id_token;
      
      // Supabase로 인증 시도
      try {
        const { data, error } = await supabase.auth.signInWithIdToken({
          provider: 'apple',
          token: idToken
        });
        
        if (!error) {
          return handleAuthSuccess(data, 'apple');
        }
        
        // 첫 번째 시도 실패 시, nonce를 명시적으로 null로 설정하여 재시도
        if (error.message?.includes('nonce') || error.message?.includes('Nonce')) {
          const { data: retryData, error: retryError } = await supabase.auth.signInWithIdToken({
            provider: 'apple',
            token: idToken,
            nonce: null
          });
          
          if (!retryError) {
            return handleAuthSuccess(retryData, 'apple');
          }
          
          // 마지막 시도
          const { data: finalData, error: finalError } = await supabase.auth.signInWithIdToken({
            provider: 'apple',
            token: idToken
          });
          
          if (!finalError) {
            return handleAuthSuccess(finalData, 'apple');
          }
          
          setError(`Apple 로그인에 실패했습니다: ${finalError.message}`);
        } else {
          setError(`Apple 로그인에 실패했습니다: ${error.message}`);
        }
      } catch (error: any) {
        setError(`Apple 로그인 처리 중 오류가 발생했습니다: ${error.message || '알 수 없는 오류'}`);
      }
    } catch (err: any) {
      setError(`Apple 로그인 처리 중 오류가 발생했습니다: ${err.message || '알 수 없는 오류'}`);
    } finally {
      setLoading(false);
    }
  };

  // 다른 소셜 로그인 처리 함수
  const handleOtherSignIn = async (provider: 'google' | 'kakao' | 'wechat') => {
    if (provider === 'google') {
      try {
        // 로딩 상태 설정 - 로그인 폼 숨김
        setLoading(true);
        
        // URL 환경 직접 감지 (window.location 객체 사용)
        const actualOrigin = window.location.origin;
        const actualHost = window.location.host;
        const actualHostname = window.location.hostname;
        const actualProtocol = window.location.protocol;
        
        // 디버깅 정보 저장
        debugLog('URL 정보 감지', {
          actualOrigin,
          actualHost,
          actualHostname,
          actualProtocol,
          href: window.location.href
        });
        
        // 환경 정보 로컬 스토리지에 저장 (인증 후 비교용)
        try {
          localStorage.setItem('auth_request_info', JSON.stringify({
            actualOrigin,
            actualHost,
            actualHostname,
            timestamp: Date.now()
          }));
        } catch (e) {
          // 저장 실패 시 무시
        }
        
        console.log('실제 URL 정보:', {
          actualOrigin,
          actualHost,
          actualHostname,
          actualProtocol,
          href: window.location.href
        });
        
        // ngrok 환경 직접 확인
        const isNgrokActual = 
          actualHostname.includes('ngrok') || 
          actualHost.includes('ngrok') ||
          /^[a-z0-9]+\.ngrok(?:-free)?\.(?:io|app)$/.test(actualHostname);
        
        debugLog('ngrok 환경 감지', {
          isNgrokActual,
          hostnameCheck: actualHostname.includes('ngrok'),
          hostCheck: actualHost.includes('ngrok'),
          regexCheck: /^[a-z0-9]+\.ngrok(?:-free)?\.(?:io|app)$/.test(actualHostname)
        });
        
        // 현재 환경에 맞는 리디렉션 URL 설정 (실제 URL 기반)
        const redirectUrl = `${actualOrigin}/auth/callback/${provider}`;
        
        // 명시적으로 리다이렉트 URL을 변경 (환경 변수를 무시)
        debugLog(`${provider} 로그인 시도`, { 
          actualOrigin,
          actualHost,
          redirectUrl,
          isNgrokActual,
          userAgent: navigator.userAgent
        });
        
        console.log(`${provider} 로그인 시도 - 실제 환경:`, { 
          actualOrigin,
          actualHost,
          redirectUrl,
          isNgrokActual,
          userAgent: navigator.userAgent
        });
        
        // 구글 로그인 리디렉션 처리 개선
        debugLog('구글 OAuth 요청 시작');
        console.log('구글 OAuth 요청 시작');
        
        // 오류 로깅 함수
        const logError = (message: string, error: any) => {
          console.error(message, error);
          debugLog('구글 OAuth 오류', { message, error });
          setError(message);
          setLoading(false);
        };
        
        // 먼저 Supabase 세션을 클리어 (기존 인증 상태로 인한 문제 방지)
        try {
          await supabase.auth.signOut({ scope: 'local' });
          debugLog('기존 세션 클리어');
        } catch (e) {
          debugLog('기존 세션 클리어 실패', { error: e });
          // 실패해도 계속 진행
        }
        
        // 공통 옵션 구성
        const oauthOptions = {
          redirectTo: redirectUrl,
          queryParams: {
            prompt: 'select_account', // 항상 계정 선택 화면 표시
            access_type: 'offline' // refresh_token을 얻기 위해 필요
          },
          scopes: 'email profile openid',
          skipBrowserRedirect: false, // true로 설정하면 자동 리디렉션이 되지 않음
          state: JSON.stringify({
            redirectUrl: actualOrigin,
            timestamp: Date.now(),
            provider: 'google',
            host: actualHost,
            isNgrok: isNgrokActual
          })
        };
        
        debugLog('OAuth 옵션', oauthOptions);
        console.log('OAuth 옵션:', JSON.stringify(oauthOptions, null, 2));
        
        // Supabase OAuth 요청
        const { data, error } = await supabase.auth.signInWithOAuth({
          provider,
          options: oauthOptions
        });
        
        // 오류 확인
        if (error) {
          logError(`구글 로그인 중 오류가 발생했습니다: ${error.message}`, error);
          return;
        }
        
        // 리디렉션 URL이 있으면 해당 URL로 이동
        if (data?.url) {
          debugLog('구글 로그인 리디렉션 URL 획득', { url: data.url });
          console.log('구글 로그인 리디렉션 URL 획득:', data.url);
          
          // 로그인 폼 계속 숨김 상태 유지
          setLoading(true);
          
          // localStorage에 시도 정보 저장 (디버깅용)
          try {
            localStorage.setItem('last_oauth_attempt', JSON.stringify({
              provider,
              timestamp: Date.now(),
              redirectUrl
            }));
          } catch (e) {
            // 저장 실패해도 진행
          }
          
          // 구글 로그인 페이지로 리디렉션
          debugLog('구글 로그인 페이지로 리디렉션', { url: data.url });
          console.log('구글 로그인 페이지로 리디렉션 중...');
          
          // 약간의 지연 후 리디렉션 (브라우저 처리 시간 확보)
          setTimeout(() => {
            window.location.href = data.url;
          }, 100);
          
          return;
        }
        
        debugLog('구글 리디렉션 URL이 없음', { data });
        console.log('구글 리디렉션 URL이 없음, 직접 처리 시도');
        
        // URL이 없지만 데이터가 있는 경우 (드문 케이스)
        if (data) {
          return handleAuthSuccess(data, provider);
        }
        
        // 여기까지 왔다면 뭔가 잘못된 것
        logError('구글 로그인을 시작할 수 없습니다. 다시 시도해주세요.', null);
      } catch (error: any) {
        console.error('구글 로그인 예외:', error);
        debugLog('구글 로그인 예외', { error: error?.message });
        setError(`구글 로그인 중 예기치 않은 오류가 발생했습니다: ${error.message || '알 수 없는 오류'}`);
        setLoading(false);
      }
      return;
    }
    
    // Kakao, WeChat 처리
    try {
      // 로딩 상태 설정 - 로그인 폼 숨김
      setLoading(true);
      
      const res = await fetch(
        `https://api.picnic.fan/functions/v1/${provider}-web-oauth`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            redirect_url: window.location.origin + '/auth/callback/' + provider,
          }),
          credentials: 'include',
        },
      );

      if (!res.ok) {
        setError(`${provider} 로그인 중 오류가 발생했습니다.`);
        setLoading(false);
        return;
      }

      const { url, error: oauthError } = await res.json();

      if (oauthError || !url) {
        setError(`${provider} 로그인 중 오류가 발생했습니다: ${oauthError || '알 수 없는 오류'}`);
        setLoading(false);
        return;
      }

      // 소셜 제공자 로그인 페이지로 이동
      window.location.href = url;
    } catch (error: any) {
      setError(`${provider} 로그인 중 오류가 발생했습니다: ${error.message || '알 수 없는 오류'}`);
      setLoading(false);
    }
  };

  // 통합된 로그인 처리 함수
  const handleSignIn = async (provider: 'google' | 'apple' | 'kakao' | 'wechat') => {
    if (provider === 'apple') {
      await handleAppleSignIn();
    } else {
      await handleOtherSignIn(provider);
    }
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
        {loading ? (
          <div className='flex flex-col items-center justify-center py-8'>
            <div className='animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary-500 mb-4'></div>
            <p className='text-gray-600'>로그인 처리 중...</p>
          </div>
        ) : (
        <div className='mt-8 space-y-4'>
          <button
            onClick={() => handleSignIn('google')}
              disabled={loading}
              className='flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed'
          >
            <Image
              src='/images/auth/google-logo.svg'
              alt={`Google ${t('button_login')}`}
              width={20}
              height={20}
              className='mr-2'
            />
            Google {t('button_continue_with')}
          </button>

          <button
            onClick={() => handleSignIn('apple')}
              disabled={loading}
              className='flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-white bg-black border border-gray-300 rounded-md hover:bg-gray-800 disabled:opacity-50 disabled:cursor-not-allowed'
              aria-label='Apple 계정으로 계속하기'
          >
            <Image
              src='/images/auth/apple-logo.svg'
              alt={`Apple ${t('button_login')}`}
              width={20}
              height={20}
              className='mr-2'
            />
            Apple {t('button_continue_with')}
          </button>

          <button
            onClick={() => handleSignIn('kakao')}
              disabled={loading}
              className='flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-[#191919] bg-[#FEE500] rounded-md hover:bg-[#F4DC00] disabled:opacity-50 disabled:cursor-not-allowed'
          >
            <Image
              src='/images/auth/kakao-logo.svg'
              alt={`Kakao ${t('button_login')}`}
              width={20}
              height={20}
              className='mr-2'
            />
            Kakao {t('button_continue_with')}
          </button>

          <button
            onClick={() => handleSignIn('wechat')}
              disabled={loading}
              className='flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-white bg-[#07C160] rounded-md hover:bg-[#06AD56] disabled:opacity-50 disabled:cursor-not-allowed'
          >
            <Image
              src='/images/auth/wechat-logo.svg'
              alt={`WeChat ${t('button_login')}`}
              width={20}
              height={20}
              className='mr-2'
            />
            WeChat {t('button_continue_with')}
          </button>
        </div>
        )}
      </div>
    </div>
  );
}

// Suspense로 감싸서 제공하는 컴포넌트
function LoginContent({ sdkScriptLoaded }: { sdkScriptLoaded: boolean }) {
  return (
    <Suspense fallback={
        <div className='min-h-screen flex items-center justify-center bg-gray-50'>
          <div className='max-w-md w-full space-y-8 p-8 bg-white rounded-xl shadow-lg'>
          <div className='flex flex-col items-center justify-center py-8'>
            <div className='animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary-500 mb-4'></div>
            <p className='text-gray-600'>로딩 중...</p>
          </div>
        </div>
      </div>
    }>
      <LoginContentInner sdkScriptLoaded={sdkScriptLoaded} />
    </Suspense>
  );
}

export default function Login() {
  // Apple SDK 스크립트 로드 상태 관리
  const [sdkScriptLoaded, setSdkScriptLoaded] = useState(false);
  
  const handleAppleScriptLoad = () => {
    setSdkScriptLoaded(true);
  };

  return (
    <>
      <Script 
        src="https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js"
        strategy="afterInteractive"
        onLoad={handleAppleScriptLoad}
        onError={() => console.error('Apple SDK 스크립트 로드 실패')}
      />
      <LoginContent sdkScriptLoaded={sdkScriptLoaded} />
    </>
  );
}