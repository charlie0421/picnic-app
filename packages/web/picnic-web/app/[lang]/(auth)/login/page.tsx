'use client';

import { useState, useEffect, Suspense } from 'react';
import { createBrowserSupabaseClient } from '@/utils/supabase-client';
import Image from 'next/image';
import { useRouter, useSearchParams } from 'next/navigation';
import { useLanguageStore } from '@/stores/languageStore';

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
      try {
        const { error } = await supabase.auth.signInWithOAuth({
          provider,
          options: {
            redirectTo: `${window.location.origin}/auth/callback/${provider}`,
          },
        });

        if (error) {
          console.error('Google Sign In Error:', {
            provider,
            error: error.message,
            code: error.status,
            details: error,
          });
          router.push('/auth/error');
        }
        return;
      } catch (error) {
        console.error('Unexpected Google Sign In Error:', {
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
