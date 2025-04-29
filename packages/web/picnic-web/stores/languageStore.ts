import { create } from "zustand";
import { persist } from "zustand/middleware";
import OtaClient from '@crowdin/ota-client';
import { settings, type Language } from '@/config/settings';
import { SUPPORTED_LANGUAGES } from '@/config/settings';

// Crowdin OTA 클라이언트 초기화
const distributionHash = process.env.NEXT_PUBLIC_CROWDIN_DISTRIBUTION_HASH;
console.log('Crowdin Distribution Hash:', distributionHash);

const otaClient = new OtaClient(distributionHash || '');
console.log('OTA Client initialized:', otaClient);

// URL에서 현재 언어 가져오기
const getCurrentLanguageFromPath = (): Language => {
  if (typeof window === 'undefined') return settings.languages.default;
  
  const pathSegments = window.location.pathname.split('/');
  const urlLang = pathSegments[1] as Language;
  
  if (urlLang && settings.languages.supported.includes(urlLang)) {
    return urlLang;
  }
  
  return settings.languages.default;
};

// 초기 언어 설정은 항상 URL 경로에서 가져옴
const initialLanguage: Language = (() => {
  if (typeof window === 'undefined') return settings.languages.default;
  return getCurrentLanguageFromPath();
})();

// OTA 클라이언트에 초기 언어 설정
if (typeof window !== 'undefined') {
  otaClient.setCurrentLocale(initialLanguage);
}

interface TranslationData {
  identifier: string;
  translation: string;
  source_string: string;
}

interface LanguageState {
  currentLanguage: Language;
  translations: Record<Language, Record<string, TranslationData>>;
  isLoading: boolean;
  error: string | null;
  setLanguage: (lang: Language) => void;
  t: (key: string, args?: Record<string, string>) => string;
  loadTranslations: (lang: string) => Promise<void>;
  setCurrentLang: (lang: Language) => void;
  syncLanguageWithPath: () => void;
}

export const useLanguageStore = create<LanguageState>()(
  persist(
    (set, get) => ({
      currentLanguage: initialLanguage,
      translations: settings.languages.supported.reduce((acc, lang) => {
        acc[lang] = {};
        return acc;
      }, {} as Record<Language, Record<string, TranslationData>>),
      isLoading: false,
      error: null,
      setLanguage: (lang: Language) => {
        if (settings.languages.supported.includes(lang)) {
          set({ currentLanguage: lang });
        }
      },
      syncLanguageWithPath: () => {
        if (typeof window === 'undefined') return;
        const langFromPath = getCurrentLanguageFromPath();
        set({ currentLanguage: langFromPath });
      },
      t: (key: string, args?: Record<string, string>) => {
        const { currentLanguage, translations } = get();
        const langTranslations = translations[currentLanguage];
        
        if (!langTranslations) {
          console.log(`No translations found for language: ${currentLanguage}`);
          return key;
        }
        
        // 배열 형태의 번역 데이터에서 identifier가 일치하는 항목 찾기
        const translationData = Object.values(langTranslations).find(
          (item) => item.identifier === key
        );

        if (!translationData) {
          console.log(`No translation found for key: ${key}`);
          return key;
        }

        let translation = translationData.translation || translationData.source_string || key;
        if (args) {
          Object.entries(args).forEach(([key, value]) => {
            translation = translation.replace(`{${key}}`, value);
          });
        }
        return translation;
      },
      loadTranslations: async (lang: string) => {
        if (typeof window === 'undefined') return;

        try {
          console.log(`Loading translations for language: ${lang}`);
          set({ isLoading: true, error: null });
          
          // Crowdin OTA 클라이언트에 현재 언어 설정
          // 중국어의 경우 'zh' 대신 'zh-CN'을 사용
          const crowdinLang = lang === 'zh' ? 'zh-CN' : lang;
          console.log(`Setting Crowdin locale to: ${crowdinLang}`);
          otaClient.setCurrentLocale(crowdinLang);
          
          // 번역 데이터 로드
          const translations = await otaClient.getStringsByLocale(crowdinLang);
          
          if (!translations || Object.keys(translations).length === 0) {
            console.warn(`No translations found for language: ${lang}`);
            // 기본 번역 데이터를 사용하도록 설정
            set((state) => ({
              translations: {
                ...state.translations,
                [lang]: {},
              },
              isLoading: false,
            }));
            return;
          }
          
          set((state) => ({
            translations: {
              ...state.translations,
              [lang]: translations,
            },
            isLoading: false,
          }));
        } catch (error) {
          console.error(`Failed to load translations for ${lang}:`, error);
          if (error instanceof Error) {
            console.error('Error details:', {
              message: error.message,
              stack: error.stack,
            });
          }
          set({ 
            error: error instanceof Error ? error.message : 'Failed to load translations',
            isLoading: false,
          });
        }
      },
      setCurrentLang: (lang) => set({ currentLanguage: lang }),
    }),
    {
      name: 'language-storage',
      partialize: (state) => ({
        currentLanguage: state.currentLanguage,
      }),
    }
  )
);
