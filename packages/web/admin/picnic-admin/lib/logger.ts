/**
 * 로깅 유틸리티
 *
 * 애플리케이션 내 로그를 표준화하고 관리하기 위한 유틸리티 함수들
 */

// 로그 레벨 정의
export enum LogLevel {
  INFO = 'INFO',
  WARN = 'WARN',
  ERROR = 'ERROR',
  DEBUG = 'DEBUG',
}

// 로그 카테고리 정의
export enum LogCategory {
  AUTH = 'AUTH',
  PERMISSION = 'PERMISSION',
  API = 'API',
  SYSTEM = 'SYSTEM',
}

/**
 * 로그 메시지 생성 함수
 *
 * @param level 로그 레벨
 * @param category 로그 카테고리
 * @param message 로그 메시지
 * @param data 추가 데이터 (선택사항)
 * @returns 포맷팅된 로그 객체
 */
export const createLogMessage = (
  level: LogLevel,
  category: LogCategory,
  message: string,
  data?: any,
) => {
  const timestamp = new Date().toISOString();
  return {
    level,
    category,
    message,
    timestamp,
    data,
  };
};

/**
 * 로그 출력 함수
 *
 * @param logMessage 로그 메시지 객체
 */
export const writeLog = (logMessage: ReturnType<typeof createLogMessage>) => {
  const { level, category, message, timestamp, data } = logMessage;

  // 개발 환경에서는 콘솔에 출력
  // if (process.env.NODE_ENV !== 'production') {
    const logPrefix = `[${timestamp}] [${level}] [${category}]`;

    let dataOutput = '';
    if (data) {
      try {
        if (typeof data === 'object') {
          // 객체를 최대 2단계까지만 문자열로 변환 (중첩 객체 처리)
          const formattedData = JSON.stringify(data, (key, value) => {
            // 길이가 긴 배열이나 객체는 요약
            if (Array.isArray(value) && value.length > 10) {
              return `Array(${value.length}) [${value.slice(0, 3).join(', ')}...]`;
            }
            // 객체를 문자열로 변환할 때 너무 깊은 중첩은 피함
            if (typeof value === 'object' && value !== null) {
              const keys = Object.keys(value);
              if (keys.length > 10) {
                const obj: Record<string, any> = {};
                keys.slice(0, 5).forEach(k => obj[k] = value[k]);
                return `Object {${keys.length} keys} ${JSON.stringify(obj)}...`;
              }
            }
            return value;
          }, 2);
          
          dataOutput = formattedData;
        } else {
          dataOutput = String(data);
        }
      } catch (e) {
        dataOutput = 'Error formatting log data';
      }
    }

    switch (level) {
      case LogLevel.ERROR:
        console.error(logPrefix, message, dataOutput);
        break;
      case LogLevel.WARN:
        console.warn(logPrefix, message, dataOutput);
        break;
      case LogLevel.DEBUG:
        console.debug(logPrefix, message, dataOutput);
        break;
      default:
        // INFO 레벨도 모두 출력하여 디버깅 용이하게
        console.log(logPrefix, message, dataOutput);
    }
  // }

  // TODO: 프로덕션 환경에서는 서버 로깅, 분석 툴 등에 전송 가능
  // 예: API 호출, 외부 로깅 서비스 등
};

/**
 * 인증 관련 로그
 *
 * @param message 로그 메시지
 * @param data 추가 데이터 (선택사항)
 * @param level 로그 레벨 (기본값: INFO)
 */
export const logAuth = (message: string, data?: any, level = LogLevel.INFO) => {
  const logMessage = createLogMessage(level, LogCategory.AUTH, message, data);
  writeLog(logMessage);
};

/**
 * 권한 관련 로그
 *
 * @param message 로그 메시지
 * @param data 추가 데이터 (선택사항)
 * @param level 로그 레벨 (기본값: INFO)
 */
export const logPermission = (
  message: string,
  data?: any,
  level = LogLevel.INFO,
) => {
  const logMessage = createLogMessage(
    level,
    LogCategory.PERMISSION,
    message,
    data,
  );
  writeLog(logMessage);
};

/**
 * API 관련 로그
 *
 * @param message 로그 메시지
 * @param data 추가 데이터 (선택사항)
 * @param level 로그 레벨 (기본값: INFO)
 */
export const logApi = (message: string, data?: any, level = LogLevel.INFO) => {
  const logMessage = createLogMessage(level, LogCategory.API, message, data);
  writeLog(logMessage);
};

/**
 * 시스템 관련 로그
 *
 * @param message 로그 메시지
 * @param data 추가 데이터 (선택사항)
 * @param level 로그 레벨 (기본값: INFO)
 */
export const logSystem = (
  message: string,
  data?: any,
  level = LogLevel.INFO,
) => {
  const logMessage = createLogMessage(level, LogCategory.SYSTEM, message, data);
  writeLog(logMessage);
};
