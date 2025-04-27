import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import { getTranslation, clearTranslationCache } from '@/utils/i18n';

interface LanguageState {
  currentLang: string;
  translations: Record<string, string>;
  isLoading: boolean;
  error: string | null;
  setCurrentLang: (lang: string) => Promise<void>;
  t: (key: string, params?: Record<string, string>) => string;
  loadTranslations: () => Promise<void>;
}

// 브라우저의 기본 언어 가져오기
const getBrowserLanguage = () => {
  if (typeof window === 'undefined') return 'en';
  const lang = window.navigator.language.toLowerCase();
  if (lang.startsWith('ko')) return 'ko';
  if (lang.startsWith('ja')) return 'ja';
  if (lang.startsWith('zh')) return 'zh';
  if (lang.startsWith('id')) return 'id';
  return 'en';
};

// 지원되는 언어 목록
const SUPPORTED_LANGUAGES = ['ko', 'en', 'ja', 'zh', 'id'];

// 초기 언어 설정
const getInitialLanguage = () => {
  // 서버 사이드에서는 항상 'en'을 반환
  if (typeof window === 'undefined') return 'en';
  
  // 클라이언트 사이드에서만 localStorage 접근
  try {
    // 1. localStorage에서 저장된 언어 확인
    const savedLang = localStorage.getItem('language-store');
    if (savedLang) {
      const parsed = JSON.parse(savedLang);
      if (parsed.state?.currentLang && SUPPORTED_LANGUAGES.includes(parsed.state.currentLang)) {
        return parsed.state.currentLang;
      }
    }
    
    // 2. 저장된 언어가 없으면 브라우저 언어 사용
    const browserLang = getBrowserLanguage();
    if (SUPPORTED_LANGUAGES.includes(browserLang)) {
      return browserLang;
    }
  } catch (e) {
    console.error('Error while getting initial language:', e);
  }
  
  // 3. 기본값으로 'en' 사용
  return 'en';
};

// 브라우저 환경에서만 localStorage를 사용
const storage = typeof window !== 'undefined' 
  ? createJSONStorage(() => localStorage)
  : undefined;

export const useLanguageStore = create<LanguageState>()(
  persist(
    (set, get) => ({
      currentLang: getInitialLanguage(), // 초기값을 getInitialLanguage()로 변경
      translations: {},
      isLoading: false,
      error: null,
      setCurrentLang: async (lang: string) => {
        set({ currentLang: lang });
        // 언어 변경 시 캐시 초기화
        clearTranslationCache();
        await get().loadTranslations();
      },
      t: (key: string, params?: Record<string, string>) => {
        const state = get();
        if (!key) return '';
        if (state.isLoading || Object.keys(state.translations).length === 0) return '';
        if (state.error) {
          console.error('Translation error:', state.error);
          return '';
        }
        let translation = state.translations[key];
        if (!translation) {
          console.warn(`Missing translation for key: ${key} in language: ${state.currentLang}`);
          return '';
        }
        if (params) {
          Object.entries(params).forEach(([key, value]) => {
            translation = translation.replace(`{${key}}`, value);
          });
        }
        return translation;
      },
      loadTranslations: async () => {
        try {
          const currentLang = get().currentLang;
          console.log('Loading translations for language:', currentLang);
          set({ isLoading: true, error: null });
          
          const result = await getTranslation('*', currentLang);
          // console.log('Loaded translations:', result);
          
          if (!result || typeof result === 'string' || Object.keys(result).length === 0) {
            throw new Error(`No translations available for language: ${currentLang}`);
          }
          
          set({ translations: result as Record<string, string>, isLoading: false });
        } catch (error) {
          console.error('Failed to load translations:', error);
          set({ 
            error: error instanceof Error ? error.message : 'Failed to load translations',
            translations: {},
            isLoading: false 
          });
        }
      },
    }),
    {
      name: "language-store",
      storage,
      version: 1,
      skipHydration: true,
      onRehydrateStorage: () => (state) => {
        if (state) {
          // 스토어가 재수화될 때 번역 다시 로드
          state.loadTranslations();
        }
      },
    },
  ),
);
