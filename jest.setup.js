// Jest DOM 확장을 가져와 테스트에서 DOM 어설션을 사용할 수 있게 합니다
import '@testing-library/jest-dom'

// Next.js 내장 함수와 컴포넌트 모킹
jest.mock('next/navigation', () => ({
  useRouter: jest.fn(() => ({
    push: jest.fn(),
    replace: jest.fn(),
    back: jest.fn(),
    forward: jest.fn(),
    refresh: jest.fn(),
    prefetch: jest.fn(),
    pathname: '/',
    query: {},
  })),
  usePathname: jest.fn(() => '/'),
  useSearchParams: jest.fn(() => new URLSearchParams()),
  useParams: jest.fn(() => ({})),
}))

// Supabase SSR 모킹 (@supabase/ssr)
jest.mock('@supabase/ssr', () => ({
  createBrowserClient: jest.fn(() => ({
    auth: {
      getUser: jest.fn(() => ({ data: { user: null }, error: null })),
      getSession: jest.fn(() => ({ data: { session: null }, error: null })),
      signInWithOAuth: jest.fn(),
      signOut: jest.fn(),
      onAuthStateChange: jest.fn(() => ({ data: { subscription: { unsubscribe: jest.fn() } } })),
    },
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() => ({
          data: [],
          error: null,
        })),
      })),
    })),
  })),
  createServerClient: jest.fn(() => ({
    auth: {
      getUser: jest.fn(() => ({ data: { user: null }, error: null })),
      getSession: jest.fn(() => ({ data: { session: null }, error: null })),
    },
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() => ({
          data: [],
          error: null,
        })),
      })),
    })),
  })),
}))

// Supabase 클라이언트 모킹
jest.mock('@/lib/supabase/client', () => {
  const mockClient = {
    auth: {
      getUser: jest.fn(() => ({ data: { user: null }, error: null })),
      getSession: jest.fn(() => ({ data: { session: null }, error: null })),
      signInWithOAuth: jest.fn(),
      signOut: jest.fn(),
      onAuthStateChange: jest.fn(() => ({ data: { subscription: { unsubscribe: jest.fn() } } })),
    },
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() => ({
          data: [],
          error: null,
        })),
      })),
    })),
  };
  
  return {
    createBrowserSupabaseClient: jest.fn(() => mockClient),
    getCurrentUser: jest.fn(() => Promise.resolve(null)),
    getCurrentSession: jest.fn(() => Promise.resolve(null)),
    signOut: jest.fn(),
  };
})

// Supabase 서버 모킹
jest.mock('@/lib/supabase/server', () => {
  const mockServerClient = {
    auth: {
      getUser: jest.fn(() => ({ data: { user: null }, error: null })),
      getSession: jest.fn(() => ({ data: { session: null }, error: null })),
    },
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() => ({
          data: [],
          error: null,
        })),
      })),
    })),
  };
  
  return {
    createServerSupabaseClient: jest.fn(() => mockServerClient),
    getServerUser: jest.fn(() => Promise.resolve(null)),
    getServerSession: jest.fn(() => Promise.resolve(null)),
    withAuth: jest.fn((handler) => handler),
  };
})

// next-intl 모킹
jest.mock('next-intl', () => ({
  useTranslations: jest.fn(() => (key) => key),
  useLocale: jest.fn(() => 'ko'),
}))

// 로컬 스토리지 모킹
class LocalStorageMock {
  constructor() {
    this.store = {}
  }

  clear() {
    this.store = {}
  }

  getItem(key) {
    return this.store[key] || null
  }

  setItem(key, value) {
    this.store[key] = String(value)
  }

  removeItem(key) {
    delete this.store[key]
  }
}

global.localStorage = new LocalStorageMock()

// 쿠키 모킹
jest.mock('next/headers', () => ({
  cookies: jest.fn(() => ({
    get: jest.fn(),
    set: jest.fn(),
  })),
})) 