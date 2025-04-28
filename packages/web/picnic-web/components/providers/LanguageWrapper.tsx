'use client';

import { useEffect } from 'react';
import { useLanguageStore } from '@/stores/languageStore';
import { usePathname } from 'next/navigation';

export default function LanguageWrapper({
  children,
}: {
  children: React.ReactNode;
}) {
  const { loadTranslations, currentLanguage } = useLanguageStore();
  const pathname = usePathname();

  useEffect(() => {
    // URL에서 언어 파라미터 가져오기
    const pathSegments = pathname.split('/');
    const urlLang = pathSegments[1];

    if (urlLang && urlLang !== currentLanguage) {
      loadTranslations(urlLang);
    } else {
      loadTranslations(currentLanguage);
    }
  }, [pathname, currentLanguage, loadTranslations]);

  return <>{children}</>;
} 