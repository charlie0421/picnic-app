import { calculateRemainingTime, getCurrentLocale, localeMap } from '@/utils/date';
import { enUS, ko, ja, zhCN, id } from 'date-fns/locale';

describe('Date 유틸리티 함수', () => {
  describe('calculateRemainingTime', () => {
    beforeEach(() => {
      // Date.now 모킹을 위한 설정
      jest.useFakeTimers();
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('남은 시간을 올바르게 계산합니다', () => {
      // 2023-01-01 00:00:00 기준으로 시간 고정
      const mockDate = new Date(2023, 0, 1, 0, 0, 0);
      jest.setSystemTime(mockDate);

      // 2023-01-02 12:30:45로 종료 시간 설정
      const endTime = new Date(2023, 0, 2, 12, 30, 45).toISOString();
      
      const remaining = calculateRemainingTime(endTime);
      
      expect(remaining.days).toBe(1);
      expect(remaining.hours).toBe(12);
      expect(remaining.minutes).toBe(30);
      expect(remaining.seconds).toBe(45);
    });

    it('종료 시간이 이미 지난 경우 0을 반환합니다', () => {
      // 2023-01-02 00:00:00 기준으로 시간 고정
      const mockDate = new Date(2023, 0, 2, 0, 0, 0);
      jest.setSystemTime(mockDate);

      // 2023-01-01 12:30:45로 종료 시간 설정 (이미 지난 시간)
      const endTime = new Date(2023, 0, 1, 12, 30, 45).toISOString();
      
      const remaining = calculateRemainingTime(endTime);
      
      expect(remaining.days).toBe(0);
      expect(remaining.hours).toBe(0);
      expect(remaining.minutes).toBe(0);
      expect(remaining.seconds).toBe(0);
    });
  });

  describe('getCurrentLocale', () => {
    it('한국어 로케일을 반환합니다', () => {
      expect(getCurrentLocale('ko')).toBe(ko);
    });

    it('일본어 로케일을 반환합니다', () => {
      expect(getCurrentLocale('ja')).toBe(ja);
    });

    it('중국어 로케일을 반환합니다', () => {
      expect(getCurrentLocale('zh')).toBe(zhCN);
    });

    it('영어 로케일을 반환합니다', () => {
      expect(getCurrentLocale('en')).toBe(enUS);
    });

    it('인도네시아어 로케일을 반환합니다', () => {
      expect(getCurrentLocale('id')).toBe(id);
    });

    it('지원하지 않는 언어는 영어 로케일을 반환합니다', () => {
      expect(getCurrentLocale('fr')).toBe(enUS);
    });
  });

  describe('localeMap', () => {
    it('모든 지원 언어에 대한 로케일 매핑이 있습니다', () => {
      expect(localeMap.ko).toBe(ko);
      expect(localeMap.ja).toBe(ja);
      expect(localeMap.zh).toBe(zhCN);
      expect(localeMap.en).toBe(enUS);
      expect(localeMap.id).toBe(id);
    });
  });
}); 