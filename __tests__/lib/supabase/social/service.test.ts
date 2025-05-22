import { SocialAuthService, getSocialAuthService } from '@/lib/supabase/social/service';
import { SocialAuthError, SocialAuthErrorCode } from '@/lib/supabase/social/types';
import { mockSupabaseClient } from '@/__tests__/utils/supabase-mocks';

// 각 소셜 로그인 구현 모듈 모킹
jest.mock('@/lib/supabase/social/google', () => ({
  signInWithGoogleImpl: jest.fn().mockResolvedValue({
    success: true,
    provider: 'google',
    message: 'Google 로그인 리디렉션 중...'
  })
}));

jest.mock('@/lib/supabase/social/apple', () => ({
  signInWithAppleImpl: jest.fn().mockResolvedValue({
    success: true,
    provider: 'apple',
    message: 'Apple 로그인 리디렉션 중...'
  })
}));

jest.mock('@/lib/supabase/social/kakao', () => ({
  signInWithKakaoImpl: jest.fn().mockResolvedValue({
    success: true,
    provider: 'kakao',
    message: 'Kakao 로그인 리디렉션 중...'
  })
}));

jest.mock('@/lib/supabase/social/wechat', () => ({
  signInWithWeChatImpl: jest.fn().mockResolvedValue({
    success: true,
    provider: 'wechat',
    message: 'WeChat 로그인 리디렉션 중...'
  })
}));

// 전역 객체 저장
const originalWindow = global.window;
const originalConsole = global.console;

describe('SocialAuthService', () => {
  let supabase: any;
  let authService: SocialAuthService;
  let mockLog: jest.Mock;
  
  beforeEach(() => {
    // 콘솔 모킹
    mockLog = jest.fn();
    global.console = {
      ...console,
      log: mockLog,
      error: jest.fn()
    };
    
    // window 모킹
    global.window = {
      ...global.window,
      location: {
        ...global.window?.location,
        origin: 'http://localhost',
        pathname: '/test-page'
      }
    } as any;
    
    // Supabase 클라이언트 모킹
    supabase = mockSupabaseClient({
      authenticated: false
    });
    
    // 인증 서비스 인스턴스 생성
    authService = new SocialAuthService(supabase);
    
    // 모킹된 구현 함수 초기화
    const { signInWithGoogleImpl } = require('@/lib/supabase/social/google');
    const { signInWithAppleImpl } = require('@/lib/supabase/social/apple');
    const { signInWithKakaoImpl } = require('@/lib/supabase/social/kakao');
    const { signInWithWeChatImpl } = require('@/lib/supabase/social/wechat');
    
    signInWithGoogleImpl.mockClear();
    signInWithAppleImpl.mockClear();
    signInWithKakaoImpl.mockClear();
    signInWithWeChatImpl.mockClear();
  });
  
  afterEach(() => {
    // 전역 객체 복원
    global.window = originalWindow;
    global.console = originalConsole;
  });
  
  describe('getSocialAuthService', () => {
    it('서비스 인스턴스를 생성하고 반환합니다', () => {
      const service = getSocialAuthService(supabase);
      
      expect(service).toBeInstanceOf(SocialAuthService);
    });
  });
  
  describe('signInWithGoogle', () => {
    it('Google 로그인 프로세스를 시작합니다', async () => {
      const { signInWithGoogleImpl } = require('@/lib/supabase/social/google');
      
      const result = await authService.signInWithGoogle();
      
      expect(signInWithGoogleImpl).toHaveBeenCalledWith(
        supabase,
        expect.objectContaining({
          redirectUrl: 'http://localhost/auth/callback/google'
        })
      );
      
      expect(result).toHaveProperty('success', true);
      expect(result).toHaveProperty('provider', 'google');
    });
    
    it('커스텀 리다이렉트 URL을 지원합니다', async () => {
      const { signInWithGoogleImpl } = require('@/lib/supabase/social/google');
      
      await authService.signInWithGoogle({
        redirectUrl: 'https://custom.example.com/callback'
      });
      
      expect(signInWithGoogleImpl).toHaveBeenCalledWith(
        supabase,
        expect.objectContaining({
          redirectUrl: 'https://custom.example.com/callback'
        })
      );
    });
    
    it('오류가 발생하면 적절히 처리합니다', async () => {
      const { signInWithGoogleImpl } = require('@/lib/supabase/social/google');
      
      const mockError = new SocialAuthError(
        SocialAuthErrorCode.AUTH_PROCESS_FAILED,
        '인증 오류 발생',
        'google'
      );
      
      signInWithGoogleImpl.mockRejectedValueOnce(mockError);
      
      const result = await authService.signInWithGoogle();
      
      expect(result).toHaveProperty('success', false);
      expect(result).toHaveProperty('error');
      expect(result.error).toBeInstanceOf(SocialAuthError);
      expect(result).toHaveProperty('provider', 'google');
    });
  });
  
  describe('signInWithApple', () => {
    it('Apple 로그인 프로세스를 시작합니다', async () => {
      const { signInWithAppleImpl } = require('@/lib/supabase/social/apple');
      
      const result = await authService.signInWithApple();
      
      expect(signInWithAppleImpl).toHaveBeenCalledWith(
        supabase,
        expect.objectContaining({
          redirectUrl: 'http://localhost/auth/callback/apple'
        })
      );
      
      expect(result).toHaveProperty('success', true);
      expect(result).toHaveProperty('provider', 'apple');
    });
  });
  
  describe('signInWithKakao', () => {
    it('Kakao 로그인 프로세스를 시작합니다', async () => {
      const { signInWithKakaoImpl } = require('@/lib/supabase/social/kakao');
      
      const result = await authService.signInWithKakao();
      
      expect(signInWithKakaoImpl).toHaveBeenCalledWith(
        supabase,
        expect.objectContaining({
          redirectUrl: 'http://localhost/auth/callback/kakao'
        })
      );
      
      expect(result).toHaveProperty('success', true);
      expect(result).toHaveProperty('provider', 'kakao');
    });
  });
  
  describe('signInWithProvider', () => {
    it('Google 공급자를 지정하면 Google 로그인을 호출합니다', async () => {
      const { signInWithGoogleImpl } = require('@/lib/supabase/social/google');
      
      await authService.signInWithProvider('google');
      
      expect(signInWithGoogleImpl).toHaveBeenCalled();
    });
    
    it('Apple 공급자를 지정하면 Apple 로그인을 호출합니다', async () => {
      const { signInWithAppleImpl } = require('@/lib/supabase/social/apple');
      
      await authService.signInWithProvider('apple');
      
      expect(signInWithAppleImpl).toHaveBeenCalled();
    });
    
    it('Kakao 공급자를 지정하면 Kakao 로그인을 호출합니다', async () => {
      const { signInWithKakaoImpl } = require('@/lib/supabase/social/kakao');
      
      await authService.signInWithProvider('kakao');
      
      expect(signInWithKakaoImpl).toHaveBeenCalled();
    });
    
    it('지원되지 않는 공급자를 지정하면 에러를 반환합니다', async () => {
      // @ts-ignore - 의도적으로 잘못된 공급자 전달
      const result = await authService.signInWithProvider('unsupported');
      
      expect(result).toHaveProperty('success', false);
      expect(result.error).toBeInstanceOf(SocialAuthError);
      if (result.error instanceof SocialAuthError) {
        expect(result.error.code).toBe(SocialAuthErrorCode.PROVIDER_NOT_SUPPORTED);
      }
    });
  });
  
  describe('로깅', () => {
    it('서비스 초기화 및 로그인 시작 로그를 기록합니다', async () => {
      // 서비스 초기화 시 로그 기록 확인
      expect(mockLog).toHaveBeenCalledWith(
        expect.stringContaining('🔑 SocialAuth: 서비스 초기화 완료'),
        expect.anything()
      );
      
      // 로그인 시작 시 로그 기록 확인
      await authService.signInWithGoogle();
      
      expect(mockLog).toHaveBeenCalledWith(
        expect.stringContaining('🔑 SocialAuth: Google 로그인 시작'),
        expect.anything()
      );
    });
  });
}); 