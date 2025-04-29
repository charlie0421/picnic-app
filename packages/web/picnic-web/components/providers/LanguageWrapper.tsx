'use client';

import { useEffect } from 'react';
import { useLanguageStore } from '@/stores/languageStore';
import { usePathname } from 'next/navigation';

export default function LanguageWrapper({
  children,
}: {
  children: React.ReactNode;
}) {
  const { loadTranslations, currentLanguage, syncLanguageWithPath } = useLanguageStore();
  const pathname = usePathname();

  useEffect(() => {
    // 페이지 이동 시마다 URL과 언어 상태를 동기화
    syncLanguageWithPath();
    
    // URL에서 언어 파라미터 가져오기
    const pathSegments = pathname.split('/');
    const urlLang = pathSegments[1];

    // 현재 경로의 언어를 기준으로 번역 데이터 로드
    if (urlLang && urlLang === currentLanguage) {
      loadTranslations(currentLanguage);
    } else if (urlLang) {
      loadTranslations(urlLang);
    } else {
      loadTranslations(currentLanguage);
    }
  }, [pathname, currentLanguage, loadTranslations, syncLanguageWithPath]);

  return <>{children}</>;
} 