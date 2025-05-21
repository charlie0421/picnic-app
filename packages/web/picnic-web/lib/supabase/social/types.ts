/**
 * 소셜 로그인 통합을 위한 타입 정의
 * 
 * 이 파일은 소셜 로그인 구현에 필요한 타입, 인터페이스 및 공통 구조를 정의합니다.
 */

import { SupabaseClient, User, Session, Provider } from '@supabase/supabase-js';
import { Database } from '@/types/supabase';

/**
 * 지원하는 소셜 로그인 제공자 타입
 */
export type SocialLoginProvider = 'google' | 'apple' | 'kakao' | 'wechat';

/**
 * 소셜 로그인 요청 옵션
 */
export interface SocialAuthOptions {
  /**
   * 요청할 권한 범위 배열
   */
  scopes?: string[];
  
  /**
   * 리디렉션 URL (기본값: `${window.location.origin}/auth/callback/{provider}`)
   */
  redirectUrl?: string;
  
  /**
   * 제공자 특화 추가 파라미터
   */
  additionalParams?: Record<string, string>;
  
  /**
   * 상태 토큰 (CSRF 방지를 위한 랜덤 문자열)
   */
  state?: string;
  
  /**
   * 디버그 모드 활성화 여부
   */
  debug?: boolean;
}

/**
 * 정규화된 소셜 프로필 정보
 */
export interface NormalizedProfile {
  /**
   * 소셜 제공자의 고유 ID
   */
  id: string;
  
  /**
   * 사용자 이름
   */
  name: string;
  
  /**
   * 사용자 이메일 (일부 제공자는 제공하지 않을 수 있음)
   */
  email: string;
  
  /**
   * 프로필 이미지 URL
   */
  avatar: string;
  
  /**
   * Supabase 사용자 ID (연결된 경우)
   */
  userId?: string;
  
  /**
   * 제공자별 추가 정보
   */
  additionalInfo?: Record<string, any>;
  
  /**
   * 원본 프로필 데이터
   */
  raw?: any;
}

/**
 * 인증 결과 인터페이스
 */
export interface AuthResult {
  /**
   * 인증 성공 여부
   */
  success: boolean;
  
  /**
   * 인증 세션 정보 (성공 시)
   */
  session?: Session | null;
  
  /**
   * 사용자 정보 (성공 시)
   */
  user?: User | null;
  
  /**
   * 오류 정보 (실패 시)
   */
  error?: Error | null;
  
  /**
   * 소셜 로그인 제공자 (인증에 사용된)
   */
  provider?: SocialLoginProvider;
  
  /**
   * 처리 과정에서 발생한 메시지
   */
  message?: string;
}

/**
 * 소셜 로그인 서비스 인터페이스
 */
export interface SocialAuthServiceInterface {
  /**
   * Google 로그인 처리
   */
  signInWithGoogle(options?: SocialAuthOptions): Promise<AuthResult>;
  
  /**
   * Apple 로그인 처리
   */
  signInWithApple(options?: SocialAuthOptions): Promise<AuthResult>;
  
  /**
   * Kakao 로그인 처리
   */
  signInWithKakao(options?: SocialAuthOptions): Promise<AuthResult>;
  
  /**
   * WeChat 로그인 처리
   */
  signInWithWeChat(options?: SocialAuthOptions): Promise<AuthResult>;
  
  /**
   * 통합 소셜 로그인 처리
   */
  signInWithProvider(provider: SocialLoginProvider, options?: SocialAuthOptions): Promise<AuthResult>;
  
  /**
   * 소셜 로그인 콜백 처리
   */
  handleCallback(provider: SocialLoginProvider, params?: Record<string, string>): Promise<AuthResult>;
}

/**
 * 플랫폼별 OAuth 설정 인터페이스
 */
export interface OAuthProviderConfig {
  /**
   * 클라이언트 ID
   */
  clientId: string;
  
  /**
   * 클라이언트 시크릿 (환경 변수 참조용)
   */
  clientSecretEnvKey?: string;
  
  /**
   * 기본 권한 범위
   */
  defaultScopes: string[];
  
  /**
   * 인증 URL (직접 구현 시)
   */
  authUrl?: string;
  
  /**
   * 토큰 URL (직접 구현 시)
   */
  tokenUrl?: string;
  
  /**
   * 프로필 URL (직접 구현 시)
   */
  profileUrl?: string;
  
  /**
   * 제공자별 추가 설정
   */
  additionalConfig?: Record<string, any>;
}

/**
 * 공통 로깅 함수 타입
 */
export type LogFunction = (message: string, data?: any) => void;

/**
 * 소셜 로그인 오류 코드
 */
export enum SocialAuthErrorCode {
  PROVIDER_NOT_SUPPORTED = 'provider_not_supported',
  INITIALIZATION_FAILED = 'initialization_failed',
  AUTH_PROCESS_FAILED = 'auth_process_failed',
  CALLBACK_FAILED = 'callback_failed',
  USER_CANCELLED = 'user_cancelled',
  NETWORK_ERROR = 'network_error',
  TOKEN_EXCHANGE_FAILED = 'token_exchange_failed',
  PROFILE_FETCH_FAILED = 'profile_fetch_failed',
  INVALID_RESPONSE = 'invalid_response',
  INVALID_STATE = 'invalid_state',
  UNKNOWN_ERROR = 'unknown_error',
  PROVIDER_NOT_AVAILABLE = 'provider_not_available',
  USER_INFO_FAILED = 'user_info_failed',
  SESSION_CREATION_FAILED = 'session_creation_failed',
  TOKEN_VALIDATION_FAILED = 'token_validation_failed',
  TOKEN_REFRESH_FAILED = 'token_refresh_failed'
}

/**
 * 소셜 인증 오류 클래스
 */
export class SocialAuthError extends Error {
  code: SocialAuthErrorCode;
  provider?: SocialLoginProvider;
  originalError?: any;
  
  constructor(
    code: SocialAuthErrorCode,
    message: string,
    provider?: SocialLoginProvider,
    originalError?: any
  ) {
    super(message);
    this.name = 'SocialAuthError';
    this.code = code;
    this.provider = provider;
    this.originalError = originalError;
  }
} 