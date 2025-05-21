/**
 * Apple 소셜 로그인 구현
 * 
 * 이 파일은 Apple Sign In을 통한 인증 구현을 담당합니다.
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
 * Apple OAuth 설정
 */
export function getAppleConfig(): OAuthProviderConfig {
  return {
    clientId: process.env.NEXT_PUBLIC_APPLE_CLIENT_ID || '',
    clientSecretEnvKey: 'APPLE_CLIENT_SECRET',
    defaultScopes: [
      'email',
      'name'
    ],
    additionalConfig: {
      // Apple 특화 설정
      responseMode: 'form_post',
      responseType: 'code id_token',
      usePopup: false,
      // 웹용 서비스 ID (Apple Developer Console에서 설정)
      webClientId: process.env.NEXT_PUBLIC_APPLE_WEB_CLIENT_ID || process.env.NEXT_PUBLIC_APPLE_CLIENT_ID || '',
      // 팀 ID (Apple Developer Console에서 확인)
      teamId: process.env.APPLE_TEAM_ID || '',
      // 키 ID (Apple Developer Console에서 생성한 프라이빗 키의 ID)
      keyId: process.env.APPLE_KEY_ID || ''
    }
  };
}

/**
 * Apple 로그인 구현
 * 
 * @param supabase Supabase 클라이언트
 * @param options 인증 옵션
 * @returns 인증 결과
 */
export async function signInWithAppleImpl(
  supabase: SupabaseClient<Database>,
  options?: SocialAuthOptions
): Promise<AuthResult> {
  try {
    // 설정값 준비
    const config = getAppleConfig();
    const redirectUrl = options?.redirectUrl || `${window.location.origin}/auth/callback/apple`;
    const scopes = options?.scopes || config.defaultScopes;
    
    // 로컬 스토리지에 리다이렉트 URL 저장 (콜백 후 되돌아올 위치)
    if (typeof localStorage !== 'undefined') {
      const returnUrl = options?.additionalParams?.return_url || window.location.pathname;
      localStorage.setItem('auth_return_url', returnUrl);
    }
    
    // Apple의 경우 추가 설정이 필요함
    const appleParams = {
      // Apple은 response_type에 id_token을 추가해야 함
      response_type: 'code id_token',
      response_mode: 'fragment',
      // 사용자 데이터 요청 (첫 로그인에서만 제공됨)
      user_data: 'name,email',
      ...options?.additionalParams
    };
    
    // Supabase OAuth 사용
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'apple',
      options: {
        redirectTo: redirectUrl,
        scopes: scopes.join(' '),
        queryParams: appleParams
      }
    });
    
    if (error) {
      throw new SocialAuthError(
        SocialAuthErrorCode.AUTH_PROCESS_FAILED,
        `Apple 로그인 프로세스 실패: ${error.message}`,
        'apple',
        error
      );
    }
    
    // OAuth 리디렉션으로 인해 이 함수는 여기까지만 실행되고 리디렉션됨
    return {
      success: true,
      provider: 'apple',
      message: 'Apple 로그인 리디렉션 중...'
    };
  } catch (error) {
    if (error instanceof SocialAuthError) {
      throw error;
    }
    
    throw new SocialAuthError(
      SocialAuthErrorCode.AUTH_PROCESS_FAILED,
      error instanceof Error ? error.message : '알 수 없는 Apple 로그인 오류',
      'apple',
      error
    );
  }
}

/**
 * Apple ID 토큰 파싱 
 * 
 * @param idToken Apple에서 반환된 ID 토큰
 * @returns 파싱된 사용자 정보
 */
export function parseAppleIdentityToken(idToken: string): Record<string, any> {
  try {
    const payload = idToken.split('.')[1];
    const decodedPayload = Buffer.from(payload, 'base64').toString('utf8');
    return JSON.parse(decodedPayload);
  } catch (error) {
    console.error('Apple ID 토큰 파싱 오류:', error);
    return {};
  }
}

/**
 * Apple 사용자 프로필 정보 정규화
 * 
 * @param payload Apple ID 토큰에서 추출한 페이로드
 * @param userData 추가 사용자 데이터 (최초 로그인 시 제공)
 * @returns 표준화된 사용자 프로필
 */
export function normalizeAppleProfile(payload: any, userData?: any): Record<string, any> {
  // 참고: Apple은 최초 로그인 시에만 이름과 이메일을 제공하므로
  // 이 정보는 저장해두고 재사용해야 합니다.
  const profile: Record<string, any> = {
    id: payload.sub || '',
    email: payload.email || '',
    email_verified: payload.email_verified || false,
    provider: 'apple'
  };
  
  // 최초 로그인 시 전달된 사용자 데이터가 있는 경우
  if (userData && userData.name) {
    profile.name = [userData.name.firstName, userData.name.lastName]
      .filter(Boolean)
      .join(' ');
    profile.givenName = userData.name.firstName || '';
    profile.familyName = userData.name.lastName || '';
  }
  
  return profile;
}

/**
 * Apple 클라이언트 시크릿 생성 
 * (서버 측에서만 사용해야 함)
 * 
 * @returns JWT 형식의 클라이언트 시크릿
 * @note 이 함수는 프라이빗 키를 필요로 하므로 서버 측에서만 실행해야 합니다.
 */
export async function generateAppleClientSecret(): Promise<string | null> {
  // 참고: 이 함수는 서버 측에서만 사용해야 합니다.
  // 클라이언트에서 사용 시 API를 통해 서버에 요청해야 합니다.
  console.warn('generateAppleClientSecret 함수는 서버 측에서만 사용해야 합니다.');
  
  if (typeof window !== 'undefined') {
    console.error('보안상의 이유로 클라이언트에서 Apple 클라이언트 시크릿을 생성할 수 없습니다.');
    return null;
  }
  
  try {
    // 이 부분은 API 엔드포인트에서 구현해야 합니다.
    // Next.js API 라우트 또는 서버 액션에서 사용하는 것이 적합합니다.
    return null;
  } catch (error) {
    console.error('Apple 클라이언트 시크릿 생성 오류:', error);
    return null;
  }
} 