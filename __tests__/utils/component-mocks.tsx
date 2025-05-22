import React, { ReactNode } from 'react';
import { useLanguageStore } from '@/stores/languageStore';

// Next/Image 모킹
jest.mock('next/image', () => ({
  __esModule: true,
  default: (props: any) => {
    // eslint-disable-next-line @next/next/no-img-element
    return <img {...props} alt={props.alt || ''} />;
  },
}));

// 모의 언어 저장소 및 컨텍스트
export const mockLanguageStore = {
  currentLanguage: 'ko',
  translations: {},
  isLoading: false,
  error: null,
  isTranslationLoaded: { ko: true, en: true, ja: true, zh: true, id: true },
  setLanguage: jest.fn(),
  syncLanguageWithPath: jest.fn(),
  t: jest.fn((key: string) => key),
  loadTranslations: jest.fn(),
};

// 언어 저장소 모킹
jest.mock('@/stores/languageStore', () => ({
  useLanguageStore: jest.fn(() => mockLanguageStore),
  // getState도 모킹해야 할 경우
  getState: jest.fn(() => mockLanguageStore),
}));

// 모의 Auth 컨텍스트 상태
type MockUser = {
  id: string;
  email: string | null;
  nickname?: string | null;
  avatarUrl?: string | null;
  [key: string]: any;
};

interface MockAuthState {
  isAuthenticated: boolean;
  user: MockUser | null;
  userProfile: any | null;
  session: any | null;
  isLoading: boolean;
  isInitialized: boolean;
  error: string | null;
}

export const mockAuthState: MockAuthState = {
  isAuthenticated: false,
  user: null,
  userProfile: null,
  session: null,
  isLoading: false,
  isInitialized: true,
  error: null,
};

// Auth Provider 모킹
export const MockAuthProvider = ({ children }: { children: ReactNode }) => {
  return (
    <div data-testid="mock-auth-provider">
      {children}
    </div>
  );
};

// Navigation Provider 모킹
export const MockNavigationProvider = ({ children }: { children: ReactNode }) => {
  return (
    <div data-testid="mock-navigation-provider">
      {children}
    </div>
  );
};

// Auth Provider 모킹
jest.mock('@/lib/supabase/auth-provider', () => ({
  AuthProvider: ({ children }: { children: ReactNode }) => (
    <MockAuthProvider>
      {children}
    </MockAuthProvider>
  ),
  useAuth: jest.fn(() => ({
    ...mockAuthState,
    signIn: jest.fn(),
    signInWithOAuth: jest.fn(),
    signUp: jest.fn(),
    signOut: jest.fn(),
    refreshSession: jest.fn(),
    updateUserProfile: jest.fn(),
  })),
}));

// Navigation Provider 모킹
jest.mock('@/contexts/NavigationContext', () => ({
  NavigationProvider: ({ children }: { children: ReactNode }) => (
    <MockNavigationProvider>
      {children}
    </MockNavigationProvider>
  ),
  useNavigation: jest.fn(() => ({
    isNavigating: false,
    startNavigation: jest.fn(),
    endNavigation: jest.fn(),
  })),
}));

// next-intl 모킹
jest.mock('next-intl', () => ({
  useTranslations: jest.fn(() => (key: string) => key),
  useLocale: jest.fn(() => 'ko'),
}));

// 테스트용 Mock 데이터
export const mockData = {
  // 사용자 데이터
  users: [
    { id: 'user-1', email: 'user1@example.com', nickname: '사용자1' },
    { id: 'user-2', email: 'user2@example.com', nickname: '사용자2' },
  ],
  
  // 투표 데이터
  votes: [
    { id: 'vote-1', title: '투표 제목 1', description: '투표 설명 1', created_by: 'user-1' },
    { id: 'vote-2', title: '투표 제목 2', description: '투표 설명 2', created_by: 'user-2' },
  ],
};

// 인증 상태 설정 헬퍼
export function setMockAuthState(authenticated: boolean, user?: MockUser) {
  if (authenticated && user) {
    mockAuthState.isAuthenticated = true;
    mockAuthState.user = user;
  } else if (authenticated) {
    mockAuthState.isAuthenticated = true;
    mockAuthState.user = {
      id: 'test-user-id',
      email: 'test@example.com',
    };
  } else {
    mockAuthState.isAuthenticated = false;
    mockAuthState.user = null;
  }
}

// 언어 설정 헬퍼
export function setMockLanguage(language: string) {
  mockLanguageStore.currentLanguage = language;
  (useLanguageStore as unknown as jest.Mock).mockReturnValue({
    ...mockLanguageStore,
    currentLanguage: language,
  });
} 