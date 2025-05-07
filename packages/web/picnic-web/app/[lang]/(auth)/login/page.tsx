'use client';

import { useState, useEffect, useCallback, Suspense } from 'react';
import { supabase } from '@/utils/supabase-client';
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
    const authError = searchParams.get('auth_error');

    // 오류 로컬 스토리지에서 확인
    const localErrorDescription = (() => {
      try {
        return localStorage.getItem('auth_error_description');
      } catch (e) {
        return null;
      }
    })();
    
    if (authError === 'true' || error) {
      // 먼저 디버그 로그 기록
      debugLog('인증 오류 발생', {
        error,
        errorDescription,
        authError,
        localErrorDescription,
        provider
      });
      
      // 오류 메시지 설정
      if (errorDescription) {
        setError(`인증 오류: ${decodeURIComponent(errorDescription)}`);
      } else if (localErrorDescription) {
        setError(`인증 오류: ${localErrorDescription}`);
        // 로컬 스토리지에서 사용 후 제거
        try {
          localStorage.removeItem('auth_error_description');
        } catch (e) {}
      } else if (error === 'invalid_request' || error === 'bad_oauth_callback') {
        setError('OAuth 인증 중 문제가 발생했습니다. 다시 시도해주세요.');
      } else if (error) {
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
            setError(`인증 오류가 발생했습니다: ${errorDescription || '알 수 없는 오류'}`);
        }
      } else {
        setError('로그인 중 알 수 없는 오류가 발생했습니다. 다시 시도해주세요.');
      }
      
      // URL에서 오류 파라미터 제거
      if (typeof window !== 'undefined') {
        const url = new URL(window.location.href);
        url.searchParams.delete('error');
        url.searchParams.delete('error_description');
        url.searchParams.delete('auth_error');
        url.searchParams.delete('provider');
        window.history.replaceState({}, document.title, url.toString());
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
        
        // 첫 번째 시도 실패 시, nonce를 명시적으로 빈 문자열로 설정하여 재시도
        if (error.message?.includes('nonce') || error.message?.includes('Nonce')) {
          const { data: retryData, error: retryError } = await supabase.auth.signInWithIdToken({
            provider: 'apple',
            token: idToken,
            nonce: ''
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
  const handleOtherSignIn = async (provider: 'google' | 'kakao') => {
    try {
      setLoading(true);
      
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: provider,
        options: {
          redirectTo: `https://${window.location.host}/auth/callback/${provider}`,
          queryParams: {
            redirect_to: `https://${window.location.host}/auth/callback/${provider}`,
          },
          skipBrowserRedirect: true,
        },
      });

      console.log('OAuth Response:', {
        data,
        error,
        redirectTo: `https://${window.location.host}/auth/callback/${provider}`,
        currentUrl: window.location.href
      });

      if (error) {
        setError(`${provider} 로그인 중 오류가 발생했습니다: ${error.message}`);
        setLoading(false);
      } else if (data?.url) {
        window.location.href = data.url;
      }
    } catch (error: any) {
      setError(`${provider} 로그인 중 오류가 발생했습니다: ${error.message || '알 수 없는 오류'}`);
      setLoading(false);
    }
  };

  // 통합된 로그인 처리 함수
  const handleSignIn = async (provider: 'google' | 'apple' | 'kakao') => {
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