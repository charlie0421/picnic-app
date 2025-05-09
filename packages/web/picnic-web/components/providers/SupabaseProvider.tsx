'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import { SupabaseClient } from '@supabase/supabase-js';
import { supabase as supabaseClient } from '@/utils/supabase-client';

// Supabase 컨텍스트 타입 정의
type SupabaseContextType = {
  supabase: SupabaseClient;
  isReady: boolean;
};

// 컨텍스트 생성
const SupabaseContext = createContext<SupabaseContextType | undefined>(undefined);

// Provider Props 타입 정의
interface SupabaseProviderProps {
  children: React.ReactNode;
}

/**
 * Supabase 클라이언트를 앱 전체에서 사용할 수 있게 해주는 Provider
 */
export const SupabaseProvider: React.FC<SupabaseProviderProps> = ({ children }) => {
  const [isReady, setIsReady] = useState(false);

  useEffect(() => {
    // 브라우저 환경에서만 실행
    if (typeof window !== 'undefined') {
      // Supabase 연결 상태 확인
      const checkConnection = async () => {
        try {
          // 간단한 쿼리로 연결 상태 확인
          await supabaseClient.from('vote').select('count').limit(1);
          setIsReady(true);
          
          console.log('Supabase 연결 성공', {
            isReady: true,
            url: window.location.href,
          });
        } catch (error) {
          console.error('Supabase 연결 실패:', error);
          // 연결 실패 시 1초 후 재시도
          setTimeout(checkConnection, 1000);
        }
      };

      checkConnection();
    }
  }, []);

  return (
    <SupabaseContext.Provider value={{ supabase: supabaseClient, isReady }}>
      {children}
    </SupabaseContext.Provider>
  );
};

/**
 * Supabase 클라이언트를 사용하기 위한 훅
 * @returns Supabase 클라이언트와 초기화 상태
 */
export const useSupabase = (): SupabaseContextType => {
  const context = useContext(SupabaseContext);
  if (!context) {
    throw new Error('useSupabase must be used within a SupabaseProvider');
  }
  return context;
};

/**
 * Supabase 클라이언트가 준비된 후에만 콘텐츠를 렌더링하는 컴포넌트
 */
export const SupabaseGuard: React.FC<{ children: React.ReactNode; fallback?: React.ReactNode }> = ({
  children,
  fallback = <div>Supabase 초기화 중...</div>,
}) => {
  const { isReady } = useSupabase();
  
  if (!isReady) {
    return <>{fallback}</>;
  }
  
  return <>{children}</>;
}; 