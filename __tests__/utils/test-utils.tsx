import React, { ReactElement } from 'react';
import { render as rtlRender, RenderOptions as RTLRenderOptions } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { SupabaseProvider } from '@/components/providers/SupabaseProvider';
import { mockSupabaseClient } from './supabase-mocks';

// 모의 언어 저장소 및 컨텍스트
export const createMockLanguageStore = (currentLanguage = 'ko') => {
  return {
    getState: jest.fn(() => ({
      currentLanguage,
      availableLanguages: ['ko', 'en', 'ja', 'zh'],
      setLanguage: jest.fn(),
    })),
    setState: jest.fn(),
    subscribe: jest.fn(),
    destroy: jest.fn(),
  };
};

// 테스트에 필요한 모든 프로바이더를 포함하는 컴포넌트
interface AllProvidersProps {
  children: React.ReactNode;
  mockUser?: any; // 필요한 경우 타입 구체화
  authenticated?: boolean;
}

export const AllProviders = ({
  children,
  mockUser = null,
  authenticated = false,
}: AllProvidersProps) => {
  // Supabase 클라이언트 모킹
  const supabase = mockSupabaseClient({
    authenticated,
    userData: mockUser,
  });

  return (
    <SupabaseProvider>
      {children}
    </SupabaseProvider>
  );
};

// 커스텀 렌더 함수 (Testing Library의 render 함수 확장)
interface CustomRenderOptions extends Omit<RTLRenderOptions, 'wrapper'> {
  mockUser?: any;
  authenticated?: boolean;
}

export function customRender(
  ui: ReactElement,
  {
    mockUser = null,
    authenticated = false,
    ...renderOptions
  }: CustomRenderOptions = {}
) {
  return rtlRender(ui, {
    wrapper: (props) => (
      <AllProviders
        mockUser={mockUser}
        authenticated={authenticated}
        {...props}
      />
    ),
    ...renderOptions,
  });
}

// Testing Library의 다른 함수들을 재내보내기
export * from '@testing-library/react';
export { customRender as render };

// 유용한 테스트 헬퍼 함수들
export const waitForComponentToLoad = async () => {
  // 비동기 컴포넌트가 로드될 때까지 대기하는 유틸리티
  return new Promise((resolve) => setTimeout(resolve, 0));
};

export const createMockRouter = (overrides: Record<string, unknown> = {}) => ({
  push: jest.fn(),
  replace: jest.fn(),
  prefetch: jest.fn(),
  back: jest.fn(),
  forward: jest.fn(),
  refresh: jest.fn(),
  pathname: '/',
  query: {},
  asPath: '/',
  ...overrides,
});

export const createMockAuthContext = (overrides: Record<string, unknown> = {}) => ({
  user: null,
  session: null,
  isLoading: false,
  signOut: jest.fn(),
  signInWithSocial: jest.fn(),
  ...overrides,
});

// 비동기 컴포넌트 테스트를 위한 유틸리티
export const renderWithAct = async (ui: ReactElement, options = {}) => {
  const result = customRender(ui, options);
  await waitForComponentToLoad();
  return result;
};

// 모킹된 localStorage 헬퍼
export const mockLocalStorage = () => {
  const storeObj: Record<string, string> = {};
  return {
    getItem: jest.fn((key: string) => storeObj[key] || null),
    setItem: jest.fn((key: string, value: string) => {
      storeObj[key] = value.toString();
    }),
    removeItem: jest.fn((key: string) => {
      delete storeObj[key];
    }),
    clear: jest.fn(() => {
      Object.keys(storeObj).forEach((key) => {
        delete storeObj[key];
      });
    }),
    store: storeObj,
  };
};

// 테스트 데이터 생성 헬퍼
export const createTestUser = (overrides: Record<string, unknown> = {}) => ({
  id: 'test-user-id',
  email: 'test@example.com',
  user_metadata: {
    full_name: 'Test User',
    avatar_url: 'https://example.com/avatar.jpg',
  },
  app_metadata: {
    provider: 'google',
  },
  aud: 'authenticated',
  ...overrides,
}); 