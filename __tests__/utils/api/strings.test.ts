import { getLocalizedString, getLocalizedJson } from '@/utils/api/strings';
import { useLanguageStore } from '@/stores/languageStore';

// zustand 스토어 모킹
jest.mock('@/stores/languageStore');

describe('문자열 유틸리티 함수', () => {
  // 테스트를 위한 글로벌 window 객체 모킹 관리
  const originalWindow = global.window;
  
  beforeEach(() => {
    // window 객체 모킹 초기화
    // @ts-ignore - 테스트 환경에서는 window 객체를 수정할 수 있음
    global.window = { ...originalWindow };
    
    // 언어 스토어 모킹 초기화 - 전체 모듈을 목킹하고 필요한 함수만 구현
    (useLanguageStore.getState as jest.Mock) = jest.fn().mockReturnValue({
      currentLanguage: 'ko',
    });
  });
  
  afterEach(() => {
    // 모킹 리셋
    jest.clearAllMocks();
    // window 객체 복원
    // @ts-ignore
    global.window = originalWindow;
  });
  
  describe('getLocalizedString', () => {
    it('null 또는 undefined 값에 대해 빈 문자열을 반환합니다', () => {
      expect(getLocalizedString(null)).toBe('');
      expect(getLocalizedString(undefined)).toBe('');
    });
    
    it('문자열 값을 그대로 반환합니다', () => {
      expect(getLocalizedString('Hello')).toBe('Hello');
    });
    
    it('숫자를 문자열로 변환하여 반환합니다', () => {
      expect(getLocalizedString(123)).toBe('123');
    });
    
    it('제공된 언어에 맞는 문자열을 반환합니다', () => {
      const localizedText = {
        en: 'Hello',
        ko: '안녕하세요',
        ja: 'こんにちは',
      };
      
      expect(getLocalizedString(localizedText, 'ko')).toBe('안녕하세요');
      expect(getLocalizedString(localizedText, 'ja')).toBe('こんにちは');
      expect(getLocalizedString(localizedText, 'en')).toBe('Hello');
    });
    
    it('현재 언어가 없는 경우 스토어에서 언어를 가져옵니다', () => {
      // 테스트를 위해 명시적으로 스토어 모킹 설정
      (useLanguageStore.getState as jest.Mock).mockReturnValue({
        currentLanguage: 'ko',
      });
      
      const localizedText = {
        en: 'Hello',
        ko: '안녕하세요',
      };
      
      // 현재 언어(ko)에 해당하는 값을 반환해야 함
      const result = getLocalizedString(localizedText);
      expect(result).toBe('안녕하세요');
      expect(useLanguageStore.getState).toHaveBeenCalled();
    });
    
    it('요청한 언어가 없는 경우 영어로 폴백합니다', () => {
      const localizedText = {
        en: 'Hello',
        ko: '안녕하세요',
      };
      
      expect(getLocalizedString(localizedText, 'fr')).toBe('Hello');
    });
    
    it('서버 사이드에서는 기본값으로 영어를 사용합니다', () => {
      // window 객체를 undefined로 설정하는 대신 typeof window 검사를 모킹
      jest.spyOn(global, 'window', 'get').mockImplementation(() => undefined as any);
      
      // 스토어 모킹 초기화 (서버 사이드에서는 호출되지 않음)
      (useLanguageStore.getState as jest.Mock).mockClear();
      
      const localizedText = {
        en: 'Hello',
        ko: '안녕하세요',
      };
      
      expect(getLocalizedString(localizedText)).toBe('Hello');
      // 서버 사이드에서는 스토어를 호출하지 않아야 함
      expect(useLanguageStore.getState).not.toHaveBeenCalled();
    });
  });
  
  describe('getLocalizedJson', () => {
    it('null 또는 undefined 값에 대해 null을 반환합니다', () => {
      expect(getLocalizedJson(null)).toBeNull();
      expect(getLocalizedJson(undefined)).toBeNull();
    });
    
    it('문자열 값을 그대로 반환합니다', () => {
      expect(getLocalizedJson('Hello')).toBe('Hello');
    });
    
    it('숫자 값을 그대로 반환합니다', () => {
      expect(getLocalizedJson(123)).toBe(123);
    });
    
    it('제공된 언어에 맞는 객체를 반환합니다', () => {
      const localizedJson = {
        en: { title: 'Title', description: 'Description' },
        ko: { title: '제목', description: '설명' },
      };
      
      expect(getLocalizedJson(localizedJson, 'ko')).toEqual({ title: '제목', description: '설명' });
      expect(getLocalizedJson(localizedJson, 'en')).toEqual({ title: 'Title', description: 'Description' });
    });
    
    it.skip('현재 언어가 없는 경우 스토어에서 언어를 가져옵니다', () => {
      // 테스트를 위해 명시적으로 스토어 모킹 설정
      (useLanguageStore.getState as jest.Mock).mockReturnValue({
        currentLanguage: 'ko',
      });
      
      const localizedJson = {
        en: { message: 'Hello' },
        ko: { message: '안녕하세요' },
      };
      
      const result = getLocalizedJson(localizedJson);
      expect(result).toEqual({ message: '안녕하세요' });
      expect(useLanguageStore.getState).toHaveBeenCalled();
    });
    
    it('요청한 언어가 없는 경우 영어로 폴백합니다', () => {
      const localizedJson = {
        en: { message: 'Hello' },
        ko: { message: '안녕하세요' },
      };
      
      expect(getLocalizedJson(localizedJson, 'fr')).toEqual({ message: 'Hello' });
    });
    
    it('서버 사이드에서는 기본값으로 영어를 사용합니다', () => {
      // window 객체를 undefined로 설정하는 대신 typeof window 검사를 모킹
      jest.spyOn(global, 'window', 'get').mockImplementation(() => undefined as any);
      
      // 스토어 모킹 초기화 (서버 사이드에서는 호출되지 않음)
      (useLanguageStore.getState as jest.Mock).mockClear();
      
      const localizedJson = {
        en: { message: 'Hello' },
        ko: { message: '안녕하세요' },
      };
      
      expect(getLocalizedJson(localizedJson)).toEqual({ message: 'Hello' });
      // 서버 사이드에서는 스토어를 호출하지 않아야 함
      expect(useLanguageStore.getState).not.toHaveBeenCalled();
    });
  });
}); 