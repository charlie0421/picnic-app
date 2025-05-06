'use client';

import { useState } from 'react';
import Script from 'next/script';
import LoginContent from './components/LoginContent';

// 리팩토링된 로그인 페이지 컴포넌트
export default function Login() {
  // Apple SDK 스크립트 로드 상태 관리
  const [sdkScriptLoaded, setSdkScriptLoaded] = useState(false);
  
  const handleAppleScriptLoad = () => {
    setSdkScriptLoaded(true);
  };

  return (
    <>
      <Script 
        src="https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js"
        strategy="afterInteractive"
        onLoad={handleAppleScriptLoad}
        onError={() => console.error('Apple SDK 스크립트 로드 실패')}
      />
      <LoginContent sdkScriptLoaded={sdkScriptLoaded} />
    </>
  );
}