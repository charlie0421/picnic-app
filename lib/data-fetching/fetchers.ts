/**
 * 서버 사이드 데이터 페칭 유틸리티
 * 
 * Next.js의 서버 컴포넌트에서 사용할 데이터 페칭 유틸리티 함수 모음입니다.
 * 이 파일의 함수들은 서버 컴포넌트에서만 사용해야 합니다.
 */

import { createClient } from '@/utils/supabase-server-client';
import { notFound } from 'next/navigation';
import { cache } from 'react';

// 기본 캐싱 옵션
export type CacheOptions = {
  revalidate?: number | false; // 데이터 재검증 시간 (초)
  tags?: string[]; // 캐시 태그
};

const DEFAULT_CACHE_OPTIONS: CacheOptions = {
  revalidate: 60, // 기본 1분 캐싱
};

/**
 * Supabase 쿼리를 위한 기본 페처 함수
 * 서버 컴포넌트에서 캐싱과 함께 Supabase 쿼리를 실행
 */
export const fetchFromSupabase = cache(async <T>(
  queryBuilder: (supabase: ReturnType<typeof createClient>) => Promise<{ data: T | null; error: any }>,
  options: CacheOptions = DEFAULT_CACHE_OPTIONS
): Promise<T> => {
  try {
    const supabase = createClient();
    const { data, error } = await queryBuilder(supabase);

    if (error) {
      console.error('Supabase query error:', error);
      throw new Error(error.message || '데이터 조회 중 오류가 발생했습니다.');
    }

    if (!data) {
      return [] as unknown as T;
    }

    return data;
  } catch (error) {
    console.error('Data fetching error:', error);
    throw error;
  }
});

/**
 * ID로 단일 데이터 조회
 */
export const fetchById = cache(async <T>(
  table: string,
  id: string,
  columns: string = '*',
  options: CacheOptions = DEFAULT_CACHE_OPTIONS
): Promise<T> => {
  return fetchFromSupabase(async (supabase) => {
    return supabase
      .from(table)
      .select(columns)
      .eq('id', id)
      .single();
  }, options);
});

/**
 * 특정 조건으로 데이터 목록 조회
 */
export const fetchList = cache(async <T>(
  table: string,
  columns: string = '*',
  filters?: Record<string, any>,
  options: CacheOptions = DEFAULT_CACHE_OPTIONS
): Promise<T[]> => {
  return fetchFromSupabase(async (supabase) => {
    let query = supabase.from(table).select(columns);
    
    // 필터 적용
    if (filters) {
      Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined) {
          query = query.eq(key, value);
        }
      });
    }
    
    return query;
  }, options);
});

/**
 * 외부 API를 호출하는 페처 함수
 */
export const fetchApi = cache(async <T>(
  url: string,
  options: RequestInit = {},
  cacheOptions: CacheOptions = DEFAULT_CACHE_OPTIONS
): Promise<T> => {
  try {
    const res = await fetch(url, {
      ...options,
      next: {
        revalidate: cacheOptions.revalidate,
        tags: cacheOptions.tags,
      },
    });

    if (!res.ok) {
      throw new Error(`API 요청 실패: ${res.status}`);
    }

    return res.json();
  } catch (error) {
    console.error('API fetch error:', error);
    throw error;
  }
}); 