import { useState, useEffect } from 'react';

// Apple SDK 초기화를 위한 훅
export const useAppleSDK = (
  sdkScriptLoaded: boolean, 
  getRedirectUrl: (provider: string) => string,
  setError: (error: string) => void
) => {
  const [appleSDKInitialized, setAppleSDKInitialized] = useState(false);

  // SDK가 로드되면 초기화
  useEffect(() => {
    if (!sdkScriptLoaded || !window.AppleID || appleSDKInitialized) return;
    
    try {
      // 리디렉션 URL 설정 - ngrok 고려
      const redirectURI = getRedirectUrl('apple');
      
      // state 파라미터 준비 (원래 URL 정보 포함)
      const stateParams = {
        redirectUrl: typeof window !== 'undefined' ? window.location.origin : '',
        timestamp: Date.now(),
      };
      
      console.log('Apple SDK 초기화:', {
        redirectURI,
        originalUrl: stateParams.redirectUrl
      });
      
      // Apple SDK 초기화 - nonce 사용하지 않음
      const initOptions = {
        clientId: 'fan.picnic.web',
        scope: 'name email',
        redirectURI: redirectURI,
        usePopup: true,
        state: JSON.stringify(stateParams)
      };
      
      window.AppleID.auth.init(initOptions);
      
      // 이벤트 리스너 등록
      const successHandler = () => {};
      const failureHandler = () => {
        setError('Apple 로그인 중 오류가 발생했습니다.');
      };
      
      document.addEventListener('AppleIDSignInOnSuccess', successHandler);
      document.addEventListener('AppleIDSignInOnFailure', failureHandler);
      
      setAppleSDKInitialized(true);
      
      return () => {
        document.removeEventListener('AppleIDSignInOnSuccess', successHandler);
        document.removeEventListener('AppleIDSignInOnFailure', failureHandler);
      };
    } catch (error) {
      setError('Apple 로그인을 초기화하는 중 오류가 발생했습니다.');
    }
  }, [sdkScriptLoaded, appleSDKInitialized, getRedirectUrl, setError]);

  return { appleSDKInitialized };
}; 