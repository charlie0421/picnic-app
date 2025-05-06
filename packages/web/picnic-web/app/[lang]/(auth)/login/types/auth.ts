// 로그인 관련 타입 정의

// 소셜 로그인 제공자 타입
export type SocialProvider = 'google' | 'apple' | 'kakao' | 'wechat';

// AppleID 타입 정의
declare global {
  interface Window {
    AppleID?: {
      auth: {
        init(params: any): void;
        signIn(): Promise<{
          authorization: {
            id_token?: string;
            code?: string;
            state?: string;
          };
        }>;
      };
    };
  }
} 