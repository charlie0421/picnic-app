import { PostgrestError } from '@supabase/supabase-js';

/**
 * 애플리케이션에서 사용하는 에러 코드 열거형
 */
export enum ErrorCode {
  NOT_FOUND = 'not_found',
  UNAUTHORIZED = 'unauthorized',
  FORBIDDEN = 'forbidden',
  CONFLICT = 'conflict',
  VALIDATION = 'validation',
  SERVER_ERROR = 'server_error',
  NETWORK_ERROR = 'network_error',
  UNKNOWN = 'unknown',
}

/**
 * 애플리케이션 에러 클래스
 * 
 * 모든 API 에러는 이 클래스를 사용하여 일관된 형식으로 반환됩니다.
 */
export class AppError extends Error {
  code: ErrorCode;
  status?: number;
  details?: unknown;

  constructor(message: string, code: ErrorCode, details?: unknown, status?: number) {
    super(message);
    this.name = 'AppError';
    this.code = code;
    this.details = details;
    this.status = status;
  }

  /**
   * 에러 메시지와 함께 토스트 등에 표시할 수 있는 사용자 친화적인 메시지를 반환합니다.
   */
  toFriendlyMessage(): string {
    switch (this.code) {
      case ErrorCode.NOT_FOUND:
        return '요청한 데이터를 찾을 수 없습니다.';
      case ErrorCode.UNAUTHORIZED:
        return '로그인이 필요합니다.';
      case ErrorCode.FORBIDDEN:
        return '접근 권한이 없습니다.';
      case ErrorCode.CONFLICT:
        return '데이터 충돌이 발생했습니다.';
      case ErrorCode.VALIDATION:
        return '입력 데이터가 유효하지 않습니다.';
      case ErrorCode.NETWORK_ERROR:
        return '네트워크 연결을 확인해주세요.';
      case ErrorCode.SERVER_ERROR:
        return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      default:
        return this.message || '알 수 없는 오류가 발생했습니다.';
    }
  }
}

/**
 * PostgreSQL 에러 코드와 관련 정보
 * 
 * https://www.postgresql.org/docs/current/errcodes-appendix.html
 */
const PG_ERROR_CODES = {
  // "not_found" 관련 에러
  UNDEFINED_TABLE: '42P01',      // undefined_table
  UNDEFINED_COLUMN: '42703',     // undefined_column
  INVALID_TEXT_REPRESENTATION: '22P02',  // invalid_text_representation (e.g., UUID 포맷 오류)
  FOREIGN_KEY_VIOLATION: '23503', // foreign_key_violation

  // "forbidden" 관련 에러
  INSUFFICIENT_PRIVILEGE: '42501', // insufficient_privilege
  INVALID_PASSWORD: '28P01',      // invalid_password

  // "conflict" 관련 에러
  UNIQUE_VIOLATION: '23505',     // unique_violation

  // "validation" 관련 에러
  NOT_NULL_VIOLATION: '23502',   // not_null_violation
  CHECK_VIOLATION: '23514',      // check_violation
  STRING_DATA_RIGHT_TRUNCATION: '22001', // string_data_right_truncation
};

/**
 * Supabase/Postgres 에러를 애플리케이션 표준 에러로 변환합니다.
 * 
 * @param error Supabase에서 반환된 PostgrestError
 * @returns 애플리케이션 표준 에러 객체
 */
export function handleSupabaseError(error: PostgrestError): AppError {
  const { code, message, details } = error;
  
  // PostgreSQL 에러 코드에 따라 적절한 에러 반환
  
  // NOT_FOUND 에러
  if (
    code === PG_ERROR_CODES.UNDEFINED_TABLE ||
    code === PG_ERROR_CODES.UNDEFINED_COLUMN ||
    code === PG_ERROR_CODES.INVALID_TEXT_REPRESENTATION ||
    code === PG_ERROR_CODES.FOREIGN_KEY_VIOLATION
  ) {
    return new AppError(
      '요청한 데이터를 찾을 수 없습니다', 
      ErrorCode.NOT_FOUND, 
      details,
      404
    );
  }
  
  // FORBIDDEN 에러
  if (
    code === PG_ERROR_CODES.INSUFFICIENT_PRIVILEGE ||
    code === PG_ERROR_CODES.INVALID_PASSWORD
  ) {
    return new AppError(
      '접근 권한이 없습니다', 
      ErrorCode.FORBIDDEN, 
      details,
      403
    );
  }
  
  // CONFLICT 에러
  if (code === PG_ERROR_CODES.UNIQUE_VIOLATION) {
    return new AppError(
      '중복된 데이터가 존재합니다', 
      ErrorCode.CONFLICT, 
      details,
      409
    );
  }
  
  // VALIDATION 에러
  if (
    code === PG_ERROR_CODES.NOT_NULL_VIOLATION ||
    code === PG_ERROR_CODES.CHECK_VIOLATION ||
    code === PG_ERROR_CODES.STRING_DATA_RIGHT_TRUNCATION ||
    code?.startsWith('22') // 데이터 예외 클래스
  ) {
    return new AppError(
      '데이터 유효성 검증에 실패했습니다', 
      ErrorCode.VALIDATION, 
      details,
      400
    );
  }
  
  // 기타 서버 에러
  return new AppError(
    message || '서버 에러가 발생했습니다', 
    ErrorCode.SERVER_ERROR, 
    details,
    500
  );
}

/**
 * 일반 에러를 애플리케이션 표준 에러로 변환합니다.
 * 
 * @param error 발생한 에러 객체
 * @returns 애플리케이션 표준 에러 객체
 */
export function handleError(error: unknown): AppError {
  // 이미 AppError인 경우 그대로 반환
  if (error instanceof AppError) {
    return error;
  }
  
  // PostgrestError인 경우 handleSupabaseError로 변환
  if (error && typeof error === 'object' && 'code' in error && 'message' in error) {
    return handleSupabaseError(error as PostgrestError);
  }
  
  // 네트워크 에러
  if (error instanceof TypeError && error.message.includes('fetch')) {
    return new AppError(
      '네트워크 연결을 확인해주세요',
      ErrorCode.NETWORK_ERROR,
      error,
      0
    );
  }
  
  // 그 외 모든 에러는 UNKNOWN으로 처리
  const errorMessage = error instanceof Error ? error.message : String(error);
  return new AppError(
    errorMessage || '알 수 없는 오류가 발생했습니다',
    ErrorCode.UNKNOWN,
    error,
    500
  );
} 