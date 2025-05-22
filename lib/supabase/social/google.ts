/**
 * Google 소셜 로그인 구현
 * 
 * 이 파일은 Google OAuth를 통한 인증 구현을 담당합니다.
 */

import { SupabaseClient } from '@supabase/supabase-js';
import { Database } from '@/types/supabase';
import { 
  SocialAuthOptions, 
  AuthResult,
  OAuthProviderConfig,
  SocialAuthError,
  SocialAuthErrorCode
} from './types';

/**
 * Google OAuth 설정
 */
export function getGoogleConfig(): OAuthProviderConfig {
  return {
    clientId: process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID || '',
    clientSecretEnvKey: 'GOOGLE_CLIENT_SECRET',
    defaultScopes: [
      'email',
      'profile',
      'openid'
    ],
    additionalConfig: {
      // Google 특화 설정
      accessType: 'offline', // 리프레시 토큰 요청
      prompt: 'consent',     // 매번 동의 화면 표시 (테스트 시 유용)
      includeGrantedScopes: true // 이전에 허용한 권한 포함
    }
  };
}

/**
 * Google 로그인 구현
 * 
 * @param supabase Supabase 클라이언트
 * @param options 인증 옵션
 * @returns 인증 결과
 */
export async function signInWithGoogleImpl(
  supabase: SupabaseClient<Database>,
  options?: SocialAuthOptions
): Promise<AuthResult> {
  try {
    // 설정값 준비
    const config = getGoogleConfig();
    const redirectUrl = options?.redirectUrl || `${window.location.origin}/auth/callback/google`;
    const scopes = options?.scopes || config.defaultScopes;
    
    // 로컬 스토리지에 리다이렉트 URL 저장 (콜백 후 되돌아올 위치)
    if (typeof localStorage !== 'undefined') {
      const returnUrl = options?.additionalParams?.return_url || window.location.pathname;
      localStorage.setItem('auth_return_url', returnUrl);
    }
    
    // Google 특화 추가 파라미터
    const googleParams = {
      access_type: (config.additionalConfig as any)?.accessType || 'offline',
      prompt: (config.additionalConfig as any)?.prompt || 'select_account',
      include_granted_scopes: (config.additionalConfig as any)?.includeGrantedScopes ? 'true' : 'false',
      ...options?.additionalParams
    };
    
    // Supabase OAuth 사용
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: redirectUrl,
        scopes: scopes.join(' '),
        queryParams: googleParams
      }
    });
    
    if (error) {
      throw new SocialAuthError(
        SocialAuthErrorCode.AUTH_PROCESS_FAILED,
        `Google 로그인 프로세스 실패: ${error.message}`,
        'google',
        error
      );
    }
    
    // OAuth 리디렉션으로 인해 이 함수는 여기까지만 실행되고 리디렉션됨
    // 리디렉션 후 콜백 처리는 callback 핸들러에서 수행
    return {
      success: true,
      provider: 'google',
      message: 'Google 로그인 리디렉션 중...'
    };
  } catch (error) {
    if (error instanceof SocialAuthError) {
      throw error;
    }
    
    throw new SocialAuthError(
      SocialAuthErrorCode.AUTH_PROCESS_FAILED,
      error instanceof Error ? error.message : '알 수 없는 Google 로그인 오류',
      'google',
      error
    );
  }
}

/**
 * Google 프로필 정보 처리
 * 
 * @param profile Google에서 반환된 프로필 정보
 * @returns 표준화된 사용자 프로필 정보
 */
export function normalizeGoogleProfile(profile: any): Record<string, any> {
  // Google ID 토큰에서 파싱된 정보 또는 userinfo 엔드포인트에서 가져온 정보
  return {
    id: profile.sub || profile.id,
    name: profile.name || '',
    email: profile.email || '',
    avatar: profile.picture || '',
    verified: profile.email_verified || false,
    familyName: profile.family_name || '',
    givenName: profile.given_name || '',
    locale: profile.locale || '',
    provider: 'google'
  };
}

/**
 * Google ID 토큰 검증 및 파싱
 * 
 * @param idToken Google에서 반환된 ID 토큰
 * @returns 파싱된 토큰 페이로드
 */
export function parseGoogleIdToken(idToken: string): Record<string, any> {
  try {
    const payload = idToken.split('.')[1];
    const decoded = Buffer.from(payload, 'base64').toString('utf8');
    return JSON.parse(decoded);
  } catch (error) {
    console.error('Google ID 토큰 파싱 오류:', error);
    return {};
  }
} 