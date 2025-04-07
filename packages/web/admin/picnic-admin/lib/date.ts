/**
 * 날짜 및 시간 출력 형식화를 위한 유틸리티 함수
 */

// 날짜 형식 타입
export type DateFormat = 'full' | 'date' | 'time' | 'datetime' | 'custom';

// 기본 날짜 형식화 옵션
const DEFAULT_FORMAT_OPTIONS = {
  full: {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  },
  date: {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  },
  time: {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  },
  datetime: {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  },
} as const;

/**
 * 날짜 문자열을 포맷팅하는 함수
 *
 * @param dateStr 날짜 문자열 (ISO 형식)
 * @param format 날짜 포맷 ('full', 'date', 'time', 'datetime')
 * @param customOptions 사용자 정의 옵션 (format이 'custom'일 때)
 * @returns 포맷팅된 날짜 문자열, 빈 값이면 '-' 반환
 */
export const formatDate = (
  dateStr?: string | null,
  format: DateFormat = 'full',
  customOptions: Intl.DateTimeFormatOptions = {},
): string => {
  if (!dateStr) return '-';

  try {
    const date = new Date(dateStr);
    const options =
      format === 'custom' ? customOptions : DEFAULT_FORMAT_OPTIONS[format];

    const formatted = date.toLocaleString('ko-KR', options);

    // 날짜 형식에 따라 추가 처리
    if (format === 'full' || format === 'custom') {
      return formatted.replace(/\. /g, '-').replace(/:/g, ':').replace('.', '');
    }

    return formatted;
  } catch (error) {
    console.error('날짜 포맷팅 오류:', error);
    return dateStr || '-';
  }
};

/**
 * dayjs 형식의 날짜 출력 포맷 문자열 (대체 사용)
 */
export const DATE_FORMATS = {
  FULL: 'YYYY-MM-DD HH:mm:ss',
  DATE: 'YYYY-MM-DD',
  TIME: 'HH:mm:ss',
  DATETIME: 'YYYY-MM-DD HH:mm',
};
