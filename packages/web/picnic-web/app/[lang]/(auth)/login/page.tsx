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
    if (error) {
      switch (error) {
        case 'missing_params':
          setError('필수 파라미터가 누락되었습니다.');
          break;
        case 'oauth_error':
          setError('소셜 로그인 중 오류가 발생했습니다.');
          break;
        case 'callback_error':
          setError('인증 처리 중 오류가 발생했습니다.');
          break;
        default:
          setError('알 수 없는 오류가 발생했습니다.');
      }
    }
  }, [searchParams]);

  const handleSignIn = async (
    provider: 'google' | 'apple' | 'kakao' | 'wechat',
  ) => {
    console.log('provider', provider);
    if (provider === 'google') {
      // 구글은 Supabase 기본 처리 유지 (원한다면 custom으로도 가능)
      const { error } = await supabase.auth.signInWithOAuth({
        provider,
        options: {
          redirectTo: `${window.location.origin}/auth/callback/google`,
        },
      });

      if (error) {
        console.error('Google Error:', error.message);
        router.push('/auth/error');
      }
      return;
    }

    // Apple, Kakao, WeChat은 Custom Edge Function 처리
    const res = await fetch(
      `https://api.picnic.fan/functions/v1/${provider}-web-oauth`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          url: window.location.origin + '/auth/callback/' + provider,
        }),
        credentials: 'include',
      },
    );

    console.log('res', res);

    const { url, error: oauthError } = await res.json();

    console.log('url', url);
    console.log('error', oauthError);

    if (oauthError || !url) {
      console.error(`${provider} OAuth URL Error:`, oauthError);
      router.push('/auth/error');
      return;
    }

    window.location.href = url;
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
