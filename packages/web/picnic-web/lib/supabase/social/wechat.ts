/**
 * WeChat OAuth 인증 및 프로필 관련 기능
 * 
 * 이 파일은 WeChat 소셜 로그인을 구현하는 함수들을 제공합니다.
 */

import { Provider, SupabaseClient } from '@supabase/supabase-js';
import { Database } from '@/types/supabase';
import { 
  SocialAuthOptions, 
  AuthResult, 
  NormalizedProfile,
  SocialAuthError,
  SocialAuthErrorCode,
  LogFunction
} from './types';

/**
 * WeChat OAuth 구성 정보 반환
 * 
 * @returns WeChat 인증에 필요한 설정 값
 */
export function getWeChatConfig() {
  return {
    appId: process.env.NEXT_PUBLIC_WECHAT_APP_ID || '',
    appSecret: process.env.WECHAT_APP_SECRET || '',
    redirectUri: typeof window !== 'undefined' 
      ? `${window.location.origin}/auth/callback/wechat` 
      : '',
    scope: 'snsapi_userinfo',
    authEndpoint: 'https://open.weixin.qq.com/connect/qrconnect',
    tokenEndpoint: 'https://api.weixin.qq.com/sns/oauth2/access_token',
    userInfoEndpoint: 'https://api.weixin.qq.com/sns/userinfo'
  };
}

/**
 * WeChat 환경 확인 헬퍼 함수
 * 
 * @returns 현재 브라우저가 WeChat 내부 브라우저인지 여부
 */
export function isWeChatBrowser(): boolean {
  if (typeof window === 'undefined') return false;
  const userAgent = window.navigator.userAgent.toLowerCase();
  return /micromessenger/.test(userAgent);
}

/**
 * 중국 내 환경인지 확인하는 헬퍼 함수 (간단한 구현)
 * 
 * 참고: 실제 프로덕션에서는 더 정확한 지역 판단 로직이 필요할 수 있습니다.
 * 
 * @returns 중국 내부 환경인지 여부 (언어 설정, 타임존 등 기반)
 */
function isLikelyInChina(): boolean {
  if (typeof navigator === 'undefined') return false;
  
  // 중국어 설정 확인
  const lang = navigator.language || '';
  if (lang.startsWith('zh-CN') || lang === 'zh') return true;
  
  // 타임존으로 확인 (중국은 GMT+8)
  try {
    const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    if (timeZone === 'Asia/Shanghai' || 
        timeZone === 'Asia/Hong_Kong' || 
        timeZone === 'Asia/Macau' ||
        timeZone === 'Asia/Chongqing') {
      return true;
    }
  } catch (e) {
    // 타임존 API가 지원되지 않는 경우 무시
  }
  
  return false;
}

/**
 * 상태 토큰 생성 (CSRF 방지용)
 * 
 * @returns 무작위 상태 문자열
 */
function generateStateToken(): string {
  const randomBytes = new Uint8Array(16);
  if (typeof crypto !== 'undefined' && crypto.getRandomValues) {
    crypto.getRandomValues(randomBytes);
  } else {
    // 서버 측 또는 crypto가 지원되지 않는 환경
    for (let i = 0; i < randomBytes.length; i++) {
      randomBytes[i] = Math.floor(Math.random() * 256);
    }
  }
  
  return Array.from(randomBytes)
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

/**
 * WeChat 프로필 정보 정규화
 * 
 * @param profile WeChat에서 반환한 사용자 정보
 * @returns 정규화된 프로필 객체
 */
export function normalizeWeChatProfile(profile: any): NormalizedProfile {
  if (!profile) {
    throw new SocialAuthError(
      SocialAuthErrorCode.PROFILE_FETCH_FAILED,
      'WeChat 프로필 정보가 없습니다.',
      'wechat'
    );
  }
  
  // WeChat API 응답 구조:
  // {
  //   openid: string; (사용자의 WeChat 고유 ID)
  //   nickname: string; (표시 이름)
  //   sex: number; (1: 남성, 2: 여성, 0: 미설정)
  //   province: string; (지역/도)
  //   city: string; (도시)
  //   country: string; (국가)
  //   headimgurl: string; (프로필 이미지 URL, 132px 크기)
  //   privilege: string[]; (권한 목록)
  //   unionid: string; (옵션, 다중 앱 간 사용자 식별자)
  // }
  
  const normalizedProfile: NormalizedProfile = {
    id: profile.openid || profile.unionid || '',
    name: profile.nickname || '',
    email: '', // WeChat은 기본적으로 이메일을 제공하지 않음
    avatar: profile.headimgurl || '',
    raw: profile
  };
  
  // unionid가 있으면 추가 (다중 앱 환경에 유용)
  if (profile.unionid && profile.openid !== profile.unionid) {
    normalizedProfile.additionalInfo = {
      ...normalizedProfile.additionalInfo,
      unionId: profile.unionid,
      openId: profile.openid
    };
  }
  
  // 성별 정보 추가
  if (profile.sex !== undefined) {
    normalizedProfile.additionalInfo = {
      ...normalizedProfile.additionalInfo,
      gender: profile.sex === 1 ? 'male' : profile.sex === 2 ? 'female' : 'unknown'
    };
  }
  
  // 지역 정보 추가
  if (profile.country || profile.province || profile.city) {
    const location = [profile.country, profile.province, profile.city]
      .filter(Boolean)
      .join(', ');
    
    normalizedProfile.additionalInfo = {
      ...normalizedProfile.additionalInfo,
      location
    };
  }
  
  return normalizedProfile;
}

/**
 * WeChat 로그인 처리 구현
 * 
 * @param supabase Supabase 클라이언트
 * @param options 인증 옵션
 * @returns 인증 결과
 */
export async function signInWithWeChatImpl(
  supabase: SupabaseClient<Database>,
  options?: SocialAuthOptions
): Promise<AuthResult> {
  const config = getWeChatConfig();
  const debug = options?.debug || false;
  
  // 로깅 함수 준비
  const log: LogFunction = debug
    ? (message, data) => console.log(`🔑 WeChat Auth: ${message}`, data || '')
    : () => {};
  
  const logError: LogFunction = (message, data) => 
    console.error(`❌ WeChat Auth Error: ${message}`, data || '');
  
  try {
    // 필수 구성 검증
    if (!config.appId) {
      throw new SocialAuthError(
        SocialAuthErrorCode.AUTH_PROCESS_FAILED,
        'WeChat 앱 ID가 설정되지 않았습니다.',
        'wechat'
      );
    }
    
    // 브라우저 환경 검증
    if (typeof window === 'undefined') {
      throw new SocialAuthError(
        SocialAuthErrorCode.AUTH_PROCESS_FAILED,
        'WeChat 로그인은 브라우저 환경에서만 사용할 수 있습니다.',
        'wechat'
      );
    }
    
    log('WeChat 로그인 시작', { redirectUri: options?.redirectUrl });
    
    // 리디렉션 URL 준비
    const redirectUri = options?.redirectUrl || config.redirectUri;
    if (!redirectUri) {
      throw new SocialAuthError(
        SocialAuthErrorCode.AUTH_PROCESS_FAILED,
        'WeChat 리디렉션 URL이 설정되지 않았습니다.',
        'wechat'
      );
    }
    
    // 상태 토큰 생성 (CSRF 방지)
    const state = generateStateToken();
    
    // 상태 저장 (콜백에서 검증용)
    if (typeof sessionStorage !== 'undefined') {
      sessionStorage.setItem('wechat_auth_state', state);
    }
    
    // WeChat은 특별한 처리가 필요한 경우가 많음
    // 예: 중국 내부와 외부의 API 엔드포인트가 다를 수 있음
    const authEndpoint = isLikelyInChina()
      ? 'https://open.weixin.qq.com/connect/qrconnect' // 중국 내 엔드포인트
      : 'https://open.weixin.qq.com/connect/qrconnect'; // 해외 엔드포인트 (현재는 동일하지만 변경될 수 있음)
    
    // 인증 URL 구성
    const authUrl = new URL(authEndpoint);
    authUrl.searchParams.append('appid', config.appId);
    authUrl.searchParams.append('redirect_uri', redirectUri);
    authUrl.searchParams.append('response_type', 'code');
    authUrl.searchParams.append('scope', config.scope);
    authUrl.searchParams.append('state', state);
    
    // WeChat 특유의 URL 형식 (URL 끝에 #wechat_redirect 추가 필요)
    const finalAuthUrl = `${authUrl.toString()}#wechat_redirect`;
    
    log('WeChat 인증 URL 구성 완료', { finalAuthUrl });
    
    // 사용자를 WeChat 인증 페이지로 리디렉션
    window.location.href = finalAuthUrl;
    
    // 리디렉션 중이므로 아래 코드는 실행되지 않음
    // 하지만 타입 안전성을 위해 리턴 값 포함
    return {
      success: true,
      provider: 'wechat',
      message: 'WeChat 인증 페이지로 리디렉션 중...'
    };
  } catch (error) {
    logError('WeChat 로그인 오류', error);
    
    if (error instanceof SocialAuthError) {
      return {
        success: false,
        error,
        provider: 'wechat',
        message: error.message
      };
    }
    
    return {
      success: false,
      error: new SocialAuthError(
        SocialAuthErrorCode.AUTH_PROCESS_FAILED,
        error instanceof Error ? error.message : '알 수 없는 WeChat 로그인 오류',
        'wechat',
        error
      ),
      provider: 'wechat'
    };
  }
}

/**
 * WeChat 로그인 콜백 처리
 * 
 * @param supabase Supabase 클라이언트
 * @param params URL 쿼리 파라미터
 * @returns 인증 결과
 */
export async function handleWeChatCallback(
  supabase: SupabaseClient<Database>,
  params: Record<string, string>
): Promise<AuthResult> {
  const config = getWeChatConfig();
  
  try {
    const { code, state, error } = params;
    
    // 에러 처리
    if (error) {
      throw new SocialAuthError(
        SocialAuthErrorCode.AUTH_PROCESS_FAILED,
        `WeChat 인증 오류: ${error}`,
        'wechat'
      );
    }
    
    // 필수 파라미터 검증
    if (!code) {
      throw new SocialAuthError(
        SocialAuthErrorCode.CALLBACK_FAILED,
        'WeChat 인증 코드가 없습니다.',
        'wechat'
      );
    }
    
    // 상태 토큰 검증 (CSRF 방지)
    if (typeof sessionStorage !== 'undefined') {
      const savedState = sessionStorage.getItem('wechat_auth_state');
      if (state && savedState && state !== savedState) {
        throw new SocialAuthError(
          SocialAuthErrorCode.AUTH_PROCESS_FAILED,
          '보안 오류: 상태 토큰이 일치하지 않습니다.',
          'wechat'
        );
      }
      // 사용된 상태 토큰 제거
      sessionStorage.removeItem('wechat_auth_state');
    }
    
    // 코드를 토큰으로 교환 (서버 측 구현 필요)
    // WeChat API는 서버 측 비밀키가 필요하므로 API 라우트 사용
    const tokenResponse = await fetch('/api/auth/wechat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ code, state })
    });
    
    if (!tokenResponse.ok) {
      const error = await tokenResponse.text();
      throw new SocialAuthError(
        SocialAuthErrorCode.TOKEN_EXCHANGE_FAILED,
        `WeChat 토큰 교환 실패: ${error}`,
        'wechat'
      );
    }
    
    const tokenData = await tokenResponse.json();
    
    if (!tokenData.success) {
      throw new SocialAuthError(
        SocialAuthErrorCode.TOKEN_EXCHANGE_FAILED,
        tokenData.error || 'WeChat 토큰 교환 실패',
        'wechat'
      );
    }
    
    // 프로필 정보가 있으면 바로 사용
    if (tokenData.profile) {
      // Supabase로 이 정보로 사용자 생성 또는 업데이트
      // 주의: WeChat은 신원 정보가 이메일이 아닌 openid를 사용
      // 커스텀 API 구현이 필요할 수 있음
      
      // Supabase OAuth 호출 - WeChat은 공식 지원되지 않으므로 이메일/비밀번호 방식으로 처리
      // 실제 구현에서는 커스텀 인증 로직 필요
      // 아래는 임시 예시 코드
      const { data, error } = await supabase.auth.signInWithPassword({
        email: `wechat_${tokenData.profile.id}@placeholder.com`,
        password: tokenData.tokens.id_token
      });
      
      if (error) {
        // 사용자가 존재하지 않으면 생성
        if (error.message.includes('Invalid login credentials')) {
          const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
            email: `wechat_${tokenData.profile.id}@placeholder.com`,
            password: tokenData.tokens.id_token,
            options: {
              data: {
                provider: 'wechat',
                provider_id: tokenData.profile.id,
                name: tokenData.profile.name
              }
            }
          });
          
          if (signUpError) {
            throw new SocialAuthError(
              SocialAuthErrorCode.AUTH_PROCESS_FAILED,
              `WeChat 사용자 등록 실패: ${signUpError.message}`,
              'wechat',
              signUpError
            );
          }
          
          return {
            success: true,
            provider: 'wechat',
            message: 'WeChat 로그인 성공 (신규 사용자)',
            user: signUpData.user,
            session: signUpData.session
          };
        }
        
        throw new SocialAuthError(
          SocialAuthErrorCode.AUTH_PROCESS_FAILED,
          `Supabase WeChat 로그인 실패: ${error.message}`,
          'wechat',
          error
        );
      }
      
      return {
        success: true,
        provider: 'wechat',
        message: 'WeChat 로그인 성공',
        user: data.user,
        session: data.session
      };
    }
    
    // 프로필 정보가 없으면 별도로 가져옴 (일반적으로는 API 응답에 포함됨)
    throw new SocialAuthError(
      SocialAuthErrorCode.PROFILE_FETCH_FAILED,
      'WeChat 프로필 정보를 가져오는데 실패했습니다.',
      'wechat'
    );
    
  } catch (error) {
    if (error instanceof SocialAuthError) {
      return {
        success: false,
        error,
        provider: 'wechat',
        message: error.message
      };
    }
    
    return {
      success: false,
      error: new SocialAuthError(
        SocialAuthErrorCode.CALLBACK_FAILED,
        error instanceof Error ? error.message : '알 수 없는 WeChat 콜백 처리 오류',
        'wechat',
        error
      ),
      provider: 'wechat'
    };
  }
} 