'use client';

import { usePathname, useRouter } from 'next/navigation';
import { SUPPORTED_LANGUAGES } from '@/config/settings';

export type Lang = typeof SUPPORTED_LANGUAGES[number];

export function useLang() {
  const pathname = usePathname();
  const router = useRouter();
  const currentLang = pathname.split('/')[1] as Lang;

  const changeLang = (newLang: Lang) => {
    const newPath = pathname.replace(`/${currentLang}`, `/${newLang}`);
    router.push(newPath);
  };

  return {
    currentLang,
    changeLang,
    supportedLangs: SUPPORTED_LANGUAGES,
  };
}

export function getLangPath(path: string, lang: Lang) {
  return `/${lang}${path}`;
} 