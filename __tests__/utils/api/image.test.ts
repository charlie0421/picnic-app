import { getCdnImageUrl } from '@/utils/api/image';
import { useLanguageStore } from '@/stores/languageStore';

// 환경 변수 모킹
const originalEnv = process.env;

// zustand 스토어 모킹
jest.mock('@/stores/languageStore', () => ({
  useLanguageStore: {
    getState: jest.fn(),
  },
}));

describe('이미지 유틸리티 함수', () => {
  // 테스트를 위한 글로벌 window 객체 모킹 관리
  const originalWindow = global.window;
  const mockCdnUrl = 'https://cdn.example.com';

  beforeEach(() => {
    // window 객체 모킹 초기화
    // @ts-ignore - 테스트 환경에서는 window 객체를 수정할 수 있음
    global.window = { ...originalWindow };
    
    // 언어 스토어 모킹 초기화
    (useLanguageStore.getState as jest.Mock).mockReturnValue({
      currentLanguage: 'ko',
    });
    
    // 환경 변수 모킹 설정
    process.env = {
      ...originalEnv,
      NEXT_PUBLIC_CDN_URL: mockCdnUrl,
    };
    
    // 콘솔 에러 방지를 위한 모킹
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });
  
  afterEach(() => {
    // 모킹 리셋
    jest.clearAllMocks();
    // window 객체 복원
    // @ts-ignore
    global.window = originalWindow;
    // 환경 변수 복원
    process.env = originalEnv;
  });
  
  describe('getCdnImageUrl', () => {
    it('null 또는 undefined 값에 대해 빈 문자열을 반환합니다', () => {
      expect(getCdnImageUrl(null)).toBe('');
      expect(getCdnImageUrl(undefined)).toBe('');
    });
    
    it('이미 전체 URL인 경우 그대로 반환합니다', () => {
      const fullUrl = 'https://example.com/image.jpg';
      expect(getCdnImageUrl(fullUrl)).toBe(fullUrl);
      
      const httpUrl = 'http://example.com/image.jpg';
      expect(getCdnImageUrl(httpUrl)).toBe(httpUrl);
    });
    
    it('일반 경로에 CDN URL을 붙여서 반환합니다', () => {
      const path = 'images/photo.jpg';
      expect(getCdnImageUrl(path)).toBe(`${mockCdnUrl}/${path}`);
    });
    
    it('슬래시로 시작하는 경로는 슬래시를 제거합니다', () => {
      const path = '/images/photo.jpg';
      expect(getCdnImageUrl(path)).toBe(`${mockCdnUrl}/images/photo.jpg`);
    });
    
    it('너비 매개변수가 제공되면 URL에 추가합니다', () => {
      const path = 'images/photo.jpg';
      const width = 300;
      expect(getCdnImageUrl(path, width)).toBe(`${mockCdnUrl}/${path}?w=${width}`);
    });
    
    it('JSON 형식의 다국어 경로를 처리합니다', () => {
      const pathJson = JSON.stringify({
        en: 'images/photo-en.jpg',
        ko: 'images/photo-ko.jpg',
        ja: 'images/photo-ja.jpg',
      });
      
      expect(getCdnImageUrl(pathJson)).toBe(`${mockCdnUrl}/images/photo-ko.jpg`);
    });
    
    it('현재 언어에 해당하는 경로가 없으면 영어로 폴백합니다', () => {
      const pathJson = JSON.stringify({
        en: 'images/photo-en.jpg',
        ja: 'images/photo-ja.jpg',
      });
      
      expect(getCdnImageUrl(pathJson)).toBe(`${mockCdnUrl}/images/photo-en.jpg`);
    });
    
    it('영어 경로도 없으면 한국어나 첫 번째 값으로 폴백합니다', () => {
      const pathJson = JSON.stringify({
        ja: 'images/photo-ja.jpg',
        fr: 'images/photo-fr.jpg',
      });
      
      expect(getCdnImageUrl(pathJson)).toBe(`${mockCdnUrl}/images/photo-ja.jpg`);
    });
    
    it('서버 사이드에서는 스토어 접근을 시도하지 않습니다', () => {
      // window 객체를 undefined로 설정하는 대신 typeof window 검사를 모킹
      jest.spyOn(global, 'window', 'get').mockImplementation(() => undefined as any);
      
      // 스토어 모킹 초기화 (서버 사이드에서는 호출되지 않음)
      (useLanguageStore.getState as jest.Mock).mockClear();
      
      const path = 'images/photo.jpg';
      expect(getCdnImageUrl(path)).toBe(`${mockCdnUrl}/${path}`);
      expect(useLanguageStore.getState).not.toHaveBeenCalled();
    });
    
    it.skip('잘못된 JSON 형식의 경로는 일반 경로로 처리합니다', () => {
      // 원래 JSON.parse 함수 저장
      const originalJSONParse = JSON.parse;
      
      // JSON.parse를 모킹하여 강제로 오류 발생시키기
      JSON.parse = jest.fn().mockImplementation(() => {
        throw new Error('Invalid JSON');
      });
      
      // console.error 모킹
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
      
      const invalidJson = '{broken json}';
      expect(getCdnImageUrl(invalidJson)).toBe(`${mockCdnUrl}/${invalidJson}`);
      
      // 콘솔 에러가 호출되었는지 확인
      expect(consoleSpy).toHaveBeenCalled();
      
      // 원래 JSON.parse 함수 복원
      JSON.parse = originalJSONParse;
    });
  });
}); 