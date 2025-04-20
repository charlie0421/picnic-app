'use client';

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';
import { getTranslation } from '@/utils/i18n';
import { useLanguageStore } from '@/stores/languageStore';

interface LanguageContextType {
  currentLang: string;
  t: (key: string) => string;
  translations: Record<string, string>;
  isLoading: boolean;
  error: string | null;
  changeLanguage: (lang: string) => void;
}

const getSystemLanguage = () => {
  if (typeof window === 'undefined') return 'ko';
  const systemLang = navigator.language.split('-')[0];
  return ['ko', 'en', 'ja', 'zh', 'id'].includes(systemLang) ? systemLang : 'ko';
};

const LanguageContext = createContext<LanguageContextType>({
  currentLang: 'ko',
  t: (key: string) => key,
  translations: {},
  isLoading: false,
  error: null,
  changeLanguage: () => {},
});

export const useLanguage = () => useContext(LanguageContext);

export const LanguageProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const pathname = usePathname();
  const router = useRouter();
  const searchParams = useSearchParams();
  const systemLang = getSystemLanguage();
  
  const getLanguageFromParams = useCallback(() => {
    const lang = searchParams.get('lang');
    if (lang && ['ko', 'en', 'ja', 'zh', 'id'].includes(lang)) {
      return lang;
    }
    return systemLang;
  }, [searchParams, systemLang]);

  const [currentLang, setCurrentLang] = useState(getLanguageFromParams());
  const [translations, setTranslations] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isChangingLanguage, setIsChangingLanguage] = useState(false);

  const changeLanguage = useCallback((lang: string) => {
    if (!['ko', 'en', 'ja', 'zh', 'id'].includes(lang) || isChangingLanguage) return;
    
    setIsChangingLanguage(true);
    const params = new URLSearchParams(searchParams.toString());
    params.set('lang', lang);
    
    const newPath = `${pathname}?${params.toString()}`;
    setCurrentLang(lang);
    useLanguageStore.getState().setCurrentLang(lang);
    router.push(newPath);
    setIsChangingLanguage(false);
  }, [pathname, router, searchParams, isChangingLanguage]);

  const loadTranslations = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);
      
      const strings = await getTranslation('*', currentLang);
      
      if (!strings || Object.keys(strings).length === 0) {
        setTranslations({});
        return;
      }
      
      setTranslations(strings);
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to load translations');
      setTranslations({});
    } finally {
      setIsLoading(false);
    }
  }, [currentLang]);

  useEffect(() => {
    loadTranslations();
  }, [currentLang, loadTranslations]);

  useEffect(() => {
    const newLang = getLanguageFromParams();
    if (newLang !== currentLang) {
      setCurrentLang(newLang);
    }
  }, [searchParams, currentLang, getLanguageFromParams]);

  const t = useCallback((key: string) => {
    if (isLoading) {
      return '';
    }
    if (error) {
      return key;
    }
    return translations[key] || key;
  }, [error, isLoading, translations]);

  return (
    <LanguageContext.Provider value={{ currentLang, t, translations, isLoading, error, changeLanguage }}>
      {children}
    </LanguageContext.Provider>
  );
}; 