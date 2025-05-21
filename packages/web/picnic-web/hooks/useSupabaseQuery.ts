'use client';

import { useState, useCallback } from 'react';
import { useSupabase } from '@/components/providers/SupabaseProvider';
import { handleError, AppError } from '@/lib/supabase/error';
import { PostgrestError } from '@supabase/supabase-js';

/**
 * 데이터 로딩 상태를 관리하는 타입
 */
export type QueryState<T> = {
  /**
   * 로딩 중 여부
   */
  isLoading: boolean;
  
  /**
   * 데이터 로딩 성공 여부
   */
  isSuccess: boolean;
  
  /**
   * 오류 발생 여부
   */
  isError: boolean;
  
  /**
   * 에러 객체
   */
  error: AppError | null;
  
  /**
   * 응답 데이터
   */
  data: T | null;
};

/**
 * Supabase 쿼리를 위한 확장 커스텀 훅
 * 
 * 이 훅은 데이터 로딩 상태 관리, 에러 처리, 자동 데이터 변환 기능을 제공합니다.
 * 자동으로 카멜 케이스 변환도 적용됩니다.
 * 
 * @example
 * ```tsx
 * const { 
 *   data, 
 *   isLoading, 
 *   isError, 
 *   error, 
 *   execute 
 * } = useSupabaseQuery(
 *   (supabase) => supabase
 *     .from('votes')
 *     .select('*')
 * );
 * 
 * // 쿼리 실행
 * useEffect(() => {
 *   execute();
 * }, []);
 * ```
 * 
 * @param queryFn Supabase 쿼리 함수
 * @returns 쿼리 상태와 실행 함수
 */
export function useSupabaseQuery<T>(
  queryFn: (supabase: ReturnType<typeof useSupabase>['supabase']) => Promise<{
    data: any;
    error: PostgrestError | null;
  }>
) {
  const { supabase, transformers } = useSupabase();
  const [state, setState] = useState<QueryState<T>>({
    isLoading: false,
    isSuccess: false,
    isError: false,
    error: null,
    data: null,
  });

  /**
   * 쿼리 실행 함수
   */
  const execute = useCallback(async () => {
    setState(prev => ({ ...prev, isLoading: true, isError: false, error: null }));
    
    try {
      const { data, error } = await queryFn(supabase);
      
      if (error) {
        const appError = handleError(error);
        setState({
          isLoading: false,
          isSuccess: false,
          isError: true,
          error: appError,
          data: null,
        });
      } else {
        // 데이터를 카멜 케이스로 변환
        const transformedData = transformers.transform(data) as T;
        setState({
          isLoading: false,
          isSuccess: true,
          isError: false,
          error: null,
          data: transformedData,
        });
      }
    } catch (error) {
      const appError = handleError(error);
      setState({
        isLoading: false,
        isSuccess: false,
        isError: true,
        error: appError,
        data: null,
      });
    }
  }, [supabase, queryFn, transformers]);

  return {
    ...state,
    execute,
  };
}

/**
 * 변경(삽입, 업데이트, 삭제) 쿼리를 위한 확장 커스텀 훅
 * 
 * @example
 * ```tsx
 * const { 
 *   isLoading, 
 *   isError, 
 *   error, 
 *   execute 
 * } = useSupabaseMutation(
 *   (supabase, data) => supabase
 *     .from('votes')
 *     .insert(data)
 * );
 * 
 * // 뮤테이션 실행
 * const handleSubmit = async (formData) => {
 *   await execute(formData);
 * };
 * ```
 * 
 * @param mutationFn Supabase 변경 쿼리 함수
 * @returns 뮤테이션 상태와 실행 함수
 */
export function useSupabaseMutation<T, R = any>(
  mutationFn: (
    supabase: ReturnType<typeof useSupabase>['supabase'],
    data: T
  ) => Promise<{
    data: any;
    error: PostgrestError | null;
  }>
) {
  const { supabase, transformers } = useSupabase();
  const [state, setState] = useState<QueryState<R>>({
    isLoading: false,
    isSuccess: false,
    isError: false,
    error: null,
    data: null,
  });

  /**
   * 뮤테이션 실행 함수
   */
  const execute = useCallback(
    async (data: T) => {
      setState(prev => ({ ...prev, isLoading: true, isError: false, error: null }));
      
      try {
        const result = await mutationFn(supabase, data);
        
        if (result.error) {
          const appError = handleError(result.error);
          setState({
            isLoading: false,
            isSuccess: false,
            isError: true,
            error: appError,
            data: null,
          });
          return { success: false, error: appError };
        } else {
          // 데이터를 카멜 케이스로 변환
          const transformedData = transformers.transform(result.data) as R;
          setState({
            isLoading: false,
            isSuccess: true,
            isError: false,
            error: null,
            data: transformedData,
          });
          return { success: true, data: transformedData };
        }
      } catch (error) {
        const appError = handleError(error);
        setState({
          isLoading: false,
          isSuccess: false,
          isError: true,
          error: appError,
          data: null,
        });
        return { success: false, error: appError };
      }
    },
    [supabase, mutationFn, transformers]
  );

  return {
    ...state,
    execute,
  };
} 