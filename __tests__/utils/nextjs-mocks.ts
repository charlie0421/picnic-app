/**
 * Next.js 모킹 유틸리티
 * 
 * 이 파일은 Next.js의 라우팅, 헤더, 쿠키, 데이터 페칭 등의 기능을 모킹하기 위한 유틸리티 함수들을 제공합니다.
 * 테스트에서 Next.js 기능을 사용하는 컴포넌트나 함수를 테스트할 때 사용할 수 있습니다.
 */

import React from 'react';

// AppRouterInstance 타입 정의
export interface AppRouterInstance {
  back: () => void;
  forward: () => void;
  push: (href: string) => void;
  replace: (href: string) => void;
  refresh: () => void;
  prefetch: (href: string) => Promise<void>;
}

// ReadonlyURLSearchParams 인터페이스 정의
export interface ReadonlyURLSearchParams {
  get: (key: string) => string | null;
  getAll: (key: string) => string[];
  has: (key: string) => boolean;
  forEach: (callback: (value: string, key: string) => void) => void;
  entries: () => IterableIterator<[string, string]>;
  keys: () => IterableIterator<string>;
  values: () => IterableIterator<string>;
  toString: () => string;
  [Symbol.iterator]: () => IterableIterator<[string, string]>;
}

// Next.js 라우터 목킹
export function createMockRouter(props: Partial<AppRouterInstance> = {}): AppRouterInstance {
  return {
    back: jest.fn(),
    forward: jest.fn(),
    push: jest.fn(),
    replace: jest.fn(),
    refresh: jest.fn(),
    prefetch: jest.fn(() => Promise.resolve()),
    ...props,
  };
}

// URL Search Params 목킹
export function createMockSearchParams(params: Record<string, string> = {}): ReadonlyURLSearchParams {
  const searchParams = new URLSearchParams();
  
  Object.entries(params).forEach(([key, value]) => {
    searchParams.set(key, value);
  });
  
  return {
    get: (key: string) => searchParams.get(key),
    getAll: (key: string) => searchParams.getAll(key),
    has: (key: string) => searchParams.has(key),
    forEach: (callback: (value: string, key: string) => void) => {
      searchParams.forEach((value, key) => callback(value, key));
    },
    entries: () => searchParams.entries(),
    keys: () => searchParams.keys(),
    values: () => searchParams.values(),
    toString: () => searchParams.toString(),
    [Symbol.iterator]: () => searchParams[Symbol.iterator](),
  };
}

// Headers 목킹
export function createMockHeaders(headers: Record<string, string> = {}): Headers {
  const mockHeaders = new Headers();
  
  Object.entries(headers).forEach(([key, value]) => {
    mockHeaders.set(key, value);
  });
  
  return mockHeaders;
}

// Next.js 쿠키 목킹
export interface MockCookies {
  get: (name: string) => { name: string; value: string } | undefined;
  getAll: () => Array<{ name: string; value: string }>;
  set: (name: string, value: string) => void;
  delete: (name: string) => void;
  has: (name: string) => boolean;
  [key: string]: any;
}

export function createMockCookies(initialCookies: Record<string, string> = {}): MockCookies {
  const cookies = new Map<string, string>();
  
  // 초기 쿠키 설정
  Object.entries(initialCookies).forEach(([name, value]) => {
    cookies.set(name, value);
  });
  
  return {
    get: (name: string) => {
      const value = cookies.get(name);
      return value !== undefined ? { name, value } : undefined;
    },
    getAll: () => {
      return Array.from(cookies.entries()).map(([name, value]) => ({ name, value }));
    },
    set: (name: string, value: string) => {
      cookies.set(name, value);
    },
    delete: (name: string) => {
      cookies.delete(name);
    },
    has: (name: string) => {
      return cookies.has(name);
    },
  };
}

// Next.js useParams 목킹
export function createMockParams(params: Record<string, string | string[]> = {}): Record<string, string | string[]> {
  return params;
}

// Next.js 서버 사이드 fetch 모킹
export function mockFetch<T>(responseData: T, options: { ok?: boolean; status?: number } = {}) {
  const { ok = true, status = 200 } = options;
  
  global.fetch = jest.fn().mockResolvedValue({
    ok,
    status,
    json: jest.fn().mockResolvedValue(responseData),
    text: jest.fn().mockResolvedValue(JSON.stringify(responseData)),
    headers: new Headers(),
    redirected: false,
    statusText: ok ? 'OK' : 'Error',
    type: 'basic',
    url: 'https://mockapi.example.com',
    clone: jest.fn(),
    body: null,
    bodyUsed: false,
    arrayBuffer: jest.fn(),
    blob: jest.fn(),
    formData: jest.fn(),
  });
}

// Next.js 이미지 컴포넌트 목킹 (JSX 부분 수정)
export function mockNextImage() {
  // Next/image 모킹
  jest.mock('next/image', () => ({
    __esModule: true,
    default: function MockImage(props: any) {
      // eslint-disable-next-line @next/next/no-img-element, jsx-a11y/alt-text
      return React.createElement('img', props);
    },
  }));
}

// Next.js 링크 컴포넌트 목킹 (JSX 부분 수정)
export function mockNextLink() {
  // Next/link 모킹
  jest.mock('next/link', () => ({
    __esModule: true,
    default: function MockLink({ children, ...props }: any) {
      return React.createElement('a', props, children);
    },
  }));
}

// Next.js dynamic 컴포넌트 목킹
export function mockNextDynamic() {
  jest.mock('next/dynamic', () => ({
    __esModule: true,
    default: function mockDynamic(componentImport: any) {
      const Component = componentImport();
      return Component;
    },
  }));
}

// Next.js API 모킹을 위한 요청/응답 객체 생성
export function createMockNextApiRequest(options: {
  method?: string;
  body?: any;
  query?: Record<string, string | string[]>;
  cookies?: Record<string, string>;
  headers?: Record<string, string>;
} = {}) {
  const {
    method = 'GET',
    body = null,
    query = {},
    cookies = {},
    headers = {},
  } = options;
  
  return {
    method,
    body,
    query,
    cookies,
    headers: createMockHeaders(headers),
  };
}

export function createMockNextApiResponse() {
  const res: any = {
    statusCode: 200,
    statusMessage: 'OK',
    headers: new Map<string, string>(),
    cookies: new Map<string, string>(),
    body: null,
  };
  
  return {
    status: jest.fn((code: number) => {
      res.statusCode = code;
      return res;
    }),
    setHeader: jest.fn((name: string, value: string) => {
      res.headers.set(name, value);
      return res;
    }),
    getHeader: jest.fn((name: string) => res.headers.get(name)),
    getHeaders: jest.fn(() => Object.fromEntries(res.headers)),
    setCookie: jest.fn((name: string, value: string) => {
      res.cookies.set(name, value);
      return res;
    }),
    json: jest.fn((body: any) => {
      res.body = body;
      return res;
    }),
    send: jest.fn((body: any) => {
      res.body = body;
      return res;
    }),
    end: jest.fn(() => res),
    redirect: jest.fn((url: string) => {
      res.redirect = url;
      return res;
    }),
    revalidate: jest.fn(),
    _getResult: () => res,
  };
}

// Next.js metadata 목킹 (JSX 부분 수정)
export function mockNextMetadata() {
  jest.mock('next/head', () => ({
    __esModule: true,
    default: function MockHead({ children }: { children: React.ReactNode }) {
      return React.createElement(React.Fragment, null, children);
    },
  }));
}

// Next.js hooks 목킹 함수
export const mockNextHooks = {
  // useRouter 목킹
  mockUseRouter: (router: Partial<AppRouterInstance> = {}) => {
    jest.mock('next/navigation', () => ({
      ...jest.requireActual('next/navigation'),
      useRouter: () => createMockRouter(router),
    }));
  },
  
  // usePathname 목킹
  mockUsePathname: (pathname: string = '/') => {
    jest.mock('next/navigation', () => ({
      ...jest.requireActual('next/navigation'),
      usePathname: () => pathname,
    }));
  },
  
  // useSearchParams 목킹
  mockUseSearchParams: (params: Record<string, string> = {}) => {
    jest.mock('next/navigation', () => ({
      ...jest.requireActual('next/navigation'),
      useSearchParams: () => createMockSearchParams(params),
    }));
  },
  
  // useParams 목킹
  mockUseParams: (params: Record<string, string | string[]> = {}) => {
    jest.mock('next/navigation', () => ({
      ...jest.requireActual('next/navigation'),
      useParams: () => params,
    }));
  },
};

// 전체 Next.js 기능 모킹 (단일 함수)
export function setupNextJsMocks(options: {
  router?: Partial<AppRouterInstance>;
  pathname?: string;
  searchParams?: Record<string, string>;
  params?: Record<string, string | string[]>;
  headers?: Record<string, string>;
  cookies?: Record<string, string>;
  mockImage?: boolean;
  mockLink?: boolean;
  mockDynamic?: boolean;
  mockMetadata?: boolean;
} = {}) {
  const {
    router = {},
    pathname = '/',
    searchParams = {},
    params = {},
    headers = {},
    cookies = {},
    mockImage = true,
    mockLink = true,
    mockDynamic = true,
    mockMetadata = true,
  } = options;
  
  // Next.js 네비게이션 관련 모킹
  jest.mock('next/navigation', () => ({
    useRouter: () => createMockRouter(router),
    usePathname: () => pathname,
    useSearchParams: () => createMockSearchParams(searchParams),
    useParams: () => params,
    headers: () => createMockHeaders(headers),
    cookies: () => createMockCookies(cookies),
  }));
  
  // 컴포넌트 모킹 (옵션에 따라)
  if (mockImage) mockNextImage();
  if (mockLink) mockNextLink();
  if (mockDynamic) mockNextDynamic();
  if (mockMetadata) mockNextMetadata();
}

// Next.js next-intl 모킹
export function mockNextIntl(translations: Record<string, string> = {}) {
  jest.mock('next-intl', () => ({
    useTranslations: () => (key: string) => translations[key] || key,
    useLocale: () => 'ko',
  }));
}

// 이 파일에는 테스트가 없어도 됩니다.
// Jest가 테스트가 없는 파일에 대해 경고하지 않도록 더미 테스트를 추가합니다.

describe('NextJS Mock Utilities', () => {
  it('is a module file, not a test file', () => {
    expect(true).toBe(true);
  });
}); 