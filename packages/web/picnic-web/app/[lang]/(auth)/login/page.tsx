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

    // 세션 정보 저장
    try {
      localStorage.setItem('auth_session_active', 'true');
      localStorage.setItem('auth_provider', provider);
    } catch (e) {
      // 무시: 저장 실패해도 인증 과정에는 영향 없음
    }
    
    // 세션 정보 갱신을 위한 이벤트 발생
    try {
      // 인증 이벤트를 여러 번 발생시켜 모든 컴포넌트가 상태 변화를 인식하도록 함
      window.dispatchEvent(new Event('supabase.auth.session-update'));
      window.dispatchEvent(new Event('auth.state.changed'));
      
      // 약간의 지연 후 다시 한번 이벤트 발생 (비동기 상태 업데이트 문제 해결)
      setTimeout(() => {
        window.dispatchEvent(new Event('auth.state.changed'));
      }, 100);
    } catch (e) {
      // 무시: 이벤트 발생 실패해도 인증 과정에는 영향 없음
    }
    
    // 상태가 적용될 시간을 주기 위해 약간 지연 후 홈으로 리디렉션
    setTimeout(() => {
      router.push('/');
    }, 300);
    
    return true;
  }, [router]);
  
  // 컴포넌트 마운트 시 현재 인증 상태 확인
  useEffect(() => {
    const checkAuth = async () => {
      try {
        const { data } = await supabase.auth.getSession();
        
        // 이미 로그인된 경우 홈으로 리디렉션
        if (data.session) {
          router.push('/');
          return;
        }
      } catch (e) {
        // 세션 확인 실패 - 로그인 화면 표시
      } finally {
        setLoading(false);
      }
    };
    
    checkAuth();
    
    // 세션 상태 변경 감지
    const authListener = supabase.auth.onAuthStateChange((event: string, session: any) => {
      if (event === 'SIGNED_IN' && session) {
        router.push('/');
      }
    });
    
    return () => {
      authListener.data.subscription.unsubscribe();
    };
  }, [supabase, router]);
  
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
        // 로딩 상태 설정
        setLoading(true);
        
        // 현재 URL (ngrok 또는 로컬 개발 환경)
        const currentDomain = typeof window !== 'undefined' ? window.location.origin : '';
        const redirectUrl = `${currentDomain}/auth/callback/${provider}`;
        
        // 별도의 ngrok 감지
        const isNgrok = typeof window !== 'undefined' && 
          (window.location.hostname.includes('ngrok') || 
           window.location.host.includes('ngrok'));
           
        console.log(`${provider} 로그인 시도 - 환경:`, { 
          currentDomain,
          redirectUrl,
          isNgrok
        });
        
        // ngrok 환경이면 커스텀 URL로 리디렉션
        if (isNgrok) {
          console.log('ngrok 환경 감지: 직접 로그인 URL 사용');
          
          // 구글 OAuth 클라이언트 ID - Supabase 설정과 동일한 값 사용
          // 이 값은 다음 경로에서 확인 가능: Supabase 대시보드 > Authentication > Providers > Google
          const clientId = '853406219989-jrfkss5a0lqe5sq43t4uhm7n6i0g6s1b.apps.googleusercontent.com';
          
          // ✓ 옵션 1: 직접 콜백 URL 사용 (구글 Cloud Console에 이 URL 추가 필요)
          // 구글 OAuth 설정에 이 URL을 추가해야 합니다:
          // Google Cloud Console > API 및 서비스 > 사용자 인증 정보 > OAuth 클라이언트 ID > 승인된 리디렉션 URI
          const ngrokCallbackUrl = `${currentDomain}/auth/callback/google`;
          
          // ✗ 옵션 2: Supabase 기본 콜백 URL 사용 (state로 원래 URL 전달)
          // const supabaseRedirectUri = 'https://api.picnic.fan/auth/v1/callback';
          
          // 세션은 브라우저 전체에서 공유되므로 직접 로그인 URL로 이동
          const url = `https://accounts.google.com/o/oauth2/v2/auth?` + 
            `client_id=${clientId}&` +
            `redirect_uri=${encodeURIComponent(ngrokCallbackUrl)}&` +
            `response_type=code&` +
            `scope=${encodeURIComponent('email profile openid')}&` +
            `prompt=select_account&` +
            `state=${encodeURIComponent(JSON.stringify({
              originalUrl: currentDomain,
              timestamp: Date.now(),
              ngrok: true
            }))}`;
          
          console.log('구글 로그인 URL로 이동:', url);
          window.location.href = url;
          return;
        }
        
        // 일반 환경은 Supabase OAuth 사용
        console.log('일반 환경: Supabase OAuth 사용');
        const { data, error } = await supabase.auth.signInWithOAuth({
          provider,
          options: {
            redirectTo: redirectUrl,
            queryParams: {
              prompt: 'select_account' // 항상 계정 선택 화면 표시
            },
            scopes: 'email profile',
            skipBrowserRedirect: false,
            state: JSON.stringify({
              redirectUrl: currentDomain,
              timestamp: Date.now(),
            })
          },
        });
        
        // 오류 확인
        if (error) {
          setError(`구글 로그인 중 오류가 발생했습니다: ${error.message}`);
          setLoading(false);
          return;
        }
        
        // 리디렉션 URL이 있으면 해당 URL로 이동
        if (data?.url) {
          // 인증 이벤트 미리 발생시키기
          try {
            window.dispatchEvent(new Event('supabase.auth.session-update'));
            window.dispatchEvent(new Event('auth.state.changed'));
          } catch (e) {
            // 무시
          }
          
          // 구글 로그인 페이지로 리디렉션
          window.location.href = data.url;
          return;
        }
        
        // URL이 없지만 데이터가 있는 경우 (드문 케이스)
        if (data) {
          return handleAuthSuccess(data, provider);
        }
        
        setLoading(false);
      } catch (error: any) {
        setError(`구글 로그인 중 예기치 않은 오류가 발생했습니다: ${error.message || '알 수 없는 오류'}`);
        setLoading(false);
      }
      return;
    }
    
    // Kakao, WeChat 처리
    try {
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
        router.push(`/login?error=oauth_error&provider=${provider}`);
        return;
      }

      const { url, error: oauthError } = await res.json();

      if (oauthError || !url) {
        router.push(`/login?error=oauth_error&provider=${provider}`);
        return;
      }

      window.location.href = url;
    } catch (error) {
      router.push(`/login?error=oauth_error&provider=${provider}`);
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
