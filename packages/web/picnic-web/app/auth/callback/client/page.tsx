'use client';

import { useEffect, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { createBrowserSupabaseClient } from '@/utils/supabase-client';

function AuthCallbackContent() {
  const router = useRouter();
  const supabase = createBrowserSupabaseClient();
  const searchParams = useSearchParams();

  useEffect(() => {
    const handleCallback = async () => {
      try {
        const code = searchParams.get('code');
        const state = searchParams.get('state');

        if (!code) {
          console.error('OAuth 코드가 없습니다.');
          router.push('/login');
          return;
        }

        // Apple OAuth 토큰 교환
        const { data, error } = await supabase.auth.signInWithOAuth({
          provider: 'apple',
          options: {
            redirectTo: 'https://api.picnic.fan/auth/callback',
            queryParams: {
              code,
              state,
            },
          },
        });

        if (error) {
          console.error('인증 에러:', error);
          router.push('/login');
          return;
        }

        if (!data?.session) {
          console.error('세션이 생성되지 않았습니다.');
          router.push('/login');
          return;
        }

        // 리다이렉트
        window.location.href = '/';
      } catch (error) {
        console.error('콜백 처리 중 오류:', error);
        router.push('/login');
      }
    };

    handleCallback();
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