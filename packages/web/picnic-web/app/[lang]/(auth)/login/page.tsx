'use client';

import { useState, useEffect, useCallback } from 'react';
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

function LoginContent({ sdkScriptLoaded }: { sdkScriptLoaded: boolean }) {
  const [supabase] = useState(() => createBrowserSupabaseClient());
  const router = useRouter();
  const searchParams = useSearchParams();
  const { t } = useLanguageStore();
  const [error, setError] = useState<string | null>(null);
  const [appleSDKInitialized, setAppleSDKInitialized] = useState(false);
  const [loading, setLoading] = useState(true);
  
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
      // Apple SDK 초기화 - nonce 사용하지 않음
      const initOptions = {
        clientId: 'fan.picnic.web',
        scope: 'name email',
        redirectURI: `${window.location.origin}/auth/callback/apple`,
        usePopup: true,
        state: 'no-nonce'
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
    }
  };

  // 다른 소셜 로그인 처리 함수
  const handleOtherSignIn = async (provider: 'google' | 'kakao' | 'wechat') => {
    if (provider === 'google') {
      try {
        const { data, error } = await supabase.auth.signInWithOAuth({
          provider,
          options: {
            redirectTo: `${window.location.origin}/auth/callback/${provider}`,
          },
        });
        
        if (error) {
          router.push('/auth/error');
        } else if (data) {
          return handleAuthSuccess(data, provider);
        }
      } catch (error) {
        router.push('/auth/error');
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
          <div className='flex justify-center py-4'>
            <div className='animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900'></div>
          </div>
        ) : (
          <div className='mt-8 space-y-4'>
            <button
              onClick={() => handleSignIn('google')}
              className='flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50'
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
              className='flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-white bg-black border border-gray-300 rounded-md hover:bg-gray-800'
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
              className='flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-[#191919] bg-[#FEE500] rounded-md hover:bg-[#F4DC00]'
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
              className='flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-white bg-[#07C160] rounded-md hover:bg-[#06AD56]'
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
