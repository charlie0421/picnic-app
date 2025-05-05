'use client';

import { useState, useEffect, Suspense } from 'react';
import { createBrowserSupabaseClient } from '@/utils/supabase-client';
import Image from 'next/image';
import { useRouter, useSearchParams } from 'next/navigation';
import { useLanguageStore } from '@/stores/languageStore';

// PKCE 유틸리티 함수
function generateCodeVerifier(): string {
  const array = new Uint8Array(64);
  crypto.getRandomValues(array);
  return Array.from(array)
    .map(b => String.fromCharCode(b % 26 + 97))
    .join('');
}

async function generateCodeChallenge(verifier: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(verifier);
  const digest = await crypto.subtle.digest("SHA-256", data);
  
  // Base64 URL 인코딩
  return btoa(Array.from(new Uint8Array(digest))
    .map(byte => String.fromCharCode(byte))
    .join(''))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function LoginContent() {
  const [supabase] = useState(() => createBrowserSupabaseClient());
  const router = useRouter();
  const searchParams = useSearchParams();
  const { t } = useLanguageStore();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const error = searchParams.get('error');
    const errorDescription = searchParams.get('error_description');
    const provider = searchParams.get('provider');

    console.log('Login Error:', {
      error,
      errorDescription,
      provider,
      searchParams: Object.fromEntries(searchParams.entries()),
    });

    if (error) {
      switch (error) {
        case 'missing_params':
          setError('필수 파라미터가 누락되었습니다.');
          console.error('Missing Parameters Error:', {
            error,
            errorDescription,
            provider,
            searchParams: Object.fromEntries(searchParams.entries()),
          });
          break;
        case 'server_error':
          setError(`서버 오류가 발생했습니다: ${errorDescription || '알 수 없는 오류'}`);
          console.error('Server Error:', {
            error,
            errorDescription,
            provider,
            searchParams: Object.fromEntries(searchParams.entries()),
          });
          break;
        case 'oauth_error':
          if (provider === 'apple') {
            setError('Apple 로그인 중 오류가 발생했습니다. 다시 시도해주세요.');
            console.error('Apple OAuth Error:', {
              error,
              errorDescription,
              provider,
              searchParams: Object.fromEntries(searchParams.entries()),
            });
          } else {
            setError('소셜 로그인 중 오류가 발생했습니다.');
            console.error('OAuth Error:', {
              error,
              errorDescription,
              provider,
              searchParams: Object.fromEntries(searchParams.entries()),
            });
          }
          break;
        case 'callback_error':
          setError('인증 처리 중 오류가 발생했습니다.');
          console.error('Callback Error:', {
            error,
            errorDescription,
            provider,
            searchParams: Object.fromEntries(searchParams.entries()),
          });
          break;
        default:
          setError('알 수 없는 오류가 발생했습니다.');
          console.error('Unknown Error:', {
            error,
            errorDescription,
            provider,
            searchParams: Object.fromEntries(searchParams.entries()),
          });
      }
    }
  }, [searchParams]);

  const handleSignIn = async (
    provider: 'google' | 'apple' | 'kakao' | 'wechat',
  ) => {
    console.log('Sign in attempt with provider:', provider);

    if (provider === 'google' || provider === 'apple') {
      const redirectUrl = provider === 'apple' 
        ? 'https://www.picnic.fan/auth/callback/apple'
        : `${window.location.origin}/auth/callback/${provider}`;

      console.log('Supabase OAuth Configuration:', {
        provider,
        redirectUrl,
        explicitRedirect: 'https://www.picnic.fan/auth/callback/apple',
        dynamicRedirect: `${window.location.origin}/auth/callback/${provider}`,
        flowType: 'pkce',
        origin: window.location.origin,
        hostName: window.location.hostname,
        supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL,
      });

      try {
        // Apple 로그인에 대해서는 PKCE 코드 검증자를 명시적으로 생성
        if (provider === 'apple') {
          // PKCE 코드 검증자 생성
          const codeVerifier = generateCodeVerifier();
          const codeChallenge = await generateCodeChallenge(codeVerifier);
          
          console.log('Generated PKCE parameters:', {
            verifierLength: codeVerifier.length,
            challengeLength: codeChallenge.length,
          });
          
          // 로컬 스토리지에 코드 검증자 저장 (후에 검증할 때 사용)
          localStorage.setItem('pkce_code_verifier', codeVerifier);
          
          // state 객체 생성
          const stateObj = {
            redirect_url: 'https://www.picnic.fan',
            provider: 'apple',
            timestamp: Date.now(),
            flow_state_id: crypto.randomUUID(),
            code_verifier: codeVerifier,
            code_challenge: codeChallenge,
            returnTo: window.location.pathname,
          };
          
          const encodedState = btoa(JSON.stringify(stateObj));
          
          // state 객체를 세션 스토리지에도 저장 (콜백에서 비교용)
          sessionStorage.setItem('apple_oauth_state', encodedState);
          sessionStorage.setItem('apple_code_verifier', codeVerifier);
          
          // Apple OAuth URL 직접 구성
          const appleAuthUrl = new URL('https://appleid.apple.com/auth/authorize');
          appleAuthUrl.searchParams.append('client_id', 'fan.picnic.web');
          appleAuthUrl.searchParams.append('redirect_uri', 'https://www.picnic.fan/auth/callback/apple');
          appleAuthUrl.searchParams.append('response_type', 'code');
          appleAuthUrl.searchParams.append('response_mode', 'form_post');
          appleAuthUrl.searchParams.append('scope', 'name email');
          appleAuthUrl.searchParams.append('code_challenge', codeChallenge);
          appleAuthUrl.searchParams.append('code_challenge_method', 'S256');
          appleAuthUrl.searchParams.append('state', encodedState);
          
          console.log('Constructed Apple OAuth URL:', appleAuthUrl.toString());
          
          // Apple 로그인 페이지로 리다이렉트
          window.location.href = appleAuthUrl.toString();
          return;
          
        } else {
          // Google 등 다른 로그인 방식
          const { error } = await supabase.auth.signInWithOAuth({
            provider,
            options: {
              redirectTo: `${window.location.origin}/auth/callback/${provider}`,
            },
          });
          
          if (error) {
            console.error(`${provider} Sign In Error:`, {
              provider,
              error,
            });
            router.push('/auth/error');
          }
        }
        return;
      } catch (error) {
        console.error(`Unexpected ${provider} Sign In Error:`, {
          provider,
          error,
        });
        router.push('/auth/error');
        return;
      }
    }

    try {
      console.log('Fetching OAuth URL for provider:', provider);
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

      console.log('OAuth URL Response:', {
        provider,
        status: res.status,
        statusText: res.statusText,
      });

      if (!res.ok) {
        const errorData = await res.json();
        console.error('OAuth URL Request Failed:', {
          provider,
          status: res.status,
          error: errorData,
        });
        router.push(`/login?error=oauth_error&provider=${provider}`);
        return;
      }

      const { url, error: oauthError } = await res.json();

      console.log('OAuth URL Result:', {
        provider,
        url,
        error: oauthError,
      });

      if (oauthError || !url) {
        console.error('OAuth URL Error:', {
          provider,
          error: oauthError,
          url,
        });
        router.push(`/login?error=oauth_error&provider=${provider}`);
        return;
      }

      window.location.href = url;
    } catch (error) {
      console.error('Unexpected OAuth Error:', {
        provider,
        error,
      });
      router.push(`/login?error=oauth_error&provider=${provider}`);
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
      </div>
    </div>
  );
}

export default function Login() {
  return (
    <Suspense
      fallback={
        <div className='min-h-screen flex items-center justify-center bg-gray-50'>
          <div className='max-w-md w-full space-y-8 p-8 bg-white rounded-xl shadow-lg'>
            <div className='text-center'>
              <h2 className='mt-6 text-3xl font-extrabold text-gray-900'>
                로딩 중...
              </h2>
            </div>
          </div>
        </div>
      }
    >
      <LoginContent />
    </Suspense>
  );
}
