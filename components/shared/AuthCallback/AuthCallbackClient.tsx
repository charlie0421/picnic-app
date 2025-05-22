'use client';

import { useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { getSocialAuthService } from '@/lib/supabase/social';
import type { SocialLoginProvider } from '@/lib/supabase/social/types';
import { AuthCallbackSkeleton } from '@/components/server';
import { RetryButton } from '@/components/client';

interface AuthCallbackClientProps {
  provider: string;
}

export default function AuthCallbackClient({ provider }: AuthCallbackClientProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [error, setError] = useState<string | null>(null);
  const [status, setStatus] = useState<string>('인증 세션을 처리 중입니다...');

  useEffect(() => {
    const handleCallback = async () => {
      try {
        // URL 쿼리 파라미터 가져오기
        const providerType = provider as SocialLoginProvider;
        
        // 오류 코드가 있으면 처리
        const errorCode = searchParams.get('error');
        if (errorCode) {
          setError(`인증 오류: ${errorCode}`);
          return;
        }
        
        // Apple은 특수한 처리가 필요함
        if (providerType === 'apple') {
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
        const authResult = await socialAuthService.handleCallback(providerType, paramObj);
        
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
  }, [provider, router, searchParams]);

  if (error) {
    return (
      <AuthCallbackSkeleton 
        error={error} 
        onRetry={() => {}} // RetryButton 렌더링을 위한 더미 핸들러
      />
    );
  }

  return <AuthCallbackSkeleton status={status} />;
} 