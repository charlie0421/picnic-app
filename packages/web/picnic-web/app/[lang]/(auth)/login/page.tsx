'use client';

import { useState } from 'react';
import { createBrowserSupabaseClient } from '@/utils/supabase-client';
import Image from 'next/image';
import { useRouter } from 'next/navigation';
import { useLanguageStore } from '@/stores/languageStore';

export default function Login() {
  const [supabase] = useState(() => createBrowserSupabaseClient());
  const router = useRouter();
  const { t } = useLanguageStore();

  const handleSignIn = async (provider: 'google' | 'apple' | 'kakao' | 'wechat') => {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: provider as any,
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    });

    if (error) {
      console.error('Error:', error.message);
      router.push('/auth/error');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8 p-8 bg-white rounded-xl shadow-lg">
        <div className="text-center">
          <h2 className="mt-6 text-3xl font-extrabold text-gray-900">
            {t('button_login')}
          </h2>
        </div>
        <div className="mt-8 space-y-4">
          <button
            onClick={() => handleSignIn('google')}
            className="flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
          >
            <Image
              src="/images/auth/google-logo.svg"
              alt={`Google ${t('button_login')}`}
              width={20}
              height={20}
              className="mr-2"
            />
            Google {t('button_login')}
          </button>
          
          <button
            onClick={() => handleSignIn('apple')}
            className="flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
          >
            <Image
              src="/images/auth/apple-logo.svg"
              alt="Apple {t('button_login')}"
              width={20}
              height={20}
              className="mr-2"
            />
            Apple {t('button_login')}
          </button>
          
          <button
            onClick={() => handleSignIn('kakao')}
            className="flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
          >
            <Image
              src="/images/auth/kakao-logo.svg"
              alt="Kakao {t('button_login')}"
              width={20}
              height={20}
              className="mr-2"
            />
            Kakao {t('button_login')}
          </button>
          <button
            onClick={() => handleSignIn('wechat')}
            className="flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
          >
            <Image
              src="/images/auth/wechat-logo.svg"
              alt={`WeChat ${t('button_login')}`}
              width={20}
              height={20}
              className="mr-2"
            />
            WeChat {t('button_login')}
          </button>
        </div>
      </div>
    </div>
  );
} 