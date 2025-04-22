import axios from 'axios';

// 지원하는 로케일 정의
export const supportedLocales = ['ko', 'en', 'ja', 'zh', 'id'] as const;
export type SupportedLocale = (typeof supportedLocales)[number];

// DeepL 언어 코드 매핑 (필요한 경우 여기에 추가)
const deeplLanguageMap: Record<SupportedLocale, string> = {
  ko: 'KO',
  en: 'EN-US',
  ja: 'JA',
  zh: 'ZH',
  id: 'ID',
};

// 번역 결과 인터페이스
export interface TranslationResult {
  text: string;
  detectedSourceLanguage?: string;
}

/**
 * DeepL API를 사용하여 텍스트를 번역합니다.
 * @param text 번역할 텍스트
 * @param targetLang 번역 대상 언어
 * @param sourceLang 원본 언어 (자동 감지하려면 생략)
 * @returns 번역된 텍스트와 감지된 원본 언어
 */
export async function translateText(
  text: string,
  targetLang: SupportedLocale,
  sourceLang?: SupportedLocale,
): Promise<TranslationResult> {
  try {
    // 내부 API Route를 통해 번역 요청
    const response = await axios.post('/api/translate', {
      text,
      targetLang: deeplLanguageMap[targetLang],
      ...(sourceLang && { sourceLang: deeplLanguageMap[sourceLang] }),
    });

    if (response.data && response.data.text) {
      return {
        text: response.data.text,
        detectedSourceLanguage: response.data.detectedSourceLanguage,
      };
    }

    throw new Error('번역 결과가 올바르지 않습니다.');
  } catch (error) {
    console.error('번역 중 오류가 발생했습니다:', error);
    throw error;
  }
}

/**
 * 여러 언어로 텍스트를 번역합니다.
 * @param text 번역할 텍스트
 * @param sourceLang 원본 언어
 * @param targetLangs 번역 대상 언어 배열
 * @returns 각 언어별 번역 결과
 */
export async function translateToMultipleLanguages(
  text: string,
  sourceLang: SupportedLocale,
  targetLangs: SupportedLocale[],
): Promise<Record<SupportedLocale, string>> {
  const results: Partial<Record<SupportedLocale, string>> = {
    [sourceLang]: text, // 원본 언어는 그대로 유지
  };

  // 번역이 필요한 언어만 필터링
  const langsToTranslate = targetLangs.filter((lang) => lang !== sourceLang);

  // 병렬로 번역 요청
  const translations = await Promise.all(
    langsToTranslate.map((lang) => translateText(text, lang, sourceLang)),
  );

  // 결과 매핑
  translations.forEach((result, index) => {
    results[langsToTranslate[index]] = result.text;
  });

  return results as Record<SupportedLocale, string>;
}
