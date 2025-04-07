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
  if (process.env.NODE_ENV !== 'production') {
    const logPrefix = `[${timestamp}] [${level}] [${category}]`;

    switch (level) {
      case LogLevel.ERROR:
        console.error(
          logPrefix,
          message,
          data ? JSON.stringify(data, null, 2) : '',
        );
        break;
      case LogLevel.WARN:
        console.warn(
          logPrefix,
          message,
          data ? JSON.stringify(data, null, 2) : '',
        );
        break;
      case LogLevel.DEBUG:
        console.debug(
          logPrefix,
          message,
          data ? JSON.stringify(data, null, 2) : '',
        );
        break;
      default:
      // console.log 제거
    }
  }

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
