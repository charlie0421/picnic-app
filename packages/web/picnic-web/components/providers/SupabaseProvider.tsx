'use client';

import React, { createContext, useContext, useState } from 'react';
import { createBrowserSupabaseClient } from '@/lib/supabase/client';
import { clientTransformers } from '@/lib/supabase/middleware';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '@/types/supabase';

/**
 * Supabase 컨텍스트 타입 정의
 */
export type SupabaseContextType = {
  /**
   * Supabase 클라이언트 인스턴스
   */
  supabase: SupabaseClient<Database>;
  
  /**
   * 카멜 케이스로 자동 변환하는 유틸리티
   */
  transformers: typeof clientTransformers;
};

/**
 * Supabase 컨텍스트
 */
const SupabaseContext = createContext<SupabaseContextType | undefined>(undefined);

export interface SupabaseProviderProps {
  /**
   * 자식 컴포넌트
   */
  children: React.ReactNode;
}

/**
 * Supabase 클라이언트를 제공하는 컨텍스트 프로바이더 컴포넌트
 * 
 * 이 컴포넌트는 애플리케이션에서 Supabase 클라이언트를 일관되게 사용할 수 있도록 합니다.
 * AuthProvider와 함께 사용해야 합니다.
 * 
 * @example
 * ```tsx
 * // app/layout.tsx (최상위 레이아웃)
 * export default function RootLayout({ children }) {
 *   return (
 *     <html>
 *       <body>
 *         <SupabaseProvider>
 *           <AuthProvider>
 *             {children}
 *           </AuthProvider>
 *         </SupabaseProvider>
 *       </body>
 *     </html>
 *   );
 * }
 * ```
 */
export const SupabaseProvider: React.FC<SupabaseProviderProps> = ({ children }) => {
  // 싱글톤 패턴으로 Supabase 클라이언트 인스턴스 생성
  const [supabase] = useState(() => createBrowserSupabaseClient());
  
  return (
    <SupabaseContext.Provider 
      value={{ 
        supabase,
        transformers: clientTransformers
      }}
    >
      {children}
    </SupabaseContext.Provider>
  );
};

/**
 * Supabase 컨텍스트를 사용하는 커스텀 훅
 * 
 * 이 훅을 사용하면 SupabaseProvider 내에서 Supabase 클라이언트에 접근할 수 있습니다.
 * 
 * @example
 * ```tsx
 * const { supabase, transformers } = useSupabase();
 * 
 * // 데이터 가져오기
 * const fetchData = async () => {
 *   const { data, error } = await supabase
 *     .from('votes')
 *     .select('*')
 *     .then(transformers.transformResponse);
 *   // ...
 * };
 * ```
 * 
 * @throws SupabaseProvider 외부에서 사용할 경우 오류
 */
export function useSupabase(): SupabaseContextType {
  const context = useContext(SupabaseContext);
  
  if (context === undefined) {
    throw new Error('useSupabase는 SupabaseProvider 내에서 사용해야 합니다');
  }
  
  return context;
}

/**
 * Supabase 클라이언트가 준비된 후에만 콘텐츠를 렌더링하는 컴포넌트
 */
export const SupabaseGuard: React.FC<{ children: React.ReactNode; fallback?: React.ReactNode }> = ({
  children,
  fallback = <div>Supabase 초기화 중...</div>,
}) => {
  const { supabase } = useSupabase();

  return <>{children}</>;
};
