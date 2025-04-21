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
  if (typeof window === 'undefined') return 'ko';
  const lang = window.navigator.language.toLowerCase();
  if (lang.startsWith('ko')) return 'ko';
  if (lang.startsWith('ja')) return 'ja';
  if (lang.startsWith('zh')) return 'zh';
  if (lang.startsWith('id')) return 'id';
  return 'en';
};

// 브라우저 환경에서만 localStorage를 사용
const storage = typeof window !== 'undefined' 
  ? createJSONStorage(() => localStorage)
  : undefined;

export const useLanguageStore = create<LanguageState>()(
  persist(
    (set, get) => ({
      currentLang: getBrowserLanguage(),
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
        if (state.isLoading) return key;
        if (state.error) {
          console.error('Translation error:', state.error);
          return key;
        }
        let translation = state.translations[key];
        if (!translation) {
          console.warn(`Missing translation for key: ${key} in language: ${state.currentLang}`);
          return key;
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
