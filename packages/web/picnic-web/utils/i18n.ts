import CrowdinOtaClient from '@crowdin/ota-client';

// 환경 변수 확인
const distributionHash = process.env.NEXT_PUBLIC_CROWDIN_DISTRIBUTION_HASH;
console.log('Crowdin Distribution Hash:', distributionHash ? 'Set' : 'Not Set');

if (!distributionHash) {
  console.error('Crowdin distribution hash is not set');
}

// 번역 캐시
const translationCache: Record<string, Record<string, string>> = {};

// Crowdin OTA 클라이언트 초기화
const client = new CrowdinOtaClient(distributionHash || '');

// 초기화 상태 관리
let isInitialized = false;
let initializationPromise: Promise<boolean> | null = null;

// Crowdin 응답에서 번역 데이터 추출
const extractTranslations = (strings: any, locale: string): Record<string, string> => {
  const translations: Record<string, string> = {};
  
  // 로케일 매핑 추가
  const localeMapping: Record<string, string> = {
    'zh': 'zh-CN',  // 중국어 간체
    'zh-TW': 'zh-TW'  // 중국어 번체
  };
  
  const mappedLocale = localeMapping[locale] || locale;
  
  if (!strings || !strings[mappedLocale]) {
    console.warn(`No translations found for locale: ${mappedLocale}`);
    return translations;
  }

  // Crowdin 응답 형식 처리
  const localeData = strings[mappedLocale];
  
  if (typeof localeData === 'object') {
    for (const key in localeData) {
      const value = localeData[key];
      
      if (value && typeof value === 'object') {
        const { source_string, translation, context, identifier } = value;
        
        if (translation) {
          // 번역 키로 context 또는 identifier 사용
          let translationKey = context || identifier;
          if (translationKey) {
            // '-> ' 접두사 제거
            translationKey = translationKey.replace(/^-> /, '');
            translations[translationKey] = translation;
          }
        }
      } else if (typeof value === 'string') {
        // 직접 키-값 쌍인 경우도 접두사 제거
        const translationKey = key.replace(/^-> /, '');
        translations[translationKey] = value;
      }
    }
  }

  return translations;
};

const initializeClient = async (): Promise<boolean> => {
  if (isInitialized) {
    return true;
  }

  if (initializationPromise) {
    return initializationPromise;
  }

  initializationPromise = (async () => {
    try {
      // Crowdin에서 번역 데이터 가져오기
      const strings = await client.getStrings();
      
      if (!strings || Object.keys(strings).length === 0) {
        console.warn('No translations available from Crowdin');
        return false;
      }
      
      // 각 로케일의 번역 데이터 처리
      Object.keys(strings).forEach(locale => {
        const translations = extractTranslations(strings, locale);
        translationCache[locale] = translations;
      });
      
      isInitialized = true;
      return true;
    } catch (error) {
      console.error('Failed to initialize Crowdin OTA Client:', error);
      return false;
    }
  })();

  return initializationPromise;
};

// 클라이언트 초기화 실행
initializeClient().then(initialized => {
  console.log('Crowdin OTA Client initialized:', initialized);
});

// 번역 캐시 초기화 함수
export const clearTranslationCache = () => {
  Object.keys(translationCache).forEach(locale => {
    delete translationCache[locale];
  });
  // 초기화 상태도 리셋
  isInitialized = false;
  initializationPromise = null;
};

export const getTranslation = async (key: string, locale: string = 'ko') => {
  try {
    const initialized = await initializeClient();
    if (!initialized) {
      console.error('Crowdin OTA Client initialization failed');
      return key;
    }

    // 캐시된 번역이 있는지 확인
    if (translationCache[locale]) {
      if (key === '*') {
        return translationCache[locale];
      }
      return translationCache[locale][key] || key;
    }

    const strings = await client.getStrings();
    
    // 번역 데이터 추출 및 캐시 업데이트
    translationCache[locale] = extractTranslations(strings, locale);

    if (key === '*') {
      return translationCache[locale];
    }

    const translation = translationCache[locale][key];
    if (!translation) {
      console.warn(`No translation found for key "${key}" in locale "${locale}"`);
    }
    return translation || key;
  } catch (error) {
    console.error('Translation error:', error);
    return key;
  }
}; 