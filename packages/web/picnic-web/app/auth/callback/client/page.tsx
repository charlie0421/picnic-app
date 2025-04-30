'use client';

import { useEffect, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { createBrowserSupabaseClient } from '@/utils/supabase-client';

function AuthCallbackContent() {
  const router = useRouter();
  const supabase = createBrowserSupabaseClient();
  const searchParams = useSearchParams();

  useEffect(() => {
    const exchangeCode = async () => {
      const code = searchParams.get('code');
      const state = searchParams.get('state');

      if (code) {
        const { data, error } = await supabase.auth.exchangeCodeForSession(code);

        if (error) {
          console.error('세션 교환 에러:', error);
          router.push('/login');
          return;
        }

        if (data.session) {
          router.push('/');
        } else {
          router.push('/login');
        }
      } else {
        console.error('OAuth 코드가 없습니다.');
        router.push('/login');
      }
    };

    exchangeCode();
  }, [router, searchParams, supabase]);

  return (
    <div className="text-center">
      <h1 className="text-2xl font-bold mb-4">인증 처리 중...</h1>
      <p>잠시만 기다려주세요.</p>
    </div>
  );
}

export default function AuthCallback() {
  return (
    <div className="flex items-center justify-center min-h-screen">
      <Suspense fallback={
        <div className="text-center">
          <h1 className="text-2xl font-bold mb-4">로딩 중...</h1>
          <p>잠시만 기다려주세요.</p>
        </div>
      }>
        <AuthCallbackContent />
      </Suspense>
    </div>
  );
} 