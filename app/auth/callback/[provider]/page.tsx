'use client';

import { useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { getSocialAuthService } from '@/lib/supabase/social';
import type { SocialLoginProvider } from '@/lib/supabase/social/types';

export default function AuthCallbackPage({ params }: { params: { provider: string } }) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [error, setError] = useState<string | null>(null);
  const [status, setStatus] = useState<string>('인증 세션을 처리 중입니다...');

  useEffect(() => {
    const handleCallback = async () => {
      try {
        // URL 쿼리 파라미터 가져오기
        const provider = params.provider as SocialLoginProvider;
        
        // 오류 코드가 있으면 처리
        const errorCode = searchParams.get('error');
        if (errorCode) {
          setError(`인증 오류: ${errorCode}`);
          return;
        }
        
        // Apple은 특수한 처리가 필요함
        if (provider === 'apple') {
          // user 파라미터 (Apple은 첫 로그인 시에만 name 정보 제공)
          const userParam = searchParams.get('user');
          
          // state 파라미터 검증 (CSRF 방지용)
          const stateParam = searchParams.get('state');
          
          // id_token 파라미터
          const idTokenParam = searchParams.get('id_token');
          
          // 코드 파라미터
          const codeParam = searchParams.get('code');
          
          // 로그 출력
          console.log('Apple callback params:', { 
            user: userParam, 
            state: stateParam, 
            id_token: idTokenParam ? '[redacted]' : null,
            code: codeParam ? '[redacted]' : null 
          });
        }
        
        // 소셜 로그인 서비스 가져오기
        const socialAuthService = getSocialAuthService();
        
        // 콜백 처리
        setStatus('인증 처리 중...');
        
        // 모든 URL 파라미터를 객체로 변환
        const paramObj: Record<string, string> = {};
        searchParams.forEach((value, key) => {
          paramObj[key] = value;
        });
        
        // 콜백 처리 요청
        const authResult = await socialAuthService.handleCallback(provider, paramObj);
        
        // 결과 처리
        if (authResult.success) {
          setStatus('인증 성공! 리디렉션 중...');
          
          // 성공 후 이동할 URL 결정
          let returnUrl = '/';
          
          // 로컬 스토리지에서 리다이렉트 URL 가져오기
          if (typeof localStorage !== 'undefined') {
            const savedReturnUrl = localStorage.getItem('auth_return_url');
            if (savedReturnUrl) {
              returnUrl = savedReturnUrl;
              localStorage.removeItem('auth_return_url');
            }
          }
          
          // 인증 후 지정된 페이지로 리디렉션
          router.push(returnUrl);
        } else if (authResult.error) {
          setError(`인증 오류: ${authResult.error.message}`);
        } else {
          setError('알 수 없는 인증 오류가 발생했습니다.');
        }
      } catch (error) {
        console.error('콜백 처리 오류:', error);
        setError('인증 처리 중 오류가 발생했습니다.');
      }
    };
    
    handleCallback();
  }, [params.provider, router, searchParams]);

  // 에러 표시
  if (error) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center p-4 text-center">
        <h1 className="text-2xl font-bold mb-4">로그인 오류</h1>
        <p className="text-red-500 mb-6">{error}</p>
        <button
          onClick={() => router.push('/login')}
          className="px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors"
        >
          로그인으로 돌아가기
        </button>
      </div>
    );
  }

  // 로딩 표시
  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-4 text-center">
      <div className="animate-spin w-12 h-12 border-4 border-gray-200 border-t-blue-500 rounded-full mb-4"></div>
      <h1 className="text-xl font-medium mb-2">처리 중입니다</h1>
      <p className="text-gray-600">{status}</p>
    </div>
  );
} 