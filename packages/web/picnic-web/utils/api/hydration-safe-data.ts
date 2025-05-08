/**
 * 하이드레이션 안전한 데이터 로딩을 위한 유틸리티
 */
import { useState, useEffect, useCallback } from 'react';

type DataFetcher<T> = () => Promise<T>;

/**
 * 하이드레이션 안전한 방식으로 데이터를 로드하는 훅
 * 
 * @param fetcher 데이터를 가져오는 비동기 함수
 * @param initialData 초기 데이터 (SSR에서 제공된 경우)
 * @param dependencies 의존성 배열 ([] 기본값은 컴포넌트 마운트 시 한 번만 실행)
 * @returns 로딩 상태, 에러, 데이터를 포함하는 객체
 */
export function useSafeData<T>(
  fetcher: DataFetcher<T>,
  initialData?: T,
  dependencies: any[] = []
) {
  const [mounted, setMounted] = useState(false);
  const [data, setData] = useState<T | undefined>(initialData);
  const [isLoading, setIsLoading] = useState(!initialData);
  const [error, setError] = useState<Error | null>(null);

  // 마운트 상태 설정
  useEffect(() => {
    setMounted(true);
    return () => setMounted(false);
  }, []);

  // 데이터 로드
  useEffect(() => {
    if (!mounted) return;

    let isCancelled = false;
    let timeoutId: NodeJS.Timeout;
    
    const loadData = async () => {
      if (!initialData) {
        setIsLoading(true);
      }

      try {
        const result = await fetcher();
        
        if (isCancelled) return;
        
        setData(result);
        setError(null);
      } catch (err) {
        if (isCancelled) return;
        console.error('데이터 로딩 중 오류 발생:', err);
        setError(err instanceof Error ? err : new Error(String(err)));
      } finally {
        if (!isCancelled) {
          setIsLoading(false);
        }
      }
    };

    // 초기 데이터 로드
    loadData();

    // 30초마다 데이터 새로고침
    timeoutId = setInterval(loadData, 30000);

    return () => {
      isCancelled = true;
      clearInterval(timeoutId);
    };
  }, [mounted, initialData, ...dependencies]);

  return { data, isLoading, error, mounted };
}

/**
 * 하이드레이션 안전한 방식으로 데이터를 새로고침하는 훅
 * 
 * @param fetcher 데이터를 가져오는 비동기 함수
 * @param interval 새로고침 간격 (밀리초)
 * @param initialData 초기 데이터 (SSR에서 제공된 경우)
 * @returns 로딩 상태, 에러, 데이터를 포함하는 객체와 수동 새로고침 함수
 */
export function useRefreshableData<T>(
  fetcher: DataFetcher<T>,
  interval: number = 0,
  initialData?: T
) {
  const [mounted, setMounted] = useState(false);
  const [data, setData] = useState<T | undefined>(initialData);
  const [isLoading, setIsLoading] = useState(!initialData);
  const [error, setError] = useState<Error | null>(null);
  const [lastRefreshed, setLastRefreshed] = useState<Date>(new Date());

  // 클라이언트 사이드에서만 마운트 설정
  useEffect(() => {
    setMounted(true);
  }, []);

  const refresh = async () => {
    if (!mounted) return;
    
    setIsLoading(true);
    try {
      const result = await fetcher();
      setData(result);
      setLastRefreshed(new Date());
      setError(null);
    } catch (err) {
      console.error('데이터 새로고침 중 오류 발생:', err);
      setError(err instanceof Error ? err : new Error(String(err)));
    } finally {
      setIsLoading(false);
    }
  };

  // 초기 데이터 로드
  useEffect(() => {
    if (!mounted) return;
    
    // 초기 데이터가 없는 경우에만 처음 로드
    if (!initialData) {
      refresh();
    }
  }, [mounted, initialData]);

  // 정기적 새로고침 설정
  useEffect(() => {
    if (!mounted || interval <= 0) return;
    
    const timer = setInterval(refresh, interval);
    
    return () => {
      clearInterval(timer);
    };
  }, [mounted, interval]);

  return { data, isLoading, error, mounted, refresh, lastRefreshed };
} 