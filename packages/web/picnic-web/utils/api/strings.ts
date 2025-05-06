import { useLanguageStore } from "@/stores/languageStore";

export const getLocalizedString = (
    value: { [key: string]: string } | string | null | any,
    currentLang?: string,
  ): string => {
    if (!value) return '';
    if (typeof value === "string") return value;
    if (typeof value === "number") return value.toString();
  
    // currentLang이 제공되지 않은 경우에만 store에서 가져옴
    if (!currentLang) {
      try {
        // 서버 사이드에서는 기본값 사용
        if (typeof window === "undefined") {
          currentLang = "en";
        } else {
          const store = useLanguageStore.getState();
          currentLang = store.currentLanguage || "en";
        }
      } catch (error) {
        console.error('Error getting current language:', error);
        currentLang = "en";
      }
    }
  
    // 현재 언어의 번역이 있으면 반환
    if (value[currentLang]) {
      return value[currentLang];
        }
    
    // 현재 언어의 번역이 없으면 영어로 폴백
    return value["en"] || '';
  };
  