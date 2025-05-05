'use client';

import React, { useEffect, useState } from 'react';
import { useLanguageStore } from '@/stores/languageStore';

interface TranslationProviderProps {
  children: React.ReactNode;
  fallback?: React.ReactNode;
  minLoadingTime?: number; // 최소 로딩 시간 (ms)
}

/**
 * 번역 데이터가 로딩될 때까지 자식 컴포넌트 렌더링을 지연시키는 컴포넌트
 */
const TranslationProvider: React.FC<TranslationProviderProps> = ({
  children,
  fallback = null,
  minLoadingTime = 300 // 최소 300ms는 로딩 상태를 유지
}) => {
  const { loadTranslations, currentLanguage, isLoading, isTranslationLoaded } = useLanguageStore();
  const [showContent, setShowContent] = useState(false);

  useEffect(() => {
    let isMounted = true;
    let timer: NodeJS.Timeout;
    const startTime = Date.now();

    if (!isTranslationLoaded[currentLanguage]) {
      setShowContent(false);

      // 번역 데이터 로드
      loadTranslations(currentLanguage).then(() => {
        if (isMounted) {
          // 최소 로딩 시간 적용
          const elapsedTime = Date.now() - startTime;
          const remainingTime = Math.max(0, minLoadingTime - elapsedTime);

          timer = setTimeout(() => {
            setShowContent(true);
          }, remainingTime);
        }
      });
    } else {
      setShowContent(true);
    }

    return () => {
      isMounted = false;
      if (timer) clearTimeout(timer);
    };
  }, [loadTranslations, currentLanguage, isTranslationLoaded, minLoadingTime]);

  // 번역이 준비되지 않았으면 fallback 컴포넌트를 표시
  if (!showContent) {
    return fallback;
  }

  // 번역이 준비되면 자식 컴포넌트를 렌더링
  return <>{children}</>;
};

export default TranslationProvider; 