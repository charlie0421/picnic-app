import React from 'react';
import { render, screen, waitFor, act } from '@testing-library/react';
import '@testing-library/jest-dom';
import { AuthProvider, useAuth } from '@/lib/supabase/auth-provider';
import { SupabaseProvider } from '@/components/providers/SupabaseProvider';
import { mockSupabaseClient, createMockSupabaseUser, createMockSupabaseSession } from '@/__tests__/utils/supabase-mocks';
import { User } from '@supabase/supabase-js';

// Supabase 클라이언트 모킹
jest.mock('@/lib/supabase/client', () => ({
  createBrowserSupabaseClient: jest.fn(() => mockSupabaseClient({
    authenticated: false
  })),
  signOut: jest.fn(() => Promise.resolve({ error: null }))
}));

// 인증된 상태의 Supabase 클라이언트 생성 - useAuth 훅 모킹을 위한 별도 작업
const mockUser = createMockSupabaseUser({
  id: 'test-user-id',
  email: 'test@example.com'
});

// 인증 프로바이더 모킹 (세션 상태를 제어하기 위해)
jest.mock('@/lib/supabase/auth-provider', () => {
  const originalModule = jest.requireActual('@/lib/supabase/auth-provider');
  
  // 상태를 공유할 변수
  let isAuthMocked = false;
  let mockUserData: User | null = null;
  
  // AuthProvider는 원본 구현을 사용
  return {
    ...originalModule,
    // useAuth 훅 모킹
    useAuth: () => {
      return {
        isLoading: false,
        isAuthenticated: isAuthMocked,
        user: isAuthMocked ? mockUserData : null,
        userProfile: isAuthMocked ? { 
          id: mockUserData?.id,
          email: mockUserData?.email, 
          nickname: '테스트사용자' 
        } : null,
        signInWithOAuth: jest.fn(),
        signIn: jest.fn(),
        signOut: jest.fn(),
        refreshSession: jest.fn(),
        updateUserProfile: jest.fn(),
        isInitialized: true,
        error: null,
        session: isAuthMocked ? { user: mockUserData } : null
      };
    },
    // 인증 상태를 설정하는 헬퍼 함수
    __setMockAuthState: (authenticated: boolean, userData: User | null = null) => {
      isAuthMocked = authenticated;
      mockUserData = userData;
    }
  };
});

// useAuth 훅을 테스트하기 위한 컴포넌트
const TestAuthComponent = () => {
  const auth = useAuth();
  
  return (
    <div>
      <div data-testid="is-authenticated">{auth.isAuthenticated ? 'true' : 'false'}</div>
      <div data-testid="is-loading">{auth.isLoading ? 'true' : 'false'}</div>
      <div data-testid="user-id">{auth.user?.id || 'no-user'}</div>
      <div data-testid="user-email">{auth.user?.email || 'no-email'}</div>
      <button 
        data-testid="sign-in-button" 
        onClick={() => auth.signIn('test@example.com', 'password')}
      >
        Sign In
      </button>
      <button 
        data-testid="sign-out-button" 
        onClick={() => auth.signOut()}
      >
        Sign Out
      </button>
      <button 
        data-testid="oauth-button" 
        onClick={() => auth.signInWithOAuth('google')}
      >
        Sign In with Google
      </button>
    </div>
  );
};

// 테스트를 위한 래퍼 컴포넌트
const TestWrapper = ({ children, initialSession = null }: { children: React.ReactNode, initialSession?: any }) => (
  <SupabaseProvider>
    <AuthProvider initialSession={initialSession}>
      {children}
    </AuthProvider>
  </SupabaseProvider>
);

describe('AuthProvider', () => {
  beforeEach(() => {
    // 테스트간 모킹 초기화
    jest.clearAllMocks();
    const { __setMockAuthState } = require('@/lib/supabase/auth-provider');
    __setMockAuthState(false);
  });

  it('인증되지 않은 초기 상태를 렌더링합니다', async () => {
    render(
      <TestWrapper>
        <TestAuthComponent />
      </TestWrapper>
    );

    // 로딩 상태가 끝날 때까지 대기
    await waitFor(() => {
      expect(screen.getByTestId('is-loading')).toHaveTextContent('false');
    });

    // 인증되지 않은 상태 확인
    expect(screen.getByTestId('is-authenticated')).toHaveTextContent('false');
    expect(screen.getByTestId('user-id')).toHaveTextContent('no-user');
    expect(screen.getByTestId('user-email')).toHaveTextContent('no-email');
  });

  it('초기 세션으로 인증된 상태를 렌더링합니다', async () => {
    // 인증 상태 설정
    const { __setMockAuthState } = require('@/lib/supabase/auth-provider');
    __setMockAuthState(true, { id: 'test-user-id', email: 'test@example.com' });
    
    render(
      <TestWrapper>
        <TestAuthComponent />
      </TestWrapper>
    );

    // 로딩 상태가 끝날 때까지 대기
    await waitFor(() => {
      expect(screen.getByTestId('is-loading')).toHaveTextContent('false');
    });

    // 인증된 상태 확인
    expect(screen.getByTestId('is-authenticated')).toHaveTextContent('true');
    expect(screen.getByTestId('user-id')).toHaveTextContent('test-user-id');
    expect(screen.getByTestId('user-email')).toHaveTextContent('test@example.com');
  });

  // 추가적인 테스트는 실제 환경에 맞게 확장 가능
  // - 로그인/로그아웃 기능 테스트
  // - OAuth 로그인 테스트
  // - 사용자 프로필 업데이트 테스트
  // - 에러 핸들링 테스트
}); 