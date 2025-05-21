/**
 * 데이터 변환 유틸리티
 * 
 * Supabase에서 반환되는 데이터의 필드명을 스네이크 케이스(snake_case)에서 
 * 카멜 케이스(camelCase)로 변환하는 유틸리티 함수를 제공합니다.
 */

/**
 * 스네이크 케이스 문자열을 카멜 케이스로 변환합니다.
 * 
 * @example
 * // 'hello_world' -> 'helloWorld'
 * snakeToCamelCase('hello_world');
 * 
 * @param str 변환할 스네이크 케이스 문자열
 * @returns 카멜 케이스로 변환된 문자열
 */
export function snakeToCamelCase(str: string): string {
  return str.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
}

/**
 * 객체의 모든 키를 재귀적으로 스네이크 케이스에서 카멜 케이스로 변환합니다.
 * 
 * @example
 * // { 'hello_world': { 'foo_bar': 'baz' } } -> { 'helloWorld': { 'fooBar': 'baz' } }
 * snakeToCamel({ 'hello_world': { 'foo_bar': 'baz' } });
 * 
 * @param obj 변환할 객체 또는 배열
 * @returns 모든 키가 카멜 케이스로 변환된 새 객체 또는 배열
 */
export function snakeToCamel<T>(obj: T): any {
  // null이나 undefined 처리
  if (obj === null || obj === undefined) {
    return obj;
  }

  // 배열 처리
  if (Array.isArray(obj)) {
    return obj.map(snakeToCamel);
  }

  // 객체가 아닌 경우 (문자열, 숫자, boolean 등)
  if (typeof obj !== 'object') {
    return obj;
  }

  // Date 객체 처리
  if (obj instanceof Date) {
    return obj;
  }

  // 객체 처리
  return Object.fromEntries(
    Object.entries(obj).map(([key, value]) => [
      snakeToCamelCase(key),
      snakeToCamel(value)
    ])
  );
}

/**
 * 타입 변환을 위한 제네릭 타입 정의
 * 스네이크 케이스 문자열을 카멜 케이스로 변환하는 타입
 */
export type SnakeToCamelCase<S extends string> = S extends `${infer T}_${infer U}`
  ? `${T}${Capitalize<SnakeToCamelCase<U>>}`
  : S;

/**
 * 객체의 스네이크 케이스 키를 카멜 케이스로 변환하는 타입
 */
export type SnakeToCamel<T> = T extends Array<infer U>
  ? Array<SnakeToCamel<U>>
  : T extends object
  ? {
      [K in keyof T as K extends string ? SnakeToCamelCase<K> : K]: SnakeToCamel<T[K]>;
    }
  : T;

/**
 * 카멜 케이스 문자열을 스네이크 케이스로 변환합니다.
 * 
 * @example
 * // 'helloWorld' -> 'hello_world'
 * camelToSnakeCase('helloWorld');
 * 
 * @param str 변환할 카멜 케이스 문자열
 * @returns 스네이크 케이스로 변환된 문자열
 */
export function camelToSnakeCase(str: string): string {
  return str.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
}

/**
 * 객체의 모든 키를 재귀적으로 카멜 케이스에서 스네이크 케이스로 변환합니다.
 * 
 * @example
 * // { 'helloWorld': { 'fooBar': 'baz' } } -> { 'hello_world': { 'foo_bar': 'baz' } }
 * camelToSnake({ 'helloWorld': { 'fooBar': 'baz' } });
 * 
 * @param obj 변환할 객체 또는 배열
 * @returns 모든 키가 스네이크 케이스로 변환된 새 객체 또는 배열
 */
export function camelToSnake<T>(obj: T): any {
  // null이나 undefined 처리
  if (obj === null || obj === undefined) {
    return obj;
  }

  // 배열 처리
  if (Array.isArray(obj)) {
    return obj.map(camelToSnake);
  }

  // 객체가 아닌 경우 (문자열, 숫자, boolean 등)
  if (typeof obj !== 'object') {
    return obj;
  }

  // Date 객체 처리
  if (obj instanceof Date) {
    return obj;
  }

  // 객체 처리
  return Object.fromEntries(
    Object.entries(obj).map(([key, value]) => [
      camelToSnakeCase(key),
      camelToSnake(value)
    ])
  );
} 