import { create } from "zustand";
import { persist } from "zustand/middleware";

interface LanguageState {
  currentLang: string;
  setCurrentLang: (lang: string) => void;
}

export const useLanguageStore = create<LanguageState>()(
  persist(
    (set) => ({
      currentLang: "en",
      setCurrentLang: (lang: string) => set({ currentLang: lang }),
    }),
    {
      name: "language-store",
    },
  ),
);
