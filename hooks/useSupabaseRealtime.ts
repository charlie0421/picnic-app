'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { useSupabase } from '@/components/providers/SupabaseProvider';
import { handleError } from '@/lib/supabase/error';
import type { RealtimeChannel, RealtimePostgresChangesPayload } from '@supabase/supabase-js';

/**
 * 구독 이벤트 타입
 */
export type SubscriptionEvent = 'INSERT' | 'UPDATE' | 'DELETE' | '*';

/**
 * 구독 설정 옵션
 */
export type SubscriptionOptions<T> = {
  /**
   * 테이블 이름 (예: 'votes')
   */
  table: string;
  
  /**
   * 구독할 이벤트 타입(들)
   * @default '*'
   */
  event?: SubscriptionEvent | SubscriptionEvent[];
  
  /**
   * 필터 조건 (예: 'vote_id=eq.123')
   */
  filter?: string;
  
  /**
   * 데이터 변경 시 호출될 콜백 함수
   */
  onChange?: (payload: RealtimePostgresChangesPayload<T>) => void;
};

/**
 * Supabase Realtime API를 사용하여 데이터 변경을 구독하는 커스텀 훅
 * 
 * @example
 * ```tsx
 * // 투표 항목 변경 구독
 * useSupabaseSubscription({
 *   table: 'vote_item',
 *   event: 'UPDATE',
 *   filter: `vote_id=eq.${voteId}`,
 *   onChange: (payload) => {
 *     // 변경된 데이터 처리
 *     console.log('투표 항목 업데이트:', payload);
 *   }
 * });
 * ```
 * 
 * @param options 구독 설정 옵션
 */
export function useSupabaseSubscription<T = any>(options: SubscriptionOptions<T>) {
  const { supabase, transformers } = useSupabase();
  const [isConnected, setIsConnected] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const channelRef = useRef<RealtimeChannel | null>(null);

  const { table, event = '*', filter, onChange } = options;

  const cleanup = useCallback(() => {
    if (channelRef.current) {
      channelRef.current.unsubscribe();
      channelRef.current = null;
      setIsConnected(false);
    }
  }, []);

  useEffect(() => {
    const setupSubscription = async () => {
      // 이전 구독 정리
      cleanup();

      try {
        // 채널 ID 생성
        const channelId = `${table}${filter ? `:${filter}` : ''}`;
        
        // 이벤트 설정
        const events = Array.isArray(event) ? event : [event];
        
        // 필터 설정
        const filterOptions = filter
          ? { filter }
          : undefined;
          
        // 구독 채널 생성
        const subscription = supabase
          .channel(channelId)
          .on(
            'postgres_changes',
            events.map(e => ({
              event: e,
              schema: 'public',
              table,
              ...(filterOptions || {}),
            })),
            (payload: RealtimePostgresChangesPayload<any>) => {
              // 페이로드 데이터를 카멜 케이스로 변환
              if (payload.new) {
                payload.new = transformers.transform(payload.new);
              }
              if (payload.old) {
                payload.old = transformers.transform(payload.old);
              }
              
              // 콜백 호출
              onChange?.(payload as RealtimePostgresChangesPayload<T>);
            }
          )
          .subscribe((status) => {
            if (status === 'SUBSCRIBED') {
              setIsConnected(true);
              setError(null);
            } else if (status === 'CHANNEL_ERROR') {
              setIsConnected(false);
              setError(new Error('실시간 구독 오류가 발생했습니다'));
            }
          });
          
        // 생성된 채널 저장
        channelRef.current = subscription;
      } catch (err) {
        setIsConnected(false);
        setError(handleError(err));
      }
    };

    setupSubscription();

    // 컴포넌트 언마운트 시 구독 정리
    return cleanup;
  }, [supabase, table, event, filter, onChange, cleanup, transformers]);

  return {
    isConnected,
    error,
    /**
     * 구독 해제 함수
     */
    unsubscribe: cleanup,
  };
}

/**
 * 간단한 Realtime 구독을 제공하는 커스텀 훅
 * 
 * 이 훅은 데이터를 자동으로 가져오고 실시간 업데이트도 구독합니다.
 * 
 * @example
 * ```tsx
 * const { data, isLoading, error } = useRealtimeData({
 *   table: 'votes',
 *   query: (supabase) => supabase
 *     .from('votes')
 *     .select('*')
 *     .eq('id', voteId)
 *     .single(),
 *   subscription: {
 *     event: 'UPDATE',
 *     filter: `id=eq.${voteId}`
 *   }
 * });
 * ```
 */
export function useRealtimeData<T>({
  table,
  query,
  subscription,
}: {
  /**
   * 테이블 이름
   */
  table: string;
  
  /**
   * 초기 데이터를 가져오는 쿼리 함수
   */
  query: (supabase: ReturnType<typeof useSupabase>['supabase']) => Promise<{
    data: any;
    error: any;
  }>;
  
  /**
   * 구독 설정 (선택적)
   */
  subscription?: {
    event?: SubscriptionEvent | SubscriptionEvent[];
    filter?: string;
  };
}) {
  const { supabase, transformers } = useSupabase();
  const [data, setData] = useState<T | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<Error | null>(null);

  // 데이터 로드 함수
  const loadData = useCallback(async () => {
    setIsLoading(true);
    
    try {
      const { data: responseData, error: responseError } = await query(supabase);
      
      if (responseError) {
        setError(handleError(responseError));
        setData(null);
      } else {
        setData(transformers.transform(responseData) as T);
        setError(null);
      }
    } catch (err) {
      setError(handleError(err));
      setData(null);
    } finally {
      setIsLoading(false);
    }
  }, [supabase, query, transformers]);

  // 데이터 변경 핸들러
  const handleDataChange = useCallback((payload: RealtimePostgresChangesPayload<T>) => {
    // 변경 타입에 따른 처리
    switch (payload.eventType) {
      case 'INSERT':
        loadData(); // 새 데이터 삽입 시 전체 다시 로드
        break;
        
      case 'UPDATE':
        // 단일 항목 업데이트인 경우 직접 상태 업데이트
        if (payload.new && typeof data === 'object' && data !== null) {
          setData(prev => {
            if (Array.isArray(prev)) {
              // 배열인 경우, ID로 항목 찾아 업데이트
              const idField = 'id' in payload.new ? 'id' : 'ID' in payload.new ? 'ID' : null;
              
              if (idField && idField in payload.new) {
                return prev.map(item => 
                  (item as any)[idField] === (payload.new as any)[idField]
                    ? { ...item, ...payload.new }
                    : item
                ) as T;
              }
            }
            
            // 단일 객체나 ID를 찾을 수 없는 경우 전체 교체
            return Array.isArray(prev) ? prev : { ...prev, ...payload.new } as T;
          });
        } else {
          // 복잡한 데이터 구조인 경우 다시 로드
          loadData();
        }
        break;
        
      case 'DELETE':
        // 삭제 시 다시 로드
        loadData();
        break;
    }
  }, [data, loadData]);

  // 초기 데이터 로드
  useEffect(() => {
    loadData();
  }, [loadData]);

  // 실시간 구독 설정 (선택적)
  useSupabaseSubscription({
    table,
    event: subscription?.event || 'UPDATE',
    filter: subscription?.filter,
    onChange: handleDataChange,
  });

  return {
    data,
    isLoading,
    error,
    /**
     * 수동으로 데이터를 다시 로드하는 함수
     */
    refresh: loadData,
  };
} 