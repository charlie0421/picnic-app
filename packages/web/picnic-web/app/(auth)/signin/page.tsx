'use client';

import { useState } from 'react';
import { createBrowserSupabaseClient } from '@/utils/supabase-client';
import Image from 'next/image';
import { useRouter } from 'next/navigation';
import { useLanguageStore } from '@/stores/languageStore';

export default function SignIn() {
  const [supabase] = useState(() => createBrowserSupabaseClient());
  const router = useRouter();
  const { t } = useLanguageStore();

  const handleSignIn = async (provider: 'google' | 'apple' | 'kakao') => {
    const { error } = await supabase.auth.signInWithOAuth({
      provider,
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
            {t('text_login_title')}
          </h2>
        </div>
        <div className="mt-8 space-y-4">
          <button
            onClick={() => handleSignIn('google')}
            className="w-full flex items-center justify-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
          >
            <Image
              src="/images/google-logo.png"
              alt="Google"
              width={20}
              height={20}
              className="mr-2"
            />
            Google로 계속하기
          </button>
          
          <button
            onClick={() => handleSignIn('apple')}
            className="w-full flex items-center justify-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
          >
            <Image
              src="/images/apple-logo.png"
              alt="Apple"
              width={20}
              height={20}
              className="mr-2"
            />
            Apple로 계속하기
          </button>
          
          <button
            onClick={() => handleSignIn('kakao')}
            className="w-full flex items-center justify-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
          >
            <Image
              src="/images/kakao-logo.png"
              alt="Kakao"
              width={20}
              height={20}
              className="mr-2"
            />
            카카오로 계속하기
          </button>
        </div>
      </div>
    </div>
  );
} 