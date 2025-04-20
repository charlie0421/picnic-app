import { create } from 'zustand';

interface LanguageState {
  currentLang: string;
  setCurrentLang: (lang: string) => void;
}

export const useLanguageStore = create<LanguageState>((set) => ({
  currentLang: 'ko',
  setCurrentLang: (lang: string) => set({ currentLang: lang }),
})); 