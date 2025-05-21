/**
 * 소셜 로그인 모듈 (진입점)
 * 
 * 모든 소셜 로그인 관련 구현체를 내보내는 진입점 파일입니다.
 */

// 타입 및 인터페이스 내보내기
export * from './types';

// 개별 제공자 모듈 내보내기
export * from './google';
export * from './apple';
export * from './kakao';
export * from './wechat';

// 통합 서비스 내보내기
export { SocialAuthService } from './service';
 
// 기본 내보내기는 서비스 인스턴스
import { SocialAuthService } from './service';
import { createBrowserSupabaseClient } from '../client';

// 브라우저 환경에서만 클라이언트를 생성
let socialAuthService: SocialAuthService;

/**
 * 기본 SocialAuthService 인스턴스를 가져옵니다.
 * 싱글톤 패턴으로 구현되어 있어 여러 번 호출해도 동일한 인스턴스를 반환합니다.
 */
export const getSocialAuthService = (): SocialAuthService => {
  if (typeof window === 'undefined') {
    throw new Error('소셜 인증 서비스는 브라우저 환경에서만 사용할 수 있습니다.');
  }
  
  if (!socialAuthService) {
    // 기본 Supabase 클라이언트 사용
    const supabase = createBrowserSupabaseClient();
    socialAuthService = new SocialAuthService(supabase);
  }
  
  return socialAuthService;
};

export default getSocialAuthService; 