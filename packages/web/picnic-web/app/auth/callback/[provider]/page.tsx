'use client';

import { useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { createBrowserSupabaseClient } from '@/lib/supabase/client';

export default function AuthCallbackPage() {
  const router = useRouter();
  const params = useParams();
  const provider = params.provider as string;

  useEffect(() => {
    const handleCallback = async () => {
      try {
        // 페이지 로드 시 즉시 Supabase 클라이언트 초기화
        const supabase = createBrowserSupabaseClient();
        
        // URL에서 인증 코드와 상태를 가져오기
        const { data, error } = await supabase.auth.getSession();
        
        if (error) {
          console.error('콜백 처리 중 오류:', error.message);
          throw error;
        }

        if (data.session) {
          console.log(`✅ ${provider} 로그인 성공:`, data.session.user.id);
          
          // 로컬 스토리지에 인증 성공 정보 저장
          localStorage.setItem('auth_success', 'true');
          localStorage.setItem('auth_provider', provider);
          localStorage.setItem('auth_timestamp', Date.now().toString());
          
          // 리다이렉트 (홈페이지 또는 이전 페이지)
          const returnUrl = localStorage.getItem('auth_return_url') || '/';
          router.push(returnUrl);
          localStorage.removeItem('auth_return_url'); // 사용 후 제거
        } else {
          console.warn('세션이 없습니다. 인증 프로세스가 완료되지 않았습니다.');
          // 로그인 페이지로 리다이렉트
          router.push('/login?error=callback_failed');
        }
      } catch (error) {
        console.error('소셜 로그인 콜백 처리 오류:', error);
        router.push('/login?error=callback_error');
      }
    };

    // 컴포넌트 마운트 시 콜백 처리 실행
    handleCallback();
  }, [provider, router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full p-6 bg-white rounded-lg shadow-md">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-gray-800 mb-4">로그인 처리 중...</h2>
          <div className="flex justify-center">
            <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary-500"></div>
          </div>
          <p className="mt-4 text-gray-600">
            {provider.charAt(0).toUpperCase() + provider.slice(1)} 계정으로 로그인을 완료하고 있습니다.
            <br />잠시만 기다려주세요.
          </p>
        </div>
      </div>
    </div>
  );
} 