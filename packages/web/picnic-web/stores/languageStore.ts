import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import { getTranslation } from '@/utils/i18n';

interface LanguageState {
  currentLang: string;
  translations: Record<string, string>;
  isLoading: boolean;
  error: string | null;
  setCurrentLang: (lang: string) => void;
  t: (key: string) => string;
  loadTranslations: () => Promise<void>;
}

// 브라우저 환경에서만 localStorage를 사용
const storage = typeof window !== 'undefined' 
  ? createJSONStorage(() => localStorage)
  : undefined;

export const useLanguageStore = create<LanguageState>()(
  persist(
    (set, get) => ({
      currentLang: "en",
      translations: {},
      isLoading: false,
      error: null,
      setCurrentLang: async (lang: string) => {
        set({ currentLang: lang });
        await get().loadTranslations();
      },
      t: (key: string) => {
        const state = get();
        if (state.isLoading) return '';
        if (state.error) return key;
        return state.translations[key] || key;
      },
      loadTranslations: async () => {
        try {
          set({ isLoading: true, error: null });
          const strings = await getTranslation('*', get().currentLang);
          set({ translations: strings || {}, isLoading: false });
        } catch (error) {
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
      // 서버 사이드에서도 동작하도록 설정
      skipHydration: true,
    },
  ),
);
