import { SupabaseClient } from '@supabase/supabase-js';
import { snakeToCamel } from '@/utils/transform';
import { Database } from '@/types/supabase';

/**
 * 응답 데이터를 스네이크 케이스에서 카멜 케이스로 변환합니다.
 * 
 * @param data 변환할 데이터
 * @returns 변환된 데이터
 */
export function transformData<T>(data: T): T {
  if (!data) return data;
  return snakeToCamel(data) as T;
}

/**
 * 서버 Supabase 클라이언트의 응답을 카멜 케이스로 변환하는 헬퍼 함수
 * 
 * @example
 * // 서버 컴포넌트에서
 * const supabase = await createServerSupabaseClient();
 * const { data, error } = await supabase
 *   .from('votes')
 *   .select('*')
 *   .then(transformResponse);
 * 
 * @param response Supabase 응답 객체
 * @returns 데이터가 카멜 케이스로 변환된 응답 객체
 */
export function transformResponse<T = any>(response: { data: T | null; error: any }) {
  if (response.data) {
    return {
      data: transformData(response.data),
      error: response.error
    };
  }
  return response;
}

/**
 * 서버에서 사용할 수 있는 변환 헬퍼 함수들을 제공합니다.
 */
export const serverTransformers = {
  /**
   * 데이터를 변환합니다.
   */
  transform: transformData,
  
  /**
   * Supabase 응답을 변환합니다.
   */
  transformResponse,
};

/**
 * 클라이언트에서 사용할 수 있는 변환 헬퍼 함수들을 제공합니다.
 */
export const clientTransformers = {
  /**
   * 데이터를 변환합니다.
   */
  transform: transformData,
  
  /**
   * Supabase 응답을 변환합니다.
   */
  transformResponse,
}; 