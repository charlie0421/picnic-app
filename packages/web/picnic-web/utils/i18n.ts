import CrowdinOtaClient from '@crowdin/ota-client';

// 환경 변수 확인
const distributionHash = process.env.NEXT_PUBLIC_CROWDIN_DISTRIBUTION_HASH;
console.log('Crowdin Distribution Hash:', distributionHash ? 'Set' : 'Not Set');

if (!distributionHash) {
  console.error('Crowdin distribution hash is not set');
}

// 기본 번역 데이터
const defaultTranslations: Record<string, Record<string, string>> = {
  'ko': {
    'nav_vote': '투표홈',
    'nav_picchart': '픽차트',
    'nav_media': '미디어',
    'nav_store': '상점',
    'test_key_1': '테스트 키 1',
    'test_key_2': '테스트 키 2'
  },
  'en': {
    'nav_vote': 'Vote Home',
    'nav_picchart': 'PicChart',
    'nav_media': 'Media',
    'nav_store': 'Store',
    'test_key_1': 'Test Key 1',
    'test_key_2': 'Test Key 2'
  },
  'ja': {
    'nav_vote': '投票ホーム',
    'nav_picchart': 'ピックチャート',
    'nav_media': 'メディア',
    'nav_store': 'ストア',
    'test_key_1': 'テストキー1',
    'test_key_2': 'テストキー2'
  },
  'zh': {
    'nav_vote': '投票首页',
    'nav_picchart': '排行榜',
    'nav_media': '媒体',
    'nav_store': '商店',
    'test_key_1': '测试键1',
    'test_key_2': '测试键2'
  },
  'id': {
    'nav_vote': 'Beranda Voting',
    'nav_picchart': 'PicChart',
    'nav_media': 'Media',
    'nav_store': 'Toko',
    'test_key_1': 'Kunci Tes 1',
    'test_key_2': 'Kunci Tes 2'
  }
};

// 번역 캐시
const translationCache: Record<string, Record<string, string>> = {};

// Crowdin OTA 클라이언트 초기화
const client = new CrowdinOtaClient(distributionHash || '');

// 초기화 상태 관리
let isInitialized = false;
let initializationPromise: Promise<boolean> | null = null;

const initializeClient = async (): Promise<boolean> => {
  if (isInitialized) {
    return true;
  }

  if (initializationPromise) {
    return initializationPromise;
  }

  initializationPromise = (async () => {
    try {
      console.log('Initializing Crowdin OTA Client...');
      // Crowdin에서 번역 데이터 가져오기
      const strings = await client.getStrings();
      console.log('Crowdin strings:', strings);
      
      if (!strings || Object.keys(strings).length === 0) {
        console.warn('No translations available from Crowdin, using default translations');
        return true;
      }
      
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

export const getTranslation = async (key: string, locale: string = 'ko') => {
  try {
    console.log('Getting translation for:', { key, locale });
    
    const initialized = await initializeClient();
    if (!initialized) {
      console.error('Crowdin OTA Client initialization failed');
      return key === '*' ? defaultTranslations[locale] || {} : key;
    }

    // 캐시된 번역이 있는지 확인
    if (translationCache[locale]) {
      if (key === '*') {
        return translationCache[locale];
      }
      return translationCache[locale][key] || key;
    }

    const strings = await client.getStrings();
    console.log('Crowdin strings:', strings);

    const mergedTranslations = {
      ...defaultTranslations[locale],
      ...(strings[locale] || {})
    };

    // 번역 캐시에 저장
    translationCache[locale] = mergedTranslations;

    if (key === '*') {
      console.log('Returning all translations for locale:', mergedTranslations);
      return mergedTranslations;
    }

    const translation = mergedTranslations[key];
    console.log(`Translation for key "${key}" in locale "${locale}":`, translation);
    return translation || key;
  } catch (error) {
    console.error('Translation error:', error);
    if (error instanceof Error) {
      console.error('Error details:', {
        message: error.message,
        stack: error.stack,
        name: error.name
      });
    }
    return key === '*' ? defaultTranslations[locale] || {} : key;
  }
}; 