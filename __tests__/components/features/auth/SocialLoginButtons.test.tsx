import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import SocialLoginButtons from '@/components/features/auth/SocialLoginButtons';
import { SupabaseProvider } from '@/components/providers/SupabaseProvider';
import { AuthProvider, useAuth } from '@/lib/supabase/auth-provider';
import { mockSupabaseClient } from '@/__tests__/utils/supabase-mocks';

// Supabase 클라이언트 모킹
jest.mock('@/lib/supabase/client', () => ({
  createBrowserSupabaseClient: jest.fn(() => mockSupabaseClient({
    authenticated: false
  })),
  signOut: jest.fn(() => Promise.resolve({ error: null }))
}));

// 소셜 로그인 서비스 모킹
const mockSignInWithProvider = jest.fn().mockResolvedValue({ success: true, error: null });

jest.mock('@/lib/supabase/social', () => ({
  getSocialAuthService: jest.fn(() => ({
    signInWithProvider: mockSignInWithProvider
  }))
}));

jest.mock('@/lib/supabase/auth-provider', () => ({
  AuthProvider: ({ children }: { children: React.ReactNode }) => <div data-testid="auth-provider">{children}</div>,
  useAuth: () => ({
    isLoading: false,
    isAuthenticated: false,
    user: null,
    userProfile: null,
    signInWithOAuth: jest.fn(),
    signIn: jest.fn(),
    signOut: jest.fn(),
    refreshSession: jest.fn(),
    updateUserProfile: jest.fn(),
    isInitialized: true,
    error: null,
    session: null
  })
}));

jest.mock('@/stores/languageStore', () => ({
  useLanguageStore: () => ({
    t: jest.fn((key: string) => {
      const translations: Record<string, string> = {
        'label_login_with_google': 'Google로 시작하기',
        'label_login_with_apple': 'Apple로 시작하기',
        'label_login_with_kakao': '카카오로 시작하기',
        'label_login_with_wechat': 'WeChat으로 시작하기'
      };
      return translations[key] || key;
    }),
    currentLanguage: 'ko'
  })
}));

// 테스트 컴포넌트 래퍼
const TestWrapper = ({ children }: { children: React.ReactNode }) => (
  <SupabaseProvider>
    <AuthProvider>
      {children}
    </AuthProvider>
  </SupabaseProvider>
);

describe('SocialLoginButtons', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('렌더링하면 소셜 로그인 버튼이 표시됩니다', () => {
    render(
      <TestWrapper>
        <SocialLoginButtons />
      </TestWrapper>
    );

    // 각 소셜 로그인 버튼이 존재하는지 확인
    expect(screen.getByText('Google로 시작하기')).toBeInTheDocument();
    expect(screen.getByText('Apple로 시작하기')).toBeInTheDocument();
    expect(screen.getByText('카카오로 시작하기')).toBeInTheDocument();

    // WeChat 버튼은 기본적으로 비활성화되어 있음
    expect(screen.queryByText('WeChat으로 시작하기')).not.toBeInTheDocument();
  });

  it('구글 로그인 버튼을 클릭하면 handleSocialLogin이 호출됩니다', async () => {
    const onLoginStart = jest.fn();
    const onError = jest.fn();

    render(
      <TestWrapper>
        <SocialLoginButtons 
          onLoginStart={onLoginStart}
          onError={onError}
        />
      </TestWrapper>
    );

    const googleButton = screen.getByText('Google로 시작하기');
    fireEvent.click(googleButton);

    // onLoginStart 콜백이 호출되었는지 확인
    expect(onLoginStart).toHaveBeenCalled();
    
    // getSocialAuthService().signInWithProvider가 'google'로 호출되었는지 확인
    expect(mockSignInWithProvider).toHaveBeenCalledWith('google');
  });

  it('에러가 발생하면 onError 콜백이 호출됩니다', async () => {
    const onLoginStart = jest.fn();
    const onError = jest.fn();

    // signInWithProvider가 에러를 반환하도록 모킹 재설정
    mockSignInWithProvider.mockResolvedValueOnce({
      success: false,
      error: new Error('인증 에러')
    });

    render(
      <TestWrapper>
        <SocialLoginButtons 
          onLoginStart={onLoginStart}
          onError={onError}
        />
      </TestWrapper>
    );

    const appleButton = screen.getByText('Apple로 시작하기');
    fireEvent.click(appleButton);

    // 에러 핸들링을 위한 시간 소요
    await new Promise(resolve => setTimeout(resolve, 0));

    // onError 콜백이 호출되었는지 확인
    expect(onError).toHaveBeenCalledWith(expect.any(Error));
  });
}); 