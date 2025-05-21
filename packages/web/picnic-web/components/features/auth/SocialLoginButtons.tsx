'use client';

import React, { useState } from 'react';
import Image from 'next/image';
import { useAuth } from '@/lib/supabase/auth-provider';
import { useLanguageStore } from '@/stores/languageStore';

type SocialLoginProvider = 'google' | 'apple' | 'kakao' | 'wechat';

interface SocialLoginButtonsProps {
  onSuccess?: () => void;
  onError?: (error: Error) => void;
  className?: string;
  size?: 'small' | 'medium' | 'large';
  showLabels?: boolean;
  providers?: SocialLoginProvider[];
}

const SocialLoginButtons: React.FC<SocialLoginButtonsProps> = ({
  onSuccess,
  onError,
  className = '',
  size = 'medium',
  showLabels = true,
  providers = ['google', 'apple', 'kakao', 'wechat']
}) => {
  const { signInWithOAuth } = useAuth();
  const [isLoading, setIsLoading] = useState<SocialLoginProvider | null>(null);
  const { t } = useLanguageStore();

  // 버튼 크기 및 스타일 설정
  const buttonSize = {
    small: 'h-9 px-3 text-sm gap-2',
    medium: 'h-11 px-4 text-base gap-3',
    large: 'h-14 px-5 text-lg gap-4'
  }[size];

  const iconSize = {
    small: 16,
    medium: 20,
    large: 24
  }[size];

  // 소셜 로그인 처리
  const handleSocialLogin = async (provider: SocialLoginProvider) => {
    try {
      // 이미 로딩 중일 때는 중복 호출 방지
      if (isLoading !== null) {
        console.log(`이미 ${isLoading} 로그인 처리중입니다. ${provider} 로그인 요청 무시`);
        return;
      }
      
      // 로그인 시도 전에 현재 페이지 URL을 저장 (로그인 후 되돌아올 수 있도록)
      localStorage.setItem('auth_return_url', window.location.pathname);
      
      setIsLoading(provider);
      const { error } = await signInWithOAuth(provider);
      
      if (error) {
        console.error(`${provider} 로그인 오류:`, error);
        onError?.(error);
      } else {
        // 성공 콜백 (리디렉션 전에 실행)
        onSuccess?.();
      }
    } catch (error) {
      console.error(`${provider} 로그인 처리 중 오류:`, error);
      onError?.(error instanceof Error ? error : new Error(String(error)));
    } finally {
      // 2초 후에 로딩 상태 해제 (너무 빠른 연속 클릭 방지)
      setTimeout(() => {
        setIsLoading(null);
      }, 2000);
    }
  };

  // 각 소셜 로그인 버튼의 스타일 및 내용 설정
  const providerConfig: Record<SocialLoginProvider, {
    label: string;
    bgColor: string;
    textColor: string;
    hoverColor: string;
    iconPath: string;
    borderColor?: string;
  }> = {
    google: {
      label: t('label_login_with_google') || '구글로 로그인',
      bgColor: 'bg-white',
      textColor: 'text-gray-700',
      hoverColor: 'hover:bg-gray-50',
      iconPath: '/images/auth/google-logo.svg',
      borderColor: 'border-gray-300'
    },
    apple: {
      label: t('label_login_with_apple') || '애플로 로그인',
      bgColor: 'bg-black',
      textColor: 'text-white',
      hoverColor: 'hover:bg-gray-900',
      iconPath: '/images/auth/apple-logo.svg'
    },
    kakao: {
      label: t('label_login_with_kakao') || '카카오로 로그인',
      bgColor: 'bg-yellow-400',
      textColor: 'text-gray-900',
      hoverColor: 'hover:bg-yellow-500',
      iconPath: '/images/auth/kakao-logo.svg'
    },
    wechat: {
      label: t('label_login_with_wechat') || '위챗으로 로그인',
      bgColor: 'bg-green-500',
      textColor: 'text-white',
      hoverColor: 'hover:bg-green-600',
      iconPath: '/images/auth/wechat-logo.svg'
    }
  };

  return (
    <div className={`flex flex-col space-y-3 w-full ${className}`}>
      {providers.map(provider => {
        const config = providerConfig[provider];
        const loading = isLoading === provider;
        
        return (
          <button
            key={provider}
            onClick={() => handleSocialLogin(provider)}
            disabled={isLoading !== null}
            className={`flex items-center justify-center ${buttonSize} rounded-lg border 
                        transition-colors duration-300 ${config.bgColor} ${config.textColor} 
                        ${config.hoverColor} ${config.borderColor ? `border-${config.borderColor}` : 'border-transparent'}
                        disabled:opacity-70 disabled:cursor-not-allowed`}
          >
            {loading ? (
              <div className="animate-spin h-5 w-5 border-t-2 border-b-2 border-current rounded-full" />
            ) : (
              <>
                <Image 
                  src={config.iconPath} 
                  width={iconSize} 
                  height={iconSize} 
                  alt={`${provider} logo`} 
                  className="flex-shrink-0"
                />
                {showLabels && <span>{config.label}</span>}
              </>
            )}
          </button>
        );
      })}
    </div>
  );
};

export default SocialLoginButtons; 