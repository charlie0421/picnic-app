/**
 * Supabase 모킹 유틸리티
 * 
 * 이 파일은 Supabase 클라이언트와 관련 기능을 모킹하기 위한 유틸리티 함수들을 제공합니다.
 * 테스트에서 Supabase에 의존하는 컴포넌트나 함수를 테스트할 때 사용할 수 있습니다.
 */

import { User, Session } from '@supabase/supabase-js';

// 기본 모의 사용자 데이터
export const mockUsers = [
  {
    id: 'user-1',
    email: 'user1@example.com',
    nickname: '사용자1',
    avatarUrl: 'https://example.com/avatar1.jpg',
    bio: '안녕하세요!',
    isAdmin: false,
    createdAt: '2023-01-01T00:00:00Z',
    updatedAt: '2023-01-01T00:00:00Z',
    deletedAt: null,
  },
  {
    id: 'user-2',
    email: 'user2@example.com',
    nickname: '사용자2',
    avatarUrl: 'https://example.com/avatar2.jpg',
    bio: '반갑습니다!',
    isAdmin: true,
    createdAt: '2023-01-02T00:00:00Z',
    updatedAt: '2023-01-02T00:00:00Z',
    deletedAt: null,
  },
];

// 기본 모의 투표 데이터
export const mockVotes = [
  {
    id: 'vote-1',
    title: '투표 제목 1',
    description: '투표 설명 1',
    created_by: 'user-1',
    created_at: '2023-02-01T00:00:00Z',
    updated_at: '2023-02-01T00:00:00Z',
    end_time: '2023-12-31T23:59:59Z',
    status: 'active',
  },
  {
    id: 'vote-2',
    title: '투표 제목 2',
    description: '투표 설명 2',
    created_by: 'user-2',
    created_at: '2023-02-02T00:00:00Z',
    updated_at: '2023-02-02T00:00:00Z',
    end_time: '2023-12-31T23:59:59Z',
    status: 'active',
  },
];

// 기본 모의 Supabase 응답 생성 함수
export function createMockSupabaseResponse<T>(data: T | null = null, error: Error | null = null) {
  return {
    data,
    error,
    count: Array.isArray(data) ? data.length : (data ? 1 : 0),
  };
}

// 기본 모의 Supabase 사용자 생성 함수
export function createMockSupabaseUser(overrides: Partial<User> = {}): User {
  return {
    id: 'default-user-id',
    app_metadata: {},
    user_metadata: {},
    aud: 'authenticated',
    created_at: '2023-01-01T00:00:00Z',
    updated_at: '2023-01-01T00:00:00Z',
    email: 'user@example.com',
    phone: '',
    confirmed_at: '2023-01-01T00:00:00Z',
    email_confirmed_at: '2023-01-01T00:00:00Z',
    phone_confirmed_at: '',
    last_sign_in_at: '2023-01-01T00:00:00Z',
    role: 'authenticated',
    ...overrides,
  };
}

// 기본 모의 Supabase 세션 생성 함수
export function createMockSupabaseSession(userOverrides: Partial<User> = {}): Session {
  const user = createMockSupabaseUser(userOverrides);
  
  return {
    access_token: 'mock-access-token',
    refresh_token: 'mock-refresh-token',
    expires_in: 3600,
    expires_at: Math.floor(Date.now() / 1000) + 3600,
    token_type: 'bearer',
    user,
  };
}

// 인증된 상태의 Supabase 모킹
export function mockAuthenticatedSupabase(userOverrides: Partial<User> = {}) {
  const user = createMockSupabaseUser(userOverrides);
  const session = createMockSupabaseSession({ ...userOverrides, id: user.id });
  
  return {
    auth: {
      getUser: jest.fn().mockResolvedValue({ data: { user }, error: null }),
      getSession: jest.fn().mockResolvedValue({ data: { session }, error: null }),
      signInWithOAuth: jest.fn().mockResolvedValue({ error: null }),
      signOut: jest.fn().mockResolvedValue({ error: null }),
      onAuthStateChange: jest.fn().mockImplementation((callback) => {
        // 콜백을 즉시 실행하여 인증된 상태 시뮬레이션
        callback('SIGNED_IN', session);
        return { data: { subscription: { unsubscribe: jest.fn() } } };
      }),
    },
    // 다른 Supabase 메소드들...
  };
}

// 비인증 상태의 Supabase 모킹
export function mockUnauthenticatedSupabase() {
  return {
    auth: {
      getUser: jest.fn().mockResolvedValue({ data: { user: null }, error: null }),
      getSession: jest.fn().mockResolvedValue({ data: { session: null }, error: null }),
      signInWithOAuth: jest.fn().mockResolvedValue({ error: null }),
      signOut: jest.fn().mockResolvedValue({ error: null }),
      onAuthStateChange: jest.fn().mockImplementation((callback) => {
        // 콜백을 즉시 실행하여 비인증 상태 시뮬레이션
        callback('SIGNED_OUT', null);
        return { data: { subscription: { unsubscribe: jest.fn() } } };
      }),
    },
    // 다른 Supabase 메소드들...
  };
}

// 특정 데이터에 대한 쿼리 모킹
export function mockSupabaseQueryWithData(tableName: string, data: any[] = []) {
  const response = { data, error: null, count: data.length };
  
  // 쿼리 메소드 체인을 모킹하기 위한 기본 객체
  const queryChain = {
    select: jest.fn().mockReturnThis(),
    insert: jest.fn().mockReturnValue(response),
    update: jest.fn().mockReturnValue(response),
    delete: jest.fn().mockReturnValue(response),
    upsert: jest.fn().mockReturnValue(response),
    eq: jest.fn().mockReturnValue(response),
    neq: jest.fn().mockReturnValue(response),
    gt: jest.fn().mockReturnValue(response),
    lt: jest.fn().mockReturnValue(response),
    gte: jest.fn().mockReturnValue(response),
    lte: jest.fn().mockReturnValue(response),
    like: jest.fn().mockReturnValue(response),
    ilike: jest.fn().mockReturnValue(response),
    in: jest.fn().mockReturnValue(response),
    is: jest.fn().mockReturnValue(response),
    match: jest.fn().mockReturnValue(response),
    or: jest.fn().mockReturnThis(),
    and: jest.fn().mockReturnThis(),
    order: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    range: jest.fn().mockReturnThis(),
    single: jest.fn().mockReturnValue({ ...response, data: data[0] || null }),
    maybeSingle: jest.fn().mockReturnValue({ ...response, data: data[0] || null }),
    execute: jest.fn().mockResolvedValue(response),
    then: jest.fn().mockImplementation((onFulfilled) => {
      return Promise.resolve(onFulfilled ? onFulfilled(response) : response);
    }),
  };
  
  // from 메소드를 호출하면 queryChain을 반환하는 모의 객체 생성
  return {
    from: jest.fn((table) => {
      if (table === tableName) {
        return queryChain;
      }
      // 다른 테이블이 요청되면 빈 데이터 반환
      return {
        ...queryChain,
        then: jest.fn().mockImplementation((onFulfilled) => {
          const emptyResponse = { data: [], error: null, count: 0 };
          return Promise.resolve(onFulfilled ? onFulfilled(emptyResponse) : emptyResponse);
        }),
      };
    }),
  };
}

// 오류를 반환하는 Supabase 쿼리 모킹
export function mockSupabaseQueryWithError(tableName: string, errorMessage: string = 'Database error') {
  const error = { message: errorMessage };
  const response = { data: null, error, count: 0 };
  
  // 쿼리 메소드 체인을 모킹하기 위한 기본 객체
  const queryChain = {
    select: jest.fn().mockReturnThis(),
    insert: jest.fn().mockReturnValue(response),
    update: jest.fn().mockReturnValue(response),
    delete: jest.fn().mockReturnValue(response),
    upsert: jest.fn().mockReturnValue(response),
    eq: jest.fn().mockReturnValue(response),
    neq: jest.fn().mockReturnValue(response),
    gt: jest.fn().mockReturnValue(response),
    lt: jest.fn().mockReturnValue(response),
    gte: jest.fn().mockReturnValue(response),
    lte: jest.fn().mockReturnValue(response),
    like: jest.fn().mockReturnValue(response),
    ilike: jest.fn().mockReturnValue(response),
    in: jest.fn().mockReturnValue(response),
    is: jest.fn().mockReturnValue(response),
    match: jest.fn().mockReturnValue(response),
    or: jest.fn().mockReturnThis(),
    and: jest.fn().mockReturnThis(),
    order: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    range: jest.fn().mockReturnThis(),
    single: jest.fn().mockReturnValue(response),
    maybeSingle: jest.fn().mockReturnValue(response),
    execute: jest.fn().mockResolvedValue(response),
    then: jest.fn().mockImplementation((onFulfilled, onRejected) => {
      return Promise.resolve(onRejected ? onRejected(error) : response);
    }),
  };
  
  // from 메소드를 호출하면 queryChain을 반환하는 모의 객체 생성
  return {
    from: jest.fn((table) => {
      if (table === tableName) {
        return queryChain;
      }
      // 다른 테이블에 대해서도 동일한 오류 반환
      return queryChain;
    }),
  };
}

// Supabase Storage 모킹
export function mockSupabaseStorage(bucketName: string = 'default') {
  return {
    storage: {
      from: jest.fn((bucket) => {
        if (bucket === bucketName) {
          return {
            upload: jest.fn().mockResolvedValue({ 
              data: { path: 'mock-file-path.jpg' }, 
              error: null 
            }),
            download: jest.fn().mockResolvedValue({ 
              data: new Blob(['mock file content']), 
              error: null 
            }),
            getPublicUrl: jest.fn().mockReturnValue({ 
              data: { publicUrl: `https://example.com/${bucketName}/mock-file-path.jpg` } 
            }),
            list: jest.fn().mockResolvedValue({ 
              data: [{ name: 'mock-file.jpg' }], 
              error: null 
            }),
            remove: jest.fn().mockResolvedValue({ 
              data: {}, 
              error: null 
            }),
          };
        }
        // 다른 버킷에 대해서는 오류 반환
        return {
          upload: jest.fn().mockResolvedValue({ 
            data: null, 
            error: new Error(`Bucket ${bucket} not found`) 
          }),
          download: jest.fn().mockResolvedValue({ 
            data: null, 
            error: new Error(`Bucket ${bucket} not found`) 
          }),
          getPublicUrl: jest.fn().mockReturnValue({ 
            data: null, 
            error: new Error(`Bucket ${bucket} not found`) 
          }),
          list: jest.fn().mockResolvedValue({ 
            data: null, 
            error: new Error(`Bucket ${bucket} not found`) 
          }),
          remove: jest.fn().mockResolvedValue({ 
            data: null, 
            error: new Error(`Bucket ${bucket} not found`) 
          }),
        };
      }),
    },
  };
}

// 전체 Supabase 클라이언트 모킹
export function mockSupabaseClient(options: {
  authenticated?: boolean;
  userData?: Partial<User>;
  tableData?: Record<string, any[]>;
  errorTables?: Record<string, string>;
  storageBuckets?: string[];
} = {}) {
  const {
    authenticated = false,
    userData = {},
    tableData = {},
    errorTables = {},
    storageBuckets = ['default'],
  } = options;
  
  // 인증 관련 모킹
  const authMock = authenticated 
    ? mockAuthenticatedSupabase(userData).auth 
    : mockUnauthenticatedSupabase().auth;
  
  // 스토리지 모킹
  const storageMock = {
    storage: {
      from: jest.fn((bucket) => {
        if (storageBuckets.includes(bucket)) {
          return {
            upload: jest.fn().mockResolvedValue({ 
              data: { path: 'mock-file-path.jpg' }, 
              error: null 
            }),
            download: jest.fn().mockResolvedValue({ 
              data: new Blob(['mock file content']), 
              error: null 
            }),
            getPublicUrl: jest.fn().mockReturnValue({ 
              data: { publicUrl: `https://example.com/${bucket}/mock-file-path.jpg` } 
            }),
            list: jest.fn().mockResolvedValue({ 
              data: [{ name: 'mock-file.jpg' }], 
              error: null 
            }),
            remove: jest.fn().mockResolvedValue({ 
              data: {}, 
              error: null 
            }),
          };
        }
        return {
          upload: jest.fn().mockResolvedValue({ 
            data: null, 
            error: { message: `Bucket ${bucket} not found` }
          }),
          download: jest.fn().mockResolvedValue({ 
            data: null, 
            error: { message: `Bucket ${bucket} not found` }
          }),
          getPublicUrl: jest.fn().mockReturnValue({ 
            data: null 
          }),
          list: jest.fn().mockResolvedValue({ 
            data: null, 
            error: { message: `Bucket ${bucket} not found` }
          }),
          remove: jest.fn().mockResolvedValue({ 
            data: null, 
            error: { message: `Bucket ${bucket} not found` }
          }),
        };
      }),
    },
  };
  
  // 데이터베이스 쿼리 모킹
  return {
    auth: authMock,
    ...storageMock,
    from: jest.fn((table) => {
      // 오류를 반환해야 하는 테이블인 경우
      if (table in errorTables) {
        const errorMessage = errorTables[table];
        const response = { data: null, error: { message: errorMessage }, count: 0 };
        
        const errorQueryChain = {
          select: jest.fn().mockReturnThis(),
          insert: jest.fn().mockReturnValue(response),
          update: jest.fn().mockReturnValue(response),
          delete: jest.fn().mockReturnValue(response),
          upsert: jest.fn().mockReturnValue(response),
          eq: jest.fn().mockReturnValue(response),
          neq: jest.fn().mockReturnValue(response),
          gt: jest.fn().mockReturnValue(response),
          lt: jest.fn().mockReturnValue(response),
          gte: jest.fn().mockReturnValue(response),
          lte: jest.fn().mockReturnValue(response),
          like: jest.fn().mockReturnValue(response),
          ilike: jest.fn().mockReturnValue(response),
          in: jest.fn().mockReturnValue(response),
          is: jest.fn().mockReturnValue(response),
          match: jest.fn().mockReturnValue(response),
          or: jest.fn().mockReturnThis(),
          and: jest.fn().mockReturnThis(),
          order: jest.fn().mockReturnThis(),
          limit: jest.fn().mockReturnThis(),
          range: jest.fn().mockReturnThis(),
          single: jest.fn().mockReturnValue(response),
          maybeSingle: jest.fn().mockReturnValue(response),
          execute: jest.fn().mockResolvedValue(response),
          then: jest.fn().mockImplementation((onFulfilled, onRejected) => {
            return Promise.resolve(onRejected ? onRejected(response.error) : response);
          }),
        };
        
        return errorQueryChain;
      }
      
      // 테이블 데이터가 있는 경우
      if (table in tableData) {
        const data = tableData[table];
        const response = { data, error: null, count: data.length };
        
        const queryChain = {
          select: jest.fn().mockReturnThis(),
          insert: jest.fn().mockReturnValue(response),
          update: jest.fn().mockReturnValue(response),
          delete: jest.fn().mockReturnValue(response),
          upsert: jest.fn().mockReturnValue(response),
          eq: jest.fn().mockReturnValue(response),
          neq: jest.fn().mockReturnValue(response),
          gt: jest.fn().mockReturnValue(response),
          lt: jest.fn().mockReturnValue(response),
          gte: jest.fn().mockReturnValue(response),
          lte: jest.fn().mockReturnValue(response),
          like: jest.fn().mockReturnValue(response),
          ilike: jest.fn().mockReturnValue(response),
          in: jest.fn().mockReturnValue(response),
          is: jest.fn().mockReturnValue(response),
          match: jest.fn().mockReturnValue(response),
          or: jest.fn().mockReturnThis(),
          and: jest.fn().mockReturnThis(),
          order: jest.fn().mockReturnThis(),
          limit: jest.fn().mockReturnThis(),
          range: jest.fn().mockReturnThis(),
          single: jest.fn().mockReturnValue({ ...response, data: data[0] || null }),
          maybeSingle: jest.fn().mockReturnValue({ ...response, data: data[0] || null }),
          execute: jest.fn().mockResolvedValue(response),
          then: jest.fn().mockImplementation((onFulfilled) => {
            return Promise.resolve(onFulfilled ? onFulfilled(response) : response);
          }),
        };
        
        return queryChain;
      }
      
      // 기본적으로 빈 데이터 반환
      const emptyResponse = { data: [], error: null, count: 0 };
      
      const emptyQueryChain = {
        select: jest.fn().mockReturnThis(),
        insert: jest.fn().mockReturnValue(emptyResponse),
        update: jest.fn().mockReturnValue(emptyResponse),
        delete: jest.fn().mockReturnValue(emptyResponse),
        upsert: jest.fn().mockReturnValue(emptyResponse),
        eq: jest.fn().mockReturnValue(emptyResponse),
        neq: jest.fn().mockReturnValue(emptyResponse),
        gt: jest.fn().mockReturnValue(emptyResponse),
        lt: jest.fn().mockReturnValue(emptyResponse),
        gte: jest.fn().mockReturnValue(emptyResponse),
        lte: jest.fn().mockReturnValue(emptyResponse),
        like: jest.fn().mockReturnValue(emptyResponse),
        ilike: jest.fn().mockReturnValue(emptyResponse),
        in: jest.fn().mockReturnValue(emptyResponse),
        is: jest.fn().mockReturnValue(emptyResponse),
        match: jest.fn().mockReturnValue(emptyResponse),
        or: jest.fn().mockReturnThis(),
        and: jest.fn().mockReturnThis(),
        order: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        range: jest.fn().mockReturnThis(),
        single: jest.fn().mockReturnValue({ ...emptyResponse, data: null }),
        maybeSingle: jest.fn().mockReturnValue({ ...emptyResponse, data: null }),
        execute: jest.fn().mockResolvedValue(emptyResponse),
        then: jest.fn().mockImplementation((onFulfilled) => {
          return Promise.resolve(onFulfilled ? onFulfilled(emptyResponse) : emptyResponse);
        }),
      };
      
      return emptyQueryChain;
    }),
    rpc: jest.fn((functionName, params = {}) => {
      // RPC 함수 호출 모킹
      return {
        then: jest.fn().mockImplementation((onFulfilled) => {
          // 기본적으로 빈 데이터 반환
          const response = { data: [], error: null };
          return Promise.resolve(onFulfilled ? onFulfilled(response) : response);
        }),
      };
    }),
  };
}

// 이 파일에는 테스트가 없어도 됩니다.
// Jest가 테스트가 없는 파일에 대해 경고하지 않도록 더미 테스트를 추가합니다.

describe('Supabase Mock Utilities', () => {
  it('is a module file, not a test file', () => {
    expect(true).toBe(true);
  });
}); 