import { 
  createMockSupabaseUser, 
  createMockSupabaseSession, 
  mockAuthenticatedSupabase,
  mockUnauthenticatedSupabase,
  mockSupabaseQueryWithData,
  mockSupabaseQueryWithError,
  mockSupabaseClient
} from './supabase-mocks';

describe('Supabase 모킹 유틸리티', () => {
  describe('createMockSupabaseUser', () => {
    it('기본 사용자를 생성합니다', () => {
      const user = createMockSupabaseUser();
      expect(user.id).toBe('default-user-id');
      expect(user.email).toBe('user@example.com');
      expect(user.role).toBe('authenticated');
    });

    it('오버라이드를 적용하여 사용자를 생성합니다', () => {
      const user = createMockSupabaseUser({
        id: 'custom-id',
        email: 'custom@example.com'
      });
      expect(user.id).toBe('custom-id');
      expect(user.email).toBe('custom@example.com');
      expect(user.role).toBe('authenticated'); // 오버라이드되지 않은 값은 유지
    });
  });

  describe('createMockSupabaseSession', () => {
    it('기본 세션을 생성합니다', () => {
      const session = createMockSupabaseSession();
      expect(session.user.id).toBe('default-user-id');
      expect(session.access_token).toBe('mock-access-token');
      expect(session.refresh_token).toBe('mock-refresh-token');
    });

    it('사용자 정보가 오버라이드된 세션을 생성합니다', () => {
      const session = createMockSupabaseSession({
        id: 'custom-id',
        email: 'custom@example.com'
      });
      expect(session.user.id).toBe('custom-id');
      expect(session.user.email).toBe('custom@example.com');
    });
  });

  describe('mockAuthenticatedSupabase', () => {
    it('인증된 Supabase 객체를 생성합니다', async () => {
      const supabase = mockAuthenticatedSupabase();
      
      // getUser 테스트
      const { data: { user } } = await supabase.auth.getUser();
      expect(user).not.toBeNull();
      expect(user!.id).toBe('default-user-id');
      
      // getSession 테스트
      const { data: { session } } = await supabase.auth.getSession();
      expect(session).not.toBeNull();
      expect(session!.user.id).toBe('default-user-id');
      
      // onAuthStateChange 테스트
      const callback = jest.fn();
      supabase.auth.onAuthStateChange(callback);
      expect(callback).toHaveBeenCalledWith('SIGNED_IN', expect.any(Object));
    });
  });

  describe('mockUnauthenticatedSupabase', () => {
    it('비인증 Supabase 객체를 생성합니다', async () => {
      const supabase = mockUnauthenticatedSupabase();
      
      // getUser 테스트
      const { data: { user } } = await supabase.auth.getUser();
      expect(user).toBeNull();
      
      // getSession 테스트
      const { data: { session } } = await supabase.auth.getSession();
      expect(session).toBeNull();
      
      // onAuthStateChange 테스트
      const callback = jest.fn();
      supabase.auth.onAuthStateChange(callback);
      expect(callback).toHaveBeenCalledWith('SIGNED_OUT', null);
    });
  });

  describe('mockSupabaseQueryWithData', () => {
    it('데이터를 반환하는 Supabase 쿼리를 모킹합니다', async () => {
      const mockData = [{ id: 1, name: 'Test' }];
      const mockSupabase = mockSupabaseQueryWithData('users', mockData);
      
      const query = mockSupabase.from('users');
      
      // select().eq() 체이닝 테스트
      const result = await query.select().eq('id', 1);
      expect(result.data).toEqual(mockData);
      expect(result.error).toBeNull();
      
      // 다른 테이블 쿼리 시 빈 데이터 반환 테스트
      const otherResult = await mockSupabase.from('other_table').select();
      expect(otherResult.data).toEqual([]);
      expect(otherResult.error).toBeNull();
    });
  });

  describe('mockSupabaseQueryWithError', () => {
    it('오류를 반환하는 Supabase 쿼리를 모킹합니다', async () => {
      const errorMessage = 'Test error';
      const mockSupabase = mockSupabaseQueryWithError('users', errorMessage);
      
      const query = mockSupabase.from('users');
      
      // select().eq() 체이닝 테스트
      const result = await query.select().eq('id', 1);
      expect(result.error).toBeDefined();
      expect(result.error).toEqual({ message: errorMessage });
    });
  });

  describe('mockSupabaseClient', () => {
    it('인증된 상태로 전체 클라이언트를 모킹합니다', async () => {
      const mockData = {
        users: [{ id: 'user-1', name: '사용자1' }],
        posts: [{ id: 'post-1', title: '게시물1' }]
      };
      
      const mockClient = mockSupabaseClient({
        authenticated: true,
        userData: { id: 'test-user', email: 'test@example.com' },
        tableData: mockData
      });
      
      // 인증 상태 테스트
      const { data: { user } } = await mockClient.auth.getUser();
      expect(user).not.toBeNull();
      expect(user!.id).toBe('test-user');
      
      // 테이블 데이터 쿼리 테스트
      const usersResult = await mockClient.from('users').select();
      expect(usersResult.data).toEqual(mockData.users);
      
      const postsResult = await mockClient.from('posts').select();
      expect(postsResult.data).toEqual(mockData.posts);
      
      // 존재하지 않는 테이블 쿼리 테스트
      const emptyResult = await mockClient.from('unknown_table').select();
      expect(emptyResult.data).toEqual([]);
    });
    
    it.skip('테이블 오류를 포함하여 클라이언트를 모킹합니다', async () => {
      const errorMessage = 'Test error';
      const mockClient = mockSupabaseClient({
        errorTables: { 'error_table': errorMessage }
      });
      
      const result = await mockClient.from('error_table').select();
      expect(result.error).toBeDefined();
      expect(result.error).toEqual({ message: errorMessage });
    });
  });
}); 